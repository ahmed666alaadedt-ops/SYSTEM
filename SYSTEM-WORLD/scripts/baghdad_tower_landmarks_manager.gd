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
	# Canonical Baghdad five-tower district. Power Tower is a separate landmark.
	_build_hunter_tower()
	_build_business_tower()
	_build_shopping_tower()
	_build_entertainment_tower()
	_build_technology_tower()
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

	_create_tower_podium(root, node_name, radius, beacon_color)
	_create_tower_architecture(root, node_name, title, height, radius, floors, beacon_color)
	_create_tower_identity_features(root, node_name, height, radius, beacon_color)
	_create_tower_vertical_transport_blockout(root, height, radius, floors, beacon_color)
	_create_tower_sky_garden_terraces(root, height, radius, beacon_color)
	_create_tower_facility_blockout(root, node_name, radius)

	root.set_meta("tower_id", location_id)
	root.set_meta("transport_blockout_revision", 1)
	root.set_meta("facility_blockout_revision", 2)
	root.set_meta("sky_garden_revision", 1)
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


func _build_technology_tower() -> void:
	_build_tower(
		"TechnologyInnovationTower",
		"برج التكنولوجيا والابتكار",
		"technology_innovation_tower_baghdad",
		city_anchor + Vector3(355.0, 0.0, 350.0),
		235.0,
		28.0,
		40,
		Color(0.22, 0.88, 0.82)
	)


func _create_tower_identity_features(root: Node3D, node_name: String, height: float, radius: float, beacon_color: Color) -> void:
	# Distinctive skyline signatures for the five approved Baghdad towers.
	match node_name:
		"HunterAssociationTower":
			for side in [-1.0, 1.0]:
				var wing := MeshInstance3D.new()
				wing.name = "HunterGuildMonumentalWing_%s" % str(side)
				var wing_mesh := BoxMesh.new()
				wing_mesh.size = Vector3(9.0, height * 0.42, 18.0)
				wing.mesh = wing_mesh
				wing.position = Vector3(side * radius * 0.92, height * 0.48 + 7.0, 0.0)
				wing.material_override = trim_material
				root.add_child(wing)
			var honor := Label3D.new()
			honor.name = "HallOfHonorSkySign"
			honor.text = "HUNTER GUILD • HALL OF HONOR"
			honor.font_size = 30
			honor.position = Vector3(0.0, height * 0.78, radius * 0.9)
			honor.modulate = beacon_color
			root.add_child(honor)
		"BusinessTower":
			for level in range(5):
				var belt := MeshInstance3D.new()
				belt.name = "BusinessSkyOfficeBelt_%02d" % level
				var belt_mesh := CylinderMesh.new()
				belt_mesh.top_radius = radius * (0.92 - float(level) * 0.035)
				belt_mesh.bottom_radius = radius * (0.92 - float(level) * 0.035)
				belt_mesh.height = 2.2
				belt.mesh = belt_mesh
				belt.position.y = height * (0.18 + float(level) * 0.14) + 7.0
				belt.material_override = trim_material
				root.add_child(belt)
		"ShoppingTower":
			for side in range(4):
				var arcade := MeshInstance3D.new()
				arcade.name = "ShoppingArcadePortal_%d" % side
				var arcade_mesh := BoxMesh.new()
				arcade_mesh.size = Vector3(radius * 0.72, 12.0, 2.0)
				arcade.mesh = arcade_mesh
				var angle := TAU * float(side) / 4.0
				arcade.position = Vector3(cos(angle) * radius * 1.12, 9.0, sin(angle) * radius * 1.12)
				arcade.rotation.y = angle
				arcade.material_override = trim_material
				root.add_child(arcade)
		"EntertainmentTower":
			for ring_index in range(3):
				var event_ring := MeshInstance3D.new()
				event_ring.name = "EntertainmentEventRing_%d" % ring_index
				var ring_mesh := CylinderMesh.new()
				ring_mesh.top_radius = radius * (1.28 + float(ring_index) * 0.12)
				ring_mesh.bottom_radius = ring_mesh.top_radius
				ring_mesh.height = 1.8
				event_ring.mesh = ring_mesh
				event_ring.position.y = height * (0.28 + float(ring_index) * 0.2) + 7.0
				event_ring.material_override = emissive_material
				root.add_child(event_ring)
		"TechnologyInnovationTower":
			var data_spire := MeshInstance3D.new()
			data_spire.name = "TechnologyCentralDataSpire"
			var spire_mesh := CylinderMesh.new()
			spire_mesh.top_radius = 1.2
			spire_mesh.bottom_radius = 4.5
			spire_mesh.height = height * 0.28
			data_spire.mesh = spire_mesh
			data_spire.position.y = height * 0.82 + 7.0
			data_spire.material_override = emissive_material
			root.add_child(data_spire)
			for side in range(8):
				var node := MeshInstance3D.new()
				node.name = "InnovationNode_%02d" % side
				var node_mesh := SphereMesh.new()
				node_mesh.radius = 2.0
				node_mesh.height = 4.0
				node.mesh = node_mesh
				var angle := TAU * float(side) / 8.0
				node.position = Vector3(cos(angle) * radius * 1.45, height * 0.58 + 7.0, sin(angle) * radius * 1.45)
				node.material_override = emissive_material
				root.add_child(node)


