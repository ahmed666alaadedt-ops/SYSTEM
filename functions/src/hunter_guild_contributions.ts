import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();
const EVENT_RULES: Record<string, { pointsPerUnit: number; maxUnits: number }> = {
  damage: { pointsPerUnit: 0.1, maxUnits: 10000 },
  healing: { pointsPerUnit: 0.12, maxUnits: 10000 },
  objective: { pointsPerUnit: 100, maxUnits: 1 },
  revive: { pointsPerUnit: 60, maxUnits: 1 },
  discovery: { pointsPerUnit: 25, maxUnits: 1 },
  survival: { pointsPerUnit: 1, maxUnits: 1 }
};

function requirePlayer(request: any): string {
  if (!request.auth) throw new HttpsError("unauthenticated", "سجّل الدخول بحساب لاعب أولاً.");
  return request.auth.uid;
}

function requireGameServer(request: any): string {
  const uid = requirePlayer(request);
  if (request.auth.token.gameServer !== true) {
    throw new HttpsError("permission-denied", "تسجيل أحداث اللعب الموثوقة متاح لخادم اللعبة فقط.");
  }
  return uid;
}

function requiredText(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string") throw new HttpsError("invalid-argument", `الحقل ${field} غير صالح.`);
  const clean = value.trim();
  if (!clean || clean.length > maxLength) throw new HttpsError("invalid-argument", `تحقق من الحقل ${field}.`);
  return clean;
}

/** The party leader opens the registered mission session. */
export const startHunterGuildMission = onCall(async (request) => {
  const uid = requirePlayer(request);
  const assignmentId = requiredText(request.data?.assignmentId, "assignmentId", 256);
  const assignmentRef = db.collection("hunterGuildMissionAssignments").doc(assignmentId);
  const sessionRef = db.collection("hunterGuildMissionSessions").doc(assignmentId);

  const result = await db.runTransaction(async (transaction) => {
    const [assignmentSnapshot, sessionSnapshot] = await Promise.all([
      transaction.get(assignmentRef),
      transaction.get(sessionRef)
    ]);
    if (!assignmentSnapshot.exists) throw new HttpsError("not-found", "تسجيل المهمة غير موجود.");
    const assignment = assignmentSnapshot.data()!;
    if (assignment.leaderId !== uid) throw new HttpsError("permission-denied", "قائد الفريق فقط يستطيع بدء المهمة.");
    if (sessionSnapshot.exists) {
      const existing = sessionSnapshot.data()!;
      if (existing.status === "active") {
        return { sessionId: sessionRef.id, status: "active", alreadyStarted: true };
      }
      throw new HttpsError("failed-precondition", "تم إنهاء جلسة هذه المهمة أو إغلاقها.");
    }
    if (assignment.status !== "registered") {
      throw new HttpsError("failed-precondition", "التسجيل ليس في حالة تسمح ببدء المهمة.");
    }
    const roster = Array.isArray(assignment.rosterSnapshot) ? assignment.rosterSnapshot : [];
    const rosterPlayerIds = roster.map((entry: any) => entry?.playerId).filter((id: unknown) => typeof id === "string");
    if (rosterPlayerIds.length === 0 || rosterPlayerIds.length !== roster.length ||
        new Set(rosterPlayerIds).size !== rosterPlayerIds.length) {
      throw new HttpsError("failed-precondition", "قائمة المشاركين المحفوظة غير صالحة.");
    }
    const profileSnapshots = [];
    for (const playerId of rosterPlayerIds) {
      profileSnapshots.push(await transaction.get(db.collection("players").doc(playerId)));
    }
    if (profileSnapshots.some((snapshot) => !snapshot.exists)) {
      throw new HttpsError("failed-precondition", "أحد حسابات المشاركين لم يعد صالحاً.");
    }

    transaction.create(sessionRef, {
      assignmentId,
      missionId: String(assignment.missionId || ""),
      missionTitle: String(assignment.missionTitle || "مهمة XSX"),
      partyId: String(assignment.partyId || ""),
      partyName: String(assignment.partyName || "فريق اللاعبين"),
      leaderId: uid,
      rosterSnapshot: roster,
      rosterPlayerIds,
      status: "active",
      startedAt: FieldValue.serverTimestamp(),
      startedBy: uid,
      verifiedEventCount: 0
    });
    transaction.update(assignmentRef, {
      status: "active",
      startedAt: FieldValue.serverTimestamp(),
      sessionId: sessionRef.id
    });
    return { sessionId: sessionRef.id, status: "active", alreadyStarted: false };
  });
  return result;
});

