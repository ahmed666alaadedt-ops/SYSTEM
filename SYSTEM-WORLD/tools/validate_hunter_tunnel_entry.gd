extends SceneTree

func _initialize() -> void:
	call_deferred("_run_validation")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter Tower recruitment validation failed: " + message)
	quit(1)
	return false


func _run_validation() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if not _check(packed != null, "MainScene could not load."):
		return
	var main := packed.instantiate() as Node3D
	if not _check(main != null, "Main scene root is not Node3D."):
		return
	root.add_child(main)
	for _frame in range(30):
		await process_frame

	var arrival := root.find_child("HunterTowerRecruitmentArrivalZone", true, false) as Area3D
	var guide := root.find_child("HunterGuildGuideAtTower", true, false) as Area3D
	var tunnel := root.find_child("BaghdadHunterExaminationTunnel", true, false) as Node3D
	var player := main.get("player") as CharacterBody3D
	if not _check(arrival != null and guide != null and tunnel != null and player != null, "Hunter Tower invitation zone, guild guide, tunnel or player is missing."):
		return
	var arrival_callback := Callable(main, "_on_hunter_tower_arrival_body_entered")
	if not _check(arrival.body_entered.is_connected(arrival_callback), "Player arrival signal is not connected to the Hunter Tower invitation handler."):
		return
	if not _check(main.find_child("HunterExamInvitationPanel", true, false) != null, "The yes/no invitation panel is missing."):
		return
	if not _check(main.has_method("_on_hunter_tower_arrival_body_entered"), "Hunter Tower arrival callback is missing."):
		return

	if not _check(root.find_child("HunterExamPrivateRoom", true, false) == null, "The obsolete restaurant-linked Hunter exam room still exists."):
		return
	if not _check(str(tunnel.get_meta("system_hunter_exam_access", "")) == "hunter_tower_recruitment_and_guide_escort", "Tunnel access is not assigned to the Hunter Tower guide route."):
		return

	var manager: SYSTEMHunterExamManager = main.get("hunter_exam_manager") as SYSTEMHunterExamManager
	if not _check(manager != null, "Hunter exam manager is missing."):
		return
	manager.set("candidate_number", 0)
	manager.set("registered", false)
	manager.set("exam_active", false)
	manager.set("current_stage_index", -1)
	manager.set("completed_stage_ids", [])
	manager.set("failed", false)
	manager.set("failure_reason", "")

	main.call("_on_hunter_tower_arrival_body_entered", player)
	var invitation := main.find_child("HunterExamInvitationPanel", true, false) as Control
	if not _check(invitation.visible, "Entering the Hunter Tower did not display the invitation."):
		return
	var invitation_text := invitation.find_child("InvitationText", true, false) as Label
	if not _check(invitation_text != null and invitation_text.text.contains("هل تريد أن تصبح صياداً"), "Invitation does not ask the player to become a Hunter."):
		return

	main.call("_on_hunter_exam_invitation_accepted")
	if not _check(not invitation.visible, "Accepting the invitation did not close the prompt."):
		return
	var overview: Dictionary = manager.get_exam_overview()
	if not _check(bool(overview.get("registered", false)), "Accepting the invitation did not register the candidate."):
		return
	var serial := int(overview.get("candidate_number", 0))
	if not _check(serial >= 1001, "Registration did not allocate a unique candidate serial."):
		return
	if not _check(bool(player.get_meta("system_hunter_exam_invitation_accepted", false)), "Accepted invitation was not stored on the player session."):
		return

	main.call("_start_hunter_guild_escort", guide)
	if not _check(bool(player.get_meta("system_hunter_exam_escort_active", false)), "The guide did not begin escorting the accepted candidate."):
		return
	await create_timer(10.5).timeout
	if not _check(bool(player.get_meta("system_inside_hunter_exam_tunnel", false)), "The guide did not deliver the player to the examination tunnel."):
		return
	if not _check(player.global_position.distance_to(tunnel.to_global(Vector3(0.0, 0.0, -1.5))) < 3.0, "Player did not arrive at the tunnel entrance."):
		return
	if not _check(int(player.get_meta("system_hunter_exam_candidate_number", 0)) == serial, "The permanent candidate serial was not handed to the player at the tunnel."):
		return
	var saved_overview: Dictionary = manager.get_exam_overview()
	if not _check(int(saved_overview.get("candidate_number", 0)) == serial, "Candidate serial changed during the escort."):
		return

	print("Hunter Tower recruitment validation passed: tower-entry invitation, explicit acceptance, persistent candidate registration, guild-guide escort to the tunnel, and serial delivery at arrival; restaurant access route absent.")
	quit(0)
