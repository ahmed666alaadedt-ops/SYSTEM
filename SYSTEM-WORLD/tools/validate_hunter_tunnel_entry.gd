extends SceneTree

const HunterExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")

func _initialize() -> void:
	call_deferred("_run_validation")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter hidden restaurant entrance validation failed: " + message)
	quit(1)
	return false


func _run_validation() -> void:
	var reset_config := ConfigFile.new()
	reset_config.set_value("exam", "next_candidate_number", 1001)
	if not _check(reset_config.save("user://system_hunter_exam.cfg") == OK, "Could not reset the isolated Hunter exam validation save."):
		return

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
	var manager: Node = main.get("hunter_exam_manager") as Node
	var operations: Node = main.get("tower_operations_manager") as Node
	if not _check(arrival != null and guide != null and tunnel != null and player != null and manager != null and operations != null, "Hunter Tower, restaurant operations, tunnel or player is missing."):
		return
	var arrival_callback := Callable(main, "_on_hunter_tower_arrival_body_entered")
	if not _check(arrival.body_entered.is_connected(arrival_callback), "Player arrival signal is not connected to the Hunter Tower invitation handler."):
		return
	if not _check(main.find_child("HunterExamInvitationPanel", true, false) != null, "The yes/no invitation panel is missing."):
		return
	if not _check(str(tunnel.get_meta("system_hunter_exam_access", "")) == "shopping_tower_restaurant_three_clue_secret_entrance", "The underground tunnel is not assigned to the concealed restaurant entrance."):
		return
	if not _check(bool(tunnel.get_meta("system_hunter_candidate_population_verified", false)) and int(tunnel.get_meta("system_hunter_candidate_count", 0)) == 500, "The tunnel did not initialize its verified 500-candidate population."):
		return
	if not _check(root.find_child("HunterExamPrivateRoom", true, false) == null, "The obsolete restaurant-linked Hunter exam private room still exists."):
		return

	var initial_crowd := tunnel.get_node_or_null("HunterCandidateCrowd")
	if not _check(initial_crowd != null, "The physical tunnel does not contain its candidate crowd."):
		return
	var crowd_status: Dictionary = initial_crowd.call("get_crowd_status")
	if not _check(int(crowd_status.get("candidate_count", 0)) == 500 and int(crowd_status.get("unique_candidate_numbers", 0)) == 500 and int(crowd_status.get("behavior_profile_count", 0)) == 500, "The tunnel crowd does not contain 500 individually tracked candidates with individual behavior profiles."):
		return

	main.call("_on_hunter_tower_arrival_body_entered", player)
	var invitation := main.find_child("HunterExamInvitationPanel", true, false) as Control
	if not _check(invitation.visible, "Entering the Hunter Tower did not display the invitation."):
		return
	var invitation_text := invitation.find_child("InvitationText", true, false) as Label
	var accept_button := invitation.find_child("AcceptHunterExamInvitation", true, false) as Button
	var decline_button := invitation.find_child("DeclineHunterExamInvitation", true, false) as Button
	if not _check(invitation_text != null and invitation_text.text.contains("هل تريد أن تصبح صياداً"), "Invitation does not ask the player to become a Hunter."):
		return
	if not _check(accept_button != null and decline_button != null, "Invitation does not provide explicit accept and decline choices."):
		return
	main.call("_on_hunter_exam_invitation_declined")
	if not _check(not invitation.visible and not bool(manager.call("get_exam_overview").get("invitation_accepted", false)), "Declining the invitation incorrectly accepted or registered the candidate."):
		return
	main.call("_on_hunter_tower_arrival_body_entered", player)
	if not _check(invitation.visible, "The invitation did not reappear after the player returned to the tower entrance."):
		return

	player.global_position = arrival.global_position
	main.call("_on_hunter_exam_invitation_accepted")
	if not _check(not invitation.visible, "Accepting the invitation did not close the prompt."):
		return
	var accepted_overview: Dictionary = manager.call("get_exam_overview")
	if not _check(bool(accepted_overview.get("invitation_accepted", false)) and not bool(accepted_overview.get("registered", false)), "Invitation acceptance must remain separate from formal Association registration."):
		return
	if not _check(int(accepted_overview.get("candidate_number", 0)) == 0, "Candidate serial was assigned before formal Association registration."):
		return

	player.global_position = guide.global_position + Vector3(0.0, 0.0, 2.0)
	main.call("_start_hunter_guild_escort", guide)
	if not _check(not bool(player.get_meta("system_inside_hunter_exam_tunnel", false)) and not bool(player.get_meta("system_hunter_exam_escort_active", false)), "The guild guide bypassed the concealed restaurant entrance or teleported the player directly into the tunnel."):
		return
	var prompt_label := main.get("interaction_prompt_label") as Label
	if not _check(prompt_label != null and prompt_label.text.contains("مطعم برج التسوق"), "The guild guide did not direct the candidate to the Shopping Tower restaurant."):
		return

	var restaurant_floor := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 29) as Node3D
	if not _check(restaurant_floor != null and restaurant_floor.get_node_or_null("RestaurantDiningSign") != null, "Shopping Tower restaurant floor 29 could not be generated."):
		return
	var entrance := restaurant_floor.get_node_or_null("HunterExamRestaurantSecretEntrance") as Node3D
	if not _check(entrance != null and entrance.has_method("handle_interaction"), "The concealed restaurant entrance controller is missing."):
		return
	var clue_eye := entrance.get_node_or_null("ClueEye/ClueInteraction") as Area3D
	var clue_river := entrance.get_node_or_null("ClueRiver/ClueInteraction") as Area3D
	var clue_crown := entrance.get_node_or_null("ClueCrown/ClueInteraction") as Area3D
	var door_interaction := entrance.get_node_or_null("OrdinaryFoundationMasonry/SecretDoorInteraction") as Area3D
	if not _check(clue_eye != null and clue_river != null and clue_crown != null and door_interaction != null, "The three ordered stone clues or disguised foundation door are missing."):
		return

	main.call("_on_interaction_performed", clue_crown, "shopping_tower_baghdad_floor_29")
	var reset_status: Dictionary = entrance.call("get_secret_entrance_status")
	if not _check(int(reset_status.get("clue_progress", -1)) == 0 and not bool(reset_status.get("riddle_solved", true)), "An incorrect first clue did not reset the riddle sequence."):
		return
	for clue in [clue_eye, clue_river, clue_crown]:
		main.call("_on_interaction_performed", clue, "shopping_tower_baghdad_floor_29")
	var solved_status: Dictionary = entrance.call("get_secret_entrance_status")
	if not _check(bool(solved_status.get("riddle_solved", false)), "Eye → River → Crown did not solve the restaurant riddle."):
		return
	if not _check(not bool(solved_status.get("registered", true)) and not bool(solved_status.get("door_unlocked", true)), "The secret entrance opened before formal Hunter Association registration."):
		return
	main.call("_on_interaction_performed", door_interaction, "shopping_tower_baghdad_floor_29")
	var blocked_status: Dictionary = entrance.call("get_secret_entrance_status")
	if not _check(not bool(blocked_status.get("door_unlocked", true)), "The door ignored the Hunter Association registration prerequisite."):
		return

	player.global_position = arrival.global_position
	main.call("_on_hunter_exam_registration_requested")
	var registered_overview: Dictionary = manager.call("get_exam_overview")
	var serial := int(registered_overview.get("candidate_number", 0))
	if not _check(bool(registered_overview.get("registered", false)) and serial >= 1001, "Formal registration at the Hunter Association did not allocate a permanent serial."):
		return
	if not _check(int(player.get_meta("system_hunter_exam_candidate_number", 0)) == serial, "The Hunter Association did not attach the candidate serial to the player."):
		return

	player.global_position = door_interaction.global_position + Vector3(0.0, 0.0, 0.5)
	main.call("_on_interaction_performed", door_interaction, "shopping_tower_baghdad_floor_29")
	await create_timer(1.25).timeout
	var revealed_status: Dictionary = entrance.call("get_secret_entrance_status")
	var door_collision := entrance.get_node_or_null("OrdinaryFoundationMasonry/ConcealedDoorCollision/DoorCollisionShape") as CollisionShape3D
	var door_panel := entrance.get_node_or_null("OrdinaryFoundationMasonry/ConcealedStoneSlab") as MeshInstance3D
	var elevator := entrance.get_node_or_null("HunterSecretDescentElevator") as Node3D
	if not _check(bool(revealed_status.get("door_unlocked", false)) and door_collision != null and door_collision.disabled and door_panel != null and door_panel.position.y > 2.7 and elevator != null and elevator.visible, "Correct clues plus Association registration did not physically reveal the stone door and elevator. status=%s collision=%s disabled=%s panel_y=%s elevator=%s visible=%s" % [str(revealed_status), str(door_collision != null), str(door_collision.disabled if door_collision != null else false), str(door_panel.position.y if door_panel != null else -999.0), str(elevator != null), str(elevator.visible if elevator != null else false)]):
		return

	main.call("_on_interaction_performed", door_interaction, "shopping_tower_baghdad_floor_29")
	var descent_status: Dictionary = entrance.call("get_secret_entrance_status")
	if not _check(bool(descent_status.get("descent_in_progress", false)), "The revealed secret entrance did not start its physical elevator descent."):
		return
	await create_timer(7.6).timeout
	var tunnel_destination := tunnel.to_global(Vector3(0.0, 1.0, -1.5))
	if not _check(bool(player.get_meta("system_inside_hunter_exam_tunnel", false)), "The elevator did not deliver the player into the underground examination tunnel."):
		return
	if not _check(player.global_position.distance_to(tunnel_destination) < 3.0, "The player did not arrive at the physical tunnel entrance."):
		return
	var arrived_overview: Dictionary = manager.call("get_exam_overview")
	if not _check(bool(arrived_overview.get("registered", false)) and int(arrived_overview.get("candidate_number", 0)) == serial and int(player.get_meta("system_hunter_exam_candidate_number", 0)) == serial, "The permanent Association candidate serial changed during the descent."):
		return
	var restored_manager: Node = HunterExamManagerScript.new()
	root.add_child(restored_manager)
	await process_frame
	var restored_overview: Dictionary = restored_manager.call("get_exam_overview")
	if not _check(bool(restored_overview.get("registered", false)) and int(restored_overview.get("candidate_number", 0)) == serial, "Candidate serial did not persist across manager recreation."):
		return
	var repeat_registration: Dictionary = restored_manager.call("register_candidate_at_tunnel", "local_player")
	if not _check(int(repeat_registration.get("candidate_number", 0)) == serial, "Re-entry allocated a different candidate serial."):
		return

	main.call("_on_hunter_exam_start_requested")
	await process_frame
	await process_frame
	var started_overview: Dictionary = manager.call("get_exam_overview")
	var stage_runtime: Node3D = main.get("hunter_exam_stage_runtime") as Node3D
	if not _check(bool(started_overview.get("active", false)) and str(manager.call("get_current_stage").get("id", "")) == "baghdad_heritage_trial", "The exam did not start at the Baghdad first stage after the hidden descent."):
		return
	if not _check(stage_runtime != null and str(stage_runtime.get("active_stage_id")) == "baghdad_heritage_trial", "The first physical stage environment did not activate from the hidden tunnel."):
		return

	print("Hunter hidden restaurant entrance validation passed: invitation, formal tower registration, wrong-order reset, Eye → River → Crown, registration-gated stone reveal, physical elevator descent, 500 tunnel competitors, permanent candidate serial and Baghdad stage-one activation.")
	quit(0)
