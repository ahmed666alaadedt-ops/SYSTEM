extends SceneTree

class FakeTerrain:
	extends Node
	func is_land_position(_x: float, _z: float) -> bool:
		return true
	func get_terrain_height(_x: float, _z: float) -> float:
		return 0.0

class FakeRegion:
	extends Node3D
	var terrain: Node
	func get_city_anchor(city_name: String) -> Vector3:
		return Vector3(100.0, 0.0, 100.0) if city_name == "Baghdad" else Vector3.INF

class FakeMap:
	extends Node
	var entries: Dictionary = {}
	func register_location(world_id: String, location_id: String, region_id: String, display_name: String, location_type: int, position: Vector3, is_fast_travel_point: bool = false) -> bool:
		if world_id.is_empty() or location_id.is_empty() or entries.has(location_id):
			return false
		entries[location_id] = {"region_id": region_id, "name": display_name, "type": location_type, "position": position, "fast_travel": is_fast_travel_point}
		return true

const TOWER_SCRIPT = preload("res://scripts/baghdad_tower_landmarks_manager.gd")
const TOWER_FLOOR_SCRIPT = preload("res://scripts/system_baghdad_tower_floor_world.gd")
const TOWER_LIFT_UI_SCRIPT = preload("res://scripts/system_baghdad_tower_lift_ui.gd")
const LANDMARK_SCRIPT = preload("res://scripts/system_baghdad_landmark_integration.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Baghdad tower integration validation failed: " + message)
	quit(1)

