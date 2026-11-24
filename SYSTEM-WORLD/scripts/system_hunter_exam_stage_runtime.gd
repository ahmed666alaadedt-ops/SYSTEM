extends Node3D
class_name SYSTEMHunterExamStageRuntime

const BAGHDAD_STAGE_ID := "baghdad_heritage_trial"
const EXPECTED_CLUES: Array[String] = ["eye", "river", "crown"]

var exam_manager: Node
var player: CharacterBody3D
var clue_progress := 0
var artifact_unlocked := false
var stage_built := false
var feedback_message := ""

func activate_stage(stage_data: Dictionary, active_player: CharacterBody3D, manager: Node) -> Dictionary:
	exam_manager = manager
	player = active_player
	var requested_stage := str(stage_data.get("id", ""))
	if requested_stage != BAGHDAD_STAGE_ID:
		return {"success": false, "reason": "STAGE_ENVIRONMENT_NOT_BUILT", "stage_id": requested_stage}
	if stage_built:
		return {"success": true, "stage_id": BAGHDAD_STAGE_ID, "resumed": true}
	_build_baghdad_heritage_site()
	stage_built = true
	return {"success": true, "stage_id": BAGHDAD_STAGE_ID, "objectives": ["اقرأ النقوش الثلاثة بالترتيب", "تجنب المسامير الحجرية", "استرجع الأثر الصحيح"]}

func handle_interaction(target: Node) -> Dictionary:
	if not stage_built or not is_instance_valid(target):
		return {"handled": false}
	var objective_id := str(target.get_meta("system_exam_stage_objective", ""))
	if objective_id.is_empty():
		return {"handled": false}
	if objective_id == "examiner_briefing":
		feedback_message = "الممتحن رائد: لا تبحث عن أسرع طريق فقط. راقب الأرض، اقرأ النقوش بالترتيب، وتجنب الفخاخ. القطعة لا تُفتح بالقوة؛ الدليل الصحيح هو الذي يفتحها."
		return {"handled": true, "success": true, "message": feedback_message, "examiner": "raed"}
	if objective_id.begins_with("inscription_"):
		var clue_id := objective_id.trim_prefix("inscription_")
		if clue_progress >= EXPECTED_CLUES.size():
			return {"handled": true, "success": true, "message": "اكتملت قراءة النقوش. اتجه إلى حجرة الأثر."}
		if clue_id != EXPECTED_CLUES[clue_progress]:
			clue_progress = 0
			feedback_message = "ترتيب خاطئ! أعيد تسلسل النقوش من البداية."
			return {"handled": true, "success": false, "message": feedback_message, "progress": clue_progress}
		clue_progress += 1
		if clue_progress == EXPECTED_CLUES.size():
			artifact_unlocked = true
			var relic := get_node_or_null("BaghdadHeritageSite/ArtifactPedestal/RecoveredArtifact")
			if relic != null:
				relic.visible = true
			var artifact_area := get_node_or_null("BaghdadHeritageSite/ArtifactPedestal/ArtifactInteraction")
			if artifact_area != null:
				artifact_area.set_meta("system_interaction_prompt", "استرجع القطعة الأثرية")
			feedback_message = "اكتمل تفسير النقوش الثلاثة. انفتح قفل حجرة الأثر."
		else:
			feedback_message = "نقش صحيح (%d/3). تابع البحث عن الرمز التالي." % clue_progress
		return {"handled": true, "success": true, "message": feedback_message, "progress": clue_progress}
	if objective_id == "recover_artifact":
		if not artifact_unlocked:
			return {"handled": true, "success": false, "message": "القطعة محمية بقفل قديم. أكمل تفسير النقوش أولاً."}
		if exam_manager == null:
			return {"handled": true, "success": false, "message": "نظام الاختبار غير متاح."}
		var result: Dictionary = exam_manager.call("complete_current_stage", BAGHDAD_STAGE_ID, "LOCAL_BAGHDAD_ARTIFACT_OBJECTIVE_SEQUENCE")
		if bool(result.get("success", false)):
			target.set_meta("system_exam_stage_objective", "artifact_recovered")
			target.set_meta("system_interaction_prompt", "تم استرجاع الأثر")
			return {"handled": true, "success": true, "stage_completed": true, "message": "نجحت في اختبار أثر بغداد. تم تسجيل المرحلة الأولى."}
		return {"handled": true, "success": false, "message": "لم يكتمل تسجيل المرحلة: %s" % str(result.get("reason", "غير معروف"))}
	return {"handled": true, "success": false, "message": "هذا العنصر ليس هدفاً متاحاً حالياً."}

