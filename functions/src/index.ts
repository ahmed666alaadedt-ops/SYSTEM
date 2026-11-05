import { initializeApp } from "firebase-admin/app";
import {
  FieldValue,
  Timestamp,
  getFirestore
} from "firebase-admin/firestore";

import {
  HttpsError,
  onCall
} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();

/**
 * إرسال رسالة دردشة عالمية.
 * الرسالة تبقى pending ولا تظهر للاعبين
 * إلا بعد موافقة المشرف.
 */
export const submitGlobalMessage = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "يجب تسجيل الدخول أولاً."
      );
    }

    const uid = request.auth.uid;
    const text = request.data?.text;

    if (
      typeof text !== "string" ||
      text.trim().length === 0 ||
      text.trim().length > 1000
    ) {
      throw new HttpsError(
        "invalid-argument",
        "الرسالة غير صالحة أو تتجاوز 1000 حرف."
      );
    }

    const banRef = db.collection("bannedUsers").doc(uid);
    const playerRef = db.collection("players").doc(uid);
    const messageRef = db.collection("globalMessages").doc();

    const result = await db.runTransaction(async (transaction) => {
      const banSnapshot = await transaction.get(banRef);
      const playerSnapshot = await transaction.get(playerRef);

      if (!playerSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "ملف اللاعب غير موجود."
        );
      }

      if (banSnapshot.exists) {
        const ban = banSnapshot.data()!;

        if (ban.active === true) {
          if (ban.permanent === true) {
            throw new HttpsError(
              "permission-denied",
              "تم منع حسابك من استخدام الدردشة نهائياً."
            );
          }

          const expiresAt = ban.expiresAt as Timestamp | undefined;

          if (expiresAt && expiresAt.toMillis() > Date.now()) {
            throw new HttpsError(
              "permission-denied",
              "أنت محظور مؤقتاً من الدردشة.",
              {
                expiresAt: expiresAt.toMillis(),
                remainingMs: expiresAt.toMillis() - Date.now()
              }
            );
          }

          transaction.update(banRef, {
            active: false,
            expiredAt: FieldValue.serverTimestamp()
          });
        }
      }

      const player = playerSnapshot.data()!;

      transaction.create(messageRef, {
        senderId: uid,
        senderName: player.displayName || "لاعب",
        text: text.trim(),
        imageUrl: null,
        moderationStatus: "pending",
        createdAt: FieldValue.serverTimestamp()
      });

      return {
        messageId: messageRef.id,
        status: "pending"
      };
    });

    return result;
  }
);

/**
 * مراجعة الرسائل بواسطة مشرف مخوّل.
 * لا يمكن للاعب العادي اعتماد الرسائل.
 */
export const reviewGlobalMessage = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "يجب تسجيل الدخول."
      );
    }

    if (request.auth.token.moderator !== true) {
      throw new HttpsError(
        "permission-denied",
        "هذه العملية للمشرفين فقط."
      );
    }

    const messageId = request.data?.messageId;
    const decision = request.data?.decision;
    const reason = request.data?.reason;

    if (
      typeof messageId !== "string" ||
      !["approve", "reject"].includes(decision)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "بيانات المراجعة غير صحيحة."
      );
    }

    const messageRef = db
      .collection("globalMessages")
      .doc(messageId);

    const eventRef = db
      .collection("moderationEvents")
      .doc();

    const result = await db.runTransaction(async (transaction) => {
      const messageSnapshot = await transaction.get(messageRef);

      if (!messageSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "الرسالة غير موجودة."
        );
      }

      const message = messageSnapshot.data()!;

      if (message.moderationStatus !== "pending") {
        throw new HttpsError(
          "failed-precondition",
          "تمت مراجعة هذه الرسالة سابقاً."
        );
      }

      if (decision === "approve") {
        transaction.update(messageRef, {
          moderationStatus: "approved",
          reviewedAt: FieldValue.serverTimestamp(),
          reviewedBy: request.auth!.uid
        });

        return {
          status: "approved"
        };
      }

      const uid = message.senderId;

      if (typeof uid !== "string" || !uid) {
        throw new HttpsError(
          "failed-precondition",
          "هوية مرسل الرسالة غير صالحة."
        );
      }

      const playerRef = db.collection("players").doc(uid);
      const banRef = db.collection("bannedUsers").doc(uid);

      const playerSnapshot = await transaction.get(playerRef);
      const banSnapshot = await transaction.get(banRef);

      if (!playerSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "ملف اللاعب غير موجود."
        );
      }

      const player = playerSnapshot.data()!;
      const strikes = Number(player.moderationStrikes || 0) + 1;

      let durationMs = 0;
      let permanent = false;

      if (strikes === 2) {
        durationMs = 60 * 60 * 1000;
      } else if (strikes === 3) {
        durationMs = 2 * 60 * 60 * 1000;
      } else if (strikes === 4) {
        durationMs = 24 * 60 * 60 * 1000;
      } else if (strikes === 5) {
        durationMs = 7 * 24 * 60 * 60 * 1000;
      } else if (strikes >= 6) {
        permanent = true;
      }

      transaction.update(messageRef, {
        moderationStatus: "rejected",
        rejectionReason:
          typeof reason === "string" ? reason.slice(0, 500) : "مخالفة",
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: request.auth!.uid
      });

      transaction.update(playerRef, {
        moderationStrikes: strikes
      });

      if (durationMs > 0 || permanent) {
        const expiresAt = permanent
          ? null
          : Timestamp.fromMillis(Date.now() + durationMs);

        transaction.set(banRef, {
          userId: uid,
          active: true,
          permanent,
          expiresAt,
          reason:
            typeof reason === "string" ? reason.slice(0, 500) : "مخالفة",
          strikes,
          updatedAt: FieldValue.serverTimestamp()
        });
      } else if (banSnapshot.exists) {
        transaction.update(banRef, {
          active: false,
          updatedAt: FieldValue.serverTimestamp()
        });
      }

      transaction.create(eventRef, {
        userId: uid,
        messageId,
        moderatorId: request.auth!.uid,
        decision: "reject",
        reason:
          typeof reason === "string" ? reason.slice(0, 500) : "مخالفة",
        strikes,
        durationMs,
        permanent,
        createdAt: FieldValue.serverTimestamp()
      });

      return {
        status: "rejected",
        strikes,
        durationMs,
        permanent
      };
    });

    return result;
  }
);
