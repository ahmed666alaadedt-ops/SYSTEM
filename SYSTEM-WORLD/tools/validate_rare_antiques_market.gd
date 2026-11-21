extends SceneTree

const MARKET_SCRIPT = preload("res://scripts/system_rare_antiques_market_manager.gd")
const MARKET_UI_SCRIPT = preload("res://scripts/system_rare_antiques_market_ui.gd")

class TestWallet:
	extends Node
	var balance := 50000
	func get_balance() -> int:
		return balance
	func spend_currency(amount: int, reason: String = "") -> Dictionary:
		if amount <= 0 or amount > balance:
			return {"success":false,"reason":"INSUFFICIENT_CURRENCY"}
		balance -= amount
		return {"success":true,"balance":balance}
	func credit_currency(amount: int, reason: String = "") -> Dictionary:
		if amount <= 0:
			return {"success":false,"reason":"INVALID_AMOUNT"}
		balance += amount
		return {"success":true,"balance":balance}

func _initialize() -> void:
	var manager = MARKET_SCRIPT.new()
	var wallet := TestWallet.new()
	root.add_child(wallet)
	root.add_child(manager)
	print("Rare antiques validator: manager setup")
	manager.setup(wallet)
	print("Rare antiques validator: manager ready")
	manager.auctions.clear()
	manager.market_seeded = false
	manager.call("_seed_house_auctions_if_needed")
	print("Rare antiques validator: seeded auction house")
	var catalogue: Dictionary = manager.get_catalogue()
	if catalogue.size() < 4:
		_fail("Rare artifact catalogue is incomplete.")
		return
	print("Rare antiques validator: catalogue size = %d" % catalogue.size())
	if manager.list_open_auctions().size() < 3:
		_fail("NPC auction house did not seed the public market board.")
		return
	manager.inventory["seller_test"] = ["uruk_cylinder_seal"]
	manager.inventory["local_player"] = ["bronze_star_astrolabe"]
	var created: Dictionary = manager.create_auction("uruk_cylinder_seal", "seller_test", 500)
	if not bool(created.get("success", false)):
		_fail("Could not create a valid artifact auction.")
		return
	if (manager.get_inventory().get("seller_test", []) as Array).has("uruk_cylinder_seal"):
		_fail("Listed artifact was not moved into auction escrow.")
		return
	var auction: Dictionary = created.get("auction", {})
	var auction_id := str(auction.get("id", ""))
	print("Rare antiques validator: created seller auction")
	var bid: Dictionary = manager.place_bid(auction_id, "local_player", 700)
	print("Rare antiques validator: placed first bid")
	if not bool(bid.get("success", false)) or wallet.balance != 49300:
		_fail("Bid escrow was not applied.")
		return
	var own_lot: Dictionary = manager.create_auction("bronze_star_astrolabe", "local_player", 800)
	var own_auction_id := str(own_lot.get("auction", {}).get("id", ""))
	var self_bid: Dictionary = manager.place_bid(own_auction_id, "local_player", 900)
	if str(self_bid.get("reason", "")) != "SELLER_CANNOT_BID":
		_fail("Seller self-bidding was not blocked.")
		return
	manager.auctions[own_auction_id]["ends_at"] = int(Time.get_unix_time_from_system()) - 1
	var unsold: Dictionary = manager.settle_auction(own_auction_id)
	print("Rare antiques validator: settled unsold lot")
	if not bool(unsold.get("success", false)) or not (manager.get_inventory().get("local_player", []) as Array).has("bronze_star_astrolabe"):
		_fail("Unsold artifact was not returned from escrow to its owner.")
		return
	var low_bid: Dictionary = manager.place_bid(auction_id, "local_player", 650)
	if str(low_bid.get("reason", "")) != "BID_MUST_EXCEED_CURRENT":
		_fail("Out-of-order bid was not blocked.")
		return
	var forged_identity: Dictionary = manager.place_bid(auction_id, "forged_player_id", 900)
	if str(forged_identity.get("reason", "")) != "INVALID_BID":
		_fail("Non-player bidder identity was accepted.")
		return
	manager.auctions[auction_id]["ends_at"] = int(Time.get_unix_time_from_system()) - 1
	var settled: Dictionary = manager.settle_auction(auction_id)
	print("Rare antiques validator: settled sold lot")
	if not bool(settled.get("success", false)) or not (manager.get_inventory().get("local_player", []) as Array).has("uruk_cylinder_seal"):
		_fail("Auction settlement did not transfer local ownership.")
		return
	var item: Dictionary = manager.get_item_details("uruk_cylinder_seal")
	if str(item.get("authenticity", "")) != "APPRAISED" or str(item.get("provenance", "")).is_empty():
		_fail("Artifact provenance/appraisal metadata is missing.")
		return
	print("Rare antiques validator: preparing UI")
	var ui = MARKET_UI_SCRIPT.new()
	ui.call("setup", manager, wallet)
	root.add_child(ui)
	print("Rare antiques validator: UI ready")
	ui.call("open_market")
	print("Rare antiques validator: market opened")
	if not bool(ui.panel.visible):
		_fail("In-world market interface did not open.")
		return
	print("Rare antiques validator: freeing test nodes")
	ui.free()
	manager.free()
	wallet.free()
	print("Rare antiques market validation passed: catalogue, provenance, escrow, anti-self-bid and local ownership ledger.")
	quit(0)

func _fail(message: String) -> void:
	push_error("Rare antiques market validation failed: " + message)
	quit(1)
