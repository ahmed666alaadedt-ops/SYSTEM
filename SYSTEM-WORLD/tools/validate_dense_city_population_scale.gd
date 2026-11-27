extends SceneTree

const SOCIETY_SCRIPT = preload("res://scripts/ai_npc_society_manager.gd")
const DAILY_LIFE_SCRIPT = preload("res://scripts/npc_daily_life_manager.gd")
const SAVE_PATH := "user://system_world_ai_society.json"
const EXPECTED_ADULTS := 42500
const EXPECTED_MINORS := 7500


func _initialize() -> void:
	call_deferred("_run_scale_validation")


func _fail(message: String) -> void:
	push_error("50,000 resident scale validation failed: " + message)
	quit(1)


func _count_demographics(population: Dictionary) -> Dictionary:
	var adults := 0
	var minors := 0
	for value in population.values():
		if not value is Dictionary:
			continue
		var npc: Dictionary = value
		if int(npc.get("world_id", -1)) != 2 or not bool(npc.get("alive", false)):
			continue
		if float(npc.get("age_years", 0.0)) < 18.0:
			minors += 1
		else:
			adults += 1
	return {"adults": adults, "minors": minors}


func _run_scale_validation() -> void:
	var save_absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		_fail("The isolated CI save path already exists; refusing to overwrite user data.")
		return

	var seed_started := Time.get_ticks_msec()
	var society = SOCIETY_SCRIPT.new()
	root.add_child(society)
	var daily_life = DAILY_LIFE_SCRIPT.new()
	root.add_child(daily_life)
	daily_life.setup(society)

	var frame_guard := 0
	while not bool(daily_life.get("seeded")) and frame_guard < 2500:
		await process_frame
		frame_guard += 1
	if not bool(daily_life.get("seeded")):
		_fail("Resident seeding did not finish within 2,500 frames.")
		return
	var seed_ms := Time.get_ticks_msec() - seed_started

	var demographics := _count_demographics(society.npcs)
	if int(demographics["adults"]) != EXPECTED_ADULTS or int(demographics["minors"]) != EXPECTED_MINORS:
		_fail("Unexpected seeded demographics: " + str(demographics))
		return
	if society.npcs.size() != EXPECTED_ADULTS + EXPECTED_MINORS:
		_fail("The society dictionary does not contain exactly 50,000 records.")
		return

	var save_started := Time.get_ticks_msec()
	if not society.save_society():
		_fail("The society manager could not save the 50,000 records.")
		return
	var save_ms := Time.get_ticks_msec() - save_started
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		_fail("The saved society file could not be reopened.")
		return
	var save_bytes := save_file.get_length()
	save_file.close()

	var load_started := Time.get_ticks_msec()
	var reloaded_society = SOCIETY_SCRIPT.new()
	root.add_child(reloaded_society)
	var load_ms := Time.get_ticks_msec() - load_started
	if reloaded_society.npcs.size() != EXPECTED_ADULTS + EXPECTED_MINORS:
		_fail("Reloaded society record count differs from 50,000.")
		return
	var reloaded_demographics := _count_demographics(reloaded_society.npcs)
	if reloaded_demographics != demographics:
		_fail("Adult/minor counts changed during save/load: " + str(reloaded_demographics))
		return

	var remove_error := DirAccess.remove_absolute(save_absolute_path)
	if remove_error != OK:
		push_warning("Could not remove temporary 50,000-resident validation save: " + str(remove_error))
	print("50,000 resident scale validation passed: adults=", EXPECTED_ADULTS,
		" minors=", EXPECTED_MINORS, " seed_ms=", seed_ms,
		" save_ms=", save_ms, " load_ms=", load_ms, " save_bytes=", save_bytes,
		" frames=", frame_guard)
	quit(0)
