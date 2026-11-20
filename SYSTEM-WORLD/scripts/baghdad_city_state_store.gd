extends Node
class_name BaghdadCityStateStore

## Saves only explicitly opted-in mutable state for OSM-backed city features.
## Static OSM geometry/tags remain in the source cell pack and are never copied.

const SCHEMA_VERSION := 1
const DEFAULT_SAVE_PATH := "user://system_world_baghdad_city_state.json"

var save_path := DEFAULT_SAVE_PATH
var cells: Dictionary = {}
var active_cells: Dictionary = {}


func _ready() -> void:
	_load_state()
	get_tree().tree_exiting.connect(_capture_all_active_cells)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_capture_all_active_cells()


## Connected to BaghdadOSMCellStreamer.cell_loaded.
func restore_cell(_cell: Vector2i, cell_root: Node3D) -> void:
	if not is_instance_valid(cell_root):
		return
	var cell_key := _get_cell_key(cell_root)
	if cell_key.is_empty():
		return
	active_cells[cell_key] = cell_root
	if not cells.has(cell_key):
		return

	var record: Variant = cells[cell_key]
	if typeof(record) != TYPE_DICTIONARY:
		return
	var features_value: Variant = record.get("features", {})
	if typeof(features_value) != TYPE_DICTIONARY:
		return

	_apply_feature_states(cell_root, features_value)


## Connected to BaghdadOSMCellStreamer.cell_unloading.
## The signal is emitted before queue_free(), so feature metadata is still readable.
func capture_cell(_cell: Vector2i, cell_root: Node3D) -> void:
	if not is_instance_valid(cell_root):
		return
	var cell_key := _get_cell_key(cell_root)
	if cell_key.is_empty():
		return
	active_cells.erase(cell_key)
	if _capture_cell_record(cell_root):
		_save_state()


func _capture_cell_record(cell_root: Node3D) -> bool:
	var cell_key := _get_cell_key(cell_root)
	if cell_key.is_empty():
		return false
	var feature_states: Dictionary = {}
	_collect_feature_states(cell_root, feature_states)
	# Do not overwrite a previous save with an empty record when a cell contains
	# no mutable gameplay features yet.
	if feature_states.is_empty():
		return false

	cells[cell_key] = {
		"region_id": str(cell_root.get_meta("region_id", "")),
		"cell_x": int(cell_root.get_meta("cell_x", 0)),
		"cell_z": int(cell_root.get_meta("cell_z", 0)),
		"cell_schema_version": int(cell_root.get_meta("schema_version", 0)),
		"source_snapshot": str(cell_root.get_meta("source_snapshot", "")),
		"features": feature_states
	}
	return true


func _capture_all_active_cells() -> void:
	var changed := false
	for cell_key in active_cells.keys():
		var cell_root: Node3D = active_cells[cell_key]
		if is_instance_valid(cell_root) and _capture_cell_record(cell_root):
			changed = true
	active_cells.clear()
	if changed:
		_save_state()


func get_saved_feature_count(cell_root: Node3D) -> int:
	var cell_key := _get_cell_key(cell_root)
	if cell_key.is_empty() or not cells.has(cell_key):
		return 0
	var record: Variant = cells[cell_key]
	if typeof(record) != TYPE_DICTIONARY:
		return 0
	var features: Variant = record.get("features", {})
	return features.size() if typeof(features) == TYPE_DICTIONARY else 0


func _get_cell_key(cell_root: Node3D) -> String:
	var region_id := str(cell_root.get_meta("region_id", ""))
	if region_id != "iraq_baghdad_region":
		return ""
	if not cell_root.has_meta("cell_x") or not cell_root.has_meta("cell_z"):
		return ""
	return "%s/%d/%d" % [
		region_id,
		int(cell_root.get_meta("cell_x")),
		int(cell_root.get_meta("cell_z"))
	]


func _collect_feature_states(parent: Node, output: Dictionary) -> void:
	if parent.has_meta("system_location_id") and parent.has_meta("system_persistent_state"):
		var stable_id := str(parent.get_meta("system_location_id", ""))
		var state: Variant = parent.get_meta("system_persistent_state")
		if not stable_id.is_empty() and typeof(state) == TYPE_DICTIONARY and not state.is_empty() and _is_json_safe(state):
			output[stable_id] = state.duplicate(true)

	for child in parent.get_children():
		_collect_feature_states(child, output)


func _apply_feature_states(parent: Node, saved_features: Dictionary) -> void:
	if parent.has_meta("system_location_id"):
		var stable_id := str(parent.get_meta("system_location_id", ""))
		if not stable_id.is_empty() and saved_features.has(stable_id):
			var state: Variant = saved_features[stable_id]
			if typeof(state) == TYPE_DICTIONARY and _is_json_safe(state):
				parent.set_meta("system_persistent_state", state.duplicate(true))

	for child in parent.get_children():
		_apply_feature_states(child, saved_features)


func _is_json_safe(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return true
		TYPE_ARRAY:
			for item in value:
				if not _is_json_safe(item):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) != TYPE_STRING or not _is_json_safe(value[key]):
					return false
			return true
		_:
			return false


func _save_state() -> void:
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"cells": cells
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("SYSTEM Baghdad city state could not be saved: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(payload))


func _load_state() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning("SYSTEM Baghdad city state could not be loaded.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SYSTEM Baghdad city state save is invalid; existing file was left untouched.")
		return
	if int(parsed.get("schema_version", 0)) != SCHEMA_VERSION:
		push_warning("SYSTEM Baghdad city state schema is unsupported; existing file was left untouched.")
		return
	var saved_cells: Variant = parsed.get("cells", {})
	if typeof(saved_cells) != TYPE_DICTIONARY:
		push_warning("SYSTEM Baghdad city state cell table is invalid; existing file was left untouched.")
		return
	cells = saved_cells
