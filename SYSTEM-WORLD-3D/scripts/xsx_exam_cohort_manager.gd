
extends Node
class_name XSXExamCohortManager

# SYSTEM WORLD - XSX Human Exam Cohorts
# Godot 4.3
# Local prototype. Multiplayer authority must move to a trusted server.
# AI characters are not allowed to become exam contestants.

signal cohort_created(cohort_id: String)
signal contestant_joined(cohort_id: String, player_id: String, number: int)
signal contestant_left(cohort_id: String, player_id: String)
signal number_transferred(
	cohort_id: String,
	number: int,
	previous_owner: String,
	new_owner: String
)
signal cohort_status_changed(cohort_id: String, status: String)

const SAVE_PATH := "user://xsx_exam_cohorts.json"
const SAVE_VERSION := 1
const FIRST_CONTESTANT_NUMBER := 1001
const MAX_EVENT_LOG := 1000

const STATUS_WAITING := "waiting"
const STATUS_ACTIVE := "active"
const STATUS_FINISHED := "finished"
const STATUS_CANCELLED := "cancelled"

var cohorts: Dictionary = {}


func _ready() -> void:
	randomize()
	load_data()


# ==================================================
# CREATE COHORT
# ==================================================

# human_player_ids must come from authenticated real accounts.
# This local prototype cannot independently verify account identity.

func create_cohort(
	cohort_id: String,
	human_player_ids: Array
) -> Dictionary:

	var id := cohort_id.strip_edges()

	if id.is_empty():
		return _failure("INVALID_COHORT_ID")

	if cohorts.has(id):
		return _failure("COHORT_ALREADY_EXISTS")

	var unique_players: Array = []

	for value in human_player_ids:
		var player_id := str(value).strip_edges()

		if player_id.is_empty():
			continue

		if not unique_players.has(player_id):
			unique_players.append(player_id)

	if unique_players.is_empty():
		return _failure("NO_HUMAN_CONTESTANTS")

	cohorts[id] = {
		"cohort_id": id,
		"status": STATUS_WAITING,
		"created_at": Time.get_datetime_string_from_system(),
		"started_at": "",
		"finished_at": "",
		"next_number": FIRST_CONTESTANT_NUMBER,
		"contestants": {},
		"number_owners": {},
		"event_log": []
	}

	for player_id in unique_players:
		var result := _add_contestant(id, player_id)

		if not bool(result.get("success", false)):
			cohorts.erase(id)
			return result

	save_data()
	cohort_created.emit(id)

	return {
		"success": true,
		"cohort_id": id,
		"contestant_count": unique_players.size(),
		"status": STATUS_WAITING
	}


# ==================================================
# JOIN COHORT
# ==================================================

