extends CanvasLayer
class_name SystemRareAntiquesMarketUI

var market: Node
var wallet: Node
var panel: PanelContainer
var balance_label: Label
var status_label: Label
var lots_list: VBoxContainer
var catalogue_list: VBoxContainer
var bid_amount_input: SpinBox
var selected_auction_id := ""

func setup(p_market: Node, p_wallet: Node) -> void:
	market = p_market
	wallet = p_wallet

func _ready() -> void:
	layer = 24
	_build_interface()

func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	var open_button := Button.new()
	open_button.text = "سوق التحف النادرة"
	open_button.position = Vector2(18, 165)
	open_button.custom_minimum_size = Vector2(210, 54)
	root.add_child(open_button)
	open_button.pressed.connect(open_market)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8.0
	panel.offset_top = 80.0
	panel.offset_right = -8.0
	panel.offset_bottom = -80.0
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "بازار بغداد للتحف النادرة"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(close_market)
	header.add_child(close_button)
	balance_label = Label.new()
	content.add_child(balance_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var sections := VBoxContainer.new()
	sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_theme_constant_override("separation", 8)
	scroll.add_child(sections)
	var auction_heading := Label.new()
	auction_heading.text = "المزادات المفتوحة"
	auction_heading.add_theme_font_size_override("font_size", 16)
	sections.add_child(auction_heading)
	lots_list = VBoxContainer.new()
	lots_list.add_theme_constant_override("separation", 6)
	sections.add_child(lots_list)
	var separator := HSeparator.new()
	sections.add_child(separator)
	var catalogue_heading := Label.new()
	catalogue_heading.text = "دليل القطع وتاريخها"
	catalogue_heading.add_theme_font_size_override("font_size", 16)
	sections.add_child(catalogue_heading)
	catalogue_list = VBoxContainer.new()
	catalogue_list.add_theme_constant_override("separation", 5)
	sections.add_child(catalogue_list)
	var bid_row := HBoxContainer.new()
	content.add_child(bid_row)
	bid_amount_input = SpinBox.new()
	bid_amount_input.min_value = 1
	bid_amount_input.max_value = 1000000
	bid_amount_input.step = 50
	bid_amount_input.value = 500
	bid_amount_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bid_row.add_child(bid_amount_input)
	var bid_button := Button.new()
	bid_button.text = "تأكيد المزايدة"
	bid_button.pressed.connect(_place_selected_bid)
	bid_row.add_child(bid_button)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "اختر مزاداً ثم أدخل مبلغ المزايدة."
	content.add_child(status_label)
	panel.hide()

func open_market() -> void:
	if not is_instance_valid(panel):
		return
	panel.show()
	refresh_market()

func close_market() -> void:
	if is_instance_valid(panel):
		panel.hide()

func refresh_market() -> void:
	if not is_instance_valid(market):
		status_label.text = "نظام سوق التحف غير متاح."
		return
	var board: Dictionary = market.call("get_market_board")
	balance_label.text = "رصيدك: %s SYSTEM Credits" % _format_number(int(board.get("balance", 0)))
	selected_auction_id = ""
	for child in lots_list.get_children():
		child.queue_free()
	var auctions: Array = board.get("auctions", [])
	if auctions.is_empty():
		var empty := Label.new()
		empty.text = "لا توجد مزادات مفتوحة حالياً. تفقد السوق لاحقاً."
		lots_list.add_child(empty)
	else:
		for auction_value in auctions:
			var auction: Dictionary = auction_value
			var auction_id := str(auction.get("id", ""))
			var item_id := str(auction.get("item_id", ""))
			var item: Dictionary = market.call("get_item_details", item_id)
			var card := PanelContainer.new()
			lots_list.add_child(card)
			var details := VBoxContainer.new()
			card.add_child(details)
			var name_label := Label.new()
			name_label.text = str(auction.get("item_name", item_id))
			name_label.add_theme_font_size_override("font_size", 15)
			details.add_child(name_label)
			var info := Label.new()
			var remaining := maxi(0, int(auction.get("ends_at", 0)) - int(Time.get_unix_time_from_system()))
			info.text = "الندرة: %s | أعلى مزايدة: %s | المتبقي: %d ث" % [
				str(item.get("rarity", "غير مصنف")),
				_format_number(int(auction.get("current_bid", 0))),
				remaining
			]
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_child(info)
			var select_button := Button.new()
			select_button.text = "اختيار هذا المزاد"
			select_button.pressed.connect(_select_auction.bind(auction_id, int(auction.get("current_bid", 0)) + 50))
			details.add_child(select_button)
	var catalogue: Dictionary = board.get("catalogue", {})
	for child in catalogue_list.get_children():
		child.queue_free()
	for item_id in catalogue:
		var item: Dictionary = catalogue[item_id]
		var entry := Label.new()
		entry.text = "%s — %s\n%s\nالمصدر: %s" % [
			str(item.get("name", item_id)),
			str(item.get("rarity", "")),
			str(item.get("era", "")),
			str(item.get("provenance", "قيد التوثيق"))
		]
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		catalogue_list.add_child(entry)
	if selected_auction_id.is_empty() and not auctions.is_empty():
		_select_auction(str(auctions[0].get("id", "")), int(auctions[0].get("current_bid", 0)) + 50)

func _select_auction(auction_id: String, suggested_bid: int) -> void:
	selected_auction_id = auction_id
	bid_amount_input.value = suggested_bid
	status_label.text = "تم اختيار المزاد. المزايدة تخص حساب اللاعب المحلي."

func _place_selected_bid() -> void:
	if selected_auction_id.is_empty():
		status_label.text = "اختر مزاداً أولاً."
		return
	var result: Dictionary = market.call("place_bid", selected_auction_id, "local_player", int(bid_amount_input.value))
	if bool(result.get("success", false)):
		status_label.text = "تم تسجيل مزايدتك وحجز الرصيد محلياً."
	else:
		var reason := str(result.get("reason", "UNKNOWN_ERROR"))
		match reason:
			"INSUFFICIENT_FUNDS":
				status_label.text = "رصيدك لا يكفي لهذه المزايدة."
			"BID_MUST_EXCEED_CURRENT":
				status_label.text = "يجب أن تكون المزايدة أعلى من السعر الحالي."
			"AUCTION_CLOSED":
				status_label.text = "انتهى المزاد. حدّث القائمة لاختيار مزاد آخر."
			"SELLER_CANNOT_BID":
				status_label.text = "لا يمكنك المزايدة على قطعتك الخاصة."
			_:
				status_label.text = "تعذرت المزايدة: " + reason
	refresh_market()

func _format_number(value: int) -> String:
	return String.num_int64(value)
