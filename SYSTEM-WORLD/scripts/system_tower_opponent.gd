extends CharacterBody3D
class_name SYSTEMTowerOpponent

signal defeated(opponent: Node)

var target_player: CharacterBody3D
var player_health: Node
var maximum_health := 120.0
var current_health := 120.0
var attack_damage := 8.0
var movement_speed := 2.4
var attack_distance := 1.8
var attack_cooldown := 1.35
var attack_clock := 0.0
var is_boss := false
var is_final_boss := false
var special_attack_clock := 3.0
var defeated_once := false

func configure(player: CharacterBody3D, health_manager: Node, health_value: float, damage_value: float, speed_value: float, boss: bool = false, final_boss: bool = false) -> void:
	target_player = player
	player_health = health_manager
	maximum_health = maxf(1.0, health_value)
	current_health = maximum_health
	attack_damage = maxf(1.0, damage_value)
	movement_speed = maxf(0.5, speed_value)
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
	var visual := MeshInstance3D.new()
	visual.name = "OpponentVisual"
	var mesh := CapsuleMesh.new()
	mesh.radius = capsule.radius
	mesh.height = capsule.height
	visual.mesh = mesh
	visual.position.y = capsule.height * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.48, 0.12, 0.10) if not is_boss else (Color(0.68, 0.43, 0.08) if is_final_boss else Color(0.22, 0.035, 0.035))
	material.metallic = 0.28
	material.roughness = 0.62
	material.emission_enabled = true
	material.emission = Color(0.65, 0.08, 0.035) if not is_boss else (Color(1.0, 0.58, 0.08) if is_final_boss else Color(0.95, 0.16, 0.025))
	material.emission_energy_multiplier = 0.7 if not is_boss else (2.6 if is_final_boss else 1.6)
	visual.material_override = material
	add_child(visual)
	var health_label := Label3D.new()
	health_label.name = "OpponentHealth"
	health_label.text = "SYSTEM FINAL BOSS" if is_final_boss else ("BOSS" if is_boss else "ENEMY")
	health_label.position.y = capsule.height + 0.55
	health_label.font_size = 24 if not is_boss else 34
	health_label.modulate = Color(1.0, 0.72, 0.55)
	add_child(health_label)
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
	if is_boss and special_attack_clock <= 0.0 and distance < (15.0 if is_final_boss else 10.0):
		if is_instance_valid(player_health) and player_health.has_method("receive_damage"):
			player_health.call("receive_damage", attack_damage * (1.15 if is_final_boss else 1.35), self)
		special_attack_clock = 3.5 if is_final_boss else 5.0
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

func take_damage(amount: float, _source: Node = null) -> void:
	if defeated_once or amount <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	set_meta("system_opponent_health", current_health)
	var label := get_node_or_null("OpponentHealth") as Label3D
	if label != null:
		label.text = ("FINAL BOSS " if is_final_boss else ("BOSS " if is_boss else "ENEMY ")) + str(int(ceil(current_health)))
	if current_health <= 0.0:
		defeated_once = true
		defeated.emit(self)
		queue_free()

func get_health_ratio() -> float:
	return current_health / maxf(1.0, maximum_health)
