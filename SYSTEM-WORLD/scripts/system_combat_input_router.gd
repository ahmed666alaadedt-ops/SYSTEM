
extends Node

const HISTORICAL_COMBAT_SCRIPT = preload(
	"res://scripts/historical_combat_system.gd/historical_combat_system.gd"
)

const HISTORICAL_WORLD_ID := 1

var bound_scene: Node
var controls: Object
var world_manager: Node
var player: CharacterBody3D
var camera: Camera3D

var historical_combat: Node


func _ready() -> void:
	name = "SYSTEMCombatInputRouter"
	set_process(true)


func _process(_delta: float) -> void:
	var current_scene := get_tree().current_scene

	if current_scene != bound_scene:
		_unbind_previous_scene()
		_try_bind_current_scene()


func _unbind_previous_scene() -> void:
	if is_instance_valid(historical_combat):
		historical_combat.queue_free()

	historical_combat = null
	bound_scene = null
	controls = null
	world_manager = null
	player = null
	camera = null


func _try_bind_current_scene() -> void:
	var scene := get_tree().current_scene

	if scene == null:
		return

	var found_controls = scene.get("mobile_controls")
	var found_manager = scene.get("world_manager")
	var found_player = scene.get("player")
	var found_camera = scene.get("camera")

	if (
		found_controls == null
		or found_manager == null
		or found_player == null
		or found_camera == null
	):
		return

	controls = found_controls
	world_manager = found_manager
	player = found_player
	camera = found_camera
	bound_scene = scene

	_connect_control_signals()
	_connect_world_signals()
	_refresh_combat_system()

	print("SYSTEM: Combat input router connected.")


func _connect_control_signals() -> void:
	_connect_signal("attack_pressed", _on_attack_pressed)
	_connect_signal("skill_one_pressed", _on_skill_one_pressed)
	_connect_signal("skill_two_pressed", _on_skill_two_pressed)
	_connect_signal("dodge_pressed", _on_dodge_pressed)


func _connect_signal(
	signal_name: String,
	callback: Callable
) -> void:
	if not controls.has_signal(signal_name):
		push_warning(
			"SYSTEM: Missing control signal: " + signal_name
		)
		return

	if not controls.is_connected(signal_name, callback):
		controls.connect(signal_name, callback)


func _connect_world_signals() -> void:
	if not world_manager.has_signal("world_changed"):
		return

	var callback := Callable(self, "_on_world_changed")

	if not world_manager.is_connected("world_changed", callback):
		world_manager.connect("world_changed", callback)


func _on_world_changed(_world_id: int) -> void:
	_refresh_combat_system()


func _refresh_combat_system() -> void:
	if not is_instance_valid(world_manager):
		return

	var active_world := int(world_manager.get("active_world"))

	if active_world != HISTORICAL_WORLD_ID:
		_hide_historical_weapon()
		return

	if not is_instance_valid(historical_combat):
		historical_combat = HISTORICAL_COMBAT_SCRIPT.new()
		historical_combat.name = "HistoricalCombatSystem"

		world_manager.add_child(historical_combat)
		historical_combat.call("bind_actor", player, camera)

		print("SYSTEM: Historical combat system activated.")
	else:
		historical_combat.call("set_combat_camera", camera)

		if historical_combat.get("actor") != player:
			historical_combat.call("bind_actor", player, camera)

	_show_historical_weapon()


func _is_historical_combat_active() -> bool:
	if not is_instance_valid(world_manager):
		return false

	if not is_instance_valid(historical_combat):
		return false

	return (
		int(world_manager.get("active_world"))
		== HISTORICAL_WORLD_ID
	)


func _on_attack_pressed() -> void:
	if not _is_historical_combat_active():
		return

	historical_combat.call("light_attack")


func _on_skill_one_pressed() -> void:
	if not _is_historical_combat_active():
		return

	historical_combat.call("heavy_attack")


func _on_skill_two_pressed() -> void:
	if not _is_historical_combat_active():
		return

	var blocking := bool(historical_combat.get("is_blocking"))

	if blocking:
		historical_combat.call("stop_block")
	else:
		historical_combat.call("start_block")


func _on_dodge_pressed() -> void:
	if not _is_historical_combat_active():
		return

	historical_combat.call("dodge")


func _show_historical_weapon() -> void:
	if not is_instance_valid(historical_combat):
		return

	var weapon_pivot = historical_combat.get("weapon_pivot")

	if is_instance_valid(weapon_pivot):
		weapon_pivot.visible = true


func _hide_historical_weapon() -> void:
	if not is_instance_valid(historical_combat):
		return

	var weapon_pivot = historical_combat.get("weapon_pivot")

	if is_instance_valid(weapon_pivot):
		weapon_pivot.visible = false
