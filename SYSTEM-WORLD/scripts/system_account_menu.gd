
extends CanvasLayer
class_name SYSTEMAccountMenu

signal profile_updated(player_name: String)

var player_name := "SYSTEM Hunter"
var player_level := 1
var player_xp := 0
var current_world := "العالم الحديث"

var account_panel: PanelContainer
var name_input: LineEdit
var name_label: Label
var level_label: Label
var xp_label: Label
var world_label: Label
var status_label: Label


func _ready() -> void:
	layer = 24
	_build_interface()
	_refresh_profile()


func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var open_button := Button.new()
	open_button.text = "حساب اللاعب"
	open_button.position = Vector2(20, 300)
	open_button.custom_minimum_size = Vector2(220, 55)
	root.add_child(open_button)
	open_button.pressed.connect(_toggle_panel)

	account_panel = PanelContainer.new()
	account_panel.position = Vector2(15, 365)
	account_panel.size = Vector2(350, 380)
	account_panel.custom_minimum_size = Vector2(350, 380)
	root.add_child(account_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	account_panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = "SYSTEM ACCOUNT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	header.add_child(close_button)
	close_button.pressed.connect(func(): account_panel.hide())

	name_label = Label.new()
	layout.add_child(name_label)

	level_label = Label.new()
	layout.add_child(level_label)

	xp_label = Label.new()
	layout.add_child(xp_label)

	world_label = Label.new()
	layout.add_child(world_label)

	var separator := HSeparator.new()
	layout.add_child(separator)

	var edit_title := Label.new()
	edit_title.text = "تعديل اسم اللاعب"
	layout.add_child(edit_title)

	name_input = LineEdit.new()
	name_input.placeholder_text = "اكتب الاسم الجديد..."
	layout.add_child(name_input)

	var save_button := Button.new()
	save_button.text = "حفظ الاسم"
	layout.add_child(save_button)
	save_button.pressed.connect(_save_profile)

	status_label = Label.new()
	layout.add_child(status_label)

	account_panel.hide()


func _toggle_panel() -> void:
	account_panel.visible = not account_panel.visible
	_refresh_profile()


func _refresh_profile() -> void:
	name_label.text = "اللاعب: " + player_name
	level_label.text = "المستوى: " + str(player_level)
	xp_label.text = "الخبرة: " + str(player_xp) + " XP"
	world_label.text = "العالم الحالي: " + current_world


func _save_profile() -> void:
	var new_name := name_input.text.strip_edges()

	if new_name.is_empty():
		status_label.text = "اكتب اسماً أولاً"
		return

	player_name = new_name
	name_input.clear()

	profile_updated.emit(player_name)
	status_label.text = "تم تحديث الاسم"
	_refresh_profile()


func set_player_progress(level: int, xp: int) -> void:
	player_level = maxi(1, level)
	player_xp = maxi(0, xp)
	_refresh_profile()


func set_current_world(world: String) -> void:
	current_world = world
	_refresh_profile()
