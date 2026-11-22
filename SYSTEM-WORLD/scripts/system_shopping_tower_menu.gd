extends CanvasLayer
class_name SYSTEMShoppingTowerMenu

signal item_purchased(item_id: String, item_name: String, price: int)

const CATALOG := [
	{"id":"baghdad_tower_emblem","name":"شارة أبراج بغداد","description":"شارة تذكارية تحمل هوية مجمّع الأبراج.","price":80,"category":"souvenir"},
	{"id":"hunter_association_patch","name":"رقعة نقابة الصيادين","description":"قطعة تذكارية من متجر البرج.","price":120,"category":"souvenir"},
	{"id":"system_city_poster","name":"ملصق مدينة SYSTEM","description":"ملصق فني تذكاري للمدينة الحديثة.","price":160,"category":"souvenir"},
	{"id":"baghdad_architecture_model","name":"مجسم بغداد المصغر","description":"مجسم تذكاري لمعالم بغداد داخل العالم.","price":260,"category":"souvenir"},
	{"id":"five_towers_collectors_set","name":"مجموعة الأبراج الخمسة","description":"مجموعة تذكارية للأبراج المتصلة.","price":420,"category":"souvenir"},
	{"id":"armory_sidearm","name":"مسدس SYSTEM","description":"سلاح ناري جانبي من فئة الأسلحة الخفيفة.","price":650,"category":"weapon"},
	{"id":"armory_assault_rifle","name":"بندقية هجومية","description":"سلاح ناري متوسط المدى للاستخدام الميداني داخل اللعبة.","price":1450,"category":"weapon"},
	{"id":"armory_precision_rifle","name":"بندقية قنص","description":"سلاح دقيق بعيد المدى.","price":1850,"category":"weapon"},
	{"id":"armory_scattergun","name":"بندقية خرطوش","description":"سلاح ناري قصير المدى.","price":1250,"category":"weapon"},
	{"id":"armory_support_gun","name":"رشاش دعم","description":"سلاح آلي ثقيل ضمن فئة أسلحة الدعم.","price":2200,"category":"weapon"},
	{"id":"armory_energy_rifle","name":"بندقية طاقة","description":"سلاح طاقة مستقبلي من عتاد SYSTEM.","price":2800,"category":"weapon"},
	{"id":"armory_long_sword","name":"سيف طويل","description":"سيف قتالي متوازن.","price":900,"category":"weapon"},
	{"id":"armory_dual_daggers","name":"خنجران مزدوجان","description":"سلاحان خفيفان للحركة السريعة.","price":720,"category":"weapon"},
	{"id":"armory_spear","name":"رمح قتالي","description":"سلاح اشتباك بمدى أطول.","price":840,"category":"weapon"},
	{"id":"armory_battle_axe","name":"فأس معركة","description":"سلاح ثقيل قوي الضربات.","price":1100,"category":"weapon"},
	{"id":"armory_recurve_bow","name":"قوس مركب","description":"قوس للرماية المتوسطة والبعيدة.","price":980,"category":"weapon"},
	{"id":"armory_crossbow","name":"قوس نشاب","description":"سلاح رماية ميكانيكي.","price":1150,"category":"weapon"},
	{"id":"armory_arrow_bundle","name":"حزمة سهام","description":"ذخيرة للأقواس.","price":90,"category":"weapon"},
	{"id":"nen_awakening_vial","name":"قارورة إيقاظ النِن","description":"تمنح بصيرة واحدة نحو اكتشاف الهالة؛ يلزم التدرج وإكمال ثلاث نقاط بصيرة، ولا تفتح القوة تلقائياً.","price":500,"category":"potion"},
	{"id":"nen_control_elixir","name":"إكسير التحكم بالهالة","description":"يساعد الشخصية التي اكتشفت النِن على تطوير تدريب TEN.","price":720,"category":"potion"}
]

var wallet: Node
var progression: Node
var nen_manager: Node
var panel: PanelContainer
var balance_label: Label
var status_label: Label
var item_list: VBoxContainer
var active_view := "weapons"


func setup(p_wallet: Node, p_progression: Node, p_nen_manager: Node = null) -> void:
	wallet = p_wallet
	progression = p_progression
	nen_manager = p_nen_manager


func _ready() -> void:
	layer = 23
	_build_interface()


func get_catalog() -> Array[Dictionary]:
	# Preserve the original five-item local collectible catalog API for existing callers.
	var result: Array[Dictionary] = []
	for item in CATALOG:
		if str(item.get("category", "")) == "souvenir":
			result.append(item.duplicate(true))
	return result


func get_full_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in CATALOG:
		result.append(item.duplicate(true))
	return result