/**
 * Only a trusted game server (Firebase custom claim gameServer=true) can submit
 * authoritative gameplay events. The Android client must never call this.
 */
export const recordHunterGuildGameplayEvent = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const sessionId = requiredText(request.data?.sessionId, "sessionId", 256);
  const playerId = requiredText(request.data?.playerId, "playerId", 128);
  const eventId = requiredText(request.data?.eventId, "eventId", 128);
  if (!/^[A-Za-z0-9_-]+$/.test(eventId)) {
    throw new HttpsError("invalid-argument", "معرّف الحدث يحتوي رموزاً غير مسموحة.");
  }
  const eventType = requiredText(request.data?.eventType, "eventType", 24);
  const rule = EVENT_RULES[eventType];
  if (!rule) throw new HttpsError("invalid-argument", "نوع مساهمة غير معروف.");
  const units = request.data?.units;
  if (typeof units !== "number" || !Number.isInteger(units) || units < 1 || units > rule.maxUnits) {
    throw new HttpsError("invalid-argument", "قيمة الحدث خارج الحدود المسموحة.");
  }
  const points = Math.round(units * rule.pointsPerUnit * 100) / 100;
  const sessionRef = db.collection("hunterGuildMissionSessions").doc(sessionId);
  const eventRef = sessionRef.collection("events").doc(eventId);
  const contributionRef = sessionRef.collection("contributions").doc(playerId);

  const result = await db.runTransaction(async (transaction) => {
    const [sessionSnapshot, eventSnapshot, contributionSnapshot] = await Promise.all([
      transaction.get(sessionRef),
      transaction.get(eventRef),
      transaction.get(contributionRef)
    ]);
    if (!sessionSnapshot.exists) throw new HttpsError("not-found", "جلسة المهمة غير موجودة.");
    if (eventSnapshot.exists) throw new HttpsError("already-exists", "تم تسجيل هذا الحدث مسبقاً.");
    const session = sessionSnapshot.data()!;
    if (session.status !== "active") throw new HttpsError("failed-precondition", "جلسة المهمة ليست نشطة.");
    const rosterIds: string[] = Array.isArray(session.rosterPlayerIds) ? session.rosterPlayerIds : [];
    if (!rosterIds.includes(playerId)) {
      throw new HttpsError("permission-denied", "اللاعب ليس ضمن قائمة المشاركين المثبتة لهذه المهمة.");
    }

    const previous = contributionSnapshot.exists ? contributionSnapshot.data()! : {};
    const windowStart = previous.windowStartedAt as Timestamp | undefined;
    const now = Date.now();
    const sameWindow = windowStart && now - windowStart.toMillis() < 60_000;
    const windowCount = sameWindow ? Number(previous.windowEventCount || 0) : 0;
    if (windowCount >= 120) {
      throw new HttpsError("resource-exhausted", "تم تجاوز معدل أحداث المساهمة المسموح.");
    }

    const eventCounts = { ...(previous.eventCounts || {}) } as Record<string, number>;
    eventCounts[eventType] = Number(eventCounts[eventType] || 0) + 1;
    transaction.create(eventRef, {
      eventId,
      playerId,
      eventType,
      units,
      points,
      verified: true,
      source: "trusted_game_server",
      gameServerUid: serverUid,
      recordedAt: FieldValue.serverTimestamp()
    });
    transaction.set(contributionRef, {
      playerId,
      displayName: String((session.rosterSnapshot || []).find((entry: any) => entry.playerId === playerId)?.displayName || "لاعب"),
      totalPoints: Number(previous.totalPoints || 0) + points,
      eventCounts,
      lastEventAt: FieldValue.serverTimestamp(),
      windowStartedAt: sameWindow ? windowStart : Timestamp.fromMillis(now),
      windowEventCount: windowCount + 1
    }, { merge: true });
    transaction.update(sessionRef, {
      verifiedEventCount: Number(session.verifiedEventCount || 0) + 1,
      updatedAt: FieldValue.serverTimestamp()
    });
    return { status: "recorded", verified: true, pointsAdded: points };
  });
  return result;
});

