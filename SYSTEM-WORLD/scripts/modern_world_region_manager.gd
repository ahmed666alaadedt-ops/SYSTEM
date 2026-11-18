extends Node3D
class_name ModernWorldRegionManager

const ModernCityTrafficManagerScript = preload("res://scripts/modern_city_traffic_manager.gd")
const VehicleDealershipManagerScript = preload("res://scripts/system_vehicle_dealership_manager.gd")
const ModernWorldLightingManagerScript = preload("res://scripts/modern_world_lighting_manager.gd")
const ModernWorldAmbienceManagerScript = preload("res://scripts/modern_world_ambience_manager.gd")
const BaghdadTowerLandmarksManagerScript = preload("res://scripts/baghdad_tower_landmarks_manager.gd")
const ModernWorldTransportNetworkManagerScript = preload("res://scripts/modern_world_transport_network_manager.gd")
const ModernCityStreetFurnitureManagerScript = preload("res://scripts/modern_city_street_furniture_manager.gd")
const ModernCityServicesManagerScript = preload("res://scripts/modern_city_services_manager.gd")

## طبقة تفاصيل المدن والمناطق الحضرية للعالم الحديث.
## تُبنى فوق تضاريس القارة الموجودة ولا تستبدلها أو تغيّر مواقعها المرجعية.

const CITY_DATA := [
	{"name": "New York", "center": Vector2(-650.0, -260.0), "style": 0},
	{"name": "London", "center": Vector2(-420.0, -90.0), "style": 1},
	{"name": "Paris", "center": Vector2(-300.0, 110.0), "style": 2},
	{"name": "Baghdad", "center": Vector2(0.0, 0.0), "style": 3},
	{"name": "Moscow", "center": Vector2(120.0, -470.0), "style": 4},
	{"name": "Cairo", "center": Vector2(-80.0, 330.0), "style": 5},
	{"name": "New Delhi", "center": Vector2(390.0, 230.0), "style": 6},
	{"name": "Guangzhou", "center": Vector2(650.0, 40.0), "style": 7},
	{"name": "Seoul", "center": Vector2(820.0, -260.0), "style": 8},
	{"name": "Tokyo", "center": Vector2(1030.0, 80.0), "style": 9},
	{"name": "Singapore", "center": Vector2(560.0, 490.0), "style": 10},
	{"name": "Sydney", "center": Vector2(1050.0, 680.0), "style": 11},
	{"name": "Rio de Janeiro", "center": Vector2(-850.0, 420.0), "style": 12},
	{"name": "Johannesburg", "center": Vector2(-350.0, 610.0), "style": 13}
]

const DISTRICT_NAMES := [
	"Downtown", "OldTown", "Residential", "Commercial",
	"Industrial", "University", "Waterfront", "GreenBelt"
]
const CITY_SPACING := 34.0
const VILLAGE_DATA := [
	{"name": "Northern Crossing", "position": Vector2(-180.0, -820.0)},
	{"name": "Riverbend", "position": Vector2(210.0, 150.0)},
	{"name": "Western Orchard", "position": Vector2(-930.0, -80.0)},
	{"name": "Highland Watch", "position": Vector2(520.0, -760.0)},
	{"name": "Southern Oasis", "position": Vector2(120.0, 760.0)},
	{"name": "Coastal Haven", "position": Vector2(850.0, 560.0)},
	{"name": "Stonebridge", "position": Vector2(-540.0, 470.0)},
	{"name": "Eastern Fields", "position": Vector2(900.0, 300.0)},
	{"name": "Pine Valley", "position": Vector2(-120.0, -560.0)},
	{"name": "Desert Gate", "position": Vector2(-250.0, 430.0)}
]
const DISTRICT_OFFSETS := [
	Vector2(0.0, 0.0), Vector2(-78.0, -52.0),
	Vector2(78.0, -52.0), Vector2(-78.0, 52.0),
	Vector2(78.0, 52.0), Vector2(0.0, -112.0),
	Vector2(0.0, 112.0), Vector2(0.0, 170.0)
]

