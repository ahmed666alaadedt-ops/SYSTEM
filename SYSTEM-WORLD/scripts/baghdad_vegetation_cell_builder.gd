extends RefCounted
class_name BaghdadVegetationCellBuilder

## Deterministic OSM-grounded vegetation batches. Only mapped green/water polygons
## receive plants; cell ownership makes unloading automatic with the OSM streamer.

const MUNICIPAL_AREA_M2 := 861080000.0
const TARGET_PLANT_COUNT := 1000000
const CATEGORY_TARGETS := {
	"large_trees": 150000,
	"palms": 100000,
	"ornamental_fruit": 150000,
	"shrubs": 250000,
	"flowers_groundcover": 250000,
	"aquatic_riparian": 100000
}
const LAND_TARGET_COUNT := 900000
const AQUATIC_TARGET_COUNT := 100000
const TARGET_DENSITY_PER_M2 := float(TARGET_PLANT_COUNT) / MUNICIPAL_AREA_M2
const MAX_PLANTS_PER_CELL := 256

var rng := RandomNumberGenerator.new()
var meshes: Dictionary = {}
var materials: Dictionary = {}

func _init() -> void:
	_create_assets()

func _create_assets() -> void:
	meshes["large_trees"] = _make_tree_mesh(3.8, 2.4, 1.05, 3)
	meshes["palms"] = _make_palm_mesh()
	meshes["ornamental_fruit"] = _make_tree_mesh(2.5, 1.8, 0.78, 4)
	var shrub := SphereMesh.new()
	shrub.radius = 0.55
	shrub.height = 1.0
	meshes["shrubs"] = shrub
	var flower := SphereMesh.new()
	flower.radius = 0.18
	flower.height = 0.42
	meshes["flowers_groundcover"] = flower
	var aquatic := CylinderMesh.new()
	aquatic.top_radius = 0.035
	aquatic.bottom_radius = 0.09
	aquatic.height = 0.9
	meshes["aquatic_riparian"] = aquatic
	var palette := {
		"large_trees": Color(0.075, 0.25, 0.105),
		"palms": Color(0.16, 0.36, 0.16),
		"ornamental_fruit": Color(0.19, 0.39, 0.14),
		"shrubs": Color(0.12, 0.31, 0.105),
		"flowers_groundcover": Color(0.76, 0.48, 0.62),
		"aquatic_riparian": Color(0.12, 0.37, 0.29)
	}
	for key in palette:
		var material := StandardMaterial3D.new()
		material.albedo_color = palette[key]
		material.roughness = 0.94
		materials[key] = material


func _make_tree_mesh(trunk_height: float, crown_height: float, crown_radius: float, crown_count: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.15
	trunk.bottom_radius = 0.25
	trunk.height = trunk_height
	surface.append_from(trunk, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, trunk_height * 0.5, 0.0)))
	var crown := SphereMesh.new()
	crown.radius = crown_radius
	crown.height = crown_height
	for index in range(crown_count):
		var angle := TAU * float(index) / float(crown_count)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * crown_radius * 0.38
		var scale := Vector3(0.78, 0.82, 0.78) if index > 0 else Vector3.ONE
		surface.append_from(crown, 0, Transform3D(Basis.from_scale(scale), Vector3(offset.x, trunk_height + crown_height * 0.34, offset.z)))
	surface.generate_normals()
	return surface.commit()


func _make_palm_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.09
	trunk.bottom_radius = 0.19
	trunk.height = 4.2
	surface.append_from(trunk, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 2.1, 0.0)))
	var frond := SphereMesh.new()
	frond.radius = 1.0
	frond.height = 0.22
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var direction := Vector3(cos(angle), 0.24, sin(angle)).normalized()
		var basis := Basis().looking_at(direction, Vector3.UP)
		basis = basis.scaled(Vector3(0.92, 0.12, 0.20))
		surface.append_from(frond, 0, Transform3D(basis, Vector3(0.0, 4.15, 0.0) + direction * 0.48))
	surface.generate_normals()
	return surface.commit()

