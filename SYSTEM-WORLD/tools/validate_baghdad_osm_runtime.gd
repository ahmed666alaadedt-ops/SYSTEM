extends SceneTree

const BAGHDAD_STREAMER = preload("res://scripts/baghdad_osm_cell_streamer.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var streamer = BAGHDAD_STREAMER.new()
	root.add_child(streamer)
	assert(streamer.enabled, "Baghdad OSM cell pack did not enable.")
	assert(streamer.get_node_or_null("BaghdadOSMAttribution/OpenStreetMapCredit") != null, "Required OSM attribution overlay is missing.")
	streamer._load_cell(Vector2i(0, 0))
	assert(streamer.loaded_cells.has(Vector2i(0, 0)), "Baghdad center cell did not load.")
	var cell_root: Node3D = streamer.loaded_cells[Vector2i(0, 0)]
	var roads := cell_root.find_children("OSMRoad_*", "MeshInstance3D", true, false)
	var buildings := cell_root.find_children("OSMBuilding_*", "MeshInstance3D", true, false)
	var landuse := cell_root.find_children("OSMLanduse_*", "MeshInstance3D", true, false)
	assert(not roads.is_empty(), "Baghdad OSM center cell has no generated road meshes.")
	assert(not buildings.is_empty(), "Baghdad OSM center cell has no generated building meshes.")
	assert(not landuse.is_empty(), "Baghdad OSM center cell has no generated land-use meshes.")
	var building_collisions := cell_root.find_children("OSMBuildingCollision_*", "StaticBody3D", true, false)
	assert(not building_collisions.is_empty(), "Baghdad OSM building collision bodies were not created.")
	print("Baghdad OSM runtime cell passed: roads=", roads.size(), " buildings=", buildings.size(), " landuse=", landuse.size(), " building_collisions=", building_collisions.size())
	streamer.queue_free()
	quit(0)
