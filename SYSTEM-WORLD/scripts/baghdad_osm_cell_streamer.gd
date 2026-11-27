extends Node3D
class_name BaghdadOSMCellStreamer

## Loads the first real Baghdad OSM cell pack in the same local tangent frame
## used by SystemRealWorldGeographyManager. Source IDs and OSM tags are retained.

const DEFAULT_DATA_ROOT := "res://data/geography/baghdad/cell_pack"
const DEFAULT_CELL_SIZE := 200.0
const MAX_CELL_OPERATIONS_PER_FRAME := 1
const VEHICLE_HIGHWAYS := [
	"motorway", "motorway_link", "trunk", "trunk_link",
	"primary", "primary_link", "secondary", "secondary_link",
	"tertiary", "tertiary_link", "unclassified", "residential",
	"living_street", "service", "track", "road"
]

signal cell_loaded(cell: Vector2i, cell_root: Node3D)
signal cell_unloading(cell: Vector2i, cell_root: Node3D)
signal cell_unloaded(cell: Vector2i, cell_id: String)

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
var canonical_origin_frame_valid := false
var source_snapshot := ""
var manifest_schema_version := 0
var _last_center_cell := Vector2i(2147483647, 2147483647)

var road_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var water_material: StandardMaterial3D
var land_material: StandardMaterial3D
var building_material: StandardMaterial3D
var amenity_material: StandardMaterial3D

var _road_navigation_graph := AStar2D.new()
var _road_navigation_positions: Dictionary = {}
var _road_navigation_graph_dirty := true
var _road_navigation_graph_build_count := 0
var _vehicle_navigation_graph := AStar2D.new()
var _vehicle_navigation_positions: Dictionary = {}
var _vehicle_navigation_graph_dirty := true
var _vehicle_navigation_graph_build_count := 0


