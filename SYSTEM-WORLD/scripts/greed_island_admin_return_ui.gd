extends Node

## أيقونة العودة إلى جزيرة الطمع — واجهة المدير فقط.
## صلاحية المدير هنا محلية للاختبار وليست حماية خادم متعددة اللاعبين.

const GREED_ISLAND_ID := 3

var world_manager: Node
var island_manager: Node3D
var return_button: Button
var canvas_layer: CanvasLayer


func _process(_delta: float) -> void:
	_find_managers()
	_remove_old_physical_return_gates()

	if world_manager == null or island_manager == null:
		return

	if not _is_admin_test_enabled():
		if return_button != null:
			return_button.visible = false
		return

	if return_button == null:
		_create_admin_return_icon()

	_update_icon_visibility()


func _find_managers() -> void:
	if world_manager == null or not is_instance_valid(world_manager):
		world_manager = get_tree().root.find_child(
			"WorldManager", true, false
		)

	if island_manager == null or not is_instance_valid(island_manager):
		island_manager = get_tree().root.find_child(
			"GreedIslandManager", true, false
		) as Node3D


func _is_admin_test_enabled() -> bool:
	return (
		island_manager != null
		and island_manager.has_method("is_admin_test_environment")
		and bool(
			island_manager.call("is_admin_test_environment")
		)
	)


func _get_world_roots() -> Dictionary:
	if world_manager == null:
		return {}

	var value: Variant = world_manager.get("world_roots")

	if value is Dictionary:
		return value

	return {}


func _remove_old_physical_return_gates() -> void:
	var roots := _get_world_roots()

	for world_id in roots.keys():
		var world_root := world_manager.call(
			"get_world_root", int(world_id)
		) as Node3D

		if world_root == null:
			continue

		var areas := world_root.find_children(
			"*", "Area3D", true, false
		)

		for area in areas:
			if area.has_meta("system_return_gate"):
				area.queue_free()


func _create_admin_return_icon() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "AdminIslandReturnLayer"
	canvas_layer.layer = 100
	add_child(canvas_layer)

	return_button = Button.new()
	return_button.name = "AdminReturnToGreedIsland"
	return_button.text = "↩"
	return_button.tooltip_text = "العودة إلى جزيرة الطمع — المدير فقط"
	return_button.custom_minimum_size = Vector2(70.0, 70.0)

	return_button.anchor_left = 1.0
	return_button.anchor_right = 1.0
	return_button.anchor_top = 0.0
	return_button.anchor_bottom = 0.0

	return_button.offset_left = -92.0
	return_button.offset_right = -22.0
	return_button.offset_top = 22.0
	return_button.offset_bottom = 92.0

	return_button.add_theme_font_size_override(
		"font_size", 34
	)

	return_button.mouse_filter = Control.MOUSE_FILTER_STOP
	return_button.pressed.connect(
		_on_admin_return_pressed
	)

	_apply_button_style()
	canvas_layer.add_child(return_button)


func _apply_button_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.12, 0.19, 0.94)
	normal.border_color = Color(0.15, 0.85, 1.0, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.25, 0.34, 1.0)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.12, 0.34, 0.42, 1.0)

	return_button.add_theme_stylebox_override(
		"normal", normal
	)
	return_button.add_theme_stylebox_override(
		"hover", hover
	)
	return_button.add_theme_stylebox_override(
		"pressed", pressed
	)

	return_button.add_theme_color_override(
		"font_color", Color(0.75, 0.97, 1.0)
	)


func _update_icon_visibility() -> void:
	if return_button == null:
		return

	if not _is_admin_test_enabled():
		return_button.visible = false
		return

	var active_world := int(
		world_manager.call("get_active_world")
	)

	return_button.visible = active_world != GREED_ISLAND_ID


func _on_admin_return_pressed() -> void:
	if world_manager == null:
		return

	if not _is_admin_test_enabled():
		return

	if int(world_manager.call("get_active_world")) == GREED_ISLAND_ID:
		return

	return_button.disabled = true

	world_manager.call(
		"switch_world", GREED_ISLAND_ID
	)

	await get_tree().create_timer(1.0).timeout

	if is_instance_valid(return_button):
		return_button.disabled = false
