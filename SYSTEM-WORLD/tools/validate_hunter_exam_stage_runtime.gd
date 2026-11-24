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
	if not _check(site.get_node_or_null("AncientStoneFloorBody/CollisionShape3D") != null, "Heritage floor collision is missing."):
		return
	if not _check(site.get_node_or_null("NorthWallBody/CollisionShape3D") != null, "Heritage wall collision is missing."):
		return
	if not _check(site.get_node_or_null("ArtifactPedestal/RecoveredArtifact") != null, "Artifact mesh is missing."):
		return
	if not _check(not bool(site.get_node("ArtifactPedestal/RecoveredArtifact").visible), "Artifact must remain hidden before the riddle."):
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

	print("Hunter examination stage validation passed: physical Baghdad chamber, collision, seven spike obstacles, ordered clues, locked artifact and sequential stage completion.")
	quit(0)
