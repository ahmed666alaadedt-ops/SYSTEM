extends Node
class_name SYSTEMPowerTowerManager

signal floor_started(floor_number: int, floor_data: Dictionary)
signal floor_cleared(floor_number: int, reward_xp: int, rank: String)
signal tower_record_updated(highest_floor: int)
signal duel_score_updated(match_id: String, duel_data: Dictionary)
signal duel_completed(match_id: String, duel_data: Dictionary)

const SAVE_PATH := "user://system_power_tower.cfg"
const MAX_FLOORS := 200
const SPECTATOR_DAILY_PREDICTION_LIMIT := 20
const SPECTATOR_MIN_STAKE := 1
const SPECTATOR_MAX_STAKE := 500
const NPC_INITIAL_TICKET_BUDGET := 300
const LOCAL_MATCH_AUTHORITY := "LOCAL_COMBAT_AUTHORITY"
const DUEL_TKO_SCORE := 10
const DUEL_MAX_CONSECUTIVE_LOSSES := 3
const DUEL_MAX_TOTAL_LOSSES := 10
const DUEL_JUDGE_IDS := ["HEAD_REFEREE", "TECHNICAL_JUDGE", "SAFETY_JUDGE"]
const FLOOR_THEME_IDS := ["IRON", "DESERT", "FROST", "VOLCANIC", "JUNGLE", "RUINS", "STORM", "SHADOW", "CELESTIAL", "SOVEREIGN"]
const FLOOR_THEME_NAMES := ["قاعة الحديد", "ساحة الصحراء", "ميدان الجليد", "حلبة البركان", "غابة المحاربين", "أطلال الملوك", "ساحة العاصفة", "ميدان الظلال", "الحلبة السماوية", "عرش السيادة"]

var highest_cleared_floor := 0
var active_floor := 0
var floor_clear_times: Dictionary = {}
var total_duels_won := 0
var total_duels_lost := 0
var consecutive_duel_losses := 0
var duel_disqualified := false
var duel_matches: Dictionary = {}
var registered_fighters: Dictionary = {}
var next_fighter_number := 1001
var elite_duels_won := 0
var boss_duels_won := 0
var total_xp_earned := 0
var total_credits_earned := 0
var processed_result_ids: Dictionary = {}
var spectator_save_path := "user://system_power_tower_spectator_predictions.cfg"
var duel_save_path := "user://system_power_tower_duels.cfg"
var spectator_matches: Dictionary = {}
var spectator_prediction_points: Dictionary = {}
var spectator_daily_counts: Dictionary = {}
var spectator_wallet_provider: Node
var spectator_npc_ticket_balances: Dictionary = {}

