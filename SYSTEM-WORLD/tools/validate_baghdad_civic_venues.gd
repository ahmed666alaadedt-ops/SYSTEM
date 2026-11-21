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
	for method_name in ["_create_mosque_details", "_create_church_details", "_create_museum_details", "_create_rare_antique_market_details", "_create_civic_structural_shell", "_build_civic_interior"]:
		if not manager.has_method(method_name):
			push_error("Baghdad civic venue validation failed: missing builder " + method_name)
			quit(1)
			return
	var wall_material := StandardMaterial3D.new()
	var glass_material := StandardMaterial3D.new()
	var trim_material := StandardMaterial3D.new()
	for service_id in ["mosque", "church", "museum", "rare_antique_market"]:
		var venue := Node3D.new()
		venue.name = service_id + "_ValidationVenue"
		root.add_child(venue)
		manager.call("_create_civic_structural_shell", venue, service_id, 34.0, 28.0, wall_material, trim_material)
		manager.call("_build_civic_interior", venue, service_id, 34.0, 28.0, wall_material, glass_material, trim_material)
		for required_node in ["CivicLeftWall_Body", "CivicRightWall_Body", "CivicRearWall_Body", "CivicFrontLeft_Body", "CivicFrontRight_Body", "CivicDoorLintel_Body", "CivicInteriorFloorCollision", "CivicInteriorFloor"]:
			if venue.get_node_or_null(required_node) == null:
				push_error("Baghdad civic venue validation failed: missing structural component " + required_node + " in " + service_id)
				quit(1)
				return
		if venue.get_node_or_null("CivicLeftWall_Body/CollisionShape3D") == null:
			push_error("Baghdad civic venue validation failed: wall collision missing in " + service_id)
			quit(1)
			return
		var specific_nodes := {
			"mosque": ["PrayerHallMihrab", "PrayerHallMinbar", "PrayerCarpetRow_00", "PrayerMat_00_00", "PrayerMat_04_09", "CivicInteriorLight_00"],
			"church": ["ChurchAltar", "ChurchLectern", "CivicInteriorLight_00"],
			"museum": ["MuseumReceptionDesk", "MuseumExhibitLabel_00", "CivicInteriorLight_00"],
			"rare_antique_market": ["AntiqueAuctioneerDesk", "AntiqueAppraisalTable", "CivicInteriorLight_00"]
		}
		for required_node in specific_nodes[service_id]:
			if venue.get_node_or_null(required_node) == null:
				push_error("Baghdad civic venue validation failed: missing interior fixture " + required_node + " in " + service_id)
				quit(1)
				return
		venue.queue_free()
	manager.free()
	print("Baghdad civic venue validation passed: four civic interiors have collision-backed walls, entry openings, floors and venue-specific fixtures; mosque includes five prayer rows with individual prayer mats.")
	quit(0)
