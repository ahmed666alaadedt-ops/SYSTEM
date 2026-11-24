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
var active_stage_id := ""
var stage_objective_progress := 0
var stage_objectives: Array[String] = []
var rival_competition: Node3D

func activate_stage(stage_data: Dictionary, active_player: CharacterBody3D, manager: Node) -> Dictionary:
	exam_manager = manager
	player = active_player
	var requested_stage := str(stage_data.get("id", ""))
	if stage_built:
		return {"success": true, "stage_id": active_stage_id, "resumed": true}
	active_stage_id = requested_stage
	if requested_stage == BAGHDAD_STAGE_ID:
		_build_baghdad_heritage_site()
		stage_built = true
		return {"success": true, "stage_id": BAGHDAD_STAGE_ID, "objectives": ["اقرأ النقوش الثلاثة بالترتيب", "تجنب المسامير الحجرية", "استرجع الأثر الصحيح"]}
	var stage_result := _build_additional_stage(requested_stage)
	if not bool(stage_result.get("success", false)):
		return stage_result
	stage_built = true
	return stage_result

func handle_interaction(target: Node) -> Dictionary:
	if not stage_built or not is_instance_valid(target):
		return {"handled": false}
	var rival_id := str(target.get_meta("system_exam_rival_id", ""))
	if not rival_id.is_empty() and is_instance_valid(rival_competition):
		return rival_competition.call("handle_rival_interaction", rival_id)
	if is_instance_valid(rival_competition) and not bool(rival_competition.call("can_continue_objectives")):
		return {"handled": true, "success": false, "message": "أحد المتسابقين سرق هدفك! استعده منه قبل متابعة الاختبار."}
	var objective_id := str(target.get_meta("system_exam_stage_objective", ""))
	if objective_id.is_empty():
		return {"handled": false}
	if active_stage_id != BAGHDAD_STAGE_ID:
		return _handle_additional_stage_objective(objective_id, target)
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
		if is_instance_valid(rival_competition):
			rival_competition.call("record_player_objective", objective_id)
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
	_spawn_rival_competition(site)

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
	collision.name = "CollisionShape3D"
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


