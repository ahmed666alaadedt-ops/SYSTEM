extends Node3D
class_name HunterHelicopterPadController

const APPROACH_DISTANCE := 38.0
const LANDING_RADIUS := 18.0
const MAX_HORIZONTAL_SPEED := 22.0
const MAX_VERTICAL_SPEED := 8.0
const ACCELERATION := 10.0
const DRAG := 5.5

var player: Node3D
var aircraft: Node3D
var aircraft_body: MeshInstance3D
var main_rotor: Node3D
var tail_rotor: Node3D
var hud: CanvasLayer
var status_label: Label
var interact_button: Button
var control_buttons: Dictionary = {}
var pilot_active := false
var landed := true
var horizontal_velocity := Vector3.ZERO
var vertical_velocity := 0.0
var input_vector := Vector2.ZERO
var vertical_input := 0.0
var heli_position := Vector3.ZERO

func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	_create_parked_helicopter()
	_create_touch_hud()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("system_player")
		if not players.is_empty():
			player = players[0] as Node3D
	if pilot_active:
		_update_flight(delta)
	else:
		_update_proximity()
	if is_instance_valid(main_rotor):
		main_rotor.rotate_y(delta * (42.0 if pilot_active else 2.0))
	if is_instance_valid(tail_rotor):
		tail_rotor.rotate_z(delta * (52.0 if pilot_active else 2.0))

func _create_parked_helicopter() -> void:
	aircraft = Node3D.new()
	aircraft.name = "HunterAssociationHelicopter"
	add_child(aircraft)
	aircraft.position = Vector3(0.0, 2.0, 0.0)
	heli_position = aircraft.global_position
	var body := MeshInstance3D.new()
	body.name = "HelicopterFuselage"
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 2.4
	body_mesh.height = 3.2
	body.mesh = body_mesh
	body.scale = Vector3(1.0, 0.72, 1.8)
	body.material_override = _make_material(Color(0.12, 0.22, 0.29), 0.42)
	aircraft.add_child(body)
	aircraft_body = body
	_add_box(aircraft, "CockpitNose", Vector3(0.0, 0.0, -2.5), Vector3(2.3, 1.35, 2.1), Color(0.18, 0.48, 0.62))
	_add_box(aircraft, "TailBoom", Vector3(0.0, 0.15, 4.0), Vector3(0.48, 0.55, 5.8), Color(0.16, 0.24, 0.30))
	_add_box(aircraft, "TailFin", Vector3(0.0, 1.0, 6.5), Vector3(0.35, 2.2, 1.0), Color(0.78, 0.56, 0.22))
	_add_box(aircraft, "LandingSkidLeft", Vector3(-1.7, -1.25, 0.0), Vector3(0.18, 0.18, 5.0), Color(0.72, 0.76, 0.78))
	_add_box(aircraft, "LandingSkidRight", Vector3(1.7, -1.25, 0.0), Vector3(0.18, 0.18, 5.0), Color(0.72, 0.76, 0.78))
	main_rotor = Node3D.new()
	main_rotor.name = "MainRotor"
	main_rotor.position.y = 1.8
	aircraft.add_child(main_rotor)
	_add_box(main_rotor, "RotorBladeA", Vector3(0.0, 0.0, 0.0), Vector3(0.35, 0.12, 13.0), Color(0.12, 0.15, 0.17))
	var blade_b := MeshInstance3D.new()
	blade_b.name = "RotorBladeB"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.35, 0.12, 13.0)
	blade_b.mesh = blade_mesh
	blade_b.rotation.y = PI * 0.5
	blade_b.material_override = _make_material(Color(0.12, 0.15, 0.17), 0.6)
	main_rotor.add_child(blade_b)
	tail_rotor = Node3D.new()
	tail_rotor.name = "TailRotor"
	tail_rotor.position = Vector3(0.0, 0.65, 6.65)
	aircraft.add_child(tail_rotor)
	_add_box(tail_rotor, "TailRotorBladeA", Vector3.ZERO, Vector3(0.12, 2.2, 0.18), Color(0.14, 0.17, 0.18))
	_add_box(tail_rotor, "TailRotorBladeB", Vector3.ZERO, Vector3(0.12, 2.2, 0.18), Color(0.14, 0.17, 0.18), Vector3(0.0, 0.0, PI * 0.5))
	aircraft.set_meta("system_vehicle_type", "hunter_association_helicopter")
	aircraft.set_meta("system_owner_tower_id", "hunter_association_tower_baghdad")

func _create_touch_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HunterHelicopterTouchHUD"
	add_child(hud)
	status_label = Label.new()
	status_label.position = Vector2(18.0, 18.0)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.text = "Hunter Association — Helicopter Pad"
	hud.add_child(status_label)
	interact_button = Button.new()
	interact_button.text = "Enter Helicopter"
	interact_button.position = Vector2(18.0, 58.0)
	interact_button.size = Vector2(210.0, 54.0)
	interact_button.visible = false
	interact_button.pressed.connect(_toggle_pilot)
	hud.add_child(interact_button)
	_add_hold_button("forward", "Forward", Vector2(-220.0, -150.0), Vector2(100.0, 54.0))
	_add_hold_button("back", "Back", Vector2(-220.0, -88.0), Vector2(100.0, 54.0))
	_add_hold_button("left", "Left", Vector2(-326.0, -88.0), Vector2(100.0, 54.0))
	_add_hold_button("right", "Right", Vector2(-114.0, -88.0), Vector2(100.0, 54.0))
	_add_hold_button("up", "Ascend", Vector2(-326.0, -150.0), Vector2(100.0, 54.0))
	_add_hold_button("down", "Descend", Vector2(-114.0, -150.0), Vector2(100.0, 54.0))
	for key in control_buttons:
		control_buttons[key].visible = false

