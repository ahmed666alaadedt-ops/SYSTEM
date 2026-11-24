extends Node3D
class_name SYSTEMHunterExamCrowd

const COMPETITOR_COUNT := 500
const COLUMNS := 25
const ROWS := 20

var competitor_mesh: CapsuleMesh
var competitor_materials: Array[StandardMaterial3D] = []
var crowd_clock := 0.0

func _ready() -> void:
	name = "HunterExaminationCompetitorCrowd"
	set_meta("system_hunter_exam_competitor_count", COMPETITOR_COUNT)
	set_meta("system_hunter_exam_player_counts_as_additional_candidate", true)
	set_meta("system_hunter_exam_total_candidates_with_player", COMPETITOR_COUNT + 1)
	set_meta("system_hunter_exam_crowd_is_visual_npc_population", true)
	_build_shared_assets()
	_spawn_competitors()
	print("SYSTEM HUNTER EXAM: 500 visible NPC competitors assembled around the player.")

func _build_shared_assets() -> void:
	competitor_mesh = CapsuleMesh.new()
	competitor_mesh.radius = 0.27
	competitor_mesh.height = 1.72
	for index in range(8):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(float(index) / 8.0, 0.42, 0.72)
		material.roughness = 0.78
		competitor_materials.append(material)

func _spawn_competitors() -> void:
	for index in range(COMPETITOR_COUNT):
		var column := index % COLUMNS
		var row := index / COLUMNS
		var competitor := Node3D.new()
		competitor.name = "HunterExamCompetitor_%03d" % (index + 1)
		competitor.add_to_group("system_hunter_exam_competitor")
		competitor.set_meta("system_exam_candidate_number", index + 1)
		competitor.set_meta("system_exam_candidate_state", "active")
		competitor.set_meta("system_exam_competitor_is_npc", true)
		competitor.set_meta("system_exam_competitor_base_position", Vector3((float(column) - 12.0) * 1.02, 0.0, 3.0 + float(row) * 1.42))
		competitor.set_meta("system_exam_competitor_motion_phase", float(index) * 0.173)
		competitor.position = competitor.get_meta("system_exam_competitor_base_position")
		var body := MeshInstance3D.new()
		body.name = "CompetitorBody"
		body.mesh = competitor_mesh
		body.material_override = competitor_materials[index % competitor_materials.size()]
		body.position.y = 0.88
		competitor.add_child(body)
		if index % 25 == 0:
			var label := Label3D.new()
			label.name = "CandidateNumber"
			label.text = "C-%03d" % (index + 1)
			label.position.y = 2.0
			label.font_size = 12
			label.pixel_size = 0.009
			label.modulate = Color(0.82, 0.91, 1.0)
			competitor.add_child(label)
		add_child(competitor)

func _process(delta: float) -> void:
	crowd_clock += delta
	if crowd_clock < 0.12:
		return
	crowd_clock = 0.0
	for competitor in get_children():
		if not competitor is Node3D:
			continue
		var base: Vector3 = competitor.get_meta("system_exam_competitor_base_position", Vector3.ZERO)
		var phase := float(competitor.get_meta("system_exam_competitor_motion_phase", 0.0))
		var sway := sin(float(Time.get_ticks_msec()) * 0.0012 + phase) * 0.12
		competitor.position.x = base.x + sway
		competitor.rotation.y = sin(float(Time.get_ticks_msec()) * 0.0008 + phase) * 0.08
