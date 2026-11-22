
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
const MAX_EQUIPMENT_UPGRADE_LEVEL := 10
const MAX_EQUIPMENT_DURABILITY := 100.0
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

const CRAFTING_RECIPES := {
	"training_sword": {"name": "صناعة سيف تدريبي", "ingredients": {"iron_ingot": 1, "wood_plank": 2}, "output": "training_sword", "required_level": 1},
	"steel_sword": {"name": "صناعة سيف فولاذي", "ingredients": {"iron_ingot": 3, "wood_plank": 2}, "output": "steel_sword", "required_level": 5},
	"hunter_spear": {"name": "صناعة رمح صياد", "ingredients": {"iron_ingot": 2, "wood_plank": 3}, "output": "hunter_spear", "required_level": 5},
	"battle_axe": {"name": "صناعة فأس قتالي", "ingredients": {"iron_ingot": 4, "wood_plank": 2}, "output": "battle_axe", "required_level": 10},
	"composite_bow": {"name": "صناعة قوس مركب", "ingredients": {"wood_plank": 4, "leather_roll": 2}, "output": "composite_bow", "required_level": 8},
	"hunter_shield": {"name": "صناعة درع يدوي", "ingredients": {"iron_ingot": 3, "leather_roll": 1}, "output": "hunter_shield", "required_level": 8},
	"hunter_armor": {"name": "صناعة درع صياد", "ingredients": {"iron_ingot": 5, "leather_roll": 4}, "output": "hunter_armor", "required_level": 10},
	"hunter_helmet": {"name": "صناعة خوذة صياد", "ingredients": {"iron_ingot": 2, "leather_roll": 1}, "output": "hunter_helmet", "required_level": 8},
	"combat_outfit": {"name": "خياطة زي قتالي", "ingredients": {"leather_roll": 4, "energy_crystal": 1}, "output": "combat_outfit", "required_level": 12},
	"healing_elixir": {"name": "تحضير إكسير الشفاء", "ingredients": {"medicinal_herb": 2, "crystal_dust": 1}, "output": "healing_elixir", "required_level": 1},
	"repair_kit": {"name": "صناعة عدة إصلاح", "ingredients": {"iron_ingot": 2, "crystal_dust": 1}, "output": "repair_kit", "required_level": 1},
	"strength_elixir": {"name": "تحضير إكسير القوة", "ingredients": {"medicinal_herb": 2, "monster_core": 1}, "output": "strength_elixir", "required_level": 5},
	"speed_elixir": {"name": "تحضير إكسير السرعة", "ingredients": {"medicinal_herb": 2, "energy_crystal": 1}, "output": "speed_elixir", "required_level": 5},
	"endurance_elixir": {"name": "تحضير إكسير التحمل", "ingredients": {"medicinal_herb": 2, "leather_roll": 1}, "output": "endurance_elixir", "required_level": 5},
	"energy_elixir": {"name": "تحضير إكسير الطاقة", "ingredients": {"crystal_dust": 2, "energy_crystal": 1}, "output": "energy_elixir", "required_level": 8},
	"nen_awakening_elixir": {"name": "تحضير إكسير إيقاظ النِن", "ingredients": {"monster_core": 2, "nen_fragment": 1}, "output": "nen_awakening_elixir", "required_level": 15},
	"nen_control_elixir": {"name": "تحضير إكسير التحكم بالنِن", "ingredients": {"nen_fragment": 2, "energy_crystal": 1}, "output": "nen_control_elixir", "required_level": 20, "requires_nen": true},
	"rare_legendary_elixir": {"name": "تحضير الإكسير النادر/الأسطوري", "ingredients": {"rare_core": 3, "nen_fragment": 5, "energy_crystal": 3}, "output": "rare_legendary_elixir", "required_level": 80, "requires_nen": true, "required_nen_rank": 5}
}


var current_level: int = 1
var total_xp: int = 0
var xp_in_level: int = 0
var available_attribute_points: int = 0

