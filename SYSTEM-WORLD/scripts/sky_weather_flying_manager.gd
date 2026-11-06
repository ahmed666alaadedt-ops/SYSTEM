
extends Node

class_name SystemSkyWeatherFlyingManager

# SYSTEM WORLD - Sky, Weather and Flying Creatures
# Godot 4

signal creature_discovered(creature: Node3D, creature_kind: String)
signal creature_landed(creature: Node3D)
signal creature_attack_requested(creature: Node3D, target: Node3D)

const WORLD_FANTASY := 0
const WORLD_HISTORICAL := 1
const WORLD_MODERN := 2
const WORLD_GREED_ISLAND := 3

const CLOUD_COUNT := 12
const STAR_COUNT := 90
const WEATHER_PARTICLE_COUNT := 100

var world_root: Node3D
var visual_root: Node3D
var player: Node3D

var world_id := WORLD_MODERN
var daylight_factor := 1.0
var current_weather := "clear"
var wind_strength := 0.3

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


func setup(target_world: Node3D, target_world_id: int = 2) -> bool:
	if target_world == null:
		push_warning("SYSTEM SKY: World root missing.")
		return false

	_remove_old_visuals()

	world_root = target_world
	world_id = clampi(target_world_id, 0, 3)
	player = world_root.find_child("Player", true, false) as Node3D

	visual_root = Node3D.new()
	visual_root.name = "SystemSkyWeatherVisuals"
	world_root.add_child(visual_root)

	_create_clouds()
	_create_stars()
	_create_moon()
	_create_weather_particles()
	_create_lightning()
	_create_flying_creatures()

	print("SYSTEM SKY: World ", world_id, " initialized.")
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
	player = null


func _process(delta: float) -> void:
	if not is_instance_valid(visual_root):
		return

	elapsed += delta

	if not is_instance_valid(player) and is_instance_valid(world_root):
		player = world_root.find_child("Player", true, false) as Node3D

	_update_clouds(delta)
	_update_stars()
	_update_moon()
	_update_weather(delta)
	_update_flying_creatures(delta)
	_update_lightning(delta)


# --------------------------------------------------
# VISUAL HELPERS
# --------------------------------------------------

func _material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
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
	var cloud_material := _material(Color(0.88, 0.91, 0.96))

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
				Vector3(2.5, 1.5, 2.5),
				cloud_material
			)

		clouds.append({
			"node": cloud,
			"speed": randf_range(0.15, 0.45)
		})


func _update_clouds(delta: float) -> void:
	for data in clouds:
		var cloud: Node3D = data["node"]

		if not is_instance_valid(cloud):
			continue

		cloud.position.x += float(data["speed"]) * (0.5 + wind_strength) * delta

		if cloud.position.x > 85.0:
			cloud.position.x = -85.0

		var visibility := 1.0

		if current_weather == "storm":
			visibility = 0.65
		elif current_weather == "rain":
			visibility = 0.8

		cloud.scale = Vector3.ONE * visibility


# --------------------------------------------------
# STARS AND MOON
# --------------------------------------------------

func _create_stars() -> void:
	var star_material := _material(Color(0.82, 0.90, 1.0), 0.2)
	star_material.emission_enabled = true
	star_material.emission = Color(0.82, 0.90, 1.0)
	star_material.emission_energy_multiplier = 1.8

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
	var moon_material := _material(Color(0.82, 0.86, 1.0))

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
	var night_amount := 1.0 - daylight_factor

	for star in stars:
		if is_instance_valid(star):
			star.visible = night_amount > 0.12


func _update_moon() -> void:
	if not is_instance_valid(moon):
		return

	var night_amount := 1.0 - daylight_factor
	moon.visible = night_amount > 0.08

	if is_instance_valid(moon_light):
		moon_light.light_energy = night_amount * 0.32


# --------------------------------------------------
# WEATHER
# --------------------------------------------------

func _create_weather_particles() -> void:
	var rain_material := _material(Color(0.52, 0.70, 0.95))
	var snow_material := _material(Color(0.95, 0.97, 1.0))

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
			"drift": randf_range(-1.0, 1.0),
			"rain_material": rain_material,
			"snow_material": snow_material
		})


func _update_weather(delta: float) -> void:
	var precipitation := current_weather in ["rain", "storm", "snow"]

	for data in weather_particles:
		var particle: MeshInstance3D = data["node"]

		if not is_instance_valid(particle):
			continue

		particle.visible = precipitation

		if not precipitation:
			continue

		if current_weather == "snow":
			particle.material_override = data["snow_material"]
			particle.position.y -= delta * 2.0
			particle.position.x += sin(elapsed + float(data["drift"])) * delta
		else:
			particle.material_override = data["rain_material"]
			particle.position.y -= delta * float(data["velocity"])
			particle.position.x += wind_strength * delta * 3.0

		if particle.position.y < 0.0:
			particle.position.y = randf_range(18.0, 35.0)
			particle.position.x = randf_range(-35.0, 35.0)
			particle.position.z = randf_range(-90.0, 10.0)


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
# CREATURE PROFILES
# --------------------------------------------------

