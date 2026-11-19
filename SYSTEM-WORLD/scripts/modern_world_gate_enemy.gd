extends "res://scripts/system_combatant.gd"
class_name ModernWorldGateEnemy

signal defeated(enemy: Node, is_boss: bool, xp_reward: int)

@export var gate_rank := "E"
@export var is_boss := false
@export var move_speed := 2.8
@export var attack_damage := 8.0
@export var attack_interval := 1.8
@export var xp_reward := 35

var target: CharacterBody3D
var attack_timer := 0.0
var attack_range := 2.2
var defeated_emitted := false


func _ready() -> void:
	maximum_health = _health_for_rank(gate_rank, is_boss)
	capsule_radius = 1.15 if is_boss else 0.72
	capsule_height = 3.4 if is_boss else 2.2
	show_placeholder_visual = false
	super._ready()
	if is_instance_valid(body_collision):
		body_collision.position.y = capsule_height * 0.5
	add_to_group("system_enemy")
	set_physics_process(true)
	_create_gate_enemy_visual()


func configure(rank: String, boss: bool, player: CharacterBody3D) -> void:
	gate_rank = rank
	is_boss = boss
	target = player
	maximum_health = _health_for_rank(rank, boss)
	attack_damage = _damage_for_rank(rank, boss)
	xp_reward = _xp_for_rank(rank, boss)


func _health_for_rank(rank: String, boss: bool) -> float:
	var base := {"F":100.0,"E":180.0,"D":260.0,"C":420.0,"B":680.0,"A":1050.0,"S":1800.0,"SS":2800.0,"SSS":4300.0,"EX":6500.0}
	return float(base.get(rank,180.0)) * (4.0 if boss else 1.0)


func _damage_for_rank(rank: String, boss: bool) -> float:
	var base := {"F":4.0,"E":7.0,"D":10.0,"C":15.0,"B":22.0,"A":32.0,"S":48.0,"SS":65.0,"SSS":82.0,"EX":110.0}
	return float(base.get(rank,7.0)) * (1.8 if boss else 1.0)


func _xp_for_rank(rank: String, boss: bool) -> int:
	var base := {"F":12,"E":25,"D":45,"C":80,"B":130,"A":210,"S":350,"SS":520,"SSS":800,"EX":1200}
	return int(base.get(rank,25)) * (5 if boss else 1)


func _create_gate_enemy_visual() -> void:
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := CapsuleMesh.new()
	mesh.radius = capsule_radius
	mesh.height = capsule_height
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.48,0.055,0.10) if is_boss else Color(0.22,0.13,0.16)
	material.metallic = 0.18
	material.roughness = 0.7
	material.emission_enabled = true
	material.emission = Color(0.18,0.015,0.025) if is_boss else Color(0.06,0.015,0.02)
	material.emission_energy_multiplier = 0.8
	visual.material_override = material
	visual.position.y = capsule_height * 0.5
	add_child(visual)
	if is_boss:
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 0.55
		crown_mesh.height = 0.8
		crown.mesh = crown_mesh
		crown.position = Vector3(0.0,capsule_height + 0.15,0.0)
		crown.material_override = material
		add_child(crown)


func _physics_process(delta: float) -> void:
	if not is_alive or not is_instance_valid(target):
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > attack_range:
		velocity.x = offset.normalized().x * move_speed
		velocity.z = offset.normalized().z * move_speed
		if distance > 1.6:
			look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z),Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x,0.0,move_speed)
		velocity.z = move_toward(velocity.z,0.0,move_speed)
		if attack_timer <= 0.0:
			_attack_target()
			attack_timer = attack_interval
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _attack_target() -> void:
	if not is_instance_valid(target):
		return
	var health_component := target.get_node_or_null("PlayerCombatHealth")
	if health_component != null and health_component.has_method("receive_damage"):
		health_component.call("receive_damage",attack_damage,self)
	elif target.has_method("take_damage"):
		target.call("take_damage",attack_damage,self)
	elif target.has_method("receive_damage"):
		target.call("receive_damage",attack_damage)
	else:
		target.set_meta("system_last_gate_attack",{"damage":attack_damage,"rank":gate_rank})
		push_warning("SYSTEM GATE: Player health component is unavailable.")


func die(source: Node = null) -> void:
	if not is_alive:
		return
	super.die(source)
	if not defeated_emitted:
		defeated_emitted = true
		defeated.emit(self,is_boss,xp_reward)
		queue_free()
