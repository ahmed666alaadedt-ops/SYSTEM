extends Node
class_name SystemRareAntiquesMarketManager

## Local prototype for the Baghdad rare-antiquities bazaar.
## Ownership and currency are local-device only until a trusted backend exists.

signal auction_started(auction_id: String)
signal bid_accepted(auction_id: String, bidder_id: String, amount: int)
signal auction_settled(auction_id: String, winner_id: String)

const SAVE_PATH := "user://system_rare_antiquities_market.cfg"
const LOTS := {
	"uruk_cylinder_seal": {"name":"Uruk Cylinder Seal","era":"Early Dynastic Mesopotamia (fictional game item)","rarity":"RARE","opening_bid":450,"museum_value":900,"provenance":"Recovered from a fictional, documented excavation in the SYSTEM setting","authenticity":"APPRAISED"},
	"bronze_star_astrolabe": {"name":"Bronze Star Astrolabe","era":"Late Abbasid-inspired (fictional game item)","rarity":"EPIC","opening_bid":1200,"museum_value":2600,"provenance":"Recorded through three fictional private collections","authenticity":"VERIFIED"},
	"lapis_guardian_figurine": {"name":"Lapis Guardian Figurine","era":"Neo-Sumerian-inspired (fictional game item)","rarity":"LEGENDARY","opening_bid":5000,"museum_value":11000,"provenance":"Museum-deaccession story arc; chain of custody documented in-game","authenticity":"VERIFIED"},
	"royal_trade_tablet": {"name":"Royal Trade Tablet","era":"Old Babylonian-inspired (fictional game item)","rarity":"MYTHIC","opening_bid":12000,"museum_value":28000,"provenance":"Found in a sealed fictional archive vault","authenticity":"SEALED"}
}
const AUCTION_DURATION_SECONDS := 180
const MAX_BID := 1000000

var wallet: Node
var inventory: Dictionary = {}
var auctions: Dictionary = {}
var transaction_ledger: Array[Dictionary] = []
var next_transaction_id := 1

func setup(p_wallet: Node) -> void:
	wallet = p_wallet
	_load_state()

func get_catalogue() -> Dictionary:
	return LOTS.duplicate(true)

func get_item_details(item_id: String) -> Dictionary:
	return LOTS.get(item_id, {}).duplicate(true)

func get_inventory() -> Dictionary:
	return inventory.duplicate(true)

func get_auction(auction_id: String) -> Dictionary:
	var auction: Dictionary = auctions.get(auction_id, {})
	return auction.duplicate(true)

func list_open_auctions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for auction_id in auctions:
		var auction: Dictionary = auctions[auction_id]
		if str(auction.get("status", "")) == "OPEN" and int(auction.get("ends_at", 0)) > int(Time.get_unix_time_from_system()):
			result.append(auction.duplicate(true))
	return result

func create_auction(item_id: String, seller_id: String, reserve_price: int = 0) -> Dictionary:
	if not LOTS.has(item_id):
		return {"success":false,"reason":"UNKNOWN_ARTIFACT"}
	if seller_id.is_empty() or reserve_price < 0 or reserve_price > MAX_BID:
		return {"success":false,"reason":"INVALID_AUCTION_DETAILS"}
	if not inventory.has(seller_id) or not (inventory[seller_id] as Array).has(item_id):
		return {"success":false,"reason":"SELLER_DOES_NOT_OWN_ARTIFACT"}
	var auction_id := "artifact_auction_%05d" % next_transaction_id
	next_transaction_id += 1
	var item: Dictionary = LOTS[item_id]
	var auction := {
		"id":auction_id,"item_id":item_id,"item_name":str(item.get("name", item_id)),
		"seller_id":seller_id,"reserve_price":reserve_price,
		"current_bid":int(item.get("opening_bid", 1)) - 1,"highest_bidder":"",
		"ends_at":int(Time.get_unix_time_from_system()) + AUCTION_DURATION_SECONDS,
		"status":"OPEN","bid_count":0
	}
	auctions[auction_id] = auction
	_save_state()
	auction_started.emit(auction_id)
	return {"success":true,"auction":auction.duplicate(true)}

