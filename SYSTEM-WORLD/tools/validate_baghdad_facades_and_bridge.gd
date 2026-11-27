extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Baghdad facade and Republic Bridge validation failed: " + message)
	quit(1)

func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not load.")
		return
	var main := packed.instantiate() as Node3D
	if main == null:
		_fail("Main scene root is not Node3D.")
		return
	root.add_child(main)
	for _frame in range(24):
		await process_frame

	var continent := main.find_child("ModernContinent", true, false) as Node3D
	if continent == null:
		_fail("ModernContinent was not initialized.")
		return
	var city_windows := 0
	for city_name in ["NewYork", "London", "Paris", "Baghdad", "Moscow", "Cairo", "Tokyo"]:
		var marker := continent.find_child("City_" + city_name, true, false)
		if marker == null:
			continue
		var windows := marker.get_node_or_null("CitySilhouetteWindows_LightLOD") as MultiMeshInstance3D
		if windows == null or windows.multimesh == null or windows.multimesh.mesh == null:
			continue
		if windows.multimesh.instance_count <= 0:
			continue
		city_windows += 1
	if city_windows < 4:
		_fail("Fewer than four distant city silhouettes expose valid lightweight window MultiMeshes.")
		return

	var bridge := continent.get_node_or_null("BaghdadRepublicBridge") as Node3D
	if bridge == null:
		_fail("Surveyed BaghdadRepublicBridge is missing.")
		return
	var deck := bridge.get_node_or_null("RepublicBridgeDeck") as MeshInstance3D
	if deck == null or deck.mesh == null or deck.mesh.get_surface_count() <= 0:
		_fail("Republic Bridge deck mesh is missing or empty.")
		return
	var guardrails := 0
	var lane_markings := 0
	var expansion_joints := 0
	var lamp_fixtures := 0
	for child in bridge.get_children():
		var node_name := str(child.name)
		if node_name.begins_with("RepublicBridgeGuardrail_"):
			guardrails += 1
		elif node_name.begins_with("RepublicBridgeLaneCenterline_"):
			lane_markings += 1
		elif node_name.begins_with("RepublicBridgeExpansionJoint_"):
			expansion_joints += 1
		elif node_name.begins_with("RepublicBridgeLampFixture_"):
			lamp_fixtures += 1
	if guardrails < 2 or lane_markings < 1 or expansion_joints < 1 or lamp_fixtures < 2:
		_fail("Bridge detail counts are incomplete: guardrails=%d lanes=%d joints=%d lamps=%d" % [guardrails, lane_markings, expansion_joints, lamp_fixtures])
		return
	print("Baghdad facade and Republic Bridge validation passed: city_window_lods=%d guardrails=%d lane_segments=%d expansion_joints=%d lamp_fixtures=%d" % [city_windows, guardrails, lane_markings, expansion_joints, lamp_fixtures])
	quit(0)
