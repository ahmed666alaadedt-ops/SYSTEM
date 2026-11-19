extends Node3D
class_name ModernCityTrafficManager

## حركة مرور مرئية إجرائية على محوري الطرق داخل المدن.
## هذه مركبات بيئية أولية؛ لا تمثل بعد نظام قيادة أو اصطدام أو ذكاء مرور.

const ROAD_LENGTH := 185.0
const LANE_OFFSET := 3.0
const TRAFFIC_FLEET := [
	{"name": "Sedan", "size": Vector3(1.9, 0.72, 4.1), "cabin": Vector3(1.52, 0.68, 1.9), "speed": 9.0},
	{"name": "Taxi", "size": Vector3(1.9, 0.72, 4.2), "cabin": Vector3(1.52, 0.68, 1.9), "speed": 8.0},
	{"name": "DeliveryVan", "size": Vector3(2.0, 1.05, 4.8), "cabin": Vector3(1.65, 0.72, 1.8), "speed": 7.2},
	{"name": "CityBus", "size": Vector3(2.45, 1.55, 8.0), "cabin": Vector3(2.2, 0.8, 3.2), "speed": 5.8},
	{"name": "Police", "size": Vector3(1.95, 0.78, 4.4), "cabin": Vector3(1.55, 0.72, 1.9), "speed": 9.5},
	{"name": "Ambulance", "size": Vector3(2.0, 1.25, 5.2), "cabin": Vector3(1.7, 0.75, 1.9), "speed": 7.0},
	{"name": "UtilityTruck", "size": Vector3(2.35, 1.35, 6.4), "cabin": Vector3(2.0, 0.82, 2.0), "speed": 6.2},
	{"name": "Sport", "size": Vector3(1.95, 0.62, 4.3), "cabin": Vector3(1.5, 0.56, 1.7), "speed": 11.0}
]

var region_manager: Node3D
var terrain: Node
var vehicles: Array[Dictionary] = []
var city_speed_factors: Dictionary = {}
var elapsed := 0.0
var city_check_clock := 0.0
var active_city_name := ""
var body_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var tire_material: StandardMaterial3D
var lamp_material: StandardMaterial3D


func _ready() -> void:
	name = "ModernCityTrafficManager"
	region_manager = get_parent() as Node3D
	if region_manager == null:
		return
	terrain = region_manager.get("terrain")
	_create_materials()
	active_city_name = _find_nearest_city_name(Vector3.ZERO)
	_build_city_traffic(active_city_name)


func _create_materials() -> void:
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.12, 0.34, 0.52)
	body_material.metallic = 0.62
	body_material.roughness = 0.28

	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.035, 0.075, 0.10)
	glass_material.metallic = 0.35
	glass_material.roughness = 0.16

	tire_material = StandardMaterial3D.new()
	tire_material.albedo_color = Color(0.018, 0.02, 0.023)
	tire_material.roughness = 0.96

	lamp_material = StandardMaterial3D.new()
	lamp_material.albedo_color = Color(1.0, 0.82, 0.48)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(1.0, 0.72, 0.32)
	lamp_material.emission_energy_multiplier = 1.8


func _build_city_traffic(city_name: String) -> void:
	if not region_manager.has_method("get_city_names") or not region_manager.has_method("get_city_anchor"):
		return
	var city_names: Array = region_manager.call("get_city_names")
	var city_index := city_names.find(city_name)
	if city_index < 0:
		return
	var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
	if anchor == Vector3.INF:
		return
	for fleet_index in range(TRAFFIC_FLEET.size()):
		var east_west := fleet_index % 2 == 1
		_create_vehicle(
			city_name + "_" + str(TRAFFIC_FLEET[fleet_index]["name"]) + "_%02d" % fleet_index,
			city_name,
			anchor,
			east_west,
			city_index * TRAFFIC_FLEET.size() + fleet_index,
			fleet_index
		)


