
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
const PowerTowerManagerScript = preload("res://scripts/system_power_tower_manager.gd")
const PlayerCombatHealthScript = preload("res://scripts/system_player_combat_health.gd")
const InventoryPanelScript = preload("res://scripts/system_inventory_panel.gd")
const PlayerCharacterModelScript = preload("res://scripts/npc_character_model.gd")
const PlayerCharacterCreatorScript = preload("res://scripts/system_player_character_creator.gd")
const SYSTEMCompanionManagerScript = preload("res://scripts/system_companion_manager.gd")
const SYSTEMEconomyManagerScript = preload("res://scripts/system_economy_manager.gd")
const SYSTEMBusinessServicesMenuScript = preload("res://scripts/system_business_services_menu.gd")

var world_manager
var world_map_manager
var interaction_manager
var ai_npc_society_manager
var npc_daily_life_manager
var world_time_manager
var wildlife_manager
var mission_reward_manager
var player_progression
var player_vehicle_manager
var economy_manager: Node
var business_services_menu: CanvasLayer
var vehicle_runtime_manager
var motorsport_manager
var motorsport_track_manager
var crime_response_manager
var npc_autonomous_event_manager
var npc_visible_population_manager
var npc_social_interaction_manager
var npc_city_navigation_manager
var hunter_exam_manager
var power_tower_manager
var player_combat_health: Node
var inventory_panel: CanvasLayer

var active_world_root: Node3D

var player: CharacterBody3D
var player_mesh: Node3D
var player_appearance_profile: Dictionary = {}
var player_character_creator: CanvasLayer
var system_companion_manager: Node3D
var camera: Camera3D
var spring_arm: SpringArm3D
var mobile_controls: MobileControls

var interaction_prompt_layer: CanvasLayer
var interaction_prompt_label: Label
var motorsport_leaderboard_layer: CanvasLayer
var motorsport_leaderboard_panel: PanelContainer
var motorsport_leaderboard_event_select: OptionButton
var motorsport_leaderboard_best_label: Label
var motorsport_leaderboard_rows: VBoxContainer

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
	create_inventory_panel()
	create_player_vehicle_manager()
	create_business_services()
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
	create_motorsport_leaderboard_ui()

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


func create_business_services() -> void:
	economy_manager = SYSTEMEconomyManagerScript.new()
	economy_manager.name = "SYSTEMEconomyManager"
	economy_manager.setup(player_vehicle_manager)
	add_child(economy_manager)

	business_services_menu = SYSTEMBusinessServicesMenuScript.new()
	business_services_menu.name = "SYSTEMBusinessServicesMenu"
	business_services_menu.setup(economy_manager)
	add_child(business_services_menu)


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
	motorsport_manager.race_finished.connect(_on_motorsport_race_finished)


func _on_motorsport_race_finished(result: Dictionary) -> void:
	var elapsed := maxf(0.0, float(result.get("elapsed_seconds", 0.0)))
	var total_ms := int(round(elapsed * 1000.0))
	var minutes := int(total_ms / 60000)
	var seconds := int(total_ms / 1000) % 60
	var milliseconds := total_ms % 1000
	var time_label := "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	var records: Dictionary = result.get("records", {})
	var best := maxf(0.0, float(records.get("best_time_seconds", elapsed)))
	var best_ms := int(round(best * 1000.0))
	var best_label := "%02d:%02d.%03d" % [int(best_ms / 60000), int(best_ms / 1000) % 60, best_ms % 1000]
	var status := "رقمك الشخصي الجديد!" if bool(records.get("is_personal_best", false)) else "تم تسجيل المحاولة."
	var scope_note := "السجل محفوظ على هذا الجهاز فقط؛ ليس ترتيباً عالمياً."
	if not bool(records.get("saved", false)):
		scope_note = "تعذر حفظ السجل؛ النتيجة الحالية ظاهرة فقط."
	if interaction_prompt_label != null:
		interaction_prompt_label.text = "اكتمل %s!\nزمنك: %s | أفضل زمن محلي: %s\n%s\n%s" % [
			str(result.get("event_name", "السباق")),
			time_label,
			best_label,
			status,
			scope_note
		]

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
	if world_manager == null:
		return
	var modern_root := world_manager.get_world_root(WorldManagerScript.WorldID.REALISTIC) as Node3D
	if modern_root == null:
		return
	active_world_root = modern_root
	var region_manager := modern_root.get_node_or_null("ModernWorldRegionManager")
	npc_city_navigation_manager = NPCCityNavigationManagerScript.new()
	npc_city_navigation_manager.name = "NPCCityNavigationManager"
	modern_root.add_child(npc_city_navigation_manager)
	npc_city_navigation_manager.setup(region_manager)


