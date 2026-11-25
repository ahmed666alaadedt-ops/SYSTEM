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
var selected_power_tower_combat_style := "UNARMED_HAND_TO_HAND"
const POWER_TOWER_FORBIDDEN_WEAPONS := ["system_firearm", "hunter_pistol", "hunter_rifle", "precision_rifle", "tactical_shotgun"]


func bind_actor(player: CharacterBody3D, combat_camera: Camera3D, player_progression: Node = null) -> void:
	actor = player
	camera = combat_camera
	progression = player_progression


func set_combat_camera(combat_camera: Camera3D) -> void:
	camera = combat_camera


func select_power_tower_combat_style(style_id: String, allowed_styles: Array = []) -> Dictionary:
	var normalized_style := style_id.strip_edges().to_upper()
	var allowed := allowed_styles.duplicate()
	if allowed.is_empty():
		var operations := get_tree().root.find_child("BaghdadTowerOperationsManager", true, false)
		if operations != null:
			var active_data: Dictionary = operations.get("active_power_floor_data")
			allowed = active_data.get("available_combat_styles", [])
	if not allowed.has(normalized_style):
		return {"success": false, "reason": "COMBAT_STYLE_NOT_AVAILABLE_ON_THIS_FLOOR"}
	var progression_node := _get_progression()
	var slots: Dictionary = progression_node.get("equipment_slots") if progression_node != null else {}
	var equipped_weapon := str(slots.get("weapon", ""))
	var nen_only_selection := allowed.size() == 2 and allowed.has("NEN_TECHNIQUES") and allowed.has("UNARMED_HAND_TO_HAND")
	if nen_only_selection and (progression_node == null or not bool(progression_node.get("nen_unlocked")) or int(progression_node.get("nen_control_rank")) < 5):
		return {"success": false, "reason": "NEN_MASTERY_RANK_FIVE_REQUIRED"}
	if nen_only_selection and not equipped_weapon.is_empty():
		return {"success": false, "reason": "NEN_ONLY_FLOOR_REQUIRES_UNARMED_COMBAT"}
	match normalized_style:
		"TRADITIONAL_MELEE":
			if equipped_weapon not in ["training_sword", "combat_knife", "steel_sword", "hunter_spear", "battle_axe", "long_sword", "great_sword", "war_hammer", "dual_blades"]:
				return {"success": false, "reason": "TRADITIONAL_MELEE_WEAPON_REQUIRED"}
		"BOW_AND_ARROW":
			if equipped_weapon not in ["composite_bow", "crossbow"]:
				return {"success": false, "reason": "BOW_OR_CROSSBOW_REQUIRED"}
		"KUNG_FU", "MARTIAL_ARTS", "UNARMED_HAND_TO_HAND":
			if not equipped_weapon.is_empty():
				return {"success": false, "reason": "UNARMED_STYLE_REQUIRES_EMPTY_WEAPON_SLOT"}
		"NEN_TECHNIQUES":
			if progression_node == null or not bool(progression_node.get("nen_unlocked")) or int(progression_node.get("nen_control_rank")) < 1:
				return {"success": false, "reason": "NEN_TRAINING_REQUIRED"}
			if not equipped_weapon.is_empty() and _is_nen_only_floor():
				return {"success": false, "reason": "NEN_ONLY_FLOOR_REQUIRES_UNARMED_COMBAT"}
	selected_power_tower_combat_style = normalized_style
	if is_instance_valid(actor):
		actor.set_meta("system_power_tower_combat_style", normalized_style)
	return {"success": true, "combat_style": normalized_style}


func perform_selected_power_tower_attack() -> Dictionary:
	if not is_instance_valid(actor):
		return {"success": false, "reason": "COMBAT_ACTOR_UNAVAILABLE"}
	var operations := get_tree().root.find_child("BaghdadTowerOperationsManager", true, false)
	if operations != null and bool(operations.get("power_floor_in_progress")):
		var active_data: Dictionary = operations.get("active_power_floor_data")
		var allowed_styles: Array = active_data.get("available_combat_styles", [])
		var style_check: Dictionary = select_power_tower_combat_style(selected_power_tower_combat_style, allowed_styles)
		if not bool(style_check.get("success", false)):
			return style_check
	match selected_power_tower_combat_style:
		"UNARMED_HAND_TO_HAND":
			await light_attack()
			return {"success": true, "combat_style": selected_power_tower_combat_style}
		"KUNG_FU":
			await _perform_kung_fu_combo()
			return {"success": true, "combat_style": selected_power_tower_combat_style}
		"MARTIAL_ARTS", "TRADITIONAL_MELEE":
			await heavy_attack()
			return {"success": true, "combat_style": selected_power_tower_combat_style}
		"BOW_AND_ARROW":
			return await _perform_bow_attack()
		"NEN_TECHNIQUES":
			var progression_node := _get_progression()
			if progression_node != null and int(progression_node.get("nen_control_rank")) >= 4:
				return skill_one()
			return skill_two()
	return {"success": false, "reason": "UNKNOWN_COMBAT_STYLE"}


func _is_nen_only_floor() -> bool:
	var operations := get_tree().root.find_child("BaghdadTowerOperationsManager", true, false)
	if operations == null:
		return false
	var active_data: Dictionary = operations.get("active_power_floor_data")
	return int(active_data.get("floor", 0)) >= 81


