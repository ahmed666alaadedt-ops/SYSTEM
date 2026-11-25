extends SceneTree

const ExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")
const StageRuntimeScript = preload("res://scripts/system_hunter_exam_stage_runtime.gd")
const CandidateCrowdScript = preload("res://scripts/system_hunter_candidate_crowd.gd")
const CONTINUOUS_STAGE_ID := "baghdad_tunnel_competition"
const EXPECTED_OBJECTIVES: Array[String] = [
	"tunnel_checkpoint_a",
	"tunnel_checkpoint_b",
	"tunnel_finish"
]

func _initialize() -> void:
	call_deferred("_run_validation")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter continuous tunnel competition validation failed: " + message)
	quit(1)
	return false


func _run_validation() -> void:
	var reset_config := ConfigFile.new()
	reset_config.set_value("exam", "next_candidate_number", 1001)
	if not _check(reset_config.save("user://system_hunter_exam.cfg") == OK, "Could not reset the isolated validation save."):
		return

	var manager := ExamManagerScript.new()
	root.add_child(manager)
	await process_frame
	var invitation: Dictionary = manager.accept_exam_invitation("hunter_continuous_validation")
	if not _check(bool(invitation.get("success", false)) and not bool(manager.get_exam_overview().get("registered", true)), "Invitation acceptance incorrectly registered the candidate."):
		return
	if not _check(int(manager.get_exam_overview().get("candidate_number", 0)) == 0, "Invitation acceptance allocated a candidate number too early."):
		return

	var registration: Dictionary = manager.register_candidate_at_tunnel("hunter_continuous_validation")
	if not _check(bool(registration.get("success", false)), "Tunnel registration failed."):
		return
	var serial := int(registration.get("candidate_number", 0))
	if not _check(serial == 1001 and int(manager.get_exam_overview().get("total_stages", 0)) == 1, "The candidate serial or one-stage continuous definition is incorrect."):
		return
	var stage_list: Array = manager.get_exam_overview().get("stages", [])
	if not _check(stage_list.size() == 1 and str(stage_list[0].get("id", "")) == CONTINUOUS_STAGE_ID, "The obsolete seven-stage journey is still active."):
		return

	var restored_manager := ExamManagerScript.new()
	root.add_child(restored_manager)
	await process_frame
	if not _check(bool(restored_manager.get_exam_overview().get("registered", false)) and int(restored_manager.get_exam_overview().get("candidate_number", 0)) == serial, "Candidate serial did not persist across manager recreation."):
		return
	var repeated_registration: Dictionary = restored_manager.register_candidate_at_tunnel("hunter_continuous_validation")
	if not _check(int(repeated_registration.get("candidate_number", 0)) == serial, "Repeated tunnel registration allocated a new serial."):
		return

	var started: Dictionary = manager.begin_exam()
	if not _check(bool(started.get("success", false)) and str(started.get("stage", {}).get("id", "")) == CONTINUOUS_STAGE_ID, "The continuous tunnel competition did not start."):
		return
	if not _check(not bool(started.get("stage", {}).get("description", "").contains("seven")), "The active competition still describes seven separate stages."):
		return

	var player := CharacterBody3D.new()
	player.name = "HunterContinuousValidationPlayer"
	root.add_child(player)
	var runtime := StageRuntimeScript.new()
	runtime.name = "HunterContinuousCompetitionRuntime"
	root.add_child(runtime)
	var activation: Dictionary = runtime.activate_stage(manager.get_current_stage(), player, manager)
	if not _check(bool(activation.get("success", false)) and str(activation.get("stage_id", "")) == CONTINUOUS_STAGE_ID, "The physical continuous tunnel environment failed to activate."):
		return
	var site := runtime.get_node_or_null("ExaminationSite_" + CONTINUOUS_STAGE_ID) as Node3D
	if not _check(site != null and str(site.get_meta("system_exam_stage_id", "")) == CONTINUOUS_STAGE_ID, "The active physical tunnel route is missing."):
		return
	if not _check(bool(site.get_meta("system_marshland_exit_is_physically_open", false)) and is_equal_approx(float(site.get_meta("system_marshland_exit_opening_width_m", 0.0)), 18.0), "The tunnel competition exit is not open and aligned with the 18 m marsh passage."):
		return
	if not _check(site.get_node_or_null("StageNorthBoundaryLeft") != null and site.get_node_or_null("StageNorthBoundaryRight") != null and site.get_node_or_null("MarshlandExitSign") is Label3D, "The physical tunnel exit opening or marshland destination sign is missing."):
		return
	var rival_system: Node = runtime.get("rival_competition")
	if not _check(is_instance_valid(rival_system) and int(rival_system.call("get_competition_status").get("rival_count", 0)) == 5, "The continuous competition does not spawn all five named rivals."):
		return

	var ground_collision := site.get_node_or_null("StageGroundBody/CollisionShape3D") as CollisionShape3D
	if not _check(ground_collision != null and ground_collision.shape != null, "The continuous tunnel route has no physical ground collision."):
		return
	for index in range(EXPECTED_OBJECTIVES.size()):
		var objective := site.get_node_or_null("ObjectiveInteraction_%02d" % index) as Area3D
		if not _check(objective != null and str(objective.get_meta("system_exam_stage_objective", "")) == EXPECTED_OBJECTIVES[index], "A physical checkpoint is missing or out of order at index %d." % index):
			return

	var wrong_order: Dictionary = runtime.handle_interaction(site.get_node("ObjectiveInteraction_01"))
	if not _check(not bool(wrong_order.get("success", false)), "The continuous competition accepted an out-of-order checkpoint."):
		return
	for index in range(EXPECTED_OBJECTIVES.size()):
		var objective := site.get_node("ObjectiveInteraction_%02d" % index)
		var result: Dictionary = runtime.handle_interaction(objective)
		if not _check(bool(result.get("success", false)), "Continuous objective %s failed." % EXPECTED_OBJECTIVES[index]):
			return
		if index == EXPECTED_OBJECTIVES.size() - 1 and not _check(bool(result.get("tunnel_section_completed", false)) and bool(result.get("exam_still_active", false)), "The tunnel checkpoints must finish the tunnel section but keep the continuous exam active for the marshland."):
			return
		if index == EXPECTED_OBJECTIVES.size() - 1 and not _check(bool(player.get_meta("system_hunter_tunnel_competition_complete", false)), "Tunnel checkpoint completion was not recorded on the candidate."):

			return

	var tunnel_section_overview: Dictionary = manager.get_exam_overview()
	if not _check(int(tunnel_section_overview.get("total_stages", 0)) == 1 and tunnel_section_overview.get("completed_stages", []).is_empty(), "The tunnel section incorrectly awarded the final Hunter exam completion before the marshland sanctuary."):
		return
	if not _check(bool(tunnel_section_overview.get("active", false)) and not bool(tunnel_section_overview.get("failed", true)), "The Hunter exam did not remain active after the tunnel section."):
		return
	var final_exam_result: Dictionary = manager.complete_current_stage(CONTINUOUS_STAGE_ID, "HUNTER_TUNNEL_AND_MARSHLAND_SANCTUARY_DISCOVERY")
	if not _check(bool(final_exam_result.get("success", false)) and bool(final_exam_result.get("exam_completed", false)), "The continuous exam did not complete when the candidate reached the marshland sanctuary."):
		return
	var final_overview: Dictionary = manager.get_exam_overview()
	if not _check(final_overview.get("completed_stages", []).size() == 1 and str(final_overview.get("completed_stages", [])[0]) == CONTINUOUS_STAGE_ID, "The single continuous exam was not recorded after the marshland sanctuary objective."):
		return
	if not _check(not bool(final_overview.get("active", true)) and not bool(final_overview.get("failed", true)), "The final competition state is not a successful completion."):
		return
	var after_completion: Dictionary = manager.begin_exam()
	if not _check(not bool(after_completion.get("success", false)) and str(after_completion.get("reason", "")) == "ALL_STAGES_COMPLETED", "A completed continuous competition unexpectedly restarted."):
		return

	var crowd := CandidateCrowdScript.new()
	root.add_child(crowd)
	await process_frame
	var crowd_status: Dictionary = crowd.call("get_crowd_status")
	if not _check(int(crowd_status.get("candidate_count", 0)) == 500 and int(crowd_status.get("unique_candidate_numbers", 0)) == 500 and int(crowd_status.get("body_instances", 0)) == 500 and int(crowd_status.get("head_instances", 0)) == 500, "The 500-candidate crowd is not fully tracked and rendered."):
		return
	crowd.call("_start_staggered_movement_wave")
	var behavior_status: Dictionary = crowd.call("get_crowd_status")
	if not _check(int(behavior_status.get("behavior_profile_count", 0)) == 500 and int(behavior_status.get("decision_count_total", 0)) >= 18, "The 500 candidates did not execute independent movement/decision behavior."):
		return

	print("Hunter continuous tunnel competition validation passed: one continuous competition, three ordered physical checkpoints, persistent candidate serial, 500 independently tracked crowd candidates and five named AI rivals.")
	quit(0)
