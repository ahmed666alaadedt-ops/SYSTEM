extends Node3D
class_name BaghdadTowerLandmarksManager

const EntranceScript = preload("res://scripts/system_tower_entrance.gd")
const HunterHelicopterControllerScript = preload("res://scripts/system_hunter_helicopter_pad_controller.gd")
const HUNTER_TOWER_HEIGHT := 650.0
const REPUBLIC_BRIDGE_DECK_HEIGHT := 18.0
const HUNTER_CENTRAL_SKY_CITY_PLATFORM_HEIGHT := 419.2
const POWER_TOWER_HEIGHT := 820.0

var terrain: Node
var city_anchor := Vector3.ZERO
var bridge_anchor := Vector2.ZERO
var bridge_axis := Vector2.ZERO
var bridge_river_axis := Vector2.ZERO
var bridge_centerline: Array[Vector2] = []
var bridge_reference_loaded := false
var tower_material: StandardMaterial3D
var trim_material: StandardMaterial3D
var emissive_material: StandardMaterial3D
var tower_positions: Array[Dictionary] = []
var district_tower_positions: Array[Dictionary] = []

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
	if not _load_republic_bridge_reference():
		push_error("SYSTEM WORLD: verified Republic Bridge reference is required for Baghdad tower placement.")
		return
	_create_materials()
	_build_hunter_tower()
	_build_power_tower()
	_build_business_tower()
	_build_shopping_tower()
	_build_entertainment_tower()
	_build_technology_tower()
	_create_baghdad_upper_city_layer()
	_create_connected_city_links()
	_create_public_amenities()
	_create_hunter_exam_tunnel()

func _load_republic_bridge_reference() -> bool:
	var path := "res://data/geography/baghdad/republic_bridge_reference.json"
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or str(parsed.get("region_id", "")) != "iraq_baghdad_region":
		return false
	var source: Dictionary = parsed.get("source", {})
	if str(source.get("license", "")) != "ODbL-1.0" or int(source.get("source_artifact_id", 0)) != 14629100933:
		return false
	var bridge: Dictionary = parsed.get("republic_bridge", {})
	var center: Dictionary = bridge.get("center_local_m", {})
	bridge_anchor = Vector2(float(center.get("east", 0.0)), float(center.get("south", 0.0)))
	for point_value in bridge.get("centerline_local_m", []):
		if point_value is Dictionary:
			bridge_centerline.append(Vector2(float(point_value.get("east_m", 0.0)), float(point_value.get("south_m", 0.0))))
	if bridge_centerline.size() < 2:
		return false
	bridge_axis = (bridge_centerline[bridge_centerline.size() - 1] - bridge_centerline[0]).normalized()
	bridge_river_axis = Vector2(-bridge_axis.y, bridge_axis.x)
	bridge_reference_loaded = true
	set_meta("system_republic_bridge_osm_way_id", int(bridge.get("osm_bridge_centerline_way_id", 0)))
	set_meta("system_republic_bridge_anchor_local_m", bridge_anchor)
	set_meta("system_tigris_river_osm_way_id", int(parsed.get("tigris_river", {}).get("osm_way_id", 0)))
	return true


func _bridge_district_position(across_offset: float, river_offset: float) -> Vector3:
	var point := bridge_anchor + bridge_axis * across_offset + bridge_river_axis * river_offset
	return Vector3(point.x, 0.0, point.y)


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
	var position := Vector3(bridge_anchor.x, HUNTER_CENTRAL_SKY_CITY_PLATFORM_HEIGHT, bridge_anchor.y)
	_build_tower(
		"HunterAssociationTower",
		"برج الصيادين العالمي",
		"hunter_association_tower_baghdad",
		position,
		HUNTER_TOWER_HEIGHT,
		38.0,
		200,
		Color(0.08, 0.62, 0.92),
		true,
		true
	)
	var hunter_tower := get_node_or_null("HunterAssociationTower") as Node3D
	if hunter_tower != null:
		_create_hunter_helipad(hunter_tower, 38.0)
		_create_hunter_advertising_facades(hunter_tower, 38.0)


func _create_hunter_helipad(tower: Node3D, tower_radius: float) -> void:
	# A dedicated rooftop helicopter pad attached to the Hunter Association only.
	var pad_root := Node3D.new()
	pad_root.name = "HunterAssociationHelipad"
	pad_root.set_script(HunterHelicopterControllerScript)
	pad_root.position = Vector3(0.0, HUNTER_TOWER_HEIGHT + 8.2, 0.0)
	pad_root.set_meta("system_facility_type", "helicopter_landing_pad")
	pad_root.set_meta("system_owner_tower_id", "hunter_association_tower_baghdad")
	pad_root.set_meta("system_landing_zone_radius_m", 18.0)
	pad_root.set_meta("system_landing_zone_status", "operational_controller_attached")
	pad_root.set_meta("system_landing_zone_controller", "HunterHelicopterPadController")
	tower.add_child(pad_root)

	var deck := MeshInstance3D.new()
	deck.name = "HelipadDeck"
	var deck_mesh := CylinderMesh.new()
	deck_mesh.top_radius = 22.0
	deck_mesh.bottom_radius = 22.0
	deck_mesh.height = 2.4
	deck.mesh = deck_mesh
	deck.material_override = _make_surface_material(Color(0.12, 0.17, 0.21), 0.72, 0.34)
	pad_root.add_child(deck)

	var deck_body := StaticBody3D.new()
	deck_body.name = "HelipadDeckCollision"
	var deck_collision := CollisionShape3D.new()
	var deck_shape := CylinderShape3D.new()
	deck_shape.radius = 22.0
	deck_shape.height = 2.4
	deck_collision.shape = deck_shape
	deck_body.add_child(deck_collision)
	pad_root.add_child(deck_body)

	var ring := MeshInstance3D.new()
	ring.name = "LandingCircleMarking"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 15.8
	ring_mesh.outer_radius = 16.5
	ring.mesh = ring_mesh
	ring.position.y = 1.24
	ring.material_override = _make_surface_material(Color(0.92, 0.94, 0.91), 0.88, 0.02)
	pad_root.add_child(ring)

	var marking_material := _make_surface_material(Color(0.96, 0.96, 0.90), 0.86, 0.0)
	for marking in [
		{"name": "HelipadH_Left", "position": Vector3(-3.2, 1.27, 0.0), "size": Vector3(1.15, 0.12, 8.0)},
		{"name": "HelipadH_Right", "position": Vector3(3.2, 1.27, 0.0), "size": Vector3(1.15, 0.12, 8.0)},
		{"name": "HelipadH_Crossbar", "position": Vector3(0.0, 1.27, 0.0), "size": Vector3(7.4, 0.12, 1.15)}
	]:
		var stripe := MeshInstance3D.new()
		stripe.name = str(marking["name"])
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = marking["size"]
		stripe.mesh = stripe_mesh
		stripe.position = marking["position"]
		stripe.material_override = marking_material
		pad_root.add_child(stripe)

	var beacon_material := _make_surface_material(Color(0.25, 0.92, 0.72), 0.28, 0.42)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(0.12, 0.9, 0.62)
	beacon_material.emission_energy_multiplier = 2.0
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var light := MeshInstance3D.new()
		light.name = "HelipadPerimeterLight_%02d" % index
		var light_mesh := SphereMesh.new()
		light_mesh.radius = 0.48
		light_mesh.height = 0.96
		light.mesh = light_mesh
		light.position = Vector3(cos(angle) * 20.0, 1.55, sin(angle) * 20.0)
		light.material_override = beacon_material
		pad_root.add_child(light)

	# A short elevated connector makes the landing deck visibly part of the tower.
	var connector := MeshInstance3D.new()
	connector.name = "HelipadAccessBridge"
	var connector_mesh := BoxMesh.new()
	connector_mesh.size = Vector3(25.0, 1.6, 8.0)
	connector.mesh = connector_mesh
	connector.position = Vector3(-22.0, -0.25, 0.0)
	connector.material_override = trim_material
	pad_root.add_child(connector)
	var connector_body := StaticBody3D.new()
	connector_body.name = "HelipadAccessBridgeCollision"
	var connector_collision := CollisionShape3D.new()
	var connector_shape := BoxShape3D.new()
	connector_shape.size = connector_mesh.size
	connector_collision.shape = connector_shape
	connector_body.position = connector.position
	connector_body.add_child(connector_collision)
	pad_root.add_child(connector_body)

	var sign := Label3D.new()
	sign.name = "HelipadIdentitySign"
	sign.text = "HUNTER ASSOCIATION\nHELICOPTER LANDING"
	sign.font_size = 24
	sign.pixel_size = 0.012
	sign.position = Vector3(0.0, 4.0, 23.5)
	sign.modulate = Color(0.72, 0.96, 1.0)
	pad_root.add_child(sign)
	print("SYSTEM WORLD: dedicated Hunter Association rooftop helicopter pad generated.")

