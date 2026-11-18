extends Node3D
class_name ModernCityCrimeResponseManager

## Local prototype: NPC-owned vehicles drive short city loops, can be stolen,
## generate witness reports and trigger police pursuit/recovery.
## Full road-lane navigation, arrest AI and multiplayer authority remain future work.

signal npc_vehicle_stolen(vehicle_id: String, owner_npc_id: String, city_name: String)
signal theft_reported(vehicle_id: String, city_name: String)
signal police_pursuit_started(vehicle_id: String, city_name: String)
signal stolen_vehicle_recovered(vehicle_id: String, city_name: String)

const NPCVehicleScript = preload("res://scripts/system_npc_vehicle.gd")
const SAVE_PATH := "user://system_city_crime_state.cfg"
const CITY_NAMES := [
	"New York", "London", "Paris", "Baghdad", "Moscow", "Cairo",
	"New Delhi", "Guangzhou", "Seoul", "Tokyo", "Singapore",
	"Sydney", "Rio de Janeiro", "Johannesburg"
]

var region_manager: Node
var vehicles: Dictionary = {}
var police_units: Array[Dictionary] = []
var next_vehicle_number := 1
var next_police_number := 1
var crime_records: Array[Dictionary] = []
var wanted_level := 0

func _ready() -> void:
	name = "ModernCityCrimeResponseManager"
	region_manager = get_parent().get_node_or_null("ModernWorldRegionManager")
	_spawn_civilian_vehicle_fleet()
	_load_crime_state()

func _spawn_civilian_vehicle_fleet() -> void:
	if region_manager == null or not region_manager.has_method("get_city_anchor"):
		push_warning("SYSTEM Crime: city region manager is unavailable.")
		return
	for city_name in CITY_NAMES:
		var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
		if anchor == Vector3.INF:
			continue
		for slot in range(3):
			var vehicle_id := "npc_car_%05d" % next_vehicle_number
			next_vehicle_number += 1
			var owner_id := "citizen_%s_%02d" % [city_name.to_lower().replace(" ", "_"), slot + 1]
			var owner_name := _citizen_name(city_name, slot)
			var vehicle := NPCVehicleScript.new()
			vehicle.configure(vehicle_id, owner_id, owner_name, city_name, self, anchor, slot)
			vehicle.position = anchor + Vector3(float(slot - 1) * 9.0, 0.05, 18.0 + float(slot) * 7.0)
			_build_vehicle_visual(vehicle, slot)
			add_child(vehicle)
			vehicles[vehicle_id] = {
				"node": vehicle,
				"owner_npc_id": owner_id,
				"owner_name": owner_name,
				"city_name": city_name,
				"stolen": false,
				"reported": false,
				"recovered": false,
				"witness_count": 1 + (slot % 3),
				"vehicle_class": ["sedan", "hatchback", "utility_suv"][slot]
			}

func _citizen_name(city_name: String, slot: int) -> String:
	var names := ["Mira", "Omar", "Daniel", "Yuki", "Lina", "Adam"]
	return names[(abs(city_name.hash()) + slot) % names.size()]

func _build_vehicle_visual(vehicle: Area3D, style: int) -> void:
	var body := MeshInstance3D.new()
	body.name = "VehicleBody"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.95, 0.78, 4.25)
	body.mesh = body_mesh
	body.position.y = 0.72
	var paint := StandardMaterial3D.new()
	var colors := [Color(0.16, 0.34, 0.58), Color(0.58, 0.20, 0.13), Color(0.22, 0.34, 0.25)]
	paint.albedo_color = colors[style % colors.size()]
	paint.metallic = 0.48
	paint.roughness = 0.3
	body.material_override = paint
	vehicle.add_child(body)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.55, 0.72, 1.95)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.0, 1.42, -0.15)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.035, 0.075, 0.10)
	glass.metallic = 0.3
	glass.roughness = 0.18
	cabin.material_override = glass
	vehicle.add_child(cabin)

	for side in [-1.0, 1.0]:
		for axle in [-1.35, 1.35]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(side * 1.0, 0.38, axle)
			wheel.material_override = _tire_material()
			vehicle.add_child(wheel)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 2.0, 4.8)
	collision.shape = shape
	collision.position.y = 1.0
	vehicle.add_child(collision)

func _tire_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.018, 0.02, 0.023)
	material.roughness = 0.96
	return material

