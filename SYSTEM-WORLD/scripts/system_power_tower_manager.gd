extends Node
class_name SYSTEMPowerTowerManager

signal floor_started(floor_number: int, floor_data: Dictionary)
signal floor_cleared(floor_number: int, reward_xp: int, rank: String)
signal floor_rewarded(reward_data: Dictionary)
signal tower_record_updated(highest_floor: int)
signal checkpoint_reached(floor_number: int, checkpoint_id: String)
signal floor_failed(floor_number: int, resume_checkpoint_id: String)

const SAVE_PATH := "user://system_power_tower.cfg"
const MAX_FLOORS := 200
const REQUIRED_CHECKPOINTS_PER_FLOOR := 3
const FLOOR_REGIONS := [
	{"id":"frontier_forest","title":"غابات الحدود","environment":"غابة وممرات جبلية"},
	{"id":"warrior_citadels","title":"قلاع المحاربين","environment":"قلاع وساحات حصينة"},
	{"id":"beast_wilds","title":"براري الوحوش","environment":"أودية وكهوف ومواطن وحوش"},
	{"id":"shifting_labyrinths","title":"المتاهات المتحولة","environment":"متاهات وأطلال وطرق متغيرة"},
	{"id":"elite_proving_grounds","title":"ميادين النخبة","environment":"ميادين قتال ومناطق تدريب"},
	{"id":"elemental_frontiers","title":"حدود العناصر","environment":"نار وجليد وعواصف"},
	{"id":"lost_kingdoms","title":"الممالك المفقودة","environment":"مدن وقلاع وممالك مستقلة"},
	{"id":"giant_territories","title":"أقاليم العمالقة","environment":"منحدرات وهياكل عملاقة"},
	{"id":"mythic_reaches","title":"المناطق الأسطورية","environment":"أطلال وآثار وقوى نادرة"},
	{"id":"apex_trials","title":"تحديات القمة","environment":"مناطق اختبار عالية الخطورة"}
]

var highest_cleared_floor := 0
var active_floor := 0
var floor_clear_times: Dictionary = {}
var completed_checkpoints_by_floor: Dictionary = {}
var tower_credits := 0
## Tests may disable disk writes; normal gameplay keeps this enabled.
var save_enabled := true

func _ready() -> void:
	name = "SYSTEMPowerTowerManager"
	if save_enabled:
		_load_progress()

func get_floor_data(floor_number: int) -> Dictionary:
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {}
	var region_index := int((floor_number - 1) / 20)
	var region: Dictionary = FLOOR_REGIONS[region_index]
	var boss_floor := floor_number % 10 == 0
	var difficulty := clampi(1 + int((floor_number - 1) / 5), 1, 40)
	var required_level := clampi(int(ceil(float(floor_number) * 0.48)), 1, 100)
	var reward_xp := 100 + floor_number * floor_number * 12
	var reward_currency := 40 + floor_number * 15
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
		"opponent_power": 80 + floor_number * 36,
		"opponent_count": 1 if arena_type == "DUEL" or boss_floor else mini(2 + int(difficulty / 4), 8),
		"wave_count": 1 if arena_type == "DUEL" or boss_floor else mini(2 + int(floor_number / 12), 12),
		"reward_xp": reward_xp,
		"reward_currency": reward_currency,
		"currency_id": "tower_credits",
		"rank": _rank_for_floor(floor_number),
		"challenge_type": "BOSS" if boss_floor else ("ELITE" if floor_number % 5 == 0 else "COMBAT_TRIAL"),
		"arena_type": arena_type,
		"arena_name": "BOSS TRIAL ARENA" if boss_floor else str(arena_names[arena_cycle]),
		"arena_rules": "مواجهة زعيم الطابق — اهزم الخصم الرئيسي" if boss_floor else str(arena_rules[arena_cycle]),
		"region_id": str(region["id"]),
		"region_title": str(region["title"]),
		"environment_profile": str(region["environment"]),
		"floor_scale": "large_explorable_region",
		"checkpoint_ids": ["entry_checkpoint", "midpoint_checkpoint", "pre_boss_checkpoint"],
		"checkpoint_count": REQUIRED_CHECKPOINTS_PER_FLOOR,
		"clear_time_recorded": true,
		"ranked": arena_type == "CHAMPIONSHIP" or boss_floor,
		"tower_finale": floor_number == MAX_FLOORS
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
	var resume_data := get_floor_resume_data(floor_number)
	data["resume_data"] = resume_data
	floor_started.emit(floor_number, data.duplicate(true))
	return {"success": true, "floor_data": data, "resume_data": resume_data}

