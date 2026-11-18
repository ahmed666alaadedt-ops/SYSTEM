extends Node

# SYSTEM WORLD - Monster Loot Manager
# Generates a deterministic structure of possible rewards; inventory integration comes later.

signal loot_generated(monster_id: String, loot_data: Dictionary)

const MATERIALS := {
	"F": ["خردة بوابة", "غبار وحشي"],
	"E": ["نواة ضعيفة", "جلد وحشي"],
	"D": ["نواة خام", "مخلب وحشي"],
	"C": ["نواة مستقرة", "سمّ مركز"],
	"B": ["نواة مشحونة", "لبّ مدرع"],
	"A": ["نواة نادرة", "قطعة أثرية"],
	"S": ["نواة عالية الطاقة", "جوهر زعيم"],
	"SS": ["نواة أسطورية", "قلب بوابة"],
	"SSS": ["نواة كارثية", "أثر قديم"],
	"EX": ["نواة EX", "جوهر متفرّد"]
}

const RANK_MULTIPLIER := {
	"F": 1, "E": 2, "D": 3, "C": 5, "B": 8,
	"A": 13, "S": 21, "SS": 34, "SSS": 55, "EX": 89
}


func process_defeat(defeat_data: Dictionary) -> void:
	var rank := str(defeat_data.get("rank", "F"))
	var is_boss := bool(defeat_data.get("is_boss", false))
	var monster_id := str(defeat_data.get("id", "UNKNOWN"))
	var multiplier := int(RANK_MULTIPLIER.get(rank, 1))
	var materials: Array = MATERIALS.get(rank, MATERIALS["F"])
	var drops: Array[Dictionary] = []

	var material_count := 1 + (1 if randf() < 0.25 else 0)
	if is_boss:
		material_count += 2
	for index in range(material_count):
		drops.append({
			"item": materials[randi_range(0, materials.size() - 1)],
			"quantity": randi_range(1, 2) * multiplier
		})

	var rare_chance := 0.015 + float(multiplier) * 0.006
	if is_boss:
		rare_chance += 0.18
	var rare_drop := randf() < minf(rare_chance, 0.75)
	if rare_drop:
		drops.append({
			"item": "قطعة نادرة من " + rank,
			"quantity": 1
		})

	var result := {
		"monster_id": monster_id,
		"rank": rank,
		"is_boss": is_boss,
		"drops": drops,
		"currency": randi_range(2, 8) * multiplier * (5 if is_boss else 1),
		"rare_drop": rare_drop,
		"inventory_committed": false
	}
	loot_generated.emit(monster_id, result)
	print("SYSTEM LOOT: ", monster_id, " | ", drops.size(), " drop entries.")


func preview_rank_rewards(rank: String) -> Dictionary:
	var materials: Array = MATERIALS.get(rank, MATERIALS["F"])
	return {
		"rank": rank,
		"possible_materials": materials.duplicate(),
		"rank_multiplier": int(RANK_MULTIPLIER.get(rank, 1))
	}
