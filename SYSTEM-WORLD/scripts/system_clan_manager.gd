
extends CanvasLayer
class_name SYSTEMClanManager

signal clan_created(clan_name: String)
signal member_added(member_name: String)
signal announcement_posted(message: String)

var clan_name := ""
var clan_leader := "أنت"
var members: Array[Dictionary] = []
var announcements: Array[String] = []

var clan_panel: PanelContainer
var status_label: Label
var clan_name_input: LineEdit
var member_input: LineEdit
var announcement_input: LineEdit
var members_list: VBoxContainer
var announcements_list: VBoxContainer


func _ready() -> void:
	layer = 23
	_build_interface()


func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var open_button := Button.new()
	open_button.text = "الفرق والكلانات"
	open_button.position = Vector2(20, 230)
	open_button.custom_minimum_size = Vector2(220, 55)
	root.add_child(open_button)
	open_button.pressed.connect(_toggle_panel)

	clan_panel = PanelContainer.new()
	clan_panel.position = Vector2(15, 290)
	clan_panel.size = Vector2(350, 500)
	clan_panel.custom_minimum_size = Vector2(350, 500)
	root.add_child(clan_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	clan_panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = "SYSTEM CLANS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	header.add_child(close_button)
	close_button.pressed.connect(func(): clan_panel.hide())

	status_label = Label.new()
	status_label.text = "أنشئ فريقك واجمع أعضاءك"
	layout.add_child(status_label)

	clan_name_input = LineEdit.new()
	clan_name_input.placeholder_text = "اسم الفريق..."
	layout.add_child(clan_name_input)

	var create_button := Button.new()
	create_button.text = "إنشاء فريق"
	layout.add_child(create_button)
	create_button.pressed.connect(_create_clan)

	member_input = LineEdit.new()
	member_input.placeholder_text = "اسم العضو..."
	layout.add_child(member_input)

	var add_button := Button.new()
	add_button.text = "إضافة عضو"
	layout.add_child(add_button)
	add_button.pressed.connect(_add_member)

	var members_title := Label.new()
	members_title.text = "أعضاء الفريق"
	layout.add_child(members_title)

	members_list = VBoxContainer.new()
	layout.add_child(members_list)

	announcement_input = LineEdit.new()
	announcement_input.placeholder_text = "اكتب إعلان الفريق..."
	layout.add_child(announcement_input)

	var announcement_button := Button.new()
	announcement_button.text = "نشر إعلان"
	layout.add_child(announcement_button)
	announcement_button.pressed.connect(_post_announcement)

	var announcements_title := Label.new()
	announcements_title.text = "إعلانات الفريق"
	layout.add_child(announcements_title)

	announcements_list = VBoxContainer.new()
	layout.add_child(announcements_list)

	clan_panel.hide()


func _toggle_panel() -> void:
	clan_panel.visible = not clan_panel.visible


func _create_clan() -> void:
	var new_name := clan_name_input.text.strip_edges()

	if new_name.is_empty():
		status_label.text = "اكتب اسم الفريق أولاً"
		return

	if not clan_name.is_empty():
		status_label.text = "لديك فريق بالفعل"
		return

	clan_name = new_name
	members.append({
		"name": clan_leader,
		"rank": "القائد"
	})

	clan_created.emit(clan_name)
	clan_name_input.clear()
	status_label.text = "تم إنشاء الفريق: " + clan_name
	_refresh_members()


func _add_member() -> void:
	if clan_name.is_empty():
		status_label.text = "أنشئ فريقاً أولاً"
		return

	var new_member := member_input.text.strip_edges()

	if new_member.is_empty():
		status_label.text = "اكتب اسم العضو"
		return

	for member in members:
		if member["name"] == new_member:
			status_label.text = "هذا العضو موجود بالفعل"
			return

	members.append({
		"name": new_member,
		"rank": "عضو"
	})

	member_added.emit(new_member)
	member_input.clear()
	status_label.text = "تمت إضافة العضو"
	_refresh_members()


func _refresh_members() -> void:
	for child in members_list.get_children():
		child.queue_free()

	for member in members:
		var member_label := Label.new()
		member_label.text = str(member["rank"]) + " : " + str(member["name"])
		members_list.add_child(member_label)


func _post_announcement() -> void:
	if clan_name.is_empty():
		status_label.text = "أنشئ فريقاً أولاً"
		return

	var message := announcement_input.text.strip_edges()

	if message.is_empty():
		status_label.text = "اكتب الإعلان أولاً"
		return

	announcements.append(message)
	announcement_posted.emit(message)
	announcement_input.clear()

	var announcement_label := Label.new()
	announcement_label.text = "• " + message
	announcements_list.add_child(announcement_label)

	status_label.text = "تم نشر الإعلان"
