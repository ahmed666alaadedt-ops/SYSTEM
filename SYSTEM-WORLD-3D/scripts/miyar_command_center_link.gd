
extends "res://scripts/premium_world_details.gd"

# SYSTEM WORLD - ADAM & MIYAR COMMAND CENTER
# Godot 4.3
# Landscape interface
# One active assistant at a time.

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

var assistant_panel: PanelContainer
var assistant_name_label: Label
var assistant_description_label: Label
var assistant_status_label: Label

var miyar_button: Button
var adam_button: Button


func _ready() -> void:
	super._ready()

	_create_wardrobe_manager()
	_create_assistant_manager()

	_create_miyar_character()
	_create_adam_character()

	if is_instance_valid(assistant_manager):
		assistant_manager.call(
			"register_assistants",
			miyar_controller,
			adam_controller
		)

	_create_assistant_selection_ui()
	_update_assistant_interface()
	_update_active_assistant_world()


# ==================================================
# MANAGERS
# ==================================================

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


# ==================================================
# MIYAR
# ==================================================

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
	if is_instance_valid(premium_status):
		premium_status.text = "حالة ميار: " + emotion


# ==================================================
# ADAM
# ==================================================

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


# ==================================================
# ASSISTANT SELECTION UI
# ==================================================

func _create_assistant_selection_ui() -> void:
	if not is_instance_valid(premium_root):
		return

	assistant_panel = _panel(
		premium_root,
		Color(0.0, 0.72, 1.0)
	)

	assistant_panel.name = "AssistantSelectionPanel"

	assistant_panel.anchor_left = 0.42
	assistant_panel.anchor_right = 0.82
	assistant_panel.anchor_top = 0.515
	assistant_panel.anchor_bottom = 0.735

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	assistant_panel.add_child(column)

	column.add_child(
		_label(
			"اختر المرافق الخاص بك",
			19,
			Color(0.30, 0.88, 1.0)
		)
	)

	assistant_name_label = _label(
		"ميار",
		21,
		Color(1.0, 0.82, 0.35)
	)
	column.add_child(assistant_name_label)

	assistant_description_label = _label(
		"مساعدتك الذكية ورفيقتك في الرحلة.",
		13
	)
	column.add_child(assistant_description_label)

	var selection_row := HBoxContainer.new()
	selection_row.add_theme_constant_override("separation", 10)
	column.add_child(selection_row)

	miyar_button = _button(
		selection_row,
		"اختيار ميار",
		Color(0.0, 0.75, 1.0),
		Vector2(0, 38)
	)

	adam_button = _button(
		selection_row,
		"اختيار آدم",
		Color(0.85, 0.62, 0.25),
		Vector2(0, 38)
	)

	miyar_button.pressed.connect(_select_miyar)
	adam_button.pressed.connect(_select_adam)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 7)
	column.add_child(action_row)

	var welcome_button := _button(
		action_row,
		"ترحيب",
		Color(0.0, 0.65, 0.9),
		Vector2(0, 32)
	)
	welcome_button.pressed.connect(
		_active_assistant_welcome
	)

	var encouragement_button := _button(
		action_row,
		"تشجيع",
		Color(0.15, 0.75, 0.55),
		Vector2(0, 32)
	)
	encouragement_button.pressed.connect(
		_active_assistant_encouragement
	)

	var world_button := _button(
		action_row,
		"تقديم العالم",
		Color(0.72, 0.48, 0.95),
		Vector2(0, 32)
	)
	world_button.pressed.connect(
		_active_assistant_explain_world
	)

	assistant_status_label = _label(
		"المساعد النشط: ميار",
		12,
		Color(0.55, 0.90, 1.0)
	)
	column.add_child(assistant_status_label)


# ==================================================
# SELECTION
# ==================================================

func _select_miyar() -> void:
	if is_instance_valid(assistant_manager):
		assistant_manager.call(
			"select_assistant",
			"miyar"
		)


func _select_adam() -> void:
	if is_instance_valid(assistant_manager):
		assistant_manager.call(
			"select_assistant",
			"adam"
		)


