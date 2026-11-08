extends "res://scripts/miyar_personality_controller.gd"
class_name AdamPersonalityController

# SYSTEM WORLD - ADAM LIVING CHARACTER
# Independent male assistant.
# Godot 4.3

func say_welcome() -> void:
	say(
		"أهلاً بك. أنا آدم، سأكون دليلك ومساعدك في رحلتك داخل SYSTEM WORLD.",
		Emotion.HAPPY
	)


func say_encouragement() -> void:
	say(
		"واصل التقدم! القوة الحقيقية تظهر عندما تواجه التحديات ولا تستسلم.",
		Emotion.EXCITED
	)


func say_success() -> void:
	say(
		"إنجاز ممتاز. لقد أثبت أنك قادر على تجاوز هذا التحدي.",
		Emotion.HAPPY
	)


func say_not_finished() -> void:
	say(
		"لم تنتهِ الرحلة بعد. هناك تحديات أكبر تنتظرنا.",
		Emotion.SERIOUS
	)


func say_warning() -> void:
	say(
		"انتبه. أمامنا خطر محتمل، من الأفضل أن نستعد قبل التقدم.",
		Emotion.CONCERNED
	)


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
				"دخلنا العالم الحديث. سأساعدك في استكشاف المدن والبوابات والتحديات.",
				Emotion.EXCITED
			)

		"history":
			say(
				"مرحباً بك في العالم التاريخي. لنكتشف الحضارات ونفهم أسرارها.",
				Emotion.HAPPY
			)

		"fantasy":
			say(
				"هذا هو العالم الخيالي. كن مستعداً للممالك والسحر والمخلوقات الأسطورية.",
				Emotion.EXCITED
			)

		"greed":
			say(
				"وصلنا إلى جزيرة الطمع. لا تستهِن بأسرار هذا المكان.",
				Emotion.SERIOUS
			)


func explain_game(
	game_name: String,
	description: String,
	development: String,
	player_benefit: String
) -> void:
	var message := (
		"دعني أوضح لك نظام " + game_name + ".\n\n" +
		description + "\n\n" +
		"طريقة التطوير: " + development + "\n\n" +
		"الفائدة للاعب: " + player_benefit
	)

	say(message, Emotion.THINKING)
