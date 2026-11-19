extends Node
class_name ModernWorldCombatSystem

signal attack_performed(damage: float, hit_target: Node)

var actor: CharacterBody3D
var camera: Camera3D
var can_attack := true
var is_blocking := false
var attack_damage := 34.0
var heavy_damage := 90.0
var attack_range := 65.0


func bind_actor(player: CharacterBody3D, combat_camera: Camera3D) -> void:
	actor = player
	camera = combat_camera


func set_combat_camera(combat_camera: Camera3D) -> void:
	camera = combat_camera


func light_attack() -> void:
	if not can_attack or not is_instance_valid(actor):
		return
	can_attack = false
	_fire_hitscan(attack_damage,attack_range)
	await get_tree().create_timer(0.38).timeout
	can_attack = true


func heavy_attack() -> void:
	if not can_attack or not is_instance_valid(actor):
		return
	can_attack = false
	_fire_hitscan(heavy_damage,attack_range * 1.35)
	await get_tree().create_timer(1.1).timeout
	can_attack = true


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
