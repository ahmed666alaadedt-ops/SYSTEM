
extends Node3D

const PLAYER_SPEED := 6.0
const JUMP_FORCE := 4.5
const GRAVITY := 9.8

const CAMERA_SENSITIVITY := 0.005
const MIN_CAMERA_PITCH := -60.0
const MAX_CAMERA_PITCH := 35.0
const THIRD_PERSON_DISTANCE := 5.0
const FIRST_PERSON_DISTANCE := 0.0
const ROTATION_SPEED := 10.0
const SOVEREIGN_FLIGHT_SPEED := 8.0

const MobileControlsScript = preload("res://scripts/mobile_controls.gd")
const WorldManagerScript = preload("res://scripts/world_manager.gd")
const WorldMapManagerScript = preload("res://scripts/world_map_manager.gd")
const WorldInteractionManagerScript = preload("res://scripts/world_interaction_manager.gd")
const AINPCSocietyManagerScript = preload("res://scripts/ai_npc_society_manager.gd")
const NPCDailyLifeManagerScript = preload("res://scripts/npc_daily_life_manager.gd")
const WorldTimeManagerScript = preload("res://scripts/world_time_manager.gd")
const WildlifeManagerScript = preload("res://scripts/wildlife_manager.gd")
const MissionRewardManagerScript = preload("res://scripts/system_mission_reward_manager.gd")
const PlayerProgressionScript = preload("res://scripts/system_player_progression.gd")
const ModernWorldCombatSystemScript = preload("res://scripts/modern_world_combat_system.gd")
const PlayerVehicleManagerScript = preload("res://scripts/system_player_vehicle_manager.gd")
const VehicleRuntimeManagerScript = preload("res://scripts/system_vehicle_runtime_manager.gd")
const MotorsportManagerScript = preload("res://scripts/system_motorsport_manager.gd")
const MotorsportTrackManagerScript = preload("res://scripts/system_motorsport_track_manager.gd")
const CrimeResponseManagerScript = preload("res://scripts/modern_city_crime_response_manager.gd")
const NPCAutonomousSocietyEventManagerScript = preload("res://scripts/npc_autonomous_society_event_manager.gd")
const NPCVisiblePopulationManagerScript = preload("res://scripts/npc_visible_population_manager.gd")
const NPCSocialInteractionManagerScript = preload("res://scripts/npc_social_interaction_manager.gd")
const NPCCityNavigationManagerScript = preload("res://scripts/npc_city_navigation_manager.gd")
const HunterExamManagerScript = preload("res://scripts/system_hunter_exam_manager.gd")
const HunterExamStageRuntimeScript = preload("res://scripts/system_hunter_exam_stage_runtime.gd")
const PowerTowerManagerScript = preload("res://scripts/system_power_tower_manager.gd")
const BaghdadTowerOperationsManagerScript = preload("res://scripts/system_baghdad_tower_operations_manager.gd")
const PlayerCombatHealthScript = preload("res://scripts/system_player_combat_health.gd")
const InventoryPanelScript = preload("res://scripts/system_inventory_panel.gd")
const PlayerCharacterModelScript = preload("res://scripts/npc_character_model.gd")
const PlayerCharacterCreatorScript = preload("res://scripts/system_player_character_creator.gd")
const SYSTEMCompanionManagerScript = preload("res://scripts/system_companion_manager.gd")
const BataweenMarketplaceUIScript = preload("res://scripts/system_bataween_marketplace_ui.gd")

var world_manager
var world_map_manager
var interaction_manager
var ai_npc_society_manager
var npc_daily_life_manager
var world_time_manager
var wildlife_manager
var mission_reward_manager
var player_progression
var modern_world_combat_system: Node
var player_vehicle_manager
var vehicle_runtime_manager
var motorsport_manager
var motorsport_track_manager
var crime_response_manager
var npc_autonomous_event_manager
var npc_visible_population_manager
var npc_social_interaction_manager
var npc_city_navigation_manager
var hunter_exam_manager
var hunter_exam_stage_runtime: Node3D
var power_tower_manager
var tower_operations_manager
var power_tower_score_event_counter := 0
var player_combat_health: Node
var inventory_panel: CanvasLayer
var bataween_marketplace_ui: CanvasLayer

var active_world_root: Node3D

var player: CharacterBody3D
var player_mesh: Node3D
var player_appearance_profile: Dictionary = {}
var player_character_creator: CanvasLayer
var system_companion_manager: Node3D
var camera: Camera3D
var spring_arm: SpringArm3D
var mobile_controls: Node

var interaction_prompt_layer: CanvasLayer
var interaction_prompt_label: Label
var hunter_exam_invitation_panel: PanelContainer
var hunter_exam_escort_active := false

var mobile_direction := Vector2.ZERO
var jump_requested := false
var flight_vertical_input := 0.0

var camera_yaw := 0.0
var camera_pitch := deg_to_rad(-10.0)
var first_person := false


func _ready() -> void:
	create_world_manager()
	create_wildlife_manager()
	create_ai_npc_society_manager()
	create_npc_daily_life_manager()
	create_world_map_manager()

	create_environment()
	create_world_time_manager()

	create_ground()
	create_player()
	create_player_character_creator()
	create_system_companions()
	register_modern_world_map_locations()
	create_player_progression()
	create_modern_world_combat_system()
	create_inventory_panel()
	create_player_vehicle_manager()
	create_vehicle_runtime_manager()
	create_motorsport_manager()
	create_modern_city_crime_manager()
	create_motorsport_track_manager()
	create_npc_autonomous_society_event_manager()
	create_npc_city_navigation_manager()
	create_npc_visible_population_manager()
	create_npc_social_interaction_manager()
	create_hunter_exam_manager()
	create_power_tower_manager()
	create_mission_reward_manager()

	connect_sovereign_system()

	create_interaction_manager()
	create_mobile_controls()
	create_interaction_prompt()
	create_baghdad_tower_operations_manager()
	call_deferred("_connect_hunter_tower_recruitment")

	update_camera_mode()
	connect_android_runtime_bridge()


func connect_android_runtime_bridge() -> void:
	if not is_instance_valid(SYSTEMAndroidBridge):
		push_warning("SYSTEM: Android runtime bridge autoload is unavailable.")
		return

	var world_callback := Callable(self, "_on_android_world_entry_requested")
	if not SYSTEMAndroidBridge.world_entry_requested.is_connected(world_callback):
		SYSTEMAndroidBridge.world_entry_requested.connect(world_callback)

	if world_manager != null and world_manager.has_signal("world_changed"):
		var changed_callback := Callable(self, "_on_runtime_world_changed")
		if not world_manager.world_changed.is_connected(changed_callback):
			world_manager.world_changed.connect(changed_callback)

	if world_manager != null:
		_publish_runtime_world_state(world_manager.active_world)

	if SYSTEMAndroidBridge.has_pending_world_request():
		call_deferred("_consume_pending_android_world_request")


func _consume_pending_android_world_request() -> void:
	if not is_instance_valid(SYSTEMAndroidBridge):
		return
	var requested_world := SYSTEMAndroidBridge.consume_pending_world_request()
	if not requested_world.is_empty():
		_handle_android_world_entry_request(requested_world)


func _on_android_world_entry_requested(world_id: String) -> void:
	if not is_instance_valid(SYSTEMAndroidBridge):
		return
	if SYSTEMAndroidBridge.has_pending_world_request():
		var pending_world := SYSTEMAndroidBridge.consume_pending_world_request()
		if not pending_world.is_empty():
			world_id = pending_world
	_handle_android_world_entry_request(world_id)


func _handle_android_world_entry_request(world_id: String) -> void:
	# External app launches may start in the modern world only.
	# Other worlds require the in-world Star Gate flow in Baghdad.
	if world_id != "modern":
		SYSTEMAndroidBridge.publish_request_result(
			world_id,
			false,
			"WORLD_ENTRY_REQUIRES_BAGHDAD_STAR_GATE"
		)
		return

	if world_manager == null:
		SYSTEMAndroidBridge.publish_request_result(
			world_id,
			false,
			"WORLD_MANAGER_UNAVAILABLE"
		)
		return

	world_manager.switch_world(WorldManagerScript.WorldID.REALISTIC)
	active_world_root = world_manager.get_active_world()
	SYSTEMAndroidBridge.publish_request_result(
		world_id,
		true,
		"MODERN_WORLD_READY"
	)


func _on_runtime_world_changed(world_id: int) -> void:
	active_world_root = world_manager.get_active_world()
	if vehicle_runtime_manager != null:
		vehicle_runtime_manager.set_world_root(active_world_root)
	_publish_runtime_world_state(world_id)
	if not player_appearance_profile.is_empty():
		var updated_profile := player_appearance_profile.duplicate(true)
		match world_id:
			WorldManagerScript.WorldID.FANTASY:
				updated_profile["world_id"] = "fantasy"
			WorldManagerScript.WorldID.MYTHOLOGY:
				updated_profile["world_id"] = "historical"
			WorldManagerScript.WorldID.REALISTIC:
				updated_profile["world_id"] = "modern"
			WorldManagerScript.WorldID.GREED_ISLAND:
				updated_profile["world_id"] = "greed_island"
		apply_player_appearance(updated_profile, false)


func _publish_runtime_world_state(world_id: int) -> void:
	if not is_instance_valid(SYSTEMAndroidBridge):
		return
	if world_manager == null:
		return

	var world_name: String = str(world_manager.get_world_name(world_id))
	var normalized_id := ""
	match world_id:
		WorldManagerScript.WorldID.FANTASY:
			normalized_id = "fantasy"
		WorldManagerScript.WorldID.MYTHOLOGY:
			normalized_id = "historical"
		WorldManagerScript.WorldID.REALISTIC:
			normalized_id = "modern"
		WorldManagerScript.WorldID.GREED_ISLAND:
			normalized_id = "greed_island"

	if not normalized_id.is_empty():
		SYSTEMAndroidBridge.publish_world_state(normalized_id, world_name)