var attributes: Dictionary = DEFAULT_ATTRIBUTES.duplicate(true)
var greed_fragments: Array[String] = []
var inventory_items: Dictionary = {}
var world_fragments: Dictionary = {"modern": [], "historical": [], "fantasy": []}
var equipment_slots: Dictionary = DEFAULT_EQUIPMENT_SLOTS.duplicate(true)
var equipment_upgrade_levels: Dictionary = {}
var equipment_durability: Dictionary = {}
var active_elixir_effects: Dictionary = {}
var nen_unlocked := false
var nen_control_rank := 0
var nen_burst_cooldown_remaining := 0.0
var nen_button_refresh_clock := 0.0
var nen_burst_button: Button

# Hunter grades are earned from verified guild work and demonstrated Nen practice.
const HUNTER_RANK_ORDER := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"]
const HUNTER_RANK_MISSION_POINTS := {"E": 100, "D": 250, "C": 500, "B": 850, "A": 1500, "S": 2500, "SS": 5000}
var verified_hunter_mission_points := 0
var verified_hunter_mission_count := 0
var verified_hunter_mission_ids: Array[String] = []
var nen_skill_use_count := 0
var nen_skill_ids: Array[String] = []
var hunter_sss_board_approved := false


func _ready() -> void:
	load_progress()
	_emit_progress()
	set_process(true)
	_create_nen_burst_button()


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
	if nen_burst_cooldown_remaining > 0.0:
		nen_burst_cooldown_remaining = maxf(0.0, nen_burst_cooldown_remaining - delta)
		nen_button_refresh_clock -= delta
		if nen_button_refresh_clock <= 0.0:
			nen_button_refresh_clock = 1.0
			_refresh_nen_burst_button()
		if nen_burst_cooldown_remaining <= 0.0:
			save_progress()
			_refresh_nen_burst_button()
	if expired:
		save_progress()


func _create_nen_burst_button() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "NenAbilityHUD"
	canvas.layer = 30
	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud)
	nen_burst_button = Button.new()
	nen_burst_button.name = "NenBurstButton"
	nen_burst_button.anchor_left = 0.83
	nen_burst_button.anchor_top = 0.82
	nen_burst_button.anchor_right = 0.98
	nen_burst_button.anchor_bottom = 0.96
	nen_burst_button.offset_left = 0.0
	nen_burst_button.offset_top = 0.0
	nen_burst_button.offset_right = 0.0
	nen_burst_button.offset_bottom = 0.0
	nen_burst_button.text = "نِن"
	nen_burst_button.pressed.connect(activate_nen_burst)
	hud.add_child(nen_burst_button)
	add_child(canvas)
	_refresh_nen_burst_button()


func _refresh_nen_burst_button() -> void:
	if not is_instance_valid(nen_burst_button):
		return
	nen_burst_button.visible = nen_unlocked
	if not nen_unlocked:
		return
	if nen_control_rank < 4:
		nen_burst_button.text = "النِن — رتبة %d/4" % nen_control_rank
		nen_burst_button.disabled = true
		return
	var active_effect: Dictionary = active_elixir_effects.get("nen_burst", {})
	var active_remaining := float(active_effect.get("remaining_seconds", 0.0))
	if active_remaining > 0.0:
		nen_burst_button.text = "النِن فعال %dث" % int(ceil(active_remaining))
		nen_burst_button.disabled = true
	elif nen_burst_cooldown_remaining > 0.0:
		nen_burst_button.text = "النِن %dث" % int(ceil(nen_burst_cooldown_remaining))
		nen_burst_button.disabled = true
	else:
		nen_burst_button.text = "تفعيل النِن"
		nen_burst_button.disabled = false