func _ready() -> void:
	name = "SYSTEMPowerTowerManager"
	_load_progress()
	_load_duel_records()
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
	var arena_name := "SOVEREIGN TITLE DUEL" if final_boss else ("TITLE HOLDER DUEL ARENA" if boss_floor else ("ELITE PLAYER DUEL ARENA" if elite_floor else "PLAYER 1 VS 1 DUEL ARENA"))
	var arena_rules := "مواجهة السيادة النهائية: لاعب بشري ضد حامل اللقب البشري — 1 ضد 1" if final_boss else ("مواجهة فردية ضد حامل لقب الطابق — لاعبان بشريان فقط" if boss_floor else ("مواجهة نخبة فردية بين لاعبين بشريين — 1 ضد 1" if elite_floor else "مواجهة فردية بين لاعبين بشريين 1 ضد 1 — لا فرق ولا خصوم آليين"))
	return {
		"floor": floor_number,
		"division_number": int(ceil(float(floor_number) / 10.0)),
		"division_floor_start": (int((floor_number - 1) / 10) * 10) + 1,
		"division_floor_end": mini(MAX_FLOORS, int(ceil(float(floor_number) / 10.0)) * 10),
		"fighter_registration_required": true,
		"private_room_eligible": floor_number >= 100,
		"judge_panel": DUEL_JUDGE_IDS.duplicate(),
		"scoring_rules": {"clean_hit": 1, "critical_hit": 2, "opponent_down": 1, "tko_score": DUEL_TKO_SCORE},
		"weapons_allowed": floor_number >= 200,
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
		"challenge_type": "FINAL_TITLE_DUEL" if final_boss else ("TITLE_HOLDER_DUEL" if boss_floor else ("ELITE_PLAYER_DUEL" if elite_floor else "SINGLE_PLAYER_DUEL")),
		"opponent_kind": "HUMAN_PLAYER",
		"ai_fallback": false,
		"matchmaking_mode": "ONLINE_1V1",
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
	if duel_disqualified:
		return {"success": false, "reason": "TOWER_DISQUALIFIED", "reason_ar": "تم إيقافك من المنافسات بعد بلوغ عشر خسائر."}
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
func confirm_floor_clear(floor_number: int, clear_time_seconds: float, server_verified: bool = false, result_id: String = "") -> Dictionary:
	if active_floor != floor_number or floor_number <= 0:
		return {"success": false, "reason": "FLOOR_NOT_ACTIVE"}
	if not server_verified:
		return {"success": false, "reason": "SERVER_VERIFICATION_REQUIRED"}
	result_id = result_id.strip_edges()
	if result_id.is_empty():
		return {"success": false, "reason": "INVALID_RESULT_ID"}
	if processed_result_ids.has(result_id):
		return {"success": false, "reason": "DUPLICATE_RESULT"}
	if clear_time_seconds <= 0.0:
		return {"success": false, "reason": "INVALID_CLEAR_TIME"}
	var data := get_floor_data(floor_number)
	processed_result_ids[result_id] = true
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
		"total_duels_lost": total_duels_lost,
		"consecutive_duel_losses": consecutive_duel_losses,
		"duel_disqualified": duel_disqualified,
		"elite_duels_won": elite_duels_won,
		"boss_duels_won": boss_duels_won,
		"total_xp_earned": total_xp_earned,
		"total_credits_earned": total_credits_earned,
		"processed_result_count": processed_result_ids.size()
	}

func register_tower_fighter(fighter_id: String) -> Dictionary:
	fighter_id = fighter_id.strip_edges()
	if fighter_id.is_empty():
		return {"success": false, "reason": "INVALID_FIGHTER_ID"}
	if registered_fighters.has(fighter_id):
		return {"success": true, "fighter_id": fighter_id, "fighter_number": int(registered_fighters[fighter_id].get("fighter_number", 0)), "already_registered": true}
	var fighter_number := next_fighter_number
	next_fighter_number += 1
	registered_fighters[fighter_id] = {
		"fighter_id": fighter_id,
		"fighter_number": fighter_number,
		"registered_at_unix": int(Time.get_unix_time_from_system()),
		"status": "ACTIVE",
		"division": 1
	}
	_save_duel_records()
	return {"success": true, "fighter_id": fighter_id, "fighter_number": fighter_number, "already_registered": false}


func register_judged_duel(match_id: String, fighter_a_id: String, fighter_b_id: String, floor_number: int, local_player_id: String = "PLAYER") -> Dictionary:
	local_player_id = local_player_id.strip_edges()
	if local_player_id.is_empty():
		return {"success": false, "reason": "LOCAL_PLAYER_ID_REQUIRED"}
	match_id = match_id.strip_edges()
	fighter_a_id = fighter_a_id.strip_edges()
	fighter_b_id = fighter_b_id.strip_edges()
	if match_id.is_empty() or fighter_a_id.is_empty() or fighter_b_id.is_empty() or fighter_a_id == fighter_b_id:
		return {"success": false, "reason": "INVALID_DUEL_IDENTITY"}
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {"success": false, "reason": "INVALID_FLOOR"}
	if not registered_fighters.has(fighter_a_id) or not registered_fighters.has(fighter_b_id):
		return {"success": false, "reason": "FIGHTER_REGISTRATION_REQUIRED"}
	if duel_matches.has(match_id):
		return {"success": false, "reason": "DUEL_ALREADY_REGISTERED"}
	var floor_data := get_floor_data(floor_number)
	duel_matches[match_id] = {
		"match_id": match_id,
		"floor": floor_number,
		"fighter_a_id": fighter_a_id,
		"fighter_b_id": fighter_b_id,
		"local_player_id": local_player_id.strip_edges(),
		"competition_format": "INDIVIDUAL_1V1",
		"state": "live",
		"score": {fighter_a_id: 0, fighter_b_id: 0},
		"knockdowns": {fighter_a_id: 0, fighter_b_id: 0},
		"judges": DUEL_JUDGE_IDS.duplicate(),
		"judge_profile": "BALANCED",
		"events": [],
		"tko_score": DUEL_TKO_SCORE,
		"floor_type": str(floor_data.get("arena_type", "DUEL")),
		"created_at_unix": int(Time.get_unix_time_from_system())
	}
	_save_duel_records()
	return {"success": true, "match_id": match_id, "judges": DUEL_JUDGE_IDS.duplicate(), "floor_type": str(floor_data.get("arena_type", "DUEL")), "state": "live"}


