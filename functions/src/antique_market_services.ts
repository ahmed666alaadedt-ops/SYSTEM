import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

const SECRET_TRADER_OFFERS = {
  secret_babylonian_star_engraving: {
    name: "نقش النجمة البابلي",
    sellerName: "تاجر بابل",
    traderId: "shadow_trader_01",
    civilization: "Babylonian",
    rarity: "mythic",
    condition: "excellent",
    price: 8500,
    authenticity: "verified",
    provenanceSummary: "سجل تاجر سري مختوم من أرشيف بابل"
  },
  secret_sumerian_oath_signet: {
    name: "ختم العهد السومري",
    sellerName: "جامع سومري",
    traderId: "shadow_trader_02",
    civilization: "Sumerian",
    rarity: "legendary",
    condition: "very_good",
    price: 6200,
    authenticity: "verified",
    provenanceSummary: "سجل منشأ سومري محفوظ لدى شبكة الجامعين"
  },
  secret_assyrian_library_key: {
    name: "مفتاح مكتبة آشور المفقودة",
    sellerName: "حارس مكتبة آشور",
    traderId: "shadow_trader_03",
    civilization: "Assyrian",
    rarity: "legendary",
    condition: "good",
    price: 7100,
    authenticity: "unverified",
    provenanceSummary: "قطعة نادرة تنتظر فحص مختبر الأصالة"
  },
  secret_sumerian_mirror_disc: {
    name: "قرص المرآة السومري",
    sellerName: "تاجر الآثار المجهولة",
    traderId: "shadow_trader_05",
    civilization: "Sumerian",
    rarity: "legendary",
    condition: "fair",
    price: 9400,
    authenticity: "unverified",
    provenanceSummary: "قطعة غامضة من مخزن لا يحمل سجلاً مكتملاً"
  },
  secret_akkadian_shadow_coin: {
    name: "عملة الظل الأكدي",
    sellerName: "تاجر الظلال الأكدي",
    traderId: "shadow_trader_04",
    civilization: "Akkadian",
    rarity: "mythic",
    condition: "excellent",
    price: 11200,
    authenticity: "verified",
    provenanceSummary: "عملة أثرية من مجموعة تاجر الظلال"
  }
} as const;

function authenticatedUid(request: any): string {
  if (!request.auth?.uid) throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  return String(request.auth.uid);
}

function cleanText(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string") throw new HttpsError("invalid-argument", `الحقل ${field} غير صالح.`);
  const result = value.trim();
  if (!result || result.length > maxLength) throw new HttpsError("invalid-argument", `تحقق من الحقل ${field}.`);
  return result;
}

export const browseSecretAntiqueOffers = onCall(async (request) => {
  authenticatedUid(request);
  return {
    offers: Object.entries(SECRET_TRADER_OFFERS).map(([offerId, offer]) => ({
      offerId,
      ...offer,
      sellerName: offer.sellerName,
      sellerType: "secret_trader"
    }))
  };
});