func activate_nen_burst() -> Dictionary:
	if not nen_unlocked or nen_control_rank < 4:
		return {"success": false, "reason": "NEN_RANK_FOUR_REQUIRED"}
	if nen_burst_cooldown_remaining > 0.0:
		return {"success": false, "reason": "NEN_BURST_ON_COOLDOWN"}
	active_elixir_effects["nen_burst"] = {"remaining_seconds": 20.0, "damage_bonus": 30.0, "defense_bonus": 20.0, "movement_multiplier": 1.1, "attack_cooldown_multiplier": 0.85}
	nen_burst_cooldown_remaining = 60.0
	nen_button_refresh_clock = 0.0
	save_progress()
	_refresh_nen_burst_button()
	return {"success": true, "duration_seconds": 20, "cooldown_seconds": 60}


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


func record_verified_hunter_mission(mission_id: String, mission_points: int, used_nen: bool = false, ability_id: String = "") -> Dictionary:
	var normalized_id := mission_id.strip_edges()
	if normalized_id.is_empty() or mission_points <= 0:
		return {"success": false, "reason": "INVALID_VERIFIED_MISSION"}
	if verified_hunter_mission_ids.has(normalized_id):
		return {"success": false, "reason": "MISSION_ALREADY_COUNTED"}
	verified_hunter_mission_ids.append(normalized_id)
	verified_hunter_mission_count += 1
	verified_hunter_mission_points += mission_points
	if used_nen and not ability_id.strip_edges().is_empty():
		record_nen_skill_use(ability_id)
	save_progress()
	return {"success": true, "rank": get_hunter_rank(), "mission_points": verified_hunter_mission_points, "mission_count": verified_hunter_mission_count}


func record_nen_skill_use(ability_id: String) -> Dictionary:
	var normalized_id := ability_id.strip_edges().to_lower()
	if not nen_unlocked or nen_control_rank <= 0:
		return {"success": false, "reason": "NEN_NOT_READY"}
	if normalized_id.is_empty():
		return {"success": false, "reason": "ABILITY_ID_REQUIRED"}
	nen_skill_use_count += 1
	if not nen_skill_ids.has(normalized_id):
		nen_skill_ids.append(normalized_id)
	save_progress()
	return {"success": true, "uses": nen_skill_use_count, "distinct_abilities": nen_skill_ids.size(), "rank": get_hunter_rank()}


func get_hunter_rank() -> String:
	var rank := "F"
	for candidate in ["E", "D", "C", "B"]:
		if verified_hunter_mission_points >= int(HUNTER_RANK_MISSION_POINTS[candidate]):
			rank = candidate
	if verified_hunter_mission_points >= 1500 and nen_unlocked and nen_control_rank >= 2 and nen_skill_use_count >= 10:
		rank = "A"
	if verified_hunter_mission_points >= 2500 and nen_unlocked and nen_control_rank >= 4 and nen_skill_use_count >= 50 and nen_skill_ids.size() >= 2:
		rank = "S"
	if verified_hunter_mission_points >= 5000 and nen_unlocked and nen_control_rank >= 5 and nen_skill_use_count >= 150 and nen_skill_ids.size() >= 3:
		rank = "SS"
	if hunter_sss_board_approved and rank == "SS":
		rank = "SSS"
	return rank


func get_hunter_rank_progress() -> Dictionary:
	return {
		"rank": get_hunter_rank(),
		"rank_order": HUNTER_RANK_ORDER.duplicate(),
		"verified_mission_points": verified_hunter_mission_points,
		"verified_mission_count": verified_hunter_mission_count,
		"nen_unlocked": nen_unlocked,
		"nen_control_rank": nen_control_rank,
		"nen_skill_uses": nen_skill_use_count,
		"distinct_nen_abilities": nen_skill_ids.size(),
		"sss_board_approved": hunter_sss_board_approved
	}


func approve_sss_by_exam_board(approval_id: String) -> bool:
	if approval_id.strip_edges().is_empty() or get_hunter_rank() != "SS":
		return false
	hunter_sss_board_approved = true
	save_progress()
	return true


