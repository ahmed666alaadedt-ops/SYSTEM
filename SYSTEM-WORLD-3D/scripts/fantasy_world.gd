extends Node3D

# SYSTEM WORLD - FANTASY WORLD
# Godot 4.3 | Android | Landscape

const COMMAND_CENTER := "res://scenes/command_center.tscn"

var player: CharacterBody3D
var camera_pivot: Node3D
var world_camera: Camera3D

var camera_yaw := 0.0
var camera_pitch := -0.25

var move_touch_index := -1
var look_touch_index := -1
var move_start := Vector2.ZERO
var touch_movement := Vector2.ZERO

const MOVE_SPEED := 6.0
const GRAVITY := 22.0


func _ready() -> void:
	_create_environment()
	_create_ground()
	_create_roads()

	_create_rivers()
	_create_lakes()
	_create_waterfalls()

	_create_great_forest()
	_create_world_tree()

	_create_elf_kingdom()
	_create_beastfolk_kingdom()
	_create_ogre_tribe()
	_create_goblin_kingdom()
	_create_human_kingdom()
	_create_demon_kingdom()

	_create_guild()
	_create_dungeon_gate()
	_create_challenge_tower()
	_create_dragon_mountain()
	_create_mythical_creatures()
	_create_caves()
	_create_trade_market()
	_create_healing_sanctuary()

	_create_player()
	_create_interface()


# ==================================================
# PLAYER MOVEMENT
# ==================================================

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var movement := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0

	movement += touch_movement
	movement = movement.limit_length(1.0)

	var forward := Vector3(
		-sin(camera_yaw), 0.0, -cos(camera_yaw)
	)

	var right := Vector3(
		cos(camera_yaw), 0.0, -sin(camera_yaw)
	)

	var direction := (
		right * movement.x + forward * -movement.y
	).normalized()

	player.velocity.x = direction.x * MOVE_SPEED
	player.velocity.z = direction.z * MOVE_SPEED

	if player.is_on_floor():
		player.velocity.y = -0.5
	else:
		player.velocity.y -= GRAVITY * delta

	player.move_and_slide()

	if direction.length() > 0.1:
		player.rotation.y = lerp_angle(
			player.rotation.y,
			atan2(direction.x, direction.z),
			delta * 8.0
		)

	camera_pivot.rotation.y = camera_yaw
	camera_pivot.rotation.x = camera_pitch


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().size.x * 0.48:
				if move_touch_index == -1:
					move_touch_index = event.index
					move_start = event.position
					touch_movement = Vector2.ZERO
			else:
				if look_touch_index == -1:
					look_touch_index = event.index
		else:
			if event.index == move_touch_index:
				move_touch_index = -1
				touch_movement = Vector2.ZERO

			if event.index == look_touch_index:
				look_touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index == move_touch_index:
			var offset := event.position - move_start
			touch_movement = Vector2(
				offset.x / 75.0,
				offset.y / 75.0
			).limit_length(1.0)

		elif event.index == look_touch_index:
			camera_yaw -= event.relative.x * 0.006
			camera_pitch = clamp(
				camera_pitch - event.relative.y * 0.006,
				-0.85, 0.2
			)

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			camera_yaw -= event.relative.x * 0.006
			camera_pitch = clamp(
				camera_pitch - event.relative.y * 0.006,
				-0.85, 0.2
			)

	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_return_to_center()


# ==================================================
# ENVIRONMENT
# ==================================================

func _create_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()

	sky_material.sky_top_color = Color(0.035, 0.07, 0.16)
	sky_material.sky_horizon_color = Color(0.35, 0.42, 0.48)
	sky_material.ground_bottom_color = Color(0.04, 0.07, 0.06)
	sky_material.ground_horizon_color = Color(0.18, 0.24, 0.20)

	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.68, 0.65)
	environment.ambient_light_energy = 0.9

	world_env.environment = environment
	add_child(world_env)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48, -32, 0)
	sunlight.light_energy = 1.1
	sunlight.shadow_enabled = true
	add_child(sunlight)


# ==================================================
# GROUND
# ==================================================

func _create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "FantasyWorldGround"

	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(220, 220)

	mesh_instance.mesh = plane
	mesh_instance.material_override = _mat(
		Color(0.16, 0.27, 0.16)
	)
	ground.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(220, 0.3, 220)
	collision.shape = shape
	collision.position.y = -0.15
	ground.add_child(collision)

	add_child(ground)


