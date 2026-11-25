extends RefCounted
class_name SystemBaghdadTowerLobbyFinishManager

static func apply_visual_finish(lobby: Node3D, tower_id: String, title: String, width: float, depth: float, center_z: float, front_z: float) -> void:
	var accent := _accent_for_tower(tower_id)
	var dark := _material(Color(0.018, 0.035, 0.055), 0.3, 0.72)
	var metal := _material(accent.darkened(0.24), 0.24, 0.82)
	var glow := _material(accent.lightened(0.18), 0.22, 0.48)
	glow.emission_enabled = true
	glow.emission = accent
	glow.emission_energy_multiplier = 1.35
	var stone := _material(Color(0.24, 0.28, 0.31), 0.34, 0.28)
	_add_box(lobby, "FinishFloorCenterInlay", Vector3(0.0, 1.015, center_z), Vector3(width * 0.44, 0.035, depth * 0.72), dark)
	_add_box(lobby, "FinishFloorAccentLineLeft", Vector3(-width * 0.225, 1.04, center_z), Vector3(0.28, 0.045, depth * 0.72), glow)
	_add_box(lobby, "FinishFloorAccentLineRight", Vector3(width * 0.225, 1.04, center_z), Vector3(0.28, 0.045, depth * 0.72), glow)
	for index in range(7):
		var z := center_z - depth * 0.31 + float(index) * depth * 0.103
		_add_box(lobby, "FinishFloorTransverseInlay_%02d" % index, Vector3(0.0, 1.045, z), Vector3(width * 0.44, 0.035, 0.12), stone)
	for side_index in range(2):
		var side: float = -1.0 if side_index == 0 else 1.0
		var x: float = side * (width * 0.31)
		_add_box(lobby, "FinishCeilingBeam_%s" % str(side), Vector3(x, 11.85, center_z), Vector3(0.42, 0.42, depth * 0.86), metal)
		for index in range(4):
			var z := center_z - depth * 0.30 + float(index) * depth * 0.20
			_add_box(lobby, "FinishCeilingLight_%s_%02d" % [str(side), index], Vector3(x - side * 0.28, 11.55, z), Vector3(0.16, 0.12, 2.8), glow)
		_add_box(lobby, "FinishWallVerticalAccent_%s" % str(side), Vector3(side * (width * 0.5 - 1.2), 5.5, center_z), Vector3(0.22, 8.4, 0.35), glow)
		_add_bench(lobby, "FinishWaitingBench_%s" % str(side), Vector3(side * (width * 0.29), 1.65, center_z + depth * 0.25), metal, stone)
		_add_planter(lobby, "FinishPlanter_%s" % str(side), Vector3(side * (width * 0.34), 1.2, front_z - 5.0), accent)
	_add_box(lobby, "FinishReceptionFront", Vector3(-width * 0.20, 2.35, center_z + depth * 0.14), Vector3(9.5, 1.15, 0.22), glow)
	_add_box(lobby, "FinishReceptionFoot", Vector3(-width * 0.20, 1.2, center_z + depth * 0.14), Vector3(10.2, 0.24, 3.3), dark)
	_add_box(lobby, "FinishEntranceHeaderAccent", Vector3(0.0, 11.15, front_z + 0.15), Vector3(16.0, 0.28, 0.42), glow)
	var title_plate := Label3D.new()
	title_plate.name = "FinishLobbyIdentityPlate"
	title_plate.text = "SYSTEM  •  " + title
	title_plate.font_size = 30
	title_plate.pixel_size = 0.016
	title_plate.position = Vector3(0.0, 9.6, front_z + 0.2)
	title_plate.modulate = Color(0.88, 0.96, 1.0)
	title_plate.outline_size = 8
	title_plate.outline_modulate = Color(0.015, 0.025, 0.04)
	lobby.add_child(title_plate)
	lobby.set_meta("system_visual_finish_piece_count", 1 + 2 + 7 + 2 + 8 + 2 + 2 + 3)
	lobby.set_meta("system_visual_finish_title", title)

static func _accent_for_tower(tower_id: String) -> Color:
	match tower_id:
		"hunter_association_tower_baghdad":
			return Color(0.16, 0.78, 0.98)
		"business_investment_tower_baghdad":
			return Color(0.88, 0.68, 0.24)
		"shopping_tower_baghdad":
			return Color(0.98, 0.55, 0.20)
		"antiques_heritage_tower_baghdad":
			return Color(0.78, 0.61, 0.34)
		"technology_tower_baghdad":
			return Color(0.22, 0.88, 0.84)
		_:
			return Color(0.22, 0.72, 0.94)

static func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

static func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

static func _add_bench(parent: Node3D, node_name: String, position: Vector3, metal: Material, stone: Material) -> void:
	_add_box(parent, node_name + "_Seat", position, Vector3(7.0, 0.42, 1.25), stone)
	for leg in [-1.0, 1.0]:
		_add_box(parent, node_name + "_Leg_" + str(leg), position + Vector3(leg * 2.7, -0.42, 0.0), Vector3(0.32, 0.84, 0.9), metal)
	_add_box(parent, node_name + "_Back", position + Vector3(0.0, 0.95, -0.48), Vector3(7.0, 1.15, 0.24), metal)

static func _add_planter(parent: Node3D, node_name: String, position: Vector3, accent: Color) -> void:
	var pot := MeshInstance3D.new()
	pot.name = node_name
	var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 1.25
	pot_mesh.bottom_radius = 0.95
	pot_mesh.height = 1.1
	pot.mesh = pot_mesh
	pot.position = position
	pot.material_override = _material(Color(0.12, 0.16, 0.18), 0.42, 0.58)
	parent.add_child(pot)
	var foliage := MeshInstance3D.new()
	foliage.name = node_name + "_Foliage"
	var foliage_mesh := SphereMesh.new()
	foliage_mesh.radius = 1.25
	foliage_mesh.height = 2.6
	foliage.mesh = foliage_mesh
	foliage.position = position + Vector3(0.0, 1.45, 0.0)
	foliage.material_override = _material(Color(0.10, 0.34, 0.22).lerp(accent, 0.18), 0.72, 0.0)
	parent.add_child(foliage)
