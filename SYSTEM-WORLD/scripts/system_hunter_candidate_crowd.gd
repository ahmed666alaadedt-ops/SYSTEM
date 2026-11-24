extends Node3D
class_name SYSTEMHunterCandidateCrowd

const TOTAL_CANDIDATES := 500
const FIRST_CANDIDATE_NUMBER := 2001
const GRID_COLUMNS := 18
const CROWD_WAVE_INTERVAL := 2.8
const ARCHETYPES := ["المراقب", "المستكشف", "السريع", "الحذر", "المثابر"]

var candidate_records: Array[Node3D] = []
var candidate_lookup: Dictionary = {}
var body_instances: MultiMeshInstance3D
var head_instances: MultiMeshInstance3D
var rng := RandomNumberGenerator.new()
var movement_clock := 0.0
var decision_wave_count := 0
var total_decision_count := 0
var cooperation_event_count := 0
var mistake_event_count := 0

func _ready() -> void:
	name = "HunterCandidateCrowd"
	rng.seed = 20261124
	_build_crowd()

func _build_crowd() -> void:
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.28
	body_mesh.height = 1.55
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38

	var body_material := StandardMaterial3D.new()
	body_material.vertex_color_use_as_albedo = true
	body_material.roughness = 0.86
	var head_material := StandardMaterial3D.new()
	head_material.vertex_color_use_as_albedo = true
	head_material.roughness = 0.72

	var body_multi := MultiMesh.new()
	body_multi.transform_format = MultiMesh.TRANSFORM_3D
	body_multi.use_colors = true
	body_multi.mesh = body_mesh
	body_multi.instance_count = TOTAL_CANDIDATES
	body_instances = MultiMeshInstance3D.new()
	body_instances.name = "CandidateBodies500"
	body_instances.multimesh = body_multi
	body_instances.material_override = body_material
	add_child(body_instances)

	var head_multi := MultiMesh.new()
	head_multi.transform_format = MultiMesh.TRANSFORM_3D
	head_multi.use_colors = true
	head_multi.mesh = head_mesh
	head_multi.instance_count = TOTAL_CANDIDATES
	head_instances = MultiMeshInstance3D.new()
	head_instances.name = "CandidateHeads500"
	head_instances.multimesh = head_multi
	head_instances.material_override = head_material
	add_child(head_instances)

	for index in range(TOTAL_CANDIDATES):
		var column := index % GRID_COLUMNS
		var row := int(index / GRID_COLUMNS)
		var x := -11.2 + float(column) * 1.2
		if column >= 9:
			x += 2.8
		var z := -10.0 + float(row) * 1.6
		var local_position := Vector3(x, 0.0, z)
		var candidate_number := FIRST_CANDIDATE_NUMBER + index
		var record := Node3D.new()
		record.name = "HunterCandidate_%04d" % candidate_number
		record.position = local_position
		record.set_meta("system_exam_competitor", true)
		record.set_meta("system_candidate_number", candidate_number)
		record.set_meta("system_candidate_status", "registered")
		record.set_meta("system_competitor_archetype", ARCHETYPES[index % ARCHETYPES.size()])
		record.set_meta("system_competitor_individual_record", true)
		record.set_meta("system_competitor_skill", 0.32 + fposmod(float(index) * 0.173, 0.66))
		record.set_meta("system_competitor_cooperation", fposmod(float(index) * 0.311, 1.0))
		record.set_meta("system_competitor_error_rate", 0.025 + fposmod(float(index) * 0.071, 0.12))
		record.set_meta("system_candidate_decision_count", 0)
		record.set_meta("system_candidate_mistake_count", 0)
		record.set_meta("system_candidate_cooperation_count", 0)
		record.set_meta("system_candidate_activity", "waiting")
		record.set_meta("system_candidate_target", local_position)
		add_child(record)
		candidate_records.append(record)
		candidate_lookup[candidate_number] = record

		var hue := fposmod(float(index) * 0.61803398875, 1.0)
		var tint := Color.from_hsv(hue, 0.28, 0.76, 1.0)
		body_multi.set_instance_transform(index, Transform3D(Basis(), local_position + Vector3(0.0, 0.78, 0.0)))
		body_multi.set_instance_color(index, tint)
		head_multi.set_instance_transform(index, Transform3D(Basis(), local_position + Vector3(0.0, 1.62, 0.0)))
		head_multi.set_instance_color(index, tint.lightened(0.16))

	set_meta("system_candidate_count", candidate_records.size())
	set_meta("system_candidate_population_is_individually_tracked", true)
	set_meta("system_candidate_population_rendering", "shared_multimesh_with_individual_candidate_records")