func record_judged_duel_event(match_id: String, judge_id: String, attacker_id: String, event_type: String, event_id: String) -> Dictionary:
	match_id = match_id.strip_edges()
	judge_id = judge_id.strip_edges()
	attacker_id = attacker_id.strip_edges()
	event_id = event_id.strip_edges()
	event_type = event_type.strip_edges().to_upper()
	if not duel_matches.has(match_id):
		return {"success": false, "reason": "DUEL_NOT_FOUND"}
	var duel: Dictionary = duel_matches[match_id]
	if str(duel.get("state", "")) != "live":
		return {"success": false, "reason": "DUEL_NOT_LIVE"}
	if not DUEL_JUDGE_IDS.has(judge_id):
		return {"success": false, "reason": "UNAUTHORIZED_JUDGE"}
	if event_id.is_empty():
		return {"success": false, "reason": "EVENT_ID_REQUIRED"}
	var events: Array = duel.get("events", [])
	for previous_event in events:
		if str(previous_event.get("event_id", "")) == event_id:
			return {"success": false, "reason": "DUPLICATE_JUDGE_EVENT"}
	var fighter_a := str(duel.get("fighter_a_id", ""))
	var fighter_b := str(duel.get("fighter_b_id", ""))
	if attacker_id != fighter_a and attacker_id != fighter_b:
		return {"success": false, "reason": "ATTACKER_NOT_IN_DUEL"}
	var points := 0
	match event_type:
		"CLEAN_HIT":
			points = 1
		"CRITICAL_HIT":
			points = 2
		"OPPONENT_DOWN":
			points = 1
		_:
			return {"success": false, "reason": "INVALID_SCORING_EVENT"}
	var score: Dictionary = duel.get("score", {})
	var knockdowns: Dictionary = duel.get("knockdowns", {})
	score[attacker_id] = int(score.get(attacker_id, 0)) + points
	if event_type == "OPPONENT_DOWN":
		knockdowns[attacker_id] = int(knockdowns.get(attacker_id, 0)) + 1
	duel["score"] = score
	duel["knockdowns"] = knockdowns
	events.append({"event_id": event_id, "judge_id": judge_id, "fighter_id": attacker_id, "event_type": event_type, "points": points, "timestamp": int(Time.get_unix_time_from_system())})
	duel["events"] = events
	var opponent_id := fighter_b if attacker_id == fighter_a else fighter_a
	var reached_tko := int(score.get(attacker_id, 0)) >= DUEL_TKO_SCORE
	duel_matches[match_id] = duel
	_save_duel_records()
	duel_score_updated.emit(match_id, duel.duplicate(true))
	return {"success": true, "fighter_id": attacker_id, "event_type": event_type, "points_awarded": points, "fighter_score": int(score.get(attacker_id, 0)), "opponent_score": int(score.get(opponent_id, 0)), "knockdowns": int(knockdowns.get(attacker_id, 0)), "tko_reached": reached_tko, "judge_id": judge_id}


