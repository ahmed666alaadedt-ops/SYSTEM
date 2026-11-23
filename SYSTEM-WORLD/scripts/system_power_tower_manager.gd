extends Node
class_name SYSTEMPowerTowerManager

signal floor_started(floor_number: int, floor_data: Dictionary)
signal floor_cleared(floor_number: int, reward_xp: int, rank: String)
signal tower_record_updated(highest_floor: int)

const SAVE_PATH := "user://system_power_tower.cfg"
const MAX_FLOORS := 200
const SPECTATOR_DAILY_PREDICTION_LIMIT := 20
const SPECTATOR_POINTS_PER_CORRECT_PREDICTION := 1
const LOCAL_MATCH_AUTHORITY := "LOCAL_COMBAT_AUTHORITY"
const FLOOR_THEME_IDS := ["IRON", "DESERT", "FROST", "VOLCANIC", "JUNGLE", "RUINS", "STORM", "SHADOW", "CELESTIAL", "SOVEREIGN"]
const FLOOR_THEME_NAMES := ["قاعة الحديد", "ساحة الصحراء", "ميدان الجليد", "حلبة البركان", "غابة المحاربين", "أطلال الملوك", "ساحة العاصفة", "ميدان الظلال", "الحلبة السماوية", "عرش السيادة"]

var highest_cleared_floor := 0
var active_floor := 0
var floor_clear_times: Dictionary = {}
var total_duels_won := 0
var elite_duels_won := 0
var boss_duels_won := 0
var total_xp_earned := 0
var total_credits_earned := 0
var spectator_save_path := "user://system_power_tower_spectator_predictions.cfg"
var spectator_matches: Dictionary = {}
var spectator_prediction_points: Dictionary = {}
var spectator_daily_counts: Dictionary = {}

func _ready() -> void:
	name = "SYSTEMPowerTowerManager"
	_load_progress()
	_load_spectator_data()

func get_floor_data(floor_number: int) -> Dictionary:
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {}
	var final_boss := floor_number == MAX_FLOORS
	var boss_floor := floor_number % 10 == 0
	var elite_floor := floor_number % 5 == 0 and not boss_floor
	var difficulty := clampi(1 + int((floor_number - 1) / 5), 1, 40)
	var required_level := clampi(int(ceil(float(floor_number) * 0.45)), 1, 100)
	var reward_xp := 100 + floor_number * floor_number * 12 + (250000 if final_boss else 0)
	var reward_credits := 75 + floor_number * 15 + (5000 if final_boss else 0)
	var theme_index := clampi(int((floor_number - 1) / 20), 0, FLOOR_THEME_IDS.size() - 1)
	var arena_theme_id := str(FLOOR_THEME_IDS[theme_index])
	var arena_theme_name := str(FLOOR_THEME_NAMES[theme_index])
	var arena_type := "BOSS_TRIAL" if boss_floor else ("ELITE_DUEL" if elite_floor else "DUEL")
	var objective_type := "DEFEAT_BOSS" if boss_floor else "DEFEAT_OPPONENT"
	var arena_name := "SYSTEM SOVEREIGN — FINAL DUEL" if final_boss else ("BOSS DUEL ARENA" if boss_floor else ("ELITE DUEL ARENA" if elite_floor else "1 VS 1 DUEL ARENA"))
	var arena_rules := "المواجهة النهائية الفردية: لاعب واحد ضد حارس برج القوة الأخير" if final_boss else ("مواجهة فردية ضد زعيم الطابق — مقاتل واحد ضد خصم واحد" if boss_floor else ("مواجهة نخبة فردية — 1 ضد 1" if elite_floor else "مواجهة فردية 1 ضد 1 — لا فرق ولا خصوم متعددون"))
	return {
		"floor": floor_number,
		"difficulty": difficulty,
		"required_level": required_level,
		"boss_floor": boss_floor,
		"elite_floor": elite_floor,
		"opponent_power": 80 + floor_number * 24,
		"opponent_count": 1,
		"wave_count": 1,
		"reward_xp": reward_xp,
		"reward_credits": reward_credits,
		"rank": _rank_for_floor(floor_number),
		"challenge_type": "FINAL_BOSS" if final_boss else ("BOSS" if boss_floor else ("ELITE_DUEL" if elite_floor else "SINGLE_DUEL")),
		"arena_type": arena_type,
		"arena_theme_index": theme_index,
		"arena_theme_id": arena_theme_id,
		"arena_theme_name": arena_theme_name,
		"objective_type": objective_type,
		"time_limit_seconds": 0,
		"arena_name": arena_name,
		"arena_rules": arena_rules,
		"clear_time_recorded": true,
		"ranked": elite_floor or boss_floor,
		"final_boss": final_boss,
		"competition_format": "INDIVIDUAL_1V1",
		"reward_items": ["power_tower_sovereign_crown", "sovereign_core", "rare_core", "nen_fragment"] if final_boss else (["boss_core", "monster_core"] if boss_floor else (["power_tower_fragment", "monster_core"] if elite_floor else ["power_tower_token"]))
	}

