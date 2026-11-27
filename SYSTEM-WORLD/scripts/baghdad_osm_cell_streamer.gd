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
var overview_mode := false
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
var facade_window_material: StandardMaterial3D
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
	if str(parsed.get("coordinate_system", "")) != "SYSTEM_LOCAL_ECEF_TANGENT":
		push_error("SYSTEM Baghdad OSM: unsupported coordinate projection.")
		return
	var origin: Dictionary = parsed.get("origin", {})
	var origin_lat := float(origin.get("latitude", 0.0))
	var origin_lon := float(origin.get("longitude", 0.0))
	var registry_path := "res://data/geography/real_world_registry.json"
	if not FileAccess.file_exists(registry_path):
		push_error("SYSTEM Baghdad OSM: canonical geography registry is missing.")
		return
	var registry: Variant = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
	if not registry is Dictionary:
		push_error("SYSTEM Baghdad OSM: canonical geography registry is invalid.")
		return
	var regions: Dictionary = registry.get("regions", {})
	var region_record: Dictionary = regions.get("iraq_baghdad_region", {})
	var canonical_origin: Dictionary = region_record.get("origin", {})
	if canonical_origin.is_empty():
		push_error("SYSTEM Baghdad OSM: canonical Baghdad region origin is missing from the geography registry.")
		return
	if absf(origin_lat - float(canonical_origin.get("latitude", 0.0))) > 0.000001 or absf(origin_lon - float(canonical_origin.get("longitude", 0.0))) > 0.000001:
		push_error("SYSTEM Baghdad OSM: cell pack origin differs from the canonical WGS84 registry anchor.")
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

	facade_window_material = StandardMaterial3D.new()
	facade_window_material.albedo_color = Color.WHITE
	facade_window_material.roughness = 0.24
	facade_window_material.metallic = 0.42
	facade_window_material.vertex_color_use_as_albedo = true
	facade_window_material.cull_mode = BaseMaterial3D.CULL_DISABLED

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
	var road_features: Array = layers.get("roads", [])
	var road_count := 0
	for feature in road_features:
		road_count += _build_line_feature(cell_root, feature, _road_width(feature.get("tags", {})), road_material, 0.16, "OSMRoad")
	var building_count := 0
	for feature in layers.get("buildings", []):
		if overview_mode:
			building_count += _build_building_overview_feature(cell_root, feature)
		else:
			building_count += _build_building_feature(cell_root, feature, road_features)
	if not overview_mode:
		_flush_facade_window_multimesh(cell_root)
	counts["buildings"] = building_count
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
	for feature in layers.get("wetlands", []):
		_build_area_feature(cell_root, feature, land_material, 0.12, "OSMWetland")
	var amenity_count := 0
	for feature in layers.get("amenities", []):
		if overview_mode:
			amenity_count += _build_regional_poi_feature(cell_root, feature)
		else:
			amenity_count += _build_amenity_feature(cell_root, feature)
	var entrance_count := 0
	if not overview_mode:
		for feature in layers.get("entrances", []):
			entrance_count += _build_entrance_feature(cell_root, feature)
	counts["entrances"] = entrance_count
	counts["roads"] = road_count
	counts["waterways"] = water_count
	counts["bridges"] = bridge_count
	counts["amenities"] = amenity_count
	cell_root.set_meta("feature_counts", counts)
	add_child(cell_root)
	loaded_cells[cell] = cell_root




