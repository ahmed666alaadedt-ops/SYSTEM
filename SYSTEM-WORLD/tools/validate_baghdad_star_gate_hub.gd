extends SceneTree

## Verifies that all inter-world Star Gates are in Baghdad and that Greed
## Island's return mechanism is a non-Star-Gate extraction beacon.

func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("Canonical MainScene could not be loaded")
		return
	var scene := packed.instantiate()
	if scene == null:
		_fail("Canonical MainScene could not be instantiated")
		return
	root.add_child(scene)

	for _frame in range(12):
		await process_frame

	var world_manager := scene.get_node_or_null("WorldManager")
	if world_manager == null:
		_fail("WorldManager is unavailable")
		return
	var modern_root := world_manager.call("get_world_root", 2) as Node3D
	var island_root := world_manager.call("get_world_root", 3) as Node3D
	if modern_root == null or island_root == null:
		_fail("One or more world roots are unavailable")
		return

	var hub := modern_root.get_node_or_null("BaghdadStarGateHub")
	if hub == null:
		_fail("Baghdad Star Gate hub was not created")
		return
	var expected_gate_names := [
		"FantasyStarGate",
		"HistoricalStarGate",
		"GreedIslandSeasonalStarGate"
	]
	for gate_name in expected_gate_names:
		var gate := hub.get_node_or_null(gate_name)
		if gate == null:
			_fail("Baghdad hub is missing gate: " + gate_name)
			return
		var trigger := gate.get_node_or_null("GateActivationArea") as Area3D
		if trigger == null or not bool(trigger.get_meta("system_star_gate", false)):
			_fail("Baghdad gate trigger metadata is invalid: " + gate_name)
			return

	var beacon := island_root.get_node_or_null("GreedIslandReturnBeacon")
	if beacon == null:
		_fail("Greed Island return beacon was not created")
		return
	var return_area := beacon.get_node_or_null("ReturnToBaghdadZone") as Area3D
	if return_area == null or not bool(return_area.get_meta("system_world_exit", false)):
		_fail("Greed Island return beacon does not expose its world-exit zone")
		return
	if bool(return_area.get_meta("system_star_gate", false)):
		_fail("Greed Island return beacon was incorrectly classified as a Star Gate")
		return

	for node in island_root.find_children("*", "Area3D", true, false):
		if bool(node.get_meta("system_star_gate", false)):
			_fail("A Star Gate trigger was found outside Baghdad: " + str(node.get_path()))
			return

	print("SYSTEM STAR GATE QA PASS: all inter-world gates are in Baghdad; Greed Island uses a non-gate return beacon.")
	quit(0)


func _fail(reason: String) -> void:
	push_error("SYSTEM STAR GATE QA FAILED: " + reason)
	quit(1)
