extends Node3D
class_name SYSTEMPowerTowerFloorWorld

## Builds one deterministic, large-scale exploration environment for the active Power Tower floor.
## Floors are instanced one at a time; this is a physical first-pass environment, not final art or combat AI.

signal checkpoint_registered(floor_number: int, checkpoint_id: String)
signal floor_exit_requested(floor_number: int, return_position: Vector3)

const FLOOR_SIZE := 520.0
const FLOOR_HALF := FLOOR_SIZE * 0.5
const CHECKPOINT_IDS := ["entry_checkpoint", "midpoint_checkpoint", "pre_boss_checkpoint"]
const GateEnemyScript = preload("res://scripts/modern_world_gate_enemy.gd")

var progression_manager: Node
var player: Node3D
var active_floor_root: Node3D
var active_floor_number := 0
var external_return_position := Vector3.ZERO
var active_floor_data: Dictionary = {}
var active_enemy_ids: Array[String] = []
var floor_started_at_msec := 0


func setup(p_progression_manager: Node, p_player: Node3D) -> void:
	progression_manager = p_progression_manager
	player = p_player


func build_floor(floor_data: Dictionary, p_return_position: Vector3) -> Dictionary:
	var floor_number := int(floor_data.get("floor", 0))
	var region_id := str(floor_data.get("region_id", ""))
	if floor_number < 1 or floor_number > 200 or region_id.is_empty():
		return {"success": false, "reason": "INVALID_FLOOR_DATA"}

	_clear_active_floor()
	active_floor_number = floor_number
	active_floor_data = floor_data.duplicate(true)
	external_return_position = p_return_position

	active_floor_root = Node3D.new()
	active_floor_root.name = "ActiveFloor_%03d" % floor_number
	active_floor_root.set_meta("power_tower_floor", floor_number)
	active_floor_root.set_meta("region_id", region_id)
	active_floor_root.set_meta("large_explorable_region", true)
	active_floor_root.set_meta("boss_floor", bool(floor_data.get("boss_floor", false)))
	add_child(active_floor_root)

	var profile := _region_profile(region_id)
	var ground_color: Color = profile["ground"]
	var structure_color: Color = profile["structure"]
	var accent_color: Color = profile["accent"]
	var ground_material := _material(ground_color, 0.96, 0.0)
	var structure_material := _material(structure_color, 0.82, 0.12)
	var accent_material := _material(accent_color, 0.34, 0.48)
	accent_material.emission_enabled = true
	accent_material.emission = accent_color * 0.28
	accent_material.emission_energy_multiplier = 0.65

	_build_ground(ground_material)
	_build_route(accent_material)
	_build_environment(floor_number, region_id, profile, structure_material, accent_material)
	_build_landmarks(floor_number, profile, structure_material, accent_material)
	_build_checkpoints()
	if is_instance_valid(progression_manager) and int(progression_manager.get("active_floor")) == floor_number:
		_spawn_floor_enemies(floor_data)
	_build_clear_gate()
	_build_exit()
	floor_started_at_msec = Time.get_ticks_msec()

	return {
		"success": true,
		"floor": floor_number,
		"region_id": region_id,
		"region_title": str(floor_data.get("region_title", profile["title"])),
		"checkpoint_count": CHECKPOINT_IDS.size(),
		"boss_floor": bool(floor_data.get("boss_floor", false)),
		"environment_status": "procedural_exploration_blockout",
		"enemy_count": active_enemy_ids.size(),
		"combat_required": not active_enemy_ids.is_empty(),
		"combat": progression_manager.call("get_floor_combat_status", active_floor_number) if is_instance_valid(progression_manager) and progression_manager.has_method("get_floor_combat_status") else {}
	}


func get_entry_position() -> Vector3:
	if not is_instance_valid(active_floor_root):
		return global_position
	var resume_data: Dictionary = active_floor_data.get("resume_data", {})
	var completed: Array = resume_data.get("completed_checkpoint_ids", [])
	var spawn_x := -220.0
	if completed.size() == 1:
		spawn_x = -130.0
	elif completed.size() == 2:
		spawn_x = 15.0
	elif completed.size() >= 3:
		spawn_x = 160.0
	return active_floor_root.to_global(Vector3(spawn_x, 2.0, 0.0))


func get_return_position() -> Vector3:
	return external_return_position


