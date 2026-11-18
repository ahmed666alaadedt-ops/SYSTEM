extends Node3D
class_name ModernContinentManager

## Procedural terrain foundation for the connected modern world.
## The map is fictional; city names are real-world references only.

const WORLD_WIDTH := 3000.0
const WORLD_DEPTH := 2200.0
const GRID_X := 151
const GRID_Z := 111
const CONTINENT_RADIUS_X := 1120.0
const CONTINENT_RADIUS_Z := 790.0
const SEA_LEVEL := 0.0
const OCEAN_FLOOR := -24.0

var terrain_height_data := PackedFloat32Array()
var terrain_step_x := WORLD_WIDTH / float(GRID_X - 1)
var terrain_step_z := WORLD_DEPTH / float(GRID_Z - 1)

const ISLAND_DATA := [
	{"name": "WesternIsle", "center": Vector2(-1260.0, -520.0), "rx": 175.0, "rz": 125.0, "height": 38.0},
	{"name": "EasternIsle", "center": Vector2(1250.0, -520.0), "rx": 190.0, "rz": 135.0, "height": 46.0},
	{"name": "SouthernIsle", "center": Vector2(1180.0, 850.0), "rx": 220.0, "rz": 150.0, "height": 54.0},
	{"name": "SouthwesternIsle", "center": Vector2(-1120.0, 820.0), "rx": 160.0, "rz": 120.0, "height": 32.0}
]

const RIVER_ROUTES := [
	[Vector2(430.0, -390.0), Vector2(330.0, -280.0), Vector2(210.0, -170.0), Vector2(90.0, -65.0), Vector2(0.0, 0.0)],
	[Vector2(-610.0, 260.0), Vector2(-470.0, 190.0), Vector2(-310.0, 120.0), Vector2(-145.0, 55.0), Vector2(0.0, 0.0)],
	[Vector2(760.0, 430.0), Vector2(610.0, 350.0), Vector2(470.0, 260.0), Vector2(330.0, 170.0)]
]

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
	_build_rivers_and_lakes()
	print("SYSTEM WORLD: modern continent terrain generated.")


func _continent_radius(x: float, z: float) -> float:
	var nx := x / CONTINENT_RADIUS_X
	var nz := z / CONTINENT_RADIUS_Z
	var coast_wave := (
		sin(x * 0.0041) * 0.025
		+ sin(z * 0.0053) * 0.022
		+ sin((x + z) * 0.0027) * 0.018
		+ sin((x - z) * 0.007) * 0.009
	)
	return sqrt(nx * nx + nz * nz) + coast_wave


func _island_radius(x: float, z: float, center: Vector2, radius_x: float, radius_z: float) -> float:
	var nx := (x - center.x) / radius_x
	var nz := (z - center.y) / radius_z
	return sqrt(nx * nx + nz * nz)


func _gaussian_peak(x: float, z: float, center: Vector2, radius_x: float, radius_z: float, strength: float) -> float:
	var nx := (x - center.x) / radius_x
	var nz := (z - center.y) / radius_z
	return strength * exp(-((nx * nx) + (nz * nz)) * 1.7)


func _land_base_height(x: float, z: float) -> float:
	var broad_hills := (
		sin(x * 0.0032 + z * 0.0011) * 7.0
		+ sin(z * 0.0044 - x * 0.0017) * 5.0
		+ sin((x + z) * 0.008) * 2.0
	)
	var rolling_detail := (
		sin(x * 0.018) * sin(z * 0.014) * 1.8
		+ sin((x - z) * 0.025) * 0.9
	)
	var mountain_belts := 0.0
	mountain_belts += _gaussian_peak(x, z, Vector2(430.0, -390.0), 230.0, 430.0, 112.0)
	mountain_belts += _gaussian_peak(x, z, Vector2(-610.0, 260.0), 270.0, 170.0, 76.0)
	mountain_belts += _gaussian_peak(x, z, Vector2(760.0, 430.0), 210.0, 250.0, 68.0)
	mountain_belts += _gaussian_peak(x, z, Vector2(-80.0, -650.0), 350.0, 115.0, 54.0)

	# A low basin through the central region creates a broad valley around the starting area.
	var central_basin := _gaussian_peak(x, z, Vector2(0.0, 0.0), 390.0, 280.0, -7.0)
	var river_carving := _river_channel_depth(x, z)
	var lake_basin := _lake_basin_depth(x, z)
	return broad_hills + rolling_detail + mountain_belts + central_basin - river_carving - lake_basin


