
extends Node

# SYSTEM WORLD - CENTRAL AUDIO MANAGER
# Godot 4.3
# Music / Combat / Animals / Birds / Monsters / NPC Voices
# Environment / Weather / City / Nature / UI

const MAX_3D_DISTANCE := 70.0
const DEFAULT_FADE := 1.2

var music_player: AudioStreamPlayer
var combat_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer

var active_players: Array[Node] = []
var current_music_path := ""
var current_ambience_path := ""
var combat_intensity := 0.0

var category_buses := {
	"music": "Music",
	"combat": "Music",
	"effects": "SFX",
	"animals": "SFX",
	"monsters": "SFX",
	"voice": "Voice",
	"npc": "Voice",
	"ambient": "Ambient",
	"weather": "Ambient",
	"ui": "UI"
}

var sound_library := {
	# Environment
	"city_day": "res://assets/audio/ambient/city_day.ogg",
	"city_night": "res://assets/audio/ambient/city_night.ogg",
	"forest": "res://assets/audio/ambient/forest.ogg",
	"desert": "res://assets/audio/ambient/desert.ogg",
	"beach": "res://assets/audio/ambient/beach.ogg",
	"river": "res://assets/audio/ambient/river.ogg",
	"rain": "res://assets/audio/weather/rain.ogg",
	"thunder": "res://assets/audio/weather/thunder.ogg",
	"wind": "res://assets/audio/weather/wind.ogg",

	# Birds
	"bird_small": "res://assets/audio/animals/birds/bird_small.ogg",
	"crow": "res://assets/audio/animals/birds/crow.ogg",
	"eagle": "res://assets/audio/animals/birds/eagle.ogg",
	"pigeon": "res://assets/audio/animals/birds/pigeon.ogg",
	"seagull": "res://assets/audio/animals/birds/seagull.ogg",

	# Animals
	"dog": "res://assets/audio/animals/dog.ogg",
	"cat": "res://assets/audio/animals/cat.ogg",
	"horse": "res://assets/audio/animals/horse.ogg",
	"cow": "res://assets/audio/animals/cow.ogg",
	"sheep": "res://assets/audio/animals/sheep.ogg",
	"wolf": "res://assets/audio/animals/wolf.ogg",
	"lion": "res://assets/audio/animals/lion.ogg",

	# Monsters
	"monster_roar": "res://assets/audio/monsters/roar.ogg",
	"monster_attack": "res://assets/audio/monsters/attack.ogg",
	"monster_hurt": "res://assets/audio/monsters/hurt.ogg",
	"monster_death": "res://assets/audio/monsters/death.ogg",

	# Combat
	"combat_start": "res://assets/audio/combat/combat_start.ogg",
	"heavy_hit": "res://assets/audio/combat/heavy_hit.ogg",
	"weapon_clash": "res://assets/audio/combat/weapon_clash.ogg",
	"special_attack": "res://assets/audio/combat/special_attack.ogg",
	"boss_appearance": "res://assets/audio/combat/boss_appearance.ogg",
	"victory": "res://assets/audio/combat/victory.ogg",
	"defeat": "res://assets/audio/combat/defeat.ogg",

	# Character and NPC
	"character_breath": "res://assets/audio/voices/character_breath.ogg",
	"character_pain": "res://assets/audio/voices/character_pain.ogg",
	"npc_greeting": "res://assets/audio/voices/npc_greeting.ogg",
	"npc_talking": "res://assets/audio/voices/npc_talking.ogg",

	# Interface
	"button_click": "res://assets/audio/ui/button_click.ogg",
	"menu_open": "res://assets/audio/ui/menu_open.ogg",
	"notification": "res://assets/audio/ui/notification.ogg"
}


func _ready() -> void:
	_create_audio_buses()
	_create_main_players()


func _create_audio_buses() -> void:
	var required_buses := [
		"Music",
		"SFX",
		"Voice",
		"Ambient",
		"UI"
	]

	for bus_name in required_buses:
		var bus_index := AudioServer.get_bus_index(bus_name)

		if bus_index == -1:
			AudioServer.add_bus()
			bus_index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(bus_index, bus_name)


