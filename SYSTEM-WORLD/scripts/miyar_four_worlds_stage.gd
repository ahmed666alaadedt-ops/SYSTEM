extends Node3D
class_name MiyarFourWorldsStage

signal world_selected(world_id: String)
signal world_entry_requested(world_id: String)

const CHARACTER_MODEL_SCRIPT = preload("res://scripts/npc_character_model.gd")
const WORLD_DATA := [
	{"id":"modern","title":"العالم الحديث","color":Color(0.12,0.78,0.96),"outfit":"modern","speech":"هذا هو العالم الحديث. مدن واسعة وحياة يومية ومهمات ومواجهات تنتظرنا."},
	{"id":"historical","title":"عالم التاريخ","color":Color(0.92,0.68,0.30),"outfit":"historical","speech":"هنا نكتشف الحضارات القديمة والتاريخ والممالك والأسرار."},
	{"id":"fantasy","title":"العالم الخيالي","color":Color(0.68,0.48,1.0),"outfit":"mythic","speech":"هذا العالم مليء بالسحر والممالك والمخلوقات والقدرات."},
	{"id":"greed_island","title":"جزيرة الطمع","color":Color(0.25,0.86,0.55),"outfit":"greed_island","speech":"وصلنا إلى جزيرة الطمع. كن مستعداً لاكتشاف أسرارها وتحدياتها."}
]

var selected_world_id := "modern"
var miyar: Node3D
var miyar_model: Node
var dialogue_label: Label
var selected_label: Label
var gate_nodes: Dictionary = {}
var is_speaking := false
var speech_elapsed := 0.0
var blink_elapsed := 0.0
var presentation_tween: Tween


func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_floor()
	_build_miyar()
	_build_world_gates()
	_build_interface()
	select_world("modern")
	_say("أهلاً بك! أنا ميار. اختَر واحداً من العوالم الأربعة، وأنا أعرّفك عليه.")


func _process(delta: float) -> void:
	blink_elapsed += delta
	if blink_elapsed >= 3.6:
		blink_elapsed = 0.0
		if is_instance_valid(miyar_model) and miyar_model.has_method("set_facial_expression"):
			miyar_model.call("set_facial_expression", "blink")
			get_tree().create_timer(0.12).timeout.connect(_restore_face)
	if is_speaking:
		speech_elapsed += delta
		if speech_elapsed >= 0.18:
			speech_elapsed = 0.0
			if is_instance_valid(miyar_model) and miyar_model.has_method("set_facial_expression"):
				miyar_model.call("set_facial_expression", "talking" if int(Time.get_ticks_msec() / 180) % 2 == 0 else "happy")


func _restore_face() -> void:
	if not is_speaking and is_instance_valid(miyar_model) and miyar_model.has_method("set_facial_expression"):
		miyar_model.call("set_facial_expression", "happy")


func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.015, 0.035, 0.10)
	sky_material.sky_horizon_color = Color(0.10, 0.20, 0.32)
	sky_material.ground_bottom_color = Color(0.008, 0.012, 0.025)
	sky_material.ground_horizon_color = Color(0.035, 0.075, 0.12)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.70, 0.88)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -28, 0)
	key.light_energy = 1.25
	key.shadow_enabled = true
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.0, 3.4, 2.5)
	fill.light_color = Color(0.30, 0.72, 1.0)
	fill.light_energy = 1.8
	fill.omni_range = 11.0
	add_child(fill)


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "WorldSelectionCamera"
	camera.position = Vector3(0.0, 3.1, 11.8)
	camera.fov = 43.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.35, 0.0), Vector3.UP)
	camera.current = true


func _build_floor() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "WorldSelectionFloor"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(15.0, 9.0)
	floor.mesh = mesh
	floor.position = Vector3(0.0, -0.035, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.018, 0.035, 0.065)
	material.metallic = 0.62
	material.roughness = 0.28
	floor.material_override = material
	add_child(floor)


func _build_miyar() -> void:
	miyar = Node3D.new()
	miyar.name = "Miyar3D"
	miyar.position = Vector3(-3.65, 0.0, 0.25)
	miyar.rotation.y = PI
	add_child(miyar)
	miyar_model = CHARACTER_MODEL_SCRIPT.new()
	miyar_model.name = "MiyarRiggedCharacter"
	miyar.add_child(miyar_model)
	miyar_model.call("configure", {
		"name":"Miyar",
		"gender":"female",
		"age":27,
		"age_group":"adult",
		"body_type":"athletic",
		"height_type":"average",
		"hair_style":"long",
		"hair_color":"black",
		"world_id":"modern",
		"job":"guide",
		"is_player_character":true
	}, 7)
	miyar_model.call("set_activity", "idle")
	miyar_model.call("set_facial_expression", "happy")


