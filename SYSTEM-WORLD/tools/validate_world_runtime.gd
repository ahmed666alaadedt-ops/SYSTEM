extends SceneTree

## Boots the canonical main scene and verifies that each of the four world roots
## can be initialized and entered through the actual WorldManager.
## Run after the editor import pass:
## godot --headless --path SYSTEM-WORLD --script res://tools/validate_world_runtime.gd

const WORLD_FANTASY := 0
const WORLD_HISTORICAL := 1
const WORLD_MODERN := 2
const WORLD_GREED_ISLAND := 3

const REQUIRED_MODERN_CITIES := [
	"Baghdad",
	"New York",
	"Tokyo",
	"London",
	"Paris",
	"Moscow",
	"Seoul",
	"Guangzhou",
	"Cairo",
	"New Delhi",
	"Singapore",
	"Sydney",
	"Rio de Janeiro",
	"Johannesburg"
]

const REQUIRED_HISTORICAL_LANDMARKS := [
	"hercules_arches",
	"atlantis",
	"alexandria_lighthouse",
	"babylon_tower",
	"ancient_rome",
	"roman_colosseum"
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed_scene := load("res://MainScene.tscn") as PackedScene
	if packed_scene == null:
		_fail("Canonical MainScene.tscn did not load.")
		_finish()
		return

	var main := packed_scene.instantiate()
	if main == null:
		_fail("Canonical main scene could not be instantiated.")
		_finish()
		return

	root.add_child(main)
	await process_frame

	var world_manager := main.get_node_or_null("WorldManager")
	var map_manager := main.get_node_or_null("WorldMapManager")
	if world_manager == null:
		_fail("Main scene did not create WorldManager.")
		_finish()
		return
	if map_manager == null:
		_fail("Main scene did not create WorldMapManager.")
		_finish()
		return

	_validate_modern_world(world_manager, map_manager)
	await _enter_world(world_manager, WORLD_HISTORICAL)
	_validate_historical_world(world_manager)
	await _enter_world(world_manager, WORLD_FANTASY)
	await process_frame
	_validate_fantasy_world(world_manager, map_manager)
	await _enter_world(world_manager, WORLD_GREED_ISLAND)
	_validate_greed_island(world_manager)

	if failures.is_empty():
		print("WORLD RUNTIME QA PASS: modern, historical, fantasy, and Greed Island initialized and entered.")
	else:
		for failure in failures:
			push_error("WORLD RUNTIME QA: " + failure)
		push_error("WORLD RUNTIME QA FAILED: %d issue(s)." % failures.size())

	_finish()


func _validate_modern_world(world_manager: Node, map_manager: Node) -> void:
	var active_root := world_manager.call("get_active_world") as Node3D
	if active_root == null:
		_fail("Modern world has no active root.")
		return

	var continent := active_root.get_node_or_null("ModernContinent")
	var region_manager := active_root.get_node_or_null("ModernWorldRegionManager")
	if continent == null:
		_fail("Modern world is missing ModernContinent.")
	if region_manager == null:
		_fail("Modern world is missing ModernWorldRegionManager.")
		return

	var anchors: Dictionary = region_manager.get("city_anchors")
	for city_name in REQUIRED_MODERN_CITIES:
		if not anchors.has(city_name):
			_fail("Modern map is missing city anchor: " + city_name)

	var all_locations: Dictionary = map_manager.get("locations_by_world")
	var modern_locations: Dictionary = all_locations.get("2", {})
	if modern_locations.size() < REQUIRED_MODERN_CITIES.size():
		_fail(
			"Modern map registered only %d locations; expected at least %d." % [
				modern_locations.size(),
				REQUIRED_MODERN_CITIES.size()
			]
		)

	_validate_visible_npc_glb_population(active_root)
	_scan_invalid_mesh_nodes(active_root, "modern")
	print(
		"MODERN WORLD QA: terrain=%s, city_anchors=%d, map_locations=%d" % [
			str(continent != null),
			anchors.size(),
			modern_locations.size()
		]
	)


func _enter_world(world_manager: Node, world_id: int) -> void:
	world_manager.call("switch_world", world_id)
	await process_frame


func _validate_historical_world(world_manager: Node) -> void:
	var active_root := world_manager.call("get_active_world") as Node3D
	if active_root == null:
		_fail("Historical world has no active root.")
		return

	var historical := active_root.get_node_or_null("HistoricalCivilizationsEnvironment")
	if historical == null:
		_fail("Historical world manager was not created.")
		return

	for landmark_id in REQUIRED_HISTORICAL_LANDMARKS:
		if historical.get_node_or_null(landmark_id) == null:
			_fail("Historical world is missing landmark: " + landmark_id)

	_scan_invalid_mesh_nodes(active_root, "historical")
	print("HISTORICAL WORLD QA: six landmark scenes present.")


func _validate_fantasy_world(world_manager: Node, map_manager: Node) -> void:
	var active_root := world_manager.call("get_active_world") as Node3D
	if active_root == null:
		_fail("Fantasy world has no active root.")
		return

	var fantasy := active_root.get_node_or_null("FantasyWorldEnvironment")
	if fantasy == null:
		_fail("Fantasy world manager was not created.")
		return

	var settlements: Node = fantasy.call("get_fantasy_settlement_manager")
	if settlements == null or not is_instance_valid(settlements):
		_fail("Fantasy village and kingdom settlement manager was not initialized.")
		return

	var village_count := int(settlements.call("get_village_count"))
	var kingdom_count := int(settlements.call("get_kingdom_count"))
	var resident_count := int(settlements.call("get_resident_count"))
	if village_count < 3:
		_fail("Fantasy world created fewer than three villages.")
	if kingdom_count < 4:
		_fail("Fantasy world created fewer than four kingdom capitals.")
	if resident_count < 18:
		_fail("Fantasy world created fewer than eighteen settlement residents.")

	var all_locations: Dictionary = map_manager.get("locations_by_world")
	var fantasy_locations: Dictionary = all_locations.get("0", {})
	if fantasy_locations.size() < 7:
		_fail("Fantasy settlements did not register villages and kingdoms on the world map.")

	_scan_invalid_mesh_nodes(active_root, "fantasy")
	print(
		"FANTASY WORLD QA: villages=%d, kingdoms=%d, residents=%d, map_locations=%d" % [
			village_count,
			kingdom_count,
			resident_count,
			fantasy_locations.size()
		]
	)


func _validate_greed_island(world_manager: Node) -> void:
	var active_root := world_manager.call("get_active_world") as Node3D
	if active_root == null:
		_fail("Greed Island has no active root.")
		return

	# GreedIslandManager renames its node during _ready(), so validate the
	# runtime name rather than the temporary name assigned by WorldManager.
	var island := active_root.get_node_or_null("GreedIslandManager")
	if island == null:
		_fail("Greed Island manager was not created or did not enter its ready state.")
		return

	if bool(island.call("is_combat_allowed")):
		_fail("Greed Island unexpectedly allows combat.")
	if not bool(island.call("is_admin_test_environment")):
		_fail("Greed Island admin test mode is not enabled.")

	var discovery_count := _count_discovery_points(island)
	if discovery_count < 4:
		_fail("Greed Island created fewer than four discoverable map points.")

	_scan_invalid_mesh_nodes(active_root, "greed_island")
	print(
		"GREED ISLAND QA: admin_test=%s, combat=%s, discovery_points=%d" % [
			str(island.call("is_admin_test_environment")),
			str(island.call("is_combat_allowed")),
			discovery_count
		]
	)


func _count_discovery_points(node: Node) -> int:
	var count := 1 if node.has_meta("system_location_id") else 0
	for child in node.get_children():
		count += _count_discovery_points(child)
	return count


func _fail(message: String) -> void:
	failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		quit(0)
	else:
		quit(1)


func _scan_invalid_mesh_nodes(node: Node, world_label: String) -> void:
	var invalid_mesh_paths: Array[String] = []
	_collect_invalid_mesh_paths(node, invalid_mesh_paths)
	if not invalid_mesh_paths.is_empty():
		_fail(
			"%s world contains %d mesh instance(s) without geometry: %s" % [
				world_label,
				invalid_mesh_paths.size(),
				"; ".join(invalid_mesh_paths.slice(0, 12))
			]
		)
	print(
		"WORLD MESH QA: %s invalid_mesh_nodes=%d" % [
			world_label,
			invalid_mesh_paths.size()
		]
	)


func _collect_invalid_mesh_paths(node: Node, result: Array[String]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			result.append(str(mesh_instance.get_path()))
	elif node is MultiMeshInstance3D:
		var multi_instance := node as MultiMeshInstance3D
		if multi_instance.multimesh == null or multi_instance.multimesh.mesh == null:
			result.append(str(multi_instance.get_path()))
	for child in node.get_children():
		_collect_invalid_mesh_paths(child, result)


func _validate_visible_npc_glb_population(modern_root: Node3D) -> void:
	var population := modern_root.get_node_or_null("NPCVisiblePopulationManager")
	if population == null:
		_fail("Modern world did not create NPCVisiblePopulationManager.")
		return

	var pedestrians: Dictionary = population.get("pedestrians")
	if pedestrians.is_empty():
		_fail("Modern world has no visible civilian characters.")
		return

	var imported_count := 0
	var unique_model_paths: Dictionary = {}
	for npc_id in pedestrians:
		var record: Dictionary = pedestrians[npc_id]
		var visual := record.get("visual") as Node
		if visual == null or not is_instance_valid(visual):
			_fail("Visible NPC has no humanoid visual: " + str(npc_id))
			continue
		var imported_model := visual.get("imported_model") as Node3D
		if imported_model == null or not is_instance_valid(imported_model):
			_fail("Visible NPC is not using an imported GLB model: " + str(npc_id))
			continue
		imported_count += 1
		unique_model_paths[str(visual.get("selected_model_path"))] = true

	if imported_count != pedestrians.size():
		_fail(
			"Only %d of %d visible civilians loaded GLB models." % [
				imported_count,
				pedestrians.size()
			]
		)

	print(
		"VISIBLE NPC GLB QA: civilians=%d, imported=%d, unique_models=%d" % [
			pedestrians.size(),
			imported_count,
			unique_model_paths.size()
		]
	)
