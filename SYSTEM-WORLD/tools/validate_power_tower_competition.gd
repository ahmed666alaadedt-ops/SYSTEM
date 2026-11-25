extends SceneTree

const ArchitectureScript = preload("res://scripts/system_power_tower_xsx_architecture.gd")
const CompetitionScript = preload("res://scripts/system_power_tower_competition_manager.gd")

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
	assert(int(manager.call("get_arena_count_for_floor", 1) == 8)
	assert(int(manager.call("get_arena_count_for_floor", 20) == 8)
	assert(int(manager.call("get_arena_count_for_floor", 21) == 6)
	assert(int(manager.call("get_arena_count_for_floor", 41) == 4)
	assert(int(manager.call("get_arena_count_for_floor", 61) == 3)
	assert(int(manager.call("get_arena_count_for_floor", 81) == 2)
	assert(int(manager.call("get_arena_count_for_floor", 101) == 1)
	assert(int(manager.call("get_arena_count_for_floor", 200) == 1)
	assert(int(manager.call("get_arena_count_for_floor", 0) == 0)
	assert(int(manager.call("get_arena_count_for_floor", 201) == 0)

	var early_nen: Dictionary = manager.call("get_nen_stage_for_floor", 1)
	var upper_nen: Dictionary = manager.call("get_nen_stage_for_floor", 175)
	assert(early_nen.get("stage") == "DISCOVERY")
	assert(upper_nen.get("stage") == "NEN_MASTERY")
	assert(manager.call("get_combat_styles_for_floor", 1).has("KUNG_FU"))
	assert(manager.call("get_combat_styles_for_floor", 150) == ["NEN_TECHNIQUES", "UNARMED_HAND_TO_HAND"])

	var trained: Dictionary = manager.call("apply_nen_training", {"nen_mastery": 90}, 20)
	assert(bool(trained.get("success", false)))
	assert(int(trained["profile"]["nen_mastery"]) == 110)
	assert(trained["profile"]["nen_stage"] == "TEN")

	var crowd := architecture.get_node_or_null("PowerTowerCompetitionManager/PowerTower500SpectatorNPCs")
	assert(crowd != null)
	assert(int(crowd.get_meta("system_visible_spectator_count", 0)) == 500)
	assert(int(crowd.get_meta("system_npc_population", 0)) == 500)
	var bodies := crowd.get_node_or_null("SpectatorNPCBodies500") as MultiMeshInstance3D
	assert(bodies != null and bodies.multimesh.instance_count == 500)

	var amenities := lobby.get_node_or_null("PowerTowerRestaurantAndRecreation")
	assert(amenities != null)
	for amenity in ["PowerTowerRestaurant", "PowerTowerRecreationLounge", "PowerTowerEntertainmentZone"]:
		assert(amenities.get_node_or_null(amenity) != null)

	var bets := [
		{"bettor_id": "fan_001", "side": "PLAYER_A", "stake": 50},
		{"bettor_id": "fan_002", "side": "PLAYER_B", "stake": 100}
	]
	var settled: Dictionary = manager.call("settle_virtual_bets", "match_test_001", bets, "PLAYER_A", true)
	assert(bool(settled.get("success", false)))
	var ledger: Dictionary = settled["ledger"]
	assert(ledger["currency"] == "SYSTEM_VIRTUAL_CREDITS")
	assert(int(ledger["tower_profit"]) == 10)
	assert(int(ledger["fighter_reward"]) == 10)
	assert(ledger["winning_bettor_payouts"].size() == 1)
	assert(int(ledger["winning_bettor_payouts"][0]["total_payout"]) == 130)
	assert(not bool(manager.settle_virtual_bets("match_test_001", bets, "PLAYER_A", true).get("success", false)))
	assert(not bool(manager.call("settle_virtual_bets", "match_test_002", bets, "PLAYER_A", false).get("success", false)))

	print("POWER TOWER COMPETITION VALIDATION PASSED: 200-floor arena ladder, Nen progression, martial styles, 500 spectator visual proxies, restaurant/recreation and idempotent virtual-credit ledger.")
	quit(0)
