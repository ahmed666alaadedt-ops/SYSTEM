
extends Button
class_name SocialHubButton

const PANEL_BACKGROUND := Color(0.025, 0.06, 0.11, 0.98)
const ACCENT_COLOR := Color(0.0, 0.75, 1.0)

var social_popup: PopupPanel
var friends_list: VBoxContainer
var private_messages: VBoxContainer
var global_messages: VBoxContainer

var friend_input: LineEdit
var private_input: LineEdit
var global_input: LineEdit

var selected_friend := ""
var friends: Array[String] = []


func _ready() -> void:
	text = "الأصدقاء والدردشة"
	tooltip_text = "الأصدقاء والمحادثات والدردشة العالمية"

	custom_minimum_size = Vector2(230, 44)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color.WHITE)

	_apply_button_style()
	_create_social_popup()

	pressed.connect(_open_social_panel)


func _apply_button_style() -> void:
	add_theme_stylebox_override(
		"normal",
		_make_style(
			Color(0.035, 0.12, 0.19),
			ACCENT_COLOR
		)
	)

	add_theme_stylebox_override(
		"hover",
		_make_style(
			Color(0.06, 0.20, 0.29),
			Color(0.15, 0.9, 1.0)
		)
	)


func _make_style(
	background: Color,
	border: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	return style


func _create_social_popup() -> void:
	social_popup = PopupPanel.new()
	social_popup.name = "SYSTEMSocialCenter"

	var panel_style := _make_style(
		PANEL_BACKGROUND,
		ACCENT_COLOR
	)

	social_popup.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	var main_column := VBoxContainer.new()
	main_column.custom_minimum_size = Vector2(480, 520)
	main_column.add_theme_constant_override("separation", 10)

	social_popup.add_child(main_column)

	var title := Label.new()
	title.text = "مركز التواصل SYSTEM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override(
		"font_color",
		Color(0.2, 0.85, 1.0)
	)
	main_column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "الأصدقاء | الرسائل | المجتمع العالمي"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_column.add_child(subtitle)

	main_column.add_child(HSeparator.new())

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_column.add_child(tabs)

	_create_friends_tab(tabs)
	_create_private_tab(tabs)
	_create_global_tab(tabs)

	var close_button := Button.new()
	close_button.text = "إغلاق مركز التواصل"
	close_button.custom_minimum_size = Vector2(180, 40)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(social_popup.hide)

	main_column.add_child(close_button)

	get_tree().root.add_child(social_popup)


func _create_friends_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "الأصدقاء"
	page.add_theme_constant_override("separation", 10)
	tabs.add_child(page)

	var heading := Label.new()
	heading.text = "قائمة الأصدقاء"
	heading.add_theme_font_size_override("font_size", 18)
	page.add_child(heading)

	var add_row := HBoxContainer.new()
	page.add_child(add_row)

	friend_input = LineEdit.new()
	friend_input.placeholder_text = "اكتب اسم اللاعب أو معرفه"
	friend_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(friend_input)

	var add_button := Button.new()
	add_button.text = "إضافة"
	add_button.pressed.connect(_add_friend)
	add_row.add_child(add_button)

	var note := Label.new()
	note.text = "الأصدقاء الذين تضيفهم هنا يظهرون في هذه القائمة."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)

	friends_list = VBoxContainer.new()
	friends_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(friends_list)


func _create_private_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "الرسائل"
	page.add_theme_constant_override("separation", 8)
	tabs.add_child(page)

	var heading := Label.new()
	heading.text = "المحادثات الخاصة"
	heading.add_theme_font_size_override("font_size", 18)
	page.add_child(heading)

	var selected_label := Label.new()
	selected_label.name = "SelectedFriendLabel"
	selected_label.text = "اختر صديقاً من قائمة الأصدقاء أولاً."
	page.add_child(selected_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)

	private_messages = VBoxContainer.new()
	private_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(private_messages)

	var send_row := HBoxContainer.new()
	page.add_child(send_row)

	private_input = LineEdit.new()
	private_input.placeholder_text = "اكتب رسالتك..."
	private_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	private_input.text_submitted.connect(_send_private_message)
	send_row.add_child(private_input)

	var send_button := Button.new()
	send_button.text = "إرسال"
	send_button.pressed.connect(
		_send_private_message.bind("")
	)
	send_row.add_child(send_button)


func _create_global_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "الدردشة العالمية"
	page.add_theme_constant_override("separation", 8)
	tabs.add_child(page)

	var heading := Label.new()
	heading.text = "المجتمع العالمي"
	heading.add_theme_font_size_override("font_size", 18)
	page.add_child(heading)

	var info := Label.new()
	info.text = "ساحة المحادثة العامة للاعبين."
	page.add_child(info)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)

	global_messages = VBoxContainer.new()
	global_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(global_messages)

	var send_row := HBoxContainer.new()
	page.add_child(send_row)

	global_input = LineEdit.new()
	global_input.placeholder_text = "اكتب رسالة للمجتمع..."
	global_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_input.text_submitted.connect(_send_global_message)
	send_row.add_child(global_input)

	var send_button := Button.new()
	send_button.text = "إرسال"
	send_button.pressed.connect(
		_send_global_message.bind("")
	)
	send_row.add_child(send_button)

	_add_message(
		global_messages,
		"SYSTEM",
		"مرحباً بك في المجتمع العالمي."
	)


func _add_friend() -> void:
	var friend_name := friend_input.text.strip_edges()

	if friend_name.is_empty():
		return

	if friends.has(friend_name):
		friend_input.text = ""
		return

	friends.append(friend_name)
	friend_input.text = ""

	var friend_button := Button.new()
	friend_button.text = "●  " + friend_name
	friend_button.custom_minimum_size = Vector2(400, 42)
	friend_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	friend_button.pressed.connect(
		_select_friend.bind(friend_name)
	)

	friends_list.add_child(friend_button)


func _select_friend(friend_name: String) -> void:
	selected_friend = friend_name

	var page := social_popup.find_child(
		"SelectedFriendLabel",
		true,
		false
	)

	if page is Label:
		page.text = "المحادثة مع: " + friend_name

	private_messages.add_child(HSeparator.new())

	var notice := Label.new()
	notice.text = "تم اختيار " + friend_name
	private_messages.add_child(notice)


func _send_private_message(_submitted_text: String = "") -> void:
	var message := private_input.text.strip_edges()

	if message.is_empty():
		return

	if selected_friend.is_empty():
		_add_message(
			private_messages,
			"SYSTEM",
			"اختر صديقاً أولاً لبدء المحادثة."
		)
		return

	_add_message(
		private_messages,
		"أنت",
		message
	)

	private_input.text = ""


func _send_global_message(_submitted_text: String = "") -> void:
	var message := global_input.text.strip_edges()

	if message.is_empty():
		return

	_add_message(
		global_messages,
		"أنت",
		message
	)

	global_input.text = ""


func _add_message(
	container: VBoxContainer,
	sender: String,
	message: String
) -> void:
	var label := Label.new()

	label.text = sender + ": " + message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.94, 1.0)
	)

	container.add_child(label)


func _open_social_panel() -> void:
	if social_popup == null:
		return

	social_popup.popup_centered(Vector2i(540, 620))