# --------------------------------------------------
# SOVEREIGN SYSTEM CONNECTION
# --------------------------------------------------

func connect_sovereign_system() -> void:
	if not is_instance_valid(SovereignPower):
		push_warning("SYSTEM: SovereignPower Autoload is unavailable.")
		return

	if world_manager == null:
		push_warning("SYSTEM: WorldManager is unavailable.")
		return

	SovereignPower.connect_world_manager(world_manager)

	print("SYSTEM: Sovereign Power connected to WorldManager.")
	print("SYSTEM: Creator identity verification is not yet configured.")


func request_sovereign_world_travel(world_id: int) -> Dictionary:
	if not is_instance_valid(SovereignPower):
		return {
			"success": false,
			"reason": "SOVEREIGN_SYSTEM_UNAVAILABLE"
		}

	return SovereignPower.travel_to_world(world_id)


func get_sovereign_status() -> Dictionary:
	if not is_instance_valid(SovereignPower):
		return {
			"available": false
		}

	return SovereignPower.get_authority_status()


# --------------------------------------------------
# SOVEREIGN FLIGHT INPUT
# --------------------------------------------------

func _on_flight_vertical_changed(value: float) -> void:
	flight_vertical_input = clampf(value, -1.0, 1.0)


func is_sovereign_flight_active() -> bool:
	if not is_instance_valid(SovereignPower):
		return false

	return (
		SovereignPower.is_sovereign(player)
		and SovereignPower.flight_enabled
	)


func update_sovereign_flight() -> bool:
	if not is_sovereign_flight_active():
		return false

	return SovereignPower.apply_flight_motion(
		flight_vertical_input,
		SOVEREIGN_FLIGHT_SPEED
	)


# --------------------------------------------------
# WORLD MANAGER
# --------------------------------------------------

func create_player_progression() -> void:
	# MainScene.tscn already owns the canonical progression node. Reuse it
	# instead of creating a second, auto-renamed instance with split save state.
	var existing_progression := get_node_or_null("PlayerProgression")
	if existing_progression != null:
		player_progression = existing_progression
		return
	player_progression = PlayerProgressionScript.new()
	player_progression.name = "PlayerProgression"
	add_child(player_progression)


func create_inventory_panel() -> void:
	inventory_panel = InventoryPanelScript.new()
	inventory_panel.name = "SYSTEMInventoryPanel"
	add_child(inventory_panel)
	inventory_panel.call("setup", player_progression)


func create_player_vehicle_manager() -> void:
	player_vehicle_manager = PlayerVehicleManagerScript.new()
	player_vehicle_manager.name = "PlayerVehicleManager"
	add_child(player_vehicle_manager)

	if world_manager != null and world_manager.has_method("get_active_world"):
		var active_root := world_manager.get_active_world() as Node3D
		if active_root != null:
			var region := active_root.get_node_or_null("ModernWorldRegionManager")
			if region != null:
				for dealership in region.get_children():
					if dealership.has_method("setup") and dealership.name.ends_with("VehicleDealership"):
						dealership.setup(player_vehicle_manager)


func create_vehicle_runtime_manager() -> void:
	vehicle_runtime_manager = VehicleRuntimeManagerScript.new()
	vehicle_runtime_manager.name = "VehicleRuntimeManager"
	add_child(vehicle_runtime_manager)
	vehicle_runtime_manager.setup(
		player,
		player_mesh,
		camera,
		spring_arm,
		player_vehicle_manager,
		active_world_root
	)


func create_motorsport_manager() -> void:
	motorsport_manager = MotorsportManagerScript.new()
	motorsport_manager.name = "MotorsportManager"
	add_child(motorsport_manager)
	motorsport_manager.setup(player_vehicle_manager)


func create_motorsport_track_manager() -> void:
	if active_world_root == null:
		push_warning("SYSTEM: Modern world is unavailable for motorsport venue.")
		return
	motorsport_track_manager = MotorsportTrackManagerScript.new()
	motorsport_track_manager.name = "MotorsportTrackManager"
	active_world_root.add_child(motorsport_track_manager)
	motorsport_track_manager.setup(player, vehicle_runtime_manager, motorsport_manager)


func create_modern_city_crime_manager() -> void:
	if active_world_root == null:
		push_warning("SYSTEM: Modern world is unavailable for city crime response.")
		return
	crime_response_manager = CrimeResponseManagerScript.new()
	crime_response_manager.name = "ModernCityCrimeResponseManager"
	crime_response_manager.setup(ai_npc_society_manager)
	active_world_root.add_child(crime_response_manager)
	crime_response_manager.npc_vehicle_stolen.connect(_on_npc_vehicle_stolen)
	crime_response_manager.theft_reported.connect(_on_vehicle_theft_reported)
	crime_response_manager.police_pursuit_started.connect(_on_police_pursuit_started)
	crime_response_manager.stolen_vehicle_recovered.connect(_on_stolen_vehicle_recovered)


func create_npc_autonomous_society_event_manager() -> void:
	if active_world_root == null or crime_response_manager == null:
		push_warning("SYSTEM: Autonomous NPC events require the modern world and crime manager.")
		return
	npc_autonomous_event_manager = NPCAutonomousSocietyEventManagerScript.new()
	npc_autonomous_event_manager.name = "NPCAutonomousSocietyEventManager"
	active_world_root.add_child(npc_autonomous_event_manager)
	npc_autonomous_event_manager.setup(ai_npc_society_manager, crime_response_manager)


func create_npc_city_navigation_manager() -> void:
	if active_world_root == null:
		return
	var region_manager := active_world_root.get_node_or_null("ModernWorldRegionManager")
	npc_city_navigation_manager = NPCCityNavigationManagerScript.new()
	npc_city_navigation_manager.name = "NPCCityNavigationManager"
	active_world_root.add_child(npc_city_navigation_manager)
	npc_city_navigation_manager.setup(region_manager)


func create_npc_visible_population_manager() -> void:
	if active_world_root == null or ai_npc_society_manager == null:
		push_warning("SYSTEM: Visible NPC population requires the active modern world and society manager.")
		return
	npc_visible_population_manager = NPCVisiblePopulationManagerScript.new()
	npc_visible_population_manager.name = "NPCVisiblePopulationManager"
	active_world_root.add_child(npc_visible_population_manager)
	var region_manager := active_world_root.get_node_or_null("ModernWorldRegionManager")
	npc_visible_population_manager.setup(
		ai_npc_society_manager,
		npc_daily_life_manager,
		crime_response_manager,
		region_manager,
		npc_city_navigation_manager
	)


func create_npc_social_interaction_manager() -> void:
	if active_world_root == null or ai_npc_society_manager == null or npc_visible_population_manager == null:
		push_warning("SYSTEM: Social interactions require society and visible population managers.")
		return
	npc_social_interaction_manager = NPCSocialInteractionManagerScript.new()
	npc_social_interaction_manager.name = "NPCSocialInteractionManager"
	active_world_root.add_child(npc_social_interaction_manager)
	npc_social_interaction_manager.setup(ai_npc_society_manager, npc_visible_population_manager)


func _on_npc_vehicle_stolen(vehicle_id: String, owner_npc_id: String, city_name: String) -> void:
	print("SYSTEM CRIME: NPC vehicle stolen: ", vehicle_id, " owner=", owner_npc_id, " city=", city_name)


func _on_vehicle_theft_reported(vehicle_id: String, city_name: String) -> void:
	print("SYSTEM POLICE: Vehicle theft reported in ", city_name, ": ", vehicle_id)


func _on_police_pursuit_started(vehicle_id: String, city_name: String) -> void:
	print("SYSTEM POLICE: Pursuit started for ", vehicle_id, " in ", city_name)


func _on_stolen_vehicle_recovered(vehicle_id: String, city_name: String) -> void:
	print("SYSTEM POLICE: Stolen vehicle recovered in ", city_name, ": ", vehicle_id)


func create_hunter_exam_manager() -> void:
	hunter_exam_manager = HunterExamManagerScript.new()
	hunter_exam_manager.name = "HunterExamManager"
	add_child(hunter_exam_manager)
	hunter_exam_manager.stage_completed.connect(_on_hunter_exam_stage_completed)
	hunter_exam_manager.stage_started.connect(_on_hunter_exam_stage_started)
	hunter_exam_manager.license_earned.connect(_on_hunter_exam_license_earned)


func create_power_tower_manager() -> void:
	power_tower_manager = PowerTowerManagerScript.new()
	power_tower_manager.name = "PowerTowerManager"
	add_child(power_tower_manager)
	power_tower_manager.floor_cleared.connect(_on_power_tower_floor_cleared)
	power_tower_manager.floor_cleared.connect(_on_public_power_tower_floor_cleared)
	power_tower_manager.duel_score_updated.connect(_on_power_tower_duel_score_updated)
	power_tower_manager.duel_completed.connect(_on_power_tower_duel_completed)


func create_modern_world_combat_system() -> void:
	modern_world_combat_system = ModernWorldCombatSystemScript.new()
	modern_world_combat_system.name = "ModernWorldCombatSystem"
	add_child(modern_world_combat_system)
	modern_world_combat_system.call("bind_actor", player, camera, player_progression)
	modern_world_combat_system.attack_performed.connect(_on_power_tower_attack_performed)


func create_baghdad_tower_operations_manager() -> void:
	if active_world_root == null:
		return
	var region_manager := active_world_root.get_node_or_null("ModernWorldRegionManager")
	if region_manager == null:
		push_warning("SYSTEM: Baghdad tower operations require the modern region manager.")
		return
	tower_operations_manager = BaghdadTowerOperationsManagerScript.new()
	tower_operations_manager.name = "BaghdadTowerOperationsManager"
	add_child(tower_operations_manager)
	tower_operations_manager.call(
		"setup",
		player,
		player_progression,
		ai_npc_society_manager,
		power_tower_manager,
		player_combat_health,
		region_manager
	)


