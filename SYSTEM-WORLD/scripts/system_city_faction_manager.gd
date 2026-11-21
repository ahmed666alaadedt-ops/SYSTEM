extends Node
class_name SystemCityFactionManager

## Local first-pass faction registry. It records fictional organization identity,
## district influence, heat and reputation without enabling online territory wars.

signal faction_standing_changed(faction_id: String, standing: int)
signal faction_incident_recorded(faction_id: String, incident_type: String, city_name: String)

const SAVE_PATH := "user://system_city_faction_state.cfg"
const FACTION_TEMPLATES := [
	{"key": "street_crew", "name": "ظلال الرصيف", "role": "street_crew", "district": "industrial_edge", "influence": 18},
	{"key": "smuggling_ring", "name": "خط الميناء", "role": "smuggling_ring", "district": "freight_corridor", "influence": 12},
	{"key": "black_market", "name": "دار المزاد الأسود", "role": "black_market_broker", "district": "old_market", "influence": 9}
]
const PROTECTED_SERVICE_TYPES := ["hospital", "school", "university", "mosque", "church", "child_safe_space"]

var factions: Dictionary = {}
var player_standing: Dictionary = {}
var incident_log: Array[Dictionary] = []
var player_contracts: Dictionary = {}
var next_contract_id := 1
var crime_manager: Node
var society_manager: Node
var region_manager: Node
var active_city_name := "Baghdad"
var next_incident_id := 1

func setup(p_crime_manager: Node, p_society_manager: Node, p_region_manager: Node) -> void:
	crime_manager = p_crime_manager
	society_manager = p_society_manager
	region_manager = p_region_manager
	if is_instance_valid(crime_manager) and crime_manager.has_signal("crime_case_opened"):
		var callback := Callable(self, "_on_crime_case_opened")
		if not crime_manager.is_connected("crime_case_opened", callback):
			crime_manager.connect("crime_case_opened", callback)
	_build_city_factions()
	_load_state()

func _ready() -> void:
	name = "SystemCityFactionManager"

func _build_city_factions() -> void:
	if not is_instance_valid(region_manager) or not region_manager.has_method("get_city_names"):
		_register_city_factions("Baghdad")
		return
	for city_value in region_manager.call("get_city_names"):
		_register_city_factions(str(city_value))

func _register_city_factions(city_name: String) -> void:
	for template in FACTION_TEMPLATES:
		var faction_id := "%s_%s" % [city_name.to_lower().replace(" ", "_"), str(template["key"])]
		if factions.has(faction_id):
			continue
		factions[faction_id] = {
			"id": faction_id,
			"city": city_name,
			"name": str(template["name"]),
			"role": str(template["role"]),
			"district": str(template["district"]),
			"influence": int(template["influence"]),
			"heat": 0,
			"members_estimate": 6 + int(abs(faction_id.hash()) % 19),
			"rivals": [],
			"status": "active",
			"protected_service_exclusion": PROTECTED_SERVICE_TYPES.duplicate()
		}
		player_standing[faction_id] = int(player_standing.get(faction_id, 0))


func set_faction_rivalry(faction_id: String, rival_id: String, hostile: bool = true) -> Dictionary:
	if faction_id == rival_id or not factions.has(faction_id) or not factions.has(rival_id):
		return {"success":false,"reason":"INVALID_FACTION_PAIR"}
	var faction: Dictionary = factions[faction_id]
	var rival: Dictionary = factions[rival_id]
	if str(faction.get("city", "")) != str(rival.get("city", "")):
		return {"success":false,"reason":"RIVAL_MUST_BE_IN_SAME_CITY"}
	var rivals: Array = faction.get("rivals", [])
	var reverse_rivals: Array = rival.get("rivals", [])
	if hostile:
		if not rivals.has(rival_id):
			rivals.append(rival_id)
		if not reverse_rivals.has(faction_id):
			reverse_rivals.append(faction_id)
	else:
		rivals.erase(rival_id)
		reverse_rivals.erase(faction_id)
	faction["rivals"] = rivals
	rival["rivals"] = reverse_rivals
	factions[faction_id] = faction
	factions[rival_id] = rival
	_record_incident(faction_id, "rivalry_updated", {"rival_id":rival_id,"hostile":hostile})
	_save_state()
	return {"success":true,"hostile":hostile}

func issue_player_contract(faction_id: String, objective_type: String) -> Dictionary:
	if not factions.has(faction_id):
		return {"success":false,"reason":"FACTION_NOT_FOUND"}
	var allowed_objectives := ["deliver_courier_package", "collect_public_evidence", "scout_district", "protect_civilian_route"]
	if not allowed_objectives.has(objective_type):
		return {"success":false,"reason":"UNSUPPORTED_PLAYER_OBJECTIVE"}
	if get_player_standing(faction_id) < -50:
		return {"success":false,"reason":"REPUTATION_TOO_LOW"}
	var contract_id := "player_faction_contract_%05d" % next_contract_id
	next_contract_id += 1
	var contract := {
		"id":contract_id,"faction_id":faction_id,"objective":objective_type,
		"status":"AVAILABLE_TO_PLAYER","owner":"local_player","player_only":true,
		"npc_completion_allowed":false,"issued_at":int(Time.get_unix_time_from_system())
	}
	player_contracts[contract_id] = contract
	_record_incident(faction_id, "player_contract_issued", {"contract_id":contract_id,"objective":objective_type})
	_save_state()
	return {"success":true,"contract":contract.duplicate(true)}

