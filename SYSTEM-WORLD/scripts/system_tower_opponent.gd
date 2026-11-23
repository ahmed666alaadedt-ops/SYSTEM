extends CharacterBody3D
class_name SYSTEMTowerOpponent

signal defeated(opponent: Node)

var target_player: CharacterBody3D
var player_health: Node
var maximum_health := 120.0
var current_health := 120.0
var attack_damage := 8.0
var movement_speed := 2.4
var base_movement_speed := 2.4
var base_attack_damage := 8.0
var base_attack_cooldown := 1.35
var attack_distance := 1.8
var attack_cooldown := 1.35
var attack_clock := 0.0
var is_boss := false
var is_final_boss := false
var special_attack_clock := 3.0
var special_attack_windup_clock := 0.0
var boss_phase := 1
var health_label: Label3D
var attack_telegraph_label: Label3D
var boss_visual: MeshInstance3D
var shockwave_telegraph: MeshInstance3D
var shockwave_material: StandardMaterial3D
var defeated_once := false

func configure(player: CharacterBody3D, health_manager: Node, health_value: float, damage_value: float, speed_value: float, boss: bool = false, final_boss: bool = false) -> void:
	target_player = player
	player_health = health_manager
	maximum_health = maxf(1.0, health_value)
	current_health = maximum_health
	attack_damage = maxf(1.0, damage_value)
	base_attack_damage = attack_damage
	movement_speed = maxf(0.5, speed_value)
	base_movement_speed = movement_speed
	base_attack_cooldown = attack_cooldown
	is_boss = boss
	is_final_boss = final_boss

func _ready() -> void:
	name = "PowerTowerOpponent"
	add_to_group("system_power_tower_opponent")
	collision_layer = 1
	collision_mask = 1
	var body_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.72 if not is_boss else (1.55 if is_final_boss else 1.25)
	capsule.height = 2.1 if not is_boss else (4.8 if is_final_boss else 3.6)
	body_shape.shape = capsule
	body_shape.position.y = capsule.height * 0.5
	add_child(body_shape)
	boss_visual = MeshInstance3D.new()
	boss_visual.name = "OpponentVisual"
	var mesh := CapsuleMesh.new()
	mesh.radius = capsule.radius
	mesh.height = capsule.height
	boss_visual.mesh = mesh
	boss_visual.position.y = capsule.height * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.48, 0.12, 0.10) if not is_boss else (Color(0.68, 0.43, 0.08) if is_final_boss else Color(0.22, 0.035, 0.035))
	material.metallic = 0.28
	material.roughness = 0.62
	material.emission_enabled = true
	material.emission = Color(0.65, 0.08, 0.035) if not is_boss else (Color(1.0, 0.58, 0.08) if is_final_boss else Color(0.95, 0.16, 0.025))
	material.emission_energy_multiplier = 0.7 if not is_boss else (2.6 if is_final_boss else 1.6)
	boss_visual.material_override = material
	add_child(boss_visual)
	health_label = Label3D.new()
	health_label.name = "OpponentHealth"
	health_label.position.y = capsule.height + 0.55
	health_label.font_size = 24 if not is_boss else 34
	health_label.modulate = Color(1.0, 0.72, 0.55)
	add_child(health_label)
	if is_boss:
		attack_telegraph_label = Label3D.new()
		attack_telegraph_label.name = "ShockwaveTelegraphLabel"
		attack_telegraph_label.position.y = capsule.height + 1.45
		attack_telegraph_label.font_size = 25 if is_final_boss else 20
		attack_telegraph_label.modulate = Color(1.0, 0.38, 0.18)
		attack_telegraph_label.text = "MOVE — SHOCKWAVE"
		attack_telegraph_label.visible = false
		add_child(attack_telegraph_label)
		shockwave_telegraph = MeshInstance3D.new()
		shockwave_telegraph.name = "ShockwaveTelegraph"
		var ring := TorusMesh.new()
		ring.inner_radius = 3.7 if not is_final_boss else 4.8
		ring.outer_radius = 4.1 if not is_final_boss else 5.2
		shockwave_telegraph.mesh = ring
		shockwave_telegraph.rotation.x = deg_to_rad(90.0)
		shockwave_telegraph.position.y = 0.12
		shockwave_telegraph.visible = false
		shockwave_material = StandardMaterial3D.new()
		shockwave_material.albedo_color = Color(1.0, 0.24, 0.08, 0.58)
		shockwave_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shockwave_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shockwave_material.emission_enabled = true
		shockwave_material.emission = Color(1.0, 0.12, 0.025)
		shockwave_material.emission_energy_multiplier = 2.2
		shockwave_telegraph.material_override = shockwave_material
		add_child(shockwave_telegraph)
	_update_health_label()
	set_meta("system_power_tower_opponent", true)
	set_meta("system_opponent_health", current_health)

