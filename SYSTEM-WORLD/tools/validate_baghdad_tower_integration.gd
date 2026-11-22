extends SceneTree

class FakeTerrain:
	extends Node
	func is_land_position(_x: float, _z: float) -> bool:
		return true
	func get_terrain_height(_x: float, _z: float) -> float:
		return 0.0

class FakeRegion:
	extends Node3D
	var terrain: Node
	func get_city_anchor(city_name: String) -> Vector3:
		return Vector3(100.0, 0.0, 100.0) if city_name == "Baghdad" else Vector3.INF

class FakeMap:
	extends Node
	var entries: Dictionary = {}
	func register_location(world_id: String, location_id: String, region_id: String, display_name: String, location_type: int, position: Vector3, is_fast_travel_point: bool = false) -> bool:
		if world_id.is_empty() or location_id.is_empty() or entries.has(location_id):
			return false
		entries[location_id] = {"region_id": region_id, "name": display_name, "type": location_type, "position": position, "fast_travel": is_fast_travel_point}
		return true

const TOWER_SCRIPT = preload("res://scripts/baghdad_tower_landmarks_manager.gd")
const TOWER_FLOOR_SCRIPT = preload("res://scripts/system_baghdad_tower_floor_world.gd")
const TOWER_LIFT_UI_SCRIPT = preload("res://scripts/system_baghdad_tower_lift_ui.gd")
const LANDMARK_SCRIPT = preload("res://scripts/system_baghdad_landmark_integration.gd")
const HUNTER_EXAM_MANAGER_SCRIPT = preload("res://scripts/system_hunter_exam_manager.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Baghdad tower integration validation failed: " + message)
	quit(1)

