extends SceneTree

const QUESTS := [
	{"id": "babylon_storm_seal", "relic": "babylon_storm_tablet", "skill": "ancient_lightning", "floor": 29, "prerequisite": "flow_counter"},
	{"id": "nineveh_shadow_seal", "relic": "nineveh_shadow_seal", "skill": "shadow_cloak", "floor": 30, "prerequisite": "resonance_burst"},
	{"id": "assyrian_colossus_core", "relic": "assyrian_colossus_core", "skill": "titan_embodiment", "floor": 31, "prerequisite": "sovereign_focus"}
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene could not load for historical artifact quest validation.")
		return
	var main := packed.instantiate() as Node3D
	if main == null:
		_fail("MainScene root is not Node3D.")
		return
	root.add_child(main)
	current_scene = main
	for _frame in range(24):
		await process_frame

	var quest_manager := main.get_node_or_null("HistoricalArtifactQuestManager")
	var progression := main.get_node_or_null("PlayerProgression")
	var operations := main.get_node_or_null("BaghdadTowerOperationsManager")
	var world_manager := main.get_node_or_null("WorldManager")
	if quest_manager == null or progression == null or operations == null or world_manager == null:
		_fail("Historical quest, progression, tower operations or world manager is missing.")
		return

	var accepted: Dictionary = quest_manager.get("accepted_quests")
	var completed: Dictionary = quest_manager.get("completed_quests")
	var stages: Dictionary = quest_manager.get("reward_stages")
	accepted.clear()
	completed.clear()
	stages.clear()
	quest_manager.call("_save_quest_state")
	var inventory: Dictionary = progression.get("inventory_items")
	var authorized_before: Array = progression.get("authorized_system_skills")
	var learned: Array = progression.get("learned_system_skills")
	var practice_data: Dictionary = progression.get("system_skill_practice")
	for quest in QUESTS:
		inventory.erase(str(quest["relic"]))
		authorized_before.erase(str(quest["skill"]))
		learned.erase(str(quest["skill"]))
		practice_data.erase(str(quest["skill"]))
	progression.set("current_level", 100)
	progression.set("verified_hunter_mission_points", 5000)
	progression.set("nen_unlocked", true)
	progression.set("nen_control_rank", 5)
	progression.set("nen_skill_use_count", 150)
	var nen_ids: Array = progression.get("nen_skill_ids")
	nen_ids.clear()
	nen_ids.append_array(["test_nen_one", "test_nen_two", "test_nen_three"])
	var verified_ids: Array = progression.get("verified_hunter_mission_ids")
	for quest in QUESTS:
		verified_ids.erase(str(quest["id"]))
	for prerequisite in ["flow_counter", "resonance_burst", "sovereign_focus"]:
		if not learned.has(prerequisite):
			learned.append(prerequisite)

	for quest in QUESTS:
		var floor_number := int(quest["floor"])
		var room := operations.call("_ensure_floor_room", "antiques_heritage_tower_baghdad", floor_number) as Node3D
		await process_frame
		if room == null:
			_fail("Antiques market floor %d could not be generated." % floor_number)
			return
		var exhibit: Node = null
		for child in room.get_children():
			if child is Node3D and str(child.name).begins_with("SpecialFacility_"):
				exhibit = child.get_node_or_null("ArtifactExhibitInteraction_00")
				if exhibit != null:
					break
		if exhibit == null or str(exhibit.get_meta("system_historical_quest_id", "")) != str(quest["id"]):
			_fail("Antiques market floor %d does not expose the expected historical quest." % floor_number)
			return
		main.call("_on_interaction_performed", exhibit, "")
		var status: Dictionary = quest_manager.call("get_quest_status", str(quest["id"]))
		if not bool(status.get("accepted", false)):
			_fail("Market exhibit did not accept quest %s." % str(quest["id"]))
			return

	world_manager.call("switch_world", 1)
	for _frame in range(12):
		await process_frame
	var historical_root: Node3D = world_manager.call("get_active_world") as Node3D
	if historical_root == null:
		_fail("Historical world did not load.")
		return
	var historical_environment := historical_root.get_node_or_null("HistoricalCivilizationsEnvironment") as Node3D
	if historical_environment == null:
		historical_environment = historical_root.find_child("HistoricalCivilizationsEnvironment", true, false) as Node3D
	if historical_environment == null:
		_fail("Historical civilizations environment node was not found inside the active historical world.")
		return

	for quest in QUESTS:
		var relic_name := "HistoricalKey_" + str(quest["relic"])
		var relic_root := historical_environment.get_node_or_null(relic_name) as Node3D
		if relic_root == null:
			relic_root = historical_environment.find_child(relic_name, true, false) as Node3D
		var endpoint := relic_root.get_node_or_null("HistoricalKeyInteraction") if relic_root != null else null
		if endpoint == null:
			_fail("Historical world is missing the physical relic interaction node for %s; relic_found=%s." % [str(quest["id"]), str(relic_root != null)])
			return
		var endpoint_action := str(endpoint.get("action_type"))
		if endpoint_action != "historical_quest_artifact":
			_fail("Historical relic %s has the wrong interaction action: %s." % [str(quest["id"]), endpoint_action])
			return
		endpoint.call("system_interact")
		var status: Dictionary = quest_manager.call("get_quest_status", str(quest["id"]))
		if not bool(status.get("completed", false)):
			_fail("Recovering relic %s did not complete its accepted quest." % str(quest["id"]))
			return
		var artifact_id := str(quest["relic"])
		var skill_id := str(quest["skill"])
		if int(progression.call("get_item_count", artifact_id)) != 1:
			_fail("Quest %s did not issue exactly one historical artifact." % str(quest["id"]))
			return
		var authorized: Array = progression.call("get_authorized_system_skills")
		if not authorized.has(skill_id):
			_fail("Quest %s did not issue its artifact-bound skill permit." % str(quest["id"]))
			return
		if progression.call("has_verified_hunter_mission", str(quest["id"])) != true:
			_fail("Quest %s was not recorded in verified Hunter mission progress." % str(quest["id"]))
			return
		for session_index in range(3):
			var practice: Dictionary = progression.call("practice_system_skill", skill_id, "historical_quest_%s_session_%d" % [skill_id, session_index])
			if not bool(practice.get("success", false)):
				_fail("Skill %s failed its practice session %d: %s" % [skill_id, session_index + 1, str(practice.get("reason", "UNKNOWN"))])
				return
		var learned_after: Array = progression.get("learned_system_skills")
		if not learned_after.has(skill_id):
			_fail("Skill %s was not learned after three verified practice sessions." % skill_id)
			return

	var router := root.find_child("SYSTEMCombatInputRouter", true, false)
	if router == null or not router.has_method("activate_system_skill"):
		_fail("Combat router does not expose rare skill activation.")
		return
	for quest in QUESTS:
		progression.set("current_system_energy", 100.0)
		var activation: Dictionary = router.call("activate_system_skill", str(quest["skill"]))
		if not bool(activation.get("success", false)):
			_fail("Rare skill %s could not activate in historical combat: %s" % [str(quest["skill"]), str(activation.get("reason", "UNKNOWN"))])
			return

	print("Historical artifact quest validation passed: Baghdad market invitations, Babylon/Nineveh/Assyrian relic recovery, persistent artifact rewards, artifact-bound training permits, three-session learning and real combat skill activation.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
