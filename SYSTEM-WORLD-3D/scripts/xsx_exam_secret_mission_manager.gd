
extends Node

class_name XSXExamSecretMissionManager

# SYSTEM WORLD - XSX Secret Examination Missions
# Godot 4.3
# Local prototype. Real multiplayer requires server validation.

signal missions_created(exam_id: String)
signal secret_mission_assigned(player_id: String, mission_id: String)
signal mission_progress_changed(player_id: String, mission_id: String)
signal secret_mission_completed(player_id: String, mission_id: String)
signal alliance_recorded(exam_id: String, player_a: String, player_b: String)
signal deception_recorded(exam_id: String, player_id: String)

const SAVE_PATH := "user://xsx_secret_missions.json"
const SAVE_VERSION := 1

const MISSION_TYPES := [
	"steal_number",
	"protect_number",
	"form_alliance",
	"deception",
	"collect_numbers"
]

var exam_missions: Dictionary = {}


func _ready() -> void:
	randomize()
	load_data()


# ==================================================
# CREATE SECRET MISSIONS
# ==================================================

func create_missions(
	exam_id: String,
	human_player_ids: Array
) -> Dictionary:

	if exam_id.strip_edges().is_empty():
		return _failure("INVALID_EXAM_ID")

	if human_player_ids.size() < 2:
		return _failure("NEED_AT_LEAST_TWO_HUMAN_PLAYERS")

	if exam_missions.has(exam_id):
		return _failure("MISSIONS_ALREADY_CREATED")

	var unique_players: Array = []

	for player_id in human_player_ids:
		var id := str(player_id).strip_edges()

		if id.is_empty():
			continue

		if not unique_players.has(id):
			unique_players.append(id)

	if unique_players.size() < 2:
		return _failure("NOT_ENOUGH_UNIQUE_PLAYERS")

	var session := {
		"exam_id": exam_id,
		"created_at": Time.get_datetime_string_from_system(),
		"finished": false,
		"participants": {},
		"alliances": [],
		"deception_events": [],
		"action_log": []
	}

	for player_id in unique_players:
		session["participants"][player_id] = {
			"player_id": player_id,
			"mission": {},
			"progress": 0,
			"completed": false,
			"secret_actions": 0,
			"penalties": 0
		}

	for player_id in unique_players:
		var mission := _generate_mission(
			player_id,
			unique_players
		)

		session["participants"][player_id]["mission"] = mission

	exam_missions[exam_id] = session

	save_data()
	missions_created.emit(exam_id)

	for player_id in unique_players:
		var mission: Dictionary = session["participants"][player_id]["mission"]
		secret_mission_assigned.emit(
			player_id,
			str(mission.get("mission_id", ""))
		)

	return {
		"success": true,
		"exam_id": exam_id,
		"participant_count": unique_players.size()
	}


func _generate_mission(
	player_id: String,
	players: Array
) -> Dictionary:

	var possible_targets: Array = []

	for target_id in players:
		if str(target_id) != player_id:
			possible_targets.append(str(target_id))

	var mission_type: String = MISSION_TYPES[
		randi_range(0, MISSION_TYPES.size() - 1)
	]

	var mission := {
		"mission_id": "SECRET-%08d" % randi_range(10000000, 99999999),
		"type": mission_type,
		"title": "",
		"description": "",
		"target_player_id": "",
		"target_progress": 1,
		"reward_points": 100,
		"revealed": false
	}

	match mission_type:

		"steal_number":
			mission["title"] = "انتزاع الرقم"
			mission["description"] = "انتزع رقم متسابق آخر وفق قوانين الاختبار."
			mission["target_player_id"] = possible_targets[
				randi_range(0, possible_targets.size() - 1)
			]
			mission["target_progress"] = 1
			mission["reward_points"] = 150

		"protect_number":
			mission["title"] = "حماية الرقم"
			mission["description"] = "حافظ على رقمك حتى نهاية المرحلة المحددة."
			mission["target_progress"] = 1
			mission["reward_points"] = 120

		"form_alliance":
			mission["title"] = "تحالف سري"
			mission["description"] = "كوّن تحالفاً سرياً مع متسابق آخر."
			mission["target_player_id"] = possible_targets[
				randi_range(0, possible_targets.size() - 1)
			]
			mission["target_progress"] = 1
			mission["reward_points"] = 100

		"deception":
			mission["title"] = "خطة التمويه"
			mission["description"] = "نفّذ خطة تمويه ناجحة ضمن قواعد الاختبار."
			mission["target_progress"] = 1
			mission["reward_points"] = 130

		"collect_numbers":
			mission["title"] = "جامع الأرقام"
			mission["description"] = "اجمع أرقام متسابقين آخرين."
			mission["target_progress"] = 2
			mission["reward_points"] = 200

	return mission


# ==================================================
# PRIVATE MISSION INFORMATION
# ==================================================

