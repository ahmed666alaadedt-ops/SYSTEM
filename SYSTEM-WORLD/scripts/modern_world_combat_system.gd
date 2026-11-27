extends Node
class_name ModernWorldCombatSystem

signal attack_performed(damage: float, hit_target: Node)

var actor: CharacterBody3D
var camera: Camera3D
var progression: Node
var can_attack := true
var is_blocking := false
var attack_damage := 34.0
var heavy_damage := 90.0
var attack_range := 65.0


func bind_actor(player: CharacterBody3D, combat_camera: Camera3D, player_progression: Node = null) -> void:
	actor = player
	camera = combat_camera
	progression = player_progression


func set_combat_camera(combat_camera: Camera3D) -> void:
	camera = combat_camera


func light_attack() -> void:
	if not can_attack or not is_instance_valid(actor):
		return
	can_attack = false
	_consume_weapon_durability(0.35)
	_fire_hitscan(attack_damage + _get_progression_damage_bonus(),attack_range)
	await get_tree().create_timer(0.38 * _get_attack_cooldown_multiplier()).timeout
	can_attack = true


func heavy_attack() -> void:
	if not can_attack or not is_instance_valid(actor):
		return
	can_attack = false
	_consume_weapon_durability(0.75)
	_fire_hitscan(heavy_damage + _get_progression_damage_bonus(),attack_range * 1.35)
	await get_tree().create_timer(1.1 * _get_attack_cooldown_multiplier()).timeout
	can_attack = true


func skill_one() -> Dictionary:
	if not can_attack or not is_instance_valid(actor):
		return {"success": false, "reason": "COMBAT_BUSY"}
	var progression := _get_progression()
	if progression == null or not progression.has_method("activate_nen_burst"):
		return {"success": false, "reason": "NEN_SYSTEM_UNAVAILABLE"}
	var activation: Dictionary = progression.call("activate_nen_burst")
	if not bool(activation.get("success", false)):
		return activation
	if progression.has_method("record_nen_skill_use"):
		progression.call("record_nen_skill_use", "nen_burst")
	can_attack = false
	_consume_weapon_durability(0.75)
	_fire_hitscan(heavy_damage + _get_progression_damage_bonus(), attack_range * 1.35)
	get_tree().create_timer(0.75).timeout.connect(func(): can_attack = true)
	return activation


func use_relic_skill(skill_id: String) -> Dictionary:
	if not can_attack or not is_instance_valid(actor):
		return {"success": false, "reason": "COMBAT_BUSY"}
	var player_progression := _get_progression()
	if player_progression == null:
		return {"success": false, "reason": "PROGRESSION_UNAVAILABLE"}
	var availability: Dictionary = player_progression.call("can_use_system_skill", skill_id)
	if not bool(availability.get("success", false)):
		return availability
	var activation: Dictionary
	if skill_id == "rare_skill_celestial_lightning":
		activation = player_progression.call("record_system_skill_use", skill_id)
	else:
		activation = player_progression.call("activate_relic_skill_effect", skill_id)
	if not bool(activation.get("success", false)):
		return activation
	can_attack = false
	match skill_id:
		"rare_skill_celestial_lightning":
			_consume_weapon_durability(0.2)
			_fire_hitscan(245.0 + _get_progression_damage_bonus(), attack_range * 1.8)
			_spawn_relic_skill_flash(actor.global_position + Vector3.UP * 1.4, Color(0.35, 0.8, 1.0))
		"rare_skill_earth_guardian":
			_spawn_relic_skill_flash(actor.global_position, Color(0.35, 0.8, 0.35))
		"rare_skill_shadow_avatar":
			_spawn_shadow_avatar()
	get_tree().create_timer(0.65).timeout.connect(func(): can_attack = true)
	return {"success": true, "skill_id": skill_id, "activation": activation}


