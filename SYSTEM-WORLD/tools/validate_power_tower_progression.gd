extends SceneTree

const POWER_TOWER_SCRIPT = preload("res://scripts/system_power_tower_manager.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _fail(message: String) -> void:
	push_error("Power Tower validation failed: " + message)
	quit(1)


func _run_validation() -> void:
	var manager = POWER_TOWER_SCRIPT.new()
	manager.save_enabled = false
	root.add_child(manager)

	if int(manager.MAX_FLOORS) != 200:
		_fail("The tower must contain exactly 200 floors.")
		return

	var boss_count := 0
	for floor_number in range(1, 201):
		var data: Dictionary = manager.get_floor_data(floor_number)
		if data.is_empty():
			_fail("Missing floor data for floor %d." % floor_number)
			return
		if str(data.get("region_id", "")).is_empty():
			_fail("Floor %d has no region profile." % floor_number)
			return
		if str(data.get("floor_scale", "")) != "large_explorable_region":
			_fail("Floor %d is not marked as a large explorable region." % floor_number)
			return
		if int(data.get("checkpoint_count", 0)) != 3:
			_fail("Floor %d must define three checkpoints." % floor_number)
			return
		if bool(data.get("boss_floor", false)):
			boss_count += 1
		if int(data.get("required_level", 101)) > 100:
			_fail("Floor %d requires a level above the current level cap." % floor_number)
			return
	if boss_count != 20:
		_fail("Expected 20 boss floors, found %d." % boss_count)
		return

	var started: Dictionary = manager.request_floor(1, 1)
	if not bool(started.get("success", false)):
		_fail("Floor 1 should be available to a level 1 player.")
		return

	for checkpoint_id in ["entry_checkpoint", "midpoint_checkpoint"]:
		var checkpoint_result: Dictionary = manager.record_floor_checkpoint(1, checkpoint_id)
		if not bool(checkpoint_result.get("success", false)):
			_fail("Could not record checkpoint: " + checkpoint_id)
			return

	var failed_run: Dictionary = manager.fail_active_floor()
	if not bool(failed_run.get("progress_preserved", false)):
		_fail("A failed run did not preserve its reached checkpoints.")
		return

	var resumed: Dictionary = manager.request_floor(1, 1)
	if not bool(resumed.get("success", false)):
		_fail("The player could not retry the same floor.")
		return
	if str(resumed.get("resume_data", {}).get("last_checkpoint_id", "")) != "midpoint_checkpoint":
		_fail("Retry did not resume from the last saved checkpoint.")
		return

	var last_checkpoint: Dictionary = manager.record_floor_checkpoint(1, "pre_boss_checkpoint")
	if not bool(last_checkpoint.get("success", false)):
		_fail("Could not record the final checkpoint.")
		return

	var clear_result: Dictionary = manager.confirm_floor_clear(1, 42.0)
	if not bool(clear_result.get("success", false)):
		_fail("A fully completed floor did not clear.")
		return
	if int(clear_result.get("reward_currency", 0)) != 55:
		_fail("Floor 1 currency reward is not the expected 55 tower credits.")
		return
	if int(manager.get_tower_status().get("next_floor", 0)) != 2:
		_fail("The next floor did not unlock after a verified clear.")
		return

	var final_floor: Dictionary = manager.get_floor_data(200)
	if not bool(final_floor.get("tower_finale", false)) or not bool(final_floor.get("boss_floor", false)):
		_fail("Floor 200 must be the final boss trial.")
		return

	manager.queue_free()
	print("Power Tower validation passed: 200 floors, 10 region bands, 20 boss floors, checkpoint retry, XP/currency rewards and floor unlock progression.")
	quit(0)
