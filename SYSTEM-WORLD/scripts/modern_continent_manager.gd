extends Node3D
class_name ModernContinentManager

## Procedural terrain foundation for the connected modern world.
## The map is fictional; city names are real-world references only.

const WORLD_WIDTH := 8000.0
const WORLD_DEPTH := 4000.0
const GRID_X := 151
const GRID_Z := 111
const CONTINENT_RADIUS_X := 1120.0
const CONTINENT_RADIUS_Z := 790.0
const SEA_LEVEL := 0.0
const OCEAN_FLOOR := -24.0
const TerrainCellStreamingManagerScript = preload("res://scripts/modern_world_cell_streaming_manager.gd")

var terrain_height_data := PackedFloat32Array()
var terrain_step_x := WORLD_WIDTH / float(GRID_X - 1)
var terrain_step_z := WORLD_DEPTH / float(GRID_Z - 1)
var baghdad_bridge_center := Vector2.ZERO
var baghdad_bridge_centerline: Array[Vector2] = []
var baghdad_bridge_secondary_centerline: Array[Vector2] = []
var baghdad_bridge_outline := PackedVector2Array()
var baghdad_tigris_route: Array[Vector2] = []
var baghdad_bridge_reference_loaded := false

const BAGHDAD_LAND_RADIUS_X := 1100.0
const BAGHDAD_LAND_RADIUS_Z := 1000.0
const BAGHDAD_URBAN_CORRIDOR_HALF_WIDTH := 560.0
const BAGHDAD_TIGRIS_HALF_WIDTH := 155.0
const BAGHDAD_TIGRIS_DEPTH := 22.0
const BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT := 18.0

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
	_load_baghdad_bridge_reference()
	_build_ocean()
	_setup_terrain_streaming()
	_build_coastal_beaches()
	_build_islands()
	_build_cave_entrances()
	_build_city_markers()
	_build_highways()
	_build_rivers_and_lakes()
	_build_baghdad_tigris_surface()
	_build_baghdad_republic_bridge()
	_build_baghdad_bridge_access_causeway()
	print("SYSTEM WORLD: modern continent terrain generated.")


