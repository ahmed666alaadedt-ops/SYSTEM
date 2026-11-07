extends Node

# SYSTEM WORLD - Living NPC Society
# Godot 4.3
# Connected NPC identity, social relationships and family records.

const RelationshipSystem = preload(
	"res://scripts/npc_relationship_system.gd"
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
		{"name": "سارة", "job": "تاجرة", "family": "family_1", "age": 28, "personality": "اجتماعية", "home": Vector3(-17, 0, -15), "work": Vector3(7, 0, 4)},
		{"name": "عمر", "job": "خباز", "family": "family_1", "age": 32, "personality": "هادئ", "home": Vector3(-17, 0, -15), "work": Vector3(10, 0, -3)},
		{"name": "ليلى", "job": "طبيبة", "family": "family_2", "age": 30, "personality": "رحيمة", "home": Vector3(18, 0, -13), "work": Vector3(-13, 0, 5)},
		{"name": "حسن", "job": "حارس", "family": "family_2", "age": 35, "personality": "شجاع", "home": Vector3(18, 0, -13), "work": Vector3(0, 0, -16)},
		{"name": "نور", "job": "مزارعة", "family": "family_3", "age": 26, "personality": "محبة للطبيعة", "home": Vector3(-19, 0, 16), "work": Vector3(-24, 0, 20)},
		{"name": "آدم", "job": "نجار", "family": "family_3", "age": 29, "personality": "مجتهد", "home": Vector3(-19, 0, 16), "work": Vector3(18, 0, 8)},
		{"name": "مريم", "job": "تاجرة", "family": "family_4", "age": 27, "personality": "ذكية", "home": Vector3(19, 0, 17), "work": Vector3(7, 0, 4)},
		{"name": "يوسف", "job": "حارس", "family": "family_4", "age": 33, "personality": "منضبط", "home": Vector3(19, 0, 17), "work": Vector3(0, 0, 15)},
		{"name": "زينب", "job": "طبيبة", "family": "family_5", "age": 31, "personality": "حكيمة", "home": Vector3(-23, 0, -5), "work": Vector3(-13, 0, 5)},
		{"name": "كريم", "job": "نجار", "family": "family_5", "age": 36, "personality": "صبور", "home": Vector3(-23, 0, -5), "work": Vector3(18, 0, 8)},
		{"name": "هند", "job": "مزارعة", "family": "family_6", "age": 25, "personality": "مرحة", "home": Vector3(24, 0, 4), "work": Vector3(-24, 0, 20)},
		{"name": "علي", "job": "خباز", "family": "family_6", "age": 34, "personality": "كريم", "home": Vector3(24, 0, 4), "work": Vector3(10, 0, -3)}
	]

	for index in range(people.size()):
		_create_resident(people[index], index)


func _create_resident(profile: Dictionary, index: int) -> void:
	var npc := Node3D.new()
	npc.name = "Resident_%02d" % index

	var home: Vector3 = profile["home"]

	npc.position = home + Vector3(
		randf_range(-1.5, 1.5),
		0,
		randf_range(-1.5, 1.5)
	)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()

	capsule.radius = 0.34
	capsule.height = 1.65

	body.mesh = capsule
	body.position.y = 0.83

	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(
		float(index) / float(RESIDENT_COUNT),
		0.48,
		0.86
	)
	material.roughness = 0.8
	body.material_override = material

	npc.add_child(body)

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
		"label": name_label
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
