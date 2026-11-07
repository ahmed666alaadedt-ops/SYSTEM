extends Node

# SYSTEM WORLD
# Four Worlds Selection Manager
# Godot 4.3

const WorldData = preload("res://scripts/world_data.gd")

signal world_selected(world_id: String)
signal world_entered(world_id: String)
signal world_entry_failed(world_id: String, reason: String)

var selected_world_id := "modern"
var selection_locked := false


func _ready() -> void:
	if not WorldData.get_world(selected_world_id).is_empty():
		world_selected.emit(selected_world_id)


func select_world(world_id: String) -> bool:
	if selection_locked:
		return false

	var world := WorldData.get_world(world_id)

	if world.is_empty():
		push_warning("SYSTEM WORLD: Unknown world ID: " + world_id)
		return false

	selected_world_id = world_id
	world_selected.emit(world_id)

	return true


func get_selected_world() -> Dictionary:
	return WorldData.get_world(selected_world_id)


func get_selected_world_id() -> String:
	return selected_world_id


func get_all_worlds() -> Array:
	return WorldData.get_all_worlds()


func get_world_info(world_id: String) -> Dictionary:
	return WorldData.get_world(world_id)


func can_enter_world(world_id: String) -> bool:
	var world := WorldData.get_world(world_id)

	if world.is_empty():
		return false

	var scene_path := str(world.get("scene_path", ""))

	if scene_path.is_empty():
		return false

	return ResourceLoader.exists(scene_path)


func enter_selected_world() -> bool:
	if selection_locked:
		return false

	var world := get_selected_world()

	if world.is_empty():
		world_entry_failed.emit(
			selected_world_id,
			"العالم غير موجود في سجل العوالم."
		)
		return false

	var scene_path := str(world.get("scene_path", ""))

	if scene_path.is_empty():
		world_entry_failed.emit(
			selected_world_id,
			"مشهد هذا العالم لم يُنشأ بعد."
		)
		return false

	if not ResourceLoader.exists(scene_path):
		world_entry_failed.emit(
			selected_world_id,
			"ملف مشهد العالم غير موجود."
		)
		return false

	selection_locked = true

	var result := get_tree().change_scene_to_file(scene_path)

	if result != OK:
		selection_locked = false

		world_entry_failed.emit(
			selected_world_id,
			"تعذر تحميل مشهد العالم."
		)
		return false

	world_entered.emit(selected_world_id)
	return true


func unlock_selection() -> void:
	selection_locked = false


func get_world_stage(world_id: String) -> String:
	return WorldData.get_world_stage(world_id)


func get_miyar_outfit(world_id: String) -> String:
	return WorldData.get_miyar_outfit(world_id)
