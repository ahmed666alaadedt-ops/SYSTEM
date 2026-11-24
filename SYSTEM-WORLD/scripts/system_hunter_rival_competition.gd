extends Node3D
class_name SYSTEMHunterRivalCompetition

signal rival_event(message: String)

const PROFILES := [
	{"id":"rival_kai","name":"كاي","archetype":"المخادع","style":"deceiver","cunning":0.94,"combat":0.42,"stealth":0.82},
	{"id":"rival_ren","name":"رِن","archetype":"سارق الأهداف","style":"thief","cunning":0.76,"combat":0.58,"stealth":0.96},
	{"id":"rival_daigo","name":"دايغو","archetype":"المقاتل","style":"fighter","cunning":0.34,"combat":0.97,"stealth":0.25},
	{"id":"rival_mira","name":"ميرا","archetype":"نصّابة الكمائن","style":"ambusher","cunning":0.88,"combat":0.73,"stealth":0.93},
	{"id":"rival_sami","name":"سامي","archetype":"المنافس الشريف","style":"honorable","cunning":0.60,"combat":0.78,"stealth":0.45}
]
var player: CharacterBody3D
var rivals: Dictionary = {}
var player_objectives: Array[String] = []
var stolen_objective_id := ""
var stolen_by_rival_id := ""
var action_cooldown := 8.0
var elapsed := 0.0
var rng := RandomNumberGenerator.new()

func setup(active_player: CharacterBody3D, parent: Node3D) -> void:
	player = active_player
	rng.randomize()
	for i in range(PROFILES.size()):
		var profile: Dictionary = PROFILES[i].duplicate(true)
		var rival := _make_rival(profile)
		rival.position = Vector3(-13.0 + float(i) * 6.5, 0.0, 8.0 + float(i % 2) * 5.0)
		parent.add_child(rival)
		rivals[str(profile["id"])] = {"profile": profile, "node": rival}

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	elapsed += delta
	for entry_value in rivals.values():
		var entry: Dictionary = entry_value
		var rival := entry["node"] as Node3D
		if not is_instance_valid(rival):
			continue
		var style := str(entry["profile"]["style"])
		var distance := rival.global_position.distance_to(player.global_position)
		if distance > 5.0 and style in ["thief", "ambusher"]:
			var direction := player.global_position - rival.global_position
			direction.y = 0.0
			if direction.length() > 0.1:
				rival.global_position += direction.normalized() * minf(delta * 1.1, distance - 4.5)
		if distance < 6.0:
			rival.look_at(Vector3(player.global_position.x, rival.global_position.y, player.global_position.z), Vector3.UP)
	if elapsed >= action_cooldown:
		elapsed = 0.0
		_perform_action()

func _perform_action() -> void:
	var ids: Array = rivals.keys()
	if ids.is_empty():
		return
	var rival_id := str(ids[rng.randi_range(0, ids.size() - 1)])
	var entry: Dictionary = rivals[rival_id]
	var profile: Dictionary = entry["profile"]
	var style := str(profile["style"])
	if style == "thief" and not player_objectives.is_empty() and stolen_objective_id.is_empty():
		stolen_objective_id = player_objectives.pop_back()
		stolen_by_rival_id = rival_id
		var theft_message := "%s سرق هدفك! أوقف تقدّمك واستعده منه." % profile["name"]
		rival_event.emit(theft_message)
		print("SYSTEM HUNTER EXAM: ", theft_message)
		return
	var messages := {
		"deceiver": "%s يضللك بمعلومة قد تكون كاذبة." % profile["name"],
		"fighter": "%s يتحداك في مواجهة فردية." % profile["name"],
		"ambusher": "%s يختبئ ويراقب تحركاتك." % profile["name"],
		"honorable": "%s ينافسك بشرف دون سرقة أو خداع." % profile["name"]
	}
	var event_message := str(messages.get(style, "%s يراقبك." % profile["name"]))
	rival_event.emit(event_message)
	print("SYSTEM HUNTER EXAM: ", event_message)

func record_player_objective(objective_id: String) -> void:
	if not objective_id.is_empty() and not player_objectives.has(objective_id):
		player_objectives.append(objective_id)

func can_continue_objectives() -> bool:
	return stolen_objective_id.is_empty()

func handle_rival_interaction(rival_id: String) -> Dictionary:
	if not rivals.has(rival_id):
		return {"handled": false}
	var entry: Dictionary = rivals[rival_id]
	var profile: Dictionary = entry["profile"]
	if stolen_by_rival_id == rival_id and not stolen_objective_id.is_empty():
		if rng.randf() > 0.42:
			return {"handled": true, "success": false, "message": "%s يرفض إعادة الهدف. حاول مراوغته أو واجهه مرة أخرى." % profile["name"]}
		var recovered := stolen_objective_id
		player_objectives.append(recovered)
		stolen_objective_id = ""
		stolen_by_rival_id = ""
		return {"handled": true, "success": true, "recovered": true, "objective_id": recovered, "message": "استعدت هدفك من %s. لا تمنحه فرصة ثانية!" % profile["name"]}
	var style := str(profile["style"])
	if style == "fighter":
		return {"handled": true, "success": rng.randf() < 0.5, "message": "%s يتحداك في نزال فردي؛ الاختبار لا يحتوي على نزالات فرق." % profile["name"]}
	if style == "deceiver":
		return {"handled": true, "success": true, "message": "%s يعطيك معلومة تبدو مفيدة، لكن تحقق منها بنفسك." % profile["name"]}
	return {"handled": true, "success": true, "message": "%s يراقبك بحذر." % profile["name"]}

func get_competition_status() -> Dictionary:
	return {"rival_count": rivals.size(), "objective_stolen": not stolen_objective_id.is_empty(), "stolen_objective_id": stolen_objective_id, "online_multiplayer": false}

func _make_rival(profile: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "HunterRival_" + str(profile["id"])
	root.set_meta("system_exam_rival_id", str(profile["id"]))
	var body := MeshInstance3D.new()
	body.name = "RivalBody"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 1.9
	body.mesh = mesh
	body.position.y = 1.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18 + float(profile["combat"]) * 0.5, 0.2 + float(profile["stealth"]) * 0.3, 0.3 + float(profile["cunning"]) * 0.4)
	body.material_override = material
	root.add_child(body)
	var label := Label3D.new()
	label.name = "RivalNameplate"
	label.text = "%s\n%s" % [profile["name"], profile["archetype"]]
	label.font_size = 22
	label.pixel_size = 0.014
	label.position.y = 2.2
	root.add_child(label)
	var area := Area3D.new()
	area.name = "RivalInteraction"
	area.add_to_group("system_interactable")
	area.set_meta("system_exam_rival_id", str(profile["id"]))
	area.set_meta("system_display_name", str(profile["name"]))
	area.set_meta("system_interaction_prompt", "تفاعل مع " + str(profile["name"]))
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.2
	shape.shape = sphere
	area.add_child(shape)
	root.add_child(area)
	return root