func add_item(item_id: String, amount: int = 1) -> bool:
	var normalized_id := item_id.strip_edges()
	if normalized_id.is_empty() or amount <= 0:
		return false
	if get_item_count(normalized_id) <= 0 and EQUIPMENT_SLOTS_BY_ITEM.has(normalized_id):
		equipment_durability[normalized_id] = MAX_EQUIPMENT_DURABILITY
		equipment_upgrade_levels[normalized_id] = 0
	inventory_items[normalized_id] = int(inventory_items.get(normalized_id,0)) + amount
	save_progress()
	return true


func get_item_count(item_id: String) -> int:
	return int(inventory_items.get(item_id,0))


func get_crafting_recipe_list() -> Dictionary:
	return CRAFTING_RECIPES.duplicate(true)


func craft_recipe(recipe_id: String) -> Dictionary:
	if not CRAFTING_RECIPES.has(recipe_id):
		return {"success": false, "reason": "UNKNOWN_RECIPE"}
	var recipe: Dictionary = CRAFTING_RECIPES[recipe_id]
	var required_level := int(recipe.get("required_level", 1))
	if current_level < required_level:
		return {"success": false, "reason": "LEVEL_REQUIREMENT", "required_level": required_level}
	if bool(recipe.get("requires_nen", false)) and not nen_unlocked:
		return {"success": false, "reason": "NEN_REQUIRED"}
	var required_nen_rank := int(recipe.get("required_nen_rank", 0))
	if nen_control_rank < required_nen_rank:
		return {"success": false, "reason": "NEN_CONTROL_RANK_REQUIRED", "required_nen_rank": required_nen_rank}
	var ingredients: Dictionary = recipe.get("ingredients", {})
	for ingredient_id in ingredients.keys():
		var required_count := int(ingredients[ingredient_id])
		if get_item_count(str(ingredient_id)) < required_count:
			return {"success": false, "reason": "MISSING_INGREDIENTS", "ingredient": str(ingredient_id), "required": required_count}
	for ingredient_id in ingredients.keys():
		var remaining := get_item_count(str(ingredient_id)) - int(ingredients[ingredient_id])
		if remaining <= 0:
			inventory_items.erase(str(ingredient_id))
		else:
			inventory_items[str(ingredient_id)] = remaining
	var output_id := str(recipe.get("output", ""))
	if output_id.is_empty():
		return {"success": false, "reason": "INVALID_RECIPE_OUTPUT"}
	add_item(output_id, 1)
	save_progress()
	return {"success": true, "recipe_id": recipe_id, "output": output_id, "output_count": 1}


func get_item_equipment_slot(item_id: String) -> String:
	return str(EQUIPMENT_SLOTS_BY_ITEM.get(item_id, ""))


func equip_item(item_id: String) -> Dictionary:
	var slot := get_item_equipment_slot(item_id)
	if slot.is_empty():
		return {"success": false, "reason": "ITEM_NOT_EQUIPPABLE"}
	if get_item_count(item_id) <= 0:
		return {"success": false, "reason": "ITEM_NOT_OWNED"}
	equipment_slots[slot] = item_id
	if not equipment_durability.has(item_id):
		equipment_durability[item_id] = MAX_EQUIPMENT_DURABILITY
	if not equipment_upgrade_levels.has(item_id):
		equipment_upgrade_levels[item_id] = 0
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


func is_item_equipped(item_id: String) -> bool:
	for equipped_item in equipment_slots.values():
		if str(equipped_item) == item_id:
			return true
	return false


