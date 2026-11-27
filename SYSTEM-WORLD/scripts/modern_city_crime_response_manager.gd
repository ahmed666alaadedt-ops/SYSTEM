extends Node3D
class_name ModernCityCrimeResponseManager

## Local prototype: NPC-owned vehicles drive short city loops, can be stolen,
## generate witness reports and trigger police pursuit/recovery.
## Full road-lane navigation, arrest AI and multiplayer authority remain future work.

signal npc_vehicle_stolen(vehicle_id: String, owner_npc_id: String, city_name: String)
signal theft_reported(vehicle_id: String, city_name: String)
signal police_pursuit_started(vehicle_id: String, city_name: String)
signal stolen_vehicle_recovered(vehicle_id: String, city_name: String)
signal crime_case_opened(case_id: String, crime_type: String, city_name: String)
signal crime_case_updated(case_id: String, status: String)
signal civilian_protection_requested(npc_id: String, reason: String)
signal illegal_street_race_reported(race_id: String, city_name: String)
signal illegal_street_race_pursuit_started(race_id: String, city_name: String)
signal illegal_street_race_stopped(race_id: String, city_name: String)

const NPCVehicleScript = preload("res://scripts/system_npc_vehicle.gd")
const SAVE_PATH := "user://system_city_crime_state.cfg"
const CIVILIAN_CRIME_TYPES := [
	"theft", "robbery", "assault", "murder", "sexual_assault",
	"harassment", "stalking", "kidnapping", "human_trafficking",
	"exploitation", "fraud", "vandalism", "arson", "corruption",
	"domestic_abuse", "child_abuse"
]
const PROTECTION_CRIMES := [
	"sexual_assault", "human_trafficking", "exploitation",
	"domestic_abuse", "child_abuse", "kidnapping"
]
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
var next_case_number := 1
var next_illegal_race_number := 1
var crime_records: Array[Dictionary] = []
var wanted_level := 0

var society_manager: Node
var owner_registry: Dictionary = {}
var active_city_name := ""
var city_check_clock := 0.0

func setup(p_society_manager: Node) -> void:
	society_manager = p_society_manager

func _ready() -> void:
	name = "ModernCityCrimeResponseManager"
	region_manager = get_parent().get_node_or_null("ModernWorldRegionManager")
	_load_crime_state()
	_spawn_civilian_vehicle_fleet()

func _spawn_civilian_vehicle_fleet() -> void:
	if region_manager == null or not region_manager.has_method("get_city_anchor"):
		push_warning("SYSTEM Crime: city region manager is unavailable.")
		return
	active_city_name = _find_nearest_city_name(Vector3.ZERO)
	_spawn_city_vehicle_fleet(active_city_name)


func _find_nearest_city_name(position: Vector3) -> String:
	if not is_instance_valid(region_manager):
		return "Baghdad"
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


func _find_city_vehicle_id(city_name: String, slot: int) -> String:
	for vehicle_id in vehicles:
		var record: Dictionary = vehicles[vehicle_id]
		if str(record.get("city_name", "")) == city_name and int(record.get("slot", -1)) == slot:
			return str(vehicle_id)
	return ""


func _spawn_city_vehicle_fleet(city_name: String) -> void:
	var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
	if anchor == Vector3.INF:
		return
	var city_names: Array = region_manager.call("get_city_names")
	var city_index := city_names.find(city_name)
	if city_index < 0:
		city_index = 0
	for slot in range(3):
		var existing_id := _find_city_vehicle_id(city_name, slot)
		if not existing_id.is_empty():
			var existing: Dictionary = vehicles[existing_id]
			if not is_instance_valid(existing.get("node")):
				_attach_vehicle_visual(existing_id, existing)
			continue
		var vehicle_id := "npc_car_%05d" % next_vehicle_number
		next_vehicle_number += 1
		var owner_key: String = city_name.to_lower().replace(" ", "_") + "_" + str(slot + 1)
		var owner_name := _citizen_name(city_name, slot)
		var owner_id := _get_or_create_owner_npc(owner_key, owner_name, city_name)
		var record := {
			"node": null,
			"owner_npc_id": owner_id,
			"owner_name": owner_name,
			"city_name": city_name,
			"anchor": anchor,
			"slot": slot,
			"stolen": false,
			"reported": false,
			"recovered": false,
			"witness_count": 1 + (slot % 3),
			"vehicle_class": ["sedan", "hatchback", "utility_suv"][slot]
		}
		vehicles[vehicle_id] = record
		if society_manager != null and society_manager.has_method("assign_vehicle_to_npc"):
			society_manager.call("assign_vehicle_to_npc", owner_id, vehicle_id)
		_attach_vehicle_visual(vehicle_id, record)
	if society_manager != null and society_manager.has_method("save_society"):
		society_manager.call("save_society")
	_save_crime_state()


