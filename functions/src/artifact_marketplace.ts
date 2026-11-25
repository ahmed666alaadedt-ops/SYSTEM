import {
  FieldValue,
  Timestamp,
  getFirestore,
  type Query
} from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

function database() {
  return getFirestore();
}

const MAX_PRICE = 1_000_000_000;
const MARKETPLACE_FEE_BASIS_POINTS = 0;
const VALID_RARITIES = new Set([
  "common", "uncommon", "rare", "epic", "legendary", "mythic", "unique"
]);
const VALID_CONDITIONS = new Set([
  "pristine", "excellent", "good", "worn", "damaged", "restored"
]);

function authenticatedUid(request: any): string {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  }
  return String(request.auth.uid);
}

function requireModerator(request: any): string {
  const uid = authenticatedUid(request);
  if (request.auth.token.moderator !== true) {
    throw new HttpsError("permission-denied", "هذه العملية للمشرفين الموثوقين فقط.");
  }
  return uid;
}

function cleanText(value: unknown, maxLength: number, fieldName: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `حقل ${fieldName} غير صالح.`);
  }
  const clean = value.trim();
  if (!clean || clean.length > maxLength) {
    throw new HttpsError("invalid-argument", `حقل ${fieldName} غير صالح.`);
  }
  return clean;
}

function positiveInteger(value: unknown, fieldName: string): number {
  if (!Number.isSafeInteger(value) || Number(value) <= 0 || Number(value) > MAX_PRICE) {
    throw new HttpsError("invalid-argument", `قيمة ${fieldName} يجب أن تكون عدداً صحيحاً موجباً.`);
  }
  return Number(value);
}

function ownershipRef(uid: string, artifactId: string) {
  return database().collection("artifactOwnership").doc(uid)
    .collection("items").doc(artifactId);
}

function walletRef(uid: string) {
  return database().collection("systemWallets").doc(uid);
}

function playerRef(uid: string) {
  return database().collection("players").doc(uid);
}

/**
 * Creates a zero-balance authoritative SYSTEM currency wallet if absent.
 * This endpoint never accepts a client-supplied balance or grants currency.
 */
export const getMyMarketplaceWallet = onCall(async (request) => {
  const uid = authenticatedUid(request);
  const ref = walletRef(uid);
  await database().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      transaction.create(ref, {
        userId: uid,
        currency: "SYSTEM",
        balance: 0,
        reservedBalance: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
    }
  });
  const snapshot = await ref.get();
  return {
    currency: "SYSTEM",
    balance: Number(snapshot.data()?.balance ?? 0),
    reservedBalance: Number(snapshot.data()?.reservedBalance ?? 0),
    availableBalance: Number(snapshot.data()?.balance ?? 0) -
      Number(snapshot.data()?.reservedBalance ?? 0)
  };
});

/** Returns only the authenticated player's server-owned artifacts. */
export const listMyMarketplaceArtifacts = onCall(async (request) => {
  const uid = authenticatedUid(request);
  const snapshot = await database().collection("artifactOwnership").doc(uid)
    .collection("items").where("status", "==", "owned").limit(100).get();

  return {
    artifacts: snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        artifactId: doc.id,
        name: data.name,
        civilization: data.civilization,
        rarity: data.rarity,
        condition: data.condition,
        authenticity: data.authenticity,
        provenanceSummary: data.provenanceSummary
      };
    })
  };
});

/**
 * Only trusted game/admin reward services may mint an ownership record.
 * A normal player cannot claim arbitrary artifacts from the client.
 */
