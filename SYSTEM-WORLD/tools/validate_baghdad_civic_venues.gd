extends SceneTree

const SERVICES_SCRIPT = preload("res://scripts/modern_city_services_manager.gd")

func _initialize() -> void:
	var manager = SERVICES_SCRIPT.new()
	var required_ids := ["mosque", "church", "museum", "rare_antique_market", "underworld_exchange", "stadium"]
	var found: Dictionary = {}
	for entry in SERVICES_SCRIPT.SERVICE_DATA:
		found[str(entry.get("id", ""))] = entry
	for service_id in required_ids:
		if not found.has(service_id):
			push_error("Baghdad civic venue validation failed: missing service " + service_id)
			quit(1)
			return
	for service_id in ["mosque", "church", "museum", "rare_antique_market"]:
		var entry: Dictionary = found[service_id]
		if str(entry.get("prompt", "")).is_empty():
			push_error("Baghdad civic venue validation failed: missing interaction prompt for " + service_id)
			quit(1)
			return
	for method_name in ["_create_mosque_details", "_create_church_details", "_create_museum_details", "_create_rare_antique_market_details", "_create_civic_interior_blockout"]:
		if not manager.has_method(method_name):
			push_error("Baghdad civic venue validation failed: missing builder " + method_name)
			quit(1)
			return
	manager.free()
	print("Baghdad civic venue validation passed: mosque, church, museum, rare antiques bazaar and football venue definitions are present.")
	quit(0)
