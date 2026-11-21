extends Node3D
class_name SystemMotorsportTrackManager

## First-pass physical motorsport venue blockout.
## The track-zone Area3D enables race-only vehicle access while the player is inside.
## AI grid and race HUD prototypes are active; final road navigation and polished production assets remain future work.

signal track_zone_entered(track_id: String)
signal track_zone_exited(track_id: String)
signal pit_lane_entered(track_id: String)
signal pit_lane_exited(track_id: String)
signal pit_lane_entry_crossed(track_id: String)
signal pit_lane_exit_crossed(track_id: String)
signal pit_lane_speed_violation(speed_kph: float, penalty_seconds: float)

const TRACK_ID := "baghdad_international_motorsport_park"
const TRACK_NAME := "Baghdad International Motorsport Park"
const TRACK_CENTER_OFFSET := Vector3(320.0, 0.0, 220.0)
const TRACK_HALF_LENGTH := 145.0
const TRACK_HALF_WIDTH := 82.0
const ROAD_WIDTH := 18.0
const ROAD_THICKNESS := 0.8
const PIT_LANE_SPEED_LIMIT_KPH := 60.0

const CHECKPOINT_COUNT := 4
const MotorsportAIControllerScript = preload("res://scripts/system_motorsport_ai_controller.gd")
const VehicleScript = preload("res://scripts/system_drivable_vehicle.gd")
const VehicleCatalogScript = preload("res://scripts/system_vehicle_catalog.gd")
const START_GRID_OFFSET := Vector3(TRACK_HALF_LENGTH, 0.0, -8.0)
const CHECKPOINT_ANGLES := [0.0, PI * 0.5, PI, PI * 1.5]

var checkpoint_areas: Array[Area3D] = []
var start_grid_marker: Node3D
var last_checkpoint_result: Dictionary = {}
var ai_opponent_nodes: Array[Node3D] = []
var ai_controller_nodes: Array[Node] = []
var ai_race_pending_start := false
var ai_race_results: Array[Dictionary] = []
var ai_race_event_id := ""


var player: CharacterBody3D
var vehicle_runtime_manager: Node
var motorsport_manager: Node
var track_root: Node3D
var track_zone: Area3D
var player_inside_track := false
var pit_lane_context_area: Area3D
var pit_lane_entry_area: Area3D
var pit_lane_exit_area: Area3D
var active_vehicle_in_pit_lane := false
var pit_lane_speed_violation_applied := false
const PIT_SPEED_PENALTY_SECONDS := 5.0
var pit_garage_nodes: Array[Node3D] = []
var marshal_post_nodes: Array[Node3D] = []
var race_control_tower: Node3D

func setup(p_player: CharacterBody3D, p_vehicle_runtime_manager: Node, p_motorsport_manager: Node) -> void:
	player = p_player
	vehicle_runtime_manager = p_vehicle_runtime_manager
	motorsport_manager = p_motorsport_manager
	if is_instance_valid(motorsport_manager):
		if motorsport_manager.has_signal("race_started"):
			motorsport_manager.connect("race_started", Callable(self, "_on_motorsport_race_started"))
		if motorsport_manager.has_signal("race_cancelled"):
			motorsport_manager.connect("race_cancelled", Callable(self, "_on_motorsport_race_cancelled"))
		if motorsport_manager.has_signal("race_go"):
			motorsport_manager.connect("race_go", Callable(self, "_on_motorsport_race_go"))
	if is_instance_valid(vehicle_runtime_manager) and vehicle_runtime_manager.has_signal("driving_changed"):
		vehicle_runtime_manager.connect("driving_changed", Callable(self, "_on_player_driving_changed"))


func _physics_process(_delta: float) -> void:
	if not active_vehicle_in_pit_lane or pit_lane_speed_violation_applied:
		return
	if not is_instance_valid(vehicle_runtime_manager) or not is_instance_valid(motorsport_manager):
		return
	var active_vehicle: Node = vehicle_runtime_manager.get("active_vehicle")
	if not is_instance_valid(active_vehicle) or not (active_vehicle is RigidBody3D):
		return
	var speed_kph := (active_vehicle as RigidBody3D).linear_velocity.length() * 3.6
	if speed_kph <= PIT_LANE_SPEED_LIMIT_KPH:
		return
	if not motorsport_manager.has_method("add_race_time_penalty") or not motorsport_manager.call("is_race_active"):
		return
	var penalty_result: Dictionary = motorsport_manager.call("add_race_time_penalty", PIT_SPEED_PENALTY_SECONDS, "pit_lane_speeding")
	if bool(penalty_result.get("success", false)):
		pit_lane_speed_violation_applied = true
		pit_lane_speed_violation.emit(speed_kph, PIT_SPEED_PENALTY_SECONDS)
		push_warning("SYSTEM Motorsport: pit lane speed %.1f km/h exceeded the %.1f km/h limit; %.1f seconds added." % [speed_kph, PIT_LANE_SPEED_LIMIT_KPH, PIT_SPEED_PENALTY_SECONDS])


func _process(_delta: float) -> void:
	_validate_countdown_grid_state()


## Cancel the start while the countdown is active if the player leaves the car
## or the staged vehicle moves away from the starting grid.
func _validate_countdown_grid_state() -> void:
	if not is_instance_valid(motorsport_manager) or not motorsport_manager.has_method("is_race_active"):
		return
	if not bool(motorsport_manager.call("is_race_active")):
		return
	var countdown_remaining := float(motorsport_manager.get("race_countdown_remaining"))
	if countdown_remaining < 0.0 or bool(motorsport_manager.get("race_is_running")):
		return
	if not is_instance_valid(vehicle_runtime_manager) or not bool(vehicle_runtime_manager.get("is_driving")):
		if motorsport_manager.has_method("cancel_race"):
			motorsport_manager.call("cancel_race")
		return
	var active_vehicle := vehicle_runtime_manager.get("active_vehicle") as Node3D
	if not is_instance_valid(active_vehicle) or active_vehicle.global_position.distance_to(get_start_grid_position()) > 22.0:
		if motorsport_manager.has_method("cancel_race"):
			motorsport_manager.call("cancel_race")


func _ready() -> void:
	name = "SystemMotorsportTrackManager"
	_build_baghdad_track()

