extends Node3D
class_name BaghdadOSMCellStreamer

## Loads the first real Baghdad OSM cell pack in the same local tangent frame
## used by SystemRealWorldGeographyManager. Source IDs and OSM tags are retained.

const DEFAULT_DATA_ROOT := "res://data/geography/baghdad/cell_pack"
const DEFAULT_CELL_SIZE := 200.0
const MAX_CELL_OPERATIONS_PER_FRAME := 1

var data_root := DEFAULT_DATA_ROOT
var cell_size := DEFAULT_CELL_SIZE
var min_cell_x := -2
var max_cell_x := 2
var min_cell_z := -2
var max_cell_z := 2
var load_radius := 1
var terrain_manager: Node
var loaded_cells: Dictionary = {}
var desired_cells: Dictionary = {}
var pending_loads: Array[Vector2i] = []
var pending_unloads: Array[Vector2i] = []
var enabled := false
var _last_center_cell := Vector2i(2147483647, 2147483647)

var road_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var water_material: StandardMaterial3D
var land_material: StandardMaterial3D
var building_material: StandardMaterial3D
var amenity_material: StandardMaterial3D


func _ready() -> void:
	var manifest_path := data_root.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		push_warning("SYSTEM Baghdad OSM: cell pack is not installed; procedural Baghdad fallback remains active.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary or str(parsed.get("region_id", "")) != "iraq_baghdad_region":
		push_error("SYSTEM Baghdad OSM: invalid region manifest.")
		return
	var origin: Dictionary = parsed.get("origin", {})
	var origin_lat := float(origin.get("latitude", 0.0))
	var origin_lon := float(origin.get("longitude", 0.0))
	var projected_origin: Vector3 = SystemRealWorldGeography.to_local_world_position(
		"iraq_baghdad_region", origin_lat, origin_lon, 0.0
	)
	if absf(projected_origin.x) > 0.05 or absf(projected_origin.z) > 0.05:
		push_error("SYSTEM Baghdad OSM: cell pack origin does not match the canonical WGS84 region origin.")
		return
	var axes: Dictionary = parsed.get("axes", {})
	if str(axes.get("x", "")) != "east_m" or str(axes.get("z", "")) != "south_m":
		push_error("SYSTEM Baghdad OSM: unsupported local coordinate axes.")
		return
	cell_size = float(parsed.get("cell_size_m", DEFAULT_CELL_SIZE))
	var bounds: Array = parsed.get("cell_bounds_inclusive", [-2, 2, -2, 2])
	if bounds.size() != 4 or cell_size <= 0.0:
		push_error("SYSTEM Baghdad OSM: invalid cell manifest bounds.")
		return
	min_cell_x = int(bounds[0])
	max_cell_x = int(bounds[1])
	min_cell_z = int(bounds[2])
	max_cell_z = int(bounds[3])
	terrain_manager = get_parent().get_node_or_null("ModernContinent")
	_create_materials()
	_add_attribution_overlay()
	enabled = true
	print("SYSTEM Baghdad OSM: metric cell pack ready; cell size ", cell_size, " m.")


func _process(_delta: float) -> void:
	if not enabled:
		return
	var players := get_tree().get_nodes_in_group("system_player")
	if players.is_empty() or not is_instance_valid(players[0]):
		return
	var player_position: Vector3 = players[0].global_position
	var center := Vector2i(floori(player_position.x / cell_size), floori(player_position.z / cell_size))
	if center != _last_center_cell:
		_last_center_cell = center
		_refresh_desired_cells(center)
	_process_cell_queue()


func _add_attribution_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BaghdadOSMAttribution"
	layer.layer = 30
	var label := Label.new()
	label.name = "OpenStreetMapCredit"
	label.text = "© OpenStreetMap contributors · BBBike.org · ODbL 1.0"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.98, 0.92))
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.offset_left = 8.0
	label.offset_top = 8.0
	label.offset_right = -8.0
	label.offset_bottom = 28.0
	layer.add_child(label)
	add_child(layer)


func _create_materials() -> void:
	road_material = StandardMaterial3D.new()
	road_material.albedo_color = Color(0.075, 0.082, 0.09)
	road_material.roughness = 0.96
	road_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	bridge_material = StandardMaterial3D.new()
	bridge_material.albedo_color = Color(0.34, 0.35, 0.36)
	bridge_material.roughness = 0.82
	bridge_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	water_material = StandardMaterial3D.new()
	water_material.albedo_color = Color(0.025, 0.24, 0.34, 0.94)
	water_material.roughness = 0.18
	water_material.metallic = 0.18
	water_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	land_material = StandardMaterial3D.new()
	land_material.albedo_color = Color(0.18, 0.34, 0.19)
	land_material.roughness = 1.0
	land_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	building_material = StandardMaterial3D.new()
	building_material.albedo_color = Color(0.55, 0.48, 0.38)
	building_material.roughness = 0.88
	building_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	amenity_material = StandardMaterial3D.new()
	amenity_material.albedo_color = Color(0.15, 0.76, 0.91)
	amenity_material.emission_enabled = true
	amenity_material.emission = Color(0.04, 0.28, 0.4)
	amenity_material.emission_energy_multiplier = 0.45


