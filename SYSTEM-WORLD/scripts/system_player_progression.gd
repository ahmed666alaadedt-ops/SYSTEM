
extends Node
class_name SYSTEMPlayerProgression

signal progress_changed(level: int, total_xp: int, xp_in_level: int, xp_to_next: int)
signal level_up(new_level: int)
signal attribute_changed(attribute: String, new_value: int)

const MAX_LEVEL := 100
const SAVE_PATH := "user://system_player_progress.cfg"

const WORLD_FRAGMENT_REQUIREMENTS := {
	"modern": ["mesopotamian_seal", "celestial_compass", "royal_sun_shard"],
	"historical": ["babylon_cuneiform_tablet", "alexandria_pharos_lens", "atlantis_tide_relic"],
	"fantasy": ["dragon_star", "moon_diamond", "ancient_mana_core"]
}

const DEFAULT_ATTRIBUTES := {
	"strength": 1,
	"speed": 1,
	"endurance": 1,
	"intelligence": 1,
	"awareness": 1,
	"discipline": 1
}

const DEFAULT_EQUIPMENT_SLOTS := {"weapon": "", "shield": "", "armor": "", "helmet": "", "outfit": ""}
const EQUIPMENT_SLOTS_BY_ITEM := {
	"training_sword": "weapon", "steel_sword": "weapon", "hunter_spear": "weapon",
	"battle_axe": "weapon", "composite_bow": "weapon", "system_firearm": "weapon",
	"hunter_shield": "shield", "hunter_armor": "armor", "hunter_helmet": "helmet",
	"combat_outfit": "outfit", "casual_outfit": "outfit"
}
const EQUIPMENT_DAMAGE_BONUS := {
	"training_sword": 5.0, "steel_sword": 12.0, "hunter_spear": 10.0,
	"battle_axe": 14.0, "composite_bow": 8.0, "system_firearm": 16.0
}
const EQUIPMENT_DEFENSE_BONUS := {"hunter_shield": 8.0, "hunter_armor": 12.0, "hunter_helmet": 4.0}

var current_level: int = 1
var total_xp: int = 0
var xp_in_level: int = 0
var available_attribute_points: int = 0

var attributes: Dictionary = DEFAULT_ATTRIBUTES.duplicate(true)
var greed_fragments: Array[String] = []
var inventory_items: Dictionary = {}
var world_fragments: Dictionary = {"modern": [], "historical": [], "fantasy": []}
var equipment_slots: Dictionary = DEFAULT_EQUIPMENT_SLOTS.duplicate(true)
var active_elixir_effects: Dictionary = {}
var nen_unlocked := false
var nen_control_rank := 0


func _ready() -> void:
	load_progress()
	_emit_progress()
	set_process(true)


func _process(delta: float) -> void:
	var expired := false
	for effect_id in active_elixir_effects.keys():
		var effect: Dictionary = active_elixir_effects[effect_id]
		var remaining := maxf(0.0, float(effect.get("remaining_seconds", 0.0)) - delta)
		if remaining <= 0.0:
			active_elixir_effects.erase(effect_id)
			expired = true
		else:
			effect["remaining_seconds"] = remaining
			active_elixir_effects[effect_id] = effect
	if expired:
		save_progress()


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


func add_item(item_id: String, amount: int = 1) -> bool:
	var normalized_id := item_id.strip_edges()
	if normalized_id.is_empty() or amount <= 0:
		return false
	inventory_items[normalized_id] = int(inventory_items.get(normalized_id,0)) + amount
	save_progress()
	return true


func get_item_count(item_id: String) -> int:
	return int(inventory_items.get(item_id,0))


func get_item_equipment_slot(item_id: String) -> String:
	return str(EQUIPMENT_SLOTS_BY_ITEM.get(item_id, ""))


func equip_item(item_id: String) -> Dictionary:
	var slot := get_item_equipment_slot(item_id)
	if slot.is_empty():
		return {"success": false, "reason": "ITEM_NOT_EQUIPPABLE"}
	if get_item_count(item_id) <= 0:
		return {"success": false, "reason": "ITEM_NOT_OWNED"}
	equipment_slots[slot] = item_id
	save_progress()
	return {"success": true, "slot": slot, "item_id": item_id}


func unequip_item(slot: String) -> bool:
	if not DEFAULT_EQUIPMENT_SLOTS.has(slot):
		return false
	equipment_slots[slot] = ""
	save_progress()
	return true


func get_equipped_item(slot: String) -> String:
	return str(equipment_slots.get(slot, ""))


func get_equipment_bonuses() -> Dictionary:
	var damage := 0.0
	var defense := 0.0
	for item_id in equipment_slots.values():
		damage += float(EQUIPMENT_DAMAGE_BONUS.get(str(item_id), 0.0))
		defense += float(EQUIPMENT_DEFENSE_BONUS.get(str(item_id), 0.0))
	return {"damage_bonus": damage, "defense_bonus": defense}


func get_combat_damage_bonus() -> float:
	var bonuses := get_equipment_bonuses()
	var result := float(bonuses.get("damage_bonus", 0.0))
	for effect in active_elixir_effects.values():
		result += float(effect.get("damage_bonus", 0.0))
	return result


func get_defense_bonus() -> float:
	var bonuses := get_equipment_bonuses()
	var result := float(bonuses.get("defense_bonus", 0.0))
	for effect in active_elixir_effects.values():
		result += float(effect.get("defense_bonus", 0.0))
	return result


func get_movement_multiplier() -> float:
	var result := 1.0
	for effect in active_elixir_effects.values():
		result *= float(effect.get("movement_multiplier", 1.0))
	return clampf(result, 0.65, 1.6)


