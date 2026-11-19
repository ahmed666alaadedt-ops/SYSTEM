extends SceneTree

## End-to-end smoke test for the civilian society and visible NPC layer.
## Runs against the canonical main scene so it verifies real manager wiring.

func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not be loaded")
		return

	var scene := packed.instantiate()
	if scene == null:
		_fail("MainScene.tscn could not be instantiated")
		return
	root.add_child(scene)

	for _frame in range(4):
		await process_frame

	var society := scene.get_node_or_null("AINPCSocietyManager")
	var daily_life := scene.get_node_or_null("NPCDailyLifeManager")
	var population := scene.find_child("NPCVisiblePopulationManager", true, false)
	var social := scene.find_child("NPCSocialInteractionManager", true, false)
	var navigation := scene.find_child("NPCCityNavigationManager", true, false)

	if society == null or daily_life == null:
		_fail("Society or daily-life manager was not mounted")
		return
	if population == null:
		_fail("Visible population manager was not mounted")
		return
	if social == null or navigation == null:
		_fail("Social or city navigation manager was not mounted")
		return

	var residents: Array = society.call("get_living_npcs", 2)
	if residents.size() < 18:
		_fail("Expected seeded Baghdad residents; found " + str(residents.size()))
		return

	var pedestrians: Dictionary = population.get("pedestrians")
	if pedestrians.size() < mini(18, residents.size()):
		_fail("Visible civilian actors were not created; found " + str(pedestrians.size()))
		return

	var loaded_models := 0
	var child_models := 0
	for npc_id in pedestrians.keys():
		var record: Dictionary = pedestrians[npc_id]
		var visual := record.get("visual") as Node
		if not is_instance_valid(visual):
			_fail("Visible NPC has no character visual: " + str(npc_id))
			return
		var imported := visual.get("imported_model") as Node3D
		if is_instance_valid(imported):
			loaded_models += 1
			if str(visual.get("age_group")) == "child":
				child_models += 1
				var child_model_path := str(visual.get("selected_model_path"))
				if not child_model_path.contains("SYSTEM_Humanoid_Child_"):
					_fail("Child resident loaded an incorrect GLB model: " + child_model_path)
					return

	if loaded_models < 18:
		_fail("Visible NPCs are falling back instead of loading their GLB models; loaded=" + str(loaded_models))
		return
	if child_models < 2:
		_fail("Child resident GLB models were not represented in the visible population")
		return

	var child_id := ""
	for npc in residents:
		if float(npc.get("age_years", 99.0)) < 18.0:
			child_id = str(npc.get("id", ""))
			break
	if child_id.is_empty():
		_fail("Seeded society has no child residents")
		return
	if bool(society.call("set_activity", child_id, "work")):
		_fail("A minor was incorrectly allowed to enter the work activity")

	var social_status: Dictionary = social.call("get_social_status")
	if not bool(social_status.get("active", false)):
		_fail("NPC social interaction manager is not processing")

	var navigation_status: Dictionary = navigation.call("get_navigation_status")
	if not bool(navigation_status.get("active", false)):
		_fail("NPC city navigation manager is not connected to the city region")

	print("SYSTEM NPC SOCIETY OK: residents=", residents.size(),
		" visible=", pedestrians.size(),
		" GLB_models=", loaded_models,
		" child_GLB_models=", child_models)
	print("SYSTEM NPC SOCIAL STATUS: ", social_status)
	print("SYSTEM NPC NAVIGATION STATUS: ", navigation_status)
	print("SYSTEM NPC SOCIETY RUNTIME VALIDATION PASSED")
	quit(0)


func _fail(reason: String) -> void:
	push_error("SYSTEM NPC SOCIETY RUNTIME VALIDATION FAILED: " + reason)
	quit(1)
