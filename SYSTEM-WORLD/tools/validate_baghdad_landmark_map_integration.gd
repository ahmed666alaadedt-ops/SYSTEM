extends SceneTree


func _initialize() -> void:
	call_deferred("_run_validation")


func _fail(message: String) -> void:
	push_error("Baghdad landmark map integration validation failed: " + message)
	quit(1)


func _run_validation() -> void:
	var main_scene := load("res://MainScene.tscn") as PackedScene
	if main_scene == null:
		_fail("Main scene resource could not be loaded.")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var map_manager: Node = main.get("world_map_manager")
	var world_manager: Node = main.get("world_manager")
	if map_manager == null or world_manager == null:
		_fail("Main scene did not initialize the world and map managers.")
		return

	var modern_root: Node = world_manager.call("get_world_root", 2)
	if modern_root == null:
		_fail("Modern world root is missing.")
		return
	var region: Node = modern_root.get_node_or_null("ModernWorldRegionManager")
	if region == null:
		_fail("ModernWorldRegionManager is missing.")
		return

	var locations_by_world: Dictionary = map_manager.get("locations_by_world")
	var locations: Dictionary = locations_by_world.get("2", {})
	if locations.is_empty():
		_fail("No modern-world map locations were registered.")
		return

	var services: Node = region.get_node_or_null("ModernCityServicesManager")
	if services == null or not services.has_method("get_service_locations"):
		_fail("City services manager is unavailable.")
		return
	var baghdad_service_count := 0
	for service in services.call("get_service_locations"):
		if str(service.get("city", "")) != "Baghdad":
			continue
		baghdad_service_count += 1
		var service_id := str(service.get("id", ""))
		if not locations.has(service_id):
			_fail("Baghdad service is not linked to the map: " + service_id)
			return

	var tower_manager: Node = region.get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager == null or not tower_manager.has_method("get_tower_positions"):
		_fail("Baghdad tower landmark manager is unavailable.")
		return
	var tower_records: Array = tower_manager.call("get_tower_positions")
	var connected_towers: Array = tower_manager.get("connected_tower_positions")
	var power_tower_found := false
	for tower in tower_records:
		var tower_id := str(tower.get("id", ""))
		if not locations.has(tower_id):
			_fail("Tower is not linked to the map: " + tower_id)
			return
		if tower_id == "power_tower_baghdad":
			power_tower_found = true
	if not power_tower_found:
		_fail("Independent Power Tower is missing from tower records.")
		return
	if connected_towers.size() != 5:
		_fail("The Baghdad tower district must contain exactly five connected towers.")
		return
	for tower in connected_towers:
		if str(tower.get("id", "")) == "power_tower_baghdad":
			_fail("Power Tower was incorrectly included in the five-tower district.")
			return

	for required_id in [
		"city_baghdad",
		"hunter_association_headquarters_baghdad",
		"hunter_exam_tunnel_start_baghdad",
		"hunter_exam_public_notice_baghdad",
		"baghdad_archaeological_ruins",
		"baghdad_international_motorsport_park"
	]:
		if not locations.has(required_id):
			_fail("Required Baghdad landmark map pin is missing: " + required_id)
			return

	var advertisements: Array = map_manager.call("get_advertisements", "2")
	var baghdad_ad_count := 0
	for advertisement in advertisements:
		if str(advertisement.get("city", "")) == "Baghdad":
			baghdad_ad_count += 1
	if baghdad_ad_count < 3:
		_fail("Expected at least three active Baghdad street-advertisement map records.")

	print(
		"Baghdad landmark map integration passed: ",
		baghdad_service_count, " civic/activity services, ",
		tower_records.size(), " tower pins with a separate 200-floor Power Tower, ",
		baghdad_ad_count, " Baghdad advertising records, and all required exploration landmarks."
	)
	main.queue_free()
	quit(0)