func _perform_kung_fu_combo() -> void:
	if not can_attack or not _power_tower_weapon_policy_allows_attack():
		return
	can_attack = false
	for strike_index in range(3):
		_fire_hitscan(attack_damage * 0.58 + _get_progression_damage_bonus() / 3.0, attack_range * 0.9)
		await get_tree().create_timer(0.10).timeout
	await get_tree().create_timer(0.42 * _get_attack_cooldown_multiplier()).timeout
	can_attack = true


func _perform_bow_attack() -> Dictionary:
	if not can_attack or not _power_tower_weapon_policy_allows_attack():
		return {"success": false, "reason": "COMBAT_BUSY_OR_RESTRICTED"}
	var progression_node := _get_progression()
	var slots: Dictionary = progression_node.get("equipment_slots") if progression_node != null else {}
	if str(slots.get("weapon", "")) not in ["composite_bow", "crossbow"]:
		return {"success": false, "reason": "BOW_OR_CROSSBOW_REQUIRED"}
	if progression_node == null or not progression_node.has_method("get_item_count") or not progression_node.has_method("consume_item"):
		return {"success": false, "reason": "ARROW_INVENTORY_UNAVAILABLE"}
	var ammunition_id := ""
	var ammunition_multiplier := 1.0
	if int(progression_node.call("get_item_count", "diamond_arrows")) > 0:
		ammunition_id = "diamond_arrows"
		ammunition_multiplier = 1.45
	elif int(progression_node.call("get_item_count", "steel_arrows")) > 0:
		ammunition_id = "steel_arrows"
		ammunition_multiplier = 1.2
	elif int(progression_node.call("get_item_count", "reinforced_arrows")) > 0:
		ammunition_id = "reinforced_arrows"
	else:
		return {"success": false, "reason": "ARROWS_REQUIRED"}
	if not bool(progression_node.call("consume_item", ammunition_id, 1)):
		return {"success": false, "reason": "ARROW_CONSUMPTION_FAILED"}
	can_attack = false
	_consume_weapon_durability(0.45)
	_fire_hitscan((attack_damage * 1.25 + _get_progression_damage_bonus()) * ammunition_multiplier, attack_range * 2.4)
	await get_tree().create_timer(0.85 * _get_attack_cooldown_multiplier()).timeout
	can_attack = true
	return {"success": true, "combat_style": "BOW_AND_ARROW", "ammunition_id": ammunition_id}


func light_attack() -> void:
	if not can_attack or not is_instance_valid(actor) or not _power_tower_weapon_policy_allows_attack():
		return
	can_attack = false
	_consume_weapon_durability(0.35)
	_fire_hitscan(attack_damage + _get_progression_damage_bonus(),attack_range)
	await get_tree().create_timer(0.38 * _get_attack_cooldown_multiplier()).timeout
	can_attack = true


func heavy_attack() -> void:
	if not can_attack or not is_instance_valid(actor) or not _power_tower_weapon_policy_allows_attack():
		return
	can_attack = false
	_consume_weapon_durability(0.75)
	_fire_hitscan(heavy_damage + _get_progression_damage_bonus(),attack_range * 1.35)
	await get_tree().create_timer(1.1 * _get_attack_cooldown_multiplier()).timeout
	can_attack = true


func skill_one() -> Dictionary:
	if not can_attack or not is_instance_valid(actor):
		return {"success": false, "reason": "COMBAT_BUSY"}
	if not _power_tower_weapon_policy_allows_attack():
		return {"success": false, "reason": "MODERN_FIREARMS_FORBIDDEN_IN_POWER_TOWER"}
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


func skill_two() -> Dictionary:
	if not can_attack or not is_instance_valid(actor):
		return {"success": false, "reason": "COMBAT_BUSY"}
	if not _power_tower_weapon_policy_allows_attack():
		return {"success": false, "reason": "MODERN_FIREARMS_FORBIDDEN_IN_POWER_TOWER"}
	can_attack = false
	_consume_weapon_durability(0.9)
	_fire_hitscan(heavy_damage * 1.2 + _get_progression_damage_bonus(), attack_range * 1.2)
	var progression := _get_progression()
	if progression != null and bool(progression.get("nen_unlocked")) and progression.has_method("record_nen_skill_use"):
		progression.call("record_nen_skill_use", "charged_strike")
	get_tree().create_timer(1.0 * _get_attack_cooldown_multiplier()).timeout.connect(func(): can_attack = true)
	return {"success": true, "ability_id": "charged_strike"}




func _power_tower_weapon_policy_allows_attack() -> bool:
	var operations := get_tree().root.find_child("BaghdadTowerOperationsManager", true, false)
	if operations == null or not bool(operations.get("power_floor_in_progress")):
		return true
	var progression_node := _get_progression()
	if progression_node == null:
		return true
	var slots: Dictionary = progression_node.get("equipment_slots")
	var equipped_weapon := str(slots.get("weapon", ""))
	var active_floor_data: Dictionary = operations.get("active_power_floor_data")
	var active_floor_number := int(active_floor_data.get("floor", 0))
	if active_floor_number >= 81:
		if not bool(progression_node.get("nen_unlocked")) or int(progression_node.get("nen_control_rank")) < 5:
			push_warning("SYSTEM POWER TOWER: floors 81–200 require Nen mastery rank 5.")
			return false
		if not equipped_weapon.is_empty():
			push_warning("SYSTEM POWER TOWER: upper floors are Nen-only; unequip all weapons and fight with Nen.")
			return false
	if POWER_TOWER_FORBIDDEN_WEAPONS.has(equipped_weapon):
		push_warning("SYSTEM POWER TOWER: modern firearms are forbidden in official tower duels; equip a traditional weapon.")
		return false
	return true


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
