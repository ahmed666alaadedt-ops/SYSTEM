extends Node
class_name ModernWorldAmbienceManager

## أصوات بيئية إجرائية مؤقتة: رياح ناعمة وزقزقة طيور.
## يمكن لاحقاً استبدالها بتسجيلات صوتية احترافية دون تغيير واجهة المدير.

const SAMPLE_RATE := 22050
const LOOP_SECONDS := 8.0

var wind_player: AudioStreamPlayer
var birds_player: AudioStreamPlayer
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "ModernWorldAmbienceManager"
	rng.seed = 20261118
	_create_players()


func _create_players() -> void:
	wind_player = AudioStreamPlayer.new()
	wind_player.name = "ProceduralWindAudio"
	wind_player.volume_db = -24.0
	wind_player.stream = _build_wind_stream()
	add_child(wind_player)
	wind_player.play()

	birds_player = AudioStreamPlayer.new()
	birds_player.name = "ProceduralBirdsongAudio"
	birds_player.volume_db = -20.0
	birds_player.stream = _build_bird_stream()
	add_child(birds_player)
	birds_player.play()


func _make_stream(samples: PackedByteArray, sample_count: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = samples
	return stream


func _encode_samples(values: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(values.size() * 2)
	for index in range(values.size()):
		var sample := int(clampf(values[index], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(index * 2, sample)
	return bytes


func _build_wind_stream() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * LOOP_SECONDS)
	var values := PackedFloat32Array()
	values.resize(count)
	var filtered_noise := 0.0
	for index in range(count):
		filtered_noise = lerpf(filtered_noise, rng.randf_range(-1.0, 1.0), 0.018)
		var slow_breath := 0.72 + 0.28 * sin(TAU * float(index) / float(count))
		var fade := minf(1.0, minf(float(index) / 1800.0, float(count - index - 1) / 1800.0))
		values[index] = filtered_noise * 0.075 * slow_breath * maxf(fade, 0.0)
	return _make_stream(_encode_samples(values), count)


func _build_bird_stream() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * LOOP_SECONDS)
	var values := PackedFloat32Array()
	values.resize(count)
	for index in range(count):
		var time := float(index) / float(SAMPLE_RATE)
		var chirp := 0.0
		for bird_index in range(5):
			var start := 0.55 + float(bird_index) * 1.37
			var local_time := time - start
			if local_time >= 0.0 and local_time < 0.24:
				var envelope := sin(PI * local_time / 0.24)
				var frequency := 1850.0 + float(bird_index % 3) * 430.0 + 620.0 * sin(local_time * 18.0)
				chirp += sin(TAU * frequency * local_time) * envelope * 0.11
		var second_call := time - 4.2
		if second_call >= 0.0 and second_call < 0.18:
			var envelope := sin(PI * second_call / 0.18)
			chirp += sin(TAU * (2650.0 - second_call * 900.0) * second_call) * envelope * 0.075
		var fade := minf(1.0, minf(float(index) / 1800.0, float(count - index - 1) / 1800.0))
		values[index] = chirp * maxf(fade, 0.0)
	return _make_stream(_encode_samples(values), count)


## تحكم عام بمستوى أصوات الطبيعة حسب المنطقة أو حالة اللعب.
func set_ambience_enabled(enabled: bool) -> void:
	if wind_player != null:
		wind_player.stream_paused = not enabled
	if birds_player != null:
		birds_player.stream_paused = not enabled


func set_ambience_volume(wind_db: float, birds_db: float) -> void:
	if wind_player != null:
		wind_player.volume_db = clampf(wind_db, -60.0, 0.0)
	if birds_player != null:
		birds_player.volume_db = clampf(birds_db, -60.0, 0.0)
