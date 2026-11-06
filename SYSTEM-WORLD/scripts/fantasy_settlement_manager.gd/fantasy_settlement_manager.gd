extends Node3D
class_name SystemFantasySettlementManager

## Fantasy settlements, villages, residents and map icon registry.
## Connects to the existing world map and AI NPC society managers.

signal settlement_created(settlement_id: String)
signal resident_created(npc_id: String, settlement_id: String)

const FANTASY_WORLD_ID := 0

const VILLAGE_DATA := [
	{
		"id": "willowmere_village",
		"name": "Willowmere Village",
		"region": "enchanted_forest",
		"position": Vector3(-22.0, 0.0, -24.0),
		"icon": "🏘️",
		"residents": [
			["Eldric", 42.0, "farmer"],
			["Mira", 35.0, "healer"],
			["Thorin", 51.0, "shepherd"],
			["Lina", 27.0, "merchant"],
			["Rowan", 31.0, "blacksmith"],
			["Bram", 38.0, "hunter"]
		]
	},
	{
		"id": "emberfall_village",
		"name": "Emberfall Village",
		"region": "dragon_mountains",
		"position": Vector3(24.0, 0.0, -35.0),
		"icon": "🏘️",
		"residents": [
			["Darius", 46.0, "blacksmith"],
			["Elena", 33.0, "merchant"],
			["Garrick", 55.0, "shepherd"],
			["Sylvia", 29.0, "healer"],
			["Cedric", 40.0, "guard"],
			["Tomas", 24.0, "farmer"]
		]
	},
	{
		"id": "moonbrook_village",
		"name": "Moonbrook Village",
		"region": "crystal_valley",
		"position": Vector3(0.0, 0.0, -75.0),
		"icon": "🏘️",
		"residents": [
			["Alaric", 48.0, "innkeeper"],
			["Nadia", 30.0, "healer"],
			["Orin", 37.0, "farmer"],
			["Freya", 26.0, "merchant"],
			["Baldric", 44.0, "guard"],
			["Perrin", 19.0, "shepherd"]
		]
	}
]

const OCCUPATION_ICONS := {
	"farmer": "🌾",
	"shepherd": "🐑",
	"merchant": "🛒",
	"guard": "🛡️",
	"healer": "✚",
	"blacksmith": "⚒️",
	"hunter": "🏹",
	"innkeeper": "🍺"
}

var world_root: Node3D
var map_manager: Node
var npc_society: Node
var world_id: int = FANTASY_WORLD_ID

var settlements: Dictionary = {}
var resident_nodes: Dictionary = {}
var map_icon_records: Array[Dictionary] = []

var initialized := false


func setup(
	target_world_root: Node3D,
	target_map_manager: Node,
	target_npc_society: Node,
	target_world_id: int = FANTASY_WORLD_ID
) -> bool:

	if target_world_root == null:
		push_warning("Fantasy settlements: world root is missing.")
		return false

	if target_map_manager == null:
		push_warning("Fantasy settlements: map manager is missing.")
		return false

	if target_npc_society == null:
		push_warning("Fantasy settlements: NPC society is missing.")
		return false

	world_root = target_world_root
	map_manager = target_map_manager
	npc_society = target_npc_society
	world_id = target_world_id

	if get_parent() == null:
		world_root.add_child(self)

	_create_all_settlements()

	initialized = true

	print(
		"Fantasy settlements initialized: ",
		settlements.size(),
		" villages."
	)

	return true


func _create_all_settlements() -> void:
	for village in VILLAGE_DATA:
		_create_settlement(village)


