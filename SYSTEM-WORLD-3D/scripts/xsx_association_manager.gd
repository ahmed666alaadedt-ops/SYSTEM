
extends Node

class_name XSXAssociationManager

# SYSTEM WORLD - XSX Hunter Association
# Godot 4.3
# Modular foundation: Hunter identity, license, benefits and rewards.
# Local prototype storage. Valuable rewards require future server validation.

signal hunter_profile_changed(player_id: String)
signal license_granted(player_id: String, card_id: String)
signal privileges_updated(player_id: String)
signal service_used(player_id: String, service_id: String)
signal reward_awarded(player_id: String, xp: int, currency: int)

const SAVE_PATH := "user://xsx_association_data.json"
const SAVE_VERSION := 1

const MIN_EXAM_SCORE := 70

const RANK_DATA := {
	"E": {
		"xp_multiplier": 1.15,
		"currency_multiplier": 1.10,
		"skill_discovery_bonus": 0.02,
		"daily_hotel": 1,
		"daily_meals": 1,
		"daily_training": 1,
		"rare_equipment_access": false
	},
	"D": {
		"xp_multiplier": 1.20,
		"currency_multiplier": 1.15,
		"skill_discovery_bonus": 0.04,
		"daily_hotel": 1,
		"daily_meals": 2,
		"daily_training": 2,
		"rare_equipment_access": false
	},
	"C": {
		"xp_multiplier": 1.25,
		"currency_multiplier": 1.20,
		"skill_discovery_bonus": 0.06,
		"daily_hotel": 2,
		"daily_meals": 2,
		"daily_training": 2,
		"rare_equipment_access": true
	},
	"B": {
		"xp_multiplier": 1.30,
		"currency_multiplier": 1.25,
		"skill_discovery_bonus": 0.08,
		"daily_hotel": 2,
		"daily_meals": 3,
		"daily_training": 3,
		"rare_equipment_access": true
	},
	"A": {
		"xp_multiplier": 1.40,
		"currency_multiplier": 1.35,
		"skill_discovery_bonus": 0.12,
		"daily_hotel": 3,
		"daily_meals": 3,
		"daily_training": 3,
		"rare_equipment_access": true
	},
	"S": {
		"xp_multiplier": 1.50,
		"currency_multiplier": 1.45,
		"skill_discovery_bonus": 0.15,
		"daily_hotel": 5,
		"daily_meals": 4,
		"daily_training": 4,
		"rare_equipment_access": true
	}
}

const SERVICE_DATA := {
	"transport": {
		"name": "النقل والقطارات",
		"coverage": 1.0,
		"daily_limit": -1
	},
	"hotel": {
		"name": "الفنادق والإقامة",
		"coverage": 1.0,
		"daily_limit_key": "daily_hotel"
	},
	"restaurant": {
		"name": "المطاعم والوجبات",
		"coverage": 1.0,
		"daily_limit_key": "daily_meals"
	},
	"medical": {
		"name": "العلاج الطبي الأساسي",
		"coverage": 1.0,
		"daily_limit": -1
	},
	"emergency": {
		"name": "الطوارئ والإنقاذ",
		"coverage": 1.0,
		"daily_limit": -1
	},
	"training": {
		"name": "التدريب المتخصص",
		"coverage": 1.0,
		"daily_limit_key": "daily_training"
	},
	"rare_shop": {
		"name": "متاجر معدات الصيادين النادرة",
		"coverage": 0.0,
		"daily_limit": -1
	}
}

var profiles: Dictionary = {}


func _ready() -> void:
	load_data()


# ==================================================
# PLAYER REGISTRATION
# ==================================================

func register_player(
	player_id: String,
	player_name: String
) -> Dictionary:

	if player_id.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_PLAYER_ID"}

	if not profiles.has(player_id):
		profiles[player_id] = {
			"player_id": player_id,
			"player_name": player_name,
			"membership_status": "independent",
			"license_active": false,
			"card_id": "",
			"rank": "",
			"exam_history": [],
			"total_hunter_xp": 0,
			"total_mission_currency": 0,
			"achievements": [],
			"service_date": Time.get_date_string_from_system(),
			"service_usage": {},
			"created_at": Time.get_datetime_string_from_system()
		}

	else:
		profiles[player_id]["player_name"] = player_name

	save_data()

	return {
		"success": true,
		"profile": get_hunter_profile(player_id)
	}


func get_hunter_profile(player_id: String) -> Dictionary:
	if not profiles.has(player_id):
		return {}

	return profiles[player_id].duplicate(true)


func is_registered_hunter(player_id: String) -> bool:
	if not profiles.has(player_id):
		return false

	var profile: Dictionary = profiles[player_id]

	return (
		bool(profile.get("license_active", false))
		and profile.get("membership_status", "") == "licensed"
	)


# ==================================================
# EXAMINATION CANDIDACY
# ==================================================