func _create_connected_city_links() -> void:
	# Elevated pedestrian/vehicle corridor blockout linking all five tower podiums.
	if tower_positions.size() < 2:
		return
	var link_root := Node3D.new()
	link_root.name = "FiveTowerConnectedDistrict"
	add_child(link_root)
	var central_hub := city_anchor + Vector3(0.0, 52.0, 0.0)
	for index in range(tower_positions.size()):
		var tower_position: Vector3 = tower_positions[index]["position"]
		_create_link_deck(link_root, central_hub, tower_position + Vector3(0.0, 52.0, 0.0), "CentralSYSTEMRadialSkybridge_%d" % index, 22.0, 1.2, trim_material)
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
	_create_central_system_spire(amenities)
	_create_shared_sky_terraces(amenities)
	_create_multilevel_parking_blockout(amenities)
	_create_vertical_access_blockout(amenities)



func _create_tower_vertical_transport_blockout(root: Node3D, height: float, radius: float, floors: int, accent: Color) -> void:
	# Visual-only lift banks and protected stair cores. Movement, floor selection,
	# access control and emergency routing are deliberately not implied here.
	var transport := Node3D.new()
	transport.name = "VerticalTransport_Blockout"
	root.add_child(transport)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.12, 0.58, 0.76, 0.32)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.52
	glass.roughness = 0.18
	var cabin_material := _make_surface_material(accent, 0.35, 0.24)
	var lift_positions := [
		Vector3(radius * 0.34, 0.0, radius * 0.34),
		Vector3(-radius * 0.34, 0.0, radius * 0.34),
		Vector3(radius * 0.34, 0.0, -radius * 0.34),
		Vector3(-radius * 0.34, 0.0, -radius * 0.34)
	]
	for index in range(lift_positions.size()):
		var lift := MeshInstance3D.new()
		lift.name = "PanoramicLiftShaft_%02d" % index
		var shaft_mesh := BoxMesh.new()
		shaft_mesh.size = Vector3(3.8, height * 0.88, 3.8)
		lift.mesh = shaft_mesh
		lift.position = lift_positions[index] + Vector3(0.0, height * 0.44 + 7.0, 0.0)
		lift.material_override = glass
		transport.add_child(lift)
		var cabin := MeshInstance3D.new()
		cabin.name = "LiftCabinVisual_%02d" % index
		var cabin_mesh := BoxMesh.new()
		cabin_mesh.size = Vector3(3.1, 3.2, 3.1)
		cabin.mesh = cabin_mesh
		cabin.position = lift_positions[index] + Vector3(0.0, 8.6, 0.0)
		cabin.material_override = cabin_material
		transport.add_child(cabin)
	for side in range(2):
		var stair_core := MeshInstance3D.new()
		stair_core.name = "ProtectedStairCore_%02d" % side
		var core_mesh := BoxMesh.new()
		core_mesh.size = Vector3(5.0, height * 0.88, 5.0)
		stair_core.mesh = core_mesh
		stair_core.position = Vector3(0.0, height * 0.44 + 7.0, radius * (0.78 if side == 0 else -0.78))
		stair_core.material_override = tower_material
		transport.add_child(stair_core)
	var directory := Node3D.new()
	directory.name = "FloorDirectoryMarkers"
	transport.add_child(directory)
	var marker_step := 10 if floors >= 40 else 5
	for floor_number in range(1, floors + 1, marker_step):
		var marker := Label3D.new()
		marker.name = "FloorMarker_%03d" % floor_number
		marker.text = "FLOOR %03d" % floor_number
		marker.font_size = 12
		marker.pixel_size = 0.018
		marker.position = Vector3(radius * 1.12, 9.0 + (height - 16.0) * float(floor_number - 1) / float(maxi(floors - 1, 1)), 0.0)
		marker.modulate = accent
		directory.add_child(marker)
	transport.set_meta("lift_count_visual", lift_positions.size())
	transport.set_meta("protected_stair_cores_visual", 2)
	transport.set_meta("floor_directory_interval", marker_step)
	transport.set_meta("interactive", false)


