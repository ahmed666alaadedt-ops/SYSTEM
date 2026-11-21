extends CanvasLayer
class_name SYSTEMPowerTowerArenaUI

const LOCAL_PLAYER_ID := "local_player"
const SHOWCASE_FIGHTERS := ["arena_guest_alpha", "arena_guest_beta"]
const SHOWCASE_TEAMS := ["arena_team_alpha", "arena_team_beta"]

var arena_manager: Node
var panel: PanelContainer
var status_label: Label
var fighters_label: Label
var pool_label: Label
var feedback_label: Label
var fighter_choice: OptionButton
var match_type_choice: OptionButton
var bet_amount: SpinBox
var register_button: Button
var create_match_button: Button
var open_betting_button: Button
var place_bet_button: Button
var start_match_button: Button
var cancel_match_button: Button
var refresh_button: Button
var _registered := false
var _busy := false

func _ready() -> void:
	_build_interface()
	visible = false

func setup(manager: Node) -> void:
	arena_manager = manager
	if is_instance_valid(arena_manager):
		if arena_manager.has_signal("match_created"):
			var created_callback := Callable(self, "_on_match_created")
			if not arena_manager.match_created.is_connected(created_callback):
				arena_manager.match_created.connect(created_callback)
		if arena_manager.has_signal("crowd_cheered"):
			var cheer_callback := Callable(self, "_on_crowd_cheered")
			if not arena_manager.crowd_cheered.is_connected(cheer_callback):
				arena_manager.crowd_cheered.connect(cheer_callback)
		_refresh()

func show_arena(manager: Node = null) -> void:
	if manager != null:
		setup(manager)
	visible = true
	_refresh()

func hide_arena() -> void:
	visible = false

func _build_interface() -> void:
	layer = 30
	panel = PanelContainer.new()
	panel.name = "ArenaControlPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-430.0, 18.0)
	panel.size = Vector2(410.0, 620.0)
	panel.custom_minimum_size = Vector2(360.0, 560.0)
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 9)
	panel.add_child(outer)

	var heading := HBoxContainer.new()
	outer.add_child(heading)
	var title := Label.new()
	title.text = "SYSTEM | حلبة برج القوة"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 21)
	heading.add_child(title)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(hide_arena)
	heading.add_child(close_button)

	status_label = _make_label("لا يوجد نزال نشط", 15)
	outer.add_child(status_label)
	fighters_label = _make_label("المقاتلون: —", 14)
	outer.add_child(fighters_label)
	pool_label = _make_label("مجموع التوقعات: 0 SYSTEM_CREDITS", 14)
	outer.add_child(pool_label)

	var registration_title := _make_label("دخول المقاتلين", 16)
	outer.add_child(registration_title)
	register_button = Button.new()
	register_button.text = "سجّل كمقاتل — دخول مجاني"
	register_button.pressed.connect(_on_register_pressed)
	outer.add_child(register_button)

	var match_title := _make_label("نزالات استعراضية محلية", 16)
	outer.add_child(match_title)
	match_type_choice = OptionButton.new()
	match_type_choice.add_item("مواجهة فردية")
	match_type_choice.add_item("مواجهة فرق")
	outer.add_child(match_type_choice)
	var note := _make_label("النزال الاستعراضي يستخدم خصمين تجريبيين لعرض واجهة الجمهور؛ لا يمثل قتالاً فعلياً أو منافسة عبر الإنترنت.", 12)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(note)
	create_match_button = Button.new()
	create_match_button.text = "إنشاء نزال استعراضي"
	create_match_button.pressed.connect(_on_create_match_pressed)
	outer.add_child(create_match_button)
	open_betting_button = Button.new()
	open_betting_button.text = "فتح التوقعات"
	open_betting_button.pressed.connect(_on_open_betting_pressed)
	outer.add_child(open_betting_button)

	var betting_title := _make_label("توقعات المشجعين", 16)
	outer.add_child(betting_title)
	fighter_choice = OptionButton.new()
	fighter_choice.add_item("الخصم الأول")
	fighter_choice.add_item("الخصم الثاني")
	fighter_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(fighter_choice)
	bet_amount = SpinBox.new()
	bet_amount.min_value = 10
	bet_amount.max_value = 1000
	bet_amount.step = 10
	bet_amount.value = 50
	bet_amount.prefix = "المبلغ: "
	bet_amount.suffix = " SYSTEM_CREDITS"
	outer.add_child(bet_amount)
	place_bet_button = Button.new()
	place_bet_button.text = "تأكيد التوقع"
	place_bet_button.pressed.connect(_on_place_bet_pressed)
	outer.add_child(place_bet_button)

	start_match_button = Button.new()
	start_match_button.text = "قفل التوقعات وبدء حالة النزال"
	start_match_button.pressed.connect(_on_start_match_pressed)
	outer.add_child(start_match_button)
	cancel_match_button = Button.new()
	cancel_match_button.text = "إلغاء النزال وإرجاع المبالغ"
	cancel_match_button.pressed.connect(_on_cancel_match_pressed)
	outer.add_child(cancel_match_button)

	feedback_label = _make_label("العملة افتراضية ومحلية على هذا الجهاز فقط.", 12)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(feedback_label)
	refresh_button = Button.new()
	refresh_button.text = "تحديث حالة الحلبة"
	refresh_button.pressed.connect(_refresh)
	outer.add_child(refresh_button)

func _make_label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _on_register_pressed() -> void:
	if not _manager_ready():
		return
	var result: Dictionary = arena_manager.call("register_fighter", LOCAL_PLAYER_ID)
	_registered = bool(result.get("success", false))
	feedback_label.text = "تم تسجيلك كمقاتل. الدخول مجاني ولا تُخصم أي عملة." if _registered else "تعذر التسجيل: " + str(result.get("reason", "UNKNOWN"))
	_refresh()

