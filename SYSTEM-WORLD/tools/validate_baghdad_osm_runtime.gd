extends SceneTree

const BAGHDAD_STREAMER = preload("res://scripts/baghdad_osm_cell_streamer.gd")
const CITY_STATE_STORE = preload("res://scripts/baghdad_city_state_store.gd")
const CITY_NAVIGATION = preload("res://scripts/npc_city_navigation_manager.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var streamer = BAGHDAD_STREAMER.new()
	root.add_child(streamer)
	print("Baghdad OSM validation: streamer added; checking manifest and origin.")
	if not streamer.enabled:
		_fail("Baghdad OSM cell pack did not enable.")
		return
	var streaming_status: Dictionary = streamer.get_streaming_status()
	if not streaming_status.get("canonical_origin_frame_valid", false):
		_fail("OSM cell coordinates do not match the canonical WGS84 origin.")
		return
	if int(streaming_status.get("manifest_schema_version", 0)) != 1:
		_fail("Baghdad OSM manifest schema version was not validated.")
		return
	if streamer.get_node_or_null("BaghdadOSMAttribution/OpenStreetMapCredit") == null:
		_fail("Required OSM attribution overlay is missing.")
		return

	print("Baghdad OSM validation: manifest/origin accepted; loading center cell.")
	streamer._load_cell(Vector2i(0, 0))
	if not streamer.loaded_cells.has(Vector2i(0, 0)):
		_fail("Baghdad center cell did not load.")
		return
	var cell_root: Node3D = streamer.loaded_cells[Vector2i(0, 0)]
	if str(cell_root.get_meta("region_id", "")) != "iraq_baghdad_region":
		_fail("Loaded cell does not expose its canonical region ID.")
		return
	if int(cell_root.get_meta("cell_x", 999)) != 0 or int(cell_root.get_meta("cell_z", 999)) != 0:
		_fail("Loaded cell identity does not match the requested cell coordinates.")
		return
	print("Baghdad OSM validation: center cell loaded; checking generated scene nodes.")
	var roads := cell_root.find_children("OSMRoad_*", "MeshInstance3D", true, false)
	var buildings := cell_root.find_children("OSMBuilding_*", "MeshInstance3D", true, false)
	var landuse := cell_root.find_children("OSMLanduse_*", "MeshInstance3D", true, false)
	if roads.is_empty():
		_fail("Baghdad OSM center cell has no generated road meshes.")
		return
	if buildings.is_empty():
		_fail("Baghdad OSM center cell has no generated building meshes.")
		return
	if landuse.is_empty():
		_fail("Baghdad OSM center cell has no generated land-use meshes.")
		return
	var building_collisions := cell_root.find_children("OSMBuildingCollision_*", "StaticBody3D", true, false)
	if building_collisions.is_empty():
		_fail("Baghdad OSM building collision bodies were not created.")
		return

	var road_segments_value: Variant = cell_root.get_meta("road_navigation_segments", [])
	if not road_segments_value is Array or road_segments_value.is_empty():
		_fail("Baghdad OSM center cell did not retain pedestrian-accessible road geometry.")
		return
	var exported_road_segments: Array[Dictionary] = streamer.get_loaded_road_map_segments()
	if exported_road_segments.is_empty():
		_fail("Baghdad map UI road-geometry API returned no loaded OSM roads.")
		return
	var exported_points: Variant = exported_road_segments[0].get("points", PackedVector2Array())
	if not exported_points is PackedVector2Array or exported_points.size() < 2:
		_fail("Baghdad map UI road-geometry API returned an unusable road segment.")
		return
	var first_road_segment: Dictionary = road_segments_value[0]
	var first_road_points: Variant = first_road_segment.get("points", PackedVector2Array())
	if not first_road_points is PackedVector2Array or first_road_points.size() < 2:
		_fail("Baghdad OSM road navigation segment has no usable path vertices.")
		return
	var road_start: Vector2 = first_road_points[0]
	var road_end: Vector2 = first_road_points[first_road_points.size() - 1]
	var osm_route: Array[Vector3] = streamer.get_road_navigation_path(
		Vector3(road_start.x, 0.0, road_start.y),
		Vector3(road_end.x, 0.0, road_end.y)
	)
	if osm_route.size() < 2:
		_fail("Real OSM road graph did not return a route along the selected road feature.")
		return
	var navigation_manager = CITY_NAVIGATION.new()
	navigation_manager.osm_streamer = streamer
	var integrated_route: Array[Vector3] = navigation_manager.find_pedestrian_path(
		"Baghdad",
		Vector3(road_start.x, 0.0, road_start.y),
		Vector3(road_end.x, 0.0, road_end.y)
	)
	if integrated_route.size() < 2 or int(navigation_manager.get_navigation_status().get("real_osm_routes_found", 0)) != 1:
		_fail("Baghdad pedestrian navigation did not consume the real OSM road graph.")
		return
	var strict_player_route: Array[Vector3] = navigation_manager.find_real_baghdad_road_path(
		"Baghdad",
		Vector3(road_start.x, 0.0, road_start.y),
		Vector3(road_end.x, 0.0, road_end.y)
	)
	if strict_player_route.size() < 2:
		_fail("Player-facing Baghdad route API did not return a real OSM road path.")
		return
	if int(navigation_manager.get_navigation_status().get("real_osm_routes_found", 0)) != 2:
		_fail("Player-facing route API did not record its real OSM route.")
		return
	var non_baghdad_route: Array[Vector3] = navigation_manager.find_real_baghdad_road_path(
		"Tokyo",
		Vector3(road_start.x, 0.0, road_start.y),
		Vector3(road_end.x, 0.0, road_end.y)
	)
	if not non_baghdad_route.is_empty():
		_fail("Baghdad OSM route API incorrectly returned a route for a different city.")
		return
	navigation_manager.free()
	print("Baghdad OSM player routing and map road export passed: road_nodes=", streamer.get_streaming_status().get("road_navigation_node_count", 0), " route_points=", strict_player_route.size(), " map_road_segments=", exported_road_segments.size())

	# Exercise persistence against a real OSM-generated building ID, not a test-only ID.
	var city_state_store = CITY_STATE_STORE.new()
	city_state_store.save_path = "user://baghdad_osm_real_feature_state_test.json"
	root.add_child(city_state_store)
	city_state_store.restore_cell(Vector2i(0, 0), cell_root)
	var persistent_building: StaticBody3D
	for candidate in building_collisions:
		if candidate.has_meta("system_location_id") and not str(candidate.get_meta("system_location_id", "")).is_empty():
			persistent_building = candidate
			break
	if persistent_building == null:
		_fail("OSM building collision has no stable SYSTEM location ID for persistence.")
		return
	var persistent_id := str(persistent_building.get_meta("system_location_id"))
	persistent_building.set_meta("system_persistent_state", {
		"door_open": true,
		"test_marker": "real_osm_feature_round_trip"
	})
	streamer.cell_loaded.connect(Callable(city_state_store, "restore_cell"))
	streamer.cell_unloading.connect(Callable(city_state_store, "capture_cell"))

	print("Baghdad OSM runtime cell passed: roads=", roads.size(), " buildings=", buildings.size(), " landuse=", landuse.size(), " building_collisions=", building_collisions.size())
	streamer._unload_cell(Vector2i(0, 0))
	if streamer.loaded_cells.has(Vector2i(0, 0)):
		_fail("Baghdad cell was not removed from the loaded-cell registry.")
		return
	streamer._load_cell(Vector2i(0, 0))
	if not streamer.loaded_cells.has(Vector2i(0, 0)):
		_fail("Baghdad cell could not be loaded again after unload.")
		return
	var reloaded_cell: Node3D = streamer.get_cell_node(Vector2i(0, 0))
	if reloaded_cell == null or str(reloaded_cell.get_meta("cell_id", "")) != "0:0":
		_fail("Reloaded Baghdad cell lost its stable cell identity.")
		return
	var restored_buildings := reloaded_cell.find_children("OSMBuildingCollision_*", "StaticBody3D", true, false)
	var restored_feature_found := false
	for candidate in restored_buildings:
		if str(candidate.get_meta("system_location_id", "")) == persistent_id:
			var restored_state: Variant = candidate.get_meta("system_persistent_state", {})
			if typeof(restored_state) == TYPE_DICTIONARY and bool(restored_state.get("door_open", false)) and str(restored_state.get("test_marker", "")) == "real_osm_feature_round_trip":
				restored_feature_found = true
				break
	if not restored_feature_found:
		_fail("Real OSM building state did not survive streamer unload/reload.")
		return
	city_state_store.queue_free()
	if FileAccess.file_exists("user://baghdad_osm_real_feature_state_test.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://baghdad_osm_real_feature_state_test.json"))

	# A queued load that is no longer desired must not recreate an old cell.
	streamer._unload_cell(Vector2i(0, 0))
	streamer.desired_cells.clear()
	streamer.pending_loads.clear()
	streamer.pending_unloads.clear()
	streamer.pending_loads.append(Vector2i(0, 0))
	streamer._process_cell_queue()
	if streamer.loaded_cells.has(Vector2i(0, 0)):
		_fail("A stale Baghdad load request recreated a cell outside the desired set.")
		return

	# A queued unload must not remove a cell that has become desired again.
	var retained_cell := Node3D.new()
	retained_cell.name = "BaghdadStaleQueueGuardTestCell"
	streamer.add_child(retained_cell)
	streamer.loaded_cells[Vector2i(9, 9)] = retained_cell
	streamer.desired_cells[Vector2i(9, 9)] = true
	streamer.pending_unloads.clear()
	streamer.pending_unloads.append(Vector2i(9, 9))
	streamer._process_cell_queue()
	if not streamer.loaded_cells.has(Vector2i(9, 9)):
		_fail("A stale Baghdad unload request removed a cell that is still desired.")
		return
	streamer._unload_cell(Vector2i(9, 9))
	streamer.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
