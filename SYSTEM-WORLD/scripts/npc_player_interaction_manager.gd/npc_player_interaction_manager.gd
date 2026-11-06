
extends Node
class_name SystemNPCPlayerInteractionManager

## يربط اللاعب بحياة شخصيات NPC.
## يدعم العلاقات والألعاب والتجارة والعمل والأنشطة المشتركة.
## يحفظ سجل اللاعب المحلي، ويسجل الذكريات لدى NPC.
## لا يسمح بعبور العلاقات والتجارة بين العوالم.

signal interaction_completed(npc_id: String, action: String)
signal relationship_changed(npc_id: String, relationship: String)
signal trade_completed(npc_id: String, item: String, amount: int)
signal game_completed(npc_id: String, game_name: String, result: String)

const SAVE_PATH := "user://system_player_npc_interactions.json"
const GREED_ISLAND_WORLD_ID := 3

const ALLOWED_ACTIONS := [
	"talk",
	"visit",
	"eat_together",
	"cook_together",
	"socialize",
	"play_game",
	"play_sport",
	"work_together",
	"travel_together",
	"gift",
	"relationship_event"
]

var society: Node
var world_manager: Node

var player_cash: float = 100.0
var player_inventory: Dictionary = {}
var player_relationships: Dictionary = {}
var player_history: Array[Dictionary] = []


func _ready() -> void:
	load_player_data()


func setup(
	p_society: Node,
	p_world_manager: Node
) -> bool:
	if p_society == null or p_world_manager == null:
		push_warning("NPC Player Interaction: Missing managers.")
		return false

	society = p_society
	world_manager = p_world_manager

	print("SYSTEM: Player-NPC interaction system connected.")
	return true


func get_current_world_id() -> int:
	if world_manager == null:
		return -1

	return int(world_manager.get("active_world"))


func _is_valid_npc(npc_id: String) -> bool:
	if society == null or not is_instance_valid(society):
		return false

	if get_current_world_id() < 0:
		return false

	if get_current_world_id() == GREED_ISLAND_WORLD_ID:
		return false

	var npc: Dictionary = society.get_npc(npc_id)

	if npc.is_empty():
		return false

	if not npc.get("alive", false):
		return false

	return int(npc.get("world_id", -1)) == get_current_world_id()


func get_relationship(npc_id: String) -> Dictionary:
	return player_relationships.get(
		npc_id,
		{
			"affinity": 0.0,
			"friendship": 0.0,
			"romance_status": "none",
			"pending_romance": false,
			"shared_events": 0
		}
	).duplicate(true)


func perform_action(
	npc_id: String,
	action: String,
	details: Dictionary = {}
) -> bool:
	if not _is_valid_npc(npc_id):
		return false

	if not ALLOWED_ACTIONS.has(action):
		return false

	var npc: Dictionary = society.get_npc(npc_id)

	_record_shared_event(
		npc_id,
		action,
		details
	)

	interaction_completed.emit(npc_id, action)

	return true


func talk_to_npc(
	npc_id: String,
	conversation_summary: String
) -> bool:
	if conversation_summary.strip_edges().is_empty():
		return false

	return perform_action(
		npc_id,
		"talk",
		{"conversation": conversation_summary}
	)


func visit_npc(npc_id: String, location: String) -> bool:
	if location.strip_edges().is_empty():
		return false

	return perform_action(
		npc_id,
		"visit",
		{"location": location}
	)


func eat_together(
	npc_id: String,
	food_name: String
) -> bool:
	if food_name.strip_edges().is_empty():
		return false

	return perform_action(
		npc_id,
		"eat_together",
		{"food": food_name}
	)


func cook_together(
	npc_id: String,
	meal_name: String
) -> bool:
	if meal_name.strip_edges().is_empty():
		return false

	return perform_action(
		npc_id,
		"cook_together",
		{"meal": meal_name}
	)


func play_game(
	npc_id: String,
	game_name: String,
	player_score: int,
	npc_score: int
) -> Dictionary:
	if not _is_valid_npc(npc_id):
		return {"success": false, "reason": "INVALID_NPC"}

	if game_name.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_GAME"}

	var result := "draw"

	if player_score > npc_score:
		result = "player_won"
	elif npc_score > player_score:
		result = "npc_won"

	var details := {
		"game": game_name,
		"player_score": player_score,
		"npc_score": npc_score,
		"result": result
	}

	_record_shared_event(npc_id, "play_game", details)

	game_completed.emit(npc_id, game_name, result)

	return {
		"success": true,
		"result": result,
		"player_score": player_score,
		"npc_score": npc_score
	}


