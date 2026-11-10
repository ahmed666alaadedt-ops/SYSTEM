
extends "res://scripts/miyar_command_center_link.gd"

# SYSTEM WORLD - Complete Command Center Integration
# Godot 4.3

const AssistantStageScript = preload(
	"res://scripts/assistant_3d_stage.gd"
)

const PartyDisplayScript = preload(
	"res://scripts/command_center_party_display_v2.gd"
)

const SYSTEM_ICON_PATH := "res://assets/system_launcher_icon.png"

var assistant_stage: Node3D
var party_display: Node3D
var system_logo: TextureRect


func _create_miyar_placeholder() -> void:
	pass


func _ready() -> void:
	super._ready()

	_create_assistant_stage()
	_create_party_display()
	_position_active_assistant()
	_create_system_logo_overlay()

	_connect_android_world_bridge()


# ==================================================
# ANDROID WORLD BRIDGE
# ==================================================

func _connect_android_world_bridge() -> void:
	var bridge := get_node_or_null(
		"/root/SYSTEMAndroidBridge"
	)

	if not is_instance_valid(bridge):
		push_warning(
			"SYSTEM: Android bridge is unavailable."
		)
		return

	var callback := Callable(
		self,
		"_on_android_world_entry_requested"
	)

	if not bridge.is_connected(
		"world_entry_requested",
		callback
	):
		bridge.connect(
			"world_entry_requested",
			callback
		)

	# Handle a request received before the command
	# center finished loading.
	if bridge.has_method("has_pending_world_request"):
		if bridge.call("has_pending_world_request"):
			call_deferred(
				"_consume_pending_android_world_request"
			)


func _consume_pending_android_world_request() -> void:
	var bridge := get_node_or_null(
		"/root/SYSTEMAndroidBridge"
	)

	if not is_instance_valid(bridge):
		return

	if not bridge.has_method("has_pending_world_request"):
		return

	if not bridge.call("has_pending_world_request"):
		return

	var world_id := str(
		bridge.call("consume_pending_world_request")
	)

	if world_id.is_empty():
		return

	_enter_world_from_android(world_id)


func _on_android_world_entry_requested(
	world_id: String
) -> void:
	var bridge := get_node_or_null(
		"/root/SYSTEMAndroidBridge"
	)

	# Consume the request so it cannot be processed
	# again after returning to the command center.
	if is_instance_valid(bridge):
		if bridge.has_method("has_pending_world_request"):
			if bridge.call("has_pending_world_request"):
				var pending_id := str(
					bridge.call(
						"consume_pending_world_request"
					)
				)

				if not pending_id.is_empty():
					world_id = pending_id

	_enter_world_from_android(world_id)


func _enter_world_from_android(
	world_id: String
) -> void:
	if not is_instance_valid(world_manager):
		push_warning(
			"SYSTEM: World manager is unavailable."
		)
		return

	if not world_manager.has_method("enter_world"):
		push_warning(
			"SYSTEM: World entry method is unavailable."
		)
		return

	var entered: bool = world_manager.call(
		"enter_world",
		world_id
	)

	if not entered:
		if is_instance_valid(utility_status):
			utility_status.text = (
				"تعذر دخول العالم: " + world_id
			)

		if is_instance_valid(miyar_message):
			miyar_message.text = (
				"لم أتمكن من فتح هذا العالم حالياً."
			)


# ==================================================
# SYSTEM OFFICIAL LOGO
# ==================================================

func _create_system_logo_overlay() -> void:
	if not ResourceLoader.exists(SYSTEM_ICON_PATH):
		push_warning(
			"SYSTEM: Official icon image was not found: "
			+ SYSTEM_ICON_PATH
		)
		return

	var icon_texture := load(SYSTEM_ICON_PATH) as Texture2D

	if icon_texture == null:
		push_warning("SYSTEM: Could not load the official icon.")
		return

	var logo_layer := CanvasLayer.new()
	logo_layer.name = "SYSTEMOfficialLogoLayer"
	logo_layer.layer = 25
	add_child(logo_layer)

	var overlay := Control.new()
	overlay.name = "SYSTEMLogoOverlay"
	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_layer.add_child(overlay)

	system_logo = TextureRect.new()
	system_logo.name = "SYSTEMOfficialLogo"
	system_logo.texture = icon_texture

	system_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	system_logo.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	system_logo.texture_filter = (
		CanvasItem.TEXTURE_FILTER_LINEAR
	)

	system_logo.tooltip_text = "SYSTEM WORLD"
	system_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	overlay.add_child(system_logo)

	_layout_system_logo()

	get_viewport().size_changed.connect(
		_layout_system_logo
	)


func _layout_system_logo() -> void:
	if not is_instance_valid(system_logo):
		return

	system_logo.position = Vector2(18, 8)
	system_logo.size = Vector2(68, 68)


# ==================================================
# ASSISTANT 3D STAGE
# ==================================================

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


func _position_active_assistant() -> void:
	if not is_instance_valid(assistant_stage):
		return

	var active := _get_active_assistant()

	if is_instance_valid(miyar_controller):
		miyar_controller.visible = (
			is_instance_valid(active)
			and active == miyar_controller
		)

	if is_instance_valid(adam_controller):
		adam_controller.visible = (
			is_instance_valid(active)
			and active == adam_controller
		)

	if not is_instance_valid(active):
		assistant_stage.call("clear_active_character")
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


# ==================================================
# PARTY DISPLAY
# ==================================================

func _create_party_display() -> void:
	party_display = PartyDisplayScript.new()
	party_display.name = "CommandCenterPartyDisplay"

	add_child(party_display)

	if not is_instance_valid(assistant_stage):
		return

	var anchor := assistant_stage.call(
		"get_party_display_anchor"
	) as Node3D

	if not is_instance_valid(anchor):
		push_warning(
			"SYSTEM: Party display anchor is unavailable."
		)
		return

	party_display.call(
		"configure_display",
		anchor,
		anchor
	)


# ==================================================
# ASSISTANT SELECTION
# ==================================================

func _on_assistant_changed(assistant_id: String) -> void:
	super._on_assistant_changed(assistant_id)
	_position_active_assistant()


func _get_active_assistant() -> Node3D:
	if not is_instance_valid(assistant_manager):
		return null

	return assistant_manager.call(
		"get_active_assistant"
	) as Node3D


# ==================================================
# PARTY DISPLAY PUBLIC API
# ==================================================

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


func remove_party_display_member(
	player_id: String
) -> void:
	if not is_instance_valid(party_display):
		return

	party_display.call(
		"unregister_party_member",
		player_id
	)


func replace_party_display_members(
	avatars: Array
) -> void:
	if not is_instance_valid(party_display):
		return

	party_display.call(
		"set_party_members",
		avatars
	)


func clear_party_display() -> void:
	if not is_instance_valid(party_display):
		return

	party_display.call(
		"clear_party_members"
	)


func get_party_display_count() -> int:
	if not is_instance_valid(party_display):
		return 0

	return int(
		party_display.call("get_member_count")
	)