func _load_baghdad_bridge_reference() -> void:
	var path := "res://data/geography/baghdad/republic_bridge_reference.json"
	if not FileAccess.file_exists(path):
		push_warning("SYSTEM Baghdad geography: verified Republic Bridge reference is unavailable.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or str(parsed.get("region_id", "")) != "iraq_baghdad_region":
		push_error("SYSTEM Baghdad geography: Republic Bridge reference is invalid.")
		return
	var source: Dictionary = parsed.get("source", {})
	if str(source.get("license", "")) != "ODbL-1.0" or int(source.get("source_artifact_id", 0)) != 14629100933:
		push_error("SYSTEM Baghdad geography: Republic Bridge source provenance is invalid.")
		return
	var bridge: Dictionary = parsed.get("republic_bridge", {})
	var center: Dictionary = bridge.get("center_local_m", {})
	baghdad_bridge_center = Vector2(float(center.get("east", 0.0)), float(center.get("south", 0.0)))
	for point_value in bridge.get("centerline_local_m", []):
		if point_value is Dictionary:
			baghdad_bridge_centerline.append(Vector2(float(point_value.get("east_m", 0.0)), float(point_value.get("south_m", 0.0))))
	for point_value in bridge.get("secondary_centerline_local_m", []):
		if point_value is Dictionary:
			baghdad_bridge_secondary_centerline.append(Vector2(float(point_value.get("east_m", 0.0)), float(point_value.get("south_m", 0.0))))
	for point_value in bridge.get("polygon_outline_local_m", []):
		if point_value is Dictionary:
			baghdad_bridge_outline.append(Vector2(float(point_value.get("east_m", 0.0)), float(point_value.get("south_m", 0.0))))
	var river: Dictionary = parsed.get("tigris_river", {})
	for point_value in river.get("centerline_local_m", []):
		if point_value is Dictionary:
			baghdad_tigris_route.append(Vector2(float(point_value.get("east_m", 0.0)), float(point_value.get("south_m", 0.0))))
	if baghdad_bridge_centerline.size() < 2 or baghdad_bridge_secondary_centerline.size() < 2 or baghdad_bridge_outline.size() < 3 or baghdad_tigris_route.size() < 2:
		push_error("SYSTEM Baghdad geography: Republic Bridge or Tigris geometry is incomplete.")
		baghdad_bridge_centerline.clear()
		baghdad_tigris_route.clear()
		return
	baghdad_bridge_reference_loaded = true
	print("SYSTEM Baghdad geography: Republic Bridge OSM way 1077808833 and Tigris way 24709603 loaded.")


func get_baghdad_bridge_anchor() -> Vector3:
	if not baghdad_bridge_reference_loaded:
		return Vector3.INF
	return Vector3(baghdad_bridge_center.x, get_terrain_height(baghdad_bridge_center.x, baghdad_bridge_center.y), baghdad_bridge_center.y)


func _baghdad_bridge_nearest_bank_point() -> Vector2:
	if not baghdad_bridge_reference_loaded or baghdad_bridge_centerline.size() < 2:
		return Vector2.INF
	var nearest_bank: Vector2 = baghdad_bridge_centerline[0]
	var opposite_bank: Vector2 = baghdad_bridge_centerline[baghdad_bridge_centerline.size() - 1]
	if opposite_bank.length_squared() < nearest_bank.length_squared():
		nearest_bank = opposite_bank
	return nearest_bank


func get_baghdad_bridge_nearest_bank_anchor() -> Vector3:
	var nearest_bank := _baghdad_bridge_nearest_bank_point()
	if nearest_bank == Vector2.INF:
		return Vector3.INF
	return Vector3(nearest_bank.x, get_terrain_height(nearest_bank.x, nearest_bank.y), nearest_bank.y)


func _baghdad_tigris_channel_depth(x: float, z: float) -> float:
	if not baghdad_bridge_reference_loaded:
		return 0.0
	var point := Vector2(x, z)
	var nearest_distance := 100000.0
	for index in range(baghdad_tigris_route.size() - 1):
		nearest_distance = minf(nearest_distance, _distance_to_segment(point, baghdad_tigris_route[index], baghdad_tigris_route[index + 1]))
	if nearest_distance >= BAGHDAD_TIGRIS_HALF_WIDTH:
		return 0.0
	var blend := 1.0 - nearest_distance / BAGHDAD_TIGRIS_HALF_WIDTH
	return BAGHDAD_TIGRIS_DEPTH * blend * blend


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
	if baghdad_bridge_reference_loaded:
		var bridge_bank_point := _baghdad_bridge_nearest_bank_point()
		var corridor_distance := _distance_to_segment(Vector2(x, z), Vector2.ZERO, bridge_bank_point)
		var corridor_height := 13.0 + sin(x * 0.009) * 1.0 + cos(z * 0.011) * 0.8
		var bridge_dx := (x - baghdad_bridge_center.x) / BAGHDAD_LAND_RADIUS_X
		var bridge_dz := (z - baghdad_bridge_center.y) / BAGHDAD_LAND_RADIUS_Z
		var bridge_radius := sqrt(bridge_dx * bridge_dx + bridge_dz * bridge_dz)
		if bridge_radius <= 1.0:
			var bridge_coast_factor := clampf((1.0 - bridge_radius) / 0.12, 0.0, 1.0)
			var bridge_coast_ease := bridge_coast_factor * bridge_coast_factor * (3.0 - 2.0 * bridge_coast_factor)
			var bridge_land_height := 18.0 + sin(x * 0.012) * 1.2 + cos(z * 0.014) * 0.9
			var bridge_natural_height := lerpf(SEA_LEVEL - 1.2, bridge_land_height, bridge_coast_ease) - _baghdad_tigris_channel_depth(x, z)
			# Continue the generated access ramp onto the near bank. The river
			# crossing itself remains the separately surveyed Republic Bridge.
			if corridor_distance <= 18.0:
				var bridge_access_blend := clampf((18.0 - corridor_distance) / 6.0, 0.0, 1.0)
				var bridge_access_ease := bridge_access_blend * bridge_access_blend * (3.0 - 2.0 * bridge_access_blend)
				return lerpf(bridge_natural_height, maxf(bridge_natural_height, corridor_height), bridge_access_ease)
			return bridge_natural_height

		var radius := _continent_radius(x, z)
		if radius <= 1.0:
			var coast_factor := clampf((1.0 - radius) / 0.10, 0.0, 1.0)
			var coast_ease := coast_factor * coast_factor * (3.0 - 2.0 * coast_factor)
			var interior_height := _land_base_height(x, z)
			var natural_height := lerpf(SEA_LEVEL - 1.2, interior_height, coast_ease)
			# Keep the connector walkable even where the procedural low basin
			# falls below sea level. This narrow strip is generated gameplay
			# infrastructure, not an OpenStreetMap road.
			if corridor_distance <= 18.0:
				var access_blend := clampf((18.0 - corridor_distance) / 6.0, 0.0, 1.0)
				var access_ease := access_blend * access_blend * (3.0 - 2.0 * access_blend)
				return lerpf(natural_height, maxf(natural_height, corridor_height), access_ease)
			return natural_height

		# The connector must remain continuous across the entire gap between
		# the playable continent and the surveyed bridge island. Do not gate
		# its elevation by the bridge island's coastal radius: that created a
		# submerged band before the near bank.
		if corridor_distance <= BAGHDAD_URBAN_CORRIDOR_HALF_WIDTH:
			var corridor_blend := clampf((BAGHDAD_URBAN_CORRIDOR_HALF_WIDTH - corridor_distance) / 110.0, 0.0, 1.0)
			var corridor_ease := corridor_blend * corridor_blend * (3.0 - 2.0 * corridor_blend)
			return lerpf(SEA_LEVEL - 1.2, corridor_height, corridor_ease)

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
	if indices.size() >= 3 and terrain_mesh.get_rid().is_valid():
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



func _setup_terrain_streaming() -> void:
	# The monolithic continent mesh/collision is intentionally no longer built.
	# Terrain cells now sample the same deterministic world-space height function.
	var streamer = TerrainCellStreamingManagerScript.new()
	streamer.name = "ModernWorldTerrainCellStreamer"
	var terrain_material := _make_terrain_material()
	if not streamer.configure(
		Callable(self, "_get_height"),
		WORLD_WIDTH,
		WORLD_DEPTH,
		200.0,
		20.0,
		terrain_material,
		2,
		1
	):
		push_error("SYSTEM WORLD: terrain cell streaming configuration failed.")
		streamer.queue_free()
		return
	add_child(streamer)


func _make_terrain_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.96
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _coastline_radius_for_angle(angle: float, target_radius: float) -> float:
	var direction := Vector2(cos(angle), sin(angle))
	var low := 0.82
	var high := 1.16
	for _iteration in range(14):
		var middle := (low + high) * 0.5
		var x := direction.x * CONTINENT_RADIUS_X * middle
		var z := direction.y * CONTINENT_RADIUS_Z * middle
		if _continent_radius(x, z) < target_radius:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5


func _build_coastal_beaches() -> void:
	# A narrow, terrain-following sand ribbon softens the transition between
	# the continent's grassland and the ocean without adding separate flat land.
	var beach_material := StandardMaterial3D.new()
	beach_material.albedo_color = Color(0.72, 0.63, 0.43)
	beach_material.roughness = 1.0
	beach_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var beach_surface := SurfaceTool.new()
	beach_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	beach_surface.set_material(beach_material)
	var segments := 128
	for index in range(segments):
		var angle_a := TAU * float(index) / float(segments)
		var angle_b := TAU * float(index + 1) / float(segments)
		var inner_a := _coastline_radius_for_angle(angle_a, 0.955)
		var outer_a := _coastline_radius_for_angle(angle_a, 0.992)
		var inner_b := _coastline_radius_for_angle(angle_b, 0.955)
		var outer_b := _coastline_radius_for_angle(angle_b, 0.992)

		var dir_a := Vector2(cos(angle_a), sin(angle_a))
		var dir_b := Vector2(cos(angle_b), sin(angle_b))
		var a_inner := dir_a * Vector2(CONTINENT_RADIUS_X * inner_a, CONTINENT_RADIUS_Z * inner_a)
		var a_outer := dir_a * Vector2(CONTINENT_RADIUS_X * outer_a, CONTINENT_RADIUS_Z * outer_a)
		var b_inner := dir_b * Vector2(CONTINENT_RADIUS_X * inner_b, CONTINENT_RADIUS_Z * inner_b)
		var b_outer := dir_b * Vector2(CONTINENT_RADIUS_X * outer_b, CONTINENT_RADIUS_Z * outer_b)

		var a_inner_y := maxf(_get_height(a_inner.x, a_inner.y) + 0.16, SEA_LEVEL + 0.18)
		var a_outer_y := maxf(_get_height(a_outer.x, a_outer.y) + 0.16, SEA_LEVEL + 0.18)
		var b_inner_y := maxf(_get_height(b_inner.x, b_inner.y) + 0.16, SEA_LEVEL + 0.18)
		var b_outer_y := maxf(_get_height(b_outer.x, b_outer.y) + 0.16, SEA_LEVEL + 0.18)

		_add_surface_quad(
			beach_surface,
			Vector3(a_inner.x, a_inner_y, a_inner.y),
			Vector3(a_outer.x, a_outer_y, a_outer.y),
			Vector3(b_inner.x, b_inner_y, b_inner.y),
			Vector3(b_outer.x, b_outer_y, b_outer.y)
		)

	beach_surface.generate_normals()
	var beaches := MeshInstance3D.new()
	beaches.name = "NaturalCoastlineBeaches"
	var beach_mesh := _commit_surface_tool_if_valid(beach_surface)
	if beach_mesh == null:
		return
	beaches.mesh = beach_mesh
	beaches.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beaches)


