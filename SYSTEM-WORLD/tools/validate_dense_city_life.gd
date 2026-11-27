extends SceneTree

const REGION_MANAGER_SCRIPT = preload("res://scripts/modern_world_region_manager.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _fail(message: String) -> void:
	push_error("Dense city life validation failed: " + message)
	quit(1)


func _run_validation() -> void:
	var region_source := FileAccess.get_file_as_string("res://scripts/modern_world_region_manager.gd")
	var population_source := FileAccess.get_file_as_string("res://scripts/npc_visible_population_manager.gd")
	var forest_source := FileAccess.get_file_as_string("res://scripts/forest_manager.gd")
	var daily_life_source := FileAccess.get_file_as_string("res://scripts/npc_daily_life_manager.gd")
	var services_source := FileAccess.get_file_as_string("res://scripts/modern_city_services_manager.gd")
	if region_source.is_empty() or population_source.is_empty() or forest_source.is_empty() or daily_life_source.is_empty() or services_source.is_empty():
		_fail("A required city-life source file could not be read.")
		return
	if not region_source.contains("for tree_index in range(5)") or not region_source.contains("for shrub_index in range(8)"):
		_fail("Dense park tree/shrub placement loops are missing.")
		return
	if not region_source.contains("MultiMeshInstance3D") or not region_source.contains("_add_park_multimesh"):
		_fail("Batched park vegetation renderer is missing.")
		return
	if not population_source.contains("const MAX_VISIBLE_CIVILIANS := 72"):
		_fail("Visible civilian cap is not the expected 72.")
		return
	if not forest_source.contains("const TREE_COUNT_PER_SIDE := 18") or not forest_source.contains("const SHRUB_COUNT_PER_SIDE := 24") or not forest_source.contains("const GRASS_COUNT := 150"):
		_fail("Natural forest density settings do not match the approved pass.")
		return

	if not daily_life_source.contains("const STARTER_RESIDENT_COUNT := 1200") or not daily_life_source.contains("const STARTER_MINOR_COUNT := 240"):
		_fail("The large resident society target is missing.")
		return
	if not daily_life_source.contains("await get_tree().process_frame"):
		_fail("Resident seeding is not spread across frames.")
		return
	if not population_source.contains("candidates.sort_custom") or not population_source.contains("41 x 41 city-block grid"):
		_fail("Nearest-resident selection or distributed block placement is missing.")
		return
	for tenant_id in ["restaurant", "cafe", "bakery", "sweets", "clothing", "shoes", "perfume", "electronics", "mobile", "furniture", "supermarket", "hardware"]:
		if not services_source.contains('"id": "' + tenant_id + '"'):
			_fail("Missing commercial tenant category: " + tenant_id)
			return
	for tenant_id in ["metal", "wood", "auto", "building", "textile", "warehouse"]:
		if not services_source.contains('"id": "' + tenant_id + '"'):
			_fail("Missing industrial tenant category: " + tenant_id)
			return
	if not services_source.contains("func _create_industrial_details") or not services_source.contains("func _create_shopfronts"):
		_fail("Commercial or industrial storefront builder is missing.")
		return

	# Exercise the batching helper with real Godot MultiMesh resources.
	var manager = REGION_MANAGER_SCRIPT.new()
	var batch_root := Node3D.new()
	root.add_child(batch_root)
	var transforms: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0)),
		Transform3D(Basis.IDENTITY, Vector3(2.0, 1.0, 0.0)),
		Transform3D(Basis.IDENTITY, Vector3(4.0, 1.0, 0.0))
	]
	manager.call("_add_park_multimesh", batch_root, "DenseParkTestBatch", BoxMesh.new(), transforms, StandardMaterial3D.new())
	var batch := batch_root.get_node_or_null("DenseParkTestBatch") as MultiMeshInstance3D
	if batch == null or batch.multimesh == null or batch.multimesh.instance_count != 3:
		_fail("MultiMesh batching helper did not preserve all three test instances.")
		return

	print("Dense city life validation passed: park_tree_slots_per_pocket=5 park_shrub_slots_per_pocket=8 visible_civilians=72 seeded_residents=1200 seeded_minors=240 commercial_tenants=12 industrial_units=6 forest_trees=36 forest_shrubs=48 forest_grass=150 multimesh_instances=", batch.multimesh.instance_count)
	quit(0)
