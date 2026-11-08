
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
	2: "مَعْلَم",
	3: "مستشفى",
	4: "عيادة",
	5: "متجر",
	6: "نقطة سفر",
	7: "موقع استكشاف"
}


class MapDrawing extends Control:

	var discovered_locations: Array = []
	var personal_markers: Array = []
	var player_position := Vector3.ZERO
	var player_visible := false

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


var map_manager: Node
var world_manager: Node
var player: CharacterBody3D

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
	p_player: CharacterBody3D
) -> void:
	map_manager = p_map_manager
	world_manager = p_world_manager
	player = p_player

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

	map_canvas.discovered_locations = snapshot.get(
		"discovered_locations",
		[]
	)

	map_canvas.personal_markers = snapshot.get(
		"personal_markers",
		[]
	)

	map_canvas.player_visible = false

	if world_manager != null and player != null:
		var active_id: Variant = world_manager.get("active_world")

		if active_id != null and int(active_id) == selected_world_id:
			map_canvas.player_position = player.global_position
			map_canvas.player_visible = true

	map_canvas.queue_redraw()

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

	var type_name := str(
		LOCATION_TYPES.get(location_type, "موقع")
	)

	var status := ""

	if bool(item.get("is_fast_travel_activated", false)):
		status = "\n✓ نقطة سفر سريع مفعّلة"

	var label := Label.new()
	label.text = "● %s\n%s%s" % [
		location_name,
		type_name,
		status
	]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_color_override(
		"font_color",
		Color(0.78, 0.88, 1.0)
	)

	location_list.add_child(label)


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
