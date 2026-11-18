extends Node3D
class_name ModernWorldLightingManager

## Procedural street-light network for the generated city road corridors.
## Fixtures are cheap emissive meshes; only a capped nearby light pool uses real OmniLights.

const MAIN_ROAD_SPACING := 30.0
const SECONDARY_ROAD_SPACING := 42.0
const ACTIVE_LIGHT_BUDGET := 24
const LIGHT_RANGE := 19.0
const NIGHT_START := 18.2
const NIGHT_END := 5.8
const REFRESH_INTERVAL := 0.8

var region_manager: Node3D
var terrain: Node
var fixture_positions: Array[Vector3] = []
var active_lights: Array[OmniLight3D] = []
var elapsed := 0.0
var pole_material: StandardMaterial3D
var lamp_material: StandardMaterial3D
var fixture_root: Node3D


func _ready() -> void:
	name = "ModernWorldLightingManager"
	region_manager = get_parent() as Node3D
	if region_manager == null:
		return
	terrain = region_manager.get("terrain")
	if terrain == null:
		push_warning("SYSTEM Lighting: terrain is unavailable.")
		return
	_create_materials()
	_build_city_fixture_network()
	_create_dynamic_light_pool()
	_refresh_nearby_lights()
	print("SYSTEM WORLD: procedural city lighting fixtures = ", fixture_positions.size())


func _create_materials() -> void:
	pole_material = StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.075, 0.09, 0.11)
	pole_material.metallic = 0.72
	pole_material.roughness = 0.42

	lamp_material = StandardMaterial3D.new()
	lamp_material.albedo_color = Color(1.0, 0.78, 0.42)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(1.0, 0.62, 0.24)
	lamp_material.emission_energy_multiplier = 2.0


func _build_city_fixture_network() -> void:
	fixture_root = Node3D.new()
	fixture_root.name = "ProceduralStreetFixtures"
	add_child(fixture_root)

	var city_names: Array = region_manager.call("get_city_names")
	for city_name_value in city_names:
		var city_name := str(city_name_value)
		var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
		if anchor == Vector3.INF:
			continue

		# Main north/south and east/west boulevards.
		_add_corridor_lights(city_name, anchor, Vector2(0.0, -185.0), MAIN_ROAD_SPACING, 13.0)
		_add_corridor_lights(city_name, anchor, Vector2(185.0, 0.0), MAIN_ROAD_SPACING, 13.0)

		# Two ring-road segments use wider spacing and lower fixture density.
		_add_corridor_lights(city_name, Vector3(anchor.x, anchor.y, anchor.z - 145.0), Vector2(145.0, 0.0), SECONDARY_ROAD_SPACING, 8.0)
		_add_corridor_lights(city_name, Vector3(anchor.x, anchor.y, anchor.z + 145.0), Vector2(145.0, 0.0), SECONDARY_ROAD_SPACING, 8.0)

		_add_plaza_lanterns(city_name, anchor)
		_add_district_and_transport_lights(city_name, anchor)


func _add_district_and_transport_lights(city_name: String, anchor: Vector3) -> void:
	# District-scale pedestrian lighting: fixtures are placed at the edges of
	# each generated district block, not only on the two central boulevards.
	var district_offsets := [
		Vector2(0.0, 0.0), Vector2(-78.0, -52.0),
		Vector2(78.0, -52.0), Vector2(-78.0, 52.0),
		Vector2(78.0, 52.0), Vector2(0.0, -112.0),
		Vector2(0.0, 112.0), Vector2(0.0, 170.0)
	]
	for district_index in range(district_offsets.size()):
		var center: Vector2 = Vector2(anchor.x, anchor.z) + district_offsets[district_index]
		var offset_distance := 58.0 if district_index == 0 else 52.0
		for corner_x in [-1.0, 1.0]:
			for corner_z in [-1.0, 1.0]:
				_add_fixture(
					city_name + "_District_%02d" % district_index,
					center + Vector2(corner_x * offset_distance, corner_z * offset_distance),
					4.8
				)

	# Airport and rail forecourts receive lower pedestrian-scale fixtures.
	for hub_offset in [Vector2(205.0, -35.0), Vector2(-205.0, 35.0)]:
		var hub_center := Vector2(anchor.x, anchor.z) + hub_offset
		for side_x in [-1.0, 1.0]:
			for side_z in [-1.0, 1.0]:
				_add_fixture(
					city_name + "_TransportForecourt",
					hub_center + Vector2(side_x * 24.0, side_z * 13.0),
					5.2
				)