func create_npc_visible_population_manager() -> void:
	if world_manager == null or ai_npc_society_manager == null:
		push_warning("SYSTEM: Visible NPC population requires the modern world and society manager.")
		return
	var modern_root := world_manager.get_world_root(WorldManagerScript.WorldID.REALISTIC) as Node3D
	if modern_root == null:
		push_warning("SYSTEM: Modern world root is unavailable for visible NPC population.")
		return
	active_world_root = modern_root
	npc_visible_population_manager = NPCVisiblePopulationManagerScript.new()
	npc_visible_population_manager.name = "NPCVisiblePopulationManager"
	modern_root.add_child(npc_visible_population_manager)
	var region_manager := modern_root.get_node_or_null("ModernWorldRegionManager")
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
	hunter_exam_manager.license_earned.connect(_on_hunter_exam_license_earned)


func create_power_tower_manager() -> void:
	power_tower_manager = PowerTowerManagerScript.new()
	power_tower_manager.name = "PowerTowerManager"
	add_child(power_tower_manager)
	power_tower_manager.floor_cleared.connect(_on_power_tower_floor_cleared)
	power_tower_manager.floor_cleared.connect(_on_public_power_tower_floor_cleared)


func _on_power_tower_floor_cleared(floor_number: int, reward_xp: int, rank: String) -> void:
	if player_progression != null:
		player_progression.add_experience(reward_xp, "Power Tower floor %d (%s)" % [floor_number, rank])



func _get_public_event_board() -> Node:
	return get_tree().root.find_child("SYSTEMPublicEventBoard", true, false)


func _on_public_mission_rewarded(mission_id: String, xp_amount: int) -> void:
	var board := _get_public_event_board()
	if board != null and board.has_method("publish_mission_completion"):
		board.call("publish_mission_completion", mission_id, xp_amount)


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
	var result: Dictionary = hunter_exam_manager.apply_for_exam("local_player")
	var menu := get_node_or_null("HunterGuildMenu")
	if menu != null and menu.has_method("set_exam_status"):
		menu.call("set_exam_status", result)


func _on_hunter_exam_start_requested() -> void:
	if hunter_exam_manager == null:
		return
	var result: Dictionary = hunter_exam_manager.begin_exam()
	var menu := get_node_or_null("HunterGuildMenu")
	if menu != null and menu.has_method("set_exam_status"):
		menu.call("set_exam_status", result)


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


