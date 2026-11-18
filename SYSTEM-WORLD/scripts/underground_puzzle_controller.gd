extends Node3D
class_name UndergroundPuzzleController

## Three-symbol sequence puzzle for hidden heritage vaults.
signal puzzle_solved
signal puzzle_failed

const CORRECT_SEQUENCE := ["river", "sun", "moon"]
var _entered_sequence: Array[String] = []
var _gate: StaticBody3D
var _gate_visual: MeshInstance3D
var _gate_collision: CollisionShape3D
var _solved := false
var _pressure_reward_claimed := false
var _pressure_plate_states: Array[bool] = [false, false, false]
var _pressure_gate_visual: MeshInstance3D
var _pressure_gate_collision: CollisionShape3D


func configure(gate: StaticBody3D, visual: MeshInstance3D, collision: CollisionShape3D) -> void:
	_gate = gate
	_gate_visual = visual
	_gate_collision = collision


func press_rune(symbol: String) -> void:
	if _solved:
		return

	_entered_sequence.append(symbol)
	var index := _entered_sequence.size() - 1
	if index >= CORRECT_SEQUENCE.size() or _entered_sequence[index] != CORRECT_SEQUENCE[index]:
		_entered_sequence.clear()
		puzzle_failed.emit()
		print("SYSTEM underground puzzle: incorrect rune sequence.")
		return

	if _entered_sequence.size() == CORRECT_SEQUENCE.size():
		_solved = true
		if _gate_visual != null:
			_gate_visual.visible = false
		if _gate_collision != null:
			_gate_collision.disabled = true
		puzzle_solved.emit()
		_grant_puzzle_xp(80, "Solved ancient rune sequence")
		print("SYSTEM underground puzzle solved: hidden vault opened.")


func get_progress_text() -> String:
	return str(_entered_sequence.size()) + "/" + str(CORRECT_SEQUENCE.size())



func configure_pressure_gate(visual: MeshInstance3D, collision: CollisionShape3D) -> void:
	_pressure_gate_visual = visual
	_pressure_gate_collision = collision


func on_pressure_plate_body_entered(body: Node3D, plate_index: int) -> void:
	if not body is CharacterBody3D or body.name != "Player":
		return
	if plate_index < 0 or plate_index >= _pressure_plate_states.size():
		return

	_pressure_plate_states[plate_index] = true
	if _pressure_plate_states.all(func(value: bool) -> bool: return value) and not _pressure_reward_claimed:
		_pressure_reward_claimed = true
		if _pressure_gate_visual != null:
			_pressure_gate_visual.visible = false
		if _pressure_gate_collision != null:
			_pressure_gate_collision.disabled = true
		_grant_puzzle_xp(25, "Opened hidden pressure-plate cache")
		print("SYSTEM underground: all pressure plates activated; reward cache revealed.")



func _grant_puzzle_xp(amount: int, reason: String) -> void:
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if progression == null or not progression.has_method("add_experience"):
		push_warning("SYSTEM underground: player progression is unavailable; puzzle XP skipped.")
		return
	progression.call("add_experience", amount, reason)
