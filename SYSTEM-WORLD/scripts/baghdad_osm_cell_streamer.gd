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
var road_marking_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D
var streetlight_metal_material: StandardMaterial3D
var streetlight_glow_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var water_material: StandardMaterial3D
var land_material: StandardMaterial3D
var building_material: StandardMaterial3D
var facade_window_material: StandardMaterial3D
var facade_architecture_material: StandardMaterial3D
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

	road_marking_material = StandardMaterial3D.new()
	road_marking_material.albedo_color = Color(0.92, 0.84, 0.58)
	road_marking_material.roughness = 0.86
	road_marking_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	sidewalk_material = StandardMaterial3D.new()
	sidewalk_material.albedo_color = Color(0.48, 0.46, 0.41)
	sidewalk_material.roughness = 0.94
	sidewalk_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	streetlight_metal_material = StandardMaterial3D.new()
	streetlight_metal_material.albedo_color = Color(0.12, 0.15, 0.17)
	streetlight_metal_material.metallic = 0.62
	streetlight_metal_material.roughness = 0.48

	streetlight_glow_material = StandardMaterial3D.new()
	streetlight_glow_material.albedo_color = Color(1.0, 0.78, 0.43)
	streetlight_glow_material.emission_enabled = true
	streetlight_glow_material.emission = Color(1.0, 0.58, 0.22)
	streetlight_glow_material.emission_energy_multiplier = 1.25

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

	facade_architecture_material = StandardMaterial3D.new()
	facade_architecture_material.albedo_color = Color(0.72, 0.77, 0.79)
	facade_architecture_material.roughness = 0.48
	facade_architecture_material.metallic = 0.28
	facade_architecture_material.vertex_color_use_as_albedo = true
	facade_architecture_material.cull_mode = BaseMaterial3D.CULL_DISABLED

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
		var road_tags: Dictionary = feature.get("tags", {})
		road_count += _build_line_feature(cell_root, feature, _road_width(road_tags), _road_surface_material(road_tags), 0.16, "OSMRoad")
	if not overview_mode:
		_flush_road_marking_multimesh(cell_root)
		_flush_sidewalk_multimesh(cell_root)
		_flush_streetlight_multimeshes(cell_root)
	var building_count := 0
	var building_features: Array = layers.get("buildings", [])
	var building_feature_ids: Dictionary = {}
	for feature in building_features:
		var building_key := _osm_feature_key(feature)
		if building_key != "":
			building_feature_ids[building_key] = true
		if overview_mode:
			building_count += _build_building_overview_feature(cell_root, feature)
		else:
			building_count += _build_building_feature(cell_root, feature, road_features)
	if not overview_mode:
		_flush_facade_window_multimesh(cell_root)
		_flush_apartment_balcony_multimeshes(cell_root)
		_flush_facade_architecture_multimesh(cell_root)
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
			# A worship polygon can be present in both OSM layers. The building
			# layer already rendered its exact footprint, so avoid a duplicate.
			var feature_key := _osm_feature_key(feature)
			var amenity_geometry: Dictionary = feature.get("geometry", {})
			var amenity_geometry_type := str(amenity_geometry.get("type", ""))
			if feature_key != "" and building_feature_ids.has(feature_key) and amenity_geometry_type in ["Polygon", "MultiPolygon"]:
				continue
			amenity_count += _build_regional_poi_feature(cell_root, feature)
		else:
			amenity_count += _build_amenity_feature(cell_root, feature)
	var entrance_count := 0
	if not overview_mode:
		for feature in layers.get("entrances", []):
			entrance_count += _build_entrance_feature(cell_root, feature, building_features)
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
	var sensitive_site := _is_sensitive_state_site(tags)
	var kind := "general_building" if sensitive_site else _game_building_kind(tags)
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
		if not sensitive_site:
			instance.set_meta("system_osm_type", str(feature.get("osm_type", "")))
			instance.set_meta("system_worship_geometry_imported", _worship_facility_type(tags) != "")
		instance.set_meta("system_geometry_type", str(geometry.get("type", "")))
		if sensitive_site:
			instance.set_meta("system_sensitive_site_neutralized", true)
		instance.set_meta("baghdad_building_type", kind)
		instance.set_meta("system_architecture_class", kind)
		var amenity_kind := str(tags.get("amenity", "")).to_lower()
		var facility_type := "" if sensitive_site else _game_worship_presentation_type(tags)
		if facility_type == "" and not sensitive_site:
			var healthcare_kind := str(tags.get("healthcare", "")).to_lower()
			var shop_kind := str(tags.get("shop", "")).to_lower()
			var office_kind := str(tags.get("office", "")).to_lower()
			var craft_kind := str(tags.get("craft", "")).to_lower()
			var tourism_kind := str(tags.get("tourism", "")).to_lower()
			var historic_kind := str(tags.get("historic", "")).to_lower()
			var leisure_kind := str(tags.get("leisure", "")).to_lower()
			var aeroway_kind := str(tags.get("aeroway", "")).to_lower()
			var public_transport_kind := str(tags.get("public_transport", "")).to_lower()
			var railway_kind := str(tags.get("railway", "")).to_lower()
			var highway_kind := str(tags.get("highway", "")).to_lower()
			if amenity_kind in ["hospital", "clinic", "doctors", "pharmacy"] or healthcare_kind != "":
				facility_type = "healthcare"
			elif amenity_kind in ["school", "university", "college", "kindergarten"] or str(tags.get("education", "")).to_lower() != "":
				facility_type = "education"
			elif amenity_kind in ["police", "police_station"]:
				facility_type = "police"
			elif amenity_kind in ["fire_station", "post_office", "bank", "townhall", "library"] or office_kind != "" or craft_kind != "":
				facility_type = "civic"
			elif amenity_kind == "marketplace" or shop_kind in ["mall", "department_store"]:
				facility_type = "market"
			elif shop_kind != "":
				facility_type = "shop"
			elif amenity_kind in ["restaurant", "cafe", "fast_food", "food_court"]:
				facility_type = "food"
			elif tourism_kind != "":
				facility_type = "tourism"
			elif historic_kind != "":
				facility_type = "heritage"
			elif leisure_kind != "":
				facility_type = "leisure"
			elif amenity_kind in ["bus_station", "bus_stop", "ferry_terminal", "parking", "taxi"] or public_transport_kind in ["station", "platform", "stop_position"] or railway_kind in ["station", "halt", "tram_stop", "subway_entrance"] or highway_kind in ["bus_stop", "platform"] or aeroway_kind != "":
				facility_type = "transport"
		if facility_type != "" and not sensitive_site:
			instance.set_meta("system_facility_type", facility_type)
		instance.set_meta("system_display_name", "مبنى معماري" if sensitive_site else _game_building_display_name(kind, tags))
		instance.set_meta("system_building_height_m", height)
		instance.set_meta("system_estimated_floors", maxi(1, int(ceil(height / 3.2))))
		instance.set_meta("system_residential_luxury_class", kind in ["villa", "palace"])
		instance.set_meta("system_footprint_geometry", "osm_polygon_extrusion")
		instance.set_meta("system_facade_detail_level", "regional_extrusion_lod")
		instance.set_meta("system_access_state", "regional_exterior_lod_no_collision_or_interior")
		parent.add_child(instance)
		if not sensitive_site and kind in ["mosque", "church"]:
			_add_polygon_worship_detail(parent, ring, height, kind, feature_id, tags)
		built += 1
	return built


func _osm_feature_key(feature: Dictionary) -> String:
	var osm_type := str(feature.get("osm_type", "")).to_lower()
	var feature_id := str(feature.get("id", ""))
	if osm_type == "" or feature_id == "":
		return ""
	return osm_type + "/" + feature_id


func _is_polygon_worship_feature(feature: Dictionary) -> bool:
	var geometry: Dictionary = feature.get("geometry", {})
	var geometry_type := str(geometry.get("type", ""))
	if geometry_type not in ["Polygon", "MultiPolygon"]:
		return false
	var tags: Dictionary = feature.get("tags", {})
	var amenity_kind := str(tags.get("amenity", "")).to_lower()
	var building_kind := str(tags.get("building", "")).to_lower()
	var religion := str(tags.get("religion", "")).to_lower()
	# Keep polygon geometry authoritative. Some mapped worship buildings carry
	# building=public/religious plus religion=* instead of building=mosque/church.
	var explicit_worship := amenity_kind in ["place_of_worship", "monastery"]
	explicit_worship = explicit_worship or building_kind in ["mosque", "church", "chapel", "cathedral", "shrine", "monastery"]
	var religious_building := religion in ["muslim", "islam", "christian", "christianity"] and building_kind in ["public", "religious"]
	return explicit_worship or religious_building


