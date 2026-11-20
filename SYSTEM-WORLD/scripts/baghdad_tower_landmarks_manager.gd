extends Node3D
class_name BaghdadTowerLandmarksManager

const EntranceScript = preload("res://scripts/system_tower_entrance.gd")
const HUNTER_TOWER_HEIGHT := 1000.0
const POWER_TOWER_HEIGHT := 168.0

var terrain: Node
var city_anchor := Vector3.ZERO
var tower_material: StandardMaterial3D
var trim_material: StandardMaterial3D
var emissive_material: StandardMaterial3D
var tower_positions: Array[Dictionary] = []

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
	_build_power_tower()
	_build_business_tower()
	_build_shopping_tower()
	_build_entertainment_tower()
	_create_rooftop_city_links()
	_create_connected_city_links()
	_create_public_amenities()

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
	var position := city_anchor + Vector3(355.0, 0.0, 350.0)
	_build_tower(
		"PowerTower",
		"برج القوة",
		"power_tower_baghdad",
		position,
		POWER_TOWER_HEIGHT,
		22.0,
		28,
		Color(0.95, 0.55, 0.16)
	)

func _build_tower(node_name: String, title: String, location_id: String, world_position: Vector3, height: float, radius: float, floors: int, beacon_color: Color) -> void:
	var resolved := _nearest_land_position(Vector2(world_position.x, world_position.z))
	if resolved == Vector2.INF:
		push_warning("SYSTEM WORLD: no suitable land for tower " + title)
		return
	var root := Node3D.new()
	root.name = node_name
	root.position = Vector3(resolved.x, float(terrain.call("get_terrain_height", resolved.x, resolved.y)), resolved.y)
	add_child(root)
	tower_positions.append({"id": location_id, "name": title, "position": root.position, "height": height, "radius": radius})

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
	var foundation_shape := CylinderShape3D.new()
	foundation_shape.radius = radius * 1.48
	foundation_shape.height = 7.0
	foundation_collision.shape = foundation_shape
	foundation_collision.position.y = 3.5
	structure_body.add_child(foundation_collision)
	var shaft_collision := CollisionShape3D.new()
	var shaft_shape := CylinderShape3D.new()
	shaft_shape.radius = radius
	shaft_shape.height = height
	shaft_collision.shape = shaft_shape
	shaft_collision.position.y = height * 0.5 + 7.0
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

	var label := Label3D.new()
	label.name = "TowerNameSign"
	label.text = title
	label.font_size = 44 if floors > 40 else 32
	label.position = Vector3(0.0, 13.0, radius * 1.5)
	label.pixel_size = 0.012
	label.modulate = beacon_color
	root.add_child(label)

	_create_tower_architecture(root, node_name, title, height, radius, floors, beacon_color)
	_create_rooftop_microcity(root, node_name, height, radius, beacon_color)

	root.set_meta("tower_id", location_id)
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


func get_tower_positions() -> Array[Dictionary]:
	return tower_positions.duplicate(true)



func _build_business_tower() -> void:
	_build_tower("BusinessTower", "برج الأعمال", "business_tower_baghdad", city_anchor + Vector3(-350.0, 0.0, 350.0), 220.0, 26.0, 36, Color(0.24, 0.78, 0.72))


func _build_shopping_tower() -> void:
	_build_tower("ShoppingTower", "برج التسوق", "shopping_tower_baghdad", city_anchor + Vector3(-355.0, 0.0, -350.0), 190.0, 30.0, 32, Color(0.95, 0.72, 0.28))


func _build_entertainment_tower() -> void:
	_build_tower("EntertainmentTower", "برج الترفيه", "entertainment_tower_baghdad", city_anchor + Vector3(355.0, 0.0, -350.0), 205.0, 29.0, 34, Color(0.75, 0.38, 0.95))


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