func _build_baghdad_track() -> void:
	var region := get_parent().get_node_or_null("ModernWorldRegionManager")
	var center := TRACK_CENTER_OFFSET
	if region != null and region.has_method("get_city_anchor"):
		var baghdad_anchor: Vector3 = region.call("get_city_anchor", "Baghdad")
		if baghdad_anchor != Vector3.INF:
			center = baghdad_anchor + TRACK_CENTER_OFFSET
	track_root = Node3D.new()
	track_root.name = "BaghdadInternationalMotorsportPark_Blockout"
	add_child(track_root)
	track_root.global_position = center
	_build_circuit_surface()
	_build_safety_barriers()
	_build_paddock()
	_build_spectator_stands()
	_build_start_finish_and_grid()
	_build_checkpoints()
	_build_track_zone()
	print("SYSTEM Motorsport: Baghdad track blockout created; final track art and navigation are pending.")

func _build_circuit_surface() -> void:
	var segments := 32
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		var next_angle := TAU * float(index + 1) / float(segments)
		var a := Vector3(cos(angle) * TRACK_HALF_LENGTH, 0.0, sin(angle) * TRACK_HALF_WIDTH)
		var b := Vector3(cos(next_angle) * TRACK_HALF_LENGTH, 0.0, sin(next_angle) * TRACK_HALF_WIDTH)
		var midpoint := (a + b) * 0.5
		var direction := b - a
		var length := direction.length() + 2.0
		_create_box("TrackRoad_%02d" % index, Vector3(ROAD_WIDTH, ROAD_THICKNESS, length), midpoint + Vector3.UP * 0.0, atan2(direction.x, direction.z), Color(0.105, 0.11, 0.12), true)
		_create_box("TrackInnerLine_%02d" % index, Vector3(0.42, 0.035, length * 0.96), midpoint + Vector3.UP * 0.43, atan2(direction.x, direction.z), Color(0.92, 0.9, 0.78), false)

func _build_safety_barriers() -> void:
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		var position := Vector3(cos(angle) * (TRACK_HALF_LENGTH + 12.0), 1.4, sin(angle) * (TRACK_HALF_WIDTH + 12.0))
		var tangent := Vector3(-sin(angle), 0.0, cos(angle))
		_create_box("SafetyBarrier_%02d" % index, Vector3(3.0, 2.8, 9.0), position, atan2(tangent.x, tangent.z), Color(0.78, 0.79, 0.8), true)

func _build_paddock() -> void:
	# Separate the north-side paddock from spectator stands and connect it to the pit lane.
	_create_box("PaddockGround", Vector3(112.0, 0.4, 58.0), Vector3(0.0, 0.2, -200.0), 0.0, Color(0.22, 0.23, 0.24), true)
	_create_box("PitServiceApron", Vector3(112.0, 0.4, 50.0), Vector3(0.0, 0.2, -145.0), 0.0, Color(0.29, 0.30, 0.31), true)
	_create_box("PitLane", Vector3(112.0, 0.4, 12.0), Vector3(0.0, 0.2, -TRACK_HALF_WIDTH - 34.0), 0.0, Color(0.16, 0.17, 0.18), true)
	for bay in range(8):
		var garage_x: float = -45.5 + float(bay) * 13.0
		_build_pit_garage_bay(bay, garage_x, -181.0)
	_build_pit_lane_triggers()


func _build_spectator_stands() -> void:
	var stand_color := Color(0.24, 0.27, 0.31)
	var seat_color := Color(0.12, 0.34, 0.52)
	# Main grandstand on the south straight.
	for row in range(4):
		var stand_y: float = 2.0 + float(row) * 1.8
		var stand_z: float = TRACK_HALF_WIDTH + 34.0 + float(row) * 5.0
		_create_box("Grandstand_South_%02d" % row, Vector3(76.0, 2.0, 7.0), Vector3(0.0, stand_y, stand_z), 0.0, stand_color, true)
		for seat_index in range(16):
			var seat_x: float = -34.0 + float(seat_index) * 4.5
			_create_box("GrandstandSeat_South_%02d_%02d" % [row, seat_index], Vector3(1.4, 0.6, 0.9), Vector3(seat_x, stand_y + 1.35, stand_z), 0.0, seat_color, false)
	# East and west end stands complete the spectator circuit without overlapping the paddock.
	for side_index in range(2):
		var side: float = -1.0 if side_index == 0 else 1.0
		var side_label: String = "west" if side < 0.0 else "east"
		for row in range(3):
			var stand_y: float = 2.0 + float(row) * 1.8
			var stand_x: float = side * (TRACK_HALF_LENGTH + 34.0 + float(row) * 5.0)
			_create_box("Grandstand_End_%s_%02d" % [side_label, row], Vector3(7.0, 2.0, 56.0), Vector3(stand_x, stand_y, 0.0), 0.0, stand_color, true)
			for seat_index in range(8):
				var seat_z: float = -24.0 + float(seat_index) * 6.8
				_create_box("GrandstandSeat_End_%s_%02d_%02d" % [side_label, row, seat_index], Vector3(0.9, 0.6, 1.4), Vector3(stand_x, stand_y + 1.35, seat_z), 0.0, seat_color, false)
	# Collision-backed stairs give players physical access to the south stand tiers.
	for stair_side in [-1.0, 1.0]:
		for step in range(5):
			var step_y: float = 0.3 + float(step) * 0.6
			var step_z: float = TRACK_HALF_WIDTH + 25.0 + float(step) * 1.5
			_create_box("GrandstandSouthStair_%s_%02d" % [str(stair_side), step], Vector3(3.2, 0.55, 2.4), Vector3(stair_side * 27.0, step_y, step_z), 0.0, stand_color, true)

func _build_track_zone() -> void:
	track_zone = Area3D.new()
	track_zone.name = "ApprovedMotorsportTrackZone"
	track_zone.position = Vector3.ZERO
	track_zone.collision_layer = 0
	track_zone.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3((TRACK_HALF_LENGTH + 48.0) * 2.0, 18.0, (TRACK_HALF_WIDTH + 150.0) * 2.0)
	collision.shape = shape
	track_zone.add_child(collision)
	track_root.add_child(track_zone)
	track_zone.body_entered.connect(_on_track_zone_body_entered)
	track_zone.body_exited.connect(_on_track_zone_body_exited)