var terrain: ModernContinentManager
var rng := RandomNumberGenerator.new()
var city_anchors: Dictionary = {}
var village_anchors: Dictionary = {}
var road_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var plaza_material: StandardMaterial3D
var building_materials: Array[StandardMaterial3D] = []
var park_material: StandardMaterial3D


func _ready() -> void:
	name = "ModernWorldRegionManager"
	rng.seed = 20261118
	terrain = get_parent().get_node_or_null("ModernContinent") as ModernContinentManager
	if terrain == null:
		push_warning("SYSTEM WORLD: region manager requires ModernContinent.")
		return
	_create_materials()
	_resolve_city_anchors()
	_build_city_districts()
	_build_city_roads()
	_create_city_street_furniture()
	_create_city_services()
	_build_transport_hubs()
	_build_green_belts()
	_build_rural_settlements()
	_create_transport_network()
	_build_city_lighting()
	_create_city_dealerships()
	_create_baghdad_towers()
	_create_city_traffic()
	_create_ambient_soundscape()
	print("SYSTEM WORLD: detailed city regions initialized: ", city_anchors.size())


func _create_materials() -> void:
	road_material = _material(Color(0.075, 0.085, 0.095), 0.94)
	rail_material = _material(Color(0.28, 0.31, 0.34), 0.72, 0.35)
	plaza_material = _material(Color(0.48, 0.48, 0.43), 0.92)
	var palettes := [
		Color(0.30, 0.39, 0.48), Color(0.43, 0.42, 0.37),
		Color(0.52, 0.48, 0.40), Color(0.49, 0.39, 0.27),
		Color(0.38, 0.42, 0.47), Color(0.58, 0.48, 0.35),
		Color(0.48, 0.40, 0.34), Color(0.36, 0.43, 0.44)
	]
	for color in palettes:
		building_materials.append(_material(color, 0.78, 0.12))
	park_material = _material(Color(0.15, 0.32, 0.18), 1.0)


func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


func _resolve_city_anchors() -> void:
	for city in CITY_DATA:
		var requested: Vector2 = city["center"]
		var resolved := _nearest_land_position(requested)
		if resolved == Vector2.INF:
			push_warning("SYSTEM WORLD: no land anchor found for " + str(city["name"]))
			continue
		city_anchors[str(city["name"])] = resolved


func _nearest_land_position(origin: Vector2) -> Vector2:
	if terrain.is_land_position(origin.x, origin.y):
		return origin
	for radius_step in range(1, 13):
		var radius := float(radius_step) * 18.0
		for sample in range(24):
			var angle := TAU * float(sample) / 24.0
			var candidate := origin + Vector2(cos(angle), sin(angle)) * radius
			if terrain.is_land_position(candidate.x, candidate.y):
				return candidate
	return Vector2.INF


func _build_city_districts() -> void:
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if not city_anchors.has(city_name):
			continue
		var anchor: Vector2 = city_anchors[city_name]
		var city_root := Node3D.new()
		city_root.name = "DetailedCity_" + city_name.replace(" ", "")
		city_root.position = Vector3(anchor.x, terrain.get_terrain_height(anchor.x, anchor.y), anchor.y)
		add_child(city_root)
		_build_city_plaza(city_root, city_name)
		for district_index in range(DISTRICT_OFFSETS.size()):
			var district_center: Vector2 = anchor + DISTRICT_OFFSETS[district_index]
			_build_district(city_root, city_name, district_index, district_center)


func _build_city_plaza(parent: Node3D, city_name: String) -> void:
	var plaza := MeshInstance3D.new()
	plaza.name = city_name.replace(" ", "") + "_CivicPlaza"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 13.0
	mesh.bottom_radius = 13.0
	mesh.height = 0.35
	plaza.mesh = mesh
	plaza.position = Vector3(0.0, 0.22, 0.0)
	plaza.material_override = plaza_material
	parent.add_child(plaza)


