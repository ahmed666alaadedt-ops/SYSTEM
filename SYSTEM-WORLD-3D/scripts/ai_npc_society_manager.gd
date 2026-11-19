extends Node

# SYSTEM WORLD - Living NPC Society
# Godot 4.3
# Connected NPC identity, social relationships and family records.

const RelationshipSystem = preload(
	"res://scripts/npc_relationship_system.gd"
)
const NPCVisual = preload(
	"res://scripts/npc_character_model.gd"
)

const RESIDENT_COUNT := 12
const WALK_SPEED := 1.35
const ARRIVAL_DISTANCE := 0.8

var world: Node3D
var residents: Array[Dictionary] = []
var relationship_system: RefCounted

var needs_timer := 0.0
var initialized := false

var town_square := Vector3(0, 0, 0)
var market_position := Vector3(7, 0, 4)
var school_position := Vector3(-8, 0, 7)


func setup(world_root: Node3D) -> void:
	if initialized:
		return

	world = world_root
	relationship_system = RelationshipSystem.new()

	_create_residents()
	initialized = true


func update_world(delta: float, world_hour: float) -> void:
	if not initialized or not is_instance_valid(world):
		return

	needs_timer += delta

	for resident in residents:
		_update_resident(resident, delta, world_hour)

	if needs_timer >= 8.0:
		needs_timer = 0.0
		_update_social_needs()


func _create_residents() -> void:
	var people := [
		{"name": "سارة", "gender": "female", "job": "تاجرة", "family": "family_1", "age": 28, "personality": "اجتماعية", "home": Vector3(-17, 0, -15), "work": Vector3(7, 0, 4)},
		{"name": "عمر", "gender": "male", "job": "خباز", "family": "family_1", "age": 32, "personality": "هادئ", "home": Vector3(-17, 0, -15), "work": Vector3(10, 0, -3)},
		{"name": "ليلى", "gender": "female", "job": "طبيبة", "family": "family_2", "age": 30, "personality": "رحيمة", "home": Vector3(18, 0, -13), "work": Vector3(-13, 0, 5)},
		{"name": "حسن", "gender": "male", "job": "حارس", "family": "family_2", "age": 35, "personality": "شجاع", "home": Vector3(18, 0, -13), "work": Vector3(0, 0, -16)},
		{"name": "نور", "gender": "female", "job": "مزارعة", "family": "family_3", "age": 26, "personality": "محبة للطبيعة", "home": Vector3(-19, 0, 16), "work": Vector3(-24, 0, 20)},
		{"name": "آدم", "gender": "male", "job": "نجار", "family": "family_3", "age": 29, "personality": "مجتهد", "home": Vector3(-19, 0, 16), "work": Vector3(18, 0, 8)},
		{"name": "مريم", "gender": "female", "job": "تاجرة", "family": "family_4", "age": 27, "personality": "ذكية", "home": Vector3(19, 0, 17), "work": Vector3(7, 0, 4)},
		{"name": "يوسف", "gender": "male", "job": "حارس", "family": "family_4", "age": 33, "personality": "منضبط", "home": Vector3(19, 0, 17), "work": Vector3(0, 0, 15)},
		{"name": "زينب", "gender": "female", "job": "طبيبة", "family": "family_5", "age": 31, "personality": "حكيمة", "home": Vector3(-23, 0, -5), "work": Vector3(-13, 0, 5)},
		{"name": "كريم", "gender": "male", "job": "نجار", "family": "family_5", "age": 36, "personality": "صبور", "home": Vector3(-23, 0, -5), "work": Vector3(18, 0, 8)},
		{"name": "هند", "gender": "female", "job": "مزارعة", "family": "family_6", "age": 25, "personality": "مرحة", "home": Vector3(24, 0, 4), "work": Vector3(-24, 0, 20)},
		{"name": "علي", "gender": "male", "job": "خباز", "family": "family_6", "age": 34, "personality": "كريم", "home": Vector3(24, 0, 4), "work": Vector3(10, 0, -3)},
		{"name": "جد سارة", "job": "متقاعد", "family": "family_1", "age": 68, "gender": "male", "personality": "حكيم", "home": Vector3(-17, 0, -15), "work": Vector3(-17, 0, -15)},
		{"name": "جدة عمر", "job": "متقاعدة", "family": "family_1", "age": 64, "gender": "female", "personality": "حنونة", "home": Vector3(-17, 0, -15), "work": Vector3(-17, 0, -15)},
		{"name": "ليان", "job": "طالبة", "family": "family_2", "age": 10, "gender": "female", "personality": "فضولية", "home": Vector3(18, 0, -13), "work": school_position},
		{"name": "حيدر", "job": "طالب", "family": "family_2", "age": 13, "gender": "male", "personality": "مرح", "home": Vector3(18, 0, -13), "work": school_position},
		{"name": "أبو نور", "job": "متقاعد", "family": "family_3", "age": 72, "gender": "male", "personality": "صبور", "home": Vector3(-19, 0, 16), "work": Vector3(-19, 0, 16)},
		{"name": "مريم الصغيرة", "job": "طالبة", "family": "family_4", "age": 8, "gender": "female", "personality": "مرحة", "home": Vector3(19, 0, 17), "work": school_position},
		{"name": "يوسف الصغير", "job": "طالب", "family": "family_5", "age": 12, "gender": "male", "personality": "هادئ", "home": Vector3(-23, 0, -5), "work": school_position},
		{"name": "أم هند", "job": "متقاعدة", "family": "family_6", "age": 66, "gender": "female", "personality": "اجتماعية", "home": Vector3(24, 0, 4), "work": Vector3(24, 0, 4)}
	]

	for index in range(people.size()):
		_create_resident(people[index], index)
	_link_initial_families()



