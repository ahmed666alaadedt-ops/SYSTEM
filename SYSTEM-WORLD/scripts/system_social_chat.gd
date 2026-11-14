
extends CanvasLayer
class_name SYSTEMSocialChat

signal friend_added(username: String)
signal message_sent(message: String)

var social_panel: PanelContainer
var chat_history: RichTextLabel
var message_input: LineEdit
var friend_input: LineEdit
var friends_list: VBoxContainer
var status_label: Label

var friends: Array[String] = []
var current_channel := "global"


func _ready() -> void:
	layer = 22
	_build_interface()


func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var open_button := Button.new()
	open_button.text = "الأصدقاء والدردشة"
	open_button.position = Vector2(20, 165)
	open_button.custom_minimum_size = Vector2(220, 55)
	root.add_child(open_button)
	open_button.pressed.connect(_toggle_panel)

	social_panel = PanelContainer.new()
	social_panel.position = Vector2(15, 230)
	social_panel.custom_minimum_size = Vector2(350, 480)
	social_panel.size = Vector2(350, 480)
	root.add_child(social_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	social_panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = "SYSTEM SOCIAL"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	header.add_child(close_button)
	close_button.pressed.connect(func(): social_panel.hide())

	var channels := HBoxContainer.new()
	layout.add_child(channels)

	var global_button := Button.new()
	global_button.text = "الدردشة العالمية"
	global_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	channels.add_child(global_button)
	global_button.pressed.connect(_show_global_chat)

	var friends_button := Button.new()
	friends_button.text = "الأصدقاء"
	friends_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	channels.add_child(friends_button)
	friends_button.pressed.connect(_show_friends)

	status_label = Label.new()
	status_label.text = "مرحباً بك في مجتمع SYSTEM"
	layout.add_child(status_label)

	chat_history = RichTextLabel.new()
	chat_history.custom_minimum_size = Vector2(300, 240)
	chat_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_history.bbcode_enabled = true
	layout.add_child(chat_history)

	message_input = LineEdit.new()
	message_input.placeholder_text = "اكتب رسالتك..."
	layout.add_child(message_input)
	message_input.text_submitted.connect(_send_message)

	var send_button := Button.new()
	send_button.text = "إرسال الرسالة"
	layout.add_child(send_button)
	send_button.pressed.connect(_send_current_message)

	friend_input = LineEdit.new()
	friend_input.placeholder_text = "اسم اللاعب لإضافته..."
	layout.add_child(friend_input)

	var add_button := Button.new()
	add_button.text = "إضافة صديق"
	layout.add_child(add_button)
	add_button.pressed.connect(_add_friend)

	friends_list = VBoxContainer.new()
	layout.add_child(friends_list)

	chat_history.append_text("[color=cyan]SYSTEM: تم تشغيل التواصل.[/color]\n")

	social_panel.hide()


func _toggle_panel() -> void:
	social_panel.visible = not social_panel.visible


func _show_global_chat() -> void:
	current_channel = "global"
	chat_history.clear()
	status_label.text = "الدردشة العالمية"
	chat_history.append_text("[color=cyan]أهلاً بك في الدردشة العالمية.[/color]\n")


func _show_friends() -> void:
	current_channel = "friends"
	chat_history.clear()
	status_label.text = "قائمة الأصدقاء"

	for child in friends_list.get_children():
		child.queue_free()

	for username in friends:
		var friend_label := Label.new()
		friend_label.text = "● " + username
		friends_list.add_child(friend_label)

	chat_history.append_text("[color=green]عدد الأصدقاء: %d[/color]\n" % friends.size())


func _send_current_message() -> void:
	_send_message(message_input.text)


func _send_message(message: String) -> void:
	var clean_message := message.strip_edges()

	if clean_message.is_empty():
		return

	chat_history.append_text(
		"[color=cyan]أنت:[/color] %s\n" % clean_message
	)

	message_sent.emit(clean_message)
	message_input.clear()


func _add_friend() -> void:
	var username := friend_input.text.strip_edges()

	if username.is_empty():
		status_label.text = "اكتب اسم اللاعب أولاً"
		return

	if friends.has(username):
		status_label.text = "هذا اللاعب موجود في قائمتك"
		return

	friends.append(username)
	friend_added.emit(username)

	friend_input.clear()
	status_label.text = "تمت إضافة اللاعب إلى القائمة"
	_show_friends()