func _create_tower_sky_garden_terraces(root: Node3D, height: float, radius: float, accent: Color) -> void:
	# Signature elevated gardens echo the approved Baghdad skyline reference.
	var gardens := Node3D.new()
	gardens.name = "SkyGardenTerraces"
	root.add_child(gardens)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.10, 0.48, 0.62, 0.46)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.42
	glass.roughness = 0.2
	var planting := _make_surface_material(Color(0.12, 0.30, 0.19), 0.08, 0.82)
	var accent_material := _make_surface_material(accent, 0.28, 0.3)
	var levels := [0.24, 0.52, 0.78]
	for index in range(levels.size()):
		var terrace_y := 9.0 + height * float(levels[index])
		var terrace_radius := radius * (2.0 if index == 0 else (1.62 if index == 1 else 1.34))
		var deck := MeshInstance3D.new()
		deck.name = "ElevatedGardenDeck_%02d" % index
		var deck_mesh := CylinderMesh.new()
		deck_mesh.top_radius = terrace_radius
		deck_mesh.bottom_radius = terrace_radius * 1.04
		deck_mesh.height = 2.4
		deck.mesh = deck_mesh
		deck.position.y = terrace_y
		deck.material_override = tower_material
		gardens.add_child(deck)
		var deck_body := StaticBody3D.new()
		deck_body.name = deck.name + "_Collision"
		deck_body.position.y = terrace_y
		var deck_collision := CollisionShape3D.new()
		var deck_shape := CylinderShape3D.new()
		deck_shape.radius = terrace_radius
		deck_shape.height = 2.4
		deck_collision.shape = deck_shape
		deck_body.add_child(deck_collision)
		gardens.add_child(deck_body)
		var ring := MeshInstance3D.new()
		ring.name = "GardenGlassRailing_%02d" % index
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = terrace_radius * 0.965
		ring_mesh.outer_radius = terrace_radius
		ring.mesh = ring_mesh
		ring.position.y = terrace_y + 2.1
		ring.material_override = glass
		gardens.add_child(ring)
		for planter_index in range(12):
			var angle := TAU * float(planter_index) / 12.0
			var planter := MeshInstance3D.new()
			planter.name = "GardenPlanter_%02d_%02d" % [index, planter_index]
			var planter_mesh := BoxMesh.new()
			planter_mesh.size = Vector3(5.0, 1.2, 3.2)
			planter.mesh = planter_mesh
			planter.position = Vector3(cos(angle) * terrace_radius * 0.78, terrace_y + 1.7, sin(angle) * terrace_radius * 0.78)
			planter.rotation.y = -angle
			planter.material_override = planting
			gardens.add_child(planter)
		var sign := Label3D.new()
		sign.name = "SkyGardenLevelSign_%02d" % index
		sign.text = "SYSTEM SKY GARDEN • %02d" % (index + 1)
		sign.font_size = 18
		sign.position = Vector3(0.0, terrace_y + 4.0, terrace_radius * 0.72)
		sign.modulate = accent
		gardens.add_child(sign)
	gardens.set_meta("terrace_count", levels.size())
	gardens.set_meta("walkable_collision_present", true)
	gardens.set_meta("interactive_amenities", false)


