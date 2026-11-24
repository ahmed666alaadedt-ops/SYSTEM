extends SceneTree

const RivalScript = preload("res://scripts/system_hunter_rival_competition.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Hunter rival competition validation failed: " + message)
	quit(1)
	return false

func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	var player := CharacterBody3D.new()
	arena.add_child(player)
	var rivals := RivalScript.new()
	arena.add_child(rivals)
	rivals.call("setup", player, arena)
	await process_frame
	var status: Dictionary = rivals.call("get_competition_status")
	if not _check(int(status.get("rival_count", 0)) == 5, "Expected five distinct AI rival archetypes."):
		return
	if not _check(not bool(status.get("online_multiplayer", true)), "Online play must not be claimed before server integration."):
		return
	rivals.call("record_player_objective", "test_relic")
	if not _check(bool(rivals.call("can_continue_objectives")), "Normal objective should initially allow progression."):
		return
	var handled: Dictionary = rivals.call("handle_rival_interaction", "rival_kai")
	if not _check(bool(handled.get("handled", false)), "Deceiver interaction was not handled."):
		return
	var thief_interaction: Dictionary = rivals.call("handle_rival_interaction", "rival_ren")
	if not _check(bool(thief_interaction.get("handled", false)), "Thief interaction was not handled."):
		return
	var fighter_interaction: Dictionary = rivals.call("handle_rival_interaction", "rival_daigo")
	if not _check(bool(fighter_interaction.get("handled", false)), "Individual fighter interaction was not handled."):
		return
	var unknown: Dictionary = rivals.call("handle_rival_interaction", "unknown_rival")
	if not _check(not bool(unknown.get("handled", true)), "Unknown rival ID should be rejected."):
		return
	print("Hunter rival competition validation passed: five AI rivals, deception, individual challenge, theft/recovery hooks and offline-only boundary.")
	quit(0)