# Six additional physical examination environments, each with its own route and objective chain.
func _build_additional_stage(stage_id: String) -> Dictionary:
	var configs := {
		"baghdad_tunnel_competition": {"title":"مسابقة نفق الصيادين","subtitle":"اجمع أهداف المسار — راقب المنافسين — بلغ بوابة النهاية","objectives":["tunnel_checkpoint_a","tunnel_checkpoint_b","tunnel_finish"],"labels":["علامة الدخول","هدف النفق","بوابة النهاية"],"positions":[Vector3(-13,1,13),Vector3(13,1,29),Vector3(0,1,46)],"material":Color(0.18,0.32,0.42)},
		"cairo_buried_market": {"title":"متاهة السوق المدفون","subtitle":"راقب العلامات — احفظ الموارد — اعثر على المخرج","objectives":["cairo_route_a","cairo_route_b","cairo_exit"],"labels":["علامة القافلة","مخزن الماء","بوابة الخروج"],"positions":[Vector3(-12,1,12),Vector3(12,1,28),Vector3(0,1,46)],"material":Color(0.62,0.39,0.19)},
		"alexandria_lighthouse": {"title":"اختبار المنارة والعاصفة","subtitle":"أصلح الإشارة — أنقذ المتسابق — وجّه الضوء","objectives":["alex_beacon","alex_rescue","alex_lighthouse"],"labels":["مولّد الإشارة","متسابق عالق","عدسة المنارة"],"positions":[Vector3(-13,1,12),Vector3(12,1,29),Vector3(0,1,46)],"material":Color(0.22,0.48,0.62)},
		"paris_catacombs": {"title":"سراديب باريس الصامتة","subtitle":"استمع — حلّل — اعبر دون إثارة الحراس","objectives":["paris_echo_a","paris_echo_b","paris_exit"],"labels":["صدى الجدار الأول","صدى الجدار الثاني","ممر الخروج"],"positions":[Vector3(-13,1,13),Vector3(13,1,29),Vector3(0,1,46)],"material":Color(0.34,0.36,0.40)},
		"babylon_guardian": {"title":"آلية حارس بابل","subtitle":"افهم دوران التروس — عطّل الآلية — استعد الختم","objectives":["babylon_gear_a","babylon_gear_b","babylon_seal"],"labels":["ترس الشمس","ترس القمر","ختم الحارس"],"positions":[Vector3(-13,1,13),Vector3(13,1,29),Vector3(0,1,46)],"material":Color(0.64,0.48,0.20)},
		"tokyo_urban_pursuit": {"title":"مطاردة المدينة المتغيرة","subtitle":"تتبّع الإشارات — احمِ المدنيين — حدّد نقطة الوصول","objectives":["tokyo_trace_a","tokyo_civilian","tokyo_finish"],"labels":["أثر المطارد","مدني يحتاج المساعدة","نقطة الاعتراض"],"positions":[Vector3(-13,1,13),Vector3(13,1,29),Vector3(0,1,46)],"material":Color(0.22,0.48,0.42)},
		"final_survival_route": {"title":"مسار البقاء الأخير","subtitle":"اجمع المؤونة — اعثر على مأوى — بلغ القمة","objectives":["highland_supply","highland_shelter","highland_summit"],"labels":["مؤونة المسار","مأوى الجبل","علامة القمة"],"positions":[Vector3(-13,1,13),Vector3(13,1,29),Vector3(0,1,46)],"material":Color(0.42,0.48,0.38)}
	}
	if not configs.has(stage_id):
		return {"success":false,"reason":"STAGE_ENVIRONMENT_NOT_BUILT","stage_id":stage_id}
	var config: Dictionary = configs[stage_id]
	stage_objectives.clear()
	for objective_value in config["objectives"]:
		stage_objectives.append(str(objective_value))
	stage_objective_progress = 0
	var site := Node3D.new()
	site.name = "ExaminationSite_" + stage_id
	add_child(site)
	site.set_meta("system_exam_stage_id",stage_id)
	site.set_meta("system_exam_environment_status","playable_local_geometry_prototype")
	var base_material := _material(config["material"],0.88)
	var floor_material := _material(Color(0.12,0.14,0.16),0.96)
	_add_box(site,"StageGround",Vector3(0,-0.5,24),Vector3(42,1,58),floor_material,true)
	_add_box(site,"StageNorthBoundary",Vector3(0,3,54),Vector3(42,6,1),base_material,true)
	_add_box(site,"StageWestBoundary",Vector3(-21,3,24),Vector3(1,6,58),base_material,true)
	_add_box(site,"StageEastBoundary",Vector3(21,3,24),Vector3(1,6,58),base_material,true)
	_add_box(site,"StageSouthBoundaryLeft",Vector3(-16,3,-4),Vector3(10,6,1),base_material,true)
	_add_box(site,"StageSouthBoundaryRight",Vector3(16,3,-4),Vector3(10,6,1),base_material,true)
	for i in range(4):
		var obstacle_pos := Vector3(-9.0 + float(i)*6.0,1.0,20.0 + float(i%2)*8.0)
		_add_box(site,"RouteObstacle_%02d"%i,obstacle_pos,Vector3(3.2,2.0,3.2),base_material,true)
	for i in range(3):
		var point: Vector3 = config["positions"][i]
		var label_text: String = config["labels"][i]
		var objective: String = config["objectives"][i]
		_add_box(site,"ObjectiveMarker_%02d"%i,point+Vector3(0,1.1,0),Vector3(2.8,2.2,2.8),base_material,true)
		var label := Label3D.new()
		label.name = "ObjectiveLabel_%02d"%i
		label.text = label_text
		label.font_size = 22
		label.pixel_size = 0.014
		label.position = point+Vector3(0,3.0,0)
		label.modulate = Color(0.94,0.87,0.68)
		site.add_child(label)
		var area := _create_objective_area("ObjectiveInteraction_%02d"%i,objective,label_text,"تفاعل: "+label_text)
		area.position = point
		site.add_child(area)
	var title := Label3D.new()
	title.name = "StageTitle"
	title.text = str(config["title"])+"\n"+str(config["subtitle"])
	title.font_size = 26
	title.pixel_size = 0.013
	title.position = Vector3(0,6,51)
	title.modulate = Color(0.94,0.84,0.62)
	site.add_child(title)
	var light := OmniLight3D.new()
	light.name = "StageRouteLight"
	light.position = Vector3(0,5,24)
	light.light_energy = 1.4
	light.omni_range = 48
	light.light_color = config["material"]
	site.add_child(light)
	_build_stage_examiner(site,base_material)
	_spawn_rival_competition(site)
	return {"success":true,"stage_id":stage_id,"environment":"physical_route_with_collisions","objectives":config["labels"].duplicate()}

