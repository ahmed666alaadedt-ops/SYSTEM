extends SceneTree

const OperationsScript = preload("res://scripts/system_baghdad_tower_operations_manager.gd")
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
	for product_value in catalog:
		var product: Dictionary = product_value
		var item_id := str(product.get("id", ""))
		assert(not item_id.is_empty(), "Every Power Tower product needs a stable item ID.")
		assert(not seen_ids.has(item_id), "Duplicate Power Tower shop item: " + item_id)
		seen_ids[item_id] = true
		assert(not FORBIDDEN_IDS.has(item_id), "Modern firearm must never be sold in the Power Tower: " + item_id)
		assert(ALLOWED_QUALITY.has(str(product.get("quality", ""))), "Missing/invalid quality tier for " + item_id)
		assert(str(product.get("rarity", "")).to_upper() in ["COMMON", "RARE"]), "Power Tower catalog rarity must be explicit and conservative.")
		assert(str(product.get("availability", "")).to_upper() in ["PERMANENT", "CONSUMABLE", "TEMPORARY"]), "Availability classification missing for " + item_id)
		var category := str(product.get("category", ""))
		if category in ["MELEE_WEAPON", "TRADITIONAL_RANGED"]:
			weapon_count += 1
			assert(category != "FIREARM" and category != "MODERN_PROJECTILE")
		if category == "SKILL":
			skill_count += 1
		if category == "CAFETERIA":
			cafeteria_count += 1
	assert(weapon_count >= 8, "Traditional weapon selection is incomplete.")
	assert(skill_count >= 3, "Nen/skill shop must expose skill manuals.")
	assert(cafeteria_count >= 3, "Power Tower cafeteria catalog is incomplete.")
	var config: Dictionary = OperationsScript.POWER_TOWER_CONFIG
	assert(int(config.get("floors", 0)) == 200)
	assert(config.get("allowed_weapon_categories", []).has("MELEE"))
	assert(config.get("prohibited_weapon_categories", []).has("FIREARM"))
	assert(config.get("jobs", []).has("match_schedule_coordinator"))
	assert(config.get("jobs", []).has("nen_discovery_trainer"))
	print("POWER TOWER SHOP VALIDATION PASSED: %d products, %d traditional weapons, %d skill manuals, %d cafeteria items; no modern firearms." % [catalog.size(), weapon_count, skill_count, cafeteria_count])
	quit(0)
