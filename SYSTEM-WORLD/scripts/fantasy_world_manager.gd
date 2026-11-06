extends Node3D
class_name FantasyWorldManager

## SYSTEM WORLD — Fantasy World Foundation
## البيئة الخيالية الأساسية: غابات، جبال، أطلال، بلورات، وبوابات سحرية.

const WORLD_CENTER := Vector3.ZERO
const GROUND_SIZE := Vector3(260.0, 2.0, 260.0)

var discovered_regions: Array[String] = []

var region_data := {
	"enchanted_forest": {
		"name": "الغابة المسحورة",
		"description": "غابة قديمة مليئة بالأشجار والكائنات الغامضة."
	},
	"dragon_mountains": {
		"name": "جبال التنانين",
		"description": "سلسلة جبلية مرتفعة تحيط بها أسرار التنانين."
	},
	"ancient_ruins": {
		"name": "الأطلال القديمة",
		"description": "بقايا مملكة سحرية اندثرت منذ عصور."
	},
	"crystal_valley": {
		"name": "وادي البلورات",
		"description": "وادي مليء بالبلورات والطاقة الغامضة."
	}
}


func _ready() -> void:
	name = "FantasyWorldEnvironment"

	_create_ground()
	_create_forest()
	_create_mountains()
	_create_ancient_ruins()
	_create_crystal_valley()
	_create_magic_gate()
	_create_environment_lighting()

	print("SYSTEM WORLD: Fantasy World initialized.")


# --------------------------------------------------
# MATERIALS
# --------------------------------------------------

func _material(
	color: Color,
	roughness: float = 0.85,
	metallic: float = 0.0,
	emission: Color = Color.BLACK
) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()

	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic

	if emission != Color.BLACK:
		result.emission_enabled = true
		result.emission = emission
		result.emission_energy_multiplier = 1.4

	return result


# --------------------------------------------------
# BASIC 3D BUILDING HELPERS
# --------------------------------------------------

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