func get_attack_cooldown_multiplier() -> float:
	var result := 1.0
	for effect in active_elixir_effects.values():
		result *= float(effect.get("attack_cooldown_multiplier", 1.0))
	return clampf(result, 0.6, 1.2)


func consume_elixir(item_id: String) -> Dictionary:
	if get_item_count(item_id) <= 0:
		return {"success": false, "reason": "ELIXIR_NOT_OWNED"}
	if item_id == "nen_acquisition_elixir":
		if nen_unlocked:
			return {"success": false, "reason": "NEN_ALREADY_UNLOCKED"}
		nen_unlocked = true
		nen_control_rank = 1
	elif item_id == "nen_control_elixir":
		if not nen_unlocked:
			return {"success": false, "reason": "NEN_NOT_UNLOCKED"}
		if nen_control_rank >= 5:
			return {"success": false, "reason": "NEN_CONTROL_MAXED"}
		nen_control_rank += 1
	elif item_id == "healing_elixir":
		var health := get_tree().root.find_child("PlayerCombatHealth", true, false)
		if health == null or not health.has_method("apply_field_healing"):
			return {"success": false, "reason": "HEALTH_SYSTEM_UNAVAILABLE"}
		if not bool(health.call("apply_field_healing", 30.0)):
			return {"success": false, "reason": "HEALING_NOT_NEEDED"}
	else:
		var effect_id := ""
		var effect: Dictionary = {}
		match item_id:
			"strength_elixir":
				effect_id = "strength"
				effect = {"remaining_seconds": 120.0, "damage_bonus": 15.0}
			"speed_elixir":
				effect_id = "speed"
				effect = {"remaining_seconds": 120.0, "movement_multiplier": 1.25}
			"endurance_elixir":
				effect_id = "endurance"
				effect = {"remaining_seconds": 120.0, "defense_bonus": 12.0}
			"energy_elixir":
				effect_id = "energy"
				effect = {"remaining_seconds": 120.0, "attack_cooldown_multiplier": 0.82}
			"rare_legendary_elixir":
				effect_id = "sovereign"
				effect = {"remaining_seconds": 180.0, "damage_bonus": 25.0, "defense_bonus": 15.0, "movement_multiplier": 1.15, "attack_cooldown_multiplier": 0.9}
			_:
				return {"success": false, "reason": "UNKNOWN_ELIXIR"}
		active_elixir_effects[effect_id] = effect
	var remaining := get_item_count(item_id) - 1
	if remaining <= 0:
		inventory_items.erase(item_id)
	else:
		inventory_items[item_id] = remaining
	save_progress()
	return {"success": true, "item_id": item_id, "nen_unlocked": nen_unlocked, "nen_control_rank": nen_control_rank}


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
		"inventory_items": inventory_items.duplicate(true),
		"equipment_slots": equipment_slots.duplicate(true),
		"equipment_bonuses": get_equipment_bonuses(),
		"active_elixir_effects": active_elixir_effects.duplicate(true),
		"nen_unlocked": nen_unlocked,
		"nen_control_rank": nen_control_rank,
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
	config.set_value("inventory", "items", inventory_items.duplicate(true))
	config.set_value("equipment", "slots", equipment_slots.duplicate(true))
	config.set_value("effects", "active_elixirs", active_elixir_effects.duplicate(true))
	config.set_value("nen", "unlocked", nen_unlocked)
	config.set_value("nen", "control_rank", nen_control_rank)

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

	var saved_inventory: Dictionary = config.get_value("inventory", "items", {})
	inventory_items = {}
	for item_id in saved_inventory.keys():
		var item_count := maxi(0,int(saved_inventory[item_id]))
		if item_count > 0:
			inventory_items[str(item_id)] = item_count

	var saved_equipment: Dictionary = config.get_value("equipment", "slots", {})
	equipment_slots = DEFAULT_EQUIPMENT_SLOTS.duplicate(true)
	for slot in DEFAULT_EQUIPMENT_SLOTS.keys():
		var item_id := str(saved_equipment.get(slot, ""))
		if item_id.is_empty() or str(EQUIPMENT_SLOTS_BY_ITEM.get(item_id, "")) == str(slot):
			equipment_slots[slot] = item_id
	var saved_effects: Dictionary = config.get_value("effects", "active_elixirs", {})
	active_elixir_effects = {}
	for effect_id in saved_effects.keys():
		var effect: Dictionary = saved_effects[effect_id].duplicate(true)
		if float(effect.get("remaining_seconds", 0.0)) > 0.0:
			active_elixir_effects[str(effect_id)] = effect
	nen_unlocked = bool(config.get_value("nen", "unlocked", false))
	nen_control_rank = clampi(int(config.get_value("nen", "control_rank", 0)), 0, 5)

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
	if not WORLD_FRAGMENT_REQUIREMENTS.has(key) or normalized_id.is_empty():
		return {"success": false, "reason": "INVALID_WORLD_FRAGMENT"}
	if not WORLD_FRAGMENT_REQUIREMENTS[key].has(normalized_id):
		return {"success": false, "reason": "UNKNOWN_WORLD_FRAGMENT"}
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
		var required_ids: Array = WORLD_FRAGMENT_REQUIREMENTS[world_key]
		var ready := true
		for required_id in required_ids:
			if not collected.has(required_id):
				ready = false
				break
		result[world_key] = {"collected": collected.duplicate(), "count": collected.size(), "required": required_ids.size(), "ready": ready}
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
	equipment_slots = DEFAULT_EQUIPMENT_SLOTS.duplicate(true)
	active_elixir_effects.clear()
	nen_unlocked = false
	nen_control_rank = 0


func _emit_progress() -> void:
	progress_changed.emit(
		current_level,
		total_xp,
		xp_in_level,
		get_xp_to_next_level()
	)