func _on_power_tower_attack_performed(damage: float, hit_target: Node) -> void:
	if not is_instance_valid(tower_operations_manager) or not bool(tower_operations_manager.get("power_floor_in_progress")):
		return
	var active_match: Dictionary = tower_operations_manager.get("active_power_tower_match")
	if active_match.is_empty():
		return
	var match_id := str(active_match.get("match_id", ""))
	var local_player_id := str(active_match.get("local_player_id", ""))
	if match_id.is_empty() or local_player_id.is_empty():
		return
	power_tower_score_event_counter += 1
	var event_type := "CRITICAL_HIT" if damage >= 80.0 else "CLEAN_HIT"
	var event_id := "%s_local_hit_%08d" % [match_id, power_tower_score_event_counter]
	power_tower_manager.call("record_judged_duel_event", match_id, "HEAD_REFEREE", local_player_id, event_type, event_id)
	if is_instance_valid(hit_target) and bool(hit_target.get_meta("system_duel_knockdown", false)):
		power_tower_score_event_counter += 1
		power_tower_manager.call("record_judged_duel_event", match_id, "SAFETY_JUDGE", local_player_id, "OPPONENT_DOWN", "%s_local_down_%08d" % [match_id, power_tower_score_event_counter])


func _on_power_tower_duel_score_updated(_match_id: String, duel_data: Dictionary) -> void:
	if tower_operations_manager != null:
		tower_operations_manager.call("update_power_tower_live_match_display", int(duel_data.get("floor", 0)), duel_data, false)


func _on_power_tower_duel_completed(_match_id: String, duel_data: Dictionary) -> void:
	if tower_operations_manager != null:
		tower_operations_manager.call("update_power_tower_live_match_display", int(duel_data.get("floor", 0)), duel_data, true)


func _on_power_tower_floor_cleared(floor_number: int, reward_xp: int, rank: String) -> void:
	if player_progression != null:
		player_progression.add_experience(reward_xp, "Power Tower floor %d (%s)" % [floor_number, rank])



func _get_public_event_board() -> Node:
	return get_tree().root.find_child("SYSTEMPublicEventBoard", true, false)


func _on_public_mission_rewarded(mission_id: String, xp_amount: int) -> void:
	var board := _get_public_event_board()
	if board != null and board.has_method("publish_mission_completion"):
		board.call("publish_mission_completion", mission_id, xp_amount)


func _on_hunter_exam_stage_started(stage_id: String, stage_number: int) -> void:
	if stage_id != "baghdad_tunnel_competition":
		push_warning("SYSTEM HUNTER EXAM: unsupported continuous competition stage %d (%s)." % [stage_number, stage_id])
		return
	var tunnel_root := get_tree().root.find_child("BaghdadHunterExaminationTunnel", true, false) as Node3D
	if tunnel_root == null:
		push_warning("SYSTEM HUNTER EXAM: Baghdad tunnel root is unavailable.")
		return
	hunter_exam_stage_runtime = tunnel_root.get_node_or_null("HunterExamStageRuntime") as Node3D
	if hunter_exam_stage_runtime == null:
		hunter_exam_stage_runtime = HunterExamStageRuntimeScript.new()
		hunter_exam_stage_runtime.name = "HunterExamStageRuntime"
		hunter_exam_stage_runtime.position = Vector3(0.0, 0.0, 40.0)
		tunnel_root.add_child(hunter_exam_stage_runtime)
	var stage_data: Dictionary = hunter_exam_manager.get_current_stage()
	var build_result: Dictionary = hunter_exam_stage_runtime.call("activate_stage", stage_data, player, hunter_exam_manager)
	if not bool(build_result.get("success", false)):
		push_warning("SYSTEM HUNTER EXAM: continuous tunnel environment activation failed: %s" % str(build_result.get("reason", "unknown")))
		return
	var rival_manager: Node = hunter_exam_stage_runtime.get("rival_competition")
	if is_instance_valid(rival_manager) and rival_manager.has_signal("rival_event"):
		var rival_callback := Callable(self, "_on_hunter_rival_event")
		if not rival_manager.is_connected("rival_event", rival_callback):
			rival_manager.connect("rival_event", rival_callback)
	if is_instance_valid(player):
		player.velocity = Vector3.ZERO
		player.global_position = hunter_exam_stage_runtime.to_global(Vector3(0.0, 1.2, 2.0))
		player.set_meta("system_hunter_exam_active_stage", stage_id)
	if interaction_prompt_label != null:
		interaction_prompt_label.text = "بدأت المسابقة المتصلة في نفق الصيادين — رقم المتسابق %d" % int(hunter_exam_manager.get_exam_overview().get("candidate_number", 0))
		interaction_prompt_label.show()
	print("SYSTEM HUNTER EXAM: single continuous Baghdad tunnel competition activated; stage %d." % stage_number)

func _on_hunter_rival_event(message: String) -> void:
	if interaction_prompt_label == null:
		return
	interaction_prompt_label.text = message
	interaction_prompt_label.show()


func _on_hunter_exam_stage_completed(stage_id: String, stage_number: int) -> void:
	var board := _get_public_event_board()
	if board != null and board.has_method("publish_exam_stage"):
		board.call("publish_exam_stage", stage_id, stage_number)


func _on_hunter_exam_license_earned(candidate_number: int, license_rank: String) -> void:
	var board := _get_public_event_board()
	if board != null and board.has_method("publish_exam_champion"):
		board.call("publish_exam_champion", candidate_number, license_rank)


func _on_public_power_tower_floor_cleared(floor_number: int, _reward_xp: int, rank: String) -> void:
	var board := _get_public_event_board()
	if board != null and board.has_method("publish_power_tower_clear"):
		board.call("publish_power_tower_clear", floor_number, rank)


func _on_hunter_exam_registration_requested() -> void:
	if hunter_exam_manager == null:
		return
	var overview: Dictionary = hunter_exam_manager.get_exam_overview()
	var result: Dictionary
	if bool(overview.get("registered", false)):
		result = {
			"success": true,
			"candidate_number": int(overview.get("candidate_number", 0)),
			"message": "أنت مسجل بالفعل. رقمك التسلسلي محفوظ؛ اتبع مرشد نقابة الصيادين."
		}
	elif bool(overview.get("invitation_accepted", false)):
		result = {
			"success": true,
			"message": "تم قبول طلبك. اتبع مرشد نقابة الصيادين إلى النفق لاستلام رقمك التسلسلي هناك."
		}
	else:
		result = {
			"success": false,
			"reason": "INVITATION_NOT_ACCEPTED",
			"message": "ابدأ بقبول دعوة نقابة الصيادين من ردهة البرج."
		}
	var menu := get_node_or_null("HunterGuildMenu")
	if menu != null and menu.has_method("set_exam_status"):
		menu.call("set_exam_status", result)
	if interaction_prompt_label != null:
		interaction_prompt_label.text = str(result.get("message", "اتبع مرشد النقابة."))
		interaction_prompt_label.show()

func _on_hunter_exam_start_requested() -> void:
	if hunter_exam_manager == null:
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "نظام اختبار الصيادين غير متاح حالياً."
			interaction_prompt_label.show()
		return
	var overview: Dictionary = hunter_exam_manager.get_exam_overview()
	if not bool(overview.get("invitation_accepted", false)):
		_show_hunter_exam_invitation()
		return
	if not bool(overview.get("registered", false)) or not bool(player.get_meta("system_inside_hunter_exam_tunnel", false)):
		_handle_hunter_exam_guide_interaction()
		return
	var result: Dictionary = hunter_exam_manager.begin_exam()
	if bool(result.get("success", false)):
		if bool(result.get("resumed", false)):
			_on_hunter_exam_stage_started("baghdad_tunnel_competition", 1)
	elif interaction_prompt_label != null:
		interaction_prompt_label.text = "تعذر بدء المسابقة: %s" % str(result.get("reason", "غير معروف"))
		interaction_prompt_label.show()

func _connect_hunter_tower_recruitment() -> void:
	var arrival_zone := get_tree().root.find_child("HunterTowerRecruitmentArrivalZone", true, false) as Area3D
	if arrival_zone == null:
		push_warning("SYSTEM Hunter Exam: Hunter Tower arrival zone is missing.")
		return
	var callback := Callable(self, "_on_hunter_tower_arrival_body_entered")
	if not arrival_zone.body_entered.is_connected(callback):
		arrival_zone.body_entered.connect(callback)


func _on_hunter_tower_arrival_body_entered(body: Node3D) -> void:
	if body != player or hunter_exam_manager == null:
		return
	var overview: Dictionary = hunter_exam_manager.get_exam_overview()
	if bool(overview.get("registered", false)) or bool(overview.get("invitation_accepted", false)):
		if interaction_prompt_label != null:
			if bool(overview.get("registered", false)):
				interaction_prompt_label.text = "أهلاً بعودتك أيها الصياد. رقمك التسلسلي %d محفوظ؛ يمكنك متابعة المسابقة من المرشد." % int(overview.get("candidate_number", 0))
			else:
				interaction_prompt_label.text = "طلبك مقبول مبدئياً. تفاعل مع مرشد نقابة الصيادين ليصطحبك إلى النفق."
			interaction_prompt_label.show()
		return
	_show_hunter_exam_invitation()

func _show_hunter_exam_invitation() -> void:
	if hunter_exam_invitation_panel != null:
		hunter_exam_invitation_panel.show()
	if interaction_prompt_label != null:
		interaction_prompt_label.hide()


func _on_hunter_exam_invitation_declined() -> void:
	if hunter_exam_invitation_panel != null:
		hunter_exam_invitation_panel.hide()
	if interaction_prompt_label != null:
		interaction_prompt_label.text = "يمكنك التسجيل في اختبار الصيادين لاحقاً من برج الصيادين."
		interaction_prompt_label.show()


