extends Node3D
class_name ModernWorldBiomeManager

## Lightweight, deterministic biome dressing placed over the existing continent.
## It does not alter terrain, city anchors, rivers, roads, or collision.

const CITY_EXCLUSION_POINTS := [
	Vector2(-650.0, -260.0), Vector2(-420.0, -90.0),
	Vector2(-300.0, 110.0), Vector2(0.0, 0.0),
	Vector2(120.0, -470.0), Vector2(-80.0, 330.0),
	Vector2(390.0, 230.0), Vector2(650.0, 40.0),
	Vector2(820.0, -260.0), Vector2(1030.0, 80.0),
	Vector2(560.0, 490.0), Vector2(1050.0, 680.0),
	Vector2(-850.0, 420.0), Vector2(-350.0, 610.0)
]

const RIVER_ROUTES := [
	[Vector2(430.0, -390.0), Vector2(330.0, -280.0), Vector2(210.0, -170.0), Vector2(90.0, -65.0), Vector2(0.0, 0.0)],
	[Vector2(-610.0, 260.0), Vector2(-470.0, 190.0), Vector2(-310.0, 120.0), Vector2(-145.0, 55.0), Vector2(0.0, 0.0)],
	[Vector2(760.0, 430.0), Vector2(610.0, 350.0), Vector2(470.0, 260.0), Vector2(330.0, 170.0)]
]

const BIOME_ZONES := [
	{"name": "WesternWoodland", "center": Vector2(-1010.0, -70.0), "radius": 175.0, "kind": "woodland"},
	{"name": "EasternWoodland", "center": Vector2(500.0, -170.0), "radius": 165.0, "kind": "woodland"},
	{"name": "SouthernDrylands", "center": Vector2(-610.0, 560.0), "radius": 165.0, "kind": "dry"},
	{"name": "NorthernHighlands", "center": Vector2(455.0, -525.0), "radius": 190.0, "kind": "alpine"},
	{"name": "NortheasternWoodland", "center": Vector2(1030.0, -610.0), "radius": 155.0, "kind": "woodland"},
	{"name": "SouthwesternDrylands", "center": Vector2(-1030.0, 690.0), "radius": 145.0, "kind": "dry"},
	{"name": "CentralWetlands", "center": Vector2(265.0, 390.0), "radius": 125.0, "kind": "wetland"},
	{"name": "EasternCoastalScrub", "center": Vector2(1190.0, 500.0), "radius": 115.0, "kind": "coastal"}
]

var terrain: ModernContinentManager
var rng := RandomNumberGenerator.new()
var trunk_material: StandardMaterial3D
var canopy_materials: Array[StandardMaterial3D] = []
var shrub_material: StandardMaterial3D
var rock_material: StandardMaterial3D


func _ready() -> void:
	name = "ModernWorldBiomeManager"
	rng.seed = 20261118
	terrain = get_parent().get_node_or_null("ModernContinent") as ModernContinentManager
	if terrain == null:
		push_warning("SYSTEM WORLD: biome dressing requires ModernContinent.")
		return
	_create_materials()
	_build_biome_zones()
	print("SYSTEM WORLD: deterministic biome dressing initialized.")


