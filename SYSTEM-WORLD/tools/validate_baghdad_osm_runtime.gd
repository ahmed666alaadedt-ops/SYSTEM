extends SceneTree

const BAGHDAD_STREAMER = preload("res://scripts/baghdad_osm_cell_streamer.gd")
const TERRAIN_MANAGER = preload("res://scripts/modern_continent_manager.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var terrain = TERRAIN_MANAGER.new()
	terrain.name = "ModernContinent"
	root.add_child(terrain)
	var streamer = BAGHDAD_STREAMER.new()
	root.add_child(streamer)
	print("Baghdad OSM validation: streamer added; checking manifest and origin.")
	if not streamer.enabled:
		_fail("Baghdad OSM cell pack did not enable.")
		return
	if not streamer.get_streaming_status().get("canonical_origin_frame_valid", false):
		_fail("OSM cell coordinates do not match the canonical WGS84 origin.")
		return
	var empty_surface := SurfaceTool.new()
	empty_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var empty_mesh: ArrayMesh = streamer._commit_surface_tool_if_valid(empty_surface)
	if empty_mesh != null:
		_fail("Empty OSM geometry must be rejected before creating a renderer mesh.")
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
	print("Baghdad OSM runtime cell passed: roads=", roads.size(), " buildings=", buildings.size(), " landuse=", landuse.size(), " building_collisions=", building_collisions.size())
	print("Baghdad OSM validation: checking automatic player-driven streaming at Republic Bridge cell 17:-6.")
	var bridge_player := Node3D.new()
	bridge_player.name = "BridgeStreamingTestPlayer"
	bridge_player.add_to_group("system_player")
	bridge_player.position = Vector3(3563.921, 18.0, -1050.256)
	root.add_child(bridge_player)
	streamer._process(0.0)
	if not streamer.desired_cells.has(Vector2i(17, -6)):
		_fail("Player-driven OSM streaming did not select Republic Bridge cell 17:-6 at the surveyed bridge coordinates.")
		return
	if not streamer.loaded_cells.has(Vector2i(17, -6)):
		_fail("Republic Bridge OSM cell 17:-6 was queued but not loaded as the player's active center cell.")
		return
	var bridge_cell_root: Node3D = streamer.loaded_cells[Vector2i(17, -6)]
	var primary_bridge := bridge_cell_root.find_children("OSMBridge_4080878_*", "MeshInstance3D", true, false)
	var secondary_bridge := bridge_cell_root.find_children("OSMBridge_754157537_*", "MeshInstance3D", true, false)
	var tigris_river := bridge_cell_root.find_children("OSMWaterway_24709603_*", "MeshInstance3D", true, false)
	if primary_bridge.is_empty() or secondary_bridge.is_empty():
		_fail("Republic Bridge primary/secondary OSM roadway centerlines were not rendered in cell 17:-6.")
		return
	for bridge_mesh in primary_bridge + secondary_bridge:
		if absf(float(bridge_mesh.get_meta("system_bridge_deck_height_override_m", 0.0)) - 18.08) > 0.1:
			_fail("Republic Bridge roadway centerline is not rendered on the physical deck elevation.")
			return
	if tigris_river.is_empty():
		_fail("Tigris River OSM geometry was not rendered in cell 17:-6.")
		return
	print("Baghdad Republic Bridge OSM cell passed: primary bridge=", primary_bridge.size(), " secondary bridge=", secondary_bridge.size(), " Tigris=", tigris_river.size())

	var regional_roads := BAGHDAD_STREAMER.new()
	regional_roads.name = "BaghdadRegionalRoadsValidationStreamer"
	regional_roads.data_root = "res://data/geography/baghdad/regional_roads"
	root.add_child(regional_roads)
	if not regional_roads.enabled or absf(regional_roads.cell_size - 1000.0) > 0.01:
		_fail("Citywide Baghdad road pack did not enable at the expected 1 km overview resolution.")
		return
	if int(regional_roads.get_streaming_status().get("loaded_cell_count", -1)) != 0:
		_fail("Regional road streamer unexpectedly loaded cells before its player update.")
		return
	regional_roads._process(0.0)
	if not regional_roads.desired_cells.has(Vector2i(3, -2)):
		_fail("Citywide road streamer did not select the Republic Bridge 1 km cell for the player.")
		return
	if not regional_roads.loaded_cells.has(Vector2i(3, -2)):
		_fail("Citywide road streamer did not load the player's Republic Bridge 1 km cell.")
		return
	regional_roads._load_cell(Vector2i(0, 0))
	if not regional_roads.loaded_cells.has(Vector2i(0, 0)):
		_fail("Citywide regional road pack has no central Baghdad road cell.")
		return
	var regional_center: Node3D = regional_roads.loaded_cells[Vector2i(0, 0)]
	var regional_center_roads := regional_center.find_children("OSMRoad_*", "MeshInstance3D", true, false)
	if regional_center_roads.is_empty():
		_fail("Citywide regional road center cell produced no road meshes.")
		return
	regional_roads._load_cell(Vector2i(3, -2))
	if not regional_roads.loaded_cells.has(Vector2i(3, -2)):
		_fail("Citywide regional road pack is missing the Republic Bridge overview cell 3:-2.")
		return
	var regional_bridge: Node3D = regional_roads.loaded_cells[Vector2i(3, -2)]
	var regional_bridge_roads := regional_bridge.find_children("OSMRoad_*", "MeshInstance3D", true, false)
	if regional_bridge_roads.is_empty():
		_fail("Republic Bridge regional overview cell has no OSM road meshes.")
		return
	print("Baghdad citywide road overview passed: center roads=", regional_center_roads.size(), " bridge-area roads=", regional_bridge_roads.size(), " resolution=1 km.")
	regional_roads.queue_free()
	streamer.queue_free()
	terrain.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