func _build_regional_poi_feature(parent: Node3D, feature: Dictionary) -> int:
	var tags: Dictionary = feature.get("tags", {})
	if _is_sensitive_state_site(tags):
		return 0
	var geometry: Dictionary = feature.get("geometry", {})
	var geometry_type := str(geometry.get("type", ""))
	var aeroway_kind := str(tags.get("aeroway", "")).to_lower()
	if geometry_type in ["LineString", "MultiLineString"] and aeroway_kind in ["runway", "taxiway"]
		var runway_width := 42.0 if aeroway_kind == "runway" else 18.0
		return _build_line_feature(parent, feature, runway_width, bridge_material, 0.12, "OSMCivilAirport_" + aeroway_kind)
	if geometry_type in ["Polygon", "MultiPolygon"] and aeroway_kind == "apron":
		return _build_area_feature(parent, feature, land_material, 0.06, "OSMCivilAirportApron")
	# Never derive a centroid marker from a mapped worship footprint. Build the
	# actual OSM polygon/multipolygon extrusion before any point fallback logic.
	if geometry_type in ["Polygon", "MultiPolygon"] and _is_polygon_worship_feature(feature):
		return _build_building_overview_feature(parent, feature)
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
	var amenity := str(tags.get("amenity", "")).to_lower()
	var shop := str(tags.get("shop", "")).to_lower()
	var tourism := str(tags.get("tourism", "")).to_lower()
	var historic := str(tags.get("historic", "")).to_lower()
	var leisure := str(tags.get("leisure", "")).to_lower()
	var healthcare := str(tags.get("healthcare", "")).to_lower()
	var craft := str(tags.get("craft", "")).to_lower()
	var office := str(tags.get("office", "")).to_lower()
	var aeroway := str(tags.get("aeroway", "")).to_lower()
	var public_transport := str(tags.get("public_transport", "")).to_lower()
	var railway := str(tags.get("railway", "")).to_lower()
	var highway := str(tags.get("highway", "")).to_lower()
	var facility_type := "public_service"
	var display_name := "مرفق خدمي"
	var worship_type := _game_worship_presentation_type(tags)
	if worship_type != "":
		facility_type = worship_type
		match worship_type:
			"mosque":
				display_name = "جامع أو مسجد"
			"church":
				display_name = "كنيسة"
			"shrine":
				display_name = "جامع أو مسجد"
			"monastery":
				display_name = "دير أو مؤسسة رهبانية"
			"religious_tag_conflict":
				display_name = "دار عبادة - تعارض في بيانات OSM"
			"place_of_worship":
				display_name = "دار عبادة - النوع غير محدد"
			_:
				display_name = "مرفق ديني"
	elif amenity in ["hospital", "clinic", "doctors", "pharmacy"] or healthcare != "":
		facility_type = "healthcare"
		display_name = "مرفق صحي"
	elif amenity in ["police", "police_station"]:
		facility_type = "police"
		display_name = "مركز شرطة"
	elif amenity == "marketplace" or shop in ["mall", "department_store"]:
		facility_type = "market"
		display_name = "سوق أو مركز تسوق"
	elif shop != "":
		facility_type = "shop"
		display_name = "محل تجاري"
	elif amenity in ["restaurant", "cafe", "fast_food", "food_court"]:
		facility_type = "food"
		display_name = "مطعم أو مقهى"
	elif amenity in ["school", "university", "college", "kindergarten"]:
		facility_type = "education"
		display_name = "مؤسسة تعليمية"
	elif amenity in ["fire_station", "post_office", "bank", "townhall", "library"] or office != "" or craft != "":
		facility_type = "civic"
		display_name = "مرفق عام"
	elif tourism != "":
		facility_type = "tourism"
		display_name = "مرفق سياحي"
	elif historic != "":
		facility_type = "heritage"
		display_name = "موقع تراثي"
	elif leisure != "":
		facility_type = "leisure"
		display_name = "مرفق ترفيهي أو حديقة"
	elif amenity in ["bus_station", "bus_stop", "ferry_terminal", "parking", "taxi"] or public_transport in ["station", "platform", "stop_position"] or railway in ["station", "halt", "tram_stop", "subway_entrance"] or highway in ["bus_stop", "platform"]:
		facility_type = "transport"
		display_name = "مرفق نقل عام"
	elif aeroway != "":
		facility_type = "transport"
		if aeroway == "aerodrome":
			display_name = "مطار مدني"
		elif aeroway == "terminal":
			display_name = "صالة ركاب جوية"
		elif aeroway == "helipad":
			display_name = "مهبط مدني"
		else:
			display_name = "مرفق طيران مدني"
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
	var kind := _game_building_kind(tags)
	var sensitive_site := _is_sensitive_state_site(tags)
	if sensitive_site:
		kind = "general_building"
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
		building.set_meta("system_display_name", "مبنى معماري" if sensitive_site else _game_building_display_name(kind, tags))
		if not sensitive_site:
			building.set_meta("osm_building_tag", str(tags.get("building", "yes")))
			building.set_meta("system_source_name", str(tags.get("name", "")))
			building.set_meta("system_source_name_ar", str(tags.get("name:ar", "")))
			building.set_meta("system_religion", str(tags.get("religion", "")))
			building.set_meta("system_denomination", str(tags.get("denomination", "")))
			building.set_meta("system_worship_classification", _game_worship_presentation_type(tags))
			building.set_meta("system_source_worship_classification", _worship_facility_type(tags))
		else:
			building.set_meta("system_sensitive_site_neutralized", true)
		building.set_meta("system_geometry_type", str(geometry.get("type", "")))
		var roof_shape := "flat" if sensitive_site else str(tags.get("roof:shape", "flat")).to_lower()
		building.set_meta("system_roof_shape", roof_shape)
		building.set_meta("system_roof_material", str(tags.get("roof:material", "")))
		building.set_meta("system_roof_colour", str(tags.get("roof:colour", "")))
		building.set_meta("system_roof_geometry_state", "source_tagged_pyramidal_mesh" if roof_shape == "pyramidal" else ("source_tagged_flat" if roof_shape == "flat" else "source_tagged_shape_retained_no_mesh"))
		parent.add_child(building)
		if roof_shape == "pyramidal":
			_add_pyramidal_roof(parent, ring, height, feature_id, tags)
		var facade_window_count := 0 if sensitive_site else _add_procedural_facade_windows(parent, ring, height, kind, feature_id)
		var balcony_detail_count := 0 if sensitive_site else _collect_apartment_balconies(parent, ring, height, kind, feature_id)
		var architecture_detail_count := 0 if sensitive_site else _collect_modern_facade_architecture(parent, ring, height, kind, feature_id)
		building.set_meta("system_facade_balcony_count", balcony_detail_count)
		building.set_meta("system_facade_architecture_detail_count", architecture_detail_count)
		building.set_meta("system_facade_detail_level", "modern_facade_multimesh" if architecture_detail_count > 0 else ("core_multimesh_windows" if facade_window_count > 0 else "core_extrusion_only"))
		building.set_meta("system_facade_window_count", facade_window_count)
		building.set_meta("system_facade_window_sampling", "even_distribution_across_facades")
		var body := StaticBody3D.new()
		body.name = "OSMBuildingCollision_%s" % feature_id
		if not sensitive_site:
			body.add_to_group("system_interactable")
			body.set_meta("osm_feature_id", feature_id)
			body.set_meta("baghdad_building_type", kind)
			body.set_meta("osm_building_tag", str(tags.get("building", "yes")))
			body.set_meta("system_source_name", str(tags.get("name", "")))
			body.set_meta("system_source_name_ar", str(tags.get("name:ar", "")))
			body.set_meta("system_religion", str(tags.get("religion", "")))
			body.set_meta("system_denomination", str(tags.get("denomination", "")))
			body.set_meta("system_worship_classification", _game_worship_presentation_type(tags))
			body.set_meta("system_source_worship_classification", _worship_facility_type(tags))
			body.set_meta("system_geometry_type", str(geometry.get("type", "")))
		else:
			body.set_meta("system_sensitive_site_neutralized", true)
		var footprint_center := _polygon_anchor_point(ring)
		var footprint_position := Vector3(
			footprint_center.x,
			_terrain_height(footprint_center),
			footprint_center.y
		)
		var estimated_floors := maxi(1, int(ceil(height / 3.2)))
		body.set_meta("system_location_position", footprint_position)
		body.set_meta("system_access_state", "neutral_exterior_shell" if sensitive_site else "exterior_only")
		if not sensitive_site:
			body.set_meta("system_building_height_m", height)
			body.set_meta("system_estimated_floors", estimated_floors)
			body.set_meta("system_location_id", "baghdad_osm_building_" + feature_id)
			body.set_meta("system_region_id", "region_baghdad")
			body.set_meta("system_location_type", 7)
			body.set_meta("system_fast_travel", false)
			body.set_meta("system_display_name", _game_building_display_name(kind, tags))
			body.set_meta("system_interaction_prompt", "استكشاف معلومات المبنى")
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(mesh.get_faces())
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
		var approach := {} if sensitive_site else _find_building_approach_point(ring, road_features)
		if not approach.is_empty():
			_add_building_approach_marker(parent, approach, feature_id, kind, tags)
			if kind in ["villa", "palace"]:
				_add_luxury_residential_entry_details(parent, ring, height, kind, feature_id, approach)
		built += 1
		if not sensitive_site and kind in ["church", "mosque"]:
			_add_polygon_worship_detail(parent, ring, height, kind, feature_id, tags)
	return built


