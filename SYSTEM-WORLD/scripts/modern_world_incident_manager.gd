extends Node3D
class_name ModernWorldIncidentManager

## Bounded procedural city incidents for the modern world.
signal incident_started(incident_id: String, city_name: String, incident_type: String)
signal incident_ended(incident_id: String, city_name: String)
signal emergency_unit_dispatched(incident_id: String, unit_type: String)

const MAX_ACTIVE_INCIDENTS := 3
const INCIDENT_TYPES := ["collision", "breakdown", "fire", "roadworks"]
const INCIDENT_LABELS := {
	"collision": "حادث مروري",
	"breakdown": "تعطل مركبة",
	"fire": "حريق في المدينة",
	"roadworks": "أعمال صيانة وإغلاق طريق"
}

var region_manager: Node
var terrain: Node
var traffic_manager: Node
var rng := RandomNumberGenerator.new()
var spawn_countdown := 24.0
var next_incident_number := 1
var active_incidents: Dictionary = {}
var city_incidents: Dictionary = {}
var response_units: Array[Dictionary] = []


func _ready() -> void:
	name = "ModernWorldIncidentManager"
	rng.randomize()
	region_manager = get_parent()
	if region_manager == null:
		return
	terrain = region_manager.get("terrain")
	traffic_manager = region_manager.get_node_or_null("ModernCityTrafficManager")
	spawn_countdown = rng.randf_range(18.0, 30.0)


func _process(delta: float) -> void:
	spawn_countdown -= delta
	if spawn_countdown <= 0.0:
		_try_spawn_incident()
		spawn_countdown = rng.randf_range(55.0, 95.0)
	_update_incidents(delta)
	_update_response_units(delta)


func _try_spawn_incident() -> void:
	if active_incidents.size() >= MAX_ACTIVE_INCIDENTS:
		return
	if region_manager == null or not region_manager.has_method("get_city_names"):
		return
	var candidates: Array = []
	for city_value in region_manager.call("get_city_names"):
		var city_name := str(city_value)
		if not city_incidents.has(city_name):
			candidates.append(city_name)
	if candidates.is_empty():
		return
	var city_name := str(candidates[rng.randi_range(0, candidates.size() - 1)])
	var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
	if anchor == Vector3.INF:
		return
	var point := anchor + Vector3(rng.randf_range(-34.0, 34.0), 0.0, rng.randf_range(-30.0, 30.0))
	if terrain != null and terrain.has_method("is_land_position") and not bool(terrain.call("is_land_position", point.x, point.z)):
		point = anchor + Vector3(18.0, 0.0, 12.0)
	var incident_type: String = str(INCIDENT_TYPES[rng.randi_range(0, INCIDENT_TYPES.size() - 1)])
	_create_incident(city_name, incident_type, point)


func _create_incident(city_name: String, incident_type: String, point: Vector3) -> void:
	var incident_id := "city_incident_%05d" % next_incident_number
	next_incident_number += 1
	var marker := Area3D.new()
	marker.name = incident_id
	marker.position = point
	marker.collision_layer = 1
	marker.collision_mask = 1
	marker.add_to_group("system_interactable")
	marker.add_to_group("system_city_incident")
	marker.set_meta("system_location_id", incident_id)
	marker.set_meta("system_region_id", "region_" + city_name.to_lower().replace(" ", "_"))
	marker.set_meta("system_display_name", str(INCIDENT_LABELS.get(incident_type, "حدث طارئ")) + " — " + city_name)
	marker.set_meta("system_location_type", 7)
	marker.set_meta("system_interaction_prompt", "فحص موقع " + str(INCIDENT_LABELS.get(incident_type, "الحدث")) + " وطلب المساعدة")
	var area_collision := CollisionShape3D.new()
	var area_shape := SphereShape3D.new()
	area_shape.radius = 7.0
	area_collision.shape = area_shape
	area_collision.position.y = 1.5
	marker.add_child(area_collision)
	add_child(marker)
	_build_incident_scene(marker, incident_type)
	var duration := rng.randf_range(70.0, 115.0)
	active_incidents[incident_id] = {"node": marker, "city": city_name, "type": incident_type, "remaining": duration}
	city_incidents[city_name] = incident_id
	if traffic_manager != null and traffic_manager.has_method("set_city_congestion"):
		traffic_manager.call("set_city_congestion", city_name, 0.38)
	_dispatch_response(incident_id, incident_type, point)
	incident_started.emit(incident_id, city_name, incident_type)
	print("SYSTEM CITY EVENT: ", INCIDENT_LABELS.get(incident_type, incident_type), " / ", city_name)


