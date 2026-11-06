
extends Node
class_name SystemSkyWeatherFlyingManager

signal creature_discovered(creature_name: String, creature_type: String)
signal creature_landed(creature_name: String)
signal creature_attack_requested(creature_name: String, target: Node3D)

const WORLD_FANTASY := 0
const WORLD_HISTORICAL := 1
const WORLD_MODERN := 2
const WORLD_GREED_ISLAND := 3

var world_root: Node3D
var target_world_id: int = WORLD_FANTASY
var visual_root: Node3D

var current_weather: String = "clear"
var daylight_factor: float = 1.0

var clouds: Array[MeshInstance3D] = []
var stars: Array[MeshInstance3D] = []
var creatures: Array[Dictionary] = []

var moon: MeshInstance3D
var lightning_light: OmniLight3D
var lightning_timer: float = 0.0
var lightning_flash: float = 0.0
var weather_particles: GPUParticles3D


func setup(target_world: Node3D, world_id: int) -> void:
	if is_instance_valid(visual_root):
		visual_root.queue_free()

	visual_root = null
	clouds.clear()
	stars.clear()
	creatures.clear()

	moon = null
	lightning_light = null
	weather_particles = null

	lightning_timer = 0.0
	lightning_flash = 0.0

	world_root = target_world
	target_world_id = clampi(world_id, 0, 3)

	if not is_instance_valid(world_root):
		return

	visual_root = Node3D.new()
	visual_root.name = "SkyWeatherFlyingVisuals"
	world_root.add_child(visual_root)

	_create_sky()
	_create_weather_system()
	_create_flying_creatures()


func _process(delta: float) -> void:
	if not is_instance_valid(visual_root):
		return

	_update_clouds(delta)
	_update_stars()
	_update_weather(delta)
	_update_flying_creatures(delta)


# --------------------------------------------------
# MATERIALS
# --------------------------------------------------

func _make_material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8

	if glow:
		material.emission_enabled = true
		material.emission = color * 0.35

	return material


# --------------------------------------------------
# SKY
# --------------------------------------------------

func _create_sky() -> void:
	for i in range(7):
		var cloud := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(2.0, 4.0)
		mesh.height = mesh.radius * 0.6
		cloud.mesh = mesh
		cloud.position = Vector3(
			randf_range(-35.0, 35.0),
			randf_range(12.0, 25.0),
			randf_range(-35.0, 35.0)
		)
		cloud.name = "SkyCloud_%d" % i
		visual_root.add_child(cloud)
		clouds.append(cloud)

	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 2.0
	moon_mesh.height = 4.0

	moon = MeshInstance3D.new()
	moon.mesh = moon_mesh
	moon.position = Vector3(0, 32, -45)
	moon.name = "WorldMoon"
	moon.material_override = _make_material(Color(0.8, 0.85, 1.0), true)
	visual_root.add_child(moon)

	for i in range(45):
		var star := MeshInstance3D.new()
		var star_mesh := SphereMesh.new()
		star_mesh.radius = 0.08
		star_mesh.height = 0.16
		star.mesh = star_mesh
		star.position = Vector3(
			randf_range(-45.0, 45.0),
			randf_range(18.0, 42.0),
			randf_range(-45.0, 45.0)
		)
		star.material_override = _make_material(Color.WHITE, true)
		visual_root.add_child(star)
		stars.append(star)

	lightning_light = OmniLight3D.new()
	lightning_light.name = "WeatherLightning"
	lightning_light.light_color = Color(0.65, 0.8, 1.0)
	lightning_light.light_energy = 0.0
	lightning_light.omni_range = 80.0
	visual_root.add_child(lightning_light)


func _update_clouds(delta: float) -> void:
	for cloud in clouds:
		if not is_instance_valid(cloud):
			continue

		cloud.position.x += delta * 0.35

		if cloud.position.x > 45.0:
			cloud.position.x = -45.0


func _update_stars() -> void:
	var visible := daylight_factor < 0.35

	for star in stars:
		if is_instance_valid(star):
			star.visible = visible

	if is_instance_valid(moon):
		moon.visible = visible


# --------------------------------------------------
# WEATHER
# --------------------------------------------------

func _create_weather_system() -> void:
	weather_particles = GPUParticles3D.new()
	weather_particles.name = "SkyWeatherParticles"
	weather_particles.amount = 500
	weather_particles.lifetime = 4.0
	weather_particles.visibility_aabb = AABB(
		Vector3(-35, -15, -35),
		Vector3(70, 40, 70)
	)

	var particle_material := ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 12.0
	particle_material.initial_velocity_min = 5.0
	particle_material.initial_velocity_max = 9.0
	particle_material.gravity = Vector3(0, -2, 0)

	weather_particles.process_material = particle_material

	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.035
	particle_mesh.height = 0.07
	weather_particles.draw_pass_1 = particle_mesh
	weather_particles.position.y = 15.0

	visual_root.add_child(weather_particles)
	_apply_weather_settings()


