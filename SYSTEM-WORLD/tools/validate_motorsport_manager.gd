extends SceneTree

const RACE_SCRIPT = preload("res://scripts/system_motorsport_manager.gd")

class TestGarage:
	extends Node
	var owned := {"sport_coupe":true}
	var paid := 0
	func get_garage() -> Dictionary:
		return owned
	func award_race_reward(amount: int) -> Dictionary:
		paid += amount
		return {"success":true}

func _initialize() -> void:
	var garage := TestGarage.new()
	var manager = RACE_SCRIPT.new()
	root.add_child(garage)
	root.add_child(manager)
	manager.setup(garage)
	manager.set_dedicated_track_context(true)
	var started: Dictionary = manager.start_race("city_sprint", "sport_coupe", 4)
	if not bool(started.get("success", false)):
		_fail("Eligible owned vehicle could not enter a dedicated-track event.")
		return
	var skipped: Dictionary = manager.register_checkpoint(1)
	if str(skipped.get("reason", "")) != "CHECKPOINT_OUT_OF_ORDER":
		_fail("Out-of-order checkpoint was accepted.")
		return
	var final_result: Dictionary = {}
	for lap in range(3):
		for checkpoint in range(4):
			final_result = manager.register_checkpoint(checkpoint)
	if not bool(final_result.get("success", false)) or manager.is_race_active():
		_fail("Ordered checkpoints did not finish the configured three-lap event.")
		return
	if garage.paid != 1800 or int(final_result.get("completed_laps", 0)) != 3:
		_fail("Race reward or lap result was incorrect.")
		return
	var record: Dictionary = final_result.get("records", {})
	if str(record.get("scope", "")) != "local_device_only":
		_fail("Race record scope was not clearly marked local.")
		return
	manager.free()
	garage.free()
	print("Motorsport validation passed: dedicated track gate, owned class eligibility, ordered checkpoints, laps, reward and local records.")
	quit(0)

func _fail(message: String) -> void:
	push_error("Motorsport validation failed: " + message)
	quit(1)
