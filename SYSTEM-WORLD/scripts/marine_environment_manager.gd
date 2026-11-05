
extends Node3D
class_name SystemMarineEnvironmentManager

# SYSTEM WORLD - Marine Environment

const MarineLifeManagerScript = preload("res://SYSTEM-WORLD/scripts/marine_life_manager.gd")

const WATER_LEVEL: float = 0.0
const OCEAN_CENTER := Vector3(350.0, 0.0, -45.0)
const COAST_X: float = 100.0

@export var ocean_size: Vector2 = Vector2(500.0, 500.0)
@export var wave_speed: float = 1.0
@export var wave_height: float = 0.18

var ocean_material: ShaderMaterial
var ship: Node3D
var ship_time: float = 0.0
var marine_life: Node3D


func _ready() -> void:
	name = "SystemMarineEnvironment"

	_create_ocean()
	_create_beaches()
	_create_islands()
	_create_coastal_rocks()
	_create_ship()
	_create_marine_life()


func _process(delta: float) -> void:
	ship_time += delta

	if ship != null:
		ship.position.y = 0.65 + sin(ship_time * wave_speed) * 0.12
		ship.rotation.z = sin(ship_time * 0.8) * 0.025
		ship.rotation.x = cos(ship_time * 0.65) * 0.018


func _create_ocean() -> void:
	var ocean := MeshInstance3D.new()
	ocean.name = "AnimatedOcean"

	var mesh := PlaneMesh.new()
	mesh.size = ocean_size
	mesh.subdivide_width = 100
	mesh.subdivide_depth = 100

	ocean.mesh = mesh
	ocean.position = OCEAN_CENTER
	ocean_material = _make_water_material()
	ocean.material_override = ocean_material

	add_child(ocean)


func _make_water_material() -> ShaderMaterial:
	var shader := Shader.new()

	shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 deep_color : source_color = vec4(0.005, 0.12, 0.23, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.02, 0.42, 0.52, 1.0);
uniform float wave_speed = 1.0;
uniform float wave_height = 0.18;

varying vec3 world_position;

void vertex() {
	vec3 p = VERTEX;

	float wave_a = sin(p.x * 0.08 + TIME * wave_speed);
	float wave_b = cos(p.z * 0.06 + TIME * wave_speed * 0.7);
	float wave_c = sin((p.x + p.z) * 0.035 + TIME * 0.5);

	p.y += (wave_a + wave_b + wave_c) * wave_height;
	VERTEX = p;

	world_position = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
}

void fragment() {
	float wave = sin(world_position.x * 0.035 + TIME * 0.8);
	float depth_mix = clamp(0.35 + wave * 0.12, 0.0, 1.0);

	vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, depth_mix);

	ALBEDO = water_color;
	METALLIC = 0.25;
	ROUGHNESS = 0.16;
	SPECULAR = 0.8;
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("wave_speed", wave_speed)
	material.set_shader_parameter("wave_height", wave_height)

	return material


func _create_beaches() -> void:
	_create_beach(
		"EastCoastBeach",
		Vector3(75.0, -0.10, -45.0),
		Vector2(50.0, 500.0)
	)


func _create_beach(
	beach_name: String,
	beach_position: Vector3,
	beach_size: Vector2
) -> void:
	var beach := MeshInstance3D.new()
	beach.name = beach_name

	var mesh := PlaneMesh.new()
	mesh.size = beach_size

	beach.mesh = mesh
	beach.position = beach_position

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.76, 0.65, 0.43)
	material.roughness = 1.0

	beach.material_override = material
	add_child(beach)


func _create_islands() -> void:
	_create_island(
		"Island_East",
		Vector3(190.0, 0.0, -5.0),
		Vector3(35.0, 7.0, 27.0)
	)

	_create_island(
		"Island_West",
		Vector3(440.0, 0.0, 65.0),
		Vector3(42.0, 9.0, 32.0)
	)

	_create_island(
		"Island_Far",
		Vector3(330.0, 0.0, -210.0),
		Vector3(25.0, 5.0, 22.0)
	)


