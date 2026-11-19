extends Node
class_name SystemNPCSocialInteractionManager

## Lightweight social encounters for visible civilians.
## Repeated greetings can become persistent mutual friendships.

const WORLD_ID := 2
const SCAN_INTERVAL := 2.0
const INTERACTION_DISTANCE := 3.2
const PAIR_COOLDOWN_SECONDS := 90.0
const MAX_INTERACTIONS_PER_SCAN := 6
const FRIENDSHIP_ENCOUNTERS_REQUIRED := 3

var society: Node
var population_manager: Node
var scan_clock := 0.0
var pair_last_seen: Dictionary = {}
var pair_encounter_counts: Dictionary = {}
var total_greetings := 0
var total_friendships := 0

func setup(p_society: Node, p_population_manager: Node) -> void:
	society = p_society
	population_manager = p_population_manager
	if not is_instance_valid(society) or not is_instance_valid(population_manager):
		push_warning("SYSTEM Social: required managers are unavailable.")
		set_process(false)
		return
	set_process(true)
	print("SYSTEM Social: visible civilian encounters connected.")

func _process(delta: float) -> void:
	scan_clock += delta
	if scan_clock < SCAN_INTERVAL:
		return
	scan_clock = 0.0
	_scan_visible_pairs()

func _scan_visible_pairs() -> void:
	if not is_instance_valid(society) or not is_instance_valid(population_manager):
		return
	var visible: Dictionary = population_manager.get("pedestrians")
	var ids: Array = visible.keys()
	var now := float(Time.get_ticks_msec()) / 1000.0
	var interactions := 0
	for i in range(ids.size()):
		if interactions >= MAX_INTERACTIONS_PER_SCAN:
			break
		var first_id := str(ids[i])
		var first_record: Dictionary = visible.get(first_id, {})
		var first_actor := first_record.get("actor") as Node3D
		if not is_instance_valid(first_actor):
			continue
		var first_npc: Dictionary = society.call("get_npc", first_id)
		if first_npc.is_empty() or not bool(first_npc.get("alive", false)):
			continue
		for j in range(i + 1, ids.size()):
			if interactions >= MAX_INTERACTIONS_PER_SCAN:
				break
			var second_id := str(ids[j])
			var second_record: Dictionary = visible.get(second_id, {})
			var second_actor := second_record.get("actor") as Node3D
			if not is_instance_valid(second_actor):
				continue
			var second_npc: Dictionary = society.call("get_npc", second_id)
			if second_npc.is_empty() or not bool(second_npc.get("alive", false)):
				continue
			if int(first_npc.get("world_id", -1)) != WORLD_ID or int(second_npc.get("world_id", -1)) != WORLD_ID:
				continue
			if bool(first_npc.get("jailed", false)) or bool(second_npc.get("jailed", false)):
				continue
			if _city_key(first_npc) != _city_key(second_npc):
				continue
			if first_actor.global_position.distance_to(second_actor.global_position) > INTERACTION_DISTANCE:
				continue
			var key := _pair_key(first_id, second_id)
			if now - float(pair_last_seen.get(key, -100000.0)) < PAIR_COOLDOWN_SECONDS:
				continue
			pair_last_seen[key] = now
			var encounters := int(pair_encounter_counts.get(key, 0)) + 1
			pair_encounter_counts[key] = encounters
			_record_greeting(first_id, second_id, encounters)
			interactions += 1
			if encounters >= FRIENDSHIP_ENCOUNTERS_REQUIRED:
				var first_friends: Array = first_npc.get("friend_ids", [])
				if not first_friends.has(second_id) and society.has_method("add_friendship"):
					if bool(society.call("add_friendship", first_id, second_id)):
						total_friendships += 1
						pair_encounter_counts.erase(key)
						pair_last_seen[key] = now + PAIR_COOLDOWN_SECONDS * 2.0

func _record_greeting(first_id: String, second_id: String, encounters: int) -> void:
	if society.has_method("add_memory"):
		var details := {"other_npc_id": second_id, "encounter_number": encounters, "interaction": "public_greeting"}
		society.call("add_memory", first_id, "civilian_social_encounter", details)
		details["other_npc_id"] = first_id
		society.call("add_memory", second_id, "civilian_social_encounter", details)
	total_greetings += 1

func _city_key(npc: Dictionary) -> String:
	var city := str(npc.get("city_name", npc.get("city_id", "baghdad"))).to_lower()
	return city.replace("city_", "").replace("_", " ").strip_edges()

func _pair_key(first_id: String, second_id: String) -> String:
	return first_id + "|" + second_id if first_id < second_id else second_id + "|" + first_id

func get_social_status() -> Dictionary:
	return {
		"active": is_processing(),
		"greetings_recorded": total_greetings,
		"friendships_formed": total_friendships,
		"tracked_pairs": pair_encounter_counts.size(),
		"interaction_model": "nearby_repeated_encounters"
	}
