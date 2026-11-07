extends Node3D

# SYSTEM WORLD - Historical Civilization
# Godot 4.3 | Landscape | Android Touch | Third Person

const PLAYER_SPEED := 6.0
const GRAVITY := 22.0
const CAMERA_SENSITIVITY := 0.006
const COMMAND_CENTER := "res://scenes/command_center.tscn"

var player: CharacterBody3D
var camera_pivot: Node3D
var world_camera: Camera3D

var camera_yaw := 0.0
var camera_pitch := -0.22

var move_touch_index := -1
var look_touch_index := -1
var move_start_position := Vector2.ZERO
var touch_movement := Vector2.ZERO

var status_label: Label


func _ready() -> void:
	_create_environment()
	_create_ground()
	_create_babylon_gate()
	_create_ziggurat()
	_create_historical_city()
	_create_river()
	_create_player()
	_create_interface()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var movement := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0

	movement += touch_movement
	movement = movement.limit_length(1.0)

	var forward := Vector3(
		-sin(camera_yaw), 0.0, -cos(camera_yaw)
	)
	var right := Vector3(
		cos(camera_yaw), 0.0, -sin(camera_yaw)
	)

	var direction := (
		right * movement.x + forward * -movement.y
	).normalized()

	player.velocity.x = direction.x * PLAYER_SPEED
	player.velocity.z = direction.z * PLAYER_SPEED

	if player.is_on_floor():
		player.velocity.y = -0.5
	else:
		player.velocity.y -= GRAVITY * delta

	player.move_and_slide()

	if direction.length() > 0.1:
		player.rotation.y = lerp_angle(
			player.rotation.y,
			atan2(direction.x, direction.z),
			delta * 9.0
		)

	camera_pivot.rotation.y = camera_yaw
	camera_pivot.rotation.x = camera_pitch


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().size.x * 0.48:
				if move_touch_index == -1:
					move_touch_index = event.index
					move_start_position = event.position
					touch_movement = Vector2.ZERO
			else:
				if look_touch_index == -1:
					look_touch_index = event.index
		else:
			if event.index == move_touch_index:
				move_touch_index = -1
				touch_movement = Vector2.ZERO

			if event.index == look_touch_index:
				look_touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index == move_touch_index:
			var offset := event.position - move_start_position
			touch_movement = Vector2(
				offset.x / 75.0,
				offset.y / 75.0
			).limit_length(1.0)

		elif event.index == look_touch_index:
			camera_yaw -= event.relative.x * CAMERA_SENSITIVITY
			camera_pitch = clamp(
				camera_pitch - event.relative.y * CAMERA_SENSITIVITY,
				-0.85, 0.2
			)

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			camera_yaw -= event.relative.x * CAMERA_SENSITIVITY
			camera_pitch = clamp(
				camera_pitch - event.relative.y * CAMERA_SENSITIVITY,
				-0.85, 0.2
			)

	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_return_to_command_center()


# --------------------------------------------------
# ENVIRONMENT
# --------------------------------------------------

func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()

	sky_material.sky_top_color = Color(0.16, 0.25, 0.39)
	sky_material.sky_horizon_color = Color(0.82, 0.65, 0.43)
	sky_material.ground_bottom_color = Color(0.20, 0.14, 0.10)
	sky_material.ground_horizon_color = Color(0.63, 0.43, 0.27)

	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.78, 0.66, 0.51)
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-42, -30, 0)
	sunlight.light_color = Color(1.0, 0.82, 0.62)
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = true
	add_child(sunlight)


# --------------------------------------------------
# GROUND
# --------------------------------------------------

func _create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "HistoricalGround"

	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(150, 150)

	mesh_instance.mesh = plane
	mesh_instance.material_override = _material(
		Color(0.53, 0.38, 0.23)
	)
	ground.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(150, 0.3, 150)
	collision.shape = shape
	collision.position.y = -0.15
	ground.add_child(collision)

	add_child(ground)

	_add_box(
		"BabylonMainRoad",
		Vector3(0, 0.04, 0),
		Vector3(12, 0.12, 85),
		Color(0.62, 0.52, 0.38)
	)

	_add_box(
		"CentralStoneSquare",
		Vector3(0, 0.08, 2),
		Vector3(34, 0.18, 28),
		Color(0.68, 0.57, 0.42)
	)


# --------------------------------------------------
# BABYLON GATE
# --------------------------------------------------

func _create_babylon_gate() -> void:
	var blue := Color(0.025, 0.20, 0.38)
	var gold := Color(0.83, 0.57, 0.19)

	_add_box(
		"GateLeftTower",
		Vector3(-10, 5, -28),
		Vector3(5, 10, 3),
		blue
	)

	_add_box(
		"GateRightTower",
		Vector3(10, 5, -28),
		Vector3(5, 10, 3),
		blue
	)

	_add_box(
		"GateTopBridge",
		Vector3(0, 10, -28),
		Vector3(25, 2, 3),
		blue
	)

	_add_box(
		"GateGoldenFrame",
		Vector3(0, 5.1, -26.2),
		Vector3(12, 9, 0.35),
		gold
	)

	for side in [-1.0, 1.0]:
		for i in range(5):
			_add_box(
				"GateDecoration",
				Vector3(side * 10.0, 1.0 + i * 1.7, -26.1),
				Vector3(4.0, 0.12, 0.15),
				gold
			)


