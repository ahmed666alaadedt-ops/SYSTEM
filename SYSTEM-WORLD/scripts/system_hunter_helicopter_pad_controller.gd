extends Node3D
class_name HunterHelicopterPadController

const APPROACH_DISTANCE := 38.0
const LANDING_RADIUS := 18.0
const MAX_HORIZONTAL_SPEED := 22.0
const MAX_VERTICAL_SPEED := 8.0
const ACCELERATION := 10.0
const DRAG := 5.5

var player: CharacterBody3D
var aircraft: Node3D
var aircraft_body: MeshInstance3D
var main_rotor: Node3D
var tail_rotor: Node3D
var hud: CanvasLayer
var status_label: Label
var interact_button: Button
var emergency_landing_button: Button
var emergency_landing_active := false
var control_buttons: Dictionary = {}
var pressed_controls: Dictionary = {}
var pilot_active := false
var player_physics_was_enabled := true
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
			player = players[0] as CharacterBody3D
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
	_load_parked_state()
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
	emergency_landing_button = Button.new()
	emergency_landing_button.text = "Emergency Landing"
	emergency_landing_button.position = Vector2(18.0, 120.0)
	emergency_landing_button.size = Vector2(210.0, 54.0)
	emergency_landing_button.visible = false
	emergency_landing_button.pressed.connect(_begin_emergency_landing)
	hud.add_child(emergency_landing_button)
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
	pressed_controls[key] = active
	input_vector.x = float(bool(pressed_controls.get("right", false))) - float(bool(pressed_controls.get("left", false)))
	input_vector.y = float(bool(pressed_controls.get("back", false))) - float(bool(pressed_controls.get("forward", false)))
	vertical_input = float(bool(pressed_controls.get("up", false))) - float(bool(pressed_controls.get("down", false)))

func _update_proximity() -> void:
	if not is_instance_valid(player) or not is_instance_valid(interact_button):
		return
	var interaction_anchor := aircraft.global_position if is_instance_valid(aircraft) else global_position
	var distance := player.global_position.distance_to(interaction_anchor)
	interact_button.visible = distance <= APPROACH_DISTANCE
	if interact_button.visible:
		interact_button.text = "Enter Helicopter" if landed else "Helicopter unavailable"
		if not _can_pilot():
			interact_button.text = "Association Staff / A-S-SS-SSS Rank / Level 50+ Required"
	status_label.text = "Hunter Association — Helicopter Pad" if distance <= APPROACH_DISTANCE else ""

func _toggle_pilot() -> void:
	if pilot_active:
		if not landed:
			return
		_exit_aircraft()
	else:
		var interaction_anchor := aircraft.global_position if is_instance_valid(aircraft) else global_position
		if not is_instance_valid(player) or player.global_position.distance_to(interaction_anchor) > APPROACH_DISTANCE:
			return
		if not _can_pilot():
			status_label.text = "Pilot access is restricted to Association staff, A/S/SS/SSS hunters, or level 50+ licensed hunters."
			return
		_enter_aircraft()

func _enter_aircraft() -> void:
	player_physics_was_enabled = player.is_physics_processing()
	pilot_active = true
	landed = true
	heli_position = aircraft.global_position
	player.set_meta("system_helicopter_piloting", true)
	player.visible = false
	player.set_physics_process(false)
	interact_button.text = "Exit Helicopter"
	interact_button.visible = true
	emergency_landing_button.visible = true
	for key in control_buttons:
		control_buttons[key].visible = true
	status_label.text = "Pilot controls: WASD / arrows, Space ascend, Shift descend"
	_update_camera()

func _exit_aircraft() -> void:
	pilot_active = false
	emergency_landing_active = false
	emergency_landing_button.visible = false
	player.set_meta("system_helicopter_piloting", false)
	player.visible = true
	player.set_physics_process(player_physics_was_enabled)
	var exit_anchor := aircraft.global_position + aircraft.global_basis.x * -8.0
	var exit_ground_height: Variant = _get_ground_landing_height(exit_anchor)
	if exit_ground_height != null:
		player.global_position = Vector3(exit_anchor.x, float(exit_ground_height) - 1.8, exit_anchor.z)
	else:
		player.global_position = aircraft.global_position + Vector3(-8.0, -1.8, 0.0)
	player.velocity = Vector3.ZERO
	heli_position = aircraft.global_position
	_save_parked_state()
	for key in control_buttons:
		control_buttons[key].visible = false
	interact_button.text = "Enter Helicopter"
	status_label.text = "Helicopter parked at Hunter Association"

func _begin_emergency_landing() -> void:
	if not pilot_active or landed:
		return
	if _get_ground_landing_height(heli_position) == null:
		status_label.text = "EMERGENCY LANDING UNAVAILABLE — no safe ground detected"
		return
	emergency_landing_active = true
	horizontal_velocity = Vector3.ZERO
	vertical_input = 0.0
	status_label.text = "EMERGENCY LANDING — descending to nearest detected ground"


