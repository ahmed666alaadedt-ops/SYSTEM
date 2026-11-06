
extends Node3D
class_name HistoricalWorldManager

signal landmark_discovered(landmark_id: String, landmark_name: String)

const LANDMARKS := {
	"hercules_arches": {
		"name": "أقواس هرقل",
		"civilization": "العالم القديم",
		"region": "مضيق جبل طارق",
		"lore": "معلم أسطوري مرتبط بحدود العالم المعروف في الأساطير القديمة."
	},
	"atlantis": {
		"name": "أتلانتس",
		"civilization": "الحضارة الأسطورية",
		"region": "مدينة بحرية غامضة",
		"lore": "مدينة أسطورية غارقة، ووجودها التاريخي غير مثبت."
	},
	"alexandria_lighthouse": {
		"name": "منارة الإسكندرية",
		"civilization": "مصر القديمة",
		"region": "الإسكندرية",
		"lore": "منارة تاريخية عظيمة كانت من أشهر عجائب العالم القديم."
	},
	"babylon_tower": {
		"name": "برج بابل",
		"civilization": "حضارة بابل",
		"region": "بلاد الرافدين",
		"lore": "برج مستوحى من العمارة البابلية والأساطير المرتبطة ببرج بابل."
	},
	"ancient_rome": {
		"name": "روما القديمة",
		"civilization": "الإمبراطورية الرومانية",
		"region": "روما، إيطاليا",
		"lore": "مدينة رومانية تاريخية تضم المنتدى والمعابد والطرق والمباني العامة."
	},
	"roman_colosseum": {
		"name": "الكولوسيوم الروماني",
		"civilization": "الإمبراطورية الرومانية",
		"region": "روما، إيطاليا",
		"lore": "مدرج روماني ضخم استُخدم للعروض والمواجهات العامة."
	}
}

var discovered_landmarks: Array[String] = []


func _ready() -> void:
	name = "HistoricalCivilizationsEnvironment"

	_create_historical_ground()

	_build_hercules_arches()
	_build_atlantis()
	_build_alexandria_lighthouse()
	_build_babylon_tower()

	_build_ancient_rome()
	_build_roman_colosseum()

	print("SYSTEM WORLD: Historical landmarks created.")


# --------------------------------------------------
# MATERIALS AND BUILDING HELPERS
# --------------------------------------------------

func _material(
	color: Color,
	roughness: float = 0.85,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


func _add_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := BoxMesh.new()
	mesh.size = size

	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)

	return instance


func _add_cylinder(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	top_radius: float,
	bottom_radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 24

	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)

	return instance


func _add_sphere(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	radius: float,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0

	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)

	return instance


# --------------------------------------------------
# HISTORICAL LANDMARK INTERACTION AND MAP REGISTRATION
# --------------------------------------------------

func _get_landmark_region_id(landmark_id: String) -> String:
	match landmark_id:
		"hercules_arches":
			return "western_mediterranean"

		"atlantis":
			return "atlantis_legend"

		"alexandria_lighthouse":
			return "alexandria_egypt"

		"babylon_tower":
			return "babylon_mesopotamia"

		"ancient_rome", "roman_colosseum":
			return "rome_italy"

		_:
			return "historical_unknown"


func _create_landmark(
	landmark_id: String,
	parent: Node3D
) -> Node3D:
	var landmark := Node3D.new()
	landmark.name = landmark_id

	landmark.add_to_group("system_historical_landmark")
	landmark.add_to_group("system_interactable")

	var information: Dictionary = LANDMARKS[landmark_id]
	var region_id := _get_landmark_region_id(landmark_id)

	# معلومات المعلم التاريخي.
	landmark.set_meta("landmark_id", landmark_id)
	landmark.set_meta("landmark_name", information["name"])
	landmark.set_meta("civilization", information["civilization"])
	landmark.set_meta("region", information["region"])
	landmark.set_meta("lore", information["lore"])
	landmark.set_meta("discovered", false)

	# البيانات التي يحتاجها نظام التفاعل والخريطة.
	landmark.set_meta(
		"system_location_id",
		"historical_" + landmark_id
	)
	landmark.set_meta("system_region_id", region_id)
	landmark.set_meta(
		"system_display_name",
		str(information["name"])
	)
	landmark.set_meta("system_location_type", 5)
	landmark.set_meta(
		"system_interaction_prompt",
		"اكتشاف " + str(information["name"])
	)
	landmark.set_meta("system_fast_travel", false)

	# نقطة تصادم حتى يتمكن Raycast من التقاط المعلم.
	var interaction_area := Area3D.new()
	interaction_area.name = "LandmarkInteractionArea"
	interaction_area.position = Vector3(0.0, 6.0, 0.0)
	interaction_area.collision_layer = 1
	interaction_area.collision_mask = 1
	interaction_area.add_to_group("system_interaction_area")

	var collision := CollisionShape3D.new()
	collision.name = "LandmarkInteractionCollision"

	var shape := SphereShape3D.new()
	shape.radius = 10.0

	collision.shape = shape
	interaction_area.add_child(collision)
	landmark.add_child(interaction_area)

	parent.add_child(landmark)
	return landmark


