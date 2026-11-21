extends Node
class_name SystemFootballMatchManager

signal match_started(home_team: String, away_team: String)
signal score_changed(home_score: int, away_score: int, scoring_team: String)
signal match_finished(result: Dictionary)

const PITCH_HALF_LENGTH := 52.5
const PITCH_HALF_WIDTH := 34.0
const MATCH_DURATION_SECONDS := 300.0
const BALL_SPAWN := Vector3(0.0, 1.8, -5.0)

var stadium_root: Node3D
var player: CharacterBody3D
var football_ball: RigidBody3D
var scoreboard: Label3D
var match_active := false
var remaining_seconds := MATCH_DURATION_SECONDS
var home_score := 0
var away_score := 0
var home_team_name := "SYSTEM Baghdad"
var away_team_name := "Baghdad United"

func setup(p_stadium_root: Node3D, p_player: CharacterBody3D) -> void:
	stadium_root = p_stadium_root
	player = p_player
	_build_match_ball()
	_build_goal_zones()
	_build_match_control()
	_build_scoreboard()
	_update_scoreboard()

func _process(delta: float) -> void:
	if not match_active:
		return
	remaining_seconds = maxf(0.0, remaining_seconds - maxf(0.0, delta))
	_update_scoreboard()
	if remaining_seconds <= 0.0:
		_finish_match()

func _build_match_ball() -> void:
	football_ball = RigidBody3D.new()
	football_ball.name = "SYSTEMFootballMatchBall"
	football_ball.position = BALL_SPAWN
	football_ball.mass = 0.43
	football_ball.linear_damp = 0.18
	football_ball.angular_damp = 0.12
	football_ball.continuous_cd = true
	football_ball.add_to_group("system_football_ball")
	var ball_mesh := MeshInstance3D.new()
	ball_mesh.name = "FootballVisual"
	var sphere := SphereMesh.new()
	sphere.radius = 0.48
	sphere.height = 0.96
	ball_mesh.mesh = sphere
	var ball_material := StandardMaterial3D.new()
	ball_material.albedo_color = Color(0.92, 0.92, 0.86)
	ball_material.roughness = 0.72
	ball_mesh.material_override = ball_material
	football_ball.add_child(ball_mesh)
	var ball_collision := CollisionShape3D.new()
	var ball_shape := SphereShape3D.new()
	ball_shape.radius = 0.48
	ball_collision.shape = ball_shape
	football_ball.add_child(ball_collision)
	var kick_interaction := Area3D.new()
	kick_interaction.name = "FootballKickInteraction"
	kick_interaction.add_to_group("system_interactable")
	kick_interaction.collision_layer = 1
	kick_interaction.collision_mask = 0
	kick_interaction.set_meta("system_location_id", "baghdad_stadium_ball")
	kick_interaction.set_meta("system_region_id", "region_baghdad")
	kick_interaction.set_meta("system_display_name", "كرة مباراة ملعب بغداد")
	kick_interaction.set_meta("system_interaction_prompt", "ركل الكرة باتجاه مرمى الخصم")
	var kick_collision := CollisionShape3D.new()
	var kick_shape := SphereShape3D.new()
	kick_shape.radius = 2.4
	kick_collision.shape = kick_shape
	kick_interaction.add_child(kick_collision)
	football_ball.add_child(kick_interaction)
	stadium_root.add_child(football_ball)

func _build_goal_zones() -> void:
	_create_goal_zone("HomeGoalTrigger", Vector3(PITCH_HALF_LENGTH + 1.5, 2.0, 0.0), "home")
	_create_goal_zone("AwayGoalTrigger", Vector3(-PITCH_HALF_LENGTH - 1.5, 2.0, 0.0), "away")

func _create_goal_zone(zone_name: String, position: Vector3, scoring_team: String) -> void:
	var goal := Area3D.new()
	goal.name = zone_name
	goal.collision_layer = 0
	goal.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.0, 4.0, 9.0)
	collision.shape = shape
	goal.add_child(collision)
	goal.position = position
	goal.body_entered.connect(_on_goal_body_entered.bind(scoring_team))
	stadium_root.add_child(goal)

