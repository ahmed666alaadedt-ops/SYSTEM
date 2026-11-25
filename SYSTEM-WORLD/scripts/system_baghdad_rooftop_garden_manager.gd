extends Node3D
class_name SYSTEMBaghdadRooftopGardenManager

const GARDEN_SIZE := Vector2(92.0, 54.0)

func _ready() -> void:
	name = "BaghdadRooftopGarden"
	_build_garden()
	set_meta("system_public_garden_runtime_ready", true)
	set_meta("system_public_garden_is_tower", false)
	set_meta("system_public_garden_tree_count", 8)
	set_meta("system_public_garden_bench_count", 8)
	set_meta("system_public_garden_flowerbed_count", 6)


func _build_garden() -> void:
	var grass_material := _material(Color(0.12, 0.31, 0.19), 0.92)
	var path_material := _material(Color(0.68, 0.62, 0.49), 0.82)
	var soil_material := _material(Color(0.22, 0.15, 0.10), 1.0)
	var leaf_material := _material(Color(0.12, 0.38, 0.20), 0.88)
	var trunk_material := _material(Color(0.30, 0.19, 0.11), 0.95)
	var bench_material := _material(Color(0.31, 0.20, 0.12), 0.62)
	var lamp_material := _material(Color(0.75, 0.59, 0.30), 0.38)

	var ground := StaticBody3D.new()
	ground.name = "GardenGroundCollision"
	var ground_shape := CollisionShape3D.new()
	ground_shape.name = "GardenWalkableSurface"
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(GARDEN_SIZE.x, 0.25, GARDEN_SIZE.y)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.13
	ground.add_child(ground_shape)
	add_child(ground)

	_add_box("GardenGrassEast", Vector3(25.0, 0.025, 0.0), Vector3(40.0, 0.05, 52.0), grass_material)
	_add_box("GardenGrassWest", Vector3(-25.0, 0.025, 0.0), Vector3(40.0, 0.05, 52.0), grass_material)
	_add_box("GardenCentralWalkway", Vector3(0.0, 0.045, 0.0), Vector3(8.0, 0.09, 52.0), path_material)
	_add_box("GardenCrossWalkway", Vector3(0.0, 0.05, 0.0), Vector3(88.0, 0.1, 7.0), path_material)
	_add_box("GardenNorthPromenade", Vector3(0.0, 0.045, -25.0), Vector3(88.0, 0.09, 3.0), path_material)
	_add_box("GardenSouthPromenade", Vector3(0.0, 0.045, 25.0), Vector3(88.0, 0.09, 3.0), path_material)

	var tree_positions := [
		Vector3(-34.0, 0.0, -17.0), Vector3(-20.0, 0.0, -17.0),
		Vector3(20.0, 0.0, -17.0), Vector3(34.0, 0.0, -17.0),
		Vector3(-34.0, 0.0, 17.0), Vector3(-20.0, 0.0, 17.0),
		Vector3(20.0, 0.0, 17.0), Vector3(34.0, 0.0, 17.0)
	]
	for index in range(tree_positions.size()):
		_build_tree(index, tree_positions[index], trunk_material, leaf_material)

	var flower_positions := [
		Vector3(-12.0, 0.0, -19.0), Vector3(12.0, 0.0, -19.0),
		Vector3(-12.0, 0.0, 19.0), Vector3(12.0, 0.0, 19.0),
		Vector3(-40.0, 0.0, 0.0), Vector3(40.0, 0.0, 0.0)
	]
	for index in range(flower_positions.size()):
		var bed := Node3D.new()
		bed.name = "GardenFlowerbed_%02d" % index
		bed.position = flower_positions[index]
		add_child(bed)
		_add_box_to(bed, "FlowerbedSoil", Vector3.ZERO, Vector3(5.0, 0.22, 3.0), soil_material)
		for flower_index in range(7):
			var flower := MeshInstance3D.new()
			flower.name = "Flower_%02d" % flower_index
			var bloom := SphereMesh.new()
			bloom.radius = 0.16
			bloom.height = 0.32
			flower.mesh = bloom
			flower.position = Vector3(-1.8 + float(flower_index % 4) * 1.15, 0.28, -0.65 + float(flower_index / 4) * 1.1)
			flower.material_override = _material(Color(0.82, 0.43 + float(flower_index % 2) * 0.18, 0.57), 0.55)
			bed.add_child(flower)

	for index in range(8):
		var x := -30.0 + float(index % 4) * 20.0
		var z := -8.5 if index < 4 else 8.5
		_build_bench(index, Vector3(x, 0.0, z), bench_material)

	for index in range(6):
		var x := -36.0 + float(index % 3) * 36.0
		var z := -22.0 if index < 3 else 22.0
		_build_lamp(index, Vector3(x, 0.0, z), lamp_material)

	var sign := Label3D.new()
	sign.name = "BaghdadRooftopGardenSign"
	sign.text = "SYSTEM BAGHDAD | ROOFTOP GARDEN\nحدائق بغداد العامة"
	sign.position = Vector3(0.0, 3.2, -24.0)
	sign.font_size = 24
	sign.pixel_size = 0.012
	sign.modulate = Color(0.75, 0.96, 0.82)
	add_child(sign)


