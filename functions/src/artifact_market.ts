import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();
const MAX_PRICE = 1_000_000_000;

function uidOf(request: any): string {
  if (!request.auth) throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  return request.auth.uid;
}
function textArg(value: unknown, name: string): string {
  if (typeof value !== "string" || !value.trim() || value.trim().length > 128) {
    throw new HttpsError("invalid-argument", `قيمة ${name} غير صالحة.`);
  }
  return value.trim();
}
function priceArg(value: unknown): number {
  if (!Number.isSafeInteger(value) || Number(value) < 1 || Number(value) > MAX_PRICE) {
    throw new HttpsError("invalid-argument", "السعر غير صالح.");
  }
  return Number(value);
}
const wallet = (uid: string) => db.collection("marketWallets").doc(uid);
const artifact = (uid: string, id: string) => db.collection("playerArtifacts").doc(uid).collection("items").doc(id);
const listing = (id: string) => db.collection("artifactMarketListings").doc(id);

/** Trusted rewards/admin flows must provision these server-only wallet and artifact documents. */
export const createArtifactListing = onCall(async (request) => {
  const uid = uidOf(request);
  const itemId = textArg(request.data?.itemId, "itemId");
  const price = priceArg(request.data?.price);
  const itemRef = artifact(uid, itemId);
  const listingRef = db.collection("artifactMarketListings").doc();
  return db.runTransaction(async (tx) => {
    const itemSnap = await tx.get(itemRef);
    if (!itemSnap.exists) throw new HttpsError("not-found", "التحفة غير موجودة في مقتنياتك.");
    const item = itemSnap.data()!;
    if (item.ownerUid !== uid || item.status !== "owned" || item.listingId) {
      throw new HttpsError("failed-precondition", "التحفة غير متاحة للبيع أو معروضة مسبقاً.");
    }
    const safeItem = {
      itemId, name: String(item.name || itemId).slice(0, 120),
      rarity: String(item.rarity || "unclassified").slice(0, 32),
      era: String(item.era || "").slice(0, 120),
      provenance: String(item.provenance || "").slice(0, 1000),
      skillRewardId: typeof item.skillRewardId === "string" ? item.skillRewardId.slice(0, 128) : null
    };
    tx.create(listingRef, { sellerUid: uid, itemId, item: safeItem, price,
      currency: "SYSTEM_CREDITS", status: "open",
      createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
    tx.update(itemRef, { status: "listed", listingId: listingRef.id, updatedAt: FieldValue.serverTimestamp() });
    return { listingId: listingRef.id, item: safeItem, price, status: "open" };
  });
});

export const listOpenArtifactListings = onCall(async (request) => {
  uidOf(request);
  const requested = request.data?.pageSize;
  const pageSize = Number.isSafeInteger(requested) ? Math.min(50, Math.max(1, Number(requested))) : 25;
  const snap = await db.collection("artifactMarketListings").where("status", "==", "open")
    .orderBy("createdAt", "desc").limit(pageSize).get();
  return { listings: snap.docs.map((doc) => {
    const d = doc.data();
    return { listingId: doc.id, sellerUid: d.sellerUid, item: d.item,
      price: d.price, currency: d.currency, createdAt: d.createdAt?.toMillis?.() ?? null };
  }) };
});

export const purchaseArtifactListing = onCall(async (request) => {
  const buyerUid = uidOf(request);
  const listingId = textArg(request.data?.listingId, "listingId");
  const listingDoc = listing(listingId);
  return db.runTransaction(async (tx) => {
    const listingSnap = await tx.get(listingDoc);
    if (!listingSnap.exists) throw new HttpsError("not-found", "إعلان التحفة غير موجود.");
    const ad = listingSnap.data()!;
    if (ad.status !== "open") throw new HttpsError("failed-precondition", "الإعلان مباع أو مسحوب.");
    const sellerUid = String(ad.sellerUid || "");
    const itemId = String(ad.itemId || "");
    const price = Number(ad.price);
    if (!sellerUid || !itemId || !Number.isSafeInteger(price) || price < 1 || price > MAX_PRICE) {
      throw new HttpsError("data-loss", "بيانات الإعلان غير سليمة.");
    }
    if (sellerUid === buyerUid) throw new HttpsError("failed-precondition", "لا يمكنك شراء تحفتك.");
    const buyerWallet = wallet(buyerUid), sellerWallet = wallet(sellerUid);
    const sellerItem = artifact(sellerUid, itemId), buyerItem = artifact(buyerUid, itemId);
    const [bw, sw, si, bi] = await Promise.all([tx.get(buyerWallet), tx.get(sellerWallet), tx.get(sellerItem), tx.get(buyerItem)]);
    if (!bw.exists || !sw.exists) throw new HttpsError("failed-precondition", "محفظة أحد الطرفين غير مهيأة على الخادم.");
    if (!si.exists || si.data()?.ownerUid !== sellerUid || si.data()?.status !== "listed" || si.data()?.listingId !== listingId) {
      throw new HttpsError("failed-precondition", "قفل التحفة أو ملكيتها غير متطابق.");
    }
    if (bi.exists) throw new HttpsError("already-exists", "يوجد عنصر بالمعرّف نفسه لدى المشتري.");
    const buyerBalance = Number(bw.data()?.balance), sellerBalance = Number(sw.data()?.balance);
    if (!Number.isSafeInteger(buyerBalance) || buyerBalance < price ||
        !Number.isSafeInteger(sellerBalance) || sellerBalance < 0 || sellerBalance + price > Number.MAX_SAFE_INTEGER) {
      throw new HttpsError("failed-precondition", "رصيد المشتري غير كافٍ أو بيانات المحفظة غير سليمة.");
    }
    tx.update(buyerWallet, { balance: buyerBalance - price, updatedAt: FieldValue.serverTimestamp() });
    tx.update(sellerWallet, { balance: sellerBalance + price, updatedAt: FieldValue.serverTimestamp() });
    tx.delete(sellerItem);
    tx.create(buyerItem, { ...si.data(), ownerUid: buyerUid, status: "owned", listingId: null,
      acquiredAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), lastPurchaseListingId: listingId });
    tx.update(listingDoc, { status: "sold", buyerUid, soldAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
    tx.create(db.collection("artifactMarketTransactions").doc(listingId), {
      listingId, itemId, sellerUid, buyerUid, amount: price, currency: "SYSTEM_CREDITS",
      status: "settled", createdAt: FieldValue.serverTimestamp()
    });
    return { listingId, itemId, sellerUid, buyerUid, amount: price, currency: "SYSTEM_CREDITS", status: "sold" };
  });
});

export const cancelArtifactListing = onCall(async (request) => {
  const uid = uidOf(request);
  const listingId = textArg(request.data?.listingId, "listingId");
  const listingDoc = listing(listingId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(listingDoc);
    if (!snap.exists) throw new HttpsError("not-found", "الإعلان غير موجود.");
    const ad = snap.data()!;
    if (ad.sellerUid !== uid) throw new HttpsError("permission-denied", "البائع فقط يسحب الإعلان.");
    if (ad.status !== "open") throw new HttpsError("failed-precondition", "الإعلان لم يعد مفتوحاً.");
    const itemId = String(ad.itemId || "");
    const itemRef = artifact(uid, itemId);
    const itemSnap = await tx.get(itemRef);
    if (!itemSnap.exists || itemSnap.data()?.status !== "listed" || itemSnap.data()?.listingId !== listingId) {
      throw new HttpsError("failed-precondition", "تعذر التحقق من حجز التحفة.");
    }
    tx.update(itemRef, { status: "owned", listingId: null, updatedAt: FieldValue.serverTimestamp() });
    tx.update(listingDoc, { status: "cancelled", cancelledAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
    return { listingId, itemId, status: "cancelled" };
  });
});
