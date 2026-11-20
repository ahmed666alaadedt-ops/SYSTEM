extends Node3D
class_name SYSTEMPublicEventBoard

## Local-session public display prototype. Results are emitted only after the
## existing gameplay managers report a completed event. Cross-player champions
## require a future authoritative online service; this node does not claim that.

const MAX_VISIBLE_RESULTS := 4
const MAX_STORED_RESULTS := 40
const SAVE_PATH := "user://system_public_event_results.cfg"

var terrain: Node
var city_anchors: Dictionary = {}
var result_labels: Dictionary = {}
var results: Array[Dictionary] = []
var ad_labels: Array[Label3D] = []


func setup(anchors: Dictionary, terrain_manager: Node) -> void:
	_load_results()
	city_anchors = anchors.duplicate(true)
	terrain = terrain_manager
	_build_city_media_displays()
	_build_baghdad_tower_displays()


func publish_gate_clear(gate_id: String, gate_rank: String, xp_awarded: int) -> void:
	_publish_result(
		"بوابة وحوش",
		"إنجاز بوابة %s" % gate_rank,
		"تم تطهير %s — %d XP" % [gate_id, xp_awarded]
	)


func publish_mission_completion(mission_id: String, xp_awarded: int) -> void:
	_publish_result(
		"مهمة مكتملة",
		"إنجاز مهمة نقابة الصيادين",
		"%s — %d XP" % [mission_id, xp_awarded]
	)


func publish_exam_stage(stage_id: String, stage_number: int) -> void:
	_publish_result(
		"اختبار الصيادين",
		"اجتياز المرحلة %d من 7" % stage_number,
		stage_id
	)


func publish_exam_champion(candidate_number: int, license_rank: String) -> void:
	_publish_result(
		"بطل اختبار الصيادين",
		"الصياد رقم %d" % candidate_number,
		"الرتبة: %s — أكمل جميع المراحل" % license_rank
	)


func publish_power_tower_clear(floor_number: int, rank: String) -> void:
	_publish_result(
		"برج القوة",
		"إنجاز الطابق %d" % floor_number,
		"التصنيف: %s" % rank
	)


func _publish_result(category: String, headline: String, detail: String) -> void:
	var record := {
		"category": category,
		"headline": headline,
		"detail": detail,
		"display_name": "SYSTEM HUNTER",
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"verification": "LOCAL_GAMEPLAY_EVENT"
	}
	results.push_front(record)
	while results.size() > MAX_STORED_RESULTS:
		results.pop_back()
	_save_results()
	_refresh_result_displays()
	print("SYSTEM PUBLIC BOARD: ", category, " — ", headline)


func _build_city_media_displays() -> void:
	var frame_material := _make_material(Color(0.035, 0.055, 0.085), 0.25, 0.5)
	var ad_material := _make_material(Color(0.025, 0.16, 0.22), 0.18, 0.35)
	var result_material := _make_material(Color(0.10, 0.075, 0.025), 0.2, 0.45)
	var building_material := _make_material(Color(0.075, 0.095, 0.13), 0.82, 0.38)
	ad_material.emission_enabled = true
	ad_material.emission = Color(0.02, 0.32, 0.48)
	ad_material.emission_energy_multiplier = 1.25
	result_material.emission_enabled = true
	result_material.emission = Color(0.48, 0.28, 0.045)
	result_material.emission_energy_multiplier = 1.0

	for city_value in city_anchors.keys():
		var city_name := str(city_value)
		var anchor: Vector2 = city_anchors[city_name]
		var placement := anchor + Vector2(24.0, -30.0)
		if is_instance_valid(terrain) and terrain.has_method("is_land_position"):
			if not bool(terrain.call("is_land_position", placement.x, placement.y)):
				var region_manager := get_parent()
				if region_manager.has_method("_nearest_land_position"):
					placement = region_manager.call("_nearest_land_position", placement)
				if placement == Vector2.INF:
					continue
		var ground := _ground_height(placement)
		var display_root := Node3D.new()
		display_root.name = "PublicMediaTower_" + city_name.replace(" ", "")
		display_root.position = Vector3(placement.x, ground, placement.y)
		add_child(display_root)

		_add_skyscraper(display_root, building_material, frame_material)
		_add_screen(display_root, "AdvertisingPanel", Vector3(0.0, 31.0, -9.55), Vector3(15.0, 8.0, 0.8), ad_material, frame_material)
		_add_screen(display_root, "ChampionResultsPanel", Vector3(0.0, 41.0, -9.55), Vector3(15.0, 8.0, 0.8), result_material, frame_material)

		var ad_label := Label3D.new()
		ad_label.name = "CuratedCampaignText"
		ad_label.text = "SYSTEM CITY — " + city_name + "\nحملة تجريبية | مساحة إعلانية رقمية"
		ad_label.position = Vector3(0.0, 31.0, -10.02)
		ad_label.font_size = 42
		ad_label.pixel_size = 0.012
		ad_label.modulate = Color(0.78, 0.96, 1.0)
		ad_label.outline_size = 8
		display_root.add_child(ad_label)
		ad_labels.append(ad_label)
		display_root.set_meta("advertising_mode", "curated_demo")
		display_root.set_meta("live_ads_enabled", false)
		display_root.set_meta("city", city_name)

		var result_label := Label3D.new()
		result_label.name = "VerifiedEventResultsText"
		result_label.text = "SYSTEM CHAMPIONS\nبانتظار أول إنجاز موثق\nالنتائج محلية لهذه الجلسة"
		result_label.position = Vector3(0.0, 41.0, -10.02)
		result_label.font_size = 29
		result_label.pixel_size = 0.014
		result_label.modulate = Color(1.0, 0.88, 0.55)
		result_label.outline_size = 7
		display_root.add_child(result_label)
		result_labels[city_name] = result_label
	_refresh_result_displays()


