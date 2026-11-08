extends "res://scripts/command_center.gd"

# SYSTEM WORLD - Main Command Center
# Godot 4.3 | Landscape 1280x720

var premium_layer: CanvasLayer
var premium_root: Control

var miyar_ring: MeshInstance3D
var miyar_orbit: MeshInstance3D

var selected_world_title: Label
var premium_status: Label
var premium_dialogue: Label

var reference_preview: TextureRect
var reference_preview_button: Button

var world_portal_buttons: Dictionary = {}

const REFERENCE_IMAGE_PATH := "res://assets/ui/file_0000000053f081f4ab5d3e27245ce7a9.png"

const PORTAL_COLORS := {
	"modern": Color(0.08, 0.72, 1.0),
	"history": Color(1.0, 0.66, 0.22),
	"fantasy": Color(0.72, 0.38, 1.0),
	"greed": Color(0.30, 1.0, 0.72)
}

const WORLD_NAMES := {
	"modern": "العالم المستقبلي",
	"history": "العالم التاريخي",
	"fantasy": "العالم الخيالي",
	"greed": "جزيرة الطمع"
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
	_create_quick_menu()
	_create_world_portals()
	_create_player_hud()
	_create_bottom_thumbnails()
	_create_miyar_dialogue()
	_create_bottom_controls()

	# تُضاف المعاينة أخيراً حتى تظهر فوق الواجهة عند تشغيلها.
	_create_reference_preview()


func _panel(parent: Control, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.035, 0.075, 0.93)
	style.border_color = accent
	style.set_border_width_all(2)

	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14

	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8

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

	result.add_theme_font_size_override("font_size", 15)
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
	bar.anchor_bottom = 0.115

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	var brand := _label(
		"👑 SYSTEM WORLD\nنظام البشرية نحو الارتقاء",
		21,
		Color(1.0, 0.82, 0.35)
	)
	brand.custom_minimum_size.x = 300
	row.add_child(brand)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var language := OptionButton.new()
	language.add_item("العربية")
	language.add_item("English")
	language.add_item("کوردی")
	language.custom_minimum_size = Vector2(110, 40)
	language.item_selected.connect(_on_language_selected)
	row.add_child(language)

	row.add_child(
		_label("🪙 1,250,000", 16, Color(1.0, 0.82, 0.35))
	)
	row.add_child(
		_label("💎 12,500", 16, Color(0.35, 0.82, 1.0))
	)

	reference_preview_button = _button(
		row,
		"معاينة التصميم",
		Color(0.25, 0.85, 1.0),
		Vector2(125, 40)
	)
	reference_preview_button.pressed.connect(
		_toggle_reference_preview
	)

	var settings := _button(
		row,
		"⚙",
		Color(1.0, 0.78, 0.30),
		Vector2(55, 40)
	)
	settings.pressed.connect(
		_on_utility_pressed.bind("الإعدادات")
	)


func _create_quick_menu() -> void:
	var row := HBoxContainer.new()

	row.anchor_left = 0.02
	row.anchor_right = 0.37
	row.anchor_top = 0.13
	row.anchor_bottom = 0.22

	row.add_theme_constant_override("separation", 8)
	premium_root.add_child(row)

	var items := [
		["🎁 المكافآت", "المكافآت"],
		["♜ الفعاليات", "الفعاليات"],
		["👑 السباق", "السباق"],
		["✪ المهام", "المهام"]
	]

	for item in items:
		var b := _button(
			row,
			item[0],
			Color(1.0, 0.72, 0.25),
			Vector2(0, 48)
		)
		b.pressed.connect(
			_on_utility_pressed.bind(item[1])
		)


func _create_world_portals() -> void:
	var row := HBoxContainer.new()

	row.anchor_left = 0.015
	row.anchor_right = 0.405
	row.anchor_top = 0.255
	row.anchor_bottom = 0.745

	row.add_theme_constant_override("separation", 8)
	premium_root.add_child(row)

	var names := {
		"modern": "✦\nالعالم\nالمستقبلي",
		"history": "⌂\nالعالم\nالتاريخي",
		"fantasy": "✧\nالعالم\nالخيالي",
		"greed": "♛\nجزيرة\nالطمع"
	}

	for world_id in ["modern", "history", "fantasy", "greed"]:
		var portal := _button(
			row,
			names[world_id],
			PORTAL_COLORS[world_id],
			Vector2(0, 260)
		)

		portal.add_theme_font_size_override("font_size", 19)
		portal.pressed.connect(
			_on_world_button_pressed.bind(world_id)
		)

		world_portal_buttons[world_id] = portal


func _create_player_hud() -> void:
	var panel := _panel(premium_root, Color(0.0, 0.58, 0.92))

	panel.anchor_left = 0.835
	panel.anchor_right = 0.985
	panel.anchor_top = 0.13
	panel.anchor_bottom = 0.235

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)

	column.add_child(_label("👤 ملف اللاعب", 18))
	column.add_child(_label("المستوى 1 | XP 0%", 15))
	column.add_child(_label("🪙 0 | 💎 0", 15))

	var items := [
		["💬 الدردشة العالمية", "الدردشة العالمية"],
		["👥 الأصدقاء", "الأصدقاء"],
		["✉ البريد", "البريد"],
		["🏆 الإنجازات", "الإنجازات"],
		["🎒 الحقيبة", "الحقيبة"],
		["📍 الخريطة", "الخريطة"]
	]

	var menu := VBoxContainer.new()
	menu.anchor_left = 0.835
	menu.anchor_right = 0.985
	menu.anchor_top = 0.265
	menu.anchor_bottom = 0.72
	menu.add_theme_constant_override("separation", 7)
	premium_root.add_child(menu)

	for item in items:
		var b := _button(
			menu,
			item[0],
			Color(0.0, 0.55, 0.9),
			Vector2(0, 43)
		)
		b.pressed.connect(
			_on_utility_pressed.bind(item[1])
		)

	premium_status = _label("النظام جاهز", 12)
	menu.add_child(premium_status)


