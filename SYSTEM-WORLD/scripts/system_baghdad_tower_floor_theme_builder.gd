extends RefCounted
class_name SYSTEMBaghdadTowerFloorThemeBuilder

const THEMES := {
	"hunter_association_tower_baghdad": {
		"id": "global_hunter_association",
		"color": Color(0.12, 0.22, 0.34),
		"accent": Color(0.92, 0.76, 0.38),
		"stations": ["مكتب المهمات", "قاعة التدريب", "سجل الصيادين", "قاعة الشرف"]
	},
	"business_investment_tower_baghdad": {
		"id": "business_and_investment",
		"color": Color(0.10, 0.27, 0.22),
		"accent": Color(0.45, 0.82, 0.62),
		"stations": ["مركز الشركات", "البنوك والعقود", "قاعة التداول", "مركز المؤتمرات"]
	},
	"shopping_tower_baghdad": {
		"id": "shopping_commerce_hospitality",
		"color": Color(0.22, 0.20, 0.34),
		"accent": Color(0.92, 0.68, 0.28),
		"stations": ["معرض الأسلحة والدروع", "مختبر الإكسير والنِن", "سوق الملابس والتجهيزات", "فندق SYSTEM والمطاعم"]
	},
	"antiques_heritage_tower_baghdad": {
		"id": "antiques_heritage_museum_and_player_galleries",
		"color": Color(0.24, 0.19, 0.13),
		"accent": Color(0.82, 0.65, 0.34),
		"stations": ["معرض الحضارات العراقية", "قاعة الآثار العالمية", "مختبر الترميم والتوثيق", "معرض ومزاد مقتنيات اللاعبين"]
	},
	"technology_tower_baghdad": {
		"id": "technology_innovation_lab",
		"color": Color(0.10, 0.22, 0.36),
		"accent": Color(0.25, 0.82, 1.0),
		"stations": ["مختبر الروبوتات", "مختبر الذكاء الاصطناعي", "محاكاة الواقع الافتراضي", "منصة الابتكار"]
	}
}

static func build(room: Node3D, tower_id: String, floor_number: int, radius: float, department: String) -> void:
	if not THEMES.has(tower_id):
		return
	if room.get_node_or_null("FloorThemeIdentity") != null:
		return
	var theme: Dictionary = THEMES[tower_id]
	room.set_meta("system_floor_theme_id", str(theme["id"]))
	room.set_meta("system_floor_theme_number", floor_number)
	var root := Node3D.new()
	root.name = "FloorThemeIdentity"
	room.add_child(root)
	var props := Node3D.new()
	props.name = "FloorThemeProps"
	root.add_child(props)
	var base_material := _material(theme["color"], 0.48, 0.32)
	var accent_material := _material(theme["accent"], 0.62, 0.24)
	var stations: Array = theme["stations"]
	var display := Label3D.new()
	display.name = "ThemeDepartmentDisplay"
	display.text = "%s\n%s — الطابق %d" % [str(stations[(floor_number - 1) % stations.size()]), department, floor_number]
	display.position = Vector3(0.0, 4.6, -radius * 0.34)
	display.font_size = 26
	display.pixel_size = 0.012
	display.modulate = theme["accent"]
	props.add_child(display)
	var ring := MeshInstance3D.new()
	ring.name = "ThemeFloorRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = radius * 0.49
	ring_mesh.outer_radius = radius * 0.51
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 48
	ring.mesh = ring_mesh
	ring.position.y = 0.18
	ring.material_override = accent_material
	props.add_child(ring)
	for index in range(4):
		var angle := TAU * float(index) / 4.0 + PI * 0.25
		var station := Node3D.new()
		station.name = "ThemeStation_%02d" % index
		station.position = Vector3(cos(angle) * radius * 0.48, 0.0, sin(angle) * radius * 0.48)
		station.rotation.y = -angle
		props.add_child(station)
		var plinth := MeshInstance3D.new()
		plinth.name = "StationPlinth"
		var plinth_mesh := BoxMesh.new()
		plinth_mesh.size = Vector3(4.2, 1.1, 3.0)
		plinth.mesh = plinth_mesh
		plinth.position.y = 0.55
		plinth.material_override = base_material
		station.add_child(plinth)
		var console := MeshInstance3D.new()
		console.name = "StationDisplay"
		var console_mesh := BoxMesh.new()
		console_mesh.size = Vector3(2.8, 1.45, 0.18)
		console.mesh = console_mesh
		console.position = Vector3(0.0, 1.82, -1.05)
		console.material_override = accent_material
		station.add_child(console)
		var station_label := Label3D.new()
		station_label.text = str(stations[index])
		station_label.position = Vector3(0.0, 2.85, -1.0)
		station_label.font_size = 17
		station_label.pixel_size = 0.012
		station.add_child(station_label)
		if tower_id == "shopping_tower_baghdad":
			_add_shop_display(station, base_material, accent_material)
		elif tower_id == "antiques_heritage_tower_baghdad":
			_add_heritage_display(station, base_material, accent_material)
		elif tower_id == "technology_tower_baghdad":
			_add_tech_display(station, base_material, accent_material)
		elif tower_id == "business_investment_tower_baghdad":
			_add_business_display(station, base_material, accent_material)
		elif tower_id == "hunter_association_tower_baghdad":
			_add_hunter_display(station, base_material, accent_material)