func request_floor(floor_number: int, player_level: int) -> Dictionary:
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {"success": false, "reason": "INVALID_FLOOR"}
	if highest_cleared_floor >= MAX_FLOORS:
		return {"success": false, "reason": "TOWER_COMPLETED"}
	if floor_number <= highest_cleared_floor:
		return {"success": false, "reason": "FLOOR_ALREADY_CLEARED", "highest_cleared": highest_cleared_floor}
	if floor_number > highest_cleared_floor + 1:
		return {"success": false, "reason": "PREVIOUS_FLOOR_REQUIRED", "highest_cleared": highest_cleared_floor}
	var data := get_floor_data(floor_number)
	if player_level < int(data["required_level"]):
		return {"success": false, "reason": "PLAYER_LEVEL_TOO_LOW", "required_level": data["required_level"]}
	if active_floor != 0:
		return {"success": false, "reason": "ANOTHER_FLOOR_IS_ACTIVE", "active_floor": active_floor}
	active_floor = floor_number
	floor_started.emit(floor_number, data)
	return {"success": true, "floor_data": data}

## يستدعيها نظام القتال بعد التأكد من فوز اللاعب في المواجهة الفردية.
func confirm_floor_clear(floor_number: int, clear_time_seconds: float) -> Dictionary:
	if active_floor != floor_number or floor_number <= 0:
		return {"success": false, "reason": "FLOOR_NOT_ACTIVE"}
	if clear_time_seconds <= 0.0:
		return {"success": false, "reason": "INVALID_CLEAR_TIME"}
	var data := get_floor_data(floor_number)
	highest_cleared_floor = maxi(highest_cleared_floor, floor_number)
	floor_clear_times[str(floor_number)] = clear_time_seconds
	total_duels_won += 1
	if bool(data.get("boss_floor", false)):
		boss_duels_won += 1
	elif bool(data.get("elite_floor", false)):
		elite_duels_won += 1
	var reward := int(data["reward_xp"])
	var credit_reward := int(data["reward_credits"])
	total_xp_earned += reward
	total_credits_earned += credit_reward
	active_floor = 0
	_save_progress()
	var rank := str(data["rank"])
	floor_cleared.emit(floor_number, reward, rank)
	tower_record_updated.emit(highest_cleared_floor)
	return {
		"success": true,
		"floor": floor_number,
		"reward_xp": reward,
		"reward_credits": credit_reward,
		"rank": rank,
		"highest_cleared_floor": highest_cleared_floor,
		"total_duels_won": total_duels_won,
		"elite_duels_won": elite_duels_won,
		"boss_duels_won": boss_duels_won,
		"total_xp_earned": total_xp_earned,
		"total_credits_earned": total_credits_earned
	}

func abandon_active_floor() -> void:
	active_floor = 0

func get_tower_status() -> Dictionary:
	var best_clear_time := 0.0
	for clear_time in floor_clear_times.values():
		var value := float(clear_time)
		if best_clear_time <= 0.0 or value < best_clear_time:
			best_clear_time = value
	var highest_floor_time := float(floor_clear_times.get(str(highest_cleared_floor), 0.0))
	return {
		"highest_cleared_floor": highest_cleared_floor,
		"active_floor": active_floor,
		"max_floors": MAX_FLOORS,
		"next_floor": 0 if highest_cleared_floor >= MAX_FLOORS else highest_cleared_floor + 1,
		"highest_rank": _rank_for_floor(highest_cleared_floor) if highest_cleared_floor > 0 else "-",
		"best_clear_time": best_clear_time,
		"highest_floor_clear_time": highest_floor_time,
		"competition_format": "INDIVIDUAL_1V1",
		"total_duels_won": total_duels_won,
		"elite_duels_won": elite_duels_won,
		"boss_duels_won": boss_duels_won,
		"total_xp_earned": total_xp_earned,
		"total_credits_earned": total_credits_earned
	}


