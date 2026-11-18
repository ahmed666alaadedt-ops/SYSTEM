import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();
const MAX_PARTY_MEMBERS = 6;

function requirePlayer(request: any): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "سجّل الدخول بحساب لاعب أولاً.");
  }
  return request.auth.uid;
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

function partyPayload(id: string, data: FirebaseFirestore.DocumentData) {
  return {
    partyId: id,
    name: String(data.name || "فريق اللاعبين"),
    leaderId: String(data.leaderId || ""),
    memberIds: Array.isArray(data.memberIds) ? data.memberIds : [],
    createdAt: data.createdAt?.toMillis?.() ?? null,
    updatedAt: data.updatedAt?.toMillis?.() ?? null,
    maxMembers: MAX_PARTY_MEMBERS
  };
}

export const createPlayerParty = onCall(async (request) => {
  const uid = requirePlayer(request);
  const name = requiredText(request.data?.name, "name", 32);
  const playerRef = db.collection("players").doc(uid);
  const partyRef = db.collection("playerParties").doc();

  const party = await db.runTransaction(async (transaction) => {
    const playerSnapshot = await transaction.get(playerRef);
    if (!playerSnapshot.exists) {
      throw new HttpsError("failed-precondition", "ملف اللاعب غير مكتمل.");
    }
    const player = playerSnapshot.data()!;
    const now = FieldValue.serverTimestamp();
    const data = {
      name,
      leaderId: uid,
      leaderName: String(player.displayName || "لاعب"),
      memberIds: [uid],
      createdAt: now,
      updatedAt: now
    };
    transaction.create(partyRef, data);
    return { ...data, createdAt: null, updatedAt: null };
  });

  return { party: partyPayload(partyRef.id, party) };
});

