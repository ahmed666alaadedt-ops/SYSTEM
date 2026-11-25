extends Node3D
class_name SYSTEMHunterMarshlandEnvironment

signal deception_triggered(npc_id: String, message: String)
signal marshland_discovered(player: Node3D)

const ZONE_ORIGIN := Vector3(2200.0, 0.0, 1800.0)
const ZONE_SIZE := Vector2(420.0, 360.0)
const PLAYER_GROUP := "system_player"

var deceptive_npc_ids: Array[String] = []
var giant_creature_ids: Array[String] = []
var _player_inside := false

func _ready() -> void:
	name = "HunterMarshlandEnvironment"
	set_meta("system_hunter_exam_marshland", true)
	set_meta("system_marshland_runtime_ready", false)
	set_meta("system_environment_role", "hunter_exam_marshland")
	_build_environment()
	set_meta("system_marshland_runtime_ready", true)


func _build_environment() -> void:
	var ground_material := _material(Color(0.20, 0.31, 0.16))
	var soil_material := _material(Color(0.30, 0.22, 0.12))
	var water_material := _material(Color(0.10, 0.30, 0.27, 0.78), 0.18)
	var wood_material := _material(Color(0.28, 0.17, 0.09))
	var leaf_material := _material(Color(0.10, 0.28, 0.12))
	var reed_material := _material(Color(0.30, 0.39, 0.18))
	var stone_material := _material(Color(0.25, 0.28, 0.24))

	var ground := _box("MarshlandWalkableGround", ZONE_ORIGIN + Vector3(0.0, -0.8, 0.0), Vector3(ZONE_SIZE.x, 1.6, ZONE_SIZE.y), ground_material, true)
	ground.set_meta("system_marshland_ground", true)
	_add_box("NorthAgriculturalTerrace", Vector3(2200.0, 0.12, 1660.0), Vector3(170.0, 0.25, 70.0), soil_material, true)
	_add_box("SouthAgriculturalTerrace", Vector3(2200.0, 0.12, 1940.0), Vector3(170.0, 0.25, 70.0), soil_material, true)
	_add_box("WestCultivatedPlots", Vector3(2070.0, 0.12, 1800.0), Vector3(65.0, 0.25, 130.0), soil_material, true)
	_add_box("EastCultivatedPlots", Vector3(2330.0, 0.12, 1800.0), Vector3(65.0, 0.25, 130.0), soil_material, true)

	for index in range(8):
		var crop := _box("CropBed_%02d" % index, Vector3(2140.0 + float(index % 4) * 38.0, 0.42, 1645.0 + float(index / 4) * 24.0), Vector3(22.0, 0.5, 2.0), reed_material, false)
		crop.set_meta("system_crop_bed", true)
	for index in range(6):
		_add_tree("AncientWetlandTree_%02d" % index, Vector3(2010.0 + float(index % 3) * 175.0, 0.0, 1650.0 + float(index / 3) * 285.0), leaf_material, wood_material)

	_add_water("MainMarshChannel", Vector3(2200.0, -0.05, 1800.0), Vector3(360.0, 0.5, 24.0), water_material, "marsh_channel")
	_add_water("EasternWetlandPool", Vector3(2350.0, -0.08, 1840.0), Vector3(62.0, 0.45, 70.0), water_material, "marsh_pool")
	_add_water("SouthernReedWater", Vector3(2110.0, -0.08, 1930.0), Vector3(78.0, 0.45, 42.0), water_material, "reed_water")
	for index in range(18):
		var reed := _cylinder("MarshReed_%02d" % index, Vector3(2020.0 + float(index % 9) * 40.0, 1.0, 1880.0 + float(index / 9) * 35.0), 0.12, 2.0, reed_material)
		reed.rotation.z = deg_to_rad(float((index % 5) - 2) * 5.0)

	_build_village(wood_material, stone_material)
	_build_giant_turtle(Vector3(2320.0, 0.0, 1840.0), leaf_material, stone_material)
	_build_giant_beast("GiantMarshMonitor", Vector3(2050.0, 0.0, 1850.0), Color(0.25, 0.31, 0.17), 1.8)
	_build_giant_beast("GiantMarshStalker", Vector3(2260.0, 0.0, 1980.0), Color(0.32, 0.22, 0.18), 2.4)
	_build_people_and_guides(wood_material)
	_build_exam_approach(stone_material)