func _build_district(parent: Node3D, city_name: String, district_index: int, center: Vector2) -> void:
	var district_name := str(DISTRICT_NAMES[district_index])
	var district := Node3D.new()
	district.name = city_name.replace(" ", "") + "_" + district_name
	district.position = Vector3(
		center.x - float(parent.position.x),
		terrain.get_terrain_height(center.x, center.y) - parent.position.y,
		center.y - float(parent.position.z)
	)
	parent.add_child(district)

	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	var transforms: Array[Transform3D] = []
	var half_width := 2
	for z_index in range(-half_width, half_width + 1):
		for x_index in range(-half_width, half_width + 1):
			if abs(x_index) <= 1 and abs(z_index) <= 1:
				continue
			var world_x := center.x + float(x_index) * CITY_SPACING
			var world_z := center.y + float(z_index) * CITY_SPACING
			if not terrain.is_land_position(world_x, world_z):
				continue
			var ground_y := terrain.get_terrain_height(world_x, world_z)
			var district_base := terrain.get_terrain_height(center.x, center.y)
			if absf(ground_y - district_base) > 13.0:
				continue
			var seed_value := absf(sin(float(district_index * 83 + x_index * 29 + z_index * 47 + city_name.length() * 11)))
			var width := 9.0 + seed_value * 8.0
			var depth := 9.0 + absf(cos(seed_value * 9.0)) * 8.0
			var height := _building_height(district_index, seed_value)
			var local_x := world_x - center.x
			var local_z := world_z - center.y
			var local_y := ground_y - district_base + height * 0.5
			var basis := Basis.from_scale(Vector3(width, height, depth))
			var transform := Transform3D(basis, Vector3(local_x, local_y, local_z))
			transforms.append(transform)
	if transforms.is_empty():
		return
	multi.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi.set_instance_transform(index, transforms[index])
	var buildings := MultiMeshInstance3D.new()
	buildings.name = "DistrictBuildings"
	buildings.multimesh = multi
	buildings.material_override = building_materials[district_index % building_materials.size()]
	district.add_child(buildings)


func _building_height(district_index: int, seed_value: float) -> float:
	match district_index:
		0:
			return 38.0 + seed_value * 95.0
		1:
			return 9.0 + seed_value * 20.0
		2:
			return 8.0 + seed_value * 18.0
		3:
			return 16.0 + seed_value * 54.0
		4:
			return 12.0 + seed_value * 35.0
		5:
			return 14.0 + seed_value * 30.0
		6:
			return 10.0 + seed_value * 42.0
		_:
			return 7.0 + seed_value * 15.0


func _build_city_roads() -> void:
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if not city_anchors.has(city_name):
			continue
		var anchor: Vector2 = city_anchors[city_name]
		_add_road_strip(city_name + "_NorthSouthBoulevard", anchor, Vector2(0.0, -185.0), 13.0)
		_add_road_strip(city_name + "_EastWestBoulevard", anchor, Vector2(185.0, 0.0), 13.0)
		_add_road_strip(city_name + "_RingRoadNorth", anchor + Vector2(0.0, -145.0), Vector2(145.0, 0.0), 8.0)
		_add_road_strip(city_name + "_RingRoadSouth", anchor + Vector2(0.0, 145.0), Vector2(145.0, 0.0), 8.0)


