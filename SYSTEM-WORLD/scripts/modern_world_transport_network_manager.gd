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
var bridge_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var port_material: StandardMaterial3D
var landmark_records: Array[Dictionary] = []

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
	_build_intercity_corridors()
	_build_city_tunnels()
	_build_city_ports()
	_build_aircraft_and_train_fleets()
	_build_race_circuits()
	print("SYSTEM WORLD: transport corridor prototype initialized; landmarks=", landmark_records.size())

func _create_materials() -> void:
	road_material = _make_material(Color(0.075, 0.085, 0.095), 0.94, 0.0)
	bridge_material = _make_material(Color(0.24, 0.29, 0.34), 0.7, 0.42)
	rail_material = _make_material(Color(0.34, 0.37, 0.4), 0.68, 0.58)
	port_material = _make_material(Color(0.35, 0.38, 0.39), 0.82, 0.22)

func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _build_intercity_corridors() -> void:
	for route_index in range(CITY_ROUTES.size()):
		var route: Array = CITY_ROUTES[route_index]
		for segment_index in range(route.size() - 1):
			var start := _city_anchor(str(route[segment_index]))
			var finish := _city_anchor(str(route[segment_index + 1]))
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
		added += 1
	road_surface.generate_normals()
	rail_surface.generate_normals()
	if added > 0:
		var road_mesh := MeshInstance3D.new()
		road_mesh.name = "IntercityHighway_%02d_%02d" % [route_index, segment_index]
		road_mesh.mesh = road_surface.commit()
		road_mesh.material_override = road_material
		road_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(road_mesh)
		var rail_mesh := MeshInstance3D.new()
		rail_mesh.name = "IntercityRailCorridor_%02d_%02d" % [route_index, segment_index]
		rail_mesh.mesh = rail_surface.commit()
		rail_mesh.material_override = rail_material
		rail_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rail_mesh)
	if not bridge_samples.is_empty():
		_build_bridge_supports(bridge_samples, route_index, segment_index)
		landmark_records.append({
			"id": "bridge_%02d_%02d" % [route_index, segment_index],
			"name": "Intercity Bridge %02d-%02d" % [route_index + 1, segment_index + 1],
			"position": bridge_samples[int(bridge_samples.size() / 2)]
		})

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


func _build_city_tunnels() -> void:
	var city_names: Array = region_manager.call("get_city_names")
	var built := 0
	for city_index in range(city_names.size()):
		var city_name := str(city_names[city_index])
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
		var z := end_sign * 42.0
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

func _build_city_ports() -> void:
	var city_names: Array = region_manager.call("get_city_names")
	for city_value in city_names:
		var city_name := str(city_value)
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
		var outward := (site - Vector2(anchor.x, anchor.z)).normalized()
		_build_ship_visual(port, outward)
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
		var station := _nearest_land(Vector2(anchor.x - 205.0, anchor.z + 35.0))
		if station != Vector2.INF:
			var train := Node3D.new()
			train.name = city_name.replace(" ", "") + "_CentralStationTrain"
			train.position = Vector3(station.x, float(terrain.call("get_terrain_height", station.x, station.y)) + 0.3, station.y)
			add_child(train)
			_build_train_visual(train)

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
			var a := points[index]
			var b := points[(index + 1) % points.size()]
			var direction := (b - a).normalized()
			var side := Vector2(-direction.y, direction.x)
			var y_a := float(terrain.call("get_terrain_height", a.x, a.y)) + 0.55
			var y_b := float(terrain.call("get_terrain_height", b.x, b.y)) + 0.55
			_add_ribbon_quad(surface, a, b, side, y_a, y_b, 5.5, 0.0)
		surface.generate_normals()
		var circuit := MeshInstance3D.new()
		circuit.name = city_name.replace(" ", "") + "RaceCircuit"
		circuit.mesh = surface.commit()
		circuit.material_override = road_material
		circuit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(circuit)
		landmark_records.append({
			"id": "race_circuit_" + city_name.to_lower().replace(" ", "_"),
			"name": city_name + " Motor Circuit",
			"position": anchor + Vector3(0.0, 0.5, 285.0)
		})

func get_landmark_locations() -> Array[Dictionary]:
	return landmark_records.duplicate(true)
