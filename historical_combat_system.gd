
extends Node3D
class_name HistoricalCombatSystem

signal attack_performed(weapon_type: String, damage: float)
signal weapon_changed(weapon_type: String)
signal combat_effect_requested(effect_type: String)

enum WeaponType {
	SWORD,
	HEAVY_SWORD,
	SPEAR,
	AXE,
	BOW
}

@export var attack_range: float = 3.2
@export var light_damage: float = 20.0
@export var heavy_damage: float = 42.0
@export var arrow_damage: float = 24.0
@export var attack_cooldown: float = 0.55
@export var arrow_speed: float = 38.0

var actor: Node3D
var combat_camera: Camera3D
var weapon_type: WeaponType = WeaponType.SWORD

var is_blocking := false
var is_dodging := false
var can_attack := true

var weapon_pivot: Node3D
var weapon_visual: MeshInstance3D
var active_projectiles: Array[Dictionary] = []

var weapon_levels := {
	WeaponType.SWORD: 1,
	WeaponType.HEAVY_SWORD: 1,
	WeaponType.SPEAR: 1,
	WeaponType.AXE: 1,
	WeaponType.BOW: 1
}

var weapon_bonus_damage := {
	WeaponType.SWORD: 0.0,
	WeaponType.HEAVY_SWORD: 0.0,
	WeaponType.SPEAR: 0.0,
	WeaponType.AXE: 0.0,
	WeaponType.BOW: 0.0
}


func _ready() -> void:
	name = "HistoricalCombatSystem"
	set_process(true)


# --------------------------------------------------
# CONNECT TO PLAYER
# --------------------------------------------------

func bind_actor(
	player: Node3D,
	camera: Camera3D = null
) -> void:
	actor = player
	combat_camera = camera
	_create_weapon_visual()


func set_combat_camera(camera: Camera3D) -> void:
	combat_camera = camera


# --------------------------------------------------
# WEAPON SELECTION
# --------------------------------------------------

func equip_weapon(new_weapon: WeaponType) -> void:
	weapon_type = new_weapon
	_create_weapon_visual()

	weapon_changed.emit(_weapon_name())
	print("SYSTEM weapon equipped: ", _weapon_name())


func _weapon_name() -> String:
	match weapon_type:
		WeaponType.SWORD:
			return "Sword"
		WeaponType.HEAVY_SWORD:
			return "Heavy Sword"
		WeaponType.SPEAR:
			return "Spear"
		WeaponType.AXE:
			return "Axe"
		WeaponType.BOW:
			return "Bow"
	return "Unknown"


func _create_weapon_visual() -> void:
	if actor == null:
		return

	if is_instance_valid(weapon_pivot):
		weapon_pivot.queue_free()

	weapon_pivot = Node3D.new()
	weapon_pivot.name = "HistoricalWeaponPivot"
	weapon_pivot.position = Vector3(0.65, 0.9, -0.75)
	actor.add_child(weapon_pivot)

	weapon_visual = MeshInstance3D.new()
	weapon_visual.name = "WeaponVisual"
	weapon_pivot.add_child(weapon_visual)

	var mesh: Mesh

	match weapon_type:
		WeaponType.SWORD:
			mesh = _make_blade(0.12, 1.3)
		WeaponType.HEAVY_SWORD:
			mesh = _make_blade(0.24, 1.8)
		WeaponType.SPEAR:
			mesh = _make_spear()
		WeaponType.AXE:
			mesh = _make_axe()
		WeaponType.BOW:
			mesh = _make_bow()

	weapon_visual.mesh = mesh
	weapon_visual.material_override = _weapon_material()


func _make_blade(width: float, length: float) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, length, 0.09)
	return mesh


func _make_spear() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.025
	mesh.bottom_radius = 0.055
	mesh.height = 2.3
	return mesh


func _make_axe() -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.75, 1.1, 0.16)
	return mesh


func _make_bow() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.38
	mesh.outer_radius = 0.45
	return mesh


func _weapon_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.76, 0.82)
	material.metallic = 0.82
	material.roughness = 0.24
	return material


# --------------------------------------------------
# LIGHT ATTACK
# --------------------------------------------------

func light_attack() -> void:
	if not _can_use_combat():
		return

	if weapon_type == WeaponType.BOW:
		shoot_arrow()
		return

	if not can_attack:
		return

	can_attack = false

	var damage := light_damage + weapon_bonus_damage[weapon_type]
	_play_weapon_swing(false)
	_apply_melee_damage(damage, attack_range)

	attack_performed.emit(_weapon_name(), damage)
	combat_effect_requested.emit("light_slash")

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


