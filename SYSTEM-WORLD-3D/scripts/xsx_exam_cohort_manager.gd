
extends Node

class_name XSXExamCohortManager

# SYSTEM WORLD - XSX Contestant Cohort and Number System
# Godot 4.3
# Local prototype. Multiplayer authority must move to a server before launch.

signal cohort_created(batch_id: String)
signal contestant_registered(batch_id: String, contestant_id: String, number: int)
signal number_stolen(batch_id: String, thief_id: String, target_id: String, number: int)
signal contestant_eliminated(batch_id: String, contestant_id: String)
signal cohort_finished(batch_id: String)

const SAVE_PATH := "user://xsx_exam_cohorts.json"
const SAVE_VERSION := 1
const MIN_NUMBER := 1000
const MAX_NUMBER := 9999
const MAX_CONTESTANTS := 64

var cohorts: Dictionary = {}
var active_batch_id := ""


func _ready() -> void:
	randomize()
	load_data()


# ==================================================
# COHORT CREATION
# ==================================================

func create_cohort(batch_name: String = "XSX Examination") -> Dictionary:
	if not active_batch_id.is_empty():
		var active := cohorts.get(active_batch_id, {})
		if not bool(active.get("finished", true)):
			return _failure("ACTIVE_COHORT_ALREADY_EXISTS")

	var batch_id := _generate_batch_id()

	var cohort := {
		"batch_id": batch_id,
		"batch_name": batch_name,
		"created_at": Time.get_datetime_string_from_system(),
		"finished_at": "",
		"finished": false,
		"participants": {},
		"number_owners": {},
		"theft_log": [],
		"eliminated": []
	}

	cohorts[batch_id] = cohort
	active_batch_id = batch_id

	save_data()
	cohort_created.emit(batch_id)

	return {
		"success": true,
		"batch_id": batch_id,
		"batch_name": batch_name
	}


func _generate_batch_id() -> String:
	return "XSX-BATCH-%08d" % randi_range(10000000, 99999999)


func get_active_batch_id() -> String:
	return active_batch_id


func get_cohort(batch_id: String = "") -> Dictionary:
	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return {}

	return cohorts[requested_id].duplicate(true)


# ==================================================
# CONTESTANT REGISTRATION
# ==================================================