/** NPC secret-trader purchases use the same artifact registry, ownership and SYSTEM wallet as the player marketplace. */
export const purchaseSecretAntiqueOffer = onCall(async (request) => {
  const buyerId = authenticatedUid(request);
  const offerId = cleanText(request.data?.offerId, "offerId", 100);
  const eventId = cleanText(request.data?.eventId, "eventId", 100);
  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) throw new HttpsError("invalid-argument", "معرّف الشراء غير صالح.");
  const offer = SECRET_TRADER_OFFERS[offerId as keyof typeof SECRET_TRADER_OFFERS];
  if (!offer) throw new HttpsError("not-found", "عرض التاجر السري غير موجود.");
  const artifactId = `secret_${buyerId}_${offerId}`;
  const playerRef = db.collection("players").doc(buyerId);
  const walletRef = db.collection("systemWallets").doc(buyerId);
  const artifactRef = db.collection("artifactOwnership").doc(buyerId).collection("items").doc(artifactId);
  const registryRef = db.collection("artifactRegistry").doc(artifactId);
  const purchaseRef = db.collection("secretAntiquePurchases").doc(buyerId + "_" + offerId);
  const transactionRef = db.collection("marketplaceTransactions").doc("secret_" + buyerId + "_" + offerId);
  const historyRef = db.collection("artifactHistory").doc(artifactId).collection("events").doc("secret_purchase");

  return db.runTransaction(async (transaction) => {
    const [player, wallet, prior, registry, item] = await Promise.all([
      transaction.get(playerRef),
      transaction.get(walletRef),
      transaction.get(purchaseRef),
      transaction.get(registryRef),
      transaction.get(artifactRef)
    ]);
    if (!player.exists) throw new HttpsError("not-found", "حساب اللاعب غير موجود.");
    if (prior.exists) {
      const previous = prior.data()!;
      return { success: true, alreadyPurchased: true, artifactId: previous.artifactId, transactionId: previous.transactionId };
    }
    if (registry.exists || item.exists) throw new HttpsError("already-exists", "معرّف التحفة مستخدم مسبقاً.");
    if (!wallet.exists) throw new HttpsError("failed-precondition", "محفظة SYSTEM غير مهيأة.");
    const balance = Number(wallet.data()!.balance || 0);
    const reserved = Number(wallet.data()!.reservedBalance || 0);
    const available = balance - reserved;
    if (!Number.isSafeInteger(balance) || !Number.isSafeInteger(reserved) || available < offer.price) {
      throw new HttpsError("failed-precondition", "رصيد SYSTEM المتاح لا يكفي لشراء التحفة.");
    }
    const playerName = String(player.data()!.displayName || "لاعب").slice(0, 40);
    transaction.update(walletRef, {
      balance: balance - offer.price,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.create(registryRef, {
      artifactId,
      originalOwnerId: "secret_trader_guild",
      issuedAt: FieldValue.serverTimestamp(),
      source: "secret_trader"
    });
    transaction.create(artifactRef, {
      artifactId,
      ownerId: buyerId,
      ...offer,
      status: "owned",
      source: "secret_trader_purchase",
      acquiredAt: FieldValue.serverTimestamp(),
      createdBy: "secret_trader_guild"
    });
    transaction.create(transactionRef, {
      transactionId: transactionRef.id,
      artifactId,
      sellerId: "secret_trader_guild",
      buyerId,
      sellerName: offer.sellerName,
      buyerName: playerName,
      price: offer.price,
      fee: 0,
      currency: "SYSTEM",
      transactionType: "secret_trader_purchase",
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.create(historyRef, {
      artifactId,
      ownerId: buyerId,
      action: "purchased_from_secret_trader",
      sellerId: "secret_trader_guild",
      price: offer.price,
      currency: "SYSTEM",
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.create(purchaseRef, {
      eventId,
      buyerId,
      offerId,
      artifactId,
      transactionId: transactionRef.id,
      price: offer.price,
      createdAt: FieldValue.serverTimestamp()
    });
    return { success: true, alreadyPurchased: false, artifactId, transactionId: transactionRef.id, price: offer.price };
  });
});

/** Appraisal compares the owned item against its immutable global artifact registry and provenance trail. */
export const appraiseMyArtifactAuthenticity = onCall(async (request) => {
  const playerId = authenticatedUid(request);
  const artifactId = cleanText(request.data?.artifactId, "artifactId", 160);
  const itemRef = db.collection("artifactOwnership").doc(playerId).collection("items").doc(artifactId);
  const registryRef = db.collection("artifactRegistry").doc(artifactId);
  const reportId = encodeURIComponent(playerId + "_" + artifactId);
  const reportRef = db.collection("artifactAuthenticityAppraisals").doc(reportId);

  return db.runTransaction(async (transaction) => {
    const [itemSnapshot, registrySnapshot, existingReport] = await Promise.all([
      transaction.get(itemRef),
      transaction.get(registryRef),
      transaction.get(reportRef)
    ]);
    if (!itemSnapshot.exists) throw new HttpsError("not-found", "القطعة ليست ضمن مقتنياتك.");
    const item = itemSnapshot.data()!;
    if (item.ownerId !== playerId || item.status !== "owned" ||
        item.activeListingId || item.activeAuctionId || item.activeExchangeId) {
      throw new HttpsError("failed-precondition", "يجب أن تكون القطعة بحيازتك وغير محجوزة في السوق.");
    }
    if (existingReport.exists) {
      const previous = existingReport.data()!;
      return {
        success: true, reportId: reportRef.id, artifactId,
        verdict: String(previous.verdict || "unverified"),
        confidence: Number(previous.confidence || 0),
        reason: String(previous.reason || ""),
        provenanceSummary: String(previous.provenanceSummary || ""),
        alreadyAppraised: true
      };
    }
    const existingAuthenticity = String(item.authenticity || "unverified");
    const registry = registrySnapshot.exists ? registrySnapshot.data()! : null;
    let verdict = "unverified";
    let confidence = 25;
    let reason = "لا يوجد سجل عالمي كافٍ لإثبات منشأ القطعة.";
    if (existingAuthenticity === "replica") {
      verdict = "replica";
      confidence = 96;
      reason = "سجل القطعة يحددها كنسخة غير أصلية.";
    } else if (registry && String(registry.originalOwnerId || "").length > 0) {
      verdict = "verified";
      confidence = 94;
      reason = "تطابق معرّف القطعة مع سجل الإصدار العالمي وسجل الملكية.";
    }
    const report = {
      reportId: reportRef.id,
      playerId,
      artifactId,
      verdict,
      confidence,
      reason,
      registryMatched: registry !== null,
      originalOwnerId: registry ? String(registry.originalOwnerId || "") : null,
      provenanceSummary: String(item.provenanceSummary || ""),
      appraisedAt: FieldValue.serverTimestamp()
    };
    transaction.create(reportRef, report);
    transaction.update(itemRef, {
      authenticity: verdict,
      latestAppraisalId: reportRef.id,
      latestAppraisalConfidence: confidence,
      appraisedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
    return {
      success: true,
      reportId: reportRef.id,
      artifactId,
      verdict,
      confidence,
      reason,
      provenanceSummary: String(item.provenanceSummary || "")
    };
  });
});

/** Reputation is derived from completed marketplace transactions and recorded authenticity reports. */
export const getMyAntiquesReputation = onCall(async (request) => {
  const playerId = authenticatedUid(request);
  const [sales, purchases, appraisals] = await Promise.all([
    db.collection("marketplaceTransactions").where("sellerId", "==", playerId).limit(200).get(),
    db.collection("marketplaceTransactions").where("buyerId", "==", playerId).limit(200).get(),
    db.collection("artifactAuthenticityAppraisals").where("playerId", "==", playerId).limit(200).get()
  ]);
  const verifiedAppraisals = appraisals.docs.filter((doc) => doc.data().verdict === "verified").length;
  const replicaAppraisals = appraisals.docs.filter((doc) => doc.data().verdict === "replica").length;
  const score = Math.max(0, sales.size * 10 + purchases.size * 5 + verifiedAppraisals * 15 - replicaAppraisals * 30);
  const tier = score >= 1500 ? "grand_master" : score >= 700 ? "master" : score >= 300 ? "curator" : score >= 100 ? "collector" : "newcomer";
  return {
    playerId,
    score,
    tier,
    completedSales: sales.size,
    completedPurchases: purchases.size,
    verifiedAppraisals,
    replicaAppraisals,
    reputationSource: "server_derived_marketplace_and_appraisal_records"
  };
});
