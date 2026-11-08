
extends Node3D
class_name MiyarPersonalityController

# SYSTEM WORLD - MIYAR LIVING CHARACTER
# Godot 4.3
# Movement, emotions, dialogue and character reactions.

signal dialogue_started(message: String)
signal dialogue_finished()
signal emotion_changed(emotion: String)
signal world_changed(world_id: String)

enum Emotion {
	NEUTRAL,
	HAPPY,
	LAUGHING,
	SHY,
	EXCITED,
	CONCERNED,
	SERIOUS,
	SURPRISED,
	THINKING
}

enum MovementState {
	IDLE,
	WALKING,
	FOLLOWING,
	PRESENTING
}

@export_group("Character Nodes")
@export var animation_player_path: NodePath
@export var voice_player_path: NodePath
@export var follow_target_path: NodePath

@export_group("Movement")
@export var movement_speed: float = 2.2
@export var rotation_speed: float = 5.0
@export var follow_distance: float = 2.0
@export var movement_enabled: bool = true

@export_group("Animation Names")
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"walk"
@export var talk_animation: StringName = &"talk"
@export var happy_animation: StringName = &"happy"
@export var laugh_animation: StringName = &"laugh"
@export var shy_animation: StringName = &"shy"
@export var concerned_animation: StringName = &"concerned"
@export var thinking_animation: StringName = &"thinking"
@export var presenting_animation: StringName = &"presenting"

var animation_player: AnimationPlayer
var voice_player: AudioStreamPlayer3D
var follow_target: Node3D

var current_emotion: Emotion = Emotion.NEUTRAL
var current_movement: MovementState = MovementState.IDLE

var current_world: String = "modern"
var current_dialogue: String = ""

var is_speaking: bool = false
var is_following: bool = false

var dialogue_queue: Array[String] = []


func _ready() -> void:
	animation_player = get_node_or_null(
		animation_player_path
	) as AnimationPlayer

	voice_player = get_node_or_null(
		voice_player_path
	) as AudioStreamPlayer3D

	follow_target = get_node_or_null(
		follow_target_path
	) as Node3D

	play_animation(idle_animation)


func _process(delta: float) -> void:
	if movement_enabled and is_following:
		_follow_player(delta)


# ==========================================
# CHARACTER MOVEMENT
# ==========================================

func start_following(target: Node3D = null) -> void:
	if target != null:
		follow_target = target

	if not is_instance_valid(follow_target):
		return

	is_following = true
	current_movement = MovementState.FOLLOWING


func stop_following() -> void:
	is_following = false
	current_movement = MovementState.IDLE

	if not is_speaking:
		play_animation(idle_animation)


func walk_to(destination: Vector3) -> void:
	is_following = false
	current_movement = MovementState.WALKING

	var distance := global_position.distance_to(destination)

	if distance <= 0.1:
		current_movement = MovementState.IDLE
		return

	play_animation(walk_animation)

	while is_inside_tree():
		var remaining := global_position.distance_to(destination)

		if remaining <= 0.12:
			break

		var delta_time := get_process_delta_time()
		var direction := global_position.direction_to(destination)

		global_position += direction * movement_speed * delta_time

		_rotate_toward(direction, delta_time)

		await get_tree().process_frame

	current_movement = MovementState.IDLE

	if not is_speaking:
		play_animation(idle_animation)


func _follow_player(delta: float) -> void:
	if not is_instance_valid(follow_target):
		stop_following()
		return

	var distance := global_position.distance_to(
		follow_target.global_position
	)

	if distance > follow_distance:
		var direction := global_position.direction_to(
			follow_target.global_position
		)

		global_position += direction * movement_speed * delta

		_rotate_toward(direction, delta)

		if not is_speaking:
			play_animation(walk_animation)
	else:
		if not is_speaking:
			play_animation(idle_animation)


func _rotate_toward(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return

	var target_angle := atan2(direction.x, direction.z)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		rotation_speed * delta
	)


func look_at_player() -> void:
	if not is_instance_valid(follow_target):
		return

	var target_position := follow_target.global_position
	target_position.y = global_position.y

	look_at(target_position, Vector3.UP)


# ==========================================
# DIALOGUE AND SPEECH
# ==========================================

func say(
	message: String,
	emotion: Emotion = Emotion.NEUTRAL,
	voice: AudioStream = null
) -> void:
	current_dialogue = message
	is_speaking = true

	set_emotion(emotion)
	dialogue_started.emit(message)

	if voice != null and is_instance_valid(voice_player):
		voice_player.stream = voice
		voice_player.play()

	_play_talking_animation()


func finish_speaking() -> void:
	is_speaking = false

	if is_instance_valid(voice_player):
		if voice_player.playing:
			voice_player.stop()

	dialogue_finished.emit()

	if current_movement == MovementState.WALKING:
		play_animation(walk_animation)
	elif current_movement == MovementState.FOLLOWING:
		play_animation(idle_animation)
	else:
		play_animation(idle_animation)