func _build_building_overview_feature(parent: Node3D, feature: Dictionary) -> int:
	var tags: Dictionary = feature.get("tags", {})
	var geometry: Dictionary = feature.get("geometry", {})
	var polygons := _extract_polygons(geometry)
	if polygons.is_empty():
		return 0
	var height := _building_height(tags)
	var kind := _building_kind(tags)
	var feature_id := str(feature.get("id", "unknown"))
	var built := 0
	for polygon in polygons:
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
		var center := Vector2.ZERO
		for point in ring:
			center += point
		center /= float(ring.size())
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
			_add_triangle(surface,
				Vector3(p0.x, _terrain_height(p0) + height, p0.y),
				Vector3(p1.x, _terrain_height(p1) + height, p1.y),
				Vector3(p2.x, _terrain_height(p2) + height, p2.y))
		surface.generate_normals()
		var mesh := _commit_surface_tool_if_valid(surface)
		if mesh == null:
			continue
		var instance := MeshInstance3D.new()
		instance.name = "OSMOverviewBuilding_%s" % feature_id
		instance.mesh = mesh
		instance.material_override = _building_material_for(kind)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.set_meta("osm_feature_id", feature_id)
		instance.set_meta("baghdad_building_type", kind)
		instance.set_meta("system_architecture_class", kind)
		var amenity_kind := str(tags.get("amenity", "")).to_lower()
		var facility_type := ""
		if amenity_kind == "hospital" or str(tags.get("healthcare", "")).to_lower() in ["hospital", "clinic"]:
			facility_type = "healthcare"
		elif amenity_kind == "place_of_worship" and str(tags.get("religion", "")).to_lower() in ["christian", "christianity"]:
			facility_type = "church"
		elif amenity_kind in ["police", "police_station"]:
			facility_type = "police"
		elif amenity_kind == "place_of_worship" and str(tags.get("religion", "")).to_lower() == "muslim":
			facility_type = "mosque"
		elif str(tags.get("shop", "")) != "":
			facility_type = "shop"
		elif amenity_kind in ["restaurant", "cafe", "fast_food", "food_court"]:
			facility_type = "food"
		if facility_type != "":
			instance.set_meta("system_facility_type", facility_type)
		instance.set_meta("system_display_name", _building_display_name(kind, tags))
		instance.set_meta("system_building_height_m", height)
		instance.set_meta("system_estimated_floors", maxi(1, int(ceil(height / 3.2))))
		instance.set_meta("system_residential_luxury_class", kind in ["villa", "palace"])
		instance.set_meta("system_footprint_geometry", "osm_polygon_extrusion")
		instance.set_meta("system_facade_detail_level", "regional_extrusion_lod")
		instance.set_meta("system_access_state", "regional_exterior_lod_no_collision_or_interior")
		parent.add_child(instance)
		if kind in ["mosque", "church"]:
			_add_polygon_worship_detail(parent, ring, height, kind, feature_id)
		built += 1
	return built


func _build_regional_poi_feature(parent: Node3D, feature: Dictionary) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	var geometry_type := str(geometry.get("type", ""))
	var point := Vector2.ZERO
	if geometry_type == "Point":
		var coordinates: Array = geometry.get("coordinates", [])
		if coordinates.size() < 2:
			return 0
		point = Vector2(float(coordinates[0]), float(coordinates[1]))
	elif geometry_type in ["Polygon", "MultiPolygon"]:
		var polygons := _extract_polygons(geometry)
		if polygons.is_empty() or polygons[0].is_empty():
			return 0
		for coordinate in polygons[0]:
			if coordinate is Array and coordinate.size() >= 2:
				point += Vector2(float(coordinate[0]), float(coordinate[1]))
		point /= float(polygons[0].size())
	else:
		return 0
	var tags: Dictionary = feature.get("tags", {})
	var amenity := str(tags.get("amenity", "")).to_lower()
	var shop := str(tags.get("shop", "")).to_lower()
	var healthcare := str(tags.get("healthcare", "")).to_lower()
	var facility_type := "public_service"
	var display_name := "مرفق خدمي"
	if amenity in ["hospital", "clinic", "doctors", "pharmacy"] or healthcare != "":
		facility_type = "healthcare"
		display_name = "مرفق صحي"
	elif amenity in ["police", "police_station"]:
		facility_type = "police"
		display_name = "مركز شرطة"
	elif amenity == "place_of_worship" and str(tags.get("religion", "")).to_lower() == "muslim":
		facility_type = "mosque"
		display_name = "جامع أو مسجد"
	elif amenity == "place_of_worship" and str(tags.get("religion", "")).to_lower() in ["christian", "christianity"]:
		facility_type = "church"
		display_name = "كنيسة"
	elif str(tags.get("building", "")).to_lower() == "church":
		facility_type = "church"
		display_name = "كنيسة"
	elif shop != "":
		facility_type = "shop"
		display_name = "محل تجاري"
	elif amenity in ["restaurant", "cafe", "fast_food", "food_court"]:
		facility_type = "food"
		display_name = "مطعم أو مقهى"
	elif amenity in ["school", "university", "college", "kindergarten"]:
		facility_type = "education"
		display_name = "مؤسسة تعليمية"
	elif amenity in ["fire_station", "post_office", "bank", "townhall", "library"]:
		facility_type = "civic"
		display_name = "مرفق عام"
	var custom_name := str(tags.get("name:ar", tags.get("name", ""))).strip_edges()
	if custom_name != "":
		display_name = custom_name
	var marker := Node3D.new()
	var feature_id := str(feature.get("id", "unknown"))
	marker.name = "OSMRegionalPOI_%s_%s" % [facility_type, feature_id]
	marker.position = Vector3(point.x, _terrain_height(point) + 0.65, point.y)
	marker.set_meta("osm_feature_id", feature_id)
	marker.set_meta("system_facility_type", facility_type)
	marker.set_meta("system_display_name", display_name)
	marker.set_meta("system_access_state", "mapped_poi_marker_no_verified_interior")
	marker.set_meta("osm_tags", tags)
	var visual := MeshInstance3D.new()
	visual.name = "POIMarker"
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.38
	marker_mesh.bottom_radius = 0.58
	marker_mesh.height = 1.3
	visual.mesh = marker_mesh
	visual.material_override = amenity_material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(visual)
	parent.add_child(marker)
	return 1

