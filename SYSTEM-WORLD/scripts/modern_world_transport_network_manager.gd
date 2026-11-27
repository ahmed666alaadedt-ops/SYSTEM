extends Node3D
class_name ModernWorldTransportNetworkManager

## First-pass visual transport corridors for the modern world.
## Roads, bridges, rail lines, ports and circuits are scenery prototypes;
## they do not yet provide vehicle navigation or passenger travel.

const CITY_ROUTES := [
	["New York", "London", "Paris", "Baghdad", "Moscow"],
	["Baghdad", "Cairo", "New Delhi", "Guangzhou", "Seoul", "Tokyo"],
	["Cairo", "Johannesburg"],
	["Guangzhou", "Singapore", "Sydney"],
	["Paris", "New Delhi"]
]

var region_manager: Node
var terrain: Node
var road_material: StandardMaterial3D
var road_marking_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var port_material: StandardMaterial3D
var landmark_records: Array[Dictionary] = []
var active_city_name := ""
var city_check_clock := 0.0

func _ready() -> void:
	name = "ModernWorldTransportNetworkManager"
	region_manager = get_parent()
	if region_manager == null:
		return
	terrain = region_manager.get("terrain")
	if terrain == null:
		push_warning("SYSTEM Transport: terrain is unavailable.")
		return
	_create_materials()
	active_city_name = _find_nearest_city_name(Vector3.ZERO)
	_build_active_city_transport()
	print("SYSTEM WORLD: local transport network streamed for ", active_city_name,
		"; landmarks=", landmark_records.size())


func _process(delta: float) -> void:
	city_check_clock += delta
	if city_check_clock < 4.0:
		return
	city_check_clock = 0.0
	var player := region_manager.get_parent().get_node_or_null("Player") as Node3D
	var player_position := player.global_position if is_instance_valid(player) else Vector3.ZERO
	var nearest_city := _find_nearest_city_name(player_position)
	if nearest_city != active_city_name:
		_rebuild_city_transport(nearest_city)


func _find_nearest_city_name(position: Vector3) -> String:
	var city_names: Array = region_manager.call("get_city_names")
	var nearest_name := "Baghdad"
	var nearest_distance := INF
	for city_value in city_names:
		var city_name := str(city_value)
		var anchor: Vector3 = _city_anchor(city_name)
		if anchor == Vector3.INF:
			continue
		var distance := Vector2(position.x - anchor.x, position.z - anchor.z).length_squared()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_name = city_name
	return nearest_name


func _build_active_city_transport() -> void:
	_build_intercity_corridors()
	_build_city_tunnels()
	_build_city_overpasses()
	_build_rural_access_roads()
	_build_city_ports()
	_build_aircraft_and_train_fleets()
	_build_race_circuits()


func _rebuild_city_transport(city_name: String) -> void:
	for child in get_children():
		child.queue_free()
	landmark_records.clear()
	active_city_name = city_name
	_build_active_city_transport()
	print("SYSTEM WORLD: local transport area changed to ", active_city_name)


func _create_materials() -> void:
	road_material = _make_material(Color(0.075, 0.085, 0.095), 0.94, 0.0)
	road_marking_material = _make_material(Color(0.88, 0.86, 0.76), 0.82, 0.0)
	bridge_material = _make_material(Color(0.24, 0.29, 0.34), 0.7, 0.42)
	rail_material = _make_material(Color(0.34, 0.37, 0.4), 0.68, 0.58)
	port_material = _make_material(Color(0.35, 0.38, 0.39), 0.82, 0.22)

func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _commit_surface_tool_if_valid(surface: SurfaceTool) -> ArrayMesh:
	# Prevent zero-surface ArrayMesh resources from reaching MeshInstance3D.
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


func _build_intercity_corridors() -> void:
	for route_index in range(CITY_ROUTES.size()):
		var route: Array = CITY_ROUTES[route_index]
		for segment_index in range(route.size() - 1):
			var route_start_city := str(route[segment_index])
			var route_finish_city := str(route[segment_index + 1])
			if route_start_city != active_city_name and route_finish_city != active_city_name:
				continue
			var start: Vector3 = _city_anchor(route_start_city)
			var finish: Vector3 = _city_anchor(route_finish_city)
			if start == Vector3.INF or finish == Vector3.INF:
				continue
			_build_corridor_segment(start, finish, route_index, segment_index)

func _city_anchor(city_name: String) -> Vector3:
	if region_manager == null or not region_manager.has_method("get_city_anchor"):
		return Vector3.INF
	return region_manager.call("get_city_anchor", city_name)

func _build_corridor_segment(start: Vector3, finish: Vector3, route_index: int, segment_index: int) -> void:
	var steps := maxi(12, int(start.distance_to(finish) / 24.0))
	var water_run := 0.0
	var maximum_water_run := 0.0
	for step in range(steps):
		var sample := Vector2(start.x, start.z).lerp(
			Vector2(finish.x, finish.z),
			(float(step) + 0.5) / float(steps)
		)
		if not bool(terrain.call("is_land_position", sample.x, sample.y)):
			water_run += start.distance_to(finish) / float(steps)
			maximum_water_run = maxf(maximum_water_run, water_run)
		else:
			water_run = 0.0
	if maximum_water_run > 180.0:
		return
	var road_surface := SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	road_surface.set_material(road_material)
	var rail_surface := SurfaceTool.new()
	rail_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	rail_surface.set_material(rail_material)
	var marking_surface := SurfaceTool.new()
	marking_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	marking_surface.set_material(road_marking_material)
	var bridge_samples: Array[Vector3] = []
	var added := 0
	for step in range(steps):
		var t0 := float(step) / float(steps)
		var t1 := float(step + 1) / float(steps)
		var a2 := Vector2(start.x, start.z).lerp(Vector2(finish.x, finish.z), t0)
		var b2 := Vector2(start.x, start.z).lerp(Vector2(finish.x, finish.z), t1)
		var middle := (a2 + b2) * 0.5
		var is_water := not bool(terrain.call("is_land_position", middle.x, middle.y))
		var a_land := bool(terrain.call("is_land_position", a2.x, a2.y))
		var b_land := bool(terrain.call("is_land_position", b2.x, b2.y))
		var a_y := float(terrain.call("get_terrain_height", a2.x, a2.y)) + 0.48
		var b_y := float(terrain.call("get_terrain_height", b2.x, b2.y)) + 0.48
		if is_water:
			a_y = maxf(a_y, 5.8)
			b_y = maxf(b_y, 5.8)
			bridge_samples.append(Vector3(middle.x, 5.8, middle.y))
		elif not a_land or not b_land:
			a_y = maxf(a_y, 5.8)
			b_y = maxf(b_y, 5.8)
		var direction := (b2 - a2).normalized()
		if direction.length_squared() < 0.001:
			continue
		var side := Vector2(-direction.y, direction.x)
		_add_ribbon_quad(road_surface, a2, b2, side, a_y, b_y, 8.5, 0.0)
		_add_ribbon_quad(rail_surface, a2, b2, side, a_y + 0.38, b_y + 0.38, 0.16, 4.5)
		_add_ribbon_quad(rail_surface, a2, b2, side, a_y + 0.38, b_y + 0.38, 0.16, -4.5)
		if step % 3 == 0:
			_add_ribbon_quad(marking_surface, a2, b2, side, a_y + 0.06, b_y + 0.06, 0.13, 0.0)
			_add_ribbon_quad(marking_surface, a2, b2, side, a_y + 0.06, b_y + 0.06, 0.11, 3.8)
			_add_ribbon_quad(marking_surface, a2, b2, side, a_y + 0.06, b_y + 0.06, 0.11, -3.8)
		added += 1
	road_surface.generate_normals()
	rail_surface.generate_normals()
	marking_surface.generate_normals()
	if added > 0:
		var road_body := StaticBody3D.new()
		road_body.name = "IntercityHighwayBody_%02d_%02d" % [route_index, segment_index]
		add_child(road_body)

		var road_mesh := MeshInstance3D.new()
		road_mesh.name = "IntercityHighway_%02d_%02d" % [route_index, segment_index]
		var committed_road_mesh := _commit_surface_tool_if_valid(road_surface)
		if committed_road_mesh == null:
			return
		road_mesh.mesh = committed_road_mesh
		road_mesh.material_override = road_material
		road_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		road_body.add_child(road_mesh)

		# Static triangle collision makes the generated highway physically solid.
		# Keep it on the same body as the visual mesh so streamed route cleanup
		# removes both together when the active city changes.
		var road_collision := CollisionShape3D.new()
		road_collision.name = "IntercityHighwayCollision"
		road_collision.shape = road_mesh.mesh.create_trimesh_shape()
		road_body.add_child(road_collision)
		var rail_mesh := MeshInstance3D.new()
		rail_mesh.name = "IntercityRailCorridor_%02d_%02d" % [route_index, segment_index]
		var committed_rail_mesh := _commit_surface_tool_if_valid(rail_surface)
		if committed_rail_mesh == null:
			return
		rail_mesh.mesh = committed_rail_mesh
		rail_mesh.material_override = rail_material
		rail_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rail_mesh)
		var marking_mesh := MeshInstance3D.new()
		marking_mesh.name = "IntercityHighwayMarkings_%02d_%02d" % [route_index, segment_index]
		var committed_marking_mesh := _commit_surface_tool_if_valid(marking_surface)
		if committed_marking_mesh == null:
			return
		marking_mesh.mesh = committed_marking_mesh
		marking_mesh.material_override = road_marking_material
		marking_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marking_mesh)
		_build_highway_rest_stop(start, finish, route_index, segment_index)
	if not bridge_samples.is_empty():
		_build_bridge_supports(bridge_samples, route_index, segment_index)
		_build_bridge_railings(bridge_samples, route_index, segment_index)
		landmark_records.append({
			"id": "bridge_%02d_%02d" % [route_index, segment_index],
			"name": "Intercity Bridge %02d-%02d" % [route_index + 1, segment_index + 1],
			"position": bridge_samples[int(bridge_samples.size() / 2)]
		})


