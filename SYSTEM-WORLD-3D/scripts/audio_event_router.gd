
extends Node

# SYSTEM WORLD - AUDIO EVENT ROUTER
# Godot 4.3
# Routes game events to the central AudioManager.

@export var audio_manager_path: NodePath = NodePath("/root/AudioManager")

var audio_manager: Node


func _ready() -> void:
	call_deferred("_connect_audio_manager")


func _connect_audio_manager() -> void:
	audio_manager = get_node_or_null(audio_manager_path)

	if audio_manager == null:
		push_warning("AudioEventRouter: AudioManager not found.")
		return


func _get_audio() -> Node:
	if is_instance_valid(audio_manager):
		return audio_manager

	_connect_audio_manager()
	return audio_manager


func play_event(
	sound_id: String,
	category: String = "effects",
	volume_db: float = 0.0
) -> void:
	var audio := _get_audio()

	if audio == null:
		return

	if audio.has_method("play_2d"):
		audio.play_2d(sound_id, category, volume_db)


func play_world_event(
	sound_id: String,
	world_position: Vector3,
	category: String = "effects",
	volume_db: float = 0.0
) -> void:
	var audio := _get_audio()

	if audio == null:
		return

	if audio.has_method("play_3d"):
		audio.play_3d(
			sound_id,
			world_position,
			category,
			volume_db
		)


# UI EVENTS

func button_pressed() -> void:
	play_event("button_click", "ui", -3.0)


func menu_opened() -> void:
	play_event("menu_open", "ui", -3.0)


func notification_received() -> void:
	play_event("notification", "ui", -3.0)


# WEATHER EVENTS

func weather_event(
	weather_type: String,
	intensity: float = 1.0
) -> void:
	var safe_intensity := clampf(intensity, 0.0, 1.0)
	var volume := lerpf(-18.0, 0.0, safe_intensity)

	match weather_type.to_lower():
		"rain":
			play_event("rain", "weather", volume)

		"thunder":
			play_event("thunder", "weather", volume)

		"wind":
			play_event("wind", "weather", volume)

		_:
			push_warning(
				"Unknown weather event: " + weather_type
			)


func thunder_at(position: Vector3) -> void:
	play_world_event(
		"thunder",
		position,
		"weather",
		0.0
	)


# COMBAT EVENTS

func combat_started() -> void:
	play_event("combat_start", "combat")


func heavy_hit() -> void:
	play_event("heavy_hit", "combat")


func weapon_clash() -> void:
	play_event("weapon_clash", "combat")


func special_attack() -> void:
	play_event("special_attack", "combat")


func boss_appeared() -> void:
	play_event("boss_appearance", "combat")


func combat_victory() -> void:
	play_event("victory", "combat")


func combat_defeat() -> void:
	play_event("defeat", "combat")


# CREATURE EVENTS

func monster_sound(
	sound_id: String,
	position: Vector3
) -> void:
	play_world_event(
		sound_id,
		position,
		"monsters"
	)


func animal_sound(
	sound_id: String,
	position: Vector3
) -> void:
	play_world_event(
		sound_id,
		position,
		"animals"
	)


func bird_sound(
	sound_id: String,
	position: Vector3
) -> void:
	play_world_event(
		sound_id,
		position,
		"animals",
		-4.0
	)


# CHARACTER AND NPC EVENTS

func character_voice(sound_id: String) -> void:
	play_event(sound_id, "voice")


func npc_voice(sound_id: String) -> void:
	play_event(sound_id, "npc")
