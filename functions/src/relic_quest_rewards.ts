import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

const RELIC_QUESTS: Record<string, {
  relicId: string;
  historicalSiteId: string;
  objectives: string[];
  returnRequired: boolean;
  skillId: string;
  skillName: string;
  rarity: "legendary" | "mythic";
}> = {
  quest_babylon_star_tablet: {
    relicId: "babylonian_star_tablet",
    historicalSiteId: "babylon_esagila_archive",
    objectives: ["find_the_sealed_archive", "solve_the_celestial_lock", "defeat_the_archive_guardian"],
    returnRequired: true,
    skillId: "rare_skill_celestial_lightning",
    skillName: "البرق السماوي",
    rarity: "mythic"
  },
  quest_sumerian_oath: {
    relicId: "sumerian_oath_seal",
    historicalSiteId: "ur_royal_temple",
    objectives: ["recover_the_three_oaths", "restore_the_temple_seal"],
    returnRequired: true,
    skillId: "rare_skill_earth_guardian",
    skillName: "درع حارس الأرض",
    rarity: "legendary"
  },
  quest_akkadian_shadow: {
    relicId: "akkadian_shadow_crown",
    historicalSiteId: "akkad_hidden_sanctum",
    objectives: ["trace_the_lost_dynasty", "pass_the_shadow_trial", "seal_the_cursed_chamber"],
    returnRequired: false,
    skillId: "rare_skill_shadow_avatar",
    skillName: "تجسيد الظل",
    rarity: "mythic"
  }
};

function requireGameServer(request: any): string {
  if (!request.auth?.uid || request.auth.token.gameServer !== true) {
    throw new HttpsError("permission-denied", "إثبات مهمات التحف متاح لخادم اللعبة الموثوق فقط.");
  }
  return String(request.auth.uid);
}

function requirePlayer(request: any): string {
  if (!request.auth?.uid) throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  return String(request.auth.uid);
}

/** Players can request a relic quest, but only the trusted game server may open its session. */
export const requestHistoricalRelicQuestStart = onCall(async (request) => {
  const playerId = requirePlayer(request);
  const questId = requiredText(request.data?.questId, "questId", 100);
  const artifactId = requiredText(request.data?.artifactId, "artifactId", 120);
  const quest = getQuest(questId, artifactId);
  const artifactRef = db.collection("artifactOwnership").doc(playerId).collection("items").doc(artifactId);
  const requestRef = db.collection("historicalRelicQuestStartRequests").doc(playerId + "_" + questId);
  return db.runTransaction(async (transaction) => {
    const [artifactSnapshot, requestSnapshot] = await Promise.all([
      transaction.get(artifactRef), transaction.get(requestRef)
    ]);
    if (!artifactSnapshot.exists) throw new HttpsError("failed-precondition", "التحفة المطلوبة ليست في مجموعة اللاعب.");
    const artifact = artifactSnapshot.data()!;
    if (artifact.ownerId !== playerId || artifact.status !== "owned" ||
        artifact.activeListingId || artifact.activeAuctionId || artifact.activeExchangeId) {
      throw new HttpsError("failed-precondition", "يجب أن تكون التحفة بحيازة اللاعب وغير محجوزة في السوق.");
    }
    if (requestSnapshot.exists) {
      if (requestSnapshot.data()?.status === "pending") {
        return { success: true, requestId: requestRef.id, alreadyPending: true, questId, artifactId };
      }
      throw new HttpsError("already-exists", "سبق تسجيل هذا الطلب أو بدأ خادم اللعبة جلسته.");
    }
    transaction.create(requestRef, {
      playerId, questId, artifactId, historicalSiteId: quest.historicalSiteId,
      status: "pending", requestedAt: FieldValue.serverTimestamp()
    });
    return { success: true, requestId: requestRef.id, alreadyPending: false, questId, artifactId };
  });
});

