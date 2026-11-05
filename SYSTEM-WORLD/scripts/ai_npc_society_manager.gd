
extends Node
class_name SystemAINPCSocietyManager

## Independent civilian AI society simulation.
## NPCs never execute player missions, solve puzzles,
## participate in mission combat, or create organizations.

signal npc_created(npc_id: String)
signal npc_married(first_id: String, second_id: String)
signal npc_child_born(parent_a: String, parent_b: String, child_id: String)
signal npc_died(npc_id: String, historical_record: Dictionary)
signal information_shared(npc_id: String, information: Dictionary)

const SAVE_PATH := "user://system_world_ai_society.json"
const HOURS_PER_YEAR := 8760.0
const MAX_MEMORY := 40
const MAX_PUBLIC_INFO := 200

const ALLOWED_ACTIVITIES := [
	"daily_life", "work", "trade", "travel", "explore",
	"gather_information", "socialize", "family", "rest"
]

const BLOCKED_INFO := [
	"mission_solution", "puzzle_solution", "hidden_objective",
	"developer_secret", "unrevealed_mission_state"
]

var simulation_hours: float = 0.0
var npcs: Dictionary = {}
var public_information: Array[Dictionary] = []
var next_npc_number: int = 1
var autosave_hours: float = 0.0


func _ready() -> void:
	load_society()


func _process(delta: float) -> void:
	# One simulated minute per real second.
	advance_simulation(delta / 60.0)


func advance_simulation(hours: float) -> void:
	if hours <= 0.0:
		return

	simulation_hours += hours
	autosave_hours += hours

	for npc_id in npcs.keys():
		var npc: Dictionary = npcs[npc_id]

		if not npc.get("alive", false):
			continue

		_update_age(str(npc_id), hours)
		_update_needs(str(npc_id), hours)

	if autosave_hours >= 6.0:
		autosave_hours = 0.0
		save_society()


func create_npc(
	display_name: String,
	world_id: int,
	age_years: float,
	personality: String = "balanced",
	occupation: String = "unemployed",
	parent_a: String = "",
	parent_b: String = ""
) -> String:

	if display_name.strip_edges().is_empty() or age_years < 0.0:
		return ""

	var npc_id := "npc_%06d" % next_npc_number
	next_npc_number += 1

	var parents: Array[String] = []

	if not parent_a.is_empty():
		parents.append(parent_a)

	if not parent_b.is_empty():
		parents.append(parent_b)

	npcs[npc_id] = {
		"id": npc_id,
		"name": display_name.strip_edges(),
		"world_id": world_id,
		"age_years": age_years,
		"life_stage": _life_stage(age_years),
		"personality": personality,
		"occupation": occupation,
		"alive": true,
		"spouse_id": "",
		"parent_ids": parents,
		"children_ids": [],
		"friend_ids": [],
		"memory": [],
		"life_history": [],
		"home_location": "",
		"current_location": "",
		"activity": "daily_life",
		"needs": {
			"energy": 100.0,
			"social": 70.0,
			"wellbeing": 80.0
		},
		"created_at_hours": simulation_hours
	}

	for parent_id in parents:
		if npcs.has(parent_id):
			var parent: Dictionary = npcs[parent_id]
			var children: Array = parent.get("children_ids", [])
			children.append(npc_id)
			parent["children_ids"] = children
			npcs[parent_id] = parent

	_add_history(
		npc_id,
		"registered_or_born",
		{"age_years": age_years}
	)

	npc_created.emit(npc_id)
	return npc_id


func get_npc(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {}).duplicate(true)


