extends Node
class_name SYSTEMPowerTowerArenaManager

signal match_created(match_data: Dictionary)
signal betting_opened(match_id: String)
signal spectator_bet_placed(bet_data: Dictionary)
signal betting_locked(match_id: String)
signal match_resolved(result: Dictionary)
signal match_cancelled(match_id: String)
signal crowd_cheered(fighter_id: String, intensity: float)

const MIN_BET := 10
const MAX_BET_PER_TICKET := 1000
const MAX_BET_PER_SPECTATOR_PER_MATCH := 5000
const LOCAL_PLAYER_ID := "local_player"
const CURRENCY_ID := "SYSTEM_CREDITS"
const REMOTE_WAGERING_ENABLED := false
const NPC_CROWD_SIZE := 28

var wallet_manager: Node
var active_match: Dictionary = {}
var venue: Node3D
var crowd_nodes: Array[Node3D] = []
var crowd_clock := 0.0
var npc_predictions: Dictionary = {}
var spectator_bets: Array[Dictionary] = []
var local_wager_totals: Dictionary = {}
var next_match_number := 1

func _ready() -> void:
	name = "SYSTEMPowerTowerArenaManager"
	set_process(true)
	crowd_cheered.connect(_on_crowd_cheered)

func setup(p_wallet_manager: Node) -> void:
	wallet_manager = p_wallet_manager

func attach_venue(p_venue: Node3D) -> void:
	if not is_instance_valid(p_venue):
		return
	venue = p_venue
	if crowd_nodes.is_empty():
		_build_npc_crowd()

func create_match(fighter_a_id: String, fighter_b_id: String, match_type: String = "SINGLE") -> Dictionary:
	var a := fighter_a_id.strip_edges()
	var b := fighter_b_id.strip_edges()
	if not active_match.is_empty():
		return {"success": false, "reason": "MATCH_ALREADY_ACTIVE"}
	if a.is_empty() or b.is_empty() or a == b:
		return {"success": false, "reason": "INVALID_FIGHTERS"}
	if not ["SINGLE", "TEAM"].has(match_type):
		return {"success": false, "reason": "INVALID_MATCH_TYPE"}
	var match_id := "power_arena_%06d" % next_match_number
	next_match_number += 1
	active_match = {
		"match_id": match_id,
		"fighter_a_id": a,
		"fighter_b_id": b,
		"match_type": match_type,
		"status": "READY",
		"fighter_entry_fee": 0,
		"currency_id": CURRENCY_ID,
		"created_at_unix": int(Time.get_unix_time_from_system())
	}
	spectator_bets.clear()
	local_wager_totals.clear()
	npc_predictions.clear()
	match_created.emit(active_match.duplicate(true))
	return {"success": true, "match": active_match.duplicate(true), "fighter_entry_fee": 0}

func register_fighter(fighter_id: String) -> Dictionary:
	if fighter_id.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_FIGHTER_ID"}
	return {"success": true, "fighter_id": fighter_id.strip_edges(), "entry_fee": 0, "currency_charged": false}

func open_betting() -> Dictionary:
	if active_match.is_empty():
		return {"success": false, "reason": "NO_ACTIVE_MATCH"}
	if str(active_match.get("status", "")) != "READY":
		return {"success": false, "reason": "BETTING_NOT_AVAILABLE"}
	active_match["status"] = "BETTING_OPEN"
	betting_opened.emit(str(active_match["match_id"]))
	return {"success": true, "match_id": str(active_match["match_id"]), "min_bet": MIN_BET, "max_bet": MAX_BET_PER_TICKET, "currency_id": CURRENCY_ID, "real_money_allowed": false}

func place_spectator_bet(spectator_id: String, fighter_id: String, amount: int) -> Dictionary:
	if active_match.is_empty() or str(active_match.get("status", "")) != "BETTING_OPEN":
		return {"success": false, "reason": "BETTING_CLOSED"}
	var bettor := spectator_id.strip_edges()
	if bettor.is_empty():
		return {"success": false, "reason": "INVALID_SPECTATOR_ID"}
	if bettor == str(active_match.get("fighter_a_id", "")) or bettor == str(active_match.get("fighter_b_id", "")):
		return {"success": false, "reason": "FIGHTERS_CANNOT_BET_ON_THEIR_MATCH"}
	if bettor != LOCAL_PLAYER_ID:
		return {"success": false, "reason": "REMOTE_WAGERS_REQUIRE_SERVER_AUTHORITY"}
	if not [str(active_match.get("fighter_a_id", "")), str(active_match.get("fighter_b_id", ""))].has(fighter_id):
		return {"success": false, "reason": "UNKNOWN_FIGHTER"}
	if amount < MIN_BET or amount > MAX_BET_PER_TICKET:
		return {"success": false, "reason": "BET_AMOUNT_OUT_OF_RANGE", "minimum": MIN_BET, "maximum": MAX_BET_PER_TICKET}
	if local_wager_totals.has(bettor):
		return {"success": false, "reason": "ONE_BET_PER_SPECTATOR_PER_MATCH"}
	if wallet_manager == null or not is_instance_valid(wallet_manager) or not wallet_manager.has_method("spend_currency"):
		return {"success": false, "reason": "WALLET_UNAVAILABLE"}
	var payment: Dictionary = wallet_manager.call("spend_currency", amount, "power_tower_spectator_bet")
	if not bool(payment.get("success", false)):
		return {"success": false, "reason": "INSUFFICIENT_VIRTUAL_CURRENCY", "balance": int(payment.get("balance", 0)), "required": amount}
	var bet := {
		"spectator_id": bettor,
		"fighter_id": fighter_id,
		"amount": amount,
		"currency_id": CURRENCY_ID,
		"created_at_unix": int(Time.get_unix_time_from_system())
	}
	spectator_bets.append(bet)
	local_wager_totals[bettor] = amount
	spectator_bet_placed.emit(bet.duplicate(true))
	return {"success": true, "bet": bet.duplicate(true), "wallet_balance": int(payment.get("balance", 0)), "pool": get_betting_pool()}