func build_cell(parent: Node3D, cell: Vector2i, landuse_features: Array,
		water_features: Array, terrain_height: Callable) -> Dictionary:
	var seed_text := "baghdad_vegetation_%d_%d" % [cell.x, cell.y]
	rng.seed = absi(hash(seed_text))
	var batches: Dictionary = {
		"large_trees": [], "palms": [], "ornamental_fruit": [],
		"shrubs": [], "flowers_groundcover": [], "aquatic_riparian": []
	}
	var eligible_area := 0.0
	var generated_total := 0
	for feature in landuse_features:
		if not _is_green_landuse(feature.get("tags", {})):
			continue
		for ring in _rings(feature.get("geometry", {})):
			var area := _polygon_area(ring)
			if area < 4.0:
				continue
			eligible_area += area
			var amount := mini(MAX_PLANTS_PER_CELL - generated_total, roundi(area * TARGET_DENSITY_PER_M2))
			for index in range(amount):
				var point := _random_point_in_ring(ring)
				if point == Vector2.INF:
					continue
				var category := _roll_land_category()
				var y := float(terrain_height.call(point)) + _plant_lift(category)
				batches[category].append(_plant_transform(category, point, y))
				generated_total += 1
	var aquatic_area := 0.0
	for feature in water_features:
		for ring in _rings(feature.get("geometry", {})):
			var area := _polygon_area(ring)
			if area < 4.0:
				continue
			aquatic_area += area
			var amount := mini(MAX_PLANTS_PER_CELL - generated_total, roundi(area * TARGET_DENSITY_PER_M2 * 0.10))
			for index in range(amount):
				var point := _random_riparian_point(ring)
				if point == Vector2.INF:
					continue
				var y := float(terrain_height.call(point)) + 0.12
				batches["aquatic_riparian"].append(_plant_transform("aquatic_riparian", point, y))
				generated_total += 1
	var counts: Dictionary = {}
	var total := 0
	for category in batches:
		var transforms: Array = batches[category]
		counts[category] = transforms.size()
		total += transforms.size()
		if not transforms.is_empty():
			_add_batch(parent, cell, str(category), transforms)
	parent.set_meta("baghdad_vegetation_counts", counts)
	parent.set_meta("baghdad_vegetation_total", total)
	return {
		"total": total,
		"green_area_m2": eligible_area,
		"water_area_m2": aquatic_area,
		"counts": counts,
		"target_density_per_km2": TARGET_DENSITY_PER_M2 * 1000000.0
	}

func _is_green_landuse(tags: Dictionary) -> bool:
	var landuse := str(tags.get("landuse", "")).to_lower()
	var leisure := str(tags.get("leisure", "")).to_lower()
	var natural := str(tags.get("natural", "")).to_lower()
	return landuse in ["grass", "forest", "orchard", "meadow", "allotments", "flowerbed", "village_green"] \
		or leisure in ["park", "garden", "nature_reserve", "recreation_ground"] \
		or natural in ["wood", "scrub", "grassland", "heath"]

func _roll_land_category() -> String:
	var roll := rng.randi_range(0, 89)
	if roll < 15:
		return "large_trees"
	if roll < 25:
		return "palms"
	if roll < 40:
		return "ornamental_fruit"
	if roll < 65:
		return "shrubs"
	return "flowers_groundcover"

func _plant_lift(category: String) -> float:
	match category:
		"large_trees", "palms", "ornamental_fruit":
			return 0.0
		"shrubs":
			return 0.5
		"flowers_groundcover":
			return 0.21
		_:
			return 0.45

