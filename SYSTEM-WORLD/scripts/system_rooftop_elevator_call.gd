extends Area3D
class_name SystemRooftopElevatorCall

## Interactive call panel for the shared rooftop lift cabin.
var player: CharacterBody3D
var lift_cabin: Node3D
var destination_cabin_position := Vector3.ZERO
var destination_player_position := Vector3.ZERO
var display_name := "مصعد المدينة العلوية"
var _player_physics_was_enabled := true

func configure(p_player: CharacterBody3D, p_cabin: Node3D, cabin_destination: Vector3, player_destination: Vector3, title: String) -> void:
	player = p_player
	lift_cabin = p_cabin
	destination_cabin_position = cabin_destination
	destination_player_position = player_destination
	display_name = title
	if not has_meta("system_location_id"):
		set_meta("system_location_id", "baghdad_rooftop_elevator_" + str(get_instance_id()))
	set_meta("system_region_id", "region_baghdad")
	set_meta("system_display_name", display_name)
	set_meta("system_interaction_prompt", "استخدام " + display_name)
	set_meta("system_location_type", 7)
	add_to_group("system_interactable")

func configure_player(p_player: CharacterBody3D) -> void:
	player = p_player

func system_interact() -> void:
	if not is_instance_valid(player) or not is_instance_valid(lift_cabin):
		push_warning("SYSTEM WORLD: rooftop elevator is not connected to the player or cabin.")
		return
	if bool(lift_cabin.get_meta("system_elevator_busy", false)):
		return
	if player.global_position.distance_to(global_position) > 7.0:
		return

	# Board the platform first; do not carry the player beside or below the cabin.
	var boarding_position := lift_cabin.global_position + Vector3(0.0, 1.1, 0.0)
	_player_physics_was_enabled = player.is_physics_processing()
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	lift_cabin.set_meta("system_elevator_busy", true)
	monitoring = false

	var boarding_tween := create_tween()
	boarding_tween.tween_property(player, "global_position", boarding_position, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	boarding_tween.finished.connect(_begin_lift_travel)

func _begin_lift_travel() -> void:
	if not is_instance_valid(player) or not is_instance_valid(lift_cabin):
		_on_ride_finished()
		return
	var ride_tween := create_tween()
	ride_tween.set_parallel(true)
	ride_tween.tween_property(lift_cabin, "global_position", destination_cabin_position, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ride_tween.tween_property(player, "global_position", destination_player_position, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ride_tween.finished.connect(_on_ride_finished)

func _on_ride_finished() -> void:
	if is_instance_valid(lift_cabin):
		lift_cabin.set_meta("system_elevator_busy", false)
	if is_instance_valid(player):
		player.velocity = Vector3.ZERO
		player.set_physics_process(_player_physics_was_enabled)
	monitoring = true
