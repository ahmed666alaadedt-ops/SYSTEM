extends Node3D
class_name SYSTEMHunterExamSecretEntrance

const SAVE_PATH := "user://system_hunter_exam.cfg"
const CLUE_SEQUENCE: Array[String] = ["eye", "river", "crown"]

var player: CharacterBody3D
var exam_manager: Node
var room_radius := 30.0
var clue_progress := 0
var riddle_solved := false
var door_unlocked := false
var descent_in_progress := false
var door_panel: MeshInstance3D
var door_collision: CollisionShape3D
var elevator_platform: Node3D
var descent_destination := Vector3.ZERO

func setup(active_player: CharacterBody3D, radius: float = 30.0) -> void:
	player = active_player
	room_radius = radius
	exam_manager = get_tree().root.find_child("HunterExamManager", true, false)
	_load_riddle_state()
	_build_secret_entrance()
	if player != null:
		player.set_meta("system_hunter_exam_riddle_solved", riddle_solved)
	if riddle_solved and _is_candidate_registered():
		_reveal_secret_door(false)

func _build_secret_entrance() -> void:
	if get_node_or_null("ClueEye") != null:
		return
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.16, 0.19, 0.20)
	stone.roughness = 0.92
	stone.metallic = 0.08
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.045, 0.22, 0.29)
	trim.emission_enabled = true
	trim.emission = Color(0.02, 0.22, 0.31)
	trim.emission_energy_multiplier = 0.45

	_create_clue_tablet("eye", "العين", Vector3(-room_radius * 0.58, 0.0, 0.0), stone, trim)
	_create_clue_tablet("river", "النهر", Vector3(0.0, 0.0, room_radius * 0.58), stone, trim)
	_create_clue_tablet("crown", "التاج", Vector3(room_radius * 0.58, 0.0, 0.0), stone, trim)

	var door_z := -room_radius * 0.73
	var door_root := Node3D.new()
	door_root.name = "OrdinaryFoundationMasonry"
	door_root.position = Vector3(0.0, 0.0, door_z)
	add_child(door_root)
	door_panel = MeshInstance3D.new()
	door_panel.name = "ConcealedStoneSlab"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(4.8, 5.4, 0.65)
	door_panel.mesh = panel_mesh
	door_panel.position = Vector3(0.0, 2.7, 0.0)
	door_panel.material_override = stone
	door_root.add_child(door_panel)

	var door_body := StaticBody3D.new()
	door_body.name = "ConcealedDoorCollision"
	door_body.collision_layer = 1
	door_body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "DoorCollisionShape"
	var collision_box := BoxShape3D.new()
	collision_box.size = Vector3(4.8, 5.4, 0.75)
	collision.shape = collision_box
	collision.position = Vector3(0.0, 2.7, 0.0)
	door_body.add_child(collision)
	door_root.add_child(door_body)
	door_collision = collision

	var door_area := Area3D.new()
	door_area.name = "SecretDoorInteraction"
	door_area.add_to_group("system_interactable")
	door_area.set_meta("system_hunter_exam_secret_interaction", true)
	door_area.set_meta("system_hunter_exam_secret_door", true)
	door_area.set_meta("system_interaction_prompt", "افحص لوح الحجر العادي")
	door_area.collision_layer = 1
	door_area.collision_mask = 0
	door_area.position = Vector3(0.0, 1.2, 1.65)
	var door_shape := CollisionShape3D.new()
	var door_sphere := SphereShape3D.new()
	door_sphere.radius = 2.7
	door_shape.shape = door_sphere
	door_area.add_child(door_shape)
	door_root.add_child(door_area)

	var riddle_hint := Label3D.new()
	riddle_hint.name = "EnvironmentalRiddleHint"
	riddle_hint.text = "ما يرى أولاً، وما يجري ثانياً، وما يتوّج أخيراً"
	riddle_hint.position = Vector3(0.0, 5.9, 1.2)
	riddle_hint.font_size = 18
	riddle_hint.pixel_size = 0.012
	riddle_hint.modulate = Color(0.74, 0.84, 0.86)
	door_root.add_child(riddle_hint)

	var shaft_glow := MeshInstance3D.new()
	shaft_glow.name = "HiddenDescentGlow"
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 2.15
	shaft_mesh.bottom_radius = 2.15
	shaft_mesh.height = 7.0
	shaft_glow.mesh = shaft_mesh
	shaft_glow.position = Vector3(0.0, -3.8, -0.6)
	var shaft_material := StandardMaterial3D.new()
	shaft_material.albedo_color = Color(0.015, 0.045, 0.065, 0.82)
	shaft_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft_material.emission_enabled = true
	shaft_material.emission = Color(0.0, 0.24, 0.38)
	shaft_material.emission_energy_multiplier = 0.8
	shaft_glow.material_override = shaft_material
	shaft_glow.visible = false
	door_root.add_child(shaft_glow)
	door_root.set_meta("system_hidden_descent_shaft", shaft_glow)

