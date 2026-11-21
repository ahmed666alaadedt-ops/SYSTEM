extends SceneTree

const STORE_SCRIPT = preload("res://scripts/baghdad_city_state_store.gd")
const TEST_SAVE_PATH := "user://baghdad_city_state_round_trip_test.json"
const FEATURE_ID := "baghdad_osm_building_way_424242"


func _initialize() -> void:
	call_deferred("_run_test")


func _make_cell() -> Node3D:
	var cell := Node3D.new()
	cell.set_meta("region_id", "iraq_baghdad_region")
	cell.set_meta("cell_x", 0)
	cell.set_meta("cell_z", 0)
	cell.set_meta("schema_version", 1)
	cell.set_meta("source_snapshot", "test-snapshot-a")
	return cell


func _run_test() -> void:
	var absolute_test_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_test_path)

	var store = STORE_SCRIPT.new()
	store.save_path = TEST_SAVE_PATH
	root.add_child(store)

	var original_cell := _make_cell()
	var original_building := StaticBody3D.new()
	original_building.set_meta("system_location_id", FEATURE_ID)
	original_building.set_meta("osm_feature_id", "way/424242")
	original_building.set_meta("system_persistent_state", {
		"door_open": true,
		"shop_inventory": {"water": 4, "bread": 2},
		"service_status": "temporarily_closed"
	})
	original_cell.add_child(original_building)

	store.capture_cell(Vector2i.ZERO, original_cell)
	assert(FileAccess.file_exists(TEST_SAVE_PATH), "Cell state file was not written.")
	assert(store.get_saved_feature_count(original_cell) == 1, "Expected one persisted city feature.")

	# Simulate a fresh game session: the second store must read the JSON file from disk.
	store.queue_free()
	var fresh_store = STORE_SCRIPT.new()
	fresh_store.save_path = TEST_SAVE_PATH
	root.add_child(fresh_store)

	var reloaded_cell := _make_cell()
	var reloaded_building := StaticBody3D.new()
	reloaded_building.set_meta("system_location_id", FEATURE_ID)
	reloaded_building.set_meta("osm_feature_id", "way/424242")
	reloaded_cell.add_child(reloaded_building)

	fresh_store.restore_cell(Vector2i.ZERO, reloaded_cell)
	assert(reloaded_building.has_meta("system_persistent_state"), "Feature state was not restored from disk.")
	var restored: Dictionary = reloaded_building.get_meta("system_persistent_state")
	assert(bool(restored.get("door_open", false)), "Door state did not survive disk unload/reload.")
	assert(restored.get("shop_inventory", {}).get("water", 0) == 4, "Inventory did not survive disk unload/reload.")
	assert(str(restored.get("service_status", "")) == "temporarily_closed", "Service state did not survive disk unload/reload.")

	# Simulate an Android pause while the cell remains loaded and mutable.
	restored["door_open"] = false
	reloaded_building.set_meta("system_persistent_state", restored)
	fresh_store._capture_all_active_cells()
	var pause_store = STORE_SCRIPT.new()
	pause_store.save_path = TEST_SAVE_PATH
	root.add_child(pause_store)
	var pause_reload_cell := _make_cell()
	var pause_reload_building := StaticBody3D.new()
	pause_reload_building.set_meta("system_location_id", FEATURE_ID)
	pause_reload_cell.add_child(pause_reload_building)
	pause_store.restore_cell(Vector2i.ZERO, pause_reload_cell)
	var pause_restored: Dictionary = pause_reload_building.get_meta("system_persistent_state")
	assert(not bool(pause_restored.get("door_open", true)), "App-pause snapshot did not persist the latest active-cell state.")

	# A changed source snapshot must not invalidate a feature with the same stable OSM-backed ID.
	var second_reload_cell := _make_cell()
	second_reload_cell.set_meta("source_snapshot", "test-snapshot-b")
	var second_reload_building := StaticBody3D.new()
	second_reload_building.set_meta("system_location_id", FEATURE_ID)
	second_reload_cell.add_child(second_reload_building)
	pause_store.restore_cell(Vector2i.ZERO, second_reload_cell)
	assert(second_reload_building.has_meta("system_persistent_state"), "Stable feature ID was discarded after source snapshot change.")

	original_cell.free()
	reloaded_cell.free()
	second_reload_cell.free()
	pause_reload_cell.free()
	fresh_store.queue_free()
	pause_store.queue_free()
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_test_path)

	print("Baghdad city state persistence round-trip passed.")
	quit(0)
