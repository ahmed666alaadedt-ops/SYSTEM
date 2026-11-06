
extends Node3D
class_name HistoricalWorldManager

# SYSTEM WORLD — Historical Civilizations
# Original world inspired by epic mythological action games.
# Greek, Mesopotamian, Egyptian and Chinese regions.

const WORLD_SIZE := 220.0

var stone_material: StandardMaterial3D
var dark_stone_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var bronze_material: StandardMaterial3D
var sand_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var grass_material: StandardMaterial3D
var energy_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_create_world_ground()
	_create_central_battle_arena()

	_create_greek_region()
	_create_mesopotamian_region()
	_create_egyptian_region()
	_create_chinese_region()

	_create_weapon_training_area()
	_create_world_landmarks()

	print("SYSTEM: Historical world environment created.")


# --------------------------------------------------
# MATERIALS
# --------------------------------------------------

func _create_materials() -> void:
	stone_material = _mat(Color(0.58, 0.53, 0.43), 0.95)
	dark_stone_material = _mat(Color(0.20, 0.22, 0.24), 0.9)
	gold_material = _mat(Color(0.83, 0.61, 0.22), 0.35, 0.7)
	bronze_material = _mat(Color(0.48, 0.28, 0.13), 0.4, 0.65)
	sand_material = _mat(Color(0.72, 0.58, 0.37), 1.0)
	roof_material = _mat(Color(0.35, 0.12, 0.10), 0.75)
	grass_material = _mat(Color(0.16, 0.27, 0.16), 1.0)

	energy_material = _mat(Color(0.95, 0.48, 0.12), 0.3, 0.2)
	energy_material.emission_enabled = true
	energy_material.emission = Color(1.0, 0.28, 0.04)
	energy_material.emission_energy_multiplier = 1.4


