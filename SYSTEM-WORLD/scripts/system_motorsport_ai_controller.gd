extends Node
class_name SystemMotorsportAIController

signal opponent_finished(result: Dictionary)

var vehicle: SystemDrivableVehicle
var opponent_id := ""
var opponent_name := ""
var waypoints: Array[Vector3] = []
var target_checkpoint := 1
var total_laps := 3
var completed_laps := 0
var elapsed_seconds := 0.0
var cruise_speed := 29.0
var active := false
var checkpoint_radius := 17.0

func setup(p_vehicle: SystemDrivableVehicle, p_id: String, p_name: String, p_waypoints: Array[Vector3], p_laps: int, p_speed: float = 29.0) -> void:
	vehicle = p_vehicle
	opponent_id = p_id
	opponent_name = p_name
	waypoints = p_waypoints.duplicate()
	total_laps = maxi(1, p_laps)
	cruise_speed = maxf(12.0, p_speed)
	target_checkpoint = 1 if waypoints.size() > 1 else 0
	active = false
	if is_instance_valid(vehicle):
		vehicle.set_ai_control_enabled(true)
		vehicle.set_ai_controls(0.0, 0.0, 1.0)

func start_race() -> void:
	if is_instance_valid(vehicle) and waypoints.size() >= 2:
		active = true

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(vehicle):
		return
	elapsed_seconds += maxf(0.0, delta)
	var target := waypoints[target_checkpoint]
	target.y = vehicle.global_position.y
	var direction := target - vehicle.global_position
	direction.y = 0.0
	var distance := direction.length()
	if distance <= checkpoint_radius:
		_reach_checkpoint()
		if not active:
			return
		target = waypoints[target_checkpoint]
		target.y = vehicle.global_position.y
		direction = target - vehicle.global_position
		direction.y = 0.0
		distance = direction.length()
	if distance < 0.1:
		vehicle.set_ai_controls(0.0, 0.0, 0.5)
		return
	var local_direction := vehicle.global_transform.basis.inverse() * direction.normalized()
	var heading_error := atan2(local_direction.x, -local_direction.z)
	var speed := vehicle.linear_velocity.length()
	var corner_factor := clampf(1.0 - absf(heading_error) * 0.48, 0.48, 1.0)
	var target_speed := cruise_speed * corner_factor
	if distance < 30.0:
		target_speed *= clampf(distance / 30.0, 0.62, 1.0)
	var braking := clampf((speed - target_speed) / 8.0, 0.0, 1.0)
	var throttle := 0.0 if braking > 0.12 else clampf((target_speed - speed) / 7.0, 0.25, 1.0)
	var steering := clampf(heading_error * 1.65, -1.0, 1.0)
	vehicle.set_ai_controls(throttle, steering, braking)

func _reach_checkpoint() -> void:
	if target_checkpoint == 0:
		completed_laps += 1
	if completed_laps >= total_laps:
		active = false
		vehicle.set_ai_controls(0.0, 0.0, 1.0)
		opponent_finished.emit({
			"opponent_id": opponent_id,
			"opponent_name": opponent_name,
			"vehicle_id": vehicle.vehicle_id,
			"completed_laps": completed_laps,
			"elapsed_seconds": elapsed_seconds,
			"finish_type": "ai_simulated_vehicle"
		})
		return
	target_checkpoint = (target_checkpoint + 1) % waypoints.size()

func stop() -> void:
	active = false
	if is_instance_valid(vehicle):
		vehicle.set_ai_controls(0.0, 0.0, 1.0)