func _add_sphere(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	scale_value: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 20
	mesh.rings = 12

	instance.mesh = mesh
	instance.position = position
	instance.scale = scale_value
	instance.material_override = material

	parent.add_child(instance)
	return instance


func _add_cylinder(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24

	instance.mesh = mesh
	instance.position = position
	instance.material_override = material

	parent.add_child(instance)
	return instance


# --------------------------------------------------
# GROUND
# --------------------------------------------------

func _create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "FantasyGround"

	var ground_mesh := MeshInstance3D.new()
	ground_mesh.name = "FantasyGroundVisual"

	var mesh := BoxMesh.new()
	mesh.size = GROUND_SIZE

	ground_mesh.mesh = mesh
	ground_mesh.position.y = -1.0
	ground_mesh.material_override = _material(
		Color(0.20, 0.29, 0.18),
		1.0
	)

	ground.add_child(ground_mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = GROUND_SIZE

	collision.shape = shape
	collision.position.y = -1.0

	ground.add_child(collision)
	add_child(ground)


# --------------------------------------------------
# ENCHANTED FOREST
# --------------------------------------------------

func _create_forest() -> void:
	var forest := Node3D.new()
	forest.name = "EnchantedForest"
	forest.position = Vector3(-65.0, 0.0, -30.0)
	add_child(forest)

	var trunk_material := _material(Color(0.20, 0.11, 0.07))
	var leaves_material := _material(
		Color(0.06, 0.28, 0.13),
		0.9,
		0.0,
		Color(0.01, 0.04, 0.01)
	)

	var rng := RandomNumberGenerator.new()
	rng.seed = 73921

	for index in range(55):
		var tree := Node3D.new()
		tree.name = "EnchantedTree_%03d" % index

		tree.position = Vector3(
			rng.randf_range(-35.0, 35.0),
			0.0,
			rng.randf_range(-45.0, 45.0)
		)

		forest.add_child(tree)

		_add_cylinder(
			tree,
			"TreeTrunk",
			Vector3(0.0, 3.0, 0.0),
			0.65,
			6.0,
			trunk_material
		)

		_add_sphere(
			tree,
			"TreeCrown",
			Vector3(0.0, 7.0, 0.0),
			Vector3(3.2, 4.0, 3.2),
			leaves_material
		)

	_add_region_marker(
		forest,
		"enchanted_forest",
		Vector3(0.0, 0.0, 52.0)
	)


# --------------------------------------------------
# DRAGON MOUNTAINS
# --------------------------------------------------

func _create_mountains() -> void:
	var mountains := Node3D.new()
	mountains.name = "DragonMountains"
	mountains.position = Vector3(65.0, 0.0, -45.0)
	add_child(mountains)

	var rock_material := _material(Color(0.29, 0.31, 0.34))
	var snow_material := _material(Color(0.82, 0.87, 0.91))

	var positions := [
		Vector3(-30.0, 10.0, -5.0),
		Vector3(-12.0, 15.0, -12.0),
		Vector3(10.0, 12.0, -8.0),
		Vector3(30.0, 18.0, 0.0),
		Vector3(0.0, 20.0, 22.0)
	]

	for index in range(positions.size()):
		var peak := Node3D.new()
		peak.name = "DragonMountain_%02d" % index
		peak.position = positions[index]
		mountains.add_child(peak)

		var height := 22.0 + float(index % 3) * 8.0

		_add_sphere(
			peak,
			"MountainBase",
			Vector3.ZERO,
			Vector3(13.0, height * 0.65, 12.0),
			rock_material
		)

		_add_cylinder(
			peak,
			"MountainPeak",
			Vector3(0.0, height * 0.55, 0.0),
			5.0,
			height,
			rock_material
		)

		_add_sphere(
			peak,
			"SnowCap",
			Vector3(0.0, height * 1.1, 0.0),
			Vector3(5.0, 3.0, 5.0),
			snow_material
		)

	_add_region_marker(
		mountains,
		"dragon_mountains",
		Vector3(0.0, 0.0, 35.0)
	)


# --------------------------------------------------
# ANCIENT RUINS
# --------------------------------------------------

func _create_ancient_ruins() -> void:
	var ruins := Node3D.new()
	ruins.name = "AncientFantasyRuins"
	ruins.position = Vector3(45.0, 0.0, 65.0)
	add_child(ruins)

	var stone := _material(Color(0.48, 0.43, 0.35))
	var dark_stone := _material(Color(0.25, 0.23, 0.22))

	_add_box(
		ruins,
		"AncientTempleFoundation",
		Vector3(0.0, 0.5, 0.0),
		Vector3(25.0, 1.0, 20.0),
		dark_stone
	)

	for index in range(8):
		var x := -10.0 + float(index) * 3.0

		_add_cylinder(
			ruins,
			"AncientTempleColumn_%02d" % index,
			Vector3(x, 5.0, -7.0),
			0.8,
			10.0,
			stone
		)

	_add_box(
		ruins,
		"AncientTempleRoof",
		Vector3(0.0, 10.5, -7.0),
		Vector3(27.0, 1.5, 4.0),
		stone
	)

	_add_region_marker(
		ruins,
		"ancient_ruins",
		Vector3(0.0, 0.0, 15.0)
	)


# --------------------------------------------------
# CRYSTAL VALLEY
# --------------------------------------------------

func _create_crystal_valley() -> void:
	var valley := Node3D.new()
	valley.name = "CrystalValley"
	valley.position = Vector3(-35.0, 0.0, 75.0)
	add_child(valley)

	var crystal_material := _material(
		Color(0.12, 0.68, 0.91),
		0.2,
		0.35,
		Color(0.04, 0.30, 0.65)
	)

	var rng := RandomNumberGenerator.new()
	rng.seed = 58241

	for index in range(24):
		var crystal := _add_cylinder(
			valley,
			"MagicCrystal_%02d" % index,
			Vector3(
				rng.randf_range(-20.0, 20.0),
				rng.randf_range(2.0, 5.0),
				rng.randf_range(-20.0, 20.0)
			),
			rng.randf_range(0.6, 1.4),
			rng.randf_range(5.0, 12.0),
			crystal_material
		)

		crystal.rotation_degrees = Vector3(
			rng.randf_range(-12.0, 12.0),
			rng.randf_range(0.0, 360.0),
			rng.randf_range(-12.0, 12.0)
		)

	_add_region_marker(
		valley,
		"crystal_valley",
		Vector3(0.0, 0.0, 25.0)
	)


# --------------------------------------------------
# MAGIC GATE
# --------------------------------------------------

func _create_magic_gate() -> void:
	var gate := Node3D.new()
	gate.name = "FantasyMagicGate"
	gate.position = Vector3(0.0, 0.0, -85.0)
	add_child(gate)

	var stone := _material(Color(0.30, 0.31, 0.36))
	var energy := _material(
		Color(0.15, 0.55, 0.95),
		0.2,
		0.3,
		Color(0.05, 0.25, 1.0)
	)

	_add_box(
		gate,
		"GateLeftPillar",
		Vector3(-5.0, 5.0, 0.0),
		Vector3(2.0, 10.0, 2.0),
		stone
	)

	_add_box(
		gate,
		"GateRightPillar",
		Vector3(5.0, 5.0, 0.0),
		Vector3(2.0, 10.0, 2.0),
		stone
	)

	_add_box(
		gate,
		"GateTop",
		Vector3(0.0, 10.0, 0.0),
		Vector3(12.0, 2.0, 2.0),
		stone
	)

	var portal := _add_cylinder(
		gate,
		"MagicPortalCore",
		Vector3(0.0, 5.0, 0.2),
		4.0,
		0.3,
		energy
	)

	portal.rotation_degrees.x = 90.0

	gate.set_meta("system_gate", true)
	gate.set_meta("gate_type", "fantasy")
	gate.set_meta("gate_active", false)


# --------------------------------------------------
# REGION DISCOVERY MARKERS
# --------------------------------------------------

func _add_region_marker(
	parent: Node3D,
	region_id: String,
	local_position: Vector3
) -> void:
	var marker := Area3D.new()
	marker.name = "Discovery_" + region_id
	marker.position = local_position

	marker.set_meta("system_location_id", region_id)
	marker.set_meta("system_region_id", region_id)
	marker.set_meta(
		"system_display_name",
		str(region_data[region_id]["name"])
	)
	marker.set_meta("system_location_type", 7)
	marker.set_meta("system_interaction_prompt", "اكتشاف المنطقة")
	marker.add_to_group("system_interactable")

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 4.0

	collision.shape = shape
	marker.add_child(collision)

	parent.add_child(marker)


func discover_region(region_id: String) -> bool:
	if not region_data.has(region_id):
		return false

	if discovered_regions.has(region_id):
		return false

	discovered_regions.append(region_id)

	print(
		"SYSTEM FANTASY REGION DISCOVERED: ",
		region_data[region_id]["name"]
	)

	return true


func get_region_information(region_id: String) -> Dictionary:
	if not region_data.has(region_id):
		return {}

	return region_data[region_id].duplicate(true)


func get_discovered_regions() -> Array[String]:
	return discovered_regions.duplicate()


func is_region_discovered(region_id: String) -> bool:
	return discovered_regions.has(region_id)


# --------------------------------------------------
# ENVIRONMENT LIGHTING
# --------------------------------------------------

func _create_environment_lighting() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "FantasyWorldEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()

	sky_material.sky_top_color = Color(0.035, 0.055, 0.14)
	sky_material.sky_horizon_color = Color(0.22, 0.29, 0.46)
	sky_material.ground_bottom_color = Color(0.06, 0.08, 0.12)
	sky_material.ground_horizon_color = Color(0.18, 0.22, 0.28)

	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.55, 0.78)
	environment.ambient_light_energy = 0.8

	environment.fog_enabled = true
	environment.fog_light_color = Color(0.24, 0.31, 0.48)
	environment.fog_density = 0.0012

	environment_node.environment = environment
	add_child(environment_node)

	var moon_light := DirectionalLight3D.new()
	moon_light.name = "FantasyMoonLight"
	moon_light.rotation_degrees = Vector3(-45.0, -25.0, 0.0)
	moon_light.light_color = Color(0.55, 0.65, 1.0)
	moon_light.light_energy = 0.65
	moon_light.shadow_enabled = true

	add_child(moon_light)