func get_equipment_bonuses() -> Dictionary:
	var damage := 0.0
	var defense := 0.0
	var movement := 1.0
	var combat_system := get_tree().root.find_child("ModernWorldCombatSystem", true, false)
	var is_blocking := combat_system != null and bool(combat_system.get("is_blocking"))
	for slot in equipment_slots.keys():
		var item_id := str(equipment_slots[slot])
		if item_id.is_empty() or get_item_durability(item_id) <= 0.0:
			continue
		if slot == "shield" and not is_blocking:
			continue
		var upgrade_level := get_item_upgrade_level(item_id)
		damage += float(EQUIPMENT_DAMAGE_BONUS.get(item_id, 0.0)) + (float(upgrade_level) * 2.0 if slot == "weapon" else 0.0)
		defense += float(EQUIPMENT_DEFENSE_BONUS.get(item_id, 0.0)) + (float(upgrade_level) * 1.5 if slot in ["shield", "armor", "helmet"] else 0.0)
		if slot == "outfit":
			movement *= 1.0 + float(upgrade_level) * 0.01
	return {"damage_bonus": damage, "defense_bonus": defense, "movement_multiplier": movement}


func get_item_upgrade_level(item_id: String) -> int:
	return clampi(int(equipment_upgrade_levels.get(item_id, 0)), 0, MAX_EQUIPMENT_UPGRADE_LEVEL)


func get_item_durability(item_id: String) -> float:
	if item_id.is_empty():
		return 0.0
	return clampf(float(equipment_durability.get(item_id, MAX_EQUIPMENT_DURABILITY)), 0.0, MAX_EQUIPMENT_DURABILITY)


func consume_equipment_durability(slot: String, amount: float) -> bool:
	if not DEFAULT_EQUIPMENT_SLOTS.has(slot) or amount <= 0.0:
		return false
	var item_id := str(equipment_slots.get(slot, ""))
	if item_id.is_empty():
		return false
	var old_value := get_item_durability(item_id)
	var new_value := maxf(0.0, old_value - amount)
	equipment_durability[item_id] = new_value
	if new_value <= 0.0 or int(old_value / 10.0) != int(new_value / 10.0):
		save_progress()
	return true


func repair_item(item_id: String) -> Dictionary:
	if get_item_equipment_slot(item_id).is_empty() or get_item_count(item_id) <= 0:
		return {"success": false, "reason": "ITEM_NOT_OWNED"}
	if get_item_durability(item_id) >= MAX_EQUIPMENT_DURABILITY:
		return {"success": false, "reason": "ITEM_ALREADY_REPAIRED"}
	if get_item_count("repair_kit") <= 0:
		return {"success": false, "reason": "REPAIR_KIT_REQUIRED"}
	var remaining := get_item_count("repair_kit") - 1
	if remaining <= 0:
		inventory_items.erase("repair_kit")
	else:
		inventory_items["repair_kit"] = remaining
	equipment_durability[item_id] = MAX_EQUIPMENT_DURABILITY
	save_progress()
	return {"success": true, "item_id": item_id, "durability": MAX_EQUIPMENT_DURABILITY}


func upgrade_item(item_id: String) -> Dictionary:
	if get_item_equipment_slot(item_id).is_empty() or get_item_count(item_id) <= 0:
		return {"success": false, "reason": "ITEM_NOT_OWNED"}
	var current_upgrade := get_item_upgrade_level(item_id)
	var next_upgrade := current_upgrade + 1
	if next_upgrade > MAX_EQUIPMENT_UPGRADE_LEVEL:
		return {"success": false, "reason": "UPGRADE_MAXED"}
	if current_level < next_upgrade:
		return {"success": false, "reason": "LEVEL_REQUIREMENT", "required_level": next_upgrade}
	var iron_cost := 2 + current_upgrade
	var rare_core_cost := 1 if next_upgrade >= 6 else 0
	var nen_fragment_cost := 1 if next_upgrade >= 8 else 0
	if next_upgrade >= 8 and (not nen_unlocked or nen_control_rank < 3):
		return {"success": false, "reason": "NEN_CONTROL_RANK_REQUIRED"}
	if get_item_count("iron_ingot") < iron_cost or get_item_count("rare_core") < rare_core_cost or get_item_count("nen_fragment") < nen_fragment_cost:
		return {"success": false, "reason": "MISSING_UPGRADE_MATERIALS"}
	for material_id in ["iron_ingot", "rare_core", "nen_fragment"]:
		var cost := iron_cost if material_id == "iron_ingot" else (rare_core_cost if material_id == "rare_core" else nen_fragment_cost)
		if cost <= 0:
			continue
		var remaining := get_item_count(material_id) - cost
		if remaining <= 0:
			inventory_items.erase(material_id)
		else:
			inventory_items[material_id] = remaining
	equipment_upgrade_levels[item_id] = next_upgrade
	if not equipment_durability.has(item_id):
		equipment_durability[item_id] = MAX_EQUIPMENT_DURABILITY
	save_progress()
	return {"success": true, "item_id": item_id, "upgrade_level": next_upgrade}


