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
		"race_ready": false
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