func _create_tower_podium(root: Node3D, node_name: String, radius: float, accent: Color) -> void:
	var podium := Node3D.new()
	podium.name = "PublicPodiumAndArrivalHall"
	root.add_child(podium)
	var glass := _make_surface_material(Color(0.035, 0.22, 0.30, 0.82), 0.18, 0.68)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var accent_material := _make_surface_material(accent, 0.24, 0.62)
	for level in range(3):
		var y := 8.0 + float(level) * 5.0
		var deck := MeshInstance3D.new()
		deck.name = "PodiumPublicFloor_%02d" % (level + 1)
		var deck_mesh := CylinderMesh.new()
		deck_mesh.top_radius = radius * (1.42 - float(level) * 0.08)
		deck_mesh.bottom_radius = radius * (1.42 - float(level) * 0.08)
		deck_mesh.height = 0.8
		deck.mesh = deck_mesh
		deck.position.y = y
		deck.material_override = trim_material
		podium.add_child(deck)
		var body := StaticBody3D.new()
		body.name = deck.name + "_Collision"
		body.position.y = y
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = deck_mesh.top_radius
		shape.height = deck_mesh.height
		collision.shape = shape
		body.add_child(collision)
		podium.add_child(body)
		for pillar_index in range(12):
			var angle := TAU * float(pillar_index) / 12.0
			var pillar := MeshInstance3D.new()
			pillar.name = "PodiumGlassPillar_%02d_%02d" % [level, pillar_index]
			var pillar_mesh := BoxMesh.new()
			pillar_mesh.size = Vector3(1.2, 4.6, 1.2)
			pillar.mesh = pillar_mesh
			pillar.position = Vector3(cos(angle) * deck_mesh.top_radius * 0.91, y + 2.7, sin(angle) * deck_mesh.top_radius * 0.91)
			pillar.material_override = glass
			podium.add_child(pillar)
		var ring := MeshInstance3D.new()
		ring.name = "PodiumAccentRing_%02d" % level
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = deck_mesh.top_radius * 0.88
		ring_mesh.outer_radius = deck_mesh.top_radius * 0.92
		ring.mesh = ring_mesh
		ring.position.y = y + 2.5
		ring.material_override = accent_material
		podium.add_child(ring)
	var arrival := Label3D.new()
	arrival.name = "PublicArrivalHallSign"
	arrival.text = "SYSTEM • " + node_name.replace("Tower", " TOWER")
	arrival.font_size = 30
	arrival.position = Vector3(0.0, 15.0, radius * 1.5)
	arrival.modulate = accent
	podium.add_child(arrival)
	podium.set_meta("public_levels", 3)
	podium.set_meta("arrival_hall_status", "visual_blockout")


