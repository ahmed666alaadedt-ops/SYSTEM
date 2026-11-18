extends Node3D
class_name UndergroundHeritageManager

const UndergroundInteractableScript = preload("res://scripts/underground_interactable.gd")

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
var _terrain: Node


func _ready() -> void:
	name = "UndergroundHeritageNetwork"
	_terrain = get_parent().get_node_or_null("ModernContinent")
	_create_materials()
	for site in SITE_DATA:
		_build_site(site)
	_build_baghdad_link()
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
	var surface_y := 0.0
	if _terrain != null and _terrain.has_method("get_terrain_height"):
		surface_y = float(_terrain.call("get_terrain_height", x, z))
	entrance.position = Vector3(x, surface_y, z)
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
	_build_secret_vault(underground, str(site["kind"]) == "market", str(site["name"]))
	_build_torch_lighting(underground)
	if str(site["kind"]) == "market":
		_build_market_stalls(underground)


func _build_main_chamber(parent: Node3D, is_market: bool) -> void:
	var room_width := 22.0 if is_market else 17.0
	var room_depth := 30.0 if is_market else 25.0
	_add_box(parent, "UndergroundStoneFloor", Vector3(0, -0.25, -17), Vector3(room_width, 0.5, room_depth), _floor, true)
	_add_box(parent, "CeilingStoneSlab", Vector3(0, 5.5, -17), Vector3(room_width, 0.7, room_depth), _stone, true)
	_add_box(parent, "LeftBuriedWall", Vector3(-room_width * 0.5, 2.6, -17), Vector3(0.7, 5.2, room_depth), _stone, true)
	_add_box(parent, "RightBuriedWall", Vector3(room_width * 0.5, 2.6, -17), Vector3(0.7, 5.2, room_depth), _stone, true)
	# Split rear wall leaves a real opening into the sealed lower passage.
	var rear_z := -17.0 - room_depth * 0.5
	var wall_segment_width := (room_width - 5.0) * 0.5
	_add_box(parent, "FarBuriedWallLeft", Vector3(-(5.0 + wall_segment_width) * 0.5, 2.6, rear_z), Vector3(wall_segment_width, 5.2, 0.7), _stone, true)
	_add_box(parent, "FarBuriedWallRight", Vector3((5.0 + wall_segment_width) * 0.5, 2.6, rear_z), Vector3(wall_segment_width, 5.2, 0.7), _stone, true)
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



