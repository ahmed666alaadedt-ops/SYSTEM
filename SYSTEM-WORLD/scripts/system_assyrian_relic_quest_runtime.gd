extends Node3D
class_name SYSTEMAssyrianRelicQuestRuntime

const QUEST_ID := "nineveh_guardians_relic_trial"
const RARE_SKILL_ID := "ashur_guardian_aegis"

var progression: Node
var player: CharacterBody3D
var world_manager: Node
var return_position := Vector3.ZERO
var active := false
var completed := false
var objective_index := 0
var objective_nodes: Array[Area3D] = []
var _status_label: Label3D


func _ready() -> void:
	name = "AssyrianRelicQuestRuntime"
	_build_quest_environment()


func begin_quest(p_progression: Node, p_player: CharacterBody3D, p_world_manager: Node, p_return_position: Vector3) -> Dictionary:
	if completed:
		return {"success": false, "reason": "RELIC_QUEST_ALREADY_COMPLETED", "message": "سبق أن أكملت حراس نينوى. راجع سجل المهارات النادرة."}
	if active:
		return {"success": false, "reason": "RELIC_QUEST_ALREADY_ACTIVE", "message": "مهمتك التاريخية ما زالت جارية."}
	progression = p_progression
	player = p_player
	world_manager = p_world_manager
	return_position = p_return_position
	active = true
	if is_instance_valid(player):
		player.velocity = Vector3.ZERO
		player.global_position = global_position + Vector3(0.0, 2.0, -10.0)
	objective_index = 0
	_refresh_status("ابدأ بقراءة الألواح بالترتيب: الأسد المجنح، دجلة، الختم الملكي.")
	return {"success": true, "quest_id": QUEST_ID, "message": "بدأت مهمة حراس نينوى التاريخية. اتبع الألواح القديمة بالترتيب."}