func apply_for_examination(player_id: String) -> Dictionary:

	if not profiles.has(player_id):
		return {"success": false, "reason": "PLAYER_NOT_REGISTERED"}

	var profile: Dictionary = profiles[player_id]

	if is_registered_hunter(player_id):
		return {"success": false, "reason": "ALREADY_LICENSED"}

	profile["membership_status"] = "candidate"
	profile["last_exam_application"] = Time.get_datetime_string_from_system()

	profiles[player_id] = profile

	save_data()
	hunter_profile_changed.emit(player_id)

	return {"success": true, "status": "candidate"}


# Called by the examination system after its evaluation.
# This local prototype is not a secure anti-cheat authority.
func process_examination_result(
	player_id: String,
	exam_id: String,
	passed: bool,
	score: int
) -> Dictionary:

	if not profiles.has(player_id):
		return {"success": false, "reason": "PLAYER_NOT_REGISTERED"}

	var profile: Dictionary = profiles[player_id]

	if profile.get("membership_status", "") != "candidate":
		return {"success": false, "reason": "NOT_AN_EXAM_CANDIDATE"}

	var final_score := clampi(score, 0, 100)

	var exam_record := {
		"exam_id": exam_id,
		"score": final_score,
		"passed": passed and final_score >= MIN_EXAM_SCORE,
		"date": Time.get_datetime_string_from_system()
	}

	var history: Array = profile.get("exam_history", [])
	history.append(exam_record)
	profile["exam_history"] = history

	if exam_record["passed"]:
		var card_id := _generate_card_id()

		profile["membership_status"] = "licensed"
		profile["license_active"] = true
		profile["card_id"] = card_id
		profile["rank"] = "E"
		profile["license_date"] = Time.get_datetime_string_from_system()

		profiles[player_id] = profile

		save_data()

		license_granted.emit(player_id, card_id)
		hunter_profile_changed.emit(player_id)
		privileges_updated.emit(player_id)

		return {
			"success": true,
			"passed": true,
			"card_id": card_id,
			"rank": "E"
		}

	profile["membership_status"] = "independent"
	profiles[player_id] = profile

	save_data()
	hunter_profile_changed.emit(player_id)

	return {
		"success": true,
		"passed": false,
		"score": final_score,
		"reason": "EXAM_NOT_PASSED"
	}


func _generate_card_id() -> String:
	return "XSX-%08d" % randi_range(10000000, 99999999)


# ==================================================
# HUNTER CARD
# ==================================================

func get_hunter_card(player_id: String) -> Dictionary:

	if not is_registered_hunter(player_id):
		return {}

	var profile: Dictionary = profiles[player_id]

	return {
		"card_id": profile.get("card_id", ""),
		"player_id": player_id,
		"player_name": profile.get("player_name", ""),
		"organization": "XSX",
		"license_status": "ACTIVE",
		"rank": profile.get("rank", "E"),
		"license_date": profile.get("license_date", ""),
		"total_hunter_xp": profile.get("total_hunter_xp", 0),
		"achievements": profile.get("achievements", []).duplicate(true)
	}


func get_hunter_rank(player_id: String) -> String:

	if not is_registered_hunter(player_id):
		return ""

	return str(profiles[player_id].get("rank", "E"))


# ==================================================
# XSX PRIVILEGES
# ==================================================

func get_service_entitlement(
	player_id: String,
	service_id: String
) -> Dictionary:

	if not SERVICE_DATA.has(service_id):
		return {"available": false, "reason": "UNKNOWN_SERVICE"}

	if not is_registered_hunter(player_id):
		return {
			"available": false,
			"free": false,
			"coverage": 0.0,
			"reason": "XSX_LICENSE_REQUIRED"
		}

	var profile: Dictionary = profiles[player_id]
	var rank := str(profile.get("rank", "E"))
	var rank_data: Dictionary = RANK_DATA.get(rank, RANK_DATA["E"])
	var service: Dictionary = SERVICE_DATA[service_id]

	var daily_limit := int(service.get("daily_limit", -1))
	var limit_key := str(service.get("daily_limit_key", ""))

	if not limit_key.is_empty():
		daily_limit = int(rank_data.get(limit_key, 0))

	return {
		"available": true,
		"free": true,
		"coverage": float(service.get("coverage", 1.0)),
		"daily_limit": daily_limit,
		"rank": rank,
		"service_name": service.get("name", service_id)
	}


func use_service(
	player_id: String,
	service_id: String
) -> Dictionary:

	var entitlement := get_service_entitlement(
		player_id,
		service_id
	)

	if not bool(entitlement.get("available", false)):
		return {
			"success": false,
			"reason": entitlement.get("reason", "NOT_AVAILABLE")
		}

	var profile: Dictionary = profiles[player_id]
	_reset_daily_usage(profile)

	var usage: Dictionary = profile.get("service_usage", {})
	var used := int(usage.get(service_id, 0))
	var limit := int(entitlement.get("daily_limit", -1))

	if limit >= 0 and used >= limit:
		return {
			"success": false,
			"reason": "DAILY_ALLOWANCE_EXCEEDED",
			"daily_limit": limit
		}

	if limit >= 0:
		usage[service_id] = used + 1

	profile["service_usage"] = usage
	profiles[player_id] = profile

	save_data()

	service_used.emit(player_id, service_id)

	return {
		"success": true,
		"free": true,
		"service": service_id,
		"remaining": -1 if limit < 0 else limit - used - 1
	}


