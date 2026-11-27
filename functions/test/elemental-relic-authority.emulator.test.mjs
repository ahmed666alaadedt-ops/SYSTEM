import { test, before } from "node:test";
import assert from "node:assert/strict";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

process.env.GCLOUD_PROJECT ||= "demo-system-world";
process.env.GOOGLE_CLOUD_PROJECT ||= "demo-system-world";
process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
const api = await import("../lib/index.js");
const db = getFirestore();
const playerId = "elemental_authority_test_player";

function request(uid, data, claims = {}) {
  return { data, auth: uid ? { uid, token: claims } : null };
}
async function call(name, uid, data, claims = {}) {
  assert.equal(typeof api[name]?.run, "function", name + " must be exported");
  return api[name].run(request(uid, data, claims));
}

before(async () => {
  await db.collection("players").doc(playerId).set({ userId: playerId, displayName: "Elemental Test" });
});

test("clients cannot publish authoritative Nen or skill progression", async () => {
  await assert.rejects(() => call("syncAuthoritativeElementalProgression", playerId, {
    playerId,
    state: { nenUnlocked: true, nenControlRank: 5, level: 100, hunterRank: "SSS",
      learnedSkills: ["stormlightning_arc"], authorizedSkills: ["stormlightning_arc"],
      practiceCounts: { stormlightning_arc: 3 }, currentEnergy: 100, maxEnergy: 100 }
  }));
});

test("elemental activation requires server-verified progression and an awakened owned relic", async () => {
  const state = { nenUnlocked: true, nenControlRank: 4, level: 60, hunterRank: "S",
    learnedSkills: ["stormlightning_arc"], authorizedSkills: ["stormlightning_arc"],
    practiceCounts: { stormlightning_arc: 3 }, currentEnergy: 100, maxEnergy: 100 };
  await call("syncAuthoritativeElementalProgression", "trusted_game_server", { playerId, state }, { gameServer: true });
  await assert.rejects(() => call("authorizeElementalRelicActivation", playerId, { skillId: "stormlightning_arc" }));
  await db.collection("artifactOwnership").doc(playerId).collection("items").doc("stormlightning_crown").set({
    artifactId: "stormlightning_crown", ownerId: playerId, status: "owned",
    awakened: true, relicSkillId: "stormlightning_arc", createdAt: FieldValue.serverTimestamp()
  });
  const activation = await call("authorizeElementalRelicActivation", playerId, { skillId: "stormlightning_arc" });
  assert.equal(activation.success, true);
  assert.equal(activation.status, "authorized_pending_combat");
  assert.equal(activation.remainingEnergy, 52);
  await assert.rejects(() => call("authorizeElementalRelicActivation", playerId, { skillId: "stormlightning_arc" }));
  const combat = await db.collection("players").doc(playerId).collection("elementalCombat").doc("state").get();
  assert.equal(combat.data().energy, 52);
});

test("a non-awakened relic and an insufficient Nen rank cannot authorize an elemental skill", async () => {
  const uid = playerId + "_low_nen";
  await db.collection("players").doc(uid).set({ userId: uid });
  await call("syncAuthoritativeElementalProgression", "trusted_game_server", {
    playerId: uid,
    state: { nenUnlocked: true, nenControlRank: 1, level: 30, hunterRank: "B",
      learnedSkills: ["primordial_flame_burst"], authorizedSkills: ["primordial_flame_burst"],
      practiceCounts: { primordial_flame_burst: 3 }, currentEnergy: 100, maxEnergy: 100 }
  }, { gameServer: true });
  await db.collection("artifactOwnership").doc(uid).collection("items").doc("primordial_flame_heart").set({
    artifactId: "primordial_flame_heart", ownerId: uid, status: "owned",
    awakened: false, relicSkillId: "primordial_flame_burst"
  });
  await assert.rejects(() => call("authorizeElementalRelicActivation", uid, { skillId: "primordial_flame_burst" }));
});

test("elemental relic rewards require a completed mission roster and cannot be replayed", async () => {
  const uid = playerId + "_quest_reward";
  const server = "trusted_game_server";
  const sessionId = "elemental_mission_session_" + uid;
  await db.collection("players").doc(uid).set({ userId: uid });
  await assert.rejects(() => call("grantElementalRelicFromCompletedMission", server, {
    playerId: uid, sessionId, eventId: "relic_reward_01", artifactId: "primordial_flame_heart"
  }, { gameServer: true }));
  await db.collection("hunterGuildMissionSessions").doc(sessionId).set({
    status: "completed", rosterPlayerIds: [uid], missionId: "verified_mission_01"
  });
  const result = await call("grantElementalRelicFromCompletedMission", server, {
    playerId: uid, sessionId, eventId: "relic_reward_01", artifactId: "primordial_flame_heart"
  }, { gameServer: true });
  assert.equal(result.success, true);
  assert.equal(result.alreadyIssued, false);
  const artifact = await db.collection("artifactOwnership").doc(uid).collection("items").doc("primordial_flame_heart").get();
  assert.equal(artifact.data().awakened, true);
  assert.equal(artifact.data().relicSkillId, "primordial_flame_burst");
  const replay = await call("grantElementalRelicFromCompletedMission", server, {
    playerId: uid, sessionId, eventId: "relic_reward_01", artifactId: "primordial_flame_heart"
  }, { gameServer: true });
  assert.equal(replay.alreadyIssued, true);
  const outsider = uid + "_outsider";
  await db.collection("players").doc(outsider).set({ userId: outsider });
  await assert.rejects(() => call("grantElementalRelicFromCompletedMission", server, {
    playerId: outsider, sessionId, eventId: "relic_reward_02", artifactId: "stormlightning_crown"
  }, { gameServer: true }));
});