func _build_village(wood: Material, stone: Material) -> void:
	var village := Node3D.new()
	village.name = "MarshlandVillage"
	add_child(village)
	for index in range(5):
		var hut := Node3D.new()
		hut.name = "VillageHut_%02d" % index
		hut.position = Vector3(1990.0 + float(index % 3) * 24.0, 0.0, 1710.0 + float(index / 3) * 26.0)
		village.add_child(hut)
		_add_box_to(hut, "HutBody", Vector3(0.0, 2.0, 0.0), Vector3(10.0, 4.0, 8.0), wood, true)
		_add_box_to(hut, "HutRoof", Vector3(0.0, 4.8, 0.0), Vector3(12.0, 1.2, 10.0), stone, false)


func _build_people_and_guides(wood: Material) -> void:
	for index in range(12):
		var guide := _create_person("MarshlandResident_%02d" % index, Vector3(1980.0 + float(index % 4) * 24.0, 0.0, 1710.0 + float(index / 4) * 20.0), Color(0.55, 0.36, 0.22))
		guide.set_meta("system_marshland_resident", true)
	for index in range(4):
		var npc := _create_person("DeceptiveExamGuide_%02d" % index, Vector3(2090.0 + float(index) * 34.0, 0.0, 1780.0 + float(index % 2) * 34.0), Color(0.18, 0.22, 0.28))
		npc.set_meta("system_deceptive_exam_npc", true)
		npc.set_meta("system_deception_pattern", ["false_safe_route", "misleading_supply_advice", "false_wetland_warning", "decoy_checkpoint"][index])
		npc.set_meta("system_interaction_prompt", "تحدث مع الدليل — انتبه، قد تكون معلوماته مضللة")
		deceptive_npc_ids.append(str(npc.name))
		var area := Area3D.new()
		area.name = "DeceptionProximity"
		area.position = Vector3(0.0, 1.0, 0.0)
		area.monitoring = true
		area.monitorable = true
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 7.0
		shape.shape = sphere
		area.add_child(shape)
		npc.add_child(area)
		area.body_entered.connect(_on_deception_area_entered.bind(str(npc.name), str(npc.get_meta("system_deception_pattern"))))


func _create_person(person_name: String, world_position: Vector3, tunic_color: Color) -> Node3D:
	var person := Node3D.new()
	person.name = person_name
	person.position = world_position
	person.set_meta("system_npc_role", "marshland_resident")
	person.set_meta("system_marshland_population", true)
	add_child(person)
	var body := _sphere(person_name + "_Body", Vector3(0.0, 1.0, 0.0), Vector3(0.42, 0.75, 0.3), _material(tunic_color))
	var head := _sphere(person_name + "_Head", Vector3(0.0, 2.0, 0.0), Vector3(0.34, 0.34, 0.34), _material(Color(0.62, 0.43, 0.30)))
	return person


func _build_giant_turtle(origin: Vector3, shell_material: Material, skin_material: Material) -> void:
	var turtle := Node3D.new()
	turtle.name = "ColossalAncientMarshTurtle"
	turtle.position = origin
	turtle.set_meta("system_giant_creature", true)
	turtle.set_meta("system_creature_species", "colossal_marsh_turtle")
	turtle.set_meta("system_creature_scale_class", "colossal")
	add_child(turtle)
	_sphere_to(turtle, "AncientTurtleShell", Vector3(0.0, 3.0, 0.0), Vector3(5.8, 2.8, 7.0), shell_material)
	_sphere_to(turtle, "AncientTurtleBody", Vector3(0.0, 1.8, 0.0), Vector3(4.8, 1.5, 5.8), skin_material)
	_sphere_to(turtle, "AncientTurtleHead", Vector3(0.0, 2.0, -6.0), Vector3(1.6, 1.3, 1.8), skin_material)
	for index in range(4):
		var x := -3.5 if index % 2 == 0 else 3.5
		var z := -3.5 if index < 2 else 3.5
		_sphere_to(turtle, "AncientTurtleLeg_%02d" % index, Vector3(x, 0.8, z), Vector3(1.5, 1.0, 1.5), skin_material)
	giant_creature_ids.append(str(turtle.name))


func _build_giant_beast(beast_name: String, origin: Vector3, tint: Color, scale_factor: float) -> void:
	var beast := Node3D.new()
	beast.name = beast_name
	beast.position = origin
	beast.scale = Vector3.ONE * scale_factor
	beast.set_meta("system_giant_creature", true)
	beast.set_meta("system_creature_species", "marshland_beast")
	beast.set_meta("system_creature_scale_class", "giant")
	add_child(beast)
	var hide := _material(tint)
	_sphere_to(beast, "BeastTorso", Vector3(0.0, 1.3, 0.0), Vector3(2.0, 1.0, 3.2), hide)
	_sphere_to(beast, "BeastHead", Vector3(0.0, 1.5, -2.6), Vector3(1.1, 0.9, 1.2), hide)
	giant_creature_ids.append(beast_name)


