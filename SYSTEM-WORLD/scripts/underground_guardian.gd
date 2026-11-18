extends CharacterBody3D
class_name UndergroundGuardian

signal player_detected(player: Node3D)
signal attack_requested(player: Node3D, damage_amount: float)

enum GuardianState { GUARDING, PURSUING, ATTACKING, RETURNING }

@export var move_speed: float = 2.8
@export var detection_range: float = 12.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.8
@export var patrol_distance: float = 4.0
@export var max_health: float = 140.0
@export var defeat_xp_reward: int = 120

var current_health: float = 140.0
var _defeated := false
var state: GuardianState = GuardianState.GUARDING
var _home_position: Vector3
var _target: Node3D
var _attack_timer: float = 0.0
var _patrol_direction: float = 1.0
var _patrol_elapsed: float = 0.0


func _ready() -> void:
	_home_position = global_position
	current_health = max_health


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _target != null and not is_instance_valid(_target):
		_target = null

	if _target != null:
		_update_combat_state(delta)
	else:
		_update_patrol(delta)

	velocity.y -= 18.0 * delta
	move_and_slide()


func set_target(player: Node3D) -> void:
	if player == null or player.name != "Player":
		return
	_target = player
	state = GuardianState.PURSUING
	player_detected.emit(player)
	print("SYSTEM underground guardian detected the player.")


func clear_target(player: Node3D) -> void:
	if _target == player:
		_target = null
		state = GuardianState.RETURNING


func _update_combat_state(delta: float) -> void:
	var distance := global_position.distance_to(_target.global_position)
	var flat_direction := _target.global_position - global_position
	flat_direction.y = 0.0

	if distance <= attack_range:
		state = GuardianState.ATTACKING
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			attack_requested.emit(_target, attack_damage)
			print("SYSTEM underground guardian attack event emitted.")
	else:
		state = GuardianState.PURSUING
		var direction := flat_direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		if direction.length_squared() > 0.01:
			look_at(global_position + direction, Vector3.UP)


func _update_patrol(delta: float) -> void:
	_patrol_elapsed += delta
	if state == GuardianState.RETURNING:
		var to_home := _home_position - global_position
		to_home.y = 0.0
		if to_home.length() > 0.5:
			var direction := to_home.normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			look_at(global_position + direction, Vector3.UP)
			return
		state = GuardianState.GUARDING
		_patrol_elapsed = 0.0

	if _patrol_elapsed >= 2.5:
		_patrol_elapsed = 0.0
		_patrol_direction *= -1.0

	var patrol_target := _home_position + Vector3(_patrol_direction * patrol_distance, 0.0, 0.0)
	var patrol_delta := patrol_target - global_position
	patrol_delta.y = 0.0
	if patrol_delta.length() > 0.35:
		var direction := patrol_delta.normalized()
		velocity.x = direction.x * move_speed * 0.55
		velocity.z = direction.z * move_speed * 0.55
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)



func take_damage(amount: float, source: Node = null) -> void:
	if _defeated or amount <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	print("SYSTEM underground guardian health: ", current_health, "/", max_health)
	if current_health <= 0.0:
		_defeat_guardian()


func _defeat_guardian() -> void:
	if _defeated:
		return
	_defeated = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true
	hide()
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if progression != null and progression.has_method("add_experience"):
		progression.call("add_experience", defeat_xp_reward, "Defeated ancient vault guardian")
	print("SYSTEM underground guardian defeated. XP reward: ", defeat_xp_reward)