func _add_pyramidal_roof(parent: Node3D, ring: PackedVector2Array, building_height: float, feature_id: String, tags: Dictionary) -> bool:
	if ring.size() < 3:
		return false
	var anchor := _polygon_anchor_point(ring)
	if not Geometry2D.is_point_in_polygon(anchor, ring):
		return false
	var roof_height := float(tags.get("roof:height", 0.0))
	if roof_height <= 0.0:
		var roof_levels := float(tags.get("roof:levels", 0.0))
		var bounds := _polygon_bounds_size(ring)
		roof_height = roof_levels * 2.5 if roof_levels > 0.0 else clampf(minf(bounds.x, bounds.y) * 0.16, 1.0, 4.5)
	roof_height = clampf(roof_height, 0.6, 12.0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(ring.size()):
		var p0 := ring[index]
		var p1 := ring[(index + 1) % ring.size()]
		var base0 := Vector3(p0.x, _terrain_height(p0) + building_height, p0.y)
		var base1 := Vector3(p1.x, _terrain_height(p1) + building_height, p1.y)
		var peak := Vector3(anchor.x, _terrain_height(anchor) + building_height + roof_height, anchor.y)
		_add_triangle(surface, base0, peak, base1)
	surface.generate_normals()
	var mesh := _commit_surface_tool_if_valid(surface)
	if mesh == null:
		return false
	var material := StandardMaterial3D.new()
	material.roughness = 0.82
	var mapped_colour := str(tags.get("roof:colour", "")).strip_edges()
	if mapped_colour != "":
		material.albedo_color = Color.from_string(mapped_colour, Color(0.55, 0.31, 0.20))
	else:
		var mapped_material := str(tags.get("roof:material", "")).to_lower()
		match mapped_material:
			"metal", "zinc", "copper":
				material.albedo_color = Color(0.34, 0.39, 0.42)
				material.metallic = 0.55
			"thatch", "wood":
				material.albedo_color = Color(0.43, 0.31, 0.19)
			"tiles", "terracotta":
				material.albedo_color = Color(0.55, 0.29, 0.20)
			_:
				material.albedo_color = Color(0.57, 0.53, 0.46)
	var roof := MeshInstance3D.new()
	roof.name = "OSMPyramidalRoof_%s" % feature_id
	roof.mesh = mesh
	roof.material_override = material
	roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	roof.set_meta("system_roof_shape", "pyramidal")
	roof.set_meta("system_roof_height_m", roof_height)
	roof.set_meta("system_roof_material", str(tags.get("roof:material", "")))
	roof.set_meta("system_roof_colour", mapped_colour)
	parent.add_child(roof)
	return true


func _polygon_bounds_size(ring: PackedVector2Array) -> Vector2:
	if ring.is_empty():
		return Vector2.ZERO
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for point in ring:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return Vector2(max_x - min_x, max_y - min_y)


func _add_luxury_residential_entry_details(
	parent: Node3D,
	ring: PackedVector2Array,
	height: float,
	kind: String,
	feature_id: String,
	approach: Dictionary
) -> void:
	# Close-range 200 m cells receive a restrained architectural entrance;
	# the 1 km overview remains a lightweight footprint extrusion.
	if ring.size() < 3:
		return
	var approach_position: Vector2 = approach.get("position", Vector2.ZERO)
	var best_edge_index := 0
	var best_distance := INF
	for edge_index in range(ring.size()):
		var edge_start := ring[edge_index]
		var edge_finish := ring[(edge_index + 1) % ring.size()]
		var nearest := _closest_point_on_segment(approach_position, edge_start, edge_finish)
		var distance := nearest.distance_to(approach_position)
		if distance < best_distance:
			best_distance = distance
			best_edge_index = edge_index
	var edge_start := ring[best_edge_index]
	var edge_finish := ring[(best_edge_index + 1) % ring.size()]
	var edge := edge_finish - edge_start
	var edge_length := edge.length()
	if edge_length < 5.0:
		return
	var tangent := edge.normalized()
	var outward := approach_position - _closest_point_on_segment(approach_position, edge_start, edge_finish)
	if outward.length_squared() < 0.0001:
		outward = Vector2(tangent.y, -tangent.x)
	else:
		outward = outward.normalized()
	var entry_center := (edge_start + edge_finish) * 0.5
	var entry_width := clampf(edge_length * 0.42, 3.2, 6.0)
	var half_width := entry_width * 0.5
	var portal_height := clampf(height * 0.30, 2.8, 4.2)
	var base_height := _terrain_height(entry_center) + 0.08
	var inward_offset := -outward * 0.42
	var trim_material := _building_material_for(kind)
	trim_material.metallic = 0.18 if kind == "villa" else 0.32
	trim_material.roughness = 0.62
	var column_mesh := CylinderMesh.new()
	column_mesh.top_radius = 0.22 if kind == "villa" else 0.28
	column_mesh.bottom_radius = column_mesh.top_radius * 1.18
	column_mesh.height = portal_height
	column_mesh.radial_segments = 12
	for side_sign in [-1.0, 1.0]:
		var column_position_2d := entry_center + tangent * half_width * float(side_sign) + inward_offset
		var column := MeshInstance3D.new()
		column.name = "LuxuryEntryColumn_%s_%s" % [feature_id, "L" if side_sign < 0.0 else "R"]
		column.mesh = column_mesh
		column.position = Vector3(column_position_2d.x, base_height + portal_height * 0.5, column_position_2d.y)
		column.material_override = trim_material
		column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(column)
	var lintel := MeshInstance3D.new()
	lintel.name = "LuxuryEntryLintel_%s" % feature_id
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(entry_width + 0.65, 0.34, 0.48)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(entry_center.x, base_height + portal_height, entry_center.y) + Vector3(inward_offset.x, 0.0, inward_offset.y)
	lintel.rotation.y = atan2(-tangent.y, tangent.x)
	lintel.material_override = trim_material
	lintel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(lintel)
	var canopy := MeshInstance3D.new()
	canopy.name = "LuxuryEntryCanopy_%s" % feature_id
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(entry_width + 1.0, 0.22, 1.65)
	canopy.mesh = canopy_mesh
	canopy.position = Vector3(entry_center.x, base_height + portal_height - 0.12, entry_center.y) + Vector3(inward_offset.x, 0.0, inward_offset.y) - Vector3(outward.x, 0.0, outward.y) * 0.72
	canopy.rotation.y = atan2(-tangent.y, tangent.x)
	canopy.material_override = trim_material
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(canopy)
	var detail_root := Node3D.new()
	detail_root.name = "LuxuryResidentialEntrance_%s" % feature_id
	detail_root.set_meta("system_luxury_building_kind", kind)
	detail_root.set_meta("system_architectural_detail", "road_facing_entry_portico")
	detail_root.set_meta("system_entry_width_m", entry_width)
	detail_root.set_meta("system_entry_height_m", portal_height)
	parent.add_child(detail_root)


func _add_procedural_facade_windows(
	parent: Node3D,
	ring: PackedVector2Array,
	height: float,
	kind: String,
	feature_id: String
) -> int:
	# The 1 km regional overview stays as a cheap extrusion LOD. Only the
	# 200 m playable cells collect close-range facade windows.
	if overview_mode or height < 5.0 or ring.size() < 3 or kind in ["mosque", "church", "shrine", "monastery"]:
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


func _collect_apartment_balconies(
	parent: Node3D,
	ring: PackedVector2Array,
	height: float,
	kind: String,
	feature_id: String
) -> int:
	# Close-range apartment blocks get shallow balconies on selected floors.
	# Both slabs and rails are instanced once per cell to keep mobile draw calls low.
	if overview_mode or kind != "apartment_block" or ring.size() < 3 or height < 9.0:
		return 0
	var slabs: Array = parent.get_meta("system_balcony_slab_transforms", [])
	var rails: Array = parent.get_meta("system_balcony_rail_transforms", [])
	var remaining_budget := maxi(0, 240 - slabs.size())
	if remaining_budget <= 0:
		return 0
	var floor_count := clampi(int(floor(height / 3.2)), 2, 10)
	var added := 0
	for edge_index in range(ring.size()):
		if added >= mini(16, remaining_budget):
			break
		var start := ring[edge_index]
		var finish := ring[(edge_index + 1) % ring.size()]
		var edge := finish - start
		var edge_length := edge.length()
		if edge_length < 8.0:
			continue
		var tangent := edge / edge_length
		var outward_2d := Vector2(tangent.y, -tangent.x)
		var outward := Vector3(outward_2d.x, 0.0, outward_2d.y)
		var facade_right := Vector3.UP.cross(outward).normalized()
		var balcony_width := minf(edge_length * 0.30, 2.4)
		var slab_basis := Basis(facade_right, Vector3.UP, outward).scaled(Vector3(balcony_width, 0.16, 0.85))
		var rail_basis := Basis(facade_right, Vector3.UP, outward).scaled(Vector3(balcony_width, 0.10, 0.10))
		for floor_index in range(1, floor_count):
			if added >= mini(16, remaining_budget):
				break
			# Alternate floors and sides to avoid a repetitive full-grid facade.
			if (floor_index + edge_index) % 2 != 0:
				continue
			var center := (start + finish) * 0.5
			var y := _terrain_height(center) + 2.05 + float(floor_index) * 3.15
			var position := Vector3(center.x, y, center.y) + outward * 0.42
			slabs.append(Transform3D(slab_basis, position))
			var rail_position := position + outward * 0.43 + Vector3.UP * 0.48
			rails.append(Transform3D(rail_basis, rail_position))
			added += 1
	parent.set_meta("system_balcony_slab_transforms", slabs)
	parent.set_meta("system_balcony_rail_transforms", rails)
	return added


func _flush_apartment_balcony_multimeshes(parent: Node3D) -> void:
	var slabs: Array = parent.get_meta("system_balcony_slab_transforms", [])
	var rails: Array = parent.get_meta("system_balcony_rail_transforms", [])
	if slabs.is_empty() or slabs.size() != rails.size():
		return
	for detail_data in [
		{"name": "BaghdadCellApartmentBalconySlabs", "transforms": slabs, "type": "apartment_balcony_slabs"},
		{"name": "BaghdadCellApartmentBalconyRails", "transforms": rails, "type": "apartment_balcony_rails"}
	]:
		var transforms: Array = detail_data["transforms"]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = BoxMesh.new()
		multimesh.instance_count = transforms.size()
		for index in range(transforms.size()):
			multimesh.set_instance_transform(index, transforms[index])
		var detail := MultiMeshInstance3D.new()
		detail.name = str(detail_data["name"])
		detail.multimesh = multimesh
		detail.material_override = facade_architecture_material
		detail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		detail.set_meta("system_facade_detail_type", str(detail_data["type"]))
		detail.set_meta("system_facade_balcony_count", transforms.size())
		detail.set_meta("system_facade_balcony_draw_calls_per_cell", 1)
		parent.add_child(detail)
	parent.set_meta("system_facade_balcony_instance_count", slabs.size())
	parent.set_meta("system_balcony_slab_transforms", [])
	parent.set_meta("system_balcony_rail_transforms", [])


func _collect_modern_facade_architecture(
	parent: Node3D,
	ring: PackedVector2Array,
	height: float,
	kind: String,
	feature_id: String
) -> int:
	# Lightweight modern architectural rhythm for close-range 200 m cells:
	# vertical corner fins and a continuous roofline cornice. All instances
	# are packed into one cell-level MultiMesh to keep Android draw calls low.
	if overview_mode or ring.size() < 3 or height < 5.0 or kind in ["mosque", "church", "shrine", "monastery"]:
		return 0
	var transforms: Array = parent.get_meta("system_facade_architecture_transforms", [])
	var colors: Array = parent.get_meta("system_facade_architecture_colors", [])
	var remaining_cell_budget := maxi(0, 600 - transforms.size())
	var building_budget := mini(12, remaining_cell_budget)
	if building_budget <= 0:
		return 0
	var color := Color(0.66, 0.73, 0.76)
	match kind:
		"villa":
			color = Color(0.82, 0.76, 0.64)
		"palace":
			color = Color(0.86, 0.78, 0.59)
		"detached_house":
			color = Color(0.72, 0.65, 0.54)
		"commercial_building":
			color = Color(0.48, 0.64, 0.72)
	var added := 0
	for edge_index in range(ring.size()):
		if added >= building_budget:
			break
		var start := ring[edge_index]
		var finish := ring[(edge_index + 1) % ring.size()]
		var edge := finish - start
		var edge_length := edge.length()
		if edge_length < 5.0:
			continue
		var tangent := edge / edge_length
		var midpoint := (start + finish) * 0.5
		var outward_2d := Vector2(tangent.y, -tangent.x)
		var outward := Vector3(outward_2d.x, 0.0, outward_2d.y)
		var facade_right := Vector3.UP.cross(outward).normalized()
		var base_y := _terrain_height(midpoint)
		var pilaster_basis := Basis(facade_right, Vector3.UP, outward).scaled(Vector3(0.14, height, 0.20))
		for side_sign in [-1.0, 1.0]:
			if added >= building_budget:
				break
			var along := clampf(0.75 / edge_length, 0.08, 0.22)
			var point := start.lerp(finish, along if side_sign < 0.0 else 1.0 - along)
			var position := Vector3(point.x, _terrain_height(point) + height * 0.5, point.y) + outward * 0.10
			transforms.append(Transform3D(pilaster_basis, position))
			colors.append(color)
			added += 1
		if added < building_budget:
			var cornice_basis := Basis(facade_right, Vector3.UP, outward).scaled(Vector3(edge_length, 0.10, 0.22))
			var cornice_position := Vector3(midpoint.x, base_y + height - 0.12, midpoint.y) + outward * 0.10
			transforms.append(Transform3D(cornice_basis, cornice_position))
			colors.append(color.lightened(0.08))
			added += 1
	parent.set_meta("system_facade_architecture_transforms", transforms)
	parent.set_meta("system_facade_architecture_colors", colors)
	return added


func _flush_facade_architecture_multimesh(parent: Node3D) -> void:
	var transforms: Array = parent.get_meta("system_facade_architecture_transforms", [])
	var colors: Array = parent.get_meta("system_facade_architecture_colors", [])
	if transforms.is_empty() or transforms.size() != colors.size():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = BoxMesh.new()
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_color(index, colors[index])
	var detail := MultiMeshInstance3D.new()
	detail.name = "BaghdadCellModernFacadeArchitecture"
	detail.multimesh = multimesh
	detail.material_override = facade_architecture_material
	detail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	detail.set_meta("system_facade_detail_type", "modern_architectural_fins_and_cornices")
	detail.set_meta("system_facade_architecture_count", transforms.size())
	detail.set_meta("system_facade_architecture_draw_calls_per_cell", 1)
	parent.add_child(detail)
	parent.set_meta("system_facade_architecture_instance_count", transforms.size())
	parent.set_meta("system_facade_architecture_transforms", [])
	parent.set_meta("system_facade_architecture_colors", [])


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
	# Release temporary arrays after copying transforms/colors into the MultiMesh.
	parent.set_meta("system_facade_window_transforms", [])
	parent.set_meta("system_facade_window_colors", [])


func _polygon_anchor_point(ring: PackedVector2Array) -> Vector2:
	# The arithmetic mean of vertices can fall outside concave Baghdad footprints.
	# Use the centroid of the largest valid triangulated face as an interior anchor.
	if ring.size() < 3:
		return ring[0] if not ring.is_empty() else Vector2.ZERO
	var triangles := Geometry2D.triangulate_polygon(ring)
	var best_area := -1.0
	var best_anchor := ring[0]
	for index in range(0, triangles.size(), 3):
		if index + 2 >= triangles.size():
			break
		var a := ring[triangles[index]]
		var b := ring[triangles[index + 1]]
		var c := ring[triangles[index + 2]]
		var area := absf((b - a).cross(c - a)) * 0.5
		if area > best_area:
			best_area = area
			best_anchor = (a + b + c) / 3.0
	return best_anchor


func _find_building_approach_point(ring: PackedVector2Array, road_features: Array) -> Dictionary:
	var center := _polygon_anchor_point(ring)
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
		"shrine":
			return "مزار"
		"monastery":
			return "دير"
		"education_building":
			return "مبنى تعليمي"
		"healthcare_building":
			return "مرفق صحي"
		"civic_building":
			return "مرفق خدمي حكومي"
		"hospitality_building":
			return "فندق أو دار ضيافة"
		_:
			return "مبنى في بغداد"


func _add_polygon_worship_detail(parent: Node3D, ring: PackedVector2Array, height: float, kind: String, feature_id: String, tags: Dictionary) -> void:
	# Use the real footprint bounds to scale roof landmarks; never place a
	# fixed-size landmark that overwhelms a small mapped building.
	var center := _polygon_anchor_point(ring)
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for point in ring:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	var footprint_width := maxf(1.0, max_x - min_x)
	var footprint_depth := maxf(1.0, max_y - min_y)
	var footprint_scale := minf(footprint_width, footprint_depth)
	var landmark_name := _building_display_name(kind, tags)
	var detail_root := Node3D.new()
	detail_root.name = "OSMWorshipDetail_%s_%s" % [kind, feature_id]
	detail_root.position = Vector3(center.x, _terrain_height(center) + height, center.y)
	detail_root.set_meta("landmark_type", kind)
	detail_root.set_meta("osm_feature_id", feature_id)
	detail_root.set_meta("system_display_name", landmark_name)
	detail_root.set_meta("system_source_name", str(tags.get("name", "")))
	detail_root.set_meta("system_source_name_ar", str(tags.get("name:ar", "")))
	detail_root.set_meta("system_religion", str(tags.get("religion", "")))
	detail_root.set_meta("system_denomination", str(tags.get("denomination", "")))
	detail_root.set_meta("system_footprint_width_m", footprint_width)
	detail_root.set_meta("system_footprint_depth_m", footprint_depth)
	parent.add_child(detail_root)
	if kind == "mosque":
		var dome_radius := clampf(footprint_scale * 0.16, 0.85, 3.2)
		var dome_height := dome_radius * 1.28
		var dome := MeshInstance3D.new()
		dome.name = "RoofDome"
		var dome_mesh := SphereMesh.new()
		dome_mesh.radius = dome_radius
		dome_mesh.height = dome_height
		dome.mesh = dome_mesh
		dome.position.y = dome_height * 0.38
		dome.material_override = _building_material_for("mosque")
		detail_root.add_child(dome)
		var minaret_count := 2 if footprint_scale >= 16.0 else 1
		for index in range(minaret_count):
			var minaret := MeshInstance3D.new()
			minaret.name = "Minaret_%02d" % index
			var minaret_mesh := CylinderMesh.new()
			var minaret_height := clampf(height * 0.72, 4.0, 15.0)
			minaret_mesh.top_radius = 0.16
			minaret_mesh.bottom_radius = 0.30
			minaret_mesh.height = minaret_height
			minaret.mesh = minaret_mesh
			var side := -1.0 if index == 0 else 1.0
			minaret.position = Vector3(side * minf(footprint_width * 0.28, 5.0), minaret_height * 0.5, 0.0)
			minaret.material_override = _building_material_for("mosque")
			detail_root.add_child(minaret)
		if footprint_scale >= 22.0:
			for index in range(4):
				var angle := TAU * float(index) / 4.0
				var small_dome := MeshInstance3D.new()
				small_dome.name = "SecondaryDome_%02d" % index
				var small_mesh := SphereMesh.new()
				small_mesh.radius = dome_radius * 0.48
				small_mesh.height = dome_height * 0.48
				small_dome.mesh = small_mesh
				small_dome.position = Vector3(cos(angle) * footprint_width * 0.22, dome_height * 0.20, sin(angle) * footprint_depth * 0.22)
				small_dome.material_override = _building_material_for("mosque")
				detail_root.add_child(small_dome)
	elif kind == "church":
		var tower := MeshInstance3D.new()
		tower.name = "ChurchBellTower"
		var tower_mesh := BoxMesh.new()
		var tower_height := clampf(height * 0.70, 5.0, 18.0)
		tower_mesh.size = Vector3(clampf(footprint_scale * 0.12, 1.2, 3.0), tower_height, clampf(footprint_scale * 0.12, 1.2, 3.0))
		tower.mesh = tower_mesh
		tower.position = Vector3(footprint_width * 0.28, tower_height * 0.5, -footprint_depth * 0.28)
		tower.material_override = _building_material_for("church")
		detail_root.add_child(tower)
		var cross := MeshInstance3D.new()
		cross.name = "ChurchCross"
		var cross_mesh := BoxMesh.new()
		cross_mesh.size = Vector3(0.35, 2.0, 0.35)
		cross.mesh = cross_mesh
		cross.position = tower.position + Vector3(0.0, tower_height * 0.5 + 1.0, 0.0)
		cross.material_override = _building_material_for("church")
		detail_root.add_child(cross)
		var cross_arm := MeshInstance3D.new()
		cross_arm.name = "ChurchCrossArm"
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(1.2, 0.3, 0.35)
		cross_arm.mesh = arm_mesh
		cross_arm.position = cross.position + Vector3(0.0, 0.3, 0.0)
		cross_arm.material_override = _building_material_for("church")
		detail_root.add_child(cross_arm)
	elif kind == "shrine":
		var shrine_dome := MeshInstance3D.new()
		shrine_dome.name = "ShrineDome"
		var shrine_dome_mesh := SphereMesh.new()
		shrine_dome_mesh.radius = clampf(footprint_scale * 0.13, 1.0, 3.0)
		shrine_dome_mesh.height = shrine_dome_mesh.radius * 1.35
		shrine_dome.mesh = shrine_dome_mesh
		shrine_dome.position.y = shrine_dome_mesh.height * 0.42
		shrine_dome.material_override = _building_material_for("shrine")
		detail_root.add_child(shrine_dome)
		for index in range(4):
			var finial := MeshInstance3D.new()
			finial.name = "ShrineCornerFinial_%02d" % index
			var finial_mesh := CylinderMesh.new()
			finial_mesh.top_radius = 0.08
			finial_mesh.bottom_radius = 0.22
			finial_mesh.height = clampf(height * 0.45, 2.0, 6.0)
			finial.mesh = finial_mesh
			var side_x := -1.0 if index % 2 == 0 else 1.0
			var side_z := -1.0 if index < 2 else 1.0
			finial.position = Vector3(side_x * footprint_width * 0.34, finial_mesh.height * 0.5, side_z * footprint_depth * 0.34)
			finial.material_override = _building_material_for("shrine")
			detail_root.add_child(finial)
	else:
		# A neutral cloister roofline for monastery footprints; no denomination-
		# specific symbols are inferred from the generic OSM monastery tag.
		var cloister_material := _building_material_for("monastery")
		var beam_height := clampf(footprint_scale * 0.055, 0.8, 2.0)
		var beam_width := maxf(2.0, footprint_width * 0.62)
		var beam_depth := maxf(2.0, footprint_depth * 0.62)
		for side in range(4):
			var arcade := MeshInstance3D.new()
			arcade.name = "MonasteryCloister_%d" % side
			var arcade_mesh := BoxMesh.new()
			arcade_mesh.size = Vector3(beam_width, beam_height, 0.65) if side < 2 else Vector3(0.65, beam_height, beam_depth)
			arcade.mesh = arcade_mesh
			var offset_x := 0.0 if side < 2 else (-beam_width * 0.5 if side == 2 else beam_width * 0.5)
			var offset_z := (-beam_depth * 0.5 if side == 0 else beam_depth * 0.5) if side < 2 else 0.0
			arcade.position = Vector3(offset_x, beam_height * 0.5, offset_z)
			arcade.material_override = cloister_material
			detail_root.add_child(arcade)


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
		if not overview_mode and prefix == "OSMRoad" and not is_bridge:
			_collect_road_center_markings(parent, line, width, feature_tags)
			_collect_sidewalk_transforms(parent, line, width, feature_tags, lift)
			_collect_streetlight_transforms(parent, line, width, feature_tags, is_bridge)
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


func _build_entrance_feature(parent: Node3D, feature: Dictionary, building_features: Array = []) -> int:
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
	var association := _find_entrance_building_association(point, building_features, tags)
	root.set_meta("system_associated_building_id", str(association.get("building_id", "")))
	root.set_meta("system_building_association_status", str(association.get("status", "unmatched")))
	root.set_meta("system_building_association_distance_m", float(association.get("distance_m", -1.0)))
	root.set_meta("system_access_state", "mapped_entrance_point_no_interior_scene")
	root.set_meta("system_entrance_type", entrance_kind if entrance_kind != "" else door_kind)
	root.set_meta("system_door_type", door_kind)
	root.set_meta("system_access_tag", str(tags.get("access", "unknown")))
	root.set_meta("system_wheelchair_tag", str(tags.get("wheelchair", "unknown")))
	root.set_meta("system_foot_access_tag", str(tags.get("foot", "unknown")))
	root.set_meta("system_level_tag", str(tags.get("level", "unknown")))
	root.set_meta("system_indoor_tag", str(tags.get("indoor", "unknown")))
	root.set_meta("system_service_tag", str(tags.get("service", "unknown")))
	root.set_meta("system_emergency_tag", str(tags.get("emergency", "unknown")))
	root.set_meta("system_can_enter", false)
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
	body.set_meta("system_associated_building_id", str(association.get("building_id", "")))
	body.set_meta("system_building_association_status", str(association.get("status", "unmatched")))
	body.set_meta("system_building_association_distance_m", float(association.get("distance_m", -1.0)))
	body.set_meta("system_access_tag", str(tags.get("access", "unknown")))
	body.set_meta("system_wheelchair_tag", str(tags.get("wheelchair", "unknown")))
	body.set_meta("system_access_state", "mapped_entrance_point_no_interior_scene")
	body.set_meta("system_door_type", door_kind)
	body.set_meta("system_foot_access_tag", str(tags.get("foot", "unknown")))
	body.set_meta("system_level_tag", str(tags.get("level", "unknown")))
	body.set_meta("system_indoor_tag", str(tags.get("indoor", "unknown")))
	body.set_meta("system_service_tag", str(tags.get("service", "unknown")))
	body.set_meta("system_emergency_tag", str(tags.get("emergency", "unknown")))
	body.set_meta("system_can_enter", false)
	root.add_child(body)
	return 1


func _find_entrance_building_association(point: Vector2, building_features: Array, entrance_tags: Dictionary = {}) -> Dictionary:
	# Associate only against actual OSM building footprints in this metric cell.
	# Ambiguous or distant matches remain review-only; no entrance is invented.
	var best_id := ""
	var best_tags: Dictionary = {}
	var best_distance := INF
	var second_distance := INF
	for feature in building_features:
		if not feature is Dictionary:
			continue
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
			var distance := 0.0 if Geometry2D.is_point_in_polygon(point, ring) else INF
			if distance > 0.0:
				for edge_index in range(ring.size()):
					var closest := _closest_point_on_segment(point, ring[edge_index], ring[(edge_index + 1) % ring.size()])
					distance = minf(distance, point.distance_to(closest))
			if distance < best_distance:
				second_distance = best_distance
				best_distance = distance
				best_id = str(feature.get("id", ""))
				best_tags = feature.get("tags", {})
			elif distance < second_distance:
				second_distance = distance
	if best_id == "" or best_distance > 10.0:
		return {"status": "unmatched", "building_id": "", "distance_m": best_distance if best_distance < INF else -1.0}
	if second_distance < INF and second_distance - best_distance < 0.75:
		return {"status": "review_ambiguous", "building_id": best_id, "distance_m": best_distance}
	var access := str(best_tags.get("access", "")).to_lower()
	var entrance_access := str(entrance_tags.get("access", "")).to_lower()
	if entrance_access in ["no", "private"] or access in ["no", "private"]:
		return {"status": "restricted", "building_id": best_id, "distance_m": best_distance}
	if best_distance <= 2.0:
		return {"status": "associated", "building_id": best_id, "distance_m": best_distance}
	if best_distance <= 5.0:
		return {"status": "review_distance", "building_id": best_id, "distance_m": best_distance}
	return {"status": "unmatched", "building_id": best_id, "distance_m": best_distance}


func _build_amenity_feature(parent: Node3D, feature: Dictionary) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	var tags: Dictionary = feature.get("tags", {})
	if _is_sensitive_state_site(tags):
		return 0
	if str(geometry.get("type", "")) != "Point":
		if str(tags.get("aeroway", "")).to_lower() != "":
			return _build_regional_poi_feature(parent, feature)
		return 0
	var coordinates: Array = geometry.get("coordinates", [])
	var worship_type := _game_worship_presentation_type(tags)
	if worship_type == "mosque":
		_build_mosque_landmark(parent, feature, coordinates)
	elif worship_type == "church":
		_build_church_landmark(parent, feature, coordinates)
	elif worship_type in ["shrine", "monastery"]:
		_build_neutral_worship_landmark(parent, feature, coordinates, worship_type)
	else:
		# Unknown and contradictory tags stay neutral; never assign a false
		# religious silhouette to an unresolved OSM point.
		_build_mapped_amenity_marker(parent, feature, coordinates)
	return 1


func _build_mapped_amenity_marker(parent: Node3D, feature: Dictionary, coordinates: Array) -> void:
	if coordinates.size() < 2:
		return
	var tags: Dictionary = feature.get("tags", {})
	var feature_id := str(feature.get("id", "unknown"))
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var position := Vector3(point.x, _terrain_height(point), point.y)
	var amenity_type := str(tags.get("amenity", tags.get("shop", tags.get("tourism", tags.get("leisure", tags.get("office", "place"))))))
	var display_name := str(tags.get("name:ar", tags.get("name", "")))
	if display_name == "":
		display_name = "موقع بغداد: " + amenity_type
	var mapped_root := Node3D.new()
	mapped_root.name = "OSMAmenity_%s" % feature_id
	mapped_root.position = position
	mapped_root.set_meta("osm_feature_id", feature_id)
	mapped_root.set_meta("system_amenity_type", amenity_type)
	mapped_root.set_meta("system_display_name", display_name)
	mapped_root.set_meta("system_source_name", str(tags.get("name", "")))
	mapped_root.set_meta("system_source_name_ar", str(tags.get("name:ar", "")))
	mapped_root.set_meta("system_operator", str(tags.get("operator", "")))
	mapped_root.set_meta("system_opening_hours", str(tags.get("opening_hours", "")))
	mapped_root.set_meta("system_access_tag", str(tags.get("access", "unknown")))
	mapped_root.set_meta("system_wheelchair_tag", str(tags.get("wheelchair", "unknown")))
	mapped_root.set_meta("system_cuisine", str(tags.get("cuisine", "")))
	mapped_root.set_meta("system_access_state", "mapped_amenity_point_no_interior_scene")
	parent.add_child(mapped_root)
	var marker := MeshInstance3D.new()
	marker.name = "OSMAmenity_%s" % feature_id
	var mesh := SphereMesh.new()
	mesh.radius = 0.48
	mesh.height = 0.96
	marker.mesh = mesh
	marker.position.y = 0.48
	marker.material_override = amenity_material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mapped_root.add_child(marker)
	var body := StaticBody3D.new()
	body.name = "MappedAmenityInteraction"
	body.add_to_group("system_interactable")
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	collision.shape = shape
	body.add_child(collision)
	body.set_meta("osm_feature_id", feature_id)
	body.set_meta("system_location_id", "baghdad_osm_amenity_" + feature_id)
	body.set_meta("system_region_id", "region_baghdad")
	body.set_meta("system_location_type", 7)
	body.set_meta("system_fast_travel", false)
	body.set_meta("system_location_position", position)
	body.set_meta("system_display_name", display_name)
	body.set_meta("system_interaction_prompt", "تفاصيل موقع خدمة محدد في بيانات الخريطة")
	body.set_meta("system_amenity_type", amenity_type)
	body.set_meta("system_access_tag", str(tags.get("access", "unknown")))
	body.set_meta("system_wheelchair_tag", str(tags.get("wheelchair", "unknown")))
	body.set_meta("system_opening_hours", str(tags.get("opening_hours", "")))
	body.set_meta("system_access_state", "mapped_amenity_point_no_interior_scene")
	body.set_meta("system_can_enter", false)
	mapped_root.add_child(body)


func _build_neutral_worship_landmark(parent: Node3D, feature: Dictionary, coordinates: Array, worship_type: String) -> void:
	if coordinates.size() < 2:
		return
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var root := Node3D.new()
	root.name = "OSM%s_%s" % ["Shrine" if worship_type == "shrine" else "Monastery", str(feature.get("id", "unknown"))]
	root.position = Vector3(point.x, _terrain_height(point) + 0.08, point.y)
	root.set_meta("landmark_type", worship_type)
	root.set_meta("osm_feature_id", str(feature.get("id", "")))
	root.set_meta("system_display_name", _game_building_display_name(worship_type, feature.get("tags", {})))
	root.set_meta("system_source_worship_classification", _worship_facility_type(feature.get("tags", {})))
	root.set_meta("system_source_name", str(feature.get("tags", {}).get("name", "")))
	root.set_meta("system_source_name_ar", str(feature.get("tags", {}).get("name:ar", "")))
	root.set_meta("system_religion", str(feature.get("tags", {}).get("religion", "")))
	parent.add_child(root)
	var body := MeshInstance3D.new()
	body.name = "WorshipBuildingBody"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(5.0, 3.0, 5.0) if worship_type == "shrine" else Vector3(6.0, 3.2, 8.0)
	body.mesh = body_mesh
	body.position.y = body_mesh.size.y * 0.5
	body.material_override = _building_material_for(worship_type)
	root.add_child(body)
	if worship_type == "shrine":
		var dome := MeshInstance3D.new()
		dome.name = "ShrineDome"
		var dome_mesh := SphereMesh.new()
		dome_mesh.radius = 1.65
		dome_mesh.height = 2.2
		dome.mesh = dome_mesh
		dome.position.y = 3.7
		dome.material_override = _building_material_for("shrine")
		root.add_child(dome)
	else:
		for index in range(4):
			var pillar := MeshInstance3D.new()
			pillar.name = "MonasteryCloisterPillar_%02d" % index
			var pillar_mesh := CylinderMesh.new()
			pillar_mesh.top_radius = 0.18
			pillar_mesh.bottom_radius = 0.22
			pillar_mesh.height = 2.8
			pillar.mesh = pillar_mesh
			pillar.position = Vector3(-2.1 if index % 2 == 0 else 2.1, 1.4, -2.8 if index < 2 else 2.8)
			pillar.material_override = _building_material_for("monastery")
			root.add_child(pillar)


func _build_church_landmark(parent: Node3D, feature: Dictionary, coordinates: Array) -> void:
	if coordinates.size() < 2:
		return
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var root := Node3D.new()
	root.name = "OSMChurch_%s" % str(feature.get("id", "unknown"))
	root.position = Vector3(point.x, _terrain_height(point) + 0.08, point.y)
	root.set_meta("landmark_type", "church")
	root.set_meta("osm_feature_id", str(feature.get("id", "")))
	root.set_meta("system_display_name", _building_display_name("church", feature.get("tags", {})))
	root.set_meta("system_source_name", str(feature.get("tags", {}).get("name", "")))
	root.set_meta("system_source_name_ar", str(feature.get("tags", {}).get("name:ar", "")))
	root.set_meta("system_religion", str(feature.get("tags", {}).get("religion", "")))
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
	root.set_meta("system_display_name", _game_building_display_name("mosque", feature.get("tags", {})))
	root.set_meta("system_game_worship_classification", "mosque")
	root.set_meta("system_source_worship_classification", _worship_facility_type(feature.get("tags", {})))
	root.set_meta("system_source_name", str(feature.get("tags", {}).get("name", "")))
	root.set_meta("system_source_name_ar", str(feature.get("tags", {}).get("name:ar", "")))
	root.set_meta("system_religion", str(feature.get("tags", {}).get("religion", "")))
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


func _collect_road_center_markings(parent: Node3D, line: PackedVector2Array, road_width: float, tags: Dictionary) -> void:
	# Dashed center guidance is generated only for close-range, two-way urban
	# roads. Residential lanes and the 1 km overview remain uncluttered.
	var highway := str(tags.get("highway", ""))
	if road_width < 5.8 or highway in ["service", "residential", "living_street", "footway", "path", "cycleway", "pedestrian"]:
		return
	var transforms: Array = parent.get_meta("system_road_marking_transforms", [])
	var remaining := maxi(0, 800 - transforms.size())
	if remaining <= 0:
		return
	for segment_index in range(line.size() - 1):
		if transforms.size() >= 800:
			break
		var start: Vector2 = line[segment_index]
		var finish: Vector2 = line[segment_index + 1]
		var segment := finish - start
		var length := segment.length()
		if length < 5.0:
			continue
		var direction := segment / length
		var dash_length := 2.8
		var dash_gap := 5.2
		var cursor := 1.0
		while cursor + dash_length < length - 0.5 and transforms.size() < 800:
			var midpoint := start + direction * (cursor + dash_length * 0.5)
			var basis := Basis(
				Vector3(direction.x, 0.0, direction.y),
				Vector3.UP,
				Vector3(-direction.y, 0.0, direction.x)
			).scaled(Vector3(dash_length, 0.025, 0.12))
			var position := Vector3(midpoint.x, _terrain_height(midpoint) + 0.205, midpoint.y)
			transforms.append(Transform3D(basis, position))
			cursor += dash_length + dash_gap
	parent.set_meta("system_road_marking_transforms", transforms)


func _collect_sidewalk_transforms(parent: Node3D, line: PackedVector2Array, road_width: float, tags: Dictionary, road_lift: float) -> void:
	# Build sidewalks only where OSM explicitly maps them. Footway/path ways
	# remain their own mapped geometry and are not duplicated as road-edge walks.
	var general := str(tags.get("sidewalk", "")).to_lower()
	var left_enabled := false
	var right_enabled := false
	if general in ["yes", "both"]:
		left_enabled = true
		right_enabled = true
	elif general == "left":
		left_enabled = true
	elif general == "right":
		right_enabled = true
	var left_tag := str(tags.get("sidewalk:left", "")).to_lower()
	var right_tag := str(tags.get("sidewalk:right", "")).to_lower()
	if left_tag != "":
		left_enabled = left_tag in ["yes", "both", "raised", "lowered", "shared"]
	if right_tag != "":
		right_enabled = right_tag in ["yes", "both", "raised", "lowered", "shared"]
	if general in ["no", "none", "separate"]:
		left_enabled = left_tag in ["yes", "both", "raised", "lowered", "shared"]
		right_enabled = right_tag in ["yes", "both", "raised", "lowered", "shared"]
	if not left_enabled and not right_enabled:
		return
	var transforms: Array = parent.get_meta("system_sidewalk_transforms", [])
	for segment_index in range(line.size() - 1):
		if transforms.size() >= 1000:
			break
		var start: Vector2 = line[segment_index]
		var finish: Vector2 = line[segment_index + 1]
		var segment := finish - start
		var length := segment.length()
		if length < 1.0:
			continue
		var direction := segment / length
		var side := Vector2(-direction.y, direction.x)
		var sidewalk_width := 1.45
		var offset := road_width * 0.5 + sidewalk_width * 0.5 + 0.18
		var rotation_basis := Basis(
			Vector3(direction.x, 0.0, direction.y),
			Vector3.UP,
			Vector3(-direction.y, 0.0, direction.x)
		)
		# Split long mapped road edges into terrain-following slabs. A single
		# 90 m box floats over height changes and looks artificial on curved streets.
		var max_segment_length := 12.0
		var chunk_count := maxi(1, int(ceil(length / max_segment_length)))
		for chunk_index in range(chunk_count):
			if transforms.size() >= 1000:
				break
			var chunk_start := start.lerp(finish, float(chunk_index) / float(chunk_count))
			var chunk_finish := start.lerp(finish, float(chunk_index + 1) / float(chunk_count))
			var chunk_length := chunk_start.distance_to(chunk_finish)
			if chunk_length < 0.25:
				continue
			var midpoint := (chunk_start + chunk_finish) * 0.5
			var chunk_basis := rotation_basis.scaled(Vector3(chunk_length, 0.12, sidewalk_width))
			if left_enabled:
				var left_point := midpoint + side * offset
				transforms.append(Transform3D(chunk_basis, Vector3(left_point.x, _terrain_height(left_point) + road_lift + 0.075, left_point.y)))
			if right_enabled and transforms.size() < 1000:
				var right_point := midpoint - side * offset
				transforms.append(Transform3D(chunk_basis, Vector3(right_point.x, _terrain_height(right_point) + road_lift + 0.075, right_point.y)))
	parent.set_meta("system_sidewalk_transforms", transforms)


func _flush_sidewalk_multimesh(parent: Node3D) -> void:
	var transforms: Array = parent.get_meta("system_sidewalk_transforms", [])
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var sidewalks := MultiMeshInstance3D.new()
	sidewalks.name = "BaghdadCellMappedSidewalks"
	sidewalks.multimesh = multimesh
	sidewalks.material_override = sidewalk_material
	sidewalks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sidewalks.set_meta("system_road_detail_type", "osm_explicit_sidewalks")
	sidewalks.set_meta("system_sidewalk_count", transforms.size())
	sidewalks.set_meta("system_sidewalk_draw_calls_per_cell", 1)
	parent.add_child(sidewalks)
	parent.set_meta("system_sidewalk_instance_count", transforms.size())
	parent.set_meta("system_sidewalk_transforms", [])


func _collect_streetlight_transforms(parent: Node3D, line: PackedVector2Array, road_width: float, tags: Dictionary, is_bridge: bool) -> void:
	# OSM's lit=yes confirms a lit road, not exact lamp coordinates. Fixtures
	# are therefore explicitly marked as inferred spacing, never as surveyed POIs.
	if is_bridge or road_width < 5.8 or str(tags.get("lit", "")).to_lower() not in ["yes", "automatic"]:
		return
	var poles: Array = parent.get_meta("system_streetlight_pole_transforms", [])
	var arms: Array = parent.get_meta("system_streetlight_arm_transforms", [])
	var heads: Array = parent.get_meta("system_streetlight_head_transforms", [])
	for segment_index in range(line.size() - 1):
		if poles.size() >= 36:
			break
		var start: Vector2 = line[segment_index]
		var finish: Vector2 = line[segment_index + 1]
		var segment := finish - start
		var length := segment.length()
		if length < 18.0:
			continue
		var direction := segment / length
		var side := Vector2(-direction.y, direction.x)
		var cursor := 14.0
		while cursor < length - 4.0 and poles.size() < 36:
			var point := start + direction * cursor
			var side_sign := 1.0 if (poles.size() % 2) == 0 else -1.0
			var lateral := side * side_sign
			var pole_point := point + lateral * (road_width * 0.5 + 0.95)
			var ground := _terrain_height(pole_point)
			poles.append(Transform3D(
				Basis().scaled(Vector3(0.16, 5.4, 0.16)),
				Vector3(pole_point.x, ground + 2.7, pole_point.y)
			))
			var arm_direction := -lateral
			var arm_basis := Basis(
				Vector3(arm_direction.x, 0.0, arm_direction.y),
				Vector3.UP,
				Vector3(-arm_direction.y, 0.0, arm_direction.x)
			).scaled(Vector3(1.15, 0.10, 0.10))
			var arm_center := pole_point + arm_direction * 0.58
			arms.append(Transform3D(arm_basis, Vector3(arm_center.x, ground + 5.15, arm_center.y)))
			var head_basis := Basis().scaled(Vector3(0.46, 0.16, 0.30))
			var head_point := pole_point + arm_direction * 1.12
			heads.append(Transform3D(head_basis, Vector3(head_point.x, ground + 5.08, head_point.y)))
			cursor += 30.0
	parent.set_meta("system_streetlight_pole_transforms", poles)
	parent.set_meta("system_streetlight_arm_transforms", arms)
	parent.set_meta("system_streetlight_head_transforms", heads)


func _flush_streetlight_multimeshes(parent: Node3D) -> void:
	var poles: Array = parent.get_meta("system_streetlight_pole_transforms", [])
	var arms: Array = parent.get_meta("system_streetlight_arm_transforms", [])
	var heads: Array = parent.get_meta("system_streetlight_head_transforms", [])
	if poles.is_empty():
		return
	var pole_mesh := BoxMesh.new()
	var arm_mesh := BoxMesh.new()
	var head_mesh := BoxMesh.new()
	var pole_multi := MultiMesh.new()
	pole_multi.transform_format = MultiMesh.TRANSFORM_3D
	pole_multi.mesh = pole_mesh
	pole_multi.instance_count = poles.size()
	var arm_multi := MultiMesh.new()
	arm_multi.transform_format = MultiMesh.TRANSFORM_3D
	arm_multi.mesh = arm_mesh
	arm_multi.instance_count = arms.size()
	var head_multi := MultiMesh.new()
	head_multi.transform_format = MultiMesh.TRANSFORM_3D
	head_multi.mesh = head_mesh
	head_multi.instance_count = heads.size()
	for index in range(poles.size()):
		pole_multi.set_instance_transform(index, poles[index])
		arm_multi.set_instance_transform(index, arms[index])
		head_multi.set_instance_transform(index, heads[index])
	var pole_node := MultiMeshInstance3D.new()
	pole_node.name = "BaghdadCellStreetlightPoles"
	pole_node.multimesh = pole_multi
	pole_node.material_override = streetlight_metal_material
	pole_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pole_node)
	var arm_node := MultiMeshInstance3D.new()
	arm_node.name = "BaghdadCellStreetlightArms"
	arm_node.multimesh = arm_multi
	arm_node.material_override = streetlight_metal_material
	arm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(arm_node)
	var head_node := MultiMeshInstance3D.new()
	head_node.name = "BaghdadCellStreetlightHeads"
	head_node.multimesh = head_multi
	head_node.material_override = streetlight_glow_material
	head_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(head_node)
	for node in [pole_node, arm_node, head_node]:
		node.set_meta("system_road_detail_type", "inferred_lighting_on_osm_lit_road")
		node.set_meta("system_streetlight_source", "inferred_spacing_from_osm_lit_yes_not_surveyed_fixture")
		node.set_meta("system_streetlight_draw_calls_per_cell", 3)
	parent.set_meta("system_streetlight_count", poles.size())
	parent.set_meta("system_streetlight_pole_transforms", [])
	parent.set_meta("system_streetlight_arm_transforms", [])
	parent.set_meta("system_streetlight_head_transforms", [])


