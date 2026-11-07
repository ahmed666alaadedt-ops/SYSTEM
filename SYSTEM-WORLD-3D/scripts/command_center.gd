extends Node3D

# SYSTEM WORLD - Command Center
# Godot 4.3 | Landscape Interface

const MODERN_SCENE := "res://scenes/main.tscn"

var selected_world := "modern"
var world_buttons: Dictionary = {}

var world_panel: PanelContainer
var player_panel: PanelContainer
var miyar_panel: PanelContainer
var title_label: Label

var miyar_message: Label
var utility_status: Label


var world_data := [
	{
		"id": "modern",
		"title": "العالم الحديث",
		"subtitle": "المدن والحياة الواقعية",
		"color": Color(0.05, 0.75, 0.95),
		"icon": "01"
	},
	{
		"id": "history",
		"title": "العالم التاريخي",
		"subtitle": "الحضارات والأسرار القديمة",
		"color": Color(0.90, 0.65, 0.25),
		"icon": "02"
	},
	{
		"id": "fantasy",
		"title": "العالم الخيالي",
		"subtitle": "الممالك والسحر والمخلوقات",
		"color": Color(0.65, 0.35, 0.95),
		"icon": "03"
	},
	{
		"id": "greed",
		"title": "جزيرة الطمع",
		"subtitle": "الموسم والتحديات النادرة",
		"color": Color(0.95, 0.72, 0.20),
		"icon": "04"
	}
]


func _ready() -> void:
	_create_environment()
	_create_command_room()
	_create_city_view()
	_create_miyar_placeholder()
	_create_camera()
	_create_interface()


# ==================================================
# ENVIRONMENT
# ==================================================

func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()

	sky_material.sky_top_color = Color(0.015, 0.035, 0.09)
	sky_material.sky_horizon_color = Color(0.08, 0.22, 0.34)
	sky_material.ground_bottom_color = Color(0.015, 0.025, 0.05)
	sky_material.ground_horizon_color = Color(0.04, 0.09, 0.14)

	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.65, 0.85)
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-35, -25, 0)
	sunlight.light_energy = 0.75
	sunlight.shadow_enabled = true
	add_child(sunlight)

	var center_light := OmniLight3D.new()
	center_light.position = Vector3(0, 5, 0)
	center_light.light_color = Color(0.10, 0.65, 1.0)
	center_light.light_energy = 2.0
	center_light.omni_range = 13.0
	add_child(center_light)


# ==================================================
# COMMAND ROOM
# ==================================================

func _create_command_room() -> void:
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()

	floor_mesh.size = Vector2(38, 30)
	floor.mesh = floor_mesh
	floor.position.y = -0.1
	floor.material_override = _material(
		Color(0.035, 0.065, 0.105),
		Color(0.02, 0.20, 0.32)
	)
	add_child(floor)

	_add_box(
		"CentralPlatform",
		Vector3(10, 0.35, 7),
		Vector3(0, 0.15, 0),
		_material(Color(0.07, 0.12, 0.18), Color(0.0, 0.55, 0.85))
	)

	_add_box(
		"RearWall",
		Vector3(34, 10, 0.5),
		Vector3(0, 5, -9),
		_material(Color(0.025, 0.055, 0.09))
	)

	_add_box(
		"CentralConsole",
		Vector3(7, 1.0, 1.5),
		Vector3(0, 1.0, 2.0),
		_material(Color(0.035, 0.10, 0.16), Color(0.0, 0.65, 1.0))
	)

	for side in [-1.0, 1.0]:
		_add_box(
			"CommandPillar",
			Vector3(0.45, 7.0, 0.45),
			Vector3(side * 13.0, 3.5, -4.0),
			_material(Color(0.07, 0.15, 0.22), Color(0.0, 0.55, 0.9))
		)


func _create_city_view() -> void:
	for i in range(19):
		var x := -15.0 + float(i) * 1.65
		var height := 3.0 + float((i * 7) % 8)

		_add_box(
			"CityTower_%02d" % i,
			Vector3(1.15, height, 0.9),
			Vector3(x, height * 0.5, -12.0),
			_material(Color(0.035, 0.09, 0.15), Color(0.0, 0.22, 0.42))
		)

		_add_box(
			"TowerLight_%02d" % i,
			Vector3(0.07, height * 0.65, 0.04),
			Vector3(x - 0.25, height * 0.5, -11.48),
			_material(Color(0.0, 0.55, 0.85), Color(0.0, 0.75, 1.0))
		)


# ==================================================
# MIYAR 3D PLACEHOLDER
# ==================================================

