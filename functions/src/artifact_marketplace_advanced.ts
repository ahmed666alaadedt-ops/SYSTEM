import {
  FieldValue,
  Timestamp,
  getFirestore
} from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

function database() {
  return getFirestore();
}

function uidOf(request: any): string {
  const uid = request.auth?.uid;
  if (typeof uid !== "string" || !uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  }
  return uid;
}

function textField(value: unknown, field: string, max = 128): string {
  if (typeof value !== "string" || !value.trim() || value.trim().length > max) {
    throw new HttpsError("invalid-argument", `حقل ${field} غير صالح.`);
  }
  return value.trim();
}

function amountField(value: unknown): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= 0 || value > 1_000_000_000) {
    throw new HttpsError("invalid-argument", "قيمة المزايدة غير صالحة.");
  }
  return value;
}

function itemRef(ownerId: string, artifactId: string) {
  return database().collection("artifactOwnership").doc(ownerId)
    .collection("items").doc(artifactId);
}

function walletRef(ownerId: string) {
  return database().collection("systemWallets").doc(ownerId);
}

function playerRef(ownerId: string) {
  return database().collection("players").doc(ownerId);
}

function appendArtifactHistory(
  transaction: FirebaseFirestore.Transaction,
  artifactId: string,
  eventId: string,
  data: Record<string, unknown>
): void {
  transaction.create(
    database().collection("artifactHistory").doc(artifactId)
      .collection("events").doc(eventId),
    { artifactId, ...data, createdAt: FieldValue.serverTimestamp() }
  );
}