func _build_start_finish_and_grid() -> void:
	start_grid_marker = Node3D.new()
	start_grid_marker.name = "RaceStartGrid"
	start_grid_marker.position = START_GRID_OFFSET
	track_root.add_child(start_grid_marker)
	for lane in range(4):
		var lane_x := -4.5 + float(lane) * 3.0
		_create_box("StartGridLane_%02d" % lane, Vector3(0.22, 0.045, 8.0), START_GRID_OFFSET + Vector3(lane_x, 0.48, -2.0), 0.0, Color(0.95, 0.95, 0.9), false)
	_create_box("StartFinishLine", Vector3(ROAD_WIDTH, 0.06, 1.3), Vector3(TRACK_HALF_LENGTH, 0.49, 0.0), 0.0, Color(0.95, 0.9, 0.16), false)
	_create_box("StartFinishGantries_Crossbar", Vector3(ROAD_WIDTH + 3.0, 0.8, 1.2), Vector3(TRACK_HALF_LENGTH, 7.0, 0.0), 0.0, Color(0.12, 0.2, 0.27), false)
	for side in [-1.0, 1.0]:
		_create_box("StartFinishGantries_Post_%s" % str(side), Vector3(1.1, 7.0, 1.2), Vector3(TRACK_HALF_LENGTH + side * (ROAD_WIDTH * 0.5 + 1.5), 3.5, 0.0), 0.0, Color(0.12, 0.2, 0.27), false)
	var race_control := Area3D.new()
	race_control.name = "RaceControlInteraction"
	race_control.position = START_GRID_OFFSET + Vector3(0.0, 1.5, -13.0)
	race_control.add_to_group("system_interactable")
	race_control.set_meta("system_location_id", "baghdad_motorsport_race_control")
	race_control.set_meta("system_region_id", "region_baghdad")
	race_control.set_meta("system_display_name", "Baghdad International Motorsport Park — Race Control")
	race_control.set_meta("system_interaction_prompt", "مكتب إدارة السباق — بدء كأس السرعة بعد الوقوف على خط الانطلاق")
	race_control.set_meta("system_location_type", 7)
	race_control.set_meta("system_access_state", "walk_in_race_control")
	race_control.set_meta("system_location_position", track_root.to_global(race_control.position))
	var control_collision := CollisionShape3D.new()
	var control_shape := SphereShape3D.new()
	control_shape.radius = 4.5
	control_collision.shape = control_shape
	race_control.add_child(control_collision)
	track_root.add_child(race_control)

	var leaderboard_board := Area3D.new()
	leaderboard_board.name = "MotorsportLeaderboardInteraction"
	leaderboard_board.position = START_GRID_OFFSET + Vector3(-13.0, 1.5, -13.0)
	leaderboard_board.add_to_group("system_interactable")
	leaderboard_board.set_meta("system_location_id", "baghdad_motorsport_leaderboard")
	leaderboard_board.set_meta("system_region_id", "region_baghdad")
	leaderboard_board.set_meta("system_display_name", "SYSTEM Motorsport — لوحة النتائج")
	leaderboard_board.set_meta("system_interaction_prompt", "لوحة نتائج السباقات — عرض أفضل الأزمنة والترتيب المحلي")
	leaderboard_board.set_meta("system_location_type", 7)
	leaderboard_board.set_meta("system_location_position", track_root.to_global(leaderboard_board.position))
	var leaderboard_collision := CollisionShape3D.new()
	var leaderboard_shape := SphereShape3D.new()
	leaderboard_shape.radius = 4.5
	leaderboard_collision.shape = leaderboard_shape
	leaderboard_board.add_child(leaderboard_collision)
	track_root.add_child(leaderboard_board)
	_create_box(
		"MotorsportLeaderboardScreen",
		Vector3(5.0, 3.2, 0.35),
		START_GRID_OFFSET + Vector3(-13.0, 3.0, -15.5),
		0.0,
		Color(0.035, 0.12, 0.17),
		false
	)
	_build_race_control_tower()

func _build_checkpoints() -> void:
	for index in range(CHECKPOINT_COUNT):
		var angle: float = CHECKPOINT_ANGLES[index]
		var point := Vector3(cos(angle) * TRACK_HALF_LENGTH, 0.0, sin(angle) * TRACK_HALF_WIDTH)
		var tangent := Vector3(-sin(angle), 0.0, cos(angle))
		var gate := Node3D.new()
		gate.name = "RaceCheckpoint_%02d" % index
		gate.position = point
		gate.rotation.y = atan2(tangent.x, tangent.z)
		track_root.add_child(gate)
		_create_box("Checkpoint_%02d_PostLeft" % index, Vector3(0.8, 5.5, 0.8), point + (Basis(Vector3.UP, gate.rotation.y) * Vector3(-ROAD_WIDTH * 0.5, 2.75, 0.0)), gate.rotation.y, Color(0.08, 0.72, 0.92), false)
		_create_box("Checkpoint_%02d_PostRight" % index, Vector3(0.8, 5.5, 0.8), point + (Basis(Vector3.UP, gate.rotation.y) * Vector3(ROAD_WIDTH * 0.5, 2.75, 0.0)), gate.rotation.y, Color(0.08, 0.72, 0.92), false)
		_create_box("Checkpoint_%02d_Header" % index, Vector3(ROAD_WIDTH, 0.55, 0.8), point + Vector3.UP * 5.5, gate.rotation.y, Color(0.08, 0.72, 0.92), false)
		var area := Area3D.new()
		area.name = "CheckpointTrigger_%02d" % index
		area.collision_layer = 0
		area.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(ROAD_WIDTH + 3.0, 8.0, 5.0)
		collision.shape = shape
		area.add_child(collision)
		area.position = point + Vector3.UP * 2.5
		track_root.add_child(area)
		area.body_entered.connect(_on_checkpoint_body_entered.bind(index))
		checkpoint_areas.append(area)
	_build_marshal_posts()

func get_start_grid_position() -> Vector3:
	if not is_instance_valid(track_root):
		return Vector3.INF
	return track_root.to_global(START_GRID_OFFSET)

