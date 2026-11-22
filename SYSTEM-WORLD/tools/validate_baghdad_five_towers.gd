extends SceneTree

const TowerManager = preload("res://scripts/baghdad_tower_landmarks_manager.gd")


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
		_expect(tower.get_node_or_null("PublicEntrance") != null, "public entrance trigger exists: " + tower_name)

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
		var radial_count := 0
		for child in district.get_children():
			if child.name.begins_with("CentralSYSTEMRadialSkybridge_"):
				radial_count += 1
		_expect(radial_count == 5, "five radial skybridges connect towers to the central SYSTEM hub")

	var amenities := manager.get_node_or_null("ConnectedCityPublicAmenities_Blockout")
	_expect(amenities != null, "shared public amenities root exists")
	if amenities != null:
		_expect(amenities.get_node_or_null("CentralSYSTEMSkySpire_Blockout") != null, "central SYSTEM skyline spire exists")
		for level in range(3):
			_expect(amenities.get_node_or_null("SharedSkyGardenTerrace_%02d" % level) != null, "shared sky garden terrace %02d exists" % level)

	region.queue_free()
	await process_frame
	print("Baghdad five-tower landmark validation passed.")
	quit(0)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		quit(1)
