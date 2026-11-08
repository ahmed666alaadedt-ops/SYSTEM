
extends "res://scripts/premium_command_center.gd"

# SYSTEM WORLD - Dynamic World Information Panel
# Godot 4.3 | Landscape 1280x720

const WorldCatalog = preload("res://scripts/world_data.gd")

var world_details_panel: PanelContainer
var world_detail_title: Label
var world_detail_subtitle: Label
var world_detail_stage: Label
var world_detail_environment: Label
var world_detail_combat: Label


func _create_interface() -> void:
	super._create_interface()
	_create_world_details_panel()
	_update_world_details(selected_world)


func _create_world_details_panel() -> void:
	world_details_panel = _panel(
		premium_root,
		Color(0.0, 0.72, 1.0)
	)

	world_details_panel.name = "DynamicWorldDetails"

	world_details_panel.anchor_left = 0.42
	world_details_panel.anchor_right = 0.82
	world_details_panel.anchor_top = 0.14
	world_details_panel.anchor_bottom = 0.49

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	world_details_panel.add_child(column)

	column.add_child(
		_label(
			"ملف العالم المحدد",
			19,
			Color(0.30, 0.88, 1.0)
		)
	)

	world_detail_title = _label(
		"العالم الحديث",
		24,
		Color(1.0, 0.82, 0.35)
	)
	column.add_child(world_detail_title)

	world_detail_subtitle = _label("", 14)
	column.add_child(world_detail_subtitle)

	world_detail_stage = _label("", 13)
	column.add_child(world_detail_stage)

	var separator := HSeparator.new()
	column.add_child(separator)

	column.add_child(
		_label("البيئة والاستكشاف", 15, Color(0.30, 0.88, 1.0))
	)

	world_detail_environment = _label("", 14)
	column.add_child(world_detail_environment)

	column.add_child(
		_label("نظام القتال", 15, Color(0.30, 0.88, 1.0))
	)

	world_detail_combat = _label("", 14)
	column.add_child(world_detail_combat)


func _on_world_manager_selected(world_id: String) -> void:
	super._on_world_manager_selected(world_id)
	_update_world_details(world_id)


func _update_world_details(world_id: String) -> void:
	if not is_instance_valid(world_detail_title):
		return

	var world: Dictionary = WorldCatalog.get_world(world_id)

	if world.is_empty():
		world_detail_title.text = "عالم غير معروف"
		world_detail_subtitle.text = "لا توجد معلومات لهذا العالم."
		world_detail_stage.text = ""
		world_detail_environment.text = ""
		world_detail_combat.text = ""
		return

	var world_title := str(world.get("title", world_id))
	var subtitle := str(world.get("subtitle", ""))
	var stage := str(world.get("stage", "planned"))
	var environment := str(world.get("environment", ""))
	var combat := str(world.get("combat", ""))

	world_detail_title.text = world_title
	world_detail_subtitle.text = subtitle
	world_detail_environment.text = environment
	world_detail_combat.text = combat

	if stage == "prototype":
		world_detail_stage.text = "الحالة: نموذج أولي قيد التطوير"
	else:
		world_detail_stage.text = "الحالة: مخطط ضمن رؤية SYSTEM WORLD"
