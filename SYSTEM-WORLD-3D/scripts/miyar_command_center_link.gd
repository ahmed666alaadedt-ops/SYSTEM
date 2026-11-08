extends "res://scripts/premium_world_details.gd"

# SYSTEM WORLD - ASSISTANT SELECTION INTEGRATION
# Godot 4.3

const MiyarCharacterScene = preload(
	"res://scenes/miyar_character.tscn"
)
const AdamCharacterScene = preload(
	"res://scenes/adam_character.tscn"
)
const WardrobeManagerScript = preload(
	"res://scripts/system_wardrobe_manager.gd"
)
const AssistantManagerScript = preload(
	"res://scripts/assistant_selection_manager.gd"
)

var miyar_controller: Node3D
var adam_controller: Node3D
var wardrobe_manager: Node
var assistant_manager: Node

var miyar_button: Button
var adam_button: Button


func _ready() -> void:
	super._ready()

	_create_wardrobe_manager()
	_create_assistant_manager()
	_create_miyar_character()
	_create_adam_character()

	assistant_manager.call(
		"register_assistants",
		miyar_controller,
		adam_controller
	)

	_create_assistant_selection_ui()
	_update_active_assistant_world()


# ==========================================
# MANAGERS
# ==========================================

func _create_wardrobe_manager() -> void:
	wardrobe_manager = WardrobeManagerScript.new()
	wardrobe_manager.name = "WardrobeManager"
	add_child(wardrobe_manager)


func _create_assistant_manager() -> void:
	assistant_manager = AssistantManagerScript.new()
	assistant_manager.name = "AssistantSelectionManager"
	add_child(assistant_manager)

	assistant_manager.connect(
		"assistant_changed",
		_on_assistant_changed
	)

	assistant_manager.connect(
		"selection_failed",
		_on_assistant_selection_failed
	)


# ==========================================
# MIYAR
# ==========================================

func _create_miyar_character() -> void:
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

	wardrobe_manager.call(
		"register_miyar",
		miyar_controller
	)


func _on_miyar_dialogue_started(message: String) -> void:
	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = "ميار: " + message

	await get_tree().create_timer(
		clampf(float(message.length()) / 12.0, 2.5, 12.0)
	).timeout

	if not is_instance_valid(miyar_controller):
		return

	if str(miyar_controller.get("current_dialogue")) == message:
		miyar_controller.call("finish_speaking")


func _on_miyar_emotion_changed(emotion: String) -> void:
	if not is_instance_valid(premium_status):
		return

	premium_status.text = "حالة ميار: " + emotion


# ==========================================
# ADAM
# ==========================================

func _create_adam_character() -> void:
	adam_controller = AdamCharacterScene.instantiate()
	adam_controller.name = "AdamCharacter"
	adam_controller.position = Vector3(1.5, 0.0, 0.0)
	adam_controller.visible = false
	add_child(adam_controller)

	adam_controller.connect(
		"dialogue_started",
		_on_adam_dialogue_started
	)

	adam_controller.connect(
		"emotion_changed",
		_on_adam_emotion_changed
	)

	wardrobe_manager.call(
		"register_adam",
		adam_controller
	)


func _on_adam_dialogue_started(message: String) -> void:
	if is_instance_valid(premium_dialogue):
		premium_dialogue.text = "آدم: " + message

	await get_tree().create_timer(
		clampf(float(message.length()) / 12.0, 2.5, 12.0)
	).timeout

	if not is_instance_valid(adam_controller):
		return

	if str(adam_controller.get("current_dialogue")) == message:
		adam_controller.call("finish_speaking")


func _on_adam_emotion_changed(emotion: String) -> void:
	if is_instance_valid(premium_status):
		premium_status.text = "حالة آدم: " + emotion


# ==========================================
# ASSISTANT SELECTION UI
# ==========================================

func _create_assistant_selection_ui() -> void:
	if not is_instance_valid(premium_root):
		return

	var panel := PanelContainer.new()
	panel.name = "AssistantSelectionPanel"

	panel.anchor_left = 0.405
	panel.anchor_right = 0.69
	panel.anchor_top = 0.13
	panel.anchor_bottom = 0.225

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.035, 0.075, 0.94)
	style.border_color = Color(0.0, 0.65, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)

	panel.add_theme_stylebox_override("panel", style)
	premium_root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	miyar_button = Button.new()
	miyar_button.text = "اختيار ميار"
	miyar_button.custom_minimum_size = Vector2(0, 45)
	miyar_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(miyar_button)

	adam_button = Button.new()
	adam_button.text = "اختيار آدم"
	adam_button.custom_minimum_size = Vector2(0, 45)
	adam_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(adam_button)

	miyar_button.pressed.connect(
		_select_miyar
	)

	adam_button.pressed.connect(
		_select_adam
	)

	_update_assistant_buttons()


func _select_miyar() -> void:
	assistant_manager.call(
		"select_assistant",
		"miyar"
	)


func _select_adam() -> void:
	assistant_manager.call(
		"select_assistant",
		"adam"
	)


func _on_assistant_changed(assistant_id: String) -> void:
	_update_assistant_buttons()
	_update_active_assistant_world()

	if assistant_id == "miyar":
		premium_dialogue.text = "تم اختيار ميار. أنا هنا لمرافقتك!"
		premium_status.text = "المساعدة النشطة: ميار"
	else:
		premium_dialogue.text = "تم اختيار آدم. أنا هنا لمرافقتك!"
		premium_status.text = "المساعد النشط: آدم"


func _on_assistant_selection_failed(reason: String) -> void:
	if is_instance_valid(premium_status):
		premium_status.text = reason


func _update_assistant_buttons() -> void:
	if not is_instance_valid(assistant_manager):
		return

	var selected := str(
		assistant_manager.call("get_selected_assistant")
	)

	if is_instance_valid(miyar_button):
		miyar_button.disabled = selected == "miyar"

	if is_instance_valid(adam_button):
		adam_button.disabled = selected == "adam"


func _update_active_assistant_world() -> void:
	if not is_instance_valid(assistant_manager):
		return

	var active = assistant_manager.call(
		"get_active_assistant"
	)

	if is_instance_valid(active):
		active.call("enter_world", selected_world)


# ==========================================
# WORLD SELECTION
# ==========================================

func _on_world_manager_selected(world_id: String) -> void:
	super._on_world_manager_selected(world_id)

	if is_instance_valid(wardrobe_manager):
		wardrobe_manager.call(
			"change_world",
			world_id
		)

	_update_active_assistant_world()


# ==========================================
# MIYAR INTERACTION
# ==========================================

func make_miyar_follow_player(player: Node3D) -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("start_following", player)


func stop_miyar_following() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("stop_following")


func make_miyar_speak(message: String) -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("say", message)


func make_miyar_happy() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("celebrate")


func make_miyar_laugh() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("laugh")


func make_miyar_shy() -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call("become_shy")


# ==========================================
# ADAM INTERACTION
# ==========================================

func make_adam_follow_player(player: Node3D) -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("start_following", player)


func stop_adam_following() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("stop_following")


func make_adam_speak(message: String) -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("say", message)


func make_adam_happy() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("celebrate")


func make_adam_laugh() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("laugh")
