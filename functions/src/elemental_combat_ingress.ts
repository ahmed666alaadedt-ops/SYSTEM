import { DocumentData, DocumentReference, FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

type NormalizedTarget = {
  id: string;
  ref: DocumentReference<DocumentData>;
  data: Record<string, unknown>;
};

function trustedServerUid(request: any): string {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "يجب مصادقة خادم اللعبة.");
  }
  if (request.auth.token.gameServer !== true) {
    throw new HttpsError("permission-denied", "إطارات القتال تقبل من خادم اللعبة الموثوق فقط.");
  }
  return String(request.auth.uid);
}

function safeId(value: unknown, field: string, max = 96): string {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]+$/.test(value) || value.length > max) {
    throw new HttpsError("invalid-argument", `معرّف ${field} غير صالح.`);
  }
  return value;
}

function position(value: any, field: string): { x: number; y: number; z: number } {
  if (!value || typeof value !== "object" ||
      !Number.isFinite(value.x) || !Number.isFinite(value.y) || !Number.isFinite(value.z) ||
      Math.abs(value.x) > 100000 || Math.abs(value.y) > 100000 || Math.abs(value.z) > 100000) {
    throw new HttpsError("invalid-argument", `إحداثيات ${field} غير صالحة.`);
  }
  return { x: value.x, y: value.y, z: value.z };
}

/**
 * Trusted game-server ingress for authoritative combat snapshots.
 * This is an API boundary, not a game server process: a separately hosted
 * server holding the gameServer custom claim must call it with its own
 * simulation ticks. Android/player clients are explicitly rejected.
 */
export const publishAuthoritativeCombatFrame = onCall(async (request) => {
  const serverUid = trustedServerUid(request);
  const playerId = safeId(request.data?.playerId, "playerId", 128);
  const sessionId = safeId(request.data?.sessionId, "sessionId", 128);
  const tickSequence = request.data?.tickSequence;
  const serverTickMs = request.data?.serverTickMs;
  const active = request.data?.active;
  const playerPosition = position(request.data?.playerPosition, "playerPosition");
  const targets = request.data?.targets;

  if (!Number.isSafeInteger(tickSequence) || tickSequence < 1 ||
      !Number.isSafeInteger(serverTickMs) ||
      typeof active !== "boolean" ||
      !Array.isArray(targets) || targets.length > 64 ||
      (!active && targets.length !== 0)) {
    throw new HttpsError("invalid-argument", "إطار القتال أو رقم التحديث غير صالح.");
  }
  const now = Date.now();
  if (serverTickMs > now + 1000 || now - serverTickMs > 3000) {
    throw new HttpsError("failed-precondition", "SERVER_FRAME_CLOCK_STALE");
  }

  const normalizedTargets: NormalizedTarget[] = targets.map((raw: any): NormalizedTarget => {
    const id = safeId(raw?.id, "targetId", 64);
    const kind = raw?.kind;
    const health = raw?.health;
    const maxHealth = raw?.maxHealth;
    if (!["monster", "boss", "player", "npc"].includes(kind) ||
        typeof health !== "number" || !Number.isFinite(health) || health < 0 ||
        typeof maxHealth !== "number" || !Number.isFinite(maxHealth) || maxHealth <= 0 ||
        health > maxHealth || typeof raw?.isAlive !== "boolean" ||
        raw.isAlive !== (health > 0)) {
      throw new HttpsError("invalid-argument", "حالة هدف القتال غير صالحة.");
    }
    const resistance: Record<string, number> = {};
    const sourceResistance = raw.elementalResistance ?? {};
    if (!sourceResistance || typeof sourceResistance !== "object" || Array.isArray(sourceResistance)) {
      throw new HttpsError("invalid-argument", "مقاومات الهدف غير صالحة.");
    }
    for (const element of ["fire", "air", "water", "earth", "lightning"]) {
      const value = sourceResistance[element] ?? 0;
      if (typeof value !== "number" || !Number.isFinite(value) || value < 0 || value > 0.9) {
        throw new HttpsError("invalid-argument", "قيمة مقاومة العنصر خارج الحدود.");
      }
      resistance[element] = value;
    }
    return {
      id,
      ref: db.collection("combatTargets").doc(`${playerId}__${sessionId}__${id}`),
      data: {
        targetId: id,
        ownerPlayerId: playerId,
        kind,
        health,
        maxHealth,
        isAlive: raw.isAlive,
        position: position(raw.position, "targetPosition"),
        elementalResistance: resistance,
        sessionId,
        lastServerTickMs: serverTickMs,
        tickSequence,
        updatedByGameServer: serverUid,
        updatedAt: FieldValue.serverTimestamp()
      }
    };
  });
  const uniqueTargetIds = new Set(normalizedTargets.map((target) => target.id));
  if (uniqueTargetIds.size !== normalizedTargets.length) {
    throw new HttpsError("invalid-argument", "إطار القتال يحتوي أهدافاً مكررة.");
  }

  const vitals = request.data?.playerVitals;
  if (vitals !== undefined &&
      (!vitals || typeof vitals !== "object" ||
       typeof vitals.health !== "number" || !Number.isFinite(vitals.health) || vitals.health < 0 ||
       typeof vitals.maxHealth !== "number" || !Number.isFinite(vitals.maxHealth) ||
       vitals.maxHealth <= 0 || vitals.health > vitals.maxHealth)) {
    throw new HttpsError("invalid-argument", "حيوية اللاعب غير صالحة.");
  }

  const playerRef = db.collection("players").doc(playerId);
  const sessionRef = playerRef.collection("combatState").doc("session");
  const vitalsRef = playerRef.collection("combatState").doc("vitals");
  const result = await db.runTransaction(async (transaction) => {
    const previous = await transaction.get(sessionRef);
    const old = previous.data();
    if (old?.active === true && old.sessionId !== sessionId) {
      throw new HttpsError("failed-precondition", "PLAYER_ALREADY_HAS_ACTIVE_COMBAT_SESSION");
    }
    if (old?.sessionId === sessionId && (!old.active || tickSequence <= Number(old.tickSequence ?? 0))) {
      throw new HttpsError("failed-precondition", "COMBAT_FRAME_REPLAY_OR_NON_MONOTONIC_TICK");
    }
    const targetSnapshots = await Promise.all(normalizedTargets.map((target) => transaction.get(target.ref)));
    for (let i = 0; i < normalizedTargets.length; i++) {
      const existing = targetSnapshots[i];
      if (existing.exists && existing.data()?.sessionId === sessionId &&
          Number(existing.data()?.tickSequence ?? 0) > tickSequence) {
        throw new HttpsError("failed-precondition", "TARGET_FRAME_REPLAY");
      }
    }

    transaction.set(sessionRef, {
      active,
      playerId,
      sessionId,
      playerPosition,
      lastServerTickMs: serverTickMs,
      tickSequence,
      updatedByGameServer: serverUid,
      updatedAt: FieldValue.serverTimestamp()
    });
    for (const target of normalizedTargets) transaction.set(target.ref, target.data);
    if (vitals !== undefined) {
      transaction.set(vitalsRef, {
        health: vitals.health,
        maxHealth: vitals.maxHealth,
        updatedByGameServer: serverUid,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });
    }
    return {
      success: true,
      playerId,
      sessionId,
      tickSequence,
      active,
      targetDocumentIds: Object.fromEntries(normalizedTargets.map((target) => [target.id, target.ref.id]))
    };
  });
  return result;
});
