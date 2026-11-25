extends SceneTree

func _initialize() -> void:
	call_deferred("_run_validation")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Baghdad Marshland validation failed: " + message)
	quit(1)
	return false


func _run_validation() -> void:
	var reset_exam_save := ConfigFile.new()
	reset_exam_save.set_value("exam", "next_candidate_number", 1001)
	if not _check(reset_exam_save.save("user://system_hunter_exam.cfg") == OK, "Could not reset the isolated Hunter marsh validation save."):
		return
	var packed := load("res://MainScene.tscn") as PackedScene
	if not _check(packed != null, "MainScene could not load."):
		return
	var main := packed.instantiate() as Node3D
	if not _check(main != null, "Main scene root is not Node3D."):
		return
	root.add_child(main)
	for _frame in range(45):
		await process_frame

	var marsh := root.find_child("BaghdadMarshland_AlZawraaReplacement", true, false) as Node3D
	var zone := root.find_child("MesopotamianMarshland", true, false) as Node3D
	var tunnel := root.find_child("BaghdadHunterExaminationTunnel", true, false) as Node3D
	var player := main.get("player") as CharacterBody3D
	var terrain_node := main.find_child("ModernContinent", true, false)
	var exam_manager: Node = main.get("hunter_exam_manager") as Node
	var connector := root.find_child("HunterTunnelToMarshlandPhysicalConnector", true, false) as Node3D
	var trial_start := root.find_child("HunterMarshTrialStartTrigger", true, false) as Area3D
	if not _check(marsh != null and zone != null and tunnel != null and connector != null and trial_start != null and player != null and exam_manager != null, "Marshland, marsh biome, Hunter tunnel or physical connector is missing."):
		return
	if not _check(str(marsh.get_meta("system_replaces_real_place", "")) == "Al-Zawraa Park, Baghdad", "The replacement does not identify Al-Zawraa Park."):
		return
	if not _check(absf(float(marsh.get_meta("system_anchor_latitude", 0.0)) - 33.31496) < 0.00001 and absf(float(marsh.get_meta("system_anchor_longitude", 0.0)) - 44.37818) < 0.00001, "The marsh is not anchored to the approved Al-Zawraa WGS84 coordinate."):
		return
	if not _check(bool(marsh.get_meta("system_hunter_tunnel_connected", false)) and bool(tunnel.get_meta("system_marshland_extension_attached", false)), "The marsh is not connected to the far end of the Hunter tunnel."):
		return
	if not _check(bool(connector.get_meta("system_no_teleport_or_loading_gate", false)), "The tunnel-to-marsh route is not a physical continuous passage."):
		return
	if not _check(trial_start.monitoring and trial_start.body_entered.get_connections().size() > 0 and is_equal_approx(trial_start.global_position.distance_to(tunnel.global_position + Vector3(0.0, 0.0, 94.0)), 0.0), "The continuous Hunter trial does not start at the open far end of the tunnel competition."):
		return
	if not _check(connector.get_meta("system_from", "") == "BaghdadHunterExaminationTunnel" and connector.get_meta("system_to", "") == "BaghdadMarshland_AlZawraaReplacement", "The physical passage does not connect the Hunter tunnel to the Al-Zawraa marshland."):
		return
	if not _check(float(marsh.get_meta("system_geographic_anchor_adjustment_m", 0.0)) <= 300.0, "The marsh anchor moved too far from the real Al-Zawraa Park coordinate."):
		return
	var marsh_center: Vector3 = marsh.get("marsh_center")
	if not _check(terrain_node != null and bool(terrain_node.call("is_land_position", marsh_center.x, marsh_center.z)), "The exact Al-Zawraa anchor is not supported by the playable Baghdad terrain."):
		return
	if not _check(zone.find_child("HunterExamMarshlandFinalObjective", true, false) is Area3D, "The final marshland exam objective is missing."):
		return
	if not _check(zone.find_child("HunterExamMarshlandFinalAltar", true, false) is MeshInstance3D, "The final marshland altar is missing."):
		return
	if not _check(zone.find_children("SeasonalMarshStarGate_*", "Node3D", true, false).size() == 3, "The three seasonal gates are not available."):
		return
	if not _check(zone.find_children("SeasonalMarshStarGate_*", "Node3D", true, false)[0].visible == false, "The hidden Star Gates should remain concealed before exam completion."):
		return
	if not _check(bool(zone.get_meta("system_hunter_exam_biome", false)), "The marsh biome is not marked as part of the Hunter examination."):
		return
	if not _check(int(connector.get_meta("system_passage_segment_count", 0)) >= 20, "The physical passage does not contain enough continuous segments."):
		return
	var water_areas := zone.find_children("MarshWaterArea_*", "Area3D", true, false)
	if not _check(water_areas.size() == 8, "Expected eight marsh water volumes; found %d." % water_areas.size()):
		return
	for water_area in water_areas:
		if not _check(water_area.monitoring and water_area.body_entered.get_connections().size() > 0 and water_area.body_exited.get_connections().size() > 0, "A marsh water volume is missing swimming enter/exit signals."):
			return
	var reeds := zone.get_node_or_null("MarshReedFields") as MultiMeshInstance3D
	if not _check(reeds != null and reeds.multimesh != null and reeds.multimesh.instance_count == 1800, "The 1800-instance marsh reed field is missing."):
		return
	if not _check(zone.find_children("MarshWillow_*", "Node3D", true, false).size() == 56, "Expected 56 marsh willow trees."):
		return
	if not _check(zone.find_children("MarshBoardwalk_*", "MeshInstance3D", true, false).size() == 9 and zone.find_children("MarshBoardwalkCollision_*", "StaticBody3D", true, false).size() == 9, "Expected nine raised boardwalk segments with matching walkable collision."):
		return

	var farm := zone.get_node_or_null("MarshAgriculturalGardens") as Node3D
	if not _check(farm != null and int(farm.get_meta("system_agricultural_plot_count", 0)) == 12 and int(farm.get_meta("system_crop_plant_count", 0)) == 432 and farm.find_children("MarshCropBatch_*", "MultiMeshInstance3D", true, false).size() == 3, "Agricultural plots and crops are missing."):
		return
	if not _check(zone.find_children("MarshGroundFog_*", "MeshInstance3D", true, false).size() == 14, "Expected fourteen low fog layers."):
		return
	if not _check(zone.find_children("HunterExamDeceptionNPC_*", "Node3D", true, false).size() == 12, "Expected twelve deception NPCs."):
		return
	if not _check(zone.find_children("GiantMarshCreature_*", "Node3D", true, false).size() == 6, "Expected six giant marsh wildlife encounters."):
		return
	if not _check(zone.find_children("HunterExamRouteArrow_*", "Node3D", true, false).size() == 9, "Expected nine route arrows."):
		return
	if not _check(zone.find_children("HunterExamWrongRouteHazard_*", "Area3D", true, false).size() == 5, "Expected five wrong-route failure hazards."):
		return
	var sanctuary := zone.get_node_or_null("HiddenMarshAncientSanctuary") as Node3D
	if not _check(sanctuary != null and sanctuary.find_children("SeasonalMarshStarGate_*", "Node3D", true, false).size() == 3, "Hidden ancient sanctuary or its three Star Gates are missing."):
		return
	if not _check(not sanctuary.visible and zone.find_child("HiddenSanctuaryDiscoveryTrigger", true, false) is Area3D, "The ancient sanctuary is not concealed behind its discovery trigger."):
		return
	var spring_destinations: Array = sanctuary.get_node("SeasonalMarshStarGate_00").get_meta("system_gate_destination_pool_by_season").get("spring", [])
	if not _check(spring_destinations == ["Tokyo", "Paris", "Singapore"], "Seasonal Star Gate destination rotation is missing."):
		return

	for creature in zone.find_children("GiantMarshCreature_*", "Node3D", true, false):
		var enemy := creature.get_node_or_null("GiantMarshCombatEnemy") as CharacterBody3D
		if not _check(enemy != null and enemy.is_in_group("system_enemy") and enemy.has_method("take_damage"), "A giant marsh animal is not wired into the combat system."):
			return

	var test_player := CharacterBody3D.new()
	test_player.add_to_group("system_player")
	root.add_child(test_player)
	var decoy_npc := zone.find_child("HunterExamDeceptionNPC_00", true, false) as Node3D
	marsh.call("_on_deception_npc_approached", test_player, decoy_npc)
	if not _check(str(test_player.get_meta("system_hunter_route_hint", "")) == "false" and test_player.has_meta("system_hunter_route_hint_waypoint"), "A deceptive Hunter NPC did not provide a false route hint."):
		return
	var wrong_route := zone.find_child("HunterExamWrongRouteHazard_00", true, false) as Area3D
	marsh.call("_on_wrong_route_hazard_entered", test_player, wrong_route)
	if not _check(str(test_player.get_meta("system_hunter_wrong_route_triggered", "")) == "HunterExamWrongRouteHazard_00", "Entering a forbidden route did not flag the candidate."):
		return
	var first_creature := zone.find_child("GiantMarshCreature_00", true, false) as Node3D
	marsh.call("_on_giant_creature_encounter", test_player, first_creature)
	var first_enemy := first_creature.get_node_or_null("GiantMarshCombatEnemy") as CharacterBody3D
	if not _check(bool(test_player.get_meta("system_hunter_marsh_encounter_active", false)) and first_enemy.get("target") == test_player, "Entering a giant animal encounter did not activate its combat enemy."):
		return
	first_enemy.set_physics_process(false)
	var first_water := water_areas[0] as Area3D
	marsh.call("_on_marsh_water_body_entered", test_player, first_water)
	if not _check(bool(test_player.get_meta("system_swimming", false)) and str(test_player.get_meta("system_swim_source", "")) == "Baghdad Mesopotamian Marshland", "Entering marsh water did not activate the canonical swimming state."):
		return
	marsh.call("_on_marsh_water_body_exited", test_player, first_water)
	if not _check(not bool(test_player.get_meta("system_swimming", false)), "Leaving the final marsh water volume did not clear swimming state."):
		return

	# Verify the actual one-stage Hunter exam remains active after the tunnel section
	# and only completes at the marsh sanctuary, then unlocks a seasonal Star Gate.
	var invitation: Dictionary = exam_manager.call("accept_exam_invitation", "baghdad_marsh_validation")
	if not _check(bool(invitation.get("success", false)), "Hunter exam invitation could not be accepted for the marsh integration test."):
		return
	var registration: Dictionary = exam_manager.call("register_candidate_at_tunnel", "baghdad_marsh_validation")
	if not _check(bool(registration.get("success", false)), "Hunter candidate could not be registered at the tunnel."):
		return
	var start_result: Dictionary = exam_manager.call("begin_exam")
	if not _check(bool(start_result.get("success", false)), "The single Hunter examination did not start."):
		return
	player.set_meta("system_hunter_tunnel_competition_complete", true)
	marsh.call("_on_marsh_trial_start_entered", player)
	marsh.call("_on_hidden_sanctuary_discovered", player, sanctuary)
	if not _check(bool(sanctuary.visible) and bool(player.get_meta("system_hidden_heritage_site_discovered", false)), "The active candidate did not reveal the hidden ancient sanctuary on approach."):
		return
	if not _check(bool(player.get_meta("system_hunter_marsh_trial_started", false)) and bool(exam_manager.get("exam_active")), "The marsh section did not start after tunnel checkpoints while keeping the exam active."):
		return
	marsh.call("_on_marsh_final_trial_entered", player)
	var completed_overview: Dictionary = exam_manager.call("get_exam_overview")
	if not _check(not bool(completed_overview.get("active", true)) and completed_overview.get("completed_stages", []).has("baghdad_tunnel_competition") and bool(player.get_meta("system_hunter_marsh_trial_completed", false)), "The Hunter exam did not complete at the hidden marsh sanctuary."):
		return
	await process_frame
	var first_gate := sanctuary.get_node("SeasonalMarshStarGate_00") as Node3D
	if not _check(first_gate.visible, "The hidden Star Gates did not unlock after the successful marsh exam."):
		return
	var current_season := str(marsh.call("_get_marsh_season"))
	var destination_pool: Dictionary = first_gate.get_meta("system_gate_destination_pool_by_season")
	var expected_destination: String = str(destination_pool.get(current_season, [])[0])
	marsh.call("_on_marsh_star_gate_entered", player, first_gate)
	if not _check(str(player.get_meta("system_last_marsh_star_gate_destination", "")) == expected_destination, "The seasonal Star Gate did not transport the Hunter to its current city destination."):
		return

	print("Baghdad Marshland validation passed: Al-Zawraa agricultural wetland, continuous Hunter tunnel connection, eight swim-enabled pools, 1800 reeds, 56 willows, nine boardwalks, 12 deception NPCs, six giant creatures, 14 fog layers, five wrong-route hazards, hidden sanctuary and three seasonal Star Gates.")
	quit(0)
