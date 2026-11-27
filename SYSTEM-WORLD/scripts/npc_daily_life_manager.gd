extends Node
class_name SystemNPCDailyLifeManager

## Persistent civilian routines and needs. This first pass simulates society
## records in bounded batches; visible pedestrian navigation is a later layer.
## Civilians never perform player missions, puzzles or mission combat.

const MODERN_WORLD_ID := 2
const TICK_INTERVAL_SECONDS := 5.0
const MAX_NPCS_PER_TICK := 200
## Seed a large persistent civilian society; only nearby actors are rendered.
const STARTER_RESIDENT_COUNT := 42500
const STARTER_MINOR_COUNT := 7500
const NPC_SEED_BATCH_SIZE := 50
const FIRST_NAMES := [
	"Ali", "Zahra", "Omar", "Noor", "Hassan", "Maryam",
	"Mustafa", "Sara", "Yusuf", "Fatima", "Karar", "Rana",
	"Haider", "Duaa", "Ammar", "Aya", "Sajad", "Huda",
	"Mahdi", "Zainab", "Laith", "Mariam", "Kadhim", "Shahad"
]
const OCCUPATIONS := [
	"teacher", "doctor", "shopkeeper", "mechanic",
	"engineer", "driver", "cook", "nurse",
	"builder", "student", "accountant", "farmer"
]

var society_manager: Node
var elapsed_seconds: float = 0.0
var next_npc_index: int = 0
var seeded: bool = false


func setup(manager: Node) -> void:
	society_manager = manager
	if not is_instance_valid(society_manager):
		push_warning("SYSTEM NPC Life: society manager is unavailable.")
		return
	_seed_baghdad_residents_if_needed()
	set_process(true)


func _process(delta: float) -> void:
	if not is_instance_valid(society_manager):
		return
	elapsed_seconds += delta
	if elapsed_seconds < TICK_INTERVAL_SECONDS:
		return
	var elapsed := elapsed_seconds
	elapsed_seconds = 0.0
	_simulate_batch(elapsed)


func _seed_baghdad_residents_if_needed() -> void:
	# Read the society dictionary directly: get_living_npcs() deep-copies every
	# record, which creates a large avoidable memory spike at 50,000 residents.
	var population: Dictionary = society_manager.get("npcs")
	var existing_count := population.size()
	var existing_minor_count := 0
	var existing_adult_count := 0
	for resident_value in population.values():
		if not resident_value is Dictionary:
			continue
		var resident: Dictionary = resident_value
		if not bool(resident.get("alive", false)) or int(resident.get("world_id", -1)) != MODERN_WORLD_ID:
			continue
		if float(resident.get("age_years", 0.0)) < 18.0:
			existing_minor_count += 1
		else:
			existing_adult_count += 1

	# Older saves may already contain the full starter headcount but no children.
	# Top up each demographic independently so the visible city always has
	# family-age variety without duplicating the entire starter population.
	var created_adults_preview: Array[String] = []
	var adults_needed := maxi(0, STARTER_RESIDENT_COUNT - existing_adult_count)
	for offset in range(adults_needed):
		var index := existing_adult_count + offset
		var age := 18.0 + float((index * 7) % 64)
		var occupation := str(OCCUPATIONS[index % OCCUPATIONS.size()])
		var npc_id: String = society_manager.call(
			"create_npc",
			str(FIRST_NAMES[index % FIRST_NAMES.size()]) + " " + str(index + 1),
			MODERN_WORLD_ID,
			age,
			"balanced",
			occupation
		)
		if npc_id.is_empty():
			continue
		if created_adults_preview.size() < 8:
			created_adults_preview.append(npc_id)
		_configure_resident(npc_id, index, occupation)
		if offset % NPC_SEED_BATCH_SIZE == NPC_SEED_BATCH_SIZE - 1:
			await get_tree().process_frame

	for pair_index in range(0, mini(8, created_adults_preview.size() - 1), 2):
		var first_id := created_adults_preview[pair_index]
		var second_id := created_adults_preview[pair_index + 1]
		var first: Dictionary = society_manager.call("get_npc", first_id)
		var second: Dictionary = society_manager.call("get_npc", second_id)
		if float(first.get("age_years", 0.0)) >= 18.0 and float(second.get("age_years", 0.0)) >= 18.0:
			society_manager.call("marry_npcs", first_id, second_id)

	var children_needed := maxi(0, STARTER_MINOR_COUNT - existing_minor_count)
	var created_children := 0
	for offset in range(children_needed):
		var child_index := existing_minor_count + offset
		var child_name := "Baghdad Child " + str(child_index + 1)
		var age := 6.0 + float(child_index % 12)
		var child_id: String = society_manager.call(
			"create_npc",
			child_name,
			MODERN_WORLD_ID,
			age,
			"curious",
			"student"
		)
		if child_id.is_empty():
			continue
		_configure_resident(child_id, STARTER_RESIDENT_COUNT + child_index, "student")
		created_children += 1
		if offset % NPC_SEED_BATCH_SIZE == NPC_SEED_BATCH_SIZE - 1:
			await get_tree().process_frame

	seeded = true
	print("SYSTEM NPC Life: seeded_city_residents=", society_manager.npcs.size(),
		" | existing minors=", existing_minor_count, " | new minors=", created_children, " | total society records=", society_manager.npcs.size())


