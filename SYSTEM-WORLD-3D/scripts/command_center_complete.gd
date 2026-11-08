
extends "res://scripts/miyar_command_center_link.gd"

# SYSTEM WORLD - Complete Command Center Integration
# Connects assistants, 3D stage and party display.

const AssistantStageScript = preload(
	"res://scripts/assistant_3d_stage.gd"
)

const PartyDisplayScript = preload(
	"res://scripts/command_center_party_display_v2.gd"
)

var assistant_stage: Node3D
var party_display: Node3D


# The new 3D stage replaces the old placeholder figure.
func _create_miyar_placeholder() -> void:
	pass


func _ready() -> void:
	super._ready()

	_create_assistant_stage()
	_create_party_display()
	_position_active_assistant()


func _create_assistant_stage() -> void:
	assistant_stage = AssistantStageScript.new()
	assistant_stage.name = "Assistant3DStage"
	assistant_stage.position = Vector3(0, 0, -0.8)
	add_child(assistant_stage)

	if is_instance_valid(miyar_controller):
		assistant_stage.call(
			"mount_character",
			miyar_controller,
			"miyar"
		)

	if is_instance_valid(adam_controller):
		assistant_stage.call(
			"mount_character",
			adam_controller,
			"adam"
		)

	_position_active_assistant()


func _create_party_display() -> void:
	party_display = PartyDisplayScript.new()
	party_display.name = "CommandCenterPartyDisplay"
	add_child(party_display)

	if is_instance_valid(assistant_stage):
		var anchor: Node3D = assistant_stage.call(
			"get_party_display_anchor"
		)

		party_display.call(
			"configure_display",
			anchor,
			anchor
		)


func _position_active_assistant() -> void:
	if not is_instance_valid(assistant_stage):
		return

	var active := _get_active_assistant()

	if not is_instance_valid(active):
		return

	var assistant_id := "miyar"

	if is_instance_valid(assistant_manager):
		assistant_id = str(
			assistant_manager.call("get_selected_assistant")
		)

	assistant_stage.call(
		"set_active_character",
		active,
		assistant_id
	)


func _on_assistant_changed(assistant_id: String) -> void:
	super._on_assistant_changed(assistant_id)
	_position_active_assistant()


# --------------------------------------------------
# PARTY DISPLAY PUBLIC API
# --------------------------------------------------

func add_party_display_member(
	player_id: String,
	avatar: Node3D
) -> void:
	if not is_instance_valid(party_display):
		return

	party_display.call(
		"register_party_member",
		player_id,
		avatar
	)


func remove_party_display_member(player_id: String) -> void:
	if not is_instance_valid(party_display):
		return

	party_display.call(
		"unregister_party_member",
		player_id
	)


func replace_party_display_members(avatars: Array) -> void:
	if not is_instance_valid(party_display):
		return

	party_display.call(
		"set_party_members",
		avatars
	)


func clear_party_display() -> void:
	if not is_instance_valid(party_display):
		return

	party_display.call("clear_party_members")


func get_party_display_count() -> int:
	if not is_instance_valid(party_display):
		return 0

	return int(party_display.call("get_member_count"))
