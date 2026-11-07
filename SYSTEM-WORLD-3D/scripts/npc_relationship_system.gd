
extends RefCounted

# SYSTEM WORLD - NPC Relationships and Family Foundation
# Social bonds, family trees, marriage records and generations.

var relationships: Dictionary = {}
var families: Dictionary = {}
var resident_profiles: Dictionary = {}
var next_resident_id := 1


func register_resident(
	resident_name: String,
	age: int,
	personality: String,
	family_id: String
) -> String:
	var resident_id := "resident_%05d" % next_resident_id
	next_resident_id += 1

	resident_profiles[resident_id] = {
		"id": resident_id,
		"name": resident_name,
		"age": maxi(age, 18),
		"personality": personality,
		"family_id": family_id,
		"alive": true,
		"married_to": "",
		"parents": [],
		"children": [],
		"generation": 1,
		"life_stage": "adult"
	}

	if not families.has(family_id):
		families[family_id] = {
			"id": family_id,
			"members": [],
			"history": []
		}

	families[family_id]["members"].append(resident_id)

	return resident_id


func set_relationship(
	first_id: String,
	second_id: String,
	relationship_type: String,
	initial_value: float = 50.0
) -> void:
	if not _resident_exists(first_id):
		return

	if not _resident_exists(second_id):
		return

	var key := _pair_key(first_id, second_id)

	relationships[key] = {
		"first": first_id,
		"second": second_id,
		"type": relationship_type,
		"affection": clampf(initial_value, 0.0, 100.0),
		"trust": clampf(initial_value, 0.0, 100.0),
		"interactions": 0,
		"last_event": "relationship_created"
	}


func change_relationship(
	first_id: String,
	second_id: String,
	affection_change: float,
	trust_change: float
) -> void:
	var key := _pair_key(first_id, second_id)

	if not relationships.has(key):
		set_relationship(first_id, second_id, "acquaintance")

	if not relationships.has(key):
		return

	var bond: Dictionary = relationships[key]

	bond["affection"] = clampf(
		float(bond["affection"]) + affection_change,
		0.0,
		100.0
	)

	bond["trust"] = clampf(
		float(bond["trust"]) + trust_change,
		0.0,
		100.0
	)

	bond["interactions"] = int(bond["interactions"]) + 1

	if float(bond["affection"]) >= 80.0:
		bond["type"] = "close_friend"
	elif float(bond["affection"]) >= 45.0:
		bond["type"] = "friend"
	elif float(bond["affection"]) <= 15.0:
		bond["type"] = "unfriendly"

	relationships[key] = bond


func create_marriage(first_id: String, second_id: String) -> bool:
	if not _resident_exists(first_id):
		return false

	if not _resident_exists(second_id):
		return false

	var first: Dictionary = resident_profiles[first_id]
	var second: Dictionary = resident_profiles[second_id]

	if int(first["age"]) < 18 or int(second["age"]) < 18:
		return false

	if not str(first["married_to"]).is_empty():
		return false

	if not str(second["married_to"]).is_empty():
		return false

	var key := _pair_key(first_id, second_id)

	if not relationships.has(key):
		return false

	var bond: Dictionary = relationships[key]

	if float(bond["affection"]) < 75.0:
		return false

	if float(bond["trust"]) < 65.0:
		return false

	first["married_to"] = second_id
	second["married_to"] = first_id

	resident_profiles[first_id] = first
	resident_profiles[second_id] = second

	bond["type"] = "married"
	bond["last_event"] = "marriage"

	relationships[key] = bond

	var family_id := str(first["family_id"])

	if families.has(family_id):
		families[family_id]["history"].append({
			"event": "marriage",
			"resident": first_id,
			"partner": second_id
		})

	return true


func create_child(
	parent_one_id: String,
	parent_two_id: String,
	child_name: String
) -> String:
	if not _resident_exists(parent_one_id):
		return ""

	if not _resident_exists(parent_two_id):
		return ""

	var parent_one: Dictionary = resident_profiles[parent_one_id]
	var parent_two: Dictionary = resident_profiles[parent_two_id]

	if str(parent_one["married_to"]) != parent_two_id:
		return ""

	if str(parent_two["married_to"]) != parent_one_id:
		return ""

	var family_id := str(parent_one["family_id"])

	var child_id := register_resident(
		child_name,
		0,
		"developing",
		family_id
	)

	var child: Dictionary = resident_profiles[child_id]

	child["age"] = 0
	child["life_stage"] = "child"
	child["generation"] = maxi(
		int(parent_one["generation"]),
		int(parent_two["generation"])
	) + 1

	child["parents"] = [
		parent_one_id,
		parent_two_id
	]

	resident_profiles[child_id] = child

	parent_one["children"].append(child_id)
	parent_two["children"].append(child_id)

	resident_profiles[parent_one_id] = parent_one
	resident_profiles[parent_two_id] = parent_two

	families[family_id]["history"].append({
		"event": "birth",
		"child": child_id,
		"parents": [parent_one_id, parent_two_id]
	})

	return child_id


func advance_age(resident_id: String, years: int = 1) -> void:
	if not _resident_exists(resident_id):
		return

	var resident: Dictionary = resident_profiles[resident_id]

	resident["age"] = int(resident["age"]) + maxi(years, 0)

	var age := int(resident["age"])

	if age < 18:
		resident["life_stage"] = "child"
	elif age < 60:
		resident["life_stage"] = "adult"
	else:
		resident["life_stage"] = "elder"

	resident_profiles[resident_id] = resident


func get_relationship(
	first_id: String,
	second_id: String
) -> Dictionary:
	var key := _pair_key(first_id, second_id)

	if relationships.has(key):
		return relationships[key].duplicate(true)

	return {}


func get_family_tree(family_id: String) -> Array:
	if not families.has(family_id):
		return []

	var result: Array = []

	for resident_id in families[family_id]["members"]:
		if resident_profiles.has(resident_id):
			result.append(
				resident_profiles[resident_id].duplicate(true)
			)

	return result


func get_resident_profile(resident_id: String) -> Dictionary:
	if not resident_profiles.has(resident_id):
		return {}

	return resident_profiles[resident_id].duplicate(true)


func _resident_exists(resident_id: String) -> bool:
	return resident_profiles.has(resident_id)


func _pair_key(first_id: String, second_id: String) -> String:
	var ids := [first_id, second_id]
	ids.sort()
	return str(ids[0]) + "::" + str(ids[1])