func _link_initial_families() -> void:
	var couples := [
		["سارة", "عمر"], ["ليلى", "حسن"], ["نور", "آدم"],
		["مريم", "يوسف"], ["زينب", "كريم"], ["هند", "علي"]
	]
	for couple in couples:
		var first_id := _find_resident_id(str(couple[0]))
		var second_id := _find_resident_id(str(couple[1]))
		if first_id.is_empty() or second_id.is_empty():
			continue
		relationship_system.set_relationship(first_id, second_id, "partner", 90.0)
		relationship_system.create_marriage(first_id, second_id)

	var family_links := [
		{"parents": ["جد سارة"], "children": ["سارة"]},
		{"parents": ["جدة عمر"], "children": ["عمر"]},
		{"parents": ["ليلى", "حسن"], "children": ["ليان", "حيدر"]},
		{"parents": ["أبو نور"], "children": ["نور", "آدم"]},
		{"parents": ["مريم", "يوسف"], "children": ["مريم الصغيرة"]},
		{"parents": ["زينب", "كريم"], "children": ["يوسف الصغير"]},
		{"parents": ["أم هند"], "children": ["هند", "علي"]}
	]
	for family in family_links:
		var parent_ids: Array[String] = []
		for parent_name in family["parents"]:
			var parent_id := _find_resident_id(str(parent_name))
			if not parent_id.is_empty():
				parent_ids.append(parent_id)
		for child_name in family["children"]:
			var child_id := _find_resident_id(str(child_name))
			if not child_id.is_empty():
				relationship_system.set_parentage(parent_ids, child_id)