func get_combat_damage_bonus() -> float:
	var bonuses := get_equipment_bonuses()
	var result := float(bonuses.get("damage_bonus", 0.0))
	for effect in active_elixir_effects.values():
		result += float(effect.get("damage_bonus", 0.0))
	if nen_unlocked and nen_control_rank >= 3:
		result += float(nen_control_rank - 2) * 2.0
	return result


func get_defense_bonus() -> float:
	var bonuses := get_equipment_bonuses()
	var result := float(bonuses.get("defense_bonus", 0.0))
	for effect in active_elixir_effects.values():
		result += float(effect.get("defense_bonus", 0.0))
	if nen_unlocked:
		result += float(nen_control_rank) * 1.5
	return result


func get_movement_multiplier() -> float:
	var result := 1.0
	var equipment_bonus := get_equipment_bonuses()
	result *= float(equipment_bonus.get("movement_multiplier", 1.0))
	if nen_unlocked:
		result *= 1.0 + float(nen_control_rank) * 0.005
	for effect in active_elixir_effects.values():
		result *= float(effect.get("movement_multiplier", 1.0))
	return clampf(result, 0.65, 1.6)


func get_attack_cooldown_multiplier() -> float:
	var result := 1.0
	for effect in active_elixir_effects.values():
		result *= float(effect.get("attack_cooldown_multiplier", 1.0))
	if nen_unlocked:
		result *= 1.0 - float(nen_control_rank) * 0.01
	return clampf(result, 0.6, 1.2)


