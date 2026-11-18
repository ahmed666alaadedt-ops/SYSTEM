extends Node3D
class_name ModernWorldArchipelagoManager

## Adds a second, outer ring of explorable islands around the existing continent.
## These landforms are deliberately separate from the main terrain grid so the
## core continent and its city coordinates remain unchanged.

const ISLANDS := [
	{"name": "Northwatch Isle", "position": Vector2(-1040.0, -1010.0), "scale": Vector3(118.0, 30.0, 82.0), "style": 0},
	{"name": "Whispering Keys", "position": Vector2(-560.0, -1030.0), "scale": Vector3(92.0, 22.0, 66.0), "style": 1},
	{"name": "Stormglass Isle", "position": Vector2(80.0, -1015.0), "scale": Vector3(145.0, 38.0, 88.0), "style": 2},
	{"name": "Eastern Crown", "position": Vector2(900.0, -1000.0), "scale": Vector3(128.0, 34.0, 92.0), "style": 0},
	{"name": "Sunset Atoll", "position": Vector2(1390.0, 420.0), "scale": Vector3(105.0, 18.0, 78.0), "style": 1},
	{"name": "Southern Reach", "position": Vector2(420.0, 1010.0), "scale": Vector3(156.0, 42.0, 104.0), "style": 2},
	{"name": "Farwind Isle", "position": Vector2(-760.0, 1010.0), "scale": Vector3(112.0, 26.0, 84.0), "style": 1},
	{"name": "Bluewater Haven", "position": Vector2(1320.0, -40.0), "scale": Vector3(88.0, 20.0, 66.0), "style": 0}
]

const ROCK_COLORS := [
	Color(0.25, 0.32, 0.31),
	Color(0.34, 0.31, 0.25),
	Color(0.27, 0.30, 0.34)
]
const GRASS_COLORS := [
	Color(0.20, 0.38, 0.22),
	Color(0.36, 0.40, 0.24),
	Color(0.24, 0.36, 0.31)
]

func _ready() -> void:
	name = "ModernWorldOuterArchipelago"
	_build_islands()
	print("SYSTEM WORLD: outer archipelago initialized: ", ISLANDS.size(), " islands")


func _build_islands() -> void:
	for data in ISLANDS:
		var island_root := Node3D.new()
		island_root.name = str(data["name"]).replace(" ", "")
		var center: Vector2 = data["position"]
		var dimensions: Vector3 = data["scale"]
		island_root.position = Vector3(center.x, -2.0, center.y)
		add_child(island_root)

		var style := int(data["style"])
		var rock_material := _make_material(ROCK_COLORS[style], 0.94)
		var grass_material := _make_material(GRASS_COLORS[style], 1.0)
		var sand_material := _make_material(Color(0.70, 0.61, 0.42), 1.0)

		_add_ellipsoid(island_root, "SubmergedRockFoundation",
			Vector3(0.0, -dimensions.y * 0.30, 0.0),
			Vector3(dimensions.x * 1.12, dimensions.y * 0.95, dimensions.z * 1.12),
			rock_material)
		_add_ellipsoid(island_root, "CoastalSandShelf",
			Vector3(0.0, dimensions.y * 0.08, 0.0),
			Vector3(dimensions.x, dimensions.y * 0.68, dimensions.z),
			sand_material)
		_add_ellipsoid(island_root, "GreenIslandCrown",
			Vector3(0.0, dimensions.y * 0.24, 0.0),
			Vector3(dimensions.x * 0.88, dimensions.y * 0.62, dimensions.z * 0.88),
			grass_material)

		var body := StaticBody3D.new()
		body.name = "IslandCollision"
		island_root.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 1.0
		collision.shape = shape
		collision.position.y = dimensions.y * 0.18
		collision.scale = Vector3(dimensions.x * 0.88, dimensions.y * 0.56, dimensions.z * 0.88)
		body.add_child(collision)

		_add_tree_cluster(island_root, dimensions, style)


func _add_ellipsoid(parent: Node3D, node_name: String, local_position: Vector3,
		dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	instance.mesh = sphere
	instance.position = local_position
	instance.scale = dimensions
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)


func _add_tree_cluster(parent: Node3D, dimensions: Vector3, style: int) -> void:
	var trunk_material := _make_material(Color(0.25, 0.16, 0.10), 1.0)
	var leaf_material := _make_material(GRASS_COLORS[(style + 1) % GRASS_COLORS.size()], 1.0)
	var offsets := [
		Vector2(-0.28, -0.12), Vector2(0.22, -0.20),
		Vector2(-0.12, 0.24), Vector2(0.34, 0.18)
	]
	for index in range(offsets.size()):
		var offset: Vector2 = offsets[index]
		var tree := Node3D.new()
		tree.name = "IslandTree_%02d" % index
		tree.position = Vector3(offset.x * dimensions.x, dimensions.y * 0.62,
			offset.y * dimensions.z)
		parent.add_child(tree)

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.18
		trunk_mesh.bottom_radius = 0.28
		trunk_mesh.height = 4.0
		trunk.mesh = trunk_mesh
		trunk.position.y = 2.0
		trunk.material_override = trunk_material
		tree.add_child(trunk)

		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 2.2
		crown_mesh.height = 4.2
		crown.mesh = crown_mesh
		crown.position.y = 5.0
		crown.material_override = leaf_material
		tree.add_child(crown)


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
