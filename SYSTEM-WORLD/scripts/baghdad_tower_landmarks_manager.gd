extends Node3D
class_name BaghdadTowerLandmarksManager

const EntranceScript = preload("res://scripts/system_tower_entrance.gd")
const HeadquartersInteriorScript = preload("res://scripts/system_hunter_headquarters_interior.gd")
const TowerInteriorScript = preload("res://scripts/system_baghdad_tower_interior.gd")
const BaghdadTowerFloorWorldScript = preload("res://scripts/system_baghdad_tower_floor_world.gd")
const PowerTowerArenaVenueScript = preload("res://scripts/system_power_tower_arena_venue.gd")
const PowerTowerFloorWorldScript = preload("res://scripts/system_power_tower_floor_world.gd")
const RepublicBridgeAccessManagerScript = preload("res://scripts/baghdad_republic_bridge_access_manager.gd")
const HUNTER_TOWER_HEIGHT := 1000.0
const POWER_TOWER_HEIGHT := 620.0
const TECHNOLOGY_TOWER_HEIGHT := 210.0

var terrain: Node
var city_anchor := Vector3.ZERO
var tower_material: StandardMaterial3D
var trim_material: StandardMaterial3D
var emissive_material: StandardMaterial3D
var tower_positions: Array[Dictionary] = []
var connected_tower_positions: Array[Dictionary] = []
var headquarters_position := Vector3.INF
var republic_bridge_route: Dictionary = {}

func _ready() -> void:
	name = "BaghdadTowerLandmarksManager"
	var region := get_parent()
	terrain = region.get("terrain")
	if terrain == null or not region.has_method("get_city_anchor"):
		push_warning("SYSTEM WORLD: Baghdad tower landmarks need the modern region manager.")
		return
	city_anchor = region.call("get_city_anchor", "Baghdad")
	if city_anchor == Vector3.INF:
		push_warning("SYSTEM WORLD: Baghdad anchor is unavailable; towers were not built.")
		return
	_create_materials()
	_build_hunter_tower()
	_build_business_tower()
	_build_shopping_tower()
	_build_entertainment_tower()
	_build_technology_tower()
	_build_power_tower()
	_create_connected_city_links()
	_create_hunter_association_headquarters()
	_create_public_amenities()
	_create_reference_sky_district()
	_create_republic_bridge_access()

func _create_materials() -> void:
	tower_material = StandardMaterial3D.new()
	tower_material.albedo_color = Color(0.055, 0.105, 0.16)
	tower_material.metallic = 0.78
	tower_material.roughness = 0.26
	trim_material = StandardMaterial3D.new()
	trim_material.albedo_color = Color(0.72, 0.49, 0.20)
	trim_material.metallic = 0.82
	trim_material.roughness = 0.22
	emissive_material = StandardMaterial3D.new()
	emissive_material.albedo_color = Color(0.08, 0.72, 0.95)
	emissive_material.emission_enabled = true
	emissive_material.emission = Color(0.02, 0.62, 1.0)
	emissive_material.emission_energy_multiplier = 3.2

func _build_hunter_tower() -> void:
	var position := city_anchor + Vector3(0.0, 0.0, 365.0)
	_build_tower(
		"HunterAssociationTower",
		"برج الصيادين العالمي",
		"hunter_association_tower_baghdad",
		position,
		HUNTER_TOWER_HEIGHT,
		38.0,
		200,
		Color(0.08, 0.62, 0.92)
	)

func _build_power_tower() -> void:
	var position := city_anchor + Vector3(850.0, 0.0, 600.0)
	_build_tower(
		"PowerTower",
		"برج القوة",
		"power_tower_baghdad",
		position,
		POWER_TOWER_HEIGHT,
		22.0,
		200,
		Color(0.95, 0.55, 0.16),
		false, false, NAN, false
	)
	var power_tower := get_node_or_null("PowerTower")
	if power_tower != null:
		var arena_venue := PowerTowerArenaVenueScript.new()
		arena_venue.name = "PowerTowerArenaVenue"
		power_tower.add_child(arena_venue)
		var floor_world := PowerTowerFloorWorldScript.new()
		floor_world.name = "PowerTowerFloorWorld"
		floor_world.position = Vector3(0.0, 6000.0, 0.0)
		power_tower.add_child(floor_world)