func _build_incident_scene(parent: Node3D, incident_type: String) -> void:
	if incident_type == "collision" or incident_type == "breakdown":
		var wreck := MeshInstance3D.new()
		wreck.name = "IncidentVehicle"
		var wreck_mesh := BoxMesh.new()
		wreck_mesh.size = Vector3(2.0, 0.8, 4.4)
		wreck.mesh = wreck_mesh
		wreck.position = Vector3(0.0, 0.75, 0.0)
		wreck.rotation.y = 0.38 if incident_type == "collision" else 0.0
		wreck.material_override = _material(Color(0.18, 0.22, 0.27), 0.42)
		parent.add_child(wreck)
		var cabin := MeshInstance3D.new()
		var cabin_mesh := BoxMesh.new()
		cabin_mesh.size = Vector3(1.55, 0.7, 1.9)
		cabin.mesh = cabin_mesh
		cabin.position = Vector3(0.0, 1.48, -0.12)
		cabin.material_override = _material(Color(0.035, 0.08, 0.12), 0.2)
		parent.add_child(cabin)
	if incident_type == "fire":
		var flame_material := _material(Color(1.0, 0.25, 0.035), 0.3, true)
		for index in range(3):
			var flame := MeshInstance3D.new()
			var flame_mesh := SphereMesh.new()
			flame_mesh.radius = 0.75 + float(index) * 0.18
			flame_mesh.height = 2.2 + float(index) * 0.5
			flame.mesh = flame_mesh
			flame.position = Vector3(float(index - 1) * 0.8, 1.5 + float(index) * 0.35, 0.0)
			flame.material_override = flame_material
			parent.add_child(flame)
	if incident_type == "roadworks":
		var barrier_material := _material(Color(0.95, 0.42, 0.06), 0.7)
		for index in range(3):
			var barrier := MeshInstance3D.new()
			var barrier_mesh := BoxMesh.new()
			barrier_mesh.size = Vector3(0.35, 1.2, 2.4)
			barrier.mesh = barrier_mesh
			barrier.position = Vector3(-3.0 + float(index) * 3.0, 0.6, 0.0)
			barrier.material_override = barrier_material
			parent.add_child(barrier)
	var beacon := MeshInstance3D.new()
	var beacon_mesh := SphereMesh.new()
	beacon_mesh.radius = 0.42
	beacon_mesh.height = 0.84
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0, 3.2, 0.0)
	beacon.material_override = _material(Color(1.0, 0.12, 0.06), 0.25, true)
	parent.add_child(beacon)


func _dispatch_response(incident_id: String, incident_type: String, target: Vector3) -> void:
	var unit_type := "Police"
	if incident_type == "collision" or incident_type == "breakdown":
		unit_type = "Ambulance"
	elif incident_type == "fire":
		unit_type = "FireRescue"
	elif incident_type == "roadworks":
		unit_type = "RoadService"
	var unit := Node3D.new()
	unit.name = "Emergency_" + incident_id
	unit.position = target + Vector3(-26.0, 0.0, 20.0)
	add_child(unit)
	var vehicle_body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.1, 1.0, 4.8)
	vehicle_body.mesh = body_mesh
	vehicle_body.position.y = 0.8
	vehicle_body.material_override = _material(Color(0.82, 0.84, 0.86) if unit_type == "Ambulance" else Color(0.08, 0.16, 0.25), 0.35)
	unit.add_child(vehicle_body)
	var light := MeshInstance3D.new()
	var light_mesh := BoxMesh.new()
	light_mesh.size = Vector3(1.0, 0.22, 0.38)
	light.mesh = light_mesh
	light.position.y = 1.48
	light.material_override = _material(Color(0.12, 0.35, 1.0), 0.25, true)
	unit.add_child(light)
	response_units.append({"node": unit, "target": target, "incident_id": incident_id, "unit_type": unit_type, "speed": 12.0})
	emergency_unit_dispatched.emit(incident_id, unit_type)


func _update_response_units(delta: float) -> void:
	for index in range(response_units.size() - 1, -1, -1):
		var unit_data: Dictionary = response_units[index]
		var vehicle := unit_data.get("node") as Node3D
		if not is_instance_valid(vehicle) or not active_incidents.has(str(unit_data.get("incident_id", ""))):
			if is_instance_valid(vehicle):
				vehicle.queue_free()
			response_units.remove_at(index)
			continue
		var target: Vector3 = unit_data.get("target", Vector3.ZERO)
		var direction := target - vehicle.position
		direction.y = 0.0
		if direction.length() > 3.0:
			vehicle.position += direction.normalized() * float(unit_data.get("speed", 12.0)) * delta
			vehicle.look_at(Vector3(target.x, vehicle.position.y, target.z), Vector3.UP)


func _update_incidents(delta: float) -> void:
	var expired: Array[String] = []
	for key in active_incidents.keys():
		var data: Dictionary = active_incidents[key]
		data["remaining"] = float(data.get("remaining", 0.0)) - delta
		active_incidents[key] = data
		if float(data["remaining"]) <= 0.0:
			expired.append(str(key))
	for incident_id in expired:
		_end_incident(incident_id)


func _end_incident(incident_id: String) -> void:
	if not active_incidents.has(incident_id):
		return
	var data: Dictionary = active_incidents[incident_id]
	var marker := data.get("node") as Node3D
	if is_instance_valid(marker):
		marker.queue_free()
	var city_name := str(data.get("city", ""))
	city_incidents.erase(city_name)
	active_incidents.erase(incident_id)
	if traffic_manager != null and traffic_manager.has_method("set_city_congestion"):
		traffic_manager.call("set_city_congestion", city_name, 1.0)
	incident_ended.emit(incident_id, city_name)


func _material(color: Color, roughness: float, emissive: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.8
	return material


func get_active_incidents() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for incident_id in active_incidents.keys():
		var data: Dictionary = active_incidents[incident_id]
		var node := data.get("node") as Node3D
		result.append({"id": str(incident_id), "city": str(data.get("city", "")), "type": str(data.get("type", "")), "position": node.position if is_instance_valid(node) else Vector3.ZERO, "remaining": float(data.get("remaining", 0.0))})
	return result
