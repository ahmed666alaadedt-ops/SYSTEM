
extends Button

signal profile_updated(profile_data: Dictionary)

var profile_data := {
	"name": "الصياد الجديد",
	"appearance": "ذكر",
	"age_group": "adult",
	"hair_style": "قصير",
	"hair_color": "أسود",
	"face": "متوازن",
	"body": "رياضي",
	"outfit": "الزي الأساسي"
}

var profile_popup: PopupPanel
var name_input: LineEdit
var appearance_option: OptionButton
var age_group_option: OptionButton
var hair_style_option: OptionButton
var hair_color_option: OptionButton
var face_option: OptionButton
var body_option: OptionButton
var height_option: OptionButton
var outfit_option: OptionButton
var status_label: Label

const PROFILE_SAVE_PATH := "user://system_player_profile.cfg"
const HAIR_STYLES := [
	"قصير", "متوسط", "طويل", "طويل جدا", "مجعد", "أفرو",
	"ضفيرة", "دريدلوك", "ذيل حصان", "ضفيرتان", "كعكة", "مرفوع",
	"بوب", "بيكسي", "مدرج", "شائك", "جانبي", "محلوق الجوانب"
]
const HAIR_COLORS := [
	"أسود", "بني", "أشقر", "أصفر", "أبيض", "فضي", "رمادي",
	"أحمر", "أزرق", "أزرق داكن", "سماوي", "بنفسجي", "وردي",
	"أخضر", "برتقالي", "ذهبي", "أرجواني"
]


func _ready() -> void:
	_load_saved_profile()
	text = "الحساب وتخصيص الشخصية"
	custom_minimum_size = Vector2(230, 42)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_font_size_override("font_size", 15)

	pressed.connect(_open_profile_window)


func _open_profile_window() -> void:
	if profile_popup != null and is_instance_valid(profile_popup):
		profile_popup.popup_centered(Vector2i(440, 740))
		return

	_create_profile_window()
	profile_popup.popup_centered(Vector2i(440, 740))


func _create_profile_window() -> void:
	profile_popup = PopupPanel.new()
	profile_popup.name = "PlayerProfileWindow"
	profile_popup.size = Vector2i(440, 740)
	add_child(profile_popup)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.custom_minimum_size = Vector2(400, 700)
	var scroll := ScrollContainer.new()
	scroll.name = "CustomizationScroll"
	scroll.custom_minimum_size = Vector2(400, 680)
	scroll.size = Vector2(400, 680)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	profile_popup.add_child(scroll)
	scroll.add_child(root)

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

	age_group_option = _add_option(
		root,
		"الفئة العمرية",
		["بالغ", "كبير السن", "طفل"],
		"كبير السن" if str(profile_data.get("age_group", "adult")) == "elder" else ("طفل" if str(profile_data.get("age_group", "adult")) == "child" else "بالغ")
	)

	hair_style_option = _add_option(
		root,
		"تسريحة الشعر",
		HAIR_STYLES,
		profile_data["hair_style"]
	)

	hair_color_option = _add_option(
		root,
		"لون الشعر",
		HAIR_COLORS,
		profile_data["hair_color"]
	)

	var hair_note := Label.new()
	hair_note.text = "كل التسريحات متاحة للرجال والنساء، ومنها الشعر الطويل للرجال."
	hair_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hair_note)

	face_option = _add_option(
		root,
		"شكل الوجه",
		["متوازن", "حاد", "ناعم", "عريض"],
		profile_data["face"]
	)

	body_option = _add_option(
		root,
		"بنية الجسم",
		["رياضي", "نحيف", "متوسط", "قوي", "سمين"],

		profile_data["body"]
	)

	height_option = _add_option(
		root,
		"الطول",
		["قصير", "متوسط", "طويل"],
		str(profile_data.get("height_type", "متوسط"))
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
	var age_label := age_group_option.get_item_text(age_group_option.selected)
	profile_data["age_group"] = "elder" if age_label == "كبير السن" else ("child" if age_label == "طفل" else "adult")
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
	var height_label := height_option.get_item_text(height_option.selected)
	profile_data["height_type"] = "short" if height_label == "قصير" else ("tall" if height_label == "طويل" else "average")
	profile_data["outfit"] = outfit_option.get_item_text(
		outfit_option.selected
	)

	_save_profile()
	status_label.text = "تم حفظ المظهر: " + str(profile_data.get("hair_style", "")) + " / " + str(profile_data.get("hair_color", ""))
	profile_updated.emit(profile_data)


func _load_saved_profile() -> void:
	var config := ConfigFile.new()
	if config.load(PROFILE_SAVE_PATH) != OK:
		return
	var saved: Variant = config.get_value("player", "profile", {})
	if saved is Dictionary:
		for key in saved.keys():
			profile_data[key] = saved[key]


func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "profile", profile_data.duplicate(true))
	var error := config.save(PROFILE_SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM PROFILE: could not save local appearance profile: " + str(error))
