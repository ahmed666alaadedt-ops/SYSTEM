
extends CanvasLayer
class_name WorldPortalMenu

const PortalButtonScript = preload("res://scripts/world_portal_button.gd")

var world_manager: Node
var toggle_button: Button
var portal_panel: PanelContainer
var portal_list: VBoxContainer


func _ready() -> void:
	layer = 20
	call_deferred("_initialize_menu")


func _initialize_menu() -> void:
	var game_root := get_parent()

	if game_root == null:
		push_warning("SYSTEM: Game root is missing.")
		return

	world_manager = game_root.get("world_manager")

	if world_manager == null:
		push_warning("SYSTEM: WorldManager is not ready.")
		return

	_build_interface()


func _build_interface() -> void:
	var root := Control.new()
	root.name = "WorldPortalInterface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	toggle_button = Button.new()
	toggle_button.name = "WorldsToggleButton"
	toggle_button.text = "العوالم الأربعة"
	toggle_button.position = Vector2(20, 25)
	toggle_button.custom_minimum_size = Vector2(190, 55)
	toggle_button.add_theme_font_size_override("font_size", 20)
	root.add_child(toggle_button)

	toggle_button.pressed.connect(_toggle_panel)

	portal_panel = PanelContainer.new()
	portal_panel.name = "WorldPortalPanel"
	portal_panel.position = Vector2(20, 90)
	portal_panel.custom_minimum_size = Vector2(260, 300)
	root.add_child(portal_panel)

	portal_list = VBoxContainer.new()
	portal_list.add_theme_constant_override("separation", 12)
	portal_panel.add_child(portal_list)

	var title := Label.new()
	title.text = "اختر عالمك"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	portal_list.add_child(title)

	_add_world_button("modern")
	_add_world_button("historical")
	_add_world_button("fantasy")
	_add_world_button("greed_island")

	portal_panel.hide()


func _add_world_button(world_id: String) -> void:
	var portal_button = PortalButtonScript.new()
	portal_button.world_id = world_id
	portal_button.custom_minimum_size = Vector2(230, 58)

	portal_list.add_child(portal_button)

	portal_button.world_selected.connect(
		_on_world_selected
	)


func _toggle_panel() -> void:
	portal_panel.visible = not portal_panel.visible


func _on_world_selected(world_id: String) -> void:
	if world_manager == null:
		push_warning("SYSTEM: WorldManager is unavailable.")
		return

	var destination_id := -1

	match world_id:
		"fantasy":
			destination_id = 0
		"historical":
			destination_id = 1
		"modern":
			destination_id = 2
		"greed_island":
			destination_id = 3

	if destination_id == -1:
		push_warning("SYSTEM: Invalid world selection.")
		return

	world_manager.switch_world(destination_id)

	portal_panel.hide()

	print("SYSTEM: Portal selected: ", world_id)
