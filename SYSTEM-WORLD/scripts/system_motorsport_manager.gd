extends Node
class_name SystemMotorsportManager

signal race_started(event_id: String, vehicle_id: String)
signal checkpoint_reached(checkpoint_index: int, completed_laps: int)
signal lap_completed(completed_laps: int, elapsed_seconds: float)
signal race_finished(result: Dictionary)
signal race_cancelled(event_id: String)
signal player_wager_created(wager_id: String, event_id: String, amount: int)

const VehicleCatalogScript = preload("res://scripts/system_vehicle_catalog.gd")
const RACE_RECORDS_PATH := "user://system_motorsport_records.cfg"
const MAX_LOCAL_ATTEMPTS_PER_EVENT := 50

const EVENTS := {
	"city_sprint": {"name":"City Sprint Cup","discipline":"street_circuit","vehicle_categories":["sports","premium","supercar","electric","race_gt","race_hyper"],"laps":3,"base_reward":1800,"description":"بطولة حلبة مدينة مغلقة ومخصصة للسباق؛ ليست سباقاً على الشوارع العامة"},
	"gt_championship": {"name":"SYSTEM GT Championship","discipline":"race_gt","vehicle_categories":["race_gt","race_endurance","race_hyper"],"laps":5,"base_reward":6500,"description":"بطولة سيارات GT والتحمل"},
	"formula_grand_prix": {"name":"SYSTEM Formula Grand Prix","discipline":"race_formula","vehicle_categories":["race_formula"],"laps":8,"base_reward":12000,"description":"سباق سيارات المقعد الواحد"},
	"endurance_challenge": {"name":"Endurance 60","discipline":"race_endurance","vehicle_categories":["race_endurance","race_gt","race_hyper"],"laps":12,"base_reward":15000,"description":"سباق تحمل طويل"},
	"drift_series": {"name":"Global Drift Series","discipline":"race_drift","vehicle_categories":["race_drift","sports","supercar"],"laps":2,"base_reward":4200,"description":"منافسات الانجراف"},
	"rally_stage": {"name":"World Rally Stage","discipline":"race_rally","vehicle_categories":["race_rally","offroad"],"laps":1,"base_reward":5200,"description":"مرحلة رالي على الطرق الوعرة"},
	"drag_quarter_mile": {"name":"Quarter Mile Drag","discipline":"race_drag","vehicle_categories":["race_drag","race_hyper","supercar"],"laps":1,"base_reward":3500,"description":"سباق تسارع لمسافة ربع ميل"}
}

var garage_manager: SystemPlayerVehicleManager
var active_race: Dictionary = {}
var race_elapsed := 0.0
var next_checkpoint_index := 0
var completed_laps := 0
var total_laps := 0
var checkpoint_total := 0
var dedicated_track_context := false
var pending_player_wagers: Dictionary = {}
var race_records: Dictionary = {}

func _ready() -> void:
	_load_race_records()

func setup(vehicle_garage: SystemPlayerVehicleManager) -> void:
	garage_manager = vehicle_garage

func _load_race_records() -> void:
	var config := ConfigFile.new()
	if config.load(RACE_RECORDS_PATH) != OK:
		return
	var saved: Variant = config.get_value("race_records", "events", {})
	if typeof(saved) == TYPE_DICTIONARY:
		race_records = saved.duplicate(true)

func _save_race_records() -> bool:
	var config := ConfigFile.new()
	config.set_value("race_records", "events", race_records.duplicate(true))
	var error := config.save(RACE_RECORDS_PATH)
	if error != OK:
		push_warning("SYSTEM: Motorsport records could not be saved.")
		return false
	return true

func _sort_race_records(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("elapsed_seconds", 0.0)) < float(b.get("elapsed_seconds", 0.0))

func _record_completed_race(result: Dictionary) -> Dictionary:
	var event_id := str(result.get("event_id", ""))
	if event_id.is_empty():
		return {"saved": false, "reason": "INVALID_EVENT_ID"}
	var attempts: Array = race_records.get(event_id, [])
	attempts.append({
		"event_id": event_id,
		"event_name": str(result.get("event_name", event_id)),
		"elapsed_seconds": maxf(0.0, float(result.get("elapsed_seconds", 0.0))),
		"completed_laps": int(result.get("completed_laps", 0)),
		"vehicle_id": str(result.get("vehicle_id", "")),
		"recorded_at_unix": int(Time.get_unix_time_from_system())
	})
	while attempts.size() > MAX_LOCAL_ATTEMPTS_PER_EVENT:
		attempts.pop_front()
	race_records[event_id] = attempts
	var saved_ok := _save_race_records()
	var sorted_attempts: Array = attempts.duplicate(true)
	sorted_attempts.sort_custom(_sort_race_records)
	var best: Dictionary = sorted_attempts[0] if not sorted_attempts.is_empty() else {}
	return {
		"saved": saved_ok,
		"scope": "local_device_only",
		"attempt_count": attempts.size(),
		"best_time_seconds": float(best.get("elapsed_seconds", 0.0)),
		"is_personal_best": not best.is_empty() and int(best.get("recorded_at_unix", 0)) == int(result.get("recorded_at_unix", -1)),
		"local_rank": 1,
		"local_leaderboard": sorted_attempts.slice(0, mini(10, sorted_attempts.size()))
	}

func get_event_leaderboard(event_id: String, limit: int = 10) -> Array:
	var attempts: Array = race_records.get(event_id, []).duplicate(true)
	attempts.sort_custom(_sort_race_records)
	return attempts.slice(0, clampi(limit, 1, 50))

