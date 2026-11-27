extends SceneTree

const ProgressionScript = preload("res://scripts/system_player_progression.gd")
const PlayerHealthScript = preload("res://scripts/system_player_combat_health.gd")
const CombatScript = preload("res://scripts/modern_world_combat_system.gd")
const CombatantScript = preload("res://scripts/system_combatant.gd")

var failures: Array[String] = []
var progression: Node
var actor: CharacterBody3D
var health: Node
var combat: Node
var target: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_path := "user://system_player_progress.cfg"
	var had_saved_profile := FileAccess.file_exists(save_path)
	var saved_profile := FileAccess.get_file_as_bytes(save_path) if had_saved_profile else PackedByteArray()
	progression = ProgressionScript.new()
	progression.name = "PlayerProgression"
	root.add_child(progression)

	actor = CharacterBody3D.new()
	actor.name = "ElementalTestPlayer"
	root.add_child(actor)
	health = PlayerHealthScript.new()
	health.name = "PlayerCombatHealth"
	actor.add_child(health)
	health.call("bind_player", actor)

	combat = CombatScript.new()
	combat.name = "ModernWorldCombatSystem"
	root.add_child(combat)
	combat.call("bind_actor", actor, null, progression)

	target = CombatantScript.new()
	target.name = "ElementalTestTarget"
	target.position = Vector3(0.0, 1.35, -8.0)
	root.add_child(target)
	await physics_frame

	progression.set("nen_unlocked", false)
	progression.set("nen_control_rank", 0)
	var no_nen: Dictionary = progression.call("activate_relic_skill", "primordial_flame_burst", actor)
	_assert(str(no_nen.get("reason", "")) == "NEN_NOT_UNLOCKED", "Elemental relic activated without Nen.")

	progression.set("nen_unlocked", true)
	progression.set("nen_control_rank", 1)
	var weak_nen: Dictionary = progression.call("activate_relic_skill", "primordial_flame_burst", actor)
	_assert(str(weak_nen.get("reason", "")) == "NEN_CONTROL_REQUIREMENT", "Fire relic ignored its minimum Nen control rank.")

	_prepare_skill("primordial_flame_burst", 2, 850, 0)
	var fire: Dictionary = progression.call("activate_relic_skill", "primordial_flame_burst", actor)
	_assert(bool(fire.get("success", false)), "Fire relic did not apply its hitscan effect.")
	_assert(is_equal_approx(float(target.get("current_health")), 74.0), "Fire damage did not reach the existing combatant health API.")

	_prepare_skill("stormwind_aerial_step", 2, 850, 0)
	actor.velocity = Vector3.ZERO
	var air: Dictionary = progression.call("activate_relic_skill", "stormwind_aerial_step", actor)
	_assert(bool(air.get("success", false)), "Air relic did not apply its movement impulse.")
	_assert(actor.velocity.y >= 5.5 and actor.has_meta("system_nen_air_dash_direction") and int(actor.get_meta("system_nen_air_dash_until_msec", 0)) > Time.get_ticks_msec(), "Air relic dash request was not handed to the player movement controller.")

	_prepare_skill("tideheart_restoration", 3, 1500, 10)
	health.set("current_health", 50.0)
	var water: Dictionary = progression.call("activate_relic_skill", "tideheart_restoration", actor)
	_assert(bool(water.get("success", false)), "Water relic did not use the player healing API.")
	_assert(is_equal_approx(float(health.get("current_health")), 72.0), "Water relic did not restore the expected capped field health.")
	_assert(int(actor.get_meta("system_tideheart_shield_until_msec", 0)) > Time.get_ticks_msec(), "Water relic did not create its temporary defensive shield.")
	var water_shield_damage: float = health.call("receive_damage", 10.0, target)
	_assert(water_shield_damage < 10.0, "Water relic shield did not reduce incoming damage.")

	_prepare_skill("worldroot_earthguard", 3, 1500, 10)
	health.set("current_health", 100.0)
	var earth: Dictionary = progression.call("activate_relic_skill", "worldroot_earthguard", actor)
	_assert(bool(earth.get("success", false)), "Earth relic did not activate its guard.")
	var mitigated: float = health.call("receive_damage", 20.0, target)
	_assert(is_equal_approx(mitigated, 7.4), "Earth guard did not stack correctly with the active water shield and Nen defense bonus.")

	_prepare_skill("stormlightning_arc", 4, 2500, 50)
	var lightning: Dictionary = progression.call("activate_relic_skill", "stormlightning_arc", actor)
	_assert(bool(lightning.get("success", false)), "Lightning relic did not apply its hitscan effect.")
	_assert(is_equal_approx(float(target.get("current_health")), 42.0), "Lightning damage did not reach the existing combatant health API.")

	_restore_saved_profile(had_saved_profile, saved_profile)
	if failures.is_empty():
		print("SYSTEM ELEMENTAL RELIC NEN QA PASS: five elements, Nen gates, combat, movement, healing and guard.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SYSTEM ELEMENTAL RELIC NEN QA FAIL: %d assertion(s)." % failures.size())
		quit(1)


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
