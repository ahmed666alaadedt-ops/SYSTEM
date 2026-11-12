
extends Node

# SYSTEM WORLD - COMMAND CENTER MAP PANEL
# Godot 4.3

const WORLD_NAMES := {
	"modern": "العالم الحديث",
	"history": "العالم التاريخي",
	"fantasy": "العالم الخيالي",
	"greed": "جزيرة الطمع"
}

const WORLD_COLORS := {
	"modern": Color(0.05, 0.75, 1.0),
	"history": Color(0.95, 0.65, 0.25),
	"fantasy": Color(0.70, 0.35, 1.0),
	"greed": Color(0.25, 0.95, 0.65)
}


class MapCanvas extends Control:

	var world_id := "modern"

	func set_world(value: String) -> void:
		world_id = value
		queue_redraw()

	func _draw() -> void:
		var area := Rect2(Vector2.ZERO, size)

		draw_rect(area, Color(0.015, 0.035, 0.065), true)

		for x in range(0, int(size.x), 38):
			draw_line(
				Vector2(x, 0),
				Vector2(x, size.y),
				Color(0.08, 0.20, 0.29, 0.55),
				1.0
			)

		for y in range(0, int(size.y), 38):
			draw_line(
				Vector2(0, y),
				Vector2(size.x, y),
				Color(0.08, 0.20, 0.29, 0.55),
				1.0
			)

		var accent: Color = WORLD_COLORS.get(
			world_id,
			Color.CYAN
		)

		var land := PackedVector2Array([
			Vector2(size.x * 0.16, size.y * 0.30),
			Vector2(size.x * 0.28, size.y * 0.17),
			Vector2(size.x * 0.48, size.y * 0.20),
			Vector2(size.x * 0.60, size.y * 0.34),
			Vector2(size.x * 0.80, size.y * 0.27),
			Vector2(size.x * 0.87, size.y * 0.49),
			Vector2(size.x * 0.73, size.y * 0.69),
			Vector2(size.x * 0.52, size.y * 0.78),
			Vector2(size.x * 0.32, size.y * 0.67),
			Vector2(size.x * 0.18, size.y * 0.51)
		])

		draw_colored_polygon(land, Color(0.07, 0.20, 0.25))
		draw_polyline(land, accent, 3.0, true)

		var points := [
			Vector2(0.30, 0.36),
			Vector2(0.48, 0.30),
			Vector2(0.65, 0.48),
			Vector2(0.42, 0.60),
			Vector2(0.73, 0.64)
		]

		for point in points:
			var location := Vector2(
				size.x * point.x,
				size.y * point.y
			)

			draw_circle(location, 6.0, accent)
			draw_arc(
				location,
				11.0,
				0.0,
				TAU,
				24,
				accent,
				1.5
			)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(18, 28),
			" SYSTEM WORLD ATLAS ",
			HORIZONTAL_ALIGNMENT_LEFT,
			240,
			16,
			accent
		)


var interface_layer: CanvasLayer
var main_panel: PanelContainer
var map_canvas: MapCanvas
var world_title: Label
var location_status: Label

var selected_world := "modern"


func _ready() -> void:
	_build_interface()


func _build_interface() -> void:
	interface_layer = CanvasLayer.new()
	interface_layer.name = "SYSTEMMapInterface"
	interface_layer.layer = 40
	add_child(interface_layer)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.color = Color(0.005, 0.012, 0.025, 0.88)
	overlay.visible = false
	interface_layer.add_child(overlay)

	main_panel = PanelContainer.new()
	main_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	main_panel.offset_left = 35
	main_panel.offset_top = 30
	main_panel.offset_right = -35
	main_panel.offset_bottom = -30

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.045, 0.085, 0.99)
	style.border_color = Color(0.0, 0.65, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)

	main_panel.add_theme_stylebox_override(
		"panel",
		style
	)

	interface_layer.add_child(main_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	main_panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	var title := Label.new()
	title.text = "خريطة SYSTEM WORLD"
	title.add_theme_font_size_override("font_size", 23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(close_map)
	header.add_child(close_button)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)

	for world_id in WORLD_NAMES:
		var button := Button.new()
		button.text = WORLD_NAMES[world_id]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		button.pressed.connect(
			_select_world.bind(world_id)
		)

		tabs.add_child(button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	root.add_child(content)

	map_canvas = MapCanvas.new()
	map_canvas.custom_minimum_size = Vector2(500, 350)
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(map_canvas)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(230, 0)
	content.add_child(side_panel)

	var side_column := VBoxContainer.new()
	side_panel.add_child(side_column)

	world_title = Label.new()
	world_title.add_theme_font_size_override("font_size", 19)
	side_column.add_child(world_title)

	side_column.add_child(HSeparator.new())

	var legend := Label.new()
	legend.text = (
		"معلومات الخريطة\n\n"
		+ "● المواقع المكتشفة\n"
		+ "● نقاط السفر السريع\n"
		+ "◆ علاماتك الشخصية"
	)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD
	side_column.add_child(legend)

	# مساحة مرنة متوافقة مع Godot 4.3
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_column.add_child(spacer)

	location_status = Label.new()
	location_status.text = "هذه معاينة أولية للأطلس."
	location_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	side_column.add_child(location_status)

	var footer := Label.new()
	footer.text = (
		"سيتم ربط المواقع الحقيقية وموقع اللاعب "
		+ "عند دخول العالم."
	)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)

	overlay.name = "MapOverlay"

	main_panel.visible = false
	overlay.visible = false

	set_meta("overlay", overlay)


func _select_world(world_id: String) -> void:
	selected_world = world_id

	map_canvas.set_world(world_id)

	world_title.text = str(
		WORLD_NAMES.get(world_id, world_id)
	)

	location_status.text = (
		"العالم المحدد: "
		+ world_title.text
	)


func open_map(world_id: String = "modern") -> void:
	_select_world(world_id)

	var overlay := get_meta("overlay") as ColorRect

	if is_instance_valid(overlay):
		overlay.visible = true

	main_panel.visible = true


func close_map() -> void:
	var overlay := get_meta("overlay") as ColorRect

	if is_instance_valid(overlay):
		overlay.visible = false

	main_panel.visible = false