func _add_road_strip(node_name: String, start: Vector2, offset: Vector2, width: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(road_material)
	var direction := offset.normalized()
	var side := Vector2(-direction.y, direction.x) * width * 0.5
	var steps := 24
	for index in range(steps):
		var t0 := float(index) / float(steps)
		var t1 := float(index + 1) / float(steps)
		var p0 := start + offset * t0
		var p1 := start + offset * t1
		if not terrain.is_land_position(p0.x, p0.y) or not terrain.is_land_position(p1.x, p1.y):
			continue
		var a := Vector3(p0.x + side.x, terrain.get_terrain_height(p0.x + side.x, p0.y + side.y) + 0.18, p0.y + side.y)
		var b := Vector3(p0.x - side.x, terrain.get_terrain_height(p0.x - side.x, p0.y - side.y) + 0.18, p0.y - side.y)
		var c := Vector3(p1.x + side.x, terrain.get_terrain_height(p1.x + side.x, p1.y + side.y) + 0.18, p1.y + side.y)
		var d := Vector3(p1.x - side.x, terrain.get_terrain_height(p1.x - side.x, p1.y - side.y) + 0.18, p1.y - side.y)
		_add_quad(surface, a, b, c, d)
	surface.generate_normals()
	var mesh := surface.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var road := MeshInstance3D.new()
	road.name = node_name
	road.mesh = mesh
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road)


func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(d)


func _build_transport_hubs() -> void:
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if not city_anchors.has(city_name):
			continue
		var anchor: Vector2 = city_anchors[city_name]
		_build_hub(city_name, "InternationalAirport", anchor + Vector2(205.0, -35.0), Color(0.35, 0.68, 0.82))
		_build_hub(city_name, "CentralRailStation", anchor + Vector2(-205.0, 35.0), Color(0.82, 0.72, 0.42))


func _build_hub(city_name: String, hub_name: String, requested: Vector2, color: Color) -> void:
	var position := _nearest_land_position(requested)
	if position == Vector2.INF:
		return
	var hub := Node3D.new()
	hub.name = city_name.replace(" ", "") + "_" + hub_name
	hub.position = Vector3(position.x, terrain.get_terrain_height(position.x, position.y) + 0.3, position.y)
	add_child(hub)
	var material := _material(color, 0.65, 0.25)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(54.0, 0.6, 24.0)
	base.mesh = base_mesh
	base.position.y = 0.3
	base.material_override = plaza_material
	hub.add_child(base)
	for index in range(3):
		var tower := MeshInstance3D.new()
		var tower_mesh := BoxMesh.new()
		tower_mesh.size = Vector3(4.0, 9.0 + float(index) * 2.0, 4.0)
		tower.mesh = tower_mesh
		tower.position = Vector3(-17.0 + float(index) * 17.0, tower_mesh.size.y * 0.5 + 0.6, 0.0)
		tower.material_override = material
		hub.add_child(tower)


func _build_green_belts() -> void:
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if not city_anchors.has(city_name):
			continue
		var anchor: Vector2 = city_anchors[city_name]
		for index in range(12):
			var angle := TAU * float(index) / 12.0
			var point := anchor + Vector2(cos(angle), sin(angle)) * 245.0
			if not terrain.is_land_position(point.x, point.y):
				continue
			var park := MeshInstance3D.new()
			park.name = city_name.replace(" ", "") + "_GreenBelt_%02d" % index
			var park_mesh := CylinderMesh.new()
			park_mesh.top_radius = 7.0
			park_mesh.bottom_radius = 7.0
			park_mesh.height = 0.24
			park.mesh = park_mesh
			park.position = Vector3(point.x, terrain.get_terrain_height(point.x, point.y) + 0.16, point.y)
			park.material_override = park_material
			add_child(park)


