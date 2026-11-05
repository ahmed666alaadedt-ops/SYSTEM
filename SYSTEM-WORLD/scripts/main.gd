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
const WorldMapManagerScript = preload("res://scripts/world_map_manager.gd")
const WorldInteractionManagerScript = preload("res://scripts/world_interaction_manager.gd")
const AINPCSocietyManagerScript = preload("res://scripts/ai_npc_society_manager.gd")

var world_manager
var world_map_manager
var interaction_manager
var ai_npc_society_manager

var active_world_root: Node3D

var player: CharacterBody3D
var player_mesh: MeshInstance3D
var camera: Camera3D
var spring_arm: SpringArm3D
var mobile_controls: MobileControls

var interaction_prompt_layer: CanvasLayer
var interaction_prompt_label: Label

var mobile_direction := Vector2.ZERO
var jump_requested := false

var camera_yaw := 0.0
var camera_pitch := deg_to_rad(-10.0)
var first_person := false


func _ready() -> void:
	create_world_manager()
	create_ai_npc_society_manager()
	create_world_map_manager()

	create_environment()
	create_ground()
	create_player()

	create_interaction_manager()
	create_mobile_controls()
	create_interaction_prompt()

	update_camera_mode()


func create_world_manager() -> void:
	world_manager = WorldManagerScript.new()
	world_manager.name = "WorldManager"
	add_child(world_manager)

	active_world_root = world_manager.get_active_world()


func create_ai_npc_society_manager() -> void:
	ai_npc_society_manager = AINPCSocietyManagerScript.new()
	ai_npc_society_manager.name = "AINPCSocietyManager"
	add_child(ai_npc_society_manager)


func create_world_map_manager() -> void:
	world_map_manager = WorldMapManagerScript.new()
	world_map_manager.name = "WorldMapManager"
	add_child(world_map_manager)

	world_map_manager.map_updated.connect(_on_map_updated)
	world_map_manager.fast_travel_confirmed.connect(_on_fast_travel_confirmed)


func create_interaction_manager() -> void:
	interaction_manager = WorldInteractionManagerScript.new()
	interaction_manager.name = "WorldInteractionManager"
	add_child(interaction_manager)

	interaction_manager.setup(
		player,
		camera,
		world_map_manager,
		world_manager
	)

	interaction_manager.interaction_target_changed.connect(
		_on_interaction_target_changed
	)

	interaction_manager.interaction_performed.connect(
		_on_interaction_performed
	)

	interaction_manager.location_discovered.connect(
		_on_location_discovered
	)

	interaction_manager.fast_travel_point_activated.connect(
		_on_fast_travel_point_activated
	)


func create_interaction_prompt() -> void:
	interaction_prompt_layer = CanvasLayer.new()
	interaction_prompt_layer.name = "InteractionPromptLayer"
	interaction_prompt_layer.layer = 9
	add_child(interaction_prompt_layer)

	interaction_prompt_label = Label.new()
	interaction_prompt_label.name = "InteractionPrompt"
	interaction_prompt_label.text = ""
	interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	interaction_prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	interaction_prompt_label.position = Vector2(-180, 85)
	interaction_prompt_label.size = Vector2(360, 55)

	interaction_prompt_label.add_theme_font_size_override("font_size", 22)
	interaction_prompt_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.85, 0.55)
	)

	interaction_prompt_layer.add_child(interaction_prompt_label)
	interaction_prompt_label.hide()


## معرّف الخريطة النصي يطابق رقم العالم الحالي في WorldManager.
func get_current_map_world_id() -> String:
	if world_manager == null:
		return ""

	return str(world_manager.active_world)


## نقطة تسجيل موحدة حتى تسجل العوالم مواقعها في مدير الخريطة.
func register_world_location(
	location_id: String,
	region_id: String,
	display_name: String,
	location_type: int,
	location_position: Vector3,
	is_fast_travel_point: bool = false
) -> bool:
	if world_map_manager == null:
		return false

	return world_map_manager.register_location(
		get_current_map_world_id(),
		location_id,
		region_id,
		display_name,
		location_type,
		location_position,
		is_fast_travel_point
	)


func discover_world_region(region_id: String) -> bool:
	if world_map_manager == null:
		return false

	return world_map_manager.discover_region(
		get_current_map_world_id(),
		region_id
	)


func discover_world_location(location_id: String) -> bool:
	if world_map_manager == null:
		return false

	return world_map_manager.discover_location(
		get_current_map_world_id(),
		location_id
	)


func activate_world_fast_travel_point(
	point_id: String,
	activation_distance: float = 3.0
) -> bool:
	if world_map_manager == null or player == null:
		return false

	return world_map_manager.activate_fast_travel_point(
		get_current_map_world_id(),
		point_id,
		player.global_position,
		activation_distance
	)


## يعيد نتيجة التحقق والوجهة المقترحة؛ لا ينفذ النقل وحده.
func request_world_fast_travel(point_id: String) -> Dictionary:
	if world_map_manager == null:
		return {
			"success": false,
			"reason": "MAP_MANAGER_NOT_READY"
		}

	return world_map_manager.request_fast_travel(
		get_current_map_world_id(),
		point_id
	)


## تستدعى بعد أن ينفذ نظام الحركة نقل اللاعب بنجاح.
func complete_world_fast_travel(point_id: String) -> void:
	if world_map_manager != null:
		world_map_manager.confirm_fast_travel(
			get_current_map_world_id(),
			point_id
		)


func _on_map_updated(world_id: String) -> void:
	print("SYSTEM WORLD map updated for world: ", world_id)


func _on_fast_travel_confirmed(
	world_id: String,
	point_id: String
) -> void:
	print(
		"SYSTEM WORLD fast travel confirmed: ",
		world_id,
		" / ",
		point_id
	)


func _on_interaction_target_changed(
	target: Node,
	prompt: String
) -> void:
	if interaction_prompt_label == null:
		return

	if target == null or prompt.is_empty():
		interaction_prompt_label.hide()
		interaction_prompt_label.text = ""
		return

	interaction_prompt_label.text = prompt + "  [E / USE]"
	interaction_prompt_label.show()


func _on_interaction_performed(
	target: Node,
	location_id: String
) -> void:
	print(
		"SYSTEM interaction performed: ",
		target.name,
		" / ",
		location_id
	)


func _on_location_discovered(
	world_id: String,
	location_id: String
) -> void:
	print(
		"SYSTEM location discovered: ",
		world_id,
		" / ",
		location_id
	)


func _on_fast_travel_point_activated(
	world_id: String,
	point_id: String
) -> void:
	print(
		"SYSTEM fast travel point activated: ",
		world_id,
		" / ",
		point_id
	)


func _on_mobile_interact_pressed() -> void:
	if interaction_manager == null:
		return

	interaction_manager.interact_with_target()


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
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)


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
