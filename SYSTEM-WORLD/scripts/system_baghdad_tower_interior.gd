extends Node3D

## Shared first playable lobby for the five connected Baghdad landmark towers.
## The Power Tower remains a separate challenge venue and never receives this lobby.

var tower_id := ""
var display_title := ""
var entrance_script: Script
var external_return_position := Vector3.ZERO

func build(p_tower_id: String, p_title: String, p_entrance_script: Script, p_external_return_position: Vector3) -> void:
	tower_id = p_tower_id
	display_title = p_title
	entrance_script = p_entrance_script
	external_return_position = p_external_return_position
	name = "TowerInterior"
	_build_lobby()
	_build_service_desks()
	_build_exit()
	_build_tower_identity_feature()
	_build_lobby_wayfinding()
	_build_upper_floor_access()
	set_meta("playable_interior_blockout", true)
	set_meta("upper_floor_blockout_count", 4)
	set_meta("interactive_floor_selection", true)
	set_meta("tower_identity_feature_ready", true)
	set_meta("service_desks_have_collision", true)
	set_meta("tower_id", tower_id)

func get_entry_position() -> Vector3:
	return to_global(Vector3(0.0, 1.4, 10.0))

func get_return_position() -> Vector3:
	return external_return_position

func _build_lobby() -> void:
	var floor_mat := _material(Color(0.11, 0.15, 0.20), 0.42, 0.45)
	var wall_mat := _material(Color(0.045, 0.075, 0.11), 0.36, 0.58)
	var accent := _material(Color(0.72, 0.52, 0.22), 0.28, 0.72)
	var glass := _material(Color(0.06, 0.35, 0.48), 0.22, 0.35)
	glass.emission_enabled = true
	glass.emission = Color(0.02, 0.18, 0.28)
	glass.emission_energy_multiplier = 1.0
	_add_solid_box("LobbyFloor", Vector3(0.0, -0.35, 0.0), Vector3(42.0, 0.7, 42.0), floor_mat)
	_add_solid_box("LobbyLeftWall", Vector3(-21.0, 7.0, 0.0), Vector3(1.0, 14.0, 42.0), wall_mat)
	_add_solid_box("LobbyRightWall", Vector3(21.0, 7.0, 0.0), Vector3(1.0, 14.0, 42.0), wall_mat)
	_add_solid_box("LobbyRearWall", Vector3(0.0, 7.0, -21.0), Vector3(42.0, 14.0, 1.0), wall_mat)
	_add_solid_box("LobbyFrontWallLeft", Vector3(-14.0, 7.0, 21.0), Vector3(14.0, 14.0, 1.0), wall_mat)
	_add_solid_box("LobbyFrontWallRight", Vector3(14.0, 7.0, 21.0), Vector3(14.0, 14.0, 1.0), wall_mat)
	_add_solid_box("LobbyCeiling", Vector3(0.0, 14.0, 0.0), Vector3(42.0, 0.8, 42.0), wall_mat)
	_add_visual_box("FloorIdentityLine", Vector3(0.0, 0.08, 0.0), Vector3(28.0, 0.08, 0.5), accent)
	_add_visual_box("RearFeatureWall", Vector3(0.0, 7.5, -20.35), Vector3(26.0, 11.0, 0.25), glass)
	var identity := Label3D.new()
	identity.name = "TowerLobbyIdentity"
	identity.text = display_title + "\nSYSTEM BAGHDAD"
	identity.font_size = 34
	identity.position = Vector3(0.0, 11.0, -19.9)
	identity.pixel_size = 0.012
	identity.modulate = Color(0.75, 0.91, 1.0)
	add_child(identity)
	var light := OmniLight3D.new()
	light.name = "LobbyLighting"
	light.position = Vector3(0.0, 11.5, 0.0)
	light.light_color = Color(0.58, 0.78, 1.0)
	light.light_energy = 1.6
	light.omni_range = 48.0
	light.shadow_enabled = false
	add_child(light)