func _get_height(x: float, z: float) -> float:
	var radius := _continent_radius(x, z)
	if radius <= 1.0:
		var coast_factor := clampf((1.0 - radius) / 0.10, 0.0, 1.0)
		var coast_ease := coast_factor * coast_factor * (3.0 - 2.0 * coast_factor)
		var interior_height := _land_base_height(x, z)
		return lerpf(SEA_LEVEL - 1.2, interior_height, coast_ease)

	for island in ISLAND_DATA:
		var island_radius_value := _island_radius(
			x, z, island["center"], island["rx"], island["rz"]
		)
		if island_radius_value < 1.0:
			var island_shape := pow(1.0 - island_radius_value, 1.25)
			var island_ridge := sin(x * 0.025 + z * 0.012) * 2.0
			return island_shape * float(island["height"]) + island_ridge

	return OCEAN_FLOOR


# Public terrain sampling API for world systems such as forests, paths and NPCs.
func get_terrain_height(x: float, z: float) -> float:
	if terrain_height_data.size() != GRID_X * GRID_Z:
		return _get_height(x, z)

	var grid_x := clampf((x + WORLD_WIDTH * 0.5) / terrain_step_x, 0.0, float(GRID_X - 1))
	var grid_z := clampf((z + WORLD_DEPTH * 0.5) / terrain_step_z, 0.0, float(GRID_Z - 1))
	var x0 := int(floor(grid_x))
	var z0 := int(floor(grid_z))
	var x1 := mini(x0 + 1, GRID_X - 1)
	var z1 := mini(z0 + 1, GRID_Z - 1)
	var tx := grid_x - float(x0)
	var tz := grid_z - float(z0)

	var h00 := terrain_height_data[z0 * GRID_X + x0]
	var h10 := terrain_height_data[z0 * GRID_X + x1]
	var h01 := terrain_height_data[z1 * GRID_X + x0]
	var h11 := terrain_height_data[z1 * GRID_X + x1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func is_land_position(x: float, z: float) -> bool:
	return _get_height(x, z) > SEA_LEVEL + 0.5


func _terrain_color(height: float, x: float, z: float) -> Color:
	if height > 92.0:
		return Color(0.88, 0.91, 0.94)
	if x < -520.0 and z > 260.0 and height < 48.0:
		return Color(0.68, 0.55, 0.34)
	if x > -360.0 and x < 300.0 and z < -260.0 and height < 65.0:
		return Color(0.12, 0.29, 0.16)
	if height < 1.0:
		return Color(0.72, 0.66, 0.49)
	if height < 16.0:
		return Color(0.25, 0.43, 0.24)
	if height < 38.0:
		return Color(0.34, 0.39, 0.25)
	if height < 75.0:
		return Color(0.38, 0.36, 0.29)
	return Color(0.48, 0.47, 0.43)


func _build_ocean() -> void:
	var ocean := MeshInstance3D.new()
	ocean.name = "WorldOcean"
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_WIDTH + 1100.0, WORLD_DEPTH + 1100.0)
	ocean.mesh = plane
	ocean.position.y = SEA_LEVEL - 1.8

	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.025, 0.16, 0.23, 1.0)
	water.metallic = 0.18
	water.roughness = 0.24
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	ocean.material_override = water
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ocean)


