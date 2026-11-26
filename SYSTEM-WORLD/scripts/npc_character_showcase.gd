extends Node3D
class_name SYSTEMNPCCharacterShowcase

const NPC_MODEL_SCRIPT := preload("res://scripts/npc_character_model.gd")

var characters: Array[Node3D] = []
var turning := false
var walking := false
var expression_index := 0
var _status_label: Label

const EXPRESSIONS := ["happy", "sad", "surprised", "angry", "talking", "blink"]

func _ready() -> void:
	_build_environment()
	_build_stage()
	_build_characters()
	_build_hud()
	print("SYSTEM NPC SHOWCASE READY: ", characters.size(), " character models")

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.045, 0.085)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.70, 0.86)
	environment.ambient_light_energy = 0.85
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key_light.light_energy = 1.35
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(0.0, 7.0, 8.0)
	fill_light.light_color = Color(0.45, 0.72, 1.0)
	fill_light.light_energy = 2.0
	fill_light.omni_range = 24.0
	add_child(fill_light)

	var camera := Camera3D.new()
	camera.name = "NPCShowcaseCamera"
	camera.position = Vector3(0.0, 8.4, 19.5)
	camera.fov = 58.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.1, 0.0), Vector3.UP)

func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "ShowcaseFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(22.0, 22.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.055, 0.075, 0.11)
	floor_material.metallic = 0.28
	floor_material.roughness = 0.42
	floor.material_override = floor_material
	floor.position.y = -0.04
	add_child(floor)

	var world_rows := [
		{"id": "modern", "name": "العالم الحديث", "color": Color(0.18, 0.72, 0.92), "z": 5.4},
		{"id": "historical", "name": "العالم التاريخي", "color": Color(0.82, 0.58, 0.28), "z": 1.8},
		{"id": "fantasy", "name": "العالم الخيالي", "color": Color(0.62, 0.42, 0.92), "z": -1.8},
		{"id": "greed_island", "name": "جزيرة الطمع", "color": Color(0.24, 0.78, 0.56), "z": -5.4}
	]
	for row in world_rows:
		var marker := MeshInstance3D.new()
		var ring := CylinderMesh.new()
		ring.top_radius = 0.78
		ring.bottom_radius = 0.78
		ring.height = 0.07
		marker.mesh = ring
		var mat := StandardMaterial3D.new()
		mat.albedo_color = row.color
		mat.emission_enabled = true
		mat.emission = row.color * 0.22
		marker.material_override = mat
		marker.position = Vector3(0.0, 0.015, float(row.z))
		add_child(marker)

		var label := Label3D.new()
		label.text = str(row.name)
		label.font_size = 48
		label.pixel_size = 0.006
		label.modulate = row.color
		label.position = Vector3(0.0, 2.65, float(row.z) - 0.7)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)

