extends SceneTree

const EXPECTED_TOWER_IDS := [
	"hunter_association_tower_baghdad",
	"weapons_equipment_elixirs_tower_baghdad",
	"shopping_tower_baghdad",
	"entertainment_tower_baghdad",
	"technology_tower_baghdad",
	"power_tower_baghdad"
]

const TOWER_NODE_NAMES := {
	"hunter_association_tower_baghdad": "HunterAssociationTower",
	"weapons_equipment_elixirs_tower_baghdad": "WeaponsEquipmentElixirsTower",
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

	var weapons_tower := tower_manager.get_node_or_null("WeaponsEquipmentElixirsTower")
	var weapon_categories: PackedStringArray = weapons_tower.get_meta("facility_categories", PackedStringArray())
	var elixir_categories: PackedStringArray = weapons_tower.get_meta("elixir_categories", PackedStringArray())
	if not weapon_categories.has("swords") or not weapon_categories.has("armor"):
		_fail("Weapons tower is missing required weapon/armour categories.")
		return
	if not elixir_categories.has("nen_acquisition") or not elixir_categories.has("healing") or not elixir_categories.has("rare_and_legendary_elixirs"):
		_fail("Weapons tower is missing required Nen/healing/rare elixir categories.")
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

	print("Baghdad tower validation passed: five connected towers, standalone 200-floor Power Tower, six lobby kiosks, floor zoning, weapons/elixir categories, and Technology public display.")
	main_scene.queue_free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad tower validation failed: " + message)
	quit(1)
