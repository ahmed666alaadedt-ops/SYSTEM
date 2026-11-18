extends Node
class_name SYSTEMPowerTowerManager

signal floor_started(floor_number: int, floor_data: Dictionary)
signal floor_cleared(floor_number: int, reward_xp: int, rank: String)
signal tower_record_updated(highest_floor: int)

const SAVE_PATH := "user://system_power_tower.cfg"
const MAX_FLOORS := 100

var highest_cleared_floor := 0
var active_floor := 0
var floor_clear_times: Dictionary = {}

func _ready() -> void:
	name = "SYSTEMPowerTowerManager"
	_load_progress()

func get_floor_data(floor_number: int) -> Dictionary:
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {}
	var boss_floor := floor_number % 10 == 0
	var difficulty := clampi(1 + int((floor_number - 1) / 5), 1, 20)
	var required_level := maxi(1, int(ceil(float(floor_number) * 0.72)))
	var reward_xp := 100 + floor_number * floor_number * 12
	return {
		"floor": floor_number,
		"difficulty": difficulty,
		"required_level": required_level,
		"boss_floor": boss_floor,
		"opponent_power": 80 + floor_number * 24,
		"reward_xp": reward_xp,
		"rank": _rank_for_floor(floor_number),
		"challenge_type": "BOSS" if boss_floor else ("ELITE" if floor_number % 5 == 0 else "COMBAT_TRIAL")
	}

func request_floor(floor_number: int, player_level: int) -> Dictionary:
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {"success": false, "reason": "INVALID_FLOOR"}
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
	return {"highest_cleared_floor": highest_cleared_floor, "active_floor": active_floor, "max_floors": MAX_FLOORS, "next_floor": mini(highest_cleared_floor + 1, MAX_FLOORS)}

func _rank_for_floor(floor_number: int) -> String:
	if floor_number >= 90: return "S"
	if floor_number >= 70: return "A"
	if floor_number >= 50: return "B"
	if floor_number >= 30: return "C"
	if floor_number >= 15: return "D"
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
