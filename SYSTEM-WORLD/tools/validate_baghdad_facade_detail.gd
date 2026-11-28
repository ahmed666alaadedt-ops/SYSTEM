extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var streamer_script := load("res://scripts/baghdad_osm_cell_streamer.gd") as Script
	if streamer_script == null:
		_fail("Baghdad OSM cell streamer script could not load.")
		return
	var streamer := streamer_script.new() as Node3D
	if streamer == null:
		_fail("Baghdad OSM cell streamer instance could not be created.")
		return
	streamer.name = "BaghdadFacadeDetailValidationStreamer"
	root.add_child(streamer)
	streamer.call("_create_materials")

	var feature := {
		"id": "facade_validation_apartment_001",
		"geometry": {
			"type": "Polygon",
			"coordinates": [[[0.0, 0.0], [24.0, 0.0], [24.0, 18.0], [0.0, 18.0], [0.0, 0.0]]]
		},
		"tags": {
			"building": "apartments",
			"height": "16",
			"building:levels": "5"
		}
	}
	var built := int(streamer.call("_build_building_feature", streamer, feature, []))
	if built != 1:
		_fail("Synthetic five-floor Baghdad apartment footprint did not build.")
		return
	streamer.call("_flush_facade_window_multimesh", streamer)
	var building := streamer.get_node_or_null("OSMBuilding_apartment_block_facade_validation_apartment_001") as MeshInstance3D
	var windows := streamer.get_node_or_null("BaghdadCellFacadeWindows") as MultiMeshInstance3D
	if building == null or windows == null or windows.multimesh == null:
		_fail("High-detail apartment is missing its instanced facade-window resource.")
		return
	var window_count := windows.multimesh.instance_count
	if window_count <= 0 or window_count > 32:
		_fail("Facade window count is outside the mobile-safe 1..32 per-building budget.")
		return
	if int(building.get_meta("system_facade_window_count", 0)) != window_count:
		_fail("Building facade metadata does not match the MultiMesh instance count.")
		return
	if str(windows.get_meta("system_facade_detail_type", "")) != "procedural_instanced_windows":
		_fail("Facade window MultiMesh is missing its detail classification.")
		return
	if str(windows.get_meta("system_facade_window_sampling", "")) != "even_distribution_across_facades":
		_fail("Facade windows were not sampled evenly across the building sides.")
		return
	if int(windows.get_meta("system_facade_window_draw_calls_per_cell", 0)) != 1:
		_fail("Facade windows are not aggregated into one MultiMesh draw call per cell.")
		return
	if not windows.multimesh.use_colors:
		_fail("Facade MultiMesh must retain per-window cool/warm color variation.")
		return

	# Validate five distinct vertical window bands without assuming the
	# synthetic test building sits at world elevation zero. Real Baghdad
	# footprints inherit terrain elevation, so absolute Y thresholds are invalid.
	var floor_levels: Array[float] = []
	var floor_instance_counts: Array[int] = []
	for instance_index in range(window_count):
		var instance_transform: Transform3D = windows.multimesh.get_instance_transform(instance_index)
		var window_y := instance_transform.origin.y
		var matched_floor := -1
		for floor_index in range(floor_levels.size()):
			if absf(window_y - floor_levels[floor_index]) <= 0.75:
				matched_floor = floor_index
				break
		if matched_floor < 0:
			floor_levels.append(window_y)
			floor_instance_counts.append(1)
		else:
			floor_instance_counts[matched_floor] += 1
	if floor_levels.size() != 5:
		_fail("Five-floor apartment must produce five distinct facade window bands; found %d." % floor_levels.size())
		return
	for floor_index in range(floor_instance_counts.size()):
		if floor_instance_counts[floor_index] < 3:
			_fail("Five-floor apartment facade coverage is incomplete on vertical band %d." % (floor_index + 1))
			return

	var overview_parent := Node3D.new()
	overview_parent.name = "BaghdadRegionalOverviewValidation"
	root.add_child(overview_parent)
	var overview_built := int(streamer.call("_build_building_overview_feature", overview_parent, feature))
	if overview_built != 1 or overview_parent.get_child_count() != 1 or overview_parent.get_child(0) is MultiMeshInstance3D:
		_fail("The 1 km regional overview must remain a low-cost extrusion LOD without facade windows.")
		return
	var overview_building := overview_parent.get_child(0) as MeshInstance3D
	if overview_building == null or str(overview_building.get_meta("system_facade_detail_level", "")) != "regional_extrusion_lod":
		_fail("Regional overview building is missing its explicit low-detail facade classification.")
		return
	if str(overview_building.get_meta("system_footprint_geometry", "")) != "osm_polygon_extrusion":
		_fail("Regional overview must preserve the mapped OSM building footprint extrusion.")
		return

	print("Baghdad facade detail validation passed: five-floor apartment generated ", window_count,
		" instanced windows across five vertical facade bands in one cell-level MultiMesh; regional 1 km overview remains extrusion-only; per-building window budget <= 32.")
	# Do not force dummy-renderer teardown in this Godot 4.3 geometry unit test.
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad facade detail validation failed: " + message)
	quit(1)