func _build_bridge_railings(samples: Array[Vector3], route_index: int, segment_index: int) -> void:
	if samples.size() < 2:
		return
	var railing_material := _make_material(Color(0.62, 0.68, 0.72), 0.48, 0.68)
	var lamp_material := _make_material(Color(0.7, 0.86, 1.0), 0.32, 0.0)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(0.24, 0.52, 0.78)
	lamp_material.emission_energy_multiplier = 1.15
	for side_sign in [-1.0, 1.0]:
		var rail_surface := SurfaceTool.new()
		rail_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		rail_surface.set_material(railing_material)
		for index in range(samples.size() - 1):
			var a: Vector3 = samples[index]
			var b: Vector3 = samples[index + 1]
			var direction := Vector2(b.x - a.x, b.z - a.z).normalized()
			var side: Vector2 = Vector2(-direction.y, direction.x) * float(side_sign) * 5.0
			var lower_a: Vector3 = Vector3(a.x + side.x, a.y + 0.7, a.z + side.y)
			var lower_b: Vector3 = Vector3(b.x + side.x, b.y + 0.7, b.z + side.y)
			var upper_a: Vector3 = lower_a + Vector3(0.0, 1.05, 0.0)
			var upper_b: Vector3 = lower_b + Vector3(0.0, 1.05, 0.0)
			rail_surface.add_vertex(lower_a)
			rail_surface.add_vertex(upper_a)
			rail_surface.add_vertex(lower_b)
			rail_surface.add_vertex(lower_b)
			rail_surface.add_vertex(upper_a)
			rail_surface.add_vertex(upper_b)
		rail_surface.generate_normals()
		var rail_mesh := MeshInstance3D.new()
		rail_mesh.name = "BridgeRailing_%02d_%02d_%s" % [route_index, segment_index, str(side_sign)]
		var committed_railing_mesh := _commit_surface_tool_if_valid(rail_surface)
		if committed_railing_mesh == null:
			continue
		rail_mesh.mesh = committed_railing_mesh
		rail_mesh.material_override = railing_material
		add_child(rail_mesh)
	for index in range(0, samples.size(), 8):
		var point: Vector3 = samples[index]
		var lamp := MeshInstance3D.new()
		lamp.name = "BridgeMarkerLight_%02d_%02d_%02d" % [route_index, segment_index, index]
		var lamp_mesh := SphereMesh.new()
		lamp_mesh.radius = 0.22
		lamp_mesh.height = 0.44
		lamp.mesh = lamp_mesh
		lamp.position = point + Vector3(0.0, 2.05, 0.0)
		lamp.material_override = lamp_material
		add_child(lamp)


func _build_waterfront_promenade(parent: Node3D, outward: Vector2) -> void:
	var walkway_material := _make_material(Color(0.52, 0.55, 0.54), 0.86, 0.08)
	var bench_material := _make_material(Color(0.25, 0.19, 0.13), 0.82, 0.0)
	var bollard_material := _make_material(Color(0.18, 0.22, 0.25), 0.55, 0.48)
	_add_box(parent, "WaterfrontPromenadeDeck", Vector3(0.0, 0.55, -3.0), Vector3(52.0, 0.35, 5.0), walkway_material)
	for index in range(6):
		var x := -22.0 + float(index) * 8.8
		_add_box(parent, "PromenadeBollard_%02d" % index, Vector3(x, 1.15, 0.2), Vector3(0.35, 1.2, 0.35), bollard_material)
		if index % 2 == 0:
			var bench := Node3D.new()
			bench.name = "PromenadeBench_%02d" % index
			bench.position = Vector3(x, 0.75, -5.4)
			parent.add_child(bench)
			_add_box(bench, "BenchSeat", Vector3.ZERO, Vector3(2.6, 0.22, 0.72), bench_material)
			_add_box(bench, "BenchBack", Vector3(0.0, 0.65, 0.32), Vector3(2.6, 0.9, 0.18), bench_material)
	var sign_root := Node3D.new()
	sign_root.name = "HarborWaterfrontSign"
	sign_root.position = Vector3(-23.0, 0.0, -7.0)
	parent.add_child(sign_root)
	_add_box(sign_root, "HarborSignPost", Vector3(0.0, 2.0, 0.0), Vector3(0.22, 4.0, 0.22), bollard_material)
	_add_box(sign_root, "HarborSignBoard", Vector3(0.0, 4.0, 0.0), Vector3(5.0, 1.1, 0.25), walkway_material)

func _add_ribbon_quad(surface: SurfaceTool, a: Vector2, b: Vector2, side: Vector2, y_a: float, y_b: float, half_width: float, lateral_offset: float) -> void:
	var center_offset := side * lateral_offset
	var left_a := a + center_offset + side * half_width
	var right_a := a + center_offset - side * half_width
	var left_b := b + center_offset + side * half_width
	var right_b := b + center_offset - side * half_width
	var va := Vector3(left_a.x, y_a, left_a.y)
	var vb := Vector3(right_a.x, y_a, right_a.y)
	var vc := Vector3(left_b.x, y_b, left_b.y)
	var vd := Vector3(right_b.x, y_b, right_b.y)
	surface.add_vertex(va)
	surface.add_vertex(vc)
	surface.add_vertex(vb)
	surface.add_vertex(vb)
	surface.add_vertex(vc)
	surface.add_vertex(vd)


