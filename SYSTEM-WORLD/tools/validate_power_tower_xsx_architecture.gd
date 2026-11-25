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
	var architecture := ArchitectureScript.new()
	tower.add_child(architecture)
	root.add_child(tower)
	await process_frame
	assert(bool(architecture.get_meta("system_power_tower_independent_landmark", false)))
	assert(int(architecture.get_meta("system_power_tower_floor_count", 0)) == 200)
	assert(int(architecture.get_meta("system_power_tower_structural_tier_count", 0)) == 3)
	assert(int(architecture.get_meta("system_power_tower_xsx_facade_sign_count", 0)) == 12)
	assert(architecture.get_node_or_null("SkyObservatory") != null)
	assert(architecture.get_node_or_null("PowerTowerRooftopHelipad") != null)
	assert(architecture.get_node_or_null("XSXCircularEntrancePodium") != null)
	assert(not bool(architecture.get_meta("system_power_tower_shop_modern_firearms_allowed", true)))
	print("X-S-X POWER TOWER ARCHITECTURE VALIDATION PASSED: 200-floor identity, tapered tiers, 12 facade marks, observatory, helipad and circular podium.")
	quit(0)
