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
	var invalid_mesh_paths := _find_invalid_mesh_nodes(cell_root)
	if not invalid_mesh_paths.is_empty():
		_fail("Baghdad OSM generated null-mesh scene nodes: " + ", ".join(invalid_mesh_paths.slice(0, 12)))
		return
	print("Baghdad OSM mesh integrity: no null MeshInstance3D or MultiMeshInstance3D resources in loaded center cell.")
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

	if streamer.entrance_association_schema_version != 1:
		_fail("Baghdad OSM runtime pack has no supported entrance association metadata.")
		return
	# Cell 0:2 is part of the verified 5x5 source sample and contains mapped
	# entrance nodes. Keep the center-cell geometry checks above independent.
	var entrance_cell_id := Vector2i(0, 2)
	streamer._load_cell(entrance_cell_id)
	var entrance_cell := streamer.get_cell_node(entrance_cell_id)
	if entrance_cell == null:
		_fail("Baghdad entrance sample cell 0:2 did not load.")
		return
	var entrance_cell_path := streamer.data_root.path_join("cells").path_join("0_2.json")
	var entrance_tile: Variant = JSON.parse_string(FileAccess.get_file_as_string(entrance_cell_path))
	if not entrance_tile is Dictionary:
		_fail("Baghdad entrance sample cell JSON could not be read.")
		return
	var entrance_layers: Dictionary = entrance_tile.get("layers", {})
	var source_entrances: Array = entrance_layers.get("entrances", [])
	var expected_runtime_entrances := 0
	for source_entrance in source_entrances:
		var source_association: Dictionary = source_entrance.get("association", {})
		if str(source_association.get("status", "")) in ["accepted", "restricted"]:
			expected_runtime_entrances += 1
	var runtime_entrance_roots := entrance_cell.find_children("OSMEntrance_*", "Node3D", true, false)
	if runtime_entrance_roots.size() != expected_runtime_entrances or runtime_entrance_roots.is_empty():
		_fail("Runtime entrance markers do not match accepted/restricted source associations.")
		return
	var accepted_runtime_entrances := 0
	for entrance_root_value in runtime_entrance_roots:
		var entrance_root := entrance_root_value as Node3D
		var entrance_interaction := entrance_root.get_node_or_null("MappedEntranceInteraction") as StaticBody3D
		if entrance_interaction == null:
			_fail("A mapped entrance marker has no interaction collision body.")
			return
		var association_status := str(entrance_interaction.get_meta("system_association_status", ""))
		if association_status not in ["accepted", "restricted"]:
			_fail("An unreviewed entrance association was exposed to the runtime.")
			return
		var entrance_id := str(entrance_interaction.get_meta("osm_feature_id", ""))
		var associated_building_id := str(entrance_interaction.get_meta("system_associated_building_id", ""))
		if entrance_id.is_empty() or associated_building_id.is_empty():
			_fail("A runtime entrance is missing its source ID or stable associated building ID.")
			return
		var linked_building_found := false
		for building_body_value in entrance_cell.find_children("OSMBuildingCollision_*", "StaticBody3D", true, false):
			var building_body := building_body_value as StaticBody3D
			if str(building_body.get_meta("system_location_id", "")) != associated_building_id:
				continue
			var linked_ids: Array = building_body.get_meta("system_verified_entrance_ids", [])
			if not linked_ids.has(entrance_id):
				_fail("The associated building does not retain the source entrance ID.")
				return
			linked_building_found = true
			break
		if not linked_building_found:
			_fail("A runtime entrance points to a building that is not present in its streamed cell.")
			return
		if association_status == "accepted":
			accepted_runtime_entrances += 1
			if str(entrance_interaction.get_meta("system_access_state", "")) != "verified_building_association_no_door_or_interior":
				_fail("An accepted source entrance was incorrectly marked as an enterable door.")
				return
		else:
			if str(entrance_interaction.get_meta("system_access_state", "")) != "restricted_no_public_entry":
				_fail("A restricted source entrance was not kept inaccessible.")
				return
	if accepted_runtime_entrances == 0:
		_fail("The Baghdad entrance sample cell contains no accepted building associations.")
		return
	print("Baghdad entrance association runtime passed: source_points=", source_entrances.size(), " linked_markers=", runtime_entrance_roots.size(), " accepted=", accepted_runtime_entrances)
	streamer._unload_cell(entrance_cell_id)

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
	print("Baghdad OSM runtime validation passed: historic landmarks, Kadhimiya exclusion, player routing and cell persistence.")
	# queue_free() is deferred. Let SceneTree process every queued deletion before
	# quitting so the headless renderer never observes partially torn-down meshes.
	await process_frame
	await process_frame
	print("Baghdad OSM runtime cleanup flushed before SceneTree shutdown.")
	quit(0)


func _find_invalid_mesh_nodes(start: Node) -> Array[String]:
	var invalid_paths: Array[String] = []
	var pending: Array[Node] = [start]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh == null:
			invalid_paths.append(str(node.get_path()))
		if node is MultiMeshInstance3D:
			var instance := node as MultiMeshInstance3D
			if instance.multimesh == null or instance.multimesh.mesh == null:
				invalid_paths.append(str(node.get_path()))
		for child in node.get_children():
			pending.append(child)
	return invalid_paths


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