func _build_highway_rest_stop(start: Vector3, finish: Vector3, route_index: int, segment_index: int) -> void:
	var midpoint := Vector2(start.x, start.z).lerp(Vector2(finish.x, finish.z), 0.5)
	var direction := (Vector2(finish.x, finish.z) - Vector2(start.x, start.z)).normalized()
	var side := Vector2(-direction.y, direction.x)
	var candidates: Array[Vector2] = [midpoint + side * 25.0, midpoint - side * 25.0]
	var site := Vector2.INF
	for candidate in candidates:
		if bool(terrain.call("is_land_position", candidate.x, candidate.y)):
			site = candidate
			break
	if site == Vector2.INF:
		return
	var stop := Node3D.new()
	stop.name = "HighwayRestStop_%02d_%02d" % [route_index, segment_index]
	stop.position = Vector3(site.x, float(terrain.call("get_terrain_height", site.x, site.y)), site.y)
	stop.rotation.y = atan2(-direction.x, -direction.y)
	add_child(stop)
	var building_material := _make_material(Color(0.38, 0.43, 0.46), 0.82, 0.12)
	var roof_material := _make_material(Color(0.12, 0.18, 0.22), 0.58, 0.3)
	var glass_material := _make_material(Color(0.12, 0.34, 0.43), 0.22, 0.25)
	var fuel_material := _make_material(Color(0.78, 0.72, 0.48), 0.72, 0.08)
	_add_box(stop, "RestStopMarket", Vector3(0.0, 3.0, -8.0), Vector3(22.0, 6.0, 12.0), building_material)
	_add_box(stop, "RestStopGlassFront", Vector3(0.0, 3.0, -14.1), Vector3(17.0, 3.8, 0.18), glass_material)
	_add_box(stop, "RestStopRoof", Vector3(0.0, 6.25, -8.0), Vector3(24.0, 0.55, 14.0), roof_material)
	_add_box(stop, "FuelCanopy", Vector3(0.0, 4.8, 8.0), Vector3(20.0, 0.45, 12.0), roof_material)
	for pump in range(4):
		var x := -7.0 + float(pump) * 4.7
		_add_box(stop, "FuelPump_%02d" % pump, Vector3(x, 1.0, 8.0), Vector3(0.9, 2.0, 0.8), fuel_material)
	for charger in range(2):
		_add_box(stop, "EVCharger_%02d" % charger, Vector3(-7.0 + float(charger) * 4.0, 1.0, 17.0), Vector3(0.9, 2.0, 0.7), glass_material)
	for bay in range(5):
		_add_box(stop, "ParkingBayLine_%02d" % bay, Vector3(-10.0 + float(bay) * 5.0, 0.13, 20.0), Vector3(0.12, 0.04, 7.0), fuel_material)
	landmark_records.append({
		"id": "highway_rest_stop_%02d_%02d" % [route_index, segment_index],
		"name": "Highway Rest Stop",
		"position": stop.position
	})

func _build_bridge_supports(samples: Array[Vector3], route_index: int, segment_index: int) -> void:
	for index in range(0, samples.size(), 3):
		var point := samples[index]
		var pier := MeshInstance3D.new()
		pier.name = "BridgePier_%02d_%02d_%02d" % [route_index, segment_index, index]
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.35, 5.8, 1.35)
		pier.mesh = mesh
		pier.position = Vector3(point.x, 2.9, point.z)
		pier.material_override = bridge_material
		add_child(pier)



func _build_city_overpasses() -> void:
	var city_names: Array = region_manager.call("get_city_names")
	var built := 0
	for city_value in city_names:
		var city_name := str(city_value)
		if city_name != active_city_name:
			continue
		var anchor := _city_anchor(city_name)
		if anchor == Vector3.INF:
			continue
		var center := Vector2(anchor.x, anchor.z)
		var valid := true
		for sample_index in range(17):
			var sample := center + Vector2(-120.0 + float(sample_index) * 15.0, 0.0)
			if not bool(terrain.call("is_land_position", sample.x, sample.y)):
				valid = false
				break
		if not valid:
			continue
		var deck_surface := SurfaceTool.new()
		deck_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		deck_surface.set_material(road_material)
		var marking_surface := SurfaceTool.new()
		marking_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		marking_surface.set_material(road_marking_material)
		var barrier_surface := SurfaceTool.new()
		barrier_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		barrier_surface.set_material(bridge_material)
		for step in range(16):
			var x0 := -120.0 + float(step) * 15.0
			var x1 := x0 + 15.0
			var p0 := center + Vector2(x0, 0.0)
			var p1 := center + Vector2(x1, 0.0)
			var ramp0 := 5.5 * (1.0 - absf(x0) / 120.0)
			var ramp1 := 5.5 * (1.0 - absf(x1) / 120.0)
			var y0 := float(terrain.call("get_terrain_height", p0.x, p0.y)) + ramp0 + 0.65
			var y1 := float(terrain.call("get_terrain_height", p1.x, p1.y)) + ramp1 + 0.65
			var direction := (p1 - p0).normalized()
			var side := Vector2(-direction.y, direction.x)
			_add_ribbon_quad(deck_surface, p0, p1, side, y0, y1, 7.0, 0.0)
			_add_ribbon_quad(marking_surface, p0, p1, side, y0 + 0.06, y1 + 0.06, 0.13, 0.0)
			for side_sign in [-1.0, 1.0]:
				var lower0 := Vector3(p0.x, y0 + 0.25, p0.y) + Vector3(side.x * 7.2 * side_sign, 0.0, side.y * 7.2 * side_sign)
				var lower1 := Vector3(p1.x, y1 + 0.25, p1.y) + Vector3(side.x * 7.2 * side_sign, 0.0, side.y * 7.2 * side_sign)
				var upper0 := lower0 + Vector3(0.0, 1.0, 0.0)
				var upper1 := lower1 + Vector3(0.0, 1.0, 0.0)
				barrier_surface.add_vertex(lower0)
				barrier_surface.add_vertex(upper0)
				barrier_surface.add_vertex(lower1)
				barrier_surface.add_vertex(lower1)
				barrier_surface.add_vertex(upper0)
				barrier_surface.add_vertex(upper1)
		deck_surface.generate_normals()
		marking_surface.generate_normals()
		barrier_surface.generate_normals()
		var deck := MeshInstance3D.new()
		deck.name = city_name.replace(" ", "") + "_UrbanFlyoverDeck"
		var committed_deck_mesh := _commit_surface_tool_if_valid(deck_surface)
		if committed_deck_mesh == null:
			return
		deck.mesh = committed_deck_mesh
		deck.material_override = road_material
		deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(deck)
		var markings := MeshInstance3D.new()
		markings.name = deck.name + "_Markings"
		var committed_markings_mesh := _commit_surface_tool_if_valid(marking_surface)
		if committed_markings_mesh == null:
			return
		markings.mesh = committed_markings_mesh
		markings.material_override = road_marking_material
		markings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(markings)
		var barriers := MeshInstance3D.new()
		barriers.name = deck.name + "_Barriers"
		var committed_barriers_mesh := _commit_surface_tool_if_valid(barrier_surface)
		if committed_barriers_mesh == null:
			return
		barriers.mesh = committed_barriers_mesh
		barriers.material_override = bridge_material
		barriers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(barriers)
		for support_index in range(3):
			var support_x := -45.0 + float(support_index) * 45.0
			var support_point := center + Vector2(support_x, 0.0)
			var support_ground := float(terrain.call("get_terrain_height", support_point.x, support_point.y))
			var support_height := 5.5 * (1.0 - absf(support_x) / 120.0) + 0.65
			var pier := MeshInstance3D.new()
			pier.name = deck.name + "_Pier_%02d" % support_index
			var pier_mesh := BoxMesh.new()
			pier_mesh.size = Vector3(1.8, maxf(1.0, support_height), 1.8)
			pier.mesh = pier_mesh
			pier.position = Vector3(support_point.x, support_ground + support_height * 0.5, support_point.y)
			pier.material_override = bridge_material
			add_child(pier)
		landmark_records.append({
			"id": "urban_flyover_" + city_name.to_lower().replace(" ", "_"),
			"name": city_name + " Urban Flyover",
			"position": anchor + Vector3(0.0, 5.5, 0.0)
		})
		built += 1
	print("SYSTEM WORLD: urban flyover prototypes built=", built)