func _add_hold_button(key: String, caption: String, offset: Vector2, size: Vector2) -> void:
	var button := Button.new()
	button.name = "Heli_" + key
	button.text = caption
	button.size = size
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = offset
	button.button_down.connect(func() -> void: _set_control(key, true))
	button.button_up.connect(func() -> void: _set_control(key, false))
	hud.add_child(button)
	control_buttons[key] = button

func _set_control(key: String, active: bool) -> void:
	match key:
		"forward": input_vector.y = -1.0 if active else 0.0
		"back": input_vector.y = 1.0 if active else 0.0
		"left": input_vector.x = -1.0 if active else 0.0
		"right": input_vector.x = 1.0 if active else 0.0
		"up": vertical_input = 1.0 if active else 0.0
		"down": vertical_input = -1.0 if active else 0.0

func _update_proximity() -> void:
	if not is_instance_valid(player) or not is_instance_valid(interact_button):
		return
	var distance := player.global_position.distance_to(global_position)
	interact_button.visible = distance <= APPROACH_DISTANCE
	if interact_button.visible:
		interact_button.text = "Enter Helicopter" if landed else "Helicopter unavailable"
	status_label.text = "Hunter Association — Helicopter Pad" if distance <= APPROACH_DISTANCE else ""

func _toggle_pilot() -> void:
	if pilot_active:
		if not landed:
			return
		_exit_aircraft()
	else:
		if not is_instance_valid(player) or player.global_position.distance_to(global_position) > APPROACH_DISTANCE:
			return
		_enter_aircraft()

func _enter_aircraft() -> void:
	pilot_active = true
	landed = true
	heli_position = global_position + Vector3(0.0, 2.0, 0.0)
	aircraft.global_position = heli_position
	player.visible = false
	player.set_physics_process(false)
	interact_button.text = "Exit Helicopter"
	interact_button.visible = true
	for key in control_buttons:
		control_buttons[key].visible = true
	status_label.text = "Pilot controls: WASD / arrows, Space ascend, Shift descend"
	_update_camera()

func _exit_aircraft() -> void:
	pilot_active = false
	player.visible = true
	player.set_physics_process(true)
	player.global_position = global_position + Vector3(-22.0, 3.0, 0.0)
	player.velocity = Vector3.ZERO
	for key in control_buttons:
		control_buttons[key].visible = false
	interact_button.text = "Enter Helicopter"
	status_label.text = "Helicopter parked at Hunter Association"

func _update_flight(delta: float) -> void:
	var forward_input := Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var side_input := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if absf(forward_input) < 0.01:
		forward_input = input_vector.y
	if absf(side_input) < 0.01:
		side_input = input_vector.x
	var lift := vertical_input
	if Input.is_key_pressed(KEY_SPACE):
		lift = 1.0
	elif Input.is_key_pressed(KEY_SHIFT):
		lift = -1.0
	var desired := (-aircraft.global_basis.z * forward_input + aircraft.global_basis.x * side_input).normalized() * MAX_HORIZONTAL_SPEED
	if Vector2(forward_input, side_input).length() < 0.05:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, DRAG * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(desired, ACCELERATION * delta)
	vertical_velocity = move_toward(vertical_velocity, lift * MAX_VERTICAL_SPEED, ACCELERATION * delta)
	var turn := side_input * delta * 0.85
	aircraft.rotate_y(-turn)
	heli_position += (horizontal_velocity + Vector3.UP * vertical_velocity) * delta
	var pad_center := global_position + Vector3(0.0, 2.0, 0.0)
	var horizontal_distance := Vector2(heli_position.x - pad_center.x, heli_position.z - pad_center.z).length()
	var altitude := heli_position.y - pad_center.y
	if horizontal_distance <= LANDING_RADIUS and altitude <= 0.0:
		heli_position.y = pad_center.y
		vertical_velocity = 0.0
		if horizontal_velocity.length() < 2.0:
			horizontal_velocity = Vector3.ZERO
			landed = true
	else:
		landed = false
	aircraft.global_position = heli_position
	status_label.text = "LANDED — safe to exit" if landed else "FLIGHT — land inside the marked pad to exit"
	_update_camera()

func _update_camera() -> void:
	var active_camera := get_viewport().get_camera_3d()
	if active_camera == null or not pilot_active:
		return
	active_camera.global_position = aircraft.global_position + aircraft.global_basis.z * 13.0 + Vector3.UP * 6.0
	active_camera.look_at(aircraft.global_position, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if not pilot_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and landed:
			_exit_aircraft()

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = _make_material(color, 0.48)
	parent.add_child(instance)

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.35
	return material

func get_helicopter_status() -> Dictionary:
	return {
		"available": true,
		"pilot_active": pilot_active,
		"landed": landed,
		"owner_tower_id": "hunter_association_tower_baghdad",
		"landing_radius_m": LANDING_RADIUS,
		"aircraft_node": aircraft
	}
