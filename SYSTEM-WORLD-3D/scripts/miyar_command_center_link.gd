extends "res://scripts/premium_world_details.gd"

# SYSTEM WORLD - DUAL ASSISTANT INTEGRATION
# Godot 4.3

const MiyarCharacterScene = preload(
	"res://scenes/miyar_character.tscn"
)

const AdamCharacterScene = preload(
	"res://scenes/adam_character.tscn"
)

var miyar_controller: Node3D
var adam_controller: Node3D


func _ready() -> void:
	super._ready()
	_create_miyar_character()
	_create_adam_character()


# ==========================================
# MIYAR
# ==========================================

func _create_miyar_character() -> void:
	if is_instance_valid(miyar_controller):
		return

	miyar_controller = MiyarCharacterScene.instantiate()
	miyar_controller.name = "MiyarCharacter"

	add_child(miyar_controller)

	miyar_controller.connect(
		"dialogue_started",
		_on_miyar_dialogue_started
	)

	miyar_controller.connect(
		"emotion_changed",
		_on_miyar_emotion_changed
	)

	miyar_controller.call("enter_world", selected_world)


func _on_miyar_dialogue_started(message: String) -> void:
	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = message

	var display_time := clampf(
		float(message.length()) / 12.0,
		2.5,
		12.0
	)

	await get_tree().create_timer(display_time).timeout

	if not is_instance_valid(miyar_controller):
		return

	if str(miyar_controller.get("current_dialogue")) == message:
		miyar_controller.call("finish_speaking")


func _on_miyar_emotion_changed(emotion: String) -> void:
	if not is_instance_valid(premium_status):
		return

	var emotion_names := {
		"neutral": "طبيعية",
		"happy": "سعيدة",
		"laughing": "تضحك",
		"shy": "خجولة",
		"excited": "متحمسة",
		"concerned": "قلقة",
		"serious": "جادة",
		"surprised": "متفاجئة",
		"thinking": "تفكر"
	}

	premium_status.text = (
		"حالة ميار: " +
		str(emotion_names.get(emotion, emotion))
	)


# ==========================================
# ADAM
# ==========================================

func _create_adam_character() -> void:
	if is_instance_valid(adam_controller):
		return

	adam_controller = AdamCharacterScene.instantiate()
	adam_controller.name = "AdamCharacter"

	# Keep Adam available but hidden until selected.
	adam_controller.visible = false
	adam_controller.position = Vector3(1.5, 0.0, 0.0)

	add_child(adam_controller)

	adam_controller.connect(
		"dialogue_started",
		_on_adam_dialogue_started
	)

	adam_controller.connect(
		"emotion_changed",
		_on_adam_emotion_changed
	)


func _on_adam_dialogue_started(message: String) -> void:
	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = "آدم: " + message

	var display_time := clampf(
		float(message.length()) / 12.0,
		2.5,
		12.0
	)

	await get_tree().create_timer(display_time).timeout

	if not is_instance_valid(adam_controller):
		return

	if str(adam_controller.get("current_dialogue")) == message:
		adam_controller.call("finish_speaking")


func _on_adam_emotion_changed(emotion: String) -> void:
	if not is_instance_valid(premium_status):
		return

	premium_status.text = "حالة آدم: " + emotion


func show_adam() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.visible = true


func hide_adam() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.visible = false


func make_adam_speak(message: String) -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("say", message)


func make_adam_follow_player(player: Node3D) -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("start_following", player)


func stop_adam_following() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("stop_following")


func make_adam_happy() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("celebrate")


func make_adam_laugh() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("laugh")


func adam_enter_world(world_id: String) -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("enter_world", world_id)


# ==========================================
# WORLD SELECTION
# ==========================================

func _on_world_manager_selected(world_id: String) -> void:
	super._on_world_manager_selected(world_id)

	if is_instance_valid(miyar_controller):
		miyar_controller.call("enter_world", world_id)

	if is_instance_valid(adam_controller):
		if adam_controller.visible:
			adam_controller.call("enter_world", world_id)


# ==========================================
# MIYAR PLAYER INTERACTION
# ==========================================

func make_miyar_follow_player(player: Node3D) -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("start_following", player)


func stop_miyar_following() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("stop_following")


func make_miyar_laugh() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("laugh")


func make_miyar_shy() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("become_shy")


func make_miyar_happy() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("celebrate")


func make_miyar_speak(message: String) -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("say", message)