func place_bid(auction_id: String, bidder_id: String, amount: int) -> Dictionary:
	if wallet == null or not is_instance_valid(wallet):
		return {"success":false,"reason":"LOCAL_WALLET_UNAVAILABLE"}
	if bidder_id.is_empty() or amount <= 0 or amount > MAX_BID:
		return {"success":false,"reason":"INVALID_BID"}
	if not auctions.has(auction_id):
		return {"success":false,"reason":"AUCTION_NOT_FOUND"}
	var auction: Dictionary = auctions[auction_id]
	if str(auction.get("status", "")) != "OPEN" or int(auction.get("ends_at", 0)) <= int(Time.get_unix_time_from_system()):
		return {"success":false,"reason":"AUCTION_CLOSED"}
	if bidder_id == str(auction.get("seller_id", "")):
		return {"success":false,"reason":"SELLER_CANNOT_BID"}
	if amount <= int(auction.get("current_bid", 0)):
		return {"success":false,"reason":"BID_MUST_EXCEED_CURRENT"}
	var previous_bidder := str(auction.get("highest_bidder", ""))
	var previous_amount := int(auction.get("current_bid", 0))
	if not bool(wallet.call("spend_currency", "SYSTEM_CREDITS", amount)):
		return {"success":false,"reason":"INSUFFICIENT_FUNDS"}
	if not previous_bidder.is_empty() and previous_amount > 0:
		wallet.call("credit_currency", "SYSTEM_CREDITS", previous_amount)
	auction["highest_bidder"] = bidder_id
	auction["current_bid"] = amount
	auction["bid_count"] = int(auction.get("bid_count", 0)) + 1
	auctions[auction_id] = auction
	_record_transaction("BID_ESCROW", auction_id, bidder_id, amount)
	_save_state()
	bid_accepted.emit(auction_id, bidder_id, amount)
	return {"success":true,"auction":auction.duplicate(true)}

func settle_auction(auction_id: String) -> Dictionary:
	if not auctions.has(auction_id):
		return {"success":false,"reason":"AUCTION_NOT_FOUND"}
	var auction: Dictionary = auctions[auction_id]
	if str(auction.get("status", "")) != "OPEN":
		return {"success":false,"reason":"AUCTION_ALREADY_SETTLED"}
	if int(Time.get_unix_time_from_system()) < int(auction.get("ends_at", 0)):
		return {"success":false,"reason":"AUCTION_STILL_RUNNING"}
	var bidder := str(auction.get("highest_bidder", ""))
	var amount := int(auction.get("current_bid", 0))
	var seller := str(auction.get("seller_id", ""))
	if bidder.is_empty() or amount < int(auction.get("reserve_price", 0)):
		if not bidder.is_empty() and amount > 0 and wallet != null:
			wallet.call("credit_currency", "SYSTEM_CREDITS", amount)
		auction["status"] = "NO_SALE"
		auction["highest_bidder"] = ""
		auction["current_bid"] = 0
		auctions[auction_id] = auction
		_save_state()
		return {"success":true,"status":"NO_SALE"}
	if wallet == null or not is_instance_valid(wallet):
		return {"success":false,"reason":"LOCAL_WALLET_UNAVAILABLE"}
	wallet.call("credit_currency", "SYSTEM_CREDITS", amount)
	_remove_item(seller, str(auction.get("item_id", "")))
	_add_item(bidder, str(auction.get("item_id", "")))
	auction["status"] = "SOLD"
	auctions[auction_id] = auction
	_record_transaction("SALE_SETTLED", auction_id, bidder, amount)
	_save_state()
	auction_settled.emit(auction_id, bidder)
	return {"success":true,"status":"SOLD","winner_id":bidder,"amount":amount}

func _add_item(owner_id: String, item_id: String) -> void:
	var owned: Array = inventory.get(owner_id, [])
	if not owned.has(item_id):
		owned.append(item_id)
	inventory[owner_id] = owned

func _remove_item(owner_id: String, item_id: String) -> void:
	var owned: Array = inventory.get(owner_id, [])
	owned.erase(item_id)
	inventory[owner_id] = owned

func _record_transaction(kind: String, auction_id: String, actor_id: String, amount: int) -> void:
	transaction_ledger.append({"id":"artifact_tx_%05d" % next_transaction_id,"type":kind,"auction_id":auction_id,"actor_id":actor_id,"amount":amount,"time_unix":int(Time.get_unix_time_from_system())})
	next_transaction_id += 1
	while transaction_ledger.size() > 500:
		transaction_ledger.pop_front()

func get_transaction_ledger() -> Array[Dictionary]:
	return transaction_ledger.duplicate(true)

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("market", "inventory", inventory)
	config.set_value("market", "auctions", auctions)
	config.set_value("market", "ledger", transaction_ledger)
	config.set_value("market", "next_transaction_id", next_transaction_id)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM antiques market: local state save failed.")

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	inventory = config.get_value("market", "inventory", {})
	auctions = config.get_value("market", "auctions", {})
	transaction_ledger = config.get_value("market", "ledger", [])
	next_transaction_id = int(config.get_value("market", "next_transaction_id", 1))