func add_npc_prediction(npc_id: String, fighter_id: String) -> Dictionary:
	if active_match.is_empty() or not ["READY", "BETTING_OPEN"].has(str(active_match.get("status", ""))):
		return {"success": false, "reason": "MATCH_NOT_ACCEPTING_PREDICTIONS"}
	if npc_id.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_NPC_ID"}
	if not [str(active_match.get("fighter_a_id", "")), str(active_match.get("fighter_b_id", ""))].has(fighter_id):
		return {"success": false, "reason": "UNKNOWN_FIGHTER"}
	npc_predictions[npc_id] = fighter_id
	var intensity := 0.45 + float((npc_predictions.size() % 6)) * 0.1
	crowd_cheered.emit(fighter_id, clampf(intensity, 0.0, 1.0))
	return {"success": true, "npc_id": npc_id, "prediction": fighter_id, "has_monetary_value": false, "crowd_size": NPC_CROWD_SIZE}

func lock_betting_and_start_match() -> Dictionary:
	if active_match.is_empty() or str(active_match.get("status", "")) != "BETTING_OPEN":
		return {"success": false, "reason": "BETTING_NOT_OPEN"}
	active_match["status"] = "IN_PROGRESS"
	active_match["betting_locked_at_unix"] = int(Time.get_unix_time_from_system())
	betting_locked.emit(str(active_match["match_id"]))
	return {"success": true, "match": active_match.duplicate(true), "pool": get_betting_pool()}

func get_betting_pool() -> Dictionary:
	var totals := {}
	var total := 0
	for bet in spectator_bets:
		var fighter_id := str(bet.get("fighter_id", ""))
		var amount := int(bet.get("amount", 0))
		totals[fighter_id] = int(totals.get(fighter_id, 0)) + amount
		total += amount
	return {"total": total, "by_fighter": totals, "currency_id": CURRENCY_ID, "bet_count": spectator_bets.size()}

func resolve_match(winner_id: String) -> Dictionary:
	if active_match.is_empty() or str(active_match.get("status", "")) != "IN_PROGRESS":
		return {"success": false, "reason": "MATCH_NOT_IN_PROGRESS"}
	if not [str(active_match.get("fighter_a_id", "")), str(active_match.get("fighter_b_id", ""))].has(winner_id):
		return {"success": false, "reason": "WINNER_NOT_IN_MATCH"}
	var pool := get_betting_pool()
	var winning_stake := int(pool.get("by_fighter", {}).get(winner_id, 0))
	var total_pool := int(pool.get("total", 0))
	var payout := 0
	var payout_count := 0
	var refunded_no_winner := 0
	if total_pool > 0 and winning_stake <= 0:
		for bet in spectator_bets:
			var refund_amount := int(bet.get("amount", 0))
			if refund_amount > 0 and wallet_manager != null and wallet_manager.has_method("credit_currency"):
				var refund: Dictionary = wallet_manager.call("credit_currency", refund_amount, "power_tower_no_winning_bets_refund")
				if bool(refund.get("success", false)):
					refunded_no_winner += refund_amount
	if total_pool > 0 and winning_stake > 0:
		for bet in spectator_bets:
			if str(bet.get("fighter_id", "")) != winner_id:
				continue
			var share := int(floor(float(total_pool) * float(bet.get("amount", 0)) / float(winning_stake)))
			if share > 0 and wallet_manager != null and wallet_manager.has_method("credit_currency"):
				var credit: Dictionary = wallet_manager.call("credit_currency", share, "power_tower_spectator_bet_payout")
				if bool(credit.get("success", false)):
					payout += share
					payout_count += 1
	var result := {
		"success": true,
		"match_id": str(active_match.get("match_id", "")),
		"winner_id": winner_id,
		"pool_total": total_pool,
		"winning_stake": winning_stake,
		"payout_total": payout,
		"winning_bets_paid": payout_count,
		"no_winner_refunds": refunded_no_winner,
		"unclaimed_pool": maxi(0, total_pool - payout - refunded_no_winner),
		"currency_id": CURRENCY_ID,
		"real_money_allowed": false,
		"settlement_mode": "local_device_prototype",
		"crowd_predictions": npc_predictions.size()
	}
	active_match["status"] = "FINISHED"
	active_match["winner_id"] = winner_id
	match_resolved.emit(result.duplicate(true))
	_clear_match()
	return result