func _refresh_desired_cells(center: Vector2i) -> void:
	desired_cells.clear()
	pending_loads.clear()
	pending_unloads.clear()
	for z in range(maxi(min_cell_z, center.y - load_radius), mini(max_cell_z, center.y + load_radius) + 1):
		for x in range(maxi(min_cell_x, center.x - load_radius), mini(max_cell_x, center.x + load_radius) + 1):
			var cell := Vector2i(x, z)
			desired_cells[cell] = true
			if not loaded_cells.has(cell):
				pending_loads.append(cell)
	for key in loaded_cells.keys():
		var cell: Vector2i = key
		if not desired_cells.has(cell):
			pending_unloads.append(cell)
	if pending_loads.has(center):
		pending_loads.erase(center)
		pending_loads.push_front(center)


func _process_cell_queue() -> void:
	var operations := 0
	while not pending_loads.is_empty() and operations < MAX_CELL_OPERATIONS_PER_FRAME:
		_load_cell(pending_loads.pop_front())
		operations += 1
	while not pending_unloads.is_empty() and operations < MAX_CELL_OPERATIONS_PER_FRAME:
		_unload_cell(pending_unloads.pop_front())
		operations += 1


func _load_cell(cell: Vector2i) -> void:
	if loaded_cells.has(cell):
		return
	var path := data_root.path_join("cells").path_join("%d_%d.json" % [cell.x, cell.y])
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("SYSTEM Baghdad OSM: invalid cell file: " + path)
		return
	var cell_root := Node3D.new()
	cell_root.name = "BaghdadOSMCell_%d_%d" % [cell.x, cell.y]
	cell_root.set_meta("cell_id", "%d:%d" % [cell.x, cell.y])
	var layers: Dictionary = parsed.get("layers", {})
	var counts := {}
	for feature in layers.get("buildings", []):
		_build_building_feature(cell_root, feature)
	counts["buildings"] = cell_root.get_child_count()
	var road_count := 0
	for feature in layers.get("roads", []):
		road_count += _build_line_feature(cell_root, feature, _road_width(feature.get("tags", {})), road_material, 0.16, "OSMRoad")
	var water_count := 0
	for feature in layers.get("waterways", []):
		water_count += _build_line_feature(cell_root, feature, _water_width(feature.get("tags", {})), water_material, 0.10, "OSMWaterway")
	var bridge_count := 0
	for feature in layers.get("bridges", []):
		bridge_count += _build_line_feature(cell_root, feature, maxf(_road_width(feature.get("tags", {})), 3.0), bridge_material, 0.28, "OSMBridge")
	for feature in layers.get("railway", []):
		_build_line_feature(cell_root, feature, 2.2, bridge_material, 0.20, "OSMRailway")
	for feature in layers.get("landuse", []):
		_build_area_feature(cell_root, feature, land_material, 0.035, "OSMLanduse")
	for feature in layers.get("natural-water", []):
		_build_area_feature(cell_root, feature, water_material, 0.08, "OSMNaturalWater")
	var amenity_count := 0
	for feature in layers.get("amenities", []):
		amenity_count += _build_amenity_feature(cell_root, feature)
	counts["roads"] = road_count
	counts["waterways"] = water_count
	counts["bridges"] = bridge_count
	counts["amenities"] = amenity_count
	cell_root.set_meta("feature_counts", counts)
	add_child(cell_root)
	loaded_cells[cell] = cell_root