func _spawn_shadow_avatar() -> void:
	if not is_instance_valid(actor):
		return
	var avatar := MeshInstance3D.new()
	avatar.name = "RareShadowAvatar"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.85
	avatar.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.035, 0.025, 0.08, 0.78)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.18, 0.08, 0.42)
	material.emission_energy_multiplier = 1.6
	avatar.material_override = material
	get_tree().current_scene.add_child(avatar)
	avatar.global_position = actor.global_position - actor.global_transform.basis.z * 1.8
	avatar.global_rotation = actor.global_rotation
	get_tree().create_timer(10.0).timeout.connect(func():
		if is_instance_valid(avatar):
			avatar.queue_free()
	)


func _spawn_relic_skill_flash(location: Vector3, tint: Color) -> void:
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.9
	mesh.height = 1.8
	flash.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 3.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = material
	get_tree().current_scene.add_child(flash)
	flash.global_position = location
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3(2.2, 2.2, 2.2), 0.35)
	tween.parallel().tween_property(flash, "transparency", 1.0, 0.35)
	tween.finished.connect(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)


func skill_two() -> Dictionary:
	if not can_attack or not is_instance_valid(actor):
		return {"success": false, "reason": "COMBAT_BUSY"}
	can_attack = false
	_consume_weapon_durability(0.9)
	_fire_hitscan(heavy_damage * 1.2 + _get_progression_damage_bonus(), attack_range * 1.2)
	var progression := _get_progression()
	if progression != null and bool(progression.get("nen_unlocked")) and progression.has_method("record_nen_skill_use"):
		progression.call("record_nen_skill_use", "charged_strike")
	get_tree().create_timer(1.0 * _get_attack_cooldown_multiplier()).timeout.connect(func(): can_attack = true)
	return {"success": true, "ability_id": "charged_strike"}




func _get_progression() -> Node:
	if is_instance_valid(progression):
		return progression
	return get_tree().root.find_child("PlayerProgression", true, false)


func _consume_weapon_durability(amount: float) -> void:
	var progression := _get_progression()
	if progression != null and progression.has_method("consume_equipment_durability"):
		progression.call("consume_equipment_durability", "weapon", amount)


func _get_progression_damage_bonus() -> float:
	var progression := _get_progression()
	if progression != null and progression.has_method("get_combat_damage_bonus"):
		return float(progression.call("get_combat_damage_bonus"))
	return 0.0


func _get_attack_cooldown_multiplier() -> float:
	var progression := _get_progression()
	if progression != null and progression.has_method("get_attack_cooldown_multiplier"):
		return float(progression.call("get_attack_cooldown_multiplier"))
	return 1.0


func _fire_hitscan(damage: float, distance: float) -> void:
	var origin := actor.global_position + Vector3.UP * 1.35
	var direction := -actor.global_transform.basis.z
	if is_instance_valid(camera):
		origin = camera.global_position
		direction = -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin,origin + direction.normalized() * distance)
	query.exclude = [actor.get_rid()]
	query.collide_with_areas = true
	var result := actor.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var collider: Object = result.get("collider")
	var target: Node = collider as Node
	if target != null and not target.has_method("receive_threat") and not target.has_method("take_damage"):
		target = target.get_parent()
	if target != null and target.has_method("receive_threat"):
		target.call("receive_threat", actor)
		_spawn_hit_flash(result.get("position",origin))
		return
	if target != null and target.has_method("take_damage"):
		target.call("take_damage",damage,actor)
		attack_performed.emit(damage,target)
		_spawn_hit_flash(result.get("position",origin))


func _spawn_hit_flash(location: Vector3) -> void:
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	flash.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35,0.8,1.0)
	material.emission_enabled = true
	material.emission = Color(0.2,0.65,1.0)
	material.emission_energy_multiplier = 2.0
	flash.material_override = material
	get_tree().current_scene.add_child(flash)
	flash.global_position = location
	get_tree().create_timer(0.18).timeout.connect(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)


func start_block() -> void:
	is_blocking = true


func stop_block() -> void:
	is_blocking = false


func dodge() -> void:
	if not is_instance_valid(actor):
		return
	var direction := -actor.global_transform.basis.z
	actor.global_position += direction * 2.4
