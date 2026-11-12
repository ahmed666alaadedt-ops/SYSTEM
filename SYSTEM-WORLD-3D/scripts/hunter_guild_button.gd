extends Button
class_name HunterGuildButton

const PANEL_BACKGROUND := Color(0.025, 0.06, 0.11, 0.98)
const ACCENT_COLOR := Color(0.0, 0.75, 1.0)

var guild_popup: PopupPanel
var details_label: Label


func _ready() -> void:
	text = "نقابة الصيادين العالمية"
	tooltip_text = "المهام والاختبارات والأنشطة"

	custom_minimum_size = Vector2(230, 44)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color.WHITE)

	_apply_button_style()
	_create_guild_popup()

	pressed.connect(_open_guild_panel)


func _apply_button_style() -> void:
	var normal := _make_style(
		Color(0.035, 0.12, 0.19),
		ACCENT_COLOR
	)

	var hover := _make_style(
		Color(0.06, 0.20, 0.29),
		Color(0.15, 0.9, 1.0)
	)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)


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


func _create_guild_popup() -> void:
	guild_popup = PopupPanel.new()
	guild_popup.name = "HunterGuildPanel"

	var panel_style := _make_style(
		PANEL_BACKGROUND,
		ACCENT_COLOR
	)

	guild_popup.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(480, 420)
	column.add_theme_constant_override("separation", 12)

	guild_popup.add_child(column)

	var title := Label.new()
	title.text = "نقابة الصيادين العالمية"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override(
		"font_color",
		Color(0.2, 0.85, 1.0)
	)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "مركز المهام والاختبارات والأنشطة"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	column.add_child(subtitle)

	column.add_child(HSeparator.new())

	_add_activity_button(
		column,
		"مهام الصيادين",
		"استعراض المهام المتاحة والمكافآت وشروط قبول كل مهمة."
	)

	_add_activity_button(
		column,
		"اختبار رخصة الصياد XSX",
		"الاستعداد لمراحل اختبار الصيادين والحصول على الرخصة."
	)

	_add_activity_button(
		column,
		"البوابات والزنزانات",
		"استكشاف البوابات ومواجهة الوحوش وجمع الغنائم."
	)

	_add_activity_button(
		column,
		"الغارات الجماعية",
		"أنشطة وتحديات تتطلب التعاون مع صيادين آخرين."
	)

	_add_activity_button(
		column,
		"تصنيف الصيادين",
		"واجهة مخصصة لترتيب الصيادين وإنجازاتهم."
	)

	_add_activity_button(
		column,
		"سجل الإنجازات",
		"متابعة الرخص والاختبارات والمهام المكتملة."
	)

	column.add_child(HSeparator.new())

	details_label = Label.new()
	details_label.text = "اختر نشاطاً لعرض تفاصيله."
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.custom_minimum_size = Vector2(440, 55)
	details_label.add_theme_font_size_override("font_size", 14)
	column.add_child(details_label)

	var close_button := Button.new()
	close_button.text = "إغلاق النقابة"
	close_button.custom_minimum_size = Vector2(180, 42)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(guild_popup.hide)
	column.add_child(close_button)

	get_tree().root.add_child(guild_popup)


func _add_activity_button(
	parent: VBoxContainer,
	title: String,
	description: String
) -> void:
	var activity_button := Button.new()

	activity_button.text = title
	activity_button.custom_minimum_size = Vector2(440, 42)
	activity_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	activity_button.add_theme_font_size_override(
		"font_size",
		15
	)

	activity_button.add_theme_stylebox_override(
		"normal",
		_make_style(
			Color(0.035, 0.10, 0.16),
			Color(0.0, 0.40, 0.65)
		)
	)

	activity_button.pressed.connect(
		_show_activity.bind(title, description)
	)

	parent.add_child(activity_button)


func _show_activity(
	title: String,
	description: String
) -> void:
	details_label.text = (
		title + "\n" +
		description + "\n" +
		"حالة النظام: واجهة أولية، بانتظار ربط نظام النشاط."
	)


func _open_guild_panel() -> void:
	if guild_popup == null:
		return

	guild_popup.popup_centered(Vector2i(540, 590))
