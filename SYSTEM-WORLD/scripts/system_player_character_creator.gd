extends CanvasLayer
class_name SYSTEMPlayerCharacterCreator

## Lightweight mobile-friendly creator for the canonical SYSTEM WORLD player.
## The selected profile is applied through main.gd's shared GLB character loader.

var runtime: Node
var profile: Dictionary = {}
var selectors: Dictionary = {}
var creator_panel: PanelContainer
var status_label: Label


func setup(runtime_node: Node) -> void:
	runtime = runtime_node
	var current_profile: Variant = runtime.get("player_appearance_profile")
	if current_profile is Dictionary:
		profile = current_profile.duplicate(true)
	_build_interface()


func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var open_button := Button.new()
	open_button.text = "تعديل الشخصية"
	open_button.position = Vector2(16, 16)
	open_button.custom_minimum_size = Vector2(170, 46)
	root.add_child(open_button)
	open_button.pressed.connect(_toggle_panel)

	creator_panel = PanelContainer.new()
	creator_panel.position = Vector2(16, 72)
	creator_panel.size = Vector2(350, 560)
	creator_panel.custom_minimum_size = Vector2(320, 460)
	creator_panel.visible = false
	root.add_child(creator_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	creator_panel.add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)

	var heading := Label.new()
	heading.text = "هوية شخصيتك"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)

	_add_selector(column, "الجنس", "gender",
		["male", "female"], ["ذكر", "أنثى"])
	_add_selector(column, "قصة الشعر", "hair_style",
		["short", "medium", "long", "curly", "braided", "ponytail", "bun", "bob", "pixie", "spiky"],
		["قصير", "متوسط", "طويل", "مجعد", "ضفائر", "ذيل حصان", "كعكة", "بوب", "قصير جداً", "شائك"])
	_add_selector(column, "لون الشعر", "hair_color",
		["black", "brown", "blonde", "white", "silver", "red", "blue", "purple", "green"],
		["أسود", "بني", "أشقر", "أبيض", "فضي", "أحمر", "أزرق", "بنفسجي", "أخضر"])
	_add_selector(column, "لون البشرة", "skin_tone",
		["fair", "olive", "tan", "dark"],
		["فاتح", "قمحي", "برونزي", "داكن"])
	_add_selector(column, "لون العينين", "eye_color",
		["brown", "green", "gray", "hazel", "blue"],
		["بني", "أخضر", "رمادي", "عسلي", "أزرق"])
	_add_selector(column, "شكل الوجه", "face_shape",
		["balanced", "sharp", "soft", "wide", "long", "round", "heart"],
		["متوازن", "حاد", "ناعم", "عريض", "طويل", "مستدير", "قلبي"])
	_add_selector(column, "بنية الجسم", "body_type",
		["slim", "average", "athletic", "heavy", "muscular"],
		["نحيف", "متوسط", "رياضي", "ممتلئ", "عضلي"])
	_add_selector(column, "الطول", "height_type",
		["short", "average", "tall"],
		["قصير", "متوسط", "طويل"])

	status_label = Label.new()
	status_label.text = "اختر المظهر ثم احفظ التغييرات"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)

	var apply_button := Button.new()
	apply_button.text = "حفظ وتطبيق المظهر"
	apply_button.custom_minimum_size = Vector2(0, 44)
	column.add_child(apply_button)
	apply_button.pressed.connect(_apply_profile)


func _add_selector(parent: VBoxContainer, title: String, profile_key: String,
		values: Array, labels: Array) -> void:
	var field := VBoxContainer.new()
	parent.add_child(field)

	var label := Label.new()
	label.text = title
	field.add_child(label)

	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index in range(values.size()):
		option.add_item(str(labels[index]))
		option.set_item_metadata(index, values[index])
	field.add_child(option)

	var current_value := str(profile.get(profile_key, values[0]))
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == current_value:
			option.select(index)
			break
	if option.selected < 0:
		option.select(0)
	selectors[profile_key] = option


func _toggle_panel() -> void:
	if is_instance_valid(creator_panel):
		creator_panel.visible = not creator_panel.visible


func _apply_profile() -> void:
	if not is_instance_valid(runtime):
		return
	for profile_key in selectors.keys():
		var option: OptionButton = selectors[profile_key]
		if option.selected >= 0:
			profile[profile_key] = option.get_item_metadata(option.selected)
	profile["age_group"] = "adult"
	profile["age"] = maxi(18, int(profile.get("age", 25)))
	profile["job"] = "hunter"
	profile["is_player_character"] = true
	runtime.call("apply_player_appearance", profile, true)
	status_label.text = "تم تطبيق المظهر وحفظه على هذا الجهاز"