func _create_clue_tablet(clue_id: String, title: String, tablet_position: Vector3, stone: Material, trim: Material) -> void:
	var tablet := Node3D.new()
	tablet.name = "Clue" + clue_id.capitalize()
	tablet.position = tablet_position
	add_child(tablet)
	var plinth := MeshInstance3D.new()
	plinth.name = "StoneTablet"
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(2.6, 2.8, 0.48)
	plinth.mesh = plinth_mesh
	plinth.position.y = 1.4
	plinth.material_override = stone
	tablet.add_child(plinth)

	var inscription := Label3D.new()
	inscription.name = "InscriptionSymbol"
	inscription.text = title
	inscription.position = Vector3(0.0, 1.55, 0.28)
	inscription.font_size = 28
	inscription.pixel_size = 0.012
	inscription.modulate = Color(0.82, 0.91, 0.94)
	tablet.add_child(inscription)

	var accent := MeshInstance3D.new()
	accent.name = "ClueAccent"
	var accent_mesh := SphereMesh.new()
	accent_mesh.radius = 0.28
	accent_mesh.height = 0.56
	accent.mesh = accent_mesh
	accent.position = Vector3(0.0, 2.35, 0.3)
	accent.material_override = trim
	tablet.add_child(accent)

	var interaction := Area3D.new()
	interaction.name = "ClueInteraction"
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_hunter_exam_secret_interaction", true)
	interaction.set_meta("system_hunter_exam_clue_id", clue_id)
	interaction.set_meta("system_interaction_prompt", "افحص نقش " + title)
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	interaction.position = Vector3(0.0, 1.25, 0.9)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.4
	shape.shape = sphere
	interaction.add_child(shape)
	tablet.add_child(interaction)

func handle_interaction(target: Node) -> Dictionary:
	if not is_instance_valid(target):
		return {"handled":false,"success":false,"reason":"INVALID_TARGET"}
	if target.has_meta("system_hunter_exam_clue_id"):
		return _handle_clue(str(target.get_meta("system_hunter_exam_clue_id", "")))
	if bool(target.get_meta("system_hunter_exam_secret_door", false)):
		return _handle_secret_door()
	return {"handled":false,"success":false,"reason":"UNKNOWN_SECRET_INTERACTION"}

func _handle_clue(clue_id: String) -> Dictionary:
	if riddle_solved:
		return {"handled":true,"success":true,"riddle_solved":true,"message":"اكتمل تسلسل النقوش الثلاثة بالفعل."}
	if clue_progress < 0 or clue_progress >= CLUE_SEQUENCE.size():
		clue_progress = 0
	var expected := CLUE_SEQUENCE[clue_progress]
	if clue_id != expected:
		clue_progress = 0
		_save_riddle_state()
		return {"handled":true,"success":false,"reason":"RIDDLE_SEQUENCE_RESET","message":"الترتيب غير صحيح. أعِد اكتشاف النقوش من البداية."}
	clue_progress += 1
	if clue_progress >= CLUE_SEQUENCE.size():
		riddle_solved = true
		if player != null:
			player.set_meta("system_hunter_exam_riddle_solved", true)
		_save_riddle_state()
		if _is_candidate_registered():
			return {"handled":true,"success":true,"riddle_solved":true,"message":"اكتمل تسلسل العين والنهر والتاج. افحص لوح الحجر لفتح المدخل."}
		return {"handled":true,"success":true,"riddle_solved":true,"message":"اكتمل تسلسل العين والنهر والتاج. بقي التسجيل الرسمي في برج جمعية الصيادين قبل فتح المدخل."}
	_save_riddle_state()
	return {"handled":true,"success":true,"riddle_progress":clue_progress,"message":"تم تسجيل النقش الصحيح. تابع البحث عن الرمز التالي."}

