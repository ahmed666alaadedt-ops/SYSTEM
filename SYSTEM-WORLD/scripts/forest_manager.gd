
extends Node3D
class_name SystemForestManager

const TREE_COUNT_PER_SIDE := 14
const SHRUB_COUNT_PER_SIDE := 12

var rng := RandomNumberGenerator.new()

var trunk_materials: Array[StandardMaterial3D] = []
var leaf_materials: Array[StandardMaterial3D] = []
var ground_material: StandardMaterial3D
var shrub_material: StandardMaterial3D
var rock_material: StandardMaterial3D
var log_material: StandardMaterial3D


func _ready() -> void:
	rng.randomize()
	_create_materials()
	_create_forest_ground()
	_create_forest()
	_create_shrubs()
	_create_rocks()
	_create_fallen_logs()

	print("SYSTEM WORLD: Natural forest initialized.")


func _make_material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _create_materials() -> void:
	trunk_materials.append(_make_material(Color(0.25, 0.14, 0.075)))
	trunk_materials.append(_make_material(Color(0.34, 0.20, 0.11)))
	trunk_materials.append(_make_material(Color(0.19, 0.13, 0.09)))

	leaf_materials.append(_make_material(Color(0.075, 0.24, 0.105)))
	leaf_materials.append(_make_material(Color(0.11, 0.31, 0.13)))
	leaf_materials.append(_make_material(Color(0.17, 0.34, 0.12)))
	leaf_materials.append(_make_material(Color(0.055, 0.19, 0.10)))

	ground_material = _make_material(Color(0.16, 0.22, 0.12))
	shrub_material = _make_material(Color(0.12, 0.28, 0.095))
	rock_material = _make_material(Color(0.30, 0.31, 0.28))
	log_material = _make_material(Color(0.22, 0.13, 0.075))


func _create_forest_ground() -> void:
	for side in [-1.0, 1.0]:
		var patch := MeshInstance3D.new()
		patch.name = "NaturalForestGround"

		var plane := PlaneMesh.new()
		plane.size = Vector2(15.0, 145.0)
		patch.mesh = plane

		patch.position = Vector3(side * 40.0, 0.018, -48.0)
		patch.material_override = ground_material

		add_child(patch)


func _create_forest() -> void:
	for side in [-1.0, 1.0]:
		for index in range(TREE_COUNT_PER_SIDE):
			var tree_x := side * rng.randf_range(34.0, 47.0)
			var tree_z := rng.randf_range(-116.0, -12.0)
			var tree_scale := rng.randf_range(0.8, 1.45)

			_create_tree(
				Vector3(tree_x, 0.0, tree_z),
				tree_scale,
				index
			)


func _create_tree(
	tree_position: Vector3,
	tree_scale: float,
	variant: int
) -> void:
	var tree := Node3D.new()
	tree.name = "NaturalForestTree"
	tree.position = tree_position
	tree.scale = Vector3.ONE * tree_scale
	add_child(tree)

	var trunk_body := StaticBody3D.new()
	trunk_body.name = "TreeTrunkCollision"
	tree.add_child(trunk_body)

	var trunk_height := rng.randf_range(3.5, 5.5)
	var trunk_radius := rng.randf_range(0.20, 0.32)

	var trunk := MeshInstance3D.new()
	trunk.name = "TreeTrunk"

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = trunk_radius * 0.7
	trunk_mesh.bottom_radius = trunk_radius
	trunk_mesh.height = trunk_height

	trunk.mesh = trunk_mesh
	trunk.position.y = trunk_height * 0.5
	trunk.material_override = trunk_materials[variant % trunk_materials.size()]
	trunk_body.add_child(trunk)

	var collision := CollisionShape3D.new()
	var collision_shape := CylinderShape3D.new()
	collision_shape.radius = trunk_radius
	collision_shape.height = trunk_height

	collision.shape = collision_shape
	collision.position.y = trunk_height * 0.5
	trunk_body.add_child(collision)

	var crown_count := rng.randi_range(3, 5)

	for crown_index in range(crown_count):
		var crown := MeshInstance3D.new()
		crown.name = "TreeLeafCrown"

		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = rng.randf_range(1.0, 1.5)
		crown_mesh.height = crown_mesh.radius * 2.0

		crown.mesh = crown_mesh
		crown.position = Vector3(
			rng.randf_range(-0.65, 0.65),
			trunk_height + rng.randf_range(-0.2, 1.3),
			rng.randf_range(-0.65, 0.65)
		)

		crown.scale = Vector3(
			rng.randf_range(0.9, 1.2),
			rng.randf_range(0.85, 1.2),
			rng.randf_range(0.9, 1.2)
		)

		crown.material_override = leaf_materials[
			rng.randi_range(0, leaf_materials.size() - 1)
		]

		tree.add_child(crown)


func _create_shrubs() -> void:
	for side in [-1.0, 1.0]:
		for index in range(SHRUB_COUNT_PER_SIDE):
			var shrub := Node3D.new()
			shrub.name = "ForestShrub"

			shrub.position = Vector3(
				side * rng.randf_range(34.0, 47.0),
				0.0,
				rng.randf_range(-116.0, -12.0)
			)

			add_child(shrub)

			var clump_count := rng.randi_range(2, 4)

			for clump_index in range(clump_count):
				var leaves := MeshInstance3D.new()
				leaves.name = "ShrubLeaves"

				var sphere := SphereMesh.new()
				sphere.radius = rng.randf_range(0.35, 0.65)
				sphere.height = sphere.radius * 2.0

				leaves.mesh = sphere
				leaves.position = Vector3(
					rng.randf_range(-0.35, 0.35),
					rng.randf_range(0.3, 0.65),
					rng.randf_range(-0.35, 0.35)
				)

				leaves.material_override = shrub_material
				shrub.add_child(leaves)


func _create_rocks() -> void:
	for index in range(12):
		var rock := MeshInstance3D.new()
		rock.name = "ForestNaturalRock"

		var mesh := SphereMesh.new()
		mesh.radius = rng.randf_range(0.35, 0.8)
		mesh.height = mesh.radius * 1.5

		rock.mesh = mesh
		rock.position = Vector3(
			rng.randf_range(-47.0, 47.0),
			0.2,
			rng.randf_range(-116.0, -12.0)
		)

		rock.scale = Vector3(
			rng.randf_range(0.8, 1.5),
			rng.randf_range(0.5, 0.9),
			rng.randf_range(0.8, 1.4)
		)

		rock.material_override = rock_material
		add_child(rock)


func _create_fallen_logs() -> void:
	for index in range(6):
		var log := MeshInstance3D.new()
		log.name = "ForestFallenTreeLog"

		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.18
		mesh.bottom_radius = 0.24
		mesh.height = rng.randf_range(2.0, 3.5)

		log.mesh = mesh
		log.position = Vector3(
			rng.randf_range(-46.0, 46.0),
			0.22,
			rng.randf_range(-112.0, -16.0)
		)

		log.rotation.z = PI * 0.5
		log.rotation.y = rng.randf_range(0.0, TAU)
		log.material_override = log_material

		add_child(log)
