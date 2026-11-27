extends RefCounted
class_name SYSTEMAntiqueMarketWorldBuilder

## Adds the dedicated 3D Yorknew-inspired market facilities to the existing
## Baghdad Antiques & Heritage Tower. It does not create a second marketplace.

static func build_floor(root: Node3D, floor_number: int, radius: float) -> void:
	if root == null or root.get_node_or_null("AntiqueMarketWorldExperience") != null:
		return
	var experience := Node3D.new()
	experience.name = "AntiqueMarketWorldExperience"
	experience.set_meta("system_tower_id", "antiques_heritage_tower_baghdad")
	experience.set_meta("system_tower_floor_number", floor_number)
	root.add_child(experience)

	var gold := _material(Color(0.68, 0.46, 0.17), 0.78, 0.24)
	var dark := _material(Color(0.035, 0.045, 0.06), 0.35, 0.32)
	var marble := _material(Color(0.58, 0.55, 0.48), 0.18, 0.34)
	var glow := _material(Color(0.08, 0.35, 0.52), 0.22, 0.2, Color(0.04, 0.38, 0.75), 1.8)
	var red_glow := _material(Color(0.42, 0.055, 0.035), 0.32, 0.24, Color(0.85, 0.12, 0.035), 2.0)

	match floor_number:
		29:
			_build_global_auction_hall(experience, radius, gold, dark, marble, glow)
		30:
			_build_secret_trader_lounge(experience, radius, gold, dark, red_glow)
		31:
			_build_authenticity_appraisal_lab(experience, radius, gold, marble, glow)
		32:
			_build_collector_reputation_hall(experience, radius, gold, dark, glow)
		_:
			experience.queue_free()


static func _build_global_auction_hall(root: Node3D, radius: float, gold: StandardMaterial3D, dark: StandardMaterial3D, marble: StandardMaterial3D, glow: StandardMaterial3D) -> void:
	_add_box(root, "AuctionStageBase", Vector3(0.0, 0.48, -3.0), Vector3(12.0, 0.9, 8.0), marble)
	_add_cylinder(root, "AuctionDisplayDais", Vector3(0.0, 1.25, -3.0), 2.6, 0.55, gold)
	_add_cylinder(root, "AuctionRelicTurntable", Vector3(0.0, 1.62, -3.0), 1.55, 0.16, glow)
	for row in range(3):
		var seat_radius := 7.0 + float(row) * 3.4
		for seat_index in range(10):
			var angle := TAU * float(seat_index) / 10.0
			var seat := _add_box(root, "AuctionSeat_%02d_%02d" % [row, seat_index],
				Vector3(cos(angle) * seat_radius, 0.62, sin(angle) * seat_radius + 2.0),
				Vector3(2.0, 1.15, 1.55), dark)
			seat.rotation.y = -angle
	for pillar_index in range(8):
		var angle := TAU * float(pillar_index) / 8.0
		_add_box(root, "AuctionGoldPillar_%02d" % pillar_index,
			Vector3(cos(angle) * radius * 0.52, 3.1, sin(angle) * radius * 0.52),
			Vector3(0.85, 6.2, 0.85), gold)
	var screen := MeshInstance3D.new()
	screen.name = "GlobalAuctionLiveScreen"
	var screen_mesh := QuadMesh.new()
	screen_mesh.size = Vector2(18.0, 7.0)
	screen.mesh = screen_mesh
	screen.position = Vector3(0.0, 7.0, -radius * 0.52)
	screen.material_override = glow
	root.add_child(screen)
	_add_label(root, "AuctionHallTitle", "المزاد العالمي للتحف | GLOBAL ANTIQUES AUCTION", Vector3(0.0, 10.8, -radius * 0.48), 22)
	_add_label(root, "AuctionHallSubtitle", "مزايدات موثقة • حجز آمن • سجل ملكية", Vector3(0.0, 6.8, -radius * 0.50), 14)
	_add_interaction(root, "GlobalAuctionHallInteraction", 29, "global_auction_hall",
		"قاعة المزاد العالمي — تصفح المزادات وشارك بالمزايدة", Vector3(0.0, 1.0, radius * 0.22))


static func _build_secret_trader_lounge(root: Node3D, radius: float, gold: StandardMaterial3D, dark: StandardMaterial3D, red_glow: StandardMaterial3D) -> void:
	_add_box(root, "SecretMarketBackWall", Vector3(0.0, 3.2, -radius * 0.48), Vector3(radius * 1.1, 6.4, 0.7), dark)
	_add_box(root, "SecretMarketCounter", Vector3(0.0, 1.0, -5.0), Vector3(17.0, 1.8, 3.0), gold)
	for stall_index in range(5):
		var x := -12.0 + float(stall_index) * 6.0
		_add_box(root, "SecretDealerBooth_%02d" % stall_index, Vector3(x, 2.8, -radius * 0.34), Vector3(4.5, 4.8, 2.4), dark)
		_add_box(root, "SecretDealerDisplay_%02d" % stall_index, Vector3(x, 3.6, -radius * 0.34 + 1.3), Vector3(3.2, 0.16, 1.0), red_glow)
		var dealer := MeshInstance3D.new()
		dealer.name = "SecretDealerSilhouette_%02d" % stall_index
		var body := CapsuleMesh.new()
		body.radius = 0.38
		body.height = 1.7
		dealer.mesh = body
		dealer.position = Vector3(x, 1.0, -radius * 0.34 + 2.0)
		dealer.material_override = dark
		root.add_child(dealer)
		var head := MeshInstance3D.new()
		head.name = "SecretDealerHead_%02d" % stall_index
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.28
		head_mesh.height = 0.56
		head.mesh = head_mesh
		head.position = dealer.position + Vector3(0.0, 1.1, 0.0)
		head.material_override = gold
		root.add_child(head)
	_add_label(root, "SecretMarketTitle", "السوق السري | THE HIDDEN EXCHANGE", Vector3(0.0, 7.2, -radius * 0.48), 21)
	_add_label(root, "SecretMarketWarning", "تجار نادرون • تحقق من المنشأ قبل أي صفقة", Vector3(0.0, 5.8, -radius * 0.46), 14)
	_add_interaction(root, "SecretTraderLoungeInteraction", 30, "secret_trader_lounge",
		"السوق السري — قابل التجار وافحص العروض النادرة", Vector3(0.0, 1.0, radius * 0.22))


