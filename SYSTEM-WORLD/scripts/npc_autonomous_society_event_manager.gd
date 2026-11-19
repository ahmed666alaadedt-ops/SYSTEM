extends Node
class_name SystemNPCAutonomousSocietyEventManager

## Runs bounded, non-graphic background civilian events and advances reported
## cases through police response, witness interviews, evidence review and court.
## Serious sexual violence and child-protection cases are never randomly spawned;
## they require an authored event and are handled by the existing safeguarding flow.

const WORLD_ID := 2
const EVENT_INTERVAL := 45.0
const CASE_STEP_INTERVAL := 18.0
const MAX_OPEN_AUTONOMOUS_CASES := 8
const CITIES := ["Baghdad", "New York", "London", "Paris", "Moscow", "Cairo",
	"New Delhi", "Guangzhou", "Seoul", "Tokyo", "Singapore", "Sydney",
	"Rio de Janeiro", "Johannesburg"]
const LOW_LEVEL_CRIMES := ["theft", "fraud", "vandalism", "robbery"]

var society: Node
var crime_manager: Node
var event_clock := 0.0
var case_clock := 0.0
var autonomous_case_ids: Array[String] = []
var total_events_created := 0
var total_cases_resolved := 0

func setup(p_society: Node, p_crime_manager: Node) -> void:
	society = p_society
	crime_manager = p_crime_manager
	if not is_instance_valid(society) or not is_instance_valid(crime_manager):
		push_warning("SYSTEM NPC Events: required managers are unavailable.")
		set_process(false)
		return
	set_process(true)
	print("SYSTEM NPC Events: autonomous civilian event simulation connected.")

func _process(delta: float) -> void:
	if not is_instance_valid(society) or not is_instance_valid(crime_manager):
		return
	event_clock += delta
	case_clock += delta
	if event_clock >= EVENT_INTERVAL:
		event_clock = 0.0
		_try_create_civilian_event()
	if case_clock >= CASE_STEP_INTERVAL:
		case_clock = 0.0
		_advance_autonomous_cases()

func _living_adults(city_name: String = "") -> Array[String]:
	var result: Array[String] = []
	for raw_id in society.npcs.keys():
		var npc_id := str(raw_id)
		var npc: Dictionary = society.call("get_npc", npc_id)
		if npc.is_empty() or not bool(npc.get("alive", false)):
			continue
		if int(npc.get("world_id", -1)) != WORLD_ID:
			continue
		if float(npc.get("age_years", 0.0)) < 18.0:
			continue
		if bool(npc.get("jailed", false)):
			continue
		var npc_city := _normalize_city_name(str(npc.get("city_name", npc.get("city_id", "Baghdad"))))
		if not city_name.is_empty() and npc_city != _normalize_city_name(city_name):
			continue
		result.append(npc_id)
	return result

func _normalize_city_name(value: String) -> String:
	return value.to_lower().replace("city_", "").replace("_", " ").strip_edges()

func _try_create_civilian_event() -> void:
	if autonomous_case_ids.size() >= MAX_OPEN_AUTONOMOUS_CASES:
		return
	# Keep background crime uncommon; the simulation is not a constant crime feed.
	if randf() > 0.32:
		return
	var all_adults := _living_adults()
	if all_adults.size() < 3:
		return
	var victim_id := all_adults[randi_range(0, all_adults.size() - 1)]
	var victim: Dictionary = society.call("get_npc", victim_id)
	var city_name := str(victim.get("city_name", victim.get("city_id", "Baghdad")))
	if city_name.is_empty() or city_name.to_lower() == "city_baghdad":
		city_name = "Baghdad"
	var local_adults := _living_adults(city_name)
	if local_adults.size() < 3:
		return
	var suspects := local_adults.duplicate()
	suspects.erase(victim_id)
	if suspects.is_empty():
		return
	var suspect_id: String = str(suspects[randi_range(0, suspects.size() - 1)])
	var crime_type := str(LOW_LEVEL_CRIMES[randi_range(0, LOW_LEVEL_CRIMES.size() - 1)])
	var witnesses := randi_range(1, mini(3, local_adults.size() - 2))
	var evidence: Array[String] = ["witness_statement"]
	if randf() < 0.65:
		evidence.append("public_camera_or_transaction_record")
	var location_id := str(victim.get("current_location", "public_district"))
	if location_id.is_empty():
		location_id = "public_district"
	var result: Dictionary = crime_manager.call(
		"report_civilian_crime", crime_type, city_name, location_id,
		suspect_id, victim_id, witnesses, evidence
	)
	if not bool(result.get("success", false)):
		return
	var case_id := str(result.get("case_id", ""))
	if case_id.is_empty():
		return
	autonomous_case_ids.append(case_id)
	total_events_created += 1
	_record_citizen_reaction(suspect_id, victim_id, case_id, crime_type, witnesses, city_name)
	_tag_case_for_background(case_id)
	print("SYSTEM SOCIETY: civilian incident created: ", crime_type, " / ", city_name, " / ", case_id)