func _build_building_feature(parent: Node3D, feature: Dictionary, road_features: Array) -> int:
	var built := 0
	var geometry: Dictionary = feature.get("geometry", {})
	var tags: Dictionary = feature.get("tags", {})
	var height := _building_height(tags)
	var kind := _building_kind(tags)
	var geometry_type := str(geometry.get("type", ""))
	if geometry_type == "Point":
		_add_point_marker(parent, geometry.get("coordinates", []), amenity_material, 0.8, "OSMBuildingPoint")
		return 0
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
		var mesh := _commit_surface_tool_if_valid(surface)
		if mesh == null:
			continue
		var feature_id := str(feature.get("id", "unknown"))
		var building := MeshInstance3D.new()
		building.name = "OSMBuilding_%s_%s" % [kind, feature_id]
		building.mesh = mesh
		building.material_override = _building_material_for(kind)
		building.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		building.set_meta("osm_feature_id", feature_id)
		building.set_meta("baghdad_building_type", kind)
		building.set_meta("osm_building_tag", str(tags.get("building", "yes")))
		parent.add_child(building)
		var facade_window_count := _add_procedural_facade_windows(parent, ring, height, kind, feature_id)
		building.set_meta("system_facade_detail_level", "core_multimesh_windows" if facade_window_count > 0 else "core_extrusion_only")
		building.set_meta("system_facade_window_count", facade_window_count)
		building.set_meta("system_facade_window_sampling", "even_distribution_across_facades")
		var body := StaticBody3D.new()
		body.name = "OSMBuildingCollision_%s" % feature_id
		body.add_to_group("system_interactable")
		body.set_meta("osm_feature_id", feature_id)
		body.set_meta("baghdad_building_type", kind)
		body.set_meta("osm_building_tag", str(tags.get("building", "yes")))
		var footprint_center := Vector2.ZERO
		for footprint_point in ring:
			footprint_center += footprint_point
		footprint_center /= float(ring.size())
		var footprint_position := Vector3(
			footprint_center.x,
			_terrain_height(footprint_center),
			footprint_center.y
		)
		var estimated_floors := maxi(1, int(ceil(height / 3.2)))
		body.set_meta("system_location_position", footprint_position)
		body.set_meta("system_building_height_m", height)
		body.set_meta("system_estimated_floors", estimated_floors)
		body.set_meta("system_access_state", "exterior_only")
		body.set_meta("system_location_id", "baghdad_osm_building_" + feature_id)
		body.set_meta("system_region_id", "region_baghdad")
		body.set_meta("system_location_type", 7)
		body.set_meta("system_fast_travel", false)
		body.set_meta("system_display_name", _building_display_name(kind, tags))
		body.set_meta("system_interaction_prompt", "استكشاف معلومات المبنى")
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(mesh.get_faces())
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
		var approach := _find_building_approach_point(ring, road_features)
		if not approach.is_empty():
			_add_building_approach_marker(parent, approach, feature_id, kind, tags)
		built += 1
		if kind == "church" or kind == "mosque":
			_add_polygon_worship_detail(parent, ring, height, kind, feature_id)
	return built


