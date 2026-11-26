extends Node3D
class_name ModernWorldMonsterGateManager

const GateEnemyScript = preload("res://scripts/modern_world_gate_enemy.gd")

## Procedural monster-gate network for every named city and the wilderness.
## Dungeon rooms and encounter markers are generated locally; combat AI/rewards
## are intentionally left to the shared combat and progression systems.

const CITY_SITES := [
	{"name":"New York","position":Vector2(-650.0,-260.0)},
	{"name":"London","position":Vector2(-420.0,-90.0)},
	{"name":"Paris","position":Vector2(-300.0,110.0)},
	{"name":"Baghdad","position":Vector2(0.0,0.0)},
	{"name":"Moscow","position":Vector2(120.0,-470.0)},
	{"name":"Cairo","position":Vector2(-80.0,330.0)},
	{"name":"New Delhi","position":Vector2(390.0,230.0)},
	{"name":"Guangzhou","position":Vector2(650.0,40.0)},
	{"name":"Seoul","position":Vector2(820.0,-260.0)},
	{"name":"Tokyo","position":Vector2(1030.0,80.0)},
	{"name":"Singapore","position":Vector2(560.0,490.0)},
	{"name":"Sydney","position":Vector2(1050.0,680.0)},
	{"name":"Rio de Janeiro","position":Vector2(-850.0,420.0)},
	{"name":"Johannesburg","position":Vector2(-350.0,610.0)}
]

const WILDERNESS_SITES := [
	Vector2(-980.0,-500.0), Vector2(-760.0,520.0),
	Vector2(-520.0,-690.0), Vector2(-180.0,-760.0),
	Vector2(280.0,-760.0), Vector2(560.0,-610.0),
	Vector2(900.0,-520.0), Vector2(1180.0,260.0),
	Vector2(760.0,760.0), Vector2(260.0,820.0),
	Vector2(-420.0,820.0), Vector2(-1080.0,160.0)
]

const GATE_RANKS := ["F","E","D","C","B","A","S","SS","SSS","EX"]
const GATE_COLORS := [
	Color(0.35,0.75,0.9), Color(0.25,0.85,1.0),
	Color(0.2,0.95,0.65), Color(0.75,0.35,1.0),
	Color(1.0,0.62,0.16), Color(1.0,0.24,0.16),
	Color(0.9,0.08,0.3), Color(0.95,0.35,0.72),
	Color(0.95,0.12,0.55), Color(1.0,0.88,0.22)
]

var modern_root: Node3D
var terrain: Node
var rng := RandomNumberGenerator.new()
var gate_counter := 0
var active_dungeon: Node3D
var active_player: CharacterBody3D
var return_position := Vector3.ZERO
var current_gate: Area3D
var dungeon_exit: Area3D
var enemies_remaining := 0
var boss_defeated := false
var active_gate_rank := "F"
var dungeon_xp_awarded := 0
var gate_event_timer: Timer


func _ready() -> void:
	name = "ModernWorldMonsterGateManager"
	rng.randomize()
	call_deferred("_initialize_gate_network")
	gate_event_timer = Timer.new()
	gate_event_timer.name = "MonsterGateEventTimer"
	gate_event_timer.wait_time = 150.0
	gate_event_timer.one_shot = false
	add_child(gate_event_timer)
	gate_event_timer.timeout.connect(_spawn_random_gate_event)
	gate_event_timer.start()


func _initialize_gate_network() -> void:
	modern_root = get_parent() as Node3D
	if modern_root == null:
		push_warning("SYSTEM: Monster gates require the modern world root.")
		return
	terrain = modern_root.get_node_or_null("ModernContinent")
	_create_city_gate_network()
	_create_wilderness_gate_network()
	print("SYSTEM: Monster gate network created across all cities and wilderness regions.")


func _spawn_random_gate_event() -> void:
	if modern_root == null or active_dungeon != null:
		return
	var choose_city := rng.randf() < 0.72
	if choose_city:
		var city: Dictionary = CITY_SITES[rng.randi_range(0,CITY_SITES.size()-1)]
		var center: Vector2 = city["position"]
		var angle := rng.randf_range(0.0,TAU)
		var distance := rng.randf_range(30.0,72.0)
		var location := center + Vector2(cos(angle),sin(angle)) * distance
		_create_gate(str(city["name"]),location,rng.randf() < 0.18)
	else:
		var location: Vector2 = WILDERNESS_SITES[rng.randi_range(0,WILDERNESS_SITES.size()-1)]
		_create_gate("Wilderness",location,rng.randf() < 0.3)