func _process(delta: float) -> void:
	movement_clock += delta
	if movement_clock >= CROWD_WAVE_INTERVAL:
		movement_clock = 0.0
		_start_staggered_movement_wave()
	for index in range(candidate_records.size()):
		var record := candidate_records[index]
		var target: Vector3 = record.get_meta("system_candidate_target", record.position)
		if record.position.distance_to(target) <= 0.025:
			if str(record.get_meta("system_candidate_status", "")) == "moving":
				record.set_meta("system_candidate_status", "registered")
			continue
		record.position = record.position.move_toward(target, delta * 0.42)
		body_instances.multimesh.set_instance_transform(index, Transform3D(Basis(), record.position + Vector3(0.0, 0.78, 0.0)))
		head_instances.multimesh.set_instance_transform(index, Transform3D(Basis(), record.position + Vector3(0.0, 1.62, 0.0)))

func _start_staggered_movement_wave() -> void:
	decision_wave_count += 1
	var selected_indices: Array[int] = []
	while selected_indices.size() < 18:
		var candidate_index := rng.randi_range(0, candidate_records.size() - 1)
		if not selected_indices.has(candidate_index):
			selected_indices.append(candidate_index)
	for decision_index in range(selected_indices.size()):
		var forced_activity := ""
		if decision_index == 0:
			forced_activity = "cooperating"
		elif decision_index == 1:
			forced_activity = "mistake_recovery"
		_apply_candidate_decision(selected_indices[decision_index], forced_activity)

func _apply_candidate_decision(index: int, forced_activity: String = "") -> void:
	if index < 0 or index >= candidate_records.size():
		return
	var record := candidate_records[index]
	var column := index % GRID_COLUMNS
	var left_side := column < 9
	var min_x := -11.2 if left_side else 1.6
	var max_x := -1.6 if left_side else 12.0
	var skill := float(record.get_meta("system_competitor_skill", 0.5))
	var cooperation := float(record.get_meta("system_competitor_cooperation", 0.5))
	var error_rate := float(record.get_meta("system_competitor_error_rate", 0.05))
	var activity := forced_activity
	if activity.is_empty():
		var decision_roll := rng.randf()
		if decision_roll < error_rate * 2.5:
			activity = "mistake_recovery"
		elif decision_roll < error_rate * 2.5 + cooperation * 0.28:
			activity = "cooperating"
		elif skill > 0.68:
			activity = "scouting"
		elif skill < 0.42:
			activity = "observing"
		else:
			activity = "practicing"

	var target: Vector3 = record.position
	match activity:
		"cooperating":
			var partner_index := _find_candidate_partner(index, left_side)
			if partner_index >= 0:
				var partner := candidate_records[partner_index]
				target = record.position.lerp(partner.position, 0.22)
				target += Vector3(0.12 if left_side else -0.12, 0.0, 0.24)
				record.set_meta("system_candidate_cooperation_count", int(record.get_meta("system_candidate_cooperation_count", 0)) + 1)
				partner.set_meta("system_candidate_cooperation_count", int(partner.get_meta("system_candidate_cooperation_count", 0)) + 1)
				cooperation_event_count += 1
			else:
				target.z += 0.25
		"mistake_recovery":
			target.z -= rng.randf_range(0.55, 0.95)
			record.set_meta("system_candidate_mistake_count", int(record.get_meta("system_candidate_mistake_count", 0)) + 1)
			mistake_event_count += 1
		"scouting":
			target.z += rng.randf_range(0.45, 0.95)
		"observing":
			target.z += rng.randf_range(-0.15, 0.15)
		_:
			target.x += rng.randf_range(-0.30, 0.30)

	record.set_meta("system_candidate_activity", activity)
	record.set_meta("system_candidate_decision_count", int(record.get_meta("system_candidate_decision_count", 0)) + 1)
	record.set_meta("system_candidate_status", "moving")
	record.set_meta("system_candidate_target", Vector3(clampf(target.x, min_x, max_x), 0.0, clampf(target.z, -12.0, 35.0)))
	total_decision_count += 1

