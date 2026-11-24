extends SceneTree

func _initialize() -> void:
	call_deferred("_run_validation")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter tunnel access validation failed: " + message)
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
	if not _check(tunnel != null, "The permanent Hunter examination tunnel is missing."):
		return
	if not _check(bool(tunnel.get_meta("system_tunnel_is_single_continuous_route", false)), "Tunnel is not marked as one continuous route."):
		return
	if not _check(tunnel.get_node_or_null("HunterGuildGuideInteraction") is Area3D, "Guild guide interaction is missing."):
		return
	if not _check(tunnel.get_node_or_null("HunterExamElevatorReturnButton") is Area3D, "Tunnel return elevator button is missing."):
		return
	if not _check(tunnel.find_child("HunterRiddleClue_1", true, false) == null, "Legacy clue 1 still exists."):
		return
	if not _check(tunnel.find_child("HunterRiddleClue_2", true, false) == null, "Legacy clue 2 still exists."):
		return
	if not _check(tunnel.find_child("HunterRiddleClue_3", true, false) == null, "Legacy clue 3 still exists."):
		return
	if not _check(tunnel.get_node_or_null("ConcealedHunterExamDoor") == null, "Legacy secret door still exists."):
		return

	var operations := main.find_child("BaghdadTowerOperationsManager", true, false)
	var shopping_tower := root.find_child("ShoppingTower", true, false) as Node3D
	var player := main.get("player") as CharacterBody3D
	if not _check(operations != null and shopping_tower != null and player != null, "Restaurant operations, Shopping Tower or player is missing."):
		return

	var restaurant_floor := Node3D.new()
	restaurant_floor.name = "InteriorFloor_029"
	restaurant_floor.position = Vector3(0.0, 170.0, 0.0)
	shopping_tower.add_child(restaurant_floor)
	operations.call("_create_restaurant_dining_area", restaurant_floor, 30.0, 29)
	var private_room := restaurant_floor.get_node_or_null("HunterExamPrivateRoom") as Node3D
	if not _check(private_room != null, "Restaurant floor 29 did not create the dedicated competitor room."):
		return
	var entry := private_room.get_node_or_null("HunterExamPrivateRoomEntry") as Area3D
	var platform := private_room.get_node_or_null("HunterExamElevatorPlatform") as Node3D
	var down_button := private_room.get_node_or_null("HunterExamElevatorDownButton") as Area3D
	if not _check(entry != null and platform != null and down_button != null, "Private room entry or physical elevator components are missing."):
		return
	if not _check(bool(private_room.get_meta("system_hunter_exam_room_access_requires_served_meal", false)), "Room does not declare its meal-delivery access gate."):
		return
	if not _check(bool(tunnel.get_meta("system_under_shopping_tower_restaurant", false)), "Tunnel is not physically linked below the restaurant room."):
		return

	var start_position := player.global_position
	operations.set("active_floor_root", restaurant_floor)
	var table_node := restaurant_floor.get_node_or_null("RestaurantTable_00") as Node3D
	if not _check(table_node != null, "Restaurant table for meal handoff is missing."):
		return
	player.set_meta("system_restaurant_seated_table_id", "qa_restaurant_table")
	player.set_meta("system_restaurant_table_node", "RestaurantTable_00")
	var meal_presentation := Node3D.new()
	meal_presentation.name = "ServedMealPresentation"
	table_node.add_child(meal_presentation)
	var saved_orders: Dictionary = operations.get("restaurant_orders")
	saved_orders["qa_restaurant_table"] = {"status":"preparing","meal_consumed":false,"npc_order":false}
	operations.set("restaurant_orders", saved_orders)
	main.call("_on_interaction_performed", entry, "")
	if not _check(player.global_position.is_equal_approx(start_position), "Room opened before the waiter delivered the meal."):
		return

	saved_orders["qa_restaurant_table"] = {"status":"served","meal_consumed":false,"npc_order":false}
	operations.set("restaurant_orders", saved_orders)
	main.call("_on_interaction_performed", entry, "")
	if not _check(player.global_position.distance_to(private_room.global_position) < 12.0, "Player was not transferred into the private competitor room after meal delivery."):
		return
	if not _check(str(player.get_meta("system_hunter_exam_meal_order_id", "")).begins_with("qa_restaurant"), "Meal order identity was not carried into the room."):
		return
	if not _check(private_room.get_node_or_null("ServedMealPresentation") != null, "Served meal presentation was not transferred from the dining table into the private room."):
		return
	if not _check(bool(operations.get("restaurant_orders").get("qa_restaurant_table", {}).get("hunter_exam_room_delivery", false)), "Restaurant order did not record the room delivery handoff."):
		return

	main.call("_on_interaction_performed", down_button, "")
	await create_timer(4.3).timeout
	if not _check(bool(player.get_meta("system_inside_hunter_exam_tunnel", false)), "Elevator did not deliver the player into the tunnel."):
		return
	if not _check(bool(platform.get_meta("system_hunter_exam_elevator_at_bottom", false)), "Elevator platform did not reach the lower stop."):
		return
	var guide := tunnel.get_node_or_null("HunterGuildGuideInteraction") as Area3D
	main.call("_on_interaction_performed", guide, "")
	var exam_manager := main.get_node_or_null("SYSTEMHunterExamManager")
	if not _check(exam_manager != null and bool(exam_manager.get_exam_overview().get("registered", false)), "Guild guide did not register the arriving competitor."):
		return
	var first_number := int(exam_manager.get_exam_overview().get("candidate_number", 0))
	if not _check(first_number > 0, "A unique positive competitor serial was not assigned."):
		return
	main.call("_on_interaction_performed", guide, "")
	var second_number := int(exam_manager.get_exam_overview().get("candidate_number", 0))
	if not _check(first_number == second_number, "Re-entering the guide changed the competitor serial."):
		return
	if not _check(main.get("hunter_exam_stage_runtime") == null, "The new tunnel flow unexpectedly started the legacy seven-stage runtime."):
		return

	var return_button := tunnel.get_node_or_null("HunterExamElevatorReturnButton") as Area3D
	main.call("_on_interaction_performed", return_button, "")
	await create_timer(4.3).timeout
	if not _check(not bool(player.get_meta("system_inside_hunter_exam_tunnel", false)), "Return elevator did not bring the player back to the restaurant room."):
		return
	if not _check(not bool(platform.get_meta("system_hunter_exam_elevator_at_bottom", true)), "Elevator platform did not return to the upper stop."):
		return

	print("Hunter tunnel access validation passed: served-meal room gate, physical down/up elevator, single permanent tunnel, guild guide registration and stable competitor serial; legacy clue/secret-door/seven-stage path is not used.")
	quit(0)
