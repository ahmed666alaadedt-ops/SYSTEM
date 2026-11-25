extends Node3D
class_name SYSTEMHunterRivalCompetition

signal rival_event(message: String)
signal rival_defeated(rival_id: String, rival_name: String)

const RivalActorScript = preload("res://scripts/system_hunter_rival_actor.gd")

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
var player_health: Node

func setup(active_player: CharacterBody3D, parent: Node3D) -> void:
	player = active_player
	player_health = player.get_node_or_null("PlayerCombatHealth")
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
		var rival := entry["node"] as CharacterBody3D
		if not is_instance_valid(rival) or bool(entry.get("defeated", false)):
			continue
		var style := str(entry["profile"]["style"])
		var distance := rival.global_position.distance_to(player.global_position)
		if style == "ambusher" and distance < 7.0:
			entry["duel_active"] = true
			if not bool(rival.get_meta("ambush_announced", false)):
				rival.set_meta("ambush_announced", true)
				_emit_event("%s باغتتك من مخبئه! استعد للمواجهة الفردية." % entry["profile"]["name"])
		if style == "thief" and stolen_by_rival_id == str(entry["profile"]["id"]):
			var away := rival.global_position - player.global_position
			away.y = 0.0
			if away.length() > 0.1:
				rival.velocity = away.normalized() * 3.8
		elif distance > 3.0 and (style in ["ambusher", "thief"] or bool(entry.get("duel_active", false))):
			var direction := player.global_position - rival.global_position
			direction.y = 0.0
			if direction.length() > 0.1:
				rival.velocity = direction.normalized() * 2.8
		else:
			rival.velocity = Vector3.ZERO
		if distance < 1.8 and (bool(entry.get("duel_active", false)) or style == "ambusher" or stolen_by_rival_id == str(entry["profile"]["id"])):
			_attempt_rival_attack(str(entry["profile"]["id"]))
		if distance < 6.0:
			rival.look_at(Vector3(player.global_position.x, rival.global_position.y, player.global_position.z), Vector3.UP)
	if elapsed >= action_cooldown:
		elapsed = 0.0
		_perform_action()

func _physics_process(_delta: float) -> void:
	for entry_value in rivals.values():
		var rival := entry_value["node"] as CharacterBody3D
		if is_instance_valid(rival) and not bool(entry_value.get("defeated", false)):
			rival.move_and_slide()

func _attempt_rival_attack(rival_id: String) -> void:
	if not rivals.has(rival_id):
		return
	var entry: Dictionary = rivals[rival_id]
	var now := float(Time.get_ticks_msec()) / 1000.0
	if bool(entry.get("defeated", false)) or float(entry.get("next_attack", 0.0)) > now:
		return
	entry["next_attack"] = now + 1.6
	if not is_instance_valid(player_health) or not player_health.has_method("receive_damage"):
		return
	var damage := float(entry["profile"].get("damage", 8.0))
	player_health.call("receive_damage", damage, entry["node"])
	_emit_event("%s أصابك بضربة مقدارها %.0f. راقب صحتك وردّ الهجوم!" % [entry["profile"]["name"], damage])