func _attach_vehicle_visual(vehicle_id: String, record: Dictionary) -> void:
	var anchor: Vector3 = record.get("anchor", Vector3.ZERO)
	var slot := int(record.get("slot", 0))
	var vehicle := NPCVehicleScript.new()
	vehicle.configure(
		vehicle_id,
		str(record.get("owner_npc_id", "")),
		str(record.get("owner_name", "Citizen")),
		str(record.get("city_name", active_city_name)),
		self,
		anchor,
		slot
	)
	vehicle.position = anchor + Vector3(float(slot - 1) * 9.0, 0.05, 18.0 + float(slot) * 7.0)
	_build_vehicle_visual(vehicle, slot)
	add_child(vehicle)
	if str(vehicle.get_meta("system_road_route_source", "")) == "real_osm_vehicle_graph" and vehicle.route_points.size() >= 2:
		var route_spawn: Vector3 = vehicle.route_points[vehicle.route_index]
		vehicle.global_position = route_spawn - Vector3.UP * 0.19
	record["node"] = vehicle
	vehicles[vehicle_id] = record


func _stream_city_vehicle_fleet(city_name: String) -> void:
	active_city_name = city_name
	for vehicle_id in vehicles.keys():
		var record: Dictionary = vehicles[vehicle_id]
		var record_city := str(record.get("city_name", ""))
		var keep_active := record_city == active_city_name or bool(record.get("stolen", false)) or bool(record.get("reported", false))
		if not keep_active:
			var old_vehicle := record.get("node") as Node3D
			if is_instance_valid(old_vehicle):
				old_vehicle.queue_free()
			record["node"] = null
			vehicles[vehicle_id] = record
	_spawn_city_vehicle_fleet(active_city_name)


func _get_or_create_owner_npc(owner_key: String, owner_name: String, city_name: String) -> String:
	var saved_id := str(owner_registry.get(owner_key, ""))
	if society_manager != null and society_manager.has_method("get_npc") and not saved_id.is_empty():
		if not society_manager.call("get_npc", saved_id).is_empty():
			return saved_id
	if society_manager != null and society_manager.has_method("create_npc"):
		var created_id := str(society_manager.call(
			"create_npc", owner_name, 2, 28.0 + float(owner_registry.size() % 24),
			"balanced", "driver"
		))
		if not created_id.is_empty():
			owner_registry[owner_key] = created_id
			if society_manager.has_method("set_activity"):
				society_manager.call("set_activity", created_id, "travel", city_name)
			return created_id
	return "citizen_" + owner_key

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
	glass.albedo_color = Color(0.035, 0.075, 0.10, 0.42)
	glass.metallic = 0.3
	glass.roughness = 0.18
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin.material_override = glass
	vehicle.add_child(cabin)

	var driver := Node3D.new()
	driver.name = "CivilianDriverVisual"
	vehicle.add_child(driver)
	var clothing := StandardMaterial3D.new()
	var clothing_colors := [Color(0.16, 0.24, 0.34), Color(0.35, 0.18, 0.12), Color(0.18, 0.3, 0.2)]
	clothing.albedo_color = clothing_colors[style % clothing_colors.size()]
	var torso := MeshInstance3D.new()
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.55, 0.72, 0.34)
	torso.mesh = torso_mesh
	torso.position = Vector3(0.0, 1.28, -0.3)
	torso.material_override = clothing
	driver.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.78, -0.3)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.62, 0.43, 0.31)
	head.material_override = skin
	driver.add_child(head)

	for side in [-1.0, 1.0]:
		for axle in [-1.35, 1.35]:
			var wheel := MeshInstance3D.new()
			wheel.name = "NPCWheel"
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
	if society_manager != null and society_manager.has_method("set_activity"):
		society_manager.call("set_activity", str(record["owner_npc_id"]), "gather_information", str(record["city_name"]))
	if society_manager != null and society_manager.has_method("add_memory"):
		society_manager.call("add_memory", str(record["owner_npc_id"]), "vehicle_stolen", {"vehicle_id": vehicle_id, "city": str(record["city_name"])})
	if int(record["witness_count"]) > 0:
		_report_theft(vehicle_id)
	_save_crime_state()
	return {"success": true, "vehicle_id": vehicle_id, "wanted_level": wanted_level, "reported": int(record["witness_count"]) > 0}