func get_active_floor_info() -> Dictionary:
	return {
		"floor": active_floor_number,
		"region_id": str(active_floor_data.get("region_id", "")),
		"boss_floor": bool(active_floor_data.get("boss_floor", false)),
		"active": is_instance_valid(active_floor_root),
		"checkpoint_count": CHECKPOINT_IDS.size(),
		"enemy_count": active_enemy_ids.size(),
		"combat": progression_manager.call("get_floor_combat_status", active_floor_number) if is_instance_valid(progression_manager) and progression_manager.has_method("get_floor_combat_status") else {}
	}


func _clear_active_floor() -> void:
	if is_instance_valid(active_floor_root):
		remove_child(active_floor_root)
		active_floor_root.queue_free()
	active_floor_root = null
	active_floor_number = 0
	active_floor_data.clear()
	active_enemy_ids.clear()
	floor_started_at_msec = 0


func _spawn_floor_enemies(floor_data: Dictionary) -> void:
	active_enemy_ids.clear()
	if not is_instance_valid(player) or not (player is CharacterBody3D):
		push_warning("SYSTEM Power Tower: player combat actor is unavailable; floor enemies were not spawned.")
		return
	var floor_rank := str(floor_data.get("rank", "E"))
	var boss_floor := bool(floor_data.get("boss_floor", false))
	var regular_count := 0 if boss_floor else clampi(int(floor_data.get("opponent_count", 2)), 1, 8)
	for index in range(regular_count + (1 if boss_floor else 0)):
		var is_boss := boss_floor and index == regular_count
		var enemy_id := "power_tower_%03d_enemy_%02d" % [active_floor_number, index + 1]
		var enemy := GateEnemyScript.new() as CharacterBody3D
		enemy.name = "PowerTowerEnemy_%02d" % (index + 1)
		enemy.call("configure", floor_rank, is_boss, player as CharacterBody3D)
		enemy.set_meta("system_power_tower_enemy_id", enemy_id)
		var spawn_position := Vector3(-35.0 + float(index % 4) * 42.0, 0.0, -38.0 + float(int(index / 4)) * 52.0)
		if is_boss:
			spawn_position = Vector3(205.0, 2.5, 0.0)
		enemy.position = spawn_position
		enemy.call("set_meta", "system_power_tower_floor", active_floor_number)
		enemy.connect("defeated", Callable(self, "_on_floor_enemy_defeated").bind(enemy_id))
		active_floor_root.add_child(enemy)
		active_enemy_ids.append(enemy_id)
	if is_instance_valid(progression_manager) and progression_manager.has_method("set_floor_enemy_roster"):
		var roster_result: Dictionary = progression_manager.call("set_floor_enemy_roster", active_floor_number, active_enemy_ids)
		if not bool(roster_result.get("success", false)):
			push_warning("SYSTEM Power Tower: enemy roster was rejected: " + str(roster_result.get("reason", "unknown")))


func _on_floor_enemy_defeated(_enemy: Node, _is_boss: bool, _xp_reward: int, enemy_id: String) -> void:
	if not is_instance_valid(progression_manager) or not progression_manager.has_method("record_floor_enemy_defeat"):
		return
	var result: Dictionary = progression_manager.call("record_floor_enemy_defeat", active_floor_number, enemy_id)
	if bool(result.get("success", false)):
		print("SYSTEM Power Tower: defeated %s (%d/%d)." % [enemy_id, int(result.get("defeated_enemies", 0)), int(result.get("required_enemies", 0))])


func get_active_enemy_nodes() -> Array[Node]:
	var result: Array[Node] = []
	if not is_instance_valid(active_floor_root):
		return result
	for child in active_floor_root.get_children():
		if child.is_in_group("system_enemy") and child.has_method("take_damage"):
			result.append(child)
	return result


func _build_clear_gate() -> void:
	var gate_material := _material(Color(0.92, 0.66, 0.18), 0.22, 0.48)
	gate_material.emission_enabled = true
	gate_material.emission = Color(0.62, 0.32, 0.04)
	gate_material.emission_energy_multiplier = 1.6
	_add_obstacle("FloorClearGateLeft", Vector3(250.0, 5.0, -9.0), Vector3(2.0, 10.0, 2.0), gate_material)
	_add_obstacle("FloorClearGateRight", Vector3(250.0, 5.0, 9.0), Vector3(2.0, 10.0, 2.0), gate_material)
	_add_obstacle("FloorClearGateHeader", Vector3(250.0, 10.0, 0.0), Vector3(2.0, 1.5, 20.0), gate_material)
	var label := Label3D.new()
	label.name = "FloorClearGateSign"
	label.text = "FLOOR CLEAR — CLAIM REWARD"
	label.font_size = 18
	label.position = Vector3(250.0, 13.0, 0.0)
	label.modulate = Color(1.0, 0.86, 0.46)
	active_floor_root.add_child(label)
	var area := Area3D.new()
	area.name = "FloorClearGate"
	area.position = Vector3(250.0, 2.0, 0.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(12.0, 8.0, 18.0)
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_floor_clear_gate_body_entered)
	active_floor_root.add_child(area)


