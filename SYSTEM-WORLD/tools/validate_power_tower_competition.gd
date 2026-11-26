extends SceneTree

const ArchitectureScript = preload("res://scripts/system_power_tower_xsx_architecture.gd")
const ProgressionScript = preload("res://scripts/system_player_progression.gd")
const PowerTowerManagerScript = preload("res://scripts/system_power_tower_manager.gd")
const CombatScript = preload("res://scripts/modern_world_combat_system.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var tower := Node3D.new()
	tower.name = "PowerTower"
	tower.set_meta("tower_id", "power_tower_baghdad")
	tower.set_meta("tower_floor_count", 200)
	tower.set_meta("tower_is_connected_district_member", false)
	var lobby := Node3D.new()
	lobby.name = "PublicLobby_Blockout"
	tower.add_child(lobby)
	var architecture := ArchitectureScript.new()
	tower.add_child(architecture)
	root.add_child(tower)
	await process_frame

	var manager := architecture.get_node_or_null("PowerTowerCompetitionManager") as Node3D
	assert(manager != null, "Competition manager must be integrated into the independent tower.")
	assert(int(manager.call("get_arena_count_for_floor", 1)) == 8)
	assert(int(manager.call("get_arena_count_for_floor", 20)) == 8)
	assert(int(manager.call("get_arena_count_for_floor", 21)) == 6)
	assert(int(manager.call("get_arena_count_for_floor", 41)) == 4)
	assert(int(manager.call("get_arena_count_for_floor", 61)) == 3)
	assert(int(manager.call("get_arena_count_for_floor", 81)) == 2)
	assert(int(manager.call("get_arena_count_for_floor", 101)) == 1)
	assert(int(manager.call("get_arena_count_for_floor", 200)) == 1)
	assert(int(manager.call("get_arena_count_for_floor", 0)) == 0)
	assert(int(manager.call("get_arena_count_for_floor", 201)) == 0)

	var arena_root := manager.get_node_or_null("PowerTowerProgressiveArenaFloors")
	assert(arena_root != null, "Physical arena floors must be generated.")
	assert(int(arena_root.get_meta("system_arena_instance_count", 0)) == 560)
	assert(int(arena_root.get_meta("system_arena_boundary_rail_count", 0)) == 2240)
	var arena_floors := arena_root.get_node_or_null("ArenaFloorSurfaces560") as MultiMeshInstance3D
	assert(arena_floors != null and arena_floors.multimesh.instance_count == 560)
	var arena_rails := arena_root.get_node_or_null("ArenaSafetyRails2240") as MultiMeshInstance3D
	assert(arena_rails != null and arena_rails.multimesh.instance_count == 2240)

	var early_nen: Dictionary = manager.call("get_nen_stage_for_floor", 1)
	var pre_gate_hatsu: Dictionary = manager.call("get_nen_stage_for_floor", 80)
	assert(pre_gate_hatsu.get("stage") == "HATSU_FOUNDATION")
	var upper_nen: Dictionary = manager.call("get_nen_stage_for_floor", 175)
	assert(early_nen.get("stage") == "DISCOVERY")
	assert(upper_nen.get("stage") == "NEN_MASTERY")
	assert(manager.call("get_combat_styles_for_floor", 1).has("KUNG_FU"))
	assert(manager.call("get_combat_styles_for_floor", 80).has("BOW_AND_ARROW"))
	assert(manager.call("get_combat_styles_for_floor", 81) == ["NEN_TECHNIQUES", "UNARMED_HAND_TO_HAND"])
	assert(manager.call("get_combat_styles_for_floor", 150) == ["NEN_TECHNIQUES", "UNARMED_HAND_TO_HAND"])

	var progression := ProgressionScript.new()
	progression.name = "SYSTEMPlayerProgression"
	root.add_child(progression)
	await process_frame
	progression.call("_reset_progress")
	var training_stages := [
		{"floor": 1, "technique": "AURA_AWARENESS", "rank": 1},
		{"floor": 21, "technique": "TEN", "rank": 2},
		{"floor": 41, "technique": "REN", "rank": 3},
		{"floor": 61, "technique": "ZETSU", "rank": 4},
		{"floor": 80, "technique": "HATSU", "rank": 5}
	]
	var training_index := 1
	var stage_index := 0
	for stage in training_stages:
		for session in range(3):
			var training_id := "pt_nen_%02d" % training_index
			var training_result: Dictionary = manager.call("train_player_nen", training_id, stage["floor"], stage["technique"])
			assert(bool(training_result.get("success", false)), "Nen training failed: " + training_id)
			var expected_rank := int(stage["rank"]) if session == 2 or int(stage["rank"]) == 1 else int(stage["rank"]) - 1
			assert(int(training_result.get("nen_control_rank", 0)) == expected_rank)
			training_index += 1
		if stage_index == 0:
			assert(not bool(manager.call("train_player_nen", "pt_nen_skip_stage", 41, "REN").get("success", false)))
		stage_index += 1
	var nen_status: Dictionary = progression.call("get_power_tower_nen_training_status")
	assert(bool(nen_status.get("nen_unlocked", false)))
	assert(int(nen_status.get("nen_control_rank", 0)) == 5)
	assert(int(nen_status.get("training_sessions", 0)) == 15)
	assert(str(nen_status.get("next_stage", "")) == "ADVANCED_NEN")
	assert(not bool(manager.call("train_player_nen", "pt_nen_15", 81, "HATSU").get("success", false)))
	assert(not bool(manager.call("train_player_nen", "pt_nen_discovery_overflow", 1, "AURA_AWARENESS").get("success", false)))
	assert(not bool(manager.call("train_player_nen", "pt_invalid_technique", 21, "HATSU").get("success", false)))

	var combat_actor := CharacterBody3D.new()
	combat_actor.name = "PowerTowerCombatStyleTestActor"
	root.add_child(combat_actor)
	var combat := CombatScript.new()
	combat.name = "ModernWorldCombatSystem"
	root.add_child(combat)
	combat.call("bind_actor", combat_actor, null, progression)
	var early_styles: Array = manager.call("get_combat_styles_for_floor", 80)
	assert(bool(combat.call("select_power_tower_combat_style", "KUNG_FU", early_styles).get("success", false)))
	assert(bool(progression.call("add_item", "training_sword", 1)))
	assert(bool(progression.call("equip_item", "training_sword").get("success", false)))
	assert(bool(combat.call("select_power_tower_combat_style", "TRADITIONAL_MELEE", early_styles).get("success", false)))
	assert(not bool(combat.call("select_power_tower_combat_style", "KUNG_FU", early_styles).get("success", false)))
	assert(bool(progression.call("unequip_item", "weapon")))
	assert(bool(combat.call("select_power_tower_combat_style", "KUNG_FU", early_styles).get("success", false)))
	assert(bool(progression.call("add_item", "composite_bow", 1)))
	assert(bool(progression.call("equip_item", "composite_bow").get("success", false)))
	assert(bool(combat.call("select_power_tower_combat_style", "BOW_AND_ARROW", early_styles).get("success", false)))
	var arrows_before_purchase := int(progression.call("get_item_count", "reinforced_arrows"))
	assert(bool(progression.call("add_item", "reinforced_arrows", 2)))
	assert(int(progression.call("get_item_count", "reinforced_arrows")) == arrows_before_purchase + 2)
	assert(bool(progression.call("consume_item", "reinforced_arrows", 1)))
	assert(int(progression.call("get_item_count", "reinforced_arrows")) == arrows_before_purchase + 1)
	var nen_only_styles: Array = manager.call("get_combat_styles_for_floor", 81)
	assert(not bool(combat.call("select_power_tower_combat_style", "NEN_TECHNIQUES", nen_only_styles).get("success", false)))
	assert(bool(progression.call("unequip_item", "weapon")))
	assert(bool(combat.call("select_power_tower_combat_style", "NEN_TECHNIQUES", nen_only_styles).get("success", false)))


	var crowd := architecture.get_node_or_null("PowerTowerCompetitionManager/PowerTower500SpectatorNPCs")
	assert(crowd != null)
	assert(int(crowd.get_meta("system_visible_spectator_count", 0)) == 500)
	assert(int(crowd.get_meta("system_npc_population", 0)) == 500)
	assert(int(crowd.get_meta("system_multimesh_impostor_count", 0)) == 492)
	assert(int(crowd.get_meta("system_full_rig_count", 0)) == 8)
	assert(int(crowd.get_meta("system_detailed_actor_nodes_created", 0)) == 8)
	var detailed_actor_count := 0
	for crowd_child in crowd.get_children():
		if crowd_child is CharacterBody3D and bool(crowd_child.get_meta("system_npc_full_rig", false)):
			detailed_actor_count += 1
			assert(crowd_child.get_node_or_null("Torso") != null)
			assert(crowd_child.get_node_or_null("Head") != null)
			assert(crowd_child.get_node_or_null("Arm_L") != null and crowd_child.get_node_or_null("Arm_R") != null)
			assert(crowd_child.get_node_or_null("Leg_L") != null and crowd_child.get_node_or_null("Leg_R") != null)
	assert(detailed_actor_count == 8, "Eight detailed spectator NPC rigs must exist as real scene nodes.")
	var bodies := crowd.get_node_or_null("SpectatorNPCBodies500") as MultiMeshInstance3D
	assert(bodies != null and bodies.multimesh.instance_count == 492)
	assert(int(crowd.get_meta("system_multimesh_impostor_count", 0)) == 492)
	assert(int(crowd.get_meta("system_full_rig_count", 0)) == 8)

	var amenities := lobby.get_node_or_null("PowerTowerRestaurantAndRecreation")
	assert(amenities != null)
	for amenity_name in ["PowerTowerRestaurant", "PowerTowerRecreationLounge", "PowerTowerEntertainmentZone"]:
		var amenity := amenities.get_node_or_null(amenity_name) as Node3D
		assert(amenity != null and amenity.position.length() < 49.0, "Power Tower amenity must remain inside the entrance podium.")
	for amenity in ["PowerTowerRestaurant", "PowerTowerRecreationLounge", "PowerTowerEntertainmentZone"]:
		assert(amenities.get_node_or_null(amenity) != null)
	var interior := lobby.get_node_or_null("XSXShopAndCafeteriaInterior")
	assert(interior != null)
	assert(interior.get_node_or_null("PowerTowerNenTrainingHall") != null)
	assert(interior.get_node_or_null("PowerTowerCafeteria") != null)

	# Exercise the real 500-NPC prediction pool and three-beneficiary settlement ledger.
	var betting_manager := PowerTowerManagerScript.new()
	root.add_child(betting_manager)
	await process_frame
	var elevator_bank := lobby.get_node_or_null("XSXShopAndCafeteriaInterior/PowerTowerLobbyElevatorBank")
	assert(elevator_bank != null)
	assert(int(elevator_bank.get_meta("system_power_tower_functional_elevator_count", 0)) == 3)
	var elevator_a := elevator_bank.get_node_or_null("ElevatorInteractiveControl_A")
	var elevator_b := elevator_bank.get_node_or_null("ElevatorInteractiveControl_B")
	var elevator_c := elevator_bank.get_node_or_null("ElevatorInteractiveControl_C")
	assert(elevator_a != null and elevator_b != null and elevator_c != null)
	for elevator in [elevator_a, elevator_b, elevator_c]:
		assert(elevator.is_in_group("system_interactable"))
		assert(elevator.has_method("request_floor"))
		assert(elevator.has_method("get_elevator_status"))
		assert(elevator.get_node_or_null("ElevatorControlInteractionShape") != null)
	var elevator_player := CharacterBody3D.new()
	elevator_player.name = "PowerTowerElevatorValidationPlayer"
	elevator_player.add_to_group("system_player")
	root.add_child(elevator_player)
	betting_manager.highest_cleared_floor = 2
	assert(int(elevator_a.call("get_max_accessible_floor")) == 3)
	var elevator_trip: Dictionary = elevator_a.call("request_floor", 3)
	assert(bool(elevator_trip.get("success", false)), "Functional elevator should accept an unlocked floor.")
	assert(bool(elevator_player.get_meta("system_tower_elevator_active", false)))
	await create_timer(float(elevator_trip.get("travel_seconds", 2.0)) + 0.7).timeout
	assert(int(elevator_a.call("get_current_lift_floor")) == 3)
	assert(not bool(elevator_player.get_meta("system_tower_elevator_active", false)))
	assert(not bool(elevator_a.call("get_elevator_status").get("moving", true)))
	assert(not bool(elevator_a.call("request_floor", 4).get("success", false)), "Elevator must not expose floors beyond the player's progression.");
	var early_floor_data: Dictionary = betting_manager.call("get_floor_data", 80)
	var upper_floor_data: Dictionary = betting_manager.call("get_floor_data", 81)
	assert(bool(early_floor_data.get("weapons_allowed", false)))
	assert(early_floor_data.get("available_combat_styles", []).has("NEN_TECHNIQUES"))
	assert(not bool(early_floor_data.get("nen_required", true)))
	assert(not bool(upper_floor_data.get("weapons_allowed", true)))
	assert(bool(upper_floor_data.get("nen_required", false)))
	assert(upper_floor_data.get("available_combat_styles", []) == ["NEN_TECHNIQUES", "UNARMED_HAND_TO_HAND"])
	# Verify the complete user-approved F-to-SSS progression across all 200 floors.
	var expected_rank_by_floor := {
		1: "F", 20: "F", 21: "E", 40: "E", 41: "D", 60: "D",
		61: "C", 80: "C", 81: "B", 100: "B", 101: "A", 120: "A",
		121: "S", 150: "S", 151: "SS", 179: "SS", 180: "SSS", 200: "SSS"
	}
	for rank_floor_value in expected_rank_by_floor.keys():
		var rank_floor := int(rank_floor_value)
		var rank_data: Dictionary = betting_manager.call("get_floor_data", rank_floor)
		assert(str(rank_data.get("rank", "")) == str(expected_rank_by_floor[rank_floor_value]), "Power Tower rank ladder mismatch at floor %d." % rank_floor)
	var floor_one_data: Dictionary = betting_manager.call("get_floor_data", 1)
	assert(int(floor_one_data.get("time_limit_seconds", 0)) == 600, "A ten-minute floor-start deadline must be configured.")
	betting_manager.highest_cleared_floor = 0
	assert(bool(betting_manager.call("request_floor", 1, 100).get("success", false)))
	assert(int(betting_manager.floor_start_deadline_unix) > 0)
	var deadline_expiry: Dictionary = betting_manager.call("check_floor_start_deadline", int(betting_manager.floor_start_deadline_unix) + 1)
	assert(bool(deadline_expiry.get("expired", false)))
	assert(int(betting_manager.active_floor) == 0)
	assert(bool(betting_manager.call("request_floor", 1, 100).get("success", false)))
	assert(bool(betting_manager.call("begin_floor_duel", 1).get("success", false)))
	var started_deadline_check: Dictionary = betting_manager.call("check_floor_start_deadline", int(Time.get_unix_time_from_system()) + 600)
	assert(not bool(started_deadline_check.get("expired", false)), "The countdown must stop once the official duel begins.")
	betting_manager.call("abandon_active_floor")

	# Heliport permissions combine tower floor, verified guild missions, Nen control and demonstrated Nen skills.
	progression.verified_hunter_mission_points = 2500
	progression.verified_hunter_mission_count = 10
	progression.nen_skill_use_count = 50
	progression.nen_skill_ids = ["ten", "ren"]
	betting_manager.highest_cleared_floor = 121
	var heliport_s: Dictionary = betting_manager.call("get_heliport_access_status", progression)
	assert(bool(heliport_s.get("access", false)) and str(heliport_s.get("eligible_rank", "")) == "S")
	progression.verified_hunter_mission_points = 5000
	progression.verified_hunter_mission_count = 20
	progression.nen_skill_use_count = 150
	progression.nen_skill_ids = ["ten", "ren", "hatsu"]
	betting_manager.highest_cleared_floor = 151
	var heliport_ss: Dictionary = betting_manager.call("get_heliport_access_status", progression)
	assert(bool(heliport_ss.get("access", false)) and str(heliport_ss.get("eligible_rank", "")) == "SS")
	progression.hunter_sss_board_approved = true
	progression.verified_hunter_mission_points = 5000
	progression.verified_hunter_mission_count = 30
	progression.nen_skill_use_count = 200
	betting_manager.highest_cleared_floor = 180
	var heliport_sss: Dictionary = betting_manager.call("get_heliport_access_status", progression)
	assert(bool(heliport_sss.get("access", false)) and str(heliport_sss.get("eligible_rank", "")) == "SSS")
	betting_manager.spectator_matches.clear()
	betting_manager.spectator_npc_ticket_balances.clear()
	betting_manager.spectator_daily_counts.clear()
	betting_manager.power_tower_house_revenue_total = 0
	betting_manager.power_tower_fighter_reward_ledger.clear()
	var match_id := "power_tower_validator_match_500_%d" % Time.get_ticks_usec()
	var registration: Dictionary = betting_manager.call("register_spectator_match", match_id, "FIGHTER_A", "FIGHTER_B", 1)
	assert(bool(registration.get("success", false)), "Could not register 1v1 spectator match.")
	var seeded: Dictionary = betting_manager.call("populate_power_tower_npc_predictions", match_id, 500)
	assert(bool(seeded.get("success", false)))
	assert(int(seeded.get("submitted", 0)) == 500, "All 500 NPC fans should submit virtual predictions.")
	var open_match: Dictionary = betting_manager.call("get_spectator_match", match_id)
	var predictions: Dictionary = open_match.get("predictions", {})
	assert(predictions.size() == 500)
	assert(str(open_match.get("state", "")) == "open")
	var locked: Dictionary = betting_manager.call("lock_spectator_predictions", match_id)
	assert(bool(locked.get("success", false)))
	var total_pool := int(open_match.get("total_pool", 0))
	var winning_stake := 0
	for prediction_value in predictions.values():
		if str(prediction_value.get("predicted_winner_id", "")) == "FIGHTER_A":
			winning_stake += int(prediction_value.get("stake_amount", 0))
	assert(winning_stake > 0 and winning_stake < total_pool)
	var losing_pool := total_pool - winning_stake
	var expected_house := int(floor(float(losing_pool) * 0.10))
	var expected_fighter := int(floor(float(losing_pool) * 0.10))
	var expected_bettor_profit := losing_pool - expected_house - expected_fighter
	var settlement: Dictionary = betting_manager.call("settle_spectator_match", match_id, "FIGHTER_A", "LOCAL_COMBAT_AUTHORITY")
	assert(bool(settlement.get("success", false)))
	assert(int(settlement.get("house_revenue", -1)) == expected_house)
	assert(int(settlement.get("fighter_reward", -1)) == expected_fighter)
	assert(int(settlement.get("bettor_profit_pool", -1)) == expected_bettor_profit)
	assert(int(settlement.get("total_paid_out", -1)) == winning_stake + expected_bettor_profit)
	assert(int(betting_manager.power_tower_house_revenue_total) == expected_house)
	assert(int(betting_manager.power_tower_fighter_reward_ledger.get("FIGHTER_A", 0)) == expected_fighter)
	assert(not bool(betting_manager.call("settle_spectator_match", match_id, "FIGHTER_A", "LOCAL_COMBAT_AUTHORITY").get("success", false)))

	print("POWER TOWER COMPETITION VALIDATION PASSED: 560 physical arena platforms, progressive Nen player training, 500 visible fans (492 LOD + 8 detailed) and 500 NPC fan predictions, three-way virtual-credit settlement, interior amenities and independent 200-floor architecture.")
	quit(0)