func _add_procedural_facade_windows(
	parent: Node3D,
	ring: PackedVector2Array,
	height: float,
	kind: String,
	feature_id: String
) -> int:
	# The 1 km regional overview stays as a cheap extrusion LOD. Only the
	# 200 m playable cells collect close-range facade windows.
	if overview_mode or height < 5.0 or ring.size() < 3 or kind in ["mosque", "church"]:
		return 0
	var window_size := Vector3(1.1, 1.4, 0.12)
	var spacing := 4.2
	match kind:
		"detached_house":
			window_size = Vector3(1.15, 1.45, 0.12)
			spacing = 4.3
		"villa", "palace":
			window_size = Vector3(1.5, 1.75, 0.14)
			spacing = 5.0
		"apartment_block":
			window_size = Vector3(1.05, 1.4, 0.12)
			spacing = 3.6
		"commercial_building":
			window_size = Vector3(1.45, 1.65, 0.14)
			spacing = 3.8
	var polygon_twice_area := 0.0
	for edge_index in range(ring.size()):
		var area_start := ring[edge_index]
		var area_finish := ring[(edge_index + 1) % ring.size()]
		polygon_twice_area += area_start.x * area_finish.y - area_finish.x * area_start.y
	if absf(polygon_twice_area) < 0.001:
		return 0
	var counter_clockwise := polygon_twice_area > 0.0
	var floor_count := clampi(int(floor(height / 3.2)), 1, 12)
	var candidate_transforms: Array[Transform3D] = []
	var candidate_colors: Array[Color] = []
	for edge_index in range(ring.size()):
		var start := ring[edge_index]
		var finish := ring[(edge_index + 1) % ring.size()]
		var edge := finish - start
		var edge_length := edge.length()
		if edge_length < spacing * 1.25:
			continue
		var windows_per_floor := clampi(int(floor(edge_length / spacing)), 1, 6)
		var edge_direction := edge / edge_length
		var outward_2d := Vector2(edge_direction.y, -edge_direction.x) if counter_clockwise else Vector2(-edge_direction.y, edge_direction.x)
		var outward := Vector3(outward_2d.x, 0.0, outward_2d.y)
		var facade_right := Vector3.UP.cross(outward).normalized()
		var facade_basis := Basis(facade_right, Vector3.UP, outward).scaled(window_size)
		for floor_index in range(floor_count):
			var floor_offset := 1.55 + float(floor_index) * 3.15
			if floor_offset + window_size.y * 0.5 >= height - 0.25:
				continue
			for window_index in range(windows_per_floor):
				var along_wall := float(window_index + 1) / float(windows_per_floor + 1)
				var point := start.lerp(finish, along_wall)
				var window_position := Vector3(
					point.x,
					_terrain_height(point) + floor_offset,
					point.y
				) + outward * 0.09
				candidate_transforms.append(Transform3D(facade_basis, window_position))
				var color_seed := absi(feature_id.hash() + edge_index * 17 + floor_index * 11 + window_index * 7)
				var window_color := Color(0.16, 0.34, 0.46)
				if color_seed % 7 == 0:
					window_color = Color(0.95, 0.71, 0.42)
				elif color_seed % 4 == 0:
					window_color = Color(0.42, 0.62, 0.72)
				candidate_colors.append(window_color)
	if candidate_transforms.is_empty():
		return 0
	# One cell-level MultiMesh keeps the whole 200 m cell to one facade draw call.
	# The per-building cap and per-cell cap bound memory on Android.
	var cell_transforms: Array = parent.get_meta("system_facade_window_transforms", [])
	var cell_colors: Array = parent.get_meta("system_facade_window_colors", [])
	var remaining_cell_budget := maxi(0, 1200 - cell_transforms.size())
	var building_budget := mini(32, remaining_cell_budget)
	if building_budget <= 0:
		return 0
	var selected_count := mini(candidate_transforms.size(), building_budget)
	var sample_step := float(candidate_transforms.size()) / float(selected_count)
	for sample_index in range(selected_count):
		var source_index := mini(
			candidate_transforms.size() - 1,
			int(floor((float(sample_index) + 0.5) * sample_step))
		)
		cell_transforms.append(candidate_transforms[source_index])
		cell_colors.append(candidate_colors[source_index])
	parent.set_meta("system_facade_window_transforms", cell_transforms)
	parent.set_meta("system_facade_window_colors", cell_colors)
	return selected_count


func _flush_facade_window_multimesh(parent: Node3D) -> void:
	var transforms: Array = parent.get_meta("system_facade_window_transforms", [])
	var colors: Array = parent.get_meta("system_facade_window_colors", [])
	if transforms.is_empty() or transforms.size() != colors.size():
		return
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3.ONE
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = window_mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_color(index, colors[index])
	var windows := MultiMeshInstance3D.new()
	windows.name = "BaghdadCellFacadeWindows"
	windows.multimesh = multimesh
	windows.material_override = facade_window_material
	windows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	windows.set_meta("system_facade_detail_type", "procedural_instanced_windows")
	windows.set_meta("system_facade_window_count", transforms.size())
	windows.set_meta("system_facade_window_sampling", "even_distribution_across_facades")
	windows.set_meta("system_facade_window_draw_calls_per_cell", 1)
	parent.add_child(windows)
	parent.set_meta("system_facade_window_instance_count", transforms.size())


func _find_building_approach_point(ring: PackedVector2Array, road_features: Array) -> Dictionary:
	var center := Vector2.ZERO
	for point in ring:
		center += point
	center /= float(ring.size())
	var best_distance := INF
	var best_road := Vector2.ZERO
	for road_feature in road_features:
		var road_tags: Dictionary = road_feature.get("tags", {})
		if str(road_tags.get("highway", "")).is_empty():
			continue
		for line in _extract_lines(road_feature.get("geometry", {})):
			for index in range(line.size() - 1):
				var candidate := _closest_point_on_segment(center, line[index], line[index + 1])
				var distance := center.distance_to(candidate)
				if distance < best_distance:
					best_distance = distance
					best_road = candidate
	if best_distance > 40.0 or best_distance == INF:
		return {}
	var best_boundary := ring[0]
	var boundary_distance := INF
	for index in range(ring.size()):
		var candidate := _closest_point_on_segment(best_road, ring[index], ring[(index + 1) % ring.size()])
		var distance := candidate.distance_to(best_road)
		if distance < boundary_distance:
			boundary_distance = distance
			best_boundary = candidate
	var outward := best_road - best_boundary
	if outward.length_squared() < 0.0001:
		return {}
	outward = outward.normalized()
	return {
		"position": best_boundary + outward * 1.8,
		"distance_to_road": boundary_distance
	}