func _build_service_desks() -> void:
	var desk_mat := _material(Color(0.20, 0.24, 0.29), 0.34, 0.55)
	var screen_mat := _material(Color(0.04, 0.52, 0.70), 0.22, 0.25)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.02, 0.35, 0.62)
	screen_mat.emission_energy_multiplier = 1.4
	var desk_positions := [Vector3(-12.0, 1.2, -8.0), Vector3(0.0, 1.2, -8.0), Vector3(12.0, 1.2, -8.0)]
	var desk_titles := _service_titles()
	for index in range(desk_positions.size()):
		_add_solid_box("ServiceDesk_%d" % index, desk_positions[index], Vector3(7.0, 2.4, 3.0), desk_mat)
		_add_visual_box("ServiceTerminal_%d" % index, desk_positions[index] + Vector3(0.0, 2.0, -0.3), Vector3(3.6, 1.7, 0.25), screen_mat)
		var label := Label3D.new()
		label.name = "ServiceLabel_%d" % index
		label.text = str(desk_titles[index])
		label.font_size = 24
		label.position = desk_positions[index] + Vector3(0.0, 4.0, -1.2)
		label.pixel_size = 0.014
		label.modulate = Color(0.78, 0.91, 1.0)
		add_child(label)
		if entrance_script != null:
			var service_area: Area3D = entrance_script.new()
			service_area.name = "ServiceInteraction_%d" % index
			service_area.configure("tower_service_" + tower_id + "_" + str(index), str(desk_titles[index]), "region_baghdad")
			service_area.set_meta("system_service_description", "نقطة معلومات وخدمة أولية في بهو البرج؛ ربط الخدمة التشغيلية الكاملة قيد التطوير.")
			service_area.set_meta("system_interaction_prompt", "استعراض " + str(desk_titles[index]))
			var service_collision := CollisionShape3D.new()
			var service_shape := SphereShape3D.new()
			service_shape.radius = 3.0
			service_collision.shape = service_shape
			service_area.add_child(service_collision)
			service_area.position = desk_positions[index] + Vector3(0.0, 1.5, 3.0)
			add_child(service_area)

func _service_titles() -> Array[String]:
	match tower_id:
		"business_tower_baghdad":
			return ["استشارات الأعمال", "مكاتب الاستثمار", "خدمات الشركات"]
		"shopping_tower_baghdad":
			return ["دليل المتاجر", "السوق والتجارة", "خدمات العملاء"]
		"entertainment_tower_baghdad":
			return ["الفعاليات", "الرياضة والترفيه", "حجز الأنشطة"]
		"technology_tower_baghdad":
			return ["مختبر الابتكار", "مركز التقنية", "معرض الاختراعات"]
		_:
			return ["تسجيل الصيادين", "لوحة المهام", "معلومات النقابة"]

func _build_exit() -> void:
	if entrance_script == null:
		return
	var exit_area: Area3D = entrance_script.new()
	exit_area.name = "TowerLobbyExit"
	exit_area.configure("tower_exit_" + tower_id, "الخروج من " + display_title, "region_baghdad")
	exit_area.position = Vector3(0.0, 1.4, 18.0)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.5
	collision.shape = shape
	exit_area.add_child(collision)
	add_child(exit_area)

func _add_solid_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_visual_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	add_child(visual)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


func _build_tower_identity_feature() -> void:
	var accent_color := Color(0.08, 0.62, 0.92)
	var feature_title := "SYSTEM"
	match tower_id:
		"hunter_association_tower_baghdad":
			accent_color = Color(0.08, 0.62, 0.92)
			feature_title = "HUNTER MISSION CORE"
		"business_tower_baghdad":
			accent_color = Color(0.24, 0.78, 0.72)
			feature_title = "BUSINESS & INVESTMENT"
		"shopping_tower_baghdad":
			accent_color = Color(0.95, 0.72, 0.28)
			feature_title = "CITY MARKET DIRECTORY"
		"entertainment_tower_baghdad":
			accent_color = Color(0.75, 0.38, 0.95)
			feature_title = "EVENTS & ARENA HUB"
		"technology_tower_baghdad":
			accent_color = Color(0.18, 0.88, 0.78)
			feature_title = "INNOVATION CORE"
	var accent := _material(accent_color, 0.24, 0.48)
	accent.emission_enabled = true
	accent.emission = accent_color * 0.38
	accent.emission_energy_multiplier = 1.2
	var dark := _material(Color(0.025, 0.055, 0.085), 0.32, 0.58)
	_add_visual_box("TowerIdentityFeatureBase", Vector3(0.0, 0.12, 1.0), Vector3(12.0, 0.22, 7.0), dark)
	_add_visual_box("TowerIdentityFeatureScreen", Vector3(0.0, 5.2, -1.0), Vector3(10.0, 7.0, 0.45), accent)
	_add_visual_box("TowerIdentityFeatureHeader", Vector3(0.0, 9.2, -0.72), Vector3(11.0, 0.28, 0.24), accent)
	var title := Label3D.new()
	title.name = "TowerIdentityFeatureTitle"
	title.text = feature_title
	title.font_size = 25
	title.position = Vector3(0.0, 10.1, -0.55)
	title.pixel_size = 0.012
	title.modulate = accent_color.lightened(0.25)
	add_child(title)
	for index in range(3):
		var marker := MeshInstance3D.new()
		marker.name = "FeatureStatusMarker_%d" % index
		var marker_mesh := SphereMesh.new()
		marker_mesh.radius = 0.28
		marker_mesh.height = 0.56
		marker.mesh = marker_mesh
		marker.position = Vector3(-3.0 + float(index) * 3.0, 2.4, -0.65)
		marker.material_override = accent
		add_child(marker)