func _build_secret_vault(parent: Node3D, is_market: bool, site_name: String) -> void:
	# A narrow rear corridor physically connects the main chamber to a hidden vault.
	_add_box(parent, "VaultPassageFloor", Vector3(0, -0.25, -39.0), Vector3(5.0, 0.5, 14.0), _floor, true)
	_add_box(parent, "VaultPassageLeftWall", Vector3(-2.7, 2.2, -39.0), Vector3(0.5, 4.4, 14.0), _stone, true)
	_add_box(parent, "VaultPassageRightWall", Vector3(2.7, 2.2, -39.0), Vector3(0.5, 4.4, 14.0), _stone, true)
	_add_box(parent, "VaultPassageCeiling", Vector3(0, 4.55, -39.0), Vector3(5.8, 0.5, 14.0), _stone, true)

	# The vault is deliberately compact so it can later be populated with real quests and loot.
	_add_box(parent, "HiddenVaultFloor", Vector3(0, -0.25, -53.0), Vector3(14.0, 0.5, 14.0), _floor, true)
	_add_box(parent, "HiddenVaultCeiling", Vector3(0, 4.8, -53.0), Vector3(14.0, 0.6, 14.0), _stone, true)
	if site_name == "BaghdadOldSouk" or site_name == "BaghdadRiverCatacombs":
		# Openings on the facing sides allow the inter-site tunnel to meet both vaults.
		for side in [-1.0, 1.0]:
			for segment_z in [-57.5, -48.5]:
				_add_box(parent, "LinkedVaultSideWall", Vector3(side * 7.0, 2.2, segment_z), Vector3(0.6, 4.4, 5.0), _stone, true)
	else:
		_add_box(parent, "HiddenVaultLeftWall", Vector3(-7.0, 2.2, -53.0), Vector3(0.6, 4.4, 14.0), _stone, true)
		_add_box(parent, "HiddenVaultRightWall", Vector3(7.0, 2.2, -53.0), Vector3(0.6, 4.4, 14.0), _stone, true)
	_add_box(parent, "HiddenVaultBackWall", Vector3(0, 2.2, -60.0), Vector3(14.0, 4.4, 0.6), _stone, true)

	# Ancient stone gate frame and a visible sealed slab mark the vault's inner chamber.
	_add_box(parent, "VaultGateLeft", Vector3(-2.9, 2.0, -46.0), Vector3(0.55, 4.0, 0.65), _gold, false)
	_add_box(parent, "VaultGateRight", Vector3(2.9, 2.0, -46.0), Vector3(0.55, 4.0, 0.65), _gold, false)
	_add_box(parent, "VaultGateTop", Vector3(0, 4.1, -46.0), Vector3(6.3, 0.55, 0.65), _gold, false)
	_create_vault_door_interaction(parent)

	if is_market:
		_add_box(parent, "MerchantHiddenStrongbox", Vector3(0, 0.9, -54.0), Vector3(2.2, 1.5, 1.5), _wood, true)
		_add_box(parent, "StrongboxGoldBand", Vector3(0, 1.0, -53.2), Vector3(2.28, 0.18, 0.12), _gold, false)
	else:
		var relic_pedestal := MeshInstance3D.new()
		relic_pedestal.name = "AncientRelicPedestal"
		var pedestal_mesh := CylinderMesh.new()
		pedestal_mesh.top_radius = 1.0
		pedestal_mesh.bottom_radius = 1.35
		pedestal_mesh.height = 1.2
		relic_pedestal.mesh = pedestal_mesh
		relic_pedestal.position = Vector3(0, 0.35, -54.0)
		relic_pedestal.material_override = _stone
		parent.add_child(relic_pedestal)
		_add_box(parent, "RelicDisplayBlock", Vector3(0, 1.35, -54.0), Vector3(1.0, 1.0, 1.0), _gold, false)
		_create_relic_interaction(parent)

	# Recesses along the vault walls suggest further sealed branches for later expansion.
	for side in [-1.0, 1.0]:
		_add_box(parent, "SealedWallNiche", Vector3(side * 6.55, 1.7, -53.0), Vector3(0.12, 2.2, 3.0), _dark, false)


func _build_torch_lighting(parent: Node3D) -> void:
	var flame_material := StandardMaterial3D.new()
	flame_material.albedo_color = Color(1.0, 0.48, 0.12)
	flame_material.emission_enabled = true
	flame_material.emission = Color(1.0, 0.24, 0.045)
	flame_material.emission_energy_multiplier = 2.0

	for point in [
		Vector3(-8.5, 3.2, -10.0),
		Vector3(8.5, 3.2, -22.0),
		Vector3(0.0, 3.0, -39.0),
		Vector3(0.0, 3.0, -55.0)
	]:
		var flame := MeshInstance3D.new()
		flame.name = "AncientTorchFlame"
		var flame_mesh := SphereMesh.new()
		flame_mesh.radius = 0.22
		flame_mesh.height = 0.55
		flame.mesh = flame_mesh
		flame.position = point
		flame.material_override = flame_material
		parent.add_child(flame)

		var light := OmniLight3D.new()
		light.name = "AncientTorchLight"
		light.position = point
		light.light_color = Color(1.0, 0.55, 0.25)
		light.light_energy = 0.65
		light.omni_range = 9.0
		parent.add_child(light)



