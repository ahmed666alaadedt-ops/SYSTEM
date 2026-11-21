extends SceneTree

const ARENA_UI_SCRIPT = preload("res://scripts/system_power_tower_arena_ui.gd")
const ARENA_MANAGER_SCRIPT = preload("res://scripts/system_power_tower_arena_manager.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Power Tower arena UI validation failed: " + message)
	quit(1)

func _run() -> void:
	var manager = ARENA_MANAGER_SCRIPT.new()
	var ui = ARENA_UI_SCRIPT.new()
	root.add_child(manager)
	root.add_child(ui)
	ui.setup(manager)
	if ui.get_node_or_null("ArenaControlPanel") == null:
		_fail("Arena panel was not created.")
		return
	if ui.get_node("ArenaControlPanel").get_node_or_null("VBoxContainer") == null:
		_fail("Arena panel layout is missing.")
		return
	if not ui.has_method("show_arena") or not ui.has_method("hide_arena"):
		_fail("Arena visibility controls are missing.")
		return
	var registration: Dictionary = manager.register_fighter("local_player")
	if not bool(registration.get("success", false)) or int(registration.get("entry_fee", -1)) != 0:
		_fail("UI-linked fighter registration is not free.")
		return
	var created: Dictionary = manager.create_match("arena_guest_alpha", "arena_guest_beta")
	if not bool(created.get("success", false)):
		_fail("Showcase match could not be created.")
		return
	for index in range(28):
		manager.add_npc_prediction("arena_spectator_%02d" % index, "arena_guest_alpha" if index % 2 == 0 else "arena_guest_beta")
	if int(manager.get_match_status().get("npc_predictions", 0)) != 28:
		_fail("The 28 spectator predictions were not registered.")
		return
	if not bool(manager.open_betting().get("success", false)):
		_fail("Showcase match betting could not be opened.")
		return
	var bet: Dictionary = manager.place_spectator_bet("local_player", "arena_guest_alpha", 50)
	if not bool(bet.get("success", false)):
		_fail("Local spectator wager could not be accepted.")
		return
	if not bool(manager.lock_betting_and_start_match().get("success", false)):
		_fail("Betting could not be locked before match start.")
		return
	if str(manager.place_spectator_bet("local_player", "arena_guest_alpha", 50).get("reason", "")) != "BETTING_CLOSED":
		_fail("The UI manager accepted a wager after match start.")
		return
	ui.queue_free()
	manager.queue_free()
	print("Power Tower arena UI validation passed: panel construction, free registration, 28 audience predictions, spectator betting and lockout.")
	quit(0)
