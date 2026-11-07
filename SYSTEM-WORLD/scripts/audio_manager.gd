extends Node

# SYSTEM WORLD AUDIO MANAGER
# Central audio controller for Godot 4.

signal audio_event_played(event_id: String)
signal world_audio_changed(world_id: String)

const SAMPLE_RATE := 22050
const EFFECT_POOL_SIZE := 8

const WORLD_AMBIENCE := {
    "modern": "res://audio/worlds/modern/ambience.ogg",
    "historical": "res://audio/worlds/historical/ambience.ogg",
    "fantasy": "res://audio/worlds/fantasy/ambience.ogg",
    "greed_island": "res://audio/worlds/greed_island/ambience.ogg"
}

const EVENT_SOUNDS := {
    "gate_open": "res://audio/effects/gate_open.ogg",
    "gate_close": "res://audio/effects/gate_close.ogg",
    "mission_complete": "res://audio/missions/mission_complete.ogg",
    "mission_failed": "res://audio/missions/mission_failed.ogg",
    "treasure_found": "res://audio/missions/treasure_found.ogg",
    "level_up": "res://audio/ui/level_up.ogg",
    "sword_attack": "res://audio/combat/sword_attack.ogg",
    "sword_clash": "res://audio/combat/sword_clash.ogg",
    "monster_roar": "res://audio/creatures/monster_roar.ogg",
    "dragon_roar": "res://audio/creatures/dragon_roar.ogg"
}

const AUDIO_BUSES := [
    "Music",
    "Environment",
    "Effects",
    "Combat",
    "Dialogue",
    "Voice",
    "UI"
]

var music_player: AudioStreamPlayer
var environment_player: AudioStreamPlayer
var dialogue_player: AudioStreamPlayer

var effect_players: Array[AudioStreamPlayer] = []
var next_effect_player := 0

var active_world := ""


func _ready() -> void:
    _setup_audio_buses()
    _create_audio_players()

    print("SYSTEM AUDIO: Audio manager initialized.")


# --------------------------------------------------
# AUDIO BUS FOUNDATION
# --------------------------------------------------

func _setup_audio_buses() -> void:
    for bus_name in AUDIO_BUSES:
        var bus_index := AudioServer.get_bus_index(bus_name)

        if bus_index == -1:
            AudioServer.add_bus(-1)
            bus_index = AudioServer.get_bus_count() - 1
            AudioServer.set_bus_name(bus_index, bus_name)

        AudioServer.set_bus_send(bus_index, "Master")


func set_category_volume(
    category: String,
    volume: float
) -> bool:
    var bus_index := AudioServer.get_bus_index(category)

    if bus_index == -1:
        return false

    var safe_volume := clampf(volume, 0.0, 1.0)

    if safe_volume <= 0.001:
        AudioServer.set_bus_volume_db(bus_index, -80.0)
    else:
        AudioServer.set_bus_volume_db(
            bus_index,
            linear_to_db(safe_volume)
        )

    return true


func mute_category(
    category: String,
    muted: bool
) -> bool:
    var bus_index := AudioServer.get_bus_index(category)

    if bus_index == -1:
        return false

    AudioServer.set_bus_mute(bus_index, muted)
    return true


# --------------------------------------------------
# AUDIO PLAYERS
# --------------------------------------------------

func _create_audio_players() -> void:
    music_player = _create_player(
        "MusicPlayer",
        "Music"
    )

    environment_player = _create_player(
        "EnvironmentPlayer",
        "Environment"
    )

    dialogue_player = _create_player(
        "DialoguePlayer",
        "Dialogue"
    )

    for index in range(EFFECT_POOL_SIZE):
        var player := _create_player(
            "EffectPlayer_%d" % index,
            "Effects"
        )

        effect_players.append(player)


func _create_player(
    player_name: String,
    bus_name: String
) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()

    player.name = player_name
    player.bus = bus_name

    add_child(player)

    return player


# --------------------------------------------------
# UI SOUND EFFECTS
# --------------------------------------------------

func play_ui_cue(cue: String) -> void:
    var frequencies: Array = []

    match cue:
        "tap":
            frequencies = [620.0]

        "confirm":
            frequencies = [520.0, 780.0]

        "back":
            frequencies = [420.0]

        "error":
            frequencies = [180.0, 140.0]

        "reward":
            frequencies = [520.0, 660.0, 880.0]

        "world_select":
            frequencies = [330.0, 495.0, 660.0]

        _:
            push_warning(
                "SYSTEM AUDIO: Unknown UI cue: " + cue
            )
            return

    var stream := _generate_tone(
        frequencies,
        0.16
    )

    _play_on_effect_bus(stream)

    audio_event_played.emit("ui_" + cue)


