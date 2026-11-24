extends SceneTree

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

	# Ren's theft must block objective progression until the player recovers the item.
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

	# The thief remains interactable after defeat so the objective cannot become permanently lost.
	rivals.call("record_player_objective", "second_relic")
	for attempt in range(100):
		if bool(rivals.call("get_competition_status").get("objective_stolen", false)):
			break
		rivals.call("_perform_action")
	if not _check(bool(rivals.call("get_competition_status").get("objective_stolen", false)), "Thief did not steal the second objective for defeated-thief recovery validation."):
		return
	var thief_entry: Dictionary = rivals.get("rivals").get("rival_ren")
	var thief_actor: Node = thief_entry.get("node")
	thief_actor.call("take_damage", 100.0, player)
	var thief_interaction := thief_actor.get_node("RivalInteraction") as Area3D
	if not _check(thief_interaction.monitoring, "Defeated thief interaction was disabled before the stolen objective could be recovered."):
		return
	var defeated_thief_recovery: Dictionary = rivals.call("handle_rival_interaction", "rival_ren")
	if not _check(bool(defeated_thief_recovery.get("recovered", false)) and bool(rivals.call("can_continue_objectives")), "Stolen objective could not be recovered after defeating the thief."):
		return

	# Kai's deceptive interaction and Sami's explicitly fair, non-combat interaction.
	var deceiver: Dictionary = rivals.call("handle_rival_interaction", "rival_kai")
	if not _check(bool(deceiver.get("handled", false)) and bool(deceiver.get("success", false)), "Deceiver interaction was not handled."):
		return
	var honorable: Dictionary = rivals.call("handle_rival_interaction", "rival_sami")
	if not _check(bool(honorable.get("handled", false)) and bool(honorable.get("success", false)) and not bool(honorable.get("duel_started", false)), "Sami's fair rival interaction unexpectedly started combat or failed."):
		return
	if not _check(bool(rivals.call("can_continue_objectives")), "Sami must not steal or block the player's objective."):
		return

	# Mira must reveal her ambush and activate pursuit when the player enters her detection radius.
	var mira_entry: Dictionary = rivals.get("rivals").get("rival_mira")
	var mira_actor: CharacterBody3D = mira_entry.get("node")
	mira_actor.global_position = Vector3(5.0, 0.0, 0.0)
	rivals.call("_process", 0.016)
	if not _check(bool(mira_entry.get("duel_active", false)) and bool(mira_actor.get_meta("ambush_announced", false)), "Mira did not reveal her ambush and activate pursuit when the player approached."):
		return
	var mira_interaction: Dictionary = rivals.call("handle_rival_interaction", "rival_mira")
	if not _check(bool(mira_interaction.get("handled", false)) and bool(mira_interaction.get("duel_started", false)), "Mira's ambush interaction did not start the individual confrontation."):
		return

	# Daigo's challenge is a one-on-one duel; rival weapon damage must reach player health.
	var fighter: Dictionary = rivals.call("handle_rival_interaction", "rival_daigo")
	if not _check(bool(fighter.get("handled", false)) and bool(fighter.get("duel_started", false)), "Individual fighter challenge did not activate a real duel."):
		return
	var health_before: float = float(player_health.get("current_health"))
	rivals.call("_attempt_rival_attack", "rival_daigo")
	var health_after: float = float(player_health.get("current_health"))
	if not _check(health_after < health_before, "Rival attack did not reduce the bound player's combat health."):
		return

	# Damage applied through the rival actor's weapon-hit entry point must reduce its health and defeat it.
	var fighter_entry: Dictionary = rivals.get("rivals").get("rival_daigo")
	var fighter_actor: Node = fighter_entry.get("node")
	if not _check(fighter_actor.has_method("take_damage"), "Hunter rivals are not damageable combatants."):
		return
	fighter_actor.call("take_damage", 35.0, player)
	if not _check(is_equal_approx(float(fighter_actor.call("get_health_ratio")), 0.65), "A player hit did not reduce the rival actor's health."):
		return
	fighter_actor.call("take_damage", 100.0, player)
	status = rivals.call("get_competition_status")
	if not _check(int(status.get("defeated_count", 0)) == 2, "Defeating rivals did not remove them from the individual competition."):
		return

	var unknown: Dictionary = rivals.call("handle_rival_interaction", "unknown_rival")
	if not _check(not bool(unknown.get("handled", true)), "Unknown rival ID should be rejected."):
		return
	print("Hunter rival competition validation passed: five AI rivals spawn; Ren steals and objectives are recoverable even after his defeat; Kai deception, Mira ambush/pursuit, Sami fair rivalry, Daigo individual combat, rival-to-player damage and player-hit-to-rival health all work; online multiplayer remains unclaimed.")
	quit(0)