func start_track_event(event_id: String) -> Dictionary:
	if not player_inside_track:
		return {"success":false,"reason":"PLAYER_NOT_INSIDE_APPROVED_TRACK"}
	if vehicle_runtime_manager == null:
		return {"success":false,"reason":"VEHICLE_RUNTIME_UNAVAILABLE"}
	# Register the event on foot at Race Control after staging the owned car on the grid.
	# This avoids requiring the player to ray-interact through the vehicle body.
	if bool(vehicle_runtime_manager.get("is_driving")):
		return {"success":false,"reason":"EXIT_VEHICLE_TO_REGISTER_RACE"}
	var vehicle: Node3D = vehicle_runtime_manager.get("active_vehicle")
	if not is_instance_valid(vehicle):
		return {"success":false,"reason":"ACTIVE_VEHICLE_UNAVAILABLE"}
	var vehicle_id := str(vehicle.get("vehicle_id"))
	var grid_position := get_start_grid_position()
	if vehicle.global_position.distance_to(grid_position) > 18.0:
		return {"success":false,"reason":"VEHICLE_NOT_ON_START_GRID","start_grid":grid_position}
	if motorsport_manager == null or not motorsport_manager.has_method("start_race"):
		return {"success":false,"reason":"MOTORSPORT_MANAGER_UNAVAILABLE"}
	var result: Dictionary = motorsport_manager.call("start_race", event_id, vehicle_id, CHECKPOINT_COUNT)
	if bool(result.get("success", false)):
		last_checkpoint_result.clear()
	return result

func _on_motorsport_race_started(event_id: String, _player_vehicle_id: String) -> void:
	_clear_ai_opponents()
	ai_race_event_id = event_id
	ai_race_pending_start = true
	ai_race_results.clear()
	var event: Dictionary = motorsport_manager.call("get_event", event_id)
	var laps := maxi(1, int(event.get("laps", 3)))
	var categories: Array = event.get("vehicle_categories", [])
	var circuit_events := ["city_sprint", "gt_championship", "formula_grand_prix", "endurance_challenge"]
	if not circuit_events.has(event_id):
		print("SYSTEM Motorsport AI: this event discipline is not yet supported by the circuit prototype.")
		return
	var waypoints: Array[Vector3] = []
	for area in checkpoint_areas:
		if is_instance_valid(area):
			waypoints.append(area.global_position)
	if waypoints.size() < 2:
		push_warning("SYSTEM Motorsport AI: checkpoint route is unavailable.")
		return
	var candidate_ids := [
		"sport_coupe", "performance_supercar", "electric_hyper_sedan",
		"gt3_race_car", "endurance_prototype", "track_hypercar", "formula_race_car"
	]
	var eligible_ids: Array[String] = []
	for candidate_id in candidate_ids:
		var data := VehicleCatalogScript.get_vehicle(candidate_id)
		if categories.has(str(data.get("category", ""))):
			eligible_ids.append(candidate_id)
	if eligible_ids.is_empty():
		push_warning("SYSTEM Motorsport AI: no eligible opponent vehicle class was found.")
		return
	var grid := get_start_grid_position()
	var lane_offsets := [-4.5, 0.0, 4.5]
	var colors := [Color(0.78, 0.12, 0.12), Color(0.08, 0.42, 0.82), Color(0.92, 0.62, 0.08)]
	for index in range(3):
		var vehicle_id: String = eligible_ids[index % eligible_ids.size()]
		var vehicle_data := VehicleCatalogScript.get_vehicle(vehicle_id)
		var opponent := VehicleScript.new()
		opponent.name = "AI_Racer_%02d_%s" % [index + 1, vehicle_id]
		opponent.configure(vehicle_data, vehicle_id)
		opponent.set_paint_color(colors[index])
		track_root.add_child(opponent)
		opponent.global_position = grid + Vector3(lane_offsets[index], 0.85, -8.0)
		opponent.global_rotation.y = PI
		var controller := MotorsportAIControllerScript.new()
		controller.name = "MotorsportAIController"
		opponent.add_child(controller)
		var opponent_name := "SYSTEM Racer %02d" % (index + 1)
		var cruise_speed := 27.0 + float(index) * 1.8
		controller.setup(opponent, "baghdad_ai_%02d" % (index + 1), opponent_name, waypoints, laps, cruise_speed)
		controller.opponent_finished.connect(_on_ai_opponent_finished)
		ai_controller_nodes.append(controller)
		ai_opponent_nodes.append(opponent)
	print("SYSTEM Motorsport AI: %d circuit opponents entered %s." % [ai_opponent_nodes.size(), event_id])

func _on_player_driving_changed(active: bool, _vehicle_id: String) -> void:
	if not active:
		_validate_countdown_grid_state()
		return
	if not ai_race_pending_start:
		return
	if not is_instance_valid(motorsport_manager) or not motorsport_manager.has_method("begin_race_countdown"):
		return
	var countdown_result: Dictionary = motorsport_manager.call("begin_race_countdown", 3.0)
	if bool(countdown_result.get("success", false)):
		ai_race_pending_start = false
		print("SYSTEM Motorsport: three-second starting countdown initiated.")


func _on_motorsport_race_go(_event_id: String) -> void:
	if not is_instance_valid(vehicle_runtime_manager) or not bool(vehicle_runtime_manager.get("is_driving")):
		if is_instance_valid(motorsport_manager) and motorsport_manager.has_method("cancel_race"):
			motorsport_manager.call("cancel_race")
		return
	var active_vehicle: Node3D = vehicle_runtime_manager.get("active_vehicle")
	if not is_instance_valid(active_vehicle) or active_vehicle.global_position.distance_to(get_start_grid_position()) > 22.0:
		if is_instance_valid(motorsport_manager) and motorsport_manager.has_method("cancel_race"):
			motorsport_manager.call("cancel_race")
		return
	for controller in ai_controller_nodes:
		if is_instance_valid(controller) and controller.has_method("start_race"):
			controller.call("start_race")
	print("SYSTEM Motorsport: green light — player and AI grid released.")

func _on_ai_opponent_finished(result: Dictionary) -> void:
	var completed_result := result.duplicate(true)
	completed_result["finish_position"] = ai_race_results.size() + 1
	ai_race_results.append(completed_result)
	print("SYSTEM Motorsport AI: %s finished in position %d." % [str(completed_result.get("opponent_name", "AI")), int(completed_result.get("finish_position", 0))])