# --------------------------------------------------
# HISTORICAL WORLD GROUND
# --------------------------------------------------

func _create_historical_ground() -> void:
	var ground_material := _material(
		Color(0.48, 0.39, 0.27)
	)

	var ground_body := StaticBody3D.new()
	ground_body.name = "HistoricalWorldGround"
	add_child(ground_body)

	var ground := MeshInstance3D.new()
	ground.name = "HistoricalTerrain"

	var plane := PlaneMesh.new()
	plane.size = Vector2(260.0, 260.0)

	ground.mesh = plane
	ground.position.y = -0.3
	ground.material_override = ground_material
	ground_body.add_child(ground)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(260.0, 0.6, 260.0)

	collision.shape = shape
	collision.position.y = -0.3
	ground_body.add_child(collision)


# --------------------------------------------------
# 1. HERCULES ARCHES
# --------------------------------------------------

func _build_hercules_arches() -> void:
	var landmark := _create_landmark(
		"hercules_arches",
		self
	)

	landmark.position = Vector3(-65.0, 0.0, -30.0)

	var stone := _material(Color(0.72, 0.64, 0.49))
	var dark_stone := _material(Color(0.43, 0.37, 0.29))

	for side in [-1.0, 1.0]:
		_add_cylinder(
			landmark,
			"HeraclesPillar",
			Vector3(side * 5.0, 5.0, 0.0),
			1.5, 2.0, 10.0,
			stone
		)

		_add_cylinder(
			landmark,
			"PillarCapital",
			Vector3(side * 5.0, 10.2, 0.0),
			2.1, 2.1, 0.7,
			dark_stone
		)

	var radius := 5.0
	var center_height := 10.0

	for index in range(13):
		var angle := PI * float(index) / 12.0

		var block := _add_box(
			landmark,
			"ArchStone_%02d" % index,
			Vector3(
				radius * cos(angle),
				center_height + radius * sin(angle),
				0.0
			),
			Vector3(2.0, 1.0, 2.0),
			stone
		)

		block.rotation.z = -angle

	_add_box(
		landmark,
		"HeraclesFoundation",
		Vector3(0.0, 0.25, 0.0),
		Vector3(17.0, 0.5, 8.0),
		dark_stone
	)


# --------------------------------------------------
# 2. ATLANTIS — LEGENDARY CITY
# --------------------------------------------------

func _build_atlantis() -> void:
	var landmark := _create_landmark(
		"atlantis",
		self
	)

	landmark.position = Vector3(65.0, 0.0, -65.0)

	var stone := _material(Color(0.48, 0.68, 0.69), 0.35, 0.25)
	var gold := _material(Color(0.85, 0.65, 0.28), 0.3, 0.65)

	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.04, 0.32, 0.43, 0.78)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness = 0.2

	var water := MeshInstance3D.new()
	water.name = "AtlantisWater"

	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(85.0, 85.0)

	water.mesh = water_mesh
	water.position.y = 0.2
	water.material_override = water_material
	landmark.add_child(water)

	for ring in range(3):
		var radius := 12.0 + float(ring) * 10.0

		var ring_node := Node3D.new()
		ring_node.name = "AtlantisCityRing_%d" % ring
		ring_node.position.y = 1.0 + float(ring) * 0.15
		landmark.add_child(ring_node)

		for index in range(16):
			var angle := TAU * float(index) / 16.0
			var x := radius * cos(angle)
			var z := radius * sin(angle)

			_add_cylinder(
				ring_node,
				"AtlantisColumn",
				Vector3(x, 2.0, z),
				0.55, 0.75, 4.0,
				stone
			)

			_add_sphere(
				ring_node,
				"ColumnCrown",
				Vector3(x, 4.1, z),
				0.85,
				gold
			)

	_add_cylinder(
		landmark,
		"AtlantisCentralPalace",
		Vector3(0.0, 4.0, 0.0),
		5.0, 7.0, 8.0,
		stone
	)

	_add_sphere(
		landmark,
		"AtlantisPalaceDome",
		Vector3(0.0, 8.5, 0.0),
		5.0,
		gold
	)

	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var x := 16.0 * cos(angle)
		var z := 16.0 * sin(angle)

		_add_cylinder(
			landmark,
			"AtlantisTower",
			Vector3(x, 7.0, z),
			1.3, 2.0, 14.0,
			stone
		)

		_add_sphere(
			landmark,
			"AtlantisTowerLight",
			Vector3(x, 14.5, z),
			1.2,
			gold
		)


