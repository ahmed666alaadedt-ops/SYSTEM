extends Node3D
class_name UndergroundInteractable

## Small interaction endpoint used by the shared SystemWorldInteractionManager.
@export_enum("stone_door", "relic", "strongbox") var action_type: String = "stone_door"
@export var action_target_path: NodePath = ^"DoorBody"
@export var puzzle_controller_path: NodePath = ^"../PuzzleController"
@export var rune_symbol: String = "river"

var _used := false
var _opened := false


func system_interact() -> void:
	match action_type:
		"stone_door":
			_toggle_stone_door()
		"relic", "strongbox":
			_claim_discovery()
		"rune":
			_press_rune()


func _toggle_stone_door() -> void:
	var door := get_node_or_null(action_target_path) as Node3D
	if door == null:
		push_warning("SYSTEM underground: door target is missing.")
		return

	_opened = not _opened
	door.visible = not _opened
	_set_collision_enabled(door, not _opened)
	set_meta(
		"system_interaction_prompt",
		"أغلق الباب الحجري" if _opened else "افتح الباب الحجري"
	)
	print("SYSTEM underground stone door opened: ", _opened)


func _set_collision_enabled(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = not enabled

	for child in node.get_children():
		_set_collision_enabled(child, enabled)


func _claim_discovery() -> void:
	if _used:
		set_meta("system_interaction_prompt", "تم اكتشاف هذا الأثر")
		return

	_used = true
	set_meta("system_interaction_prompt", "تم اكتشاف هذا الأثر")
	print("SYSTEM underground discovery claimed: ", name)



func _press_rune() -> void:
	var controller := get_node_or_null(puzzle_controller_path)
	if controller == null or not controller.has_method("press_rune"):
		push_warning("SYSTEM underground: puzzle controller is missing.")
		return

	controller.call("press_rune", rune_symbol)
	set_meta("system_interaction_prompt", "رمز أثري: " + rune_symbol)
