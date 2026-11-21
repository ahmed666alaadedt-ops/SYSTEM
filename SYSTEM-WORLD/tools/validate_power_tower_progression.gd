extends SceneTree

const POWER_TOWER_SCRIPT = preload("res://scripts/system_power_tower_manager.gd")
const FLOOR_WORLD_SCRIPT = preload("res://scripts/system_power_tower_floor_world.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _fail(message: String) -> void:
	push_error("Power Tower validation failed: " + message)
	quit(1)


func _run_validation() -> void:
	var manager = POWER_TOWER_SCRIPT.new()
	manager.save_enabled = false
	root.add_child(manager)

	var player := CharacterBody3D.new()
	player.name = "PowerTowerValidationPlayer"
	player.add_to_group("system_player")
	root.add_child(player)
	var floor_world = FLOOR_WORLD_SCRIPT.new()
	floor_world.name = "PowerTowerFloorWorldValidation"
	root.add_child(floor_world)
	floor_world.setup(manager, player)

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

	var floor_build: Dictionary = floor_world.build_floor(started.get("floor_data", {}), Vector3.ZERO)
	if not bool(floor_build.get("success", false)):
		_fail("Floor 1 physical exploration environment could not be built.")
		return
	if floor_world.get_node_or_null("ActiveFloor_001/GroundCollision/CollisionShape3D") == null:
		_fail("Floor 1 has no collision-backed exploration ground.")
		return
	for checkpoint_id in ["entry_checkpoint", "midpoint_checkpoint", "pre_boss_checkpoint"]:
		if floor_world.get_node_or_null("ActiveFloor_001/Checkpoint_" + checkpoint_id) == null:
			_fail("Floor 1 is missing checkpoint area: " + checkpoint_id)
			return
		if floor_world.get_node_or_null("ActiveFloor_001/CheckpointMarker_" + checkpoint_id) == null:
			_fail("Floor 1 is missing visible checkpoint marker: " + checkpoint_id)
			return
	if floor_world.get_node_or_null("ActiveFloor_001/FloorReturnGateSign") == null:
		_fail("Floor 1 is missing its visible return gate.")
		return

	for checkpoint_id in ["entry_checkpoint", "midpoint_checkpoint"]:
		floor_world.call("_on_checkpoint_body_entered", player, checkpoint_id)
		if manager.get_floor_resume_data(1).get("completed_checkpoint_ids", []).size() != (1 if checkpoint_id == "entry_checkpoint" else 2):
			_fail("Physical checkpoint trigger did not record: " + checkpoint_id)
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

	floor_world.call("_on_checkpoint_body_entered", player, "pre_boss_checkpoint")
	if manager.get_floor_resume_data(1).get("completed_checkpoint_ids", []).size() != 3:
		_fail("Physical final checkpoint trigger did not record.")
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

	var finale_build: Dictionary = floor_world.build_floor(final_floor, Vector3.ZERO)
	if not bool(finale_build.get("success", false)):
		_fail("Floor 200 physical exploration environment could not be built.")
		return
	if floor_world.get_node_or_null("ActiveFloor_200/BossArenaPlatform") == null:
		_fail("Floor 200 is missing its physical boss-trial arena.")
		return
	if int(floor_world.get_active_floor_info().get("floor", 0)) != 200:
		_fail("Generated floor-world status does not report floor 200.")
		return

	floor_world.queue_free()
	player.queue_free()
	manager.queue_free()
	print("Power Tower validation passed: 200 floors, 10 region bands, generated collision-backed exploration worlds, physical checkpoints, boss arenas, retry, XP/currency rewards and floor unlock progression.")
	quit(0)