func _create_settlement(data: Dictionary) -> void:
	var village_id := str(data["id"])

	if settlements.has(village_id):
		return

	var village := Node3D.new()
	village.name = village_id
	village.position = data["position"]

	village.set_meta("system_settlement_id", village_id)
	village.set_meta("system_region_id", data["region"])
	village.set_meta("system_display_name", data["name"])
	village.set_meta("system_settlement_type", "village")

	add_child(village)

	_create_village_ground(village)
	_create_village_houses(village)
	_create_village_sign(village, str(data["name"]))
	_create_village_interaction(village, data)

	settlements[village_id] = {
		"id": village_id,
		"name": data["name"],
		"region": data["region"],
		"position": data["position"],
		"icon": data["icon"],
		"resident_ids": []
	}

	_register_map_location(data)

	var residents: Array = data.get("residents", [])

	for resident in residents:
		if resident.size() < 3:
			continue

		_create_resident(
			village,
			village_id,
			str(resident[0]),
			float(resident[1]),
			str(resident[2])
		)

	settlement_created.emit(village_id)


func _create_village_ground(parent: Node3D) -> void:
	var ground := MeshInstance3D.new()
	ground.name = "VillageGround"

	var mesh := CylinderMesh.new()
	mesh.top_radius = 13.0
	mesh.bottom_radius = 14.0
	mesh.height = 0.25

	ground.mesh = mesh
	ground.position.y = 0.05

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.28, 0.24, 0.16)
	material.roughness = 1.0

	ground.material_override = material
	parent.add_child(ground)


func _create_village_houses(parent: Node3D) -> void:
	var house_positions := [
		Vector3(-5.0, 0.0, -4.0),
		Vector3(5.0, 0.0, -4.0),
		Vector3(-5.0, 0.0, 5.0),
		Vector3(5.0, 0.0, 5.0)
	]

	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.48, 0.34, 0.22)

	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.20, 0.13, 0.11)

	for index in range(house_positions.size()):
		var house := Node3D.new()
		house.name = "VillageHouse_%02d" % index
		house.position = house_positions[index]

		parent.add_child(house)

		var body := MeshInstance3D.new()
		var body_mesh := BoxMesh.new()
		body_mesh.size = Vector3(4.0, 3.0, 4.0)

		body.mesh = body_mesh
		body.position.y = 1.5
		body.material_override = wall_material

		house.add_child(body)

		var roof := MeshInstance3D.new()
		var roof_mesh := PrismMesh.new()

		roof_mesh.size = Vector3(4.8, 2.0, 4.8)

		roof.mesh = roof_mesh
		roof.position.y = 3.8
		roof.material_override = roof_material

		house.add_child(roof)


func _create_village_sign(
	parent: Node3D,
	display_name: String
) -> void:

	var sign := Label3D.new()
	sign.name = "VillageNameSign"
	sign.text = display_name
	sign.position = Vector3(0.0, 5.0, -10.0)
	sign.font_size = 48
	sign.outline_size = 8
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	parent.add_child(sign)


func _create_village_interaction(
	parent: Node3D,
	data: Dictionary
) -> void:

	var area := Area3D.new()
	area.name = "VillageInteractionArea"
	area.position.y = 1.0
	area.collision_layer = 1
	area.collision_mask = 1

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 12.0

	collision.shape = shape
	area.add_child(collision)

	area.set_meta("system_location_id", data["id"])
	area.set_meta("system_region_id", data["region"])
	area.set_meta("system_display_name", data["name"])
	area.set_meta("system_location_type", 1)
	area.set_meta(
		"system_interaction_prompt",
		"Explore " + str(data["name"])
	)

	area.add_to_group("system_interactable")
	area.add_to_group("system_village")

	parent.add_child(area)


func _register_map_location(data: Dictionary) -> void:
	if map_manager == null:
		return

	map_manager.register_location(
		str(world_id),
		str(data["id"]),
		str(data["region"]),
		str(data["name"]),
		1,
		data["position"],
		false
	)

	_add_map_icon(
		str(data["id"]),
		str(data["name"]),
		str(data["icon"]),
		"village",
		data["position"]
	)