func get_player_secret_mission(
	exam_id: String,
	player_id: String
) -> Dictionary:

	if not exam_missions.has(exam_id):
		return {}

	var session: Dictionary = exam_missions[exam_id]
	var participants: Dictionary = session["participants"]

	if not participants.has(player_id):
		return {}

	var participant: Dictionary = participants[player_id]

	return {
		"mission": participant["mission"].duplicate(true),
		"progress": int(participant["progress"]),
		"completed": bool(participant["completed"])
	}


func get_public_mission_status(
	exam_id: String,
	player_id: String
) -> Dictionary:

	if not exam_missions.has(exam_id):
		return {}

	var session: Dictionary = exam_missions[exam_id]
	var participants: Dictionary = session["participants"]

	if not participants.has(player_id):
		return {}

	var participant: Dictionary = participants[player_id]
	var mission: Dictionary = participant["mission"]

	# Never expose secret mission type or target.
	return {
		"player_id": player_id,
		"completed": participant["completed"],
		"progress": participant["progress"]
	}


# ==================================================
# ACTION VALIDATION
# ==================================================

func record_number_stolen(
	exam_id: String,
	thief_id: String,
	target_id: String,
	number: int
) -> Dictionary:

	if thief_id == target_id:
		return _failure("INVALID_THEFT")

	if number <= 0:
		return _failure("INVALID_NUMBER")

	if not _valid_participants(exam_id, thief_id, target_id):
		return _failure("PARTICIPANT_NOT_FOUND")

	_add_action_log(exam_id, {
		"type": "number_stolen",
		"actor": thief_id,
		"target": target_id,
		"number": number
	})

	var thief_mission := get_player_secret_mission(
		exam_id,
		thief_id
	)

	if thief_mission.is_empty():
		return {"success": true, "mission_updated": false}

	var mission: Dictionary = thief_mission["mission"]

	if mission["type"] == "steal_number":
		if str(mission["target_player_id"]) == target_id:
			_increase_progress(exam_id, thief_id, 1)

	elif mission["type"] == "collect_numbers":
		_increase_progress(exam_id, thief_id, 1)

	var target_mission := get_player_secret_mission(
		exam_id,
		target_id
	)

	if not target_mission.is_empty():
		var target_type: String = target_mission["mission"]["type"]

		if target_type == "protect_number":
			# Losing the number prevents this protection objective
			# from being completed later in this mission.
			_add_penalty(exam_id, target_id)

	return {
		"success": true,
		"mission_updated": true
	}


func record_alliance(
	exam_id: String,
	player_a: String,
	player_b: String
) -> Dictionary:

	if player_a == player_b:
		return _failure("CANNOT_ALLY_WITH_SELF")

	if not _valid_participants(exam_id, player_a, player_b):
		return _failure("PARTICIPANT_NOT_FOUND")

	var session: Dictionary = exam_missions[exam_id]
	var alliances: Array = session["alliances"]

	for alliance in alliances:
		var same_pair := (
			(
				alliance["player_a"] == player_a
				and alliance["player_b"] == player_b
			)
			or
			(
				alliance["player_a"] == player_b
				and alliance["player_b"] == player_a
			)
		)

		if same_pair:
			return _failure("ALLIANCE_ALREADY_RECORDED")

	alliances.append({
		"player_a": player_a,
		"player_b": player_b,
		"created_at": Time.get_datetime_string_from_system(),
		"active": true
	})

	session["alliances"] = alliances
	exam_missions[exam_id] = session

	_increase_progress(exam_id, player_a, 1)
	_increase_progress(exam_id, player_b, 1)

	save_data()
	alliance_recorded.emit(exam_id, player_a, player_b)

	return {"success": true}


func record_deception(
	exam_id: String,
	player_id: String,
	target_id: String,
	description: String
) -> Dictionary:

	if not _valid_participants(exam_id, player_id, target_id):
		return _failure("PARTICIPANT_NOT_FOUND")

	if description.strip_edges().is_empty():
		return _failure("DESCRIPTION_REQUIRED")

	var session: Dictionary = exam_missions[exam_id]
	var events: Array = session["deception_events"]

	events.append({
		"player_id": player_id,
		"target_id": target_id,
		"description": description,
		"timestamp": Time.get_datetime_string_from_system(),
		"verified": false
	})

	session["deception_events"] = events
	exam_missions[exam_id] = session

	_add_action_log(exam_id, {
		"type": "deception_attempt",
		"actor": player_id,
		"target": target_id
	})

	save_data()
	deception_recorded.emit(exam_id, player_id)

	return {
		"success": true,
		"pending_verification": true
	}


func verify_deception(
	exam_id: String,
	event_index: int,
	approved: bool
) -> Dictionary:

	if not exam_missions.has(exam_id):
		return _failure("EXAM_NOT_FOUND")

	var session: Dictionary = exam_missions[exam_id]
	var events: Array = session["deception_events"]

	if event_index < 0 or event_index >= events.size():
		return _failure("INVALID_EVENT")

	var event: Dictionary = events[event_index]

	if bool(event.get("verified", false)):
		return _failure("EVENT_ALREADY_VERIFIED")

	event["verified"] = true
	event["approved"] = approved

	events[event_index] = event
	session["deception_events"] = events
	exam_missions[exam_id] = session

	if approved:
		_increase_progress(exam_id, str(event["player_id"]), 1)

	save_data()

	return {
		"success": true,
		"approved": approved
	}