static func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

static func _add_shop_display(parent: Node3D, base: Material, accent: Material) -> void:
	for index in range(3):
		var item := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.72, 0.9 + float(index % 2) * 0.45, 0.72)
		item.mesh = mesh
		item.position = Vector3(-0.95 + float(index) * 0.95, 1.2, 0.25)
		item.material_override = accent if index == 1 else base
		parent.add_child(item)

static func _add_sports_display(parent: Node3D, base: Material, accent: Material) -> void:
	var target := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.72
	mesh.bottom_radius = 0.72
	mesh.height = 0.22
	target.mesh = mesh
	target.position = Vector3(0.0, 1.45, 0.3)
	target.material_override = accent
	parent.add_child(target)
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(3.0, 0.18, 0.18)
	bar.mesh = bar_mesh
	bar.position = Vector3(0.0, 2.1, 0.3)
	bar.material_override = base
	parent.add_child(bar)

static func _add_heritage_display(parent: Node3D, base: Material, accent: Material) -> void:
	var pedestal := MeshInstance3D.new()
	pedestal.name = "ArtifactDisplayPedestal"
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 0.78
	pedestal_mesh.bottom_radius = 0.92
	pedestal_mesh.height = 0.72
	pedestal.mesh = pedestal_mesh
	pedestal.position = Vector3(0.0, 1.15, 0.25)
	pedestal.material_override = base
	parent.add_child(pedestal)
	var artifact_case := MeshInstance3D.new()
	artifact_case.name = "GlassArtifactDisplayCase"
	var case_mesh := BoxMesh.new()
	case_mesh.size = Vector3(1.35, 1.55, 1.1)
	artifact_case.mesh = case_mesh
	artifact_case.position = Vector3(0.0, 2.28, 0.25)
	artifact_case.material_override = accent
	parent.add_child(artifact_case)
	var archive_panel := MeshInstance3D.new()
	archive_panel.name = "ArtifactProvenancePanel"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(1.8, 0.9, 0.12)
	archive_panel.mesh = panel_mesh
	archive_panel.position = Vector3(0.0, 3.2, -0.42)
	archive_panel.material_override = base
	parent.add_child(archive_panel)

static func _add_tech_display(parent: Node3D, base: Material, accent: Material) -> void:
	for index in range(3):
		var node := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.62, 1.6, 0.62)
		node.mesh = mesh
		node.position = Vector3(-0.9 + float(index) * 0.9, 1.55, 0.3)
		node.material_override = accent if index == 1 else base
		parent.add_child(node)

static func _add_business_display(parent: Node3D, base: Material, accent: Material) -> void:
	var desk := MeshInstance3D.new()
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(2.8, 1.0, 1.3)
	desk.mesh = desk_mesh
	desk.position = Vector3(0.0, 0.9, 0.25)
	desk.material_override = base
	parent.add_child(desk)
	var display := MeshInstance3D.new()
	var display_mesh := BoxMesh.new()
	display_mesh.size = Vector3(2.2, 1.25, 0.12)
	display.mesh = display_mesh
	display.position = Vector3(0.0, 2.15, -0.55)
	display.material_override = accent
	parent.add_child(display)

static func _add_hunter_display(parent: Node3D, base: Material, accent: Material) -> void:
	var pillar := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.34
	mesh.bottom_radius = 0.48
	mesh.height = 2.0
	pillar.mesh = mesh
	pillar.position = Vector3(0.0, 2.0, 0.3)
	pillar.material_override = base
	parent.add_child(pillar)
	var crest := MeshInstance3D.new()
	var crest_mesh := SphereMesh.new()
	crest_mesh.radius = 0.52
	crest_mesh.height = 0.72
	crest.mesh = crest_mesh
	crest.position = Vector3(0.0, 3.2, 0.3)
	crest.material_override = accent
	parent.add_child(crest)