func get_floor_resume_data(floor_number: int) -> Dictionary:
	var completed := _get_completed_checkpoints(floor_number)
	var last_checkpoint := ""
	if not completed.is_empty():
		last_checkpoint = str(completed[completed.size() - 1])
	return {
		"floor": floor_number,
		"completed_checkpoint_ids": completed,
		"last_checkpoint_id": last_checkpoint,
		"next_checkpoint_index": completed.size(),
		"checkpoint_count": REQUIRED_CHECKPOINTS_PER_FLOOR
	}

## Called by the trusted floor objective controller after the player reaches a checkpoint.
func record_floor_checkpoint(floor_number: int, checkpoint_id: String) -> Dictionary:
	if active_floor != floor_number or floor_number <= 0:
		return {"success": false, "reason": "FLOOR_NOT_ACTIVE"}
	var normalized_id := checkpoint_id.strip_edges()
	var data := get_floor_data(floor_number)
	var allowed_ids: Array = data.get("checkpoint_ids", [])
	if not allowed_ids.has(normalized_id):
		return {"success": false, "reason": "UNKNOWN_CHECKPOINT"}
	var completed := _get_completed_checkpoints(floor_number)
	if completed.has(normalized_id):
		return {"success": false, "reason": "CHECKPOINT_ALREADY_RECORDED"}
	var expected_index := completed.size()
	if expected_index >= allowed_ids.size() or str(allowed_ids[expected_index]) != normalized_id:
		return {"success": false, "reason": "CHECKPOINT_ORDER_MISMATCH"}
	completed.append(normalized_id)
	completed_checkpoints_by_floor[str(floor_number)] = completed
	_save_progress()
	checkpoint_reached.emit(floor_number, normalized_id)
	return {"success": true, "floor": floor_number, "checkpoint_id": normalized_id, "resume_data": get_floor_resume_data(floor_number)}

## Call this after defeat. Checkpoints remain saved and the player can retry the same floor.
func fail_active_floor() -> Dictionary:
	if active_floor <= 0:
		return {"success": false, "reason": "NO_ACTIVE_FLOOR"}
	var failed_floor := active_floor
	var resume_data := get_floor_resume_data(failed_floor)
	active_floor = 0
	_save_progress()
	floor_failed.emit(failed_floor, str(resume_data.get("last_checkpoint_id", "")))
	return {"success": true, "floor": failed_floor, "resume_data": resume_data, "progress_preserved": true}

## Compatibility alias: abandoning a run now safely preserves its reached checkpoints.
func abandon_active_floor() -> void:
	fail_active_floor()