# --------------------------------------------------
# ZIGGURAT
# --------------------------------------------------

func _create_ziggurat() -> void:
	var stone_colors := [
		Color(0.62, 0.40, 0.23),
		Color(0.69, 0.47, 0.28),
		Color(0.76, 0.55, 0.34),
		Color(0.57, 0.35, 0.21)
	]

	var widths := [22.0, 17.0, 12.0, 7.0]

	for i in range(4):
		var width: float = widths[i]
		var height := 2.4

		_add_box(
			"ZigguratLevel_%d" % i,
			Vector3(0, 1.2 + i * 2.3, -55),
			Vector3(width, height, width),
			stone_colors[i]
		)

	_add_box(
		"ZigguratTemple",
		Vector3(0, 11.0, -55),
		Vector3(6, 1.5, 6),
		Color(0.83, 0.63, 0.34)
	)


# --------------------------------------------------
# HISTORICAL CITY
# --------------------------------------------------

func _create_historical_city() -> void:
	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := -12.0 - float(i) * 7.0
		var height := 4.0 + float(i % 4)

		_add_box(
			"AncientHouse_%d" % i,
			Vector3(side * 19.0, height * 0.5, z),
			Vector3(7, height, 7),
			Color(0.57, 0.39, 0.24)
		)

		_add_box(
			"AncientHouseRoof_%d" % i,
			Vector3(side * 19.0, height + 0.2, z),
			Vector3(7.5, 0.4, 7.5),
			Color(0.35, 0.22, 0.15)
		)

	_create_columns()
	_create_palm_grove()


func _create_columns() -> void:
	for i in range(8):
		var x := -12.0 + float(i) * 3.5

		_add_cylinder(
			"TempleColumn_%d" % i,
			Vector3(x, 2.2, -12),
			0.42,
			4.4,
			Color(0.82, 0.72, 0.56)
		)

		_add_box(
			"ColumnCapital_%d" % i,
			Vector3(x, 4.5, -12),
			Vector3(1.2, 0.3, 1.2),
			Color(0.87, 0.68, 0.39)
		)


func _create_palm_grove() -> void:
	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0
		var position := Vector3(
			side * (25.0 + float(i % 3) * 3.0),
			0,
			-35.0 + float(i) * 6.0
		)

		_add_cylinder(
			"PalmTrunk_%d" % i,
			position + Vector3(0, 2.0, 0),
			0.28,
			4.0,
			Color(0.35, 0.21, 0.11)
		)

		var crown := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.8
		sphere.height = 1.5
		crown.mesh = sphere
		crown.position = position + Vector3(0, 4.2, 0)
		crown.material_override = _material(
			Color(0.16, 0.34, 0.13)
		)
		add_child(crown)


# --------------------------------------------------
# RIVER
# --------------------------------------------------

func _create_river() -> void:
	var river_material := StandardMaterial3D.new()
	river_material.albedo_color = Color(0.08, 0.39, 0.53, 0.88)
	river_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	river_material.roughness = 0.18

	_add_box(
		"AncientRiver",
		Vector3(42, 0.06, -72),
		Vector3(150, 0.08, 13),
		Color(0.08, 0.39, 0.53)
	)


# --------------------------------------------------
# PLAYER AND CAMERA
# --------------------------------------------------

func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "HistoricalPlayer"
	player.position = Vector3(0, 1.1, 13)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	body.mesh = capsule
	body.position.y = 0.9
	body.material_override = _material(
		Color(0.15, 0.35, 0.55)
	)
	player.add_child(body)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	player.add_child(collision)

	add_child(player)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	player.add_child(camera_pivot)

	world_camera = Camera3D.new()
	world_camera.position = Vector3(0, 3.0, 7.5)
	world_camera.current = true
	camera_pivot.add_child(world_camera)


# --------------------------------------------------
# INTERFACE
# --------------------------------------------------

func _create_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	status_label = Label.new()
	status_label.text = "SYSTEM WORLD | العالم التاريخي"
	status_label.position = Vector2(22, 18)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.83, 0.56)
	)
	layer.add_child(status_label)

	var instructions := Label.new()
	instructions.text = "اسحب يسار الشاشة للحركة • اسحب يمينها لتحريك الكاميرا"
	instructions.position = Vector2(22, 55)
	instructions.add_theme_font_size_override("font_size", 16)
	layer.add_child(instructions)

	var back_button := Button.new()
	back_button.text = "العودة إلى مركز القيادة"
	back_button.position = Vector2(22, 95)
	back_button.custom_minimum_size = Vector2(220, 48)
	back_button.pressed.connect(_return_to_command_center)
	layer.add_child(back_button)


func _return_to_command_center() -> void:
	if ResourceLoader.exists(COMMAND_CENTER):
		get_tree().change_scene_to_file(COMMAND_CENTER)
	else:
		push_warning("Command Center scene was not found.")


# --------------------------------------------------
# BUILDING HELPERS
# --------------------------------------------------

func _add_box(
	object_name: String,
	at: Vector3,
	box_size: Vector3,
	color: Color
) -> void:
	var body := StaticBody3D.new()
	body.name = object_name
	body.position = at

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	add_child(body)


func _add_cylinder(
	object_name: String,
	at: Vector3,
	radius: float,
	height: float,
	color: Color
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height

	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.material_override = _material(color)
	add_child(mesh_instance)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
