import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

function database() {
  return getFirestore();
}

function requireGameServer(request: any): string {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "يجب التحقق من هوية خادم اللعبة.");
  }
  if (request.auth.token.gameServer !== true) {
    throw new HttpsError(
      "permission-denied",
      "إضافة أرصدة المكافآت متاحة لخادم اللعبة الموثوق فقط."
    );
  }
  return String(request.auth.uid);
}

/**
 * Replay-safe server reward for the virtual SYSTEM currency.
 * The game client cannot mint credits: only a Firebase identity with the
 * gameServer custom claim can call this endpoint. A server event is credited
 * once, and wallet + immutable award record commit atomically.
 */
export const awardMarketplaceCurrency = onCall(async (request) => {
  const gameServerUid = requireGameServer(request);
  const playerId = request.data?.playerId;
  const eventId = request.data?.eventId;
  const source = request.data?.source;
  const referenceId = request.data?.referenceId;
  const amount = request.data?.amount;

  if (typeof playerId !== "string" || !playerId.trim() || playerId.length > 128) {
    throw new HttpsError("invalid-argument", "معرّف اللاعب غير صالح.");
  }
  if (typeof eventId !== "string" || !/^[A-Za-z0-9_-]{1,100}$/.test(eventId)) {
    throw new HttpsError("invalid-argument", "معرّف حدث المكافأة غير صالح.");
  }
  if (
    typeof amount !== "number" ||
    !Number.isSafeInteger(amount) ||
    amount < 1 ||
    amount > 1_000_000
  ) {
    throw new HttpsError("invalid-argument", "قيمة المكافأة خارج الحدود المسموحة.");
  }

  const allowedSources = new Set([
    "verified_quest",
    "hunter_guild_mission",
    "dungeon_clear",
    "system_event",
    "admin_compensation"
  ]);
  if (typeof source !== "string" || !allowedSources.has(source)) {
    throw new HttpsError("invalid-argument", "مصدر المكافأة غير معتمد.");
  }
  if (referenceId !== undefined &&
      (typeof referenceId !== "string" || referenceId.length > 160)) {
    throw new HttpsError("invalid-argument", "مرجع المكافأة غير صالح.");
  }

  const db = database();
  const playerRef = db.collection("players").doc(playerId);
  const walletRef = db.collection("systemWallets").doc(playerId);
  const awardId = gameServerUid + "_" + playerId + "_" + eventId;
  const awardRef = db.collection("marketplaceCurrencyAwards").doc(awardId);

  return db.runTransaction(async (transaction) => {
    const [playerSnapshot, walletSnapshot, awardSnapshot] = await Promise.all([
      transaction.get(playerRef),
      transaction.get(walletRef),
      transaction.get(awardRef)
    ]);

    if (!playerSnapshot.exists) {
      throw new HttpsError("not-found", "حساب اللاعب غير موجود.");
    }

    if (awardSnapshot.exists) {
      const previous = awardSnapshot.data()!;
      if (
        previous.playerId !== playerId ||
        previous.amount !== amount ||
        previous.source !== source
      ) {
        throw new HttpsError(
          "already-exists",
          "معرّف الحدث مستخدم مسبقاً بمعلومات مكافأة مختلفة."
        );
      }
      return {
        success: true,
        alreadyAwarded: true,
        awardId,
        balance: Number(walletSnapshot.data()?.balance ?? 0)
      };
    }

    const currentBalance = walletSnapshot.exists
      ? walletSnapshot.data()?.balance
      : 0;
    if (
      typeof currentBalance !== "number" ||
      !Number.isSafeInteger(currentBalance) ||
      currentBalance < 0 ||
      currentBalance + amount > Number.MAX_SAFE_INTEGER
    ) {
      throw new HttpsError("failed-precondition", "رصيد المحفظة الحالي غير صالح.");
    }

    const newBalance = currentBalance + amount;
    const walletData = {
      userId: playerId,
      currency: "SYSTEM",
      balance: newBalance,
      updatedAt: FieldValue.serverTimestamp()
    };

    if (walletSnapshot.exists) {
      transaction.update(walletRef, walletData);
    } else {
      transaction.create(walletRef, {
        ...walletData,
        reservedBalance: 0,
        createdAt: FieldValue.serverTimestamp()
      });
    }

    transaction.create(awardRef, {
      awardId,
      playerId,
      amount,
      currency: "SYSTEM",
      source,
      referenceId: typeof referenceId === "string" ? referenceId : null,
      gameServerUid,
      balanceAfter: newBalance,
      createdAt: FieldValue.serverTimestamp()
    });

    return {
      success: true,
      alreadyAwarded: false,
      awardId,
      amount,
      balance: newBalance
    };
  });
});
