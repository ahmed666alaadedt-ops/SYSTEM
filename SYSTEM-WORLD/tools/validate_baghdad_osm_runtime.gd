extends SceneTree

const BAGHDAD_STREAMER = preload("res://scripts/baghdad_osm_cell_streamer.gd")
const CITY_STATE_STORE = preload("res://scripts/baghdad_city_state_store.gd")
const CITY_NAVIGATION = preload("res://scripts/npc_city_navigation_manager.gd")
const NPC_VEHICLE_SCRIPT = preload("res://scripts/system_npc_vehicle.gd")
const CITY_TRAFFIC_SCRIPT = preload("res://scripts/modern_city_traffic_manager.gd")


class MockVehicleRoadStreamer:
	extends Node
	var enabled := true
	var loaded_cells: Dictionary = {}
	var route_ready := true
	func get_vehicle_navigation_path(start: Vector3, target: Vector3, _max_snap_distance: float = 70.0) -> Array[Vector3]:
		if not route_ready:
			return []
		return [start, (start + target) * 0.5, target]


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
	var cell_feature_counts: Dictionary = cell_root.get_meta("feature_counts", {})
	if not cell_feature_counts.has("historic-sites"):
		_fail("Baghdad OSM cell did not report its dedicated historic-sites layer.")
		return
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

	var archaeological_feature := {
		"id": "validator_archaeological_site",
		"tags": {"historic": "archaeological_site", "name:ar": "موقع أثري اختباري"},
		"geometry": {"type": "Point", "coordinates": [60.0, 60.0]}
	}
	var archaeological_count: int = streamer.call("_build_historic_site_feature", cell_root, archaeological_feature)
	if archaeological_count != 1:
		_fail("An OSM-tagged archaeological site was not converted into a physical landmark.")
		return
	var archaeological_root := cell_root.get_node_or_null("OSMArchaeologicalSite_validator_archaeological_site")
	if archaeological_root == null:
		_fail("The archaeological site landmark root is missing.")
		return
	var archaeological_interaction := archaeological_root.get_node_or_null("ArchaeologicalSiteInteraction")
	if archaeological_interaction == null or not archaeological_interaction.is_in_group("system_interactable"):
		_fail("The archaeological site is missing its discoverable interaction area.")
		return
	if str(archaeological_interaction.get_meta("system_location_id", "")).is_empty():
		_fail("The archaeological site has no stable map/discovery location ID.")
		return

	var archaeological_area_feature := {
		"id": "validator_archaeological_polygon",
		"tags": {"historic": "ruins", "name:ar": "أطلال أثرية اختبارية"},
		"geometry": {
			"type": "Polygon",
			"coordinates": [[[40.0, 40.0], [80.0, 40.0], [80.0, 80.0], [40.0, 80.0], [40.0, 40.0]]]
		}
	}
	var archaeological_area_count: int = streamer.call("_build_amenity_feature", cell_root, archaeological_area_feature)
	if archaeological_area_count != 1:
		_fail("An OSM archaeological polygon was not converted into a ruin landmark.")
		return
	var archaeological_area_root := cell_root.get_node_or_null("OSMArchaeologicalSiteArea_validator_archaeological_polygon_0")
	if archaeological_area_root == null:
		_fail("The archaeological polygon has no physical ruin detail root.")
		return
	if archaeological_area_root.get_node_or_null("ArchaeologicalSiteInteraction") == null:
		_fail("The archaeological polygon is missing its stable discovery interaction.")
		return

	var memorial_feature := {
		"id": "validator_memorial",
		"tags": {"historic": "memorial", "name:ar": "نصب تذكاري اختباري"},
		"geometry": {"type": "Point", "coordinates": [90.0, 90.0]}
	}
	var memorial_count: int = streamer.call("_build_historic_site_feature", cell_root, memorial_feature)
	if memorial_count != 1:
		_fail("An OSM memorial feature was not recognized as a historic landmark.")
		return
	var memorial_root := cell_root.get_node_or_null("OSMArchaeologicalSite_validator_memorial")
	if memorial_root == null or memorial_root.get_node_or_null("MonumentPedestal") == null:
		_fail("An OSM memorial did not receive its monument-specific physical style.")
		return

	var kadhimiya_feature := {
		"id": "validator_kadhimiya_shrine",
		"tags": {"historic": "tomb", "name:en": "Kadhimain Shrine"},
		"geometry": {"type": "Point", "coordinates": [100.0, 100.0]}
	}
	var kadhimiya_count: int = streamer.call("_build_historic_site_feature", cell_root, kadhimiya_feature)
	if kadhimiya_count != 0:
		_fail("A Kadhimiya historic feature entered the current Baghdad landmark scope.")
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

	var vehicle_segments: Array[Dictionary] = streamer.get_loaded_vehicle_map_segments()
	if vehicle_segments.is_empty():
		_fail("Baghdad OSM center cell has no motor-vehicle-accessible road segments.")
		return
	var selected_vehicle_segment: Dictionary = {}
	for candidate_segment in vehicle_segments:
		var candidate_points: Variant = candidate_segment.get("points", PackedVector2Array())
		if candidate_points is PackedVector2Array and candidate_points.size() >= 2:
			if candidate_points[0].distance_to(candidate_points[candidate_points.size() - 1]) > 15.0:
				selected_vehicle_segment = candidate_segment
				break
	if selected_vehicle_segment.is_empty():
		_fail("Baghdad OSM vehicle graph has no usable road segment longer than 15 metres.")
		return
	var vehicle_points: PackedVector2Array = selected_vehicle_segment["points"]
	var vehicle_start: Vector2 = vehicle_points[0]
	var vehicle_end: Vector2 = vehicle_points[vehicle_points.size() - 1]
	if str(selected_vehicle_segment.get("oneway", "no")) == "-1":
		var swap_point := vehicle_start
		vehicle_start = vehicle_end
		vehicle_end = swap_point
	var vehicle_route: Array[Vector3] = streamer.get_vehicle_navigation_path(
		Vector3(vehicle_start.x, 0.0, vehicle_start.y),
		Vector3(vehicle_end.x, 0.0, vehicle_end.y),
		8.0
	)
	if vehicle_route.size() < 2:
		_fail("Real OSM motor-vehicle graph did not return a route along a permitted road direction.")
		return

	var direction_test_streamer = BAGHDAD_STREAMER.new()
	direction_test_streamer.enabled = true
	var direction_test_cell := Node3D.new()
	var one_way_points := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(20.0, 0.0), Vector2(40.0, 0.0)
	])
	direction_test_cell.set_meta("vehicle_navigation_segments", [
		{"oneway": "yes", "points": one_way_points}
	])
	direction_test_streamer.loaded_cells[Vector2i.ZERO] = direction_test_cell
	if not direction_test_streamer._is_vehicle_road({"highway": "residential"}):
		_fail("Residential roads were incorrectly excluded from motor traffic.")
		return
	if direction_test_streamer._is_vehicle_road({"highway": "footway"}) or direction_test_streamer._is_vehicle_road({"highway": "service", "access": "private"}) or direction_test_streamer._is_vehicle_road({"highway": "primary", "motor_vehicle": "no"}) or direction_test_streamer._is_vehicle_road({"highway": "primary", "oneway:conditional": "yes @ (Mo-Fr)"}) or direction_test_streamer._is_vehicle_road({"highway": "primary", "oneway": "reversible"}) or direction_test_streamer._is_vehicle_road({"highway": "residential", "access": "destination"}):
		_fail("Pedestrian-only or explicitly restricted roads entered the vehicle graph.")
		return
	var one_way_forward: Array[Vector3] = direction_test_streamer.get_vehicle_navigation_path(
		Vector3.ZERO, Vector3(40.0, 0.0, 0.0), 2.0
	)
	var one_way_reverse: Array[Vector3] = direction_test_streamer.get_vehicle_navigation_path(
		Vector3(40.0, 0.0, 0.0), Vector3.ZERO, 2.0
	)
	if one_way_forward.size() < 2 or not one_way_reverse.is_empty():
		_fail("OSM one-way vehicle direction was not enforced.")
		return
	direction_test_cell.set_meta("vehicle_navigation_segments", [
		{"oneway": "-1", "points": one_way_points}
	])
	direction_test_streamer._vehicle_navigation_graph_dirty = true
	var reverse_one_way_forward: Array[Vector3] = direction_test_streamer.get_vehicle_navigation_path(
		Vector3(40.0, 0.0, 0.0), Vector3.ZERO, 2.0
	)
	var reverse_one_way_wrong: Array[Vector3] = direction_test_streamer.get_vehicle_navigation_path(
		Vector3.ZERO, Vector3(40.0, 0.0, 0.0), 2.0
	)
	if reverse_one_way_forward.size() < 2 or not reverse_one_way_wrong.is_empty():
		_fail("OSM reverse one-way (-1) direction was not normalized correctly.")
		return
	direction_test_cell.set_meta("vehicle_navigation_segments", [
		{"oneway": "no", "points": one_way_points}
	])
	direction_test_streamer._vehicle_navigation_graph_dirty = true
	var two_way_reverse: Array[Vector3] = direction_test_streamer.get_vehicle_navigation_path(
		Vector3(40.0, 0.0, 0.0), Vector3.ZERO, 2.0
	)
	if two_way_reverse.size() < 2:
		_fail("Bidirectional residential vehicle roads did not permit reverse travel.")
		return
	var horizontal_road := PackedVector2Array([
		Vector2(-20.0, 0.0), Vector2(0.0, 0.0), Vector2(20.0, 0.0)
	])
	var elevated_road := PackedVector2Array([
		Vector2(0.0, -20.0), Vector2(0.0, 0.0), Vector2(0.0, 20.0)
	])
	direction_test_cell.set_meta("vehicle_navigation_segments", [
		{"oneway": "no", "layer": "0", "points": horizontal_road},
		{"oneway": "no", "layer": "1", "bridge": "yes", "points": elevated_road}
	])
	direction_test_streamer._vehicle_navigation_graph_dirty = true
	var overpass_route: Array[Vector3] = direction_test_streamer.get_vehicle_navigation_path(
		Vector3(-20.0, 0.0, 0.0), Vector3(0.0, 0.0, 20.0), 2.0
	)
	if not overpass_route.is_empty():
		_fail("Vehicle graph connected roads that cross geometrically at different bridge levels.")
		return
	direction_test_cell.set_meta("vehicle_navigation_segments", [
		{"oneway": "no", "layer": "0", "points": horizontal_road},
		{"oneway": "no", "layer": "0", "points": elevated_road}
	])
	direction_test_streamer._vehicle_navigation_graph_dirty = true
	var at_grade_route: Array[Vector3] = direction_test_streamer.get_vehicle_navigation_path(
		Vector3(-20.0, 0.0, 0.0), Vector3(0.0, 0.0, 20.0), 2.0
	)
	if at_grade_route.size() < 3:
		_fail("Vehicle graph failed to connect roads that share a same-level intersection.")
		return
	direction_test_streamer.free()
	direction_test_cell.free()

	var mock_world_root := Node3D.new()
	root.add_child(mock_world_root)
	var mock_vehicle_streamer := MockVehicleRoadStreamer.new()
	mock_vehicle_streamer.name = "BaghdadOSMCellStreamer"
	mock_vehicle_streamer.route_ready = false
	mock_world_root.add_child(mock_vehicle_streamer)
	var mock_crime_manager := Node.new()
	mock_world_root.add_child(mock_crime_manager)
	var mock_region_manager := Node3D.new()
	mock_world_root.add_child(mock_region_manager)
	var traffic_manager = CITY_TRAFFIC_SCRIPT.new()
	traffic_manager.region_manager = mock_region_manager
	if not traffic_manager._should_wait_for_osm_routes("Baghdad") or not traffic_manager._build_real_traffic_route("Baghdad", Vector3.ZERO, 0).is_empty():
		_fail("Ambient Baghdad traffic did not wait for the streamed OSM vehicle graph.")
		return
	var baghdad_npc_vehicle = NPC_VEHICLE_SCRIPT.new()
	mock_world_root.add_child(baghdad_npc_vehicle)
	baghdad_npc_vehicle.configure("npc_test_baghdad", "citizen_test", "Test Driver", "Baghdad", mock_crime_manager, Vector3.ZERO, 0)
	if str(baghdad_npc_vehicle.get_meta("system_road_route_source", "")) != "waiting_for_osm_vehicle_graph" or baghdad_npc_vehicle.is_driving:
		_fail("Baghdad NPC vehicle did not wait safely for streamed OSM roads.")
		return
	mock_vehicle_streamer.route_ready = true
	mock_vehicle_streamer.loaded_cells[Vector2i.ZERO] = true
	var ambient_baghdad_route: Array[Vector3] = traffic_manager._build_real_traffic_route("Baghdad", Vector3.ZERO, 0)
	if ambient_baghdad_route.size() < 4 or not traffic_manager._build_real_traffic_route("Tokyo", Vector3.ZERO, 0).is_empty():
		_fail("Ambient traffic did not use Baghdad OSM loops exclusively in the real-world Baghdad region.")
		return
	if not baghdad_npc_vehicle._try_upgrade_to_osm_vehicle_route() or not baghdad_npc_vehicle.is_driving or str(baghdad_npc_vehicle.get_meta("system_road_route_source", "")) != "real_osm_vehicle_graph" or baghdad_npc_vehicle.route_points.size() < 4:
		_fail("Baghdad civilian NPC vehicle did not upgrade to real OSM routing after cells became available.")
		return
	var other_city_npc_vehicle = NPC_VEHICLE_SCRIPT.new()
	mock_world_root.add_child(other_city_npc_vehicle)
	other_city_npc_vehicle.configure("npc_test_tokyo", "citizen_tokyo", "Test Driver", "Tokyo", mock_crime_manager, Vector3.ZERO, 1)
	if str(other_city_npc_vehicle.get_meta("system_road_route_source", "")) != "procedural_fallback" or other_city_npc_vehicle.route_points.size() != 4:
		_fail("Non-Baghdad NPC vehicles did not preserve their city-local fallback route.")
		return
	baghdad_npc_vehicle.free()
	other_city_npc_vehicle.free()
	traffic_manager.free()
	mock_world_root.free()

	navigation_manager.free()
	print("Baghdad OSM routing passed: pedestrian_points=", strict_player_route.size(), " vehicle_points=", vehicle_route.size(), " motor_roads=", vehicle_segments.size(), " map_road_segments=", exported_road_segments.size())

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
	print("Baghdad OSM runtime validation passed: historic landmarks, Kadhimiya exclusion, player routing and cell persistence.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
