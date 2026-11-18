extends Node

# SYSTEM WORLD - Hunter Guild Gate Operations
# Registry, threat assessment, dispatch records and clear reports.

signal gate_registered(report: Dictionary)
signal gate_reported(report: Dictionary)
signal team_dispatched(gate_id: String, team: Array)
signal gate_cleared(report: Dictionary)
signal gate_breached_report(report: Dictionary)

const RANK_ORDER := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "EX"]

var gate_records: Dictionary = {}
var report_counter := 0
var player_rank := "F"


func setup(gate_manager: Node, monster_manager: Node) -> void:
	if is_instance_valid(gate_manager):
		if gate_manager.has_signal("gate_spawned"):
			gate_manager.connect("gate_spawned", Callable(self, "register_gate"))
		if gate_manager.has_signal("gate_became_unstable"):
			gate_manager.connect("gate_became_unstable", Callable(self, "mark_gate_unstable"))
		if gate_manager.has_signal("gate_breached"):
			gate_manager.connect("gate_breached", Callable(self, "mark_gate_breached"))
		if gate_manager.has_signal("gate_contained"):
			gate_manager.connect("gate_contained", Callable(self, "mark_gate_contained"))
	if is_instance_valid(monster_manager):
		if monster_manager.has_signal("gate_encounter_completed"):
			monster_manager.connect("gate_encounter_completed", Callable(self, "complete_gate_operation"))
	print("SYSTEM: Hunter Guild Gate Operations connected.")


func register_gate(gate_data: Dictionary) -> Dictionary:
	var gate_id := str(gate_data.get("id", ""))
	if gate_id.is_empty() or gate_records.has(gate_id):
		return {}
	report_counter += 1
	var rank := str(gate_data.get("displayed_rank", "F"))
	var record := {
		"report_id": "HGR-%07d" % report_counter,
		"gate_id": gate_id,
		"region": str(gate_data.get("region", "Unknown")),
		"biome": str(gate_data.get("biome", "unknown")),
		"rank": rank,
		"status": "discovered",
		"risk_score": _risk_score(rank),
		"recommended_team_size": _recommended_team_size(rank),
		"assigned_team": [],
		"reported_at": Time.get_unix_time_from_system(),
		"breach_reported": false,
		"cleared": false
	}
	gate_records[gate_id] = record
	gate_registered.emit(record.duplicate(true))
	return record.duplicate(true)


func report_gate(gate_id: String, reporter_id: String = "PLAYER") -> Dictionary:
	if not gate_records.has(gate_id):
		return {}
	var record: Dictionary = gate_records[gate_id]
	record["status"] = "reported"
	record["reporter_id"] = reporter_id
	record["report_timestamp"] = Time.get_unix_time_from_system()
	gate_reported.emit(record.duplicate(true))
	return record.duplicate(true)


func mark_gate_unstable(gate_data: Dictionary) -> void:
	_update_status(str(gate_data.get("id", "")), "unstable")


func mark_gate_breached(gate_data: Dictionary) -> void:
	var gate_id := str(gate_data.get("id", ""))
	if not gate_records.has(gate_id):
		register_gate(gate_data)
	var record: Dictionary = gate_records.get(gate_id, {})
	record["status"] = "breached"
	record["breach_reported"] = true
	record["risk_score"] = mini(100, int(record.get("risk_score", 0)) + 25)
	gate_breached_report.emit(record.duplicate(true))


func assign_team(gate_id: String, member_ids: Array[String]) -> bool:
	if not gate_records.has(gate_id) or member_ids.is_empty():
		return false
	var record: Dictionary = gate_records[gate_id]
	record["assigned_team"] = member_ids.duplicate()
	record["status"] = "team_assembled"
	return true


func dispatch_team(gate_id: String) -> Dictionary:
	if not gate_records.has(gate_id):
		return {}
	var record: Dictionary = gate_records[gate_id]
	var team: Array = record.get("assigned_team", [])
	if team.is_empty():
		return {}
	record["status"] = "in_operation"
	record["dispatch_timestamp"] = Time.get_unix_time_from_system()
	team_dispatched.emit(gate_id, team.duplicate())
	return record.duplicate(true)


func complete_gate_operation(gate_id: String) -> void:
	if not gate_records.has(gate_id):
		return
	var record: Dictionary = gate_records[gate_id]
	record["status"] = "cleared"
	record["cleared"] = true
	record["clear_timestamp"] = Time.get_unix_time_from_system()
	gate_cleared.emit(record.duplicate(true))


func mark_gate_contained(gate_data: Dictionary) -> void:
	var gate_id := str(gate_data.get("id", ""))
	_update_status(gate_id, "contained")


func _update_status(gate_id: String, status: String) -> void:
	if gate_records.has(gate_id):
		var record: Dictionary = gate_records[gate_id]
		record["status"] = status


func get_gate_report(gate_id: String) -> Dictionary:
	if not gate_records.has(gate_id):
		return {}
	return gate_records[gate_id].duplicate(true)


func get_all_reports() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gate_id in gate_records:
		result.append(gate_records[gate_id].duplicate(true))
	return result


func get_open_reports() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gate_id in gate_records:
		var record: Dictionary = gate_records[gate_id]
		if not bool(record.get("cleared", false)):
			result.append(record.duplicate(true))
	return result


func _risk_score(rank: String) -> int:
	var index := RANK_ORDER.find(rank)
	return clampi(8 + maxi(index, 0) * 10, 5, 100)


func _recommended_team_size(rank: String) -> int:
	var index := maxi(0, RANK_ORDER.find(rank))
	return clampi(3 + index * 2, 3, 20)