func _build_city_tunnels() -> void:
	var city_names: Array = region_manager.call("get_city_names")
	var built := 0
	for city_index in range(city_names.size()):
		var city_name: String = str(city_names[city_index])
		if city_name != active_city_name:
			continue
		var anchor := _city_anchor(city_name)
		if anchor == Vector3.INF:
			continue
		var radial := Vector2(anchor.x, anchor.z).normalized()
		if radial.length_squared() < 0.01:
			radial = Vector2.RIGHT
		var directions: Array[Vector2] = [
			radial.rotated(PI * 0.5),
			radial,
			radial.rotated(-PI * 0.5),
			Vector2.UP
		]
		var chosen_position := Vector2.INF
		var chosen_direction := Vector2.ZERO
		for direction in directions:
			var requested := Vector2(anchor.x, anchor.z) + direction * 175.0
			var candidate := _nearest_land(requested)
			if candidate == Vector2.INF:
				continue
			var valid := true
			var min_height := INF
			var max_height := -INF
			for sample_index in range(9):
				var along := -42.0 + float(sample_index) * 10.5
				var sample := candidate + direction * along
				if not bool(terrain.call("is_land_position", sample.x, sample.y)):
					valid = false
					break
				var height := float(terrain.call("get_terrain_height", sample.x, sample.y))
				min_height = minf(min_height, height)
				max_height = maxf(max_height, height)
			if valid and max_height - min_height <= 4.0:
				chosen_position = candidate
				chosen_direction = direction
				break
		if chosen_position == Vector2.INF:
			continue
		var tunnel := Node3D.new()
		tunnel.name = city_name.replace(" ", "") + "_RoadTunnel"
		var ground_y := float(terrain.call("get_terrain_height", chosen_position.x, chosen_position.y))
		tunnel.position = Vector3(chosen_position.x, ground_y + 0.25, chosen_position.y)
		tunnel.rotation.y = atan2(-chosen_direction.x, -chosen_direction.y)
		add_child(tunnel)
		_build_tunnel_structure(tunnel, city_name)
		landmark_records.append({
			"id": "road_tunnel_" + city_name.to_lower().replace(" ", "_"),
			"name": city_name + " Road Tunnel",
			"position": tunnel.position
		})
		built += 1
	print("SYSTEM WORLD: city road tunnel visual prototypes built=", built)


func _build_tunnel_structure(parent: Node3D, city_name: String) -> void:
	var concrete := _make_material(Color(0.25, 0.29, 0.32), 0.9, 0.12)
	var inner_concrete := _make_material(Color(0.12, 0.15, 0.18), 0.96, 0.0)
	var road := _make_material(Color(0.045, 0.052, 0.06), 0.98, 0.0)
	var marking := _make_material(Color(0.88, 0.82, 0.57), 0.82, 0.0)
	var lamp := _make_material(Color(0.72, 0.82, 0.9), 0.35, 0.0)
	lamp.emission_enabled = true
	lamp.emission = Color(0.42, 0.62, 0.82)
	lamp.emission_energy_multiplier = 1.35
	_add_box(parent, "TunnelRoadBed", Vector3(0.0, -0.12, 0.0), Vector3(15.0, 0.35, 84.0), road)
	_add_box(parent, "TunnelLeftWall", Vector3(-7.5, 3.0, 0.0), Vector3(0.8, 6.0, 84.0), concrete)
	_add_box(parent, "TunnelRightWall", Vector3(7.5, 3.0, 0.0), Vector3(0.8, 6.0, 84.0), concrete)
	_add_box(parent, "TunnelCeiling", Vector3(0.0, 6.25, 0.0), Vector3(15.8, 0.7, 84.0), inner_concrete)
	for end_sign in [-1.0, 1.0]:
		var z: float = float(end_sign) * 42.0
		_add_box(parent, "TunnelPortalLeft_%s" % str(end_sign), Vector3(-7.1, 3.15, z), Vector3(1.2, 6.3, 1.8), concrete)
		_add_box(parent, "TunnelPortalRight_%s" % str(end_sign), Vector3(7.1, 3.15, z), Vector3(1.2, 6.3, 1.8), concrete)
		_add_box(parent, "TunnelPortalHeader_%s" % str(end_sign), Vector3(0.0, 6.25, z), Vector3(15.4, 1.1, 1.8), concrete)
		_add_box(parent, "TunnelApproach_%s" % str(end_sign), Vector3(0.0, -0.12, end_sign * 57.0), Vector3(15.0, 0.3, 30.0), road)
		_add_box(parent, "TunnelApproachLine_%s" % str(end_sign), Vector3(0.0, 0.06, end_sign * 57.0), Vector3(0.22, 0.035, 25.0), marking)
	for lane_side in [-1.0, 1.0]:
		_add_box(parent, "TunnelEdgeLine_%s" % str(lane_side), Vector3(lane_side * 6.2, 0.08, 0.0), Vector3(0.18, 0.04, 78.0), marking)
	for lamp_index in range(9):
		var z := -34.0 + float(lamp_index) * 8.5
		_add_box(parent, "TunnelCeilingLamp_%02d" % lamp_index, Vector3(0.0, 5.78, z), Vector3(1.25, 0.12, 0.42), lamp)
	for sign_side in [-1.0, 1.0]:
		_add_box(parent, "TunnelSafetyBay_%s" % str(sign_side), Vector3(sign_side * 6.72, 1.25, 0.0), Vector3(0.22, 1.6, 3.0), concrete)
	_add_box(parent, "TunnelNameSign", Vector3(0.0, 7.2, -43.2), Vector3(10.0, 0.55, 0.35), bridge_material)
	_add_box(parent, "TunnelNameSignRear", Vector3(0.0, 7.2, 43.2), Vector3(10.0, 0.55, 0.35), bridge_material)


