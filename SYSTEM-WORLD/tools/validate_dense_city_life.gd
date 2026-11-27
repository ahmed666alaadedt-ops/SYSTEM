extends SceneTree

const REGION_MANAGER_SCRIPT = preload("res://scripts/modern_world_region_manager.gd")
const BAGHDAD_VEGETATION_BUILDER = preload("res://scripts/baghdad_vegetation_cell_builder.gd")


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
	var vegetation_source := FileAccess.get_file_as_string("res://scripts/baghdad_vegetation_cell_builder.gd")
	var baghdad_streamer_source := FileAccess.get_file_as_string("res://scripts/baghdad_osm_cell_streamer.gd")
	var tower_landmarks_source := FileAccess.get_file_as_string("res://scripts/baghdad_tower_landmarks_manager.gd")
	if region_source.is_empty() or population_source.is_empty() or forest_source.is_empty() or daily_life_source.is_empty() or services_source.is_empty() or vegetation_source.is_empty() or baghdad_streamer_source.is_empty() or tower_landmarks_source.is_empty():
		_fail("A required city-life source file could not be read.")
		return
	if not region_source.contains("for tree_index in range(5)") or not region_source.contains("for shrub_index in range(8)"):
		_fail("Dense park tree/shrub placement loops are missing.")
		return
	if not region_source.contains("MultiMeshInstance3D") or not region_source.contains("_add_park_multimesh"):
		_fail("Batched park vegetation renderer is missing.")
		return
	if not vegetation_source.contains("const TARGET_PLANT_COUNT := 1000000") or not vegetation_source.contains("TARGET_DENSITY_PER_M2") or not vegetation_source.contains("MAX_PLANTS_PER_CELL"):
		_fail("The million-plant Baghdad density profile or per-cell safety cap is missing.")
		return
	var vegetation_quota_total := 0
	for quota in BAGHDAD_VEGETATION_BUILDER.CATEGORY_TARGETS.values():
		vegetation_quota_total += int(quota)
	if vegetation_quota_total != BAGHDAD_VEGETATION_BUILDER.TARGET_PLANT_COUNT:
		_fail("Baghdad vegetation category quotas do not add up to one million.")
		return
	if int(BAGHDAD_VEGETATION_BUILDER.CATEGORY_TARGETS.get("large_trees", 0)) != 150000 or int(BAGHDAD_VEGETATION_BUILDER.CATEGORY_TARGETS.get("aquatic_riparian", 0)) != 100000:
		_fail("Baghdad vegetation category quotas differ from the approved distribution.")
		return
	for category in ["large_trees", "palms", "ornamental_fruit", "shrubs", "flowers_groundcover", "aquatic_riparian"]:
		if not vegetation_source.contains('"'+category+'"'):
			_fail("Missing Baghdad vegetation category: " + category)
			return
	if not vegetation_source.contains("BaghdadVegetationNear_") or not vegetation_source.contains("BaghdadVegetationFar_") or not vegetation_source.contains("visibility_range_begin = 240.0") or not vegetation_source.contains("visibility_range_end = 900.0"):
		_fail("Near/far vegetation LOD batches are missing.")
		return
	if not tower_landmarks_source.contains("vegetation_builder.build_planter") or not tower_landmarks_source.contains("baghdad_sky_ring_planter_"):
		_fail("Baghdad elevated sky-garden planters are not connected to the shared vegetation builder.")
		return
	if not baghdad_streamer_source.contains("vegetation_builder.build_cell") or not baghdad_streamer_source.contains("BaghdadVegetationCellBuilderScript.TARGET_PLANT_COUNT"):
		_fail("Baghdad OSM cell loading is not connected to the vegetation streamer.")
		return

	if not population_source.contains("const MAX_VISIBLE_CIVILIANS := 72"):
		_fail("Visible civilian cap is not the expected 72.")
		return
	if not forest_source.contains("const TREE_COUNT_PER_SIDE := 18") or not forest_source.contains("const SHRUB_COUNT_PER_SIDE := 24") or not forest_source.contains("const GRASS_COUNT := 150"):
		_fail("Natural forest density settings do not match the approved pass.")
		return

	if not daily_life_source.contains("const STARTER_RESIDENT_COUNT := 42500") or not daily_life_source.contains("const STARTER_MINOR_COUNT := 7500"):
		_fail("The 50,000 resident society target is missing.")
		return
	if not daily_life_source.contains("await get_tree().process_frame"):
		_fail("Resident seeding is not spread across frames.")
		return
	if not population_source.contains("_heap_push_farthest") or not population_source.contains("_heap_sift_down") or not population_source.contains("41 x 41 city-block grid"):
		_fail("Bounded nearest-resident heap or distributed block placement is missing.")
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

	var vegetation_builder = BAGHDAD_VEGETATION_BUILDER.new()
	var vegetation_root := Node3D.new()
	root.add_child(vegetation_root)
	var park_feature := {
		"tags": {"leisure": "park"},
		"geometry": {"type": "Polygon", "coordinates": [[[0, 0], [200, 0], [200, 200], [0, 200], [0, 0]]]}
	}
	var water_feature := {
		"tags": {"natural": "water"},
		"geometry": {"type": "Polygon", "coordinates": [[[50, 50], [150, 50], [150, 150], [50, 150], [50, 50]]]}
	}
	var road_feature := {
		"tags": {"highway": "residential"},
		"geometry": {"type": "LineString", "coordinates": [[0, 100], [200, 100]]}
	}
	var planter_root := Node3D.new()
	root.add_child(planter_root)
	var planter_stats: Dictionary = vegetation_builder.build_planter(
		planter_root, Vector2(14.0, 18.0), 2.28, 20, "validator_sky_planter"
	)
	if int(planter_stats.get("total", 0)) != 20 or int(planter_root.get_meta("baghdad_planter_plant_count", 0)) != 20:
		_fail("Elevated sky-garden planter vegetation did not preserve the requested plant count.")
		return
	var vegetation_stats: Dictionary = vegetation_builder.build_cell(
		vegetation_root, Vector2i(0, 0), [park_feature], [water_feature],
		Callable(self, "_zero_height"), [road_feature], 200.0
	)
	if int(vegetation_stats.get("total", 0)) < 40 or int(vegetation_stats.get("counts", {}).get("aquatic_riparian", 0)) < 1 or int(vegetation_stats.get("roadside_count", 0)) < 2:
		_fail("OSM park, roadside and riparian vegetation batching did not create the expected instances.")
		return
	print("Dense city life validation passed: park_tree_slots_per_pocket=5 park_shrub_slots_per_pocket=8 visible_civilians=72 seeded_residents=42500 seeded_minors=7500 nearest_resident_heap=top_72 commercial_tenants=12 industrial_units=6 forest_trees=36 forest_shrubs=48 forest_grass=150 vegetation_target=", BAGHDAD_VEGETATION_BUILDER.TARGET_PLANT_COUNT, " vegetation_cell_instances=", vegetation_stats.total, " multimesh_instances=", batch.multimesh.instance_count)

	quit(0)


func _zero_height(_point: Vector2) -> float:
	return 0.0
