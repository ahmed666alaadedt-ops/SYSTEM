
extends Node
class_name SystemWorldTimeManager

const UPDATE_INTERVAL := 1.0
const NIGHT_LIGHT_RANGE := 18.0
const NIGHT_LIGHT_MAX_ENERGY := 1.35

var world_root: Node3D
var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var sky_material: ProceduralSkyMaterial

var night_lights: Array[OmniLight3D] = []
var world_manager: Node

var elapsed := 0.0
var current_hour := 12.0
var current_daylight := 1.0


# --------------------------------------------------
# WORLD MANAGER CONNECTION
# --------------------------------------------------

func _connect_world_manager() -> void:
	var scene_root := get_parent()

	if scene_root == null:
		return

	world_manager = scene_root.get_node_or_null("WorldManager")

	if world_manager == null:
		push_warning("SYSTEM Time Manager: WorldManager not found.")
		return

	if not world_manager.has_signal("world_changed"):
		push_warning("SYSTEM Time Manager: world_changed signal missing.")
		return

	var callback := Callable(self, "_on_world_changed")

	if not world_manager.is_connected("world_changed", callback):
		world_manager.connect("world_changed", callback)


func _on_world_changed(world_id: int) -> void:
	if world_manager == null:
		return

	if not world_manager.has_method("get_world_root"):
		return

	var next_root := world_manager.call(
		"get_world_root",
		world_id
	) as Node3D

	if next_root == null:
		push_warning("SYSTEM Time Manager: new world root is missing.")
		return

	if next_root == world_root:
		return

	print("SYSTEM: Switching time and atmosphere to ", next_root.name)
	setup(next_root)


# --------------------------------------------------
# SETUP — SUPPORT ALL WORLDS
# --------------------------------------------------

func setup(target_world: Node3D) -> bool:
	if target_world == null:
		push_warning("SYSTEM Time Manager: world root is missing.")
		return false

	world_root = target_world
	world_environment = null
	sun = null
	sky_material = null
	night_lights.clear()
	elapsed = 0.0

	_connect_world_manager()

	_find_or_create_environment()
	_find_or_create_sun()

	if world_environment == null or sun == null:
		push_warning("SYSTEM Time Manager: environment setup failed.")
		return false

	if world_environment.environment == null:
		world_environment.environment = Environment.new()

	var environment := world_environment.environment

	if environment.sky == null:
		environment.background_mode = Environment.BG_SKY
		environment.sky = Sky.new()

	if environment.sky.sky_material == null:
		environment.sky.sky_material = ProceduralSkyMaterial.new()

	sky_material = (
		environment.sky.sky_material
		as ProceduralSkyMaterial
	)

	if sky_material == null:
		sky_material = ProceduralSkyMaterial.new()
		environment.sky.sky_material = sky_material

	_create_world_night_lights()
	_update_clock()

	print("SYSTEM Time Manager: active world = ", world_root.name)

	return true


func _find_or_create_environment() -> void:
	world_environment = null

	if world_root == null:
		return

	var found := world_root.find_children(
		"*",
		"WorldEnvironment",
		true,
		false
	)

	if not found.is_empty():
		world_environment = found[0] as WorldEnvironment

	if world_environment == null:
		world_environment = WorldEnvironment.new()
		world_environment.name = "SystemWorldEnvironment"

		var environment := Environment.new()
		environment.background_mode = Environment.BG_SKY
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.55, 0.65, 0.78)
		environment.ambient_light_energy = 0.65
		environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		environment.fog_enabled = true
		environment.fog_light_color = Color(0.48, 0.57, 0.68)
		environment.fog_density = 0.0015

		var sky := Sky.new()
		var material := ProceduralSkyMaterial.new()
		material.sky_top_color = Color(0.055, 0.12, 0.23)
		material.sky_horizon_color = Color(0.48, 0.57, 0.68)
		material.ground_bottom_color = Color(0.10, 0.12, 0.15)
		material.ground_horizon_color = Color(0.36, 0.40, 0.43)

		sky.sky_material = material
		environment.sky = sky

		world_environment.environment = environment
		world_root.add_child(world_environment)