func _create_hunter_advertising_facades(tower: Node3D, tower_radius: float) -> void:
	var facade_root := Node3D.new()
	facade_root.name = "HunterTowerAdvertisingFacades"
	facade_root.set_meta("system_advertising_scope", "hunter_tower_exterior")
	facade_root.set_meta("system_advertising_mode", "curated_demo_no_live_ad_network")
	tower.add_child(facade_root)
	var frame_material := _make_surface_material(Color(0.018, 0.035, 0.052), 0.28, 0.68)
	var screen_material := _make_surface_material(Color(0.015, 0.15, 0.22), 0.2, 0.35)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.02, 0.48, 0.72)
	screen_material.emission_energy_multiplier = 1.8
	var screen_count := 0
	var tier_halo_count := 0
	for level in [150.0, 340.0, 530.0]:
		var progress: float = float(level) / HUNTER_TOWER_HEIGHT
		var halo_radius: float = tower_radius * lerpf(1.0, 0.62, progress) * 1.08
		var halo := MeshInstance3D.new()
		halo.name = "HunterAdvertisingTierHalo_%03d" % int(level)
		var halo_mesh := TorusMesh.new()
		halo_mesh.inner_radius = halo_radius - 0.65
		halo_mesh.outer_radius = halo_radius + 0.45
		halo_mesh.rings = 48
		halo_mesh.ring_segments = 10
		halo.mesh = halo_mesh
		halo.rotation.x = PI * 0.5
		halo.position.y = level + 7.0
		halo.material_override = screen_material
		facade_root.add_child(halo)
		tier_halo_count += 1
	for side in range(4):
		var angle := TAU * float(side) / 4.0
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		for level in [150.0, 340.0, 530.0]:
			var panel := Node3D.new()
			panel.name = "HunterExteriorAd_%02d_%03d" % [side, int(level)]
			panel.position = outward * (tower_radius + 1.5) + Vector3(0.0, level, 0.0)
			panel.rotation.y = -angle
			panel.set_meta("system_advertising_scope", "hunter_tower_exterior")
			panel.set_meta("system_advertising_mode", "curated_demo")
			facade_root.add_child(panel)
			var frame := MeshInstance3D.new()
			frame.name = "AdvertisingFrame"
			var frame_mesh := BoxMesh.new()
			frame_mesh.size = Vector3(1.2, 20.0, 34.0)
			frame.mesh = frame_mesh
			frame.material_override = frame_material
			panel.add_child(frame)
			var screen := MeshInstance3D.new()
			screen.name = "AdvertisingScreen"
			var screen_mesh := BoxMesh.new()
			screen_mesh.size = Vector3(0.42, 17.5, 31.5)
			screen.mesh = screen_mesh
			screen.position.x = 0.68
			screen.material_override = screen_material
			screen.set_meta("system_advertising_screen", true)
			panel.add_child(screen)
			var label := Label3D.new()
			label.name = "AdvertisingIdentity"
			label.text = "SYSTEM HUNTER ASSOCIATION\nإعلانات برج الصيادين"
			label.font_size = 24
			label.pixel_size = 0.012
			label.modulate = Color(0.78, 0.96, 1.0)
			label.position = Vector3(0.9, 0.0, 0.0)
			label.rotation.y = PI * 0.5
			panel.add_child(label)
			screen_count += 1
	facade_root.set_meta("system_advertising_screen_count", screen_count)
	facade_root.set_meta("system_hunter_ad_tier_halo_count", tier_halo_count)
	tower.set_meta("system_hunter_exterior_ad_facades", screen_count)


func _build_power_tower() -> void:
	# Standalone challenge destination: deliberately outside the five-tower district.
	var position := city_anchor + Vector3(650.0, 0.0, 620.0)
	_build_tower(
		"PowerTower",
		"برج القوة",
		"power_tower_baghdad",
		position,
		POWER_TOWER_HEIGHT,
		26.0,
		200,
		Color(0.95, 0.55, 0.16),
		false
	)

func _build_tower(node_name: String, title: String, location_id: String, world_position: Vector3, height: float, radius: float, floors: int, beacon_color: Color, connect_to_district: bool = true, allow_bridge_platform: bool = false) -> void:
	var requested_position := Vector2(world_position.x, world_position.z)
	var resolved := requested_position
	var root_height := 0.0
	if allow_bridge_platform:
		if not bridge_reference_loaded or requested_position.distance_to(bridge_anchor) > 80.0:
			push_error("SYSTEM WORLD: bridge platform requested outside the verified Republic Bridge anchor.")
			return
		root_height = HUNTER_CENTRAL_SKY_CITY_PLATFORM_HEIGHT
	else:
		resolved = _nearest_land_position(requested_position)
		if resolved == Vector2.INF:
			push_warning("SYSTEM WORLD: no suitable land for tower " + title)
			return
		if resolved.distance_to(requested_position) > 0.5:
			print("SYSTEM WORLD: tower plot relocated to nearby land: ", title, " / offset ", snappedf(resolved.distance_to(requested_position), 0.1), "m")
		root_height = float(terrain.call("get_terrain_height", resolved.x, resolved.y))
	var root := Node3D.new()
	root.name = node_name
	root.position = Vector3(resolved.x, root_height, resolved.y)
	root.set_meta("system_placement_source", "verified_republic_bridge_osm_upper_sky_city_central_platform" if allow_bridge_platform else "verified_baghdad_bridge_riverbank_terrain")
	add_child(root)
	var tower_record := {"id": location_id, "name": title, "position": root.position, "height": height, "radius": radius}
	tower_positions.append(tower_record)
	if connect_to_district:
		district_tower_positions.append(tower_record)

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

	# Keep the Hunter rooftop landing circle completely clear: the generic solid crown
	# would overlap the 22 m helipad deck, so that tower uses the roof beacon as its crown identity.
	if node_name != "HunterAssociationTower":
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
	else:
		root.set_meta("system_hunter_roof_clearance_reserved", true)

	var beacon := OmniLight3D.new()
	beacon.name = "SkyBeacon"
	beacon.position = Vector3(radius * 0.84, height + 22.0, 0.0) if node_name == "HunterAssociationTower" else Vector3(0.0, height + 22.0, 0.0)
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
	beacon_core.position = Vector3(radius * 0.84, height + 22.0, 0.0) if node_name == "HunterAssociationTower" else Vector3(0.0, height + 22.0, 0.0)
	beacon_core.material_override = emissive_material
	root.add_child(beacon_core)

	var entrance := EntranceScript.new()
	entrance.name = "PublicEntrance"
	entrance.configure(location_id, title, "region_baghdad")
	entrance.set_meta("system_tower_id", location_id)
	entrance.set_meta("system_tower_floor_count", floors)
	entrance.set_meta("system_tower_height_m", height)
	entrance.set_meta("system_tower_district_member", connect_to_district)
	entrance.set_meta("system_tower_floor_directory", _get_tower_floor_directory(location_id))
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
	root.set_meta("tower_id", location_id)
	root.set_meta("tower_floor_count", floors)
	root.set_meta("tower_height_m", height)
	root.set_meta("tower_is_connected_district_member", connect_to_district)
	root.set_meta("system_republic_bridge_anchor_local_m", bridge_anchor)
	root.set_meta("tower_floor_directory", _get_tower_floor_directory(location_id))
	_create_tower_lobby(root, location_id, title, radius, floors, height, connect_to_district)
	if connect_to_district:
		_create_tower_sky_gardens(root, location_id, title, height, radius, floors)
	print("SYSTEM WORLD: landmark tower generated: ", title, " / ", floors, " floors / ", height, "m")