## Local prototype lifecycle for free fan predictions. Online settlement must move to a trusted server.
func register_spectator_match(match_id: String, fighter_a_id: String, fighter_b_id: String, floor_number: int) -> Dictionary:
	if match_id.strip_edges().is_empty() or fighter_a_id.strip_edges().is_empty() or fighter_b_id.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_MATCH_IDENTITY"}
	if fighter_a_id == fighter_b_id:
		return {"success": false, "reason": "FIGHTERS_MUST_BE_DISTINCT"}
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {"success": false, "reason": "INVALID_FLOOR"}
	if spectator_matches.has(match_id):
		return {"success": false, "reason": "MATCH_ALREADY_REGISTERED"}
	spectator_matches[match_id] = {
		"match_id": match_id,
		"fighter_a_id": fighter_a_id,
		"fighter_b_id": fighter_b_id,
		"floor": floor_number,
		"competition_format": "INDIVIDUAL_1V1",
		"state": "open",
		"predictions": {},
		"created_at_unix": int(Time.get_unix_time_from_system())
	}
	_save_spectator_data()
	return {"success": true, "match_id": match_id, "state": "open"}

func submit_spectator_prediction(match_id: String, spectator_id: String, predicted_winner_id: String) -> Dictionary:
	if spectator_id.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_SPECTATOR"}
	if not spectator_matches.has(match_id):
		return {"success": false, "reason": "MATCH_NOT_FOUND"}
	var match_record: Dictionary = spectator_matches[match_id]
	if str(match_record.get("state", "")) != "open":
		return {"success": false, "reason": "PREDICTIONS_LOCKED"}
	var fighter_a := str(match_record.get("fighter_a_id", ""))
	var fighter_b := str(match_record.get("fighter_b_id", ""))
	if spectator_id == fighter_a or spectator_id == fighter_b:
		return {"success": false, "reason": "FIGHTERS_CANNOT_PREDICT_OWN_MATCH"}
	if predicted_winner_id != fighter_a and predicted_winner_id != fighter_b:
		return {"success": false, "reason": "PREDICTION_MUST_SELECT_A_MATCH_FIGHTER"}
	var predictions: Dictionary = match_record.get("predictions", {})
	if predictions.has(spectator_id):
		return {"success": false, "reason": "PREDICTION_ALREADY_SUBMITTED"}
	var today := Time.get_date_string_from_system(true)
	var daily_record: Dictionary = spectator_daily_counts.get(spectator_id, {})
	var daily_count := int(daily_record.get("count", 0)) if str(daily_record.get("date", "")) == today else 0
	if daily_count >= SPECTATOR_DAILY_PREDICTION_LIMIT:
		return {"success": false, "reason": "DAILY_PREDICTION_LIMIT_REACHED"}
	predictions[spectator_id] = {
		"predicted_winner_id": predicted_winner_id,
		"submitted_at_unix": int(Time.get_unix_time_from_system()),
		"correct": false,
		"points_awarded": 0
	}
	match_record["predictions"] = predictions
	spectator_matches[match_id] = match_record
	spectator_daily_counts[spectator_id] = {"date": today, "count": daily_count + 1}
	_save_spectator_data()
	return {"success": true, "match_id": match_id, "prediction_locked_at_match_start": true}

func lock_spectator_predictions(match_id: String) -> Dictionary:
	if not spectator_matches.has(match_id):
		return {"success": false, "reason": "MATCH_NOT_FOUND"}
	var match_record: Dictionary = spectator_matches[match_id]
	if str(match_record.get("state", "")) != "open":
		return {"success": false, "reason": "MATCH_NOT_OPEN"}
	match_record["state"] = "locked"
	match_record["locked_at_unix"] = int(Time.get_unix_time_from_system())
	spectator_matches[match_id] = match_record
	_save_spectator_data()
	return {"success": true, "state": "locked"}