func _create_tower_facility_blockout(root: Node3D, node_name: String, radius: float) -> void:
	# Facility shells and interior layout markers are a readable 3D blockout.
	# They are deliberately tagged non-interactive until dedicated scenes are connected.
	var facility_root := Node3D.new()
	facility_root.name = "TowerFacilities_Blockout"
	facility_root.position = Vector3(0.0, 10.0, 0.0)
	root.add_child(facility_root)
	var glass := _make_surface_material(Color(0.08, 0.28, 0.38), 0.2, 0.72)
	var interior := _make_surface_material(Color(0.16, 0.19, 0.23), 0.42, 0.28)
	var screen := _make_surface_material(Color(0.025, 0.16, 0.24), 0.18, 0.3)
	screen.emission_enabled = true
	screen.emission = Color(0.02, 0.3, 0.52)
	screen.emission_energy_multiplier = 1.4
	var facility_ids := PackedStringArray()
	match node_name:
		"HunterAssociationTower":
			facility_ids = PackedStringArray(["hunter_registration", "mission_hall", "guild_services", "hunter_training", "medical_clinic", "hall_of_honor", "examination_admin", "hunter_restaurant"])
			_add_facility_block(facility_root, "HunterRegistrationHall", Vector3(-10.0, 5.0, 0.0), Vector3(18.0, 8.0, 16.0), glass, "HUNTER REGISTRATION")
			_add_facility_block(facility_root, "MissionHall", Vector3(12.0, 5.0, 0.0), Vector3(18.0, 8.0, 16.0), interior, "MISSION HALL")
			_add_facility_block(facility_root, "HallOfHonorGallery", Vector3(0.0, 5.0, -19.0), Vector3(34.0, 8.0, 10.0), screen, "HALL OF HONOR")
			_add_facility_block(facility_root, "HunterMedicalClinic", Vector3(0.0, 5.0, 19.0), Vector3(20.0, 8.0, 10.0), glass, "HUNTER CLINIC")
		"BusinessTower":
			facility_ids = PackedStringArray(["company_headquarters", "investment_exchange", "conference_center", "business_hotel", "banking_services", "coworking_hub", "business_restaurants"])
			_add_facility_block(facility_root, "CorporateHeadquarters", Vector3(-12.0, 5.0, 0.0), Vector3(18.0, 9.0, 18.0), glass, "CORPORATE HQ")
			_add_facility_block(facility_root, "InvestmentExchange", Vector3(12.0, 5.0, 0.0), Vector3(18.0, 9.0, 18.0), screen, "INVESTMENT EXCHANGE")
			_add_facility_block(facility_root, "ConferenceCenter", Vector3(0.0, 5.0, -20.0), Vector3(34.0, 9.0, 12.0), interior, "CONFERENCE CENTER")
			_add_facility_block(facility_root, "BusinessHotel", Vector3(0.0, 5.0, 20.0), Vector3(34.0, 9.0, 12.0), glass, "BUSINESS HOTEL")
		"ShoppingTower":
			facility_ids = PackedStringArray(["multi_level_mall", "retail_shops", "luxury_stores", "food_court", "restaurants", "cafes", "cinema_multiplex", "family_entertainment", "indoor_promenade"])
			_add_facility_block(facility_root, "GrandMallAtrium", Vector3(0.0, 5.0, 0.0), Vector3(40.0, 8.0, 34.0), glass, "GRAND MALL")
			_add_facility_block(facility_root, "FoodCourt", Vector3(-22.0, 5.0, 0.0), Vector3(12.0, 7.0, 26.0), interior, "FOOD COURT")
			_add_facility_block(facility_root, "RestaurantAndCafeGallery", Vector3(22.0, 5.0, 0.0), Vector3(12.0, 7.0, 26.0), interior, "RESTAURANTS • CAFES")
			_add_facility_block(facility_root, "CinemaMultiplex", Vector3(0.0, 5.0, -25.0), Vector3(38.0, 9.0, 14.0), screen, "CINEMA MULTIPLEX")
			_create_cinema_hall_layout(facility_root, radius, interior, screen)
		"EntertainmentTower":
			facility_ids = PackedStringArray(["amusement_park", "family_entertainment", "concert_hall", "esports_arena", "bowling", "arcade", "virtual_reality", "water_park", "swimming_pools", "sports_courts", "festival_plaza", "cinema_outdoor"])
			_add_facility_block(facility_root, "IndoorAmusementAtrium", Vector3(-18.0, 5.0, 0.0), Vector3(22.0, 9.0, 22.0), glass, "FAMILY AMUSEMENT")
			_add_facility_block(facility_root, "EsportsAndArcade", Vector3(18.0, 5.0, 0.0), Vector3(22.0, 9.0, 22.0), screen, "ESPORTS • ARCADE")
			_add_facility_block(facility_root, "ConcertAndFestivalHall", Vector3(0.0, 5.0, -22.0), Vector3(38.0, 10.0, 14.0), interior, "LIVE EVENTS")
			_add_facility_block(facility_root, "BowlingAndVRCenter", Vector3(0.0, 5.0, 22.0), Vector3(38.0, 8.0, 14.0), glass, "BOWLING • VR")
			_create_recreation_feature_markers(facility_root, radius, glass, screen)
		"TechnologyInnovationTower":
			facility_ids = PackedStringArray(["research_labs", "robotics_center", "ai_laboratories", "virtual_reality_lab", "innovation_incubator", "technology_exhibition", "digital_library", "prototype_workshops"])
			_add_facility_block(facility_root, "ResearchLaboratories", Vector3(-14.0, 5.0, 0.0), Vector3(20.0, 9.0, 20.0), glass, "RESEARCH LABS")
			_add_facility_block(facility_root, "RoboticsAndAI", Vector3(14.0, 5.0, 0.0), Vector3(20.0, 9.0, 20.0), screen, "ROBOTICS • AI")
			_add_facility_block(facility_root, "InnovationExhibition", Vector3(0.0, 5.0, -22.0), Vector3(38.0, 9.0, 14.0), interior, "INNOVATION EXPO")
			_add_facility_block(facility_root, "DigitalLibrary", Vector3(0.0, 5.0, 22.0), Vector3(38.0, 9.0, 14.0), glass, "DIGITAL LIBRARY")
	facility_root.set_meta("facility_ids", facility_ids)
	facility_root.set_meta("geometry_status", "visual_blockout")
	facility_root.set_meta("interactive", false)