func finish_judged_duel(match_id: String, winner_id: String, finish_type: String, settlement_source: String) -> Dictionary:
	match_id = match_id.strip_edges()
	winner_id = winner_id.strip_edges()
	finish_type = finish_type.strip_edges().to_upper()
	if settlement_source != LOCAL_MATCH_AUTHORITY:
		return {"success": false, "reason": "UNTRUSTED_MATCH_RESULT"}
	if not duel_matches.has(match_id):
		return {"success": false, "reason": "DUEL_NOT_FOUND"}
	var duel: Dictionary = duel_matches[match_id]
	if str(duel.get("state", "")) != "live":
		return {"success": false, "reason": "DUEL_ALREADY_FINISHED"}
	var fighter_a := str(duel.get("fighter_a_id", ""))
	var fighter_b := str(duel.get("fighter_b_id", ""))
	if winner_id != fighter_a and winner_id != fighter_b:
		return {"success": false, "reason": "WINNER_NOT_IN_DUEL"}
	if not ["KO", "TKO", "JUDGES_DECISION", "FORFEIT", "REFEREE_STOPPAGE"].has(finish_type):
		return {"success": false, "reason": "INVALID_FINISH_TYPE"}
	var score: Dictionary = duel.get("score", {})
	if finish_type == "TKO" and int(score.get(winner_id, 0)) < DUEL_TKO_SCORE:
		return {"success": false, "reason": "TKO_REQUIRES_TEN_POINTS"}
	if finish_type == "JUDGES_DECISION" and int(score.get(fighter_a, 0)) == int(score.get(fighter_b, 0)):
		return {"success": false, "reason": "TIED_SCORE_REQUIRES_REFEREE_REVIEW"}
	var loser_id := fighter_b if winner_id == fighter_a else fighter_a
	duel["state"] = "settled"
	duel["winner_id"] = winner_id
	duel["loser_id"] = loser_id
	duel["finish_type"] = finish_type
	duel["settled_at_unix"] = int(Time.get_unix_time_from_system())
	duel_matches[match_id] = duel
	var career_result := _record_duel_career_result(winner_id, loser_id, int(duel.get("floor", 1)), str(duel.get("local_player_id", "PLAYER")))
	_save_duel_records()
	duel_completed.emit(match_id, duel.duplicate(true))
	return {"success": true, "winner_id": winner_id, "loser_id": loser_id, "finish_type": finish_type, "score": score.duplicate(true), "career_result": career_result, "cash_value": 0}


func _record_duel_career_result(winner_id: String, loser_id: String, floor_number: int, local_player_id: String) -> Dictionary:
	var is_local_player := loser_id == local_player_id
	var player_won := winner_id == local_player_id
	var result := {"player_won": player_won, "player_lost": is_local_player, "demoted": false, "disqualified": false, "highest_cleared_floor": highest_cleared_floor}
	if player_won:
		consecutive_duel_losses = 0
		total_duels_won += 1
		_save_progress()
	elif is_local_player:
		total_duels_lost += 1
		consecutive_duel_losses += 1
		if total_duels_lost >= DUEL_MAX_TOTAL_LOSSES:
			highest_cleared_floor = 0
			active_floor = 0
			duel_disqualified = true
			result["disqualified"] = true
			result["demotion_reason"] = "TEN_TOTAL_LOSSES"
		elif consecutive_duel_losses >= DUEL_MAX_CONSECUTIVE_LOSSES:
			var current_band := int(floor(float(maxi(floor_number, highest_cleared_floor)) / 10.0))
			highest_cleared_floor = maxi(0, (current_band - 1) * 10)
			active_floor = 0
			result["demoted"] = true
			result["demotion_reason"] = "THREE_CONSECUTIVE_LOSSES"
		result["highest_cleared_floor"] = highest_cleared_floor
		result["consecutive_losses"] = consecutive_duel_losses
		result["total_losses"] = total_duels_lost
		_save_progress()
	return result


func get_duel_match(match_id: String) -> Dictionary:
	return (duel_matches.get(match_id, {}) as Dictionary).duplicate(true)


func get_duel_career_status() -> Dictionary:
	return {
		"total_wins": total_duels_won,
		"total_losses": total_duels_lost,
		"consecutive_losses": consecutive_duel_losses,
		"max_consecutive_losses": DUEL_MAX_CONSECUTIVE_LOSSES,
		"max_total_losses": DUEL_MAX_TOTAL_LOSSES,
		"disqualified": duel_disqualified,
		"highest_cleared_floor": highest_cleared_floor,
		"next_floor": 0 if duel_disqualified or highest_cleared_floor >= MAX_FLOORS else highest_cleared_floor + 1,
		"rank": _rank_for_floor(highest_cleared_floor) if highest_cleared_floor > 0 else "E"
	}