func _create_rooftop_microcity(root: Node3D, tower_id: String, tower_height: float, radius: float, beacon_color: Color) -> void:
	# A supported, explorable rooftop district on every Baghdad landmark tower.
	# The platform is seated directly on the tower crown; it is not a floating island.
	var district := Node3D.new()
	district.name = "RooftopMicroCity_" + tower_id
	district.position = Vector3(0.0, tower_height + 8.0, 0.0)
	root.add_child(district)

	var platform_radius := maxf(radius * 2.05, 58.0)
	var platform := MeshInstance3D.new()
	platform.name = "SupportedRooftopCityPlatform"
	var platform_mesh := CylinderMesh.new()
	platform_mesh.top_radius = platform_radius
	platform_mesh.bottom_radius = platform_radius * 0.94
	platform_mesh.height = 2.4
	platform.mesh = platform_mesh
	platform.material_override = tower_material
	district.add_child(platform)
	_add_static_box_collision(district, "RooftopCityWalkableCollision", Vector3(0.0, 0.7, 0.0), Vector3(platform_radius * 1.2, 1.0, platform_radius * 1.2))

	# Four structural piers visibly transfer the rooftop district load into the tower crown.
	for support_index in range(4):
		var angle := TAU * float(support_index) / 4.0
		var support := MeshInstance3D.new()
		support.name = "RooftopCityStructuralPier_%02d" % support_index
		var support_mesh := BoxMesh.new()
		support_mesh.size = Vector3(4.0, 7.0, 4.0)
		support.mesh = support_mesh
		support.position = Vector3(cos(angle) * radius * 0.82, -4.2, sin(angle) * radius * 0.82)
		support.material_override = trim_material
		district.add_child(support)

	var plaza := MeshInstance3D.new()
	plaza.name = "RooftopCentralPlaza"
	var plaza_mesh := CylinderMesh.new()
	plaza_mesh.top_radius = 13.0
	plaza_mesh.bottom_radius = 13.0
	plaza_mesh.height = 0.28
	plaza.mesh = plaza_mesh
	plaza.position.y = 1.45
	plaza.material_override = trim_material
	district.add_child(plaza)

	var district_specs := [
		{"name": "ResidentialQuarter", "center": Vector3(-platform_radius * 0.43, 0.0, -platform_radius * 0.34), "color": Color(0.30, 0.43, 0.52)},
		{"name": "MarketAndServicesQuarter", "center": Vector3(platform_radius * 0.43, 0.0, -platform_radius * 0.34), "color": Color(0.48, 0.38, 0.25)},
		{"name": "GardenAndLeisureQuarter", "center": Vector3(-platform_radius * 0.43, 0.0, platform_radius * 0.34), "color": Color(0.20, 0.40, 0.27)},
		{"name": "CivicAndCultureQuarter", "center": Vector3(platform_radius * 0.43, 0.0, platform_radius * 0.34), "color": Color(0.39, 0.36, 0.48)}
	]
	for spec in district_specs:
		var quarter := Node3D.new()
		quarter.name = str(spec["name"])
		quarter.position = spec["center"]
		district.add_child(quarter)
		var quarter_material := StandardMaterial3D.new()
		quarter_material.albedo_color = spec["color"]
		quarter_material.roughness = 0.72
		quarter_material.metallic = 0.18
		for building_index in range(3):
			var building := MeshInstance3D.new()
			building.name = "MicroCityBuilding_%02d" % building_index
			var building_mesh := BoxMesh.new()
			var width := 9.0 + float((building_index + 1) % 2) * 3.0
			var building_height := 9.0 + float(building_index) * 5.0
			building_mesh.size = Vector3(width, building_height, 9.0)
			building.mesh = building_mesh
			building.position = Vector3(float(building_index - 1) * 13.0, 1.2 + building_height * 0.5, 0.0)
			building.material_override = quarter_material
			quarter.add_child(building)
			_add_static_box_collision(quarter, "MicroCityBuildingCollision_%02d" % building_index, building.position, building_mesh.size)
		_add_static_box_collision(quarter, "QuarterWalkwayCollision", Vector3.ZERO, Vector3(48.0, 0.45, 30.0))

	var identity := Label3D.new()
	identity.name = "RooftopCitySYSTEMIdentity"
	identity.text = "SYSTEM"
	identity.font_size = 72
	identity.position = Vector3(0.0, 5.0, -platform_radius * 0.72)
	identity.pixel_size = 0.012
	identity.modulate = Color(0.88, 0.70, 0.34)
	district.add_child(identity)
	district.set_meta("tower_id", tower_id)
	district.set_meta("walkable_rooftop_city", true)
	district.set_meta("supported_by_tower", true)
	district.set_meta("districts", PackedStringArray(["ResidentialQuarter", "MarketAndServicesQuarter", "GardenAndLeisureQuarter", "CivicAndCultureQuarter"]))
	print("SYSTEM WORLD: supported rooftop micro-city generated for ", tower_id, " at ", tower_height, "m.")


