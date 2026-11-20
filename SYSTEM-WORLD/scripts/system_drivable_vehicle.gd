extends VehicleBody3D
class_name SystemDrivableVehicle

const ENGINE_FORCE_MAX := 1250.0
const BRAKE_FORCE_MAX := 32.0
const STEERING_LIMIT := 0.48

var vehicle_id := "city_sedan"
var control_enabled := false
var max_forward_speed := 40.0
var max_reverse_speed := 12.0
var mobile_throttle := 0.0
var mobile_steering := 0.0
var mobile_brake := 0.0
var paint_color := Color(0.08, 0.28, 0.48)

func configure(vehicle_data: Dictionary, requested_id: String = "city_sedan") -> void:
	vehicle_id = requested_id
	max_forward_speed = maxf(12.0, float(vehicle_data.get("max_speed", 145)) / 3.6)
	mass = 1450.0
	_build_chassis()
	_add_wheel(Vector3(-0.92, -0.28, -1.35), true, "FrontLeft")
	_add_wheel(Vector3(0.92, -0.28, -1.35), true, "FrontRight")
	_add_wheel(Vector3(-0.92, -0.28, 1.25), false, "RearLeft")
	_add_wheel(Vector3(0.92, -0.28, 1.25), false, "RearRight")
	center_of_mass = Vector3(0.0, -0.35, 0.0)

func set_paint_color(color: Color) -> void:
	paint_color = color
	var chassis := get_node_or_null("VehicleChassisVisual") as MeshInstance3D
	if chassis != null and chassis.material_override is StandardMaterial3D:
		var material := (chassis.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		material.albedo_color = paint_color
		chassis.material_override = material

func _physics_process(_delta: float) -> void:
	if not control_enabled:
		engine_force = 0.0
		brake = 8.0
		steering = 0.0
		return
	var throttle := mobile_throttle
	var reverse := 0.0
	var steer := mobile_steering
	var braking := mobile_brake
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle = 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		reverse = 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer = 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer = -1.0
	if Input.is_key_pressed(KEY_SPACE):
		braking = 1.0
	var speed_kmh := linear_velocity.length() * 3.6
	var drive := throttle - reverse
	if speed_kmh >= max_forward_speed * 3.6 and drive > 0.0:
		drive = 0.0
	if speed_kmh >= max_reverse_speed * 3.6 and drive < 0.0:
		drive = 0.0
	engine_force = drive * ENGINE_FORCE_MAX
	brake = braking * BRAKE_FORCE_MAX
	steering = clampf(steer, -1.0, 1.0) * STEERING_LIMIT

func set_mobile_controls(throttle: float, steering_value: float, brake_value: float) -> void:
	mobile_throttle = clampf(throttle, -1.0, 1.0)
	mobile_steering = clampf(steering_value, -1.0, 1.0)
	mobile_brake = clampf(brake_value, 0.0, 1.0)

func set_driver_active(active: bool) -> void:
	control_enabled = active
	if not active:
		mobile_throttle = 0.0
		mobile_steering = 0.0
		mobile_brake = 0.0
		engine_force = 0.0
		steering = 0.0
		brake = 8.0

func _build_chassis() -> void:
	var chassis := MeshInstance3D.new()
	chassis.name = "VehicleChassisVisual"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.9, 0.62, 4.2)
	chassis.mesh = mesh
	chassis.position.y = 0.25
	var material := StandardMaterial3D.new()
	material.albedo_color = paint_color
	material.metallic = 0.72
	material.roughness = 0.28
	chassis.material_override = material
	add_child(chassis)
	var collision := CollisionShape3D.new()
	collision.name = "VehicleChassisCollision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.85, 0.62, 4.05)
	collision.shape = shape
	collision.position.y = 0.25
	add_child(collision)

func _add_wheel(wheel_position: Vector3, front: bool, wheel_name: String) -> void:
	var wheel := VehicleWheel3D.new()
	wheel.name = wheel_name
	wheel.position = wheel_position
	wheel.use_as_steering = front
	wheel.use_as_traction = not front
	wheel.wheel_radius = 0.36
	wheel.wheel_rest_length = 0.18
	wheel.suspension_travel = 0.16
	wheel.suspension_stiffness = 28.0
	wheel.damping_compression = 0.35
	wheel.damping_relaxation = 0.42
	wheel.wheel_friction_slip = 3.0
	add_child(wheel)
	var visual := MeshInstance3D.new()
	visual.name = wheel_name + "Visual"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.34
	cylinder.bottom_radius = 0.34
	cylinder.height = 0.22
	visual.mesh = cylinder
	visual.rotation.z = PI * 0.5
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.035, 0.035, 0.04)
	visual.material_override = rubber
	wheel.add_child(visual)