func _record_citizen_reaction(suspect_id: String, victim_id: String, case_id: String,
		crime_type: String, witness_count: int, city_name: String) -> void:
	if society.has_method("add_memory"):
		society.call("add_memory", victim_id, "civilian_crime_reported", {
			"case_id": case_id, "crime_type": crime_type, "support_available": true
		})
		society.call("add_memory", suspect_id, "civilian_case_opened", {
			"case_id": case_id, "crime_type": crime_type
		})
	var suspect: Dictionary = society.call("get_npc", suspect_id)
	suspect["legal_status"] = "under_investigation"
	suspect["reputation"] = float(suspect.get("reputation", 0.0)) - 2.0
	society.npcs[suspect_id] = suspect
	var victim: Dictionary = society.call("get_npc", victim_id)
	victim["support_contact_pending"] = true
	society.npcs[victim_id] = victim
	# Witnesses are represented as independent memories without exposing victim details.
	var adults := _living_adults(city_name)
	var recorded := 0
	for witness_id in adults:
		if witness_id == suspect_id or witness_id == victim_id:
			continue
		if recorded >= witness_count:
			break
		if society.has_method("add_memory"):
			society.call("add_memory", witness_id, "witnessed_public_incident", {
				"case_id": case_id, "reporting_status": "statement_available"
			})
		recorded += 1

func _tag_case_for_background(case_id: String) -> void:
	for index in range(crime_manager.crime_records.size()):
		var record: Dictionary = crime_manager.crime_records[index]
		if str(record.get("case_id", "")) != case_id:
			continue
		record["autonomous_simulation"] = true
		record["autonomous_step"] = 0
		record["autonomous_next_step_seconds"] = Time.get_ticks_msec() / 1000.0 + CASE_STEP_INTERVAL
		crime_manager.crime_records[index] = record
		return

func _advance_autonomous_cases() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for case_id in autonomous_case_ids.duplicate():
		var record: Dictionary = crime_manager.call("get_crime_case", case_id)
		if record.is_empty() or str(record.get("status", "")) == "closed":
			autonomous_case_ids.erase(case_id)
			continue
		if now < float(record.get("autonomous_next_step_seconds", 0.0)):
			continue
		var step_index := int(record.get("autonomous_step", 0))
		var steps := ["police_arrived", "witness_interviewed", "evidence_collected",
			"suspect_identified", "victim_support_contacted", "case_sent_to_court"]
		if step_index >= steps.size():
			_resolve_case(case_id, record)
			autonomous_case_ids.erase(case_id)
			total_cases_resolved += 1
			continue
		var evidence_gain := 0.12 if steps[step_index] == "evidence_collected" else 0.04
		crime_manager.call("record_investigation_step", case_id, steps[step_index], evidence_gain)
		_update_case_metadata(case_id, step_index + 1, now + CASE_STEP_INTERVAL)
		_apply_investigation_memories(record, steps[step_index])
		if steps[step_index] == "case_sent_to_court":
			_resolve_case(case_id, crime_manager.call("get_crime_case", case_id))
			autonomous_case_ids.erase(case_id)
			total_cases_resolved += 1

func _update_case_metadata(case_id: String, next_step: int, next_time: float) -> void:
	for index in range(crime_manager.crime_records.size()):
		var record: Dictionary = crime_manager.crime_records[index]
		if str(record.get("case_id", "")) != case_id:
			continue
		record["autonomous_step"] = next_step
		record["autonomous_next_step_seconds"] = next_time
		crime_manager.crime_records[index] = record
		return

func _apply_investigation_memories(record: Dictionary, step: String) -> void:
	if not society.has_method("add_memory"):
		return
	var case_id := str(record.get("case_id", ""))
	var suspect_id := str(record.get("suspect_npc_id", ""))
	var victim_id := str(record.get("victim_npc_id", ""))
	if not suspect_id.is_empty():
		society.call("add_memory", suspect_id, "case_progress_" + step, {"case_id": case_id})
	if not victim_id.is_empty() and step == "victim_support_contacted":
		society.call("add_memory", victim_id, "victim_support_contacted", {"case_id": case_id})

func _resolve_case(case_id: String, record: Dictionary) -> void:
	var evidence_score := float(record.get("evidence_score", 0.0))
	var verdict := "guilty" if evidence_score >= 0.35 else "insufficient_evidence"
	var severity := int(record.get("severity", 1))
	var sentence_days := clampi(severity * 12 + int(evidence_score * 40.0), 1, 3650)
	var result: Dictionary = crime_manager.call("resolve_crime_case", case_id, verdict, sentence_days)
	if bool(result.get("success", false)):
		print("SYSTEM COURT: case ", case_id, " resolved: ", verdict)
		var suspect_id := str(record.get("suspect_npc_id", ""))
		if not suspect_id.is_empty() and society.has_method("add_memory"):
			society.call("add_memory", suspect_id, "court_verdict_" + verdict, {
				"case_id": case_id, "sentence_days": sentence_days if verdict == "guilty" else 0
			})

func get_society_event_status() -> Dictionary:
	return {
		"active": is_processing(),
		"autonomous_cases_open": autonomous_case_ids.size(),
		"events_created": total_events_created,
		"cases_resolved": total_cases_resolved,
		"simulation_scope": "bounded_background_adult_civilian_events",
		"violent_and_sexual_crimes": "authored_events_only_non_graphic_safeguarding"
	}
