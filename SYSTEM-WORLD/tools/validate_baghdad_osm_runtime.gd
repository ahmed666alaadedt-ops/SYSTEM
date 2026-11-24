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
	print("Baghdad OSM validation: loading Republic Bridge/Tigris cell 17:-6.")
	streamer._load_cell(Vector2i(17, -6))
	if not streamer.loaded_cells.has(Vector2i(17, -6)):
		_fail("Republic Bridge OSM cell 17:-6 did not load from the extended metric pack.")
		return
	var bridge_cell_root: Node3D = streamer.loaded_cells[Vector2i(17, -6)]
	var primary_bridge := bridge_cell_root.find_children("OSMBridge_4080878_*", "MeshInstance3D", true, false)
	var secondary_bridge := bridge_cell_root.find_children("OSMBridge_754157537_*", "MeshInstance3D", true, false)
	var tigris_river := bridge_cell_root.find_children("OSMWaterway_24709603_*", "MeshInstance3D", true, false)
	if primary_bridge.is_empty() or secondary_bridge.is_empty():
		_fail("Republic Bridge primary/secondary OSM roadway centerlines were not rendered in cell 17:-6.")
		return
	if tigris_river.is_empty():
		_fail("Tigris River OSM geometry was not rendered in cell 17:-6.")
		return
	print("Baghdad Republic Bridge OSM cell passed: primary bridge=", primary_bridge.size(), " secondary bridge=", secondary_bridge.size(), " Tigris=", tigris_river.size())
	streamer.queue_free()
	terrain.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
