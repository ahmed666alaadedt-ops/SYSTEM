extends Node3D
class_name SystemNPCVisiblePopulationManager

## Visible pedestrian layer for the modern world.
## Uses lightweight procedural characters and bounded updates; destinations are
## approximate city-block anchors until real street/navigation data is connected.

const WORLD_ID := 2
const MAX_VISIBLE_CIVILIANS := 32
const WALK_SPEED := 1.45
const ARRIVAL_DISTANCE := 0.65
const RESIDENT_REFRESH_SECONDS := 3.0
const SERVICE_SPEED := 8.0

var society: Node
var daily_life: Node
var crime_manager: Node
var region_manager: Node
var navigation_manager: Node
var pedestrians: Dictionary = {}
var service_units: Array[Dictionary] = []
var refresh_clock := 0.0
var animation_clock := 0.0
var next_service_id := 1
var skin_materials: Array[StandardMaterial3D] = []
var clothing_materials: Array[StandardMaterial3D] = []
var police_material: StandardMaterial3D
var ambulance_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var siren_red_material: StandardMaterial3D
var siren_blue_material: StandardMaterial3D

func setup(p_society: Node, p_daily_life: Node, p_crime_manager: Node,
		p_region_manager: Node, p_navigation_manager: Node = null) -> void:
	society = p_society
	daily_life = p_daily_life
	crime_manager = p_crime_manager
	region_manager = p_region_manager
	navigation_manager = p_navigation_manager
	if not is_instance_valid(society):
		push_warning("SYSTEM Pedestrians: society manager is unavailable.")
		set_process(false)
		return
	_create_materials()
	if is_instance_valid(crime_manager) and crime_manager.has_signal("crime_case_opened"):
		var callback := Callable(self, "_on_crime_case_opened")
		if not crime_manager.crime_case_opened.is_connected(callback):
			crime_manager.crime_case_opened.connect(callback)
	_refresh_pedestrians()
	set_process(true)
	print("SYSTEM Pedestrians: visible civilian movement connected.")

func _create_materials() -> void:
	for color in [Color(0.68, 0.49, 0.36), Color(0.82, 0.65, 0.51), Color(0.43, 0.29, 0.21)]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.86
		skin_materials.append(material)
	for color in [Color(0.12, 0.20, 0.31), Color(0.35, 0.16, 0.12),
			Color(0.16, 0.29, 0.19), Color(0.36, 0.34, 0.27), Color(0.28, 0.22, 0.34)]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		clothing_materials.append(material)
	police_material = _new_material(Color(0.035, 0.10, 0.22), 0.55)
	ambulance_material = _new_material(Color(0.82, 0.84, 0.82), 0.48)
	glass_material = _new_material(Color(0.045, 0.09, 0.12), 0.22)
	siren_red_material = _new_material(Color(0.9, 0.04, 0.025), 0.3)
	siren_red_material.emission_enabled = true
	siren_red_material.emission = Color(1.0, 0.015, 0.01)
	siren_blue_material = _new_material(Color(0.025, 0.18, 0.95), 0.3)
	siren_blue_material.emission_enabled = true
	siren_blue_material.emission = Color(0.02, 0.12, 1.0)

func _new_material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material

func _process(delta: float) -> void:
	animation_clock += delta
	refresh_clock += delta
	if refresh_clock >= RESIDENT_REFRESH_SECONDS:
		refresh_clock = 0.0
		_refresh_pedestrians()
	_update_pedestrians(delta)
	_update_service_units(delta)

func _refresh_pedestrians() -> void:
	if not is_instance_valid(society):
		return
	var living: Array = society.call("get_living_npcs", WORLD_ID)
	var visible_ids: Dictionary = {}
	var added := 0
	for raw_npc in living:
		if added >= MAX_VISIBLE_CIVILIANS:
			break
		var npc_id := str(raw_npc.get("npc_id", raw_npc.get("id", ""))) if raw_npc is Dictionary else str(raw_npc)
		if npc_id.is_empty():
			continue
		var npc: Dictionary = society.call("get_npc", npc_id)
		if npc.is_empty() or not bool(npc.get("alive", false)):
			continue
		if bool(npc.get("jailed", false)):
			continue
		visible_ids[npc_id] = true
		if not pedestrians.has(npc_id):
			_create_pedestrian(npc_id, npc, added)
		_set_pedestrian_destination(npc_id, npc)
		added += 1
	for npc_id in pedestrians.keys():
		if not visible_ids.has(npc_id):
			var record: Dictionary = pedestrians[npc_id]
			var actor: Node3D = record.get("actor")
			if is_instance_valid(actor):
				actor.queue_free()
			pedestrians.erase(npc_id)

