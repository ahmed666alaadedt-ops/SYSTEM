import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

const RELIC_QUESTS: Record<string, {
  relicId: string;
  historicalSiteId: string;
  returnRequired: boolean;
  skillId: string;
  skillName: string;
  rarity: "legendary" | "mythic";
}> = {
  quest_babylon_star_tablet: {
    relicId: "babylonian_star_tablet",
    historicalSiteId: "babylon_esagila_archive",
    returnRequired: true,
    skillId: "rare_skill_celestial_lightning",
    skillName: "البرق السماوي",
    rarity: "mythic"
  },
  quest_sumerian_oath: {
    relicId: "sumerian_oath_seal",
    historicalSiteId: "ur_royal_temple",
    returnRequired: true,
    skillId: "rare_skill_earth_guardian",
    skillName: "درع حارس الأرض",
    rarity: "legendary"
  },
  quest_akkadian_shadow: {
    relicId: "akkadian_shadow_crown",
    historicalSiteId: "akkad_hidden_sanctum",
    returnRequired: false,
    skillId: "rare_skill_shadow_avatar",
    skillName: "تجسيد الظل",
    rarity: "mythic"
  }
};

function requiredText(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `الحقل ${field} غير صالح.`);
  }
  const result = value.trim();
  if (!result || result.length > maxLength) {
    throw new HttpsError("invalid-argument", `تحقق من الحقل ${field}.`);
  }
  return result;
}

/**
 * Completes a historical relic quest only for the trusted game-server identity.
 * Objective validation is performed by the game server before this call.
 * Return-required relics are removed from the player's tradable ownership in
 * the same transaction that unlocks the rare skill. Stable event IDs make retries safe.
 */
export const completeHistoricalRelicQuest = onCall(async (request) => {
  if (!request.auth?.uid || request.auth.token.gameServer !== true) {
    throw new HttpsError("permission-denied", "إكمال مهمات التحف وإصدار مهاراتها متاح لخادم اللعبة الموثوق فقط.");
  }

  const gameServerUid = String(request.auth.uid);
  const playerId = requiredText(request.data?.playerId, "playerId", 128);
  const questId = requiredText(request.data?.questId, "questId", 100);
  const artifactId = requiredText(request.data?.artifactId, "artifactId", 120);
  const eventId = requiredText(request.data?.eventId, "eventId", 100);
  const siteId = typeof request.data?.siteId === "string" ? request.data.siteId.trim() : "";

  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) {
    throw new HttpsError("invalid-argument", "معرّف حدث المهمة غير صالح.");
  }
  const quest = RELIC_QUESTS[questId];
  if (!quest || quest.relicId !== artifactId) {
    throw new HttpsError("invalid-argument", "التحفة لا تطابق المهمة التاريخية.");
  }
  if (quest.returnRequired && siteId !== quest.historicalSiteId) {
    throw new HttpsError("failed-precondition", "يجب إرجاع التحفة إلى موقعها التاريخي الصحيح.");
  }
  if (!quest.returnRequired && siteId) {
    throw new HttpsError("invalid-argument", "هذه المهمة لا تتطلب إرجاع التحفة.");
  }

  const playerRef = db.collection("players").doc(playerId);
  const artifactRef = db.collection("artifactOwnership").doc(playerId).collection("items").doc(artifactId);
  const eventRef = db.collection("historicalRelicQuestRewards")
    .doc(gameServerUid + "_" + playerId + "_" + eventId);
  const skillRef = db.collection("playerSkillUnlocks").doc(playerId).collection("skills").doc(quest.skillId);
  const historyRef = db.collection("artifactHistory").doc(artifactId).collection("events").doc("historical_return_" + eventId);

  return db.runTransaction(async (transaction) => {
    const [player, artifact, priorEvent, existingSkill] = await Promise.all([
      transaction.get(playerRef),
      transaction.get(artifactRef),
      transaction.get(eventRef),
      transaction.get(skillRef)
    ]);

    if (!player.exists) throw new HttpsError("not-found", "حساب اللاعب غير موجود.");
    if (priorEvent.exists) {
      const previous = priorEvent.data()!;
      if (previous.questId !== questId || previous.artifactId !== artifactId || previous.playerId !== playerId) {
        throw new HttpsError("already-exists", "معرّف الحدث مستخدم لمكافأة مختلفة.");
      }
      return {
        success: true,
        alreadyCompleted: true,
        questId,
        artifactId,
        skillId: quest.skillId,
        relicReturned: quest.returnRequired
      };
    }
    if (!artifact.exists) throw new HttpsError("not-found", "التحفة غير موجودة في مجموعة اللاعب.");
    const artifactData = artifact.data()!;
    if (artifactData.status !== "owned" || artifactData.ownerId !== playerId ||
        artifactData.activeListingId || artifactData.activeAuctionId || artifactData.activeExchangeId) {
      throw new HttpsError("failed-precondition", "يجب أن تكون التحفة مملوكة وغير محجوزة في السوق.");
    }
    if (existingSkill.exists) {
      const existing = existingSkill.data()!;
      if (existing.questId !== questId) {
        throw new HttpsError("already-exists", "المهارة مسجلة من مصدر مختلف.");
      }
    }

    if (quest.returnRequired) {
      transaction.update(artifactRef, {
        status: "returned_to_history",
        returnedToHistoricalSite: quest.historicalSiteId,
        historicalQuestId: questId,
        returnedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
      transaction.create(historyRef, {
        artifactId,
        ownerId: playerId,
        action: "returned_to_historical_site",
        historicalSiteId: quest.historicalSiteId,
        questId,
        actorId: gameServerUid,
        createdAt: FieldValue.serverTimestamp()
      });
    }

    if (!existingSkill.exists) {
      transaction.create(skillRef, {
        skillId: quest.skillId,
        skillName: quest.skillName,
        rarity: quest.rarity,
        playerId,
        questId,
        sourceArtifactId: artifactId,
        verifiedByGameServer: gameServerUid,
        unlockedAt: FieldValue.serverTimestamp()
      });
    }
    transaction.create(eventRef, {
      eventId,
      playerId,
      questId,
      artifactId,
      skillId: quest.skillId,
      relicReturned: quest.returnRequired,
      historicalSiteId: quest.returnRequired ? quest.historicalSiteId : null,
      gameServerUid,
      createdAt: FieldValue.serverTimestamp()
    });

    return {
      success: true,
      alreadyCompleted: false,
      questId,
      artifactId,
      skillId: quest.skillId,
      skillName: quest.skillName,
      rarity: quest.rarity,
      relicReturned: quest.returnRequired
    };
  });
});
