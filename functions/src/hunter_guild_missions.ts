import { FieldValue, Timestamp, getFirestore, type DocumentData } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();
const MAX_PARTY_SIZE = 6;

function requirePlayer(request: any): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "سجّل الدخول بحساب لاعب أولاً.");
  }
  return request.auth.uid;
}

function requireModerator(request: any): string {
  const uid = requirePlayer(request);
  if (request.auth.token.moderator !== true) {
    throw new HttpsError("permission-denied", "نشر مهمات XSX متاح للمشرفين فقط.");
  }
  return uid;
}

function requiredText(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `الحقل ${field} غير صالح.`);
  }
  const clean = value.trim();
  if (!clean || clean.length > maxLength) {
    throw new HttpsError("invalid-argument", `تحقق من الحقل ${field}.`);
  }
  return clean;
}

function missionPayload(id: string, data: DocumentData) {
  const closesAt = data.closesAt as Timestamp | undefined;
  return {
    missionId: id,
    title: String(data.title || "مهمة XSX"),
    description: String(data.description || ""),
    worldId: String(data.worldId || "modern"),
    category: String(data.category || "general"),
    rank: String(data.rank || "E"),
    minMembers: Number(data.minMembers || 1),
    maxMembers: Number(data.maxMembers || MAX_PARTY_SIZE),
    maxTeams: Number(data.maxTeams || 1),
    activeTeamCount: Number(data.activeTeamCount || 0),
    closesAt: closesAt?.toMillis?.() ?? null,
    status: String(data.status || "open")
  };
}

/**
 * Trusted XSX staff publish missions. Clients cannot create mission records.
 * Required document schema is initialized here, not supplied by party leaders.
 */
export const publishHunterGuildMission = onCall(async (request) => {
  const moderatorUid = requireModerator(request);
  const title = requiredText(request.data?.title, "title", 80);
  const description = requiredText(request.data?.description, "description", 1200);
  const worldId = requiredText(request.data?.worldId, "worldId", 32);
  const category = requiredText(request.data?.category, "category", 40);
  const rank = requiredText(request.data?.rank, "rank", 8).toUpperCase();
  const minMembers = Number(request.data?.minMembers ?? 1);
  const maxMembers = Number(request.data?.maxMembers ?? MAX_PARTY_SIZE);
  const maxTeams = Number(request.data?.maxTeams ?? 1);
  const closesAtMs = request.data?.closesAtMs;

  if (!Number.isInteger(minMembers) || minMembers < 1 ||
      !Number.isInteger(maxMembers) || maxMembers > MAX_PARTY_SIZE ||
      maxMembers < minMembers) {
    throw new HttpsError("invalid-argument", "نطاق عدد أعضاء الفريق غير صالح (1 إلى 6).");
  }
  if (!Number.isInteger(maxTeams) || maxTeams < 1 || maxTeams > 100) {
    throw new HttpsError("invalid-argument", "الحد الأقصى للفرق يجب أن يكون بين 1 و100.");
  }
  if (closesAtMs !== undefined &&
      (typeof closesAtMs !== "number" || !Number.isFinite(closesAtMs) || closesAtMs <= Date.now())) {
    throw new HttpsError("invalid-argument", "موعد إغلاق المهمة غير صالح.");
  }

  const missionRef = db.collection("hunterGuildMissions").doc();
  const missionData = {
    title,
    description,
    worldId,
    category,
    rank,
    minMembers,
    maxMembers,
    maxTeams,
    activeTeamCount: 0,
    status: "open",
    publishedBy: moderatorUid,
    publishedAt: FieldValue.serverTimestamp(),
    closesAt: typeof closesAtMs === "number" ? Timestamp.fromMillis(closesAtMs) : null
  };
  await missionRef.create(missionData);
  return { mission: missionPayload(missionRef.id, missionData) };
});

/** Lists only missions that are open and have not passed their closing time. */
export const listAvailableHunterGuildMissions = onCall(async (request) => {
  requirePlayer(request);
  const now = Date.now();
  const snapshot = await db.collection("hunterGuildMissions")
    .where("status", "==", "open")
    .limit(50)
    .get();

  const missions = snapshot.docs
    .map((doc) => missionPayload(doc.id, doc.data()))
    .filter((mission) => mission.closesAt === null || mission.closesAt > now)
    .filter((mission) => mission.activeTeamCount < mission.maxTeams);
  return { missions };
});

/**
 * The party leader registers the existing real-player party.
 * A server-created immutable roster snapshot is stored with the assignment.
 */