func _build_continent() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	terrain_height_data.resize(GRID_X * GRID_Z)

	for z_index in range(GRID_Z):
		for x_index in range(GRID_X):
			var x := -WORLD_WIDTH * 0.5 + float(x_index) * terrain_step_x
			var z := -WORLD_DEPTH * 0.5 + float(z_index) * terrain_step_z
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
			var average_height := (
				terrain_height_data[a] + terrain_height_data[b]
				+ terrain_height_data[c] + terrain_height_data[d]
			) * 0.25
			if average_height > SEA_LEVEL - 0.6:
				indices.append_array(PackedInt32Array([a, c, b, b, c, d]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var terrain_mesh := ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if terrain_mesh.get_surface_count() > 0:
		terrain_mesh.surface_set_material(0, _make_terrain_material())

	var terrain_visual := MeshInstance3D.new()
	terrain_visual.name = "ContinentTerrainVisual"
	terrain_visual.mesh = terrain_mesh
	terrain_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(terrain_visual)

	# HeightMapShape3D is centered around its local origin; scale it to match
	# the generated terrain grid spacing and place its center over the world.
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "ContinentTerrainCollision"
	var height_shape := HeightMapShape3D.new()
	height_shape.map_width = GRID_X
	height_shape.map_depth = GRID_Z
	height_shape.map_data = terrain_height_data
	var collision := CollisionShape3D.new()
	collision.shape = height_shape
	collision.scale = Vector3(terrain_step_x, 1.0, terrain_step_z)
	collision.position = Vector3(0.0, 0.0, 0.0)
	terrain_body.add_child(collision)
	add_child(terrain_body)


func _make_terrain_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.96
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _build_islands() -> void:
	# Islands are sculpted directly into the same connected terrain mesh and collision.
	for island in ISLAND_DATA:
		var center: Vector2 = island["center"]
		var marker := Node3D.new()
		marker.name = str(island["name"])
		marker.position = Vector3(
			center.x,
			_get_height(center.x, center.y),
			center.y
		)
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
		_build_city_silhouette(marker, x, z, CITY_DATA.find(city))


func _build_city_silhouette(
	city_root: Node3D,
	city_x: float,
	city_z: float,
	city_index: int
) -> void:
	# Lightweight procedural skyline blocks establish a distinct 3D footprint
	# for every named city while keeping draw calls low through MultiMesh.
	var palettes := [
		Color(0.28, 0.36, 0.44), Color(0.42, 0.43, 0.41),
		Color(0.34, 0.38, 0.46), Color(0.48, 0.42, 0.32),
		Color(0.31, 0.37, 0.39), Color(0.43, 0.39, 0.33)
	]
	var building_material := StandardMaterial3D.new()
	building_material.albedo_color = palettes[city_index % palettes.size()]
	building_material.roughness = 0.76
	building_material.metallic = 0.12

	var building_mesh := BoxMesh.new()
	building_mesh.size = Vector3.ONE
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = building_mesh

	var transforms: Array[Transform3D] = []
	var spacing := 27.0
	for grid_z in range(-2, 3):
		for grid_x in range(-2, 3):
			if grid_x == 0 and grid_z == 0:
				continue
			var offset_x := float(grid_x) * spacing
			var offset_z := float(grid_z) * spacing
			var world_x := city_x + offset_x
			var world_z := city_z + offset_z
			if not is_land_position(world_x, world_z):
				continue

			var ground_height := get_terrain_height(world_x, world_z)
			var city_base_height := city_root.position.y
			if absf(ground_height - city_base_height) > 18.0:
				continue

			var seed_value := absf(sin(float(city_index * 71 + grid_x * 19 + grid_z * 37)))
			var width := 9.0 + seed_value * 7.0
			var depth := 9.0 + absf(cos(seed_value * 8.0)) * 6.0
			var height := 13.0 + seed_value * 48.0
			var local_position := Vector3(
				offset_x,
				ground_height - city_base_height + height * 0.5,
				offset_z
			)
			var scale := Vector3(width, height, depth)
			transforms.append(Transform3D(Basis().scaled(scale), local_position))

	if transforms.is_empty():
		return

	multi_mesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi_mesh.set_instance_transform(index, transforms[index])

	var skyline := MultiMeshInstance3D.new()
	skyline.name = "CityDistrictBuildings"
	skyline.multimesh = multi_mesh
	skyline.material_override = building_material
	skyline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	city_root.add_child(skyline)


func _build_highways() -> void:
	var routes := [
		[Vector2(0, 0), Vector2(-300, 100), Vector2(-650, -260)],
		[Vector2(0, 0), Vector2(120, -250), Vector2(120, -470)],
		[Vector2(0, 0), Vector2(390, 230), Vector2(650, 40), Vector2(1030, 80)],
		[Vector2(0, 0), Vector2(-80, 330), Vector2(-350, 610)]
	]
	var road_material := StandardMaterial3D.new()
	road_material.albedo_color = Color(0.12, 0.14, 0.16)
	road_material.roughness = 0.9

	var road_surface := SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	road_surface.set_material(road_material)
	for route_index in range(routes.size()):
		var points: Array = routes[route_index]
		for segment_index in range(points.size() - 1):
			var start_2d: Vector2 = points[segment_index]
			var finish_2d: Vector2 = points[segment_index + 1]
			var subdivisions := 8
			for step in range(subdivisions):
				var t0 := float(step) / float(subdivisions)
				var t1 := float(step + 1) / float(subdivisions)
				var a := start_2d.lerp(finish_2d, t0)
				var b := start_2d.lerp(finish_2d, t1)
				var direction := (b - a).normalized()
				var side := Vector2(-direction.y, direction.x) * 5.0
				var a_left := a + side
				var a_right := a - side
				var b_left := b + side
				var b_right := b - side
				var a_y := _get_height(a.x, a.y) + 0.38
				var b_y := _get_height(b.x, b.y) + 0.38
				_add_surface_quad(
					road_surface,
					Vector3(a_left.x, a_y, a_left.y),
					Vector3(a_right.x, a_y, a_right.y),
					Vector3(b_left.x, b_y, b_left.y),
					Vector3(b_right.x, b_y, b_right.y)
				)
	road_surface.generate_normals()
	var road_visual := MeshInstance3D.new()
	road_visual.name = "ContinentalHighwayNetwork"
	road_visual.mesh = road_surface.commit()
	road_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road_visual)


# --------------------------------------------------
# NATURAL WATER NETWORK
# --------------------------------------------------

func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _lake_basin_depth(x: float, z: float) -> float:
	var depth := 0.0
	var lake_centers := [
		{"center": Vector2(250.0, 165.0), "radius_x": 44.0, "radius_z": 32.0, "depth": 9.0},
		{"center": Vector2(-430.0, -70.0), "radius_x": 36.0, "radius_z": 27.0, "depth": 7.0}
	]
	for lake in lake_centers:
		var center: Vector2 = lake["center"]
		var nx := (x - center.x) / float(lake["radius_x"])
		var nz := (z - center.y) / float(lake["radius_z"])
		var distance_squared := nx * nx + nz * nz
		if distance_squared < 1.0:
			depth = maxf(depth, float(lake["depth"]) * exp(-distance_squared * 1.65))
	return depth


func _river_channel_depth(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var nearest_distance := 100000.0
	for route in RIVER_ROUTES:
		for index in range(route.size() - 1):
			nearest_distance = minf(
				nearest_distance,
				_distance_to_segment(point, route[index], route[index + 1])
			)
	if nearest_distance >= 9.0:
		return 0.0
	var blend := 1.0 - nearest_distance / 9.0
	return 2.8 * blend * blend


func _build_rivers_and_lakes() -> void:
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.035, 0.29, 0.39, 0.92)
	water_material.metallic = 0.16
	water_material.roughness = 0.2
	water_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var river_surface := SurfaceTool.new()
	river_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	river_surface.set_material(water_material)
	for route_index in range(RIVER_ROUTES.size()):
		var route: Array = RIVER_ROUTES[route_index]
		for point_index in range(route.size() - 1):
			var start_2d: Vector2 = route[point_index]
			var finish_2d: Vector2 = route[point_index + 1]
			var subdivisions := 12
			for step in range(subdivisions):
				var t0 := float(step) / float(subdivisions)
				var t1 := float(step + 1) / float(subdivisions)
				var a := start_2d.lerp(finish_2d, t0)
				var b := start_2d.lerp(finish_2d, t1)
				var direction := (b - a).normalized()
				var bank_offset := Vector2(-direction.y, direction.x) * 4.0
				var a_left := a + bank_offset
				var a_right := a - bank_offset
				var b_left := b + bank_offset
				var b_right := b - bank_offset
				var a_y := _get_height(a.x, a.y) + 0.42
				var b_y := _get_height(b.x, b.y) + 0.42
				_add_surface_quad(
					river_surface,
					Vector3(a_left.x, a_y, a_left.y),
					Vector3(a_right.x, a_y, a_right.y),
					Vector3(b_left.x, b_y, b_left.y),
					Vector3(b_right.x, b_y, b_right.y)
				)
	river_surface.generate_normals()
	var river_visual := MeshInstance3D.new()
	river_visual.name = "ConnectedRiverNetwork"
	river_visual.mesh = river_surface.commit()
	river_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(river_visual)
	_build_mountain_waterfalls()

	var lake_data := [
		{"name": "CentralLake", "center": Vector2(250.0, 165.0), "size": Vector2(58.0, 42.0)},
		{"name": "WesternLake", "center": Vector2(-430.0, -70.0), "size": Vector2(42.0, 30.0)}
	]
	for lake in lake_data:
		var center: Vector2 = lake["center"]
		var lake_node := MeshInstance3D.new()
		lake_node.name = str(lake["name"])
		var lake_mesh := PlaneMesh.new()
		lake_mesh.size = lake["size"]
		lake_mesh.subdivide_width = 12
		lake_mesh.subdivide_depth = 12
		lake_node.mesh = lake_mesh
		lake_node.position = Vector3(
			center.x,
			_get_height(center.x, center.y) + (6.5 if str(lake["name"]) == "CentralLake" else 5.0),
			center.y
		)
		lake_node.material_override = water_material
		lake_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lake_node)