func _find_candidate_partner(index: int, left_side: bool) -> int:
	for _attempt in range(16):
		var partner_index := rng.randi_range(0, candidate_records.size() - 1)
		if partner_index == index:
			continue
		if (partner_index % GRID_COLUMNS < 9) == left_side:
			return partner_index
	return -1


func get_candidate_by_number(candidate_number: int) -> Node3D:
	return candidate_lookup.get(candidate_number) as Node3D

func get_crowd_status() -> Dictionary:
	var behavior_profile_count := 0
	var decision_count := 0
	var candidate_mistakes := 0
	var candidate_cooperations := 0
	var activity_counts: Dictionary = {}
	for record in candidate_records:
		if record.has_meta("system_competitor_skill") and record.has_meta("system_competitor_cooperation") and record.has_meta("system_competitor_error_rate"):
			behavior_profile_count += 1
		decision_count += int(record.get_meta("system_candidate_decision_count", 0))
		candidate_mistakes += int(record.get_meta("system_candidate_mistake_count", 0))
		candidate_cooperations += int(record.get_meta("system_candidate_cooperation_count", 0))
		var activity := str(record.get_meta("system_candidate_activity", "waiting"))
		activity_counts[activity] = int(activity_counts.get(activity, 0)) + 1
	return {
		"candidate_count": candidate_records.size(),
		"unique_candidate_numbers": candidate_lookup.size(),
		"body_instances": body_instances.multimesh.instance_count if is_instance_valid(body_instances) and body_instances.multimesh != null else 0,
		"head_instances": head_instances.multimesh.instance_count if is_instance_valid(head_instances) and head_instances.multimesh != null else 0,
		"first_candidate_number": FIRST_CANDIDATE_NUMBER,
		"last_candidate_number": FIRST_CANDIDATE_NUMBER + candidate_records.size() - 1,
		"autonomous_staggered_movement": true,
		"individual_candidate_records": true,
		"behavior_profile_count": behavior_profile_count,
		"decision_wave_count": decision_wave_count,
		"decision_count_total": decision_count,
		"cooperation_events": cooperation_event_count,
		"mistake_events": mistake_event_count,
		"candidate_mistake_count": candidate_mistakes,
		"candidate_cooperation_count": candidate_cooperations,
		"behavior_activity_counts": activity_counts
	}

func get_candidate_behavior(candidate_number: int) -> Dictionary:
	var record := get_candidate_by_number(candidate_number)
	if record == null:
		return {}
	return {
		"candidate_number": candidate_number,
		"archetype": str(record.get_meta("system_competitor_archetype", "")),
		"skill": float(record.get_meta("system_competitor_skill", 0.0)),
		"cooperation": float(record.get_meta("system_competitor_cooperation", 0.0)),
		"error_rate": float(record.get_meta("system_competitor_error_rate", 0.0)),
		"activity": str(record.get_meta("system_candidate_activity", "waiting")),
		"decision_count": int(record.get_meta("system_candidate_decision_count", 0)),
		"mistakes": int(record.get_meta("system_candidate_mistake_count", 0)),
		"cooperation_count": int(record.get_meta("system_candidate_cooperation_count", 0))
	}