func _reset_daily_usage(profile: Dictionary) -> void:

	var today := Time.get_date_string_from_system()

	if str(profile.get("service_date", "")) != today:
		profile["service_date"] = today
		profile["service_usage"] = {}


func get_all_privileges(player_id: String) -> Dictionary:

	if not is_registered_hunter(player_id):
		return {}

	var result := {}

	for service_id in SERVICE_DATA.keys():
		result[service_id] = get_service_entitlement(
			player_id,
			str(service_id)
		)

	var rank := get_hunter_rank(player_id)

	result["rank_benefits"] = RANK_DATA.get(
		rank,
		RANK_DATA["E"]
	).duplicate(true)

	return result


# ==================================================
# MISSION REWARDS
# ==================================================

func calculate_mission_rewards(
	player_id: String,
	base_xp: int,
	base_currency: int
) -> Dictionary:

	var xp_multiplier := 1.0
	var currency_multiplier := 1.0

	if is_registered_hunter(player_id):
		var rank := get_hunter_rank(player_id)
		var rank_data: Dictionary = RANK_DATA.get(
			rank,
			RANK_DATA["E"]
		)

		xp_multiplier = float(rank_data["xp_multiplier"])
		currency_multiplier = float(rank_data["currency_multiplier"])

	var final_xp := int(round(
		maxi(0, base_xp) * xp_multiplier
	))

	var final_currency := int(round(
		maxi(0, base_currency) * currency_multiplier
	))

	return {
		"base_xp": base_xp,
		"base_currency": base_currency,
		"final_xp": final_xp,
		"final_currency": final_currency,
		"xp_multiplier": xp_multiplier,
		"currency_multiplier": currency_multiplier
	}


func award_mission_rewards(
	player_id: String,
	base_xp: int,
	base_currency: int
) -> Dictionary:

	if not profiles.has(player_id):
		return {"success": false, "reason": "PLAYER_NOT_REGISTERED"}

	var rewards := calculate_mission_rewards(
		player_id,
		base_xp,
		base_currency
	)

	var profile: Dictionary = profiles[player_id]

	profile["total_hunter_xp"] = (
		int(profile.get("total_hunter_xp", 0))
		+ int(rewards["final_xp"])
	)

	profile["total_mission_currency"] = (
		int(profile.get("total_mission_currency", 0))
		+ int(rewards["final_currency"])
	)

	profiles[player_id] = profile

	save_data()

	reward_awarded.emit(
		player_id,
		int(rewards["final_xp"]),
		int(rewards["final_currency"])
	)

	hunter_profile_changed.emit(player_id)

	return {
		"success": true,
		"rewards": rewards
	}


# ==================================================
# SKILLS AND RARE EQUIPMENT
# ==================================================

func get_skill_discovery_bonus(player_id: String) -> float:

	if not is_registered_hunter(player_id):
		return 0.0

	var rank := get_hunter_rank(player_id)
	var rank_data: Dictionary = RANK_DATA.get(
		rank,
		RANK_DATA["E"]
	)

	return float(rank_data.get("skill_discovery_bonus", 0.0))


func can_access_rare_equipment(player_id: String) -> bool:

	if not is_registered_hunter(player_id):
		return false

	var rank := get_hunter_rank(player_id)
	var rank_data: Dictionary = RANK_DATA.get(
		rank,
		RANK_DATA["E"]
	)

	return bool(rank_data.get("rare_equipment_access", false))


# ==================================================
# RANK MANAGEMENT
# ==================================================

func set_hunter_rank(
	player_id: String,
	new_rank: String
) -> Dictionary:

	if not profiles.has(player_id):
		return {"success": false, "reason": "PLAYER_NOT_REGISTERED"}

	if not RANK_DATA.has(new_rank):
		return {"success": false, "reason": "INVALID_RANK"}

	if not is_registered_hunter(player_id):
		return {"success": false, "reason": "LICENSE_REQUIRED"}

	var profile: Dictionary = profiles[player_id]
	profile["rank"] = new_rank
	profiles[player_id] = profile

	save_data()

	hunter_profile_changed.emit(player_id)
	privileges_updated.emit(player_id)

	return {"success": true, "rank": new_rank}


# ==================================================
# PERSISTENCE
# ==================================================

func save_data() -> bool:

	var payload := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"profiles": profiles
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("XSX: Could not open save file.")
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	return true


func load_data() -> bool:

	if not FileAccess.file_exists(SAVE_PATH):
		profiles = {}
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("XSX: Could not read save file.")
		return false

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("XSX: Invalid save data.")
		return false

	if int(parsed.get("save_version", -1)) != SAVE_VERSION:
		push_warning("XSX: Save version is not compatible.")
		return false

	var saved_profiles = parsed.get("profiles", {})

	if typeof(saved_profiles) != TYPE_DICTIONARY:
		return false

	profiles = saved_profiles.duplicate(true)

	return true


func get_registered_player_count() -> int:
	return profiles.size()