func get_personal_best(event_id: String) -> Dictionary:
	var leaderboard := get_event_leaderboard(event_id, MAX_LOCAL_ATTEMPTS_PER_EVENT)
	return leaderboard[0].duplicate(true) if not leaderboard.is_empty() else {}

func set_dedicated_track_context(enabled: bool) -> void:
	dedicated_track_context = enabled

func get_wager_rules() -> Dictionary:
	return {
		"enabled":false,
		"currency":"SYSTEM_CREDITS",
		"mode":"player_vs_player_escrow",
		"requires_multiplayer":true,
		"requires_server_authority":true,
		"real_money_allowed":false,
		"reason":"Wagers stay disabled until authenticated multiplayer escrow, anti-cheat, dispute handling, and regional compliance are implemented."
	}

func create_player_wager(_event_id: String, _opponent_player_id: String, _amount: int) -> Dictionary:
	return {"success":false,"reason":"SERVER_AUTHORITATIVE_MULTIPLAYER_WAGERING_NOT_IMPLEMENTED","rules":get_wager_rules()}

func _process(delta: float) -> void:
	if not active_race.is_empty():
		race_elapsed += maxf(0.0, delta)

func get_event_catalog() -> Dictionary:
	return EVENTS.duplicate(true)

func get_event(event_id: String) -> Dictionary:
	return EVENTS.get(event_id, {}).duplicate(true)

func is_race_active() -> bool:
	return not active_race.is_empty()

func start_race(event_id: String, vehicle_id: String, checkpoints: int, laps_override: int = -1) -> Dictionary:
	if is_race_active():
		return {"success":false,"reason":"RACE_ALREADY_ACTIVE"}
	if garage_manager == null:
		return {"success":false,"reason":"GARAGE_NOT_READY"}
	if not dedicated_track_context:
		return {"success":false,"reason":"RACE_REQUIRES_DEDICATED_TRACK"}
	var event: Dictionary = get_event(event_id)
	if event.is_empty():
		return {"success":false,"reason":"UNKNOWN_RACE_EVENT"}
	if not garage_manager.get_garage().has(vehicle_id):
		return {"success":false,"reason":"RACE_VEHICLE_NOT_OWNED"}
	var vehicle: Dictionary = VehicleCatalogScript.get_vehicle(vehicle_id)
	var category := str(vehicle.get("category", ""))
	var allowed: Array = event.get("vehicle_categories", [])
	if not allowed.has(category):
		return {"success":false,"reason":"VEHICLE_CLASS_NOT_ELIGIBLE"}
	if checkpoints < 2:
		return {"success":false,"reason":"RACE_NEEDS_AT_LEAST_TWO_CHECKPOINTS"}
	var requested_laps := int(event.get("laps", 1)) if laps_override < 1 else laps_override
	if requested_laps > 100:
		return {"success":false,"reason":"INVALID_LAP_COUNT"}
	total_laps = requested_laps
	checkpoint_total = checkpoints
	next_checkpoint_index = 0
	completed_laps = 0
	race_elapsed = 0.0
	active_race = {
		"event_id":event_id,
		"event_name":str(event.get("name", event_id)),
		"discipline":str(event.get("discipline", "")),
		"vehicle_id":vehicle_id,
		"total_laps":total_laps,
		"checkpoint_total":checkpoint_total,
		"base_reward":int(event.get("base_reward", 0))
	}
	race_started.emit(event_id, vehicle_id)
	return {"success":true,"event":active_race.duplicate(true)}

func register_checkpoint(checkpoint_index: int) -> Dictionary:
	if not is_race_active():
		return {"success":false,"reason":"NO_ACTIVE_RACE"}
	if checkpoint_index != next_checkpoint_index:
		return {"success":false,"reason":"CHECKPOINT_OUT_OF_ORDER","expected":next_checkpoint_index}
	next_checkpoint_index += 1
	checkpoint_reached.emit(checkpoint_index, completed_laps)
	if next_checkpoint_index >= checkpoint_total:
		completed_laps += 1
		next_checkpoint_index = 0
		lap_completed.emit(completed_laps, race_elapsed)
		if completed_laps >= total_laps:
			return finish_race()
	return {"success":true,"completed_laps":completed_laps,"next_checkpoint":next_checkpoint_index}

func finish_race() -> Dictionary:
	if not is_race_active():
		return {"success":false,"reason":"NO_ACTIVE_RACE"}
	var finished := active_race.duplicate(true)
	var reward := int(finished.get("base_reward", 0))
	var payment: Dictionary = garage_manager.award_race_reward(reward) if garage_manager != null else {"success":false}
	var result := {
		"success":true,
		"event_id":str(finished.get("event_id", "")),
		"event_name":str(finished.get("event_name", "")),
		"vehicle_id":str(finished.get("vehicle_id", "")),
		"completed_laps":completed_laps,
		"elapsed_seconds":race_elapsed,
		"reward":reward if bool(payment.get("success", false)) else 0,
		"wallet_updated":bool(payment.get("success", false)),
		"economy_mode":"local_prototype",
		"recorded_at_unix":int(Time.get_unix_time_from_system())
	}
	result["records"] = _record_completed_race(result)
	active_race.clear()
	race_finished.emit(result)
	return result

func cancel_race() -> Dictionary:
	if not is_race_active():
		return {"success":false,"reason":"NO_ACTIVE_RACE"}
	var event_id := str(active_race.get("event_id", ""))
	active_race.clear()
	race_elapsed = 0.0
	next_checkpoint_index = 0
	completed_laps = 0
	total_laps = 0
	checkpoint_total = 0
	race_cancelled.emit(event_id)
	return {"success":true,"event_id":event_id}
