
extends Node
class_name SYSTEMPlayerProgression

signal progress_changed(level: int, total_xp: int, xp_in_level: int, xp_to_next: int)
signal level_up(new_level: int)
signal attribute_changed(attribute: String, new_value: int)

const MAX_LEVEL := 100
const SAVE_PATH := "user://system_player_progress.cfg"

const DEFAULT_ATTRIBUTES := {
	"strength": 1,
	"speed": 1,
	"endurance": 1,
	"intelligence": 1,
	"awareness": 1,
	"discipline": 1
}

var current_level: int = 1
var total_xp: int = 0
var xp_in_level: int = 0
var available_attribute_points: int = 0

var attributes: Dictionary = DEFAULT_ATTRIBUTES.duplicate(true)


func _ready() -> void:
	load_progress()
	_emit_progress()


func get_xp_required_for_next_level() -> int:
	if current_level >= MAX_LEVEL:
		return 0

	return 100 + (current_level * current_level * 4)


func get_xp_to_next_level() -> int:
	if current_level >= MAX_LEVEL:
		return 0

	return maxi(
		0,
		get_xp_required_for_next_level() - xp_in_level
	)


func add_experience(amount: int, reason: String = "") -> Dictionary:
	if amount <= 0:
		return {
			"success": false,
			"reason": "INVALID_XP_AMOUNT"
		}

	total_xp += amount

	if current_level >= MAX_LEVEL:
		xp_in_level = 0
		save_progress()
		_emit_progress()

		return {
			"success": true,
			"level": current_level,
			"total_xp": total_xp,
			"max_level_reached": true,
			"reason": reason
		}

	xp_in_level += amount

	var levels_gained := 0

	while current_level < MAX_LEVEL:
		var required_xp := get_xp_required_for_next_level()

		if xp_in_level < required_xp:
			break

		xp_in_level -= required_xp
		current_level += 1
		available_attribute_points += 1
		levels_gained += 1

		level_up.emit(current_level)

	if current_level >= MAX_LEVEL:
		xp_in_level = 0

	save_progress()
	_emit_progress()

	return {
		"success": true,
		"level": current_level,
		"total_xp": total_xp,
		"levels_gained": levels_gained,
		"attribute_points": available_attribute_points,
		"reason": reason
	}


func spend_attribute_point(attribute: String) -> bool:
	if available_attribute_points <= 0:
		return false

	if not attributes.has(attribute):
		return false

	attributes[attribute] = int(attributes[attribute]) + 1
	available_attribute_points -= 1

	attribute_changed.emit(
		attribute,
		int(attributes[attribute])
	)

	save_progress()
	return true


func get_attribute(attribute: String) -> int:
	if not attributes.has(attribute):
		return 0

	return int(attributes[attribute])


func get_progress_data() -> Dictionary:
	return {
		"level": current_level,
		"total_xp": total_xp,
		"xp_in_level": xp_in_level,
		"xp_to_next": get_xp_to_next_level(),
		"max_level": MAX_LEVEL,
		"attribute_points": available_attribute_points,
		"attributes": attributes.duplicate(true)
	}


func save_progress() -> void:
	var config := ConfigFile.new()

	config.set_value("progress", "level", current_level)
	config.set_value("progress", "total_xp", total_xp)
	config.set_value("progress", "xp_in_level", xp_in_level)
	config.set_value(
		"progress",
		"attribute_points",
		available_attribute_points
	)

	config.set_value(
		"player",
		"attributes",
		attributes.duplicate(true)
	)

	var error := config.save(SAVE_PATH)

	if error != OK:
		push_warning("SYSTEM: Could not save player progress.")


func load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error != OK:
		_reset_progress()
		return

	current_level = clampi(
		int(config.get_value("progress", "level", 1)),
		1,
		MAX_LEVEL
	)

	total_xp = maxi(
		0,
		int(config.get_value("progress", "total_xp", 0))
	)

	xp_in_level = maxi(
		0,
		int(config.get_value("progress", "xp_in_level", 0))
	)

	available_attribute_points = maxi(
		0,
		int(config.get_value("progress", "attribute_points", 0))
	)

	var saved_attributes: Dictionary = config.get_value(
		"player",
		"attributes",
		DEFAULT_ATTRIBUTES.duplicate(true)
	)

	attributes = DEFAULT_ATTRIBUTES.duplicate(true)

	for key in DEFAULT_ATTRIBUTES.keys():
		attributes[key] = maxi(
			1,
			int(saved_attributes.get(key, 1))
		)

	if current_level >= MAX_LEVEL:
		xp_in_level = 0
	else:
		xp_in_level = mini(
			xp_in_level,
			get_xp_required_for_next_level() - 1
		)


func _reset_progress() -> void:
	current_level = 1
	total_xp = 0
	xp_in_level = 0
	available_attribute_points = 0
	attributes = DEFAULT_ATTRIBUTES.duplicate(true)


func _emit_progress() -> void:
	progress_changed.emit(
		current_level,
		total_xp,
		xp_in_level,
		get_xp_to_next_level()
	)