func _create_main_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "WorldMusic"
	music_player.bus = "Music"
	add_child(music_player)

	combat_player = AudioStreamPlayer.new()
	combat_player.name = "CombatMusic"
	combat_player.bus = "Music"
	add_child(combat_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "WorldAmbience"
	ambience_player.bus = "Ambient"
	add_child(ambience_player)


func _get_stream(sound_id: String) -> AudioStream:
	if not sound_library.has(sound_id):
		push_warning("Unknown sound: " + sound_id)
		return null

	var path: String = sound_library[sound_id]

	if not ResourceLoader.exists(path):
		push_warning("Audio file not found: " + path)
		return null

	var resource = load(path)

	if resource is AudioStream:
		return resource

	return null


func play_2d(
	sound_id: String,
	category: String = "effects",
	volume_db: float = 0.0
) -> void:
	var stream := _get_stream(sound_id)

	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = category_buses.get(category, "SFX")

	add_child(player)
	active_players.append(player)

	player.finished.connect(
		_remove_player.bind(player)
	)

	player.play()


func play_3d(
	sound_id: String,
	position: Vector3,
	category: String = "effects",
	volume_db: float = 0.0,
	max_distance: float = MAX_3D_DISTANCE
) -> void:
	var stream := _get_stream(sound_id)

	if stream == null:
		return

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.position = position
	player.volume_db = volume_db
	player.max_distance = max_distance
	player.unit_size = 8.0
	player.bus = category_buses.get(category, "SFX")

	add_child(player)
	active_players.append(player)

	player.finished.connect(
		_remove_player.bind(player)
	)

	player.play()


func _remove_player(player: Node) -> void:
	active_players.erase(player)

	if is_instance_valid(player):
		player.queue_free()


func play_music(
	sound_id: String,
	fade_duration: float = DEFAULT_FADE
) -> void:
	if current_music_path == sound_id and music_player.playing:
		return

	var stream := _get_stream(sound_id)

	if stream == null:
		return

	current_music_path = sound_id

	var tween := create_tween()
	tween.tween_property(
		music_player,
		"volume_db",
		-35.0,
		fade_duration
	)

	tween.tween_callback(
		func():
			music_player.stream = stream
			music_player.volume_db = 0.0
			music_player.play()
	)


func stop_music(fade_duration: float = DEFAULT_FADE) -> void:
	var tween := create_tween()

	tween.tween_property(
		music_player,
		"volume_db",
		-40.0,
		fade_duration
	)

	tween.tween_callback(
		music_player.stop
	)

	current_music_path = ""


func set_ambience(
	sound_id: String,
	fade_duration: float = DEFAULT_FADE
) -> void:
	if current_ambience_path == sound_id and ambience_player.playing:
		return

	var stream := _get_stream(sound_id)

	if stream == null:
		return

	current_ambience_path = sound_id

	var tween := create_tween()

	tween.tween_property(
		ambience_player,
		"volume_db",
		-35.0,
		fade_duration
	)

	tween.tween_callback(
		func():
			ambience_player.stream = stream
			ambience_player.volume_db = -5.0
			ambience_player.play()
	)


func start_combat(sound_id: String = "combat_start") -> void:
	play_2d(sound_id, "combat", 0.0)


func play_animal(
	animal_sound: String,
	position: Vector3
) -> void:
	play_3d(animal_sound, position, "animals")


func play_bird(
	bird_sound: String,
	position: Vector3
) -> void:
	play_3d(bird_sound, position, "animals", -4.0)


func play_monster(
	monster_sound: String,
	position: Vector3
) -> void:
	play_3d(monster_sound, position, "monsters", 0.0)


func play_character_voice(sound_id: String) -> void:
	play_2d(sound_id, "voice")


func play_npc_voice(sound_id: String) -> void:
	play_2d(sound_id, "npc")


func play_ui(sound_id: String) -> void:
	play_2d(sound_id, "ui", -3.0)


func set_combat_intensity(value: float) -> void:
	combat_intensity = clampf(value, 0.0, 1.0)

	if combat_player.playing:
		combat_player.volume_db = lerpf(
			-18.0,
			0.0,
			combat_intensity
		)


func set_category_volume(
	category: String,
	volume_linear: float
) -> void:
	var bus_name: String = category_buses.get(
		category,
		"SFX"
	)

	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	var safe_volume := clampf(volume_linear, 0.0, 1.0)

	AudioServer.set_bus_volume_linear(
		bus_index,
		safe_volume
	)


func stop_all_effects() -> void:
	for player in active_players.duplicate():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()

	active_players.clear()