func _generate_tone(
    frequencies: Array,
    duration: float
) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()

    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false

    var sample_count := int(SAMPLE_RATE * duration)
    var bytes := PackedByteArray()

    for index in range(sample_count):
        var time := float(index) / SAMPLE_RATE
        var progress := float(index) / sample_count

        var envelope := pow(1.0 - progress, 2.0)
        var sample_value := 0.0

        for frequency in frequencies:
            sample_value += sin(
                TAU * float(frequency) * time
            )

        sample_value /= maxf(
            1.0,
            float(frequencies.size())
        )

        sample_value *= envelope * 0.30

        var sample_int := int(
            clampf(sample_value, -1.0, 1.0) * 32767.0
        )

        bytes.append(sample_int & 0xff)
        bytes.append((sample_int >> 8) & 0xff)

    stream.data = bytes

    return stream


func _play_on_effect_bus(
    stream: AudioStream
) -> void:
    if effect_players.is_empty():
        return

    var player := effect_players[next_effect_player]

    next_effect_player = (
        next_effect_player + 1
    ) % effect_players.size()

    player.stream = stream
    player.play()


# --------------------------------------------------
# WORLD AMBIENCE
# --------------------------------------------------

func play_world_ambience(world_id: String) -> bool:
    if not WORLD_AMBIENCE.has(world_id):
        push_warning(
            "SYSTEM AUDIO: Unknown world: " + world_id
        )
        return false

    var audio_path: String = WORLD_AMBIENCE[world_id]

    if not ResourceLoader.exists(audio_path):
        push_warning(
            "SYSTEM AUDIO: Ambience asset not installed: "
            + audio_path
        )
        return false

    var stream := load(audio_path) as AudioStream

    if stream == null:
        return false

    environment_player.stop()
    environment_player.stream = stream
    environment_player.play()

    active_world = world_id

    world_audio_changed.emit(world_id)

    return true


func stop_world_ambience() -> void:
    if environment_player != null:
        environment_player.stop()

    active_world = ""


# --------------------------------------------------
# MUSIC
# --------------------------------------------------

func play_music(audio_path: String) -> bool:
    if not ResourceLoader.exists(audio_path):
        push_warning(
            "SYSTEM AUDIO: Music file not found: "
            + audio_path
        )
        return false

    var stream := load(audio_path) as AudioStream

    if stream == null:
        return false

    music_player.stop()
    music_player.stream = stream
    music_player.play()

    return true


func stop_music() -> void:
    if music_player != null:
        music_player.stop()


# --------------------------------------------------
# GAMEPLAY SOUND EVENTS
# --------------------------------------------------

func play_event(event_id: String) -> bool:
    if not EVENT_SOUNDS.has(event_id):
        push_warning(
            "SYSTEM AUDIO: Unknown event: " + event_id
        )
        return false

    var audio_path: String = EVENT_SOUNDS[event_id]

    if not ResourceLoader.exists(audio_path):
        push_warning(
            "SYSTEM AUDIO: Sound asset not installed: "
            + audio_path
        )
        return false

    var stream := load(audio_path) as AudioStream

    if stream == null:
        return false

    _play_on_effect_bus(stream)

    audio_event_played.emit(event_id)

    return true


# --------------------------------------------------
# DIALOGUE
# --------------------------------------------------

func play_dialogue(audio_path: String) -> bool:
    if not ResourceLoader.exists(audio_path):
        return false

    var stream := load(audio_path) as AudioStream

    if stream == null:
        return false

    dialogue_player.stop()
    dialogue_player.stream = stream
    dialogue_player.play()

    return true


func stop_dialogue() -> void:
    if dialogue_player != null:
        dialogue_player.stop()


# --------------------------------------------------
# GLOBAL CONTROL
# --------------------------------------------------

func stop_all_audio() -> void:
    if music_player != null:
        music_player.stop()

    if environment_player != null:
        environment_player.stop()

    if dialogue_player != null:
        dialogue_player.stop()

    for player in effect_players:
        player.stop()


func get_audio_status() -> Dictionary:
    return {
        "initialized": is_inside_tree(),
        "active_world": active_world,
        "music_playing": (
            music_player.playing
            if music_player != null
            else false
        ),
        "environment_playing": (
            environment_player.playing
            if environment_player != null
            else false
        ),
        "dialogue_playing": (
            dialogue_player.playing
            if dialogue_player != null
            else false
        )
    }
