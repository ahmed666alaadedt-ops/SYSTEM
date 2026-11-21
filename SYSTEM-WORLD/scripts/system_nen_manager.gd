extends Node
class_name SYSTEMNenManager

## Original SYSTEM aura discipline inspired by the broad idea of Nen.
## Every eligible character can discover it; affinity and growth are individual.
## This local prototype is not an online/server-authoritative anti-cheat system.

signal nen_state_changed(character_id: String, state: Dictionary)
signal discovery_stage_changed(character_id: String, stage: int)

var save_path := "user://system_nen_progress.cfg"
const AFFINITIES := ["enhancement", "emission", "manipulation", "transmutation", "conjuration", "specialization"]
const AFFINITY_AR := {
	"enhancement": "التعزيز",
	"emission": "الإطلاق",
	"manipulation": "التحكم",
	"transmutation": "التحويل",
	"conjuration": "التجسيد",
	"specialization": "التخصص"
}
const TECHNIQUES := {
	"enhancement": ["قبضة الاندفاع", "درع النبض", "خطوة الثبات"],
	"emission": ["نبضة بعيدة", "قذيفة الهالة", "موجة الصدى"],
	"manipulation": ["خيط التوجيه", "علامة الاستدعاء", "توجيه الحركة"],
	"transmutation": ["هالة الشحنة", "نبض متغير", "غلاف الصدى"],
	"conjuration": ["أداة الهالة", "حاجز متشكل", "مرساة الطاقة"],
	"specialization": ["بصمة الإدراك", "عين الاحتمال", "أثر الذاكرة"]
}
const DISCOVERY_STEPS := [
	"الإحساس بوجود الهالة",
	"فتح تدفق الهالة والسيطرة الأولية",
	"اكتشاف الميل الشخصي"
]

var profiles: Dictionary = {}
var player_id := "local_player"
var progression: Node
var _rng := RandomNumberGenerator.new()


func setup(player_progression: Node = null) -> void:
	progression = player_progression
	_rng.randomize()
	_load_state()
	register_character(player_id, {"is_player": true, "name": "اللاعب"}, true)


func register_character(character_id: String, character_profile: Dictionary = {}, is_player: bool = false) -> Dictionary:
	var key := character_id.strip_edges()
	if key.is_empty():
		return {"success": false, "reason": "INVALID_CHARACTER_ID"}
	if profiles.has(key):
		var existing: Dictionary = profiles[key]
		if is_player:
			existing["is_player"] = true
			profiles[key] = existing
		return {"success": true, "profile": existing.duplicate(true), "already_registered": true}
	var seed_text := "%s|%s|%s|%s" % [
		key,
		str(character_profile.get("personality", character_profile.get("temperament", "balanced"))),
		str(character_profile.get("background", character_profile.get("occupation", "unknown"))),
		str(character_profile.get("birth_seed", character_profile.get("variant_index", key.hash())))
	]
	var affinity: String = AFFINITIES[abs(seed_text.hash()) % AFFINITIES.size()]
	var record := {
		"character_id": key,
		"display_name": str(character_profile.get("name", key)),
		"is_player": is_player or bool(character_profile.get("is_player", false)),
		"eligible": bool(character_profile.get("nen_eligible", true)),
		"discovered": false,
		"discovery_stage": 0,
		"insight": 0,
		"affinity": affinity,
		"affinity_revealed": false,
		"aura_control": 0,
		"aura_capacity": 10 + abs(seed_text.hash() % 16),
		"training": {"ten": 0, "ren": 0, "zetsu": 0, "hatsu": 0},
		"technique": "",
		"technique_unlocked": false,
		"vow": "",
		"training_sessions": 0,
		"created_at": int(Time.get_unix_time_from_system())
	}
	profiles[key] = record
	_save_state()
	return {"success": true, "profile": record.duplicate(true), "already_registered": false}


func add_discovery_insight(character_id: String, source: String = "observation") -> Dictionary:
	var record := _get_or_register(character_id)
	if not bool(record.get("eligible", true)):
		return {"success": false, "reason": "CHARACTER_NOT_ELIGIBLE"}
	if bool(record.get("discovered", false)):
		return {"success": false, "reason": "NEN_ALREADY_DISCOVERED"}
	var amount := 2 if source in ["mentor", "hunter_exam", "dangerous_encounter", "deep_meditation"] else 1
	record["insight"] = mini(3, int(record.get("insight", 0)) + amount)
	var old_stage := int(record.get("discovery_stage", 0))
	record["discovery_stage"] = mini(3, int(record["insight"]))
	profiles[character_id] = record
	if int(record["discovery_stage"]) != old_stage:
		discovery_stage_changed.emit(character_id, int(record["discovery_stage"]))
	_save_state()
	_emit_state(character_id)
	if int(record["insight"]) >= 3:
		return awaken(character_id)
	return {"success": true, "discovered": false, "insight": int(record["insight"]), "stage": int(record["discovery_stage"]), "next_step": DISCOVERY_STEPS[mini(int(record["discovery_stage"]), 2)]}