func attempt_vehicle_theft(vehicle_id: String) -> Dictionary:
	if not vehicles.has(vehicle_id):
		return {"success": false, "reason": "VEHICLE_NOT_FOUND"}
	var record: Dictionary = vehicles[vehicle_id]
	if bool(record.get("stolen", false)):
		return {"success": false, "reason": "VEHICLE_ALREADY_STOLEN"}
	if bool(record.get("recovered", false)):
		return {"success": false, "reason": "VEHICLE_RECOVERED"}
	record["stolen"] = true
	vehicles[vehicle_id] = record
	var vehicle: Node = record.get("node")
	if is_instance_valid(vehicle) and vehicle.has_method("set_stolen_visual"):
		vehicle.call("set_stolen_visual")
	wanted_level = mini(5, wanted_level + 1)
	var event := {
		"type": "vehicle_theft",
		"vehicle_id": vehicle_id,
		"owner_npc_id": str(record["owner_npc_id"]),
		"owner_name": str(record["owner_name"]),
		"city_name": str(record["city_name"]),
		"witnesses": int(record["witness_count"]),
		"wanted_level": wanted_level,
		"time_unix": int(Time.get_unix_time_from_system())
	}
	crime_records.append(event)
	npc_vehicle_stolen.emit(vehicle_id, str(record["owner_npc_id"]), str(record["city_name"]))
	if int(record["witness_count"]) > 0:
		_report_theft(vehicle_id)
	_save_crime_state()
	return {"success": true, "vehicle_id": vehicle_id, "wanted_level": wanted_level, "reported": int(record["witness_count"]) > 0}

func _report_theft(vehicle_id: String) -> void:
	var record: Dictionary = vehicles[vehicle_id]
	if bool(record.get("reported", false)):
		return
	record["reported"] = true
	vehicles[vehicle_id] = record
	theft_reported.emit(vehicle_id, str(record["city_name"]))
	_dispatch_police(vehicle_id)

func _dispatch_police(vehicle_id: String) -> void:
	var record: Dictionary = vehicles[vehicle_id]
	var target := record.get("node") as Node3D
	if not is_instance_valid(target):
		return
	var police := Node3D.new()
	police.name = "PolicePursuit_%04d" % next_police_number
	next_police_number += 1
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 0.9, 4.4)
	body.mesh = mesh
	body.position.y = 0.72
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.035, 0.07, 0.13)
	material.metallic = 0.45
	body.material_override = material
	police.add_child(body)
	var beacon := MeshInstance3D.new()
	var beacon_mesh := BoxMesh.new()
	beacon_mesh.size = Vector3(0.9, 0.18, 0.3)
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0, 1.28, 0.0)
	var beacon_material := StandardMaterial3D.new()
	beacon_material.albedo_color = Color(0.1, 0.35, 1.0)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(0.08, 0.25, 1.0)
	beacon_material.emission_energy_multiplier = 2.0
	beacon.material_override = beacon_material
	police.add_child(beacon)
	add_child(police)
	police.global_position = target.global_position + Vector3(-12.0, 0.0, -16.0)
	police_units.append({"node": police, "target_id": vehicle_id, "speed": 14.5, "active": true})
	police_pursuit_started.emit(vehicle_id, str(record["city_name"]))

func _process(delta: float) -> void:
	for index in range(police_units.size() - 1, -1, -1):
		var unit: Dictionary = police_units[index]
		var police := unit.get("node") as Node3D
		var record: Dictionary = vehicles.get(str(unit.get("target_id", "")), {})
		var target := record.get("node") as Node3D
		if not is_instance_valid(police) or not is_instance_valid(target):
			if is_instance_valid(police):
				police.queue_free()
			police_units.remove_at(index)
			continue
		if bool(record.get("recovered", false)):
			police.queue_free()
			police_units.remove_at(index)
			continue
		var direction := target.global_position - police.global_position
		direction.y = 0.0
		if direction.length() > 3.2:
			police.global_position += direction.normalized() * float(unit["speed"]) * delta
			police.look_at(Vector3(target.global_position.x, police.global_position.y, target.global_position.z), Vector3.UP)
		else:
			_recover_stolen_vehicle(str(unit["target_id"]))
			police.queue_free()
			police_units.remove_at(index)

func _recover_stolen_vehicle(vehicle_id: String) -> void:
	var record: Dictionary = vehicles.get(vehicle_id, {})
	if record.is_empty():
		return
	record["recovered"] = true
	record["stolen"] = false
	vehicles[vehicle_id] = record
	var vehicle := record.get("node") as Node3D
	if is_instance_valid(vehicle):
		if vehicle.has_method("stop_for_recovery"):
			vehicle.call("stop_for_recovery")
		vehicle.visible = false
	stolen_vehicle_recovered.emit(vehicle_id, str(record["city_name"]))
	_save_crime_state()

func get_vehicle_record(vehicle_id: String) -> Dictionary:
	var record: Dictionary = vehicles.get(vehicle_id, {}).duplicate(true)
	record.erase("node")
	return record

func get_crime_status() -> Dictionary:
	return {
		"wanted_level": wanted_level,
		"active_pursuits": police_units.size(),
		"record_count": crime_records.size(),
		"vehicle_count": vehicles.size(),
		"moving_npc_vehicles": vehicles.size(),
		"save_mode": "local_prototype"
	}

func _save_crime_state() -> void:
	var config := ConfigFile.new()
	config.set_value("crime", "wanted_level", wanted_level)
	config.set_value("crime", "records", crime_records)
	config.save(SAVE_PATH)

func _load_crime_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	wanted_level = clampi(int(config.get_value("crime", "wanted_level", 0)), 0, 5)
	crime_records = config.get_value("crime", "records", [])