func join_cohort(
	cohort_id: String,
	player_id: String
) -> Dictionary:

	var id := player_id.strip_edges()

	if id.is_empty():
		return _failure("INVALID_PLAYER_ID")

	if not cohorts.has(cohort_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[cohort_id]

	if str(cohort["status"]) != STATUS_WAITING:
		return _failure("COHORT_NOT_ACCEPTING_CONTESTANTS")

	if cohort["contestants"].has(id):
		return _failure("ALREADY_REGISTERED_IN_COHORT")

	var result := _add_contestant(cohort_id, id)

	if bool(result.get("success", false)):
		save_data()

	return result


func _add_contestant(
	cohort_id: String,
	player_id: String
) -> Dictionary:

	if not cohorts.has(cohort_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[cohort_id]
	var number := _generate_unique_number(cohort)

	var contestant := {
		"player_id": player_id,

		# Permanent original number.
		"contestant_number": number,

		# Numbers currently held by this contestant.
		"holdings": [number],

		"status": "registered",
		"joined_at": Time.get_datetime_string_from_system(),
		"left_at": ""
	}

	var contestants: Dictionary = cohort["contestants"]
	var owners: Dictionary = cohort["number_owners"]

	contestants[player_id] = contestant
	owners[str(number)] = player_id

	cohort["contestants"] = contestants
	cohort["number_owners"] = owners
	cohorts[cohort_id] = cohort

	_log_event(cohort_id, {
		"type": "contestant_joined",
		"player_id": player_id,
		"number": number
	})

	contestant_joined.emit(cohort_id, player_id, number)

	return {
		"success": true,
		"player_id": player_id,
		"contestant_number": number,
		"holdings": [number]
	}


# ==================================================
# UNIQUE NUMBER GENERATION
# ==================================================

func _generate_unique_number(cohort: Dictionary) -> int:

	var number := int(
		cohort.get("next_number", FIRST_CONTESTANT_NUMBER)
	)

	var owners: Dictionary = cohort.get("number_owners", {})

	while owners.has(str(number)):
		number += 1

	cohort["next_number"] = number + 1

	return number


# ==================================================
# START COHORT
# ==================================================

func start_cohort(cohort_id: String) -> Dictionary:

	if not cohorts.has(cohort_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[cohort_id]

	if str(cohort["status"]) != STATUS_WAITING:
		return _failure("COHORT_CANNOT_START")

	var contestants: Dictionary = cohort["contestants"]
	var eligible_count := 0

	for player_id in contestants.keys():
		var contestant: Dictionary = contestants[player_id]

		if str(contestant["status"]) == "registered":
			eligible_count += 1

	if eligible_count < 2:
		return _failure("NEED_TWO_ACTIVE_HUMAN_CONTESTANTS")

	for player_id in contestants.keys():
		var contestant: Dictionary = contestants[player_id]

		if str(contestant["status"]) == "registered":
			contestant["status"] = "active"
			contestants[player_id] = contestant

	cohort["contestants"] = contestants
	cohort["status"] = STATUS_ACTIVE
	cohort["started_at"] = Time.get_datetime_string_from_system()

	cohorts[cohort_id] = cohort

	_log_event(cohort_id, {
		"type": "cohort_started"
	})

	save_data()
	cohort_status_changed.emit(cohort_id, STATUS_ACTIVE)

	return {
		"success": true,
		"cohort_id": cohort_id,
		"status": STATUS_ACTIVE,
		"contestant_count": eligible_count
	}


# ==================================================
# FINISH / CANCEL COHORT
# ==================================================

func finish_cohort(cohort_id: String) -> Dictionary:

	if not cohorts.has(cohort_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[cohort_id]

	if str(cohort["status"]) != STATUS_ACTIVE:
		return _failure("COHORT_NOT_ACTIVE")

	cohort["status"] = STATUS_FINISHED
	cohort["finished_at"] = Time.get_datetime_string_from_system()

	cohorts[cohort_id] = cohort

	_log_event(cohort_id, {
		"type": "cohort_finished"
	})

	save_data()
	cohort_status_changed.emit(cohort_id, STATUS_FINISHED)

	return {
		"success": true,
		"status": STATUS_FINISHED
	}


func cancel_cohort(cohort_id: String) -> Dictionary:

	if not cohorts.has(cohort_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[cohort_id]

	if str(cohort["status"]) == STATUS_FINISHED:
		return _failure("COHORT_ALREADY_FINISHED")

	cohort["status"] = STATUS_CANCELLED
	cohorts[cohort_id] = cohort

	_log_event(cohort_id, {
		"type": "cohort_cancelled"
	})

	save_data()
	cohort_status_changed.emit(cohort_id, STATUS_CANCELLED)

	return {
		"success": true,
		"status": STATUS_CANCELLED
	}


# ==================================================
# NUMBER TRANSFER
# ==================================================

# from_player = contestant trying to take the number.
# to_player = current owner of the number.
# Call this only after gameplay validates a successful theft.

func transfer_number(
	cohort_id: String,
	from_player: String,
	to_player: String,
	number: int
) -> Dictionary:

	if from_player == to_player:
		return _failure("CANNOT_STEAL_FROM_SELF")

	if number <= 0:
		return _failure("INVALID_NUMBER")

	if not cohorts.has(cohort_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[cohort_id]

	if str(cohort["status"]) != STATUS_ACTIVE:
		return _failure("COHORT_NOT_ACTIVE")

	var contestants: Dictionary = cohort["contestants"]

	if not contestants.has(from_player):
		return _failure("THIEF_NOT_REGISTERED")

	if not contestants.has(to_player):
		return _failure("OWNER_NOT_REGISTERED")

	var thief: Dictionary = contestants[from_player]
	var owner: Dictionary = contestants[to_player]

	if str(thief["status"]) != "active":
		return _failure("THIEF_NOT_ACTIVE")

	if str(owner["status"]) != "active":
		return _failure("OWNER_NOT_ACTIVE")

	var owners: Dictionary = cohort["number_owners"]

	if str(owners.get(str(number), "")) != to_player:
		return _failure("NUMBER_OWNER_MISMATCH")

	var thief_holdings: Array = thief["holdings"]
	var owner_holdings: Array = owner["holdings"]

	if not owner_holdings.has(number):
		return _failure("NUMBER_NOT_HELD_BY_OWNER")

	if thief_holdings.has(number):
		return _failure("NUMBER_ALREADY_HELD_BY_THIEF")

	owner_holdings.erase(number)
	thief_holdings.append(number)

	owner["holdings"] = owner_holdings
	thief["holdings"] = thief_holdings

	contestants[to_player] = owner
	contestants[from_player] = thief

	owners[str(number)] = from_player

	cohort["contestants"] = contestants
	cohort["number_owners"] = owners

	cohorts[cohort_id] = cohort

	_log_event(cohort_id, {
		"type": "number_transferred",
		"number": number,
		"previous_owner": to_player,
		"new_owner": from_player
	})

	save_data()

	number_transferred.emit(
		cohort_id,
		number,
		to_player,
		from_player
	)

	return {
		"success": true,
		"number": number,
		"previous_owner": to_player,
		"new_owner": from_player
	}


# ==================================================
# LEAVE COHORT
# ==================================================

func leave_cohort(
	cohort_id: String,
	player_id: String
) -> Dictionary:

	if not cohorts.has(cohort_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[cohort_id]

	if str(cohort["status"]) == STATUS_FINISHED:
		return _failure("COHORT_ALREADY_FINISHED")

	var contestants: Dictionary = cohort["contestants"]

	if not contestants.has(player_id):
		return _failure("CONTESTANT_NOT_FOUND")

	var contestant: Dictionary = contestants[player_id]

	if str(contestant["status"]) == "left":
		return _failure("ALREADY_LEFT")

	contestant["status"] = "left"
	contestant["left_at"] = Time.get_datetime_string_from_system()

	# Preserve original number and holdings as historical records.
	contestants[player_id] = contestant
	cohort["contestants"] = contestants
	cohorts[cohort_id] = cohort

	_log_event(cohort_id, {
		"type": "contestant_left",
		"player_id": player_id
	})

	save_data()
	contestant_left.emit(cohort_id, player_id)

	return {"success": true}


# ==================================================
# CONTESTANT INFORMATION
# ==================================================

func get_contestant(
	cohort_id: String,
	player_id: String
) -> Dictionary:

	if not cohorts.has(cohort_id):
		return {}

	var contestants: Dictionary = cohorts[cohort_id]["contestants"]

	if not contestants.has(player_id):
		return {}

	return contestants[player_id].duplicate(true)


func get_original_number(
	cohort_id: String,
	player_id: String
) -> int:

	var contestant := get_contestant(cohort_id, player_id)

	return int(contestant.get("contestant_number", 0))


func get_player_holdings(
	cohort_id: String,
	player_id: String
) -> Array:

	var contestant := get_contestant(cohort_id, player_id)

	return contestant.get("holdings", []).duplicate(true)


func get_number_owner(
	cohort_id: String,
	number: int
) -> String:

	if not cohorts.has(cohort_id):
		return ""

	var owners: Dictionary = cohorts[cohort_id]["number_owners"]

	return str(owners.get(str(number), ""))


func is_active_contestant(
	cohort_id: String,
	player_id: String
) -> bool:

	var contestant := get_contestant(cohort_id, player_id)

	return str(contestant.get("status", "")) == "active"


# ==================================================
# COHORT INFORMATION
# ==================================================

func get_cohort_status(cohort_id: String) -> String:

	if not cohorts.has(cohort_id):
		return ""

	return str(cohorts[cohort_id].get("status", ""))


func get_contestant_count(cohort_id: String) -> int:

	if not cohorts.has(cohort_id):
		return 0

	var contestants: Dictionary = cohorts[cohort_id]["contestants"]
	var count := 0

	for player_id in contestants.keys():
		var contestant: Dictionary = contestants[player_id]

		if str(contestant["status"]) != "left":
			count += 1

	return count


func get_cohort_summary(cohort_id: String) -> Dictionary:

	if not cohorts.has(cohort_id):
		return {}

	var cohort: Dictionary = cohorts[cohort_id]
	var contestants: Dictionary = cohort["contestants"]
	var public_list: Array = []

	for player_id in contestants.keys():
		var contestant: Dictionary = contestants[player_id]

		public_list.append({
			"player_id": player_id,
			"contestant_number": contestant["contestant_number"],
			"holdings_count": contestant["holdings"].size(),
			"status": contestant["status"]
		})

	return {
		"cohort_id": cohort_id,
		"status": cohort["status"],
		"contestant_count": get_contestant_count(cohort_id),
		"contestants": public_list,
		"created_at": cohort["created_at"],
		"started_at": cohort["started_at"],
		"finished_at": cohort["finished_at"]
	}


func get_event_log(cohort_id: String) -> Array:

	if not cohorts.has(cohort_id):
		return []

	return cohorts[cohort_id]["event_log"].duplicate(true)


# ==================================================
# EVENT LOG
# ==================================================

func _log_event(
	cohort_id: String,
	event: Dictionary
) -> void:

	if not cohorts.has(cohort_id):
		return

	var cohort: Dictionary = cohorts[cohort_id]
	var log: Array = cohort["event_log"]

	event["timestamp"] = Time.get_datetime_string_from_system()
	log.append(event)

	if log.size() > MAX_EVENT_LOG:
		log.pop_front()

	cohort["event_log"] = log
	cohorts[cohort_id] = cohort


# ==================================================
# SAVE / LOAD
# ==================================================

func save_data() -> bool:

	var payload := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"cohorts": cohorts
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("XSX Cohort Manager: Save failed.")
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	return true


func load_data() -> bool:

	if not FileAccess.file_exists(SAVE_PATH):
		cohorts = {}
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

	var saved = parsed.get("cohorts", {})

	if typeof(saved) != TYPE_DICTIONARY:
		return false

	cohorts = saved.duplicate(true)
	return true


# ==================================================
# HELPERS
# ==================================================

func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason
	}
