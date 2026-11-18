extends CanvasLayer

# SYSTEM WORLD - Hunter Guild Operations Panel
# Runtime-built mobile-friendly UI. Connects to the guild gate manager.

var guild_manager: Node
var player_node: Node3D
var member_manager: Node
var panel: PanelContainer
var report_list: VBoxContainer
var detail_label: Label
var selected_gate_id := ""
var status_label: Label


func setup(manager: Node, player: Node3D, member_manager_node: Node = null) -> void:
	guild_manager = manager
	player_node = player
	member_manager = member_manager_node
	_build_interface()
	if is_instance_valid(guild_manager):
		if guild_manager.has_signal("gate_registered"):
			guild_manager.connect("gate_registered", Callable(self, "_refresh_reports"))
		if guild_manager.has_signal("gate_breached_report"):
			guild_manager.connect("gate_breached_report", Callable(self, "_on_alert"))
		if guild_manager.has_signal("city_alert_requested"):
			guild_manager.connect("city_alert_requested", Callable(self, "_on_alert"))
		if guild_manager.has_signal("gate_cleared"):
			guild_manager.connect("gate_cleared", Callable(self, "_refresh_reports"))
	_refresh_reports()


func _build_interface() -> void:
	var toggle := Button.new()
	toggle.name = "GuildToggle"
	toggle.text = "نقابة الصيادين"
	toggle.position = Vector2(18, 105)
	toggle.custom_minimum_size = Vector2(190, 48)
	toggle.add_theme_font_size_override("font_size", 18)
	add_child(toggle)
	toggle.pressed.connect(_toggle_panel)

	panel = PanelContainer.new()
	panel.name = "HunterGuildPanel"
	panel.visible = false
	panel.anchor_left = 0.04
	panel.anchor_top = 0.16
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.94
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "SYSTEM  /  نقابة الصيادين"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(_toggle_panel)
	header.add_child(close_button)

	status_label = Label.new()
	status_label.text = "سجل البوابات والعمليات"
	status_label.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	root.add_child(status_label)

	var split := VBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	report_list = VBoxContainer.new()
	report_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_list.add_theme_constant_override("separation", 7)
	scroll.add_child(report_list)

	var details := VBoxContainer.new()
	details.custom_minimum_size = Vector2(0, 175)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(details)
	var detail_title := Label.new()
	detail_title.text = "تفاصيل العملية"
	detail_title.add_theme_font_size_override("font_size", 18)
	details.add_child(detail_title)
	detail_label = Label.new()
	detail_label.text = "اختر بوابة من السجل"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(detail_label)

	var refresh_button := Button.new()
	refresh_button.text = "تحديث السجل"
	refresh_button.pressed.connect(_refresh_reports)
	root.add_child(refresh_button)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.09, 0.96)
	style.border_color = Color(0.12, 0.72, 0.92, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _toggle_panel() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_refresh_reports()


func _refresh_reports(_unused = null) -> void:
	if not is_instance_valid(report_list) or not is_instance_valid(guild_manager):
		return
	for child in report_list.get_children():
		child.queue_free()
	var reports: Array = guild_manager.call("get_all_reports")
	status_label.text = "عدد البوابات المسجلة: %d" % reports.size()
	if reports.is_empty():
		var empty_label := Label.new()
		empty_label.text = "لا توجد بوابات مسجلة حالياً"
		report_list.add_child(empty_label)
		return
	for report in reports:
		var gate_id := str(report.get("gate_id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s  |  رتبة %s  |  %s" % [
			gate_id,
			str(report.get("verified_rank", report.get("rank", "?"))),
			str(report.get("status", "discovered"))
		]
		button.pressed.connect(_select_gate.bind(gate_id))
		report_list.add_child(button)


func _select_gate(gate_id: String) -> void:
	selected_gate_id = gate_id
	if not is_instance_valid(guild_manager):
		return
	var report: Dictionary = guild_manager.call("get_gate_report", gate_id)
	if report.is_empty():
		return
	var rank_text := str(report.get("verified_rank", "غير مؤكدة - " + str(report.get("rank", "?"))))
	var reward: Dictionary = report.get("reward_preview", {})
	detail_label.text = "رقم التقرير: %s\nالبوابة: %s\nالمنطقة: %s\nالرتبة: %s\nالحالة: %s\nمؤشر الخطر: %s/100\nالفريق المقترح: %s\nالفريق الحالي: %s" % [
		str(report.get("report_id", "-")),
		gate_id,
		str(report.get("region", "-")),
		rank_text,
		str(report.get("status", "-")),
		str(report.get("risk_score", 0)),
		str(report.get("recommended_team_size", 3)),
		str(report.get("assigned_team", []).size())
	]
	if not reward.is_empty():
		detail_label.text += "\n\nمكافأة تقديرية: %s XP / %s Credits / %s سمعة" % [
			str(reward.get("guild_xp", 0)),
			str(reward.get("credits", 0)),
			str(reward.get("reputation", 0))
		]
	_add_detail_actions(report)


func _add_detail_actions(report: Dictionary) -> void:
	var parent := detail_label.get_parent()
	for child in parent.get_children():
		if child is Button:
			child.queue_free()
	var gate_id := str(report.get("gate_id", ""))
	var scan_button := Button.new()
	scan_button.text = "مسح الرتبة"
	scan_button.pressed.connect(_scan_selected)
	parent.add_child(scan_button)
	var report_button := Button.new()
	report_button.text = "إرسال بلاغ للنقابة"
	report_button.pressed.connect(_report_selected)
	parent.add_child(report_button)
	var reward_button := Button.new()
	reward_button.text = "عرض المكافأة التقديرية"
	reward_button.pressed.connect(_preview_reward)
	parent.add_child(reward_button)
	var team_button := Button.new()
	team_button.text = "اختيار أفضل فريق من أعضاء النقابة"
	team_button.pressed.connect(_assign_recommended_team)
	parent.add_child(team_button)
	var roster_button := Button.new()
	roster_button.text = "عرض أعضاء النقابة ورتبهم"
	roster_button.pressed.connect(_show_roster)
	parent.add_child(roster_button)
	var dispatch_button := Button.new()
	dispatch_button.text = "إرسال الفريق"
	dispatch_button.pressed.connect(_dispatch_selected)
	parent.add_child(dispatch_button)


func _scan_selected() -> void:
	if not is_instance_valid(player_node) or selected_gate_id.is_empty():
		return
	var result: Dictionary = guild_manager.call("scan_nearby_gate", selected_gate_id, player_node.global_position, 30.0)
	if result.is_empty():
		detail_label.text = "تعذر إجراء المسح"
	elif not bool(result.get("success", false)):
		detail_label.text = "المسح غير ناجح أو البوابة خارج مدى 30 متراً"
	else:
		detail_label.text = "نجح المسح. الرتبة المؤكدة: %s" % str(result.get("verified_rank", result.get("rank", "?")))
	_select_gate(selected_gate_id)


func _report_selected() -> void:
	if selected_gate_id.is_empty():
		return
	guild_manager.call("report_gate", selected_gate_id, "PLAYER")
	_select_gate(selected_gate_id)


func _preview_reward() -> void:
	if selected_gate_id.is_empty():
		return
	guild_manager.call("calculate_clear_reward", selected_gate_id, false)
	_select_gate(selected_gate_id)


func _assign_recommended_team() -> void:
	if selected_gate_id.is_empty() or not is_instance_valid(member_manager):
		return
	var report: Dictionary = guild_manager.call("get_gate_report", selected_gate_id)
	var wanted := int(report.get("recommended_team_size", 4))
	wanted = mini(wanted, 5)
	var team: Array[String] = member_manager.call("recommend_team", selected_gate_id, wanted)
	if team.is_empty():
		detail_label.text = "لا يوجد أعضاء متاحون بالرتب المناسبة لهذه البوابة"
		return
	guild_manager.call("assign_team", selected_gate_id, team)
	var summary: Dictionary = member_manager.call("get_team_summary", team)
	detail_label.text = "تم اختيار الفريق: %s\nالعدد: %d\nمتوسط الرتبة: %s\nقتال: %s | استطلاع: %s\nعلاج: %s | دعم: %s" % [
		str(team), team.size(), str(summary.get("average_rank", "F")),
		str(summary.get("combat", 0)), str(summary.get("scouting", 0)),
		str(summary.get("healing", 0)), str(summary.get("support", 0))
	]

func _show_roster() -> void:
	if not is_instance_valid(member_manager):
		return
	var roster: Array = member_manager.call("get_roster")
	var lines := ["أعضاء نقابة الصيادين:"]
	for member in roster:
		lines.append("%s | %s | %s | XP %s" % [
			str(member.get("name", "-")), str(member.get("rank", "F")),
			str(member.get("role", "fighter")), str(member.get("guild_xp", 0))
		])
	detail_label.text = "\n".join(lines)


func _dispatch_selected() -> void:
	if selected_gate_id.is_empty():
		return
	var result: Dictionary = guild_manager.call("dispatch_team", selected_gate_id)
	if result.is_empty():
		detail_label.text = "لا يمكن إرسال الفريق: جهّز الفريق أولاً"
	else:
		_select_gate(selected_gate_id)


func _on_alert(report: Dictionary) -> void:
	if is_instance_valid(status_label):
		status_label.text = "تحذير نقابة: بوابة %s في خطر!" % str(report.get("gate_id", "UNKNOWN"))
	if is_instance_valid(panel):
		panel.visible = true
