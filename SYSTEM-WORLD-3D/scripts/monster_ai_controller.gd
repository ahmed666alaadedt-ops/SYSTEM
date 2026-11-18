extends Node

# SYSTEM WORLD - Monster AI Controller
# Prototype AI: patrol, detect player, pursue and attack.
# Actual combat/damage integration is intentionally exposed through signals.

signal monster_spawned(monster_data: Dictionary)
signal monster_attacked_player(monster_id: String, damage: float)
signal monster_defeated(monster_id: String, reward_xp: int)

const DETECTION_RANGE := 18.0
const ATTACK_RANGE := 2.0
const ATTACK_COOLDOWN := 2.0
const MAX_VISIBLE_PER_GATE := 12

var world_root: Node3D
var player: Node3D
var monsters: Array[Dictionary] = []
var initialized := false
var monster_counter := 0


func setup(world: Node3D, player_node: Node3D) -> void:
	world_root = world
	player = player_node
	initialized = is_instance_valid(world_root)
	print("SYSTEM: Monster AI Controller initialized.")


func spawn_gate_wave(gate_data: Dictionary) -> void:
	if not initialized or not is_instance_valid(world_root):
		return

	var gate_position: Vector3 = gate_data.get("position", Vector3.ZERO)
	var requested_count := int(gate_data.get("monster_count", 4))
	var visible_count := mini(requested_count, MAX_VISIBLE_PER_GATE)
	var rank := str(gate_data.get("displayed_rank", "F"))
	var boss_count := int(gate_data.get("boss_count", 0))

	for index in range(visible_count):
		var angle := TAU * float(index) / float(maxi(visible_count, 1))
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * randf_range(5.0, 11.0)
		_create_monster(gate_position + offset, rank, false)

	if boss_count > 0:
		_create_monster(gate_position + Vector3(0, 0, -13), rank, true)

	print("SYSTEM: Gate wave spawned. Visible monsters: ", visible_count)


func _create_monster(position: Vector3, rank: String, is_boss: bool) -> void:
	monster_counter += 1
	var monster_id := "MON-%06d" % monster_counter
	var actor := Node3D.new()
	actor.name = monster_id
	actor.position = position

	var body := MeshInstance3D.new()
	var mesh: Mesh
	if is_boss:
		var sphere := SphereMesh.new()
		sphere.radius = 1.15
		sphere.height = 2.3
		mesh = sphere
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.48
		capsule.height = 1.7
		mesh = capsule
	body.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = _rank_color(rank)
	material.roughness = 0.72
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.22
	body.material_override = material
	body.position.y = 0.95 if not is_boss else 1.2
	actor.add_child(body)

	var label := Label3D.new()
	label.text = ("BOSS " if is_boss else "MONSTER ") + rank
	label.position.y = 2.3 if not is_boss else 3.0
	label.font_size = 22 if not is_boss else 30
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	actor.add_child(label)

	world_root.add_child(actor)

	var hp := 100.0 + float(RANKS_INDEX(rank)) * 75.0
	if is_boss:
		hp *= 8.0

	monsters.append({
		"id": monster_id,
		"node": actor,
		"rank": rank,
		"is_boss": is_boss,
		"health": hp,
		"max_health": hp,
		"state": "patrol",
		"speed": (2.0 + float(RANKS_INDEX(rank)) * 0.22) * (1.2 if is_boss else 1.0),
		"attack_timer": randf_range(0.2, 1.0),
		"patrol_target": position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	})

	monster_spawned.emit({
		"id": monster_id, "rank": rank, "is_boss": is_boss,
		"health": hp, "position": position
	})


func update_world(delta: float) -> void:
	if not initialized:
		return

	for index in range(monsters.size() - 1, -1, -1):
		var data: Dictionary = monsters[index]
		var actor = data.get("node")
		if not is_instance_valid(actor):
			monsters.remove_at(index)
			continue
		_update_monster(data, delta)


func _update_monster(data: Dictionary, delta: float) -> void:
	var actor: Node3D = data["node"]
	if not is_instance_valid(player):
		return

	var distance := actor.global_position.distance_to(player.global_position)
	data["attack_timer"] = maxf(0.0, float(data["attack_timer"]) - delta)

	if distance <= DETECTION_RANGE:
		data["state"] = "chase"
		if distance <= ATTACK_RANGE:
			data["state"] = "attack"
			_try_attack(data)
		else:
			_move_toward(actor, player.global_position, float(data["speed"]), delta)
	else:
		data["state"] = "patrol"
		var patrol_target: Vector3 = data["patrol_target"]
		if actor.global_position.distance_to(patrol_target) < 1.2:
			data["patrol_target"] = actor.global_position + Vector3(
				randf_range(-7.0, 7.0), 0.0, randf_range(-7.0, 7.0)
			)
		else:
			_move_toward(actor, patrol_target, float(data["speed"]) * 0.35, delta)


func _move_toward(actor: Node3D, target: Vector3, speed: float, delta: float) -> void:
	var flat_target := Vector3(target.x, actor.global_position.y, target.z)
	var direction := flat_target - actor.global_position
	if direction.length() < 0.05:
		return
	actor.global_position = actor.global_position.move_toward(flat_target, speed * delta)
	actor.rotation.y = lerp_angle(
		actor.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 5.0)
	)


func _try_attack(data: Dictionary) -> void:
	if float(data["attack_timer"]) > 0.0:
		return
	data["attack_timer"] = ATTACK_COOLDOWN
	var rank_index := RANKS_INDEX(str(data["rank"]))
	var damage := 5.0 + float(rank_index) * 4.0
	if bool(data["is_boss"]):
		damage *= 2.5
	monster_attacked_player.emit(str(data["id"]), damage)


func apply_damage(monster_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return false
	for index in range(monsters.size()):
		var data: Dictionary = monsters[index]
		if str(data["id"]) != monster_id:
			continue
		data["health"] = maxf(0.0, float(data["health"]) - amount)
		if float(data["health"]) <= 0.0:
			var actor = data.get("node")
			if is_instance_valid(actor):
				actor.queue_free()
			var xp := 25 + RANKS_INDEX(str(data["rank"])) * 50
			if bool(data["is_boss"]):
				xp *= 10
			monster_defeated.emit(monster_id, xp)
			monsters.remove_at(index)
		return true
	return false


func get_monster_count() -> int:
	return monsters.size()


func get_monster_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in monsters:
		result.append({
			"id": data["id"], "rank": data["rank"],
			"is_boss": data["is_boss"], "health": data["health"],
			"max_health": data["max_health"], "state": data["state"]
		})
	return result


func _rank_color(rank: String) -> Color:
	match rank:
		"F": return Color(0.35, 0.75, 1.0)
		"E": return Color(0.25, 0.9, 0.55)
		"D": return Color(0.1, 0.8, 0.85)
		"C": return Color(0.55, 0.35, 1.0)
		"B": return Color(1.0, 0.25, 0.2)
		"A": return Color(1.0, 0.65, 0.15)
		"S": return Color(1.0, 0.85, 0.2)
		"SS": return Color(0.9, 0.15, 0.45)
		"SSS": return Color(0.65, 0.1, 0.95)
		"EX": return Color(0.95, 0.95, 1.0)
	return Color.WHITE


func RANKS_INDEX(rank: String) -> int:
	var ranks := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "EX"]
	return maxi(0, ranks.find(rank))
