
extends Node3D

# SYSTEM WORLD - Fantasy World
# Procedural 3D world foundation for mobile devices.

const WORLD_SIZE := 1200.0
const TERRAIN_RESOLUTION := 100
const CITY_RADIUS := 190.0

var terrain_noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()

var grass_mat: StandardMaterial3D
var mountain_mat: StandardMaterial3D
var water_mat: StandardMaterial3D
var road_mat: StandardMaterial3D
var wall_mat: StandardMaterial3D
var stone_mat: StandardMaterial3D
var wood_mat: StandardMaterial3D
var roof_mat: StandardMaterial3D
var leaf_mat: StandardMaterial3D
var castle_mat: StandardMaterial3D


func _ready() -> void:
	rng.seed = 73421
	_setup_materials()
	_setup_noise()
	_create_environment()
	_create_terrain()
	_create_river()
	_create_roads()
	_create_city_walls()
	_create_main_city()
	_create_forest()
	_create_mountain_landmarks()


func _setup_materials() -> void:
	grass_mat = _material(Color(0.19, 0.34, 0.17))
	mountain_mat = _material(Color(0.30, 0.29, 0.28))
	water_mat = _material(Color(0.08, 0.35, 0.55, 0.85))
	road_mat = _material(Color(0.32, 0.28, 0.22))
	wall_mat = _material(Color(0.48, 0.47, 0.43))
	stone_mat = _material(Color(0.55, 0.49, 0.39))
	wood_mat = _material(Color(0.28, 0.15, 0.08))
	roof_mat = _material(Color(0.30, 0.12, 0.10))
	leaf_mat = _material(Color(0.10, 0.27, 0.12))
	castle_mat = _material(Color(0.65, 0.59, 0.46))


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat


func _setup_noise() -> void:
	terrain_noise.seed = 92817
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = 0.006
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.48


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.72)
	environment.ambient_light_energy = 0.8
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sun.light_energy = 1.2
	add_child(sun)


