extends Node3D

# SYSTEM WORLD - XSX EXAM WORLD CONTROLLER
# Godot 4.3
# First playable examination route prototype.
# Local identity now; Firebase identity will replace it before launch.

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

var player_id := ""
var player: CharacterBody3D

var exam_active := false
var current_stage: Dictionary = {}

var active_checkpoint: Area3D
var status_label: Label
var progress_label: Label
var exam_button: Button

var stage_started_at := 0.0
var stage_start_position := Vector3.ZERO
var last_player_position := Vector3.ZERO
var distance_travelled := 0.0


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
	status_label.size = Vector2(520, 65)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 1.0, 1.0)
	)
	layer.add_child(status_label)

	progress_label = Label.new()
	progress_label.position = Vector2(22, 192)
	progress_label.size = Vector2(520, 35)
	progress_label.add_theme_font_size_override("font_size", 17)
	progress_label.add_theme_color_override(
		"font_color",
		Color(0.65, 0.9, 1.0)
	)
	layer.add_child(progress_label)

	exam_button = Button.new()
	exam_button.text = "التقدم لاختبار الصيادين"
	exam_button.position = Vector2(22, 235)
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

	# Resume an existing unfinished exam if one exists.
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
	current_stage = stage.duplicate(true)
	exam_active = true

	stage_started_at = Time.get_ticks_msec() / 1000.0
	stage_start_position = player.global_position
	last_player_position = player.global_position
	distance_travelled = 0.0

	_spawn_stage_checkpoint()

	var stage_number := int(
		current_stage.get("stage_number", 1)
	)

	var total_stages := int(
		current_stage.get("total_stages", 8)
	)

	status_label.text = str(
		current_stage.get("name", "مرحلة الاختبار")
	)

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


# ==================================================
# CHECKPOINT CREATION
# ==================================================

func _spawn_stage_checkpoint() -> void:
	_clear_checkpoint()

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


func _clear_checkpoint() -> void:
	if is_instance_valid(active_checkpoint):
		active_checkpoint.queue_free()

	active_checkpoint = null


# ==================================================
# CHECKPOINT VALIDATION
# ==================================================

func _on_checkpoint_body_entered(body: Node3D) -> void:
	if not exam_active:
		return

	if body != player:
		return

	var stage_id := str(current_stage.get("id", ""))

	# The endurance stage requires actual movement.
	if stage_id == "endurance" and distance_travelled < 10.0:
		status_label.text = "اختبار التحمل: واصل الحركة قبل عبور النقطة"
		return

	_complete_current_stage()


func _complete_current_stage() -> void:
	if not exam_active:
		return

	exam_active = false

	var elapsed := (
		Time.get_ticks_msec() / 1000.0
	) - stage_started_at

	var distance_to_checkpoint := player.global_position.distance_to(
		active_checkpoint.global_position
	) if is_instance_valid(active_checkpoint) else 0.0

	# Prototype metrics derived from observed local gameplay.
	var completion_score := 100.0

	var precision_score := clampf(
		100.0 - distance_to_checkpoint * 12.0,
		40.0,
		100.0
	)

	var decision_score := clampf(
		100.0 - elapsed * 0.35,
		40.0,
		100.0
	)

	var survival_score := 100.0

	var evidence := {
		"completion": completion_score,
		"precision": precision_score,
		"decision": decision_score,
		"survival": survival_score
	}

	var stage_id := str(current_stage.get("id", ""))

	var result: Dictionary = XSXExaminer.submit_stage_evidence(
		player_id,
		stage_id,
		evidence
	)

	_clear_checkpoint()

	if not bool(result.get("success", false)):
		exam_active = false
		status_label.text = "تعذر اعتماد المرحلة: " + str(
			result.get("reason", "UNKNOWN")
		)
		exam_button.text = "إعادة المحاولة لاحقاً"
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
