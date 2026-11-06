
extends Node

class_name SystemSkyWeatherFlyingManager

# SYSTEM WORLD — Sky, Weather and Flying Creatures
# Godot 4 — Procedural visuals, no external assets required.

const CLOUD_COUNT := 12
const STAR_COUNT := 90
const WEATHER_PARTICLE_COUNT := 100

const WORLD_MODERN := 0
const WORLD_HISTORICAL := 1
const WORLD_FANTASY := 2
const WORLD_GREED_ISLAND := 3

var world_root: Node3D
var visual_root: Node3D
var world_id := WORLD_MODERN

var daylight_factor := 1.0
var current_weather := "clear"
var wind_strength := 0.35
var elapsed := 0.0
var storm_timer := 0.0
var flash_timer := 0.0

var clouds: Array[Dictionary] = []
var stars: Array[MeshInstance3D] = []
var weather_particles: Array[Dictionary] = []
var flying_creatures: Array[Dictionary] = []

var moon: MeshInstance3D
var moon_light: OmniLight3D
var lightning: OmniLight3D


func setup(target_world: Node3D, target_world_id: int = 0) -> bool:
	if target_world == null:
		push_warning("SYSTEM SKY: World root is missing.")
		return false

	_remove_old_visuals()

	world_root = target_world
	world_id = clampi(target_world_id, 0, 3)

	visual_root = Node3D.new()
	visual_root.name = "SystemSkyWeatherVisuals"
	world_root.add_child(visual_root)

	_create_clouds()
	_create_stars()
	_create_moon()
	_create_weather_particles()
	_create_lightning()
	_create_flying_creatures()

	print(
		"SYSTEM SKY: initialized for world ",
		world_id,
		" with ",
		flying_creatures.size(),
		" flying creatures."
	)

	return true


func _remove_old_visuals() -> void:
	if is_instance_valid(visual_root):
		visual_root.queue_free()

	clouds.clear()
	stars.clear()
	weather_particles.clear()
	flying_creatures.clear()

	moon = null
	moon_light = null
	lightning = null


func _process(delta: float) -> void:
	if not is_instance_valid(visual_root):
		return

	elapsed += delta

	_update_clouds(delta)
	_update_stars()
	_update_moon()
	_update_weather(delta)
	_update_flying_creatures(delta)
	_update_lightning(delta)


# --------------------------------------------------
# MATERIALS AND SIMPLE MESHES
# --------------------------------------------------