func _create_resident(profile: Dictionary, index: int) -> void:
	var npc := Node3D.new()
	npc.name = "Resident_%02d" % index

	var home: Vector3 = profile["home"]

	npc.position = home + Vector3(
		randf_range(-1.5, 1.5),
		0,
		randf_range(-1.5, 1.5)
	)

	# Use the shared full-body 3D civilian model instead of a capsule placeholder.
	var enriched_profile := profile.duplicate(true)
	var resident_age := int(profile.get("age", 30))
	enriched_profile["age_group"] = "child" if resident_age < 18 else ("elder" if resident_age >= 60 else "adult")
	enriched_profile["body_type"] = ["average", "slim", "heavy", "athletic", "muscular"][posmod(index * 3 + resident_age, 5)]
	enriched_profile["height_type"] = ["short", "average", "tall"][posmod(index + resident_age, 3)]
	var visual := NPCVisual.new()
	visual.name = "HumanoidVisual"
	npc.add_child(visual)
	visual.configure(enriched_profile, index)

	var name_label := Label3D.new()
	name_label.name = "ResidentName"
	name_label.text = str(profile["name"]) + " • " + str(profile["job"])
	name_label.position.y = 2.0
	name_label.font_size = 30
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.modulate = Color(0.9, 0.95, 1.0)

	npc.add_child(name_label)
	world.add_child(npc)

	# Register the NPC in the relationship and family system.
	var resident_id: String = relationship_system.register_resident(
		str(profile["name"]),
		int(profile["age"]),
		str(profile["personality"]),
		str(profile["family"])
	)

	var record := {
		"node": npc,
		"id": resident_id,
		"name": profile["name"],
		"job": profile["job"],
		"family": profile["family"],
		"age": profile["age"],
		"age_group": enriched_profile["age_group"],
		"body_type": enriched_profile["body_type"],
		"height_type": enriched_profile["height_type"],
		"gender": profile.get("gender", "female" if index % 2 == 1 else "male"),
		"personality": profile["personality"],
		"home": home,
		"workplace": profile["work"],
		"state": "rest",
		"target": home,
		"energy": randf_range(65.0, 100.0),
		"hunger": randf_range(10.0, 35.0),
		"social": randf_range(45.0, 90.0),
		"money": randi_range(20, 100),
		"activity_timer": randf_range(2.0, 8.0),
		"speed": randf_range(0.9, 1.2),
		"label": name_label,
		"visual": visual
	}

	residents.append(record)


func _update_resident(
	record: Dictionary,
	delta: float,
	world_hour: float
) -> void:
	var npc: Node3D = record["node"]

	if not is_instance_valid(npc):
		return

	record["activity_timer"] -= delta

	if record["activity_timer"] <= 0.0:
		_choose_daily_activity(record, world_hour)

	_move_resident(record, delta)
	_update_needs(record, delta)


func _choose_daily_activity(
	record: Dictionary,
	world_hour: float
) -> void:
	var hour := int(world_hour)
	var current_state := str(record["state"])

	var resident_age := int(record.get("age", 30))
	if resident_age < 18:
		if hour >= 22 or hour < 7:
			_set_activity(record, "rest", record["home"])
		elif hour >= 8 and hour < 13:
			_set_activity(record, "school", record["workplace"])
		else:
			_set_activity(record, "play", _find_social_destination())
		return
	if hour >= 22 or hour < 6:
		_set_activity(record, "rest", record["home"])
		return

	if float(record["energy"]) < 15.0:
		_set_activity(record, "rest", record["home"])
		return

	if float(record["hunger"]) > 75.0:
		_set_activity(record, "eat", market_position)
		return

	if hour >= 7 and hour < 16:
		if current_state != "work" and randf() < 0.72:
			_set_activity(record, "work", record["workplace"])
			return

	if hour >= 16 and hour < 22:
		_set_activity(
			record,
			"socialize",
			_find_social_destination()
		)
		return

	var random_destination := Vector3(
		randf_range(-23, 23),
		0,
		randf_range(-24, 24)
	)

	_set_activity(record, "wander", random_destination)


func _set_activity(
	record: Dictionary,
	new_state: String,
	destination: Vector3
) -> void:
	record["state"] = new_state
	record["target"] = destination
	record["activity_timer"] = randf_range(7.0, 15.0)

	var visual: Node = record.get("visual")
	if is_instance_valid(visual):
		visual.call("set_activity", new_state)

	var label: Label3D = record["label"]

	if is_instance_valid(label):
		var activity_text := ""

		match new_state:
			"work":
				activity_text = "يعمل"
			"rest":
				activity_text = "يرتاح"
			"eat":
				activity_text = "يتناول الطعام"
			"socialize":
				activity_text = "يتفاعل"
			"wander":
				activity_text = "يتجول"
			"school":
				activity_text = "في المدرسة"
			"play":
				activity_text = "يلعب"

		label.text = str(record["name"]) + " • " + activity_text


