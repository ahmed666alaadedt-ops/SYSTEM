extends SceneTree

const STAGE_SCENE := preload("res://scenes/MiyarFourWorldsStage.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := STAGE_SCENE.instantiate()
	if stage == null:
		_fail("Miyar 3D stage could not be instantiated")
		return
	root.add_child(stage)
	await process_frame
	await process_frame

	if not stage is Node3D:
		_fail("Miyar world selection stage must be 3D")
		return
	if stage.get_node_or_null("Miyar3D") == null:
		_fail("Miyar 3D actor missing")
		return
	if stage.get_node_or_null("MiyarWorldSelectionHUD") == null:
		_fail("World selection HUD missing")
		return
	if stage.gate_nodes.size() != 4:
		_fail("Exactly four world gates are required")
		return
	if stage.miyar_model == null or stage.miyar_model.imported_model == null:
		_fail("Miyar rigged female GLB did not load; procedural fallback is not accepted")
		return
	if stage.miyar_model.animation_player == null:
		_fail("Miyar imported AnimationPlayer is missing")
		return

	var animation_names: Array = stage.miyar_model.animation_player.get_animation_list()
	var has_breathing := false
	for animation_name in animation_names:
		if str(animation_name).to_lower() == "idle_breathing":
			has_breathing = true
			break
	if not has_breathing:
		_fail("Miyar idle-breathing clip is missing")
		return
	if stage.selected_world_id != "modern":
		_fail("Modern world should be the default selection")
		return

	for world_id in ["historical", "fantasy", "greed_island", "modern"]:
		stage.select_world(world_id)
		if stage.selected_world_id != world_id:
			_fail("World selection state failed for " + world_id)
			return

	print("MIYAR FOUR WORLDS 3D STAGE VALIDATION PASSED")
	quit(0)


func _fail(reason: String) -> void:
	push_error("MIYAR FOUR WORLDS 3D STAGE VALIDATION FAILED: " + reason)
	quit(1)