func _create_island(
	island_name: String,
	island_position: Vector3,
	island_size: Vector3
) -> void:
	var island := StaticBody3D.new()
	island.name = island_name
	island.position = island_position

	var ground := MeshInstance3D.new()
	ground.name = "IslandGround"

	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 32
	mesh.rings = 16

	ground.mesh = mesh
	ground.scale = island_size

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.30, 0.48, 0.22)
	material.roughness = 1.0

	ground.material_override = material
	island.add_child(ground)

	var collision := CollisionShape3D.new()
	collision.name = "IslandCollision"

	var shape := BoxShape3D.new()
	shape.size = Vector3(
		island_size.x * 1.5,
		island_size.y * 0.9,
		island_size.z * 1.5
	)

	collision.shape = shape
	collision.position.y = island_size.y * 0.25

	island.add_child(collision)
	add_child(island)


func _create_coastal_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 82451

	for i in range(35):
		var rock := MeshInstance3D.new()
		rock.name = "CoastalRock_%02d" % i

		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 1.7
		mesh.radial_segments = 12
		mesh.rings = 8

		rock.mesh = mesh

		rock.position = Vector3(
			rng.randf_range(88.0, 98.0),
			rng.randf_range(-0.1, 0.5),
			rng.randf_range(-245.0, 205.0)
		)

		rock.scale = Vector3(
			rng.randf_range(1.0, 3.5),
			rng.randf_range(0.7, 2.0),
			rng.randf_range(1.0, 3.0)
		)

		var material := StandardMaterial3D.new()
		material.albedo_color = Color(
			rng.randf_range(0.25, 0.42),
			rng.randf_range(0.27, 0.38),
			rng.randf_range(0.28, 0.40)
		)
		material.roughness = 1.0

		rock.material_override = material
		add_child(rock)


func _create_ship() -> void:
	ship = Node3D.new()
	ship.name = "CoastalShip"
	ship.position = Vector3(260.0, 0.65, 35.0)

	var hull := MeshInstance3D.new()
	hull.name = "ShipHull"

	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(4.0, 1.0, 11.0)

	hull.mesh = hull_mesh

	var hull_material := StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.24, 0.12, 0.065)
	hull_material.roughness = 0.75

	hull.material_override = hull_material
	ship.add_child(hull)

	var deck := MeshInstance3D.new()
	deck.name = "ShipDeck"

	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(3.5, 0.25, 8.0)

	deck.mesh = deck_mesh
	deck.position.y = 0.62

	var deck_material := StandardMaterial3D.new()
	deck_material.albedo_color = Color(0.55, 0.39, 0.22)

	deck.material_override = deck_material
	ship.add_child(deck)

	var mast := MeshInstance3D.new()
	mast.name = "ShipMast"

	var mast_mesh := CylinderMesh.new()
	mast_mesh.top_radius = 0.08
	mast_mesh.bottom_radius = 0.12
	mast_mesh.height = 7.0

	mast.mesh = mast_mesh
	mast.position.y = 4.0

	var mast_material := StandardMaterial3D.new()
	mast_material.albedo_color = Color(0.30, 0.19, 0.10)

	mast.material_override = mast_material
	ship.add_child(mast)

	var sail := MeshInstance3D.new()
	sail.name = "ShipSail"

	var sail_mesh := PlaneMesh.new()
	sail_mesh.size = Vector2(4.0, 5.0)

	sail.mesh = sail_mesh
	sail.position = Vector3(0.0, 4.1, 0.0)

	var sail_material := StandardMaterial3D.new()
	sail_material.albedo_color = Color(0.88, 0.82, 0.65)
	sail_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	sail.material_override = sail_material
	ship.add_child(sail)

	add_child(ship)


func _create_marine_life() -> void:
	marine_life = MarineLifeManagerScript.new()
	marine_life.name = "UnderwaterMarineLife"
	add_child(marine_life)


func get_marine_status() -> Dictionary:
	return {
		"ocean": true,
		"beaches": true,
		"islands": true,
		"coastal_rocks": true,
		"ship": ship != null,
		"marine_life": marine_life != null,
		"fish_count": 24 if marine_life != null else 0,
		"prototype": true
	}