export const grantMarketplaceArtifact = onCall(async (request) => {
  const moderatorId = requireModerator(request);
  const ownerId = cleanText(request.data?.ownerId, 128, "ownerId");
  const artifactId = cleanText(request.data?.artifactId, 120, "artifactId");
  const name = cleanText(request.data?.name, 100, "name");
  const civilization = cleanText(request.data?.civilization, 60, "civilization");
  const rarity = cleanText(request.data?.rarity, 20, "rarity").toLowerCase();
  const condition = cleanText(request.data?.condition, 20, "condition").toLowerCase();
  const authenticity = cleanText(request.data?.authenticity, 30, "authenticity").toLowerCase();
  const provenanceSummary = typeof request.data?.provenanceSummary === "string"
    ? request.data.provenanceSummary.trim().slice(0, 500)
    : "";

  if (!VALID_RARITIES.has(rarity) || !VALID_CONDITIONS.has(condition)) {
    throw new HttpsError("invalid-argument", "تصنيف الندرة أو حالة القطعة غير صالح.");
  }
  if (!["verified", "unverified", "replica"].includes(authenticity)) {
    throw new HttpsError("invalid-argument", "حالة الأصالة غير صالحة.");
  }

  const ownerProfile = playerRef(ownerId);
  const itemRef = ownershipRef(ownerId, artifactId);
  const auditRef = database().collection("artifactOwnershipAudit").doc(artifactId);
  const registryRef = database().collection("artifactRegistry").doc(artifactId);

  await database().runTransaction(async (transaction) => {
    const [profile, existing, registry] = await Promise.all([
      transaction.get(ownerProfile),
      transaction.get(itemRef),
      transaction.get(registryRef)
    ]);
    if (!profile.exists) {
      throw new HttpsError("not-found", "حساب مالك القطعة غير موجود.");
    }
    if (existing.exists || registry.exists) {
      throw new HttpsError("already-exists", "معرّف القطعة مستخدم مسبقاً على مستوى العالم.");
    }
    transaction.create(registryRef, {
      artifactId,
      originalOwnerId: ownerId,
      issuedAt: FieldValue.serverTimestamp()
    });
    transaction.create(itemRef, {
      artifactId,
      ownerId,
      name,
      civilization,
      rarity,
      condition,
      authenticity,
      provenanceSummary,
      status: "owned",
      acquiredAt: FieldValue.serverTimestamp(),
      source: "trusted_reward_or_admin_grant",
      createdBy: moderatorId
    });
    transaction.create(auditRef, {
      artifactId,
      ownerId,
      action: "issued",
      actorId: moderatorId,
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.create(
      database().collection("artifactHistory").doc(artifactId)
        .collection("events").doc("issued"),
      {
        artifactId,
        ownerId,
        action: "issued",
        actorId: moderatorId,
        createdAt: FieldValue.serverTimestamp()
      }
    );
  });

  return { success: true, artifactId, ownerId };
});

/** Public authenticated read of active fixed-price listings. */
export const browseArtifactMarketplace = onCall(async (request) => {
  authenticatedUid(request);
  const civilization = typeof request.data?.civilization === "string"
    ? request.data.civilization.trim().slice(0, 60)
    : "";
  const rarity = typeof request.data?.rarity === "string"
    ? request.data.rarity.trim().toLowerCase()
    : "";

  let query: Query = database().collection("marketplaceListings")
    .where("status", "==", "active");

  if (civilization) query = query.where("civilization", "==", civilization);
  if (rarity && VALID_RARITIES.has(rarity)) query = query.where("rarity", "==", rarity);

  const snapshot = await query.orderBy("createdAt", "desc").limit(40).get();
  return {
    listings: snapshot.docs.filter((doc) => {
      const expiresAt = doc.data().expiresAt;
      return !(expiresAt instanceof Timestamp) || expiresAt.toMillis() > Date.now();
    }).map((doc) => {
      const data = doc.data();
      return {
        listingId: doc.id,
        artifactId: data.artifactId,
        name: data.name,
        civilization: data.civilization,
        rarity: data.rarity,
        condition: data.condition,
        authenticity: data.authenticity,
        provenanceSummary: data.provenanceSummary,
        price: data.price,
        currency: "SYSTEM",
        sellerId: data.sellerId,
        sellerName: data.sellerName,
        createdAt: data.createdAt?.toMillis?.() ?? null,
        expiresAt: data.expiresAt?.toMillis?.() ?? null
      };
    })
  };
});

/** Locks an actually-owned artifact in escrow and creates a fixed-price listing. */
export const createArtifactListing = onCall(async (request) => {
  const sellerId = authenticatedUid(request);
  const artifactId = cleanText(request.data?.artifactId, 120, "artifactId");
  const price = positiveInteger(request.data?.price, "price");
  const durationDays = Number.isInteger(request.data?.durationDays)
    ? Number(request.data.durationDays)
    : 7;

  if (durationDays < 1 || durationDays > 30) {
    throw new HttpsError("invalid-argument", "مدة العرض يجب أن تكون بين يوم و30 يوماً.");
  }

  const listingRef = database().collection("marketplaceListings").doc();
  const itemRef = ownershipRef(sellerId, artifactId);
  const sellerProfileRef = playerRef(sellerId);
  const expiresAt = Timestamp.fromMillis(Date.now() + durationDays * 24 * 60 * 60 * 1000);

  await database().runTransaction(async (transaction) => {
    const [itemSnapshot, sellerProfile] = await Promise.all([
      transaction.get(itemRef),
      transaction.get(sellerProfileRef)
    ]);
    if (!itemSnapshot.exists || !sellerProfile.exists) {
      throw new HttpsError("not-found", "القطعة أو ملف البائع غير موجود.");
    }
    const item = itemSnapshot.data()!;
    if (item.ownerId !== sellerId || item.status !== "owned") {
      throw new HttpsError("failed-precondition", "لا تملك هذه القطعة أو أنها محجوزة في صفقة أخرى.");
    }

    transaction.update(itemRef, {
      status: "escrow",
      activeListingId: listingRef.id,
      escrowAt: FieldValue.serverTimestamp()
    });
    transaction.create(listingRef, {
      listingId: listingRef.id,
      artifactId,
      sellerId,
      sellerName: String(sellerProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      name: item.name,
      civilization: item.civilization,
      rarity: item.rarity,
      condition: item.condition,
      authenticity: item.authenticity,
      provenanceSummary: item.provenanceSummary ?? "",
      price,
      currency: "SYSTEM",
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
      expiresAt
    });
  });

  return { success: true, listingId: listingRef.id, artifactId, price, expiresAt: expiresAt.toMillis() };
});

/** Cancels only the seller's own active listing and releases escrow. */
export const cancelArtifactListing = onCall(async (request) => {
  const sellerId = authenticatedUid(request);
  const listingId = cleanText(request.data?.listingId, 128, "listingId");
  const listingRef = database().collection("marketplaceListings").doc(listingId);

  await database().runTransaction(async (transaction) => {
    const listingSnapshot = await transaction.get(listingRef);
    if (!listingSnapshot.exists) throw new HttpsError("not-found", "العرض غير موجود.");
    const listing = listingSnapshot.data()!;
    if (listing.sellerId !== sellerId) {
      throw new HttpsError("permission-denied", "يمكن للبائع إلغاء عرضه فقط.");
    }
    if (listing.status !== "active") {
      throw new HttpsError("failed-precondition", "هذا العرض لم يعد نشطاً.");
    }
    const itemRef = ownershipRef(sellerId, String(listing.artifactId));
    const itemSnapshot = await transaction.get(itemRef);
    if (!itemSnapshot.exists || itemSnapshot.data()?.activeListingId !== listingId) {
      throw new HttpsError("failed-precondition", "سجل الحجز لا يطابق العرض.");
    }
    transaction.update(itemRef, {
      status: "owned",
      activeListingId: FieldValue.delete(),
      escrowReleasedAt: FieldValue.serverTimestamp()
    });
    transaction.update(listingRef, {
      status: "cancelled",
      cancelledAt: FieldValue.serverTimestamp()
    });
  });

  return { success: true, listingId };
});

/**
 * Atomic settlement: exactly one buyer can win a listing.
 * The artifact transfer, wallet debit/credit, listing close and audit record
 * are committed together in one Firestore transaction.
 */
export const purchaseArtifactListing = onCall(async (request) => {
  const buyerId = authenticatedUid(request);
  const listingId = cleanText(request.data?.listingId, 128, "listingId");
  const listingRef = database().collection("marketplaceListings").doc(listingId);
  const transactionRef = database().collection("marketplaceTransactions").doc();
  const auditRef = database().collection("marketplaceAudit").doc(transactionRef.id);

  const result = await database().runTransaction(async (transaction) => {
    const listingSnapshot = await transaction.get(listingRef);
    if (!listingSnapshot.exists) throw new HttpsError("not-found", "العرض غير موجود.");
    const listing = listingSnapshot.data()!;
    const sellerId = String(listing.sellerId ?? "");
    const artifactId = String(listing.artifactId ?? "");
    if (listing.status !== "active") {
      throw new HttpsError("failed-precondition", "تم بيع القطعة أو إلغاء عرضها مسبقاً.");
    }
    if (listing.expiresAt instanceof Timestamp && listing.expiresAt.toMillis() <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "انتهت مدة عرض القطعة.");
    }
    if (!sellerId || !artifactId || sellerId === buyerId) {
      throw new HttpsError("failed-precondition", "لا يمكن شراء هذا العرض.");
    }

    const price = positiveInteger(listing.price, "price");
    const fee = Math.floor(price * MARKETPLACE_FEE_BASIS_POINTS / 10_000);
    const sellerCredit = price - fee;
    const buyerWalletRef = walletRef(buyerId);
    const sellerWalletRef = walletRef(sellerId);
    const buyerItemRef = ownershipRef(buyerId, artifactId);
    const sellerItemRef = ownershipRef(sellerId, artifactId);
    const buyerProfileRef = playerRef(buyerId);
    const sellerProfileRef = playerRef(sellerId);

    const [
      buyerWallet, sellerWallet, sellerItem, buyerItem,
      buyerProfile, sellerProfile
    ] = await Promise.all([
      transaction.get(buyerWalletRef),
      transaction.get(sellerWalletRef),
      transaction.get(sellerItemRef),
      transaction.get(buyerItemRef),
      transaction.get(buyerProfileRef),
      transaction.get(sellerProfileRef)
    ]);

    if (!buyerWallet.exists || !sellerWallet.exists) {
      throw new HttpsError("failed-precondition", "محفظة أحد الطرفين غير مهيأة.");
    }
    if (!buyerProfile.exists || !sellerProfile.exists) {
      throw new HttpsError("failed-precondition", "ملف أحد اللاعبين غير موجود.");
    }
    if (buyerItem.exists) {
      throw new HttpsError("already-exists", "يمتلك المشتري قطعة بهذا المعرّف مسبقاً.");
    }
    const buyerBalance = Number(buyerWallet.data()?.balance ?? -1);
    const buyerReserved = Number(buyerWallet.data()?.reservedBalance ?? 0);
    const sellerBalance = Number(sellerWallet.data()?.balance ?? -1);
    if (!Number.isSafeInteger(buyerBalance) || buyerBalance < price ||
        !Number.isSafeInteger(buyerReserved) || buyerReserved < 0 ||
        buyerReserved > buyerBalance || buyerBalance - buyerReserved < price ||
        !Number.isSafeInteger(sellerBalance) || sellerBalance < 0 ||
        sellerBalance + sellerCredit > Number.MAX_SAFE_INTEGER) {
      throw new HttpsError("failed-precondition", "رصيد المشتري غير كافٍ أو بيانات المحفظة غير صالحة.");
    }
    if (!sellerItem.exists ||
        sellerItem.data()?.ownerId !== sellerId ||
        sellerItem.data()?.status !== "escrow" ||
        sellerItem.data()?.activeListingId !== listingId) {
      throw new HttpsError("failed-precondition", "ملكية القطعة أو حجزها غير صالح.");
    }

    const item = sellerItem.data()!;
    const { activeListingId: _activeListingId, ...transferableItem } = item;
    transaction.update(buyerWalletRef, {
      balance: buyerBalance - price,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.update(sellerWalletRef, {
      balance: sellerBalance + sellerCredit,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.delete(sellerItemRef);
    transaction.create(buyerItemRef, {
      ...transferableItem,
      ownerId: buyerId,
      status: "owned",
      acquiredAt: FieldValue.serverTimestamp(),
      lastTransferId: transactionRef.id
    });
    transaction.update(listingRef, {
      status: "sold",
      buyerId,
      soldAt: FieldValue.serverTimestamp(),
      transactionId: transactionRef.id
    });
    transaction.create(transactionRef, {
      transactionId: transactionRef.id,
      artifactId,
      listingId,
      sellerId,
      buyerId,
      sellerName: String(sellerProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      buyerName: String(buyerProfile.data()?.displayName ?? "لاعب").slice(0, 40),
      price,
      fee,
      currency: "SYSTEM",
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.create(auditRef, {
      transactionId: transactionRef.id,
      artifactId,
      listingId,
      sellerId,
      buyerId,
      action: "sold_and_transferred",
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.create(
      database().collection("artifactHistory").doc(artifactId)
        .collection("events").doc(transactionRef.id),
      {
        transactionId: transactionRef.id,
        artifactId,
        listingId,
        sellerId,
        buyerId,
        action: "sold_and_transferred",
        price,
        currency: "SYSTEM",
        createdAt: FieldValue.serverTimestamp()
      }
    );
    return {
      success: true,
      transactionId: transactionRef.id,
      artifactId,
      price,
      currency: "SYSTEM",
      sellerCredit
    };
  });

  return result;
});


/** Releases an expired listing from escrow without allowing another player to cancel a live offer. */
export const expireArtifactListing = onCall(async (request) => {
  authenticatedUid(request);
  const listingId = cleanText(request.data?.listingId, 128, "listingId");
  const listingRef = database().collection("marketplaceListings").doc(listingId);

  await database().runTransaction(async (transaction) => {
    const listingSnapshot = await transaction.get(listingRef);
    if (!listingSnapshot.exists) throw new HttpsError("not-found", "العرض غير موجود.");
    const listing = listingSnapshot.data()!;
    if (listing.status !== "active") {
      throw new HttpsError("failed-precondition", "العرض لم يعد نشطاً.");
    }
    if (!(listing.expiresAt instanceof Timestamp) || listing.expiresAt.toMillis() > Date.now()) {
      throw new HttpsError("failed-precondition", "لم تنتهِ مدة العرض بعد.");
    }
    const sellerId = String(listing.sellerId);
    const artifactId = String(listing.artifactId);
    const itemRef = ownershipRef(sellerId, artifactId);
    const item = await transaction.get(itemRef);
    if (!item.exists || item.data()?.activeListingId !== listingId ||
        item.data()?.status !== "escrow") {
      throw new HttpsError("failed-precondition", "حجز القطعة لا يطابق العرض.");
    }
    transaction.update(itemRef, {
      status: "owned",
      activeListingId: FieldValue.delete(),
      escrowReleasedAt: FieldValue.serverTimestamp()
    });
    transaction.update(listingRef, {
      status: "expired",
      expiredAt: FieldValue.serverTimestamp()
    });
  });

  return { success: true, listingId, status: "expired" };
});

/** Returns the authenticated player's purchase and sale receipts. */
export const listMyMarketplaceTransactions = onCall(async (request) => {
  const uid = authenticatedUid(request);
  const collection = database().collection("marketplaceTransactions");
  const [purchases, sales] = await Promise.all([
    collection.where("buyerId", "==", uid).orderBy("createdAt", "desc").limit(50).get(),
    collection.where("sellerId", "==", uid).orderBy("createdAt", "desc").limit(50).get()
  ]);
  const records = new Map<string, Record<string, unknown>>();
  for (const doc of [...purchases.docs, ...sales.docs]) {
    const data = doc.data();
    records.set(doc.id, {
      transactionId: doc.id,
      artifactId: data.artifactId ?? null,
      artifactIds: data.artifactIds ?? null,
      listingId: data.listingId ?? null,
      auctionId: data.auctionId ?? null,
      exchangeId: data.exchangeId ?? null,
      sellerId: data.sellerId,
      buyerId: data.buyerId,
      sellerName: data.sellerName ?? null,
      buyerName: data.buyerName ?? null,
      transactionType: data.transactionType ?? "sale",
      price: data.price ?? 0,
      currency: data.currency ?? "SYSTEM",
      createdAt: data.createdAt?.toMillis?.() ?? 0
    });
  }
  return {
    transactions: [...records.values()]
      .sort((a, b) => Number(b.createdAt) - Number(a.createdAt))
      .slice(0, 50)
  };
});


/**
 * Replay-safe artifact reward issuance for the trusted game-server identity.
 * Event IDs prevent retrying a quest reward from minting a second artifact.
 */
export const grantMarketplaceArtifactFromReward = onCall(async (request) => {
  if (!request.auth?.uid || request.auth.token.gameServer !== true) {
    throw new HttpsError("permission-denied", "إصدار القطع متاح لخادم اللعبة الموثوق فقط.");
  }
  const gameServerUid = String(request.auth.uid);
  const ownerId = cleanText(request.data?.playerId, 128, "playerId");
  const eventId = cleanText(request.data?.eventId, 100, "eventId");
  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) {
    throw new HttpsError("invalid-argument", "معرّف حدث المكافأة غير صالح.");
  }
  const artifactId = cleanText(request.data?.artifactId, 120, "artifactId");
  const name = cleanText(request.data?.name, 100, "name");
  const civilization = cleanText(request.data?.civilization, 60, "civilization");
  const rarity = cleanText(request.data?.rarity, 20, "rarity").toLowerCase();
  const condition = cleanText(request.data?.condition, 20, "condition").toLowerCase();
  const authenticity = cleanText(request.data?.authenticity, 30, "authenticity").toLowerCase();
  const source = cleanText(request.data?.source, 40, "source");
  const referenceId = typeof request.data?.referenceId === "string"
    ? request.data.referenceId.slice(0, 160)
    : "";

  if (!VALID_RARITIES.has(rarity) || !VALID_CONDITIONS.has(condition) ||
      !["verified", "unverified", "replica"].includes(authenticity)) {
    throw new HttpsError("invalid-argument", "بيانات القطعة أو أصالتها غير صالحة.");
  }
  if (!["verified_quest", "hunter_guild_mission", "dungeon_clear", "system_event"].includes(source)) {
    throw new HttpsError("invalid-argument", "مصدر مكافأة القطعة غير معتمد.");
  }

  const player = playerRef(ownerId);
  const item = ownershipRef(ownerId, artifactId);
  const registry = database().collection("artifactRegistry").doc(artifactId);
  const event = database().collection("artifactRewardEvents").doc(gameServerUid + "_" + ownerId + "_" + eventId);
  const history = database().collection("artifactHistory").doc(artifactId)
    .collection("events").doc("reward_" + eventId);

  return database().runTransaction(async (transaction) => {
    const [playerSnapshot, itemSnapshot, registrySnapshot, eventSnapshot] = await Promise.all([
      transaction.get(player),
      transaction.get(item),
      transaction.get(registry),
      transaction.get(event)
    ]);
    if (!playerSnapshot.exists) throw new HttpsError("not-found", "حساب اللاعب غير موجود.");
    if (eventSnapshot.exists) {
      const prior = eventSnapshot.data()!;
      if (prior.playerId !== ownerId || prior.artifactId !== artifactId || prior.source !== source) {
        throw new HttpsError("already-exists", "معرّف الحدث مستخدم لمكافأة مختلفة.");
      }
      return { success: true, alreadyIssued: true, artifactId, ownerId };
    }
    if (itemSnapshot.exists || registrySnapshot.exists) {
      throw new HttpsError("already-exists", "معرّف القطعة مستخدم مسبقاً عالمياً.");
    }

    transaction.create(registry, {
      artifactId,
      originalOwnerId: ownerId,
      issuedAt: FieldValue.serverTimestamp()
    });
    transaction.create(item, {
      artifactId,
      ownerId,
      name,
      civilization,
      rarity,
      condition,
      authenticity,
      provenanceSummary: typeof request.data?.provenanceSummary === "string"
        ? request.data.provenanceSummary.trim().slice(0, 500)
        : "",
      status: "owned",
      acquiredAt: FieldValue.serverTimestamp(),
      source,
      referenceId,
      createdByGameServer: gameServerUid
    });
    transaction.create(event, {
      eventId,
      playerId: ownerId,
      artifactId,
      source,
      referenceId,
      gameServerUid,
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.create(history, {
      artifactId,
      ownerId,
      action: "issued_as_game_reward",
      source,
      referenceId,
      actorId: gameServerUid,
      createdAt: FieldValue.serverTimestamp()
    });
    return { success: true, alreadyIssued: false, artifactId, ownerId };
  });
});