func _ready() -> void:
	var manifest_path := data_root.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		push_warning("SYSTEM Baghdad OSM: cell pack is not installed; procedural Baghdad fallback remains active.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		push_error("SYSTEM Baghdad OSM: manifest JSON must be an object.")
		return
	manifest_schema_version = int(parsed.get("schema_version", 0))
	if manifest_schema_version != 1:
		push_error("SYSTEM Baghdad OSM: unsupported manifest schema version.")
		return
	if str(parsed.get("region_id", "")) != "iraq_baghdad_region":
		push_error("SYSTEM Baghdad OSM: manifest region ID is invalid.")
		return
	if str(parsed.get("coordinate_system", "")) != "SYSTEM_LOCAL_ECEF_TANGENT":
		push_error("SYSTEM Baghdad OSM: unsupported coordinate projection.")
		return
	var origin_value: Variant = parsed.get("origin", {})
	if not origin_value is Dictionary:
		push_error("SYSTEM Baghdad OSM: manifest origin must be an object.")
		return
	var origin: Dictionary = origin_value
	var origin_lat := float(origin.get("latitude", NAN))
	var origin_lon := float(origin.get("longitude", NAN))
	if not is_finite(origin_lat) or not is_finite(origin_lon) or origin_lat < -90.0 or origin_lat > 90.0 or origin_lon < -180.0 or origin_lon > 180.0:
		push_error("SYSTEM Baghdad OSM: manifest WGS84 origin is invalid.")
		return
	var registry_path := "res://data/geography/real_world_registry.json"
	if not FileAccess.file_exists(registry_path):
		push_error("SYSTEM Baghdad OSM: canonical geography registry is missing.")
		return
	var registry: Variant = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
	if not registry is Dictionary:
		push_error("SYSTEM Baghdad OSM: canonical geography registry is invalid.")
		return
	var regions_value: Variant = registry.get("regions", {})
	if not regions_value is Dictionary:
		push_error("SYSTEM Baghdad OSM: geography registry regions must be an object.")
		return
	var regions: Dictionary = regions_value
	var region_record_value: Variant = regions.get("iraq_baghdad_region", {})
	if not region_record_value is Dictionary:
		push_error("SYSTEM Baghdad OSM: canonical Baghdad registry record is invalid.")
		return
	var region_record: Dictionary = region_record_value
	var canonical_origin_value: Variant = region_record.get("origin", {})
	if not canonical_origin_value is Dictionary:
		push_error("SYSTEM Baghdad OSM: canonical Baghdad origin is invalid.")
		return
	var canonical_origin: Dictionary = canonical_origin_value
	if canonical_origin.is_empty():
		push_error("SYSTEM Baghdad OSM: canonical Baghdad region origin is missing from the geography registry.")
		return
	if absf(origin_lat - float(canonical_origin.get("latitude", 0.0))) > 0.000001 or absf(origin_lon - float(canonical_origin.get("longitude", 0.0))) > 0.000001:
		push_error("SYSTEM Baghdad OSM: cell pack origin differs from the canonical WGS84 registry anchor.")
		return
	var axes_value: Variant = parsed.get("axes", {})
	if not axes_value is Dictionary:
		push_error("SYSTEM Baghdad OSM: manifest axes must be an object.")
		return
	var axes: Dictionary = axes_value
	if str(axes.get("x", "")) != "east_m" or str(axes.get("z", "")) != "south_m":
		push_error("SYSTEM Baghdad OSM: unsupported local coordinate axes.")
		return
	cell_size = float(parsed.get("cell_size_m", NAN))
	var bounds_value: Variant = parsed.get("cell_bounds_inclusive", [])
	if not bounds_value is Array or not is_finite(cell_size) or cell_size <= 0.0:
		push_error("SYSTEM Baghdad OSM: invalid cell size or bounds format.")
		return
	var bounds: Array = bounds_value
	if bounds.size() != 4:
		push_error("SYSTEM Baghdad OSM: cell bounds must contain min_x, max_x, min_z, max_z.")
		return
	for bound in bounds:
		if typeof(bound) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(bound)):
			push_error("SYSTEM Baghdad OSM: cell bounds must be finite numbers.")
			return
	min_cell_x = int(bounds[0])
	max_cell_x = int(bounds[1])
	min_cell_z = int(bounds[2])
	max_cell_z = int(bounds[3])
	if min_cell_x > max_cell_x or min_cell_z > max_cell_z:
		push_error("SYSTEM Baghdad OSM: cell bounds are inverted.")
		return
	terrain_manager = get_parent().get_node_or_null("ModernContinent")
	_create_materials()
	_add_attribution_overlay()
	source_snapshot = str(parsed.get("source_snapshot", ""))
	canonical_origin_frame_valid = true
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
		var cell: Vector2i = pending_loads.pop_front()
		if desired_cells.has(cell) and not loaded_cells.has(cell):
			_load_cell(cell)
			operations += 1
	while not pending_unloads.is_empty() and operations < MAX_CELL_OPERATIONS_PER_FRAME:
		var cell: Vector2i = pending_unloads.pop_front()
		if not desired_cells.has(cell) and loaded_cells.has(cell):
			_unload_cell(cell)
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
	if int(parsed.get("schema_version", 0)) != manifest_schema_version:
		push_warning("SYSTEM Baghdad OSM: cell schema version does not match manifest: " + path)
		return
	if str(parsed.get("region_id", "")) != "iraq_baghdad_region":
		push_warning("SYSTEM Baghdad OSM: cell region ID does not match manifest: " + path)
		return
	if int(parsed.get("cell_x", 2147483647)) != cell.x or int(parsed.get("cell_z", 2147483647)) != cell.y:
		push_warning("SYSTEM Baghdad OSM: cell coordinates do not match requested cell: " + path)
		return
	var tile_cell_size := float(parsed.get("cell_size_m", NAN))
	if not is_finite(tile_cell_size) or not is_equal_approx(tile_cell_size, cell_size):
		push_warning("SYSTEM Baghdad OSM: cell size does not match manifest: " + path)
		return
	var layers_value: Variant = parsed.get("layers", {})
	if not layers_value is Dictionary:
		push_warning("SYSTEM Baghdad OSM: cell layers must be an object: " + path)
		return
	var layers: Dictionary = layers_value
	for layer_name in layers:
		if not layers[layer_name] is Array:
			push_warning("SYSTEM Baghdad OSM: cell layer is not an array: " + str(layer_name))
			return
	var cell_root := Node3D.new()
	cell_root.name = "BaghdadOSMCell_%d_%d" % [cell.x, cell.y]
	cell_root.set_meta("cell_id", "%d:%d" % [cell.x, cell.y])
	cell_root.set_meta("region_id", "iraq_baghdad_region")
	cell_root.set_meta("cell_x", cell.x)
	cell_root.set_meta("cell_z", cell.y)
	cell_root.set_meta("schema_version", manifest_schema_version)
	cell_root.set_meta("source_snapshot", source_snapshot)
	var counts := {}
	var road_features: Array = layers.get("roads", [])
	var road_navigation_segments: Array[Dictionary] = []
	var vehicle_navigation_segments: Array[Dictionary] = []
	var road_count := 0
	for feature in road_features:
		var road_tags: Dictionary = feature.get("tags", {})
		var highway_kind := str(road_tags.get("highway", "")).to_lower()
		if not highway_kind.is_empty() and str(road_tags.get("access", "")).to_lower() not in ["no", "private"] and str(road_tags.get("foot", "")).to_lower() != "no" and highway_kind not in ["motorway", "motorway_link", "trunk", "trunk_link", "raceway", "proposed", "construction"]:
			for road_line in _extract_lines(feature.get("geometry", {})):
				if road_line.size() >= 2:
					road_navigation_segments.append({
						"feature_id": str(feature.get("id", "")),
						"highway": highway_kind,
						"points": road_line
					})
		if _is_vehicle_road(road_tags):
			var oneway := str(road_tags.get("oneway", "no")).to_lower()
			if oneway.is_empty() and str(road_tags.get("junction", "")).to_lower() == "roundabout":
				oneway = "yes"
			for vehicle_road_line in _extract_lines(feature.get("geometry", {})):
				if vehicle_road_line.size() >= 2:
					vehicle_navigation_segments.append({
						"feature_id": str(feature.get("id", "")),
						"highway": highway_kind,
						"oneway": oneway,
						"maxspeed": str(road_tags.get("maxspeed", "")),
						"lanes": str(road_tags.get("lanes", "")),
						"surface": str(road_tags.get("surface", "")),
						"layer": str(road_tags.get("layer", "0")),
						"bridge": str(road_tags.get("bridge", "")),
						"tunnel": str(road_tags.get("tunnel", "")),
						"points": vehicle_road_line
					})
		road_count += _build_line_feature(cell_root, feature, _road_width(road_tags), road_material, 0.16, "OSMRoad")
	cell_root.set_meta("road_navigation_segments", road_navigation_segments)
	cell_root.set_meta("vehicle_navigation_segments", vehicle_navigation_segments)
	var building_count := 0
	for feature in layers.get("buildings", []):
		building_count += _build_building_feature(cell_root, feature, road_features)
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
	var amenity_count := 0
	for feature in layers.get("amenities", []):
		amenity_count += _build_amenity_feature(cell_root, feature)
	var historic_site_count := 0
	for feature in layers.get("historic-sites", []):
		historic_site_count += _build_historic_site_feature(cell_root, feature)
	var entrance_count := 0
	for feature in layers.get("entrances", []):
		entrance_count += _build_entrance_feature(cell_root, feature)
	counts["entrances"] = entrance_count
	counts["roads"] = road_count
	counts["waterways"] = water_count
	counts["bridges"] = bridge_count
	counts["amenities"] = amenity_count
	counts["historic-sites"] = historic_site_count
	cell_root.set_meta("feature_counts", counts)
	add_child(cell_root)
	loaded_cells[cell] = cell_root
	_road_navigation_graph_dirty = true
	_vehicle_navigation_graph_dirty = true
	cell_loaded.emit(cell, cell_root)