func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared < 0.0001:
		return a
	var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return a + segment * t


func _add_building_approach_marker(parent: Node3D, approach: Dictionary, feature_id: String, kind: String, tags: Dictionary) -> void:
	var point: Vector2 = approach.get("position", Vector2.ZERO)
	var position := Vector3(point.x, _terrain_height(point), point.y)
	var location_id := "baghdad_osm_approach_" + feature_id
	var display_name := _building_display_name(kind, tags) + " — نقطة اقتراب"
	var root := Node3D.new()
	root.name = "OSMBuildingApproach_%s" % feature_id
	root.position = position
	root.set_meta("osm_feature_id", feature_id)
	root.set_meta("baghdad_building_type", kind)
	root.set_meta("system_access_state", "approach_only_no_verified_door")
	root.set_meta("system_approach_distance_m", float(approach.get("distance_to_road", 0.0)))
	parent.add_child(root)
	var marker := MeshInstance3D.new()
	marker.name = "ApproachMarkerVisual"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.42
	mesh.height = 0.8
	marker.mesh = mesh
	marker.position.y = 0.55
	marker.material_override = amenity_material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(marker)
	var body := StaticBody3D.new()
	body.name = "ApproachInteractionBody"
	body.add_to_group("system_interactable")
	var shape := SphereShape3D.new()
	shape.radius = 0.75
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	body.set_meta("system_location_id", location_id)
	body.set_meta("system_region_id", "region_baghdad")
	body.set_meta("system_location_type", 7)
	body.set_meta("system_fast_travel", false)
	body.set_meta("system_location_position", position)
	body.set_meta("system_display_name", display_name)
	body.set_meta("system_interaction_prompt", "فحص واجهة المبنى (نقطة اقتراب تقريبية)")
	body.set_meta("system_approach_distance_m", float(approach.get("distance_to_road", 0.0)))
	body.set_meta("system_building_height_m", _building_height(tags))
	body.set_meta("system_estimated_floors", maxi(1, int(ceil(_building_height(tags) / 3.2))))
	body.set_meta("system_access_state", "approach_only_no_verified_door")
	root.add_child(body)


func _building_display_name(kind: String, tags: Dictionary) -> String:
	var custom_name := str(tags.get("name:ar", tags.get("name", ""))).strip_edges()
	if not custom_name.is_empty():
		return custom_name
	match kind:
		"detached_house":
			return "منزل سكني"
		"villa":
			return "فيلا سكنية"
		"palace":
			return "قصر"
		"apartment_block":
			return "عمارة سكنية"
		"commercial_building":
			return "مبنى تجاري"
		"mosque":
			return "مسجد"
		"church":
			return "كنيسة"
		_:
			return "مبنى في بغداد"


func _add_polygon_worship_detail(parent: Node3D, ring: PackedVector2Array, height: float, kind: String, feature_id: String) -> void:
	var center := Vector2.ZERO
	for point in ring:
		center += point
	center /= float(ring.size())
	var detail_root := Node3D.new()
	detail_root.name = "OSMWorshipDetail_%s_%s" % [kind, feature_id]
	detail_root.position = Vector3(center.x, _terrain_height(center) + height, center.y)
	detail_root.set_meta("landmark_type", kind)
	detail_root.set_meta("osm_feature_id", feature_id)
	parent.add_child(detail_root)
	if kind == "mosque":
		var dome := MeshInstance3D.new()
		dome.name = "RoofDome"
		var dome_mesh := SphereMesh.new()
		dome_mesh.radius = 2.2
		dome_mesh.height = 2.8
		dome.mesh = dome_mesh
		dome.position.y = 1.1
		dome.material_override = _building_material_for("mosque")
		detail_root.add_child(dome)
		var minaret := MeshInstance3D.new()
		minaret.name = "MinaretMarker"
		var minaret_mesh := CylinderMesh.new()
		minaret_mesh.top_radius = 0.22
		minaret_mesh.bottom_radius = 0.38
		minaret_mesh.height = 7.0
		minaret.mesh = minaret_mesh
		minaret.position = Vector3(3.0, 3.5, 0.0)
		minaret.material_override = _building_material_for("mosque")
		detail_root.add_child(minaret)
	else:
		var tower := MeshInstance3D.new()
		tower.name = "ChurchBellTower"
		var tower_mesh := BoxMesh.new()
		tower_mesh.size = Vector3(1.5, 5.0, 1.5)
		tower.mesh = tower_mesh
		tower.position = Vector3(3.0, 2.5, 0.0)
		tower.material_override = _building_material_for("church")
		detail_root.add_child(tower)
		var cross := MeshInstance3D.new()
		cross.name = "ChurchCross"
		var cross_mesh := BoxMesh.new()
		cross_mesh.size = Vector3(0.35, 2.0, 0.35)
		cross.mesh = cross_mesh
		cross.position = Vector3(3.0, 5.7, 0.0)
		cross.material_override = _building_material_for("church")
		detail_root.add_child(cross)
		var cross_arm := MeshInstance3D.new()
		cross_arm.name = "ChurchCrossArm"
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(1.2, 0.3, 0.35)
		cross_arm.mesh = arm_mesh
		cross_arm.position = Vector3(3.0, 6.0, 0.0)
		cross_arm.material_override = _building_material_for("church")
		detail_root.add_child(cross_arm)