func set_weather(weather_name: String) -> void:
	current_weather = weather_name.to_lower()
	_apply_weather_settings()


func _apply_weather_settings() -> void:
	if not is_instance_valid(weather_particles):
		return

	var material := weather_particles.process_material as ParticleProcessMaterial

	if material == null:
		return

	match current_weather:
		"rain", "storm":
			weather_particles.emitting = true
			material.direction = Vector3(0.1, -1, 0)
			material.initial_velocity_min = 12.0
			material.initial_velocity_max = 20.0
			material.gravity = Vector3(0, -5, 0)

		"snow":
			weather_particles.emitting = true
			material.direction = Vector3(0, -1, 0)
			material.initial_velocity_min = 1.0
			material.initial_velocity_max = 3.0
			material.gravity = Vector3(0, -0.5, 0)

		_:
			weather_particles.emitting = false


func _update_weather(delta: float) -> void:
	if current_weather == "storm":
		lightning_timer -= delta

		if lightning_timer <= 0.0:
			lightning_timer = randf_range(5.0, 14.0)
			lightning_flash = 0.25

			lightning_light.position = Vector3(
				randf_range(-20, 20),
				25,
				randf_range(-20, 20)
			)

			lightning_light.light_energy = 5.0

	if lightning_flash > 0.0:
		lightning_flash -= delta

		if lightning_flash <= 0.0:
			lightning_light.light_energy = 0.0


func set_daylight_factor(value: float) -> void:
	daylight_factor = clampf(value, 0.0, 1.0)
	_update_stars()


# --------------------------------------------------
# WORLD CREATURE PROFILES
# --------------------------------------------------

func _create_flying_creatures() -> void:
	match target_world_id:
		WORLD_MODERN:
			_create_birds(12, "modern")

		WORLD_HISTORICAL:
			_create_birds(10, "historical")

		WORLD_FANTASY:
			_create_fantasy_creatures()

		WORLD_GREED_ISLAND:
			_create_greed_creatures()


func _create_fantasy_creatures() -> void:
	_create_large_creature(
		"FantasyDragon",
		Color(0.65, 0.12, 0.08),
		1.5,
		4
	)

	_create_large_creature(
		"FantasyWyvern",
		Color(0.2, 0.35, 0.7),
		1.0,
		2
	)


func _create_greed_creatures() -> void:
	_create_large_creature(
		"GreedSkyDragon",
		Color(0.65, 0.45, 0.12),
		2.2,
		3
	)

	_create_large_creature(
		"GreedWingedGuardian",
		Color(0.65, 0.85, 0.95),
		1.7,
		2
	)

	_create_large_creature(
		"GreedNightCreature",
		Color(0.35, 0.15, 0.55),
		1.3,
		1
	)


# --------------------------------------------------
# BIRDS
# --------------------------------------------------

func _create_birds(amount: int, profile: String) -> void:
	var species: Array[Dictionary] = []

	if profile == "modern":
		species = [
			{"name": "Eagle", "color": Color(0.42, 0.25, 0.12), "size": 1.5},
			{"name": "Falcon", "color": Color(0.45, 0.48, 0.52), "size": 0.9},
			{"name": "Pigeon", "color": Color(0.5, 0.55, 0.62), "size": 0.65},
			{"name": "Crow", "color": Color(0.06, 0.07, 0.09), "size": 0.8},
			{"name": "Seabird", "color": Color(0.9, 0.9, 0.85), "size": 1.0}
		]
	else:
		species = [
			{"name": "AncientFalcon", "color": Color(0.65, 0.42, 0.18), "size": 1.1},
			{"name": "SacredIbis", "color": Color(0.88, 0.82, 0.68), "size": 1.0},
			{"name": "AncientRaven", "color": Color(0.12, 0.13, 0.16), "size": 1.2},
			{"name": "HeritageEagle", "color": Color(0.5, 0.3, 0.16), "size": 1.5}
		]

	for i in range(amount):
		var selected: Dictionary = species.pick_random()
		var bird := Node3D.new()

		bird.name = str(selected["name"]) + "_%d" % i
		visual_root.add_child(bird)

		var scale_factor: float = float(selected["size"])
		var bird_material := _make_material(selected["color"])

		var body := MeshInstance3D.new()
		var body_mesh := SphereMesh.new()
		body_mesh.radius = 0.22 * scale_factor
		body_mesh.height = 0.35 * scale_factor
		body.mesh = body_mesh
		body.material_override = bird_material
		bird.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.11 * scale_factor
		head_mesh.height = 0.16 * scale_factor
		head.mesh = head_mesh
		head.position = Vector3(0, 0.04, -0.23 * scale_factor)
		head.material_override = bird_material
		bird.add_child(head)

		var wing_left := _make_wing(scale_factor, bird_material)
		wing_left.position.x = -0.22 * scale_factor
		bird.add_child(wing_left)

		var wing_right := _make_wing(scale_factor, bird_material)
		wing_right.position.x = 0.22 * scale_factor
		bird.add_child(wing_right)

		bird.position = Vector3(
			randf_range(-20, 20),
			randf_range(9, 22),
			randf_range(-20, 20)
		)

		var behavior := ["orbit", "hunt", "migrate", "perch"].pick_random()

		creatures.append({
			"node": bird,
			"type": "bird",
			"name": bird.name,
			"species": str(selected["name"]),
			"behavior": behavior,
			"origin": bird.position,
			"target": bird.position + Vector3(
				randf_range(-8, 8), 0, randf_range(-8, 8)
			),
			"wing_left": wing_left,
			"wing_right": wing_right,
			"wing_phase": randf_range(0.0, TAU),
			"landed_emitted": false,
			"discovered": false,
			"speed": randf_range(2.0, 4.0) * scale_factor
		})