func _create_flying_creatures() -> void:
	match world_id:
		WORLD_MODERN:
			_create_bird_group(
				10,
				Color(0.28, 0.30, 0.34),
				Color(0.12, 0.14, 0.18),
				"ModernBird"
			)

		WORLD_HISTORICAL:
			_create_bird_group(
				12,
				Color(0.48, 0.34, 0.20),
				Color(0.25, 0.18, 0.12),
				"HistoricalBird"
			)

		WORLD_FANTASY:
			_create_dragon_group(6, false)

		WORLD_GREED_ISLAND:
			_create_dragon_group(5, true)


func _create_bird_group(
	count: int,
	body_color: Color,
	wing_color: Color,
	prefix: String
) -> void:
	var body_material := _material(body_color)
	var wing_material := _material(wing_color)

	for index in range(count):
		var bird := Node3D.new()
		bird.name = "%s_%02d" % [prefix, index]
		visual_root.add_child(bird)

		_sphere(
			bird,
			"BirdBody",
			Vector3.ZERO,
			Vector3(0.35, 0.25, 0.75),
			body_material
		)

		var left_wing := _sphere(
			bird,
			"LeftWing",
			Vector3(-0.48, 0.0, 0.0),
			Vector3(0.85, 0.09, 0.35),
			wing_material
		)

		var right_wing := _sphere(
			bird,
			"RightWing",
			Vector3(0.48, 0.0, 0.0),
			Vector3(0.85, 0.09, 0.35),
			wing_material
		)

		var home := Vector3(
			randf_range(-15.0, 15.0),
			0.0,
			randf_range(-55.0, -25.0)
		)

		flying_creatures.append({
			"node": bird,
			"left_wing": left_wing,
			"right_wing": right_wing,
			"kind": "bird",
			"phase": randf() * TAU,
			"speed": randf_range(1.5, 3.0),
			"radius": randf_range(8.0, 22.0),
			"height": randf_range(13.0, 23.0),
			"home": home,
			"state": "orbit",
			"timer": randf_range(5.0, 12.0),
			"target": home,
			"discovered": false
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

		var home := Vector3(
			randf_range(-10.0, 10.0),
			0.0,
			randf_range(-60.0, -30.0)
		)

		flying_creatures.append({
			"node": dragon,
			"left_wing": left_wing,
			"right_wing": right_wing,
			"kind": "dragon",
			"phase": randf() * TAU,
			"speed": randf_range(0.65, 1.2),
			"radius": randf_range(15.0, 30.0),
			"height": randf_range(24.0, 37.0),
			"home": home,
			"state": "guard",
			"timer": randf_range(8.0, 16.0),
			"target": home,
			"attack_cooldown": 0.0,
			"discovered": false,
			"island": island_style
		})


# --------------------------------------------------
# CREATURE BEHAVIOR
# --------------------------------------------------

func _update_flying_creatures(delta: float) -> void:
	for data in flying_creatures:
		var creature: Node3D = data["node"]

		if not is_instance_valid(creature):
			continue

		data["timer"] = float(data["timer"]) - delta

		if data["kind"] == "bird":
			_update_bird_behavior(data, delta)
		else:
			_update_dragon_behavior(data, delta)

		_update_wings(data, delta)
		_check_discovery(data)


func _update_bird_behavior(data: Dictionary, delta: float) -> void:
	var creature: Node3D = data["node"]
	var state: String = data["state"]
	var home: Vector3 = data["home"]

	if state == "orbit":
		var phase := float(data["phase"]) + float(data["speed"]) * delta
		data["phase"] = phase

		var radius := float(data["radius"])

		var destination := home + Vector3(
			cos(phase) * radius,
			float(data["height"]) + sin(phase * 1.8) * 1.8,
			sin(phase) * radius
		)

		creature.position = creature.position.lerp(destination, delta * 2.0)

		if float(data["timer"]) <= 0.0:
			var choice := randi_range(0, 2)

			if choice == 0:
				data["state"] = "perch"
				data["target"] = home + Vector3(0.0, 2.0, 0.0)
			elif choice == 1:
				data["state"] = "hunt"
				data["target"] = home + Vector3(
					randf_range(-8.0, 8.0),
					1.0,
					randf_range(-8.0, 8.0)
				)
			else:
				data["state"] = "migrate"
				data["target"] = home + Vector3(
					randf_range(25.0, 45.0),
					randf_range(8.0, 15.0),
					randf_range(-20.0, 20.0)
				)

			data["timer"] = randf_range(5.0, 10.0)

	elif state == "perch":
		var target: Vector3 = data["target"]
		creature.position = creature.position.move_toward(target, delta * 5.0)

		if creature.position.distance_to(target) < 0.8:
			creature.position.y = target.y

		if float(data["timer"]) <= 0.0:
			data["state"] = "orbit"
			data["timer"] = randf_range(6.0, 12.0)

	elif state == "hunt":
		var target: Vector3 = data["target"]
		creature.position = creature.position.move_toward(target, delta * 9.0)

		if creature.position.distance_to(target) < 1.5 or float(data["timer"]) <= 0.0:
			data["state"] = "orbit"
			data["timer"] = randf_range(6.0, 12.0)

	elif state == "migrate":
		var target: Vector3 = data["target"]
		creature.position = creature.position.move_toward(target, delta * 4.0)

		if creature.position.distance_to(target) < 2.0 or float(data["timer"]) <= 0.0:
			data["home"] = target
			data["state"] = "orbit"
			data["timer"] = randf_range(8.0, 15.0)

	creature.rotation.y = atan2(
		-creature.velocity.x if creature is CharacterBody3D else 0.0,
		-1.0
	)


func _update_dragon_behavior(data: Dictionary, delta: float) -> void:
	var dragon: Node3D = data["node"]
	var home: Vector3 = data["home"]
	var state: String = data["state"]

	var target_position := home + Vector3(
		cos(elapsed * 0.25 + float(data["phase"])) * float(data["radius"]),
		float(data["height"]) + sin(elapsed * 0.45) * 3.0,
		sin(elapsed * 0.25 + float(data["phase"])) * float(data["radius"])
	)

	if state == "guard":
		dragon.position = dragon.position.lerp(target_position, delta * 1.2)

		if is_instance_valid(player):
			var player_local := world_root.to_local(player.global_position)
			var distance := dragon.position.distance_to(player_local)

			var detection_range := 24.0
			if bool(data.get("island", false)):
				detection_range = 32.0

			if distance < detection_range:
				data["state"] = "chase"
				data["timer"] = 12.0

		if float(data["timer"]) <= 0.0:
			data["state"] = "patrol"
			data["timer"] = randf_range(8.0, 15.0)

	elif state == "patrol":
		dragon.position = dragon.position.lerp(target_position, delta * 1.8)

		if float(data["timer"]) <= 0.0:
			data["state"] = "guard"
			data["timer"] = randf_range(8.0, 16.0)

	elif state == "chase":
		if not is_instance_valid(player):
			data["state"] = "guard"
			return

		var player_local := world_root.to_local(player.global_position)
		var chase_target := player_local + Vector3(0.0, 5.0, 0.0)

		dragon.position = dragon.position.move_toward(
			chase_target,
			delta * 8.0
		)

		var distance := dragon.global_position.distance_to(player.global_position)

		if distance < 4.0:
			_request_dragon_attack(data)

		if distance > 42.0 or float(data["timer"]) <= 0.0:
			data["state"] = "guard"
			data["timer"] = randf_range(8.0, 15.0)

	var look_target := dragon.position + Vector3(
		cos(elapsed * 0.4),
		0.0,
		-1.0
	)

	dragon.look_at(
		visual_root.to_global(look_target),
		Vector3.UP
	)


func _request_dragon_attack(data: Dictionary) -> void:
	data["attack_cooldown"] = float(data.get("attack_cooldown", 0.0)) - get_process_delta_time()

	if float(data["attack_cooldown"]) > 0.0:
		return

	data["attack_cooldown"] = 3.0

	if is_instance_valid(player):
		creature_attack_requested.emit(
			data["node"],
			player
		)

		print("SYSTEM SKY: Dragon attack requested.")


func _update_wings(data: Dictionary, delta: float) -> void:
	var left_wing: Node3D = data["left_wing"]
	var right_wing: Node3D = data["right_wing"]

	if not is_instance_valid(left_wing) or not is_instance_valid(right_wing):
		return

	var flap_speed := 7.0

	if data["kind"] == "dragon":
		flap_speed = 3.0

	var flap := sin(elapsed * flap_speed + float(data["phase"])) * 0.48

	left_wing.rotation.z = lerpf(
		left_wing.rotation.z,
		flap,
		delta * 8.0
	)

	right_wing.rotation.z = lerpf(
		right_wing.rotation.z,
		-flap,
		delta * 8.0
	)


func _check_discovery(data: Dictionary) -> void:
	if bool(data["discovered"]):
		return

	var creature: Node3D = data["node"]

	if not is_instance_valid(player):
		return

	var distance := creature.global_position.distance_to(player.global_position)

	if distance < 35.0:
		data["discovered"] = true
		creature_discovered.emit(
			creature,
			str(data["kind"])
		)


# --------------------------------------------------
# PUBLIC API
# --------------------------------------------------

func set_weather(weather_name: String) -> void:
	var allowed := ["clear", "cloudy", "rain", "snow", "storm"]

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

	print("SYSTEM SKY: Weather changed to ", current_weather)


func set_daylight_factor(value: float) -> void:
	daylight_factor = clampf(value, 0.0, 1.0)


func set_world_profile(target_world_id: int) -> void:
	if not is_instance_valid(world_root):
		return

	setup(world_root, target_world_id)


func get_current_weather() -> String:
	return current_weather


func get_flying_creature_count() -> int:
	return flying_creatures.size()


func get_creature_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for data in flying_creatures:
		result.append({
			"name": data["node"].name,
			"kind": data["kind"],
			"state": data["state"]
		})

	return result
