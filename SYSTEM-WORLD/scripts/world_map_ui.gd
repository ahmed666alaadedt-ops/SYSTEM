
extends CanvasLayer

const WORLD_NAMES := {
	0: "العالم الخيالي",
	1: "العالم التاريخي",
	2: "العالم الحديث",
	3: "جزيرة الطمع"
}

const LOCATION_TYPES := {
	0: "مدينة",
	1: "قرية",
	2: "مستشفى",
	3: "عيادة",
	4: "متجر",
	5: "مَعْلَم",
	6: "نقطة سفر",
	7: "موقع آخر"
}


class MapDrawing extends Control:

	var discovered_locations: Array = []
	var personal_markers: Array = []
	var world_overview: Dictionary = {}
	var player_position := Vector3.ZERO
	var player_visible := false
	var road_segments: Array = []
	var navigation_route: Array[Vector3] = []
	var navigation_destination := Vector3.ZERO
	var navigation_destination_visible := false
	var navigation_focus := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x < 50.0 or size.y < 50.0:
			return

		var background := Color(0.025, 0.045, 0.075)
		draw_rect(Rect2(Vector2.ZERO, size), background, true)

		var map_rect := Rect2(
			Vector2(25, 25),
			size - Vector2(50, 50)
		)

		_draw_grid(map_rect)

		var all_positions: Array[Vector3] = []
		if not navigation_focus:
			for city in world_overview.get("cities", []):
				if typeof(city) == TYPE_DICTIONARY and city.get("position") is Vector3:
					all_positions.append(city["position"])
			for village in world_overview.get("villages", []):
				if typeof(village) == TYPE_DICTIONARY and village.get("position") is Vector3:
					all_positions.append(village["position"])
		for segment_value in road_segments:
			if not segment_value is Dictionary:
				continue
			var segment_points: Variant = segment_value.get("points", PackedVector2Array())
			if segment_points is PackedVector2Array:
				for road_point in segment_points:
					all_positions.append(Vector3(road_point.x, 0.0, road_point.y))
		for route_point in navigation_route:
			all_positions.append(route_point)
		if navigation_destination_visible:
			all_positions.append(navigation_destination)

		for item in discovered_locations:
			if typeof(item) != TYPE_DICTIONARY:
				continue

			var position: Variant = item.get("position", Vector3.ZERO)
			if position is Vector3:
				all_positions.append(position)

		for marker in personal_markers:
			if typeof(marker) != TYPE_DICTIONARY:
				continue

			var position: Variant = marker.get("position", Vector3.ZERO)
			if position is Vector3:
				all_positions.append(position)

		if player_visible:
			all_positions.append(player_position)

		if all_positions.is_empty():
			draw_string(
				ThemeDB.fallback_font,
				map_rect.get_center() + Vector2(-130, 0),
				"استكشف العالم لاكتشاف المواقع",
				HORIZONTAL_ALIGNMENT_LEFT,
				260,
				18,
				Color(0.55, 0.72, 0.88)
			)
			return

		var min_x := all_positions[0].x
		var max_x := all_positions[0].x
		var min_z := all_positions[0].z
		var max_z := all_positions[0].z

		for position in all_positions:
			min_x = minf(min_x, position.x)
			max_x = maxf(max_x, position.x)
			min_z = minf(min_z, position.z)
			max_z = maxf(max_z, position.z)

		if max_x - min_x < 20.0:
			min_x -= 10.0
			max_x += 10.0

		if max_z - min_z < 20.0:
			min_z -= 10.0
			max_z += 10.0

		if not navigation_focus:
			_draw_world_overview(map_rect, min_x, max_x, min_z, max_z)

		for segment_value in road_segments:
			if not segment_value is Dictionary:
				continue
			var segment_points: Variant = segment_value.get("points", PackedVector2Array())
			if not segment_points is PackedVector2Array or segment_points.size() < 2:
				continue
			var projected_road := PackedVector2Array()
			for road_point in segment_points:
				projected_road.append(_project_position(
					Vector3(road_point.x, 0.0, road_point.y),
					map_rect, min_x, max_x, min_z, max_z
				))
			if projected_road.size() >= 2:
				draw_polyline(projected_road, Color(0.43, 0.55, 0.62, 0.82), 1.35, true)

		if navigation_route.size() >= 2:
			var projected_route := PackedVector2Array()
			for route_point in navigation_route:
				projected_route.append(_project_position(
					route_point, map_rect, min_x, max_x, min_z, max_z
				))
			draw_polyline(projected_route, Color(0.015, 0.06, 0.09, 0.96), 7.0, true)
			draw_polyline(projected_route, Color(0.10, 0.91, 1.0, 1.0), 4.0, true)
			for route_index in range(1, projected_route.size() - 1):
				draw_circle(projected_route[route_index], 2.2, Color(0.88, 0.98, 1.0, 0.95))

		if navigation_destination_visible:
			var destination_point := _project_position(
				navigation_destination, map_rect, min_x, max_x, min_z, max_z
			)
			draw_circle(destination_point, 9.0, Color(1.0, 0.58, 0.18, 1.0))
			draw_arc(destination_point, 15.0, 0.0, TAU, 32, Color(1.0, 0.78, 0.35, 0.95), 2.5)
			draw_string(ThemeDB.fallback_font, destination_point + Vector2(12, 18), "الوجهة", HORIZONTAL_ALIGNMENT_LEFT, 80, 12, Color(1.0, 0.84, 0.56))

		for item in discovered_locations:
			if typeof(item) != TYPE_DICTIONARY:
				continue

			var position: Variant = item.get("position", Vector3.ZERO)
			if not position is Vector3:
				continue

			var point := _project_position(
				position,
				map_rect,
				min_x,
				max_x,
				min_z,
				max_z
			)

			var activated := bool(
				item.get("is_fast_travel_activated", false)
			)

			var point_color := (
				Color(0.25, 0.95, 0.85)
				if activated
				else Color(0.15, 0.65, 1.0)
			)

			draw_circle(point, 8.0, point_color)
			draw_arc(
				point,
				13.0,
				0.0,
				TAU,
				32,
				Color(point_color.r, point_color.g, point_color.b, 0.7),
				2.0
			)

			var location_name := str(item.get("name", "موقع"))
			draw_string(
				ThemeDB.fallback_font,
				point + Vector2(12, -10),
				location_name,
				HORIZONTAL_ALIGNMENT_LEFT,
				180,
				13,
				Color(0.88, 0.94, 1.0)
			)

		for marker in personal_markers:
			if typeof(marker) != TYPE_DICTIONARY:
				continue

			var position: Variant = marker.get("position", Vector3.ZERO)
			if not position is Vector3:
				continue

			var point := _project_position(
				position,
				map_rect,
				min_x,
				max_x,
				min_z,
				max_z
			)

			var diamond := PackedVector2Array([
				point + Vector2(0, -10),
				point + Vector2(10, 0),
				point + Vector2(0, 10),
				point + Vector2(-10, 0)
			])

			draw_colored_polygon(
				diamond,
				Color(1.0, 0.72, 0.20)
			)

			draw_string(
				ThemeDB.fallback_font,
				point + Vector2(13, 18),
				str(marker.get("label", "علامة")),
				HORIZONTAL_ALIGNMENT_LEFT,
				150,
				12,
				Color(1.0, 0.82, 0.48)
			)

		if player_visible:
			var player_point := _project_position(
				player_position,
				map_rect,
				min_x,
				max_x,
				min_z,
				max_z
			)

			draw_circle(
				player_point,
				10.0,
				Color(0.25, 0.95, 0.45)
			)

			draw_arc(
				player_point,
				17.0,
				0.0,
				TAU,
				40,
				Color(0.25, 0.95, 0.45),
				2.5
			)

			draw_string(
				ThemeDB.fallback_font,
				player_point + Vector2(14, -14),
				"أنت هنا",
				HORIZONTAL_ALIGNMENT_LEFT,
				100,
				14,
				Color(0.45, 1.0, 0.58)
			)

	func _draw_grid(rect: Rect2) -> void:
		var grid_color := Color(0.10, 0.22, 0.32, 0.55)

		for i in range(1, 8):
			var x := rect.position.x + rect.size.x * float(i) / 8.0
			draw_line(
				Vector2(x, rect.position.y),
				Vector2(x, rect.end.y),
				grid_color,
				1.0
			)

		for i in range(1, 6):
			var y := rect.position.y + rect.size.y * float(i) / 6.0
			draw_line(
				Vector2(rect.position.x, y),
				Vector2(rect.end.x, y),
				grid_color,
				1.0
			)

		draw_rect(
			rect,
			Color(0.12, 0.48, 0.72, 0.8),
			false,
			2.0
		)

	func _project_position(
		position: Vector3,
		rect: Rect2,
		min_x: float,
		max_x: float,
		min_z: float,
		max_z: float
	) -> Vector2:
		var x_ratio := clampf(
			(position.x - min_x) / maxf(max_x - min_x, 0.1),
			0.0,
			1.0
		)

		var z_ratio := clampf(
			(position.z - min_z) / maxf(max_z - min_z, 0.1),
			0.0,
			1.0
		)

		return Vector2(
			rect.position.x + x_ratio * rect.size.x,
			rect.position.y + z_ratio * rect.size.y
		)



	func _draw_world_overview(rect: Rect2, min_x: float, max_x: float, min_z: float, max_z: float) -> void:
		var land := PackedVector2Array()
		var coast := PackedVector2Array()
		var center := rect.get_center()
		var radius_x := rect.size.x * 0.455
		var radius_y := rect.size.y * 0.435
		for index in range(80):
			var angle := TAU * float(index) / 80.0
			var wobble := 1.0 + 0.035 * sin(angle * 5.0) + 0.018 * cos(angle * 9.0)
			var point := center + Vector2(cos(angle) * radius_x * wobble, sin(angle) * radius_y * wobble)
			land.append(point)
			coast.append(point)
		draw_colored_polygon(land, Color(0.13, 0.20, 0.17, 0.96))
		draw_polyline(coast, Color(0.48, 0.62, 0.48, 0.95), 2.2, true)

		var cities: Array = world_overview.get("cities", [])
		var city_points: Array[Vector2] = []
		var city_point_names: Array[String] = []
		for city in cities:
			if typeof(city) != TYPE_DICTIONARY or not (city.get("position") is Vector3):
				continue
			city_points.append(_project_position(city["position"], rect, min_x, max_x, min_z, max_z))
			city_point_names.append(str(city.get("name", "City")))

		if city_points.size() > 1:
			var connected: Array[int] = [0]
			while connected.size() < city_points.size():
				var best_distance := INF
				var best_from := -1
				var best_to := -1
				for from_index in connected:
					for to_index in range(city_points.size()):
						if connected.has(to_index):
							continue
						var distance := city_points[from_index].distance_to(city_points[to_index])
						if distance < best_distance:
							best_distance = distance
							best_from = from_index
							best_to = to_index
				if best_from < 0 or best_to < 0:
					break
				draw_line(city_points[best_from], city_points[best_to], Color(0.72, 0.66, 0.48, 0.8), 3.0, true)
				draw_line(city_points[best_from], city_points[best_to], Color(0.20, 0.24, 0.22, 0.95), 1.0, true)
				connected.append(best_to)

		for village in world_overview.get("villages", []):
			if typeof(village) != TYPE_DICTIONARY or not (village.get("position") is Vector3):
				continue
			var village_point := _project_position(village["position"], rect, min_x, max_x, min_z, max_z)
			draw_circle(village_point, 3.0, Color(0.78, 0.72, 0.52, 0.9))

		for city_index in range(city_points.size()):
			var point := city_points[city_index]
			draw_circle(point, 5.0, Color(0.92, 0.78, 0.42))
			draw_arc(point, 8.0, 0.0, TAU, 24, Color(0.95, 0.86, 0.62, 0.8), 1.2)
			draw_string(ThemeDB.fallback_font, point + Vector2(8, -7), city_point_names[city_index], HORIZONTAL_ALIGNMENT_LEFT, 110, 10, Color(0.92, 0.94, 0.86))

		for incident in world_overview.get("incidents", []):
			if typeof(incident) != TYPE_DICTIONARY or not (incident.get("position") is Vector3):
				continue
			var incident_point := _project_position(incident["position"], rect, min_x, max_x, min_z, max_z)
			draw_circle(incident_point, 5.5, Color(1.0, 0.22, 0.12))
			draw_arc(incident_point, 9.0, 0.0, TAU, 20, Color(1.0, 0.42, 0.18), 1.5)