func report_illegal_street_race(target_vehicle: Node3D, city_name: String) -> Dictionary:
	## Called by the street-race activity when witnesses report an unsanctioned race.
	## The target must be a road-legal street vehicle; purpose-built race cars are track-only.
	if not is_instance_valid(target_vehicle):
		return {"success": false, "reason": "INVALID_RACE_VEHICLE"}
	if bool(target_vehicle.get_meta("system_illegal_race_reported", false)):
		return {"success": false, "reason": "RACE_ALREADY_REPORTED"}
	target_vehicle.set_meta("system_illegal_race_reported", true)
	var race_id := "illegal_street_race_%05d" % next_illegal_race_number
	next_illegal_race_number += 1
	var record := {
		"node": target_vehicle,
		"owner_npc_id": "player_or_civilian",
		"owner_name": "Street racer",
		"city_name": city_name,
		"anchor": target_vehicle.global_position,
		"slot": -1,
		"stolen": false,
		"reported": true,
		"recovered": false,
		"illegal_race": true,
		"witness_count": 1
	}
	vehicles[race_id] = record
	wanted_level = mini(5, wanted_level + 1)
	crime_records.append({
		"type": "illegal_street_racing",
		"vehicle_id": race_id,
		"city_name": city_name,
		"wanted_level": wanted_level,
		"time_unix": int(Time.get_unix_time_from_system())
	})
	illegal_street_race_reported.emit(race_id, city_name)
	_dispatch_police(race_id)
	illegal_street_race_pursuit_started.emit(race_id, city_name)
	_save_crime_state()
	return {"success": true, "race_id": race_id, "wanted_level": wanted_level, "police_dispatched": true}


func _stop_illegal_street_race(race_id: String) -> void:
	var record: Dictionary = vehicles.get(race_id, {})
	if record.is_empty():
		return
	var target := record.get("node") as Node3D
	if is_instance_valid(target):
		if target.has_method("set_mobile_controls"):
			target.call("set_mobile_controls", 0.0, 0.0, 1.0)
		if target.has_method("set_driver_active"):
			target.call("set_driver_active", false)
	record["recovered"] = true
	vehicles[race_id] = record
	illegal_street_race_stopped.emit(race_id, str(record.get("city_name", "")))
	crime_case_opened.emit(race_id, "illegal_street_racing", str(record.get("city_name", "")))
	_save_crime_state()


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
	city_check_clock += delta
	if city_check_clock >= 4.0:
		city_check_clock = 0.0
		var player := get_parent().get_node_or_null("Player") as Node3D
		var player_position := player.global_position if is_instance_valid(player) else Vector3.ZERO
		var nearest_city := _find_nearest_city_name(player_position)
		if nearest_city != active_city_name:
			_stream_city_vehicle_fleet(nearest_city)
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
			var target_id := str(unit["target_id"])
			if bool(record.get("illegal_race", false)):
				_stop_illegal_street_race(target_id)
			else:
				_recover_stolen_vehicle(target_id)
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
	if society_manager != null and society_manager.has_method("set_activity"):
		society_manager.call("set_activity", str(record["owner_npc_id"]), "work", str(record["city_name"]))
	if society_manager != null and society_manager.has_method("add_memory"):
		society_manager.call("add_memory", str(record["owner_npc_id"]), "vehicle_recovered", {"vehicle_id": vehicle_id, "city": str(record["city_name"])})
	stolen_vehicle_recovered.emit(vehicle_id, str(record["city_name"]))
	_save_crime_state()