func _build_baghdad_tower_displays() -> void:
	var tower_manager := get_parent().get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager == null or not tower_manager.has_method("get_tower_positions"):
		return
	var frame_material := _make_material(Color(0.035, 0.055, 0.085), 0.25, 0.5)
	var ad_material := _make_material(Color(0.025, 0.16, 0.22), 0.18, 0.35)
	var result_material := _make_material(Color(0.10, 0.075, 0.025), 0.2, 0.45)
	ad_material.emission_enabled = true
	ad_material.emission = Color(0.02, 0.32, 0.48)
	ad_material.emission_energy_multiplier = 1.2
	result_material.emission_enabled = true
	result_material.emission = Color(0.48, 0.28, 0.045)
	result_material.emission_energy_multiplier = 1.0
	var tower_nodes := {
		"hunter_association_tower_baghdad": "HunterAssociationTower",
		"power_tower_baghdad": "PowerTower",
		"business_tower_baghdad": "BusinessTower",
		"shopping_tower_baghdad": "ShoppingTower",
		"entertainment_tower_baghdad": "EntertainmentTower"
	}
	var tower_records: Array = tower_manager.call("get_tower_positions")
	for record_value in tower_records:
		if typeof(record_value) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_value
		var tower_id := str(record.get("id", ""))
		var node_name := str(tower_nodes.get(tower_id, ""))
		var tower := tower_manager.get_node_or_null(node_name) as Node3D
		if tower == null:
			continue
		var tower_height := float(record.get("height", 160.0))
		var tower_radius := float(record.get("radius", 24.0))
		var panel_width := clampf(tower_radius * 1.55, 24.0, 58.0)
		var panel_height := panel_width * 0.43
		var panel_y := clampf(tower_height * 0.58, 48.0, maxf(50.0, tower_height - panel_height * 2.2))
		var panel_size := Vector3(panel_width, panel_height, 0.9)
		_add_screen(tower, "TowerAdvertisingPanel", Vector3(0.0, panel_y + panel_height + 1.5, tower_radius + 0.55), panel_size, ad_material, frame_material)
		_add_screen(tower, "TowerChampionPanel", Vector3(0.0, panel_y, tower_radius + 0.55), panel_size, result_material, frame_material)
		var ad_label := Label3D.new()
		ad_label.name = "TowerCampaignText"
		ad_label.text = "SYSTEM BAGHDAD\nحملة تجريبية — مساحة إعلانية"
		ad_label.position = Vector3(0.0, panel_y + panel_height + 1.5, tower_radius + 1.08)
		ad_label.font_size = 32
		ad_label.pixel_size = 0.012
		ad_label.modulate = Color(0.78, 0.96, 1.0)
		ad_label.outline_size = 7
		tower.add_child(ad_label)
		var result_label := Label3D.new()
		result_label.name = "TowerChampionResultsText"
		result_label.text = "SYSTEM CHAMPIONS\nبانتظار أول إنجاز موثق\nسجل محلي لهذه الجلسة"
		result_label.position = Vector3(0.0, panel_y, tower_radius + 1.08)
		result_label.font_size = 28
		result_label.pixel_size = 0.012
		result_label.modulate = Color(1.0, 0.88, 0.55)
		result_label.outline_size = 7
		tower.add_child(result_label)
		result_labels["Baghdad Tower " + tower_id] = result_label
	_refresh_result_displays()