func register_contestant(
	contestant_id: String,
	display_name: String,
	is_ai: bool = false,
	batch_id: String = ""
) -> Dictionary:

	if contestant_id.strip_edges().is_empty():
		return _failure("INVALID_CONTESTANT_ID")

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if requested_id.is_empty() or not cohorts.has(requested_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[requested_id]

	if bool(cohort.get("finished", false)):
		return _failure("COHORT_FINISHED")

	var participants: Dictionary = cohort.get("participants", {})

	if participants.has(contestant_id):
		return {
			"success": true,
			"already_registered": true,
			"contestant": participants[contestant_id].duplicate(true)
		}

	if participants.size() >= MAX_CONTESTANTS:
		return _failure("COHORT_IS_FULL")

	var number := _generate_unique_number(cohort)

	if number <= 0:
		return _failure("NO_NUMBERS_AVAILABLE")

	var contestant := {
		"contestant_id": contestant_id,
		"display_name": display_name,
		"is_ai": is_ai,
		"original_number": number,
		"held_numbers": [number],
		"active": true,
		"registered_at": Time.get_datetime_string_from_system(),
		"successful_thefts": 0,
		"failed_thefts": 0
	}

	participants[contestant_id] = contestant

	var owners: Dictionary = cohort.get("number_owners", {})
	owners[str(number)] = contestant_id

	cohort["participants"] = participants
	cohort["number_owners"] = owners
	cohorts[requested_id] = cohort

	save_data()

	contestant_registered.emit(requested_id, contestant_id, number)

	return {
		"success": true,
		"batch_id": requested_id,
		"contestant": contestant.duplicate(true),
		"contestant_number": number
	}


func _generate_unique_number(cohort: Dictionary) -> int:
	var owners: Dictionary = cohort.get("number_owners", {})

	if owners.size() >= MAX_NUMBER - MIN_NUMBER + 1:
		return -1

	var candidate := randi_range(MIN_NUMBER, MAX_NUMBER)
	var attempts := 0

	while owners.has(str(candidate)) and attempts < 10000:
		candidate = randi_range(MIN_NUMBER, MAX_NUMBER)
		attempts += 1

	if owners.has(str(candidate)):
		return -1

	return candidate


func register_ai_contestants(
	count: int,
	batch_id: String = ""
) -> Dictionary:

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return _failure("COHORT_NOT_FOUND")

	var names := [
		"آدم",
		"رين",
		"كاي",
		"ليان",
		"آريس",
		"سورا",
		"نادر",
		"إيلا",
		"ريان",
		"ميرال",
		"دارك",
		"هارو"
	]

	var registered: Array = []

	for i in range(maxi(0, count)):
		var ai_id := "XSX-AI-%03d-%04d" % [
			i + 1,
			randi_range(1000, 9999)
		]

		var ai_name: String = names[i % names.size()]

		var result := register_contestant(
			ai_id,
			ai_name,
			true,
			requested_id
		)

		if bool(result.get("success", false)):
			registered.append(result.get("contestant", {}))

	return {
		"success": true,
		"registered_count": registered.size(),
		"contestants": registered
	}


# ==================================================
# CONTESTANT INFORMATION
# ==================================================

func get_contestant(
	contestant_id: String,
	batch_id: String = ""
) -> Dictionary:

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return {}

	var cohort: Dictionary = cohorts[requested_id]
	var participants: Dictionary = cohort.get("participants", {})

	if not participants.has(contestant_id):
		return {}

	var contestant: Dictionary = participants[contestant_id]

	return contestant.duplicate(true)


func get_contestant_number(
	contestant_id: String,
	batch_id: String = ""
) -> int:

	var contestant := get_contestant(contestant_id, batch_id)

	return int(contestant.get("original_number", 0))


func get_held_numbers(
	contestant_id: String,
	batch_id: String = ""
) -> Array:

	var contestant := get_contestant(contestant_id, batch_id)

	var numbers: Array = contestant.get("held_numbers", [])

	return numbers.duplicate()


func get_number_owner(
	number: int,
	batch_id: String = ""
) -> String:

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return ""

	var cohort: Dictionary = cohorts[requested_id]
	var owners: Dictionary = cohort.get("number_owners", {})

	return str(owners.get(str(number), ""))


func get_cohort_roster(batch_id: String = "") -> Array:
	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return []

	var cohort: Dictionary = cohorts[requested_id]
	var participants: Dictionary = cohort.get("participants", {})

	var roster: Array = []

	for contestant_id in participants.keys():
		roster.append(participants[contestant_id].duplicate(true))

	return roster


# ==================================================
# NUMBER THEFT
# ==================================================

func attempt_number_theft(
	thief_id: String,
	target_id: String,
	number_to_steal: int = 0,
	batch_id: String = ""
) -> Dictionary:

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[requested_id]

	if bool(cohort.get("finished", false)):
		return _failure("COHORT_FINISHED")

	var participants: Dictionary = cohort.get("participants", {})

	if not participants.has(thief_id):
		return _failure("THIEF_NOT_REGISTERED")

	if not participants.has(target_id):
		return _failure("TARGET_NOT_REGISTERED")

	if thief_id == target_id:
		return _failure("CANNOT_STEAL_FROM_SELF")

	var thief: Dictionary = participants[thief_id]
	var target: Dictionary = participants[target_id]

	if not bool(thief.get("active", false)):
		return _failure("THIEF_NOT_ACTIVE")

	if not bool(target.get("active", false)):
		return _failure("TARGET_NOT_ACTIVE")

	var target_numbers: Array = target.get("held_numbers", [])

	if target_numbers.is_empty():
		return _failure("TARGET_HAS_NO_NUMBERS")

	var selected_number := number_to_steal

	if selected_number == 0:
		selected_number = int(target_numbers[0])

	if not target_numbers.has(selected_number):
		return _failure("TARGET_DOES_NOT_HOLD_THIS_NUMBER")

	# Transfer the number badge to the successful thief.
	target_numbers.erase(selected_number)

	var thief_numbers: Array = thief.get("held_numbers", [])
	thief_numbers.append(selected_number)

	target["held_numbers"] = target_numbers
	thief["held_numbers"] = thief_numbers

	thief["successful_thefts"] = int(
		thief.get("successful_thefts", 0)
	) + 1

	var owners: Dictionary = cohort.get("number_owners", {})
	owners[str(selected_number)] = thief_id

	var theft_log: Array = cohort.get("theft_log", [])

	var event := {
		"number": selected_number,
		"thief_id": thief_id,
		"previous_owner_id": target_id,
		"new_owner_id": thief_id,
		"timestamp": Time.get_datetime_string_from_system()
	}

	theft_log.append(event)

	participants[thief_id] = thief
	participants[target_id] = target

	cohort["participants"] = participants
	cohort["number_owners"] = owners
	cohort["theft_log"] = theft_log

	cohorts[requested_id] = cohort

	save_data()

	number_stolen.emit(
		requested_id,
		thief_id,
		target_id,
		selected_number
	)

	return {
		"success": true,
		"stolen_number": selected_number,
		"thief_id": thief_id,
		"previous_owner_id": target_id,
		"new_owner_id": thief_id,
		"thief_total_numbers": thief_numbers.size(),
		"target_total_numbers": target_numbers.size()
	}


func record_failed_theft(
	thief_id: String,
	batch_id: String = ""
) -> Dictionary:

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[requested_id]
	var participants: Dictionary = cohort.get("participants", {})

	if not participants.has(thief_id):
		return _failure("THIEF_NOT_REGISTERED")

	var contestant: Dictionary = participants[thief_id]

	contestant["failed_thefts"] = int(
		contestant.get("failed_thefts", 0)
	) + 1

	participants[thief_id] = contestant
	cohort["participants"] = participants
	cohorts[requested_id] = cohort

	save_data()

	return {
		"success": true,
		"failed_thefts": int(contestant["failed_thefts"])
	}


# ==================================================
# AI OPPONENT ACTION
# ==================================================

func simulate_ai_theft(
	ai_id: String,
	batch_id: String = ""
) -> Dictionary:

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	var ai := get_contestant(ai_id, requested_id)

	if ai.is_empty():
		return _failure("AI_NOT_FOUND")

	if not bool(ai.get("is_ai", false)):
		return _failure("CONTESTANT_IS_NOT_AI")

	var roster := get_cohort_roster(requested_id)
	var possible_targets: Array = []

	for contestant in roster:
		var target_id := str(contestant.get("contestant_id", ""))

		if target_id == ai_id:
			continue

		if not bool(contestant.get("active", false)):
			continue

		var held: Array = contestant.get("held_numbers", [])

		if not held.is_empty():
			possible_targets.append(target_id)

	if possible_targets.is_empty():
		return _failure("NO_VALID_TARGETS")

	var target_id: String = possible_targets[
		randi_range(0, possible_targets.size() - 1)
	]

	return attempt_number_theft(
		ai_id,
		target_id,
		0,
		requested_id
	)


# ==================================================
# ELIMINATION AND RESULTS
# ==================================================

func eliminate_contestant(
	contestant_id: String,
	batch_id: String = ""
) -> Dictionary:

	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[requested_id]
	var participants: Dictionary = cohort.get("participants", {})

	if not participants.has(contestant_id):
		return _failure("CONTESTANT_NOT_FOUND")

	var contestant: Dictionary = participants[contestant_id]

	contestant["active"] = false
	participants[contestant_id] = contestant

	cohort["participants"] = participants

	var eliminated: Array = cohort.get("eliminated", [])

	if not eliminated.has(contestant_id):
		eliminated.append(contestant_id)

	cohort["eliminated"] = eliminated
	cohorts[requested_id] = cohort

	save_data()

	contestant_eliminated.emit(requested_id, contestant_id)

	return {
		"success": true,
		"contestant_id": contestant_id,
		"held_numbers": contestant.get("held_numbers", [])
	}


func get_number_rankings(batch_id: String = "") -> Array:
	var roster := get_cohort_roster(batch_id)

	roster.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_count: int = a.get("held_numbers", []).size()
			var b_count: int = b.get("held_numbers", []).size()
			return a_count > b_count
	)

	return roster


