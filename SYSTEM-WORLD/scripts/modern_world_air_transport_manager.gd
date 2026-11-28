extends Node3D
class_name ModernWorldAirTransportManager

signal ticket_created(ticket: Dictionary)
signal ticket_status_changed(ticket: Dictionary)
signal passenger_arrived(ticket: Dictionary)

const REGION_MANAGER_PATH := NodePath("../ModernWorldRegionManager")
const CITY_AIRPORT_OFFSET := Vector2(185.0, 145.0)
const AIRSHIP_LENGTH_M := 90.0
const AIRSHIP_BALLOON_DIAMETER_M := 28.0
const AIRSHIP_CABIN_LENGTH_M := 45.0
const AIRSHIP_MIN_CAPACITY := 40
const AIRSHIP_MAX_CAPACITY := 60
const AIRSHIP_ROUTE_RADIUS_M := 900.0
const AIRSHIP_CRUISE_ALTITUDE_M := 190.0
const AIRSHIP_SPEED_MPS := 42.0
const CITY_AIRCRAFT_CAPACITY := 180

var city_airports: Dictionary = {}
var routes: Dictionary = {}
var tickets: Dictionary = {}
var route_ticket_counts: Dictionary = {}
var ticket_sequence: int = 0
var _airship_follow: PathFollow3D
var _airship_station: Node3D


func _ready() -> void:
	_build_baghdad_airship_station()
	_build_baghdad_airship()
	_register_existing_city_airports()
	_build_bidirectional_city_routes()
	print("SYSTEM WORLD: air transport initialized. City terminals: ", city_airports.size(), " routes: ", routes.size(), " airship capacity: ", AIRSHIP_MIN_CAPACITY, "-", AIRSHIP_MAX_CAPACITY)


func _process(delta: float) -> void:
	if _airship_follow != null:
		_airship_follow.progress += AIRSHIP_SPEED_MPS * delta


func _register_existing_city_airports() -> void:
	var region_manager := get_parent().get_node_or_null("ModernWorldRegionManager")
	if region_manager == null:
		push_warning("SYSTEM WORLD: city airport anchors unavailable; air terminals remain unregistered.")
		return
	var anchors: Dictionary = region_manager.get("city_anchors")
	for city_name in anchors:
		var anchor: Vector2 = anchors[city_name]
		var terminal_position := Vector3(anchor.x + CITY_AIRPORT_OFFSET.x, 0.0, anchor.y + CITY_AIRPORT_OFFSET.y)
		register_city_airport(_city_id(str(city_name)), str(city_name), terminal_position, "prototype_world_city_anchor" if str(city_name) != "Baghdad" else "baghdad_world_anchor")


func _city_id(city_name: String) -> String:
	return city_name.to_lower().replace(" ", "_").replace(",", "")


func register_city_airport(city_id: String, city_name: String, world_position: Vector3, coordinate_source: String) -> bool:
	if city_id.strip_edges().is_empty() or city_name.strip_edges().is_empty():
		return false
	if city_airports.has(city_id):
		return false
	var airport_root := Node3D.new()
	airport_root.name = "CivilAirport_" + city_id
	airport_root.position = world_position
	airport_root.set_meta("system_airport_city_id", city_id)
	airport_root.set_meta("system_airport_city_name", city_name)
	airport_root.set_meta("system_coordinate_source", coordinate_source)
	add_child(airport_root)
	_build_civil_terminal(airport_root, city_name)
	_build_runway_and_apron(airport_root)
	city_airports[city_id] = {
		"city_id": city_id,
		"city_name": city_name,
		"position": world_position,
		"coordinate_source": coordinate_source,
		"terminal": airport_root
	}
	return true


func _build_bidirectional_city_routes() -> void:
	var city_ids: Array = city_airports.keys()
	for i in range(city_ids.size()):
		for j in range(i + 1, city_ids.size()):
			var origin_id := str(city_ids[i])
			var destination_id := str(city_ids[j])
			_register_route_pair(origin_id, destination_id, "aircraft")


func _register_route_pair(origin_id: String, destination_id: String, transport_type: String) -> void:
	if not city_airports.has(origin_id) or not city_airports.has(destination_id):
		return
	var origin: Dictionary = city_airports[origin_id]
	var destination: Dictionary = city_airports[destination_id]
	var distance := origin.position.distance_to(destination.position)
	var duration_minutes := maxi(5, int(ceil(distance / 230.0 / 60.0)))
	var route_id := origin_id + "__" + destination_id + "__" + transport_type
	var reverse_id := destination_id + "__" + origin_id + "__" + transport_type
	routes[route_id] = {"route_id": route_id, "origin_city_id": origin_id, "destination_city_id": destination_id, "transport_type": transport_type, "duration_minutes": duration_minutes, "capacity": CITY_AIRCRAFT_CAPACITY, "enabled": true}
	routes[reverse_id] = {"route_id": reverse_id, "origin_city_id": destination_id, "destination_city_id": origin_id, "transport_type": transport_type, "duration_minutes": duration_minutes, "capacity": CITY_AIRCRAFT_CAPACITY, "enabled": true}


