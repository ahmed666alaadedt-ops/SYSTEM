extends SceneTree

const BAGHDAD_DISTRICT_TOWER_IDS := [
	"hunter_association_tower_baghdad",
	"business_investment_tower_baghdad",
	"shopping_tower_baghdad",
	"antiques_heritage_tower_baghdad",
	"technology_tower_baghdad"
]

# Power Tower is validated as a separate facility, never as a sixth Baghdad tower.
const STANDALONE_FACILITY_IDS := ["power_tower_baghdad"]
const ALL_VALIDATED_FACILITY_IDS := BAGHDAD_DISTRICT_TOWER_IDS + STANDALONE_FACILITY_IDS

const TOWER_NODE_NAMES := {
	"hunter_association_tower_baghdad": "HunterAssociationTower",
	"business_investment_tower_baghdad": "BusinessInvestmentTower",
	"shopping_tower_baghdad": "ShoppingTower",
	"antiques_heritage_tower_baghdad": "AntiquesHeritageTower",
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
	var bridge_centerline_markings := bridge_node.get_node_or_null("RepublicBridgeCenterlineMarkings") as MeshInstance3D
	var bridge_lane_markings := bridge_node.get_node_or_null("RepublicBridgeLaneMarkings") as MeshInstance3D
	var bridge_guardrail_posts := bridge_node.get_node_or_null("RepublicBridgeGuardrailPosts") as MultiMeshInstance3D
	var bridge_light_poles := bridge_node.get_node_or_null("RepublicBridgeLightPoles") as MultiMeshInstance3D
	var bridge_lamp_heads := bridge_node.get_node_or_null("RepublicBridgeLampHeads") as MultiMeshInstance3D
	if bridge_centerline_markings == null or bridge_lane_markings == null:
		_fail("Republic Bridge is missing the surveyed yellow centerline or white lane markings.")
		return
	if bridge_guardrail_posts == null or bridge_guardrail_posts.multimesh == null or bridge_guardrail_posts.multimesh.instance_count < 8:
		_fail("Republic Bridge is missing its instanced guardrail safety posts.")
		return
	if bridge_light_poles == null or bridge_lamp_heads == null or bridge_light_poles.multimesh == null or bridge_lamp_heads.multimesh == null:
		_fail("Republic Bridge is missing its instanced street-light poles or emissive lamp heads.")
		return
	if bridge_light_poles.multimesh.instance_count < 2 or bridge_lamp_heads.multimesh.instance_count != bridge_light_poles.multimesh.instance_count:
		_fail("Republic Bridge street-light poles and lamp heads are incomplete or mismatched.")
		return
	var bridge_joints := bridge_node.get_node_or_null("RepublicBridgeExpansionJoints") as MeshInstance3D
	if bridge_joints == null:
		_fail("Republic Bridge is missing its transverse expansion-joint detail.")
		return
	var tigris := terrain.get_node_or_null("BaghdadTigrisRiver") as MeshInstance3D
	if tigris == null or str(tigris.get_meta("system_geography_source", "")) != "OpenStreetMap way 24709603":
		_fail("Tigris River surface is missing its verified OSM geometry source.")
		return
	if str(tigris.get_meta("system_water_shader", "")) != "world_space_animated_ripples" or tigris.mesh == null:
		_fail("Tigris River is missing its animated world-space water surface.")
		return
	var tigris_material := tigris.material_override as ShaderMaterial
	if tigris_material == null or tigris_material.shader == null or not tigris_material.shader.code.contains("TIME"):
		_fail("Tigris River shader is missing its time-driven wave and shimmer animation.")
		return
	var tigris_foam := terrain.get_node_or_null("BaghdadTigrisBankFoam") as MeshInstance3D
	if tigris_foam == null or str(tigris_foam.get_meta("system_water_edge_detail", "")) != "soft_bank_foam":
		_fail("Tigris River is missing its two-bank foam edge detail.")
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
	if records.size() != ALL_VALIDATED_FACILITY_IDS.size():
		_fail("Expected five Baghdad district towers plus one separate Power Tower facility; found %d." % records.size())
		return

	var found_ids: Dictionary = {}
	for record_value in records:
		if typeof(record_value) != TYPE_DICTIONARY:
			_fail("A Baghdad tower landmark record is not a Dictionary.")
			return
		var record: Dictionary = record_value
		found_ids[str(record.get("id", ""))] = true

	for tower_id in ALL_VALIDATED_FACILITY_IDS:
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
			if district_height < 650.0 or Vector2(district_position.x - bridge_anchor.x, district_position.z - bridge_anchor.z).length() > 0.5 or absf(district_position.y - 419.2) > 0.1:
				_fail("Hunter Association Tower must be the 650 m central landmark seated on the upper Baghdad sky-city crown platform at 418 m.")
				return
		elif district_height >= 650.0:
			_fail("A non-Hunter Baghdad district tower incorrectly matches or exceeds the Hunter Tower height.")
			return
		if district_id != "hunter_association_tower_baghdad" and not bool(terrain.call("is_land_position", district_position.x, district_position.z)):
			_fail("A riverbank tower is not supported by playable land: " + district_id)
			return
	for expected_district_id in BAGHDAD_DISTRICT_TOWER_IDS:
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
	if upper_city.get_node_or_null("UpperCitySkyway_00_LeftSafetyRail") == null or upper_city.get_node_or_null("UpperCitySkyway_00_RightSafetyRail") == null or upper_city.get_node_or_null("HunterAtriumSkyway_00_LeftSafetyRail") == null:
		_fail("Upper-city pedestrian skyways are missing their architectural safety rails.")
		return
	var upper_platform := upper_city.get_node_or_null("ReferenceSkyPlatform_Upper") as MeshInstance3D
	if upper_platform == null or not bool(upper_platform.get_meta("system_platform_safety_railings", false)) or int(upper_platform.get_meta("system_platform_guardrail_balusters", 0)) != 32 or upper_city.get_node_or_null("ReferenceSkyPlatform_Upper_PerimeterGuardrail") == null:
		_fail("The upper circular sky platform is missing its illuminated perimeter guardrail and balusters.")
		return
	for district_id in BAGHDAD_DISTRICT_TOWER_IDS:
		var district_node_name := str(TOWER_NODE_NAMES[district_id])
		var district_tower := tower_manager.get_node_or_null(district_node_name) as Node3D
		var facade_accents := district_tower.get_node_or_null("CinematicFacadeAccents") as Node3D if district_tower != null else null
		if facade_accents == null or not bool(facade_accents.get_meta("system_cinematic_facade", false)):
			_fail("A Baghdad district tower is missing its cinematic facade lighting: " + district_id)
			return
		if int(facade_accents.get_meta("system_vertical_light_count", 0)) != 4 or int(facade_accents.get_meta("system_skyline_halo_count", 0)) != 3:
			_fail("A Baghdad district tower has incomplete cinematic facade accents: " + district_id)
			return
	var standalone_power_tower := tower_manager.get_node_or_null("PowerTower") as Node3D
	if standalone_power_tower == null or standalone_power_tower.get_node_or_null("CinematicFacadeAccents") != null:
		_fail("The standalone Power Tower must remain visually separate from the five-tower Baghdad district treatment.")
		return
	var central_hunter := tower_manager.get_node_or_null("HunterAssociationTower") as Node3D
	if central_hunter == null or absf(central_hunter.position.y - 419.2) > 0.1:
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

	for tower_id in ALL_VALIDATED_FACILITY_IDS:
		var tower := tower_manager.get_node_or_null(str(TOWER_NODE_NAMES[tower_id])) as Node3D
		if tower == null:
			_fail("Missing tower node for " + tower_id)
			return
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
		if lobby == null:
			_fail("Missing public lobby blockout for " + tower_id)
			return
		if str(lobby.get_meta("system_visual_finish_layer", "")) != "architectural_lobby_finish_v1":
			_fail("Architectural lobby finish layer is missing for " + tower_id)
			return
		if lobby.get_node_or_null("FinishLobbyIdentityPlate") == null or lobby.get_node_or_null("FinishFloorCenterInlay") == null or lobby.get_node_or_null("FinishCeilingBeam_Left") == null:
			_fail("Finished lobby identity, floor inlay or ceiling lighting is missing for " + tower_id)
			return
		if int(lobby.get_meta("system_visual_finish_piece_count", 0)) < 20:
			_fail("Lobby visual finish layer has too few architectural pieces for " + tower_id)
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
		if str(tower.get_meta("system_tower_visual_finish", "")) != "facade_fins_belts_and_crown_v1" or tower.get_node_or_null("FacadeFinishFin_00") == null or tower.get_node_or_null("FacadeFinishCrownRing") == null:
			_fail("Tower facade finish fins, identity belts or crown are missing for " + tower_id)
			return
		var floor_directory: Variant = tower.get_meta("tower_floor_directory", PackedStringArray())
		if not floor_directory is PackedStringArray or floor_directory.is_empty():
			_fail("Floor zoning metadata is missing for " + tower_id)
			return

	# Verify the actual procedural architecture on every tower, not only its lobby metadata.
	const IDENTITY_NODES_BY_TOWER := {
		"hunter_association_tower_baghdad": ["HunterXSXEmblemPlaque_00", "HunterXSXEmblemPlaque_01", "HunterXSXEmblemPlaque_02", "HunterXSXEmblemPlaque_03"],
		"business_investment_tower_baghdad": ["BusinessCapitalSpire", "BusinessCapitalRing_00", "BusinessCapitalRing_01", "BusinessCapitalRing_02", "BusinessInvestmentSign"],
		"shopping_tower_baghdad": ["RetailGalleryRing_00", "RetailGalleryRing_01", "RetailGalleryRing_02", "ShoppingAtriumSign", "ShoppingTowerWeaponBlade_left", "ShoppingTowerWeaponBlade_right", "ShoppingTowerElixirBeacon"],
		"antiques_heritage_tower_baghdad": ["HeritageMuseumPodium", "HeritageMuseumEntranceCanopy", "HeritageGalleryWing_left", "HeritageGalleryWing_right", "HeritageGalleryColumn_left", "HeritageGalleryColumn_right", "HeritageArchiveCrown"],
		"technology_tower_baghdad": ["InnovationAntenna_00", "InnovationAntenna_01", "InnovationAntenna_02", "InnovationLabSkyRibbon"],
		"power_tower_baghdad": ["TournamentBlade_left", "TournamentBlade_right", "PowerTowerChampionCrown"]
	}
	for tower_id in ALL_VALIDATED_FACILITY_IDS:
		var architecture_tower := tower_manager.get_node_or_null(str(TOWER_NODE_NAMES[tower_id])) as Node3D
		if architecture_tower == null:
			_fail("Architecture audit could not resolve tower: " + tower_id)
			return
		if architecture_tower.get_node_or_null("MonumentalFoundation") == null or architecture_tower.get_node_or_null("TowerMainShaft") == null or architecture_tower.get_node_or_null("IlluminatedIdentityRing") == null:
			_fail("A tower is missing its foundation, main shaft or illuminated identity ring: " + tower_id)
			return
		var structure := architecture_tower.get_node_or_null("TowerStructureCollision") as StaticBody3D
		if structure == null:
			_fail("A tower is missing its physical structural collision body: " + tower_id)
			return
		var structural_collision_count := 0
		for structural_child in structure.get_children():
			if structural_child is CollisionShape3D and structural_child.shape != null:
				structural_collision_count += 1
		if structural_collision_count < 2:
			_fail("A tower must have both foundation and shaft collision volumes: " + tower_id)
			return
		for podium_index in range(3):
			if architecture_tower.get_node_or_null("PodiumTerrace_%d" % podium_index) == null:
				_fail("A tower is missing a podium terrace: " + tower_id)
				return
		for fin_index in range(4):
			if architecture_tower.get_node_or_null("FacadeFin_%d" % fin_index) == null:
				_fail("A tower is missing one of its four vertical facade fins: " + tower_id)
				return
		var glazing := architecture_tower.get_node_or_null("FacadeGlazingPanels") as MultiMeshInstance3D
		var tower_floors := int(architecture_tower.get_meta("tower_floor_count", 0))
		if glazing == null or glazing.multimesh == null or glazing.multimesh.instance_count != tower_floors * 20 or int(architecture_tower.get_meta("system_facade_window_count", 0)) != tower_floors * 20:
			_fail("A tower's procedural glass facade does not cover all 20 facade segments on every floor: " + tower_id)
			return
		for identity_node_name in IDENTITY_NODES_BY_TOWER[tower_id]:
			if architecture_tower.get_node_or_null(str(identity_node_name)) == null:
				_fail("A tower is missing its approved architectural identity feature %s: %s" % [str(identity_node_name), tower_id])
				return

	var hunter_tower := tower_manager.get_node_or_null("HunterAssociationTower") as Node3D
	var hunter_pad := hunter_tower.get_node_or_null("HunterAssociationHelipad") as Node3D if hunter_tower != null else null
	if hunter_pad == null or str(hunter_pad.get_meta("system_landing_zone_status", "")) != "operational_controller_attached" or hunter_pad.get_node_or_null("HunterAssociationHelicopter") == null:
		_fail("Hunter Tower rooftop helicopter pad is not connected to its live flight controller and aircraft.")
		return
	var helipad_deck := hunter_pad.get_node_or_null("HelipadDeck") as MeshInstance3D
	var helipad_deck_shape := hunter_pad.get_node_or_null("HelipadDeckCollision/CollisionShape3D") as CollisionShape3D
	var helipad_bridge := hunter_pad.get_node_or_null("HelipadAccessBridge") as MeshInstance3D
	var helipad_bridge_shape := hunter_pad.get_node_or_null("HelipadAccessBridgeCollision/CollisionShape3D") as CollisionShape3D
	var landing_ring := hunter_pad.get_node_or_null("LandingCircleMarking") as MeshInstance3D
	var helipad_sign := hunter_pad.get_node_or_null("HelipadIdentitySign") as Label3D
	if helipad_deck == null or helipad_deck_shape == null or not (helipad_deck_shape.shape is CylinderShape3D):
		_fail("Hunter rooftop helipad is missing its physical circular deck collision.")
		return
	if helipad_bridge == null or helipad_bridge_shape == null or not (helipad_bridge_shape.shape is BoxShape3D):
		_fail("Hunter rooftop helipad is missing its collidable access bridge.")
		return
	if landing_ring == null or helipad_sign == null:
		_fail("Hunter rooftop helipad is missing its landing-circle marking or identity sign.")
		return
	for marking_name in ["HelipadH_Left", "HelipadH_Right", "HelipadH_Crossbar"]:
		if hunter_pad.get_node_or_null(marking_name) == null:
			_fail("Hunter rooftop helipad is missing an H landing marking: " + marking_name)
			return
	var helipad_light_count := 0
	for child in hunter_pad.get_children():
		if child.name.begins_with("HelipadPerimeterLight_"):
			helipad_light_count += 1
	if helipad_light_count != 8:
		_fail("Hunter rooftop helipad must have eight perimeter lights; found %d." % helipad_light_count)
		return
	var helicopter_status: Dictionary = hunter_pad.call("get_helicopter_status")
	if not bool(helicopter_status.get("available", false)) or str(helicopter_status.get("owner_tower_id", "")) != "hunter_association_tower_baghdad" or not is_equal_approx(float(helicopter_status.get("landing_radius_m", 0.0)), 18.0):
		_fail("Hunter helicopter controller does not report the expected owner, availability and 18 m landing radius.")
		return
	var helicopter_test_player := main_scene.find_child("Player", true, false) as CharacterBody3D
	if helicopter_test_player == null:
		_fail("A canonical player is required to validate helicopter pilot authorization and takeoff.")
		return
	var had_original_hunter_rank := helicopter_test_player.has_meta("system_hunter_rank")
	var original_hunter_rank: Variant = helicopter_test_player.get_meta("system_hunter_rank", "")
	var original_player_position := helicopter_test_player.global_position
	var original_aircraft_position: Vector3 = (hunter_pad.get_node("HunterAssociationHelicopter") as Node3D).global_position
	if not bool(hunter_pad.call("_is_aircraft_position_clear", original_aircraft_position)):
		_fail("The helicopter's own helipad deck is still blocking its parked flight-clearance volume.")
		return
	helicopter_test_player.set_meta("system_hunter_rank", "S")
	if not bool(hunter_pad.call("_can_pilot")):
		_fail("An S-rank Hunter was incorrectly denied helicopter pilot authorization.")
		return
	helicopter_test_player.set_meta("system_hunter_rank", "A")
	if bool(hunter_pad.call("_can_pilot")):
		_fail("An A-rank Hunter was incorrectly granted helicopter pilot authorization.")
		return
	helicopter_test_player.set_meta("system_hunter_rank", "S")
	hunter_pad.call("_enter_aircraft")
	hunter_pad.set("vertical_input", 1.0)
	hunter_pad.call("_update_flight", 0.5)
	var takeoff_position: Vector3 = hunter_pad.get_node("HunterAssociationHelicopter").global_position
	if not bool(hunter_pad.get("pilot_active")) or takeoff_position.y <= original_aircraft_position.y + 0.1:
		_fail("Authorized helicopter pilot could not lift the aircraft clear of its own landing deck.")
		return
	# Restore the parked aircraft and player after the takeoff regression.
	hunter_pad.get_node("HunterAssociationHelicopter").global_position = original_aircraft_position
	hunter_pad.set("heli_position", original_aircraft_position)
	hunter_pad.set("landed", true)
	hunter_pad.call("_exit_aircraft")
	helicopter_test_player.global_position = original_player_position
	if had_original_hunter_rank:
		helicopter_test_player.set_meta("system_hunter_rank", original_hunter_rank)
	else:
		helicopter_test_player.remove_meta("system_hunter_rank")
	if not helicopter_test_player.visible or bool(helicopter_test_player.get_meta("system_helicopter_piloting", false)):
		_fail("Exiting the parked helicopter did not restore the player visibility and piloting state.")
		return

	var parked_aircraft := hunter_pad.get_node_or_null("HunterAssociationHelicopter") as Node3D
	if parked_aircraft.get_node_or_null("HelicopterFuselage") == null or parked_aircraft.get_node_or_null("MainRotor") == null or parked_aircraft.get_node_or_null("TailRotor") == null:
		_fail("Hunter rooftop helicopter is missing its fuselage or rotor assemblies.")
		return
	if hunter_record.is_empty() or hunter_pad.position.y <= float(hunter_record.get("height", 0.0)):
		_fail("Hunter helicopter pad must be physically positioned above the tallest Hunter Tower roof.")
		return
	if not bool(hunter_tower.get_meta("system_hunter_roof_clearance_reserved", false)) or hunter_tower.get_node_or_null("Crown") != null:
		_fail("Hunter Tower's rooftop helipad clearance is obstructed by the generic solid crown.")
		return
	if hunter_tower.get_node_or_null("AssociationCrownSpire") != null:
		_fail("The obsolete central Hunter crown spire must not obstruct the rooftop helicopter pad.")
		return
	for mast_index in range(4):
		if hunter_tower.get_node_or_null("HunterRoofBeaconMast_%02d" % mast_index) == null:
			_fail("Hunter rooftop perimeter beacon mast is missing: %d" % mast_index)
			return
	var hunter_beacon := hunter_tower.get_node_or_null("SkyBeacon") as OmniLight3D
	if hunter_beacon == null or hunter_beacon.position.x < 22.0:
		_fail("Hunter Tower's rooftop beacon must sit outside the helicopter landing circle.")
		return
	var hunter_facades := hunter_tower.get_node_or_null("HunterTowerAdvertisingFacades") as Node3D if hunter_tower != null else null
	if hunter_facades == null or int(hunter_facades.get_meta("system_advertising_screen_count", 0)) < 12:
		_fail("Hunter Tower exterior advertising facades are missing or incomplete.")
		return
	if int(hunter_facades.get_meta("system_hunter_ad_tier_halo_count", 0)) != 3 or hunter_facades.get_node_or_null("HunterAdvertisingTierHalo_150") == null or hunter_facades.get_node_or_null("HunterAdvertisingTierHalo_340") == null or hunter_facades.get_node_or_null("HunterAdvertisingTierHalo_530") == null:
		_fail("Hunter Tower is missing one or more illuminated architectural advertising-tier halos.")
		return
	var hunter_lobby := hunter_tower.get_node_or_null("PublicLobby_Blockout") as Node3D if hunter_tower != null else null
	if hunter_lobby == null or hunter_lobby.get_node_or_null("InteriorAdvertisingFrame_Left") == null or hunter_lobby.get_node_or_null("InteriorAdvertisingFrame_Right") == null:
		_fail("Hunter Tower internal advertising facades are missing.")
		return
	var tunnel_root := tower_manager.get_node_or_null("BaghdadHunterExaminationTunnel") as Node3D
	if tunnel_root == null or not bool(tunnel_root.get_meta("system_under_republic_bridge_district", false)):
		_fail("Hunter examination tunnel is not anchored beneath the Republic Bridge tower district.")
		return

	# Every one of the five connected civic towers must have three physical, walkable sky gardens.
	for district_tower_id in BAGHDAD_DISTRICT_TOWER_IDS:
		var district_node_name := str(TOWER_NODE_NAMES[district_tower_id])
		var district_tower := tower_manager.get_node_or_null(district_node_name) as Node3D
		var gardens := district_tower.get_node_or_null("TowerSkyGardens") as Node3D if district_tower != null else null
		if gardens == null or str(gardens.get_meta("system_owner_tower_id", "")) != district_tower_id or int(gardens.get_meta("system_sky_garden_count", 0)) != 3:
			_fail("A Baghdad civic tower is missing its three dedicated sky gardens: " + district_tower_id)
			return
		for garden_index in range(3):
			var garden := gardens.get_node_or_null("SkyGarden_%02d" % (garden_index + 1)) as Node3D
			var interaction := garden.get_node_or_null("SkyGardenInteraction_%02d" % (garden_index + 1)) as Area3D if garden != null else null
			if garden == null or not bool(garden.get_meta("system_garden_walkable", false)) or not bool(garden.get_meta("system_glass_perimeter_railing", false)):
				_fail("A Baghdad sky garden is missing its walkable deck or glass safety rail.")
				return
			var mapped_floor := int(garden.get_meta("system_tower_floor", 0))
			var tower_height_m := float(district_tower.get_meta("tower_height_m", 0.0))
			var tower_floor_count := int(district_tower.get_meta("tower_floor_count", 0))
			if mapped_floor < 1 or tower_floor_count < 2 or tower_height_m <= 16.0:
				_fail("A Baghdad sky garden has invalid elevator floor mapping metadata.")
				return
			var expected_elevator_floor_y := 9.0 + (tower_height_m - 16.0) * float(mapped_floor - 1) / float(tower_floor_count - 1)
			if absf(garden.position.y - expected_elevator_floor_y) > 0.05 or absf(float(garden.get_meta("system_garden_elevator_floor_y", -999.0)) - expected_elevator_floor_y) > 0.05:
				_fail("A Baghdad sky garden deck is vertically misaligned with its numbered elevator destination.")
				return
			if garden.get_node_or_null("GardenFloor_North_Collision") == null or garden.get_node_or_null("GardenFloor_South_Collision") == null or garden.get_node_or_null("GardenFloor_East_Collision") == null or garden.get_node_or_null("GardenFloor_West_Collision") == null:
				_fail("A Baghdad sky garden is missing one or more physical floor collisions.")
				return
			var access_bridge := garden.get_node_or_null("GardenAccessBridge") as MeshInstance3D
			var access_collision := garden.get_node_or_null("GardenAccessBridge_Collision") as StaticBody3D
			var access_collision_shape := access_collision.get_node_or_null("CollisionShape3D") as CollisionShape3D if access_collision != null else null
			if access_bridge == null or access_collision_shape == null or access_collision_shape.shape == null or not bool(garden.get_meta("system_garden_elevator_access_bridge", false)):
				_fail("A Baghdad sky garden is missing its physical elevator-core access bridge and collision.")
				return
			if garden.get_node_or_null("GardenAccessBridgeRail_Left_Collision") == null or garden.get_node_or_null("GardenAccessBridgeRail_Right_Collision") == null:
				_fail("A Baghdad sky garden access bridge is missing its two collidable safety rails.")
				return
			if interaction == null or not interaction.is_in_group("system_interactable") or int(interaction.get_meta("system_tower_floor", 0)) <= 0:
				_fail("A Baghdad sky garden is missing its tower-floor interaction route.")
				return
			if int(garden.get_meta("system_garden_planter_count", 0)) < 4 or int(garden.get_meta("system_garden_tree_count", 0)) < 4 or int(garden.get_meta("system_garden_bench_count", 0)) < 2:
				_fail("A Baghdad sky garden is missing planters, trees or seating.")
				return

	var shopping_tower := tower_manager.get_node_or_null("ShoppingTower") as Node3D
	if shopping_tower == null:
		_fail("Shopping and Commerce Tower is missing.")
		return
	var antiques_tower := tower_manager.get_node_or_null("AntiquesHeritageTower") as Node3D
	if antiques_tower == null or str(antiques_tower.get_meta("tower_id", "")) != "antiques_heritage_tower_baghdad":
		_fail("The fourth Baghdad district tower is not the Antiques and Heritage Tower.")
		return
	var antiques_directory: Variant = antiques_tower.get_meta("tower_floor_directory", PackedStringArray())
	if not antiques_directory is PackedStringArray or antiques_directory.size() != 9 or not str(antiques_directory[0]).contains("سومر") or not str(antiques_directory[7]).contains("المزادات"):
		_fail("Antiques and Heritage Tower does not expose its approved 34-floor museum directory.")
		return
	if str(antiques_tower.get_meta("gameplay_status", "")) != "antiques_heritage_tower_34_floors_102_named_interactive_exhibits_complete":
		_fail("Antiques and Heritage Tower museum exhibit completion status is missing.")
		return
	if int(antiques_tower.get_meta("tower_floor_count", 0)) != 34 or int(antiques_tower.get_meta("system_antiques_floor_count", 0)) != 34:
		_fail("Antiques and Heritage Tower must generate all 34 numbered museum floors.")
		return
	var exhibit_root := antiques_tower.get_node_or_null("AntiquesMuseumExhibits") as Node3D
	if exhibit_root == null or exhibit_root.get_child_count() != 34 or int(exhibit_root.get_meta("system_total_exhibits", 0)) != 102:
		_fail("Antiques museum must contain 34 physical floor galleries and 102 exhibits.")
		return
	var seen_antiques_ids: Dictionary = {}
	var verified_exhibits := 0
	for floor_number in range(1, 35):
		var museum_floor := exhibit_root.get_node_or_null("MuseumFloor_%02d" % floor_number) as Node3D
		if museum_floor == null or int(museum_floor.get_meta("system_tower_floor", 0)) != floor_number or museum_floor.get_child_count() != 3:
			_fail("Antiques museum floor %02d is missing its three exhibit stands or floor metadata." % floor_number)
			return
		for exhibit_number in range(1, 4):
			var exhibit := museum_floor.get_node_or_null("Exhibit_%02d" % exhibit_number) as Node3D
			if exhibit == null or not bool(exhibit.get_meta("system_exhibit_is_physical_3d", false)):
				_fail("Antiques museum floor %02d is missing physical exhibit %02d." % [floor_number, exhibit_number])
				return
			var artifact_id := str(exhibit.get_meta("system_artifact_id", ""))
			var artifact_name := str(exhibit.get_meta("system_artifact_name", ""))
			if artifact_id.is_empty() or artifact_name.is_empty() or seen_antiques_ids.has(artifact_id):
				_fail("Antiques museum exhibit identity is missing or duplicated on floor %02d." % floor_number)
				return
			seen_antiques_ids[artifact_id] = true
			var artifact_mesh := exhibit.get_node_or_null("ArtifactMesh") as MeshInstance3D
			var pedestal_mesh := exhibit.get_node_or_null("PedestalMesh") as MeshInstance3D
			var exhibit_title := exhibit.get_node_or_null("ExhibitTitle") as Label3D
			var interaction := exhibit.get_node_or_null("ArtifactInteraction") as Area3D
			var interaction_shape := interaction.get_node_or_null("CollisionShape3D") as CollisionShape3D if interaction != null else null
			if artifact_mesh == null or artifact_mesh.mesh == null or pedestal_mesh == null or pedestal_mesh.mesh == null or exhibit_title == null:
				_fail("Antiques exhibit %s is missing its 3D display mesh, pedestal or visible title." % artifact_id)
				return
			if interaction == null or not interaction.is_in_group("system_interactable") or str(interaction.get_meta("system_interaction_action", "")) != "inspect_artifact" or interaction_shape == null or interaction_shape.shape == null:
				_fail("Antiques exhibit %s is missing its working interaction area and collision." % artifact_id)
				return
			if str(interaction.get_meta("system_artifact_id", "")) != artifact_id or str(interaction.get_meta("system_tower_id", "")) != "antiques_heritage_tower_baghdad" or int(interaction.get_meta("system_tower_floor", 0)) != floor_number or int(interaction.get_meta("system_tower_floor_number", 0)) != floor_number:
				_fail("Antiques exhibit %s has inconsistent tower/floor ownership metadata." % artifact_id)
				return
			if str(interaction.get_meta("system_interaction_type", "")) != "museum_artifact_exhibit" or str(interaction.get_meta("system_artifact_display_role", "")) not in ["museum_exhibit", "player_market_prototype"] or str(interaction.get_meta("system_artifact_provenance", "")) == "" or str(interaction.get_meta("system_artifact_authenticity", "")) != "curator_review_required":
				_fail("Antiques exhibit %s is not wired to the museum inspection and marketplace UI contract." % artifact_id)
				return
			verified_exhibits += 1
	if verified_exhibits != 102 or int(antiques_tower.get_meta("system_antiques_interactive_exhibit_count", 0)) != 102:
		_fail("Antiques museum did not validate all 102 unique interactive exhibits.")
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

	if (tower_manager.get_node_or_null("PowerTower") as Node3D).get_node_or_null("TowerSkyGardens") != null:
		_fail("Standalone Power Tower must not inherit the five civic sky-garden destinations.")
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


	# Structural architecture audit: validate generated geometry and each tower's approved visual identity.
	const ARCHITECTURAL_IDENTITIES := {
		"hunter_association_tower_baghdad": ["HunterXSXEmblemPlaque_00", "HunterXSXEmblemPlaque_01", "HunterXSXEmblemPlaque_02", "HunterXSXEmblemPlaque_03"],
		"business_investment_tower_baghdad": ["BusinessCapitalSpire", "BusinessCapitalRing_00", "BusinessCapitalRing_01", "BusinessCapitalRing_02", "BusinessInvestmentSign"],
		"shopping_tower_baghdad": ["RetailGalleryRing_00", "RetailGalleryRing_01", "RetailGalleryRing_02", "ShoppingAtriumSign", "ShoppingTowerWeaponBlade_left", "ShoppingTowerWeaponBlade_right", "ShoppingTowerElixirBeacon"],
		"antiques_heritage_tower_baghdad": ["HeritageMuseumPodium", "HeritageMuseumEntranceCanopy", "HeritageGalleryWing_left", "HeritageGalleryWing_right", "HeritageGalleryColumn_left", "HeritageGalleryColumn_right", "HeritageArchiveCrown"],
		"technology_tower_baghdad": ["InnovationAntenna_00", "InnovationAntenna_01", "InnovationAntenna_02", "InnovationLabSkyRibbon"],
		"power_tower_baghdad": ["TournamentBlade_left", "TournamentBlade_right", "PowerTowerChampionCrown"]
	}
	for architecture_tower_id in ALL_VALIDATED_FACILITY_IDS:
		var architecture_tower := tower_manager.get_node_or_null(str(TOWER_NODE_NAMES[architecture_tower_id])) as Node3D
		if architecture_tower == null:
			_fail("Architecture audit cannot resolve tower: " + architecture_tower_id)
			return
		var architecture_height := float(architecture_tower.get_meta("tower_height_m", 0.0))
		var architecture_floors := int(architecture_tower.get_meta("tower_floor_count", 0))
		if architecture_height <= 0.0 or architecture_floors <= 0:
			_fail("Tower architectural height or floor count is missing: " + architecture_tower_id)
			return
		if architecture_tower.get_node_or_null("MonumentalFoundation") == null or architecture_tower.get_node_or_null("TowerMainShaft") == null or architecture_tower.get_node_or_null("IlluminatedIdentityRing") == null:
			_fail("Tower is missing its generated foundation, main shaft or illuminated identity ring: " + architecture_tower_id)
			return
		var architecture_body := architecture_tower.get_node_or_null("TowerStructureCollision") as StaticBody3D
		if architecture_body == null:
			_fail("Tower is missing its physical structural collision body: " + architecture_tower_id)
			return
		var structural_shape_count := 0
		for structural_child in architecture_body.get_children():
			if structural_child is CollisionShape3D and structural_child.shape != null:
				structural_shape_count += 1
		if structural_shape_count < 2:
			_fail("Tower must have separate foundation and shaft collision volumes: " + architecture_tower_id)
			return
		for podium_index in range(3):
			if architecture_tower.get_node_or_null("PodiumTerrace_%d" % podium_index) == null:
				_fail("Tower is missing a podium terrace: " + architecture_tower_id)
				return
		for fin_index in range(4):
			if architecture_tower.get_node_or_null("FacadeFin_%d" % fin_index) == null:
				_fail("Tower is missing one of its four vertical facade fins: " + architecture_tower_id)
				return
		var architecture_glazing := architecture_tower.get_node_or_null("FacadeGlazingPanels") as MultiMeshInstance3D
		var expected_window_count := architecture_floors * 20
		if architecture_glazing == null or architecture_glazing.multimesh == null or architecture_glazing.multimesh.instance_count != expected_window_count or int(architecture_tower.get_meta("system_facade_window_count", 0)) != expected_window_count:
			_fail("Tower glass facade does not contain 20 window panels for every declared floor: " + architecture_tower_id)
			return
		if int(architecture_tower.get_meta("system_facade_window_segments_per_floor", 0)) != 20 or int(architecture_tower.get_meta("system_facade_window_floors", 0)) != architecture_floors:
			_fail("Tower facade floor/segment metadata does not match its generated glass geometry: " + architecture_tower_id)
			return
		for identity_node_name in ARCHITECTURAL_IDENTITIES[architecture_tower_id]:
			if architecture_tower.get_node_or_null(str(identity_node_name)) == null:
				_fail("Tower is missing its approved architectural identity feature %s: %s" % [str(identity_node_name), architecture_tower_id])
				return
	var hunter_architecture := tower_manager.get_node_or_null("HunterAssociationTower") as Node3D
	if hunter_architecture == null or str(hunter_architecture.get_meta("system_hunter_guild_insignia", "")) != "XSX" or int(hunter_architecture.get_meta("system_hunter_guild_identity_facades", 0)) != 4:
		_fail("Hunter Association Tower must retain the four-sided approved XSX identity.")
		return
	var power_architecture := tower_manager.get_node_or_null("PowerTower") as Node3D
	if power_architecture == null or int(power_architecture.get_meta("tower_floor_count", 0)) != 200 or bool(power_architecture.get_meta("tower_is_connected_district_member", true)):
		_fail("Power Tower must remain an independent 200-floor structure outside the five Baghdad civic towers.")
		return

	print("Baghdad tower validation passed: verified Republic Bridge and Tigris runtime geometry, five towers on both riverbanks/bridge, upper sky city, standalone Power Tower, Hunter rooftop helicopter controller, internal/external ads, tunnel anchor, five Baghdad tower lobby kiosks plus one separate Power Tower kiosk and Shopping Tower facilities.")
	# This is a short-lived headless validation process; avoid forcing dummy-renderer teardown of placeholder meshes.
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad tower validation failed: " + message)
	quit(1)