func _physics_process(delta: float) -> void:
	if defeated_once or not is_instance_valid(target_player):
		return
	attack_clock = maxf(0.0, attack_clock - delta)
	special_attack_clock = maxf(0.0, special_attack_clock - delta)
	var offset := target_player.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if is_final_boss:
		var health_ratio := get_health_ratio()
		if health_ratio <= 0.5 and boss_phase == 1:
			_set_boss_phase(2)
		elif health_ratio <= 0.2 and boss_phase == 2:
			_set_boss_phase(3)
	if is_boss:
		if special_attack_windup_clock > 0.0:
			special_attack_windup_clock = maxf(0.0, special_attack_windup_clock - delta)
			_update_shockwave_telegraph()
			if special_attack_windup_clock <= 0.0:
				if distance < (15.0 if is_final_boss else 10.0) and is_instance_valid(player_health) and player_health.has_method("receive_damage"):
					player_health.call("receive_damage", attack_damage * (1.15 if is_final_boss else 1.35), self)
				_set_shockwave_telegraph(false)
				special_attack_clock = 2.8 if is_final_boss and boss_phase == 3 else (3.5 if is_final_boss else 5.0)
				_update_health_label()
		elif special_attack_clock <= 0.0 and distance < (15.0 if is_final_boss else 10.0):
			special_attack_windup_clock = 1.0 if is_final_boss else 0.75
			_set_shockwave_telegraph(true)
			_update_shockwave_telegraph()
	if distance > attack_distance:
		var direction := offset.normalized()
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, movement_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, movement_speed * 4.0 * delta)
		if attack_clock <= 0.0 and is_instance_valid(player_health) and player_health.has_method("receive_damage"):
			player_health.call("receive_damage", attack_damage, self)
			attack_clock = attack_cooldown
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _set_boss_phase(next_phase: int) -> void:
	boss_phase = clampi(next_phase, 1, 3)
	movement_speed = base_movement_speed * (1.0 if boss_phase == 1 else (1.2 if boss_phase == 2 else 1.45))
	attack_damage = base_attack_damage * (1.0 if boss_phase == 1 else (1.1 if boss_phase == 2 else 1.25))
	attack_cooldown = base_attack_cooldown * (1.0 if boss_phase == 1 else (0.9 if boss_phase == 2 else 0.75))
	if boss_visual != null and boss_visual.material_override is StandardMaterial3D:
		var material := boss_visual.material_override as StandardMaterial3D
		material.emission = Color(1.0, 0.58, 0.08) if boss_phase == 1 else (Color(1.0, 0.28, 0.035) if boss_phase == 2 else Color(0.72, 0.08, 0.025))
		material.emission_energy_multiplier = 2.6 + float(boss_phase - 1) * 0.8
	if shockwave_telegraph != null and shockwave_telegraph.mesh is TorusMesh:
		var ring := shockwave_telegraph.mesh as TorusMesh
		var radius := 4.8 + float(boss_phase - 1) * 0.7
		ring.inner_radius = radius
		ring.outer_radius = radius + 0.4
	_update_health_label()

func _set_shockwave_telegraph(active: bool) -> void:
	if shockwave_telegraph != null:
		shockwave_telegraph.visible = active
	if attack_telegraph_label != null:
		attack_telegraph_label.visible = active
	if not active:
		special_attack_windup_clock = 0.0

func _update_shockwave_telegraph() -> void:
	if not is_instance_valid(shockwave_telegraph) or not shockwave_telegraph.visible:
		return
	var duration := 1.0 if is_final_boss else 0.75
	var remaining_ratio := clampf(special_attack_windup_clock / duration, 0.0, 1.0)
	var pulse := 1.0 + (1.0 - remaining_ratio) * 0.22
	shockwave_telegraph.scale = Vector3.ONE * pulse
	if shockwave_material != null:
		shockwave_material.emission_energy_multiplier = 1.8 + (1.0 - remaining_ratio) * 3.0
	if attack_telegraph_label != null:
		attack_telegraph_label.text = "SHOCKWAVE IN %.1f — EVADE!" % special_attack_windup_clock

func _update_health_label() -> void:
	if health_label == null:
		return
	var prefix := "FINAL BOSS" if is_final_boss else ("BOSS" if is_boss else "ENEMY")
	if is_final_boss:
		prefix += " — PHASE " + str(boss_phase)
	health_label.text = prefix + " " + str(int(ceil(current_health)))

func take_damage(amount: float, _source: Node = null) -> void:
	if defeated_once or amount <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	set_meta("system_opponent_health", current_health)
	_update_health_label()
	if current_health <= 0.0:
		defeated_once = true
		_set_shockwave_telegraph(false)
		defeated.emit(self)
		queue_free()

func get_health_ratio() -> float:
	return current_health / maxf(1.0, maximum_health)
