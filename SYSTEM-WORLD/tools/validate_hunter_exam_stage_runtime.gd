extends SceneTree

const ExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")
const StageRuntimeScript = preload("res://scripts/system_hunter_exam_stage_runtime.gd")
const EXPECTED_STAGE_IDS: Array[String] = [
	"baghdad_heritage_trial",
	"cairo_buried_market",
	"alexandria_lighthouse",
	"paris_catacombs",
	"babylon_guardian",
	"tokyo_urban_pursuit",
	"final_survival_route"
]

func _initialize() -> void:
	call_deferred("_run_validation")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter seven-stage runtime validation failed: " + message)
	quit(1)
	return false

func _run_validation() -> void:
	var reset_config := ConfigFile.new()
	reset_config.set_value("exam", "next_candidate_number", 1001)
	if not _check(reset_config.save("user://system_hunter_exam.cfg") == OK, "Could not reset the isolated validation save file."):
		return

	var manager := ExamManagerScript.new()
	root.add_child(manager)
	await process_frame
	var registration: Dictionary = manager.apply_for_exam("hunter_seven_stage_validation")
	if not _check(bool(registration.get("success", false)), "Candidate registration failed."):
		return
	var serial := int(registration.get("candidate_number", 0))
	if not _check(serial >= 1001 and int(registration.get("stages", 0)) == 7, "Registration did not allocate a serial and seven stages."):
		return

	var overview: Dictionary = manager.get_exam_overview()
	var stages: Array = overview.get("stages", [])
	if not _check(int(overview.get("total_stages", 0)) == 7 and stages.size() == EXPECTED_STAGE_IDS.size(), "The Hunter examination must contain exactly seven stages."):
		return
	for index in range(EXPECTED_STAGE_IDS.size()):
		if not _check(str(stages[index].get("id", "")) == EXPECTED_STAGE_IDS[index], "Stage order or identifier mismatch at stage %d." % (index + 1)):
			return

	var repeated_registration: Dictionary = manager.apply_for_exam("hunter_seven_stage_validation")
	if not _check(not bool(repeated_registration.get("success", false)) and int(repeated_registration.get("candidate_number", 0)) == serial, "Repeat registration allocated a new candidate number."):
		return

	var started: Dictionary = manager.begin_exam()
	if not _check(bool(started.get("success", false)) and str(started.get("stage", {}).get("id", "")) == EXPECTED_STAGE_IDS[0], "The examination did not begin at the Baghdad heritage stage."):
		return
	var wrong_order: Dictionary = manager.complete_current_stage(EXPECTED_STAGE_IDS[1], "OUT_OF_ORDER_TEST")
	if not _check(not bool(wrong_order.get("success", false)) and str(wrong_order.get("reason", "")) == "STAGE_ORDER_MISMATCH", "The manager accepted a stage out of sequence."):
		return
	var missing_evidence: Dictionary = manager.complete_current_stage(EXPECTED_STAGE_IDS[0], "")
	if not _check(not bool(missing_evidence.get("success", false)), "The manager accepted an empty evidence record."):
		return

	var player := CharacterBody3D.new()
	player.name = "HunterExamValidationPlayer"
	root.add_child(player)
	var active_manager: Node = manager

	for stage_index in range(EXPECTED_STAGE_IDS.size()):
		var stage_data: Dictionary = active_manager.call("get_current_stage")
		var expected_id := EXPECTED_STAGE_IDS[stage_index]
		if not _check(str(stage_data.get("id", "")) == expected_id, "Current stage did not advance to %s." % expected_id):
			return
		var runtime := StageRuntimeScript.new()
		runtime.name = "ValidationRuntime_" + expected_id
		root.add_child(runtime)
		var activation: Dictionary = runtime.activate_stage(stage_data, player, active_manager)
		if not _check(bool(activation.get("success", false)) and str(activation.get("stage_id", "")) == expected_id, "Physical environment failed to activate for %s." % expected_id):
			return

		var rival_system: Node = runtime.get("rival_competition")
		if not _check(is_instance_valid(rival_system) and int(rival_system.call("get_competition_status").get("rival_count", 0)) == 5, "The named rival competition actors did not initialize for %s." % expected_id):
			return

		if stage_index == 0:
			var site := runtime.get_node_or_null("BaghdadHeritageSite")
			if not _check(site != null, "Baghdad heritage chamber was not built."):
				return
			var floor_collision := site.get_node_or_null("AncientStoneFloorBody/CollisionShape3D") as CollisionShape3D
			if not _check(floor_collision != null and floor_collision.shape != null, "Baghdad chamber floor has no physical collision."):
				return
			var spike_count := 0
			for child in site.get_children():
				if str(child.name).begins_with("StoneTrapSpikeCollision_"):
					spike_count += 1
			if not _check(spike_count == 7, "Baghdad stage must contain seven physical spike obstacles."):
				return
			var relic := site.get_node_or_null("ArtifactPedestal/RecoveredArtifact") as MeshInstance3D
			if not _check(relic != null and not relic.visible, "The Baghdad relic must remain hidden before the three clues."):
				return
			var wrong_clue := site.get_node_or_null("CrownInscription/InscriptionInteraction")
			var wrong_result: Dictionary = runtime.handle_interaction(wrong_clue)
			if not _check(not bool(wrong_result.get("success", false)), "The Baghdad clue sequence accepted the wrong first inscription."):
				return
			for clue_name in ["EyeInscription", "RiverInscription", "CrownInscription"]:
				var clue := site.get_node_or_null(clue_name + "/InscriptionInteraction")
				var clue_result: Dictionary = runtime.handle_interaction(clue)
				if not _check(bool(clue_result.get("success", false)), "The correct Baghdad clue sequence failed at %s." % clue_name):
					return
			if not _check(relic.visible, "The Baghdad relic did not unlock after all three clues."):
				return
			var artifact_area := site.get_node_or_null("ArtifactPedestal/ArtifactInteraction")
			var artifact_result: Dictionary = runtime.handle_interaction(artifact_area)
			if not _check(bool(artifact_result.get("stage_completed", false)), "The Baghdad artifact objective did not complete stage one."):
				return
		else:
			var site_name := "ExaminationSite_" + expected_id
			var site := runtime.get_node_or_null(site_name)
			if not _check(site != null, "Physical stage environment is missing: " + expected_id):
				return
			var floor_collision := site.get_node_or_null("StageGroundBody/CollisionShape3D") as CollisionShape3D
			if not _check(floor_collision != null and floor_collision.shape != null, "Physical ground collision is missing for " + expected_id):
				return
			for objective_index in range(3):
				var objective := site.get_node_or_null("ObjectiveInteraction_%02d" % objective_index)
				if not _check(objective != null, "A sequential physical objective is missing in " + expected_id):
					return
				var objective_result: Dictionary = runtime.handle_interaction(objective)
				if not _check(bool(objective_result.get("success", false)), "Sequential objective %d failed in %s." % [objective_index + 1, expected_id]):
					return
				if objective_index == 2 and not _check(bool(objective_result.get("stage_completed", false)), "Final objective did not advance " + expected_id):
					return

		if stage_index == 0:
			var restored_manager := ExamManagerScript.new()
			root.add_child(restored_manager)
			await process_frame
			var restored_overview: Dictionary = restored_manager.get_exam_overview()
			if not _check(bool(restored_overview.get("registered", false)) and bool(restored_overview.get("active", false)), "Candidate registration/active exam did not persist after stage one."):
				return
			if not _check(int(restored_overview.get("candidate_number", 0)) == serial and restored_overview.get("completed_stages", []).has(EXPECTED_STAGE_IDS[0]), "Candidate serial or Baghdad completion was not persisted."):
				return
			if not _check(str(restored_manager.get_current_stage().get("id", "")) == EXPECTED_STAGE_IDS[1], "Reload did not resume at Cairo after Baghdad."):
				return
			active_manager = restored_manager

		runtime.queue_free()
		await process_frame

	var final_overview: Dictionary = active_manager.call("get_exam_overview")
	if not _check(int(final_overview.get("total_stages", 0)) == 7 and final_overview.get("completed_stages", []).size() == 7, "All seven stages were not recorded as completed."):
		return
	if not _check(not bool(final_overview.get("active", true)) and not bool(final_overview.get("failed", true)), "Exam state is not a successful completed state."):
		return
	var after_completion: Dictionary = active_manager.begin_exam()
	if not _check(not bool(after_completion.get("success", false)) and str(after_completion.get("reason", "")) == "ALL_STAGES_COMPLETED", "A completed examination unexpectedly restarted."):
		return

	print("Hunter seven-stage runtime validation passed: all seven physical environments, ordered objectives, candidate persistence, and final provisional license progression.")
	quit(0)