func complete_player_contract(contract_id: String, evidence_token: String) -> Dictionary:
	if not player_contracts.has(contract_id):
		return {"success":false,"reason":"CONTRACT_NOT_FOUND"}
	var contract: Dictionary = player_contracts[contract_id]
	if str(contract.get("status", "")) != "AVAILABLE_TO_PLAYER":
		return {"success":false,"reason":"CONTRACT_NOT_ACTIVE"}
	if not evidence_token.begins_with("SYSTEM_PLAYER_EVIDENCE:"):
		return {"success":false,"reason":"PLAYER_EVIDENCE_REQUIRED"}
	contract["status"] = "COMPLETED"
	contract["completed_at"] = int(Time.get_unix_time_from_system())
	player_contracts[contract_id] = contract
	adjust_player_standing(str(contract.get("faction_id", "")), 5, "player_contract_completed")
	_save_state()
	return {"success":true,"contract":contract.duplicate(true)}

func get_player_contracts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for contract_id in player_contracts:
		result.append(player_contracts[contract_id].duplicate(true))
	return result

func get_city_factions(city_name: String) -> Array[Dictionary]:
	_register_city_factions(city_name)
	var result: Array[Dictionary] = []
	for faction_id in factions:
		var record: Dictionary = factions[faction_id]
		if str(record.get("city", "")) == city_name:
			result.append(record.duplicate(true))
	return result

func get_faction(faction_id: String) -> Dictionary:
	var record: Dictionary = factions.get(faction_id, {})
	return record.duplicate(true)

func get_player_standing(faction_id: String) -> int:
	return int(player_standing.get(faction_id, 0))

func adjust_player_standing(faction_id: String, amount: int, reason: String = "") -> Dictionary:
	if not factions.has(faction_id):
		return {"success": false, "reason": "FACTION_NOT_FOUND"}
	var updated := clampi(get_player_standing(faction_id) + amount, -100, 100)
	player_standing[faction_id] = updated
	faction_standing_changed.emit(faction_id, updated)
	_record_incident(faction_id, "standing_adjustment", {"amount": amount, "reason": reason})
	_save_state()
	return {"success": true, "faction_id": faction_id, "standing": updated}

func record_faction_incident(faction_id: String, incident_type: String, details: Dictionary = {}) -> Dictionary:
	if not factions.has(faction_id):
		return {"success": false, "reason": "FACTION_NOT_FOUND"}
	var record: Dictionary = factions[faction_id]
	var severity := clampi(int(details.get("severity", 1)), 1, 5)
	record["heat"] = clampi(int(record.get("heat", 0)) + severity * 3, 0, 100)
	record["influence"] = clampi(int(record.get("influence", 0)) + int(details.get("influence_delta", 0)), 0, 100)
	factions[faction_id] = record
	_record_incident(faction_id, incident_type, details)
	faction_incident_recorded.emit(faction_id, incident_type, str(record.get("city", "")))
	_save_state()
	return {"success": true, "heat": int(record["heat"]), "influence": int(record["influence"])}

func _record_incident(faction_id: String, incident_type: String, details: Dictionary) -> void:
	var faction: Dictionary = factions.get(faction_id, {})
	var incident := {
		"id": "faction_incident_%05d" % next_incident_id,
		"faction_id": faction_id,
		"city": str(faction.get("city", "")),
		"type": incident_type,
		"details": details.duplicate(true),
		"time_unix": int(Time.get_unix_time_from_system())
	}
	next_incident_id += 1
	incident_log.append(incident)
	if incident_log.size() > 250:
		incident_log.pop_front()

func _on_crime_case_opened(case_id: String, crime_type: String, city_name: String) -> void:
	# Crime cases are logged for later investigation-board integration; they do not
	# automatically assign guilt or reveal the player's location to a faction.
	_register_city_factions(city_name)
	var city_factions := get_city_factions(city_name)
	if city_factions.is_empty():
		return
	var selected: Dictionary = city_factions[abs(case_id.hash()) % city_factions.size()]
	_record_incident(str(selected.get("id", "")), "public_crime_case_opened", {
		"case_id": case_id,
		"crime_type": crime_type,
		"evidence_required": true
	})
	_save_state()

func get_recent_incidents(city_name: String, limit: int = 20) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(incident_log.size() - 1, -1, -1):
		var item: Dictionary = incident_log[index]
		if str(item.get("city", "")) == city_name:
			result.append(item.duplicate(true))
			if result.size() >= maxi(limit, 1):
				break
	return result

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	player_standing = config.get_value("factions", "player_standing", player_standing)
	incident_log = config.get_value("factions", "incident_log", incident_log)
	next_incident_id = int(config.get_value("factions", "next_incident_id", next_incident_id))
	player_contracts = config.get_value("factions", "player_contracts", {})
	next_contract_id = int(config.get_value("factions", "next_contract_id", next_contract_id))
	var saved_factions: Dictionary = config.get_value("factions", "faction_state", {})
	for faction_id in saved_factions:
		if factions.has(faction_id):
			factions[faction_id] = saved_factions[faction_id]

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("factions", "player_standing", player_standing)
	config.set_value("factions", "incident_log", incident_log)
	config.set_value("factions", "next_incident_id", next_incident_id)
	config.set_value("factions", "player_contracts", player_contracts)
	config.set_value("factions", "next_contract_id", next_contract_id)
	config.set_value("factions", "faction_state", factions)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM factions: unable to save local faction state: %s" % error)