export const invitePlayerToParty = onCall(async (request) => {
  const uid = requirePlayer(request);
  const partyId = requiredText(request.data?.partyId, "partyId", 128);
  const targetUid = requiredText(request.data?.targetPlayerId, "targetPlayerId", 128);
  if (targetUid === uid) {
    throw new HttpsError("invalid-argument", "لا يمكنك دعوة نفسك.");
  }

  const partyRef = db.collection("playerParties").doc(partyId);
  const targetRef = db.collection("players").doc(targetUid);
  const inviteRef = db.collection("playerPartyInvites").doc(`${partyId}_${targetUid}`);

  const result = await db.runTransaction(async (transaction) => {
    const [partySnapshot, targetSnapshot, inviteSnapshot] = await Promise.all([
      transaction.get(partyRef),
      transaction.get(targetRef),
      transaction.get(inviteRef)
    ]);
    if (!partySnapshot.exists) throw new HttpsError("not-found", "الفريق غير موجود.");
    if (!targetSnapshot.exists) throw new HttpsError("not-found", "لم يتم العثور على حساب اللاعب.");
    const party = partySnapshot.data()!;
    const memberIds: string[] = Array.isArray(party.memberIds) ? party.memberIds : [];
    if (party.leaderId !== uid) throw new HttpsError("permission-denied", "دعوة الأعضاء متاحة لقائد الفريق فقط.");
    if (memberIds.includes(targetUid)) throw new HttpsError("already-exists", "اللاعب عضو في الفريق بالفعل.");
    if (memberIds.length >= MAX_PARTY_MEMBERS) throw new HttpsError("resource-exhausted", "وصل الفريق إلى الحد الأقصى: 6 لاعبين.");
    if (inviteSnapshot.exists && inviteSnapshot.data()?.status === "pending") {
      throw new HttpsError("already-exists", "توجد دعوة معلقة لهذا اللاعب.");
    }
    const inviter = await transaction.get(db.collection("players").doc(uid));
    const inviterName = inviter.exists ? String(inviter.data()?.displayName || "لاعب") : "لاعب";
    transaction.set(inviteRef, {
      partyId,
      partyName: String(party.name || "فريق اللاعبين"),
      fromUid: uid,
      fromName: inviterName,
      toUid: targetUid,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
    return { inviteId: inviteRef.id, status: "pending" };
  });
  return result;
});

export const respondToPlayerPartyInvite = onCall(async (request) => {
  const uid = requirePlayer(request);
  const inviteId = requiredText(request.data?.inviteId, "inviteId", 256);
  const accept = request.data?.accept;
  if (typeof accept !== "boolean") throw new HttpsError("invalid-argument", "قرار الدعوة غير صالح.");

  const inviteRef = db.collection("playerPartyInvites").doc(inviteId);
  const result = await db.runTransaction(async (transaction) => {
    const inviteSnapshot = await transaction.get(inviteRef);
    if (!inviteSnapshot.exists) throw new HttpsError("not-found", "الدعوة غير موجودة.");
    const invite = inviteSnapshot.data()!;
    if (invite.toUid !== uid) throw new HttpsError("permission-denied", "هذه الدعوة ليست موجهة إلى حسابك.");
    if (invite.status !== "pending") throw new HttpsError("failed-precondition", "تم التعامل مع هذه الدعوة سابقاً.");
    const partyRef = db.collection("playerParties").doc(String(invite.partyId));
    const partySnapshot = await transaction.get(partyRef);
    if (!partySnapshot.exists) {
      transaction.update(inviteRef, { status: "expired", updatedAt: FieldValue.serverTimestamp() });
      return { status: "expired", party: null };
    }
    const party = partySnapshot.data()!;
    const memberIds: string[] = Array.isArray(party.memberIds) ? [...party.memberIds] : [];
    if (!accept) {
      transaction.update(inviteRef, { status: "declined", updatedAt: FieldValue.serverTimestamp() });
      return { status: "declined", party: null };
    }
    if (!memberIds.includes(uid) && memberIds.length >= MAX_PARTY_MEMBERS) {
      throw new HttpsError("resource-exhausted", "امتلأ الفريق قبل قبول الدعوة.");
    }
    if (!memberIds.includes(uid)) memberIds.push(uid);
    transaction.update(partyRef, { memberIds, updatedAt: FieldValue.serverTimestamp() });
    transaction.update(inviteRef, { status: "accepted", updatedAt: FieldValue.serverTimestamp() });
    return {
      status: "accepted",
      party: {
        partyId: partyRef.id,
        name: String(party.name || "فريق اللاعبين"),
        leaderId: String(party.leaderId || ""),
        memberIds,
        maxMembers: MAX_PARTY_MEMBERS
      }
    };
  });
  return result;
});

export const leavePlayerParty = onCall(async (request) => {
  const uid = requirePlayer(request);
  const partyId = requiredText(request.data?.partyId, "partyId", 128);
  const partyRef = db.collection("playerParties").doc(partyId);
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(partyRef);
    if (!snapshot.exists) throw new HttpsError("not-found", "الفريق غير موجود.");
    const party = snapshot.data()!;
    const memberIds: string[] = Array.isArray(party.memberIds) ? [...party.memberIds] : [];
    if (!memberIds.includes(uid)) throw new HttpsError("permission-denied", "أنت لست عضواً في هذا الفريق.");
    const remaining = memberIds.filter((memberId) => memberId !== uid);
    if (remaining.length === 0) {
      transaction.delete(partyRef);
      return { status: "disbanded" };
    }
    const update: Record<string, unknown> = {
      memberIds: remaining,
      updatedAt: FieldValue.serverTimestamp()
    };
    if (party.leaderId === uid) {
      update.leaderId = remaining[0];
      const nextLeader = await transaction.get(db.collection("players").doc(remaining[0]));
      update.leaderName = nextLeader.exists ? String(nextLeader.data()?.displayName || "لاعب") : "لاعب";
    }
    transaction.update(partyRef, update);
    return { status: "left", newLeaderId: update.leaderId || party.leaderId };
  });
  return result;
});

export const listMyPlayerParties = onCall(async (request) => {
  const uid = requirePlayer(request);
  const snapshot = await db.collection("playerParties")
    .where("memberIds", "array-contains", uid)
    .limit(30)
    .get();
  return {
    parties: snapshot.docs.map((doc) => partyPayload(doc.id, doc.data()))
  };
});

export const listMyPlayerPartyInvites = onCall(async (request) => {
  const uid = requirePlayer(request);
  const snapshot = await db.collection("playerPartyInvites")
    .where("toUid", "==", uid)
    .where("status", "==", "pending")
    .limit(30)
    .get();
  return {
    invites: snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        inviteId: doc.id,
        partyId: String(data.partyId || ""),
        partyName: String(data.partyName || "فريق اللاعبين"),
        fromUid: String(data.fromUid || ""),
        fromName: String(data.fromName || "لاعب"),
        createdAt: data.createdAt?.toMillis?.() ?? null
      };
    })
  };
});