func _build_rural_access_roads() -> void:
	if not region_manager.has_method("get_village_names") or not region_manager.has_method("get_village_anchor"):
		return
	var city_names: Array = region_manager.call("get_city_names")
	var village_names: Array = region_manager.call("get_village_names")
	var built := 0
	for village_value in village_names:
		var village_name := str(village_value)
		var village_anchor: Vector3 = region_manager.call("get_village_anchor", village_name)
		if village_anchor == Vector3.INF:
			continue
		var best_city := ""
		var best_distance := INF
		var best_finish := Vector3.INF
		for city_value in city_names:
			var city_name := str(city_value)
			var city_anchor := _city_anchor(city_name)
			if city_anchor == Vector3.INF:
				continue
			var distance := Vector2(village_anchor.x, village_anchor.z).distance_to(Vector2(city_anchor.x, city_anchor.z))
			if distance >= best_distance:
				continue
			if not _is_land_road_corridor(village_anchor, city_anchor):
				continue
			best_city = city_name
			best_distance = distance
			best_finish = city_anchor
		if best_city.is_empty() or best_city != active_city_name:
			continue
		var start_2d := Vector2(village_anchor.x, village_anchor.z)
		var finish_2d := Vector2(best_finish.x, best_finish.z)
		var steps := maxi(10, int(best_distance / 20.0))
		var road_surface := SurfaceTool.new()
		road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		road_surface.set_material(road_material)
		var line_material := _make_material(Color(0.88, 0.82, 0.57), 0.82, 0.0)
		var line_surface := SurfaceTool.new()
		line_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		line_surface.set_material(line_material)
		for step in range(steps):
			var t0 := float(step) / float(steps)
			var t1 := float(step + 1) / float(steps)
			var a := start_2d.lerp(finish_2d, t0)
			var b := start_2d.lerp(finish_2d, t1)
			var direction := (b - a).normalized()
			if direction.length_squared() < 0.001:
				continue
			var side := Vector2(-direction.y, direction.x)
			var y_a := float(terrain.call("get_terrain_height", a.x, a.y)) + 0.42
			var y_b := float(terrain.call("get_terrain_height", b.x, b.y)) + 0.42
			_add_ribbon_quad(road_surface, a, b, side, y_a, y_b, 4.2, 0.0)
			if step % 3 == 0:
				_add_ribbon_quad(line_surface, a, b, side, y_a + 0.035, y_b + 0.035, 0.12, 0.0)
		road_surface.generate_normals()
		line_surface.generate_normals()
		var road_mesh := MeshInstance3D.new()
		road_mesh.name = "RuralAccessRoad_" + village_name.replace(" ", "")
		var committed_rural_road_mesh := _commit_surface_tool_if_valid(road_surface)
		if committed_rural_road_mesh == null:
			return
		road_mesh.mesh = committed_rural_road_mesh
		road_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(road_mesh)
		var line_mesh := MeshInstance3D.new()
		line_mesh.name = road_mesh.name + "_CenterMarkings"
		var committed_line_mesh := _commit_surface_tool_if_valid(line_surface)
		if committed_line_mesh == null:
			return
		line_mesh.mesh = committed_line_mesh
		line_mesh.material_override = line_material
		line_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(line_mesh)
		landmark_records.append({
			"id": "rural_road_" + village_name.to_lower().replace(" ", "_"),
			"name": village_name + " Access Road",
			"position": (village_anchor + best_finish) * 0.5
		})
		built += 1
	print("SYSTEM WORLD: rural access road prototypes built=", built)


func _is_land_road_corridor(start: Vector3, finish: Vector3) -> bool:
	var start_2d := Vector2(start.x, start.z)
	var finish_2d := Vector2(finish.x, finish.z)
	var distance := start_2d.distance_to(finish_2d)
	var steps := maxi(12, int(distance / 18.0))
	for sample_index in range(steps + 1):
		var point := start_2d.lerp(finish_2d, float(sample_index) / float(steps))
		if not bool(terrain.call("is_land_position", point.x, point.y)):
			return false
	return true


func _build_city_ports() -> void:
	var city_names: Array = region_manager.call("get_city_names")
	for city_value in city_names:
		var city_name := str(city_value)
		if city_name != active_city_name:
			continue
		var anchor := _city_anchor(city_name)
		if anchor == Vector3.INF:
			continue
		var site := _find_waterfront(Vector2(anchor.x, anchor.z))
		if site == Vector2.INF:
			continue
		var port := Node3D.new()
		port.name = city_name.replace(" ", "") + "PortAndHarbor"
		port.position = Vector3(site.x, float(terrain.call("get_terrain_height", site.x, site.y)) + 0.25, site.y)
		add_child(port)
		var dock := MeshInstance3D.new()
		var dock_mesh := BoxMesh.new()
		dock_mesh.size = Vector3(42.0, 0.7, 15.0)
		dock.mesh = dock_mesh
		dock.material_override = port_material
		port.add_child(dock)
		for pier_index in range(4):
			var pier := MeshInstance3D.new()
			var pier_mesh := BoxMesh.new()
			pier_mesh.size = Vector3(2.0, 1.1, 28.0)
			pier.mesh = pier_mesh
			pier.position = Vector3(-15.0 + float(pier_index) * 10.0, 0.15, 15.0)
			pier.material_override = bridge_material
			port.add_child(pier)
		_build_port_cranes(port)
		_build_port_terminal_facilities(port)
		var outward := (site - Vector2(anchor.x, anchor.z)).normalized()
		_build_waterfront_promenade(port, outward)
		_build_ship_visual(port, outward)
		_build_access_road(anchor, port.position, "PortAccess_" + city_name.replace(" ", ""), 5.5)
		landmark_records.append({
			"id": "port_" + city_name.to_lower().replace(" ", "_"),
			"name": city_name + " International Harbor",
			"position": port.position
		})

func _find_waterfront(origin: Vector2) -> Vector2:
	var best := Vector2.INF
	var best_distance := INF
	for radius in range(80, 221, 20):
		for index in range(24):
			var angle := TAU * float(index) / 24.0
			var candidate := origin + Vector2(cos(angle), sin(angle)) * float(radius)
			if not bool(terrain.call("is_land_position", candidate.x, candidate.y)):
				continue
			var water_point := candidate + Vector2(cos(angle), sin(angle)) * 24.0
			if bool(terrain.call("is_land_position", water_point.x, water_point.y)):
				continue
			var distance := candidate.distance_squared_to(origin)
			if distance < best_distance:
				best_distance = distance
				best = candidate
		if best != Vector2.INF:
			break
	return best

func _build_ship_visual(parent: Node3D, outward: Vector2) -> void:
	var ship := Node3D.new()
	ship.name = "HarborPassengerAndCargoShip"
	ship.position = Vector3(outward.x * 31.0, 0.7, outward.y * 31.0)
	ship.rotation.y = atan2(-outward.x, -outward.y)
	parent.add_child(ship)
	var hull_material := _make_material(Color(0.075, 0.16, 0.22), 0.58, 0.48)
	var deck_material := _make_material(Color(0.68, 0.69, 0.65), 0.75, 0.12)
	var container_material := _make_material(Color(0.56, 0.22, 0.13), 0.78, 0.08)
	_add_box(ship, "ShipHull", Vector3(0.0, 0.0, 0.0), Vector3(9.0, 2.8, 25.0), hull_material)
	_add_box(ship, "ShipDeck", Vector3(0.0, 1.55, 0.0), Vector3(8.0, 0.35, 22.0), deck_material)
	_add_box(ship, "ShipBridge", Vector3(0.0, 3.2, -7.0), Vector3(5.0, 3.2, 5.0), deck_material)
	for row in range(2):
		for column in range(2):
			_add_box(
				ship,
				"CargoContainer_%02d_%02d" % [row, column],
				Vector3(-2.0 + float(column) * 4.0, 2.8, 1.5 + float(row) * 5.0),
				Vector3(3.6, 2.2, 4.6),
				container_material
			)