func _on_assistant_changed(assistant_id: String) -> void:
	_update_assistant_interface()
	_update_active_assistant_world()

	if assistant_id == "miyar":
		if is_instance_valid(premium_dialogue):
			premium_dialogue.text = (
				"تم اختيار ميار. أنا هنا لمرافقتك!"
			)

		if is_instance_valid(premium_status):
			premium_status.text = "المساعدة النشطة: ميار"

	else:
		if is_instance_valid(premium_dialogue):
			premium_dialogue.text = (
				"تم اختيار آدم. أنا هنا لمرافقتك!"
			)

		if is_instance_valid(premium_status):
			premium_status.text = "المساعد النشط: آدم"


func _on_assistant_selection_failed(reason: String) -> void:
	if is_instance_valid(assistant_status_label):
		assistant_status_label.text = reason

	if is_instance_valid(premium_status):
		premium_status.text = reason


# ==================================================
# UPDATE INTERFACE
# ==================================================

func _update_assistant_interface() -> void:
	if not is_instance_valid(assistant_manager):
		return

	var selected := str(
		assistant_manager.call(
			"get_selected_assistant"
		)
	)

	var is_miyar := selected == "miyar"

	if is_instance_valid(miyar_button):
		miyar_button.disabled = is_miyar
		miyar_button.text = (
			"✓ ميار المختارة"
			if is_miyar
			else "اختيار ميار"
		)

	if is_instance_valid(adam_button):
		adam_button.disabled = not is_miyar
		adam_button.text = (
			"اختيار آدم"
			if is_miyar
			else "✓ آدم المختار"
		)

	if is_miyar:
		if is_instance_valid(assistant_name_label):
			assistant_name_label.text = "ميار"

		if is_instance_valid(assistant_description_label):
			assistant_description_label.text = (
				"مساعدتك الذكية ورفيقتك في الرحلة."
			)

		if is_instance_valid(assistant_status_label):
			assistant_status_label.text = (
				"المساعدة النشطة: ميار"
			)

	else:
		if is_instance_valid(assistant_name_label):
			assistant_name_label.text = "آدم"

		if is_instance_valid(assistant_description_label):
			assistant_description_label.text = (
				"مرشد SYSTEM ومساعدك في التخطيط والتحديات."
			)

		if is_instance_valid(assistant_status_label):
			assistant_status_label.text = (
				"المساعد النشط: آدم"
			)


# ==================================================
# ACTIVE ASSISTANT ACTIONS
# ==================================================

func _get_active_assistant() -> Node3D:
	if not is_instance_valid(assistant_manager):
		return null

	return assistant_manager.call(
		"get_active_assistant"
	) as Node3D


func _active_assistant_welcome() -> void:
	var active := _get_active_assistant()

	if not is_instance_valid(active):
		return

	active.call("say_welcome")


func _active_assistant_encouragement() -> void:
	var active := _get_active_assistant()

	if not is_instance_valid(active):
		return

	active.call("say_encouragement")


func _active_assistant_explain_world() -> void:
	var active := _get_active_assistant()

	if not is_instance_valid(active):
		return

	active.call(
		"enter_world",
		selected_world
	)


# ==================================================
# WORLD INTEGRATION
# ==================================================

func _update_active_assistant_world() -> void:
	var active := _get_active_assistant()

	if is_instance_valid(active):
		active.call(
			"enter_world",
			selected_world
		)


func _on_world_manager_selected(world_id: String) -> void:
	super._on_world_manager_selected(world_id)

	if is_instance_valid(wardrobe_manager):
		wardrobe_manager.call(
			"change_world",
			world_id
		)

	_update_active_assistant_world()


# ==================================================
# MIYAR INTERACTION API
# ==================================================

func make_miyar_follow_player(player: Node3D) -> void:
	if is_instance_valid(miyar_controller):
		miyar_controller.call(
			"start_following",
			player
		)


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


# ==================================================
# ADAM INTERACTION API
# ==================================================

func make_adam_follow_player(player: Node3D) -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call(
			"start_following",
			player
		)


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


func make_adam_shy() -> void:
	if is_instance_valid(adam_controller):
		adam_controller.call("become_shy")
