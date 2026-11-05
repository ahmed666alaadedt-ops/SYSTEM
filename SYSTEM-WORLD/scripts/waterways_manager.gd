extends Node3D
class_name SystemWaterwaysManager

# SYSTEM WORLD - Rivers, Lakes, Dams and Bridges
# Initial procedural environment system for Godot 4.

const RIVER_POSITION := Vector3(29.0, 0.42, -55.0)
const RIVER_SIZE := Vector2(9.0, 150.0)

const LAKE_POSITION := Vector3(29.0, 0.44, -126.0)
const LAKE_SIZE := Vector2(28.0, 23.0)

const BRIDGE_POSITION := Vector3(29.0, 2.15, -55.0)
const DAM_POSITION := Vector3(29.0, 0.0, -147.0)

var water_material: ShaderMaterial
var land_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var concrete_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var metal_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_create_river()
	_create_lake()
	_create_bridge()
	_create_dam()
	_create_waterfall()
	_create_lakeside_details()

	print("SYSTEM WORLD: Waterways environment initialized.")


# --------------------------------------------------
# MATERIALS
# --------------------------------------------------

func _create_materials() -> void:
	land_material = StandardMaterial3D.new()
	land_material.albedo_color = Color(0.24, 0.29, 0.20)
	land_material.roughness = 0.95

	stone_material = StandardMaterial3D.new()
	stone_material.albedo_color = Color(0.34, 0.35, 0.32)
	stone_material.roughness = 0.9

	concrete_material = StandardMaterial3D.new()
	concrete_material.albedo_color = Color(0.43, 0.45, 0.46)
	concrete_material.roughness = 0.82

	bridge_material = StandardMaterial3D.new()
	bridge_material.albedo_color = Color(0.30, 0.27, 0.22)
	bridge_material.roughness = 0.8

	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color(0.12, 0.17, 0.20)
	metal_material.metallic = 0.72
	metal_material.roughness = 0.35

	_create_water_material()


func _create_water_material() -> void:
	var shader := Shader.new()

	shader.code = """
shader_type spatial;
render_mode cull_disabled;

uniform vec4 water_color : source_color =
	vec4(0.025, 0.30, 0.39, 1.0);

uniform float wave_strength = 0.055;
uniform float wave_speed = 1.0;
uniform float wave_frequency = 2.0;

void vertex() {
	float wave_a = sin(
		UV.x * 38.0 + TIME * wave_speed
	);

	float wave_b = cos(
		UV.y * 31.0 - TIME * wave_speed * 0.72
	);

	float wave_c = sin(
		(UV.x + UV.y) * 24.0 + TIME * 0.65
	);

	VERTEX.y += (
		wave_a * 0.45 +
		wave_b * 0.35 +
		wave_c * 0.20
	) * wave_strength;
}

void fragment() {
	float movement = sin(
		(UV.x * 35.0) +
		(UV.y * 22.0) +
		TIME * wave_speed
	);

	float highlights = smoothstep(
		0.72,
		0.98,
		movement * 0.5 + 0.5
	);

	ALBEDO = water_color.rgb +
		vec3(0.035, 0.075, 0.085) * highlights;

	METALLIC = 0.22;
	ROUGHNESS = 0.16;
	SPECULAR = 0.85;
}
"""

	water_material = ShaderMaterial.new()
	water_material.shader = shader


# --------------------------------------------------
# RIVER
# --------------------------------------------------

func _create_river() -> void:
	var river := Node3D.new()
	river.name = "ModernWorldRiver"
	add_child(river)

	var river_mesh := MeshInstance3D.new()
	river_mesh.name = "AnimatedRiverSurface"

	var plane := PlaneMesh.new()
	plane.size = RIVER_SIZE
	plane.subdivide_width = 48
	plane.subdivide_depth = 128

	river_mesh.mesh = plane
	river_mesh.position = RIVER_POSITION
	river_mesh.material_override = water_material
	river_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	river.add_child(river_mesh)

	_create_river_banks(river)


func _create_river_banks(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var bank := StaticBody3D.new()
		bank.name = "RiverBank"
		bank.position = Vector3(
			29.0 + side * 6.0,
			0.05,
			-55.0
		)
		parent.add_child(bank)

		var bank_mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.8, 0.65, 150.0)

		bank_mesh.mesh = box
		bank_mesh.position.y = 0.15
		bank_mesh.material_override = land_material
		bank.add_child(bank_mesh)

		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.8, 0.65, 150.0)

		collision.shape = shape
		collision.position.y = 0.15
		bank.add_child(collision)


# --------------------------------------------------
# LAKE
# --------------------------------------------------

func _create_lake() -> void:
	var lake := Node3D.new()
	lake.name = "ModernWorldLake"
	add_child(lake)

	var lake_surface := MeshInstance3D.new()
	lake_surface.name = "AnimatedLakeSurface"

	var plane := PlaneMesh.new()
	plane.size = LAKE_SIZE
	plane.subdivide_width = 48
	plane.subdivide_depth = 48

	lake_surface.mesh = plane
	lake_surface.position = LAKE_POSITION
	lake_surface.material_override = water_material
	lake_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	lake.add_child(lake_surface)

	_create_lake_shore(lake)


