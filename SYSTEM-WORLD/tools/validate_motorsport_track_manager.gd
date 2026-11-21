extends SceneTree

const TRACK_SCRIPT = preload("res://scripts/system_motorsport_track_manager.gd")
const RACE_SCRIPT = preload("res://scripts/system_motorsport_manager.gd")

class MockVehicleRuntime extends Node:
	var active_vehicle: Node3D
	var is_driving := true

class MockAIController extends Node:
	var opponent_id := ""
	var opponent_name := ""
	var vehicle: Node
	var completed_laps := 0
	var total_laps := 3
	var target_checkpoint := 1
	var waypoints: Array[Vector3] = [Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]
	var elapsed_seconds := 0.0
	var active := true

func _initialize() -> void:
	var runtime := MockVehicleRuntime.new()
	root.add_child(runtime)
	var test_vehicle := RigidBody3D.new()
	test_vehicle.linear_velocity = Vector3(20.0, 0.0, 0.0)
	root.add_child(test_vehicle)
	runtime.active_vehicle = test_vehicle
	var race_manager: SystemMotorsportManager = RACE_SCRIPT.new() as SystemMotorsportManager
	root.add_child(race_manager)
	race_manager.active_race = {"event_id": "pit_speed_validation"}
	var manager: SystemMotorsportTrackManager = TRACK_SCRIPT.new() as SystemMotorsportTrackManager
	manager.setup(null, runtime, race_manager)
	root.add_child(manager)
	# The track is constructed from _ready(); wait for the manager to enter the tree.
	await process_frame
	var track_root: Node3D = manager.track_root
	if not is_instance_valid(track_root):
		_fail("Baghdad motorsport track root was not built.")
		return

	for required_node in [
		"PaddockGround", "PitServiceApron", "PitLane", "PitLaneContextArea",
		"PitLaneEntryGateArea", "PitLaneExitGateArea", "RaceControlTower",
		"RaceControlInteraction", "MarshalPost_00", "MarshalPost_01",
		"MarshalPost_02", "MarshalPost_03", "Grandstand_South_00",
		"Grandstand_End_west_00", "Grandstand_End_east_00"
	]:
		if track_root.get_node_or_null(required_node) == null:
			_fail("Missing physical motorsport facility: " + required_node)
			return

	if manager.pit_garage_nodes.size() != 8 or manager.marshal_post_nodes.size() != 4:
		_fail("Pit garage or marshal post count is incorrect.")
		return
	var garage: Node3D = track_root.get_node_or_null("PitGarageBay_00")
	if garage == null or not _has_collision(garage.get_node_or_null("GarageFloor")):
		_fail("First pit garage does not have a collision-backed floor.")
		return
	var garage_interaction_node: Node = garage.get_node_or_null("GarageEntranceInteraction")
	if garage_interaction_node == null:
		_fail("Pit garage walk-in interaction is missing.")
		return
	var garage_interaction: Area3D = garage_interaction_node as Area3D
	if str(garage_interaction.get_meta("system_location_id", "")) != "baghdad_motorsport_pit_garage_00":
		_fail("Pit garage stable location ID is incorrect.")
		return
	if not _has_collision(track_root.get_node_or_null("RaceControlTower/RaceControlFloor")):
		_fail("Race control tower floor collision is missing.")
		return
	if not _has_collision(track_root.get_node_or_null("Grandstand_South_00")):
		_fail("South grandstand collision is missing.")
		return

	var entry: Area3D = track_root.get_node("PitLaneEntryGateArea") as Area3D
	var exit_gate: Area3D = track_root.get_node("PitLaneExitGateArea") as Area3D
	if str(entry.get_meta("system_location_id", "")) != "baghdad_motorsport_pit_entry":
		_fail("Pit lane entry gate does not expose a stable location ID.")
		return
	if str(exit_gate.get_meta("system_location_id", "")) != "baghdad_motorsport_pit_exit":
		_fail("Pit lane exit gate does not expose a stable location ID.")
		return
	if not manager.pit_lane_context_area.body_entered.is_connected(Callable(manager, "_on_pit_lane_context_body_entered")):
		_fail("Pit lane vehicle context does not listen for vehicle entry.")
		return
	if not entry.body_entered.is_connected(Callable(manager, "_on_pit_lane_entry_body_entered")):
		_fail("Pit lane entry gate is not connected to its vehicle trigger.")
		return

	manager.active_vehicle_in_pit_lane = true
	manager._physics_process(0.016)
	if absf(race_manager.race_time_penalty - 5.0) > 0.01 or not manager.pit_lane_speed_violation_applied:
		_fail("Pit lane speeding above 60 km/h did not apply the five-second penalty.")
		return
	manager._physics_process(0.016)
	if absf(race_manager.race_time_penalty - 5.0) > 0.01:
		_fail("The same pit lane speeding incident was penalized more than once.")
		return
	manager.active_vehicle_in_pit_lane = false
	manager._on_pit_lane_context_body_exited(test_vehicle)

	# Leaving the vehicle during the countdown must cancel immediately.
	race_manager.cancel_race()
	race_manager.active_race = {"event_id": "leave_vehicle_during_countdown"}
	race_manager.race_countdown_remaining = 2.0
	race_manager.race_is_running = false
	runtime.is_driving = false
	manager._on_player_driving_changed(false, "sport_coupe")
	if race_manager.is_race_active():
		_fail("Leaving the vehicle during the countdown did not cancel the race.")
		return

	# Moving the staged vehicle away from the grid during the countdown must cancel.
	runtime.is_driving = true
	race_manager.active_race = {"event_id": "leave_grid_during_countdown"}
	race_manager.race_countdown_remaining = 2.0
	race_manager.race_is_running = false
	test_vehicle.global_position = manager.get_start_grid_position() + Vector3(30.0, 0.0, 0.0)
	manager._process(0.016)
	if race_manager.is_race_active():
		_fail("Moving away from the start grid during the countdown did not cancel the race.")
		return

	# Remaining in the vehicle and on the grid must preserve the active countdown.
	test_vehicle.global_position = manager.get_start_grid_position()
	race_manager.active_race = {"event_id": "valid_grid_countdown"}
	race_manager.race_countdown_remaining = 2.0
	race_manager.race_is_running = false
	manager._process(0.016)
	if not race_manager.is_race_active():
		_fail("A valid staged vehicle was incorrectly removed from the countdown.")
		return
	race_manager.cancel_race()

	manager.ai_race_event_id = "city_sprint"
	var ai_finished := MockAIController.new()
	ai_finished.opponent_id = "ai_finished"
	ai_finished.opponent_name = "SYSTEM Racer Finished"
	ai_finished.active = false
	ai_finished.completed_laps = 3
	ai_finished.elapsed_seconds = 115.0
	root.add_child(ai_finished)
	var ai_second := MockAIController.new()
	ai_second.opponent_id = "ai_second"
	ai_second.opponent_name = "SYSTEM Racer Two"
	ai_second.completed_laps = 2
	ai_second.target_checkpoint = 0
	ai_second.elapsed_seconds = 80.0
	root.add_child(ai_second)
	var ai_same_lap_advanced := MockAIController.new()
	ai_same_lap_advanced.opponent_id = "ai_same_lap_advanced"
	ai_same_lap_advanced.opponent_name = "SYSTEM Racer Advanced"
	ai_same_lap_advanced.completed_laps = 1
	ai_same_lap_advanced.target_checkpoint = 0
	ai_same_lap_advanced.elapsed_seconds = 90.0
	root.add_child(ai_same_lap_advanced)
	var ai_same_lap_middle := MockAIController.new()
	ai_same_lap_middle.opponent_id = "ai_same_lap_middle"
	ai_same_lap_middle.opponent_name = "SYSTEM Racer Middle"
	ai_same_lap_middle.completed_laps = 1
	ai_same_lap_middle.target_checkpoint = 2
	ai_same_lap_middle.elapsed_seconds = 30.0
	root.add_child(ai_same_lap_middle)
	var ai_third := MockAIController.new()
	ai_third.opponent_id = "ai_third"
	ai_third.opponent_name = "SYSTEM Racer Three"
	ai_third.completed_laps = 1
	ai_third.target_checkpoint = 1
	ai_third.elapsed_seconds = 60.0
	root.add_child(ai_third)
	manager.ai_controller_nodes = [ai_third, ai_same_lap_middle, ai_finished, ai_second, ai_same_lap_advanced]
	var ai_standings: Array[Dictionary] = manager.get_ai_race_status()
	if manager.get_ai_race_event_id() != "city_sprint" or ai_standings.size() != 5:
		_fail("The last AI race event or opponent standings were not exposed.")
		return
	var expected_ai_order := ["ai_finished", "ai_second", "ai_same_lap_advanced", "ai_same_lap_middle", "ai_third"]
	for index in range(expected_ai_order.size()):
		if str(ai_standings[index].get("opponent_id", "")) != expected_ai_order[index]:
			_fail("AI standings did not prioritize laps and ordered checkpoint progress.")
			return

	var info: Dictionary = manager.get_track_info()
	if int(info.get("pit_garage_count", 0)) != 8 or int(info.get("marshal_post_count", 0)) != 4:
		_fail("Track info does not report the physical garage and marshal facilities.")
		return
	if float(info.get("pit_lane_speed_limit_kph", 0.0)) != 60.0 or bool(info.get("race_ready", true)):
		_fail("Pit lane limit or conservative race-ready state is incorrect.")
		return
	manager.free()
	ai_finished.free()
	ai_second.free()
	ai_same_lap_advanced.free()
	ai_same_lap_middle.free()
	ai_third.free()
	race_manager.free()
	test_vehicle.free()
	runtime.free()
	print("Baghdad motorsport track validation passed: 8 walk-in pit garages, pit lane entry/exit and context areas, race control tower, four marshal posts, collision-backed spectator stands and 60 km/h pit speed enforcement.")
	quit(0)


func _has_collision(node: Node) -> bool:
	if node == null:
		return false
	for body in node.find_children("*", "StaticBody3D", true, false):
		for child in body.get_children():
			if child is CollisionShape3D and child.shape != null and not child.disabled:
				return true
	return false


func _fail(message: String) -> void:
	push_error("Baghdad motorsport track validation failed: " + message)
	quit(1)