func _get_ground_landing_height(from_position: Vector3) -> Variant:
	var world := get_world_3d()
	if world == null:
		return null
	var query := PhysicsRayQueryParameters3D.create(
		from_position + Vector3.UP * 4.0,
		from_position - Vector3.UP * 100.0
	)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return float(hit.position.y) + 2.8


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
	if emergency_landing_active:
		forward_input = 0.0
		side_input = 0.0
		lift = -0.45
	var desired := (-aircraft.global_basis.z * forward_input + aircraft.global_basis.x * side_input).normalized() * MAX_HORIZONTAL_SPEED
	if Vector2(forward_input, side_input).length() < 0.05:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, DRAG * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(desired, ACCELERATION * delta)
	vertical_velocity = move_toward(vertical_velocity, lift * MAX_VERTICAL_SPEED, ACCELERATION * delta)
	var turn := side_input * delta * 0.85
	aircraft.rotate_y(-turn)
	var candidate_position := heli_position + (horizontal_velocity + Vector3.UP * vertical_velocity) * delta
	var pad_center := global_position + Vector3(0.0, 2.8, 0.0)
	var horizontal_distance := Vector2(candidate_position.x - pad_center.x, candidate_position.z - pad_center.z).length()
	var altitude := candidate_position.y - pad_center.y
	if emergency_landing_active:
		var ground_height: Variant = _get_ground_landing_height(heli_position)
		if ground_height == null:
			emergency_landing_active = false
			status_label.text = "EMERGENCY LANDING ABORTED — ground not detected"
		else:
			candidate_position.y = maxf(candidate_position.y, float(ground_height))
			if heli_position.y <= float(ground_height) + 0.35:
				candidate_position.y = float(ground_height)
				vertical_velocity = 0.0
				horizontal_velocity = Vector3.ZERO
				landed = true
				emergency_landing_active = false
	elif horizontal_distance <= LANDING_RADIUS and altitude <= 0.0:
		candidate_position.y = pad_center.y
		vertical_velocity = 0.0
		if horizontal_velocity.length() < 2.0:
			horizontal_velocity = Vector3.ZERO
			landed = true
	else:
		landed = false
	if not landed and not _is_aircraft_position_clear(candidate_position):
		horizontal_velocity = Vector3.ZERO
		vertical_velocity = 0.0
		status_label.text = "OBSTACLE — full aircraft clearance blocked"
		_update_camera()
		return
	heli_position = candidate_position
	aircraft.global_position = heli_position
	status_label.text = "LANDED — safe to exit" if landed else ("EMERGENCY LANDING — controlled descent" if emergency_landing_active else "FLIGHT — land inside the marked pad to exit")
	_update_camera()

func _can_pilot() -> bool:
	if not is_instance_valid(player):
		return false

	var association_role := str(player.get_meta("system_hunter_association_role", "")).strip_edges().to_lower()
	# Only senior officials and explicitly certified professional employees may use aircraft.
	if association_role in ["association_director", "association_official", "chief_hunter", "helicopter_pilot"]:
		return true
	if bool(player.get_meta("system_hunter_staff_professional", false)) and association_role in ["professional_employee", "senior_security", "operations_manager", "tower_manager"]:
		return true

	# Hunter pilot privileges begin at S rank. A license or player level alone never substitutes for rank.
	var hunter_rank := str(player.get_meta("system_hunter_rank", "")).strip_edges().to_upper()
	if hunter_rank.is_empty():
		var progression := get_tree().root.find_child("PlayerProgression", true, false)
		if progression != null and progression.has_method("get_hunter_rank"):
			hunter_rank = str(progression.call("get_hunter_rank")).strip_edges().to_upper()
	return hunter_rank in ["S", "SS", "SSS"]

func _load_parked_state() -> void:
	var config := ConfigFile.new()
	if config.load("user://system_hunter_helicopter_parking.cfg") != OK:
		return
	var saved_position: Variant = config.get_value("parking", "local_position", Vector3(0.0, 2.0, 0.0))
	var saved_rotation: Variant = config.get_value("parking", "local_rotation", Vector3.ZERO)
	if typeof(saved_position) != TYPE_VECTOR3 or typeof(saved_rotation) != TYPE_VECTOR3:
		return
	var position_value: Vector3 = saved_position
	if absf(position_value.x) > 250.0 or absf(position_value.z) > 250.0 or position_value.y < -5.0 or position_value.y > 200.0:
		return
	aircraft.position = position_value
	aircraft.rotation = saved_rotation


func _save_parked_state() -> bool:
	if not is_instance_valid(aircraft) or pilot_active or not landed:
		return false
	var config := ConfigFile.new()
	config.set_value("parking", "local_position", aircraft.position)
	config.set_value("parking", "local_rotation", aircraft.rotation)
	return config.save("user://system_hunter_helicopter_parking.cfg") == OK


func _is_aircraft_position_clear(candidate_position: Vector3) -> bool:
	var fuselage_clearance := BoxShape3D.new()
	fuselage_clearance.size = Vector3(5.0, 5.0, 14.0)
	if not _flight_shape_is_clear(fuselage_clearance, Transform3D(aircraft.global_basis, candidate_position)):
		return false
	var rotor_clearance := BoxShape3D.new()
	rotor_clearance.size = Vector3(13.2, 0.35, 13.2)
	var rotor_origin := candidate_position + aircraft.global_basis * Vector3(0.0, 1.8, 0.0)
	if not _flight_shape_is_clear(rotor_clearance, Transform3D(aircraft.global_basis, rotor_origin)):
		return false
	var tail_rotor_clearance := BoxShape3D.new()
	tail_rotor_clearance.size = Vector3(0.35, 2.2, 2.2)
	var tail_rotor_origin := candidate_position + aircraft.global_basis * Vector3(0.0, 0.65, 6.65)
	return _flight_shape_is_clear(tail_rotor_clearance, Transform3D(aircraft.global_basis, tail_rotor_origin))


func _flight_shape_is_clear(shape: Shape3D, shape_transform: Transform3D) -> bool:
	var world := get_world_3d()
	if world == null:
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = shape_transform
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if is_instance_valid(player):
		query.exclude = [player.get_rid()]
	return world.direct_space_state.intersect_shape(query, 12).is_empty()

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
		"pilot_authorized": _can_pilot(),
		"aircraft_node": aircraft
	}