func cancel_match() -> Dictionary:
	if active_match.is_empty():
		return {"success": false, "reason": "NO_ACTIVE_MATCH"}
	var match_id := str(active_match.get("match_id", ""))
	var refunded := 0
	for bet in spectator_bets:
		var amount := int(bet.get("amount", 0))
		if amount > 0 and wallet_manager != null and wallet_manager.has_method("credit_currency"):
			var credit: Dictionary = wallet_manager.call("credit_currency", amount, "power_tower_spectator_bet_refund")
			if bool(credit.get("success", false)):
				refunded += amount
	match_cancelled.emit(match_id)
	_clear_match()
	return {"success": true, "match_id": match_id, "refunded": refunded, "currency_id": CURRENCY_ID}

func get_match_status() -> Dictionary:
	if active_match.is_empty():
		return {"active": false, "npc_crowd_size": crowd_nodes.size()}
	return {"active": true, "match": active_match.duplicate(true), "pool": get_betting_pool(), "npc_predictions": npc_predictions.size(), "npc_crowd_size": crowd_nodes.size(), "remote_wagering_enabled": REMOTE_WAGERING_ENABLED}

func _clear_match() -> void:
	active_match.clear()
	spectator_bets.clear()
	local_wager_totals.clear()
	npc_predictions.clear()

func _build_npc_crowd() -> void:
	if not is_instance_valid(venue):
		return
	var palette := [Color(0.12, 0.55, 0.85), Color(0.78, 0.46, 0.18), Color(0.34, 0.68, 0.42), Color(0.55, 0.42, 0.78)]
	for index in range(NPC_CROWD_SIZE):
		var side := -1.0 if index % 2 == 0 else 1.0
		var row := int(index / 6) % 5
		var column := index % 6
		var spectator := Node3D.new()
		spectator.name = "ArenaSpectatorNPC_%02d" % index
		spectator.position = Vector3((float(column) - 2.5) * 8.5, 3.0 + float(row) * 1.55, side * (ARENA_STAND_Z + float(row) * 4.0))
		spectator.set_meta("base_y", spectator.position.y)
		spectator.set_meta("cheer_intensity", 0.0)
		var body := MeshInstance3D.new()
		body.name = "SpectatorBody"
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.38
		capsule.height = 1.65
		body.mesh = capsule
		var material := StandardMaterial3D.new()
		material.albedo_color = palette[index % palette.size()]
		material.roughness = 0.8
		body.material_override = material
		body.position.y = 0.85
		spectator.add_child(body)
		var head := MeshInstance3D.new()
		head.name = "SpectatorHead"
		var sphere := SphereMesh.new()
		sphere.radius = 0.27
		sphere.height = 0.54
		head.mesh = sphere
		head.position.y = 1.82
		head.material_override = material
		spectator.add_child(head)
		venue.add_child(spectator)
		crowd_nodes.append(spectator)

const ARENA_STAND_Z := 38.0

func _on_crowd_cheered(_fighter_id: String, intensity: float) -> void:
	for index in range(crowd_nodes.size()):
		var spectator := crowd_nodes[index]
		if not is_instance_valid(spectator):
			continue
		if index % 5 != 0 or intensity >= 0.75:
			spectator.set_meta("cheer_intensity", maxf(float(spectator.get_meta("cheer_intensity", 0.0)), intensity))

func _process(delta: float) -> void:
	crowd_clock += delta
	for index in range(crowd_nodes.size()):
		var spectator := crowd_nodes[index]
		if is_instance_valid(spectator):
			var intensity := float(spectator.get_meta("cheer_intensity", 0.0))
			var sway := sin(crowd_clock * (2.0 + float(index % 4) * 0.25) + float(index)) * (0.035 + intensity * 0.08)
			spectator.rotation.z = sway
			var base_y := float(spectator.get_meta("base_y", spectator.position.y))
			spectator.position.y = base_y + absf(sin(crowd_clock * 5.0 + float(index))) * 0.32 * intensity
			spectator.set_meta("cheer_intensity", maxf(0.0, intensity - delta * 0.7))

func _exit_tree() -> void:
	for spectator in crowd_nodes:
		if is_instance_valid(spectator):
			spectator.queue_free()