func _plant_transform(category: String, point: Vector2, y: float) -> Transform3D:
	var scale_value := rng.randf_range(0.72, 1.32)
	var height_scale := rng.randf_range(0.85, 1.4)
	var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU))
	if category == "large_trees":
		basis = basis.scaled(Vector3(1.45, 2.2 * height_scale, 1.45) * scale_value)
	elif category == "palms":
		basis = basis.scaled(Vector3(0.58, 2.8 * height_scale, 0.58) * scale_value)
	elif category == "ornamental_fruit":
		basis = basis.scaled(Vector3(1.0, 1.35 * height_scale, 1.0) * scale_value)
	elif category == "shrubs":
		basis = basis.scaled(Vector3(1.1, 0.8 * height_scale, 1.1) * scale_value)
	elif category == "flowers_groundcover":
		basis = basis.scaled(Vector3(0.65, 0.7 * height_scale, 0.65) * scale_value)
	else:
		basis = basis.scaled(Vector3(0.32, 1.2 * height_scale, 0.32) * scale_value)
	return Transform3D(basis, Vector3(point.x, y, point.y))

func _rings(geometry: Dictionary) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var geometry_type := str(geometry.get("type", ""))
	if geometry_type == "GeometryCollection":
		for child in geometry.get("geometries", []):
			result.append_array(_rings(child))
		return result
	var coordinates: Variant = geometry.get("coordinates", [])
	var polygons: Array = []
	if geometry_type == "Polygon":
		polygons.append(coordinates)
	elif geometry_type == "MultiPolygon":
		polygons = coordinates
	else:
		return result
	for polygon in polygons:
		if not polygon is Array or polygon.is_empty():
			continue
		var outer: Variant = polygon[0]
		if not outer is Array:
			continue
		var ring := PackedVector2Array()
		for coordinate in outer:
			if coordinate is Array and coordinate.size() >= 2:
				ring.append(Vector2(float(coordinate[0]), float(coordinate[1])))
		if ring.size() > 2 and ring[0].is_equal_approx(ring[ring.size() - 1]):
			ring.remove_at(ring.size() - 1)
		if ring.size() >= 3:
			result.append(ring)
	return result

func _polygon_area(ring: PackedVector2Array) -> float:
	var twice_area := 0.0
	for index in range(ring.size()):
		var next := (index + 1) % ring.size()
		twice_area += ring[index].x * ring[next].y - ring[next].x * ring[index].y
	return absf(twice_area) * 0.5

func _random_riparian_point(ring: PackedVector2Array) -> Vector2:
	if ring.size() < 3:
		return Vector2.INF
	var centroid := Vector2.ZERO
	for point in ring:
		centroid += point
	centroid /= float(ring.size())
	var edge_index := rng.randi_range(0, ring.size() - 1)
	var start := ring[edge_index]
	var finish := ring[(edge_index + 1) % ring.size()]
	var edge_point := start.lerp(finish, rng.randf_range(0.15, 0.85))
	var outward := (edge_point - centroid).normalized()
	if outward.length_squared() < 0.5:
		return Vector2.INF
	return edge_point + outward * rng.randf_range(0.8, 2.8)

func _random_point_in_ring(ring: PackedVector2Array) -> Vector2:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for point in ring:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_z = minf(min_z, point.y)
		max_z = maxf(max_z, point.y)
	for _attempt in range(48):
		var point := Vector2(rng.randf_range(min_x, max_x), rng.randf_range(min_z, max_z))
		if Geometry2D.is_point_in_polygon(point, ring):
			return point
	return Vector2.INF

func _add_batch(parent: Node3D, cell: Vector2i, category: String, transforms: Array) -> void:
	var packed := MultiMesh.new()
	packed.transform_format = MultiMesh.TRANSFORM_3D
	packed.mesh = meshes[category]
	packed.instance_count = transforms.size()
	for index in range(transforms.size()):
		packed.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = "BaghdadVegetation_%s_%d_%d" % [category, cell.x, cell.y]
	instance.multimesh = packed
	instance.material_override = materials[category]
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = 450.0
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	parent.add_child(instance)
