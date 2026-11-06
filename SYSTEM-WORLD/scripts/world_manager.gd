
extends Node3D
class_name WorldManager

const ForestManagerScript = preload("res://scripts/forest_manager.gd")
const MountainManagerScript = preload("res://scripts/mountain_manager.gd")
const WaterwaysManagerScript = preload("res://scripts/waterways_manager.gd")
const MarineEnvironmentManagerScript = preload("res://scripts/marine_environment_manager.gd")
const GreedIslandManagerScript = preload("res://scripts/greed_island_manager.gd")
const HistoricalWorldManagerScript = preload("res://scripts/historical_world_manager.gd/historical_world_manager.gd")
const FantasyWorldManagerScript = preload("res://scripts/fantasy_world_manager.gd")

signal world_changed(world_id: int)

enum WorldID {
	FANTASY,
	MYTHOLOGY,
	REALISTIC,
	GREED_ISLAND
}

const WORLD_NAMES := {
	WorldID.FANTASY: "Fantasy World",
	WorldID.MYTHOLOGY: "Historical & Civilizations World",
	WorldID.REALISTIC: "Modern Realistic World",
	WorldID.GREED_ISLAND: "Greed Island World"
}

var active_world: int = -1
var world_roots: Dictionary = {}


func _ready() -> void:
	create_worlds()
	switch_world(WorldID.REALISTIC)


func create_worlds() -> void:
	for world_id in WORLD_NAMES:
		var world_root := Node3D.new()
		world_root.name = WORLD_NAMES[world_id]
		world_root.visible = false
		world_root.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(world_root)
		world_roots[world_id] = world_root

	_create_fantasy_world()
	_create_modern_city()
	_create_historical_world()
	_create_greed_island()


# --------------------------------------------------
# WORLD SWITCHING
# --------------------------------------------------

func switch_world(world_id: int) -> void:
	if not world_roots.has(world_id):
		push_warning("SYSTEM WORLD: Unknown world ID.")
		return

	if active_world == world_id:
		return

	var previous_world := active_world
	var destination_root: Node3D = world_roots[world_id]

	for id in world_roots:
		var root: Node3D = world_roots[id]
		var is_selected := id == world_id

		root.visible = is_selected
		root.process_mode = (
			Node.PROCESS_MODE_INHERIT
			if is_selected
			else Node.PROCESS_MODE_DISABLED
		)

	if previous_world >= 0 and world_roots.has(previous_world):
		var previous_root: Node3D = world_roots[previous_world]
		var player := previous_root.get_node_or_null(
			"Player"
		) as CharacterBody3D

		if player != null:
			player.reparent(destination_root, true)
			player.velocity = Vector3.ZERO

			player.position = get_world_spawn_position(world_id)
			player.rotation = Vector3.ZERO

			var camera_rig := player.get_node_or_null(
				"SpringArm3D"
			) as SpringArm3D

			if camera_rig != null:
				camera_rig.rotation = Vector3(
					deg_to_rad(-10.0),
					0.0,
					0.0
				)

	active_world = world_id
	world_changed.emit(world_id)

	print(
		"SYSTEM WORLD: switched to ",
		get_world_name(world_id)
	)


func get_active_world() -> Node3D:
	return world_roots.get(active_world)


func get_world_root(world_id: int) -> Node3D:
	return world_roots.get(world_id)


func get_world_name(world_id: int) -> String:
	return WORLD_NAMES.get(world_id, "Unknown World")


func get_all_world_ids() -> Array:
	return WORLD_NAMES.keys()


func is_greed_island_active() -> bool:
	return active_world == WorldID.GREED_ISLAND


func is_combat_allowed() -> bool:
	return not is_greed_island_active()


func get_world_spawn_position(world_id: int) -> Vector3:
	if world_id == WorldID.GREED_ISLAND:
		return Vector3(0.0, 2.0, -45.0)

	return Vector3(0.0, 2.0, 0.0)


# --------------------------------------------------
# FANTASY WORLD
# --------------------------------------------------

func _create_fantasy_world() -> void:
	var root: Node3D = world_roots[WorldID.FANTASY]

	var fantasy_world := FantasyWorldManagerScript.new()
	fantasy_world.name = "FantasyWorldEnvironment"

	root.add_child(fantasy_world)

	print("SYSTEM WORLD: Fantasy World created.")


