extends Node

# SYSTEM WORLD - Fantasy City Interior Expansion
# Creates enterable interiors for kingdom facilities and homes.

const BuildingEntryInteractionScript = preload(
	"res://scripts/fantasy_building_entry_interaction.gd"
)

var _completed := false


func _process(_delta: float) -> void:
	if _completed:
		return

	var tree := get_tree()
	if tree == null:
		return

	var root := tree.root
	if root == null:
		return

	var manager := root.find_child(
		"FantasySettlementManager",
		true,
		false
	)

	if manager == null:
		return

	var kingdom_data = manager.get("kingdoms")

	if typeof(kingdom_data) != TYPE_DICTIONARY:
		return

	if kingdom_data.size() < 4:
		return

	var built_count := _build_all_city_interiors(manager)

	if built_count > 0:
		_completed = true
		print(
			"SYSTEM FANTASY: Interior buildings created: ",
			built_count
		)


func _build_all_city_interiors(manager: Node) -> int:
	var built_count := 0

	for city_node in manager.get_children():
		if not city_node is Node3D:
			continue

		var city := city_node as Node3D

		if not city.has_meta("system_kingdom_id"):
			continue

		for building_node in city.get_children():
			if not building_node is Node3D:
				continue

			var building := building_node as Node3D

			if not _is_supported_building(building.name):
				continue

			if _build_building_interior(building, city):
				built_count += 1

	return built_count


func _is_supported_building(building_name: String) -> bool:
	var supported := [
		"GuildHall",
		"MarketHall",
		"BlacksmithForge",
		"HealerSanctuary",
		"TravelersInn",
		"GuardBarracks",
		"GrandTemple"
	]

	if supported.has(building_name):
		return true

	return building_name.begins_with("ResidentialHouse_")


func _build_building_interior(
	building: Node3D,
	city: Node3D
) -> bool:

	if building.has_meta("system_interior_built"):
		return false

	var body := building.get_node_or_null(
		"BuildingBody"
	) as MeshInstance3D

	if body == null:
		return false

	var box_mesh := body.mesh as BoxMesh
	if box_mesh == null:
		return false

	var dimensions := box_mesh.size

	# Hide the original solid wall block and entrance door.
	body.visible = false

	var old_door := building.get_node_or_null(
		"EntranceDoor"
	) as MeshInstance3D

	if old_door != null:
		old_door.visible = false

	var interior := Node3D.new()
	interior.name = "WalkableInterior"
	building.add_child(interior)

	var half_x := dimensions.x * 0.5
	var half_z := dimensions.z * 0.5
	var wall_height := maxf(2.8, dimensions.y - 0.3)

	var wall_material := _make_material(
		Color(0.48, 0.38, 0.28)
	)

	var floor_material := _make_material(
		Color(0.25, 0.21, 0.17)
	)

	var wood_material := _make_material(
		Color(0.30, 0.17, 0.09)
	)

	var dark_material := _make_material(
		Color(0.12, 0.11, 0.10)
	)

	var accent_material := _make_material(
		Color(0.55, 0.37, 0.17),
		Color(0.12, 0.06, 0.01)
	)

	# Interior floor.
	_add_solid_box(
		interior,
		"InteriorFloor",
		Vector3(0.0, 0.12, 0.0),
		Vector3(dimensions.x, 0.24, dimensions.z),
		floor_material
	)

	# Left and right walls.
	_add_solid_box(
		interior,
		"LeftInteriorWall",
		Vector3(
			-half_x + 0.08,
			wall_height * 0.5 + 0.24,
			0.0
		),
		Vector3(0.16, wall_height, dimensions.z),
		wall_material
	)

	_add_solid_box(
		interior,
		"RightInteriorWall",
		Vector3(
			half_x - 0.08,
			wall_height * 0.5 + 0.24,
			0.0
		),
		Vector3(0.16, wall_height, dimensions.z),
		wall_material
	)

	# Back wall.
	_add_solid_box(
		interior,
		"BackInteriorWall",
		Vector3(
			0.0,
			wall_height * 0.5 + 0.24,
			-half_z + 0.08
		),
		Vector3(dimensions.x, wall_height, 0.16),
		wall_material
	)

	# Front wall with an open entrance.
	var door_width := minf(1.8, dimensions.x * 0.4)
	var segment_width := (dimensions.x - door_width) * 0.5

	_add_solid_box(
		interior,
		"FrontLeftWall",
		Vector3(
			-(door_width * 0.5 + segment_width * 0.5),
			wall_height * 0.5 + 0.24,
			half_z - 0.08
		),
		Vector3(segment_width, wall_height, 0.16),
		wall_material
	)

	_add_solid_box(
		interior,
		"FrontRightWall",
		Vector3(
			door_width * 0.5 + segment_width * 0.5,
			wall_height * 0.5 + 0.24,
			half_z - 0.08
		),
		Vector3(segment_width, wall_height, 0.16),
		wall_material
	)

	# Warm interior light.
	var light := OmniLight3D.new()
	light.name = "InteriorWarmLight"
	light.position = Vector3(0.0, wall_height - 0.2, 0.0)
	light.light_color = Color(1.0, 0.78, 0.52)
	light.light_energy = 0.85
	light.omni_range = maxf(
		10.0,
		maxf(dimensions.x, dimensions.z) * 1.6
	)
	light.shadow_enabled = false
	interior.add_child(light)

	# Furniture according to building type.
	_build_facility_furniture(
		interior,
		building.name,
		dimensions,
		wood_material,
		dark_material,
		accent_material
	)

	# Building sign.
	var sign := Label3D.new()
	sign.name = "InteriorBuildingSign"
	sign.text = _get_building_display_name(building.name)
	sign.position = Vector3(
		0.0,
		wall_height + 1.2,
		half_z + 0.4
	)
	sign.font_size = 30
	sign.outline_size = 6
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	building.add_child(sign)

	# Entry, exit, and discovery interactions.
	_add_building_interaction(
		building,
		city,
		half_z
	)

	building.set_meta("system_interior_built", true)

	return true


