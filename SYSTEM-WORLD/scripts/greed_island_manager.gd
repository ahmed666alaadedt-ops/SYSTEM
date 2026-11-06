
extends Node3D
class_name GreedIslandManager

## جزيرة الطمع — مملكة اختبار خاصة بمدير اللعبة.
## القتال معطل بالكامل. الكائنات الموجودة للعرض والاستكشاف فقط.

const ISLAND_CENTER := Vector3(0.0, -3.0, -45.0)
const ISLAND_SIZE := Vector3(118.0, 6.0, 145.0)
const OCEAN_SIZE := Vector2(520.0, 520.0)

var admin_test_mode := true
var combat_enabled := false
var ocean_material: ShaderMaterial
var cloud_nodes: Array[Node3D] = []
var animated_time := 0.0


func _ready() -> void:
	name = "GreedIslandManager"

	_build_ocean()
	_build_island()
	_build_coastline()
	_build_forests()
	_build_landmarks()
	_build_showcase_creatures()
	_build_clouds()

	# توسعة المملكة الأسطورية
	_build_mountain_ranges()
	_build_rivers_and_lakes()
	_build_floating_islands()
	_build_royal_palace()
	_build_babylon_tower()
	_build_greek_test_arena()
	_build_crystal_caverns()
	_build_royal_guard()
	_build_royal_servants()
	_build_mythical_sky_beasts()

	_register_island_features()


func _process(delta: float) -> void:
	animated_time += delta
	_animate_clouds(delta)
	_animate_floating_islands(delta)


func is_combat_allowed() -> bool:
	return false


func is_admin_test_environment() -> bool:
	return admin_test_mode


# --------------------------------------------------
# MATERIALS AND BUILDING HELPERS
# --------------------------------------------------

