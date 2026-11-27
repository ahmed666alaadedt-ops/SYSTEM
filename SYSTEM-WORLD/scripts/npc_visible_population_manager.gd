extends Node3D
class_name SystemNPCVisiblePopulationManager

## Visible pedestrian layer for the modern world.
## Uses lightweight procedural characters and bounded updates; destinations are
## approximate city-block anchors until real street/navigation data is connected.

const NPCHumanoidVisualScript = preload("res://scripts/npc_character_model.gd")
const NPCThreatReceiverScript = preload("res://scripts/npc_threat_receiver.gd")

const WORLD_ID := 2
## Higher pedestrian density with a hard cap for mobile frame-time safety.
const MAX_VISIBLE_CIVILIANS := 72
const WALK_SPEED := 1.45
const ARRIVAL_DISTANCE := 0.65
const RESIDENT_REFRESH_SECONDS := 5.0
const SERVICE_SPEED := 8.0

var society: Node
var daily_life: Node
var crime_manager: Node
var region_manager: Node
var navigation_manager: Node
signal npc_defensive_response(npc_id: String, response: String)

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
	print("SYSTEM Pedestrians: nearest-resident streaming connected; visible cap=", MAX_VISIBLE_CIVILIANS)

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
	var player := get_parent().get_node_or_null("Player") as Node3D
	var reference_position := to_local(player.global_position) if is_instance_valid(player) else Vector3.ZERO
	var candidates: Array[Dictionary] = []
	for raw_npc in living:
		if not raw_npc is Dictionary:
			continue
		var npc: Dictionary = raw_npc
		var npc_id := str(npc.get("npc_id", npc.get("id", "")))
		if npc_id.is_empty() or not bool(npc.get("alive", false)) or bool(npc.get("jailed", false)):
			continue
		var home := _location_for_action(npc, "home", 0)
		candidates.append({
			"npc_id": npc_id,
			"npc": npc,
			"distance_squared": Vector2(home.x - reference_position.x, home.z - reference_position.z).length_squared()
		})
	# Keep the nearest residents around the player, not the first records in the database.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance_squared"]) < float(b["distance_squared"])
	)
	var visible_ids: Dictionary = {}
	var visible_count := mini(MAX_VISIBLE_CIVILIANS, candidates.size())
	for index in range(visible_count):
		var candidate: Dictionary = candidates[index]
		var npc_id := str(candidate["npc_id"])
		var npc: Dictionary = candidate["npc"]
		visible_ids[npc_id] = true
		if not pedestrians.has(npc_id):
			_create_pedestrian(npc_id, npc, index)
		_set_pedestrian_destination(npc_id, npc)
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
	actor.set_script(NPCThreatReceiverScript)
	actor.set("npc_id", npc_id)
	actor.set("population_manager", self)
	add_child(actor)

	var hit_area := Area3D.new()
	hit_area.name = "NPCThreatHitArea"
	hit_area.collision_layer = 2
	hit_area.collision_mask = 0
	hit_area.monitoring = false
	hit_area.monitorable = true
	hit_area.input_ray_pickable = true
	var hit_shape := CollisionShape3D.new()
	var hit_capsule := CapsuleShape3D.new()
	hit_capsule.radius = 0.42
	hit_capsule.height = 1.8
	hit_shape.shape = hit_capsule
	hit_shape.position.y = 0.9
	hit_area.add_child(hit_shape)
	actor.add_child(hit_area)

	var visual := NPCHumanoidVisualScript.new()
	visual.name = "HumanoidVisual"
	actor.add_child(visual)
	var visual_profile := npc.duplicate(true)
	visual_profile["name"] = str(npc.get("name", npc.get("display_name", npc_id)))
	visual_profile["job"] = str(npc.get("occupation", npc.get("job", "")))
	# Society records store age_years; the character renderer consumes age.
	# Preserve the real age so child and elder residents load their dedicated GLBs.
	visual_profile["age"] = float(npc.get("age_years", npc.get("age", 30.0)))

	# Give residents stable, reproducible visual variety while preserving any
	# explicit appearance data already stored on their society profile.
	var appearance_seed := absi(npc_id.hash())
	var appearance_defaults := {
		"gender": "female" if posmod(appearance_seed, 2) == 1 else "male",
		"skin_tone": ["fair", "olive", "tan", "dark"][posmod(appearance_seed / 3, 4)],
		"hair_color": ["black", "brown", "blonde", "gray", "red"][posmod(appearance_seed / 5, 5)],
		"eye_color": ["brown", "green", "gray", "hazel", "blue"][posmod(appearance_seed / 7, 5)],
		"face_shape": ["balanced", "sharp", "soft", "wide", "long", "round", "heart"][posmod(appearance_seed / 11, 7)],
		"body_type": ["slim", "average", "athletic", "heavy", "muscular"][posmod(appearance_seed / 13, 5)],
		"height_type": ["short", "average", "tall"][posmod(appearance_seed / 17, 3)],
		"hair_style": ["short", "fade", "medium", "long", "curly", "braided", "ponytail", "bun", "afro", "dreadlocks", "quiff", "slick_back", "side_swept"][posmod(appearance_seed / 19, 13)]
	}
	for appearance_key in appearance_defaults.keys():
		if not visual_profile.has(appearance_key) or str(visual_profile.get(appearance_key, "")).is_empty():
			visual_profile[appearance_key] = appearance_defaults[appearance_key]
	visual.configure(visual_profile, seed_index)

	var city_name := _city_name_for_npc(npc)
	var start := _location_for_action(npc, "home", seed_index)
	actor.position = start
	pedestrians[npc_id] = {
		"actor": actor,
		"visual": visual,
		"city_name": city_name,
		"destination": start,
		"path": [],
		"phase": float(absi(npc_id.hash()) % 100) * 0.1,
		"walking": false,
		"animation_walking": false,
		"seed": seed_index
	}

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
	var seed_value: int = absi(str(npc.get("npc_id", npc.get("id", seed_index))).hash())
	# Spread thousands of residents over a deterministic 41 x 41 city-block grid.
	# This prevents the old 5 x 5 spawn cluster from stacking crowds on one spot.
	var grid_x := posmod(seed_value, 41) - 20
	var grid_z := posmod(floori(float(seed_value) / 41.0), 41) - 20
	var block_x := float(grid_x) * 8.0
	var block_z := float(grid_z) * 8.0
	var home := Vector3(block_x, 0.0, block_z) + anchor
	var district := Vector3(float(posmod(grid_x, 7) - 3) * 42.0, 0.0,
		float(posmod(grid_z, 7) - 3) * 42.0) + anchor
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

