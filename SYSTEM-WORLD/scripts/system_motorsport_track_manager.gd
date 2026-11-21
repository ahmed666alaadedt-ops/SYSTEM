extends Node3D
class_name SystemMotorsportTrackManager

## First-pass physical motorsport venue blockout.
## The track-zone Area3D enables race-only vehicle access while the player is inside.
## Final road navigation, polished assets, AI grid, and race UI remain future work.

signal track_zone_entered(track_id: String)
signal track_zone_exited(track_id: String)

const TRACK_ID := "baghdad_international_motorsport_park"
const TRACK_NAME := "Baghdad International Motorsport Park"
const TRACK_CENTER_OFFSET := Vector3(320.0, 0.0, 220.0)
const TRACK_HALF_LENGTH := 145.0
const TRACK_HALF_WIDTH := 82.0
const ROAD_WIDTH := 18.0
const ROAD_THICKNESS := 0.8

const CHECKPOINT_COUNT := 4
const START_GRID_OFFSET := Vector3(TRACK_HALF_LENGTH, 0.0, -8.0)
const CHECKPOINT_ANGLES := [0.0, PI * 0.5, PI, PI * 1.5]

var checkpoint_areas: Array[Area3D] = []
var start_grid_marker: Node3D
var last_checkpoint_result: Dictionary = {}


var player: CharacterBody3D
var vehicle_runtime_manager: Node
var motorsport_manager: Node
var track_root: Node3D
var track_zone: Area3D
var player_inside_track := false

func setup(p_player: CharacterBody3D, p_vehicle_runtime_manager: Node, p_motorsport_manager: Node) -> void:
	player = p_player
	vehicle_runtime_manager = p_vehicle_runtime_manager
	motorsport_manager = p_motorsport_manager

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
	_create_box("PaddockGround", Vector3(112.0, 0.7, 58.0), Vector3(0.0, 0.0, -TRACK_HALF_WIDTH - 66.0), 0.0, Color(0.22, 0.23, 0.24), true)
	for bay in range(8):
		var x := -46.0 + float(bay) * 13.0
		_create_box("PitGarageBay_%02d" % bay, Vector3(11.0, 5.0, 16.0), Vector3(x, 2.8, -TRACK_HALF_WIDTH - 77.0), 0.0, Color(0.28, 0.32, 0.36), false)
	_create_box("PitLane", Vector3(112.0, 0.45, 12.0), Vector3(0.0, 0.5, -TRACK_HALF_WIDTH - 34.0), 0.0, Color(0.16, 0.17, 0.18), true)

func _build_spectator_stands() -> void:
	for side in [-1.0, 1.0]:
		for row in range(4):
			_create_box("Grandstand_%s_%02d" % [str(side), row], Vector3(76.0, 2.0, 7.0), Vector3(0.0, 2.0 + float(row) * 1.8, side * (TRACK_HALF_WIDTH + 34.0 + float(row) * 5.0)), 0.0, Color(0.24, 0.27, 0.31), false)

func _build_track_zone() -> void:
	track_zone = Area3D.new()
	track_zone.name = "ApprovedMotorsportTrackZone"
	track_zone.position = Vector3.ZERO
	track_zone.collision_layer = 0
	track_zone.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3((TRACK_HALF_LENGTH + 48.0) * 2.0, 18.0, (TRACK_HALF_WIDTH + 104.0) * 2.0)
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
		"venue_status": "procedural_blockout",
		"race_ready": false,
		"checkpoint_count": checkpoint_areas.size(),
		"start_grid_position": get_start_grid_position(),
		"race_start_api_available": true
	}

func _create_box(box_name: String, box_size: Vector3, local_position: Vector3, yaw: float, color: Color, with_collision: bool) -> void:
	var root := Node3D.new()
	root.name = box_name
	root.position = local_position
	root.rotation.y = yaw
	track_root.add_child(root)
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
		var shape := BoxShape3D.new()
		shape.size = box_size
		shape_node.shape = shape
		body.add_child(shape_node)
		root.add_child(body)
