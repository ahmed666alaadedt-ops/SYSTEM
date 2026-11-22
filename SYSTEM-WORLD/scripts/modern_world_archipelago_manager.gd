extends Node3D
class_name ModernWorldArchipelagoManager

## Adds a second, outer ring of explorable islands around the existing continent.
## These landforms are deliberately separate from the main terrain grid so the
## core continent and its city coordinates remain unchanged.

const ISLANDS := [
	{"name": "Northwatch Isle", "position": Vector2(-1040.0, -1010.0), "scale": Vector3(118.0, 30.0, 82.0), "style": 0, "biome": "alpine"},
	{"name": "Whispering Keys", "position": Vector2(-560.0, -1030.0), "scale": Vector3(92.0, 22.0, 66.0), "style": 1, "biome": "tropical"},
	{"name": "Stormglass Isle", "position": Vector2(80.0, -1015.0), "scale": Vector3(145.0, 38.0, 88.0), "style": 2, "biome": "volcanic"},
	{"name": "Eastern Crown", "position": Vector2(900.0, -1000.0), "scale": Vector3(128.0, 34.0, 92.0), "style": 0, "biome": "temperate"},
	{"name": "Sunset Atoll", "position": Vector2(1390.0, 420.0), "scale": Vector3(105.0, 18.0, 78.0), "style": 1, "biome": "atoll"},
	{"name": "Southern Reach", "position": Vector2(420.0, 1010.0), "scale": Vector3(156.0, 42.0, 104.0), "style": 2, "biome": "highland"},
	{"name": "Farwind Isle", "position": Vector2(-760.0, 1010.0), "scale": Vector3(112.0, 26.0, 84.0), "style": 1, "biome": "desert"},
	{"name": "Bluewater Haven", "position": Vector2(1320.0, -40.0), "scale": Vector3(88.0, 20.0, 66.0), "style": 0, "biome": "rocky"}
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
	_build_navigation_buoys()
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
		_build_shoreline_details(island_root, dimensions, style)
		_build_island_biome_feature(
			island_root,
			dimensions,
			str(data.get("biome", "temperate"))
		)
		_build_island_harbor(island_root, dimensions, style, str(data["name"]))
		island_root.set_meta("system_island_biome", str(data.get("biome", "temperate")))


## Adds one readable landmark formation per island biome without changing
## the island footprint, harbor coordinates or existing collision surface.
func _build_island_biome_feature(
	parent: Node3D,
	dimensions: Vector3,
	biome: String
) -> void:
	var base_y := dimensions.y * 0.82
	var dark_rock := _make_material(Color(0.16, 0.19, 0.21), 0.96)
	var pale_rock := _make_material(Color(0.52, 0.54, 0.52), 0.98)
	var snow := _make_material(Color(0.88, 0.93, 0.97), 0.92)
	var sand := _make_material(Color(0.76, 0.65, 0.43), 1.0)
	var water := _make_material(Color(0.025, 0.40, 0.52), 0.18)
	var lava := _make_material(Color(1.0, 0.22, 0.035), 0.28)
	lava.emission_enabled = true
	lava.emission = Color(1.0, 0.12, 0.015)
	lava.emission_energy_multiplier = 2.0

	match biome:
		"alpine":
			_add_island_cone(parent, "SnowPeak_Main", Vector3(0.0, base_y + 15.0, 0.0), 34.0, 30.0, pale_rock)
			_add_island_cone(parent, "SnowCap_Main", Vector3(0.0, base_y + 27.0, 0.0), 15.0, 8.0, snow)
			_add_island_cone(parent, "SnowPeak_West", Vector3(-34.0, base_y + 9.0, 12.0), 19.0, 18.0, pale_rock)
			_add_island_cone(parent, "SnowPeak_East", Vector3(38.0, base_y + 8.0, -14.0), 17.0, 16.0, snow)
		"volcanic":
			_add_island_cone(parent, "StormglassVolcano", Vector3(0.0, base_y + 18.0, 0.0), 42.0, 36.0, dark_rock)
			var crater := TorusMesh.new()
			crater.inner_radius = 7.0
			crater.outer_radius = 10.0
			var crater_visual := MeshInstance3D.new()
			crater_visual.name = "VolcanoCraterRim"
			crater_visual.mesh = crater
			crater_visual.position = Vector3(0.0, base_y + 35.0, 0.0)
			crater_visual.material_override = lava
			parent.add_child(crater_visual)
			var lava_pool := MeshInstance3D.new()
			lava_pool.name = "VolcanoLavaPool"
			var pool_mesh := CylinderMesh.new()
			pool_mesh.top_radius = 6.5
			pool_mesh.bottom_radius = 6.5
			pool_mesh.height = 0.35
			lava_pool.mesh = pool_mesh
			lava_pool.position = Vector3(0.0, base_y + 34.0, 0.0)
			lava_pool.material_override = lava
			parent.add_child(lava_pool)
		"atoll":
			var lagoon := MeshInstance3D.new()
			lagoon.name = "ShallowBlueLagoon"
			var lagoon_mesh := SphereMesh.new()
			lagoon_mesh.radius = 1.0
			lagoon_mesh.height = 2.0
			lagoon.mesh = lagoon_mesh
			lagoon.position = Vector3(0.0, dimensions.y * 0.77, 0.0)
			lagoon.scale = Vector3(dimensions.x * 0.30, 0.45, dimensions.z * 0.30)
			lagoon.material_override = water
			lagoon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(lagoon)
			for index in range(6):
				var angle := TAU * float(index) / 6.0
				_add_island_cone(
					parent,
					"AtollCoralRock_%02d" % index,
					Vector3(cos(angle) * dimensions.x * 0.38, base_y + 2.5, sin(angle) * dimensions.z * 0.38),
					5.0,
					5.0 + float(index % 3) * 2.0,
					pale_rock
				)
		"highland":
			for index in range(4):
				var angle := TAU * float(index) / 4.0
				var radius := dimensions.x * 0.28
				var peak_height := 20.0 + float(index % 2) * 9.0
				_add_island_cone(
					parent,
					"SouthernReachRidge_%02d" % index,
					Vector3(cos(angle) * radius, base_y + peak_height * 0.5, sin(angle) * radius * 0.62),
					16.0 + float(index % 2) * 4.0,
					peak_height,
					pale_rock
				)
		"desert":
			for index in range(4):
				var dune := MeshInstance3D.new()
				dune.name = "FarwindSandDune_%02d" % index
				var dune_mesh := SphereMesh.new()
				dune_mesh.radius = 1.0
				dune_mesh.height = 2.0
				dune.mesh = dune_mesh
				dune.position = Vector3(
					-float(index % 2) * 24.0 + 12.0,
					base_y + 2.0,
					-30.0 + float(index) * 18.0
				)
				dune.scale = Vector3(30.0, 5.0, 15.0)
				dune.material_override = sand
				dune.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				parent.add_child(dune)
		"rocky":
			for index in range(5):
				var angle := TAU * float(index) / 5.0
				var height := 12.0 + float(index % 3) * 5.0
				_add_island_cone(
					parent,
					"BluewaterSeaStack_%02d" % index,
					Vector3(cos(angle) * dimensions.x * 0.34, base_y + height * 0.5, sin(angle) * dimensions.z * 0.34),
					7.0 + float(index % 2) * 3.0,
					height,
					dark_rock
				)
		"tropical":
			var palm_material := _make_material(Color(0.22, 0.15, 0.08), 1.0)
			var palm_leaf := _make_material(Color(0.12, 0.36, 0.17), 1.0)
			for index in range(5):
				var angle := TAU * float(index) / 5.0
				var palm := Node3D.new()
				palm.name = "WhisperingPalm_%02d" % index
				palm.position = Vector3(cos(angle) * dimensions.x * 0.32, base_y, sin(angle) * dimensions.z * 0.32)
				parent.add_child(palm)
				var trunk := MeshInstance3D.new()
				var trunk_mesh := CylinderMesh.new()
				trunk_mesh.top_radius = 0.16
				trunk_mesh.bottom_radius = 0.24
				trunk_mesh.height = 7.0
				trunk.mesh = trunk_mesh
				trunk.position.y = 3.5
				trunk.rotation.z = -0.12
				trunk.material_override = palm_material
				palm.add_child(trunk)
				var crown := MeshInstance3D.new()
				var crown_mesh := SphereMesh.new()
				crown_mesh.radius = 2.4
				crown_mesh.height = 2.0
				crown.mesh = crown_mesh
				crown.position.y = 7.0
				crown.scale = Vector3(1.8, 0.55, 1.8)
				crown.material_override = palm_leaf
				palm.add_child(crown)
		_:
			# Temperate islands retain their existing woodland and shoreline dressing.
			pass


func _add_island_cone(
	parent: Node3D,
	node_name: String,
	local_position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := ConeMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)


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
		tree.position = Vector3(offset.x * dimensions.x, dimensions.y * 0.80,
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


## Harbor details for the outer islands.
func _build_island_harbor(parent: Node3D, dimensions: Vector3, style: int, island_name: String) -> void:
	var harbor := Node3D.new()
	harbor.name = "Harbor_" + island_name.replace(" ", "")
	parent.add_child(harbor)

	var deck_material := _make_material(Color(0.34, 0.25, 0.16), 0.88)
	var metal_material := _make_material(Color(0.18, 0.23, 0.27), 0.48)
	var light_material := _make_material(Color(1.0, 0.78, 0.42), 0.35)
	light_material.emission_enabled = true
	light_material.emission = Color(1.0, 0.48, 0.12)
	light_material.emission_energy_multiplier = 1.1

	var pier_length := dimensions.x * 0.92
	var pier_width := 9.0
	var pier_y := maxf(dimensions.y * 0.42, 5.0)
	var pier_center_x := dimensions.x * 0.62 + pier_length * 0.5
	_add_box(harbor, "MainPierDeck",
		Vector3(pier_center_x, pier_y, 0.0),
		Vector3(pier_length, 1.1, pier_width), deck_material)

	for support_index in range(5):
		var support_x := dimensions.x * 0.68 + float(support_index) * pier_length * 0.20
		for side in [-1.0, 1.0]:
			_add_cylinder(harbor, "PierSupport",
				Vector3(support_x, pier_y * 0.48, side * pier_width * 0.34),
				0.42, pier_y, metal_material)

	for side in [-1.0, 1.0]:
		_add_box(harbor, "PierEdgeRail",
			Vector3(pier_center_x, pier_y + 0.85, side * (pier_width * 0.48)),
			Vector3(pier_length * 0.92, 0.22, 0.22), metal_material)

	for lamp_index in range(4):
		var lamp_x := dimensions.x * 0.76 + float(lamp_index) * pier_length * 0.22
		_add_cylinder(harbor, "HarborLampPole",
			Vector3(lamp_x, pier_y + 2.0, -pier_width * 0.34),
			0.12, 4.0, metal_material)
		_add_box(harbor, "HarborLamp",
			Vector3(lamp_x, pier_y + 4.0, -pier_width * 0.34),
			Vector3(0.8, 0.35, 0.8), light_material)

	var boat_x := pier_center_x + pier_length * 0.10
	var boat := Node3D.new()
	boat.name = "MooredFerryBoat"
	boat.position = Vector3(boat_x, 1.1, pier_width * 1.7)
	harbor.add_child(boat)
	_add_box(boat, "FerryHull", Vector3.ZERO, Vector3(15.0, 2.2, 5.0), metal_material)
	_add_box(boat, "FerryCabin", Vector3(-1.0, 2.0, 0.0), Vector3(6.0, 2.6, 4.0),
		_make_material(Color(0.72, 0.76, 0.77), 0.42))
	_add_box(boat, "FerryWindowBand", Vector3(-1.0, 2.1, -2.08),
		Vector3(4.8, 0.8, 0.08), _make_material(Color(0.08, 0.22, 0.30), 0.2))

	if style == 0 or style == 2:
		_build_lighthouse(harbor, dimensions, pier_y, light_material, metal_material)

	harbor.add_to_group("system_world_landmarks")
	harbor.set_meta("landmark_name", island_name + " Harbor")
	harbor.set_meta("landmark_type", "island_harbor")
	harbor.set_meta("fast_travel_enabled", false)


func _build_lighthouse(parent: Node3D, dimensions: Vector3, pier_y: float,
		light_material: Material, metal_material: Material) -> void:
	var lighthouse := Node3D.new()
	lighthouse.name = "CoastalLighthouse"
	lighthouse.position = Vector3(-dimensions.x * 0.48, dimensions.y * 0.48, -dimensions.z * 0.30)
	parent.add_child(lighthouse)
	_add_cylinder(lighthouse, "LighthouseTower", Vector3(0.0, 7.0, 0.0),
		2.2, 14.0, _make_material(Color(0.82, 0.81, 0.74), 0.82))
	_add_cylinder(lighthouse, "LighthouseLanternRoom", Vector3(0.0, 14.8, 0.0),
		2.5, 1.8, metal_material)
	_add_box(lighthouse, "LighthouseBeacon",
		Vector3(0.0, 15.0, 0.0), Vector3(2.0, 1.2, 2.0), light_material)
	_add_cylinder(lighthouse, "LighthouseRoof", Vector3(0.0, 16.2, 0.0),
		2.8, 1.0, metal_material)
	lighthouse.add_to_group("system_world_landmarks")
	lighthouse.set_meta("landmark_name", "Coastal Lighthouse")
	lighthouse.set_meta("landmark_type", "lighthouse")


func _add_box(parent: Node3D, node_name: String, local_position: Vector3,
		dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _add_cylinder(parent: Node3D, node_name: String, local_position: Vector3,
		radius: float, height: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.12
	mesh.height = height
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _build_navigation_buoys() -> void:
	var buoy_sites := [
		Vector2(-1290.0, -850.0), Vector2(-810.0, -900.0),
		Vector2(-300.0, -900.0), Vector2(420.0, -900.0),
		Vector2(1120.0, -820.0), Vector2(1450.0, 180.0),
		Vector2(940.0, 650.0), Vector2(40.0, 900.0),
		Vector2(-650.0, 900.0), Vector2(-1120.0, 560.0),
		Vector2(1180.0, -250.0), Vector2(700.0, 780.0)
	]
	var buoy_material := _make_material(Color(0.92, 0.34, 0.12), 0.48)
	var beacon_material := _make_material(Color(1.0, 0.82, 0.42), 0.3)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(1.0, 0.52, 0.16)
	beacon_material.emission_energy_multiplier = 1.5
	for index in range(buoy_sites.size()):
		var site: Vector2 = buoy_sites[index]
		var buoy := Node3D.new()
		buoy.name = "SeaNavigationBuoy_%02d" % (index + 1)
		buoy.position = Vector3(site.x, -0.3, site.y)
		add_child(buoy)
		_add_cylinder(buoy, "BuoyFloat", Vector3.ZERO, 1.1, 2.2, buoy_material)
		_add_cylinder(buoy, "BuoyBeaconMast", Vector3(0.0, 1.8, 0.0),
			0.12, 1.8, buoy_material)
		_add_box(buoy, "BuoySignalLight", Vector3(0.0, 2.8, 0.0),
			Vector3(0.65, 0.55, 0.65), beacon_material)
		buoy.add_to_group("system_world_landmarks")
		buoy.set_meta("landmark_type", "sea_navigation_buoy")
		buoy.set_meta("discovery_required", true)


func _build_shoreline_details(parent: Node3D, dimensions: Vector3, style: int) -> void:
	var rock_material := _make_material(ROCK_COLORS[style], 0.98)
	var shrub_material := _make_material(GRASS_COLORS[style], 1.0)
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var direction := Vector2(cos(angle), sin(angle))
		var rock := MeshInstance3D.new()
		rock.name = "CoastalBoulder_%02d" % index
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 1.0
		rock_mesh.height = 2.0
		rock.mesh = rock_mesh
		rock.position = Vector3(
			direction.x * dimensions.x * 0.91,
			dimensions.y * 0.19,
			direction.y * dimensions.z * 0.91
		)
		var rock_size := 2.2 + float(index % 4) * 0.9
		rock.scale = Vector3(rock_size * 1.4, rock_size, rock_size)
		rock.material_override = rock_material
		rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(rock)

	for index in range(7):
		var angle := TAU * (float(index) + 0.5) / 7.0
		var shrub := MeshInstance3D.new()
		shrub.name = "CoastalShrub_%02d" % index
		var shrub_mesh := SphereMesh.new()
		shrub_mesh.radius = 1.0
		shrub_mesh.height = 1.5
		shrub.mesh = shrub_mesh
		shrub.position = Vector3(
			cos(angle) * dimensions.x * 0.48,
			dimensions.y * 0.72,
			sin(angle) * dimensions.z * 0.48
		)
		shrub.scale = Vector3(2.2, 1.5, 2.2)
		shrub.material_override = shrub_material
		shrub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(shrub)

	var trail_material := _make_material(Color(0.48, 0.39, 0.27), 1.0)
	_add_box(parent, "TrailToHarbor",
		Vector3(dimensions.x * 0.40, dimensions.y * 0.48, 0.0),
		Vector3(dimensions.x * 0.55, 0.24, 3.2), trail_material)