/** Creates a player-owned auction and locks the artifact in escrow. */
export const createArtifactAuction = onCall(async (request) => {
  const sellerId = uidOf(request);
  const artifactId = textField(request.data?.artifactId, "artifactId", 120);
  const startingBid = amountField(request.data?.startingBid);
  const durationHours = Number.isInteger(request.data?.durationHours)
    ? Number(request.data.durationHours)
    : 24;
  if (durationHours < 1 || durationHours > 168) {
    throw new HttpsError("invalid-argument", "مدة المزاد يجب أن تكون بين ساعة وسبعة أيام.");
  }

  const auctionRef = database().collection("marketplaceAuctions").doc();
  const ownedItemRef = itemRef(sellerId, artifactId);
  const sellerWalletRef = walletRef(sellerId);
  const expiresAt = Timestamp.fromMillis(Date.now() + durationHours * 60 * 60 * 1000);

  await database().runTransaction(async (transaction) => {
    const [item, profile, wallet] = await Promise.all([
      transaction.get(ownedItemRef),
      transaction.get(playerRef(sellerId)),
      transaction.get(sellerWalletRef)
    ]);
    if (!item.exists || !profile.exists) {
      throw new HttpsError("not-found", "القطعة أو حساب البائع غير موجود.");
    }
    if (item.data()?.ownerId !== sellerId || item.data()?.status !== "owned") {
      throw new HttpsError("failed-precondition", "القطعة غير متاحة أو محجوزة مسبقاً.");
    }
    transaction.update(ownedItemRef, {
      status: "escrow",
      activeAuctionId: auctionRef.id,
      escrowAt: FieldValue.serverTimestamp()
    });
    if (!wallet.exists) {
      transaction.create(sellerWalletRef, {
        userId: sellerId,
        currency: "SYSTEM",
        balance: 0,
        reservedBalance: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
    }
    const artifact = item.data()!;
    transaction.create(auctionRef, {
      auctionId: auctionRef.id,
      artifactId,
      sellerId,
      sellerName: String(profile.data()?.displayName ?? "لاعب").slice(0, 40),
      name: artifact.name,
      civilization: artifact.civilization,
      rarity: artifact.rarity,
      condition: artifact.condition,
      authenticity: artifact.authenticity,
      provenanceSummary: artifact.provenanceSummary ?? "",
      startingBid,
      highestBid: 0,
      highestBidderId: null,
      highestBidderName: null,
      bidCount: 0,
      status: "active",
      currency: "SYSTEM",
      createdAt: FieldValue.serverTimestamp(),
      endsAt: expiresAt
    });
  });

  return { success: true, auctionId: auctionRef.id, expiresAt: expiresAt.toMillis() };
});

/** Lists active auctions; the server omits expired auctions. */
export const browseArtifactAuctions = onCall(async (request) => {
  const uid = uidOf(request);
  const snapshot = await database().collection("marketplaceAuctions")
    .where("status", "==", "active")
    .orderBy("endsAt", "asc")
    .limit(40)
    .get();

  return {
    auctions: snapshot.docs.filter((doc) => {
      const end = doc.data().endsAt;
      return end instanceof Timestamp && end.toMillis() > Date.now();
    }).map((doc) => {
      const data = doc.data();
      return {
        auctionId: doc.id,
        artifactId: data.artifactId,
        name: data.name,
        civilization: data.civilization,
        rarity: data.rarity,
        condition: data.condition,
        authenticity: data.authenticity,
        sellerName: data.sellerName,
        isSeller: data.sellerId === uid,
        startingBid: data.startingBid,
        highestBid: data.highestBid,
        highestBidderName: data.highestBidderName,
        bidCount: data.bidCount,
        endsAt: data.endsAt.toMillis(),
        currency: "SYSTEM"
      };
    })
  };
});

/**
 * Holds the current high bid in reservedBalance. When outbid, the prior
 * leader's reservation is released atomically with the new reservation.
 */
export const placeArtifactAuctionBid = onCall(async (request) => {
  const bidderId = uidOf(request);
  const auctionId = textField(request.data?.auctionId, "auctionId");
  const bidAmount = amountField(request.data?.amount);
  const auctionRef = database().collection("marketplaceAuctions").doc(auctionId);
  const bidRef = auctionRef.collection("bids").doc();

  const result = await database().runTransaction(async (transaction) => {
    const auctionSnapshot = await transaction.get(auctionRef);
    if (!auctionSnapshot.exists) throw new HttpsError("not-found", "المزاد غير موجود.");
    const auction = auctionSnapshot.data()!;
    if (auction.status !== "active" || !(auction.endsAt instanceof Timestamp) ||
        auction.endsAt.toMillis() <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "المزاد منتهٍ أو غير نشط.");
    }
    const sellerId = String(auction.sellerId ?? "");
    const previousBidderId = typeof auction.highestBidderId === "string"
      ? auction.highestBidderId
      : "";
    if (!sellerId || bidderId === sellerId) {
      throw new HttpsError("permission-denied", "لا يمكن للبائع المزايدة على قطعته.");
    }

    const highestBid = Number(auction.highestBid ?? 0);
    const startingBid = Number(auction.startingBid ?? 0);
    const minimumNextBid = highestBid > 0 ? highestBid + 1 : startingBid;
    if (bidAmount < minimumNextBid) {
      throw new HttpsError("failed-precondition", `أقل مزايدة مقبولة هي ${minimumNextBid}.`);
    }

    const bidderWalletRef = walletRef(bidderId);
    const previousWalletRef = previousBidderId && previousBidderId !== bidderId
      ? walletRef(previousBidderId)
      : null;
    const bidderProfileRef = playerRef(bidderId);
    const [bidderWallet, bidderProfile, previousWallet] = await Promise.all([
      transaction.get(bidderWalletRef),
      transaction.get(bidderProfileRef),
      previousWalletRef ? transaction.get(previousWalletRef) : Promise.resolve(null)
    ]);

    if (!bidderWallet.exists || !bidderProfile.exists) {
      throw new HttpsError("failed-precondition", "أنشئ محفظتك وسجّل الدخول مجدداً قبل المزايدة.");
    }
    const balance = Number(bidderWallet.data()?.balance ?? -1);
    const reserved = Number(bidderWallet.data()?.reservedBalance ?? 0);
    if (!Number.isSafeInteger(balance) || !Number.isSafeInteger(reserved) ||
        balance < 0 || reserved < 0 || reserved > balance) {
      throw new HttpsError("failed-precondition", "بيانات محفظتك غير صالحة.");
    }

    const isRaisingOwnBid = previousBidderId === bidderId;
    const additionalReservation = isRaisingOwnBid ? bidAmount - highestBid : bidAmount;
    if (balance - reserved < additionalReservation) {
      throw new HttpsError("failed-precondition", "الرصيد المتاح بعد الحجوزات غير كافٍ.");
    }

    if (previousWalletRef && previousWallet) {
      if (!previousWallet.exists) {
        throw new HttpsError("failed-precondition", "محفظة صاحب المزايدة السابقة غير موجودة.");
      }
      const previousReserved = Number(previousWallet.data()?.reservedBalance ?? 0);
      if (!Number.isSafeInteger(previousReserved) || previousReserved < highestBid) {
        throw new HttpsError("failed-precondition", "حجز المزايدة السابقة غير صالح.");
      }
      transaction.update(previousWalletRef, {
        reservedBalance: previousReserved - highestBid,
        updatedAt: FieldValue.serverTimestamp()
      });
    }

    transaction.update(bidderWalletRef, {
      reservedBalance: reserved + additionalReservation,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.create(bidRef, {
      bidId: bidRef.id,
      bidderId,
      bidderName: String(bidderProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      amount: bidAmount,
      createdAt: FieldValue.serverTimestamp()
    });

    const remainingMs = auction.endsAt.toMillis() - Date.now();
    const newEndsAt = remainingMs <= 120_000
      ? Timestamp.fromMillis(Date.now() + 120_000)
      : auction.endsAt;
    transaction.update(auctionRef, {
      highestBid: bidAmount,
      highestBidderId: bidderId,
      highestBidderName: String(bidderProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      bidCount: Number(auction.bidCount ?? 0) + 1,
      endsAt: newEndsAt,
      updatedAt: FieldValue.serverTimestamp()
    });

    return { success: true, auctionId, amount: bidAmount, endsAt: newEndsAt.toMillis() };
  });

  return result;
});

/** Anyone signed in may trigger settlement after the deadline; settlement is idempotent. */
async function settleExpiredAuctionById(auctionId: string) {
  const auctionRef = database().collection("marketplaceAuctions").doc(auctionId);
  const settlementRef = database().collection("marketplaceTransactions").doc();

  const result = await database().runTransaction(async (transaction) => {
    const auctionSnapshot = await transaction.get(auctionRef);
    if (!auctionSnapshot.exists) throw new HttpsError("not-found", "المزاد غير موجود.");
    const auction = auctionSnapshot.data()!;
    if (auction.status !== "active") {
      return { success: true, status: String(auction.status), alreadySettled: true };
    }
    if (!(auction.endsAt instanceof Timestamp) || auction.endsAt.toMillis() > Date.now()) {
      throw new HttpsError("failed-precondition", "لم ينتهِ وقت المزاد بعد.");
    }

    const sellerId = String(auction.sellerId ?? "");
    const artifactId = String(auction.artifactId ?? "");
    const sellerItemRef = itemRef(sellerId, artifactId);
    const sellerWalletDocument = walletRef(sellerId);
    const sellerItem = await transaction.get(sellerItemRef);
    if (!sellerItem.exists || sellerItem.data()?.activeAuctionId !== auctionId ||
        sellerItem.data()?.status !== "escrow") {
      throw new HttpsError("failed-precondition", "حجز القطعة لا يطابق المزاد.");
    }

    const highestBid = Number(auction.highestBid ?? 0);
    const winnerId = typeof auction.highestBidderId === "string"
      ? auction.highestBidderId
      : "";
    if (!winnerId || highestBid <= 0) {
      transaction.update(sellerItemRef, {
        status: "owned",
        activeAuctionId: FieldValue.delete(),
        escrowReleasedAt: FieldValue.serverTimestamp()
      });
      transaction.update(auctionRef, {
        status: "ended_without_bids",
        settledAt: FieldValue.serverTimestamp()
      });
      return { success: true, status: "ended_without_bids", auctionId };
    }

    const winnerWalletRef = walletRef(winnerId);
    const winnerItemRef = itemRef(winnerId, artifactId);
    const [sellerWallet, winnerWallet, winnerItem, sellerProfile, winnerProfile] = await Promise.all([
      transaction.get(sellerWalletDocument),
      transaction.get(winnerWalletRef),
      transaction.get(winnerItemRef),
      transaction.get(playerRef(sellerId)),
      transaction.get(playerRef(winnerId))
    ]);
    if (!sellerWallet.exists || !winnerWallet.exists || !sellerProfile.exists || !winnerProfile.exists) {
      throw new HttpsError("failed-precondition", "تعذر التحقق من محافظ أو حسابات أطراف المزاد.");
    }
    if (winnerItem.exists) {
      throw new HttpsError("already-exists", "الفائز يمتلك معرّف القطعة مسبقاً.");
    }
    const sellerBalance = Number(sellerWallet.data()?.balance ?? -1);
    const winnerBalance = Number(winnerWallet.data()?.balance ?? -1);
    const winnerReserved = Number(winnerWallet.data()?.reservedBalance ?? 0);
    if (!Number.isSafeInteger(sellerBalance) || sellerBalance < 0 ||
        !Number.isSafeInteger(winnerBalance) || winnerBalance < highestBid ||
        !Number.isSafeInteger(winnerReserved) || winnerReserved < highestBid || winnerReserved > winnerBalance ||
        sellerBalance + highestBid > Number.MAX_SAFE_INTEGER) {
      throw new HttpsError("failed-precondition", "الرصيد المحجوز لتسوية المزاد غير صالح.");
    }

    const artifact = sellerItem.data()!;
    const { activeAuctionId: _activeAuctionId, ...transferable } = artifact;
    transaction.update(winnerWalletRef, {
      balance: winnerBalance - highestBid,
      reservedBalance: winnerReserved - highestBid,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.update(sellerWalletDocument, {
      balance: sellerBalance + highestBid,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.delete(sellerItemRef);
    transaction.create(winnerItemRef, {
      ...transferable,
      ownerId: winnerId,
      status: "owned",
      acquiredAt: FieldValue.serverTimestamp(),
      lastTransferId: settlementRef.id
    });
    transaction.update(auctionRef, {
      status: "sold",
      winnerId,
      finalPrice: highestBid,
      transactionId: settlementRef.id,
      settledAt: FieldValue.serverTimestamp()
    });
    transaction.create(settlementRef, {
      transactionId: settlementRef.id,
      artifactId,
      auctionId,
      listingId: null,
      sellerId,
      buyerId: winnerId,
      sellerName: String(sellerProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      buyerName: String(winnerProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      price: highestBid,
      fee: 0,
      currency: "SYSTEM",
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.create(database().collection("marketplaceAudit").doc(settlementRef.id), {
      transactionId: settlementRef.id,
      artifactId,
      auctionId,
      sellerId,
      buyerId: winnerId,
      action: "auction_settled",
      createdAt: FieldValue.serverTimestamp()
    });
    appendArtifactHistory(transaction, artifactId, settlementRef.id, {
      auctionId,
      sellerId,
      buyerId: winnerId,
      action: "auction_transferred",
      price: highestBid,
      currency: "SYSTEM"
    });
    return {
      success: true,
      status: "sold",
      auctionId,
      transactionId: settlementRef.id,
      winnerId,
      finalPrice: highestBid
    };
  });

  return result;
}

/** Authenticated clients may settle a single auction after its deadline. */
export const settleExpiredArtifactAuction = onCall(async (request) => {
  uidOf(request);
  const auctionId = textField(request.data?.auctionId, "auctionId");
  return settleExpiredAuctionById(auctionId);
});

/** Settles expired auctions even when bidders and sellers are offline. */
export const settleExpiredArtifactAuctions = onSchedule("every 5 minutes", async () => {
  const now = Timestamp.now();
  const expiredAuctions = await database()
    .collection("marketplaceAuctions")
    .where("status", "==", "active")
    .where("endsAt", "<=", now)
    .limit(50)
    .get();

  let settledCount = 0;
  let skippedCount = 0;
  for (const candidate of expiredAuctions.docs) {
    try {
      await settleExpiredAuctionById(candidate.id);
      settledCount += 1;
    } catch (error) {
      skippedCount += 1;
      console.error("SYSTEM marketplace: failed to settle expired auction", candidate.id, error);
    }
  }
  console.info("SYSTEM marketplace expired auction sweep completed", {
    examined: expiredAuctions.size,
    settled: settledCount,
    skipped: skippedCount
  });
});

/** Seller may cancel an auction only before any bid has been accepted. */
export const cancelArtifactAuction = onCall(async (request) => {
  const sellerId = uidOf(request);
  const auctionId = textField(request.data?.auctionId, "auctionId");
  const auctionRef = database().collection("marketplaceAuctions").doc(auctionId);
  await database().runTransaction(async (transaction) => {
    const auctionSnapshot = await transaction.get(auctionRef);
    if (!auctionSnapshot.exists) throw new HttpsError("not-found", "المزاد غير موجود.");
    const auction = auctionSnapshot.data()!;
    if (auction.sellerId !== sellerId) {
      throw new HttpsError("permission-denied", "يمكن للبائع إلغاء مزاده فقط.");
    }
    if (auction.status !== "active" || Number(auction.bidCount ?? 0) > 0) {
      throw new HttpsError("failed-precondition", "لا يمكن إلغاء مزاد نشط تلقّى مزايدات.");
    }
    const artifactId = String(auction.artifactId);
    const ownedItemRef = itemRef(sellerId, artifactId);
    const item = await transaction.get(ownedItemRef);
    if (!item.exists || item.data()?.activeAuctionId !== auctionId) {
      throw new HttpsError("failed-precondition", "حجز القطعة لا يطابق المزاد.");
    }
    transaction.update(ownedItemRef, {
      status: "owned",
      activeAuctionId: FieldValue.delete(),
      escrowReleasedAt: FieldValue.serverTimestamp()
    });
    transaction.update(auctionRef, {
      status: "cancelled",
      cancelledAt: FieldValue.serverTimestamp()
    });
  });
  return { success: true, auctionId };
});

/** Creates a two-sided exchange offer and escrows the initiator's artifact. */
export const createArtifactExchangeOffer = onCall(async (request) => {
  const initiatorId = uidOf(request);
  const recipientId = textField(request.data?.recipientId, "recipientId");
  const offeredArtifactId = textField(request.data?.offeredArtifactId, "offeredArtifactId", 120);
  const requestedArtifactId = textField(request.data?.requestedArtifactId, "requestedArtifactId", 120);
  if (initiatorId === recipientId || offeredArtifactId === requestedArtifactId) {
    throw new HttpsError("invalid-argument", "لا يمكن إنشاء هذا التبادل.");
  }

  const offerRef = database().collection("marketplaceExchanges").doc();
  const offeredItemRef = itemRef(initiatorId, offeredArtifactId);
  const expiresAt = Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000);

  await database().runTransaction(async (transaction) => {
    const [offeredItem, initiatorProfile, recipientProfile, requestedRegistry] = await Promise.all([
      transaction.get(offeredItemRef),
      transaction.get(playerRef(initiatorId)),
      transaction.get(playerRef(recipientId)),
      transaction.get(database().collection("artifactRegistry").doc(requestedArtifactId))
    ]);
    if (!offeredItem.exists || !initiatorProfile.exists || !recipientProfile.exists ||
        !requestedRegistry.exists) {
      throw new HttpsError("not-found", "القطعة أو أحد حسابي التبادل غير موجود.");
    }
    if (offeredItem.data()?.ownerId !== initiatorId || offeredItem.data()?.status !== "owned") {
      throw new HttpsError("failed-precondition", "القطعة المعروضة ليست ملكك أو أنها محجوزة.");
    }
    transaction.update(offeredItemRef, {
      status: "escrow",
      activeExchangeId: offerRef.id,
      escrowAt: FieldValue.serverTimestamp()
    });
    transaction.create(offerRef, {
      exchangeId: offerRef.id,
      initiatorId,
      initiatorName: String(initiatorProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      recipientId,
      recipientName: String(recipientProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      offeredArtifactId,
      offeredArtifactName: offeredItem.data()?.name ?? "قطعة أثرية",
      requestedArtifactId,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      expiresAt
    });
  });

  return { success: true, exchangeId: offerRef.id, expiresAt: expiresAt.toMillis() };
});

/** Recipient explicitly accepts; both artifact ownership records swap atomically. */
export const acceptArtifactExchangeOffer = onCall(async (request) => {
  const recipientId = uidOf(request);
  const exchangeId = textField(request.data?.exchangeId, "exchangeId");
  const exchangeRef = database().collection("marketplaceExchanges").doc(exchangeId);
  const transactionRef = database().collection("marketplaceTransactions").doc();

  const result = await database().runTransaction(async (transaction) => {
    const exchangeSnapshot = await transaction.get(exchangeRef);
    if (!exchangeSnapshot.exists) throw new HttpsError("not-found", "عرض التبادل غير موجود.");
    const exchange = exchangeSnapshot.data()!;
    if (exchange.recipientId !== recipientId) {
      throw new HttpsError("permission-denied", "هذا العرض موجّه للاعب آخر.");
    }
    if (exchange.status !== "pending" ||
        !(exchange.expiresAt instanceof Timestamp) ||
        exchange.expiresAt.toMillis() <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "عرض التبادل منتهٍ أو لم يعد نشطاً.");
    }
    const initiatorId = String(exchange.initiatorId);
    const offeredArtifactId = String(exchange.offeredArtifactId);
    const requestedArtifactId = String(exchange.requestedArtifactId);
    const initiatorItemRef = itemRef(initiatorId, offeredArtifactId);
    const recipientItemRef = itemRef(recipientId, requestedArtifactId);
    const [initiatorItem, recipientItem] = await Promise.all([
      transaction.get(initiatorItemRef),
      transaction.get(recipientItemRef)
    ]);
    if (!initiatorItem.exists || initiatorItem.data()?.status !== "escrow" ||
        initiatorItem.data()?.activeExchangeId !== exchangeId ||
        initiatorItem.data()?.ownerId !== initiatorId) {
      throw new HttpsError("failed-precondition", "القطعة الأولى لم تعد محجوزة لهذا التبادل.");
    }
    if (!recipientItem.exists || recipientItem.data()?.status !== "owned" ||
        recipientItem.data()?.ownerId !== recipientId) {
      throw new HttpsError("failed-precondition", "القطعة المطلوبة ليست ملك اللاعب المستلم أو أنها محجوزة.");
    }

    const offered = initiatorItem.data()!;
    const requested = recipientItem.data()!;
    const { activeExchangeId: _activeExchangeId, ...offeredTransfer } = offered;
    const { activeExchangeId: _recipientExchangeId, ...requestedTransfer } = requested;
    const initiatorNewItemRef = itemRef(initiatorId, requestedArtifactId);
    const recipientNewItemRef = itemRef(recipientId, offeredArtifactId);

    transaction.delete(initiatorItemRef);
    transaction.delete(recipientItemRef);
    transaction.create(initiatorNewItemRef, {
      ...requestedTransfer,
      ownerId: initiatorId,
      status: "owned",
      acquiredAt: FieldValue.serverTimestamp(),
      lastTransferId: transactionRef.id
    });
    transaction.create(recipientNewItemRef, {
      ...offeredTransfer,
      ownerId: recipientId,
      status: "owned",
      acquiredAt: FieldValue.serverTimestamp(),
      lastTransferId: transactionRef.id
    });
    transaction.update(exchangeRef, {
      status: "accepted",
      acceptedAt: FieldValue.serverTimestamp(),
      transactionId: transactionRef.id
    });
    transaction.create(transactionRef, {
      transactionId: transactionRef.id,
      exchangeId,
      artifactIds: [offeredArtifactId, requestedArtifactId],
      sellerId: initiatorId,
      buyerId: recipientId,
      transactionType: "direct_exchange",
      price: 0,
      fee: 0,
      currency: "SYSTEM",
      createdAt: FieldValue.serverTimestamp()
    });
    appendArtifactHistory(transaction, offeredArtifactId, transactionRef.id + "_a", {
      exchangeId,
      sellerId: initiatorId,
      buyerId: recipientId,
      action: "exchanged"
    });
    appendArtifactHistory(transaction, requestedArtifactId, transactionRef.id + "_b", {
      exchangeId,
      sellerId: recipientId,
      buyerId: initiatorId,
      action: "exchanged"
    });
    return { success: true, exchangeId, transactionId: transactionRef.id };
  });

  return result;
});

/** Initiator cancels, or recipient declines, a pending offer and releases escrow. */
export const closeArtifactExchangeOffer = onCall(async (request) => {
  const actorId = uidOf(request);
  const exchangeId = textField(request.data?.exchangeId, "exchangeId");
  const action = request.data?.action;
  if (action !== "cancel" && action !== "decline" && action !== "expire") {
    throw new HttpsError("invalid-argument", "الإجراء غير صالح.");
  }
  const exchangeRef = database().collection("marketplaceExchanges").doc(exchangeId);

  await database().runTransaction(async (transaction) => {
    const exchangeSnapshot = await transaction.get(exchangeRef);
    if (!exchangeSnapshot.exists) throw new HttpsError("not-found", "عرض التبادل غير موجود.");
    const exchange = exchangeSnapshot.data()!;
    if (exchange.status !== "pending") {
      throw new HttpsError("failed-precondition", "عرض التبادل لم يعد معلقاً.");
    }
    if (action === "expire") {
      if (!(exchange.expiresAt instanceof Timestamp) || exchange.expiresAt.toMillis() > Date.now()) {
        throw new HttpsError("failed-precondition", "لم تنتهِ مدة عرض التبادل بعد.");
      }
    } else {
      const expectedActor = action === "cancel" ? exchange.initiatorId : exchange.recipientId;
      if (expectedActor !== actorId) {
        throw new HttpsError("permission-denied", "لا تملك صلاحية إغلاق هذا العرض.");
      }
    }
    const offeredArtifactId = String(exchange.offeredArtifactId);
    const initiatorItemRef = itemRef(String(exchange.initiatorId), offeredArtifactId);
    const item = await transaction.get(initiatorItemRef);
    if (!item.exists || item.data()?.activeExchangeId !== exchangeId) {
      throw new HttpsError("failed-precondition", "حجز القطعة لا يطابق عرض التبادل.");
    }
    transaction.update(initiatorItemRef, {
      status: "owned",
      activeExchangeId: FieldValue.delete(),
      escrowReleasedAt: FieldValue.serverTimestamp()
    });
    transaction.update(exchangeRef, {
      status: action === "cancel" ? "cancelled" : (action === "decline" ? "declined" : "expired"),
      closedBy: actorId,
      closedAt: FieldValue.serverTimestamp()
    });
  });

  return {
    success: true,
    exchangeId,
    status: action === "cancel" ? "cancelled" : (action === "decline" ? "declined" : "expired")
  };
});


/** Returns a bounded public bid history for an authenticated player. */
export const listArtifactAuctionBids = onCall(async (request) => {
  uidOf(request);
  const auctionId = textField(request.data?.auctionId, "auctionId");
  const auctionRef = database().collection("marketplaceAuctions").doc(auctionId);
  const auction = await auctionRef.get();
  if (!auction.exists) throw new HttpsError("not-found", "المزاد غير موجود.");
  const bids = await auctionRef.collection("bids")
    .orderBy("createdAt", "desc").limit(50).get();
  return {
    bids: bids.docs.map((doc) => {
      const data = doc.data();
      return {
        bidId: doc.id,
        bidderId: data.bidderId,
        bidderName: data.bidderName,
        amount: data.amount,
        createdAt: data.createdAt?.toMillis?.() ?? null
      };
    })
  };
});

/** Returns only exchange offers involving the authenticated player. */
export const listMyArtifactExchangeOffers = onCall(async (request) => {
  const uid = uidOf(request);
  const collection = database().collection("marketplaceExchanges");
  const [sent, received] = await Promise.all([
    collection.where("initiatorId", "==", uid).orderBy("createdAt", "desc").limit(40).get(),
    collection.where("recipientId", "==", uid).orderBy("createdAt", "desc").limit(40).get()
  ]);
  const mapOffer = (doc: FirebaseFirestore.QueryDocumentSnapshot) => {
    const data = doc.data();
    return {
      exchangeId: doc.id,
      initiatorId: data.initiatorId,
      initiatorName: data.initiatorName,
      recipientId: data.recipientId,
      recipientName: data.recipientName,
      offeredArtifactId: data.offeredArtifactId,
      offeredArtifactName: data.offeredArtifactName,
      requestedArtifactId: data.requestedArtifactId,
      status: data.status,
      expiresAt: data.expiresAt?.toMillis?.() ?? null,
      createdAt: data.createdAt?.toMillis?.() ?? null
    };
  };
  return {
    sent: sent.docs.map(mapOffer),
    received: received.docs.map(mapOffer)
  };
});


/** Releases escrow for expired player-to-player exchange offers automatically. */
export const releaseExpiredArtifactExchangeOffers = onSchedule("every 15 minutes", async () => {
  const now = Timestamp.now();
  const expiredOffers = await database()
    .collection("marketplaceExchanges")
    .where("status", "==", "pending")
    .where("expiresAt", "<=", now)
    .limit(100)
    .get();

  let releasedCount = 0;
  let skippedCount = 0;
  for (const candidate of expiredOffers.docs) {
    try {
      const released = await database().runTransaction(async (transaction) => {
        const offerSnapshot = await transaction.get(candidate.ref);
        if (!offerSnapshot.exists) return false;
        const offer = offerSnapshot.data()!;
        if (offer.status !== "pending" ||
            !(offer.expiresAt instanceof Timestamp) ||
            offer.expiresAt.toMillis() > now.toMillis()) {
          return false;
        }
        const initiatorId = String(offer.initiatorId ?? "");
        const artifactId = String(offer.offeredArtifactId ?? "");
        if (!initiatorId || !artifactId) {
          throw new Error("Expired exchange offer is missing its owner or artifact identity.");
        }
        const artifactRef = itemRef(initiatorId, artifactId);
        const artifactSnapshot = await transaction.get(artifactRef);
        if (!artifactSnapshot.exists ||
            artifactSnapshot.data()?.ownerId !== initiatorId ||
            artifactSnapshot.data()?.status !== "escrow" ||
            artifactSnapshot.data()?.activeExchangeId !== candidate.id) {
          throw new Error("Expired exchange escrow does not match the initiator's artifact.");
        }
        transaction.update(artifactRef, {
          status: "owned",
          activeExchangeId: FieldValue.delete(),
          escrowReleasedAt: FieldValue.serverTimestamp()
        });
        transaction.update(candidate.ref, {
          status: "expired",
          closedBy: "system_scheduler",
          closedAt: FieldValue.serverTimestamp()
        });
        return true;
      });
      if (released) releasedCount += 1;
    } catch (error) {
      skippedCount += 1;
      console.error("SYSTEM marketplace: failed to release expired exchange offer", candidate.id, error);
    }
  }

  console.info("SYSTEM marketplace expired exchange sweep completed", {
    examined: expiredOffers.size,
    released: releasedCount,
    skipped: skippedCount
  });
});
