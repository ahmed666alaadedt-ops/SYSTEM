extends SceneTree

const BAGHDAD_STREAMER = preload("res://scripts/baghdad_osm_cell_streamer.gd")
const TERRAIN_MANAGER = preload("res://scripts/modern_continent_manager.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var terrain = TERRAIN_MANAGER.new()
	terrain.name = "ModernContinent"
	root.add_child(terrain)
	var streamer = BAGHDAD_STREAMER.new()
	root.add_child(streamer)
	print("Baghdad OSM validation: streamer added; checking manifest and origin.")
	if not streamer.enabled:
		_fail("Baghdad OSM cell pack did not enable.")
		return
	if not streamer.get_streaming_status().get("canonical_origin_frame_valid", false):
		_fail("OSM cell coordinates do not match the canonical WGS84 origin.")
		return
	var empty_surface := SurfaceTool.new()
	empty_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var empty_mesh: ArrayMesh = streamer._commit_surface_tool_if_valid(empty_surface)
	if empty_mesh != null:
		_fail("Empty OSM geometry must be rejected before creating a renderer mesh.")
		return
	if streamer.get_node_or_null("BaghdadOSMAttribution/OpenStreetMapCredit") == null:
		_fail("Required OSM attribution overlay is missing.")
		return

	print("Baghdad OSM validation: manifest/origin accepted; loading center cell.")
	streamer._load_cell(Vector2i(0, 0))
	if not streamer.loaded_cells.has(Vector2i(0, 0)):
		_fail("Baghdad center cell did not load.")
		return
	var cell_root: Node3D = streamer.loaded_cells[Vector2i(0, 0)]
	print("Baghdad OSM validation: center cell loaded; checking generated scene nodes.")
	var roads := cell_root.find_children("OSMRoad_*", "MeshInstance3D", true, false)
	var buildings := cell_root.find_children("OSMBuilding_*", "MeshInstance3D", true, false)
	var landuse := cell_root.find_children("OSMLanduse_*", "MeshInstance3D", true, false)
	if roads.is_empty():
		_fail("Baghdad OSM center cell has no generated road meshes.")
		return
	if buildings.is_empty():
		_fail("Baghdad OSM center cell has no generated building meshes.")
		return
	if landuse.is_empty():
		_fail("Baghdad OSM center cell has no generated land-use meshes.")
		return
	var building_collisions := cell_root.find_children("OSMBuildingCollision_*", "StaticBody3D", true, false)
	if building_collisions.is_empty():
		_fail("Baghdad OSM building collision bodies were not created.")
		return
	print("Baghdad OSM runtime cell passed: roads=", roads.size(), " buildings=", buildings.size(), " landuse=", landuse.size(), " building_collisions=", building_collisions.size())
	print("Baghdad OSM validation: checking automatic player-driven streaming at Republic Bridge cell 17:-6.")
	var bridge_player := Node3D.new()
	bridge_player.name = "BridgeStreamingTestPlayer"
	bridge_player.add_to_group("system_player")
	bridge_player.position = Vector3(3563.921, 18.0, -1050.256)
	root.add_child(bridge_player)
	streamer._process(0.0)
	if not streamer.desired_cells.has(Vector2i(17, -6)):
		_fail("Player-driven OSM streaming did not select Republic Bridge cell 17:-6 at the surveyed bridge coordinates.")
		return
	if not streamer.loaded_cells.has(Vector2i(17, -6)):
		_fail("Republic Bridge OSM cell 17:-6 was queued but not loaded as the player's active center cell.")
		return
	var bridge_cell_root: Node3D = streamer.loaded_cells[Vector2i(17, -6)]
	var primary_bridge := bridge_cell_root.find_children("OSMBridge_4080878_*", "MeshInstance3D", true, false)
	var secondary_bridge := bridge_cell_root.find_children("OSMBridge_754157537_*", "MeshInstance3D", true, false)
	var tigris_river := bridge_cell_root.find_children("OSMWaterway_24709603_*", "MeshInstance3D", true, false)
	if primary_bridge.is_empty() or secondary_bridge.is_empty():
		_fail("Republic Bridge primary/secondary OSM roadway centerlines were not rendered in cell 17:-6.")
		return
	for bridge_mesh in primary_bridge + secondary_bridge:
		if absf(float(bridge_mesh.get_meta("system_bridge_deck_height_override_m", 0.0)) - 18.08) > 0.1:
			_fail("Republic Bridge roadway centerline is not rendered on the physical deck elevation.")
			return
	if tigris_river.is_empty():
		_fail("Tigris River OSM geometry was not rendered in cell 17:-6.")
		return
	print("Baghdad Republic Bridge OSM cell passed: primary bridge=", primary_bridge.size(), " secondary bridge=", secondary_bridge.size(), " Tigris=", tigris_river.size())

	# Verify the physical Republic Bridge, its safety/road details and the animated Tigris
	# built by ModernContinentManager, not just the separate OSM centerline cell meshes.
	var physical_bridge := terrain.get_node_or_null("BaghdadRepublicBridge") as Node3D
	if physical_bridge == null:
		_fail("Verified Republic Bridge polygon deck was not built in the terrain manager.")
		return
	var bridge_deck := physical_bridge.get_node_or_null("RepublicBridgeDeck") as MeshInstance3D
	var bridge_collision := physical_bridge.get_node_or_null("RepublicBridgeDeckCollision/RepublicBridgeDeckCollisionShape") as CollisionShape3D
	if bridge_deck == null or bridge_deck.mesh == null or bridge_deck.mesh.get_surface_count() == 0:
		_fail("Republic Bridge polygon deck mesh is missing or empty.")
		return
	if absf(float(bridge_deck.get_meta("system_bridge_deck_height_m", -999.0)) - 18.0) > 0.01:
		_fail("Republic Bridge physical deck is not aligned to the approved 18 m elevation.")
		return
	if bridge_collision == null or not bridge_collision.shape is ConcavePolygonShape3D:
		_fail("Republic Bridge deck is missing its physical concave collision.")
		return
	var bridge_collision_shape := bridge_collision.shape as ConcavePolygonShape3D
	if bridge_collision_shape.get_faces().size() < 30:
		_fail("Republic Bridge collision does not contain the triangulated OSM deck surface.")
		return
	var bridge_posts := physical_bridge.get_node_or_null("RepublicBridgeGuardrailPosts") as MultiMeshInstance3D
	if bridge_posts == null or bridge_posts.multimesh == null or bridge_posts.multimesh.instance_count < 16:
		_fail("Republic Bridge perimeter safety posts are missing or below the minimum coverage.")
		return
	var bridge_rail_count := physical_bridge.find_children("RepublicBridgeGuardrail_*", "MeshInstance3D", true, false).size()
	var bridge_handrail_count := physical_bridge.find_children("RepublicBridgeHandrail_*", "MeshInstance3D", true, false).size()
	if bridge_rail_count < 3 or bridge_handrail_count != bridge_rail_count:
		_fail("Republic Bridge continuous perimeter rails and handrails are incomplete.")
		return
	for marking_name in ["RepublicBridgeCenterlineMarkings", "RepublicBridgeLaneMarkings", "RepublicBridgeExpansionJoints"]:
		var marking := physical_bridge.get_node_or_null(marking_name) as MeshInstance3D
		if marking == null or marking.mesh == null or marking.mesh.get_surface_count() == 0:
			_fail("Republic Bridge road marking or expansion-joint surface is missing: " + marking_name)
			return
	var bridge_poles := physical_bridge.get_node_or_null("RepublicBridgeLightPoles") as MultiMeshInstance3D
	var bridge_lamps := physical_bridge.get_node_or_null("RepublicBridgeLampHeads") as MultiMeshInstance3D
	if bridge_poles == null or bridge_lamps == null or bridge_poles.multimesh == null or bridge_lamps.multimesh == null:
		_fail("Republic Bridge approach lighting is missing its instanced poles or lamp heads.")
		return
	if bridge_poles.multimesh.instance_count < 4 or bridge_lamps.multimesh.instance_count != bridge_poles.multimesh.instance_count:
		_fail("Republic Bridge light poles and lamp heads are not paired across both roadways.")
		return
	var tigris_surface := terrain.get_node_or_null("BaghdadTigrisRiver") as MeshInstance3D
	var tigris_foam := terrain.get_node_or_null("BaghdadTigrisBankFoam") as MeshInstance3D
	if tigris_surface == null or tigris_surface.mesh == null or tigris_surface.mesh.get_surface_count() == 0:
		_fail("The verified Tigris River surface mesh is missing or empty.")
		return
	var tigris_material := tigris_surface.material_override as ShaderMaterial
	if tigris_material == null or tigris_material.shader == null or not tigris_material.shader.code.contains("TIME * 0.52"):
		_fail("Tigris water surface is missing its world-space animated ripple shader.")
		return
	if tigris_foam == null or tigris_foam.mesh == null or tigris_foam.mesh.get_surface_count() == 0 or str(tigris_foam.get_meta("system_water_edge_detail", "")) != "soft_bank_foam":
		_fail("Tigris riverbank soft-foam geometry is missing or invalid.")
		return
	print("Baghdad Republic Bridge physical-detail QA passed: triangulated deck/collision, ", bridge_posts.multimesh.instance_count,
		" guardrail posts, rails=", bridge_rail_count, " markings/joints, paired lamps=", bridge_lamps.multimesh.instance_count,
		"; animated Tigris shader and bank foam verified.")

	var regional_roads := BAGHDAD_STREAMER.new()
	regional_roads.name = "BaghdadRegionalRoadsValidationStreamer"
	regional_roads.data_root = "res://data/geography/baghdad/regional_roads"
	root.add_child(regional_roads)
	if not regional_roads.enabled or absf(regional_roads.cell_size - 1000.0) > 0.01:
		_fail("Citywide Baghdad road pack did not enable at the expected 1 km overview resolution.")
		return
	if int(regional_roads.get_streaming_status().get("loaded_cell_count", -1)) != 0:
		_fail("Regional road streamer unexpectedly loaded cells before its player update.")
		return
	regional_roads._process(0.0)
	if not regional_roads.desired_cells.has(Vector2i(3, -2)):
		_fail("Citywide road streamer did not select the Republic Bridge 1 km cell for the player.")
		return
	if not regional_roads.loaded_cells.has(Vector2i(3, -2)):
		_fail("Citywide road streamer did not load the player's Republic Bridge 1 km cell.")
		return
	regional_roads._load_cell(Vector2i(0, 0))
	if not regional_roads.loaded_cells.has(Vector2i(0, 0)):
		_fail("Citywide regional road pack has no central Baghdad road cell.")
		return
	var regional_center: Node3D = regional_roads.loaded_cells[Vector2i(0, 0)]
	var regional_center_roads := regional_center.find_children("OSMRoad_*", "MeshInstance3D", true, false)
	if regional_center_roads.is_empty():
		_fail("Citywide regional road center cell produced no road meshes.")
		return
	regional_roads._load_cell(Vector2i(3, -2))
	if not regional_roads.loaded_cells.has(Vector2i(3, -2)):
		_fail("Citywide regional road pack is missing the Republic Bridge overview cell 3:-2.")
		return
	var regional_bridge: Node3D = regional_roads.loaded_cells[Vector2i(3, -2)]
	var regional_bridge_roads := regional_bridge.find_children("OSMRoad_*", "MeshInstance3D", true, false)
	if regional_bridge_roads.is_empty():
		_fail("Republic Bridge regional overview cell has no OSM road meshes.")
		return
	print("Baghdad citywide road overview passed: center roads=", regional_center_roads.size(), " bridge-area roads=", regional_bridge_roads.size(), " resolution=1 km.")

	var regional_urban := BAGHDAD_STREAMER.new()
	regional_urban.name = "BaghdadRegionalUrbanValidationStreamer"
	regional_urban.data_root = "res://data/geography/baghdad/regional_urban"
	regional_urban.load_radius = 0
	regional_urban.overview_mode = true
	root.add_child(regional_urban)
	if not regional_urban.enabled or not regional_urban.overview_mode or absf(regional_urban.cell_size - 1000.0) > 0.01:
		_fail("Citywide Baghdad urban detail pack did not enable in 1 km low-detail mode.")
		return
	var urban_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/geography/baghdad/regional_urban/manifest.json"))
	if not urban_manifest is Dictionary:
		_fail("Citywide Baghdad urban manifest is invalid.")
		return
	var expected_urban_layers := ["buildings", "waterways", "bridges", "landuse", "amenities", "railway", "natural-water", "wetlands", "entrances"]
	if urban_manifest.get("layers_included", []) != expected_urban_layers:
		_fail("Citywide Baghdad urban pack is missing one or more expected OSM layers.")
		return
	var urban_cells_path := "res://data/geography/baghdad/regional_urban/cells"
	var urban_files := DirAccess.get_files_at(urban_cells_path)
	var building_cell := Vector2i(2147483647, 2147483647)
	var poi_cell := Vector2i(2147483647, 2147483647)
	for file_name in urban_files:
		if not file_name.ends_with(".json"):
			continue
		var tile: Variant = JSON.parse_string(FileAccess.get_file_as_string(urban_cells_path.path_join(file_name)))
		if not tile is Dictionary:
			continue
		var tile_layers: Dictionary = tile.get("layers", {})
		var tile_cell := Vector2i(int(tile.get("cell_x", 0)), int(tile.get("cell_z", 0)))
		if building_cell.x == 2147483647 and not tile_layers.get("buildings", []).is_empty():
			building_cell = tile_cell
		if poi_cell.x == 2147483647 and not tile_layers.get("amenities", []).is_empty():
			poi_cell = tile_cell
		if building_cell.x != 2147483647 and poi_cell.x != 2147483647:
			break
	if building_cell.x == 2147483647 or poi_cell.x == 2147483647:
		_fail("Citywide urban pack must contain mapped building footprints and public/commercial POIs.")
		return
	regional_urban._load_cell(building_cell)
	if not regional_urban.loaded_cells.has(building_cell):
		_fail("Citywide urban building cell did not load.")
		return
	var urban_buildings: Node3D = regional_urban.loaded_cells[building_cell]
	var overview_buildings := urban_buildings.find_children("OSMOverviewBuilding_*", "MeshInstance3D", true, false)
	if overview_buildings.is_empty():
		_fail("Citywide urban building footprints did not produce low-detail building meshes.")
		return
	var footprint_verified := false
	for building_mesh in overview_buildings:
		if str(building_mesh.get_meta("system_footprint_geometry", "")) == "osm_polygon_extrusion":
			footprint_verified = true
			break
	if not footprint_verified:
		_fail("Citywide urban buildings are not using their true OSM polygon footprints.")
		return
	regional_urban._load_cell(poi_cell)
	if not regional_urban.loaded_cells.has(poi_cell):
		_fail("Citywide urban POI cell did not load.")
		return
	var urban_pois: Node3D = regional_urban.loaded_cells[poi_cell]
	var poi_markers := urban_pois.find_children("OSMRegionalPOI_*", "Node3D", true, false)
	if poi_markers.is_empty():
		_fail("Citywide urban amenities did not produce POI markers.")
		return

	# Exercise every genuine religious polygon/multipolygon in all 925 regional cells.
	# The production cell loader builds the buildings layer first, then skips an
	# identical worship object from amenities by its OSM type/id. Reproduce that
	# exact ordering here, while checking every emitted mesh surface.
	var worship_instance_count := 0
	var worship_cross_layer_deduplicated := 0
	var worship_mosque_meshes := 0
	var worship_church_meshes := 0
	var worship_other_meshes := 0
	var worship_cell_count := 0
	for file_name in urban_files:
		if not file_name.ends_with(".json"):
			continue
		var tile_path := urban_cells_path.path_join(file_name)
		var worship_tile: Variant = JSON.parse_string(FileAccess.get_file_as_string(tile_path))
		if not worship_tile is Dictionary:
			_fail("Invalid Baghdad regional cell JSON during full worship polygon QA: " + file_name)
			return
		var worship_layers: Dictionary = worship_tile.get("layers", {})
		var building_features: Array = worship_layers.get("buildings", [])
		var amenity_features: Array = worship_layers.get("amenities", [])
		var building_feature_ids: Dictionary = {}
		for building_feature in building_features:
			var building_key := regional_urban._osm_feature_key(building_feature)
			if building_key != "":
				building_feature_ids[building_key] = true
		var cell_worship_features: Array[Dictionary] = []
		var cell_worship_from_buildings: Array[bool] = []
		for building_feature in building_features:
			if regional_urban._is_polygon_worship_feature(building_feature):
				cell_worship_features.append(building_feature)
				cell_worship_from_buildings.append(true)
		for amenity_feature in amenity_features:
			if not regional_urban._is_polygon_worship_feature(amenity_feature):
				continue
			var amenity_key := regional_urban._osm_feature_key(amenity_feature)
			if amenity_key != "" and building_feature_ids.has(amenity_key):
				worship_cross_layer_deduplicated += 1
				continue
			cell_worship_features.append(amenity_feature)
			cell_worship_from_buildings.append(false)
		if cell_worship_features.is_empty():
			continue
		worship_cell_count += 1
		for feature_index in range(cell_worship_features.size()):
			var worship_feature: Dictionary = cell_worship_features[feature_index]
			var feature_id := str(worship_feature.get("id", ""))
			var source_type := str(worship_feature.get("osm_type", ""))
			if feature_id == "" or source_type == "":
				_fail("A Baghdad worship polygon is missing its stable OSM type/id in " + file_name)
				return
			var worship_root := Node3D.new()
			var built_count := 0
			if cell_worship_from_buildings[feature_index]:
				built_count = regional_urban._build_building_overview_feature(worship_root, worship_feature)
			else:
				built_count = regional_urban._build_regional_poi_feature(worship_root, worship_feature)
			var worship_meshes := worship_root.find_children("OSMOverviewBuilding_*", "MeshInstance3D", true, false)
			var worship_markers := worship_root.find_children("OSMRegionalPOI_*", "Node3D", true, false)
			if built_count <= 0 or worship_meshes.size() != built_count:
				_fail("Baghdad worship polygon failed to create all expected footprint meshes: " + source_type + "/" + feature_id + " in " + file_name)
				worship_root.free()
				return
			if not worship_markers.is_empty():
				_fail("Baghdad worship polygon was downgraded or duplicated as a POI marker: " + source_type + "/" + feature_id)
				worship_root.free()
				return
			for worship_mesh in worship_meshes:
				if str(worship_mesh.get_meta("osm_feature_id", "")) != feature_id or str(worship_mesh.get_meta("system_osm_type", "")) != source_type:
					_fail("A worship footprint mesh lost its source OSM identity: " + source_type + "/" + feature_id)
					worship_root.free()
					return
				if str(worship_mesh.get_meta("system_geometry_type", "")) not in ["Polygon", "MultiPolygon"] or str(worship_mesh.get_meta("system_footprint_geometry", "")) != "osm_polygon_extrusion":
					_fail("A worship footprint did not retain its original polygon geometry: " + source_type + "/" + feature_id)
					worship_root.free()
					return
				if worship_mesh.mesh == null or worship_mesh.mesh.get_surface_count() == 0:
					_fail("A Baghdad worship footprint mesh has no renderable surface: " + source_type + "/" + feature_id)
					worship_root.free()
					return
				var facility_type := str(worship_mesh.get_meta("system_facility_type", ""))
				if facility_type == "mosque":
					worship_mosque_meshes += 1
				elif facility_type == "church":
					worship_church_meshes += 1
				else:
					worship_other_meshes += 1
			worship_instance_count += 1
			worship_root.free()
	if worship_instance_count < 150:
		_fail("Full Baghdad worship polygon QA found unexpectedly few runtime footprint instances: " + str(worship_instance_count))
		return
	if worship_cross_layer_deduplicated < 100:
		_fail("Full Baghdad worship QA did not exercise expected buildings/amenities OSM identity deduplication.")
		return
	if worship_mosque_meshes <= 0 or worship_church_meshes <= 0:
		_fail("Full Baghdad worship polygon QA must independently verify both mosque and church footprint meshes; mosques=" + str(worship_mosque_meshes) + " churches=" + str(worship_church_meshes))
		return
	print("Baghdad full worship polygon runtime QA passed: ", worship_instance_count,
		" unique cell-local polygon instances across ", worship_cell_count, " cells; cross-layer duplicates suppressed=", worship_cross_layer_deduplicated,
		"; classified mosque meshes=", worship_mosque_meshes, " church meshes=", worship_church_meshes,
		" other/unspecified worship meshes=", worship_other_meshes, ".")
	# Exercise real mesh construction for common OSM tagging variants. Each
	# synthetic polygon must become a footprint mesh, never a centroid POI.
	var synthetic_index := 0
	for synthetic_tags in [
		{"building": "public", "religion": "muslim"},
		{"building": "religious", "religion": "christian"},
		{"amenity": "place_of_worship", "religion": "muslim"},
		{"building": "chapel", "religion": "christian"},
		{"building": "cathedral", "religion": "christian"}
	]:
		var synthetic := {
			"id": "runtime_worship_%d" % synthetic_index,
			"osm_type": "way",
			"geometry": {"type": "Polygon", "coordinates": [[[0.0, 0.0], [4.0, 0.0], [4.0, 4.0], [0.0, 4.0], [0.0, 0.0]]]},
			"tags": synthetic_tags
		}
		var synthetic_root := Node3D.new()
		var synthetic_built := regional_urban._build_regional_poi_feature(synthetic_root, synthetic)
		var synthetic_meshes := synthetic_root.find_children("OSMOverviewBuilding_*", "MeshInstance3D", true, false)
		var synthetic_markers := synthetic_root.find_children("OSMRegionalPOI_*", "Node3D", true, false)
		if synthetic_built != 1 or synthetic_meshes.size() != 1 or not synthetic_markers.is_empty():
			_fail("A supported OSM worship polygon was downgraded to a point marker: " + str(synthetic_tags))
			synthetic_root.free()
			return
		if str(synthetic_meshes[0].get_meta("system_footprint_geometry", "")) != "osm_polygon_extrusion":
			_fail("Synthetic worship polygon did not preserve its actual footprint geometry.")
			synthetic_root.free()
			return
		synthetic_root.free()
		synthetic_index += 1
	print("Baghdad synthetic worship tagging QA passed: three OSM tagging variants generated polygon footprint meshes without POI duplication.")
	# Verify the expanded OSM amenity source categories render as typed POIs.
	var poi_cases := [
		{"tags": {"shop": "supermarket"}, "expected": "shop"},
		{"tags": {"tourism": "museum"}, "expected": "tourism"},
		{"tags": {"historic": "monument"}, "expected": "heritage"},
		{"tags": {"leisure": "park"}, "expected": "leisure"},
		{"tags": {"aeroway": "terminal"}, "expected": "transport"},
		{"tags": {"healthcare": "hospital"}, "expected": "healthcare"},
		{"tags": {"office": "government"}, "expected": "civic"}
	]
	for poi_case in poi_cases:
		var poi_root := Node3D.new()
		var poi_feature := {
			"id": "runtime_poi_" + str(poi_case.expected),
			"osm_type": "node",
			"geometry": {"type": "Point", "coordinates": [0.0, 0.0]},
			"tags": poi_case.tags
		}
		var poi_built := regional_urban._build_regional_poi_feature(poi_root, poi_feature)
		var typed_poi := poi_root.find_children("OSMRegionalPOI_*", "Node3D", true, false)
		if poi_built != 1 or typed_poi.size() != 1 or str(typed_poi[0].get_meta("system_facility_type", "")) != str(poi_case.expected):
			_fail("Expanded Baghdad POI category was not classified/rendered correctly: " + str(poi_case.tags))
			poi_root.free()
			return
		poi_root.free()
	print("Baghdad expanded OSM POI category QA passed: shops, tourism, heritage, leisure, aeroway, healthcare and civic offices.")
	print("Baghdad citywide urban overview passed: buildings=", overview_buildings.size(), " POI markers=", poi_markers.size(), " resolution=1 km.")
	regional_urban.queue_free()
	regional_roads.queue_free()
	streamer.queue_free()
	terrain.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
