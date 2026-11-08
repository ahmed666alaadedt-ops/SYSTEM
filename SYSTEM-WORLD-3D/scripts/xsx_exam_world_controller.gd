
extends Node3D

# SYSTEM WORLD - XSX EXAM WORLD CONTROLLER
# Godot 4.3
# Endurance and survival stage prototype.
# Local identity only; Firebase/server authority comes before launch.

const IDENTITY_PATH := "user://system_local_identity.cfg"

const CHECKPOINT_POSITIONS := [
	Vector3(0, 0.1, -18),
	Vector3(15, 0.1, -30),
	Vector3(30, 0.1, -15),
	Vector3(35, 0.1, 10),
	Vector3(20, 0.1, 30),
	Vector3(-10, 0.1, 35),
	Vector3(-30, 0.1, 15),
	Vector3(-20, 0.1, -20)
]

const ENDURANCE_FINISH_POSITION := Vector3(-18, 0.1, -36)
const ENDURANCE_MIN_DISTANCE := 42.0
const ENDURANCE_REQUIRED_SUPPLIES := 2

const ENDURANCE_SUPPLY_POSITIONS := [
	Vector3(0, 0.4, -2),
	Vector3(10, 0.4, -12),
	Vector3(0, 0.4, -25)
]

const ENDURANCE_HAZARD_POSITIONS := [
	Vector3(7, 0.15, -5),
	Vector3(-8, 0.15, -18),
	Vector3(-12, 0.15, -29)
]

var player_id := ""
var player: CharacterBody3D

var exam_active := false
var current_stage: Dictionary = {}

var active_checkpoint: Area3D
var supply_pickups: Array[Area3D] = []
var hazard_zones: Array[Area3D] = []

var status_label: Label
var progress_label: Label
var exam_button: Button

var stage_started_at := 0.0
var last_player_position := Vector3.ZERO
var distance_travelled := 0.0

var supplies_collected := 0
var hazards_hit := 0
var survival_score := 100.0


func _ready() -> void:
	call_deferred("_initialize_exam_system")


func _initialize_exam_system() -> void:
	var world := get_parent()

	if world == null:
		push_warning("XSX Exam: World parent was not found.")
		return

	player = world.get_node_or_null("MainPlayer") as CharacterBody3D

	if player == null:
		push_warning("XSX Exam: MainPlayer was not found.")
		return

	_load_or_create_local_identity()

	if player_id.is_empty():
		push_error("XSX Exam: Local player identity could not be created.")
		return

	var registration: Dictionary = XSXAssociation.register_player(
		player_id,
		"SYSTEM Player"
	)

	if not bool(registration.get("success", false)):
		push_error("XSX Exam: Player registration failed.")
		return

	_create_exam_interface()

	status_label.text = "XSX جاهزة لاستقبال طلبك"
	progress_label.text = "اختبار الصيادين | 8 مراحل"

	print("XSX Exam: Local player registered: ", player_id)


# ==================================================
# LOCAL PLAYER IDENTITY
# ==================================================

func _load_or_create_local_identity() -> void:
	var config := ConfigFile.new()
	var load_result := config.load(IDENTITY_PATH)

	if load_result == OK:
		player_id = str(
			config.get_value("identity", "player_id", "")
		)

	if not player_id.is_empty():
		return

	randomize()

	player_id = "LOCAL-XSX-%08d" % randi_range(
		10000000,
		99999999
	)

	config.set_value("identity", "player_id", player_id)

	var save_result := config.save(IDENTITY_PATH)

	if save_result != OK:
		player_id = ""
		push_error("XSX Exam: Could not save local identity.")


# ==================================================
# USER INTERFACE
# ==================================================

func _create_exam_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "XSXExamInterface"
	add_child(layer)

	var title := Label.new()
	title.text = "XSX | اختبار الصيادين"
	title.position = Vector2(22, 92)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override(
		"font_color",
		Color(0.35, 0.88, 1.0)
	)
	layer.add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(22, 128)
	status_label.size = Vector2(560, 65)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 1.0, 1.0)
	)
	layer.add_child(status_label)

	progress_label = Label.new()
	progress_label.position = Vector2(22, 192)
	progress_label.size = Vector2(620, 45)
	progress_label.add_theme_font_size_override("font_size", 17)
	progress_label.add_theme_color_override(
		"font_color",
		Color(0.65, 0.9, 1.0)
	)
	layer.add_child(progress_label)

	exam_button = Button.new()
	exam_button.text = "التقدم لاختبار الصيادين"
	exam_button.position = Vector2(22, 245)
	exam_button.size = Vector2(280, 58)
	exam_button.add_theme_font_size_override("font_size", 18)
	exam_button.pressed.connect(_on_exam_button_pressed)
	layer.add_child(exam_button)