## Returns a route along real OSM pedestrian-accessible roads in currently loaded cells.
## The route is local to the streamed neighborhood; callers should request it only for Baghdad.
func get_road_navigation_path(start: Vector3, target: Vector3, max_snap_distance: float = 55.0) -> Array[Vector3]:
	if not enabled or loaded_cells.is_empty():
		return []
	_ensure_road_navigation_graph()
	if _road_navigation_graph.get_point_count() < 2:
		return []
	var start_id := _nearest_road_graph_point(Vector2(start.x, start.z), max_snap_distance)
	var target_id := _nearest_road_graph_point(Vector2(target.x, target.z), max_snap_distance)
	if start_id < 0 or target_id < 0:
		return []
	var graph_path := _road_navigation_graph.get_point_path(start_id, target_id)
	if graph_path.is_empty():
		return []
	var route: Array[Vector3] = []
	var start_road_point: Vector2 = graph_path[0]
	var start_approach := Vector3(start.x, _terrain_height(Vector2(start.x, start.z)) + 0.22, start.z)
	var snapped_start := Vector3(start_road_point.x, _terrain_height(start_road_point) + 0.24, start_road_point.y)
	if start_approach.distance_to(snapped_start) > 0.35:
		route.append(start_approach)
	for point in graph_path:
		var world_point := Vector3(point.x, _terrain_height(point) + 0.24, point.y)
		if route.is_empty() or route[route.size() - 1].distance_to(world_point) > 0.5:
			route.append(world_point)
	var target_road_point: Vector2 = graph_path[graph_path.size() - 1]
	var target_approach := Vector3(target.x, _terrain_height(Vector2(target.x, target.z)) + 0.22, target.z)
	var snapped_target := Vector3(target_road_point.x, _terrain_height(target_road_point) + 0.24, target_road_point.y)
	if snapped_target.distance_to(target_approach) > 0.35:
		route.append(target_approach)
	return route


## Returns a route along real OSM motor-vehicle roads in currently loaded Baghdad cells.
## OSM one-way direction and explicit motor-vehicle access restrictions are enforced.
func get_vehicle_navigation_path(start: Vector3, target: Vector3, max_snap_distance: float = 70.0) -> Array[Vector3]:
	if not enabled or loaded_cells.is_empty():
		return []
	_ensure_vehicle_navigation_graph()
	if _vehicle_navigation_graph.get_point_count() < 2:
		return []
	var start_id := _nearest_vehicle_road_graph_point(Vector2(start.x, start.z), max_snap_distance)
	var target_id := _nearest_vehicle_road_graph_point(Vector2(target.x, target.z), max_snap_distance)
	if start_id < 0 or target_id < 0:
		return []
	var graph_path := _vehicle_navigation_graph.get_point_path(start_id, target_id)
	if graph_path.is_empty():
		return []
	# Vehicles stay on mapped road vertices; unlike pedestrian routes, no
	# straight-line snap connector may cross a building or restricted area.
	var route: Array[Vector3] = []
	for point in graph_path:
		var world_point := Vector3(point.x, _terrain_height(point) + 0.24, point.y)
		if route.is_empty() or route[route.size() - 1].distance_to(world_point) > 0.5:
			route.append(world_point)
	return route


func get_loaded_vehicle_map_segments() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cell_root_value in loaded_cells.values():
		var cell_root := cell_root_value as Node3D
		if not is_instance_valid(cell_root):
			continue
		var segments_value: Variant = cell_root.get_meta("vehicle_navigation_segments", [])
		if not segments_value is Array:
			continue
		for segment_value in segments_value:
			if not segment_value is Dictionary:
				continue
			var points_value: Variant = segment_value.get("points", PackedVector2Array())
			if not points_value is PackedVector2Array or points_value.size() < 2:
				continue
			result.append({
				"feature_id": str(segment_value.get("feature_id", "")),
				"highway": str(segment_value.get("highway", "road")),
				"oneway": str(segment_value.get("oneway", "no")),
				"maxspeed": str(segment_value.get("maxspeed", "")),
				"lanes": str(segment_value.get("lanes", "")),
				"surface": str(segment_value.get("surface", "")),
				"layer": str(segment_value.get("layer", "0")),
				"bridge": str(segment_value.get("bridge", "")),
				"tunnel": str(segment_value.get("tunnel", "")),
				"points": points_value
			})
	return result


func _is_vehicle_road(tags: Dictionary) -> bool:
	var highway := str(tags.get("highway", "")).to_lower()
	if highway not in VEHICLE_HIGHWAYS:
		return false
	# Conditional access and reversible one-way rules need a time-aware traffic
	# controller; do not silently treat them as unrestricted two-way streets.
	for conditional_key in ["access:conditional", "vehicle:conditional", "motor_vehicle:conditional", "oneway:conditional"]:
		if not str(tags.get(conditional_key, "")).strip_edges().is_empty():
			return false
	if str(tags.get("oneway", "")).to_lower() == "reversible":
		return false
	for access_key in ["access", "vehicle", "motor_vehicle", "motorcar"]:
		var access_value := str(tags.get(access_key, "")).to_lower()
		if access_value in ["no", "private", "agricultural", "forestry", "destination", "customers", "delivery", "permit"]:
			return false
	return true