func _add_facility_block(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material, sign_text: String) -> void:
	# Open-front architectural shell: a walkable floor plate, two side walls,
	# a rear wall and a high lintel leave a clear entrance into each facility.
	var shell := Node3D.new()
	shell.name = node_name
	shell.position = local_position
	parent.add_child(shell)
	var wall_thickness := 0.65
	_add_facility_piece(shell, "WalkableFloor", Vector3(0.0, 0.0, 0.0), Vector3(size.x, 0.45, size.z), material, true)
	_add_facility_piece(shell, "RearWall", Vector3(0.0, size.y * 0.5, -size.z * 0.5), Vector3(size.x, size.y, wall_thickness), material, true)
	_add_facility_piece(shell, "LeftWall", Vector3(-size.x * 0.5, size.y * 0.5, 0.0), Vector3(wall_thickness, size.y, size.z), material, true)
	_add_facility_piece(shell, "RightWall", Vector3(size.x * 0.5, size.y * 0.5, 0.0), Vector3(wall_thickness, size.y, size.z), material, true)
	_add_facility_piece(shell, "EntranceLintel", Vector3(0.0, size.y - 0.6, size.z * 0.5), Vector3(size.x, 1.2, wall_thickness), material, true)
	var sign := Label3D.new()
	sign.name = node_name + "_Sign"
	sign.text = sign_text
	sign.font_size = 22
	sign.pixel_size = 0.014
	sign.position = Vector3(0.0, size.y + 1.0, size.z * 0.5 + 0.3)
	sign.modulate = Color(0.55, 0.88, 1.0)
	shell.add_child(sign)
	shell.set_meta("entrance_open", true)
	shell.set_meta("navigation_ready", false)


func _add_facility_piece(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material, add_collision: bool) -> void:
	var piece := MeshInstance3D.new()
	piece.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	piece.mesh = mesh
	piece.position = local_position
	piece.material_override = material
	parent.add_child(piece)
	if add_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "_Collision"
		body.position = local_position
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)