func _create_pedestrian(npc_id: String, npc: Dictionary, seed_index: int) -> void:
	var actor := Node3D.new()
	actor.name = "Civilian_" + npc_id.validate_node_name()
	add_child(actor)
	var seed_value := abs(npc_id.hash())
	var clothing := clothing_materials[seed_value % clothing_materials.size()]
	var skin := skin_materials[(int(seed_value / 7)) % skin_materials.size()]
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.24
	torso_mesh.height = 0.88
	torso.mesh = torso_mesh
	torso.position.y = 1.02
	torso.material_override = clothing
	actor.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.34
	head.mesh = head_mesh
	head.position.y = 1.62
	head.material_override = skin
	actor.add_child(head)
	var left_leg := _create_limb("LeftLeg", Vector3(0.13, 0.48, 0.13), clothing)
	left_leg.position = Vector3(-0.12, 0.48, 0.0)
	actor.add_child(left_leg)
	var right_leg := _create_limb("RightLeg", Vector3(0.13, 0.48, 0.13), clothing)
	right_leg.position = Vector3(0.12, 0.48, 0.0)
	actor.add_child(right_leg)
	var left_arm := _create_limb("LeftArm", Vector3(0.11, 0.52, 0.11), clothing)
	left_arm.position = Vector3(-0.30, 1.02, 0.0)
	actor.add_child(left_arm)
	var right_arm := _create_limb("RightArm", Vector3(0.11, 0.52, 0.11), clothing)
	right_arm.position = Vector3(0.30, 1.02, 0.0)
	actor.add_child(right_arm)
	var city_name := _city_name_for_npc(npc)
	var start := _location_for_action(npc, "home", seed_index)
	actor.position = start
	pedestrians[npc_id] = {
		"actor": actor,
		"city_name": city_name,
		"destination": start,
		"path": [],
		"leg_l": left_leg,
		"leg_r": right_leg,
		"arm_l": left_arm,
		"arm_r": right_arm,
		"phase": float(seed_value % 100) * 0.1,
		"walking": false,
		"seed": seed_index
	}

