extends SceneTree

const TowerManager = preload("res://scripts/baghdad_tower_landmarks_manager.gd")

var failures := 0


class MockTerrain extends Node:
	func is_land_position(_x: float, _z: float) -> bool:
		return true

	func get_terrain_height(_x: float, _z: float) -> float:
		return 0.0


class MockBaghdadRegion extends Node3D:
	var terrain: Node

	func get_city_anchor(_city_name: String) -> Vector3:
		return Vector3.ZERO


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var region := MockBaghdadRegion.new()
	region.name = "MockBaghdadRegion"
	region.terrain = MockTerrain.new()
	region.add_child(region.terrain)
	root.add_child(region)

	var manager := TowerManager.new()
	region.add_child(manager)
	await process_frame

	var towers := manager.get_tower_positions()
	_expect(towers.size() == 5, "exactly five Baghdad district towers are generated")
	_expect(manager.get_node_or_null("PowerTower") == null, "Power Tower remains separate from the five-tower district")

	var expected_towers := [
		"HunterAssociationTower",
		"BusinessTower",
		"ShoppingTower",
		"EntertainmentTower",
		"TechnologyInnovationTower"
	]
	for tower_name in expected_towers:
		var tower := manager.get_node_or_null(tower_name)
		_expect(tower != null, "tower exists: " + tower_name)
		if tower == null:
			continue
		_expect(tower.get_node_or_null("PublicPodiumAndArrivalHall") != null, "three-level public podium exists: " + tower_name)
		_expect(tower.get_node_or_null("TowerFacilities_Blockout") != null, "facility zone exists: " + tower_name)
		var transport := tower.get_node_or_null("VerticalTransport_Blockout")
		_expect(transport != null, "lift and stair core blockout exists: " + tower_name)
		if transport != null:
			_expect(transport.get_node_or_null("PanoramicLiftShaft_00") != null, "panoramic lift shaft exists: " + tower_name)
			_expect(transport.get_node_or_null("ProtectedStairCore_00") != null, "protected stair core exists: " + tower_name)
			_expect(transport.get_node_or_null("FloorDirectoryMarkers") != null, "floor directory exists: " + tower_name)
		var gardens := tower.get_node_or_null("SkyGardenTerraces")
		_expect(gardens != null, "elevated sky gardens exist: " + tower_name)
		if gardens != null:
			_expect(gardens.get_node_or_null("ElevatedGardenDeck_00") != null, "lower sky garden deck exists: " + tower_name)
			_expect(gardens.get_node_or_null("ElevatedGardenDeck_01") != null, "middle sky garden deck exists: " + tower_name)
			_expect(gardens.get_node_or_null("ElevatedGardenDeck_02") != null, "upper sky garden deck exists: " + tower_name)
		_expect(tower.get_node_or_null("PublicEntrance") != null, "public entrance trigger exists: " + tower_name)
		_expect(int(tower.get_meta("transport_blockout_revision", 0)) == 1, "transport blockout revision is registered: " + tower_name)
		_expect(int(tower.get_meta("sky_garden_revision", 0)) == 1, "sky garden revision is registered: " + tower_name)

	var shopping := manager.get_node_or_null("ShoppingTower")
	if shopping != null:
		var facilities := shopping.get_node_or_null("TowerFacilities_Blockout")
		var cinema := facilities.get_node_or_null("CinemaSixHallLayout_Blockout") if facilities != null else null
		_expect(cinema != null, "Shopping Tower cinema layout exists")
		if cinema != null:
			_expect(cinema.get_child_count() == 6, "cinema contains six halls")
			for hall_index in range(1, 7):
				var hall := cinema.get_node_or_null("CinemaHall_%02d" % hall_index)
				_expect(hall != null, "cinema hall %02d exists" % hall_index)
				if hall != null:
					_expect(hall.get_node_or_null("CinemaWalkableFloor") != null, "cinema hall %02d has floor collision" % hall_index)

	var district := manager.get_node_or_null("FiveTowerConnectedDistrict")
	_expect(district != null, "connected five-tower district exists")
	if district != null:
		for bridge_index in range(5):
			var bridge_name := "CentralSYSTEMRadialSkybridge_%d" % bridge_index
			_expect(district.get_node_or_null(bridge_name) != null, "radial skybridge exists: " + bridge_name)

	var amenities := manager.get_node_or_null("ConnectedCityPublicAmenities_Blockout")
	_expect(amenities != null, "shared public amenities root exists")
	if amenities != null:
		_expect(amenities.get_node_or_null("CentralSYSTEMSkySpire_Blockout") != null, "central SYSTEM skyline spire exists")
		for level in range(3):
			_expect(amenities.get_node_or_null("SharedSkyGardenTerrace_%02d" % level) != null, "shared sky garden terrace %02d exists" % level)

	region.queue_free()
	await process_frame
	if failures == 0:
		print("Baghdad five-tower landmark validation passed.")
		quit(0)
	else:
		push_error("Baghdad five-tower landmark validation failed: %d check(s)." % failures)
		quit(1)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1


func _count_named_prefix(node: Node, prefix: String) -> int:
	var count := 0
	for child in node.get_children():
		if child.name.begins_with(prefix):
			count += 1
		count += _count_named_prefix(child, prefix)
	return count