# ==================================================
# EXAM APPLICATION AND START
# ==================================================

func _on_exam_button_pressed() -> void:
	if player_id.is_empty():
		status_label.text = "تعذر تحديد هوية اللاعب"
		return

	if exam_active:
		status_label.text = "أكمل المرحلة الحالية أولاً"
		return

	var profile: Dictionary = XSXAssociation.get_hunter_profile(
		player_id
	)

	if profile.is_empty():
		status_label.text = "تعذر تحميل ملف اللاعب"
		return

	if bool(profile.get("license_active", false)):
		status_label.text = "أنت تحمل رخصة صياد XSX بالفعل"
		exam_button.text = "رخصة الصياد مفعلة"
		exam_button.disabled = true
		return

	var saved_stage: Dictionary = XSXExaminer.get_current_stage(
		player_id
	)

	if not saved_stage.is_empty():
		_begin_playable_stage(saved_stage)
		return

	if str(profile.get("membership_status", "")) != "candidate":
		var application: Dictionary = XSXExaminer.apply_for_exam(
			player_id
		)

		if not bool(application.get("success", false)):
			status_label.text = "تعذر تقديم طلب الاختبار"
			return

	var result: Dictionary = XSXExaminer.start_exam(player_id)

	if not bool(result.get("success", false)):
		status_label.text = "تعذر بدء الاختبار: " + str(
			result.get("reason", "UNKNOWN")
		)
		return

	var first_stage: Dictionary = result.get(
		"first_stage",
		{}
	)

	if first_stage.is_empty():
		status_label.text = "لم يتم العثور على المرحلة الأولى"
		return

	_begin_playable_stage(first_stage)


# ==================================================
# PLAYABLE STAGE SETUP
# ==================================================

func _begin_playable_stage(stage: Dictionary) -> void:
	_clear_course_objects()

	current_stage = stage.duplicate(true)
	exam_active = true

	stage_started_at = Time.get_ticks_msec() / 1000.0
	last_player_position = player.global_position
	distance_travelled = 0.0

	supplies_collected = 0
	hazards_hit = 0
	survival_score = 100.0

	var stage_id := str(current_stage.get("id", ""))

	if stage_id == "endurance":
		_spawn_endurance_course()
		status_label.text = "اختبار التحمل والنجاة: اجتز الطريق واجمع المؤن"
	else:
		_spawn_stage_checkpoint()
		status_label.text = str(
			current_stage.get("name", "مرحلة الاختبار")
		)

	var stage_number := int(
		current_stage.get("stage_number", 1)
	)

	var total_stages := int(
		current_stage.get("total_stages", 8)
	)

	if stage_id == "endurance":
		progress_label.text = "اجمع مؤنين على الأقل وتجنب مناطق الخطر"
	else:
		progress_label.text = (
			"المرحلة %d من %d | تحرك نحو العلامة المضيئة"
			% [stage_number, total_stages]
		)

	exam_button.text = "الاختبار جارٍ"
	exam_button.disabled = true


func _process(_delta: float) -> void:
	if not exam_active:
		return

	if not is_instance_valid(player):
		return

	var current_position := player.global_position

	distance_travelled += last_player_position.distance_to(
		current_position
	)

	last_player_position = current_position

	if str(current_stage.get("id", "")) == "endurance":
		var elapsed := (
			Time.get_ticks_msec() / 1000.0
		) - stage_started_at

		progress_label.text = (
			"المسافة: %d / %d م | المؤن: %d / 3 | الأخطار: %d | الوقت: %d ث"
			% [
				int(distance_travelled),
				int(ENDURANCE_MIN_DISTANCE),
				supplies_collected,
				hazards_hit,
				int(elapsed)
			]
		)


# ==================================================
# ENDURANCE AND SURVIVAL COURSE
# ==================================================

func _spawn_endurance_course() -> void:
	_create_finish_checkpoint(
		ENDURANCE_FINISH_POSITION,
		"نهاية اختبار التحمل"
	)

	for i in range(ENDURANCE_SUPPLY_POSITIONS.size()):
		_create_supply_pickup(
			i + 1,
			ENDURANCE_SUPPLY_POSITIONS[i]
		)

	for i in range(ENDURANCE_HAZARD_POSITIONS.size()):
		_create_hazard_zone(
			i + 1,
			ENDURANCE_HAZARD_POSITIONS[i]
		)


