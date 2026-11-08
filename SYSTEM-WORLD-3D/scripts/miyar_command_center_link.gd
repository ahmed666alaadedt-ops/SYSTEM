
extends "res://scripts/premium_world_details.gd"

# SYSTEM WORLD - Miyar Command Center Integration
# Godot 4.3

const MiyarPersonalityScript = preload(
	"res://scripts/miyar_personality_controller.gd"
)

var miyar_controller: Node3D


func _ready() -> void:
	super._ready()
	_create_miyar_controller()


func _create_miyar_controller() -> void:
	if is_instance_valid(miyar_controller):
		return

	miyar_controller = MiyarPersonalityScript.new()
	miyar_controller.name = "MiyarPersonalityController"

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


# ==========================================
# MIYAR DIALOGUE CONNECTION
# ==========================================

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
# WORLD SELECTION
# ==========================================

func _on_world_manager_selected(world_id: String) -> void:
	super._on_world_manager_selected(world_id)

	if is_instance_valid(miyar_controller):
		miyar_controller.call("enter_world", world_id)


# ==========================================
# PLAYER INTERACTION
# ==========================================

func make_miyar_follow_player(player: Node3D) -> void:
	if not is_instance_valid(miyar_controller):
		return

	miyar_controller.call("start_following", player)


func stop_miyar_following() -> void:
	if not is_instance_valid(miyar_controller):
		return

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
		miyar_controller.call(
			"say",
			message
		)
