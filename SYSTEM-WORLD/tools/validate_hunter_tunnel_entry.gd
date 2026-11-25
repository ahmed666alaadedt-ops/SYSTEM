extends SceneTree

const HunterExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")

func _initialize() -> void:
	call_deferred("_run_validation")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter Tower guide-led tunnel validation failed: " + message)
	quit(1)
	return false


func _run_validation() -> void:
	var reset_config := ConfigFile.new()
	reset_config.set_value("exam", "next_candidate_number", 1001)
	if not _check(reset_config.save("user://system_hunter_exam.cfg") == OK, "Could not reset the isolated Hunter validation save."):
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
	if not _check(arrival != null and guide != null and tunnel != null and player != null and manager != null and operations != null, "Hunter Tower recruitment, guide, tunnel, player or tower operations are missing."):
		return
	var arrival_callback := Callable(main, "_on_hunter_tower_arrival_body_entered")
	if not _check(arrival.body_entered.is_connected(arrival_callback), "Hunter Tower arrival is not connected to the invitation handler."):
		return
	if not _check(main.find_child("HunterExamInvitationPanel", true, false) != null, "The Hunter invitation panel is missing."):
		return
	if not _check(str(tunnel.get_meta("system_hunter_exam_access", "")) == "hunter_tower_recruitment_and_guide_escort", "Tunnel access metadata still points to the obsolete restaurant secret entrance."):
		return
	if not _check(bool(tunnel.get_meta("system_tunnel_is_single_continuous_route", false)), "The tunnel is not marked as one continuous route."):
		return

	var crowd := tunnel.get_node_or_null("HunterCandidateCrowd")
	if not _check(crowd != null, "The tunnel does not contain the 500-candidate population."):
		return
	var crowd_status: Dictionary = crowd.call("get_crowd_status")
	if not _check(int(crowd_status.get("candidate_count", 0)) == 500 and int(crowd_status.get("unique_candidate_numbers", 0)) == 500 and int(crowd_status.get("behavior_profile_count", 0)) == 500, "The tunnel crowd is not 500 individually tracked competitors with behavior profiles."):
		return
	if not _check(bool(tunnel.get_meta("system_hunter_candidate_population_verified", false)), "The tunnel did not mark its 500-candidate population verified."):
		return

	var marshland := tunnel.get_node_or_null("HunterMarshland") as Node3D
	if not _check(marshland != null and bool(tunnel.get_meta("system_tunnel_marshland_connected", false)), "The single Hunter tunnel does not open directly into the Marshland."):
		return
	if not _check(bool(marshland.get_meta("system_marshland_generated", false)) and int(marshland.get_meta("system_marshland_agricultural_plot_count", 0)) == 12 and int(marshland.get_meta("system_marshland_tree_count", 0)) == 168 and int(marshland.get_meta("system_marshland_undergrowth_count", 0)) == 220 and int(marshland.get_meta("system_marshland_reed_cluster_count", 0)) == 96 and int(marshland.get_meta("system_marshland_tree_species_count", 0)) >= 4 and int(marshland.get_meta("system_marshland_understory_species_count", 0)) >= 4 and int(marshland.get_meta("system_marshland_reed_blades_per_cluster", 0)) >= 7 and int(marshland.get_meta("system_marshland_forest_canopy_layers", 0)) >= 3 and str(marshland.get_meta("system_marshland_forest_density_profile", "")) == "dense_mixed_groves_with_walkable_routes", "The agricultural Marshland environment or diverse dense vegetation is incomplete."):
		return
	if not _check(int(marshland.get_meta("system_marshland_water_zone_count", 0)) == 5 and int(marshland.get_meta("system_marshland_giant_turtle_count", 0)) == 3 and int(marshland.get_meta("system_marshland_decoy_npc_count", 0)) == 6, "Marshland water, giant wildlife or misleading resident population is incomplete."):
		return
	if not _check(int(marshland.get_meta("system_marshland_carnivorous_plant_count", 0)) == 12 and bool(marshland.get_meta("system_marshland_running_exam_hazards_enabled", false)), "The carnivorous plant hazards are missing from the running examination route."):
		return
	var carnivorous_count := 0
	for child in marshland.get_children():
		if child is Node3D and child.name.begins_with("CarnivorousExamPlant_"):
			carnivorous_count += 1
			var capture_zone := child.get_node_or_null("CandidateCaptureZone") as Area3D
			if not _check(capture_zone != null and capture_zone.body_entered.get_connections().size() > 0 and bool(child.get_meta("system_hunter_exam_running_hazard", false)), "A carnivorous plant is missing its candidate capture trigger."):
				return
	if not _check(carnivorous_count == 12, "Expected 12 physical carnivorous plant hazards along the running route."):
		return
	if not _check(int(marshland.get_meta("system_marshland_tracking_arrow_count", 0)) == 8 and int(marshland.get_meta("system_marshland_fog_bank_count", 0)) == 14 and bool(marshland.get_meta("system_marshland_exit_gate_present", false)), "The fog, tracking arrows or final Marshland gate are missing."):
		return

	# The ordinary restaurant and its dine-in service remain, but no longer create an exam entrance.
	var restaurant_floor := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 29) as Node3D
	if not _check(restaurant_floor != null and restaurant_floor.get_node_or_null("RestaurantDiningSign") != null, "Shopping Tower restaurant floor 29 was damaged or is missing."):
		return
	if not _check(restaurant_floor.get_node_or_null("HunterExamRestaurantSecretEntrance") == null, "The obsolete secret entrance is still being created in the restaurant."):
		return

	main.call("_on_hunter_tower_arrival_body_entered", player)
	var invitation := main.find_child("HunterExamInvitationPanel", true, false) as Control
	if not _check(invitation != null and invitation.visible, "Entering the Hunter Tower did not display the invitation."):
		return
	var invitation_text := invitation.find_child("InvitationText", true, false) as Label
	var accept_button := invitation.find_child("AcceptHunterExamInvitation", true, false) as Button
	var decline_button := invitation.find_child("DeclineHunterExamInvitation", true, false) as Button
	if not _check(invitation_text != null and invitation_text.text.contains("هل تريد أن تصبح صياداً"), "The invitation does not ask the player to become a Hunter."):
		return
	if not _check(accept_button != null and decline_button != null, "The invitation does not provide explicit accept and decline choices."):
		return

	main.call("_on_hunter_exam_invitation_declined")
	var declined_overview: Dictionary = manager.call("get_exam_overview")
	if not _check(not invitation.visible and not bool(declined_overview.get("invitation_accepted", false)) and int(declined_overview.get("candidate_number", 0)) == 0, "Declining the invitation changed registration or allocated a serial."):
		return
	main.call("_on_hunter_tower_arrival_body_entered", player)
	if not _check(invitation.visible, "The invitation did not reappear on a later visit after declining."):
		return

	main.call("_on_hunter_exam_invitation_accepted")
	var accepted_overview: Dictionary = manager.call("get_exam_overview")
	if not _check(not invitation.visible and bool(accepted_overview.get("invitation_accepted", false)) and not bool(accepted_overview.get("registered", false)), "Accepting the invitation must remain separate from tunnel registration."):
		return
	if not _check(int(accepted_overview.get("candidate_number", 0)) == 0, "A candidate serial was assigned before reaching the tunnel."):
		return
	main.call("_on_hunter_exam_registration_requested")
	if not _check(int(manager.call("get_exam_overview").get("candidate_number", 0)) == 0, "The registration menu allocated a serial before tunnel arrival."):
		return

	player.global_position = guide.global_position + Vector3(0.0, 0.0, 2.0)
	main.call("_start_hunter_guild_escort", guide)
	if not _check(bool(player.get_meta("system_hunter_exam_escort_active", false)) and bool(main.get("hunter_exam_escort_active")), "Interacting with the guide did not start the escorted journey."):
		return
	await create_timer(5.4).timeout

	var registered_overview: Dictionary = manager.call("get_exam_overview")
	var serial := int(registered_overview.get("candidate_number", 0))
	if not _check(bool(registered_overview.get("registered", false)) and serial >= 1001, "The guide did not register the candidate at tunnel arrival. overview=%s escort_active=%s player_inside=%s player_position=%s" % [str(registered_overview), str(main.get("hunter_exam_escort_active")), str(player.get_meta("system_inside_hunter_exam_tunnel", false)), str(player.global_position)]):
		return
	if not _check(bool(player.get_meta("system_inside_hunter_exam_tunnel", false)) and int(player.get_meta("system_hunter_exam_candidate_number", 0)) == serial, "The player or permanent candidate serial was not recorded at tunnel arrival."):
		return
	var tunnel_guide := tunnel.get_node_or_null("HunterGuildGuideAtTunnel") as Area3D
	if not _check(tunnel_guide != null and tunnel_guide.is_in_group("system_interactable") and bool(tunnel.get_meta("system_hunter_exam_guide_present", false)), "The guild guide did not remain available to explain and assist inside the tunnel."):
		return
	if not _check(bool(registered_overview.get("active", false)) and int(registered_overview.get("total_stages", 0)) == 1, "The single continuous tunnel competition did not start."):
		return
	var current_stage: Dictionary = manager.call("get_current_stage")
	if not _check(str(current_stage.get("id", "")) == "baghdad_tunnel_competition", "The active exam is not the single continuous tunnel competition."):
		return

	var runtime := main.get("hunter_exam_stage_runtime") as Node3D
	if not _check(runtime != null and str(runtime.get("active_stage_id")) == "baghdad_tunnel_competition", "The continuous competition environment did not activate at the tunnel."):
		return
	var rival_manager: Node = runtime.get("rival_competition")
	if not _check(is_instance_valid(rival_manager) and int(rival_manager.call("get_competition_status").get("rival_count", 0)) == 5, "The five named rival competitors were not attached to the active tunnel competition."):
		return
	if not _check(player.global_position.distance_to(runtime.to_global(Vector3(0.0, 1.2, 2.0))) < 1.5, "The player was not transferred to the physical competition start."):
		return

	var restored_manager: Node = HunterExamManagerScript.new()
	root.add_child(restored_manager)
	await process_frame
	var restored_overview: Dictionary = restored_manager.call("get_exam_overview")
	if not _check(bool(restored_overview.get("registered", false)) and int(restored_overview.get("candidate_number", 0)) == serial, "The candidate serial did not persist after manager recreation."):
		return
	var repeat_registration: Dictionary = restored_manager.call("register_candidate_at_tunnel", "local_player")
	if not _check(bool(repeat_registration.get("success", false)) and int(repeat_registration.get("candidate_number", 0)) == serial, "Re-entry allocated a second candidate serial."):
		return

	print("Hunter guide-led tunnel validation passed: invitation accept/decline, no pre-arrival serial, real guide-led transfer, one continuous competition, persistent candidate number, 500 individually tracked candidates, five named rivals, and preserved restaurant service.")
	quit(0)
