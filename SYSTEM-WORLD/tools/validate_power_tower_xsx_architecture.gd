extends SceneTree

const ArchitectureScript = preload("res://scripts/system_power_tower_xsx_architecture.gd")

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
	assert(bool(architecture.get_meta("system_power_tower_independent_landmark", false)))
	assert(int(architecture.get_meta("system_power_tower_floor_count", 0)) == 200)
	assert(int(architecture.get_meta("system_power_tower_structural_tier_count", 0)) == 3)
	assert(int(architecture.get_meta("system_power_tower_facade_rib_count", 0)) == 64)
	assert(int(architecture.get_meta("system_power_tower_floor_light_band_count", 0)) == 15)
	assert(int(architecture.get_meta("system_power_tower_arrival_media_panel_count", 0)) == 4)
	assert(int(architecture.get_meta("system_power_tower_xsx_facade_sign_count", 0)) == 12)
	assert(architecture.get_node_or_null("SkyObservatory") != null)
	assert(architecture.get_node_or_null("PowerTowerRooftopHelipad") != null)
	assert(architecture.get_node_or_null("XSXCircularEntrancePodium") != null)
	var interior := lobby.get_node_or_null("XSXShopAndCafeteriaInterior") as Node3D
	assert(interior != null)
	for facility_name in ["TraditionalWeaponsGallery", "ArmorShowroom", "NenElixirCabinet", "SkillScrollLibrary", "HunterAccessoriesGallery", "PowerTowerCafeteria", "PowerTowerNenTrainingHall"]:
		assert(interior.get_node_or_null(facility_name) != null, "Missing Power Tower interior facility: " + facility_name)
	assert(int(architecture.get_meta("system_power_tower_cafeteria_table_count", 0)) == 4)
	var armor_showroom := interior.get_node_or_null("ArmorShowroom")
	assert(armor_showroom != null)
	assert(int(armor_showroom.get_meta("system_footwear_display_count", 0)) == 5)
	assert(armor_showroom.get_node_or_null("FootwearProgressionSign") != null)
	assert(int(architecture.get_meta("system_power_tower_cafeteria_seat_count", 0)) == 16)
	assert(interior.get_node_or_null("PowerTowerCombatStyleBoard") != null)
	var combat_board := interior.get_node_or_null("PowerTowerCombatStyleBoard")
	assert(combat_board.get_node_or_null("CombatStyleBoardInteraction") != null)
	var nen_hall := interior.get_node_or_null("PowerTowerNenTrainingHall")
	assert(nen_hall != null)
	assert(nen_hall.get_node_or_null("NenTrainingInteractionArea") != null)
	assert(str(nen_hall.get_meta("system_interaction_action", "")) == "POWER_TOWER_NEN_TRAINING")
	assert(not bool(architecture.get_meta("system_power_tower_shop_modern_firearms_allowed", true)))
	print("X-S-X POWER TOWER ARCHITECTURE VALIDATION PASSED: 200-floor identity, tapered tiers, 12 facade marks, observatory, helipad, circular podium, shop galleries and cafeteria.")
	quit(0)