func _create_materials() -> void:
	trunk_material = _make_material(Color(0.25, 0.15, 0.085), 0.96)
	canopy_materials.append(_make_material(Color(0.075, 0.24, 0.105), 1.0))
	canopy_materials.append(_make_material(Color(0.12, 0.32, 0.14), 1.0))
	canopy_materials.append(_make_material(Color(0.19, 0.36, 0.16), 1.0))
	shrub_material = _make_material(Color(0.25, 0.34, 0.14), 1.0)
	rock_material = _make_material(Color(0.34, 0.35, 0.34), 0.98)


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _build_biome_zones() -> void:
	for zone in BIOME_ZONES:
		var zone_root := Node3D.new()
		zone_root.name = str(zone["name"])
		zone_root.set_meta("system_biome_type", str(zone["kind"]))
		add_child(zone_root)
		var tree_transforms: Array[Transform3D] = []
		var canopy_transforms: Array[Transform3D] = []
		var shrub_transforms: Array[Transform3D] = []
		var rock_transforms: Array[Transform3D] = []
		var center: Vector2 = zone["center"]
		var radius: float = float(zone["radius"])
		var kind := str(zone["kind"])
		var attempts := 190
		for _attempt in range(attempts):
			var angle := rng.randf_range(0.0, TAU)
			var distance := sqrt(rng.randf()) * radius
			var point := center + Vector2(cos(angle), sin(angle)) * distance
			if not _is_valid_biome_position(point, kind):
				continue
			var ground_y := terrain.get_terrain_height(point.x, point.y)
			if kind == "woodland":
				if rng.randf() < 0.48:
					var tree_height := rng.randf_range(7.0, 12.5)
					var trunk_width := rng.randf_range(0.65, 1.05)
					tree_transforms.append(Transform3D(
						Basis().scaled(Vector3(trunk_width, tree_height, trunk_width)),
						Vector3(point.x, ground_y + tree_height * 0.5, point.y)
					))
					var canopy_scale := rng.randf_range(4.0, 6.5)
					canopy_transforms.append(Transform3D(
						Basis().scaled(Vector3(canopy_scale, canopy_scale * 0.9, canopy_scale)),
						Vector3(point.x, ground_y + tree_height * 0.88, point.y)
					))
				elif rng.randf() < 0.68:
					shrub_transforms.append(_shrub_transform(point, ground_y))
				else:
					rock_transforms.append(_rock_transform(point, ground_y))
			elif kind == "dry":
				if rng.randf() < 0.72:
					shrub_transforms.append(_shrub_transform(point, ground_y))
				else:
					rock_transforms.append(_rock_transform(point, ground_y))
			elif kind == "wetland":
				if rng.randf() < 0.86:
					shrub_transforms.append(_shrub_transform(point, ground_y))
				else:
					rock_transforms.append(_rock_transform(point, ground_y))
			elif kind == "coastal":
				if rng.randf() < 0.42:
					shrub_transforms.append(_shrub_transform(point, ground_y))
				else:
					rock_transforms.append(_rock_transform(point, ground_y))
			else:
				if rng.randf() < 0.78:
					rock_transforms.append(_rock_transform(point, ground_y))
				else:
					shrub_transforms.append(_shrub_transform(point, ground_y))
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.height = 1.0
		trunk_mesh.top_radius = 0.42
		trunk_mesh.bottom_radius = 0.5
		_add_multimesh(zone_root, "TreeTrunks", trunk_mesh, trunk_material, tree_transforms)
		_add_multimesh(zone_root, "TreeCanopies", SphereMesh.new(), canopy_materials[1], canopy_transforms)
		_add_multimesh(zone_root, "LowShrubs", SphereMesh.new(), shrub_material, shrub_transforms)
		_add_multimesh(zone_root, "NaturalRocks", SphereMesh.new(), rock_material, rock_transforms)


func _is_valid_biome_position(point: Vector2, kind: String) -> bool:
	if not terrain.is_land_position(point.x, point.y):
		return false
	var height := terrain.get_terrain_height(point.x, point.y)
	if kind == "woodland" and (height < 2.0 or height > 82.0):
		return false
	if kind == "dry" and (height < 1.0 or height > 55.0):
		return false
	if kind == "wetland" and (height < 0.5 or height > 18.0):
		return false
	if kind == "coastal" and (height < 0.5 or height > 24.0):
		return false
	if kind == "alpine" and height < 24.0:
		return false
	for city_point in CITY_EXCLUSION_POINTS:
		if point.distance_to(city_point) < 105.0:
			return false
	for route in RIVER_ROUTES:
		for index in range(route.size() - 1):
			if _distance_to_segment(point, route[index], route[index + 1]) < 16.0:
				return false
	if point.distance_to(Vector2(250.0, 165.0)) < 62.0:
		return false
	if point.distance_to(Vector2(-430.0, -70.0)) < 48.0:
		return false
	return true


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _shrub_transform(point: Vector2, ground_y: float) -> Transform3D:
	var width := rng.randf_range(1.4, 2.8)
	var height := rng.randf_range(0.8, 1.8)
	return Transform3D(
		Basis().scaled(Vector3(width, height, width)),
		Vector3(point.x, ground_y + height * 0.45, point.y)
	)


func _rock_transform(point: Vector2, ground_y: float) -> Transform3D:
	var width := rng.randf_range(1.2, 3.8)
	var height := rng.randf_range(1.0, 3.2)
	var depth := rng.randf_range(1.2, 3.6)
	return Transform3D(
		Basis().scaled(Vector3(width, height, depth)),
		Vector3(point.x, ground_y + height * 0.42, point.y)
	)


func _add_multimesh(
	parent: Node3D,
	node_name: String,
	source_mesh: Mesh,
	material: Material,
	transforms: Array[Transform3D]
) -> void:
	if transforms.is_empty():
		return
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = source_mesh
	multi_mesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi_mesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi_mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.set_meta("system_scenery_only", true)
	parent.add_child(instance)
