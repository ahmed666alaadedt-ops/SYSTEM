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
		print("SYSTEM COMPANION CLIPS [", companion_id, "]: ", clips)
		for required_clip in ["Idle_Breathing", "Walk", "Run"]:
			if not clips.has(required_clip):
				_fail(companion_id + " is missing imported animation clip: " + required_clip)
				return
		companion.call("set_activity", "idle")
		if animation_player.current_animation != "Idle_Breathing":
			_fail(companion_id + " idle activity did not select Idle_Breathing")
			return
		companion.call("set_activity", "walk")
		if animation_player.current_animation != "Walk":
			_fail(companion_id + " walk activity did not select Walk")
			return
		companion.call("set_activity", "run")
		if animation_player.current_animation != "Run":
			_fail(companion_id + " run activity did not select Run")
			return
		print("SYSTEM COMPANION OK: ", companion_id, " | clips=", clips)

	print("SYSTEM COMPANION RUNTIME VALIDATION PASSED")
	quit(0)


func _fail(reason: String) -> void:
	push_error("SYSTEM COMPANION RUNTIME VALIDATION FAILED: " + reason)
	quit(1)