func _save_duel_records() -> void:
	var config := ConfigFile.new()
	config.set_value("duels", "matches", duel_matches)
	config.set_value("duels", "registered_fighters", registered_fighters)
	config.set_value("duels", "next_fighter_number", next_fighter_number)
	config.set_value("duels", "total_losses", total_duels_lost)
	config.set_value("duels", "consecutive_losses", consecutive_duel_losses)
	config.set_value("duels", "disqualified", duel_disqualified)
	var error := config.save(duel_save_path)
	if error != OK:
		push_warning("SYSTEM: Power Tower duel records could not be saved.")


func _load_duel_records() -> void:
	var config := ConfigFile.new()
	if config.load(duel_save_path) != OK:
		return
	var saved_matches: Variant = config.get_value("duels", "matches", {})
	var saved_fighters: Variant = config.get_value("duels", "registered_fighters", {})
	registered_fighters = saved_fighters.duplicate(true) if saved_fighters is Dictionary else {}
	next_fighter_number = maxi(1001, int(config.get_value("duels", "next_fighter_number", 1001)))
	var saved_total_losses := int(config.get_value("duels", "total_losses", 0))
	var saved_consecutive_losses := int(config.get_value("duels", "consecutive_losses", 0))
	duel_matches = saved_matches.duplicate(true) if saved_matches is Dictionary else {}
	total_duels_lost = maxi(0, saved_total_losses)
	consecutive_duel_losses = clampi(saved_consecutive_losses, 0, DUEL_MAX_CONSECUTIVE_LOSSES)
	duel_disqualified = bool(config.get_value("duels", "disqualified", false))


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


## Local prototype for virtual-credit fan ticket pools. Online settlement must move to a trusted server.
func set_spectator_wallet_provider(provider: Node) -> void:
	spectator_wallet_provider = provider


func register_spectator_match(match_id: String, fighter_a_id: String, fighter_b_id: String, floor_number: int) -> Dictionary:
	match_id = match_id.strip_edges()
	fighter_a_id = fighter_a_id.strip_edges()
	fighter_b_id = fighter_b_id.strip_edges()
	if match_id.is_empty() or fighter_a_id.is_empty() or fighter_b_id.is_empty():
		return {"success": false, "reason": "INVALID_MATCH_IDENTITY"}
	if fighter_a_id == fighter_b_id:
		return {"success": false, "reason": "FIGHTERS_MUST_BE_DISTINCT"}
	if floor_number < 1 or floor_number > MAX_FLOORS:
		return {"success": false, "reason": "INVALID_FLOOR"}
	var floor_data := get_floor_data(floor_number)
	if str(floor_data.get("competition_format", "")) != "INDIVIDUAL_1V1" or int(floor_data.get("opponent_count", 0)) != 1 or int(floor_data.get("wave_count", 0)) != 1 or str(floor_data.get("opponent_kind", "")) != "HUMAN_PLAYER" or bool(floor_data.get("ai_fallback", true)) or str(floor_data.get("matchmaking_mode", "")) != "ONLINE_1V1":
		return {"success": false, "reason": "INDIVIDUAL_1V1_REQUIRED"}
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
		"total_pool": 0,
		"created_at_unix": int(Time.get_unix_time_from_system())
	}
	_save_spectator_data()
	return {"success": true, "match_id": match_id, "state": "open", "total_pool": 0}


func register_npc_spectator(npc_id: String) -> Dictionary:
	npc_id = npc_id.strip_edges()
	if npc_id.is_empty():
		return {"success": false, "reason": "INVALID_NPC_SPECTATOR"}
	var spectator_key := "npc:" + npc_id
	if not spectator_npc_ticket_balances.has(spectator_key):
		spectator_npc_ticket_balances[spectator_key] = NPC_INITIAL_TICKET_BUDGET
		_save_spectator_data()
	return {"success": true, "spectator_id": spectator_key, "ticket_balance": int(spectator_npc_ticket_balances[spectator_key]), "participant_type": "NPC"}