func consume_elixir(item_id: String) -> Dictionary:
	if get_item_count(item_id) <= 0:
		return {"success": false, "reason": "ELIXIR_NOT_OWNED"}
	if item_id in ["nen_awakening_elixir", "nen_acquisition_elixir"]:
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
	_refresh_nen_burst_button()
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
		"equipment_upgrade_levels": equipment_upgrade_levels.duplicate(true),
		"equipment_durability": equipment_durability.duplicate(true),
		"equipment_bonuses": get_equipment_bonuses(),
		"active_elixir_effects": active_elixir_effects.duplicate(true),
		"nen_unlocked": nen_unlocked,
		"nen_control_rank": nen_control_rank,
		"nen_burst_cooldown_remaining": nen_burst_cooldown_remaining,
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
	config.set_value("equipment", "upgrade_levels", equipment_upgrade_levels.duplicate(true))
	config.set_value("equipment", "durability", equipment_durability.duplicate(true))
	config.set_value("effects", "active_elixirs", active_elixir_effects.duplicate(true))
	config.set_value("nen", "unlocked", nen_unlocked)
	config.set_value("nen", "control_rank", nen_control_rank)
	config.set_value("nen", "burst_cooldown_remaining", nen_burst_cooldown_remaining)
	config.set_value("hunter_rank", "verified_mission_points", verified_hunter_mission_points)
	config.set_value("hunter_rank", "verified_mission_count", verified_hunter_mission_count)
	config.set_value("hunter_rank", "verified_mission_ids", verified_hunter_mission_ids)
	config.set_value("hunter_rank", "nen_skill_use_count", nen_skill_use_count)
	config.set_value("hunter_rank", "nen_skill_ids", nen_skill_ids)
	config.set_value("hunter_rank", "sss_board_approved", hunter_sss_board_approved)

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
		var normalized_item_id := "nen_awakening_elixir" if str(item_id) == "nen_acquisition_elixir" else str(item_id)
		var item_count := maxi(0, int(saved_inventory[item_id]))
		if item_count > 0:
			inventory_items[normalized_item_id] = int(inventory_items.get(normalized_item_id, 0)) + item_count

	var saved_equipment: Dictionary = config.get_value("equipment", "slots", {})
	equipment_slots = DEFAULT_EQUIPMENT_SLOTS.duplicate(true)
	for slot in DEFAULT_EQUIPMENT_SLOTS.keys():
		var item_id := str(saved_equipment.get(slot, ""))
		if item_id.is_empty() or str(EQUIPMENT_SLOTS_BY_ITEM.get(item_id, "")) == str(slot):
			equipment_slots[slot] = item_id
	equipment_upgrade_levels = {}
	var saved_upgrades: Dictionary = config.get_value("equipment", "upgrade_levels", {})
	for item_id in saved_upgrades.keys():
		equipment_upgrade_levels[str(item_id)] = clampi(int(saved_upgrades[item_id]), 0, MAX_EQUIPMENT_UPGRADE_LEVEL)
	equipment_durability = {}
	var saved_durability: Dictionary = config.get_value("equipment", "durability", {})
	for item_id in saved_durability.keys():
		equipment_durability[str(item_id)] = clampf(float(saved_durability[item_id]), 0.0, MAX_EQUIPMENT_DURABILITY)
	for item_id in equipment_slots.values():
		var equipped_id := str(item_id)
		if not equipped_id.is_empty() and not equipment_durability.has(equipped_id):
			equipment_durability[equipped_id] = MAX_EQUIPMENT_DURABILITY

	var saved_effects: Dictionary = config.get_value("effects", "active_elixirs", {})
	active_elixir_effects = {}
	for effect_id in saved_effects.keys():
		var effect: Dictionary = saved_effects[effect_id].duplicate(true)
		if float(effect.get("remaining_seconds", 0.0)) > 0.0:
			active_elixir_effects[str(effect_id)] = effect
	nen_unlocked = bool(config.get_value("nen", "unlocked", false))
	nen_control_rank = clampi(int(config.get_value("nen", "control_rank", 0)), 0, 5)
	nen_burst_cooldown_remaining = maxf(0.0, float(config.get_value("nen", "burst_cooldown_remaining", 0.0)))
	verified_hunter_mission_points = maxi(0, int(config.get_value("hunter_rank", "verified_mission_points", 0)))
	verified_hunter_mission_count = maxi(0, int(config.get_value("hunter_rank", "verified_mission_count", 0)))
	verified_hunter_mission_ids.clear()
	for mission_id in config.get_value("hunter_rank", "verified_mission_ids", []):
		var normalized_mission_id := str(mission_id).strip_edges()
		if not normalized_mission_id.is_empty() and not verified_hunter_mission_ids.has(normalized_mission_id):
			verified_hunter_mission_ids.append(normalized_mission_id)
	nen_skill_use_count = maxi(0, int(config.get_value("hunter_rank", "nen_skill_use_count", 0)))
	nen_skill_ids.clear()
	for ability_id in config.get_value("hunter_rank", "nen_skill_ids", []):
		var normalized_ability_id := str(ability_id).strip_edges().to_lower()
		if not normalized_ability_id.is_empty() and not nen_skill_ids.has(normalized_ability_id):
			nen_skill_ids.append(normalized_ability_id)
	hunter_sss_board_approved = bool(config.get_value("hunter_rank", "sss_board_approved", false))

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
	equipment_upgrade_levels.clear()
	equipment_durability.clear()
	active_elixir_effects.clear()
	nen_unlocked = false
	nen_control_rank = 0
	nen_burst_cooldown_remaining = 0.0


func _emit_progress() -> void:
	progress_changed.emit(
		current_level,
		total_xp,
		xp_in_level,
		get_xp_to_next_level()
	)