func _build_baghdad_heritage_site() -> void:
	var site := Node3D.new()
	site.name = "BaghdadHeritageSite"
	add_child(site)
	site.set_meta("system_exam_stage_id", BAGHDAD_STAGE_ID)
	site.set_meta("system_exam_stage_number", 1)
	site.set_meta("system_exam_environment_status", "playable_local_geometry_prototype")
	var stone := _material(Color(0.24, 0.22, 0.18), 0.94)
	var dark_stone := _material(Color(0.075, 0.09, 0.10), 0.9)
	var gold := _material(Color(0.68, 0.48, 0.18), 0.62)
	var glow := _material(Color(0.08, 0.48, 0.62), 0.42)
	glow.emission_enabled = true
	glow.emission = Color(0.02, 0.35, 0.55)
	glow.emission_energy_multiplier = 1.1

	_add_box(site, "AncientStoneFloor", Vector3(0.0, -0.5, 20.0), Vector3(36.0, 1.0, 40.0), dark_stone, true)
	_add_box(site, "NorthWall", Vector3(0.0, 4.0, 40.0), Vector3(36.0, 9.0, 1.2), stone, true)
	_add_box(site, "WestWall", Vector3(-18.0, 4.0, 20.0), Vector3(1.2, 9.0, 40.0), stone, true)
	_add_box(site, "EastWall", Vector3(18.0, 4.0, 20.0), Vector3(1.2, 9.0, 40.0), stone, true)
	_add_box(site, "SouthWallLeft", Vector3(-13.0, 4.0, 0.0), Vector3(10.0, 9.0, 1.2), stone, true)
	_add_box(site, "SouthWallRight", Vector3(13.0, 4.0, 0.0), Vector3(10.0, 9.0, 1.2), stone, true)
	for side in [-1.0, 1.0]:
		for row in range(3):
			var pillar_pos := Vector3(side * 14.0, 4.0, 9.0 + float(row) * 12.0)
			_add_box(site, "HeritagePillar_%s_%d" % [str(side), row], pillar_pos, Vector3(1.7, 8.0, 1.7), gold, true)

	_add_inscription(site, "EyeInscription", "inscription_eye", "العين", Vector3(-11.0, 1.6, 13.0), glow)
	_add_inscription(site, "RiverInscription", "inscription_river", "النهر", Vector3(0.0, 1.6, 17.0), glow)
	_add_inscription(site, "CrownInscription", "inscription_crown", "التاج", Vector3(11.0, 1.6, 13.0), glow)

	# Physical spike obstacles leave narrow safe routes along both sides of the chamber.
	for index in range(7):
		var spike := MeshInstance3D.new()
		spike.name = "StoneTrapSpike_%02d" % index
		var spike_mesh := CylinderMesh.new()
		spike_mesh.top_radius = 0.0
		spike_mesh.bottom_radius = 0.9
		spike_mesh.height = 2.6
		spike.mesh = spike_mesh
		spike.position = Vector3(-4.5 + float(index) * 1.5, 0.8, 25.0)
		spike.material_override = gold
		site.add_child(spike)
		var spike_body := StaticBody3D.new()
		spike_body.name = "StoneTrapSpikeCollision_%02d" % index
		spike_body.position = spike.position
		var spike_shape := CollisionShape3D.new()
		var spike_collision := CylinderShape3D.new()
		spike_collision.radius = 0.82
		spike_collision.height = 2.6
		spike_shape.shape = spike_collision
		spike_body.add_child(spike_shape)
		site.add_child(spike_body)
	_add_box(site, "TrapWarningLeft", Vector3(-4.5, 0.025, 20.0), Vector3(10.0, 0.05, 1.0), glow, false)
	_add_box(site, "TrapWarningRight", Vector3(4.5, 0.025, 20.0), Vector3(10.0, 0.05, 1.0), glow, false)

	var pedestal := Node3D.new()
	pedestal.name = "ArtifactPedestal"
	pedestal.position = Vector3(0.0, 0.0, 34.0)
	site.add_child(pedestal)
	_add_box(pedestal, "PedestalBase", Vector3(0.0, 1.0, 0.0), Vector3(5.0, 2.0, 4.0), gold, true)
	_add_box(pedestal, "PedestalTop", Vector3(0.0, 2.2, 0.0), Vector3(3.6, 0.4, 3.0), stone, true)
	var artifact := MeshInstance3D.new()
	artifact.name = "RecoveredArtifact"
	var artifact_mesh := PrismMesh.new()
	artifact_mesh.size = Vector3(1.6, 2.0, 0.7)
	artifact.mesh = artifact_mesh
	artifact.position = Vector3(0.0, 3.6, 0.0)
	artifact.material_override = glow
	artifact.visible = false
	pedestal.add_child(artifact)
	var artifact_area := _create_objective_area("ArtifactInteraction", "recover_artifact", "قطعة أثرية رافدينية", "افحص قفل القطعة الأثرية")
	artifact_area.position = Vector3(0.0, 2.8, 0.0)
	pedestal.add_child(artifact_area)

	var title := Label3D.new()
	title.name = "StageTitle"
	title.text = "اختبار الأثر الرافديني\nاستكشف — فسّر — استرجع"
	title.font_size = 30
	title.pixel_size = 0.012
	title.position = Vector3(0.0, 7.0, 39.0)
	title.modulate = Color(0.9, 0.82, 0.58)
	site.add_child(title)
	var lantern := OmniLight3D.new()
	lantern.name = "HeritageChamberLight"
	lantern.position = Vector3(0.0, 6.0, 20.0)
	lantern.light_color = Color(0.35, 0.62, 0.78)
	lantern.light_energy = 1.8
	lantern.omni_range = 42.0
	site.add_child(lantern)
	_build_original_examiner(site, gold, glow)

