extends Node3D
class_name BaghdadMarshlandManager

## Replaces the Al-Zawraa Park gameplay footprint with a traversable marsh biome.
## The marsh anchor is the published Al-Zawraa Park WGS84 location, projected
## through the same Baghdad regional origin used by the Republic Bridge.

const PARK_LATITUDE := 33.31496
const PARK_LONGITUDE := 44.37818
const MARSH_RADIUS_X := 980.0
const MARSH_RADIUS_Z := 975.0
const CONNECTOR_SEGMENT_LENGTH := 60.0
const HUNTER_MARSH_SEASONS := ["spring", "summer", "autumn", "winter"]
const SEASONAL_GATE_DESTINATIONS := {
	"spring": ["Tokyo", "Paris", "Singapore"],
	"summer": ["Cairo", "Sydney", "Guangzhou"],
	"autumn": ["London", "Seoul", "New York"],
	"winter": ["Moscow", "New Delhi", "Rio de Janeiro"]
}

var terrain: Node
var marsh_center := Vector3.ZERO
var tunnel_connector_length := 0.0
var marsh_entry_local := Vector3(-420.0, 0.0, -15.0)
var hidden_gates_unlocked := false


func _process(_delta: float) -> void:
	if hidden_gates_unlocked:
		return
	var exam_manager := get_tree().root.find_child("SYSTEMHunterExamManager", true, false)
	if exam_manager == null or not bool(exam_manager.get("registered")):
		return
	var completed_exam_segments: Array = exam_manager.get("completed_stage_ids")
	if not completed_exam_segments.has("baghdad_tunnel_competition"):
		return
	for gate in find_children("SeasonalMarshStarGate_*", "Node3D", true, false):
		gate.visible = true
		gate.set_meta("system_hidden_until_final_exam_discovery", false)
	hidden_gates_unlocked = true
	set_meta("system_hidden_heritage_site_discovered", true)
	print("SYSTEM Hunter Exam: hidden marsh sanctuary and seasonal Star Gates discovered.")


func setup(terrain_node: Node, hunter_tunnel: Node3D) -> void:
	terrain = terrain_node
	if terrain == null or not is_instance_valid(hunter_tunnel):
		push_error("SYSTEM Baghdad Marshland: terrain or Hunter tunnel is missing.")
		return
	var projected: Vector3 = SystemRealWorldGeography.to_local_world_position(
		"iraq_baghdad_region", PARK_LATITUDE, PARK_LONGITUDE, 0.0
	)
	if projected == Vector3.ZERO:
		push_error("SYSTEM Baghdad Marshland: Al-Zawraa geographic anchor could not be projected.")
		return
	var park_ground_y := float(terrain.call("get_terrain_height", projected.x, projected.z))
	marsh_center = Vector3(projected.x, park_ground_y, projected.z)
	var tunnel_end_for_entry := hunter_tunnel.global_position + Vector3(0.0, 0.0, 39.0)
	var entry_direction := Vector2(marsh_center.x - tunnel_end_for_entry.x, marsh_center.z - tunnel_end_for_entry.z).normalized()
	marsh_entry_local = Vector3(-entry_direction.x * 420.0, 0.0, -entry_direction.y * 420.0)
	global_position = Vector3.ZERO
	name = "BaghdadMarshland_AlZawraaReplacement"
	set_meta("system_region_id", "baghdad_marshland_al_zawraa")
	set_meta("system_replaces_real_place", "Al-Zawraa Park, Baghdad")
	set_meta("system_anchor_latitude", PARK_LATITUDE)
	set_meta("system_anchor_longitude", PARK_LONGITUDE)
	set_meta("system_biome", "mesopotamian_marshland")
	set_meta("system_playable_area_dimensions_m", Vector2(MARSH_RADIUS_X * 2.0, MARSH_RADIUS_Z * 2.0))
	set_meta("system_hunter_tunnel_connected", false)
	_build_marshland()
	_build_hunter_tunnel_connection(hunter_tunnel)
	set_meta("system_hunter_tunnel_connected", tunnel_connector_length > 0.0)
	set_meta("system_hunter_tunnel_connection_length_m", tunnel_connector_length)
	set_meta("system_marshland_runtime_status", "procedural_marshland_with_physical_tunnel_connection")