func _flush_road_marking_multimesh(parent: Node3D) -> void:
	var transforms: Array = parent.get_meta("system_road_marking_transforms", [])
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var markings := MultiMeshInstance3D.new()
	markings.name = "BaghdadCellRoadCenterMarkings"
	markings.multimesh = multimesh
	markings.material_override = road_marking_material
	markings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	markings.set_meta("system_road_detail_type", "dashed_center_lane_guidance")
	markings.set_meta("system_road_marking_count", transforms.size())
	markings.set_meta("system_road_marking_draw_calls_per_cell", 1)
	parent.add_child(markings)
	parent.set_meta("system_road_marking_instance_count", transforms.size())
	parent.set_meta("system_road_marking_transforms", [])


func _road_surface_material(tags: Dictionary) -> Material:
	var highway := str(tags.get("highway", "")).to_lower()
	if highway in ["footway", "path", "pedestrian", "steps", "bridleway"]:
		return sidewalk_material
	return road_material


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


func _is_sensitive_state_site(tags: Dictionary) -> bool:
	var amenity := str(tags.get("amenity", "")).to_lower()
	var building := str(tags.get("building", "")).to_lower()
	var office := str(tags.get("office", "")).to_lower()
	var landuse := str(tags.get("landuse", "")).to_lower()
	var military := str(tags.get("military", "")).to_lower()
	var security := str(tags.get("security", "")).to_lower()
	var aeroway := str(tags.get("aeroway", "")).to_lower()
	return military != "" or security != "" or aeroway in ["military", "airbase"] or amenity in ["police", "police_station"] or building in ["military", "bunker", "government"] or office == "government" or landuse == "military"