func _on_floor_clear_gate_body_entered(body: Node3D) -> void:
	if not is_instance_valid(body) or not body.is_in_group("system_player"):
		return
	if not is_instance_valid(progression_manager) or not progression_manager.has_method("confirm_floor_clear"):
		return
	var elapsed := maxf(float(Time.get_ticks_msec() - floor_started_at_msec) / 1000.0, 0.1)
	var result: Dictionary = progression_manager.call("confirm_floor_clear", active_floor_number, elapsed)
	if bool(result.get("success", false)):
		print("SYSTEM Power Tower: floor %d cleared with rank %s." % [active_floor_number, str(result.get("rank", "?"))])
		floor_exit_requested.emit(active_floor_number, external_return_position)
	else:
		push_warning("SYSTEM Power Tower: clear gate rejected the run: " + str(result.get("reason", "unknown")))


func _build_ground(material: Material) -> void:
	_add_obstacle(
		"GroundCollision",
		Vector3(0.0, -1.0, 0.0),
		Vector3(FLOOR_SIZE, 2.0, FLOOR_SIZE),
		material
	)


func _build_route(material: Material) -> void:
	_add_visual_box("MainExplorationRoute", Vector3(0.0, 0.035, 0.0), Vector3(12.0, 0.07, FLOOR_SIZE - 36.0), material)
	_add_visual_box("CrossExplorationRoute", Vector3(0.0, 0.04, 0.0), Vector3(FLOOR_SIZE - 36.0, 0.08, 9.0), material)


