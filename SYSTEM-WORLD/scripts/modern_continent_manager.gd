extends Node3D
class_name ModernContinentManager

## المرحلة الأولى من خريطة العالم الحديث: قارة متصلة، بحر، جزر، مواقع المدن وطرق رئيسية.
## التضاريس مولّدة حسابياً لتبقى خفيفة وقابلة للتوسعة.

const WORLD_WIDTH := 3000.0
const WORLD_DEPTH := 2200.0
const GRID_X := 151
const GRID_Z := 111
const CONTINENT_RADIUS_X := 1120.0
const CONTINENT_RADIUS_Z := 790.0

var terrain_height_data := PackedFloat32Array()

const CITY_DATA := [
	{"name": "New York", "x": -650.0, "z": -260.0},
	{"name": "London", "x": -420.0, "z": -90.0},
	{"name": "Paris", "x": -300.0, "z": 110.0},
	{"name": "Baghdad", "x": 0.0, "z": 0.0},
	{"name": "Moscow", "x": 120.0, "z": -470.0},
	{"name": "Cairo", "x": -80.0, "z": 330.0},
	{"name": "New Delhi", "x": 390.0, "z": 230.0},
	{"name": "Guangzhou", "x": 650.0, "z": 40.0},
	{"name": "Seoul", "x": 820.0, "z": -260.0},
	{"name": "Tokyo", "x": 1030.0, "z": 80.0},
	{"name": "Singapore", "x": 560.0, "z": 490.0},
	{"name": "Sydney", "x": 1050.0, "z": 680.0},
	{"name": "Rio de Janeiro", "x": -850.0, "z": 420.0},
	{"name": "Johannesburg", "x": -350.0, "z": 610.0}
]


func _ready() -> void:
	name = "ModernContinent"
	_build_ocean()
	_build_continent()
	_build_islands()
	_build_city_markers()
	_build_highways()
	print("SYSTEM WORLD: Modern continent terrain generated.")


func _continent_radius(x: float, z: float) -> float:
	var nx := x / CONTINENT_RADIUS_X
	var nz := z / CONTINENT_RADIUS_Z
	var wave := (
		sin(x * 0.0041) * 0.025
		+ sin(z * 0.0053) * 0.022
		+ sin((x + z) * 0.0027) * 0.018
	)
	return sqrt(nx * nx + nz * nz) + wave


func _island_radius(x: float, z: float, center: Vector2, radius_x: float, radius_z: float) -> float:
	var nx := (x - center.x) / radius_x
	var nz := (z - center.y) / radius_z
	return sqrt(nx * nx + nz * nz)


func _get_height(x: float, z: float) -> float:
	var radius := _continent_radius(x, z)
	if radius <= 1.0:
		if radius < 0.72:
			return 0.0
		var slope := (radius - 0.72) / 0.28
		return pow(clampf(slope, 0.0, 1.0), 1.45) * 72.0

	var islands := [
		{"center": Vector2(-1260.0, -520.0), "rx": 175.0, "rz": 125.0},
		{"center": Vector2(1250.0, -520.0), "rx": 190.0, "rz": 135.0},
		{"center": Vector2(1180.0, 850.0), "rx": 220.0, "rz": 150.0},
		{"center": Vector2(-1120.0, 820.0), "rx": 160.0, "rz": 120.0}
	]
	for island in islands:
		var island_r := _island_radius(
			x, z, island["center"], island["rx"], island["rz"]
		)
		if island_r < 1.0:
			return pow(1.0 - island_r, 1.25) * 24.0
	return -18.0


func _terrain_color(height: float, x: float, z: float) -> Color:
	if height < -2.0:
		return Color(0.035, 0.13, 0.19)
	if height < 1.0:
		return Color(0.72, 0.66, 0.48)
	if height < 18.0:
		return Color(0.24, 0.39, 0.22)
	if height < 42.0:
		return Color(0.29, 0.36, 0.25)
	return Color(0.43, 0.43, 0.40)


func _build_ocean() -> void:
	var ocean := MeshInstance3D.new()
	ocean.name = "WorldOcean"
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_WIDTH + 900.0, WORLD_DEPTH + 900.0)
	ocean.mesh = plane
	ocean.position.y = -2.2

	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.025, 0.16, 0.23, 1.0)
	water.metallic = 0.18
	water.roughness = 0.28
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	ocean.material_override = water
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ocean)


