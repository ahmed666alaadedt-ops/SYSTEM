
extends "res://scripts/command_center.gd"

# SYSTEM WORLD - Premium Command Center
# Godot 4.3 - Landscape UI

var premium_layer: CanvasLayer
var premium_root: Control

var miyar_ring: MeshInstance3D
var miyar_orbit: MeshInstance3D

var selected_world_title: Label
var premium_status: Label
var premium_dialogue: Label

var world_portal_buttons: Dictionary = {}

const PORTAL_COLORS := {
	"modern": Color(0.08, 0.72, 1.0),
	"history": Color(1.0, 0.66, 0.22),
	"fantasy": Color(0.72, 0.38, 1.0),
	"greed": Color(0.30, 1.0, 0.72)
}


func _create_miyar_placeholder() -> void:
	super._create_miyar_placeholder()

	var mat := _material(
		Color(0.02, 0.16, 0.24),
		Color(0.0, 0.72, 1.0)
	)
	mat.emission_energy_multiplier = 2.2

	miyar_ring = MeshInstance3D.new()
	miyar_ring.name = "MiyarHologramRing"

	var ring := TorusMesh.new()
	ring.inner_radius = 1.65
	ring.outer_radius = 1.78

	miyar_ring.mesh = ring
	miyar_ring.position = Vector3(0, 0.18, -0.55)
	miyar_ring.rotation_degrees.x = 90
	miyar_ring.material_override = mat
	add_child(miyar_ring)

	miyar_orbit = MeshInstance3D.new()
	miyar_orbit.name = "MiyarInnerOrbit"

	var orbit := TorusMesh.new()
	orbit.inner_radius = 1.22
	orbit.outer_radius = 1.28

	miyar_orbit.mesh = orbit
	miyar_orbit.position = Vector3(0, 0.22, -0.55)
	miyar_orbit.rotation_degrees.x = 90
	miyar_orbit.material_override = mat
	add_child(miyar_orbit)


func _process(delta: float) -> void:
	if is_instance_valid(miyar_ring):
		miyar_ring.rotate_y(delta * 0.20)

	if is_instance_valid(miyar_orbit):
		miyar_orbit.rotate_y(-delta * 0.32)


func _create_interface() -> void:
	premium_layer = CanvasLayer.new()
	premium_layer.name = "SYSTEMPremiumInterface"
	premium_layer.layer = 10
	add_child(premium_layer)

	premium_root = Control.new()
	premium_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	premium_layer.add_child(premium_root)

	_create_top_bar()
	_create_world_portals()
	_create_player_hud()
	_create_miyar_dialogue()
	_create_bottom_controls()


func _panel(parent: Control, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()

	style.bg_color = Color(0.012, 0.035, 0.075, 0.91)
	style.border_color = accent
	style.set_border_width_all(2)

	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14

	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10

	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	return panel


func _label(
	value: String,
	size: int,
	color: Color = Color(0.88, 0.95, 1.0)
) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	return result


func _button(
	parent: Control,
	value: String,
	accent: Color,
	min_size: Vector2 = Vector2(0, 42)
) -> Button:
	var result := Button.new()
	result.text = value
	result.custom_minimum_size = min_size
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	result.add_theme_font_size_override("font_size", 16)
	result.add_theme_color_override(
		"font_color",
		Color(0.93, 0.97, 1.0)
	)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.085, 0.14, 0.98)
	normal.border_color = accent
	normal.set_border_width_all(2)

	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10

	result.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.07, 0.18, 0.27, 1.0)

	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", hover)

	parent.add_child(result)

	return result


func _create_top_bar() -> void:
	var bar := _panel(premium_root, Color(0.0, 0.55, 0.9))

	bar.anchor_left = 0.015
	bar.anchor_right = 0.985
	bar.anchor_top = 0.018
	bar.anchor_bottom = 0.13

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)

	var brand := _label(
		"👑 SYSTEM WORLD\nنظام البشرية نحو الارتقاء",
		20,
		Color(1.0, 0.82, 0.35)
	)
	brand.custom_minimum_size.x = 250
	row.add_child(brand)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var language := OptionButton.new()
	language.add_item("العربية")
	language.add_item("English")
	language.add_item("کوردی")
	language.custom_minimum_size = Vector2(125, 40)
	language.item_selected.connect(_on_language_selected)
	row.add_child(language)

	row.add_child(_label("🪙 0", 17, Color(1.0, 0.82, 0.35)))
	row.add_child(_label("💎 0", 17, Color(0.35, 0.82, 1.0)))

	var settings := _button(
		row,
		"⚙ الإعدادات",
		Color(1.0, 0.78, 0.30),
		Vector2(125, 40)
	)
	settings.pressed.connect(
		_on_utility_pressed.bind("الإعدادات")
	)


