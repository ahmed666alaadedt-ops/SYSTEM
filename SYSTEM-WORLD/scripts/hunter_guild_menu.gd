
extends CanvasLayer
class_name HunterGuildMenu

signal mission_accepted(mission_id: String)
signal exam_registration_requested
signal exam_start_requested

var root_ui: Control
var guild_panel: PanelContainer
var mission_list: VBoxContainer
var status_label: Label
var exam_register_button: Button
var exam_start_button: Button
var service_info_label: Label

var missions := [
	{
		"id": "guild_001",
		"title": "مهمة الصياد المبتدئ",
		"description": "استكشف المنطقة المحيطة وسجل أول اكتشاف لك.",
		"rank": "E",
		"reward": 100
	},
	{
		"id": "guild_002",
		"title": "مطاردة الوحش",
		"description": "تعقب وحشاً مجهولاً واجمع معلومات عنه.",
		"rank": "D",
		"reward": 250
	},
	{
		"id": "guild_003",
		"title": "بوابة غامضة",
		"description": "تحقق من بوابة ظهرت خارج المدينة.",
		"rank": "C",
		"reward": 500
	}
]


func _ready() -> void:
	layer = 21
	_build_interface()


func _build_interface() -> void:
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root_ui)

	var open_button := Button.new()
	open_button.text = "نقابة الصيادين"
	open_button.position = Vector2(20, 95)
	open_button.custom_minimum_size = Vector2(210, 58)
	open_button.add_theme_font_size_override("font_size", 19)
	root_ui.add_child(open_button)
	open_button.pressed.connect(_toggle_panel)

	guild_panel = PanelContainer.new()
	guild_panel.position = Vector2(20, 165)
	guild_panel.custom_minimum_size = Vector2(340, 440)
	guild_panel.size = Vector2(340, 440)
	root_ui.add_child(guild_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	guild_panel.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)

	var title := Label.new()
	title.text = "نقابة الصيادين العالمية"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	header.add_child(close_button)
	close_button.pressed.connect(func(): guild_panel.hide())

	status_label = Label.new()
	status_label.text = "اختر مهمة للبدء بمغامرتك"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status_label)

	service_info_label = Label.new()
	service_info_label.text = "معلومات نقابة الصيادين واختبارها العالمي."
	service_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(service_info_label)

	var separator := HSeparator.new()
	content.add_child(separator)

	exam_register_button = Button.new()
	exam_register_button.text = "التسجيل في اختبار الصيادين العالمي"
	exam_register_button.pressed.connect(func(): exam_registration_requested.emit())
	content.add_child(exam_register_button)

	exam_start_button = Button.new()
	exam_start_button.text = "بدء سلسلة الاختبار"
	exam_start_button.pressed.connect(func(): exam_start_requested.emit())
	content.add_child(exam_start_button)

	mission_list = VBoxContainer.new()
	mission_list.add_theme_constant_override("separation", 10)
	content.add_child(mission_list)

	_build_missions()
	guild_panel.hide()
	_set_service_view("all")


func set_exam_status(result: Dictionary) -> void:
	if not bool(result.get("success", false)):
		status_label.text = "حالة الاختبار: " + str(result.get("reason", "تعذر تنفيذ الطلب"))
		return
	if result.has("candidate_number") and result.has("stages"):
		status_label.text = "رقم المتسابق: %d | مراحل الاختبار: %d" % [int(result["candidate_number"]), int(result["stages"])]
	elif result.has("stage"):
		var stage: Dictionary = result["stage"]
		status_label.text = "بدأ الاختبار: " + str(stage.get("title", ""))
	else:
		status_label.text = "تم تحديث حالة اختبار الصيادين"


func _build_missions() -> void:
	for mission in missions:
		var card := PanelContainer.new()
		mission_list.add_child(card)

		var details := VBoxContainer.new()
		details.add_theme_constant_override("separation", 5)
		card.add_child(details)

		var name_label := Label.new()
		name_label.text = mission["title"]
		name_label.add_theme_font_size_override("font_size", 18)
		details.add_child(name_label)

		var description := Label.new()
		description.text = mission["description"]
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(description)

		var info := Label.new()
		info.text = "الرتبة: %s  |  المكافأة: %d XP" % [
			mission["rank"],
			mission["reward"]
		]
		details.add_child(info)

		var accept_button := Button.new()
		accept_button.text = "قبول المهمة"
		details.add_child(accept_button)

		accept_button.pressed.connect(
			_on_mission_accepted.bind(mission["id"], mission["title"])
		)


func open_guild_panel() -> void:
	open_service_view("all")


## Opens the section associated with the selected Hunter Association desk.
## Lobby service IDs end in _0 (registration), _1 (missions), or _2 (information).
func open_service_view(service_id: String) -> void:
	if not is_instance_valid(guild_panel):
		return
	var view := "all"
	if service_id.ends_with("_0"):
		view = "registration"
	elif service_id.ends_with("_1"):
		view = "missions"
	elif service_id.ends_with("_2"):
		view = "information"
	_set_service_view(view)
	guild_panel.show()


func _set_service_view(view: String) -> void:
	if not is_instance_valid(exam_register_button):
		return
	exam_register_button.visible = view == "all" or view == "registration"
	exam_start_button.visible = view == "all" or view == "registration"
	mission_list.visible = view == "all" or view == "missions"
	service_info_label.visible = view == "all" or view == "information"
	match view:
		"registration":
			status_label.text = "مكتب تسجيل الصيادين"
			service_info_label.text = "سجّل في اختبار الصيادين العالمي، ثم ابدأ سلسلة الاختبار عند جاهزيتك."
		"missions":
			status_label.text = "لوحة مهام نقابة الصيادين"
			service_info_label.text = "اختر إحدى المهام المتاحة لقبولها."
		"information":
			status_label.text = "معلومات نقابة الصيادين"
			service_info_label.text = "تدير النقابة تصنيف الصيادين والمهام والاختبار العالمي. تفاصيل التحديات والتحقق النهائي ما زالت قيد التطوير."
		_:
			status_label.text = "اختر مهمة أو إجراء اختبار الصيادين"
			service_info_label.text = "مركز خدمات نقابة الصيادين العالمية."


func close_guild_panel() -> void:
	if is_instance_valid(guild_panel):
		guild_panel.hide()


func _toggle_panel() -> void:
	guild_panel.visible = not guild_panel.visible


func _on_mission_accepted(mission_id: String, mission_title: String) -> void:
	status_label.text = "تم اختيار: " + mission_title
	mission_accepted.emit(mission_id)

	print("SYSTEM: Hunter mission selected: ", mission_id)
