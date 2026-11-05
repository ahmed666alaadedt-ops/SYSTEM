
extends Node3D
class_name SystemMountainManager

const MOUNTAIN_COUNT := 5
const GRID_STEPS := 18
const MOUNTAIN_WIDTH := 68.0
const MOUNTAIN_DEPTH := 58.0

var rng := RandomNumberGenerator.new()
var mountain_material: StandardMaterial3D


func _ready() -> void:
	rng.randomize()
	_create_material()
	_create_mountain_range()
	print("SYSTEM WORLD: Mountain range initialized.")


func _create_material() -> void:
	mountain_material = StandardMaterial3D.new()
	mountain_material.vertex_color_use_as_albedo = true
	mountain_material.roughness = 1.0


func _create_mountain_range() -> void:
	var positions := [-110.0, -55.0, 0.0, 55.0, 110.0]

	for index in range(MOUNTAIN_COUNT):
		_create_mountain(
			index,
			positions[index],
			-160.0 + rng.randf_range(-8.0, 8.0)
		)


func _create_mountain(index: int, world_x: float, world_z: float) -> void:
	var mountain_body := StaticBody3D.new()
	mountain_body.name = "Mountain_%02d" % index
	mountain_body.position = Vector3(world_x, 0.0, world_z)
	add_child(mountain_body)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(mountain_material)

	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []

	var peak_height := rng.randf_range(38.0, 55.0)
	var peak_x := rng.randf_range(-0.16, 0.16)
	var peak_z := rng.randf_range(-0.12, 0.12)

	for z_index in range(GRID_STEPS + 1):
		for x_index in range(GRID_STEPS + 1):
			var nx := float(x_index) / float(GRID_STEPS)
			var nz := float(z_index) / float(GRID_STEPS)

			var local_x := (nx - 0.5) * MOUNTAIN_WIDTH
			var local_z := (nz - 0.5) * MOUNTAIN_DEPTH

			var height := _calculate_height(
				nx,
				nz,
				peak_x,
				peak_z,
				peak_height
			)

			var vertex := Vector3(local_x, height, local_z)
			vertices.append(vertex)

			colors.append(_get_terrain_color(height, peak_height))

	for z_index in range(GRID_STEPS):
		for x_index in range(GRID_STEPS):
			var a := z_index * (GRID_STEPS + 1) + x_index
			var b := a + 1
			var c := a + GRID_STEPS + 1
			var d := c + 1

			_add_triangle(surface, vertices, colors, a, c, b)
			_add_triangle(surface, vertices, colors, b, c, d)

	var mountain_mesh := surface.commit()

	var visual := MeshInstance3D.new()
	visual.name = "MountainTerrain"
	visual.mesh = mountain_mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mountain_body.add_child(visual)

	_create_mountain_collision(mountain_body, vertices)


func _calculate_height(
	nx: float,
	nz: float,
	peak_x: float,
	peak_z: float,
	peak_height: float
) -> float:
	var dx := (nx - 0.5 - peak_x) / 0.36
	var dz := (nz - 0.5 - peak_z) / 0.40

	var main_peak := exp(
		-(dx * dx + dz * dz) * 2.4
	) * peak_height

	var ridge_dx := (nx - 0.28) / 0.22
	var ridge_dz := (nz - 0.55) / 0.48

	var secondary_ridge := exp(
		-(ridge_dx * ridge_dx + ridge_dz * ridge_dz) * 2.0
	) * peak_height * 0.35

	var edge_x := sin(nx * PI)
	var edge_z := sin(nz * PI)
	var edge_factor := pow(maxf(0.0, edge_x * edge_z), 0.55)

	var roughness := rng.randf_range(-1.8, 1.8)

	var final_height := (
		(main_peak + secondary_ridge + roughness) * edge_factor
	)

	return maxf(0.0, final_height)


func _get_terrain_color(height: float, peak_height: float) -> Color:
	var ratio := height / peak_height

	if ratio > 0.82:
		return Color(0.88, 0.91, 0.94)

	if ratio > 0.63:
		return Color(0.43, 0.43, 0.40)

	if ratio > 0.35:
		return Color(0.32, 0.30, 0.25)

	if ratio > 0.12:
		return Color(0.24, 0.30, 0.19)

	return Color(0.20, 0.25, 0.16)


func _add_triangle(
	surface: SurfaceTool,
	vertices: Array[Vector3],
	colors: Array[Color],
	a: int,
	b: int,
	c: int
) -> void:
	surface.set_color(colors[a])
	surface.add_vertex(vertices[a])

	surface.set_color(colors[b])
	surface.add_vertex(vertices[b])

	surface.set_color(colors[c])
	surface.add_vertex(vertices[c])


func _create_mountain_collision(
	parent: StaticBody3D,
	vertices: Array[Vector3]
) -> void:
	var faces := PackedVector3Array()
	var row_size := GRID_STEPS + 1

	for z_index in range(GRID_STEPS):
		for x_index in range(GRID_STEPS):
			var a := z_index * row_size + x_index
			var b := a + 1
			var c := a + row_size
			var d := c + 1

			faces.append(vertices[a])
			faces.append(vertices[c])
			faces.append(vertices[b])

			faces.append(vertices[b])
			faces.append(vertices[c])
			faces.append(vertices[d])

	var collision_shape := ConcavePolygonShape3D.new()
	collision_shape.set_faces(faces)

	var collision := CollisionShape3D.new()
	collision.name = "MountainCollision"
	collision.shape = collision_shape
	parent.add_child(collision)