func _create_tower_sky_gardens(tower: Node3D, tower_id: String, tower_title: String, tower_height: float, tower_radius: float, floor_count: int) -> void:
	# Three real, walkable sky gardens are attached to each of Baghdad's five civic towers.
	# The central shaft remains clear; four collidable deck sections form a ring promenade.
	var gardens := Node3D.new()
	gardens.name = "TowerSkyGardens"
	gardens.set_meta("system_owner_tower_id", tower_id)
	gardens.set_meta("system_sky_garden_count", 3)
	gardens.set_meta("system_sky_gardens_walkable", true)
	tower.add_child(gardens)

	var deck_material := _make_surface_material(Color(0.12, 0.19, 0.20), 0.82, 0.12)
	var soil_material := _make_surface_material(Color(0.18, 0.105, 0.055), 0.96, 0.0)
	var planter_material := _make_surface_material(Color(0.12, 0.18, 0.20), 0.7, 0.25)
	var glass_material := _make_surface_material(Color(0.28, 0.72, 0.82, 0.48), 0.18, 0.55)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color.a = 0.42
	var foliage_material := _make_surface_material(Color(0.12, 0.42, 0.22), 0.92, 0.0)
	var canopy_material := _make_surface_material(Color(0.22, 0.58, 0.30), 0.88, 0.0)
	var trunk_material := _make_surface_material(Color(0.28, 0.16, 0.085), 0.96, 0.0)
	var light_material := _make_surface_material(Color(0.32, 0.88, 0.82), 0.28, 0.18)
	light_material.emission_enabled = true
	light_material.emission = Color(0.08, 0.62, 0.56)
	light_material.emission_energy_multiplier = 1.25

	var progress_values := [0.24, 0.52, 0.80]
	var outer := tower_radius * 2.18
	var inner := tower_radius * 1.16
	var strip := outer - inner
	var side_center := (outer + inner) * 0.5
	for garden_index in range(3):
		var progress := float(progress_values[garden_index])
		var floor_number := clampi(roundi(1.0 + float(maxi(floor_count - 1, 0)) * progress), 1, floor_count)
		var floor_height := 9.0 + (tower_height - 16.0) * progress
		var garden := Node3D.new()
		garden.name = "SkyGarden_%02d" % (garden_index + 1)
		garden.position.y = floor_height
		garden.set_meta("system_facility_type", "elevated_public_sky_garden")
		garden.set_meta("system_owner_tower_id", tower_id)
		garden.set_meta("system_garden_level", garden_index + 1)
		garden.set_meta("system_tower_floor", floor_number)
		garden.set_meta("system_garden_walkable", true)
		gardens.add_child(garden)

		var deck_specs := [
			{"name": "North", "position": Vector3(0.0, 0.0, -side_center), "size": Vector3(outer * 2.0, 0.72, strip)},
			{"name": "South", "position": Vector3(0.0, 0.0, side_center), "size": Vector3(outer * 2.0, 0.72, strip)},
			{"name": "East", "position": Vector3(side_center, 0.0, 0.0), "size": Vector3(strip, 0.72, inner * 2.0)},
			{"name": "West", "position": Vector3(-side_center, 0.0, 0.0), "size": Vector3(strip, 0.72, inner * 2.0)}
		]
		for deck_spec in deck_specs:
			var deck := MeshInstance3D.new()
			deck.name = "GardenFloor_" + str(deck_spec["name"])
			var deck_mesh := BoxMesh.new()
			deck_mesh.size = deck_spec["size"]
			deck.mesh = deck_mesh
			deck.position = deck_spec["position"]
			deck.material_override = deck_material
			garden.add_child(deck)
			_add_static_box_collision(garden, deck.name + "_Collision", deck.position, deck_mesh.size)

		# Four glass perimeter rails keep the elevated garden safe without enclosing the views.
		for side in [-1.0, 1.0]:
			for axis in [-1.0, 1.0]:
				var rail := MeshInstance3D.new()
				rail.name = "GardenGlassRail_%s_%s" % [str(side), str(axis)]
				var rail_mesh := BoxMesh.new()
				rail_mesh.size = Vector3(outer * 2.0 + 0.8, 1.35, 0.24) if side == 0.0 else Vector3(0.24, 1.35, outer * 2.0 + 0.8)
				# Four independent perimeter edges; the conditional keeps the geometry axis-aligned.
				rail_mesh.size = Vector3(outer * 2.0 + 0.8, 1.35, 0.24) if side < 0.0 else Vector3(0.24, 1.35, outer * 2.0 + 0.8)
				rail.mesh = rail_mesh
				rail.position = Vector3(0.0, 1.02, axis * outer) if side < 0.0 else Vector3(axis * outer, 1.02, 0.0)
				rail.material_override = glass_material
				garden.add_child(rail)
		garden.set_meta("system_glass_perimeter_railing", true)

		# Planter beds, trees, benches and low garden lights provide distinct public green space.
		for plant_index in range(4):
			var angle := TAU * float(plant_index) / 4.0 + float(garden_index) * 0.28
			var plant_position := Vector3(cos(angle) * (inner + strip * 0.72), 0.42, sin(angle) * (inner + strip * 0.72))
			var planter := MeshInstance3D.new()
			planter.name = "GardenPlanter_%02d" % plant_index
			var planter_mesh := BoxMesh.new()
			planter_mesh.size = Vector3(maxf(3.0, tower_radius * 0.42), 1.1, maxf(2.6, tower_radius * 0.34))
			planter.mesh = planter_mesh
			planter.position = plant_position
			planter.rotation.y = angle
			planter.material_override = planter_material
			garden.add_child(planter)
			var soil := MeshInstance3D.new()
			soil.name = "GardenPlanterSoil_%02d" % plant_index
			var soil_mesh := BoxMesh.new()
			soil_mesh.size = Vector3(planter_mesh.size.x * 0.86, 0.12, planter_mesh.size.z * 0.82)
			soil.mesh = soil_mesh
			soil.position = plant_position + Vector3(0.0, 0.58, 0.0)
			soil.rotation.y = angle
			soil.material_override = soil_material
			garden.add_child(soil)
			var trunk := MeshInstance3D.new()
			trunk.name = "GardenTreeTrunk_%02d" % plant_index
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.22
			trunk_mesh.bottom_radius = 0.36
			trunk_mesh.height = 2.7
			trunk.mesh = trunk_mesh
			trunk.position = plant_position + Vector3(0.0, 2.0, 0.0)
			trunk.material_override = trunk_material
			garden.add_child(trunk)
			var canopy := MeshInstance3D.new()
			canopy.name = "GardenTreeCanopy_%02d" % plant_index
			var canopy_mesh := SphereMesh.new()
			canopy_mesh.radius = 1.45
			canopy_mesh.height = 2.9
			canopy.mesh = canopy_mesh
			canopy.position = plant_position + Vector3(0.0, 3.75, 0.0)
			canopy.material_override = canopy_material if plant_index % 2 == 0 else foliage_material
			garden.add_child(canopy)

		for bench_index in range(2):
			var bench := MeshInstance3D.new()
			bench.name = "GardenBench_%02d" % bench_index
			var bench_mesh := BoxMesh.new()
			bench_mesh.size = Vector3(maxf(2.8, tower_radius * 0.36), 0.28, 0.82)
			bench.mesh = bench_mesh
			bench.position = Vector3(0.0, 0.78, (-1.0 if bench_index == 0 else 1.0) * (inner + strip * 0.28))
			bench.material_override = trim_material
			garden.add_child(bench)
		for light_index in range(4):
			var angle := TAU * float(light_index) / 4.0
			var garden_light := MeshInstance3D.new()
			garden_light.name = "GardenPathLight_%02d" % light_index
			var light_mesh := SphereMesh.new()
			light_mesh.radius = 0.28
			light_mesh.height = 0.56
			garden_light.mesh = light_mesh
			garden_light.position = Vector3(cos(angle) * (inner + strip * 0.46), 1.15, sin(angle) * (inner + strip * 0.46))
			garden_light.material_override = light_material
			garden.add_child(garden_light)

		var sign := Label3D.new()
		sign.name = "GardenIdentitySign"
		sign.text = "SYSTEM SKY GARDEN %d\nحديقة سماوية — %s\nالطابق %d" % [garden_index + 1, tower_title, floor_number]
		sign.font_size = 22
		sign.pixel_size = 0.012
		sign.position = Vector3(0.0, 2.2, -inner - strip * 0.25)
		sign.modulate = Color(0.78, 0.96, 0.82)
		garden.add_child(sign)

		var interaction := Area3D.new()
		interaction.name = "SkyGardenInteraction_%02d" % (garden_index + 1)
		interaction.position = Vector3(0.0, 1.8, 0.0)
		interaction.add_to_group("system_interactable")
		interaction.set_meta("system_facility_type", "elevated_public_sky_garden")
		interaction.set_meta("system_owner_tower_id", tower_id)
		interaction.set_meta("system_garden_level", garden_index + 1)
		interaction.set_meta("system_tower_floor", floor_number)
		interaction.set_meta("system_interaction_prompt", "استكشف الحديقة السماوية — الطابق %d" % floor_number)
		var interaction_shape := CollisionShape3D.new()
		interaction_shape.name = "GardenInteractionShape"
		var interaction_box := BoxShape3D.new()
		interaction_box.size = Vector3(outer * 2.0, 4.0, outer * 2.0)
		interaction_shape.shape = interaction_box
		interaction.add_child(interaction_shape)
		garden.add_child(interaction)

		garden.set_meta("system_garden_planter_count", 4)
		garden.set_meta("system_garden_tree_count", 4)
		garden.set_meta("system_garden_bench_count", 2)
		garden.set_meta("system_garden_path_light_count", 4)
		garden.set_meta("system_garden_floor_collision_count", 4)
	gardens.set_meta("system_sky_garden_levels", PackedInt32Array([1, 2, 3]))
	gardens.set_meta("system_sky_garden_floor_map", PackedInt32Array([
		clampi(roundi(1.0 + float(maxi(floor_count - 1, 0)) * 0.24), 1, floor_count),
		clampi(roundi(1.0 + float(maxi(floor_count - 1, 0)) * 0.52), 1, floor_count),
		clampi(roundi(1.0 + float(maxi(floor_count - 1, 0)) * 0.80), 1, floor_count)
	]))



func _create_hunter_exam_tunnel() -> void:
	# One permanent Hunter Examination tunnel. Access is provided by the
	# dedicated restaurant room elevator; there are no hidden clues or doors.
	var tunnel_root := Node3D.new()
	tunnel_root.name = "BaghdadHunterExaminationTunnel"
	tunnel_root.position = Vector3(
		bridge_anchor.x,
		float(terrain.call("get_terrain_height", bridge_anchor.x, bridge_anchor.y)) - 45.0,
		bridge_anchor.y
	)
	tunnel_root.set_meta("system_under_republic_bridge_district", true)
	tunnel_root.set_meta("system_tunnel_location_source", "Hunter Association Tower Baghdad guild guide escort")
	tunnel_root.set_meta("system_facility_type", "hunter_examination_tunnel")
	tunnel_root.set_meta("system_under_baghdad_tower_district", true)
	tunnel_root.set_meta("system_exam_manager", "SYSTEMHunterExamManager")
	tunnel_root.set_meta("system_hunter_exam_access", "hunter_tower_recruitment_and_guide_escort")
	tunnel_root.set_meta("system_tunnel_is_single_continuous_route", true)
	add_child(tunnel_root)

	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(28.0, 1.0, 54.0)
	var stone_material := _make_surface_material(Color(0.075, 0.105, 0.13), 0.88, 0.18)
	var trim_material := _make_surface_material(Color(0.015, 0.28, 0.36), 0.38, 0.65)
	trim_material.emission_enabled = true
	trim_material.emission = Color(0.0, 0.38, 0.56)
	trim_material.emission_energy_multiplier = 1.1

	var tunnel_floor := MeshInstance3D.new()
	tunnel_floor.name = "HunterTunnelFloor"
	tunnel_floor.mesh = floor_mesh
	tunnel_floor.position = Vector3(0.0, -0.5, 12.0)
	tunnel_floor.material_override = stone_material
	tunnel_root.add_child(tunnel_floor)
	_add_static_box_collision(tunnel_root, "HunterTunnelFloorCollision", tunnel_floor.position, floor_mesh.size)

	for side in [-1.0, 1.0]:
		var wall := MeshInstance3D.new()
		wall.name = "HunterTunnelWall_" + ("Left" if side < 0.0 else "Right")
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(0.8, 8.0, 54.0)
		wall.mesh = wall_mesh
		wall.position = Vector3(side * 13.6, 3.5, 12.0)
		wall.material_override = stone_material
		tunnel_root.add_child(wall)
		_add_static_box_collision(tunnel_root, wall.name + "Collision", wall.position, wall_mesh.size)

	var ceiling := MeshInstance3D.new()
	ceiling.name = "HunterTunnelCeiling"
	var ceiling_mesh := BoxMesh.new()
	ceiling_mesh.size = Vector3(28.0, 0.7, 54.0)
	ceiling.mesh = ceiling_mesh
	ceiling.position = Vector3(0.0, 7.5, 12.0)
	ceiling.material_override = stone_material
	tunnel_root.add_child(ceiling)

	for index in range(8):
		var light := OmniLight3D.new()
		light.name = "HunterTunnelLight_%02d" % index
		light.position = Vector3(0.0, 5.8, -10.0 + float(index) * 6.2)
		light.light_color = Color(0.08, 0.72, 0.95)
		light.light_energy = 1.15
		light.omni_range = 11.0
		tunnel_root.add_child(light)

	var sign := Label3D.new()
	sign.name = "HunterTunnelWelcomeSign"
	sign.text = "SYSTEM HUNTER EXAMINATION\nنفق اختبار الصيادين"
	sign.position = Vector3(0.0, 5.8, 6.0)
	sign.font_size = 28
	sign.pixel_size = 0.014
	sign.modulate = Color(0.42, 0.9, 1.0)
	tunnel_root.add_child(sign)

	tunnel_root.set_meta("system_hunter_exam_guide_present", false)
	tunnel_root.set_meta("system_hunter_exam_return_elevator_present", false)
	print("SYSTEM WORLD: one continuous Hunter Examination tunnel reached by the Hunter Tower guild guide escort.")


