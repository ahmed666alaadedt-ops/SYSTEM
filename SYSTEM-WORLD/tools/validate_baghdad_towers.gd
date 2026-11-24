extends SceneTree

const EXPECTED_TOWER_IDS := [
	"hunter_association_tower_baghdad",
	"business_investment_tower_baghdad",
	"shopping_tower_baghdad",
	"entertainment_tower_baghdad",
	"technology_tower_baghdad",
	"power_tower_baghdad"
]

const TOWER_NODE_NAMES := {
	"hunter_association_tower_baghdad": "HunterAssociationTower",
	"business_investment_tower_baghdad": "BusinessInvestmentTower",
	"shopping_tower_baghdad": "ShoppingTower",
	"entertainment_tower_baghdad": "EntertainmentTower",
	"technology_tower_baghdad": "TechnologyTower",
	"power_tower_baghdad": "PowerTower"
}


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load("res://MainScene.tscn") as PackedScene
	if packed_scene == null:
		_fail("MainScene.tscn could not be loaded.")
		return

	var main_scene := packed_scene.instantiate() as Node3D
	if main_scene == null:
		_fail("MainScene.tscn did not instantiate as Node3D.")
		return
	root.add_child(main_scene)

	for frame_index in range(14):
		await process_frame

	var region := main_scene.find_child("ModernWorldRegionManager", true, false) as Node3D
	if region == null:
		_fail("ModernWorldRegionManager was not created by the main scene.")
		return

	var tower_manager := region.get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager == null:
		_fail("BaghdadTowerLandmarksManager was not created.")
		return

	var terrain := tower_manager.get("terrain") as Node3D
	if terrain == null or not terrain.has_method("get_baghdad_bridge_anchor") or not terrain.has_method("get_baghdad_bridge_nearest_bank_anchor"):
		_fail("ModernContinent is missing the verified Baghdad bridge anchor APIs.")
		return
	var bridge_anchor: Vector3 = terrain.call("get_baghdad_bridge_anchor")
	var bridge_bank_anchor: Vector3 = terrain.call("get_baghdad_bridge_nearest_bank_anchor")
	if bridge_anchor == Vector3.INF or absf(bridge_anchor.x - 3563.921) > 2.0 or absf(bridge_anchor.z + 1050.256) > 2.0:
		_fail("Republic Bridge local anchor does not match the verified WGS84/OSM reference.")
		return
	if bridge_bank_anchor == Vector3.INF or bridge_bank_anchor.length() >= bridge_anchor.length():
		_fail("Republic Bridge nearest surveyed bank endpoint is missing or not the nearest approach point.")
		return
	var bridge_node := terrain.get_node_or_null("BaghdadRepublicBridge") as Node3D
	if bridge_node == null or int(bridge_node.get_meta("system_osm_bridge_polygon_way_id", 0)) != 1077808833:
		_fail("Republic Bridge runtime deck is missing or not tied to OSM bridge way 1077808833.")
		return
	if bridge_node.get_node_or_null("RepublicBridgeDeckCollision") == null or bridge_node.get_node_or_null("RepublicBridgeDeck") == null:
		_fail("Republic Bridge has no physical collision deck.")
		return
	if int(bridge_node.get_meta("system_bridge_polygon_points", 0)) < 20 or absf(float(bridge_node.get_meta("system_bridge_deck_height_m", 0.0)) - 18.0) > 0.1:
		_fail("Republic Bridge runtime deck does not use the surveyed polygon and bank-aligned elevation.")
		return
	var tigris := terrain.get_node_or_null("BaghdadTigrisRiver") as MeshInstance3D
	if tigris == null or str(tigris.get_meta("system_geography_source", "")) != "OpenStreetMap way 24709603":
		_fail("Tigris River surface is missing its verified OSM geometry source.")
		return
	var access_causeway := terrain.get_node_or_null("BaghdadBridgeAccessCauseway") as MeshInstance3D
	if access_causeway == null or not bool(access_causeway.get_meta("system_generated_access_route", false)):
		_fail("The playable Baghdad-to-bridge access causeway is missing.")
		return
	if not str(access_causeway.get_meta("system_geography_source", "")).contains("not OpenStreetMap road geometry"):
		_fail("The generated access causeway must be explicitly distinguished from OSM road geometry.")
		return
	var causeway_body := access_causeway.get_node_or_null("BaghdadBridgeAccessCausewayCollision") as StaticBody3D
	var causeway_shape := causeway_body.get_node_or_null("CausewayCollisionShape") as CollisionShape3D if causeway_body != null else null
	if causeway_body == null or causeway_shape == null or causeway_shape.shape == null:
		_fail("The Baghdad bridge access causeway has no physical collision.")
		return
	if not causeway_shape.shape is ConcavePolygonShape3D or (causeway_shape.shape as ConcavePolygonShape3D).get_faces().size() < 100:
		_fail("The Baghdad bridge access causeway collision mesh is empty or incomplete.")
		return
	var causeway_end: Vector3 = access_causeway.get_meta("system_route_end", Vector3.INF)
	if causeway_end == Vector3.INF or Vector2(causeway_end.x, causeway_end.z).distance_to(Vector2(bridge_bank_anchor.x, bridge_bank_anchor.z)) > 1.0:
		_fail("The playable causeway does not terminate at the nearest surveyed bridge bank.")
		return
	# Test only the land approach up to the surveyed near bank. The river itself
	# is crossed on the separately validated Republic Bridge deck, not by
	# demanding that the Tigris water surface be classified as dry land.
	for sample_index in range(1, 19):
		var corridor_fraction := float(sample_index) * 0.05
		var corridor_x := bridge_bank_anchor.x * corridor_fraction
		var corridor_z := bridge_bank_anchor.z * corridor_fraction
		if not bool(terrain.call("is_land_position", corridor_x, corridor_z)):
			var sample_height := float(terrain.call("get_terrain_height", corridor_x, corridor_z))
			var procedural_radius := float(terrain.call("_continent_radius", corridor_x, corridor_z))
			var procedural_land_height := float(terrain.call("_land_base_height", corridor_x, corridor_z))
			_fail(
				"Baghdad bridge approach gap at %.0f%%: world=(%.1f, %.1f), height=%.2f m, continent_radius=%.4f, base_land_height=%.2f m."
				% [corridor_fraction * 100.0, corridor_x, corridor_z, sample_height, procedural_radius, procedural_land_height]
			)
			return

	var records: Array = tower_manager.call("get_tower_positions")
	if records.size() != EXPECTED_TOWER_IDS.size():
		_fail("Expected six Baghdad tower landmarks (five connected plus standalone Power Tower); found %d." % records.size())
		return

	var found_ids: Dictionary = {}
	for record_value in records:
		if typeof(record_value) != TYPE_DICTIONARY:
			_fail("A Baghdad tower landmark record is not a Dictionary.")
			return
		var record: Dictionary = record_value
		found_ids[str(record.get("id", ""))] = true

	for tower_id in EXPECTED_TOWER_IDS:
		if not found_ids.has(tower_id):
			_fail("Missing Baghdad tower landmark ID: " + tower_id)
			return

	if tower_manager.district_tower_positions.size() != 5:
		_fail("The connected Baghdad district must contain exactly five towers.")
		return
	var district_ids: Dictionary = {}
	var hunter_record: Dictionary = {}
	for district_record in tower_manager.district_tower_positions:
		var district_id := str(district_record.get("id", ""))
		if district_ids.has(district_id) or district_id == "power_tower_baghdad":
			_fail("The five-tower district contains a duplicate or standalone Power Tower entry.")
			return
		district_ids[district_id] = true
		var district_position: Vector3 = district_record.get("position", Vector3.INF)
		var district_height := float(district_record.get("height", 0.0))
		var horizontal_distance := Vector2(district_position.x - bridge_anchor.x, district_position.z - bridge_anchor.z).length()
		if horizontal_distance > 900.0:
			_fail("A connected Baghdad tower is outside the Republic Bridge / Tigris district: " + district_id)
			return
		if district_id == "hunter_association_tower_baghdad":
			hunter_record = district_record
			if district_height < 1000.0 or Vector2(district_position.x - bridge_anchor.x, district_position.z - bridge_anchor.z).length() > 0.5 or absf(district_position.y - 418.0) > 0.1:
				_fail("Hunter Association Tower must be the 1000 m central landmark seated on the upper Baghdad sky-city crown platform at 418 m.")
				return
		elif district_height >= 1000.0:
			_fail("A non-Hunter Baghdad district tower incorrectly matches or exceeds the Hunter Tower height.")
			return
		if district_id != "hunter_association_tower_baghdad" and not bool(terrain.call("is_land_position", district_position.x, district_position.z)):
			_fail("A riverbank tower is not supported by playable land: " + district_id)
			return
	for expected_district_id in EXPECTED_TOWER_IDS.slice(0, 5):
		if not district_ids.has(expected_district_id):
			_fail("The connected district is missing approved tower: " + str(expected_district_id))
			return
	var upper_city := tower_manager.get_node_or_null("BaghdadUpperSkyCity") as Node3D
	if upper_city == null or int(upper_city.get_meta("system_upper_city_blocks", 0)) != 4 or not bool(upper_city.get_meta("system_power_tower_excluded", false)):
		_fail("The playable upper Baghdad sky city is missing, incomplete or incorrectly includes Power Tower.")
		return
	if Vector2(upper_city.position.x - bridge_anchor.x, upper_city.position.z - bridge_anchor.z).length() > 0.1 or absf(float(upper_city.get_meta("system_upper_city_elevation_m", 0.0)) - 270.0) > 0.1:
		_fail("The upper Baghdad city is not centered over the five-tower Republic Bridge district at its approved 270 m elevation.")
		return
	var upper_city_blocks := 0
	for city_child in upper_city.get_children():
		if city_child.name.begins_with("UpperCityBlock_"):
			upper_city_blocks += 1
			if city_child.get_node_or_null("UpperCityPlatformCollision") == null:
				_fail("An upper-city block has no physical walkable platform.")
				return
	if upper_city_blocks != 4:
		_fail("The upper city must contain exactly four physical district blocks above the riverbank towers.")
		return
	if upper_city.get_node_or_null("HunterTowerUpperCityAtriumRing") == null or upper_city.get_node_or_null("HunterAtriumWalkway_North_Collision") == null or upper_city.get_node_or_null("HunterAtriumSkyway_00") == null or upper_city.get_node_or_null("UpperCitySkyway_00") == null:
		_fail("The upper city does not provide the Hunter Tower atrium and connected walkable skyways.")
		return
	var central_hunter := tower_manager.get_node_or_null("HunterAssociationTower") as Node3D
	if central_hunter == null or absf(central_hunter.position.y - 418.0) > 0.1:
		_fail("The functional Hunter Association Tower is not physically seated on the uppermost 418 m Baghdad sky-city platform.")
		return
	if str(central_hunter.get_meta("system_hunter_guild_insignia", "")) != "XSX" or int(central_hunter.get_meta("system_hunter_guild_identity_facades", 0)) != 4:
		_fail("The central Hunter Association Tower must display the XSX guild emblem on all four exterior sides.")
		return
	var hunter_emblem := central_hunter.get_node_or_null("HunterXSXEmblemPlaque_00/XSXEmblemText") as Label3D
	if hunter_emblem == null or hunter_emblem.text != "XSX":
		_fail("The central Hunter Association Tower XSX emblem is missing.")
		return
	if tower_manager.get_node_or_null("BaghdadUpperSkyCity/BaghdadSYSTEMCentralSpire") != null:
		_fail("The obsolete decorative central S spire must not coexist with the functional Hunter Association Tower.")
		return

	for district_record in tower_manager.district_tower_positions:
		if str(district_record.get("id", "")) == "power_tower_baghdad":
			_fail("Power Tower was incorrectly added to the connected district.")
			return

	for tower_id in EXPECTED_TOWER_IDS:
		var tower := tower_manager.get_node_or_null(str(TOWER_NODE_NAMES[tower_id])) as Node3D
		if tower == null:
			_fail("Missing tower node for " + tower_id)
			return
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
		if lobby == null:
			_fail("Missing public lobby blockout for " + tower_id)
			return
		if lobby.get_node_or_null("LobbyFloorCollision") == null:
			_fail("Lobby floor collision is missing for " + tower_id)
			return
		if lobby.get_node_or_null("LobbyReceptionCounter_Collision") == null:
			_fail("Lobby reception counter collision is missing for " + tower_id)
			return
		if lobby.get_node_or_null("LobbyLiftDoor_Blockout") == null:
			_fail("Lift-core door blockout is missing for " + tower_id)
			return
		var directory_sign := lobby.get_node_or_null("LobbyDirectorySign") as Label3D
		if directory_sign == null or not directory_sign.text.contains("SYSTEM TOWER DIRECTORY"):
			_fail("Lobby directory sign is missing or has no title for " + tower_id)
			return
		var kiosk := lobby.get_node_or_null("TowerDirectoryInteraction") as Area3D
		if kiosk == null or not kiosk.is_in_group("system_interactable"):
			_fail("Ray-interactable lobby directory kiosk is missing for " + tower_id)
			return
		if str(kiosk.get_meta("system_tower_id", "")) != tower_id:
			_fail("Lobby kiosk has an incorrect tower ID for " + tower_id)
			return
		var floor_directory: Variant = tower.get_meta("tower_floor_directory", PackedStringArray())
		if not floor_directory is PackedStringArray or floor_directory.is_empty():
			_fail("Floor zoning metadata is missing for " + tower_id)
			return

	var hunter_tower := tower_manager.get_node_or_null("HunterAssociationTower") as Node3D
	var hunter_pad := hunter_tower.get_node_or_null("HunterAssociationHelipad") as Node3D if hunter_tower != null else null
	if hunter_pad == null or str(hunter_pad.get_meta("system_landing_zone_status", "")) != "operational_controller_attached" or hunter_pad.get_node_or_null("HunterAssociationHelicopter") == null:
		_fail("Hunter Tower rooftop helicopter pad is not connected to its live flight controller and aircraft.")
		return
	if hunter_record.is_empty() or hunter_pad.position.y <= float(hunter_record.get("height", 0.0)):
		_fail("Hunter helicopter pad must be physically positioned above the tallest Hunter Tower roof.")
		return
	var hunter_facades := hunter_tower.get_node_or_null("HunterTowerAdvertisingFacades") as Node3D if hunter_tower != null else null
	if hunter_facades == null or int(hunter_facades.get_meta("system_advertising_screen_count", 0)) < 12:
		_fail("Hunter Tower exterior advertising facades are missing or incomplete.")
		return
	var hunter_lobby := hunter_tower.get_node_or_null("PublicLobby_Blockout") as Node3D if hunter_tower != null else null
	if hunter_lobby == null or hunter_lobby.get_node_or_null("InteriorAdvertisingFrame_Left") == null or hunter_lobby.get_node_or_null("InteriorAdvertisingFrame_Right") == null:
		_fail("Hunter Tower internal advertising facades are missing.")
		return
	var tunnel_root := tower_manager.get_node_or_null("BaghdadHunterExaminationTunnel") as Node3D
	if tunnel_root == null or not bool(tunnel_root.get_meta("system_under_republic_bridge_district", false)):
		_fail("Hunter examination tunnel is not anchored beneath the Republic Bridge tower district.")
		return

	var shopping_tower := tower_manager.get_node_or_null("ShoppingTower") as Node3D
	if shopping_tower == null:
		_fail("Shopping and Commerce Tower is missing.")
		return
	var shopping_categories: PackedStringArray = shopping_tower.get_meta("facility_categories", PackedStringArray())
	var elixir_categories: PackedStringArray = shopping_tower.get_meta("elixir_categories", PackedStringArray())
	var hospitality_categories: PackedStringArray = shopping_tower.get_meta("hospitality_categories", PackedStringArray())
	if not shopping_categories.has("swords") or not shopping_categories.has("armor") or not shopping_categories.has("hotel") or not shopping_categories.has("restaurants"):
		_fail("Shopping Tower is missing weapons, armour, restaurant or hotel facility categories.")
		return
	if not elixir_categories.has("nen_acquisition") or not elixir_categories.has("healing") or not elixir_categories.has("rare_and_legendary_elixirs"):
		_fail("Shopping Tower is missing Nen/healing/rare elixir categories.")
		return
	if not hospitality_categories.has("hotel_reception") or not hospitality_categories.has("guest_rooms") or not hospitality_categories.has("room_service"):
		_fail("Shopping Tower is missing hotel and hospitality departments.")
		return
	if tower_manager.get_node_or_null("WeaponsEquipmentElixirsTower") != null:
		_fail("Obsolete standalone Weapons/Equipment/Elixirs Tower must not exist in Baghdad.")
		return

	var power_tower := tower_manager.get_node_or_null("PowerTower")
	if int(power_tower.get_meta("tower_floor_count", 0)) != 200:
		_fail("Standalone Power Tower must retain 200 floors.")
		return
	if bool(power_tower.get_meta("tower_is_connected_district_member", true)):
		_fail("Power Tower must remain outside the connected five-tower district.")
		return

	var public_board := region.get_node_or_null("SYSTEMPublicEventBoard")
	if public_board == null:
		_fail("SYSTEMPublicEventBoard was not created.")
		return
	var result_labels: Dictionary = public_board.get("result_labels")
	if not result_labels.has("Baghdad Tower technology_tower_baghdad"):
		_fail("Technology Tower is missing from the public event-board node map.")
		return

	print("Baghdad tower validation passed: verified Republic Bridge and Tigris runtime geometry, five towers on both riverbanks/bridge, upper sky city, standalone Power Tower, Hunter rooftop helicopter controller, internal/external ads, tunnel anchor, six lobby kiosks and Shopping Tower facilities.")
	# This is a short-lived headless validation process; avoid forcing dummy-renderer teardown of placeholder meshes.
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad tower validation failed: " + message)
	quit(1)
