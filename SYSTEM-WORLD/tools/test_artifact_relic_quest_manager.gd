extends SceneTree

const ManagerScript = preload("res://scripts/artifact_relic_quest_manager.gd")
const ProgressionScript = preload("res://scripts/system_player_progression.gd")

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

	var return_request: Dictionary = manager.request_relic_return("babylonian_star_tablet")
	assert(return_request.get("awaiting_server_confirmation", false), "Return should wait for server verification.")
	assert(return_events.size() == 1, "Return request should be emitted once.")
	var returned: Dictionary = manager.confirm_relic_return("babylonian_star_tablet", true, true)
	assert(returned.get("awaiting_server_reward", false), "Verified return should request a server skill reward.")
	assert(manager.get_relic_quest_state("babylonian_star_tablet") == ManagerScript.QUEST_STATE_READY_FOR_REWARD,
		"Quest must wait for authoritative skill reward confirmation.")
	assert(skill_events.size() == 1, "Exactly one rare skill reward request is expected.")
	assert(skill_events[0][0] == "rare_skill_celestial_lightning", "Unexpected Babylonian skill reward.")
	var verified_reward: Dictionary = manager.confirm_verified_skill_reward(
		"babylonian_star_tablet", "quest_babylon_star_tablet", "rare_skill_celestial_lightning", true
	)
	assert(verified_reward.get("completed", false), "Verified server reward should complete the quest.")
	var duplicate: Dictionary = manager.confirm_verified_skill_reward(
		"babylonian_star_tablet", "quest_babylon_star_tablet", "rare_skill_celestial_lightning", true
	)
	assert(not duplicate.get("ok", false), "Duplicate skill reward must be rejected.")

	var declined: Dictionary = manager.begin_relic_quest("akkadian_shadow_crown", false)
	assert(not declined.get("ok", false), "Travel must remain opt-in.")

	var akkadian_start: Dictionary = manager.begin_relic_quest("akkadian_shadow_crown", true)
	assert(akkadian_start.get("ok", false), "Akkadian quest should start after opt-in.")
	for objective_id in ManagerScript.RELIC_QUESTS["akkadian_shadow_crown"].objectives:
		manager.record_historical_objective("akkadian_shadow_crown", objective_id, true)
	assert(manager.get_relic_quest_state("akkadian_shadow_crown") == ManagerScript.QUEST_STATE_READY_FOR_REWARD,
		"Retain-relic quest should request reward without a return step.")
	assert(skill_events.size() == 2, "Akkadian skill should be requested once.")
	var akkadian_reward: Dictionary = manager.confirm_verified_skill_reward(
		"akkadian_shadow_crown", "quest_akkadian_shadow", "rare_skill_shadow_avatar", true
	)
	assert(akkadian_reward.get("completed", false), "Verified Akkadian reward should complete the quest.")

	var progression = ProgressionScript.new()
	root.add_child(progression)
	progression.current_level = 100
	progression.current_system_energy = 100.0
	progression.system_skill_cooldowns.clear()
	var local_practice: Dictionary = progression.practice_system_skill(
		"rare_skill_celestial_lightning", "local_forged_practice"
	)
	assert(not local_practice.get("success", false),
		"Local practice must never unlock a server-gated relic skill.")
	var locked_use: Dictionary = progression.can_use_system_skill("rare_skill_celestial_lightning")
	assert(not locked_use.get("success", false),
		"Rare relic skills must remain unavailable without a Firebase server receipt.")
	progression.apply_server_verified_relic_skills(["rare_skill_celestial_lightning"])
	var unlocked_use: Dictionary = progression.can_use_system_skill("rare_skill_celestial_lightning")
	assert(unlocked_use.get("success", false),
		"A server-read unlock receipt should expose the skill to the combat system.")
	var activation: Dictionary = progression.record_system_skill_use("rare_skill_celestial_lightning")
	assert(activation.get("success", false),
		"A verified rare relic skill should consume energy and enter cooldown.")
	print("ARTIFACT_RELIC_QUEST_MANAGER_TESTS_PASSED")
	quit(0)