var map_manager: Node
var world_manager: Node
var player: CharacterBody3D
var navigation_manager: Node
var navigation_status_label: Label
var clear_navigation_button: Button

var selected_world_id := 2

var open_button: Button
var blocker: ColorRect
var map_panel: PanelContainer
var map_canvas: MapDrawing
var location_list: VBoxContainer
var statistics_label: Label
var marker_button: Button
var tab_buttons: Dictionary = {}


func setup(
	p_map_manager: Node,
	p_world_manager: Node,
	p_player: CharacterBody3D,
	p_navigation_manager: Node = null
) -> void:
	map_manager = p_map_manager
	world_manager = p_world_manager
	player = p_player
	navigation_manager = p_navigation_manager

	_build_interface()

	if map_manager != null:
		map_manager.connect("map_updated", _on_map_updated)

	if world_manager != null:
		world_manager.connect("world_changed", _on_world_changed)

	_sync_current_world()
	_refresh_map()


func _ready() -> void:
	layer = 20


func _build_interface() -> void:
	open_button = Button.new()
	open_button.name = "OpenWorldMapButton"
	open_button.text = "الخريطة"
	open_button.position = Vector2(22, 22)
	open_button.custom_minimum_size = Vector2(125, 48)
	open_button.add_theme_font_size_override("font_size", 19)
	open_button.pressed.connect(_open_map)
	add_child(open_button)

	blocker = ColorRect.new()
	blocker.name = "MapScreenBlocker"
	blocker.color = Color(0.005, 0.012, 0.025, 0.82)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.visible = false
	add_child(blocker)

	map_panel = PanelContainer.new()
	map_panel.name = "WorldMapPanel"
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_panel.offset_left = 42
	map_panel.offset_top = 35
	map_panel.offset_right = -42
	map_panel.offset_bottom = -35

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.075, 0.98)
	panel_style.border_color = Color(0.12, 0.55, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12

	map_panel.add_theme_stylebox_override("panel", panel_style)
	map_panel.visible = false
	add_child(map_panel)

	var main_column := VBoxContainer.new()
	main_column.add_theme_constant_override("separation", 10)
	map_panel.add_child(main_column)

	_build_header(main_column)
	_build_world_tabs(main_column)
	_build_map_body(main_column)


func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	parent.add_child(header)

	var title := Label.new()
	title.text = "SYSTEM  |  خريطة العالم"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override(
		"font_color",
		Color(0.45, 0.82, 1.0)
	)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.custom_minimum_size = Vector2(90, 42)
	close_button.pressed.connect(_close_map)
	header.add_child(close_button)


func _build_world_tabs(parent: VBoxContainer) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	parent.add_child(tabs)

	for world_id in [2, 1, 0, 3]:
		var button := Button.new()
		button.text = WORLD_NAMES[world_id]
		button.custom_minimum_size = Vector2(135, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(
			_on_world_tab_pressed.bind(world_id)
		)

		tab_buttons[world_id] = button
		tabs.add_child(button)


func _build_map_body(parent: VBoxContainer) -> void:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	parent.add_child(body)

	map_canvas = MapDrawing.new()
	map_canvas.name = "WorldMapDrawing"
	map_canvas.custom_minimum_size = Vector2(420, 300)
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(map_canvas)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(270, 0)
	body.add_child(side_panel)

	var side_column := VBoxContainer.new()
	side_column.add_theme_constant_override("separation", 8)
	side_panel.add_child(side_column)

	var side_title := Label.new()
	side_title.text = "المواقع المكتشفة"
	side_title.add_theme_font_size_override("font_size", 18)
	side_title.add_theme_color_override(
		"font_color",
		Color(0.55, 0.85, 1.0)
	)
	side_column.add_child(side_title)

	statistics_label = Label.new()
	statistics_label.add_theme_color_override(
		"font_color",
		Color(0.72, 0.82, 0.92)
	)
	side_column.add_child(statistics_label)

	navigation_status_label = Label.new()
	navigation_status_label.text = "اختر موقعاً مكتشفاً لرسم طريق المشاة."
	navigation_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	navigation_status_label.add_theme_color_override("font_color", Color(0.48, 0.86, 0.96))
	side_column.add_child(navigation_status_label)

	clear_navigation_button = Button.new()
	clear_navigation_button.text = "إلغاء مسار الملاحة"
	clear_navigation_button.custom_minimum_size = Vector2(0, 36)
	clear_navigation_button.visible = false
	clear_navigation_button.pressed.connect(_clear_navigation_route)
	side_column.add_child(clear_navigation_button)

	marker_button = Button.new()
	marker_button.text = "＋ أضف علامة هنا"
	marker_button.custom_minimum_size = Vector2(0, 42)
	marker_button.pressed.connect(_add_player_marker)
	side_column.add_child(marker_button)

	var separator := HSeparator.new()
	side_column.add_child(separator)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_column.add_child(scroll)

	location_list = VBoxContainer.new()
	location_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location_list.add_theme_constant_override("separation", 7)
	scroll.add_child(location_list)


func _open_map() -> void:
	_sync_current_world()
	blocker.visible = true
	map_panel.visible = true
	open_button.visible = false
	_refresh_map()


func _close_map() -> void:
	map_panel.visible = false
	blocker.visible = false
	open_button.visible = true


func _sync_current_world() -> void:
	if world_manager == null:
		return

	var active_id: Variant = world_manager.get("active_world")

	if active_id != null:
		selected_world_id = int(active_id)


func _on_world_tab_pressed(world_id: int) -> void:
	selected_world_id = world_id
	_refresh_map()


func _on_world_changed(world_id: int) -> void:
	selected_world_id = world_id
	_refresh_map()


func _on_map_updated(world_id: String) -> void:
	if world_id == str(selected_world_id):
		_refresh_map()


func _refresh_map() -> void:
	if map_manager == null or map_canvas == null:
		return

	var snapshot: Dictionary = map_manager.call(
		"get_map_snapshot",
		str(selected_world_id)
	)
	map_canvas.world_overview = {}
	map_canvas.road_segments.clear()
	if selected_world_id == 2 and world_manager != null and world_manager.has_method("get_world_root"):
		var modern_root := world_manager.call("get_world_root", 2) as Node3D
		if modern_root != null:
			var region := modern_root.get_node_or_null("ModernWorldRegionManager")
			if region != null and region.has_method("get_map_overview"):
				map_canvas.world_overview = region.call("get_map_overview")
			var osm_streamer := modern_root.find_child("BaghdadOSMCellStreamer", true, false)
			if is_instance_valid(osm_streamer) and osm_streamer.has_method("get_loaded_road_map_segments"):
				map_canvas.road_segments = osm_streamer.call("get_loaded_road_map_segments")
	map_canvas.navigation_focus = not map_canvas.road_segments.is_empty()

	map_canvas.discovered_locations = snapshot.get(
		"discovered_locations",
		[]
	)

	map_canvas.personal_markers = snapshot.get(
		"personal_markers",
		[]
	)

	map_canvas.player_visible = false
	if selected_world_id != 2:
		map_canvas.navigation_route.clear()
		map_canvas.navigation_destination_visible = false
		map_canvas.navigation_focus = false
		if navigation_status_label != null:
			navigation_status_label.text = "الملاحة بالطرق الحقيقية متاحة حالياً في بغداد فقط."
		if clear_navigation_button != null:
			clear_navigation_button.visible = false

	if world_manager != null and player != null:
		var active_id: Variant = world_manager.get("active_world")

		if active_id != null and int(active_id) == selected_world_id:
			map_canvas.player_position = player.global_position
			map_canvas.player_visible = true

	map_canvas.queue_redraw()
	if clear_navigation_button != null:
		clear_navigation_button.visible = not map_canvas.navigation_route.is_empty()

	var regions: Array = snapshot.get("discovered_regions", [])
	var locations: Array = snapshot.get("discovered_locations", [])
	var markers: Array = snapshot.get("personal_markers", [])

	statistics_label.text = (
		"المناطق المكتشفة: %d\nالمواقع المكتشفة: %d\nعلاماتك الشخصية: %d"
		% [regions.size(), locations.size(), markers.size()]
	)

	for child in location_list.get_children():
		location_list.remove_child(child)
		child.queue_free()

	if locations.is_empty():
		_add_list_label("لم تكتشف مواقع في هذا العالم بعد.")
	else:
		for item in locations:
			if typeof(item) == TYPE_DICTIONARY:
				_add_location_entry(item)

	if not markers.is_empty():
		_add_list_label("علاماتك الشخصية")

		for marker in markers:
			if typeof(marker) == TYPE_DICTIONARY:
				var marker_name := str(
					marker.get("label", "علامة شخصية")
				)
				_add_list_label("◆ " + marker_name)

	marker_button.disabled = (
		player == null
		or world_manager == null
		or int(world_manager.get("active_world")) != selected_world_id
	)


func _add_location_entry(item: Dictionary) -> void:
	var location_name := str(item.get("name", "موقع"))
	var location_type := int(item.get("type", 7))
	var type_name := str(LOCATION_TYPES.get(location_type, "موقع"))
	var status := ""
	if bool(item.get("is_fast_travel_activated", false)):
		status = "\n✓ نقطة سفر سريع مفعّلة"

	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 3)
	location_list.add_child(entry)

	var label := Label.new()
	label.text = "● %s\n%s%s" % [location_name, type_name, status]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0))
	entry.add_child(label)

	var region_id := str(item.get("region_id", "")).to_lower()
	if selected_world_id == 2 and region_id in ["region_baghdad", "iraq_baghdad_region"]:
		var route_button := Button.new()
		route_button.text = "ارسم الطريق إلى هذا الموقع"
		route_button.custom_minimum_size = Vector2(0, 34)
		route_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route_button.pressed.connect(_request_navigation_to_location.bind(item.duplicate(true)))
		entry.add_child(route_button)


