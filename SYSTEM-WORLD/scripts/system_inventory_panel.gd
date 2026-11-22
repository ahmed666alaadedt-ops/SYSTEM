extends CanvasLayer
class_name SYSTEMInventoryPanel

var progression: Node
var panel: PanelContainer
var item_list: Label


func setup(player_progression: Node) -> void:
	progression = player_progression


func _ready() -> void:
	layer = 20
	var toggle_button := Button.new()
	toggle_button.name = "InventoryToggle"
	toggle_button.text = "الحقيبة"
	toggle_button.position = Vector2(24.0, 24.0)
	toggle_button.size = Vector2(112.0, 48.0)
	toggle_button.pressed.connect(_toggle_panel)
	add_child(toggle_button)

	panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.position = Vector2(24.0, 82.0)
	panel.size = Vector2(300.0, 360.0)
	panel.visible = false
	add_child(panel)

	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "حقيبة اللاعب"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)

	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): panel.visible = false)
	column.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	item_list = Label.new()
	item_list.text = "الحقيبة فارغة"
	item_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(item_list)


func _toggle_panel() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		refresh_inventory()


func refresh_inventory() -> void:
	if not is_instance_valid(progression) or item_list == null:
		return
	var data: Dictionary = progression.call("get_progress_data")
	var items: Dictionary = data.get("inventory_items", {})
	var equipment: Dictionary = data.get("equipment_slots", {})
	var effects: Dictionary = data.get("active_elixir_effects", {})
	var upgrade_levels: Dictionary = data.get("equipment_upgrade_levels", {})
	var durability: Dictionary = data.get("equipment_durability", {})
	var lines := PackedStringArray()
	lines.append("المعدات المجهزة")
	for slot in equipment.keys():
		var item_id := str(equipment[slot])
		lines.append("%s: %s" % [str(slot), "غير مجهز" if item_id.is_empty() else item_id])
		if not item_id.is_empty():
			lines.append("  ترقية +%d | متانة %.0f/100" % [int(upgrade_levels.get(item_id, 0)), float(durability.get(item_id, 100.0))])
	lines.append("Nen: " + ("مفتوح — رتبة التحكم %d/5" % int(data.get("nen_control_rank", 0)) if bool(data.get("nen_unlocked", false)) else "غير مستيقظ"))
	lines.append("")
	lines.append("التأثيرات النشطة")
	if effects.is_empty():
		lines.append("لا توجد تأثيرات إكسير نشطة")
	else:
		for effect_id in effects.keys():
			var effect: Dictionary = effects[effect_id]
			lines.append("%s — %d ثانية" % [str(effect_id), int(ceil(float(effect.get("remaining_seconds", 0.0))))])
	lines.append("")
	lines.append("محتويات الحقيبة")
	if items.is_empty():
		lines.append("الحقيبة فارغة حالياً")
	else:
		for item_id in items.keys():
			lines.append("%s  × %d" % [str(item_id), int(items[item_id])])
	item_list.text = "\n".join(lines)