func _build_match_control() -> void:
	var control := Area3D.new()
	control.name = "FootballMatchControlInteraction"
	control.add_to_group("system_interactable")
	control.set_meta("system_location_id", "baghdad_stadium_match_control")
	control.set_meta("system_region_id", "region_baghdad")
	control.set_meta("system_display_name", "إدارة مباريات ملعب بغداد")
	control.set_meta("system_interaction_prompt", "بدء مباراة كرة القدم — خمس دقائق")
	control.position = Vector3(0.0, 1.5, -42.0)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 4.0
	collision.shape = shape
	control.add_child(collision)
	stadium_root.add_child(control)

func _build_scoreboard() -> void:
	scoreboard = Label3D.new()
	scoreboard.name = "FootballMatchScoreboard"
	scoreboard.font_size = 28
	scoreboard.pixel_size = 0.014
	scoreboard.position = Vector3(0.0, 12.0, -43.0)
	scoreboard.modulate = Color(0.88, 0.96, 1.0)
	stadium_root.add_child(scoreboard)

func start_match(home_name: String = "SYSTEM Baghdad", away_name: String = "Baghdad United") -> Dictionary:
	if match_active:
		return {"success": false, "reason": "MATCH_ALREADY_ACTIVE"}
	home_team_name = home_name if not home_name.strip_edges().is_empty() else "SYSTEM Baghdad"
	away_team_name = away_name if not away_name.strip_edges().is_empty() else "Baghdad United"
	home_score = 0
	away_score = 0
	remaining_seconds = MATCH_DURATION_SECONDS
	match_active = true
	_reset_ball()
	_update_scoreboard()
	match_started.emit(home_team_name, away_team_name)
	return {"success": true, "home_team": home_team_name, "away_team": away_team_name, "duration_seconds": MATCH_DURATION_SECONDS}

func kick_ball_toward_goal(kicker: Node3D) -> Dictionary:
	if not match_active:
		return {"success": false, "reason": "MATCH_NOT_ACTIVE"}
	if not is_instance_valid(football_ball) or not is_instance_valid(kicker):
		return {"success": false, "reason": "BALL_OR_PLAYER_UNAVAILABLE"}
	if kicker.global_position.distance_to(football_ball.global_position) > 6.0:
		return {"success": false, "reason": "PLAYER_TOO_FAR_FROM_BALL"}
	football_ball.freeze = false
	var attack_direction := 1.0 if kicker.global_position.x <= stadium_root.global_position.x else -1.0
	var impulse := Vector3(attack_direction * 17.0, 4.2, 0.0)
	football_ball.apply_central_impulse(impulse)
	return {"success": true, "message": "BALL_KICKED"}

func _on_goal_body_entered(body: Node3D, scoring_team: String) -> void:
	if not match_active or body != football_ball:
		return
	if scoring_team == "home":
		home_score += 1
	else:
		away_score += 1
	score_changed.emit(home_score, away_score, scoring_team)
	_update_scoreboard()
	football_ball.freeze = true
	get_tree().create_timer(1.6).timeout.connect(_reset_ball)

func _reset_ball() -> void:
	if not is_instance_valid(football_ball):
		return
	football_ball.freeze = true
	football_ball.global_position = stadium_root.to_global(BALL_SPAWN)
	football_ball.linear_velocity = Vector3.ZERO
	football_ball.angular_velocity = Vector3.ZERO
	football_ball.freeze = false

func _finish_match() -> void:
	match_active = false
	var result := {
		"home_team": home_team_name,
		"away_team": away_team_name,
		"home_score": home_score,
		"away_score": away_score,
		"winner": "draw" if home_score == away_score else ("home" if home_score > away_score else "away"),
		"duration_seconds": MATCH_DURATION_SECONDS
	}
	_update_scoreboard()
	match_finished.emit(result)

func get_match_status() -> Dictionary:
	return {
		"active": match_active,
		"home_team": home_team_name,
		"away_team": away_team_name,
		"home_score": home_score,
		"away_score": away_score,
		"remaining_seconds": remaining_seconds
	}

func _update_scoreboard() -> void:
	if not is_instance_valid(scoreboard):
		return
	var minutes := int(remaining_seconds / 60.0)
	var seconds := int(remaining_seconds) % 60
	scoreboard.text = "%s  %d : %d  %s\n%02d:%02d" % [home_team_name, home_score, away_score, away_team_name, minutes, seconds]