func _build_tower(
	node_name: String,
	title: String,
	location_id: String,
	world_position: Vector3,
	height: float,
	radius: float,
	floors: int,
	beacon_color: Color,
	connected_to_district: bool = true,
	use_exact_position: bool = false,
	base_height_override: float = NAN,
	build_playable_interior: bool = true
) -> void:
	var requested_position := Vector2(world_position.x, world_position.z)
	var resolved := requested_position if use_exact_position else _nearest_land_position(requested_position)
	if resolved == Vector2.INF:
		push_warning("SYSTEM WORLD: no suitable land for tower " + title)
		return
	var base_height := float(terrain.call("get_terrain_height", resolved.x, resolved.y))
	if is_finite(base_height_override):
		base_height = base_height_override
	var root := Node3D.new()
	root.name = node_name
	root.position = Vector3(resolved.x, base_height, resolved.y)
	root.set_meta("connected_to_local_tower_district", connected_to_district)
	add_child(root)
	var tower_record := {"id": location_id, "name": title, "position": root.position, "height": height, "radius": radius, "floors": floors, "connected_to_district": connected_to_district, "has_playable_interior": build_playable_interior}
	tower_positions.append(tower_record)
	if connected_to_district:
		connected_tower_positions.append(tower_record)

	var base := MeshInstance3D.new()
	base.name = "MonumentalFoundation"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = radius * 1.32
	base_mesh.bottom_radius = radius * 1.48
	base_mesh.height = 7.0
	base.mesh = base_mesh
	base.position.y = 3.5
	base.material_override = trim_material
	root.add_child(base)

	var structure_body := StaticBody3D.new()
	structure_body.name = "TowerStructureCollision"
	root.add_child(structure_body)
	var foundation_collision := CollisionShape3D.new()
	foundation_collision.name = "FoundationCollisionShape"
	var foundation_shape := CylinderShape3D.new()
	foundation_shape.radius = radius * 1.48
	foundation_shape.height = 7.0
	foundation_collision.shape = foundation_shape
	foundation_collision.position.y = 3.5
	# Public entrances sit outside the tower footprint and teleport visitors into
	# the separate interior scene; keep the visible exterior physically solid.
	foundation_collision.disabled = false
	structure_body.add_child(foundation_collision)
	var shaft_collision := CollisionShape3D.new()
	shaft_collision.name = "ShaftCollisionShape"
	var shaft_shape := CylinderShape3D.new()
	shaft_shape.radius = radius
	shaft_shape.height = height
	shaft_collision.shape = shaft_shape
	shaft_collision.position.y = height * 0.5 + 7.0
	# The detached playable lobby is not inside this exterior mesh volume.
	# All six visible tower shafts therefore need their own solid collision shell.
	shaft_collision.disabled = false
	structure_body.add_child(shaft_collision)

	var shaft := MeshInstance3D.new()
	shaft.name = "TowerMainShaft"
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = radius * 0.62
	shaft_mesh.bottom_radius = radius
	shaft_mesh.height = height
	shaft.mesh = shaft_mesh
	shaft.position.y = height * 0.5 + 7.0
	shaft.material_override = tower_material
	root.add_child(shaft)

	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = radius * 1.035
	floor_mesh.bottom_radius = radius * 1.035
	floor_mesh.height = 0.72
	var floor_multimesh := MultiMesh.new()
	floor_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	floor_multimesh.mesh = floor_mesh
	floor_multimesh.instance_count = floors
	for index in range(floors):
		var y := 9.0 + (height - 16.0) * float(index) / float(maxi(floors - 1, 1))
		floor_multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(0.0, y, 0.0)))
	var floor_bands := MultiMeshInstance3D.new()
	floor_bands.name = "VisibleFloorBands_%d" % floors
	floor_bands.multimesh = floor_multimesh
	floor_bands.material_override = trim_material
	root.add_child(floor_bands)

	for side in range(4):
		var rib := MeshInstance3D.new()
		var rib_mesh := BoxMesh.new()
		rib_mesh.size = Vector3(1.6, height * 0.94, 1.6)
		rib.mesh = rib_mesh
		var angle := TAU * float(side) / 4.0
		rib.position = Vector3(cos(angle) * radius * 0.56, height * 0.5 + 7.0, sin(angle) * radius * 0.56)
		rib.material_override = trim_material
		root.add_child(rib)

	var crown := MeshInstance3D.new()
	crown.name = "Crown"
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = radius * 0.28
	crown_mesh.bottom_radius = radius * 0.64
	crown_mesh.height = height * 0.075
	crown.mesh = crown_mesh
	crown.position.y = height + 7.0 + height * 0.0375
	crown.material_override = trim_material
	root.add_child(crown)

	var beacon := OmniLight3D.new()
	beacon.name = "SkyBeacon"
	beacon.position.y = height + 22.0
	beacon.light_color = beacon_color
	beacon.light_energy = 2.0
	beacon.omni_range = 90.0
	beacon.shadow_enabled = false
	root.add_child(beacon)

	var beacon_core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 3.5
	core_mesh.height = 7.0
	beacon_core.mesh = core_mesh
	beacon_core.position.y = height + 22.0
	beacon_core.material_override = emissive_material
	root.add_child(beacon_core)

	var entrance := EntranceScript.new()
	entrance.name = "PublicEntrance"
	entrance.configure(location_id, title, "region_baghdad")
	var entrance_shape := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.5
	entrance_shape.shape = shape
	entrance.add_child(entrance_shape)
	entrance.position = Vector3(0.0, 3.0, radius * 1.48 + 6.0)
	root.add_child(entrance)

	# All five primary towers receive playable service lobbies; the bridge outpost is linked by its express skyway.
	# Power Tower is deliberately excluded: it remains an independent challenge venue.
	if build_playable_interior:
		var tower_interior := TowerInteriorScript.new()
		tower_interior.name = "TowerInterior"
		root.add_child(tower_interior)
		tower_interior.call("build", location_id, title, EntranceScript, entrance.global_position + Vector3(0.0, 0.0, 5.0), floors)
		var tower_floor_world := BaghdadTowerFloorWorldScript.new()
		tower_floor_world.name = "BaghdadTowerFloorWorld"
		tower_floor_world.position = Vector3(0.0, 4000.0, 0.0)
		root.add_child(tower_floor_world)
		tower_floor_world.call("setup", location_id, floors)

	var label := Label3D.new()
	label.name = "TowerNameSign"
	label.text = title
	label.font_size = 44 if floors > 40 else 32
	label.position = Vector3(0.0, 13.0, radius * 1.5)
	label.pixel_size = 0.012
	label.modulate = beacon_color
	root.add_child(label)

	_create_tower_architecture(root, node_name, title, height, radius, floors, beacon_color)
	_create_tower_advertising_screens(root, node_name, height, radius)

	root.set_meta("tower_id", location_id)
	root.set_meta("tower_floor_count", floors)
	print("SYSTEM WORLD: landmark tower generated: ", title, " / ", floors, " floors / ", height, "m")

func _nearest_land_position(origin: Vector2) -> Vector2:
	if terrain.call("is_land_position", origin.x, origin.y):
		return origin
	for radius_step in range(1, 17):
		var radius := float(radius_step) * 12.0
		for sample in range(32):
			var angle := TAU * float(sample) / 32.0
			var candidate := origin + Vector2(cos(angle), sin(angle)) * radius
			if terrain.call("is_land_position", candidate.x, candidate.y):
				return candidate
	return Vector2.INF


func get_tower_root(tower_id: String) -> Node3D:
	for child in get_children():
		if child is Node3D and str(child.get_meta("tower_id", "")) == tower_id:
			return child as Node3D
	return null


func get_tower_positions() -> Array[Dictionary]:
	return tower_positions.duplicate(true)



func _build_business_tower() -> void:
	_build_tower("BusinessTower", "برج الأعمال", "business_tower_baghdad", city_anchor + Vector3(-350.0, 0.0, 350.0), 220.0, 26.0, 36, Color(0.24, 0.78, 0.72))


func _build_shopping_tower() -> void:
	republic_bridge_route = _read_verified_republic_bridge_route()
	var tower_position := city_anchor + Vector3(-355.0, 0.0, -350.0)
	var connected_to_district := true
	var use_exact_position := false
	var platform_height_override := NAN
	if not republic_bridge_route.is_empty():
		var anchor: Array = republic_bridge_route["tower_anchor_local_m"]
		tower_position = Vector3(float(anchor[0]), 0.0, float(anchor[1]))
		platform_height_override = float(republic_bridge_route["world_tower_platform_elevation_m"])
		connected_to_district = false
		use_exact_position = true
	_build_tower(
		"ShoppingTower", "برج الأسلحة وإيقاظ النِن", "shopping_tower_baghdad",
		tower_position, 190.0, 30.0, 32, Color(0.95, 0.72, 0.28),
		connected_to_district, use_exact_position, platform_height_override, true
	)
	var armory_tower := get_node_or_null("ShoppingTower")
	if armory_tower != null:
		armory_tower.set_meta("tower_role", "weapon_armory_and_nen_awakening")
		armory_tower.set_meta("target_latitude", 33.32495)
		armory_tower.set_meta("target_longitude", 44.40483)
		armory_tower.set_meta("target_landmark", "Republic Bridge / جسر الجمهورية")
		armory_tower.set_meta("target_river", "Tigris / نهر دجلة")
		armory_tower.set_meta("target_bank_connection", PackedStringArray(["Al-Karkh / الكرخ", "Al-Rusafa / الرصافة"]))
		armory_tower.set_meta("geospatial_relocation_pending", republic_bridge_route.is_empty())
		armory_tower.set_meta("real_world_anchor_verified", false)
		armory_tower.set_meta("tower_network_role", "republic_bridge_outpost" if not republic_bridge_route.is_empty() else "core_district_pending")
		if not republic_bridge_route.is_empty():
			armory_tower.set_meta("bridge_osm_centerline_id", "754157537")
			armory_tower.set_meta("tigris_osm_centerline_id", "24709603")
			armory_tower.set_meta("tower_platform_elevation_world_m", platform_height_override)


