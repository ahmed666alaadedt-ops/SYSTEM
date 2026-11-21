extends Node3D
class_name ModernWorldCavePassageManager

## Builds walkable, collision-backed cave passages at the four existing
## mountain cave sites. This adds geometry only; no quest or reward is implied.

const CAVE_SITES := [
	{"name": "NorthernRidgeCave", "position": Vector2(430.0, -515.0), "style": 0},
	{"name": "WesternCliffCave", "position": Vector2(-690.0, 260.0), "style": 1},
	{"name": "EasternHighlandCave", "position": Vector2(760.0, 470.0), "style": 2},
	{"name": "FrostPassageCave", "position": Vector2(-80.0, -690.0), "style": 3}
]

const TUNNEL_LENGTH := 42.0
const TUNNEL_WIDTH := 9.0
const TUNNEL_HEIGHT := 6.0

var terrain: ModernContinentManager


func _ready() -> void:
	name = "ModernWorldCavePassageManager"
	terrain = get_parent().get_node_or_null("ModernContinent") as ModernContinentManager
	if terrain == null:
		push_warning("SYSTEM WORLD: cave passages require ModernContinent.")
		return
	_build_passages()
	print("SYSTEM WORLD: cave passage blockouts generated.")


func _build_passages() -> void:
	for site in CAVE_SITES:
		var point: Vector2 = site["position"]
		if not terrain.is_land_position(point.x, point.y):
			continue
		var cave := Node3D.new()
		cave.name = str(site["name"]) + "Passage"
		cave.position = Vector3(point.x, terrain.get_terrain_height(point.x, point.y), point.y)
		add_child(cave)
		_build_tunnel(cave, int(site["style"]))
		_build_chamber(cave, int(site["style"]))
		cave.add_to_group("system_world_landmarks")
		cave.set_meta("landmark_name", str(site["name"]))
		cave.set_meta("landmark_type", "cave_passage")
		cave.set_meta("system_geometry_blockout", true)
		cave.set_meta("system_requires_runtime_validation", true)


func _material(color: Color, roughness: float = 0.98) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result


func _build_tunnel(parent: Node3D, style: int) -> void:
	var rock_colors := [
		Color(0.25, 0.27, 0.28),
		Color(0.34, 0.29, 0.23),
		Color(0.27, 0.31, 0.34),
		Color(0.48, 0.51, 0.54)
	]
	var rock := _material(rock_colors[style])
	var floor_material := _material(Color(0.19, 0.18, 0.16))
	var floor_body := StaticBody3D.new()
	floor_body.name = "WalkableCaveFloorCollision"
	parent.add_child(floor_body)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(TUNNEL_WIDTH, 0.5, TUNNEL_LENGTH)
	var floor_visual := MeshInstance3D.new()
	floor_visual.name = "CavePassageFloor"
	floor_visual.mesh = floor_mesh
	floor_visual.position = Vector3(0.0, 0.0, -TUNNEL_LENGTH * 0.5)
	floor_visual.material_override = floor_material
	floor_body.add_child(floor_visual)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = floor_mesh.size
	floor_shape.shape = floor_box
	floor_shape.position = floor_visual.position
	floor_body.add_child(floor_shape)

	for side in [-1.0, 1.0]:
		var wall_body := StaticBody3D.new()
		wall_body.name = "CaveSideWallCollision"
		parent.add_child(wall_body)
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(0.7, TUNNEL_HEIGHT, TUNNEL_LENGTH)
		var wall := MeshInstance3D.new()
		wall.name = "CaveRockWall"
		wall.mesh = wall_mesh
		wall.position = Vector3(side * (TUNNEL_WIDTH * 0.5), TUNNEL_HEIGHT * 0.5, -TUNNEL_LENGTH * 0.5)
		wall.material_override = rock
		wall_body.add_child(wall)
		var wall_shape := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = wall_mesh.size
		wall_shape.shape = wall_box
		wall_shape.position = wall.position
		wall_body.add_child(wall_shape)

	_build_roof(parent, rock)


func _build_roof(parent: Node3D, material: Material) -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var arc_segments := 12
	var length_segments := 8
	for length_index in range(length_segments + 1):
		var z := -TUNNEL_LENGTH * float(length_index) / float(length_segments)
		for arc_index in range(arc_segments + 1):
			var angle := PI * float(arc_index) / float(arc_segments)
			vertices.append(Vector3(
				cos(angle) * TUNNEL_WIDTH * 0.5,
				2.5 + sin(angle) * TUNNEL_HEIGHT * 0.58,
				z
			))
	for length_index in range(length_segments):
		for arc_index in range(arc_segments):
			var a := length_index * (arc_segments + 1) + arc_index
			var b := a + 1
			var c := a + arc_segments + 1
			var d := c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var roof := MeshInstance3D.new()
	roof.name = "CaveArchedRockCeiling"
	roof.mesh = mesh
	roof.material_override = material
	roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(roof)


func _build_chamber(parent: Node3D, style: int) -> void:
	var chamber := Node3D.new()
	chamber.name = "CaveInnerChamber"
	chamber.position = Vector3(0.0, 0.0, -TUNNEL_LENGTH - 10.0)
	parent.add_child(chamber)
	var stone := _material(Color(0.22, 0.24, 0.25) if style != 3 else Color(0.39, 0.43, 0.47))
	var floor_body := StaticBody3D.new()
	floor_body.name = "ChamberFloorCollision"
	chamber.add_child(floor_body)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(22.0, 0.6, 20.0)
	var floor := MeshInstance3D.new()
	floor.name = "ChamberFloor"
	floor.mesh = floor_mesh
	floor.material_override = _material(Color(0.16, 0.17, 0.17))
	floor_body.add_child(floor)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = floor_mesh.size
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	for side in [-1.0, 1.0]:
		var wall := MeshInstance3D.new()
		wall.name = "ChamberRockWall"
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(1.0, 7.0, 20.0)
		wall.mesh = wall_mesh
		wall.position = Vector3(side * 11.0, 3.5, 0.0)
		wall.material_override = stone
		chamber.add_child(wall)
	var discovery := Area3D.new()
	discovery.name = "CaveChamberDiscoveryArea"
	var area_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 9.0
	area_shape.shape = sphere
	area_shape.position = Vector3(0.0, 2.0, 0.0)
	discovery.add_child(area_shape)
	discovery.set_meta("system_discovery_type", "cave_chamber")
	discovery.set_meta("system_discovery_name", parent.name)
	chamber.add_child(discovery)
