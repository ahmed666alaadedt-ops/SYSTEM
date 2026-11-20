extends Node
class_name SystemVehicleRuntimeManager

signal driving_changed(active: bool, vehicle_id: String)

const VehicleScript = preload("res://scripts/system_drivable_vehicle.gd")
const VehicleCatalogScript = preload("res://scripts/system_vehicle_catalog.gd")

var player: CharacterBody3D
var player_mesh: Node3D
var camera: Camera3D
var spring_arm: SpringArm3D
var garage_manager: SystemPlayerVehicleManager
var world_root: Node3D
var active_vehicle: SystemDrivableVehicle
var is_driving := false
var mobile_throttle := 0.0
var mobile_steering := 0.0
var brake_hold_time := 0.0
var player_mesh_was_visible := true

func setup(
	player_node: CharacterBody3D,
	player_visual: Node3D,
	camera_node: Camera3D,
	camera_arm: SpringArm3D,
	garage: SystemPlayerVehicleManager,
	active_root: Node3D
) -> void:
	player = player_node
	player_mesh = player_visual
	camera = camera_node
	spring_arm = camera_arm
	garage_manager = garage
	world_root = active_root

func _process(delta: float) -> void:
	if not is_driving or not is_instance_valid(active_vehicle):
		return
	if brake_hold_time > 0.0:
		brake_hold_time = maxf(0.0, brake_hold_time - delta)
		active_vehicle.set_mobile_controls(mobile_throttle, mobile_steering, 1.0 if brake_hold_time > 0.0 else 0.0)
	_update_follow_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if is_driving:
			exit_vehicle()
		else:
			try_dealership_interaction()

func try_dealership_interaction() -> bool:
	if not is_instance_valid(player) or garage_manager == null:
		return false
	if is_driving:
		exit_vehicle()
		return true
	if is_instance_valid(active_vehicle):
		if player.global_position.distance_to(active_vehicle.global_position) <= 5.0:
			enter_vehicle()
			return true
		return false
	var dealership := _find_nearest_dealership(18.0)
	if dealership == null:
		return false
	var owned := garage_manager.get_garage()
	if owned.is_empty():
		return false
	var vehicle_id := garage_manager.active_vehicle_id
	if vehicle_id.is_empty() or not owned.has(vehicle_id):
		vehicle_id = owned[0]
	var result := spawn_owned_vehicle(vehicle_id)
	if bool(result.get("success", false)):
		enter_vehicle()
		return true
	return false

func _find_nearest_dealership(max_distance: float) -> Node3D:
	if world_root == null:
		return null
	var region := world_root.get_node_or_null("ModernWorldRegionManager")
	if region == null:
		return null
	var nearest: Node3D
	var nearest_distance := max_distance
	for child in region.get_children():
		if child is Node3D and child.name.ends_with("VehicleDealership"):
			var distance := player.global_position.distance_to(child.global_position)
			if distance <= nearest_distance:
				nearest = child
				nearest_distance = distance
	return nearest

func spawn_owned_vehicle(vehicle_id: String) -> Dictionary:
	if is_instance_valid(active_vehicle):
		return {"success":false,"reason":"VEHICLE_ALREADY_SPAWNED"}
	if garage_manager == null or not garage_manager.get_garage().has(vehicle_id):
		return {"success":false,"reason":"VEHICLE_NOT_OWNED"}
	if world_root == null or player == null:
		return {"success":false,"reason":"WORLD_OR_PLAYER_UNAVAILABLE"}
	var data := VehicleCatalogScript.get_vehicle(vehicle_id)
	if data.is_empty():
		return {"success":false,"reason":"UNKNOWN_VEHICLE"}
	active_vehicle = VehicleScript.new()
	active_vehicle.name = "PlayerVehicle_" + vehicle_id
	active_vehicle.configure(data, vehicle_id)
	world_root.add_child(active_vehicle)
	var forward := -player.global_transform.basis.z
	active_vehicle.global_position = player.global_position + forward * 3.0 + Vector3.UP * 0.8
	active_vehicle.global_rotation.y = player.global_rotation.y
	return {"success":true,"vehicle_id":vehicle_id}

func enter_vehicle() -> bool:
	if is_driving or not is_instance_valid(active_vehicle):
		return false
	if player.global_position.distance_to(active_vehicle.global_position) > 5.0:
		return false
	is_driving = true
	active_vehicle.set_driver_active(true)
	if is_instance_valid(player_mesh):
		player_mesh_was_visible = player_mesh.visible
		player_mesh.visible = false
	for child in player.get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	player.set_meta("system_driving_vehicle", true)
	if is_instance_valid(camera):
		camera.top_level = true
	_update_follow_camera()
	driving_changed.emit(true, active_vehicle.vehicle_id)
	return true

func exit_vehicle() -> bool:
	if not is_driving or not is_instance_valid(active_vehicle):
		return false
	active_vehicle.set_driver_active(false)
	var exit_position := active_vehicle.global_position + active_vehicle.global_transform.basis.x * 2.2 + Vector3.UP * 0.5
	player.global_position = exit_position
	player.velocity = Vector3.ZERO
	player.set_meta("system_driving_vehicle", false)
	for child in player.get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", false)
	if is_instance_valid(player_mesh):
		player_mesh.visible = player_mesh_was_visible
	if is_instance_valid(camera):
		camera.top_level = false
		camera.transform = Transform3D.IDENTITY
	if is_instance_valid(camera):
		camera.current = true
	is_driving = false
	mobile_throttle = 0.0
	mobile_steering = 0.0
	brake_hold_time = 0.0
	driving_changed.emit(false, active_vehicle.vehicle_id)
	return true

func set_mobile_movement(direction: Vector2) -> void:
	if not is_driving or not is_instance_valid(active_vehicle):
		return
	mobile_throttle = clampf(-direction.y, -1.0, 1.0)
	mobile_steering = clampf(direction.x, -1.0, 1.0)
	active_vehicle.set_mobile_controls(mobile_throttle, mobile_steering, 1.0 if brake_hold_time > 0.0 else 0.0)

func apply_mobile_brake() -> void:
	if not is_driving or not is_instance_valid(active_vehicle):
		return
	brake_hold_time = 0.28
	active_vehicle.set_mobile_controls(mobile_throttle, mobile_steering, 1.0)

func _update_follow_camera() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(active_vehicle):
		return
	var behind := active_vehicle.global_transform.basis * Vector3(0.0, 3.0, 7.0)
	camera.global_position = active_vehicle.global_position + behind
	camera.look_at(active_vehicle.global_position + Vector3.UP * 1.0, Vector3.UP)
