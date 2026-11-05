
extends Node3D
class_name WorldManager

signal world_changed(world_id: int)

enum WorldID {
	FANTASY,
	MYTHOLOGY,
	REALISTIC,
	GREED_ISLAND
}

const WORLD_NAMES := {
	WorldID.FANTASY: "Fantasy World",
	WorldID.MYTHOLOGY: "Mythology World",
	WorldID.REALISTIC: "Modern Realistic World",
	WorldID.GREED_ISLAND: "Greed Island World"
}

var active_world: int = WorldID.REALISTIC
var world_roots: Dictionary = {}


func _ready() -> void:
	create_worlds()
	switch_world(WorldID.REALISTIC)


func create_worlds() -> void:
	for world_id in WORLD_NAMES:
		var world_root := Node3D.new()
		world_root.name = WORLD_NAMES[world_id]
		world_root.visible = false
		add_child(world_root)
		world_roots[world_id] = world_root

	_create_modern_city()


func switch_world(world_id: int) -> void:
	if not world_roots.has(world_id):
		push_warning("World ID does not exist.")
		return

	for id in world_roots:
		var world_root: Node3D = world_roots[id]
		world_root.visible = id == world_id
		world_root.process_mode = (
			Node.PROCESS_MODE_INHERIT
			if id == world_id
			else Node.PROCESS_MODE_DISABLED
		)

	active_world = world_id
	world_changed.emit(world_id)


func get_active_world() -> Node3D:
	return world_roots.get(active_world)


func get_world_name(world_id: int) -> String:
	return WORLD_NAMES.get(world_id, "Unknown World")


func get_all_world_ids() -> Array:
	return WORLD_NAMES.keys()


# --------------------------------------------------
# MODERN WORLD - FIRST 3D CITY TEST
# --------------------------------------------------

func _create_modern_city() -> void:
	var root: Node3D = world_roots[WorldID.REALISTIC]

	_create_road(root)
	_create_sidewalks(root)
	_create_city_buildings(root)
	_create_city_trees(root)
	_create_street_lights(root)
	_create_distant_skyline(root)


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
		_add_box(
			parent,
			"CitySidewalk",
			Vector3(side * 7.3, 0.10, -45),
			Vector3(2.6, 0.20, 150),
			sidewalk_material
		)

		_add_box(
			parent,
			"CityCurb",
			Vector3(side * 6.05, 0.16, -45),
			Vector3(0.25, 0.32, 150),
			curb_material
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

			var building := Node3D.new()
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

			_create_building_windows(
				building,
				width,
				height,
				depth
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

			var trunk := MeshInstance3D.new()
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.16
			trunk_mesh.bottom_radius = 0.23
			trunk_mesh.height = 2.5
			trunk.mesh = trunk_mesh
			trunk.position.y = 1.25
			trunk.material_override = trunk_material
			tree.add_child(trunk)

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

			var pole := MeshInstance3D.new()
			var pole_mesh := CylinderMesh.new()
			pole_mesh.top_radius = 0.07
			pole_mesh.bottom_radius = 0.12
			pole_mesh.height = 6.0

			pole.mesh = pole_mesh
			pole.position = Vector3(side * 6.2, 3.0, z)
			pole.material_override = pole_material
			parent.add_child(pole)

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