func awaken(character_id: String) -> Dictionary:
	var record := _get_or_register(character_id)
	if not bool(record.get("eligible", true)):
		return {"success": false, "reason": "CHARACTER_NOT_ELIGIBLE"}
	if bool(record.get("discovered", false)):
		return {"success": false, "reason": "NEN_ALREADY_DISCOVERED"}
	if int(record.get("insight", 0)) < 3:
		return {"success": false, "reason": "DISCOVERY_INSIGHT_INCOMPLETE", "insight": int(record.get("insight", 0)), "required": 3}
	record["discovered"] = true
	record["discovery_stage"] = 3
	record["aura_control"] = 1
	record["affinity_revealed"] = true
	profiles[character_id] = record
	discovery_stage_changed.emit(character_id, 3)
	_save_state()
	_emit_state(character_id)
	return {"success": true, "discovered": true, "affinity": str(record["affinity"]), "affinity_ar": str(AFFINITY_AR[record["affinity"]]), "message": "اكتشفت الهالة وظهر ميلك الخاص."}


func train(character_id: String, discipline: String, effort: int = 1) -> Dictionary:
	var record := _get_or_register(character_id)
	if not bool(record.get("discovered", false)):
		return {"success": false, "reason": "NEN_NOT_DISCOVERED"}
	var key := discipline.strip_edges().to_lower()
	if not ["ten", "ren", "zetsu", "hatsu"].has(key):
		return {"success": false, "reason": "UNKNOWN_DISCIPLINE"}
	var amount := clampi(effort, 1, 3)
	var training: Dictionary = record.get("training", {})
	var before := int(training.get(key, 0))
	training[key] = mini(100, before + amount)
	record["training"] = training
	record["training_sessions"] = int(record.get("training_sessions", 0)) + 1
	record["aura_control"] = mini(100, int(record.get("aura_control", 0)) + 1)
	profiles[character_id] = record
	_save_state()
	_emit_state(character_id)
	return {"success": true, "discipline": key, "value": int(training[key]), "aura_control": int(record["aura_control"]), "sessions": int(record["training_sessions"])}


func create_personal_technique(character_id: String, technique_name: String = "", vow: String = "") -> Dictionary:
	var record := _get_or_register(character_id)
	if not bool(record.get("discovered", false)):
		return {"success": false, "reason": "NEN_NOT_DISCOVERED"}
	if bool(record.get("technique_unlocked", false)):
		return {"success": false, "reason": "PERSONAL_TECHNIQUE_ALREADY_CREATED"}
	var training: Dictionary = record.get("training", {})
	if int(training.get("ten", 0)) < 5 or int(training.get("ren", 0)) < 5 or int(training.get("zetsu", 0)) < 3:
		return {"success": false, "reason": "FOUNDATION_TRAINING_REQUIRED", "required": {"ten": 5, "ren": 5, "zetsu": 3}}
	var affinity := str(record.get("affinity", "enhancement"))
	var options: Array = TECHNIQUES.get(affinity, TECHNIQUES["enhancement"])
	var selected_name := technique_name.strip_edges()
	if selected_name.is_empty():
		selected_name = str(options[abs((character_id + affinity).hash()) % options.size()])
	record["technique"] = selected_name
	record["technique_unlocked"] = true
	record["vow"] = vow.strip_edges()
	profiles[character_id] = record
	_save_state()
	_emit_state(character_id)
	return {"success": true, "technique": selected_name, "affinity": affinity, "vow": str(record["vow"]), "message": "تم إنشاء أسلوبك الشخصي الأول؛ تطويره يعتمد على التدريب والقيود التي تختارها."}


func get_character_state(character_id: String) -> Dictionary:
	return _get_or_register(character_id).duplicate(true)


func get_affinity_ar(character_id: String) -> String:
	var record := _get_or_register(character_id)
	if not bool(record.get("affinity_revealed", false)):
		return "غير مكتشف"
	return str(AFFINITY_AR.get(str(record.get("affinity", "")), "غير محدد"))


func get_population_discovery_summary() -> Dictionary:
	var total := profiles.size()
	var discovered := 0
	for key in profiles:
		if bool(profiles[key].get("discovered", false)):
			discovered += 1
	return {"registered_characters": total, "discovered": discovered, "undiscovered": total - discovered, "all_can_discover": true}


func _get_or_register(character_id: String) -> Dictionary:
	if not profiles.has(character_id):
		register_character(character_id, {"name": character_id}, character_id == player_id)
	return profiles[character_id].duplicate(true)


func _emit_state(character_id: String) -> void:
	nen_state_changed.emit(character_id, get_character_state(character_id))


func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("nen", "profiles", profiles)
	var error := config.save(save_path)
	if error != OK:
		push_warning("SYSTEM NEN: Could not save local aura progression.")


func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	var saved: Dictionary = config.get_value("nen", "profiles", {})
	for key in saved:
		if saved[key] is Dictionary:
			profiles[str(key)] = saved[key].duplicate(true)