func _play_talking_animation() -> void:
	if has_animation(talk_animation):
		play_animation(talk_animation)
	else:
		play_animation(idle_animation)


func say_encouragement() -> void:
	say(
		"يلا، تگدر تكمل! لا تستسلم، أنا وياك.",
		Emotion.EXCITED
	)


func say_success() -> void:
	say(
		"أحسنت! إنجاز جديد ينضاف إلى رحلتك.",
		Emotion.HAPPY
	)


func say_not_finished() -> void:
	say(
		"لسه ما خلصنا! عدنا تحديات أقوى بانتظارك.",
		Emotion.EXCITED
	)


func say_welcome() -> void:
	say(
		"أهلاً بك! نورت SYSTEM WORLD، خلينا نبدأ رحلتنا.",
		Emotion.HAPPY
	)


func say_warning() -> void:
	say(
		"انتبه! الوضع هنا خطير، خلينا نراجع خطتنا.",
		Emotion.CONCERNED
	)


func say_thanks_for_compliment() -> void:
	say(
		"شكراً إلك... خجلتني بكلامك.",
		Emotion.SHY
	)


# ==========================================
# EMOTIONS AND EXPRESSIONS
# ==========================================

func set_emotion(emotion: Emotion) -> void:
	current_emotion = emotion

	var animation_name: StringName = idle_animation
	var emotion_name := "neutral"

	match emotion:
		Emotion.HAPPY:
			animation_name = happy_animation
			emotion_name = "happy"

		Emotion.LAUGHING:
			animation_name = laugh_animation
			emotion_name = "laughing"

		Emotion.SHY:
			animation_name = shy_animation
			emotion_name = "shy"

		Emotion.EXCITED:
			animation_name = happy_animation
			emotion_name = "excited"

		Emotion.CONCERNED:
			animation_name = concerned_animation
			emotion_name = "concerned"

		Emotion.SERIOUS:
			emotion_name = "serious"

		Emotion.SURPRISED:
			emotion_name = "surprised"

		Emotion.THINKING:
			animation_name = thinking_animation
			emotion_name = "thinking"

		Emotion.NEUTRAL:
			emotion_name = "neutral"

	emotion_changed.emit(emotion_name)

	if not is_speaking:
		play_animation(animation_name)


func laugh() -> void:
	set_emotion(Emotion.LAUGHING)


func become_shy() -> void:
	set_emotion(Emotion.SHY)


func celebrate() -> void:
	set_emotion(Emotion.HAPPY)


func become_concerned() -> void:
	set_emotion(Emotion.CONCERNED)


func think() -> void:
	set_emotion(Emotion.THINKING)


# ==========================================
# WORLD INTERACTION
# ==========================================

func enter_world(world_id: String) -> void:
	var valid_worlds := [
		"modern",
		"history",
		"fantasy",
		"greed"
	]

	if not valid_worlds.has(world_id):
		return

	current_world = world_id
	world_changed.emit(world_id)

	match world_id:
		"modern":
			say(
				"وصلنا إلى العالم الحديث. هنا تنتظرنا المدن والبوابات والتحديات.",
				Emotion.EXCITED
			)

		"history":
			say(
				"أهلاً بك في العالم التاريخي. سنكتشف الحضارات والمدن القديمة.",
				Emotion.HAPPY
			)

		"fantasy":
			say(
				"مرحباً بك في العالم الخيالي. هنا الممالك والسحر والمخلوقات الأسطورية.",
				Emotion.EXCITED
			)

		"greed":
			say(
				"وصلنا إلى جزيرة الطمع. كن مستعداً، فالأسرار والمكافآت تنتظرنا.",
				Emotion.SERIOUS
			)


func explain_game(
	game_name: String,
	description: String,
	development: String,
	player_benefit: String
) -> void:
	var message := (
		"خليني أشرح لك " + game_name + ".\n\n" +
		description + "\n\n" +
		"طريقة التطوير: " + development + "\n\n" +
		"الفائدة للاعب: " + player_benefit
	)

	say(message, Emotion.THINKING)


# ==========================================
# ANIMATION HELPERS
# ==========================================

func has_animation(animation_name: StringName) -> bool:
	if not is_instance_valid(animation_player):
		return false

	return animation_player.has_animation(animation_name)


func play_animation(animation_name: StringName) -> void:
	if not is_instance_valid(animation_player):
		return

	if animation_player.has_animation(animation_name):
		if animation_player.current_animation != animation_name:
			animation_player.play(animation_name)


func get_current_world() -> String:
	return current_world


func get_current_dialogue() -> String:
	return current_dialogue