func _build_line_feature(parent: Node3D, feature: Dictionary, width: float, material: Material, lift: float, prefix: String) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	var lines := _extract_lines(geometry)
	var feature_id := str(feature.get("id", "unknown"))
	var feature_tags: Dictionary = feature.get("tags", {})
	var bridge_tag := str(feature_tags.get("bridge", "")).to_lower()
	var is_bridge := bridge_tag != "" and bridge_tag != "no"
	var republic_bridge_centerline := feature_id in ["4080878", "754157537"] and (prefix == "OSMBridge" or (prefix == "OSMRoad" and is_bridge))
	var non_republic_bridge_lift := maxf(lift, 4.0) if is_bridge else lift
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
			var a_height := 18.08 if republic_bridge_centerline else _terrain_height(a2) + non_republic_bridge_lift
			var b_height := 18.08 if republic_bridge_centerline else _terrain_height(b2) + non_republic_bridge_lift
			var c_height := 18.08 if republic_bridge_centerline else _terrain_height(c2) + non_republic_bridge_lift
			var d_height := 18.08 if republic_bridge_centerline else _terrain_height(d2) + non_republic_bridge_lift
			var a := Vector3(a2.x, a_height, a2.y)
			var b := Vector3(b2.x, b_height, b2.y)
			var c := Vector3(c2.x, c_height, c2.y)
			var d := Vector3(d2.x, d_height, d2.y)
			_add_triangle(surface, a, c, b)
			_add_triangle(surface, b, c, d)
		surface.generate_normals()
		var mesh := _commit_surface_tool_if_valid(surface)
		if mesh == null:
			continue
		var instance := MeshInstance3D.new()
		instance.name = "%s_%s_%02d" % [prefix, feature_id, built]
		instance.mesh = mesh
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.set_meta("osm_feature_id", feature_id)
		if republic_bridge_centerline:
			instance.set_meta("system_bridge_deck_height_override_m", 18.08)
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
		var mesh := _commit_surface_tool_if_valid(surface)
		if mesh == null:
			continue
		var instance := MeshInstance3D.new()
		instance.name = "%s_%s" % [prefix, str(feature.get("id", "unknown"))]
		instance.mesh = mesh
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)