## Called by a trusted combat/objective verifier only after all floor objectives are completed.
func confirm_floor_clear(floor_number: int, clear_time_seconds: float) -> Dictionary:
	if active_floor != floor_number or floor_number <= 0:
		return {"success": false, "reason": "FLOOR_NOT_ACTIVE"}
	if clear_time_seconds <= 0.0:
		return {"success": false, "reason": "INVALID_CLEAR_TIME"}
	var data := get_floor_data(floor_number)
	var completed := _get_completed_checkpoints(floor_number)
	if completed.size() < REQUIRED_CHECKPOINTS_PER_FLOOR:
		return {"success": false, "reason": "FLOOR_OBJECTIVES_INCOMPLETE", "completed_checkpoints": completed.size(), "required_checkpoints": REQUIRED_CHECKPOINTS_PER_FLOOR}
	highest_cleared_floor = maxi(highest_cleared_floor, floor_number)
	floor_clear_times[str(floor_number)] = clear_time_seconds
	active_floor = 0
	var reward_xp := int(data["reward_xp"])
	var reward_currency := int(data["reward_currency"])
	tower_credits += reward_currency
	completed_checkpoints_by_floor.erase(str(floor_number))
	_save_progress()
	var rank := str(data["rank"])
	floor_cleared.emit(floor_number, reward_xp, rank)
	var reward_data := {
		"floor": floor_number,
		"xp": reward_xp,
		"currency": reward_currency,
		"currency_id": "tower_credits",
		"rank": rank,
		"highest_cleared_floor": highest_cleared_floor,
		"tower_credits_balance": tower_credits,
		"clear_time_seconds": clear_time_seconds,
		"tower_completed": floor_number == MAX_FLOORS
	}
	floor_rewarded.emit(reward_data.duplicate(true))
	tower_record_updated.emit(highest_cleared_floor)
	return {"success": true, "floor": floor_number, "reward_xp": reward_xp, "reward_currency": reward_currency, "rank": rank, "highest_cleared_floor": highest_cleared_floor, "tower_credits_balance": tower_credits, "tower_completed": floor_number == MAX_FLOORS}

func spend_tower_credits(amount: int, reason: String = "tower_activity") -> Dictionary:
	if amount <= 0:
		return {"success": false, "reason": "INVALID_AMOUNT"}
	if tower_credits < amount:
		return {"success": false, "reason": "INSUFFICIENT_TOWER_CREDITS", "balance": tower_credits, "required": amount}
	tower_credits -= amount
	_save_progress()
	return {"success": true, "spent": amount, "reason": reason, "balance": tower_credits}

func get_tower_status() -> Dictionary:
	return {
		"highest_cleared_floor": highest_cleared_floor,
		"active_floor": active_floor,
		"max_floors": MAX_FLOORS,
		"next_floor": 0 if highest_cleared_floor >= MAX_FLOORS else highest_cleared_floor + 1,
		"tower_credits": tower_credits,
		"active_floor_resume": get_floor_resume_data(active_floor) if active_floor > 0 else {}
	}

func _get_completed_checkpoints(floor_number: int) -> Array:
	var value: Variant = completed_checkpoints_by_floor.get(str(floor_number), [])
	if value is Array:
		return value.duplicate()
	return []

func _rank_for_floor(floor_number: int) -> String:
	if floor_number >= 180: return "S"
	if floor_number >= 140: return "A"
	if floor_number >= 100: return "B"
	if floor_number >= 60: return "C"
	if floor_number >= 30: return "D"
	return "E"

func _save_progress() -> void:
	if not save_enabled:
		return
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("tower", "highest_cleared_floor", highest_cleared_floor)
	config.set_value("tower", "floor_clear_times", floor_clear_times)
	config.set_value("tower", "completed_checkpoints_by_floor", completed_checkpoints_by_floor)
	config.set_value("tower", "tower_credits", tower_credits)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM: Power Tower progress could not be saved.")

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	highest_cleared_floor = clampi(int(config.get_value("tower", "highest_cleared_floor", 0)), 0, MAX_FLOORS)
	var saved_times: Variant = config.get_value("tower", "floor_clear_times", {})
	floor_clear_times = saved_times.duplicate(true) if saved_times is Dictionary else {}
	var saved_checkpoints: Variant = config.get_value("tower", "completed_checkpoints_by_floor", {})
	completed_checkpoints_by_floor = saved_checkpoints.duplicate(true) if saved_checkpoints is Dictionary else {}
	tower_credits = maxi(0, int(config.get_value("tower", "tower_credits", 0)))
