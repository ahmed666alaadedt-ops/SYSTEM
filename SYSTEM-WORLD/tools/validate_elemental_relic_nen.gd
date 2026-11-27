extends SceneTree

const ProgressionScript = preload("res://scripts/system_player_progression.gd")

class MockElementalBridge extends Node:
	signal marketplace_result_received(request_id: String, payload: Dictionary)
	var last_skill := ""
	var last_request_id := ""

	func request_elemental_activation(skill_id: String, request_id: String) -> bool:
		last_skill = skill_id
		last_request_id = request_id
		return true


var failures: Array[String] = []
var progression: Node
var actor: CharacterBody3D
var bridge: MockElementalBridge
var received_receipt := false
var received_skill := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_path := "user://system_player_progress.cfg"
	var had_saved_profile := FileAccess.file_exists(save_path)
	var saved_profile := FileAccess.get_file_as_bytes(save_path) if had_saved_profile else PackedByteArray()

	bridge = MockElementalBridge.new()
	bridge.name = "SYSTEMAndroidBridge"
	root.add_child(bridge)

	progression = ProgressionScript.new()
	progression.name = "PlayerProgression"
	root.add_child(progression)
	progression.elemental_activation_receipt_received.connect(_on_receipt)

	actor = CharacterBody3D.new()
	actor.name = "ElementalTestPlayer"
	root.add_child(actor)
	await physics_frame

	progression.set("nen_unlocked", false)
	progression.set("nen_control_rank", 0)
	var no_nen: Dictionary = progression.call("activate_relic_skill", "primordial_flame_burst", actor)
	_assert(str(no_nen.get("reason", "")) == "NEN_NOT_UNLOCKED", "Elemental relic passed the Nen-unlocked gate.")

	progression.set("nen_unlocked", true)
	progression.set("nen_control_rank", 1)
	var weak_nen: Dictionary = progression.call("activate_relic_skill", "primordial_flame_burst", actor)
	_assert(str(weak_nen.get("reason", "")) == "NEN_CONTROL_REQUIREMENT", "Fire relic ignored its minimum Nen control rank.")

	var skills := [
		{"id": "primordial_flame_burst", "rank": 2, "points": 850, "uses": 0},
		{"id": "stormwind_aerial_step", "rank": 2, "points": 850, "uses": 0},
		{"id": "tideheart_restoration", "rank": 3, "points": 1500, "uses": 10},
		{"id": "worldroot_earthguard", "rank": 3, "points": 1500, "uses": 10},
		{"id": "stormlightning_arc", "rank": 4, "points": 2500, "uses": 50}
	]
	for skill in skills:
		var skill_id := str(skill["id"])
		_prepare_skill(skill_id, int(skill["rank"]), int(skill["points"]), int(skill["uses"]))
		var energy_before := float(progression.get("current_system_energy"))
		var result: Dictionary = progression.call("activate_relic_skill", skill_id, actor)
		print("ELEMENTAL BRIDGE DIAGNOSTIC: node=%s has_method=%s result=%s" % [str(root.find_child("SYSTEMAndroidBridge", true, false)), str(bridge.has_method("request_elemental_activation")), str(result)])
		_assert(bool(result.get("success", false)) and bool(result.get("pending", false)), "%s did not enter server-authorized pending state." % skill_id)
		_assert(str(bridge.last_skill) == skill_id, "%s was not sent through the Android/Firebase authority bridge." % skill_id)
		_assert(not str(bridge.last_request_id).is_empty(), "%s did not receive a correlation request ID." % skill_id)
		_assert(is_equal_approx(float(progression.get("current_system_energy")), energy_before), "%s charged client-side energy before trusted combat resolution." % skill_id)
		_assert(not progression.get("system_skill_cooldowns").has(skill_id), "%s set a client-side cooldown before trusted combat resolution." % skill_id)
		_assert(not actor.has_meta("system_nen_air_dash_direction") and not actor.has_meta("system_tideheart_shield_until_msec") and not actor.has_meta("system_earthguard_until_msec"), "%s applied a local elemental combat effect before server resolution." % skill_id)

		received_receipt = false
		bridge.marketplace_result_received.emit(bridge.last_request_id, {
			"success": true,
			"data": {
				"success": true,
				"activationId": "test_activation_%s" % skill_id,
				"skillId": skill_id,
				"status": "authorized_pending_combat",
				"energyCost": 10,
				"remainingEnergy": 90,
				"cooldownSeconds": 8
			}
		})
		_assert(received_receipt and received_skill == skill_id, "%s server receipt was not correlated and delivered to gameplay." % skill_id)

	_restore_saved_profile(had_saved_profile, saved_profile)
	if failures.is_empty():
		print("SYSTEM ELEMENTAL RELIC NEN QA PASS: Nen gates, five server-authorized requests, receipt correlation and no client-side combat authority.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SYSTEM ELEMENTAL RELIC NEN QA FAIL: %d assertion(s)." % failures.size())
		quit(1)


func _on_receipt(skill_id: String, _receipt: Dictionary) -> void:
	received_receipt = true
	received_skill = skill_id


func _restore_saved_profile(had_saved_profile: bool, saved_profile: PackedByteArray) -> void:
	var save_path := "user://system_player_progress.cfg"
	if had_saved_profile:
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		if file == null:
			failures.append("Could not restore the pre-test player progression save.")
			return
		file.store_buffer(saved_profile)
		file.close()
	elif FileAccess.file_exists(save_path):
		var absolute_path := ProjectSettings.globalize_path(save_path)
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			failures.append("Could not remove the temporary elemental test progression save.")


func _prepare_skill(skill_id: String, nen_rank: int, mission_points: int, nen_uses: int) -> void:
	progression.set("current_level", 100)
	progression.set("verified_hunter_mission_points", mission_points)
	progression.set("nen_unlocked", true)
	progression.set("nen_control_rank", nen_rank)
	progression.set("nen_skill_use_count", nen_uses)
	var nen_ids: Array[String] = progression.get("nen_skill_ids")
	nen_ids.clear()
	if nen_uses >= 50:
		nen_ids.append("nen_test_ability_one")
		nen_ids.append("nen_test_ability_two")
	progression.set("nen_skill_ids", nen_ids)
	progression.set("current_system_energy", 100.0)
	var learned: Array[String] = progression.get("learned_system_skills")
	if not learned.has(skill_id):
		learned.append(skill_id)
	progression.set("learned_system_skills", learned)
	var authorized: Array[String] = progression.get("authorized_system_skills")
	if not authorized.has(skill_id):
		authorized.append(skill_id)
	progression.set("authorized_system_skills", authorized)
	var practice: Dictionary = progression.get("system_skill_practice")
	practice[skill_id] = 3
	progression.set("system_skill_practice", practice)
	var cooldowns: Dictionary = progression.get("system_skill_cooldowns")
	cooldowns.erase(skill_id)
	progression.set("system_skill_cooldowns", cooldowns)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