func _build_entrance_feature(parent: Node3D, feature: Dictionary) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	if str(geometry.get("type", "")) != "Point":
		return 0
	var tags: Dictionary = feature.get("tags", {})
	var entrance_kind := str(tags.get("entrance", "")).to_lower()
	var door_kind := str(tags.get("door", "")).to_lower()
	if entrance_kind == "no" or door_kind == "no":
		return 0
	var coordinates: Array = geometry.get("coordinates", [])
	if coordinates.size() < 2:
		return 0
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var position := Vector3(point.x, _terrain_height(point), point.y)
	var feature_id := str(feature.get("id", "unknown"))
	var location_id := "baghdad_osm_entrance_" + feature_id
	var entrance_label := "مدخل مبنى موثق من بيانات OpenStreetMap"
	if entrance_kind == "main":
		entrance_label = "مدخل رئيسي موثق من بيانات OpenStreetMap"
	elif entrance_kind == "service":
		entrance_label = "مدخل خدمة موثق من بيانات OpenStreetMap"
	elif entrance_kind == "exit":
		entrance_label = "مخرج موثق من بيانات OpenStreetMap"
	elif door_kind != "":
		entrance_label = "باب موثق من بيانات OpenStreetMap"
	var root := Node3D.new()
	root.name = "OSMEntrance_%s" % feature_id
	root.position = position
	root.set_meta("osm_feature_id", feature_id)
	root.set_meta("system_access_state", "mapped_entrance_point_no_interior_scene")
	parent.add_child(root)
	var marker := MeshInstance3D.new()
	marker.name = "MappedEntranceMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.34
	mesh.height = 0.65
	marker.mesh = mesh
	marker.position.y = 0.42
	marker.material_override = amenity_material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(marker)
	var body := StaticBody3D.new()
	body.name = "MappedEntranceInteraction"
	body.add_to_group("system_interactable")
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	body.set_meta("osm_feature_id", feature_id)
	body.set_meta("system_location_id", location_id)
	body.set_meta("system_region_id", "region_baghdad")
	body.set_meta("system_location_type", 7)
	body.set_meta("system_fast_travel", false)
	body.set_meta("system_location_position", position)
	body.set_meta("system_display_name", entrance_label)
	body.set_meta("system_interaction_prompt", "مدخل محدد في بيانات الخريطة")
	body.set_meta("system_entrance_type", entrance_kind if entrance_kind != "" else door_kind)
	body.set_meta("system_access_tag", str(tags.get("access", "unknown")))
	body.set_meta("system_wheelchair_tag", str(tags.get("wheelchair", "unknown")))
	body.set_meta("system_access_state", "mapped_entrance_point_no_interior_scene")
	root.add_child(body)
	return 1


func _build_amenity_feature(parent: Node3D, feature: Dictionary) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	if str(geometry.get("type", "")) != "Point":
		return 0
	var tags: Dictionary = feature.get("tags", {})
	var coordinates: Array = geometry.get("coordinates", [])
	var worship := str(tags.get("amenity", "")) == "place_of_worship"
	var religion := str(tags.get("religion", "")).to_lower()
	var is_mosque := (worship and religion == "muslim") or str(tags.get("building", "")).to_lower() == "mosque"
	var is_church := (worship and religion == "christian") or str(tags.get("building", "")).to_lower() == "church"
	if is_mosque:
		_build_mosque_landmark(parent, feature, coordinates)
	elif is_church:
		_build_church_landmark(parent, feature, coordinates)
	else:
		_add_point_marker(parent, coordinates, amenity_material, 0.48, "OSMAmenity_%s" % str(feature.get("id", "")))
	return 1


func _build_church_landmark(parent: Node3D, feature: Dictionary, coordinates: Array) -> void:
	if coordinates.size() < 2:
		return
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var root := Node3D.new()
	root.name = "OSMChurch_%s" % str(feature.get("id", "unknown"))
	root.position = Vector3(point.x, _terrain_height(point) + 0.08, point.y)
	root.set_meta("landmark_type", "church")
	root.set_meta("osm_feature_id", str(feature.get("id", "")))
	parent.add_child(root)
	var stone := _building_material_for("church")
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Color(0.36, 0.24, 0.18)
	roof.roughness = 0.86
	var nave := MeshInstance3D.new()
	nave.name = "ChurchNave"
	var nave_mesh := BoxMesh.new()
	nave_mesh.size = Vector3(9.0, 5.0, 14.0)
	nave.mesh = nave_mesh
	nave.position.y = 2.5
	nave.material_override = stone
	root.add_child(nave)
	var tower := MeshInstance3D.new()
	tower.name = "BellTower"
	var tower_mesh := BoxMesh.new()
	tower_mesh.size = Vector3(2.2, 8.0, 2.2)
	tower.mesh = tower_mesh
	tower.position = Vector3(0.0, 4.0, -7.0)
	tower.material_override = stone
	root.add_child(tower)
	var cross := MeshInstance3D.new()
	cross.name = "CrossVertical"
	var cross_mesh := BoxMesh.new()
	cross_mesh.size = Vector3(0.35, 2.2, 0.35)
	cross.mesh = cross_mesh
	cross.position = Vector3(0.0, 9.1, -7.0)
	cross.material_override = roof
	root.add_child(cross)
	var cross_arm := MeshInstance3D.new()
	cross_arm.name = "CrossHorizontal"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(1.4, 0.32, 0.35)
	cross_arm.mesh = arm_mesh
	cross_arm.position = Vector3(0.0, 9.4, -7.0)
	cross_arm.material_override = roof
	root.add_child(cross_arm)