func _build_exam_approach(stone: Material) -> void:
	var approach := Node3D.new()
	approach.name = "HunterExamMarshlandApproach"
	approach.position = Vector3(2200.0, 0.0, 1560.0)
	approach.set_meta("system_exam_destination", "hunter_exam_marshland")
	approach.set_meta("system_exam_route_kind", "marshland_extension")
	add_child(approach)
	_add_box_to(approach, "ApproachCauseway", Vector3(0.0, 0.15, 0.0), Vector3(18.0, 0.3, 90.0), stone, true)
	var marker := Area3D.new()
	marker.name = "MarshlandExamArrivalZone"
	marker.position = Vector3(0.0, 1.0, -42.0)
	marker.set_meta("system_hunter_exam_marshland_arrival", true)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 5.0, 12.0)
	collision.shape = box
	marker.add_child(collision)
	approach.add_child(marker)
	marker.body_entered.connect(_on_marshland_arrival)


func _on_marshland_arrival(body: Node3D) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return
	body.set_meta("system_hunter_exam_marshland_reached", true)
	body.set_meta("system_hunter_exam_current_environment", "marshland")
	marshland_discovered.emit(body)


func _on_deception_area_entered(body: Node3D, npc_id: String, pattern: String) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return
	body.set_meta("system_marshland_deception_warning", true)
	body.set_meta("system_marshland_deception_source", npc_id)
	var messages := {
		"false_safe_route": "تحذير: الدليل يقترح طريقاً آمناً غير موثوق.",
		"misleading_supply_advice": "تحذير: معلومات الإمدادات قد تكون مضللة.",
		"false_wetland_warning": "تحذير: تحقّق من تحذيرات المياه قبل اتباعها.",
		"decoy_checkpoint": "تحذير: قد تكون نقطة التفتيش علامة زائفة."
	}
	deception_triggered.emit(npc_id, str(messages.get(pattern, "تحقق من معلومات هذا الشخص.")))


func _add_water(node_name: String, center: Vector3, size: Vector3, material: Material, water_type: String) -> void:
	var water := Area3D.new()
	water.name = node_name
	water.position = center
	water.monitoring = true
	water.monitorable = true
	water.set_meta("system_marshland_water", true)
	water.set_meta("system_water_type", water_type)
	add_child(water)
	var surface := MeshInstance3D.new()
	surface.name = "WaterSurface"
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.mesh = mesh
	surface.material_override = material
	water.add_child(surface)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	water.add_child(collision)


func _add_tree(tree_name: String, center: Vector3, leaves: Material, trunk: Material) -> void:
	var tree := Node3D.new()
	tree.name = tree_name
	tree.position = center
	add_child(tree)
	_cylinder_to(tree, "Trunk", Vector3(0.0, 5.0, 0.0), 1.0, 10.0, trunk)
	_sphere_to(tree, "Canopy", Vector3(0.0, 11.0, 0.0), Vector3(6.0, 6.0, 6.0), leaves)


func _material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result


func _box(node_name: String, center: Vector3, size: Vector3, material: Material, with_collision: bool) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	box.name = node_name
	box.position = center
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.material_override = material
	add_child(box)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		body.position = center
		add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	return box


func _add_box_to(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material, with_collision: bool) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = local_position
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	parent.add_child(visual)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		body.position = local_position
		parent.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)


func _sphere(node_name: String, center: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = center
	instance.scale = scale_value
	instance.mesh = sphere
	instance.material_override = material
	add_child(instance)
	return instance


func _sphere_to(parent: Node3D, node_name: String, center: Vector3, scale_value: Vector3, material: Material) -> void:
	var sphere := SphereMesh.new()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = center
	instance.scale = scale_value
	instance.mesh = sphere
	instance.material_override = material
	parent.add_child(instance)


func _cylinder(node_name: String, center: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = center
	instance.mesh = cylinder
	instance.material_override = material
	add_child(instance)
	return instance


func _cylinder_to(parent: Node3D, node_name: String, center: Vector3, radius: float, height: float, material: Material) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = center
	instance.mesh = cylinder
	instance.material_override = material
	parent.add_child(instance)
