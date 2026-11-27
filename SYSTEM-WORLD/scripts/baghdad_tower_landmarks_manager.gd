extends Node3D
class_name BaghdadTowerLandmarksManager

const EntranceScript = preload("res://scripts/system_tower_entrance.gd")
const HeadquartersInteriorScript = preload("res://scripts/system_hunter_headquarters_interior.gd")
const TowerInteriorScript = preload("res://scripts/system_baghdad_tower_interior.gd")
const PowerTowerArenaVenueScript = preload("res://scripts/system_power_tower_arena_venue.gd")
const PowerTowerFloorWorldScript = preload("res://scripts/system_power_tower_floor_world.gd")
const BaghdadVegetationCellBuilderScript = preload("res://scripts/baghdad_vegetation_cell_builder.gd")
const HUNTER_TOWER_HEIGHT := 1000.0
const POWER_TOWER_HEIGHT := 168.0
const TECHNOLOGY_TOWER_HEIGHT := 210.0

var terrain: Node
var city_anchor := Vector3.ZERO
var tower_material: StandardMaterial3D
var trim_material: StandardMaterial3D
var emissive_material: StandardMaterial3D
var tower_positions: Array[Dictionary] = []
var connected_tower_positions: Array[Dictionary] = []
var headquarters_position := Vector3.INF
var vegetation_builder: RefCounted

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
	vegetation_builder = BaghdadVegetationCellBuilderScript.new()
	_build_hunter_tower()
	_build_business_tower()
	_build_shopping_tower()
	_build_entertainment_tower()
	_build_technology_tower()
	_build_power_tower()
	_rebuild_connected_tower_positions()
	_create_connected_city_links()
	_create_hunter_association_headquarters()
	_create_public_amenities()
	_create_reference_sky_district()

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
		false
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

func _rebuild_connected_tower_positions() -> void:
	# Rebuild the district from the five canonical tower IDs after all tower
	# records exist. This guarantees Power Tower can never enter the district.
	connected_tower_positions.clear()
	var district_ids := [
		"hunter_association_tower_baghdad",
		"business_tower_baghdad",
		"shopping_tower_baghdad",
		"entertainment_tower_baghdad",
		"technology_tower_baghdad"
	]
	for required_id in district_ids:
		for tower_data in tower_positions:
			if str(tower_data.get("id", "")) == required_id:
				connected_tower_positions.append(tower_data)
				break


func get_connected_tower_positions() -> Array[Dictionary]:
	return connected_tower_positions.duplicate(true)


func _build_tower(node_name: String, title: String, location_id: String, world_position: Vector3, height: float, radius: float, floors: int, beacon_color: Color, connected_to_district: bool = true) -> void:
	var resolved := _nearest_land_position(Vector2(world_position.x, world_position.z))
	if resolved == Vector2.INF:
		push_warning("SYSTEM WORLD: no suitable land for tower " + title)
		return
	var root := Node3D.new()
	root.name = node_name
	root.position = Vector3(resolved.x, float(terrain.call("get_terrain_height", resolved.x, resolved.y)), resolved.y)
	add_child(root)
	var tower_record := {"id": location_id, "name": title, "position": root.position, "height": height, "radius": radius}
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
	var foundation_shape := CylinderShape3D.new()
	foundation_shape.radius = radius * 1.48
	foundation_shape.height = 7.0
	foundation_collision.shape = foundation_shape
	foundation_collision.position.y = 3.5
	# The five connected towers have a ground-floor lobby; do not seal it inside
	# the monolithic foundation collider. Their lobby supplies its own floor/walls.
	foundation_collision.disabled = connected_to_district
	structure_body.add_child(foundation_collision)
	var shaft_collision := CollisionShape3D.new()
	var shaft_shape := CylinderShape3D.new()
	shaft_shape.radius = radius
	shaft_shape.height = height
	shaft_collision.shape = shaft_shape
	shaft_collision.position.y = height * 0.5 + 7.0
	# Keep the lobby volume clear; the independent Power Tower retains its full collider.
	shaft_collision.disabled = connected_to_district
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

	# The five connected district towers each receive a distinct service lobby.
	# Power Tower is deliberately excluded: it remains an independent challenge venue.
	if connected_to_district:
		var tower_interior := TowerInteriorScript.new()
		tower_interior.name = "TowerInterior"
		root.add_child(tower_interior)
		tower_interior.call("build", location_id, title, EntranceScript, entrance.global_position + Vector3(0.0, 0.0, 5.0))

	var label := Label3D.new()
	label.name = "TowerNameSign"
	label.text = title
	label.font_size = 44 if floors > 40 else 32
	label.position = Vector3(0.0, 13.0, radius * 1.5)
	label.pixel_size = 0.012
	label.modulate = beacon_color
	root.add_child(label)

	_create_tower_architecture(root, node_name, title, height, radius, floors, beacon_color)

	root.set_meta("tower_id", location_id)
	print("SYSTEM WORLD: landmark tower generated: ", title, " / ", floors, " floors / ", height, "m")

func _nearest_land_position(origin: Vector2) -> Vector2:
	if _is_stable_tower_land(origin):
		return origin
	# The central Baghdad basin contains low wetlands. Search farther inland
	# and require a safe elevation so no tower foundation is placed in shallow water.
	for radius_step in range(1, 49):
		var radius := float(radius_step) * 12.0
		for sample in range(48):
			var angle := TAU * float(sample) / 48.0
			var candidate := origin + Vector2(cos(angle), sin(angle)) * radius
			if _is_stable_tower_land(candidate):
				return candidate
	return Vector2.INF


func _is_stable_tower_land(point: Vector2) -> bool:
	if not bool(terrain.call("is_land_position", point.x, point.y)):
		return false
	if terrain.has_method("get_terrain_height"):
		return float(terrain.call("get_terrain_height", point.x, point.y)) > 4.0
	return true


func get_tower_positions() -> Array[Dictionary]:
	return tower_positions.duplicate(true)



func _build_business_tower() -> void:
	_build_tower("BusinessTower", "برج الأعمال", "business_tower_baghdad", city_anchor + Vector3(-350.0, 0.0, 350.0), 220.0, 26.0, 36, Color(0.24, 0.78, 0.72))


func _build_shopping_tower() -> void:
	_build_tower("ShoppingTower", "برج التسوق", "shopping_tower_baghdad", city_anchor + Vector3(-355.0, 0.0, -350.0), 190.0, 30.0, 32, Color(0.95, 0.72, 0.28))


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



func _create_reference_sky_district() -> void:
	# First-pass walkable sky promenade inspired by the approved Baghdad reference.
	# The five towers remain separate landmarks; this ring supplements their existing links.
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
			var planter_vegetation: Dictionary = vegetation_builder.build_planter(
				segment, Vector2(planter_mesh.size.x, planter_mesh.size.z),
				2.28, 20, "baghdad_sky_ring_planter_%d" % index
			)
			planter.set_meta("vegetation_count", int(planter_vegetation.get("total", 0)))
	district.set_meta("reference_visual_blockout", true)
	district.set_meta("walkable_ring_segment_count", segment_count)
	district.set_meta("radial_tower_connectors", connected_tower_positions.size())
	district.set_meta("ring_radius_m", ring_radius)
	district.set_meta("segment_length_m", segment_length)
	district.set_meta("deck_width_m", deck_width)
	district.set_meta("safety_rail_collision", true)
	district.set_meta("final_art_assets_ready", false)
	district.set_meta("note", "Procedural first-pass sky promenade; validate land clearance, navigation, collision and Android performance before final art.")


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