/** Players may request a return; the server must independently verify world position and site presence. */
export const requestHistoricalRelicReturn = onCall(async (request) => {
  const playerId = requirePlayer(request);
  const questId = requiredText(request.data?.questId, "questId", 100);
  const artifactId = requiredText(request.data?.artifactId, "artifactId", 120);
  const quest = getQuest(questId, artifactId);
  if (!quest.returnRequired) throw new HttpsError("failed-precondition", "هذه المهمة لا تتطلب إعادة التحفة.");
  const artifactSnapshot = await db.collection("artifactOwnership").doc(playerId).collection("items").doc(artifactId).get();
  if (!artifactSnapshot.exists) throw new HttpsError("failed-precondition", "التحفة غير موجودة في مجموعة اللاعب.");
  const ownedArtifact = artifactSnapshot.data()!;
  if (ownedArtifact.ownerId !== playerId || ownedArtifact.status !== "owned" ||
      ownedArtifact.activeListingId || ownedArtifact.activeAuctionId || ownedArtifact.activeExchangeId) {
    throw new HttpsError("failed-precondition", "التحفة ليست بحيازة اللاعب أو محجوزة في السوق.");
  }
  const sessions = await db.collection("historicalRelicQuestSessions")
    .where("playerId", "==", playerId).limit(50).get();
  const sessionDoc = sessions.docs.find((doc) => {
    const session = doc.data();
    return session.questId === questId && session.artifactId === artifactId &&
      session.status === "active" &&
      quest.objectives.every((id) => session.completedObjectives?.[id] === true);
  });
  if (!sessionDoc) throw new HttpsError("failed-precondition", "لا توجد جلسة موثوقة مكتملة الأهداف تنتظر الإرجاع.");
  if (ownedArtifact.activeHistoricalQuestSessionId !== sessionDoc.id) {
    throw new HttpsError("failed-precondition", "قفل التحفة لا يطابق جلسة المهمة النشطة.");
  }
  const requestRef = db.collection("historicalRelicReturnRequests").doc(sessionDoc.id);
  const requestSnapshot = await requestRef.get();
  if (requestSnapshot.exists) {
    const existing = requestSnapshot.data()!;
    if (existing.playerId !== playerId || existing.questId !== questId) {
      throw new HttpsError("permission-denied", "طلب الإرجاع لا يخص هذا اللاعب.");
    }
    return { success: true, requestId: requestRef.id, sessionId: sessionDoc.id, alreadyPending: existing.status === "pending" };
  }
  await requestRef.create({
    playerId, questId, artifactId, sessionId: sessionDoc.id,
    historicalSiteId: quest.historicalSiteId,
    status: "pending", requestedAt: FieldValue.serverTimestamp()
  });
  return { success: true, requestId: requestRef.id, sessionId: sessionDoc.id, alreadyPending: false };
});

/** Only the trusted game server may poll player requests; it must validate live gameplay before acting. */
export const listPendingHistoricalRelicQuestRequests = onCall(async (request) => {
  requireGameServer(request);
  const [starts, returns] = await Promise.all([
    db.collection("historicalRelicQuestStartRequests").where("status", "==", "pending").limit(50).get(),
    db.collection("historicalRelicReturnRequests").where("status", "==", "pending").limit(50).get()
  ]);
  return {
    starts: starts.docs.map((doc) => ({ requestId: doc.id, ...doc.data() })),
    returns: returns.docs.map((doc) => ({ requestId: doc.id, ...doc.data() }))
  };
});

function requiredText(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string") throw new HttpsError("invalid-argument", `الحقل ${field} غير صالح.`);
  const result = value.trim();
  if (!result || result.length > maxLength) throw new HttpsError("invalid-argument", `تحقق من الحقل ${field}.`);
  return result;
}

function getQuest(questId: string, artifactId: string) {
  const quest = RELIC_QUESTS[questId];
  if (!quest || quest.relicId !== artifactId) {
    throw new HttpsError("invalid-argument", "التحفة لا تطابق المهمة التاريخية.");
  }
  return quest;
}

function getSessionRef(sessionId: string) {
  return db.collection("historicalRelicQuestSessions").doc(sessionId);
}

