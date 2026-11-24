extends SceneTree

const ExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")
const StageRuntimeScript = preload("res://scripts/system_hunter_exam_stage_runtime.gd")

func _initialize() -> void:
	call_deferred("_run_validation")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter examination stage validation failed: " + message)
	quit(1)
	return false

func _run_validation() -> void:
	var manager := ExamManagerScript.new()
	root.add_child(manager)
	await process_frame
	# Isolate this regression from any prior user:// exam save created by other QA runs.
	manager.set("candidate_number", 0)
	manager.set("registered", false)
	manager.set("exam_active", false)
	manager.set("current_stage_index", -1)
	manager.set("completed_stage_ids", [])
	manager.set("failed", false)
	manager.set("failure_reason", "")
	var registration: Dictionary = manager.apply_for_exam("hunter_stage_validation")
	if not _check(bool(registration.get("success", false)), "Hunter exam registration failed."):
		return
	var start_result: Dictionary = manager.begin_exam()
	if not _check(bool(start_result.get("success", false)), "Hunter exam did not start."):
		return
	if not _check(str(start_result.get("stage", {}).get("id", "")) == "baghdad_heritage_trial", "Wrong first examination stage."):
		return

	var player := CharacterBody3D.new()
	root.add_child(player)
	var runtime := StageRuntimeScript.new()
	root.add_child(runtime)
	var build_result: Dictionary = runtime.activate_stage(manager.get_current_stage(), player, manager)
	if not _check(bool(build_result.get("success", false)), "Baghdad heritage stage did not build."):
		return
	var site := runtime.get_node_or_null("BaghdadHeritageSite") as Node3D
	if not _check(site != null, "Physical Baghdad heritage site is missing."):
		return
	var floor_body := site.get_node_or_null("AncientStoneFloorBody") as StaticBody3D
	if not _check(floor_body != null, "Heritage floor physics body is missing."):
		return
	if not _check(floor_body.get_child_count() > 0 and floor_body.get_child(0) is CollisionShape3D, "Heritage floor collision shape is missing."):
		return
	var north_wall_body := site.get_node_or_null("NorthWallBody") as StaticBody3D
	if not _check(north_wall_body != null, "Heritage north-wall physics body is missing."):
		return
	if not _check(north_wall_body.get_child_count() > 0 and north_wall_body.get_child(0) is CollisionShape3D, "Heritage north-wall collision shape is missing."):
		return
	if not _check(site.get_node_or_null("ArtifactPedestal/RecoveredArtifact") != null, "Artifact mesh is missing."):
		return
	if not _check(not bool(site.get_node("ArtifactPedestal/RecoveredArtifact").visible), "Artifact must remain hidden before the riddle."):
		return
	var examiner := site.get_node_or_null("ExaminerRaed") as Node3D
	if not _check(examiner != null, "Original SYSTEM stage examiner is missing."):
		return
	var briefing_area := examiner.get_node_or_null("ExaminerBriefingInteraction") as Area3D
	if not _check(briefing_area != null, "Examiner briefing interaction is missing."):
		return
	var briefing_result: Dictionary = runtime.handle_interaction(briefing_area)
	if not _check(bool(briefing_result.get("success", false)) and str(briefing_result.get("message", "")).contains("راقب الأرض"), "Examiner briefing did not explain observation and trap rules."):
		return
	var spike_count := 0
	for child in site.get_children():
		if str(child.name).begins_with("StoneTrapSpikeCollision_"):
			spike_count += 1
	if not _check(spike_count == 7, "Physical spike-trap collision count must be seven."):
		return

	var river := site.get_node("RiverInscription/InscriptionInteraction")
	var wrong_result: Dictionary = runtime.handle_interaction(river)
	if not _check(not bool(wrong_result.get("success", false)), "Wrong inscription order must be rejected."):
		return
	if not _check(int(wrong_result.get("progress", -1)) == 0, "Wrong inscription must reset clue progress."):
		return

	for objective_path in [
		"EyeInscription/InscriptionInteraction",
		"RiverInscription/InscriptionInteraction",
		"CrownInscription/InscriptionInteraction"
	]:
		var objective := site.get_node(objective_path)
		var result: Dictionary = runtime.handle_interaction(objective)
		if not _check(bool(result.get("success", false)), "Correct inscription sequence was rejected: " + objective_path):
			return

	if not _check(bool(site.get_node("ArtifactPedestal/RecoveredArtifact").visible), "Artifact must unlock after all three inscriptions."):
		return
	var artifact_result: Dictionary = runtime.handle_interaction(site.get_node("ArtifactPedestal/ArtifactInteraction"))
	if not _check(bool(artifact_result.get("success", false)), "Artifact recovery did not complete stage one."):
		return
	if not _check(bool(artifact_result.get("stage_completed", false)), "Artifact recovery did not report stage completion."):
		return
	if not _check(manager.completed_stage_ids.has("baghdad_heritage_trial"), "Exam manager did not persist stage-one completion."):
		return
	if not _check(str(manager.get_current_stage().get("id", "")) == "cairo_buried_market", "Exam progression did not advance to stage two."):
		return

	var remaining_stage_objectives := {
		"cairo_buried_market":["cairo_route_a","cairo_route_b","cairo_exit"],
		"alexandria_lighthouse":["alex_beacon","alex_rescue","alex_lighthouse"],
		"paris_catacombs":["paris_echo_a","paris_echo_b","paris_exit"],
		"babylon_guardian":["babylon_gear_a","babylon_gear_b","babylon_seal"],
		"tokyo_urban_pursuit":["tokyo_trace_a","tokyo_civilian","tokyo_finish"],
		"final_survival_route":["highland_supply","highland_shelter","highland_summit"]
	}
	for stage_id in remaining_stage_objectives.keys():
		var stage_data: Dictionary = manager.get_current_stage()
		if not _check(str(stage_data.get("id","")) == stage_id, "Examination stage order mismatch before " + stage_id):
			return
		var next_runtime := StageRuntimeScript.new()
		root.add_child(next_runtime)
		var next_build: Dictionary = next_runtime.activate_stage(stage_data,player,manager)
		if not _check(bool(next_build.get("success",false)), "Physical environment failed to build for " + stage_id):
			return
		var next_site := next_runtime.get_node_or_null("ExaminationSite_" + stage_id) as Node3D
		if not _check(next_site != null, "Physical stage geometry missing for " + stage_id):
			return
		if not _check(next_site.get_node_or_null("StageGroundBody/CollisionShape3D") != null, "Stage ground collision missing for " + stage_id):
			return
		if not _check(next_site.get_node_or_null("StageExaminer") != null, "Stage examiner missing for " + stage_id):
			return
		var expected_objectives: Array = remaining_stage_objectives[stage_id]
		var objective_areas: Array[Area3D] = []
		for child in next_site.get_children():
			if child is Area3D and str(child.get_meta("system_exam_stage_objective","")) in expected_objectives:
				objective_areas.append(child as Area3D)
		if not _check(objective_areas.size() == 3, "Three physical objectives missing for " + stage_id):
			return
		var wrong_attempt: Dictionary = next_runtime.handle_interaction(objective_areas[1])
		if not _check(not bool(wrong_attempt.get("success",false)), "Out-of-order objective accepted for " + stage_id):
			return
		for objective_index in range(expected_objectives.size()):
			var objective_area: Area3D = null
			for candidate in objective_areas:
				if str(candidate.get_meta("system_exam_stage_objective","")) == str(expected_objectives[objective_index]):
					objective_area = candidate
					break
			if not _check(objective_area != null, "Objective order node missing for " + stage_id):
				return
			var objective_result: Dictionary = next_runtime.handle_interaction(objective_area)
			if not _check(bool(objective_result.get("success",false)), "Objective rejected in " + stage_id + ": " + str(expected_objectives[objective_index])):
				return
			if objective_index == expected_objectives.size()-1 and not _check(bool(objective_result.get("stage_completed",false)), "Final objective did not complete " + stage_id):
				return
		if not _check(manager.completed_stage_ids.has(stage_id), "Exam manager did not record " + stage_id):
			return
		next_runtime.queue_free()
		await process_frame
	if not _check(manager.completed_stage_ids.size() == 7, "All seven examination stages were not recorded."):
		return
	if not _check(not bool(manager.get_current_stage()), "Exam should not expose another stage after the seventh completion."):
		return

	print("Hunter examination validation passed: Baghdad plus six additional physical environments, objective-order enforcement and all seven sequential stage completions.")
	quit(0)