func get_vehicle_record(vehicle_id: String) -> Dictionary:
	var record: Dictionary = vehicles.get(vehicle_id, {}).duplicate(true)
	record.erase("node")
	return record

func get_crime_status() -> Dictionary:
	var active_vehicle_count := 0
	for record in vehicles.values():
		if is_instance_valid(record.get("node")):
			active_vehicle_count += 1
	return {
		"wanted_level": wanted_level,
		"active_pursuits": police_units.size(),
		"record_count": crime_records.size(),
		"vehicle_count": vehicles.size(),
		"moving_npc_vehicles": active_vehicle_count,
		"active_city": active_city_name,
		"save_mode": "local_prototype"
	}

func _save_crime_state() -> void:
	var config := ConfigFile.new()
	config.set_value("crime", "wanted_level", wanted_level)
	config.set_value("crime", "records", crime_records)
	config.set_value("crime", "next_case_number", next_case_number)
	config.set_value("crime", "owner_registry", owner_registry)
	config.save(SAVE_PATH)

func _load_crime_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	wanted_level = clampi(int(config.get_value("crime", "wanted_level", 0)), 0, 5)
	crime_records = config.get_value("crime", "records", [])
	next_case_number = maxi(1, int(config.get_value("crime", "next_case_number", crime_records.size() + 1)))
	owner_registry = config.get_value("crime", "owner_registry", {})



# --------------------------------------------------
# CIVILIAN CRIME, JUSTICE AND PROTECTION
# --------------------------------------------------

## Creates a non-graphic crime record. Serious incidents are represented
## through evidence, witness reports, investigation, support and legal outcomes.
func report_civilian_crime(
	crime_type: String,
	city_name: String,
	location_id: String,
	suspect_npc_id: String = "",
	victim_npc_id: String = "",
	witness_count: int = 0,
	evidence_tags: Array[String] = []
) -> Dictionary:
	if not CIVILIAN_CRIME_TYPES.has(crime_type):
		return {"success": false, "reason": "UNKNOWN_CRIME_TYPE"}
	if city_name.strip_edges().is_empty() or location_id.strip_edges().is_empty():
		return {"success": false, "reason": "LOCATION_REQUIRED"}
	if society_manager == null:
		return {"success": false, "reason": "SOCIETY_MANAGER_UNAVAILABLE"}
	if not suspect_npc_id.is_empty() and society_manager.call("get_npc", suspect_npc_id).is_empty():
		return {"success": false, "reason": "SUSPECT_NOT_FOUND"}
	if not victim_npc_id.is_empty() and society_manager.call("get_npc", victim_npc_id).is_empty():
		return {"success": false, "reason": "VICTIM_NOT_FOUND"}

	var case_id := "case_%06d" % next_case_number
	next_case_number += 1
	var severity := _crime_severity(crime_type)
	var case_record := {
		"case_id": case_id,
		"type": crime_type,
		"city_name": city_name,
		"location_id": location_id,
		"suspect_npc_id": suspect_npc_id,
		"victim_npc_id": victim_npc_id,
		"witness_count": maxi(0, witness_count),
		"evidence_tags": evidence_tags.duplicate(),
		"evidence_score": minf(0.85, float(evidence_tags.size()) * 0.12 + float(maxi(0, witness_count)) * 0.08),
		"severity": severity,
		"status": "reported",
		"investigation_stage": "awaiting_dispatch",
		"reported_at_unix": int(Time.get_unix_time_from_system()),
		"victim_support_offered": false,
		"court_verdict": "pending",
		"sentence_days": 0
	}
	crime_records.append(case_record)

	if not victim_npc_id.is_empty():
		_apply_victim_protection(victim_npc_id, crime_type, case_id)
	if crime_type == "murder" and not victim_npc_id.is_empty():
		if society_manager.has_method("record_npc_death"):
			society_manager.call("record_npc_death", victim_npc_id, "murder")
	if not suspect_npc_id.is_empty():
		var wanted_increase := 2 if severity >= 4 else 1
		wanted_level = mini(5, wanted_level + wanted_increase)

	_save_crime_state()
	crime_case_opened.emit(case_id, crime_type, city_name)
	return {"success": true, "case_id": case_id, "severity": severity, "status": "reported"}