func _add_surface_quad(
	surface: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3
) -> void:
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(d)


func _build_mountain_waterfalls() -> void:
	# Add a vertical water sheet only where a river segment crosses a meaningful
	# terrain drop. This keeps waterfalls tied to the actual mountain profile.
	var waterfall_material := StandardMaterial3D.new()
	waterfall_material.albedo_color = Color(0.20, 0.72, 0.86, 0.86)
	waterfall_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	waterfall_material.roughness = 0.18
	waterfall_material.metallic = 0.08
	waterfall_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var waterfall_surface := SurfaceTool.new()
	waterfall_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	waterfall_surface.set_material(waterfall_material)
	var waterfall_count := 0

	for route in RIVER_ROUTES:
		for index in range(route.size() - 1):
			var start: Vector2 = route[index]
			var finish: Vector2 = route[index + 1]
			var start_height := _get_height(start.x, start.y)
			var finish_height := _get_height(finish.x, finish.y)
			var drop := absf(start_height - finish_height)
			if drop < 14.0:
				continue

			var high_point := start if start_height > finish_height else finish
			var low_point := finish if start_height > finish_height else start
			var midpoint := high_point.lerp(low_point, 0.5)
			var direction := (low_point - high_point).normalized()
			var side := Vector2(-direction.y, direction.x) * 3.4
			var top_y := _get_height(midpoint.x, midpoint.y) + drop * 0.5
			var bottom_y := _get_height(low_point.x, low_point.y) + 0.55
			var left_top := Vector3(midpoint.x + side.x, top_y, midpoint.y + side.y)
			var right_top := Vector3(midpoint.x - side.x, top_y, midpoint.y - side.y)
			var left_bottom := Vector3(midpoint.x + side.x, bottom_y, midpoint.y + side.y)
			var right_bottom := Vector3(midpoint.x - side.x, bottom_y, midpoint.y - side.y)

			_add_surface_quad(
				waterfall_surface,
				left_top,
				right_top,
				left_bottom,
				right_bottom
			)
			waterfall_count += 1

	if waterfall_count == 0:
		return

	waterfall_surface.generate_normals()
	var waterfall_visual := MeshInstance3D.new()
	waterfall_visual.name = "MountainWaterfalls"
	waterfall_visual.mesh = waterfall_surface.commit()
	waterfall_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(waterfall_visual)
	print("SYSTEM WORLD: generated ", waterfall_count, " terrain-based waterfalls.")