func _handle_secret_door() -> Dictionary:
	var candidate_registered := _is_candidate_registered()
	var current_overview: Dictionary = exam_manager.call("get_exam_overview") if is_instance_valid(exam_manager) else {}
	print("SYSTEM HUNTER SECRET DOOR CHECK: solved=%s registered=%s candidate=%d manager=%s" % [str(riddle_solved), str(candidate_registered), int(current_overview.get("candidate_number", 0)), str(is_instance_valid(exam_manager))])
	if not riddle_solved:
		return {"handled":true,"success":false,"reason":"HUNTER_TUNNEL_RIDDLE_NOT_SOLVED","message":"لوح الحجر لا يتحرك. افحص رموز العين والنهر والتاج بالترتيب."}
	if not candidate_registered:
		return {"handled":true,"success":false,"reason":"NOT_REGISTERED","message":"حللت اللغز، لكن يجب إكمال التسجيل الرسمي في برج جمعية الصيادين أولاً."}
	if descent_in_progress:
		return {"handled":true,"success":false,"reason":"DESCENT_IN_PROGRESS","message":"المصعد السري ينزل بالفعل."}
	if not door_unlocked:
		_reveal_secret_door(true)
		return {"handled":true,"success":true,"door_revealed":true,"message":"تحرك اللوح الحجري وكشف المصعد السري. تفاعل معه مرة أخرى للنزول."}
	_begin_descent()
	return {"handled":true,"success":true,"descent_started":true,"message":"بدأ النزول السري إلى نفق اختبار الصيادين."}

func _reveal_secret_door(animate: bool) -> void:
	if door_unlocked:
		return
	door_unlocked = true
	if door_collision != null:
		door_collision.disabled = true
	if door_panel != null:
		if animate:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(door_panel, "position:y", door_panel.position.y + 5.5, 1.1)
		else:
			door_panel.position.y += 5.5
	var door_root := get_node_or_null("OrdinaryFoundationMasonry")
	if door_root != null:
		var glow := door_root.get_meta("system_hidden_descent_shaft") as MeshInstance3D
		if glow != null:
			glow.visible = true
	_create_elevator_platform()

func _create_elevator_platform() -> void:
	if is_instance_valid(elevator_platform):
		elevator_platform.show()
		return
	elevator_platform = Node3D.new()
	elevator_platform.name = "HunterSecretDescentElevator"
	elevator_platform.position = Vector3(0.0, -0.25, -room_radius * 0.73 - 1.2)
	add_child(elevator_platform)
	var platform := MeshInstance3D.new()
	platform.name = "ElevatorPlatform"
	var platform_mesh := BoxMesh.new()
	platform_mesh.size = Vector3(4.8, 0.45, 4.8)
	platform.mesh = platform_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.045, 0.18, 0.24)
	material.metallic = 0.68
	material.roughness = 0.32
	material.emission_enabled = true
	material.emission = Color(0.0, 0.28, 0.42)
	material.emission_energy_multiplier = 0.8
	platform.material_override = material
	elevator_platform.add_child(platform)
	var light := OmniLight3D.new()
	light.name = "ElevatorDescentLight"
	light.position.y = 1.0
	light.light_color = Color(0.12, 0.75, 0.95)
	light.light_energy = 1.8
	light.omni_range = 13.0
	elevator_platform.add_child(light)
	elevator_platform.visible = true