func _create_miyar_placeholder() -> void:
	var chair_material := _material(
		Color(0.08, 0.12, 0.19),
		Color(0.0, 0.55, 0.85)
	)

	_add_box(
		"MiyarChairBack",
		Vector3(2.0, 2.4, 0.35),
		Vector3(0, 1.65, -1.7),
		chair_material
	)

	_add_box(
		"MiyarChairSeat",
		Vector3(2.2, 0.35, 1.5),
		Vector3(0, 0.75, -1.0),
		chair_material
	)

	var body_material := _material(
		Color(0.12, 0.30, 0.48),
		Color(0.0, 0.75, 1.0)
	)

	var skin_material := _material(Color(0.78, 0.59, 0.48))
	var hair_material := _material(Color(0.035, 0.045, 0.075))

	_add_capsule(
		"MiyarBody",
		0.58,
		1.45,
		Vector3(0, 1.95, -0.7),
		body_material
	)

	_add_sphere(
		"MiyarHead",
		0.48,
		Vector3(0, 3.05, -0.65),
		skin_material
	)

	_add_sphere(
		"MiyarHair",
		0.51,
		Vector3(0, 3.27, -0.75),
		hair_material
	)

	var left_arm := _add_capsule(
		"MiyarLeftArm",
		0.17,
		1.05,
		Vector3(-0.72, 2.0, -0.5),
		body_material
	)
	left_arm.rotation_degrees.z = -18

	var right_arm := _add_capsule(
		"MiyarRightArm",
		0.17,
		1.05,
		Vector3(0.72, 2.0, -0.5),
		body_material
	)
	right_arm.rotation_degrees.z = 18

	_add_capsule(
		"MiyarLeftLeg",
		0.20,
		1.0,
		Vector3(-0.32, 0.35, -0.4),
		body_material
	)

	_add_capsule(
		"MiyarRightLeg",
		0.20,
		1.0,
		Vector3(0.32, 0.35, -0.4),
		body_material
	)


# ==================================================
# CAMERA
# ==================================================

func _create_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "CommandCenterCamera"
	camera.position = Vector3(0, 5.4, 17.5)
	camera.fov = 55.0

	add_child(camera)
	camera.look_at(Vector3(0, 2.0, -1.0), Vector3.UP)
	camera.current = true


# ==================================================
# INTERFACE
# ==================================================

func _create_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	title_label = _make_label("S Y S T E M   W O R L D", 25)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title_label)

	_create_world_panel(root)
	_create_player_panel(root)
	_create_miyar_panel(root)

	root.resized.connect(_layout_interface.bind(root))
	call_deferred("_layout_interface", root)


func _layout_interface(root: Control) -> void:
	var view_size := root.size

	if view_size.x <= 0 or view_size.y <= 0:
		return

	var side_margin := 18.0
	var panel_width := minf(300.0, view_size.x * 0.25)
	var panel_height := minf(535.0, view_size.y - 155.0)

	world_panel.position = Vector2(side_margin, 82)
	world_panel.size = Vector2(panel_width, panel_height)

	player_panel.position = Vector2(
		view_size.x - panel_width - side_margin,
		82
	)
	player_panel.size = Vector2(panel_width, panel_height)

	title_label.position = Vector2(
		(view_size.x - 420.0) * 0.5,
		18
	)
	title_label.size = Vector2(420, 42)

	var helper_width := minf(600.0, view_size.x - (panel_width * 2.0) - 60.0)
	helper_width = maxf(helper_width, 300.0)

	miyar_panel.size = Vector2(helper_width, 92)
	miyar_panel.position = Vector2(
		(view_size.x - helper_width) * 0.5,
		view_size.y - 112
	)


# ==================================================
# WORLD PANEL
# ==================================================

func _create_world_panel(root: Control) -> void:
	world_panel = _create_panel(
		root,
		Vector2.ZERO,
		Vector2(300, 535),
		Color(0.025, 0.06, 0.11, 0.94),
		Color(0.0, 0.48, 0.75)
	)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	world_panel.add_child(column)

	column.add_child(_make_label("اختر عالمك", 23))
	column.add_child(_make_label("أربعة عوالم مستقلة", 15))

	for world in world_data:
		var world_id := str(world["id"])

		var button := Button.new()
		button.text = (
			str(world["icon"]) + "   " +
			str(world["title"]) + "\n" +
			str(world["subtitle"])
		)

		button.custom_minimum_size = Vector2(250, 82)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17)

		button.add_theme_stylebox_override(
			"normal",
			_button_style(
				Color(0.045, 0.10, 0.16, 0.96),
				world["color"]
			)
		)

		button.add_theme_stylebox_override(
			"hover",
			_button_style(
				Color(0.08, 0.18, 0.26, 1.0),
				world["color"]
			)
		)

		button.add_theme_color_override(
			"font_color",
			Color(0.90, 0.96, 1.0)
		)

		button.pressed.connect(_on_world_selected.bind(world_id))

		column.add_child(button)
		world_buttons[world_id] = button

	_update_world_buttons()


# ==================================================
# PLAYER PANEL
# ==================================================

