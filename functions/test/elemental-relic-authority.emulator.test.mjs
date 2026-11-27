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

async function createActiveCombatSession(uid) {
  const sessionId = "session_" + uid;
  await db.collection("players").doc(uid).collection("combatState").doc("session").set({
    active: true, playerId: uid, sessionId,
    playerPosition: { x: 0, y: 0, z: 0 },
    lastServerTickMs: Date.now()
  });
  return sessionId;
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


test("trusted combat server consumes elemental receipts once and applies server-side boss resistance", async () => {
  const uid = playerId + "_combat_resolver";
  const server = "trusted_game_server";
  await db.collection("players").doc(uid).set({ userId: uid });
  await call("syncAuthoritativeElementalProgression", server, {
    playerId: uid,
    state: { nenUnlocked: true, nenControlRank: 4, level: 60, hunterRank: "S",
      learnedSkills: ["stormlightning_arc"], authorizedSkills: ["stormlightning_arc"],
      practiceCounts: { stormlightning_arc: 3 }, currentEnergy: 100, maxEnergy: 100 }
  }, { gameServer: true });
  await db.collection("artifactOwnership").doc(uid).collection("items").doc("stormlightning_crown").set({
    artifactId: "stormlightning_crown", ownerId: uid, status: "owned",
    awakened: true, relicSkillId: "stormlightning_arc"
  });
  const receipt = await call("authorizeElementalRelicActivation", uid, { skillId: "stormlightning_arc" });
  const sessionId = await createActiveCombatSession(uid);
  const targetId = "elemental_boss_" + uid;
  await db.collection("combatTargets").doc(targetId).set({
    kind: "boss", health: 200, maxHealth: 200, isAlive: true,
    sessionId, position: { x: 0, y: 0, z: -10 }, lastServerTickMs: Date.now(),
    elementalResistance: { lightning: 0.25 }
  });
  const resolved = await call("resolveElementalRelicCombat", server, {
    playerId: uid, activationId: receipt.activationId, targetId
  }, { gameServer: true });
  assert.equal(resolved.success, true);
  assert.equal(resolved.result.damage, 12);
  assert.equal(resolved.result.remainingHealth, 188);
  const target = await db.collection("combatTargets").doc(targetId).get();
  assert.equal(target.data().health, 188);
  await assert.rejects(() => call("resolveElementalRelicCombat", server, {
    playerId: uid, activationId: receipt.activationId, targetId
  }, { gameServer: true }));
});

test("trusted combat resolver applies water healing, earth guard and air dash to server state", async () => {
  const cases = [
    { uid: playerId + "_water_resolve", skill: "tideheart_restoration", artifact: "tideheart_pearl", elementRank: 3 },
    { uid: playerId + "_earth_resolve", skill: "worldroot_earthguard", artifact: "worldroot_geode", elementRank: 3 },
    { uid: playerId + "_air_resolve", skill: "stormwind_aerial_step", artifact: "stormwind_sigil", elementRank: 2 }
  ];
  for (const item of cases) {
    await db.collection("players").doc(item.uid).set({ userId: item.uid });
    await call("syncAuthoritativeElementalProgression", "trusted_game_server", {
      playerId: item.uid,
      state: { nenUnlocked: true, nenControlRank: 4, level: 60, hunterRank: "S",
        learnedSkills: [item.skill], authorizedSkills: [item.skill],
        practiceCounts: { [item.skill]: 3 }, currentEnergy: 100, maxEnergy: 100 }
    }, { gameServer: true });
    await db.collection("artifactOwnership").doc(item.uid).collection("items").doc(item.artifact).set({
      artifactId: item.artifact, ownerId: item.uid, status: "owned",
      awakened: true, relicSkillId: item.skill
    });
    await createActiveCombatSession(item.uid);
    if (item.skill === "tideheart_restoration") {
      await db.collection("players").doc(item.uid).collection("combatState").doc("vitals").set({ health: 50, maxHealth: 100 });
    }
    const receipt = await call("authorizeElementalRelicActivation", item.uid, { skillId: item.skill });
    const resolved = await call("resolveElementalRelicCombat", "trusted_game_server", {
      playerId: item.uid, activationId: receipt.activationId
    }, { gameServer: true });
    assert.equal(resolved.success, true);
    const status = await db.collection("players").doc(item.uid).collection("combatState").doc("elemental_status").get();
    assert.equal(status.exists, true);
    if (item.skill === "tideheart_restoration") {
      const vitals = await db.collection("players").doc(item.uid).collection("combatState").doc("vitals").get();
      assert.equal(vitals.data().health, 72);
    }
  }
});


test("elemental combat rejects missing, stale and out-of-range server session state", async () => {
  const uid = playerId + "_invalid_session";
  await db.collection("players").doc(uid).set({ userId: uid });
  await call("syncAuthoritativeElementalProgression", "trusted_game_server", {
    playerId: uid,
    state: { nenUnlocked: true, nenControlRank: 4, level: 60, hunterRank: "S",
      learnedSkills: ["stormlightning_arc"], authorizedSkills: ["stormlightning_arc"],
      practiceCounts: { stormlightning_arc: 3 }, currentEnergy: 100, maxEnergy: 100 }
  }, { gameServer: true });
  await db.collection("artifactOwnership").doc(uid).collection("items").doc("stormlightning_crown").set({
    artifactId: "stormlightning_crown", ownerId: uid, status: "owned",
    awakened: true, relicSkillId: "stormlightning_arc"
  });
  const receipt = await call("authorizeElementalRelicActivation", uid, { skillId: "stormlightning_arc" });
  await assert.rejects(() => call("resolveElementalRelicCombat", "trusted_game_server", {
    playerId: uid, activationId: receipt.activationId
  }, { gameServer: true }));

  const sessionId = await createActiveCombatSession(uid);
  await db.collection("combatTargets").doc("far_target_" + uid).set({
    kind: "monster", health: 100, maxHealth: 100, isAlive: true,
    sessionId, position: { x: 0, y: 0, z: -100 }, lastServerTickMs: Date.now()
  });
  await assert.rejects(() => call("resolveElementalRelicCombat", "trusted_game_server", {
    playerId: uid, activationId: receipt.activationId, targetId: "far_target_" + uid
  }, { gameServer: true }));
  await db.collection("players").doc(uid).collection("combatState").doc("session").update({
    lastServerTickMs: Date.now() - 5000
  });
  await assert.rejects(() => call("resolveElementalRelicCombat", "trusted_game_server", {
    playerId: uid, activationId: receipt.activationId
  }, { gameServer: true }));
});


test("combat frames are accepted only from the trusted server and reject stale or replayed ticks", async () => {
  const uid = playerId + "_frame_ingress";
  const server = "trusted_game_server";
  await db.collection("players").doc(uid).set({ userId: uid });
  const frame = {
    playerId: uid,
    sessionId: "live_session_01",
    tickSequence: 1,
    serverTickMs: Date.now(),
    active: true,
    playerPosition: { x: 0, y: 0, z: 0 },
    targets: [{
      id: "boss_01", kind: "boss", health: 200, maxHealth: 200, isAlive: true,
      position: { x: 0, y: 0, z: -10 },
      elementalResistance: { lightning: 0.25 }
    }],
    playerVitals: { health: 75, maxHealth: 100 }
  };
  await assert.rejects(() => call("publishAuthoritativeCombatFrame", uid, frame));
  const published = await call("publishAuthoritativeCombatFrame", server, frame, { gameServer: true });
  assert.equal(published.success, true);
  const targetId = published.targetDocumentIds.boss_01;
  assert.ok(targetId);
  const session = await db.collection("players").doc(uid).collection("combatState").doc("session").get();
  assert.equal(session.data().sessionId, frame.sessionId);
  assert.equal(session.data().tickSequence, 1);
  const vitals = await db.collection("players").doc(uid).collection("combatState").doc("vitals").get();
  assert.equal(vitals.data().health, 75);

  await assert.rejects(() => call("publishAuthoritativeCombatFrame", server, frame, { gameServer: true }));
  await assert.rejects(() => call("publishAuthoritativeCombatFrame", server, {
    ...frame, tickSequence: 2, serverTickMs: Date.now() - 5000
  }, { gameServer: true }));

  const nextFrame = { ...frame, tickSequence: 2, serverTickMs: Date.now(),
    targets: [{ ...frame.targets[0], health: 180 }] };
  const next = await call("publishAuthoritativeCombatFrame", server, nextFrame, { gameServer: true });
  assert.equal(next.success, true);
  const target = await db.collection("combatTargets").doc(targetId).get();
  assert.equal(target.data().health, 180);
});

test("trusted combat frame ingress rejects duplicate targets, invalid resistance and cross-session replacement", async () => {
  const uid = playerId + "_frame_validation";
  const server = "trusted_game_server";
  await db.collection("players").doc(uid).set({ userId: uid });
  const base = {
    playerId: uid, sessionId: "frame_validation_session", tickSequence: 1,
    serverTickMs: Date.now(), active: true,
    playerPosition: { x: 0, y: 0, z: 0 }, targets: []
  };
  await call("publishAuthoritativeCombatFrame", server, base, { gameServer: true });
  await assert.rejects(() => call("publishAuthoritativeCombatFrame", server, {
    ...base, tickSequence: 2, serverTickMs: Date.now(), sessionId: "another_session"
  }, { gameServer: true }));
  await assert.rejects(() => call("publishAuthoritativeCombatFrame", server, {
    ...base, tickSequence: 2, serverTickMs: Date.now(),
    targets: [
      { id: "same_target", kind: "monster", health: 10, maxHealth: 10, isAlive: true, position: { x: 0, y: 0, z: 1 } },
      { id: "same_target", kind: "monster", health: 10, maxHealth: 10, isAlive: true, position: { x: 0, y: 0, z: 1 } }
    ]
  }, { gameServer: true }));
  await assert.rejects(() => call("publishAuthoritativeCombatFrame", server, {
    ...base, tickSequence: 2, serverTickMs: Date.now(),
    targets: [{ id: "bad_resistance", kind: "monster", health: 10, maxHealth: 10, isAlive: true,
      position: { x: 0, y: 0, z: 1 }, elementalResistance: { lightning: 1.5 } }]
  }, { gameServer: true }));
});