# --------------------------------------------------
# HEAVY ATTACK
# --------------------------------------------------

func heavy_attack() -> void:
	if not _can_use_combat() or not can_attack:
		return

	if weapon_type == WeaponType.BOW:
		shoot_arrow(true)
		return

	can_attack = false

	var damage := heavy_damage + weapon_bonus_damage[weapon_type]
	_play_weapon_swing(true)
	_apply_melee_damage(damage, attack_range + 1.0)

	_create_impact_effect()
	_shake_camera(0.20, 0.16)

	attack_performed.emit(_weapon_name(), damage)
	combat_effect_requested.emit("heavy_impact")

	await get_tree().create_timer(attack_cooldown * 1.7).timeout
	can_attack = true


# --------------------------------------------------
# MELEE HIT DETECTION
# --------------------------------------------------

func _apply_melee_damage(damage: float, distance: float) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var space := actor.get_world_3d().direct_space_state
	var forward := -actor.global_transform.basis.z

	var from := actor.global_position + Vector3.UP * 1.1
	var to := from + forward * distance

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [actor.get_rid()]

	var result := space.intersect_ray(query)

	if result.is_empty():
		return

	var target: Object = result.get("collider")

	if target == null:
		return

	if target.has_method("take_damage"):
		target.take_damage(damage)

	elif target is Node:
		var target_node := target as Node
		var parent := target_node.get_parent()

		if parent != null and parent.has_method("take_damage"):
			parent.take_damage(damage)

	_create_impact_effect(result.get("position", to))


# --------------------------------------------------
# BLOCK / SHIELD
# --------------------------------------------------

func start_block() -> void:
	if actor == null:
		return

	is_blocking = true
	combat_effect_requested.emit("block_start")


func stop_block() -> void:
	is_blocking = false
	combat_effect_requested.emit("block_end")


func receive_damage(incoming_damage: float) -> float:
	if is_dodging:
		return 0.0

	var final_damage := incoming_damage

	if is_blocking:
		final_damage *= 0.25
		_create_impact_effect()

	return final_damage


# --------------------------------------------------
# DODGE
# --------------------------------------------------

func dodge() -> void:
	if actor == null or is_dodging:
		return

	is_dodging = true
	is_blocking = false

	var direction := -actor.global_transform.basis.z
	actor.global_position += direction * 2.0

	combat_effect_requested.emit("dodge")

	await get_tree().create_timer(0.45).timeout
	is_dodging = false


# --------------------------------------------------
# BOW AND ARROWS
# --------------------------------------------------

func shoot_arrow(powerful: bool = false) -> void:
	if actor == null or not can_attack:
		return

	can_attack = false

	var damage := arrow_damage + weapon_bonus_damage[WeaponType.BOW]

	if powerful:
		damage *= 1.8

	var direction := -actor.global_transform.basis.z
	var origin := actor.global_position + Vector3.UP * 1.5
	var target := origin + direction * 100.0

	if combat_camera != null:
		origin = combat_camera.global_position
		direction = -combat_camera.global_transform.basis.z
		target = origin + direction * 100.0

	var projectile := {
		"position": origin,
		"direction": direction.normalized(),
		"damage": damage,
		"distance": 0.0,
		"node": _create_arrow_visual(origin, direction)
	}

	active_projectiles.append(projectile)

	combat_effect_requested.emit(
		"powerful_arrow" if powerful else "arrow_shot"
	)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func _create_arrow_visual(
	origin: Vector3,
	direction: Vector3
) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	arrow.name = "SYSTEM_Arrow"

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.045, 0.045, 0.85)

	arrow.mesh = mesh
	arrow.position = origin
	arrow.look_at(origin + direction, Vector3.UP)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.65, 0.48, 0.25)
	material.metallic = 0.25
	arrow.material_override = material

	get_tree().current_scene.add_child(arrow)
	return arrow


func _process(delta: float) -> void:
	_update_projectiles(delta)


