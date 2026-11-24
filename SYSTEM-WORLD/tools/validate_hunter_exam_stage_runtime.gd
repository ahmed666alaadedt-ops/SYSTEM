extends SceneTree

const ExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")
const StageRuntimeScript = preload("res://scripts/system_hunter_exam_stage_runtime.gd")

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var manager := ExamManagerScript.new()
	root.add_child(manager)
	await process_frame
	var registration: Dictionary = manager.apply_for_exam("hunter_stage_validation")
	assert(bool(registration.get("success", false)), "Hunter exam registration failed.")
	var start_result: Dictionary = manager.begin_exam()
	assert(bool(start_result.get("success", false)), "Hunter exam did not start.")
	assert(str(start_result.get("stage", {}).get("id", "")) == "baghdad_heritage_trial", "Wrong first examination stage.")

	var player := CharacterBody3D.new()
	root.add_child(player)
	var runtime := StageRuntimeScript.new()
	root.add_child(runtime)
	var build_result: Dictionary = runtime.activate_stage(manager.get_current_stage(), player, manager)
	assert(bool(build_result.get("success", false)), "Baghdad heritage stage did not build.")
	var site := runtime.get_node_or_null("BaghdadHeritageSite") as Node3D
	assert(site != null, "Physical Baghdad heritage site is missing.")
	assert(site.get_node_or_null("AncientStoneFloorBody/CollisionShape3D") != null, "Heritage floor collision is missing.")
	assert(site.get_node_or_null("NorthWallBody/CollisionShape3D") != null, "Heritage wall collision is missing.")
	assert(site.get_node_or_null("ArtifactPedestal/RecoveredArtifact") != null, "Artifact mesh is missing.")
	assert(not bool(site.get_node("ArtifactPedestal/RecoveredArtifact").visible), "Artifact must remain hidden before the riddle.")
	var spike_count := 0
	for child in site.get_children():
		if str(child.name).begins_with("StoneTrapSpikeCollision_"):
			spike_count += 1
	assert(spike_count == 7, "Physical spike-trap collision count must be seven.")

	var river := site.get_node("RiverInscription/InscriptionInteraction")
	var wrong_result: Dictionary = runtime.handle_interaction(river)
	assert(not bool(wrong_result.get("success", false)), "Wrong inscription order must be rejected.")
	assert(int(wrong_result.get("progress", -1)) == 0, "Wrong inscription must reset clue progress.")

	for objective_path in [
		"EyeInscription/InscriptionInteraction",
		"RiverInscription/InscriptionInteraction",
		"CrownInscription/InscriptionInteraction"
	]:
		var objective := site.get_node(objective_path)
		var result: Dictionary = runtime.handle_interaction(objective)
		assert(bool(result.get("success", false)), "Correct inscription sequence was rejected: " + objective_path)

	assert(bool(site.get_node("ArtifactPedestal/RecoveredArtifact").visible), "Artifact must unlock after all three inscriptions.")
	var artifact_result: Dictionary = runtime.handle_interaction(site.get_node("ArtifactPedestal/ArtifactInteraction"))
	assert(bool(artifact_result.get("success", false)), "Artifact recovery did not complete stage one.")
	assert(bool(artifact_result.get("stage_completed", false)), "Artifact recovery did not report stage completion.")
	assert(manager.completed_stage_ids.has("baghdad_heritage_trial"), "Exam manager did not persist stage-one completion.")
	assert(str(manager.get_current_stage().get("id", "")) == "cairo_buried_market", "Exam progression did not advance to stage two.")

	print("Hunter examination stage validation passed: physical Baghdad chamber, collision, seven spike obstacles, ordered clues, locked artifact and sequential stage completion.")
	quit(0)