func _build_marshland() -> void:
	var water_material := _make_material(Color(0.055, 0.24, 0.20, 0.88), 0.12, 0.08, true)
	var mud_material := _make_material(Color(0.19, 0.16, 0.095), 0.98, 0.0)
	var reed_material := _make_material(Color(0.24, 0.36, 0.13), 0.92, 0.0)
	var wood_material := _make_material(Color(0.30, 0.20, 0.11), 0.82, 0.0)
	var lily_material := _make_material(Color(0.20, 0.48, 0.30), 0.48, 0.0)

	var zone := Node3D.new()
	zone.name = "MesopotamianMarshland"
	zone.position = marsh_center
	add_child(zone)

	var shore := MeshInstance3D.new()
	shore.name = "MarshMudShore"
	var shore_mesh := CylinderMesh.new()
	shore_mesh.top_radius = 1.0
	shore_mesh.bottom_radius = 1.0
	shore_mesh.height = 0.34
	shore.mesh = shore_mesh
	shore.scale = Vector3(MARSH_RADIUS_X, 1.0, MARSH_RADIUS_Z)
	shore.position.y = 0.12
	shore.material_override = mud_material
	zone.add_child(shore)

	var pond_specs := [
		{"x": -250.0, "z": -120.0, "rx": 94.0, "rz": 66.0},
		{"x": -85.0, "z": -220.0, "rx": 72.0, "rz": 104.0},
		{"x": 110.0, "z": -150.0, "rx": 108.0, "rz": 72.0},
		{"x": 270.0, "z": -45.0, "rx": 76.0, "rz": 112.0},
		{"x": 180.0, "z": 190.0, "rx": 112.0, "rz": 74.0},
		{"x": -35.0, "z": 205.0, "rx": 96.0, "rz": 62.0},
		{"x": -265.0, "z": 155.0, "rx": 82.0, "rz": 96.0},
		{"x": -15.0, "z": 0.0, "rx": 68.0, "rz": 58.0}
	]
	for index in range(pond_specs.size()):
		var spec: Dictionary = pond_specs[index]
		var pond := MeshInstance3D.new()
		pond.name = "MarshWaterBody_%02d" % index
		var pond_mesh := CylinderMesh.new()
		pond_mesh.top_radius = 1.0
		pond_mesh.bottom_radius = 1.0
		pond_mesh.height = 0.42
		pond.mesh = pond_mesh
		pond.scale = Vector3(float(spec["rx"]), 1.0, float(spec["rz"]))
		pond.position = Vector3(float(spec["x"]), 0.32, float(spec["z"]))
		pond.material_override = water_material
		zone.add_child(pond)
		_add_water_collision(zone, pond.position, float(spec["rx"]), float(spec["rz"]), index)
		_add_lily_pads(zone, pond.position, float(spec["rx"]), float(spec["rz"]), lily_material, index)

	_add_reed_fields(zone, reed_material)
	_add_marsh_trees(zone, wood_material, reed_material)
	_add_boardwalk_network(zone, wood_material)
	_add_marsh_entry(zone, wood_material)
	_build_hunter_marsh_trials(zone)
	zone.set_meta("system_marsh_water_body_count", pond_specs.size())
	zone.set_meta("system_marsh_reed_instance_count", 1800)
	zone.set_meta("system_marsh_tree_count", 56)
	zone.set_meta("system_marsh_boardwalk_count", 9)
	zone.set_meta("system_marshland_is_replacement_for_al_zawraa", true)
	zone.set_meta("system_marshland_is_traversable", true)


func _build_hunter_tunnel_connection(hunter_tunnel: Node3D) -> void:
	# The existing examination tunnel remains intact. This physical extension
	# starts at its open far end and rises gradually to the west edge of the marsh.
	var tunnel_end := hunter_tunnel.global_position + Vector3(0.0, 0.0, 39.0)
	var toward_marsh := Vector2(marsh_center.x - tunnel_end.x, marsh_center.z - tunnel_end.z)
	if toward_marsh.length() < 100.0:
		push_error("SYSTEM Baghdad Marshland: tunnel and marsh anchors are unexpectedly close.")
		return
	var direction := toward_marsh.normalized()
	var entry_xz := Vector2(marsh_center.x, marsh_center.z) - direction * 420.0
	var entry_ground := float(terrain.call("get_terrain_height", entry_xz.x, entry_xz.y))
	var start_floor_y := tunnel_end.y
	var end_floor_y := entry_ground - 0.25
	var horizontal_distance := Vector2(entry_xz.x - tunnel_end.x, entry_xz.y - tunnel_end.z).length()
	tunnel_connector_length = horizontal_distance

	var connector := Node3D.new()
	connector.name = "HunterTunnelToMarshlandPhysicalConnector"
	connector.set_meta("system_connection_type", "continuous_walkable_underground_passage")
	connector.set_meta("system_from", "BaghdadHunterExaminationTunnel")
	connector.set_meta("system_to", "BaghdadMarshland_AlZawraaReplacement")
	connector.set_meta("system_no_teleport_or_loading_gate", true)
	connector.set_meta("system_length_m", horizontal_distance)
	add_child(connector)

	var passage_material := _make_material(Color(0.085, 0.105, 0.115), 0.9, 0.12)
	var edge_material := _make_material(Color(0.025, 0.30, 0.36), 0.4, 0.45)
	edge_material.emission_enabled = true
	edge_material.emission = Color(0.0, 0.24, 0.32)
	edge_material.emission_energy_multiplier = 0.8
	var segment_count := maxi(1, ceili(horizontal_distance / CONNECTOR_SEGMENT_LENGTH))
	for index in range(segment_count):
		var t0 := float(index) / float(segment_count)
		var t1 := float(index + 1) / float(segment_count)
		var p0 := Vector3(
			lerpf(tunnel_end.x, entry_xz.x, t0),
			lerpf(start_floor_y, end_floor_y, t0),
			lerpf(tunnel_end.z, entry_xz.y, t0)
		)
		var p1 := Vector3(
			lerpf(tunnel_end.x, entry_xz.x, t1),
			lerpf(start_floor_y, end_floor_y, t1),
			lerpf(tunnel_end.z, entry_xz.y, t1)
		)
		_create_passage_segment(connector, p0, p1, index, passage_material, edge_material, index < segment_count - 1)
	var entry := Node3D.new()
	entry.name = "HunterTunnelMarshlandExit"
	entry.global_position = Vector3(entry_xz.x, entry_ground, entry_xz.y)
	entry.set_meta("system_facility_type", "hunter_exam_marshland_exit")
	entry.set_meta("system_interactable_destination", "baghdad_marshland_al_zawraa")
	entry.set_meta("system_walkable_connection", true)
	connector.add_child(entry)
	_create_entry_arch(entry, edge_material)
	connector.set_meta("system_passage_segment_count", segment_count)
	connector.set_meta("system_exit_at_marshland_edge", true)
	hunter_tunnel.set_meta("system_marshland_extension_attached", true)
	hunter_tunnel.set_meta("system_marshland_exit_world_position", entry.global_position)