func _build_rural_settlements() -> void:
	for village in VILLAGE_DATA:
		var requested: Vector2 = village["position"]
		var center := _nearest_land_position(requested)
		if center == Vector2.INF:
			continue
		village_anchors[str(village["name"])] = center
		var village_root := Node3D.new()
		village_root.name = "Village_" + str(village["name"]).replace(" ", "")
		village_root.position = Vector3(
			center.x,
			terrain.get_terrain_height(center.x, center.y),
			center.y
		)
		add_child(village_root)
		var ground := MeshInstance3D.new()
		ground.name = "VillageCentralSquare"
		var ground_mesh := CylinderMesh.new()
		ground_mesh.top_radius = 11.0
		ground_mesh.bottom_radius = 11.0
		ground_mesh.height = 0.25
		ground.mesh = ground_mesh
		ground.position.y = 0.14
		ground.material_override = plaza_material
		village_root.add_child(ground)
		for house_index in range(9):
			var angle := TAU * float(house_index) / 9.0
			var offset := Vector2(cos(angle), sin(angle)) * 19.0
			var house_position := center + offset
			if not terrain.is_land_position(house_position.x, house_position.y):
				continue
			var house := MeshInstance3D.new()
			house.name = "VillageHouse_%02d" % house_index
			var house_mesh := BoxMesh.new()
			var width := 6.0 + float(house_index % 3)
			var height := 4.5 + float(house_index % 4) * 1.1
			house_mesh.size = Vector3(width, height, 6.0)
			house.mesh = house_mesh
			house.position = Vector3(
				offset.x,
				terrain.get_terrain_height(house_position.x, house_position.y)
				- village_root.position.y + height * 0.5,
				offset.y
			)
			house.material_override = building_materials[house_index % building_materials.size()]
			village_root.add_child(house)
		var marker := MeshInstance3D.new()
		marker.name = "VillageNoticeTower"
		var tower_mesh := CylinderMesh.new()
		tower_mesh.top_radius = 0.45
		tower_mesh.bottom_radius = 0.8
		tower_mesh.height = 8.0
		marker.mesh = tower_mesh
		marker.position = Vector3(0.0, 4.0, -8.0)
		marker.material_override = rail_material
		village_root.add_child(marker)



func register_map_locations(map_manager: Node, world_id: String) -> void:
	if map_manager == null or not map_manager.has_method("register_location"):
		return
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if not city_anchors.has(city_name):
			continue
		var region_id := "region_" + city_name.to_lower().replace(" ", "_")
		var point := get_city_anchor(city_name)
		map_manager.call(
			"register_location", world_id,
			"city_" + city_name.to_lower().replace(" ", "_"),
			region_id, city_name, 0, point, false
		)
		var airport_position := _nearest_land_position(city_anchors[city_name] + Vector2(205.0, -35.0))
		if airport_position != Vector2.INF:
			map_manager.call(
				"register_location", world_id,
				"airport_" + city_name.to_lower().replace(" ", "_"),
				region_id, city_name + " International Airport", 6,
				Vector3(airport_position.x, terrain.get_terrain_height(airport_position.x, airport_position.y), airport_position.y), true
			)
		var rail_position := _nearest_land_position(city_anchors[city_name] + Vector2(-205.0, 35.0))
		if rail_position != Vector2.INF:
			map_manager.call(
				"register_location", world_id,
				"rail_" + city_name.to_lower().replace(" ", "_"),
				region_id, city_name + " Central Station", 6,
				Vector3(rail_position.x, terrain.get_terrain_height(rail_position.x, rail_position.y), rail_position.y), true
			)
	for village in VILLAGE_DATA:
		var village_name := str(village["name"])
		var village_position := _nearest_land_position(village["position"])
		if village_position == Vector2.INF:
			continue
		var region_id := "region_" + village_name.to_lower().replace(" ", "_")
		map_manager.call(
			"register_location", world_id,
			"village_" + village_name.to_lower().replace(" ", "_"),
			region_id, village_name, 1,
			Vector3(village_position.x, terrain.get_terrain_height(village_position.x, village_position.y), village_position.y), false
		)

	var services_manager := get_node_or_null("ModernCityServicesManager")
	if services_manager != null and services_manager.has_method("get_service_locations"):
		for service_data in services_manager.call("get_service_locations"):
			map_manager.call(
				"register_location", world_id,
				str(service_data["id"]),
				"region_" + str(service_data["city"]).to_lower().replace(" ", "_"),
				str(service_data["name"]), int(service_data.get("location_type", 7)),
				service_data["position"], false
			)

	var transport_manager := get_node_or_null("ModernWorldTransportNetworkManager")
	if transport_manager != null and transport_manager.has_method("get_landmark_locations"):
		for transport_data in transport_manager.call("get_landmark_locations"):
			map_manager.call(
				"register_location", world_id,
				str(transport_data["id"]), "region_transport",
				str(transport_data["name"]), 7,
				transport_data["position"], false
			)

	var tower_manager := get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager != null and tower_manager.has_method("get_tower_positions"):
		for tower_data in tower_manager.call("get_tower_positions"):
			map_manager.call(
				"register_location", world_id,
				str(tower_data["id"]), "region_baghdad",
				str(tower_data["name"]), 5,
				tower_data["position"], false
			)