func submit_npc_spectator_ticket(match_id: String, npc_id: String, predicted_winner_id: String, stake_amount: int = 10) -> Dictionary:
	npc_id = npc_id.strip_edges()
	if npc_id.is_empty():
		return {"success": false, "reason": "INVALID_NPC_SPECTATOR"}
	var spectator_key := "npc:" + npc_id
	var registration := register_npc_spectator(npc_id)
	if not bool(registration.get("success", false)):
		return registration
	return submit_spectator_prediction(match_id, spectator_key, predicted_winner_id, stake_amount, true)


func submit_spectator_prediction(match_id: String, spectator_id: String, predicted_winner_id: String, stake_amount: int = 10, participant_is_npc: bool = false) -> Dictionary:
	match_id = match_id.strip_edges()
	spectator_id = spectator_id.strip_edges()
	predicted_winner_id = predicted_winner_id.strip_edges()
	if spectator_id.is_empty():
		return {"success": false, "reason": "INVALID_SPECTATOR"}
	if stake_amount < SPECTATOR_MIN_STAKE or stake_amount > SPECTATOR_MAX_STAKE:
		return {"success": false, "reason": "INVALID_TICKET_STAKE", "minimum": SPECTATOR_MIN_STAKE, "maximum": SPECTATOR_MAX_STAKE}
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
	if participant_is_npc:
		if not spectator_npc_ticket_balances.has(spectator_id):
			spectator_npc_ticket_balances[spectator_id] = NPC_INITIAL_TICKET_BUDGET
		if int(spectator_npc_ticket_balances.get(spectator_id, 0)) < stake_amount:
			return {"success": false, "reason": "INSUFFICIENT_NPC_TICKET_BUDGET"}
		spectator_npc_ticket_balances[spectator_id] = int(spectator_npc_ticket_balances.get(spectator_id, 0)) - stake_amount
	else:
		if not is_instance_valid(spectator_wallet_provider) or not spectator_wallet_provider.has_method("spend_spectator_stake"):
			return {"success": false, "reason": "SPECTATOR_WALLET_UNAVAILABLE"}
		if not bool(spectator_wallet_provider.call("spend_spectator_stake", stake_amount)):
			return {"success": false, "reason": "INSUFFICIENT_VIRTUAL_CREDITS"}
	predictions[spectator_id] = {
		"predicted_winner_id": predicted_winner_id,
		"participant_type": "NPC" if participant_is_npc else "PLAYER",
		"stake_amount": stake_amount,
		"submitted_at_unix": int(Time.get_unix_time_from_system()),
		"correct": false,
		"payout_amount": 0,
		"net_profit": -stake_amount
	}
	match_record["predictions"] = predictions
	match_record["total_pool"] = int(match_record.get("total_pool", 0)) + stake_amount
	spectator_matches[match_id] = match_record
	spectator_daily_counts[spectator_id] = {"date": today, "count": daily_count + 1}
	_save_spectator_data()
	return {"success": true, "match_id": match_id, "stake_amount": stake_amount, "total_pool": int(match_record["total_pool"]), "virtual_currency": "SYSTEM_CREDITS"}


func lock_spectator_predictions(match_id: String) -> Dictionary:
	match_id = match_id.strip_edges()
	if not spectator_matches.has(match_id):
		return {"success": false, "reason": "MATCH_NOT_FOUND"}
	var match_record: Dictionary = spectator_matches[match_id]
	if str(match_record.get("state", "")) != "open":
		return {"success": false, "reason": "MATCH_NOT_OPEN"}
	match_record["state"] = "locked"
	match_record["locked_at_unix"] = int(Time.get_unix_time_from_system())
	spectator_matches[match_id] = match_record
	_save_spectator_data()
	return {"success": true, "state": "locked", "total_pool": int(match_record.get("total_pool", 0))}