func get_ai_race_results() -> Array[Dictionary]:
	return ai_race_results.duplicate(true)


func get_ai_race_event_id() -> String:
	return ai_race_event_id


func get_ai_race_status() -> Array[Dictionary]:
	var standings: Array[Dictionary] = []
	for controller in ai_controller_nodes:
		if not is_instance_valid(controller):
			continue
		var completed_laps := int(controller.get("completed_laps"))
		var total_laps := maxi(1, int(controller.get("total_laps")))
		var elapsed := float(controller.get("elapsed_seconds"))
		var active := bool(controller.get("active"))
		var finished := not active and completed_laps >= total_laps
		var target_checkpoint := int(controller.get("target_checkpoint"))
		var waypoints: Array = controller.get("waypoints")
		var checkpoint_progress := posmod(target_checkpoint - 1, waypoints.size()) if not waypoints.is_empty() else 0
		var distance_to_next_checkpoint := INF
		var vehicle_node := controller.get("vehicle") as Node3D
		if is_instance_valid(vehicle_node) and target_checkpoint >= 0 and target_checkpoint < waypoints.size():
			distance_to_next_checkpoint = vehicle_node.global_position.distance_to(waypoints[target_checkpoint])
		standings.append({
			"opponent_id": str(controller.get("opponent_id")),
			"opponent_name": str(controller.get("opponent_name")),
			"vehicle_id": str(vehicle_node.get("vehicle_id")) if is_instance_valid(vehicle_node) else "",
			"completed_laps": completed_laps,
			"total_laps": total_laps,
			"checkpoint_progress": checkpoint_progress,
			"distance_to_next_checkpoint": distance_to_next_checkpoint,
			"elapsed_seconds": elapsed,
			"finished": finished,
			"status": "finished" if finished else ("racing" if active else ("starting" if ai_race_pending_start or (is_instance_valid(motorsport_manager) and float(motorsport_manager.get("race_countdown_remaining")) >= 0.0) else "retired"))
		})
	standings.sort_custom(_sort_race_standings)
	return standings


func get_race_standings() -> Array[Dictionary]:
	var standings := get_ai_race_status()
	if ai_race_event_id.is_empty() or not is_instance_valid(motorsport_manager):
		return standings
	var active_race := bool(motorsport_manager.call("is_race_active"))
	var completed_laps := int(motorsport_manager.get("completed_laps"))
	var total_laps := maxi(1, int(motorsport_manager.get("total_laps")))
	var next_checkpoint := int(motorsport_manager.get("next_checkpoint_index"))
	var finished := not active_race and completed_laps >= total_laps
	var checkpoint_progress := next_checkpoint if not finished else 0
	var distance_to_next_checkpoint := INF
	var player_vehicle := vehicle_runtime_manager.get("active_vehicle") as Node3D if is_instance_valid(vehicle_runtime_manager) else null
	if not finished and is_instance_valid(player_vehicle) and next_checkpoint >= 0 and next_checkpoint < checkpoint_areas.size():
		distance_to_next_checkpoint = player_vehicle.global_position.distance_to(checkpoint_areas[next_checkpoint].global_position)
	var countdown_active := float(motorsport_manager.get("race_countdown_remaining")) >= 0.0
	var race_running := bool(motorsport_manager.get("race_is_running"))
	var player_status := "finished" if finished else ("racing" if race_running else ("starting" if countdown_active else ("awaiting_vehicle" if ai_race_pending_start else "ready")))
	standings.append({
		"opponent_id": "player",
		"opponent_name": "أنت",
		"vehicle_id": str(player_vehicle.get("vehicle_id")) if is_instance_valid(player_vehicle) else "",
		"completed_laps": completed_laps,
		"total_laps": total_laps,
		"checkpoint_progress": checkpoint_progress,
		"distance_to_next_checkpoint": distance_to_next_checkpoint,
		"elapsed_seconds": float(motorsport_manager.get("race_elapsed")) + float(motorsport_manager.get("race_time_penalty")),
		"finished": finished,
		"status": player_status,
		"is_player": true
	})
	standings.sort_custom(_sort_race_standings)
	return standings


func _sort_race_standings(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("completed_laps", 0)) != int(b.get("completed_laps", 0)):
		return int(a.get("completed_laps", 0)) > int(b.get("completed_laps", 0))
	var a_finished := bool(a.get("finished", false))
	var b_finished := bool(b.get("finished", false))
	if a_finished != b_finished:
		return a_finished
	if a_finished and b_finished:
		return float(a.get("elapsed_seconds", 0.0)) < float(b.get("elapsed_seconds", 0.0))
	if int(a.get("checkpoint_progress", 0)) != int(b.get("checkpoint_progress", 0)):
		return int(a.get("checkpoint_progress", 0)) > int(b.get("checkpoint_progress", 0))
	if absf(float(a.get("distance_to_next_checkpoint", INF)) - float(b.get("distance_to_next_checkpoint", INF))) > 0.001:
		return float(a.get("distance_to_next_checkpoint", INF)) < float(b.get("distance_to_next_checkpoint", INF))
	return float(a.get("elapsed_seconds", 0.0)) < float(b.get("elapsed_seconds", 0.0))

func _on_motorsport_race_cancelled(_event_id: String) -> void:
	_clear_ai_opponents()
	ai_race_results.clear()
	ai_race_pending_start = false
	ai_race_event_id = ""

func _clear_ai_opponents() -> void:
	for opponent in ai_opponent_nodes:
		if is_instance_valid(opponent):
			opponent.queue_free()
	ai_opponent_nodes.clear()
	ai_controller_nodes.clear()

func _on_checkpoint_body_entered(body: Node3D, checkpoint_index: int) -> void:
	if vehicle_runtime_manager == null:
		return
	var active_vehicle: Node = vehicle_runtime_manager.get("active_vehicle")
	if not is_instance_valid(active_vehicle) or body != active_vehicle:
		return
	if motorsport_manager == null or not motorsport_manager.has_method("register_checkpoint"):
		return
	last_checkpoint_result = motorsport_manager.call("register_checkpoint", checkpoint_index)
	if bool(last_checkpoint_result.get("success", false)):
		print("SYSTEM Motorsport: checkpoint %d registered." % checkpoint_index)

