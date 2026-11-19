extends SceneTree

## Headless runtime smoke test: verifies the player scene actually mounts
## both GLB companions and that their rigged animation clips are imported.

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

	await process_frame
	await process_frame

	var manager := scene.get_node_or_null("SYSTEMCompanionManager")
	if manager == null:
		_fail("SYSTEMCompanionManager was not mounted by main.gd")
		return

	for companion_id in ["miyar", "adam"]:
		var companion := manager.get(companion_id) as Node3D
		if companion == null or not is_instance_valid(companion):
			_fail(companion_id + " companion node is missing")
			return
		var model := companion.get("imported_model") as Node3D
		if model == null or not is_instance_valid(model):
			_fail(companion_id + " did not load a rigged GLB model")
			return
		var animation_player := companion.get("animation_player") as AnimationPlayer
		if animation_player == null:
			_fail(companion_id + " GLB has no AnimationPlayer")
			return
		var clips := animation_player.get_animation_list()
		for required_clip in ["Idle_Breathing", "Walk_Cycle", "Run_Cycle"]:
			var found := false
			for clip in clips:
				if required_clip.to_lower() in str(clip).to_lower():
					found = true
					break
			if not found:
				_fail(companion_id + " is missing animation clip: " + required_clip)
				return
		print("SYSTEM COMPANION OK: ", companion_id, " | clips=", clips)

	print("SYSTEM COMPANION RUNTIME VALIDATION PASSED")
	quit(0)


func _fail(reason: String) -> void:
	push_error("SYSTEM COMPANION RUNTIME VALIDATION FAILED: " + reason)
	quit(1)