func _nearest_land_position(origin: Vector2) -> Vector2:
	if terrain.call("is_land_position", origin.x, origin.y):
		return origin
	# Baghdad tower sites may fall beside the Tigris or on a generated water
	# channel. Search a wider local radius so one unsuitable plot cannot remove
	# a required tower from the five-tower district.
	for radius_step in range(1, 49):
		var radius := float(radius_step) * 12.0
		var sample_count := 32 if radius_step <= 16 else 48
		for sample in range(sample_count):
			var angle := TAU * float(sample) / float(sample_count)
			var candidate := origin + Vector2(cos(angle), sin(angle)) * radius
			if terrain.call("is_land_position", candidate.x, candidate.y):
				return candidate
	return Vector2.INF


func get_tower_positions() -> Array[Dictionary]:
	return tower_positions.duplicate(true)



func _build_business_tower() -> void:
	_build_tower(
		"BusinessInvestmentTower",
		"برج الأعمال والاستثمار",
		"business_investment_tower_baghdad",
		_bridge_district_position(390.0, 170.0),
		220.0,
		26.0,
		36,
		Color(0.22, 0.76, 0.52)
	)


func _build_shopping_tower() -> void:
	_build_tower("ShoppingTower", "برج التسوق والتجارة", "shopping_tower_baghdad", _bridge_district_position(-390.0, -170.0), 190.0, 30.0, 32, Color(0.95, 0.72, 0.28))
	var tower := get_node_or_null("ShoppingTower")
	if tower != null:
		tower.set_meta("facility_categories", PackedStringArray([
			"retail", "weapons", "swords", "spears", "axes", "bows", "firearms",
			"shields", "armor", "armour", "helmets", "ranked_hunter_outfits",
			"equipment_upgrades", "repair", "crafting", "nen_research",
			"healing_elixirs", "strength_elixirs", "speed_elixirs",
			"endurance_elixirs", "energy_elixirs", "rare_legendary_elixirs",
			"restaurants", "cafes", "bakeries", "hotel", "guest_suites"
		]))
		tower.set_meta("elixir_categories", PackedStringArray([
			"nen_acquisition", "nen_control", "nen_stabilization", "healing",
			"regeneration", "strength", "speed", "endurance", "energy",
			"antidotes", "rare_and_legendary_elixirs"
		]))
		tower.set_meta("hospitality_categories", PackedStringArray([
			"iraqi_restaurants", "arab_restaurants", "international_restaurants",
			"cafes", "dessert_shops", "bakeries", "hotel_reception",
			"guest_rooms", "suites", "room_service"
		]))
		tower.set_meta("gameplay_status", "shopping_commerce_hospitality_hotel_and_equipment_blockout")


func _build_entertainment_tower() -> void:
	_build_tower("EntertainmentTower", "برج الترفيه والرياضة", "entertainment_tower_baghdad", _bridge_district_position(430.0, -180.0), 205.0, 29.0, 34, Color(0.75, 0.38, 0.95))


func _build_technology_tower() -> void:
	_build_tower("TechnologyTower", "برج التكنولوجيا والابتكار", "technology_tower_baghdad", _bridge_district_position(-430.0, 180.0), 245.0, 27.0, 40, Color(0.20, 0.82, 0.98))


func _create_tower_lobby(root: Node3D, tower_id: String, title: String, radius: float, floors: int, height: float, connect_to_district: bool) -> void:
	# Ground-level open lobby pavilion sits outside the tower shaft, avoiding the
	# full-height shaft collision while providing a reachable public directory kiosk.
	var lobby := Node3D.new()
	lobby.name = "PublicLobby_Blockout"
	root.add_child(lobby)
	var width := radius * 2.8
	var depth := 36.0
	var center_z := radius * 1.48 + depth * 0.5
	var floor_material := _make_surface_material(Color(0.16, 0.20, 0.24), 0.62, 0.38)
	var canopy_material := _make_surface_material(Color(0.045, 0.12, 0.18), 0.34, 0.58)
	var lobby_floor := MeshInstance3D.new()
	lobby_floor.name = "LobbyFloor"
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(width, 1.0, depth)
	lobby_floor.mesh = floor_mesh
	lobby_floor.position = Vector3(0.0, 0.5, center_z)
	lobby_floor.material_override = floor_material
	lobby.add_child(lobby_floor)
	_add_static_box_collision(lobby, "LobbyFloorCollision", lobby_floor.position, floor_mesh.size)
	var wall_material := _make_surface_material(Color(0.075, 0.13, 0.18), 0.48, 0.42)
	var wall_height := 11.0
	var wall_y := wall_height * 0.5
	var back_z := center_z - depth * 0.5
	var front_z := center_z + depth * 0.5
	for side in [-1.0, 1.0]:
		var side_wall_position := Vector3(side * (width * 0.5), wall_y, center_z)
		_add_tower_identity_box(lobby, "LobbySideWall_%s" % str(side), side_wall_position, Vector3(0.8, wall_height, depth), wall_material)
		_add_static_box_collision(lobby, "LobbySideWallCollision_%s" % str(side), side_wall_position, Vector3(0.8, wall_height, depth))
	var back_segment_width := (width - 12.0) * 0.5
	for side in [-1.0, 1.0]:
		var back_wall_position := Vector3(side * (6.0 + back_segment_width * 0.5), wall_y, back_z)
		_add_tower_identity_box(lobby, "LobbyBackWall_%s" % str(side), back_wall_position, Vector3(back_segment_width, wall_height, 0.8), wall_material)
		_add_static_box_collision(lobby, "LobbyBackWallCollision_%s" % str(side), back_wall_position, Vector3(back_segment_width, wall_height, 0.8))
	var lift_door_position := Vector3(0.0, 4.5, back_z + 0.55)
	_add_tower_identity_box(lobby, "LobbyLiftDoor_Blockout", lift_door_position, Vector3(11.2, 9.0, 0.55), emissive_material)
	_add_static_box_collision(lobby, "LobbyLiftDoorCollision", lift_door_position, Vector3(11.2, 9.0, 0.55))
	var lift_area := Area3D.new()
	lift_area.name = "LobbyElevatorInteraction"
	lift_area.position = lift_door_position + Vector3(0.0, 0.0, 1.2)
	lift_area.add_to_group("system_interactable")
	lift_area.set_meta("system_tower_id", tower_id)
	lift_area.set_meta("system_tower_floor_count", floors)
	lift_area.set_meta("system_interaction_prompt", "افتح مصعد " + title + " واختر الطابق")
	lift_area.collision_layer = 1
	lift_area.collision_mask = 0
	var lift_shape := CollisionShape3D.new()
	var lift_sphere := SphereShape3D.new()
	lift_sphere.radius = 4.5
	lift_shape.shape = lift_sphere
	lift_area.add_child(lift_shape)
	lobby.add_child(lift_area)
	var front_segment_width := (width - 14.0) * 0.5
	for side in [-1.0, 1.0]:
		var front_wall_position := Vector3(side * (7.0 + front_segment_width * 0.5), wall_y, front_z)
		_add_tower_identity_box(lobby, "LobbyFrontWall_%s" % str(side), front_wall_position, Vector3(front_segment_width, wall_height, 0.8), wall_material)
		_add_static_box_collision(lobby, "LobbyFrontWallCollision_%s" % str(side), front_wall_position, Vector3(front_segment_width, wall_height, 0.8))
	var entrance_header_position := Vector3(0.0, 10.5, front_z)
	_add_tower_identity_box(lobby, "LobbyEntranceHeader", entrance_header_position, Vector3(14.0, 1.0, 0.8), trim_material)
	var canopy := MeshInstance3D.new()
	canopy.name = "LobbyCanopy"
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(width, 1.2, depth)
	canopy.mesh = canopy_mesh
	canopy.position = Vector3(0.0, 13.0, center_z)
	canopy.material_override = canopy_material
	lobby.add_child(canopy)
	for side in [-1.0, 1.0]:
		for front_back in [-1.0, 1.0]:
			var column_position := Vector3(side * (width * 0.5 - 2.0), 6.5, center_z + front_back * (depth * 0.5 - 2.0))
			var column := MeshInstance3D.new()
			column.name = "LobbyColumn_%s_%s" % [str(side), str(front_back)]
			var column_mesh := BoxMesh.new()
			column_mesh.size = Vector3(2.0, 13.0, 2.0)
			column.mesh = column_mesh
			column.position = column_position
			column.material_override = trim_material
			lobby.add_child(column)
			_add_static_box_collision(lobby, column.name + "_Collision", column_position, column_mesh.size)
	var kiosk_position := Vector3(radius * 0.62, 3.5, center_z)
	var kiosk := MeshInstance3D.new()
	kiosk.name = "TowerDirectoryKiosk"
	var kiosk_mesh := BoxMesh.new()
	kiosk_mesh.size = Vector3(4.0, 7.0, 3.0)
	kiosk.mesh = kiosk_mesh
	kiosk.position = kiosk_position
	kiosk.material_override = emissive_material
	lobby.add_child(kiosk)
	var kiosk_area := Area3D.new()
	kiosk_area.name = "TowerDirectoryInteraction"
	kiosk_area.position = kiosk_position + Vector3(0.0, 0.5, 2.2)
	kiosk_area.add_to_group("system_interactable")
	kiosk_area.set_meta("system_tower_id", tower_id)
	kiosk_area.set_meta("system_tower_floor_count", floors)
	kiosk_area.set_meta("system_tower_height_m", height)
	kiosk_area.set_meta("system_tower_district_member", connect_to_district)
	kiosk_area.set_meta("system_tower_floor_directory", _get_tower_floor_directory(tower_id))
	kiosk_area.set_meta("system_display_name", title)
	kiosk_area.set_meta("system_interaction_prompt", "استخدم دليل " + title)
	var kiosk_shape := CollisionShape3D.new()
	var kiosk_sphere := SphereShape3D.new()
	kiosk_sphere.radius = 3.4
	kiosk_shape.shape = kiosk_sphere
	kiosk_area.add_child(kiosk_shape)
	lobby.add_child(kiosk_area)
	var reception_position := Vector3(-radius * 0.62, 1.7, center_z + 5.0)
	var reception := MeshInstance3D.new()
	reception.name = "LobbyReceptionCounter"
	var reception_mesh := BoxMesh.new()
	reception_mesh.size = Vector3(11.0, 3.4, 3.0)
	reception.mesh = reception_mesh
	reception.position = reception_position
	reception.material_override = trim_material
	lobby.add_child(reception)
	_add_static_box_collision(lobby, "LobbyReceptionCounter_Collision", reception_position, reception_mesh.size)
	var security_z := center_z - depth * 0.5 + 8.0
	for side in [-1.0, 1.0]:
		var gate_post_position := Vector3(side * 5.0, 4.0, security_z)
		_add_tower_identity_box(lobby, "LobbySecurityGatePost_%s" % str(side), gate_post_position, Vector3(0.8, 8.0, 0.8), emissive_material)
		_add_static_box_collision(lobby, "LobbySecurityGatePostCollision_%s" % str(side), gate_post_position, Vector3(0.8, 8.0, 0.8))
	var gate_header_position := Vector3(0.0, 8.0, security_z)
	_add_tower_identity_box(lobby, "LobbySecurityGateHeader", gate_header_position, Vector3(10.8, 0.8, 0.8), trim_material)
	var sign := Label3D.new()
	sign.name = "LobbyDirectorySign"
	sign.text = "SYSTEM TOWER DIRECTORY\n" + title + "\n" + "\n".join(_get_tower_floor_directory(tower_id))
	sign.font_size = 22
	sign.pixel_size = 0.012
	sign.position = Vector3(0.0, 10.0, center_z - depth * 0.5 + 4.0)
	sign.modulate = Color(0.78, 0.94, 1.0)
	lobby.add_child(sign)
	_create_lobby_media_panels(lobby, width, center_z, wall_height)
	lobby.set_meta("lobby_status", "enclosed_reception_lobby_blockout")
	lobby.set_meta("elevator_status", "not_implemented")
	lobby.set_meta("lift_door_visual_only", false)
	lobby.set_meta("lift_door_interactive", true)
	if tower_id == "hunter_association_tower_baghdad":
		_create_hunter_guild_recruitment(lobby, radius, center_z, front_z)


