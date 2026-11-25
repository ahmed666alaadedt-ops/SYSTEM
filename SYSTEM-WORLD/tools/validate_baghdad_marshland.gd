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
	var connector := root.find_child("HunterTunnelToMarshlandPhysicalConnector", true, false) as Node3D
	var trial_start := root.find_child("HunterMarshTrialStartTrigger", true, false) as Area3D
	if not _check(marsh != null and zone != null and tunnel != null and connector != null and trial_start != null, "Marshland, marsh biome, Hunter tunnel or physical connector is missing."):
		return
	if not _check(str(marsh.get_meta("system_replaces_real_place", "")) == "Al-Zawraa Park, Baghdad", "The replacement does not identify Al-Zawraa Park."):
		return
	if not _check(absf(float(marsh.get_meta("system_anchor_latitude", 0.0)) - 33.31496) < 0.00001 and absf(float(marsh.get_meta("system_anchor_longitude", 0.0)) - 44.37818) < 0.00001, "The marsh is not anchored to the approved Al-Zawraa WGS84 coordinate."):
		return
	if not _check(bool(marsh.get_meta("system_hunter_tunnel_connected", false)) and bool(tunnel.get_meta("system_marshland_extension_attached", false)), "The marsh is not connected to the far end of the Hunter tunnel."):
		return
	if not _check(bool(connector.get_meta("system_no_teleport_or_loading_gate", false)), "The tunnel-to-marsh route is not a physical continuous passage."):
		return
	if not _check(trial_start.monitoring and trial_start.body_entered.get_connections().size() > 0, "The continuous Hunter trial does not start at the tunnel exit."):
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
	if not _check(bool(connector.get_meta("system_no_teleport_or_loading_gate", false)), "The tunnel-to-marsh route is not a physical continuous passage."):
		return
	if not _check(int(connector.get_meta("system_passage_segment_count", 0)) >= 20, "The physical passage does not contain enough continuous segments."):
		return
	var water_areas := zone.find_children("*", "Area3D", true, false)
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
	if not _check(zone.find_children("MarshBoardwalk_*", "MeshInstance3D", true, false).size() == 9, "Expected nine raised boardwalk segments.")
		return

	var farm := zone.get_node_or_null("MarshAgriculturalGardens") as Node3D
	if not _check(farm != null and int(farm.get_meta("system_agricultural_plot_count", 0)) == 12 and int(farm.get_meta("system_crop_plant_count", 0)) == 432, "Agricultural plots and crops are missing."):
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
	var spring_destinations: Array = sanctuary.get_node("SeasonalMarshStarGate_00").get_meta("system_gate_destination_pool_by_season").get("spring", [])
	if not _check(spring_destinations == ["Tokyo", "Paris", "Singapore"], "Seasonal Star Gate destination rotation is missing."):
		return

	var test_player := CharacterBody3D.new()
	test_player.add_to_group("system_player")
	root.add_child(test_player)
	var first_water := water_areas[0] as Area3D
	marsh.call("_on_marsh_water_body_entered", test_player, first_water)
	if not _check(bool(test_player.get_meta("system_swimming", false)) and str(test_player.get_meta("system_swim_source", "")) == "Baghdad Mesopotamian Marshland", "Entering marsh water did not activate the canonical swimming state."):
		return
	marsh.call("_on_marsh_water_body_exited", test_player, first_water)
	if not _check(not bool(test_player.get_meta("system_swimming", false)), "Leaving the final marsh water volume did not clear swimming state."):
		return

	print("Baghdad Marshland validation passed: Al-Zawraa agricultural wetland, continuous Hunter tunnel connection, eight swim-enabled pools, 1800 reeds, 56 willows, nine boardwalks, 12 deception NPCs, six giant creatures, 14 fog layers, five wrong-route hazards, hidden sanctuary and three seasonal Star Gates.")
	quit(0)