## Called by a trusted hit/threat detector when a visible civilian NPC is attacked.
## Minors evade farther toward safety; adults adopt a defensive stance and retreat.
## NPCs never counterattack or become combatants.
func notify_npc_attacked(npc_id: String, attacker_global_position: Vector3) -> bool:
	if not pedestrians.has(npc_id):
		return false
	var record: Dictionary = pedestrians[npc_id]
	var actor := record.get("actor") as Node3D
	var visual := record.get("visual") as Node
	if not is_instance_valid(actor) or not is_instance_valid(visual):
		return false
	if not visual.has_method("respond_to_attack") or not bool(visual.call("respond_to_attack")):
		return false

	var is_minor := str(visual.get("age_group")) == "child"
	var away := actor.global_position - attacker_global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = -actor.global_basis.z
		away.y = 0.0
	if away.length_squared() < 0.0001:
		away = Vector3.BACK
	var retreat_distance := 6.0 if is_minor else 3.0
	var safe_global_target := actor.global_position + away.normalized() * retreat_distance
	var safe_local_target := to_local(safe_global_target)
	record["destination"] = safe_local_target
	record["path"] = _build_city_block_path(actor.position, safe_local_target)
	record["walking"] = true
	record["animation_walking"] = true
	pedestrians[npc_id] = record
	npc_defensive_response.emit(npc_id, "evade_to_safety" if is_minor else "defend_and_retreat")
	return true


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
		var visual: Node = record.get("visual")
		if is_instance_valid(visual) and bool(record.get("animation_walking", false)) != walking:
			visual.call("set_activity", "walk" if walking else "idle")
			record["animation_walking"] = walking
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
