extends CanvasLayer
class_name SYSTEMBusinessServicesMenu

var economy: Node
var panel: PanelContainer
var heading: Label
var status_label: Label
var balance_label: Label
var company_name_input: LineEdit
var sector_select: OptionButton
var company_list: VBoxContainer
var active_view := "overview"


func setup(p_economy: Node) -> void:
	economy = p_economy


func _ready() -> void:
	layer = 22
	_build_interface()


func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	panel = PanelContainer.new()
	panel.position = Vector2(18, 110)
	panel.size = Vector2(350, 500)
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	heading = Label.new()
	heading.text = "برج التجارة والاستثمار"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 20)
	header.add_child(heading)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)
	balance_label = Label.new()
	content.add_child(balance_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)
	var separator := HSeparator.new()
	content.add_child(separator)
	var form_label := Label.new()
	form_label.text = "تسجيل شركة جديدة"
	content.add_child(form_label)
	company_name_input = LineEdit.new()
	company_name_input.placeholder_text = "اسم الشركة (3 إلى 32 حرفاً)"
	content.add_child(company_name_input)
	sector_select = OptionButton.new()
	for sector in ["تجارة", "تقنية", "خدمات", "ضيافة", "نقل", "صناعة"]:
		sector_select.add_item(sector)
	content.add_child(sector_select)
	var register_button := Button.new()
	register_button.text = "تسجيل الشركة — 1,000 رصيد"
	register_button.pressed.connect(_on_register_company_pressed)
	content.add_child(register_button)
	var list_heading := Label.new()
	list_heading.text = "الشركات المسجلة محلياً"
	content.add_child(list_heading)
	company_list = VBoxContainer.new()
	content.add_child(company_list)
	panel.hide()


func open_service_view(service_id: String) -> void:
	if not is_instance_valid(panel):
		return
	if service_id.ends_with("_0"):
		active_view = "overview"
	elif service_id.ends_with("_1"):
		active_view = "investments"
	elif service_id.ends_with("_2"):
		active_view = "companies"
	_refresh_view()
	panel.show()


func close_panel() -> void:
	if is_instance_valid(panel):
		panel.hide()


func _refresh_view() -> void:
	if not is_instance_valid(economy):
		status_label.text = "نظام الاقتصاد غير متاح حالياً."
		return
	var balance := int(economy.call("get_balance"))
	balance_label.text = "رصيدك الحالي: %s SYSTEM Credits" % _format_number(balance)
	heading.text = "برج التجارة والاستثمار"
	match active_view:
		"overview":
			status_label.text = "مركز استشارات الأعمال: يمكنك تأسيس شركة محلية وتسجيل نشاطها. خدمات التراخيص الرسمية والموظفين والعقود قيد التطوير."
		"investments":
			status_label.text = "سوق الاستثمار غير مفعّل بعد. لن تُخصم أموال ولن تُعرض أرباح وهمية. سيُفتح بعد بناء نظام شركات ومشاريع وعوائد قابلة للتحقق."
		"companies":
			status_label.text = "سجّل شركتك وابدأ ملفها التجاري. التسجيل الحالي محلي على هذا الجهاز، وليس سجلاً تجارياً حقيقياً أو حساباً متصلاً بالإنترنت."
	_refresh_company_list()


func _refresh_company_list() -> void:
	for child in company_list.get_children():
		child.queue_free()
	if not is_instance_valid(economy):
		return
	var entries: Array = economy.call("get_companies")
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "لا توجد شركات مسجلة حتى الآن."
		company_list.add_child(empty_label)
		return
	for company in entries:
		var row := Label.new()
		row.text = "%s — %s" % [str(company.get("name", "")), str(company.get("sector", ""))]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		company_list.add_child(row)


func _on_register_company_pressed() -> void:
	if not is_instance_valid(economy):
		status_label.text = "تعذر الوصول إلى نظام الاقتصاد."
		return
	var sector := sector_select.get_item_text(sector_select.selected)
	var result: Dictionary = economy.call("register_company", company_name_input.text, sector)
	if bool(result.get("success", false)):
		company_name_input.clear()
		status_label.text = "تم تسجيل الشركة محلياً: %s. الرصيد المتبقي: %s" % [
			str(result.company.get("name", "")),
			_format_number(int(result.get("balance", 0)))
		]
	else:
		var reason := str(result.get("reason", "UNKNOWN_ERROR"))
		match reason:
			"COMPANY_NAME_LENGTH":
				status_label.text = "اسم الشركة يجب أن يكون بين 3 و32 حرفاً."
			"INVALID_BUSINESS_SECTOR":
				status_label.text = "اختر مجال عمل صحيحاً."
			"LOCAL_COMPANY_LIMIT_REACHED":
				status_label.text = "وصلت إلى الحد الحالي: خمس شركات محلية."
			"COMPANY_NAME_ALREADY_REGISTERED":
				status_label.text = "هذا الاسم مسجل مسبقاً."
			"INSUFFICIENT_CURRENCY":
				status_label.text = "الرصيد غير كافٍ. تحتاج إلى 1,000 رصيد."
			_:
				status_label.text = "تعذر التسجيل: " + reason
	_refresh_view()


func _format_number(value: int) -> String:
	return String.num_int64(value)
