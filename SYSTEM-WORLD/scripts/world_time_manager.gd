
extends Node

class_name SystemWorldTimeManager

const UPDATE_INTERVAL := 1.0

var world_root: Node3D
var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var sky_material: ProceduralSkyMaterial

var elapsed := 0.0
var current_hour := 12.0


func setup(target_world: Node3D) -> bool:
	world_root = target_world

	if world_root == null:
		push_warning("SYSTEM Time Manager: world root is missing.")
		return false

	world_environment = world_root.get_node_or_null(
		"ModernCityEnvironment"
	) as WorldEnvironment

	sun = world_root.get_node_or_null(
		"ModernCitySun"
	) as DirectionalLight3D

	if world_environment == null or sun == null:
		push_warning("SYSTEM Time Manager: environment or sun is missing.")
		return false

	if world_environment.environment == null:
		return false

	sky_material = (
		world_environment.environment.sky.sky_material
		as ProceduralSkyMaterial
	)

	if sky_material == null:
		push_warning("SYSTEM Time Manager: procedural sky is missing.")
		return false

	_update_clock()
	return true


func _process(delta: float) -> void:
	if world_environment == null or sun == null:
		return

	elapsed += delta

	if elapsed < UPDATE_INTERVAL:
		return

	elapsed = 0.0
	_update_clock()


func _update_clock() -> void:
	var datetime := Time.get_datetime_dict_from_system(false)

	current_hour = (
		float(datetime.get("hour", 12))
		+ float(datetime.get("minute", 0)) / 60.0
		+ float(datetime.get("second", 0)) / 3600.0
	)

	_apply_day_night_cycle(current_hour)


func _apply_day_night_cycle(hour: float) -> void:
	var environment := world_environment.environment

	var sun_curve := sin(
		(hour - 6.0) / 12.0 * PI
	)

	var daylight := clampf(sun_curve, 0.0, 1.0)

	var elevation := clampf(
		sun_curve * 70.0,
		-18.0,
		70.0
	)

	var dawn_factor := maxf(
		1.0 - absf(hour - 6.0) / 3.0,
		1.0 - absf(hour - 18.0) / 3.0
	)

	dawn_factor = clampf(dawn_factor, 0.0, 1.0)

	# حركة الشمس بحسب ساعة الجهاز المحلية.
	sun.rotation_degrees = Vector3(
		-elevation,
		-30.0,
		0.0
	)

	# شدة ضوء الشمس.
	sun.light_energy = lerpf(
		0.04,
		1.2,
		daylight
	)

	sun.light_color = Color(
		1.0,
		0.72 + daylight * 0.18,
		0.48 + daylight * 0.42
	)

	# إضاءة السماء والبيئة.
	environment.ambient_light_energy = lerpf(
		0.18,
		0.75,
		daylight
	)

	environment.background_energy_multiplier = lerpf(
		0.22,
		1.0,
		daylight
	)

	# ألوان السماء بين الليل والنهار.
	sky_material.sky_top_color = Color(
		0.012,
		0.025,
		0.075
	).lerp(
		Color(0.12, 0.38, 0.72),
		daylight
	)

	sky_material.sky_horizon_color = Color(
		0.025,
		0.035,
		0.085
	).lerp(
		Color(0.68, 0.78, 0.88),
		daylight
	)

	# ألوان الشروق والغروب.
	sky_material.sky_horizon_color = sky_material.sky_horizon_color.lerp(
		Color(1.0, 0.43, 0.20),
		dawn_factor * 0.65
	)

	environment.ambient_light_color = Color(
		0.12,
		0.16,
		0.30
	).lerp(
		Color(0.72, 0.78, 0.88),
		daylight
	)

	environment.fog_light_color = Color(
		0.055,
		0.075,
		0.14
	).lerp(
		Color(0.58, 0.68, 0.78),
		daylight
	)

	environment.fog_density = lerpf(
		0.0022,
		0.0012,
		daylight
	)


func get_current_hour() -> float:
	return current_hour


func get_time_label() -> String:
	var hour := int(floor(current_hour))
	var minute := int(
		floor((current_hour - float(hour)) * 60.0)
	)

	return "%02d:%02d" % [hour, minute]
