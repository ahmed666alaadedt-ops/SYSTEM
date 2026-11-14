
extends CanvasLayer
class_name HunterGuildMenu

signal mission_accepted(mission_id: String)

var root_ui: Control
var guild_panel: PanelContainer
var mission_list: VBoxContainer
var status_label: Label

var missions := [
	{
		"id": "guild_001",
		"title": "مهمة الصياد المبتدئ",
		"description": "استكشف المنطقة المحيطة وسجل أول اكتشاف لك.",
		"rank": "E",
		"reward": 100
	},
	{
		"id": "guild_002",
		"title": "مطاردة الوحش",
		"description": "تعقب وحشاً مجهولاً واجمع معلومات عنه.",
		"rank": "D",
		"reward": 250
	},
	{
		"id": "guild_003",
		"title": "بوابة غامضة",
		"description": "تحقق من بوابة ظهرت خارج المدينة.",
		"rank": "C",
		"reward": 500
	}
]


func _ready() -> void:
	layer = 21
	_build_interface()


func _build_interface() -> void:
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root_ui)

	var open_button := Button.new()
	open_button.text = "نقابة الصيادين"
	open_button.position = Vector2(20, 95)
	open_button.custom_minimum_size = Vector2(210, 58)
	open_button.add_theme_font_size_override("font_size", 19)
	root_ui.add_child(open_button)
	open_button.pressed.connect(_toggle_panel)

	guild_panel = PanelContainer.new()
	guild_panel.position = Vector2(20, 165)
	guild_panel.custom_minimum_size = Vector2(340, 440)
	guild_panel.size = Vector2(340, 440)
	root_ui.add_child(guild_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	guild_panel.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)

	var title := Label.new()
	title.text = "نقابة الصيادين العالمية"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	header.add_child(close_button)
	close_button.pressed.connect(func(): guild_panel.hide())

	status_label = Label.new()
	status_label.text = "اختر مهمة للبدء بمغامرتك"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status_label)

	var separator := HSeparator.new()
	content.add_child(separator)

	mission_list = VBoxContainer.new()
	mission_list.add_theme_constant_override("separation", 10)
	content.add_child(mission_list)

	_build_missions()
	guild_panel.hide()


func _build_missions() -> void:
	for mission in missions:
		var card := PanelContainer.new()
		mission_list.add_child(card)

		var details := VBoxContainer.new()
		details.add_theme_constant_override("separation", 5)
		card.add_child(details)

		var name_label := Label.new()
		name_label.text = mission["title"]
		name_label.add_theme_font_size_override("font_size", 18)
		details.add_child(name_label)

		var description := Label.new()
		description.text = mission["description"]
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(description)

		var info := Label.new()
		info.text = "الرتبة: %s  |  المكافأة: %d XP" % [
			mission["rank"],
			mission["reward"]
		]
		details.add_child(info)

		var accept_button := Button.new()
		accept_button.text = "قبول المهمة"
		details.add_child(accept_button)

		accept_button.pressed.connect(
			_on_mission_accepted.bind(mission["id"], mission["title"])
		)


func _toggle_panel() -> void:
	guild_panel.visible = not guild_panel.visible


func _on_mission_accepted(mission_id: String, mission_title: String) -> void:
	status_label.text = "تم اختيار: " + mission_title
	mission_accepted.emit(mission_id)

	print("SYSTEM: Hunter mission selected: ", mission_id)