func _crime_severity(crime_type: String) -> int:
	match crime_type:
		"murder", "sexual_assault", "human_trafficking", "kidnapping", "child_abuse":
			return 5
		"robbery", "assault", "arson", "domestic_abuse", "exploitation":
			return 4
		"stalking", "harassment", "fraud", "corruption":
			return 3
		"theft", "vandalism":
			return 2
		_:
			return 1


func _apply_victim_protection(victim_npc_id: String, crime_type: String, case_id: String) -> void:
	var victim: Dictionary = society_manager.call("get_npc", victim_npc_id)
	if victim.is_empty():
		return
	victim["safety_status"] = "protected_pending_investigation" if PROTECTION_CRIMES.has(crime_type) else "support_available"
	victim["active_crime_case_id"] = case_id
	var needs: Dictionary = victim.get("needs", {})
	needs["wellbeing"] = maxf(0.0, float(needs.get("wellbeing", 80.0)) - 22.0)
	victim["needs"] = needs
	society_manager.npcs[victim_npc_id] = victim
	if society_manager.has_method("add_memory"):
		society_manager.call("add_memory", victim_npc_id, "crime_victim_support_recorded", {
			"case_id": case_id,
			"crime_type": crime_type,
			"details_visibility": "private"
		})
	if PROTECTION_CRIMES.has(crime_type):
		civilian_protection_requested.emit(victim_npc_id, crime_type)


func record_investigation_step(case_id: String, step: String, evidence_points: float = 0.0) -> Dictionary:
	var index := _find_crime_case_index(case_id)
	if index < 0:
		return {"success": false, "reason": "CASE_NOT_FOUND"}
	var record: Dictionary = crime_records[index]
	var allowed_steps := ["police_arrived", "witness_interviewed", "evidence_collected", "suspect_identified", "victim_support_contacted", "case_sent_to_court"]
	if not allowed_steps.has(step):
		return {"success": false, "reason": "INVALID_INVESTIGATION_STEP"}
	record["investigation_stage"] = step
	record["evidence_score"] = clampf(float(record.get("evidence_score", 0.0)) + maxf(0.0, evidence_points), 0.0, 1.0)
	if step == "victim_support_contacted":
		record["victim_support_offered"] = true
	if step == "case_sent_to_court":
		record["status"] = "awaiting_trial"
	crime_records[index] = record
	_save_crime_state()
	crime_case_updated.emit(case_id, str(record["status"]))
	return {"success": true, "evidence_score": record["evidence_score"], "status": record["status"]}