func _add_corridor_lights(city_name: String, start_3d: Vector3, offset: Vector2, spacing: float, road_width: float) -> void:
	var start := Vector2(start_3d.x, start_3d.z)
	var length := offset.length()
	if length <= 0.1:
		return
	var direction := offset.normalized()
	var side := Vector2(-direction.y, direction.x)
	var count := int(floor(length / spacing))
	for index in range(count + 1):
		var point := start + direction * minf(float(index) * spacing, length)
		for side_sign in [-1.0, 1.0]:
			var lamp_point := point + side * (road_width * 0.5 + 3.0) * side_sign
			_add_fixture(city_name, lamp_point)


func _add_plaza_lanterns(city_name: String, anchor: Vector3) -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var point := Vector2(anchor.x, anchor.z) + Vector2(cos(angle), sin(angle)) * 17.0
		_add_fixture(city_name + "_Plaza", point, 5.2)


func _add_fixture(city_name: String, point: Vector2, pole_height: float = 6.8) -> void:
	if not terrain.call("is_land_position", point.x, point.y):
		return
	var ground_y := float(terrain.call("get_terrain_height", point.x, point.y))
	var root := Node3D.new()
	root.name = city_name.replace(" ", "") + "_StreetFixture_%04d" % fixture_positions.size()
	root.position = Vector3(point.x, ground_y, point.y)
	fixture_root.add_child(root)

	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.075
	pole_mesh.bottom_radius = 0.13
	pole_mesh.height = pole_height
	pole.mesh = pole_mesh
	pole.position.y = pole_height * 0.5
	pole.material_override = pole_material
	root.add_child(pole)

	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(1.25, 0.10, 0.12)
	arm.mesh = arm_mesh
	arm.position = Vector3(0.48, pole_height - 0.15, 0.0)
	arm.material_override = pole_material
	root.add_child(arm)

	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.52, 0.16, 0.44)
	head.mesh = head_mesh
	head.position = Vector3(0.98, pole_height - 0.22, 0.0)
	head.material_override = lamp_material
	root.add_child(head)

	fixture_positions.append(Vector3(point.x, ground_y + pole_height - 0.25, point.y))


func _create_dynamic_light_pool() -> void:
	for index in range(ACTIVE_LIGHT_BUDGET):
		var light := OmniLight3D.new()
		light.name = "NearbyStreetLight_%02d" % index
		light.light_color = Color(1.0, 0.72, 0.43)
		light.light_energy = 0.0
		light.omni_range = LIGHT_RANGE
		light.shadow_enabled = false
		light.light_specular = 0.2
		add_child(light)
		active_lights.append(light)


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < REFRESH_INTERVAL:
		return
	elapsed = 0.0
	_refresh_nearby_lights()


func _refresh_nearby_lights() -> void:
	if fixture_positions.is_empty() or active_lights.is_empty():
		return
	var player := get_tree().root.find_child("Player", true, false) as Node3D
	if player == null:
		for light in active_lights:
			light.light_energy = 0.0
		return

	var hour := _get_local_hour()
	var night_factor := 1.0 if hour >= NIGHT_START or hour < NIGHT_END else 0.0
	var used: Dictionary = {}
	for light in active_lights:
		var best_index := -1
		var best_distance := INF
		for index in range(fixture_positions.size()):
			if used.has(index):
				continue
			var distance := player.global_position.distance_squared_to(fixture_positions[index])
			if distance < best_distance:
				best_distance = distance
				best_index = index
		if best_index < 0 or best_distance > 90.0 * 90.0:
			light.light_energy = 0.0
			continue
		used[best_index] = true
		light.global_position = fixture_positions[best_index]
		light.light_energy = 1.25 * night_factor


func _get_local_hour() -> float:
	var clock := Time.get_datetime_dict_from_system(false)
	return float(clock.get("hour", 12)) + float(clock.get("minute", 0)) / 60.0
