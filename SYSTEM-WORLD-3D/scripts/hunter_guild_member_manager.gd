extends Node

# SYSTEM WORLD - Hunter Guild Member Roster
# Prototype NPC roster, rank eligibility, team recommendations and guild XP.

signal roster_changed
signal member_rank_up(member_id: String, new_rank: String)

const RANKS := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "EX"]
var members: Dictionary = {}
var guild_manager: Node

func setup(guild_gate_manager: Node) -> void:
	guild_manager = guild_gate_manager
	_create_initial_roster()
	if is_instance_valid(guild_manager) and guild_manager.has_signal("gate_cleared"):
		guild_manager.connect("gate_cleared", Callable(self, "_on_gate_cleared"))
	print("SYSTEM: Hunter Guild roster initialized.")

func _create_initial_roster() -> void:
	var roster := [
		["HNT-001", "ليث", "B", "fighter", 82, 58, 42, 35],
		["HNT-002", "سارة", "A", "scout", 55, 94, 61, 48],
		["HNT-003", "نور", "C", "healer", 48, 62, 88, 72],
		["HNT-004", "كرار", "D", "fighter", 74, 46, 38, 40],
		["HNT-005", "مريم", "B", "support", 61, 67, 79, 91],
		["HNT-006", "آدم", "S", "fighter", 96, 76, 65, 58],
		["HNT-007", "زينب", "E", "scout", 42, 81, 54, 43],
		["HNT-008", "حيدر", "C", "tank", 88, 43, 55, 63],
		["HNT-009", "رنا", "A", "healer", 57, 78, 97, 86],
		["HNT-010", "يوسف", "F", "support", 35, 54, 72, 89]
	]
	for item in roster:
		members[item[0]] = {
			"id": item[0], "name": item[1], "rank": item[2],
			"role": item[3], "combat": item[4], "scouting": item[5],
			"healing": item[6], "support": item[7], "guild_xp": 0,
			"missions_completed": 0, "available": true
		}
	roster_changed.emit()

func get_roster() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member_id in members:
		result.append(members[member_id].duplicate(true))
	return result

func get_member(member_id: String) -> Dictionary:
	if not members.has(member_id):
		return {}
	return members[member_id].duplicate(true)

func recommend_team(gate_id: String, requested_size: int = 4) -> Array[String]:
	if not is_instance_valid(guild_manager):
		return []
	var report: Dictionary = guild_manager.call("get_gate_report", gate_id)
	if report.is_empty():
		return []
	var required_rank := str(report.get("verified_rank", report.get("rank", "F")))
	var required_index := maxi(0, RANKS.find(required_rank))
	var candidates: Array[Dictionary] = []
	for member_id in members:
		var member: Dictionary = members[member_id]
		if not bool(member.get("available", true)):
			continue
		var member_index := maxi(0, RANKS.find(str(member.get("rank", "F"))))
		if member_index < required_index - 2:
			continue
		var score := _member_score(member, required_rank)
		var candidate := member.duplicate(true)
		candidate["team_score"] = score
		candidates.append(candidate)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("team_score", 0)) > int(b.get("team_score", 0))
	)
	var team: Array[String] = []
	var wanted := clampi(requested_size, 1, 8)
	var role_counts := {"fighter": 0, "tank": 0, "healer": 0, "support": 0, "scout": 0}
	for candidate in candidates:
		if team.size() >= wanted:
			break
		var role := str(candidate.get("role", "fighter"))
		if role == "healer" and int(role_counts["healer"]) >= 1:
			continue
		if role == "tank" and int(role_counts["tank"]) >= 1:
			continue
		team.append(str(candidate["id"]))
		role_counts[role] = int(role_counts.get(role, 0)) + 1
	for candidate in candidates:
		if team.size() >= wanted:
			break
		var candidate_id := str(candidate["id"])
		if not team.has(candidate_id):
			team.append(candidate_id)
	return team

func get_team_summary(member_ids: Array) -> Dictionary:
	var summary := {"members": [], "combat": 0, "scouting": 0, "healing": 0, "support": 0, "average_rank": "F"}
	var rank_total := 0
	for member_id in member_ids:
		if not members.has(str(member_id)):
			continue
		var member: Dictionary = members[str(member_id)]
		summary["members"].append(member.duplicate(true))
		for stat in ["combat", "scouting", "healing", "support"]:
			summary[stat] = int(summary[stat]) + int(member.get(stat, 0))
		rank_total += maxi(0, RANKS.find(str(member.get("rank", "F"))))
	var count := int(summary["members"].size())
	if count > 0:
		for stat in ["combat", "scouting", "healing", "support"]:
			summary[stat] = int(round(float(summary[stat]) / count))
		summary["average_rank"] = RANKS[clampi(int(round(float(rank_total) / count)), 0, RANKS.size() - 1)]
	return summary

func _member_score(member: Dictionary, gate_rank: String) -> int:
	var role := str(member.get("role", "fighter"))
	var score := int(member.get("combat", 0)) + int(member.get("support", 0))
	if role == "scout":
		score += int(member.get("scouting", 0))
	elif role == "healer":
		score += int(member.get("healing", 0)) * 2
	elif role == "tank":
		score += int(member.get("combat", 0)) / 2
	var rank_gap := maxi(0, RANKS.find(gate_rank) - RANKS.find(str(member.get("rank", "F"))))
	return score - rank_gap * 18

func _on_gate_cleared(report: Dictionary) -> void:
	var gate_id := str(report.get("gate_id", ""))
	var team: Array = report.get("assigned_team", [])
	var reward: Dictionary = guild_manager.call("calculate_clear_reward", gate_id, false)
	var xp_share := maxi(1, int(reward.get("guild_xp", 40)) / maxi(1, team.size()))
	for member_id in team:
		if not members.has(str(member_id)):
			continue
		var member: Dictionary = members[str(member_id)]
		member["guild_xp"] = int(member.get("guild_xp", 0)) + xp_share
		member["missions_completed"] = int(member.get("missions_completed", 0)) + 1
		_check_rank_up(member)
	roster_changed.emit()

func _check_rank_up(member: Dictionary) -> void:
	var current_index := RANKS.find(str(member.get("rank", "F")))
	if current_index < 0 or current_index >= RANKS.size() - 1:
		return
	var thresholds := [0, 100, 250, 500, 900, 1500, 2400, 3600, 5200, 7500]
	if int(member.get("guild_xp", 0)) >= thresholds[current_index + 1]:
		member["rank"] = RANKS[current_index + 1]
		member["guild_xp"] = 0
		member_rank_up.emit(str(member.get("id", "")), str(member["rank"]))
