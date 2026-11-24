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
	if terrain == null or not terrain.has_method("get_baghdad_bridge_anchor"):
		_fail("ModernContinent is missing the verified Baghdad bridge anchor API.")
		return
	var bridge_anchor: Vector3 = terrain.call("get_baghdad_bridge_anchor")
	if bridge_anchor == Vector3.INF or absf(bridge_anchor.x - 3563.921) > 2.0 or absf(bridge_anchor.z + 1050.256) > 2.0:
		_fail("Republic Bridge local anchor does not match the verified WGS84/OSM reference.")
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
	for corridor_fraction in [0.25, 0.5, 0.75]:
		var corridor_x := bridge_anchor.x * float(corridor_fraction)
		var corridor_z := bridge_anchor.z * float(corridor_fraction)
		if not bool(terrain.call("is_land_position", corridor_x, corridor_z)):
			_fail("Baghdad playable land corridor is broken between the city core and Republic Bridge.")
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
	for district_record in tower_manager.district_tower_positions:
		var district_position: Vector3 = district_record.get("position", Vector3.INF)
		var horizontal_distance := Vector2(district_position.x - bridge_anchor.x, district_position.z - bridge_anchor.z).length()
		if horizontal_distance > 900.0:
			_fail("A connected Baghdad tower is outside the Republic Bridge / Tigris district: " + str(district_record.get("id", "unknown")))
			return
		if str(district_record.get("id", "")) != "hunter_association_tower_baghdad" and not bool(terrain.call("is_land_position", district_position.x, district_position.z)):
			_fail("A riverbank tower is not supported by playable land: " + str(district_record.get("id", "unknown")))
			return
	var upper_city := tower_manager.get_node_or_null("BaghdadUpperSkyCity") as Node3D
	if upper_city == null or int(upper_city.get_meta("system_upper_city_blocks", 0)) != 4 or not bool(upper_city.get_meta("system_power_tower_excluded", false)):
		_fail("The playable upper Baghdad sky city is missing, incomplete or incorrectly includes Power Tower.")
		return
	if upper_city.get_node_or_null("HunterTowerUpperCityAtriumRing") == null or upper_city.get_node_or_null("HunterAtriumWalkway_North_Collision") == null or upper_city.get_node_or_null("HunterAtriumSkyway_00") == null:
		_fail("The upper city does not provide a walkable Hunter Tower atrium and connected skyways.")
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
