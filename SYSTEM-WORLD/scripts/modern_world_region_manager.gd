extends Node3D
class_name ModernWorldRegionManager

const ModernCityTrafficManagerScript = preload("res://scripts/modern_city_traffic_manager.gd")
const ModernWorldIncidentManagerScript = preload("res://scripts/modern_world_incident_manager.gd")
const VehicleDealershipManagerScript = preload("res://scripts/system_vehicle_dealership_manager.gd")
const ModernWorldLightingManagerScript = preload("res://scripts/modern_world_lighting_manager.gd")
const ModernWorldCinematicPresentationScript = preload("res://scripts/modern_world_cinematic_presentation.gd")
const ModernWorldAmbienceManagerScript = preload("res://scripts/modern_world_ambience_manager.gd")
const BaghdadTowerLandmarksManagerScript = preload("res://scripts/baghdad_tower_landmarks_manager.gd")
const ModernWorldTransportNetworkManagerScript = preload("res://scripts/modern_world_transport_network_manager.gd")
const ModernCityStreetFurnitureManagerScript = preload("res://scripts/modern_city_street_furniture_manager.gd")
const ModernCityServicesManagerScript = preload("res://scripts/modern_city_services_manager.gd")
const SYSTEMPublicEventBoardScript = preload("res://scripts/system_public_event_board.gd")

## طبقة تفاصيل المدن والمناطق الحضرية للعالم الحديث.
## تُبنى فوق تضاريس القارة الموجودة ولا تستبدلها أو تغيّر مواقعها المرجعية.