func discover_starting_city(map_manager: Node, world_id: String) -> void:
	if map_manager == null or not map_manager.has_method("discover_region"):
		return
	var city_name := "Baghdad"
	if not city_anchors.has(city_name):
		return
	var region_id := "region_baghdad"
	map_manager.call("discover_region", world_id, region_id)
	map_manager.call("discover_location", world_id, "city_baghdad")


func get_city_anchor(city_name: String) -> Vector3:
	if not city_anchors.has(city_name):
		return Vector3.INF
	var point: Vector2 = city_anchors[city_name]
	return Vector3(point.x, terrain.get_terrain_height(point.x, point.y), point.y)


func get_city_names() -> Array[String]:
	var result: Array[String] = []
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if city_anchors.has(city_name):
			result.append(city_name)
	return result


func get_village_names() -> Array[String]:
	var result: Array[String] = []
	for village in VILLAGE_DATA:
		var village_name := str(village["name"])
		if village_anchors.has(village_name):
			result.append(village_name)
	return result


func get_village_anchor(village_name: String) -> Vector3:
	if not village_anchors.has(village_name):
		return Vector3.INF
	var point: Vector2 = village_anchors[village_name]
	return Vector3(point.x, terrain.get_terrain_height(point.x, point.y), point.y)


func _create_city_services() -> void:
	var services := ModernCityServicesManagerScript.new()
	services.name = "ModernCityServicesManager"
	add_child(services)


func _create_city_street_furniture() -> void:
	var street_furniture := ModernCityStreetFurnitureManagerScript.new()
	street_furniture.name = "ModernCityStreetFurnitureManager"
	add_child(street_furniture)


func _create_transport_network() -> void:
	var transport := ModernWorldTransportNetworkManagerScript.new()
	transport.name = "ModernWorldTransportNetworkManager"
	add_child(transport)


func _create_city_dealerships() -> void:
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if not city_anchors.has(city_name):
			continue
		var anchor: Vector2 = city_anchors[city_name]
		var position := _nearest_land_position(anchor + Vector2(105.0, 105.0))
		if position == Vector2.INF:
			continue
		var dealer := VehicleDealershipManagerScript.new()
		dealer.name = city_name.replace(" ", "") + "VehicleDealership"
		dealer.position = Vector3(position.x, terrain.get_terrain_height(position.x, position.y), position.y)
		add_child(dealer)
		dealer.setup(null)


func _create_baghdad_towers() -> void:
	var towers := BaghdadTowerLandmarksManagerScript.new()
	towers.name = "BaghdadTowerLandmarksManager"
	add_child(towers)


func _create_city_traffic() -> void:
	var traffic := ModernCityTrafficManagerScript.new()
	traffic.name = "ModernCityTrafficManager"
	add_child(traffic)


func _create_ambient_soundscape() -> void:
	var ambience := ModernWorldAmbienceManagerScript.new()
	ambience.name = "ModernWorldAmbienceManager"
	add_child(ambience)


func _build_city_lighting() -> void:
	var lighting := ModernWorldLightingManagerScript.new()
	lighting.name = "ModernWorldLightingManager"
	add_child(lighting)
