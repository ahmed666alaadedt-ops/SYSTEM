extends Node3D

## First playable interior blockout for the Global Hunter Association HQ.
## The room is built inside the elevated headquarters hall; it does not add a tower.

var entrance_script: Script
var _entry_local := Vector3(0.0, 6.0, 20.0)
var _return_local := Vector3(0.0, 6.0, 53.0)


func build(p_entrance_script: Script) -> void:
	entrance_script = p_entrance_script
	name = "HeadquartersInterior"
	_build_room()
	_build_service_room_partitions()
	_build_furnishings()
	_build_public_service_desks()
	_build_exit_interaction()
	set_meta("playable_interior_blockout", true)


func get_entry_position() -> Vector3:
	return to_global(_entry_local)


func get_return_position() -> Vector3:
	return to_global(_return_local)


func _build_room() -> void:
	var floor_material := _material(Color(0.10, 0.16, 0.22), 0.48, 0.42)
	var wall_material := _material(Color(0.055, 0.10, 0.16), 0.38, 0.55)
	var trim_material := _material(Color(0.76, 0.55, 0.24), 0.32, 0.78)
	var glass_material := _material(Color(0.08, 0.34, 0.48, 0.78), 0.2, 0.45)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.emission_enabled = true
	glass_material.emission = Color(0.02, 0.20, 0.34)
	glass_material.emission_energy_multiplier = 0.8

	_add_solid_box("InteriorFloor", Vector3(0.0, 4.0, 0.0), Vector3(108.0, 2.0, 78.0), floor_material)
	_add_solid_box("InteriorLeftWall", Vector3(-54.0, 18.0, 0.0), Vector3(2.0, 28.0, 82.0), wall_material)
	_add_solid_box("InteriorRightWall", Vector3(54.0, 18.0, 0.0), Vector3(2.0, 28.0, 82.0), wall_material)
	_add_solid_box("InteriorRearWall", Vector3(0.0, 18.0, -40.0), Vector3(108.0, 28.0, 2.0), wall_material)
	_add_solid_box("InteriorFrontWallLeft", Vector3(-35.0, 18.0, 40.0), Vector3(38.0, 28.0, 2.0), wall_material)
	_add_solid_box("InteriorFrontWallRight", Vector3(35.0, 18.0, 40.0), Vector3(38.0, 28.0, 2.0), wall_material)
	_add_solid_box("InteriorRoof", Vector3(0.0, 32.0, 0.0), Vector3(108.0, 2.0, 82.0), wall_material)

	_add_visual_box("GoldFloorInlay", Vector3(0.0, 5.08, 0.0), Vector3(72.0, 0.08, 1.0), trim_material)
	_add_visual_box("ReceptionBackPanel", Vector3(0.0, 17.0, -34.0), Vector3(42.0, 18.0, 0.8), glass_material)
	_add_visual_box("CeilingLightStrip", Vector3(0.0, 30.8, 0.0), Vector3(52.0, 0.22, 1.4), trim_material)

	var light := OmniLight3D.new()
	light.name = "HeadquartersInteriorLighting"
	light.position = Vector3(0.0, 27.0, -4.0)
	light.light_color = Color(0.52, 0.78, 1.0)
	light.light_energy = 2.2
	light.omni_range = 92.0
	light.shadow_enabled = false
	add_child(light)


