
extends Node
class_name XSXExamSecretMissionManager

# SYSTEM WORLD - XSX Secret Examination Missions
# Godot 4.3
# Local prototype. Trusted server validation is required
# before enabling competitive online multiplayer.

signal missions_created(exam_id: String)
signal secret_mission_assigned(player_id: String, mission_id: String)
signal mission_progress_changed(player_id: String, mission_id: String)
signal secret_mission_completed(player_id: String, mission_id: String)
signal alliance_requested(exam_id: String, requester: String, target: String)
signal alliance_recorded(exam_id: String, player_a: String, player_b: String)
signal deception_recorded(exam_id: String, player_id: String)

const SAVE_PATH := "user://xsx_secret_missions.json"
const SAVE_VERSION := 2

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
# CREATE MISSIONS
# ==================================================

# cohort_id defaults to exam_id for compatibility.
# The cohort must already be active before missions are created.

func create_missions(
	exam_id: String,
	human_player_ids: Array,
	cohort_id: String = ""
) -> Dictionary:

	if exam_id.strip_edges().is_empty():
		return _failure("INVALID_EXAM_ID")

	var linked_cohort := cohort_id.strip_edges()

	if linked_cohort.is_empty():
		linked_cohort = exam_id

	if exam_missions.has(exam_id):
		return _failure("MISSIONS_ALREADY_CREATED")

	if XSXCohorts.get_cohort_status(linked_cohort) != "active":
		return _failure("COHORT_NOT_ACTIVE")

	var unique_players: Array = []

	for value in human_player_ids:
		var player_id := str(value).strip_edges()

		if player_id.is_empty():
			continue

		if not unique_players.has(player_id):
			unique_players.append(player_id)

	if unique_players.size() < 2:
		return _failure("NEED_TWO_UNIQUE_HUMAN_PLAYERS")

	for player_id in unique_players:
		if not XSXCohorts.is_active_contestant(
			linked_cohort,
			player_id
		):
			return _failure("PLAYER_NOT_ACTIVE_IN_COHORT")

	var session := {
		"exam_id": exam_id,
		"cohort_id": linked_cohort,
		"created_at": Time.get_datetime_string_from_system(),
		"finished": false,
		"participants": {},
		"alliances": [],
		"alliance_requests": [],
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
			str(mission["mission_id"])
		)

	return {
		"success": true,
		"exam_id": exam_id,
		"cohort_id": linked_cohort,
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
			mission["description"] = "انتزع رقم المتسابق المحدد وفق قوانين الاختبار."
			mission["target_player_id"] = possible_targets[
				randi_range(0, possible_targets.size() - 1)
			]
			mission["reward_points"] = 150

		"protect_number":
			mission["title"] = "حماية الرقم"
			mission["description"] = "حافظ على رقمك الأصلي حتى نهاية المرحلة."
			mission["reward_points"] = 120

		"form_alliance":
			mission["title"] = "تحالف سري"
			mission["description"] = "اطلب تحالفاً سرياً واحصل على موافقة الطرف الآخر."
			mission["target_player_id"] = possible_targets[
				randi_range(0, possible_targets.size() - 1)
			]
			mission["reward_points"] = 100

		"deception":
			mission["title"] = "خطة التمويه"
			mission["description"] = "نفّذ خطة تمويه ناجحة تخضع للتحقق."
			mission["reward_points"] = 130

		"collect_numbers":
			mission["title"] = "جامع الأرقام"
			mission["description"] = "اجمع أرقام متسابقين آخرين."
			mission["target_progress"] = 2
			mission["reward_points"] = 200

	return mission


# ==================================================
# MISSION INFORMATION
# ==================================================

func get_player_secret_mission(
	exam_id: String,
	player_id: String
) -> Dictionary:

	if not exam_missions.has(exam_id):
		return {}

	var participants: Dictionary = exam_missions[exam_id]["participants"]

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

	var participants: Dictionary = exam_missions[exam_id]["participants"]

	if not participants.has(player_id):
		return {}

	var participant: Dictionary = participants[player_id]

	# Never expose mission type, target, or secret description.
	return {
		"player_id": player_id,
		"completed": participant["completed"],
		"progress": participant["progress"]
	}


# ==================================================
# VERIFIED NUMBER THEFT
# ==================================================

func record_number_stolen(
	exam_id: String,
	thief_id: String,
	target_id: String,
	number: int
) -> Dictionary:

	if thief_id == target_id or number <= 0:
		return _failure("INVALID_THEFT")

	if not _valid_participants(exam_id, thief_id, target_id):
		return _failure("PARTICIPANT_NOT_ACTIVE")

	var session: Dictionary = exam_missions[exam_id]
	var cohort_id: String = str(session["cohort_id"])

	# The cohort manager must confirm that the number
	# is now actually owned by the thief.
	if XSXCohorts.get_number_owner(cohort_id, number) != thief_id:
		return _failure("THEFT_NOT_CONFIRMED_BY_COHORT")

	# Confirm that the cohort event log contains the
	# exact transfer from the intended target to the thief.
	if not _has_confirmed_transfer(
		cohort_id,
		number,
		target_id,
		thief_id
	):
		return _failure("TRANSFER_EVENT_NOT_FOUND")

	_add_action_log(exam_id, {
		"type": "number_stolen",
		"actor": thief_id,
		"target": target_id,
		"number": number
	})

	var thief_data := get_player_secret_mission(exam_id, thief_id)

	if not thief_data.is_empty():
		var thief_mission: Dictionary = thief_data["mission"]

		if thief_mission["type"] == "steal_number":
			if str(thief_mission["target_player_id"]) == target_id:
				_increase_progress(exam_id, thief_id, 1)

		elif thief_mission["type"] == "collect_numbers":
			_increase_progress(exam_id, thief_id, 1)

	var target_data := get_player_secret_mission(exam_id, target_id)

	if not target_data.is_empty():
		var target_mission: Dictionary = target_data["mission"]

		if target_mission["type"] == "protect_number":
			_add_penalty(exam_id, target_id)

	return {
		"success": true,
		"number": number,
		"thief": thief_id,
		"previous_owner": target_id
	}


func _has_confirmed_transfer(
	cohort_id: String,
	number: int,
	previous_owner: String,
	new_owner: String
) -> bool:

	var events: Array = XSXCohorts.get_event_log(cohort_id)

	for i in range(events.size() - 1, -1, -1):
		var event: Dictionary = events[i]

		if str(event.get("type", "")) != "number_transferred":
			continue

		if int(event.get("number", -1)) != number:
			continue

		if str(event.get("previous_owner", "")) != previous_owner:
			continue

		if str(event.get("new_owner", "")) != new_owner:
			continue

		return true

	return false


# ==================================================
# MUTUAL ALLIANCE SYSTEM
# ==================================================

func request_alliance(
	exam_id: String,
	requester_id: String,
	target_id: String
) -> Dictionary:

	if requester_id == target_id:
		return _failure("CANNOT_ALLY_WITH_SELF")

	if not _valid_participants(exam_id, requester_id, target_id):
		return _failure("PARTICIPANT_NOT_ACTIVE")

	var session: Dictionary = exam_missions[exam_id]
	var requests: Array = session["alliance_requests"]

	if _has_active_alliance(exam_id, requester_id, target_id):
		return _failure("ALLIANCE_ALREADY_ACTIVE")

	for request in requests:
		if (
			str(request["requester"]) == requester_id
			and str(request["target"]) == target_id
			and str(request["status"]) == "pending"
		):
			return _failure("REQUEST_ALREADY_PENDING")

	requests.append({
		"requester": requester_id,
		"target": target_id,
		"status": "pending",
		"created_at": Time.get_datetime_string_from_system()
	})

	session["alliance_requests"] = requests
	exam_missions[exam_id] = session

	_add_action_log(exam_id, {
		"type": "alliance_requested",
		"actor": requester_id,
		"target": target_id
	})

	save_data()
	alliance_requested.emit(exam_id, requester_id, target_id)

	return {
		"success": true,
		"status": "pending_acceptance"
	}


func accept_alliance(
	exam_id: String,
	target_id: String,
	requester_id: String
) -> Dictionary:

	if not _valid_participants(exam_id, target_id, requester_id):
		return _failure("PARTICIPANT_NOT_ACTIVE")

	var session: Dictionary = exam_missions[exam_id]
	var requests: Array = session["alliance_requests"]
	var request_index := -1

	for i in range(requests.size()):
		var request: Dictionary = requests[i]

		if (
			str(request["requester"]) == requester_id
			and str(request["target"]) == target_id
			and str(request["status"]) == "pending"
		):
			request_index = i
			break

	if request_index == -1:
		return _failure("PENDING_REQUEST_NOT_FOUND")

	var request: Dictionary = requests[request_index]
	request["status"] = "accepted"
	request["accepted_at"] = Time.get_datetime_string_from_system()
	requests[request_index] = request

	var alliances: Array = session["alliances"]

	alliances.append({
		"player_a": requester_id,
		"player_b": target_id,
		"created_at": Time.get_datetime_string_from_system(),
		"active": true
	})

	session["alliance_requests"] = requests
	session["alliances"] = alliances
	exam_missions[exam_id] = session

	_add_action_log(exam_id, {
		"type": "alliance_accepted",
		"actor": target_id,
		"target": requester_id
	})

	_increase_progress(exam_id, requester_id, 1)
	_increase_progress(exam_id, target_id, 1)

	save_data()
	alliance_recorded.emit(exam_id, requester_id, target_id)

	return {"success": true, "status": "alliance_active"}


# Compatibility method:
# This now creates a request, not an instant alliance.

func record_alliance(
	exam_id: String,
	player_a: String,
	player_b: String
) -> Dictionary:

	return request_alliance(exam_id, player_a, player_b)


func _has_active_alliance(
	exam_id: String,
	player_a: String,
	player_b: String
) -> bool:

	var alliances: Array = exam_missions[exam_id]["alliances"]

	for alliance in alliances:
		var same_pair := (
			(
				str(alliance["player_a"]) == player_a
				and str(alliance["player_b"]) == player_b
			)
			or
			(
				str(alliance["player_a"]) == player_b
				and str(alliance["player_b"]) == player_a
			)
		)

		if same_pair and bool(alliance["active"]):
			return true

	return false


func get_pending_alliance_requests(
	exam_id: String,
	player_id: String
) -> Array:

	if not exam_missions.has(exam_id):
		return []

	var requests: Array = exam_missions[exam_id]["alliance_requests"]
	var result: Array = []

	for request in requests:
		if (
			str(request["target"]) == player_id
			and str(request["status"]) == "pending"
		):
			result.append(request.duplicate(true))

	return result


func get_alliances(exam_id: String) -> Array:

	if not exam_missions.has(exam_id):
		return []

	return exam_missions[exam_id]["alliances"].duplicate(true)


# ==================================================
# DECEPTION SYSTEM
# ==================================================

func record_deception(
	exam_id: String,
	player_id: String,
	target_id: String,
	description: String
) -> Dictionary:

	if not _valid_participants(exam_id, player_id, target_id):
		return _failure("PARTICIPANT_NOT_ACTIVE")

	if description.strip_edges().is_empty():
		return _failure("DESCRIPTION_REQUIRED")

	var session: Dictionary = exam_missions[exam_id]
	var events: Array = session["deception_events"]

	events.append({
		"player_id": player_id,
		"target_id": target_id,
		"description": description,
		"timestamp": Time.get_datetime_string_from_system(),
		"verified": false,
		"approved": false
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

	if bool(event["verified"]):
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
# PROTECT ORIGINAL NUMBER
# ==================================================

func verify_number_protection(
	exam_id: String,
	player_id: String,
	stage_finished: bool,
	still_holds_original_number: bool
) -> Dictionary:

	if not _valid_single_participant(exam_id, player_id):
		return _failure("PARTICIPANT_NOT_ACTIVE")

	var session: Dictionary = exam_missions[exam_id]
	var cohort_id: String = str(session["cohort_id"])

	var mission_data := get_player_secret_mission(exam_id, player_id)

	if mission_data.is_empty():
		return _failure("PLAYER_NOT_FOUND")

	var mission: Dictionary = mission_data["mission"]

	if str(mission["type"]) != "protect_number":
		return _failure("WRONG_MISSION_TYPE")

	if not stage_finished:
		return _failure("STAGE_NOT_FINISHED")

	var original_number := XSXCohorts.get_original_number(
		cohort_id,
		player_id
	)

	var actual_owner := XSXCohorts.get_number_owner(
		cohort_id,
		original_number
	)

	if not still_holds_original_number or actual_owner != player_id:
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

	if not exam_missions.has(exam_id):
		return

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
# VALIDATION HELPERS
# ==================================================

func _valid_participants(
	exam_id: String,
	player_a: String,
	player_b: String
) -> bool:

	if not exam_missions.has(exam_id):
		return false

	var session: Dictionary = exam_missions[exam_id]
	var participants: Dictionary = session["participants"]
	var cohort_id: String = str(session["cohort_id"])

	if not participants.has(player_a) or not participants.has(player_b):
		return false

	return (
		XSXCohorts.is_active_contestant(cohort_id, player_a)
		and XSXCohorts.is_active_contestant(cohort_id, player_b)
	)


func _valid_single_participant(
	exam_id: String,
	player_id: String
) -> bool:

	if not exam_missions.has(exam_id):
		return false

	var session: Dictionary = exam_missions[exam_id]
	var participants: Dictionary = session["participants"]

	if not participants.has(player_id):
		return false

	return XSXCohorts.is_active_contestant(
		str(session["cohort_id"]),
		player_id
	)


func _add_action_log(
	exam_id: String,
	action: Dictionary
) -> void:

	if not exam_missions.has(exam_id):
		return

	var session: Dictionary = exam_missions[exam_id]
	var log: Array = session["action_log"]

	action["timestamp"] = Time.get_datetime_string_from_system()
	log.append(action)

	if log.size() > 1000:
		log.pop_front()

	session["action_log"] = log
	exam_missions[exam_id] = session

	save_data()


# ==================================================
# EXAM CONTROL
# ==================================================

func finish_secret_missions(exam_id: String) -> Dictionary:

	if not exam_missions.has(exam_id):
		return _failure("EXAM_NOT_FOUND")

	var session: Dictionary = exam_missions[exam_id]

	if bool(session["finished"]):
		return _failure("MISSIONS_ALREADY_FINISHED")

	session["finished"] = true
	session["finished_at"] = Time.get_datetime_string_from_system()

	exam_missions[exam_id] = session
	save_data()

	return {
		"success": true,
		"exam_id": exam_id
	}


# ==================================================
# SAVE / LOAD
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

	var saved = parsed.get("exam_missions", {})

	if typeof(saved) != TYPE_DICTIONARY:
		return false

	# Older save files may not contain the new alliance request field.
	exam_missions = saved.duplicate(true)

	for exam_id in exam_missions.keys():
		var session: Dictionary = exam_missions[exam_id]

		if not session.has("alliance_requests"):
			session["alliance_requests"] = []

		exam_missions[exam_id] = session

	return true


func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason
	}
