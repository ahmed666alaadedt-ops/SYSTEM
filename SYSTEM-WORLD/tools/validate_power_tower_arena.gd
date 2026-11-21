extends SceneTree

class FakeWallet:
	extends Node
	var balance := 10000
	func spend_currency(amount: int, _reason: String = "") -> Dictionary:
		if amount <= 0 or balance < amount:
			return {"success": false, "balance": balance}
		balance -= amount
		return {"success": true, "balance": balance}
	func credit_currency(amount: int, _reason: String = "") -> Dictionary:
		if amount <= 0:
			return {"success": false, "balance": balance}
		balance += amount
		return {"success": true, "balance": balance}

const ARENA_SCRIPT = preload("res://scripts/system_power_tower_arena_manager.gd")
const ARENA_VENUE_SCRIPT = preload("res://scripts/system_power_tower_arena_venue.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Power Tower arena validation failed: " + message)
	quit(1)

func _run() -> void:
	var wallet := FakeWallet.new()
	var arena = ARENA_SCRIPT.new()
	arena.setup(wallet)
	root.add_child(wallet)
	root.add_child(arena)

	var venue = ARENA_VENUE_SCRIPT.new()
	root.add_child(venue)
	var venue_interaction := venue.get_node_or_null("PowerTowerArenaInteraction")
	if venue_interaction == null:
		_fail("The independent exhibition arena has no physical entry interaction.")
		return
	if str(venue_interaction.get_meta("system_location_id", "")) != "power_tower_arena_baghdad":
		_fail("The exhibition arena entry does not have its stable Baghdad location ID.")
		return
	if not venue_interaction.is_in_group("system_interactable"):
		_fail("The exhibition arena entry is not registered as an interactable location.")
		return
	var created: Dictionary = arena.create_match("fighter_a", "fighter_b")
	if not bool(created.get("success", false)) or int(created.get("fighter_entry_fee", -1)) != 0:
		_fail("Fighter entry must be free.")
		return
	if not bool(arena.open_betting().get("success", false)):
		_fail("Spectator betting did not open.")
		return
	var fighter_bet: Dictionary = arena.place_spectator_bet("fighter_a", "fighter_b", 100)
	if str(fighter_bet.get("reason", "")) != "FIGHTERS_CANNOT_BET_ON_THEIR_MATCH":
		_fail("A fighter was allowed to bet on their own match.")
		return
	var invalid_remote: Dictionary = arena.place_spectator_bet("another_online_user", "fighter_a", 100)
	if str(invalid_remote.get("reason", "")) != "REMOTE_WAGERS_REQUIRE_SERVER_AUTHORITY":
		_fail("Remote wagering was allowed without server authority.")
		return
	var too_small: Dictionary = arena.place_spectator_bet("local_player", "fighter_a", 5)
	if str(too_small.get("reason", "")) != "BET_AMOUNT_OUT_OF_RANGE":
		_fail("A below-minimum bet was accepted.")
		return
	var placed: Dictionary = arena.place_spectator_bet("local_player", "fighter_a", 100)
	if not bool(placed.get("success", false)) or wallet.balance != 9900:
		_fail("A valid local spectator bet was not escrowed.")
		return
	if bool(arena.place_spectator_bet("local_player", "fighter_b", 100).get("success", false)):
		_fail("A spectator placed more than one bet in a match.")
		return
	arena.add_npc_prediction("npc_01", "fighter_a")
	var locked: Dictionary = arena.lock_betting_and_start_match()
	if not bool(locked.get("success", false)):
		_fail("Betting could not be locked before match start.")
		return
	if str(arena.place_spectator_bet("local_player", "fighter_a", 100).get("reason", "")) != "BETTING_CLOSED":
		_fail("A bet was accepted after the match started.")
		return
	var result: Dictionary = arena.resolve_match("fighter_a")
	if not bool(result.get("success", false)) or int(result.get("payout_total", 0)) != 100:
		_fail("Winning spectator did not receive the pari-mutuel pool.")
		return
	if wallet.balance != 10000:
		_fail("Wallet settlement did not conserve virtual currency.")
		return
	var no_winner_match: Dictionary = arena.create_match("fighter_e", "fighter_f")
	if not bool(no_winner_match.get("success", false)):
		_fail("Could not create no-winner refund test match.")
		return
	arena.open_betting()
	var losing_side_bet: Dictionary = arena.place_spectator_bet("local_player", "fighter_e", 200)
	if not bool(losing_side_bet.get("success", false)):
		_fail("Could not place no-winner refund test bet.")
		return
	arena.lock_betting_and_start_match()
	var no_winner_result: Dictionary = arena.resolve_match("fighter_f")
	if int(no_winner_result.get("no_winner_refunds", 0)) != 200 or wallet.balance != 10000:
		_fail("A pool with no winning tickets was not refunded.")
		return

	var cancel_match: Dictionary = arena.create_match("fighter_c", "fighter_d")
	if not bool(cancel_match.get("success", false)):
		_fail("Could not create a second match.")
		return
	arena.open_betting()
	var second_bet: Dictionary = arena.place_spectator_bet("local_player", "fighter_c", 150)
	if not bool(second_bet.get("success", false)):
		_fail("Could not place cancellation test bet.")
		return
	var cancelled: Dictionary = arena.cancel_match()
	if int(cancelled.get("refunded", 0)) != 150 or wallet.balance != 10000:
		_fail("Cancelled match did not refund the spectator.")
		return
	venue.queue_free()
	arena.queue_free()
	wallet.queue_free()
	print("Power Tower arena validation passed: free fighter entry, spectator-only local wagers, anti-self-bet, locked betting, pari-mutuel payout, NPC predictions and refunds.")
	quit(0)