func _build_service_room_partitions() -> void:
	var partition_material := _material(Color(0.045, 0.085, 0.13), 0.38, 0.62)
	var trim_material := _material(Color(0.72, 0.49, 0.20), 0.28, 0.72)
	var wall_specs: Array[Dictionary] = [
		{"name": "ReceptionRoomFrontWall_Left", "position": Vector3(-49.0, 18.0, 8.0), "size": Vector3(10.0, 16.0, 1.0)},
		{"name": "ReceptionRoomFrontWall_Right", "position": Vector3(-28.0, 18.0, 8.0), "size": Vector3(24.0, 16.0, 1.0)},
		{"name": "RegistryRoomFrontWall_Left", "position": Vector3(28.0, 18.0, 8.0), "size": Vector3(24.0, 16.0, 1.0)},
		{"name": "RegistryRoomFrontWall_Right", "position": Vector3(49.0, 18.0, 8.0), "size": Vector3(10.0, 16.0, 1.0)},
		{"name": "MissionRoomFrontWall_Left", "position": Vector3(-49.0, 18.0, -8.0), "size": Vector3(10.0, 16.0, 1.0)},
		{"name": "MissionRoomFrontWall_Right", "position": Vector3(-28.0, 18.0, -8.0), "size": Vector3(24.0, 16.0, 1.0)},
		{"name": "ExaminerRoomFrontWall_Left", "position": Vector3(28.0, 18.0, -8.0), "size": Vector3(24.0, 16.0, 1.0)},
		{"name": "ExaminerRoomFrontWall_Right", "position": Vector3(49.0, 18.0, -8.0), "size": Vector3(10.0, 16.0, 1.0)},
		{"name": "ReceptionRoomSideWall_Lower", "position": Vector3(-16.0, 18.0, 12.0), "size": Vector3(1.0, 16.0, 8.0)},
		{"name": "ReceptionRoomSideWall_Upper", "position": Vector3(-16.0, 18.0, 31.0), "size": Vector3(1.0, 16.0, 14.0)},
		{"name": "RegistryRoomSideWall_Lower", "position": Vector3(16.0, 18.0, 12.0), "size": Vector3(1.0, 16.0, 8.0)},
		{"name": "RegistryRoomSideWall_Upper", "position": Vector3(16.0, 18.0, 31.0), "size": Vector3(1.0, 16.0, 14.0)},
		{"name": "MissionRoomSideWall_Lower", "position": Vector3(-16.0, 18.0, -30.0), "size": Vector3(1.0, 16.0, 16.0)},
		{"name": "MissionRoomSideWall_Upper", "position": Vector3(-16.0, 18.0, -11.0), "size": Vector3(1.0, 16.0, 6.0)},
		{"name": "ExaminerRoomSideWall_Lower", "position": Vector3(16.0, 18.0, -30.0), "size": Vector3(1.0, 16.0, 16.0)},
		{"name": "ExaminerRoomSideWall_Upper", "position": Vector3(16.0, 18.0, -11.0), "size": Vector3(1.0, 16.0, 6.0)}
	]
	for wall in wall_specs:
		_add_solid_box(str(wall["name"]), wall["position"], wall["size"], partition_material)
	for room in [
		{"name": "Reception", "position": Vector3(-42.0, 27.0, 8.0), "title": "الاستعلامات"},
		{"name": "Registry", "position": Vector3(42.0, 27.0, 8.0), "title": "سجل الصيادين"},
		{"name": "Mission", "position": Vector3(-42.0, 27.0, -8.0), "title": "المهام والعقود"},
		{"name": "Examiner", "position": Vector3(42.0, 27.0, -8.0), "title": "مراقبة الاختبارات"}
	]:
		var header := MeshInstance3D.new()
		header.name = "HQRoomDoorHeader_" + str(room["name"])
		var header_mesh := BoxMesh.new()
		header_mesh.size = Vector3(5.0, 0.35, 0.45)
		header.mesh = header_mesh
		header.position = room["position"]
		header.material_override = trim_material
		add_child(header)
		var label := Label3D.new()
		label.name = "HQRoomDoorSign_" + str(room["name"])
		label.text = str(room["title"])
		label.font_size = 20
		label.position = room["position"] + Vector3(0.0, 2.0, 0.0)
		label.pixel_size = 0.012
		label.modulate = Color(0.82, 0.94, 1.0)
		add_child(label)
	set_meta("headquarters_service_rooms_count", 4)
	set_meta("headquarters_service_room_partition_count", wall_specs.size())


func _build_furnishings() -> void:
	var gold := _material(Color(0.72, 0.48, 0.18), 0.3, 0.72)
	var dark := _material(Color(0.035, 0.065, 0.09), 0.36, 0.35)
	var cyan := _material(Color(0.08, 0.68, 0.86), 0.25, 0.25)
	cyan.emission_enabled = true
	cyan.emission = Color(0.02, 0.42, 0.72)
	cyan.emission_energy_multiplier = 1.5

	_add_visual_box("ReceptionDesk", Vector3(0.0, 7.0, -22.0), Vector3(24.0, 3.0, 5.0), gold)
	_add_visual_box("ReceptionDeskFront", Vector3(0.0, 8.6, -19.35), Vector3(23.0, 0.18, 0.18), cyan)
	_add_visual_box("CentralCouncilTable", Vector3(0.0, 6.0, 2.0), Vector3(20.0, 1.2, 8.0), dark)
	_add_visual_box("CouncilTableAccent", Vector3(0.0, 6.65, 2.0), Vector3(16.0, 0.12, 0.25), gold)

	for side in [-1.0, 1.0]:
		for row in range(3):
			var seat_position := Vector3(side * 30.0, 6.0, -2.0 + float(row) * 10.0)
			_add_visual_box("WaitingSeat_%s_%d" % [str(int(side)), row], seat_position, Vector3(8.0, 1.0, 3.0), dark)
			_add_visual_box("WaitingSeatBack_%s_%d" % [str(int(side)), row], seat_position + Vector3(0.0, 2.0, -1.2), Vector3(8.0, 3.0, 0.8), gold)

	var emblem := Label3D.new()
	emblem.name = "HunterAssociationInteriorEmblem"
	emblem.text = "WORLD HUNTER ASSOCIATION\nالمقر الرئيسي — مجلس الصيادين"
	emblem.font_size = 38
	emblem.position = Vector3(0.0, 25.0, -38.7)
	emblem.pixel_size = 0.012
	emblem.modulate = Color(0.55, 0.88, 1.0)
	add_child(emblem)

	for index in range(4):
		var display := MeshInstance3D.new()
		display.name = "MissionDisplay_%d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(8.0, 4.0, 0.35)
		display.mesh = mesh
		display.position = Vector3(-30.0 + float(index) * 20.0, 20.0, -38.2)
		display.material_override = cyan
		add_child(display)