func _on_hunter_exam_invitation_accepted() -> void:
	if hunter_exam_manager == null:
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "نظام نقابة الصيادين غير متاح حالياً."
			interaction_prompt_label.show()
		return
	var result: Dictionary = hunter_exam_manager.accept_exam_invitation("local_player")
	if not bool(result.get("success", false)):
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر قبول طلبك: %s" % str(result.get("reason", "غير معروف"))
			interaction_prompt_label.show()
		return
	if is_instance_valid(player):
		player.set_meta("system_hunter_exam_invitation_accepted", true)
	if hunter_exam_invitation_panel != null:
		hunter_exam_invitation_panel.hide()
	if interaction_prompt_label != null:
		interaction_prompt_label.text = "تم قبولك مبدئياً. اتبع مرشد نقابة الصيادين؛ سيصطحبك إلى نفق المنافسة ويسلمك رقمك التسلسلي عند الوصول."
		interaction_prompt_label.show()

func _start_hunter_guild_escort(guide: Node) -> void:
	if not is_instance_valid(player) or not is_instance_valid(guide) or hunter_exam_manager == null:
		return
	var overview: Dictionary = hunter_exam_manager.get_exam_overview()
	if not bool(overview.get("invitation_accepted", false)):
		_show_hunter_exam_invitation()
		return
	if hunter_exam_escort_active:
		return
	if bool(player.get_meta("system_inside_hunter_exam_tunnel", false)):
		var resumed_result: Dictionary = hunter_exam_manager.begin_exam()
		if bool(resumed_result.get("success", false)) and bool(resumed_result.get("resumed", false)):
			_on_hunter_exam_stage_started("baghdad_tunnel_competition", 1)
		return
	if player.global_position.distance_to(guide.global_position) > 8.0:
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "مرشد النقابة موجود داخل برج الصيادين. اقترب منه أولاً ليصطحبك إلى النفق."
			interaction_prompt_label.show()
		return
	var tunnel_root := get_tree().root.find_child("BaghdadHunterExaminationTunnel", true, false) as Node3D
	if tunnel_root == null:
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر العثور على نفق اختبار الصيادين."
			interaction_prompt_label.show()
		return
	var guide_node := guide as Node3D
	var guide_origin := guide_node.global_position
	var tunnel_guide := tunnel_root.get_node_or_null("HunterGuildGuideAtTunnel") as Area3D
	if tunnel_guide == null:
		tunnel_guide = guide_node.duplicate() as Area3D
		if tunnel_guide == null:
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "تعذر تجهيز مرشد الوصول داخل النفق."
				interaction_prompt_label.show()
			return
		tunnel_guide.name = "HunterGuildGuideAtTunnel"
		tunnel_guide.add_to_group("system_interactable")
		tunnel_guide.set_meta("system_hunter_exam_guide", true)
		tunnel_guide.set_meta("system_interaction_prompt", "مرشد النقابة: تحدث معي لمتابعة المنافسة")
		tunnel_root.add_child(tunnel_guide)
	tunnel_guide.global_position = guide_origin
	tunnel_root.set_meta("system_hunter_exam_guide_present", true)
	hunter_exam_escort_active = true
	player.set_meta("system_hunter_exam_escort_active", true)
	player.velocity = Vector3.ZERO
	var destination := tunnel_root.to_global(Vector3(0.0, 1.0, -1.5))
	if interaction_prompt_label != null:
		interaction_prompt_label.text = "مرشد النقابة: ابقَ قريباً مني. نتجه الآن إلى نفق المنافسة."
		interaction_prompt_label.show()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(tunnel_guide, "global_position", destination + Vector3(0.0, 0.0, 2.0), 5.0)
	tween.parallel().tween_property(player, "global_position", destination, 5.0)
	tween.finished.connect(func():
		if not is_instance_valid(player):
			hunter_exam_escort_active = false
			return
		player.velocity = Vector3.ZERO
		player.set_meta("system_hunter_exam_escort_active", false)
		player.set_meta("system_inside_hunter_exam_tunnel", true)
		var registration: Dictionary = hunter_exam_manager.register_candidate_at_tunnel("local_player")
		if not bool(registration.get("success", false)):
			player.set_meta("system_inside_hunter_exam_tunnel", false)
			hunter_exam_escort_active = false
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "تعذر إكمال تسجيلك داخل النفق: %s" % str(registration.get("reason", "غير معروف"))
				interaction_prompt_label.show()
			return
		var candidate_number := int(registration.get("candidate_number", 0))
		player.set_meta("system_hunter_exam_candidate_number", candidate_number)
		var start_result: Dictionary = hunter_exam_manager.begin_exam()
		if not bool(start_result.get("success", false)):
			hunter_exam_escort_active = false
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "وصلت إلى النفق، لكن تعذر بدء المنافسة: %s" % str(start_result.get("reason", "غير معروف"))
				interaction_prompt_label.show()
			return
		if bool(start_result.get("resumed", false)):
			_on_hunter_exam_stage_started("baghdad_tunnel_competition", 1)
		hunter_exam_escort_active = false
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "وصلت إلى نفق الصيادين. رقمك التسلسلي الدائم: %d — بدأت المنافسة المتصلة. المرشد بانتظارك داخل النفق." % candidate_number
			interaction_prompt_label.show()
	)

func _handle_hunter_exam_guide_interaction() -> void:
	var guide := get_tree().root.find_child("HunterGuildGuideAtTower", true, false)
	_start_hunter_guild_escort(guide)

func create_mission_reward_manager() -> void:
	mission_reward_manager = MissionRewardManagerScript.new()
	mission_reward_manager.name = "MissionRewardManager"
	add_child(mission_reward_manager)
	mission_reward_manager.mission_rewarded.connect(_on_public_mission_rewarded)

	var hunter_guild_menu := get_node_or_null("HunterGuildMenu")

	if hunter_guild_menu == null:
		push_warning("SYSTEM: HunterGuildMenu is unavailable; mission acceptance is not connected.")
		return

	if not hunter_guild_menu.has_signal("mission_accepted"):
		push_warning("SYSTEM: HunterGuildMenu has no mission_accepted signal.")
		return

	hunter_guild_menu.mission_accepted.connect(_on_hunter_mission_accepted)
	if hunter_guild_menu.has_signal("exam_registration_requested"):
		hunter_guild_menu.exam_registration_requested.connect(_on_hunter_exam_registration_requested)
	if hunter_guild_menu.has_signal("exam_start_requested"):
		hunter_guild_menu.exam_start_requested.connect(_on_hunter_exam_start_requested)

	print("SYSTEM: Mission rewards connected to Hunter Guild and Player Progression.")


func _on_hunter_mission_accepted(mission_id: String) -> void:
	if not is_instance_valid(mission_reward_manager):
		push_warning("SYSTEM: Mission reward manager is unavailable.")
		return

	if not mission_reward_manager.accept_mission(mission_id):
		push_warning("SYSTEM: Could not accept hunter mission: " + mission_id)


## يستدعيها نظام تحقق موثوق فقط بعد إكمال أهداف المهمة فعلياً.
func confirm_verified_hunter_mission(mission_id: String) -> bool:
	if not is_instance_valid(mission_reward_manager):
		return false

	return mission_reward_manager.confirm_verified_completion(mission_id)


func create_world_manager() -> void:
	world_manager = WorldManagerScript.new()
	world_manager.name = "WorldManager"
	add_child(world_manager)

	active_world_root = world_manager.get_active_world()


# --------------------------------------------------
# WILDLIFE SYSTEM
# --------------------------------------------------

func create_wildlife_manager() -> void:
	if active_world_root == null:
		push_warning("SYSTEM WORLD: Modern world is missing.")
		return

	wildlife_manager = WildlifeManagerScript.new()
	wildlife_manager.name = "WildlifeManager"

	active_world_root.add_child(wildlife_manager)

	print("SYSTEM WORLD: Wildlife system initialized.")


func create_ai_npc_society_manager() -> void:
	ai_npc_society_manager = AINPCSocietyManagerScript.new()
	ai_npc_society_manager.name = "AINPCSocietyManager"
	add_child(ai_npc_society_manager)


func create_npc_daily_life_manager() -> void:
	npc_daily_life_manager = NPCDailyLifeManagerScript.new()
	npc_daily_life_manager.name = "NPCDailyLifeManager"
	add_child(npc_daily_life_manager)
	npc_daily_life_manager.setup(ai_npc_society_manager)


func register_modern_world_map_locations() -> void:
	if world_map_manager == null or world_manager == null:
		return
	var modern_root: Node = world_manager.get_world_root(2)
	if modern_root == null:
		return
	var region_manager: Node = modern_root.get_node_or_null("ModernWorldRegionManager")
	if region_manager == null:
		return
	if region_manager.has_method("register_map_locations"):
		region_manager.call("register_map_locations", world_map_manager, "2")
	if region_manager.has_method("discover_starting_city"):
		region_manager.call("discover_starting_city", world_map_manager, str(WorldManagerScript.WorldID.REALISTIC))


func create_world_map_manager() -> void:
	world_map_manager = WorldMapManagerScript.new()
	world_map_manager.name = "WorldMapManager"
	add_child(world_map_manager)

	world_map_manager.map_updated.connect(_on_map_updated)
	world_map_manager.fast_travel_confirmed.connect(_on_fast_travel_confirmed)


func create_world_time_manager() -> void:
	world_time_manager = WorldTimeManagerScript.new()
	world_time_manager.name = "WorldTimeManager"
	add_child(world_time_manager)

	var initialized: bool = world_time_manager.setup(active_world_root)

	if not initialized:
		push_warning("SYSTEM WORLD: Time manager initialization failed.")
		return

	print(
		"SYSTEM WORLD local time: ",
		world_time_manager.get_time_label()
	)


func create_interaction_manager() -> void:
	interaction_manager = WorldInteractionManagerScript.new()
	interaction_manager.name = "WorldInteractionManager"
	add_child(interaction_manager)

	interaction_manager.setup(
		player,
		camera,
		world_map_manager,
		world_manager
	)

	interaction_manager.interaction_target_changed.connect(
		_on_interaction_target_changed
	)

	interaction_manager.interaction_performed.connect(
		_on_interaction_performed
	)

	interaction_manager.location_discovered.connect(
		_on_location_discovered
	)

	interaction_manager.fast_travel_point_activated.connect(
		_on_fast_travel_point_activated
	)


