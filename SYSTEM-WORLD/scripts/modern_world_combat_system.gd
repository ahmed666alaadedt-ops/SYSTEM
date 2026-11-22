extends Node
class_name ModernWorldCombatSystem

signal attack_performed(damage: float, hit_target: Node)

var actor: CharacterBody3D
var camera: Camera3D
var progression: Node

const DEFAULT_WEAPON_PROFILE := {"light_damage":34.0,"heavy_damage":90.0,"range":65.0,"weapon_class":"unarmed"}
const WEAPON_PROFILES := {
	"armory_sidearm":{"light_damage":24.0,"heavy_damage":38.0,"range":40.0,"weapon_class":"firearm"},
	"armory_assault_rifle":{"light_damage":30.0,"heavy_damage":45.0,"range":70.0,"weapon_class":"firearm"},
	"armory_precision_rifle":{"light_damage":75.0,"heavy_damage":125.0,"range":160.0,"weapon_class":"firearm"},
	"armory_scattergun":{"light_damage":48.0,"heavy_damage":70.0,"range":18.0,"weapon_class":"firearm"},
	"armory_support_gun":{"light_damage":34.0,"heavy_damage":52.0,"range":85.0,"weapon_class":"firearm"},
	"armory_energy_rifle":{"light_damage":46.0,"heavy_damage":80.0,"range":105.0,"weapon_class":"energy"},
	"armory_long_sword":{"light_damage":38.0,"heavy_damage":68.0,"range":4.8,"weapon_class":"melee"},
	"armory_dual_daggers":{"light_damage":25.0,"heavy_damage":46.0,"range":3.6,"weapon_class":"melee"},
	"armory_spear":{"light_damage":34.0,"heavy_damage":62.0,"range":6.5,"weapon_class":"melee"},
	"armory_battle_axe":{"light_damage":48.0,"heavy_damage":86.0,"range":4.2,"weapon_class":"melee"},
	"armory_recurve_bow":{"light_damage":32.0,"heavy_damage":58.0,"range":58.0,"weapon_class":"projectile"},
	"armory_crossbow":{"light_damage":44.0,"heavy_damage":76.0,"range":72.0,"weapon_class":"projectile"}
}
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
	var profile := get_equipped_weapon_profile()
	_fire_hitscan(float(profile.get("light_damage", attack_damage)), float(profile.get("range", attack_range)))
	await get_tree().create_timer(0.38).timeout
	can_attack = true


func heavy_attack() -> void:
	if not can_attack or not is_instance_valid(actor):
		return
	can_attack = false
	var profile := get_equipped_weapon_profile()
	_fire_hitscan(float(profile.get("heavy_damage", heavy_damage)), float(profile.get("range", attack_range)) * 1.15)
	await get_tree().create_timer(1.1).timeout
	can_attack = true



func get_equipped_weapon_profile() -> Dictionary:
	if not is_instance_valid(progression) or not progression.has_method("get_equipped_weapon"):
		return DEFAULT_WEAPON_PROFILE.duplicate(true)
	var weapon_id := str(progression.call("get_equipped_weapon"))
	if weapon_id.is_empty():
		return DEFAULT_WEAPON_PROFILE.duplicate(true)
	var profile: Dictionary = WEAPON_PROFILES.get(weapon_id, DEFAULT_WEAPON_PROFILE)
	return profile.duplicate(true)


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