# --------------------------------------------------
# HISTORICAL & CIVILIZATIONS WORLD
# --------------------------------------------------

func _create_historical_world() -> void:
	var root: Node3D = world_roots[WorldID.MYTHOLOGY]

	var historical_world := HistoricalWorldManagerScript.new()
	historical_world.name = "HistoricalCivilizationsEnvironment"
	root.add_child(historical_world)

	print("SYSTEM WORLD: Historical & Civilizations world created.")


# --------------------------------------------------
# GREED ISLAND — PRIVATE ENVIRONMENT
# --------------------------------------------------

func _create_greed_island() -> void:
	var root: Node3D = world_roots[WorldID.GREED_ISLAND]

	var island := GreedIslandManagerScript.new()
	island.name = "GreedIslandEnvironment"

	island.set_meta("system_private_environment", true)
	island.set_meta("system_admin_test_mode", true)
	island.set_meta("system_combat_enabled", false)
	island.set_meta("system_isolated_memory", true)

	root.add_child(island)

	print("SYSTEM WORLD: Greed Island environment created.")
	print("SYSTEM WORLD: Admin exploration mode enabled.")
	print("SYSTEM WORLD: Combat disabled on Greed Island.")


# --------------------------------------------------
# MODERN WORLD CITY
# --------------------------------------------------

func _create_modern_city() -> void:
	var root: Node3D = world_roots[WorldID.REALISTIC]

	_create_road(root)
	_create_sidewalks(root)
	_create_city_buildings(root)
	_create_city_trees(root)
	_create_street_lights(root)
	_create_distant_skyline(root)
	_create_forest(root)
	_create_mountains(root)
	_create_waterways(root)
	_create_marine_environment(root)


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