func create_motorsport_leaderboard_ui() -> void:
	motorsport_leaderboard_layer = CanvasLayer.new()
	motorsport_leaderboard_layer.name = "MotorsportLeaderboardLayer"
	motorsport_leaderboard_layer.layer = 18
	add_child(motorsport_leaderboard_layer)

	motorsport_leaderboard_panel = PanelContainer.new()
	motorsport_leaderboard_panel.name = "MotorsportLeaderboardPanel"
	motorsport_leaderboard_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	motorsport_leaderboard_panel.offset_left = 12.0
	motorsport_leaderboard_panel.offset_top = 82.0
	motorsport_leaderboard_panel.offset_right = -12.0
	motorsport_leaderboard_panel.offset_bottom = -82.0
	motorsport_leaderboard_panel.visible = false
	motorsport_leaderboard_layer.add_child(motorsport_leaderboard_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	motorsport_leaderboard_panel.add_child(layout)

	var heading := Label.new()
	heading.text = "SYSTEM MOTORSPORT — لوحة النتائج"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	layout.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "مضمار بغداد الدولي | أفضل الأزمنة المسجلة على هذا الجهاز"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)

	motorsport_leaderboard_event_select = OptionButton.new()
	motorsport_leaderboard_event_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(motorsport_leaderboard_event_select)
	motorsport_leaderboard_event_select.item_selected.connect(_on_motorsport_leaderboard_event_selected)

	motorsport_leaderboard_best_label = Label.new()
	motorsport_leaderboard_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	motorsport_leaderboard_best_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(motorsport_leaderboard_best_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	motorsport_leaderboard_rows = VBoxContainer.new()
	motorsport_leaderboard_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(motorsport_leaderboard_rows)

	var scope_note := Label.new()
	scope_note.text = "تنبيه: هذا ترتيب محلي لمحاولاتك فقط، وليس ترتيباً عالمياً بين اللاعبين."
	scope_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scope_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(scope_note)

	var close_button := Button.new()
	close_button.text = "إغلاق اللوحة"
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(_close_motorsport_leaderboard)
	layout.add_child(close_button)

	var catalog: Dictionary = motorsport_manager.get_event_catalog() if motorsport_manager != null else {}
	var event_ids: Array = catalog.keys()
	event_ids.sort()
	for event_id in event_ids:
		var event_data: Dictionary = catalog[event_id]
		motorsport_leaderboard_event_select.add_item(str(event_data.get("name", event_id)))
		motorsport_leaderboard_event_select.set_item_metadata(
			motorsport_leaderboard_event_select.item_count - 1,
			str(event_id)
		)
	if motorsport_leaderboard_event_select.item_count > 0:
		motorsport_leaderboard_event_select.select(0)
		_refresh_motorsport_leaderboard()


func _show_motorsport_leaderboard() -> void:
	if motorsport_leaderboard_layer == null:
		return
	motorsport_leaderboard_panel.show()
	_refresh_motorsport_leaderboard()


func _close_motorsport_leaderboard() -> void:
	if motorsport_leaderboard_layer != null:
		motorsport_leaderboard_panel.hide()


func _on_motorsport_leaderboard_event_selected(_index: int) -> void:
	_refresh_motorsport_leaderboard()


func _format_motorsport_time(elapsed_seconds: float) -> String:
	var total_ms := int(round(maxf(0.0, elapsed_seconds) * 1000.0))
	var minutes := int(total_ms / 60000)
	var seconds := int(total_ms / 1000) % 60
	var milliseconds := total_ms % 1000
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]


