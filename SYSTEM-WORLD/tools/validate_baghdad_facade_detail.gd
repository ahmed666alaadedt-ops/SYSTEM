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
	var building := streamer.get_node_or_null("OSMBuilding_apartment_block_facade_validation_apartment_001") as MeshInstance3D
	var windows := streamer.get_node_or_null("OSMBuildingWindows_facade_validation_apartment_001") as MultiMeshInstance3D
	if building == null or windows == null or windows.multimesh == null:
		_fail("High-detail apartment is missing its instanced facade-window resource.")
		return
	var window_count := windows.multimesh.instance_count
	if window_count <= 0 or window_count > 64:
		_fail("Facade window count is outside the mobile-safe 1..64 per-building budget.")
		return
	if int(building.get_meta("system_facade_window_count", 0)) != window_count:
		_fail("Building facade metadata does not match the MultiMesh instance count.")
		return
	if str(windows.get_meta("system_facade_detail_type", "")) != "procedural_instanced_windows":
		_fail("Facade window MultiMesh is missing its detail classification.")
		return

	var overview_parent := Node3D.new()
	overview_parent.name = "BaghdadRegionalOverviewValidation"
	root.add_child(overview_parent)
	streamer.call("_build_building_overview_feature", overview_parent, feature)
	if overview_parent.get_child_count() != 1 or overview_parent.get_child(0) is MultiMeshInstance3D:
		_fail("The 1 km regional overview must remain a low-cost extrusion LOD without facade windows.")
		return
	var overview_building := overview_parent.get_child(0) as MeshInstance3D
	if overview_building == null or str(overview_building.get_meta("system_facade_detail_level", "")) != "regional_extrusion_lod":
		_fail("Regional overview building is missing its explicit low-detail facade classification.")
		return

	print("Baghdad facade detail validation passed: high-detail 200 m cell apartment generated ", window_count,
		" instanced windows; regional 1 km overview remains extrusion-only; per-building window budget <= 64.")
	# Do not force dummy-renderer teardown in this Godot 4.3 geometry unit test.
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad facade detail validation failed: " + message)
	quit(1)
