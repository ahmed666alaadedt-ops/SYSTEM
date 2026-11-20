extends SceneTree

const STREAMER_SCRIPT = preload("res://scripts/modern_world_cell_streaming_manager.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _height_at(x: float, z: float) -> float:
	return x * 0.01 + z * 0.02


func _run_tests() -> void:
	var streamer = STREAMER_SCRIPT.new()
	root.add_child(streamer)
	streamer._last_center_cell = Vector2i.ZERO
	assert(streamer.configure(Callable(self, "_height_at"), 600.0, 600.0, 200.0, 20.0))
	assert(streamer.world_to_cell(-199.0, -199.0) == Vector2i(0, 0))
	assert(streamer.world_to_cell(0.0, 0.0) == Vector2i(1, 1))
	assert(streamer.cell_origin(Vector2i(1, 0)) == Vector2(-100.0, -300.0))

	streamer._refresh_desired_cells(Vector2i(1, 1))
	assert(streamer.desired_cells.size() == 9)
	assert(streamer.pending_loads.size() == 9)
	assert(streamer.pending_loads[0] == Vector2i(1, 1), "Player cell must load first.")
	streamer._process_cell_queue()
	assert(streamer.loaded_cells.has(Vector2i(1, 1)), "Player cell was not loaded first.")

	streamer._load_cell(Vector2i(0, 0))
	streamer._load_cell(Vector2i(1, 0))
	assert(streamer.loaded_cells.size() == 2)

	var left_root: Node3D = streamer.loaded_cells[Vector2i(0, 0)]
	var right_root: Node3D = streamer.loaded_cells[Vector2i(1, 0)]
	var left_mesh: ArrayMesh = left_root.get_node("TerrainVisual").mesh
	var right_mesh: ArrayMesh = right_root.get_node("TerrainVisual").mesh
	var left_vertices: PackedVector3Array = left_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var right_vertices: PackedVector3Array = right_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var row := 5
	var intervals := 10
	var left_edge_height := left_vertices[row * (intervals + 1) + intervals].y
	var right_edge_height := right_vertices[row * (intervals + 1)].y
	assert(is_equal_approx(left_edge_height, right_edge_height), "Adjacent terrain cell edge heights do not match.")

	assert(left_root.get_node_or_null("TerrainCollision") != null)
	streamer._unload_cell(Vector2i(0, 0))
	assert(streamer.loaded_cells.size() == 1)
	streamer.queue_free()
	print("Terrain cell streaming checks passed: stable IDs, shared edge heights, collision and unload.")
	quit(0)