func _create_city_gate_network() -> void:
	for city in CITY_SITES:
		var center: Vector2 = city["position"]
		for local_index in range(2):
			var angle := rng.randf_range(0.0, TAU)
			var distance := rng.randf_range(24.0, 58.0)
			var location := center + Vector2(cos(angle), sin(angle)) * distance
			_create_gate(str(city["name"]), location, local_index == 0)


func _create_wilderness_gate_network() -> void:
	for index in range(WILDERNESS_SITES.size()):
		_create_gate("Wilderness", WILDERNESS_SITES[index], index % 4 == 0)


func _terrain_height(x: float, z: float) -> float:
	if terrain != null and terrain.has_method("get_terrain_height"):
		return float(terrain.call("get_terrain_height", x, z))
	return 0.0


func _roll_gate_rank(elite_event: bool) -> int:
	var roll := rng.randf()
	if elite_event and roll < 0.005:
		return 9
	if elite_event and roll < 0.02:
		return 8
	if elite_event and roll < 0.06:
		return 7
	if elite_event and roll < 0.14:
		return 6
	return rng.randi_range(0, 5)


func _create_gate(region_name: String, location: Vector2, elite_event: bool) -> void:
	if terrain != null and terrain.has_method("is_land_position"):
		if not bool(terrain.call("is_land_position", location.x, location.y)):
			return
	gate_counter += 1
	var rank_index := _roll_gate_rank(elite_event)
	var rank: String = str(GATE_RANKS[rank_index])
	var gate := Area3D.new()
	gate.name = "MonsterGate_%03d" % gate_counter
	gate.position = Vector3(location.x, _terrain_height(location.x, location.y), location.y)
	gate.collision_layer = 1
	gate.collision_mask = 1
	gate.monitoring = true
	gate.monitorable = true
	gate.add_to_group("system_interactable")
	gate.add_to_group("system_monster_gate")
	gate.set_meta("system_monster_gate", true)
	gate.set_meta("system_gate_rank", rank)
	gate.set_meta("system_gate_region", region_name)
	gate.set_meta("system_gate_id", gate.name)
	gate.set_meta("system_gate_status", "active")

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.8
	collision.shape = sphere
	collision.position.y = 2.0
	gate.add_child(collision)
	_build_gate_visual(gate, GATE_COLORS[rank_index], rank)
	modern_root.add_child(gate)
	gate.body_entered.connect(_on_gate_body_entered.bind(gate))


func _build_gate_visual(parent: Node3D, color: Color, rank: String) -> void:
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.09,0.12,0.17)
	frame_material.metallic = 0.72
	frame_material.roughness = 0.3
	var energy := StandardMaterial3D.new()
	energy.albedo_color = color
	energy.emission_enabled = true
	energy.emission = color
	energy.emission_energy_multiplier = 3.0
	energy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	energy.albedo_color.a = 0.82

	for side in [-1.0,1.0]:
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.28
		pillar_mesh.bottom_radius = 0.48
		pillar_mesh.height = 5.6
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(side * 2.0,2.8,0.0)
		pillar.material_override = frame_material
		parent.add_child(pillar)

	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(4.8,0.55,0.8)
	lintel.mesh = lintel_mesh
	lintel.position.y = 5.55
	lintel.material_override = frame_material
	parent.add_child(lintel)

	var rift := MeshInstance3D.new()
	var rift_mesh := SphereMesh.new()
	rift_mesh.radius = 1.65
	rift_mesh.height = 4.7
	rift.mesh = rift_mesh
	rift.scale = Vector3(1.0,1.0,0.22)
	rift.position = Vector3(0.0,2.8,0.18)
	rift.material_override = energy
	parent.add_child(rift)

	var label := Label3D.new()
	label.name = "GateRankLabel"
	label.text = "GATE  " + rank
	label.position = Vector3(0.0,6.5,0.0)
	label.font_size = 36
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	parent.add_child(label)


func _is_player(body: Node3D) -> bool:
	return body is CharacterBody3D and (
		body.name == "Player" or body.is_in_group("system_player")
	)


func _on_gate_body_entered(body: Node3D, gate: Area3D) -> void:
	if not _is_player(body) or active_dungeon != null:
		return
	if not is_instance_valid(gate) or str(gate.get_meta("system_gate_status","")) != "active":
		return
	active_player = body as CharacterBody3D
	return_position = gate.global_position + Vector3(0.0,1.5,5.0)
	gate.set_meta("system_gate_status","occupied")
	current_gate = gate
	_enter_dungeon(gate)


