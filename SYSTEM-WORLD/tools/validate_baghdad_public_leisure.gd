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
		var water_shape := water_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if not water_area.monitoring or water_shape == null:
			var child_names: Array[String] = []
			for child in water_area.get_children():
				child_names.append(child.name)
			_fail("Pool water volume is missing active monitoring or collision: %s; monitoring=%s; collision=%s; children=%s" % [pool_name, str(water_area.monitoring), str(water_shape != null), str(child_names)])
			return
			return

	var player := main_scene.find_child("Player", true, false) as CharacterBody3D
	if player == null or not player.is_in_group("system_player"):
		_fail("Canonical main-scene player or system_player group is missing.")
		return
	var lap_water := district.get_node("OlympicLapPool/WaterVolume") as Area3D
	district.call("_on_water_body_entered", player, lap_water)
	if not bool(player.get_meta("system_public_leisure_swimming", false)) or str(player.get_meta("system_public_leisure_water_type", "")) != "lap_pool":
		_fail("Entering a public pool did not set the player's swimming state.")
		return
	district.call("_on_water_body_exited", player, lap_water)
	if player.has_meta("system_public_leisure_swimming"):
		_fail("Leaving the pool did not clear the player's swimming state.")
		return

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

	print("SYSTEM PUBLIC LEISURE QA PASS: integrated in Baghdad public amenities; three monitored pool volumes, canonical player swim-state, 16 lockers, suite-specific release, shower and lifeguard dispatch; independent of the five Baghdad towers.")
	main_scene.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error("SYSTEM PUBLIC LEISURE QA FAIL: " + message)
	quit(1)