/** Team members can view verified contribution totals for their active/completed sessions. */
export const listMyHunterGuildMissionContributions = onCall(async (request) => {
  const uid = requirePlayer(request);
  const sessions = await db.collection("hunterGuildMissionSessions")
    .where("rosterPlayerIds", "array-contains", uid)
    .limit(30)
    .get();

  const results = [];
  for (const sessionDoc of sessions.docs) {
    const session = sessionDoc.data();
    const contributionSnapshot = await sessionDoc.ref.collection("contributions").get();
    const contributions = contributionSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        playerId: String(data.playerId || doc.id),
        displayName: String(data.displayName || "لاعب"),
        totalPoints: Number(data.totalPoints || 0),
        eventCounts: data.eventCounts || {}
      };
    });
    results.push({
      sessionId: sessionDoc.id,
      missionTitle: String(session.missionTitle || "مهمة XSX"),
      partyName: String(session.partyName || "فريق اللاعبين"),
      status: String(session.status || "active"),
      verifiedEventCount: Number(session.verifiedEventCount || 0),
      contributions
    });
  }
  return { sessions: results };
});


/** Only the trusted game server can close an active mission session. No rewards are granted here. */
export const finishHunterGuildMissionSession = onCall(async (request) => {
  const serverUid = requireGameServer(request);
  const sessionId = requiredText(request.data?.sessionId, "sessionId", 256);
  const sessionRef = db.collection("hunterGuildMissionSessions").doc(sessionId);

  const result = await db.runTransaction(async (transaction) => {
    const sessionSnapshot = await transaction.get(sessionRef);
    if (!sessionSnapshot.exists) throw new HttpsError("not-found", "جلسة المهمة غير موجودة.");
    const session = sessionSnapshot.data()!;
    if (session.status === "completed") {
      return { status: "completed", alreadyCompleted: true };
    }
    if (session.status !== "active") {
      throw new HttpsError("failed-precondition", "جلسة المهمة ليست نشطة.");
    }
    const assignmentRef = db.collection("hunterGuildMissionAssignments").doc(sessionId);
    const missionRef = db.collection("hunterGuildMissions").doc(String(session.missionId || ""));
    const [assignmentSnapshot, missionSnapshot] = await Promise.all([
      transaction.get(assignmentRef),
      transaction.get(missionRef)
    ]);
    if (!assignmentSnapshot.exists || !missionSnapshot.exists) {
      throw new HttpsError("failed-precondition", "سجل المهمة أو المهمة الأصلية غير موجود.");
    }
    const mission = missionSnapshot.data()!;
    transaction.update(sessionRef, {
      status: "completed",
      completedAt: FieldValue.serverTimestamp(),
      completedByGameServer: serverUid
    });
    transaction.update(assignmentRef, {
      status: "completed",
      completedAt: FieldValue.serverTimestamp()
    });
    transaction.update(missionRef, {
      activeTeamCount: Math.max(0, Number(mission.activeTeamCount || 0) - 1),
      updatedAt: FieldValue.serverTimestamp()
    });
    return { status: "completed", alreadyCompleted: false };
  });
  return result;
});
