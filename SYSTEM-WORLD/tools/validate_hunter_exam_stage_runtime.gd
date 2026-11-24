extends SceneTree

const ExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")

func _initialize() -> void:
	call_deferred("_run_validation")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter continuous competition validation failed: " + message)
	quit(1)
	return false


func _run_validation() -> void:
	var manager := ExamManagerScript.new()
	root.add_child(manager)
	await process_frame
	manager.set("candidate_number", 0)
	manager.set("registered", false)
	manager.set("exam_active", false)
	manager.set("current_stage_index", -1)
	manager.set("completed_stage_ids", [])
	manager.set("failed", false)
	manager.set("failure_reason", "")

	var registration: Dictionary = manager.apply_for_exam("hunter_continuous_validation")
	if not _check(bool(registration.get("success", false)), "Candidate registration failed."):
		return
	var serial := int(registration.get("candidate_number", 0))
	if not _check(serial >= 1001, "Candidate serial is not a valid positive sequence number."):
		return
	var overview: Dictionary = manager.get_exam_overview()
	if not _check(int(overview.get("total_stages", 0)) == 1, "Hunter examination must be one continuous competition, not seven stages."):
		return
	var stage: Dictionary = overview.get("stages", [])[0]
	if not _check(str(stage.get("id", "")) == "baghdad_tunnel_competition", "The single competition route has the wrong identifier."):
		return
	if not _check(str(stage.get("type", "")) == "continuous_tunnel_trial", "The examination is not configured as one continuous tunnel trial."):
		return

	var repeated_registration: Dictionary = manager.apply_for_exam("hunter_continuous_validation")
	if not _check(not bool(repeated_registration.get("success", false)), "A repeat registration unexpectedly allocated another candidate number."):
		return
	if not _check(int(repeated_registration.get("candidate_number", 0)) == serial, "The candidate serial changed on repeat registration."):
		return

	var restored_manager := ExamManagerScript.new()
	root.add_child(restored_manager)
	await process_frame
	var restored_overview: Dictionary = restored_manager.get_exam_overview()
	if not _check(bool(restored_overview.get("registered", false)), "Candidate registration did not survive manager recreation."):
		return
	if not _check(int(restored_overview.get("candidate_number", 0)) == serial, "Candidate serial was not persisted across manager recreation."):
		return

	print("Hunter continuous competition validation passed: exactly one continuous tunnel competition and stable persisted candidate serial.")
	quit(0)
