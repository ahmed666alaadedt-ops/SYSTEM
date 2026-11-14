
extends Node
class_name SYSTEMMissionRewardManager

signal mission_rewarded(mission_id: String, xp_amount: int)
signal mission_rejected(mission_id: String, reason: String)

const MISSION_REWARDS := {
	"guild_001": 100,
	"guild_002": 250,
	"guild_003": 500
}

var progression: Node
var accepted_missions: Dictionary = {}
var completed_missions: Dictionary = {}


func _ready() -> void:
	progression = get_parent().get_node_or_null("PlayerProgression")

	if progression == null:
		push_warning("SYSTEM: PlayerProgression is missing.")


func accept_mission(mission_id: String) -> bool:
	if not MISSION_REWARDS.has(mission_id):
		mission_rejected.emit(mission_id, "UNKNOWN_MISSION")
		return false

	if accepted_missions.has(mission_id):
		return false

	if completed_missions.has(mission_id):
		return false

	accepted_missions[mission_id] = true

	print("SYSTEM: Mission accepted: ", mission_id)
	return true


# تستدعى فقط من نظام أهداف موثوق بعد التحقق من إنجاز المهمة.
func confirm_verified_completion(mission_id: String) -> bool:
	if not accepted_missions.has(mission_id):
		mission_rejected.emit(mission_id, "MISSION_NOT_ACCEPTED")
		return false

	if completed_missions.has(mission_id):
		mission_rejected.emit(mission_id, "MISSION_ALREADY_COMPLETED")
		return false

	if not is_instance_valid(progression):
		mission_rejected.emit(mission_id, "PROGRESSION_UNAVAILABLE")
		return false

	var reward: int = int(MISSION_REWARDS.get(mission_id, 0))

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

	completed_missions[mission_id] = true
	accepted_missions.erase(mission_id)

	mission_rewarded.emit(mission_id, reward)

	print(
		"SYSTEM: Verified mission completed: ",
		mission_id,
		" | XP: ",
		reward
	)

	return true


func is_mission_accepted(mission_id: String) -> bool:
	return accepted_missions.has(mission_id)


func is_mission_completed(mission_id: String) -> bool:
	return completed_missions.has(mission_id)