func _create_roads() -> void:
	_box(
		"MainNorthRoad",
		Vector3(0, 0.05, 0),
		Vector3(9, 0.1, 170),
		Color(0.43, 0.39, 0.29)
	)

	_box(
		"MainEastRoad",
		Vector3(0, 0.05, 0),
		Vector3(150, 0.1, 9),
		Color(0.43, 0.39, 0.29)
	)


# ==================================================
# RIVERS
# ==================================================

func _create_rivers() -> void:
	_box(
		"GreatRiverNorth",
		Vector3(-20, 0.08, -65),
		Vector3(95, 0.12, 7),
		Color(0.08, 0.40, 0.68),
		true
	)

	_box(
		"GreatRiverSouth",
		Vector3(20, 0.08, 75),
		Vector3(110, 0.12, 6),
		Color(0.08, 0.40, 0.68),
		true
	)

	_box(
		"RiverEast",
		Vector3(80, 0.08, 0),
		Vector3(6, 0.12, 100),
		Color(0.08, 0.40, 0.68),
		true
	)

	_box(
		"RiverWest",
		Vector3(-80, 0.08, 0),
		Vector3(6, 0.12, 100),
		Color(0.08, 0.40, 0.68),
		true
	)


# ==================================================
# LAKES
# ==================================================

func _create_lakes() -> void:
	_box(
		"CrystalLake",
		Vector3(75, 0.08, -75),
		Vector3(35, 0.12, 24),
		Color(0.08, 0.45, 0.72),
		true
	)

	_box(
		"ForestLake",
		Vector3(-75, 0.08, -75),
		Vector3(28, 0.12, 20),
		Color(0.08, 0.38, 0.62),
		true
	)

	_box(
		"DemonLavaLake",
		Vector3(75, 0.08, 75),
		Vector3(30, 0.12, 20),
		Color(0.85, 0.12, 0.025),
		true
	)

	_box(
		"BeastfolkMoonLake",
		Vector3(-75, 0.08, 75),
		Vector3(28, 0.12, 20),
		Color(0.10, 0.36, 0.58),
		true
	)


# ==================================================
# WATERFALLS
# ==================================================

func _create_waterfalls() -> void:
	for i in range(3):
		var x := -55.0 + float(i) * 55.0

		_box(
			"Waterfall_%d" % i,
			Vector3(x, 9, -88),
			Vector3(8, 18, 1),
			Color(0.16, 0.60, 0.85),
			true
		)


# ==================================================
# FOREST
# ==================================================

func _create_great_forest() -> void:
	for i in range(42):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (65.0 + float(i % 4) * 6.0)
		var z := -75.0 + float(i) * 3.5

		var height := 8.0 + float(i % 4) * 2.0

		_cylinder(
			"ForestTrunk_%d" % i,
			Vector3(x, height * 0.5, z),
			0.65,
			height,
			Color(0.24, 0.15, 0.09)
		)

		_sphere(
			"ForestCrown_%d" % i,
			Vector3(x, height + 2.0, z),
			3.5,
			Color(0.10, 0.30, 0.16)
		)


func _create_world_tree() -> void:
	var center := Vector3(0, 0, -105)

	_cylinder(
		"AncientWorldTree",
		center + Vector3(0, 17, 0),
		4.0,
		34.0,
		Color(0.29, 0.19, 0.12)
	)

	for i in range(6):
		_sphere(
			"WorldTreeCrown_%d" % i,
			center + Vector3(
				-8.0 + float(i) * 3.2,
				35.0 + float(i % 3) * 5.0,
				0
			),
			8.0,
			Color(0.12, 0.39, 0.23)
		)


# ==================================================
# ELF KINGDOM
# ==================================================

func _create_elf_kingdom() -> void:
	var center := Vector3(-48, 0, -32)

	_box(
		"ElfKingdom",
		center,
		Vector3(36, 0.5, 38),
		Color(0.25, 0.42, 0.32)
	)

	_box(
		"ElfRoyalPalace",
		center + Vector3(0, 5, -8),
		Vector3(18, 10, 12),
		Color(0.73, 0.82, 0.73)
	)

	for side in [-1.0, 1.0]:
		_cylinder(
			"ElfTower",
			center + Vector3(side * 12, 8, -8),
			1.4,
			16,
			Color(0.75, 0.85, 0.77)
		)

		_cone(
			"ElfTowerRoof",
			center + Vector3(side * 12, 17, -8),
			2.5,
			4,
			Color(0.20, 0.49, 0.39)
		)


