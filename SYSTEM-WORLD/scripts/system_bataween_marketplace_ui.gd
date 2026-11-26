extends CanvasLayer
class_name SYSTEMBataweenMarketplaceUI

var bridge: Node
var request_counter := 0
var pending_operations: Dictionary = {}
var owned_artifacts: Array = []
var active_listings: Array = []
var wallet_balance := 0
var wallet_reserved := 0
var selected_artifact_id := ""
var busy := false

var _panel: PanelContainer
var _wallet_label: Label
var _status_label: Label
var _listing_list: VBoxContainer
var _artifact_picker: OptionButton
var _price_input: LineEdit
var _sell_button: Button


func _ready() -> void:
	layer = 30
	_build_interface()
	visible = false
	bridge = get_node_or_null("/root/SYSTEMAndroidBridge")
	if bridge != null and bridge.has_signal("marketplace_result_received"):
		bridge.connect("marketplace_result_received", Callable(self, "_on_marketplace_result"))


func open_market() -> void:
	visible = true
	_refresh_market()


func close_market() -> void:
	visible = false


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "MarketplaceBackdrop"
	backdrop.color = Color(0.015, 0.02, 0.035, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_panel = PanelContainer.new()
	_panel.name = "BataweenMarketplacePanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-520.0, -330.0)
	_panel.custom_minimum_size = Vector2(1040.0, 660.0)
	add_child(_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	_panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "سوق البتاوين"
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var market_type := Label.new()
	market_type.name = "BataweenMarketplaceCategory"
	market_type.text = "سوق التحف والآثار — بيع وشراء بين اللاعبين"
	layout.add_child(market_type)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(close_market)
	header.add_child(close_button)

	_wallet_label = Label.new()
	_wallet_label.text = "رصيد SYSTEM: —"
	layout.add_child(_wallet_label)

	var sell_row := HBoxContainer.new()
	layout.add_child(sell_row)
	_artifact_picker = OptionButton.new()
	_artifact_picker.custom_minimum_size = Vector2(350.0, 48.0)
	_artifact_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_artifact_picker.item_selected.connect(_on_artifact_selected)
	sell_row.add_child(_artifact_picker)
	_price_input = LineEdit.new()
	_price_input.placeholder_text = "السعر"
	_price_input.custom_minimum_size = Vector2(150.0, 48.0)
	_price_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	sell_row.add_child(_price_input)
	_sell_button = Button.new()
	_sell_button.text = "اعرض قطعتي للبيع"
	_sell_button.pressed.connect(_create_listing)
	sell_row.add_child(_sell_button)

	_status_label = Label.new()
	_status_label.text = "جارٍ تجهيز السوق..."
	layout.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 450.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	_listing_list = VBoxContainer.new()
	_listing_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_listing_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_listing_list)


func _refresh_market() -> void:
	if bridge == null or not bridge.has_method("request_marketplace_operation"):
		_set_status("السوق يحتاج إلى جلسة Android موثقة واتصال Firebase.")
		return
	_request("wallet", {})
	_request("owned_artifacts", {})
	_request("browse_listings", {})


func _request(operation: String, payload: Dictionary) -> void:
	if bridge == null:
		_set_status("نقل سوق اللاعبين غير متاح على هذا التشغيل.")
		return
	request_counter += 1
	var request_id := "bataween_market_%d" % request_counter
	pending_operations[request_id] = operation
	var sent := bool(bridge.call("request_marketplace_operation", operation, payload, request_id))
	if not sent:
		pending_operations.erase(request_id)
		if operation in ["create_listing", "purchase_listing", "cancel_listing"]:
			busy = false
			_sell_button.disabled = _artifact_picker.item_count == 0
		var bridge_status: Dictionary = bridge.call("get_bridge_status") if bridge.has_method("get_bridge_status") else {}
		_set_status("تعذر الاتصال بسوق اللاعبين: " + str(bridge_status.get("last_error", "ANDROID_MARKETPLACE_TRANSPORT_UNAVAILABLE")))


func _on_marketplace_result(request_id: String, payload: Dictionary) -> void:
	if not pending_operations.has(request_id):
		return
	var operation := str(pending_operations[request_id])
	pending_operations.erase(request_id)
	if not bool(payload.get("success", false)):
		busy = false
		if _sell_button != null:
			_sell_button.disabled = _artifact_picker == null or _artifact_picker.item_count == 0
		_set_status("لم تكتمل العملية: " + str(payload.get("error", "MARKETPLACE_REQUEST_FAILED")))
		return
	var data: Dictionary = payload.get("data", {}) if payload.get("data", {}) is Dictionary else {}
	match operation:
		"wallet":
			wallet_balance = int(data.get("balance", 0))
			wallet_reserved = int(data.get("reservedBalance", 0))
			_wallet_label.text = "رصيد SYSTEM: %d | محجوز: %d | متاح: %d" % [
				wallet_balance, wallet_reserved, int(data.get("availableBalance", wallet_balance - wallet_reserved))
			]
		"owned_artifacts":
			owned_artifacts = data.get("artifacts", [])
			_render_owned_artifacts()
		"browse_listings":
			active_listings = data.get("listings", [])
			_render_listings()
		"create_listing":
			busy = false
			_set_status("تم إنشاء عرض البيع وحجز القطعة بأمان.")
			_price_input.text = ""
			_refresh_market()
		"purchase_listing":
			busy = false
			_set_status("اكتمل الشراء وانتقلت ملكية القطعة إلى حسابك.")
			_refresh_market()
		"cancel_listing":
			busy = false
			_set_status("تم إلغاء العرض وإرجاع القطعة إلى ملكيتك.")
			_refresh_market()


func _render_owned_artifacts() -> void:
	_artifact_picker.clear()
	selected_artifact_id = ""
	for artifact in owned_artifacts:
		if not artifact is Dictionary:
			continue
		var artifact_id := str(artifact.get("artifactId", ""))
		if artifact_id.is_empty():
			continue
		var label := "%s — %s" % [str(artifact.get("name", "قطعة أثرية")), str(artifact.get("rarity", "common"))]
		_artifact_picker.add_item(label)
		_artifact_picker.set_item_metadata(_artifact_picker.item_count - 1, artifact_id)
	if _artifact_picker.item_count > 0:
		_artifact_picker.select(0)
		selected_artifact_id = str(_artifact_picker.get_item_metadata(0))
	_sell_button.disabled = _artifact_picker.item_count == 0 or busy


func _on_artifact_selected(index: int) -> void:
	selected_artifact_id = str(_artifact_picker.get_item_metadata(index))


func _create_listing() -> void:
	if busy:
		return
	var price := _price_input.text.strip_edges().to_int()
	if selected_artifact_id.is_empty() or price <= 0:
		_set_status("اختر قطعة مملوكة لك واكتب سعراً صحيحاً.")
		return
	busy = true
	_sell_button.disabled = true
	_set_status("جارٍ إرسال عرض البيع إلى الخادم...")
	_request("create_listing", {
		"artifactId": selected_artifact_id,
		"price": price,
		"durationDays": 7
	})


func _render_listings() -> void:
	for child in _listing_list.get_children():
		child.queue_free()
	if active_listings.is_empty():
		var empty_label := Label.new()
		empty_label.text = "لا توجد عروض بيع نشطة حالياً."
		_listing_list.add_child(empty_label)
		return
	for listing in active_listings:
		if not listing is Dictionary:
			continue
		var card := PanelContainer.new()
		_listing_list.add_child(card)
		var row := HBoxContainer.new()
		card.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var name_label := Label.new()
		name_label.text = str(listing.get("name", "قطعة أثرية"))
		name_label.add_theme_font_size_override("font_size", 18)
		details.add_child(name_label)
		var meta_label := Label.new()
		meta_label.text = "%s | %s | %s" % [
			str(listing.get("civilization", "غير محدد")),
			str(listing.get("rarity", "common")),
			str(listing.get("condition", "غير محدد"))
		]
		details.add_child(meta_label)
		var authenticity_label := Label.new()
		authenticity_label.text = "الأصالة: " + str(listing.get("authenticity", "غير موثّق"))
		details.add_child(authenticity_label)
		var provenance_summary := str(listing.get("provenanceSummary", "")).strip_edges()
		if not provenance_summary.is_empty():
			var provenance_label := Label.new()
			provenance_label.text = "سجل المصدر: " + provenance_summary
			provenance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_child(provenance_label)
		var seller_label := Label.new()
		seller_label.text = "البائع: " + str(listing.get("sellerName", "لاعب"))
		details.add_child(seller_label)
		var listing_id := str(listing.get("listingId", ""))
		var action_button := Button.new()
		if bool(listing.get("isSeller", false)):
			action_button.text = "إلغاء العرض"
			action_button.disabled = busy
			action_button.pressed.connect(_cancel_listing.bind(listing_id))
		else:
			action_button.text = "%d SYSTEM — شراء" % int(listing.get("price", 0))
			action_button.disabled = busy
			action_button.pressed.connect(_purchase_listing.bind(listing_id))
		row.add_child(action_button)


func _cancel_listing(listing_id: String) -> void:
	if busy or listing_id.is_empty():
		return
	busy = true
	_set_status("جارٍ إلغاء العرض وإرجاع القطعة إلى ملكيتك...")
	_request("cancel_listing", {"listingId": listing_id})


func _purchase_listing(listing_id: String) -> void:
	if busy or listing_id.is_empty():
		return
	busy = true
	_set_status("جارٍ تأكيد الشراء مع الخادم...")
	_request("purchase_listing", {"listingId": listing_id})


func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message
