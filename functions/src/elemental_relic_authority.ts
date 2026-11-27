import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

const ELEMENTAL_SKILLS: Record<string, { artifactId: string; nenRank: number; level: number; hunterRank: string; energy: number; cooldown: number }> = {
  primordial_flame_burst: { artifactId: "primordial_flame_heart", nenRank: 2, level: 25, hunterRank: "B", energy: 32, cooldown: 28 },
  stormwind_aerial_step: { artifactId: "stormwind_sigil", nenRank: 2, level: 25, hunterRank: "B", energy: 28, cooldown: 24 },
  tideheart_restoration: { artifactId: "tideheart_pearl", nenRank: 3, level: 30, hunterRank: "A", energy: 36, cooldown: 40 },
  worldroot_earthguard: { artifactId: "worldroot_geode", nenRank: 3, level: 35, hunterRank: "A", energy: 38, cooldown: 42 },
  stormlightning_arc: { artifactId: "stormlightning_crown", nenRank: 4, level: 50, hunterRank: "S", energy: 48, cooldown: 55 }
};

function requirePlayer(request: any): string {
  if (!request.auth?.uid) throw new HttpsError("unauthenticated", "سجّل الدخول بحساب اللاعب أولاً.");
  return String(request.auth.uid);
}

function requireGameServer(request: any): string {
  const uid = requirePlayer(request);
  if (request.auth.token.gameServer !== true) {
    throw new HttpsError("permission-denied", "تحديث تقدم النين الموثوق متاح لخادم اللعبة فقط.");
  }
  return uid;
}

function requiredText(value: unknown, field: string, max: number): string {
  if (typeof value !== "string" || !value.trim() || value.trim().length > max) {
    throw new HttpsError("invalid-argument", `الحقل ${field} غير صالح.`);
  }
  return value.trim();
}

/**
 * The trusted game server publishes verified progression only after validating
 * its own mission, Nen-training and skill-learning records. Clients cannot write this document.
 */
export const syncAuthoritativeElementalProgression = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const playerId = requiredText(request.data?.playerId, "playerId", 128);
  const state = request.data?.state;
  if (!state || typeof state !== "object" || Array.isArray(state)) {
    throw new HttpsError("invalid-argument", "بيانات تقدم اللاعب غير صالحة.");
  }
  const nenUnlocked = state.nenUnlocked;
  const nenRank = state.nenControlRank;
  const level = state.level;
  const hunterRank = state.hunterRank;
  const learned = state.learnedSkills;
  const permitted = state.authorizedSkills;
  const practice = state.practiceCounts;
  const energy = state.currentEnergy;
  const maxEnergy = state.maxEnergy;
  if (typeof nenUnlocked !== "boolean" ||
      !Number.isInteger(nenRank) || nenRank < 0 || nenRank > 5 ||
      !Number.isInteger(level) || level < 1 || level > 1000 ||
      typeof hunterRank !== "string" ||
      !Array.isArray(learned) || !learned.every((v: unknown) => typeof v === "string") ||
      !Array.isArray(permitted) || !permitted.every((v: unknown) => typeof v === "string") ||
      !practice || typeof practice !== "object" || Array.isArray(practice) ||
      typeof energy !== "number" || !Number.isFinite(energy) || energy < 0 ||
      typeof maxEnergy !== "number" || !Number.isFinite(maxEnergy) || maxEnergy <= 0 || energy > maxEnergy) {
    throw new HttpsError("invalid-argument", "قيم تقدم النين أو الطاقة خارج الحدود.");
  }
  const practiceCounts: Record<string, number> = {};
  for (const [skillId, count] of Object.entries(practice)) {
    if (!Number.isInteger(count) || Number(count) < 0 || Number(count) > 10000) {
      throw new HttpsError("invalid-argument", "عدد تدريبات المهارة غير صالح.");
    }
    practiceCounts[skillId] = Number(count);
  }

  const playerRef = db.collection("players").doc(playerId);
  const [player, current] = await Promise.all([
    playerRef.get(),
    playerRef.collection("elementalCombat").doc("state").get()
  ]);
  if (!player.exists) throw new HttpsError("not-found", "ملف اللاعب غير موجود.");
  await playerRef.collection("elementalProgression").doc("verified").set({
    nenUnlocked,
    nenControlRank: nenRank,
    level,
    hunterRank: hunterRank.toUpperCase(),
    learnedSkills: [...new Set(learned as string[])],
    authorizedSkills: [...new Set(permitted as string[])],
    practiceCounts,
    verifiedByGameServer: serverUid,
    verifiedAt: FieldValue.serverTimestamp()
  });
  if (!current.exists) {
    await playerRef.collection("elementalCombat").doc("state").create({
      energy,
      maxEnergy,
      cooldowns: {},
      updatedAt: FieldValue.serverTimestamp(),
      initializedByGameServer: serverUid
    });
  } else {
    // Never let a routine progression sync refill energy or erase active cooldowns.
    await playerRef.collection("elementalCombat").doc("state").update({
      maxEnergy,
      energy: Math.min(Number(current.data()?.energy ?? 0), maxEnergy),
      updatedAt: FieldValue.serverTimestamp(),
      lastProgressionSyncBy: serverUid
    });
  }
  return { success: true, playerId, progressionVerified: true };
});

