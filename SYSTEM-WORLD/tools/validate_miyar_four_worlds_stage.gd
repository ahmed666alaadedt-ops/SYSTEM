extends SceneTree

const STAGE_SCENE := preload("res://scenes/MiyarFourWorldsStage.tscn")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := STAGE_SCENE.instantiate()
	root.add_child(stage)
	await process_frame
	assert(stage is Node3D, "Miyar world selection stage must be 3D")
	assert(stage.get_node_or_null("Miyar3D") != null, "Miyar 3D actor missing")
	assert(stage.get_node_or_null("MiyarWorldSelectionHUD") != null, "World selection HUD missing")
	assert(stage.gate_nodes.size() == 4, "Exactly four world gates are required")
	assert(stage.miyar_model != null, "Miyar rigged model loader missing")
	assert(stage.selected_world_id == "modern", "Modern world should be the default selection")
	stage.select_world("historical")
	assert(stage.selected_world_id == "historical", "World selection state did not update")
	stage.select_world("fantasy")
	assert(stage.selected_world_id == "fantasy", "Fantasy selection did not update")
	stage.select_world("greed_island")
	assert(stage.selected_world_id == "greed_island", "Greed Island selection did not update")
	print("MIYAR FOUR WORLDS 3D STAGE VALIDATION PASSED")
	quit(0)