func _create_finish_checkpoint(
	finish_position: Vector3,
	label_text: String
) -> void:
	var checkpoint := Area3D.new()
	checkpoint.name = "XSX_Endurance_Finish"
	checkpoint.position = finish_position

	checkpoint.body_entered.connect(
		_on_checkpoint_body_entered
	)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()

	torus.inner_radius = 1.5
	torus.outer_radius = 1.9
	torus.rings = 28
	torus.ring_segments = 14

	ring.mesh = torus
	ring.rotation_degrees.x = 90.0

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.05, 0.75, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.02, 0.55, 1.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	ring.material_override = material
	checkpoint.add_child(ring)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.5
	collision.shape = sphere
	checkpoint.add_child(collision)

	var marker := Label3D.new()
	marker.text = label_text
	marker.position = Vector3(0, 3.0, 0)
	marker.font_size = 42
	marker.modulate = Color(0.55, 0.95, 1.0)
	checkpoint.add_child(marker)

	get_parent().add_child(checkpoint)
	active_checkpoint = checkpoint


func _create_supply_pickup(
	pickup_number: int,
	pickup_position: Vector3
) -> void:
	var pickup := Area3D.new()
	pickup.name = "XSX_Supply_%d" % pickup_number
	pickup.position = pickup_position

	pickup.body_entered.connect(
		_on_supply_body_entered.bind(pickup)
	)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.9, 0.9)

	mesh.mesh = box
	mesh.position.y = 0.7

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.68, 0.12)
	material.emission_enabled = true
	material.emission = Color(0.75, 0.35, 0.03)
	mesh.material_override = material

	pickup.add_child(mesh)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	collision.shape = sphere
	pickup.add_child(collision)

	var marker := Label3D.new()
	marker.text = "SUPPLY"
	marker.position = Vector3(0, 1.8, 0)
	marker.font_size = 28
	marker.modulate = Color(1.0, 0.8, 0.25)
	pickup.add_child(marker)

	get_parent().add_child(pickup)
	supply_pickups.append(pickup)


func _create_hazard_zone(
	hazard_number: int,
	hazard_position: Vector3
) -> void:
	var hazard := Area3D.new()
	hazard.name = "XSX_Hazard_%d" % hazard_number
	hazard.position = hazard_position

	hazard.body_entered.connect(
		_on_hazard_body_entered.bind(hazard)
	)

	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.7
	cylinder.bottom_radius = 1.7
	cylinder.height = 0.18

	mesh.mesh = cylinder

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.75, 0.08, 0.08)
	material.emission_enabled = true
	material.emission = Color(0.8, 0.02, 0.02)
	mesh.material_override = material

	hazard.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.0
	shape.height = 1.8
	collision.shape = shape
	hazard.add_child(collision)

	var marker := Label3D.new()
	marker.text = "DANGER"
	marker.position = Vector3(0, 2.0, 0)
	marker.font_size = 30
	marker.modulate = Color(1.0, 0.25, 0.2)
	hazard.add_child(marker)

	get_parent().add_child(hazard)
	hazard_zones.append(hazard)


func _on_supply_body_entered(
	body: Node3D,
	pickup: Area3D
) -> void:
	if not exam_active or body != player:
		return

	if not is_instance_valid(pickup):
		return

	supplies_collected += 1
	supply_pickups.erase(pickup)
	pickup.queue_free()

	status_label.text = "تم جمع المؤن: %d / 3" % supplies_collected


func _on_hazard_body_entered(
	body: Node3D,
	hazard: Area3D
) -> void:
	if not exam_active or body != player:
		return

	if not is_instance_valid(hazard):
		return

	hazards_hit += 1
	survival_score = maxf(
		25.0,
		100.0 - float(hazards_hit) * 25.0
	)

	hazard_zones.erase(hazard)
	hazard.queue_free()

	status_label.text = (
		"دخلت منطقة خطر! انتبه للطريق. عدد الأخطار: %d"
		% hazards_hit
	)


# ==================================================
# OTHER EXAM STAGE CHECKPOINTS
# ==================================================