func _build_continent() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	terrain_height_data.resize(GRID_X * GRID_Z)

	var step_x := WORLD_WIDTH / float(GRID_X - 1)
	var step_z := WORLD_DEPTH / float(GRID_Z - 1)

	for z_index in range(GRID_Z):
		for x_index in range(GRID_X):
			var x := -WORLD_WIDTH * 0.5 + float(x_index) * step_x
			var z := -WORLD_DEPTH * 0.5 + float(z_index) * step_z
			var height := _get_height(x, z)
			var data_index := z_index * GRID_X + x_index
			terrain_height_data[data_index] = height
			vertices.append(Vector3(x, height, z))
			colors.append(_terrain_color(height, x, z))

	for z_index in range(GRID_Z - 1):
		for x_index in range(GRID_X - 1):
			var a := z_index * GRID_X + x_index
			var b := a + 1
			var c := a + GRID_X
			var d := c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var terrain_mesh := ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	terrain_mesh.surface_set_material(0, _make_terrain_material())

	var terrain_visual := MeshInstance3D.new()
	terrain_visual.name = "ContinentTerrainVisual"
	terrain_visual.mesh = terrain_mesh
	terrain_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(terrain_visual)

	var terrain_body := StaticBody3D.new()
	terrain_body.name = "ContinentTerrainCollision"
	var height_shape := HeightMapShape3D.new()
	height_shape.map_width = GRID_X
	height_shape.map_depth = GRID_Z
	height_shape.map_data = terrain_height_data
	var collision := CollisionShape3D.new()
	collision.shape = height_shape
	terrain_body.add_child(collision)
	add_child(terrain_body)


func _make_terrain_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _build_islands() -> void:
	var island_data := [
		{"name": "WesternIsle", "position": Vector3(-1260.0, 0.0, -520.0)},
		{"name": "EasternIsle", "position": Vector3(1250.0, 0.0, -520.0)},
		{"name": "SouthernIsle", "position": Vector3(1180.0, 0.0, 850.0)},
		{"name": "SouthwesternIsle", "position": Vector3(-1120.0, 0.0, 820.0)}
	]
	for item in island_data:
		var marker := Node3D.new()
		marker.name = str(item["name"])
		marker.position = item["position"]
		add_child(marker)


func _build_city_markers() -> void:
	for city in CITY_DATA:
		var x: float = city["x"]
		var z: float = city["z"]
		var marker := Node3D.new()
		marker.name = "CityMarker_" + str(city["name"]).replace(" ", "")
		marker.position = Vector3(x, _get_height(x, z), z)
		add_child(marker)

		var beacon := MeshInstance3D.new()
		beacon.name = "CityBeacon"
		var sphere := SphereMesh.new()
		sphere.radius = 2.8
		sphere.height = 5.6
		beacon.mesh = sphere
		beacon.position.y = 3.0
		var beacon_material := StandardMaterial3D.new()
		beacon_material.albedo_color = Color(0.12, 0.82, 1.0)
		beacon_material.emission_enabled = true
		beacon_material.emission = Color(0.04, 0.45, 0.9)
		beacon_material.emission_energy_multiplier = 1.5
		beacon.material_override = beacon_material
		marker.add_child(beacon)

		var label := Label3D.new()
		label.name = "CityName"
		label.text = str(city["name"])
		label.position = Vector3(0.0, 9.0, 0.0)
		label.font_size = 48
		label.outline_size = 8
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(0.72, 0.94, 1.0)
		marker.add_child(label)


func _build_highways() -> void:
	var routes := [
		[Vector3(0, 0.35, 0), Vector3(-300, 0.35, 100), Vector3(-650, 0.35, -260)],
		[Vector3(0, 0.35, 0), Vector3(120, 0.35, -250), Vector3(120, 0.35, -470)],
		[Vector3(0, 0.35, 0), Vector3(390, 0.35, 230), Vector3(650, 0.35, 40), Vector3(1030, 0.35, 80)],
		[Vector3(0, 0.35, 0), Vector3(-80, 0.35, 330), Vector3(-350, 0.35, 610)]
	]
	var road_material := StandardMaterial3D.new()
	road_material.albedo_color = Color(0.12, 0.14, 0.16)
	road_material.roughness = 0.9
	for route_index in range(routes.size()):
		var points: Array = routes[route_index]
		for segment_index in range(points.size() - 1):
			var start: Vector3 = points[segment_index]
			var finish: Vector3 = points[segment_index + 1]
			var midpoint := (start + finish) * 0.5
			var length := start.distance_to(finish)
			var road := MeshInstance3D.new()
			road.name = "ContinentalHighway_%02d_%02d" % [route_index, segment_index]
			var box := BoxMesh.new()
			box.size = Vector3(10.0, 0.18, length)
			road.mesh = box
			road.position = midpoint
			road.look_at(finish, Vector3.UP)
			road.material_override = road_material
			road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(road)