func _build_mosque_landmark(parent: Node3D, feature: Dictionary, coordinates: Array) -> void:
	if coordinates.size() < 2:
		return
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var root := Node3D.new()
	root.name = "OSMMosque_%s" % str(feature.get("id", "unknown"))
	root.position = Vector3(point.x, _terrain_height(point) + 0.08, point.y)
	root.set_meta("landmark_type", "mosque")
	root.set_meta("osm_feature_id", str(feature.get("id", "")))
	parent.add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.78, 0.72, 0.57)
	stone.roughness = 0.88
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Color(0.12, 0.42, 0.39)
	roof.metallic = 0.18
	var minaret_material := StandardMaterial3D.new()
	minaret_material.albedo_color = Color(0.84, 0.78, 0.63)
	var body := MeshInstance3D.new()
	body.name = "PrayerHall"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(9.0, 4.0, 8.0)
	body.mesh = body_mesh
	body.position.y = 2.0
	body.material_override = stone
	root.add_child(body)
	var dome := MeshInstance3D.new()
	dome.name = "CentralDome"
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 2.5
	dome_mesh.height = 3.2
	dome.mesh = dome_mesh
	dome.position = Vector3(0.0, 5.2, 0.0)
	dome.material_override = roof
	root.add_child(dome)
	for side in [-1.0, 1.0]:
		var minaret := MeshInstance3D.new()
		minaret.name = "Minaret_%s" % str(side)
		var minaret_mesh := CylinderMesh.new()
		minaret_mesh.top_radius = 0.32
		minaret_mesh.bottom_radius = 0.55
		minaret_mesh.height = 10.0
		minaret.mesh = minaret_mesh
		minaret.position = Vector3(side * 6.0, 5.0, -2.5)
		minaret.material_override = minaret_material
		root.add_child(minaret)
		var cap := MeshInstance3D.new()
		cap.name = "MinaretCap_%s" % str(side)
		var cap_mesh := CylinderMesh.new()
		cap_mesh.height = 1.8
		cap_mesh.top_radius = 0.0
		cap_mesh.bottom_radius = 0.65
		cap.mesh = cap_mesh
		cap.position = Vector3(side * 6.0, 10.9, -2.5)
		cap.material_override = roof
		root.add_child(cap)



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
	var kind := str(tags.get("building", "yes")).to_lower()
	if kind in ["house", "detached", "semidetached_house", "bungalow", "terrace", "villa"]:
		return 7.5
	if kind in ["palace", "castle", "manor"]:
		return 18.0
	if kind in ["apartments", "residential", "dormitory"]:
		return 16.0
	if kind in ["commercial", "office", "retail"]:
		return 12.0
	return 6.0


func _building_kind(tags: Dictionary) -> String:
	var kind := str(tags.get("building", "yes")).to_lower()
	if kind in ["house", "detached", "semidetached_house", "bungalow", "terrace"]:
		return "detached_house"
	if kind in ["villa", "residential"] and (str(tags.get("building", "")).to_lower() == "villa" or str(tags.get("residential", "")).to_lower() == "villa"):
		return "villa"
	if kind in ["palace", "castle", "manor"]:
		return "palace"
	if kind in ["apartments", "residential", "dormitory"]:
		return "apartment_block"
	if kind in ["commercial", "office", "retail", "industrial"]:
		return "commercial_building"
	if kind == "mosque" or (str(tags.get("amenity", "")) == "place_of_worship" and str(tags.get("religion", "")).to_lower() == "muslim"):
		return "mosque"
	if kind == "church" or (str(tags.get("amenity", "")) == "place_of_worship" and str(tags.get("religion", "")).to_lower() == "christian"):
		return "church"
	return "general_building"


func _building_material_for(kind: String) -> StandardMaterial3D:
	var material := building_material.duplicate() as StandardMaterial3D
	match kind:
		"detached_house":
			material.albedo_color = Color(0.68, 0.55, 0.40)
		"villa":
			material.albedo_color = Color(0.78, 0.70, 0.55)
		"palace":
			material.albedo_color = Color(0.76, 0.67, 0.48)
		"apartment_block":
			material.albedo_color = Color(0.62, 0.63, 0.60)
		"commercial_building":
			material.albedo_color = Color(0.43, 0.51, 0.56)
		"mosque":
			material.albedo_color = Color(0.72, 0.67, 0.52)
		"church":
			material.albedo_color = Color(0.70, 0.63, 0.52)
	return material


func _commit_surface_tool_if_valid(surface: SurfaceTool) -> ArrayMesh:
	# Inspect the vertex array before creating a mesh. Calling get_surface_count()
	# on an empty SurfaceTool commit can dereference a null renderer mesh in
	# Godot's headless/dummy backend when OSM features contain degenerate lines.
	var arrays: Array = surface.commit_to_arrays()
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return null
	var raw_vertices: Variant = arrays[Mesh.ARRAY_VERTEX]
	if typeof(raw_vertices) != TYPE_PACKED_VECTOR3_ARRAY:
		return null
	var vertices: PackedVector3Array = raw_vertices
	if vertices.size() < 3:
		return null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if not mesh.get_rid().is_valid():
		return null
	return mesh


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
