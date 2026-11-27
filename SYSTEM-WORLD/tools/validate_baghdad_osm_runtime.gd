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

	var regional_urban := BAGHDAD_STREAMER.new()
	regional_urban.name = "BaghdadRegionalUrbanValidationStreamer"
	regional_urban.data_root = "res://data/geography/baghdad/regional_urban"
	regional_urban.load_radius = 0
	regional_urban.overview_mode = true
	root.add_child(regional_urban)
	if not regional_urban.enabled or not regional_urban.overview_mode or absf(regional_urban.cell_size - 1000.0) > 0.01:
		_fail("Citywide Baghdad urban detail pack did not enable in 1 km low-detail mode.")
		return
	var urban_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/geography/baghdad/regional_urban/manifest.json"))
	if not urban_manifest is Dictionary:
		_fail("Citywide Baghdad urban manifest is invalid.")
		return
	var expected_urban_layers := ["buildings", "waterways", "bridges", "landuse", "amenities", "railway", "natural-water", "entrances"]
	if urban_manifest.get("layers_included", []) != expected_urban_layers:
		_fail("Citywide Baghdad urban pack is missing one or more expected OSM layers.")
		return
	var urban_cells_path := "res://data/geography/baghdad/regional_urban/cells"
	var urban_files := DirAccess.get_files_at(urban_cells_path)
	var building_cell := Vector2i(2147483647, 2147483647)
	var poi_cell := Vector2i(2147483647, 2147483647)
	for file_name in urban_files:
		if not file_name.ends_with(".json"):
			continue
		var tile: Variant = JSON.parse_string(FileAccess.get_file_as_string(urban_cells_path.path_join(file_name)))
		if not tile is Dictionary:
			continue
		var tile_layers: Dictionary = tile.get("layers", {})
		var tile_cell := Vector2i(int(tile.get("cell_x", 0)), int(tile.get("cell_z", 0)))
		if building_cell.x == 2147483647 and not tile_layers.get("buildings", []).is_empty():
			building_cell = tile_cell
		if poi_cell.x == 2147483647 and not tile_layers.get("amenities", []).is_empty():
			poi_cell = tile_cell
		if building_cell.x != 2147483647 and poi_cell.x != 2147483647:
			break
	if building_cell.x == 2147483647 or poi_cell.x == 2147483647:
		_fail("Citywide urban pack must contain mapped building footprints and public/commercial POIs.")
		return
	regional_urban._load_cell(building_cell)
	if not regional_urban.loaded_cells.has(building_cell):
		_fail("Citywide urban building cell did not load.")
		return
	var urban_buildings: Node3D = regional_urban.loaded_cells[building_cell]
	var overview_buildings := urban_buildings.find_children("OSMOverviewBuilding_*", "MeshInstance3D", true, false)
	if overview_buildings.is_empty():
		_fail("Citywide urban building footprints did not produce low-detail building meshes.")
		return
	regional_urban._load_cell(poi_cell)
	if not regional_urban.loaded_cells.has(poi_cell):
		_fail("Citywide urban POI cell did not load.")
		return
	var urban_pois: Node3D = regional_urban.loaded_cells[poi_cell]
	var poi_markers := urban_pois.find_children("OSMRegionalPOI_*", "Node3D", true, false)
	if poi_markers.is_empty():
		_fail("Citywide urban amenities did not produce POI markers.")
		return
	print("Baghdad citywide urban overview passed: buildings=", overview_buildings.size(), " POI markers=", poi_markers.size(), " resolution=1 km.")
	regional_urban.queue_free()
	regional_roads.queue_free()
	streamer.queue_free()
	terrain.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