func _find_nearest_city_name(position: Vector3) -> String:
	var city_names: Array = region_manager.call("get_city_names")
	var nearest_name := "Baghdad"
	var nearest_distance := INF
	for city_value in city_names:
		var city_name := str(city_value)
		var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
		if anchor == Vector3.INF:
			continue
		var distance := Vector2(position.x - anchor.x, position.z - anchor.z).length_squared()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_name = city_name
	return nearest_name


func _rebuild_city_traffic(city_name: String) -> void:
	for item in vehicles:
		var vehicle := item.get("node") as Node3D
		if is_instance_valid(vehicle):
			vehicle.queue_free()
	vehicles.clear()
	active_city_name = city_name
	_build_city_traffic(active_city_name)


func _create_vehicle(vehicle_name: String, city_name: String, anchor: Vector3, east_west: bool, seed_index: int, fleet_index: int) -> void:
	var definition: Dictionary = TRAFFIC_FLEET[fleet_index]
	var vehicle := Node3D.new()
	vehicle.name = vehicle_name
	add_child(vehicle)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = definition["size"]
	body.mesh = body_mesh
	body.position.y = 0.72
	body.material_override = body_material
	vehicle.add_child(body)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = definition["cabin"]
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.0, float(definition["size"].y) + float(definition["cabin"].y) * 0.5, -0.18)
	cabin.material_override = glass_material
	vehicle.add_child(cabin)

	for side in [-1.0, 1.0]:
		for axle in [-1.25, 1.25]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(side * 0.98, 0.38, axle)
			wheel.material_override = tire_material
			vehicle.add_child(wheel)

	for side in [-1.0, 1.0]:
		var headlamp := MeshInstance3D.new()
		var lamp_mesh := BoxMesh.new()
		lamp_mesh.size = Vector3(0.34, 0.16, 0.07)
		headlamp.mesh = lamp_mesh
		headlamp.position = Vector3(side * 0.58, 0.83, -2.08)
		headlamp.material_override = lamp_material
		vehicle.add_child(headlamp)

	vehicles.append({
		"node": vehicle,
		"city_name": city_name,
		"anchor": anchor,
		"east_west": east_west,
		"speed": float(definition["speed"]) + float(seed_index % 3) * 0.35,
		"lane": 2.8 + float((fleet_index / 2) % 2) * 2.1,
		"offset": float(seed_index) * 17.0 + (ROAD_LENGTH * 0.5 if east_west else 0.0)
	})


func _process(delta: float) -> void:
	elapsed += delta
	city_check_clock += delta
	if city_check_clock >= 4.0:
		city_check_clock = 0.0
		var player := region_manager.get_parent().get_node_or_null("Player") as Node3D
		var player_position := player.global_position if is_instance_valid(player) else Vector3.ZERO
		var nearest_city := _find_nearest_city_name(player_position)
		if nearest_city != active_city_name:
			_rebuild_city_traffic(nearest_city)
	for item in vehicles:
		var vehicle: Node3D = item["node"]
		if not is_instance_valid(vehicle):
			continue
		var anchor: Vector3 = item["anchor"]
		var city_factor := float(city_speed_factors.get(str(item.get("city_name", "")), 1.0))
		var distance := fposmod(elapsed * float(item["speed"]) * city_factor + float(item["offset"]), ROAD_LENGTH)
		var position := anchor
		if bool(item["east_west"]):
			position.x += distance
			position.z += float(item["lane"])
			vehicle.rotation.y = PI * 0.5
		else:
			position.z -= distance
			position.x -= float(item["lane"])
			vehicle.rotation.y = 0.0
		if terrain != null and terrain.has_method("is_land_position"):
			if not bool(terrain.call("is_land_position", position.x, position.z)):
				vehicle.visible = false
				continue
			vehicle.visible = true
		if terrain != null and terrain.has_method("get_terrain_height"):
			position.y = float(terrain.call("get_terrain_height", position.x, position.z)) + 0.05
		vehicle.position = position



func set_city_congestion(city_name: String, speed_factor: float) -> void:
	if city_name.is_empty():
		return
	city_speed_factors[city_name] = clampf(speed_factor, 0.15, 1.0)


func get_city_congestion(city_name: String) -> float:
	return float(city_speed_factors.get(city_name, 1.0))
