extends CanvasLayer
class_name WorldPortalMenu

## This panel is informational only. World travel is performed by physical
## star gates in Baghdad, never by selecting a destination from a menu.

var toggle_button: Button
var portal_panel: PanelContainer


func _ready() -> void:
	layer = 20
	call_deferred("_build_interface")


func _build_interface() -> void:
	var root := Control.new()
	root.name = "WorldPortalInterface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	toggle_button = Button.new()
	toggle_button.name = "WorldsToggleButton"
	toggle_button.text = "بوابات العوالم"
	toggle_button.position = Vector2(20, 25)
	toggle_button.custom_minimum_size = Vector2(190, 55)
	toggle_button.add_theme_font_size_override("font_size", 20)
	root.add_child(toggle_button)
	toggle_button.pressed.connect(_toggle_panel)

	portal_panel = PanelContainer.new()
	portal_panel.name = "WorldPortalPanel"
	portal_panel.position = Vector2(20, 90)
	portal_panel.custom_minimum_size = Vector2(310, 190)
	root.add_child(portal_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	portal_panel.add_child(content)

	var title := Label.new()
	title.text = "مركز العبور بين العوالم"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 21)
	content.add_child(title)

	var message := Label.new()
	message.text = "الانتقال بين العوالم يتم حصراً عبر البوابات النجمية في بغداد.\nاذهب إلى مركز بوابات بغداد واختر البوابة المناسبة.\nجزيرة الطمع تفتح خلال موسمها وبعد استكمال مفاتيح العوالم."
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(285, 105)
	content.add_child(message)

	portal_panel.hide()


func _toggle_panel() -> void:
	if portal_panel != null:
		portal_panel.visible = not portal_panel.visible