func _build_quest_environment() -> void:
	var stone := _material(Color(0.28, 0.22, 0.15), 0.96)
	var brass := _material(Color(0.66, 0.43, 0.16), 0.48, 0.62)
	var floor_body := StaticBody3D.new()
	floor_body.name = "AssyrianRelicTrialGround"
	floor_body.position = Vector3(0.0, -0.35, -30.0)
	add_child(floor_body)
	_add_box(floor_body, "AncientStoneFloor", Vector3.ZERO, Vector3(58.0, 0.7, 54.0), stone)
	_add_collision(floor_body, "AncientStoneFloorCollision", Vector3.ZERO, Vector3(58.0, 0.7, 54.0))
	_add_box(self, "AssyrianRelicSanctumLintel", Vector3(0.0, 7.0, -55.0), Vector3(25.0, 1.4, 1.8), brass)
	_add_box(self, "AssyrianRelicSanctumPillarLeft", Vector3(-11.0, 3.5, -55.0), Vector3(1.8, 7.0, 1.8), stone)
	_add_box(self, "AssyrianRelicSanctumPillarRight", Vector3(11.0, 3.5, -55.0), Vector3(1.8, 7.0, 1.8), stone)
	var heading := Label3D.new()
	heading.name = "AssyrianRelicQuestHeading"
	heading.text = "حراس نينوى\nمهمة الأثر النادر"
	heading.font_size = 34
	heading.position = Vector3(0.0, 9.0, -55.0)
	add_child(heading)
	_status_label = Label3D.new()
	_status_label.name = "AssyrianRelicQuestStatus"
	_status_label.text = "المهمة تنتظر تفعيل القطعة الأثرية من سوق التحف."
	_status_label.font_size = 20
	_status_label.position = Vector3(0.0, 5.8, -26.0)
	_status_label.modulate = Color(0.72, 0.88, 1.0)
	add_child(_status_label)
	var objective_data := [
		{"id": "winged_lion", "name": "تمثال الأسد المجنح", "position": Vector3(-13.0, 1.5, -35.0), "color": Color(0.78, 0.61, 0.24)},
		{"id": "tigris", "name": "لوح دجلة", "position": Vector3(0.0, 1.5, -43.0), "color": Color(0.22, 0.54, 0.72)},
		{"id": "royal_seal", "name": "الختم الملكي", "position": Vector3(13.0, 1.5, -35.0), "color": Color(0.72, 0.39, 0.22)}
	]
	for item in objective_data:
		_add_box(self, "RelicCluePedestal_" + str(item["id"]), item["position"], Vector3(3.2, 1.2, 2.6), stone)
		_add_box(self, "RelicClueTablet_" + str(item["id"]), item["position"] + Vector3(0.0, 2.1, 0.0), Vector3(1.5, 2.4, 0.35), brass)
		var label := Label3D.new()
		label.text = str(item["name"])
		label.font_size = 19
		label.position = item["position"] + Vector3(0.0, 3.8, 0.0)
		add_child(label)
		var area := _make_interaction("AssyrianRelicClue_" + str(item["id"]), item["position"] + Vector3(0.0, 1.5, 1.9), "اقرأ " + str(item["name"]))
		area.set_meta("system_assyrian_relic_objective", str(item["id"]))
		add_child(area)
		objective_nodes.append(area)
	var relic_position := Vector3(0.0, 1.7, -50.0)
	_add_cylinder(self, "AssyrianStarTabletRelic", relic_position, 0.9, 1.2, 2.2, brass)
	var relic_label := Label3D.new()
	relic_label.text = "تمثال الأسد المجنح البابلي — الختم الملكي المختوم"
	relic_label.font_size = 20
	relic_label.position = relic_position + Vector3(0.0, 2.8, 0.0)
	add_child(relic_label)
	var relic_area := _make_interaction("RecoverAssyrianRoyalSeal", relic_position + Vector3(0.0, 0.0, 2.1), "استعد تمثال الأسد المجنح البابلي")
	relic_area.set_meta("system_assyrian_relic_objective", "recover_seal")
	add_child(relic_area)
	_add_box(self, "HistoricalReturnGateLeftPillar", Vector3(-3.2, 3.0, -4.0), Vector3(0.8, 6.0, 0.8), brass)
	_add_box(self, "HistoricalReturnGateRightPillar", Vector3(3.2, 3.0, -4.0), Vector3(0.8, 6.0, 0.8), brass)
	_add_box(self, "HistoricalReturnGateLintel", Vector3(0.0, 6.1, -4.0), Vector3(7.2, 0.8, 0.8), brass)


	var hidden_echo_trace := Node3D.new()
	hidden_echo_trace.name = "HiddenAssyrianRoyalTrace"
	hidden_echo_trace.position = Vector3(18.0, 0.2, -39.0)
	hidden_echo_trace.visible = false
	hidden_echo_trace.add_to_group("system_hidden_historical_trace")
	var trace_mesh := MeshInstance3D.new()
	trace_mesh.name = "AssyrianEchoTraceMarker"
	var trace_sphere := SphereMesh.new()
	trace_sphere.radius = 0.7
	trace_sphere.height = 1.4
	trace_mesh.mesh = trace_sphere
	trace_mesh.material_override = _material(Color(0.12, 0.58, 0.88), 0.28, 0.35)
	hidden_echo_trace.add_child(trace_mesh)
	var trace_text := Label3D.new()
	trace_text.text = "أثر مخفي — نقش آشوري ملكي"
	trace_text.font_size = 18
	trace_text.position = Vector3(0.0, 1.8, 0.0)
	hidden_echo_trace.add_child(trace_text)
	add_child(hidden_echo_trace)

	var return_arch := _make_interaction("AssyrianRelicReturnGate", Vector3(0.0, 1.5, -4.0), "ارجع إلى سوق التحف والآثار الغامضة")
	return_arch.set_meta("system_assyrian_relic_return", true)
	add_child(return_arch)


