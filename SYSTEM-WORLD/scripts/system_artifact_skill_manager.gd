extends Node
class_name SYSTEMArtifactSkillManager

const HISTORICAL_WORLD_ID := 1
const MODERN_WORLD_ID := 2
const QUESTS := {
	"babylon_seal_trial": {"relic_id": "babylon_cuneiform_tablet", "skill_id": "babylon_seal", "title": "ختم بابل القديم"},
	"pharos_sight_trial": {"relic_id": "alexandria_pharos_lens", "skill_id": "pharos_sight", "title": "بصيرة منارة الإسكندرية"},
	"atlantis_tide_trial": {"relic_id": "atlantis_tide_relic", "skill_id": "atlantis_tide_guard", "title": "حارس مدّ أتلانتس"}
}

var world_manager: Node
var progression: Node
var combat_system: Node
var player: CharacterBody3D
var active_offer_quest_id := ""
var panel_layer: CanvasLayer
var panel: PanelContainer
var panel_content: VBoxContainer
var status_label: Label

func setup(world: Node, player_progression: Node, combat: Node, player_actor: CharacterBody3D) -> void:
	world_manager = world
	progression = player_progression
	combat_system = combat
	player = player_actor
	_create_panel()

func _create_panel() -> void:
	panel_layer = CanvasLayer.new()
	panel_layer.name = "ArtifactSkillQuestUI"
	panel_layer.layer = 35
	add_child(panel_layer)
	panel = PanelContainer.new()
	panel.name = "ArtifactSkillPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-245.0, -155.0)
	panel.size = Vector2(490.0, 310.0)
	panel.custom_minimum_size = Vector2(490.0, 310.0)
	panel_layer.add_child(panel)
	panel_content = VBoxContainer.new()
	panel_content.add_theme_constant_override("separation", 10)
	panel.add_child(panel_content)
	panel.hide()

func _clear_panel() -> void:
	for child in panel_content.get_children():
		child.queue_free()

func _set_status(message: String) -> void:
	if status_label != null and is_instance_valid(status_label):
		status_label.text = message
	print("SYSTEM ARTIFACT QUEST: ", message)