func _build_port_cranes(parent: Node3D) -> void:
	for index in range(2):
		var crane := Node3D.new()
		crane.name = "HarborCrane_%02d" % index
		crane.position = Vector3(-13.0 + float(index) * 26.0, 0.0, -5.0)
		parent.add_child(crane)
		var mast := MeshInstance3D.new()
		var mast_mesh := BoxMesh.new()
		mast_mesh.size = Vector3(0.65, 13.0, 0.65)
		mast.mesh = mast_mesh
		mast.position.y = 6.5
		mast.material_override = bridge_material
		crane.add_child(mast)
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(11.0, 0.5, 0.5)
		arm.mesh = arm_mesh
		arm.position = Vector3(5.0, 12.5, 0.0)
		arm.material_override = bridge_material
		crane.add_child(arm)

func _build_aircraft_and_train_fleets() -> void:
	var city_names: Array = region_manager.call("get_city_names")
	for city_value in city_names:
		var city_name := str(city_value)
		if city_name != active_city_name:
			continue
		var anchor := _city_anchor(city_name)
		if anchor == Vector3.INF:
			continue
		var airport := _nearest_land(Vector2(anchor.x + 205.0, anchor.z - 35.0))
		if airport != Vector2.INF:
			var plane := Node3D.new()
			plane.name = city_name.replace(" ", "") + "_ParkedPassengerAircraft"
			plane.position = Vector3(airport.x, float(terrain.call("get_terrain_height", airport.x, airport.y)) + 1.0, airport.y)
			add_child(plane)
			_build_aircraft_visual(plane)
			_build_access_road(anchor, plane.position, "AirportAccess_" + city_name.replace(" ", ""), 6.0)
		var station := _nearest_land(Vector2(anchor.x - 205.0, anchor.z + 35.0))
		if station != Vector2.INF:
			var train := Node3D.new()
			train.name = city_name.replace(" ", "") + "_CentralStationTrain"
			train.position = Vector3(station.x, float(terrain.call("get_terrain_height", station.x, station.y)) + 0.3, station.y)
			add_child(train)
			_build_train_visual(train)
			_build_access_road(anchor, train.position, "StationAccess_" + city_name.replace(" ", ""), 4.8)


func _build_access_road(start: Vector3, finish: Vector3, road_name: String, half_width: float) -> void:
	if not _is_land_road_corridor(start, finish):
		return
	var start_2d := Vector2(start.x, start.z)
	var finish_2d := Vector2(finish.x, finish.z)
	var distance := start_2d.distance_to(finish_2d)
	if distance < 8.0:
		return
	var steps := maxi(8, int(distance / 14.0))
	var road_surface := SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	road_surface.set_material(road_material)
	var edge_material := _make_material(Color(0.88, 0.82, 0.57), 0.82, 0.0)
	var edge_surface := SurfaceTool.new()
	edge_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	edge_surface.set_material(edge_material)
	for step in range(steps):
		var t0 := float(step) / float(steps)
		var t1 := float(step + 1) / float(steps)
		var a := start_2d.lerp(finish_2d, t0)
		var b := start_2d.lerp(finish_2d, t1)
		var direction := (b - a).normalized()
		if direction.length_squared() < 0.001:
			continue
		var side := Vector2(-direction.y, direction.x)
		var y_a := float(terrain.call("get_terrain_height", a.x, a.y)) + 0.46
		var y_b := float(terrain.call("get_terrain_height", b.x, b.y)) + 0.46
		_add_ribbon_quad(road_surface, a, b, side, y_a, y_b, half_width, 0.0)
		_add_ribbon_quad(edge_surface, a, b, side, y_a + 0.035, y_b + 0.035, 0.12, half_width - 0.35)
		_add_ribbon_quad(edge_surface, a, b, side, y_a + 0.035, y_b + 0.035, 0.12, -half_width + 0.35)
	road_surface.generate_normals()
	edge_surface.generate_normals()
	var road_mesh := MeshInstance3D.new()
	road_mesh.name = road_name
	var committed_access_road := _commit_surface_tool_if_valid(road_surface)
	if committed_access_road == null:
		return
	road_mesh.mesh = committed_access_road
	road_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road_mesh)
	var edge_mesh := MeshInstance3D.new()
	edge_mesh.name = road_name + "_EdgeLines"
	var committed_access_edges := _commit_surface_tool_if_valid(edge_surface)
	if committed_access_edges == null:
		road_mesh.queue_free()
		return
	edge_mesh.mesh = committed_access_edges
	edge_mesh.material_override = edge_material
	edge_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edge_mesh)
	landmark_records.append({
		"id": road_name.to_lower(),
		"name": road_name.replace("_", " "),
		"position": (start + finish) * 0.5
	})

func _nearest_land(origin: Vector2) -> Vector2:
	if bool(terrain.call("is_land_position", origin.x, origin.y)):
		return origin
	for radius_step in range(1, 13):
		var radius := float(radius_step) * 18.0
		for sample in range(24):
			var angle := TAU * float(sample) / 24.0
			var candidate := origin + Vector2(cos(angle), sin(angle)) * radius
			if bool(terrain.call("is_land_position", candidate.x, candidate.y)):
				return candidate
	return Vector2.INF

func _build_aircraft_visual(parent: Node3D) -> void:
	var body_material := _make_material(Color(0.78, 0.81, 0.83), 0.42, 0.28)
	var dark_material := _make_material(Color(0.12, 0.18, 0.23), 0.38, 0.3)
	var runway_material := _make_material(Color(0.075, 0.085, 0.095), 0.96, 0.0)
	var runway_marking := _make_material(Color(0.9, 0.9, 0.84), 0.8, 0.0)
	_add_box(parent, "AirportRunwaySurface", Vector3(0.0, -0.68, 0.0), Vector3(150.0, 0.22, 28.0), runway_material)
	for index in range(11):
		_add_box(parent, "RunwayCenterMark_%02d" % index, Vector3(0.0, -0.54, -55.0 + float(index) * 11.0), Vector3(1.1, 0.04, 5.0), runway_marking)
	var runway_light_material := _make_material(Color(0.45, 0.82, 1.0), 0.3, 0.0)
	runway_light_material.emission_enabled = true
	runway_light_material.emission = Color(0.25, 0.65, 1.0)
	runway_light_material.emission_energy_multiplier = 1.4
	var light_mesh := SphereMesh.new()
	light_mesh.radius = 0.18
	light_mesh.height = 0.36
	var runway_light_multi := MultiMesh.new()
	runway_light_multi.transform_format = MultiMesh.TRANSFORM_3D
	runway_light_multi.mesh = light_mesh
	var light_transforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		for index in range(15):
			var light_position := Vector3(side * 14.5, -0.42, -70.0 + float(index) * 10.0)
			light_transforms.append(Transform3D(Basis(), light_position))
	runway_light_multi.instance_count = light_transforms.size()
	for index in range(light_transforms.size()):
		runway_light_multi.set_instance_transform(index, light_transforms[index])
	var runway_lights := MultiMeshInstance3D.new()
	runway_lights.name = "RunwayEdgeLightMultiMesh"
	runway_lights.multimesh = runway_light_multi
	runway_lights.material_override = runway_light_material
	runway_lights.visibility_range_end = 1800.0
	parent.add_child(runway_lights)
	_add_box(parent, "AircraftFuselage", Vector3(0.0, 1.7, 0.0), Vector3(3.2, 2.1, 19.0), body_material)
	_add_box(parent, "AircraftMainWing", Vector3(0.0, 1.2, 0.0), Vector3(25.0, 0.35, 3.6), body_material)
	_add_box(parent, "AircraftTailWing", Vector3(0.0, 2.5, 7.0), Vector3(9.0, 0.3, 2.1), body_material)
	_add_box(parent, "AircraftVerticalTail", Vector3(0.0, 3.4, 7.4), Vector3(0.35, 2.1, 2.0), body_material)
	for side in [-1.0, 1.0]:
		_add_box(parent, "AircraftEngine", Vector3(side * 6.0, 0.65, 0.1), Vector3(1.8, 1.5, 4.0), dark_material)
		_add_box(parent, "AircraftWingTip", Vector3(side * 12.1, 1.25, 0.0), Vector3(0.35, 0.45, 1.0), dark_material)
	_build_airport_terminal(parent, body_material, dark_material, runway_material)