func _find_or_create_sun() -> void:
	sun = null

	if world_root == null:
		return

	var found := world_root.find_children(
		"*",
		"DirectionalLight3D",
		true,
		false
	)

	if not found.is_empty():
		sun = found[0] as DirectionalLight3D

	if sun == null:
		sun = DirectionalLight3D.new()
		sun.name = "SystemWorldSun"
		sun.rotation_degrees = Vector3(-38.0, -30.0, 0.0)
		sun.shadow_enabled = true
		world_root.add_child(sun)


# --------------------------------------------------
# WORLD NIGHT LIGHTS
# --------------------------------------------------

func _create_world_night_lights() -> void:
	if world_root == null:
		return

	var light_positions: Array[Vector3] = []

	var is_greed_island := (
		world_root.get_node_or_null(
			"GreedIslandEnvironment"
		) != null
	)

	if is_greed_island:
		light_positions = [
			Vector3(-35.0, 5.0, -45.0),
			Vector3(35.0, 5.0, -45.0),
			Vector3(-20.0, 5.0, 5.0),
			Vector3(20.0, 5.0, -90.0),
			Vector3(0.0, 6.0, -70.0),
			Vector3(-40.0, 5.0, -15.0)
		]
	else:
		light_positions = [
			Vector3(-5.35, 5.55, -10.0),
			Vector3(5.35, 5.55, -10.0),
			Vector3(-5.35, 5.55, -54.0),
			Vector3(5.35, 5.55, -54.0),
			Vector3(-5.35, 5.55, -98.0),
			Vector3(5.35, 5.55, -98.0)
		]

	for index in range(light_positions.size()):
		var light_name := "SystemNightLight_%02d" % index

		var existing := world_root.get_node_or_null(
			light_name
		) as OmniLight3D

		if existing != null:
			night_lights.append(existing)
			continue

		var light := OmniLight3D.new()
		light.name = light_name
		light.position = light_positions[index]
		light.light_color = Color(1.0, 0.72, 0.43)
		light.light_energy = 0.0
		light.omni_range = NIGHT_LIGHT_RANGE
		light.shadow_enabled = false
		light.light_specular = 0.25

		world_root.add_child(light)
		night_lights.append(light)


func _update_night_lights(daylight: float) -> void:
	var night_factor := clampf(
		(0.42 - daylight) / 0.42,
		0.0,
		1.0
	)

	night_factor = (
		night_factor
		* night_factor
		* (3.0 - 2.0 * night_factor)
	)

	var target_energy := night_factor * NIGHT_LIGHT_MAX_ENERGY

	for light in night_lights:
		if is_instance_valid(light):
			light.light_energy = target_energy


# --------------------------------------------------
# REAL-TIME CLOCK
# --------------------------------------------------

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


# --------------------------------------------------
# DAY / NIGHT ATMOSPHERE
# --------------------------------------------------

func _apply_day_night_cycle(hour: float) -> void:
	if world_environment == null:
		return

	if sun == null or sky_material == null:
		return

	var environment := world_environment.environment

	if environment == null:
		return

	var sun_curve := sin(
		(hour - 6.0) / 12.0 * PI
	)

	var daylight := clampf(sun_curve, 0.0, 1.0)
	current_daylight = daylight

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

	sun.rotation_degrees = Vector3(
		-elevation,
		-30.0,
		0.0
	)

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

	_update_night_lights(daylight)

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

	sky_material.sky_horizon_color = (
		sky_material.sky_horizon_color.lerp(
			Color(1.0, 0.43, 0.20),
			dawn_factor * 0.65
		)
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


# --------------------------------------------------
# PUBLIC TIME API
# --------------------------------------------------

func get_current_hour() -> float:
	return current_hour


func get_time_label() -> String:
	var hour := int(floor(current_hour))
	var minute := int(
		floor((current_hour - float(hour)) * 60.0)
	)

	return "%02d:%02d" % [hour, minute]


func get_daylight_factor() -> float:
	return current_daylight


func is_night() -> bool:
	return current_daylight < 0.25