func _create_rooftop_city_links() -> void:
	# Connect all five rooftop micro-cities at one shared upper-city elevation.
	# Each tower receives a visible vertical access core from its own roof to the sky promenade.
	if tower_positions.size() < 2:
		return
	var upper_city := Node3D.new()
	upper_city.name = "BaghdadUnifiedRooftopCityNetwork"
	add_child(upper_city)
	var highest_tower_height := 0.0
	for tower_data in tower_positions:
		highest_tower_height = maxf(highest_tower_height, float(tower_data["height"]))
	var shared_level := highest_tower_height + 58.0
	for index in range(tower_positions.size()):
		var tower_data: Dictionary = tower_positions[index]
		var tower_position: Vector3 = tower_data["position"]
		var roof_level := tower_position.y + float(tower_data["height"]) + 8.0
		var access_height := shared_level - roof_level
		var radius := float(tower_data["radius"])
		var access_offset := Vector3(radius * 1.35, 0.0, 0.0)
		var access_base := tower_position + Vector3(0.0, roof_level - tower_position.y, 0.0) + access_offset
		var access_top := tower_position + Vector3(0.0, shared_level, 0.0) + access_offset
		var access_core := MeshInstance3D.new()
		access_core.name = "RooftopCityVerticalLiftCore_%02d" % index
		var core_mesh := BoxMesh.new()
		core_mesh.size = Vector3(7.0, maxf(access_height, 8.0), 7.0)
		access_core.mesh = core_mesh
		access_core.position = (access_base + access_top) * 0.5
		access_core.material_override = emissive_material
		upper_city.add_child(access_core)
		var lift_cabin := MeshInstance3D.new()
		lift_cabin.name = "RooftopCityLiftCabin_%02d" % index
		var cabin_mesh := BoxMesh.new()
		cabin_mesh.size = Vector3(5.2, 4.0, 5.2)
		lift_cabin.mesh = cabin_mesh
		lift_cabin.position = access_base + Vector3(0.0, 2.0, 0.0)
		lift_cabin.material_override = trim_material
		upper_city.add_child(lift_cabin)
		var landing := MeshInstance3D.new()
		landing.name = "UpperSkyPromenadeLanding_%02d" % index
		var landing_mesh := BoxMesh.new()
		landing_mesh.size = Vector3(24.0, 1.2, 24.0)
		landing.mesh = landing_mesh
		landing.position = access_top
		landing.material_override = tower_material
		upper_city.add_child(landing)
		_add_static_box_collision(upper_city, "UpperSkyPromenadeLandingCollision_%02d" % index, access_top, landing_mesh.size)
		var next_data: Dictionary = tower_positions[(index + 1) % tower_positions.size()]
		var next_position: Vector3 = next_data["position"] + Vector3(0.0, shared_level, 0.0) + Vector3(float(next_data["radius"]) * 1.35, 0.0, 0.0)
		_create_link_deck(upper_city, access_top, next_position, "UpperCityBridge_%02d" % index, 16.0, 1.4, trim_material)
	upper_city.set_meta("connected_tower_count", tower_positions.size())
	upper_city.set_meta("shared_upper_city_elevation", shared_level)
	upper_city.set_meta("upper_city_network", true)
	print("SYSTEM WORLD: upper rooftop city bridge network created for ", tower_positions.size(), " towers at shared elevation ", shared_level, "m.")


func _create_connected_city_links() -> void:
	# Elevated pedestrian/vehicle corridor blockout linking all five tower podiums.
	if tower_positions.size() < 2:
		return
	var link_root := Node3D.new()
	link_root.name = "FiveTowerConnectedDistrict"
	add_child(link_root)
	for index in range(tower_positions.size()):
		var first: Vector3 = tower_positions[index]["position"]
		var second: Vector3 = tower_positions[(index + 1) % tower_positions.size()]["position"]
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
	# Visual ramp prototype only; drivable vehicle navigation and collision validation remain future work.
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