func register_external_city_airport(city_id: String, city_name: String, world_position: Vector3) -> bool:
	return register_city_airport(city_id, city_name, world_position, "authored_external_city_anchor")


func create_ticket(player_id: String, route_id: String, passenger_count: int = 1) -> Dictionary:
	if player_id.strip_edges().is_empty() or not routes.has(route_id):
		return {}
	var route: Dictionary = routes[route_id]
	if not bool(route.get("enabled", false)) or passenger_count < 1 or passenger_count > int(route.capacity):
		return {}
	var occupied := int(route_ticket_counts.get(route_id, 0))
	if occupied + passenger_count > int(route.capacity):
		return {}
	ticket_sequence += 1
	var ticket_id := "AIR-%08d" % ticket_sequence
	var ticket := {
		"ticket_id": ticket_id,
		"player_id": player_id,
		"route_id": route_id,
		"passenger_count": passenger_count,
		"status": "pending_payment",
		"payment_reference": "",
		"created_unix": int(Time.get_unix_time_from_system())
	}
	tickets[ticket_id] = ticket
	route_ticket_counts[route_id] = occupied + passenger_count
	ticket_created.emit(ticket.duplicate(true))
	return ticket.duplicate(true)


func confirm_ticket_payment(ticket_id: String, payment_reference: String) -> bool:
	if not tickets.has(ticket_id) or payment_reference.strip_edges().is_empty():
		return false
	var ticket: Dictionary = tickets[ticket_id]
	if str(ticket.status) != "pending_payment":
		return false
	ticket.status = "paid"
	ticket.payment_reference = payment_reference
	tickets[ticket_id] = ticket
	ticket_status_changed.emit(ticket.duplicate(true))
	return true


func board_ticket(ticket_id: String, player_id: String) -> bool:
	if not tickets.has(ticket_id):
		return false
	var ticket: Dictionary = tickets[ticket_id]
	if str(ticket.player_id) != player_id or str(ticket.status) != "paid":
		return false
	ticket.status = "boarded"
	tickets[ticket_id] = ticket
	ticket_status_changed.emit(ticket.duplicate(true))
	return true


func complete_ticket_travel(ticket_id: String, player_id: String) -> Dictionary:
	if not tickets.has(ticket_id):
		return {}
	var ticket: Dictionary = tickets[ticket_id]
	if str(ticket.player_id) != player_id or str(ticket.status) != "boarded":
		return {}
	var route: Dictionary = routes.get(str(ticket.route_id), {})
	var destination_id := str(route.get("destination_city_id", ""))
	if not city_airports.has(destination_id):
		return {}
	var airport: Dictionary = city_airports[destination_id]
	ticket.status = "arrived"
	ticket.destination_city_id = destination_id
	ticket.arrival_position = airport.position
	tickets[ticket_id] = ticket
	ticket_status_changed.emit(ticket.duplicate(true))
	passenger_arrived.emit(ticket.duplicate(true))
	return {"ticket": ticket.duplicate(true), "destination_position": airport.position, "destination_city_name": airport.city_name}


func get_available_routes(origin_city_id: String = "") -> Array:
	var result: Array = []
	for route_id in routes:
		var route: Dictionary = routes[route_id]
		if bool(route.enabled) and (origin_city_id.is_empty() or str(route.origin_city_id) == origin_city_id):
			result.append(route.duplicate(true))
	return result


func get_ticket(ticket_id: String) -> Dictionary:
	return tickets.get(ticket_id, {}).duplicate(true)


func export_travel_state() -> Dictionary:
	return {"ticket_sequence": ticket_sequence, "tickets": tickets.duplicate(true), "route_ticket_counts": route_ticket_counts.duplicate(true)}


func restore_travel_state(state: Dictionary) -> bool:
	if not state.has("tickets") or not state.has("route_ticket_counts"):
		return false
	ticket_sequence = maxi(0, int(state.get("ticket_sequence", 0)))
	tickets = state.tickets.duplicate(true)
	route_ticket_counts = state.route_ticket_counts.duplicate(true)
	return true