func _move_resident(record: Dictionary, delta: float) -> void:
	var npc: Node3D = record["node"]
	var destination: Vector3 = record["target"]

	var target := Vector3(
		destination.x,
		npc.position.y,
		destination.z
	)

	var distance := npc.position.distance_to(target)

	if distance <= ARRIVAL_DISTANCE:
		return

	var speed := WALK_SPEED * float(record["speed"])
	if int(record.get("age", 30)) >= 60:
		speed *= 0.78
	elif int(record.get("age", 30)) < 18:
		speed *= 0.92

	if str(record["state"]) == "rest":
		speed *= 0.5

	npc.position = npc.position.move_toward(
		target,
		speed * delta
	)

	var direction := target - npc.position

	if direction.length() > 0.1:
		npc.rotation.y = lerp_angle(
			npc.rotation.y,
			atan2(direction.x, direction.z),
			delta * 4.0
		)


func _update_needs(record: Dictionary, delta: float) -> void:
	var state := str(record["state"])

	record["hunger"] = clampf(
		float(record["hunger"]) + delta * 0.16,
		0.0,
		100.0
	)

	if state == "rest":
		record["energy"] = clampf(
			float(record["energy"]) + delta * 0.7,
			0.0,
			100.0
		)
	else:
		record["energy"] = clampf(
			float(record["energy"]) - delta * 0.045,
			0.0,
			100.0
		)

	if state == "eat":
		record["hunger"] = clampf(
			float(record["hunger"]) - delta * 2.0,
			0.0,
			100.0
		)

	if state == "socialize":
		record["social"] = clampf(
			float(record["social"]) + delta * 0.4,
			0.0,
			100.0
		)
	else:
		record["social"] = clampf(
			float(record["social"]) - delta * 0.015,
			0.0,
			100.0
		)


func _update_social_needs() -> void:
	for record in residents:
		if float(record["social"]) < 20.0:
			if str(record["state"]) != "rest":
				_set_activity(
					record,
					"socialize",
					_find_social_destination()
				)

	# A small social event gradually builds relationships.
	if residents.size() >= 2:
		var first_index := randi_range(0, residents.size() - 1)
		var second_index := randi_range(0, residents.size() - 1)

		while second_index == first_index:
			second_index = randi_range(0, residents.size() - 1)

		var first: Dictionary = residents[first_index]
		var second: Dictionary = residents[second_index]

		relationship_system.change_relationship(
			str(first["id"]),
			str(second["id"]),
			1.0,
			0.5
		)


func _find_social_destination() -> Vector3:
	return town_square + Vector3(
		randf_range(-5.0, 5.0),
		0,
		randf_range(-5.0, 5.0)
	)


func add_resident(profile: Dictionary) -> bool:
	if not initialized or not is_instance_valid(world):
		return false
	var resident_name := str(profile.get("name", "")).strip_edges()
	if resident_name.is_empty():
		return false
	var normalized := profile.duplicate(true)
	var age := clampi(int(normalized.get("age", 30)), 0, 110)
	normalized["age"] = age
	normalized["family"] = str(normalized.get("family", "family_generated_%02d" % (residents.size() + 1)))
	normalized["personality"] = str(normalized.get("personality", "متوازن"))
	if age < 18:
		normalized["job"] = "طالب"
	elif age >= 60 and str(normalized.get("job", "")).is_empty():
		normalized["job"] = "متقاعد"
	else:
		normalized["job"] = str(normalized.get("job", "مواطن"))
	normalized["home"] = normalized.get("home", Vector3(randf_range(-20.0, 20.0), 0.0, randf_range(-20.0, 20.0)))
	normalized["work"] = normalized.get("work", normalized["home"] if age < 18 or age >= 60 else market_position)
	_create_resident(normalized, residents.size())
	return true