export const registerPartyForHunterGuildMission = onCall(async (request) => {
  const uid = requirePlayer(request);
  const missionId = requiredText(request.data?.missionId, "missionId", 128);
  const partyId = requiredText(request.data?.partyId, "partyId", 128);

  const missionRef = db.collection("hunterGuildMissions").doc(missionId);
  const partyRef = db.collection("playerParties").doc(partyId);
  const assignmentId = `${missionId}_${partyId}`;
  const assignmentRef = db.collection("hunterGuildMissionAssignments").doc(assignmentId);

  const result = await db.runTransaction(async (transaction) => {
    const [missionSnapshot, partySnapshot, assignmentSnapshot] = await Promise.all([
      transaction.get(missionRef),
      transaction.get(partyRef),
      transaction.get(assignmentRef)
    ]);

    if (!missionSnapshot.exists) throw new HttpsError("not-found", "مهمة XSX غير موجودة.");
    if (!partySnapshot.exists) throw new HttpsError("not-found", "فريق اللاعبين غير موجود.");
    if (assignmentSnapshot.exists) {
      throw new HttpsError("already-exists", "هذا الفريق مسجل بهذه المهمة مسبقاً.");
    }

    const mission = missionSnapshot.data()!;
    const party = partySnapshot.data()!;
    const memberIds: string[] = Array.isArray(party.memberIds) ? party.memberIds : [];
    if (party.leaderId !== uid) {
      throw new HttpsError("permission-denied", "قائد الفريق فقط يستطيع تسجيله في المهمة.");
    }
    if (!memberIds.includes(uid) || memberIds.length === 0 || memberIds.length > MAX_PARTY_SIZE ||
        new Set(memberIds).size !== memberIds.length) {
      throw new HttpsError("failed-precondition", "قائمة أعضاء الفريق غير صالحة.");
    }
    if (mission.status !== "open") {
      throw new HttpsError("failed-precondition", "المهمة لم تعد متاحة للتسجيل.");
    }
    const closesAt = mission.closesAt as Timestamp | null;
    if (closesAt && closesAt.toMillis() <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "انتهت مدة التسجيل في هذه المهمة.");
    }
    const minMembers = Number(mission.minMembers || 1);
    const maxMembers = Number(mission.maxMembers || MAX_PARTY_SIZE);
    if (memberIds.length < minMembers || memberIds.length > maxMembers) {
      throw new HttpsError("failed-precondition", `تتطلب المهمة فريقاً من ${minMembers} إلى ${maxMembers} لاعبين.`);
    }
    const activeTeamCount = Number(mission.activeTeamCount || 0);
    const maxTeams = Number(mission.maxTeams || 1);
    if (activeTeamCount >= maxTeams) {
      throw new HttpsError("resource-exhausted", "اكتمل عدد الفرق المسموح لهذه المهمة.");
    }

    // Read every real player profile before writing any transaction document.
    const roster: Array<{ playerId: string; displayName: string }> = [];
    for (const memberId of memberIds) {
      const playerSnapshot = await transaction.get(db.collection("players").doc(memberId));
      if (!playerSnapshot.exists) {
        throw new HttpsError("failed-precondition", "يحتوي الفريق على حساب لاعب غير مكتمل.");
      }
      roster.push({
        playerId: memberId,
        displayName: String(playerSnapshot.data()?.displayName || "لاعب")
      });
    }

    const assignmentData = {
      missionId,
      missionTitle: String(mission.title || "مهمة XSX"),
      partyId,
      partyName: String(party.name || "فريق اللاعبين"),
      leaderId: uid,
      rosterSnapshot: roster,
      rosterPlayerIds: memberIds,
      status: "registered",
      registeredAt: FieldValue.serverTimestamp(),
      // Contribution and rewards are deliberately not client-writable.
      contributionStatus: "not_started"
    };
    transaction.create(assignmentRef, assignmentData);
    transaction.update(missionRef, {
      activeTeamCount: activeTeamCount + 1,
      updatedAt: FieldValue.serverTimestamp()
    });
    return {
      assignmentId,
      missionId,
      partyId,
      status: "registered",
      rosterSnapshot: roster
    };
  });

  return result;
});

/** Lists assignments for teams the signed-in player currently belongs to. */
export const listMyHunterGuildMissionAssignments = onCall(async (request) => {
  const uid = requirePlayer(request);
  const snapshot = await db.collection("hunterGuildMissionAssignments")
    .where("rosterPlayerIds", "array-contains", uid)
    .limit(50)
    .get();

  return {
    assignments: snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        assignmentId: doc.id,
        missionId: String(data.missionId || ""),
        missionTitle: String(data.missionTitle || "مهمة XSX"),
        partyId: String(data.partyId || ""),
        partyName: String(data.partyName || "فريق اللاعبين"),
        leaderId: String(data.leaderId || ""),
        status: String(data.status || "registered"),
        rosterSnapshot: Array.isArray(data.rosterSnapshot) ? data.rosterSnapshot : [],
        registeredAt: data.registeredAt?.toMillis?.() ?? null
      };
    })
  };
});
