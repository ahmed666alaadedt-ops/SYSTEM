extends Node3D
class_name BaghdadTowerLandmarksManager

const EntranceScript = preload("res://scripts/system_tower_entrance.gd")
const HunterHelicopterControllerScript = preload("res://scripts/system_hunter_helicopter_pad_controller.gd")
const HUNTER_TOWER_HEIGHT := 1000.0
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
	var position := Vector3(bridge_anchor.x, 0.0, bridge_anchor.y)
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
	for side in range(4):
		var angle := TAU * float(side) / 4.0
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		for level in [220.0, 520.0, 800.0]:
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
		root_height = 0.0
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
	root.set_meta("system_placement_source", "verified_republic_bridge_osm" if allow_bridge_platform else "verified_baghdad_bridge_riverbank_terrain")
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
	print("SYSTEM WORLD: landmark tower generated: ", title, " / ", floors, " floors / ", height, "m")


func _create_hunter_exam_tunnel() -> void:
	# Secret Hunter Examination entrance hidden beneath the Baghdad five-tower district.
	# No exposed ramp, portal frame, or public tunnel sign is shown before the riddle is solved.
	var tunnel_root := Node3D.new()
	tunnel_root.name = "BaghdadHunterExaminationTunnel"
	tunnel_root.position = Vector3(
		bridge_anchor.x,
		float(terrain.call("get_terrain_height", bridge_anchor.x, bridge_anchor.y)),
		bridge_anchor.y
	)
	tunnel_root.set_meta("system_under_republic_bridge", true)
	tunnel_root.set_meta("system_tunnel_location_source", "OpenStreetMap Republic Bridge / Tigris reference")
	tunnel_root.set_meta("system_facility_type", "hunter_examination_tunnel")
	tunnel_root.set_meta("system_under_baghdad_tower_district", true)
	tunnel_root.set_meta("system_exam_manager", "SYSTEMHunterExamManager")
	tunnel_root.set_meta("system_tunnel_riddle_progress", 0)
	tunnel_root.set_meta("system_tunnel_riddle_solved", false)
	add_child(tunnel_root)

	var stone_material := _make_surface_material(Color(0.16, 0.18, 0.19), 0.94, 0.08)
	var carved_material := _make_surface_material(Color(0.24, 0.29, 0.30), 0.82, 0.12)
	var hidden_trim := _make_surface_material(Color(0.025, 0.20, 0.25), 0.42, 0.5)
	hidden_trim.emission_enabled = true
	hidden_trim.emission = Color(0.0, 0.34, 0.48)
	hidden_trim.emission_energy_multiplier = 0.65

	# The concealed wall resembles ordinary foundation masonry. Its door seam
	# is intentionally indistinguishable until the three-symbol riddle is solved.
	var wall := MeshInstance3D.new()
	wall.name = "OrdinaryFoundationMasonry"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(22.0, 16.0, 2.4)
	wall.mesh = wall_mesh
	wall.position = Vector3(0.0, -7.5, 96.0)
	wall.material_override = stone_material
	tunnel_root.add_child(wall)
	_add_static_box_collision(tunnel_root, "FoundationMasonryCollision", wall.position, wall_mesh.size)

	var hidden_door := MeshInstance3D.new()
	hidden_door.name = "ConcealedHunterDoorSlab"
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(13.5, 11.5, 0.65)
	hidden_door.mesh = door_mesh
	hidden_door.position = Vector3(0.0, -8.0, 94.65)
	hidden_door.material_override = stone_material
	tunnel_root.add_child(hidden_door)
	_add_static_box_collision(tunnel_root, "ConcealedDoorCollision", hidden_door.position, door_mesh.size)

	# Three low-profile clue stones are scattered around the public district.
	# They look like ordinary paving details; each can be examined up close.
	var clue_positions := [
		Vector3(-34.0, 0.12, 18.0),
		Vector3(28.0, 0.12, -26.0),
		Vector3(4.0, 0.12, 70.0)
	]
	var clue_symbols := ["عين", "نهر", "تاج"]
	for index in range(3):
		var clue := Area3D.new()
		clue.name = "HunterRiddleClue_%d" % (index + 1)
		clue.add_to_group("system_interactable")
		clue.set_meta("system_hunter_tunnel_riddle_step", index + 1)
		clue.set_meta("system_display_name", "نقش حجري قديم")
		clue.set_meta("system_interaction_prompt", "تفحّص النقش الحجري")
		var clue_local: Vector3 = clue_positions[index]
		var clue_world_x := bridge_anchor.x + clue_local.x
		var clue_world_z := bridge_anchor.y + clue_local.z
		clue_local.y = float(terrain.call("get_terrain_height", clue_world_x, clue_world_z)) - tunnel_root.position.y + 0.12
		clue.position = clue_local
		clue.collision_layer = 1
		clue.collision_mask = 0
		var stone := MeshInstance3D.new()
		stone.name = "WeatheredClueStone"
		var stone_mesh := BoxMesh.new()
		stone_mesh.size = Vector3(2.8, 0.24, 2.8)
		stone.mesh = stone_mesh
		stone.material_override = carved_material
		clue.add_child(stone)
		var glyph := Label3D.new()
		glyph.name = "WornGlyph"
		glyph.text = clue_symbols[index]
		glyph.font_size = 18
		glyph.pixel_size = 0.012
		glyph.position = Vector3(0.0, 0.16, 0.0)
		glyph.modulate = Color(0.48, 0.57, 0.57, 0.72)
		clue.add_child(glyph)
		var clue_shape := CollisionShape3D.new()
		var clue_sphere := SphereShape3D.new()
		clue_sphere.radius = 3.0
		clue_shape.shape = clue_sphere
		clue_shape.position = Vector3(0.0, 1.0, 0.0)
		clue.add_child(clue_shape)
		tunnel_root.add_child(clue)

	# The final interaction is on the blank masonry. It reveals no prompt until
	# the player has found the clues in the correct order.
	var entrance := Area3D.new()
	entrance.name = "ConcealedHunterExamDoor"
	entrance.add_to_group("system_interactable")
	entrance.set_meta("system_hunter_exam_tunnel", true)
	entrance.set_meta("system_facility_type", "hunter_examination_tunnel")
	entrance.set_meta("system_display_name", "باب حجري قديم")
	entrance.set_meta("system_interaction_prompt", "افحص الجدار الحجري")
	entrance.position = Vector3(0.0, 0.0, 88.0)
	entrance.collision_layer = 1
	entrance.collision_mask = 0
	var entrance_shape := CollisionShape3D.new()
	var entrance_sphere := SphereShape3D.new()
	entrance_sphere.radius = 5.0
	entrance_shape.shape = entrance_sphere
	entrance.add_child(entrance_shape)
	tunnel_root.add_child(entrance)

	# The descending passage exists behind the concealed door and is revealed
	# only after solving the riddle.
	var passage_material := _make_surface_material(Color(0.055, 0.09, 0.12), 0.9, 0.2)
	for segment in range(10):
		var t0 := float(segment) / 10.0
		var t1 := float(segment + 1) / 10.0
		var ramp := MeshInstance3D.new()
		ramp.name = "HiddenExamPassageRamp_%02d" % segment
		var ramp_mesh := BoxMesh.new()
		ramp_mesh.size = Vector3(14.0, 0.65, 9.0)
		ramp.mesh = ramp_mesh
		var a := Vector3(0.0, -1.0 - t0 * 16.0, 100.0 + t0 * 90.0)
		var b := Vector3(0.0, -1.0 - t1 * 16.0, 100.0 + t1 * 90.0)
		ramp.position = (a + b) * 0.5
		ramp.rotation.x = -atan2(b.y - a.y, b.z - a.z)
		ramp.material_override = passage_material
		ramp.visible = false
		tunnel_root.add_child(ramp)
		_add_static_box_collision(tunnel_root, ramp.name + "_Collision", ramp.position, ramp_mesh.size)
		var ramp_body := tunnel_root.get_node_or_null(ramp.name + "_Collision") as StaticBody3D
		if ramp_body != null:
			ramp_body.rotation.x = ramp.rotation.x
		var ramp_collision := tunnel_root.get_node_or_null(ramp.name + "_Collision/CollisionShape3D") as CollisionShape3D
		if ramp_collision != null:
			ramp_collision.disabled = true

	var light := OmniLight3D.new()
	light.name = "SecretDoorRevealLight"
	light.position = Vector3(0.0, -4.0, 91.0)
	light.light_color = Color(0.04, 0.62, 0.9)
	light.light_energy = 0.0
	light.omni_range = 18.0
	tunnel_root.add_child(light)

	tunnel_root.set_meta("system_tunnel_riddle_order", PackedInt32Array([1, 2, 3]))
	tunnel_root.set_meta("system_tunnel_clue_count", 3)
	tunnel_root.set_meta("system_tunnel_hidden_door", true)
	tunnel_root.set_meta("system_tunnel_interaction_ready", true)
	print("SYSTEM WORLD: concealed Hunter Examination riddle door prepared beneath Baghdad district.")

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
				"01-06: السوق الرئيسي والاحتياجات والمتاجر",
				"07-14: الأسلحة الحديثة والتقليدية والدروع والورش",
				"15-20: الأزياء والتجهيزات والتطوير والصيانة",
				"21-26: صيدليات الإكسير ومختبرات النِن والعلاج",
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
			for side in [-1.0, 1.0]:
				_add_tower_identity_box(root, "AssociationWing_%s" % str(side), Vector3(side * radius * 1.48, 15.0, 0.0), Vector3(radius * 0.62, 30.0, radius * 0.82), tower_material, Vector3(0.0, 0.0, side * -0.10))
				_add_tower_identity_box(root, "HonorHallPillar_%s" % str(side), Vector3(side * radius * 1.12, 27.0, -radius * 0.62), Vector3(2.8, 54.0, 2.8), trim_material)
			_add_tower_identity_box(root, "AssociationHonorLintel", Vector3(0.0, 54.0, -radius * 0.62), Vector3(radius * 2.35, 3.0, 3.0), glow)
			_add_tower_identity_box(root, "AssociationCrownSpire", Vector3(0.0, height + 34.0, 0.0), Vector3(5.0, 68.0, 5.0), accent)
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
	city.set_meta("system_upper_city_blocks", upper_positions.size())
	city.set_meta("system_upper_city_elevation_m", 270.0)


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