func _build_facility_furniture(
	parent: Node3D,
	building_name: String,
	dimensions: Vector3,
	wood: Material,
	dark: Material,
	accent: Material
) -> void:

	var back_z := -dimensions.z * 0.5 + 0.8

	match building_name:

		"GuildHall":
			_add_visual_box(
				parent,
				"GuildNoticeBoard",
				Vector3(0.0, 1.8, back_z),
				Vector3(3.0, 2.0, 0.18),
				accent
			)

			_add_visual_box(
				parent,
				"GuildCentralTable",
				Vector3(0.0, 0.65, 0.0),
				Vector3(3.0, 0.25, 1.5),
				wood
			)

			_add_visual_box(
				parent,
				"GuildBenchLeft",
				Vector3(-2.1, 0.35, 0.0),
				Vector3(0.5, 0.7, 2.0),
				wood
			)

			_add_visual_box(
				parent,
				"GuildBenchRight",
				Vector3(2.1, 0.35, 0.0),
				Vector3(0.5, 0.7, 2.0),
				wood
			)

		"MarketHall":
			_add_visual_box(
				parent,
				"MarketCounter",
				Vector3(0.0, 0.65, back_z + 1.0),
				Vector3(dimensions.x * 0.65, 1.3, 0.8),
				wood
			)

			_add_visual_box(
				parent,
				"MarketShelfLeft",
				Vector3(-dimensions.x * 0.32, 1.0, 0.0),
				Vector3(0.45, 2.0, 2.5),
				dark
			)

			_add_visual_box(
				parent,
				"MarketShelfRight",
				Vector3(dimensions.x * 0.32, 1.0, 0.0),
				Vector3(0.45, 2.0, 2.5),
				dark
			)

		"BlacksmithForge":
			_add_visual_box(
				parent,
				"ForgeFurnace",
				Vector3(-dimensions.x * 0.28, 1.0, back_z + 0.8),
				Vector3(1.8, 2.0, 1.5),
				dark
			)

			_add_visual_box(
				parent,
				"BlacksmithAnvil",
				Vector3(1.2, 0.6, 0.0),
				Vector3(1.3, 1.2, 0.9),
				accent
			)

			_add_visual_box(
				parent,
				"WeaponRack",
				Vector3(dimensions.x * 0.32, 1.2, back_z + 0.8),
				Vector3(0.35, 2.4, 2.0),
				wood
			)

		"HealerSanctuary":
			_add_visual_box(
				parent,
				"HealingBedLeft",
				Vector3(-dimensions.x * 0.27, 0.4, 0.0),
				Vector3(2.0, 0.8, 3.0),
				wood
			)

			_add_visual_box(
				parent,
				"HealingBedRight",
				Vector3(dimensions.x * 0.27, 0.4, 0.0),
				Vector3(2.0, 0.8, 3.0),
				wood
			)

			_add_visual_box(
				parent,
				"MedicineCabinet",
				Vector3(0.0, 1.1, back_z + 0.6),
				Vector3(2.5, 2.2, 0.6),
				accent
			)

		"TravelersInn":
			_add_visual_box(
				parent,
				"InnReceptionCounter",
				Vector3(0.0, 0.65, back_z + 0.7),
				Vector3(dimensions.x * 0.55, 1.3, 0.8),
				wood
			)

			_add_visual_box(
				parent,
				"InnDiningTable",
				Vector3(0.0, 0.6, 1.0),
				Vector3(2.2, 1.0, 1.5),
				wood
			)

			_add_visual_box(
				parent,
				"InnGuestBed",
				Vector3(-dimensions.x * 0.28, 0.4, -0.2),
				Vector3(1.8, 0.8, 2.5),
				accent
			)

		"GuardBarracks":
			_add_visual_box(
				parent,
				"BarracksWeaponRack",
				Vector3(0.0, 1.2, back_z + 0.6),
				Vector3(dimensions.x * 0.6, 2.4, 0.4),
				dark
			)

			for index in range(2):
				_add_visual_box(
					parent,
					"BarracksBed_%02d" % index,
					Vector3(-2.0 + float(index) * 4.0, 0.4, 1.0),
					Vector3(1.7, 0.8, 2.5),
					wood
				)

		"GrandTemple":
			_add_visual_box(
				parent,
				"TempleAltar",
				Vector3(0.0, 0.8, back_z + 1.0),
				Vector3(2.5, 1.6, 1.4),
				accent
			)

			for side in [-1.0, 1.0]:
				_add_visual_box(
					parent,
					"TemplePillar",
					Vector3(side * 2.7, 1.5, -0.5),
					Vector3(0.55, 3.0, 0.55),
					dark
				)

		_:
			# Residential home furniture.
			_add_visual_box(
				parent,
				"HomeBed",
				Vector3(-1.0, 0.4, back_z + 1.4),
				Vector3(2.0, 0.8, 2.5),
				accent
			)

			_add_visual_box(
				parent,
				"HomeTable",
				Vector3(1.0, 0.6, 0.8),
				Vector3(1.5, 1.0, 1.2),
				wood
			)

			_add_visual_box(
				parent,
				"HomeStorage",
				Vector3(dimensions.x * 0.3, 1.0, back_z + 0.5),
				Vector3(1.0, 2.0, 0.8),
				dark
			)


