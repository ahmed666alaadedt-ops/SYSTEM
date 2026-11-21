extends SceneTree

const TRACK_SCRIPT = preload("res://scripts/system_motorsport_track_manager.gd")

func _initialize() -> void:
	var manager: SystemMotorsportTrackManager = TRACK_SCRIPT.new() as SystemMotorsportTrackManager
	manager.setup(null, null, null)
	root.add_child(manager)
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

	var info: Dictionary = manager.get_track_info()
	if int(info.get("pit_garage_count", 0)) != 8 or int(info.get("marshal_post_count", 0)) != 4:
		_fail("Track info does not report the physical garage and marshal facilities.")
		return
	if float(info.get("pit_lane_speed_limit_kph", 0.0)) != 60.0 or bool(info.get("race_ready", true)):
		_fail("Pit lane limit or conservative race-ready state is incorrect.")
		return
	manager.free()
	print("Baghdad motorsport track validation passed: 8 walk-in pit garages, pit lane entry/exit and context areas, race control tower, four marshal posts and collision-backed spectator stands.")
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
