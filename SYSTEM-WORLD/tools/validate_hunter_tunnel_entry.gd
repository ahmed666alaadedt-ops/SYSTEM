extends SceneTree

func _initialize() -> void:
	call_deferred("_run_validation")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter tunnel entry validation failed: " + message)
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
	for _frame in range(20):
		await process_frame

	var tunnel := root.find_child("BaghdadHunterExaminationTunnel", true, false) as Node3D
	if not _check(tunnel != null, "Hidden Baghdad tunnel is missing."):
		return
	var door := tunnel.get_node_or_null("ConcealedHunterExamDoor") as Area3D
	var door_collision := tunnel.get_node_or_null("ConcealedDoorCollision") as StaticBody3D
	var wall_frame := tunnel.get_node_or_null("OrdinaryFoundationMasonry") as Node3D
	if not _check(door != null and door_collision != null and wall_frame != null, "Secret door or its masonry frame is missing."):
		return
	for segment_name in ["Left", "Right", "Top", "Bottom"]:
		if not _check(wall_frame.get_node_or_null("FoundationMasonryCollision_" + segment_name) != null, "Concealed doorway masonry frame collision is missing: " + segment_name):
			return
	if not _check(not bool(tunnel.get_meta("system_tunnel_riddle_solved", true)), "Tunnel must start locked."):
		return

	var player: CharacterBody3D = main.get("player") as CharacterBody3D
	var start_position := player.global_position
	main.call("_on_interaction_performed", door, "")
	if not _check(player.global_position.is_equal_approx(start_position), "Player entered before solving the riddle."):
		return
	if not _check(is_instance_valid(door_collision), "Door collision was removed before the riddle."):
		return

	var clue_1 := tunnel.get_node_or_null("HunterRiddleClue_1") as Area3D
	var clue_2 := tunnel.get_node_or_null("HunterRiddleClue_2") as Area3D
	var clue_3 := tunnel.get_node_or_null("HunterRiddleClue_3") as Area3D
	if not _check(clue_1 != null and clue_2 != null and clue_3 != null, "All three hidden clues must exist."):
		return
	var operations := main.find_child("BaghdadTowerOperationsManager", true, false)
	var shopping_tower := root.find_child("ShoppingTower", true, false) as Node3D
	if not _check(operations != null and shopping_tower != null, "Shopping Tower operations or restaurant host is missing."):
		return
	var clue_positions_before: Array[Vector3] = [clue_1.global_position, clue_2.global_position, clue_3.global_position]
	var restaurant_floor := Node3D.new()
	restaurant_floor.name = "InteriorFloor_029"
	restaurant_floor.position = Vector3(0.0, 170.0, 0.0)
	shopping_tower.add_child(restaurant_floor)
	operations.call("_create_restaurant_dining_area", restaurant_floor, 30.0, 29)
	if not _check(bool(restaurant_floor.get_meta("system_hunter_exam_secret_entry", false)), "Restaurant floor 29 did not receive the concealed Hunter tunnel entrance."):
		return
	if not _check(str(tunnel.get_meta("system_tunnel_secret_entry_location", "")) == "shopping_tower_restaurant_floor_29", "Tunnel root is not anchored beneath the Shopping Tower restaurant."):
		return
	if not _check(bool(tunnel.get_meta("system_under_shopping_tower_restaurant", false)), "Tunnel does not report its physical location under the restaurant."):
		return
	if not _check(bool(door.get_meta("system_hidden_restaurant_entry", false)), "Concealed entrance is not tagged as the restaurant entry."):
		return
	if not _check(door.collision_layer == 0 and not door.monitoring, "Restaurant secret entry must remain undetectable before solving the three clues."):
		return
	var hidden_door := tunnel.get_node_or_null("ConcealedHunterDoorSlab") as Node3D
	if not _check(hidden_door != null and hidden_door.global_position.y < restaurant_floor.global_position.y, "Physical concealed door slab is not positioned below the restaurant floor."):
		return
	if not _check(door.global_position.y < restaurant_floor.global_position.y and door.global_position.distance_to(restaurant_floor.global_position) < 30.0, "Restaurant interaction area is not physically positioned at the concealed floor entry."):
		return
	if not _check(clue_1.global_position.is_equal_approx(clue_positions_before[0]) and clue_2.global_position.is_equal_approx(clue_positions_before[1]) and clue_3.global_position.is_equal_approx(clue_positions_before[2]), "Moving the tunnel under the restaurant must not move the three surveyed riverbank clues."):
		return

	main.call("_on_interaction_performed", clue_3, "")
	if not _check(int(tunnel.get_meta("system_tunnel_riddle_progress", -1)) == 0, "Wrong clue order must reset progress."):
		return
	main.call("_on_interaction_performed", clue_1, "")
	main.call("_on_interaction_performed", clue_2, "")
	main.call("_on_interaction_performed", clue_3, "")
	# queue_free() removes the blocking collision at the end of the frame.
	await process_frame
	if not _check(bool(tunnel.get_meta("system_tunnel_riddle_solved", false)), "Correct Eye → River → Crown sequence did not solve the riddle."):
		return
	if not _check(door.collision_layer == 1 and door.monitoring and door.monitorable, "Restaurant secret entry did not become interactable after the riddle was solved."):
		return
	if not _check(hidden_door.global_position.y > restaurant_floor.global_position.y, "Concealed door slab did not rise above the restaurant floor after solving."):
		return
	if not _check(tunnel.get_node_or_null("ConcealedDoorCollision") == null, "Secret door collision did not unlock after solving."):
		return
	var visible_ramp := tunnel.get_node_or_null("HiddenExamPassageRamp_00") as MeshInstance3D
	var ramp_body := tunnel.get_node_or_null("HiddenExamPassageRamp_00_Collision") as StaticBody3D
	if not _check(visible_ramp != null and visible_ramp.visible, "Physical underground passage did not become visible."):
		return
	if not _check(ramp_body != null, "Underground passage physics body is missing."):
		return
	var ramp_collision := ramp_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not _check(ramp_collision != null, "Underground passage collision shape is missing."):
		return
	if not _check(not ramp_collision.disabled, "Underground passage collision remained disabled after reveal."):
		return

	var exam_manager := main.get_node_or_null("SYSTEMHunterExamManager")
	if not _check(exam_manager != null, "Hunter exam manager is missing."):
		return
	var before_registration := player.global_position
	main.call("_on_interaction_performed", door, "")
	if not _check(player.global_position.is_equal_approx(before_registration), "Player entered before Hunter Association registration."):
		return

	exam_manager.set("registered", true)
	exam_manager.set("candidate_number", 9901)
	exam_manager.set("completed_stage_ids", [])
	exam_manager.set("failed", false)
	exam_manager.set("exam_active", false)
	exam_manager.set("current_stage_index", -1)
	main.call("_on_interaction_performed", door, "")
	if not _check(bool(exam_manager.get("exam_active")), "Registered candidate could not start the examination."):
		return
	if not _check(bool(player.get_meta("system_inside_hunter_exam_tunnel", false)), "Player tunnel-entry state was not recorded."):
		return
	if not _check(player.global_position.distance_to(before_registration) > 5.0, "Player was not physically moved to the underground exam entrance."):
		return
	var runtime := tunnel.get_node_or_null("HunterExamStageRuntime")
	if not _check(runtime != null and runtime.get_node_or_null("BaghdadHeritageSite") != null, "Physical Baghdad stage one was not activated after entry."):
		return

	print("Hunter tunnel validation passed: locked door, wrong-order reset, Eye-River-Crown unlock, physical ramp reveal/collision, registration gate and actual player transfer into stage one.")
	quit(0)