func _build_baghdad_link() -> void:
	# A real underground corridor links the Baghdad heritage souk vault to
	# the nearby river catacombs beneath the fictional modern-world map.
	var start := Vector2(25.0, -29.0)
	var finish := Vector2(-49.0, 19.0)
	var delta := finish - start
	var total_length := delta.length()
	var segment_count := 12
	var segment_length := total_length / float(segment_count) + 0.35
	var yaw := atan2(delta.x, delta.y)
	var link_root := Node3D.new()
	link_root.name = "BaghdadSoukToRiverCatacombsTunnel"
	add_child(link_root)

	for index in range(segment_count):
		var t := (float(index) + 0.5) / float(segment_count)
		var point := start.lerp(finish, t)
		var surface_y := 0.0
		if _terrain != null and _terrain.has_method("get_terrain_height"):
			surface_y = float(_terrain.call("get_terrain_height", point.x, point.y))
		var segment := Node3D.new()
		segment.name = "UndergroundLinkSegment"
		segment.position = Vector3(point.x, surface_y - 9.3, point.y)
		segment.rotation.y = yaw
		link_root.add_child(segment)

		_add_box(segment, "LinkStoneFloor", Vector3(0, -2.1, 0), Vector3(3.8, 0.35, segment_length), _floor, true)
		_add_box(segment, "LinkStoneCeiling", Vector3(0, 2.1, 0), Vector3(3.8, 0.35, segment_length), _stone, true)
		_add_box(segment, "LinkLeftWall", Vector3(-2.0, 0, 0), Vector3(0.35, 4.0, segment_length), _stone, true)
		_add_box(segment, "LinkRightWall", Vector3(2.0, 0, 0), Vector3(0.35, 4.0, segment_length), _stone, true)

		if index % 3 == 1:
			var light := OmniLight3D.new()
			light.name = "BaghdadTunnelLantern"
			light.position = Vector3(0, 1.25, 0)
			light.light_color = Color(1.0, 0.58, 0.29)
			light.light_energy = 0.55
			light.omni_range = 8.0
			segment.add_child(light)



func _create_vault_door_interaction(parent: Node3D) -> void:
	var target: Node3D = UndergroundInteractableScript.new()
	target.name = "VaultStoneDoorInteraction"
	target.set("action_type", "stone_door")
	target.set("action_target_path", ^"DoorBody")
	target.position = Vector3(0, 0, -39.0)
	target.add_to_group("system_interactable")
	target.set_meta("system_interaction_prompt", "اسحب الرافعة لفتح الباب الحجري")
	parent.add_child(target)

	var door_body := StaticBody3D.new()
	door_body.name = "DoorBody"
	door_body.position = Vector3(0, 1.9, -7.0)
	target.add_child(door_body)

	var door_visual := MeshInstance3D.new()
	door_visual.name = "AncientSlidingStoneSlab"
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(4.8, 3.8, 0.55)
	door_visual.mesh = door_mesh
	door_visual.material_override = _stone
	door_body.add_child(door_visual)

	var door_collision := CollisionShape3D.new()
	var door_shape := BoxShape3D.new()
	door_shape.size = door_mesh.size
	door_collision.shape = door_shape
	door_body.add_child(door_collision)

	var lever_area := Area3D.new()
	lever_area.name = "LeverInteractionArea"
	lever_area.position = Vector3(3.4, 1.2, 0.0)
	target.add_child(lever_area)
	var lever_shape := CollisionShape3D.new()
	var lever_box := BoxShape3D.new()
	lever_box.size = Vector3(1.4, 2.0, 1.4)
	lever_shape.shape = lever_box
	lever_area.add_child(lever_shape)

	_add_box(target, "GoldenLeverHandle", Vector3(3.4, 1.25, -0.25), Vector3(0.18, 1.1, 0.18), _gold, false)
	_add_box(target, "GoldenLeverBase", Vector3(3.4, 0.65, -0.25), Vector3(0.65, 0.18, 0.45), _gold, false)


func _create_relic_interaction(parent: Node3D) -> void:
	var target: Node3D = UndergroundInteractableScript.new()
	target.name = "AncientRelicInteraction"
	target.set("action_type", "relic")
	target.position = Vector3(0, 1.0, -54.0)
	target.add_to_group("system_interactable")
	target.set_meta("system_interaction_prompt", "افحص الأثر القديم")
	parent.add_child(target)

	var relic_area := Area3D.new()
	relic_area.name = "RelicInteractionArea"
	target.add_child(relic_area)
	var relic_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.8
	relic_shape.shape = sphere
	relic_area.add_child(relic_shape)
