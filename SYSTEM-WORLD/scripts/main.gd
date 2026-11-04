extends Node3D

const PLAYER_SPEED := 6.0
const JUMP_FORCE := 4.5
const GRAVITY := 9.8

const CAMERA_SENSITIVITY := 0.005
const MIN_CAMERA_PITCH := -60.0
const MAX_CAMERA_PITCH := 35.0
const THIRD_PERSON_DISTANCE := 5.0
const FIRST_PERSON_DISTANCE := 0.0
const ROTATION_SPEED := 10.0

const MobileControlsScript = preload("res://scripts/mobile_controls.gd")
const WorldManagerScript = preload("res://scripts/world_manager.gd")

var world_manager
var active_world_root: Node3D

var player: CharacterBody3D
var player_mesh: MeshInstance3D
var camera: Camera3D
var spring_arm: SpringArm3D
var mobile_controls: MobileControls

var mobile_direction := Vector2.ZERO
var jump_requested := false

var camera_yaw := 0.0
var camera_pitch := deg_to_rad(-10.0)
var first_person := false


func _ready() -> void:
	create_world_manager()

	create_environment()
	create_ground()
	create_player()
	create_mobile_controls()
	update_camera_mode()


func create_world_manager() -> void:
	world_manager = WorldManagerScript.new()
	world_manager.name = "WorldManager"
	add_child(world_manager)

	active_world_root = world_manager.get_active_world()


func create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.72, 0.85)
	environment.ambient_light_energy = 0.7

	world_environment.environment = environment
	active_world_root.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.2
	active_world_root.add_child(sun)


func create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	active_world_root.add_child(ground)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(100, 1, 100)
	mesh.mesh = box

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.28, 0.20)
	mesh.material_override = material
	ground.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100, 1, 100)
	collision.shape = shape
	ground.add_child(collision)


func create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 2, 0)
	active_world_root.add_child(player)

	player_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	player_mesh.mesh = capsule

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.55, 0.95)
	player_mesh.material_override = material
	player.add_child(player_mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape
	player.add_child(collision)

	spring_arm = SpringArm3D.new()
	spring_arm.position = Vector3(0, 0.65, 0)
	spring_arm.spring_length = THIRD_PERSON_DISTANCE
	player.add_child(spring_arm)

	camera = Camera3D.new()
	spring_arm.add_child(camera)
	camera.current = true

	update_camera_rotation()


func create_mobile_controls() -> void:
	mobile_controls = MobileControlsScript.new()
	add_child(mobile_controls)

	mobile_controls.movement_changed.connect(_on_movement_changed)
	mobile_controls.jump_pressed.connect(_on_jump_pressed)
	mobile_controls.look_changed.connect(_on_look_changed)
	mobile_controls.camera_toggle_pressed.connect(_on_camera_toggle_pressed)


func _on_movement_changed(direction: Vector2) -> void:
	mobile_direction = direction


func _on_jump_pressed() -> void:
	jump_requested = true


func _on_look_changed(delta: Vector2) -> void:
	camera_yaw -= delta.x * CAMERA_SENSITIVITY
	camera_pitch -= delta.y * CAMERA_SENSITIVITY

	camera_pitch = clampf(
		camera_pitch,
		deg_to_rad(MIN_CAMERA_PITCH),
		deg_to_rad(MAX_CAMERA_PITCH)
	)

	update_camera_rotation()


func _on_camera_toggle_pressed() -> void:
	first_person = not first_person
	update_camera_mode()


func update_camera_mode() -> void:
	if spring_arm == null:
		return

	if first_person:
		spring_arm.spring_length = FIRST_PERSON_DISTANCE
		player_mesh.visible = false
	else:
		spring_arm.spring_length = THIRD_PERSON_DISTANCE
		player_mesh.visible = true

	update_camera_rotation()


func update_camera_rotation() -> void:
	if spring_arm == null:
		return

	spring_arm.rotation = Vector3(
		camera_pitch,
		camera_yaw,
		0.0
	)


func _physics_process(delta: float) -> void:
	if player == null:
		return

	var direction := Vector3.ZERO

	direction.x = mobile_direction.x
	direction.z = mobile_direction.y

	if Input.is_key_pressed(KEY_W):
		direction.z -= 1
	if Input.is_key_pressed(KEY_S):
		direction.z += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	direction = direction.normalized()

	var camera_basis := spring_arm.global_transform.basis
	var forward := -camera_basis.z
	var right := camera_basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var move_direction := right * direction.x
	move_direction += forward * -direction.z
	move_direction = move_direction.normalized()

	player.velocity.x = move_direction.x * PLAYER_SPEED
	player.velocity.z = move_direction.z * PLAYER_SPEED

	if move_direction.length() > 0.01:
		var target_angle := atan2(
			move_direction.x,
			move_direction.z
		)

		player.rotation.y = lerp_angle(
			player.rotation.y,
			target_angle,
			ROTATION_SPEED * delta
		)

	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif jump_requested or Input.is_key_pressed(KEY_SPACE):
		player.velocity.y = JUMP_FORCE

	jump_requested = false
	player.move_and_slide()
