extends SceneTree

const BaghdadTowerManagerScript = preload("res://scripts/baghdad_tower_landmarks_manager.gd")

class FakeTerrain extends Node:
	func is_land_position(_x: float, _z: float) -> bool:
		return true

	func get_terrain_height(_x: float, _z: float) -> float:
		return 0.0

class FakeRegion extends Node3D:
	var terrain: Node

	func get_city_anchor(city_name: String) -> Vector3:
		return Vector3.ZERO if city_name == "Baghdad" else Vector3.INF


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var region := FakeRegion.new()
	region.name = "ModernWorldRegionManager"
	region.terrain = FakeTerrain.new()
	root.add_child(region)

	var manager := BaghdadTowerManagerScript.new()
	region.add_child(manager)

	var towers: Array[Dictionary] = manager.call("get_tower_positions")
	if towers.size() != 5:
		_fail("Expected five Baghdad landmark towers; found %d." % towers.size())
		return

	var expected_names := [
		"HunterAssociationTower",
		"PowerTower",
		"BusinessTower",
		"ShoppingTower",
		"EntertainmentTower"
	]
	for tower_name in expected_names:
		var tower := manager.get_node_or_null(NodePath(tower_name))
		if tower == null:
			_fail("Missing tower node: " + tower_name)
			return
		var district := tower.get_node_or_null(NodePath("RooftopMicroCity_" + tower_name))
		if district == null:
			_fail("Missing supported rooftop micro-city on " + tower_name)
			return
		if not bool(district.get_meta("supported_by_tower", false)):
			_fail("Rooftop district is not marked as tower-supported: " + tower_name)
			return
		for quarter_name in ["ResidentialQuarter", "MarketAndServicesQuarter", "GardenAndLeisureQuarter", "CivicAndCultureQuarter"]:
			if district.get_node_or_null(NodePath(quarter_name)) == null:
				_fail("Missing rooftop quarter %s on %s." % [quarter_name, tower_name])
				return

	var network := manager.get_node_or_null("BaghdadUnifiedRooftopCityNetwork")
	if network == null:
		_fail("Unified rooftop city network was not created.")
		return
	if int(network.get_meta("connected_tower_count", 0)) != 5:
		_fail("Unified rooftop network does not report five connected towers.")
		return
	var bridge_count := 0
	var lift_core_count := 0
	for child in network.get_children():
		# Count visible deck nodes only; each bridge also owns a collision body.
		if child is MeshInstance3D and child.name.begins_with("UpperCityBridge_"):
			bridge_count += 1
		if child is MeshInstance3D and child.name.begins_with("RooftopCityVerticalLiftCore_"):
			lift_core_count += 1
	if bridge_count != 5:
		_fail("Expected five upper-city bridges; found %d." % bridge_count)
		return
	if lift_core_count != 5:
		_fail("Expected five vertical access cores; found %d." % lift_core_count)
		return

	print("Baghdad rooftop city runtime passed: 5 towers, 20 rooftop quarters, 5 upper bridges, 5 access cores.")
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad rooftop city runtime failed: " + message)
	quit(1)
