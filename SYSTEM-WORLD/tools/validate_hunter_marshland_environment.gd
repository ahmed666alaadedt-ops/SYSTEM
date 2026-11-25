extends SceneTree

const MarshlandScript = preload("res://scripts/system_hunter_marshland_environment.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var marshland := MarshlandScript.new()
	root.add_child(marshland)
	for index in range(3):
		await process_frame
	if not bool(marshland.get_meta("system_marshland_runtime_ready", false)):
		_fail("Marshland manager did not finish building.")
		return
	if marshland.get_node_or_null("MarshlandWalkableGround") == null:
		_fail("Walkable marshland ground is missing.")
		return
	for path in ["NorthAgriculturalTerrace", "SouthAgriculturalTerrace", "WestCultivatedPlots", "EastCultivatedPlots", "MainMarshChannel", "EasternWetlandPool", "SouthernReedWater", "MarshlandVillage", "ColossalAncientMarshTurtle", "GiantMarshMonitor", "GiantMarshStalker", "HunterExamMarshlandApproach"]:
		if marshland.get_node_or_null(path) == null:
			_fail("Required marshland feature is missing: " + path)
			return
	if marshland.deceptive_npc_ids.size() != 4:
		_fail("Expected four deceptive Hunter-exam NPCs.")
		return
	if marshland.giant_creature_ids.size() != 3:
		_fail("Expected three giant creature actors.")
		return
	var water_count := 0
	for child in marshland.get_children():
		if child is Area3D and bool(child.get_meta("system_marshland_water", false)):
			water_count += 1
			if not child.monitoring or child.get_node_or_null("CollisionShape3D") == null:
				_fail("Marshland water is missing active collision monitoring: " + child.name)
				return
	if water_count != 3:
		_fail("Expected three independently monitored marshland water zones.")
		return
	var turtle := marshland.get_node("ColossalAncientMarshTurtle")
	if not bool(turtle.get_meta("system_giant_creature", false)) or str(turtle.get_meta("system_creature_species", "")) != "colossal_marsh_turtle":
		_fail("Colossal turtle species metadata is missing.")
		return
	var deception := marshland.get_node("DeceptiveExamGuide_00/DeceptionProximity") as Area3D
	if deception == null or not deception.monitoring:
		_fail("Deceptive NPC proximity trigger is missing.")
		return
	var arrival := marshland.get_node("HunterExamMarshlandApproach/MarshlandExamArrivalZone") as Area3D
	if arrival == null:
		_fail("Hunter exam marshland arrival trigger is missing.")
		return
	var player := CharacterBody3D.new()
	player.name = "ValidationPlayer"
	player.add_to_group("system_player")
	root.add_child(player)
	var deception_messages: Array[String] = []
	marshland.deception_triggered.connect(func(_npc_id: String, message: String): deception_messages.append(message))
	marshland._on_deception_area_entered(player, "DeceptiveExamGuide_00", "false_safe_route")
	if not bool(player.get_meta("system_marshland_deception_warning", false)) or deception_messages.is_empty():
		_fail("Deceptive NPC did not issue a player-facing warning.")
		return
	marshland._on_marshland_arrival(player)
	if not bool(player.get_meta("system_hunter_exam_marshland_reached", false)) or str(player.get_meta("system_hunter_exam_current_environment", "")) != "marshland":
		_fail("Hunter exam arrival did not record marshland progress.")
		return
	player.queue_free()
	marshland.queue_free()
	print("Hunter marshland environment validation passed.")
	quit(0)

func _fail(message: String) -> void:
	push_error("Hunter marshland environment validation failed: " + message)
	quit(1)