func _build_train_visual(parent: Node3D) -> void:
	var body_material := _make_material(Color(0.12, 0.28, 0.36), 0.45, 0.38)
	var window_material := _make_material(Color(0.08, 0.22, 0.31), 0.2, 0.35)
	var track_material := _make_material(Color(0.28, 0.3, 0.32), 0.62, 0.62)
	_add_box(parent, "StationTrackBed", Vector3(0.0, -0.12, 22.0), Vector3(6.5, 0.22, 82.0), track_material)
	for side in [-1.0, 1.0]:
		_add_box(parent, "StationRail", Vector3(side * 2.0, 0.02, 22.0), Vector3(0.18, 0.18, 82.0), track_material)
	for sleeper_index in range(20):
		_add_box(parent, "RailSleeper_%02d" % sleeper_index, Vector3(0.0, -0.01, -17.0 + float(sleeper_index) * 4.0), Vector3(5.8, 0.16, 0.35), bridge_material)
	for car_index in range(4):
		var carriage := Node3D.new()
		carriage.name = "TrainCarriage_%02d" % car_index
		carriage.position.z = float(car_index) * 15.0
		parent.add_child(carriage)
		_add_box(carriage, "TrainCarBody", Vector3(0.0, 1.8, 0.0), Vector3(3.5, 3.2, 13.5), body_material)
		_add_box(carriage, "TrainWindows", Vector3(0.0, 2.45, -0.1), Vector3(3.58, 1.05, 10.2), window_material)
		for side in [-1.0, 1.0]:
			for axle in [-4.5, 4.5]:
				var wheel := MeshInstance3D.new()
				var wheel_mesh := CylinderMesh.new()
				wheel_mesh.top_radius = 0.58
				wheel_mesh.bottom_radius = 0.58
				wheel_mesh.height = 0.28
				wheel.mesh = wheel_mesh
				wheel.rotation.z = PI * 0.5
				wheel.position = Vector3(side * 1.8, 0.62, axle)
				wheel.material_override = window_material
				carriage.add_child(wheel)
	_build_station_facilities(parent, body_material, window_material, track_material)


func _build_airport_terminal(parent: Node3D, facade: Material, glass: Material, apron_material: Material) -> void:
	var terminal := Node3D.new()
	terminal.name = "AirportPassengerTerminal"
	terminal.position = Vector3(0.0, -0.55, 48.0)
	parent.add_child(terminal)
	_add_box(terminal, "TerminalMainHall", Vector3(0.0, 5.0, 0.0), Vector3(58.0, 10.0, 22.0), facade)
	_add_box(terminal, "TerminalGlassFront", Vector3(0.0, 4.5, -11.2), Vector3(52.0, 7.0, 0.25), glass)
	_add_box(terminal, "TerminalRoofCanopy", Vector3(0.0, 10.4, -2.0), Vector3(62.0, 0.8, 27.0), glass)
	_add_box(terminal, "TerminalDepartureWing", Vector3(-34.0, 3.2, 4.0), Vector3(14.0, 6.4, 18.0), facade)
	_add_box(terminal, "TerminalArrivalWing", Vector3(34.0, 3.2, 4.0), Vector3(14.0, 6.4, 18.0), facade)
	_add_box(terminal, "AirportApron", Vector3(0.0, -0.35, -19.0), Vector3(78.0, 0.22, 15.0), apron_material)
	for bay in range(4):
		_add_box(terminal, "ApronStandLine_%02d" % bay, Vector3(-27.0 + float(bay) * 18.0, -0.20, -18.0), Vector3(0.16, 0.035, 12.0), glass)
	var tower := Node3D.new()
	tower.name = "AirportControlTower"
	tower.position = Vector3(39.0, 0.0, 16.0)
	terminal.add_child(tower)
	_add_box(tower, "ControlTowerShaft", Vector3(0.0, 10.0, 0.0), Vector3(5.0, 20.0, 5.0), facade)
	_add_box(tower, "ControlTowerCabin", Vector3(0.0, 21.0, 0.0), Vector3(9.0, 4.0, 9.0), glass)
	_add_box(tower, "ControlTowerRoof", Vector3(0.0, 23.2, 0.0), Vector3(10.0, 0.5, 10.0), facade)


func _build_station_facilities(parent: Node3D, facade: Material, glass: Material, track: Material) -> void:
	for side in [-1.0, 1.0]:
		var platform := Node3D.new()
		platform.name = "PassengerPlatform_%s" % str(side)
		platform.position = Vector3(side * 6.0, 0.0, 22.0)
		parent.add_child(platform)
		_add_box(platform, "PlatformSurface", Vector3(0.0, 0.12, 0.0), Vector3(4.0, 0.28, 78.0), facade)
		_add_box(platform, "PlatformCanopy", Vector3(0.0, 4.0, 0.0), Vector3(4.8, 0.3, 32.0), track)
		for support in [-14.0, 0.0, 14.0]:
			_add_box(platform, "CanopySupport_%s" % str(support), Vector3(0.0, 2.0, support), Vector3(0.22, 4.0, 0.22), track)
	var concourse := Node3D.new()
	concourse.name = "CentralStationConcourse"
	concourse.position = Vector3(0.0, 0.0, -35.0)
	parent.add_child(concourse)
	_add_box(concourse, "StationHall", Vector3(0.0, 4.0, 0.0), Vector3(34.0, 8.0, 18.0), facade)
	_add_box(concourse, "StationGlassFacade", Vector3(0.0, 3.8, -9.2), Vector3(28.0, 5.4, 0.25), glass)
	_add_box(concourse, "StationRoof", Vector3(0.0, 8.2, 0.0), Vector3(36.0, 0.6, 20.0), track)
	_add_box(concourse, "StationDepartureSign", Vector3(0.0, 7.0, -9.6), Vector3(8.0, 1.0, 0.25), track)


func _build_port_terminal_facilities(parent: Node3D) -> void:
	var warehouse_material := _make_material(Color(0.42, 0.45, 0.46), 0.88, 0.18)
	var roof_material := _make_material(Color(0.17, 0.21, 0.25), 0.62, 0.35)
	var container_material := _make_material(Color(0.62, 0.27, 0.15), 0.82, 0.12)
	var warehouse := Node3D.new()
	warehouse.name = "HarborCargoWarehouse"
	warehouse.position = Vector3(0.0, 0.0, -24.0)
	parent.add_child(warehouse)
	_add_box(warehouse, "CargoWarehouseBody", Vector3(0.0, 4.0, 0.0), Vector3(34.0, 8.0, 18.0), warehouse_material)
	_add_box(warehouse, "CargoWarehouseRoof", Vector3(0.0, 8.3, 0.0), Vector3(36.0, 0.6, 20.0), roof_material)
	for row in range(2):
		for column in range(3):
			_add_box(
				parent,
				"HarborContainer_%02d_%02d" % [row, column],
				Vector3(-20.0 + float(column) * 9.0, 1.3, -37.0 + float(row) * 6.0),
				Vector3(8.0, 2.6, 5.5),
				container_material
			)
	_add_box(parent, "HarborTruckLoadingApron", Vector3(0.0, 0.08, -12.0), Vector3(46.0, 0.18, 10.0), port_material)

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	instance.visibility_range_end = 1800.0
	parent.add_child(instance)