func _build_characters() -> void:
	var roster: Array[Dictionary] = [
		{"world_id":"modern","name":"Modern Man","gender":"male","age":29,"skin_tone":"olive","hair_color":"black","eye_color":"brown","face_shape":"sharp","body_type":"athletic","height_type":"tall","hair_style":"fade"},
		{"world_id":"modern","name":"Modern Woman","gender":"female","age":26,"skin_tone":"tan","hair_color":"brown","eye_color":"hazel","face_shape":"soft","body_type":"slim","height_type":"average","hair_style":"long"},
		{"world_id":"modern","name":"Modern Elder","gender":"female","age":68,"age_group":"elder","skin_tone":"fair","hair_color":"gray","eye_color":"blue","face_shape":"round","body_type":"average","height_type":"short","hair_style":"bob"},
		{"world_id":"historical","name":"Historical Man","gender":"male","age":34,"skin_tone":"tan","hair_color":"brown","eye_color":"brown","face_shape":"wide","body_type":"heavy","height_type":"average","hair_style":"slick_back"},
		{"world_id":"historical","name":"Historical Child","gender":"male","age":12,"age_group":"child","skin_tone":"olive","hair_color":"black","eye_color":"brown","face_shape":"round","body_type":"slim","height_type":"short","hair_style":"short"},
		{"world_id":"historical","name":"Historical Elder","gender":"male","age":72,"age_group":"elder","skin_tone":"dark","hair_color":"gray","eye_color":"brown","face_shape":"long","body_type":"average","height_type":"short","hair_style":"short"},
		{"world_id":"fantasy","name":"Fantasy Woman","gender":"female","age":31,"skin_tone":"fair","hair_color":"red","eye_color":"green","face_shape":"heart","body_type":"athletic","height_type":"tall","hair_style":"braided"},
		{"world_id":"fantasy","name":"Fantasy Elder","gender":"male","age":65,"age_group":"elder","skin_tone":"olive","hair_color":"gray","eye_color":"hazel","face_shape":"long","body_type":"heavy","height_type":"average","hair_style":"medium"},
		{"world_id":"fantasy","name":"Fantasy Child","gender":"female","age":10,"age_group":"child","skin_tone":"fair","hair_color":"brown","eye_color":"green","face_shape":"soft","body_type":"slim","height_type":"short","hair_style":"ponytail"},
		{"world_id":"greed_island","name":"Island Man","gender":"male","age":24,"skin_tone":"dark","hair_color":"black","eye_color":"brown","face_shape":"sharp","body_type":"muscular","height_type":"tall","hair_style":"curly"},
		{"world_id":"greed_island","name":"Island Woman","gender":"female","age":28,"skin_tone":"olive","hair_color":"black","eye_color":"gray","face_shape":"wide","body_type":"athletic","height_type":"average","hair_style":"bun"},
		{"world_id":"greed_island","name":"Island Child","gender":"male","age":13,"age_group":"child","skin_tone":"tan","hair_color":"brown","eye_color":"hazel","face_shape":"balanced","body_type":"average","height_type":"short","hair_style":"spiky"}
	]
	var world_z := {"modern":5.4, "historical":1.8, "fantasy":-1.8, "greed_island":-5.4}
	var world_counts := {"modern":0, "historical":0, "fantasy":0, "greed_island":0}
	for index in range(roster.size()):
		var profile: Dictionary = roster[index].duplicate(true)
		profile["job"] = "civilian"
		profile["age_group"] = str(profile.get("age_group", "adult"))
		var world_id := str(profile["world_id"])
		var slot := int(world_counts[world_id])
		world_counts[world_id] = slot + 1

		var character := NPC_MODEL_SCRIPT.new() as Node3D
		character.name = "Showcase_" + str(profile["name"]).replace(" ", "_")
		add_child(character)
		character.call("configure", profile, index + 1)
		character.call("set_activity", "idle")
		character.position = Vector3(-5.0 + float(slot) * 5.0, 0.0, float(world_z[world_id]))
		characters.append(character)

		var name_label := Label3D.new()
		name_label.text = str(profile["name"])
		name_label.font_size = 24
		name_label.pixel_size = 0.004
		name_label.modulate = Color(0.88, 0.92, 1.0)
		name_label.position = character.position + Vector3(0.0, 2.05, 0.0)
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(name_label)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "NPCShowcaseHUD"
	layer.layer = 20
	add_child(layer)

	var root_control := Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root_control)

	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(390.0, 0.0)
	root_control.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title := Label.new()
	title.text = "SYSTEM WORLD | معرض الشخصيات ثلاثي الأبعاد"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	_status_label = Label.new()
	_status_label.text = "12 نموذجاً • أربعة عوالم • ستة نماذج أساسية للعمر والجنس"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status_label)

	var controls := HBoxContainer.new()
	content.add_child(controls)

	var animation_button := Button.new()
	animation_button.text = "تشغيل المشي"
	animation_button.pressed.connect(_toggle_walking)
	controls.add_child(animation_button)

	var expression_button := Button.new()
	expression_button.text = "تغيير التعابير"
	expression_button.pressed.connect(_cycle_expressions)
	controls.add_child(expression_button)

	var turn_button := Button.new()
	turn_button.text = "تدوير الشخصيات"
	turn_button.pressed.connect(_toggle_turning)
	controls.add_child(turn_button)

	var back_button := Button.new()
	back_button.text = "العودة للعبة"
	back_button.pressed.connect(_return_to_game)
	content.add_child(back_button)

func _toggle_walking() -> void:
	walking = not walking
	for character in characters:
		character.call("set_activity", "walk" if walking else "idle")
	if is_instance_valid(_status_label):
		_status_label.text = "حركة المشي قيد العرض" if walking else "الشخصيات بوضع الوقوف والتنفس"

func _cycle_expressions() -> void:
	var expression: String = str(EXPRESSIONS[expression_index % EXPRESSIONS.size()])
	expression_index += 1
	for character in characters:
		character.call("set_facial_expression", expression)
	if is_instance_valid(_status_label):
		_status_label.text = "التعبير المعروض: " + expression

func _toggle_turning() -> void:
	turning = not turning
	if is_instance_valid(_status_label):
		_status_label.text = "تدوير النماذج مفعّل" if turning else "تدوير النماذج متوقف"

func _return_to_game() -> void:
	get_tree().change_scene_to_file("res://MainScene.tscn")

func _process(delta: float) -> void:
	if turning:
		for character in characters:
			character.rotate_y(delta * 0.28)
