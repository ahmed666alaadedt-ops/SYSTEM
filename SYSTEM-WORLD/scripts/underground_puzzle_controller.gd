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
		print("SYSTEM underground puzzle solved: hidden vault opened.")


func get_progress_text() -> String:
	return str(_entered_sequence.size()) + "/" + str(CORRECT_SEQUENCE.size())