func _on_track_zone_body_entered(body: Node3D) -> void:
	if body != player:
		return
	player_inside_track = true
	_set_track_context(true)
	track_zone_entered.emit(TRACK_ID)

func _on_track_zone_body_exited(body: Node3D) -> void:
	if body != player:
		return
	player_inside_track = false
	_set_track_context(false)
	track_zone_exited.emit(TRACK_ID)

func _set_track_context(enabled: bool) -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.has_method("set_dedicated_track_context"):
		vehicle_runtime_manager.call("set_dedicated_track_context", enabled)
	if motorsport_manager != null and motorsport_manager.has_method("set_dedicated_track_context"):
		motorsport_manager.call("set_dedicated_track_context", enabled)

func get_track_info() -> Dictionary:
	return {
		"track_id": TRACK_ID,
		"name": TRACK_NAME,
		"track_zone_active": is_instance_valid(track_zone),
		"player_inside": player_inside_track,
		"venue_status": "physical_facilities_blockout",
		"race_ready": false,
		"checkpoint_count": checkpoint_areas.size(),
		"pit_garage_count": pit_garage_nodes.size(),
		"marshal_post_count": marshal_post_nodes.size(),
		"pit_lane_context_active": is_instance_valid(pit_lane_context_area),
		"active_vehicle_in_pit_lane": active_vehicle_in_pit_lane,
		"pit_lane_speed_limit_kph": PIT_LANE_SPEED_LIMIT_KPH,
		"race_control_tower_ready": is_instance_valid(race_control_tower),
		"start_grid_position": get_start_grid_position(),
		"race_start_api_available": true
	}

func _build_pit_garage_bay(bay_index: int, x: float, z: float) -> void:
	var garage := Node3D.new()
	garage.name = "PitGarageBay_%02d" % bay_index
	garage.position = Vector3(x, 0.0, z)
	garage.set_meta("system_location_id", "baghdad_motorsport_pit_garage_%02d" % bay_index)
	track_root.add_child(garage)
	pit_garage_nodes.append(garage)
	var wall_color := Color(0.28, 0.32, 0.36)
	_create_box_under(garage, "GarageFloor", Vector3(11.0, 0.4, 16.0), Vector3(0.0, 0.2, 0.0), 0.0, Color(0.19, 0.21, 0.23), true)
	_create_box_under(garage, "GarageBackWall", Vector3(11.0, 5.0, 0.6), Vector3(0.0, 2.9, -7.7), 0.0, wall_color, true)
	_create_box_under(garage, "GarageLeftWall", Vector3(0.6, 5.0, 16.0), Vector3(-5.2, 2.9, 0.0), 0.0, wall_color, true)
	_create_box_under(garage, "GarageRightWall", Vector3(0.6, 5.0, 16.0), Vector3(5.2, 2.9, 0.0), 0.0, wall_color, true)
	_create_box_under(garage, "GarageFrontHeader", Vector3(11.0, 0.7, 0.6), Vector3(0.0, 4.9, 7.7), 0.0, wall_color, true)
	_create_box_under(garage, "TireRack", Vector3(1.2, 2.5, 1.5), Vector3(-4.0, 1.45, -3.0), 0.0, Color(0.13, 0.15, 0.17), true)
	_create_box_under(garage, "ToolCabinet", Vector3(1.2, 2.4, 1.2), Vector3(4.0, 1.4, -3.0), 0.0, Color(0.48, 0.27, 0.12), true)
	_create_box_under(garage, "WorkBench", Vector3(4.0, 0.9, 1.5), Vector3(0.0, 0.65, -5.2), 0.0, Color(0.34, 0.36, 0.38), true)
	_create_box_under(garage, "GarageRoof", Vector3(11.0, 0.4, 16.0), Vector3(0.0, 5.35, 0.0), 0.0, Color(0.12, 0.16, 0.2), false)
	var sign := Label3D.new()
	sign.name = "PitGarageSign"
	sign.text = "PIT %02d" % (bay_index + 1)
	sign.font_size = 22
	sign.position = Vector3(0.0, 5.9, 7.9)
	sign.modulate = Color(0.62, 0.9, 1.0)
	garage.add_child(sign)
	var light := OmniLight3D.new()
	light.name = "GarageCeilingLight"
	light.position = Vector3(0.0, 4.6, 0.0)
	light.omni_range = 18.0
	light.light_energy = 1.1
	garage.add_child(light)
	var interaction := Area3D.new()
	interaction.name = "GarageEntranceInteraction"
	interaction.position = Vector3(0.0, 1.5, 7.2)
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_location_id", "baghdad_motorsport_pit_garage_%02d" % bay_index)
	interaction.set_meta("system_region_id", "region_baghdad")
	interaction.set_meta("system_location_type", 7)
	interaction.set_meta("system_display_name", "كراج صيانة السباق — %02d" % (bay_index + 1))
	interaction.set_meta("system_interaction_prompt", "دخول كراج الصيانة وفحص تجهيزات سيارة السباق")
	interaction.set_meta("system_access_state", "walk_in_pit_garage")
	interaction.set_meta("system_location_position", garage.to_global(interaction.position))
	var area_collision := CollisionShape3D.new()
	var area_shape := BoxShape3D.new()
	area_shape.size = Vector3(4.0, 3.0, 3.0)
	area_collision.shape = area_shape
	interaction.add_child(area_collision)
	garage.add_child(interaction)


func _build_pit_lane_triggers() -> void:
	var pit_z: float = -TRACK_HALF_WIDTH - 34.0
	pit_lane_context_area = Area3D.new()
	pit_lane_context_area.name = "PitLaneContextArea"
	pit_lane_context_area.position = Vector3(0.0, 2.5, pit_z)
	pit_lane_context_area.collision_layer = 0
	pit_lane_context_area.collision_mask = 1
	pit_lane_context_area.set_meta("system_pit_lane_speed_limit_kph", PIT_LANE_SPEED_LIMIT_KPH)
	var context_collision := CollisionShape3D.new()
	var context_shape := BoxShape3D.new()
	context_shape.size = Vector3(112.0, 6.0, 12.0)
	context_collision.shape = context_shape
	pit_lane_context_area.add_child(context_collision)
	track_root.add_child(pit_lane_context_area)
	pit_lane_context_area.body_entered.connect(_on_pit_lane_context_body_entered)
	pit_lane_context_area.body_exited.connect(_on_pit_lane_context_body_exited)
	pit_lane_entry_area = _build_pit_lane_gate("PitLaneEntryGateArea", "baghdad_motorsport_pit_entry", Vector3(45.0, 0.0, pit_z), true)
	pit_lane_exit_area = _build_pit_lane_gate("PitLaneExitGateArea", "baghdad_motorsport_pit_exit", Vector3(-45.0, 0.0, pit_z), false)