func _build_civil_terminal(parent: Node3D, city_name: String) -> void:
	var shell_material := _material(Color(0.58, 0.66, 0.72), 0.34, 0.42)
	var glass_material := _material(Color(0.12, 0.32, 0.42, 0.82), 0.18, 0.52)
	var sign_material := _emissive_material(Color(0.12, 0.68, 0.96))
	_add_box(parent, "PassengerTerminalMain", Vector3(0, 7, 0), Vector3(90, 14, 52), shell_material)
	_add_box(parent, "TerminalGlassFacade", Vector3(0, 6.5, 26.4), Vector3(76, 9, 0.8), glass_material)
	_add_box(parent, "TerminalRoofCanopy", Vector3(0, 14.5, 0), Vector3(98, 1.2, 58), shell_material)
	_add_box(parent, "CheckInHall", Vector3(-18, 3.2, 2), Vector3(28, 0.5, 26), glass_material)
	_add_box(parent, "DepartureHall", Vector3(18, 3.2, 2), Vector3(28, 0.5, 26), glass_material)
	_add_box(parent, "BaggageArrivalWing", Vector3(0, 3.5, -30), Vector3(56, 7, 12), shell_material)
	_add_box(parent, "AirportCitySign", Vector3(0, 17, 27), Vector3(32, 2.4, 0.7), sign_material)
	for gate_index in range(4):
		var gate_x := -30.0 + float(gate_index) * 20.0
		_add_box(parent, "BoardingGate_%02d" % gate_index, Vector3(gate_x, 2.0, -28), Vector3(10, 4, 8), glass_material)
		_add_box(parent, "GateCanopy_%02d" % gate_index, Vector3(gate_x, 4.2, -28), Vector3(12, 0.6, 10), shell_material)
	for seat_index in range(12):
		var row := int(seat_index / 4)
		var col := seat_index % 4
		_add_box(parent, "WaitingSeat_%02d" % seat_index, Vector3(-24.0 + float(col) * 16.0, 1.2, 8.0 + float(row) * 5.0), Vector3(6, 1.1, 2.2), shell_material)
	_add_box(parent, "CheckInCounter", Vector3(-25, 2, 15), Vector3(24, 2, 3), shell_material)
	_add_box(parent, "BaggageCarousel", Vector3(0, 1.5, -31), Vector3(28, 1.0, 5), shell_material)
	parent.set_meta("system_terminal_features", ["check_in", "departure_boards", "boarding_gates", "waiting_lounge", "baggage_arrivals", "npc_passenger_spawn_points"])
	parent.set_meta("system_terminal_interior_state", "authored_exterior_and_interactive_layout_pending_player_ui_and_npc_binding")
	parent.set_meta("system_terminal_city_name", city_name)


func _build_runway_and_apron(parent: Node3D) -> void:
	var asphalt := _material(Color(0.075, 0.085, 0.095), 0.96)
	var concrete := _material(Color(0.38, 0.40, 0.42), 0.88)
	var marking := _emissive_material(Color(0.92, 0.88, 0.62))
	_add_box(parent, "CivilAirportApron", Vector3(0, 0.1, -115), Vector3(210, 0.25, 110), concrete)
	_add_box(parent, "CivilRunway", Vector3(0, 0.04, -260), Vector3(42, 0.18, 360), asphalt)
	for x in [-16.0, 16.0]:
		_add_box(parent, "RunwayEdgeLight", Vector3(x, 0.3, -260), Vector3(0.4, 0.4, 350), marking)
	_add_box(parent, "RunwayCenterMarking", Vector3(0, 0.16, -260), Vector3(0.7, 0.04, 320), marking)
	for index in range(8):
		var z := -165.0 - float(index) * 23.0
		_add_box(parent, "ApronTaxiLine_%02d" % index, Vector3(0, 0.28, z), Vector3(1.2, 0.04, 9), marking)


func _build_baghdad_airship_station() -> void:
	_airship_station = Node3D.new()
	_airship_station.name = "BaghdadAirshipPassengerStation"
	_airship_station.position = Vector3(0, 0, 0)
	_airship_station.set_meta("system_transport_type", "fictional_airship")
	_airship_station.set_meta("system_airship_capacity_min", AIRSHIP_MIN_CAPACITY)
	_airship_station.set_meta("system_airship_capacity_max", AIRSHIP_MAX_CAPACITY)
	add_child(_airship_station)
	var platform_material := _material(Color(0.30, 0.34, 0.39), 0.55, 0.32)
	var glow := _emissive_material(Color(0.18, 0.72, 1.0))
	_add_box(_airship_station, "AirshipBoardingPlatform", Vector3(0, 1, 0), Vector3(86, 2, 54), platform_material)
	_add_box(_airship_station, "AirshipMooringTower", Vector3(-38, 24, 0), Vector3(8, 48, 8), platform_material)
	_add_box(_airship_station, "AirshipPassengerBridge", Vector3(-12, 10, 0), Vector3(48, 1.8, 8), glow)
	_add_box(_airship_station, "AirshipStationSign", Vector3(0, 15, 28), Vector3(34, 3, 0.8), glow)
	for index in range(10):
		_add_box(_airship_station, "AirshipWaitingBench_%02d" % index, Vector3(-32.0 + float(index % 5) * 16.0, 2.2, -16.0 + float(int(index / 5)) * 28.0), Vector3(7, 1.0, 2.0), platform_material)
	_airship_station.set_meta("system_route_id", "baghdad_airship_loop")
	_airship_station.set_meta("system_boarding_flow", ["ticket_validation", "waiting_lounge", "boarding_bridge", "passenger_cabin", "arrival_platform"])
	_airship_station.set_meta("system_access_state", "fictional_game_transport_hub")