func _build_original_examiner(parent: Node3D, uniform_material: Material, signal_material: Material) -> void:
	# Original SYSTEM examiner: a quiet rules-focused proctor, not an anime character recreation.
	var examiner := Node3D.new()
	examiner.name = "ExaminerRaed"
	examiner.position = Vector3(-13.0, 0.0, 4.0)
	examiner.set_meta("system_examiner_id", "baghdad_examiner_raed")
	parent.add_child(examiner)
	var body := MeshInstance3D.new()
	body.name = "ExaminerUniform"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.62
	body_mesh.height = 2.2
	body.mesh = body_mesh
	body.position.y = 1.25
	body.material_override = uniform_material
	examiner.add_child(body)
	var head := MeshInstance3D.new()
	head.name = "ExaminerHead"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.42
	head_mesh.height = 0.84
	head.mesh = head_mesh
	head.position.y = 2.72
	head.material_override = signal_material
	examiner.add_child(head)
	var title := Label3D.new()
	title.name = "ExaminerNameplate"
	title.text = "الممتحن رائد\nمراقب المرحلة الأولى"
	title.font_size = 24
	title.pixel_size = 0.012
	title.position = Vector3(0.0, 3.65, 0.0)
	title.modulate = Color(0.88, 0.91, 0.84)
	examiner.add_child(title)
	var briefing := _create_objective_area("ExaminerBriefingInteraction", "examiner_briefing", "الممتحن رائد", "تحدث مع ممتحن المرحلة")
	briefing.position = Vector3(0.0, 1.3, 0.0)
	examiner.add_child(briefing)

func _add_inscription(parent: Node3D, node_name: String, objective_id: String, label_text: String, local_position: Vector3, material: Material) -> void:
	var plaque := Node3D.new()
	plaque.name = node_name
	plaque.position = local_position
	parent.add_child(plaque)
	_add_box(plaque, "CarvedStoneTablet", Vector3.ZERO, Vector3(3.2, 2.8, 0.65), material, true)
	var glyph := Label3D.new()
	glyph.name = "AncientGlyph"
	glyph.text = label_text
	glyph.font_size = 34
	glyph.pixel_size = 0.012
	glyph.position = Vector3(0.0, 0.0, -0.38)
	glyph.modulate = Color(0.94, 0.86, 0.63)
	plaque.add_child(glyph)
	var area := _create_objective_area("InscriptionInteraction", objective_id, "نقش حجري", "افحص النقش: " + label_text)
	plaque.add_child(area)

func _create_objective_area(node_name: String, objective_id: String, display_name: String, prompt: String) -> Area3D:
	var area := Area3D.new()
	area.name = node_name
	area.add_to_group("system_interactable")
	area.set_meta("system_exam_stage_objective", objective_id)
	area.set_meta("system_display_name", display_name)
	area.set_meta("system_interaction_prompt", prompt)
	area.collision_layer = 1
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.2
	shape.shape = sphere
	area.add_child(shape)
	return area

func _add_box(parent: Node3D, node_name: String, local_position: Vector3, dimensions: Vector3, material: Material, with_collision: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	if not with_collision:
		return
	var body := StaticBody3D.new()
	body.name = node_name + "Body"
	body.position = local_position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