func _create_limb(limb_name: String, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var limb := MeshInstance3D.new()
	limb.name = limb_name
	var mesh := CapsuleMesh.new()
	mesh.radius = dimensions.x * 0.5
	mesh.height = dimensions.y
	limb.mesh = mesh
	limb.material_override = material
	return limb

func _city_name_for_npc(npc: Dictionary) -> String:
	var city_id := str(npc.get("city_id", "city_baghdad"))
	if city_id == "city_baghdad" or city_id.to_lower().contains("baghdad"):
		return "Baghdad"
	return str(npc.get("city_name", "Baghdad"))

func _city_anchor(city_name: String) -> Vector3:
	if is_instance_valid(region_manager) and region_manager.has_method("get_city_anchor"):
		var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
		if anchor != Vector3.INF:
			return anchor
	return Vector3.ZERO

func _location_for_action(npc: Dictionary, action: String, seed_index: int) -> Vector3:
	var city := _city_name_for_npc(npc)
	var anchor := _city_anchor(city)
	var seed_value := abs(str(npc.get("npc_id", npc.get("id", seed_index))).hash())
	var block_x := float((seed_value % 5) - 2) * 7.0
	var block_z := float((floori(float(seed_value) / 5.0) % 5) - 2) * 7.0
	var home := Vector3(block_x, 0.0, block_z) + anchor
	var district := Vector3(float((seed_value % 3) - 1) * 28.0, 0.0,
		float((floori(float(seed_value) / 3.0) % 3) - 1) * 24.0) + anchor
	match action:
		"work":
			return anchor + Vector3(block_x + 42.0, 0.0, block_z - 18.0)
		"eat", "drink":
			return anchor + Vector3(block_x + 18.0, 0.0, block_z + 26.0)
		"socialize", "family":
			return district
		"sleep", "wash", "serving_sentence", "released_from_sentence":
			return home
		_:
			return home

func _set_pedestrian_destination(npc_id: String, npc: Dictionary) -> void:
	if not pedestrians.has(npc_id):
		return
	var record: Dictionary = pedestrians[npc_id]
	var action := str(npc.get("current_action", "daily_life"))
	var target := _location_for_action(npc, action, int(record.get("seed", 0)))
	var old_target: Vector3 = record.get("destination", Vector3.INF)
	if old_target.distance_to(target) < 1.5:
		return
	record["destination"] = target
	var actor := record["actor"] as Node3D
	if is_instance_valid(navigation_manager) and navigation_manager.has_method("find_pedestrian_path"):
		record["path"] = navigation_manager.call("find_pedestrian_path", str(record.get("city_name", "Baghdad")), actor.position, target)
	else:
		record["path"] = _build_city_block_path(actor.position, target)
	record["walking"] = true
	pedestrians[npc_id] = record

func _build_city_block_path(start: Vector3, target: Vector3) -> Array[Vector3]:
	var path: Array[Vector3] = []
	var bend := Vector3(target.x, start.y, start.z)
	if start.distance_to(bend) > ARRIVAL_DISTANCE:
		path.append(bend)
	if Vector2(bend.x, bend.z).distance_to(Vector2(target.x, target.z)) > ARRIVAL_DISTANCE:
		path.append(Vector3(target.x, target.y, target.z))
	return path

func _update_pedestrians(delta: float) -> void:
	for npc_id in pedestrians.keys():
		var record: Dictionary = pedestrians[npc_id]
		var actor: Node3D = record.get("actor")
		if not is_instance_valid(actor):
			continue
		var path: Array = record.get("path", [])
		var walking := not path.is_empty()
		if walking:
			var target: Vector3 = path[0]
			var direction := target - actor.position
			direction.y = 0.0
			if direction.length() <= ARRIVAL_DISTANCE:
				path.pop_front()
			else:
				var step := direction.normalized()
				var candidate := actor.position + step * WALK_SPEED * delta
				for other_id in pedestrians.keys():
					if str(other_id) == str(npc_id):
						continue
					var other_record: Dictionary = pedestrians[other_id]
					var other_actor := other_record.get("actor") as Node3D
					if not is_instance_valid(other_actor):
						continue
					var separation := candidate - other_actor.position
					separation.y = 0.0
					if separation.length() < 0.9:
						var away := actor.position - other_actor.position
						away.y = 0.0
						if away.length() > 0.01:
							step = (step + away.normalized() * 0.85).normalized()
							candidate = actor.position + step * WALK_SPEED * delta
						if candidate.distance_to(other_actor.position) < 0.62:
							step = Vector3.ZERO
						break
				if step.length() > 0.01:
					actor.position = candidate
					actor.rotation.y = atan2(step.x, step.z)
		record["path"] = path
		record["walking"] = not path.is_empty()
		var phase := float(record.get("phase", 0.0)) + delta * (8.0 if walking else 1.5)
		record["phase"] = phase
		var swing := sin(phase) * (0.48 if walking else 0.025)
		(record["leg_l"] as Node3D).rotation.x = swing
		(record["leg_r"] as Node3D).rotation.x = -swing
		(record["arm_l"] as Node3D).rotation.x = -swing * 0.65
		(record["arm_r"] as Node3D).rotation.x = swing * 0.65
		pedestrians[npc_id] = record

func _on_crime_case_opened(case_id: String, crime_type: String, city_name: String) -> void:
	var record: Dictionary = crime_manager.call("get_crime_case", case_id)
	var severity := int(record.get("severity", 1))
	_spawn_service_unit("police", city_name, case_id)
	if severity >= 4:
		_spawn_service_unit("ambulance", city_name, case_id)

func _spawn_service_unit(unit_type: String, city_name: String, case_id: String) -> void:
	var anchor := _city_anchor(city_name)
	var offset := Vector3(-55.0 - float(next_service_id % 3) * 8.0, 0.0,
		-38.0 + float(next_service_id % 4) * 12.0)
	var vehicle := Node3D.new()
	vehicle.name = "Emergency_" + unit_type + "_" + str(next_service_id)
	add_child(vehicle)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 0.85, 4.5)
	body.mesh = mesh
	body.position.y = 0.65
	body.material_override = police_material if unit_type == "police" else ambulance_material
	vehicle.add_child(body)
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.55, 0.65, 1.8)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.0, 1.38, -0.2)
	cabin.material_override = glass_material
	vehicle.add_child(cabin)
	if unit_type == "police":
		_add_siren(vehicle, Vector3(-0.42, 1.0, -0.25), siren_red_material)
		_add_siren(vehicle, Vector3(0.42, 1.0, -0.25), siren_blue_material)
	vehicle.position = anchor + offset
	var target := anchor + Vector3(float((case_id.hash() % 9) - 4) * 5.0, 0.0,
		float((floori(float(case_id.hash()) / 9.0) % 9) - 4) * 5.0)
	service_units.append({
		"node": vehicle, "type": unit_type, "case_id": case_id,
		"target": target, "phase": "responding", "speed": SERVICE_SPEED
	})
	next_service_id += 1

func _add_siren(parent: Node3D, position: Vector3, material: Material) -> void:
	var lamp := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.32, 0.16, 0.25)
	lamp.mesh = mesh
	lamp.position = position
	lamp.material_override = material
	parent.add_child(lamp)

func _update_service_units(delta: float) -> void:
	for index in range(service_units.size() - 1, -1, -1):
		var unit: Dictionary = service_units[index]
		var vehicle: Node3D = unit.get("node")
		if not is_instance_valid(vehicle):
			service_units.remove_at(index)
			continue
		var target: Vector3 = unit.get("target", vehicle.position)
		var direction := target - vehicle.position
		direction.y = 0.0
		if direction.length() > 2.0:
			var step := direction.normalized()
			vehicle.position += step * float(unit.get("speed", SERVICE_SPEED)) * delta
			vehicle.rotation.y = atan2(step.x, step.z)
		else:
			unit["phase"] = "on_scene"
			unit["ttl"] = float(unit.get("ttl", 0.0)) + delta
			if float(unit["ttl"]) >= 35.0:
				vehicle.queue_free()
				service_units.remove_at(index)
				continue
		service_units[index] = unit

func get_visible_population_status() -> Dictionary:
	return {
		"visible_civilians": pedestrians.size(),
		"active_emergency_units": service_units.size(),
		"movement_model": "lightweight_city_block_waypoints",
		"navigation_mesh_connected": false,
		"scope": "prototype_visual_pedestrian_and_emergency_response"
	}