func _ensure_vehicle_navigation_graph() -> void:
	if not _vehicle_navigation_graph_dirty:
		return
	_vehicle_navigation_graph = AStar2D.new()
	_vehicle_navigation_positions.clear()
	var coordinate_to_id: Dictionary = {}
	var next_id := 1
	for cell_root_value in loaded_cells.values():
		var cell_root := cell_root_value as Node3D
		if not is_instance_valid(cell_root):
			continue
		var segments_value: Variant = cell_root.get_meta("vehicle_navigation_segments", [])
		if not segments_value is Array:
			continue
		for segment_value in segments_value:
			if not segment_value is Dictionary:
				continue
			var points_value: Variant = segment_value.get("points", PackedVector2Array())
			if not points_value is PackedVector2Array or points_value.size() < 2:
				continue
			var points: PackedVector2Array = points_value
			var oneway := str(segment_value.get("oneway", "no")).to_lower()
			if oneway == "-1":
				points.reverse()
			var bidirectional := oneway not in ["yes", "1", "true", "-1"]
			var previous_id := -1
			for point in points:
				var level_key := "%s:%s:%s" % [str(segment_value.get("layer", "0")), str(segment_value.get("bridge", "")), str(segment_value.get("tunnel", ""))]
				var key := "%s:%d:%d" % [level_key, roundi(point.x * 2.0), roundi(point.y * 2.0)]
				var point_id := int(coordinate_to_id.get(key, -1))
				if point_id < 0:
					point_id = next_id
					next_id += 1
					coordinate_to_id[key] = point_id
					_vehicle_navigation_graph.add_point(point_id, point)
					_vehicle_navigation_positions[point_id] = point
				if previous_id >= 0 and previous_id != point_id and not _vehicle_navigation_graph.are_points_connected(previous_id, point_id):
					_vehicle_navigation_graph.connect_points(previous_id, point_id, bidirectional)
				previous_id = point_id
	_vehicle_navigation_graph_dirty = false
	_vehicle_navigation_graph_build_count += 1


func _nearest_vehicle_road_graph_point(position: Vector2, max_distance: float) -> int:
	var best_id := -1
	var best_distance_squared := max_distance * max_distance
	for point_id_value in _vehicle_navigation_positions.keys():
		var point_id := int(point_id_value)
		var point: Vector2 = _vehicle_navigation_positions[point_id]
		var distance_squared := position.distance_squared_to(point)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_id = point_id
	return best_id


## Returns real OSM pedestrian road segments from currently loaded Baghdad cells.
## Coordinates use the canonical local metric frame shared with the cell pack.
func get_loaded_road_map_segments() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cell_root_value in loaded_cells.values():
		var cell_root := cell_root_value as Node3D
		if not is_instance_valid(cell_root):
			continue
		var segments_value: Variant = cell_root.get_meta("road_navigation_segments", [])
		if not segments_value is Array:
			continue
		for segment_value in segments_value:
			if not segment_value is Dictionary:
				continue
			var points_value: Variant = segment_value.get("points", PackedVector2Array())
			if not points_value is PackedVector2Array or points_value.size() < 2:
				continue
			result.append({
				"highway": str(segment_value.get("highway", "road")),
				"points": points_value
			})
	return result


func _ensure_road_navigation_graph() -> void:
	if not _road_navigation_graph_dirty:
		return
	_road_navigation_graph = AStar2D.new()
	_road_navigation_positions.clear()
	var coordinate_to_id: Dictionary = {}
	var next_id := 1
	for cell_root_value in loaded_cells.values():
		var cell_root := cell_root_value as Node3D
		if not is_instance_valid(cell_root):
			continue
		var segments_value: Variant = cell_root.get_meta("road_navigation_segments", [])
		if not segments_value is Array:
			continue
		for segment_value in segments_value:
			if not segment_value is Dictionary:
				continue
			var points_value: Variant = segment_value.get("points", PackedVector2Array())
			if not points_value is PackedVector2Array or points_value.size() < 2:
				continue
			var previous_id := -1
			for point in points_value:
				var key := "%d:%d" % [roundi(point.x * 2.0), roundi(point.y * 2.0)]
				var point_id := int(coordinate_to_id.get(key, -1))
				if point_id < 0:
					point_id = next_id
					next_id += 1
					coordinate_to_id[key] = point_id
					_road_navigation_graph.add_point(point_id, point)
					_road_navigation_positions[point_id] = point
				if previous_id >= 0 and previous_id != point_id and not _road_navigation_graph.are_points_connected(previous_id, point_id):
					_road_navigation_graph.connect_points(previous_id, point_id, true)
				previous_id = point_id
	_road_navigation_graph_dirty = false
	_road_navigation_graph_build_count += 1


func _nearest_road_graph_point(position: Vector2, max_distance: float) -> int:
	var best_id := -1
	var best_distance_squared := max_distance * max_distance
	for point_id_value in _road_navigation_positions.keys():
		var point_id := int(point_id_value)
		var point: Vector2 = _road_navigation_positions[point_id]
		var distance_squared := position.distance_squared_to(point)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_id = point_id
	return best_id


func get_cell_node(cell: Vector2i) -> Node3D:
	return loaded_cells.get(cell) as Node3D


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
		var mesh := surface.commit()
		if mesh == null or mesh.get_surface_count() == 0:
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
		var historic_landmark_kind := _historic_landmark_kind(tags)
		if not historic_landmark_kind.is_empty():
			building.set_meta("landmark_type", historic_landmark_kind)
			building.set_meta("osm_feature_id", feature_id)
			building.set_meta("osm_historic_tag", str(tags.get("historic", tags.get("building", ""))))
			if historic_landmark_kind in ["archaeological_ruin", "archaeological_site"]:
				_add_archaeological_ruin_detail(parent, ring, height, feature_id, tags)
			else:
				_add_historic_polygon_landmark(parent, ring, height, feature_id, tags, historic_landmark_kind)
		var approach := _find_building_approach_point(ring, road_features)
		if not approach.is_empty():
			_add_building_approach_marker(parent, approach, feature_id, kind, tags)
		built += 1
		if kind == "church" or kind == "mosque":
			_add_polygon_worship_detail(parent, ring, height, kind, feature_id)
	return built


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
		"archaeological_ruin", "archaeological_site":
			return "أطلال أو موقع أثري موثق"
		"historic_monument":
			return "نصب أو معلم تذكاري"
		"historic_tomb":
			return "مرقد أو ضريح تراثي"
		"historic_building":
			return "مبنى تراثي"
		"historic_fortification":
			return "حصن أو قصر تاريخي"
		"historic_gate":
			return "بوابة تاريخية"
		"detached_house":
			return "منزل سكني"
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


