extends Node

# SYSTEM WORLD - Hunter Guild Gate Operations
# Registry, threat assessment, dispatch records and clear reports.

signal gate_registered(report: Dictionary)
signal gate_reported(report: Dictionary)
signal team_dispatched(gate_id: String, team: Array)
signal gate_cleared(report: Dictionary)
signal gate_breached_report(report: Dictionary)
signal gate_scan_completed(report: Dictionary)
signal city_alert_requested(report: Dictionary)
signal reinforcement_requested(report: Dictionary)
signal gate_reward_previewed(report: Dictionary)

const RANK_ORDER := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "EX"]

var gate_manager: Node
var gate_records: Dictionary = {}
var report_counter := 0
var player_rank := "F"


func setup(gate_manager_node: Node, monster_manager: Node) -> void:
	gate_manager = gate_manager_node
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
	if is_instance_valid(gate_manager) and gate_manager.has_method("contain_gate"):
		gate_manager.call("contain_gate", gate_id)
	record["status"] = "cleared"
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



# Scan a nearby gate without exposing its hidden rank before a successful scan.
func scan_nearby_gate(gate_id: String, scanner_position: Vector3, scan_range: float = 30.0) -> Dictionary:
	if not gate_records.has(gate_id) or not is_instance_valid(gate_manager):
		return {}
	if not gate_manager.has_method("get_gate_information") or not gate_manager.has_method("scan_gate"):
		return {}
	var info: Dictionary = gate_manager.call("get_gate_information", gate_id)
	if info.is_empty():
		return {}
	var gate_position: Vector3 = info.get("position", Vector3.ZERO)
	var distance := scanner_position.distance_to(gate_position)
	if distance > maxf(1.0, scan_range):
		return {"success": false, "reason": "out_of_range", "distance": distance}
	var scan: Dictionary = gate_manager.call("scan_gate", gate_id)
	if scan.is_empty():
		return {}
	var record: Dictionary = gate_records[gate_id]
	record["last_scan_at"] = Time.get_unix_time_from_system()
	record["scan_count"] = int(record.get("scan_count", 0)) + 1
	if bool(scan.get("scan_success", false)):
		record["verified_rank"] = str(scan.get("scanned_rank", record.get("rank", "F")))
		record["rank_verified"] = true
		record["risk_score"] = _risk_score(str(record["verified_rank"]))
	else:
		record["rank_verified"] = false
	var result := record.duplicate(true)
	result["success"] = bool(scan.get("scan_success", false))
	result["distance"] = distance
	result["real_rank_revealed"] = bool(scan.get("real_rank_revealed", false))
	gate_scan_completed.emit(result)
	return result


# Recalculate threat and request a city warning before a gate breaches.
func assess_gate_threat(gate_id: String, time_remaining: float) -> Dictionary:
	if not gate_records.has(gate_id):
		return {}
	var record: Dictionary = gate_records[gate_id]
	var rank := str(record.get("verified_rank", record.get("rank", "F")))
	var base_risk := _risk_score(rank)
	var urgency := 0
	if time_remaining <= 30.0:
		urgency = 3
	elif time_remaining <= 90.0:
		urgency = 2
	elif time_remaining <= 180.0:
		urgency = 1
	var risk := clampi(base_risk + urgency * 15, 0, 100)
	record["risk_score"] = risk
	record["time_remaining"] = maxf(0.0, time_remaining)
	record["threat_level"] = "critical" if risk >= 75 else ("high" if risk >= 50 else ("elevated" if risk >= 25 else "low"))
	var report := record.duplicate(true)
	if urgency >= 2:
		city_alert_requested.emit(report)
	if urgency >= 3:
		reinforcement_requested.emit(report)
	return report


func request_reinforcements(gate_id: String, reason: String = "threat_escalation") -> Dictionary:
	if not gate_records.has(gate_id):
		return {}
	var record: Dictionary = gate_records[gate_id]
	record["reinforcement_requested"] = true
	record["reinforcement_reason"] = reason
	record["reinforcement_timestamp"] = Time.get_unix_time_from_system()
	var report := record.duplicate(true)
	reinforcement_requested.emit(report)
	return report


# Estimate in-game rewards only; this does not credit a wallet or real money.
func calculate_clear_reward(gate_id: String, boss_defeated: bool = false) -> Dictionary:
	if not gate_records.has(gate_id):
		return {}
	var record: Dictionary = gate_records[gate_id]
	var rank := str(record.get("verified_rank", record.get("rank", "F")))
	var rank_index := maxi(0, RANK_ORDER.find(rank))
	var guild_xp := 40 + rank_index * 35
	var credits := 25 + rank_index * 50
	var reputation := 2 + rank_index * 2
	if boss_defeated:
		guild_xp = int(round(guild_xp * 1.5))
		credits = int(round(credits * 1.5))
		reputation += 3
	var reward := {
		"gate_id": gate_id,
		"rank": rank,
		"guild_xp": guild_xp,
		"credits": credits,
		"reputation": reputation,
		"boss_bonus": boss_defeated,
		"estimated_only": true
	}
	record["reward_preview"] = reward.duplicate(true)
	gate_reward_previewed.emit(reward.duplicate(true))
	return reward


func get_verified_gate_rank(gate_id: String) -> String:
	if not gate_records.has(gate_id):
		return ""
	var record: Dictionary = gate_records[gate_id]
	return str(record.get("verified_rank", "")) if bool(record.get("rank_verified", false)) else ""
