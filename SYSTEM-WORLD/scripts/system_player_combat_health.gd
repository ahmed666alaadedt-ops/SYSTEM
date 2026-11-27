extends Node
class_name SYSTEMPlayerCombatHealth

signal health_changed(current_health: float, maximum_health: float)
signal player_wounded

const MAX_HEALTH := 100.0
const INCAPACITATED_RECOVERY_HEALTH := 30.0

var player: CharacterBody3D
var current_health := MAX_HEALTH
var is_wounded := false
var is_treating := false


func bind_player(actor: CharacterBody3D) -> void:
	player = actor
	_sync_player_state()


func receive_damage(amount: float, source: Node = null) -> float:
	if amount <= 0.0 or not is_instance_valid(player):
		return 0.0
	var incoming := amount
	var water_shield_until := int(player.get_meta("system_tideheart_shield_until_msec", 0))
	if water_shield_until > Time.get_ticks_msec():
		incoming *= 1.0 - clampf(float(player.get_meta("system_tideheart_shield_reduction", 0.0)), 0.0, 0.15)
	elif water_shield_until > 0:
		player.remove_meta("system_tideheart_shield_until_msec")
		player.remove_meta("system_tideheart_shield_reduction")
	var earthguard_until := int(player.get_meta("system_earthguard_until_msec", 0))
	if earthguard_until > Time.get_ticks_msec():
		incoming *= 1.0 - clampf(float(player.get_meta("system_earthguard_reduction", 0.0)), 0.0, 0.30)
	elif earthguard_until > 0:
		player.remove_meta("system_earthguard_until_msec")
		player.remove_meta("system_earthguard_reduction")
	var aegis_until := int(player.get_meta("system_assyrian_aegis_until_msec", 0))
	if aegis_until > Time.get_ticks_msec():
		incoming *= 0.35
	elif aegis_until > 0:
		player.remove_meta("system_assyrian_aegis_until_msec")
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if progression != null and progression.has_method("get_defense_bonus"):
		var defense_bonus := float(progression.call("get_defense_bonus"))
		incoming = maxf(1.0, incoming - minf(defense_bonus, incoming * 0.65))
	var combat := get_tree().root.find_child("ModernWorldCombatSystem",true,false)
	var is_blocking := combat != null and bool(combat.get("is_blocking"))
	if progression != null and progression.has_method("consume_equipment_durability"):
		if is_blocking:
			progression.call("consume_equipment_durability", "shield", 0.8)
		else:
			progression.call("consume_equipment_durability", "armor", 0.55)
			progression.call("consume_equipment_durability", "helmet", 0.2)
	if is_blocking:
		incoming *= 0.25
	current_health = maxf(current_health - incoming,0.0)
	_sync_player_state()
	health_changed.emit(current_health,MAX_HEALTH)
	if current_health <= 0.0:
		_enter_wounded_state(source)
	return incoming


func _enter_wounded_state(source: Node) -> void:
	is_wounded = true
	current_health = INCAPACITATED_RECOVERY_HEALTH
	_sync_player_state()
	player.velocity = Vector3.ZERO
	player.global_position += Vector3(0.0,0.0,3.0)
	player_wounded.emit()
	push_warning("SYSTEM: Player is wounded after a monster-gate defeat. Visit a hospital for full treatment.")
	health_changed.emit(current_health,MAX_HEALTH)


func apply_field_healing(amount: float) -> bool:
	if amount <= 0.0 or not is_instance_valid(player) or current_health >= MAX_HEALTH:
		return false
	current_health = minf(current_health + amount, MAX_HEALTH)
	# Field healing restores combat health but deliberately does not clear a
	# persistent wound state; full recovery still requires hospital treatment.
	_sync_player_state()
	health_changed.emit(current_health, MAX_HEALTH)
	return true


func begin_hospital_treatment() -> bool:
	if is_treating or not is_instance_valid(player) or current_health >= MAX_HEALTH:
		return false
	is_treating = true
	var missing_health := MAX_HEALTH - current_health
	var treatment_seconds := clampf(missing_health * 0.22, 5.0, 22.0)
	player.set_meta("system_hospital_treatment", true)
	player.velocity = Vector3.ZERO
	_complete_hospital_treatment(treatment_seconds)
	return true


func _complete_hospital_treatment(duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(player):
		is_treating = false
		return
	heal_at_hospital(MAX_HEALTH)
	player.set_meta("system_hospital_treatment", false)
	is_treating = false


func heal_at_hospital(amount: float = MAX_HEALTH) -> bool:
	if amount <= 0.0 or not is_instance_valid(player):
		return false
	current_health = minf(current_health + amount,MAX_HEALTH)
	if current_health >= MAX_HEALTH:
		is_wounded = false
	_sync_player_state()
	health_changed.emit(current_health,MAX_HEALTH)
	return true


func get_health_data() -> Dictionary:
	return {
		"current_health":current_health,
		"maximum_health":MAX_HEALTH,
		"is_wounded":is_wounded
	}


func _sync_player_state() -> void:
	if not is_instance_valid(player):
		return
	player.set_meta("system_current_health",current_health)
	player.set_meta("system_maximum_health",MAX_HEALTH)
	player.set_meta("system_wounded",is_wounded)
