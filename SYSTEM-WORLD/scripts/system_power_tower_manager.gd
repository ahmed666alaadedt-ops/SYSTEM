extends Node
class_name SYSTEMPowerTowerManager

signal floor_started(floor_number: int, floor_data: Dictionary)
signal floor_cleared(floor_number: int, reward_xp: int, rank: String)
signal tower_record_updated(highest_floor: int)

const SAVE_PATH := "user://system_power_tower.cfg"
const MAX_FLOORS := 200

var highest_cleared_floor := 0
var active_floor := 0
var floor_clear_times: Dictionary = {}

func _ready() -> void:
	name = "SYSTEMPowerTowerManager"
	_load_progress()

func get_floor_data(floor_number: int) -> Dictionary:
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {}
	var final_boss := floor_number == MAX_FLOORS
	var boss_floor := floor_number % 10 == 0
	var difficulty := clampi(1 + int((floor_number - 1) / 5), 1, 40)
	var required_level := clampi(int(ceil(float(floor_number) * 0.45)), 1, 100)
	var reward_xp := 100 + floor_number * floor_number * 12 + (250000 if final_boss else 0)
	var arena_cycle := (floor_number - 1) % 5
	var arena_names := [
		"DUEL ARENA",
		"TEAM BATTLE ARENA",
		"SURVIVAL ARENA",
		"ELITE GAUNTLET",
		"CHAMPIONSHIP ARENA"
	]
	var arena_rules := [
		"مواجهة فردية — اهزم خصمك ضمن حدود الحلبة",
		"قتال فرق — تعاون مع فريقك ضد مجموعة خصوم",
		"اختبار بقاء — اصمد أمام موجات متتابعة",
		"تحدي نخبة — واجه خصوماً أقوى تباعاً",
		"بطولة تصنيفية — سلسلة مواجهات بأداء ووقت محسوبين"
	]
	var arena_type := "BOSS_TRIAL" if boss_floor else str(["DUEL", "TEAM", "SURVIVAL", "ELITE", "CHAMPIONSHIP"][arena_cycle])
	return {
		"floor": floor_number,
		"difficulty": difficulty,
		"required_level": required_level,
		"boss_floor": boss_floor,
		"opponent_power": 80 + floor_number * 24,
		"opponent_count": 1 if arena_type == "DUEL" or boss_floor else mini(2 + int(difficulty / 4), 8),
		"wave_count": 1 if arena_type == "DUEL" or boss_floor else mini(2 + int(floor_number / 12), 10),
		"reward_xp": reward_xp,
		"rank": _rank_for_floor(floor_number),
		"challenge_type": "BOSS" if boss_floor else ("ELITE" if floor_number % 5 == 0 else "COMBAT_TRIAL"),
		"arena_type": arena_type,
		"arena_name": "SYSTEM SOVEREIGN — FINAL TRIAL" if final_boss else ("BOSS TRIAL ARENA" if boss_floor else str(arena_names[arena_cycle])),
		"arena_rules": "المواجهة النهائية: اهزم حارس برج القوة الأخير لإتمام الطوابق الـ200" if final_boss else ("مواجهة زعيم الطابق — اهزم الخصم الرئيسي" if boss_floor else str(arena_rules[arena_cycle])),
		"clear_time_recorded": true,
		"ranked": arena_type == "CHAMPIONSHIP" or boss_floor,
		"final_boss": final_boss
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

## يستدعيها نظام قتال موثوق بعد التحقق من هزيمة خصوم الطابق فعلياً.
func confirm_floor_clear(floor_number: int, clear_time_seconds: float) -> Dictionary:
	if active_floor != floor_number or floor_number <= 0:
		return {"success": false, "reason": "FLOOR_NOT_ACTIVE"}
	if clear_time_seconds <= 0.0:
		return {"success": false, "reason": "INVALID_CLEAR_TIME"}
	var data := get_floor_data(floor_number)
	highest_cleared_floor = maxi(highest_cleared_floor, floor_number)
	floor_clear_times[str(floor_number)] = clear_time_seconds
	active_floor = 0
	_save_progress()
	var reward := int(data["reward_xp"])
	var rank := str(data["rank"])
	floor_cleared.emit(floor_number, reward, rank)
	tower_record_updated.emit(highest_cleared_floor)
	return {"success": true, "floor": floor_number, "reward_xp": reward, "rank": rank, "highest_cleared_floor": highest_cleared_floor}

func abandon_active_floor() -> void:
	active_floor = 0

func get_tower_status() -> Dictionary:
	return {"highest_cleared_floor": highest_cleared_floor, "active_floor": active_floor, "max_floors": MAX_FLOORS, "next_floor": 0 if highest_cleared_floor >= MAX_FLOORS else highest_cleared_floor + 1}

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