func _build_building_feature(parent: Node3D, feature: Dictionary) -> void:
	var geometry: Dictionary = feature.get("geometry", {})
	var tags: Dictionary = feature.get("tags", {})
	var height := _building_height(tags)
	var geometry_type := str(geometry.get("type", ""))
	if geometry_type == "Point":
		_add_point_marker(parent, geometry.get("coordinates", []), amenity_material, 0.8, "OSMBuildingPoint")
		return
	for polygon in _extract_polygons(geometry):
		if polygon.size() < 4:
			continue
		var ring := PackedVector2Array()
		for coordinate in polygon:
			if coordinate is Array and coordinate.size() >= 2:
				ring.append(Vector2(float(coordinate[0]), float(coordinate[1])))
		if ring.size() > 2 and ring[0].is_equal_approx(ring[ring.size() - 1]):
			ring.remove_at(ring.size() - 1)
		if ring.size() < 3:
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(ring.size()):
			var next_index := (index + 1) % ring.size()
			var p0 := ring[index]
			var p1 := ring[next_index]
			var base0 := Vector3(p0.x, _terrain_height(p0) + 0.04, p0.y)
			var base1 := Vector3(p1.x, _terrain_height(p1) + 0.04, p1.y)
			var top0 := base0 + Vector3.UP * height
			var top1 := base1 + Vector3.UP * height
			_add_triangle(surface, base0, top0, base1)
			_add_triangle(surface, base1, top0, top1)
		var triangulation := Geometry2D.triangulate_polygon(ring)
		for index in range(0, triangulation.size(), 3):
			var p0 := ring[triangulation[index]]
			var p1 := ring[triangulation[index + 1]]
			var p2 := ring[triangulation[index + 2]]
			_add_triangle(
				surface,
				Vector3(p0.x, _terrain_height(p0) + height, p0.y),
				Vector3(p1.x, _terrain_height(p1) + height, p1.y),
				Vector3(p2.x, _terrain_height(p2) + height, p2.y)
			)
		surface.generate_normals()
		var mesh := surface.commit()
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var feature_id := str(feature.get("id", "unknown"))
		var building := MeshInstance3D.new()
		building.name = "OSMBuilding_%s" % feature_id
		building.mesh = mesh
		building.material_override = building_material
		building.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		building.set_meta("osm_feature_id", feature_id)
		parent.add_child(building)
		var body := StaticBody3D.new()
		body.name = "OSMBuildingCollision_%s" % feature_id
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(mesh.get_faces())
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)


func _build_line_feature(parent: Node3D, feature: Dictionary, width: float, material: Material, lift: float, prefix: String) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	var lines := _extract_lines(geometry)
	var built := 0
	for line in lines:
		if line.size() < 2:
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(line.size() - 1):
			var p0: Vector2 = line[index]
			var p1: Vector2 = line[index + 1]
			var direction := p1 - p0
			if direction.length_squared() < 0.0001:
				continue
			var side := Vector2(-direction.y, direction.x).normalized() * width * 0.5
			var a2 := p0 + side
			var b2 := p0 - side
			var c2 := p1 + side
			var d2 := p1 - side
			var a := Vector3(a2.x, _terrain_height(a2) + lift, a2.y)
			var b := Vector3(b2.x, _terrain_height(b2) + lift, b2.y)
			var c := Vector3(c2.x, _terrain_height(c2) + lift, c2.y)
			var d := Vector3(d2.x, _terrain_height(d2) + lift, d2.y)
			_add_triangle(surface, a, c, b)
			_add_triangle(surface, b, c, d)
		surface.generate_normals()
		var mesh := surface.commit()
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var instance := MeshInstance3D.new()
		instance.name = "%s_%s_%02d" % [prefix, str(feature.get("id", "unknown")), built]
		instance.mesh = mesh
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.set_meta("osm_feature_id", str(feature.get("id", "")))
		parent.add_child(instance)
		built += 1
	return built


func _build_area_feature(parent: Node3D, feature: Dictionary, material: Material, lift: float, prefix: String) -> void:
	var geometry: Dictionary = feature.get("geometry", {})
	for polygon in _extract_polygons(geometry):
		if polygon.size() < 4:
			continue
		var ring := PackedVector2Array()
		for coordinate in polygon:
			if coordinate is Array and coordinate.size() >= 2:
				ring.append(Vector2(float(coordinate[0]), float(coordinate[1])))
		if ring.size() > 2 and ring[0].is_equal_approx(ring[ring.size() - 1]):
			ring.remove_at(ring.size() - 1)
		if ring.size() < 3:
			continue
		var triangulation := Geometry2D.triangulate_polygon(ring)
		if triangulation.is_empty():
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(0, triangulation.size(), 3):
			var p0 := ring[triangulation[index]]
			var p1 := ring[triangulation[index + 1]]
			var p2 := ring[triangulation[index + 2]]
			_add_triangle(
				surface,
				Vector3(p0.x, _terrain_height(p0) + lift, p0.y),
				Vector3(p1.x, _terrain_height(p1) + lift, p1.y),
				Vector3(p2.x, _terrain_height(p2) + lift, p2.y)
			)
		surface.generate_normals()
		var mesh := surface.commit()
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var instance := MeshInstance3D.new()
		instance.name = "%s_%s" % [prefix, str(feature.get("id", "unknown"))]
		instance.mesh = mesh
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)


