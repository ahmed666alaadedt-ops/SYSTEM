extends Area3D
class_name SystemNPCVehicle

## Civilian-owned vehicle with a lightweight road-loop driver.
## The simulation is intentionally local and lightweight until road navigation
## and server-authoritative traffic are implemented.

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
	route_points = [
		city_anchor + Vector3(-34.0, 0.0, -24.0),
		city_anchor + Vector3(34.0, 0.0, -24.0),
		city_anchor + Vector3(34.0, 0.0, 24.0),
		city_anchor + Vector3(-34.0, 0.0, 24.0)
	]
	route_index = p_slot % route_points.size()

func _process(delta: float) -> void:
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
