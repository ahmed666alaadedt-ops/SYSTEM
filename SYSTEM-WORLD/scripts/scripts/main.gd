extends Node3D

const PLAYER_SPEED := 6.0
const JUMP_FORCE := 4.5
const GRAVITY := 9.8

var player: CharacterBody3D
var camera: Camera3D


func _ready() -> void:
	create_environment()
	create_ground()
	create_player()


func create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.72, 0.85)
	environment.ambient_light_energy = 0.7

	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.2
	add_child(sun)


func create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)

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
	add_child(player)

	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh.mesh = capsule

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.55, 0.95)
	mesh.material_override = material
	player.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape
	player.add_child(collision)

	var spring_arm := SpringArm3D.new()
	spring_arm.spring_length = 5.0
	spring_arm.position = Vector3(0, 1.2, 0)
	player.add_child(spring_arm)

	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 0)
	spring_arm.add_child(camera)
	camera.current = true


func _physics_process(delta: float) -> void:
	if player == null:
		return

	var direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direction.z -= 1
	if Input.is_key_pressed(KEY_S):
		direction.z += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	direction = direction.normalized()
	direction = player.global_transform.basis * direction
	direction.y = 0
	direction = direction.normalized()

	player.velocity.x = direction.x * PLAYER_SPEED
	player.velocity.z = direction.z * PLAYER_SPEED

	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif Input.is_key_pressed(KEY_SPACE):
		player.velocity.y = JUMP_FORCE

	player.move_and_slide()