func settle_spectator_match(match_id: String, winner_id: String, settlement_source: String) -> Dictionary:
	match_id = match_id.strip_edges()
	winner_id = winner_id.strip_edges()
	if settlement_source != LOCAL_MATCH_AUTHORITY:
		return {"success": false, "reason": "UNTRUSTED_MATCH_RESULT"}
	if not spectator_matches.has(match_id):
		return {"success": false, "reason": "MATCH_NOT_FOUND"}
	var match_record: Dictionary = spectator_matches[match_id]
	if str(match_record.get("state", "")) != "locked":
		return {"success": false, "reason": "MATCH_NOT_LOCKED"}
	if winner_id != str(match_record.get("fighter_a_id", "")) and winner_id != str(match_record.get("fighter_b_id", "")):
		return {"success": false, "reason": "WINNER_NOT_IN_MATCH"}
	if not is_instance_valid(spectator_wallet_provider) or not spectator_wallet_provider.has_method("grant_spectator_payout"):
		return {"success": false, "reason": "SPECTATOR_WALLET_UNAVAILABLE"}
	var predictions: Dictionary = match_record.get("predictions", {})
	var total_pool := int(match_record.get("total_pool", 0))
	var winning_stake := 0
	var winning_ids: Array[String] = []
	for spectator_id_variant in predictions.keys():
		var spectator_id := str(spectator_id_variant)
		var prediction: Dictionary = predictions[spectator_id]
		if str(prediction.get("predicted_winner_id", "")) == winner_id:
			winning_stake += int(prediction.get("stake_amount", 0))
			winning_ids.append(spectator_id)
	var payouts: Dictionary = {}
	var profits: Dictionary = {}
	var total_paid_out := 0
	if winning_stake > 0:
		for index in range(winning_ids.size()):
			var spectator_id := winning_ids[index]
			var prediction: Dictionary = predictions[spectator_id]
			var stake := int(prediction.get("stake_amount", 0))
			var payout := total_pool - total_paid_out if index == winning_ids.size() - 1 else int(floor(float(total_pool) * float(stake) / float(winning_stake)))
			if payout > 0:
				if str(prediction.get("participant_type", "PLAYER")) == "NPC":
					spectator_npc_ticket_balances[spectator_id] = int(spectator_npc_ticket_balances.get(spectator_id, 0)) + payout
				else:
					var granted := int(spectator_wallet_provider.call("grant_spectator_payout", payout))
					if granted != payout:
						return {"success": false, "reason": "PAYOUT_GRANT_FAILED", "spectator_id": spectator_id}
			total_paid_out += payout
			prediction["correct"] = true
			prediction["payout_amount"] = payout
			prediction["net_profit"] = payout - stake
			predictions[spectator_id] = prediction
			payouts[spectator_id] = payout
			profits[spectator_id] = payout - stake
		for spectator_id_variant in predictions.keys():
			var spectator_id := str(spectator_id_variant)
			if winning_ids.has(spectator_id):
				continue
			var losing_prediction: Dictionary = predictions[spectator_id]
			losing_prediction["correct"] = false
			losing_prediction["payout_amount"] = 0
			losing_prediction["net_profit"] = -int(losing_prediction.get("stake_amount", 0))
			predictions[spectator_id] = losing_prediction
	else:
		# No correct forecast: void this pool and return each fan's virtual stake.
		for spectator_id_variant in predictions.keys():
			var spectator_id := str(spectator_id_variant)
			var prediction: Dictionary = predictions[spectator_id]
			var refund := int(prediction.get("stake_amount", 0))
			if refund > 0:
				if str(prediction.get("participant_type", "PLAYER")) == "NPC":
					spectator_npc_ticket_balances[spectator_id] = int(spectator_npc_ticket_balances.get(spectator_id, 0)) + refund
				else:
					var granted := int(spectator_wallet_provider.call("grant_spectator_payout", refund))
					if granted != refund:
						return {"success": false, "reason": "STAKE_REFUND_FAILED", "spectator_id": spectator_id}
			prediction["correct"] = false
			prediction["payout_amount"] = refund
			prediction["net_profit"] = 0
			prediction["refunded"] = true
			predictions[spectator_id] = prediction
			payouts[spectator_id] = refund
			profits[spectator_id] = 0
			total_paid_out += refund
	match_record["predictions"] = predictions
	match_record["state"] = "settled"
	match_record["winner_id"] = winner_id
	match_record["winning_stake"] = winning_stake
	match_record["total_paid_out"] = total_paid_out
	match_record["payouts"] = payouts
	match_record["net_profits"] = profits
	match_record["settled_at_unix"] = int(Time.get_unix_time_from_system())
	match_record["settlement_source"] = settlement_source
	spectator_matches[match_id] = match_record
	_save_spectator_data()
	return {"success": true, "winner_id": winner_id, "total_pool": total_pool, "winning_stake": winning_stake, "payouts": payouts, "net_profits": profits, "total_paid_out": total_paid_out, "refunded": winning_stake == 0, "virtual_currency": "SYSTEM_CREDITS", "cash_value": 0}