# ==================================================
# BEASTFOLK KINGDOM
# ==================================================

func _create_beastfolk_kingdom() -> void:
	var center := Vector3(-48, 0, 42)

	_box(
		"BeastfolkKingdom",
		center,
		Vector3(38, 0.5, 36),
		Color(0.35, 0.30, 0.20)
	)

	_box(
		"BeastfolkGreatHall",
		center + Vector3(0, 5, -7),
		Vector3(20, 10, 14),
		Color(0.48, 0.32, 0.19)
	)

	# Separate humanoid races and their settlements.
	_create_beastfolk_race(
		"Foxfolk",
		center + Vector3(-12, 0, 12),
		Color(0.80, 0.35, 0.12),
		"fox"
	)

	_create_beastfolk_race(
		"Wolffolk",
		center + Vector3(-4, 0, 12),
		Color(0.38, 0.40, 0.46),
		"wolf"
	)

	_create_beastfolk_race(
		"Rabbitfolk",
		center + Vector3(4, 0, 12),
		Color(0.78, 0.72, 0.68),
		"rabbit"
	)

	_create_beastfolk_race(
		"Catfolk",
		center + Vector3(12, 0, 12),
		Color(0.76, 0.62, 0.38),
		"cat"
	)

	_create_beastfolk_race(
		"Tigerfolk",
		center + Vector3(-12, 0, 22),
		Color(0.88, 0.47, 0.12),
		"tiger"
	)

	_create_beastfolk_race(
		"Bearfolk",
		center + Vector3(-4, 0, 22),
		Color(0.38, 0.23, 0.15),
		"bear"
	)

	_create_beastfolk_race(
		"Deerfolk",
		center + Vector3(4, 0, 22),
		Color(0.68, 0.48, 0.29),
		"deer"
	)

	_create_beastfolk_race(
		"Birdfolk",
		center + Vector3(12, 0, 22),
		Color(0.35, 0.48, 0.68),
		"bird"
	)

	_create_beastfolk_race(
		"Reptilefolk",
		center + Vector3(0, 0, 32),
		Color(0.22, 0.48, 0.27),
		"reptile"
	)


# ==================================================
# HUMANOID BEASTFOLK RACE DISPLAY
# ==================================================

func _create_beastfolk_race(
	race_name: String,
	position: Vector3,
	color: Color,
	race_type: String
) -> void:
	var race := Node3D.new()
	race.name = race_name
	race.position = position
	add_child(race)

	# Human-like body.
	_cylinder(
		race_name + "_Body",
		Vector3(0, 1.2, 0),
		0.42,
		1.3,
		color
	)

	_sphere(
		race_name + "_Head",
		Vector3(0, 2.2, 0),
		0.42,
		color
	)

	# Human-like arms.
	_cylinder(
		race_name + "_LeftArm",
		Vector3(-0.55, 1.35, 0),
		0.13,
		0.9,
		color
	)

	_cylinder(
		race_name + "_RightArm",
		Vector3(0.55, 1.35, 0),
		0.13,
		0.9,
		color
	)

	# Human-like legs.
	_cylinder(
		race_name + "_LeftLeg",
		Vector3(-0.2, 0.35, 0),
		0.16,
		0.8,
		color
	)

	_cylinder(
		race_name + "_RightLeg",
		Vector3(0.2, 0.35, 0),
		0.16,
		0.8,
		color
	)

	# Animal ears, tail and special traits.
	match race_type:
		"fox":
			_ears(race_name, color, 0.32)
			_tail(race_name, color, Vector3(0, 0.9, 0.65))
			_tail(race_name + "_SecondTail", color, Vector3(0.3, 1.0, 0.6))

		"wolf":
			_ears(race_name, color, 0.35)
			_tail(race_name, color, Vector3(0, 1.0, 0.65))

		"rabbit":
			_ears(race_name, color, 0.55)
			_tail(race_name, Color.WHITE, Vector3(0, 1.0, 0.55))

		"cat":
			_ears(race_name, color, 0.25)
			_tail(race_name, color, Vector3(0, 1.0, 0.65))

		"tiger":
			_ears(race_name, color, 0.28)
			_tail(race_name, color, Vector3(0, 1.0, 0.65))

		"bear":
			_ears(race_name, color, 0.20)

		"deer":
			_ears(race_name, color, 0.35)
			_cone(
				race_name + "_LeftAntler",
				Vector3(-0.22, 2.85, 0),
				0.13,
				0.65,
				color
			)
			_cone(
				race_name + "_RightAntler",
				Vector3(0.22, 2.85, 0),
				0.13,
				0.65,
				color
			)

		"bird":
			_add_wings(race_name, color)

		"reptile":
			_tail(race_name, color, Vector3(0, 1.0, 0.7))


