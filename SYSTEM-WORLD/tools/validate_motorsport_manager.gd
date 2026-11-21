extends SceneTree

const RACE_SCRIPT = preload("res://scripts/system_motorsport_manager.gd")
const GARAGE_SCRIPT = preload("res://scripts/system_player_vehicle_manager.gd")

func _initialize() -> void:
	var garage: Variant = GARAGE_SCRIPT.new()
	root.add_child(garage)
	garage.owned_vehicles = ["sport_coupe"]
	var starting_balance: int = garage.balance

	var manager = RACE_SCRIPT.new()
	root.add_child(manager)
	manager.setup(garage)
	manager.set_dedicated_track_context(true)
	var started: Dictionary = manager.start_race("city_sprint", "sport_coupe", 4)
	if not bool(started.get("success", false)):
		_fail("Eligible owned vehicle could not enter a dedicated-track event.")
		return
	var premature: Dictionary = manager.register_checkpoint(0)
	if str(premature.get("reason", "")) != "RACE_NOT_STARTED":
		_fail("The race accepted checkpoints before the green light.")
		return
	var countdown: Dictionary = manager.begin_race_countdown(0.0)
	if not bool(countdown.get("success", false)) or not bool(countdown.get("running", false)):
		_fail("The zero-duration test countdown did not release the green light.")
		return
	var skipped: Dictionary = manager.register_checkpoint(1)
	if str(skipped.get("reason", "")) != "CHECKPOINT_OUT_OF_ORDER":
		_fail("Out-of-order checkpoint was accepted.")
		return
	var penalty: Dictionary = manager.add_race_time_penalty(5.0, "validation")
	if not bool(penalty.get("success", false)) or float(penalty.get("penalty_seconds", 0.0)) != 5.0:
		_fail("Race time penalty could not be recorded.")
		return
	var final_result: Dictionary = {}
	for lap in range(3):
		for checkpoint in range(4):
			final_result = manager.register_checkpoint(checkpoint)
	if not bool(final_result.get("success", false)) or manager.is_race_active():
		_fail("Ordered checkpoints did not finish the configured three-lap event.")
		return
	if garage.balance - starting_balance != 1800 or int(final_result.get("completed_laps", 0)) != 3 or absf(float(final_result.get("elapsed_seconds", 0.0)) - 5.0) > 0.01:
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
