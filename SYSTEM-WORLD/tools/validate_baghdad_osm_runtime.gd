extends SceneTree

const BAGHDAD_STREAMER = preload("res://scripts/baghdad_osm_cell_streamer.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
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

	var invalid_mesh_paths := _find_invalid_mesh_nodes(cell_root)
	print("Baghdad OSM mesh integrity: null mesh nodes=", invalid_mesh_paths.size())
	if not invalid_mesh_paths.is_empty():
		_fail("Baghdad OSM cell contains nodes without valid mesh resources: " + ", ".join(invalid_mesh_paths.slice(0, 20)))
		return

	print("Baghdad OSM runtime cell passed: roads=", roads.size(), " buildings=", buildings.size(), " landuse=", landuse.size(), " building_collisions=", building_collisions.size())
	print("Baghdad OSM cleanup: queueing cell and streamer for deletion.")
	streamer.queue_free()
	await process_frame
	print("Baghdad OSM cleanup: first process frame completed.")
	await process_frame
	print("Baghdad OSM cleanup: second process frame completed.")
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