func _terrain_height(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var mountain_factor := clampf((distance - 220.0) / 430.0, 0.0, 1.0)

	var noise_value := terrain_noise.get_noise_2d(x, z)
	var height := noise_value * 17.0
	height += mountain_factor * (35.0 + noise_value * 55.0)

	# Keep the central city area relatively flat.
	var city_flatten := clampf((distance - 145.0) / 100.0, 0.0, 1.0)
	height *= city_flatten

	return height


func _create_terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size := WORLD_SIZE / 2.0
	var step := WORLD_SIZE / float(TERRAIN_RESOLUTION)

	for z_index in range(TERRAIN_RESOLUTION + 1):
		for x_index in range(TERRAIN_RESOLUTION + 1):
			var x := -half_size + float(x_index) * step
			var z := -half_size + float(z_index) * step
			var y := _terrain_height(x, z)

			surface.add_vertex(Vector3(x, y, z))

	for z_index in range(TERRAIN_RESOLUTION):
		for x_index in range(TERRAIN_RESOLUTION):
			var a := z_index * (TERRAIN_RESOLUTION + 1) + x_index
			var b := a + 1
			var c := a + TERRAIN_RESOLUTION + 1
			var d := c + 1

			surface.add_index(a)
			surface.add_index(c)
			surface.add_index(b)

			surface.add_index(b)
			surface.add_index(c)
			surface.add_index(d)

	surface.generate_normals()

	var terrain_mesh := surface.commit()
	var terrain_instance := MeshInstance3D.new()
	terrain_instance.name = "FantasyTerrain"
	terrain_instance.mesh = terrain_mesh
	terrain_instance.material_override = grass_mat
	add_child(terrain_instance)

	var terrain_body := StaticBody3D.new()
	terrain_body.name = "TerrainCollision"

	var terrain_collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(terrain_mesh.get_faces())
	terrain_collision.shape = shape

	terrain_body.add_child(terrain_collision)
	add_child(terrain_body)


func _create_river() -> void:
	# A wide river running along the western side of the city.
	var river := MeshInstance3D.new()
	river.name = "MainRiver"

	var river_mesh := BoxMesh.new()
	river_mesh.size = Vector3(32.0, 1.0, 850.0)
	river.mesh = river_mesh
	river.material_override = water_mat
	river.position = Vector3(-280.0, 3.0, 0.0)
	river.rotation_degrees.y = -8.0
	add_child(river)


func _create_roads() -> void:
	# Main roads connecting the gates to the central plaza.
	_add_box(
		"NorthRoad",
		Vector3(0.0, 3.0, -90.0),
		Vector3(13.0, 0.5, 185.0),
		road_mat
	)

	_add_box(
		"SouthRoad",
		Vector3(0.0, 3.0, 90.0),
		Vector3(13.0, 0.5, 185.0),
		road_mat
	)

	_add_box(
		"EastRoad",
		Vector3(90.0, 3.0, 0.0),
		Vector3(185.0, 0.5, 13.0),
		road_mat
	)

	_add_box(
		"WestRoad",
		Vector3(-90.0, 3.0, 0.0),
		Vector3(185.0, 0.5, 13.0),
		road_mat
	)


func _create_city_walls() -> void:
	var wall_height := 18.0
	var wall_thickness := 9.0
	var wall_length := 370.0
	var wall_y := 10.0

	_add_box(
		"NorthCityWall",
		Vector3(0.0, wall_y, -185.0),
		Vector3(wall_length, wall_height, wall_thickness),
		wall_mat
	)

	_add_box(
		"SouthCityWall",
		Vector3(0.0, wall_y, 185.0),
		Vector3(wall_length, wall_height, wall_thickness),
		wall_mat
	)

	_add_box(
		"EastCityWall",
		Vector3(185.0, wall_y, 0.0),
		Vector3(wall_thickness, wall_height, wall_length),
		wall_mat
	)

	_add_box(
		"WestCityWall",
		Vector3(-185.0, wall_y, 0.0),
		Vector3(wall_thickness, wall_height, wall_length),
		wall_mat
	)

	# Four corner watchtowers.
	for x in [-185.0, 185.0]:
		for z in [-185.0, 185.0]:
			_create_tower(Vector3(x, 0.0, z), 25.0, 12.0)


func _create_main_city() -> void:
	# Central plaza.
	_add_box(
		"CentralPlaza",
		Vector3(0.0, 3.2, 0.0),
		Vector3(65.0, 1.0, 65.0),
		stone_mat
	)

	# Royal castle in the northern district.
	_create_castle(Vector3(0.0, 3.0, -115.0))

	# Market buildings.
	for i in range(6):
		var x := -130.0 + float(i) * 52.0
		_create_building(
			"MarketBuilding_" + str(i),
			Vector3(x, 3.0, 55.0),
			Vector3(24.0, 13.0, 22.0)
		)

	# Residential and craft districts.
	var building_index := 0

	for x in range(-140, 141, 55):
		for z in range(-45, 146, 55):
			if absf(float(x)) < 38.0 and absf(float(z)) < 38.0:
				continue

			if z < -70:
				continue

			if absf(float(x)) > 155.0:
				continue

			var height := rng.randf_range(9.0, 16.0)
			var width := rng.randf_range(15.0, 23.0)

			_create_building(
				"CityBuilding_" + str(building_index),
				Vector3(float(x), 3.0, float(z)),
				Vector3(width, height, width)
			)

			building_index += 1

	# Main entrance gates.
	_create_gate(Vector3(0.0, 3.0, 185.0), "SouthGate")
	_create_gate(Vector3(185.0, 3.0, 0.0), "EastGate")


func _create_castle(origin: Vector3) -> void:
	_add_box(
		"RoyalCastle",
		origin + Vector3(0.0, 19.0, 0.0),
		Vector3(72.0, 32.0, 58.0),
		castle_mat
	)

	for x in [-32.0, 32.0]:
		for z in [-25.0, 25.0]:
			_create_tower(
				origin + Vector3(x, 3.0, z),
				34.0,
				10.0
			)

	_add_box(
		"CastleEntrance",
		origin + Vector3(0.0, 12.0, 31.0),
		Vector3(19.0, 22.0, 8.0),
		stone_mat
	)


func _create_tower(
	origin: Vector3,
	height: float,
	width: float
) -> void:
	_add_box(
		"StoneTower",
		origin + Vector3(0.0, height / 2.0, 0.0),
		Vector3(width, height, width),
		wall_mat
	)

	var roof := MeshInstance3D.new()
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = width * 0.72
	roof_mesh.height = height * 0.35
	roof.mesh = roof_mesh
	roof.material_override = roof_mat
	roof.position = origin + Vector3(0.0, height + height * 0.17, 0.0)
	add_child(roof)


func _create_building(
	building_name: String,
	origin: Vector3,
	dimensions: Vector3
) -> void:
	_add_box(
		building_name,
		origin + Vector3(0.0, dimensions.y / 2.0, 0.0),
		dimensions,
		wood_mat
	)

	var roof := MeshInstance3D.new()
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = maxf(dimensions.x, dimensions.z) * 0.75
	roof_mesh.height = dimensions.y * 0.35
	roof.mesh = roof_mesh
	roof.material_override = roof_mat
	roof.position = origin + Vector3(
		0.0,
		dimensions.y + dimensions.y * 0.16,
		0.0
	)
	add_child(roof)


func _create_gate(origin: Vector3, gate_name: String) -> void:
	_add_box(
		gate_name + "_Left",
		origin + Vector3(-11.0, 11.0, 0.0),
		Vector3(9.0, 22.0, 12.0),
		wall_mat
	)

	_add_box(
		gate_name + "_Right",
		origin + Vector3(11.0, 11.0, 0.0),
		Vector3(9.0, 22.0, 12.0),
		wall_mat
	)

	_add_box(
		gate_name + "_Top",
		origin + Vector3(0.0, 23.0, 0.0),
		Vector3(31.0, 7.0, 13.0),
		castle_mat
	)


func _create_forest() -> void:
	# Trees are kept outside the central city.
	for i in range(260):
		var x := rng.randf_range(-560.0, 560.0)
		var z := rng.randf_range(-560.0, 560.0)

		var distance := Vector2(x, z).length()

		if distance < 235.0:
			continue

		# Leave room around the river.
		if absf(x + 280.0) < 35.0:
			continue

		var ground_y := _terrain_height(x, z)
		_create_tree(Vector3(x, ground_y, z))


func _create_tree(origin: Vector3) -> void:
	var trunk_height := rng.randf_range(5.0, 9.0)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.65
	trunk_mesh.bottom_radius = 1.0
	trunk_mesh.height = trunk_height
	trunk.mesh = trunk_mesh
	trunk.material_override = wood_mat
	trunk.position = origin + Vector3(0.0, trunk_height / 2.0, 0.0)
	add_child(trunk)

	var leaves := MeshInstance3D.new()
	var leaves_mesh := SphereMesh.new()
	leaves_mesh.radius = rng.randf_range(3.0, 5.0)
	leaves_mesh.height = leaves_mesh.radius * 2.0
	leaves.mesh = leaves_mesh
	leaves.material_override = leaf_mat
	leaves.position = origin + Vector3(0.0, trunk_height + 2.0, 0.0)
	add_child(leaves)


func _create_mountain_landmarks() -> void:
	# Distant mountain peaks around the world.
	var peaks := [
		Vector3(-430.0, 0.0, -390.0),
		Vector3(420.0, 0.0, -410.0),
		Vector3(450.0, 0.0, 390.0),
		Vector3(-420.0, 0.0, 410.0)
	]

	for i in range(peaks.size()):
		var peak := peaks[i]
		var ground_y := _terrain_height(peak.x, peak.z)

		var mountain := MeshInstance3D.new()
		var mountain_mesh := CylinderMesh.new()
		mountain_mesh.top_radius = 0.0
		mountain_mesh.bottom_radius = 90.0
		mountain_mesh.height = 145.0
		mountain.mesh = mountain_mesh
		mountain.material_override = mountain_mat
		mountain.position = Vector3(
			peak.x,
			ground_y + 65.0,
			peak.z
		)
		add_child(mountain)


func _add_box(
	object_name: String,
	object_position: Vector3,
	object_size: Vector3,
	material: Material
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = object_name

	var box := BoxMesh.new()
	box.size = object_size

	instance.mesh = box
	instance.material_override = material
	instance.position = object_position
	add_child(instance)
