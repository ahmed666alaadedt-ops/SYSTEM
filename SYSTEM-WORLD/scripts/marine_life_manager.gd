
extends Node3D
class_name SystemMarineLifeManager

# SYSTEM WORLD - Underwater Marine Life
# First prototype: four schools, six fish per school.

const SCHOOL_COUNT: int = 4
const FISH_PER_SCHOOL: int = 6

var fish_agents: Array[Dictionary] = []
var swim_time: float = 0.0


func _ready() -> void:
	name = "SystemMarineLifeManager"
	_create_fish_schools()


func _process(delta: float) -> void:
	swim_time += delta

	for agent in fish_agents:
		var fish: Node3D = agent["node"]
		var center: Vector3 = agent["center"]
		var phase: float = agent["phase"]
		var radius: float = agent["radius"]
		var speed: float = agent["speed"]
		var depth_motion: float = agent["depth_motion"]

		var angle: float = swim_time * speed + phase

		var offset := Vector3(
			cos(angle) * radius,
			sin(angle * 0.8) * depth_motion,
			sin(angle) * radius
		)

		fish.position = center + offset

		var direction := Vector3(
			-sin(angle),
			cos(angle * 0.8) * 0.2,
			cos(angle)
		)

		fish.look_at(
			fish.position + direction,
			Vector3.UP
		)


func _create_fish_schools() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 73192

	var school_centers: Array[Vector3] = [
		Vector3(165.0, -4.0, -80.0),
		Vector3(260.0, -7.0, 50.0),
		Vector3(370.0, -10.0, -180.0),
		Vector3(500.0, -5.0, 100.0)
	]

	var school_colors: Array[Color] = [
		Color(0.12, 0.62, 0.82),
		Color(0.92, 0.62, 0.18),
		Color(0.35, 0.72, 0.48),
		Color(0.72, 0.48, 0.82)
	]

	for school_index in range(SCHOOL_COUNT):
		var school := Node3D.new()
		school.name = "FishSchool_%02d" % school_index
		add_child(school)

		for fish_index in range(FISH_PER_SCHOOL):
			var fish := _create_fish(
				school_colors[school_index],
				rng.randf_range(0.75, 1.15)
			)

			school.add_child(fish)

			var center := school_centers[school_index] + Vector3(
				rng.randf_range(-3.0, 3.0),
				rng.randf_range(-1.5, 1.5),
				rng.randf_range(-3.0, 3.0)
			)

			fish.position = center

			fish_agents.append({
				"node": fish,
				"center": center,
				"phase": rng.randf_range(0.0, TAU),
				"radius": rng.randf_range(1.5, 4.0),
				"speed": rng.randf_range(0.45, 0.9),
				"depth_motion": rng.randf_range(0.2, 0.8)
			})


func _create_fish(fish_color: Color, fish_scale: float) -> Node3D:
	var fish := Node3D.new()
	fish.name = "MarineFish"

	var body := MeshInstance3D.new()
	body.name = "FishBody"

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.5
	body_mesh.height = 1.0
	body_mesh.radial_segments = 16
	body_mesh.rings = 10

	body.mesh = body_mesh
	body.scale = Vector3(
		0.48 * fish_scale,
		0.30 * fish_scale,
		0.95 * fish_scale
	)

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = fish_color
	body_material.roughness = 0.38
	body_material.metallic = 0.08
	body.material_override = body_material

	fish.add_child(body)

	var tail := MeshInstance3D.new()
	tail.name = "FishTail"

	var tail_mesh := SphereMesh.new()
	tail_mesh.radius = 0.5
	tail_mesh.height = 1.0
	tail_mesh.radial_segments = 12
	tail_mesh.rings = 8

	tail.mesh = tail_mesh
	tail.position.z = -0.72 * fish_scale
	tail.scale = Vector3(
		0.12 * fish_scale,
		0.48 * fish_scale,
		0.12 * fish_scale
	)

	var tail_material := StandardMaterial3D.new()
	tail_material.albedo_color = fish_color.darkened(0.18)
	tail_material.roughness = 0.5
	tail.material_override = tail_material

	fish.add_child(tail)

	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.015, 0.015, 0.02)

	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.name = "FishEye"

		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.055
		eye_mesh.height = 0.11
		eye_mesh.radial_segments = 8
		eye_mesh.rings = 6

		eye.mesh = eye_mesh
		eye.position = Vector3(
			0.19 * side * fish_scale,
			0.09 * fish_scale,
			0.30 * fish_scale
		)

		eye.material_override = eye_material
		fish.add_child(eye)

	return fish


func get_marine_life_status() -> Dictionary:
	return {
		"fish_schools": SCHOOL_COUNT,
		"fish_per_school": FISH_PER_SCHOOL,
		"total_fish": fish_agents.size(),
		"swimming_animation": true,
		"prototype": true
	}