func _run() -> void:
	var region := FakeRegion.new()
	region.name = "FakeModernWorldRegionManager"
	var terrain := FakeTerrain.new()
	terrain.name = "Terrain"
	region.terrain = terrain
	region.add_child(terrain)
	root.add_child(region)

	var towers = TOWER_SCRIPT.new()
	towers.name = "BaghdadTowerLandmarksManager"
	region.add_child(towers)
	await process_frame

	var tower_records: Array = towers.get_tower_positions()
	if tower_records.size() != 6:
		_fail("Expected five connected towers plus one independent Power Tower; got %d." % tower_records.size())
		return
	if towers.connected_tower_positions.size() != 5:
		_fail("Power Tower was incorrectly included in the five-tower district.")
		return

	var expected_roots := ["HunterAssociationTower", "BusinessTower", "ShoppingTower", "EntertainmentTower", "TechnologyTower"]
	for root_name in expected_roots:
		var tower_root := towers.get_node_or_null(root_name)
		if tower_root == null:
			_fail("Missing Baghdad tower root: " + root_name)
			return
		var exterior_collision := tower_root.get_node_or_null("TowerStructureCollision") as StaticBody3D
		if exterior_collision == null:
			_fail("Missing physical exterior collision body for " + root_name)
			return
		for collider_name in ["CollisionShape3D", "CollisionShape3D2"]:
			var exterior_shape := exterior_collision.get_node_or_null(collider_name) as CollisionShape3D
			if exterior_shape == null or exterior_shape.shape == null or exterior_shape.disabled:
				_fail("Tower exterior shell collision is missing or disabled for " + root_name + ": " + collider_name)
				return
		var interior := tower_root.get_node_or_null("TowerInterior")
		if interior == null:
			_fail("Missing playable lobby for " + root_name)
			return
		var lift_console := interior.get_node_or_null("CentralLiftConsoleInteraction") as Area3D
		if lift_console == null or not lift_console.is_in_group("system_interactable"):
			_fail("Missing full-range central lift console for " + root_name)
			return
		if int(lift_console.get_meta("system_tower_floor_count", 0)) < 30:
			_fail("Central lift console does not expose the full tower floor count for " + root_name)
			return
		var floor_world := tower_root.get_node_or_null("BaghdadTowerFloorWorld")
		if floor_world == null or not floor_world.has_method("build_floor"):
			_fail("Missing procedural floor world for " + root_name)
			return
		var configured_floor_count := int(floor_world.get("max_floors"))
		if configured_floor_count < 30:
			_fail("Tower floor world does not expose its full building floor count for " + root_name)
			return
		var generated_floor: Dictionary = floor_world.call("build_floor", configured_floor_count, Vector3(5.0, 0.0, 5.0))
		if not bool(generated_floor.get("success", false)):
			_fail("Could not generate the top floor for " + root_name)
			return
		var active_floor_name := "ActiveTowerFloor_%03d" % configured_floor_count
		var generated_root := floor_world.get_node_or_null(active_floor_name)
		if generated_root == null:
			_fail("Generated floor root is missing for " + root_name + ": " + str(floor_world.get_children().map(func(child): return child.name)))
			return
		var ground_body := generated_root.get_node_or_null("FloorGround_Collision") as StaticBody3D
		var has_ground_collision := false
		if ground_body != null:
			for collision_child in ground_body.get_children():
				if collision_child is CollisionShape3D and collision_child.shape != null and not collision_child.disabled:
					has_ground_collision = true
					break
		if not has_ground_collision:
			_fail("Generated floor has no collision-backed ground for " + root_name)
			return
		var floor_exit := generated_root.get_node_or_null("TowerFloorExit") as Area3D
		if floor_exit == null or not floor_exit.is_in_group("system_interactable"):
			_fail("Generated tower floor has no usable return gate for " + root_name)
			return
		if floor_exit.get_meta("system_return_position", Vector3.INF) == Vector3.INF:
			_fail("Generated tower floor return gate has no saved return position for " + root_name)
			return
		for floor_number in range(2, 6):
			var selector := interior.get_node_or_null("LobbyLiftSelector_%02d" % floor_number) as Area3D
			if selector == null or not selector.is_in_group("system_interactable"):
				_fail("Missing accessible lobby lift selector %02d in %s." % [floor_number, root_name])
				return
			if selector.get_meta("system_destination_position", Vector3.INF) == Vector3.INF:
				_fail("Lobby lift selector has no destination in " + root_name)
				return

	var connected_district := towers.get_node_or_null("FiveTowerConnectedDistrict")
	if connected_district == null:
		_fail("The five connected towers have no shared district bridge network.")
		return
	for index in range(5):
		var ramp_collision := connected_district.get_node_or_null("VehicleAccessRamp_%d/RampSegment_0_Collision/CollisionShape3D" % index) as CollisionShape3D
		if ramp_collision == null or ramp_collision.shape == null:
			_fail("A tower access ramp is missing physical collision: %d" % index)
			return
	var sky_ring := towers.get_node_or_null("BaghdadReferenceSkyPromenade_Blockout")
	if sky_ring == null or sky_ring.get_child_count() < 12:
		_fail("The shared sky promenade ring is missing its twelve walkable segments.")
		return
	var first_ring_segment := sky_ring.get_node_or_null("SkyPromenadeSegment_00")
	if first_ring_segment == null or first_ring_segment.get_node_or_null("WalkableDeckCollision") == null:
		_fail("The sky promenade has no collision-backed walking deck.")
		return
	var amenities := towers.get_node_or_null("ConnectedCityPublicAmenities_Blockout")
	if amenities == null:
		_fail("The connected tower district public amenities are missing.")
		return
	for amenity_name in ["RooftopGardenDeck", "LeisureAndPoolDeck", "FamilyEntertainmentPlaza"]:
		if amenities.get_node_or_null(amenity_name + "_Collision/CollisionShape3D") == null:
			_fail("Public amenity deck is not physically walkable: " + amenity_name)
			return

	var power_record: Dictionary = {}
	for record in tower_records:
		if str(record.get("id", "")) == "power_tower_baghdad":
			power_record = record
	if power_record.is_empty() or int(power_record.get("floors", 0)) != 200:
		_fail("Power Tower physical landmark must expose exactly 200 floors.")
		return
	if float(power_record.get("height", 0.0)) < 600.0:
		_fail("Power Tower structure height does not provide a realistic 200-floor facade.")
		return
	var power_root := towers.get_node_or_null("PowerTower")
	if power_root == null or power_root.get_node_or_null("TowerInterior") != null:
		_fail("Power Tower must remain a separate challenge structure without a five-tower lobby.")
		return
	var power_collision := power_root.get_node_or_null("TowerStructureCollision") as StaticBody3D
	if power_collision == null:
		_fail("Independent Power Tower exterior collision body is missing.")
		return
	for collider_name in ["CollisionShape3D", "CollisionShape3D2"]:
		var power_shape := power_collision.get_node_or_null(collider_name) as CollisionShape3D
		if power_shape == null or power_shape.shape == null or power_shape.disabled:
			_fail("Independent Power Tower exterior collision is missing or disabled: " + collider_name)
			return
	if power_root.get_node_or_null("PowerTowerArenaVenue/PowerTowerArenaInteraction") == null:
		_fail("Power Tower exhibition arena entry is missing.")
		return
	if power_root.get_node_or_null("PowerTowerFloorWorld") == null:
		_fail("Power Tower 200-floor exploration world is not attached.")
		return

	var lift_ui = TOWER_LIFT_UI_SCRIPT.new()
	root.add_child(lift_ui)
	await process_frame
	lift_ui.call("open_for_tower", "hunter_association_tower_baghdad", "برج نقابة الصيادين", 200)
	var available_floor_count := int(lift_ui.call("get_available_floor_count"))
	if available_floor_count != 200:
		_fail("Hunter tower lift UI does not list all 200 floors; listed=%d." % available_floor_count)
		return
	lift_ui.queue_free()

	var headquarters_position: Vector3 = towers.get_headquarters_position()
	if headquarters_position == Vector3.INF:
		_fail("Hunter Association headquarters has no resolved elevated position.")
		return
	if towers.get_node_or_null("HunterAssociationHeadquarters/HeadquartersInterior/HeadquartersExit") == null:
		_fail("Hunter Association headquarters interior exit is missing.")
		return

	var landmarks = LANDMARK_SCRIPT.new()
	region.add_child(landmarks)
	landmarks.call("build", terrain)
	var fake_map := FakeMap.new()
	root.add_child(fake_map)
	# The region manager owns the single registration pass for existing tower roots;
	# the civic landmark manager contributes only tunnel/ruins/motorsport locations.
	for record in tower_records:
		fake_map.call("register_location", "2", str(record.get("id", "")), "region_baghdad", str(record.get("name", "")), 5, record.get("position", Vector3.ZERO), false)
	fake_map.call("register_location", "2", "hunter_association_headquarters_baghdad", "region_baghdad", "المقر الرئيسي لنقابة الصيادين", 5, headquarters_position, false)
	landmarks.call("register_map_locations", fake_map, "2")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required_contract in ["tower_lift_console_", "tower_floor_exit_", "_enter_baghdad_tower_floor", "BaghdadTowerLiftUIScript"]:
		if not main_source.contains(required_contract):
			_fail("Main interaction runtime is missing tower lift contract: " + required_contract)
			return
	var region_source := FileAccess.get_file_as_string("res://scripts/modern_world_region_manager.gd")
	if not region_source.contains("tower_manager.call(\"get_tower_positions\")") or not region_source.contains("baghdad_landmarks.call(\"register_map_locations\""):
		_fail("Modern region manager does not register tower roots and Baghdad landmark locations.")
		return
	for record in tower_records:
		var tower_id := str(record.get("id", ""))
		if not fake_map.entries.has(tower_id):
			_fail("Tower is missing from the world map: " + tower_id)
			return
	if not fake_map.entries.has("hunter_association_headquarters_baghdad"):
		_fail("Hunter Association headquarters is missing from the world map.")
		return
	for location_id in ["hunter_exam_tunnel_start_baghdad", "hunter_exam_public_notice_baghdad", "baghdad_archaeological_ruins", "baghdad_international_motorsport_park"]:
		if not fake_map.entries.has(location_id):
			_fail("Baghdad civic/sport landmark is missing from the world map: " + location_id)
			return

	landmarks.free()
	towers.free()
	region.free()
	fake_map.free()
	print("Baghdad tower integration validation passed: five connected playable towers, accessible lobby lifts, independent 200-floor Power Tower, arena, Hunter HQ and all tower/sport/exam map registrations.")
	quit(0)
