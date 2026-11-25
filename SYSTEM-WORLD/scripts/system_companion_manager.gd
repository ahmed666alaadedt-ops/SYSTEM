extends Node3D
class_name SYSTEMCompanionManager

## UI-only assistant interface.
## Miyar and Adam explain SYSTEM from the interface; they never follow or accompany
## the player as world companions. Their in-world appearances are reserved for
## their approved tower-leader roles.

var player: CharacterBody3D
var world_manager: Node
var dialogue_label: Label
var selected_assistant := "miyar"

func setup(player_node: CharacterBody3D, manager: Node) -> void:
	player = player_node
	world_manager = manager
	_create_assistant_interface()
	_show_welcome("miyar")


func _create_assistant_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SYSTEMCompanionInterface"
	layer.layer = 11
	add_child(layer)
	var root := Control.new()
	root.name = "AssistantRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(390.0, 14.0)
	root.size = Vector2(430.0, 126.0)
	layer.add_child(root)
	var panel := PanelContainer.new()
	panel.name = "AssistantPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.name = "AssistantColumn"
	panel.add_child(column)
	var buttons := HBoxContainer.new()
	buttons.name = "AssistantButtons"
	column.add_child(buttons)
	var miyar_button := Button.new()
	miyar_button.name = "MiyarAssistantButton"
	miyar_button.text = "تحدث مع ميار"
	miyar_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(miyar_button)
	miyar_button.pressed.connect(func() -> void:
		_show_welcome("miyar")
	)
	var adam_button := Button.new()
	adam_button.name = "AdamAssistantButton"
	adam_button.text = "تحدث مع آدم"
	adam_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(adam_button)
	adam_button.pressed.connect(func() -> void:
		_show_welcome("adam")
	)
	dialogue_label = Label.new()
	dialogue_label.name = "AssistantDialogue"
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(0.0, 58.0)
	column.add_child(dialogue_label)


func _show_welcome(assistant_id: String) -> void:
	selected_assistant = assistant_id
	if not is_instance_valid(dialogue_label):
		return
	if assistant_id == "miyar":
		dialogue_label.text = "ميار: أهلاً بك. أشرح لك عوالم SYSTEM وقصصها ومهامها وأنظمتها من هذه الواجهة."
	else:
		dialogue_label.text = "آدم: أهلاً بك. أشرح لك أنظمة التحديات والتقدم والاستكشاف من هذه الواجهة."