func resolve_crime_case(case_id: String, verdict: String, sentence_days: int = 0) -> Dictionary:
	var index := _find_crime_case_index(case_id)
	if index < 0:
		return {"success": false, "reason": "CASE_NOT_FOUND"}
	if verdict != "guilty" and verdict != "not_guilty" and verdict != "insufficient_evidence":
		return {"success": false, "reason": "INVALID_VERDICT"}
	var record: Dictionary = crime_records[index]
	if str(record.get("status", "")) != "awaiting_trial":
		return {"success": false, "reason": "CASE_NOT_READY_FOR_TRIAL"}
	if verdict == "guilty" and float(record.get("evidence_score", 0.0)) < 0.35:
		return {"success": false, "reason": "INSUFFICIENT_EVIDENCE"}
	record["court_verdict"] = verdict
	record["status"] = "closed"
	if verdict == "guilty":
		record["sentence_days"] = clampi(sentence_days, 1, 3650)
		var suspect_id := str(record.get("suspect_npc_id", ""))
		if not suspect_id.is_empty():
			var suspect: Dictionary = society_manager.call("get_npc", suspect_id)
			if not suspect.is_empty():
				suspect["jailed"] = true
				suspect["jail_days_remaining"] = int(record["sentence_days"])
				suspect["reputation"] = float(suspect.get("reputation", 0.0)) - 30.0
				suspect["current_location"] = "baghdad_central_detention"
				suspect["current_action"] = "serving_sentence"
				society_manager.npcs[suspect_id] = suspect
				if society_manager.has_method("add_memory"):
					society_manager.call("add_memory", suspect_id, "convicted_and_imprisoned", {"case_id": case_id, "sentence_days": record["sentence_days"]})
	crime_records[index] = record
	_save_crime_state()
	crime_case_updated.emit(case_id, "closed")
	return {"success": true, "verdict": verdict, "sentence_days": int(record.get("sentence_days", 0))}


func _find_crime_case_index(case_id: String) -> int:
	for index in range(crime_records.size()):
		if str(crime_records[index].get("case_id", "")) == case_id:
			return index
	return -1


func get_crime_case(case_id: String) -> Dictionary:
	var index := _find_crime_case_index(case_id)
	if index < 0:
		return {}
	return crime_records[index].duplicate(true)


## Only consenting adults can be registered as independent adult workers.
## Coercion, trafficking, and anyone under 18 are rejected and routed to protection.
func register_adult_sex_work(npc_id: String, voluntary: bool, coercion_suspected: bool = false) -> Dictionary:
	if society_manager == null:
		return {"success": false, "reason": "SOCIETY_MANAGER_UNAVAILABLE"}
	var npc: Dictionary = society_manager.call("get_npc", npc_id)
	if npc.is_empty():
		return {"success": false, "reason": "NPC_NOT_FOUND"}
	if float(npc.get("age_years", 0.0)) < 18.0:
		report_civilian_crime("human_trafficking", str(npc.get("city_id", "unknown")), str(npc.get("current_location", "unknown")), "", npc_id, 0, ["underage_exploitation_risk"])
		return {"success": false, "reason": "MINOR_PROTECTION_REQUIRED"}
	if not voluntary or coercion_suspected:
		report_civilian_crime("human_trafficking", str(npc.get("city_id", "unknown")), str(npc.get("current_location", "unknown")), "", npc_id, 0, ["coercion_or_exploitation_report"])
		return {"success": false, "reason": "COERCION_OR_EXPLOITATION_REQUIRES_PROTECTION"}
	npc["occupation"] = "adult_independent_sex_worker"
	npc["adult_work_status"] = "self_declared_voluntary"
	npc["workplace_category"] = "adult_service_establishment"
	npc["consent_policy"] = "revocable_at_any_time"
	society_manager.npcs[npc_id] = npc
	if society_manager.has_method("add_memory"):
		society_manager.call("add_memory", npc_id, "adult_occupation_registered", {"category": "private_adult_work"})
	return {"success": true, "occupation": "adult_independent_sex_worker", "explicit_content": false}


func get_public_safety_snapshot(city_name: String) -> Dictionary:
	var open_cases := 0
	var serious_cases := 0
	for record in crime_records:
		if str(record.get("city_name", "")) != city_name:
			continue
		if str(record.get("status", "")) != "closed":
			open_cases += 1
			if int(record.get("severity", 0)) >= 4:
				serious_cases += 1
	return {
		"city_name": city_name,
		"open_cases": open_cases,
		"serious_open_cases": serious_cases,
		"wanted_level": wanted_level,
		"police_units_active": police_units.size()
	}
