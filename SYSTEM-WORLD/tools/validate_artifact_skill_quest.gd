extends SceneTree

const MAIN_SCENE := preload("res://MainScene.tscn")
const ORIGINAL_SKILLS := [
	"guard_breaker", "swift_step", "focused_strike", "iron_guard", "pulse_dash",
	"aura_shield", "sensory_mark", "flow_counter", "resonance_burst", "sovereign_focus"
]
const ARTIFACT_QUESTS := [
	{"quest_id": "babylon_seal_trial", "skill_id": "babylon_seal", "relic_id": "babylon_cuneiform_tablet"},
	{"quest_id": "pharos_sight_trial", "skill_id": "pharos_sight", "relic_id": "alexandria_pharos_lens"},
	{"quest_id": "atlantis_tide_trial", "skill_id": "atlantis_tide_guard", "relic_id": "atlantis_tide_relic"}
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	for frame_index in range(8):
		await process_frame
	var progression := main.get("player_progression") as Node
	var world_manager := main.get("world_manager") as Node
	var artifact_manager := main.get("artifact_skill_manager") as Node
	var combat := main.get("modern_world_combat_system") as Node
	if progression == null or world_manager == null or artifact_manager == null or combat == null:
		_fail("Main scene did not initialize the artifact quest, progression, world or combat managers.")
		return
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
			await process_frame
		var modern_root := world_manager.call("get_active_world") as Node
		var quest_exhibit: Node
		for candidate in modern_root.find_children("*", "Area3D", true, false):
			if str(candidate.get_meta("system_artifact_quest_id", "")) == str(quest["quest_id"]):
				quest_exhibit = candidate
				break
		if quest_exhibit == null:
			_fail("Museum does not expose the quest offer for " + str(quest["quest_id"]))
			return
		if not bool(artifact_manager.call("offer_quest_from_exhibit", quest_exhibit)):
			_fail("Market exhibit rejected its artifact quest offer: " + str(quest["quest_id"]))
			return
		var accepted: Dictionary = artifact_manager.call("accept_active_offer")
		if not bool(accepted.get("success", false)) or int(world_manager.get("active_world")) != 1:
			_fail("Accepting the museum quest did not enter the historical world: " + str(accepted))
			return
		await process_frame
		var historical_root := world_manager.call("get_active_world") as Node
		var relic_parent := historical_root.find_child("HistoricalKey_" + str(quest["relic_id"]), true, false)
		var relic := relic_parent.get_node_or_null("HistoricalKeyInteraction") as Node if relic_parent != null else null
		if relic == null:
			_fail("Historical world is missing quest relic " + str(quest["relic_id"]))
			return
		var recovery: Dictionary = artifact_manager.call("handle_historical_relic_interaction", relic)
		if not bool(recovery.get("handled", false)) or not bool(recovery.get("success", false)):
			_fail("Historical relic recovery did not complete the active quest: " + str(recovery))
			return
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
		var permit_check: Dictionary = progression.call("check_skill_training_permit", skill_id)
		if bool(permit_check.get("success", false)):
			_fail("Artifact skill permit was granted before verified training, rather than authorizing training only.")
			return
		for session_index in range(3):
			var session_id := str(quest["quest_id"]) + "_session_" + str(session_index + 1)
			var practice: Dictionary = artifact_manager.call("practice_artifact_skill", skill_id, session_id)
			if not bool(practice.get("success", false)):
				_fail("Artifact skill training session %d/3 failed for %s: %s" % [session_index + 1, skill_id, str(practice)])
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