/** A trusted server opens a quest session only after the player has the matching artifact. */
export const startHistoricalRelicQuestSession = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const playerId = requiredText(request.data?.playerId, "playerId", 128);
  const questId = requiredText(request.data?.questId, "questId", 100);
  const artifactId = requiredText(request.data?.artifactId, "artifactId", 120);
  const quest = getQuest(questId, artifactId);
  const playerRef = db.collection("players").doc(playerId);
  const artifactRef = db.collection("artifactOwnership").doc(playerId).collection("items").doc(artifactId);
  const requestId = requiredText(request.data?.requestId, "requestId", 180);
  if (!/^[A-Za-z0-9_-]+$/.test(requestId)) throw new HttpsError("invalid-argument", "معرّف طلب بدء المهمة غير صالح.");
  const startRequestRef = db.collection("historicalRelicQuestStartRequests").doc(requestId);
  const sessionRef = db.collection("historicalRelicQuestSessions").doc(requestId);

  await db.runTransaction(async (transaction) => {
    const [player, artifact, startRequest, existingSession] = await Promise.all([
      transaction.get(playerRef),
      transaction.get(artifactRef),
      transaction.get(startRequestRef),
      transaction.get(sessionRef)
    ]);
    if (!player.exists) throw new HttpsError("not-found", "حساب اللاعب غير موجود.");
    if (!artifact.exists) throw new HttpsError("not-found", "التحفة غير موجودة في مجموعة اللاعب.");
    const item = artifact.data()!;
    if (item.status !== "owned" || item.ownerId !== playerId ||
        item.activeListingId || item.activeAuctionId || item.activeExchangeId) {
      throw new HttpsError("failed-precondition", "التحفة ليست بحيازة اللاعب أو محجوزة في السوق.");
    }
    if (!startRequest.exists) throw new HttpsError("failed-precondition", "لا يوجد طلب مهمة من اللاعب.");
    const queued = startRequest.data()!;
    if (queued.playerId !== playerId || queued.questId !== questId || queued.artifactId !== artifactId) {
      throw new HttpsError("failed-precondition", "طلب بدء المهمة لا يطابق اللاعب أو التحفة.");
    }
    if (queued.status === "accepted" && queued.acceptedBy === serverUid && existingSession.exists) {
      return {
        success: true, alreadyStarted: true, sessionId: sessionRef.id,
        questId, artifactId, requiredObjectives: quest.objectives
      };
    }
    if (queued.status !== "pending" || existingSession.exists) {
      throw new HttpsError("failed-precondition", "طلب بدء المهمة استُهلك أو مرتبط بخادم آخر.");
    }
    transaction.create(sessionRef, {
      playerId, questId, artifactId, gameServerUid: serverUid,
      requiredObjectives: quest.objectives,
      completedObjectives: {},
      status: "active",
      startedAt: FieldValue.serverTimestamp()
    });
    transaction.update(artifactRef, {
      activeHistoricalQuestSessionId: sessionRef.id,
      historicalQuestStartedAt: FieldValue.serverTimestamp()
    });
    transaction.update(startRequestRef, {
      status: "accepted", sessionId: sessionRef.id, acceptedBy: serverUid,
      acceptedAt: FieldValue.serverTimestamp()
    });
  });
  return { success: true, sessionId: sessionRef.id, questId, artifactId, requiredObjectives: quest.objectives };
});

