extends CanvasLayer
class_name SYSTEMNenUI

var nen_manager: Node
var panel: PanelContainer
var summary: Label
var status: Label
var technique_input: LineEdit
var vow_input: LineEdit
var buttons: Dictionary = {}


func setup(manager: Node) -> void:
	nen_manager = manager
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var open_button := Button.new()
	open_button.text = "قوة النِن"
	open_button.position = Vector2(16, 68)
	open_button.custom_minimum_size = Vector2(150, 44)
	root.add_child(open_button)
	open_button.pressed.connect(_toggle_panel)

	panel = PanelContainer.new()
	panel.position = Vector2(12, 120)
	panel.size = Vector2(350, 520)
	panel.custom_minimum_size = Vector2(300, 420)
	panel.visible = false
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var heading := Label.new()
	heading.text = "SYSTEM — اكتشاف وتطوير النِن"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	var discovery := Button.new()
	discovery.text = "تأمل واكتساب بصيرة"
	column.add_child(discovery)
	discovery.pressed.connect(_on_discovery)
	for item in [
		["ten", "تدريب TEN — تثبيت الهالة"],
		["ren", "تدريب REN — رفع تدفق الهالة"],
		["zetsu", "تدريب ZETSU — إخفاء الهالة"]
	]:
		var button := Button.new()
		button.text = str(item[1])
		column.add_child(button)
		button.pressed.connect(_on_train.bind(str(item[0])))
		buttons[str(item[0])] = button
	technique_input = LineEdit.new()
	technique_input.placeholder_text = "اسم أسلوبك الشخصي (اختياري)"
	column.add_child(technique_input)
	vow_input = LineEdit.new()
	vow_input.placeholder_text = "شرط/قيد تختاره لأسلوبك (اختياري)"
	column.add_child(vow_input)
	var create_button := Button.new()
	create_button.text = "إنشاء أسلوب HATSU الشخصي"
	column.add_child(create_button)
	create_button.pressed.connect(_on_create_technique)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	column.add_child(close_button)
	close_button.pressed.connect(func(): panel.hide())
	_refresh()


func _toggle_panel() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_refresh()


func _refresh() -> void:
	if not is_instance_valid(nen_manager):
		return
	var state: Dictionary = nen_manager.call("get_character_state", "local_player")
	var discovered := bool(state.get("discovered", false))
	var training: Dictionary = state.get("training", {})
	var affinity := str(state.get("affinity", ""))
	var affinity_text := str(nen_manager.call("get_affinity_ar", "local_player"))
	summary.text = "الحالة: %s\nمراحل الاكتشاف: %d/3 | البصيرة: %d/3\nميلك: %s\nتحكم الهالة: %d | السعة: %d\nTEN: %d | REN: %d | ZETSU: %d\nأسلوبك: %s\n\nكل شخصية لها ميل مختلف، ولا تُفتح القوة تلقائياً." % [
		"مكتشفة" if discovered else "لم تُكتشف بعد",
		int(state.get("discovery_stage", 0)),
		int(state.get("insight", 0)),
		affinity_text,
		int(state.get("aura_control", 0)),
		int(state.get("aura_capacity", 0)),
		int(training.get("ten", 0)),
		int(training.get("ren", 0)),
		int(training.get("zetsu", 0)),
		str(state.get("technique", "لم يُنشأ"))
	]
	for key in buttons:
		buttons[key].disabled = not discovered
	technique_input.editable = discovered and not bool(state.get("technique_unlocked", false))
	vow_input.editable = technique_input.editable


func _on_discovery() -> void:
	var result: Dictionary = nen_manager.call("add_discovery_insight", "local_player", "deep_meditation")
	status.text = "اكتشاف النِن: %s" % str(result)
	_refresh()


func _on_train(discipline: String) -> void:
	var result: Dictionary = nen_manager.call("train", "local_player", discipline, 1)
	status.text = "نتيجة التدريب: %s" % str(result)
	_refresh()


func _on_create_technique() -> void:
	var result: Dictionary = nen_manager.call("create_personal_technique", "local_player", technique_input.text, vow_input.text)
	status.text = "أسلوب HATSU: %s" % str(result)
	_refresh()