func _read_verified_republic_bridge_route() -> Dictionary:
	var manifest_path := "res://data/geography/baghdad/cell_pack/manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return {}
	var manifest_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest_value is Dictionary:
		return {}
	var manifest: Dictionary = manifest_value
	if int(manifest.get("ground_layer_schema_version", 0)) != 1:
		return {}
	var source_ground := float(manifest.get("ground_elevation_m", NAN))
	var source_water := float(manifest.get("water_surface_elevation_m", NAN))
	var source_bridge := float(manifest.get("bridge_deck_elevation_m", NAN))
	if not is_finite(source_ground) or not is_finite(source_water) or not is_finite(source_bridge):
		return {}
	if not is_equal_approx(source_ground, 34.0) or not is_equal_approx(source_water, 28.0) or not is_equal_approx(source_bridge, 34.28):
		return {}
	var route: Dictionary = manifest.get("landmark_routes", {}).get("republic_bridge", {})
	if str(route.get("osm_bridge_polygon_id", "")) != "1077808833":
		return {}
	if str(route.get("osm_bridge_centerline_id", "")) != "754157537":
		return {}
	if str(route.get("osm_tigris_water_polygon_id", "")) != "1145641":
		return {}
	if str(route.get("osm_tigris_centerline_id", "")) != "24709603":
		return {}
	var anchor: Array = route.get("tower_anchor_local_m", [])
	var bank_points: Array = route.get("bank_access_points_local_m", [])
	var centerline: Array = route.get("centerline_local_m", [])
	var skyway_start: Array = route.get("express_skyway_start_local_m", [])
	var skyway_support_points: Array = route.get("express_skyway_support_points_local_m", [])
	if anchor.size() != 2 or bank_points.size() != 2 or centerline.size() < 2 or skyway_start.size() != 2 or skyway_support_points.size() < 5:
		return {}
	var bounds: Array = manifest.get("cell_bounds_inclusive", [])
	if bounds.size() != 4:
		return {}
	var target_cell_x := floori(float(anchor[0]) / float(manifest.get("cell_size_m", 200.0)))
	var target_cell_z := floori(float(anchor[1]) / float(manifest.get("cell_size_m", 200.0)))
	if target_cell_x < int(bounds[0]) or target_cell_x > int(bounds[1]) or target_cell_z < int(bounds[2]) or target_cell_z > int(bounds[3]):
		return {}
	var source_platform := float(route.get("tower_platform_elevation_m", NAN))
	var top_level_platform := float(manifest.get("bridge_tower_platform_elevation_m", NAN))
	var source_river := float(route.get("river_surface_elevation_m", NAN))
	var source_deck := float(route.get("bridge_deck_elevation_m", NAN))
	if not is_finite(source_platform) or not is_finite(top_level_platform) or not is_finite(source_river) or not is_finite(source_deck):
		return {}
	if not is_equal_approx(source_platform, top_level_platform) or not is_equal_approx(source_river, source_water) or not is_equal_approx(source_deck, source_bridge):
		return {}
	if source_platform - source_river < 18.0 or source_platform <= source_deck:
		return {}
	var world_ground := float(terrain.call("get_terrain_height", city_anchor.x, city_anchor.z))
	if terrain.has_method("configure_baghdad_osm_ground"):
		if not bool(terrain.get("baghdad_osm_ground_enabled")):
			terrain.call("configure_baghdad_osm_ground", world_ground)
		if bool(terrain.get("baghdad_osm_ground_enabled")):
			world_ground = float(terrain.get("baghdad_osm_world_ground_elevation_m"))
	var karkh_bank: Array = bank_points[0]
	var rusafa_bank: Array = bank_points[1]
	if karkh_bank.size() != 2 or rusafa_bank.size() != 2:
		return {}
	route["world_ground_elevation_m"] = world_ground
	var bank_height_method := "get_baghdad_osm_ground_height" if terrain.has_method("get_baghdad_osm_ground_height") else "get_terrain_height"
	route["world_karkh_bank_elevation_m"] = float(terrain.call(bank_height_method, float(karkh_bank[0]), float(karkh_bank[1])))
	route["world_rusafa_bank_elevation_m"] = float(terrain.call(bank_height_method, float(rusafa_bank[0]), float(rusafa_bank[1])))
	route["world_bridge_deck_elevation_m"] = world_ground + source_deck - source_ground
	route["world_river_surface_elevation_m"] = world_ground + source_river - source_ground
	route["world_tower_platform_elevation_m"] = world_ground + source_platform - source_ground
	return route


func _build_entertainment_tower() -> void:
	_build_tower("EntertainmentTower", "برج الترفيه", "entertainment_tower_baghdad", city_anchor + Vector3(355.0, 0.0, -350.0), 205.0, 29.0, 34, Color(0.75, 0.38, 0.95))


func _build_technology_tower() -> void:
	_build_tower("TechnologyTower", "برج التكنولوجيا والابتكار", "technology_tower_baghdad", city_anchor + Vector3(355.0, 0.0, 350.0), TECHNOLOGY_TOWER_HEIGHT, 28.0, 36, Color(0.18, 0.88, 0.78))


