extends SceneTree

const SERVICES_SCRIPT = preload("res://scripts/modern_city_services_manager.gd")

func _has_collision_shape(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape3D and child.shape != null and not child.disabled:
			return true
	return false


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
		for wall_body_name in ["CivicLeftWall_Body", "CivicRightWall_Body", "CivicRearWall_Body", "CivicFrontLeft_Body", "CivicFrontRight_Body", "CivicDoorLintel_Body"]:
			var wall_body: Node = venue.get_node_or_null(wall_body_name)
			if wall_body == null or not _has_collision_shape(wall_body):
				push_error("Baghdad civic venue validation failed: collision-backed wall missing in " + service_id + " at " + wall_body_name)
				quit(1)
				return
		var floor_collision: Node = venue.get_node_or_null("CivicInteriorFloorCollision")
		if floor_collision == null or not _has_collision_shape(floor_collision):
			push_error("Baghdad civic venue validation failed: floor collision missing in " + service_id)
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

	var stadium := Node3D.new()
	stadium.name = "BaghdadStadiumValidation"
	root.add_child(stadium)
	manager.call("_create_stadium_details", stadium, 150.0, 180.0)
	manager.call("_build_baghdad_stadium_facilities", stadium, 105.0, 68.0)
	for required_node in [
		"StadiumNorthConcourseFloor", "StadiumSouthConcourseFloor",
		"StadiumGate_north_Interaction", "StadiumGate_south_Interaction",
		"StadiumGate_east_Interaction", "StadiumGate_west_Interaction",
		"HomeTeamLockerRoom", "AwayTeamLockerRoom", "RefereeRoom",
		"MedicalRoom", "MediaRoom", "PressConferenceRoom",
		"PlayerTunnelFloor", "StadiumFloodlight_00", "BaghdadStadiumScoreboard"
	]:
		if stadium.get_node_or_null(required_node) == null:
			push_error("Baghdad stadium validation failed: missing physical facility " + required_node)
			quit(1)
			return
	if stadium.get_node_or_null("HomeTeamLockerRoom/RoomFloor/CollisionShape3D") == null:
		push_error("Baghdad stadium validation failed: locker room floor collision is missing.")
		quit(1)
		return
	if stadium.get_node_or_null("HomeTeamLockerRoom/RoomEntranceInteraction") == null:
		push_error("Baghdad stadium validation failed: locker room entry interaction is missing.")
		quit(1)
		return
	stadium.queue_free()
	manager.free()
	print("Baghdad civic venue validation passed: civic interiors plus the Baghdad stadium's collision-backed concourses, four gates, walk-in team/referee/medical/media rooms, player tunnel, floodlights and scoreboard.")
	quit(0)
