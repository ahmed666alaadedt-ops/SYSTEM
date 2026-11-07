extends Node3D
class_name SystemFantasySettlementManager

## SYSTEM WORLD - Fantasy Kingdoms and Settlements
## Villages, kingdom capitals, buildings and map registration.

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


const KINGDOM_DATA := [
	{
		"id": "elven_kingdom_capital",
		"name": "Lethariel - عاصمة الإلف",
		"region": "enchanted_forest",
		"position": Vector3(-92.0, 0.0, 88.0),
		"icon": "🌿",
		"style": "elven",
		"wall": Color(0.20, 0.39, 0.28),
		"roof": Color(0.12, 0.28, 0.22),
		"stone": Color(0.56, 0.66, 0.49)
	},
	{
		"id": "human_kingdom_capital",
		"name": "Aurelia - عاصمة البشر",
		"region": "ancient_ruins",
		"position": Vector3(91.0, 0.0, 87.0),
		"icon": "👑",
		"style": "human",
		"wall": Color(0.57, 0.43, 0.29),
		"roof": Color(0.34, 0.16, 0.12),
		"stone": Color(0.72, 0.64, 0.49)
	},
	{
		"id": "beastfolk_kingdom_capital",
		"name": "Gorvann - عاصمة الأعراق الوحشية",
		"region": "dragon_mountains",
		"position": Vector3(-91.0, 0.0, -94.0),
		"icon": "🐺",
		"style": "beastfolk",
		"wall": Color(0.35, 0.25, 0.19),
		"roof": Color(0.20, 0.14, 0.12),
		"stone": Color(0.48, 0.39, 0.30)
	},
	{
		"id": "dwarven_kingdom_capital",
		"name": "Khaz Barum - عاصمة الأقزام",
		"region": "dragon_mountains",
		"position": Vector3(88.0, 0.0, -100.0),
		"icon": "⛏️",
		"style": "dwarven",
		"wall": Color(0.30, 0.32, 0.36),
		"roof": Color(0.16, 0.18, 0.22),
		"stone": Color(0.59, 0.57, 0.52)
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
var kingdoms: Dictionary = {}
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
		"SYSTEM FANTASY: Villages created: ",
		settlements.size()
	)

	print(
		"SYSTEM FANTASY: Kingdom capitals created: ",
		kingdoms.size()
	)

	return true


# ==================================================
# INITIALIZATION
# ==================================================

func _create_all_settlements() -> void:
	for village in VILLAGE_DATA:
		_create_settlement(village)

	_create_all_kingdoms()


func _create_all_kingdoms() -> void:
	for kingdom in KINGDOM_DATA:
		_create_kingdom_city(kingdom)


# ==================================================
# KINGDOM CITIES
# ==================================================

func _create_kingdom_city(data: Dictionary) -> void:
	var kingdom_id := str(data["id"])

	if kingdoms.has(kingdom_id):
		return

	var city := Node3D.new()
	city.name = kingdom_id
	city.position = data["position"]

	city.set_meta("system_kingdom_id", kingdom_id)
	city.set_meta("system_display_name", data["name"])
	city.set_meta("system_region_id", data["region"])
	city.set_meta("system_settlement_type", "kingdom_capital")
	city.set_meta("system_culture_style", data["style"])

	add_child(city)

	var wall_material := _kingdom_material(data["wall"])
	var roof_material := _kingdom_material(data["roof"])
	var stone_material := _kingdom_material(data["stone"])
	var wood_material := _kingdom_material(Color(0.34, 0.22, 0.14))
	var road_material := _kingdom_material(Color(0.31, 0.29, 0.25))

	# Central plaza.
	_kingdom_box(
		city,
		"CentralPlaza",
		Vector3(0.0, 0.08, 0.0),
		Vector3(30.0, 0.16, 30.0),
		road_material
	)

	# Defensive walls.
	_kingdom_box(
		city,
		"NorthWall",
		Vector3(0.0, 3.0, -25.0),
		Vector3(54.0, 6.0, 2.0),
		wall_material
	)

	_kingdom_box(
		city,
		"WestWall",
		Vector3(-26.0, 3.0, 0.0),
		Vector3(2.0, 6.0, 52.0),
		wall_material
	)

	_kingdom_box(
		city,
		"EastWall",
		Vector3(26.0, 3.0, 0.0),
		Vector3(2.0, 6.0, 52.0),
		wall_material
	)

	_kingdom_box(
		city,
		"SouthWallLeft",
		Vector3(-17.0, 3.0, 25.0),
		Vector3(18.0, 6.0, 2.0),
		wall_material
	)

	_kingdom_box(
		city,
		"SouthWallRight",
		Vector3(17.0, 3.0, 25.0),
		Vector3(18.0, 6.0, 2.0),
		wall_material
	)

	# Main entrance towers.
	for side in [-1.0, 1.0]:
		_kingdom_tower(
			city,
			"GateTower",
			Vector3(side * 9.0, 0.0, 25.0),
			6.0,
			wall_material,
			roof_material
		)

	# Royal palace.
	_kingdom_box(
		city,
		"RoyalPalaceBase",
		Vector3(0.0, 3.0, -5.0),
		Vector3(17.0, 6.0, 14.0),
		stone_material
	)

	_kingdom_roof(
		city,
		"RoyalPalaceRoof",
		Vector3(0.0, 7.2, -5.0),
		Vector3(19.0, 3.0, 16.0),
		roof_material
	)

	var palace_corners := [
		Vector3(-7.0, 0.0, -11.0),
		Vector3(7.0, 0.0, -11.0),
		Vector3(-7.0, 0.0, 1.0),
		Vector3(7.0, 0.0, 1.0)
	]

	for corner in palace_corners:
		_kingdom_tower(
			city,
			"PalaceTower",
			corner,
			9.0,
			stone_material,
			roof_material
		)

	# Important city facilities.
	var building_specs := [
		[
			"GuildHall",
			Vector3(-15.0, 0.0, -13.0),
			Vector3(8.0, 5.0, 7.0)
		],
		[
			"MarketHall",
			Vector3(15.0, 0.0, -13.0),
			Vector3(8.0, 4.0, 7.0)
		],
		[
			"BlacksmithForge",
			Vector3(-16.0, 0.0, 4.0),
			Vector3(8.0, 4.0, 7.0)
		],
		[
			"HealerSanctuary",
			Vector3(16.0, 0.0, 4.0),
			Vector3(8.0, 5.0, 7.0)
		],
		[
			"TravelersInn",
			Vector3(-15.0, 0.0, 16.0),
			Vector3(8.0, 4.0, 7.0)
		],
		[
			"GuardBarracks",
			Vector3(15.0, 0.0, 16.0),
			Vector3(8.0, 5.0, 7.0)
		],
		[
			"GrandTemple",
			Vector3(0.0, 0.0, -20.0),
			Vector3(10.0, 6.0, 7.0)
		]
	]

	for spec in building_specs:
		_kingdom_building(
			city,
			str(spec[0]),
			spec[1],
			spec[2],
			stone_material,
			roof_material,
			wood_material
		)

	# Residential district.
	for index in range(8):
		var angle := TAU * float(index) / 8.0

		var home_position := Vector3(
			cos(angle) * 21.0,
			0.0,
			sin(angle) * 21.0
		)

		_kingdom_building(
			city,
			"ResidentialHouse_%02d" % index,
			home_position,
			Vector3(5.0, 3.5, 5.0),
			wood_material,
			roof_material,
			wood_material
		)

	# City name sign.
	var sign := Label3D.new()
	sign.name = "KingdomCitySign"
	sign.text = str(data["name"])
	sign.position = Vector3(0.0, 11.0, 31.0)
	sign.font_size = 48
	sign.outline_size = 8
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	city.add_child(sign)

	# City discovery interaction.
	var interaction := Area3D.new()
	interaction.name = "KingdomCityInteraction"
	interaction.position = Vector3(0.0, 1.0, 29.0)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 5.0
	collision.shape = sphere

	interaction.add_child(collision)

	interaction.set_meta("system_location_id", kingdom_id)
	interaction.set_meta("system_region_id", data["region"])
	interaction.set_meta("system_display_name", data["name"])
	interaction.set_meta("system_location_type", 0)
	interaction.set_meta(
		"system_interaction_prompt",
		"اكتشاف عاصمة المملكة"
	)

	interaction.add_to_group("system_interactable")
	interaction.add_to_group("system_kingdom_city")

	city.add_child(interaction)

	_register_kingdom_map_location(data)

	kingdoms[kingdom_id] = {
		"id": kingdom_id,
		"name": data["name"],
		"region": data["region"],
		"position": data["position"],
		"style": data["style"],
		"city_node": city
	}


# ==================================================
# KINGDOM BUILDING HELPERS
# ==================================================

func _kingdom_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material


func _kingdom_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> MeshInstance3D:

	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := BoxMesh.new()
	mesh.size = size

	instance.mesh = mesh
	instance.position = position
	instance.material_override = material

	parent.add_child(instance)

	return instance


func _kingdom_roof(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> MeshInstance3D:

	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := PrismMesh.new()
	mesh.size = size

	instance.mesh = mesh
	instance.position = position
	instance.material_override = material

	parent.add_child(instance)

	return instance


func _kingdom_tower(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	height: float,
	stone: Material,
	roof: Material
) -> void:

	_kingdom_box(
		parent,
		node_name + "Body",
		position + Vector3.UP * (height * 0.5),
		Vector3(4.0, height, 4.0),
		stone
	)

	_kingdom_roof(
		parent,
		node_name + "Roof",
		position + Vector3.UP * (height + 1.5),
		Vector3(5.0, 3.0, 5.0),
		roof
	)


func _kingdom_building(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	wall: Material,
	roof: Material,
	wood: Material
) -> void:

	var building := Node3D.new()
	building.name = node_name
	building.position = position

	parent.add_child(building)

	_kingdom_box(
		building,
		"BuildingBody",
		Vector3(0.0, size.y * 0.5, 0.0),
		size,
		wall
	)

	_kingdom_roof(
		building,
		"BuildingRoof",
		Vector3(0.0, size.y + 1.0, 0.0),
		Vector3(size.x * 1.15, 2.0, size.z * 1.15),
		roof
	)

	_kingdom_box(
		building,
		"EntranceDoor",
		Vector3(0.0, 1.0, size.z * 0.5 + 0.04),
		Vector3(1.2, 2.0, 0.12),
		wood
	)


# ==================================================
# KINGDOM MAP CONNECTION
# ==================================================

func _register_kingdom_map_location(data: Dictionary) -> void:
	if map_manager != null:
		map_manager.register_location(
			str(world_id),
			str(data["id"]),
			str(data["region"]),
			str(data["name"]),
			0,
			data["position"],
			false
		)

	_add_map_icon(
		str(data["id"]),
		str(data["name"]),
		str(data["icon"]),
		"kingdom",
		data["position"]
	)


func get_kingdoms() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for kingdom in kingdoms.values():
		var record: Dictionary = kingdom.duplicate()
		record.erase("city_node")
		result.append(record)

	return result


func get_kingdom_count() -> int:
	return kingdoms.size()


# ==================================================
# VILLAGES
# ==================================================

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


# ==================================================
# VILLAGE RESIDENTS
# ==================================================

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
	resident.set_meta(
		"system_interaction_prompt",
		"Talk to " + display_name
	)

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


# ==================================================
# MAP ICONS AND PUBLIC API
# ==================================================

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


func get_kingdom_count() -> int:
	return kingdoms.size()


func get_kingdoms() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for kingdom in kingdoms.values():
		var record: Dictionary = kingdom.duplicate()
		record.erase("city_node")
		result.append(record)

	return result