func _handle_additional_stage_objective(objective_id: String, target: Node) -> Dictionary:
	if not stage_built or stage_objectives.is_empty():
		return {"handled":true,"success":false,"message":"بيئة المرحلة غير مفعّلة."}
	if objective_id == "examiner_briefing":
		return {"handled":true,"success":true,"message":"راقب المسار، التزم بسلامة الآخرين، وأنجز الأهداف بالترتيب. التسرع قد يضيّع عليك أدلة مهمة."}
	if stage_objective_progress >= stage_objectives.size():
		return {"handled":true,"success":true,"message":"اكتملت أهداف المرحلة بالفعل."}
	var expected := stage_objectives[stage_objective_progress]
	if objective_id != expected:
		return {"handled":true,"success":false,"message":"هذا ليس الهدف التالي. راجع مسار المرحلة قبل التقدم.","progress":stage_objective_progress}
	stage_objective_progress += 1
	if is_instance_valid(rival_competition):
		rival_competition.call("record_player_objective", objective_id)
	var stage_labels := {
		"cairo_buried_market":["تم تحديد علامة القافلة.","حافظت على مورد الماء ووصلت إلى بوابة الخروج."],
		"alexandria_lighthouse":["عادت إشارة المنارة للعمل.","تم إنقاذ المتسابق وتوجيه العدسة."],
		"paris_catacombs":["تم تحليل الصدى الأول.","عبرت المسار الصامت وحددت المخرج."],
		"babylon_guardian":["تحرك ترس الشمس إلى موضعه.","تعطلت الآلية واستعدت ختم الحارس."],
		"tokyo_urban_pursuit":["تم تتبع الأثر الحضري.","ساعدت المدني وحددت نقطة الاعتراض دون إيذائه."],
		"final_survival_route":["جمعت مؤونة الطريق.","وصلت إلى المأوى ثم بلغت علامة القمة."]
	}
	var messages: Array = stage_labels.get(active_stage_id,["تم إنجاز الهدف."])
	feedback_message = str(messages[min(stage_objective_progress-1,messages.size()-1)])
	if stage_objective_progress < stage_objectives.size():
		return {"handled":true,"success":true,"message":feedback_message,"progress":stage_objective_progress,"total":stage_objectives.size()}
	if exam_manager == null:
		return {"handled":true,"success":false,"message":"نظام الاختبار غير متاح."}
	var evidence := "SYSTEM_LOCAL_STAGE_OBJECTIVES:" + active_stage_id + ":" + str(stage_objective_progress)
	var result: Dictionary = exam_manager.call("complete_current_stage",active_stage_id,evidence)
	if bool(result.get("success",false)):
		target.set_meta("system_exam_stage_objective","stage_completed")
		target.set_meta("system_interaction_prompt","اكتملت المرحلة")
		return {"handled":true,"success":true,"stage_completed":true,"message":"اكتملت أهداف المرحلة وتم تسجيل اجتيازها.","next_stage":result.get("next_stage",{})}
	return {"handled":true,"success":false,"message":"تعذر تسجيل المرحلة: "+str(result.get("reason","غير معروف"))}

func _build_stage_examiner(parent: Node3D, uniform_material: Material) -> void:
	var examiner := Node3D.new()
	examiner.name = "StageExaminer"
	examiner.position = Vector3(-17,0,3)
	examiner.set_meta("system_examiner_id","system_examiner_"+active_stage_id)
	parent.add_child(examiner)
	var body := MeshInstance3D.new()
	body.name = "ExaminerBody"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.55
	mesh.height = 2.0
	body.mesh = mesh
	body.position.y = 1.1
	body.material_override = uniform_material
	examiner.add_child(body)
	var nameplate := Label3D.new()
	nameplate.name = "ExaminerNameplate"
	nameplate.text = "مراقب الاختبار"
	nameplate.font_size = 22
	nameplate.pixel_size = 0.014
	nameplate.position.y = 2.8
	examiner.add_child(nameplate)
	var briefing := _create_objective_area("ExaminerBriefingInteraction","examiner_briefing","مراقب الاختبار","استمع إلى تعليمات المرحلة")
	briefing.position.y = 1.0
	examiner.add_child(briefing)


func _spawn_rival_competition(parent: Node3D) -> void:
	if is_instance_valid(rival_competition):
		return
	var rival_script := load("res://scripts/system_hunter_rival_competition.gd")
	if rival_script == null:
		push_warning("SYSTEM Hunter Exam: rival competition module could not be loaded.")
		return
	rival_competition = rival_script.new()
	rival_competition.name = "HunterRivalCompetition"
	parent.add_child(rival_competition)
	rival_competition.call("setup", player, parent)