func _spawn_stage_checkpoint() -> void:
	_clear_course_objects()

	var stage_number := int(
		current_stage.get("stage_number", 1)
	)

	var position_index := clampi(
		stage_number - 1,
		0,
		CHECKPOINT_POSITIONS.size() - 1
	)

	var checkpoint := Area3D.new()
	checkpoint.name = "XSX_Exam_Checkpoint_%d" % stage_number
	checkpoint.position = CHECKPOINT_POSITIONS[position_index]

	checkpoint.body_entered.connect(
		_on_checkpoint_body_entered
	)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()

	torus.inner_radius = 1.05
	torus.outer_radius = 1.35
	torus.rings = 24
	torus.ring_segments = 12

	ring.mesh = torus
	ring.rotation_degrees.x = 90.0

	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.05, 0.75, 1.0)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.02, 0.55, 1.0)
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	ring.material_override = ring_material
	checkpoint.add_child(ring)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.8
	collision.shape = sphere
	checkpoint.add_child(collision)

	var marker_label := Label3D.new()
	marker_label.text = "XSX  |  %02d" % stage_number
	marker_label.position = Vector3(0, 2.8, 0)
	marker_label.font_size = 48
	marker_label.modulate = Color(0.55, 0.95, 1.0)
	checkpoint.add_child(marker_label)

	get_parent().add_child(checkpoint)
	active_checkpoint = checkpoint


func _clear_course_objects() -> void:
	if is_instance_valid(active_checkpoint):
		active_checkpoint.queue_free()

	active_checkpoint = null

	for pickup in supply_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()

	supply_pickups.clear()

	for hazard in hazard_zones:
		if is_instance_valid(hazard):
			hazard.queue_free()

	hazard_zones.clear()


# ==================================================
# CHECKPOINT VALIDATION
# ==================================================

func _on_checkpoint_body_entered(body: Node3D) -> void:
	if not exam_active:
		return

	if body != player:
		return

	var stage_id := str(current_stage.get("id", ""))

	if stage_id == "endurance":
		if distance_travelled < ENDURANCE_MIN_DISTANCE:
			status_label.text = "واصل الحركة حتى تقطع المسافة المطلوبة"
			return

		if supplies_collected < ENDURANCE_REQUIRED_SUPPLIES:
			status_label.text = "اجمع مؤنين على الأقل قبل الوصول للنهاية"
			return

	_complete_current_stage()


# ==================================================
# STAGE EVALUATION
# ==================================================

func _complete_current_stage() -> void:
	if not exam_active:
		return

	exam_active = false

	var elapsed := (
		Time.get_ticks_msec() / 1000.0
	) - stage_started_at

	var stage_id := str(current_stage.get("id", ""))

	var completion_score := 100.0
	var precision_score := 100.0
	var decision_score := 100.0
	var stage_survival_score := 100.0

	if stage_id == "endurance":
		precision_score = clampf(
			55.0 + float(supplies_collected) * 15.0,
			40.0,
			100.0
		)

		decision_score = clampf(
			100.0 - elapsed * 0.08,
			40.0,
			100.0
		)

		stage_survival_score = survival_score
	else:
		var distance_to_checkpoint := player.global_position.distance_to(
			active_checkpoint.global_position
		) if is_instance_valid(active_checkpoint) else 0.0

		precision_score = clampf(
			100.0 - distance_to_checkpoint * 12.0,
			40.0,
			100.0
		)

		decision_score = clampf(
			100.0 - elapsed * 0.35,
			40.0,
			100.0
		)

	var evidence := {
		"completion": completion_score,
		"precision": precision_score,
		"decision": decision_score,
		"survival": stage_survival_score
	}

	var result: Dictionary = XSXExaminer.submit_stage_evidence(
		player_id,
		stage_id,
		evidence
	)

	_clear_course_objects()

	if not bool(result.get("success", false)):
		status_label.text = "تعذر اعتماد المرحلة: " + str(
			result.get("reason", "UNKNOWN")
		)
		exam_button.text = "إعادة المحاولة"
		exam_button.disabled = false
		return

	if result.has("next_stage"):
		var next_stage: Dictionary = result.get(
			"next_stage",
			{}
		)

		status_label.text = "تم اجتياز المرحلة بنجاح"
		_begin_playable_stage(next_stage)
		return

	_handle_final_exam_result(result)


# ==================================================
# FINAL RESULT
# ==================================================

func _handle_final_exam_result(result: Dictionary) -> void:
	var passed := bool(result.get("passed", false))
	var score := int(result.get("final_score", 0))
	var license_granted := bool(
		result.get("license_granted", false)
	)

	if passed and license_granted:
		status_label.text = "مبروك! حصلت على رخصة صياد XSX"
		progress_label.text = "النتيجة النهائية: %d / 100" % score
		exam_button.text = "رخصة الصياد مفعلة"
		exam_button.disabled = true
	else:
		status_label.text = "لم تجتز الاختبار هذه المرة"
		progress_label.text = "النتيجة النهائية: %d / 100" % score
		exam_button.text = "إغلاق نتيجة الاختبار"
		exam_button.disabled = false

	exam_active = false
	current_stage = {}

	print(
		"XSX Exam completed. Passed: ",
		passed,
		" | Score: ",
		score,
		" | License: ",
		license_granted
	)