func _create_resident(
	village: Node3D,
	village_id: String,
	display_name: String,
	age: float,
	occupation: String
) -> void:

	if not npc_society.has_method("create_npc"):
		return

	var npc_id := npc_society.create_npc(
		display_name,
		world_id,
		age,
		"balanced",
		occupation
	)

	if npc_id.is_empty():
		return

	# Connect the resident to the village and daily life.
	if npc_society.npcs.has(npc_id):
		var npc: Dictionary = npc_society.npcs[npc_id]

		npc["home_location"] = village_id
		npc["current_location"] = village_id
		npc["activity"] = "daily_life"
		npc["settlement_type"] = "village"
		npc["map_icon"] = OCCUPATION_ICONS.get(
			occupation,
			"👤"
		)

		npc_society.npcs[npc_id] = npc

	var resident := Node3D.new()
	resident.name = "Resident_" + npc_id

	resident.set_meta("system_npc_id", npc_id)
	resident.set_meta("system_location_id", npc_id)
	resident.set_meta("system_region_id", village_id)
	resident.set_meta("system_display_name", display_name)
	resident.set_meta("system_npc_occupation", occupation)
	resident.set_meta("system_interaction_prompt", "Talk to " + display_name)

	resident.add_to_group("system_npc")
	resident.add_to_group("system_interactable")

	var capsule := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()

	capsule_mesh.radius = 0.35
	capsule_mesh.height = 1.8

	capsule.mesh = capsule_mesh
	capsule.position.y = 0.9

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.35, 0.42, 0.52)
	capsule.material_override = body_material

	resident.add_child(capsule)

	var name_label := Label3D.new()
	name_label.text = display_name
	name_label.position.y = 2.1
	name_label.font_size = 28
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	resident.add_child(name_label)

	var area := Area3D.new()
	area.name = "NPCInteractionArea"
	area.collision_layer = 1
	area.collision_mask = 1

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5

	collision.shape = sphere
	area.add_child(collision)

	resident.add_child(area)

	resident.position = _get_resident_position(
		village,
		resident_nodes.size()
	)

	village.add_child(resident)

	resident_nodes[npc_id] = resident

	var settlement: Dictionary = settlements[village_id]
	var ids: Array = settlement["resident_ids"]

	ids.append(npc_id)
	settlement["resident_ids"] = ids
	settlements[village_id] = settlement

	_add_map_icon(
		npc_id,
		display_name,
		str(OCCUPATION_ICONS.get(occupation, "👤")),
		"npc",
		resident.global_position
	)

	resident_created.emit(npc_id, village_id)


func _get_resident_position(
	village: Node3D,
	index: int
) -> Vector3:

	var positions := [
		Vector3(-3.0, 0.0, -1.0),
		Vector3(3.0, 0.0, -1.0),
		Vector3(-3.0, 0.0, 2.0),
		Vector3(3.0, 0.0, 2.0),
		Vector3(0.0, 0.0, 4.0),
		Vector3(0.0, 0.0, -5.0)
	]

	return positions[index % positions.size()]


func _add_map_icon(
	icon_id: String,
	display_name: String,
	icon: String,
	category: String,
	position: Vector3
) -> void:

	map_icon_records.append({
		"id": icon_id,
		"name": display_name,
		"icon": icon,
		"category": category,
		"world_id": world_id,
		"position": position
	})


func get_settlements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for settlement in settlements.values():
		result.append(settlement.duplicate(true))

	return result


func get_settlement(settlement_id: String) -> Dictionary:
	return settlements.get(
		settlement_id,
		{}
	).duplicate(true)


func get_village_residents(settlement_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var settlement := get_settlement(settlement_id)

	if settlement.is_empty():
		return result

	for npc_id in settlement["resident_ids"]:
		if npc_society != null:
			result.append(npc_society.get_npc(str(npc_id)))

	return result


func get_map_icons(category: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for record in map_icon_records:
		if not category.is_empty():
			if str(record["category"]) != category:
				continue

		result.append(record.duplicate(true))

	return result


func get_village_count() -> int:
	return settlements.size()


func get_resident_count() -> int:
	return resident_nodes.size()
