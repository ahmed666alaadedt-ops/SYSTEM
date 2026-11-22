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
	var power_manager: Node = main.get("power_tower_manager") as Node
	if power_manager == null:
		_fail("Power Tower progression manager is missing.")
		return
	var boss_data: Dictionary = power_manager.call("get_floor_data", 200)
	if not bool(boss_data.get("boss_floor", false)) or str(boss_data.get("arena_type", "")) != "BOSS_TRIAL":
		_fail("Power Tower floor 200 is not configured as a boss trial.")
		return
	if not bool(boss_data.get("final_boss", false)) or str(boss_data.get("challenge_type", "")) != "FINAL_BOSS":
		_fail("Power Tower floor 200 is missing its unique final sovereign boss profile.")
		return
	if int(boss_data.get("required_level", 999)) > 100:
		_fail("Power Tower floor 200 is unreachable under the 100-level player progression cap.")
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
	var progression: Node = main.get("player_progression") as Node
	var shop_employee: Node = null
	var shopping_tower := tower_manager.get_node_or_null("ShoppingTower") as Node3D
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
	print("Baghdad tower operations validation passed: six tower interiors, 24 NPC employees, internal/external NPC-managed ads, buy/sell inventory transactions, and generated 200th-floor boss arena.")
	main.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("Baghdad tower operations validation failed: " + message)
	quit(1)