func _build_environment(
	floor_number: int,
	region_id: String,
	profile: Dictionary,
	structure_material: Material,
	accent_material: Material
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(floor_number * 7919 + abs(region_id.hash()))
	var style := str(profile.get("style", "ruins"))

	for index in range(22):
		var point := Vector3(rng.randf_range(-190.0, 190.0), 0.0, rng.randf_range(-190.0, 190.0))
		if absf(point.x) < 28.0:
			point.x += 52.0 if point.x >= 0.0 else -52.0
		if absf(point.z) < 22.0:
			point.z += 42.0 if point.z >= 0.0 else -42.0
		var width := rng.randf_range(5.0, 14.0)
		var height := rng.randf_range(7.0, 25.0)
		var depth := rng.randf_range(5.0, 14.0)
		var obstacle_material: Material = accent_material if index % 4 == 0 else structure_material

		match style:
			"forest":
				_add_obstacle("ForestTrunk_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(2.8, height, 2.8), structure_material)
				_add_visual_box("ForestCanopy_%02d" % index, point + Vector3.UP * (height + 3.0), Vector3(width + 8.0, 8.0, depth + 8.0), accent_material)
			"citadel", "labyrinth":
				_add_obstacle("Fortification_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(width + 5.0, height, depth), obstacle_material)
			"beast":
				_add_obstacle("BeastWildRock_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(width, height, depth), obstacle_material)
			"training":
				_add_obstacle("TrainingPylon_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(4.0, height, 4.0), obstacle_material)
				_add_visual_box("TrainingPad_%02d" % index, point + Vector3(0.0, 0.08, 8.0), Vector3(width + 6.0, 0.16, depth + 6.0), accent_material)
			"elemental":
				_add_obstacle("ElementalCrystal_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(width * 0.55, height, depth * 0.55), obstacle_material)
			"giant":
				_add_obstacle("GiantPillar_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(width * 1.8, height * 1.8, depth * 1.8), obstacle_material)
			"mythic":
				_add_obstacle("MythicMonolith_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(width * 0.7, height * 1.3, depth * 0.7), obstacle_material)
			_:
				_add_obstacle("AncientStructure_%02d" % index, point + Vector3.UP * (height * 0.5), Vector3(width, height, depth), obstacle_material)

	for corner in [
		Vector3(-FLOOR_HALF + 8.0, 9.0, -FLOOR_HALF + 8.0),
		Vector3(FLOOR_HALF - 8.0, 9.0, -FLOOR_HALF + 8.0),
		Vector3(-FLOOR_HALF + 8.0, 9.0, FLOOR_HALF - 8.0),
		Vector3(FLOOR_HALF - 8.0, 9.0, FLOOR_HALF - 8.0)
	]:
		_add_obstacle("RegionBoundaryPillar_%d" % active_floor_root.get_child_count(), corner, Vector3(8.0, 18.0, 8.0), accent_material)


func _build_landmarks(
	floor_number: int,
	profile: Dictionary,
	structure_material: Material,
	accent_material: Material
) -> void:
	var accent_color: Color = profile["accent"]
	_add_obstacle("FloorArrivalGateLeft", Vector3(-205.0, 8.0, -15.0), Vector3(5.0, 16.0, 4.0), accent_material)
	_add_obstacle("FloorArrivalGateRight", Vector3(-205.0, 8.0, 15.0), Vector3(5.0, 16.0, 4.0), accent_material)
	_add_obstacle("FloorArrivalGateHeader", Vector3(-205.0, 16.0, 0.0), Vector3(5.0, 2.0, 34.0), accent_material)
	_add_obstacle("CentralRegionLandmark", Vector3(0.0, 7.0, 45.0), Vector3(24.0, 14.0, 24.0), structure_material)
	_add_visual_box("CentralLandmarkCrown", Vector3(0.0, 16.0, 45.0), Vector3(18.0, 2.0, 18.0), accent_material)

	var region_sign := Label3D.new()
	region_sign.name = "FloorRegionSign"
	region_sign.text = "FLOOR %03d\n%s" % [floor_number, str(profile["title"])]
	region_sign.font_size = 28
	region_sign.position = Vector3(0.0, 20.0, -22.0)
	region_sign.modulate = accent_color
	active_floor_root.add_child(region_sign)

	if floor_number % 10 == 0:
		_add_obstacle("BossArenaPlatform", Vector3(205.0, 1.2, 0.0), Vector3(54.0, 2.4, 54.0), accent_material)
		_add_obstacle("BossSpawnMarker", Vector3(205.0, 4.0, 0.0), Vector3(8.0, 8.0, 8.0), structure_material)
		var boss_sign := Label3D.new()
		boss_sign.name = "BossTrialSign"
		boss_sign.text = "BOSS TRIAL\nFLOOR %03d" % floor_number
		boss_sign.font_size = 24
		boss_sign.position = Vector3(205.0, 18.0, -34.0)
		boss_sign.modulate = accent_color
		active_floor_root.add_child(boss_sign)


func _build_checkpoints() -> void:
	var checkpoint_positions := [
		Vector3(-145.0, 2.0, 0.0),
		Vector3(0.0, 2.0, 0.0),
		Vector3(145.0, 2.0, 0.0)
	]
	var marker_material := _material(Color(0.12, 0.76, 0.96), 0.24, 0.42)
	marker_material.emission_enabled = true
	marker_material.emission = Color(0.04, 0.42, 0.72)
	marker_material.emission_energy_multiplier = 1.2
	for index in range(CHECKPOINT_IDS.size()):
		var checkpoint_id := str(CHECKPOINT_IDS[index])
		var marker := MeshInstance3D.new()
		marker.name = "CheckpointMarker_" + checkpoint_id
		var ring := TorusMesh.new()
		ring.inner_radius = 4.5
		ring.outer_radius = 5.0
		ring.ring_segments = 40
		marker.mesh = ring
		marker.position = checkpoint_positions[index] + Vector3.UP * 0.18
		marker.material_override = marker_material
		active_floor_root.add_child(marker)
		var marker_label := Label3D.new()
		marker_label.name = "CheckpointLabel_" + checkpoint_id
		marker_label.text = "CHECKPOINT %02d" % (index + 1)
		marker_label.font_size = 18
		marker_label.position = checkpoint_positions[index] + Vector3.UP * 5.0
		marker_label.modulate = Color(0.52, 0.88, 1.0)
		active_floor_root.add_child(marker_label)
		var area := Area3D.new()
		area.name = "Checkpoint_" + checkpoint_id
		area.position = checkpoint_positions[index]
		area.set_meta("floor_number", active_floor_number)
		area.set_meta("checkpoint_id", checkpoint_id)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(14.0, 8.0, 14.0)
		collision.shape = shape
		area.add_child(collision)
		area.body_entered.connect(_on_checkpoint_body_entered.bind(checkpoint_id))
		active_floor_root.add_child(area)


func _build_exit() -> void:
	var gate_material := _material(Color(0.12, 0.66, 0.82), 0.24, 0.5)
	gate_material.emission_enabled = true
	gate_material.emission = Color(0.03, 0.3, 0.52)
	gate_material.emission_energy_multiplier = 1.4
	_add_obstacle("FloorReturnGateLeft", Vector3(-250.0, 5.0, -8.0), Vector3(1.5, 10.0, 1.5), gate_material)
	_add_obstacle("FloorReturnGateRight", Vector3(-250.0, 5.0, 8.0), Vector3(1.5, 10.0, 1.5), gate_material)
	_add_obstacle("FloorReturnGateHeader", Vector3(-250.0, 10.0, 0.0), Vector3(1.5, 1.5, 18.0), gate_material)
	var exit_label := Label3D.new()
	exit_label.name = "FloorReturnGateSign"
	exit_label.text = "RETURN TO POWER TOWER"
	exit_label.font_size = 18
	exit_label.position = Vector3(-250.0, 13.0, 0.0)
	exit_label.modulate = Color(0.5, 0.9, 1.0)
	active_floor_root.add_child(exit_label)
	var exit_area := Area3D.new()
	exit_area.name = "FloorReturnGate"
	exit_area.position = Vector3(-250.0, 2.0, 0.0)
	exit_area.set_meta("floor_number", active_floor_number)
	exit_area.set_meta("return_gate", true)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(12.0, 8.0, 18.0)
	collision.shape = shape
	exit_area.add_child(collision)
	exit_area.body_entered.connect(_on_floor_exit_body_entered)
	active_floor_root.add_child(exit_area)


func _on_checkpoint_body_entered(body: Node3D, checkpoint_id: String) -> void:
	if not is_instance_valid(body) or not body.is_in_group("system_player"):
		return
	if not is_instance_valid(progression_manager) or not progression_manager.has_method("record_floor_checkpoint"):
		return
	var result: Dictionary = progression_manager.call("record_floor_checkpoint", active_floor_number, checkpoint_id)
	if bool(result.get("success", false)):
		checkpoint_registered.emit(active_floor_number, checkpoint_id)


func _on_floor_exit_body_entered(body: Node3D) -> void:
	if not is_instance_valid(body) or not body.is_in_group("system_player"):
		return
	floor_exit_requested.emit(active_floor_number, external_return_position)


func _add_obstacle(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	active_floor_root.add_child(body)


func _add_visual_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	active_floor_root.add_child(visual)


func _region_profile(region_id: String) -> Dictionary:
	match region_id:
		"frontier_forest":
			return {"title": "غابات الحدود", "style": "forest", "ground": Color(0.12, 0.25, 0.15), "structure": Color(0.25, 0.19, 0.12), "accent": Color(0.18, 0.56, 0.28)}
		"warrior_citadels":
			return {"title": "قلاع المحاربين", "style": "citadel", "ground": Color(0.24, 0.22, 0.20), "structure": Color(0.40, 0.37, 0.33), "accent": Color(0.75, 0.42, 0.15)}
		"beast_wilds":
			return {"title": "براري الوحوش", "style": "beast", "ground": Color(0.27, 0.22, 0.16), "structure": Color(0.39, 0.34, 0.28), "accent": Color(0.72, 0.26, 0.18)}
		"shifting_labyrinths":
			return {"title": "المتاهات المتحولة", "style": "labyrinth", "ground": Color(0.17, 0.18, 0.23), "structure": Color(0.31, 0.33, 0.40), "accent": Color(0.23, 0.70, 0.82)}
		"elite_proving_grounds":
			return {"title": "ميادين النخبة", "style": "training", "ground": Color(0.20, 0.21, 0.24), "structure": Color(0.34, 0.37, 0.42), "accent": Color(0.92, 0.68, 0.22)}
		"elemental_frontiers":
			return {"title": "حدود العناصر", "style": "elemental", "ground": Color(0.15, 0.20, 0.25), "structure": Color(0.31, 0.42, 0.49), "accent": Color(0.18, 0.78, 0.92)}
		"lost_kingdoms":
			return {"title": "الممالك المفقودة", "style": "ruins", "ground": Color(0.25, 0.22, 0.17), "structure": Color(0.49, 0.39, 0.27), "accent": Color(0.82, 0.64, 0.29)}
		"giant_territories":
			return {"title": "أقاليم العمالقة", "style": "giant", "ground": Color(0.23, 0.23, 0.20), "structure": Color(0.42, 0.42, 0.38), "accent": Color(0.69, 0.57, 0.37)}
		"mythic_reaches":
			return {"title": "المناطق الأسطورية", "style": "mythic", "ground": Color(0.16, 0.16, 0.23), "structure": Color(0.34, 0.32, 0.44), "accent": Color(0.55, 0.32, 0.82)}
		_:
			return {"title": "تحديات القمة", "style": "training", "ground": Color(0.16, 0.17, 0.19), "structure": Color(0.32, 0.34, 0.38), "accent": Color(0.92, 0.54, 0.16)}


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