func create_interaction_prompt() -> void:
	interaction_prompt_layer = CanvasLayer.new()
	interaction_prompt_layer.name = "InteractionPromptLayer"
	interaction_prompt_layer.layer = 9
	add_child(interaction_prompt_layer)

	interaction_prompt_label = Label.new()
	interaction_prompt_label.name = "InteractionPrompt"
	interaction_prompt_label.text = ""
	interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	interaction_prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	interaction_prompt_label.position = Vector2(-180, 85)
	interaction_prompt_label.size = Vector2(360, 55)

	interaction_prompt_label.add_theme_font_size_override("font_size", 22)
	interaction_prompt_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.85, 0.55)
	)

	interaction_prompt_layer.add_child(interaction_prompt_label)
	interaction_prompt_label.hide()

	hunter_exam_invitation_panel = PanelContainer.new()
	hunter_exam_invitation_panel.name = "HunterExamInvitationPanel"
	hunter_exam_invitation_panel.set_anchors_preset(Control.PRESET_CENTER)
	hunter_exam_invitation_panel.position = Vector2(-230.0, -105.0)
	hunter_exam_invitation_panel.size = Vector2(460.0, 210.0)
	hunter_exam_invitation_panel.custom_minimum_size = Vector2(460.0, 210.0)
	var invitation_layout := VBoxContainer.new()
	invitation_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	hunter_exam_invitation_panel.add_child(invitation_layout)
	var invitation_title := Label.new()
	invitation_title.text = "دعوة نقابة الصيادين"
	invitation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invitation_title.add_theme_font_size_override("font_size", 25)
	invitation_layout.add_child(invitation_title)
	var invitation_text := Label.new()
	invitation_text.name = "InvitationText"
	invitation_text.text = "هل تريد أن تصبح صياداً وتسجل في اختبار الصيادين؟"
	invitation_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invitation_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	invitation_text.custom_minimum_size = Vector2(420.0, 65.0)
	invitation_text.add_theme_font_size_override("font_size", 21)
	invitation_layout.add_child(invitation_text)
	var invitation_buttons := HBoxContainer.new()
	invitation_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	invitation_layout.add_child(invitation_buttons)
	var accept_button := Button.new()
	accept_button.name = "AcceptHunterExamInvitation"
	accept_button.text = "نعم، أريد أن أصبح صياداً"
	accept_button.custom_minimum_size = Vector2(220.0, 48.0)
	accept_button.pressed.connect(_on_hunter_exam_invitation_accepted)
	invitation_buttons.add_child(accept_button)
	var decline_button := Button.new()
	decline_button.name = "DeclineHunterExamInvitation"
	decline_button.text = "ليس الآن"
	decline_button.custom_minimum_size = Vector2(120.0, 48.0)
	decline_button.pressed.connect(_on_hunter_exam_invitation_declined)
	invitation_buttons.add_child(decline_button)
	interaction_prompt_layer.add_child(hunter_exam_invitation_panel)
	hunter_exam_invitation_panel.hide()


## معرّف الخريطة النصي يطابق رقم العالم الحالي في WorldManager.
func get_current_map_world_id() -> String:
	if world_manager == null:
		return ""

	return str(world_manager.active_world)


## نقطة تسجيل موحدة حتى تسجل العوالم مواقعها في مدير الخريطة.
func register_world_location(
	location_id: String,
	region_id: String,
	display_name: String,
	location_type: int,
	location_position: Vector3,
	is_fast_travel_point: bool = false
) -> bool:
	if world_map_manager == null:
		return false

	return world_map_manager.register_location(
		get_current_map_world_id(),
		location_id,
		region_id,
		display_name,
		location_type,
		location_position,
		is_fast_travel_point
	)


func discover_world_region(region_id: String) -> bool:
	if world_map_manager == null:
		return false

	return world_map_manager.discover_region(
		get_current_map_world_id(),
		region_id
	)


func discover_world_location(location_id: String) -> bool:
	if world_map_manager == null:
		return false

	return world_map_manager.discover_location(
		get_current_map_world_id(),
		location_id
	)


func activate_world_fast_travel_point(
	point_id: String,
	activation_distance: float = 3.0
) -> bool:
	if world_map_manager == null or player == null:
		return false

	return world_map_manager.activate_fast_travel_point(
		get_current_map_world_id(),
		point_id,
		player.global_position,
		activation_distance
	)


## يعيد نتيجة التحقق والوجهة المقترحة؛ لا ينفذ النقل وحده.
func request_world_fast_travel(point_id: String) -> Dictionary:
	if world_map_manager == null:
		return {
			"success": false,
			"reason": "MAP_MANAGER_NOT_READY"
		}

	return world_map_manager.request_fast_travel(
		get_current_map_world_id(),
		point_id
	)


## تستدعى بعد أن ينفذ نظام الحركة نقل اللاعب بنجاح.
func complete_world_fast_travel(point_id: String) -> void:
	if world_map_manager != null:
		world_map_manager.confirm_fast_travel(
			get_current_map_world_id(),
			point_id
		)


func _on_map_updated(world_id: String) -> void:
	print("SYSTEM WORLD map updated for world: ", world_id)


func _on_fast_travel_confirmed(
	world_id: String,
	point_id: String
) -> void:
	print(
		"SYSTEM WORLD fast travel confirmed: ",
		world_id,
		" / ",
		point_id
	)


func _on_interaction_target_changed(
	target: Node,
	prompt: String
) -> void:
	if interaction_prompt_label == null:
		return

	if target == null or prompt.is_empty():
		interaction_prompt_label.hide()
		interaction_prompt_label.text = ""
		return

	interaction_prompt_label.text = prompt + "  [E / USE]"
	interaction_prompt_label.show()


func _start_historical_relic_quest() -> void:
	if world_manager == null or player == null or player_progression == null:
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر بدء المهمة: نظام العالم أو اللاعب غير جاهز."
			interaction_prompt_label.show()
		return
	var return_position := player.global_position
	world_manager.call("switch_world", WorldManagerScript.WorldID.MYTHOLOGY)
	var historical_root: Node = world_manager.call("get_world_root", WorldManagerScript.WorldID.MYTHOLOGY)
	var relic_runtime: Node = historical_root.get_node_or_null("HistoricalRelicQuestRuntime") if historical_root != null else null
	if relic_runtime == null or not relic_runtime.has_method("begin_quest"):
		world_manager.call("switch_world", WorldManagerScript.WorldID.REALISTIC)
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر تحميل مهمة الأثر التاريخي."
			interaction_prompt_label.show()
		return
	var result: Dictionary = relic_runtime.call("begin_quest", player_progression, player, world_manager, return_position)
	if interaction_prompt_label != null:
		interaction_prompt_label.text = str(result.get("message", "بدأت المهمة التاريخية."))
		interaction_prompt_label.show()


func _start_assyrian_relic_quest() -> void:
	if world_manager == null or player == null or player_progression == null:
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر بدء المهمة الآشورية: نظام العالم أو اللاعب غير جاهز."
			interaction_prompt_label.show()
		return
	var return_position := player.global_position
	world_manager.call("switch_world", WorldManagerScript.WorldID.MYTHOLOGY)
	var historical_root: Node = world_manager.call("get_world_root", WorldManagerScript.WorldID.MYTHOLOGY)
	var relic_runtime: Node = historical_root.get_node_or_null("AssyrianRelicQuestRuntime") if historical_root != null else null
	if relic_runtime == null or not relic_runtime.has_method("begin_quest"):
		world_manager.call("switch_world", WorldManagerScript.WorldID.REALISTIC)
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر تحميل مهمة حراس نينوى."
			interaction_prompt_label.show()
		return
	var result: Dictionary = relic_runtime.call("begin_quest", player_progression, player, world_manager, return_position)
	if interaction_prompt_label != null:
		interaction_prompt_label.text = str(result.get("message", "بدأت مهمة حراس نينوى."))
		interaction_prompt_label.show()