func handle_interaction(target: Node) -> Dictionary:
	if target == null:
		return {"handled": false}
	if target.has_meta("system_assyrian_relic_return"):
		if not completed:
			return {"handled": true, "success": false, "message": "أكمل استعادة الأثر أولاً حتى ينفتح طريق العودة."}
		if world_manager != null and world_manager.has_method("switch_world"):
			world_manager.call("switch_world", 2)
			if is_instance_valid(player):
				player.global_position = return_position
			return {"handled": true, "success": true, "message": "رجعت إلى سوق التحف والآثار الغامضة ومعك سر الأثر."}
	if not target.has_meta("system_assyrian_relic_objective"):
		return {"handled": false}
	if not active:
		return {"handled": true, "success": false, "message": "فعّل المهمة من القطعة الغامضة في السوق أولاً."}
	var objective := str(target.get_meta("system_assyrian_relic_objective"))
	var sequence := ["winged_lion", "tigris", "royal_seal", "recover_seal"]
	if objective_index >= sequence.size():
		return {"handled": true, "success": false, "message": "انتهت أهداف المهمة بالفعل."}
	if objective != sequence[objective_index]:
		_refresh_status("هذا ليس الرمز الصحيح. تذكّر ترتيب الأسد المجنح ثم دجلة ثم الختم الملكي.")
		return {"handled": true, "success": false, "message": "الترتيب غير صحيح. ابدأ بالأسد المجنح ثم دجلة ثم الختم الملكي."}
	objective_index += 1
	if objective == "recover_seal":
		return _complete_quest()
	var next_name: String = ["لوح دجلة", "الختم الملكي", "استعادة الأثر"][objective_index - 1]
	_refresh_status("انكشف الرمز الآشوري. هدفك التالي: " + next_name)
	return {"handled": true, "success": true, "message": "تم تسجيل الرمز القديم. " + next_name}


func _complete_quest() -> Dictionary:
	if progression == null or not progression.has_method("grant_skill_training_permit"):
		objective_index -= 1
		return {"handled": true, "success": false, "message": "تعذر ربط مكافأة المهارة بالتقدم. لم تُستهلك القطعة."}
	var reward: Dictionary = progression.call("grant_skill_training_permit", RARE_SKILL_ID)
	if not bool(reward.get("success", false)) and not (str(reward.get("reason", "")) in ["SKILL_PERMIT_ALREADY_OWNED", "SKILL_ALREADY_LEARNED"]):
		objective_index -= 1
		return {"handled": true, "success": false, "message": "الأثر استُعيد، لكن تصريح المهارة لم يُمنح: " + str(reward.get("reason", "UNKNOWN"))}
	completed = true
	active = false
	_refresh_status("اكتملت المهمة — فُتح تصريح مهارة درع الحارس الآشوري النادرة.")
	return {"handled": true, "success": true, "completed": true, "skill_id": RARE_SKILL_ID, "message": "أكملت حراس نينوى! حصلت على تصريح مهارة نادرة: درع الحارس الآشوري. تحتاج 3 جلسات تدريب لإتقانها."}


func _refresh_status(message: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = message


func _make_interaction(node_name: String, point: Vector3, prompt: String) -> Area3D:
	var area := Area3D.new()
	area.name = node_name
	area.position = point
	area.collision_layer = 1
	area.collision_mask = 0
	area.add_to_group("system_interactable")
	area.set_meta("system_location_id", "assyrian_relic_trial_" + node_name.to_lower())
	area.set_meta("system_interaction_prompt", prompt)
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.8
	shape_node.shape = shape
	area.add_child(shape_node)
	return area


func _material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _add_box(parent: Node3D, node_name: String, point: Vector3, size: Vector3, material: Material = null) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = point
	mesh_node.material_override = material if material != null else _material(Color(0.3, 0.25, 0.18))
	parent.add_child(mesh_node)
	return mesh_node


func _add_cylinder(parent: Node3D, node_name: String, point: Vector3, top_radius: float, bottom_radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh_node.mesh = mesh
	mesh_node.position = point
	mesh_node.material_override = material
	parent.add_child(mesh_node)
	return mesh_node


func _add_collision(parent: Node3D, node_name: String, point: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = point
	parent.add_child(body)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)


func _ready_interaction_shape(area: Area3D) -> void:
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.8
	shape_node.shape = shape
	area.add_child(shape_node)