func _game_worship_presentation_type(tags: Dictionary) -> String:
	return "mosque" if _worship_facility_type(tags) == "shrine" else _worship_facility_type(tags)


func _game_building_kind(tags: Dictionary) -> String:
	return "mosque" if _building_kind(tags) == "shrine" else _building_kind(tags)


func _game_building_display_name(kind: String, tags: Dictionary) -> String:
	if _worship_facility_type(tags) == "shrine":
		return "جامع أو مسجد"
	return _building_display_name(kind, tags)


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
	var worship_type := _worship_facility_type(tags)
	if worship_type in ["mosque", "church", "shrine", "monastery"]:
		return worship_type
	var amenity_kind := str(tags.get("amenity", "")).to_lower()
	var healthcare_kind := str(tags.get("healthcare", "")).to_lower()
	var tourism_kind := str(tags.get("tourism", "")).to_lower()
	if kind in ["school", "college", "university", "kindergarten"] or amenity_kind in ["school", "college", "university", "kindergarten"]:
		return "education_building"
	if kind in ["hospital", "clinic", "healthcare"] or amenity_kind in ["hospital", "clinic"] or healthcare_kind != "":
		return "healthcare_building"
	if kind in ["fire_station", "police", "government"] or amenity_kind in ["fire_station", "police", "townhall"] or str(tags.get("office", "")).to_lower() == "government":
		return "civic_building"
	if kind in ["hotel", "hostel", "guest_house"] or tourism_kind in ["hotel", "hostel", "guest_house"]:
		return "hospitality_building"
	return "general_building"