func _on_interaction_performed(
	target: Node,
	location_id: String
) -> void:
	print(
		"SYSTEM interaction performed: ",
		target.name,
		" / ",
		location_id
	)
	if target.has_meta("system_assyrian_relic_quest_start"):
		_start_assyrian_relic_quest()
		return
	if target.has_meta("system_historical_relic_quest_start"):
		_start_historical_relic_quest()
		return
	if target.has_meta("system_assyrian_relic_objective") or target.has_meta("system_assyrian_relic_return"):
		var historical_root: Node = world_manager.call("get_world_root", WorldManagerScript.WorldID.MYTHOLOGY) if world_manager != null else null
		var assyrian_runtime: Node = historical_root.get_node_or_null("AssyrianRelicQuestRuntime") if historical_root != null else null
		if assyrian_runtime == null or not assyrian_runtime.has_method("handle_interaction"):
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "نظام مهمة حراس نينوى غير متاح."
			return
		var assyrian_result: Dictionary = assyrian_runtime.call("handle_interaction", target)
		if interaction_prompt_label != null:
			interaction_prompt_label.text = str(assyrian_result.get("message", "تم التفاعل مع الختم الآشوري."))
			interaction_prompt_label.show()
		return
	if target.has_meta("system_historical_relic_objective") or target.has_meta("system_historical_relic_return"):
		var historical_root: Node = world_manager.call("get_world_root", WorldManagerScript.WorldID.MYTHOLOGY) if world_manager != null else null
		var relic_runtime: Node = historical_root.get_node_or_null("HistoricalRelicQuestRuntime") if historical_root != null else null
		if relic_runtime == null or not relic_runtime.has_method("handle_interaction"):
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "نظام المهمة التاريخية غير متاح."
			return
		var relic_result: Dictionary = relic_runtime.call("handle_interaction", target)
		if interaction_prompt_label != null:
			interaction_prompt_label.text = str(relic_result.get("message", "تم التفاعل مع الأثر التاريخي."))
			interaction_prompt_label.show()
		return
	if target.has_meta("system_bataween_market_action"):
		if not is_instance_valid(bataween_marketplace_ui):
			bataween_marketplace_ui = BataweenMarketplaceUIScript.new()
			bataween_marketplace_ui.name = "BataweenMarketplaceUI"
			add_child(bataween_marketplace_ui)
		bataween_marketplace_ui.call("open_market")
		return
	if target.has_meta("system_exam_stage_objective") or target.has_meta("system_exam_rival_id"):
		if hunter_exam_stage_runtime == null or not hunter_exam_stage_runtime.has_method("handle_interaction"):
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "نظام أهداف الاختبار غير متاح حالياً."
			return
		var objective_result: Dictionary = hunter_exam_stage_runtime.call("handle_interaction", target)
		if bool(objective_result.get("handled", false)):
			if interaction_prompt_label != null:
				interaction_prompt_label.text = str(objective_result.get("message", "تم التفاعل مع هدف الاختبار."))
			return
	if target.has_meta("system_hunter_exam_secret_interaction"):
		var entrance_root: Node = target
		while entrance_root != null and not entrance_root.has_method("handle_interaction"):
			entrance_root = entrance_root.get_parent()
		if entrance_root == null:
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "نظام المدخل السري غير متاح حالياً."
				interaction_prompt_label.show()
			return
		if entrance_root.has_method("set_exam_manager"):
			entrance_root.call("set_exam_manager", hunter_exam_manager)
		var secret_result: Dictionary = entrance_root.call("handle_interaction", target)
		if interaction_prompt_label != null:
			interaction_prompt_label.text = str(secret_result.get("message", "تم التفاعل مع المدخل السري."))
			interaction_prompt_label.show()
		return
	if target.has_meta("system_hunter_exam_tower_guide"):
		_start_hunter_guild_escort(target)
		return
	if target.has_meta("system_hunter_exam_guide"):
		_handle_hunter_exam_guide_interaction()
		return
	if target.has_meta("system_power_tower_spectator_seat_interaction") and tower_operations_manager != null:
		tower_operations_manager.call("interact_power_tower_spectator_seat", target)
		return
	if target.has_meta("system_power_tower_prediction_board") and tower_operations_manager != null:
		tower_operations_manager.call("open_power_tower_ticket_terminal")
		return
	if target.has_meta("system_power_tower_ticket_terminal") and tower_operations_manager != null:
		tower_operations_manager.call("open_power_tower_ticket_terminal")
		return
	if str(target.get_meta("system_interaction_type", "")) == "museum_artifact_exhibit" and tower_operations_manager != null:
		tower_operations_manager.call("open_museum_artifact_exhibit", target)
		return
	if target.has_meta("system_pool_service_type") and tower_operations_manager != null:
		tower_operations_manager.call("open_pool_service", target)
		return
	if target.has_meta("system_tower_staff_id") and tower_operations_manager != null:
		tower_operations_manager.call("open_staff_service", target)
		return
	if target.has_meta("system_restaurant_table_id") and tower_operations_manager != null:
		tower_operations_manager.call("open_restaurant_table", target)
		return
	if target.has_meta("system_hotel_room_id") and tower_operations_manager != null:
		tower_operations_manager.call("open_hotel_room_preview", str(target.get_meta("system_hotel_room_id", "")))
		return
	if target.has_meta("system_arcade_cabinet_id") and tower_operations_manager != null:
		tower_operations_manager.call(
			"open_arcade_cabinet",
			str(target.get_meta("system_tower_id", "")),
			int(target.get_meta("system_tower_floor_number", 0)),
			int(target.get_meta("system_arcade_cabinet_id", -1)),
			str(target.get_meta("system_arcade_cabinet_mode", ""))
		)
		return
	if bool(target.get_meta("system_tower_elevator_destination", false)) and tower_operations_manager != null:
		tower_operations_manager.call("open_tower", str(target.get_meta("system_tower_id", "")))
		return
	if target.has_meta("system_showcase_product_id") and target.has_meta("system_facility_type") and target.has_meta("system_tower_floor_number") and target.has_meta("system_tower_id") and tower_operations_manager != null:
		tower_operations_manager.call(
			"open_showcase_product_service",
			str(target.get_meta("system_tower_id", "")),
			int(target.get_meta("system_tower_floor_number", 0)),
			str(target.get_meta("system_facility_type", "")),
			str(target.get_meta("system_showcase_product_id", ""))
		)
		return
	if target.has_meta("system_facility_type") and target.has_meta("system_tower_floor_number") and target.has_meta("system_tower_id") and tower_operations_manager != null:
		tower_operations_manager.call(
			"open_facility_service",
			str(target.get_meta("system_tower_id", "")),
			int(target.get_meta("system_tower_floor_number", 0)),
			str(target.get_meta("system_facility_type", ""))
		)
		return
	if target.has_meta("system_tower_floor_number") and target.has_meta("system_tower_id") and tower_operations_manager != null:
		tower_operations_manager.call(
			"open_floor_services",
			str(target.get_meta("system_tower_id", "")),
			int(target.get_meta("system_tower_floor_number", 0))
		)
		return
	if bool(target.get_meta("system_tower_elevator_return", false)) and tower_operations_manager != null:
		tower_operations_manager.call("return_to_lobby")
		return
	if location_id.begins_with("baghdad_osm_entrance_"):
		var entrance_name := str(target.get_meta("system_display_name", "مدخل محدد على الخريطة"))
		var entrance_kind := str(target.get_meta("system_entrance_type", "غير محدد"))
		var access_tag := str(target.get_meta("system_access_tag", "unknown"))
		var wheelchair_tag := str(target.get_meta("system_wheelchair_tag", "unknown"))
		var access_note := "هذه نقطة مدخل موثقة في بيانات الخريطة؛ مشهد المبنى الداخلي لم يُنفذ بعد."
		if access_tag == "private" or access_tag == "no":
			access_note += " الوصول مقيّد حسب بيانات المصدر."
		var accessibility_note := "إمكانية وصول الكراسي المتحركة غير محددة."
		if wheelchair_tag == "yes":
			accessibility_note = "بيانات المصدر تشير إلى إمكانية وصول الكراسي المتحركة."
		elif wheelchair_tag == "no":
			accessibility_note = "بيانات المصدر تشير إلى عدم تهيئة المدخل للكراسي المتحركة."
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "%s\nنوع المدخل: %s | الوصول: %s\n%s\n%s" % [
				entrance_name,
				entrance_kind,
				access_tag,
				access_note,
				accessibility_note
			]
	elif location_id.begins_with("baghdad_osm_building_") or location_id.begins_with("baghdad_osm_approach_"):
		var building_name := str(target.get_meta("system_display_name", "مبنى في بغداد"))
		var building_kind := str(target.get_meta("baghdad_building_type", "general_building"))
		var estimated_floors := int(target.get_meta("system_estimated_floors", 1))
		var height_m := float(target.get_meta("system_building_height_m", 0.0))
		var access_note := "المبنى الخارجي مكتشف؛ الدخول والداخلية لم يُنفذا بعد."
		if location_id.begins_with("baghdad_osm_approach_"):
			var road_distance := float(target.get_meta("system_approach_distance_m", 0.0))
			access_note = "نقطة اقتراب تقريبية تبعد %.1f م عن أقرب طريق؛ ليست باباً مؤكداً." % road_distance
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "%s | %s | نحو %d طابق | ارتفاع تقديري %.1f م\n%s" % [
				building_name,
				building_kind,
				estimated_floors,
				height_m,
				access_note
			]
	if str(target.get_meta("system_service_type", "")) == "hospital":
		if is_instance_valid(player_combat_health):
			if bool(player_combat_health.call("begin_hospital_treatment")):
				if interaction_prompt_label != null:
					interaction_prompt_label.text = "بدأ العلاج في المستشفى — يرجى الانتظار حتى اكتماله"
			elif interaction_prompt_label != null:
				interaction_prompt_label.text = "لا تحتاج إلى علاج حالياً أو أن العلاج جارٍ بالفعل"
	var tower_id := str(target.get_meta("system_tower_id", location_id))
	if tower_id in [
		"hunter_association_tower_baghdad",
		"business_investment_tower_baghdad",
		"shopping_tower_baghdad",
		"antiques_heritage_tower_baghdad",
		"technology_tower_baghdad",
		"power_tower_baghdad"
	]:
		var tower_name := str(target.get_meta("system_display_name", "برج بغداد"))
		var floor_count := int(target.get_meta("system_tower_floor_count", 0))
		var height_m := float(target.get_meta("system_tower_height_m", 0.0))
		var connected := bool(target.get_meta("system_tower_district_member", false))
		var network_label := "ضمن مجمع الأبراج الخمسة المترابط" if connected else "مستقل عن المجمع"
		var directory := ""
		match tower_id:
			"hunter_association_tower_baghdad":
				directory = "الأقسام: الإدارة العليا للنقابة، تسجيل الصيادين، المهمات، اختبارات الصيادين، استشارات الرتب، النقابات، قاعات التدريب، المكتبة والأرشيف، قاعة الشرف العالمية، ومهبط المروحيات فوق البرج، ومقهى واستراحة للزوار."
			"business_investment_tower_baghdad":
				directory = "الأقسام: إدارة الشركات، الاستثمار والتمويل، البنوك والحسابات، العقود والاستشارات القانونية، المحاسبة، التوظيف، قاعة التداول والبورصة، مركز المؤتمرات، وصالة المستثمرين، ومقهى للزوار."
			"shopping_tower_baghdad":
				directory = "الأقسام: الأسواق والمتاجر، الأسلحة الحديثة والتقليدية، السيوف والأقواس والسهام، الدروع والخوذ والبدلات حسب الرتب، الحدادة وإصلاح المعدات، مختبر إيقاظ النِن والتحكم والتثبيت والاستعادة، صيدلية العلاج والأكاسير، فندق SYSTEM في الطابقين 27–28، والمطاعم والمقاهي والمخابز في الطوابق 29–32."
			"antiques_heritage_tower_baghdad":
				directory = "الأقسام: متحف الآثار العراقية وحضارات العالم، قاعات السومرية والبابلية والآشورية والمصرية واليونانية والصينية، مختبر البحث والتنقيب، ترميم القطع، توثيق الملكية والأصالة وسجل المنشأ، المعارض الدائمة والخاصة، صالات المقتنين، ومزاد وتجارة القطع الأثرية بين اللاعبين."
			"technology_tower_baghdad":
				directory = "الأقسام: مختبرات الروبوتات، الذكاء الاصطناعي، الواقع الافتراضي والمحاكاة، هندسة الأجهزة، الصيانة، الخدمات الرقمية، معرض الابتكار، ومنصة الرصد التقني، ومقهى واستراحة."
			"power_tower_baghdad":
				directory = "برج منافسات مستقل من 200 طابق؛ لاعب بشري ضد لاعب بشري 1 ضد 1 فقط، عشر بيئات قتالية، ومدرج مشجعين بسعة 48 مقعداً في كل ساحة؛ لا خصوم آليين ولا فرق، والمطابقة عبر الإنترنت قيد الإعداد."
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "%s\n%d طابق | ارتفاع تقريبي %.0f م\n%s\n%s\nملاحظة: المرافق الداخلية تُنشأ عند زيارة طوابقها؛ خدمات الموظفين والشراء والبيع ومخزون المتاجر وحركة زبائن NPC تعمل محلياً، والربط الجماعي عبر الخادم والتحقق البصري على الهاتف ما زالا ضمن التحقق." % [
				tower_name, floor_count, height_m, network_label, directory
			]
	if tower_operations_manager != null:
		tower_operations_manager.call("open_tower", tower_id)


