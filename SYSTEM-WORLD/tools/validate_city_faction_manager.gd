extends SceneTree

const FACTION_SCRIPT = preload("res://scripts/system_city_faction_manager.gd")

func _initialize() -> void:
	var manager = FACTION_SCRIPT.new()
	var expected_roles := ["street_crew", "smuggling_ring", "black_market_broker"]
	var records: Array[Dictionary] = manager.get_city_factions("Baghdad")
	if records.size() != 3:
		push_error("City faction validation failed: Baghdad should register three original factions.")
		quit(1)
		return
	for role in expected_roles:
		var found := false
		for record in records:
			if str(record.get("role", "")) == role:
				found = true
				if str(record.get("id", "")).is_empty() or str(record.get("district", "")).is_empty():
					push_error("City faction validation failed: faction identity or district is missing.")
					quit(1)
					return
		if not found:
			push_error("City faction validation failed: missing role " + role)
			quit(1)
			return
	var protected: Array = records[0].get("protected_service_exclusion", [])
	for service_type in ["hospital", "school", "university", "mosque", "church"]:
		if not protected.has(service_type):
			push_error("City faction validation failed: protected venue exclusion missing " + service_type)
			quit(1)
			return
	var faction_id := str(records[0].get("id", ""))
	var standing: Dictionary = manager.adjust_player_standing(faction_id, 12, "validator")
	if not bool(standing.get("success", false)) or manager.get_player_standing(faction_id) != 12:
		push_error("City faction validation failed: local standing update did not apply.")
		quit(1)
		return
	manager.free()
	print("City faction validation passed: Baghdad factions, roles, protected civic venues and reputation API.")
	quit(0)
