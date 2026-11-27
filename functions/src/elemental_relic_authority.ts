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
  const progressionRef = playerRef.collection("elementalProgression").doc("verified");
  const combatRef = playerRef.collection("elementalCombat").doc("state");
  await db.runTransaction(async (transaction) => {
    const [player, current] = await Promise.all([
      transaction.get(playerRef),
      transaction.get(combatRef)
    ]);
    if (!player.exists) throw new HttpsError("not-found", "ملف اللاعب غير موجود.");
    transaction.set(progressionRef, {
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
      transaction.create(combatRef, {
        energy,
        maxEnergy,
        cooldowns: {},
        updatedAt: FieldValue.serverTimestamp(),
        initializedByGameServer: serverUid
      });
    } else {
      // Transaction conflict detection prevents a concurrent activation from being overwritten by a stale sync read.
      transaction.update(combatRef, {
        maxEnergy,
        energy: Math.min(Number(current.data()?.energy ?? 0), maxEnergy),
        updatedAt: FieldValue.serverTimestamp(),
        lastProgressionSyncBy: serverUid
      });
    }
  });
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


/**
 * Trusted combat-server consumer for a previously authorized elemental activation.
 * The caller supplies only the activation receipt and target ID; damage, healing,
 * resistance and movement values are derived here from server-owned records.
 */
export const resolveElementalRelicCombat = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const activationId = requiredText(request.data?.activationId, "activationId", 128);
  const targetId = typeof request.data?.targetId === "string" ? request.data.targetId.trim() : "";
  if (targetId && targetId.length > 128) throw new HttpsError("invalid-argument", "معرّف الهدف غير صالح.");

  const activationRef = db.collection("players").doc(requiredText(request.data?.playerId, "playerId", 128))
    .collection("elementalActivations").doc(activationId);
  const activationSnap = await activationRef.get();
  if (!activationSnap.exists) throw new HttpsError("not-found", "تذكرة التفعيل غير موجودة.");
  const playerId = activationSnap.ref.parent.parent!.id;
  const activation = activationSnap.data()!;
  const playerRef = db.collection("players").doc(playerId);
  const sessionRef = playerRef.collection("combatState").doc("session");
  const targetRef = targetId ? db.collection("combatTargets").doc(targetId) : null;
  const eventRef = db.collection("elementalCombatEvents").doc(activationId);

  return db.runTransaction(async (transaction) => {
    const [freshActivation, player, session, target] = await Promise.all([
      transaction.get(activationRef),
      transaction.get(playerRef),
      transaction.get(sessionRef),
      targetRef ? transaction.get(targetRef) : Promise.resolve(null)
    ]);
    if (!freshActivation.exists || !player.exists) throw new HttpsError("not-found", "بيانات القتال غير موجودة.");
    const a = freshActivation.data()!;
    if (a.status !== "authorized_pending_combat") {
      throw new HttpsError("failed-precondition", "ACTIVATION_ALREADY_CONSUMED");
    }
    const now = Date.now();
    if (!session.exists) throw new HttpsError("failed-precondition", "ACTIVE_COMBAT_SESSION_REQUIRED");
    const sessionData = session.data()!;
    const sessionId = String(sessionData.sessionId ?? "");
    const sessionTick = Number(sessionData.lastServerTickMs ?? 0);
    const playerPosition = sessionData.playerPosition;
    const validPosition = (value: any) => value &&
      Number.isFinite(Number(value.x)) && Number.isFinite(Number(value.y)) && Number.isFinite(Number(value.z));
    if (sessionData.active !== true || !sessionId || sessionData.playerId !== playerId ||
        !Number.isFinite(sessionTick) || now - sessionTick < 0 || now - sessionTick > 3000 ||
        !validPosition(playerPosition)) {
      throw new HttpsError("failed-precondition", "COMBAT_SESSION_STALE_OR_INVALID");
    }
    const expiry = Number(a.expiresAtMs ?? 0);
    if (!Number.isFinite(expiry) || expiry < now) {
      throw new HttpsError("deadline-exceeded", "ACTIVATION_EXPIRED");
    }

    const element = String(a.element);
    let result: Record<string, unknown> = {};
    if (element === "fire" || element === "lightning") {
      if (!targetRef || !target?.exists) throw new HttpsError("failed-precondition", "COMBAT_TARGET_NOT_FOUND");
      const t = target.data()!;
      if (t.isAlive !== true || !Number.isFinite(Number(t.health)) || Number(t.health) <= 0 ||
          !Number.isFinite(Number(t.maxHealth)) || Number(t.maxHealth) <= 0) {
        throw new HttpsError("failed-precondition", "COMBAT_TARGET_NOT_ALIVE");
      }
      if (t.sessionId !== sessionId || !validPosition(t.position) ||
          !Number.isFinite(Number(t.lastServerTickMs)) || now - Number(t.lastServerTickMs) < 0 ||
          now - Number(t.lastServerTickMs) > 3000) {
        throw new HttpsError("failed-precondition", "COMBAT_TARGET_NOT_IN_ACTIVE_SESSION");
      }
      const dx = Number(t.position.x) - Number(playerPosition.x);
      const dy = Number(t.position.y) - Number(playerPosition.y);
      const dz = Number(t.position.z) - Number(playerPosition.z);
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
      const maxRange = element === "fire" ? 42 : 48;
      if (!Number.isFinite(distance) || distance > maxRange) {
        throw new HttpsError("failed-precondition", "ELEMENTAL_TARGET_OUT_OF_RANGE");
      }
      const baseDamage = element === "fire" ? 26 : 32;
      const mitigation = Math.min(0.9, Math.max(0, Number(t.elementalResistance?.[element] ?? 0)));
      const categoryMultiplier = t.kind === "boss" || t.kind === "player" ? 0.5 : 1.0;
      const damage = Math.max(1, baseDamage * (1 - mitigation) * categoryMultiplier);
      const nextHealth = Math.max(0, Number(t.health) - damage);
      transaction.update(targetRef, {
        health: nextHealth,
        isAlive: nextHealth > 0,
        lastDamage: { amount: damage, element, sourcePlayerId: playerId, at: FieldValue.serverTimestamp() },
        updatedAt: FieldValue.serverTimestamp()
      });
      result = { targetId, damage, remainingHealth: nextHealth, defeated: nextHealth <= 0 };
    } else {
      const vitalsRef = playerRef.collection("combatState").doc("vitals");
      const statusRef = playerRef.collection("combatState").doc("elemental_status");
      const [vitals, status] = await Promise.all([transaction.get(vitalsRef), transaction.get(statusRef)]);
      if (element === "water") {
        if (!vitals.exists) throw new HttpsError("failed-precondition", "PLAYER_VITALS_NOT_READY");
        const v = vitals.data()!;
        const health = Number(v.health), maxHealth = Number(v.maxHealth);
        if (!Number.isFinite(health) || !Number.isFinite(maxHealth) || health >= maxHealth) {
          throw new HttpsError("failed-precondition", "NO_VALID_HEAL_TARGET");
        }
        const healed = Math.min(22, maxHealth - health);
        transaction.update(vitalsRef, { health: health + healed, updatedAt: FieldValue.serverTimestamp() });
        transaction.set(statusRef, { waterShieldUntilMs: now + 6000, waterShieldReduction: 0.15, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        result = { healed, shieldSeconds: 6, remainingHealth: health + healed };
      } else if (element === "earth") {
        transaction.set(statusRef, { earthGuardUntilMs: now + 8000, earthGuardReduction: 0.30, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        result = { guardSeconds: 8, damageReduction: 0.30 };
      } else if (element === "air") {
        transaction.set(statusRef, { airDashUntilMs: now + 220, airDashSpeed: 11, airDashVerticalImpulse: 5.5, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        result = { dashSeconds: 0.22, horizontalSpeed: 11, verticalImpulse: 5.5 };
      } else {
        throw new HttpsError("failed-precondition", "UNSUPPORTED_ELEMENTAL_EFFECT");
      }
    }

    transaction.update(activationRef, {
      status: "consumed",
      consumedAt: FieldValue.serverTimestamp(),
      consumedByGameServer: serverUid
    });
    transaction.create(eventRef, {
      activationId,
      playerId,
      skillId: a.skillId,
      artifactId: a.artifactId,
      element,
      result,
      gameServerUid: serverUid,
      createdAt: FieldValue.serverTimestamp()
    });
    return { success: true, activationId, element, result, status: "consumed" };
  });
});
