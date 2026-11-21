extends SceneTree

const LANDMARK_INTEGRATION_SCRIPT = preload("res://scripts/system_baghdad_landmark_integration.gd")

class MockTerrain:
	extends Node
	func get_terrain_height(_x: float, _z: float) -> float:
		return 0.0


class MockRegion:
	extends Node3D
	func get_city_anchor(city_name: String) -> Vector3:
		return Vector3.ZERO if city_name == "Baghdad" else Vector3.INF


class MockServices:
	extends Node
	func get_service_locations() -> Array[Dictionary]:
		return [
			{"city": "Baghdad", "position": Vector3(45.0, 0.0, 25.0)},
			{"city": "Baghdad", "position": Vector3(-35.0, 0.0, -20.0)},
			{"city": "Tokyo", "position": Vector3(1000.0, 0.0, 1000.0)}
		]


class MockTowers:
	extends Node
	func get_tower_positions() -> Array[Dictionary]:
		return [
			{"id": "hunter_association_tower_baghdad", "position": Vector3(0.0, 0.0, 365.0)},
			{"id": "power_tower_baghdad", "position": Vector3(850.0, 0.0, 600.0)}
		]


class MockMap:
	extends Node
	var registered: Dictionary = {}
	func register_location(world_id: String, location_id: String, region_id: String, display_name: String, location_type: int, position: Vector3, fast_travel: bool = false) -> bool:
		var key := world_id + ":" + location_id
		if registered.has(key):
			return false
		registered[key] = {
			"region_id": region_id,
			"name": display_name,
			"type": location_type,
			"position": position,
			"fast_travel": fast_travel
		}
		return true


func _initialize() -> void:
	_run_validation()


func _fail(message: String) -> void:
	push_error("Baghdad landmark map integration validation failed: " + message)
	quit(1)


func _run_validation() -> void:
	var region := MockRegion.new()
	region.name = "MockBaghdadRegion"
	root.add_child(region)

	var services := MockServices.new()
	services.name = "ModernCityServicesManager"
	region.add_child(services)

	var towers := MockTowers.new()
	towers.name = "BaghdadTowerLandmarksManager"
	region.add_child(towers)

	var terrain := MockTerrain.new()
	root.add_child(terrain)

	var map_manager := MockMap.new()
	root.add_child(map_manager)

	var integration: Node3D = LANDMARK_INTEGRATION_SCRIPT.new()
	region.add_child(integration)
	integration.call("build", terrain)
	integration.call("register_map_locations", map_manager, "2")

	for required_id in [
		"hunter_exam_tunnel_start_baghdad",
		"hunter_exam_public_notice_baghdad",
		"baghdad_archaeological_ruins",
		"baghdad_international_motorsport_park"
	]:
		if not map_manager.registered.has("2:" + required_id):
			_fail("Required Baghdad exploration pin is missing: " + required_id)
			return

	if integration.get_node_or_null("hunter_exam_tunnel_start_baghdad") == null:
		_fail("Hunter examination tunnel geometry was not built.")
		return
	if integration.get_node_or_null("hunter_exam_public_notice_baghdad") == null:
		_fail("Hunter examination public notice geometry was not built.")
		return
	if integration.get_node_or_null("baghdad_archaeological_ruins") == null:
		_fail("Archaeological exploration site geometry was not built.")
		return

	var road_count := 0
	for child in integration.get_children():
		if child is MeshInstance3D and child.name.begins_with("BaghdadRoad_"):
			road_count += 1
	if road_count < 4:
		_fail("Expected connected road links to civic services, the motorsport venue and the Power Tower.")
		return

	var power_tower_was_used := false
	for child in integration.get_children():
		if child is MeshInstance3D and child.name.begins_with("BaghdadRoad_"):
			if child.mesh is BoxMesh:
				power_tower_was_used = true
				break
	if not power_tower_was_used:
		_fail("No physical connector roads were generated.")

	print(
		"Baghdad landmark map integration passed: 4 registered exploration/venue pins, ",
		road_count, " connector road segments, and the independent Power Tower road anchor."
	)
	quit(0)