/**
 * Client-callable gate. All eligibility, ownership, awakening, energy and cooldown
 * checks are read from server-owned Firestore records in one transaction.
 * This reserves a one-time activation ticket; a trusted combat server must consume
 * that ticket before applying damage, healing or movement in online play.
 */
export const authorizeElementalRelicActivation = onCall(async (request) => {
  const uid = requirePlayer(request);
  const skillId = requiredText(request.data?.skillId, "skillId", 80).toLowerCase();
  const definition = ELEMENTAL_SKILLS[skillId];
  if (!definition) throw new HttpsError("invalid-argument", "المهارة العنصرية غير معروفة.");

  const playerRef = db.collection("players").doc(uid);
  const progressionRef = playerRef.collection("elementalProgression").doc("verified");
  const combatRef = playerRef.collection("elementalCombat").doc("state");
  const artifactRef = db.collection("artifactOwnership").doc(uid).collection("items").doc(definition.artifactId);
  const activationRef = playerRef.collection("elementalActivations").doc();

  const result = await db.runTransaction(async (transaction) => {
    const [player, progression, combat, artifact] = await Promise.all([
      transaction.get(playerRef),
      transaction.get(progressionRef),
      transaction.get(combatRef),
      transaction.get(artifactRef)
    ]);
    if (!player.exists) throw new HttpsError("not-found", "ملف اللاعب غير موجود.");
    if (!progression.exists || !combat.exists) {
      throw new HttpsError("failed-precondition", "لم يصل تقدم اللاعب الموثق من خادم اللعبة بعد.");
    }
    if (!artifact.exists || artifact.data()?.ownerId !== uid || artifact.data()?.status !== "owned" ||
        artifact.data()?.awakened !== true || artifact.data()?.relicSkillId !== skillId) {
      throw new HttpsError("failed-precondition", "التحفة المطلوبة غير مملوكة أو لم تُوقظ بعد.");
    }

    const p = progression.data()!;
    const c = combat.data()!;
    if (p.nenUnlocked !== true) throw new HttpsError("failed-precondition", "NEN_NOT_UNLOCKED");
    if (Number(p.nenControlRank) < definition.nenRank) {
      throw new HttpsError("failed-precondition", "NEN_CONTROL_REQUIREMENT");
    }
    if (Number(p.level) < definition.level || !Array.isArray(p.learnedSkills) ||
        !p.learnedSkills.includes(skillId) || !Array.isArray(p.authorizedSkills) ||
        !p.authorizedSkills.includes(skillId) || Number(p.practiceCounts?.[skillId] ?? 0) < 3) {
      throw new HttpsError("failed-precondition", "SKILL_NOT_READY");
    }
    const rankOrder = ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"];
    if (rankOrder.indexOf(String(p.hunterRank).toUpperCase()) < rankOrder.indexOf(definition.hunterRank)) {
      throw new HttpsError("failed-precondition", "HUNTER_RANK_REQUIREMENT");
    }
    const now = Date.now();
    const cooldownUntil = Number(c.cooldowns?.[skillId] ?? 0);
    if (cooldownUntil > now) {
      throw new HttpsError("failed-precondition", "SKILL_ON_COOLDOWN", { remainingMs: cooldownUntil - now });
    }
    const energy = Number(c.energy);
    if (!Number.isFinite(energy) || energy < definition.energy) {
      throw new HttpsError("failed-precondition", "SYSTEM_ENERGY_LOW");
    }

    const cooldowns = { ...(c.cooldowns || {}), [skillId]: now + definition.cooldown * 1000 };
    transaction.update(combatRef, {
      energy: energy - definition.energy,
      cooldowns,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.create(activationRef, {
      activationId: activationRef.id,
      playerId: uid,
      skillId,
      artifactId: definition.artifactId,
      element: skillId.startsWith("primordial_flame") ? "fire" :
        skillId.startsWith("stormwind") ? "air" :
        skillId.startsWith("tideheart") ? "water" :
        skillId.startsWith("worldroot") ? "earth" : "lightning",
      status: "authorized_pending_combat",
      energyCost: definition.energy,
      nenRank: Number(p.nenControlRank),
      createdAt: FieldValue.serverTimestamp(),
      expiresAtMs: now + 10000
    });
    return {
      success: true,
      activationId: activationRef.id,
      skillId,
      energyCost: definition.energy,
      remainingEnergy: energy - definition.energy,
      cooldownSeconds: definition.cooldown,
      status: "authorized_pending_combat"
    };
  });
  return result;
});


/**
 * Issues one of the five elemental relics only after the trusted game server
 * has closed a registered Hunter Guild mission as completed for this player.
 * The artifact is awakened by that verified quest reward and is replay-safe.
 */
export const grantElementalRelicFromCompletedMission = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const playerId = requiredText(request.data?.playerId, "playerId", 128);
  const sessionId = requiredText(request.data?.sessionId, "sessionId", 256);
  const eventId = requiredText(request.data?.eventId, "eventId", 100);
  const artifactId = requiredText(request.data?.artifactId, "artifactId", 100);
  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) {
    throw new HttpsError("invalid-argument", "معرّف حدث المكافأة غير صالح.");
  }
  const skillEntry = Object.entries(ELEMENTAL_SKILLS).find(([, definition]) => definition.artifactId === artifactId);
  if (!skillEntry) throw new HttpsError("invalid-argument", "هذه ليست تحفة عنصرية معتمدة.");
  const [skillId] = skillEntry;
  const playerRef = db.collection("players").doc(playerId);
  const sessionRef = db.collection("hunterGuildMissionSessions").doc(sessionId);
  const artifactRef = db.collection("artifactOwnership").doc(playerId).collection("items").doc(artifactId);
  const registryRef = db.collection("artifactRegistry").doc(artifactId);
  const eventRef = db.collection("elementalRelicRewardEvents").doc(`${serverUid}_${playerId}_${eventId}`);

  return db.runTransaction(async (transaction) => {
    const [player, session, artifact, registry, event] = await Promise.all([
      transaction.get(playerRef), transaction.get(sessionRef), transaction.get(artifactRef),
      transaction.get(registryRef), transaction.get(eventRef)
    ]);
    if (!player.exists) throw new HttpsError("not-found", "ملف اللاعب غير موجود.");
    if (event.exists) {
      const previous = event.data()!;
      if (previous.playerId !== playerId || previous.artifactId !== artifactId || previous.sessionId !== sessionId) {
        throw new HttpsError("already-exists", "معرّف المكافأة مستخدم لحدث آخر.");
      }
      return { success: true, alreadyIssued: true, artifactId, skillId };
    }
    if (!session.exists || session.data()?.status !== "completed") {
      throw new HttpsError("failed-precondition", "لا يمكن منح التحفة قبل إكمال المهمة وتوثيقها من خادم اللعبة.");
    }
    const roster: string[] = Array.isArray(session.data()?.rosterPlayerIds) ? session.data()!.rosterPlayerIds : [];
    if (!roster.includes(playerId)) {
      throw new HttpsError("permission-denied", "اللاعب ليس ضمن المشاركين المثبتين في المهمة المكتملة.");
    }
    if (artifact.exists || registry.exists) {
      throw new HttpsError("already-exists", "معرّف التحفة مستخدم مسبقاً.");
    }
    transaction.create(registryRef, {
      artifactId, originalOwnerId: playerId, issuedAt: FieldValue.serverTimestamp(),
      source: "verified_hunter_guild_mission", referenceId: sessionId
    });
    transaction.create(artifactRef, {
      artifactId, ownerId: playerId, name: artifactId, civilization: "Unknown",
      rarity: "mythic", condition: "excellent", authenticity: "verified",
      status: "owned", awakened: true, relicSkillId: skillId,
      source: "verified_hunter_guild_mission", referenceId: sessionId,
      acquiredAt: FieldValue.serverTimestamp(), awakenedAt: FieldValue.serverTimestamp(),
      createdByGameServer: serverUid
    });
    transaction.create(eventRef, {
      playerId, artifactId, skillId, sessionId, eventId, gameServerUid: serverUid,
      createdAt: FieldValue.serverTimestamp()
    });
    return { success: true, alreadyIssued: false, artifactId, skillId };
  });
});
