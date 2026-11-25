extends SceneTree

const OperationsScript = preload("res://scripts/system_baghdad_tower_operations_manager.gd")
const CombatScript = preload("res://scripts/modern_world_combat_system.gd")
const ProgressionScript = preload("res://scripts/system_player_progression.gd")
const ALLOWED_QUALITY := ["BRONZE", "SILVER", "GOLD", "DIAMOND"]
const FORBIDDEN_IDS := ["system_firearm", "hunter_pistol", "hunter_rifle", "precision_rifle", "tactical_shotgun"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog: Array = OperationsScript.PRODUCT_CATALOG.get("power_tower_baghdad", [])
	assert(not catalog.is_empty(), "Power Tower shop catalog must exist.")
	var seen_ids := {}
	var skill_count := 0
	var weapon_count := 0
	var cafeteria_count := 0
	var accessory_count := 0
	var footwear_count := 0
	var armor_count := 0
	var rare_elixir_count := 0
	var ammunition_count := 0
	for product_value in catalog:
		var product: Dictionary = product_value
		var item_id := str(product.get("id", ""))
		assert(not item_id.is_empty(), "Every Power Tower product needs a stable item ID.")
		assert(not seen_ids.has(item_id), "Duplicate Power Tower shop item: " + item_id)
		seen_ids[item_id] = true
		assert(not FORBIDDEN_IDS.has(item_id), "Modern firearm must never be sold in the Power Tower: " + item_id)
		assert(ALLOWED_QUALITY.has(str(product.get("quality", ""))), "Missing/invalid quality tier for " + item_id)
		assert(str(product.get("rarity", "")).to_upper() in ["COMMON", "RARE"], "Power Tower catalog rarity must be explicit and conservative.")
		assert(str(product.get("availability", "")).to_upper() in ["PERMANENT", "CONSUMABLE", "TEMPORARY"], "Availability classification missing for " + item_id)
		var category := str(product.get("category", ""))
		if category in ["MELEE_WEAPON", "TRADITIONAL_RANGED"]:
			weapon_count += 1
			assert(category != "FIREARM" and category != "MODERN_PROJECTILE")
		if category == "SKILL":
			skill_count += 1
		if category == "CAFETERIA":
			cafeteria_count += 1
		if category == "ACCESSORY":
			accessory_count += 1
		if category == "FOOTWEAR":
			footwear_count += 1
		if category == "AMMUNITION":
			ammunition_count += 1
		if category == "ARMOR":
			armor_count += 1
		if category == "NEN_ELIXIR" and str(product.get("rarity", "")).to_upper() == "RARE":
			rare_elixir_count += 1
	assert(weapon_count >= 8, "Traditional weapon selection is incomplete.")
	assert(skill_count >= 3, "Nen/skill shop must expose skill manuals.")
	assert(cafeteria_count >= 3, "Power Tower cafeteria catalog is incomplete.")
	assert(accessory_count >= 4, "Hunter accessory catalog is incomplete.")
	assert(footwear_count >= 5, "Bronze-to-diamond Power Tower footwear progression is incomplete.")
	assert(ammunition_count >= 3, "Bronze, silver and diamond arrow ammunition tiers are incomplete.")
	assert(armor_count >= 5, "Armor progression from bronze to diamond is incomplete.")
	assert(rare_elixir_count >= 4, "Rare Nen elixir selection is incomplete.")
	assert(ProgressionScript.DEFAULT_EQUIPMENT_SLOTS.has("boots"))
	assert(ProgressionScript.EQUIPMENT_SLOTS_BY_ITEM.get("training_boots", "") == "boots")
	assert(ProgressionScript.EQUIPMENT_SLOTS_BY_ITEM.get("rank_sss_boots", "") == "boots")
	var progression := ProgressionScript.new()
	progression.name = "PowerTowerFootwearProgressionTest"
	root.add_child(progression)
	await process_frame
	progression.call("_reset_progress")
	assert(bool(progression.call("add_item", "training_boots", 1)))
	var boot_equip: Dictionary = progression.call("equip_item", "training_boots")
	assert(bool(boot_equip.get("success", false)))
	assert(str(progression.call("get_equipped_item", "boots")) == "training_boots")
	assert(float(progression.call("get_movement_multiplier")) > 1.0)
	assert(bool(progression.call("add_item", "reinforced_arrows", 3)))
	assert(bool(progression.call("consume_item", "reinforced_arrows", 1)))
	assert(int(progression.call("get_item_count", "reinforced_arrows")) == 2)
	assert(ProgressionScript.EQUIPMENT_SLOTS_BY_ITEM.get("hunter_pendant", "") == "accessory_1")
	assert(ProgressionScript.EQUIPMENT_SLOTS_BY_ITEM.get("nen_aura_bracelet", "") == "accessory_2")
	var config: Dictionary = OperationsScript.POWER_TOWER_CONFIG
	assert(int(config.get("floors", 0)) == 200)
	assert(config.get("allowed_weapon_categories", []).has("MELEE"))
	assert(config.get("prohibited_weapon_categories", []).has("FIREARM"))
	assert(config.get("jobs", []).has("arena_registrar"))
	assert(config.get("jobs", []).has("arena_coordinator"))
	assert(config.get("roles", []).size() == 4)
	assert(str(config.get("roles", [])[3]).contains("النِن"))
	assert(CombatScript.POWER_TOWER_FORBIDDEN_WEAPONS.has("system_firearm"))
	assert(CombatScript.POWER_TOWER_FORBIDDEN_WEAPONS.has("hunter_rifle"))
	print("POWER TOWER SHOP VALIDATION PASSED: %d products, %d traditional weapons, %d skill manuals, %d cafeteria items, %d accessories, %d footwear, %d armor, %d arrow ammunition tiers and %d rare Nen elixirs; no modern firearms." % [catalog.size(), weapon_count, skill_count, cafeteria_count, accessory_count, footwear_count, armor_count, ammunition_count, rare_elixir_count])
	quit(0)
