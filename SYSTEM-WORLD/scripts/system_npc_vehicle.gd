extends Area3D
class_name SystemNPCVehicle

## Civilian-owned vehicle with a lightweight route-following driver.
## Baghdad uses streamed OSM motor-vehicle routes when available; other cities
## retain local prototype loops. Lane-level traffic rules, collision avoidance
## and server-authoritative traffic remain future work.

var vehicle_id := ""
var owner_npc_id := ""
var owner_name := ""
var city_name := ""
var crime_manager: Node
var city_anchor := Vector3.ZERO
var route_points: Array[Vector3] = []
var route_index := 0
var cruise_speed := 7.0
var stolen_speed := 12.5
var is_stolen := false
var is_driving := true
var stop_timer := 0.0
var vehicle_style := 0
var route_retry_clock := 0.0
var wheel_nodes: Array[MeshInstance3D] = []

func _ready() -> void:
	_collect_wheels(self)

func _collect_wheels(parent: Node) -> void:
	for child in parent.get_children():
		if child is MeshInstance3D and str(child.name).begins_with("NPCWheel"):
			wheel_nodes.append(child as MeshInstance3D)
		if child.get_child_count() > 0:
			_collect_wheels(child)

func configure(
	p_vehicle_id: String,
	p_owner_id: String,
	p_owner_name: String,
	p_city: String,
	p_manager: Node,
	p_city_anchor: Vector3,
	p_slot: int
) -> void:
	vehicle_id = p_vehicle_id
	owner_npc_id = p_owner_id
	owner_name = p_owner_name
	city_name = p_city
	crime_manager = p_manager
	city_anchor = p_city_anchor
	vehicle_style = p_slot
	cruise_speed = 6.8 + float(p_slot) * 0.65
	name = "NPCVehicle_" + vehicle_id
	add_to_group("system_interactable")
	set_meta("system_interaction_prompt", "سيارة المواطن %s — تفاعل لسرقتها" % owner_name)
	set_meta("system_vehicle_id", vehicle_id)
	route_points = _build_real_osm_vehicle_loop(p_slot)
	if route_points.size() >= 4:
		set_meta("system_road_route_source", "real_osm_vehicle_graph")
		set_meta("system_vehicle_route_points", route_points.size())
	else:
		route_points = [
			city_anchor + Vector3(-34.0, 0.0, -24.0),
			city_anchor + Vector3(34.0, 0.0, -24.0),
			city_anchor + Vector3(34.0, 0.0, 24.0),
			city_anchor + Vector3(-34.0, 0.0, 24.0)
		]
		set_meta("system_road_route_source", "procedural_fallback")
		set_meta("system_vehicle_route_points", route_points.size())
	route_index = p_slot % route_points.size()


func _try_upgrade_to_osm_vehicle_route() -> bool:
	var real_route := _build_real_osm_vehicle_loop(vehicle_style)
	if real_route.size() < 4:
		return false
	route_points = real_route
	route_index = 0
	global_position = route_points[0] - Vector3.UP * 0.19
	set_meta("system_road_route_source", "real_osm_vehicle_graph")
	set_meta("system_vehicle_route_points", route_points.size())
	return true


func _build_real_osm_vehicle_loop(slot: int) -> Array[Vector3]:
	if city_name != "Baghdad" or not is_instance_valid(crime_manager):
		return []
	var world_root := crime_manager.get_parent()
	if world_root == null:
		return []
	var streamer := world_root.get_node_or_null("BaghdadOSMCellStreamer")
	if streamer == null or not streamer.has_method("get_vehicle_navigation_path"):
		return []
	var candidates := [
		{"start": Vector3(-72.0, 0.0, -48.0), "target": Vector3(72.0, 0.0, 48.0)},
		{"start": Vector3(-82.0, 0.0, 52.0), "target": Vector3(82.0, 0.0, -52.0)},
		{"start": Vector3(-105.0, 0.0, 4.0), "target": Vector3(105.0, 0.0, -4.0)}
	]
	var candidate: Dictionary = candidates[slot % candidates.size()]
	var start: Vector3 = city_anchor + candidate["start"]
	var target: Vector3 = city_anchor + candidate["target"]
	var outbound_value: Variant = streamer.call("get_vehicle_navigation_path", start, target, 75.0)
	var inbound_value: Variant = streamer.call("get_vehicle_navigation_path", target, start, 75.0)
	if not outbound_value is Array or not inbound_value is Array:
		return []
	var outbound: Array = outbound_value
	var inbound: Array = inbound_value
	if outbound.size() < 2 or inbound.size() < 2:
		return []
	var loop: Array[Vector3] = []
	for point in outbound:
		if point is Vector3:
			loop.append(point)
	for index in range(1, inbound.size()):
		if inbound[index] is Vector3:
			loop.append(inbound[index])
	return loop if loop.size() >= 4 else []

func _process(delta: float) -> void:
	if city_name == "Baghdad" and str(get_meta("system_road_route_source", "")) != "real_osm_vehicle_graph":
		route_retry_clock += delta
		if route_retry_clock >= 2.0:
			route_retry_clock = 0.0
			_try_upgrade_to_osm_vehicle_route()
	if not is_driving or route_points.is_empty():
		return
	if stop_timer > 0.0 and not is_stolen:
		stop_timer = maxf(0.0, stop_timer - delta)
		return
	var target := route_points[route_index]
	var terrain := _get_terrain()
	if terrain != null and terrain.has_method("is_land_position"):
		if not bool(terrain.call("is_land_position", target.x, target.z)):
			route_index = (route_index + 1) % route_points.size()
			return
	if terrain != null and terrain.has_method("get_terrain_height"):
		target.y = float(terrain.call("get_terrain_height", target.x, target.z)) + 0.05
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() <= 2.2:
		route_index = (route_index + 1) % route_points.size()
		if not is_stolen:
			stop_timer = 0.7 + float(vehicle_style % 3) * 0.45
		return
	var speed := stolen_speed if is_stolen else cruise_speed
	global_position += direction.normalized() * speed * delta
	look_at(Vector3(target.x, global_position.y, target.z), Vector3.UP)
	for wheel in wheel_nodes:
		if is_instance_valid(wheel):
			wheel.rotation.x += speed * delta / 0.34

func _get_terrain() -> Node:
	if not is_instance_valid(crime_manager):
		return null
	var region: Node = crime_manager.get("region_manager")
	if region == null:
		return null
	return region.get("terrain")

func system_interact() -> void:
	if is_instance_valid(crime_manager):
		crime_manager.call("attempt_vehicle_theft", vehicle_id)

func set_stolen_visual() -> void:
	is_stolen = true
	stop_timer = 0.0
	set_meta("system_interaction_prompt", "مركبة مسروقة — الشرطة قد تلاحقك")
	var driver := get_node_or_null("CivilianDriverVisual") as Node3D
	if driver != null:
		driver.visible = false
	var body := get_node_or_null("VehicleBody") as MeshInstance3D
	if body != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.08, 0.07)
		material.metallic = 0.45
		body.material_override = material

func stop_for_recovery() -> void:
	is_driving = false
	is_stolen = false
	set_meta("system_interaction_prompt", "مركبة مسترجعة لصاحبها")