func _add_skyscraper(parent: Node3D, building_material: Material, trim_material: Material) -> void:
	var tower := MeshInstance3D.new()
	tower.name = "AdvertisingSkyscraperFacade"
	var tower_mesh := BoxMesh.new()
	tower_mesh.size = Vector3(22.0, 82.0, 18.0)
	tower.mesh = tower_mesh
	tower.position = Vector3(0.0, 41.0, 0.0)
	tower.material_override = building_material
	parent.add_child(tower)
	for side in [-1.0, 1.0]:
		var fin := MeshInstance3D.new()
		fin.name = "FacadeVerticalFin"
		var fin_mesh := BoxMesh.new()
		fin_mesh.size = Vector3(0.45, 78.0, 0.55)
		fin.mesh = fin_mesh
		fin.position = Vector3(side * 10.3, 41.0, -9.2)
		fin.material_override = trim_material
		parent.add_child(fin)
	for level in range(10):
		var band := MeshInstance3D.new()
		band.name = "FacadeWindowBand_%02d" % level
		var band_mesh := BoxMesh.new()
		band_mesh.size = Vector3(20.0, 0.22, 0.12)
		band.mesh = band_mesh
		band.position = Vector3(0.0, 5.0 + float(level) * 7.5, -9.12)
		band.material_override = trim_material
		parent.add_child(band)


func _load_results() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Array = config.get_value("public_board", "results", [])
	results.clear()
	for value in saved:
		if typeof(value) == TYPE_DICTIONARY:
			results.append(value.duplicate(true))
	while results.size() > MAX_STORED_RESULTS:
		results.pop_back()


func _save_results() -> void:
	var config := ConfigFile.new()
	config.set_value("public_board", "results", results)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM: Public event results could not be saved.")


func _add_screen(parent: Node3D, node_name: String, location: Vector3, size: Vector3, surface_material: Material, frame_material: Material) -> void:
	var frame := MeshInstance3D.new()
	frame.name = node_name + "Frame"
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = size
	frame.mesh = frame_mesh
	frame.position = location
	frame.material_override = frame_material
	parent.add_child(frame)

	var surface := MeshInstance3D.new()
	surface.name = node_name + "Surface"
	var surface_mesh := BoxMesh.new()
	surface_mesh.size = Vector3(size.x - 0.8, size.y - 0.8, 0.12)
	surface.mesh = surface_mesh
	surface.position = location + Vector3(0.0, 0.0, -0.48)
	surface.material_override = surface_material
	parent.add_child(surface)


func _add_support(parent: Node3D, location: Vector3, size: Vector3, material: Material) -> void:
	var support := MeshInstance3D.new()
	support.name = "MediaTowerSupport"
	var mesh := BoxMesh.new()
	mesh.size = size
	support.mesh = mesh
	support.position = location
	support.material_override = material
	parent.add_child(support)


func _ground_height(point: Vector2) -> float:
	if is_instance_valid(terrain) and terrain.has_method("get_terrain_height"):
		return float(terrain.call("get_terrain_height", point.x, point.y))
	return 0.0


func _refresh_result_displays() -> void:
	var lines: Array[String] = ["SYSTEM CHAMPIONS"]
	if results.is_empty():
		lines.append("بانتظار أول إنجاز موثق")
	else:
		for index in range(mini(results.size(), MAX_VISIBLE_RESULTS)):
			var record: Dictionary = results[index]
			lines.append("%d. %s" % [index + 1, str(record.get("headline", ""))])
			lines.append(str(record.get("detail", "")))
	lines.append("سجل محلي — ليس ترتيباً عالمياً")
	var text_value := "\n".join(lines)
	for label_value in result_labels.values():
		var label := label_value as Label3D
		if is_instance_valid(label):
			label.text = text_value


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