func _refresh_motorsport_leaderboard() -> void:
	if motorsport_manager == null or motorsport_leaderboard_event_select == null:
		return
	if motorsport_leaderboard_event_select.item_count == 0:
		return
	var selected_index := motorsport_leaderboard_event_select.selected
	if selected_index < 0:
		selected_index = 0
	var event_id := str(motorsport_leaderboard_event_select.get_item_metadata(selected_index))
	var best: Dictionary = motorsport_manager.get_personal_best(event_id)
	var attempts: Array = motorsport_manager.get_event_leaderboard(event_id, 10)

	if best.is_empty():
		motorsport_leaderboard_best_label.text = "أفضل زمن شخصي: لا توجد نتيجة بعد — أكمل السباق لتسجيل أول زمن."
	else:
		motorsport_leaderboard_best_label.text = "أفضل زمن شخصي: %s | عدد المحاولات: %d" % [
			_format_motorsport_time(float(best.get("elapsed_seconds", 0.0))),
			int(attempts.size())
		]

	for child in motorsport_leaderboard_rows.get_children():
		motorsport_leaderboard_rows.remove_child(child)
		child.queue_free()

	if attempts.is_empty():
		var empty_label := Label.new()
		empty_label.text = "لا توجد محاولات مسجلة لهذه البطولة حتى الآن."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		motorsport_leaderboard_rows.add_child(empty_label)
		return

	for index in range(attempts.size()):
		var attempt: Dictionary = attempts[index]
		var row := Label.new()
		row.text = "%02d  |  %s  |  %s" % [
			index + 1,
			_format_motorsport_time(float(attempt.get("elapsed_seconds", 0.0))),
			str(attempt.get("vehicle_id", "مركبة"))
		]
		row.add_theme_font_size_override("font_size", 17)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		motorsport_leaderboard_rows.add_child(row)


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
	if location_id.begins_with("tower_service_"):
		var service_title := str(target.get_meta("system_interaction_prompt", "خدمات البرج"))
		var service_description := str(target.get_meta("system_service_description", "الخدمة قيد التطوير."))
		if location_id.begins_with("tower_service_hunter_association_tower_baghdad_"):
			var hunter_menu := get_node_or_null("HunterGuildMenu")
			if hunter_menu != null and hunter_menu.has_method("open_service_view"):
				hunter_menu.call("open_service_view", location_id)
				if location_id.ends_with("_0"):
					service_description = "تم فتح مكتب تسجيل اختبار الصيادين."
				elif location_id.ends_with("_1"):
					service_description = "تم فتح لوحة مهام النقابة."
				elif location_id.ends_with("_2"):
					service_description = "تم فتح مكتب معلومات النقابة."
		elif location_id.begins_with("tower_service_business_tower_baghdad_"):
			if is_instance_valid(business_services_menu) and business_services_menu.has_method("open_service_view"):
				business_services_menu.call("open_service_view", location_id)
				if location_id.ends_with("_0"):
					service_description = "تم فتح مركز استشارات الأعمال."
				elif location_id.ends_with("_1"):
					service_description = "تم فتح مكتب الاستثمار؛ السوق الاستثماري ما زال مغلقاً حتى اكتمال ضوابطه."
				elif location_id.ends_with("_2"):
					service_description = "تم فتح مكتب تسجيل الشركات."
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "%s\\n%s" % [service_title, service_description]
	elif location_id.begins_with("street_ad_"):
		var advertising_manager: Node = target.get_parent().get_parent() if target.get_parent() != null else null
		if advertising_manager != null and advertising_manager.has_method("get_campaign_details"):
			var campaign: Dictionary = advertising_manager.call("get_campaign_details", location_id)
			if interaction_prompt_label != null and not campaign.is_empty():
				var remaining := maxi(0, int(campaign.get("expires_at", 0)) - int(Time.get_unix_time_from_system()))
				interaction_prompt_label.text = "%s\n%s\n%s\nالإجراء المقترح: %s\n%s" % [
					str(campaign.get("category", "إعلان")),
					str(campaign.get("title", "حملة SYSTEM")),
					str(campaign.get("body", "")),
					str(campaign.get("action", "استكشف المدينة")),
					"انتهت مدة الإعلان" if remaining <= 0 else "مدة العرض المتبقية: %d ثانية" % remaining
				]
	if location_id == "hunter_exam_public_notice_baghdad":
		var notice_hunter_menu := get_node_or_null("HunterGuildMenu")
		if notice_hunter_menu != null and notice_hunter_menu.has_method("open_service_view"):
			notice_hunter_menu.call("open_service_view", "tower_service_hunter_association_tower_baghdad_2")
		if interaction_prompt_label != null:
			interaction_prompt_label.text = "إعلان رسمي من نقابة الصيادين — التسجيل والاستعلام من مكاتب النقابة، والدخول للنفق للمسجلين والمقبولين فقط."
	if location_id == "hunter_exam_tunnel_start_baghdad":
		var tunnel_hunter_menu := get_node_or_null("HunterGuildMenu")
		if hunter_exam_manager != null:
			var exam_result: Dictionary = hunter_exam_manager.call("begin_exam")
			if tunnel_hunter_menu != null and tunnel_hunter_menu.has_method("show_exam_tunnel_result"):
				tunnel_hunter_menu.call("show_exam_tunnel_result", exam_result)
			if interaction_prompt_label != null:
				if bool(exam_result.get("success", false)):
					var stage: Dictionary = exam_result.get("stage", {})
					interaction_prompt_label.text = "بوابة اختبار الصيادين مفعّلة — %s" % str(stage.get("title", "المرحلة الحالية"))
				else:
					interaction_prompt_label.text = "يلزم التسجيل في مكتب النقابة قبل دخول الاختبار."
		elif interaction_prompt_label != null:
			interaction_prompt_label.text = "نظام اختبارات الصيادين غير متاح حالياً."
	if location_id == "service_baghdad_stadium":
		var stadium := target.get_parent()
		if stadium != null and player != null:
			player.global_position = stadium.global_position + Vector3(0.0, 2.0, 0.0)
			player.velocity = Vector3.ZERO
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "دخلت ملعب كرة القدم — الملعب مفتوح للاستكشاف؛ نظام المباريات والفرق قيد التطوير."
	elif location_id == "baghdad_motorsport_leaderboard":
		_show_motorsport_leaderboard()
	elif location_id == "baghdad_motorsport_race_control":
		if motorsport_track_manager != null and motorsport_track_manager.has_method("start_track_event"):
			var race_result: Dictionary = motorsport_track_manager.call("start_track_event", "city_sprint")
			if interaction_prompt_label != null:
				if bool(race_result.get("success", false)):
					var event_data: Dictionary = race_result.get("event", {})
					interaction_prompt_label.text = "تم تسجيل %s! ارجع إلى سيارتك، اركبها، ثم اعبر نقاط التفتيش بالترتيب لإكمال اللفات." % str(event_data.get("event_name", "السباق"))
				else:
					var reason := str(race_result.get("reason", "تعذر بدء السباق"))
					var reason_text := reason
					match reason:
						"PLAYER_NOT_INSIDE_APPROVED_TRACK":
							reason_text = "يجب دخول منطقة الحلبة أولاً."
						"EXIT_VEHICLE_TO_REGISTER_RACE":
							reason_text = "انزل من السيارة وسجّل السباق من مكتب الإدارة."
						"VEHICLE_NOT_ON_START_GRID":
							reason_text = "ضع سيارتك على خط الانطلاق أولاً."
						"ACTIVE_VEHICLE_UNAVAILABLE":
							reason_text = "أحضر سيارة مملوكة لك إلى خط الانطلاق."
					interaction_prompt_label.text = "إدارة السباق: " + reason_text
	elif location_id.begins_with("baghdad_osm_entrance_"):
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
	if location_id == "power_tower_baghdad" and power_tower_manager != null:
		var next_floor := int(power_tower_manager.get_tower_status().get("next_floor", 1))
		var level := int(player_progression.current_level) if player_progression != null else 1
		var result: Dictionary = power_tower_manager.request_floor(next_floor, level)
		if bool(result.get("success", false)):
			var power_tower_root := target.get_parent()
			var arena_venue := power_tower_root.get_node_or_null("PowerTowerArenaVenue") if power_tower_root != null else null
			if arena_venue != null and player != null:
				player.global_position = arena_venue.call("get_arena_entry_position")
				player.velocity = Vector3.ZERO
				if interaction_prompt_label != null:
					interaction_prompt_label.text = "برج القوة — بدأت محاولة الطابق %d. الحلبة جاهزة، ونظام الخصوم والقتال الفعلي قيد الإكمال." % next_floor
			elif interaction_prompt_label != null:
				interaction_prompt_label.text = "تم حجز الطابق %d، لكن الحلبة غير متاحة حالياً." % next_floor
		elif interaction_prompt_label != null:
			interaction_prompt_label.text = "برج القوة: " + str(result.get("reason", "تعذر بدء التحدي"))
	elif location_id == "hunter_association_tower_baghdad":
		var hunter_tower_root := target.get_parent()
		var hunter_tower_lobby := hunter_tower_root.get_node_or_null("TowerInterior") if hunter_tower_root != null else null
		if hunter_tower_lobby != null and player != null:
			player.global_position = hunter_tower_lobby.call("get_entry_position")
			player.velocity = Vector3.ZERO
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "دخلت برج نقابة الصيادين — استخدم مكاتب الاستقبال ولوحة المعلومات"
		elif interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر تحميل بهو برج نقابة الصيادين"
	elif location_id in ["business_tower_baghdad", "shopping_tower_baghdad", "entertainment_tower_baghdad", "technology_tower_baghdad"]:
		var tower_root := target.get_parent()
		var tower_lobby := tower_root.get_node_or_null("TowerInterior") if tower_root != null else null
		if tower_lobby != null and player != null:
			player.global_position = tower_lobby.call("get_entry_position")
			player.velocity = Vector3.ZERO
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "دخلت بهو البرج — اقترب من بوابة الخروج للتفاعل"
		elif interaction_prompt_label != null:
			interaction_prompt_label.text = "تعذر تحميل بهو البرج حالياً"
	elif location_id == "hunter_association_headquarters_baghdad":
		var headquarters := target.get_parent()
		var interior := headquarters.get_node_or_null("HeadquartersInterior") if headquarters != null else null
		if interior != null and player != null:
			player.global_position = interior.call("get_entry_position")
			player.velocity = Vector3.ZERO
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "دخلت المقر الرئيسي لنقابة الصيادين — اقترب من بوابة الخروج للتفاعل"
		elif interaction_prompt_label != null:
			interaction_prompt_label.text = "المقر الرئيسي لنقابة الصيادين — تعذر تحميل المساحة الداخلية"
	elif location_id == "hunter_association_headquarters_exit_baghdad":
		var interior := target.get_parent()
		if interior != null and player != null and interior.has_method("get_return_position"):
			player.global_position = interior.call("get_return_position")
			player.velocity = Vector3.ZERO
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "خرجت من المقر الرئيسي لنقابة الصيادين"
	elif location_id.begins_with("tower_exit_"):
		var tower_lobby := target.get_parent()
		if tower_lobby != null and player != null and tower_lobby.has_method("get_return_position"):
			player.global_position = tower_lobby.call("get_return_position")
			player.velocity = Vector3.ZERO
			if interaction_prompt_label != null:
				interaction_prompt_label.text = "خرجت إلى ساحة البرج"
	elif location_id.begins_with("tower_service_"):
		var service_title := str(target.get_meta("system_display_name", "خدمة البرج"))
		var service_note := str(target.get_meta("system_service_description", "معلومات الخدمة غير متاحة."))
		if interaction_prompt_label != null:
			interaction_prompt_label.text = service_title + "\n" + service_note


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
	if not is_instance_valid(player) or not is_instance_valid(spring_arm):
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
	var movement_speed := PLAYER_SPEED
	if bool(player.get_meta("system_wounded", false)):
		movement_speed *= 0.7
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
		if not player.is_on_floor():
			player.velocity.y -= GRAVITY * delta
		elif not is_in_hospital_treatment and (jump_requested or Input.is_key_pressed(KEY_SPACE)):
			player.velocity.y = JUMP_FORCE

	jump_requested = false
	player.move_and_slide()
	if is_instance_valid(player_mesh):
		var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.15
		set_player_character_activity("run" if moving else "idle")