# --------------------------------------------------
# 3. LIGHTHOUSE OF ALEXANDRIA — EGYPT
# --------------------------------------------------

func _build_alexandria_lighthouse() -> void:
	var landmark := _create_landmark(
		"alexandria_lighthouse",
		self
	)

	landmark.position = Vector3(65.0, 0.0, 35.0)

	var limestone := _material(Color(0.78, 0.70, 0.54))
	var upper_stone := _material(Color(0.88, 0.82, 0.67))
	var bronze := _material(Color(0.55, 0.38, 0.18), 0.35, 0.65)

	_add_box(
		landmark,
		"LighthouseFoundation",
		Vector3(0.0, 0.6, 0.0),
		Vector3(20.0, 1.2, 20.0),
		limestone
	)

	_add_box(
		landmark,
		"LighthouseLowerTower",
		Vector3(0.0, 6.0, 0.0),
		Vector3(15.0, 11.0, 15.0),
		limestone
	)

	_add_cylinder(
		landmark,
		"LighthouseMiddleTower",
		Vector3(0.0, 17.0, 0.0),
		5.0, 7.0, 12.0,
		upper_stone
	)

	_add_cylinder(
		landmark,
		"LighthouseUpperTower",
		Vector3(0.0, 26.0, 0.0),
		3.0, 5.0, 7.0,
		limestone
	)

	_add_cylinder(
		landmark,
		"LighthouseLanternBase",
		Vector3(0.0, 30.0, 0.0),
		4.0, 4.0, 1.0,
		bronze
	)

	_add_cylinder(
		landmark,
		"LighthouseLanternRoom",
		Vector3(0.0, 32.0, 0.0),
		2.5, 2.5, 3.0,
		bronze
	)

	var flame_material := StandardMaterial3D.new()
	flame_material.albedo_color = Color(1.0, 0.68, 0.2)
	flame_material.emission_enabled = true
	flame_material.emission = Color(1.0, 0.48, 0.12)
	flame_material.emission_energy_multiplier = 3.0

	_add_sphere(
		landmark,
		"LighthouseBeacon",
		Vector3(0.0, 35.0, 0.0),
		1.0,
		flame_material
	)

	for index in range(8):
		var angle := TAU * float(index) / 8.0

		_add_cylinder(
			landmark,
			"LighthouseOuterColumn",
			Vector3(
				8.5 * cos(angle),
				2.5,
				8.5 * sin(angle)
			),
			0.35, 0.45, 5.0,
			upper_stone
		)


# --------------------------------------------------
# 4. TOWER OF BABYLON — MESOPOTAMIA
# --------------------------------------------------

func _build_babylon_tower() -> void:
	var landmark := _create_landmark(
		"babylon_tower",
		self
	)

	landmark.position = Vector3(-65.0, 0.0, 65.0)

	var brick := _material(Color(0.62, 0.30, 0.17))
	var dark_brick := _material(Color(0.38, 0.19, 0.13))
	var gold := _material(Color(0.85, 0.65, 0.25), 0.35, 0.55)

	for layer in range(7):
		var width := 34.0 - float(layer) * 4.0
		var height := 3.0
		var y := float(layer) * height + height * 0.5

		var layer_material: Material = (
			brick if layer % 2 == 0 else dark_brick
		)

		_add_box(
			landmark,
			"BabylonTerrace_%02d" % layer,
			Vector3(0.0, y, 0.0),
			Vector3(width, height, width),
			layer_material
		)

		_add_box(
			landmark,
			"BabylonFrontDecoration_%02d" % layer,
			Vector3(0.0, y, -width * 0.5 - 0.08),
			Vector3(width, 0.35, 0.18),
			gold
		)

	_add_box(
		landmark,
		"BabylonSummitTemple",
		Vector3(0.0, 23.0, 0.0),
		Vector3(7.0, 4.0, 7.0),
		gold
	)

	_add_box(
		landmark,
		"BabylonTempleRoof",
		Vector3(0.0, 25.3, 0.0),
		Vector3(8.0, 0.8, 8.0),
		dark_brick
	)

	for side in [-1.0, 1.0]:
		_add_cylinder(
			landmark,
			"BabylonEntranceColumn",
			Vector3(side * 3.0, 4.0, -18.0),
			0.8, 1.0, 8.0,
			gold
		)

	_add_box(
		landmark,
		"BabylonEntrancePath",
		Vector3(0.0, 0.25, -23.0),
		Vector3(10.0, 0.5, 12.0),
		dark_brick
	)