func _make_wing(
	scale_factor: float,
	material: Material
) -> MeshInstance3D:
	var wing := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		0.5 * scale_factor,
		0.06 * scale_factor,
		0.18 * scale_factor
	)

	wing.mesh = mesh
	wing.material_override = material
	return wing


# --------------------------------------------------
# LARGE FLYING CREATURES
# --------------------------------------------------

func _create_large_creature(
	creature_name: String,
	creature_color: Color,
	size_factor: float,
	amount: int
) -> void:
	for i in range(amount):
		var creature := Node3D.new()
		creature.name = "%s_%d" % [creature_name, i]
		visual_root.add_child(creature)

		var creature_material := _make_material(creature_color, true)

		var body := MeshInstance3D.new()
		var body_mesh := SphereMesh.new()
		body_mesh.radius = size_factor
		body_mesh.height = size_factor * 2.0
		body.mesh = body_mesh
		body.material_override = creature_material
		creature.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = size_factor * 0.45
		head_mesh.height = size_factor * 0.8
		head.mesh = head_mesh
		head.position = Vector3(0, 0.1, -size_factor)
		head.material_override = creature_material
		creature.add_child(head)

		var tail := MeshInstance3D.new()
		var tail_mesh := BoxMesh.new()
		tail_mesh.size = Vector3(
			size_factor * 0.25,
			size_factor * 0.25,
			size_factor * 1.8
		)
		tail.mesh = tail_mesh
		tail.position.z = size_factor * 1.2
		tail.material_override = creature_material
		creature.add_child(tail)

		var wing_left := _make_dragon_wing(size_factor, creature_material)
		wing_left.position = Vector3(-size_factor * 0.9, 0.2, 0)
		creature.add_child(wing_left)

		var wing_right := _make_dragon_wing(size_factor, creature_material)
		wing_right.position = Vector3(size_factor * 0.9, 0.2, 0)
		creature.add_child(wing_right)

		creature.position = Vector3(
			randf_range(-25, 25),
			randf_range(15, 28),
			randf_range(-25, 25)
		)

		var behavior := ["patrol", "guard"].pick_random()

		creatures.append({
			"node": creature,
			"type": "large_flying",
			"name": creature.name,
			"species": creature_name,
			"behavior": behavior,
			"origin": creature.position,
			"target": creature.position + Vector3(10, 0, 10),
			"wing_left": wing_left,
			"wing_right": wing_right,
			"wing_phase": randf_range(0.0, TAU),
			"attack_cooldown": randf_range(0.0, 2.0),
			"discovered": false,
			"speed": randf_range(3.0, 5.0) * size_factor
		})


func _make_dragon_wing(
	size_factor: float,
	material: Material
) -> MeshInstance3D:
	var wing := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		1.5 * size_factor,
		0.08 * size_factor,
		0.7 * size_factor
	)

	wing.mesh = mesh
	wing.material_override = material
	return wing


# --------------------------------------------------
# CREATURE BEHAVIOR
# --------------------------------------------------

func _update_flying_creatures(delta: float) -> void:
	for data in creatures:
		var creature := data.get("node") as Node3D

		if not is_instance_valid(creature):
			continue

		data["wing_phase"] = float(data.get("wing_phase", 0.0)) + delta * 7.0
		_animate_wings(data)

		if data["type"] == "bird":
			_update_bird_behavior(data, delta)
		else:
			_update_large_creature_behavior(data, delta)


