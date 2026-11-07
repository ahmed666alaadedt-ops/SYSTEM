extends Node

# SYSTEM WORLD
# World Save Manager
# Godot 4.3

const SAVE_PATH := "user://system_world_save.json"
const TEMP_PATH := "user://system_world_save.tmp"
const SAVE_VERSION := 1

var last_save_time := ""
var last_error := ""


func save_world(world_data: Dictionary) -> bool:
	last_error = ""

	var save_data := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"world_data": world_data
	}

	var json_text := JSON.stringify(save_data, "\t")

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)

	if file == null:
		last_error = "تعذر فتح ملف الحفظ المؤقت"
		return false

	file.store_string(json_text)
	file.flush()

	var write_error := file.get_error()
	file.close()

	if write_error != OK:
		last_error = "حدث خطأ أثناء كتابة بيانات الحفظ"
		return false

	var temp_absolute := ProjectSettings.globalize_path(TEMP_PATH)
	var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(save_absolute)

		if remove_error != OK:
			last_error = "تعذر استبدال ملف الحفظ القديم"
			return false

	var rename_error := DirAccess.rename_absolute(
		temp_absolute,
		save_absolute
	)

	if rename_error != OK:
		last_error = "تعذر تثبيت ملف الحفظ الجديد"
		return false

	last_save_time = str(save_data["saved_at"])
	return true


func load_world() -> Dictionary:
	last_error = ""

	if not FileAccess.file_exists(SAVE_PATH):
		last_error = "لا يوجد ملف حفظ سابق"
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		last_error = "تعذر قراءة ملف الحفظ"
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(json_text)

	if parse_error != OK:
		last_error = "ملف الحفظ تالف أو غير صالح"
		return {}

	var loaded_data = json.data

	if typeof(loaded_data) != TYPE_DICTIONARY:
		last_error = "صيغة بيانات العالم غير صحيحة"
		return {}

	var save_data: Dictionary = loaded_data

	if int(save_data.get("save_version", -1)) != SAVE_VERSION:
		last_error = "إصدار ملف الحفظ غير متوافق"
		return {}

	var world_data = save_data.get("world_data", {})

	if typeof(world_data) != TYPE_DICTIONARY:
		last_error = "بيانات العالم غير صالحة"
		return {}

	last_save_time = str(save_data.get("saved_at", ""))

	return world_data


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

	var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	var error := DirAccess.remove_absolute(absolute_path)

	if error != OK:
		last_error = "تعذر حذف ملف الحفظ"
		return false

	last_save_time = ""
	return true