## Baghdad is anchored to the provisional WGS84 registry record.
## Other city centers remain clearly marked prototype-layout coordinates until
## licensed regional datasets are imported for each city.
const CITY_DATA := [
	{"name": "New York", "center": Vector2(-650.0, -260.0), "style": 0, "coordinate_source": "prototype_layout"},
	{"name": "London", "center": Vector2(-420.0, -90.0), "style": 1, "coordinate_source": "prototype_layout"},
	{"name": "Paris", "center": Vector2(-300.0, 110.0), "style": 2, "coordinate_source": "prototype_layout"},
	{"name": "Baghdad", "center": Vector2(0.0, 0.0), "style": 3, "geography_city_id": "city_baghdad", "coordinate_source": "WGS84_registry_anchor"},
	{"name": "Moscow", "center": Vector2(120.0, -470.0), "style": 4, "coordinate_source": "prototype_layout"},
	{"name": "Cairo", "center": Vector2(-80.0, 330.0), "style": 5, "coordinate_source": "prototype_layout"},
	{"name": "New Delhi", "center": Vector2(390.0, 230.0), "style": 6, "coordinate_source": "prototype_layout"},
	{"name": "Guangzhou", "center": Vector2(650.0, 40.0), "style": 7, "coordinate_source": "prototype_layout"},
	{"name": "Seoul", "center": Vector2(820.0, -260.0), "style": 8, "coordinate_source": "prototype_layout"},
	{"name": "Tokyo", "center": Vector2(1030.0, 80.0), "style": 9, "coordinate_source": "prototype_layout"},
	{"name": "Singapore", "center": Vector2(560.0, 490.0), "style": 10, "coordinate_source": "prototype_layout"},
	{"name": "Sydney", "center": Vector2(1050.0, 680.0), "style": 11, "coordinate_source": "prototype_layout"},
	{"name": "Rio de Janeiro", "center": Vector2(-850.0, 420.0), "style": 12, "coordinate_source": "prototype_layout"},
	{"name": "Johannesburg", "center": Vector2(-350.0, 610.0), "style": 13, "coordinate_source": "prototype_layout"}
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

var terrain: Variant
var rng := RandomNumberGenerator.new()
var city_anchors: Dictionary = {}
var village_anchors: Dictionary = {}
var road_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var plaza_material: StandardMaterial3D
var building_materials: Array[StandardMaterial3D] = []
var park_material: StandardMaterial3D
var use_baghdad_osm_cells := false


func _ready() -> void:
	name = "ModernWorldRegionManager"
	rng.seed = 20261118
	use_baghdad_osm_cells = FileAccess.file_exists("res://data/geography/baghdad/cell_pack/manifest.json")
	terrain = get_parent().get_node_or_null("ModernContinent")
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
	_create_cinematic_presentation()
	_create_city_dealerships()
	_create_baghdad_towers()
	_create_city_advertising_screens()
	_create_city_traffic()
	_create_city_incidents()
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
		var geography_city_id := str(city.get("geography_city_id", ""))
		if not geography_city_id.is_empty():
			var geography_record := SystemRealWorldGeography.get_city(geography_city_id)
			if geography_record.is_empty():
				push_warning("SYSTEM WORLD: missing geographic registry record for " + str(city["name"]))
				continue
			var projected_position := SystemRealWorldGeography.get_city_world_position(geography_city_id)
			requested = Vector2(projected_position.x, projected_position.z)
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
		_build_city_identity_landmarks(city_root, city_name, int(city.get("style", 0)))
		if city_name == "Baghdad" and use_baghdad_osm_cells:
			continue
		for district_index in range(DISTRICT_OFFSETS.size()):
			var district_center: Vector2 = anchor + DISTRICT_OFFSETS[district_index]
			_build_district(city_root, city_name, district_index, district_center)
			_build_district_street_grid(city_root, city_name, district_index, district_center)



func _build_city_identity_landmarks(parent: Node3D, city_name: String, style: int) -> void:
	var root := Node3D.new()
	root.name = city_name.replace(" ", "") + "_IdentityLandmarks"
	root.position = Vector3(0.0, 0.0, -24.0)
	parent.add_child(root)
	var stone := building_materials[style % building_materials.size()]
	var accent := _material(Color(0.62, 0.72, 0.76), 0.42, 0.42)
	var glow := _material(Color(0.22, 0.72, 0.86), 0.3, 0.12)
	glow.emission_enabled = true
	glow.emission = Color(0.08, 0.42, 0.68)
	glow.emission_energy_multiplier = 1.25
	match style:
		0:
			for index in range(3):
				var x := -18.0 + float(index) * 18.0
				var height := 38.0 + float(index) * 13.0
				_add_identity_box(root, "SkylineTower_%02d" % index, Vector3(x, height * 0.5, 0.0), Vector3(9.0, height, 9.0), stone)
				_add_identity_cylinder(root, "SkylineCrown_%02d" % index, Vector3(x, height + 4.0, 0.0), 3.0, 1.0, 8.0, accent)
			_add_identity_cylinder(root, "SkylineBeacon", Vector3(0.0, 68.0, 0.0), 0.6, 0.1, 20.0, glow)
		1:
			_add_identity_box(root, "CivicClockTower", Vector3(0.0, 17.0, 0.0), Vector3(9.0, 34.0, 9.0), stone)
			_add_identity_cylinder(root, "ClockFace", Vector3(0.0, 25.0, -4.8), 2.5, 2.5, 0.35, accent)
			_add_identity_cylinder(root, "ClockSpire", Vector3(0.0, 38.0, 0.0), 2.2, 0.0, 9.0, glow)
			_add_identity_box(root, "CivicBridgeTower", Vector3(22.0, 12.0, 2.0), Vector3(7.0, 24.0, 7.0), accent)
		2:
			_add_identity_cylinder(root, "ObservationTowerShaft", Vector3(0.0, 19.0, 0.0), 3.2, 1.2, 38.0, stone)
			_add_identity_cylinder(root, "ObservationDeckLower", Vector3(0.0, 25.0, 0.0), 7.0, 7.0, 2.0, accent)
			_add_identity_cylinder(root, "ObservationDeckUpper", Vector3(0.0, 34.0, 0.0), 5.0, 5.0, 2.0, accent)
			_add_identity_cylinder(root, "ObservationBeacon", Vector3(0.0, 43.0, 0.0), 0.8, 0.0, 16.0, glow)
		3:
			_add_identity_cylinder(root, "RiverfrontCivicHall", Vector3(0.0, 7.0, 0.0), 12.0, 10.0, 14.0, stone)
			_add_identity_cylinder(root, "CivicDome", Vector3(0.0, 16.0, 0.0), 7.0, 0.8, 7.0, accent)
			for side in [-1.0, 1.0]:
				_add_identity_cylinder(root, "RiverfrontMinaret_%s" % str(side), Vector3(side * 17.0, 12.0, 0.0), 1.8, 0.8, 24.0, glow)
			_add_identity_box(root, "RiverTerrace", Vector3(0.0, 0.5, 15.0), Vector3(46.0, 1.0, 8.0), accent)
		4:
			_add_identity_box(root, "CivicSpireBase", Vector3(0.0, 15.0, 0.0), Vector3(12.0, 30.0, 12.0), stone)
			_add_identity_cylinder(root, "CivicSpireDome", Vector3(0.0, 33.0, 0.0), 5.0, 0.4, 7.0, glow)
			for index in range(4):
				var angle := TAU * float(index) / 4.0
				var point := Vector3(cos(angle) * 17.0, 8.0, sin(angle) * 17.0)
				_add_identity_cylinder(root, "HeritageDome_%02d" % index, point, 3.8, 1.0, 8.0, accent)
		5:
			for index in range(3):
				var x := -18.0 + float(index) * 18.0
				_add_identity_cylinder(root, "DesertPyramid_%02d" % index, Vector3(x, 7.0, 0.0), 8.0, 0.0, 14.0, stone)
			_add_identity_box(root, "MuseumAxis", Vector3(0.0, 1.0, 17.0), Vector3(42.0, 2.0, 5.0), accent)
		6:
			_add_identity_box(root, "CeremonialGatewayLeft", Vector3(-8.0, 10.0, 0.0), Vector3(4.0, 20.0, 5.0), stone)
			_add_identity_box(root, "CeremonialGatewayRight", Vector3(8.0, 10.0, 0.0), Vector3(4.0, 20.0, 5.0), stone)
			_add_identity_box(root, "CeremonialGatewayLintel", Vector3(0.0, 20.0, 0.0), Vector3(22.0, 4.0, 7.0), accent)
			_add_identity_cylinder(root, "GatewayBeacon", Vector3(0.0, 26.0, 0.0), 1.2, 0.0, 8.0, glow)
		7:
			for side in [-1.0, 1.0]:
				_add_identity_box(root, "TwinSkyTower_%s" % str(side), Vector3(side * 12.0, 27.0, 0.0), Vector3(8.0, 54.0, 8.0), stone)
			_add_identity_box(root, "SkyBridge", Vector3(0.0, 38.0, 0.0), Vector3(32.0, 3.0, 8.0), glow)
		8:
			_add_identity_box(root, "DigitalCultureTower", Vector3(0.0, 25.0, 0.0), Vector3(12.0, 50.0, 12.0), stone)
			for level in range(5):
				_add_identity_box(root, "DigitalLightBand_%02d" % level, Vector3(0.0, 8.0 + float(level) * 8.0, -6.2), Vector3(13.0, 0.65, 0.3), glow)
		9:
			_add_identity_box(root, "CulturalGateLeft", Vector3(-9.0, 8.0, 0.0), Vector3(2.0, 16.0, 2.0), accent)
			_add_identity_box(root, "CulturalGateRight", Vector3(9.0, 8.0, 0.0), Vector3(2.0, 16.0, 2.0), accent)
			_add_identity_box(root, "CulturalGateBeam", Vector3(0.0, 16.0, 0.0), Vector3(24.0, 2.0, 3.0), glow)
			_add_identity_box(root, "PagodaRoof", Vector3(0.0, 20.0, 0.0), Vector3(19.0, 1.0, 12.0), stone)
		10:
			for index in range(3):
				var x := -16.0 + float(index) * 16.0
				_add_identity_cylinder(root, "GardenDome_%02d" % index, Vector3(x, 7.0, 0.0), 8.0, 8.0, 14.0, glow)
			_add_identity_box(root, "GardenCanopyWalk", Vector3(0.0, 2.0, 16.0), Vector3(48.0, 1.0, 5.0), accent)
		11:
			for index in range(3):
				var sail := Node3D.new()
				sail.name = "HarborSailRoof_%02d" % index
				sail.position = Vector3(-14.0 + float(index) * 14.0, 9.0 + float(index % 2) * 4.0, 0.0)
				sail.rotation.z = -0.42 if index % 2 == 0 else 0.42
				root.add_child(sail)
				_add_identity_box(sail, "SailSurface", Vector3.ZERO, Vector3(12.0, 0.8, 8.0), accent)
		12:
			_add_identity_cylinder(root, "CoastalLookoutBase", Vector3(0.0, 8.0, 0.0), 12.0, 9.0, 16.0, stone)
			_add_identity_cylinder(root, "CoastalLookoutDeck", Vector3(0.0, 17.0, 0.0), 16.0, 16.0, 2.0, accent)
			_add_identity_cylinder(root, "CoastalLookoutBeacon", Vector3(0.0, 25.0, 0.0), 2.0, 0.5, 14.0, glow)
		13:
			_add_identity_box(root, "MiningHeritageFrame", Vector3(0.0, 14.0, 0.0), Vector3(18.0, 28.0, 3.0), stone)
			_add_identity_box(root, "MiningCrossbeam", Vector3(0.0, 26.0, 0.0), Vector3(28.0, 2.0, 3.0), accent)
			_add_identity_cylinder(root, "GoldDiscoveryBeacon", Vector3(0.0, 32.0, 0.0), 1.0, 0.2, 10.0, glow)


func _add_identity_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _add_identity_cylinder(parent: Node3D, node_name: String, position: Vector3, bottom_radius: float, top_radius: float, height: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.height = height
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

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
			var ground_y: float = float(terrain.get_terrain_height(world_x, world_z))
			var district_base: float = float(terrain.get_terrain_height(center.x, center.y))
			if absf(ground_y - district_base) > 13.0:
				continue
			var seed_value := absf(sin(float(district_index * 83 + x_index * 29 + z_index * 47 + city_name.length() * 11)))
			var width := 9.0 + seed_value * 8.0
			var depth := 9.0 + absf(cos(seed_value * 9.0)) * 8.0
			var height := _building_height(district_index, seed_value)
			var local_x := world_x - center.x
			var local_z := world_z - center.y
			var local_y: float = ground_y - district_base + height * 0.5
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



func _build_district_street_grid(parent: Node3D, city_name: String, district_index: int, center: Vector2) -> void:
	var road_surface := SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sidewalk_surface := SurfaceTool.new()
	sidewalk_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var crossing_surface := SurfaceTool.new()
	crossing_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var street_offsets: Array[float] = [-51.0, -17.0, 17.0, 51.0]
	for offset in street_offsets:
		_append_district_street(road_surface, sidewalk_surface, center, Vector2(-68.0, offset), Vector2(68.0, offset), parent.position)
		_append_district_street(road_surface, sidewalk_surface, center, Vector2(offset, -68.0), Vector2(offset, 68.0), parent.position)
		for crossing_offset in street_offsets:
			_append_crosswalk(crossing_surface, center, Vector2(offset, crossing_offset), true, parent.position)
			_append_crosswalk(crossing_surface, center, Vector2(crossing_offset, offset), false, parent.position)
	road_surface.generate_normals()
	sidewalk_surface.generate_normals()
	crossing_surface.generate_normals()
	var road_mesh := _commit_surface_tool_if_valid(road_surface)
	if road_mesh != null and road_mesh.get_rid().is_valid():
		var road_instance := MeshInstance3D.new()
		road_instance.name = city_name.replace(" ", "") + "_DistrictRoadGrid_%02d" % district_index
		road_instance.mesh = road_mesh
		road_instance.material_override = road_material
		road_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(road_instance)
	var sidewalk_mesh := _commit_surface_tool_if_valid(sidewalk_surface)
	if sidewalk_mesh != null and sidewalk_mesh.get_rid().is_valid():
		var sidewalk_instance := MeshInstance3D.new()
		sidewalk_instance.name = city_name.replace(" ", "") + "_DistrictSidewalks_%02d" % district_index
		sidewalk_instance.mesh = sidewalk_mesh
		sidewalk_instance.material_override = plaza_material
		sidewalk_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(sidewalk_instance)
	var crossing_mesh := _commit_surface_tool_if_valid(crossing_surface)
	if crossing_mesh != null and crossing_mesh.get_rid().is_valid():
		var crossing_material := _material(Color(0.82, 0.84, 0.82), 0.9)
		var crossing_instance := MeshInstance3D.new()
		crossing_instance.name = city_name.replace(" ", "") + "_Crosswalks_%02d" % district_index
		crossing_instance.mesh = crossing_mesh
		crossing_instance.material_override = crossing_material
		crossing_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(crossing_instance)


func _append_district_street(roads: SurfaceTool, sidewalks: SurfaceTool, center: Vector2, start: Vector2, finish: Vector2, parent_position: Vector3) -> void:
	var direction := (finish - start).normalized()
	var side := Vector2(-direction.y, direction.x)
	var steps := 16
	for step in range(steps):
		var p0 := start.lerp(finish, float(step) / float(steps))
		var p1 := start.lerp(finish, float(step + 1) / float(steps))
		var middle := center + (p0 + p1) * 0.5
		if not terrain.is_land_position(middle.x, middle.y):
			continue
		var road_left := _district_local_point(center + p0 + side * 3.5, parent_position, 0.22)
		var road_right := _district_local_point(center + p0 - side * 3.5, parent_position, 0.22)
		var road_far_left := _district_local_point(center + p1 + side * 3.5, parent_position, 0.22)
		var road_far_right := _district_local_point(center + p1 - side * 3.5, parent_position, 0.22)
		_add_quad(roads, road_left, road_right, road_far_left, road_far_right)
		for side_sign in [-1.0, 1.0]:
			var sidewalk_inner_0: Vector2 = center + p0 + side * (side_sign * 3.5)
			var sidewalk_outer_0: Vector2 = center + p0 + side * (side_sign * 5.8)
			var sidewalk_inner_1: Vector2 = center + p1 + side * (side_sign * 3.5)
			var sidewalk_outer_1: Vector2 = center + p1 + side * (side_sign * 5.8)
			var a := _district_local_point(sidewalk_inner_0, parent_position, 0.27)
			var b := _district_local_point(sidewalk_outer_0, parent_position, 0.27)
			var c := _district_local_point(sidewalk_inner_1, parent_position, 0.27)
			var d := _district_local_point(sidewalk_outer_1, parent_position, 0.27)
			_add_quad(sidewalks, a, b, c, d)


func _append_crosswalk(surface: SurfaceTool, center: Vector2, offset: Vector2, horizontal: bool, parent_position: Vector3) -> void:
	var stripe_count := 5
	for stripe in range(stripe_count):
		var along := -2.4 + float(stripe) * 1.2
		var point := center + offset
		var half_width := 2.6
		var half_length := 0.28
		var a2: Vector2
		var b2: Vector2
		var c2: Vector2
		var d2: Vector2
		if horizontal:
			a2 = point + Vector2(along - half_length, -half_width)
			b2 = point + Vector2(along - half_length, half_width)
			c2 = point + Vector2(along + half_length, -half_width)
			d2 = point + Vector2(along + half_length, half_width)
		else:
			a2 = point + Vector2(-half_width, along - half_length)
			b2 = point + Vector2(half_width, along - half_length)
			c2 = point + Vector2(-half_width, along + half_length)
			d2 = point + Vector2(half_width, along + half_length)
		if not terrain.is_land_position(point.x, point.y):
			return
		_add_quad(
			surface,
			_district_local_point(a2, parent_position, 0.3),
			_district_local_point(b2, parent_position, 0.3),
			_district_local_point(c2, parent_position, 0.3),
			_district_local_point(d2, parent_position, 0.3)
		)


func _district_local_point(world_point: Vector2, parent_position: Vector3, lift: float) -> Vector3:
	return Vector3(
		world_point.x - parent_position.x,
		terrain.get_terrain_height(world_point.x, world_point.y) + lift - parent_position.y,
		world_point.y - parent_position.z
	)

func _build_city_roads() -> void:
	for city in CITY_DATA:
		var city_name := str(city["name"])
		if not city_anchors.has(city_name):
			continue
		if city_name == "Baghdad" and use_baghdad_osm_cells:
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
	var mesh := _commit_surface_tool_if_valid(surface)
	if mesh == null or not mesh.get_rid().is_valid():
		return
	var road := MeshInstance3D.new()
	road.name = node_name
	road.mesh = mesh
	road.material_override = road_material
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road)


func _commit_surface_tool_if_valid(surface: SurfaceTool) -> ArrayMesh:
	# Never attach an ArrayMesh created from an empty SurfaceTool. A zero-surface
	# mesh can still expose a RID in the dummy renderer and trigger repeated
	# mesh_get_surface_count null-parameter errors during headless scene tests.
	var arrays: Array = surface.commit_to_arrays()
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return null
	var raw_vertices: Variant = arrays[Mesh.ARRAY_VERTEX]
	if typeof(raw_vertices) != TYPE_PACKED_VECTOR3_ARRAY:
		return null
	var vertices: PackedVector3Array = raw_vertices
	if vertices.size() < 3:
		return null
	var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
	if raw_indices is PackedInt32Array:
		var indices: PackedInt32Array = raw_indices
		if not indices.is_empty() and indices.size() < 3:
			return null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if not mesh.get_rid().is_valid():
		return null
	return mesh


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
	var transport: Node3D = ModernWorldTransportNetworkManagerScript.new()
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


func _create_cinematic_presentation() -> void:
	var presentation := ModernWorldCinematicPresentationScript.new()
	presentation.name = "ModernWorldCinematicPresentation"
	add_child(presentation)


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


## Stable overview data for the large external-style world map.
## The map displays the whole fictional continent while discovery markers remain separate.
func get_map_overview() -> Dictionary:
	var cities: Array[Dictionary] = []
	var villages: Array[Dictionary] = []
	for city_name in get_city_names():
		cities.append({"name": city_name, "position": get_city_anchor(city_name)})
	for village_name in get_village_names():
		villages.append({"name": village_name, "position": get_village_anchor(village_name)})
	var incidents: Array[Dictionary] = []
	var incident_manager := get_node_or_null("ModernWorldIncidentManager")
	if incident_manager != null and incident_manager.has_method("get_active_incidents"):
		incidents = incident_manager.call("get_active_incidents")
	return {"cities": cities, "villages": villages, "incidents": incidents}


func _create_city_incidents() -> void:
	var incidents := ModernWorldIncidentManagerScript.new()
	incidents.name = "ModernWorldIncidentManager"
	add_child(incidents)

func _create_city_advertising_screens() -> void:
	var public_board := SYSTEMPublicEventBoardScript.new()
	public_board.name = "SYSTEMPublicEventBoard"
	add_child(public_board)
	public_board.setup(city_anchors, terrain)