func _commit_surface_tool_if_valid(surface: SurfaceTool) -> ArrayMesh:
	# Empty SurfaceTools must never become MeshInstance3D resources. Godot's
	# dummy/headless renderer can emit repeated mesh_get_surface_count errors
	# for zero-surface ArrayMesh resources even when scene-node checks look clean.
	var arrays: Array = surface.commit_to_arrays()
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return null
	var raw_vertices: Variant = arrays[Mesh.ARRAY_VERTEX]
	if typeof(raw_vertices) != TYPE_PACKED_VECTOR3_ARRAY:
		return null
	var vertices: PackedVector3Array = raw_vertices
	if vertices.size() < 3:
		return null
	var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
	if raw_indices is PackedInt32Array:
		var indices: PackedInt32Array = raw_indices
		if not indices.is_empty() and indices.size() < 3:
			return null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if not mesh.get_rid().is_valid():
		return null
	return mesh


func _build_cave_entrances() -> void:
	# Initial discoverable cave mouths placed in the mountain belts.
	var cave_sites := [
		{"name": "NorthernRidgeCave", "position": Vector2(430.0, -515.0)},
		{"name": "WesternCliffCave", "position": Vector2(-690.0, 260.0)},
		{"name": "EasternHighlandCave", "position": Vector2(760.0, 470.0)},
		{"name": "FrostPassageCave", "position": Vector2(-80.0, -690.0)}
	]
	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.29, 0.30, 0.29)
	rock_material.roughness = 0.98
	var darkness_material := StandardMaterial3D.new()
	darkness_material.albedo_color = Color(0.012, 0.018, 0.022)
	darkness_material.roughness = 1.0
	darkness_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	for cave in cave_sites:
		var location: Vector2 = cave["position"]
		if not is_land_position(location.x, location.y):
			continue
		var entrance := Node3D.new()
		entrance.name = str(cave["name"])
		entrance.position = Vector3(
			location.x,
			get_terrain_height(location.x, location.y) + 0.3,
			location.y
		)
		add_child(entrance)

		var opening := MeshInstance3D.new()
		opening.name = "CaveDarkOpening"
		var opening_mesh := PlaneMesh.new()
		opening_mesh.size = Vector2(8.0, 6.0)
		opening.mesh = opening_mesh
		opening.rotation_degrees.x = 90.0
		opening.position = Vector3(0.0, 3.0, -0.35)
		opening.material_override = darkness_material
		entrance.add_child(opening)

		for side in [-1.0, 1.0]:
			var pillar := MeshInstance3D.new()
			pillar.name = "CaveRockPillar"
			var pillar_mesh := SphereMesh.new()
			pillar_mesh.radius = 1.0
			pillar_mesh.height = 2.0
			pillar.mesh = pillar_mesh
			pillar.position = Vector3(side * 4.1, 2.2, 0.0)
			pillar.scale = Vector3(1.7, 2.7, 1.6)
			pillar.material_override = rock_material
			entrance.add_child(pillar)

		var arch := MeshInstance3D.new()
		arch.name = "CaveRockArch"
		var arch_mesh := SphereMesh.new()
		arch_mesh.radius = 1.0
		arch_mesh.height = 2.0
		arch.mesh = arch_mesh
		arch.position = Vector3(0.0, 5.2, 0.0)
		arch.scale = Vector3(4.5, 1.6, 1.8)
		arch.material_override = rock_material
		entrance.add_child(arch)


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
		# City beacons are small navigation markers, not giant glowing orbs.
		# The previous 2.8 m radius obscured the player camera when spawning near
		# the starting city marker.
		var sphere := SphereMesh.new()
		sphere.radius = 0.32
		sphere.height = 0.64
		beacon.mesh = sphere
		beacon.position.y = 1.25
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
		label.position = Vector3(0.0, 5.5, 0.0)
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
	var highway_mesh := _commit_surface_tool_if_valid(road_surface)
	if highway_mesh == null:
		return
	road_visual.mesh = highway_mesh
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


