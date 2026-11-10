
extends Node

# SYSTEM WORLD
# Unified Four Worlds Selection and Entry Manager
# Godot 4.3

const WorldData = preload("res://scripts/world_data.gd")

signal world_selected(world_id: String)
signal world_entered(world_id: String)
signal world_entry_failed(world_id: String, reason: String)

var selected_world_id: String = "modern"
var selection_locked: bool = false


func _ready() -> void:
	selected_world_id = "modern"

	if not WorldData.get_world(selected_world_id).is_empty():
		world_selected.emit(selected_world_id)


# --------------------------------------------------
# WORLD SELECTION
# --------------------------------------------------

func select_world(world_id: String) -> bool:
	if selection_locked:
		return false

	var normalized_id := WorldData.normalize_world_id(world_id)

	if normalized_id.is_empty():
		push_warning("SYSTEM WORLD: Unknown world ID: " + world_id)
		return false

	var world := WorldData.get_world(normalized_id)

	if world.is_empty():
		push_warning("SYSTEM WORLD: World data is unavailable.")
		return false

	selected_world_id = normalized_id
	world_selected.emit(selected_world_id)

	return true


func get_selected_world() -> Dictionary:
	return WorldData.get_world(selected_world_id)


func get_selected_world_id() -> String:
	return selected_world_id


func get_all_worlds() -> Array:
	return WorldData.get_all_worlds()


func get_world_info(world_id: String) -> Dictionary:
	return WorldData.get_world(world_id)


# --------------------------------------------------
# WORLD AVAILABILITY
# --------------------------------------------------

func can_enter_world(world_id: String) -> bool:
	var normalized_id := WorldData.normalize_world_id(world_id)

	if normalized_id.is_empty():
		return false

	var scene_path := WorldData.get_world_scene(normalized_id)

	if scene_path.is_empty():
		return false

	return ResourceLoader.exists(scene_path)


func get_world_stage(world_id: String) -> String:
	return WorldData.get_world_stage(world_id)


func get_miyar_outfit(world_id: String) -> String:
	return WorldData.get_miyar_outfit(world_id)


# --------------------------------------------------
# WORLD ENTRY
# --------------------------------------------------

func enter_selected_world() -> bool:
	if selection_locked:
		return false

	return _load_world(selected_world_id)


func enter_world(world_id: String) -> bool:
	if selection_locked:
		return false

	var normalized_id := WorldData.normalize_world_id(world_id)

	if normalized_id.is_empty():
		world_entry_failed.emit(
			world_id,
			"معرّف العالم غير معروف."
		)
		return false

	selected_world_id = normalized_id
	world_selected.emit(selected_world_id)

	return _load_world(selected_world_id)


func start_quick_play() -> bool:
	# Quick Play always starts in the modern world.
	return enter_world("modern")


func _load_world(world_id: String) -> bool:
	var world := WorldData.get_world(world_id)

	if world.is_empty():
		world_entry_failed.emit(
			world_id,
			"العالم غير موجود في سجل العوالم."
		)
		return false

	var scene_path := str(world.get("scene_path", ""))

	if scene_path.is_empty():
		world_entry_failed.emit(
			world_id,
			"مشهد هذا العالم لم يُنشأ بعد."
		)
		return false

	if not ResourceLoader.exists(scene_path):
		world_entry_failed.emit(
			world_id,
			"ملف مشهد العالم غير موجود."
		)
		return false

	selection_locked = true

	var result: Error = get_tree().change_scene_to_file(scene_path)

	if result != OK:
		selection_locked = false

		world_entry_failed.emit(
			world_id,
			"تعذر تحميل مشهد العالم. رمز الخطأ: " + str(result)
		)
		return false

	world_entered.emit(world_id)
	return true


# --------------------------------------------------
# SELECTION CONTROL
# --------------------------------------------------

func unlock_selection() -> void:
	selection_locked = false


func is_selection_locked() -> bool:
	return selection_locked


func get_world_entry_status(world_id: String) -> String:
	var normalized_id := WorldData.normalize_world_id(world_id)

	if normalized_id.is_empty():
		return "unknown"

	if not can_enter_world(normalized_id):
		return "unavailable"

	return "available"
