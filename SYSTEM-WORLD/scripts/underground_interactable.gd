extends Node3D
class_name UndergroundInteractable

signal door_state_changed(is_open: bool)

## Small interaction endpoint used by the shared SystemWorldInteractionManager.
@export_enum("stone_door", "relic", "strongbox", "rune", "greed_fragment", "world_fragment") var action_type: String = "stone_door"
@export var action_target_path: NodePath = ^"DoorBody"
@export_enum("modern", "historical", "fantasy") var world_fragment_world: String = "modern"
@export var world_fragment_id: String = ""
@export var puzzle_controller_path: NodePath = ^"../PuzzleController"
@export var rune_symbol: String = "river"
@export_range(1, 500, 1) var discovery_xp: int = 35
@export var greed_fragment_id: String = ""

var _used := false
var _opened := false
var _door_tween: Tween
var _closed_door_position := Vector3.ZERO
var _door_position_captured := false

const DOOR_OPEN_OFFSET := Vector3(0.0, 4.2, 0.0)
const DOOR_ANIMATION_SECONDS := 1.25


func system_interact() -> void:
	match action_type:
		"stone_door":
			_toggle_stone_door()
		"relic", "strongbox":
			_claim_discovery()
		"rune":
			_press_rune()
		"greed_fragment":
			_claim_greed_fragment()
		"world_fragment":
			_claim_world_fragment()


func _toggle_stone_door() -> void:
	var door := get_node_or_null(action_target_path) as Node3D
	if door == null:
		push_warning("SYSTEM underground: door target is missing.")
		return

	if not _door_position_captured:
		_closed_door_position = door.position
		_door_position_captured = true

	if _door_tween != null and _door_tween.is_running():
		_door_tween.kill()

	_opened = not _opened
	door.visible = true
	var destination := _closed_door_position
	if _opened:
		destination += DOOR_OPEN_OFFSET

	# Keep the collision attached to the moving slab. Raising the slab clears
	# the doorway physically; hiding/disabling its collision would be a fake open.
	_door_tween = create_tween()
	_door_tween.set_trans(Tween.TRANS_CUBIC)
	_door_tween.set_ease(Tween.EASE_IN_OUT)
	_door_tween.tween_property(
		door,
		"position",
		destination,
		DOOR_ANIMATION_SECONDS
	)

	set_meta("system_door_open", _opened)
	door_state_changed.emit(_opened)
	set_meta(
		"system_interaction_prompt",
		"أغلق الباب الحجري" if _opened else "افتح الباب الحجري"
	)
	print("SYSTEM underground stone door transition started; open: ", _opened)



func restore_stone_door_state(opened: bool) -> void:
	if action_type != "stone_door":
		return
	var door := get_node_or_null(action_target_path) as Node3D
	if door == null:
		push_warning("SYSTEM underground: cannot restore door state; target is missing.")
		return

	if not _door_position_captured:
		_closed_door_position = door.position
		_door_position_captured = true
	_opened = opened
	var restored_position := _closed_door_position
	if _opened:
		restored_position += DOOR_OPEN_OFFSET
	# The door is an AnimatableBody3D registered with physics; defer the
	# restored transform until the current scene-tree setup has completed.
	door.set_deferred("position", restored_position)
	door.visible = true
	set_meta("system_door_open", _opened)
	set_meta(
		"system_interaction_prompt",
		"أغلق الباب الحجري" if _opened else "افتح الباب الحجري"
	)


func _claim_discovery() -> void:
	if _used:
		set_meta("system_interaction_prompt", "تم اكتشاف هذا الأثر")
		return

	_used = true
	set_meta("system_interaction_prompt", "تم اكتشاف هذا الأثر")
	var reward_xp := discovery_xp
	if action_type == "strongbox":
		reward_xp = maxi(reward_xp, 50)
	_grant_exploration_xp(reward_xp, "Underground discovery: " + name)
	print("SYSTEM underground discovery claimed: ", name)



func _claim_greed_fragment() -> void:
	if _used:
		return
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if progression == null or not progression.has_method("collect_greed_fragment"):
		push_warning("SYSTEM: Greed Island collection service is unavailable.")
		return
	var result: Dictionary = progression.call("collect_greed_fragment", greed_fragment_id)
	if not bool(result.get("success", false)):
		set_meta("system_interaction_prompt", "هذه القطعة موجودة في مجموعتك مسبقاً")
		return
	_used = true
	set_meta("system_interaction_prompt", "تم جمع قطعة جزيرة الطمع")
	print("SYSTEM Greed Island fragment collected: ", greed_fragment_id, " (", result.get("count", 0), "/3)")


func _claim_world_fragment() -> void:
	if _used:
		return
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if progression == null or not progression.has_method("collect_world_fragment"):
		push_warning("SYSTEM: World fragment collection service is unavailable.")
		return
	var result: Dictionary = progression.call("collect_world_fragment", world_fragment_world, world_fragment_id)
	if not bool(result.get("success", false)):
		set_meta("system_interaction_prompt", "هذه القطعة موجودة في مجموعتك مسبقاً")
		return
	_used = true
	set_meta("system_interaction_prompt", "تم جمع قطعة " + world_fragment_world)
	print("SYSTEM world fragment collected: ", world_fragment_world, " / ", world_fragment_id, " (", result.get("count", 0), "/3)")


func _press_rune() -> void:
	var controller := get_node_or_null(puzzle_controller_path)
	if controller == null or not controller.has_method("press_rune"):
		push_warning("SYSTEM underground: puzzle controller is missing.")
		return

	controller.call("press_rune", rune_symbol)
	set_meta("system_interaction_prompt", "رمز أثري: " + rune_symbol)



func _grant_exploration_xp(amount: int, reason: String) -> void:
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if progression == null or not progression.has_method("add_experience"):
		push_warning("SYSTEM underground: player progression is unavailable; XP reward skipped.")
		return
	progression.call("add_experience", amount, reason)