func _animate_wings(data: Dictionary) -> void:
	var phase: float = float(data.get("wing_phase", 0.0))
	var left := data.get("wing_left") as Node3D
	var right := data.get("wing_right") as Node3D

	if is_instance_valid(left):
		left.rotation.z = sin(phase) * 0.65

	if is_instance_valid(right):
		right.rotation.z = -sin(phase) * 0.65


func _update_bird_behavior(data: Dictionary, delta: float) -> void:
	var bird := data["node"] as Node3D
	var behavior: String = data["behavior"]
	var target: Vector3 = data["target"]

	if behavior == "orbit":
		var origin: Vector3 = data["origin"]
		var angle: float = float(data["wing_phase"]) * 0.25
		target = origin + Vector3(
			cos(angle) * 7.0,
			1.5,
			sin(angle) * 7.0
		)

	elif behavior == "hunt":
		target = data["origin"] + Vector3(
			sin(float(data["wing_phase"])) * 5.0,
			-1.0,
			cos(float(data["wing_phase"]) * 0.7) * 5.0
		)

	elif behavior == "migrate":
		target = bird.position + Vector3(12.0, 0.0, 8.0)

		if bird.position.distance_to(data["origin"]) > 35.0:
			data["origin"] = bird.position
			target = bird.position + Vector3(-20.0, 0.0, -15.0)

	elif behavior == "perch":
		target = data["target"]

	var previous: Vector3 = bird.position

	bird.position = bird.position.move_toward(
		target,
		float(data["speed"]) * delta
	)

	var direction: Vector3 = bird.position - previous

	if direction.length() > 0.01:
		bird.rotation.y = atan2(-direction.x, -direction.z)

	if behavior == "perch":
		if bird.position.distance_to(target) < 0.25:
			if not bool(data["landed_emitted"]):
				data["landed_emitted"] = true
				creature_landed.emit(str(data["name"]))
		else:
			data["landed_emitted"] = false

	if not bool(data["discovered"]) and bird.position.length() < 12.0:
		data["discovered"] = true
		creature_discovered.emit(
			str(data["name"]),
			str(data["species"])
		)

	data["target"] = target


func _update_large_creature_behavior(
	data: Dictionary,
	delta: float
) -> void:
	var creature := data["node"] as Node3D
	var behavior: String = data["behavior"]

	data["attack_cooldown"] = maxf(
		0.0,
		float(data.get("attack_cooldown", 0.0)) - delta
	)

	var target: Vector3 = data["target"]

	if behavior == "guard":
		target = data["origin"]

	elif behavior == "patrol":
		if creature.position.distance_to(target) < 1.5:
			target = data["origin"] + Vector3(
				randf_range(-15, 15),
				randf_range(-3, 3),
				randf_range(-15, 15)
			)

	elif behavior == "chase":
		var player := _find_player()

		if is_instance_valid(player):
			target = visual_root.to_local(player.global_position)

			if creature.position.distance_to(target) < 4.0:
				_request_creature_attack(data, player)

	creature.position = creature.position.move_toward(
		target,
		float(data["speed"]) * delta
	)

	var direction: Vector3 = target - creature.position

	if direction.length() > 0.01:
		creature.rotation.y = atan2(-direction.x, -direction.z)

	if not bool(data["discovered"]) and creature.position.length() < 18.0:
		data["discovered"] = true
		creature_discovered.emit(
			str(data["name"]),
			str(data["species"])
		)

	data["target"] = target


func _request_creature_attack(
	data: Dictionary,
	target: Node3D
) -> void:
	if float(data["attack_cooldown"]) > 0.0:
		return

	data["attack_cooldown"] = 3.0
	creature_attack_requested.emit(str(data["name"]), target)


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")

	for item in players:
		if item is Node3D:
			return item as Node3D

	return null


# --------------------------------------------------
# WORLD PROFILE AND PUBLIC API
# --------------------------------------------------

func set_world_profile(world_id: int) -> void:
	target_world_id = clampi(world_id, 0, 3)

	if is_instance_valid(world_root):
		setup(world_root, target_world_id)


func get_current_weather() -> String:
	return current_weather


func get_flying_creature_count() -> int:
	var count := 0

	for data in creatures:
		if is_instance_valid(data.get("node")):
			count += 1

	return count


func get_creature_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for data in creatures:
		var creature := data.get("node") as Node3D

		if not is_instance_valid(creature):
			continue

		result.append({
			"name": str(data["name"]),
			"type": str(data["type"]),
			"species": str(data.get("species", "")),
			"behavior": str(data["behavior"]),
			"position": creature.position
		})

	return result