func _emit_event(message: String) -> void:
	rival_event.emit(message)
	print("SYSTEM HUNTER EXAM: ", message)

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
		_emit_event("%s سرق هدفك وهرب به! أوقف تقدّمك واستعده منه." % profile["name"])
		return
	var messages := {
		"deceiver": "%s يضللك بمعلومة تبدو صحيحة؛ تحقق منها بنفسك." % profile["name"],
		"fighter": "%s يتحداك في مواجهة فردية." % profile["name"],
		"ambusher": "%s يختبئ ويراقب تحركاتك." % profile["name"],
		"honorable": "%s ينافسك بشرف ويحاول الوصول للهدف قبلك." % profile["name"]
	}
	_emit_event(str(messages.get(style, "%s يراقبك." % profile["name"])))

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
	if bool(entry.get("defeated", false)) and stolen_by_rival_id == rival_id and not stolen_objective_id.is_empty():
		return _recover_stolen_objective(rival_id, profile)
	if stolen_by_rival_id == rival_id and not stolen_objective_id.is_empty():
		if rng.randf() > 0.42:
			return {"handled": true, "success": false, "message": "%s يرفض إعادة الهدف. حاول مراوغته أو واجهه مرة أخرى." % profile["name"]}
		return _recover_stolen_objective(rival_id, profile)
	var style := str(profile["style"])
	if style == "fighter":
		entry["duel_active"] = true
		_emit_event("بدأ النزال الفردي مع %s. اهزم منافسك دون مساعدة فريق." % profile["name"])
		return {"handled": true, "success": true, "duel_started": true, "message": "بدأ النزال الفردي مع %s. تفادَ ضرباته واهزمه." % profile["name"]}
	if style == "deceiver":
		return {"handled": true, "success": true, "message": "%s يعطيك معلومة تبدو مفيدة، لكنها خدعة محتملة. تحقق منها بنفسك." % profile["name"]}
	if style == "ambusher":
		entry["duel_active"] = true
		return {"handled": true, "success": true, "duel_started": true, "message": "%s كشف كمينه وبدأ بمطاردتك. استعد للقتال أو ابتعد." % profile["name"]}
	return {"handled": true, "success": true, "message": "%s ينافسك بشرف ويحاول الوصول للأهداف قبلك." % profile["name"]}

func _recover_stolen_objective(rival_id: String, profile: Dictionary) -> Dictionary:
	var recovered := stolen_objective_id
	player_objectives.append(recovered)
	stolen_objective_id = ""
	stolen_by_rival_id = ""
	_emit_event("استعدت هدفك من %s. يمكنك متابعة المسابقة." % profile["name"])
	return {"handled": true, "success": true, "recovered": true, "objective_id": recovered, "message": "استعدت هدفك من %s وعاد مسار المسابقة للعمل." % profile["name"]}

func _on_rival_damaged(rival_id: String, amount: float, _source: Node) -> void:
	if not rivals.has(rival_id):
		return
	var entry: Dictionary = rivals[rival_id]
	if bool(entry.get("defeated", false)):
		return
	var profile: Dictionary = entry["profile"]
	var rival := entry["node"] as Node3D
	var remaining := float(rival.get_meta("rival_health", 0.0))
	_emit_event("%s تلقى ضربة %.0f. صحته المتبقية %.0f." % [profile["name"], amount, remaining])
	if remaining <= 0.0:
		entry["defeated"] = true
		entry["duel_active"] = false
		rival.velocity = Vector3.ZERO
		rival.set_physics_process(false)
		var interaction := rival.get_node_or_null("RivalInteraction") as Area3D
		if interaction != null:
			# A defeated thief must remain interactable so the stolen objective can be recovered.
			interaction.monitoring = stolen_by_rival_id == rival_id and not stolen_objective_id.is_empty()
		_emit_event("هزمت %s في مواجهة فردية وأُخرج من المنافسة." % profile["name"])
		rival_defeated.emit(rival_id, str(profile["name"]))
	else:
		entry["duel_active"] = true

func get_competition_status() -> Dictionary:
	var defeated_count := 0
	for entry_value in rivals.values():
		if bool(entry_value.get("defeated", false)):
			defeated_count += 1
	return {"rival_count": rivals.size(), "defeated_count": defeated_count, "objective_stolen": not stolen_objective_id.is_empty(), "stolen_objective_id": stolen_objective_id, "online_multiplayer": false}

func _make_rival(profile: Dictionary) -> CharacterBody3D:
	var root := RivalActorScript.new() as CharacterBody3D
	root.call("configure", profile, self)
	var body_collision := CollisionShape3D.new()
	body_collision.name = "BodyCollision"
	var body_capsule := CapsuleShape3D.new()
	body_capsule.radius = 0.48
	body_capsule.height = 1.9
	body_collision.shape = body_capsule
	root.add_child(body_collision)
	root.name = "HunterRival_" + str(profile["id"])
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
