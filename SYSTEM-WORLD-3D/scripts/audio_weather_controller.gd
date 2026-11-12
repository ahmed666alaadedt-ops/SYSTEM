
extends Node

# SYSTEM WORLD - DYNAMIC WEATHER AUDIO CONTROLLER
# Godot 4.3
# Continuous weather ambience with dynamic intensity.

@export_group("Weather Audio")
@export var rain_stream: AudioStream
@export var wind_stream: AudioStream
@export var storm_stream: AudioStream
@export var snow_stream: AudioStream
@export var sandstorm_stream: AudioStream
@export var thunder_stream: AudioStream

@export_group("Audio Settings")
@export var ambient_bus: String = "Ambient"
@export var sfx_bus: String = "SFX"

@export_range(0.0, 1.0, 0.05)
var master_weather_volume: float = 0.8

@export_range(0.1, 10.0, 0.1)
var fade_duration: float = 2.0

@export_group("Thunder Settings")
@export_range(3.0, 60.0, 1.0)
var thunder_min_delay: float = 8.0

@export_range(5.0, 90.0, 1.0)
var thunder_max_delay: float = 25.0

var weather_players: Dictionary = {}
var thunder_timer: Timer

var current_weather: String = "clear"
var current_intensity: float = 0.0
var player_is_indoors: bool = false


func _ready() -> void:
	_create_weather_player("rain", rain_stream)
	_create_weather_player("wind", wind_stream)
	_create_weather_player("storm", storm_stream)
	_create_weather_player("snow", snow_stream)
	_create_weather_player("sandstorm", sandstorm_stream)

	thunder_timer = Timer.new()
	thunder_timer.name = "ThunderTimer"
	thunder_timer.one_shot = true
	thunder_timer.timeout.connect(_play_thunder)
	add_child(thunder_timer)


func _create_weather_player(
	weather_name: String,
	stream: AudioStream
) -> void:
	var player := AudioStreamPlayer.new()
	player.name = weather_name.capitalize() + "Audio"

	player.stream = stream
	player.volume_db = -40.0

	if AudioServer.get_bus_index(ambient_bus) >= 0:
		player.bus = ambient_bus
	else:
		player.bus = "Master"

	add_child(player)
	weather_players[weather_name] = player


func set_weather(
	weather_name: String,
	intensity: float = 1.0,
	indoors: bool = false
) -> void:
	current_weather = weather_name.to_lower()
	current_intensity = clampf(intensity, 0.0, 1.0)
	player_is_indoors = indoors

	_update_weather_audio()
	_update_thunder_timer()


func set_weather_intensity(
	intensity: float
) -> void:
	current_intensity = clampf(intensity, 0.0, 1.0)

	_update_weather_audio()
	_update_thunder_timer()


func set_indoors(
	indoors: bool
) -> void:
	player_is_indoors = indoors

	_update_weather_audio()


func _update_weather_audio() -> void:
	var rain_amount := 0.0
	var wind_amount := 0.0
	var storm_amount := 0.0
	var snow_amount := 0.0
	var sand_amount := 0.0

	match current_weather:
		"rain":
			rain_amount = current_intensity
			wind_amount = current_intensity * 0.25

		"wind":
			wind_amount = current_intensity

		"storm":
			rain_amount = current_intensity
			wind_amount = current_intensity
			storm_amount = current_intensity

		"snow":
			snow_amount = current_intensity
			wind_amount = current_intensity * 0.35

		"sandstorm":
			sand_amount = current_intensity
			wind_amount = current_intensity * 0.8

		_:
			pass

	var indoor_multiplier := 0.3 if player_is_indoors else 1.0

	_set_loop("rain", rain_amount * indoor_multiplier)
	_set_loop("wind", wind_amount * indoor_multiplier)
	_set_loop("storm", storm_amount * indoor_multiplier)
	_set_loop("snow", snow_amount * indoor_multiplier)
	_set_loop("sandstorm", sand_amount * indoor_multiplier)


func _set_loop(
	weather_name: String,
	intensity: float
) -> void:
	if not weather_players.has(weather_name):
		return

	var player: AudioStreamPlayer = weather_players[weather_name]

	if player.stream == null:
		return

	var final_intensity := clampf(
		intensity * master_weather_volume,
		0.0,
		1.0
	)

	if final_intensity > 0.01:
		if not player.playing:
			player.volume_db = -40.0
			player.play()

		var target_db := linear_to_db(final_intensity)

		var tween := create_tween()
		tween.tween_property(
			player,
			"volume_db",
			target_db,
			maxf(fade_duration, 0.1)
		)
	else:
		if player.playing:
			var tween := create_tween()

			tween.tween_property(
				player,
				"volume_db",
				-40.0,
				maxf(fade_duration, 0.1)
			)

			tween.tween_callback(player.stop)


func _update_thunder_timer() -> void:
	if thunder_timer == null:
		return

	if current_weather != "storm":
		thunder_timer.stop()
		return

	if thunder_stream == null:
		return

	if current_intensity < 0.35:
		thunder_timer.stop()
		return

	if thunder_timer.is_stopped():
		var delay := randf_range(
			thunder_min_delay,
			maxf(thunder_max_delay, thunder_min_delay)
		)

		thunder_timer.start(delay)


func _play_thunder() -> void:
	if current_weather != "storm":
		return

	if current_intensity < 0.35:
		return

	if thunder_stream == null:
		return

	var thunder_player := AudioStreamPlayer.new()
	thunder_player.stream = thunder_stream
	thunder_player.volume_db = linear_to_db(
		current_intensity * master_weather_volume
	)

	if AudioServer.get_bus_index(sfx_bus) >= 0:
		thunder_player.bus = sfx_bus
	else:
		thunder_player.bus = "Master"

	add_child(thunder_player)

	thunder_player.finished.connect(
		thunder_player.queue_free
	)

	thunder_player.play()

	_update_thunder_timer()


func stop_weather_audio() -> void:
	current_weather = "clear"
	current_intensity = 0.0

	if thunder_timer != null:
		thunder_timer.stop()

	_update_weather_audio()


func _exit_tree() -> void:
	if thunder_timer != null:
		thunder_timer.stop()

	for player in weather_players.values():
		if is_instance_valid(player):
			player.stop()
