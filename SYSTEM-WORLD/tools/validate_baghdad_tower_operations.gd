extends SceneTree

const TOWER_IDS := [
	"hunter_association_tower_baghdad",
	"business_investment_tower_baghdad",
	"shopping_tower_baghdad",
	"entertainment_tower_baghdad",
	"technology_tower_baghdad",
	"power_tower_baghdad"
]

const NODE_NAMES := {
	"hunter_association_tower_baghdad": "HunterAssociationTower",
	"business_investment_tower_baghdad": "BusinessInvestmentTower",
	"shopping_tower_baghdad": "ShoppingTower",
	"entertainment_tower_baghdad": "EntertainmentTower",
	"technology_tower_baghdad": "TechnologyTower",
	"power_tower_baghdad": "PowerTower"
}

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
	if operations == null:
		_fail("BaghdadTowerOperationsManager was not initialized.")
		return
	var player: CharacterBody3D = main.get("player") as CharacterBody3D
	if player == null:
		_fail("Player character was not initialized for tower operations validation.")
		return
	var status: Dictionary = operations.call("get_operations_status")
	var schedule_expectations := {
		8: "cafe",
		11: "browse",
		15: "social",
		19: "leisure",
		23: "quiet"
	}
	for schedule_hour in schedule_expectations.keys():
		var actual_phase := str(operations.call("get_customer_schedule_phase", int(schedule_hour)))
		if actual_phase != str(schedule_expectations[schedule_hour]):
			_fail("Baghdad customer daily routine phase is incorrect at hour %d: %s." % [int(schedule_hour), actual_phase])
			return
	operations.call("_move_customer_visitors")
	var scheduled_customer_count := 0
	for tower_id in ["hunter_association_tower_baghdad", "business_investment_tower_baghdad", "shopping_tower_baghdad", "entertainment_tower_baghdad", "technology_tower_baghdad"]:
		var customer_tower := operations.get("tower_nodes").get(tower_id) as Node3D
		var customer_lobby := customer_tower.get_node_or_null("PublicLobby_Blockout") as Node3D if customer_tower != null else null
		if customer_lobby == null:
			_fail("Customer daily routine test could not find lobby for " + tower_id)
			return
		for customer_node in customer_lobby.get_children():
			if str(customer_node.name).begins_with("TowerCustomer_"):
				if not customer_node.has_meta("system_customer_schedule_phase") or not customer_node.has_meta("system_customer_schedule_target") or not customer_node.has_meta("system_customer_schedule_action"):
					_fail("Customer NPC is missing its daily schedule state: " + str(customer_node.name))
					return
				scheduled_customer_count += 1
	if scheduled_customer_count != 20:
		_fail("Expected 20 customer NPCs with active daily routine states; found %d." % scheduled_customer_count)
		return
	var routine_tower := operations.get("tower_nodes").get("hunter_association_tower_baghdad") as Node3D
	var routine_lobby := routine_tower.get_node_or_null("PublicLobby_Blockout") as Node3D if routine_tower != null else null
	var routine_customer: Node3D = null
	if routine_lobby != null:
		for routine_child in routine_lobby.get_children():
			if str(routine_child.name).begins_with("TowerCustomer_"):
				routine_customer = routine_child as Node3D
				break
	if routine_customer == null:
		_fail("Customer routine movement regression could not find a persistent lobby customer.")
		return
	var routine_start_position := routine_customer.position
	operations.call("_move_customer_visitors", 8)
	var cafe_target: Vector3 = routine_customer.get_meta("system_customer_schedule_target", Vector3.ZERO)
	var cafe_tween: Variant = routine_customer.get_meta("system_customer_move_tween", null)
	if str(routine_customer.get_meta("system_customer_schedule_phase", "")) != "cafe" or str(routine_customer.get_meta("system_customer_schedule_action", "")) != "having_breakfast" or not (cafe_tween is Tween) or not (cafe_tween as Tween).is_running():
		_fail("Customer NPC did not begin its breakfast route during the cafe schedule phase.")
		return
	operations.call("_move_customer_visitors", 11)
	var browse_target: Vector3 = routine_customer.get_meta("system_customer_schedule_target", Vector3.ZERO)
	var browse_tween: Variant = routine_customer.get_meta("system_customer_move_tween", null)
	if str(routine_customer.get_meta("system_customer_schedule_phase", "")) != "browse" or str(routine_customer.get_meta("system_customer_schedule_action", "")) != "browsing_services" or browse_target.is_equal_approx(cafe_target) or not (browse_tween is Tween) or not (browse_tween as Tween).is_running():
		_fail("Customer NPC did not redirect its active route when the daily schedule changed from cafe to browsing.")
		return
	if cafe_tween is Tween and (cafe_tween as Tween).is_running():
		_fail("Customer NPC retained an obsolete breakfast tween after its schedule changed.")
		return
	for _movement_frame in range(4):
		await process_frame
	if routine_customer.position.distance_to(routine_start_position) <= 0.001:
		_fail("Customer NPC schedule changed its metadata but did not physically move toward the new destination.")
		return
	var portrait_panel_size: Vector2 = operations.call("_get_responsive_panel_size", Vector2(360.0, 780.0))
	if portrait_panel_size.x > 336.0 or portrait_panel_size.y > 530.0:
		_fail("Baghdad tower operations panel exceeds a 360x780 phone portrait viewport.")
		return
	var landscape_panel_size: Vector2 = operations.call("_get_responsive_panel_size", Vector2(780.0, 360.0))
	if landscape_panel_size.x > 470.0 or landscape_panel_size.y > 328.0:
		_fail("Baghdad tower operations panel exceeds a 780x360 phone landscape viewport.")
		return
	if int(status.get("tower_count", 0)) != 6:
		_fail("Operations manager did not resolve all six towers.")
		return
	operations.call("open_tower", "hunter_association_tower_baghdad")
	if operations.find_child("HunterRankBoardButton", true, false) == null:
		_fail("Hunter Association lobby menu is missing the hunter rank board entry.")
		return
	operations.call("_open_hunter_rank_board")
	if operations.find_child("HunterRankProgressRows", true, false) == null:
		_fail("Hunter rank board did not render its F-to-SSS progression requirements.")
		return
	if int(status.get("staff_count", 0)) != 45:
		_fail("Expected eight professional NPC staff members in four district towers, nine in Shopping Tower, plus four Power Tower staff; found %d." % int(status.get("staff_count", 0)))
		return
	if int(status.get("customer_count", 0)) != 20:
		_fail("Expected four persistent customer NPCs in each of the five Baghdad district towers; found %d." % int(status.get("customer_count", 0)))
		return
	var region := main.find_child("ModernWorldRegionManager", true, false)
	if region == null:
		_fail("ModernWorldRegionManager is missing.")
		return
	var tower_manager := region.get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager == null:
		_fail("BaghdadTowerLandmarksManager is missing.")
		return
	var expected_tower_nodes := {
		"hunter_association_tower_baghdad": "HunterAssociationTower",
		"business_investment_tower_baghdad": "BusinessInvestmentTower",
		"shopping_tower_baghdad": "ShoppingTower",
		"entertainment_tower_baghdad": "EntertainmentTower",
		"technology_tower_baghdad": "TechnologyTower"
	}
	var expected_staff_per_tower := {
		"hunter_association_tower_baghdad": 8,
		"business_investment_tower_baghdad": 8,
		"shopping_tower_baghdad": 9,
		"entertainment_tower_baghdad": 8,
		"technology_tower_baghdad": 8
	}
	var expected_facade_floors := {
		"hunter_association_tower_baghdad": 200,
		"business_investment_tower_baghdad": 36,
		"shopping_tower_baghdad": 32,
		"entertainment_tower_baghdad": 34,
		"technology_tower_baghdad": 40,
		"power_tower_baghdad": 200
	}
	for tower_id in TOWER_IDS:
		var facade_tower := tower_manager.get_node_or_null(str(NODE_NAMES[tower_id])) as Node3D
		var facade_windows := facade_tower.get_node_or_null("FacadeGlazingPanels") as MultiMeshInstance3D if facade_tower != null else null
		if facade_windows == null or facade_windows.multimesh == null or facade_windows.multimesh.mesh == null:
			_fail("Tower facade glazing is missing a valid MultiMesh window surface: " + tower_id)
			return
		var expected_window_count := int(expected_facade_floors[tower_id]) * 20
		if facade_windows.multimesh.instance_count != expected_window_count:
			_fail("Tower facade window count mismatch for %s: expected %d, found %d." % [tower_id, expected_window_count, facade_windows.multimesh.instance_count])
			return
		var configured_window_count := int(facade_tower.get_meta("system_facade_window_count", 0))
		var configured_segments := int(facade_tower.get_meta("system_facade_window_segments_per_floor", 0))
		var configured_floors := int(facade_tower.get_meta("system_facade_window_floors", 0))
		var glazing_box := facade_windows.multimesh.mesh as BoxMesh
		if configured_window_count != expected_window_count or configured_segments != 20 or configured_floors != int(expected_facade_floors[tower_id]):
			_fail("Tower facade glazing layout metadata is incorrect: " + tower_id)
			return
		if glazing_box == null or glazing_box.size.distance_to(Vector3(4.4, 1.45, 0.2)) > 0.01:
			_fail("Tower facade glazing panel dimensions are incorrect: " + tower_id)
			return
	for tower_id in expected_tower_nodes.keys():
		var tower_node := tower_manager.get_node_or_null(str(expected_tower_nodes[tower_id]))
		var lobby := tower_node.get_node_or_null("PublicLobby_Blockout") if tower_node != null else null
		if lobby == null:
			_fail("Tower lobby missing for staff/customer validation: " + tower_id)
			return
		var visible_staff := 0
		var visible_customers := 0
		var uniformed_staff := 0
		for lobby_child in lobby.get_children():
			if str(lobby_child.name).begins_with("TowerStaff_"):
				visible_staff += 1
				var staff_waypoints: Array = lobby_child.get_meta("system_staff_patrol_waypoints", [])
				if not bool(lobby_child.get_meta("system_staff_navigation_enabled", false)) or staff_waypoints.size() < 4:
					_fail("Tower staff member is missing an autonomous lobby patrol route: " + str(lobby_child.name))
					return
				for staff_child in lobby_child.get_children():
					if staff_child.has_meta("system_uniform_id") and not str(staff_child.get_meta("system_uniform_id", "")).is_empty():
						uniformed_staff += 1
			elif str(lobby_child.name).begins_with("TowerCustomer_"):
				visible_customers += 1
		var expected_staff := int(expected_staff_per_tower[tower_id])
		if visible_staff != expected_staff or uniformed_staff != expected_staff or visible_customers != 4:
			_fail("Tower %s requires %d uniformed visible staff and 4 visible customer NPCs; found staff=%d uniformed=%d customers=%d." % [tower_id, expected_staff, visible_staff, uniformed_staff, visible_customers])
			return
	var hunter_staff_sample: Node3D
	var hunter_staff_model: Node3D
	var hunter_lobby := tower_manager.get_node("HunterAssociationTower/PublicLobby_Blockout") as Node3D
	for lobby_child in hunter_lobby.get_children():
		if str(lobby_child.name).begins_with("TowerStaff_"):
			hunter_staff_sample = lobby_child as Node3D
			for staff_child in lobby_child.get_children():
				if staff_child.has_method("set_activity"):
					hunter_staff_model = staff_child as Node3D
					break
			break
	if hunter_staff_sample == null or hunter_staff_model == null:
		_fail("Hunter staff patrol sample could not be resolved.")
		return
	operations.call("_start_tower_staff_waypoint_patrol", hunter_staff_sample, hunter_staff_model, 0)
	var staff_start_position := hunter_staff_sample.position
	await create_timer(0.65).timeout
	if hunter_staff_sample.position.distance_to(staff_start_position) < 0.1:
		_fail("Tower staff waypoint patrol did not move the employee.")
		return
	if str(hunter_staff_model.get("current_activity")) != "walk":
		_fail("Tower staff waypoint patrol did not trigger the walk animation.")
		return
	operations.call("_simulate_customer_purchases")
	var shopping_customer_floor := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 29) as Node3D
	var shopping_customer_lobby := tower_manager.get_node("ShoppingTower/PublicLobby_Blockout") as Node3D
	if shopping_customer_floor == null or shopping_customer_lobby == null:
		_fail("Shopping Tower restaurant floor or customer lobby could not be prepared.")
		return
	operations.set("active_floor_root", shopping_customer_floor)
	shopping_customer_floor.set_meta("system_tower_id", "shopping_tower_baghdad")
	operations.call("_place_customer_visitors_on_floor", "shopping_tower_baghdad", 29, shopping_customer_floor)
	var floor_visitors := 0
	for floor_child in shopping_customer_floor.get_children():
		if str(floor_child.name).begins_with("TowerCustomer_"):
			floor_visitors += 1
	var lobby_visitors_during_visit := 0
	for lobby_child in shopping_customer_lobby.get_children():
		if str(lobby_child.name).begins_with("TowerCustomer_"):
			lobby_visitors_during_visit += 1
	if floor_visitors != 2 or lobby_visitors_during_visit != 2:
		_fail("Shopping Tower customers did not split between the lobby and restaurant floor; floor=%d lobby=%d." % [floor_visitors, lobby_visitors_during_visit])
		return
	operations.call("_return_customer_visitors_to_lobbies")
	operations.set("active_floor_root", null)
	var lobby_visitors_after_return := 0
	for lobby_child in shopping_customer_lobby.get_children():
		if str(lobby_child.name).begins_with("TowerCustomer_"):
			lobby_visitors_after_return += 1
	if lobby_visitors_after_return != 4:
		_fail("Shopping Tower restaurant visitors did not return to the public lobby; found %d." % lobby_visitors_after_return)
		return
	var post_purchase_status: Dictionary = operations.call("get_operations_status")
	if int(post_purchase_status.get("npc_purchase_count", 0)) <= 0:
		_fail("NPC customer purchasing did not complete a transaction.")
		return
	if str(status.get("advertising_mode", "")) != "npc_staff_managed_internal_external":
		_fail("NPC-managed internal/external advertising is not active.")
		return
	var entertainment_pool := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 18) as Node3D
	var pool_facility := entertainment_pool.get_node_or_null("SpecialFacility_swimming_pool") as Node3D if entertainment_pool != null else null
	if pool_facility == null or pool_facility.get_node_or_null("PoolWater") == null:
		_fail("Entertainment Tower swimming pool floor is missing its pool and water surface.")
		return
	for pool_floor_number in [18, 19, 20]:
		var pool_floor_room := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", pool_floor_number) as Node3D
		var pool_floor_facility := pool_floor_room.get_node_or_null("SpecialFacility_swimming_pool") as Node3D if pool_floor_room != null else null
		if pool_floor_facility == null:
			_fail("Entertainment Tower aquatic facility is missing from floor %d." % pool_floor_number)
			return
		for required_pool_node in ["MensChangingSuite", "WomensChangingSuite", "PoolLifeguardStation", "PoolWaterVolume"]:
			if pool_floor_facility.get_node_or_null(required_pool_node) == null:
				_fail("Pool floor %d is missing required indoor facility %s." % [pool_floor_number, required_pool_node])
				return
		var mens_suite := pool_floor_facility.get_node("MensChangingSuite")
		var womens_suite := pool_floor_facility.get_node("WomensChangingSuite")
		if mens_suite.get_node_or_null("Locker_00") == null or mens_suite.get_node_or_null("ShowerHead_00") == null or womens_suite.get_node_or_null("Locker_05") == null or womens_suite.get_node_or_null("ShowerDrain_02") == null:
			_fail("Pool floor %d changing suites are missing lockers or shower fixtures." % pool_floor_number)
			return
	if pool_facility.find_child("LapLaneDivider_00", true, false) == null or pool_facility.find_child("LapStartBlock_00", true, false) == null:
		_fail("Pool floor 18 is missing its lap lanes and starting blocks.")
		return
	var family_pool_room := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 19) as Node3D
	var family_pool_facility := family_pool_room.get_node("SpecialFacility_swimming_pool") as Node3D
	if family_pool_facility.find_child("FamilySplashPoolWater", true, false) == null or family_pool_facility.find_child("SplashFountain_00", true, false) == null:
		_fail("Pool floor 19 is missing its family splash pool and fountains.")
		return
	var spa_pool_room := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 20) as Node3D
	var spa_pool_facility := spa_pool_room.get_node("SpecialFacility_swimming_pool") as Node3D
	for spa_node in ["SpaHotTubWater", "ThermalPoolWater", "SaunaCabin", "SteamRoomCabin"]:
		if spa_pool_facility.find_child(spa_node, true, false) == null:
			_fail("Pool floor 20 is missing its spa feature: " + spa_node)
			return
	var cinema_floor := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 24) as Node3D
	var cinema_facility := cinema_floor.get_node_or_null("SpecialFacility_cinema") as Node3D if cinema_floor != null else null
	if cinema_facility == null or cinema_facility.find_child("CinemaScreen", true, false) == null:
		_fail("Entertainment Tower cinema room is missing its screen.")
		return
	if cinema_facility.get_node_or_null("CinemaProgramScreen") == null or cinema_facility.get_node_or_null("CinemaProgramTitle") == null:
		_fail("Cinema must generate its original program screen and scene title display.")
		return
	var business_floor := operations.call("_ensure_floor_room", "business_investment_tower_baghdad", 8) as Node3D
	if business_floor == null or business_floor.find_child("TradingDisplay", true, false) == null:
		_fail("Business Tower stock-exchange trading hall is missing its display.")
		return
	var technology_floor := operations.call("_ensure_floor_room", "technology_tower_baghdad", 20) as Node3D
	if technology_floor == null or technology_floor.find_child("TechnologyPod_00", true, false) == null:
		_fail("Technology Tower AI laboratory is missing its equipment pods.")
		return
	var hunter_honor_floor := operations.call("_ensure_floor_room", "hunter_association_tower_baghdad", 100) as Node3D
	if hunter_honor_floor == null or hunter_honor_floor.find_child("HonorPillar_00", true, false) == null:
		_fail("Hunter Association Tower Hall of Honor floor is missing its pillars.")
		return
	var hunter_headquarters_floor := operations.call("_ensure_floor_room", "hunter_association_tower_baghdad", 200) as Node3D
	if hunter_headquarters_floor == null or hunter_headquarters_floor.find_child("GlobalOperationsDisplay", true, false) == null or hunter_headquarters_floor.find_child("AssociationDirectorDesk", true, false) == null:
		_fail("The Global Hunter Association headquarters must occupy the top floor of the Hunter Association Tower.")
		return
	var hunter_council_floor := operations.call("_ensure_floor_room", "hunter_association_tower_baghdad", 195) as Node3D
	if hunter_council_floor == null or hunter_council_floor.find_child("GlobalCouncilTable", true, false) == null:
		_fail("The Global Hunter Association Council chamber is missing from floor 195.")
		return
	var restaurant_room := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 29) as Node3D
	if restaurant_room == null or restaurant_room.get_node_or_null("RestaurantDiningSign") == null or restaurant_room.get_node_or_null("RestaurantTable_00") == null:
		_fail("Shopping Tower restaurant dining hall is missing from floors 29–32.")
		return

	var emergency_exit_floors: Array[Node3D] = [
		shopping_customer_floor,
		entertainment_pool,
		cinema_floor,
		business_floor,
		technology_floor,
		hunter_honor_floor,
		hunter_council_floor,
		hunter_headquarters_floor,
		restaurant_room
	]
	for floor_room in emergency_exit_floors:
		var exit_root := floor_room.get_node_or_null("EmergencyEvacuationExit") as Node3D
		var exit_sensor := floor_room.get_node_or_null("EmergencyExitSensor") as Area3D
		var exit_sign := exit_root.get_node_or_null("EmergencyExitSign") as Label3D if exit_root != null else null
		if exit_root == null or exit_sensor == null or exit_sign == null:
			_fail("A generated Baghdad tower floor is missing its emergency evacuation exit, physical sensor or sign.")
			return
		if exit_root.get_node_or_null("EmergencyExitFramePillar_L") == null or exit_root.get_node_or_null("EmergencyExitFramePillar_R") == null or exit_root.get_node_or_null("EmergencyExitBeacon") == null or exit_root.get_node_or_null("EmergencyExitLight") == null:
			_fail("A Baghdad floor emergency exit is missing its frame, illuminated beacon or safety light.")
			return
		if floor_room.get_node_or_null("InteriorWall_15") != null or floor_room.get_node_or_null("InteriorWall_14") == null or floor_room.get_node_or_null("InteriorWall_16") == null:
			_fail("A Baghdad emergency exit is blocked by the circular wall or its adjacent wall segments are missing.")
			return
		var has_exit_collision := false
		for sensor_child in exit_sensor.get_children():
			if sensor_child is CollisionShape3D and sensor_child.shape != null:
				has_exit_collision = true
		if not has_exit_collision or not exit_sensor.monitoring:
			_fail("A Baghdad floor emergency exit is missing its active physical sensor/collision: floor=%s shape=%s monitoring=%s." % [str(floor_room.name), str(has_exit_collision), str(exit_sensor.monitoring)])
			return
		if not bool(exit_sensor.get_meta("system_emergency_exit", false)) or str(exit_sensor.get_meta("system_tower_id", "")) != str(floor_room.get_meta("system_tower_id", exit_sensor.get_meta("system_tower_id", ""))):
			_fail("A Baghdad floor emergency exit has invalid tower ownership metadata.")
			return
		if exit_sign.text.is_empty() or not exit_sign.text.contains("مخرج الطوارئ"):
			_fail("A Baghdad floor emergency exit sign is missing its Arabic evacuation direction.")
			return
	var exam_manager := main.get_node_or_null("SYSTEMHunterExamManager")
	if exam_manager == null:
		_fail("HunterExamManager is missing.")
		return
	var empty_stage_ids: Array[String] = []
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	exam_manager.set("registered", true)
	exam_manager.set("exam_active", true)
	exam_manager.set("current_stage_index", 0)
	var resume_result: Dictionary = exam_manager.call("begin_exam")
	if not bool(resume_result.get("success", false)) or not bool(resume_result.get("resumed", false)):
		_fail("An in-progress Hunter examination must resume at its saved stage.")
		return
	var exam_overview: Dictionary = exam_manager.call("get_exam_overview")
	var all_stage_ids: Array[String] = []
	for stage_value in exam_overview.get("stages", []):
		all_stage_ids.append(str(stage_value.get("id", "")))
	exam_manager.set("completed_stage_ids", all_stage_ids)
	exam_manager.set("exam_active", false)
	var completed_exam_result: Dictionary = exam_manager.call("begin_exam")
	if str(completed_exam_result.get("reason", "")) != "ALL_STAGES_COMPLETED" or bool(exam_manager.get("exam_active")):
		_fail("A completed Hunter examination must not reopen or remain marked active.")
		return
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	exam_manager.set("registered", false)
	exam_manager.set("exam_active", false)
	exam_manager.set("current_stage_index", -1)
	var hunter_tower := tower_manager.get_node_or_null("HunterAssociationTower") as Node3D
	var helipad := hunter_tower.get_node_or_null("HunterAssociationHelipad") as Node3D if hunter_tower != null else null
	if helipad == null or str(helipad.get_meta("system_owner_tower_id", "")) != "hunter_association_tower_baghdad":
		_fail("Hunter Association helicopter landing pad is missing or assigned to the wrong tower.")
		return
	if helipad.get_node_or_null("HelipadDeck") == null or helipad.get_node_or_null("HelipadDeckCollision") == null or helipad.get_node_or_null("LandingCircleMarking") == null or helipad.get_node_or_null("HelipadIdentitySign") == null:
		_fail("Hunter Association helicopter landing pad deck, collision, markings or sign is incomplete.")
		return
	if helipad.get_node_or_null("HelipadAccessBridge") == null or helipad.get_node_or_null("HelipadAccessBridgeCollision") == null:
		_fail("Hunter Association helicopter landing pad access bridge is missing collision.")
		return
	var helipad_lights := 0
	for child in helipad.get_children():
		if str(child.name).begins_with("HelipadPerimeterLight_"):
			helipad_lights += 1
	if helipad_lights != 8:
		_fail("Hunter Association helicopter landing pad requires eight perimeter lights.")
		return
	if not helipad.has_method("get_helicopter_status"):
		_fail("Hunter Association helicopter flight controller is not attached to the landing pad.")
		return
	var helicopter_status: Dictionary = helipad.call("get_helicopter_status")
	if not bool(helicopter_status.get("available", false)) or str(helicopter_status.get("owner_tower_id", "")) != "hunter_association_tower_baghdad" or float(helicopter_status.get("landing_radius_m", 0.0)) != 18.0:
		_fail("Hunter Association helicopter controller ownership or landing-zone configuration is invalid.")
		return
	if not helicopter_status.has("pilot_authorized") or helipad.call("_can_pilot"):
		_fail("Unlicensed test profile must not be granted helicopter pilot access.")
		return
	exam_manager.set("registered", true)
	exam_manager.set("completed_stage_ids", all_stage_ids)
	var pilot_player := main.get("player") as CharacterBody3D
	var pilot_progression := main.get("player_progression") as Node
	if pilot_player == null or pilot_progression == null:
		_fail("Player and progression data are required for helicopter authorization tests.")
		return
	var operations_progression := operations.get("progression") as Node
	var named_progression := main.get_node_or_null("PlayerProgression") as Node
	var main_progression := main.get("player_progression") as Node
	if operations_progression != pilot_progression or named_progression != pilot_progression:
		_fail("Baghdad progression binding mismatch: operations=%s#%d, named=%s#%d, main_var=%s#%d." % [str(operations_progression), operations_progression.get_instance_id() if is_instance_valid(operations_progression) else -1, str(pilot_progression), pilot_progression.get_instance_id() if is_instance_valid(pilot_progression) else -1, str(main_progression), main_progression.get_instance_id() if is_instance_valid(main_progression) else -1])
		return
	if helipad.call("_can_pilot"):
		_fail("A completed Hunter License alone must not grant helicopter access.")
		return
	pilot_progression.set("current_level", 100)
	exam_manager.set("completed_stage_ids", all_stage_ids)
	if helipad.call("_can_pilot"):
		_fail("Player level and a completed Hunter License must not replace S-rank helicopter authorization.")
		return
	pilot_progression.set("current_level", 1)
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	for role in ["association_director", "association_official", "chief_hunter", "helicopter_pilot"]:
		pilot_player.set_meta("system_hunter_association_role", role)
		if not helipad.call("_can_pilot"):
			_fail("Senior Association role %s must receive helicopter access." % role)
			return
	pilot_player.set_meta("system_hunter_association_role", "mission_clerk")
	if helipad.call("_can_pilot"):
		_fail("A standard mission clerk must not receive professional helicopter access.")
		return
	pilot_player.set_meta("system_hunter_staff_professional", true)
	pilot_player.set_meta("system_hunter_association_role", "professional_employee")
	if not helipad.call("_can_pilot"):
		_fail("A certified professional Association employee must receive helicopter access.")
		return
	pilot_player.remove_meta("system_hunter_staff_professional")
	pilot_player.remove_meta("system_hunter_association_role")
	pilot_progression.set("current_level", 1)
	for rank in ["F", "E", "D", "C", "B", "A"]:
		pilot_player.set_meta("system_hunter_rank", rank)
		if helipad.call("_can_pilot"):
			_fail("A %s hunter must not receive S-rank helicopter authorization." % rank)
			return
	for rank in ["S", "SS", "SSS"]:
		pilot_player.set_meta("system_hunter_rank", rank)
		if not helipad.call("_can_pilot"):
			_fail("A %s hunter must receive helicopter access." % rank)
			return
	pilot_player.remove_meta("system_hunter_rank")
	var original_rank_points := int(pilot_progression.get("verified_hunter_mission_points"))
	var original_rank_count := int(pilot_progression.get("verified_hunter_mission_count"))
	var original_rank_ids: Array[String] = pilot_progression.get("verified_hunter_mission_ids").duplicate()
	var original_nen_uses := int(pilot_progression.get("nen_skill_use_count"))
	var original_nen_skills: Array[String] = pilot_progression.get("nen_skill_ids").duplicate()
	var original_nen_unlocked := bool(pilot_progression.get("nen_unlocked"))
	var original_nen_control := int(pilot_progression.get("nen_control_rank"))
	var original_sss_approval := bool(pilot_progression.get("hunter_sss_board_approved"))
	pilot_progression.set("verified_hunter_mission_points", 0)
	if str(pilot_progression.call("get_hunter_rank")) != "F":
		_fail("New hunters must begin at F rank.")
		return
	pilot_progression.set("verified_hunter_mission_points", 850)
	if str(pilot_progression.call("get_hunter_rank")) != "B":
		_fail("Verified mission score did not advance through the F-to-B grades.")
		return
	pilot_progression.set("verified_hunter_mission_points", 1500)
	pilot_progression.set("nen_unlocked", true)
	pilot_progression.set("nen_control_rank", 2)
	pilot_progression.set("nen_skill_use_count", 10)
	if str(pilot_progression.call("get_hunter_rank")) != "A":
		_fail("A-rank promotion must require verified mission score and Nen practice.")
		return
	pilot_progression.set("verified_hunter_mission_points", 2500)
	pilot_progression.set("nen_control_rank", 4)
	pilot_progression.set("nen_skill_use_count", 50)
	var s_rank_skills: Array[String] = ["nen_burst", "charged_strike"]
	pilot_progression.set("nen_skill_ids", s_rank_skills)
	if str(pilot_progression.call("get_hunter_rank")) != "S":
		_fail("S-rank promotion must require high mission score and demonstrated Nen mastery.")
		return
	pilot_progression.set("verified_hunter_mission_points", 5000)
	pilot_progression.set("nen_control_rank", 5)
	pilot_progression.set("nen_skill_use_count", 150)
	var ss_rank_skills: Array[String] = ["nen_burst", "charged_strike", "aura_guard"]
	pilot_progression.set("nen_skill_ids", ss_rank_skills)
	if str(pilot_progression.call("get_hunter_rank")) != "SS":
		_fail("SS-rank promotion must require advanced mission and Nen mastery.")
		return
	pilot_progression.set("hunter_sss_board_approved", true)
	if str(pilot_progression.call("get_hunter_rank")) != "SSS":
		_fail("SSS rank must require explicit Hunter Examination Board approval.")
		return
	pilot_progression.set("verified_hunter_mission_points", original_rank_points)
	pilot_progression.set("verified_hunter_mission_count", original_rank_count)
	pilot_progression.set("verified_hunter_mission_ids", original_rank_ids)
	pilot_progression.set("nen_skill_use_count", original_nen_uses)
	pilot_progression.set("nen_skill_ids", original_nen_skills)
	pilot_progression.set("nen_unlocked", original_nen_unlocked)
	pilot_progression.set("nen_control_rank", original_nen_control)
	pilot_progression.set("hunter_sss_board_approved", original_sss_approval)
	pilot_progression.set("current_level", 50)
	exam_manager.set("completed_stage_ids", all_stage_ids)
	if not helipad.has_method("_is_aircraft_position_clear"):
		_fail("Hunter Association helicopter obstacle-clearance query is missing.")
		return
	if not helipad.has_method("_save_parked_state") or not helipad.has_method("_load_parked_state"):
		_fail("Hunter Association helicopter parking persistence methods are missing.")
		return
	var helicopter_node := helipad.get_node_or_null("HunterAssociationHelicopter") as Node3D
	var parked_position := helicopter_node.position
	var parked_rotation := helicopter_node.rotation
	helicopter_node.position = parked_position + Vector3(1.0, 0.0, 0.0)
	helicopter_node.rotation = parked_rotation + Vector3(0.0, 0.15, 0.0)
	if not bool(helipad.call("_save_parked_state")):
		_fail("Hunter Association helicopter could not save its parked state.")
		return
	helicopter_node.position = parked_position
	helicopter_node.rotation = Vector3.ZERO
	helipad.call("_load_parked_state")
	if not helicopter_node.position.is_equal_approx(parked_position + Vector3(1.0, 0.0, 0.0)):
		_fail("Hunter Association helicopter parked position did not survive reload.")
		return
	if not helicopter_node.rotation.is_equal_approx(parked_rotation + Vector3(0.0, 0.15, 0.0)):
		_fail("Hunter Association helicopter parked orientation did not survive reload.")
		return
	helicopter_node.position = parked_position
	helicopter_node.rotation = parked_rotation
	helipad.call("_save_parked_state")
	var rotor_test_position := helicopter_node.global_position + Vector3.UP * 100.0
	var rotor_obstacle := StaticBody3D.new()
	var rotor_obstacle_shape := CollisionShape3D.new()
	var rotor_obstacle_box := BoxShape3D.new()
	rotor_obstacle_box.size = Vector3(0.6, 0.6, 0.6)
	rotor_obstacle_shape.shape = rotor_obstacle_box
	rotor_obstacle.add_child(rotor_obstacle_shape)
	main.add_child(rotor_obstacle)
	rotor_obstacle.global_position = rotor_test_position + helicopter_node.global_basis * Vector3(6.0, 1.8, 0.0)
	await physics_frame
	var main_rotor_blocked: bool = not bool(helipad.call("_is_aircraft_position_clear", rotor_test_position))
	rotor_obstacle.queue_free()
	await physics_frame
	if not main_rotor_blocked:
		_fail("Helicopter clearance query did not detect an obstacle at the main rotor disc edge.")
		return
	var helicopter_player: CharacterBody3D = main.get("player") as CharacterBody3D
	if helicopter_player == null:
		_fail("A player character is required for the helicopter takeoff/landing test.")
		return
	var player_physics_before_flight := helicopter_player.is_physics_processing()
	helipad.call("_enter_aircraft")
	if not bool(helipad.get("pilot_active")) or helicopter_player.visible or (player_physics_before_flight and helicopter_player.is_physics_processing()):
		_fail("Authorized pilot entry did not transfer control from the on-foot character.")
		return
	helipad.set("vertical_input", 1.0)
	helipad.call("_update_flight", 0.5)
	var takeoff_height := float(helipad.get("heli_position").y)
	if takeoff_height <= helipad.global_position.y + 2.8:
		_fail("Authorized helicopter pilot could not lift off from the landing pad.")
		return
	helipad.set("vertical_input", -1.0)
	helipad.call("_update_flight", 0.5)
	helipad.call("_update_flight", 0.5)
	if not bool(helipad.get("landed")):
		_fail("Helicopter could not complete a controlled landing inside its marked pad.")
		return
	helipad.call("_exit_aircraft")
	if bool(helipad.get("pilot_active")) or not helicopter_player.visible or bool(helicopter_player.get_meta("system_helicopter_piloting", true)) or helicopter_player.is_physics_processing() != player_physics_before_flight:
		_fail("Helicopter exit did not restore the on-foot player controls.")
		return
	if helicopter_player.global_position.distance_to(helicopter_node.global_position) > 12.0:
		_fail("Helicopter exit did not place the pilot beside the parked aircraft.")
		return
	helipad.call("_enter_aircraft")
	helipad.set("vertical_input", 1.0)
	helipad.call("_update_flight", 0.5)
	if bool(helipad.get("landed")):
		_fail("Emergency-landing regression setup could not reach airborne state.")
		return
	helipad.call("_begin_emergency_landing")
	if not bool(helipad.get("emergency_landing_active")):
		_fail("Emergency landing did not activate over a detected safe ground surface.")
		return
	for _landing_step in range(12):
		helipad.call("_update_flight", 0.5)
		if bool(helipad.get("landed")):
			break
	if not bool(helipad.get("landed")) or bool(helipad.get("emergency_landing_active")):
		_fail("Emergency landing did not complete a controlled descent to detected ground.")
		return
	helipad.call("_exit_aircraft")
	exam_manager.set("registered", false)
	exam_manager.set("completed_stage_ids", empty_stage_ids)
	exam_manager.set("exam_active", false)
	if helipad.get_node_or_null("HunterAssociationHelicopter") == null or helipad.get_node_or_null("HunterHelicopterTouchHUD") == null:
		_fail("Hunter Association helicopter aircraft model or touch-control HUD was not generated.")
		return
	for tower_id in TOWER_IDS:
		var tower := tower_manager.get_node_or_null(str(NODE_NAMES[tower_id])) as Node3D
		if tower == null:
			_fail("Missing tower node: " + tower_id)
			return
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
		if lobby == null:
			_fail("Missing lobby for " + tower_id)
			return
		var lobby_lift := lobby.get_node_or_null("LobbyElevatorInteraction") as Area3D
		if lobby_lift == null or not lobby_lift.is_in_group("system_interactable") or str(lobby_lift.get_meta("system_tower_id", "")) != tower_id:
			_fail("Lobby elevator selector is not interactable for " + tower_id)
			return
		var staff_count := 0
		for child in lobby.get_children():
			if child.has_meta("system_tower_staff_id"):
				staff_count += 1
		var expected_staff_count := 4
		match tower_id:
			"hunter_association_tower_baghdad", "business_investment_tower_baghdad", "entertainment_tower_baghdad", "technology_tower_baghdad":
				expected_staff_count = 8
			"shopping_tower_baghdad":
				expected_staff_count = 9
		if staff_count != expected_staff_count:
			_fail("Expected %d visible NPC employees in %s; found %d." % [expected_staff_count, tower_id, staff_count])
			return
		if tower_id != "power_tower_baghdad":
			var lobby_cafe := lobby.get_node_or_null("SYSTEMLobbyCafe") as Node3D
			var cafe_interaction := lobby_cafe.get_node_or_null("CafeServiceInteraction") as Area3D if lobby_cafe != null else null
			if cafe_interaction == null or not cafe_interaction.is_in_group("system_interactable") or not cafe_interaction.has_meta("system_tower_staff_id"):
				_fail("A staffed public cafe and customer service interaction are missing from " + tower_id)
				return
		var internal_ad := lobby.get_node_or_null("NPCManagedInternalCampaign") as Label3D
		if internal_ad == null or not internal_ad.text.contains("بإدارة"):
			_fail("Internal NPC-managed advertising is missing for " + tower_id)
			return
		var external_ad := tower.get_node_or_null("TowerCampaignText") as Label3D
		if external_ad == null or not external_ad.text.contains("بإدارة"):
			_fail("External NPC-managed advertising is missing for " + tower_id)
			return
		var room := operations.call("_ensure_floor_room", tower_id, 1) as Node3D
		if room == null:
			_fail("Could not generate playable interior floor 1 for " + tower_id)
			return
		if room.get_node_or_null("FloorCollision") == null:
			_fail("Interior floor collision is missing for " + tower_id)
			return
		if tower_id != "power_tower_baghdad":
			var service_kiosk := room.get_node_or_null("ServiceKiosk_0/TowerServiceInteraction") as Area3D
			if service_kiosk == null or str(service_kiosk.get_meta("system_tower_id", "")) != tower_id or int(service_kiosk.get_meta("system_tower_floor_number", 0)) != 1:
				_fail("Tower floor service kiosk metadata is missing or incorrect for " + tower_id)
				return
			if not operations.has_method("open_floor_services"):
				_fail("Tower floor kiosk service routing method is missing.")
				return
			operations.call("open_floor_services", tower_id, 1)
			var service_panel := operations.get("panel") as Control
			if service_panel == null or not service_panel.visible:
				_fail("Tower floor kiosk did not open its assigned NPC service for " + tower_id)
				return
			service_panel.hide()
		if tower_id != "power_tower_baghdad":
			var theme_root := room.get_node_or_null("FloorThemeIdentity") as Node3D
			var theme_props := theme_root.get_node_or_null("FloorThemeProps") as Node3D if theme_root != null else null
			if theme_root == null or theme_props == null or theme_props.get_child_count() < 5 or str(room.get_meta("system_floor_theme_id", "")).is_empty():
				_fail("Distinct department floor theme is missing or incomplete for " + tower_id)
				return
		else:
			if not room.has_meta("system_power_tower_arena_type") or room.get_node_or_null("ArenaChallengeDisplay") == null:
				_fail("Power Tower arena layout is missing for its challenge floor.")
				return
		if tower_id != "power_tower_baghdad":
			var service_area := room.find_child("TowerServiceInteraction", true, false) as Area3D
			if service_area == null or not service_area.is_in_group("system_interactable") or str(service_area.get_meta("system_tower_id", "")) != tower_id:
				_fail("Interactive NPC service kiosk is missing for " + tower_id)
				return
	var power_manager: Node = main.get("power_tower_manager") as Node
	if power_manager == null:
		_fail("Power Tower progression manager is missing.")
		return
	var power_probe_script := load("res://scripts/system_power_tower_manager.gd") as Script
	if power_probe_script == null:
		_fail("Power Tower progression manager script could not load for regression tests.")
		return
	var power_probe := power_probe_script.new() as Node
	main.add_child(power_probe)
	power_probe.set("highest_cleared_floor", 0)
	power_probe.set("active_floor", 0)
	power_probe.set("floor_clear_times", {})
	var skipped_floor: Dictionary = power_probe.call("request_floor", 2, 1)
	if str(skipped_floor.get("reason", "")) != "PREVIOUS_FLOOR_REQUIRED":
		_fail("Power Tower allowed a player to skip the previous floor.")
		return
	var low_level: Dictionary = power_probe.call("request_floor", 1, 0)
	if str(low_level.get("reason", "")) != "PLAYER_LEVEL_TOO_LOW":
		_fail("Power Tower allowed a player below the required level to enter.")
		return
	var first_floor: Dictionary = power_probe.call("request_floor", 1, 1)
	if not bool(first_floor.get("success", false)):
		_fail("Power Tower rejected a valid first-floor request.")
		return
	var duplicate_active: Dictionary = power_probe.call("request_floor", 1, 1)
	if str(duplicate_active.get("reason", "")) != "ANOTHER_FLOOR_IS_ACTIVE":
		_fail("Power Tower allowed a second concurrent active floor.")
		return
	var forged_clear: Dictionary = power_probe.call("confirm_floor_clear", 2, 30.0)
	if str(forged_clear.get("reason", "")) != "FLOOR_NOT_ACTIVE":
		_fail("Power Tower accepted a clear report for a floor that was never activated.")
		return
	power_probe.call("abandon_active_floor")
	power_probe.queue_free()
	var power_tower_theme_ids: Dictionary = {}
	for floor_number in range(1, 201):
		var floor_data: Dictionary = power_manager.call("get_floor_data", floor_number)
		var theme_id := str(floor_data.get("arena_theme_id", ""))
		if theme_id.is_empty():
			_fail("Power Tower floor %d is missing its arena environment theme." % floor_number)
			return
		power_tower_theme_ids[theme_id] = true
		if int(floor_data.get("floor", 0)) != floor_number or int(floor_data.get("required_level", 999)) > 100:
			_fail("Power Tower floor data or level gate is invalid at floor %d." % floor_number)
			return
		if bool(floor_data.get("boss_floor", false)) != (floor_number % 10 == 0):
			_fail("Power Tower boss cadence is incorrect at floor %d." % floor_number)
			return
		if int(floor_data.get("opponent_count", 0)) != 1 or int(floor_data.get("wave_count", 0)) != 1 or int(floor_data.get("reward_xp", 0)) <= 0 or int(floor_data.get("reward_credits", 0)) <= 0:
			_fail("Power Tower floor %d must contain exactly one opponent, one round and positive rewards." % floor_number)
			return
		if str(floor_data.get("competition_format", "")) != "INDIVIDUAL_1V1" or int(floor_data.get("time_limit_seconds", -1)) != 0:
			_fail("Power Tower floor %d violates the individual-only, no-team 1v1 competition rule." % floor_number)
			return
		if str(floor_data.get("arena_type", "")) not in ["DUEL", "ELITE_DUEL", "BOSS_TRIAL"]:
			_fail("Power Tower floor %d exposes a non-individual competition type." % floor_number)
			return
		var expected_objective := "DEFEAT_BOSS" if bool(floor_data.get("boss_floor", false)) else "DEFEAT_OPPONENT"
		if str(floor_data.get("objective_type", "")) != expected_objective:
			_fail("Power Tower floor %d does not use a single-opponent defeat objective." % floor_number)
			return
	if power_tower_theme_ids.size() != 10:
		_fail("Power Tower must expose ten distinct 20-floor environment themes.")
		return
	var power_tower := tower_manager.get_node_or_null("PowerTower") as Node3D
	var power_lobby := power_tower.get_node_or_null("PublicLobby_Blockout") as Node3D
	var progress_board := power_lobby.get_node_or_null("PowerTowerProgressBoard") as Label3D
	if progress_board == null or not progress_board.text.contains("200") or not progress_board.text.contains("أفضل وقت") or not progress_board.text.contains("1 VS 1") or not progress_board.text.contains("المواجهات الفردية الفائزة"):
		_fail("Power Tower lobby progress board is missing the 200-floor completion target.")
		return
	var first_floor_rewards: Dictionary = power_manager.call("get_floor_data", 1)
	var second_floor_rewards: Dictionary = power_manager.call("get_floor_data", 2)
	if int(second_floor_rewards.get("reward_credits", 0)) <= int(first_floor_rewards.get("reward_credits", 0)):
		_fail("Power Tower virtual-credit rewards must scale upward with floor difficulty.")
		return
	var boss_data: Dictionary = power_manager.call("get_floor_data", 200)
	if not bool(boss_data.get("boss_floor", false)) or str(boss_data.get("arena_type", "")) != "BOSS_TRIAL":
		_fail("Power Tower floor 200 is not configured as a boss trial.")
		return
	if not bool(boss_data.get("final_boss", false)) or str(boss_data.get("challenge_type", "")) != "FINAL_BOSS":
		_fail("Power Tower floor 200 is missing its unique final sovereign boss profile.")
		return
	var final_rewards: Array = boss_data.get("reward_items", [])
	if not final_rewards.has("power_tower_sovereign_crown") or not final_rewards.has("sovereign_core") or not final_rewards.has("rare_core") or not final_rewards.has("nen_fragment"):
		_fail("Power Tower floor 200 is missing its unique completion rewards.")
		return
	if int(boss_data.get("required_level", 999)) > 100:
		_fail("Power Tower floor 200 is unreachable under the 100-level player progression cap.")
		return
	var power_tower_test_script := load("res://scripts/system_power_tower_manager.gd") as Script
	if power_tower_test_script == null:
		_fail("Power Tower progression script could not be loaded for the 200-floor regression.")
		return
	var progression_test_manager := power_tower_test_script.new() as Node
	progression_test_manager.set("spectator_save_path", "user://validator_power_tower_spectator_predictions.cfg")
	root.add_child(progression_test_manager)
	await process_frame
	progression_test_manager.set("highest_cleared_floor", 0)
	progression_test_manager.set("active_floor", 0)
	progression_test_manager.set("floor_clear_times", {})
	progression_test_manager.set("total_duels_won", 0)
	progression_test_manager.set("elite_duels_won", 0)
	progression_test_manager.set("boss_duels_won", 0)
	progression_test_manager.set("total_xp_earned", 0)
	progression_test_manager.set("total_credits_earned", 0)
	for test_floor in range(1, 201):
		var floor_request: Dictionary = progression_test_manager.call("request_floor", test_floor, 100)
		if not bool(floor_request.get("success", false)):
			_fail("Power Tower rejected sequential progression at floor %d: %s" % [test_floor, str(floor_request.get("reason", "unknown"))])
			progression_test_manager.queue_free()
			return
		var floor_clear: Dictionary = progression_test_manager.call("confirm_floor_clear", test_floor, float(test_floor))
		if not bool(floor_clear.get("success", false)):
			_fail("Power Tower could not persist a valid clear at floor %d." % test_floor)
			progression_test_manager.queue_free()
			return
	var reloaded_progression_manager := power_tower_test_script.new() as Node
	root.add_child(reloaded_progression_manager)
	await process_frame
	var reloaded_tower_status: Dictionary = reloaded_progression_manager.call("get_tower_status")
	var reloaded_floor_times: Dictionary = reloaded_progression_manager.get("floor_clear_times")
	if int(reloaded_tower_status.get("highest_cleared_floor", 0)) != 200 or int(reloaded_tower_status.get("next_floor", 1)) != 0 or int(reloaded_floor_times.size()) != 200 or int(reloaded_tower_status.get("total_duels_won", 0)) != 200 or int(reloaded_tower_status.get("elite_duels_won", 0)) != 20 or int(reloaded_tower_status.get("boss_duels_won", 0)) != 20 or int(reloaded_tower_status.get("total_xp_earned", 0)) <= 0 or int(reloaded_tower_status.get("total_credits_earned", 0)) <= 0:
		_fail("Power Tower did not restore all 200 individual duel wins, elite/boss records, clear times and lifetime rewards.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		return
	var prediction_match := progression_test_manager.call("register_spectator_match", "validator_duel_001", "fighter_alpha", "fighter_beta", 12)
	if not bool(prediction_match.get("success", false)):
		_fail("Spectator prediction match registration failed.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		return
	var fighter_prediction: Dictionary = progression_test_manager.call("submit_spectator_prediction", "validator_duel_001", "fighter_alpha", "fighter_beta")
	var fan_prediction: Dictionary = progression_test_manager.call("submit_spectator_prediction", "validator_duel_001", "fan_alpha", "fighter_beta")
	var duplicate_prediction: Dictionary = progression_test_manager.call("submit_spectator_prediction", "validator_duel_001", "fan_alpha", "fighter_alpha")
	var second_fan_prediction: Dictionary = progression_test_manager.call("submit_spectator_prediction", "validator_duel_001", "fan_beta", "fighter_alpha")
	if str(fighter_prediction.get("reason", "")) != "FIGHTERS_CANNOT_PREDICT_OWN_MATCH" or not bool(fan_prediction.get("success", false)) or str(duplicate_prediction.get("reason", "")) != "PREDICTION_ALREADY_SUBMITTED" or not bool(second_fan_prediction.get("success", false)):
		_fail("Spectator predictions allowed a fighter to predict their own match, duplicate a vote or reject a valid fan forecast.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		return
	var untrusted_settlement: Dictionary = progression_test_manager.call("settle_spectator_match", "validator_duel_001", "fighter_beta", "CLIENT_SUBMITTED_RESULT")
	var locked_prediction: Dictionary = progression_test_manager.call("lock_spectator_predictions", "validator_duel_001")
	var late_prediction: Dictionary = progression_test_manager.call("submit_spectator_prediction", "validator_duel_001", "fan_late", "fighter_beta")
	var settled_prediction: Dictionary = progression_test_manager.call("settle_spectator_match", "validator_duel_001", "fighter_beta", "LOCAL_COMBAT_AUTHORITY")
	var repeated_settlement: Dictionary = progression_test_manager.call("settle_spectator_match", "validator_duel_001", "fighter_beta", "LOCAL_COMBAT_AUTHORITY")
	var fan_alpha_status: Dictionary = progression_test_manager.call("get_spectator_status", "fan_alpha")
	var fan_beta_status: Dictionary = progression_test_manager.call("get_spectator_status", "fan_beta")
	if str(untrusted_settlement.get("reason", "")) != "UNTRUSTED_MATCH_RESULT" or not bool(locked_prediction.get("success", false)) or str(late_prediction.get("reason", "")) != "PREDICTIONS_LOCKED" or not bool(settled_prediction.get("success", false)) or str(repeated_settlement.get("reason", "")) != "MATCH_NOT_LOCKED":
		_fail("Spectator prediction locking or trusted one-time match settlement failed.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		return
	if int(fan_alpha_status.get("prediction_points", 0)) != 1 or int(fan_beta_status.get("prediction_points", 0)) != 0 or int(fan_alpha_status.get("cash_value", -1)) != 0 or bool(fan_alpha_status.get("transferable", true)) or bool(fan_alpha_status.get("purchasable", true)):
		_fail("Correct fan predictions must award only non-transferable, non-purchasable points; incorrect forecasts must not lose value.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		return
	for daily_index in range(20):
		var daily_match_id := "validator_daily_%02d" % daily_index
		var daily_match: Dictionary = progression_test_manager.call("register_spectator_match", daily_match_id, "daily_fighter_a", "daily_fighter_b", 1)
		var daily_prediction: Dictionary = progression_test_manager.call("submit_spectator_prediction", daily_match_id, "daily_fan", "daily_fighter_a")
		if not bool(daily_match.get("success", false)) or not bool(daily_prediction.get("success", false)):
			_fail("The free spectator daily prediction allowance failed before reaching its published limit.")
			progression_test_manager.queue_free()
			reloaded_progression_manager.queue_free()
			return
	var limit_match: Dictionary = progression_test_manager.call("register_spectator_match", "validator_daily_limit", "daily_fighter_a", "daily_fighter_b", 1)
	var limit_prediction: Dictionary = progression_test_manager.call("submit_spectator_prediction", "validator_daily_limit", "daily_fan", "daily_fighter_a")
	if not bool(limit_match.get("success", false)) or str(limit_prediction.get("reason", "")) != "DAILY_PREDICTION_LIMIT_REACHED":
		_fail("Spectator daily prediction limit was not enforced consistently.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		return
	var spectator_reload_manager := power_tower_test_script.new() as Node
	spectator_reload_manager.set("spectator_save_path", "user://validator_power_tower_spectator_predictions.cfg")
	root.add_child(spectator_reload_manager)
	await process_frame
	var persisted_fan_status: Dictionary = spectator_reload_manager.call("get_spectator_status", "fan_alpha")
	if int(persisted_fan_status.get("prediction_points", 0)) != 1:
		_fail("Spectator prediction points did not persist through a manager reload.")
		progression_test_manager.queue_free()
		reloaded_progression_manager.queue_free()
		spectator_reload_manager.queue_free()
		return
	progression_test_manager.queue_free()
	reloaded_progression_manager.queue_free()
	spectator_reload_manager.queue_free()
	var prediction_file_path := ProjectSettings.globalize_path("user://validator_power_tower_spectator_predictions.cfg")
	if FileAccess.file_exists(prediction_file_path):
		DirAccess.remove_absolute(prediction_file_path)
	print("QA: fan predictions reject fighter/self and duplicate entries, lock before combat, settle once from match authority, award only free non-transferable points and persist with a daily cap.")
	var tower_player: CharacterBody3D = main.get("player") as CharacterBody3D
	var final_boss_script := load("res://scripts/system_tower_opponent.gd") as Script
	if tower_player == null or final_boss_script == null:
		_fail("Power Tower final boss combat fixture could not be created.")
		return
	var final_boss_test := final_boss_script.new() as Node3D
	root.add_child(final_boss_test)
	final_boss_test.call("configure", tower_player, null, 100.0, 12.0, 2.5, true, true)
	final_boss_test.global_position = tower_player.global_position + Vector3(0.0, 0.0, 4.0)
	await physics_frame
	var shockwave_ring := final_boss_test.get_node_or_null("ShockwaveTelegraph") as MeshInstance3D
	var shockwave_label := final_boss_test.get_node_or_null("ShockwaveTelegraphLabel") as Label3D
	if shockwave_ring == null or shockwave_label == null or shockwave_ring.visible:
		_fail("Power Tower sovereign boss is missing its hidden initial shockwave telegraph.")
		final_boss_test.queue_free()
		return
	if not str(final_boss_test.get("health_label").text).contains("PHASE 1") or not is_equal_approx(float(final_boss_test.get("movement_speed")), 2.5) or not is_equal_approx(float(final_boss_test.get("attack_damage")), 12.0):
		_fail("Power Tower sovereign boss initial phase combat profile or phase label is incorrect.")
		final_boss_test.queue_free()
		return
	final_boss_test.set("special_attack_clock", 0.0)
	await physics_frame
	if not shockwave_ring.visible or not shockwave_label.visible or not str(shockwave_label.text).contains("EVADE"):
		_fail("Power Tower sovereign boss did not show a readable shockwave warning.")
		final_boss_test.queue_free()
		return
	final_boss_test.set("special_attack_windup_clock", 0.01)
	await physics_frame
	if shockwave_ring.visible or shockwave_label.visible:
		_fail("Power Tower sovereign boss telegraph did not clear after the shockwave.")
		final_boss_test.queue_free()
		return
	var initial_ring := shockwave_ring.mesh as TorusMesh
	if initial_ring == null or not is_equal_approx(initial_ring.inner_radius, 4.8):
		_fail("Power Tower sovereign boss initial phase ring geometry is incorrect.")
		final_boss_test.queue_free()
		return
	final_boss_test.call("take_damage", 51.0, tower_player)
	await physics_frame
	if int(final_boss_test.get("boss_phase")) != 2:
		_fail("Power Tower sovereign boss did not enter its second health phase.")
		final_boss_test.queue_free()
		return
	if not is_equal_approx((shockwave_ring.mesh as TorusMesh).inner_radius, 5.5):
		_fail("Power Tower sovereign boss phase two did not expand its attack telegraph.")
		final_boss_test.queue_free()
		return
	if not str(final_boss_test.get("health_label").text).contains("PHASE 2") or not is_equal_approx(float(final_boss_test.get("movement_speed")), 3.0) or not is_equal_approx(float(final_boss_test.get("attack_damage")), 13.2) or not is_equal_approx(float(final_boss_test.get("attack_cooldown")), 1.215):
		_fail("Power Tower sovereign boss phase two did not apply its combat escalation and phase label.")
		final_boss_test.queue_free()
		return
	final_boss_test.call("take_damage", 31.0, tower_player)
	await physics_frame
	if int(final_boss_test.get("boss_phase")) != 3:
		_fail("Power Tower sovereign boss did not enter its final health phase.")
		final_boss_test.queue_free()
		return
	if not is_equal_approx((shockwave_ring.mesh as TorusMesh).inner_radius, 6.2):
		_fail("Power Tower sovereign boss phase three did not expand its attack telegraph.")
		final_boss_test.queue_free()
		return
	if not str(final_boss_test.get("health_label").text).contains("PHASE 3") or not is_equal_approx(float(final_boss_test.get("movement_speed")), 3.625) or not is_equal_approx(float(final_boss_test.get("attack_damage")), 15.0) or not is_equal_approx(float(final_boss_test.get("attack_cooldown")), 1.0125):
		_fail("Power Tower sovereign boss final phase did not apply its combat escalation and phase label.")
		final_boss_test.queue_free()
		return
	final_boss_test.call("take_damage", 100.0, tower_player)
	if not bool(final_boss_test.get("defeated_once")):
		_fail("Power Tower sovereign boss did not register its defeat.")
		final_boss_test.queue_free()
		return
	var tower_progression: Node = operations.get("progression") as Node
	var original_highest_floor := int(power_manager.get("highest_cleared_floor"))
	var original_active_floor := int(power_manager.get("active_floor"))
	var original_clear_times: Dictionary = power_manager.get("floor_clear_times").duplicate(true)
	var original_inventory: Dictionary = tower_progression.get("inventory_items").duplicate(true) if tower_progression != null else {}
	var original_credits := int(operations.get("credits"))
	if tower_progression == null:
		_fail("Power Tower final reward test has no player progression manager.")
		return
	power_manager.set("highest_cleared_floor", 199)
	power_manager.set("active_floor", 200)
	operations.set("active_power_floor_data", boss_data.duplicate(true))
	operations.set("power_floor_in_progress", true)
	operations.set("power_floor_started_at", Time.get_ticks_msec() - 1500)
	operations.set("active_opponents", {})
	operations.call("_complete_power_floor")
	var final_rewards_granted := true
	for reward_id in final_rewards:
		if int(tower_progression.call("get_item_count", str(reward_id))) <= int(original_inventory.get(str(reward_id), 0)):
			final_rewards_granted = false
	if int(power_manager.get("highest_cleared_floor")) != 200 or int(power_manager.get("active_floor")) != 0 or int(operations.get("credits")) <= original_credits or not final_rewards_granted:
		_fail("Power Tower final boss clear did not grant the sovereign rewards, credits and completion record.")
		power_manager.set("highest_cleared_floor", original_highest_floor)
		power_manager.set("active_floor", original_active_floor)
		power_manager.set("floor_clear_times", original_clear_times)
		power_manager.call("_save_progress")
		tower_progression.set("inventory_items", original_inventory)
		tower_progression.call("save_progress")
		operations.set("credits", original_credits)
		operations.call("_save_wallet")
		return
	power_manager.set("highest_cleared_floor", original_highest_floor)
	power_manager.set("active_floor", original_active_floor)
	power_manager.set("floor_clear_times", original_clear_times)
	power_manager.call("_save_progress")
	tower_progression.set("inventory_items", original_inventory)
	tower_progression.call("save_progress")
	operations.set("credits", original_credits)
	operations.call("_save_wallet")
	operations.set("active_power_floor_data", {})
	operations.set("power_floor_in_progress", false)
	for individual_floor in [1, 3, 5, 10, 25, 50, 100, 150, 199, 200]:
		var individual_data: Dictionary = power_manager.call("get_floor_data", individual_floor)
		if int(individual_data.get("opponent_count", 0)) != 1 or int(individual_data.get("wave_count", 0)) != 1 or str(individual_data.get("competition_format", "")) != "INDIVIDUAL_1V1":
			_fail("Power Tower individual challenge regression failed at floor %d." % individual_floor)
			power_manager.set("highest_cleared_floor", original_highest_floor)
			power_manager.set("active_floor", original_active_floor)
			power_manager.set("floor_clear_times", original_clear_times)
			power_manager.call("_save_progress")
			tower_progression.set("inventory_items", original_inventory)
			tower_progression.call("save_progress")
			operations.set("credits", original_credits)
			operations.call("_save_wallet")
			return
	power_manager.set("highest_cleared_floor", 5)
	power_manager.set("active_floor", 6)
	operations.set("current_tower_id", "power_tower_baghdad")
	operations.set("active_power_floor_data", power_manager.call("get_floor_data", 6))
	operations.set("power_floor_in_progress", true)
	operations.set("active_opponents", {})
	operations.call("_on_player_wounded")
	if int(power_manager.get("highest_cleared_floor")) != 5 or int(power_manager.get("active_floor")) != 0 or bool(operations.get("power_floor_in_progress")):
		_fail("Power Tower wound/abandon recovery did not clear the active attempt without crediting the floor.")
		power_manager.set("highest_cleared_floor", original_highest_floor)
		power_manager.set("active_floor", original_active_floor)
		power_manager.set("floor_clear_times", original_clear_times)
		power_manager.call("_save_progress")
		tower_progression.set("inventory_items", original_inventory)
		tower_progression.call("save_progress")
		operations.set("credits", original_credits)
		operations.call("_save_wallet")
		return
	power_manager.set("highest_cleared_floor", original_highest_floor)
	power_manager.set("active_floor", original_active_floor)
	power_manager.set("floor_clear_times", original_clear_times)
	power_manager.call("_save_progress")
	tower_progression.set("inventory_items", original_inventory)
	tower_progression.call("save_progress")
	operations.set("credits", original_credits)
	operations.call("_save_wallet")
	operations.set("active_power_floor_data", {})
	operations.set("power_floor_in_progress", false)
	operations.set("active_opponents", {})
	operations.call("_refresh_power_tower_progress_board")
	var shopping_workshop_room := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 14) as Node3D
	if shopping_workshop_room == null or shopping_workshop_room.get_node_or_null("WeaponsForge") == null or shopping_workshop_room.get_node_or_null("ElixirLaboratory") == null:
		_fail("Shopping Tower weapon forge and elixir laboratory stations are missing.")
		return
	var forge_area := shopping_workshop_room.get_node("WeaponsForge/CraftingStationInteraction") as Area3D
	if forge_area == null or not forge_area.is_in_group("system_interactable") or not forge_area.has_meta("system_tower_staff_id"):
		_fail("Shopping Tower crafting station is not connected to its NPC employee.")
		return
	var hotel_reception_room := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 27) as Node3D
	var hotel_suite_room := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 28) as Node3D
	if hotel_reception_room == null or hotel_suite_room == null or hotel_reception_room.get_node_or_null("SYSTEMHotelFacilities/HotelReceptionInteraction") == null or hotel_suite_room.get_node_or_null("SYSTEMHotelFacilities/HotelSuiteBookingInteraction") == null:
		_fail("SYSTEM Hotel reception or guest-suite booking area is missing from Shopping Tower floors 27–28.")
		return
	for room_value in operations.call("_get_hotel_room_catalog"):
		var room_data: Dictionary = room_value
		var room_id := str(room_data.get("id", ""))
		var interior := hotel_suite_room.get_node_or_null("SYSTEMHotelFacilities/HotelRoomInterior_" + room_id) as Node3D
		if interior == null:
			_fail("Hotel room interior is missing: " + room_id)
			return
		for required_part in ["HotelRoomFloor", "HotelRoomBed", "HotelRoomWardrobe", "HotelRoomDesk", "HotelRoomBathroom", "HotelRoomDoor", "HotelRoomWindow", "HotelRoomDoorInteraction"]:
			if interior.get_node_or_null(required_part) == null:
				_fail("Hotel room %s is missing interior component %s." % [room_id, required_part])
				return
		var room_interaction := interior.get_node_or_null("HotelRoomDoorInteraction") as Area3D
		if room_interaction == null or not room_interaction.is_in_group("system_interactable") or str(room_interaction.get_meta("system_hotel_room_id", "")) != room_id:
			_fail("Hotel room door interaction is not linked to its catalog room.")
			return
	if hotel_suite_room.get_node_or_null("SYSTEMHotelFacilities/HotelRoomInterior_hotel_hunter_suite/HotelRoomHunterGearRack") == null or hotel_suite_room.get_node_or_null("SYSTEMHotelFacilities/HotelRoomInterior_hotel_elite_vip/HotelRoomVIPDiningTable") == null:
		_fail("Hunter suite or VIP hotel room is missing its signature furnishings.")
		return
	var preview_booking_snapshot: Dictionary = operations.get("hotel_bookings").duplicate(true)
	var preview_credits_snapshot := int(operations.get("credits"))
	operations.set("hotel_bookings", {})
	operations.set("credits", maxi(preview_credits_snapshot, 500))
	operations.call("open_hotel_room_preview", "hotel_standard_01")
	await process_frame
	var hotel_preview_title := operations.get("title_label") as Label
	var hotel_preview_content := operations.get("content") as VBoxContainer
	var hotel_preview_button: Button
	if hotel_preview_content != null:
		for preview_child in hotel_preview_content.get_children():
			if preview_child is Button:
				hotel_preview_button = preview_child as Button
				break
	var hotel_preview_valid := hotel_preview_title != null and hotel_preview_title.text.contains("غرفة قياسية 01") and hotel_preview_button != null and not hotel_preview_button.disabled
	operations.set("hotel_bookings", preview_booking_snapshot)
	operations.set("credits", preview_credits_snapshot)
	operations.call("_save_hotel_bookings")
	if not hotel_preview_valid:
		_fail("Hotel room door preview did not display an available, rank-eligible booking action.")
		return
	var shopping_staff: Array = operations.get("staff_by_tower").get("shopping_tower_baghdad", [])
	if shopping_staff.size() != 9:
		_fail("Shopping Tower must create all nine management, shop, workshop, restaurant, hotel and advertising staff roles.")
		return
	if not operations.has_method("_book_hotel_room") or not operations.has_method("_check_in_hotel_room") or not operations.has_method("_checkout_hotel_room") or not operations.has_method("_save_hotel_bookings") or not operations.has_method("_start_hotel_room_cleaning") or not operations.has_method("_complete_hotel_room_cleaning") or not operations.has_method("_is_hotel_room_available"):
		_fail("SYSTEM Hotel reservation/check-in/check-out persistence methods are missing.")
		return
	if not operations.has_method("open_hotel_room_preview"):
		_fail("Hotel room door preview and booking entry point is missing.")
		return
	if not operations.has_method("_place_hotel_room_service_order") or not operations.has_method("_update_hotel_room_service_order"):
		_fail("SYSTEM Hotel room-service order lifecycle methods are missing.")
		return
	var room_service_snapshot: Dictionary = operations.get("hotel_bookings").duplicate(true)
	var room_service_credits := int(operations.get("credits"))
	var service_room_id := "hotel_standard_01"
	var service_now := int(Time.get_unix_time_from_system())
	operations.set("hotel_bookings", {service_room_id: {"room_id": service_room_id, "room_name": "غرفة خدمة الاختبار", "guest_id": "local_player", "check_in_unix": service_now, "check_out_unix": service_now + 86400, "status": "checked_in", "room_service_orders": []}})
	operations.set("credits", maxi(room_service_credits, 100))
	operations.call("_place_hotel_room_service_order", "restaurant_kebab", "كباب عراقي", 68)
	var service_booking: Dictionary = operations.get("hotel_bookings").get(service_room_id, {})
	var service_orders: Array = service_booking.get("room_service_orders", [])
	var service_order_ok := service_orders.size() == 1 and int(operations.get("credits")) == maxi(room_service_credits, 100) - 68 and str(service_orders[0].get("status", "")) == "placed"
	if service_order_ok:
		operations.call("_update_hotel_room_service_order", 0, "preparing")
		service_booking = operations.get("hotel_bookings").get(service_room_id, {})
		service_orders = service_booking.get("room_service_orders", [])
		service_order_ok = service_orders.size() == 1 and str(service_orders[0].get("status", "")) == "preparing"
	if service_order_ok:
		operations.call("_update_hotel_room_service_order", 0, "delivered")
		service_booking = operations.get("hotel_bookings").get(service_room_id, {})
		service_orders = service_booking.get("room_service_orders", [])
		service_order_ok = service_orders.size() == 1 and str(service_orders[0].get("status", "")) == "delivered"
	operations.set("hotel_bookings", room_service_snapshot)
	operations.set("credits", room_service_credits)
	operations.call("_save_hotel_bookings")
	operations.call("_save_wallet")
	if not service_order_ok:
		_fail("SYSTEM Hotel room service did not complete the paid placed/preparing/delivered lifecycle.")
		return
	var original_hotel_bookings: Dictionary = operations.get("hotel_bookings").duplicate(true)
	var original_hotel_credits := int(operations.get("credits"))
	operations.set("hotel_bookings", {})
	operations.set("credits", maxi(original_hotel_credits, 500))
	operations.call("_book_hotel_room", "hotel_standard_01", "غرفة قياسية 01", 180, "F", 1)
	var hotel_booking_fixture: Dictionary = operations.get("hotel_bookings").get("hotel_standard_01", {})
	if hotel_booking_fixture.is_empty() or int(operations.get("credits")) != maxi(original_hotel_credits, 500) - 180:
		operations.set("hotel_bookings", original_hotel_bookings)
		operations.set("credits", original_hotel_credits)
		operations.call("_save_hotel_bookings")
		operations.call("_save_wallet")
		_fail("SYSTEM Hotel did not reserve an available room or deduct the correct one-night rate.")
		return
	operations.call("_check_in_hotel_room")
	var checked_in_fixture: Dictionary = operations.get("hotel_bookings").get("hotel_standard_01", {})
	if int(checked_in_fixture.get("check_in_unix", 0)) <= 0 or str(checked_in_fixture.get("status", "")) != "checked_in":
		operations.set("hotel_bookings", original_hotel_bookings)
		operations.set("credits", original_hotel_credits)
		operations.call("_save_hotel_bookings")
		operations.call("_save_wallet")
		_fail("SYSTEM Hotel check-in did not persist the guest arrival state.")
		return
	operations.call("_checkout_hotel_room")
	var checked_out_fixture: Dictionary = operations.get("hotel_bookings").get("hotel_standard_01", {})
	if str(checked_out_fixture.get("status", "")) != "needs_cleaning" or operations.call("_is_hotel_room_available", "hotel_standard_01"):
		operations.set("hotel_bookings", original_hotel_bookings)
		operations.set("credits", original_hotel_credits)
		operations.call("_save_hotel_bookings")
		operations.call("_save_wallet")
		_fail("SYSTEM Hotel checkout must retain the room as unavailable until housekeeping.")
		return
	operations.call("_start_hotel_room_cleaning", "hotel_standard_01")
	var cleaning_fixture: Dictionary = operations.get("hotel_bookings").get("hotel_standard_01", {})
	if str(cleaning_fixture.get("status", "")) != "cleaning":
		operations.set("hotel_bookings", original_hotel_bookings)
		operations.set("credits", original_hotel_credits)
		operations.call("_save_hotel_bookings")
		operations.call("_save_wallet")
		_fail("SYSTEM Hotel housekeeping did not enter the cleaning state.")
		return
	operations.call("_complete_hotel_room_cleaning", "hotel_standard_01")
	var ready_fixture: Dictionary = operations.get("hotel_bookings").get("hotel_standard_01", {})
	if str(ready_fixture.get("status", "")) != "ready" or not bool(ready_fixture.get("inspection_passed", false)) or not operations.call("_is_hotel_room_available", "hotel_standard_01"):
		operations.set("hotel_bookings", original_hotel_bookings)
		operations.set("credits", original_hotel_credits)
		operations.call("_save_hotel_bookings")
		operations.call("_save_wallet")
		_fail("SYSTEM Hotel room did not become bookable after cleaning and inspection.")
		return
	operations.set("hotel_bookings", original_hotel_bookings)
	operations.set("credits", original_hotel_credits)
	operations.call("_save_hotel_bookings")
	operations.call("_save_wallet")
	var restaurant_floor := operations.call("_ensure_floor_room", "shopping_tower_baghdad", 29) as Node3D
	if restaurant_floor == null:
		_fail("Shopping Tower restaurant floor 29 was not generated.")
		return
	var restaurant_table_count := 0
	var restaurant_table_interaction: StaticBody3D
	for table_index in range(4):
		var table_root := restaurant_floor.get_node_or_null("RestaurantTable_%02d" % table_index) as Node3D
		var table_body := table_root.get_node_or_null("RestaurantTableInteraction") as StaticBody3D if table_root != null else null
		if table_body != null and table_body.is_in_group("system_interactable") and table_body.has_meta("system_restaurant_table_id") and table_body.has_meta("system_interaction_prompt"):
			restaurant_table_count += 1
			if restaurant_table_interaction == null:
				restaurant_table_interaction = table_body
	if restaurant_table_count != 4 or restaurant_table_interaction == null:
		_fail("Restaurant floor must generate four physical, interactable dining tables.")
		return
	if not operations.has_method("open_restaurant_table") or not operations.has_method("_place_restaurant_order") or not operations.has_method("_advance_restaurant_order") or not operations.has_method("_save_restaurant_orders") or not operations.has_method("_load_restaurant_orders"):
		_fail("Restaurant table ordering and kitchen service lifecycle methods are missing.")
		return
	var restaurant_orders_snapshot: Dictionary = operations.get("restaurant_orders").duplicate(true)
	var restaurant_history_snapshot: Array = operations.get("restaurant_order_history").duplicate(true)
	var restaurant_drafts_snapshot: Dictionary = operations.get("restaurant_draft_items").duplicate(true)
	var restaurant_credits_snapshot := int(operations.get("credits"))
	var restaurant_test_table_id := "validator_restaurant_table"
	operations.set("restaurant_orders", {})
	operations.set("restaurant_order_history", [])
	operations.set("restaurant_draft_items", {restaurant_test_table_id: [{"item_id": "restaurant_kebab", "name": "كباب عراقي", "price": 68}, {"item_id": "restaurant_fresh_juice", "name": "عصير طازج", "price": 22}]})
	operations.set("credits", maxi(restaurant_credits_snapshot, 200))
	var had_player_seat_meta := player.has_meta("system_restaurant_seated_table_id")
	var previous_player_seat_meta: Variant = player.get_meta("system_restaurant_seated_table_id", "")
	var previous_player_seated_state := bool(player.get_meta("system_restaurant_seated", false))
	player.set_meta("system_restaurant_seated_table_id", restaurant_test_table_id)
	player.set_meta("system_restaurant_seated", true)
	operations.call("_place_restaurant_order", restaurant_test_table_id)
	var restaurant_test_order: Dictionary = operations.get("restaurant_orders").get(restaurant_test_table_id, {})
	var restaurant_order_ok := str(restaurant_test_order.get("status", "")) == "awaiting_waiter" and int(restaurant_test_order.get("total", 0)) == 90 and int(operations.get("credits")) == maxi(restaurant_credits_snapshot, 200) - 90
	if restaurant_order_ok:
		operations.call("_advance_restaurant_order", restaurant_test_table_id, "placed")
		operations.call("_save_restaurant_orders")
		operations.set("restaurant_orders", {})
		operations.call("_load_restaurant_orders")
		restaurant_test_order = operations.get("restaurant_orders").get(restaurant_test_table_id, {})
		restaurant_order_ok = str(restaurant_test_order.get("status", "")) == "placed"
	if restaurant_order_ok:
		operations.call("_advance_restaurant_order", restaurant_test_table_id, "preparing")
		operations.call("_advance_restaurant_order", restaurant_test_table_id, "ready")
		operations.call("_advance_restaurant_order", restaurant_test_table_id, "served")
		var persisted_test_order: Dictionary = operations.get("restaurant_orders").get(restaurant_test_table_id, {})
		persisted_test_order["meal_consumed"] = true
		var persisted_test_orders: Dictionary = operations.get("restaurant_orders")
		persisted_test_orders[restaurant_test_table_id] = persisted_test_order
		operations.set("restaurant_orders", persisted_test_orders)
		operations.call("_advance_restaurant_order", restaurant_test_table_id, "completed")
		var restaurant_history: Array = operations.get("restaurant_order_history")
		restaurant_order_ok = not operations.get("restaurant_orders").has(restaurant_test_table_id) and not restaurant_history.is_empty() and str(restaurant_history[-1].get("status", "")) == "completed"
	if restaurant_order_ok:
		operations.call("_rate_restaurant_order", restaurant_test_table_id, 5)
		operations.call("_rate_restaurant_order", restaurant_test_table_id, 3)
		var rated_history: Array = operations.get("restaurant_order_history")
		restaurant_order_ok = int(rated_history[-1].get("rating", 0)) == 5 and int(rated_history[-1].get("rated_at_unix", 0)) > 0
	if had_player_seat_meta:
		player.set_meta("system_restaurant_seated_table_id", previous_player_seat_meta)
	else:
		player.remove_meta("system_restaurant_seated_table_id")
	player.set_meta("system_restaurant_seated", previous_player_seated_state)
	operations.set("restaurant_orders", restaurant_orders_snapshot)
	operations.set("restaurant_order_history", restaurant_history_snapshot)
	operations.set("restaurant_draft_items", restaurant_drafts_snapshot)
	operations.set("credits", restaurant_credits_snapshot)
	operations.call("_save_restaurant_orders")
	operations.call("_save_wallet")
	if not restaurant_order_ok:
		_fail("Restaurant ordering failed payment, persisted kitchen preparation, serving and table-release lifecycle checks.")
		return
	var boss_room := operations.call("_ensure_floor_room", "power_tower_baghdad", 200) as Node3D
	if boss_room == null or boss_room.get_node_or_null("BossTrialPlatform") == null:
		_fail("Power Tower floor 200 boss arena was not generated.")
		return
	var boss_theme_pillar_count := 0
	for boss_room_child in boss_room.get_children():
		if str(boss_room_child.name).begins_with("ArenaThemePillar_"):
			boss_theme_pillar_count += 1
	if boss_room.get_node_or_null("ArenaThemeRing") == null or boss_theme_pillar_count != 4 or str(boss_room.get_meta("system_power_tower_theme", "")) != "SOVEREIGN":
		_fail("Power Tower final sovereign arena is missing its unique themed ring and four pylons.")
		return
	var spectator_gallery := boss_room.get_node_or_null("PowerTowerSpectatorGallery") as Node3D
	var spectator_seat_count := 0
	if spectator_gallery != null:
		for spectator_seat in spectator_gallery.get_children():
			if bool(spectator_seat.get_meta("system_power_tower_spectator_seat", false)):
				spectator_seat_count += 1
				if spectator_seat.get_node_or_null("SpectatorSeatCollision") == null or bool(spectator_seat.get_meta("system_spectator_seat_reserved", true)) or int(spectator_seat.get_meta("system_spectator_seat_floor", 0)) != 200:
					_fail("A Power Tower spectator seat is missing its collision, floor identity or free initial state.")
					return
	if spectator_gallery == null or spectator_seat_count != 48 or int(spectator_gallery.get_meta("system_spectator_seat_count", 0)) != 48 or str(spectator_gallery.get_meta("system_competition_format", "")) != "INDIVIDUAL_1V1":
		_fail("Power Tower floor 200 must provide a physical 48-seat spectator gallery for individual duels.")
		return
	if boss_room.get_node_or_null("ArenaChallengeDisplay") == null:
		_fail("Power Tower arena challenge display is missing.")
		return
	if not operations.has_method("_buy_product") or not operations.has_method("_sell_item"):
		_fail("NPC-supervised buy/sell transaction methods are missing.")
		return
	print("QA: Power Tower final arena, ten themes and 48-seat spectator gallery passed.")
	var shopping_tower := tower_manager.get_node_or_null("ShoppingTower") as Node3D
	print("QA: Starting Shopping Tower elevator regression; registered=%s player_valid=%s" % [str(operations.get("tower_nodes").has("shopping_tower_baghdad")), str(is_instance_valid(player))])
	operations.call("open_tower", "shopping_tower_baghdad")
	operations.call("_travel_to_floor", "shopping_tower_baghdad", 1)
	print("QA: Shopping Tower travel request issued.")
	await create_timer(2.8).timeout
	print("QA: Shopping Tower elevator wait completed.")
	if shopping_tower.get_node_or_null("ActiveTowerElevatorCar") == null:
		var elevator_status_label := operations.get("status_label") as Label
		var elevator_active_car := operations.get("active_elevator_car") as Node3D
		var elevator_tower_nodes: Dictionary = operations.get("tower_nodes")
		print("QA DIAGNOSTIC: elevator missing | current_tower=%s | player_valid=%s | tower_registered=%s | active_car=%s | active_car_tower=%s | status=%s" % [str(operations.get("current_tower_id")), str(is_instance_valid(player)), str(elevator_tower_nodes.has("shopping_tower_baghdad")), str(is_instance_valid(elevator_active_car)), str(operations.get("active_elevator_tower_id")), elevator_status_label.text if elevator_status_label != null else "no status label"])
		_fail("Visible elevator cabin was not created for tower travel.")
		return
	if bool(player.get_meta("system_tower_elevator_active", true)):
		_fail("Elevator transition did not complete.")
		return
	operations.call("return_to_lobby")
	await create_timer(3.0).timeout
	if shopping_tower.get_node_or_null("ActiveTowerElevatorCar") != null:
		_fail("Elevator cabin was not cleaned up after returning to the lobby.")
		return
	var district_tower_lifts := {
		"hunter_association_tower_baghdad": "HunterAssociationTower",
		"business_investment_tower_baghdad": "BusinessInvestmentTower",
		"shopping_tower_baghdad": "ShoppingTower",
		"entertainment_tower_baghdad": "EntertainmentTower",
		"technology_tower_baghdad": "TechnologyTower"
	}
	for district_tower_id in district_tower_lifts.keys():
		var district_tower := tower_manager.get_node_or_null(str(district_tower_lifts[district_tower_id])) as Node3D
		if district_tower == null:
			_fail("District tower lift regression could not resolve: " + str(district_tower_id))
			return
		operations.call("open_tower", str(district_tower_id))
		operations.call("_travel_to_floor", str(district_tower_id), 2)
		await create_timer(2.8).timeout
		var lift_floor := operations.get("active_floor_root") as Node3D
		var lift_car := district_tower.get_node_or_null("ActiveTowerElevatorCar") as Node3D
		if lift_floor == null or int(lift_floor.get_meta("system_tower_floor_number", 0)) != 2:
			_fail("Elevator did not deliver the player to floor 2 of " + str(district_tower_id))
			return
		if lift_car == null or absf(lift_car.position.y - lift_floor.position.y) > 0.08:
			_fail("Elevator cabin did not reach the selected floor in " + str(district_tower_id))
			return
		if bool(player.get_meta("system_tower_elevator_active", true)):
			_fail("Elevator transition remained locked after reaching " + str(district_tower_id))
			return
		operations.call("return_to_lobby")
		await create_timer(3.0).timeout
		if district_tower.get_node_or_null("ActiveTowerElevatorCar") != null or operations.get("active_floor_root") != null:
			_fail("Elevator did not cleanly return to the lobby in " + str(district_tower_id))
			return
	var shop_progression: Node = operations.get("progression") as Node
	if shop_progression == null:
		_fail("Shopping tower purchase test has no player progression reference.")
		return
	var shop_employee: Node = null
	var shopping_lobby := shopping_tower.get_node_or_null("PublicLobby_Blockout")
	for child in shopping_lobby.get_children():
		if child.has_meta("system_tower_staff_id"):
			shop_employee = child
			break
	if shop_employee == null:
		_fail("No NPC shop employee can be interacted with.")
		return
	var shop_inventory_snapshot: Dictionary = shop_progression.get("inventory_items").duplicate(true)
	var shop_inventory_fixture: Dictionary = shop_inventory_snapshot.duplicate(true)
	shop_inventory_fixture.erase("water_bottle")
	var shop_stock_snapshot: Dictionary = operations.get("vendor_stock").duplicate(true)
	var shop_stock_fixture: Dictionary = shop_stock_snapshot.duplicate(true)
	shop_stock_fixture["water_bottle"] = int(operations.call("_get_stock_cap", "water_bottle"))
	var shop_credits_snapshot := int(operations.get("credits"))
	shop_progression.set("inventory_items", shop_inventory_fixture)
	operations.set("vendor_stock", shop_stock_fixture)
	operations.set("credits", maxi(shop_credits_snapshot, 100))
	operations.call("open_staff_service", shop_employee)
	var water_stock_before := int(operations.call("get_vendor_stock", "water_bottle"))
	operations.call("_buy_product", "water_bottle", "قارورة ماء", 12)
	var shop_purchase_succeeded := int(shop_progression.call("get_item_count", "water_bottle")) == 1
	var shop_stock_decreased := int(operations.call("get_vendor_stock", "water_bottle")) == water_stock_before - 1
	operations.call("_sell_item", "water_bottle", 1)
	var shop_sale_succeeded := int(shop_progression.call("get_item_count", "water_bottle")) == 0
	var shop_stock_restored := int(operations.call("get_vendor_stock", "water_bottle")) == water_stock_before
	shop_progression.set("inventory_items", shop_inventory_snapshot)
	shop_progression.call("save_progress")
	operations.set("vendor_stock", shop_stock_snapshot)
	operations.call("_save_vendor_stock")
	operations.set("credits", shop_credits_snapshot)
	operations.call("_save_wallet")
	if not shop_purchase_succeeded or not shop_stock_decreased or not shop_sale_succeeded or not shop_stock_restored:
		_fail("NPC shop buy/sell regression failed. Purchase status: " + str(operations.get("status_label").text))
		return
	pilot_progression.call("add_item", "iron_ingot", 1)
	pilot_progression.call("add_item", "wood_plank", 2)
	var craft_result: Dictionary = pilot_progression.call("craft_recipe", "training_sword")
	if not bool(craft_result.get("success", false)) or int(pilot_progression.call("get_item_count", "training_sword")) < 1 or int(pilot_progression.call("get_item_count", "iron_ingot")) != 0 or int(pilot_progression.call("get_item_count", "wood_plank")) != 0:
		_fail("NPC-supervised crafting did not consume ingredients and create the requested weapon.")
		return
	pilot_progression.call("add_item", "training_sword", 1)
	var equip_result: Dictionary = pilot_progression.call("equip_item", "training_sword")
	if not bool(equip_result.get("success", false)) or str(pilot_progression.call("get_equipped_item", "weapon")) != "training_sword":
		_fail("Weapon equipment slot did not accept an owned training sword.")
		return
	if float(pilot_progression.call("get_combat_damage_bonus")) < 5.0:
		_fail("Equipped weapon did not apply its combat damage bonus.")
		return
	operations.call("_sell_item", "training_sword", 1)
	if int(pilot_progression.call("get_item_count", "training_sword")) != 2:
		_fail("NPC vendor allowed sale of a currently equipped weapon.")
		return
	operations.call("_unequip_item", "weapon")
	if not str(pilot_progression.call("get_equipped_item", "weapon")).is_empty():
		_fail("NPC service did not remove the weapon from its equipment slot.")
		return
	pilot_progression.call("add_item", "iron_ingot", 2)
	var upgrade_result: Dictionary = pilot_progression.call("upgrade_item", "training_sword")
	if not bool(upgrade_result.get("success", false)) or int(pilot_progression.call("get_item_upgrade_level", "training_sword")) != 1:
		_fail("NPC weapon upgrade service did not apply the first equipment upgrade.")
		return
	pilot_progression.call("equip_item", "training_sword")
	pilot_progression.call("consume_equipment_durability", "weapon", 100.0)
	if float(pilot_progression.call("get_item_durability", "training_sword")) > 0.0 or float(pilot_progression.call("get_combat_damage_bonus")) > 0.0:
		_fail("Broken weapon durability did not disable its equipment damage bonus.")
		return
	pilot_progression.call("add_item", "repair_kit", 1)
	var repair_result: Dictionary = pilot_progression.call("repair_item", "training_sword")
	if not bool(repair_result.get("success", false)) or float(pilot_progression.call("get_item_durability", "training_sword")) < 99.9 or float(pilot_progression.call("get_combat_damage_bonus")) < 7.0:
		_fail("NPC repair service did not restore the upgraded weapon and its damage bonus.")
		return
	pilot_progression.call("add_item", "strength_elixir", 1)
	var strength_result: Dictionary = pilot_progression.call("consume_elixir", "strength_elixir")
	if not bool(strength_result.get("success", false)) or float(pilot_progression.call("get_combat_damage_bonus")) < 22.0:
		_fail("Strength elixir did not stack with the upgraded weapon's timed combat bonus.")
		return
	pilot_progression.call("add_item", "speed_elixir", 1)
	pilot_progression.call("consume_elixir", "speed_elixir")
	if float(pilot_progression.call("get_movement_multiplier")) <= 1.0:
		_fail("Speed elixir did not increase the player movement multiplier.")
		return
	pilot_progression.call("add_item", "endurance_elixir", 1)
	pilot_progression.call("consume_elixir", "endurance_elixir")
	if float(pilot_progression.call("get_defense_bonus")) < 12.0:
		_fail("Endurance elixir did not apply a defense bonus.")
		return
	pilot_progression.call("add_item", "energy_elixir", 1)
	pilot_progression.call("consume_elixir", "energy_elixir")
	if float(pilot_progression.call("get_attack_cooldown_multiplier")) >= 1.0:
		_fail("Energy elixir did not reduce the attack cooldown multiplier.")
		return
	pilot_progression.call("add_item", "nen_awakening_elixir", 1)
	var awakening_result: Dictionary = pilot_progression.call("consume_elixir", "nen_awakening_elixir")
	if not bool(awakening_result.get("success", false)):
		_fail("Nen Awakening Elixir did not awaken Nen: " + str(awakening_result))
		return
	pilot_progression.call("add_item", "nen_control_elixir", 1)
	pilot_progression.call("consume_elixir", "nen_control_elixir")
	if not bool(pilot_progression.get("nen_unlocked")) or int(pilot_progression.get("nen_control_rank")) != 2:
		_fail("Nen Awakening/Control elixirs did not update the player's Nen state.")
		return
	operations.call("open_tower", "hunter_association_tower_baghdad")
	var demo_button := operations.get("content").get_node_or_null("NenTrainingDemoButton") as Button
	if demo_button == null or not demo_button.text.contains("ضربة النِن"):
		_fail("Hunter Association Tower is missing its Nen strike training demonstration.")
		return
	pilot_progression.call("add_item", "nen_control_elixir", 2)
	pilot_progression.call("consume_elixir", "nen_control_elixir")
	pilot_progression.call("consume_elixir", "nen_control_elixir")
	if int(pilot_progression.get("nen_control_rank")) != 4:
		_fail("Nen control elixirs did not unlock the rank-four ability threshold.")
		return
	var combat_system: Node = main.get("modern_world_combat_system") as Node
	if combat_system == null or not combat_system.has_method("light_attack") or not combat_system.has_method("skill_one") or not combat_system.has_method("skill_two") or not combat_system.has_method("dodge"):
		_fail("Modern World combat system was not created or is missing mobile combat actions.")
		return
	if combat_system.get("actor") != player or combat_system.get("progression") != pilot_progression:
		_fail("Modern World combat system is not bound to the active player and progression manager.")
		return
	var mobile_controls: Node = main.get("mobile_controls") as Node
	if mobile_controls == null:
		_fail("Mobile controls were not created.")
		return
	var mobile_callbacks := {
		"attack_pressed": "_on_mobile_attack_pressed",
		"skill_one_pressed": "_on_mobile_skill_one_pressed",
		"skill_two_pressed": "_on_mobile_skill_two_pressed",
		"dodge_pressed": "_on_mobile_dodge_pressed"
	}
	for signal_name in mobile_callbacks.keys():
		if not mobile_controls.is_connected(str(signal_name), Callable(main, str(mobile_callbacks[signal_name]))):
			_fail("Mobile combat signal is not connected: " + str(signal_name))
			return
	pilot_progression.set("nen_burst_cooldown_remaining", 0.0)
	var clean_effects: Dictionary = pilot_progression.get("active_elixir_effects")
	clean_effects.erase("nen_burst")
	pilot_progression.set("active_elixir_effects", clean_effects)
	pilot_progression.call("_refresh_nen_burst_button")
	var nen_burst_result: Dictionary = combat_system.call("skill_one")
	var nen_button: Button = pilot_progression.get("nen_burst_button") as Button
	if not bool(nen_burst_result.get("success", false)):
		_fail("Mobile Nen Burst skill activation failed: " + str(nen_burst_result))
		return
	if not pilot_progression.get("active_elixir_effects").has("nen_burst"):
		_fail("Mobile Nen Burst did not apply its timed combat effect.")
		return
	if nen_button == null or not nen_button.visible:
		_fail("Mobile Nen Burst did not expose its cooldown HUD button.")
		return
	await create_timer(0.85).timeout
	var charged_result: Dictionary = combat_system.call("skill_two")
	if not bool(charged_result.get("success", false)) or str(charged_result.get("ability_id", "")) != "charged_strike":
		_fail("Second mobile combat skill did not perform a charged strike.")
		return
	var dodge_position_before: Vector3 = player.global_position
	main.call("_on_mobile_dodge_pressed")
	if player.global_position.distance_to(dodge_position_before) < 2.0:
		_fail("Mobile dodge input did not move the player.")
		return

	var credits_before := int(operations.call("get_operations_status").get("credits", 0))
	var final_credit_reward := int(operations.call("grant_power_tower_credits", 200, true))
	var credits_after := int(operations.call("get_operations_status").get("credits", 0))
	if final_credit_reward != 8075 or credits_after - credits_before != 8075:
		_fail("Power Tower floor 200 did not grant the unique SYSTEM credit reward.")
		return
	var health_manager: Node = main.get("player_combat_health") as Node
	health_manager.call("receive_damage", 150.0, null)
	pilot_progression.call("add_item", "healing_elixir", 1)
	var healing_result: Dictionary = pilot_progression.call("consume_elixir", "healing_elixir")
	if not bool(healing_result.get("success", false)) or not bool(health_manager.get("is_wounded")) or float(health_manager.get("current_health")) <= 30.0:
		_fail("Healing elixir must restore field health without clearing the persistent wound state.")
		return

	var activity_stats_snapshot: Dictionary = operations.get("facility_activity_stats").duplicate(true)
	var activity_credits_snapshot := int(operations.get("credits"))
	var bowling_room := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 23) as Node3D
	var bowling_facility := bowling_room.get_node_or_null("SpecialFacility_bowling") as Node3D if bowling_room != null else null
	if bowling_facility == null or bowling_facility.get_node_or_null("BowlingLanePhysics") == null:
		_fail("Bowling lane physics body was not generated.")
		return
	var bowling_pin_count := 0
	for bowling_child in bowling_facility.get_children():
		if bowling_child is RigidBody3D and str(bowling_child.name).begins_with("BowlingPin_"):
			bowling_pin_count += 1
	if bowling_pin_count != 10:
		_fail("Bowling lane must spawn ten physical rigid-body pins.")
		return
	operations.set("current_facility_root", bowling_facility)
	operations.call("_on_facility_aim_changed", 0.5)
	if absf(float(operations.get("facility_aim")) - 0.5) > 0.001:
		_fail("Touch aim control did not update the facility throw direction.")
		return
	operations.call("_on_facility_aim_changed", 0.0)
	var court_room := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 22) as Node3D
	var court_facility := court_room.get_node_or_null("SpecialFacility_sports_court") as Node3D if court_room != null else null
	if court_facility == null or court_facility.get_node_or_null("BasketballScoringSensor") == null:
		_fail("Basketball scoring sensor was not generated.")
		return
	var arcade_room := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 25) as Node3D
	var arcade_facility := arcade_room.get_node_or_null("SpecialFacility_arcade") as Node3D if arcade_room != null else null
	if arcade_facility == null:
		_fail("Arcade facility was not generated.")
		return
	if arcade_facility.get_node_or_null("ArcadeCabinet_00") == null or arcade_facility.get_node_or_null("ArcadeCabinet_05") == null:
		_fail("Arcade gallery must generate six individually addressable cabinets.")
		return
	var arcade_interaction_count := 0
	for cabinet_index in range(6):
		var cabinet_interaction := arcade_facility.get_node_or_null("ArcadeCabinetInteraction_%02d" % cabinet_index) as Area3D
		if cabinet_interaction == null or not cabinet_interaction.is_in_group("system_interactable"):
			_fail("Arcade cabinet %d is missing its direct interaction area." % cabinet_index)
			return
		if int(cabinet_interaction.get_meta("system_arcade_cabinet_id", -1)) != cabinet_index:
			_fail("Arcade cabinet interaction metadata does not match its cabinet ID.")
			return
		if str(cabinet_interaction.get_meta("system_arcade_cabinet_mode", "")) not in ["shooter", "memory", "reflex", "puzzle"]:
			_fail("Arcade cabinet must route to a supported playable game mode.")
			return
		arcade_interaction_count += 1
	if arcade_interaction_count != 6:
		_fail("Arcade gallery must expose six direct cabinet interactions.")
		return
	var arcade_sensor_count := 0
	for arcade_child in arcade_facility.get_children():
		if arcade_child is Area3D and str(arcade_child.name).begins_with("ArcadeTargetSensor_"):
			arcade_sensor_count += 1
	if arcade_sensor_count != 5:
		_fail("Arcade gallery must have five physical target sensors.")
		return
	var perfect_bowling_rolls: Array = []
	for _roll in range(12):
		perfect_bowling_rolls.append(10)
	if int(operations.call("_calculate_bowling_score", perfect_bowling_rolls)) != 300:
		_fail("Bowling scoring engine did not calculate a perfect 300 game.")
		return
	var gutter_bowling_rolls: Array = []
	for _roll in range(20):
		gutter_bowling_rolls.append(0)
	if int(operations.call("_calculate_bowling_score", gutter_bowling_rolls)) != 0:
		_fail("Bowling scoring engine did not calculate a zero-pin game.")
		return
	var spare_bowling_rolls: Array = []
	for _frame in range(9):
		spare_bowling_rolls.append(5)
		spare_bowling_rolls.append(5)
	spare_bowling_rolls.append_array([5, 5, 5])
	if int(operations.call("_calculate_bowling_score", spare_bowling_rolls)) != 150:
		_fail("Bowling scoring engine did not calculate ten consecutive spares.")
		return
	var memory_sequence := [2, 0, 3, 1, 2]
	var memory_first := operations.call("_evaluate_arcade_memory_input", memory_sequence, 0, 2) as Dictionary
	var memory_wrong := operations.call("_evaluate_arcade_memory_input", memory_sequence, 1, 3) as Dictionary
	var memory_last := operations.call("_evaluate_arcade_memory_input", memory_sequence, 4, 2) as Dictionary
	var memory_invalid_cursor := operations.call("_evaluate_arcade_memory_input", memory_sequence, 5, 0) as Dictionary
	if not bool(memory_first.get("valid", false)) or int(memory_first.get("next_cursor", -1)) != 1:
		_fail("Arcade memory cabinet did not accept a correct first color.")
		return
	if bool(memory_wrong.get("valid", true)) or int(memory_wrong.get("next_cursor", -1)) != 0:
		_fail("Arcade memory cabinet must reset the sequence after a wrong color.")
		return
	if not bool(memory_last.get("complete", false)):
		_fail("Arcade memory cabinet did not complete the five-color sequence.")
		return
	if bool(memory_invalid_cursor.get("valid", true)) or bool(memory_invalid_cursor.get("complete", true)):
		_fail("Arcade memory cabinet must reject inputs after the sequence has ended.")
		return
	if int(operations.call("_calculate_arcade_mode_index", "shooter")) != 0 or int(operations.call("_calculate_arcade_mode_index", "memory")) != 1 or int(operations.call("_calculate_arcade_mode_index", "reflex")) != 2 or int(operations.call("_calculate_arcade_mode_index", "puzzle")) != 3:
		_fail("Arcade cabinet mode selector does not map all four playable games.")
		return
	if int(operations.call("_calculate_arcade_mode_index", "unknown")) != -1:
		_fail("Arcade cabinet mode selector must reject unknown games.")
		return
	var puzzle_questions: Array = operations.call("_arcade_puzzle_questions")
	var puzzle_correct: Dictionary = operations.call("_evaluate_arcade_puzzle_answer", puzzle_questions, 0, 7)
	var puzzle_wrong: Dictionary = operations.call("_evaluate_arcade_puzzle_answer", puzzle_questions, 0, 6)
	var puzzle_last: Dictionary = operations.call("_evaluate_arcade_puzzle_answer", puzzle_questions, 4, 11)
	var puzzle_invalid: Dictionary = operations.call("_evaluate_arcade_puzzle_answer", puzzle_questions, 5, 11)
	if puzzle_questions.size() != 5 or not bool(puzzle_correct.get("correct", false)) or int(puzzle_correct.get("next_cursor", -1)) != 1:
		_fail("Arcade number-puzzle cabinet did not accept a correct first answer.")
		return
	if bool(puzzle_wrong.get("correct", true)) or int(puzzle_wrong.get("next_cursor", -1)) != 0:
		_fail("Arcade number-puzzle cabinet must not advance on a wrong answer.")
		return
	if not bool(puzzle_last.get("complete", false)) or bool(puzzle_invalid.get("valid", true)):
		_fail("Arcade number-puzzle cabinet did not complete or correctly reject an invalid cursor.")
		return
	if int(operations.call("_calculate_arcade_reflex_score", 160)) != 23:
		_fail("Arcade reflex cabinet should award 23 points for a 160 ms reaction.")
		return
	if int(operations.call("_calculate_arcade_reflex_score", 800)) != 15:
		_fail("Arcade reflex cabinet should award fewer points for a slower reaction.")
		return
	if int(operations.call("_calculate_arcade_reflex_score", 6000)) != 0:
		_fail("Arcade reflex cabinet must reject reaction times beyond five seconds.")
		return
	if int(operations.call("_calculate_arcade_target_points", 2, 0)) != 12:
		_fail("Arcade center target scoring did not award 12 base points.")
		return
	if int(operations.call("_calculate_arcade_target_points", 2, 4)) != 20:
		_fail("Arcade combo scoring did not award the capped 8-point combo bonus.")
		return
	if int(operations.call("_calculate_arcade_target_points", -1, 4)) != 0:
		_fail("Arcade invalid target IDs must not award points.")
		return
	var activity_cases := {
		"swimming_pool": ["lap", 3],
		"fitness_gym": ["rep", 8],
		"sports_court": ["shot", 10],
		"bowling": ["throw", 10],
		"cinema": ["watch", 3],
		"arcade": ["hit", 10],
		"family_zone": ["discover", 3],
		"rooftop_leisure": ["photo", 1],
		"robotics_lab": ["assemble", 5],
		"ai_lab": ["analyze", 3],
		"vr_lab": ["checkpoint", 3]
	}
	var bowling_total_pinfall := 0
	var basketball_made_count := 0
	var arcade_hit_count := 0
	var arcade_last_result: Dictionary = {}
	var cinema_scene_count := 0
	for activity_type in activity_cases.keys():
		var activity_case: Array = activity_cases[activity_type]
		if str(activity_type) == "sports_court":
			operations.set("current_facility_root", court_facility)
		elif str(activity_type) == "bowling":
			operations.set("current_facility_root", bowling_facility)
		elif str(activity_type) == "arcade":
			operations.set("current_facility_root", arcade_facility)
		elif str(activity_type) == "cinema":
			operations.set("current_facility_root", cinema_facility)
		elif str(activity_type) == "robotics_lab":
			var robotics_room := operations.call("_ensure_floor_room", "technology_tower_baghdad", 10) as Node3D
			var robotics_facility := robotics_room.get_node_or_null("SpecialFacility_robotics_lab") as Node3D if robotics_room != null else null
			operations.set("current_facility_root", robotics_facility)
		elif str(activity_type) == "vr_lab":
			var vr_room := operations.call("_ensure_floor_room", "technology_tower_baghdad", 30) as Node3D
			var vr_facility := vr_room.get_node_or_null("SpecialFacility_vr_lab") as Node3D if vr_room != null else null
			if vr_facility == null:
				_fail("VR simulation facility was not generated.")
				return
			var vr_course := vr_facility.get_node_or_null("VRSimulationCourse") as Node3D
			if vr_course == null:
				_fail("VR simulation course geometry was not generated.")
				return
			var vr_floor_body := vr_course.get_node_or_null("VRSimulationFloorPhysics") as StaticBody3D
			var vr_floor_collision := vr_floor_body.get_node_or_null("CollisionShape3D") as CollisionShape3D if vr_floor_body != null else null
			if vr_floor_collision == null or not (vr_floor_collision.shape is BoxShape3D):
				var floor_child_names := PackedStringArray()
				if vr_floor_body != null:
					for floor_child in vr_floor_body.get_children():
						floor_child_names.append(str(floor_child.name))
				_fail("VR course floor is missing its named physical BoxShape3D collider. Children: %s" % ", ".join(floor_child_names))
				return
			var vr_floor_shape := vr_floor_collision.shape as BoxShape3D
			if vr_floor_shape.size.distance_to(Vector3(12.0, 0.24, 23.0)) > 0.01:
				_fail("VR course floor collider dimensions do not cover the full 12x23m course.")
				return
			var vr_exit_platform := vr_course.get_node_or_null("VRSimulationExitPlatform") as MeshInstance3D
			var vr_exit_sensor := vr_course.get_node_or_null("VRSimulationExitSensor") as Area3D
			var vr_exit_collision := vr_exit_sensor.get_node_or_null("CollisionShape3D") as CollisionShape3D if vr_exit_sensor != null else null
			if vr_exit_platform == null or vr_exit_collision == null or not (vr_exit_collision.shape is BoxShape3D):
				_fail("VR course exit platform or its named physical BoxShape3D arrival sensor is missing.")
				return
			if (vr_exit_collision.shape as BoxShape3D).size.distance_to(Vector3(4.2, 3.0, 2.4)) > 0.01:
				_fail("VR course exit sensor does not cover the arrival platform.")
				return
			for checkpoint_index in range(3):
				var checkpoint_sensor := vr_course.get_node_or_null("VRCheckpointGate_%02d/VRCheckpointSensor_%02d" % [checkpoint_index, checkpoint_index]) as Area3D
				var checkpoint_collision := checkpoint_sensor.get_node_or_null("CollisionShape3D") as CollisionShape3D if checkpoint_sensor != null else null
				if checkpoint_sensor == null or checkpoint_collision == null or not (checkpoint_collision.shape is BoxShape3D) or not checkpoint_sensor.monitoring:
					_fail("VR course checkpoint %d is missing its active physical BoxShape3D sensor." % checkpoint_index)
					return
				if (checkpoint_collision.shape as BoxShape3D).size.distance_to(Vector3(3.8, 3.0, 1.2)) > 0.01:
					_fail("VR course checkpoint %d sensor dimensions are incorrect." % checkpoint_index)
					return
			for obstacle_index in range(4):
				var obstacle_body := vr_course.get_node_or_null("VRHologramObstaclePhysics_%02d" % obstacle_index) as StaticBody3D
				var obstacle_collision := obstacle_body.get_node_or_null("CollisionShape3D") as CollisionShape3D if obstacle_body != null else null
				if obstacle_collision == null or not (obstacle_collision.shape is BoxShape3D):
					_fail("VR hologram obstacle %d is missing its named physical BoxShape3D collision body." % obstacle_index)
					return
			operations.set("current_facility_root", vr_facility)
		if not bool(operations.call("start_facility_activity", str(activity_type))):
			_fail("Facility activity could not start: " + str(activity_type))
			return
		var final_activity_result: Dictionary = {}
		var activity_attempt_limit := 21 if str(activity_type) == "bowling" else int(activity_case[1])
		for _step in range(activity_attempt_limit):
			if str(activity_type) == "vr_lab":
				var vr_active_course := (operations.get("current_facility_root") as Node3D).get_node("VRSimulationCourse") as Node3D
				var vr_exit_sensor := vr_active_course.get_node("VRSimulationExitSensor") as Area3D
				if _step == 0:
					var manual_action_result: Dictionary = operations.call("perform_facility_activity", "checkpoint")
					if bool(manual_action_result.get("success", false)) or int(operations.get("active_facility_activity").get("step", -1)) != 0:
						_fail("VR course incorrectly advanced from a button/action without physical gate traversal.")
						return
					vr_exit_sensor.body_entered.emit(player)
					if operations.get("active_facility_activity").is_empty():
						_fail("VR exit platform completed the course while still locked.")
						return
					var out_of_order_sensor := vr_active_course.get_node("VRCheckpointGate_01/VRCheckpointSensor_01") as Area3D
					out_of_order_sensor.body_entered.emit(player)
					if int(operations.get("active_facility_activity").get("step", -1)) != 0:
						_fail("VR course accepted a checkpoint out of sequence.")
						return
				var vr_sensor := vr_active_course.get_node("VRCheckpointGate_%02d/VRCheckpointSensor_%02d" % [_step, _step]) as Area3D
				vr_sensor.body_entered.emit(player)
				var vr_activity_state: Dictionary = operations.get("active_facility_activity")
				if int(vr_activity_state.get("step", -1)) != _step + 1:
					_fail("VR course did not record the physical crossing of gate %d." % (_step + 1))
					return
				if _step < 2:
					if bool(vr_activity_state.get("exit_unlocked", false)) or vr_exit_sensor.monitoring:
						_fail("VR exit platform unlocked before all three energy gates were crossed.")
						return
					final_activity_result = {"success": true, "completed": false, "step": _step + 1}
				else:
					var exit_platform := vr_active_course.get_node("VRSimulationExitPlatform") as MeshInstance3D
					if not bool(vr_activity_state.get("exit_unlocked", false)) or not vr_exit_sensor.monitoring or bool(exit_platform.get_meta("system_vr_exit_locked", true)):
						_fail("VR exit platform did not unlock after the third physical energy gate.")
						return
					if operations.get("active_facility_activity").is_empty():
						_fail("VR course completed at the third gate without reaching the exit platform.")
						return
					vr_exit_sensor.body_entered.emit(player)
					final_activity_result = {"success": true, "completed": operations.get("active_facility_activity").is_empty(), "step": 3}

			elif str(activity_type) in ["bowling", "sports_court", "arcade"]:
				final_activity_result = await operations.call("perform_facility_activity", str(activity_case[0]))
			else:
				final_activity_result = operations.call("perform_facility_activity", str(activity_case[0]))
			if not bool(final_activity_result.get("success", false)):
				_fail("Facility activity action failed: " + str(activity_type) + " / " + str(final_activity_result))
				return
			if str(activity_type) == "cinema":
				cinema_scene_count += 1
				var cinema_title := cinema_facility.get_node_or_null("CinemaProgramTitle") as Label3D
				if cinema_title == null or not cinema_title.text.contains("المشهد %d" % cinema_scene_count):
					_fail("Cinema scene progression did not update the screen for scene %d." % cinema_scene_count)
					return
			if str(activity_type) == "bowling":
				bowling_total_pinfall += int(final_activity_result.get("pins", final_activity_result.get("last_throw", 0)))
			elif str(activity_type) == "sports_court":
				if bool(final_activity_result.get("scored", final_activity_result.get("last_shot_scored", false))):
					basketball_made_count += 1
			elif str(activity_type) == "arcade":
				arcade_last_result = final_activity_result.duplicate(true)
				if bool(final_activity_result.get("hit", final_activity_result.get("last_target_hit", false))):
					arcade_hit_count += 1
			if bool(final_activity_result.get("completed", false)):
				break
		if str(activity_type) == "arcade" and (not final_activity_result.has("last_target_hit") or typeof(final_activity_result.get("last_target_hit")) != TYPE_BOOL or int(final_activity_result.get("last_target_id", -1)) < -1 or int(final_activity_result.get("last_target_id", -1)) > 4):
			_fail("Arcade final attempt did not return a valid physical target-sensor result.")
			return
		if str(activity_type) == "arcade" and (int(final_activity_result.get("hits", -1)) < 1 or int(final_activity_result.get("lives_remaining", -1)) < 0 or int(final_activity_result.get("best_combo", -1)) < 1):
			_fail("Arcade game did not preserve hit count, lives and combo results.")
			return
		if str(activity_type) == "sports_court" and (not final_activity_result.has("last_shot_scored") or typeof(final_activity_result.get("last_shot_scored")) != TYPE_BOOL):
			_fail("Basketball final attempt did not return a physical hoop-sensor result.")
			return
		if str(activity_type) == "sports_court" and (not final_activity_result.has("player_score") or not final_activity_result.has("opponent_score") or not ["win", "draw", "loss"].has(str(final_activity_result.get("match_result", "")))):
			_fail("Basketball 1v1 match did not return both scores and a valid match result.")
			return
		if str(activity_type) == "bowling" and (int(final_activity_result.get("last_throw", -1)) < 0 or int(final_activity_result.get("last_throw", -1)) > 10):
			_fail("Bowling final frame did not report physical pinfall results.")
			return
		if not bool(final_activity_result.get("completed", false)):
			if str(activity_type) == "bowling":
				_fail("Bowling did not complete all ten frames and tenth-frame bonus rolls within 21 throws.")
			else:
				_fail("Facility activity did not complete its required steps: " + str(activity_type))
			return
		if str(activity_type) == "robotics_lab":
			var robotics_root := operations.get("current_facility_root") as Node3D
			var assembly := robotics_root.get_node_or_null("RobotAssemblyDisplay") as Node3D if robotics_root != null else null
			if assembly == null:
				_fail("Robotics assembly display was not generated.")
				return
			await create_timer(1.0).timeout
			for part_index in range(5):
				var part := assembly.get_node_or_null("RobotAssemblyPart_%02d" % part_index) as MeshInstance3D
				if part == null or not part.visible or not bool(part.get_meta("system_robot_assembled", false)):
					_fail("Robotics assembly part %d did not animate into its completed position." % part_index)
					return
				var target_position: Vector3 = part.get_meta("system_robot_target_position", Vector3.ZERO)
				if part.position.distance_to(target_position) > 0.08 or part.scale.distance_to(Vector3.ONE) > 0.08:
					_fail("Robotics assembly part %d did not settle at its target position and scale." % part_index)
					return
			if not bool(assembly.get_meta("system_robot_idle_animation", false)):
				_fail("Completed SYSTEM robot did not start its autonomous idle animation.")
				return
			var left_arm := assembly.get_node_or_null("RobotAssemblyPart_03") as MeshInstance3D
			var right_arm := assembly.get_node_or_null("RobotAssemblyPart_04") as MeshInstance3D
			if left_arm == null or right_arm == null or (left_arm.rotation.length() < 0.01 and right_arm.rotation.length() < 0.01):
				_fail("Completed SYSTEM robot arms are not moving in their idle animation.")
				return
		if not operations.get("facility_activity_stats").has(activity_type):
			_fail("Facility activity result was not recorded: " + str(activity_type))
			return
	if bowling_total_pinfall <= 0:
		_fail("Bowling physics test did not knock down any pins across the ten-frame game.")
		return
	if basketball_made_count <= 0:
		_fail("Basketball physics test did not score a basket in five attempts.")
		return
	if arcade_hit_count <= 0:
		_fail("Arcade physics test did not hit any target during the ten-shot game. Last result: " + str(arcade_last_result))
		return
	print("QA TRACE: activity loops completed; starting pool water regression.")
	var pool_room := operations.call("_ensure_floor_room", "entertainment_tower_baghdad", 18) as Node3D
	var pool_physics_facility := pool_room.get_node_or_null("SpecialFacility_swimming_pool") as Node3D if pool_room != null else null
	var pool_water := pool_physics_facility.get_node_or_null("PoolWaterVolume") as Area3D if pool_physics_facility != null else null
	var mens_pool_suite := pool_physics_facility.get_node_or_null("MensChangingSuite") as Node3D if pool_physics_facility != null else null
	if pool_water == null or mens_pool_suite == null:
		_fail("Swimming pool water volume was not generated.")
		return
	var locker_service := pool_physics_facility.get_node_or_null("MensChangingSuite/PoolLockerServiceInteraction") as Area3D
	var shower_service := pool_physics_facility.get_node_or_null("MensChangingSuite/PoolShowerServiceInteraction") as Area3D
	var lifeguard_service := pool_physics_facility.get_node_or_null("PoolLifeguardStation/PoolLifeguardServiceInteraction") as Area3D
	if locker_service == null or shower_service == null or lifeguard_service == null:
		_fail("Pool changing suites or lifeguard station are missing their interactive service areas.")
		return
	for pool_service in [locker_service, shower_service, lifeguard_service]:
		if not pool_service.is_in_group("system_interactable") or not pool_service.has_meta("system_interaction_prompt") or str(pool_service.get_meta("system_tower_id", "")) != "entertainment_tower_baghdad" or int(pool_service.get_meta("system_tower_floor_number", 0)) != 18:
			_fail("Pool service interaction is missing its prompt or tower/floor routing metadata: " + str(pool_service.name))
			return
	operations.set("current_tower_id", "entertainment_tower_baghdad")
	operations.set("active_floor_root", pool_room)
	pool_room.set_meta("system_tower_id", "entertainment_tower_baghdad")
	pool_room.set_meta("system_tower_floor_number", 18)
	operations.call("open_pool_service", locker_service)
	operations.call("_use_pool_service", "locker")
	var assigned_pool_locker_id := str(player.get_meta("system_pool_locker_id", ""))
	var assigned_pool_locker := mens_pool_suite.get_node_or_null(assigned_pool_locker_id) as MeshInstance3D
	if not bool(player.get_meta("system_pool_locker_reserved", false)) or str(player.get_meta("system_pool_locker_tower", "")) != "entertainment_tower_baghdad" or assigned_pool_locker == null or not bool(assigned_pool_locker.get_meta("system_pool_locker_occupied", false)) or int(assigned_pool_locker.get_meta("system_pool_locker_owner", -1)) != player.get_instance_id():
		_fail("Pool locker service did not allocate and mark a real locker for the player in the correct tower.")
		return
	operations.call("_use_pool_service", "locker")
	if str(player.get_meta("system_pool_locker_id", "")) != assigned_pool_locker_id:
		_fail("Repeated pool locker requests allocated a second locker instead of retaining the player's existing reservation.")
		return
	operations.call("open_pool_service", shower_service)
	operations.call("_use_pool_service", "shower")
	if not bool(player.get_meta("system_pool_showered", false)):
		_fail("Pool shower service did not record the player's hygiene preparation.")
		return
	operations.call("open_pool_service", lifeguard_service)
	operations.call("_use_pool_service", "lifeguard")
	if not bool(player.get_meta("system_pool_assistance_requested", false)):
		_fail("Lifeguard service did not record the player's assistance request.")
		return
	pool_water.body_entered.emit(player)
	if not bool(player.get_meta("system_swimming", false)):
		_fail("Entering the pool volume did not enable the player's swimming state.")
		return
	player.set_meta("system_hospital_treatment", false)
	main.set("jump_requested", true)
	main.call("_physics_process", 0.016)
	if float(player.get_meta("system_swim_last_stroke_force", 0.0)) < 2.4:
		_fail("Swimming stroke input did not register its upward swim impulse.")
		return
	pool_water.body_exited.emit(player)
	if bool(player.get_meta("system_swimming", false)):
		_fail("Leaving the pool volume did not restore normal movement state.")
		return
	var completed_activity_stats: Dictionary = operations.get("facility_activity_stats").duplicate(true)
	operations.call("_save_facility_activity_stats")
	operations.set("facility_activity_stats", {})
	operations.call("_load_facility_activity_stats")
	if operations.get("facility_activity_stats") != completed_activity_stats:
		_fail("Facility activity statistics did not survive a save/load cycle.")
		return
	operations.set("facility_activity_stats", activity_stats_snapshot)
	operations.set("credits", activity_credits_snapshot)
	operations.call("_save_facility_activity_stats")
	operations.call("_save_wallet")
	if not operations.has_method("open_facility_service"):
		_fail("Facility interaction service entry point is missing.")
		return
	if int(operations.call("_get_floor_duty_staff_index", "shopping_tower_baghdad", 29)) != 4 or int(operations.call("_get_floor_duty_staff_index", "shopping_tower_baghdad", 27)) != 6 or int(operations.call("_get_floor_duty_staff_index", "technology_tower_baghdad", 20)) != 4:
		_fail("Baghdad floor-to-staff duty assignments are incorrect.")
		return
	print("QA TRACE: pool movement and save/load regressions completed; starting staff elevator trip.")
	operations.set("current_tower_id", "shopping_tower_baghdad")
	print("QA TRACE: invoking floor 29 staff elevator trip.")
	operations.call("_travel_to_floor", "shopping_tower_baghdad", 29)
	if bool(player.get_meta("system_pool_locker_reserved", false)) or assigned_pool_locker.has_meta("system_pool_locker_occupied") or assigned_pool_locker.has_meta("system_pool_locker_owner"):
		_fail("Leaving the pool facility did not release the player's locker for the next guest.")
		return
	print("QA TRACE: floor 29 elevator trip requested.")
	var shopping_staff_ids: Array = operations.get("staff_by_tower").get("shopping_tower_baghdad", [])
	if shopping_staff_ids.size() <= 4:
		_fail("Shopping Tower restaurant chef staff record is missing.")
		return
	var shopping_tower_node := tower_manager.get_node("ShoppingTower") as Node3D
	var restaurant_chef := shopping_tower_node.find_child("TowerStaff_" + str(shopping_staff_ids[4]), true, false) as Node3D
	var staff_elevator_car := operations.get("active_elevator_car") as Node3D
	if restaurant_chef == null or staff_elevator_car == null or restaurant_chef.get_parent() != staff_elevator_car or not bool(restaurant_chef.get_meta("system_staff_in_elevator", false)):
		_fail("The assigned Shopping Tower restaurant chef did not board the physical tower elevator.")
		return
	var customer_elevator_passengers := 0
	for elevator_child in staff_elevator_car.get_children():
		if str(elevator_child.name).begins_with("TowerCustomer_") and bool(elevator_child.get_meta("system_customer_in_elevator", false)) and int(elevator_child.get_meta("system_customer_elevator_target_floor", 0)) == 29:
			customer_elevator_passengers += 1
	if customer_elevator_passengers != 2:
		_fail("Two persistent Shopping Tower customers did not physically board the elevator with the player.")
		return
	print("QA TRACE: two customer NPCs boarded the physical elevator; waiting for floor 29 arrival.")
	await create_timer(3.8).timeout
	print("QA TRACE: floor 29 elevator wait completed.")
	var arrived_customer_passengers := 0
	for floor_child in restaurant_room.get_children():
		if str(floor_child.name).begins_with("TowerCustomer_") and not bool(floor_child.get_meta("system_customer_in_elevator", false)) and int(floor_child.get_meta("system_customer_current_floor", 0)) == 29:
			arrived_customer_passengers += 1
	if arrived_customer_passengers != 2:
		_fail("The two customer NPCs did not disembark onto restaurant floor 29 after the elevator ride.")
		return
	var seated_restaurant_customers := 0
	for floor_child in restaurant_room.get_children():
		if not str(floor_child.name).begins_with("TowerCustomer_"):
			continue
		var table_name := str(floor_child.get_meta("system_restaurant_table_node", ""))
		var seat_name := str(floor_child.get_meta("system_restaurant_seat_node", ""))
		var table_root := restaurant_room.get_node_or_null(table_name) as Node3D
		var seat_marker := table_root.get_node_or_null(seat_name) as Node3D if table_root != null else null
		var customer_id := str(floor_child.get_meta("system_tower_customer_id", floor_child.name))
		if seat_marker != null and str(seat_marker.get_meta("system_restaurant_seat_occupant", "")) == customer_id and table_root.get_meta("system_restaurant_occupants", []).has(customer_id):
			seated_restaurant_customers += 1
	var visible_queue_positions := 0
	for queue_index in range(8):
		if restaurant_room.get_node_or_null("RestaurantQueuePosition_%02d" % queue_index) != null:
			visible_queue_positions += 1
	if seated_restaurant_customers != 2 or visible_queue_positions != 8:
		_fail("Restaurant visitors were not assigned to real owned seats or the eight visible waiting positions were not generated.")
		return
	print("QA TRACE: two restaurant customers occupy individually owned seats; eight visible queue positions are available.")
	var waiter_staff_id := str(shopping_staff_ids[5]) if shopping_staff_ids.size() > 5 else ""
	var restaurant_waiter := shopping_tower_node.find_child("TowerStaff_" + waiter_staff_id, true, false) as Node3D if not waiter_staff_id.is_empty() else null
	if restaurant_waiter == null:
		_fail("The assigned restaurant waiter could not be found before player ordering.")
		return
	for _staff_wait_attempt in range(100):
		if restaurant_chef.get_parent() == restaurant_room and restaurant_waiter.get_parent() == restaurant_room:
			break
		await create_timer(0.1).timeout
	if restaurant_chef.get_parent() != restaurant_room or restaurant_waiter.get_parent() != restaurant_room:
		_fail("Restaurant service staff did not disembark onto floor 29: chef=%s waiter=%s." % [str(restaurant_chef.get_parent().name if restaurant_chef.get_parent() != null else "none"), str(restaurant_waiter.get_parent().name if restaurant_waiter.get_parent() != null else "none")])
		return
	if str(restaurant_waiter.get_meta("system_tower_staff_role", "")) != "restaurant_waiter":
		_fail("The floor-29 support employee is not assigned the restaurant waiter role.")
		return
	print("QA TRACE: restaurant chef and waiter reached floor 29; player order service can begin.")
	var player_test_table: Node3D
	for table_index in range(4):
		var candidate_table := restaurant_room.get_node_or_null("RestaurantTable_%02d" % table_index) as Node3D
		if candidate_table == null:
			continue
		for seat_index in range(4):
			var candidate_seat := candidate_table.get_node_or_null("RestaurantSeat_%02d" % seat_index) as Node3D
			if candidate_seat != null and str(candidate_seat.get_meta("system_restaurant_seat_occupant", "")).is_empty():
				player_test_table = candidate_table
				break
		if player_test_table != null:
			break
	if player_test_table == null:
		_fail("No free physical restaurant seat remained for the player seating regression.")
		return
	operations.call("_seat_player_at_restaurant", player_test_table)
	await create_timer(0.8).timeout
	var player_seat_name := str(player.get_meta("system_restaurant_seat_node", ""))
	var player_seat_marker := player_test_table.get_node_or_null(player_seat_name) as Node3D
	var player_seating_ok: bool = bool(player.get_meta("system_restaurant_seated", false)) and str(player.get_meta("system_restaurant_seated_table_id", "")) == str(player_test_table.get_meta("system_restaurant_table_id", "")) and player_seat_marker != null and str(player_seat_marker.get_meta("system_restaurant_seat_occupant", "")) == "PLAYER" and player_test_table.get_meta("system_restaurant_occupants", []).has("PLAYER")
	if not player_seating_ok:
		_fail("The player did not physically reserve and reach an individually owned restaurant seat.")
		return
	var player_position_before_seated_input: Vector3 = player.global_position
	main.set("mobile_direction", Vector2(1.0, 0.0))
	main.call("_physics_process", 0.016)
	main.set("mobile_direction", Vector2.ZERO)
	if not player.global_position.is_equal_approx(player_position_before_seated_input):
		_fail("The player movement controller did not lock movement while seated at the restaurant table.")
		return
	var player_cycle_table_id := str(player_test_table.get_meta("system_restaurant_table_id", ""))
	var player_cycle_credits_snapshot := int(operations.get("credits"))
	var player_cycle_orders_snapshot: Dictionary = operations.get("restaurant_orders").duplicate(true)
	var player_cycle_history_snapshot: Array = operations.get("restaurant_order_history").duplicate(true)
	var player_cycle_drafts_snapshot: Dictionary = operations.get("restaurant_draft_items").duplicate(true)
	var progression_manager := main.get("player_progression") as Node
	if health_manager == null or progression_manager == null:
		_fail("Restaurant meal effects could not access the canonical player health/progression systems.")
		return
	var health_before_test := float(health_manager.get("current_health"))
	var wounded_before_meal := bool(health_manager.get("is_wounded"))
	var total_xp_before_meal := int(progression_manager.get("total_xp"))
	var xp_in_level_before_meal := int(progression_manager.get("xp_in_level"))
	var level_before_meal := int(progression_manager.get("current_level"))
	var attribute_points_before_meal := int(progression_manager.get("available_attribute_points"))
	health_manager.set("current_health", minf(75.0, health_before_test))
	health_manager.call("_sync_player_state")
	var health_before_meal := float(health_manager.get("current_health"))
	operations.set("credits", maxi(player_cycle_credits_snapshot, 200))
	operations.set("current_restaurant_table_node", player_test_table)
	operations.set("current_restaurant_table_id", player_cycle_table_id)
	operations.set("restaurant_draft_items", {player_cycle_table_id: [
		{"item_id": "restaurant_kebab", "name": "كباب عراقي", "price": 68},
		{"item_id": "restaurant_fresh_juice", "name": "عصير طازج", "price": 22}
	]})
	operations.call("_place_restaurant_order", player_cycle_table_id)
	var player_order: Dictionary = operations.get("restaurant_orders").get(player_cycle_table_id, {})
	if str(player_order.get("status", "")) != "awaiting_waiter" or int(player_order.get("total", 0)) != 90:
		_fail("A seated player could not send and pay for a restaurant order into the waiter queue.")
		return
	var observed_player_service_states := {"awaiting_waiter": true}
	for _attempt in range(600):
		operations.call("_process_restaurant_staff_service")
		player_order = operations.get("restaurant_orders").get(player_cycle_table_id, {})
		var observed_state := str(player_order.get("status", ""))
		if not observed_state.is_empty():
			observed_player_service_states[observed_state] = true
		if observed_state == "served":
			break
		await create_timer(0.05).timeout
	var required_player_service_states := ["taking_order", "placed", "preparing", "ready", "delivering", "served"]
	for required_state in required_player_service_states:
		if not observed_player_service_states.has(required_state):
			_fail("The player's restaurant order did not pass through the real waiter/kitchen/chef/waiter stage: " + required_state)
			return
	if player_test_table.get_node_or_null("ServedMealPresentation/MealPlate") == null or player_test_table.get_node_or_null("ServedMealPresentation/PreparedMeal") == null:
		_fail("The waiter did not deliver the prepared meal and render it on the player's occupied table.")
		return
	if not bool(operations.call("_consume_restaurant_meal", player_cycle_table_id)):
		_fail("The player could not consume the delivered restaurant meal.")
		return
	player_order = operations.get("restaurant_orders").get(player_cycle_table_id, {})
	var first_meal_health := float(health_manager.get("current_health"))
	var first_meal_xp := int(progression_manager.get("total_xp"))
	var consumed_presentation := player_test_table.get_node_or_null("ServedMealPresentation") as Node3D
	var consumed_label := consumed_presentation.get_node_or_null("MealReadyLabel") as Label3D if consumed_presentation != null else null
	if not bool(player_order.get("meal_consumed", false)) or first_meal_health <= health_before_meal or first_meal_xp != total_xp_before_meal + 10 or bool(health_manager.get("is_wounded")) != wounded_before_meal:
		_fail("Eating the delivered meal did not restore bounded health, preserve wound state and award the expected one-time XP.")
		return
	if consumed_presentation == null or consumed_presentation.get_node_or_null("MealPlate") == null or consumed_presentation.get_node_or_null("PreparedMeal") != null or consumed_label == null or consumed_label.text != "تم تناول الوجبة":
		_fail("The served food remained visible after consumption instead of leaving an empty plate.")
		return
	if bool(operations.call("_consume_restaurant_meal", player_cycle_table_id)) or float(health_manager.get("current_health")) != first_meal_health or int(progression_manager.get("total_xp")) != first_meal_xp:
		_fail("The restaurant meal reward could be claimed more than once.")
		return
	operations.call("_advance_restaurant_order", player_cycle_table_id, "completed")
	if operations.get("restaurant_orders").has(player_cycle_table_id) or player.has_meta("system_restaurant_seated_table_id") or player_test_table.get_meta("system_restaurant_occupants", []).has("PLAYER") or str(player_seat_marker.get_meta("system_restaurant_seat_occupant", "")) == "PLAYER":
		_fail("Completing an eaten meal did not archive the order and release the player's physical seat.")
		return
	var player_cycle_history: Array = operations.get("restaurant_order_history")
	if player_cycle_history.is_empty() or str(player_cycle_history[-1].get("status", "")) != "completed" or not bool(player_cycle_history[-1].get("meal_consumed", false)):
		_fail("The completed restaurant meal receipt did not preserve its consumption/reward record.")
		return
	operations.set("restaurant_orders", player_cycle_orders_snapshot)
	operations.set("restaurant_order_history", player_cycle_history_snapshot)
	operations.set("restaurant_draft_items", player_cycle_drafts_snapshot)
	operations.set("credits", player_cycle_credits_snapshot)
	operations.call("_save_restaurant_orders")
	operations.call("_save_wallet")
	health_manager.set("current_health", health_before_test)
	health_manager.set("is_wounded", wounded_before_meal)
	health_manager.call("_sync_player_state")
	health_manager.emit_signal("health_changed", health_before_test, 100.0)
	progression_manager.set("total_xp", total_xp_before_meal)
	progression_manager.set("xp_in_level", xp_in_level_before_meal)
	progression_manager.set("current_level", level_before_meal)
	progression_manager.set("available_attribute_points", attribute_points_before_meal)
	progression_manager.call("save_progress")
	progression_manager.call("_emit_progress")
	print("QA TRACE: player sits, movement locks, waiter accepts order, chef prepares it, waiter delivers it, meal restores health and grants XP exactly once, and checkout releases the seat.")
	var npc_restaurant_order_id := ""
	for floor_child in restaurant_room.get_children():
		if not str(floor_child.name).begins_with("TowerCustomer_"):
			continue
		var npc_table_name := str(floor_child.get_meta("system_restaurant_table_node", ""))
		var npc_table_root := restaurant_room.get_node_or_null(npc_table_name) as Node3D
		if npc_table_root == null:
			continue
		var candidate_order_id := str(npc_table_root.get_meta("system_restaurant_table_id", "")) + "_npc"
		var candidate_order: Dictionary = operations.get("restaurant_orders").get(candidate_order_id, {})
		var npc_customer_id := str(floor_child.get_meta("system_tower_customer_id", floor_child.name))
		if bool(candidate_order.get("npc_order", false)) and candidate_order.get("customer_ids", []).has(npc_customer_id):
			npc_restaurant_order_id = candidate_order_id
			break
	if npc_restaurant_order_id.is_empty():
		_fail("Seated customer NPCs did not generate an independent restaurant order for the waiter.")
		return
	var npc_restaurant_order: Dictionary = operations.get("restaurant_orders").get(npc_restaurant_order_id, {})
	if str(npc_restaurant_order.get("status", "")) not in ["awaiting_waiter", "taking_order", "placed", "preparing", "ready", "delivering", "served"] or npc_restaurant_order.get("items", []).size() < 1:
		_fail("An autonomous NPC restaurant order was not created in the waiter queue.")
		return
	if restaurant_waiter == null or restaurant_waiter.get_parent() != restaurant_room:
		_fail("The assigned restaurant waiter did not reach the dining floor.")
		return
	print("QA TRACE: autonomous NPC dining order created; waiting for waiter to take the order.")
	for _attempt in range(80):
		npc_restaurant_order = operations.get("restaurant_orders").get(npc_restaurant_order_id, {})
		if str(npc_restaurant_order.get("status", "")) != "awaiting_waiter":
			break
		await create_timer(0.25).timeout
	if str(npc_restaurant_order.get("status", "")) == "awaiting_waiter":
		_fail("The waiter did not physically visit the NPC table and accept its order.")
		return
	print("QA TRACE: waiter accepted the NPC order; waiting for kitchen preparation.")
	for _attempt in range(80):
		npc_restaurant_order = operations.get("restaurant_orders").get(npc_restaurant_order_id, {})
		if str(npc_restaurant_order.get("status", "")) == "ready":
			break
		await create_timer(0.25).timeout
	if str(npc_restaurant_order.get("status", "")) != "ready":
		_fail("The restaurant chef did not prepare the autonomous NPC order.")
		return
	print("QA TRACE: chef prepared the NPC order; waiting for waiter delivery.")
	for _attempt in range(80):
		npc_restaurant_order = operations.get("restaurant_orders").get(npc_restaurant_order_id, {})
		if str(npc_restaurant_order.get("status", "")) == "served":
			break
		await create_timer(0.25).timeout
	if str(npc_restaurant_order.get("status", "")) != "served":
		_fail("The waiter did not deliver the prepared NPC meal to the occupied table.")
		return
	print("QA TRACE: autonomous NPC order completed waiter acceptance, chef preparation and waiter delivery.")
	var chef_workstation := restaurant_room.get_node_or_null("StaffWorkstation_restaurant_chef") as Node3D
	if restaurant_chef.get_parent() != restaurant_room or chef_workstation == null or not bool(restaurant_chef.get_meta("system_staff_workstation_active", false)):
		_fail("The restaurant chef did not travel to floor 29 and reach the active workstation.")
		return
	var restaurant_emergency_sensor := restaurant_room.get_node("EmergencyExitSensor") as Area3D
	print("QA TRACE: triggering restaurant emergency evacuation.")
	restaurant_emergency_sensor.body_entered.emit(player)
	await create_timer(3.1).timeout
	print("QA TRACE: evacuation wait completed.")
	if operations.get("active_floor_root") != null or bool(player.get_meta("system_tower_elevator_active", false)):
		_fail("Physically entering the tower emergency exit did not complete the evacuation return to the public lobby.")
		return
	if restaurant_chef.get_parent() != shopping_customer_lobby or restaurant_chef.has_meta("system_staff_duty_floor") or not bool(restaurant_chef.get_meta("system_staff_navigation_enabled", false)) or restaurant_chef.get_meta("system_staff_patrol_waypoints", []).size() < 4:
		_fail("The restaurant chef did not ride the elevator back to the lobby and resume the persistent lobby patrol.")
		return
	var customers_after_evacuation := 0
	for lobby_child in shopping_customer_lobby.get_children():
		if str(lobby_child.name).begins_with("TowerCustomer_"):
			customers_after_evacuation += 1
	if customers_after_evacuation != 4:
		_fail("Shopping Tower customer visitors did not return to the public lobby after emergency evacuation; found %d." % customers_after_evacuation)
		return
	for lobby_child in shopping_customer_lobby.get_children():
		if str(lobby_child.name).begins_with("TowerCustomer_") and (lobby_child.has_meta("system_restaurant_table_node") or lobby_child.has_meta("system_restaurant_seat_node") or lobby_child.has_meta("system_restaurant_queue_marker")):
			_fail("A customer retained a restaurant seat or queue reservation after evacuation.")
			return
	print("QA TRACE: restaurant seating reservations released on evacuation; customer return passed; starting pool supervisor duty trip.")
	operations.set("current_tower_id", "entertainment_tower_baghdad")
	operations.call("_travel_to_floor", "entertainment_tower_baghdad", 18)
	var entertainment_staff_ids: Array = operations.get("staff_by_tower").get("entertainment_tower_baghdad", [])
	if entertainment_staff_ids.size() <= 3:
		_fail("Entertainment Tower pool supervisor staff record is missing.")
		return
	var entertainment_tower_node := tower_manager.get_node("EntertainmentTower") as Node3D
	var pool_supervisor := entertainment_tower_node.find_child("TowerStaff_" + str(entertainment_staff_ids[3]), true, false) as Node3D
	var pool_staff_car := operations.get("active_elevator_car") as Node3D
	if pool_supervisor == null or pool_staff_car == null or pool_supervisor.get_parent() != pool_staff_car or not bool(pool_supervisor.get_meta("system_staff_in_elevator", false)):
		_fail("The assigned pool supervisor did not board the physical elevator to the swimming pool floor.")
		return
	await create_timer(3.8).timeout
	var pool_staff_room := operations.get("active_floor_root") as Node3D
	var pool_supervisor_station := pool_staff_room.get_node_or_null("StaffWorkstation_pool_supervisor") as Node3D if pool_staff_room != null else null
	var pool_staff_service := pool_staff_room.get_node_or_null("StaffServicePoint_pool_supervisor") as Node3D if pool_staff_room != null else null
	var pool_facility_station := pool_staff_room.get_node_or_null("SpecialFacility_swimming_pool/PoolLifeguardStation") as Node3D if pool_staff_room != null else null
	var rescue_kit := pool_supervisor_station.get_node_or_null("PoolRescueFirstAidKit") as MeshInstance3D if pool_supervisor_station != null else null
	var rescue_tube := pool_supervisor_station.get_node_or_null("PoolRescueTubeRack") as MeshInstance3D if pool_supervisor_station != null else null
	var rescue_sign := pool_supervisor_station.get_node_or_null("PoolSafetyEquipmentSign") as Label3D if pool_supervisor_station != null else null
	if pool_supervisor.get_parent() != pool_staff_room or pool_supervisor_station == null or pool_staff_service == null or pool_facility_station == null or rescue_kit == null or rescue_tube == null or rescue_sign == null or not bool(pool_supervisor.get_meta("system_staff_workstation_active", false)):
		_fail("The pool supervisor did not reach an active lifeguard workstation beside the pool safety station.")
		return
	var expected_pool_duty_position := Vector3(3.2, 0.0, -17.0)
	var actual_pool_duty_position: Vector3 = pool_supervisor.get_meta("system_staff_workstation_position", Vector3.ZERO)
	if not actual_pool_duty_position.is_equal_approx(expected_pool_duty_position):
		_fail("The pool supervisor workstation is not positioned beside the lifeguard station.")
		return
	operations.call("_use_pool_service", "lifeguard")
	var rescue_tween: Variant = pool_supervisor.get_meta("system_staff_patrol_tween", null)
	if not bool(pool_supervisor.get_meta("system_staff_assistance_requested", false)) or not (rescue_tween is Tween) or not (rescue_tween as Tween).is_running():
		_fail("The pool supervisor did not respond to a lifeguard assistance request.")
		return
	await create_timer(1.25).timeout
	if not bool(pool_supervisor.get_meta("system_staff_assistance_arrived", false)):
		_fail("The pool supervisor did not physically reach the player after accepting the assistance request.")
		return
	operations.call("_return_floor_duty_staff_to_lobbies")
	if pool_supervisor.get_parent() != entertainment_tower_node.get_node("PublicLobby_Blockout") or pool_supervisor.has_meta("system_staff_duty_floor") or pool_supervisor.has_meta("system_staff_assistance_requested") or pool_supervisor.has_meta("system_staff_assistance_arrived") or not bool(pool_supervisor.get_meta("system_staff_navigation_enabled", false)):
		_fail("The pool supervisor did not return to the public lobby and resume the lobby patrol after duty.")
		return
	print("QA TRACE: pool supervisor duty, lifeguard workstation and lobby return passed.")
	print("QA TRACE: final staff/customer assertions passed.")
	print("Baghdad tower operations validation passed: five connected Baghdad towers, independent Power Tower, NPC commerce, hotel workflows, eleven playable leisure/technology activity loops, equipment, Nen progression and the 200th-floor sovereign boss arena.")
	# This is a short-lived headless validation process; avoid forcing dummy-renderer teardown of placeholder meshes.
	quit(0)

func _fail(message: String) -> void:
	push_error("Baghdad tower operations validation failed: " + message)
	quit(1)
