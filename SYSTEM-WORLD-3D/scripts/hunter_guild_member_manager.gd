extends Node

# SYSTEM WORLD - Hunter Guild Supervisory Staff
# NPCs administer the guild only. They never join missions, exams or combat teams.

signal staff_roster_changed

var staff: Dictionary = {}

func setup(_guild_gate_manager: Node = null) -> void:
	_create_staff_roster()
	print("SYSTEM: Hunter Guild supervisory staff initialized.")

func _create_staff_roster() -> void:
	var roster := [
		["GST-001", "ليث", "موظف التسجيل", "تسجيل حسابات اللاعبين والتحقق من بياناتهم"],
		["GST-002", "سارة", "منسقة المهمات", "إعلان المهمات وتنظيم جداولها"],
		["GST-003", "نور", "محللة البوابات", "تحليل بيانات البوابات وتقدير مستوى الخطر"],
		["GST-004", "كرار", "مشرف الاختبارات", "مراقبة اختبارات الصيادين وتوثيق نتائجها"],
		["GST-005", "مريم", "مسؤولة السجلات", "حفظ التقارير والنتائج والسجلات"],
		["GST-006", "آدم", "موظف المكافآت", "تدقيق المكافآت وإجراءات تسليمها"]
	]
	for item in roster:
		staff[item[0]] = {
			"id": item[0],
			"name": item[1],
			"role": item[2],
			"duties": item[3],
			"staff_type": "npc_supervisor"
		}
	staff_roster_changed.emit()

func get_staff_roster() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for staff_id in staff:
		result.append(staff[staff_id].duplicate(true))
	return result

func get_staff_member(staff_id: String) -> Dictionary:
	if not staff.has(staff_id):
		return {}
	return staff[staff_id].duplicate(true)

func get_supervision_status() -> Dictionary:
	return {
		"staff_count": staff.size(),
		"role": "administration_only",
		"npc_can_join_missions": false,
		"npc_can_join_exams": false,
		"npc_can_join_player_teams": false
	}