func _build_historic_site_feature(parent: Node3D, feature: Dictionary) -> int:
	var tags: Dictionary = feature.get("tags", {})
	if not _is_historic_landmark(tags):
		return 0
	var feature_id := str(feature.get("id", "unknown"))
	for child in parent.get_children():
		if str(child.get_meta("osm_feature_id", "")) == feature_id and not str(child.get_meta("landmark_type", "")).is_empty():
			return 0
	var geometry: Dictionary = feature.get("geometry", {})
	var geometry_type := str(geometry.get("type", ""))
	if geometry_type in ["Point", "Polygon", "MultiPolygon"]:
		return _build_amenity_feature(parent, feature)
	if geometry_type == "LineString" or geometry_type == "MultiLineString":
		var stone := StandardMaterial3D.new()
		stone.albedo_color = Color(0.48, 0.38, 0.28)
		stone.roughness = 0.98
		var built := _build_line_feature(parent, feature, 1.6, stone, 0.14, "OSMHistoricSiteBoundary")
		var lines := _extract_lines(geometry)
		if not lines.is_empty() and lines[0].size() >= 2:
			var line: PackedVector2Array = lines[0]
			var midpoint: Vector2 = line[int(line.size() / 2)]
			_build_archaeological_site_landmark(parent, feature, [midpoint.x, midpoint.y])
			return maxi(built, 1)
		return built
	if geometry_type == "GeometryCollection":
		var built_parts := 0
		var geometry_parts: Array = geometry.get("geometries", [])
		for index in range(geometry_parts.size()):
			var part: Dictionary = geometry_parts[index]
			var part_feature: Dictionary = feature.duplicate(true)
			part_feature["id"] = feature_id + "_part_" + str(index)
			part_feature["geometry"] = part
			built_parts += _build_historic_site_feature(parent, part_feature)
		return built_parts
	return 0


func _is_kadhimiya_historic_feature(tags: Dictionary) -> bool:
	for key in ["name", "name:ar", "name:en", "addr:suburb", "addr:district", "addr:neighbourhood", "addr:city", "addr:quarter"]:
		var value := str(tags.get(key, "")).to_lower()
		if value.contains("الكاظمية") or value.contains("kadhimiya") or value.contains("kadhimain"):
			return true
	return false


func _historic_landmark_kind(tags: Dictionary) -> String:
	if _is_kadhimiya_historic_feature(tags):
		return ""
	var historic := str(tags.get("historic", "")).to_lower()
	var building := str(tags.get("building", "")).to_lower()
	var site_type := str(tags.get("site_type", "")).to_lower()
	var ruins_tag := str(tags.get("ruins", "")).to_lower()
	if historic in ["ruins", "citywalls"] or building == "ruins" or ruins_tag in ["yes", "fort"]:
		return "archaeological_ruin"
	if historic == "archaeological_site" or site_type == "archaeological":
		return "archaeological_site"
	if historic in ["castle", "fort"]:
		return "historic_fortification"
	if historic == "city_gate":
		return "historic_gate"
	if historic == "tomb":
		return "historic_tomb"
	if historic == "building":
		return "historic_building"
	if historic in ["monument", "memorial"]:
		return "historic_monument"
	return ""


func _is_historic_landmark(tags: Dictionary) -> bool:
	return not _historic_landmark_kind(tags).is_empty()


func _build_amenity_feature(parent: Node3D, feature: Dictionary) -> int:
	var geometry: Dictionary = feature.get("geometry", {})
	var geometry_type := str(geometry.get("type", ""))
	var tags: Dictionary = feature.get("tags", {})
	var feature_id := str(feature.get("id", "unknown"))
	var worship := str(tags.get("amenity", "")) == "place_of_worship"
	var religion := str(tags.get("religion", "")).to_lower()
	var is_mosque := (worship and religion == "muslim") or str(tags.get("building", "")).to_lower() == "mosque"
	var is_church := (worship and religion == "christian") or str(tags.get("building", "")).to_lower() == "church"
	if geometry_type == "Point" and is_mosque:
		_build_mosque_landmark(parent, feature, geometry.get("coordinates", []))
		return 1
	if geometry_type == "Point" and is_church:
		_build_church_landmark(parent, feature, geometry.get("coordinates", []))
		return 1
	if _is_historic_landmark(tags):
		if geometry_type == "Point":
			_build_archaeological_site_landmark(parent, feature, geometry.get("coordinates", []))
			return 1
		if geometry_type == "Polygon" or geometry_type == "MultiPolygon":
			var built_sites := 0
			for polygon in _extract_polygons(geometry):
				var ring := PackedVector2Array()
				for coordinate in polygon:
					if coordinate is Array and coordinate.size() >= 2:
						ring.append(Vector2(float(coordinate[0]), float(coordinate[1])))
				if ring.size() > 2 and ring[0].is_equal_approx(ring[ring.size() - 1]):
					ring.remove_at(ring.size() - 1)
				if ring.size() < 3:
					continue
				var landmark_kind := _historic_landmark_kind(tags)
				var site_root: Node3D
				if landmark_kind in ["archaeological_ruin", "archaeological_site"]:
					site_root = _add_archaeological_ruin_detail(parent, ring, 3.2, feature_id, tags)
				else:
					site_root = _add_historic_polygon_landmark(parent, ring, 8.0, feature_id, tags, landmark_kind)
				if site_root != null:
					site_root.name = "OSMArchaeologicalSiteArea_%s_%d" % [feature_id, built_sites]
					_add_archaeological_site_interaction(site_root, feature_id, tags)
					built_sites += 1
			return built_sites
		return 0
	if geometry_type != "Point":
		return 0
	_add_point_marker(parent, geometry.get("coordinates", []), amenity_material, 0.48, "OSMAmenity_%s" % feature_id)
	return 1


