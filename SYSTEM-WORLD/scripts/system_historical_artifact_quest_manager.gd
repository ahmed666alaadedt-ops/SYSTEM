extends Node
class_name SYSTEMHistoricalArtifactQuestManager

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String, artifact_id: String)
signal quest_rejected(quest_id: String, reason: String)

const SAVE_PATH := "user://system_historical_artifact_quests.cfg"
const QUESTS := {
	"babylon_storm_seal": {
		"title": "سر لوح العاصفة البابلي",
		"relic_id": "babylon_storm_tablet",
		"artifact_id": "babylon_storm_tablet",
		"artifact_name": "لوح العاصفة البابلي",
		"civilization": "حضارة بابل",
		"skill_id": "ancient_lightning",
		"xp": 750,
		"mission_points": 750
	},
	"nineveh_shadow_seal": {
		"title": "ختم الظلال الآشوري",
		"relic_id": "nineveh_shadow_seal",
		"artifact_id": "nineveh_shadow_seal",
		"artifact_name": "ختم الظلال من نينوى",
		"civilization": "الإمبراطورية الآشورية — نينوى",
		"skill_id": "shadow_cloak",
		"xp": 1000,
		"mission_points": 1000
	},
	"assyrian_colossus_core": {
		"title": "قلب التجسيد الآشوري",
		"relic_id": "assyrian_colossus_core",
		"artifact_id": "assyrian_colossus_core",
		"artifact_name": "قلب الحارس العملاق الآشوري",
		"civilization": "الإمبراطورية الآشورية",
		"skill_id": "titan_embodiment",
		"xp": 1500,
		"mission_points": 1500
	}
}

var progression: Node
var accepted_quests: Dictionary = {}
var completed_quests: Dictionary = {}
var reward_stages: Dictionary = {}


func setup(player_progression: Node) -> void:
	progression = player_progression
	_load_quest_state()


func start_quest(quest_id: String) -> Dictionary:
	var key := quest_id.strip_edges().to_lower()
	if not QUESTS.has(key):
		quest_rejected.emit(key, "UNKNOWN_HISTORICAL_QUEST")
		return {"success": false, "reason": "UNKNOWN_HISTORICAL_QUEST"}
	if completed_quests.has(key):
		return {"success": false, "reason": "QUEST_ALREADY_COMPLETED"}
	if accepted_quests.has(key):
		return {"success": true, "already_accepted": true, "quest_id": key, "title": str(QUESTS[key]["title"])}
	accepted_quests[key] = true
	_save_quest_state()
	quest_started.emit(key)
	return {"success": true, "quest_id": key, "title": str(QUESTS[key]["title"])}


func complete_quest(quest_id: String, recovered_relic_id: String) -> Dictionary:
	var key := quest_id.strip_edges().to_lower()
	if not QUESTS.has(key):
		quest_rejected.emit(key, "UNKNOWN_HISTORICAL_QUEST")
		return {"success": false, "reason": "UNKNOWN_HISTORICAL_QUEST"}
	if completed_quests.has(key):
		return {"success": false, "reason": "QUEST_ALREADY_COMPLETED"}
	if not accepted_quests.has(key):
		quest_rejected.emit(key, "QUEST_NOT_ACCEPTED_FROM_ANTIQUES_MARKET")
		return {"success": false, "reason": "QUEST_NOT_ACCEPTED"}
	var quest: Dictionary = QUESTS[key]
	if recovered_relic_id.strip_edges() != str(quest["relic_id"]):
		quest_rejected.emit(key, "WRONG_HISTORICAL_RELIC")
		return {"success": false, "reason": "WRONG_HISTORICAL_RELIC"}
	if not is_instance_valid(progression):
		quest_rejected.emit(key, "PLAYER_PROGRESSION_UNAVAILABLE")
		return {"success": false, "reason": "PLAYER_PROGRESSION_UNAVAILABLE"}

	var stage: Dictionary = reward_stages.get(key, {})
	var artifact_id := str(quest["artifact_id"])
	if not bool(stage.get("artifact_granted", false)):
		if int(progression.call("get_item_count", artifact_id)) <= 0:
			if not bool(progression.call("add_item", artifact_id, 1)):
				return {"success": false, "reason": "ARTIFACT_REWARD_FAILED"}
		stage["artifact_granted"] = true
		reward_stages[key] = stage
		_save_quest_state()

	if not bool(stage.get("permit_granted", false)):
		if not progression.has_method("grant_artifact_skill_training_permit"):
			return {"success": false, "reason": "ARTIFACT_SKILL_PERMIT_SERVICE_UNAVAILABLE"}
		var permit: Dictionary = progression.call("grant_artifact_skill_training_permit", str(quest["skill_id"]), artifact_id)
		if not bool(permit.get("success", false)):
			return {"success": false, "reason": str(permit.get("reason", "ARTIFACT_SKILL_PERMIT_FAILED"))}
		stage["permit_granted"] = true
		reward_stages[key] = stage
		_save_quest_state()

	if not bool(stage.get("rank_recorded", false)):
		if not bool(progression.call("has_verified_hunter_mission", key)):
			var rank_result: Dictionary = progression.call("record_verified_hunter_mission", key, int(quest["mission_points"]), false, "")
			if not bool(rank_result.get("success", false)):
				return {"success": false, "reason": str(rank_result.get("reason", "HUNTER_RANK_REWARD_FAILED"))}
		stage["rank_recorded"] = true
		reward_stages[key] = stage
		_save_quest_state()

	if not bool(stage.get("xp_granted", false)):
		var xp_result: Dictionary = progression.call("add_experience", int(quest["xp"]), "Historical artifact quest: " + key)
		if not bool(xp_result.get("success", false)):
			return {"success": false, "reason": "HISTORICAL_QUEST_XP_FAILED"}
		stage["xp_granted"] = true
		reward_stages[key] = stage
		_save_quest_state()

	completed_quests[key] = true
	accepted_quests.erase(key)
	_save_quest_state()
	quest_completed.emit(key, artifact_id)
	return {"success": true, "quest_id": key, "artifact_id": artifact_id, "skill_id": str(quest["skill_id"]), "title": str(quest["title"])}


func get_quest_status(quest_id: String) -> Dictionary:
	var key := quest_id.strip_edges().to_lower()
	if not QUESTS.has(key):
		return {"known": false}
	var stages: Dictionary = reward_stages.get(key, {})
	return {
		"known": true,
		"title": str(QUESTS[key]["title"]),
		"accepted": accepted_quests.has(key),
		"completed": completed_quests.has(key),
		"reward_stages": stages.duplicate(true)
	}


func _load_quest_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved_accepted: Array = config.get_value("quests", "accepted", [])
	var saved_completed: Array = config.get_value("quests", "completed", [])
	accepted_quests.clear()
	completed_quests.clear()
	for value in saved_accepted:
		var key := str(value)
		if QUESTS.has(key) and not saved_completed.has(key):
			accepted_quests[key] = true
	for value in saved_completed:
		var key := str(value)
		if QUESTS.has(key):
			completed_quests[key] = true
	reward_stages = config.get_value("quests", "reward_stages", {})


func _save_quest_state() -> void:
	var config := ConfigFile.new()
	config.set_value("quests", "accepted", accepted_quests.keys())
	config.set_value("quests", "completed", completed_quests.keys())
	config.set_value("quests", "reward_stages", reward_stages.duplicate(true))
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM: Could not persist historical artifact quest progress.")