func _build_lobby_wayfinding() -> void:
	var gold := _material(Color(0.78, 0.57, 0.25), 0.28, 0.72)
	var cyan := _material(Color(0.06, 0.56, 0.78), 0.24, 0.42)
	cyan.emission_enabled = true
	cyan.emission = Color(0.02, 0.32, 0.62)
	cyan.emission_energy_multiplier = 1.0
	for side in [-1.0, 1.0]:
		_add_solid_box("LobbyWayfindingPillar_%s" % str(int(side)), Vector3(side * 17.5, 6.0, 12.0), Vector3(1.2, 12.0, 1.2), gold)
		_add_visual_box("LobbyWayfindingLight_%s" % str(int(side)), Vector3(side * 17.5, 10.0, 11.3), Vector3(0.16, 6.0, 0.12), cyan)
	var direction := Label3D.new()
	direction.name = "LobbyWayfindingSign"
	direction.text = "معلومات وخدمات البرج  ←     →  المخرج"
	direction.font_size = 22
	direction.position = Vector3(0.0, 12.0, 16.0)
	direction.pixel_size = 0.012
	direction.modulate = Color(0.72, 0.9, 1.0)
	add_child(direction)


func _build_upper_floor_access() -> void:
	var floor_material := _material(Color(0.13, 0.19, 0.25), 0.38, 0.52)
	var edge_material := _material(Color(0.06, 0.55, 0.78), 0.24, 0.42)
	edge_material.emission_enabled = true
	edge_material.emission = Color(0.02, 0.32, 0.58)
	edge_material.emission_energy_multiplier = 1.1
	# Continuous visual lift shaft, with paired illuminated guide rails.
	_add_visual_box("LiftShaftGuide_Left", Vector3(8.0, 36.0, 12.0), Vector3(0.35, 72.0, 0.35), edge_material)
	_add_visual_box("LiftShaftGuide_Right", Vector3(12.0, 36.0, 12.0), Vector3(0.35, 72.0, 0.35), edge_material)
	var floor_titles := ["الطابق 02 — الخدمات", "الطابق 03 — المرافق", "الطابق 04 — الإدارة", "الطابق 05 — المنصة العليا"]
	for index in range(4):
		var floor_number := index + 2
		var floor_y := 18.0 * float(floor_number - 1)
		_add_solid_box("UpperFloor_%02d" % floor_number, Vector3(0.0, floor_y, 0.0), Vector3(38.0, 0.8, 38.0), floor_material)
		_add_visual_box("UpperFloorIdentityBand_%02d" % floor_number, Vector3(0.0, floor_y + 0.48, -17.0), Vector3(24.0, 0.18, 0.22), edge_material)
		var floor_label := Label3D.new()
		floor_label.name = "UpperFloorLabel_%02d" % floor_number
		floor_label.text = str(floor_titles[index])
		floor_label.font_size = 26
		floor_label.position = Vector3(0.0, floor_y + 4.0, -16.5)
		floor_label.pixel_size = 0.014
		floor_label.modulate = Color(0.76, 0.91, 1.0)
		add_child(floor_label)
		_add_solid_box("LiftLandingMarker_%02d" % floor_number, Vector3(14.0, floor_y + 1.2, 12.0), Vector3(5.0, 2.4, 4.0), floor_material)
		_add_visual_box("LiftDoor_Left_%02d" % floor_number, Vector3(9.0, floor_y + 4.0, 11.6), Vector3(1.8, 7.0, 0.22), edge_material)
		_add_visual_box("LiftDoor_Right_%02d" % floor_number, Vector3(11.0, floor_y + 4.0, 11.6), Vector3(1.8, 7.0, 0.22), edge_material)
		_create_floor_selector(floor_number, floor_y)


func _create_floor_selector(floor_number: int, floor_y: float) -> void:
	if entrance_script == null:
		return
	var area: Area3D = entrance_script.new()
	area.name = "LiftFloorSelector_%02d" % floor_number
	var floor_title := "الطابق %02d" % floor_number
	area.configure("tower_floor_%s_%02d" % [tower_id, floor_number], "الانتقال إلى " + floor_title, "region_baghdad")
	area.set_meta("system_destination_position", to_global(Vector3(10.0, floor_y + 1.5, 12.0)))
	area.set_meta("system_interaction_prompt", "استخدام المصعد — " + floor_title)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.2
	collision.shape = shape
	area.add_child(collision)
	area.position = Vector3(10.0, floor_y + 1.5, 8.0)
	add_child(area)