func _create_passage_segment(parent: Node3D, start: Vector3, finish: Vector3, index: int, wall_material: Material, trim: Material, has_ceiling: bool) -> void:
	var delta := finish - start
	var segment_length := delta.length()
	if segment_length < 0.1:
		return
	var segment := Node3D.new()
	segment.name = "MarshConnectionSegment_%03d" % index
	segment.position = (start + finish) * 0.5 + Vector3.UP * 4.0
	parent.add_child(segment)
	segment.look_at(segment.global_position + delta, Vector3.UP)
	_add_segment_box(segment, "PassageFloor", Vector3(0.0, -4.0, 0.0), Vector3(18.0, 0.8, segment_length + 0.8), wall_material, true)
	_add_segment_box(segment, "PassageLeftWall", Vector3(-9.0, 0.0, 0.0), Vector3(0.8, 8.0, segment_length + 0.8), wall_material, true)
	_add_segment_box(segment, "PassageRightWall", Vector3(9.0, 0.0, 0.0), Vector3(0.8, 8.0, segment_length + 0.8), wall_material, true)
	if has_ceiling:
		_add_segment_box(segment, "PassageCeiling", Vector3(0.0, 4.0, 0.0), Vector3(18.0, 0.8, segment_length + 0.8), wall_material, false)
	for side in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		strip.name = "PassageGuideLight_" + str(side)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.16, 0.18, segment_length)
		strip.mesh = mesh
		strip.position = Vector3(side * 8.35, -3.45, 0.0)
		strip.material_override = trim
		segment.add_child(strip)


func _add_segment_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material, collision_enabled: bool) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = local_position
	visual.material_override = material
	parent.add_child(visual)
	if not collision_enabled:
		return
	var body := StaticBody3D.new()
	body.name = node_name + "Collision"
	body.position = local_position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)


func _add_water_collision(parent: Node3D, position: Vector3, radius_x: float, radius_z: float, index: int) -> void:
	var area := Area3D.new()
	area.name = "MarshWaterArea_%02d" % index
	area.position = position
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.set_meta("system_water_type", "shallow_marsh")
	area.set_meta("system_public_leisure_water_type", "marsh_shallow")
	area.set_meta("system_public_leisure_water_depth", 1.1)
	area.set_meta("system_swimmable", true)
	var shape := CollisionShape3D.new()
	var points := PackedVector3Array()
	for layer in [-0.6, 0.6]:
		for point_index in range(24):
			var angle := TAU * float(point_index) / 24.0
			points.append(Vector3(cos(angle) * radius_x, float(layer), sin(angle) * radius_z))
	var water_hull := ConvexPolygonShape3D.new()
	water_hull.points = points
	shape.shape = water_hull
	area.add_child(shape)
	area.body_entered.connect(_on_marsh_water_body_entered.bind(area))
	area.body_exited.connect(_on_marsh_water_body_exited.bind(area))
	parent.add_child(area)