func _create_bottom_thumbnails() -> void:
	var row := HBoxContainer.new()

	row.anchor_left = 0.015
	row.anchor_right = 0.33
	row.anchor_top = 0.86
	row.anchor_bottom = 0.985

	row.add_theme_constant_override("separation", 6)
	premium_root.add_child(row)

	var names := [
		"العالم\nالمستقبلي",
		"العالم\nالتاريخي",
		"العالم\nالخيالي",
		"جزيرة\nالطمع"
	]

	var ids := ["modern", "history", "fantasy", "greed"]

	for i in range(4):
		var b := _button(
			row,
			names[i],
			PORTAL_COLORS[ids[i]],
			Vector2(0, 70)
		)
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(
			_on_world_button_pressed.bind(ids[i])
		)


func _create_miyar_dialogue() -> void:
	var panel := _panel(premium_root, Color(0.0, 0.68, 1.0))

	panel.anchor_left = 0.335
	panel.anchor_right = 0.69
	panel.anchor_top = 0.775
	panel.anchor_bottom = 0.925

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)

	column.add_child(
		_label("ميار | المساعدة الذكية", 17, Color(0.25, 0.88, 1.0))
	)

	premium_dialogue = _label(
		"مرحباً بك أيها الملك! هذه هي العوالم الأربعة في SYSTEM WORLD. اختر عالمك، ولنبدأ رحلتنا نحو الارتقاء معاً!",
		14
	)
	column.add_child(premium_dialogue)


func _create_bottom_controls() -> void:
	var controls := HBoxContainer.new()

	controls.anchor_left = 0.72
	controls.anchor_right = 0.985
	controls.anchor_top = 0.755
	controls.anchor_bottom = 0.835

	controls.add_theme_constant_override("separation", 5)
	premium_root.add_child(controls)

	var items := [
		["🔊 الصوت", "الصوت"],
		["♫ الموسيقى", "الموسيقى"],
		["▣ الجودة", "الجودة"],
		["☁ الحفظ", "الحفظ السحابي"]
	]

	for item in items:
		var b := _button(
			controls,
			item[0],
			Color(0.0, 0.55, 0.9),
			Vector2(0, 48)
		)
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(
			_on_utility_pressed.bind(item[1])
		)

	var enter := _button(
		premium_root,
		"⚔ ابدأ المغامرة",
		Color(1.0, 0.72, 0.20),
		Vector2(250, 68)
	)

	enter.anchor_left = 0.78
	enter.anchor_right = 0.985
	enter.anchor_top = 0.87
	enter.anchor_bottom = 0.985

	enter.add_theme_font_size_override("font_size", 23)
	enter.pressed.connect(_enter_selected_world)


func _create_reference_preview() -> void:
	reference_preview = TextureRect.new()
	reference_preview.name = "SYSTEMDesignReferencePreview"

	reference_preview.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	reference_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# لا تمنع الصورة الضغط على الزر الموجود تحتها.
	reference_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	reference_preview.visible = false
	reference_preview.modulate = Color(1, 1, 1, 0.96)

	if ResourceLoader.exists(REFERENCE_IMAGE_PATH):
		var loaded_texture = load(REFERENCE_IMAGE_PATH)

		if loaded_texture is Texture2D:
			reference_preview.texture = loaded_texture
		else:
			_set_status("تعذر تحميل صورة التصميم")
	else:
		_set_status("صورة التصميم غير موجودة في المسار المحدد")

	premium_root.add_child(reference_preview)


func _toggle_reference_preview() -> void:
	if not is_instance_valid(reference_preview):
		return

	if reference_preview.texture == null:
		_set_status("لم يتم العثور على صورة التصميم")
		return

	reference_preview.visible = not reference_preview.visible

	if reference_preview.visible:
		reference_preview_button.text = "إخفاء المعاينة"
		_set_status("معاينة الصورة المرجعية")
	else:
		reference_preview_button.text = "معاينة التصميم"
		_set_status("النظام جاهز")


func _set_status(message: String) -> void:
	if is_instance_valid(premium_status):
		premium_status.text = message


func _on_world_manager_selected(world_id: String) -> void:
	selected_world = world_id
	_update_world_buttons()

	var world_name := str(
		WORLD_NAMES.get(world_id, world_id)
	)

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
		premium_status.text = action_name + " | الخدمة قيد الربط."

	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = (
			"أنا ميار. قسم " +
			action_name +
			" سيُفتح عند اكتمال ربط خدمته."
		)


func _on_language_selected(index: int) -> void:
	var languages := ["العربية", "English", "کوردی"]

	if is_instance_valid(premium_status):
		premium_status.text = "اللغة المختارة: " + languages[index]


func _on_world_entry_failed(
	world_id: String,
	reason: String
) -> void:
	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = reason

	if is_instance_valid(premium_status):
		premium_status.text = "تعذر الدخول إلى " + world_id