func _configure_resident(npc_id: String, index: int, occupation: String) -> void:
	var npc: Dictionary = society_manager.npcs.get(npc_id, {})
	if npc.is_empty():
		return
	var home_number := int(index / 3) + 1
	npc["home_location"] = "baghdad_home_%02d" % home_number
	npc["current_location"] = str(npc["home_location"])
	npc["city_id"] = "city_baghdad"
	npc["district_id"] = "baghdad_district_%02d" % (int(index / 6) + 1)
	npc["occupation"] = occupation
	npc["employer_id"] = "baghdad_employer_%02d" % (int(index / 4) + 1)
	npc["wallet"] = 25.0 + float((index * 13) % 180)
	npc["bank_balance"] = float((index * 47) % 900)
	npc["daily_wage"] = 8.0 + float((index * 3) % 17)
	npc["current_action"] = "settling_in"
	npc["schedule_profile"] = "student" if occupation == "student" else "day_worker"
	npc["needs"] = {
		"health": 100.0, "hunger": 82.0, "thirst": 88.0,
		"energy": 82.0, "hygiene": 78.0, "social": 68.0,
		"wellbeing": 78.0, "safety": 95.0
	}
	society_manager.npcs[npc_id] = npc


func _simulate_batch(real_seconds: float) -> void:
	var npc_ids: Array = society_manager.npcs.keys()
	if npc_ids.is_empty():
		return
	var elapsed_hours := real_seconds / 60.0
	var count := mini(MAX_NPCS_PER_TICK, npc_ids.size())
	var simulated_hours := elapsed_hours * float(npc_ids.size()) / float(count)
	for offset in range(count):
		var index := (next_npc_index + offset) % npc_ids.size()
		_update_resident(str(npc_ids[index]), simulated_hours)
	next_npc_index = (next_npc_index + count) % npc_ids.size()