func _create_hunter_guild_recruitment(lobby: Node3D, radius: float, center_z: float, front_z: float) -> void:
	var arrival_zone := Area3D.new()
	arrival_zone.name = "HunterTowerRecruitmentArrivalZone"
	arrival_zone.set_meta("system_hunter_exam_arrival_zone", true)
	arrival_zone.position = Vector3(0.0, 1.4, front_z - 7.0)
	arrival_zone.monitoring = true
	arrival_zone.monitorable = true
	arrival_zone.collision_layer = 0
	arrival_zone.collision_mask = 1
	var arrival_shape := CollisionShape3D.new()
	var arrival_sphere := SphereShape3D.new()
	arrival_sphere.radius = 9.0
	arrival_shape.shape = arrival_sphere
	arrival_zone.add_child(arrival_shape)
	lobby.add_child(arrival_zone)

	var guide := Area3D.new()
	guide.name = "HunterGuildGuideAtTower"
	guide.add_to_group("system_interactable")
	guide.set_meta("system_hunter_exam_tower_guide", true)
	guide.set_meta("system_display_name", "مرشد نقابة الصيادين")
	guide.set_meta("system_interaction_prompt", "اتبع مرشد نقابة الصيادين إلى نفق الاختبار")
	guide.position = Vector3(-radius * 0.62, 0.0, center_z + 9.0)
	guide.collision_layer = 1
	guide.collision_mask = 0
	var guide_shape := CollisionShape3D.new()
	var guide_sphere := SphereShape3D.new()
	guide_sphere.radius = 3.2
	guide_shape.shape = guide_sphere
	guide_shape.position.y = 1.0
	guide.add_child(guide_shape)
	var guide_marker := MeshInstance3D.new()
	guide_marker.name = "GuildGuideCharacter"
	var guide_mesh := CapsuleMesh.new()
	guide_mesh.radius = 0.58
	guide_mesh.height = 2.25
	guide_marker.mesh = guide_mesh
	guide_marker.position.y = 1.12
	var guide_material := StandardMaterial3D.new()
	guide_material.albedo_color = Color(0.08, 0.22, 0.3)
	guide_material.emission_enabled = true
	guide_material.emission = Color(0.0, 0.3, 0.46)
	guide_material.emission_energy_multiplier = 0.65
	guide_marker.material_override = guide_material
	guide.add_child(guide_marker)
	var guide_label := Label3D.new()
	guide_label.name = "GuildGuideName"
	guide_label.text = "مرشد نقابة الصيادين"
	guide_label.position = Vector3(0.0, 2.7, 0.0)
	guide_label.font_size = 18
	guide_label.pixel_size = 0.012
	guide_label.modulate = Color(1.0, 0.82, 0.45)
	guide.add_child(guide_label)
	lobby.add_child(guide)
	lobby.set_meta("system_hunter_exam_recruitment_available", true)



func _get_tower_floor_directory(tower_id: String) -> PackedStringArray:
	match tower_id:
		"hunter_association_tower_baghdad":
			return PackedStringArray([
				"01-10: الاستقبال والتسجيل وخدمات الصيادين",
				"11-40: قاعات المهمات والنقابات وسجلات الإنجاز",
				"41-80: إدارة الاختبار العالمي والتدريب",
				"81-140: البحث والتطوير والدعم الطبي والاجتماعات",
				"141-200: الإدارة العليا وقاعة الشرف العالمية"
			])
		"business_investment_tower_baghdad":
			return PackedStringArray([
				"01-08: الاستقبال والخدمات المصرفية",
				"09-16: تأسيس الشركات والمكاتب التجارية",
				"17-24: الاستثمار والعقود وإدارة الأصول",
				"25-32: قاعات الصفقات ومراكز الأعمال",
				"33-36: مجلس الاستثمار والشركات الكبرى"
			])
		"shopping_tower_baghdad":
			return PackedStringArray([
				"01-04: السوق العام والاحتياجات ومتجر تصاريح المهارات",
				"05-07: معارض الأسلحة القريبة — السيوف والرماح والفؤوس والخناجر",
				"08-10: الأسلحة بعيدة المدى — الأقواس والنشّابات والمعدات الحديثة",
				"11-13: معارض الدروع والخوذ والدروع الواقية والملابس القتالية",
				"14: ورشة الحدادة الرئيسية — التصنيع والترقية والإصلاح",
				"15-16: المواد الخام وقطع التصنيع والوصفات",
				"17-19: صيدلية الأكاسير الأساسية والمؤقتة",
				"20-22: مركز إيقاظ النِن والتحكم والتدريب",
				"23-25: مختبر الأكاسير المتقدمة والمقيدة",
				"26: خزنة الأكاسير النادرة والأسطورية",
				"27: فندق SYSTEM — الاستقبال والحجوزات والصالة",
				"28: فندق SYSTEM — الغرف والأجنحة",
				"29-30: المطاعم العراقية والعربية والعالمية والمقاهي",
				"31-32: المطاعم الراقية والحلويات والمخابز"
			])
		"entertainment_tower_baghdad":
			return PackedStringArray([
				"01-08: الاستقبال والأنشطة العائلية",
				"09-16: الرياضات والصالات والبطولات",
				"17-22: المسابح والألعاب المائية",
				"23-30: الترفيه والألعاب والمهرجانات",
				"31-34: منصات المشاهدة والفعاليات الكبرى"
			])
		"technology_tower_baghdad":
			return PackedStringArray([
				"01-06: الاستقبال والمعارض التقنية",
				"07-14: الروبوتات والأنظمة الذكية",
				"15-22: الهندسة والطاقة والمواد",
				"23-30: المختبرات والبحث والتطوير",
				"31-36: الخدمات الرقمية وحاضنات الابتكار",
				"37-40: مركز القيادة والتجارب المتقدمة"
			])
		"power_tower_baghdad":
			return PackedStringArray([
				"001-009: ساحات التحديات المتدرجة",
				"010: زعيم الطابق",
				"011-199: دورات التحديات والبطولات",
				"200: التحدي النهائي"
			])
	return PackedStringArray()


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
	_create_tower_facade_glazing(root, height, radius, floors, beacon_color)
	_create_tower_identity_details(root, node_name, height, radius, beacon_color)