/** Each objective event must originate from the trusted game server and belong to the active session. */
export const recordHistoricalRelicQuestObjective = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const sessionId = requiredText(request.data?.sessionId, "sessionId", 128);
  const eventId = requiredText(request.data?.eventId, "eventId", 100);
  const objectiveId = requiredText(request.data?.objectiveId, "objectiveId", 100);
  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) throw new HttpsError("invalid-argument", "معرّف الحدث غير صالح.");
  const sessionRef = getSessionRef(sessionId);
  const eventRef = sessionRef.collection("events").doc(eventId);

  return db.runTransaction(async (transaction) => {
    const [sessionSnapshot, eventSnapshot] = await Promise.all([
      transaction.get(sessionRef),
      transaction.get(eventRef)
    ]);
    if (!sessionSnapshot.exists) throw new HttpsError("not-found", "جلسة المهمة غير موجودة.");
    const session = sessionSnapshot.data()!;
    if (session.gameServerUid !== serverUid) throw new HttpsError("permission-denied", "خادم آخر بدأ جلسة المهمة.");
    if (session.status !== "active") throw new HttpsError("failed-precondition", "جلسة المهمة ليست نشطة.");
    const quest = getQuest(String(session.questId), String(session.artifactId));
    if (!quest.objectives.includes(objectiveId)) throw new HttpsError("invalid-argument", "الهدف لا ينتمي إلى هذه المهمة.");
    if (eventSnapshot.exists) throw new HttpsError("already-exists", "تم تسجيل حدث الهدف مسبقاً.");
    const completed: Record<string, boolean> = { ...(session.completedObjectives || {}) };
    completed[objectiveId] = true;
    transaction.create(eventRef, {
      eventId, objectiveId, playerId: session.playerId,
      verified: true, gameServerUid: serverUid,
      recordedAt: FieldValue.serverTimestamp()
    });
    transaction.update(sessionRef, {
      completedObjectives: completed,
      verifiedObjectiveCount: Object.keys(completed).length,
      updatedAt: FieldValue.serverTimestamp()
    });
    return {
      success: true,
      objectiveId,
      completedCount: Object.keys(completed).length,
      requiredCount: quest.objectives.length,
      allObjectivesComplete: quest.objectives.every((id) => completed[id] === true)
    };
  });
});

/** A return-required relic can only be marked returned by the trusted server at its exact historical site. */
export const recordHistoricalRelicReturn = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const sessionId = requiredText(request.data?.sessionId, "sessionId", 128);
  const eventId = requiredText(request.data?.eventId, "eventId", 100);
  const siteId = requiredText(request.data?.siteId, "siteId", 120);
  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) throw new HttpsError("invalid-argument", "معرّف حدث الإرجاع غير صالح.");
  const sessionRef = getSessionRef(sessionId);
  const eventRef = sessionRef.collection("events").doc("return_" + eventId);
  const returnRequestRef = db.collection("historicalRelicReturnRequests").doc(sessionId);

  return db.runTransaction(async (transaction) => {
    const [sessionSnapshot, eventSnapshot, returnRequestSnapshot] = await Promise.all([
      transaction.get(sessionRef),
      transaction.get(eventRef),
      transaction.get(returnRequestRef)
    ]);
    if (!sessionSnapshot.exists) throw new HttpsError("not-found", "جلسة المهمة غير موجودة.");
    const session = sessionSnapshot.data()!;
    if (session.gameServerUid !== serverUid) throw new HttpsError("permission-denied", "خادم آخر بدأ جلسة المهمة.");
    if (session.status !== "active") throw new HttpsError("failed-precondition", "جلسة المهمة ليست نشطة.");
    const quest = getQuest(String(session.questId), String(session.artifactId));
    if (!quest.returnRequired || siteId !== quest.historicalSiteId) {
      throw new HttpsError("failed-precondition", "موقع إرجاع التحفة غير صحيح.");
    }
    const queuedReturn = returnRequestSnapshot.data();
    if (!returnRequestSnapshot.exists || queuedReturn?.status !== "pending" ||
        queuedReturn?.playerId !== session.playerId ||
        queuedReturn?.sessionId !== sessionId ||
        queuedReturn?.questId !== session.questId ||
        queuedReturn?.artifactId !== session.artifactId ||
        queuedReturn?.historicalSiteId !== siteId) {
      throw new HttpsError("failed-precondition", "لا يوجد طلب إرجاع معتمد يطابق اللاعب والتحفة والموقع لهذه الجلسة.");
    }
    if (!quest.objectives.every((id) => session.completedObjectives?.[id] === true)) {
      throw new HttpsError("failed-precondition", "لم تثبت جميع أهداف المهمة من خادم اللعبة.");
    }
    if (eventSnapshot.exists) throw new HttpsError("already-exists", "حدث الإرجاع مسجل مسبقاً.");
    transaction.create(eventRef, {
      eventId, action: "verified_historical_return", siteId,
      playerId: session.playerId, artifactId: session.artifactId,
      verified: true, gameServerUid: serverUid,
      recordedAt: FieldValue.serverTimestamp()
    });
    transaction.update(sessionRef, {
      returnProof: { siteId, eventId, verifiedBy: serverUid, recordedAt: FieldValue.serverTimestamp() },
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.update(returnRequestRef, {
      status: "verified", verifiedBy: serverUid, eventId,
      verifiedAt: FieldValue.serverTimestamp()
    });
    return { success: true, returnVerified: true, siteId };
  });
});