# --------------------------------------------------
# 5. ANCIENT ROME — ROMAN FORUM
# --------------------------------------------------

func _build_ancient_rome() -> void:
	var landmark := _create_landmark(
		"ancient_rome",
		self
	)

	landmark.position = Vector3(0.0, 0.0, -75.0)

	var marble := _material(Color(0.78, 0.73, 0.63))
	var aged_marble := _material(Color(0.58, 0.53, 0.45))
	var roof_material := _material(Color(0.48, 0.27, 0.19))
	var bronze := _material(Color(0.55, 0.38, 0.18), 0.4, 0.6)

	_add_box(
		landmark,
		"RomanForumSquare",
		Vector3(0.0, 0.12, 0.0),
		Vector3(65.0, 0.25, 42.0),
		aged_marble
	)

	_add_box(
		landmark,
		"RomanMainRoad",
		Vector3(0.0, 0.18, 25.0),
		Vector3(75.0, 0.35, 10.0),
		marble
	)

	_add_box(
		landmark,
		"RomanTempleFoundation",
		Vector3(0.0, 1.0, -7.0),
		Vector3(25.0, 2.0, 18.0),
		aged_marble
	)

	_add_box(
		landmark,
		"RomanTempleMainHall",
		Vector3(0.0, 7.0, -7.0),
		Vector3(17.0, 10.0, 12.0),
		marble
	)

	_add_box(
		landmark,
		"RomanTempleRoof",
		Vector3(0.0, 13.0, -7.0),
		Vector3(23.0, 2.0, 17.0),
		roof_material
	)

	for index in range(7):
		var x := -9.0 + float(index) * 3.0

		_add_cylinder(
			landmark,
			"RomanTempleColumn_%02d" % index,
			Vector3(x, 5.0, -16.0),
			0.65, 0.8, 10.0,
			marble
		)

		_add_cylinder(
			landmark,
			"RomanTempleCapital_%02d" % index,
			Vector3(x, 10.2, -16.0),
			1.0, 1.0, 0.5,
			bronze
		)

	_add_box(
		landmark,
		"RomanSenateFoundation",
		Vector3(-23.0, 1.0, -5.0),
		Vector3(13.0, 2.0, 13.0),
		aged_marble
	)

	_add_box(
		landmark,
		"RomanSenateBuilding",
		Vector3(-23.0, 6.0, -5.0),
		Vector3(11.0, 9.0, 11.0),
		marble
	)

	_add_box(
		landmark,
		"RomanSenateRoof",
		Vector3(-23.0, 11.0, -5.0),
		Vector3(14.0, 1.5, 14.0),
		roof_material
	)

	var arch_position := Vector3(23.0, 0.0, -5.0)

	for side in [-1.0, 1.0]:
		_add_box(
			landmark,
			"RomanTriumphalArchPillar",
			arch_position + Vector3(side * 4.0, 4.0, 0.0),
			Vector3(2.0, 8.0, 3.0),
			marble
		)

	_add_box(
		landmark,
		"RomanTriumphalArchTop",
		arch_position + Vector3(0.0, 8.0, 0.0),
		Vector3(10.0, 2.0, 3.0),
		aged_marble
	)

	for index in range(10):
		var x := -28.0 + float(index) * 6.0

		_add_cylinder(
			landmark,
			"ForumColumn_%02d" % index,
			Vector3(x, 3.0, 17.0),
			0.45, 0.6, 6.0,
			marble
		)

	_add_cylinder(
		landmark,
		"RomanStatuePedestal",
		Vector3(0.0, 1.5, 8.0),
		2.0, 2.5, 3.0,
		bronze
	)

	_add_sphere(
		landmark,
		"RomanStatueFigure",
		Vector3(0.0, 4.0, 8.0),
		1.6,
		bronze
	)


# --------------------------------------------------
# 6. ROMAN COLOSSEUM — AMPHITHEATRE
# --------------------------------------------------

