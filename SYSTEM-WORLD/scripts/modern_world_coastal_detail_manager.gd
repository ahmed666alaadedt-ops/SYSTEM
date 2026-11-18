extends Node3D
class_name ModernWorldCoastalDetailManager

## Adds lightweight natural detail along the existing main-continent shoreline.
## It does not reshape terrain, move settlements, or replace the ocean/beach mesh.

const CONTINENT_RADIUS_X := 1120.0
const CONTINENT_RADIUS_Z := 790.0
const SHORE_SAMPLES := 256
const CITY_EXCLUSION_POINTS := [
	Vector2(-650.0, -260.0), Vector2(-420.0, -90.0),
	Vector2(-300.0, 110.0), Vector2(0.0, 0.0),
	Vector2(120.0, -470.0), Vector2(-80.0, 330.0),
	Vector2(390.0, 230.0), Vector2(650.0, 40.0),
	Vector2(820.0, -260.0), Vector2(1030.0, 80.0),
	Vector2(560.0, 490.0), Vector2(1050.0, 680.0),
	Vector2(-850.0, 420.0), Vector2(-350.0, 610.0)
]

var terrain: ModernContinentManager
var rock_material: StandardMaterial3D
var driftwood_material: StandardMaterial3D
var dune_grass_material: StandardMaterial3D
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "ModernWorldCoastalDetailManager"
	rng.seed = 20261119
	terrain = get_parent().get_node_or_null("ModernContinent") as ModernContinentManager
	if terrain == null:
		push_warning("SYSTEM WORLD: coastal details require ModernContinent.")
		return
	_create_materials()
	_build_shoreline_details()
	print("SYSTEM WORLD: coastal detail pass initialized.")


func _create_materials() -> void:
	rock_material = _material(Color(0.31, 0.34, 0.34), 0.98)
	driftwood_material = _material(Color(0.30, 0.20, 0.12), 0.96)
	dune_grass_material = _material(Color(0.43, 0.47, 0.24), 1.0)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result


func _build_shoreline_details() -> void:
	var rock_transforms: Array[Transform3D] = []
	var wood_transforms: Array[Transform3D] = []
	var grass_transforms: Array[Transform3D] = []
	var accepted_sites: Array[Vector2] = []

	for index in range(SHORE_SAMPLES):
		var angle := TAU * float(index) / float(SHORE_SAMPLES)
		var direction := Vector2(cos(angle), sin(angle))
		var shoreline := _find_shore_position(direction)
		if shoreline == Vector2.INF:
			continue
		if _near_city(shoreline, 125.0):
			continue
		accepted_sites.append(shoreline)
		var ground_y := terrain.get_terrain_height(shoreline.x, shoreline.y)
		var rock_count := rng.randi_range(1, 3)
		for _rock in range(rock_count):
			var offset := Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-8.0, 8.0))
			var point := shoreline + offset
			if not terrain.is_land_position(point.x, point.y):
				continue
			rock_transforms.append(_rock_transform(point, terrain.get_terrain_height(point.x, point.y)))
		if index % 4 == 0:
			wood_transforms.append(_driftwood_transform(shoreline, ground_y))
		if index % 2 == 0 and ground_y < 5.0:
			for _grass in range(3):
				var point := shoreline + Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-7.0, 7.0))
				if terrain.is_land_position(point.x, point.y):
					grass_transforms.append(_grass_transform(point, terrain.get_terrain_height(point.x, point.y)))

	_add_multimesh("CoastalRockClusters", SphereMesh.new(), rock_material, rock_transforms)
	var wood_mesh := BoxMesh.new()
	wood_mesh.size = Vector3(1.0, 1.0, 1.0)
	_add_multimesh("CoastalDriftwood", wood_mesh, driftwood_material, wood_transforms)
	var grass_mesh := CylinderMesh.new()
	grass_mesh.height = 1.0
	grass_mesh.top_radius = 0.04
	grass_mesh.bottom_radius = 0.18
	_add_multimesh("CoastalDuneGrass", grass_mesh, dune_grass_material, grass_transforms)
	set_meta("system_coastal_sample_count", SHORE_SAMPLES)
	set_meta("system_coastal_site_count", accepted_sites.size())


func _find_shore_position(direction: Vector2) -> Vector2:
	var best := Vector2.INF
	var best_height := 100000.0
	# Follow the same angle-dependent shoreline profile used by the continent
	# and beach builders, rather than sampling the old unmodified ellipse.
	var angle := atan2(direction.y, direction.x)
	var shoreline_radius := terrain._coastline_radius_for_angle(angle, 0.975)
	for sample in range(28):
		var radius := shoreline_radius - 0.025 + float(sample) * 0.00185
		var point := Vector2(
			direction.x * CONTINENT_RADIUS_X * radius,
			direction.y * CONTINENT_RADIUS_Z * radius
		)
		if not terrain.is_land_position(point.x, point.y):
			continue
		var height := terrain.get_terrain_height(point.x, point.y)
		if height >= 0.0 and height <= 12.0 and height < best_height:
			best = point
			best_height = height
	if best == Vector2.INF:
		return best
	return best


func _near_city(point: Vector2, radius: float) -> bool:
	for city in CITY_EXCLUSION_POINTS:
		if point.distance_to(city) < radius:
			return true
	return false


func _rock_transform(point: Vector2, ground_y: float) -> Transform3D:
	var sx := rng.randf_range(1.2, 4.2)
	var sy := rng.randf_range(0.8, 2.8)
	var sz := rng.randf_range(1.4, 4.0)
	return Transform3D(
		Basis().scaled(Vector3(sx, sy, sz)),
		Vector3(point.x, ground_y + sy * 0.38, point.y)
	)


func _driftwood_transform(point: Vector2, ground_y: float) -> Transform3D:
	var length := rng.randf_range(3.0, 7.0)
	var thickness := rng.randf_range(0.18, 0.34)
	var angle := rng.randf_range(0.0, TAU)
	var basis := Basis(Vector3.UP, angle).scaled(Vector3(length, thickness, thickness))
	return Transform3D(
		basis,
		Vector3(point.x, ground_y + thickness * 0.45, point.y)
	)


func _grass_transform(point: Vector2, ground_y: float) -> Transform3D:
	var height := rng.randf_range(0.7, 1.8)
	var width := rng.randf_range(0.12, 0.25)
	var angle := rng.randf_range(0.0, TAU)
	return Transform3D(
		Basis(Vector3.UP, angle).scaled(Vector3(width, height, width)),
		Vector3(point.x, ground_y + height * 0.5, point.y)
	)


func _add_multimesh(
	node_name: String,
	source_mesh: Mesh,
	material: Material,
	transforms: Array[Transform3D]
) -> void:
	if transforms.is_empty():
		return
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = source_mesh
	batch.instance_count = transforms.size()
	for index in range(transforms.size()):
		batch.set_instance_transform(index, transforms[index])
	var visual := MultiMeshInstance3D.new()
	visual.name = node_name
	visual.multimesh = batch
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.set_meta("system_scenery_only", true)
	add_child(visual)
