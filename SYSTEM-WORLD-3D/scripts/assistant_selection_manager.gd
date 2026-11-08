
extends Node
class_name AssistantSelectionManager

# SYSTEM WORLD
# Assistant Selection Manager
# Godot 4.3
# One visible assistant at a time.
# Saves the player's choice locally.

signal assistant_changed(assistant_id: String)
signal selection_failed(reason: String)

const SETTINGS_PATH := "user://assistant_preferences.cfg"

const MIYAR_ID := "miyar"
const ADAM_ID := "adam"

var miyar: Node3D
var adam: Node3D

var selected_assistant: String = MIYAR_ID
var assistants_registered: bool = false


func _ready() -> void:
	_load_preferences()


# Register both assistant characters.
func register_assistants(
	miyar_character: Node3D,
	adam_character: Node3D
) -> void:
	miyar = miyar_character
	adam = adam_character

	assistants_registered = true
	_apply_selection()


# Select Miyar or Adam.
func select_assistant(assistant_id: String) -> void:
	if assistant_id != MIYAR_ID and assistant_id != ADAM_ID:
		selection_failed.emit("اختيار المساعد غير صالح.")
		return

	if not assistants_registered:
		selection_failed.emit("الشخصيات لم تجهز بعد.")
		return

	if assistant_id == MIYAR_ID:
		if not is_instance_valid(miyar):
			selection_failed.emit("شخصية ميار غير متاحة حالياً.")
			return

	if assistant_id == ADAM_ID:
		if not is_instance_valid(adam):
			selection_failed.emit("شخصية آدم غير متاحة حالياً.")
			return

	selected_assistant = assistant_id

	_apply_selection()
	_save_preferences()

	assistant_changed.emit(selected_assistant)


# Show exactly one assistant.
func _apply_selection() -> void:
	if is_instance_valid(miyar):
		miyar.visible = selected_assistant == MIYAR_ID

	if is_instance_valid(adam):
		adam.visible = selected_assistant == ADAM_ID


# Return the currently selected assistant.
func get_active_assistant() -> Node3D:
	if selected_assistant == ADAM_ID:
		if is_instance_valid(adam):
			return adam

	if selected_assistant == MIYAR_ID:
		if is_instance_valid(miyar):
			return miyar

	return null


func get_selected_assistant() -> String:
	return selected_assistant


func is_miyar_selected() -> bool:
	return selected_assistant == MIYAR_ID


func is_adam_selected() -> bool:
	return selected_assistant == ADAM_ID


func is_ready_for_interaction() -> bool:
	return (
		assistants_registered
		and is_instance_valid(get_active_assistant())
	)


# Save the selected assistant.
func _save_preferences() -> void:
	var config := ConfigFile.new()

	config.set_value(
		"assistant",
		"selected",
		selected_assistant
	)

	var error := config.save(SETTINGS_PATH)

	if error != OK:
		push_warning(
			"Could not save assistant preference: " + str(error)
		)


# Load the previous selection.
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
		selected_assistant = str(saved_choice)
	else:
		selected_assistant = MIYAR_ID


# Reset to Miyar.
func reset_assistant_choice() -> void:
	selected_assistant = MIYAR_ID

	_apply_selection()
	_save_preferences()

	assistant_changed.emit(selected_assistant)


# Clear references safely if a character is removed.
func unregister_assistants() -> void:
	miyar = null
	adam = null
	assistants_registered = false