func _mat(
	color: Color,
	roughness: float = 0.8,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


# --------------------------------------------------
# BASIC BUILDING HELPERS
# --------------------------------------------------

func _box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name

	var mesh := BoxMesh.new()
	mesh.size = size

	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	parent.add_child(visual)

	return visual


func _solid_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	parent.add_child(body)

	_box(body, "Visual", Vector3.ZERO, size, material)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	return body


func _cylinder(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.85
	mesh.bottom_radius = radius
	mesh.height = height

	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	parent.add_child(visual)

	return visual


func _solid_cylinder(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	parent.add_child(body)

	_cylinder(
		body,
		"Visual",
		Vector3.ZERO,
		radius,
		height,
		material
	)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	body.add_child(collision)

	return body


# --------------------------------------------------
# WORLD GROUND
# --------------------------------------------------

func _create_world_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "HistoricalWorldGround"
	ground.position = Vector3(0, -0.5, 0)
	add_child(ground)

	_box(
		ground,
		"AncientLandVisual",
		Vector3.ZERO,
		Vector3(WORLD_SIZE, 1.0, WORLD_SIZE),
		grass_material
	)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(WORLD_SIZE, 1.0, WORLD_SIZE)
	collision.shape = shape
	ground.add_child(collision)

	# Stone roads connect the four civilizations.
	_solid_box(
		self,
		"CentralAncientRoad",
		Vector3(0, 0.04, 0),
		Vector3(12, 0.12, 190),
		stone_material
	)

	_solid_box(
		self,
		"CrossCivilizationRoad",
		Vector3(0, 0.05, 0),
		Vector3(190, 0.12, 12),
		stone_material
	)


# --------------------------------------------------
# CENTRAL BATTLE ARENA
# --------------------------------------------------

func _create_central_battle_arena() -> void:
	var arena := Node3D.new()
	arena.name = "AncientBattleArena"
	add_child(arena)

	# Arena floor.
	_solid_box(
		arena,
		"ArenaStoneFloor",
		Vector3(0, 0.12, 0),
		Vector3(48, 0.5, 48),
		dark_stone_material
	)

	# Circular-looking boundary pillars.
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var x := cos(angle) * 23.0
		var z := sin(angle) * 23.0

		_solid_cylinder(
			arena,
			"ArenaBoundaryColumn_%02d" % index,
			Vector3(x, 3.0, z),
			0.65,
			6.0,
			stone_material
		)

	# Spectator platforms.
	for side in [-1.0, 1.0]:
		_solid_box(
			arena,
			"ArenaGrandstand",
			Vector3(side * 30.0, 2.0, 0),
			Vector3(9.0, 4.0, 42.0),
			stone_material
		)

	# Decorative golden entrance.
	_solid_box(
		arena,
		"ArenaEntranceTop",
		Vector3(0, 7.0, -25.0),
		Vector3(13.0, 1.2, 2.0),
		gold_material
	)

	for side in [-1.0, 1.0]:
		_solid_cylinder(
			arena,
			"ArenaEntrancePillar",
			Vector3(side * 5.5, 3.5, -25.0),
			1.0,
			7.0,
			stone_material
		)


# --------------------------------------------------
# GREEK MYTHOLOGY REGION
# --------------------------------------------------

func _create_greek_region() -> void:
	var region := Node3D.new()
	region.name = "AncientGreekRegion"
	region.position = Vector3(-55, 0, -55)
	add_child(region)

	# Temple stairs.
	for index in range(5):
		_solid_box(
			region,
			"GreekTempleStep_%02d" % index,
			Vector3(0, 0.25 + float(index) * 0.35, -12.0 + float(index) * 1.4),
			Vector3(27.0 - float(index) * 2.0, 0.5, 3.0),
			stone_material
		)

	# Temple platform.
	_solid_box(
		region,
		"GreekTemplePlatform",
		Vector3(0, 2.0, -5),
		Vector3(25, 1, 17),
		stone_material
	)

	# Columns.
	for x in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		for z in [-11.0, 1.0]:
			_solid_cylinder(
				region,
				"GreekTempleColumn",
				Vector3(x, 6.0, z),
				0.8,
				8.0,
				stone_material
			)

	_solid_box(
		region,
		"GreekTempleRoof",
		Vector3(0, 10.2, -5),
		Vector3(27, 1.0, 18),
		stone_material
	)

	# Ancient statue.
	_cylinder(
		region,
		"GreekHeroStatueBase",
		Vector3(0, 1.5, 12),
		2.0,
		3.0,
		gold_material
	)

	_cylinder(
		region,
		"GreekHeroStatueBody",
		Vector3(0, 4.2, 12),
		0.85,
		3.0,
		bronze_material
	)

	_cylinder(
		region,
		"GreekHeroStatueHead",
		Vector3(0, 6.2, 12),
		0.65,
		1.0,
		gold_material
	)


# --------------------------------------------------
# MESOPOTAMIAN / BABYLON REGION
# --------------------------------------------------

func _create_mesopotamian_region() -> void:
	var region := Node3D.new()
	region.name = "MesopotamianCivilizationRegion"
	region.position = Vector3(55, 0, -55)
	add_child(region)

	# Babylonian ziggurat, layered in steps.
	for level in range(6):
		var width := 28.0 - float(level) * 4.0
		var height := 2.5

		_solid_box(
			region,
			"BabylonZigguratLevel_%02d" % level,
			Vector3(0, float(level) * height + height * 0.5, 0),
			Vector3(width, height, width),
			stone_material if level % 2 == 0 else sand_material
		)

	# Golden temple on top.
	_solid_box(
		region,
		"BabylonSummitTemple",
		Vector3(0, 16.0, 0),
		Vector3(9, 5, 9),
		gold_material
	)

	# Ancient gate towers.
	for side in [-1.0, 1.0]:
		_solid_box(
			region,
			"BabylonGateTower",
			Vector3(side * 19.0, 7.0, -17.0),
			Vector3(7, 14, 7),
			bronze_material
		)

	_solid_box(
		region,
		"BabylonGateLintel",
		Vector3(0, 14.0, -17.0),
		Vector3(45, 3, 7),
		gold_material
	)

	# Carved-looking relief bands.
	for y in [3.0, 7.0, 11.0]:
		_box(
			region,
			"BabylonZigguratReliefBand",
			Vector3(0, y, -14.2),
			Vector3(20, 0.35, 0.25),
			bronze_material
		)


# --------------------------------------------------
# ANCIENT EGYPT REGION
# --------------------------------------------------

func _create_egyptian_region() -> void:
	var region := Node3D.new()
	region.name = "AncientEgyptRegion"
	region.position = Vector3(-55, 0, 55)
	add_child(region)

	# Three monumental pyramid forms.
	for index in range(3):
		var pyramid := MeshInstance3D.new()
		pyramid.name = "EgyptianPyramid_%02d" % index

		var mesh := PrismMesh.new()
		mesh.size = Vector3(22, 20, 22)
		pyramid.mesh = mesh
		pyramid.position = Vector3(
			float(index) * 18.0 - 18.0,
			10.0,
			-8.0 - float(index % 2) * 10.0
		)
		pyramid.material_override = sand_material
		region.add_child(pyramid)

	# Obelisks.
	for x in [-15.0, 15.0]:
		var obelisk := MeshInstance3D.new()
		obelisk.name = "EgyptianObelisk"

		var mesh := PrismMesh.new()
		mesh.size = Vector3(3.0, 15.0, 3.0)
		obelisk.mesh = mesh
		obelisk.position = Vector3(x, 7.5, 18.0)
		obelisk.material_override = gold_material
		region.add_child(obelisk)

	# Temple hall.
	_solid_box(
		region,
		"EgyptianTempleFloor",
		Vector3(0, 0.3, 25),
		Vector3(34, 0.6, 18),
		stone_material
	)

	for x in [-13.0, -7.0, -1.0, 5.0, 11.0]:
		_solid_cylinder(
			region,
			"EgyptianTempleColumn",
			Vector3(x, 5.0, 25),
			1.0,
			10.0,
			gold_material
		)


# --------------------------------------------------
# ANCIENT CHINA REGION
# --------------------------------------------------

func _create_chinese_region() -> void:
	var region := Node3D.new()
	region.name = "AncientChinaRegion"
	region.position = Vector3(55, 0, 55)
	add_child(region)

	# Imperial palace platform.
	_solid_box(
		region,
		"ChineseImperialPalacePlatform",
		Vector3(0, 0.5, 0),
		Vector3(34, 1.0, 28),
		dark_stone_material
	)

	# Palace pillars.
	for x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		for z in [-8.0, 8.0]:
			_solid_cylinder(
				region,
				"ChinesePalacePillar",
				Vector3(x, 4.5, z),
				0.65,
				9.0,
				roof_material
			)

	# Multi-level imperial roofs.
	for level in range(3):
		var width := 28.0 - float(level) * 6.0
		_solid_box(
			region,
			"ChinesePalaceRoof_%02d" % level,
			Vector3(0, 9.5 + float(level) * 3.0, 0),
			Vector3(width, 0.8, width * 0.75),
			roof_material
		)

	# Static mythological dragon sculpture.
	_create_chinese_dragon_statue(region)


func _create_chinese_dragon_statue(parent: Node3D) -> void:
	var dragon := Node3D.new()
	dragon.name = "AncientChineseDragonStatue"
	dragon.position = Vector3(0, 0, 23)
	parent.add_child(dragon)

	_cylinder(
		dragon,
		"DragonPedestal",
		Vector3(0, 1.0, 0),
		3.0,
		2.0,
		gold_material
	)

	# Body segments.
	for index in range(7):
		var segment := MeshInstance3D.new()
		segment.name = "DragonBodySegment_%02d" % index

		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		segment.mesh = mesh
		segment.position = Vector3(
			sin(float(index) * 0.65) * 2.0,
			3.0 + float(index) * 0.25,
			float(index) * 1.6 - 5.0
		)
		segment.material_override = gold_material
		dragon.add_child(segment)

	# Dragon head.
	var head := MeshInstance3D.new()
	head.name = "DragonHead"

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 1.25
	head.mesh = head_mesh
	head.position = Vector3(0, 5.2, 7.0)
	head.material_override = bronze_material
	dragon.add_child(head)

	# Horns.
	for side in [-1.0, 1.0]:
		_cylinder(
			dragon,
			"DragonHorn",
			Vector3(side * 0.9, 6.4, 7.0),
			0.18,
			1.8,
			gold_material
		)


# --------------------------------------------------
# WEAPON TRAINING AREA
# --------------------------------------------------

func _create_weapon_training_area() -> void:
	var training := Node3D.new()
	training.name = "HistoricalWeaponTrainingGround"
	training.position = Vector3(0, 0, 55)
	add_child(training)

	_solid_box(
		training,
		"TrainingGroundFloor",
		Vector3(0, 0.15, 0),
		Vector3(42, 0.3, 28),
		stone_material
	)

	# Weapon display racks.
	for index in range(3):
		var rack := Node3D.new()
		rack.name = "WeaponRack_%02d" % index
		rack.position = Vector3(
			float(index) * 13.0 - 13.0,
			0,
			-8.0
		)
		training.add_child(rack)

		_solid_box(
			rack,
			"WeaponRackBase",
			Vector3(0, 1.0, 0),
			Vector3(5, 2, 1),
			dark_stone_material
		)

	# Sword display.
	_box(
		training,
		"TrainingSwordBlade",
		Vector3(-12.0, 3.0, -8.0),
		Vector3(0.18, 3.0, 0.12),
		bronze_material
	)
	_box(
		training,
		"TrainingSwordHandle",
		Vector3(-12.0, 1.25, -8.0),
		Vector3(0.65, 0.18, 0.25),
		gold_material
	)

	# Spear display.
	_cylinder(
		training,
		"TrainingSpearShaft",
		Vector3(0, 3.0, -8.0),
		0.09,
		4.5,
		stone_material
	)
	_cylinder(
		training,
		"TrainingSpearHead",
		Vector3(0, 5.3, -8.0),
		0.2,
		0.8,
		gold_material
	)

	# Bow display frame.
	_cylinder(
		training,
		"TrainingBowDisplay",
		Vector3(12.0, 3.0, -8.0),
		0.12,
		3.5,
		bronze_material
	)

	# Training dummies.
	for index in range(4):
		var x := float(index) * 8.0 - 12.0

		_solid_cylinder(
			training,
			"TrainingDummy_%02d" % index,
			Vector3(x, 1.6, 7.0),
			0.55,
			3.2,
			bronze_material
		)

		_cylinder(
			training,
			"TrainingDummyHead",
			Vector3(x, 3.5, 7.0),
			0.45,
			0.8,
			stone_material
		)


# --------------------------------------------------
# WORLD LANDMARKS
# --------------------------------------------------

func _create_world_landmarks() -> void:
	# Ancient stone monuments along the roads.
	for index in range(8):
		var side := -1.0 if index % 2 == 0 else 1.0
		var z := -80.0 + float(index) * 22.0

		_solid_cylinder(
			self,
			"AncientRoadMonument_%02d" % index,
			Vector3(side * 13.0, 2.5, z),
			0.9,
			5.0,
			stone_material
		)

	# Fire braziers at the arena entrance.
	for side in [-1.0, 1.0]:
		_solid_cylinder(
			self,
			"AncientBrazierBase",
			Vector3(side * 9.0, 1.0, -29.0),
			0.8,
			2.0,
			bronze_material
		)

		_cylinder(
			self,
			"AncientBrazierFlame",
			Vector3(side * 9.0, 2.5, -29.0),
			0.35,
			1.0,
			energy_material
		)