func _build_amenity_feature(parent: Node3D, feature: Dictionary) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	if str(geometry.get("type", "")) != "Point":
		return 0
	_add_point_marker(parent, geometry.get("coordinates", []), amenity_material, 0.48, "OSMAmenity_%s" % str(feature.get("id", "")))
	return 1


func _add_point_marker(parent: Node3D, coordinates: Array, material: Material, radius: float, node_name: String) -> void:
	if coordinates.size() < 2:
		return
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var marker := MeshInstance3D.new()
	marker.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	marker.mesh = mesh
	marker.position = Vector3(point.x, _terrain_height(point) + radius, point.y)
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(marker)


func _extract_lines(geometry: Dictionary) -> Array:
	var result: Array = []
	match str(geometry.get("type", "")):
		"LineString":
			result.append(_coordinates_to_line(geometry.get("coordinates", [])))
		"MultiLineString":
			for coordinates in geometry.get("coordinates", []):
				result.append(_coordinates_to_line(coordinates))
		"GeometryCollection":
			for child in geometry.get("geometries", []):
				result.append_array(_extract_lines(child))
	return result


func _coordinates_to_line(coordinates: Array) -> PackedVector2Array:
	var line := PackedVector2Array()
	for coordinate in coordinates:
		if coordinate is Array and coordinate.size() >= 2:
			line.append(Vector2(float(coordinate[0]), float(coordinate[1])))
	return line


func _extract_polygons(geometry: Dictionary) -> Array:
	var result: Array = []
	match str(geometry.get("type", "")):
		"Polygon":
			var rings: Array = geometry.get("coordinates", [])
			if not rings.is_empty():
				result.append(rings[0])
		"MultiPolygon":
			for polygon in geometry.get("coordinates", []):
				if not polygon.is_empty():
					result.append(polygon[0])
		"GeometryCollection":
			for child in geometry.get("geometries", []):
				result.append_array(_extract_polygons(child))
	return result


func _terrain_height(point: Vector2) -> float:
	if is_instance_valid(terrain_manager) and terrain_manager.has_method("get_terrain_height"):
		return float(terrain_manager.call("get_terrain_height", point.x, point.y))
	return 0.0


func _road_width(tags: Dictionary) -> float:
	var kind := str(tags.get("highway", "residential"))
	var widths := {
		"motorway": 12.0, "trunk": 10.0, "primary": 8.5,
		"secondary": 7.0, "tertiary": 6.0, "residential": 5.0,
		"living_street": 4.5, "service": 3.4, "unclassified": 4.8,
		"footway": 1.8, "path": 1.5, "cycleway": 2.0
	}
	var width := float(widths.get(kind, 4.0))
	var explicit_width := str(tags.get("width", "")).replace(" m", "").to_float()
	if explicit_width > 0.5 and explicit_width < 40.0:
		width = explicit_width
	return width


func _water_width(tags: Dictionary) -> float:
	var kind := str(tags.get("waterway", "stream"))
	var widths := {"river": 18.0, "canal": 7.0, "stream": 2.4, "ditch": 1.2, "drain": 0.9}
	var width := float(widths.get(kind, 2.0))
	var explicit_width := str(tags.get("width", "")).replace(" m", "").to_float()
	if explicit_width > 0.5 and explicit_width < 100.0:
		width = explicit_width
	return width


func _building_height(tags: Dictionary) -> float:
	var explicit_height := str(tags.get("height", "")).replace(" m", "").to_float()
	if explicit_height >= 2.5 and explicit_height <= 180.0:
		return explicit_height
	var levels := str(tags.get("building:levels", "")).to_int()
	if levels > 0 and levels <= 60:
		return float(levels) * 3.2
	return 6.0


func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _unload_cell(cell: Vector2i) -> void:
	if not loaded_cells.has(cell):
		return
	var node: Node3D = loaded_cells[cell]
	loaded_cells.erase(cell)
	if is_instance_valid(node):
		node.queue_free()


func get_streaming_status() -> Dictionary:
	return {
		"enabled": enabled,
		"loaded_cell_count": loaded_cells.size(),
		"queued_load_count": pending_loads.size(),
		"queued_unload_count": pending_unloads.size(),
		"cell_size_m": cell_size,
		"source_license": "ODbL-1.0",
		"source_attribution": "© OpenStreetMap contributors; © BBBike.org",
		"real_scale_baghdad_pack": true,
		"canonical_origin_frame_valid": true
	}