func finish_cohort(batch_id: String = "") -> Dictionary:
	var requested_id := batch_id

	if requested_id.is_empty():
		requested_id = active_batch_id

	if not cohorts.has(requested_id):
		return _failure("COHORT_NOT_FOUND")

	var cohort: Dictionary = cohorts[requested_id]

	cohort["finished"] = true
	cohort["finished_at"] = Time.get_datetime_string_from_system()

	cohorts[requested_id] = cohort

	if active_batch_id == requested_id:
		active_batch_id = ""

	save_data()
	cohort_finished.emit(requested_id)

	return {
		"success": true,
		"batch_id": requested_id,
		"rankings": get_number_rankings(requested_id)
	}


# ==================================================
# PERSISTENCE
# ==================================================

func save_data() -> bool:
	var payload := {
		"save_version": SAVE_VERSION,
		"active_batch_id": active_batch_id,
		"cohorts": cohorts,
		"saved_at": Time.get_datetime_string_from_system()
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("XSX Cohort: Could not save data.")
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	return true


func load_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		cohorts = {}
		active_batch_id = ""
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return false

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	if int(parsed.get("save_version", -1)) != SAVE_VERSION:
		push_warning("XSX Cohort: Save version mismatch.")
		return false

	var saved_cohorts = parsed.get("cohorts", {})

	if typeof(saved_cohorts) != TYPE_DICTIONARY:
		return false

	cohorts = saved_cohorts.duplicate(true)
	active_batch_id = str(parsed.get("active_batch_id", ""))

	return true


# ==================================================
# UTILITIES
# ==================================================

func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason
	}