func play_sport(
	npc_id: String,
	sport_name: String,
	team_name: String = ""
) -> bool:
	return perform_action(
		npc_id,
		"play_sport",
		{
			"sport": sport_name,
			"team": team_name
		}
	)


func work_together(
	npc_id: String,
	job_name: String,
	hours: float,
	player_reward: float
) -> Dictionary:
	if not _is_valid_npc(npc_id):
		return {"success": false, "reason": "INVALID_NPC"}

	if hours <= 0.0 or player_reward < 0.0:
		return {"success": false, "reason": "INVALID_VALUES"}

	var npc_data: Dictionary = society.get_npc(npc_id)
	var occupation := str(npc_data.get("occupation", ""))

	if occupation.is_empty():
		return {"success": false, "reason": "NO_OCCUPATION"}

	player_cash += player_reward

	var details := {
		"job": job_name,
		"occupation": occupation,
		"hours": hours,
		"player_reward": player_reward
	}

	_record_shared_event(
		npc_id,
		"work_together",
		details
	)

	return {
		"success": true,
		"reward": player_reward,
		"cash": player_cash
	}


func travel_together(
	npc_id: String,
	destination: String
) -> bool:
	if destination.strip_edges().is_empty():
		return false

	return perform_action(
		npc_id,
		"travel_together",
		{"destination": destination}
	)


func trade_with_npc(
	npc_id: String,
	item_name: String,
	quantity: int,
	unit_price: float,
	player_buys: bool
) -> Dictionary:
	if not _is_valid_npc(npc_id):
		return {"success": false, "reason": "INVALID_NPC"}

	if item_name.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_ITEM"}

	if quantity <= 0 or unit_price <= 0.0:
		return {"success": false, "reason": "INVALID_VALUES"}

	var population: Dictionary = society.get("npcs")
	var npc: Dictionary = population.get(npc_id, {})

	if npc.is_empty():
		return {"success": false, "reason": "NPC_NOT_FOUND"}

	var npc_inventory: Dictionary = npc.get("inventory", {})
	var npc_wallet := float(npc.get("wallet", 100.0))

	var total_price := float(quantity) * unit_price

	if player_buys:
		var stock := int(npc_inventory.get(item_name, 0))

		if stock < quantity:
			return {"success": false, "reason": "NOT_ENOUGH_STOCK"}

		if player_cash < total_price:
			return {"success": false, "reason": "NOT_ENOUGH_MONEY"}

		npc_inventory[item_name] = stock - quantity
		player_inventory[item_name] = (
			int(player_inventory.get(item_name, 0)) + quantity
		)

		player_cash -= total_price
		npc_wallet += total_price

	else:
		var player_stock := int(
			player_inventory.get(item_name, 0)
		)

		if player_stock < quantity:
			return {"success": false, "reason": "NOT_ENOUGH_ITEMS"}

		if npc_wallet < total_price:
			return {"success": false, "reason": "NPC_NOT_ENOUGH_MONEY"}

		player_inventory[item_name] = player_stock - quantity
		npc_inventory[item_name] = (
			int(npc_inventory.get(item_name, 0)) + quantity
		)

		player_cash += total_price
		npc_wallet -= total_price

	npc["inventory"] = npc_inventory
	npc["wallet"] = npc_wallet
	population[npc_id] = npc
	society.set("npcs", population)

	var details := {
		"item": item_name,
		"quantity": quantity,
		"unit_price": unit_price,
		"total_price": total_price,
		"player_bought": player_buys
	}

	_record_shared_event(npc_id, "trade", details)

	trade_completed.emit(npc_id, item_name, quantity)

	save_player_data()

	return {
		"success": true,
		"total_price": total_price,
		"player_cash": player_cash,
		"inventory": player_inventory.duplicate(true)
	}


