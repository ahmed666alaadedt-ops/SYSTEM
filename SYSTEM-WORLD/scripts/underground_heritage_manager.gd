extends Node3D
class_name UndergroundHeritageManager

## Hidden underground passages and heritage markets for the modern world.
## This is a first procedural exploration layout, not a complete navigable quest system.

const SITE_DATA := [
	{"name":"BaghdadOldSouk","label":"Baghdad Heritage Souk","x":18.0,"z":24.0,"kind":"market"},
	{"name":"BaghdadRiverCatacombs","label":"River Catacombs","x":-42.0,"z":72.0,"kind":"catacomb"},
	{"name":"ParisStonePassages","label":"Old Stone Passages","x":-300.0,"z":110.0,"kind":"catacomb"},
	{"name":"CairoBuriedBazaar","label":"Buried Bazaar","x":-80.0,"z":330.0,"kind":"market"},
	{"name":"LondonVaultMarket","label":"Vault Market","x":-420.0,"z":-90.0,"kind":"market"}
]

var _stone: StandardMaterial3D
var _floor: StandardMaterial3D
var _dark: StandardMaterial3D
var _gold: StandardMaterial3D
var _wood: StandardMaterial3D


func _ready() -> void:
	name = "UndergroundHeritageNetwork"
	_create_materials()
	for site in SITE_DATA:
		_build_site(site)
	print("SYSTEM WORLD: underground heritage passages generated: ", SITE_DATA.size())


func _create_materials() -> void:
	_stone = _material(Color(0.31, 0.29, 0.25), 0.94)
	_floor = _material(Color(0.22, 0.21, 0.19), 0.98)
	_dark = _material(Color(0.012, 0.014, 0.016), 1.0)
	_gold = _material(Color(0.62, 0.43, 0.16), 0.48, 0.42)
	_wood = _material(Color(0.24, 0.13, 0.065), 0.82)


func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


func _build_site(site: Dictionary) -> void:
	var x := float(site["x"])
	var z := float(site["z"])
	var entrance := Node3D.new()
	entrance.name = str(site["name"])
	entrance.position = Vector3(x, 0.0, z)
	add_child(entrance)

	# A visible stone hatch/arch marks the secret entrance at ground level.
	_add_box(entrance, "EntranceStoneLintel", Vector3(0, 2.5, -4), Vector3(5.8, 0.8, 1.0), _stone, false)
	_add_box(entrance, "EntranceLeftPillar", Vector3(-2.5, 1.2, -4), Vector3(0.8, 2.4, 1.0), _stone, false)
	_add_box(entrance, "EntranceRightPillar", Vector3(2.5, 1.2, -4), Vector3(0.8, 2.4, 1.0), _stone, false)
	_add_box(entrance, "EntranceDarkness", Vector3(0, 1.0, -3.92), Vector3(3.9, 2.0, 0.12), _dark, false)

	# The first stair section descends into a connected underground chamber.
	for step in range(8):
		var y := -float(step + 1) * 1.25
		var step_z := -float(step) * 1.65
		_add_box(entrance, "StoneDescentStep", Vector3(0, y, step_z), Vector3(3.2, 0.35, 1.9), _stone, true)

	var underground := Node3D.new()
	underground.name = "UndergroundChambers"
	underground.position = Vector3(0, -11.5, 1.5)
	entrance.add_child(underground)
	_build_main_chamber(underground, str(site["kind"]) == "market")
	_build_side_passage(underground)
	if str(site["kind"]) == "market":
		_build_market_stalls(underground)


func _build_main_chamber(parent: Node3D, is_market: bool) -> void:
	var room_width := 22.0 if is_market else 17.0
	var room_depth := 30.0 if is_market else 25.0
	_add_box(parent, "UndergroundStoneFloor", Vector3(0, -0.25, -17), Vector3(room_width, 0.5, room_depth), _floor, true)
	_add_box(parent, "CeilingStoneSlab", Vector3(0, 5.5, -17), Vector3(room_width, 0.7, room_depth), _stone, true)
	_add_box(parent, "LeftBuriedWall", Vector3(-room_width * 0.5, 2.6, -17), Vector3(0.7, 5.2, room_depth), _stone, true)
	_add_box(parent, "RightBuriedWall", Vector3(room_width * 0.5, 2.6, -17), Vector3(0.7, 5.2, room_depth), _stone, true)
	_add_box(parent, "FarBuriedWall", Vector3(0, 2.6, -17 - room_depth * 0.5), Vector3(room_width, 5.2, 0.7), _stone, true)
	_add_box(parent, "BackDarkPassage", Vector3(0, 2.0, -17 - room_depth * 0.5 + 0.4), Vector3(4.0, 3.5, 0.1), _dark, false)

	for side in [-1.0, 1.0]:
		for pillar_index in range(3):
			_add_box(
				parent,
				"AncientSupportPillar",
				Vector3(side * (room_width * 0.5 - 1.4), 2.5, -7.0 - float(pillar_index) * 9.0),
				Vector3(1.5, 5.0, 1.5),
				_stone,
				true
			)


func _build_side_passage(parent: Node3D) -> void:
	# A short side tunnel branches from the chamber; its dark end hints at a
	# larger future dungeon network without generating a huge empty cave.
	_add_box(parent, "SidePassageFloor", Vector3(13.0, -0.2, -20.0), Vector3(12.0, 0.4, 4.2), _floor, true)
	_add_box(parent, "SidePassageLeftWall", Vector3(13.0, 1.7, -22.1), Vector3(12.0, 3.8, 0.45), _stone, true)
	_add_box(parent, "SidePassageRightWall", Vector3(13.0, 1.7, -17.9), Vector3(12.0, 3.8, 0.45), _stone, true)
	_add_box(parent, "SidePassageEndShadow", Vector3(19.0, 1.6, -20.0), Vector3(0.15, 3.0, 3.8), _dark, false)


func _build_market_stalls(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		for index in range(3):
			var z := -8.0 - float(index) * 8.0
			var stall := Node3D.new()
			stall.name = "HeritageMarketStall"
			stall.position = Vector3(side * 7.0, 0.0, z)
			parent.add_child(stall)
			_add_box(stall, "WoodenCounter", Vector3(0, 1.0, 0), Vector3(3.0, 1.0, 1.5), _wood, true)
			_add_box(stall, "GoldTrim", Vector3(0, 1.55, -0.05), Vector3(3.2, 0.12, 1.65), _gold, false)
			_add_box(stall, "Canopy", Vector3(0, 2.7, 0), Vector3(3.8, 0.18, 2.3), _wood, false)
			for item_index in range(3):
				var item := MeshInstance3D.new()
				item.name = "AntiqueDisplay"
				var mesh := SphereMesh.new()
				mesh.radius = 0.28
				mesh.height = 0.55
				item.mesh = mesh
				item.position = Vector3(-0.8 + float(item_index) * 0.8, 1.7, 0)
				item.material_override = _gold if item_index == 1 else _stone
				stall.add_child(item)


func _add_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material,
	with_collision: bool
) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	parent.add_child(visual)
	if not with_collision:
		return

	var body := StaticBody3D.new()
	body.name = node_name + "Body"
	body.position = position
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
