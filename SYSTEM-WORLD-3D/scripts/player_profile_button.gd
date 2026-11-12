
extends Button

signal profile_updated(profile_data: Dictionary)

var profile_data := {
	"name": "الصياد الجديد",
	"appearance": "ذكر",
	"hair_style": "قصير",
	"hair_color": "أسود",
	"face": "متوازن",
	"body": "رياضي",
	"outfit": "الزي الأساسي"
}

var profile_popup: PopupPanel
var name_input: LineEdit
var appearance_option: OptionButton
var hair_style_option: OptionButton
var hair_color_option: OptionButton
var face_option: OptionButton
var body_option: OptionButton
var outfit_option: OptionButton
var status_label: Label


func _ready() -> void:
	text = "الحساب وتخصيص الشخصية"
	custom_minimum_size = Vector2(230, 42)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_font_size_override("font_size", 15)

	pressed.connect(_open_profile_window)


func _open_profile_window() -> void:
	if profile_popup != null and is_instance_valid(profile_popup):
		profile_popup.popup_centered(Vector2i(440, 620))
		return

	_create_profile_window()
	profile_popup.popup_centered(Vector2i(440, 620))


func _create_profile_window() -> void:
	profile_popup = PopupPanel.new()
	profile_popup.name = "PlayerProfileWindow"
	profile_popup.size = Vector2i(440, 620)
	add_child(profile_popup)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.custom_minimum_size = Vector2(400, 580)
	profile_popup.add_child(root)

	var title := Label.new()
	title.text = "ملف اللاعب | تخصيص الشخصية"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	var description := Label.new()
	description.text = "أنشئ مظهرك الخاص داخل SYSTEM WORLD"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(description)

	root.add_child(HSeparator.new())

	name_input = _add_text_input(
		root,
		"اسم الشخصية",
		profile_data["name"]
	)

	appearance_option = _add_option(
		root,
		"نوع الشخصية",
		["ذكر", "أنثى"],
		profile_data["appearance"]
	)

	hair_style_option = _add_option(
		root,
		"تسريحة الشعر",
		["قصير", "متوسط", "طويل", "مجعد", "مربوط"],
		profile_data["hair_style"]
	)

	hair_color_option = _add_option(
		root,
		"لون الشعر",
		["أسود", "بني", "أشقر", "أبيض", "أحمر"],
		profile_data["hair_color"]
	)

	face_option = _add_option(
		root,
		"شكل الوجه",
		["متوازن", "حاد", "ناعم", "عريض"],
		profile_data["face"]
	)

	body_option = _add_option(
		root,
		"بنية الجسم",
		["رياضي", "نحيف", "متوسط", "قوي"],
		profile_data["body"]
	)

	outfit_option = _add_option(
		root,
		"الملابس الأساسية",
		["الزي الأساسي", "زي قتالي", "زي مغامر", "ملابس يومية"],
		profile_data["outfit"]
	)

	root.add_child(HSeparator.new())

	status_label = Label.new()
	status_label.text = "يمكنك تعديل مظهرك قبل الدخول إلى العالم."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status_label)

	var save_button := Button.new()
	save_button.text = "تأكيد المظهر"
	save_button.custom_minimum_size = Vector2(0, 46)
	save_button.pressed.connect(_confirm_profile)
	root.add_child(save_button)

	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.custom_minimum_size = Vector2(0, 38)
	close_button.pressed.connect(profile_popup.hide)
	root.add_child(close_button)


func _add_text_input(
	parent: VBoxContainer,
	field_title: String,
	default_text: String
) -> LineEdit:
	var label := Label.new()
	label.text = field_title
	parent.add_child(label)

	var field := LineEdit.new()
	field.text = default_text
	field.placeholder_text = field_title
	parent.add_child(field)

	return field


func _add_option(
	parent: VBoxContainer,
	field_title: String,
	options: Array,
	selected_value: String
) -> OptionButton:
	var label := Label.new()
	label.text = field_title
	parent.add_child(label)

	var option := OptionButton.new()

	for item in options:
		option.add_item(str(item))

	var selected_index := options.find(selected_value)
	if selected_index >= 0:
		option.select(selected_index)

	parent.add_child(option)
	return option


func _confirm_profile() -> void:
	profile_data["name"] = name_input.text.strip_edges()
	profile_data["appearance"] = appearance_option.get_item_text(
		appearance_option.selected
	)
	profile_data["hair_style"] = hair_style_option.get_item_text(
		hair_style_option.selected
	)
	profile_data["hair_color"] = hair_color_option.get_item_text(
		hair_color_option.selected
	)
	profile_data["face"] = face_option.get_item_text(
		face_option.selected
	)
	profile_data["body"] = body_option.get_item_text(
		body_option.selected
	)
	profile_data["outfit"] = outfit_option.get_item_text(
		outfit_option.selected
	)

	status_label.text = "تم تأكيد اختيارات الشخصية."
	profile_updated.emit(profile_data)
