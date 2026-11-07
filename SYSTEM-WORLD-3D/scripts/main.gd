extends Node3D

# SYSTEM WORLD - 3D foundation
# Godot 4.3 - Landscape / Android touch / Third-person
# NPC Society + Persistent Save Integration

const PLAYER_SPEED := 6.0
const GRAVITY := 22.0
const CAMERA_SENSITIVITY := 0.006

const NPC_MANAGER_PATH := "res://scripts/ai_npc_society_manager.gd"
const SAVE_MANAGER_PATH := "res://scripts/world_save_manager.gd"
const AUTOSAVE_INTERVAL := 60.0

var player: CharacterBody3D
var camera_pivot: Node3D
var world_camera: Camera3D

var camera_yaw := 0.0
var camera_pitch := -0.22

var move_touch_index := -1
var look_touch_index := -1
var move_start_position := Vector2.ZERO
var touch_movement := Vector2.ZERO

var world_clock := 8.0
var autosave_timer := 0.0

var status_label: Label
var npc_manager: Node
var save_manager: Node


func _ready() -> void:
	randomize()

	_create_environment()
	_create_terrain()
	_create_town()
	_create_player()
	_create_interface()

	_connect_npc_society()
	_connect_world_save_manager()


func _process(delta: float) -> void:
	world_clock = fposmod(world_clock + delta * 0.025, 24.0)

	if is_instance_valid(status_label):
		var hour := int(world_clock)
		var minute := int(fposmod(world_clock * 60.0, 60.0))
		status_label.text = "SYSTEM WORLD  |  %02d:%02d" % [hour, minute]

	if is_instance_valid(npc_manager):
		if npc_manager.has_method("update_world"):
			npc_manager.call("update_world", delta, world_clock)

	_update_autosave(delta)


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
		-sin(camera_yaw),
		0.0,
		-cos(camera_yaw)
	)

	var right := Vector3(
		cos(camera_yaw),
		0.0,
		-sin(camera_yaw)
	)

	var direction := (
		right * movement.x +
		forward * -movement.y
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
				-0.85,
				0.2
			)

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			camera_yaw -= event.relative.x * CAMERA_SENSITIVITY

			camera_pitch = clamp(
				camera_pitch - event.relative.y * CAMERA_SENSITIVITY,
				-0.85,
				0.2
			)


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()

	sky_material.sky_top_color = Color(0.08, 0.17, 0.30)
	sky_material.sky_horizon_color = Color(0.55, 0.65, 0.72)
	sky_material.ground_bottom_color = Color(0.04, 0.05, 0.06)
	sky_material.ground_horizon_color = Color(0.30, 0.37, 0.39)

	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.72, 0.85)
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "WorldSun"
	sunlight.rotation_degrees = Vector3(-48, -32, 0)
	sunlight.light_energy = 1.2
	sunlight.shadow_enabled = true
	add_child(sunlight)


