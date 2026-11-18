extends RefCounted

# SYSTEM WORLD - Monster Species Database
# Data-driven prototype for regional monster families.

const SPECIES := {
	"urban_stalker": {
		"name": "Urban Stalker", "name_ar": "المتربص الحضري",
		"family": "beast", "biomes": ["urban", "ruins"],
		"color": Color(0.32, 0.42, 0.48), "health_mult": 1.0,
		"speed_mult": 1.18, "damage_mult": 1.0,
		"behavior": "ambush", "weakness": "fire", "resistance": "dark"
	},
	"ash_wolf": {
		"name": "Ash Wolf", "name_ar": "ذئب الرماد",
		"family": "beast", "biomes": ["forest", "mountain", "plains"],
		"color": Color(0.48, 0.40, 0.34), "health_mult": 0.82,
		"speed_mult": 1.5, "damage_mult": 0.9,
		"behavior": "pack", "weakness": "lightning", "resistance": "wind"
	},
	"ironback": {
		"name": "Ironback", "name_ar": "مدرع الحديد",
		"family": "reptile", "biomes": ["desert", "ruins"],
		"color": Color(0.42, 0.48, 0.38), "health_mult": 1.75,
		"speed_mult": 0.62, "damage_mult": 1.35,
		"behavior": "territorial", "weakness": "ice", "resistance": "physical"
	},
	"web_matriarch": {
		"name": "Web Matriarch", "name_ar": "أمّ العناكب",
		"family": "insect", "biomes": ["forest", "cave"],
		"color": Color(0.30, 0.18, 0.38), "health_mult": 1.15,
		"speed_mult": 0.92, "damage_mult": 1.2,
		"behavior": "ambush", "weakness": "fire", "resistance": "poison"
	},
	"crypt_wanderer": {
		"name": "Crypt Wanderer", "name_ar": "تائه السرداب",
		"family": "undead", "biomes": ["ruins", "cave", "urban"],
		"color": Color(0.55, 0.66, 0.52), "health_mult": 1.25,
		"speed_mult": 0.78, "damage_mult": 1.12,
		"behavior": "guard", "weakness": "light", "resistance": "poison"
	},
	"storm_wisp": {
		"name": "Storm Wisp", "name_ar": "طيف العاصفة",
		"family": "elemental", "biomes": ["mountain", "plains"],
		"color": Color(0.25, 0.72, 0.92), "health_mult": 0.72,
		"speed_mult": 1.32, "damage_mult": 1.28,
		"behavior": "ranged", "weakness": "earth", "resistance": "lightning"
	},
	"dune_reaver": {
		"name": "Dune Reaver", "name_ar": "ناهب الكثبان",
		"family": "humanoid", "biomes": ["desert", "plains"],
		"color": Color(0.72, 0.49, 0.25), "health_mult": 1.0,
		"speed_mult": 1.0, "damage_mult": 1.0,
		"behavior": "patrol", "weakness": "ice", "resistance": "fire"
	},
	"root_colossus": {
		"name": "Root Colossus", "name_ar": "عملاق الجذور",
		"family": "giant", "biomes": ["forest", "mountain"],
		"color": Color(0.28, 0.38, 0.22), "health_mult": 2.8,
		"speed_mult": 0.48, "damage_mult": 2.0,
		"behavior": "boss_guard", "weakness": "fire", "resistance": "earth"
	}
}


func choose_species(biome: String, rank: String, is_boss: bool = false) -> Dictionary:
	var candidates: Array[String] = []
	for species_id in SPECIES.keys():
		var data: Dictionary = SPECIES[species_id]
		if biome == "any" or data["biomes"].has(biome):
			candidates.append(species_id)
	if candidates.is_empty():
		candidates = ["urban_stalker", "ash_wolf", "dune_reaver"]
	if is_boss and rank in ["A", "S", "SS", "SSS", "EX"]:
		var giant_candidates := ["root_colossus", "web_matriarch", "ironback"]
		var valid_giants: Array[String] = []
		for species_id in giant_candidates:
			if candidates.has(species_id):
				valid_giants.append(species_id)
		if not valid_giants.is_empty():
			candidates = valid_giants
	var selected: String = candidates[randi_range(0, candidates.size() - 1)]
	return get_species_data(selected)


func get_species_data(species_id: String) -> Dictionary:
	if not SPECIES.has(species_id):
		return {}
	var result: Dictionary = SPECIES[species_id].duplicate(true)
	result["id"] = species_id
	return result


func get_all_species() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for species_id in SPECIES.keys():
		result.append(get_species_data(species_id))
	return result
