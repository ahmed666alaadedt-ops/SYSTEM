extends CharacterBody3D
class_name SYSTEMCombatant

signal health_changed(current_health: float, maximum_health: float)
signal damage_received(amount: float, source: Node)
signal combatant_died(combatant: Node, source: Node)

@export_group("Health")
@export var maximum_health: float = 100.0
@export var show_placeholder_visual: bool = true

@export_group("Appearance")
@export var capsule_radius: float = 0.5
@export var capsule_height: float = 2.0

var current_health: float = 100.0
var is_alive: bool = true

var body_collision: CollisionShape3D


func _ready() -> void:
    add_to_group("system_combatants")

    maximum_health = maxf(maximum_health, 1.0)
    current_health = maximum_health
    is_alive = true

    _create_collision()
    _create_visual()

    health_changed.emit(current_health, maximum_health)


func _create_collision() -> void:
    body_collision = get_node_or_null("CollisionShape3D")

    if body_collision == null:
        body_collision = CollisionShape3D.new()
        body_collision.name = "CollisionShape3D"

        var capsule := CapsuleShape3D.new()
        capsule.radius = capsule_radius
        capsule.height = maxf(capsule_height, capsule_radius * 2.0)

        body_collision.shape = capsule
        add_child(body_collision)


func _create_visual() -> void:
    if not show_placeholder_visual:
        return

    if get_node_or_null("Visual") != null:
        return

    var visual := MeshInstance3D.new()
    visual.name = "Visual"

    var capsule := CapsuleMesh.new()
    capsule.radius = capsule_radius
    capsule.height = maxf(capsule_height, capsule_radius * 2.0)

    visual.mesh = capsule

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.1, 0.65, 0.9)
    material.metallic = 0.25
    material.roughness = 0.4

    visual.material_override = material

    add_child(visual)


func take_damage(amount: float, source: Node = null) -> bool:
    if not is_alive:
        return false

    if amount <= 0.0:
        return false

    current_health = maxf(current_health - amount, 0.0)

    damage_received.emit(amount, source)
    health_changed.emit(current_health, maximum_health)

    if current_health <= 0.0:
        die(source)

    return true


func heal(amount: float) -> float:
    if not is_alive or amount <= 0.0:
        return 0.0

    var previous_health := current_health

    current_health = minf(
        current_health + amount,
        maximum_health
    )

    var recovered := current_health - previous_health

    if recovered > 0.0:
        health_changed.emit(current_health, maximum_health)

    return recovered


func get_health_ratio() -> float:
    if maximum_health <= 0.0:
        return 0.0

    return current_health / maximum_health


func die(source: Node = null) -> void:
    if not is_alive:
        return

    is_alive = false
    current_health = 0.0
    velocity = Vector3.ZERO

    if body_collision != null:
        body_collision.set_deferred("disabled", true)

    set_physics_process(false)

    health_changed.emit(current_health, maximum_health)
    combatant_died.emit(self, source)


func revive(health_amount: float = -1.0) -> void:
    if is_alive:
        return

    if health_amount <= 0.0:
        current_health = maximum_health
    else:
        current_health = minf(health_amount, maximum_health)

    is_alive = current_health > 0.0

    if body_collision != null:
        body_collision.set_deferred("disabled", false)

    set_physics_process(true)

    health_changed.emit(current_health, maximum_health)