func _add_box(
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


func _add_collision(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3
) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	collision.name = node_name

	var shape := BoxShape3D.new()
	shape.size = size

	collision.shape = shape
	collision.position = position
	parent.add_child(collision)

	return collision


func _create_road(parent: Node3D) -> void:
	var asphalt := _make_material(
		Color(0.075, 0.085, 0.10),
		0.95
	)

	var road := _add_box(
		parent,
		"MainCityRoad",
		Vector3(0, 0.025, -45),
		Vector3(12, 0.08, 150),
		asphalt
	)

	road.cast_shadow = false

	var line_material := _make_material(
		Color(0.88, 0.78, 0.48),
		0.8
	)

	for z in range(-115, 30, 10):
		_add_box(
			parent,
			"RoadCenterLine",
			Vector3(0, 0.075, float(z)),
			Vector3(0.16, 0.025, 4.0),
			line_material
		)


func _create_sidewalks(parent: Node3D) -> void:
	var sidewalk_material := _make_material(
		Color(0.38, 0.40, 0.42)
	)

	var curb_material := _make_material(
		Color(0.62, 0.63, 0.61)
	)

	for side in [-1.0, 1.0]:
		var sidewalk := StaticBody3D.new()
		sidewalk.name = "CitySidewalkCollision"
		sidewalk.position = Vector3(side * 7.3, 0, -45)
		parent.add_child(sidewalk)

		_add_box(
			sidewalk,
			"CitySidewalkVisual",
			Vector3.ZERO,
			Vector3(2.6, 0.20, 150),
			sidewalk_material
		)

		_add_collision(
			sidewalk,
			"SidewalkCollision",
			Vector3.ZERO,
			Vector3(2.6, 0.20, 150)
		)

		var curb := StaticBody3D.new()
		curb.name = "CityCurbCollision"
		curb.position = Vector3(side * 6.05, 0.16, -45)
		parent.add_child(curb)

		_add_box(
			curb,
			"CityCurbVisual",
			Vector3.ZERO,
			Vector3(0.25, 0.32, 150),
			curb_material
		)

		_add_collision(
			curb,
			"CurbCollision",
			Vector3.ZERO,
			Vector3(0.25, 0.32, 150)
		)


func _create_city_buildings(parent: Node3D) -> void:
	var building_colors := [
		Color(0.28, 0.32, 0.37),
		Color(0.38, 0.39, 0.40),
		Color(0.25, 0.29, 0.33),
		Color(0.46, 0.43, 0.37),
		Color(0.20, 0.25, 0.31)
	]

	for side in [-1.0, 1.0]:
		for index in range(7):
			var height := 12.0 + float((index * 7) % 4) * 5.0
			var width := 9.0 + float(index % 3) * 2.0
			var depth := 10.0

			var z_position := -float(index) * 19.0 - 8.0
			var x_position := side * (15.0 + width * 0.5)

			var building := StaticBody3D.new()
			building.name = "CityBuilding_%s_%02d" % [
				str(int(side)),
				index
			]

			building.position = Vector3(
				x_position,
				0,
				z_position
			)

			parent.add_child(building)

			var facade_material := _make_material(
				building_colors[index % building_colors.size()],
				0.72,
				0.12
			)

			_add_box(
				building,
				"BuildingStructure",
				Vector3(0, height * 0.5, 0),
				Vector3(width, height, depth),
				facade_material
			)

			_add_collision(
				building,
				"BuildingCollision",
				Vector3(0, height * 0.5, 0),
				Vector3(width, height, depth)
			)

			_create_building_windows(
				building,
				width,
				height,
				depth
			)

			_create_building_entrance(
				building,
				width,
				height,
				depth,
				index
			)

			var roof_material := _make_material(
				Color(0.12, 0.15, 0.19),
				0.6,
				0.2
			)

			_add_box(
				building,
				"BuildingRoof",
				Vector3(0, height + 0.15, 0),
				Vector3(width + 0.3, 0.3, depth + 0.3),
				roof_material
			)


func _create_building_windows(
	parent: Node3D,
	width: float,
	height: float,
	depth: float
) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.12, 0.22, 0.30)
	glass.metallic = 0.35
	glass.roughness = 0.2
	glass.emission_enabled = true
	glass.emission = Color(0.12, 0.22, 0.30)
	glass.emission_energy_multiplier = 0.35

	var window_width := 0.9
	var window_height := 1.25
	var spacing_x := 1.7
	var spacing_y := 2.5

	var columns := int(floor(width / spacing_x))
	var rows := int(floor(height / spacing_y))

	for row in range(rows):
		for column in range(columns):
			var x := (
				-float(columns - 1) * spacing_x * 0.5
				+ float(column) * spacing_x
			)

			var y := 2.0 + float(row) * spacing_y

			_add_box(
				parent,
				"FrontWindow",
				Vector3(
					x,
					y,
					-depth * 0.5 - 0.035
				),
				Vector3(
					window_width,
					window_height,
					0.07
				),
				glass
			)


func _create_building_entrance(
	parent: Node3D,
	width: float,
	height: float,
	depth: float,
	index: int
) -> void:
	var door_material := _make_material(
		Color(0.055, 0.075, 0.095),
		0.35,
		0.4
	)

	var frame_material := _make_material(
		Color(0.55, 0.48, 0.34),
		0.4,
		0.65
	)

	var door_width := 1.5
	var door_height := minf(2.8, height * 0.25)
	var door_z := -depth * 0.5 - 0.045

	_add_box(
		parent,
		"BuildingEntranceDoor_%02d" % index,
		Vector3(0, door_height * 0.5, door_z),
		Vector3(door_width, door_height, 0.09),
		door_material
	)

	_add_box(
		parent,
		"EntranceFrameTop",
		Vector3(0, door_height + 0.08, door_z),
		Vector3(door_width + 0.3, 0.16, 0.15),
		frame_material
	)

	for side in [-1.0, 1.0]:
		_add_box(
			parent,
			"EntranceFrameSide",
			Vector3(side * (door_width * 0.5 + 0.08), door_height * 0.5, door_z),
			Vector3(0.16, door_height, 0.15),
			frame_material
		)