func _create_world_portals() -> void:
	var panel := _panel(premium_root, Color(0.0, 0.58, 0.92))

	panel.anchor_left = 0.015
	panel.anchor_top = 0.155
	panel.anchor_bottom = 0.82
	panel.anchor_right = 0.235

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	column.add_child(
		_label("بوابات العوالم الأربعة", 20, Color(0.45, 0.86, 1.0))
	)

	var names := {
		"modern": "✦ العالم المستقبلي\nالمدن والتقنية",
		"history": "⌂ العالم التاريخي\nالحضارات القديمة",
		"fantasy": "✧ العالم الخيالي\nالممالك والسحر",
		"greed": "♛ جزيرة الطمع\nالجزيرة العائمة"
	}

	for world_id in ["modern", "history", "fantasy", "greed"]:
		var portal := _button(
			column,
			names[world_id],
			PORTAL_COLORS[world_id],
			Vector2(0, 76)
		)

		portal.add_theme_font_size_override("font_size", 17)

		portal.pressed.connect(
			_on_world_button_pressed.bind(world_id)
		)

		world_portal_buttons[world_id] = portal

	selected_world_title = _label(
		"العالم المحدد: العالم المستقبلي",
		14
	)
	column.add_child(selected_world_title)


func _create_player_hud() -> void:
	var panel := _panel(premium_root, Color(0.0, 0.58, 0.92))

	panel.anchor_left = 0.765
	panel.anchor_right = 0.985
	panel.anchor_top = 0.155
	panel.anchor_bottom = 0.82

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	column.add_child(_label("ملف اللاعب", 21))
	column.add_child(_label("المستوى 1 | XP 0%", 17))
	column.add_child(_label("العملة 0 | الجواهر 0", 15))

	column.add_child(HSeparator.new())
	column.add_child(_label("التواصل والأنظمة", 17))

	var items := [
		["الدردشة العالمية", "الدردشة"],
		["الأصدقاء", "الأصدقاء"],
		["البريد والإشعارات", "البريد"],
		["الإنجازات", "الإنجازات"],
		["الحقيبة", "الحقيبة"],
		["الخريطة", "الخريطة"]
	]

	for item in items:
		var b := _button(
			column,
			item[0],
			Color(0.0, 0.48, 0.78),
			Vector2(0, 38)
		)
		b.pressed.connect(
			_on_utility_pressed.bind(item[1])
		)

	premium_status = _label("النظام جاهز", 13)
	column.add_child(premium_status)


func _create_miyar_dialogue() -> void:
	var panel := _panel(premium_root, Color(0.0, 0.68, 1.0))

	panel.anchor_left = 0.255
	panel.anchor_right = 0.745
	panel.anchor_top = 0.79
	panel.anchor_bottom = 0.965

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)

	column.add_child(
		_label("ميار | المساعدة الذكية", 18, Color(0.25, 0.88, 1.0))
	)

	premium_dialogue = _label(
		"مرحباً أيها الملك! اختر أحد العوالم الأربعة، وسأرشدك في رحلتك.",
		16
	)
	column.add_child(premium_dialogue)

	var enter := _button(
		column,
		"⚔ ابدأ المغامرة",
		Color(1.0, 0.72, 0.20),
		Vector2(0, 46)
	)

	enter.pressed.connect(_enter_selected_world)


func _create_bottom_controls() -> void:
	var row := HBoxContainer.new()

	row.anchor_left = 0.255
	row.anchor_right = 0.745
	row.anchor_top = 0.145
	row.anchor_bottom = 0.205

	row.add_theme_constant_override("separation", 8)
	premium_root.add_child(row)

	var items := [
		["الصوت", "الصوت"],
		["الموسيقى", "الموسيقى"],
		["الجودة", "الجودة"],
		["الحفظ السحابي", "الحفظ السحابي"]
	]

	for item in items:
		var b := _button(
			row,
			item[0],
			Color(0.0, 0.45, 0.72),
			Vector2(0, 38)
		)
		b.pressed.connect(
			_on_utility_pressed.bind(item[1])
		)


func _on_world_manager_selected(world_id: String) -> void:
	selected_world = world_id
	_update_world_buttons()

	var world_info := WorldData.get_world(world_id)
	var world_name := str(world_info.get("title", world_id))

	if world_id == "modern":
		world_name = "العالم المستقبلي"

	if is_instance_valid(selected_world_title):
		selected_world_title.text = "العالم المحدد: " + world_name

	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = (
			"أحسنت الاختيار! هذا هو " +
			world_name +
			". أنا ميار، وسأرافقك في رحلتك."
		)


func _update_world_buttons() -> void:
	for world_id in world_portal_buttons:
		var button: Button = world_portal_buttons[world_id]
		button.modulate = Color.WHITE

		if world_id == selected_world:
			button.modulate = Color(1.18, 1.18, 1.18, 1.0)


func _on_utility_pressed(action_name: String) -> void:
	if is_instance_valid(premium_status):
		premium_status.text = (
			action_name +
			" | الربط التفصيلي يحتاج توصيل النظام المختص."
		)

	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = (
			"أنا ميار. قسم " +
			action_name +
			" سيُفتح عند اكتمال ربط خدمته."
		)


func _on_language_selected(index: int) -> void:
	var languages := ["العربية", "English", "کوردی"]

	if is_instance_valid(premium_status):
		premium_status.text = (
			"اللغة المختارة: " +
			languages[index] +
			" - الترجمة الكاملة تحتاج ملفات ترجمة."
		)


func _on_world_entry_failed(
	world_id: String,
	reason: String
) -> void:
	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = reason

	if is_instance_valid(premium_status):
		premium_status.text = "تعذر الدخول إلى " + world_id