func _on_create_match_pressed() -> void:
	if not _manager_ready():
		return
	var match_type := "TEAM" if match_type_choice.selected == 1 else "SINGLE"
	var participants: Array = SHOWCASE_TEAMS if match_type == "TEAM" else SHOWCASE_FIGHTERS
	var result: Dictionary = arena_manager.call("create_match", str(participants[0]), str(participants[1]), match_type)
	if not bool(result.get("success", false)):
		feedback_label.text = "تعذر إنشاء النزال: " + str(result.get("reason", "UNKNOWN"))
		_refresh()
		return
	for index in range(28):
		var fighter_id: String = str(participants[index % 2])
		arena_manager.call("add_npc_prediction", "arena_spectator_%02d" % index, fighter_id)
	feedback_label.text = "تم إنشاء نزال استعراضي؛ توقعات الجمهور الـ28 تفاعلية وغير نقدية."
	_refresh()

func _on_open_betting_pressed() -> void:
	if not _manager_ready():
		return
	var result: Dictionary = arena_manager.call("open_betting")
	feedback_label.text = "فُتحت التوقعات للمشجعين." if bool(result.get("success", false)) else "تعذر فتح التوقعات: " + str(result.get("reason", "UNKNOWN"))
	_refresh()

func _on_place_bet_pressed() -> void:
	if not _manager_ready():
		return
	var status: Dictionary = arena_manager.call("get_match_status")
	if not bool(status.get("active", false)):
		feedback_label.text = "لا يوجد نزال متاح للتوقع."
		return
	var match_data: Dictionary = status.get("match", {})
	var fighter_id := str(match_data.get("fighter_a_id", ""))
	if fighter_choice.selected == 1:
		fighter_id = str(match_data.get("fighter_b_id", ""))
	var amount := int(bet_amount.value)
	var result: Dictionary = arena_manager.call("place_spectator_bet", LOCAL_PLAYER_ID, fighter_id, amount)
	if bool(result.get("success", false)):
		feedback_label.text = "تم قبول توقعك. رصيدك الافتراضي: %d" % int(result.get("wallet_balance", 0))
	else:
		feedback_label.text = "لم يُقبل التوقع: " + str(result.get("reason", "UNKNOWN"))
	_refresh()

func _on_start_match_pressed() -> void:
	if not _manager_ready():
		return
	var result: Dictionary = arena_manager.call("lock_betting_and_start_match")
	feedback_label.text = "أُغلقت التوقعات. حالة النزال أصبحت قيد التنفيذ؛ نتيجة القتال تحتاج ربط نظام القتال." if bool(result.get("success", false)) else "تعذر بدء حالة النزال: " + str(result.get("reason", "UNKNOWN"))
	_refresh()

func _on_cancel_match_pressed() -> void:
	if not _manager_ready():
		return
	var result: Dictionary = arena_manager.call("cancel_match")
	feedback_label.text = "أُلغي النزال وأُعيدت %d من العملة الافتراضية." % int(result.get("refunded", 0)) if bool(result.get("success", false)) else "تعذر الإلغاء: " + str(result.get("reason", "UNKNOWN"))
	_refresh()

func _on_match_created(_match_data: Dictionary) -> void:
	_refresh()

func _on_crowd_cheered(_fighter_id: String, intensity: float) -> void:
	if feedback_label != null and intensity >= 0.75:
		feedback_label.text = "الجمهور يشتعل حماساً! توقعات المشجعين حرّكت المدرجات."

func _manager_ready() -> bool:
	if not is_instance_valid(arena_manager):
		feedback_label.text = "مدير الحلبة غير متاح."
		return false
	return true

func _refresh() -> void:
	if not is_instance_valid(arena_manager) or status_label == null:
		return
	var status: Dictionary = arena_manager.call("get_match_status")
	var active := bool(status.get("active", false))
	var crowd_count := int(status.get("npc_crowd_size", 0))
	if not active:
		status_label.text = "لا يوجد نزال نشط | الجمهور: %d/28" % crowd_count
		fighters_label.text = "المقاتلون: —"
		pool_label.text = "مجموع التوقعات: 0 SYSTEM_CREDITS"
	else:
		var match_data: Dictionary = status.get("match", {})
		var pool: Dictionary = status.get("pool", {})
		var state := str(match_data.get("status", ""))
		status_label.text = "النزال: %s | الحالة: %s | الجمهور: %d/28" % [str(match_data.get("match_id", "")), state, crowd_count]
		fighters_label.text = "%s: %s  VS  %s: %s" % [str(match_data.get("fighter_a_id", "")), "الأول", str(match_data.get("fighter_b_id", "")), "الثاني"]
		pool_label.text = "مجموع التوقعات: %d | عدد التذاكر: %d SYSTEM_CREDITS" % [int(pool.get("total", 0)), int(pool.get("bet_count", 0))]
		var locked := state == "IN_PROGRESS"
		open_betting_button.disabled = state != "READY"
		place_bet_button.disabled = state != "BETTING_OPEN"
		start_match_button.disabled = state != "BETTING_OPEN"
		cancel_match_button.disabled = false
		create_match_button.disabled = true
		return
	open_betting_button.disabled = true
	place_bet_button.disabled = true
	start_match_button.disabled = true
	cancel_match_button.disabled = true
	create_match_button.disabled = false
	register_button.text = "تم تسجيلك — دخول المقاتل مجاني" if _registered else "سجّل كمقاتل — دخول مجاني"