func _create_city_trees(parent: Node3D) -> void:
	var trunk_material := _make_material(
		Color(0.25, 0.16, 0.10)
	)

	var leaves_material := _make_material(
		Color(0.10, 0.28, 0.16)
	)

	for side in [-1.0, 1.0]:
		for index in range(10):
			var tree := Node3D.new()
			tree.name = "StreetTree"
			tree.position = Vector3(
				side * 8.2,
				0,
				-float(index) * 14.0 - 5.0
			)
			parent.add_child(tree)

			var trunk_body := StaticBody3D.new()
			trunk_body.name = "TreeTrunkBody"
			tree.add_child(trunk_body)

			var trunk := MeshInstance3D.new()
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.16
			trunk_mesh.bottom_radius = 0.23
			trunk_mesh.height = 2.5
			trunk.mesh = trunk_mesh
			trunk.position.y = 1.25
			trunk.material_override = trunk_material
			trunk_body.add_child(trunk)

			var trunk_collision := CollisionShape3D.new()
			var trunk_shape := CylinderShape3D.new()
			trunk_shape.radius = 0.23
			trunk_shape.height = 2.5
			trunk_collision.shape = trunk_shape
			trunk_collision.position.y = 1.25
			trunk_body.add_child(trunk_collision)

			var crown := MeshInstance3D.new()
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 1.2
			crown_mesh.height = 2.2
			crown.mesh = crown_mesh
			crown.position.y = 3.0
			crown.material_override = leaves_material
			tree.add_child(crown)


func _create_street_lights(parent: Node3D) -> void:
	var pole_material := _make_material(
		Color(0.16, 0.18, 0.20),
		0.4,
		0.65
	)

	var lamp_material := StandardMaterial3D.new()
	lamp_material.albedo_color = Color(1.0, 0.82, 0.55)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(1.0, 0.68, 0.30)
	lamp_material.emission_energy_multiplier = 1.4

	for side in [-1.0, 1.0]:
		for index in range(7):
			var z := -float(index) * 22.0 - 10.0

			var pole_body := StaticBody3D.new()
			pole_body.name = "StreetLightPoleBody"
			pole_body.position = Vector3(side * 6.2, 0, z)
			parent.add_child(pole_body)

			var pole := MeshInstance3D.new()
			var pole_mesh := CylinderMesh.new()
			pole_mesh.top_radius = 0.07
			pole_mesh.bottom_radius = 0.12
			pole_mesh.height = 6.0

			pole.mesh = pole_mesh
			pole.position.y = 3.0
			pole.material_override = pole_material
			pole_body.add_child(pole)

			var pole_collision := CollisionShape3D.new()
			var pole_shape := CylinderShape3D.new()
			pole_shape.radius = 0.12
			pole_shape.height = 6.0
			pole_collision.shape = pole_shape
			pole_collision.position.y = 3.0
			pole_body.add_child(pole_collision)

			_add_box(
				parent,
				"StreetLampArm",
				Vector3(side * 5.8, 5.8, z),
				Vector3(0.9, 0.10, 0.12),
				pole_material
			)

			_add_box(
				parent,
				"StreetLampGlow",
				Vector3(side * 5.35, 5.72, z),
				Vector3(0.55, 0.12, 0.45),
				lamp_material
			)


func _create_distant_skyline(parent: Node3D) -> void:
	var distant_material := _make_material(
		Color(0.24, 0.29, 0.35),
		0.9
	)

	for index in range(12):
		var height := 22.0 + float((index * 11) % 5) * 9.0
		var x := -65.0 + float(index) * 12.0

		_add_box(
			parent,
			"DistantSkylineBuilding",
			Vector3(x, height * 0.5, -105),
			Vector3(9.0, height, 12.0),
			distant_material
		)


func _create_forest(parent: Node3D) -> void:
	var forest := ForestManagerScript.new()
	forest.name = "ModernWorldForest"
	parent.add_child(forest)


func _create_mountains(parent: Node3D) -> void:
	var mountains := MountainManagerScript.new()
	mountains.name = "ModernWorldMountains"
	parent.add_child(mountains)


func _create_waterways(parent: Node3D) -> void:
	var waterways := WaterwaysManagerScript.new()
	waterways.name = "ModernWorldWaterways"
	parent.add_child(waterways)


func _create_marine_environment(parent: Node3D) -> void:
	var marine := MarineEnvironmentManagerScript.new()
	marine.name = "ModernWorldMarineEnvironment"
	parent.add_child(marine)