func _update_resident(npc_id: String, hours: float) -> void:
	var npc: Dictionary = society_manager.call("get_npc", npc_id)
	if npc.is_empty() or not bool(npc.get("alive", false)):
		return
	if int(npc.get("world_id", -1)) != MODERN_WORLD_ID:
		return
	if bool(npc.get("jailed", false)):
		var remaining_days := maxf(0.0, float(npc.get("jail_days_remaining", 0.0)) - hours / 24.0)
		npc["jail_days_remaining"] = remaining_days
		npc["current_location"] = "baghdad_central_detention"
		npc["current_action"] = "serving_sentence"
		if remaining_days <= 0.0:
			npc["jailed"] = false
			npc["current_location"] = str(npc.get("home_location", "baghdad_residential_area"))
			npc["current_action"] = "released_from_sentence"
			npc["reputation"] = float(npc.get("reputation", 0.0)) - 5.0
			if society_manager.has_method("add_memory"):
				society_manager.call("add_memory", npc_id, "released_from_sentence", {})
		society_manager.npcs[npc_id] = npc
		return
	var needs: Dictionary = npc.get("needs", {})
	needs["hunger"] = maxf(0.0, float(needs.get("hunger", 80.0)) - hours * 1.7)
	needs["thirst"] = maxf(0.0, float(needs.get("thirst", 85.0)) - hours * 2.6)
	needs["hygiene"] = maxf(0.0, float(needs.get("hygiene", 75.0)) - hours * 0.22)
	var action := _choose_action(npc, needs)
	npc["current_action"] = action
	npc["needs"] = needs
	var location := str(npc.get("home_location", "baghdad_residential_area"))
	match action:
		"work":
			# Defensive guard: a minor can never be sent to an employer or paid wages.
			if float(npc.get("age_years", 0.0)) < 18.0:
				action = "school" if float(society_manager.get("simulation_hours")) >= 8.0 and fposmod(float(society_manager.get("simulation_hours")), 24.0) < 15.0 else "family"
				location = "baghdad_school" if action == "school" else str(npc.get("home_location", "baghdad_residential_area"))
			else:
				location = str(npc.get("employer_id", "baghdad_workplace"))
				npc["wallet"] = float(npc.get("wallet", 0.0)) + float(npc.get("daily_wage", 10.0)) * hours / 8.0
		"school":
			location = "baghdad_school"
		"eat":
			location = "baghdad_market_or_cafe"
			needs["hunger"] = minf(100.0, float(needs["hunger"]) + hours * 8.0)
			npc["wallet"] = maxf(0.0, float(npc.get("wallet", 0.0)) - hours * 0.8)
		"drink":
			location = "baghdad_market_or_home"
			needs["thirst"] = minf(100.0, float(needs["thirst"]) + hours * 18.0)
			npc["wallet"] = maxf(0.0, float(npc.get("wallet", 0.0)) - hours * 0.25)
		"sleep":
			needs["energy"] = minf(100.0, float(needs["energy"]) + hours * 12.0)
		"wash":
			needs["hygiene"] = minf(100.0, float(needs["hygiene"]) + hours * 10.0)
		"socialize", "family":
			location = str(npc.get("district_id", "baghdad_neighborhood"))
			needs["social"] = minf(100.0, float(needs["social"]) + hours * 2.5)
	npc["current_action"] = action
	npc["needs"] = needs
	npc["current_location"] = location
	society_manager.npcs[npc_id] = npc
	society_manager.call("set_activity", npc_id, _activity_for_action(action), location)


func _choose_action(npc: Dictionary, needs: Dictionary) -> String:
	var hour := fposmod(float(society_manager.get("simulation_hours")), 24.0)
	if float(needs.get("thirst", 100.0)) < 24.0:
		return "drink"
	if float(needs.get("hunger", 100.0)) < 28.0:
		return "eat"
	if float(needs.get("hygiene", 100.0)) < 18.0:
		return "wash"
	if float(needs.get("energy", 100.0)) < 20.0:
		return "sleep"
	if float(needs.get("social", 100.0)) < 22.0:
		return "socialize"
	if hour >= 22.0 or hour < 6.0:
		return "sleep"
	# Minors attend school during daytime and never enter the employment schedule,
	# even if an older save contains an invalid occupation label.
	if float(npc.get("age_years", 0.0)) < 18.0:
		if hour >= 8.0 and hour < 15.0:
			return "school"
		if hour >= 15.0 and hour < 20.0:
			var parent_ids: Array = npc.get("parent_ids", [])
			return "family" if not parent_ids.is_empty() else "socialize"
		return "daily_life"
	if hour >= 8.0 and hour < 16.0 and str(npc.get("occupation", "")) != "unemployed":
		return "work"
	if hour >= 16.0 and hour < 20.0:
		return "family" if not str(npc.get("spouse_id", "")).is_empty() else "socialize"
	if hour >= 6.0 and hour < 8.0:
		return "wash"
	if hour >= 20.0:
		return "socialize"
	return "daily_life"


func _activity_for_action(action: String) -> String:
	match action:
		"work":
			return "work"
		"school":
			return "daily_life"
		"socialize":
			return "socialize"
		"family":
			return "family"
		"sleep", "wash", "eat", "drink":
			return "rest"
		_:
			return "daily_life"