func _add_lily_pads(parent: Node3D, center: Vector3, radius_x: float, radius_z: float, material: Material, pond_index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261125 + pond_index * 31
	for index in range(7):
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(0.18, 0.72)
		var pad := MeshInstance3D.new()
		pad.name = "LilyPad_%02d_%02d" % [pond_index, index]
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1.0
		mesh.bottom_radius = 1.0
		mesh.height = 0.08
		pad.mesh = mesh
		pad.scale = Vector3(rng.randf_range(2.0, 4.2), 1.0, rng.randf_range(1.4, 3.0))
		pad.position = Vector3(
			center.x + cos(angle) * radius_x * distance,
			center.y + 0.28,
			center.z + sin(angle) * radius_z * distance
		)
		pad.material_override = material
		parent.add_child(pad)


func _add_reed_fields(parent: Node3D, material: Material) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026112501
	var reed_mesh := CylinderMesh.new()
	reed_mesh.top_radius = 0.035
	reed_mesh.bottom_radius = 0.075
	reed_mesh.height = 2.6
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = reed_mesh
	multi.instance_count = 1800
	for index in range(1800):
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * 930.0
		var x := cos(angle) * radius
		var z := sin(angle) * radius * 0.92
		var ground_y := float(terrain.call("get_terrain_height", marsh_center.x + x, marsh_center.z + z)) - marsh_center.y
		var transform := Transform3D(Basis.IDENTITY, Vector3(x, ground_y + 1.3, z))
		multi.set_instance_transform(index, transform)
	var reeds := MultiMeshInstance3D.new()
	reeds.name = "MarshReedFields"
	reeds.multimesh = multi
	reeds.material_override = material
	parent.add_child(reeds)


func _add_marsh_trees(parent: Node3D, trunk_material: Material, canopy_material: Material) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 202611252
	for index in range(56):
		var angle := TAU * float(index) / 56.0
		var radius := rng.randf_range(700.0, 945.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius * 0.92
		var ground_y := float(terrain.call("get_terrain_height", marsh_center.x + x, marsh_center.z + z)) - marsh_center.y
		var tree := Node3D.new()
		tree.name = "MarshWillow_%02d" % index
		tree.position = Vector3(x, ground_y, z)
		parent.add_child(tree)
		var trunk := MeshInstance3D.new()
		trunk.name = "Trunk"
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.28
		trunk_mesh.bottom_radius = 0.52
		trunk_mesh.height = 8.0
		trunk.mesh = trunk_mesh
		trunk.position.y = 4.0
		trunk.material_override = trunk_material
		tree.add_child(trunk)
		var canopy := MeshInstance3D.new()
		canopy.name = "Canopy"
		var canopy_mesh := SphereMesh.new()
		canopy_mesh.radius = 4.0
		canopy_mesh.height = 7.0
		canopy.mesh = canopy_mesh
		canopy.position = Vector3(0.0, 8.0, 0.0)
		canopy.scale = Vector3(1.8, 0.75, 1.35)
		canopy.material_override = canopy_material
		tree.add_child(canopy)


func _add_boardwalk_network(parent: Node3D, material: Material) -> void:
	var entry := Vector3(marsh_entry_local.x, 0.6, marsh_entry_local.z)
	var inner := entry.lerp(Vector3(0.0, 0.6, 0.0), 0.48)
	var hub := Vector3(0.0, 0.6, 0.0)
	var paths := [
		[entry, inner],
		[inner, hub],
		[hub, Vector3(190.0, 0.6, -110.0)],
		[Vector3(190.0, 0.6, -110.0), Vector3(345.0, 0.6, 80.0)],
		[hub, Vector3(100.0, 0.6, 235.0)],
		[Vector3(100.0, 0.6, 235.0), Vector3(-180.0, 0.6, 290.0)],
		[inner, Vector3(-280.0, 0.6, -230.0)],
		[Vector3(100.0, 0.6, 235.0), Vector3(430.0, 0.6, 500.0)],
		[Vector3(430.0, 0.6, 500.0), Vector3(745.0, 0.6, 745.0)]
	]
	for index in range(paths.size()):
		var start: Vector3 = paths[index][0]
		var finish: Vector3 = paths[index][1]
		var midpoint := (start + finish) * 0.5
		var delta := finish - start
		var deck := MeshInstance3D.new()
		deck.name = "MarshBoardwalk_%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(5.0, 0.55, delta.length() + 1.0)
		deck.mesh = mesh
		deck.position = midpoint
		deck.material_override = material
		parent.add_child(deck)
		deck.look_at(finish, Vector3.UP)
		var body := StaticBody3D.new()
		body.name = "MarshBoardwalkCollision_%02d" % index
		body.position = deck.position
		body.rotation = deck.rotation
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
		for side in [-1.0, 1.0]:
			var rail := MeshInstance3D.new()
			rail.name = "BoardwalkRail_%02d_%s" % [index, str(side)]
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(0.18, 1.0, delta.length())
			rail.mesh = rail_mesh
			rail.position = Vector3(side * 2.35, 0.65, 0.0)
			rail.material_override = material
			deck.add_child(rail)


func _on_marsh_water_body_entered(body: Node3D, water_area: Area3D) -> void:
	if body == null or not is_instance_valid(body) or not body.is_in_group("system_player"):
		return
	var surface_y := water_area.global_position.y + 0.53
	var active_zones: Dictionary = body.get_meta("system_public_leisure_water_zones", {}).duplicate()
	active_zones[str(water_area.get_instance_id())] = {
		"type": "marsh_shallow",
		"depth": 1.1,
		"surface_y": surface_y
	}
	body.set_meta("system_public_leisure_water_zones", active_zones)
	body.set_meta("system_public_leisure_swimming", true)
	body.set_meta("system_public_leisure_water_type", "marsh_shallow")
	body.set_meta("system_public_leisure_water_depth", 1.1)
	body.set_meta("system_swimming", true)
	body.set_meta("system_swim_surface_y", surface_y)
	body.set_meta("system_swim_source", "Baghdad Mesopotamian Marshland")


func _on_marsh_water_body_exited(body: Node3D, water_area: Area3D) -> void:
	if body == null or not is_instance_valid(body) or not body.is_in_group("system_player"):
		return
	var active_zones: Dictionary = body.get_meta("system_public_leisure_water_zones", {}).duplicate()
	active_zones.erase(str(water_area.get_instance_id()))
	if active_zones.is_empty():
		body.remove_meta("system_public_leisure_water_zones")
		body.remove_meta("system_public_leisure_swimming")
		body.remove_meta("system_public_leisure_water_type")
		body.remove_meta("system_public_leisure_water_depth")
		body.remove_meta("system_swimming")
		body.remove_meta("system_swim_surface_y")
		body.remove_meta("system_swim_source")
		body.remove_meta("system_swim_last_stroke_force")
		return
	body.set_meta("system_public_leisure_water_zones", active_zones)
	var remaining_ids: Array = active_zones.keys()
	var remaining: Dictionary = active_zones[remaining_ids.back()]
	body.set_meta("system_public_leisure_swimming", true)
	body.set_meta("system_public_leisure_water_type", str(remaining.get("type", "marsh_shallow")))
	body.set_meta("system_public_leisure_water_depth", float(remaining.get("depth", 1.1)))
	body.set_meta("system_swimming", true)
	body.set_meta("system_swim_surface_y", float(remaining.get("surface_y", body.global_position.y + 0.25)))
	body.set_meta("system_swim_source", "Baghdad Mesopotamian Marshland")


func _add_marsh_entry(parent: Node3D, material: Material) -> void:
	var entry := Node3D.new()
	entry.name = "MarshlandPublicEntry"
	entry.position = marsh_entry_local
	entry.set_meta("system_entry_from", "HunterTunnelToMarshlandPhysicalConnector")
	entry.set_meta("system_destination_id", "baghdad_marshland_al_zawraa")
	entry.set_meta("system_walkable", true)
	parent.add_child(entry)
	var arch := MeshInstance3D.new()
	arch.name = "MarshlandEntryArch"
	var arch_mesh := BoxMesh.new()
	arch_mesh.size = Vector3(13.0, 0.8, 2.0)
	arch.mesh = arch_mesh
	arch.position.y = 8.0
	arch.material_override = material
	entry.add_child(arch)
	var sign := Label3D.new()
	sign.name = "MarshlandWelcomeSign"
	sign.text = "SYSTEM MARSHLAND\nأرض المستنقعات"
	sign.font_size = 28
	sign.pixel_size = 0.016
	sign.position = Vector3(0.0, 9.0, -1.4)
	sign.modulate = Color(0.72, 0.91, 0.76)
	entry.add_child(sign)


func _create_entry_arch(parent: Node3D, material: Material) -> void:
	var arch := MeshInstance3D.new()
	arch.name = "TunnelExitArch"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(18.0, 1.0, 2.0)
	arch.mesh = mesh
	arch.position.y = 8.0
	arch.material_override = material
	parent.add_child(arch)
	var label := Label3D.new()
	label.name = "TunnelExitDestinationSign"
	label.text = "BAGHDAD MARSHLAND\nأرض المستنقعات"
	label.font_size = 26
	label.pixel_size = 0.014
	label.position = Vector3(0.0, 9.5, -1.5)
	label.modulate = Color(0.7, 0.94, 0.78)
	parent.add_child(label)


func _build_hunter_marsh_trials(zone: Node3D) -> void:
	zone.set_meta("system_hunter_exam_biome", true)
	zone.set_meta("system_hunter_exam_trial_type", "seasonal_marsh_survival_and_navigation")
	zone.set_meta("system_hunter_exam_inspired_by", "Hunter x Hunter Hunter Exam swamp atmosphere; original SYSTEM WORLD implementation")
	zone.set_meta("system_hunter_marsh_deception_npc_count", 12)
	zone.set_meta("system_hunter_marsh_giant_creature_count", 6)
	zone.set_meta("system_hunter_marsh_seasonal_gate_count", 3)
	zone.set_meta("system_current_marsh_season", _get_marsh_season())
	zone.set_meta("system_hunter_marsh_wrong_route_hazards", 5)
	zone.set_meta("system_hunter_marsh_hidden_heritage_site", "HiddenMarshAncientSanctuary")
	_build_marsh_farms(zone)
	_build_marsh_fog(zone)
	_build_marsh_deception_npcs(zone)
	_build_giant_marsh_creatures(zone)
	_build_marsh_route_markers(zone)
	_build_wrong_route_hazards(zone)
	_build_hidden_heritage_gates(zone)


func _get_marsh_season() -> String:
	var date := Time.get_date_dict_from_system()
	var month := int(date.get("month", 1))
	if month in [3, 4, 5]:
		return "spring"
	if month in [6, 7, 8]:
		return "summer"
	if month in [9, 10, 11]:
		return "autumn"
	return "winter"


func _build_marsh_farms(zone: Node3D) -> void:
	var soil := _make_material(Color(0.23, 0.16, 0.09), 1.0, 0.0)
	var crop_materials := [
		_make_material(Color(0.24, 0.46, 0.13), 0.92, 0.0),
		_make_material(Color(0.42, 0.55, 0.16), 0.9, 0.0),
		_make_material(Color(0.55, 0.32, 0.12), 0.85, 0.0)
	]
	var farm_root := Node3D.new()
	farm_root.name = "MarshAgriculturalGardens"
	farm_root.position = Vector3(-240.0, 0.2, 440.0)
	zone.add_child(farm_root)
	for plot_index in range(12):
		var plot := MeshInstance3D.new()
		plot.name = "CultivatedSoilPlot_%02d" % plot_index
		var plot_mesh := BoxMesh.new()
		plot_mesh.size = Vector3(26.0, 0.24, 13.0)
		plot.mesh = plot_mesh
		plot.position = Vector3(float(plot_index % 4) * 32.0, 0.0, float(plot_index / 4) * 20.0)
		plot.material_override = soil
		farm_root.add_child(plot)
		for row in range(4):
			for plant_index in range(9):
				var crop := MeshInstance3D.new()
				crop.name = "MarshCrop_%02d_%02d_%02d" % [plot_index, row, plant_index]
				var crop_mesh := CapsuleMesh.new()
				crop_mesh.radius = 0.18
				crop_mesh.height = 1.25
				crop.mesh = crop_mesh
				crop.position = plot.position + Vector3(-11.0 + float(plant_index) * 2.7, 0.65, -4.5 + float(row) * 3.0)
				crop.material_override = crop_materials[(plot_index + row) % crop_materials.size()]
				farm_root.add_child(crop)
	farm_root.set_meta("system_agricultural_plot_count", 12)
	farm_root.set_meta("system_crop_plant_count", 432)
	farm_root.set_meta("system_marshland_farm_is_walkable", true)


func _build_marsh_fog(zone: Node3D) -> void:
	var fog_material := StandardMaterial3D.new()
	fog_material.albedo_color = Color(0.68, 0.78, 0.72, 0.16)
	fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fog_material.no_depth_test = false
	for index in range(14):
		var fog := MeshInstance3D.new()
		fog.name = "MarshGroundFog_%02d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 0.32
		fog.mesh = mesh
		fog.scale = Vector3(65.0 + float(index % 4) * 12.0, 1.0, 28.0 + float(index % 3) * 9.0)
		fog.position = Vector3(-620.0 + float((index * 97) % 1240), 1.8 + float(index % 3) * 0.35, -540.0 + float((index * 131) % 1080))
		fog.material_override = fog_material
		fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.add_child(fog)
		fog.set_meta("system_fog_layer", "low_swamp_mist")
	zone.set_meta("system_ground_fog_layer_count", 14)


func _build_marsh_deception_npcs(zone: Node3D) -> void:
	var clothing := _make_material(Color(0.20, 0.25, 0.21), 0.9, 0.0)
	var skin := _make_material(Color(0.55, 0.39, 0.27), 0.92, 0.0)
	var decoy_positions := [
		Vector3(-620.0, 0.0, -240.0), Vector3(-430.0, 0.0, 350.0),
		Vector3(-120.0, 0.0, -520.0), Vector3(250.0, 0.0, -410.0),
		Vector3(570.0, 0.0, -190.0), Vector3(650.0, 0.0, 300.0),
		Vector3(330.0, 0.0, 570.0), Vector3(-400.0, 0.0, 620.0),
		Vector3(-720.0, 0.0, 90.0), Vector3(30.0, 0.0, 700.0),
		Vector3(720.0, 0.0, 80.0), Vector3(-30.0, 0.0, -700.0)
	]
	for index in range(decoy_positions.size()):
		var npc := Node3D.new()
		npc.name = "HunterExamDeceptionNPC_%02d" % index
		npc.position = decoy_positions[index]
		npc.set_meta("system_npc_role", "hunter_exam_candidate_or_false_guide")
		npc.set_meta("system_deception_enabled", true)
		npc.set_meta("system_npc_can_give_false_route_hint", true)
		npc.set_meta("system_is_real_guild_guide", false)
		zone.add_child(npc)
		var torso := MeshInstance3D.new()
		torso.name = "NPCBody"
		var torso_mesh := CapsuleMesh.new()
		torso_mesh.radius = 0.48
		torso_mesh.height = 1.8
		torso.mesh = torso_mesh
		torso.position.y = 1.1
		torso.material_override = clothing
		npc.add_child(torso)
		var head := MeshInstance3D.new()
		head.name = "NPCHead"
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.34
		head_mesh.height = 0.68
		head.mesh = head_mesh
		head.position.y = 2.25
		head.material_override = skin
		npc.add_child(head)
		var label := Label3D.new()
		label.name = "DeceptionRoleLabel"
		label.text = "مختبر" if index % 3 != 0 else "مرشد؟"
		label.font_size = 20
		label.pixel_size = 0.012
		label.position.y = 3.0
		label.modulate = Color(0.95, 0.82, 0.55)
		npc.add_child(label)
		var trigger := Area3D.new()
		trigger.name = "FalseRouteHintTrigger"
		trigger.position.y = 1.0
		trigger.set_meta("system_deception_trigger", true)
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 4.0
		collision.shape = sphere
		trigger.add_child(collision)
		npc.add_child(trigger)
		trigger.body_entered.connect(_on_deception_npc_approached.bind(npc))


func _on_deception_npc_approached(body: Node3D, npc: Node3D) -> void:
	if not _is_hunter_exam_player(body):
		return
	body.set_meta("system_hunter_route_hint", "false")
	body.set_meta("system_hunter_route_hint_source", npc.name)
	body.set_meta("system_hunter_route_hint_destination", "wrong_marshland_path")
	body.set_meta("system_hunter_deception_warning", "Some candidates and apparent guides deliberately mislead exam participants.")


func _build_giant_marsh_creatures(zone: Node3D) -> void:
	var shell_material := _make_material(Color(0.16, 0.25, 0.13), 0.78, 0.0)
	var hide_material := _make_material(Color(0.20, 0.31, 0.24), 0.9, 0.0)
	var positions := [
		Vector3(-650.0, 0.0, -420.0), Vector3(-280.0, 0.0, 260.0),
		Vector3(80.0, 0.0, -600.0), Vector3(430.0, 0.0, -300.0),
		Vector3(560.0, 0.0, 480.0), Vector3(-520.0, 0.0, 560.0)
	]
	for index in range(positions.size()):
		var creature := Node3D.new()
		creature.name = "GiantMarshCreature_%02d" % index
		creature.position = positions[index]
		creature.set_meta("system_creature_is_giant", true)
		creature.set_meta("system_hunter_exam_hazard", true)
		creature.set_meta("system_creature_species", "giant_marsh_turtle" if index % 2 == 0 else "ancient_swamp_beast")
		creature.set_meta("system_encounter_class", "giant_wildlife")
		zone.add_child(creature)
		var body := MeshInstance3D.new()
		body.name = "CreatureBody"
		var body_mesh := SphereMesh.new()
		body_mesh.radius = 1.0
		body_mesh.height = 2.0
		body.mesh = body_mesh
		body.scale = Vector3(3.8, 1.0, 5.2) if index % 2 == 0 else Vector3(4.5, 1.2, 6.0)
		body.position.y = 1.2
		body.material_override = hide_material
		creature.add_child(body)
		if index % 2 == 0:
			var shell := MeshInstance3D.new()
			shell.name = "GiantTurtleShell"
			var shell_mesh := SphereMesh.new()
			shell_mesh.radius = 1.0
			shell_mesh.height = 1.5
			shell.mesh = shell_mesh
			shell.scale = Vector3(3.7, 1.45, 4.7)
			shell.position.y = 2.0
			shell.material_override = shell_material
			creature.add_child(shell)
		else:
			var jaws := MeshInstance3D.new()
			jaws.name = "SwampBeastHead"
			var head_mesh := BoxMesh.new()
			head_mesh.size = Vector3(2.5, 1.3, 2.8)
			jaws.mesh = head_mesh
			jaws.position = Vector3(0.0, 1.1, -5.0)
			jaws.material_override = hide_material
			creature.add_child(jaws)
		var encounter := Area3D.new()
		encounter.name = "GiantCreatureEncounterZone"
		encounter.position.y = 1.0
		encounter.set_meta("system_giant_creature_encounter", true)
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 11.0
		collision.shape = sphere
		encounter.add_child(collision)
		creature.add_child(encounter)
		encounter.body_entered.connect(_on_giant_creature_encounter.bind(creature))


func _is_hunter_exam_player(body: Node3D) -> bool:
	return body != null and is_instance_valid(body) and body.is_in_group("system_player")


func _on_giant_creature_encounter(body: Node3D, creature: Node3D) -> void:
	if not _is_hunter_exam_player(body):
		return
	body.set_meta("system_hunter_marsh_encounter", creature.name)
	body.set_meta("system_hunter_marsh_encounter_species", str(creature.get_meta("system_creature_species", "giant_wildlife")))
	body.set_meta("system_hunter_marsh_encounter_state", "combat_or_escape_required")
	body.set_meta("system_hunter_marsh_encounter_active", true)


func _build_marsh_route_markers(zone: Node3D) -> void:
	var material := _make_material(Color(0.96, 0.72, 0.18), 0.35, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.9, 0.45, 0.05)
	material.emission_energy_multiplier = 1.0
	var marker_positions := [
		Vector3(-780.0, 0.0, -60.0), Vector3(-620.0, 0.0, 20.0),
		Vector3(-460.0, 0.0, 100.0), Vector3(-280.0, 0.0, 170.0),
		Vector3(-80.0, 0.0, 260.0), Vector3(120.0, 0.0, 360.0),
		Vector3(300.0, 0.0, 470.0), Vector3(500.0, 0.0, 620.0), Vector3(680.0, 0.0, 700.0)
	]
	for index in range(marker_positions.size()):
		var marker := Node3D.new()
		marker.name = "HunterExamRouteArrow_%02d" % index
		marker.position = marker_positions[index]
		marker.set_meta("system_route_marker", true)
		marker.set_meta("system_route_marker_index", index)
		zone.add_child(marker)
		var stem := MeshInstance3D.new()
		stem.name = "ArrowStem"
		var stem_mesh := BoxMesh.new()
		stem_mesh.size = Vector3(0.25, 0.2, 3.4)
		stem.mesh = stem_mesh
		stem.position.y = 0.35
		stem.material_override = material
		marker.add_child(stem)
		var head := MeshInstance3D.new()
		head.name = "ArrowHead"
		var head_mesh := PrismMesh.new()
		head_mesh.size = Vector3(1.5, 0.25, 1.5)
		head.mesh = head_mesh
		head.position = Vector3(0.0, 0.42, -1.6)
		head.material_override = material
		marker.add_child(head)
		var label := Label3D.new()
		label.name = "ArrowDirectionLabel"
		label.text = "اتبع المسار"
		label.font_size = 18
		label.pixel_size = 0.012
		label.position.y = 1.0
		label.modulate = Color(1.0, 0.83, 0.32)
		marker.add_child(label)
	zone.set_meta("system_route_arrow_count", marker_positions.size())


func _build_wrong_route_hazards(zone: Node3D) -> void:
	var hazard_positions := [
		Vector3(720.0, 0.0, -620.0), Vector3(-760.0, 0.0, 430.0),
		Vector3(660.0, 0.0, 680.0), Vector3(-220.0, 0.0, -760.0),
		Vector3(30.0, 0.0, 760.0)
	]
	for index in range(hazard_positions.size()):
		var hazard := Area3D.new()
		hazard.name = "HunterExamWrongRouteHazard_%02d" % index
		hazard.position = hazard_positions[index]
		hazard.set_meta("system_wrong_route_hazard", true)
		hazard.set_meta("system_exam_failure_on_entry", true)
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 7.5
		collision.shape = sphere
		hazard.add_child(collision)
		zone.add_child(hazard)
		hazard.body_entered.connect(_on_wrong_route_hazard_entered.bind(hazard))


func _on_wrong_route_hazard_entered(body: Node3D, hazard: Area3D) -> void:
	if not _is_hunter_exam_player(body):
		return
	body.set_meta("system_hunter_wrong_route_triggered", hazard.name)
	body.set_meta("system_hunter_exam_failure_reason", "Entered a forbidden marshland route.")
	var exam_manager := get_tree().root.find_child("SYSTEMHunterExamManager", true, false)
	if exam_manager != null and bool(exam_manager.get("exam_active")):
		exam_manager.call("withdraw_or_fail", "فشلت في اختبار المستنقعات: دخلت مساراً محظوراً.")


func _build_hidden_heritage_gates(zone: Node3D) -> void:
	var sanctuary := Node3D.new()
	sanctuary.name = "HiddenMarshAncientSanctuary"
	sanctuary.position = Vector3(760.0, 0.0, 760.0)
	sanctuary.set_meta("system_hidden_ancient_site", true)
	sanctuary.set_meta("system_hunter_exam_final_discovery", true)
	sanctuary.set_meta("system_star_gate_hub", true)
	zone.add_child(sanctuary)
	var stone := _make_material(Color(0.29, 0.27, 0.20), 0.95, 0.0)
	var relic := _make_material(Color(0.48, 0.34, 0.15), 0.4, 0.3)
	for index in range(8):
		var pillar := MeshInstance3D.new()
		pillar.name = "AncientSanctuaryPillar_%02d" % index
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.8
		mesh.bottom_radius = 1.1
		mesh.height = 8.0
		pillar.mesh = mesh
		pillar.position = Vector3(-14.0 + float(index % 4) * 9.0, 4.0, -10.0 + float(index / 4) * 20.0)
		pillar.material_override = stone
		sanctuary.add_child(pillar)
	for gate_index in range(3):
		var gate := Node3D.new()
		gate.name = "SeasonalMarshStarGate_%02d" % gate_index
		gate.position = Vector3(-12.0 + float(gate_index) * 12.0, 0.0, -22.0)
		gate.set_meta("system_star_gate", true)
		gate.set_meta("system_gate_id", gate_index)
		gate.set_meta("system_gate_destination_pool_by_season", SEASONAL_GATE_DESTINATIONS.duplicate(true))
		gate.set_meta("system_gate_current_season", _get_marsh_season())
		gate.set_meta("system_gate_destination_city", str(SEASONAL_GATE_DESTINATIONS[_get_marsh_season()][gate_index]))
		gate.set_meta("system_gate_rotation", "seasonal")
		gate.set_meta("system_hidden_until_final_exam_discovery", true)
		gate.visible = false
		sanctuary.add_child(gate)
		_build_marsh_star_gate_visual(gate, relic, gate_index)
		var area := Area3D.new()
		area.name = "SeasonalGateActivationArea"
		area.position = Vector3(0.0, 2.0, 2.5)
		area.set_meta("system_star_gate_activation", true)
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 2.8
		collision.shape = sphere
		area.add_child(collision)
		gate.add_child(area)
		area.body_entered.connect(_on_marsh_star_gate_entered.bind(gate))
		gate.set_meta("system_activation_area_path", area.get_path())


func _build_marsh_star_gate_visual(gate: Node3D, material: Material, gate_index: int) -> void:
	var frame := MeshInstance3D.new()
	frame.name = "AncientStarGateFrame"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(4.8, 6.5, 0.6)
	frame.mesh = mesh
	frame.position.y = 3.2
	frame.material_override = material
	gate.add_child(frame)
	var energy := MeshInstance3D.new()
	energy.name = "StarGateEnergyVeil"
	var energy_mesh := PlaneMesh.new()
	energy_mesh.size = Vector2(3.7, 5.4)
	energy.mesh = energy_mesh
	energy.position = Vector3(0.0, 3.2, 0.34)
	var glow := _make_material([Color(0.1, 0.65, 0.95, 0.7), Color(0.65, 0.3, 0.95, 0.7), Color(0.2, 0.85, 0.55, 0.7)][gate_index], 0.25, 0.2, true)
	glow.emission_enabled = true
	glow.emission = glow.albedo_color
	glow.emission_energy_multiplier = 1.6
	energy.material_override = glow
	gate.add_child(energy)
	var label := Label3D.new()
	label.name = "StarGateDestinationLabel"
	label.text = "بوابة نجمية %d" % (gate_index + 1)
	label.font_size = 24
	label.pixel_size = 0.014
	label.position.y = 7.0
	gate.add_child(label)


func _on_marsh_star_gate_entered(body: Node3D, gate: Node3D) -> void:
	if not _is_hunter_exam_player(body):
		return
	var exam_manager := get_tree().root.find_child("SYSTEMHunterExamManager", true, false)
	if exam_manager == null or not bool(exam_manager.get("registered")):
		return
	var completed_exam_segments: Array = exam_manager.get("completed_stage_ids")
	if not completed_exam_segments.has("baghdad_tunnel_competition"):
		return
	if bool(exam_manager.get("exam_active")):
		return
	var gate_id := int(gate.get_meta("system_gate_id", -1))
	var season := _get_marsh_season()
	var destinations: Array = SEASONAL_GATE_DESTINATIONS.get(season, [])
	if gate_id < 0 or gate_id >= destinations.size():
		return
	var city_name := str(destinations[gate_id])
	var world_manager := get_tree().root.find_child("WorldManager", true, false)
	if world_manager == null:
		return
	var roots: Dictionary = world_manager.get("world_roots")
	var modern_root := roots.get(2) as Node3D
	if modern_root == null:
		return
	var region := modern_root.get_node_or_null("ModernWorldRegionManager")
	if region == null:
		return
	var anchors: Dictionary = region.get("city_anchors")
	if not anchors.has(city_name):
		push_warning("SYSTEM Marshland Star Gate: destination city anchor is unavailable: " + city_name)
		return
	var anchor: Vector2 = anchors[city_name]
	var terrain_node := modern_root.get_node_or_null("ModernContinent")
	var height := 0.0
	if terrain_node != null and terrain_node.has_method("get_terrain_height"):
		height = float(terrain_node.call("get_terrain_height", anchor.x, anchor.y))
	body.set_meta("system_last_marsh_star_gate", gate.name)
	body.set_meta("system_last_marsh_star_gate_season", season)
	body.set_meta("system_last_marsh_star_gate_destination", city_name)
	body.global_position = Vector3(anchor.x, height + 3.0, anchor.y)
	body.velocity = Vector3.ZERO
	print("SYSTEM Marshland Star Gate: season ", season, " -> ", city_name)


func _make_material(color: Color, roughness: float, metallic: float, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	return material
