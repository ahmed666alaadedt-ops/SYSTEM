extends SceneTree

const TOWER_IDS := [
	"hunter_association_tower_baghdad",
	"weapons_equipment_elixirs_tower_baghdad",
	"shopping_tower_baghdad",
	"entertainment_tower_baghdad",
	"technology_tower_baghdad",
	"power_tower_baghdad"
]

const NODE_NAMES := {
	"hunter_association_tower_baghdad": "HunterAssociationTower",
	"weapons_equipment_elixirs_tower_baghdad": "WeaponsEquipmentElixirsTower",
	"shopping_tower_baghdad": "ShoppingTower",
	"entertainment_tower_baghdad": "EntertainmentTower",
	"technology_tower_baghdad": "TechnologyTower",
	"power_tower_baghdad": "PowerTower"
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not load.")
		return
	var main := packed.instantiate() as Node3D
	if main == null:
		_fail("Main scene root is not Node3D.")
		return
	root.add_child(main)
	for _frame in range(18):
		await process_frame
	var operations := main.get_node_or_null("BaghdadTowerOperationsManager")
	if operations == null:
		_fail("BaghdadTowerOperationsManager was not initialized.")
		return
	var status: Dictionary = operations.call("get_operations_status")
	if int(status.get("tower_count", 0)) != 6:
		_fail("Operations manager did not resolve all six towers.")
		return
	if int(status.get("staff_count", 0)) != 24:
		_fail("Expected four persistent NPC staff members per tower; found %d." % int(status.get("staff_count", 0)))
		return
	if str(status.get("advertising_mode", "")) != "npc_staff_managed_internal_external":
		_fail("NPC-managed internal/external advertising is not active.")
		return
	var region := main.find_child("ModernWorldRegionManager", true, false)
	if region == null:
		_fail("ModernWorldRegionManager is missing.")
		return
	var tower_manager := region.get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager == null:
		_fail("BaghdadTowerLandmarksManager is missing.")
		return
	for tower_id in TOWER_IDS:
		var tower := tower_manager.get_node_or_null(str(NODE_NAMES[tower_id])) as Node3D
		if tower == null:
			_fail("Missing tower node: " + tower_id)
			return
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
		if lobby == null:
			_fail("Missing lobby for " + tower_id)
			return
		var lobby_lift := lobby.get_node_or_null("LobbyElevatorInteraction") as Area3D
		if lobby_lift == null or not lobby_lift.is_in_group("system_interactable") or str(lobby_lift.get_meta("system_tower_id", "")) != tower_id:
			_fail("Lobby elevator selector is not interactable for " + tower_id)
			return
		var staff_count := 0
		for child in lobby.get_children():
			if child.has_meta("system_tower_staff_id"):
				staff_count += 1
		if staff_count != 4:
			_fail("Expected four visible NPC employees in " + tower_id + "; found %d." % staff_count)
			return
		var internal_ad := lobby.get_node_or_null("NPCManagedInternalCampaign") as Label3D
		if internal_ad == null or not internal_ad.text.contains("بإدارة"):
			_fail("Internal NPC-managed advertising is missing for " + tower_id)
			return
		var external_ad := tower.get_node_or_null("TowerCampaignText") as Label3D
		if external_ad == null or not external_ad.text.contains("بإدارة"):
			_fail("External NPC-managed advertising is missing for " + tower_id)
			return
		var room := operations.call("_ensure_floor_room", tower_id, 1) as Node3D
		if room == null:
			_fail("Could not generate playable interior floor 1 for " + tower_id)
			return
		if room.get_node_or_null("FloorCollision") == null:
			_fail("Interior floor collision is missing for " + tower_id)
			return
		if tower_id != "power_tower_baghdad":
			var service_area := room.find_child("TowerServiceInteraction", true, false) as Area3D
			if service_area == null or not service_area.is_in_group("system_interactable") or str(service_area.get_meta("system_tower_id", "")) != tower_id:
				_fail("Interactive NPC service kiosk is missing for " + tower_id)
				return
	var power_manager: Node = main.get("power_tower_manager") as Node
	if power_manager == null:
		_fail("Power Tower progression manager is missing.")
		return
	for floor_number in range(1, 201):
		var floor_data: Dictionary = power_manager.call("get_floor_data", floor_number)
		if int(floor_data.get("floor", 0)) != floor_number or int(floor_data.get("required_level", 999)) > 100:
			_fail("Power Tower floor data or level gate is invalid at floor %d." % floor_number)
			return
		if bool(floor_data.get("boss_floor", false)) != (floor_number % 10 == 0):
			_fail("Power Tower boss cadence is incorrect at floor %d." % floor_number)
			return
		if int(floor_data.get("opponent_count", 0)) < 1 or int(floor_data.get("wave_count", 0)) < 1 or int(floor_data.get("reward_xp", 0)) <= 0:
			_fail("Power Tower challenge data is incomplete at floor %d." % floor_number)
			return
	var boss_data: Dictionary = power_manager.call("get_floor_data", 200)
	if not bool(boss_data.get("boss_floor", false)) or str(boss_data.get("arena_type", "")) != "BOSS_TRIAL":
		_fail("Power Tower floor 200 is not configured as a boss trial.")
		return
	if not bool(boss_data.get("final_boss", false)) or str(boss_data.get("challenge_type", "")) != "FINAL_BOSS":
		_fail("Power Tower floor 200 is missing its unique final sovereign boss profile.")
		return
	var final_rewards: Array = boss_data.get("reward_items", [])
	if not final_rewards.has("power_tower_sovereign_crown") or not final_rewards.has("sovereign_core"):
		_fail("Power Tower floor 200 is missing its unique completion rewards.")
		return
	if int(boss_data.get("required_level", 999)) > 100:
		_fail("Power Tower floor 200 is unreachable under the 100-level player progression cap.")
		return
	var weapons_room := operations.call("_ensure_floor_room", "weapons_equipment_elixirs_tower_baghdad", 1) as Node3D
	if weapons_room.get_node_or_null("WeaponsForge") == null or weapons_room.get_node_or_null("ElixirLaboratory") == null:
		_fail("Weapons Tower forge and elixir laboratory stations are missing.")
		return
	var forge_area := weapons_room.get_node("WeaponsForge/CraftingStationInteraction") as Area3D
	if forge_area == null or not forge_area.is_in_group("system_interactable") or not forge_area.has_meta("system_tower_staff_id"):
		_fail("Weapons Tower crafting station is not connected to its NPC employee.")
		return
	var boss_room := operations.call("_ensure_floor_room", "power_tower_baghdad", 200) as Node3D
	if boss_room == null or boss_room.get_node_or_null("BossTrialPlatform") == null:
		_fail("Power Tower floor 200 boss arena was not generated.")
		return
	if boss_room.get_node_or_null("ArenaChallengeDisplay") == null:
		_fail("Power Tower arena challenge display is missing.")
		return
	if not operations.has_method("_buy_product") or not operations.has_method("_sell_item"):
		_fail("NPC-supervised buy/sell transaction methods are missing.")
		return
	var shopping_tower := tower_manager.get_node_or_null("ShoppingTower") as Node3D
	operations.call("open_tower", "shopping_tower_baghdad")
	operations.call("_travel_to_floor", "shopping_tower_baghdad", 1)
	await create_timer(2.8).timeout
	if shopping_tower.get_node_or_null("ActiveTowerElevatorCar") == null:
		_fail("Visible elevator cabin was not created for tower travel.")
		return
	var player: CharacterBody3D = main.get("player") as CharacterBody3D
	if bool(player.get_meta("system_tower_elevator_active", true)):
		_fail("Elevator transition did not complete.")
		return
	operations.call("return_to_lobby")
	await create_timer(3.0).timeout
	if shopping_tower.get_node_or_null("ActiveTowerElevatorCar") != null:
		_fail("Elevator cabin was not cleaned up after returning to the lobby.")
		return
	var progression: Node = main.get("player_progression") as Node
	var shop_employee: Node = null
	var shopping_lobby := shopping_tower.get_node_or_null("PublicLobby_Blockout")
	for child in shopping_lobby.get_children():
		if child.has_meta("system_tower_staff_id"):
			shop_employee = child
			break
	if shop_employee == null:
		_fail("No NPC shop employee can be interacted with.")
		return
	operations.call("open_staff_service", shop_employee)
	operations.call("_buy_product", "water_bottle", "قارورة ماء", 12)
	if int(progression.call("get_item_count", "water_bottle")) < 1:
		_fail("NPC shop purchase did not add the item to player inventory.")
		return
	operations.call("_sell_item", "water_bottle", 1)
	if int(progression.call("get_item_count", "water_bottle")) != 0:
		_fail("NPC shop sale did not remove the sold inventory item.")
		return
	progression.call("add_item", "iron_ingot", 1)
	progression.call("add_item", "wood_plank", 2)
	var craft_result: Dictionary = progression.call("craft_recipe", "training_sword")
	if not bool(craft_result.get("success", false)) or int(progression.call("get_item_count", "training_sword")) < 1 or int(progression.call("get_item_count", "iron_ingot")) != 0 or int(progression.call("get_item_count", "wood_plank")) != 0:
		_fail("NPC-supervised crafting did not consume ingredients and create the requested weapon.")
		return
	progression.call("add_item", "training_sword", 1)
	var equip_result: Dictionary = progression.call("equip_item", "training_sword")
	if not bool(equip_result.get("success", false)) or str(progression.call("get_equipped_item", "weapon")) != "training_sword":
		_fail("Weapon equipment slot did not accept an owned training sword.")
		return
	if float(progression.call("get_combat_damage_bonus")) < 5.0:
		_fail("Equipped weapon did not apply its combat damage bonus.")
		return
	operations.call("_sell_item", "training_sword", 1)
	if int(progression.call("get_item_count", "training_sword")) != 1:
		_fail("NPC vendor allowed sale of a currently equipped weapon.")
		return
	operations.call("_unequip_item", "weapon")
	if not str(progression.call("get_equipped_item", "weapon")).is_empty():
		_fail("NPC service did not remove the weapon from its equipment slot.")
		return
	progression.call("add_item", "strength_elixir", 1)
	var strength_result: Dictionary = progression.call("consume_elixir", "strength_elixir")
	if not bool(strength_result.get("success", false)) or float(progression.call("get_combat_damage_bonus")) < 20.0:
		_fail("Strength elixir did not apply its timed combat damage effect.")
		return
	progression.call("add_item", "speed_elixir", 1)
	progression.call("consume_elixir", "speed_elixir")
	if float(progression.call("get_movement_multiplier")) <= 1.0:
		_fail("Speed elixir did not increase the player movement multiplier.")
		return
	progression.call("add_item", "endurance_elixir", 1)
	progression.call("consume_elixir", "endurance_elixir")
	if float(progression.call("get_defense_bonus")) < 12.0:
		_fail("Endurance elixir did not apply a defense bonus.")
		return
	progression.call("add_item", "energy_elixir", 1)
	progression.call("consume_elixir", "energy_elixir")
	if float(progression.call("get_attack_cooldown_multiplier")) >= 1.0:
		_fail("Energy elixir did not reduce the attack cooldown multiplier.")
		return
	progression.call("add_item", "nen_acquisition_elixir", 1)
	progression.call("consume_elixir", "nen_acquisition_elixir")
	progression.call("add_item", "nen_control_elixir", 1)
	progression.call("consume_elixir", "nen_control_elixir")
	if not bool(progression.get("nen_unlocked")) or int(progression.get("nen_control_rank")) != 2:
		_fail("Nen acquisition/control elixirs did not update the player's Nen state.")
		return
	var health_manager: Node = main.get("player_combat_health") as Node
	health_manager.call("receive_damage", 150.0, null)
	progression.call("add_item", "healing_elixir", 1)
	var healing_result: Dictionary = progression.call("consume_elixir", "healing_elixir")
	if not bool(healing_result.get("success", false)) or not bool(health_manager.get("is_wounded")) or float(health_manager.get("current_health")) <= 30.0:
		_fail("Healing elixir must restore field health without clearing the persistent wound state.")
		return
	print("Baghdad tower operations validation passed: six tower interiors, 24 NPC employees, internal/external NPC-managed ads, buy/sell, equipment, timed elixir effects, Nen progression and the 200th-floor sovereign boss arena.")
	main.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("Baghdad tower operations validation failed: " + message)
	quit(1)
