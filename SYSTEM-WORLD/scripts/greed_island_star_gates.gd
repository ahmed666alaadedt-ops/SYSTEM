extends Node

## البوابات النجمية الملكية — وضع اختبار المدير المحلي.
## حماية اللعب الجماعي الحقيقية تتطلب صلاحيات موثوقة من الخادم.

const FANTASY_ID := 0
const REALISTIC_ID := 2
const GREED_ISLAND_ID := 3
const HISTORICAL_ID := 4

const GATE_DATA := [
	{
		"id": FANTASY_ID,
		"name": "FantasyStarGate",
		"title": "بوابة عالم الخيال",
		"position": Vector3(-25.0, 0.0, -70.0),
		"theme": "fantasy"
	},
	{
		"id": REALISTIC_ID,
		"name": "RealisticStarGate",
		"title": "بوابة العالم الواقعي",
		"position": Vector3(0.0, 0.0, -70.0),
		"theme": "modern"
	},
	{
		"id": HISTORICAL_ID,
		"name": "HistoricalStarGate",
		"title": "بوابة العالم التاريخي",
		"position": Vector3(25.0, 0.0, -70.0),
		"theme": "historical"
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
		"WorldManager", true, false
	)

	island_manager = get_tree().root.find_child(
		"GreedIslandManager", true, false
	) as Node3D

	if world_manager == null or island_manager == null:
		return

	if not _is_admin_test_enabled():
		return

	_ensure_destination_worlds()
	_create_island_gates()
	_create_return_gates()

	gates_created = true
	print("SYSTEM: Royal star gates initialized.")


func _is_admin_test_enabled() -> bool:
	return (
		island_manager != null
		and island_manager.has_method("is_admin_test_environment")
		and bool(
			island_manager.call("is_admin_test_environment")
		)
	)


func _get_world_roots() -> Dictionary:
	if world_manager == null:
		return {}

	var value: Variant = world_manager.get("world_roots")
	if value is Dictionary:
		return value

	return {}


# --------------------------------------------------
# DESTINATION WORLDS
# --------------------------------------------------

func _ensure_destination_worlds() -> void:
	var roots := _get_world_roots()

	if roots.has(FANTASY_ID):
		var fantasy_root := roots[FANTASY_ID] as Node3D
		if fantasy_root != null and fantasy_root.get_child_count() == 0:
			_build_fantasy_preview(fantasy_root)

	if not roots.has(HISTORICAL_ID):
		var historical_root := Node3D.new()
		historical_root.name = "Historical World"
		historical_root.visible = false
		historical_root.process_mode = Node.PROCESS_MODE_DISABLED

		world_manager.add_child(historical_root)
		roots[HISTORICAL_ID] = historical_root

		_build_historical_preview(historical_root)


func _build_fantasy_preview(root: Node3D) -> void:
	var ground_material := _make_material(
		Color(0.12, 0.20, 0.28), 0.8, 0.25
	)

	var crystal_material := _make_glowing_material(
		Color(0.25, 0.55, 1.0)
	)

	_add_preview_ground(
		root,
		"FantasyPreviewGround",
		Vector3(110.0, 0.8, 110.0),
		ground_material
	)

	for index in range(5):
		var crystal := MeshInstance3D.new()
		crystal.name = "FantasyCrystal_%02d" % index

		var mesh := PrismMesh.new()
		mesh.size = Vector3(2.0, 7.0, 2.0)
		crystal.mesh = mesh

		crystal.position = Vector3(
			float(index) * 12.0 - 24.0,
			3.5,
			-18.0 - float(index % 2) * 8.0
		)

		crystal.material_override = crystal_material
		root.add_child(crystal)

	root.set_meta("system_world_type", "fantasy_preview")


func _build_historical_preview(root: Node3D) -> void:
	var stone := _make_material(
		Color(0.58, 0.45, 0.30), 0.95
	)

	var bronze := _make_material(
		Color(0.65, 0.40, 0.16), 0.4, 0.65
	)

	_add_preview_ground(
		root,
		"HistoricalPreviewPlaza",
		Vector3(110.0, 0.8, 110.0),
		stone
	)

	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var column := MeshInstance3D.new()
		column.name = "HistoricalColumn_%02d" % index

		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.7
		mesh.bottom_radius = 1.0
		mesh.height = 8.0
		column.mesh = mesh

		column.position = Vector3(
			cos(angle) * 17.0,
			4.0,
			sin(angle) * 17.0
		)

		column.material_override = bronze
		root.add_child(column)

	_add_gate_box(
		root,
		"HistoricalAncientMonument",
		Vector3(0.0, 3.0, -28.0),
		Vector3(18.0, 6.0, 5.0),
		bronze
	)

	root.set_meta("system_world_type", "historical_preview")


func _add_preview_ground(
	root: Node3D,
	node_name: String,
	size: Vector3,
	material: Material
) -> void:
	_add_gate_box(
		root,
		node_name,
		Vector3(0.0, -0.4, 0.0),
		size,
		material
	)

	var body := StaticBody3D.new()
	body.name = node_name + "Collision"
	body.position = Vector3(0.0, -0.4, 0.0)
	root.add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


# --------------------------------------------------
# THREE DIFFERENT ROYAL GATE DESIGNS
# --------------------------------------------------

func _create_island_gates() -> void:
	for data in GATE_DATA:
		var gate := Node3D.new()
		gate.name = data["name"]
		gate.position = data["position"]
		island_manager.add_child(gate)

		match data["theme"]:
			"fantasy":
				_build_fantasy_gate(gate)
			"modern":
				_build_modern_gate(gate)
			"historical":
				_build_historical_gate(gate)

		_add_gate_trigger(gate, data)


# بوابة خيالية: بلورات وأحجار سحرية وكرات طاقة.
func _build_fantasy_gate(parent: Node3D) -> void:
	var stone := _make_material(
		Color(0.19, 0.23, 0.38), 0.35, 0.5
	)

	var energy := _make_glowing_material(
		Color(0.28, 0.48, 1.0)
	)

	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		pillar.name = "FantasyCrystalPillar"

		var mesh := PrismMesh.new()
		mesh.size = Vector3(1.2, 5.0, 1.2)
		pillar.mesh = mesh
		pillar.position = Vector3(side * 1.9, 2.5, 0.0)
		pillar.material_override = stone
		parent.add_child(pillar)

		var orb := MeshInstance3D.new()
		orb.name = "FantasyMagicOrb"

		var orb_mesh := SphereMesh.new()
		orb_mesh.radius = 0.55
		orb.mesh = orb_mesh
		orb.position = Vector3(side * 1.9, 5.4, 0.0)
		orb.material_override = energy
		parent.add_child(orb)

	_add_gate_box(
		parent,
		"FantasyAncientCrown",
		Vector3(0.0, 5.0, 0.0),
		Vector3(4.8, 0.55, 0.9),
		stone
	)

	_add_gate_box(
		parent,
		"FantasyPortalEnergy",
		Vector3(0.0, 2.4, 0.2),
		Vector3(2.8, 3.8, 0.12),
		energy
	)


# بوابة حديثة: هيكل معدني وشاشة طاقة ووحدة تقنية.
func _build_modern_gate(parent: Node3D) -> void:
	var metal := _make_material(
		Color(0.12, 0.19, 0.25), 0.25, 0.85
	)

	var cyan := _make_glowing_material(
		Color(0.12, 0.9, 1.0)
	)

	_add_gate_box(
		parent,
		"ModernLeftFrame",
		Vector3(-1.8, 2.5, 0.0),
		Vector3(0.35, 5.0, 0.6),
		metal
	)

	_add_gate_box(
		parent,
		"ModernRightFrame",
		Vector3(1.8, 2.5, 0.0),
		Vector3(0.35, 5.0, 0.6),
		metal
	)

	_add_gate_box(
		parent,
		"ModernTopFrame",
		Vector3(0.0, 4.9, 0.0),
		Vector3(3.9, 0.35, 0.6),
		metal
	)

	_add_gate_box(
		parent,
		"ModernEnergyScreen",
		Vector3(0.0, 2.4, 0.15),
		Vector3(2.9, 3.9, 0.08),
		cyan
	)

	_add_gate_box(
		parent,
		"ModernLowerConsole",
		Vector3(0.0, 0.35, -0.5),
		Vector3(3.8, 0.45, 0.8),
		metal
	)


# بوابة تاريخية: أعمدة أثرية وحجر رملي وبرونز.
func _build_historical_gate(parent: Node3D) -> void:
	var sandstone := _make_material(
		Color(0.60, 0.43, 0.27), 0.95
	)

	var bronze := _make_material(
		Color(0.72, 0.48, 0.19), 0.35, 0.65
	)

	var light := _make_glowing_material(
		Color(1.0, 0.62, 0.22)
	)

	for side in [-1.0, 1.0]:
		var column := MeshInstance3D.new()
		column.name = "HistoricalCarvedColumn"

		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.55
		mesh.bottom_radius = 0.8
		mesh.height = 4.8
		column.mesh = mesh
		column.position = Vector3(side * 1.9, 2.4, 0.0)
		column.material_override = sandstone
		parent.add_child(column)

		_add_gate_box(
			parent,
			"HistoricalColumnBand",
			Vector3(side * 1.9, 3.7, 0.0),
			Vector3(1.0, 0.3, 1.0),
			bronze
		)

	_add_gate_box(
		parent,
		"HistoricalStoneLintel",
		Vector3(0.0, 4.9, 0.0),
		Vector3(4.8, 0.9, 1.0),
		sandstone
	)

	_add_gate_box(
		parent,
		"HistoricalGoldenInscription",
		Vector3(0.0, 4.95, -0.55),
		Vector3(2.7, 0.35, 0.08),
		light
	)

	_add_gate_box(
		parent,
		"HistoricalPortalLight",
		Vector3(0.0, 2.2, 0.2),
		Vector3(2.8, 3.5, 0.08),
		light
	)


# --------------------------------------------------
# MATERIALS AND VISUAL OBJECTS
# --------------------------------------------------

func _make_material(
	color: Color,
	roughness: float = 0.8,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_glowing_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	return material


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


# --------------------------------------------------
# ENTRY AND RETURN AREAS
# --------------------------------------------------

func _add_gate_trigger(
	parent: Node3D,
	data: Dictionary
) -> void:
	var trigger := Area3D.new()
	trigger.name = "GateActivationArea"
	trigger.position = Vector3(0.0, 1.2, 1.8)
	trigger.set_meta("system_star_gate", true)
	trigger.set_meta("system_gate_title", data["title"])

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.2
	collision.shape = sphere
	trigger.add_child(collision)

	parent.add_child(trigger)

	trigger.body_entered.connect(
		_on_island_gate_entered.bind(int(data["id"]))
	)


func _create_return_gates() -> void:
	var roots := _get_world_roots()

	for world_id in [FANTASY_ID, REALISTIC_ID, HISTORICAL_ID]:
		if not roots.has(world_id):
			continue

		var root := world_manager.call(
			"get_world_root", world_id
		) as Node3D

		if root == null:
			continue

		var return_gate := Area3D.new()
		return_gate.name = "RoyalReturnGate"
		return_gate.position = Vector3(0.0, 1.2, 1.8)
		return_gate.set_meta("system_return_gate", true)

		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 2.0
		collision.shape = sphere
		return_gate.add_child(collision)

		root.add_child(return_gate)
		return_gate.body_entered.connect(
			_on_return_gate_entered
		)


# --------------------------------------------------
# ADMIN ACCESS AND TRANSITIONS
# --------------------------------------------------

func _is_local_admin_player(body: Node3D) -> bool:
	if not body is CharacterBody3D:
		return false

	if body.name != "Player":
		return false

	return _is_admin_test_enabled()


func _on_island_gate_entered(
	body: Node3D,
	destination_id: int
) -> void:
	if transition_locked:
		return

	if not _is_local_admin_player(body):
		return

	var roots := _get_world_roots()
	if not roots.has(destination_id):
		push_warning(
			"SYSTEM: Destination world is unavailable."
		)
		return

	transition_locked = true
	world_manager.call("switch_world", destination_id)

	await get_tree().create_timer(1.0).timeout
	transition_locked = false


func _on_return_gate_entered(body: Node3D) -> void:
	if transition_locked:
		return

	if not _is_local_admin_player(body):
		return

	transition_locked = true
	world_manager.call(
		"switch_world", GREED_ISLAND_ID
	)

	await get_tree().create_timer(1.0).timeout
	transition_locked = false