func _build_baghdad_airship() -> void:
	var path := Path3D.new()
	path.name = "BaghdadAirshipCircularRoute"
	var curve := Curve3D.new()
	for index in range(9):
		var angle := TAU * float(index) / 8.0
		curve.add_point(Vector3(cos(angle) * AIRSHIP_ROUTE_RADIUS_M, AIRSHIP_CRUISE_ALTITUDE_M, sin(angle) * AIRSHIP_ROUTE_RADIUS_M))
	path.curve = curve
	add_child(path)
	_airship_follow = PathFollow3D.new()
	_airship_follow.name = "HunterInspiredPassengerAirshipRouteFollower"
	_airship_follow.loop = true
	path.add_child(_airship_follow)
	var airship := Node3D.new()
	airship.name = "HunterInspiredBaghdadPassengerAirship"
	_airship_follow.add_child(airship)
	var balloon_material := _material(Color(0.78, 0.82, 0.88), 0.42, 0.16)
	var cabin_material := _material(Color(0.12, 0.18, 0.24), 0.28, 0.58)
	var window_material := _emissive_material(Color(0.18, 0.76, 1.0))
	var balloon := MeshInstance3D.new()
	balloon.name = "90mPassengerAirshipBalloon"
	var balloon_mesh := CapsuleMesh.new()
	balloon_mesh.radius = AIRSHIP_BALLOON_DIAMETER_M * 0.5
	balloon_mesh.height = AIRSHIP_LENGTH_M - AIRSHIP_BALLOON_DIAMETER_M
	balloon.mesh = balloon_mesh
	balloon.rotation.z = PI * 0.5
	balloon.position.y = 14
	balloon.material_override = balloon_material
	airship.add_child(balloon)
	_add_box(airship, "45mPassengerCabin", Vector3(0, -8, 0), Vector3(AIRSHIP_CABIN_LENGTH_M, 6, 10), cabin_material)
	_add_box(airship, "CabinWindowBandLeft", Vector3(0, -6.5, 5.15), Vector3(38, 1.5, 0.25), window_material)
	_add_box(airship, "CabinWindowBandRight", Vector3(0, -6.5, -5.15), Vector3(38, 1.5, 0.25), window_material)
	_add_box(airship, "AirshipLowerKeel", Vector3(0, -12, 0), Vector3(38, 1.0, 5), cabin_material)
	_add_box(airship, "AirshipTailFin", Vector3(-42, 12, 0), Vector3(9, 12, 2), cabin_material)
	_add_box(airship, "AirshipSideLEDAdvertising", Vector3(0, -9.5, 5.35), Vector3(24, 2.0, 0.35), _emissive_material(Color(0.95, 0.58, 0.12)))
	_add_box(airship, "AirshipSYSTEMWorldLogo", Vector3(0, 17, 0), Vector3(12, 1.0, 2.5), _emissive_material(Color(0.95, 0.78, 0.26)))
	for seat_index in range(12):
		var x := -18.0 + float(seat_index % 6) * 7.0
		var z := -2.6 if seat_index < 6 else 2.6
		_add_box(airship, "PassengerSeat_%02d" % seat_index, Vector3(x, -10.7, z), Vector3(2.4, 1.2, 2.0), cabin_material)
	airship.set_meta("system_airship_length_m", AIRSHIP_LENGTH_M)
	airship.set_meta("system_balloon_diameter_m", AIRSHIP_BALLOON_DIAMETER_M)
	airship.set_meta("system_passenger_cabin_length_m", AIRSHIP_CABIN_LENGTH_M)
	airship.set_meta("system_passenger_capacity_min", AIRSHIP_MIN_CAPACITY)
	airship.set_meta("system_passenger_capacity_max", AIRSHIP_MAX_CAPACITY)
	airship.set_meta("system_led_advertising", true)
	airship.set_meta("system_route_id", "baghdad_airship_loop")
	airship.set_meta("system_viewing_cabin", true)


func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive_material(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.28, 0.35)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	return material