func _material(
	color: Color,
	roughness: float = 0.85,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


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


func _add_discovery(
	parent: Node3D,
	node_name: String,
	display_name: String,
	location_id: String,
	region_id: String,
	position: Vector3,
	radius: float = 5.0
) -> void:
	_add_interaction_point(
		parent,
		node_name,
		display_name,
		location_id,
		region_id,
		position,
		radius
	)


# --------------------------------------------------
# ANIMATED OCEAN
# --------------------------------------------------

func _build_ocean() -> void:
	var ocean := MeshInstance3D.new()
	ocean.name = "GreedIslandAnimatedOcean"

	var mesh := PlaneMesh.new()
	mesh.size = OCEAN_SIZE
	mesh.subdivide_width = 64
	mesh.subdivide_depth = 64

	ocean.mesh = mesh
	ocean.position = Vector3(0.0, -1.15, -45.0)

	ocean_material = ShaderMaterial.new()
	var shader := Shader.new()

	shader.code = """
shader_type spatial;
render_mode cull_disabled;

uniform vec4 deep_color : source_color =
	vec4(0.005, 0.10, 0.20, 1.0);

uniform vec4 shallow_color : source_color =
	vec4(0.015, 0.38, 0.43, 1.0);

uniform float wave_height = 0.22;
uniform float wave_speed = 0.8;

void vertex() {
	vec3 p = VERTEX;

	float wave_a = sin(p.x * 0.075 + TIME * wave_speed);
	float wave_b = cos(p.z * 0.065 + TIME * wave_speed * 0.75);
	float wave_c = sin((p.x + p.z) * 0.035 + TIME * 0.45);

	p.y += (wave_a + wave_b + wave_c) * wave_height;
	VERTEX = p;
}

void fragment() {
	float pattern_a = sin(UV.x * 35.0 + TIME * 0.35);
	float pattern_b = cos(UV.y * 28.0 - TIME * 0.25);

	float blend_value = clamp(
		0.48 + (pattern_a + pattern_b) * 0.08,
		0.0,
		1.0
	);

	ALBEDO = mix(
		deep_color.rgb,
		shallow_color.rgb,
		blend_value
	);

	METALLIC = 0.18;
	ROUGHNESS = 0.22;
	SPECULAR = 0.75;
}
"""

	ocean_material.shader = shader
	ocean.material_override = ocean_material
	add_child(ocean)


# --------------------------------------------------
# MAIN ISLAND
# --------------------------------------------------

func _build_island() -> void:
	var island := StaticBody3D.new()
	island.name = "GreedIslandLand"
	island.position = ISLAND_CENTER
	add_child(island)

	var ground := MeshInstance3D.new()
	ground.name = "IslandGround"

	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 48

	ground.mesh = mesh
	ground.scale = Vector3(
		ISLAND_SIZE.x * 0.5,
		ISLAND_SIZE.y,
		ISLAND_SIZE.z * 0.5
	)

	ground.material_override = _material(
		Color(0.25, 0.43, 0.20),
		1.0
	)
	island.add_child(ground)

	var collision := CollisionShape3D.new()
	collision.name = "IslandWalkableCollision"

	var shape := BoxShape3D.new()
	shape.size = Vector3(
		ISLAND_SIZE.x * 0.82,
		ISLAND_SIZE.y,
		ISLAND_SIZE.z * 0.82
	)

	collision.shape = shape
	collision.position.y = -ISLAND_SIZE.y * 0.5
	island.add_child(collision)

	_build_island_hills(island)


func _build_island_hills(parent: Node3D) -> void:
	var hill_material := _material(Color(0.20, 0.37, 0.17), 1.0)

	_add_sphere(parent, "NorthGreenHill",
		Vector3(-28.0, 4.0, -42.0),
		Vector3(23.0, 9.0, 19.0), hill_material)

	_add_sphere(parent, "EastGreenHill",
		Vector3(34.0, 3.0, -15.0),
		Vector3(20.0, 7.0, 24.0), hill_material)

	_add_sphere(parent, "SouthHill",
		Vector3(8.0, 3.0, 43.0),
		Vector3(28.0, 8.0, 19.0), hill_material)


# --------------------------------------------------
# COASTLINE
# --------------------------------------------------

func _build_coastline() -> void:
	var rock_material := _material(Color(0.27, 0.29, 0.28), 1.0)
	var sand_material := _material(Color(0.78, 0.66, 0.44), 1.0)

	_add_box(self, "MainBeach",
		Vector3(0.0, 0.02, 16.0),
		Vector3(75.0, 0.12, 16.0), sand_material)

	var rng := RandomNumberGenerator.new()
	rng.seed = 74021

	for index in range(44):
		var angle := TAU * float(index) / 44.0
		var radius_x := rng.randf_range(55.0, 69.0)
		var radius_z := rng.randf_range(68.0, 84.0)

		var rock := _add_sphere(
			self,
			"CoastRock_%02d" % index,
			Vector3(
				cos(angle) * radius_x,
				rng.randf_range(-0.2, 0.8),
				-45.0 + sin(angle) * radius_z
			),
			Vector3(
				rng.randf_range(1.5, 4.0),
				rng.randf_range(1.0, 2.8),
				rng.randf_range(1.5, 4.0)
			),
			rock_material
		)
		rock.cast_shadow = false


# --------------------------------------------------
# FORESTS
# --------------------------------------------------

func _build_forests() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91827

	var trunk_material := _material(Color(0.25, 0.13, 0.07))
	var leaves_material := _material(Color(0.08, 0.28, 0.12))

	for index in range(42):
		var x := rng.randf_range(-48.0, 48.0)
		var z := rng.randf_range(-108.0, 12.0)

		if absf(x) < 10.0 and z > -75.0 and z < -15.0:
			continue

		var tree := Node3D.new()
		tree.name = "IslandTree_%02d" % index
		tree.position = Vector3(x, 0.0, z)
		add_child(tree)

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.16
		trunk_mesh.bottom_radius = 0.27
		trunk_mesh.height = 3.6
		trunk.mesh = trunk_mesh
		trunk.position.y = 1.8
		trunk.material_override = trunk_material
		tree.add_child(trunk)

		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 1.5
		crown_mesh.height = 2.7
		crown.mesh = crown_mesh
		crown.position.y = 4.0
		crown.scale = Vector3(1.1, 1.0, 1.1)
		crown.material_override = leaves_material
		tree.add_child(crown)


# --------------------------------------------------
# ORIGINAL LANDMARKS
# --------------------------------------------------

func _build_landmarks() -> void:
	_build_ruins()
	_build_secret_cave()
	_build_waterfall()
	_build_treasure_chest()


func _build_ruins() -> void:
	var ruins := Node3D.new()
	ruins.name = "AncientIslandRuins"
	ruins.position = Vector3(-28.0, 0.0, -82.0)
	add_child(ruins)

	var stone := _material(Color(0.48, 0.44, 0.35), 0.95)

	for index in range(5):
		var x := float(index) * 3.2 - 6.4
		_add_box(ruins, "AncientPillar_%02d" % index,
			Vector3(x, 2.5, 0.0),
			Vector3(1.0, 5.0, 1.0), stone)

	_add_box(ruins, "AncientStoneArch",
		Vector3(0.0, 5.1, 0.0),
		Vector3(15.0, 0.8, 1.4), stone)

	_add_discovery(ruins, "AncientRuinsDiscovery",
		"الأطلال القديمة", "greed_ruins", "north_ruins",
		Vector3(0.0, 1.0, 4.0), 4.0)


func _build_secret_cave() -> void:
	var cave := Node3D.new()
	cave.name = "SecretCave"
	cave.position = Vector3(38.0, 0.0, -88.0)
	add_child(cave)

	var dark_stone := _material(Color(0.12, 0.15, 0.16), 1.0)

	_add_sphere(cave, "CaveRockLeft",
		Vector3(-4.0, 2.0, 0.0),
		Vector3(3.0, 4.0, 4.0), dark_stone)

	_add_sphere(cave, "CaveRockRight",
		Vector3(4.0, 2.0, 0.0),
		Vector3(3.0, 4.0, 4.0), dark_stone)

	_add_sphere(cave, "CaveRoof",
		Vector3(0.0, 5.0, 0.0),
		Vector3(5.0, 2.0, 4.5), dark_stone)

	_add_discovery(cave, "SecretCaveDiscovery",
		"الكهف السري", "greed_cave", "hidden_cave",
		Vector3(0.0, 1.0, 5.0), 5.0)


func _build_waterfall() -> void:
	var waterfall := Node3D.new()
	waterfall.name = "IslandWaterfall"
	waterfall.position = Vector3(-43.0, 0.0, -35.0)
	add_child(waterfall)

	var water_material := _material(Color(0.15, 0.65, 0.78), 0.2)
	water_material.emission_enabled = true
	water_material.emission = Color(0.03, 0.18, 0.22)
	water_material.emission_energy_multiplier = 0.4

	var water := _add_box(waterfall, "WaterfallStream",
		Vector3(0.0, 3.0, 0.0),
		Vector3(3.0, 7.0, 0.5), water_material)
	water.cast_shadow = false

	_add_sphere(waterfall, "WaterfallPool",
		Vector3(0.0, 0.0, 4.0),
		Vector3(6.0, 0.4, 5.0), water_material)

	_add_discovery(waterfall, "WaterfallDiscovery",
		"الشلال", "greed_waterfall", "waterfall_region",
		Vector3(0.0, 1.0, 6.0), 4.0)


func _build_treasure_chest() -> void:
	var chest := Node3D.new()
	chest.name = "GoldenTreasureChest"
	chest.position = Vector3(12.0, 0.0, -70.0)
	add_child(chest)

	var gold := _material(Color(0.83, 0.55, 0.12), 0.3, 0.65)
	var wood := _material(Color(0.24, 0.12, 0.055), 0.8)

	_add_box(chest, "ChestWoodenBody",
		Vector3(0.0, 0.8, 0.0),
		Vector3(2.2, 1.5, 1.5), wood)

	_add_box(chest, "ChestGoldenBand",
		Vector3(0.0, 0.8, -0.78),
		Vector3(2.3, 0.18, 0.12), gold)

	_add_box(chest, "ChestGoldenLock",
		Vector3(0.0, 0.85, -0.88),
		Vector3(0.35, 0.45, 0.16), gold)

	_add_discovery(chest, "TreasureChestDiscovery",
		"صندوق الكنز", "greed_treasure", "treasure_beach",
		Vector3(0.0, 1.0, 2.0), 3.5)


# --------------------------------------------------
# MOUNTAINS AND HIGH PEAKS
# --------------------------------------------------

func _build_mountain_ranges() -> void:
	var mountain_material := _material(Color(0.27, 0.30, 0.32), 0.95)
	var snow_material := _material(Color(0.82, 0.88, 0.92), 0.8)
	var peak_positions := [
		Vector3(-43.0, 8.0, -105.0),
		Vector3(-18.0, 12.0, -112.0),
		Vector3(15.0, 10.0, -112.0),
		Vector3(43.0, 8.0, -94.0),
		Vector3(48.0, 7.0, -55.0)
	]

	for index in range(peak_positions.size()):
		var peak := Node3D.new()
		peak.name = "RoyalMountain_%02d" % index
		peak.position = peak_positions[index]
		add_child(peak)

		var height := 18.0 + float(index % 3) * 5.0

		_add_sphere(peak, "MountainBase",
			Vector3(0.0, 0.0, 0.0),
			Vector3(13.0, height * 0.55, 12.0),
			mountain_material)

		_add_cylinder(peak, "MountainPeak",
			Vector3(0.0, height * 0.65, 0.0),
			5.0, height, mountain_material)

		_add_sphere(peak, "SnowCrown",
			Vector3(0.0, height * 1.05, 0.0),
			Vector3(5.2, 3.0, 5.2), snow_material)

		peak.set_meta("system_display_only", true)
		peak.set_meta("combat_enabled", false)

	_add_discovery(self, "MountainRangeDiscovery",
		"جبال المملكة العالية", "greed_mountains",
		"high_mountain_region",
		Vector3(-38.0, 2.0, -105.0), 8.0)


# --------------------------------------------------
# RIVERS AND LAKES
# --------------------------------------------------

func _build_rivers_and_lakes() -> void:
	var river_material := _material(Color(0.08, 0.48, 0.67), 0.18, 0.12)
	river_material.emission_enabled = true
	river_material.emission = Color(0.02, 0.12, 0.18)
	river_material.emission_energy_multiplier = 0.25

	_add_box(self, "RoyalRiverNorth",
		Vector3(-18.0, 0.18, -67.0),
		Vector3(5.0, 0.16, 47.0), river_material)

	_add_box(self, "RoyalRiverEast",
		Vector3(4.0, 0.18, -45.0),
		Vector3(42.0, 0.16, 4.0), river_material)

	_add_box(self, "RoyalRiverSouth",
		Vector3(25.0, 0.18, -20.0),
		Vector3(4.0, 0.16, 45.0), river_material)

	_add_sphere(self, "RoyalLake",
		Vector3(-18.0, 0.12, -43.0),
		Vector3(12.0, 0.18, 10.0), river_material)

	_add_sphere(self, "CrystalLake",
		Vector3(35.0, 0.12, -80.0),
		Vector3(9.0, 0.16, 7.0), river_material)

	_add_discovery(self, "RoyalLakeDiscovery",
		"بحيرة المملكة", "greed_royal_lake",
		"riverlands_region",
		Vector3(-18.0, 1.0, -43.0), 7.0)


# --------------------------------------------------
# FLOATING ISLANDS
# --------------------------------------------------

func _build_floating_islands() -> void:
	var stone := _material(Color(0.28, 0.31, 0.34), 0.9)
	var grass := _material(Color(0.16, 0.38, 0.20), 0.95)
	var gold := _material(Color(0.72, 0.52, 0.18), 0.35, 0.65)

	var island_positions := [
		Vector3(-55.0, 29.0, -70.0),
		Vector3(48.0, 34.0, -88.0),
		Vector3(0.0, 42.0, -112.0),
		Vector3(65.0, 25.0, -25.0)
	]

	for index in range(island_positions.size()):
		var floating := Node3D.new()
		floating.name = "FloatingIsland_%02d" % index
		floating.position = island_positions[index]
		floating.set_meta("base_y", floating.position.y)
		add_child(floating)

		_add_sphere(floating, "FloatingIslandTop",
			Vector3.ZERO,
			Vector3(13.0, 2.0, 11.0), grass)

		_add_sphere(floating, "FloatingIslandRock",
			Vector3(0.0, -4.0, 0.0),
			Vector3(9.0, 5.0, 8.0), stone)

		_add_cylinder(floating, "FloatingIslandAncientColumn",
			Vector3(0.0, 2.5, 0.0),
			1.0, 5.0, gold)

		if index == 0 or index == 2:
			_add_box(floating, "FloatingIslandSmallPalace",
				Vector3(0.0, 5.0, 0.0),
				Vector3(8.0, 4.0, 7.0), gold)

		floating.set_meta("system_display_only", true)
		floating.set_meta("combat_enabled", false)
		floating.add_to_group("greed_floating_islands")


func _animate_floating_islands(delta: float) -> void:
	var islands := get_tree().get_nodes_in_group(
		"greed_floating_islands"
	)

	for island in islands:
		if not is_instance_valid(island):
			continue

		var base_y := float(island.get_meta("base_y", island.position.y))
		var phase := float(island.get_instance_id() % 100) * 0.05
		island.position.y = base_y + sin(animated_time * 0.45 + phase) * 0.65


# --------------------------------------------------
# ROYAL PALACE
# --------------------------------------------------

func _build_royal_palace() -> void:
	var palace := Node3D.new()
	palace.name = "RoyalPalace"
	palace.position = Vector3(0.0, 0.0, -88.0)
	add_child(palace)

	var marble := _material(Color(0.78, 0.75, 0.66), 0.55)
	var gold := _material(Color(0.82, 0.59, 0.20), 0.28, 0.7)
	var royal_blue := _material(Color(0.08, 0.17, 0.32), 0.45)

	_add_box(palace, "PalaceMainHall",
		Vector3(0.0, 7.0, 0.0),
		Vector3(34.0, 14.0, 23.0), marble)

	_add_box(palace, "PalaceRoyalRoof",
		Vector3(0.0, 14.5, 0.0),
		Vector3(38.0, 1.5, 27.0), gold)

	_add_box(palace, "PalaceRoyalDoor",
		Vector3(0.0, 4.0, -11.7),
		Vector3(5.0, 8.0, 0.5), royal_blue)

	for side in [-1.0, 1.0]:
		for index in range(4):
			var x := side * 15.0
			var z := float(index) * 5.5 - 8.0

			_add_cylinder(palace, "PalaceColumn",
				Vector3(x, 5.5, z),
				1.0, 11.0, gold)

		_add_cylinder(palace, "PalaceRoyalTower",
			Vector3(side * 20.0, 9.0, 0.0),
			3.0, 18.0, marble)

		_add_sphere(palace, "PalaceTowerCrown",
			Vector3(side * 20.0, 19.0, 0.0),
			Vector3(3.5, 2.0, 3.5), gold)

	_add_box(palace, "RoyalThronePlatform",
		Vector3(0.0, 0.6, 18.0),
		Vector3(18.0, 1.2, 10.0), gold)

	_add_discovery(palace, "RoyalPalaceDiscovery",
		"القصر الملكي", "greed_royal_palace",
		"royal_capital_region",
		Vector3(0.0, 1.0, 24.0), 9.0)

	palace.set_meta("system_display_only", true)
	palace.set_meta("combat_enabled", false)


# --------------------------------------------------
# BABYLON TOWER
# --------------------------------------------------

func _build_babylon_tower() -> void:
	var tower := Node3D.new()
	tower.name = "TowerOfBabylon"
	tower.position = Vector3(-42.0, 0.0, -45.0)
	add_child(tower)

	var stone := _material(Color(0.56, 0.36, 0.22), 0.85)
	var gold := _material(Color(0.85, 0.61, 0.22), 0.35, 0.6)

	var widths := [19.0, 16.0, 13.0, 10.0, 7.0, 4.5]
	var heights := [4.0, 4.0, 4.0, 4.0, 4.0, 4.0]
	var current_y := 2.0

	for index in range(widths.size()):
		var width := widths[index]

		_add_box(tower, "BabylonTerrace_%02d" % index,
			Vector3(0.0, current_y, 0.0),
			Vector3(width, heights[index], width),
			stone if index % 2 == 0 else gold)

		current_y += heights[index]

	_add_cylinder(tower, "BabylonSummit",
		Vector3(0.0, current_y + 2.0, 0.0),
		3.0, 5.0, gold)

	_add_sphere(tower, "BabylonSummitLight",
		Vector3(0.0, current_y + 5.0, 0.0),
		Vector3(2.0, 2.0, 2.0), gold)

	_add_discovery(tower, "BabylonTowerDiscovery",
		"برج بابل العظيم", "greed_babylon_tower",
		"ancient_wonders_region",
		Vector3(0.0, 1.0, 13.0), 8.0)

	tower.set_meta("system_display_only", true)
	tower.set_meta("combat_enabled", false)


# --------------------------------------------------
# GREEK TEST ARENA
# --------------------------------------------------

func _build_greek_test_arena() -> void:
	var arena := Node3D.new()
	arena.name = "GrandGreekTestArena"
	arena.position = Vector3(40.0, 0.0, -42.0)
	add_child(arena)

	var marble := _material(Color(0.77, 0.72, 0.60), 0.8)
	var floor_material := _material(Color(0.45, 0.39, 0.30), 0.95)
	var gold := _material(Color(0.83, 0.62, 0.25), 0.35, 0.5)

	_add_cylinder(arena, "ArenaMainFloor",
		Vector3(0.0, 0.0, 0.0),
		22.0, 1.0, floor_material)

	_add_cylinder(arena, "ArenaOuterPlatform",
		Vector3(0.0, 1.0, 0.0),
		25.0, 1.0, marble)

	for index in range(20):
		var angle := TAU * float(index) / 20.0
		var x := cos(angle) * 21.0
		var z := sin(angle) * 21.0

		_add_cylinder(arena, "ArenaGreekColumn_%02d" % index,
			Vector3(x, 5.0, z),
			1.0, 8.0, marble)

	_add_cylinder(arena, "ArenaCentralMarker",
		Vector3(0.0, 1.0, 0.0),
		3.0, 1.0, gold)

	_add_discovery(arena, "GrandArenaDiscovery",
		"ساحة الاختبارات الكبرى", "greed_test_arena",
		"royal_trials_region",
		Vector3(0.0, 1.0, 27.0), 10.0)

	arena.set_meta("system_display_only", true)
	arena.set_meta("combat_enabled", false)
	arena.set_meta("admin_test_arena", true)


# --------------------------------------------------
# CRYSTAL CAVERNS
# --------------------------------------------------

func _build_crystal_caverns() -> void:
	var cavern := Node3D.new()
	cavern.name = "CrystalCavernShowcase"
	cavern.position = Vector3(-42.0, -1.0, -100.0)
	add_child(cavern)

	var rock := _material(Color(0.15, 0.18, 0.22), 0.95)
	var crystal := _material(Color(0.12, 0.75, 0.88), 0.2, 0.4)
	crystal.emission_enabled = true
	crystal.emission = Color(0.04, 0.38, 0.55)
	crystal.emission_energy_multiplier = 1.2

	_add_sphere(cavern, "CavernMainRock",
		Vector3(0.0, 2.0, 0.0),
		Vector3(13.0, 5.0, 11.0), rock)

	for index in range(9):
		var angle := TAU * float(index) / 9.0
		var position := Vector3(
			cos(angle) * 7.0,
			1.0 + float(index % 3),
			sin(angle) * 6.0
		)

		var shard := _add_cylinder(
			cavern,
			"CrystalShard_%02d" % index,
			position,
			0.8,
			5.0 + float(index % 4) * 1.5,
			crystal
		)

		shard.rotation.z = deg_to_rad(12.0 * float(index % 3))

	_add_discovery(cavern, "CrystalCavernDiscovery",
		"مغارة الكريستال", "greed_crystal_cavern",
		"underground_wonders_region",
		Vector3(0.0, 1.0, 12.0), 8.0)


# --------------------------------------------------
# ROYAL GUARD — DISPLAY ONLY
# --------------------------------------------------

func _build_royal_guard() -> void:
	var guard_group := Node3D.new()
	guard_group.name = "RoyalIslandGuard"
	guard_group.position = Vector3(0.0, 0.0, -65.0)
	add_child(guard_group)

	var armor := _material(Color(0.17, 0.22, 0.31), 0.35, 0.55)
	var gold := _material(Color(0.82, 0.60, 0.22), 0.3, 0.7)

	for index in range(8):
		var side := -1.0 if index % 2 == 0 else 1.0
		var row := float(index / 2)

		var guard := Node3D.new()
		guard.name = "RoyalGuard_%02d" % index
		guard.position = Vector3(
			side * (8.0 + row * 3.0),
			0.0,
			row * 5.0
		)
		guard_group.add_child(guard)

		_add_sphere(guard, "GuardBody",
			Vector3(0.0, 1.7, 0.0),
			Vector3(0.65, 1.0, 0.4), armor)

		_add_sphere(guard, "GuardHelmet",
			Vector3(0.0, 3.0, 0.0),
			Vector3(0.55, 0.55, 0.55), gold)

		_add_box(guard, "GuardShield",
			Vector3(side * 0.8, 1.8, -0.2),
			Vector3(0.25, 1.8, 1.1), gold)

		guard.set_meta("system_display_only", true)
		guard.set_meta("combat_enabled", false)
		guard.set_meta("royal_guard", true)

	guard_group.set_meta("system_display_only", true)
	guard_group.set_meta("combat_enabled", false)


# --------------------------------------------------
# ROYAL SERVANTS — PALACE DISPLAY
# --------------------------------------------------

func _build_royal_servants() -> void:
	var servants := Node3D.new()
	servants.name = "RoyalPalaceServants"
	servants.position = Vector3(0.0, 0.0, -72.0)
	add_child(servants)

	var clothing := _material(Color(0.48, 0.12, 0.24), 0.65)
	var skin := _material(Color(0.78, 0.58, 0.43), 0.8)
	var gold := _material(Color(0.85, 0.67, 0.30), 0.35, 0.5)

	for index in range(4):
		var servant := Node3D.new()
		servant.name = "RoyalServant_%02d" % index
		servant.position = Vector3(
			float(index) * 5.0 - 7.5,
			0.0,
			-8.0
		)
		servants.add_child(servant)

		_add_sphere(servant, "ServantDress",
			Vector3(0.0, 1.0, 0.0),
			Vector3(0.65, 1.0, 0.45), clothing)

		_add_sphere(servant, "ServantHead",
			Vector3(0.0, 2.2, 0.0),
			Vector3(0.4, 0.48, 0.4), skin)

		_add_sphere(servant, "ServantHair",
			Vector3(0.0, 2.55, 0.0),
			Vector3(0.43, 0.25, 0.43), gold)

		servant.set_meta("system_display_only", true)
		servant.set_meta("combat_enabled", false)
		servant.set_meta("royal_servant", true)

	servants.set_meta("system_display_only", true)
	servants.set_meta("combat_enabled", false)


# --------------------------------------------------
# MYTHICAL SKY BEASTS — DISPLAY ONLY
# --------------------------------------------------

func _build_mythical_sky_beasts() -> void:
	var beast_material := _material(Color(0.20, 0.25, 0.42), 0.4, 0.25)
	var wing_material := _material(Color(0.12, 0.17, 0.28), 0.5)

	for index in range(3):
		var beast := Node3D.new()
		beast.name = "RoyalSkyBeast_%02d" % index
		beast.position = Vector3(
			float(index) * 25.0 - 25.0,
			24.0 + float(index % 2) * 5.0,
			-50.0 - float(index) * 12.0
		)
		add_child(beast)

		_add_sphere(beast, "SkyBeastBody",
			Vector3.ZERO,
			Vector3(2.0, 1.2, 3.5), beast_material)

		_add_sphere(beast, "SkyBeastHead",
			Vector3(0.0, 0.4, -3.4),
			Vector3(1.0, 0.8, 1.2), beast_material)

		for side in [-1.0, 1.0]:
			var wing := _add_box(beast, "SkyBeastWing",
				Vector3(side * 3.2, 0.7, 0.0),
				Vector3(4.5, 0.15, 2.4), wing_material)
			wing.rotation.z = side * deg_to_rad(-15.0)

		beast.set_meta("system_display_only", true)
		beast.set_meta("combat_enabled", false)
		beast.set_meta("royal_beast", true)


# --------------------------------------------------
# ORIGINAL SHOWCASE DRAGON
# --------------------------------------------------

func _build_showcase_creatures() -> void:
	_build_showcase_dragon()


func _build_showcase_dragon() -> void:
	var dragon := Node3D.new()
	dragon.name = "DisplayDragon_NoCombat"
	dragon.position = Vector3(26.0, 0.0, -25.0)
	add_child(dragon)

	var dragon_material := _material(Color(0.12, 0.23, 0.30), 0.45, 0.25)
	var wing_material := _material(Color(0.08, 0.14, 0.20), 0.55)

	_add_sphere(dragon, "DragonBody",
		Vector3(0.0, 2.5, 0.0),
		Vector3(2.5, 1.4, 4.0), dragon_material)

	_add_sphere(dragon, "DragonHead",
		Vector3(0.0, 3.2, -4.0),
		Vector3(1.3, 1.1, 1.7), dragon_material)

	for side in [-1.0, 1.0]:
		var wing := _add_box(dragon, "DragonWing",
			Vector3(side * 4.0, 3.2, 0.0),
			Vector3(5.0, 0.18, 3.0), wing_material)
		wing.rotation.z = side * deg_to_rad(-18.0)

		_add_sphere(dragon, "DragonHorn",
			Vector3(side * 0.8, 4.2, -4.8),
			Vector3(0.25, 0.75, 0.25), dragon_material)

	dragon.set_meta("system_display_only", true)
	dragon.set_meta("combat_enabled", false)
	dragon.set_meta("royal_beast", true)


# --------------------------------------------------
# CLOUDS
# --------------------------------------------------

func _build_clouds() -> void:
	var cloud_material := _material(Color(0.82, 0.88, 0.94, 0.72), 1.0)

	for index in range(7):
		var cloud := Node3D.new()
		cloud.name = "IslandCloud_%02d" % index
		cloud.position = Vector3(
			float(index) * 32.0 - 95.0,
			35.0 + float(index % 3) * 4.0,
			-100.0 + float(index % 4) * 38.0
		)
		add_child(cloud)

		for part in range(4):
			_add_sphere(cloud, "CloudPart_%02d" % part,
				Vector3(float(part) * 2.3, float(part % 2) * 0.8, 0.0),
				Vector3(3.0, 1.3, 2.0), cloud_material)

		cloud_nodes.append(cloud)


func _animate_clouds(delta: float) -> void:
	for index in range(cloud_nodes.size()):
		var cloud := cloud_nodes[index]
		if not is_instance_valid(cloud):
			continue

		cloud.position.x += delta * (0.8 + float(index % 3) * 0.18)

		if cloud.position.x > 125.0:
			cloud.position.x = -125.0


# --------------------------------------------------
# MAP DISCOVERY
# --------------------------------------------------

func _add_interaction_point(
	parent: Node3D,
	node_name: String,
	display_name: String,
	location_id: String,
	region_id: String,
	local_position: Vector3,
	radius: float
) -> void:
	var area := Area3D.new()
	area.name = node_name
	area.position = local_position
	area.add_to_group("system_interactable")

	area.set_meta("system_location_id", location_id)
	area.set_meta("system_region_id", region_id)
	area.set_meta("system_display_name", display_name)
	area.set_meta("system_location_type", 5)
	area.set_meta("system_interaction_prompt", "اكتشاف " + display_name)
	area.set_meta("system_display_only", true)
	area.set_meta("combat_enabled", false)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	collision.shape = shape

	area.add_child(collision)
	parent.add_child(area)


func _register_island_features() -> void:
	print("GREED ISLAND: private royal kingdom ready.")
	print("GREED ISLAND: admin exploration mode enabled.")
	print("GREED ISLAND: combat disabled.")