func _create_terrain() -> void:
	var ground := StaticBody3D.new()
	ground.name = "WorldGround"

	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()

	plane.size = Vector2(120, 120)

	ground_mesh.mesh = plane
	ground_mesh.material_override = _make_material(
		Color(0.19, 0.29, 0.20)
	)
	ground.add_child(ground_mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()

	shape.size = Vector3(120, 0.3, 120)
	collision.shape = shape
	collision.position.y = -0.15
	ground.add_child(collision)

	add_child(ground)


func _create_town() -> void:
	_add_static_box(
		"MainRoad",
		Vector3(0, 0.03, 0),
		Vector3(11, 0.12, 90),
		Color(0.24, 0.25, 0.25)
	)

	_add_static_box(
		"TownSquare",
		Vector3(0, 0.04, 0),
		Vector3(25, 0.14, 22),
		Color(0.43, 0.40, 0.34)
	)

	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0

		var position := Vector3(
			side * 14.0,
			0.0,
			-38.0 + float(i) * 7.0
		)

		var height := randf_range(5.0, 9.0)
		var building_size := Vector3(8.0, height, 7.0)

		_create_building(position, building_size, i)

	for i in range(28):
		var angle := TAU * float(i) / 28.0

		var position := Vector3(
			cos(angle) * randf_range(34.0, 45.0),
			0.0,
			sin(angle) * randf_range(34.0, 45.0)
		)

		_create_tree(position)


func _create_building(
	position: Vector3,
	size: Vector3,
	index: int
) -> void:
	var colors := [
		Color(0.55, 0.43, 0.32),
		Color(0.48, 0.51, 0.54),
		Color(0.61, 0.55, 0.42)
	]

	var building_color: Color = colors[index % colors.size()]

	_add_static_box(
		"Building_%d" % index,
		position + Vector3(0, size.y * 0.5, 0),
		size,
		building_color
	)

	_add_static_box(
		"BuildingRoof_%d" % index,
		position + Vector3(0, size.y + 0.25, 0),
		Vector3(size.x + 0.6, 0.5, size.z + 0.6),
		Color(0.20, 0.25, 0.29)
	)


func _create_tree(position: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()

	cylinder.top_radius = 0.22
	cylinder.bottom_radius = 0.35
	cylinder.height = 2.4

	trunk.mesh = cylinder
	trunk.position = position + Vector3(0, 1.2, 0)
	trunk.material_override = _make_material(
		Color(0.25, 0.16, 0.10)
	)
	add_child(trunk)

	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()

	sphere.radius = 1.7
	sphere.height = 3.4

	crown.mesh = sphere
	crown.position = position + Vector3(0, 3.0, 0)
	crown.material_override = _make_material(
		Color(0.12, 0.31, 0.17)
	)
	add_child(crown)


func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "MainPlayer"
	player.position = Vector3(0, 1.2, 13)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()

	capsule.radius = 0.42
	capsule.height = 1.8

	body.mesh = capsule
	body.position.y = 0.9
	body.material_override = _make_material(
		Color(0.08, 0.68, 0.86)
	)
	player.add_child(body)

	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()

	capsule_shape.radius = 0.42
	capsule_shape.height = 1.8

	collision.shape = capsule_shape
	collision.position.y = 0.9
	player.add_child(collision)

	add_child(player)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	player.add_child(camera_pivot)

	world_camera = Camera3D.new()
	world_camera.position = Vector3(0, 3.0, 7.5)
	world_camera.rotation.x = -0.22
	world_camera.current = true

	camera_pivot.add_child(world_camera)


func _create_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	status_label = Label.new()
	status_label.position = Vector2(22, 18)
	status_label.add_theme_font_size_override("font_size", 23)

	status_label.add_theme_color_override(
		"font_color",
		Color(0.75, 0.94, 1.0)
	)
	layer.add_child(status_label)

	var instructions := Label.new()
	instructions.text = "اسحب يسار الشاشة للحركة • اسحب يمينها لتحريك الكاميرا"
	instructions.position = Vector2(22, 55)
	instructions.add_theme_font_size_override("font_size", 17)

	instructions.add_theme_color_override(
		"font_color",
		Color(0.95, 0.95, 0.95)
	)
	layer.add_child(instructions)


func _connect_npc_society() -> void:
	if not ResourceLoader.exists(NPC_MANAGER_PATH):
		push_warning("NPC Society Manager script was not found.")
		return

	var manager_script = load(NPC_MANAGER_PATH)

	if manager_script == null:
		push_warning("NPC Society Manager could not be loaded.")
		return

	npc_manager = manager_script.new()
	npc_manager.name = "NPC_Society_Manager"
	add_child(npc_manager)

	if npc_manager.has_method("setup"):
		npc_manager.call("setup", self)


func _connect_world_save_manager() -> void:
	if not ResourceLoader.exists(SAVE_MANAGER_PATH):
		push_warning("World Save Manager script was not found.")
		return

	var manager_script = load(SAVE_MANAGER_PATH)

	if manager_script == null:
		push_warning("World Save Manager could not be loaded.")
		return

	save_manager = manager_script.new()
	save_manager.name = "World_Save_Manager"
	add_child(save_manager)

	if is_instance_valid(npc_manager):
		if save_manager.has_method("restore_npc_manager"):
			var restored: bool = save_manager.call(
				"restore_npc_manager",
				npc_manager
			)

			if restored:
				print("SYSTEM WORLD: NPC data restored.")
			else:
				print(
					"SYSTEM WORLD: No compatible NPC save was restored."
				)


func _update_autosave(delta: float) -> void:
	if not is_instance_valid(save_manager):
		return

	if not is_instance_valid(npc_manager):
		return

	autosave_timer += delta

	if autosave_timer >= AUTOSAVE_INTERVAL:
		autosave_timer = 0.0
		_save_world_progress()


func _save_world_progress() -> void:
	if not is_instance_valid(save_manager):
		return

	if not is_instance_valid(npc_manager):
		return

	if save_manager.has_method("save_npc_manager"):
		var saved: bool = save_manager.call(
			"save_npc_manager",
			npc_manager
		)

		if saved:
			print("SYSTEM WORLD: NPC progress saved.")
		else:
			push_warning(
				"SYSTEM WORLD save failed: " +
				str(save_manager.get("last_error"))
			)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_world_progress()
		get_tree().quit()


func _add_static_box(
	object_name: String,
	position: Vector3,
	size: Vector3,
	color: Color
) -> void:
	var body := StaticBody3D.new()
	body.name = object_name
	body.position = position

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()

	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = _make_material(color)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()

	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	add_child(body)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
