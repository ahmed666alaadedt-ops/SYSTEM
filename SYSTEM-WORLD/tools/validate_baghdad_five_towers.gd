extends SceneTree

const TowerManager = preload("res://scripts/baghdad_tower_landmarks_manager.gd")

var failures := 0


class MockTerrain extends Node:
	func is_land_position(_x: float, _z: float) -> bool:
		return true

	func get_terrain_height(_x: float, _z: float) -> float:
		return 0.0


class MockBaghdadRegion extends Node3D:
	var terrain: Node

	func get_city_anchor(_city_name: String) -> Vector3:
		return Vector3.ZERO


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var region := MockBaghdadRegion.new()
	region.name = "MockBaghdadRegion"
	region.terrain = MockTerrain.new()
	region.add_child(region.terrain)
	root.add_child(region)

	var manager := TowerManager.new()
	region.add_child(manager)
	await process_frame

	var towers := manager.get_tower_positions()
	_expect(towers.size() == 5, "exactly five Baghdad district towers are generated")
	var power_tower := manager.get_node_or_null("PowerTower")
	_expect(power_tower != null, "separate Power Tower landmark exists outside the five-tower district")
	if power_tower != null:
		_expect(bool(power_tower.get_meta("is_separate_landmark", false)), "Power Tower is tagged as a separate landmark")
		_expect(int(power_tower.get_meta("floor_count", 0)) == 200, "Power Tower has 200 floors")
		var challenge_system := power_tower.get_node_or_null("PowerTower200FloorChallengeSystem")
		_expect(challenge_system != null, "Power Tower challenge system exists")
		if challenge_system != null:
			_expect(int(challenge_system.get_meta("floor_count", 0)) == 200, "Power Tower challenge registry contains 200 floors")
			_expect(int(challenge_system.get_meta("boss_trial_count", 0)) == 20, "Power Tower has 20 boss trial floors")
			_expect(challenge_system.get_child_count() == 40, "Power Tower has a boss arena and floor label for each tenth floor")
			var registry: Array = challenge_system.get_meta("floor_registry", [])
			_expect(registry.size() == 200, "Power Tower floor registry has 200 challenge entries")
			var boss_count := 0
			for floor_entry in registry:
				if bool(floor_entry.get("boss_trial", false)):
					boss_count += 1
			_expect(boss_count == 20, "Power Tower registry marks every tenth floor as a boss trial")

	var expected_towers := [
		"HunterAssociationTower",
		"BusinessTower",
		"ShoppingTower",
		"EntertainmentTower",
		"TechnologyInnovationTower"
	]
	for tower_name in expected_towers:
		var tower := manager.get_node_or_null(tower_name)
		_expect(tower != null, "tower exists: " + tower_name)
		if tower == null:
			continue
		_expect(tower.get_node_or_null("PublicPodiumAndArrivalHall") != null, "three-level public podium exists: " + tower_name)
		_expect(tower.get_node_or_null("TowerFacilities_Blockout") != null, "facility zone exists: " + tower_name)
		var tower_facilities := tower.get_node_or_null("TowerFacilities_Blockout")
		var has_service_directory := false
		var has_reception_counter := false
		if tower_facilities != null:
			for facility in tower_facilities.get_children():
				if facility.get_node_or_null("FacilityServiceDirectory") != null:
					has_service_directory = true
				if facility.get_node_or_null("ReceptionCounterVisual") != null:
					has_reception_counter = true
		_expect(has_service_directory, "tower facilities include visitor service directories: " + tower_name)
		_expect(has_reception_counter, "tower facilities include reception counters: " + tower_name)
		var transport := tower.get_node_or_null("VerticalTransport_Blockout")
		_expect(transport != null, "lift and stair core blockout exists: " + tower_name)
		if transport != null:
			_expect(transport.get_node_or_null("PanoramicLiftShaft_00") != null, "panoramic lift shaft exists: " + tower_name)
			_expect(transport.get_node_or_null("ProtectedStairCore_00") != null, "protected stair core exists: " + tower_name)
			_expect(transport.get_node_or_null("FloorDirectoryMarkers") != null, "floor directory exists: " + tower_name)
		var gardens := tower.get_node_or_null("SkyGardenTerraces")
		_expect(gardens != null, "elevated sky gardens exist: " + tower_name)
		if gardens != null:
			_expect(gardens.get_node_or_null("ElevatedGardenDeck_00") != null, "lower sky garden deck exists: " + tower_name)
			_expect(gardens.get_node_or_null("ElevatedGardenDeck_01") != null, "middle sky garden deck exists: " + tower_name)
			_expect(gardens.get_node_or_null("ElevatedGardenDeck_02") != null, "upper sky garden deck exists: " + tower_name)
		_expect(tower.get_node_or_null("PublicEntrance") != null, "public entrance trigger exists: " + tower_name)
		_expect(int(tower.get_meta("transport_blockout_revision", 0)) == 1, "transport blockout revision is registered: " + tower_name)
		_expect(int(tower.get_meta("sky_garden_revision", 0)) == 1, "sky garden revision is registered: " + tower_name)
		_expect(int(tower.get_meta("service_furniture_revision", 0)) == 1, "service furniture revision is registered: " + tower_name)
		_expect(int(tower.get_meta("specialized_interiors_revision", 0)) == 1, "specialized interior revision is registered: " + tower_name)

	var shopping := manager.get_node_or_null("ShoppingTower")
	if shopping != null:
		var facilities := shopping.get_node_or_null("TowerFacilities_Blockout")
		var cinema := facilities.get_node_or_null("CinemaSixHallLayout_Blockout") if facilities != null else null
		_expect(cinema != null, "Shopping Tower cinema layout exists")
		if cinema != null:
			_expect(cinema.get_child_count() == 6, "cinema contains six halls")
			for hall_index in range(1, 7):
				var hall := cinema.get_node_or_null("CinemaHall_%02d" % hall_index)
				_expect(hall != null, "cinema hall %02d exists" % hall_index)
				if hall != null:
					_expect(hall.get_node_or_null("CinemaWalkableFloor") != null, "cinema hall %02d has floor collision" % hall_index)
					_expect(hall.get_node_or_null("AisleGuidanceLights") != null, "cinema hall %02d has aisle guidance" % hall_index)
					_expect(hall.get_node_or_null("EmergencyExitSign") != null, "cinema hall %02d has exit signage" % hall_index)
					_expect(hall.get_node_or_null("TicketKioskVisual") != null, "cinema hall %02d has ticket kiosk visual" % hall_index)
					_expect(hall.get_node_or_null("HallNumberSign") != null, "cinema hall %02d has hall numbering" % hall_index)

	var hunter_tower := manager.get_node_or_null("HunterAssociationTower")
	var hunter_details := hunter_tower.get_node_or_null("TowerFacilities_Blockout/SpecializedInteriorDetails_Blockout") if hunter_tower != null else null
	_expect(hunter_details != null, "Hunter Association specialized interior exists")
	if hunter_details != null:
		_expect(hunter_details.get_node_or_null("HunterMissionBoardGallery") != null, "hunter mission board gallery exists")
		_expect(hunter_details.get_node_or_null("HunterTrainingDummyGallery") != null, "hunter training dummy gallery exists")
		_expect(hunter_details.get_node_or_null("HunterClinicTreatmentStations") != null, "hunter clinic treatment stations exist")
	var business_tower := manager.get_node_or_null("BusinessTower")
	var business_details := business_tower.get_node_or_null("TowerFacilities_Blockout/SpecializedInteriorDetails_Blockout") if business_tower != null else null
	_expect(business_details != null, "Business Tower specialized interior exists")
	if business_details != null:
		_expect(business_details.get_node_or_null("ExecutiveConferenceTableAndSeating") != null, "business conference room layout exists")
		_expect(business_details.get_node_or_null("InvestmentMarketTicker") != null, "investment market ticker exists")
		_expect(business_details.get_node_or_null("BusinessHotelGuestRoomGallery") != null, "business hotel guest room gallery exists")
	var technology_tower := manager.get_node_or_null("TechnologyInnovationTower")
	var technology_details := technology_tower.get_node_or_null("TowerFacilities_Blockout/SpecializedInteriorDetails_Blockout") if technology_tower != null else null
	_expect(technology_details != null, "Technology Tower specialized interior exists")
	if technology_details != null:
		_expect(technology_details.get_node_or_null("RoboticsResearchBenchGallery") != null, "robotics research benches exist")
		_expect(technology_details.get_node_or_null("ArtificialIntelligenceResearchPods") != null, "AI research pods exist")
		_expect(technology_details.get_node_or_null("DigitalLibraryShelfGallery") != null, "digital library shelves exist")

	var shopping_tower := manager.get_node_or_null("ShoppingTower")
	var shopping_facilities := shopping_tower.get_node_or_null("TowerFacilities_Blockout") if shopping_tower != null else null
	_expect(shopping_facilities != null, "Shopping Tower facility layout exists")
	if shopping_tower != null:
		_expect(int(shopping_tower.get_meta("shopping_mall_revision", 0)) == 1, "shopping mall interior revision is registered")
	if shopping_facilities != null:
		_expect(shopping_facilities.get_node_or_null("RetailStorefrontGallery_Blockout") != null, "retail storefront gallery exists")
		_expect(shopping_facilities.get_node_or_null("FoodCourtVendorGallery_Blockout") != null, "food court vendor gallery exists")
		_expect(shopping_facilities.get_node_or_null("FoodCourtDiningArea_Blockout") != null, "food court dining area exists")

	var entertainment := manager.get_node_or_null("EntertainmentTower")
	var entertainment_facilities := entertainment.get_node_or_null("TowerFacilities_Blockout") if entertainment != null else null
	_expect(entertainment_facilities != null, "Entertainment Tower facility layout exists")
	if entertainment != null:
		_expect(int(entertainment.get_meta("entertainment_venue_revision", 0)) == 1, "entertainment venue revision is registered")
	if entertainment_facilities != null:
		_expect(entertainment_facilities.get_node_or_null("ArcadeCabinetGallery_Blockout") != null, "arcade cabinet gallery exists")
		_expect(entertainment_facilities.get_node_or_null("BowlingLaneGallery_Blockout") != null, "bowling lane gallery exists")
		_expect(entertainment_facilities.get_node_or_null("VirtualRealityPodGallery_Blockout") != null, "VR pod gallery exists")
		_expect(entertainment_facilities.get_node_or_null("ConcertHallStageAndSeating_Blockout") != null, "concert hall stage and seating exist")

	var district := manager.get_node_or_null("FiveTowerConnectedDistrict")
	_expect(district != null, "connected five-tower district exists")
	if district != null:
		for bridge_index in range(5):
			var bridge_name := "CentralSYSTEMRadialSkybridge_%d" % bridge_index
			_expect(district.get_node_or_null(bridge_name) != null, "radial skybridge exists: " + bridge_name)

	var amenities := manager.get_node_or_null("ConnectedCityPublicAmenities_Blockout")
	_expect(amenities != null, "shared public amenities root exists")
	if amenities != null:
		_expect(amenities.get_node_or_null("CentralSYSTEMSkySpire_Blockout") != null, "central SYSTEM skyline spire exists")
		for level in range(3):
			_expect(amenities.get_node_or_null("SharedSkyGardenTerrace_%02d" % level) != null, "shared sky garden terrace %02d exists" % level)

	region.queue_free()
	await process_frame
	if failures == 0:
		print("Baghdad five-tower landmark validation passed.")
		quit(0)
	else:
		push_error("Baghdad five-tower landmark validation failed: %d check(s)." % failures)
		quit(1)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1


func _count_named_prefix(node: Node, prefix: String) -> int:
	var count := 0
	for child in node.get_children():
		if child.name.begins_with(prefix):
			count += 1
		count += _count_named_prefix(child, prefix)
	return count