func _begin_descent() -> void:
	if not is_instance_valid(player):
		return
	var tunnel_root := get_tree().root.find_child("BaghdadHunterExaminationTunnel", true, false) as Node3D
	if tunnel_root == null:
		return
	descent_destination = tunnel_root.to_global(Vector3(0.0, 1.0, -1.5))
	descent_in_progress = true
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.set_meta("system_hunter_exam_descent_active", true)
	var start_position := player.global_position
	if not is_instance_valid(elevator_platform):
		_create_elevator_platform()
	elevator_platform.global_position = start_position - Vector3(0.0, 1.0, 0.0)
	var middle_player := Vector3(start_position.x, lerpf(start_position.y, descent_destination.y, 0.55), start_position.z)
	var middle_platform := middle_player - Vector3(0.0, 1.0, 0.0)
	var final_platform := descent_destination - Vector3(0.0, 1.0, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(elevator_platform, "global_position", middle_platform, 3.5)
	tween.parallel().tween_property(player, "global_position", middle_player, 3.5)
	tween.tween_property(elevator_platform, "global_position", final_platform, 3.5)
	tween.parallel().tween_property(player, "global_position", descent_destination, 3.5)
	tween.finished.connect(_finish_descent)

func _finish_descent() -> void:
	if is_instance_valid(player):
		player.global_position = descent_destination
		player.velocity = Vector3.ZERO
		player.set_physics_process(true)
		player.set_meta("system_hunter_exam_descent_active", false)
		player.set_meta("system_hunter_exam_escort_active", false)
		player.set_meta("system_inside_hunter_exam_tunnel", true)
		player.set_meta("system_hunter_exam_riddle_solved", true)
	if is_instance_valid(elevator_platform):
		elevator_platform.queue_free()
	elevator_platform = null
	var registration: Dictionary = {}
	if is_instance_valid(exam_manager):
		registration = exam_manager.call("register_candidate_at_tunnel", "local_player")
	if not bool(registration.get("success", false)):
		if is_instance_valid(player):
			player.set_meta("system_inside_hunter_exam_tunnel", false)
		descent_in_progress = false
		push_warning("SYSTEM HUNTER EXAM: candidate serial registration at tunnel arrival failed: %s" % str(registration.get("reason", "unknown")))
		return
	var overview: Dictionary = exam_manager.call("get_exam_overview")
	var candidate_number := int(overview.get("candidate_number", 0))
	if is_instance_valid(player):
		player.set_meta("system_hunter_exam_candidate_number", candidate_number)
	var menu := get_tree().root.find_child("HunterGuildMenu", true, false)
	if menu != null and menu.has_method("set_exam_status"):
		menu.call("set_exam_status", {"success":true,"candidate_number":candidate_number,"stages":7})
	descent_in_progress = false
	print("SYSTEM HUNTER EXAM: hidden restaurant entrance descended into the tunnel; candidate serial %d is active." % candidate_number)

func _is_candidate_registered() -> bool:
	if not is_instance_valid(exam_manager):
		exam_manager = get_tree().root.find_child("HunterExamManager", true, false)
	if not is_instance_valid(exam_manager):
		return false
	var overview: Dictionary = exam_manager.call("get_exam_overview")
	return bool(overview.get("registered", false)) and int(overview.get("candidate_number", 0)) > 0

func _load_riddle_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	clue_progress = clampi(int(config.get_value("hunter_riddle", "clue_progress", 0)), 0, CLUE_SEQUENCE.size())
	riddle_solved = bool(config.get_value("hunter_riddle", "riddle_solved", false))

func _save_riddle_state() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("hunter_riddle", "clue_progress", clue_progress)
	config.set_value("hunter_riddle", "riddle_solved", riddle_solved)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM HUNTER EXAM: secret entrance riddle state could not be saved.")

func get_secret_entrance_status() -> Dictionary:
	return {
		"clue_progress": clue_progress,
		"required_clues": CLUE_SEQUENCE.size(),
		"riddle_solved": riddle_solved,
		"registered": _is_candidate_registered(),
		"door_unlocked": door_unlocked,
		"descent_in_progress": descent_in_progress,
		"clue_sequence": CLUE_SEQUENCE.duplicate()
	}