func _create_hunter_association_headquarters() -> void:
	# The Hunter Association headquarters crowns the shared five-tower district;
	# it is an elevated headquarters building, not a sixth tower and not part of Power Tower.
	var headquarters := Node3D.new()
	headquarters.name = "HunterAssociationHeadquarters"
	var highest_district_roof := city_anchor.y
	var highest_tower: Dictionary = {}
	for tower_data in connected_tower_positions:
		var roof_y := float(tower_data["position"].y) + float(tower_data["height"]) + 14.0
		if roof_y > highest_district_roof:
			highest_district_roof = roof_y
			highest_tower = tower_data
	headquarters.position = Vector3(city_anchor.x, highest_district_roof + 12.0, city_anchor.z)
	headquarters_position = headquarters.position
	add_child(headquarters)

	var podium := MeshInstance3D.new()
	podium.name = "HeadquartersSkyPodium"
	var podium_mesh := BoxMesh.new()
	podium_mesh.size = Vector3(156.0, 4.0, 118.0)
	podium.mesh = podium_mesh
	podium.position.y = 2.0
	podium.material_override = trim_material
	headquarters.add_child(podium)
	_add_static_box_collision(headquarters, "HeadquartersPodiumCollision", podium.position, podium_mesh.size)

	var hall := MeshInstance3D.new()
	hall.name = "GlobalHunterHeadquartersHall"
	var hall_mesh := BoxMesh.new()
	hall_mesh.size = Vector3(112.0, 28.0, 82.0)
	hall.mesh = hall_mesh
	hall.position.y = 18.0
	hall.material_override = tower_material
	headquarters.add_child(hall)
	var headquarters_interior := HeadquartersInteriorScript.new()
	headquarters_interior.name = "HeadquartersInterior"
	headquarters.add_child(headquarters_interior)
	headquarters_interior.call("build", EntranceScript)

	# Four monumental corner pylons give the elevated headquarters a distinct skyline silhouette.
	for corner_index in range(4):
		var pylon := MeshInstance3D.new()
		pylon.name = "HeadquartersCornerPylon_%d" % corner_index
		var pylon_mesh := CylinderMesh.new()
		pylon_mesh.top_radius = 2.8
		pylon_mesh.bottom_radius = 5.0
		pylon_mesh.height = 28.0
		pylon.mesh = pylon_mesh
		var x_side := -1.0 if corner_index in [0, 2] else 1.0
		var z_side := -1.0 if corner_index in [0, 1] else 1.0
		pylon.position = Vector3(x_side * 66.0, 16.0, z_side * 51.0)
		pylon.material_override = trim_material
		headquarters.add_child(pylon)

	var crown := MeshInstance3D.new()
	crown.name = "HeadquartersCrown"
	var crown_mesh := BoxMesh.new()
	crown_mesh.size = Vector3(120.0, 2.0, 90.0)
	crown.mesh = crown_mesh
	crown.position.y = 33.0
	crown.material_override = emissive_material
	headquarters.add_child(crown)

	var sign := Label3D.new()
	sign.name = "HeadquartersIdentitySign"
	sign.text = "WORLD HUNTER ASSOCIATION\nالمقر الرئيسي لنقابة الصيادين"
	sign.font_size = 38
	sign.position = Vector3(0.0, 36.0, 42.0)
	sign.pixel_size = 0.014
	sign.modulate = Color(0.45, 0.88, 1.0)
	headquarters.add_child(sign)

	var entrance := EntranceScript.new()
	entrance.name = "HeadquartersEntrance"
	entrance.configure("hunter_association_headquarters_baghdad", "المقر الرئيسي لنقابة الصيادين", "region_baghdad")
	var entrance_shape := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 5.0
	entrance_shape.shape = shape
	entrance.add_child(entrance_shape)
	entrance.position = Vector3(0.0, 6.0, 48.0)
	headquarters.add_child(entrance)

	# Connect the headquarters sky platform to the highest district tower roof.
	# This is a dedicated access bridge, not an extension of the five-tower district loop.
	if not highest_tower.is_empty():
		var access_bridge := Node3D.new()
		access_bridge.name = "HunterHeadquartersSkyAccessBridge"
		add_child(access_bridge)
		var tower_roof: Vector3 = highest_tower["position"] + Vector3(0.0, float(highest_tower["height"]) + 14.0, 0.0)
		var headquarters_edge := headquarters.position + Vector3(0.0, 2.0, 59.0)
		_create_link_deck(access_bridge, tower_roof, headquarters_edge, "HunterHeadquartersAccessDeck", 16.0, 2.4, trim_material)
		for side in range(2):
			var rail := MeshInstance3D.new()
			rail.name = "HeadquartersAccessRail_%d" % side
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(1.2, 3.0, tower_roof.distance_to(headquarters_edge))
			rail.mesh = rail_mesh
			rail.position = (tower_roof + headquarters_edge) * 0.5 + Vector3(8.0 if side == 0 else -8.0, 2.0, 0.0)
			rail.rotation.y = atan2((headquarters_edge - tower_roof).x, (headquarters_edge - tower_roof).z)
			rail.material_override = emissive_material
			access_bridge.add_child(rail)
		headquarters.set_meta("district_headquarters", true)


func get_headquarters_position() -> Vector3:
	return headquarters_position


func _create_tower_architecture(root: Node3D, node_name: String, title: String, height: float, radius: float, floors: int, beacon_color: Color) -> void:
	# Procedural architectural blockout: podium terraces, facade fins, crown and identity signage.
	for tier in range(3):
		var podium := MeshInstance3D.new()
		podium.name = "PodiumTerrace_%d" % tier
		var podium_mesh := CylinderMesh.new()
		podium_mesh.top_radius = radius * (1.48 - float(tier) * 0.13)
		podium_mesh.bottom_radius = radius * (1.62 - float(tier) * 0.13)
		podium_mesh.height = 3.0
		podium.mesh = podium_mesh
		podium.position.y = 8.5 + float(tier) * 3.2
		podium.material_override = trim_material if tier == 0 else tower_material
		root.add_child(podium)
	for side in range(4):
		var fin := MeshInstance3D.new()
		fin.name = "FacadeFin_%d" % side
		var fin_mesh := BoxMesh.new()
		fin_mesh.size = Vector3(2.0, height * 0.94, 2.0)
		fin.mesh = fin_mesh
		var angle := TAU * float(side) / 4.0
		fin.position = Vector3(cos(angle) * radius * 0.82, height * 0.5 + 7.0, sin(angle) * radius * 0.82)
		fin.material_override = trim_material
		root.add_child(fin)
	var identity_ring := MeshInstance3D.new()
	identity_ring.name = "IlluminatedIdentityRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = radius * 0.72
	ring_mesh.bottom_radius = radius * 0.72
	ring_mesh.height = 1.2
	identity_ring.mesh = ring_mesh
	identity_ring.position.y = height * 0.72 + 7.0
	identity_ring.material_override = emissive_material
	root.add_child(identity_ring)
	_create_tower_identity_features(root, node_name, height, radius)
	_create_tower_facade_glazing(root, height, radius, floors, beacon_color)
	if node_name != "PowerTower":
		_create_tower_exterior_detail_pass(root, title, height, radius, beacon_color, floors)