func _enter_dungeon(gate: Area3D) -> void:
	var rank := str(gate.get_meta("system_gate_rank","E"))
	active_gate_rank = rank
	active_dungeon = Node3D.new()
	active_dungeon.name = "MonsterGateDungeon_" + rank
	active_dungeon.position = Vector3(5000.0 + float(gate_counter) * 120.0, 100.0, 5000.0)
	modern_root.add_child(active_dungeon)
	_build_dungeon_rooms(active_dungeon, rank, active_player)
	if is_instance_valid(active_player):
		active_player.reparent(active_dungeon, true)
		active_player.velocity = Vector3.ZERO
		active_player.global_position = active_dungeon.global_position + Vector3(0.0,1.5,9.0)


func _build_dungeon_rooms(root: Node3D, rank: String, player: CharacterBody3D) -> void:
	var stone := _make_material(Color(0.16,0.18,0.22))
	var floor_material := _make_material(Color(0.09,0.11,0.14))
	var glow := _make_material(Color(0.25,0.42,0.58), true)
	_add_box(root,"DungeonEntryFloor",Vector3(0.0,-0.35,8.0),Vector3(22.0,0.7,24.0),floor_material)
	_add_box(root,"DungeonMiddleFloor",Vector3(0.0,-0.35,-12.0),Vector3(26.0,0.7,20.0),floor_material)
	_add_box(root,"DungeonBossFloor",Vector3(0.0,-0.35,-34.0),Vector3(34.0,0.7,24.0),floor_material)
	for side in [-1.0,1.0]:
		_add_box(root,"DungeonEntryWall",Vector3(side*11.0,3.0,8.0),Vector3(0.8,6.0,24.0),stone)
		_add_box(root,"DungeonMiddleWall",Vector3(side*13.0,3.0,-12.0),Vector3(0.8,6.0,20.0),stone)
		_add_box(root,"DungeonBossWall",Vector3(side*17.0,4.0,-34.0),Vector3(0.8,8.0,24.0),stone)
	_add_box(root,"DungeonEntryCeiling",Vector3(0.0,6.3,8.0),Vector3(22.0,0.6,24.0),stone)
	_add_box(root,"DungeonBossArch",Vector3(0.0,4.5,-23.0),Vector3(8.0,1.0,0.8),glow)
	enemies_remaining = 5
	boss_defeated = false
	dungeon_xp_awarded = 0
	for index in range(4):
		_create_enemy_marker(root,Vector3(-5.0 + float(index)*3.3,0.0,-8.0),rank,false,player)
	_create_enemy_marker(root,Vector3(0.0,0.0,-34.0),rank,true,player)
	_create_exit_gate(root)


func _create_enemy_marker(root: Node3D, location: Vector3, rank: String, boss: bool, player: CharacterBody3D) -> void:
	var enemy := GateEnemyScript.new() as CharacterBody3D
	enemy.name = "GateBoss" if boss else "GateMonster"
	enemy.position = location
	enemy.call("configure",rank,boss,player)
	enemy.connect("defeated",_on_gate_enemy_defeated)
	root.add_child(enemy)


func _on_gate_enemy_defeated(enemy: Node, is_boss: bool, xp_reward: int) -> void:
	enemies_remaining = maxi(enemies_remaining - 1,0)
	dungeon_xp_awarded += xp_reward
	var progression := get_tree().root.find_child("PlayerProgression",true,false)
	if progression != null and progression.has_method("add_experience"):
		progression.call("add_experience",xp_reward,"Monster Gate: " + str(enemy.name))
	if is_instance_valid(enemy):
		_create_loot_drop(enemy.global_position, is_boss, active_gate_rank, str(enemy.get_instance_id()))
	if is_boss:
		boss_defeated = true
	if enemies_remaining == 0 and boss_defeated:
		_unlock_dungeon_exit()


