extends Node

# SYSTEM WORLD - Persistent NPC and World Data
# Godot 4.3

const SAVE_PATH := "user://system_world_save.json"
const TEMP_PATH := "user://system_world_save.tmp"
const SAVE_VERSION := 2

var last_save_time := ""
var last_error := ""


func save_world(world_data: Dictionary) -> bool:
	last_error = ""

	var save_data := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"world_data": world_data
	}

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)

	if file == null:
		last_error = "تعذر فتح ملف الحفظ المؤقت"
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.flush()

	var write_error := file.get_error()
	file.close()

	if write_error != OK:
		last_error = "حدث خطأ أثناء كتابة البيانات"
		return false

	var temp_path := ProjectSettings.globalize_path(TEMP_PATH)
	var save_path := ProjectSettings.globalize_path(SAVE_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(save_path)

		if remove_error != OK:
			last_error = "تعذر استبدال ملف الحفظ القديم"
			return false

	var rename_error := DirAccess.rename_absolute(
		temp_path,
		save_path
	)

	if rename_error != OK:
		last_error = "تعذر تثبيت ملف الحفظ الجديد"
		return false

	last_save_time = str(save_data["saved_at"])
	return true


func load_world() -> Dictionary:
	last_error = ""

	if not FileAccess.file_exists(SAVE_PATH):
		last_error = "لا يوجد حفظ سابق"
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		last_error = "تعذرت قراءة البيانات"
		return {}

	var content := file.get_as_text()
	file.close()

	var parser := JSON.new()

	if parser.parse(content) != OK:
		last_error = "ملف الحفظ غير صالح"
		return {}

	if typeof(parser.data) != TYPE_DICTIONARY:
		last_error = "صيغة الحفظ غير صحيحة"
		return {}

	var data: Dictionary = parser.data

	if int(data.get("save_version", -1)) != SAVE_VERSION:
		last_error = "إصدار الحفظ غير متوافق"
		return {}

	var world_data = data.get("world_data", {})

	if typeof(world_data) != TYPE_DICTIONARY:
		last_error = "بيانات العالم غير صالحة"
		return {}

	last_save_time = str(data.get("saved_at", ""))
	return world_data


func save_npc_manager(manager: Node) -> bool:
	if not is_instance_valid(manager):
		last_error = "مدير السكان غير موجود"
		return false

	var snapshot := {
		"residents": [],
		"relationships": {},
		"families": {},
		"resident_profiles": {},
		"next_resident_id": 1
	}

	for resident in manager.residents:
		var npc: Node3D = resident.get("node")

		if not is_instance_valid(npc):
			continue

		snapshot["residents"].append({
			"id": resident.get("id", ""),
			"name": resident.get("name", ""),
			"job": resident.get("job", ""),
			"family": resident.get("family", ""),
			"age": resident.get("age", 18),
			"personality": resident.get("personality", ""),
			"position": _vector_to_array(npc.position),
			"home": _vector_to_array(resident.get("home", Vector3.ZERO)),
			"workplace": _vector_to_array(
				resident.get("workplace", Vector3.ZERO)
			),
			"state": resident.get("state", "rest"),
			"target": _vector_to_array(
				resident.get("target", Vector3.ZERO)
			),
			"energy": resident.get("energy", 100.0),
			"hunger": resident.get("hunger", 0.0),
			"social": resident.get("social", 50.0),
			"money": resident.get("money", 0),
			"activity_timer": resident.get("activity_timer", 0.0),
			"speed": resident.get("speed", 1.0)
		})

	var relationships = manager.relationship_system

	if relationships != null:
		snapshot["relationships"] = relationships.relationships.duplicate(true)
		snapshot["families"] = relationships.families.duplicate(true)
		snapshot["resident_profiles"] = relationships.resident_profiles.duplicate(true)
		snapshot["next_resident_id"] = relationships.next_resident_id

	return save_world({
		"npc_snapshot": snapshot
	})


func restore_npc_manager(manager: Node) -> bool:
	if not is_instance_valid(manager):
		last_error = "مدير السكان غير موجود"
		return false

	var world_data := load_world()

	if world_data.is_empty():
		return false

	var snapshot = world_data.get("npc_snapshot", {})

	if typeof(snapshot) != TYPE_DICTIONARY:
		last_error = "بيانات السكان غير صالحة"
		return false

	var saved_residents: Array = snapshot.get("residents", [])

	for saved in saved_residents:
		if typeof(saved) != TYPE_DICTIONARY:
			continue

		var resident_id := str(saved.get("id", ""))
		var record_index := _find_resident_index(
			manager.residents,
			resident_id
		)

		if record_index < 0:
			continue

		var record: Dictionary = manager.residents[record_index]
		var npc: Node3D = record.get("node")

		if is_instance_valid(npc):
			npc.position = _array_to_vector(
				saved.get("position", [0.0, 0.0, 0.0])
			)

		record["energy"] = float(saved.get("energy", 100.0))
		record["hunger"] = float(saved.get("hunger", 0.0))
		record["social"] = float(saved.get("social", 50.0))
		record["money"] = int(saved.get("money", 0))
		record["state"] = str(saved.get("state", "rest"))
		record["activity_timer"] = float(
			saved.get("activity_timer", 0.0)
		)

		record["target"] = _array_to_vector(
			saved.get("target", [0.0, 0.0, 0.0])
		)

		manager.residents[record_index] = record

	var relationships = manager.relationship_system

	if relationships != null:
		relationships.relationships = snapshot.get(
			"relationships", {}
		).duplicate(true)

		relationships.families = snapshot.get(
			"families", {}
		).duplicate(true)

		relationships.resident_profiles = snapshot.get(
			"resident_profiles", {}
		).duplicate(true)

		relationships.next_resident_id = int(
			snapshot.get("next_resident_id", 1)
		)

	return true


func _find_resident_index(
	residents: Array,
	resident_id: String
) -> int:
	for index in range(residents.size()):
		if str(residents[index].get("id", "")) == resident_id:
			return index

	return -1


func _vector_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Array) -> Vector3:
	if value.size() < 3:
		return Vector3.ZERO

	return Vector3(
		float(value[0]),
		float(value[1]),
		float(value[2])
	)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func get_last_save_time() -> String:
	return last_save_time


func get_last_error() -> String:
	return last_error


func delete_save() -> bool:
	last_error = ""

	if not FileAccess.file_exists(SAVE_PATH):
		return true

	var path := ProjectSettings.globalize_path(SAVE_PATH)
	var error := DirAccess.remove_absolute(path)

	if error != OK:
		last_error = "تعذر حذف ملف الحفظ"
		return false

	last_save_time = ""
	return true