func _create_connected_city_links() -> void:
	# Elevated pedestrian/vehicle corridor blockout linking only the five district towers.
	# Power Tower is intentionally excluded and remains a remote independent landmark.
	if connected_tower_positions.size() < 2:
		return
	var link_root := Node3D.new()
	link_root.name = "FiveTowerConnectedDistrict"
	add_child(link_root)
	for index in range(connected_tower_positions.size()):
		var first: Vector3 = connected_tower_positions[index]["position"]
		var second: Vector3 = connected_tower_positions[(index + 1) % connected_tower_positions.size()]["position"]
		_create_link_deck(link_root, first + Vector3(0.0, 34.0, 0.0), second + Vector3(0.0, 34.0, 0.0), "SkyPromenade_%d" % index, 12.0, 0.65, trim_material)
		_create_link_deck(link_root, first + Vector3(0.0, 23.0, 0.0), second + Vector3(0.0, 23.0, 0.0), "VehicleDeck_%d" % index, 18.0, 1.1, tower_material)
		_create_vehicle_access_ramp(link_root, first, index)


func _create_link_deck(parent: Node3D, start: Vector3, finish: Vector3, deck_name: String, width: float, thickness: float, material: Material) -> void:
	var midpoint := (start + finish) * 0.5
	var delta := finish - start
	var deck := MeshInstance3D.new()
	deck.name = deck_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, thickness, delta.length())
	deck.mesh = mesh
	deck.position = midpoint
	deck.rotation.y = atan2(delta.x, delta.z)
	deck.material_override = material
	parent.add_child(deck)
	var collision_body := StaticBody3D.new()
	collision_body.name = deck_name + "_Collision"
	collision_body.position = midpoint
	collision_body.rotation.y = deck.rotation.y
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	collision_body.add_child(collision)
	parent.add_child(collision_body)


func _create_vehicle_access_ramp(parent: Node3D, tower_position: Vector3, index: int) -> void:
	# Collision-backed ramp segments are walkable; drivable vehicle navigation and slope testing remain future work.
	var ramp_root := Node3D.new()
	ramp_root.name = "VehicleAccessRamp_%d" % index
	parent.add_child(ramp_root)
	var outward := Vector3(1.0, 0.0, 0.35) if index % 2 == 0 else Vector3(-1.0, 0.0, -0.35)
	var horizontal := Vector3(tower_position.x, 0.0, tower_position.z) + outward.normalized() * 58.0
	for segment in range(8):
		var t0 := float(segment) / 8.0
		var t1 := float(segment + 1) / 8.0
		var a := Vector3(horizontal.x, 2.0 + t0 * 21.0, horizontal.z) + outward * (t0 * 42.0)
		var b := Vector3(horizontal.x, 2.0 + t1 * 21.0, horizontal.z) + outward * (t1 * 42.0)
		_create_link_deck(ramp_root, a, b, "RampSegment_%d" % segment, 18.0, 1.0, tower_material)


func _create_public_amenities() -> void:
	var amenities := Node3D.new()
	amenities.name = "ConnectedCityPublicAmenities_Blockout"
	add_child(amenities)
	var amenity_specs := [
		{"name": "RooftopGardenDeck", "offset": Vector3(0.0, 38.0, 0.0), "size": Vector3(92.0, 1.2, 54.0), "material": trim_material},
		{"name": "LeisureAndPoolDeck", "offset": Vector3(0.0, 42.0, 72.0), "size": Vector3(68.0, 1.0, 42.0), "material": emissive_material},
		{"name": "FamilyEntertainmentPlaza", "offset": Vector3(0.0, 28.0, -78.0), "size": Vector3(82.0, 1.0, 48.0), "material": tower_material}
	]
	for spec in amenity_specs:
		var deck := MeshInstance3D.new()
		deck.name = str(spec["name"])
		var mesh := BoxMesh.new()
		mesh.size = spec["size"]
		deck.mesh = mesh
		deck.position = city_anchor + spec["offset"]
		deck.material_override = spec["material"]
		amenities.add_child(deck)
		_add_static_box_collision(amenities, str(spec["name"]) + "_Collision", deck.position, mesh.size)
	amenities.set_meta("planned_facilities", PackedStringArray(["parks", "restaurants", "cafes", "hotels", "cinema", "amusement_park", "water_park", "swimming_pools", "sports_courts", "family_services", "parking", "emergency_access"]))
	_create_multilevel_parking_blockout(amenities)
	_create_vertical_access_blockout(amenities)


func _create_multilevel_parking_blockout(parent: Node3D) -> void:
	var garage := Node3D.new()
	garage.name = "ConnectedDistrictParkingGarage_Blockout"
	garage.position = city_anchor + Vector3(112.0, 0.0, 24.0)
	parent.add_child(garage)
	var floor_material := _make_surface_material(Color(0.12, 0.15, 0.18), 0.82, 0.28)
	var marking_material := _make_surface_material(Color(0.88, 0.78, 0.48), 0.7, 0.0)
	for level in range(3):
		var y := 8.0 + float(level) * 6.0
		var slab := MeshInstance3D.new()
		slab.name = "ParkingLevel_%02d" % level
		var slab_mesh := BoxMesh.new()
		slab_mesh.size = Vector3(72.0, 0.65, 48.0)
		slab.mesh = slab_mesh
		slab.position = Vector3(0.0, y, 0.0)
		slab.material_override = floor_material
		garage.add_child(slab)
		_add_static_box_collision(garage, "ParkingLevelCollision_%02d" % level, slab.position, slab_mesh.size)
		for bay in range(10):
			var line := MeshInstance3D.new()
			line.name = "ParkingBayLine_%02d_%02d" % [level, bay]
			var line_mesh := BoxMesh.new()
			line_mesh.size = Vector3(0.14, 0.04, 5.4)
			line.mesh = line_mesh
			line.position = Vector3(-31.0 + float(bay) * 6.8, y + 0.36, -13.0)
			line.material_override = marking_material
			garage.add_child(line)
	for level in range(2):
		var ramp_start := Vector3(-25.0, 8.35 + float(level) * 6.0, 16.0)
		var ramp_end := Vector3(25.0, 14.35 + float(level) * 6.0, 16.0)
		_create_link_deck(garage, ramp_start, ramp_end, "ParkingRamp_%02d" % level, 8.0, 0.55, floor_material)
	garage.set_meta("levels", 3)
	garage.set_meta("parking_bays_visual", 30)


func _create_vertical_access_blockout(parent: Node3D) -> void:
	var access := Node3D.new()
	access.name = "PedestrianElevatorAndServiceCore_Blockout"
	access.position = city_anchor + Vector3(-112.0, 0.0, 24.0)
	parent.add_child(access)
	var core_material := _make_surface_material(Color(0.18, 0.25, 0.31), 0.5, 0.42)
	for shaft_index in range(2):
		var shaft := MeshInstance3D.new()
		shaft.name = "ElevatorShaftVisual_%02d" % shaft_index
		var shaft_mesh := BoxMesh.new()
		shaft_mesh.size = Vector3(7.0, 34.0, 7.0)
		shaft.mesh = shaft_mesh
		shaft.position = Vector3(float(shaft_index) * 10.0, 17.0, 0.0)
		shaft.material_override = core_material
		access.add_child(shaft)
	access.set_meta("planned_access", PackedStringArray(["passenger_elevator", "service_elevator", "emergency_stairwell"]))
	access.set_meta("interactive_lift_ready", false)


