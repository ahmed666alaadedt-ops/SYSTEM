extends CanvasLayer
class_name SYSTEMShoppingTowerMenu

signal item_purchased(item_id: String, item_name: String, price: int)

const CATALOG := [
	{"id": "baghdad_tower_emblem", "name": "شارة أبراج بغداد", "description": "شارة تذكارية تحمل هوية مجمّع الأبراج.", "price": 80},
	{"id": "hunter_association_patch", "name": "رقعة نقابة الصيادين", "description": "قطعة تذكارية من متجر برج التسوق.", "price": 120},
	{"id": "system_city_poster", "name": "ملصق مدينة SYSTEM", "description": "ملصق فني تذكاري للمدينة الحديثة.", "price": 160},
	{"id": "baghdad_architecture_model", "name": "مجسم بغداد المصغر", "description": "مجسم تذكاري لمعالم بغداد داخل العالم.", "price": 260},
	{"id": "five_towers_collectors_set", "name": "مجموعة الأبراج الخمسة", "description": "مجموعة تذكارية للأبراج المتصلة.", "price": 420}
]

var wallet: Node
var progression: Node
var panel: PanelContainer
var balance_label: Label
var status_label: Label
var item_list: VBoxContainer
var active_view := "overview"


func setup(p_wallet: Node, p_progression: Node) -> void:
	wallet = p_wallet
	progression = p_progression


func _ready() -> void:
	layer = 23
	_build_interface()


func get_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in CATALOG:
		result.append(item.duplicate(true))
	return result


func open_service_view(service_id: String) -> void:
	if not is_instance_valid(panel):
		return
	if service_id.ends_with("_1"):
		active_view = "catalog"
	elif service_id.ends_with("_2"):
		active_view = "collection"
	else:
		active_view = "overview"
	_refresh_view()
	panel.show()


func close_panel() -> void:
	if is_instance_valid(panel):
		panel.hide()


func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	panel = PanelContainer.new()
	panel.position = Vector2(14.0, 92.0)
	panel.size = Vector2(350.0, 520.0)
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "متجر برج التسوق — بغداد"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)
	balance_label = Label.new()
	content.add_child(balance_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	item_list = VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 7)
	scroll.add_child(item_list)
	panel.hide()


func _refresh_view() -> void:
	if not is_instance_valid(wallet) or not is_instance_valid(progression):
		status_label.text = "المتجر غير متصل بمحفظة اللاعب أو حقيبته."
		return
	balance_label.text = "رصيدك: %s SYSTEM Credits" % String.num_int64(int(wallet.call("get_balance")))
	for child in item_list.get_children():
		child.queue_free()
	if active_view == "overview":
		status_label.text = "متجر تذكارات محلي. المشتريات تُحفظ في حقيبتك ولا تمنح أفضلية قتالية."
	elif active_view == "catalog":
		status_label.text = "كتالوج المقتنيات المتاحة للشراء."
	else:
		status_label.text = "مقتنياتك المسجلة في حقيبة اللاعب."
	if active_view == "collection":
		_show_owned_items()
	else:
		_show_catalog_items()


func _show_catalog_items() -> void:
	for item in CATALOG:
		var row := PanelContainer.new()
		item_list.add_child(row)
		var column := VBoxContainer.new()
		row.add_child(column)
		var title := Label.new()
		title.text = "%s — %s رصيد" % [str(item["name"]), String.num_int64(int(item["price"]))]
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(title)
		var description := Label.new()
		description.text = str(item["description"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(description)
		var count := int(progression.call("get_item_count", str(item["id"])))
		var owned := Label.new()
		owned.text = "الكمية في الحقيبة: %d" % count
		column.add_child(owned)
		var buy_button := Button.new()
		buy_button.text = "شراء"
		buy_button.pressed.connect(_purchase_item.bind(str(item["id"])))
		column.add_child(buy_button)


func _show_owned_items() -> void:
	var found := false
	for item in CATALOG:
		var count := int(progression.call("get_item_count", str(item["id"])))
		if count <= 0:
			continue
		found = true
		var row := Label.new()
		row.text = "%s × %d" % [str(item["name"]), count]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_list.add_child(row)
	if not found:
		var empty := Label.new()
		empty.text = "لم تشترِ أي مقتنى من المتجر بعد."
		item_list.add_child(empty)


func _purchase_item(item_id: String) -> void:
	var selected: Dictionary = {}
	for item in CATALOG:
		if str(item["id"]) == item_id:
			selected = item
			break
	if selected.is_empty():
		status_label.text = "هذا المنتج غير موجود في الكتالوج."
		return
	var price := int(selected["price"])
	var payment: Dictionary = wallet.call("spend_currency", price, "baghdad_shopping_tower")
	if not bool(payment.get("success", false)):
		status_label.text = "رصيدك غير كافٍ لشراء هذا المقتنى."
		return
	if not bool(progression.call("add_item", item_id, 1)):
		wallet.call("credit_currency", price, "shopping_tower_purchase_refund")
		status_label.text = "تعذرت إضافة المقتنى إلى الحقيبة؛ أُعيد المبلغ إلى محفظتك."
		_refresh_view()
		return
	item_purchased.emit(item_id, str(selected["name"]), price)
	status_label.text = "تم شراء %s وإضافته إلى حقيبتك." % str(selected["name"])
	_refresh_view()
