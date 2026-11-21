extends SceneTree

const STREAMER_SCRIPT = preload("res://scripts/modern_world_cell_streaming_manager.gd")
const CONTINENT_SCRIPT = preload("res://scripts/modern_continent_manager.gd")
const GEOMETRY_CLIPPER = preload("res://scripts/system_world_cell_geometry_clipper.gd")

var _loaded_signal_count := 0
var _unloading_signal_count := 0
var _unloaded_signal_count := 0
var _last_unloading_cell_root: Node3D


func _on_cell_loaded(_cell: Vector2i, _cell_root: Node3D) -> void:
	_loaded_signal_count += 1


func _on_cell_unloading(_cell: Vector2i, cell_root: Node3D) -> void:
	_unloading_signal_count += 1
	_last_unloading_cell_root = cell_root


func _on_cell_unloaded(_cell: Vector2i, _cell_id: String) -> void:
	_unloaded_signal_count += 1


func _initialize() -> void:
	call_deferred("_run_tests")


func _height_at(x: float, z: float) -> float:
	return x * 0.01 + z * 0.02


func _run_tests() -> void:
	var source_line := PackedVector2Array([Vector2(-50.0, 50.0), Vector2(150.0, 50.0)])
	var left_pieces: Array[PackedVector2Array] = GEOMETRY_CLIPPER.clip_polyline_to_rect(source_line, Vector2(0.0, 0.0), Vector2(100.0, 100.0))
	var right_pieces: Array[PackedVector2Array] = GEOMETRY_CLIPPER.clip_polyline_to_rect(source_line, Vector2(100.0, 0.0), Vector2(200.0, 100.0))
	assert(left_pieces.size() == 1 and right_pieces.size() == 1)
	assert(left_pieces[0][1].is_equal_approx(right_pieces[0][0]), "Adjacent cell road/river clip endpoints must match.")

	var streamer = STREAMER_SCRIPT.new()
	root.add_child(streamer)
	streamer.cell_loaded.connect(_on_cell_loaded)
	streamer.cell_unloading.connect(_on_cell_unloading)
	streamer.cell_unloaded.connect(_on_cell_unloaded)
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
	assert(streamer.loaded_cells.size() == 3)

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

	var terrain_collision := left_root.get_node_or_null("TerrainCollision/TerrainHeightCollision") as CollisionShape3D
	assert(terrain_collision != null)
	streamer._update_loaded_cell_collisions(Vector2i(10, 10))
	assert(terrain_collision.disabled, "Distant cell collision should be disabled.")
	streamer._update_loaded_cell_collisions(Vector2i.ZERO)
	assert(not terrain_collision.disabled, "Nearby cell collision should be enabled again.")
	streamer._unload_cell(Vector2i(0, 0))
	assert(streamer.loaded_cells.size() == 2)
	assert(_loaded_signal_count >= 3, "Cell-loaded lifecycle signal was not emitted.")
	assert(_unloading_signal_count == 1, "Cell-unloading signal must fire before the cell is freed.")
	assert(_unloaded_signal_count == 1, "Cell-unloaded signal was not emitted.")
	assert(_last_unloading_cell_root != null, "Pre-unload signal must expose the cell root for state capture.")
	streamer.queue_free()

	var edge_streamer = STREAMER_SCRIPT.new()
	root.add_child(edge_streamer)
	edge_streamer._last_center_cell = Vector2i(3, 2)
	assert(edge_streamer.configure(Callable(self, "_height_at"), 660.0, 460.0, 200.0, 20.0))
	edge_streamer._load_cell(Vector2i(3, 2))
	var edge_root: Node3D = edge_streamer.loaded_cells[Vector2i(3, 2)]
	var edge_vertices: PackedVector3Array = edge_root.get_node("TerrainVisual").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert(edge_vertices[edge_vertices.size() - 1].x == 60.0)
	assert(edge_vertices[edge_vertices.size() - 1].z == 60.0)
	var edge_shape := edge_root.get_node("TerrainCollision/TerrainHeightCollision").shape as HeightMapShape3D
	assert(edge_shape.map_width == 4 and edge_shape.map_depth == 4, "Partial edge collision dimensions are incorrect.")
	edge_streamer.queue_free()

	var continent = CONTINENT_SCRIPT.new()
	root.add_child(continent)
	var integrated_streamer := continent.get_node_or_null("ModernWorldTerrainCellStreamer")
	assert(integrated_streamer != null, "Modern continent did not instantiate the cell streamer.")
	assert(continent.get_node_or_null("ContinentTerrainVisual") == null, "Monolithic terrain visual is still active.")
	assert(continent.get_node_or_null("ContinentTerrainCollision") == null, "Monolithic terrain collision is still active.")
	continent.queue_free()
	print("Terrain cell streaming checks passed: lifecycle, shared edges, collision and canonical continent integration and deterministic road/river clipping.")
	quit(0)