func _build_baghdad_tigris_surface() -> void:
	if not baghdad_bridge_reference_loaded or baghdad_tigris_route.size() < 2:
		return
	var water_shader := Shader.new()
	water_shader.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float wave_a = sin(world_position.x * 0.035 + world_position.z * 0.012 + TIME * 0.52);
	float wave_b = sin(world_position.z * 0.052 - world_position.x * 0.018 - TIME * 0.38);
	float ripple = wave_a * 0.55 + wave_b * 0.45;
	float glint = smoothstep(0.72, 0.96, ripple);
	vec3 deep_water = vec3(0.012, 0.13, 0.20);
	vec3 lit_water = vec3(0.035, 0.30, 0.38);
	ALBEDO = mix(deep_water, lit_water, clamp(0.48 + ripple * 0.24, 0.0, 1.0));
	ROUGHNESS = 0.22;
	METALLIC = 0.16;
	EMISSION = vec3(0.004, 0.018, 0.024) + glint * vec3(0.018, 0.045, 0.052);
}
"""
	var material := ShaderMaterial.new()
	material.shader = water_shader
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	var foam_material := StandardMaterial3D.new()
	foam_material.albedo_color = Color(0.42, 0.75, 0.78, 0.42)
	foam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam_material.roughness = 0.34
	foam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var foam_surface := SurfaceTool.new()
	foam_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	foam_surface.set_material(foam_material)
	for index in range(baghdad_tigris_route.size() - 1):
		var start: Vector2 = baghdad_tigris_route[index]
		var finish: Vector2 = baghdad_tigris_route[index + 1]
		var direction := (finish - start).normalized()
		var side := Vector2(-direction.y, direction.x)
		var bank_offset := side * BAGHDAD_TIGRIS_HALF_WIDTH
		var a_left := start + bank_offset
		var a_right := start - bank_offset
		var b_left := finish + bank_offset
		var b_right := finish - bank_offset
		_add_surface_quad(surface, Vector3(a_left.x, SEA_LEVEL + 0.28, a_left.y), Vector3(a_right.x, SEA_LEVEL + 0.28, a_right.y), Vector3(b_left.x, SEA_LEVEL + 0.28, b_left.y), Vector3(b_right.x, SEA_LEVEL + 0.28, b_right.y))
		for side_sign in [-1.0, 1.0]:
			var inner_a := start + side * (BAGHDAD_TIGRIS_HALF_WIDTH - 0.12) * float(side_sign)
			var outer_a := start + side * (BAGHDAD_TIGRIS_HALF_WIDTH + 0.18) * float(side_sign)
			var inner_b := finish + side * (BAGHDAD_TIGRIS_HALF_WIDTH - 0.12) * float(side_sign)
			var outer_b := finish + side * (BAGHDAD_TIGRIS_HALF_WIDTH + 0.18) * float(side_sign)
			_add_surface_quad(foam_surface,
				Vector3(inner_a.x, SEA_LEVEL + 0.33, inner_a.y),
				Vector3(outer_a.x, SEA_LEVEL + 0.33, outer_a.y),
				Vector3(inner_b.x, SEA_LEVEL + 0.33, inner_b.y),
				Vector3(outer_b.x, SEA_LEVEL + 0.33, outer_b.y))
	surface.generate_normals()
	foam_surface.generate_normals()
	var river := MeshInstance3D.new()
	river.name = "BaghdadTigrisRiver"
	var river_mesh := _commit_surface_tool_if_valid(surface)
	if river_mesh == null:
		return
	river.mesh = river_mesh
	river.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	river.set_meta("system_geography_source", "OpenStreetMap way 24709603")
	river.set_meta("system_geography_name", "Tigris River")
	river.set_meta("system_water_shader", "world_space_animated_ripples")
	add_child(river)
	var foam_mesh := _commit_surface_tool_if_valid(foam_surface)
	if foam_mesh != null:
		var foam := MeshInstance3D.new()
		foam.name = "BaghdadTigrisBankFoam"
		foam.mesh = foam_mesh
		foam.material_override = foam_material
		foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		foam.set_meta("system_water_edge_detail", "soft_bank_foam")
		add_child(foam)


func _build_baghdad_republic_bridge() -> void:
	if not baghdad_bridge_reference_loaded or baghdad_bridge_outline.size() < 3:
		return
	var bridge := Node3D.new()
	bridge.name = "BaghdadRepublicBridge"
	bridge.set_meta("system_geography_source", "OpenStreetMap way 1077808833")
	bridge.set_meta("system_osm_bridge_polygon_way_id", 1077808833)
	bridge.set_meta("system_osm_primary_centerline_way_id", 4080878)
	bridge.set_meta("system_osm_secondary_centerline_way_id", 754157537)
	bridge.set_meta("system_bridge_name", "جسر الجمهورية / Republic Bridge")
	add_child(bridge)
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(baghdad_bridge_outline)
	if triangles.is_empty():
		push_error("SYSTEM Baghdad geography: Republic Bridge polygon could not be triangulated.")
		bridge.queue_free()
		return
	var deck_material := StandardMaterial3D.new()
	deck_material.albedo_color = Color(0.24, 0.28, 0.31)
	deck_material.roughness = 0.82
	deck_material.metallic = 0.24
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(deck_material)
	var collision_faces := PackedVector3Array()
	for triangle_index in range(0, triangles.size(), 3):
		var point_a: Vector2 = baghdad_bridge_outline[triangles[triangle_index]]
		var point_b: Vector2 = baghdad_bridge_outline[triangles[triangle_index + 1]]
		var point_c: Vector2 = baghdad_bridge_outline[triangles[triangle_index + 2]]
		var signed_area := (point_b.x - point_a.x) * (point_c.y - point_a.y) - (point_b.y - point_a.y) * (point_c.x - point_a.x)
		if signed_area > 0.0:
			var swap_point := point_b
			point_b = point_c
			point_c = swap_point
		var vertex_a := Vector3(point_a.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT, point_a.y)
		var vertex_b := Vector3(point_b.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT, point_b.y)
		var vertex_c := Vector3(point_c.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT, point_c.y)
		surface.add_vertex(vertex_a)
		surface.add_vertex(vertex_b)
		surface.add_vertex(vertex_c)
		collision_faces.append(vertex_a)
		collision_faces.append(vertex_b)
		collision_faces.append(vertex_c)
	surface.generate_normals()
	var deck := MeshInstance3D.new()
	deck.name = "RepublicBridgeDeck"
	var deck_mesh := _commit_surface_tool_if_valid(surface)
	if deck_mesh == null:
		bridge.queue_free()
		return
	deck.mesh = deck_mesh
	deck.set_meta("system_bridge_deck_height_m", BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT)
	deck.set_meta("system_bridge_polygon_points", baghdad_bridge_outline.size())
	bridge.add_child(deck)
	var body := StaticBody3D.new()
	body.name = "RepublicBridgeDeckCollision"
	var collision := CollisionShape3D.new()
	collision.name = "RepublicBridgeDeckCollisionShape"
	var concave := ConcavePolygonShape3D.new()
	concave.set_faces(collision_faces)
	collision.shape = concave
	body.add_child(collision)
	bridge.add_child(body)
	var rail_material := StandardMaterial3D.new()
	rail_material.albedo_color = Color(0.58, 0.62, 0.64)
	rail_material.metallic = 0.72
	var polygon_center := Vector2.ZERO
	for point in baghdad_bridge_outline:
		polygon_center += point
	polygon_center /= float(baghdad_bridge_outline.size())
	for index in range(baghdad_bridge_outline.size()):
		var start_point: Vector2 = baghdad_bridge_outline[index]
		var finish_point: Vector2 = baghdad_bridge_outline[(index + 1) % baghdad_bridge_outline.size()]
		var delta := Vector3(finish_point.x - start_point.x, 0.0, finish_point.y - start_point.y)
		if delta.length() < 4.0:
			continue
		var midpoint := Vector3((start_point.x + finish_point.x) * 0.5, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.675, (start_point.y + finish_point.y) * 0.5)
		var outward_2d := (Vector2(midpoint.x, midpoint.z) - polygon_center).normalized()
		var rail := MeshInstance3D.new()
		rail.name = "RepublicBridgeGuardrail_%02d" % index
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(0.18, 1.15, delta.length())
		rail.mesh = rail_mesh
		rail.position = midpoint + Vector3(outward_2d.x, 0.0, outward_2d.y) * 0.52
		rail.rotation.y = atan2(delta.x, delta.z)
		rail.material_override = rail_material
		bridge.add_child(rail)
		var handrail := MeshInstance3D.new()
		handrail.name = "RepublicBridgeHandrail_%02d" % index
		var handrail_mesh := BoxMesh.new()
		handrail_mesh.size = Vector3(0.24, 0.14, delta.length())
		handrail.mesh = handrail_mesh
		handrail.position = midpoint + Vector3(0.0, 1.12, 0.0) + Vector3(outward_2d.x, 0.0, outward_2d.y) * 0.52
		handrail.rotation.y = atan2(delta.x, delta.z)
		handrail.material_override = rail_material
		bridge.add_child(handrail)
	_add_baghdad_bridge_guardrail_posts(bridge, baghdad_bridge_outline, rail_material)
	_add_baghdad_bridge_lane_markings(bridge)
	_add_baghdad_bridge_lighting(bridge)
	bridge.set_meta("system_bridge_deck_height_m", BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT)
	bridge.set_meta("system_bridge_centerline_points", baghdad_bridge_centerline.size())
	bridge.set_meta("system_bridge_secondary_centerline_points", baghdad_bridge_secondary_centerline.size())
	bridge.set_meta("system_bridge_polygon_points", baghdad_bridge_outline.size())
	print("SYSTEM Baghdad geography: Republic Bridge polygon deck, collision and guardrails generated from verified OSM way 1077808833.")


func _add_baghdad_bridge_guardrail_posts(
	bridge: Node3D,
	outline: PackedVector2Array,
	material: StandardMaterial3D
) -> void:
	var polygon_center := Vector2.ZERO
	for point in outline:
		polygon_center += point
	polygon_center /= float(outline.size())
	var transforms: Array[Transform3D] = []
	for edge_index in range(outline.size()):
		var start := outline[edge_index]
		var finish := outline[(edge_index + 1) % outline.size()]
		var edge := finish - start
		var edge_length := edge.length()
		if edge_length < 4.0:
			continue
		var midpoint := (start + finish) * 0.5
		var outward := (midpoint - polygon_center).normalized()
		var post_count := maxi(1, int(ceil(edge_length / 3.2)))
		for post_index in range(post_count + 1):
			var t := float(post_index) / float(post_count)
			var point := start.lerp(finish, t) + outward * 0.52
			transforms.append(Transform3D(
				Basis.IDENTITY,
				Vector3(point.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.58, point.y)
			))
	if transforms.is_empty():
		return
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.14, 1.16, 0.14)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = post_mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var posts := MultiMeshInstance3D.new()
	posts.name = "RepublicBridgeGuardrailPosts"
	posts.multimesh = multimesh
	posts.material_override = material
	posts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bridge.add_child(posts)
	bridge.set_meta("system_bridge_guardrail_post_count", transforms.size())


func _add_baghdad_bridge_lane_markings(bridge: Node3D) -> void:
	var yellow_material := StandardMaterial3D.new()
	yellow_material.albedo_color = Color(0.96, 0.78, 0.32)
	yellow_material.roughness = 0.76
	var white_material := StandardMaterial3D.new()
	white_material.albedo_color = Color(0.88, 0.90, 0.88)
	white_material.roughness = 0.76
	var joint_material := StandardMaterial3D.new()
	joint_material.albedo_color = Color(0.12, 0.15, 0.17)
	joint_material.roughness = 0.9
	var yellow_surface := SurfaceTool.new()
	yellow_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	yellow_surface.set_material(yellow_material)
	var white_surface := SurfaceTool.new()
	white_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	white_surface.set_material(white_material)
	var joint_surface := SurfaceTool.new()
	joint_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	joint_surface.set_material(joint_material)
	var centerlines: Array = [baghdad_bridge_centerline, baghdad_bridge_secondary_centerline]
	for route_value in centerlines:
		var route: Array = route_value
		if route.size() < 2:
			continue
		var dash_distance_to_next := 0.0
		var joint_distance_to_next := 24.0
		for segment_index in range(route.size() - 1):
			var start: Vector2 = route[segment_index]
			var finish: Vector2 = route[segment_index + 1]
			var segment := finish - start
			var segment_length := segment.length()
			if segment_length < 0.5:
				continue
			var direction := segment / segment_length
			var side := Vector2(-direction.y, direction.x)
			var cursor := dash_distance_to_next
			while cursor < segment_length:
				var dash_end := minf(cursor + 4.0, segment_length)
				var a := start + direction * cursor
				var b := start + direction * dash_end
				for offset in [-3.1, 3.1]:
					var half_width := 0.055
					var a_left := a + side * (float(offset) - half_width)
					var a_right := a + side * (float(offset) + half_width)
					var b_left := b + side * (float(offset) - half_width)
					var b_right := b + side * (float(offset) + half_width)
					_add_surface_quad(white_surface,
						Vector3(a_left.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.045, a_left.y),
						Vector3(a_right.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.045, a_right.y),
						Vector3(b_left.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.045, b_left.y),
						Vector3(b_right.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.045, b_right.y))
				var center_half_width := 0.075
				var center_a_left := a + side * -center_half_width
				var center_a_right := a + side * center_half_width
				var center_b_left := b + side * -center_half_width
				var center_b_right := b + side * center_half_width
				_add_surface_quad(yellow_surface,
					Vector3(center_a_left.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.05, center_a_left.y),
					Vector3(center_a_right.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.05, center_a_right.y),
					Vector3(center_b_left.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.05, center_b_left.y),
					Vector3(center_b_right.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.05, center_b_right.y))
				cursor += 7.0
			dash_distance_to_next = cursor - segment_length
			var joint_cursor := joint_distance_to_next
			while joint_cursor < segment_length:
				var joint_center := start + direction * joint_cursor
				var along := direction * 0.055
				var across := side * 6.25
				_add_surface_quad(joint_surface,
					Vector3((joint_center - along + across).x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.025, (joint_center - along + across).y),
					Vector3((joint_center - along - across).x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.025, (joint_center - along - across).y),
					Vector3((joint_center + along + across).x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.025, (joint_center + along + across).y),
					Vector3((joint_center + along - across).x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 0.025, (joint_center + along - across).y))
				joint_cursor += 24.0
			joint_distance_to_next = joint_cursor - segment_length
	yellow_surface.generate_normals()
	white_surface.generate_normals()
	joint_surface.generate_normals()
	var yellow_mesh := _commit_surface_tool_if_valid(yellow_surface)
	if yellow_mesh != null:
		var yellow_lines := MeshInstance3D.new()
		yellow_lines.name = "RepublicBridgeCenterlineMarkings"
		yellow_lines.mesh = yellow_mesh
		yellow_lines.material_override = yellow_material
		yellow_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bridge.add_child(yellow_lines)
	var white_mesh := _commit_surface_tool_if_valid(white_surface)
	if white_mesh != null:
		var white_lines := MeshInstance3D.new()
		white_lines.name = "RepublicBridgeLaneMarkings"
		white_lines.mesh = white_mesh
		white_lines.material_override = white_material
		white_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bridge.add_child(white_lines)
	var joint_mesh := _commit_surface_tool_if_valid(joint_surface)
	if joint_mesh != null:
		var joints := MeshInstance3D.new()
		joints.name = "RepublicBridgeExpansionJoints"
		joints.mesh = joint_mesh
		joints.material_override = joint_material
		joints.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bridge.add_child(joints)
	bridge.set_meta("system_bridge_lane_marking_segments", baghdad_bridge_centerline.size() + baghdad_bridge_secondary_centerline.size())


func _add_baghdad_bridge_lighting(bridge: Node3D) -> void:
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.075
	pole_mesh.bottom_radius = 0.11
	pole_mesh.height = 5.5
	pole_mesh.radial_segments = 8
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.9, 0.14, 0.32)
	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.16, 0.19, 0.22)
	pole_material.roughness = 0.5
	pole_material.metallic = 0.78
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(1.0, 0.78, 0.48)
	head_material.emission_enabled = true
	head_material.emission = Color(1.0, 0.62, 0.28)
	head_material.emission_energy_multiplier = 1.35
	var pole_transforms: Array[Transform3D] = []
	var head_transforms: Array[Transform3D] = []
	for route_value in [baghdad_bridge_centerline, baghdad_bridge_secondary_centerline]:
		var route: Array = route_value
		if route.size() < 2:
			continue
		var lamp_distance_to_next := 12.0
		for segment_index in range(route.size() - 1):
			var start: Vector2 = route[segment_index]
			var finish: Vector2 = route[segment_index + 1]
			var segment := finish - start
			var segment_length := segment.length()
			if segment_length < 0.5:
				continue
			var direction := segment / segment_length
			var side := Vector2(-direction.y, direction.x)
			var lamp_distance := lamp_distance_to_next
			while lamp_distance < segment_length:
				var center := start + direction * lamp_distance
				for side_sign in [-1.0, 1.0]:
					var point := center + side * 6.35 * float(side_sign)
					var pole_position := Vector3(point.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 2.75, point.y)
					var head_position := Vector3(point.x, BAGHDAD_REPUBLIC_BRIDGE_DECK_HEIGHT + 5.48, point.y)
					pole_transforms.append(Transform3D(Basis.IDENTITY, pole_position))
					var head_right := Vector3(direction.x, 0.0, direction.y)
					var head_forward := Vector3(-direction.y, 0.0, direction.x)
					head_transforms.append(Transform3D(Basis(head_right, Vector3.UP, head_forward), head_position))
				lamp_distance += 28.0
			lamp_distance_to_next = lamp_distance - segment_length
	if pole_transforms.is_empty():
		return
	var pole_multimesh := MultiMesh.new()
	pole_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	pole_multimesh.mesh = pole_mesh
	pole_multimesh.instance_count = pole_transforms.size()
	for index in range(pole_transforms.size()):
		pole_multimesh.set_instance_transform(index, pole_transforms[index])
	var poles := MultiMeshInstance3D.new()
	poles.name = "RepublicBridgeLightPoles"
	poles.multimesh = pole_multimesh
	poles.material_override = pole_material
	poles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bridge.add_child(poles)
	var head_multimesh := MultiMesh.new()
	head_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	head_multimesh.mesh = head_mesh
	head_multimesh.instance_count = head_transforms.size()
	for index in range(head_transforms.size()):
		head_multimesh.set_instance_transform(index, head_transforms[index])
	var heads := MultiMeshInstance3D.new()
	heads.name = "RepublicBridgeLampHeads"
	heads.multimesh = head_multimesh
	heads.material_override = head_material
	heads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bridge.add_child(heads)
	bridge.set_meta("system_bridge_light_count", pole_transforms.size())


func _build_baghdad_bridge_access_causeway() -> void:
	if not baghdad_bridge_reference_loaded:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.14, 0.16)
	material.roughness = 0.92
	material.metallic = 0.12
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	var start := Vector2.ZERO
	# Join the bank nearest the playable Baghdad origin; the surveyed bridge
	# deck itself carries the player across the Tigris to the opposite bank.
	var finish := _baghdad_bridge_nearest_bank_point()
	if finish == Vector2.INF:
		return
	var half_width := 7.0
	var segments := 96
	for index in range(segments):
		var t0 := float(index) / float(segments)
		var t1 := float(index + 1) / float(segments)
		var a := start.lerp(finish, t0)
		var b := start.lerp(finish, t1)
		var direction := (b - a).normalized()
		var side := Vector2(-direction.y, direction.x) * half_width
		var a_left := a + side
		var a_right := a - side
		var b_left := b + side
		var b_right := b - side
		_add_surface_quad(
			surface,
			Vector3(a_left.x, get_terrain_height(a_left.x, a_left.y) + 0.48, a_left.y),
			Vector3(a_right.x, get_terrain_height(a_right.x, a_right.y) + 0.48, a_right.y),
			Vector3(b_left.x, get_terrain_height(b_left.x, b_left.y) + 0.48, b_left.y),
			Vector3(b_right.x, get_terrain_height(b_right.x, b_right.y) + 0.48, b_right.y)
		)
	surface.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "BaghdadBridgeAccessCauseway"
	var access_mesh := _commit_surface_tool_if_valid(surface)
	if access_mesh == null:
		return
	road.mesh = access_mesh
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	road.set_meta("system_generated_access_route", true)
	road.set_meta("system_geography_source", "SYSTEM procedural playable connector; not OpenStreetMap road geometry")
	road.set_meta("system_route_start", Vector3.ZERO)
	road.set_meta("system_route_end", Vector3(finish.x, 0.0, finish.y))
	add_child(road)
	var body := StaticBody3D.new()
	body.name = "BaghdadBridgeAccessCausewayCollision"
	var collision := CollisionShape3D.new()
	collision.name = "CausewayCollisionShape"
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(road.mesh.get_faces())
	collision.shape = shape
	body.add_child(collision)
	road.add_child(body)
	print("SYSTEM Baghdad geography: playable generated access causeway connects the Baghdad origin to the surveyed Republic Bridge anchor; it is not OSM road data.")


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
	var river_network_mesh := _commit_surface_tool_if_valid(river_surface)
	if river_network_mesh == null:
		return
	river_visual.mesh = river_network_mesh
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
	var waterfall_mesh := _commit_surface_tool_if_valid(waterfall_surface)
	if waterfall_mesh == null:
		return
	waterfall_visual.mesh = waterfall_mesh
	waterfall_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(waterfall_visual)
	print("SYSTEM WORLD: generated ", waterfall_count, " terrain-based waterfalls.")