func _build_tree(index: int, at: Vector3, trunk_material: Material, leaf_material: Material) -> void:
	var tree := Node3D.new()
	tree.name = "GardenTree_%02d" % index
	tree.position = at
	add_child(tree)
	var trunk := MeshInstance3D.new()
	trunk.name = "TreeTrunk"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 3.2
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.6
	trunk.material_override = trunk_material
	tree.add_child(trunk)
	var canopy := MeshInstance3D.new()
	canopy.name = "TreeCanopy"
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 2.1
	canopy_mesh.height = 4.0
	canopy.mesh = canopy_mesh
	canopy.position.y = 4.0
	canopy.material_override = leaf_material
	tree.add_child(canopy)
	var collider := StaticBody3D.new()
	collider.name = "TreeTrunkCollision"
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.42
	cylinder.height = 3.2
	shape.shape = cylinder
	shape.position.y = 1.6
	collider.add_child(shape)
	tree.add_child(collider)


func _build_bench(index: int, at: Vector3, material: Material) -> void:
	var bench := Node3D.new()
	bench.name = "GardenBench_%02d" % index
	bench.position = at
	add_child(bench)
	_add_box_to(bench, "BenchSeat", Vector3(0.0, 0.65, 0.0), Vector3(2.8, 0.22, 0.8), material)
	_add_box_to(bench, "BenchBack", Vector3(0.0, 1.15, -0.32), Vector3(2.8, 0.9, 0.18), material)
	for side in [-1.0, 1.0]:
		_add_box_to(bench, "BenchLeg_%s" % str(side), Vector3(side * 1.05, 0.3, 0.0), Vector3(0.16, 0.6, 0.65), material)
	var body := StaticBody3D.new()
	body.name = "BenchCollision"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 1.2, 0.8)
	collision.shape = box
	collision.position.y = 0.6
	body.add_child(collision)
	bench.add_child(body)


func _build_lamp(index: int, at: Vector3, material: Material) -> void:
	var lamp := Node3D.new()
	lamp.name = "GardenLamp_%02d" % index
	lamp.position = at
	add_child(lamp)
	_add_box_to(lamp, "LampPost", Vector3(0.0, 2.0, 0.0), Vector3(0.16, 4.0, 0.16), material)
	_add_box_to(lamp, "LampHead", Vector3(0.0, 4.1, 0.0), Vector3(0.75, 0.22, 0.75), material)
	var light := OmniLight3D.new()
	light.name = "GardenLight"
	light.position.y = 3.9
	light.light_color = Color(1.0, 0.82, 0.58)
	light.light_energy = 0.55
	light.omni_range = 9.0
	lamp.add_child(light)


func _add_box(node_name: String, at: Vector3, size: Vector3, material: Material) -> void:
	_add_box_to(self, node_name, at, size, material)


func _add_box_to(parent: Node3D, node_name: String, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = at
	mesh_node.material_override = material
	parent.add_child(mesh_node)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result
