extends CanvasLayer
class_name SYSTEMBaghdadTowerLiftUI

signal floor_selected(tower_id: String, floor_number: int)

var _tower_id := ""
var _max_floors := 1
var _panel: PanelContainer
var _floor_picker: OptionButton
var _title: Label


func _ready() -> void:
	name = "SYSTEMBaghdadTowerLiftUI"
	_build_interface()
	hide()


func open_for_tower(tower_id: String, tower_title: String, max_floors: int) -> void:
	_tower_id = tower_id
	_max_floors = maxi(1, max_floors)
	_title.text = tower_title + " — المصعد المركزي"
	_floor_picker.clear()
	for floor_number in range(1, _max_floors + 1):
		_floor_picker.add_item("الطابق %03d" % floor_number)
		_floor_picker.set_item_metadata(_floor_picker.item_count - 1, floor_number)
	_floor_picker.select(0)
	_panel.show()
	show()


func _build_interface() -> void:
	_panel = PanelContainer.new()
	_panel.name = "TowerLiftPanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -190.0
	_panel.offset_top = -135.0
	_panel.offset_right = 190.0
	_panel.offset_bottom = 135.0
	add_child(_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	_panel.add_child(layout)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_title)
	var hint := Label.new()
	hint.text = "اختر أي طابق متاح في هذا البرج"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hint)
	_floor_picker = OptionButton.new()
	_floor_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_floor_picker)
	var enter_button := Button.new()
	enter_button.text = "الصعود إلى الطابق"
	enter_button.pressed.connect(_on_enter_pressed)
	layout.add_child(enter_button)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(hide)
	layout.add_child(close_button)


func _on_enter_pressed() -> void:
	if _tower_id.is_empty() or _floor_picker.item_count == 0:
		return
	var selected_index := _floor_picker.selected
	var floor_number := int(_floor_picker.get_item_metadata(selected_index))
	floor_selected.emit(_tower_id, floor_number)
	hide()
