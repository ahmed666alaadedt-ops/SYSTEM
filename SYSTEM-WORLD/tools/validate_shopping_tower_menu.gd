extends SceneTree

class FakeWallet:
	extends Node
	var balance := 500
	func get_balance() -> int:
		return balance
	func spend_currency(amount: int, _reason: String = "") -> Dictionary:
		if amount <= 0 or balance < amount:
			return {"success": false, "reason": "INSUFFICIENT_FUNDS"}
		balance -= amount
		return {"success": true, "balance": balance}
	func credit_currency(amount: int, _reason: String = "") -> Dictionary:
		balance += amount
		return {"success": true, "balance": balance}

class FakeProgression:
	extends Node
	var inventory: Dictionary = {}
	func add_item(item_id: String, amount: int = 1) -> bool:
		if item_id.is_empty() or amount <= 0:
			return false
		inventory[item_id] = int(inventory.get(item_id, 0)) + amount
		return true
	func get_item_count(item_id: String) -> int:
		return int(inventory.get(item_id, 0))
	func get_progress_data() -> Dictionary:
		return {"inventory_items": inventory.duplicate(true)}

const MENU_SCRIPT = preload("res://scripts/system_shopping_tower_menu.gd")
const INVENTORY_SCRIPT = preload("res://scripts/system_inventory_panel.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Baghdad Shopping Tower validation failed: " + message)
	quit(1)

func _run() -> void:
	var wallet := FakeWallet.new()
	var progression := FakeProgression.new()
	root.add_child(wallet)
	root.add_child(progression)
	var menu = MENU_SCRIPT.new()
	menu.setup(wallet, progression)
	root.add_child(menu)
	await process_frame
	var catalog: Array = menu.get_catalog()
	if catalog.size() != 5:
		_fail("Shopping Tower must expose five catalogued local collectibles.")
		return
	menu.call("open_service_view", "tower_service_shopping_tower_baghdad_1")
	if not menu.panel.visible or menu.item_list.get_child_count() != 5:
		_fail("The shopping tower service desk did not open the five-item catalog.")
		return
	menu.call("_purchase_item", "baghdad_tower_emblem")
	if wallet.balance != 420 or progression.get_item_count("baghdad_tower_emblem") != 1:
		_fail("A successful purchase did not deduct credits and add one item to inventory.")
		return
	menu.call("_purchase_item", "baghdad_tower_emblem")
	if wallet.balance != 340 or progression.get_item_count("baghdad_tower_emblem") != 2:
		_fail("A repeat purchase did not update the wallet and inventory correctly.")
		return
	wallet.balance = 0
	menu.call("_purchase_item", "hunter_association_patch")
	if progression.get_item_count("hunter_association_patch") != 0:
		_fail("An unaffordable collectible was added to inventory.")
		return
	menu.call("open_service_view", "tower_service_shopping_tower_baghdad_2")
	if not menu.panel.visible or menu.item_list.get_child_count() != 1:
		_fail("The shopping tower collection desk did not show the owned collectibles.")
		return
	var inventory_panel = INVENTORY_SCRIPT.new()
	inventory_panel.setup(progression)
	root.add_child(inventory_panel)
	await process_frame
	inventory_panel.call("refresh_inventory")
	if not str(inventory_panel.item_list.text).contains("شارة أبراج بغداد"):
		_fail("Purchased Shopping Tower collectibles are not displayed with readable names in the player inventory.")
		return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not main_source.contains("SYSTEMShoppingTowerMenuScript") or not main_source.contains("tower_service_shopping_tower_baghdad_") or not main_source.contains("shopping_tower_menu.call(\"open_service_view\", location_id)"):
		_fail("Main interaction routing does not connect the Shopping Tower service desks to the shop UI.")
		return
	var tower_interior_source := FileAccess.get_file_as_string("res://scripts/system_baghdad_tower_interior.gd")
	if not tower_interior_source.contains("tower_service_") or not tower_interior_source.contains("ServiceInteraction_%d"):
		_fail("Baghdad tower interiors do not generate the three indexed service desk interactions.")
		return
	inventory_panel.free()
	menu.free()
	wallet.free()
	progression.free()
	print("Baghdad Shopping Tower validation passed: five local collectibles, wallet deductions, persistent inventory additions, repeat purchases, insufficient-funds protection and collection view.")
	quit(0)
