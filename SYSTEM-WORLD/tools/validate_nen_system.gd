extends SceneTree

const NenManagerScript = preload("res://scripts/system_nen_manager.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = NenManagerScript.new()
	root.add_child(manager)
	manager.setup(null)
	var first := manager.register_character("validator_alpha", {"personality": "calm", "background": "scholar"})
	var second := manager.register_character("validator_beta", {"personality": "bold", "background": "fighter"})
	assert(bool(first.get("success", false)))
	assert(bool(second.get("success", false)))
	assert(str(first.profile.affinity) != str(second.profile.affinity), "Distinct profile seeds should produce individual affinities.")
	assert(not bool(manager.get_character_state("validator_alpha").discovered))
	for index in range(3):
		manager.add_discovery_insight("validator_alpha", "deep_meditation")
	var awakened: Dictionary = manager.get_character_state("validator_alpha")
	assert(bool(awakened.discovered))
	assert(bool(awakened.affinity_revealed))
	assert(not bool(manager.get_character_state("validator_beta").discovered), "One character's discovery must not awaken everyone.")
	for discipline in ["ten", "ren", "zetsu"]:
		for index in range(5 if discipline != "zetsu" else 3):
			manager.train("validator_alpha", discipline, 1)
	var technique: Dictionary = manager.create_personal_technique("validator_alpha")
	assert(bool(technique.get("success", false)))
	assert(bool(manager.get_character_state("validator_alpha").technique_unlocked))
	assert(bool(manager.get_population_discovery_summary().all_can_discover))
	print("SYSTEM NEN VALIDATION PASSED")
	quit(0)