func _build_pit_lane_gate(node_name: String, location_id: String, center: Vector3, is_entry: bool) -> Area3D:
	var gate_name: String = "ENTRY" if is_entry else "EXIT"
	_create_box("PitLane%s_LeftPost" % gate_name, Vector3(0.8, 5.0, 0.8), center + Vector3(-5.0, 2.5, 0.0), 0.0, Color(0.08, 0.7, 0.88), false)
	_create_box("PitLane%s_RightPost" % gate_name, Vector3(0.8, 5.0, 0.8), center + Vector3(5.0, 2.5, 0.0), 0.0, Color(0.08, 0.7, 0.88), false)
	_create_box("PitLane%s_Header" % gate_name, Vector3(10.0, 0.6, 0.8), center + Vector3(0.0, 5.0, 0.0), 0.0, Color(0.08, 0.7, 0.88), false)
	var sign := Label3D.new()
	sign.name = "PitLane%sSign" % gate_name
	sign.text = "PIT " + gate_name
	sign.font_size = 20
	sign.position = center + Vector3(0.0, 6.0, 0.0)
	sign.modulate = Color(0.62, 0.9, 1.0)
	track_root.add_child(sign)
	var area := Area3D.new()
	area.name = node_name
	area.position = center + Vector3.UP * 1.5
	area.collision_layer = 0
	area.collision_mask = 1
	area.set_meta("system_location_id", location_id)
	area.set_meta("system_region_id", "region_baghdad")
	area.set_meta("system_location_type", 7)
	area.set_meta("system_display_name", "بوابة حارة الصيانة — " + gate_name)
	area.set_meta("system_access_state", "pit_lane_vehicle_gate")
	area.set_meta("system_location_position", track_root.to_global(center))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(10.0, 4.0, 5.0)
	collision.shape = shape
	area.add_child(collision)
	track_root.add_child(area)
	if is_entry:
		area.body_entered.connect(_on_pit_lane_entry_body_entered)
	else:
		area.body_entered.connect(_on_pit_lane_exit_body_entered)
	return area


func _on_pit_lane_context_body_entered(body: Node3D) -> void:
	if not _is_active_vehicle(body) or active_vehicle_in_pit_lane:
		return
	active_vehicle_in_pit_lane = true
	pit_lane_speed_violation_applied = false
	pit_lane_entered.emit(TRACK_ID)


func _on_pit_lane_context_body_exited(body: Node3D) -> void:
	if not _is_active_vehicle(body) or not active_vehicle_in_pit_lane:
		return
	active_vehicle_in_pit_lane = false
	pit_lane_speed_violation_applied = false
	pit_lane_exited.emit(TRACK_ID)


func _on_pit_lane_entry_body_entered(body: Node3D) -> void:
	if _is_active_vehicle(body):
		pit_lane_entry_crossed.emit(TRACK_ID)


func _on_pit_lane_exit_body_entered(body: Node3D) -> void:
	if _is_active_vehicle(body):
		pit_lane_exit_crossed.emit(TRACK_ID)


func _is_active_vehicle(body: Node3D) -> bool:
	if not is_instance_valid(vehicle_runtime_manager):
		return false
	var active_vehicle: Node = vehicle_runtime_manager.get("active_vehicle")
	return is_instance_valid(active_vehicle) and body == active_vehicle


