extends Node3D
class_name SYSTEMCityAdvertisingManager

## شبكة إعلانات حضرية موحدة: لوحات الشوارع ونقاط الخريطة والإعلانات التفاعلية.
## الحملات الحالية بيانات تجريبية محلية؛ لا توجد منصة شراء إعلانات أو اتصال بخادم خارجي.

const CAMPAIGNS: Array[Dictionary] = [
	{"id":"hunter_trials","category":"نقابة الصيادين","title":"اختبارات الصيادين","body":"سجّل في الاختبار القادم واختبر مهاراتك","action":"زيارة مقر نقابة الصيادين","color":Color(0.08,0.32,0.48),"duration":120},
	{"id":"city_market","category":"تجارة المدينة","title":"سوق المدينة","body":"اكتشف المتاجر والعروض التجارية المحلية","action":"زيارة منطقة التسوق","color":Color(0.12,0.38,0.25),"duration":105},
	{"id":"power_tower","category":"بطولات","title":"تحديات برج القوة","body":"اصعد الطوابق ونافس على المراتب العليا","action":"زيارة برج القوة في بغداد","color":Color(0.48,0.20,0.08),"duration":90},
	{"id":"football_event","category":"رياضة","title":"فعاليات كرة القدم","body":"تابع أخبار الملعب والأنشطة الرياضية","action":"زيارة الملعب الرياضي","color":Color(0.12,0.34,0.16),"duration":110},
	{"id":"motorsport_event","category":"رياضة المحركات","title":"سباقات المدينة","body":"استعد لتحديات السرعة على الحلبة","action":"زيارة حلبة السباق","color":Color(0.42,0.16,0.12),"duration":95},
	{"id":"city_festival","category":"فعاليات المدينة","title":"مهرجان المدينة","body":"اكتشف الأنشطة والفعاليات الموسمية","action":"تفقد ساحة المدينة","color":Color(0.34,0.18,0.42),"duration":130}
]

const BOARDS_PER_CITY := 3
const ROTATION_REFRESH_SECONDS := 8.0
const WORLD_ID := "2"

var city_anchors: Dictionary = {}
var terrain: Node
var map_manager: Node
var display_records: Array[Dictionary] = []
var displays_by_id: Dictionary = {}
var refresh_elapsed := 0.0


func setup(anchors: Dictionary, terrain_manager: Node, p_map_manager: Node = null) -> void:
	city_anchors = anchors.duplicate(true)
	terrain = terrain_manager
	map_manager = p_map_manager
	for city_value in city_anchors.keys():
		_build_city_boards(str(city_value), city_anchors[city_value])
	_refresh_all_displays()


func connect_map_manager(p_map_manager: Node, world_id: String = WORLD_ID) -> void:
	map_manager = p_map_manager
	for record in display_records:
		var board_id := str(record.get("id", ""))
		if map_manager != null and map_manager.has_method("register_advertisement"):
			map_manager.call(
				"register_advertisement",
				world_id,
				board_id,
				str(record.get("city", "")),
				str(record.get("name", "إعلان")),
				record.get("position", Vector3.ZERO)
			)
		if map_manager != null and map_manager.has_method("update_advertisement"):
			map_manager.call("update_advertisement", world_id, board_id, _campaign_for_record(record, int(Time.get_unix_time_from_system())))


func _process(delta: float) -> void:
	refresh_elapsed += delta
	if refresh_elapsed < ROTATION_REFRESH_SECONDS:
		return
	refresh_elapsed = 0.0
	_refresh_all_displays()


func _build_city_boards(city_name: String, anchor: Vector2) -> void:
	var offsets: Array[Vector2] = [
		Vector2(34.0, -18.0),
		Vector2(-34.0, 18.0),
		Vector2(12.0, 42.0)
	]
	for index in range(mini(BOARDS_PER_CITY, offsets.size())):
		var requested: Vector2 = anchor + offsets[index]
		var placement := requested
		if is_instance_valid(terrain) and terrain.has_method("is_land_position"):
			if not bool(terrain.call("is_land_position", placement.x, placement.y)):
				var region := get_parent()
				if region != null and region.has_method("_nearest_land_position"):
					placement = region.call("_nearest_land_position", placement)
				if placement == Vector2.INF:
					continue
		var ground := _ground_height(placement)
		var board_id := "street_ad_%s_%02d" % [city_name.to_lower().replace(" ", "_"), index + 1]
		var board_root := Node3D.new()
		board_root.name = "StreetAdvertisingBoard_" + city_name.replace(" ", "") + "_%02d" % index
		board_root.position = Vector3(placement.x, ground, placement.y)
		board_root.rotation.y = deg_to_rad(float((index * 65 + 25) % 360))
		add_child(board_root)
		_build_board_geometry(board_root)
		var campaign_label := Label3D.new()
		campaign_label.name = "CampaignText"
		campaign_label.position = Vector3(0.0, 4.45, -0.57)
		campaign_label.font_size = 34
		campaign_label.pixel_size = 0.012
		campaign_label.modulate = Color(0.92, 0.98, 1.0)
		campaign_label.outline_size = 8
		campaign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		campaign_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		board_root.add_child(campaign_label)
		var interaction := Area3D.new()
		interaction.name = "AdvertisingInteraction"
		interaction.position = Vector3(0.0, 2.5, -2.1)
		interaction.add_to_group("system_interactable")
		interaction.set_meta("system_location_id", board_id)
		interaction.set_meta("system_region_id", "region_" + city_name.to_lower().replace(" ", "_"))
		interaction.set_meta("system_display_name", "لوحة إعلانات — " + city_name)
		interaction.set_meta("system_location_type", 8)
		interaction.set_meta("system_interaction_prompt", "تفاعل لعرض الإعلان الحالي")
		interaction.set_meta("system_advertisement_id", board_id)
		var area_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(5.0, 4.0, 3.0)
		area_shape.shape = box
		interaction.add_child(area_shape)
		board_root.add_child(interaction)
		var record := {
			"id": board_id,
			"city": city_name,
			"name": "إعلان شارع — " + city_name,
			"position": board_root.global_position,
			"root": board_root,
			"label": campaign_label,
			"index": index
		}
		display_records.append(record)
		displays_by_id[board_id] = record
		_register_map_advertisement(record)


