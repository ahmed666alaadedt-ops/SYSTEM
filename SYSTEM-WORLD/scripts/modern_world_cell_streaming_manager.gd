extends Node3D
class_name ModernWorldCellStreamingManager

## Independent terrain-cell streamer. Cell borders use identical world-space
## sample coordinates, so adjacent cells share exact edge heights.
## LOD is deliberately metadata-only until edge stitching is implemented.

const DEFAULT_CELL_SIZE := 500.0
const DEFAULT_SAMPLE_SPACING := 20.0
const MAX_CELL_OPERATIONS_PER_FRAME := 1

var height_sampler: Callable
var world_width := 0.0
var world_depth := 0.0
var cell_size := DEFAULT_CELL_SIZE
var sample_spacing := DEFAULT_SAMPLE_SPACING
var load_radius := 1
var collision_radius := 1
var terrain_material: Material

var loaded_cells: Dictionary = {}
var desired_cells: Dictionary = {}
var pending_loads: Array[Vector2i] = []
var pending_unloads: Array[Vector2i] = []
var _last_center_cell := Vector2i(2147483647, 2147483647)


func configure(
	sampler: Callable,
	width_m: float,
	depth_m: float,
	cell_size_m: float = DEFAULT_CELL_SIZE,
	sample_spacing_m: float = DEFAULT_SAMPLE_SPACING,
	material: Material = null,
	near_radius: int = 1,
	collision_near_radius: int = 1
) -> bool:
	if not sampler.is_valid() or width_m <= 0.0 or depth_m <= 0.0:
		push_error("SYSTEM CellStreamer: invalid terrain source or world dimensions.")
		return false
	cell_size = maxf(cell_size_m, sample_spacing_m)
	sample_spacing = maxf(sample_spacing_m, 1.0)
	if not is_equal_approx(cell_size / sample_spacing, round(cell_size / sample_spacing)):
		push_error("SYSTEM CellStreamer: cell size must be an integer multiple of sample spacing.")
		return false
	world_width = width_m
	world_depth = depth_m
	height_sampler = sampler
	terrain_material = material
	load_radius = maxi(near_radius, 0)
	collision_radius = clampi(collision_near_radius, 0, load_radius)
	return true


func _process(_delta: float) -> void:
	if not height_sampler.is_valid():
		return
	var players := get_tree().get_nodes_in_group("system_player")
	if players.is_empty() or not is_instance_valid(players[0]):
		return
	var player_position: Vector3 = players[0].global_position
	var center := world_to_cell(player_position.x, player_position.z)
	if center != _last_center_cell:
		_last_center_cell = center
		_refresh_desired_cells(center)
	_process_cell_queue()


func world_to_cell(world_x: float, world_z: float) -> Vector2i:
	return Vector2i(floori((world_x + world_width * 0.5) / cell_size), floori((world_z + world_depth * 0.5) / cell_size))


func cell_origin(cell: Vector2i) -> Vector2:
	return Vector2(
		-world_width * 0.5 + float(cell.x) * cell_size,
		-world_depth * 0.5 + float(cell.y) * cell_size
	)


func get_cell_lod(cell: Vector2i, center: Vector2i) -> int:
	var distance := maxi(absi(cell.x - center.x), absi(cell.y - center.y))
	if distance <= 0:
		return 0
	if distance == 1:
		return 1
	return 2


func _refresh_desired_cells(center: Vector2i) -> void:
	desired_cells.clear()
	pending_loads.clear()
	pending_unloads.clear()
	var cells_x := ceili(world_width / cell_size)
	var cells_z := ceili(world_depth / cell_size)
	for z in range(maxi(0, center.y - load_radius), mini(cells_z, center.y + load_radius + 1)):
		for x in range(maxi(0, center.x - load_radius), mini(cells_x, center.x + load_radius + 1)):
			var cell := Vector2i(x, z)
			desired_cells[cell] = true
			if not loaded_cells.has(cell):
				pending_loads.append(cell)
	for key in loaded_cells.keys():
		var cell: Vector2i = key
		if not desired_cells.has(cell):
			pending_unloads.append(cell)


func _process_cell_queue() -> void:
	var operations := 0
	while not pending_unloads.is_empty() and operations < MAX_CELL_OPERATIONS_PER_FRAME:
		var cell: Vector2i = pending_unloads.pop_front()
		_unload_cell(cell)
		operations += 1
	while not pending_loads.is_empty() and operations < MAX_CELL_OPERATIONS_PER_FRAME:
		var cell: Vector2i = pending_loads.pop_front()
		_load_cell(cell)
		operations += 1


func _load_cell(cell: Vector2i) -> void:
	if loaded_cells.has(cell):
		return
	var origin := cell_origin(cell)
	var intervals := int(round(cell_size / sample_spacing))
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var heights := PackedFloat32Array()
	heights.resize((intervals + 1) * (intervals + 1))
	for z_index in range(intervals + 1):
		for x_index in range(intervals + 1):
			var world_x := origin.x + float(x_index) * sample_spacing
			var world_z := origin.y + float(z_index) * sample_spacing
			var height := float(height_sampler.call(world_x, world_z))
			heights[z_index * (intervals + 1) + x_index] = height
			vertices.append(Vector3(float(x_index) * sample_spacing, height, float(z_index) * sample_spacing))
	for z_index in range(intervals):
		for x_index in range(intervals):
			var a := z_index * (intervals + 1) + x_index
			var b := a + 1
			var c := a + intervals + 1
			var d := c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var cell_root := Node3D.new()
	cell_root.name = "TerrainCell_%d_%d" % [cell.x, cell.y]
	cell_root.position = Vector3(origin.x, 0.0, origin.y)
	cell_root.set_meta("cell_id", "%d:%d" % [cell.x, cell.y])
	cell_root.set_meta("lod_tier", get_cell_lod(cell, _last_center_cell))
	var visual := MeshInstance3D.new()
	visual.name = "TerrainVisual"
	visual.mesh = mesh
	visual.material_override = terrain_material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cell_root.add_child(visual)
	var center_distance := maxi(absi(cell.x - _last_center_cell.x), absi(cell.y - _last_center_cell.y))
	if center_distance <= collision_radius:
		var body := StaticBody3D.new()
		body.name = "TerrainCollision"
		var shape := HeightMapShape3D.new()
		shape.map_width = intervals + 1
		shape.map_depth = intervals + 1
		shape.map_data = heights
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.scale = Vector3(sample_spacing, 1.0, sample_spacing)
		body.add_child(collision)
		cell_root.add_child(body)
	add_child(cell_root)
	loaded_cells[cell] = cell_root


func _unload_cell(cell: Vector2i) -> void:
	if not loaded_cells.has(cell):
		return
	var node: Node3D = loaded_cells[cell]
	loaded_cells.erase(cell)
	if is_instance_valid(node):
		node.queue_free()


func get_streaming_status() -> Dictionary:
	return {
		"loaded_cell_count": loaded_cells.size(),
		"queued_load_count": pending_loads.size(),
		"queued_unload_count": pending_unloads.size(),
		"cell_size_m": cell_size,
		"sample_spacing_m": sample_spacing,
		"lod_geometry_enabled": false,
		"collision_streaming_enabled": true
	}
