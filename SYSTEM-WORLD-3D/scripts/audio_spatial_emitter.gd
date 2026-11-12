
extends Node3D

# SYSTEM WORLD - 3D SPATIAL AUDIO EMITTER
# Godot 4.3
# Persistent environmental and positional audio.

@export var audio_stream: AudioStream

@export_enum("SFX", "Ambient", "Voice", "Music", "UI")
var audio_bus: String = "Ambient"

@export_range(-40.0, 6.0, 0.5)
var target_volume_db: float = -5.0

@export_range(1.0, 500.0, 1.0)
var max_distance: float = 60.0

@export_range(1.0, 30.0, 0.5)
var unit_size: float = 8.0

@export_range(0.0, 2.0, 0.05)
var panning_strength: float = 1.0

@export var play_on_ready: bool = true

var audio_player: AudioStreamPlayer3D
var emitter_enabled := true


func _ready() -> void:
	_create_player()

	if play_on_ready:
		start_emitter()


func _create_player() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "SpatialAudioPlayer"

	audio_player.stream = audio_stream
	audio_player.max_distance = max_distance
	audio_player.unit_size = unit_size
	audio_player.panning_strength = panning_strength
	audio_player.volume_db = target_volume_db

	if AudioServer.get_bus_index(audio_bus) >= 0:
		audio_player.bus = audio_bus
	else:
		audio_player.bus = "Master"

	add_child(audio_player)


func start_emitter(
	fade_duration: float = 1.5
) -> void:
	if audio_player == null:
		return

	if audio_stream == null:
		push_warning("SpatialAudioEmitter: No audio stream assigned.")
		return

	emitter_enabled = true

	if not audio_player.playing:
		audio_player.volume_db = -40.0
		audio_player.play()

	var tween := create_tween()

	tween.tween_property(
		audio_player,
		"volume_db",
		target_volume_db,
		maxf(fade_duration, 0.01)
	)


func stop_emitter(
	fade_duration: float = 1.5
) -> void:
	if audio_player == null:
		return

	emitter_enabled = false

	if not audio_player.playing:
		return

	var tween := create_tween()

	tween.tween_property(
		audio_player,
		"volume_db",
		-40.0,
		maxf(fade_duration, 0.01)
	)

	tween.tween_callback(audio_player.stop)


func set_emitter_volume(volume_db: float) -> void:
	target_volume_db = clampf(volume_db, -40.0, 6.0)

	if audio_player != null and emitter_enabled:
		audio_player.volume_db = target_volume_db


func set_emitter_distance(distance: float) -> void:
	max_distance = maxf(distance, 1.0)

	if audio_player != null:
		audio_player.max_distance = max_distance


func set_emitter_position(
	world_position: Vector3
) -> void:
	global_position = world_position


func set_emitter_enabled(
	enabled: bool,
	fade_duration: float = 1.5
) -> void:
	if enabled:
		start_emitter(fade_duration)
	else:
		stop_emitter(fade_duration)


func play_once() -> void:
	if audio_player == null or audio_stream == null:
		return

	audio_player.play()


func is_emitter_playing() -> bool:
	if audio_player == null:
		return false

	return audio_player.playing


func _exit_tree() -> void:
	if is_instance_valid(audio_player):
		audio_player.stop()
