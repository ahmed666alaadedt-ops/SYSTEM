extends SceneTree

const TOWER_IDS := [
	"hunter_association_tower_baghdad",
	"weapons_equipment_elixirs_tower_baghdad",
	"shopping_tower_baghdad",
	"entertainment_tower_baghdad",
	"technology_tower_baghdad",
	"power_tower_baghdad"
]

const NODE_NAMES := {
	"hunter_association_tower_baghdad": "HunterAssociationTower",
	"weapons_equipment_elixirs_tower_baghdad": "WeaponsEquipmentElixirsTower",
	"shopping_tower_baghdad": "ShoppingTower",
	"entertainment_tower_baghdad": "EntertainmentTower",
	"technology_tower_baghdad": "TechnologyTower",
	"power_tower_baghdad": "PowerTower"
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not load.")
		return
	var main := packed.instantiate() as Node3D
	if main == null:
		_fail("Main scene root is not Node3D.")
		return
	root.add_child(main)
	for _frame in range(18):
		await process_frame
	var operations := main.get_node_or_null("BaghdadTowerOperationsManager")
	if operations == null:
		_fail("BaghdadTowerOperationsManager was not initialized.")
		return
	var status: Dictionary = operations.call("get_operations_status")
	var portrait_panel_size: Vector2 = operations.call("_get_responsive_panel_size", Vector2(360.0, 780.0))
	if portrait_panel_size.x > 336.0 or portrait_panel_size.y > 530.0:
		_fail("Baghdad tower operations panel exceeds a 360x780 phone portrait viewport.")
		return
	var landscape_panel_size: Vector2 = operations.call("_get_responsive_panel_size", Vector2(780.0, 360.0))
	if landscape_panel_size.x > 470.0 or landscape_panel_size.y > 328.0:
		_fail("Baghdad tower operations panel exceeds a 780x360 phone landscape viewport.")
		return
	if int(status.get("tower_count", 0)) != 6:
		_fail("Operations manager did not resolve all six towers.")
		return
	if int(status.get("staff_count", 0)) != 24:
		_fail("Expected four persistent NPC staff members per tower; found %d." % int(status.get("staff_count", 0)))
		return
	if str(status.get("advertising_mode", "")) != "npc_staff_managed_internal_external":
		_fail("NPC-managed internal/external advertising is not active.")
		return
	var region := main.find_child("ModernWorldRegionManager", true, false)
	if region == null:
		_fail("ModernWorldRegionManager is missing.")
		return
	var tower_manager := region.get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager == null:
		_fail("BaghdadTowerLandmarksManager is missing.")
		return
	var exam_manager := main.get_node_or_null("SYSTEMHunterExamManager")
	if exam_manager == null:
		_fail("HunterExamManager is missing.")
		return
	var empty_stage_ids: Array[String] = []
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	exam_manager.set("registered", true)
	exam_manager.set("exam_active", true)
	exam_manager.set("current_stage_index", 0)
	var resume_result: Dictionary = exam_manager.call("begin_exam")
	if not bool(resume_result.get("success", false)) or not bool(resume_result.get("resumed", false)):
		_fail("An in-progress Hunter examination must resume at its saved stage.")
		return
	var exam_overview: Dictionary = exam_manager.call("get_exam_overview")
	var all_stage_ids: Array[String] = []
	for stage_value in exam_overview.get("stages", []):
		all_stage_ids.append(str(stage_value.get("id", "")))
	exam_manager.set("completed_stage_ids", all_stage_ids)
	exam_manager.set("exam_active", false)
	var completed_exam_result: Dictionary = exam_manager.call("begin_exam")
	if str(completed_exam_result.get("reason", "")) != "ALL_STAGES_COMPLETED" or bool(exam_manager.get("exam_active")):
		_fail("A completed Hunter examination must not reopen or remain marked active.")
		return
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	exam_manager.set("registered", false)
	exam_manager.set("exam_active", false)
	exam_manager.set("current_stage_index", -1)
	var hunter_tower := tower_manager.get_node_or_null("HunterAssociationTower") as Node3D
	var helipad := hunter_tower.get_node_or_null("HunterAssociationHelipad") as Node3D if hunter_tower != null else null
	if helipad == null or str(helipad.get_meta("system_owner_tower_id", "")) != "hunter_association_tower_baghdad":
		_fail("Hunter Association helicopter landing pad is missing or assigned to the wrong tower.")
		return
	if helipad.get_node_or_null("HelipadDeck") == null or helipad.get_node_or_null("HelipadDeckCollision") == null or helipad.get_node_or_null("LandingCircleMarking") == null or helipad.get_node_or_null("HelipadIdentitySign") == null:
		_fail("Hunter Association helicopter landing pad deck, collision, markings or sign is incomplete.")
		return
	if helipad.get_node_or_null("HelipadAccessBridge") == null or helipad.get_node_or_null("HelipadAccessBridgeCollision") == null:
		_fail("Hunter Association helicopter landing pad access bridge is missing collision.")
		return
	var helipad_lights := 0
	for child in helipad.get_children():
		if str(child.name).begins_with("HelipadPerimeterLight_"):
			helipad_lights += 1
	if helipad_lights != 8:
		_fail("Hunter Association helicopter landing pad requires eight perimeter lights.")
		return
	if not helipad.has_method("get_helicopter_status"):
		_fail("Hunter Association helicopter flight controller is not attached to the landing pad.")
		return
	var helicopter_status: Dictionary = helipad.call("get_helicopter_status")
	if not bool(helicopter_status.get("available", false)) or str(helicopter_status.get("owner_tower_id", "")) != "hunter_association_tower_baghdad" or float(helicopter_status.get("landing_radius_m", 0.0)) != 18.0:
		_fail("Hunter Association helicopter controller ownership or landing-zone configuration is invalid.")
		return
	if not helicopter_status.has("pilot_authorized") or helipad.call("_can_pilot"):
		_fail("Unlicensed test profile must not be granted helicopter pilot access.")
		return
	exam_manager.set("registered", true)
	exam_manager.set("completed_stage_ids", all_stage_ids)
	var pilot_player := main.get("player") as CharacterBody3D
	var pilot_progression := main.get_node_or_null("PlayerProgression")
	if pilot_player == null or pilot_progression == null:
		_fail("Player and progression data are required for helicopter authorization tests.")
		return
	if helipad.call("_can_pilot"):
		_fail("A completed Hunter License alone must not grant helicopter access.")
		return
	pilot_progression.set("current_level", 100)
	exam_manager.set("completed_stage_ids", all_stage_ids)
	if helipad.call("_can_pilot"):
		_fail("Player level and a completed Hunter License must not replace S-rank helicopter authorization.")
		return
	pilot_progression.set("current_level", 1)
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	for role in ["association_director", "association_official", "chief_hunter", "helicopter_pilot"]:
		pilot_player.set_meta("system_hunter_association_role", role)
		if not helipad.call("_can_pilot"):
			_fail("Senior Association role %s must receive helicopter access." % role)
			return
	pilot_player.set_meta("system_hunter_association_role", "mission_clerk")
	if helipad.call("_can_pilot"):
		_fail("A standard mission clerk must not receive professional helicopter access.")
		return
	pilot_player.set_meta("system_hunter_staff_professional", true)
	pilot_player.set_meta("system_hunter_association_role", "professional_employee")
	if not helipad.call("_can_pilot"):
		_fail("A certified professional Association employee must receive helicopter access.")
		return
	pilot_player.remove_meta("system_hunter_staff_professional")
	pilot_player.remove_meta("system_hunter_association_role")
	pilot_progression.set("current_level", 1)
	for rank in ["F", "E", "D", "C", "B", "A"]:
		pilot_player.set_meta("system_hunter_rank", rank)
		if helipad.call("_can_pilot"):
			_fail("A %s hunter must not receive S-rank helicopter authorization." % rank)
			return
	for rank in ["S", "SS", "SSS"]:
		pilot_player.set_meta("system_hunter_rank", rank)
		if not helipad.call("_can_pilot"):
			_fail("A %s hunter must receive helicopter access." % rank)
			return
	pilot_player.remove_meta("system_hunter_rank")
	pilot_progression.set("current_level", 50)
	exam_manager.set("completed_stage_ids", all_stage_ids)
	if not helipad.has_method("_is_aircraft_position_clear"):
		_fail("Hunter Association helicopter obstacle-clearance query is missing.")
		return
	if not helipad.has_method("_save_parked_state") or not helipad.has_method("_load_parked_state"):
		_fail("Hunter Association helicopter parking persistence methods are missing.")
		return
	var helicopter_node := helipad.get_node_or_null("HunterAssociationHelicopter") as Node3D
	var parked_position := helicopter_node.position
	var parked_rotation := helicopter_node.rotation
	helicopter_node.position = parked_position + Vector3(1.0, 0.0, 0.0)
	helicopter_node.rotation = parked_rotation + Vector3(0.0, 0.15, 0.0)
	if not bool(helipad.call("_save_parked_state")):
		_fail("Hunter Association helicopter could not save its parked state.")
		return
	helicopter_node.position = parked_position
	helicopter_node.rotation = Vector3.ZERO
	helipad.call("_load_parked_state")
	if not helicopter_node.position.is_equal_approx(parked_position + Vector3(1.0, 0.0, 0.0)):
		_fail("Hunter Association helicopter parked position did not survive reload.")
		return
	if not helicopter_node.rotation.is_equal_approx(parked_rotation + Vector3(0.0, 0.15, 0.0)):
		_fail("Hunter Association helicopter parked orientation did not survive reload.")
		return
	helicopter_node.position = parked_position
	helicopter_node.rotation = parked_rotation
	helipad.call("_save_parked_state")
	var rotor_test_position := helicopter_node.global_position + Vector3.UP * 100.0
	var rotor_obstacle := StaticBody3D.new()
	var rotor_obstacle_shape := CollisionShape3D.new()
	var rotor_obstacle_box := BoxShape3D.new()
	rotor_obstacle_box.size = Vector3(0.6, 0.6, 0.6)
	rotor_obstacle_shape.shape = rotor_obstacle_box
	rotor_obstacle.add_child(rotor_obstacle_shape)
	main.add_child(rotor_obstacle)
	rotor_obstacle.global_position = rotor_test_position + helicopter_node.global_basis * Vector3(6.0, 1.8, 0.0)
	await physics_frame
	var main_rotor_blocked: bool = not bool(helipad.call("_is_aircraft_position_clear", rotor_test_position))
	rotor_obstacle.queue_free()
	await physics_frame
	if not main_rotor_blocked:
		_fail("Helicopter clearance query did not detect an obstacle at the main rotor disc edge.")
		return
	var helicopter_player: CharacterBody3D = main.get("player") as CharacterBody3D
	if helicopter_player == null:
		_fail("A player character is required for the helicopter takeoff/landing test.")
		return
	var player_physics_before_flight := helicopter_player.is_physics_processing()
	helipad.call("_enter_aircraft")
	if not bool(helipad.get("pilot_active")) or helicopter_player.visible or (player_physics_before_flight and helicopter_player.is_physics_processing()):
		_fail("Authorized pilot entry did not transfer control from the on-foot character.")
		return
	helipad.set("vertical_input", 1.0)
	helipad.call("_update_flight", 0.5)
	var takeoff_height := float(helipad.get("heli_position").y)
	if takeoff_height <= helipad.global_position.y + 2.8:
		_fail("Authorized helicopter pilot could not lift off from the landing pad.")
		return
	helipad.set("vertical_input", -1.0)
	helipad.call("_update_flight", 0.5)
	helipad.call("_update_flight", 0.5)
	if not bool(helipad.get("landed")):
		_fail("Helicopter could not complete a controlled landing inside its marked pad.")
		return
	helipad.call("_exit_aircraft")
	if bool(helipad.get("pilot_active")) or not helicopter_player.visible or bool(helicopter_player.get_meta("system_helicopter_piloting", true)) or helicopter_player.is_physics_processing() != player_physics_before_flight:
		_fail("Helicopter exit did not restore the on-foot player controls.")
		return
	if helicopter_player.global_position.distance_to(helicopter_node.global_position) > 12.0:
		_fail("Helicopter exit did not place the pilot beside the parked aircraft.")
		return
	helipad.call("_enter_aircraft")
	helipad.set("vertical_input", 1.0)
	helipad.call("_update_flight", 0.5)
	if bool(helipad.get("landed")):
		_fail("Emergency-landing regression setup could not reach airborne state.")
		return
	helipad.call("_begin_emergency_landing")
	if not bool(helipad.get("emergency_landing_active")):
		_fail("Emergency landing did not activate over a detected safe ground surface.")
		return
	for _landing_step in range(12):
		helipad.call("_update_flight", 0.5)
		if bool(helipad.get("landed")):
			break
	if not bool(helipad.get("landed")) or bool(helipad.get("emergency_landing_active")):
		_fail("Emergency landing did not complete a controlled descent to detected ground.")
		return
	helipad.call("_exit_aircraft")
	exam_manager.set("registered", false)
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	exam_manager.set("exam_active", false)
	if helipad.get_node_or_null("HunterAssociationHelicopter") == null or helipad.get_node_or_null("HunterHelicopterTouchHUD") == null:
		_fail("Hunter Association helicopter aircraft model or touch-control HUD was not generated.")
		return
	for tower_id in TOWER_IDS:
		var tower := tower_manager.get_node_or_null(str(NODE_NAMES[tower_id])) as Node3D
		if tower == null:
			_fail("Missing tower node: " + tower_id)
			return
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
		if lobby == null:
			_fail("Missing lobby for " + tower_id)
			return
		var lobby_lift := lobby.get_node_or_null("LobbyElevatorInteraction") as Area3D
		if lobby_lift == null or not lobby_lift.is_in_group("system_interactable") or str(lobby_lift.get_meta("system_tower_id", "")) != tower_id:
			_fail("Lobby elevator selector is not interactable for " + tower_id)
			return
		var staff_count := 0
		for child in lobby.get_children():
			if child.has_meta("system_tower_staff_id"):
				staff_count += 1
		if staff_count != 4:
			_fail("Expected four visible NPC employees in " + tower_id + "; found %d." % staff_count)
			return
		var internal_ad := lobby.get_node_or_null("NPCManagedInternalCampaign") as Label3D
		if internal_ad == null or not internal_ad.text.contains("بإدارة"):
			_fail("Internal NPC-managed advertising is missing for " + tower_id)
			return
		var external_ad := tower.get_node_or_null("TowerCampaignText") as Label3D
		if external_ad == null or not external_ad.text.contains("بإدارة"):
			_fail("External NPC-managed advertising is missing for " + tower_id)
			return
		var room := operations.call("_ensure_floor_room", tower_id, 1) as Node3D
		if room == null:
			_fail("Could not generate playable interior floor 1 for " + tower_id)
			return
		if room.get_node_or_null("FloorCollision") == null:
			_fail("Interior floor collision is missing for " + tower_id)
			return
		if tower_id != "power_tower_baghdad":
			var service_kiosk := room.get_node_or_null("ServiceKiosk_0/TowerServiceInteraction") as Area3D
			if service_kiosk == null or str(service_kiosk.get_meta("system_tower_id", "")) != tower_id or int(service_kiosk.get_meta("system_tower_floor_number", 0)) != 1:
				_fail("Tower floor service kiosk metadata is missing or incorrect for " + tower_id)
				return
			if not operations.has_method("open_floor_services"):
				_fail("Tower floor kiosk service routing method is missing.")
				return
			operations.call("open_floor_services", tower_id, 1)
			var service_panel := operations.get("panel") as Control
			if service_panel == null or not service_panel.visible:
				_fail("Tower floor kiosk did not open its assigned NPC service for " + tower_id)
				return
			service_panel.hide()
		if tower_id != "power_tower_baghdad":
			var theme_root := room.get_node_or_null("FloorThemeIdentity") as Node3D
			var theme_props := theme_root.get_node_or_null("FloorThemeProps") as Node3D if theme_root != null else null
			if theme_root == null or theme_props == null or theme_props.get_child_count() < 5 or str(room.get_meta("system_floor_theme_id", "")).is_empty():
				_fail("Distinct department floor theme is missing or incomplete for " + tower_id)
				return
		else:
			if not room.has_meta("system_power_tower_arena_type") or room.get_node_or_null("ArenaChallengeDisplay") == null:
				_fail("Power Tower arena layout is missing for its challenge floor.")
				return
		if tower_id != "power_tower_baghdad":
			var service_area := room.find_child("TowerServiceInteraction", true, false) as Area3D
			if service_area == null or not service_area.is_in_group("system_interactable") or str(service_area.get_meta("system_tower_id", "")) != tower_id:
				_fail("Interactive NPC service kiosk is missing for " + tower_id)
				return
	var power_manager: Node = main.get("power_tower_manager") as Node
	if power_manager == null:
		_fail("Power Tower progression manager is missing.")
		return
	var power_probe_script := load("res://scripts/system_power_tower_manager.gd") as Script
	if power_probe_script == null:
		_fail("Power Tower progression manager script could not load for regression tests.")
		return
	var power_probe := power_probe_script.new() as Node
	main.add_child(power_probe)
	power_probe.set("highest_cleared_floor", 0)
	power_probe.set("active_floor", 0)
	power_probe.set("floor_clear_times", {})
	var skipped_floor: Dictionary = power_probe.call("request_floor", 2, 1)
	if str(skipped_floor.get("reason", "")) != "PREVIOUS_FLOOR_REQUIRED":
		_fail("Power Tower allowed a player to skip the previous floor.")
		return
	var low_level: Dictionary = power_probe.call("request_floor", 1, 0)
	if str(low_level.get("reason", "")) != "PLAYER_LEVEL_TOO_LOW":
		_fail("Power Tower allowed a player below the required level to enter.")
		return
	var first_floor: Dictionary = power_probe.call("request_floor", 1, 1)
	if not bool(first_floor.get("success", false)):
		_fail("Power Tower rejected a valid first-floor request.")
		return
	var duplicate_active: Dictionary = power_probe.call("request_floor", 1, 1)
	if str(duplicate_active.get("reason", "")) != "ANOTHER_FLOOR_IS_ACTIVE":
		_fail("Power Tower allowed a second concurrent active floor.")
		return
	var forged_clear: Dictionary = power_probe.call("confirm_floor_clear", 2, 30.0)
	if str(forged_clear.get("reason", "")) != "FLOOR_NOT_ACTIVE":
		_fail("Power Tower accepted a clear report for a floor that was never activated.")
		return
	power_probe.call("abandon_active_floor")
	power_probe.queue_free()
	for floor_number in range(1, 201):
		var floor_data: Dictionary = power_manager.call("get_floor_data", floor_number)
		if int(floor_data.get("floor", 0)) != floor_number or int(floor_data.get("required_level", 999)) > 100:
			_fail("Power Tower floor data or level gate is invalid at floor %d." % floor_number)
			return
		if bool(floor_data.get("boss_floor", false)) != (floor_number % 10 == 0):
			_fail("Power Tower boss cadence is incorrect at floor %d." % floor_number)
			return
		if int(floor_data.get("opponent_count", 0)) < 1 or int(floor_data.get("wave_count", 0)) < 1 or int(floor_data.get("reward_xp", 0)) <= 0:
			_fail("Power Tower challenge data is incomplete at floor %d." % floor_number)
			return
		if str(floor_data.get("arena_type", "")) == "SURVIVAL" and (str(floor_data.get("objective_type", "")) != "SURVIVE_TIMER" or int(floor_data.get("time_limit_seconds", 0)) <= 0):
			_fail("Power Tower survival floor is missing its timed survival objective at floor %d." % floor_number)
			return
		if str(floor_data.get("arena_type", "")) == "CHAMPIONSHIP" and (str(floor_data.get("objective_type", "")) != "CLEAR_WITHIN_TIME" or int(floor_data.get("time_limit_seconds", 0)) <= 0):
			_fail("Power Tower championship floor is missing its timed clear objective at floor %d." % floor_number)
			return
	var power_tower := tower_manager.get_node_or_null("PowerTower") as Node3D
	var power_lobby := power_tower.get_node_or_null("PublicLobby_Blockout") as Node3D
	var progress_board := power_lobby.get_node_or_null("PowerTowerProgressBoard") as Label3D
	if progress_board == null or not progress_board.text.contains("200") or not progress_board.text.contains("أفضل وقت"):
		_fail("Power Tower lobby progress board is missing the 200-floor completion target.")
		return
	var boss_data: Dictionary = power_manager.call("get_floor_data", 200)
	if not bool(boss_data.get("boss_floor", false)) or str(boss_data.get("arena_type", "")) != "BOSS_TRIAL":
		_fail("Power Tower floor 200 is not configured as a boss trial.")
		return
	if not bool(boss_data.get("final_boss", false)) or str(boss_data.get("challenge_type", "")) != "FINAL_BOSS":
		_fail("Power Tower floor 200 is missing its unique final sovereign boss profile.")
		return
	var final_rewards: Array = boss_data.get("reward_items", [])
	if not final_rewards.has("power_tower_sovereign_crown") or not final_rewards.has("sovereign_core") or not final_rewards.has("rare_core") or not final_rewards.has("nen_fragment"):
		_fail("Power Tower floor 200 is missing its unique completion rewards.")
		return
	if int(boss_data.get("required_level", 999)) > 100:
		_fail("Power Tower floor 200 is unreachable under the 100-level player progression cap.")
		return
	var power_tower_test_script := load("res://scripts/system_power_tower_manager.gd") as Script
	if power_tower_test_script == null:
		_fail("Power Tower progression script could not be loaded for the 200-floor regression.")
		return
	var progression_test_manager := power_tower_test_script.new() as Node
	root.add_child(progression_test_manager)
	await process_frame
	progression_test_manager.set("highest_cleared_floor", 0)
	progression_test_manager.set("active_floor", 0)
	progression_test_manager.set("floor_clear_times", {})
	for test_floor in range(1, 201):
		var floor_request: Dictionary = progression_test_manager.call("request_floor", test_floor, 100)
		if not bool(floor_request.get("success", false)):
			_fail("Power Tower rejected sequential progression at floor %d: %s" % [test_floor, str(floor_request.get("reason", "unknown"))])
			progression_test_manager.queue_free()
			return
		var floor_clear: Dictionary = progression_test_manager.call("confirm_floor_clear", test_floor, float(test_floor))
		if not bool(floor_clear.get("success", false)):
			_fail("Power Tower could not persist a valid clear at floor %d." % test_floor)
			progression_test_manager.queue_free()
			return
	var reloaded_progression_manager := power_tower_test_script.new() as Node
	root.add_child(reloaded_progression_manager)
	await process_frame
	var reloaded_tower_status: Dictionary = reloaded_progression_manager.call("get_tower_status")
	var reloaded_floor_times: Dictionary = reloaded_progression_manager.get("floor_clear_times")
	if int(reloaded_tower_status.get("highest_cleared_floor", 0)) != 200 or int(reloaded_tower_status.get("next_floor", 1)) != 0 or int(reloaded_floor_times.size()) != 200:
		_fail("Power Tower did not restore all 200 cleared floors and their clear-time records.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		return
	progression_test_manager.queue_free()
	reloaded_progression_manager.queue_free()
	var tower_player: CharacterBody3D = main.get("player") as CharacterBody3D
	var final_boss_script := load("res://scripts/system_tower_opponent.gd") as Script
	if tower_player == null or final_boss_script == null:
		_fail("Power Tower final boss combat fixture could not be created.")
		return
	var final_boss_test := final_boss_script.new() as Node3D
	root.add_child(final_boss_test)
	final_boss_test.call("configure", tower_player, null, 100.0, 12.0, 2.5, true, true)
	await physics_frame
	final_boss_test.call("take_damage", 51.0, tower_player)
	await physics_frame
	if int(final_boss_test.get("boss_phase")) != 2:
		_fail("Power Tower sovereign boss did not enter its second health phase.")
		final_boss_test.queue_free()
		return
	final_boss_test.call("take_damage", 31.0, tower_player)
	await physics_frame
	if int(final_boss_test.get("boss_phase")) != 3:
		_fail("Power Tower sovereign boss did not enter its final health phase.")
		final_boss_test.queue_free()
		return
	final_boss_test.call("take_damage", 100.0, tower_player)
	if not bool(final_boss_test.get("defeated_once")):
		_fail("Power Tower sovereign boss did not register its defeat.")
		final_boss_test.queue_free()
		return
	var tower_progression: Node = operations.get("progression") as Node
	var original_highest_floor := int(power_manager.get("highest_cleared_floor"))
	var original_active_floor := int(power_manager.get("active_floor"))
	var original_clear_times: Dictionary = power_manager.get("floor_clear_times").duplicate(true)
	var original_inventory: Dictionary = tower_progression.get("inventory_items").duplicate(true) if tower_progression != null else {}
	var original_credits := int(operations.get("credits"))
	if tower_progression == null:
		_fail("Power Tower final reward test has no player progression manager.")
		return
	power_manager.set("highest_cleared_floor", 199)
	power_manager.set("active_floor", 200)
	operations.set("active_power_floor_data", boss_data.duplicate(true))
	operations.set("power_floor_in_progress", true)
	operations.set("power_floor_started_at", Time.get_ticks_msec() - 1500)
	operations.set("active_opponents", {})
	operations.call("_complete_power_floor")
	var final_rewards_granted := true
	for reward_id in final_rewards:
		if int(tower_progression.call("get_item_count", str(reward_id))) <= int(original_inventory.get(str(reward_id), 0)):
			final_rewards_granted = false
	if int(power_manager.get("highest_cleared_floor")) != 200 or int(power_manager.get("active_floor")) != 0 or int(operations.get("credits")) <= original_credits or not final_rewards_granted:
		_fail("Power Tower final boss clear did not grant the sovereign rewards, credits and completion record.")
		power_manager.set("highest_cleared_floor", original_highest_floor)
		power_manager.set("active_floor", original_active_floor)
		power_manager.set("floor_clear_times", original_clear_times)
		power_manager.call("_save_progress")
		tower_progression.set("inventory_items", original_inventory)
		tower_progression.call("save_progress")
		operations.set("credits", original_credits)
		operations.call("_save_wallet")
		return
	power_manager.set("highest_cleared_floor", original_highest_floor)
	power_manager.set("active_floor", original_active_floor)
	power_manager.set("floor_clear_times", original_clear_times)
	power_manager.call("_save_progress")
	tower_progression.set("inventory_items", original_inventory)
	tower_progression.call("save_progress")
	operations.set("credits", original_credits)
	operations.call("_save_wallet")
	operations.set("active_power_floor_data", {})
	operations.set("power_floor_in_progress", false)
	power_manager.set("highest_cleared_floor", 2)
	power_manager.set("active_floor", 3)
	operations.set("active_power_floor_data", power_manager.call("get_floor_data", 3))
	operations.set("power_floor_in_progress", true)
	operations.set("power_floor_timer_remaining", 0.05)
	operations.set("active_opponents", {})
	operations.call("_process", 0.1)
	if int(power_manager.get("highest_cleared_floor")) != 3 or int(power_manager.get("active_floor")) != 0 or bool(operations.get("power_floor_in_progress")):
		_fail("Power Tower survival timer did not clear its floor when the survival duration elapsed.")
		power_manager.set("highest_cleared_floor", original_highest_floor)
		power_manager.set("active_floor", original_active_floor)
		power_manager.set("floor_clear_times", original_clear_times)
		power_manager.call("_save_progress")
		tower_progression.set("inventory_items", original_inventory)
		tower_progression.call("save_progress")
		operations.set("credits", original_credits)
		operations.call("_save_wallet")
		return
	power_manager.set("highest_cleared_floor", 4)
	power_manager.set("active_floor", 5)
	operations.set("active_power_floor_data", power_manager.call("get_floor_data", 5))
	operations.set("power_floor_in_progress", true)
	operations.set("power_floor_timer_remaining", 0.05)
	operations.set("active_opponents", {})
	operations.call("_process", 0.1)
	if int(power_manager.get("highest_cleared_floor")) != 4 or int(power_manager.get("active_floor")) != 0 or bool(operations.get("power_floor_in_progress")):
		_fail("Power Tower championship timeout did not abandon the attempt without granting a floor clear.")
		power_manager.set("highest_cleared_floor", original_highest_floor)
		power_manager.set("active_floor", original_active_floor)
		power_manager.set("floor_clear_times", original_clear_times)
		power_manager.call("_save_progress")
		tower_progression.set("inventory_items", original_inventory)
		tower_progression.call("save_progress")
		operations.set("credits", original_credits)
		operations.call("_save_wallet")
		return
	power_manager.set("highest_cleared_floor", 5)
	power_manager.set("active_floor", 6)
	operations.set("current_tower_id", "power_tower_baghdad")
	operations.set("active_power_floor_data", power_manager.call("get_floor_data", 6))
	operations.set("power_floor_in_progress", true)
	operations.set("active_opponents", {})
	operations.call("_on_player_wounded")
	if int(power_manager.get("highest_cleared_floor")) != 5 or int(power_manager.get("active_floor")) != 0 or bool(operations.get("power_floor_in_progress")):
		_fail("Power Tower wound/abandon recovery did not clear the active attempt without crediting the floor.")
		power_manager.set("highest_cleared_floor", original_highest_floor)
		power_manager.set("active_floor", original_active_floor)
		power_manager.set("floor_clear_times", original_clear_times)
		power_manager.call("_save_progress")
		tower_progression.set("inventory_items", original_inventory)
		tower_progression.call("save_progress")
		operations.set("credits", original_credits)
		operations.call("_save_wallet")
		return
	power_manager.set("highest_cleared_floor", original_highest_floor)
	power_manager.set("active_floor", original_active_floor)
	power_manager.set("floor_clear_times", original_clear_times)
	power_manager.call("_save_progress")
	tower_progression.set("inventory_items", original_inventory)
	tower_progression.call("save_progress")
	operations.set("credits", original_credits)
	operations.call("_save_wallet")
	operations.set("active_power_floor_data", {})
	operations.set("power_floor_in_progress", false)
	operations.set("power_floor_timer_remaining", 0.0)
	operations.set("active_opponents", {})
	operations.call("_refresh_power_tower_progress_board")
	var weapons_room := operations.call("_ensure_floor_room", "weapons_equipment_elixirs_tower_baghdad", 1) as Node3D
	if weapons_room.get_node_or_null("WeaponsForge") == null or weapons_room.get_node_or_null("ElixirLaboratory") == null:
		_fail("Weapons Tower forge and elixir laboratory stations are missing.")
		return
	var forge_area := weapons_room.get_node("WeaponsForge/CraftingStationInteraction") as Area3D
	if forge_area == null or not forge_area.is_in_group("system_interactable") or not forge_area.has_meta("system_tower_staff_id"):
		_fail("Weapons Tower crafting station is not connected to its NPC employee.")
		return
	var boss_room := operations.call("_ensure_floor_room", "power_tower_baghdad", 200) as Node3D
	if boss_room == null or boss_room.get_node_or_null("BossTrialPlatform") == null:
		_fail("Power Tower floor 200 boss arena was not generated.")
		return
	if boss_room.get_node_or_null("ArenaChallengeDisplay") == null:
		_fail("Power Tower arena challenge display is missing.")
		return
	if not operations.has_method("_buy_product") or not operations.has_method("_sell_item"):
		_fail("NPC-supervised buy/sell transaction methods are missing.")
		return
	var shopping_tower := tower_manager.get_node_or_null("ShoppingTower") as Node3D
	operations.call("open_tower", "shopping_tower_baghdad")
	operations.call("_travel_to_floor", "shopping_tower_baghdad", 1)
	await create_timer(2.8).timeout
	if shopping_tower.get_node_or_null("ActiveTowerElevatorCar") == null:
		_fail("Visible elevator cabin was not created for tower travel.")
		return
	var player: CharacterBody3D = main.get("player") as CharacterBody3D
	if bool(player.get_meta("system_tower_elevator_active", true)):
		_fail("Elevator transition did not complete.")
		return
	operations.call("return_to_lobby")
	await create_timer(3.0).timeout
	if shopping_tower.get_node_or_null("ActiveTowerElevatorCar") != null:
		_fail("Elevator cabin was not cleaned up after returning to the lobby.")
		return
	var shop_employee: Node = null
	var shopping_lobby := shopping_tower.get_node_or_null("PublicLobby_Blockout")
	for child in shopping_lobby.get_children():
		if child.has_meta("system_tower_staff_id"):
			shop_employee = child
			break
	if shop_employee == null:
		_fail("No NPC shop employee can be interacted with.")
		return
	operations.call("open_staff_service", shop_employee)
	var water_stock_before := int(operations.call("get_vendor_stock", "water_bottle"))
	operations.call("_buy_product", "water_bottle", "قارورة ماء", 12)
	if int(pilot_progression.call("get_item_count", "water_bottle")) < 1:
		_fail("NPC shop purchase did not add the item to player inventory.")
		return
	if int(operations.call("get_vendor_stock", "water_bottle")) != water_stock_before - 1:
		_fail("NPC shop purchase did not reduce vendor stock.")
		return
	operations.call("_sell_item", "water_bottle", 1)
	if int(pilot_progression.call("get_item_count", "water_bottle")) != 0:
		_fail("NPC shop sale did not remove the sold inventory item.")
		return
	if int(operations.call("get_vendor_stock", "water_bottle")) != water_stock_before:
		_fail("NPC shop sale did not return the item to vendor stock.")
		return
	pilot_progression.call("add_item", "iron_ingot", 1)
	pilot_progression.call("add_item", "wood_plank", 2)
	var craft_result: Dictionary = pilot_progression.call("craft_recipe", "training_sword")
	if not bool(craft_result.get("success", false)) or int(pilot_progression.call("get_item_count", "training_sword")) < 1 or int(pilot_progression.call("get_item_count", "iron_ingot")) != 0 or int(pilot_progression.call("get_item_count", "wood_plank")) != 0:
		_fail("NPC-supervised crafting did not consume ingredients and create the requested weapon.")
		return
	pilot_progression.call("add_item", "training_sword", 1)
	var equip_result: Dictionary = pilot_progression.call("equip_item", "training_sword")
	if not bool(equip_result.get("success", false)) or str(pilot_progression.call("get_equipped_item", "weapon")) != "training_sword":
		_fail("Weapon equipment slot did not accept an owned training sword.")
		return
	if float(pilot_progression.call("get_combat_damage_bonus")) < 5.0:
		_fail("Equipped weapon did not apply its combat damage bonus.")
		return
	operations.call("_sell_item", "training_sword", 1)
	if int(pilot_progression.call("get_item_count", "training_sword")) != 2:
		_fail("NPC vendor allowed sale of a currently equipped weapon.")
		return
	operations.call("_unequip_item", "weapon")
	if not str(pilot_progression.call("get_equipped_item", "weapon")).is_empty():
		_fail("NPC service did not remove the weapon from its equipment slot.")
		return
	pilot_progression.call("add_item", "iron_ingot", 2)
	var upgrade_result: Dictionary = pilot_progression.call("upgrade_item", "training_sword")
	if not bool(upgrade_result.get("success", false)) or int(pilot_progression.call("get_item_upgrade_level", "training_sword")) != 1:
		_fail("NPC weapon upgrade service did not apply the first equipment upgrade.")
		return
	pilot_progression.call("equip_item", "training_sword")
	pilot_progression.call("consume_equipment_durability", "weapon", 100.0)
	if float(pilot_progression.call("get_item_durability", "training_sword")) > 0.0 or float(pilot_progression.call("get_combat_damage_bonus")) > 0.0:
		_fail("Broken weapon durability did not disable its equipment damage bonus.")
		return
	pilot_progression.call("add_item", "repair_kit", 1)
	var repair_result: Dictionary = pilot_progression.call("repair_item", "training_sword")
	if not bool(repair_result.get("success", false)) or float(pilot_progression.call("get_item_durability", "training_sword")) < 99.9 or float(pilot_progression.call("get_combat_damage_bonus")) < 7.0:
		_fail("NPC repair service did not restore the upgraded weapon and its damage bonus.")
		return
	pilot_progression.call("add_item", "strength_elixir", 1)
	var strength_result: Dictionary = pilot_progression.call("consume_elixir", "strength_elixir")
	if not bool(strength_result.get("success", false)) or float(pilot_progression.call("get_combat_damage_bonus")) < 22.0:
		_fail("Strength elixir did not stack with the upgraded weapon's timed combat bonus.")
		return
	pilot_progression.call("add_item", "speed_elixir", 1)
	pilot_progression.call("consume_elixir", "speed_elixir")
	if float(pilot_progression.call("get_movement_multiplier")) <= 1.0:
		_fail("Speed elixir did not increase the player movement multiplier.")
		return
	pilot_progression.call("add_item", "endurance_elixir", 1)
	pilot_progression.call("consume_elixir", "endurance_elixir")
	if float(pilot_progression.call("get_defense_bonus")) < 12.0:
		_fail("Endurance elixir did not apply a defense bonus.")
		return
	pilot_progression.call("add_item", "energy_elixir", 1)
	pilot_progression.call("consume_elixir", "energy_elixir")
	if float(pilot_progression.call("get_attack_cooldown_multiplier")) >= 1.0:
		_fail("Energy elixir did not reduce the attack cooldown multiplier.")
		return
	pilot_progression.call("add_item", "nen_awakening_elixir", 1)
	var awakening_result: Dictionary = pilot_progression.call("consume_elixir", "nen_awakening_elixir")
	if not bool(awakening_result.get("success", false)):
		_fail("Nen Awakening Elixir did not awaken Nen: " + str(awakening_result))
		return
	pilot_progression.call("add_item", "nen_control_elixir", 1)
	pilot_progression.call("consume_elixir", "nen_control_elixir")
	if not bool(pilot_progression.get("nen_unlocked")) or int(pilot_progression.get("nen_control_rank")) != 2:
		_fail("Nen Awakening/Control elixirs did not update the player's Nen state.")
		return
	operations.call("open_tower", "hunter_association_tower_baghdad")
	var demo_button := operations.get("content").get_node_or_null("NenTrainingDemoButton") as Button
	if demo_button == null or not demo_button.text.contains("ضربة النِن"):
		_fail("Hunter Association Tower is missing its Nen strike training demonstration.")
		return
	pilot_progression.call("add_item", "nen_control_elixir", 2)
	pilot_progression.call("consume_elixir", "nen_control_elixir")
	pilot_progression.call("consume_elixir", "nen_control_elixir")
	if int(pilot_progression.get("nen_control_rank")) != 4:
		_fail("Nen control elixirs did not unlock the rank-four ability threshold.")
		return
	var combat_system: Node = main.get("modern_world_combat_system") as Node
	if combat_system == null or not combat_system.has_method("light_attack") or not combat_system.has_method("skill_one") or not combat_system.has_method("skill_two") or not combat_system.has_method("dodge"):
		_fail("Modern World combat system was not created or is missing mobile combat actions.")
		return
	if combat_system.get("actor") != player or combat_system.get("progression") != pilot_progression:
		_fail("Modern World combat system is not bound to the active player and progression manager.")
		return
	var mobile_controls: Node = main.get("mobile_controls") as Node
	if mobile_controls == null:
		_fail("Mobile controls were not created.")
		return
	var mobile_callbacks := {
		"attack_pressed": "_on_mobile_attack_pressed",
		"skill_one_pressed": "_on_mobile_skill_one_pressed",
		"skill_two_pressed": "_on_mobile_skill_two_pressed",
		"dodge_pressed": "_on_mobile_dodge_pressed"
	}
	for signal_name in mobile_callbacks.keys():
		if not mobile_controls.is_connected(str(signal_name), Callable(main, str(mobile_callbacks[signal_name]))):
			_fail("Mobile combat signal is not connected: " + str(signal_name))
			return
	pilot_progression.set("nen_burst_cooldown_remaining", 0.0)
	var clean_effects: Dictionary = pilot_progression.get("active_elixir_effects")
	clean_effects.erase("nen_burst")
	pilot_progression.set("active_elixir_effects", clean_effects)
	pilot_progression.call("_refresh_nen_burst_button")
	var nen_burst_result: Dictionary = combat_system.call("skill_one")
	var nen_button: Button = pilot_progression.get("nen_burst_button") as Button
	if not bool(nen_burst_result.get("success", false)):
		_fail("Mobile Nen Burst skill activation failed: " + str(nen_burst_result))
		return
	if not pilot_progression.get("active_elixir_effects").has("nen_burst"):
		_fail("Mobile Nen Burst did not apply its timed combat effect.")
		return
	if nen_button == null or not nen_button.visible:
		_fail("Mobile Nen Burst did not expose its cooldown HUD button.")
		return
	await create_timer(0.85).timeout
	var charged_result: Dictionary = combat_system.call("skill_two")
	if not bool(charged_result.get("success", false)) or str(charged_result.get("ability_id", "")) != "charged_strike":
		_fail("Second mobile combat skill did not perform a charged strike.")
		return
	var dodge_position_before: Vector3 = player.global_position
	main.call("_on_mobile_dodge_pressed")
	if player.global_position.distance_to(dodge_position_before) < 2.0:
		_fail("Mobile dodge input did not move the player.")
		return

	var credits_before := int(operations.call("get_operations_status").get("credits", 0))
	var final_credit_reward := int(operations.call("grant_power_tower_credits", 200, true))
	var credits_after := int(operations.call("get_operations_status").get("credits", 0))
	if final_credit_reward != 8075 or credits_after - credits_before != 8075:
		_fail("Power Tower floor 200 did not grant the unique SYSTEM credit reward.")
		return
	var health_manager: Node = main.get("player_combat_health") as Node
	health_manager.call("receive_damage", 150.0, null)
	pilot_progression.call("add_item", "healing_elixir", 1)
	var healing_result: Dictionary = pilot_progression.call("consume_elixir", "healing_elixir")
	if not bool(healing_result.get("success", false)) or not bool(health_manager.get("is_wounded")) or float(health_manager.get("current_health")) <= 30.0:
		_fail("Healing elixir must restore field health without clearing the persistent wound state.")
		return
	print("Baghdad tower operations validation passed: six tower interiors, 24 NPC employees, internal/external NPC-managed ads, buy/sell, equipment, timed elixir effects, Nen progression and the 200th-floor sovereign boss arena.")
	main.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("Baghdad tower operations validation failed: " + message)
	quit(1)