# ==================================================
# PROTECTION OBJECTIVE
# ==================================================

func verify_number_protection(
	exam_id: String,
	player_id: String,
	stage_finished: bool,
	still_holds_original_number: bool
) -> Dictionary:

	if not exam_missions.has(exam_id):
		return _failure("EXAM_NOT_FOUND")

	var mission_data := get_player_secret_mission(
		exam_id,
		player_id
	)

	if mission_data.is_empty():
		return _failure("PLAYER_NOT_FOUND")

	var mission: Dictionary = mission_data["mission"]

	if mission["type"] != "protect_number":
		return _failure("WRONG_MISSION_TYPE")

	if not stage_finished:
		return _failure("STAGE_NOT_FINISHED")

	if not still_holds_original_number:
		_add_penalty(exam_id, player_id)
		return _failure("ORIGINAL_NUMBER_NOT_PROTECTED")

	_increase_progress(exam_id, player_id, 1)

	return {"success": true}


# ==================================================
# PROGRESS AND REWARDS
# ==================================================

func _increase_progress(
	exam_id: String,
	player_id: String,
	amount: int
) -> void:

	var session: Dictionary = exam_missions[exam_id]
	var participants: Dictionary = session["participants"]

	if not participants.has(player_id):
		return

	var participant: Dictionary = participants[player_id]

	if bool(participant["completed"]):
		return

	var mission: Dictionary = participant["mission"]

	participant["progress"] = min(
		int(participant["progress"]) + amount,
		int(mission["target_progress"])
	)

	if int(participant["progress"]) >= int(mission["target_progress"]):
		participant["completed"] = true

		secret_mission_completed.emit(
			player_id,
			str(mission["mission_id"])
		)

	participants[player_id] = participant
	session["participants"] = participants
	exam_missions[exam_id] = session

	save_data()

	mission_progress_changed.emit(
		player_id,
		str(mission["mission_id"])
	)


func _add_penalty(
	exam_id: String,
	player_id: String
) -> void:

	var session: Dictionary = exam_missions[exam_id]
	var participants: Dictionary = session["participants"]

	if not participants.has(player_id):
		return

	var participant: Dictionary = participants[player_id]
	participant["penalties"] = int(participant["penalties"]) + 1

	participants[player_id] = participant
	session["participants"] = participants
	exam_missions[exam_id] = session

	save_data()


func get_mission_result(
	exam_id: String,
	player_id: String
) -> Dictionary:

	if not exam_missions.has(exam_id):
		return {}

	var participants: Dictionary = exam_missions[exam_id]["participants"]

	if not participants.has(player_id):
		return {}

	var participant: Dictionary = participants[player_id]
	var mission: Dictionary = participant["mission"]

	return {
		"completed": participant["completed"],
		"progress": participant["progress"],
		"required": mission["target_progress"],
		"reward_points": mission["reward_points"] if participant["completed"] else 0,
		"penalties": participant["penalties"]
	}


# ==================================================
# INTERNAL HELPERS
# ==================================================

func _valid_participants(
	exam_id: String,
	player_a: String,
	player_b: String
) -> bool:

	if not exam_missions.has(exam_id):
		return false

	var participants: Dictionary = exam_missions[exam_id]["participants"]

	return (
		participants.has(player_a)
		and participants.has(player_b)
	)


func _add_action_log(
	exam_id: String,
	action: Dictionary
) -> void:

	var session: Dictionary = exam_missions[exam_id]
	var log: Array = session["action_log"]

	action["timestamp"] = Time.get_datetime_string_from_system()
	log.append(action)

	session["action_log"] = log
	exam_missions[exam_id] = session

	save_data()


func get_alliances(exam_id: String) -> Array:
	if not exam_missions.has(exam_id):
		return []

	return exam_missions[exam_id]["alliances"].duplicate(true)


# ==================================================
# EXAM CONTROL
# ==================================================

func finish_secret_missions(exam_id: String) -> Dictionary:

	if not exam_missions.has(exam_id):
		return _failure("EXAM_NOT_FOUND")

	var session: Dictionary = exam_missions[exam_id]
	session["finished"] = true
	session["finished_at"] = Time.get_datetime_string_from_system()

	exam_missions[exam_id] = session
	save_data()

	return {
		"success": true,
		"exam_id": exam_id
	}


# ==================================================
# SAVE AND LOAD
# ==================================================

func save_data() -> bool:

	var payload := {
		"save_version": SAVE_VERSION,
		"exam_missions": exam_missions,
		"saved_at": Time.get_datetime_string_from_system()
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("XSX Secret Missions: Save failed.")
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	return true


func load_data() -> bool:

	if not FileAccess.file_exists(SAVE_PATH):
		exam_missions = {}
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	if int(parsed.get("save_version", -1)) != SAVE_VERSION:
		return false

	var saved = parsed.get("exam_missions", {})

	if typeof(saved) != TYPE_DICTIONARY:
		return false

	exam_missions = saved.duplicate(true)
	return true


func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason
	}