func _add_static_box_collision(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _make_surface_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material



func _create_reference_sky_district() -> void:
	# Four core towers stay on the local ring; the fifth, Republic Bridge outpost,
	# joins the same network through a dedicated elevated express skyway.
	var district := Node3D.new()
	district.name = "BaghdadReferenceSkyPromenade_Blockout"
	add_child(district)
	var deck_material := _make_surface_material(Color(0.075, 0.12, 0.17), 0.34, 0.72)
	var rail_material := _make_surface_material(Color(0.16, 0.31, 0.39), 0.24, 0.58)
	var light_material := _make_surface_material(Color(0.035, 0.58, 0.82), 0.22, 0.38)
	light_material.emission_enabled = true
	light_material.emission = Color(0.02, 0.42, 0.82)
	light_material.emission_energy_multiplier = 1.8
	var segment_count := 12
	var ring_radius := 580.0
	var segment_length := 302.0
	var deck_width := 80.0
	var deck_y := 34.0
	# Radial pedestrian bridges connect each tower perimeter to the outer ring.
	# The 580 m ring radius clears the five tower footprints instead of cutting through them.
	for tower_index in range(connected_tower_positions.size()):
		var tower_data: Dictionary = connected_tower_positions[tower_index]
		var tower_position: Vector3 = tower_data["position"]
		var outward := Vector3(tower_position.x - city_anchor.x, 0.0, tower_position.z - city_anchor.z).normalized()
		var tower_radius := float(tower_data.get("radius", 28.0))
		var bridge_start := tower_position + Vector3.UP * deck_y + outward * (tower_radius + 2.0)
		var bridge_end := city_anchor + outward * ring_radius + Vector3.UP * deck_y
		_create_link_deck(district, bridge_start, bridge_end, "TowerToSkyRing_%02d" % tower_index, 12.0, 1.6, deck_material)
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		var tangent_rotation := -angle
		var center := city_anchor + Vector3(cos(angle) * ring_radius, deck_y, sin(angle) * ring_radius)
		var segment := Node3D.new()
		segment.name = "SkyPromenadeSegment_%02d" % index
		segment.position = center
		segment.rotation.y = tangent_rotation
		district.add_child(segment)
		var deck := MeshInstance3D.new()
		deck.name = "WalkableDeck"
		var deck_mesh := BoxMesh.new()
		deck_mesh.size = Vector3(deck_width, 2.4, segment_length)
		deck.mesh = deck_mesh
		deck.material_override = deck_material
		segment.add_child(deck)
		_add_static_box_collision(segment, "WalkableDeckCollision", Vector3.ZERO, deck_mesh.size)
		for side in [-1.0, 1.0]:
			var rail := MeshInstance3D.new()
			rail.name = "GlassSafetyRail_%s" % str(int(side))
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(1.0, 3.2, segment_length)
			rail.mesh = rail_mesh
			rail.position = Vector3(side * (deck_width * 0.5 - 1.0), 2.7, 0.0)
			rail.material_override = rail_material
			segment.add_child(rail)
			_add_static_box_collision(segment, "GlassSafetyRailCollision_%s" % str(int(side)), rail.position, rail_mesh.size)
			var rail_light := MeshInstance3D.new()
			rail_light.name = "RailLight_%s" % str(int(side))
			var light_mesh := BoxMesh.new()
			light_mesh.size = Vector3(0.32, 0.12, segment_length - 8.0)
			rail_light.mesh = light_mesh
			rail_light.position = Vector3(side * (deck_width * 0.5 - 1.0), 1.15, 0.0)
			rail_light.material_override = light_material
			segment.add_child(rail_light)
		if index % 2 == 0:
			var planter := MeshInstance3D.new()
			planter.name = "SkyGardenPlanter"
			var planter_mesh := BoxMesh.new()
			planter_mesh.size = Vector3(14.0, 1.1, 18.0)
			planter.mesh = planter_mesh
			planter.position = Vector3(0.0, 1.7, 0.0)
			planter.material_override = trim_material
			segment.add_child(planter)
			var tree_trunk := MeshInstance3D.new()
			tree_trunk.name = "SkyGardenTreeTrunk"
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.45
			trunk_mesh.bottom_radius = 0.7
			trunk_mesh.height = 5.0
			tree_trunk.mesh = trunk_mesh
			tree_trunk.position = Vector3(0.0, 4.7, 0.0)
			tree_trunk.material_override = tower_material
			segment.add_child(tree_trunk)
			var canopy := MeshInstance3D.new()
			canopy.name = "SkyGardenCanopy"
			var canopy_mesh := SphereMesh.new()
			canopy_mesh.radius = 3.2
			canopy_mesh.height = 5.6
			canopy.mesh = canopy_mesh
			canopy.position = Vector3(0.0, 8.2, 0.0)
			canopy.material_override = _make_surface_material(Color(0.12, 0.34, 0.22), 0.82, 0.0)
			segment.add_child(canopy)
	district.set_meta("reference_visual_blockout", true)
	district.set_meta("walkable_ring_segment_count", segment_count)
	district.set_meta("radial_tower_connectors", connected_tower_positions.size())
	district.set_meta("ring_radius_m", ring_radius)
	district.set_meta("segment_length_m", segment_length)
	district.set_meta("deck_width_m", deck_width)
	district.set_meta("safety_rail_collision", true)
	district.set_meta("final_art_assets_ready", false)
	district.set_meta("note", "Procedural first-pass sky promenade; validate land clearance, navigation, collision and Android performance before final art.")


func _create_tower_advertising_screens(root: Node3D, node_name: String, height: float, radius: float) -> void:
	# Two large emissive public advertising displays on every connected tower facade.
	# Content is local placeholder material; no live ad provider or tracking is enabled.
	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_color = Color(0.015, 0.12, 0.19)
	screen_material.roughness = 0.24
	screen_material.metallic = 0.32
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.015, 0.32, 0.58)
	screen_material.emission_energy_multiplier = 1.8
	var frame_material := trim_material
	var display_names := ["ExteriorAdScreen_00", "ExteriorAdScreen_01"]
	var display_heights := [18.0, maxf(34.0, height * 0.42)]
	var display_angles := [0.0, PI * 0.5]
	for index in range(display_names.size()):
		var angle: float = display_angles[index]
		var width := maxf(22.0, radius * 1.45)
		var screen_height := maxf(10.0, radius * 0.42)
		var screen_position := Vector3(sin(angle) * (radius + 1.6), display_heights[index], cos(angle) * (radius + 1.6))
		var screen_root := Node3D.new()
		screen_root.name = display_names[index]
		screen_root.position = screen_position
		screen_root.rotation.y = angle
		root.add_child(screen_root)
		var frame := MeshInstance3D.new()
		frame.name = "AdScreenFrame"
		var frame_mesh := BoxMesh.new()
		frame_mesh.size = Vector3(width + 1.4, screen_height + 1.4, 0.9)
		frame.mesh = frame_mesh
		frame.material_override = frame_material
		screen_root.add_child(frame)
		var panel := MeshInstance3D.new()
		panel.name = "AdScreenDisplay"
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(width, screen_height, 0.16)
		panel.mesh = panel_mesh
		panel.position.z = -0.52
		panel.material_override = screen_material
		screen_root.add_child(panel)
		var message := Label3D.new()
		message.name = "AdScreenMessage"
		message.text = "إعلانات بغداد\nفعاليات وعروض المدينة\nSYSTEM AD NETWORK"
		message.font_size = 30
		message.position = Vector3(0.0, 0.0, -0.64)
		message.pixel_size = 0.018
		message.modulate = Color(0.82, 0.94, 1.0)
		screen_root.add_child(message)
	root.set_meta("exterior_ad_screen_count", display_names.size())
	root.set_meta("local_ad_content_only", true)