static func _build_authenticity_appraisal_lab(root: Node3D, radius: float, gold: StandardMaterial3D, marble: StandardMaterial3D, glow: StandardMaterial3D) -> void:
	_add_box(root, "AppraisalWorkbench", Vector3(0.0, 1.0, -4.0), Vector3(14.0, 1.7, 5.0), marble)
	_add_box(root, "AppraisalAnalysisScreen", Vector3(0.0, 4.6, -radius * 0.46), Vector3(13.0, 5.0, 0.5), glow)
	for index in range(3):
		var scanner := MeshInstance3D.new()
		scanner.name = "AuthenticityScanner_%02d" % index
		var ring := TorusMesh.new()
		ring.inner_radius = 1.0
		ring.outer_radius = 1.16
		scanner.mesh = ring
		scanner.position = Vector3(-5.0 + float(index) * 5.0, 2.6, -4.0)
		scanner.material_override = gold
		root.add_child(scanner)
	_add_label(root, "AppraisalLabTitle", "مختبر فحص الأصالة والمنشأ | AUTHENTICITY LAB", Vector3(0.0, 8.0, -radius * 0.47), 20)
	_add_label(root, "AppraisalLabDetails", "فحص الحالة • مقارنة السجلات • تقرير موثق", Vector3(0.0, 6.5, -radius * 0.46), 14)
	_add_interaction(root, "AuthenticityAppraisalInteraction", 31, "authenticity_appraisal",
		"مكتب تقييم الأصالة — افحص قطعة من مقتنياتك", Vector3(0.0, 1.0, radius * 0.22))


static func _build_collector_reputation_hall(root: Node3D, radius: float, gold: StandardMaterial3D, dark: StandardMaterial3D, glow: StandardMaterial3D) -> void:
	_add_box(root, "CollectorHallStage", Vector3(0.0, 0.55, -3.0), Vector3(18.0, 1.0, 7.0), gold)
	_add_box(root, "CollectorReputationBoard", Vector3(0.0, 5.8, -radius * 0.46), Vector3(20.0, 8.0, 0.65), dark)
	for column in range(5):
		var x := -8.0 + float(column) * 4.0
		_add_box(root, "CollectorRankColumn_%02d" % column,
			Vector3(x, 2.0 + float(4 - column) * 0.42, -2.0),
			Vector3(2.2, 2.0 + float(4 - column) * 0.8, 2.0), glow if column == 0 else gold)
	_add_label(root, "CollectorHallTitle", "مجلس كبار الجامعين | COLLECTORS' PRESTIGE", Vector3(0.0, 10.4, -radius * 0.45), 21)
	_add_label(root, "CollectorHallSubtitle", "سمعة موثقة • صفقات مكتملة • تقارير أصالة", Vector3(0.0, 7.8, -radius * 0.45), 14)
	_add_interaction(root, "CollectorReputationInteraction", 32, "collector_reputation",
		"مجلس السمعة — راجع سمعتك وترتيب الجامعين", Vector3(0.0, 1.0, radius * 0.22))


static func _material(color: Color, metallic: float, roughness: float, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material


static func _add_box(root: Node3D, node_name: String, position: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	root.add_child(instance)
	return instance


static func _add_cylinder(root: Node3D, node_name: String, position: Vector3, radius: float, height: float, material: StandardMaterial3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	root.add_child(instance)


static func _add_label(root: Node3D, node_name: String, value: String, position: Vector3, font_size: int) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = value
	label.position = position
	label.font_size = font_size
	label.pixel_size = 0.012
	label.modulate = Color(0.94, 0.82, 0.58)
	root.add_child(label)


static func _add_interaction(root: Node3D, node_name: String, floor_number: int, facility_type: String, prompt: String, position: Vector3) -> void:
	var area := Area3D.new()
	area.name = node_name
	area.position = position
	area.collision_layer = 1
	area.collision_mask = 0
	area.monitoring = true
	area.add_to_group("system_interactable")
	area.set_meta("system_interaction_type", "antiques_world_facility")
	area.set_meta("system_antique_facility_type", facility_type)
	area.set_meta("system_tower_id", "antiques_heritage_tower_baghdad")
	area.set_meta("system_tower_floor_number", floor_number)
	area.set_meta("system_interaction_prompt", prompt)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.2
	collision.shape = sphere
	collision.position.y = 1.0
	area.add_child(collision)
	root.add_child(area)
