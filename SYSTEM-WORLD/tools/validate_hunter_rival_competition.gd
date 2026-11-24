extends SceneTree

const RivalScript = preload("res://scripts/system_hunter_rival_competition.gd")
const StageRuntimeScript = preload("res://scripts/system_hunter_exam_stage_runtime.gd")
const PlayerHealthScript = preload("res://scripts/system_player_combat_health.gd")

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
	var player_health := PlayerHealthScript.new()
	player_health.name = "PlayerCombatHealth"
	player.add_child(player_health)
	player_health.call("bind_player", player)
	var runtime := StageRuntimeScript.new()
	runtime.name = "HunterCompetitionRuntime"
	arena.add_child(runtime)
	var built: Dictionary = runtime.call("activate_stage", {"id":"baghdad_tunnel_competition"}, player, null)
	if not _check(bool(built.get("success", false)), "The canonical continuous tunnel competition environment did not build."):
		return
	var rivals: Node = runtime.get("rival_competition")
	if not _check(is_instance_valid(rivals), "AI rivals were not attached to the actual Hunter tunnel environment."):
		return
	var status: Dictionary = rivals.call("get_competition_status")
	if not _check(int(status.get("rival_count", 0)) == 5, "Expected five distinct AI rival archetypes in the tunnel."):
		return
	if not _check(not bool(status.get("online_multiplayer", true)), "Online play must not be claimed before server integration."):
		return
	rivals.call("record_player_objective", "test_relic")
	for attempt in range(100):
		if bool(rivals.call("get_competition_status").get("objective_stolen", false)):
			break
		rivals.call("_perform_action")
	status = rivals.call("get_competition_status")
	if not _check(bool(status.get("objective_stolen", false)), "Thief AI did not steal a recorded player objective."):
		return
	if not _check(not bool(rivals.call("can_continue_objectives")), "A stolen objective did not block progression."):
		return
	var recovered := false
	for attempt in range(30):
		var recovery: Dictionary = rivals.call("handle_rival_interaction", "rival_ren")
		if bool(recovery.get("recovered", false)):
			recovered = true
			break
	if not _check(recovered and bool(rivals.call("can_continue_objectives")), "Player could not recover the stolen objective from the thief."):
		return
	var deceiver: Dictionary = rivals.call("handle_rival_interaction", "rival_kai")
	if not _check(bool(deceiver.get("handled", false)), "Deceiver interaction was not handled."):
		return
	var fighter: Dictionary = rivals.call("handle_rival_interaction", "rival_daigo")
	if not _check(bool(fighter.get("handled", false)) and bool(fighter.get("duel_started", false)), "Individual fighter challenge did not activate a real duel."):
		return
	var fighter_entry: Dictionary = rivals.get("rivals").get("rival_daigo")
	var fighter_actor: Node = fighter_entry.get("node")
	if not _check(fighter_actor.has_method("take_damage"), "Hunter rivals are not damageable combatants."):
		return
	fighter_actor.call("take_damage", 150.0, player)
	status = rivals.call("get_competition_status")
	if not _check(int(status.get("defeated_count", 0)) == 1, "Defeating a rival did not remove them from the individual competition."):
		return
	var unknown: Dictionary = rivals.call("handle_rival_interaction", "unknown_rival")
	if not _check(not bool(unknown.get("handled", true)), "Unknown rival ID should be rejected."):
		return
	print("Hunter rival competition validation passed: five AI rivals spawn; theft blocks progress and recovery restores it; deception and ambush interactions work; individual combat damage defeats rivals; online multiplayer remains unclaimed.")
	quit(0)