func _worship_facility_type(tags: Dictionary) -> String:
	var amenity_kind := str(tags.get("amenity", "")).to_lower()
	var religion := str(tags.get("religion", "")).to_lower()
	var building_kind := str(tags.get("building", "")).to_lower()
	if (religion in ["muslim", "islam"] and building_kind in ["church", "chapel", "cathedral"]) or (religion in ["christian", "christianity"] and building_kind == "mosque"):
		return "religious_tag_conflict"
	if amenity_kind == "monastery" or building_kind == "monastery":
		return "monastery"
	if amenity_kind == "place_of_worship" and religion in ["muslim", "islam"]:
		return "mosque"
	if amenity_kind == "place_of_worship" and religion in ["christian", "christianity"]:
		return "church"
	if building_kind in ["church", "chapel", "cathedral"]:
		return "church"
	# OSM sometimes records religion on a generic mapped building footprint.
	if religion in ["muslim", "islam"] and building_kind in ["religious", "public"]:
		return "mosque"
	if religion in ["christian", "christianity"] and building_kind in ["religious", "public"]:
		return "church"
	if building_kind == "mosque":
		return "mosque"
	if building_kind == "church":
		return "church"
	if building_kind == "shrine":
		return "shrine"
	if amenity_kind == "place_of_worship":
		return "place_of_worship"
	return ""


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
		"shrine":
			material.albedo_color = Color(0.76, 0.62, 0.39)
		"monastery":
			material.albedo_color = Color(0.66, 0.59, 0.49)
		"education_building":
			material.albedo_color = Color(0.72, 0.66, 0.48)
		"healthcare_building":
			material.albedo_color = Color(0.66, 0.76, 0.78)
		"civic_building":
			material.albedo_color = Color(0.62, 0.67, 0.72)
		"hospitality_building":
			material.albedo_color = Color(0.74, 0.62, 0.50)
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
