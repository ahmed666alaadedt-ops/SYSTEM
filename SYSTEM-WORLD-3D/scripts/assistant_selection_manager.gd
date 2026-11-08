extends Node

class_name AssistantSelectionManager

# SYSTEM WORLD
# Assistant Selection Manager
# Godot 4.3

signal assistant_changed(assistant_id: String)
signal selection_failed(reason: String)

const SETTINGS_PATH := "user://assistant_preferences.cfg"

const MIYAR_ID := "miyar"
const ADAM_ID := "adam"

var miyar: Node3D
var adam: Node3D

var selected_assistant := MIYAR_ID


func _ready() -> void:
	_load_preferences()


# تسجيل الشخصيتين
func register_assistants(
	miyar_character: Node3D,
	adam_character: Node3D
) -> void:

	miyar = miyar_character
	adam = adam_character

	_apply_selection()


# اختيار المساعد
func select_assistant(assistant_id: String) -> void:

	if assistant_id != MIYAR_ID and assistant_id != ADAM_ID:
		selection_failed.emit("اختيار المساعد غير صالح.")
		return

	if assistant_id == ADAM_ID and not is_instance_valid(adam):
		selection_failed.emit("شخصية آدم غير متاحة حالياً.")
		return

	if assistant_id == MIYAR_ID and not is_instance_valid(miyar):
		selection_failed.emit("شخصية ميار غير متاحة حالياً.")
		return

	selected_assistant = assistant_id

	_apply_selection()
	_save_preferences()

	assistant_changed.emit(selected_assistant)


# تطبيق الاختيار وإظهار شخصية واحدة
func _apply_selection() -> void:

	if is_instance_valid(miyar):
		miyar.visible = selected_assistant == MIYAR_ID

	if is_instance_valid(adam):
		adam.visible = selected_assistant == ADAM_ID


# الحصول على المساعد النشط
func get_active_assistant() -> Node3D:

	if selected_assistant == ADAM_ID:
		if is_instance_valid(adam):
			return adam

	if is_instance_valid(miyar):
		return miyar

	return null


# معرفة المساعد المختار
func get_selected_assistant() -> String:
	return selected_assistant


# حفظ الاختيار محلياً
func _save_preferences() -> void:

	var config := ConfigFile.new()

	config.set_value(
		"assistant",
		"selected",
		selected_assistant
	)

	config.save(SETTINGS_PATH)


# تحميل الاختيار السابق
func _load_preferences() -> void:

	var config := ConfigFile.new()

	var error := config.load(SETTINGS_PATH)

	if error != OK:
		selected_assistant = MIYAR_ID
		return

	var saved_choice = config.get_value(
		"assistant",
		"selected",
		MIYAR_ID
	)

	if saved_choice == MIYAR_ID or saved_choice == ADAM_ID:
		selected_assistant = saved_choice
	else:
		selected_assistant = MIYAR_ID


# إعادة الاختيار الافتراضي
func reset_assistant_choice() -> void:

	selected_assistant = MIYAR_ID

	_apply_selection()
	_save_preferences()

	assistant_changed.emit(selected_assistant)