func _build_archaeological_site_landmark(parent: Node3D, feature: Dictionary, coordinates: Array) -> void:
	if coordinates.size() < 2:
		return
	var point := Vector2(float(coordinates[0]), float(coordinates[1]))
	var feature_id := str(feature.get("id", "unknown"))
	var tags: Dictionary = feature.get("tags", {})
	var historic_kind := str(tags.get("historic", tags.get("site_type", "archaeological_site")))
	var landmark_kind := _historic_landmark_kind(tags)
	var site_name := str(tags.get("name:ar", tags.get("name", "معلم تاريخي موثق")))
	var root := Node3D.new()
	root.name = "OSMArchaeologicalSite_%s" % feature_id
	root.position = Vector3(point.x, _terrain_height(point), point.y)
	root.set_meta("landmark_type", landmark_kind)
	root.set_meta("osm_feature_id", feature_id)
	root.set_meta("osm_historic_tag", historic_kind)
	root.set_meta("system_display_name", site_name)
	parent.add_child(root)

	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.55, 0.43, 0.30)
	stone.roughness = 0.94
	var worn_stone := StandardMaterial3D.new()
	worn_stone.albedo_color = Color(0.39, 0.32, 0.25)
	worn_stone.roughness = 1.0
	_add_archaeology_box(root, "SiteFoundation", Vector3(0.0, 0.16, 0.0), Vector3(22.0, 0.32, 22.0), stone, 0.0)
	match landmark_kind:
		"historic_monument":
			_build_point_historic_monument(root, tags, stone, worn_stone)
		"historic_tomb":
			_build_point_historic_tomb(root, stone, worn_stone)
		"historic_building":
			_build_point_historic_building(root, stone, worn_stone)
		"historic_fortification":
			_build_point_historic_fortification(root, stone, worn_stone)
		"historic_gate":
			_build_point_historic_gate(root, stone, worn_stone)
		_:
			_build_point_archaeological_ruins(root, feature_id, stone, worn_stone)

	var sign := Label3D.new()
	sign.name = "HistoricLandmarkName"
	sign.text = site_name
	sign.font_size = 24
	sign.position = Vector3(0.0, 10.0, -12.0)
	sign.modulate = Color(0.9, 0.78, 0.57)
	root.add_child(sign)

	_add_archaeological_site_interaction(root, feature_id, tags)


func _add_archaeology_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, rotation_y: float) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.rotation.y = rotation_y
	var visual := MeshInstance3D.new()
	visual.name = "StoneVisual"
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _build_point_historic_monument(root: Node3D, tags: Dictionary, stone: Material, accent: Material) -> void:
	if str(tags.get("memorial", "")).to_lower() == "plaque":
		_add_archaeology_box(root, "MemorialPlaqueBase", Vector3(0.0, 0.55, 0.0), Vector3(10.0, 1.1, 3.0), stone, 0.0)
		_add_archaeology_box(root, "MemorialPlaqueWall", Vector3(0.0, 2.9, 0.0), Vector3(8.0, 3.8, 0.65), accent, 0.0)
	else:
		_add_archaeology_box(root, "MonumentPedestal", Vector3(0.0, 0.8, 0.0), Vector3(5.5, 1.6, 5.5), stone, 0.0)
		_add_archaeology_box(root, "MonumentShaft", Vector3(0.0, 4.5, 0.0), Vector3(2.2, 6.0, 2.2), accent, 0.0)
		_add_archaeology_box(root, "MonumentCap", Vector3(0.0, 7.8, 0.0), Vector3(3.5, 1.0, 3.5), stone, 0.0)


func _build_point_historic_tomb(root: Node3D, stone: Material, accent: Material) -> void:
	_add_archaeology_box(root, "TombFoundation", Vector3(0.0, 0.45, 0.0), Vector3(15.0, 0.9, 15.0), stone, 0.0)
	_add_archaeology_box(root, "TombLeftWall", Vector3(-6.5, 3.0, 0.0), Vector3(0.8, 5.0, 13.0), stone, 0.0)
	_add_archaeology_box(root, "TombRightWall", Vector3(6.5, 3.0, 0.0), Vector3(0.8, 5.0, 13.0), stone, 0.0)
	_add_archaeology_box(root, "TombRearWall", Vector3(0.0, 3.0, 6.5), Vector3(13.0, 5.0, 0.8), stone, 0.0)
	_add_archaeology_box(root, "TombEntranceLintel", Vector3(0.0, 5.0, -6.5), Vector3(5.0, 1.0, 0.8), accent, 0.0)
	var dome := MeshInstance3D.new()
	dome.name = "TombDome"
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 4.8
	dome_mesh.height = 4.2
	dome.mesh = dome_mesh
	dome.position = Vector3(0.0, 6.8, 0.0)
	dome.material_override = accent
	root.add_child(dome)


func _build_point_historic_building(root: Node3D, stone: Material, accent: Material) -> void:
	_add_archaeology_box(root, "HeritageBuildingBase", Vector3(0.0, 0.4, 0.0), Vector3(18.0, 0.8, 14.0), stone, 0.0)
	for x_side in [-1.0, 1.0]:
		for z_side in [-1.0, 1.0]:
			_add_archaeology_box(root, "HeritageFacadeColumn_%s_%s" % [str(x_side), str(z_side)], Vector3(x_side * 6.5, 3.0, z_side * 4.8), Vector3(1.1, 5.2, 1.1), accent, 0.0)
	_add_archaeology_box(root, "HeritageFacadeLintel", Vector3(0.0, 5.8, -4.8), Vector3(14.0, 1.0, 1.0), stone, 0.0)
	_add_archaeology_box(root, "HeritageRoof", Vector3(0.0, 6.4, 0.0), Vector3(18.0, 0.8, 14.0), stone, 0.0)