func _ears(
	race_name: String,
	color: Color,
	ear_height: float
) -> void:
	_cone(
		race_name + "_LeftEar",
		Vector3(-0.28, 2.75 + ear_height * 0.2, 0),
		0.16,
		ear_height,
		color
	)

	_cone(
		race_name + "_RightEar",
		Vector3(0.28, 2.75 + ear_height * 0.2, 0),
		0.16,
		ear_height,
		color
	)


func _tail(
	race_name: String,
	color: Color,
	position: Vector3
) -> void:
	_sphere(
		race_name + "_Tail",
		position,
		0.35,
		color
	)


func _add_wings(race_name: String, color: Color) -> void:
	_box(
		race_name + "_LeftWing",
		Vector3(-0.85, 1.7, -0.1),
		Vector3(0.9, 1.0, 0.15),
		color
	)

	_box(
		race_name + "_RightWing",
		Vector3(0.85, 1.7, -0.1),
		Vector3(0.9, 1.0, 0.15),
		color
	)


# ==================================================
# OGRE TRIBE
# ==================================================

func _create_ogre_tribe() -> void:
	var center := Vector3(-82, 0, 42)

	_box(
		"OgreTribeGround",
		center,
		Vector3(22, 0.4, 24),
		Color(0.31, 0.25, 0.19)
	)

	_box(
		"OgreGreatHall",
		center + Vector3(0, 5, -6),
		Vector3(14, 10, 12),
		Color(0.35, 0.25, 0.19)
	)

	for i in range(4):
		var x := -7.0 + float(i) * 4.5

		_cylinder(
			"OgreTribePillar_%d" % i,
			center + Vector3(x, 4, 8),
			0.8,
			8,
			Color(0.27, 0.21, 0.17)
		)


# ==================================================
# GOBLIN KINGDOM
# ==================================================

func _create_goblin_kingdom() -> void:
	var center := Vector3(82, 0, 42)

	_box(
		"GoblinKingdomGround",
		center,
		Vector3(25, 0.4, 25),
		Color(0.29, 0.31, 0.18)
	)

	_box(
		"GoblinChiefHall",
		center + Vector3(0, 3, -6),
		Vector3(12, 6, 10),
		Color(0.36, 0.28, 0.18)
	)

	for i in range(8):
		var x := -10.0 + float(i) * 3.0

		_box(
			"GoblinHouse_%d" % i,
			center + Vector3(x, 1.8, 7),
			Vector3(3, 3.6, 4),
			Color(0.38, 0.31, 0.20)
		)

		_cone(
			"GoblinHouseRoof_%d" % i,
			center + Vector3(x, 4.3, 7),
			2.3,
			2.0,
			Color(0.24, 0.20, 0.14)
		)

	# Goblin humanoid display.
	for i in range(5):
		var x := -8.0 + float(i) * 4.0

		_cylinder(
			"GoblinBody_%d" % i,
			center + Vector3(x, 1.0, 13),
			0.38,
			1.1,
			Color(0.35, 0.57, 0.24)
		)

		_sphere(
			"GoblinHead_%d" % i,
			center + Vector3(x, 1.9, 13),
			0.38,
			Color(0.35, 0.57, 0.24)
		)

		_cone(
			"GoblinEar_%d" % i,
			center + Vector3(x - 0.35, 2.0, 13),
			0.12,
			0.55,
			Color(0.35, 0.57, 0.24)
		)


# ==================================================
# HUMAN KINGDOM
# ==================================================

