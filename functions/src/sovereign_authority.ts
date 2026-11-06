
import { onCall } from "firebase-functions/v2/https";

/**
 * SYSTEM WORLD - Server-side Sovereign Authority
 *
 * لا يمنح هذا الملف الملكية لأي حساب.
 * يتحقق فقط من Custom Claim يصدر من Firebase Admin SDK
 * بعد التحقق الإداري من هوية المالك.
 *
 * يمنع الاعتماد على اسم اللاعب أو بيانات يرسلها التطبيق.
 */

const OWNER_CLAIM = "systemSovereignOwner";

const SOVEREIGN_ABILITIES = [
  "sovereign_flight",
  "sovereign_aura",
  "world_travel",
  "absolute_authority"
];

export const getSovereignAuthority = onCall(
  async (request) => {
    if (!request.auth) {
      return {
        authenticated: false,
        authorized: false,
        serverVerified: false,
        reason: "AUTHENTICATION_REQUIRED"
      };
    }

    const token = request.auth.token;

    const emailVerified =
      token.email_verified === true;

    const ownerClaim =
      token[OWNER_CLAIM] === true;

    const authorized =
      emailVerified && ownerClaim;

    if (!authorized) {
      return {
        authenticated: true,
        authorized: false,
        serverVerified: false,
        reason: emailVerified
          ? "OWNER_CLAIM_NOT_GRANTED"
          : "EMAIL_NOT_VERIFIED"
      };
    }

    return {
      authenticated: true,
      authorized: true,
      serverVerified: true,
      authority: "SYSTEM_SUPREME_SOVEREIGN",
      title: "ملك العوالم الأربعة ومالك جزيرة الطمع",
      worldIds: [0, 1, 2, 3],
      exclusive: true,
      abilities: SOVEREIGN_ABILITIES
    };
  }
);