func get_spectator_match(match_id: String) -> Dictionary:
	match_id = match_id.strip_edges()
	var match_record: Dictionary = spectator_matches.get(match_id, {})
	return match_record.duplicate(true)


func get_spectator_status(spectator_id: String) -> Dictionary:
	spectator_id = spectator_id.strip_edges()
	var today := Time.get_date_string_from_system(true)
	var daily_record: Dictionary = spectator_daily_counts.get(spectator_id, {})
	var daily_count := int(daily_record.get("count", 0)) if str(daily_record.get("date", "")) == today else 0
	var is_npc := spectator_id.begins_with("npc:")
	var ticket_balance := int(spectator_npc_ticket_balances.get(spectator_id, 0)) if is_npc else (int(spectator_wallet_provider.call("get_spectator_wallet_balance")) if is_instance_valid(spectator_wallet_provider) and spectator_wallet_provider.has_method("get_spectator_wallet_balance") else 0)
	return {
		"spectator_id": spectator_id,
		"participant_type": "NPC" if is_npc else "PLAYER",
		"ticket_balance": ticket_balance,
		"predictions_today": daily_count,
		"daily_prediction_limit": SPECTATOR_DAILY_PREDICTION_LIMIT,
		"minimum_stake": SPECTATOR_MIN_STAKE,
		"maximum_stake": SPECTATOR_MAX_STAKE,
		"virtual_currency": "SYSTEM_CREDITS",
		"cash_value": 0,
		"transferable": false,
		"purchasable": false
	}


func _save_spectator_data() -> void:
	var config := ConfigFile.new()
	config.set_value("spectators", "matches", spectator_matches)
	config.set_value("spectators", "points", spectator_prediction_points)
	config.set_value("spectators", "daily_counts", spectator_daily_counts)
	config.set_value("spectators", "npc_ticket_balances", spectator_npc_ticket_balances)
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
	var saved_npc_balances: Variant = config.get_value("spectators", "npc_ticket_balances", {})
	spectator_matches = saved_matches.duplicate(true) if saved_matches is Dictionary else {}
	spectator_prediction_points = saved_points.duplicate(true) if saved_points is Dictionary else {}
	spectator_daily_counts = saved_daily_counts.duplicate(true) if saved_daily_counts is Dictionary else {}
	spectator_npc_ticket_balances = saved_npc_balances.duplicate(true) if saved_npc_balances is Dictionary else {}

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
	config.set_value("tower", "total_duels_lost", total_duels_lost)
	config.set_value("tower", "consecutive_duel_losses", consecutive_duel_losses)
	config.set_value("tower", "duel_disqualified", duel_disqualified)
	config.set_value("tower", "elite_duels_won", elite_duels_won)
	config.set_value("tower", "boss_duels_won", boss_duels_won)
	config.set_value("tower", "total_xp_earned", total_xp_earned)
	config.set_value("tower", "total_credits_earned", total_credits_earned)
	config.set_value("tower", "processed_result_ids", processed_result_ids)
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
	total_duels_lost = maxi(0, int(config.get_value("tower", "total_duels_lost", 0)))
	consecutive_duel_losses = clampi(int(config.get_value("tower", "consecutive_duel_losses", 0)), 0, DUEL_MAX_CONSECUTIVE_LOSSES)
	duel_disqualified = bool(config.get_value("tower", "duel_disqualified", false))
	elite_duels_won = maxi(0, int(config.get_value("tower", "elite_duels_won", 0)))
	boss_duels_won = maxi(0, int(config.get_value("tower", "boss_duels_won", 0)))
	total_xp_earned = maxi(0, int(config.get_value("tower", "total_xp_earned", 0)))
	total_credits_earned = maxi(0, int(config.get_value("tower", "total_credits_earned", 0)))
	var saved_result_ids: Dictionary = config.get_value("tower", "processed_result_ids", {})
	processed_result_ids = saved_result_ids.duplicate(true)
