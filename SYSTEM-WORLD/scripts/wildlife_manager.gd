extends Node3D

class_name SystemWildlifeManager

const BIRD_COUNT := 8
const ANIMAL_COUNT := 6

const WORLD_BOUNDS_X := 38.0
const WORLD_BOUNDS_Z_MIN := -120.0
const WORLD_BOUNDS_Z_MAX := -8.0

var birds: Array[Dictionary] = []
var animals: Array[Dictionary] = []
var elapsed := 0.0


func _ready() -> void:
	_create_bird_flock()
	_create_wild_animals()


func _process(delta: float) -> void:
	elapsed += delta
	_update_birds(delta)
	_update_animals(delta)


# --------------------------------------------------
# MATERIALS AND SIMPLE 3D PARTS
# --------------------------------------------------

func _make_material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _add_sphere(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	scale: Vector3,
	material: Material
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name

	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0

	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = scale
	mesh_instance.material_override = material

	parent.add_child(mesh_instance)
	return mesh_instance


func _add_capsule(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height

	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material

	parent.add_child(mesh_instance)
	return mesh_instance


# --------------------------------------------------
# BIRDS
# --------------------------------------------------

func _create_bird_flock() -> void:
	var bird_material := _make_material(
		Color(0.32, 0.35, 0.38)
	)

	var wing_material := _make_material(
		Color(0.19, 0.22, 0.25)
	)

	for index in range(BIRD_COUNT):
		var bird := Node3D.new()
		bird.name = "WildBird_%02d" % index

		add_child(bird)

		_add_sphere(
			bird,
			"BirdBody",
			Vector3.ZERO,
			Vector3(0.30, 0.22, 0.48),
			bird_material
		)

		_add_sphere(
			bird,
			"BirdHead",
			Vector3(0.0, 0.08, -0.23),
			Vector3(0.20, 0.19, 0.20),
			bird_material
		)

		var left_wing := Node3D.new()
		left_wing.name = "LeftWing"
		left_wing.position = Vector3(-0.12, 0.04, 0.0)
		bird.add_child(left_wing)

		_add_sphere(
			left_wing,
			"WingMesh",
			Vector3(-0.27, 0.0, 0.0),
			Vector3(0.62, 0.07, 0.28),
			wing_material
		)

		var right_wing := Node3D.new()
		right_wing.name = "RightWing"
		right_wing.position = Vector3(0.12, 0.04, 0.0)
		bird.add_child(right_wing)

		_add_sphere(
			right_wing,
			"WingMesh",
			Vector3(0.27, 0.0, 0.0),
			Vector3(0.62, 0.07, 0.28),
			wing_material
		)

		var phase := float(index) * 0.8
		var radius := 3.0 + float(index % 4) * 1.4

		birds.append({
			"node": bird,
			"left_wing": left_wing,
			"right_wing": right_wing,
			"phase": phase,
			"radius": radius,
			"speed": 0.22 + float(index % 3) * 0.035
		})


func _update_birds(delta: float) -> void:
	for bird_data in birds:
		var bird: Node3D = bird_data["node"]

		if not is_instance_valid(bird):
			continue

		var phase: float = bird_data["phase"]
		var speed: float = bird_data["speed"]
		var radius: float = bird_data["radius"]

		phase += speed * delta
		bird_data["phase"] = phase

		var center := Vector3(0.0, 11.0, -48.0)

		bird.position = center + Vector3(
			cos(phase) * radius,
			sin(phase * 2.0) * 0.8,
			sin(phase * 0.7) * radius
		)

		bird.rotation.y = -phase * 0.7

		var flap := sin(elapsed * 12.0 + phase) * 0.65

		var left_wing: Node3D = bird_data["left_wing"]
		var right_wing: Node3D = bird_data["right_wing"]

		left_wing.rotation.z = flap
		right_wing.rotation.z = -flap


# --------------------------------------------------
# WILD ANIMALS
# --------------------------------------------------

func _create_wild_animals() -> void:
	_create_animal("Deer", Vector3(-30.0, 0.0, -28.0), 1.15)
	_create_animal("Deer", Vector3(31.0, 0.0, -62.0), 1.15)

	_create_animal("Fox", Vector3(-34.0, 0.0, -88.0), 0.85)
	_create_animal("Fox", Vector3(34.0, 0.0, -105.0), 0.85)

	_create_animal("Rabbit", Vector3(-25.0, 0.0, -112.0), 0.65)
	_create_animal("Rabbit", Vector3(26.0, 0.0, -35.0), 0.65)


func _create_animal(
	species: String,
	start_position: Vector3,
	animal_scale: float
) -> void:
	var animal := Node3D.new()
	animal.name = "WildAnimal_" + species
	animal.position = start_position
	animal.scale = Vector3.ONE * animal_scale

	add_child(animal)

	var body_color := Color(0.48, 0.29, 0.16)

	if species == "Fox":
		body_color = Color(0.72, 0.28, 0.10)
	elif species == "Rabbit":
		body_color = Color(0.55, 0.48, 0.40)

	var body_material := _make_material(body_color)
	var light_material := _make_material(
		Color(0.78, 0.67, 0.52)
	)
	var dark_material := _make_material(
		Color(0.16, 0.12, 0.10)
	)

	var body_length := 1.0

	if species == "Deer":
		body_length = 1.25
	elif species == "Rabbit":
		body_length = 0.65

	_add_sphere(
		animal,
		"AnimalBody",
		Vector3(0.0, 0.78, 0.0),
		Vector3(0.48, 0.52, body_length),
		body_material
	)

	_add_sphere(
		animal,
		"AnimalHead",
		Vector3(0.0, 1.10, -body_length * 0.48),
		Vector3(0.34, 0.36, 0.35),
		body_material
	)

	_add_sphere(
		animal,
		"AnimalNose",
		Vector3(0.0, 1.02, -body_length * 0.78),
		Vector3(0.13, 0.12, 0.15),
		dark_material
	)

	# الأذنان
	for side in [-1.0, 1.0]:
		var ear_height := 0.28

		if species == "Rabbit":
			ear_height = 0.62

		var ear := _add_capsule(
			animal,
			"AnimalEar",
			Vector3(
				side * 0.17,
				1.40 + ear_height * 0.3,
				-body_length * 0.5
			),
			0.09,
			ear_height,
			light_material
		)

		ear.rotation.z = side * 0.16

	# الذيل
	var tail_position := Vector3(
		0.0,
		0.83,
		body_length * 0.65
	)

	var tail_size := Vector3(0.20, 0.20, 0.40)

	if species == "Fox":
		tail_size = Vector3(0.35, 0.35, 0.85)
	elif species == "Rabbit":
		tail_size = Vector3(0.22, 0.22, 0.22)

	_add_sphere(
		animal,
		"AnimalTail",
		tail_position,
		tail_size,
		light_material if species == "Fox" else body_material
	)

	# الأرجل
	var leg_positions := [
		Vector3(-0.19, 0.40, -0.30),
		Vector3(0.19, 0.40, -0.30),
		Vector3(-0.19, 0.40, 0.30),
		Vector3(0.19, 0.40, 0.30)
	]

	for leg_position in leg_positions:
		_add_capsule(
			animal,
			"AnimalLeg",
			leg_position,
			0.075,
			0.55,
			dark_material
		)

	animals.append({
		"node": animal,
		"species": species,
		"origin": start_position,
		"direction": Vector3.FORWARD,
		"speed": 0.45 + randf() * 0.35,
		"change_timer": randf_range(1.5, 4.0),
		"phase": randf() * TAU
	})


func _update_animals(delta: float) -> void:
	for animal_data in animals:
		var animal: Node3D = animal_data["node"]

		if not is_instance_valid(animal):
			continue

		animal_data["change_timer"] -= delta
		animal_data["phase"] += delta

		if animal_data["change_timer"] <= 0.0:
			var angle := randf_range(-PI, PI)

			animal_data["direction"] = Vector3(
				sin(angle),
				0.0,
				cos(angle)
			)

			animal_data["change_timer"] = randf_range(
				2.0,
				5.0
			)

		var direction: Vector3 = animal_data["direction"]
		var speed: float = animal_data["speed"]

		var movement := direction * speed * delta

		animal.position += movement

		# إبقاء الحيوان ضمن المنطقة المخصصة له.
		var origin: Vector3 = animal_data["origin"]

		var offset := animal.position - origin

		if offset.length() > 9.0:
			animal_data["direction"] = (
				-origin.direction_to(animal.position)
			)

		animal.position.x = clampf(
			animal.position.x,
			-WORLD_BOUNDS_X,
			WORLD_BOUNDS_X
		)

		animal.position.z = clampf(
			animal.position.z,
			WORLD_BOUNDS_Z_MIN,
			WORLD_BOUNDS_Z_MAX
		)

		if direction.length() > 0.01:
			var target_angle := atan2(
				direction.x,
				direction.z
			)

			animal.rotation.y = lerp_angle(
				animal.rotation.y,
				target_angle,
				delta * 2.0
			)

		# حركة بسيطة للجسم أثناء المشي.
		var bob := sin(
			float(animal_data["phase"]) * 5.0
		) * 0.025

		animal.position.y = bob