func _add_building_interaction(
	building: Node3D,
	city: Node3D,
	half_z: float
) -> void:

	# Main entrance and map discovery point.
	var area := Area3D.new()
	area.name = "BuildingDiscoveryInteraction"
	area.position = Vector3(0.0, 1.0, half_z + 1.8)
	area.collision_layer = 1
	area.collision_mask = 1

	area.set_script(BuildingEntryInteractionScript)
	area.call(
		"configure",
		building,
		half_z,
		false
	)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.5
	collision.shape = sphere
	area.add_child(collision)

	var kingdom_id := str(
		city.get_meta("system_kingdom_id", "fantasy_kingdom")
	)

	var region_id := str(
		city.get_meta("system_region_id", "fantasy_region")
	)

	var display_name := _get_building_display_name(building.name)

	area.set_meta(
		"system_location_id",
		kingdom_id + "_" + building.name.to_lower()
	)

	area.set_meta("system_region_id", region_id)
	area.set_meta("system_display_name", display_name)
	area.set_meta("system_location_type", 0)
	area.set_meta(
		"system_interaction_prompt",
		"ادخل إلى " + display_name
	)

	area.add_to_group("system_interactable")
	area.add_to_group("system_kingdom_building")

	building.add_child(area)

	# Interior exit point.
	var exit_area := Area3D.new()
	exit_area.name = "BuildingExitInteraction"
	exit_area.position = Vector3(
		0.0,
		1.0,
		half_z - 1.0
	)
	exit_area.collision_layer = 1
	exit_area.collision_mask = 0

	exit_area.set_script(BuildingEntryInteractionScript)
	exit_area.call(
		"configure",
		building,
		half_z,
		true
	)

	var exit_collision := CollisionShape3D.new()
	var exit_sphere := SphereShape3D.new()
	exit_sphere.radius = 1.4
	exit_collision.shape = exit_sphere
	exit_area.add_child(exit_collision)

	exit_area.set_meta(
		"system_interaction_prompt",
		"اخرج إلى المدينة"
	)

	exit_area.add_to_group("system_interactable")
	exit_area.add_to_group("system_kingdom_building_exit")

	building.add_child(exit_area)


func _get_building_display_name(building_name: String) -> String:
	var names := {
		"GuildHall": "نقابة المملكة",
		"MarketHall": "السوق الرئيسي",
		"BlacksmithForge": "حدادة المملكة",
		"HealerSanctuary": "مركز العلاج",
		"TravelersInn": "نُزل المسافرين",
		"GuardBarracks": "ثكنة الحراس",
		"GrandTemple": "المعبد الكبير"
	}

	if building_name.begins_with("ResidentialHouse_"):
		return "منزل سكني"

	return str(names.get(building_name, "مبنى المملكة"))


func _make_material(
	color: Color,
	emission: Color = Color.BLACK
) -> StandardMaterial3D:

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9

	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 0.8

	return material


func _add_visual_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> MeshInstance3D:

	# Furniture now has a physical collision body.
	var body := StaticBody3D.new()
	body.name = node_name + "Body"
	body.position = position

	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := BoxMesh.new()
	mesh.size = size

	instance.mesh = mesh
	instance.material_override = material
	body.add_child(instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size

	collision.shape = shape
	body.add_child(collision)

	parent.add_child(body)

	return instance


func _add_solid_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> StaticBody3D:

	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position

	var visual := MeshInstance3D.new()
	visual.name = "Visual"

	var mesh := BoxMesh.new()
	mesh.size = size

	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size

	collision.shape = shape
	body.add_child(collision)

	parent.add_child(body)

	return body
