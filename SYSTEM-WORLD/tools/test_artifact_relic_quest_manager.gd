extends SceneTree

const ManagerScript = preload("res://scripts/artifact_relic_quest_manager.gd")

func _initialize() -> void:
	var manager = ManagerScript.new()
	root.add_child(manager)
	var travel_events: Array = []
	var skill_events: Array = []
	var return_events: Array = []
	manager.historical_world_requested.connect(func(world_id, quest_id, relic_id):
		travel_events.append([world_id, quest_id, relic_id])
	)
	manager.rare_skill_reward_requested.connect(func(skill_id, relic_id, quest_id):
		skill_events.append([skill_id, relic_id, quest_id])
	)
	manager.relic_return_requested.connect(func(relic_id, site_id, quest_id):
		return_events.append([relic_id, site_id, quest_id])
	)

	var inspected: Dictionary = manager.inspect_relic("babylonian_star_tablet")
	assert(inspected.get("ok", false), "Relic inspection should reveal its quest.")
	var started: Dictionary = manager.begin_relic_quest("babylonian_star_tablet", true)
	assert(started.get("ok", false), "Player confirmation should start the quest.")
	assert(travel_events.size() == 1, "Exactly one historical travel request is expected.")

	for objective_id in ManagerScript.RELIC_QUESTS["babylonian_star_tablet"].objectives:
		var progress: Dictionary = manager.record_historical_objective("babylonian_star_tablet", objective_id, true)
		assert(progress.get("ok", false), "Each authored objective should be accepted.")

	assert(manager.get_relic_quest_state("babylonian_star_tablet") == ManagerScript.QUEST_STATE_READY_TO_RETURN,
		"Babylonian relic must wait for historical return.")
	assert(skill_events.is_empty(), "Skill must not be granted before required relic return.")

	var returned: Dictionary = manager.confirm_relic_return("babylonian_star_tablet", true, true)
	assert(returned.get("ok", false), "Verified return should complete the quest.")
	assert(return_events.size() == 1, "Return request should be emitted once.")
	assert(skill_events.size() == 1, "Exactly one rare skill reward request is expected.")
	assert(skill_events[0][0] == "rare_skill_celestial_lightning", "Unexpected Babylonian skill reward.")

	var duplicate: Dictionary = manager.confirm_relic_return("babylonian_star_tablet", true, true)
	assert(not duplicate.get("ok", false), "Duplicate relic return must not reward again.")

	var declined: Dictionary = manager.begin_relic_quest("akkadian_shadow_crown", false)
	assert(not declined.get("ok", false), "Travel must remain opt-in.")

	var akkadian_start: Dictionary = manager.begin_relic_quest("akkadian_shadow_crown", true)
	assert(akkadian_start.get("ok", false), "Akkadian quest should start after opt-in.")
	for objective_id in ManagerScript.RELIC_QUESTS["akkadian_shadow_crown"].objectives:
		manager.record_historical_objective("akkadian_shadow_crown", objective_id, true)
	assert(manager.get_relic_quest_state("akkadian_shadow_crown") == ManagerScript.QUEST_STATE_COMPLETED,
		"Retain-relic quest should complete without a return step.")
	assert(skill_events.size() == 2, "Akkadian skill should be requested once.")

	print("ARTIFACT_RELIC_QUEST_MANAGER_TESTS_PASSED")
	quit(0)
