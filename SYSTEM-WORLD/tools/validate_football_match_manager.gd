extends SceneTree

const FOOTBALL_SCRIPT = preload("res://scripts/system_football_match_manager.gd")

func _initialize() -> void:
	var stadium := Node3D.new()
	stadium.name = "ValidatorStadium"
	root.add_child(stadium)
	var player := CharacterBody3D.new()
	player.name = "ValidatorPlayer"
	root.add_child(player)
	var manager = FOOTBALL_SCRIPT.new()
	root.add_child(manager)
	manager.setup(stadium, player)
	for node_name in ["SYSTEMFootballMatchBall", "FootballMatchControlInteraction", "FootballMatchScoreboard", "HomeGoalTrigger", "AwayGoalTrigger"]:
		if stadium.get_node_or_null(node_name) == null:
			push_error("Football validation failed: missing stadium component " + node_name)
			quit(1)
			return
	var started: Dictionary = manager.start_match("SYSTEM Baghdad", "Validator United")
	if not bool(started.get("success", false)):
		push_error("Football validation failed: match could not start.")
		quit(1)
		return
	player.global_position = stadium.global_position + Vector3(0.0, 0.0, -5.0)
	var kick: Dictionary = manager.kick_ball_toward_goal(player)
	if not bool(kick.get("success", false)):
		push_error("Football validation failed: nearby player could not kick the ball.")
		quit(1)
		return
	manager.call("_on_goal_body_entered", manager.football_ball, "home")
	var status: Dictionary = manager.get_match_status()
	if int(status.get("home_score", 0)) != 1:
		push_error("Football validation failed: goal did not update the scoreboard state.")
		quit(1)
		return
	if float(status.get("remaining_seconds", 0.0)) <= 0.0:
		push_error("Football validation failed: match timer is invalid.")
		quit(1)
		return
	manager.queue_free()
	stadium.queue_free()
	player.queue_free()
	print("Football validation passed: match start, ball interaction, scoring and timer state.")
	quit(0)