/**
 * Rewards are issued only after the server-recorded session proves every objective
 * and (when required) the exact historical return. Artifact custody, skill unlock
 * and session completion are committed atomically and retries are idempotent.
 */
export const completeHistoricalRelicQuest = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const playerId = requiredText(request.data?.playerId, "playerId", 128);
  const questId = requiredText(request.data?.questId, "questId", 100);
  const artifactId = requiredText(request.data?.artifactId, "artifactId", 120);
  const sessionId = requiredText(request.data?.sessionId, "sessionId", 128);
  const eventId = requiredText(request.data?.eventId, "eventId", 100);
  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) throw new HttpsError("invalid-argument", "معرّف حدث المكافأة غير صالح.");
  const quest = getQuest(questId, artifactId);
  const playerRef = db.collection("players").doc(playerId);
  const artifactRef = db.collection("artifactOwnership").doc(playerId).collection("items").doc(artifactId);
  const sessionRef = getSessionRef(sessionId);
  const eventRef = db.collection("historicalRelicQuestRewards").doc(serverUid + "_" + playerId + "_" + eventId);
  const skillRef = db.collection("playerSkillUnlocks").doc(playerId).collection("skills").doc(quest.skillId);
  const historyRef = db.collection("artifactHistory").doc(artifactId).collection("events").doc("historical_return_" + eventId);

  return db.runTransaction(async (transaction) => {
    const [player, artifact, sessionSnapshot, priorEvent, existingSkill] = await Promise.all([
      transaction.get(playerRef),
      transaction.get(artifactRef),
      transaction.get(sessionRef),
      transaction.get(eventRef),
      transaction.get(skillRef)
    ]);
    if (!player.exists) throw new HttpsError("not-found", "حساب اللاعب غير موجود.");
    if (!sessionSnapshot.exists) throw new HttpsError("not-found", "جلسة المهمة الموثوقة غير موجودة.");
    const session = sessionSnapshot.data()!;
    if (session.gameServerUid !== serverUid || session.playerId !== playerId ||
        session.questId !== questId || session.artifactId !== artifactId) {
      throw new HttpsError("permission-denied", "جلسة الإثبات لا تطابق اللاعب أو التحفة أو الخادم.");
    }
    if (priorEvent.exists) {
      const previous = priorEvent.data()!;
      if (previous.questId !== questId || previous.artifactId !== artifactId || previous.playerId !== playerId) {
        throw new HttpsError("already-exists", "معرّف الحدث مستخدم لمكافأة مختلفة.");
      }
      return { success: true, alreadyCompleted: true, questId, artifactId, skillId: quest.skillId, relicReturned: quest.returnRequired };
    }
    if (session.status !== "active") throw new HttpsError("failed-precondition", "جلسة المهمة ليست نشطة.");
    if (!quest.objectives.every((id) => session.completedObjectives?.[id] === true)) {
      throw new HttpsError("failed-precondition", "لا توجد أدلة خادم موثوقة لجميع أهداف المهمة.");
    }
    if (quest.returnRequired && session.returnProof?.siteId !== quest.historicalSiteId) {
      throw new HttpsError("failed-precondition", "لم يؤكد خادم اللعبة إرجاع التحفة إلى موقعها التاريخي الصحيح.");
    }
    if (!artifact.exists) throw new HttpsError("not-found", "التحفة غير موجودة في مجموعة اللاعب.");
    const artifactData = artifact.data()!;
    if (artifactData.status !== "owned" || artifactData.ownerId !== playerId ||
        artifactData.activeListingId || artifactData.activeAuctionId || artifactData.activeExchangeId ||
        artifactData.activeHistoricalQuestSessionId !== sessionId) {
      throw new HttpsError("failed-precondition", "يجب أن تكون التحفة مملوكة ومقفلة لهذه الجلسة وغير محجوزة في السوق.");
    }
    if (existingSkill.exists && existingSkill.data()!.questId !== questId) {
      throw new HttpsError("already-exists", "المهارة مسجلة من مصدر مختلف.");
    }

    if (quest.returnRequired) {
      transaction.update(artifactRef, {
        status: "returned_to_history",
        returnedToHistoricalSite: quest.historicalSiteId,
        historicalQuestId: questId,
        activeHistoricalQuestSessionId: FieldValue.delete(),
        returnedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
      transaction.create(historyRef, {
        artifactId, ownerId: playerId, action: "returned_to_historical_site",
        historicalSiteId: quest.historicalSiteId, questId, actorId: serverUid,
        createdAt: FieldValue.serverTimestamp()
      });
    }
    if (!quest.returnRequired) {
      transaction.update(artifactRef, {
        activeHistoricalQuestSessionId: FieldValue.delete(),
        historicalQuestCompletedAt: FieldValue.serverTimestamp()
      });
    }
    if (!existingSkill.exists) {
      transaction.create(skillRef, {
        skillId: quest.skillId, skillName: quest.skillName, rarity: quest.rarity,
        playerId, questId, sourceArtifactId: artifactId,
        relicReturned: quest.returnRequired,
        historicalSiteId: quest.returnRequired ? quest.historicalSiteId : null,
        verifiedByGameServer: serverUid, unlockedAt: FieldValue.serverTimestamp()
      });
    }
    transaction.create(eventRef, {
      eventId, playerId, questId, artifactId, skillId: quest.skillId,
      relicReturned: quest.returnRequired,
      historicalSiteId: quest.returnRequired ? quest.historicalSiteId : null,
      gameServerUid: serverUid, sessionId,
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.update(sessionRef, {
      status: "completed",
      completedAt: FieldValue.serverTimestamp(),
      rewardEventId: eventId
    });
    return {
      success: true, alreadyCompleted: false, questId, artifactId,
      skillId: quest.skillId, skillName: quest.skillName,
      rarity: quest.rarity, relicReturned: quest.returnRequired
    };
  });
});

/** The signed-in player can read only their own server-authoritative relic quest progress. */
export const listMyHistoricalRelicQuestSessions = onCall(async (request) => {
  const playerId = requirePlayer(request);
  const snapshot = await db.collection("historicalRelicQuestSessions")
    .where("playerId", "==", playerId).limit(30).get();
  return {
    sessions: snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        sessionId: doc.id,
        questId: String(data.questId || ""),
        artifactId: String(data.artifactId || ""),
        status: String(data.status || ""),
        requiredObjectives: Array.isArray(data.requiredObjectives) ? data.requiredObjectives : [],
        completedObjectives: data.completedObjectives && typeof data.completedObjectives === "object" ? data.completedObjectives : {},
        returnProof: data.returnProof ? {
          siteId: String(data.returnProof.siteId || ""),
          verified: true
        } : null
      };
    })
  };
});

/** The signed-in player can read only their own server-issued rare skill unlocks. */
export const listMyRareRelicSkills = onCall(async (request) => {
  const playerId = requirePlayer(request);
  const snapshot = await db.collection("playerSkillUnlocks").doc(playerId).collection("skills").get();
  return {
    skills: snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        skillId: String(data.skillId || doc.id),
        skillName: String(data.skillName || ""),
        rarity: String(data.rarity || ""),
        questId: String(data.questId || ""),
        sourceArtifactId: String(data.sourceArtifactId || ""),
        relicReturned: data.relicReturned === true,
        historicalSiteId: data.historicalSiteId ? String(data.historicalSiteId) : null,
        unlockedAt: data.unlockedAt?.toMillis?.() ?? null
      };
    })
  };
});