func _create_lake_shore(parent: Node3D) -> void:
	for index in range(32):
		var angle := TAU * float(index) / 32.0

		var rock := MeshInstance3D.new()
		rock.name = "LakeShoreRock_%02d" % index

		var sphere := SphereMesh.new()
		sphere.radius = 0.65
		sphere.height = 0.9

		rock.mesh = sphere

		var radius_x := 14.7
		var radius_z := 12.2

		rock.position = Vector3(
			29.0 + cos(angle) * radius_x,
			0.15,
			-126.0 + sin(angle) * radius_z
		)

		rock.scale = Vector3(
			1.0 + float(index % 3) * 0.25,
			0.65,
			0.8 + float(index % 2) * 0.2
		)

		rock.material_override = stone_material
		parent.add_child(rock)


# --------------------------------------------------
# BRIDGE
# --------------------------------------------------

func _create_bridge() -> void:
	var bridge := StaticBody3D.new()
	bridge.name = "ModernWorldRiverBridge"
	bridge.position = BRIDGE_POSITION
	add_child(bridge)

	var deck := MeshInstance3D.new()
	deck.name = "BridgeDeck"

	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(18.0, 0.65, 3.8)

	deck.mesh = deck_mesh
	deck.material_override = bridge_material
	bridge.add_child(deck)

	var deck_collision := CollisionShape3D.new()
	var deck_shape := BoxShape3D.new()
	deck_shape.size = Vector3(18.0, 0.65, 3.8)

	deck_collision.shape = deck_shape
	bridge.add_child(deck_collision)

	_create_bridge_supports(bridge)
	_create_bridge_rails(bridge)


func _create_bridge_supports(parent: Node3D) -> void:
	for x_offset in [-7.2, 7.2]:
		var support := MeshInstance3D.new()
		support.name = "BridgeStoneSupport"

		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.0, 2.6, 3.2)

		support.mesh = mesh
		support.position = Vector3(
			x_offset,
			-1.3,
			0.0
		)

		support.material_override = concrete_material
		parent.add_child(support)


func _create_bridge_rails(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "BridgeMetalRail"

		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(18.0, 0.18, 0.18)

		rail.mesh = rail_mesh
		rail.position = Vector3(
			0.0,
			0.48,
			side * 1.72
		)

		rail.material_override = metal_material
		parent.add_child(rail)

		for index in range(13):
			var post := MeshInstance3D.new()
			post.name = "BridgeRailPost"

			var post_mesh := BoxMesh.new()
			post_mesh.size = Vector3(0.14, 0.8, 0.14)

			post.mesh = post_mesh
			post.position = Vector3(
				-8.5 + float(index) * 1.42,
				0.30,
				side * 1.72
			)

			post.material_override = metal_material
			parent.add_child(post)


# --------------------------------------------------
# DAM
# --------------------------------------------------

func _create_dam() -> void:
	var dam := StaticBody3D.new()
	dam.name = "ModernWorldHydroelectricDam"
	dam.position = DAM_POSITION
	add_child(dam)

	var wall := MeshInstance3D.new()
	wall.name = "MainDamWall"

	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(22.0, 7.0, 2.5)

	wall.mesh = wall_mesh
	wall.position = Vector3(0.0, 3.5, 0.0)
	wall.material_override = concrete_material
	dam.add_child(wall)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(22.0, 7.0, 2.5)

	collision.shape = shape
	collision.position = Vector3(0.0, 3.5, 0.0)
	dam.add_child(collision)

	_create_dam_tower(dam)


func _create_dam_tower(parent: Node3D) -> void:
	var tower := MeshInstance3D.new()
	tower.name = "DamControlBuilding"

	var mesh := BoxMesh.new()
	mesh.size = Vector3(5.0, 5.0, 4.0)

	tower.mesh = mesh
	tower.position = Vector3(7.0, 9.5, 0.0)
	tower.material_override = concrete_material
	parent.add_child(tower)

	var roof := MeshInstance3D.new()
	roof.name = "DamControlRoof"

	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(5.6, 0.35, 4.6)

	roof.mesh = roof_mesh
	roof.position = Vector3(7.0, 12.15, 0.0)
	roof.material_override = metal_material
	parent.add_child(roof)


# --------------------------------------------------
# WATERFALL / SPILLWAY
# --------------------------------------------------

func _create_waterfall() -> void:
	var waterfall := MeshInstance3D.new()
	waterfall.name = "DamWaterfall"

	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 5.5)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24

	waterfall.mesh = plane
	waterfall.rotation_degrees.x = 90.0
	waterfall.position = Vector3(
		29.0,
		2.8,
		-148.7
	)

	waterfall.material_override = water_material
	waterfall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(waterfall)


# --------------------------------------------------
# LAKESIDE DETAILS
# --------------------------------------------------

func _create_lakeside_details() -> void:
	for index in range(8):
		var reed := MeshInstance3D.new()
		reed.name = "LakesideReed"

		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.025
		mesh.bottom_radius = 0.055
		mesh.height = 1.15

		reed.mesh = mesh
		reed.position = Vector3(
			18.0 + float(index) * 0.65,
			0.55,
			-118.0 - float(index % 3) * 2.0
		)

		reed.material_override = land_material
		add_child(reed)