func _update_projectiles(delta: float) -> void:
	for index in range(active_projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = active_projectiles[index]

		var node: MeshInstance3D = projectile["node"]

		if not is_instance_valid(node):
			active_projectiles.remove_at(index)
			continue

		var direction: Vector3 = projectile["direction"]
		var movement := direction * arrow_speed * delta
		var old_position: Vector3 = projectile["position"]
		var new_position := old_position + movement

		var space := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(
			old_position,
			new_position
		)

		if actor != null:
			query.exclude = [actor.get_rid()]

		var result := space.intersect_ray(query)

		projectile["distance"] += movement.length()
		projectile["position"] = new_position

		if not result.is_empty():
			var target: Object = result.get("collider")

			if target != null and target.has_method("take_damage"):
				target.take_damage(projectile["damage"])

			_create_impact_effect(result.get("position", new_position))
			node.queue_free()
			active_projectiles.remove_at(index)
			continue

		if projectile["distance"] > 100.0:
			node.queue_free()
			active_projectiles.remove_at(index)
			continue

		node.global_position = new_position
		node.look_at(new_position + direction, Vector3.UP)
		active_projectiles[index] = projectile


# --------------------------------------------------
# WEAPON SWING
# --------------------------------------------------

func _play_weapon_swing(heavy: bool) -> void:
	if not is_instance_valid(weapon_pivot):
		return

	var duration := 0.24 if heavy else 0.16
	var rotation_amount := 2.1 if heavy else 1.35

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		weapon_pivot,
		"rotation:z",
		-rotation_amount,
		duration * 0.5
	)

	tween.tween_property(
		weapon_pivot,
		"rotation:z",
		0.0,
		duration * 0.5
	)


# --------------------------------------------------
# IMPACT AND CAMERA EFFECTS
# --------------------------------------------------

func _create_impact_effect(
	position: Vector3 = Vector3.ZERO
) -> void:
	var effect := GPUParticles3D.new()
	effect.name = "SYSTEM_WeaponImpact"
	effect.position = position
	effect.amount = 24
	effect.lifetime = 0.35
	effect.one_shot = true
	effect.explosiveness = 0.95

	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.045
	particle_mesh.height = 0.09

	var particle_material := StandardMaterial3D.new()
	particle_material.albedo_color = Color(1.0, 0.67, 0.22)
	particle_material.emission_enabled = true
	particle_material.emission = Color(1.0, 0.32, 0.06)
	particle_material.emission_energy_multiplier = 2.0

	effect.draw_pass_1 = particle_mesh
	effect.material_override = particle_material

	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 2.0
	process_material.initial_velocity_max = 7.0
	process_material.gravity = Vector3(0, -9.8, 0)

	effect.process_material = process_material
	get_tree().current_scene.add_child(effect)
	effect.global_position = position
	effect.emitting = true

	get_tree().create_timer(1.0).timeout.connect(
		func():
			if is_instance_valid(effect):
				effect.queue_free()
	)


func _shake_camera(
	duration: float,
	strength: float
) -> void:
	if combat_camera == null:
		return

	var original := combat_camera.position
	var elapsed := 0.0

	while elapsed < duration:
		if not is_instance_valid(combat_camera):
			return

		combat_camera.position = original + Vector3(
			randf_range(-strength, strength),
			randf_range(-strength, strength),
			0
		)

		await get_tree().process_frame
		elapsed += get_process_delta_time()

	if is_instance_valid(combat_camera):
		combat_camera.position = original


# --------------------------------------------------
# WEAPON PROGRESSION
# --------------------------------------------------

func upgrade_weapon(
	target_weapon: WeaponType,
	damage_increase: float
) -> void:
	if damage_increase <= 0.0:
		return

	weapon_levels[target_weapon] += 1
	weapon_bonus_damage[target_weapon] += damage_increase

	print(
		"SYSTEM weapon upgraded: ",
		target_weapon,
		" Level: ",
		weapon_levels[target_weapon]
	)


func get_weapon_level(target_weapon: WeaponType) -> int:
	return weapon_levels[target_weapon]


func get_weapon_damage(target_weapon: WeaponType) -> float:
	var base_damage := light_damage

	if target_weapon == WeaponType.BOW:
		base_damage = arrow_damage
	elif target_weapon == WeaponType.HEAVY_SWORD:
		base_damage = heavy_damage

	return base_damage + weapon_bonus_damage[target_weapon]


# --------------------------------------------------
# SAFETY
# --------------------------------------------------

func _can_use_combat() -> bool:
	if actor == null or not is_instance_valid(actor):
		return false

	var manager := get_node_or_null("/root/WorldManager")

	if manager != null and manager.has_method("is_combat_allowed"):
		return manager.is_combat_allowed()

	return true