func _create_human_kingdom() -> void:
	var center := Vector3(48, 0, -32)

	_box(
		"HumanKingdom",
		center,
		Vector3(40, 0.4, 40),
		Color(0.43, 0.39, 0.31)
	)

	_box(
		"HumanRoyalCastle",
		center + Vector3(0, 7, -8),
		Vector3(22, 14, 14),
		Color(0.60, 0.57, 0.48)
	)

	for side in [-1.0, 1.0]:
		for depth in [-1.0, 1.0]:
			var pos := center + Vector3(
				side * 12,
				8,
				-8 + depth * 10
			)

			_box(
				"HumanCastleTower",
				pos,
				Vector3(5, 16, 5),
				Color(0.65, 0.62, 0.52)
			)

			_cone(
				"HumanCastleRoof",
				pos + Vector3(0, 9, 0),
				3.5,
				5,
				Color(0.50, 0.20, 0.17)
			)


# ==================================================
# DEMON KINGDOM
# ==================================================

func _create_demon_kingdom() -> void:
	var center := Vector3(48, 0, 42)

	_box(
		"DemonKingdom",
		center,
		Vector3(42, 0.4, 40),
		Color(0.20, 0.13, 0.15)
	)

	_box(
		"DemonRoyalFortress",
		center + Vector3(0, 9, -8),
		Vector3(24, 18, 16),
		Color(0.19, 0.17, 0.21)
	)

	for side in [-1.0, 1.0]:
		_cylinder(
			"DemonTower",
			center + Vector3(side * 13, 10, -8),
			2.0,
			20,
			Color(0.14, 0.12, 0.16)
		)

		_cone(
			"DemonTowerSpire",
			center + Vector3(side * 13, 21, -8),
			3.0,
			6,
			Color(0.48, 0.08, 0.13)
		)


# ==================================================
# GUILD
# ==================================================

func _create_guild() -> void:
	var center := Vector3(0, 0, 25)

	_box(
		"AdventurerGuild",
		center + Vector3(0, 4, 0),
		Vector3(20, 8, 13),
		Color(0.38, 0.31, 0.23)
	)


# ==================================================
# DUNGEON
# ==================================================

func _create_dungeon_gate() -> void:
	var center := Vector3(0, 0, -42)

	_box(
		"DungeonGateLeft",
		center + Vector3(-5, 4, 0),
		Vector3(2, 8, 2),
		Color(0.16, 0.20, 0.28)
	)

	_box(
		"DungeonGateRight",
		center + Vector3(5, 4, 0),
		Vector3(2, 8, 2),
		Color(0.16, 0.20, 0.28)
	)

	_box(
		"DungeonGateMagic",
		center + Vector3(0, 4, 0.8),
		Vector3(8, 6, 0.3),
		Color(0.12, 0.25, 0.62),
		true
	)


# ==================================================
# CHALLENGE TOWER
# ==================================================

func _create_challenge_tower() -> void:
	var center := Vector3(30, 0, 0)

	for i in range(6):
		_box(
			"ChallengeTowerFloor_%d" % i,
			center + Vector3(0, i * 3.0 + 1.5, 0),
			Vector3(13 - i * 1.5, 3, 13 - i * 1.5),
			Color(0.30, 0.34, 0.42)
		)

	_sphere(
		"ChallengeTowerCore",
		center + Vector3(0, 20, 0),
		2.5,
		Color(0.25, 0.65, 0.95),
		true
	)


# ==================================================
# DRAGON MOUNTAIN
# ==================================================

func _create_dragon_mountain() -> void:
	var center := Vector3(0, 0, -125)

	_cone(
		"DragonMountain",
		center + Vector3(0, 25, 0),
		25,
		50,
		Color(0.25, 0.26, 0.29)
	)

	_sphere(
		"DragonNest",
		center + Vector3(0, 42, 0),
		4,
		Color(0.43, 0.17, 0.12)
	)

	_sphere(
		"DragonFireCore",
		center + Vector3(0, 18, 15),
		2.5,
		Color(0.90, 0.23, 0.08),
		true
	)


# ==================================================
# MYTHICAL CREATURE REGIONS
# ==================================================

func _create_mythical_creatures() -> void:
	var creatures := [
		["AncientDragon", Vector3(0, 0, -125)],
		["SkyPhoenix", Vector3(75, 0, -75)],
		["SeaLeviathan", Vector3(75, 0, 75)],
		["ForestGuardian", Vector3(-75, 0, -75)],
		["StoneGiant", Vector3(-75, 0, 75)],
		["ShadowBeast", Vector3(0, 0, -55)],
		["CrystalSerpent", Vector3(75, 0, -20)],
		["ThunderGriffin", Vector3(-75, 0, -20)]
	]

	for creature in creatures:
		var creature_name: String = creature[0]
		var position: Vector3 = creature[1]

		_sphere(
			creature_name + "_DiscoveryMarker",
			position + Vector3(0, 3, 0),
			2.0,
			Color(0.65, 0.28, 0.85),
			true
		)