func _create_player_panel(root: Control) -> void:
	player_panel = _create_panel(
		root,
		Vector2.ZERO,
		Vector2(300, 535),
		Color(0.025, 0.06, 0.11, 0.94),
		Color(0.0, 0.48, 0.75)
	)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	player_panel.add_child(column)

	column.add_child(_make_label("ملف اللاعب", 22))
	column.add_child(_make_label("المستوى  1", 19))
	column.add_child(_make_label("الخبرة  0 / 100", 16))
	column.add_child(_make_label("العملة  0", 16))

	column.add_child(HSeparator.new())
	column.add_child(_make_label("أنظمة العالم", 18))

	_add_utility_button(column, "الخريطة", "الخريطة")
	_add_utility_button(column, "الدردشة العالمية", "الدردشة")
	_add_utility_button(column, "المهام", "المهام")
	_add_utility_button(column, "الإعدادات", "الإعدادات")

	utility_status = _make_label("النظام جاهز", 13)
	column.add_child(utility_status)

	var enter_button := Button.new()
	enter_button.text = "دخول العالم المحدد"
	enter_button.custom_minimum_size = Vector2(240, 48)
	enter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enter_button.add_theme_font_size_override("font_size", 17)

	enter_button.add_theme_stylebox_override(
		"normal",
		_button_style(
			Color(0.02, 0.25, 0.38),
			Color(0.0, 0.85, 1.0)
		)
	)

	enter_button.pressed.connect(_enter_selected_world)
	column.add_child(enter_button)


# ==================================================
# MIYAR PANEL
# ==================================================

func _create_miyar_panel(root: Control) -> void:
	miyar_panel = _create_panel(
		root,
		Vector2.ZERO,
		Vector2(600, 92),
		Color(0.02, 0.055, 0.10, 0.94),
		Color(0.0, 0.55, 0.85)
	)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	miyar_panel.add_child(column)

	column.add_child(_make_label("ميار | SYSTEM AI", 18))

	miyar_message = _make_label(
		"أهلاً بك. أنا ميار، سأرافقك في رحلتك داخل SYSTEM WORLD.",
		15
	)
	column.add_child(miyar_message)


# ==================================================
# WORLD SELECTION
# ==================================================

func _on_world_selected(world_id: String) -> void:
	selected_world = world_id
	_update_world_buttons()

	for world in world_data:
		if str(world["id"]) == selected_world:
			miyar_message.text = (
				"تم اختيار " + str(world["title"]) + ". أنا معك."
			)
			utility_status.text = "العالم المحدد: " + str(world["title"])
			return


func _update_world_buttons() -> void:
	for world in world_data:
		var world_id := str(world["id"])

		if not world_buttons.has(world_id):
			continue

		var button: Button = world_buttons[world_id]
		var background := Color(0.045, 0.10, 0.16, 0.96)

		if world_id == selected_world:
			background = Color(0.08, 0.22, 0.30, 1.0)

		button.add_theme_stylebox_override(
			"normal",
			_button_style(background, world["color"])
		)


func _enter_selected_world() -> void:
	if selected_world == "modern":
		var result := get_tree().change_scene_to_file(MODERN_SCENE)

		if result != OK:
			utility_status.text = "تعذر فتح مشهد العالم الحديث."
		return

	miyar_message.text = "هذا العالم ضمن مراحل البناء القادمة."
	utility_status.text = "العالم المحدد لم يُربط بمشهد لعب بعد."


# ==================================================
# UTILITY BUTTONS
# ==================================================

func _add_utility_button(
	parent: VBoxContainer,
	button_text: String,
	action_name: String
) -> void:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(230, 36)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)

	button.add_theme_stylebox_override(
		"normal",
		_button_style(
			Color(0.04, 0.09, 0.15),
			Color(0.0, 0.40, 0.65)
		)
	)

	button.pressed.connect(_on_utility_pressed.bind(action_name))
	parent.add_child(button)


func _on_utility_pressed(action_name: String) -> void:
	utility_status.text = action_name + " - قيد التطوير"


# ==================================================
# VISUAL HELPERS
# ==================================================

func _create_panel(
	parent: Control,
	panel_position: Vector2,
	panel_size: Vector2,
	background_color: Color,
	border_color: Color
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.size = panel_size

	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(2)

	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12

	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10

	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	return panel


func _make_label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)

	label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.94, 1.0)
	)

	return label


func _button_style(
	background_color: Color,
	border_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(2)

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	return style


func _material(
	base_color: Color,
	glow_color: Color = Color.BLACK
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.roughness = 0.55

	if glow_color != Color.BLACK:
		material.emission_enabled = true
		material.emission = glow_color
		material.emission_energy_multiplier = 0.65

	return material


func _add_box(
	object_name: String,
	box_size: Vector3,
	at: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = object_name

	var mesh := BoxMesh.new()
	mesh.size = box_size

	instance.mesh = mesh
	instance.position = at
	instance.material_override = material

	add_child(instance)
	return instance


func _add_capsule(
	object_name: String,
	radius: float,
	height: float,
	at: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = object_name

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height

	instance.mesh = mesh
	instance.position = at
	instance.material_override = material

	add_child(instance)
	return instance


func _add_sphere(
	object_name: String,
	radius: float,
	at: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = object_name

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0

	instance.mesh = mesh
	instance.position = at
	instance.material_override = material

	add_child(instance)
	return instance