func _on_location_discovered(
	world_id: String,
	location_id: String
) -> void:
	print(
		"SYSTEM location discovered: ",
		world_id,
		" / ",
		location_id
	)


func _on_fast_travel_point_activated(
	world_id: String,
	point_id: String
) -> void:
	print(
		"SYSTEM fast travel point activated: ",
		world_id,
		" / ",
		point_id
	)


func _on_mobile_interact_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.try_dealership_interaction():
		return
	if interaction_manager == null:
		return

	interaction_manager.interact_with_target()


# --------------------------------------------------
# CINEMATIC CITY ENVIRONMENT
# --------------------------------------------------

func create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "ModernCityEnvironment"

	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()

	sky_material.sky_top_color = Color(0.055, 0.12, 0.23)
	sky_material.sky_horizon_color = Color(0.48, 0.57, 0.68)
	sky_material.ground_bottom_color = Color(0.10, 0.12, 0.15)
	sky_material.ground_horizon_color = Color(0.36, 0.40, 0.43)
	sky_material.sun_angle_max = 25.0
	sky_material.sun_curve = 0.15

	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.65, 0.78)
	environment.ambient_light_energy = 0.65

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0

	environment.fog_enabled = true
	environment.fog_light_color = Color(0.48, 0.57, 0.68)
	environment.fog_density = 0.0015

	world_environment.environment = environment
	active_world_root.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "ModernCitySun"
	sun.rotation_degrees = Vector3(-38, -30, 0)
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	active_world_root.add_child(sun)


# --------------------------------------------------
# CITY GROUND AND COLLISION
# --------------------------------------------------

func create_ground() -> void:
	if active_world_root != null and active_world_root.get_node_or_null("ModernContinent") != null:
		return

	var ground := StaticBody3D.new()
	ground.name = "ModernCityGround"
	ground.position = Vector3(0, 0, -45)
	active_world_root.add_child(ground)

	var ground_size := Vector3(100, 1, 160)

	var mesh := MeshInstance3D.new()
	mesh.name = "GroundVisual"

	var box := BoxMesh.new()
	box.size = ground_size
	mesh.mesh = box
	mesh.position.y = -0.5

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.21, 0.22)
	material.roughness = 0.95
	mesh.material_override = material

	ground.add_child(mesh)

	var collision := CollisionShape3D.new()
	collision.name = "GroundCollision"

	var shape := BoxShape3D.new()
	shape.size = ground_size
	collision.shape = shape
	collision.position.y = -0.5

	ground.add_child(collision)


# --------------------------------------------------
# PLAYER
# --------------------------------------------------

func create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.add_to_group("system_player")
	player.position = Vector3(0, 2, 0)
	player_combat_health = PlayerCombatHealthScript.new()
	player_combat_health.name = "PlayerCombatHealth"
	player.add_child(player_combat_health)
	player_combat_health.call("bind_player", player)
	active_world_root.add_child(player)

	apply_player_appearance(_load_player_appearance_profile(), false)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape
	player.add_child(collision)

	spring_arm = SpringArm3D.new()
	spring_arm.position = Vector3(0, 0.65, 0)
	spring_arm.spring_length = THIRD_PERSON_DISTANCE
	player.add_child(spring_arm)

	camera = Camera3D.new()
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 300.0
	spring_arm.add_child(camera)
	camera.current = true

	update_camera_rotation()


func _default_player_appearance_profile() -> Dictionary:
	return {
		"name": "الصياد الجديد",
		"gender": "male",
		"age": 25,
		"age_group": "adult",
		"body_type": "athletic",
		"height_type": "average",
		"skin_tone": "olive",
		"hair_style": "short",
		"hair_color": "black",
		"eye_color": "brown",
		"face_shape": "balanced",
		"job": "hunter",
		"world_id": "modern",
		"is_player_character": true
	}


func _load_player_appearance_profile() -> Dictionary:
	var config := ConfigFile.new()
	if config.load("user://system_player_profile.cfg") != OK:
		return _default_player_appearance_profile()
	var saved: Variant = config.get_value("appearance", "profile", {})
	if saved is Dictionary:
		var profile: Dictionary = _default_player_appearance_profile()
		profile.merge(saved, true)
		return profile
	return _default_player_appearance_profile()


## Rebuilds the live player with the shared rigged GLB character pipeline.
## Appearance is saved locally so it survives a new game session on this device.
func apply_player_appearance(profile: Dictionary, persist: bool = true) -> void:
	if not is_instance_valid(player):
		return
	if is_instance_valid(player_mesh):
		player_mesh.queue_free()
	player_appearance_profile = _default_player_appearance_profile()
	player_appearance_profile.merge(profile, true)
	player_appearance_profile["is_player_character"] = true
	player_appearance_profile["age_group"] = "adult"
	player_appearance_profile["age"] = maxi(18, int(player_appearance_profile.get("age", 25)))
	player_appearance_profile["job"] = "hunter"
	player_mesh = PlayerCharacterModelScript.new()
	player_mesh.name = "PlayerCharacterVisual"
	player.add_child(player_mesh)
	player_mesh.call("configure", player_appearance_profile, int(player_appearance_profile.get("variant_index", 0)))
	player_mesh.call("set_activity", "idle")
	if persist:
		var config := ConfigFile.new()
		config.set_value("appearance", "profile", player_appearance_profile)
		var save_error := config.save("user://system_player_profile.cfg")
		if save_error != OK:
			push_warning("SYSTEM: Could not save the player appearance profile.")


func set_player_character_activity(activity: String) -> void:
	if not is_instance_valid(player_mesh) or not player_mesh.has_method("set_activity"):
		return
	if str(player_mesh.get("current_activity")) != activity:
		player_mesh.call("set_activity", activity)


func create_system_companions() -> void:
	system_companion_manager = SYSTEMCompanionManagerScript.new()
	system_companion_manager.name = "SYSTEMCompanionManager"
	add_child(system_companion_manager)
	system_companion_manager.call("setup", player, world_manager)


func create_player_character_creator() -> void:
	player_character_creator = PlayerCharacterCreatorScript.new()
	player_character_creator.name = "SYSTEMPlayerCharacterCreator"
	add_child(player_character_creator)
	player_character_creator.call("setup", self)


# --------------------------------------------------
# MOBILE CONTROLS
# --------------------------------------------------

func create_mobile_controls() -> void:
	mobile_controls = MobileControlsScript.new()
	add_child(mobile_controls)

	mobile_controls.movement_changed.connect(_on_movement_changed)
	mobile_controls.jump_pressed.connect(_on_jump_pressed)
	mobile_controls.look_changed.connect(_on_look_changed)
	mobile_controls.camera_toggle_pressed.connect(_on_camera_toggle_pressed)
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)
	mobile_controls.flight_vertical_changed.connect(_on_flight_vertical_changed)
	mobile_controls.attack_pressed.connect(_on_mobile_attack_pressed)
	mobile_controls.skill_one_pressed.connect(_on_mobile_skill_one_pressed)
	mobile_controls.skill_two_pressed.connect(_on_mobile_skill_two_pressed)
	mobile_controls.relic_echo_pressed.connect(_on_mobile_relic_echo_pressed)
	mobile_controls.relic_aegis_pressed.connect(_on_mobile_relic_aegis_pressed)
	mobile_controls.dodge_pressed.connect(_on_mobile_dodge_pressed)


func _on_mobile_attack_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		return
	if is_instance_valid(modern_world_combat_system):
		modern_world_combat_system.call("light_attack")


func _on_mobile_skill_one_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		return
	if is_instance_valid(modern_world_combat_system):
		modern_world_combat_system.call("skill_one")


func _on_mobile_skill_two_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		return
	if is_instance_valid(modern_world_combat_system):
		modern_world_combat_system.call("skill_two")


