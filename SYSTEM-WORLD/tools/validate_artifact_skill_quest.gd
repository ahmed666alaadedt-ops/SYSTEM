extends SceneTree

const ProgressionScript := preload("res://scripts/system_player_progression.gd")
const HistoricalWorldManagerScript := preload("res://scripts/historical_world_manager.gd/historical_world_manager.gd")
const ArtifactSkillManagerScript := preload("res://scripts/system_artifact_skill_manager.gd")
const CombatScript := preload("res://scripts/modern_world_combat_system.gd")
const ORIGINAL_SKILLS := [
	"guard_breaker", "swift_step", "focused_strike", "iron_guard", "pulse_dash",
	"aura_shield", "sensory_mark", "flow_counter", "resonance_burst", "sovereign_focus"
]
const ARTIFACT_QUESTS := [
	{"quest_id": "babylon_seal_trial", "skill_id": "babylon_seal", "relic_id": "babylon_cuneiform_tablet"},
	{"quest_id": "pharos_sight_trial", "skill_id": "pharos_sight", "relic_id": "alexandria_pharos_lens"},
	{"quest_id": "atlantis_tide_trial", "skill_id": "atlantis_tide_guard", "relic_id": "atlantis_tide_relic"}
]

class MockWorldManager extends Node:
	var active_world := 2
	var roots: Dictionary = {}

	func initialize_world_roots() -> void:
		for world_id in [1, 2]:
			var world_root := Node3D.new()
			world_root.name = "HistoricalWorld" if world_id == 1 else "ModernWorld"
			add_child(world_root)
			roots[world_id] = world_root

	func switch_world(world_id: int) -> void:
		if roots.has(world_id):
			active_world = world_id

	func get_active_world() -> Node3D:
		return roots.get(active_world) as Node3D

	func get_world_root(world_id: int) -> Node3D:
		return roots.get(world_id) as Node3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world_manager := MockWorldManager.new()
	world_manager.name = "ArtifactQuestWorldManager"
	root.add_child(world_manager)
	world_manager.initialize_world_roots()
	var historical_world := HistoricalWorldManagerScript.new()
	historical_world.name = "HistoricalCivilizationsEnvironment"
	world_manager.get_world_root(1).add_child(historical_world)
	var progression := ProgressionScript.new()
	progression.name = "PlayerProgression"
	root.add_child(progression)
	var player := CharacterBody3D.new()
	player.name = "Player"
	world_manager.get_world_root(2).add_child(player)
	var combat := CombatScript.new()
	combat.name = "ModernWorldCombatSystem"
	root.add_child(combat)
	combat.call("bind_actor", player, null, progression)
	var artifact_manager := ArtifactSkillManagerScript.new()
	artifact_manager.name = "ArtifactSkillManager"
	root.add_child(artifact_manager)
	artifact_manager.call("setup", world_manager, progression, combat, player)
	for frame_index in range(4):
		await process_frame
	var skill_tree: Dictionary = progression.call("get_system_skill_tree")
	if skill_tree.size() != 13:
		_fail("Skill tree must contain the ten original skills plus exactly three artifact skills; found %d." % skill_tree.size())
		return
	for skill_id in ORIGINAL_SKILLS:
		if not skill_tree.has(skill_id):
			_fail("Original SYSTEM skill was replaced or lost: " + skill_id)
			return
	for artifact_skill in ["babylon_seal", "pharos_sight", "atlantis_tide_guard"]:
		if not skill_tree.has(artifact_skill):
			_fail("Missing rare artifact skill: " + artifact_skill)
			return
	progression.set("current_level", 1)
	progression.set("verified_hunter_mission_points", 0)
	progression.set("current_system_energy", 100.0)
	for quest in ARTIFACT_QUESTS:
		if int(world_manager.get("active_world")) != 2:
			world_manager.call("switch_world", 2)
		var quest_exhibit := Area3D.new()
		quest_exhibit.name = "MuseumQuest_" + str(quest["quest_id"])
		quest_exhibit.add_to_group("system_interactable")
		quest_exhibit.set_meta("system_interaction_type", "museum_artifact_exhibit")
		quest_exhibit.set_meta("system_artifact_quest_id", str(quest["quest_id"]))
		world_manager.get_world_root(2).add_child(quest_exhibit)
		var pre_quest_permit: Dictionary = progression.call("check_skill_training_permit", str(quest["skill_id"]))
		if bool(pre_quest_permit.get("success", false)) or str(pre_quest_permit.get("reason", "")) != "ARTIFACT_QUEST_REQUIRED":
			_fail("Artifact skill permit was not gated behind its historical quest: " + str(pre_quest_permit))
			return
		if not bool(artifact_manager.call("offer_quest_from_exhibit", quest_exhibit)):
			_fail("Museum exhibit rejected its artifact quest offer: " + str(quest["quest_id"]))
			return
		var accepted: Dictionary = artifact_manager.call("accept_active_offer")
		if not bool(accepted.get("success", false)) or int(world_manager.get("active_world")) != 1:
			_fail("Accepting the museum quest did not enter the historical world: " + str(accepted))
			return
		await process_frame
		var historical_root := world_manager.get_world_root(1)
		var relic_parent := historical_root.find_child("HistoricalKey_" + str(quest["relic_id"]), true, false)
		var relic := relic_parent.get_node_or_null("HistoricalKeyInteraction") as Node if relic_parent != null else null
		if relic == null:
			_fail("Historical world is missing quest relic " + str(quest["relic_id"]))
			return
		var wrong_relic_parent := historical_root.find_child("HistoricalKey_" + str("alexandria_pharos_lens" if str(quest["relic_id"]) != "alexandria_pharos_lens" else "atlantis_tide_relic"), true, false)
		var wrong_relic := wrong_relic_parent.get_node_or_null("HistoricalKeyInteraction") as Node if wrong_relic_parent != null else null
		if wrong_relic != null:
			var wrong_result: Dictionary = artifact_manager.call("handle_historical_relic_interaction", wrong_relic)
			if bool(wrong_result.get("success", false)) or str(wrong_result.get("reason", "")) != "WRONG_HISTORICAL_RELIC":
				_fail("A different historical relic incorrectly completed the active quest: " + str(wrong_result))
				return
		var recovery: Dictionary = artifact_manager.call("handle_historical_relic_interaction", relic)
		if not bool(recovery.get("handled", false)) or not bool(recovery.get("success", false)):
			_fail("Historical relic recovery did not complete the active quest: " + str(recovery))
			return
		relic.call("system_interact")
		if int(world_manager.get("active_world")) != 2:
			_fail("Successful relic recovery did not return the player to Baghdad.")
			return
		var skill_id := str(quest["skill_id"])
		if not progression.get("completed_artifact_quests").has(str(quest["quest_id"])):
			_fail("Recovered artifact quest was not persisted as completed: " + str(quest["quest_id"]))
			return
		if not progression.get("authorized_system_skills").has(skill_id):
			_fail("Artifact recovery did not grant the matching skill training permit: " + skill_id)
			return
		var practice: Dictionary = progression.get("system_skill_practice")
		if not practice.has(skill_id + "_sessions") or practice[skill_id + "_sessions"].size() != 0:
			_fail("Artifact skill must not have training sessions before the permit-holder trains.")
			return
		for session_index in range(3):
			var session_id := str(quest["quest_id"]) + "_session_" + str(session_index + 1)
			var training: Dictionary = artifact_manager.call("practice_artifact_skill", skill_id, session_id)
			if not bool(training.get("success", false)):
				_fail("Artifact skill training session %d/3 failed for %s: %s" % [session_index + 1, skill_id, str(training)])
				return
		if not progression.get("learned_system_skills").has(skill_id):
			_fail("Three verified training sessions did not unlock artifact skill: " + skill_id)
			return
		var duplicate_session: Dictionary = artifact_manager.call("practice_artifact_skill", skill_id, str(quest["quest_id"]) + "_session_3")
		if bool(duplicate_session.get("success", false)) or str(duplicate_session.get("reason", "")) != "SESSION_ALREADY_RECORDED":
			_fail("Artifact skill training accepted a duplicate session: " + str(duplicate_session))
			return
		var activation: Dictionary = artifact_manager.call("activate_artifact_skill_in_combat", skill_id)
		if not bool(activation.get("success", false)):
			_fail("Artifact skill failed to activate through the real combat system: " + str(activation))
			return
		var combat_state: Dictionary = combat.call("get_artifact_skill_state")
		if not bool(combat_state.get("active", false)):
			_fail("Combat system did not retain the activated artifact skill effect: " + skill_id)
			return
		print("SYSTEM ARTIFACT SKILL QA PASS: ", skill_id, " | quest=", quest["quest_id"], " | sessions=3 | combat=", combat_state)
	print("SYSTEM ARTIFACT SKILL QUEST QA PASS: 3/3 artifact quests, 13/13 skills preserved, permits, nine unique training sessions and real combat activations verified.")
	quit(0)

func _fail(message: String) -> void:
	push_error("SYSTEM ARTIFACT SKILL QUEST QA FAILED: " + message)
	quit(1)