func offer_quest_from_exhibit(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var quest_id := str(target.get_meta("system_artifact_quest_id", ""))
	if not QUESTS.has(quest_id):
		return false
	if world_manager == null or int(world_manager.get("active_world")) != MODERN_WORLD_ID:
		return false
	active_offer_quest_id = quest_id
	_clear_panel()
	var definition: Dictionary = QUESTS[quest_id]
	var title := Label.new()
	title.text = "مهمة أثرية نادرة — " + str(definition["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_content.add_child(title)
	var description := Label.new()
	description.text = "اقبل المهمة من سوق التحف، ثم انتقل إلى العالم التاريخي للعثور على الأثر واستعادته. استعادة الأثر تمنح تصريح المهارة النادرة."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_content.add_child(description)
	var accept := Button.new()
	accept.name = "AcceptArtifactQuest"
	accept.text = "قبول المهمة والدخول إلى العالم التاريخي"
	accept.pressed.connect(accept_active_offer)
	panel_content.add_child(accept)
	var close := Button.new()
	close.text = "ليس الآن"
	close.pressed.connect(func(): panel.hide())
	panel_content.add_child(close)
	status_label = Label.new()
	status_label.name = "ArtifactQuestStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_content.add_child(status_label)
	panel.show()
	return true

func accept_active_offer() -> Dictionary:
	if not QUESTS.has(active_offer_quest_id) or progression == null or world_manager == null:
		return {"success": false, "reason": "NO_VALID_ARTIFACT_QUEST_OFFER"}
	var result: Dictionary = progression.call("set_active_artifact_quest", active_offer_quest_id)
	if not bool(result.get("success", false)):
		return result
	var quest_id := active_offer_quest_id
	active_offer_quest_id = ""
	panel.hide()
	world_manager.call("switch_world", HISTORICAL_WORLD_ID)
	return {"success": true, "quest_id": quest_id, "world_id": HISTORICAL_WORLD_ID}

func handle_historical_relic_interaction(target: Node) -> Dictionary:
	if target == null or not is_instance_valid(target) or progression == null or world_manager == null:
		return {"handled": false, "success": false, "reason": "INVALID_RELIC_TARGET"}
	if int(world_manager.get("active_world")) != HISTORICAL_WORLD_ID:
		return {"handled": true, "success": false, "reason": "HISTORICAL_WORLD_REQUIRED"}
	var quest_id := str(progression.get("active_artifact_quest_id"))
	var definition: Dictionary = QUESTS.get(quest_id, {})
	if definition.is_empty():
		return {"handled": true, "success": false, "reason": "NO_ACTIVE_ARTIFACT_QUEST"}
	var relic_id := str(target.get_meta("system_artifact_quest_relic_id", ""))
	if relic_id != str(definition["relic_id"]) or str(target.get_meta("system_artifact_quest_id", "")) != quest_id:
		return {"handled": true, "success": false, "reason": "WRONG_HISTORICAL_RELIC"}
	var completion: Dictionary = progression.call("complete_artifact_quest", quest_id)
	if not bool(completion.get("success", false)):
		return {"handled": true, "success": false, "reason": str(completion.get("reason", "QUEST_COMPLETION_FAILED"))}
	var skill_id := str(definition["skill_id"])
	var permit: Dictionary = progression.call("grant_skill_training_permit", skill_id)
	if not bool(permit.get("success", false)):
		return {"handled": true, "success": false, "reason": "ARTIFACT_RECOVERED_BUT_PERMIT_FAILED", "permit": permit}
	world_manager.call("switch_world", MODERN_WORLD_ID)
	open_training_panel(skill_id, quest_id)
	return {"handled": true, "success": true, "quest_id": quest_id, "skill_id": skill_id, "permit": permit}

func open_training_panel(skill_id: String, quest_id: String) -> void:
	_clear_panel()
	var title := Label.new()
	title.text = "تصريح مهارة أثرية: " + skill_id
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_content.add_child(title)
	var instructions := Label.new()
	instructions.text = "أكمل ثلاث جلسات تدريب مختلفة. شراء التصريح وحده لا يفتح المهارة."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_content.add_child(instructions)
	status_label = Label.new()
	status_label.name = "ArtifactQuestStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_content.add_child(status_label)
	for session_index in range(3):
		var session_button := Button.new()
		session_button.name = "ArtifactTrainingSession_%d" % (session_index + 1)
		session_button.text = "جلسة التدريب %d / 3" % (session_index + 1)
		session_button.pressed.connect(practice_artifact_skill.bind(skill_id, quest_id + "_session_" + str(session_index + 1)))
		panel_content.add_child(session_button)
	var activate := Button.new()
	activate.name = "ActivateArtifactSkillInCombat"
	activate.text = "تفعيل المهارة في القتال"
	activate.pressed.connect(activate_artifact_skill_in_combat.bind(skill_id))
	panel_content.add_child(activate)
	var close := Button.new()
	close.text = "إغلاق"
	close.pressed.connect(func(): panel.hide())
	panel_content.add_child(close)
	_update_training_status(skill_id)
	panel.show()

func practice_artifact_skill(skill_id: String, session_id: String) -> Dictionary:
	if progression == null or not QUESTS.values().any(func(entry: Dictionary) -> bool: return str(entry["skill_id"]) == skill_id):
		return {"success": false, "reason": "UNKNOWN_ARTIFACT_SKILL"}
	var result: Dictionary = progression.call("practice_system_skill", skill_id, session_id)
	_update_training_status(skill_id)
	return result

func _update_training_status(skill_id: String) -> void:
	if status_label == null or progression == null:
		return
	var practice: Dictionary = progression.get("system_skill_practice")
	var count := int(practice.get(skill_id, 0))
	var learned: Array = progression.get("learned_system_skills")
	status_label.text = "جلسات التدريب: %d / 3\nحالة المهارة: %s" % [mini(count, 3), "مفتوحة" if learned.has(skill_id) else "قيد التدريب"]
	var activate := panel_content.get_node_or_null("ActivateArtifactSkillInCombat") as Button
	if activate != null:
		activate.disabled = not learned.has(skill_id)

func activate_artifact_skill_in_combat(skill_id: String) -> Dictionary:
	if world_manager == null or int(world_manager.get("active_world")) != MODERN_WORLD_ID:
		return {"success": false, "reason": "COMBAT_WORLD_REQUIRED"}
	if combat_system == null or not combat_system.has_method("activate_artifact_skill"):
		return {"success": false, "reason": "COMBAT_SKILL_ROUTER_UNAVAILABLE"}
	var result: Dictionary = combat_system.call("activate_artifact_skill", skill_id)
	_update_training_status(skill_id)
	if bool(result.get("success", false)):
		_set_status("تم تفعيل المهارة الأثرية داخل نظام القتال: " + skill_id)
	return result