func _on_mobile_relic_aegis_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		return
	if player_progression == null or player == null:
		return
	var result: Dictionary = player_progression.call("record_system_skill_use", "ashur_guardian_aegis")
	if not bool(result.get("success", false)):
		var reason := str(result.get("reason", "UNKNOWN"))
		var message := "درع الحارس الآشوري غير متاح."
		if reason == "SKILL_NOT_LEARNED":
			message = "أكمل مهمة حراس نينوى وتدرب ثلاث مرات أولاً."
		elif reason == "SKILL_COOLDOWN":
			message = "درع الحارس الآشوري يحتاج انتظار %.0f ثانية." % float(result.get("remaining_seconds", 0.0))
		elif reason == "SYSTEM_ENERGY_LOW":
			message = "تحتاج 35 طاقة لتفعيل درع الحارس الآشوري."
		if interaction_prompt_label != null:
			interaction_prompt_label.text = message
			interaction_prompt_label.show()
		return
	player.set_meta("system_assyrian_aegis_until_msec", Time.get_ticks_msec() + 12000)
	_create_assyrian_aegis_visual()
	if interaction_prompt_label != null:
		interaction_prompt_label.text = "درع الحارس الآشوري نشط: تقليل الضرر 65% لمدة 12 ثانية."
		interaction_prompt_label.show()


func _create_assyrian_aegis_visual() -> void:
	var previous := player.get_node_or_null("AssyrianGuardianAegis")
	if previous != null:
		previous.queue_free()
	var shield := MeshInstance3D.new()
	shield.name = "AssyrianGuardianAegis"
	var sphere := SphereMesh.new()
	sphere.radius = 1.25
	sphere.height = 2.5
	shield.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.58, 0.18, 0.24)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.7
	material.roughness = 0.18
	material.emission_enabled = true
	material.emission = Color(0.95, 0.52, 0.12)
	shield.material_override = material
	shield.position = Vector3(0.0, 1.0, 0.0)
	player.add_child(shield)
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(shield, "scale", Vector3.ONE * 1.08, 0.8)
	pulse.tween_property(shield, "scale", Vector3.ONE, 0.8)
	var expiry_timer := get_tree().create_timer(12.0)
	expiry_timer.timeout.connect(func() -> void:
		if is_instance_valid(shield):
			shield.queue_free()
	)


func _on_mobile_relic_echo_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		return
	if player_progression == null or player == null:
		return
	var result: Dictionary = player_progression.call("record_system_skill_use", "relic_echo_sight")
	if not bool(result.get("success", false)):
		var reason := str(result.get("reason", "UNKNOWN"))
		var message := "مهارة عين صدى الأثر غير متاحة."
		if reason == "SKILL_NOT_LEARNED":
			message = "تحتاج إكمال مهمة الأثر النادر والتدريب ثلاث مرات أولاً."
		elif reason == "SKILL_COOLDOWN":
			message = "عين صدى الأثر تحتاج إلى انتظار %.0f ثانية." % float(result.get("remaining_seconds", 0.0))
		elif reason == "SYSTEM_ENERGY_LOW":
			message = "طاقة النظام غير كافية لتفعيل عين صدى الأثر."
		if interaction_prompt_label != null:
			interaction_prompt_label.text = message
			interaction_prompt_label.show()
		return
	var revealed := 0
	for trace in get_tree().get_nodes_in_group("system_hidden_historical_trace"):
		if not is_instance_valid(trace) or not (trace is Node3D):
			continue
		if player.global_position.distance_to((trace as Node3D).global_position) > 32.0:
			continue
		(trace as Node3D).visible = true
		(trace as Node3D).set_meta("system_echo_revealed", true)
		revealed += 1
	_create_relic_echo_pulse()
	if interaction_prompt_label != null:
		interaction_prompt_label.text = "عين صدى الأثر كشفت %d أثراً خفياً قريباً لمدة 10 ثوانٍ." % revealed if revealed > 0 else "انطلقت موجة صدى الأثر، لكن لا توجد آثار مخفية قريبة."
		interaction_prompt_label.show()
	_hide_relic_echo_traces_after_delay()


func _create_relic_echo_pulse() -> void:
	var pulse := MeshInstance3D.new()
	pulse.name = "RelicEchoSightPulse"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.88
	ring.outer_radius = 1.0
	pulse.mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.78, 1.0, 0.72)
	material.emission_enabled = true
	material.emission = Color(0.12, 0.68, 1.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse.material_override = material
	pulse.rotation.x = PI * 0.5
	pulse.position = Vector3(0.0, 0.15, 0.0)
	player.add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector3.ONE * 32.0, 1.15)
	tween.parallel().tween_property(material, "albedo_color", Color(0.18, 0.78, 1.0, 0.0), 1.15)
	await get_tree().create_timer(1.25).timeout
	if is_instance_valid(pulse):
		pulse.queue_free()


func _hide_relic_echo_traces_after_delay() -> void:
	await get_tree().create_timer(10.0).timeout
	for trace in get_tree().get_nodes_in_group("system_hidden_historical_trace"):
		if is_instance_valid(trace) and trace is Node3D and bool((trace as Node3D).get_meta("system_echo_revealed", false)):
			(trace as Node3D).visible = false
			(trace as Node3D).set_meta("system_echo_revealed", false)


func _on_mobile_dodge_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		return
	if is_instance_valid(modern_world_combat_system):
		modern_world_combat_system.call("dodge")


func _on_movement_changed(direction: Vector2) -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		vehicle_runtime_manager.set_mobile_movement(direction)
		return
	mobile_direction = direction


func _on_jump_pressed() -> void:
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		vehicle_runtime_manager.apply_mobile_brake()
		return
	jump_requested = true


func _on_look_changed(delta: Vector2) -> void:
	camera_yaw -= delta.x * CAMERA_SENSITIVITY
	camera_pitch -= delta.y * CAMERA_SENSITIVITY

	camera_pitch = clampf(
		camera_pitch,
		deg_to_rad(MIN_CAMERA_PITCH),
		deg_to_rad(MAX_CAMERA_PITCH)
	)

	update_camera_rotation()


func _on_camera_toggle_pressed() -> void:
	first_person = not first_person
	update_camera_mode()


func update_camera_mode() -> void:
	if spring_arm == null:
		return

	if first_person:
		spring_arm.spring_length = FIRST_PERSON_DISTANCE
		player_mesh.visible = false
	else:
		spring_arm.spring_length = THIRD_PERSON_DISTANCE
		player_mesh.visible = true

	update_camera_rotation()


func update_camera_rotation() -> void:
	if spring_arm == null:
		return

	spring_arm.rotation = Vector3(
		camera_pitch,
		camera_yaw,
		0.0
	)


# --------------------------------------------------
# PLAYER MOVEMENT
# --------------------------------------------------

func _physics_process(delta: float) -> void:
	if player == null:
		return
	if bool(player.get_meta("system_helicopter_piloting", false)):
		return
	if bool(player.get_meta("system_tower_elevator_active", false)):
		player.velocity = Vector3.ZERO
		return
	if bool(player.get_meta("system_hunter_exam_escort_active", false)):
		player.velocity = Vector3.ZERO
		return
	if bool(player.get_meta("system_restaurant_seated", false)) or bool(player.get_meta("system_restaurant_seating_transition", false)):
		player.velocity = Vector3.ZERO
		return
	if bool(player.get_meta("system_power_tower_seated", false)):
		player.velocity = Vector3.ZERO
		return
	if vehicle_runtime_manager != null and vehicle_runtime_manager.is_driving:
		return

	var direction := Vector3.ZERO

	direction.x = mobile_direction.x
	direction.z = mobile_direction.y

	if Input.is_key_pressed(KEY_W):
		direction.z -= 1

	if Input.is_key_pressed(KEY_S):
		direction.z += 1

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1

	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	direction = direction.normalized()

	var camera_basis := spring_arm.global_transform.basis
	var forward := -camera_basis.z
	var right := camera_basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var move_direction := right * direction.x
	move_direction += forward * -direction.z
	move_direction = move_direction.normalized()
	var is_in_hospital_treatment := bool(player.get_meta("system_hospital_treatment", false))
	var is_swimming := bool(player.get_meta("system_swimming", false))
	var movement_speed := PLAYER_SPEED
	if is_swimming:
		movement_speed *= 0.62
	if bool(player.get_meta("system_wounded", false)):
		movement_speed *= 0.7
	if is_instance_valid(player_progression) and player_progression.has_method("get_movement_multiplier"):
		movement_speed *= float(player_progression.call("get_movement_multiplier"))
	if is_in_hospital_treatment:
		move_direction = Vector3.ZERO
		movement_speed = 0.0

	player.velocity.x = move_direction.x * movement_speed
	player.velocity.z = move_direction.z * movement_speed

	if move_direction.length() > 0.01:
		var target_angle := atan2(
			move_direction.x,
			move_direction.z
		)

		player.rotation.y = lerp_angle(
			player.rotation.y,
			target_angle,
			ROTATION_SPEED * delta
		)

	var flight_controlled := update_sovereign_flight()

	if not flight_controlled:
		if is_swimming:
			var swim_surface_y := float(player.get_meta("system_swim_surface_y", player.global_position.y + 0.25))
			var swim_target_y := swim_surface_y - 0.25
			var swim_stroke_requested := not is_in_hospital_treatment and (jump_requested or Input.is_action_just_pressed("ui_accept"))
			if swim_stroke_requested:
				player.velocity.y = 2.6
				player.set_meta("system_swim_last_stroke_force", 2.6)
			else:
				player.remove_meta("system_swim_last_stroke_force")
				var buoyancy_error := swim_target_y - player.global_position.y
				player.velocity.y = clampf(buoyancy_error * 3.2, -2.0, 2.0)
		elif not player.is_on_floor():
			player.remove_meta("system_swim_last_stroke_force")
			player.velocity.y -= GRAVITY * delta
		elif not is_in_hospital_treatment and (jump_requested or Input.is_key_pressed(KEY_SPACE)):
			player.velocity.y = JUMP_FORCE

	jump_requested = false
	player.move_and_slide()
	if is_instance_valid(player_mesh):
		var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.15
		set_player_character_activity("run" if moving else "idle")
