extends Node3D
class_name SYSTEMCompanionManager

## Mounts the two SYSTEM companions in the canonical 3D runtime.
## Their appearance uses the same rigged GLB pipeline as the player and NPCs.

const CharacterModelScript = preload("res://scripts/npc_character_model.gd")

var player: CharacterBody3D
var world_manager: Node
var miyar: Node3D
var adam: Node3D
var miyar_label: Label3D
var adam_label: Label3D
var dialogue_label: Label
var selected_assistant := "miyar"
var _last_world_id := "modern"

const FOLLOW_SPEED := 3.2
const MIYAR_OFFSET := Vector3(-1.25, 0.0, 1.55)
const ADAM_OFFSET := Vector3(1.25, 0.0, 1.85)


func setup(player_node: CharacterBody3D, manager: Node) -> void:
	player = player_node
	world_manager = manager
	_create_companion("miyar")
	_create_companion("adam")
	_create_assistant_interface()
	_update_world_wardrobes()
	_show_welcome("miyar")


func _create_companion(assistant_id: String) -> void:
	var profile := {
		"name": "ميار" if assistant_id == "miyar" else "آدم",
		"gender": "female" if assistant_id == "miyar" else "male",
		"age": 24 if assistant_id == "miyar" else 28,
		"age_group": "adult",
		"body_type": "average" if assistant_id == "miyar" else "athletic",
		"height_type": "average",
		"skin_tone": "olive",
		"hair_style": "long" if assistant_id == "miyar" else "short",
		"hair_color": "black",
		"eye_color": "brown",
		"face_shape": "balanced",
		"job": "civilian",
		"occupation": "civilian",
		"world_id": _last_world_id,
		"is_player_character": false
	}
	var character := CharacterModelScript.new() as Node3D
	character.name = "SYSTEM_Miyar" if assistant_id == "miyar" else "SYSTEM_Adam"
	add_child(character)
	character.call("configure", profile, 1 if assistant_id == "miyar" else 0)
	character.call("set_activity", "idle")
	var name_tag := Label3D.new()
	name_tag.name = "CompanionName"
	name_tag.text = "ميار" if assistant_id == "miyar" else "آدم"
	name_tag.position = Vector3(0.0, 2.25, 0.0)
	name_tag.font_size = 30
	name_tag.outline_size = 6
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.modulate = Color(0.35, 0.9, 1.0) if assistant_id == "miyar" else Color(1.0, 0.78, 0.42)
	character.add_child(name_tag)
	if assistant_id == "miyar":
		miyar = character
		miyar_label = name_tag
	else:
		adam = character
		adam_label = name_tag


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_follow_companion(miyar, MIYAR_OFFSET, delta)
	_follow_companion(adam, ADAM_OFFSET, delta)
	var world_id := _get_world_id()
	if world_id != _last_world_id:
		_last_world_id = world_id
		_update_world_wardrobes()


func _follow_companion(companion: Node3D, offset: Vector3, delta: float) -> void:
	if not is_instance_valid(companion):
		return
	var target := player.global_position + player.global_transform.basis * offset
	target.y = player.global_position.y
	var distance := companion.global_position.distance_to(target)
	companion.global_position = companion.global_position.move_toward(
		target,
		FOLLOW_SPEED * delta
	)
	if distance > 0.55:
		companion.call("set_activity", "walk")
	else:
		companion.call("set_activity", "idle")
	var look_target := player.global_position
	look_target.y = companion.global_position.y
	if companion.global_position.distance_squared_to(look_target) > 0.05:
		companion.look_at(look_target, Vector3.UP)


func _get_world_id() -> String:
	if not is_instance_valid(world_manager):
		return "modern"
	var active_id := int(world_manager.get("active_world"))
	match active_id:
		0:
			return "fantasy"
		1:
			return "historical"
		2:
			return "modern"
		3:
			return "greed_island"
	return "modern"


func _update_world_wardrobes() -> void:
	for pair in [[miyar, "ميار"], [adam, "آدم"]]:
		var character: Node3D = pair[0]
		if not is_instance_valid(character):
			continue
		var profile: Dictionary = character.get("appearance_profile")
		if profile.is_empty():
			continue
		profile["world_id"] = _last_world_id
		character.call("configure", profile, 1 if pair[1] == "ميار" else 0)


func _create_assistant_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SYSTEMCompanionInterface"
	layer.layer = 11
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(390.0, 14.0)
	root.size = Vector2(430.0, 126.0)
	layer.add_child(root)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	var miyar_button := Button.new()
	miyar_button.text = "تحدث مع ميار"
	miyar_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(miyar_button)
	miyar_button.pressed.connect(func() -> void:
		selected_assistant = "miyar"
		_show_welcome("miyar")
	)
	var adam_button := Button.new()
	adam_button.text = "تحدث مع آدم"
	adam_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(adam_button)
	adam_button.pressed.connect(func() -> void:
		selected_assistant = "adam"
		_show_welcome("adam")
	)
	dialogue_label = Label.new()
	dialogue_label.text = "مساعداك يرافقانك في العالم."
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(0.0, 58.0)
	column.add_child(dialogue_label)


func _show_welcome(assistant_id: String) -> void:
	selected_assistant = assistant_id
	if not is_instance_valid(dialogue_label):
		return
	if assistant_id == "miyar":
		dialogue_label.text = "ميار: أهلاً بك! سأرافقك وأشرح لك العوالم والمهام والأنظمة."
	else:
		dialogue_label.text = "آدم: أهلاً بك. سأساعدك في الاستكشاف والاستعداد للتحديات."
