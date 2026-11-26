extends SceneTree

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var packed := load("res://scenes/NPCCharacterShowcase.tscn") as PackedScene
	if packed == null:
		_fail("NPC showcase scene could not be loaded")
		return
	var scene := packed.instantiate()
	if scene == null:
		_fail("NPC showcase scene could not be instantiated")
		return
	root.add_child(scene)
	for _frame in range(5):
		await process_frame

	var characters: Array = scene.get("characters")
	if characters.size() != 12:
		_fail("Expected 12 showcase characters; found " + str(characters.size()))
		return

	var model_paths: Dictionary = {}
	var world_ids: Dictionary = {}
	var imported_count := 0
	for character in characters:
		if not is_instance_valid(character):
			_fail("Showcase contains an invalid character node")
			return
		var imported := character.get("imported_model") as Node3D
		if not is_instance_valid(imported):
			_fail("A showcase character failed to load its rigged GLB: " + str(character.name))
			return
		imported_count += 1
		var model_path := str(character.get("selected_model_path"))
		model_paths[model_path] = true
		var profile: Dictionary = character.get("appearance_profile")
		world_ids[str(profile.get("world_id", ""))] = true
		var animation_player := character.get("animation_player") as AnimationPlayer
		if not is_instance_valid(animation_player):
			_fail("A showcase GLB has no AnimationPlayer: " + str(character.name))
			return
		var clips := animation_player.get_animation_list()
		var has_idle := false
		var has_walk := false
		for clip in clips:
			has_idle = has_idle or str(clip).to_lower() == "idle_breathing"
			has_walk = has_walk or str(clip).to_lower() == "walk_cycle"
		if not has_idle or not has_walk:
			_fail("A showcase GLB is missing idle or walk animation: " + model_path)
			return
		character.call("set_activity", "walk")
		character.call("set_activity", "idle")

	if imported_count != 12:
		_fail("Not all 12 imported models loaded")
		return
	if model_paths.size() != 6:
		_fail("Expected all six age/gender GLB variants; found " + str(model_paths.size()))
		return
	if world_ids.size() != 4:
		_fail("Expected NPC outfits for all four worlds; found " + str(world_ids.keys()))
		return

	print("SYSTEM NPC SHOWCASE PASS: imported=", imported_count,
		" base_variants=", model_paths.size(),
		" worlds=", world_ids.size())
	print("SYSTEM NPC SHOWCASE VALIDATION PASSED")
	quit(0)

func _fail(reason: String) -> void:
	push_error("SYSTEM NPC SHOWCASE VALIDATION FAILED: " + reason)
	quit(1)
