extends Node
class_name SYSTEMMissionRewardManager

signal mission_rewarded(mission_id: String, xp_amount: int)
signal mission_rejected(mission_id: String, reason: String)
signal mission_progress_changed(mission_id: String, current: int, required: int)
signal mission_status_changed(mission_id: String, status: String)

const SAVE_PATH := "user://system_mission_state.json"

# تعريف الأهداف هنا يحدد الحدث الحقيقي المطلوب، وليس مجرد ضغط زر الإكمال.
const MISSION_DEFINITIONS := {
	"guild_001": {
		"reward": 100,
		"objective_event": "discover_location",
		"required": 1
	},
	"guild_002": {
		"reward": 250,
		"objective_event": "scan_creature",
		"required": 1
	},
	"guild_003": {
		"reward": 500,
		"objective_event": "investigate_portal",
		"required": 1
	}
}

var progression: Node
# mission_id -> progress count
var accepted_missions: Dictionary = {}
var completed_missions: Dictionary = {}
# mission_id -> { event_id: true }; يمنع احتساب الحدث نفسه مرتين.
var processed_objective_events: Dictionary = {}


func _ready() -> void:
	var scene_root := get_parent()
	if scene_root != null:
		progression = scene_root.get_node_or_null("PlayerProgression")

	if progression == null:
		push_warning("SYSTEM: PlayerProgression is missing.")

	_load_state()


func accept_mission(mission_id: String) -> bool:
	if not MISSION_DEFINITIONS.has(mission_id):
		mission_rejected.emit(mission_id, "UNKNOWN_MISSION")
		return false

	if accepted_missions.has(mission_id) or completed_missions.has(mission_id):
		mission_rejected.emit(mission_id, "MISSION_ALREADY_ACTIVE_OR_COMPLETED")
		return false

	accepted_missions[mission_id] = 0
	processed_objective_events[mission_id] = {}
	_save_state()
	mission_status_changed.emit(mission_id, "accepted")

	var definition: Dictionary = MISSION_DEFINITIONS[mission_id]
	mission_progress_changed.emit(
		mission_id,
		0,
		int(definition["required"])
	)

	print("SYSTEM: Mission accepted: ", mission_id)
	return true


## يسجل حدثاً حدث فعلاً داخل العالم. event_id فريد حتى لا يتكرر احتساب نفس الاكتشاف.
func record_objective_event(
	event_type: String,
	event_id: String,
	amount: int = 1
) -> int:
	if event_type.is_empty() or event_id.is_empty() or amount <= 0:
		return 0

	var updated_count := 0

	for mission_variant in accepted_missions.keys():
		var mission_id := str(mission_variant)
		if not MISSION_DEFINITIONS.has(mission_id):
			continue

		var definition: Dictionary = MISSION_DEFINITIONS[mission_id]
		if str(definition["objective_event"]) != event_type:
			continue

		var processed: Dictionary = processed_objective_events.get(
			mission_id,
			{}
		)
		if processed.has(event_id):
			continue

		processed[event_id] = true
		processed_objective_events[mission_id] = processed

		var required := int(definition["required"])
		var current := int(accepted_missions[mission_id])
		current = mini(current + amount, required)
		accepted_missions[mission_id] = current
		updated_count += 1

		mission_progress_changed.emit(mission_id, current, required)
		_save_state()

		if current >= required:
			_complete_mission(mission_id)

	return updated_count


# لا تُقبل المكافأة إلا بعد بلوغ الهدف المسجل من أحداث العالم.
func confirm_verified_completion(mission_id: String) -> bool:
	if not accepted_missions.has(mission_id):
		mission_rejected.emit(mission_id, "MISSION_NOT_ACCEPTED")
		return false

	if completed_missions.has(mission_id):
		mission_rejected.emit(mission_id, "MISSION_ALREADY_COMPLETED")
		return false

	var definition: Dictionary = MISSION_DEFINITIONS.get(mission_id, {})
	if definition.is_empty():
		mission_rejected.emit(mission_id, "UNKNOWN_MISSION")
		return false

	if int(accepted_missions[mission_id]) < int(definition["required"]):
		mission_rejected.emit(mission_id, "OBJECTIVE_NOT_COMPLETED")
		return false

	return _complete_mission(mission_id)


func _complete_mission(mission_id: String) -> bool:
	if not accepted_missions.has(mission_id):
		return false

	if not is_instance_valid(progression):
		mission_rejected.emit(mission_id, "PROGRESSION_UNAVAILABLE")
		return false

	var definition: Dictionary = MISSION_DEFINITIONS.get(mission_id, {})
	var reward := int(definition.get("reward", 0))
	if reward <= 0:
		mission_rejected.emit(mission_id, "INVALID_REWARD")
		return false

	var result: Dictionary = progression.add_experience(
		reward,
		"Mission: " + mission_id
	)
	if not bool(result.get("success", false)):
		mission_rejected.emit(mission_id, "XP_REWARD_FAILED")
		return false

	accepted_missions.erase(mission_id)
	completed_missions[mission_id] = true
	_save_state()

	mission_status_changed.emit(mission_id, "completed")
	mission_rewarded.emit(mission_id, reward)
	print(
		"SYSTEM: Objective completed: ",
		mission_id,
		" | XP: ",
		reward
	)
	return true


func get_mission_progress(mission_id: String) -> Dictionary:
	if not MISSION_DEFINITIONS.has(mission_id):
		return {}

	var definition: Dictionary = MISSION_DEFINITIONS[mission_id]
	return {
		"accepted": accepted_missions.has(mission_id),
		"completed": completed_missions.has(mission_id),
		"progress": int(accepted_missions.get(mission_id, 0)),
		"required": int(definition["required"]),
		"reward": int(definition["reward"]),
		"objective_event": str(definition["objective_event"])
	}


func is_mission_accepted(mission_id: String) -> bool:
	return accepted_missions.has(mission_id)


func is_mission_completed(mission_id: String) -> bool:
	return completed_missions.has(mission_id)


func _save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SYSTEM: Mission state could not be saved.")
		return

	var state := {
		"accepted_missions": accepted_missions,
		"completed_missions": completed_missions,
		"processed_objective_events": processed_objective_events
	}
	file.store_string(JSON.stringify(state))


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SYSTEM: Mission state could not be loaded.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SYSTEM: Mission save data is invalid.")
		return

	var state: Dictionary = parsed
	var saved_accepted: Variant = state.get("accepted_missions", {})
	var saved_completed: Variant = state.get("completed_missions", {})
	var saved_events: Variant = state.get("processed_objective_events", {})

	if typeof(saved_accepted) == TYPE_DICTIONARY:
		for key in saved_accepted.keys():
			var mission_id := str(key)
			if MISSION_DEFINITIONS.has(mission_id):
				accepted_missions[mission_id] = clampi(
					int(saved_accepted[key]),
					0,
					int(MISSION_DEFINITIONS[mission_id]["required"])
				)

	if typeof(saved_completed) == TYPE_DICTIONARY:
		for key in saved_completed.keys():
			var mission_id := str(key)
			if MISSION_DEFINITIONS.has(mission_id) and bool(saved_completed[key]):
				completed_missions[mission_id] = true

	if typeof(saved_events) == TYPE_DICTIONARY:
		for key in saved_events.keys():
			var mission_id := str(key)
			if MISSION_DEFINITIONS.has(mission_id) and typeof(saved_events[key]) == TYPE_DICTIONARY:
				processed_objective_events[mission_id] = saved_events[key]