func _build_race_control_tower() -> void:
	var center: Vector3 = START_GRID_OFFSET + Vector3(0.0, 0.0, -13.0)
	race_control_tower = Node3D.new()
	race_control_tower.name = "RaceControlTower"
	race_control_tower.position = center
	race_control_tower.set_meta("system_location_id", "baghdad_motorsport_race_control")
	race_control_tower.set_meta("system_location_position", track_root.to_global(center))
	track_root.add_child(race_control_tower)
	var wall_color := Color(0.22, 0.29, 0.35)
	var glass_color := Color(0.12, 0.38, 0.48)
	_create_box_under(race_control_tower, "RaceControlFloor", Vector3(14.0, 0.4, 12.0), Vector3(0.0, 0.2, 0.0), 0.0, Color(0.19, 0.21, 0.23), true)
	_create_box_under(race_control_tower, "RaceControlLeftWall", Vector3(0.45, 6.0, 12.0), Vector3(-6.8, 3.2, 0.0), 0.0, wall_color, true)
	_create_box_under(race_control_tower, "RaceControlRightWall", Vector3(0.45, 6.0, 12.0), Vector3(6.8, 3.2, 0.0), 0.0, wall_color, true)
	_create_box_under(race_control_tower, "RaceControlRearWall", Vector3(14.0, 6.0, 0.45), Vector3(0.0, 3.2, -5.8), 0.0, wall_color, true)
	_create_box_under(race_control_tower, "RaceControlFrontLeftWall", Vector3(4.5, 6.0, 0.45), Vector3(-4.75, 3.2, 5.8), 0.0, wall_color, true)
	_create_box_under(race_control_tower, "RaceControlFrontRightWall", Vector3(4.5, 6.0, 0.45), Vector3(4.75, 3.2, 5.8), 0.0, wall_color, true)
	_create_box_under(race_control_tower, "RaceControlDoorHeader", Vector3(5.0, 0.6, 0.45), Vector3(0.0, 5.8, 5.8), 0.0, wall_color, true)
	_create_box_under(race_control_tower, "RaceControlRoof", Vector3(14.0, 0.4, 12.0), Vector3(0.0, 6.4, 0.0), 0.0, wall_color, false)
	_create_box_under(race_control_tower, "RaceControlObservationDeck", Vector3(16.0, 0.4, 14.0), Vector3(0.0, 6.8, 0.0), 0.0, Color(0.16, 0.21, 0.26), true)
	_create_box_under(race_control_tower, "RaceControlBalconyFrontRail", Vector3(16.0, 1.0, 0.35), Vector3(0.0, 7.5, 6.8), 0.0, glass_color, true)
	_create_box_under(race_control_tower, "RaceControlBalconyBackRail", Vector3(16.0, 1.0, 0.35), Vector3(0.0, 7.5, -6.8), 0.0, glass_color, true)
	_create_box_under(race_control_tower, "RaceControlBalconyLeftRail", Vector3(0.35, 1.0, 13.6), Vector3(-7.8, 7.5, 0.0), 0.0, glass_color, true)
	_create_box_under(race_control_tower, "RaceControlBalconyRightRail", Vector3(0.35, 1.0, 13.6), Vector3(7.8, 7.5, 0.0), 0.0, glass_color, true)
	_create_box_under(race_control_tower, "RaceControlConsole", Vector3(4.5, 0.9, 1.4), Vector3(0.0, 0.85, -2.0), 0.0, Color(0.08, 0.12, 0.16), true)
	for index in range(3):
		_create_box_under(race_control_tower, "RaceControlMonitor_%02d" % index, Vector3(1.15, 0.9, 0.15), Vector3(-1.35 + float(index) * 1.35, 1.75, -2.55), 0.0, Color(0.06, 0.34, 0.48), false)
	for step in range(8):
		var step_y: float = 0.45 + float(step) * 0.82
		var step_z: float = 5.0 - float(step) * 1.35
		_create_box_under(race_control_tower, "RaceControlStair_%02d" % step, Vector3(3.0, 0.55, 1.5), Vector3(-8.2, step_y, step_z), 0.0, Color(0.27, 0.31, 0.35), true)
	var label := Label3D.new()
	label.name = "RaceControlTowerSign"
	label.text = "RACE CONTROL"
	label.font_size = 22
	label.position = Vector3(0.0, 9.0, -5.9)
	label.modulate = Color(0.6, 0.9, 1.0)
	race_control_tower.add_child(label)
	var light := OmniLight3D.new()
	light.name = "RaceControlInteriorLight"
	light.position = Vector3(0.0, 5.0, 0.0)
	light.omni_range = 18.0
	light.light_energy = 1.0
	race_control_tower.add_child(light)


func _build_marshal_posts() -> void:
	for index in range(CHECKPOINT_COUNT):
		var angle: float = CHECKPOINT_ANGLES[index]
		var post_x: float = cos(angle) * (TRACK_HALF_LENGTH + 24.0)
		var post_z: float = sin(angle) * (TRACK_HALF_WIDTH + 24.0)
		if index == 3:
			post_x = -80.0
		var post := Node3D.new()
		post.name = "MarshalPost_%02d" % index
		post.position = Vector3(post_x, 0.0, post_z)
		post.set_meta("system_location_id", "baghdad_motorsport_marshal_post_%02d" % index)
		post.set_meta("system_region_id", "region_baghdad")
		post.set_meta("system_display_name", "نقطة مراقبة السباق — %02d" % (index + 1))
		post.set_meta("system_location_position", track_root.to_global(post.position))
		track_root.add_child(post)
		marshal_post_nodes.append(post)
		_create_box_under(post, "MarshalPlatform", Vector3(6.0, 0.4, 6.0), Vector3(0.0, 0.2, 0.0), 0.0, Color(0.24, 0.27, 0.3), true)
		_create_box_under(post, "MarshalRearWall", Vector3(6.0, 3.0, 0.4), Vector3(0.0, 1.9, -2.8), 0.0, Color(0.3, 0.34, 0.38), true)
		_create_box_under(post, "MarshalSideWall", Vector3(0.4, 3.0, 6.0), Vector3(-2.8, 1.9, 0.0), 0.0, Color(0.3, 0.34, 0.38), true)
		_create_box_under(post, "MarshalRoof", Vector3(6.0, 0.4, 6.0), Vector3(0.0, 3.7, 0.0), 0.0, Color(0.12, 0.17, 0.22), false)
		_create_box_under(post, "MarshalFlagRack", Vector3(0.8, 1.8, 0.8), Vector3(2.0, 1.3, 2.0), 0.0, Color(0.72, 0.16, 0.12), true)
		var sign := Label3D.new()
		sign.name = "MarshalPostSign"
		sign.text = "MARSHAL %02d" % (index + 1)
		sign.font_size = 18
		sign.position = Vector3(0.0, 4.8, 2.7)
		post.add_child(sign)
		var interaction := Area3D.new()
		interaction.name = "MarshalPostInteraction"
		interaction.position = Vector3(0.0, 1.4, 2.5)
		interaction.add_to_group("system_interactable")
		interaction.set_meta("system_location_id", "baghdad_motorsport_marshal_post_%02d" % index)
		interaction.set_meta("system_region_id", "region_baghdad")
		interaction.set_meta("system_location_type", 7)
		interaction.set_meta("system_display_name", "نقطة مراقبة السباق — %02d" % (index + 1))
		interaction.set_meta("system_interaction_prompt", "فحص نقطة مراقبة الحكام وإشارات السلامة")
		interaction.set_meta("system_location_position", post.to_global(interaction.position))
		var area_collision := CollisionShape3D.new()
		var area_shape := BoxShape3D.new()
		area_shape.size = Vector3(4.0, 2.5, 3.0)
		area_collision.shape = area_shape
		interaction.add_child(area_collision)
		post.add_child(interaction)


func _create_box_under(parent: Node3D, box_name: String, box_size: Vector3, local_position: Vector3, yaw: float, color: Color, with_collision: bool) -> Node3D:
	var root := Node3D.new()
	root.name = box_name
	root.position = local_position
	root.rotation.y = yaw
	parent.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = "StaticCollision"
		var shape_node := CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = box_size
		shape_node.shape = shape
		body.add_child(shape_node)
		root.add_child(body)
	return root


func _create_box(box_name: String, box_size: Vector3, local_position: Vector3, yaw: float, color: Color, with_collision: bool) -> void:
	_create_box_under(track_root, box_name, box_size, local_position, yaw, color, with_collision)