func settle_spectator_match(match_id: String, winner_id: String, settlement_source: String) -> Dictionary:
	if settlement_source != LOCAL_MATCH_AUTHORITY:
		return {"success": false, "reason": "UNTRUSTED_MATCH_RESULT"}
	if not spectator_matches.has(match_id):
		return {"success": false, "reason": "MATCH_NOT_FOUND"}
	var match_record: Dictionary = spectator_matches[match_id]
	if str(match_record.get("state", "")) != "locked":
		return {"success": false, "reason": "MATCH_NOT_LOCKED"}
	if winner_id != str(match_record.get("fighter_a_id", "")) and winner_id != str(match_record.get("fighter_b_id", "")):
		return {"success": false, "reason": "WINNER_NOT_IN_MATCH"}
	var predictions: Dictionary = match_record.get("predictions", {})
	var awarded: Dictionary = {}
	for spectator_id_variant in predictions.keys():
		var spectator_id := str(spectator_id_variant)
		var prediction: Dictionary = predictions[spectator_id]
		var correct := str(prediction.get("predicted_winner_id", "")) == winner_id
		var points := SPECTATOR_POINTS_PER_CORRECT_PREDICTION if correct else 0
		prediction["correct"] = correct
		prediction["points_awarded"] = points
		predictions[spectator_id] = prediction
		if points > 0:
			spectator_prediction_points[spectator_id] = int(spectator_prediction_points.get(spectator_id, 0)) + points
			awarded[spectator_id] = points
	match_record["predictions"] = predictions
	match_record["state"] = "settled"
	match_record["winner_id"] = winner_id
	match_record["settled_at_unix"] = int(Time.get_unix_time_from_system())
	match_record["settlement_source"] = settlement_source
	spectator_matches[match_id] = match_record
	_save_spectator_data()
	return {"success": true, "winner_id": winner_id, "points_awarded": awarded, "cash_value": 0}

func get_spectator_match(match_id: String) -> Dictionary:
	return (spectator_matches.get(match_id, {}) as Dictionary).duplicate(true)

func get_spectator_status(spectator_id: String) -> Dictionary:
	var today := Time.get_date_string_from_system(true)
	var daily_record: Dictionary = spectator_daily_counts.get(spectator_id, {})
	var daily_count := int(daily_record.get("count", 0)) if str(daily_record.get("date", "")) == today else 0
	return {
		"spectator_id": spectator_id,
		"prediction_points": int(spectator_prediction_points.get(spectator_id, 0)),
		"predictions_today": daily_count,
		"daily_prediction_limit": SPECTATOR_DAILY_PREDICTION_LIMIT,
		"cash_value": 0,
		"transferable": false,
		"purchasable": false
	}

func _save_spectator_data() -> void:
	var config := ConfigFile.new()
	config.set_value("spectators", "matches", spectator_matches)
	config.set_value("spectators", "points", spectator_prediction_points)
	config.set_value("spectators", "daily_counts", spectator_daily_counts)
	var error := config.save(spectator_save_path)
	if error != OK:
		push_warning("SYSTEM: Spectator prediction data could not be saved.")

func _load_spectator_data() -> void:
	var config := ConfigFile.new()
	if config.load(spectator_save_path) != OK:
		return
	var saved_matches: Variant = config.get_value("spectators", "matches", {})
	var saved_points: Variant = config.get_value("spectators", "points", {})
	var saved_daily_counts: Variant = config.get_value("spectators", "daily_counts", {})
	spectator_matches = saved_matches.duplicate(true) if saved_matches is Dictionary else {}
	spectator_prediction_points = saved_points.duplicate(true) if saved_points is Dictionary else {}
	spectator_daily_counts = saved_daily_counts.duplicate(true) if saved_daily_counts is Dictionary else {}

func _rank_for_floor(floor_number: int) -> String:
	if floor_number >= 180: return "S"
	if floor_number >= 150: return "A"
	if floor_number >= 110: return "B"
	if floor_number >= 70: return "C"
	if floor_number >= 30: return "D"
	return "E"

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("tower", "highest_cleared_floor", highest_cleared_floor)
	config.set_value("tower", "floor_clear_times", floor_clear_times)
	config.set_value("tower", "total_duels_won", total_duels_won)
	config.set_value("tower", "elite_duels_won", elite_duels_won)
	config.set_value("tower", "boss_duels_won", boss_duels_won)
	config.set_value("tower", "total_xp_earned", total_xp_earned)
	config.set_value("tower", "total_credits_earned", total_credits_earned)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM: Power Tower progress could not be saved.")

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	highest_cleared_floor = clampi(int(config.get_value("tower", "highest_cleared_floor", 0)), 0, MAX_FLOORS)
	var saved_times: Dictionary = config.get_value("tower", "floor_clear_times", {})
	floor_clear_times = saved_times.duplicate(true)
	total_duels_won = maxi(0, int(config.get_value("tower", "total_duels_won", highest_cleared_floor)))
	elite_duels_won = maxi(0, int(config.get_value("tower", "elite_duels_won", 0)))
	boss_duels_won = maxi(0, int(config.get_value("tower", "boss_duels_won", 0)))
	total_xp_earned = maxi(0, int(config.get_value("tower", "total_xp_earned", 0)))
	total_credits_earned = maxi(0, int(config.get_value("tower", "total_credits_earned", 0)))