func open_service_view(service_id: String) -> void:
	if not is_instance_valid(panel):
		return
	if service_id.ends_with("_3"):
		active_view = "weapons"
	elif service_id.ends_with("_4"):
		active_view = "potions"
	elif service_id.ends_with("_2"):
		active_view = "collection"
	else:
		active_view = "souvenir"
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
	title.text = "برج الأسلحة وإيقاظ النِن — بغداد"
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
		item_list.remove_child(child)
		child.queue_free()
	match active_view:
		"weapons":
			status_label.text = "معرض الأسلحة: تُضاف المشتريات إلى حقيبتك. ربط التجهيز والقتال الفعلي مرحلة مستقلة."
		"potions":
			status_label.text = "مختبر الجرعات: قارورة الإيقاظ تمنح بصيرة تدريجية، ولا تتجاوز شروط نظام النِن."
		"souvenir":
			status_label.text = "سوق بغداد ومقتنيات المجمع؛ بقيت التجارة والمتاجر ضمن البرج."
		_:
			status_label.text = "مقتنياتك وجرعاتك المسجلة في حقيبة اللاعب."
	if active_view == "collection":
		_show_owned_items()
	else:
		_show_catalog_items()


func _show_catalog_items() -> void:
	var wanted_category := "weapon" if active_view == "weapons" else ("potion" if active_view == "potions" else "souvenir")
	for item in CATALOG:
		if str(item.get("category", "")) != wanted_category:
			continue
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
		var row := PanelContainer.new()
		item_list.add_child(row)
		var column := VBoxContainer.new()
		row.add_child(column)
		var label := Label.new()
		label.text = "%s × %d" % [str(item["name"]), count]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)
		var item_category := str(item.get("category", ""))
		if item_category == "weapon" and str(item["id"]) != "armory_arrow_bundle":
			var equipped_id := str(progression.call("get_equipped_weapon")) if progression.has_method("get_equipped_weapon") else ""
			var equip_button := Button.new()
			equip_button.text = "مجهز حالياً" if equipped_id == str(item["id"]) else "تجهيز السلاح"
			equip_button.disabled = equipped_id == str(item["id"])
			equip_button.pressed.connect(_equip_weapon.bind(str(item["id"])))
			column.add_child(equip_button)
		elif item_category == "potion":
			var use_button := Button.new()
			use_button.text = "استخدام الجرعة"
			use_button.pressed.connect(_use_potion.bind(str(item["id"])))
			column.add_child(use_button)
	if not found:
		var empty := Label.new()
		empty.text = "حقيبتك فارغة من مقتنيات هذا البرج."
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
	var payment: Dictionary = wallet.call("spend_currency", price, "baghdad_weapon_nen_tower")
	if not bool(payment.get("success", false)):
		status_label.text = "رصيدك غير كافٍ لشراء هذا المنتج."
		return
	if not bool(progression.call("add_item", item_id, 1)):
		wallet.call("credit_currency", price, "weapon_nen_tower_purchase_refund")
		_refresh_view()
		status_label.text = "تعذرت إضافة المنتج إلى الحقيبة؛ أُعيد المبلغ إلى محفظتك."
		return
	_refresh_view()
	status_label.text = "تم شراء %s وإضافته إلى حقيبتك." % str(selected["name"])
	item_purchased.emit(item_id, str(selected["name"]), price)



func _equip_weapon(item_id: String) -> void:
	if not progression.has_method("equip_weapon"):
		status_label.text = "نظام تجهيز الأسلحة غير متاح."
		return
	if not bool(progression.call("equip_weapon", item_id)):
		status_label.text = "لا تملك هذا السلاح أو لا يمكن تجهيزه."
		return
	_refresh_view()
	status_label.text = "تم تجهيز السلاح: %s" % item_id


func _use_potion(item_id: String) -> void:
	if not is_instance_valid(nen_manager):
		status_label.text = "نظام النِن غير متاح حالياً."
		return
	if not bool(progression.call("remove_item", item_id, 1)):
		status_label.text = "لا توجد جرعة متاحة في الحقيبة."
		return
	var result: Dictionary = {}
	if item_id == "nen_awakening_vial":
		result = nen_manager.call("add_discovery_insight", "local_player", "tower_awakening_potion")
	elif item_id == "nen_control_elixir":
		result = nen_manager.call("train", "local_player", "ten", 1)
	else:
		progression.call("add_item", item_id, 1)
		status_label.text = "هذه الجرعة غير معروفة."
		return
	if not bool(result.get("success", false)):
		progression.call("add_item", item_id, 1)
		status_label.text = "لم تُستخدم الجرعة: %s. أُعيدت إلى حقيبتك." % str(result.get("reason", "تعذر الاستخدام"))
		return
	_refresh_view()
	status_label.text = "نتيجة الجرعة: %s" % str(result)
