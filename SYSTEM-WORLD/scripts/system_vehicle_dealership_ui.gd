extends CanvasLayer
class_name SystemVehicleDealershipUI

const CatalogScript = preload("res://scripts/system_vehicle_catalog.gd")

var garage_manager: Variant
var runtime_manager
var root_panel: PanelContainer
var balance_label: Label
var status_label: Label
var list_container: VBoxContainer
var scroll_container: ScrollContainer
var selected_vehicle_id := ""
var preview_body: MeshInstance3D
var preview_cabin: MeshInstance3D
var preview_body_material: StandardMaterial3D
var preview_cabin_material: StandardMaterial3D
var preview_status: Label

func setup(garage: Variant, runtime) -> void:
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

	_build_3d_preview(outer)
	_build_paint_palette(outer)

	var scroll := ScrollContainer.new()
	scroll_container = scroll
	scroll.custom_minimum_size = Vector2(0, 155)
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
	scroll_container.custom_minimum_size.y = maxf(75.0, panel_height - 390.0)
	_refresh_catalog()
	status_label.text = "اختر مركبتك. الشراء والحفظ حالياً محليان على هذا الجهاز."
	_update_vehicle_preview()
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
		details.text = "%s\n%s | %s\n%s | %s | %s" % [str(data.get("name", vehicle_id)), str(data.get("model_class", data.get("category", "car"))), str(data.get("brand_reference", "SYSTEM vehicle market")), price_text, ownership, "سباق" if str(data.get("category", "")).begins_with("race_") else "سوق عالمي"]
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.custom_minimum_size = Vector2(0, 68)
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

	_update_vehicle_preview()

func _on_select_vehicle(vehicle_id: String) -> void:
	var result := garage_manager.set_active_vehicle(vehicle_id)
	if bool(result.get("success", false)):
		selected_vehicle_id = vehicle_id
		_update_vehicle_preview()
		status_label.text = "تم تحديد المركبة. اضغط استلام وقيادة."
	_refresh_catalog()

func _on_purchase_vehicle(vehicle_id: String) -> void:
	var result := garage_manager.purchase_vehicle(vehicle_id)
	if bool(result.get("success", false)):
		garage_manager.set_active_vehicle(vehicle_id)
		selected_vehicle_id = vehicle_id
		_update_vehicle_preview()
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

func _build_3d_preview(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "معاينة المركبة ثلاثية الأبعاد"
	parent.add_child(heading)
	var preview_container := SubViewportContainer.new()
	preview_container.custom_minimum_size = Vector2(0, 138)
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.stretch = true
	parent.add_child(preview_container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 220)
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	preview_container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var camera_3d := Camera3D.new()
	camera_3d.position = Vector3(4.2, 2.8, 5.6)
	camera_3d.look_at_from_position(camera_3d.position, Vector3(0.0, 0.25, 0.0), Vector3.UP)
	camera_3d.current = true
	world.add_child(camera_3d)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	light.light_energy = 1.5
	world.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.0, 2.0, 2.0)
	fill.light_energy = 0.7
	world.add_child(fill)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(12.0, 9.0)
	floor.mesh = floor_mesh
	floor.position.y = -0.48
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.055, 0.075, 0.095)
	floor_material.metallic = 0.35
	floor.material_override = floor_material
	world.add_child(floor)
	var model := Node3D.new()
	world.add_child(model)
	preview_body = MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.9, 0.62, 4.0)
	preview_body.mesh = body_mesh
	preview_body.position.y = 0.0
	preview_body_material = StandardMaterial3D.new()
	preview_body_material.metallic = 0.62
	preview_body_material.roughness = 0.25
	preview_body.material_override = preview_body_material
	model.add_child(preview_body)
	preview_cabin = MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.48, 0.72, 1.85)
	preview_cabin.mesh = cabin_mesh
	preview_cabin.position = Vector3(0.0, 0.62, -0.25)
	preview_cabin_material = StandardMaterial3D.new()
	preview_cabin_material.albedo_color = Color(0.045, 0.075, 0.095)
	preview_cabin_material.metallic = 0.48
	preview_cabin_material.roughness = 0.2
	preview_cabin.material_override = preview_cabin_material
	model.add_child(preview_cabin)
	for x in [-0.98, 0.98]:
		for z in [-1.28, 1.28]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(x, -0.28, z)
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color(0.025, 0.028, 0.032)
			wheel.material_override = rubber
			model.add_child(wheel)
	preview_status = Label.new()
	preview_status.text = "نموذج عرض إجرائي أولي — ليس موديل السيارة النهائي."
	preview_status.add_theme_font_size_override("font_size", 11)
	parent.add_child(preview_status)

func _build_paint_palette(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "لون الطلاء"
	parent.add_child(heading)
	var palette := HBoxContainer.new()
	palette.add_theme_constant_override("separation", 7)
	parent.add_child(palette)
	var paints := [
		{"name":"أزرق","color":Color("#1479C8")},
		{"name":"أحمر","color":Color("#B83232")},
		{"name":"أسود","color":Color("#20252B")},
		{"name":"أبيض","color":Color("#E7E9EC")},
		{"name":"ذهبي","color":Color("#C69A42")}
	]
	for paint in paints:
		var swatch := Button.new()
		swatch.text = str(paint["name"])
		swatch.custom_minimum_size = Vector2(52, 32)
		var style := StyleBoxFlat.new()
		style.bg_color = paint["color"]
		style.set_corner_radius_all(5)
		swatch.add_theme_stylebox_override("normal", style)
		var hover_style := style.duplicate() as StyleBoxFlat
		hover_style.border_width_left = 2
		hover_style.border_width_right = 2
		hover_style.border_width_top = 2
		hover_style.border_width_bottom = 2
		hover_style.border_color = Color.WHITE
		swatch.add_theme_stylebox_override("hover", hover_style)
		swatch.pressed.connect(_on_paint_selected.bind(paint["color"]))
		palette.add_child(swatch)

func _on_paint_selected(color: Color) -> void:
	if selected_vehicle_id.is_empty():
		status_label.text = "حدد مركبة أولاً حتى تحفظ لونها."
		return
	garage_manager.set_vehicle_color(selected_vehicle_id, color)
	runtime_manager.apply_vehicle_paint(selected_vehicle_id, color)
	_update_vehicle_preview()
	status_label.text = "تم حفظ لون المركبة محلياً: " + color.to_html(false).to_upper()

func _update_vehicle_preview() -> void:
	if preview_body_material == null:
		return
	var color := garage_manager.get_vehicle_color(selected_vehicle_id) if not selected_vehicle_id.is_empty() else Color(0.08, 0.28, 0.48)
	preview_body_material.albedo_color = color
	if preview_status != null:
		preview_status.text = "المركبة المحددة: " + (selected_vehicle_id if not selected_vehicle_id.is_empty() else "لم يتم التحديد") + " | معاينة إجرائية أولية"

func _format_number(value: int) -> String:
	return str(value)