func _build_public_service_desks() -> void:
	if entrance_script == null:
		push_warning("SYSTEM HQ: public service desk interactions are unavailable.")
		return
	var desk_material := _material(Color(0.68, 0.46, 0.19), 0.3, 0.72)
	var accent_material := _material(Color(0.04, 0.58, 0.82), 0.22, 0.42)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.015, 0.34, 0.72)
	accent_material.emission_energy_multiplier = 1.2
	var service_specs: Array[Dictionary] = [
		{"id": "reception", "title": "استعلامات المقر", "description": "استقبال الصيادين والزوار وتوجيههم إلى أقسام نقابة الصيادين.", "position": Vector3(-32.0, 7.0, 23.0)},
		{"id": "registry", "title": "سجل الصيادين", "description": "مكتب مراجعة بيانات الصيادين وطلبات التسجيل والعضوية.", "position": Vector3(32.0, 7.0, 23.0)},
		{"id": "missions", "title": "مجلس المهام والعقود", "description": "نقطة معلومات لعرض المهام والعقود التي يتولاها اللاعب بنفسه.", "position": Vector3(-32.0, 7.0, -23.0)},
		{"id": "examiner_control", "title": "مراقبة الاختبارات", "description": "مكتب المشرفين والممتحنين لمتابعة مراحل اختبار الصيادين؛ الشخصيات غير اللاعبة موظفون وممتحنون وليست مرشحين.", "position": Vector3(32.0, 7.0, -23.0)}
	]
	for service in service_specs:
		var service_id := str(service["id"])
		var desk_position: Vector3 = service["position"]
		_add_solid_box("HQServiceDeskCollision_" + service_id, desk_position, Vector3(14.0, 3.0, 5.0), desk_material)
		_add_visual_box("HQServiceDeskAccent_" + service_id, desk_position + Vector3(0.0, 1.58, 0.0), Vector3(13.2, 0.12, 4.5), accent_material)
		var sign := Label3D.new()
		sign.name = "HQServiceSign_" + service_id
		sign.text = str(service["title"])
		sign.font_size = 24
		sign.position = desk_position + Vector3(0.0, 5.0, -1.0)
		sign.pixel_size = 0.014
		sign.modulate = Color(0.78, 0.92, 1.0)
		add_child(sign)
		var interaction: Area3D = entrance_script.new()
		interaction.name = "HQServiceInteraction_" + service_id
		interaction.configure("tower_service_hunter_headquarters_" + service_id, str(service["title"]), "region_baghdad")
		interaction.set_meta("system_service_description", str(service["description"]))
		interaction.set_meta("system_hq_service_id", service_id)
		interaction.position = desk_position + Vector3(0.0, -0.2, 5.0)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 3.4
		collision.shape = shape
		interaction.add_child(collision)
		add_child(interaction)
	set_meta("headquarters_public_service_count", service_specs.size())
	set_meta("headquarters_service_interactions_ready", true)


func _build_exit_interaction() -> void:
	if entrance_script == null:
		push_warning("SYSTEM HQ interior: entrance script unavailable.")
		return
	var exit_area: Area3D = entrance_script.new()
	exit_area.name = "HeadquartersExit"
	exit_area.configure(
		"hunter_association_headquarters_exit_baghdad",
		"الخروج من المقر الرئيسي",
		"region_baghdad"
	)
	exit_area.position = Vector3(0.0, 6.0, 34.0)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 4.0
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