func _run() -> void:
	var region := FakeRegion.new()
	region.name = "FakeModernWorldRegionManager"
	var terrain := FakeTerrain.new()
	terrain.name = "Terrain"
	region.terrain = terrain
	region.add_child(terrain)
	root.add_child(region)

	var towers = TOWER_SCRIPT.new()
	towers.name = "BaghdadTowerLandmarksManager"
	region.add_child(towers)
	await process_frame

	var tower_records: Array = towers.get_tower_positions()
	if tower_records.size() != 6:
		_fail("Expected five connected towers plus one independent Power Tower; got %d." % tower_records.size())
		return
	if towers.connected_tower_positions.size() != 5:
		_fail("Power Tower was incorrectly included in the five-tower district.")
		return

	var expected_roots := ["HunterAssociationTower", "BusinessTower", "ShoppingTower", "EntertainmentTower", "TechnologyTower"]
	var hunter_tower_interior: Node3D
	for root_name in expected_roots:
		var tower_root := towers.get_node_or_null(root_name)
		if tower_root == null:
			_fail("Missing Baghdad tower root: " + root_name)
			return
		var exterior_collision := tower_root.get_node_or_null("TowerStructureCollision") as StaticBody3D
		if exterior_collision == null:
			_fail("Missing physical exterior collision body for " + root_name)
			return
		for collider_name in ["FoundationCollisionShape", "ShaftCollisionShape"]:
			var exterior_shape := exterior_collision.get_node_or_null(collider_name) as CollisionShape3D
			if exterior_shape == null or exterior_shape.shape == null or exterior_shape.disabled:
				_fail("Tower exterior shell collision is missing or disabled for " + root_name + ": " + collider_name)
				return
		var interior := tower_root.get_node_or_null("TowerInterior")
		if interior == null:
			_fail("Missing playable lobby for " + root_name)
			return

		var expected_facade_panels := int(tower_root.get_meta("tower_floor_count", 0)) * 4
		var facade_glass := tower_root.get_node_or_null("TowerFacadeGlassPanels") as MultiMeshInstance3D
		var facade_frames := tower_root.get_node_or_null("TowerFacadeMetalFrames") as MultiMeshInstance3D
		if facade_glass == null or facade_glass.multimesh == null or facade_glass.multimesh.instance_count != expected_facade_panels:
			_fail("Tower facade glass panels do not cover every floor on " + root_name)
			return
		if facade_frames == null or facade_frames.multimesh == null or facade_frames.multimesh.instance_count != expected_facade_panels:
			_fail("Tower facade metal frames do not cover every floor on " + root_name)
			return
		for screen_name in ["ExteriorAdScreen_00", "ExteriorAdScreen_01"]:
			var exterior_screen := tower_root.get_node_or_null(screen_name)
			if exterior_screen == null or exterior_screen.get_node_or_null("AdScreenDisplay") == null or exterior_screen.get_node_or_null("AdScreenMessage") == null:
				_fail("Missing public-facing advertising display on " + root_name + ": " + screen_name)
				return
		for screen_name in ["InteriorAdScreen_00", "InteriorAdScreen_01"]:
			var interior_screen := interior.get_node_or_null(screen_name)
			if interior_screen == null or interior_screen.get_node_or_null("AdScreenDisplay") == null or interior_screen.get_node_or_null("AdScreenMessage") == null:
				_fail("Missing lobby advertising display on " + root_name + ": " + screen_name)
				return
		var elevator_cabin := interior.get_node_or_null("AnimatedElevatorCabin")
		if elevator_cabin == null or interior.get_node_or_null("AnimatedElevatorCabin/CabinDoorLeft") == null or interior.get_node_or_null("AnimatedElevatorCabin/CabinDoorRight") == null:
			_fail("Animated elevator cabin or sliding doors are missing for " + root_name)
			return
		if not bool(interior.get_meta("emergency_stairwell_ready", false)) or int(interior.get_meta("emergency_stairwell_step_count", 0)) != 200:
			_fail("Physical emergency stairwell steps are incomplete for " + root_name)
			return
		if root_name == "HunterAssociationTower":
			hunter_tower_interior = interior as Node3D
		var lift_console := interior.get_node_or_null("CentralLiftConsoleInteraction") as Area3D
		if lift_console == null or not lift_console.is_in_group("system_interactable"):
			_fail("Missing full-range central lift console for " + root_name)
			return
		if int(lift_console.get_meta("system_tower_floor_count", 0)) < 30:
			_fail("Central lift console does not expose the full tower floor count for " + root_name)
			return
		var floor_world := tower_root.get_node_or_null("BaghdadTowerFloorWorld")
		if floor_world == null or not floor_world.has_method("build_floor"):
			_fail("Missing procedural floor world for " + root_name)
			return
		var configured_floor_count := int(floor_world.get("max_floors"))
		if configured_floor_count < 30:
			_fail("Tower floor world does not expose its full building floor count for " + root_name)
			return
		var generated_floor: Dictionary = floor_world.call("build_floor", configured_floor_count, Vector3(5.0, 0.0, 5.0))
		if not bool(generated_floor.get("success", false)):
			_fail("Could not generate the top floor for " + root_name)
			return
		var active_floor_name := "ActiveTowerFloor_%03d" % configured_floor_count
		var generated_root := floor_world.get_node_or_null(active_floor_name)
		if generated_root == null:
			_fail("Generated floor root is missing for " + root_name + ": " + str(floor_world.get_children().map(func(child): return child.name)))
			return
		var ground_body := generated_root.get_node_or_null("FloorGround_Collision") as StaticBody3D
		var has_ground_collision := false
		if ground_body != null:
			for collision_child in ground_body.get_children():
				if collision_child is CollisionShape3D and collision_child.shape != null and not collision_child.disabled:
					has_ground_collision = true
					break
		if not has_ground_collision:
			_fail("Generated floor has no collision-backed ground for " + root_name)
			return
		var stair_down := generated_root.get_node_or_null("StairDownInteraction") as Area3D
		if configured_floor_count > 1 and (stair_down == null or not stair_down.is_in_group("system_interactable")):
			_fail("Top floor has no usable emergency stair descent for " + root_name)
			return
		if generated_root.get_node_or_null("StairUpInteraction") != null:
			_fail("Top floor incorrectly exposes an emergency stair leading above the tower.")
			return
		for stair_step_index in range(15):
			var stair_body := generated_root.get_node_or_null("EmergencyStairDownStep_%02d_Collision" % stair_step_index) as StaticBody3D
			var stair_collision := stair_body.get_node_or_null("CollisionShape3D") as CollisionShape3D if stair_body != null else null
			if stair_collision == null or stair_collision.shape == null or stair_collision.disabled:
				var stair_debug: Array[String] = []
				for child in generated_root.get_children():
					if str(child.name).contains("EmergencyStair"):
						stair_debug.append("%s:%s" % [str(child.name), child.get_class()])
				_fail("Top floor emergency stair step is missing physical collision: %d; floor=%d/%d; active_floor=%d; children=%s" % [stair_step_index, configured_floor_count, int(floor_world.get("max_floors")), int(floor_world.get("active_floor")), ", ".join(stair_debug)])
				return
		var floor_exit := generated_root.get_node_or_null("TowerFloorExit") as Area3D
		if floor_exit == null or not floor_exit.is_in_group("system_interactable"):
			_fail("Generated tower floor has no usable return gate for " + root_name)
			return
		if floor_exit.get_meta("system_return_position", Vector3.INF) == Vector3.INF:
			_fail("Generated tower floor return gate has no saved return position for " + root_name)
			return
		var tower_variant_nodes := {
			"hunter_association_tower_baghdad": ["HunterTrainingMat", "HunterMissionBriefingTable", "HunterSparringCircle", "HunterWeaponPracticeTarget_00"],
			"business_tower_baghdad": ["BusinessOffice_00", "TradingDesk_00_00", "ExecutiveBoardroomTable", "ExecutiveSuite_00"],
			"shopping_tower_baghdad": ["RetailKiosk_00", "FashionDisplayPod_00", "FoodCourtCounter_00", "ElectronicsIsland_00"],
			"entertainment_tower_baghdad": ["EntertainmentStage", "EsportsArenaStage", "CinemaScreen", "IndoorSportsCourt"],
			"technology_tower_baghdad": ["InnovationWorkbench_00", "ResearchLabBench_00", "ServerRack_00_00", "PrototypeDisplayPod_00"]
		}
		var expected_variant_nodes: Array = tower_variant_nodes.get(str(tower_root.get_meta("tower_id", "")), [])
		if expected_variant_nodes.size() != 4:
			_fail("Missing four-layout test catalog for " + root_name)
			return
		for variant_index in range(4):
			var variant_build: Dictionary = floor_world.call("build_floor", variant_index + 1, Vector3(5.0, 0.0, 5.0))
			if not bool(variant_build.get("success", false)):
				_fail("Could not generate tower floor layout variant %d for %s." % [variant_index + 1, root_name])
				return
			var variant_root := floor_world.get_node_or_null("ActiveTowerFloor_%03d" % (variant_index + 1))
			if variant_root == null or int(variant_root.get_meta("floor_theme_variant", -1)) != variant_index:
				_fail("Tower floor variant index was not preserved for %s." % root_name)
				return
			if variant_root.get_node_or_null(str(expected_variant_nodes[variant_index])) == null:
				_fail("Tower %s is missing its unique floor layout feature: %s" % [root_name, str(expected_variant_nodes[variant_index])])
				return
			if variant_index + 1 < configured_floor_count and variant_root.get_node_or_null("StairUpInteraction") == null:
				_fail("Tower floor variant is missing its emergency stair-up route: " + root_name)
				return
			if variant_index + 1 > 1 and variant_root.get_node_or_null("StairDownInteraction") == null:
				_fail("Tower floor variant is missing its emergency stair-down route: " + root_name)
				return

		for floor_number in range(2, 6):
			var selector := interior.get_node_or_null("LobbyLiftSelector_%02d" % floor_number) as Area3D
			if selector == null or not selector.is_in_group("system_interactable"):
				_fail("Missing accessible lobby lift selector %02d in %s." % [floor_number, root_name])
				return
			if selector.get_meta("system_destination_position", Vector3.INF) == Vector3.INF:
				_fail("Lobby lift selector has no destination in " + root_name)
				return

	# The Hunter tunnel starts on the lobby side of seven real collision-backed
	# gates. An unregistered candidate cannot open the route; a valid exam start can.
	if hunter_tower_interior == null:
		_fail("Hunter Association tower interior is missing for tunnel access validation.")
		return
	var tunnel_start := hunter_tower_interior.get_node_or_null("HunterExamTunnelStart") as Area3D
	if tunnel_start == null or not tunnel_start.is_in_group("system_interactable"):
		_fail("Hunter exam start interaction is missing from the lobby-side tunnel threshold.")
		return
	var first_exam_gate := hunter_tower_interior.get_node_or_null("HunterExamStageGateBarrier_01") as StaticBody3D
	if first_exam_gate == null or tunnel_start.position.z <= first_exam_gate.position.z:
		_fail("Hunter exam start interaction is not positioned before the first stage gate.")
		return
	for stage_number in range(1, 8):
		var barrier := hunter_tower_interior.get_node_or_null("HunterExamStageGateBarrier_%02d" % stage_number) as StaticBody3D
		var barrier_collision := barrier.get_node_or_null("GatePanelCollision") as CollisionShape3D if barrier != null else null
		var barrier_visual := barrier.get_node_or_null("GatePanelVisual") as MeshInstance3D if barrier != null else null
		if barrier_collision == null or barrier_collision.shape == null or barrier_collision.disabled:
			_fail("Hunter exam stage gate %02d is not physically closed before exam start." % stage_number)
			return
		if barrier_visual == null or not barrier_visual.visible:
			_fail("Hunter exam stage gate %02d has no visible locked panel." % stage_number)
			return
	var staging_barrier := hunter_tower_interior.get_node_or_null("HunterExamStagingGateBarrier") as StaticBody3D
	var staging_collision := staging_barrier.get_node_or_null("GatePanelCollision") as CollisionShape3D if staging_barrier != null else null
	if staging_collision == null or staging_collision.shape == null or staging_collision.disabled:
		_fail("Hunter exam staging chamber is not physically secured before exam start.")
		return

	var exam_manager = HUNTER_EXAM_MANAGER_SCRIPT.new()
	var validation_save_path := "user://hunter_tunnel_gate_validator_%d.cfg" % int(Time.get_unix_time_from_system())
	exam_manager.save_path = validation_save_path
	root.add_child(exam_manager)
	var unregistered_start: Dictionary = exam_manager.begin_exam()
	if str(unregistered_start.get("reason", "")) != "NOT_REGISTERED":
		_fail("An unregistered player was allowed to start the Hunter examination.")
		return
	var registration: Dictionary = exam_manager.apply_for_exam("hunter_tunnel_gate_validator")
	if not bool(registration.get("success", false)):
		_fail("A fresh Hunter exam candidate could not register for the tunnel access test.")
		return
	var authorized_start: Dictionary = exam_manager.begin_exam()
	if not bool(authorized_start.get("success", false)):
		_fail("A registered Hunter exam candidate could not begin the examination.")
		return
	hunter_tower_interior.call("set_hunter_exam_tunnel_access", true)
	for stage_number in range(1, 8):
		var opened_barrier := hunter_tower_interior.get_node_or_null("HunterExamStageGateBarrier_%02d" % stage_number) as StaticBody3D
		var opened_collision := opened_barrier.get_node_or_null("GatePanelCollision") as CollisionShape3D
		var opened_visual := opened_barrier.get_node_or_null("GatePanelVisual") as MeshInstance3D
		if not opened_collision.disabled or opened_visual.visible:
			_fail("A registered candidate could not open Hunter exam stage gate %02d." % stage_number)
			return
	if not staging_collision.disabled:
		_fail("A registered candidate could not open the Hunter exam staging gate.")
		return
	if not bool(hunter_tower_interior.get_meta("hunter_exam_tunnel_access_open", false)):
		_fail("Hunter exam tunnel did not record its authorized open state.")
		return
	exam_manager.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(validation_save_path))
	print("Hunter exam tunnel access passed: seven physical stage gates and staging barrier stay locked until registered exam start.")

	if hunter_tower_interior == null:
		_fail("Hunter Association Tower interior is unavailable for elevator travel validation.")
		return
	var elevator_test_ok: bool = await hunter_tower_interior.call("animate_lift_to_floor", 3)
	if not elevator_test_ok:
		_fail("Animated elevator could not complete its floor-three travel cycle.")
		return
	var tested_cabin := hunter_tower_interior.get_node_or_null("AnimatedElevatorCabin") as Node3D
	if tested_cabin == null or absf(tested_cabin.position.y - 36.0) > 0.1:
		_fail("Animated elevator cabin did not reach the expected floor-three height.")
		return

	var connected_district := towers.get_node_or_null("FiveTowerConnectedDistrict")
	if connected_district == null:
		_fail("The five connected towers have no shared district bridge network.")
		return
	for index in range(5):
		var ramp_root := connected_district.get_node_or_null("VehicleAccessRamp_%d" % index)
		var ramp_has_collision := false
		if ramp_root != null:
			for ramp_body in ramp_root.find_children("*", "StaticBody3D", true, false):
				for ramp_shape in ramp_body.get_children():
					if ramp_shape is CollisionShape3D and ramp_shape.shape != null and not ramp_shape.disabled:
						ramp_has_collision = true
						break
				if ramp_has_collision:
					break
		if not ramp_has_collision:
			_fail("A tower access ramp is missing physical collision: %d" % index)
			return
	var sky_ring := towers.get_node_or_null("BaghdadReferenceSkyPromenade_Blockout")
	if sky_ring == null or sky_ring.get_child_count() < 12:
		_fail("The shared sky promenade ring is missing its twelve walkable segments.")
		return
	var first_ring_segment := sky_ring.get_node_or_null("SkyPromenadeSegment_00")
	if first_ring_segment == null or first_ring_segment.get_node_or_null("WalkableDeckCollision") == null:
		_fail("The sky promenade has no collision-backed walking deck.")
		return
	var amenities := towers.get_node_or_null("ConnectedCityPublicAmenities_Blockout")
	if amenities == null:
		_fail("The connected tower district public amenities are missing.")
		return
	for amenity_name in ["RooftopGardenDeck", "LeisureAndPoolDeck", "FamilyEntertainmentPlaza"]:
		var amenity_body := amenities.find_child(amenity_name + "_Collision", true, false) as StaticBody3D
		var amenity_has_collision := false
		if amenity_body != null:
			for amenity_shape in amenity_body.get_children():
				if amenity_shape is CollisionShape3D and amenity_shape.shape != null and not amenity_shape.disabled:
					amenity_has_collision = true
					break
		if not amenity_has_collision:
			_fail("Public amenity deck is not physically walkable: " + amenity_name)
			return

	var power_record: Dictionary = {}
	for record in tower_records:
		if str(record.get("id", "")) == "power_tower_baghdad":
			power_record = record
	if power_record.is_empty() or int(power_record.get("floors", 0)) != 200:
		_fail("Power Tower physical landmark must expose exactly 200 floors.")
		return
	if float(power_record.get("height", 0.0)) < 600.0:
		_fail("Power Tower structure height does not provide a realistic 200-floor facade.")
		return
	var power_root := towers.get_node_or_null("PowerTower")
	if power_root == null or power_root.get_node_or_null("TowerInterior") != null:
		_fail("Power Tower must remain a separate challenge structure without a five-tower lobby.")
		return
	var power_collision := power_root.get_node_or_null("TowerStructureCollision") as StaticBody3D
	if power_collision == null:
		_fail("Independent Power Tower exterior collision body is missing.")
		return
	for collider_name in ["FoundationCollisionShape", "ShaftCollisionShape"]:
		var power_shape := power_collision.get_node_or_null(collider_name) as CollisionShape3D
		if power_shape == null or power_shape.shape == null or power_shape.disabled:
			_fail("Independent Power Tower exterior collision is missing or disabled: " + collider_name)
			return
	if power_root.get_node_or_null("PowerTowerArenaVenue/PowerTowerArenaInteraction") == null:
		_fail("Power Tower exhibition arena entry is missing.")
		return
	if power_root.get_node_or_null("PowerTowerFloorWorld") == null:
		_fail("Power Tower 200-floor exploration world is not attached.")
		return

	var lift_ui = TOWER_LIFT_UI_SCRIPT.new()
	root.add_child(lift_ui)
	await process_frame
	lift_ui.call("open_for_tower", "hunter_association_tower_baghdad", "برج نقابة الصيادين", 200)
	var available_floor_count := int(lift_ui.call("get_available_floor_count"))
	if available_floor_count != 200:
		_fail("Hunter tower lift UI does not list all 200 floors; listed=%d." % available_floor_count)
		return
	lift_ui.queue_free()

	var headquarters_position: Vector3 = towers.get_headquarters_position()
	if headquarters_position == Vector3.INF:
		_fail("Hunter Association headquarters has no resolved elevated position.")
		return
	if towers.get_node_or_null("HunterAssociationHeadquarters/HeadquartersInterior/HeadquartersExit") == null:
		_fail("Hunter Association headquarters interior exit is missing.")
		return

	var landmarks = LANDMARK_SCRIPT.new()
	region.add_child(landmarks)
	landmarks.call("build", terrain)
	var fake_map := FakeMap.new()
	root.add_child(fake_map)
	# The region manager owns the single registration pass for existing tower roots;
	# the civic landmark manager contributes only tunnel/ruins/motorsport locations.
	for record in tower_records:
		fake_map.call("register_location", "2", str(record.get("id", "")), "region_baghdad", str(record.get("name", "")), 5, record.get("position", Vector3.ZERO), false)
	fake_map.call("register_location", "2", "hunter_association_headquarters_baghdad", "region_baghdad", "المقر الرئيسي لنقابة الصيادين", 5, headquarters_position, false)
	landmarks.call("register_map_locations", fake_map, "2")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required_contract in ["tower_lift_console_", "tower_floor_exit_", "_enter_baghdad_tower_floor", "BaghdadTowerLiftUIScript", "set_hunter_exam_tunnel_access"]:
		if not main_source.contains(required_contract):
			_fail("Main interaction runtime is missing tower lift contract: " + required_contract)
			return
	var region_source := FileAccess.get_file_as_string("res://scripts/modern_world_region_manager.gd")
	if not region_source.contains("tower_manager.call(\"get_tower_positions\")") or not region_source.contains("baghdad_landmarks.call(\"register_map_locations\""):
		_fail("Modern region manager does not register tower roots and Baghdad landmark locations.")
		return
	for record in tower_records:
		var tower_id := str(record.get("id", ""))
		if not fake_map.entries.has(tower_id):
			_fail("Tower is missing from the world map: " + tower_id)
			return
	if not fake_map.entries.has("hunter_association_headquarters_baghdad"):
		_fail("Hunter Association headquarters is missing from the world map.")
		return
	for location_id in ["hunter_exam_tunnel_start_baghdad", "hunter_exam_public_notice_baghdad", "baghdad_archaeological_ruins", "baghdad_international_motorsport_park"]:
		if not fake_map.entries.has(location_id):
			_fail("Baghdad civic/sport landmark is missing from the world map: " + location_id)
			return

	landmarks.free()
	towers.free()
	region.free()
	fake_map.free()
	print("Baghdad tower integration validation passed: five connected playable towers, accessible lobby lifts, independent 200-floor Power Tower, arena, Hunter HQ and all tower/sport/exam map registrations.")
	quit(0)