func create_family_child(parent_one_name: String, parent_two_name: String, child_profile: Dictionary) -> bool:
	var first_id := _find_resident_id(parent_one_name)
	var second_id := _find_resident_id(parent_two_name)
	if first_id.is_empty() or second_id.is_empty():
		return false
	var first_profile: Dictionary = relationship_system.get_resident_profile(first_id)
	var second_profile: Dictionary = relationship_system.get_resident_profile(second_id)
	if str(first_profile.get("married_to", "")) != second_id:
		return false
	if str(second_profile.get("married_to", "")) != first_id:
		return false
	if int(first_profile.get("age", 0)) < 18 or int(second_profile.get("age", 0)) < 18:
		return false
	var newborn := child_profile.duplicate(true)
	newborn["age"] = 0
	newborn["family"] = str(first_profile.get("family_id", "family_new"))
	newborn["job"] = "طفل"
	if not add_resident(newborn):
		return false
	var child_id := _find_resident_id(str(newborn.get("name", "")))
	return relationship_system.set_parentage([first_id, second_id], child_id)

func set_resident_activity(resident_name: String, activity: String, destination: Vector3) -> bool:
	for record in residents:
		if str(record.get("name", "")) != resident_name:
			continue
		var age := int(record.get("age", 30))
		if age < 18 and activity in ["work", "attack", "combat", "fight", "hunter_mission"]:
			return false
		_set_activity(record, activity, destination)
		return true
	return false


func get_population_summary() -> Dictionary:
	var result := {
		"total": residents.size(),
		"children": 0,
		"adults": 0,
		"elders": 0,
		"body_types": {},
		"height_types": {}
	}
	for record in residents:
		var stage := str(record.get("age_group", "adult"))
		var stage_key := "children" if stage == "child" else ("elders" if stage == "elder" else "adults")
		result[stage_key] = int(result.get(stage_key, 0)) + 1
		var body_key := str(record.get("body_type", "average"))
		var height_key := str(record.get("height_type", "average"))
		var bodies: Dictionary = result["body_types"]
		var heights: Dictionary = result["height_types"]
		bodies[body_key] = int(bodies.get(body_key, 0)) + 1
		heights[height_key] = int(heights.get(height_key, 0)) + 1
		result["body_types"] = bodies
		result["height_types"] = heights
	return result


func get_resident_count() -> int:
	return residents.size()


func get_resident_information(resident_name: String) -> Dictionary:
	for record in residents:
		if str(record["name"]) == resident_name:
			var information := {
				"name": record["name"],
				"id": record["id"],
				"job": record["job"],
				"family": record["family"],
				"age": record["age"],
				"age_group": record.get("age_group", "adult"),
				"body_type": record.get("body_type", "average"),
				"height_type": record.get("height_type", "average"),
				"personality": record["personality"],
				"state": record["state"],
				"energy": record["energy"],
				"hunger": record["hunger"],
				"social": record["social"],
				"money": record["money"]
			}

			information["family_profile"] = (
				relationship_system.get_resident_profile(
					str(record["id"])
				)
			)

			return information

	return {}


func get_relationship_information(
	first_name: String,
	second_name: String
) -> Dictionary:
	var first_id := _find_resident_id(first_name)
	var second_id := _find_resident_id(second_name)

	if first_id.is_empty() or second_id.is_empty():
		return {}

	return relationship_system.get_relationship(
		first_id,
		second_id
	)


func get_family_tree_for_resident(resident_name: String) -> Array:
	var resident_id := _find_resident_id(resident_name)

	if resident_id.is_empty():
		return []

	var profile: Dictionary = relationship_system.get_resident_profile(
		resident_id
	)

	return relationship_system.get_family_tree(
		str(profile.get("family_id", ""))
	)


func _find_resident_id(resident_name: String) -> String:
	for record in residents:
		if str(record["name"]) == resident_name:
			return str(record["id"])

	return ""