func _build_point_historic_fortification(root: Node3D, stone: Material, accent: Material) -> void:
	for x_side in [-1.0, 1.0]:
		for z_side in [-1.0, 1.0]:
			_add_archaeology_box(root, "FortressCornerTower_%s_%s" % [str(x_side), str(z_side)], Vector3(x_side * 8.0, 4.0, z_side * 8.0), Vector3(4.0, 8.0, 4.0), accent, 0.0)
	_add_archaeology_box(root, "FortressNorthWall", Vector3(0.0, 2.2, -8.0), Vector3(14.0, 4.4, 1.2), stone, 0.0)
	_add_archaeology_box(root, "FortressSouthWall", Vector3(0.0, 2.2, 8.0), Vector3(14.0, 4.4, 1.2), stone, 0.0)
	_add_archaeology_box(root, "FortressWestWall", Vector3(-8.0, 2.2, 0.0), Vector3(1.2, 4.4, 14.0), stone, 0.0)
	_add_archaeology_box(root, "FortressEastWall", Vector3(8.0, 2.2, 0.0), Vector3(1.2, 4.4, 14.0), stone, 0.0)


func _build_point_historic_gate(root: Node3D, stone: Material, accent: Material) -> void:
	_add_archaeology_box(root, "HistoricGateLeftPillar", Vector3(-5.0, 4.0, 0.0), Vector3(2.0, 8.0, 2.0), stone, 0.0)
	_add_archaeology_box(root, "HistoricGateRightPillar", Vector3(5.0, 4.0, 0.0), Vector3(2.0, 8.0, 2.0), stone, 0.0)
	_add_archaeology_box(root, "HistoricGateHeader", Vector3(0.0, 8.0, 0.0), Vector3(12.0, 2.0, 2.0), accent, 0.0)


func _build_point_archaeological_ruins(root: Node3D, feature_id: String, stone: Material, worn_stone: Material) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(feature_id.hash())
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var radius := 8.0 + rng.randf_range(-1.2, 1.2)
		var wall_height := rng.randf_range(1.1, 2.8)
		var wall_length := rng.randf_range(3.0, 5.5)
		var wall_position := Vector3(cos(angle) * radius, wall_height * 0.5, sin(angle) * radius)
		_add_archaeology_box(root, "BrokenWall_%02d" % index, wall_position, Vector3(wall_length, wall_height, 0.9), worn_stone, angle)
	for index in range(4):
		var angle := TAU * float(index) / 4.0 + 0.35
		var pillar_height := rng.randf_range(2.2, 5.0)
		var pillar := StaticBody3D.new()
		pillar.name = "RuinedColumn_%02d" % index
		pillar.position = Vector3(cos(angle) * 5.8, pillar_height * 0.5, sin(angle) * 5.8)
		var visual := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.42
		cylinder.bottom_radius = 0.58
		cylinder.height = pillar_height
		visual.mesh = cylinder
		visual.material_override = stone
		pillar.add_child(visual)
		var collision := CollisionShape3D.new()
		var cylinder_shape := CylinderShape3D.new()
		cylinder_shape.radius = 0.58
		cylinder_shape.height = pillar_height
		collision.shape = cylinder_shape
		pillar.add_child(collision)
		root.add_child(pillar)


func _add_historic_polygon_landmark(parent: Node3D, ring: PackedVector2Array, height: float, feature_id: String, tags: Dictionary, landmark_kind: String) -> Node3D:
	if ring.size() < 3:
		return null
	var center := Vector2.ZERO
	for point in ring:
		center += point
	center /= float(ring.size())
	var root := Node3D.new()
	root.name = "OSMHistoricLandmarkDetail_%s" % feature_id
	root.position = Vector3(center.x, _terrain_height(center), center.y)
	root.set_meta("landmark_type", landmark_kind)
	root.set_meta("osm_feature_id", feature_id)
	root.set_meta("osm_historic_tag", str(tags.get("historic", "")))
	parent.add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.55, 0.43, 0.30)
	stone.roughness = 0.94
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(0.39, 0.32, 0.25)
	accent.roughness = 0.98
	match landmark_kind:
		"historic_monument":
			_build_point_historic_monument(root, tags, stone, accent)
		"historic_tomb":
			_build_point_historic_tomb(root, stone, accent)
		"historic_building":
			_build_point_historic_building(root, stone, accent)
		"historic_fortification":
			_build_point_historic_fortification(root, stone, accent)
		"historic_gate":
			_build_point_historic_gate(root, stone, accent)
		_:
			_build_point_archaeological_ruins(root, feature_id, stone, accent)
	var label := Label3D.new()
	label.name = "HistoricLandmarkLabel"
	label.text = str(tags.get("name:ar", tags.get("name", "معلم تاريخي موثق")))
	label.font_size = 20
	label.position = Vector3(0.0, maxf(height, 7.0) + 2.0, 0.0)
	label.modulate = Color(0.9, 0.78, 0.57)
	root.add_child(label)
	return root




func _add_archaeological_site_interaction(root: Node3D, feature_id: String, tags: Dictionary) -> void:
	var site_name := str(tags.get("name:ar", tags.get("name", "موقع أثري موثق")))
	var historic_kind := str(tags.get("historic", tags.get("site_type", "archaeological_site")))
	var interaction := Area3D.new()
	interaction.name = "ArchaeologicalSiteInteraction"
	interaction.add_to_group("system_interactable")
	interaction.set_meta("osm_feature_id", feature_id)
	interaction.set_meta("system_location_id", "baghdad_osm_historic_" + feature_id)
	interaction.set_meta("system_region_id", "region_baghdad")
	interaction.set_meta("system_location_type", 7)
	interaction.set_meta("system_fast_travel", false)
	interaction.set_meta("system_location_position", root.position)
	interaction.set_meta("system_display_name", site_name)
	interaction.set_meta("system_interaction_prompt", "استكشاف معلم تاريخي موثق — فحص معلومات الموقع")
	interaction.set_meta("system_historic_tag", historic_kind)
	interaction.set_meta("system_access_state", "historic_landmark_discovery")
	var area_collision := CollisionShape3D.new()
	var area_shape := SphereShape3D.new()
	area_shape.radius = 5.5
	area_collision.shape = area_shape
	interaction.add_child(area_collision)
	root.add_child(interaction)