func _material(
	color: Color,
	roughness: float = 0.85,
	emission: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness

	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission

	return material


func _sphere(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	scale_value: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0

	instance.mesh = mesh
	instance.position = position
	instance.scale = scale_value
	instance.material_override = material

	parent.add_child(instance)
	return instance


func _capsule(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height

	instance.mesh = mesh
	instance.position = position
	instance.material_override = material

	parent.add_child(instance)
	return instance


# --------------------------------------------------
# CLOUDS
# --------------------------------------------------

func _create_clouds() -> void:
	var cloud_material := _material(
		Color(0.88, 0.91, 0.96),
		1.0
	)

	for index in range(CLOUD_COUNT):
		var cloud := Node3D.new()
		cloud.name = "SkyCloud_%02d" % index

		cloud.position = Vector3(
			randf_range(-65.0, 65.0),
			randf_range(25.0, 37.0),
			randf_range(-125.0, 15.0)
		)

		visual_root.add_child(cloud)

		var width := randf_range(5.0, 9.0)

		_sphere(
			cloud,
			"CloudMain",
			Vector3.ZERO,
			Vector3(width, 1.8, width * 0.48),
			cloud_material
		)

		for puff in range(4):
			_sphere(
				cloud,
				"CloudPuff_%02d" % puff,
				Vector3(
					randf_range(-width * 0.65, width * 0.65),
					randf_range(0.2, 1.0),
					randf_range(-1.5, 1.5)
				),
				Vector3(
					randf_range(2.0, 3.5),
					randf_range(1.3, 2.0),
					randf_range(1.8, 3.0)
				),
				cloud_material
			)

		clouds.append({
			"node": cloud,
			"speed": randf_range(0.15, 0.45),
			"origin_y": cloud.position.y
		})


func _update_clouds(delta: float) -> void:
	for data in clouds:
		var cloud: Node3D = data["node"]

		if not is_instance_valid(cloud):
			continue

		cloud.position.x += (
			float(data["speed"])
			* (0.5 + wind_strength)
			* delta
		)

		if cloud.position.x > 85.0:
			cloud.position.x = -85.0

		var cloud_visibility := 1.0

		if current_weather == "storm":
			cloud_visibility = 0.65
		elif current_weather == "rain":
			cloud_visibility = 0.8

		cloud.scale = Vector3.ONE * cloud_visibility


# --------------------------------------------------
# STARS AND MOON
# --------------------------------------------------

func _create_stars() -> void:
	var star_material := _material(
		Color(0.82, 0.90, 1.0),
		0.2,
		1.8
	)

	for index in range(STAR_COUNT):
		var star := MeshInstance3D.new()
		star.name = "SkyStar_%03d" % index

		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.07, 0.13)
		mesh.height = mesh.radius * 2.0

		star.mesh = mesh
		star.material_override = star_material
		star.position = Vector3(
			randf_range(-85.0, 85.0),
			randf_range(30.0, 65.0),
			randf_range(-150.0, 25.0)
		)

		visual_root.add_child(star)
		stars.append(star)


func _create_moon() -> void:
	var moon_material := _material(
		Color(0.82, 0.86, 1.0),
		0.45,
		0.65
	)

	moon = _sphere(
		visual_root,
		"SystemMoon",
		Vector3(45.0, 48.0, -100.0),
		Vector3(5.0, 5.0, 5.0),
		moon_material
	)

	moon_light = OmniLight3D.new()
	moon_light.name = "SystemMoonLight"
	moon_light.position = moon.position
	moon_light.light_color = Color(0.48, 0.58, 1.0)
	moon_light.light_energy = 0.0
	moon_light.omni_range = 65.0
	moon_light.shadow_enabled = false

	visual_root.add_child(moon_light)


func _update_stars() -> void:
	var night_amount := 1.0 - clampf(daylight_factor, 0.0, 1.0)

	for star in stars:
		if is_instance_valid(star):
			star.visible = night_amount > 0.12


func _update_moon() -> void:
	if not is_instance_valid(moon):
		return

	var night_amount := 1.0 - clampf(daylight_factor, 0.0, 1.0)

	moon.visible = night_amount > 0.08

	if is_instance_valid(moon_light):
		moon_light.light_energy = night_amount * 0.32


# --------------------------------------------------
# RAIN AND SNOW — PROCEDURAL PARTICLES
# --------------------------------------------------

func _create_weather_particles() -> void:
	var rain_material := _material(
		Color(0.52, 0.70, 0.95),
		0.25,
		0.2
	)

	var snow_material := _material(
		Color(0.95, 0.97, 1.0),
		0.8,
		0.15
	)

	for index in range(WEATHER_PARTICLE_COUNT):
		var particle := MeshInstance3D.new()
		particle.name = "WeatherParticle_%03d" % index

		var mesh := SphereMesh.new()
		mesh.radius = 0.045
		mesh.height = 0.09

		particle.mesh = mesh
		particle.material_override = rain_material
		particle.visible = false

		particle.position = Vector3(
			randf_range(-35.0, 35.0),
			randf_range(2.0, 35.0),
			randf_range(-90.0, 10.0)
		)

		visual_root.add_child(particle)

		weather_particles.append({
			"node": particle,
			"velocity": randf_range(12.0, 22.0),
			"drift": randf_range(-1.0, 1.0)
		})


func _update_weather(delta: float) -> void:
	var precipitation := (
		current_weather == "rain"
		or current_weather == "storm"
		or current_weather == "snow"
	)

	for data in weather_particles:
		var particle: MeshInstance3D = data["node"]

		if not is_instance_valid(particle):
			continue

		particle.visible = precipitation

		if not precipitation:
			continue

		if current_weather == "snow":
			particle.position.y -= delta * 2.0
			particle.position.x += (
				sin(elapsed + float(data["drift"])) * delta
			)
		else:
			particle.position.y -= (
				delta * float(data["velocity"])
			)

			particle.position.x += (
				wind_strength * delta * 3.0
			)

		if particle.position.y < 0.0:
			particle.position.y = randf_range(18.0, 35.0)
			particle.position.x = randf_range(-35.0, 35.0)
			particle.position.z = randf_range(-90.0, 10.0)


# --------------------------------------------------
# LIGHTNING
# --------------------------------------------------

func _create_lightning() -> void:
	lightning = OmniLight3D.new()
	lightning.name = "SystemStormLightning"
	lightning.position = Vector3(0.0, 30.0, -45.0)
	lightning.light_color = Color(0.72, 0.83, 1.0)
	lightning.light_energy = 0.0
	lightning.omni_range = 100.0
	lightning.shadow_enabled = false

	visual_root.add_child(lightning)


func _update_lightning(delta: float) -> void:
	if not is_instance_valid(lightning):
		return

	if current_weather != "storm":
		lightning.light_energy = 0.0
		return

	storm_timer -= delta
	flash_timer -= delta

	if storm_timer <= 0.0:
		storm_timer = randf_range(3.0, 9.0)
		flash_timer = 0.18

	if flash_timer > 0.0:
		lightning.light_energy = randf_range(1.5, 4.0)
	else:
		lightning.light_energy = 0.0


# --------------------------------------------------
# FLYING CREATURES — WORLD PROFILES
# --------------------------------------------------

func _create_flying_creatures() -> void:
	match world_id:
		WORLD_MODERN:
			_create_bird_group(
				7,
				Color(0.28, 0.30, 0.34),
				Color(0.12, 0.14, 0.18),
				"ModernBird"
			)

		WORLD_HISTORICAL:
			_create_bird_group(
				9,
				Color(0.48, 0.34, 0.20),
				Color(0.25, 0.18, 0.12),
				"HistoricalBird"
			)

		WORLD_FANTASY:
			_create_dragon_group(5, false)

		WORLD_GREED_ISLAND:
			_create_dragon_group(4, true)


func _create_bird_group(
	count: int,
	body_color: Color,
	wing_color: Color,
	prefix: String
) -> void:
	var body_material := _material(body_color)
	var wing_material := _material(wing_color)

	for index in range(count):
		var creature := Node3D.new()
		creature.name = "%s_%02d" % [prefix, index]
		visual_root.add_child(creature)

		_sphere(
			creature,
			"BirdBody",
			Vector3.ZERO,
			Vector3(0.35, 0.25, 0.75),
			body_material
		)

		var left_wing := _sphere(
			creature,
			"LeftWing",
			Vector3(-0.48, 0.0, 0.0),
			Vector3(0.85, 0.09, 0.35),
			wing_material
		)

		var right_wing := _sphere(
			creature,
			"RightWing",
			Vector3(0.48, 0.0, 0.0),
			Vector3(0.85, 0.09, 0.35),
			wing_material
		)

		flying_creatures.append({
			"node": creature,
			"left_wing": left_wing,
			"right_wing": right_wing,
			"kind": "bird",
			"phase": randf() * TAU,
			"speed": randf_range(1.5, 3.0),
			"radius": randf_range(8.0, 22.0),
			"height": randf_range(13.0, 23.0),
			"center": Vector3(
				randf_range(-15.0, 15.0),
				0.0,
				randf_range(-55.0, -25.0)
			)
		})


func _create_dragon_group(count: int, island_style: bool) -> void:
	var body_color := Color(0.16, 0.28, 0.22)
	var wing_color := Color(0.08, 0.12, 0.11)
	var horn_color := Color(0.72, 0.66, 0.48)

	if island_style:
		body_color = Color(0.38, 0.20, 0.48)
		wing_color = Color(0.17, 0.08, 0.25)
		horn_color = Color(0.95, 0.72, 0.35)

	var body_material := _material(body_color, 0.55)
	var wing_material := _material(wing_color, 0.65)
	var horn_material := _material(horn_color, 0.5)

	for index in range(count):
		var dragon := Node3D.new()
		dragon.name = (
			"GreedSkyDragon_%02d" % index
			if island_style
			else "FantasySkyDragon_%02d" % index
		)

		visual_root.add_child(dragon)

		_sphere(
			dragon,
			"DragonBody",
			Vector3.ZERO,
			Vector3(1.0, 0.85, 2.1),
			body_material
		)

		_sphere(
			dragon,
			"DragonHead",
			Vector3(0.0, 0.2, -1.35),
			Vector3(0.65, 0.58, 0.85),
			body_material
		)

		_sphere(
			dragon,
			"DragonTail",
			Vector3(0.0, -0.12, 1.55),
			Vector3(0.25, 0.25, 1.65),
			body_material
		)

		var left_wing := Node3D.new()
		left_wing.name = "LeftDragonWing"
		left_wing.position = Vector3(-0.48, 0.25, 0.0)
		dragon.add_child(left_wing)

		_sphere(
			left_wing,
			"WingSurface",
			Vector3(-1.0, 0.0, 0.1),
			Vector3(1.8, 0.12, 1.0),
			wing_material
		)

		_capsule(
			left_wing,
			"WingBone",
			Vector3(-1.45, 0.05, 0.0),
			0.07,
			2.4,
			horn_material
		)

		var right_wing := Node3D.new()
		right_wing.name = "RightDragonWing"
		right_wing.position = Vector3(0.48, 0.25, 0.0)
		dragon.add_child(right_wing)

		_sphere(
			right_wing,
			"WingSurface",
			Vector3(1.0, 0.0, 0.1),
			Vector3(1.8, 0.12, 1.0),
			wing_material
		)

		_capsule(
			right_wing,
			"WingBone",
			Vector3(1.45, 0.05, 0.0),
			0.07,
			2.4,
			horn_material
		)

		for side in [-1.0, 1.0]:
			var horn := _capsule(
				dragon,
				"DragonHorn",
				Vector3(side * 0.28, 0.62, -1.55),
				0.10,
				0.75,
				horn_material
			)
			horn.rotation.z = side * 0.45

		flying_creatures.append({
			"node": dragon,
			"left_wing": left_wing,
			"right_wing": right_wing,
			"kind": "dragon",
			"phase": randf() * TAU,
			"speed": randf_range(0.65, 1.2),
			"radius": randf_range(15.0, 30.0),
			"height": randf_range(24.0, 37.0),
			"center": Vector3(
				randf_range(-10.0, 10.0),
				0.0,
				randf_range(-60.0, -30.0)
			)
		})


func _update_flying_creatures(delta: float) -> void:
	for data in flying_creatures:
		var creature: Node3D = data["node"]

		if not is_instance_valid(creature):
			continue

		var phase: float = data["phase"]
		phase += float(data["speed"]) * delta
		data["phase"] = phase

		var center: Vector3 = data["center"]
		var radius: float = data["radius"]
		var height: float = data["height"]

		creature.position = center + Vector3(
			cos(phase) * radius,
			height + sin(phase * 1.8) * 1.8,
			sin(phase) * radius
		)

		creature.rotation.y = -phase

		var flap_speed := 7.0

		if data["kind"] == "dragon":
			flap_speed = 3.0

		var flap := sin(elapsed * flap_speed + phase) * 0.48

		var left_wing: Node3D = data["left_wing"]
		var right_wing: Node3D = data["right_wing"]

		left_wing.rotation.z = flap
		right_wing.rotation.z = -flap


# --------------------------------------------------
# PUBLIC WEATHER AND WORLD API
# --------------------------------------------------

func set_weather(weather_name: String) -> void:
	var allowed := [
		"clear",
		"cloudy",
		"rain",
		"snow",
		"storm"
	]

	if not allowed.has(weather_name):
		push_warning("SYSTEM SKY: Unknown weather: " + weather_name)
		return

	current_weather = weather_name

	match current_weather:
		"clear":
			wind_strength = 0.25
		"cloudy":
			wind_strength = 0.45
		"rain":
			wind_strength = 0.8
		"snow":
			wind_strength = 0.35
		"storm":
			wind_strength = 1.5

	print("SYSTEM SKY: weather changed to ", current_weather)


func set_daylight_factor(value: float) -> void:
	daylight_factor = clampf(value, 0.0, 1.0)


func set_world_profile(target_world_id: int) -> void:
	if world_root == null:
		return

	setup(world_root, target_world_id)


func get_current_weather() -> String:
	return current_weather


func get_flying_creature_count() -> int:
	return flying_creatures.size()