func _request_navigation_to_location(item: Dictionary) -> void:
	if selected_world_id != 2 or world_manager == null or player == null:
		return
	if int(world_manager.get("active_world")) != selected_world_id:
		navigation_status_label.text = "ادخل العالم الحديث أولاً حتى نحدد موقعك الحالي."
		return
	if not is_instance_valid(navigation_manager) or not navigation_manager.has_method("find_real_baghdad_road_path"):
		navigation_status_label.text = "مدير الملاحة غير جاهز حالياً."
		return
	var destination_value: Variant = item.get("position", null)
	if not destination_value is Vector3:
		navigation_status_label.text = "إحداثيات الوجهة غير متاحة."
		return
	var destination: Vector3 = destination_value
	var route_value: Variant = navigation_manager.call(
		"find_real_baghdad_road_path",
		"Baghdad",
		player.global_position,
		destination
	)
	if not route_value is Array or route_value.size() < 2:
		map_canvas.navigation_route.clear()
		map_canvas.navigation_destination_visible = false
		map_canvas.queue_redraw()
		navigation_status_label.text = "لم نعثر على طريق مشاة متصل ضمن خلايا الطرق المحمّلة. اقترب من المنطقة أو انتظر تحميل خلاياها."
		clear_navigation_button.visible = false
		return
	map_canvas.navigation_route.clear()
	for point in route_value:
		if point is Vector3:
			map_canvas.navigation_route.append(point)
	if map_canvas.navigation_route.size() < 2:
		navigation_status_label.text = "بيانات الطريق غير مكتملة؛ لم نعرض مساراً تخمينياً."
		return
	map_canvas.navigation_destination = destination
	map_canvas.navigation_destination_visible = true
	map_canvas.navigation_focus = true
	map_canvas.queue_redraw()
	var distance_m := 0.0
	for index in range(1, map_canvas.navigation_route.size()):
		distance_m += map_canvas.navigation_route[index - 1].distance_to(map_canvas.navigation_route[index])
	navigation_status_label.text = "مسار مشاة عبر طرق OpenStreetMap المحمّلة · %s · %d نقطة" % [
		"%.0f م" % distance_m if distance_m < 1000.0 else "%.2f كم" % (distance_m / 1000.0),
		map_canvas.navigation_route.size()
	]
	clear_navigation_button.visible = true


func _clear_navigation_route() -> void:
	if map_canvas == null:
		return
	map_canvas.navigation_route.clear()
	map_canvas.navigation_destination_visible = false
	map_canvas.navigation_focus = not map_canvas.road_segments.is_empty()
	map_canvas.queue_redraw()
	if navigation_status_label != null:
		navigation_status_label.text = "اختر موقعاً مكتشفاً لرسم طريق المشاة."
	if clear_navigation_button != null:
		clear_navigation_button.visible = false


func _add_list_label(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_color_override(
		"font_color",
		Color(0.62, 0.75, 0.88)
	)
	location_list.add_child(label)


func _add_player_marker() -> void:
	if map_manager == null or player == null:
		return

	if world_manager == null:
		return

	var active_id: Variant = world_manager.get("active_world")

	if active_id == null or int(active_id) != selected_world_id:
		return

	var marker_id := "personal_%s" % str(Time.get_ticks_msec())

	var added: bool = map_manager.call(
		"add_personal_marker",
		str(selected_world_id),
		marker_id,
		"علامة شخصية",
		player.global_position,
		"علامة أضفتها من الخريطة"
	)

	if added:
		_refresh_map()
