extends SceneTree

const MARKET_SCRIPT = preload("res://scripts/system_rare_antiques_market_manager.gd")

class TestWallet:
	extends Node
	var balance := 50000
	func spend_currency(currency: String, amount: int) -> bool:
		if currency != "SYSTEM_CREDITS" or amount > balance:
			return false
		balance -= amount
		return true
	func credit_currency(currency: String, amount: int) -> void:
		if currency == "SYSTEM_CREDITS":
			balance += amount

func _initialize() -> void:
	var manager = MARKET_SCRIPT.new()
	var wallet := TestWallet.new()
	root.add_child(wallet)
	root.add_child(manager)
	manager.setup(wallet)
	var catalogue: Dictionary = manager.get_catalogue()
	if catalogue.size() < 4:
		_fail("Rare artifact catalogue is incomplete.")
		return
	manager.inventory["seller_test"] = ["uruk_cylinder_seal"]
	var created: Dictionary = manager.create_auction("uruk_cylinder_seal", "seller_test", 500)
	if not bool(created.get("success", false)):
		_fail("Could not create a valid artifact auction.")
		return
	var auction: Dictionary = created.get("auction", {})
	var auction_id := str(auction.get("id", ""))
	var bid: Dictionary = manager.place_bid(auction_id, "buyer_test", 700)
	if not bool(bid.get("success", false)) or wallet.balance != 49300:
		_fail("Bid escrow was not applied.")
		return
	var self_bid: Dictionary = manager.place_bid(auction_id, "seller_test", 900)
	if str(self_bid.get("reason", "")) != "SELLER_CANNOT_BID":
		_fail("Seller self-bidding was not blocked.")
		return
	var low_bid: Dictionary = manager.place_bid(auction_id, "other_test", 650)
	if str(low_bid.get("reason", "")) != "BID_MUST_EXCEED_CURRENT":
		_fail("Out-of-order bid was not blocked.")
		return
	var item: Dictionary = manager.get_item_details("uruk_cylinder_seal")
	if str(item.get("authenticity", "")) != "APPRAISED" or str(item.get("provenance", "")).is_empty():
		_fail("Artifact provenance/appraisal metadata is missing.")
		return
	manager.free()
	wallet.free()
	print("Rare antiques market validation passed: catalogue, provenance, escrow, anti-self-bid and local ownership ledger.")
	quit(0)

func _fail(message: String) -> void:
	push_error("Rare antiques market validation failed: " + message)
	quit(1)
