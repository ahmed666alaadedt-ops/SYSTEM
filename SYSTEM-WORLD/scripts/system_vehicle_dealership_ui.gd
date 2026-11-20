extends CanvasLayer
class_name SystemVehicleDealershipUI

const CatalogScript = preload("res://scripts/system_vehicle_catalog.gd")

var garage_manager: SystemPlayerVehicleManager
var runtime_manager
var root_panel: PanelContainer
var balance_label: Label
var status_label: Label
var list_container: VBoxContainer
var scroll_container: ScrollContainer
var selected_vehicle_id := ""

func setup(garage: SystemPlayerVehicleManager, runtime) -> void:
	garage_manager = garage
	runtime_manager = runtime
	_build_interface()
	visible = false

func _build_interface() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.05, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	root_panel = PanelContainer.new()
	root_panel.name = "VehicleShowroomPanel"
	root_panel.anchor_left = 0.5
	root_panel.anchor_top = 0.5
	root_panel.anchor_right = 0.5
	root_panel.anchor_bottom = 0.5
	root_panel.offset_left = -310
	root_panel.offset_top = -260
	root_panel.offset_right = 310
	root_panel.offset_bottom = 260
	add_child(root_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	root_panel.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "SYSTEM | معرض المركبات"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 23)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(close)
	header.add_child(close_button)

	balance_label = Label.new()
	balance_label.add_theme_font_size_override("font_size", 17)
	outer.add_child(balance_label)

	var hint := Label.new()
	hint.text = "اختر مركبة للشراء أو حدّد مركبة تمتلكها لاستلامها."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll_container = scroll
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	outer.add_child(status_label)

	var actions := HBoxContainer.new()
	outer.add_child(actions)
	var drive_button := Button.new()
	drive_button.text = "استلام وقيادة المركبة المحددة"
	drive_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drive_button.pressed.connect(_on_drive_pressed)
	actions.add_child(drive_button)
	var sell_button := Button.new()
	sell_button.text = "بيع المحددة"
	sell_button.pressed.connect(_on_sell_pressed)
	actions.add_child(sell_button)
	var store_button := Button.new()
	store_button.text = "إرجاع للمرآب"
	store_button.pressed.connect(_on_store_pressed)
	actions.add_child(store_button)

func open_showroom() -> void:
	if garage_manager == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_width := minf(620.0, maxf(300.0, viewport_size.x - 24.0))
	var panel_height := minf(520.0, maxf(260.0, viewport_size.y - 24.0))
	root_panel.offset_left = -panel_width * 0.5
	root_panel.offset_right = panel_width * 0.5
	root_panel.offset_top = -panel_height * 0.5
	root_panel.offset_bottom = panel_height * 0.5
	scroll_container.custom_minimum_size.y = maxf(110.0, panel_height - 225.0)
	_refresh_catalog()
	status_label.text = "اختر مركبتك. الشراء والحفظ حالياً محليان على هذا الجهاز."
	visible = true

func close() -> void:
	visible = false