func get_living_npcs(world_id: int = -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for value in npcs.values():
		var npc: Dictionary = value

		if not npc.get("alive", false):
			continue

		if world_id >= 0 and int(npc.get("world_id", -1)) != world_id:
			continue

		result.append(npc.duplicate(true))

	return result


func set_activity(
	npc_id: String,
	activity: String,
	location: String = ""
) -> bool:

	if not npcs.has(npc_id):
		return false

	if not ALLOWED_ACTIVITIES.has(activity):
		return false

	var npc: Dictionary = npcs[npc_id]

	if not npc.get("alive", false):
		return false

	npc["activity"] = activity

	if not location.is_empty():
		npc["current_location"] = location

	npcs[npc_id] = npc
	return true


func add_memory(
	npc_id: String,
	event_type: String,
	details: Dictionary
) -> bool:

	if not npcs.has(npc_id):
		return false

	var npc: Dictionary = npcs[npc_id]
	var memory: Array = npc.get("memory", [])

	memory.append({
		"time_hours": simulation_hours,
		"type": event_type,
		"details": details.duplicate(true)
	})

	while memory.size() > MAX_MEMORY:
		memory.pop_front()

	npc["memory"] = memory
	npcs[npc_id] = npc

	return true


func add_friendship(first_id: String, second_id: String) -> bool:
	if first_id == second_id:
		return false

	if not npcs.has(first_id) or not npcs.has(second_id):
		return false

	var first: Dictionary = npcs[first_id]
	var second: Dictionary = npcs[second_id]

	if not first.get("alive", false) or not second.get("alive", false):
		return false

	if int(first.world_id) != int(second.world_id):
		return false

	var first_friends: Array = first.get("friend_ids", [])
	var second_friends: Array = second.get("friend_ids", [])

	if not first_friends.has(second_id):
		first_friends.append(second_id)

	if not second_friends.has(first_id):
		second_friends.append(first_id)

	first["friend_ids"] = first_friends
	second["friend_ids"] = second_friends

	npcs[first_id] = first
	npcs[second_id] = second

	add_memory(first_id, "friendship_formed", {
		"other_npc_id": second_id
	})

	add_memory(second_id, "friendship_formed", {
		"other_npc_id": first_id
	})

	return true


func marry_npcs(first_id: String, second_id: String) -> bool:
	if first_id == second_id:
		return false

	if not npcs.has(first_id) or not npcs.has(second_id):
		return false

	var first: Dictionary = npcs[first_id]
	var second: Dictionary = npcs[second_id]

	if not _can_marry(first) or not _can_marry(second):
		return false

	if int(first.world_id) != int(second.world_id):
		return false

	first["spouse_id"] = second_id
	second["spouse_id"] = first_id

	npcs[first_id] = first
	npcs[second_id] = second

	_add_history(first_id, "married", {
		"spouse_id": second_id
	})

	_add_history(second_id, "married", {
		"spouse_id": first_id
	})

	npc_married.emit(first_id, second_id)
	return true


func have_child(
	parent_a: String,
	parent_b: String,
	child_name: String
) -> String:

	if not npcs.has(parent_a) or not npcs.has(parent_b):
		return ""

	var a: Dictionary = npcs[parent_a]
	var b: Dictionary = npcs[parent_b]

	if not a.get("alive", false) or not b.get("alive", false):
		return ""

	if str(a.get("spouse_id", "")) != parent_b:
		return ""

	if str(b.get("spouse_id", "")) != parent_a:
		return ""

	if int(a.world_id) != int(b.world_id):
		return ""

	var child_id := create_npc(
		child_name,
		int(a.world_id),
		0.0,
		"developing",
		"child",
		parent_a,
		parent_b
	)

	if child_id.is_empty():
		return ""

	add_memory(parent_a, "child_born", {
		"child_id": child_id
	})

	add_memory(parent_b, "child_born", {
		"child_id": child_id
	})

	npc_child_born.emit(parent_a, parent_b, child_id)
	return child_id


func publish_information(
	npc_id: String,
	world_id: int,
	category: String,
	message: String,
	source_location: String = ""
) -> bool:

	if not npcs.has(npc_id):
		return false

	if message.strip_edges().is_empty():
		return false

	if BLOCKED_INFO.has(category):
		return false

	var npc: Dictionary = npcs[npc_id]

	if not npc.get("alive", false):
		return false

	if int(npc.world_id) != world_id:
		return false

	var info := {
		"source_npc_id": npc_id,
		"source_name": str(npc.name),
		"world_id": world_id,
		"category": category,
		"message": message.strip_edges(),
		"source_location": source_location,
		"time_hours": simulation_hours
	}

	public_information.append(info)

	while public_information.size() > MAX_PUBLIC_INFO:
		public_information.pop_front()

	add_memory(npc_id, "information_shared", {
		"category": category,
		"message": message
	})

	information_shared.emit(npc_id, info.duplicate(true))
	return true


func get_information_for_player(
	world_id: int,
	limit: int = 20
) -> Array[Dictionary]:

	var result: Array[Dictionary] = []

	for index in range(public_information.size() - 1, -1, -1):
		var info: Dictionary = public_information[index]

		if int(info.world_id) != world_id:
			continue

		result.append(info.duplicate(true))

		if result.size() >= maxi(1, limit):
			break

	return result


func get_family_tree(npc_id: String) -> Dictionary:
	if not npcs.has(npc_id):
		return {}

	var npc: Dictionary = npcs[npc_id]

	return {
		"npc": npc.duplicate(true),
		"parents": _related_records(npc.get("parent_ids", [])),
		"spouse": get_npc(str(npc.get("spouse_id", ""))),
		"children": _related_records(npc.get("children_ids", []))
	}


func save_society() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error(
			"Could not save AI society: "
			+ str(FileAccess.get_open_error())
		)
		return false

	file.store_string(JSON.stringify({
		"version": 1,
		"simulation_hours": simulation_hours,
		"next_npc_number": next_npc_number,
		"npcs": npcs,
		"public_information": public_information
	}, "\t"))

	file.close()
	return true


func load_society() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return false

	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not data is Dictionary:
		push_warning("AI society save is invalid; starting empty.")
		return false

	var payload: Dictionary = data

	simulation_hours = float(
		payload.get("simulation_hours", 0.0)
	)

	next_npc_number = int(
		payload.get("next_npc_number", 1)
	)

	npcs = payload.get("npcs", {})
	public_information.clear()

	for item in payload.get("public_information", []):
		if item is Dictionary:
			public_information.append(item)

	return true


func _update_age(npc_id: String, hours: float) -> void:
	var npc: Dictionary = npcs[npc_id]

	var old_stage := str(
		npc.get("life_stage", "child")
	)

	var age := float(
		npc.get("age_years", 0.0)
	) + hours / HOURS_PER_YEAR

	npc["age_years"] = age
	npc["life_stage"] = _life_stage(age)
	npcs[npc_id] = npc

	if old_stage != str(npc.life_stage):
		_add_history(npc_id, "life_stage_changed", {
			"from": old_stage,
			"to": npc.life_stage
		})

	if age >= 75.0:
		var hourly_risk := 0.0000007 * pow(
			1.12,
			age - 75.0
		)

		if randf() < 1.0 - pow(1.0 - hourly_risk, hours):
			_mark_dead(npc_id, "old_age")


func _update_needs(npc_id: String, hours: float) -> void:
	var npc: Dictionary = npcs[npc_id]
	var needs: Dictionary = npc.get("needs", {})

	needs["energy"] = clampf(
		float(needs.get("energy", 100.0)) - hours * 0.35,
		0.0,
		100.0
	)

	needs["social"] = clampf(
		float(needs.get("social", 70.0)) - hours * 0.08,
		0.0,
		100.0
	)

	npc["needs"] = needs
	npcs[npc_id] = npc


func _mark_dead(npc_id: String, cause: String) -> void:
	var npc: Dictionary = npcs[npc_id]

	npc["alive"] = false
	npc["activity"] = "deceased"
	npc["death_cause"] = cause
	npc["death_time_hours"] = simulation_hours

	npcs[npc_id] = npc

	var spouse_id := str(npc.get("spouse_id", ""))

	if npcs.has(spouse_id):
		add_memory(spouse_id, "bereavement", {
			"deceased_npc_id": npc_id
		})

	_add_history(npc_id, "death", {
		"cause": cause
	})

	npc_died.emit(npc_id, get_npc(npc_id))


func _life_stage(age: float) -> String:
	if age < 13.0:
		return "child"

	if age < 18.0:
		return "teen"

	if age < 65.0:
		return "adult"

	return "elder"


func _can_marry(npc: Dictionary) -> bool:
	return (
		npc.get("alive", false)
		and float(npc.get("age_years", 0.0)) >= 18.0
		and str(npc.get("spouse_id", "")).is_empty()
	)


func _add_history(
	npc_id: String,
	event_name: String,
	details: Dictionary
) -> void:

	if not npcs.has(npc_id):
		return

	var npc: Dictionary = npcs[npc_id]
	var history: Array = npc.get("life_history", [])

	history.append({
		"time_hours": simulation_hours,
		"event": event_name,
		"details": details.duplicate(true)
	})

	npc["life_history"] = history
	npcs[npc_id] = npc


func _related_records(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for related_id in ids:
		if npcs.has(str(related_id)):
			result.append(get_npc(str(related_id)))

	return result
