extends Node

## بوابات الجزيرة النجمية — وضع اختبار المدير المحلي.
## الحماية هنا للاختبار الفردي فقط، وليست حماية خادم متعددة اللاعبين.

const FANTASY_WORLD_ID := 0
const REALISTIC_WORLD_ID := 2
const HISTORICAL_WORLD_ID := 4
const GREED_ISLAND_WORLD_ID := 3

const GATE_DATA := [
	{
		"id": FANTASY_WORLD_ID,
		"name": "FantasyStarGate",
		"title": "بوابة عالم الخيال",
		"position": Vector3(-25.0, 0.0, -70.0),
		"color": Color(0.35, 0.65, 1.0)
	},
	{
		"id": REALISTIC_WORLD_ID,
		"name": "RealisticStarGate",
		"title": "بوابة العالم الواقعي",
		"position": Vector3(0.0, 0.0, -70.0),
		"color": Color(0.2, 0.95, 0.85)
	},
	{
		"id": HISTORICAL_WORLD_ID,
		"name": "HistoricalStarGate",
		"title": "بوابة العالم التاريخي",
		"position": Vector3(25.0, 0.0, -70.0),
		"color": Color(1.0, 0.68, 0.25)
	}
]

var world_manager: Node
var island_manager: Node3D
var gates_created := false
var transition_locked := false


func _process(_delta: float) -> void:
	if gates_created:
		return

	world_manager = get_tree().root.find_child(
		"WorldManager",
		true,
		false
	)

	island_manager = get_tree().root.find_child(
		"GreedIslandManager",
		true,
		false
	) as Node3D

	if world_manager == null or island_manager == null:
		return

	_create_island_gates()
	_create_return_gates()
	gates_created = true

	print("SYSTEM: Royal star gates initialized.")


func _create_island_gates() -> void:
	for data in GATE_DATA:
		var gate := Node3D.new()
		gate.name = data["name"]
		gate.position = data["position"]
		island_manager.add_child(gate)

		_build_gate_visual(
			gate,
			data["color"]
		)

		var trigger := Area3D.new()
		trigger.name = "GateActivationArea"
		trigger.position = Vector3(0.0, 1.2, 1.8)
		trigger.set_meta("system_star_gate", true)
		trigger.set_meta("system_gate_title", data["title"])

		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 2.2
		shape.shape = sphere
		trigger.add_child(shape)

		gate.add_child(trigger)

		trigger.body_entered.connect(
			_on_island_gate_entered.bind(int(data["id"]))
		)


func _build_gate_visual(
	parent: Node3D,
	gate_color: Color
) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.24, 0.25, 0.31)
	stone.roughness = 0.35
	stone.metallic = 0.55

	var energy := StandardMaterial3D.new()
	energy.albedo_color = gate_color
	energy.emission_enabled = true
	energy.emission = gate_color
	energy.emission_energy_multiplier = 2.5
	energy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	energy.albedo_color.a = 0.72

	_add_gate_box(
		parent,
		"LeftRoyalPillar",
		Vector3(-1.8, 2.3, 0.0),
		Vector3(0.55, 4.6, 0.65),
		stone
	)

	_add_gate_box(
		parent,
		"RightRoyalPillar",
		Vector3(1.8, 2.3, 0.0),
		Vector3(0.55, 4.6, 0.65),
		stone
	)

	_add_gate_box(
		parent,
		"RoyalTopBeam",
		Vector3(0.0, 4.55, 0.0),
		Vector3(4.1, 0.65, 0.8),
		stone
	)

	_add_gate_box(
		parent,
		"StarEnergySurface",
		Vector3(0.0, 2.2, 0.15),
		Vector3(2.9, 3.7, 0.12),
		energy
	)

	for side in [-1.0, 1.0]:
		var crystal := MeshInstance3D.new()
		crystal.name = "RoyalEnergyCrystal"

		var mesh := SphereMesh.new()
		mesh.radius = 0.35
		mesh.height = 0.8
		crystal.mesh = mesh
		crystal.position = Vector3(side * 1.8, 4.9, 0.0)
		crystal.material_override = energy
		parent.add_child(crystal)


func _add_gate_box(
	parent: Node3D,
	node_name: String,
	local_position: Vector3,
	box_size: Vector3,
	material: Material
) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name

	var mesh := BoxMesh.new()
	mesh.size = box_size

	visual.mesh = mesh
	visual.position = local_position
	visual.material_override = material

	parent.add_child(visual)


func _create_return_gates() -> void:
	for world_id in [
		FANTASY_WORLD_ID,
		REALISTIC_WORLD_ID,
		HISTORICAL_WORLD_ID
	]:
		if not world_manager.world_roots.has(world_id):
			continue

		var root := world_manager.get_world_root(world_id) as Node3D
		if root == null:
			continue

		var return_gate := Area3D.new()
		return_gate.name = "RoyalReturnGate"
		return_gate.position = Vector3(0.0, 1.2, 7.0)
		return_gate.set_meta("system_return_gate", true)

		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 2.0
		shape.shape = sphere
		return_gate.add_child(shape)

		root.add_child(return_gate)

		return_gate.body_entered.connect(
			_on_return_gate_entered
		)


func _is_local_admin_player(body: Node) -> bool:
	if not body is CharacterBody3D:
		return false

	if body.name != "Player":
		return false

	if island_manager == null:
		return false

	if not island_manager.has_method("is_admin_test_environment"):
		return false

	return bool(island_manager.call(
		"is_admin_test_environment"
	))


func _on_island_gate_entered(
	body: Node3D,
	destination_id: int
) -> void:
	if transition_locked:
		return

	if not _is_local_admin_player(body):
		return

	if not world_manager.world_roots.has(destination_id):
		push_warning(
			"SYSTEM STAR GATE: destination world is not available yet."
		)
		return

	transition_locked = true
	world_manager.switch_world(destination_id)

	await get_tree().create_timer(1.0).timeout
	transition_locked = false


func _on_return_gate_entered(body: Node3D) -> void:
	if transition_locked:
		return

	if not body is CharacterBody3D:
		return

	if body.name != "Player":
		return

	if world_manager == null:
		return

	transition_locked = true
	world_manager.switch_world(GREED_ISLAND_WORLD_ID)

	await get_tree().create_timer(1.0).timeout
	transition_locked = false
