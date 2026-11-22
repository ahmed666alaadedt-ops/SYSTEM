extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not load.")
		return
	var main := packed.instantiate() as Node3D
	if main == null:
		_fail("Main scene root is not Node3D.")
		return
	root.add_child(main)
	for _frame in range(18):
		await process_frame

	var operations := main.get_node_or_null("BaghdadTowerOperationsManager")
	var region := main.find_child("ModernWorldRegionManager", true, false)
	var tower_manager := region.get_node_or_null("BaghdadTowerLandmarksManager") if region != null else null
	if operations == null or tower_manager == null:
		_fail("Baghdad tower operations or landmark manager did not initialize.")
		return
	var player := operations.get("player") as Node3D
	if player == null:
		_fail("The active player reference is missing from tower operations.")
		return

	var staff_by_tower: Dictionary = operations.get("staff_by_tower")
	var tower_floor_counts := {
		"hunter_association_tower_baghdad": 200,
		"business_investment_tower_baghdad": 36,
		"shopping_tower_baghdad": 32,
		"entertainment_tower_baghdad": 34,
		"technology_tower_baghdad": 40,
		"power_tower_baghdad": 200
	}
	for tower_id_value in tower_floor_counts.keys():
		var tower_id := str(tower_id_value)
		var staff_ids_for_tower: Array = staff_by_tower.get(tower_id, [])
		var total_floors := int(tower_floor_counts[tower_id])
		if staff_ids_for_tower.is_empty():
			_fail("Tower %s has no persistent duty staff." % tower_id)
			return
		for floor_number in range(1, total_floors + 1):
			var assigned_staff_index := int(operations.call("_get_floor_duty_staff_index", tower_id, floor_number))
			if assigned_staff_index < 0 or assigned_staff_index >= staff_ids_for_tower.size():
				_fail("Tower %s floor %d has no valid persistent duty-staff assignment." % [tower_id, floor_number])
				return

	var floor_specs := [
		["hunter_association_tower_baghdad", 100],
		["business_investment_tower_baghdad", 8],
		["shopping_tower_baghdad", 29],
		["entertainment_tower_baghdad", 18],
		["technology_tower_baghdad", 20],
		["power_tower_baghdad", 1]
	]
	for spec in floor_specs:
		var tower_id := str(spec[0])
		var floor_number := int(spec[1])
		var floor_room := operations.call("_ensure_floor_room", tower_id, floor_number) as Node3D
		if floor_room == null:
			_fail("Could not generate %s floor %d for emergency-exit validation." % [tower_id, floor_number])
			return
		var exit_root := floor_room.get_node_or_null("EmergencyEvacuationExit") as Node3D
		var exit_sensor := floor_room.get_node_or_null("EmergencyExitSensor") as Area3D
		var exit_sign := exit_root.get_node_or_null("EmergencyExitSign") as Label3D if exit_root != null else null
		if exit_root == null or exit_sensor == null or exit_sign == null:
			_fail("Tower %s floor %d is missing its emergency exit, physical sensor or bilingual sign." % [tower_id, floor_number])
			return
		var has_collision := false
		for child in exit_sensor.get_children():
			if child is CollisionShape3D and child.shape != null:
				has_collision = true
		if not has_collision or not exit_sensor.monitoring:
			_fail("Tower %s floor %d has an inactive emergency-exit sensor or missing collision shape." % [tower_id, floor_number])
			return
		if floor_room.get_node_or_null("InteriorWall_15") != null or floor_room.get_node_or_null("InteriorWall_14") == null or floor_room.get_node_or_null("InteriorWall_16") == null:
			_fail("Tower %s floor %d has a blocked or malformed emergency-exit doorway." % [tower_id, floor_number])
			return
		if exit_root.get_node_or_null("EmergencyExitFramePillar_L") == null or exit_root.get_node_or_null("EmergencyExitFramePillar_R") == null or exit_root.get_node_or_null("EmergencyExitBeacon") == null or exit_root.get_node_or_null("EmergencyExitLight") == null:
			_fail("Tower %s floor %d is missing its emergency-exit frame, beacon or light." % [tower_id, floor_number])
			return
		if not bool(exit_sensor.get_meta("system_emergency_exit", false)) or str(exit_sensor.get_meta("system_tower_id", "")) != tower_id or int(exit_sensor.get_meta("system_floor_number", 0)) != floor_number:
			_fail("Tower %s floor %d emergency-exit ownership metadata is invalid." % [tower_id, floor_number])
			return
		if not exit_sign.text.contains("مخرج الطوارئ"):
			_fail("Tower %s floor %d emergency-exit sign is missing Arabic guidance." % [tower_id, floor_number])

	operations.call("open_tower", "shopping_tower_baghdad")
	var restaurant_room := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 29) as Node3D
	var shopping_tower := tower_manager.get_node_or_null("ShoppingTower") as Node3D
	var shopping_lobby := shopping_tower.get_node_or_null("PublicLobby_Blockout") as Node3D if shopping_tower != null else null
	var staff_ids: Array = staff_by_tower.get("shopping_tower_baghdad", [])
	if restaurant_room == null or shopping_lobby == null or staff_ids.size() <= 4:
		_fail("Shopping Tower floor 29, lobby or chef staff record is missing.")
		return
	var restaurant_chef := shopping_tower.find_child("TowerStaff_" + str(staff_ids[4]), true, false) as Node3D
	if restaurant_chef == null:
		_fail("The persistent restaurant chef NPC could not be found.")
		return

	operations.call("_travel_to_floor", "shopping_tower_baghdad", 29)
	var elevator_car := operations.get("active_elevator_car") as Node3D
	if elevator_car == null or restaurant_chef.get_parent() != elevator_car or not bool(restaurant_chef.get_meta("system_staff_in_elevator", false)):
		_fail("The assigned restaurant chef did not board the real Shopping Tower elevator car.")
		return
	await create_timer(3.8).timeout
	var workstation := restaurant_room.get_node_or_null("StaffWorkstation_restaurant_chef") as Node3D
	if restaurant_chef.get_parent() != restaurant_room or workstation == null or not bool(restaurant_chef.get_meta("system_staff_workstation_active", false)):
		_fail("The restaurant chef did not arrive at the floor-29 workstation after riding the elevator.")
		return

	var emergency_sensor := restaurant_room.get_node_or_null("EmergencyExitSensor") as Area3D
	if emergency_sensor == null:
		_fail("Shopping Tower floor 29 emergency-exit sensor is missing.")
		return
	emergency_sensor.body_entered.emit(player)
	await create_timer(3.1).timeout
	if operations.get("active_floor_root") != null or bool(player.get_meta("system_tower_elevator_active", false)):
		_fail("The physical emergency-exit trigger did not complete the safe return to the public lobby.")
		return
	if restaurant_chef.get_parent() != shopping_lobby or restaurant_chef.has_meta("system_staff_duty_floor") or not bool(restaurant_chef.get_meta("system_staff_navigation_enabled", false)) or restaurant_chef.get_meta("system_staff_patrol_waypoints", []).size() < 4:
		_fail("The chef did not ride the elevator back and resume the original lobby patrol.")
		return
	var lobby_customer_count := 0
	for lobby_child in shopping_lobby.get_children():
		if str(lobby_child.name).begins_with("TowerCustomer_"):
			lobby_customer_count += 1
	if lobby_customer_count != 4:
		_fail("Shopping Tower customers did not return to their public lobby; found %d." % lobby_customer_count)
		return

	print("Baghdad tower elevator and emergency safety validation passed: six tower exits, physical exit trigger, floor-29 chef elevator ride, workstation arrival, safe lobby return and four persistent customers.")
	quit(0)

func _fail(message: String) -> void:
	push_error("Baghdad tower elevator safety validation failed: " + message)
	quit(1)
