extends SceneTree


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load("res://MainScene.tscn") as PackedScene
	if packed_scene == null:
		_fail("MainScene.tscn could not be loaded for cinematic validation.")
		return
	var main_scene := packed_scene.instantiate() as Node3D
	if main_scene == null:
		_fail("MainScene.tscn did not instantiate as Node3D.")
		return
	root.add_child(main_scene)
	for frame_index in range(14):
		await process_frame

	var region := main_scene.find_child("ModernWorldRegionManager", true, false) as Node3D
	if region == null:
		_fail("ModernWorldRegionManager is missing.")
		return
	var presentation := region.get_node_or_null("ModernWorldCinematicPresentation") as Node3D
	if presentation == null or not bool(presentation.get_meta("system_cinematic_presentation", false)):
		_fail("The modern world cinematic presentation rig was not initialized.")
		return
	var world_environment := presentation.get_node_or_null("SYSTEMCinematicWorldEnvironment") as WorldEnvironment
	if world_environment == null or world_environment.environment == null:
		_fail("The cinematic WorldEnvironment is missing.")
		return
	var environment := world_environment.environment
	if environment.background_mode != Environment.BG_SKY:
		_fail("The cinematic sky background is not active.")
		return
	if environment.tonemap_mode != Environment.TONE_MAPPER_FILMIC:
		_fail("Filmic tone mapping is not enabled.")
		return
	if not environment.glow_enabled or not environment.fog_enabled:
		_fail("Cinematic glow or atmospheric depth fog is disabled.")
		return
	var sun := presentation.get_node_or_null("SYSTEMCinematicGoldenHourSun") as DirectionalLight3D
	if sun == null or not sun.shadow_enabled or sun.light_energy <= 0.0:
		_fail("The cinematic golden-hour directional light is missing or inactive.")
		return
	print("SYSTEM CINEMATIC QA PASS: sky, filmic tone mapping, glow, atmospheric fog and golden-hour sun are active.")
	quit(0)


func _fail(message: String) -> void:
	push_error("SYSTEM CINEMATIC QA FAIL: " + message)
	quit(1)
