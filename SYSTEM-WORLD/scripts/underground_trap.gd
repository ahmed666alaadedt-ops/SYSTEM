extends Node3D
class_name UndergroundTrap

signal trap_triggered(player: Node3D, damage_amount: float)

@export_range(0.0, 100.0, 1.0) var damage_amount: float = 18.0
@export var one_shot: bool = true

var _triggered := false
var _spike_visuals: Array[Node3D] = []


func configure_spikes(spikes: Array[Node3D]) -> void:
	_spike_visuals = spikes
	for spike in _spike_visuals:
		spike.visible = false
		_set_spike_collision(spike, false)


func activate_for(body: Node3D) -> void:
	if _triggered and one_shot:
		return
	if body.name != "Player":
		return

	_triggered = true
	for spike in _spike_visuals:
		spike.visible = true
		_set_spike_collision(spike, true)
	trap_triggered.emit(body, damage_amount)
	print("SYSTEM underground trap triggered. Damage event emitted: ", damage_amount)


func reset_trap() -> void:
	_triggered = false
	for spike in _spike_visuals:
		spike.visible = false



func _set_spike_collision(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = not enabled
	for child in node.get_children():
		_set_spike_collision(child, enabled)
