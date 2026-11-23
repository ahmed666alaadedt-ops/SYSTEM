extends Node
class_name SYSTEMPowerTowerManager

signal floor_started(floor_number: int, floor_data: Dictionary)
signal floor_cleared(floor_number: int, reward_xp: int, rank: String)
signal tower_record_updated(highest_floor: int)

const SAVE_PATH := "user://system_power_tower.cfg"
const MAX_FLOORS := 200
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

func _ready() -> void:
	name = "SYSTEMPowerTowerManager"
	_load_progress()

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