func _create_tower_facade_glazing(root: Node3D, height: float, radius: float, floors: int, accent_color: Color) -> void:
	const WINDOW_SEGMENTS := 20
	var glazing_mesh := BoxMesh.new()
	glazing_mesh.size = Vector3(4.4, 1.45, 0.2)
	var glazing_multimesh := MultiMesh.new()
	glazing_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	glazing_multimesh.mesh = glazing_mesh
	glazing_multimesh.instance_count = floors * WINDOW_SEGMENTS
	var instance_index := 0
	for floor_index in range(floors):
		var progress := float(floor_index) / float(maxi(floors - 1, 1))
		var taper := lerpf(1.0, 0.62, progress)
		var floor_height := 9.0 + (height - 16.0) * progress + 1.0
		var facade_radius := radius * taper + 0.16
		for segment_index in range(WINDOW_SEGMENTS):
			var angle := TAU * float(segment_index) / float(WINDOW_SEGMENTS)
			var outward := Vector3(cos(angle), 0.0, sin(angle))
			var orientation := Basis.looking_at(outward, Vector3.UP)
			var panel_position := outward * facade_radius + Vector3.UP * floor_height
			glazing_multimesh.set_instance_transform(instance_index, Transform3D(orientation, panel_position))
			instance_index += 1
	root.set_meta("system_facade_window_count", instance_index)
	root.set_meta("system_facade_window_segments_per_floor", WINDOW_SEGMENTS)
	root.set_meta("system_facade_window_floors", floors)
	root.set_meta("system_facade_window_base_radius", radius)
	var glass_material := _make_surface_material(Color(0.08, 0.34, 0.48, 0.78), 0.52, 0.2)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.emission_enabled = true
	glass_material.emission = accent_color.darkened(0.48)
	glass_material.emission_energy_multiplier = 0.18
	var glazing := MultiMeshInstance3D.new()
	glazing.name = "FacadeGlazingPanels"
	glazing.multimesh = glazing_multimesh
	glazing.material_override = glass_material
	root.add_child(glazing)


func _create_tower_identity_details(root: Node3D, node_name: String, height: float, radius: float, accent_color: Color) -> void:
	var accent := _make_surface_material(accent_color, 0.34, 0.72)
	var glow := _make_surface_material(accent_color.lightened(0.24), 0.22, 0.48)
	glow.emission_enabled = true
	glow.emission = accent_color
	glow.emission_energy_multiplier = 1.65
	match node_name:
		"HunterAssociationTower":
			# The former central S-spire is now the real, functional Hunter Association Tower.
			# Four large XSX identity plaques make the guild unmistakable from every approach.
			for side in range(4):
				var angle := TAU * float(side) / 4.0
				var outward := Vector3(cos(angle), 0.0, sin(angle))
				var plaque := Node3D.new()
				plaque.name = "HunterXSXEmblemPlaque_%02d" % side
				plaque.position = outward * (radius * 0.91) + Vector3(0.0, height * 0.56, 0.0)
				plaque.rotation.y = -angle - PI * 0.5
				root.add_child(plaque)
				_add_tower_identity_box(plaque, "XSXEmblemFrame", Vector3.ZERO, Vector3(34.0, 24.0, 1.8), trim_material)
				_add_tower_identity_box(plaque, "XSXEmblemFace", Vector3(0.0, 0.0, -1.05), Vector3(30.0, 20.0, 0.35), glow)
				var emblem := Label3D.new()
				emblem.name = "XSXEmblemText"
				emblem.text = "XSX"
				emblem.font_size = 150
				emblem.pixel_size = 0.035
				emblem.position = Vector3(0.0, -1.5, -1.35)
				emblem.modulate = Color(0.92, 0.84, 0.62)
				emblem.outline_size = 10
				emblem.outline_modulate = Color(0.025, 0.045, 0.08)
				plaque.add_child(emblem)
				var guild_title := Label3D.new()
				guild_title.name = "HunterGuildIdentity"
				guild_title.text = "نقابة الصيادين العالمية"
				guild_title.font_size = 34
				guild_title.pixel_size = 0.018
				guild_title.position = Vector3(0.0, -17.0, -1.4)
				guild_title.modulate = Color(0.78, 0.94, 1.0)
				plaque.add_child(guild_title)
			root.set_meta("system_hunter_guild_insignia", "XSX")
			root.set_meta("system_hunter_guild_identity_facades", 4)
			# Four diagonal roof masts frame the helipad from outside its clear landing circle.
			for mast_index in range(4):
				var mast_angle := TAU * (float(mast_index) + 0.5) / 4.0
				_add_tower_identity_box(
					root,
					"HunterRoofBeaconMast_%02d" % mast_index,
					Vector3(cos(mast_angle) * 30.0, height + 14.0, sin(mast_angle) * 30.0),
					Vector3(1.6, 12.0, 1.6),
					accent
				)
		"ShoppingTower":
			for level in range(3):
				var retail_ring := MeshInstance3D.new()
				retail_ring.name = "RetailGalleryRing_%02d" % level
				var ring_mesh := CylinderMesh.new()
				ring_mesh.top_radius = radius * (1.65 + float(level) * 0.16)
				ring_mesh.bottom_radius = radius * (1.65 + float(level) * 0.16)
				ring_mesh.height = 1.8
				retail_ring.mesh = ring_mesh
				retail_ring.position.y = 16.0 + float(level) * 8.0
				retail_ring.material_override = glow if level == 1 else accent
				root.add_child(retail_ring)
			_add_tower_identity_box(root, "ShoppingAtriumSign", Vector3(0.0, 35.0, -radius * 1.55), Vector3(radius * 1.7, 5.0, 1.0), glow)
			# The same tower showcases the armoury, elixir research and retail identity.
			for side in [-1.0, 1.0]:
				var blade := MeshInstance3D.new()
				blade.name = "ShoppingTowerWeaponBlade_%s" % str(side)
				var blade_mesh := BoxMesh.new()
				blade_mesh.size = Vector3(2.0, 24.0, 1.0)
				blade.mesh = blade_mesh
				blade.position = Vector3(side * 7.0, 24.0, -radius * 1.55)
				blade.rotation.z = side * deg_to_rad(30.0)
				blade.material_override = accent
				root.add_child(blade)
			_add_tower_identity_box(root, "ShoppingTowerElixirBeacon", Vector3(0.0, 44.0, radius * 1.48), Vector3(12.0, 2.0, 2.0), glow)
		"EntertainmentTower":
			var arena_bowl := MeshInstance3D.new()
			arena_bowl.name = "EntertainmentArenaBowl"
			var bowl_mesh := CylinderMesh.new()
			bowl_mesh.top_radius = radius * 1.9
			bowl_mesh.bottom_radius = radius * 1.45
			bowl_mesh.height = 5.0
			arena_bowl.mesh = bowl_mesh
			arena_bowl.position.y = 13.0
			arena_bowl.material_override = accent
			root.add_child(arena_bowl)
			_add_tower_identity_box(root, "EntertainmentEventScreen", Vector3(0.0, 31.0, -radius * 1.7), Vector3(radius * 1.5, 9.0, 1.0), glow)
			for side in [-1.0, 1.0]:
				_add_tower_identity_box(root, "RecreationArch_%s" % str(side), Vector3(side * radius * 1.2, 20.0, radius * 0.9), Vector3(2.0, 40.0, 2.0), glow)
		"TechnologyTower":
			for index in range(3):
				var antenna := MeshInstance3D.new()
				antenna.name = "InnovationAntenna_%02d" % index
				var antenna_mesh := CylinderMesh.new()
				antenna_mesh.top_radius = 0.55
				antenna_mesh.bottom_radius = 1.1
				antenna_mesh.height = 28.0 + float(index) * 7.0
				antenna.mesh = antenna_mesh
				antenna.position = Vector3((float(index) - 1.0) * radius * 0.7, height + 18.0 + float(index) * 3.0, 0.0)
				antenna.material_override = glow
				root.add_child(antenna)
			_add_tower_identity_box(root, "InnovationLabSkyRibbon", Vector3(0.0, height * 0.62, -radius * 1.4), Vector3(radius * 1.7, 2.0, 2.0), glow)
		"PowerTower":
			for side in [-1.0, 1.0]:
				_add_tower_identity_box(root, "TournamentBlade_%s" % str(side), Vector3(side * radius * 1.25, height * 0.48, 0.0), Vector3(3.0, height * 0.82, 3.0), accent)
			var champion_ring := MeshInstance3D.new()
			champion_ring.name = "PowerTowerChampionCrown"
			var champion_mesh := CylinderMesh.new()
			champion_mesh.top_radius = radius * 1.25
			champion_mesh.bottom_radius = radius * 1.25
			champion_mesh.height = 2.0
			champion_ring.mesh = champion_mesh
			champion_ring.position.y = height * 0.88
			champion_ring.material_override = glow
			root.add_child(champion_ring)


