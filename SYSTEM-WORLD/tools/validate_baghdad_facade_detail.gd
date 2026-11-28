extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var streamer_script := load("res://scripts/baghdad_osm_cell_streamer.gd") as Script
	if streamer_script == null:
		_fail("Baghdad OSM cell streamer script could not load.")
		return
	var streamer := streamer_script.new() as Node3D
	if streamer == null:
		_fail("Baghdad OSM cell streamer instance could not be created.")
		return
	streamer.name = "BaghdadFacadeDetailValidationStreamer"
	root.add_child(streamer)
	streamer.call("_create_materials")

	var feature := {
		"id": "facade_validation_apartment_001",
		"geometry": {
			"type": "Polygon",
			"coordinates": [[[0.0, 0.0], [24.0, 0.0], [24.0, 18.0], [0.0, 18.0], [0.0, 0.0]]]
		},
		"tags": {
			"building": "apartments",
			"height": "16",
			"building:levels": "5"
		}
	}
	var built := int(streamer.call("_build_building_feature", streamer, feature, []))
	if built != 1:
		_fail("Synthetic five-floor Baghdad apartment footprint did not build.")
		return

	# Inspect the generator's source transforms before they are packed into MultiMesh.
	# This avoids depending on renderer-side MultiMesh readback in headless CI.
	var generated_balconies: Array = streamer.get_meta("system_balcony_slab_transforms", [])
	var generated_balcony_rails: Array = streamer.get_meta("system_balcony_rail_transforms", [])
	if generated_balconies.is_empty() or generated_balconies.size() != generated_balcony_rails.size() or generated_balconies.size() > 16:
		_fail("Five-floor apartment must generate paired mobile-safe balcony slabs and rails.")
		return
	var generated_architecture: Array = streamer.get_meta("system_facade_architecture_transforms", [])
	if generated_architecture.is_empty() or generated_architecture.size() > 12:
		_fail("Modern apartment facade must generate 1..12 lightweight architectural fins/cornices.")
		return
	var generated_transforms: Array = streamer.get_meta("system_facade_window_transforms", [])
	if generated_transforms.is_empty() or generated_transforms.size() > 32:
		_fail("Generated facade transforms are outside the mobile-safe 1..32 per-building budget.")
		return
	var floor_levels: Array[float] = []
	var floor_instance_counts: Array[int] = []
	for generated_transform in generated_transforms:
		if not generated_transform is Transform3D:
			_fail("Facade generator emitted a non-Transform3D window instance.")
			return
		var window_y: float = generated_transform.origin.y
		var matched_floor := -1
		for floor_index in range(floor_levels.size()):
			if absf(window_y - floor_levels[floor_index]) <= 0.75:
				matched_floor = floor_index
				break
		if matched_floor < 0:
			floor_levels.append(window_y)
			floor_instance_counts.append(1)
		else:
			floor_instance_counts[matched_floor] += 1
	if floor_levels.size() != 5:
		_fail("Five-floor apartment must generate five distinct facade window bands; found %d." % floor_levels.size())
		return
	for floor_index in range(floor_instance_counts.size()):
		if floor_instance_counts[floor_index] < 3:
			_fail("Five-floor apartment facade coverage is incomplete on vertical band %d." % (floor_index + 1))
			return

	streamer.call("_flush_facade_window_multimesh", streamer)
	streamer.call("_flush_apartment_balcony_multimeshes", streamer)
	streamer.call("_flush_facade_architecture_multimesh", streamer)
	var balcony_slabs := streamer.get_node_or_null("BaghdadCellApartmentBalconySlabs") as MultiMeshInstance3D
	var balcony_rails := streamer.get_node_or_null("BaghdadCellApartmentBalconyRails") as MultiMeshInstance3D
	if balcony_slabs == null or balcony_rails == null or balcony_slabs.multimesh == null or balcony_rails.multimesh == null:
		_fail("Apartment facade balcony slab/rail MultiMeshes are missing.")
		return
	if balcony_slabs.multimesh.instance_count != generated_balconies.size() or balcony_rails.multimesh.instance_count != generated_balcony_rails.size():
		_fail("Apartment facade balcony MultiMesh counts do not match generated transforms.")
		return
	if str(balcony_slabs.get_meta("system_facade_detail_type", "")) != "apartment_balcony_slabs" or str(balcony_rails.get_meta("system_facade_detail_type", "")) != "apartment_balcony_rails":
		_fail("Apartment facade balcony resources are missing their distinct detail classifications.")
		return
	var building := streamer.get_node_or_null("OSMBuilding_apartment_block_facade_validation_apartment_001") as MeshInstance3D
	var windows := streamer.get_node_or_null("BaghdadCellFacadeWindows") as MultiMeshInstance3D
	if building == null or windows == null or windows.multimesh == null:
		_fail("High-detail apartment is missing its instanced facade-window resource.")
		return
	var architecture := streamer.get_node_or_null("BaghdadCellModernFacadeArchitecture") as MultiMeshInstance3D
	if architecture == null or architecture.multimesh == null or architecture.multimesh.instance_count != generated_architecture.size():
		_fail("Modern facade architecture MultiMesh does not preserve the generated trim instances.")
		return
	if str(architecture.get_meta("system_facade_detail_type", "")) != "modern_architectural_fins_and_cornices" or int(architecture.get_meta("system_facade_architecture_draw_calls_per_cell", 0)) != 1:
		_fail("Modern facade architecture is missing its mobile-safe single-draw-call classification.")
		return
	var window_count := windows.multimesh.instance_count
	if window_count != generated_transforms.size():
		_fail("Packed MultiMesh instance count does not match the generated facade transforms.")
		return
	if int(building.get_meta("system_facade_window_count", 0)) != window_count:
		_fail("Building facade metadata does not match the MultiMesh instance count.")
		return
	if str(windows.get_meta("system_facade_detail_type", "")) != "procedural_instanced_windows":
		_fail("Facade window MultiMesh is missing its detail classification.")
		return
	if str(windows.get_meta("system_facade_window_sampling", "")) != "even_distribution_across_facades":
		_fail("Facade windows were not sampled evenly across the building sides.")
		return
	if int(windows.get_meta("system_facade_window_draw_calls_per_cell", 0)) != 1:
		_fail("Facade windows are not aggregated into one MultiMesh draw call per cell.")
		return
	if not windows.multimesh.use_colors:
		_fail("Facade MultiMesh must retain per-window cool/warm color variation.")
		return

	var overview_parent := Node3D.new()
	overview_parent.name = "BaghdadRegionalOverviewValidation"
	root.add_child(overview_parent)
	var overview_built := int(streamer.call("_build_building_overview_feature", overview_parent, feature))
	if overview_built != 1 or overview_parent.get_child_count() != 1 or overview_parent.get_child(0) is MultiMeshInstance3D:
		_fail("The 1 km regional overview must remain a low-cost extrusion LOD without facade windows.")
		return
	var overview_building := overview_parent.get_child(0) as MeshInstance3D
	if overview_building == null or str(overview_building.get_meta("system_facade_detail_level", "")) != "regional_extrusion_lod":
		_fail("Regional overview building is missing its explicit low-detail facade classification.")
		return
	if str(overview_building.get_meta("system_footprint_geometry", "")) != "osm_polygon_extrusion":
		_fail("Regional overview must preserve the mapped OSM building footprint extrusion.")
		return

	# Luxury residential footprints must get a distinct road-facing entry treatment
	# in the 200 m close-range renderer, not only a different material tint.
	var villa_feature := {
		"id": "facade_validation_villa_001",
		"geometry": {
			"type": "Polygon",
			"coordinates": [[[40.0, 0.0], [60.0, 0.0], [60.0, 20.0], [40.0, 20.0], [40.0, 0.0]]]
		},
		"tags": {
			"building": "villa",
			"height": "9",
			"name:ar": "فيلا اختبار الواجهة"
		}
	}
	var nearby_road := [{
		"id": "facade_validation_road_001",
		"geometry": {"type": "LineString", "coordinates": [[20.0, 10.0], [35.0, 10.0]]},
		"tags": {"highway": "residential"}
	}]
	var villa_built := int(streamer.call("_build_building_feature", streamer, villa_feature, nearby_road))
	if villa_built != 1:
		_fail("Synthetic Baghdad villa footprint did not build.")
		return
	var villa_entrance := streamer.get_node_or_null("LuxuryResidentialEntrance_facade_validation_villa_001") as Node3D
	if villa_entrance == null or str(villa_entrance.get_meta("system_luxury_building_kind", "")) != "villa":
		_fail("Close-range villa renderer did not create its distinct road-facing entrance treatment.")
		return
	if streamer.get_node_or_null("LuxuryEntryColumn_facade_validation_villa_001_L") == null or streamer.get_node_or_null("LuxuryEntryColumn_facade_validation_villa_001_R") == null:
		_fail("Villa entrance is missing its paired architectural columns.")
		return
	if streamer.get_node_or_null("LuxuryEntryLintel_facade_validation_villa_001") == null or streamer.get_node_or_null("LuxuryEntryCanopy_facade_validation_villa_001") == null:
		_fail("Villa entrance is missing its lintel or covered entry canopy.")
		return

	var palace_feature := {
		"id": "facade_validation_palace_001",
		"geometry": {
			"type": "Polygon",
			"coordinates": [[[80.0, 0.0], [112.0, 0.0], [112.0, 26.0], [80.0, 26.0], [80.0, 0.0]]]
		},
		"tags": {
			"building": "palace",
			"height": "18",
			"name:ar": "قصر اختبار الواجهة"
		}
	}
	var palace_road := [{
		"id": "facade_validation_palace_road_001",
		"geometry": {"type": "LineString", "coordinates": [[60.0, 13.0], [75.0, 13.0]]},
		"tags": {"highway": "tertiary"}
	}]
	var palace_built := int(streamer.call("_build_building_feature", streamer, palace_feature, palace_road))
	if palace_built != 1:
		_fail("Synthetic Baghdad palace footprint did not build.")
		return
	var palace_entrance := streamer.get_node_or_null("LuxuryResidentialEntrance_facade_validation_palace_001") as Node3D
	if palace_entrance == null or str(palace_entrance.get_meta("system_luxury_building_kind", "")) != "palace":
		_fail("Close-range palace renderer did not create its distinct road-facing entrance treatment.")
		return
	if streamer.get_node_or_null("LuxuryEntryColumn_facade_validation_palace_001_L") == null or streamer.get_node_or_null("LuxuryEntryCanopy_facade_validation_palace_001") == null:
		_fail("Palace entrance is missing its architectural columns or covered entry canopy.")
		return

	# Polygon worship features in the 1 km regional layer must keep their
	# mapped footprints and get the correct religious building class.
	var worship_parent := Node3D.new()
	worship_parent.name = "WorshipPolygonValidation"
	streamer.add_child(worship_parent)
	var mosque_polygon := {
		"id": "worship_validation_mosque_001",
		"geometry": {"type": "Polygon", "coordinates": [[[140.0, 0.0], [160.0, 0.0], [160.0, 16.0], [140.0, 16.0], [140.0, 0.0]]]},
		"tags": {"amenity": "place_of_worship", "religion": "muslim", "name:ar": "جامع اختبار"}
	}
	var mosque_polygon_built := int(streamer.call("_build_regional_poi_feature", worship_parent, mosque_polygon))
	var mosque_mesh := worship_parent.get_node_or_null("OSMOverviewBuilding_worship_validation_mosque_001") as MeshInstance3D
	var mosque_detail := worship_parent.get_node_or_null("OSMWorshipDetail_mosque_worship_validation_mosque_001") as Node3D
	if mosque_polygon_built != 1 or mosque_mesh == null or str(mosque_mesh.get_meta("system_facility_type", "")) != "mosque":
		_fail("Regional mosque polygon was not built as a mapped-footprint mosque.")
		return
	var mosque_minarets := mosque_detail.find_children("Minaret_*", "MeshInstance3D", true, false) if mosque_detail != null else []
	if mosque_detail == null or mosque_detail.get_node_or_null("RoofDome") == null or mosque_minarets.is_empty():
		_fail("Regional mosque polygon is missing its dome/minaret silhouette details.")
		return

	var church_polygon := {
		"id": "worship_validation_church_001",
		"geometry": {"type": "Polygon", "coordinates": [[[180.0, 0.0], [198.0, 0.0], [198.0, 14.0], [180.0, 14.0], [180.0, 0.0]]]},
		"tags": {"amenity": "place_of_worship", "religion": "christianity", "name:ar": "كنيسة اختبار"}
	}
	var church_polygon_built := int(streamer.call("_build_regional_poi_feature", worship_parent, church_polygon))
	var church_mesh := worship_parent.get_node_or_null("OSMOverviewBuilding_worship_validation_church_001") as MeshInstance3D
	var church_detail := worship_parent.get_node_or_null("OSMWorshipDetail_church_worship_validation_church_001") as Node3D
	if church_polygon_built != 1 or church_mesh == null or str(church_mesh.get_meta("system_facility_type", "")) != "church":
		_fail("Regional Christian worship polygon was not built as a mapped-footprint church.")
		return
	if church_detail == null or church_detail.get_node_or_null("ChurchBellTower") == null or church_detail.get_node_or_null("ChurchCross") == null:
		_fail("Regional church polygon is missing its bell-tower/cross silhouette details.")
		return

	# OSM also contains buildings tagged directly as mosque/church without
	# amenity=place_of_worship, and point nodes using religion=islam.
	var mosque_building_only := {
		"id": "worship_validation_mosque_building_only_001",
		"geometry": {"type": "Polygon", "coordinates": [[[210.0, 0.0], [226.0, 0.0], [226.0, 14.0], [210.0, 14.0], [210.0, 0.0]]]},
		"tags": {"building": "mosque", "name:ar": "مسجد بوسم المبنى فقط"}
	}
	var mosque_building_built := int(streamer.call("_build_regional_poi_feature", worship_parent, mosque_building_only))
	var mosque_building_mesh := worship_parent.get_node_or_null("OSMOverviewBuilding_worship_validation_mosque_building_only_001") as MeshInstance3D
	if mosque_building_built != 1 or mosque_building_mesh == null or str(mosque_building_mesh.get_meta("system_facility_type", "")) != "mosque":
		_fail("A building=mosque polygon without amenity tags was not classified as a mosque.")
		return

	var mosque_point := {
		"id": "worship_validation_mosque_islam_point_001",
		"geometry": {"type": "Point", "coordinates": [230.0, 12.0]},
		"tags": {"amenity": "place_of_worship", "religion": "islam", "name:ar": "نقطة مسجد اختبار"}
	}
	var mosque_point_built := int(streamer.call("_build_regional_poi_feature", worship_parent, mosque_point))
	var mosque_point_marker := worship_parent.get_node_or_null("OSMRegionalPOI_mosque_worship_validation_mosque_islam_point_001") as Node3D
	if mosque_point_built != 1 or mosque_point_marker == null or str(mosque_point_marker.get_meta("system_facility_type", "")) != "mosque":
		_fail("A point place_of_worship with religion=islam was not classified as a mosque.")
		return

	var unclassified_worship_point := {
		"id": "worship_validation_unspecified_point_001",
		"geometry": {"type": "Point", "coordinates": [234.0, 12.0]},
		"tags": {"amenity": "place_of_worship", "name:ar": "دار عبادة غير محددة"}
	}
	var unspecified_built := int(streamer.call("_build_regional_poi_feature", worship_parent, unclassified_worship_point))
	var unspecified_marker := worship_parent.get_node_or_null("OSMRegionalPOI_place_of_worship_worship_validation_unspecified_point_001") as Node3D
	if unspecified_built != 1 or unspecified_marker == null or str(unspecified_marker.get_meta("system_facility_type", "")) != "place_of_worship":
		_fail("Unspecified place_of_worship points must remain neutral instead of being mislabeled as a mosque or church.")
		return

	# Neutral worship polygons retain their actual OSM footprint without an
	# invented mosque/church silhouette when religion/building tags are absent.
	var neutral_worship_polygon := {
		"id": "worship_validation_neutral_polygon_001",
		"geometry": {"type": "Polygon", "coordinates": [[[240.0, 0.0], [254.0, 0.0], [254.0, 12.0], [240.0, 12.0], [240.0, 0.0]]]},
		"tags": {"amenity": "place_of_worship", "name:ar": "دار عبادة محايدة"}
	}
	var neutral_polygon_built := int(streamer.call("_build_regional_poi_feature", worship_parent, neutral_worship_polygon))
	var neutral_polygon_mesh := worship_parent.get_node_or_null("OSMOverviewBuilding_worship_validation_neutral_polygon_001") as MeshInstance3D
	if neutral_polygon_built != 1 or neutral_polygon_mesh == null or str(neutral_polygon_mesh.get_meta("system_facility_type", "")) != "place_of_worship":
		_fail("Unclassified worship polygon did not preserve its mapped footprint as a neutral religious building.")
		return
	if str(neutral_polygon_mesh.get_meta("system_footprint_geometry", "")) != "osm_polygon_extrusion":
		_fail("Neutral worship polygon lost its OSM footprint geometry.")
		return
	if worship_parent.get_node_or_null("OSMWorshipDetail_mosque_worship_validation_neutral_polygon_001") != null or worship_parent.get_node_or_null("OSMWorshipDetail_church_worship_validation_neutral_polygon_001") != null:
		_fail("Neutral worship polygon received an invented mosque or church silhouette.")
		return

	# Conflicting OSM tags are surfaced as conflicts and receive no invented
	# religious silhouette until their source classification is reviewed.
	var conflicting_worship_polygon := {
		"id": "worship_validation_conflict_polygon_001",
		"geometry": {"type": "Polygon", "coordinates": [[[260.0, 0.0], [274.0, 0.0], [274.0, 12.0], [260.0, 12.0], [260.0, 0.0]]]},
		"tags": {"amenity": "place_of_worship", "religion": "muslim", "building": "church", "name:ar": "دار عبادة متعارضة"}
	}
	var conflict_polygon_built := int(streamer.call("_build_regional_poi_feature", worship_parent, conflicting_worship_polygon))
	var conflict_polygon_mesh := worship_parent.get_node_or_null("OSMOverviewBuilding_worship_validation_conflict_polygon_001") as MeshInstance3D
	if conflict_polygon_built != 1 or conflict_polygon_mesh == null or str(conflict_polygon_mesh.get_meta("system_facility_type", "")) != "religious_tag_conflict":
		_fail("Conflicting OSM worship tags were not isolated for review.")
		return
	if worship_parent.get_node_or_null("OSMWorshipDetail_mosque_worship_validation_conflict_polygon_001") != null or worship_parent.get_node_or_null("OSMWorshipDetail_church_worship_validation_conflict_polygon_001") != null:
		_fail("Conflicting OSM worship tags received an unsupported mosque/church silhouette.")
		return

	# Shrine/mausoleum footprints are a distinct religious building class,
	# not mosque or church geometry; preserve the mapped polygon as-is.
	var shrine_polygon := {
		"id": "worship_validation_shrine_polygon_001",
		"geometry": {"type": "Polygon", "coordinates": [[[280.0, 0.0], [296.0, 0.0], [296.0, 12.0], [280.0, 12.0], [280.0, 0.0]]]},
		"tags": {"building": "shrine", "religion": "muslim", "name:ar": "مرقد اختبار"}
	}
	var shrine_built := int(streamer.call("_build_regional_poi_feature", worship_parent, shrine_polygon))
	var shrine_mesh := worship_parent.get_node_or_null("OSMOverviewBuilding_worship_validation_shrine_polygon_001") as MeshInstance3D
	if shrine_built != 1 or shrine_mesh == null or str(shrine_mesh.get_meta("system_facility_type", "")) != "shrine":
		_fail("A mapped building=shrine polygon was not preserved as a distinct shrine feature.")
		return
	if str(shrine_mesh.get_meta("system_footprint_geometry", "")) != "osm_polygon_extrusion" or str(shrine_mesh.get_meta("baghdad_building_type", "")) != "shrine":
		_fail("Shrine footprint was not kept as its own mapped building class.")
		return
	if worship_parent.get_node_or_null("OSMWorshipDetail_mosque_worship_validation_shrine_polygon_001") != null or worship_parent.get_node_or_null("OSMWorshipDetail_church_worship_validation_shrine_polygon_001") != null:
		_fail("Shrine polygon received an unsupported mosque or church silhouette.")
		return

	# Monastery polygons are preserved separately from churches and shrines.
	var monastery_polygon := {
		"id": "worship_validation_monastery_polygon_001",
		"geometry": {"type": "Polygon", "coordinates": [[[300.0, 0.0], [316.0, 0.0], [316.0, 12.0], [300.0, 12.0], [300.0, 0.0]]]},
		"tags": {"amenity": "monastery", "religion": "christian", "name:ar": "دير اختبار"}
	}
	var monastery_built := int(streamer.call("_build_regional_poi_feature", worship_parent, monastery_polygon))
	var monastery_mesh := worship_parent.get_node_or_null("OSMOverviewBuilding_worship_validation_monastery_polygon_001") as MeshInstance3D
	if monastery_built != 1 or monastery_mesh == null or str(monastery_mesh.get_meta("system_facility_type", "")) != "monastery":
		_fail("A mapped monastery polygon was not preserved as a distinct monastery feature.")
		return
	if str(monastery_mesh.get_meta("system_footprint_geometry", "")) != "osm_polygon_extrusion" or str(monastery_mesh.get_meta("baghdad_building_type", "")) != "monastery":
		_fail("Monastery footprint was not kept as its own mapped building class.")
		return
	if worship_parent.get_node_or_null("OSMWorshipDetail_mosque_worship_validation_monastery_polygon_001") != null or worship_parent.get_node_or_null("OSMWorshipDetail_church_worship_validation_monastery_polygon_001") != null:
		_fail("Monastery polygon received an unsupported mosque or church silhouette.")
		return

	# Road details must honor explicit OSM sidewalk sides and lit-road tags,
	# while keeping inferred lamp positions clearly distinct from surveyed POIs.
	var road_detail_feature := {
		"id": "road_detail_validation_001",
		"geometry": {"type": "LineString", "coordinates": [[0.0, 80.0], [96.0, 80.0]]},
		"tags": {"highway": "primary", "sidewalk": "both", "lit": "yes"}
	}
	var road_detail_built := int(streamer.call("_build_line_feature", streamer, road_detail_feature, 8.5, streamer.get("road_material"), 0.16, "OSMRoad"))
	if road_detail_built != 1:
		_fail("Synthetic mapped Baghdad road did not build for sidewalk/lighting validation.")
		return
	var sidewalk_transforms: Array = streamer.get_meta("system_sidewalk_transforms", [])
	var pole_transforms: Array = streamer.get_meta("system_streetlight_pole_transforms", [])
	var arm_transforms: Array = streamer.get_meta("system_streetlight_arm_transforms", [])
	var head_transforms: Array = streamer.get_meta("system_streetlight_head_transforms", [])
	if sidewalk_transforms.size() != 2:
		_fail("OSM sidewalk=both must generate exactly two side-specific sidewalk segments.")
		return
	if pole_transforms.is_empty() or pole_transforms.size() != arm_transforms.size() or pole_transforms.size() != head_transforms.size() or pole_transforms.size() > 36:
		_fail("OSM lit=yes road must generate paired, mobile-budgeted streetlight poles, arms and heads.")
		return
	streamer.call("_flush_sidewalk_multimesh", streamer)
	streamer.call("_flush_streetlight_multimeshes", streamer)
	var sidewalks := streamer.get_node_or_null("BaghdadCellMappedSidewalks") as MultiMeshInstance3D
	var lamp_poles := streamer.get_node_or_null("BaghdadCellStreetlightPoles") as MultiMeshInstance3D
	var lamp_arms := streamer.get_node_or_null("BaghdadCellStreetlightArms") as MultiMeshInstance3D
	var lamp_heads := streamer.get_node_or_null("BaghdadCellStreetlightHeads") as MultiMeshInstance3D
	if sidewalks == null or sidewalks.multimesh == null or sidewalks.multimesh.instance_count != sidewalk_transforms.size():
		_fail("Mapped Baghdad sidewalks were not packed into the expected single MultiMesh.")
		return
	if lamp_poles == null or lamp_arms == null or lamp_heads == null:
		_fail("Inferred streetlight fixture meshes are incomplete.")
		return
	if lamp_poles.multimesh.instance_count != pole_transforms.size() or lamp_arms.multimesh.instance_count != arm_transforms.size() or lamp_heads.multimesh.instance_count != head_transforms.size():
		_fail("Streetlight MultiMesh instance counts do not match their source transforms.")
		return
	if str(lamp_poles.get_meta("system_streetlight_source", "")) != "inferred_spacing_from_osm_lit_yes_not_surveyed_fixture":
		_fail("Streetlights must disclose that their spacing is inferred from lit=yes, not mapped fixture coordinates.")
		return
	var one_side_feature := {
		"id": "road_detail_validation_left_only",
		"geometry": {"type": "LineString", "coordinates": [[0.0, 100.0], [24.0, 100.0]]},
		"tags": {"highway": "tertiary", "sidewalk": "left"}
	}
	streamer.set_meta("system_sidewalk_transforms", [])
	streamer.call("_collect_sidewalk_transforms", streamer, PackedVector2Array([Vector2(0.0, 100.0), Vector2(24.0, 100.0)]), 6.0, one_side_feature["tags"], 0.16)
	var left_only_transforms: Array = streamer.get_meta("system_sidewalk_transforms", [])
	if left_only_transforms.size() != 1:
		_fail("OSM sidewalk=left must not invent a sidewalk on the right side.")
		return

	print("Baghdad facade detail validation passed: ", window_count,
		" instanced windows across five vertical facade bands; regional 1 km OSM footprints preserve mosque/church silhouettes, neutral worship polygons, isolated tag conflicts, shrine and monastery classes; close-range villa and palace include road-facing columned entry canopies; per-building window budget <= 32.")
	# Do not force dummy-renderer teardown in this Godot 4.3 geometry unit test.
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad facade detail validation failed: " + message)
	quit(1)
