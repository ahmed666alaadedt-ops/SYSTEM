
extends Node
class_name SystemWorldInteractionManager

## نظام التفاعل مع المواقع والشخصيات واكتشافها داخل العالم.

signal interaction_target_changed(target: Node, prompt: String)
signal interaction_performed(target: Node, location_id: String)
signal location_discovered(world_id: String, location_id: String)
signal fast_travel_point_activated(world_id: String, point_id: String)

const INTERACT_ACTION := "system_interact"

@export_range(1.0, 20.0, 0.5)
var interaction_distance: float = 4.0

var player: CharacterBody3D
var camera: Camera3D
var world_map_manager: Node
var world_manager: Node

var current_target: Node
var current_prompt := "تفاعل"


func setup(
	p_player: CharacterBody3D,
	p_camera: Camera3D,
	p_world_map_manager: Node,
	p_world_manager: Node
) -> void:
	player = p_player
	camera = p_camera
	world_map_manager = p_world_map_manager
	world_manager = p_world_manager

	_setup_input_action()


func _ready() -> void:
	_setup_input_action()


func _setup_input_action() -> void:
	if not InputMap.has_action(INTERACT_ACTION):
		InputMap.add_action(INTERACT_ACTION)

	var has_keyboard_key := false
	var has_gamepad_button := false

	for event in InputMap.action_get_events(INTERACT_ACTION):
		if event is InputEventKey:
			if event.physical_keycode == KEY_E:
				has_keyboard_key = true

		if event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_A:
				has_gamepad_button = true

	if not has_keyboard_key:
		var keyboard_event := InputEventKey.new()
		keyboard_event.physical_keycode = KEY_E
		InputMap.action_add_event(INTERACT_ACTION, keyboard_event)

	if not has_gamepad_button:
		var gamepad_event := InputEventJoypadButton.new()
		gamepad_event.button_index = JOY_BUTTON_A
		InputMap.action_add_event(INTERACT_ACTION, gamepad_event)


func _physics_process(_delta: float) -> void:
	if player == null or camera == null:
		return

	_update_interaction_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INTERACT_ACTION):
		interact_with_target()
		get_viewport().set_input_as_handled()


## تحديد العنصر الموجود أمام الكاميرا.
func _update_interaction_target() -> void:
	var detected_target := _find_target_in_front()

	if detected_target == current_target:
		return

	current_target = detected_target

	if current_target == null:
		current_prompt = "تفاعل"
		interaction_target_changed.emit(null, "")
		return

	current_prompt = _get_target_prompt(current_target)
	interaction_target_changed.emit(current_target, current_prompt)


func _find_target_in_front() -> Node:
	var space_state := camera.get_world_3d().direct_space_state

	var ray_start := camera.global_position
	var ray_end := ray_start + (-camera.global_transform.basis.z * interaction_distance)

	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end
	)

	query.collide_with_areas = true
	query.collide_with_bodies = true

	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]

	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return null

	var collider: Object = result.get("collider")

	if not collider is Node:
		return null

	return _resolve_interactable(collider as Node)


## البحث عن العنصر القابل للتفاعل في العقدة أو أحد آبائها.
func _resolve_interactable(node: Node) -> Node:
	var candidate := node

	while candidate != null:
		if candidate.is_in_group("system_interactable"):
			return candidate

		if candidate.has_meta("system_location_id"):
			return candidate

		candidate = candidate.get_parent()

	return null


func _get_target_prompt(target: Node) -> String:
	if target.has_meta("system_interaction_prompt"):
		return str(target.get_meta("system_interaction_prompt"))

	return "تفاعل"


## تنفيذ التفاعل واكتشاف الموقع إن كانت بياناته موجودة.
func interact_with_target() -> bool:
	if current_target == null:
		return false

	if not is_instance_valid(current_target):
		current_target = null
		return false

	var target := current_target
	var world_id := _get_current_world_id()

	if world_id.is_empty():
		return false

	var location_id := str(
		target.get_meta("system_location_id", "")
	)

	if not location_id.is_empty():
		_register_and_discover_location(
			target,
			world_id,
			location_id
		)

	interaction_performed.emit(target, location_id)

	if target.has_method("system_interact"):
		target.call("system_interact")

	return true


func _register_and_discover_location(
	target: Node,
	world_id: String,
	location_id: String
) -> void:
	if world_map_manager == null:
		return

	var region_id := str(
		target.get_meta("system_region_id", "")
	)

	var display_name := str(
		target.get_meta("system_display_name", target.name)
	)

	if region_id.is_empty():
		push_warning(
			"SYSTEM interaction: missing region ID on " + target.name
		)
		return

	var location_type := int(
		target.get_meta("system_location_type", 7)
	)

	var is_fast_travel := bool(
		target.get_meta("system_fast_travel", false)
	)

	var location_position := Vector3.ZERO

	if target is Node3D:
		location_position = (target as Node3D).global_position

	# التسجيل آمن عند تكراره؛ مدير الخريطة يرفض المعرف المكرر.
	world_map_manager.call(
		"register_location",
		world_id,
		location_id,
		region_id,
		display_name,
		location_type,
		location_position,
		is_fast_travel
	)

	var region_was_discovered := bool(
		world_map_manager.call(
			"discover_region",
			world_id,
			region_id
		)
	)

	var location_was_discovered := bool(
		world_map_manager.call(
			"discover_location",
			world_id,
			location_id
		)
	)

	if location_was_discovered:
		location_discovered.emit(world_id, location_id)

	# كل نقطة انتقال تحتاج تفعيلها بصورة مستقلة.
	if is_fast_travel and player != null:
		var activated := bool(
			world_map_manager.call(
				"activate_fast_travel_point",
				world_id,
				location_id,
				player.global_position,
				interaction_distance
			)
		)

		if activated:
			fast_travel_point_activated.emit(
				world_id,
				location_id
			)


func _get_current_world_id() -> String:
	if world_manager == null:
		return ""

	var active_world: Variant = world_manager.get("active_world")

	if active_world == null:
		return ""

	return str(active_world)


func clear_interaction_target() -> void:
	current_target = null
	current_prompt = "تفاعل"
	interaction_target_changed.emit(null, "")