func _add_tower_identity_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _create_baghdad_upper_city_layer() -> void:
	if district_tower_positions.size() != 5:
		push_warning("SYSTEM WORLD: upper Baghdad city requires exactly five district towers.")
		return
	var city := Node3D.new()
	city.name = "BaghdadUpperSkyCity"
	city.position = Vector3(bridge_anchor.x, 0.0, bridge_anchor.y)
	city.set_meta("system_city_layer", "upper_sky_city")
	city.set_meta("system_district_tower_count", 5)
	city.set_meta("system_power_tower_excluded", true)
	add_child(city)
	var deck_material := _make_surface_material(Color(0.12, 0.19, 0.25), 0.62, 0.48)
	var trim := _make_surface_material(Color(0.72, 0.52, 0.25), 0.42, 0.72)
	var upper_positions: Array[Vector3] = []
	for record in district_tower_positions:
		if str(record.get("id", "")) == "hunter_association_tower_baghdad":
			continue
		var tower_position: Vector3 = record.get("position", Vector3.ZERO)
		var local := Vector3(tower_position.x - bridge_anchor.x, 0.0, tower_position.z - bridge_anchor.y)
		upper_positions.append(local)
		var block := Node3D.new()
		block.name = "UpperCityBlock_" + str(record.get("id", "tower"))
		block.position = Vector3(local.x, 270.0, local.z)
		block.set_meta("system_upper_city_tower_id", str(record.get("id", "")))
		city.add_child(block)
		var platform := MeshInstance3D.new()
		platform.name = "UpperCityPlatform"
		var platform_mesh := BoxMesh.new()
		platform_mesh.size = Vector3(170.0, 2.2, 145.0)
		platform.mesh = platform_mesh
		platform.material_override = deck_material
		block.add_child(platform)
		_add_static_box_collision(block, "UpperCityPlatformCollision", Vector3.ZERO, platform_mesh.size)
		for building_index in range(3):
			var building := MeshInstance3D.new()
			building.name = "UpperCityBuilding_%02d" % building_index
			var building_mesh := BoxMesh.new()
			var building_height := 18.0 + float((building_index + upper_positions.size()) % 3) * 7.0
			building_mesh.size = Vector3(24.0, building_height, 22.0)
			building.mesh = building_mesh
			building.position = Vector3(-48.0 + float(building_index) * 48.0, 1.1 + building_height * 0.5, -18.0 if building_index % 2 == 0 else 24.0)
			building.material_override = tower_material if building_index % 2 == 0 else trim
			block.add_child(building)
		var label := Label3D.new()
		label.name = "UpperCityDistrictSign"
		label.text = "BAGHDAD SKY CITY\nالمدينة العلوية"
		label.font_size = 22
		label.pixel_size = 0.012
		label.position = Vector3(0.0, 7.0, -62.0)
		label.modulate = Color(0.78, 0.94, 1.0)
		block.add_child(label)
	for index in range(upper_positions.size()):
		var first := upper_positions[index] + Vector3(0.0, 272.0, 0.0)
		var second := upper_positions[(index + 1) % upper_positions.size()] + Vector3(0.0, 272.0, 0.0)
		_create_link_deck(city, first, second, "UpperCitySkyway_%02d" % index, 22.0, 1.5, trim)
		_create_bridge_edge_details(city, first, second, "UpperCitySkyway_%02d" % index, 22.0, emissive_material)
	var hunter_atrium := MeshInstance3D.new()
	hunter_atrium.name = "HunterTowerUpperCityAtriumRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 62.0
	ring_mesh.outer_radius = 78.0
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 12
	hunter_atrium.mesh = ring_mesh
	hunter_atrium.position = Vector3(0.0, 270.0, 0.0)
	hunter_atrium.material_override = trim
	city.add_child(hunter_atrium)
	var atrium_walkways := [
		{"name": "North", "position": Vector3(0.0, 270.0, 70.0), "size": Vector3(140.0, 1.6, 28.0)},
		{"name": "South", "position": Vector3(0.0, 270.0, -70.0), "size": Vector3(140.0, 1.6, 28.0)},
		{"name": "East", "position": Vector3(70.0, 270.0, 0.0), "size": Vector3(28.0, 1.6, 140.0)},
		{"name": "West", "position": Vector3(-70.0, 270.0, 0.0), "size": Vector3(28.0, 1.6, 140.0)}
	]
	for walkway_spec in atrium_walkways:
		var walkway := MeshInstance3D.new()
		walkway.name = "HunterAtriumWalkway_" + str(walkway_spec["name"])
		var walkway_mesh := BoxMesh.new()
		walkway_mesh.size = walkway_spec["size"]
		walkway.mesh = walkway_mesh
		walkway.position = walkway_spec["position"]
		walkway.material_override = deck_material
		city.add_child(walkway)
		_add_static_box_collision(city, walkway.name + "_Collision", walkway.position, walkway_mesh.size)
	for index in range(upper_positions.size()):
		var destination: Vector3 = upper_positions[index]
		var outward := Vector3(destination.x, 0.0, destination.z).normalized()
		var skyway_start := outward * 82.0 + Vector3(0.0, 272.0, 0.0)
		var skyway_end := destination + Vector3(0.0, 272.0, 0.0)
		_create_link_deck(city, skyway_start, skyway_end, "HunterAtriumSkyway_%02d" % index, 18.0, 1.5, trim)
		_create_bridge_edge_details(city, skyway_start, skyway_end, "HunterAtriumSkyway_%02d" % index, 18.0, emissive_material)
	_create_reference_city_architecture(city)
	city.set_meta("system_upper_city_blocks", upper_positions.size())
	city.set_meta("system_upper_city_elevation_m", 270.0)


func _create_reference_city_architecture(city: Node3D) -> void:
	# Visual expansion based on the user-approved Baghdad skyline reference:
	# broad circular sky platforms and glass skyline towers; the functional Hunter Association Tower is the central landmark.
	# This is a visual city layer; it does not create extra functional district towers.
	var platform_material := _make_surface_material(Color(0.055, 0.16, 0.23), 0.24, 0.72)
	platform_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	platform_material.albedo_color.a = 0.92
	var edge_material := _make_surface_material(Color(0.10, 0.62, 0.82), 0.2, 0.68)
	edge_material.emission_enabled = true
	edge_material.emission = Color(0.015, 0.32, 0.58)
	edge_material.emission_energy_multiplier = 1.5
	var platform_specs := [
		{"name": "ReferenceSkyPlatform_Lower", "radius": 238.0, "height": 3.2, "y": 310.0},
		{"name": "ReferenceSkyPlatform_Middle", "radius": 178.0, "height": 2.8, "y": 365.0},
		{"name": "ReferenceSkyPlatform_Upper", "radius": 116.0, "height": 2.4, "y": 418.0}
	]
	for spec in platform_specs:
		var platform := MeshInstance3D.new()
		platform.name = str(spec["name"])
		var platform_mesh := CylinderMesh.new()
		platform_mesh.top_radius = float(spec["radius"])
		platform_mesh.bottom_radius = float(spec["radius"]) * 0.985
		platform_mesh.height = float(spec["height"])
		platform.mesh = platform_mesh
		platform.position.y = float(spec["y"])
		platform.material_override = platform_material
		city.add_child(platform)
		var rim := MeshInstance3D.new()
		rim.name = str(spec["name"]) + "_LuminousRim"
		var rim_mesh := TorusMesh.new()
		rim_mesh.inner_radius = float(spec["radius"]) - 1.2
		rim_mesh.outer_radius = float(spec["radius"]) + 0.8
		rim_mesh.rings = 48
		rim_mesh.ring_segments = 12
		rim.mesh = rim_mesh
		rim.rotation.x = PI * 0.5
		rim.position.y = float(spec["y"]) + float(spec["height"]) * 0.5
		rim.material_override = edge_material
		city.add_child(rim)
		# Continuous illuminated safety rail and evenly spaced structural balusters around each floating deck.
		var guardrail := MeshInstance3D.new()
		guardrail.name = str(spec["name"]) + "_PerimeterGuardrail"
		var guardrail_mesh := TorusMesh.new()
		guardrail_mesh.inner_radius = float(spec["radius"]) - 4.35
		guardrail_mesh.outer_radius = float(spec["radius"]) - 3.65
		guardrail_mesh.rings = 64
		guardrail_mesh.ring_segments = 12
		guardrail.mesh = guardrail_mesh
		guardrail.rotation.x = PI * 0.5
		guardrail.position.y = float(spec["y"]) + float(spec["height"]) * 0.5 + 1.45
		guardrail.material_override = edge_material
		city.add_child(guardrail)
		var baluster_material := _make_surface_material(Color(0.12, 0.22, 0.29), 0.28, 0.84)
		for baluster_index in range(32):
			var baluster_angle := TAU * float(baluster_index) / 32.0
			var baluster := MeshInstance3D.new()
			baluster.name = str(spec["name"]) + "_GuardrailBaluster_%02d" % baluster_index
			var baluster_mesh := CylinderMesh.new()
			baluster_mesh.top_radius = 0.22
			baluster_mesh.bottom_radius = 0.34
			baluster_mesh.height = 2.6
			baluster.mesh = baluster_mesh
			baluster.position = Vector3(cos(baluster_angle) * (float(spec["radius"]) - 4.0), float(spec["y"]) + float(spec["height"]) * 0.5 + 1.3, sin(baluster_angle) * (float(spec["radius"]) - 4.0))
			baluster.material_override = baluster_material
			city.add_child(baluster)
		platform.set_meta("system_platform_safety_railings", true)
		platform.set_meta("system_platform_guardrail_balusters", 32)
		platform.set_meta("system_reference_design_element", "multi_level_circular_sky_platform")
	var support_material := _make_surface_material(Color(0.12, 0.22, 0.29), 0.3, 0.82)
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var support := MeshInstance3D.new()
		support.name = "SkyPlatformSupport_%02d" % index
		var support_mesh := CylinderMesh.new()
		support_mesh.top_radius = 2.2
		support_mesh.bottom_radius = 4.0
		support_mesh.height = 38.0
		support.mesh = support_mesh
		support.position = Vector3(cos(angle) * 220.0, 291.0, sin(angle) * 220.0)
		support.material_override = support_material
		city.add_child(support)
	var glass_material := _make_surface_material(Color(0.035, 0.22, 0.34), 0.16, 0.62)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color.a = 0.84
	var skyline_specs := [
		{"angle": 0.0, "radius": 192.0, "height": 76.0, "width": 18.0},
		{"angle": 0.62, "radius": 214.0, "height": 54.0, "width": 15.0},
		{"angle": 1.24, "radius": 188.0, "height": 92.0, "width": 17.0},
		{"angle": 1.88, "radius": 218.0, "height": 63.0, "width": 14.0},
		{"angle": 2.51, "radius": 194.0, "height": 84.0, "width": 16.0},
		{"angle": 3.14, "radius": 216.0, "height": 58.0, "width": 15.0},
		{"angle": 3.77, "radius": 190.0, "height": 98.0, "width": 18.0},
		{"angle": 4.40, "radius": 218.0, "height": 68.0, "width": 14.0},
		{"angle": 5.03, "radius": 196.0, "height": 88.0, "width": 17.0},
		{"angle": 5.66, "radius": 214.0, "height": 60.0, "width": 15.0}
	]
	for index in range(skyline_specs.size()):
		var spec: Dictionary = skyline_specs[index]
		var angle := float(spec["angle"])
		var radius := float(spec["radius"])
		var height := float(spec["height"])
		var width := float(spec["width"])
		var tower := Node3D.new()
		tower.name = "ReferenceGlassSkylineTower_%02d" % index
		tower.position = Vector3(cos(angle) * radius, 312.0, sin(angle) * radius)
		city.add_child(tower)
		var shaft := MeshInstance3D.new()
		shaft.name = "GlassShaft"
		var shaft_mesh := BoxMesh.new()
		shaft_mesh.size = Vector3(width, height, width * 0.78)
		shaft.mesh = shaft_mesh
		shaft.position.y = height * 0.5
		shaft.material_override = glass_material
		tower.add_child(shaft)
		var crown := MeshInstance3D.new()
		crown.name = "IlluminatedCrown"
		var crown_mesh := PrismMesh.new()
		crown_mesh.size = Vector3(width * 1.18, height * 0.16, width * 0.92)
		crown.mesh = crown_mesh
		crown.position.y = height + crown_mesh.size.y * 0.5
		crown.material_override = edge_material
		tower.add_child(crown)
		var vertical_light := MeshInstance3D.new()
		vertical_light.name = "BlueVerticalLight"
		var light_mesh := BoxMesh.new()
		light_mesh.size = Vector3(0.55, height * 0.82, 0.32)
		vertical_light.mesh = light_mesh
		vertical_light.position = Vector3(width * 0.5 + 0.32, height * 0.5, 0.0)
		vertical_light.material_override = emissive_material
		tower.add_child(vertical_light)
	# The former decorative S-spire has been removed. The functional Hunter Association
	# Tower now occupies this central crown position above the upper-city platforms.
	city.set_meta("system_central_landmark_tower_id", "hunter_association_tower_baghdad")
	city.set_meta("system_central_landmark_insignia", "XSX")
	city.set_meta("system_reference_sky_platform_count", platform_specs.size())
	city.set_meta("system_reference_glass_tower_count", skyline_specs.size())
	city.set_meta("system_reference_visual_profile", "approved_baghdad_towers_image")