func _build_board_geometry(parent: Node3D) -> void:
	var frame_material := _material(Color(0.035, 0.055, 0.075), 0.42, 0.55)
	var panel_material := _material(Color(0.035, 0.18, 0.24), 0.32, 0.25)
	panel_material.emission_enabled = true
	panel_material.emission = Color(0.015, 0.16, 0.24)
	panel_material.emission_energy_multiplier = 1.1
	for side in [-1.0, 1.0]:
		_add_box(parent, "Support_%s" % str(side), Vector3(side * 2.35, 2.05, 0.0), Vector3(0.24, 4.1, 0.28), frame_material)
	_add_box(parent, "DisplayFrame", Vector3(0.0, 4.15, 0.0), Vector3(5.5, 3.5, 0.48), frame_material)
	_add_box(parent, "DisplaySurface", Vector3(0.0, 4.15, -0.29), Vector3(5.12, 3.12, 0.08), panel_material)
	_add_box(parent, "BaseFoot", Vector3(0.0, 0.16, 0.0), Vector3(5.2, 0.28, 1.2), frame_material)
	_add_box(parent, "TopLightBar", Vector3(0.0, 6.02, -0.12), Vector3(5.3, 0.12, 0.18), _material(Color(0.15, 0.72, 0.95), 0.25, 0.25))


func _add_box(parent: Node3D, node_name: String, point: Vector3, dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = point
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _register_map_advertisement(record: Dictionary) -> void:
	if not is_instance_valid(map_manager) or not map_manager.has_method("register_advertisement"):
		return
	map_manager.call(
		"register_advertisement",
		WORLD_ID,
		str(record["id"]),
		str(record["city"]),
		str(record["name"]),
		record["position"]
	)


func _refresh_all_displays() -> void:
	var now := int(Time.get_unix_time_from_system())
	for record in display_records:
		var campaign := _campaign_for_record(record, now)
		var label := record.get("label") as Label3D
		if is_instance_valid(label):
			label.text = "%s\n%s\n%s" % [
				str(campaign.get("title", "SYSTEM")),
				str(campaign.get("body", "")),
				"تفاعل لمعرفة التفاصيل"
			]
			var root := record.get("root") as Node3D
			if is_instance_valid(root):
				var surface := root.get_node_or_null("DisplaySurface") as MeshInstance3D
				if surface != null:
					surface.material_override = _campaign_material(campaign.get("color", Color(0.04, 0.16, 0.22)))
		if map_manager != null and map_manager.has_method("update_advertisement"):
			map_manager.call("update_advertisement", WORLD_ID, str(record["id"]), campaign)


func _campaign_for_record(record: Dictionary, now: int) -> Dictionary:
	var city_offset := abs(hash(str(record.get("city", "")))) % CAMPAIGNS.size()
	var board_offset := int(record.get("index", 0))
	var cycle_seconds := 0
	for campaign in CAMPAIGNS:
		cycle_seconds += int(campaign.get("duration", 90))
	var cycle_position := posmod(now + city_offset * 37 + board_offset * 19, maxi(cycle_seconds, 1))
	var campaign: Dictionary = {}
	var remaining_in_campaign := 0
	for candidate in CAMPAIGNS:
		var duration := maxi(1, int(candidate.get("duration", 90)))
		if cycle_position < duration:
			campaign = candidate.duplicate(true)
			remaining_in_campaign = duration - cycle_position
			break
		cycle_position -= duration
	if campaign.is_empty():
		campaign = CAMPAIGNS[0].duplicate(true)
		remaining_in_campaign = int(campaign.get("duration", 90))
	campaign["expires_at"] = now + remaining_in_campaign
	campaign["city"] = str(record.get("city", ""))
	campaign["board_id"] = str(record.get("id", ""))
	return campaign


func get_campaign_details(board_id: String) -> Dictionary:
	if not displays_by_id.has(board_id):
		return {}
	var record: Dictionary = displays_by_id[board_id]
	return _campaign_for_record(record, int(Time.get_unix_time_from_system()))


func get_advertisement_locations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in display_records:
		var campaign := get_campaign_details(str(record["id"]))
		result.append({
			"id": str(record["id"]),
			"name": str(record["name"]),
			"city": str(record["city"]),
			"position": record["position"],
			"campaign_title": str(campaign.get("title", "")),
			"campaign_category": str(campaign.get("category", "")),
			"campaign_body": str(campaign.get("body", "")),
			"campaign_action": str(campaign.get("action", "")),
			"expires_at": int(campaign.get("expires_at", 0))
		})
	return result


func _ground_height(point: Vector2) -> float:
	if is_instance_valid(terrain) and terrain.has_method("get_terrain_height"):
		return float(terrain.call("get_terrain_height", point.x, point.y))
	return 0.0


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _campaign_material(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.32, 0.25)
	material.emission_enabled = true
	material.emission = color * 0.42
	material.emission_energy_multiplier = 1.0
	return material
