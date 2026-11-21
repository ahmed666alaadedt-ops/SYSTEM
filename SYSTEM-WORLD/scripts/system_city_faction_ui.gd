extends CanvasLayer
class_name SystemCityFactionUI

var faction_manager: Node
var panel: PanelContainer
var city_label: Label
var status_label: Label
var faction_list: VBoxContainer
var contracts_list: VBoxContainer
var objective_select: OptionButton
var active_city := "Baghdad"

const OBJECTIVES := [
	{"id":"deliver_courier_package","label":"توصيل طرد"},
	{"id":"collect_public_evidence","label":"جمع أدلة عامة"},
	{"id":"scout_district","label":"استطلاع منطقة"},
	{"id":"protect_civilian_route","label":"حماية طريق مدني"}
]

func setup(p_manager: Node) -> void:
	faction_manager = p_manager

func _ready() -> void:
	layer = 25
	_build_interface()

func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8.0
	panel.offset_top = 75.0
	panel.offset_right = -8.0
	panel.offset_bottom = -75.0
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "دار الوسطاء — شبكة الفصائل"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(close_board)
	header.add_child(close_button)
	city_label = Label.new()
	content.add_child(city_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var sections := VBoxContainer.new()
	sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_theme_constant_override("separation", 8)
	scroll.add_child(sections)
	var faction_heading := Label.new()
	faction_heading.text = "الفصائل المسجلة في المدينة"
	faction_heading.add_theme_font_size_override("font_size", 16)
	sections.add_child(faction_heading)
	faction_list = VBoxContainer.new()
	faction_list.add_theme_constant_override("separation", 7)
	sections.add_child(faction_list)
	var contract_heading := Label.new()
	contract_heading.text = "عقود اللاعب"
	contract_heading.add_theme_font_size_override("font_size", 16)
	sections.add_child(contract_heading)
	contracts_list = VBoxContainer.new()
	sections.add_child(contracts_list)
	objective_select = OptionButton.new()
	for objective in OBJECTIVES:
		objective_select.add_item(str(objective["label"]))
	content.add_child(objective_select)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)
	panel.hide()

func open_city(city_name: String) -> void:
	if not is_instance_valid(faction_manager):
		return
	active_city = city_name if not city_name.is_empty() else "Baghdad"
	_refresh_board()
	panel.show()

func close_board() -> void:
	if is_instance_valid(panel):
		panel.hide()

func _refresh_board() -> void:
	city_label.text = "المدينة: " + active_city
	for child in faction_list.get_children():
		child.queue_free()
	var factions: Array = faction_manager.call("get_city_factions", active_city)
	for faction_value in factions:
		var faction: Dictionary = faction_value
		var faction_id := str(faction.get("id", ""))
		var card := PanelContainer.new()
		faction_list.add_child(card)
		var details := VBoxContainer.new()
		card.add_child(details)
		var title := Label.new()
		title.text = str(faction.get("name", "فصيل"))
		title.add_theme_font_size_override("font_size", 16)
		details.add_child(title)
		var info := Label.new()
		info.text = "الحي: %s | النفوذ: %d | الحرارة: %d | سمعتك: %d" % [
			str(faction.get("district", "")),
			int(faction.get("influence", 0)),
			int(faction.get("heat", 0)),
			int(faction_manager.call("get_player_standing", faction_id))
		]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(info)
		var rivals: Array = faction.get("rivals", [])
		var rival_names := PackedStringArray()
		for rival_id in rivals:
			var rival: Dictionary = faction_manager.call("get_faction", str(rival_id))
			rival_names.append(str(rival.get("name", rival_id)))
		var rivals_label := Label.new()
		rivals_label.text = "الخصومات: " + ("، ".join(rival_names) if not rival_names.is_empty() else "لا توجد خصومة مسجلة")
		rivals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(rivals_label)
		var issue_button := Button.new()
		issue_button.text = "طلب عقد من هذا الفصيل"
		issue_button.pressed.connect(_issue_contract.bind(faction_id))
		details.add_child(issue_button)
	_refresh_contracts()

func _issue_contract(faction_id: String) -> void:
	var index := objective_select.selected
	if index < 0 or index >= OBJECTIVES.size():
		status_label.text = "اختر نوع العقد أولاً."
		return
	var objective_id := str(OBJECTIVES[index]["id"])
	var result: Dictionary = faction_manager.call("issue_player_contract", faction_id, objective_id)
	if bool(result.get("success", false)):
		status_label.text = "تم استلام عقد للاعب فقط. يجب تنفيذ الهدف داخل العالم؛ الشخصيات غير القابلة للعب لا تكمله نيابة عنك."
	else:
		status_label.text = "تعذر إصدار العقد: " + str(result.get("reason", "UNKNOWN_ERROR"))
	_refresh_contracts()

func _refresh_contracts() -> void:
	for child in contracts_list.get_children():
		child.queue_free()
	var contracts: Array = faction_manager.call("get_player_contracts")
	var city_contracts := 0
	for contract_value in contracts:
		var contract: Dictionary = contract_value
		var faction: Dictionary = faction_manager.call("get_faction", str(contract.get("faction_id", "")))
		if str(faction.get("city", "")) != active_city:
			continue
		city_contracts += 1
		var label := Label.new()
		label.text = "%s — %s | %s" % [
			str(faction.get("name", "فصيل")),
			str(contract.get("objective", "")),
			str(contract.get("status", ""))
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contracts_list.add_child(label)
	if city_contracts == 0:
		var empty := Label.new()
		empty.text = "لا توجد عقود مسجلة لك في هذه المدينة."
		contracts_list.add_child(empty)