func _build_roman_colosseum() -> void:
	var landmark := _create_landmark(
		"roman_colosseum",
		self
	)

	landmark.position = Vector3(0.0, 0.0, 75.0)

	var outer_stone := _material(Color(0.72, 0.66, 0.55))
	var inner_stone := _material(Color(0.58, 0.51, 0.42))
	var arch_shadow := _material(Color(0.30, 0.27, 0.23))
	var sand := _material(Color(0.76, 0.59, 0.34))
	var seat_material := _material(Color(0.66, 0.57, 0.45))

	var outer_plaza := _add_cylinder(
		landmark,
		"ColosseumOuterPlaza",
		Vector3(0.0, 0.1, 0.0),
		29.0, 29.0, 0.2,
		inner_stone
	)
	outer_plaza.scale = Vector3(1.0, 1.0, 0.72)

	var arena_sand := _add_cylinder(
		landmark,
		"ColosseumArenaSand",
		Vector3(0.0, 0.45, 0.0),
		13.0, 13.0, 0.5,
		sand
	)
	arena_sand.scale = Vector3(1.0, 1.0, 0.72)

	for level in range(3):
		var radius := 23.0 - float(level) * 2.5
		var y := 2.0 + float(level) * 4.5
		var height := 4.0

		var tier := _add_cylinder(
			landmark,
			"ColosseumTier_%d" % level,
			Vector3(0.0, y, 0.0),
			radius,
			radius + 1.0,
			height,
			outer_stone if level != 1 else inner_stone
		)

		tier.scale = Vector3(1.0, 1.0, 0.72)

	for row in range(5):
		var radius := 17.0 - float(row) * 1.0
		var seat := _add_cylinder(
			landmark,
			"ColosseumSeatingRow_%d" % row,
			Vector3(0.0, 3.0 + float(row) * 1.15, 0.0),
			radius,
			radius + 1.0,
			0.8,
			seat_material
		)

		seat.scale = Vector3(1.0, 1.0, 0.72)

	for level in range(3):
		var y := 2.0 + float(level) * 4.5
		var radius_x := 23.5 - float(level) * 2.5
		var radius_z := radius_x * 0.72

		for index in range(32):
			var angle := TAU * float(index) / 32.0

			var x := radius_x * cos(angle)
			var z := radius_z * sin(angle)

			var pillar := _add_cylinder(
				landmark,
				"ColosseumPillar_%d_%d" % [level, index],
				Vector3(x, y, z),
				0.55, 0.7, 4.0,
				outer_stone
			)

			pillar.rotation.y = -angle

			var arch_marker := _add_box(
				landmark,
				"ColosseumArchFrame_%d_%d" % [level, index],
				Vector3(x, y + 2.05, z),
				Vector3(1.8, 0.35, 1.0),
				arch_shadow
			)

			arch_marker.rotation.y = -angle

	_add_box(
		landmark,
		"ColosseumMainEntrance",
		Vector3(0.0, 1.2, -24.0),
		Vector3(9.0, 2.4, 4.0),
		inner_stone
	)

	for side in [-1.0, 1.0]:
		_add_cylinder(
			landmark,
			"ColosseumEntranceTower",
			Vector3(side * 7.0, 5.0, -22.0),
			1.2, 1.6, 10.0,
			outer_stone
		)

	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var x := 18.0 * cos(angle)
		var z := 13.0 * sin(angle)

		_add_cylinder(
			landmark,
			"ColosseumUpperColumn_%d" % index,
			Vector3(x, 15.0, z),
			0.45, 0.55, 5.0,
			outer_stone
		)

	_add_cylinder(
		landmark,
		"ColosseumArenaMarker",
		Vector3(0.0, 0.75, 0.0),
		2.0, 2.0, 0.15,
		bronze_material()
	)


func bronze_material() -> StandardMaterial3D:
	return _material(Color(0.55, 0.34, 0.15), 0.4, 0.6)


# --------------------------------------------------
# LANDMARK DISCOVERY INTERFACE
# --------------------------------------------------

func discover_landmark(landmark_id: String) -> bool:
	if not LANDMARKS.has(landmark_id):
		return false

	if discovered_landmarks.has(landmark_id):
		return false

	discovered_landmarks.append(landmark_id)

	var landmark_node := get_node_or_null(landmark_id)

	if landmark_node != null:
		landmark_node.set_meta("discovered", true)

	var information: Dictionary = LANDMARKS[landmark_id]

	landmark_discovered.emit(
		landmark_id,
		str(information["name"])
	)

	print(
		"SYSTEM WORLD: Landmark discovered: ",
		information["name"]
	)

	return true


func get_landmark_information(landmark_id: String) -> Dictionary:
	if not LANDMARKS.has(landmark_id):
		return {}

	return LANDMARKS[landmark_id].duplicate(true)


func get_discovered_landmarks() -> Array[String]:
	return discovered_landmarks.duplicate()


func is_landmark_discovered(landmark_id: String) -> bool:
	return discovered_landmarks.has(landmark_id)