func _build_world_gates() -> void:
	var start_x := -1.45
	for index in range(WORLD_DATA.size()):
		var data: Dictionary = WORLD_DATA[index]
		var gate := Node3D.new()
		gate.name = "Gate_" + str(data.id)
		gate.position = Vector3(start_x + float(index) * 1.92, 0.0, -0.8)
		add_child(gate)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.53
		torus.outer_radius = 0.62
		torus.rings = 16
		torus.ring_segments = 64
		ring.mesh = torus
		ring.position.y = 1.72
		ring.rotation.x = deg_to_rad(90.0)
		var ring_material := StandardMaterial3D.new()
		ring_material.albedo_color = data.color
		ring_material.emission_enabled = true
		ring_material.emission = data.color
		ring_material.emission_energy_multiplier = 2.2
		ring_material.metallic = 0.35
		ring.material_override = ring_material
		gate.add_child(ring)
		var core := MeshInstance3D.new()
		var orb := SphereMesh.new()
		orb.radius = 0.43
		orb.height = 0.86
		core.mesh = orb
		core.position.y = 1.72
		var core_material := StandardMaterial3D.new()
		core_material.albedo_color = data.color.darkened(0.68)
		core_material.emission_enabled = true
		core_material.emission = data.color
		core_material.emission_energy_multiplier = 0.75
		core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		core_material.albedo_color.a = 0.28
		core.material_override = core_material
		gate.add_child(core)
		var plinth := MeshInstance3D.new()
		var plinth_mesh := CylinderMesh.new()
		plinth_mesh.top_radius = 0.72
		plinth_mesh.bottom_radius = 0.78
		plinth_mesh.height = 0.16
		plinth.mesh = plinth_mesh
		plinth.position.y = 0.08
		var plinth_material := StandardMaterial3D.new()
		plinth_material.albedo_color = Color(0.035, 0.075, 0.12)
		plinth_material.metallic = 0.8
		plinth_material.roughness = 0.22
		plinth.material_override = plinth_material
		gate.add_child(plinth)
		var title := Label3D.new()
		title.text = str(data.title)
		title.position = Vector3(0.0, 0.72, -0.05)
		title.font_size = 30
		title.outline_size = 7
		title.modulate = Color.WHITE
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		gate.add_child(title)
		gate_nodes[str(data.id)] = gate


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MiyarWorldSelectionHUD"
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var heading := Label.new()
	heading.text = "SYSTEM WORLD  •  العوالم الأربعة"
	heading.position = Vector2(28, 18)
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color(1.0, 0.79, 0.35))
	root.add_child(heading)
	dialogue_label = Label.new()
	dialogue_label.name = "MiyarDialogue"
	dialogue_label.position = Vector2(28, 78)
	dialogue_label.size = Vector2(420, 100)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 18)
	dialogue_label.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	root.add_child(dialogue_label)
	selected_label = Label.new()
	selected_label.position = Vector2(28, 190)
	selected_label.add_theme_font_size_override("font_size", 16)
	selected_label.add_theme_color_override("font_color", Color(0.35, 0.88, 1.0))
	root.add_child(selected_label)
	var button_row := HBoxContainer.new()
	button_row.anchor_left = 0.04
	button_row.anchor_right = 0.96
	button_row.anchor_top = 1.0
	button_row.anchor_bottom = 1.0
	button_row.offset_top = -104
	button_row.offset_bottom = -22
	button_row.add_theme_constant_override("separation", 12)
	root.add_child(button_row)
	for data in WORLD_DATA:
		var button := Button.new()
		button.text = str(data.title)
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_world.bind(str(data.id)))
		button_row.add_child(button)
	var enter_button := Button.new()
	enter_button.text = "دخول العالم المختار"
	enter_button.anchor_left = 0.72
	enter_button.anchor_right = 0.96
	enter_button.anchor_top = 0.0
	enter_button.anchor_bottom = 0.0
	enter_button.offset_top = 190
	enter_button.offset_bottom = 246
	root.add_child(enter_button)
	enter_button.pressed.connect(_request_entry)


func select_world(world_id: String) -> void:
	for data in WORLD_DATA:
		if str(data.id) == world_id:
			selected_world_id = world_id
			selected_label.text = "العالم المختار: " + str(data.title)
			world_selected.emit(world_id)
			if is_instance_valid(miyar_model):
				miyar_model.call("set_outfit", str(data.outfit), 7)
				miyar_model.call("set_facial_expression", "happy")
			_say(str(data.speech))
			_present_gate(world_id)
			return


func _present_gate(world_id: String) -> void:
	if not gate_nodes.has(world_id) or not is_instance_valid(miyar):
		return
	if presentation_tween and presentation_tween.is_running():
		presentation_tween.kill()
	var destination: Vector3 = gate_nodes[world_id].position + Vector3(-0.82, 0.0, 0.55)
	if is_instance_valid(miyar_model):
		miyar_model.call("set_activity", "walk")
	presentation_tween = create_tween()
	presentation_tween.tween_property(miyar, "position", destination, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	presentation_tween.tween_callback(func() -> void:
		if is_instance_valid(miyar_model):
			miyar_model.call("set_activity", "idle")
			miyar_model.call("set_facial_expression", "happy")
	)
	presentation_tween.tween_interval(0.65)
	presentation_tween.tween_property(miyar, "position", Vector3(-3.65, 0.0, 0.25), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _say(message: String) -> void:
	if is_instance_valid(dialogue_label):
		dialogue_label.text = "ميار: " + message
	is_speaking = true
	speech_elapsed = 0.0
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		var voices := DisplayServer.tts_get_voices()
		var voice_id := ""
		for voice in voices:
			if str(voice.get("language", "")).to_lower().begins_with("ar"):
				voice_id = str(voice.get("id", ""))
				break
		DisplayServer.tts_speak(message, voice_id, 50, 1.0, 1.0, 0, true)
		get_tree().create_timer(maxf(2.0, float(message.length()) * 0.075)).timeout.connect(_finish_speaking)
	else:
		_finish_speaking()


func _finish_speaking() -> void:
	is_speaking = false
	if is_instance_valid(miyar_model):
		miyar_model.call("set_facial_expression", "happy")


func _request_entry() -> void:
	world_entry_requested.emit(selected_world_id)
	if not is_instance_valid(SYSTEMAndroidBridge):
		if selected_world_id == "modern":
			get_tree().change_scene_to_file("res://MainScene.tscn")
		return
	if SYSTEMAndroidBridge.request_world_selection_entry(selected_world_id):
		get_tree().change_scene_to_file("res://MainScene.tscn")
