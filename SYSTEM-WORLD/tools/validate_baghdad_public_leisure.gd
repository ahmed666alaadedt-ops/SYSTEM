extends SceneTree


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load("res://MainScene.tscn") as PackedScene
	if packed_scene == null:
		_fail("MainScene.tscn could not be loaded.")
		return
	var main_scene := packed_scene.instantiate() as Node3D
	if main_scene == null:
		_fail("MainScene.tscn did not instantiate as Node3D.")
		return
	root.add_child(main_scene)
	for frame_index in range(14):
		await process_frame

	var region := main_scene.find_child("ModernWorldRegionManager", true, false) as Node3D
	var tower_manager := region.get_node_or_null("BaghdadTowerLandmarksManager") as Node3D if region != null else null
	var amenities := tower_manager.get_node_or_null("ConnectedCityPublicAmenities_Blockout") as Node3D if tower_manager != null else null
	var district := amenities.get_node_or_null("BaghdadPublicLeisureDistrict") as Node3D if amenities != null else null
	if district == null:
		_fail("Independent public leisure manager is not attached to Baghdad's runtime public amenities.")
		return
	if not bool(district.get_meta("system_public_leisure_runtime_ready", false)):
		_fail("Independent Baghdad public leisure manager did not initialize.")
		return
	if bool(district.get_meta("system_public_leisure_is_tower", true)):
		_fail("Public leisure district must not be registered as a sixth tower.")
		return

	var rooftop_deck := amenities.get_node_or_null("RooftopGardenDeck") as MeshInstance3D
	var garden := rooftop_deck.get_node_or_null("BaghdadRooftopGarden") as Node3D if rooftop_deck != null else null
	if garden == null or not bool(garden.get_meta("system_public_garden_runtime_ready", false)):
		_fail("The independent Baghdad rooftop garden did not initialize on its public amenity deck.")
		return
	if bool(garden.get_meta("system_public_garden_is_tower", true)):
		_fail("The rooftop garden must remain an independent public facility, not a sixth Baghdad tower.")
		return
	if garden.get_node_or_null("GardenGroundCollision/GardenWalkableSurface") == null:
		_fail("The rooftop garden is missing its walkable ground collision.")
		return
	for expected_group in [{"prefix":"GardenTree_","count":8},{"prefix":"GardenBench_","count":8},{"prefix":"GardenFlowerbed_","count":6},{"prefix":"GardenLamp_","count":6}]:
		var found := 0
		for child in garden.get_children():
			if child.name.begins_with(str(expected_group["prefix"])):
				found += 1
		if found != int(expected_group["count"]):
			_fail("Rooftop garden expected %d %s elements; found %d." % [int(expected_group["count"]), str(expected_group["prefix"]), found])
			return
	for path_name in ["GardenCentralWalkway","GardenCrossWalkway","GardenNorthPromenade","GardenSouthPromenade"]:
		if garden.get_node_or_null(path_name) == null:
			_fail("The rooftop garden is missing a continuous pedestrian route: " + path_name)
			return
	if int(district.get_meta("system_public_leisure_water_volume_count", 0)) != 3:
		_fail("Expected three active public pool water volumes.")
		return
	if int(district.get_meta("system_public_leisure_locker_count", 0)) != 16:
		_fail("Expected sixteen public pool lockers across the two changing suites.")
		return
	var access_ramp := district.get_node_or_null("PublicLeisureGroundAccessRamp") as Node3D
	if access_ramp == null or not bool(access_ramp.get_meta("system_public_leisure_ground_access", false)) or int(access_ramp.get_meta("system_public_leisure_access_ramp_segments", 0)) != 8:
		_fail("Public leisure district is missing its eight-segment physical ground access ramp.")
		return
	if access_ramp.get_node_or_null("PublicLeisureGroundArrival/GroundArrivalPlazaCollision") == null:
		_fail("Public leisure ramp does not terminate at a collidable ground arrival plaza.")
		return
	for segment_index in range(8):
		if access_ramp.get_node_or_null("AccessRampCollision_%02d" % segment_index) == null:
			_fail("Public leisure access ramp segment has no physical collision: %d" % segment_index)
			return

	for pool_name in ["OlympicLapPool", "FamilyLeisurePool", "ThermalPool"]:
		var water_area := district.get_node_or_null(NodePath(pool_name + "/WaterVolume")) as Area3D
		if water_area == null:
			_fail("Pool water volume node is missing: " + pool_name)
			return
		var water_shape_found := false
		var child_names: Array[String] = []
		for child in water_area.get_children():
			child_names.append(child.name)
			if child is CollisionShape3D:
				water_shape_found = true
		if not water_area.monitoring or not water_shape_found:
			_fail("Pool water volume is missing active monitoring or a CollisionShape3D child: %s; monitoring=%s; collision=%s; children=%s" % [pool_name, str(water_area.monitoring), str(water_shape_found), str(child_names)])
			return
		if str(water_area.get_meta("system_activity_category", "")) != "leisure":
			_fail("Public pool must be categorized as leisure/recreation, not a sports competition: " + pool_name)
			return

	var player := main_scene.find_child("Player", true, false) as CharacterBody3D
	if player == null or not player.is_in_group("system_player"):
		_fail("Canonical main-scene player or system_player group is missing.")
		return
	# Exercise real Area3D/body overlap signals rather than calling the callbacks directly.
	var original_player_position := player.global_position
	var original_physics_processing := player.is_physics_processing()
	player.set_physics_process(false)
	var overlap_test_center := district.global_position + Vector3(500.0, 12.0, 500.0)
	player.global_position = overlap_test_center
	var lap_test_water := _create_overlap_test_water_area(district, "OverlapLapWaterTest", overlap_test_center, Vector3(8.0, 4.0, 8.0), "lap_pool", player.collision_layer)
	var family_test_water := _create_overlap_test_water_area(district, "OverlapFamilyWaterTest", overlap_test_center + Vector3(-1.5, 0.0, 0.0), Vector3(4.0, 4.0, 4.0), "family_pool", player.collision_layer)
	for frame_index in range(3):
		await physics_frame
	var entered_zones: Dictionary = player.get_meta("system_public_leisure_water_zones", {})
	if entered_zones.size() != 2 or not entered_zones.has(str(lap_test_water.get_instance_id())) or not entered_zones.has(str(family_test_water.get_instance_id())):
		_fail("Real physics overlap did not register both water Area3D volumes for the player.")
		return
	if not bool(player.get_meta("system_swimming", false)) or not player.has_meta("system_swim_surface_y"):
		_fail("Public leisure pool entry did not activate the canonical player swimming locomotion state.")
		return
	# Move out of the smaller family volume while remaining inside the larger lap volume.
	player.global_position = overlap_test_center + Vector3(2.5, 0.0, 0.0)
	for frame_index in range(3):
		await physics_frame
	var remaining_zones: Dictionary = player.get_meta("system_public_leisure_water_zones", {})
	if remaining_zones.size() != 1 or not remaining_zones.has(str(lap_test_water.get_instance_id())):
		_fail("Leaving one physically overlapping water volume did not preserve exactly the remaining lap-pool zone.")
		return
	if not bool(player.get_meta("system_public_leisure_swimming", false)) or str(player.get_meta("system_public_leisure_water_type", "")) != "lap_pool":
		_fail("The player lost the swimming state after physically exiting only one overlapping water volume.")
		return
	if not bool(player.get_meta("system_swimming", false)) or absf(float(player.get_meta("system_swim_surface_y", -999.0)) - (lap_test_water.global_position.y + 0.54)) > 0.01:
		_fail("Leaving one overlapping zone did not preserve the canonical swim controller or remaining pool surface height.")
		return
	player.global_position = overlap_test_center + Vector3(9.0, 0.0, 0.0)
	for frame_index in range(3):
		await physics_frame
	if player.has_meta("system_public_leisure_swimming") or player.has_meta("system_public_leisure_water_zones"):
		_fail("Leaving the final physical water volume did not clear all swimming state.")
		return
	if bool(player.get_meta("system_swimming", false)) or player.has_meta("system_swim_surface_y") or player.has_meta("system_swim_source"):
		_fail("Leaving the final public pool volume did not clear the canonical player locomotion swimming state.")
		return
	lap_test_water.queue_free()
	family_test_water.queue_free()
	player.global_position = original_player_position
	player.set_physics_process(original_physics_processing)
	for frame_index in range(2):
		await physics_frame

	var locker := district.get_node("WomensChangingSuite/Locker_00") as MeshInstance3D
	locker.set_meta("system_pool_locker_occupied", true)
	locker.set_meta("system_pool_locker_owner", 9917)
	if not bool(district.call("release_locker", "WomensChangingSuite", "Locker_00", 9917)):
		_fail("The public leisure manager could not release a locker from the selected changing suite.")
		return
	if bool(locker.get_meta("system_pool_locker_occupied", true)):
		_fail("Released public pool locker remains occupied.")
		return

	var lifeguard_service := district.get_node_or_null("PoolLifeguardStation/PoolLifeguardServiceInteraction") as Area3D
	if lifeguard_service == null or not lifeguard_service.is_in_group("system_interactable") or str(lifeguard_service.get_meta("system_pool_service_type", "")) != "lifeguard":
		_fail("Public lifeguard service interaction is missing.")
		return
	if str(lifeguard_service.get_meta("system_tower_id", "")) != "public_leisure_district":
		_fail("Public leisure service is incorrectly attributed to a tower.")
		return
	if not bool(district.call("dispatch_lifeguard_to", player)):
		_fail("Public lifeguard could not accept a player assistance request.")
		return
	if not bool(district.get_node("PoolLifeguardStation/PublicLifeguardNPC").get_meta("system_lifeguard_assistance_requested", false)):
		_fail("Lifeguard assistance request was not recorded.")
		return

	for suite_name in ["MensChangingSuite", "WomensChangingSuite"]:
		var suite := district.get_node_or_null(suite_name) as Node3D
		var suite_locker_count := 0
		if suite != null:
			for child in suite.get_children():
				if child is MeshInstance3D and child.name.begins_with("Locker_"):
					suite_locker_count += 1
		if suite_locker_count != 8:
			_fail("Each public changing suite must expose eight individually reservable lockers: " + suite_name)
			return
		for service_name in ["PoolLockerServiceInteraction", "PoolShowerServiceInteraction"]:
			var service := district.get_node_or_null(NodePath(suite_name + "/" + service_name)) as Area3D
			if service == null or not service.is_in_group("system_interactable"):
				_fail("Public changing suite service interaction is missing: " + suite_name + "/" + service_name)
				return

	print("SYSTEM PUBLIC LEISURE QA PASS: integrated in Baghdad public amenities; three monitored pool volumes, canonical player swim-state, 16 lockers, suite-specific release, shower and lifeguard dispatch; walkable rooftop garden with trees, benches, flowerbeds and lighting; all public facilities independent of the five Baghdad towers.")
	main_scene.queue_free()
	quit(0)



func _create_overlap_test_water_area(parent: Node3D, area_name: String, center: Vector3, volume_size: Vector3, water_type: String, body_collision_layer: int) -> Area3D:
	var area := Area3D.new()
	area.name = area_name
	area.collision_layer = 0
	area.collision_mask = body_collision_layer
	area.monitoring = true
	area.set_meta("system_public_leisure_water_type", water_type)
	area.set_meta("system_public_leisure_water_depth", 1.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = volume_size
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(Callable(parent, "_on_water_body_entered").bind(area))
	area.body_exited.connect(Callable(parent, "_on_water_body_exited").bind(area))
	parent.add_child(area)
	area.global_position = center
	return area


func _fail(message: String) -> void:
	push_error("SYSTEM PUBLIC LEISURE QA FAIL: " + message)
	quit(1)