func _create_tower_facade_glazing(root: Node3D, height: float, radius: float, floors: int, beacon_color: Color) -> void:
	# Batched glass panels and metal frames add readable facade depth without
	# creating hundreds of individual scene nodes per tower.
	var safe_floor_count := maxi(1, floors)
	var panel_width := radius * 0.68
	var panel_height := clampf((height / float(safe_floor_count)) * 0.52, 0.9, 3.2)
	var glass_material := StandardMaterial3D.new()
	glass_material.albedo_color = beacon_color.darkened(0.68)
	glass_material.metallic = 0.42
	glass_material.roughness = 0.16
	glass_material.emission_enabled = true
	glass_material.emission = beacon_color * 0.08
	glass_material.emission_energy_multiplier = 0.7
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(panel_width + 0.72, panel_height + 0.58, 0.34)
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(panel_width, panel_height, 0.16)
	var frame_multimesh := MultiMesh.new()
	frame_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	frame_multimesh.mesh = frame_mesh
	frame_multimesh.instance_count = safe_floor_count * 4
	var glass_multimesh := MultiMesh.new()
	glass_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	glass_multimesh.mesh = glass_mesh
	glass_multimesh.instance_count = safe_floor_count * 4
	var instance_index := 0
	for floor_index in range(safe_floor_count):
		var floor_y := 9.0 + (height - 16.0) * (float(floor_index) + 0.5) / float(safe_floor_count)
		for side in range(4):
			var angle := TAU * float(side) / 4.0
			var rotation := Basis(Vector3.UP, angle)
			var frame_position := Vector3(sin(angle) * (radius * 0.895), floor_y, cos(angle) * (radius * 0.895))
			var glass_position := Vector3(sin(angle) * (radius * 0.91), floor_y, cos(angle) * (radius * 0.91))
			frame_multimesh.set_instance_transform(instance_index, Transform3D(rotation, frame_position))
			glass_multimesh.set_instance_transform(instance_index, Transform3D(rotation, glass_position))
			instance_index += 1
	var frames := MultiMeshInstance3D.new()
	frames.name = "TowerFacadeMetalFrames"
	frames.multimesh = frame_multimesh
	frames.material_override = trim_material
	root.add_child(frames)
	var glazing := MultiMeshInstance3D.new()
	glazing.name = "TowerFacadeGlassPanels"
	glazing.multimesh = glass_multimesh
	glazing.material_override = glass_material
	root.add_child(glazing)
	var accent_light := OmniLight3D.new()
	accent_light.name = "TowerFacadeAccentLight"
	accent_light.position = Vector3(0.0, height * 0.56, 0.0)
	accent_light.light_color = beacon_color
	accent_light.light_energy = 0.35
	accent_light.omni_range = radius * 2.4
	accent_light.shadow_enabled = false
	root.add_child(accent_light)
	root.set_meta("facade_glass_panel_count", safe_floor_count * 4)
	root.set_meta("facade_metal_frame_count", safe_floor_count * 4)


func _create_tower_exterior_detail_pass(root: Node3D, title: String, height: float, radius: float, beacon_color: Color, floors: int) -> void:
	# Second-pass exterior detailing for the five Baghdad civic towers.
	# The independent Power Tower intentionally does not use this district facade package.
	var rib_mesh := BoxMesh.new()
	rib_mesh.size = Vector3(1.15, height * 0.86, 1.15)
	var rib_batch := MultiMesh.new()
	rib_batch.transform_format = MultiMesh.TRANSFORM_3D
	rib_batch.mesh = rib_mesh
	rib_batch.instance_count = 8
	for rib_index in range(8):
		var angle := TAU * float(rib_index) / 8.0
		var rib_position := Vector3(cos(angle) * radius * 0.94, height * 0.5 + 7.0, sin(angle) * radius * 0.94)
		rib_batch.set_instance_transform(rib_index, Transform3D(Basis(Vector3.UP, -angle), rib_position))
	var facade_ribs := MultiMeshInstance3D.new()
	facade_ribs.name = "TowerFacadeVerticalDetailRibs"
	facade_ribs.multimesh = rib_batch
	facade_ribs.material_override = trim_material
	root.add_child(facade_ribs)

	var arcade_mesh := CylinderMesh.new()
	arcade_mesh.top_radius = 0.72
	arcade_mesh.bottom_radius = 0.92
	arcade_mesh.height = 11.0
	var arcade_batch := MultiMesh.new()
	arcade_batch.transform_format = MultiMesh.TRANSFORM_3D
	arcade_batch.mesh = arcade_mesh
	arcade_batch.instance_count = 8
	for column_index in range(8):
		var angle := TAU * float(column_index) / 8.0
		var column_position := Vector3(cos(angle) * radius * 1.36, 8.5, sin(angle) * radius * 1.36)
		arcade_batch.set_instance_transform(column_index, Transform3D(Basis.IDENTITY, column_position))
	var arcade_columns := MultiMeshInstance3D.new()
	arcade_columns.name = "TowerEntranceArcadeColumns"
	arcade_columns.multimesh = arcade_batch
	arcade_columns.material_override = trim_material
	root.add_child(arcade_columns)

	var entrance_canopy := MeshInstance3D.new()
	entrance_canopy.name = "TowerGrandEntranceCanopy"
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(radius * 1.75, 1.35, 10.0)
	entrance_canopy.mesh = canopy_mesh
	entrance_canopy.position = Vector3(0.0, 14.2, radius * 1.48 + 7.0)
	entrance_canopy.material_override = tower_material
	root.add_child(entrance_canopy)

	var canopy_edge := MeshInstance3D.new()
	canopy_edge.name = "TowerGrandEntranceCanopyLight"
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(radius * 1.78, 0.32, 10.15)
	canopy_edge.mesh = edge_mesh
	canopy_edge.position = entrance_canopy.position + Vector3(0.0, -0.78, 0.0)
	canopy_edge.material_override = emissive_material
	root.add_child(canopy_edge)

	var entrance_sign := Label3D.new()
	entrance_sign.name = "TowerEntranceWayfinding"
	entrance_sign.text = title + "\nالمدخل الرئيسي  •  " + str(floors) + " طابق"
	entrance_sign.font_size = 28
	entrance_sign.pixel_size = 0.014
	entrance_sign.modulate = beacon_color
	entrance_sign.position = Vector3(0.0, 18.0, radius * 1.48 + 12.2)
	root.add_child(entrance_sign)

	var crown_ring := MeshInstance3D.new()
	crown_ring.name = "TowerCrownDetailRing"
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = radius * 0.42
	crown_mesh.bottom_radius = radius * 0.48
	crown_mesh.height = 1.1
	crown_ring.mesh = crown_mesh
	crown_ring.position.y = height + 7.0 + height * 0.075
	crown_ring.material_override = emissive_material
	root.add_child(crown_ring)

	root.set_meta("exterior_detail_pass", 2)
	root.set_meta("exterior_vertical_rib_count", 8)
	root.set_meta("entrance_arcade_column_count", 8)
	root.set_meta("grand_entrance_canopy_ready", true)


