extends Node
class_name ArtifactRelicQuestManager

## Story and reward bridge for historical relic quests.
## The authoritative marketplace still owns artifact custody and ownership.
## This node tracks quest progression and emits requests; it never edits wallet,
## marketplace ownership, or server-granted rewards directly.

signal historical_world_requested(world_id: String, quest_id: String, relic_id: String)
signal relic_return_requested(relic_id: String, historical_site_id: String, quest_id: String)
signal rare_skill_reward_requested(skill_id: String, relic_id: String, quest_id: String)
signal present_world_return_requested(quest_id: String, relic_id: String)
signal quest_state_changed(quest_id: String, state: String)
signal quest_message(message: String)

const QUEST_STATE_DISCOVERED := "discovered"
const QUEST_STATE_ACTIVE := "active"
const QUEST_STATE_READY_TO_RETURN := "ready_to_return"
const QUEST_STATE_COMPLETED := "completed"

# Each relic binds one historical setting, objectives, a return rule and a rare skill.
# IDs are stable content identifiers; actual artifact ownership remains server-authoritative.
const RELIC_QUESTS := {
	"babylonian_star_tablet": {
		"artifact_name": "لوح النجمة البابلي",
		"world_id": "ancient_babylon",
		"historical_site_id": "babylon_esagila_archive",
		"quest_id": "quest_babylon_star_tablet",
		"title": "سرّ لوح النجمة",
		"objectives": ["find_the_sealed_archive", "solve_the_celestial_lock", "defeat_the_archive_guardian"],
		"return_relic": true,
		"skill_id": "rare_skill_celestial_lightning",
		"skill_name": "البرق السماوي",
		"skill_rarity": "mythic"
	},
	"sumerian_oath_seal": {
		"artifact_name": "ختم العهد السومري",
		"world_id": "ancient_sumer",
		"historical_site_id": "ur_royal_temple",
		"quest_id": "quest_sumerian_oath",
		"title": "العهد المنقوش",
		"objectives": ["recover_the_three_oaths", "restore_the_temple_seal"],
		"return_relic": true,
		"skill_id": "rare_skill_earth_guardian",
		"skill_name": "درع حارس الأرض",
		"skill_rarity": "legendary"
	},
	"akkadian_shadow_crown": {
		"artifact_name": "تاج الظل الأكدي",
		"world_id": "ancient_akkad",
		"historical_site_id": "akkad_hidden_sanctum",
		"quest_id": "quest_akkadian_shadow",
		"title": "عرش الظلال",
		"objectives": ["trace_the_lost_dynasty", "pass_the_shadow_trial", "seal_the_cursed_chamber"],
		"return_relic": false,
		"skill_id": "rare_skill_shadow_avatar",
		"skill_name": "تجسيد الظل",
		"skill_rarity": "mythic"
	}
}

var _quest_states: Dictionary = {}
var _objective_progress: Dictionary = {}
var _completed_rewards: Dictionary = {}

func inspect_relic(relic_id: String) -> Dictionary:
	if not RELIC_QUESTS.has(relic_id):
		return {"ok": false, "message": "هذه القطعة لا تملك مهمة تاريخية مرتبطة بها."}
	var definition: Dictionary = RELIC_QUESTS[relic_id]
	if _quest_states.get(relic_id, "") == QUEST_STATE_COMPLETED:
		return {"ok": true, "completed": true, "definition": definition.duplicate(true)}
	if not _quest_states.has(relic_id):
		_quest_states[relic_id] = QUEST_STATE_DISCOVERED
		_objective_progress[relic_id] = {}
		quest_state_changed.emit(String(definition.quest_id), QUEST_STATE_DISCOVERED)
	return {
		"ok": true,
		"completed": false,
		"definition": definition.duplicate(true),
		"message": "نقوش التحفة تشير إلى عالم تاريخي ومهمة سرية."
	}