func _get_eligible_skill_drop_candidates(gate_rank: String, progression: Node) -> Array[String]:
	var candidates: Array[String] = []
	if not is_instance_valid(progression) or not progression.has_method("get_system_skill_tree") or not progression.has_method("check_skill_training_permit"):
		return candidates
	if not bool(progression.get("nen_unlocked")) or not progression.has_method("get_nen_foundation_status"):
		return candidates
	var nen_status: Dictionary = progression.call("get_nen_foundation_status")
	if not bool(nen_status.get("all_complete", false)) or str(nen_status.get("affinity", "")).is_empty():
		return candidates
	var rank_order := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"]
	var source_rank := "SSS" if gate_rank == "EX" else gate_rank
	var source_index := rank_order.find(source_rank)
	if source_index < 0:
		return candidates
	var tree: Dictionary = progression.call("get_system_skill_tree")
	for skill_value in tree.keys():
		var skill_id := str(skill_value)
		var skill: Dictionary = tree[skill_id]
		if not bool(skill.get("requires_nen", false)) or not bool(skill.get("requires_training_permit", false)):
			continue
		var required_index := rank_order.find(str(skill.get("required_rank", "F")))
		if required_index < 0 or source_index < required_index:
			continue
		var eligibility: Dictionary = progression.call("check_skill_training_permit", skill_id)
		if bool(eligibility.get("success", false)):
			candidates.append(skill_id)
	return candidates


func _roll_skill_training_drop(gate_rank: String, boss: bool, progression: Node) -> String:
	var candidates := _get_eligible_skill_drop_candidates(gate_rank, progression)
	if candidates.is_empty():
		return ""
	var drop_chance := 0.10 if not boss else 0.38
	if boss and gate_rank in ["S", "SS", "SSS", "EX"]:
		drop_chance = 0.55
	if rng.randf() > drop_chance:
		return ""
	if boss:
		var rare_candidates: Array[String] = []
		var tree: Dictionary = progression.call("get_system_skill_tree")
		for candidate in candidates:
			var category := str(tree[candidate].get("category", ""))
			if category in ["rare_elemental", "rare_shadow", "rare_body", "legendary_elemental", "legendary_shadow"]:
				rare_candidates.append(candidate)
		if not rare_candidates.is_empty() and rng.randf() < 0.8:
			candidates = rare_candidates
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _create_loot_drop(location: Vector3, boss: bool, gate_rank: String, enemy_token: String) -> void:
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	var skill_id := _roll_skill_training_drop(gate_rank, boss, progression)
	var is_skill_drop := not skill_id.is_empty()
	var pickup := Area3D.new()
	pickup.name = "GateLoot_SkillPermit_" + skill_id if is_skill_drop else ("GateLoot_BossRelic" if boss else "GateLoot_MonsterCore")
	pickup.add_to_group("system_gate_loot")
	pickup.set_meta("system_loot_type", "skill_training_permit" if is_skill_drop else ("boss_relic" if boss else "monster_core"))
	var quality := "common"
	if boss or is_skill_drop:
		quality = "rare"
	if is_skill_drop:
		var skill_tree_for_quality: Dictionary = progression.call("get_system_skill_tree")
		if str(skill_tree_for_quality[skill_id].get("category", "")).begins_with("legendary"):
			quality = "legendary"
	pickup.set_meta("system_loot_quality", quality)
	pickup.set_meta("system_gate_rank", gate_rank)
	if is_skill_drop:
		pickup.set_meta("system_skill_id", skill_id)
		var gate_id := str(current_gate.get_meta("system_gate_id", "monster_gate")) if is_instance_valid(current_gate) else "monster_gate"
		pickup.set_meta("system_drop_id", "%s_%s_%s_%d_%d" % [gate_id, enemy_token, skill_id, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()])
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.38 if is_skill_drop else (0.32 if boss else 0.2)
	mesh.height = mesh.radius * 2.0
	visual.mesh = mesh
	var loot_color := Color(0.82, 0.2, 0.92) if is_skill_drop else (Color(1.0, 0.62, 0.12) if boss else Color(0.22, 0.78, 0.92))
	visual.material_override = _make_material(loot_color, true)
	pickup.add_child(visual)
	if is_skill_drop:
		var skill_tree: Dictionary = progression.call("get_system_skill_tree")
		var skill_label := Label3D.new()
		skill_label.name = "SkillPermitDropLabel"
		skill_label.text = "مخطوطة: " + str(skill_tree[skill_id].get("name", skill_id))
		skill_label.position.y = 0.75
		skill_label.font_size = 24
		skill_label.pixel_size = 0.008
		skill_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pickup.add_child(skill_label)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.25
	collision.shape = sphere
	pickup.add_child(collision)
	active_dungeon.add_child(pickup)
	pickup.global_position = location + Vector3(0.0, 0.8, 0.0)
	pickup.body_entered.connect(_on_loot_collected.bind(pickup))


