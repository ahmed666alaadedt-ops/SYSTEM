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
	set_meta("playable_interior_blockout", true)
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
		_add_visual_box("ServiceDesk_%d" % index, desk_positions[index], Vector3(7.0, 2.4, 3.0), desk_mat)
		_add_visual_box("ServiceTerminal_%d" % index, desk_positions[index] + Vector3(0.0, 2.0, -0.3), Vector3(3.6, 1.7, 0.25), screen_mat)
		var label := Label3D.new()
		label.name = "ServiceLabel_%d" % index
		label.text = str(desk_titles[index])
		label.font_size = 24
		label.position = desk_positions[index] + Vector3(0.0, 4.0, -1.2)
		label.pixel_size = 0.014
		label.modulate = Color(0.78, 0.91, 1.0)
		add_child(label)

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