func begin_relic_quest(relic_id: String, player_confirmed: bool) -> Dictionary:
	if not player_confirmed:
		return {"ok": false, "message": "لم يبدأ الانتقال؛ ينتظر تأكيد اللاعب."}
	if not RELIC_QUESTS.has(relic_id):
		return {"ok": false, "message": "معرّف التحفة غير معروف."}
	var definition: Dictionary = RELIC_QUESTS[relic_id]
	var state := String(_quest_states.get(relic_id, QUEST_STATE_DISCOVERED))
	if state == QUEST_STATE_COMPLETED:
		return {"ok": false, "message": "أُكملت هذه المهمة سابقاً."}
	if state == QUEST_STATE_ACTIVE or state == QUEST_STATE_READY_TO_RETURN:
		return {"ok": false, "message": "هذه المهمة قيد التنفيذ بالفعل."}
	_quest_states[relic_id] = QUEST_STATE_ACTIVE
	_objective_progress[relic_id] = {}
	quest_state_changed.emit(String(definition.quest_id), QUEST_STATE_ACTIVE)
	historical_world_requested.emit(String(definition.world_id), String(definition.quest_id), relic_id)
	return {"ok": true, "world_id": definition.world_id, "quest_id": definition.quest_id}

func record_historical_objective(relic_id: String, objective_id: String, trusted_event: bool) -> Dictionary:
	if not trusted_event:
		return {"ok": false, "message": "لا يُقبل إنجاز هدف المهمة من حدث غير موثوق."}
	if not RELIC_QUESTS.has(relic_id) or _quest_states.get(relic_id, "") != QUEST_STATE_ACTIVE:
		return {"ok": false, "message": "لا توجد مهمة نشطة لهذه التحفة."}
	var definition: Dictionary = RELIC_QUESTS[relic_id]
	var objectives: Array = definition.objectives
	if not objectives.has(objective_id):
		return {"ok": false, "message": "الهدف غير تابع لهذه المهمة."}
	var progress: Dictionary = _objective_progress.get(relic_id, {})
	progress[objective_id] = true
	_objective_progress[relic_id] = progress
	for required_objective in objectives:
		if not progress.get(required_objective, false):
			return {"ok": true, "all_objectives_complete": false, "completed_count": progress.size(), "required_count": objectives.size()}
	if bool(definition.return_relic):
		_quest_states[relic_id] = QUEST_STATE_READY_TO_RETURN
		quest_state_changed.emit(String(definition.quest_id), QUEST_STATE_READY_TO_RETURN)
		quest_message.emit("اكتملت المهمة. أعد التحفة إلى موقعها التاريخي لاستلام المهارة.")
		return {"ok": true, "all_objectives_complete": true, "return_required": true, "site_id": definition.historical_site_id}
	return _complete_reward(relic_id, definition)

func confirm_relic_return(relic_id: String, returned_at_site: bool, trusted_server_confirmation: bool) -> Dictionary:
	if not RELIC_QUESTS.has(relic_id) or _quest_states.get(relic_id, "") != QUEST_STATE_READY_TO_RETURN:
		return {"ok": false, "message": "هذه التحفة ليست بانتظار الإرجاع."}
	if not returned_at_site or not trusted_server_confirmation:
		return {"ok": false, "message": "يجب تأكيد إرجاع التحفة إلى موقعها التاريخي من الخادم."}
	var definition: Dictionary = RELIC_QUESTS[relic_id]
	relic_return_requested.emit(relic_id, String(definition.historical_site_id), String(definition.quest_id))
	return _complete_reward(relic_id, definition)

func _complete_reward(relic_id: String, definition: Dictionary) -> Dictionary:
	var quest_id := String(definition.quest_id)
	if _completed_rewards.has(quest_id):
		return {"ok": false, "message": "مكافأة هذه المهمة صُرفت سابقاً."}
	_completed_rewards[quest_id] = true
	_quest_states[relic_id] = QUEST_STATE_COMPLETED
	quest_state_changed.emit(quest_id, QUEST_STATE_COMPLETED)
	rare_skill_reward_requested.emit(String(definition.skill_id), relic_id, quest_id)
	present_world_return_requested.emit(quest_id, relic_id)
	quest_message.emit("حصلت على المهارة النادرة: " + String(definition.skill_name))
	return {
		"ok": true,
		"completed": true,
		"skill_id": definition.skill_id,
		"skill_name": definition.skill_name,
		"skill_rarity": definition.skill_rarity
	}

func get_relic_quest_state(relic_id: String) -> String:
	return String(_quest_states.get(relic_id, "not_discovered"))

func get_objective_progress(relic_id: String) -> Dictionary:
	return (_objective_progress.get(relic_id, {}) as Dictionary).duplicate(true)