func _on_loot_collected(body: Node3D, pickup: Area3D) -> void:
	if not _is_player(body) or not is_instance_valid(pickup):
		return
	var loot_type := str(pickup.get_meta("system_loot_type", ""))
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if loot_type == "skill_training_permit":
		if progression == null or not progression.has_method("grant_skill_training_permit_from_drop"):
			print("SYSTEM LOOT: Nen skill permit could not be claimed; progression API unavailable.")
			return
		var drop_result: Dictionary = progression.call("grant_skill_training_permit_from_drop", str(pickup.get_meta("system_skill_id", "")), str(pickup.get_meta("system_drop_id", "")), str(pickup.get_meta("system_gate_rank", "F")))
		if not bool(drop_result.get("success", false)):
			print("SYSTEM LOOT: Skill permit not claimed: ", str(drop_result.get("reason", "UNKNOWN")))
			return
		print("SYSTEM LOOT: Monster gate granted training permit for ", str(drop_result.get("skill_id", "")))
	elif progression != null and progression.has_method("add_item"):
		progression.call("add_item", loot_type, 1)
	else:
		print("SYSTEM LOOT: Player progression inventory is unavailable.")
	pickup.queue_free()


	var pickup := Area3D.new()
	pickup.name = "GateLoot_BossRelic" if boss else "GateLoot_MonsterCore"
	pickup.add_to_group("system_gate_loot")
	pickup.set_meta("system_loot_type","boss_relic" if boss else "monster_core")
	pickup.set_meta("system_loot_quality","rare" if boss else "common")
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.32 if boss else 0.2
	mesh.height = 0.64 if boss else 0.4
	visual.mesh = mesh
	visual.material_override = _make_material(Color(1.0,0.62,0.12) if boss else Color(0.22,0.78,0.92),true)
	pickup.add_child(visual)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.25
	collision.shape = sphere
	pickup.add_child(collision)
	active_dungeon.add_child(pickup)
	pickup.global_position = location + Vector3(0.0,0.8,0.0)
	pickup.body_entered.connect(_on_loot_collected.bind(pickup))


func _on_loot_collected(body: Node3D, pickup: Area3D) -> void:
	if not _is_player(body) or not is_instance_valid(pickup):
		return
	var loot_type := str(pickup.get_meta("system_loot_type",""))
	var progression := get_tree().root.find_child("PlayerProgression",true,false)
	if progression != null and progression.has_method("add_item"):
		progression.call("add_item",loot_type,1)
	else:
		print("SYSTEM LOOT: Player progression inventory is unavailable.")
	pickup.queue_free()

func _create_exit_gate(root: Node3D) -> void:
	var exit_area := Area3D.new()
	exit_area.name = "DungeonReturnGate"
	exit_area.monitoring = false
	dungeon_exit = exit_area
	exit_area.position = Vector3(0.0,1.0,17.0)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.8
	collision.shape = sphere
	exit_area.add_child(collision)
	root.add_child(exit_area)
	exit_area.body_entered.connect(_on_dungeon_exit_entered)


func _unlock_dungeon_exit() -> void:
	if is_instance_valid(dungeon_exit):
		dungeon_exit.monitoring = true
		var label := Label3D.new()
		label.text = "DUNGEON CLEARED — EXIT OPEN"
		label.position = Vector3(0.0,3.2,17.0)
		label.font_size = 30
		label.modulate = Color(0.3,1.0,0.65)
		dungeon_exit.add_child(label)
	if is_instance_valid(current_gate):
		current_gate.set_meta("system_gate_status","cleared")
		current_gate.set_meta("system_gate_cleared",true)
		var public_board := get_tree().root.find_child("SYSTEMPublicEventBoard", true, false)
		if public_board != null and public_board.has_method("publish_gate_clear"):
			public_board.call(
				"publish_gate_clear",
				str(current_gate.get_meta("system_gate_id", current_gate.name)),
				str(current_gate.get_meta("system_gate_rank", "UNKNOWN")),
				dungeon_xp_awarded
			)
		current_gate.monitoring = false
		current_gate.visible = false
		current_gate.queue_free()
	print("SYSTEM GATE: Dungeon cleared. XP awarded: ",dungeon_xp_awarded)


func _on_dungeon_exit_entered(body: Node3D) -> void:
	if not _is_player(body) or active_dungeon == null:
		return
	var player := body as CharacterBody3D
	player.reparent(modern_root, true)
	player.velocity = Vector3.ZERO
	player.global_position = return_position
	active_dungeon.queue_free()
	active_dungeon = null
	active_player = null
	current_gate = null
	dungeon_exit = null
	enemies_remaining = 0
	boss_defeated = false


func _add_box(root: Node3D, node_name: String, location: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = location
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)


func _make_material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.8
	return material