func _create_connected_city_links() -> void:
	# Elevated pedestrian/vehicle corridor blockout linking only the five district towers.
	# Keep the route in a perimeter sequence; the previous creation order crossed
	# the district diagonally between opposite towers.
	# The standalone Power Tower is deliberately excluded from this network.
	var ordered_tower_ids := [
		"hunter_association_tower_baghdad",
		"business_investment_tower_baghdad",
		"entertainment_tower_baghdad",
		"shopping_tower_baghdad",
		"technology_tower_baghdad"
	]
	var ordered_positions: Array[Vector3] = []
	for tower_id in ordered_tower_ids:
		for tower_data in district_tower_positions:
			if str(tower_data.get("id", "")) == tower_id:
				ordered_positions.append(tower_data["position"])
				break
	if ordered_positions.size() < 2:
		push_warning("SYSTEM WORLD: Baghdad connected district needs at least two placed towers.")
		return
	var link_root := Node3D.new()
	link_root.name = "BaghdadFiveTowerConnectedDistrict"
	add_child(link_root)
	for index in range(ordered_positions.size()):
		var first: Vector3 = ordered_positions[index]
		var second: Vector3 = ordered_positions[(index + 1) % ordered_positions.size()]
		var promenade_start := first + Vector3(0.0, 34.0, 0.0)
		var promenade_end := second + Vector3(0.0, 34.0, 0.0)
		_create_link_deck(link_root, promenade_start, promenade_end, "SkyPromenade_%d" % index, 12.0, 0.65, trim_material)
		_create_bridge_edge_details(link_root, promenade_start, promenade_end, "SkyPromenade_%d" % index, 12.0, emissive_material)
		_create_link_deck(link_root, first + Vector3(0.0, 23.0, 0.0), second + Vector3(0.0, 23.0, 0.0), "VehicleDeck_%d" % index, 18.0, 1.1, tower_material)
		_create_vehicle_access_ramp(link_root, first, index)


func _create_bridge_edge_details(parent: Node3D, start: Vector3, finish: Vector3, bridge_name: String, deck_width: float, light_material: Material) -> void:
	# Architectural pedestrian safety rails and low-profile guide lights for elevated promenades.
	var delta := finish - start
	var bridge_length := delta.length()
	if bridge_length < 4.0:
		return
	var angle := atan2(delta.x, delta.z)
	var side_axis := Vector3(cos(angle), 0.0, -sin(angle))
	var post_count := clampi(int(ceil(bridge_length / 32.0)), 4, 24)
	var edge_offset := deck_width * 0.5 - 0.45
	var rail_material := _make_surface_material(Color(0.055, 0.12, 0.17), 0.34, 0.78)
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.name = bridge_name + ("_LeftSafetyRail" if side < 0.0 else "_RightSafetyRail")
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(0.42, 0.22, bridge_length)
		rail.mesh = rail_mesh
		rail.position = (start + finish) * 0.5 + side_axis * edge_offset + Vector3(0.0, 1.12, 0.0)
		rail.rotation.y = angle
		rail.material_override = rail_material
		parent.add_child(rail)
		for post_index in range(post_count + 1):
			var progress := float(post_index) / float(post_count)
			var post := MeshInstance3D.new()
			post.name = bridge_name + "_RailPost_%s_%02d" % ["L" if side < 0.0 else "R", post_index]
			var post_mesh := CylinderMesh.new()
			post_mesh.top_radius = 0.16
			post_mesh.bottom_radius = 0.24
			post_mesh.height = 1.18
			post.mesh = post_mesh
			post.position = start.lerp(finish, progress) + side_axis * edge_offset + Vector3(0.0, 0.68, 0.0)
			post.material_override = rail_material
			parent.add_child(post)
			if post_index % 3 == 0:
				var guide_light := MeshInstance3D.new()
				guide_light.name = bridge_name + "_GuideLight_%s_%02d" % ["L" if side < 0.0 else "R", post_index]
				var light_mesh := SphereMesh.new()
				light_mesh.radius = 0.22
				light_mesh.height = 0.44
				guide_light.mesh = light_mesh
				guide_light.position = post.position + Vector3(0.0, 0.72, 0.0)
				guide_light.material_override = light_material
				parent.add_child(guide_light)


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
		deck.position = Vector3(bridge_anchor.x, 0.0, bridge_anchor.y) + spec["offset"]
		deck.material_override = spec["material"]
		amenities.add_child(deck)
	amenities.set_meta("planned_facilities", PackedStringArray(["parks", "restaurants", "cafes", "hotels", "cinema", "amusement_park", "water_park", "swimming_pools", "sports_courts", "family_services", "parking", "emergency_access"]))
	_create_multilevel_parking_blockout(amenities)
	_create_vertical_access_blockout(amenities)


func _create_multilevel_parking_blockout(parent: Node3D) -> void:
	var garage := Node3D.new()
	garage.name = "ConnectedDistrictParkingGarage_Blockout"
	garage.position = Vector3(bridge_anchor.x, 0.0, bridge_anchor.y) + Vector3(112.0, 0.0, 24.0)
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
	access.position = Vector3(bridge_anchor.x, 0.0, bridge_anchor.y) + Vector3(-112.0, 0.0, 24.0)
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
	collision.name = "CollisionShape3D"
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



func _create_lobby_media_panels(lobby: Node3D, lobby_width: float, center_z: float, wall_height: float) -> void:
	# Two-sided indoor media: a curated campaign screen and a local champion/results screen.
	# Panels are attached to the inner faces of the lobby side walls, not floating UI.
	var frame_material := _make_surface_material(Color(0.025, 0.045, 0.065), 0.28, 0.62)
	var ad_material := _make_surface_material(Color(0.015, 0.12, 0.18), 0.22, 0.35)
	var result_material := _make_surface_material(Color(0.15, 0.095, 0.025), 0.24, 0.42)
	ad_material.emission_enabled = true
	ad_material.emission = Color(0.02, 0.42, 0.62)
	ad_material.emission_energy_multiplier = 1.4
	result_material.emission_enabled = true
	result_material.emission = Color(0.62, 0.36, 0.06)
	result_material.emission_energy_multiplier = 1.15
	for side in [-1.0, 1.0]:
		var inward_rotation := -PI * 0.5 if side < 0.0 else PI * 0.5
		var wall_x: float = side * (lobby_width * 0.5 - 0.62)
		for panel_index in range(2):
			var is_advertising := panel_index == 0
			var panel_name := "InteriorAdvertising" if is_advertising else "InteriorChampionResults"
			var panel_y := 8.0 if is_advertising else 3.8
			var panel_size := Vector3(0.42, 3.25, minf(10.0, lobby_width * 0.34))
			var frame := MeshInstance3D.new()
			frame.name = panel_name + "Frame_" + ("Left" if side < 0.0 else "Right")
			var frame_mesh := BoxMesh.new()
			frame_mesh.size = panel_size
			frame.mesh = frame_mesh
			frame.position = Vector3(wall_x, panel_y, center_z)
			frame.rotation.y = inward_rotation
			frame.material_override = frame_material
			lobby.add_child(frame)
			var surface := MeshInstance3D.new()
			surface.name = panel_name + "Surface_" + ("Left" if side < 0.0 else "Right")
			var surface_mesh := BoxMesh.new()
			surface_mesh.size = Vector3(0.12, panel_size.y - 0.3, panel_size.z - 0.3)
			surface.mesh = surface_mesh
			surface.position = frame.position + Vector3(-side * 0.24, 0.0, 0.0)
			surface.rotation.y = inward_rotation
			surface.material_override = ad_material if is_advertising else result_material
			lobby.add_child(surface)
			var label := Label3D.new()
			label.name = panel_name + "Text_" + ("Left" if side < 0.0 else "Right")
			if is_advertising:
				label.text = "SYSTEM BAGHDAD\nحملة داخلية تجريبية\nمساحة إعلانية رقمية"
				label.modulate = Color(0.78, 0.96, 1.0)
			else:
				label.text = "SYSTEM CHAMPIONS\nإنجازات البرج\nالنتائج المحلية فقط"
				label.modulate = Color(1.0, 0.88, 0.55)
			label.font_size = 24
			label.pixel_size = 0.012
			label.outline_size = 7
			label.position = surface.position + Vector3(-side * 0.1, 0.0, 0.0)
			label.rotation.y = inward_rotation
			lobby.add_child(label)
			label.set_meta("media_scope", "baghdad_tower_interior_lobby")
			label.set_meta("media_type", "curated_demo" if is_advertising else "local_event_results")