# ==================================================
# CAVES
# ==================================================

func _create_caves() -> void:
	var positions := [
		Vector3(-85, 0, -20),
		Vector3(85, 0, -20),
		Vector3(-85, 0, 65),
		Vector3(85, 0, 65)
	]

	for i in range(positions.size()):
		_box(
			"CaveEntrance_%d" % i,
			positions[i] + Vector3(0, 2, 0),
			Vector3(9, 5, 2),
			Color(0.10, 0.10, 0.12)
		)


# ==================================================
# TRADE MARKET
# ==================================================

func _create_trade_market() -> void:
	var center := Vector3(0, 0, 48)

	_box(
		"FantasyTradeSquare",
		center,
		Vector3(30, 0.2, 18),
		Color(0.52, 0.44, 0.31)
	)

	for i in range(6):
		var x := -12.0 + float(i) * 4.8

		_box(
			"TradeStall_%d" % i,
			center + Vector3(x, 2, 0),
			Vector3(3.5, 4, 4),
			Color(0.49, 0.29, 0.17)
		)


# ==================================================
# HEALING SANCTUARY
# ==================================================

func _create_healing_sanctuary() -> void:
	var center := Vector3(-28, 0, 15)

	_box(
		"HealingSanctuary",
		center + Vector3(0, 3, 0),
		Vector3(13, 6, 11),
		Color(0.70, 0.75, 0.66)
	)

	_sphere(
		"HealingCrystal",
		center + Vector3(0, 5, 7),
		1.8,
		Color(0.22, 0.85, 0.72),
		true
	)


# ==================================================
# PLAYER
# ==================================================

func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "FantasyPlayer"
	player.position = Vector3(0, 1.1, 12)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8

	body.mesh = capsule
	body.position.y = 0.9
	body.material_override = _mat(Color(0.18, 0.35, 0.58))
	player.add_child(body)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	player.add_child(collision)

	add_child(player)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	player.add_child(camera_pivot)

	world_camera = Camera3D.new()
	world_camera.position = Vector3(0, 3, 7.5)
	world_camera.current = true
	camera_pivot.add_child(world_camera)


# ==================================================
# UI
# ==================================================

func _create_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var title := Label.new()
	title.text = "SYSTEM WORLD | FANTASY WORLD"
	title.position = Vector2(22, 18)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override(
		"font_color",
		Color(0.65, 0.91, 0.84)
	)
	layer.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "ELVES | BEASTFOLK | OGRES | GOBLINS | HUMANS | DEMONS"
	subtitle.position = Vector2(22, 55)
	subtitle.add_theme_font_size_override("font_size", 15)
	layer.add_child(subtitle)

	var back_button := Button.new()
	back_button.text = "العودة إلى مركز القيادة"
	back_button.position = Vector2(22, 95)
	back_button.custom_minimum_size = Vector2(230, 48)
	back_button.pressed.connect(_return_to_center)
	layer.add_child(back_button)


func _return_to_center() -> void:
	if ResourceLoader.exists(COMMAND_CENTER):
		get_tree().change_scene_to_file(COMMAND_CENTER)
	else:
		push_warning("Command Center scene was not found.")


# ==================================================
# BUILDING HELPERS
# ==================================================

func _box(
	object_name: String,
	position: Vector3,
	size: Vector3,
	color: Color,
	emission: bool = false
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _mat(color, emission)

	add_child(mesh_instance)


func _cylinder(
	object_name: String,
	position: Vector3,
	radius: float,
	height: float,
	color: Color
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height

	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _mat(color)

	add_child(mesh_instance)


func _cone(
	object_name: String,
	position: Vector3,
	radius: float,
	height: float,
	color: Color
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height

	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _mat(color)

	add_child(mesh_instance)


func _sphere(
	object_name: String,
	position: Vector3,
	radius: float,
	color: Color,
	emission: bool = false
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0

	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _mat(color, emission)

	add_child(mesh_instance)


func _mat(
	color: Color,
	emission: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78

	if emission:
		material.emission_enabled = true
		material.emission = color

	return material
