extends Node3D
class_name ModernCityTrafficManager

## حركة مرور مرئية إجرائية على محوري الطرق داخل المدن.
## هذه مركبات بيئية أولية؛ لا تمثل بعد نظام قيادة أو اصطدام أو ذكاء مرور.

const ROAD_LENGTH := 185.0
const LANE_OFFSET := 3.1

var region_manager: Node3D
var terrain: Node
var vehicles: Array[Dictionary] = []
var elapsed := 0.0
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
	_build_city_traffic()


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


func _build_city_traffic() -> void:
	if not region_manager.has_method("get_city_names") or not region_manager.has_method("get_city_anchor"):
		return
	var city_names: Array = region_manager.call("get_city_names")
	for city_index in range(city_names.size()):
		var city_name := str(city_names[city_index])
		var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
		if anchor == Vector3.INF:
			continue
		_create_vehicle(city_name + "_NorthSouthTraffic", anchor, false, city_index)
		_create_vehicle(city_name + "_EastWestTraffic", anchor, true, city_index)


func _create_vehicle(vehicle_name: String, anchor: Vector3, east_west: bool, seed_index: int) -> void:
	var vehicle := Node3D.new()
	vehicle.name = vehicle_name
	add_child(vehicle)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.9, 0.72, 4.1)
	body.mesh = body_mesh
	body.position.y = 0.72
	body.material_override = body_material
	vehicle.add_child(body)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.52, 0.68, 1.9)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.0, 1.38, -0.18)
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
		"anchor": anchor,
		"east_west": east_west,
		"speed": 8.5 + float(seed_index % 5) * 1.4,
		"offset": float(seed_index) * 13.0 + (ROAD_LENGTH * 0.5 if east_west else 0.0)
	})


func _process(delta: float) -> void:
	elapsed += delta
	for item in vehicles:
		var vehicle: Node3D = item["node"]
		if not is_instance_valid(vehicle):
			continue
		var anchor: Vector3 = item["anchor"]
		var distance := fposmod(elapsed * float(item["speed"]) + float(item["offset"]), ROAD_LENGTH)
		var position := anchor
		if bool(item["east_west"]):
			position.x += distance
			position.z += LANE_OFFSET
			vehicle.rotation.y = PI * 0.5
		else:
			position.z -= distance
			position.x -= LANE_OFFSET
			vehicle.rotation.y = 0.0
		if terrain != null and terrain.has_method("get_terrain_height"):
			position.y = float(terrain.call("get_terrain_height", position.x, position.z)) + 0.05
		vehicle.position = position
