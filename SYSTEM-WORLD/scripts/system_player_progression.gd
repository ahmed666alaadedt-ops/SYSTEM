
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
var greed_fragments: Array[String] = []
var world_fragments: Dictionary = {"modern": [], "historical": [], "fantasy": []}


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
		"attributes": attributes.duplicate(true),
		"greed_fragments": greed_fragments.duplicate(),
		"greed_fragments_count": greed_fragments.size(),
		"greed_island_seal_ready": bool(get_world_fragment_data().get("all_world_keys_ready", false)),
		"world_keys": get_world_fragment_data()
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
	config.set_value(
		"greed_island",
		"fragments",
		greed_fragments.duplicate()
	)
	config.set_value("world_keys", "fragments", world_fragments.duplicate(true))

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

	var saved_fragments: Array = config.get_value("greed_island", "fragments", [])
	greed_fragments.clear()
	for fragment_id in saved_fragments:
		var normalized_id := str(fragment_id)
		if not normalized_id.is_empty() and not greed_fragments.has(normalized_id):
			greed_fragments.append(normalized_id)

	var saved_world_fragments: Dictionary = config.get_value("world_keys", "fragments", {})
	world_fragments = {"modern": [], "historical": [], "fantasy": []}
	for world_key in world_fragments.keys():
		var entries: Array = saved_world_fragments.get(world_key, [])
		for fragment_id in entries:
			var normalized_id := str(fragment_id).strip_edges()
			if not normalized_id.is_empty() and not world_fragments[world_key].has(normalized_id):
				world_fragments[world_key].append(normalized_id)
	for legacy_id in greed_fragments:
		if not world_fragments["modern"].has(legacy_id):
			world_fragments["modern"].append(legacy_id)

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


func collect_world_fragment(world_key: String, fragment_id: String) -> Dictionary:
	var key := world_key.strip_edges().to_lower()
	var normalized_id := fragment_id.strip_edges()
	if not world_fragments.has(key) or normalized_id.is_empty():
		return {"success": false, "reason": "INVALID_WORLD_FRAGMENT"}
	var collected: Array = world_fragments[key]
	if collected.has(normalized_id):
		return {"success": false, "reason": "ALREADY_COLLECTED", "count": collected.size()}
	collected.append(normalized_id)
	world_fragments[key] = collected
	if key == "modern" and not greed_fragments.has(normalized_id):
		greed_fragments.append(normalized_id)
	save_progress()
	return {"success": true, "world": key, "fragment_id": normalized_id, "count": collected.size(), "required": 3, "world_key_ready": collected.size() >= 3}


func get_world_fragment_data() -> Dictionary:
	var result := {}
	var all_ready := true
	for world_key in ["modern", "historical", "fantasy"]:
		var collected: Array = world_fragments.get(world_key, [])
		var ready := collected.size() >= 3
		result[world_key] = {"collected": collected.duplicate(), "count": collected.size(), "required": 3, "ready": ready}
		all_ready = all_ready and ready
	result["all_world_keys_ready"] = all_ready
	return result


func collect_greed_fragment(fragment_id: String) -> Dictionary:
	return collect_world_fragment("modern", fragment_id)


func _legacy_collect_greed_fragment_unused(fragment_id: String) -> Dictionary:
	var normalized_id := fragment_id.strip_edges()
	if normalized_id.is_empty():
		return {"success": false, "reason": "INVALID_FRAGMENT_ID"}
	if greed_fragments.has(normalized_id):
		return {"success": false, "reason": "ALREADY_COLLECTED", "count": greed_fragments.size()}
	greed_fragments.append(normalized_id)
	save_progress()
	return {
		"success": true,
		"fragment_id": normalized_id,
		"count": greed_fragments.size(),
		"required": 3,
		"island_seal_ready": greed_fragments.size() >= 3
	}


func has_greed_fragment(fragment_id: String) -> bool:
	return greed_fragments.has(fragment_id)


func get_greed_fragment_data() -> Dictionary:
	return {
		"collected": greed_fragments.duplicate(),
		"count": greed_fragments.size(),
		"required": 3,
		"island_seal_ready": greed_fragments.size() >= 3
	}


func _reset_progress() -> void:
	greed_fragments.clear()
	world_fragments = {"modern": [], "historical": [], "fantasy": []}
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