func _refresh_catalog() -> void:
	for child in list_container.get_children():
		child.queue_free()
	var owned := garage_manager.get_garage()
	var catalog: Dictionary = CatalogScript.get_catalog()
	var ids: Array = catalog.keys()
	ids.sort()
	balance_label.text = "الرصيد: %s SYSTEM Credits" % _format_number(garage_manager.get_balance())
	if not owned.has(selected_vehicle_id):
		selected_vehicle_id = garage_manager.active_vehicle_id if owned.has(garage_manager.active_vehicle_id) else (str(owned[0]) if not owned.is_empty() else "")
	for value in ids:
		var vehicle_id := str(value)
		var data: Dictionary = catalog[vehicle_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list_container.add_child(row)
		var details := Label.new()
		var price := int(data.get("price", 0))
		var price_text := "غير متاح للبيع" if price <= 0 else _format_number(price) + " Credits"
		var ownership := "مملوكة" if owned.has(vehicle_id) else "غير مملوكة"
		details.text = "%s\n%s | %s | %s" % [str(data.get("name", vehicle_id)), str(data.get("category", "car")), price_text, ownership]
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.custom_minimum_size = Vector2(0, 54)
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(details)
		var action := Button.new()
		action.custom_minimum_size = Vector2(112, 42)
		if owned.has(vehicle_id):
			action.text = "تحديد" if selected_vehicle_id != vehicle_id else "محدد"
			action.disabled = selected_vehicle_id == vehicle_id
			action.pressed.connect(_on_select_vehicle.bind(vehicle_id))
		elif price > 0:
			action.text = "شراء"
			action.pressed.connect(_on_purchase_vehicle.bind(vehicle_id))
		else:
			action.text = "مقيدة"
			action.disabled = true
		row.add_child(action)

func _on_select_vehicle(vehicle_id: String) -> void:
	var result := garage_manager.set_active_vehicle(vehicle_id)
	if bool(result.get("success", false)):
		selected_vehicle_id = vehicle_id
		status_label.text = "تم تحديد المركبة. اضغط استلام وقيادة."
	_refresh_catalog()

func _on_purchase_vehicle(vehicle_id: String) -> void:
	var result := garage_manager.purchase_vehicle(vehicle_id)
	if bool(result.get("success", false)):
		garage_manager.set_active_vehicle(vehicle_id)
		selected_vehicle_id = vehicle_id
		status_label.text = "تم الشراء وحفظ الملكية محلياً. يمكنك استلام المركبة."
	else:
		var reason := str(result.get("reason", "PURCHASE_FAILED"))
		if reason == "INSUFFICIENT_CURRENCY":
			status_label.text = "الرصيد غير كافٍ. تحتاج %s Credits." % _format_number(int(result.get("required", 0)))
		elif reason == "ALREADY_OWNED":
			status_label.text = "هذه المركبة مملوكة لك بالفعل."
		else:
			status_label.text = "تعذر إتمام الشراء: " + reason
	_refresh_catalog()

func _on_drive_pressed() -> void:
	if selected_vehicle_id.is_empty():
		status_label.text = "اختر أو اشترِ مركبة أولاً."
		return
	var result: Dictionary = runtime_manager.spawn_selected_vehicle_and_enter(selected_vehicle_id)
	if bool(result.get("success", false)):
		close()
	else:
		status_label.text = _reason_text(str(result.get("reason", "UNKNOWN")))


func _on_sell_pressed() -> void:
	if selected_vehicle_id.is_empty():
		status_label.text = "حدد مركبة تملكها حتى تبيعها."
		return
	var result := garage_manager.sell_vehicle(selected_vehicle_id)
	if bool(result.get("success", false)):
		status_label.text = "تم بيع المركبة واسترجاع %s Credits." % _format_number(int(result.get("received", 0)))
		selected_vehicle_id = ""
	else:
		var reason := str(result.get("reason", "SALE_FAILED"))
		if reason == "RETURN_VEHICLE_TO_GARAGE_FIRST":
			status_label.text = "أرجع المركبة إلى المرآب قبل بيعها."
		elif reason == "NOT_OWNED":
			status_label.text = "هذه المركبة ليست ضمن ملكيتك."
		else:
			status_label.text = "تعذر بيع المركبة: " + reason
	_refresh_catalog()

func _on_store_pressed() -> void:
	var result: Dictionary = runtime_manager.store_parked_vehicle()
	if bool(result.get("success", false)):
		status_label.text = "تم إرجاع المركبة إلى المرآب."
		_refresh_catalog()
	else:
		status_label.text = _reason_text(str(result.get("reason", "UNKNOWN")))

func _reason_text(reason: String) -> String:
	match reason:
		"VEHICLE_ALREADY_SPAWNED":
			return "هناك مركبة مستلمة بالفعل. أرجعها إلى المرآب أولاً إذا تريد تبديلها."
		"VEHICLE_NOT_OWNED":
			return "لا تملك هذه المركبة."
		"UNKNOWN_VEHICLE":
			return "المركبة غير موجودة في الكتالوج."
		"VEHICLE_IN_USE":
			return "اخرج من المركبة قبل إرجاعها."
		"TOO_FAR_FROM_DEALERSHIP":
			return "اقترب من المعرض لإرجاع المركبة."
		_:
			return "تعذر تنفيذ الطلب: " + reason

func _format_number(value: int) -> String:
	return str(value)