func _create_cinema_hall_layout(parent: Node3D, radius: float, seat_material: Material, screen_material: Material) -> void:
	var cinema := Node3D.new()
	cinema.name = "CinemaSixHallLayout_Blockout"
	cinema.position = Vector3(0.0, 10.0, -25.0)
	parent.add_child(cinema)
	for hall_index in range(6):
		var hall := Node3D.new()
		hall.name = "CinemaHall_%02d" % (hall_index + 1)
		var column := hall_index % 3
		var row := hall_index / 3
		hall.position = Vector3(float(column - 1) * 13.0, 0.0, float(row) * 13.0)
		cinema.add_child(hall)
		_add_facility_piece(hall, "CinemaWalkableFloor", Vector3(0.0, 0.0, 0.0), Vector3(12.0, 0.35, 12.0), seat_material, true)
		var screen_panel := MeshInstance3D.new()
		screen_panel.name = "ProjectionScreen"
		var screen_mesh := BoxMesh.new()
		screen_mesh.size = Vector3(8.0, 4.5, 0.35)
		screen_panel.mesh = screen_mesh
		screen_panel.position = Vector3(0.0, 3.8, -4.5)
		screen_panel.material_override = screen_material
		hall.add_child(screen_panel)
		for seat_row in range(4):
			for seat_column in range(6):
				var seat := MeshInstance3D.new()
				seat.name = "Seat_%02d_%02d" % [seat_row, seat_column]
				var seat_mesh := BoxMesh.new()
				seat_mesh.size = Vector3(0.8, 0.9, 0.8)
				seat.mesh = seat_mesh
				seat.position = Vector3(-2.5 + float(seat_column), 0.55 + float(seat_row) * 0.18, 1.0 + float(seat_row) * 1.6)
				seat.material_override = seat_material
				hall.add_child(seat)
	cinema.set_meta("hall_count", 6)
	cinema.set_meta("seats_per_hall_visual", 24)
	cinema.set_meta("playback_enabled", false)
	cinema.set_meta("status", "visual_blockout_only")


func _create_recreation_feature_markers(parent: Node3D, radius: float, material: Material, accent: Material) -> void:
	var wheel := MeshInstance3D.new()
	wheel.name = "ObservationWheel_Blockout"
	var wheel_mesh := TorusMesh.new()
	wheel_mesh.inner_radius = 8.0
	wheel_mesh.outer_radius = 9.0
	wheel.mesh = wheel_mesh
	wheel.position = Vector3(0.0, 13.0, -radius * 0.72)
	wheel.material_override = accent
	parent.add_child(wheel)
	var pool := MeshInstance3D.new()
	pool.name = "SkyPool_Blockout"
	var pool_mesh := BoxMesh.new()
	pool_mesh.size = Vector3(18.0, 0.4, 8.0)
	pool.mesh = pool_mesh
	pool.position = Vector3(0.0, 11.0, radius * 0.72)
	pool.material_override = material
	parent.add_child(pool)
	parent.set_meta("ride_interactions_enabled", false)


func _create_central_system_spire(parent: Node3D) -> void:
	var spire := Node3D.new()
	spire.name = "CentralSYSTEMSkySpire_Blockout"
	spire.position = city_anchor + Vector3(0.0, 0.0, 0.0)
	parent.add_child(spire)
	var core := MeshInstance3D.new()
	core.name = "CentralBlueGlassSpire"
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 5.0
	core_mesh.bottom_radius = 18.0
	core_mesh.height = 150.0
	core.mesh = core_mesh
	core.position.y = 75.0
	core.material_override = emissive_material
	spire.add_child(core)
	var logo := Label3D.new()
	logo.name = "SYSTEMSkylineEmblem"
	logo.text = "S"
	logo.font_size = 220
	logo.position = Vector3(0.0, 86.0, 18.5)
	logo.modulate = Color(0.25, 0.88, 1.0)
	spire.add_child(logo)
	spire.set_meta("identity", "SYSTEM central landmark")
	spire.set_meta("status", "visual_blockout_only")


func _create_shared_sky_terraces(parent: Node3D) -> void:
	var terrace_material := _make_surface_material(Color(0.08, 0.22, 0.20), 0.36, 0.36)
	for level in range(3):
		var terrace := MeshInstance3D.new()
		terrace.name = "SharedSkyGardenTerrace_%02d" % level
		var mesh := CylinderMesh.new()
		mesh.top_radius = 118.0 - float(level) * 18.0
		mesh.bottom_radius = 126.0 - float(level) * 18.0
		mesh.height = 2.2
		terrace.mesh = mesh
		terrace.position = city_anchor + Vector3(0.0, 28.0 + float(level) * 13.0, 0.0)
		terrace.material_override = terrace_material
		parent.add_child(terrace)
		_add_static_box_collision(parent, "SharedSkyGardenCollision_%02d" % level, terrace.position, Vector3(252.0, 2.2, 252.0))
		terrace.set_meta("amenities", PackedStringArray(["gardens", "cafes", "viewing_decks", "family_seating", "public_art"]))




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