func give_gift(
	npc_id: String,
	item_name: String
) -> bool:
	var quantity := int(player_inventory.get(item_name, 0))

	if quantity <= 0:
		return false

	player_inventory[item_name] = quantity - 1

	_record_shared_event(
		npc_id,
		"gift",
		{"item": item_name}
	)

	save_player_data()
	return true


func request_romance(npc_id: String) -> bool:
	if not _is_valid_npc(npc_id):
		return false

	var npc: Dictionary = society.get_npc(npc_id)

	if float(npc.get("age_years", 0.0)) < 18.0:
		return false

	var relationship := get_relationship(npc_id)

	relationship["pending_romance"] = true

	player_relationships[npc_id] = relationship

	_record_shared_event(
		npc_id,
		"romance_request",
		{"status": "awaiting_npc_decision"}
	)

	save_player_data()
	return true


func resolve_romance_request(
	npc_id: String,
	accepted: bool
) -> bool:
	if not _is_valid_npc(npc_id):
		return false

	var relationship := get_relationship(npc_id)

	if not relationship.get("pending_romance", false):
		return false

	relationship["pending_romance"] = false

	if accepted:
		relationship["romance_status"] = "dating"
	else:
		relationship["romance_status"] = "rejected"

	player_relationships[npc_id] = relationship

	_record_shared_event(
		npc_id,
		"romance_decision",
		{"accepted": accepted}
	)

	relationship_changed.emit(
		npc_id,
		str(relationship["romance_status"])
	)

	save_player_data()
	return true


func end_relationship(npc_id: String) -> bool:
	if not _is_valid_npc(npc_id):
		return false

	var relationship := get_relationship(npc_id)

	relationship["romance_status"] = "none"
	relationship["pending_romance"] = false

	player_relationships[npc_id] = relationship

	_record_shared_event(
		npc_id,
		"relationship_ended",
		{}
	)

	relationship_changed.emit(npc_id, "none")

	save_player_data()
	return true


func _record_shared_event(
	npc_id: String,
	action: String,
	details: Dictionary
) -> void:
	if not _is_valid_npc(npc_id):
		return

	var relationship := get_relationship(npc_id)

	relationship["affinity"] = clampf(
		float(relationship.get("affinity", 0.0)) + 1.0,
		-100.0,
		100.0
	)

	relationship["shared_events"] = (
		int(relationship.get("shared_events", 0)) + 1
	)

	if action in ["talk", "visit", "socialize", "eat_together"]:
		relationship["friendship"] = clampf(
			float(relationship.get("friendship", 0.0)) + 2.0,
			0.0,
			100.0
		)

	player_relationships[npc_id] = relationship

	society.add_memory(
		npc_id,
		"player_shared_" + action,
		{
			"player_action": action,
			"details": details.duplicate(true),
			"world_id": get_current_world_id()
		}
	)

	_add_player_history(npc_id, action, details)

	save_player_data()


func _add_player_history(
	npc_id: String,
	action: String,
	details: Dictionary
) -> void:
	player_history.append({
		"npc_id": npc_id,
		"action": action,
		"details": details.duplicate(true),
		"world_id": get_current_world_id(),
		"time": Time.get_unix_time_from_system()
	})

	while player_history.size() > 500:
		player_history.pop_front()


func get_player_history(
	npc_id: String = "",
	limit: int = 50
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for index in range(player_history.size() - 1, -1, -1):
		var entry: Dictionary = player_history[index]

		if not npc_id.is_empty():
			if str(entry.get("npc_id", "")) != npc_id:
				continue

		result.append(entry.duplicate(true))

		if result.size() >= maxi(1, limit):
			break

	return result


func save_player_data() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("NPC Player data save failed.")
		return false

	file.store_string(JSON.stringify({
		"version": 1,
		"player_cash": player_cash,
		"player_inventory": player_inventory,
		"player_relationships": player_relationships,
		"player_history": player_history
	}, "\t"))

	file.close()
	return true


func load_player_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not parsed is Dictionary:
		return false

	var data: Dictionary = parsed

	player_cash = float(data.get("player_cash", 100.0))
	player_inventory = data.get("player_inventory", {})
	player_relationships = data.get("player_relationships", {})

	player_history.clear()

	for item in data.get("player_history", []):
		if item is Dictionary:
			player_history.append(item)

	return true