func _add_archaeological_ruin_detail(parent: Node3D, ring: PackedVector2Array, height: float, feature_id: String, tags: Dictionary) -> Node3D:
	if ring.size() < 3:
		return null
	var center := Vector2.ZERO
	for point in ring:
		center += point
	center /= float(ring.size())
	var root := Node3D.new()
	root.name = "OSMArchaeologicalRuinDetail_%s" % feature_id
	root.position = Vector3(center.x, _terrain_height(center), center.y)
	root.set_meta("landmark_type", _historic_landmark_kind(tags))
	root.set_meta("osm_feature_id", feature_id)
	root.set_meta("osm_historic_tag", str(tags.get("historic", tags.get("building", "ruins"))))
	parent.add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.48, 0.38, 0.28)
	stone.roughness = 0.98
	for index in range(mini(ring.size(), 8)):
		if index % 3 == 1:
			continue
		var p0: Vector2 = ring[index]
		var p1: Vector2 = ring[(index + 1) % ring.size()]
		var direction := p1 - p0
		var length := direction.length()
		if length < 2.0:
			continue
		var midpoint := (p0 + p1) * 0.5
		var wall_height := minf(2.8, maxf(1.1, height * (0.35 + float(index % 3) * 0.12)))
		var local_position := Vector3(midpoint.x - center.x, _terrain_height(midpoint) - _terrain_height(center) + wall_height * 0.5, midpoint.y - center.y)
		_add_archaeology_box(root, "BrokenRuinWall_%02d" % index, local_position, Vector3(length, wall_height, 0.75), stone, atan2(-direction.y, direction.x))
	var site_label := Label3D.new()
	site_label.name = "ArchaeologicalRuinLabel"
	site_label.text = str(tags.get("name:ar", tags.get("name", "أطلال أثرية موثقة")))
	site_label.font_size = 20
	site_label.position = Vector3(0.0, 5.0, 0.0)
	site_label.modulate = Color(0.9, 0.78, 0.57)
	root.add_child(site_label)
	return root


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
	var historic_kind := _historic_landmark_kind(tags)
	match historic_kind:
		"archaeological_ruin":
			return 2.8
		"archaeological_site":
			return 4.0
		"historic_monument":
			return 9.0
		"historic_tomb":
			return 8.0
		"historic_fortification":
			return 12.0
		"historic_gate":
			return 10.0
		"historic_building":
			return 8.0
	var kind := str(tags.get("building", "yes")).to_lower()
	if kind in ["house", "detached", "semidetached_house", "bungalow", "terrace"]:
		return 6.5
	if kind in ["apartments", "residential", "dormitory"]:
		return 16.0
	if kind in ["commercial", "office", "retail"]:
		return 12.0
	return 6.0


func _building_kind(tags: Dictionary) -> String:
	var kind := str(tags.get("building", "yes")).to_lower()
	if kind == "mosque" or (str(tags.get("amenity", "")) == "place_of_worship" and str(tags.get("religion", "")).to_lower() == "muslim"):
		return "mosque"
	if kind == "church" or (str(tags.get("amenity", "")) == "place_of_worship" and str(tags.get("religion", "")).to_lower() == "christian"):
		return "church"
	var historic_kind := _historic_landmark_kind(tags)
	if not historic_kind.is_empty():
		return historic_kind
	if kind in ["house", "detached", "semidetached_house", "bungalow", "terrace"]:
		return "detached_house"
	if kind in ["apartments", "residential", "dormitory"]:
		return "apartment_block"
	if kind in ["commercial", "office", "retail", "industrial"]:
		return "commercial_building"
	return "general_building"


func _building_material_for(kind: String) -> StandardMaterial3D:
	var material := building_material.duplicate() as StandardMaterial3D
	match kind:
		"detached_house":
			material.albedo_color = Color(0.68, 0.55, 0.40)
		"apartment_block":
			material.albedo_color = Color(0.62, 0.63, 0.60)
		"commercial_building":
			material.albedo_color = Color(0.43, 0.51, 0.56)
		"mosque":
			material.albedo_color = Color(0.72, 0.67, 0.52)
		"church":
			material.albedo_color = Color(0.70, 0.63, 0.52)
		"archaeological_ruin", "archaeological_site":
			material.albedo_color = Color(0.48, 0.38, 0.28)
		"historic_monument":
			material.albedo_color = Color(0.61, 0.54, 0.45)
		"historic_tomb":
			material.albedo_color = Color(0.66, 0.57, 0.43)
		"historic_building":
			material.albedo_color = Color(0.59, 0.44, 0.29)
		"historic_fortification":
			material.albedo_color = Color(0.45, 0.36, 0.27)
		"historic_gate":
			material.albedo_color = Color(0.57, 0.45, 0.31)
	return material


func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _unload_cell(cell: Vector2i) -> void:
	if not loaded_cells.has(cell):
		return
	var node: Node3D = loaded_cells[cell]
	var cell_id := str(node.get_meta("cell_id", "%d:%d" % [cell.x, cell.y]))
	cell_unloading.emit(cell, node)
	loaded_cells.erase(cell)
	_road_navigation_graph_dirty = true
	_vehicle_navigation_graph_dirty = true
	cell_unloaded.emit(cell, cell_id)
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
		"manifest_schema_version": manifest_schema_version,
		"source_snapshot": source_snapshot,
		"canonical_origin_frame_valid": canonical_origin_frame_valid,
		"road_navigation_graph_dirty": _road_navigation_graph_dirty,
		"road_navigation_node_count": _road_navigation_graph.get_point_count(),
		"road_navigation_graph_build_count": _road_navigation_graph_build_count,
		"vehicle_navigation_graph_dirty": _vehicle_navigation_graph_dirty,
		"vehicle_navigation_node_count": _vehicle_navigation_graph.get_point_count(),
		"vehicle_navigation_graph_build_count": _vehicle_navigation_graph_build_count
	}