func _create_republic_bridge_access() -> void:
	if republic_bridge_route.is_empty():
		return
	var armory_tower := get_node_or_null("ShoppingTower") as Node3D
	if armory_tower == null:
		push_warning("SYSTEM WORLD: verified Republic Bridge tower anchor exists, but ShoppingTower was not built.")
		return
	var access_manager := RepublicBridgeAccessManagerScript.new()
	access_manager.name = "RepublicBridgeTowerAccessManager"
	add_child(access_manager)
	var access_ready := bool(access_manager.call("build", armory_tower, city_anchor, republic_bridge_route, terrain))
	if not access_ready:
		access_manager.queue_free()
		armory_tower.set_meta("geospatial_relocation_pending", true)
		armory_tower.set_meta("real_world_anchor_verified", false)
		armory_tower.set_meta("bridge_tower_access_ready", false)
		push_warning("SYSTEM WORLD: Republic Bridge tower access corridors failed validation; inspect the QA branch before release.")
		return
	armory_tower.set_meta("geospatial_relocation_pending", false)
	armory_tower.set_meta("real_world_anchor_verified", true)
	armory_tower.set_meta("bridge_tower_access_ready", true)
	armory_tower.set_meta("district_connector_type", "express_skyway")
	print("SYSTEM WORLD: weapon/Nen tower relocated above Republic Bridge with Al-Karkh and Al-Rusafa access corridors.")


func _create_tower_identity_features(root: Node3D, node_name: String, height: float, radius: float) -> void:
	# Low-node-count silhouette accents distinguish the five functional towers.
	# These are visual blockouts; access, collision and final materials are separate tasks.
	match node_name:
		"HunterAssociationTower":
			for tier in range(3):
				var y := height * (0.28 + float(tier) * 0.25)
				var terrace := MeshInstance3D.new()
				terrace.name = "HunterSkyTerrace_%d" % tier
				var terrace_mesh := CylinderMesh.new()
				terrace_mesh.top_radius = radius * (2.05 - float(tier) * 0.22)
				terrace_mesh.bottom_radius = radius * (2.12 - float(tier) * 0.22)
				terrace_mesh.height = 2.8
				terrace.mesh = terrace_mesh
				terrace.position.y = y
				terrace.material_override = trim_material
				root.add_child(terrace)
		"BusinessTower":
			for tier in range(4):
				var balcony := MeshInstance3D.new()
				balcony.name = "BusinessSkyOfficeDeck_%d" % tier
				var balcony_mesh := BoxMesh.new()
				balcony_mesh.size = Vector3(radius * 3.1, 2.0, radius * 1.25)
				balcony.mesh = balcony_mesh
				balcony.position = Vector3(0.0, height * (0.22 + float(tier) * 0.18), 0.0)
				balcony.rotation.y = PI * 0.25 if tier % 2 == 0 else -PI * 0.25
				balcony.material_override = trim_material
				root.add_child(balcony)
		"ShoppingTower":
			for tier in range(3):
				var market_deck := MeshInstance3D.new()
				market_deck.name = "ShoppingSkyMarketDeck_%d" % tier
				var market_mesh := CylinderMesh.new()
				market_mesh.top_radius = radius * (2.0 - float(tier) * 0.28)
				market_mesh.bottom_radius = radius * (2.08 - float(tier) * 0.28)
				market_mesh.height = 3.2
				market_deck.mesh = market_mesh
				market_deck.position.y = 16.0 + float(tier) * 30.0
				market_deck.material_override = trim_material if tier == 0 else tower_material
				root.add_child(market_deck)
		"EntertainmentTower":
			for tier in range(2):
				var halo := MeshInstance3D.new()
				halo.name = "EntertainmentSkyHalo_%d" % tier
				var halo_mesh := CylinderMesh.new()
				halo_mesh.top_radius = radius * 1.72
				halo_mesh.bottom_radius = radius * 1.72
				halo_mesh.height = 1.6
				halo.mesh = halo_mesh
				halo.position.y = height * (0.42 + float(tier) * 0.28)
				halo.material_override = emissive_material
				root.add_child(halo)
		"TechnologyTower":
			var spire := MeshInstance3D.new()
			spire.name = "TechnologyInnovationSpire"
			var spire_mesh := CylinderMesh.new()
			spire_mesh.top_radius = 0.35
			spire_mesh.bottom_radius = radius * 0.22
			spire_mesh.height = height * 0.18
			spire.mesh = spire_mesh
			spire.position.y = height + height * 0.09 + 7.0
			spire.material_override = emissive_material
			root.add_child(spire)
			for antenna_index in range(3):
				var antenna := MeshInstance3D.new()
				antenna.name = "TechnologyAntenna_%d" % antenna_index
				var antenna_mesh := CylinderMesh.new()
				antenna_mesh.top_radius = 0.12
				antenna_mesh.bottom_radius = 0.28
				antenna_mesh.height = 18.0 + float(antenna_index) * 5.0
				antenna.mesh = antenna_mesh
				antenna.position = Vector3((float(antenna_index) - 1.0) * 4.0, height + 18.0, 0.0)
				antenna.material_override = trim_material
				root.add_child(antenna)