func _build_race_circuits() -> void:
	var city_names: Array = region_manager.call("get_city_names")
	for city_value in city_names:
		var city_name := str(city_value)
		if city_name != active_city_name:
			continue
		var anchor := _city_anchor(city_name)
		if anchor == Vector3.INF:
			continue
		var points: Array[Vector2] = []
		var valid := true
		for index in range(48):
			var angle := TAU * float(index) / 48.0
			var point := Vector2(anchor.x, anchor.z) + Vector2(cos(angle), sin(angle)) * 285.0
			if not bool(terrain.call("is_land_position", point.x, point.y)):
				valid = false
				break
			points.append(point)
		if not valid:
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(road_material)
		for index in range(points.size()):
			var a: Vector2 = points[index]
			var b: Vector2 = points[(index + 1) % points.size()]
			var direction := (b - a).normalized()
			var side := Vector2(-direction.y, direction.x)
			var y_a := float(terrain.call("get_terrain_height", a.x, a.y)) + 0.55
			var y_b := float(terrain.call("get_terrain_height", b.x, b.y)) + 0.55
			_add_ribbon_quad(surface, a, b, side, y_a, y_b, 5.5, 0.0)
		surface.generate_normals()
		var circuit := MeshInstance3D.new()
		circuit.name = city_name.replace(" ", "") + "RaceCircuit"
		var committed_circuit_mesh := _commit_surface_tool_if_valid(surface)
		if committed_circuit_mesh == null:
			return
		circuit.mesh = committed_circuit_mesh
		circuit.material_override = road_material
		circuit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(circuit)
		_build_race_facilities(city_name, anchor, points)
		landmark_records.append({
			"id": "race_circuit_" + city_name.to_lower().replace(" ", "_"),
			"name": city_name + " Motor Circuit",
			"position": anchor + Vector3(0.0, 0.5, 285.0)
		})


func _build_race_facilities(city_name: String, anchor: Vector3, points: Array[Vector2]) -> void:
	var barrier_material := _make_material(Color(0.78, 0.8, 0.82), 0.62, 0.28)
	var curb_material := _make_material(Color(0.78, 0.16, 0.12), 0.78, 0.0)
	var glass_material := _make_material(Color(0.2, 0.42, 0.52, 0.72), 0.3, 0.18)
	var barrier_surface := SurfaceTool.new()
	barrier_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	barrier_surface.set_material(barrier_material)
	var curb_surface := SurfaceTool.new()
	curb_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	curb_surface.set_material(curb_material)
	for index in range(points.size()):
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		var direction := (b - a).normalized()
		var outward := Vector2(direction.y, -direction.x)
		var barrier_a := a + outward * 8.5
		var barrier_b := b + outward * 8.5
		var ground_a := float(terrain.call("get_terrain_height", barrier_a.x, barrier_a.y))
		var ground_b := float(terrain.call("get_terrain_height", barrier_b.x, barrier_b.y))
		var lower_a := Vector3(barrier_a.x, ground_a + 0.25, barrier_a.y)
		var lower_b := Vector3(barrier_b.x, ground_b + 0.25, barrier_b.y)
		var upper_a := lower_a + Vector3(0.0, 1.35, 0.0)
		var upper_b := lower_b + Vector3(0.0, 1.35, 0.0)
		barrier_surface.add_vertex(lower_a)
		barrier_surface.add_vertex(upper_a)
		barrier_surface.add_vertex(lower_b)
		barrier_surface.add_vertex(lower_b)
		barrier_surface.add_vertex(upper_a)
		barrier_surface.add_vertex(upper_b)
		var curb_a := a + outward * 6.0
		var curb_b := b + outward * 6.0
		var curb_y_a := float(terrain.call("get_terrain_height", curb_a.x, curb_a.y)) + 0.62
		var curb_y_b := float(terrain.call("get_terrain_height", curb_b.x, curb_b.y)) + 0.62
		_add_ribbon_quad(curb_surface, curb_a, curb_b, outward, curb_y_a, curb_y_b, 0.65, 0.0)
	barrier_surface.generate_normals()
	curb_surface.generate_normals()
	var barriers := MeshInstance3D.new()
	barriers.name = city_name.replace(" ", "") + "_RaceSafetyBarrier"
	var committed_race_barrier_mesh := _commit_surface_tool_if_valid(barrier_surface)
	if committed_race_barrier_mesh == null:
		return
	barriers.mesh = committed_race_barrier_mesh
	barriers.material_override = barrier_material
	barriers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(barriers)
	var curbs := MeshInstance3D.new()
	curbs.name = city_name.replace(" ", "") + "_RaceKerbs"
	var committed_race_curb_mesh := _commit_surface_tool_if_valid(curb_surface)
	if committed_race_curb_mesh == null:
		barriers.queue_free()
		return
	curbs.mesh = committed_race_curb_mesh
	curbs.material_override = curb_material
	curbs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(curbs)
	var start_point: Vector2 = points[0]
	var start_ground := float(terrain.call("get_terrain_height", start_point.x, start_point.y))
	var start_root := Node3D.new()
	start_root.name = city_name.replace(" ", "") + "_RaceStartFinish"
	start_root.position = Vector3(start_point.x, start_ground + 0.8, start_point.y)
	add_child(start_root)
	_add_box(start_root, "StartFinishArchLeft", Vector3(-7.0, 5.0, 0.0), Vector3(0.8, 10.0, 0.8), barrier_material)
	_add_box(start_root, "StartFinishArchRight", Vector3(7.0, 5.0, 0.0), Vector3(0.8, 10.0, 0.8), barrier_material)
	_add_box(start_root, "StartFinishArchTop", Vector3(0.0, 9.8, 0.0), Vector3(14.8, 0.8, 0.8), barrier_material)
	_add_box(start_root, "StartFinishSign", Vector3(0.0, 8.5, 0.48), Vector3(8.0, 1.0, 0.2), glass_material)
	var facility_position := Vector2(anchor.x, anchor.z) + Vector2(315.0, -28.0)
	if bool(terrain.call("is_land_position", facility_position.x, facility_position.y)):
		var facility := Node3D.new()
		facility.name = city_name.replace(" ", "") + "_RacePitAndGrandstand"
		facility.position = Vector3(
			facility_position.x,
			float(terrain.call("get_terrain_height", facility_position.x, facility_position.y)),
			facility_position.y
		)
		add_child(facility)
		_add_box(facility, "PitGarage", Vector3(0.0, 4.0, 0.0), Vector3(38.0, 8.0, 16.0), barrier_material)
		_add_box(facility, "PitRoof", Vector3(0.0, 8.3, 0.0), Vector3(40.0, 0.6, 18.0), bridge_material)
		_add_box(facility, "GrandstandBase", Vector3(0.0, 2.0, -22.0), Vector3(34.0, 4.0, 10.0), bridge_material)
		for seat_row in range(3):
			_add_box(
				facility,
				"GrandstandTier_%02d" % seat_row,
				Vector3(0.0, 4.2 + float(seat_row) * 1.5, -25.0 - float(seat_row) * 2.0),
				Vector3(32.0, 0.45, 2.0),
				glass_material
			)

func get_landmark_locations() -> Array[Dictionary]:
	return landmark_records.duplicate(true)
