extends Node3D
class_name BaghdadRepublicBridgeAccessManager

const BANK_RAMP_WIDTH := 6.0
const BANK_RAMP_THICKNESS := 0.42
const BANK_RAMP_SIDE_OFFSET := 12.0
const TOWER_PLATFORM_RADIUS := 64.0
const TOWER_PLATFORM_THICKNESS := 2.4
const TOWER_PLATFORM_EDGE_DISTANCE := 58.0
const EXPRESS_SKYWAY_WIDTH := 10.0
const EXPRESS_SKYWAY_THICKNESS := 0.8
const EXPRESS_SKYWAY_SEGMENT_LENGTH := 160.0
const EXPRESS_SKYWAY_SUPPORT_SPACING := 250.0
const EXPRESS_SKYWAY_NO_PYLON_RADIUS := 700.0

var deck_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var light_material: StandardMaterial3D
var support_material: StandardMaterial3D


func build(tower: Node3D, city_anchor: Vector3, route: Dictionary, terrain_manager: Node = null) -> bool:
	if tower == null or route.is_empty():
		return false
	var anchor_value: Array = route.get("tower_anchor_local_m", [])
	var bank_values: Array = route.get("bank_access_points_local_m", [])
	var bank_elevations: Array = [
		route.get("world_karkh_bank_elevation_m", NAN),
		route.get("world_rusafa_bank_elevation_m", NAN),
	]
	var centerline_values: Array = route.get("centerline_local_m", [])
	var support_points: Array = route.get("express_skyway_support_points_local_m", [])
	var manifest_skyway_start: Array = route.get("express_skyway_start_local_m", [])
	if anchor_value.size() != 2 or bank_values.size() != 2 or centerline_values.size() < 2:
		return false
	if bank_elevations.size() != 2 or not is_finite(float(bank_elevations[0])) or not is_finite(float(bank_elevations[1])):
		return false
	if support_points.size() < 5 or manifest_skyway_start.size() != 2:
		return false

	var target := Vector2(float(anchor_value[0]), float(anchor_value[1]))
	if Vector2(tower.position.x, tower.position.z).distance_to(target) > 0.5:
		push_warning("SYSTEM Baghdad bridge access: tower root does not match the verified bridge anchor.")
		return false

	var ground_y := float(route.get("world_ground_elevation_m", NAN))
	var bridge_y := float(route.get("world_bridge_deck_elevation_m", NAN))
	var water_y := float(route.get("world_river_surface_elevation_m", NAN))
	var platform_y := float(route.get("world_tower_platform_elevation_m", NAN))
	if not is_finite(ground_y) or not is_finite(bridge_y) or not is_finite(water_y) or not is_finite(platform_y):
		return false
	if platform_y - water_y < 18.0 or platform_y <= bridge_y:
		push_warning("SYSTEM Baghdad bridge access: insufficient verified clearance above the Tigris.")
		return false

	_create_materials()
	_create_tower_platform(tower)
	var centerline: Array[Vector2] = []
	for coordinate in centerline_values:
		if coordinate is Array and coordinate.size() >= 2:
			centerline.append(Vector2(float(coordinate[0]), float(coordinate[1])))
	if centerline.size() < 2:
		return false

	var direction := (centerline[centerline.size() - 1] - centerline[0]).normalized()
	if direction.length_squared() < 0.9:
		return false
	var side := Vector2(-direction.y, direction.x)
	var target_index := 0
	var nearest_distance := INF
	for index in range(centerline.size()):
		var distance := centerline[index].distance_to(target)
		if distance < nearest_distance:
			nearest_distance = distance
			target_index = index

	var karkh_bank := Vector2(float(bank_values[0][0]), float(bank_values[0][1]))
	var rusafa_bank := Vector2(float(bank_values[1][0]), float(bank_values[1][1]))
	var karkh_path: Array[Vector2] = [karkh_bank]
	for index in range(target_index + 1):
		var point := centerline[index] + side * BANK_RAMP_SIDE_OFFSET
		if karkh_path[karkh_path.size() - 1].distance_to(point) > 0.5:
			karkh_path.append(point)
	var karkh_platform_edge := target - direction * TOWER_PLATFORM_EDGE_DISTANCE + side * BANK_RAMP_SIDE_OFFSET
	if karkh_path[karkh_path.size() - 1].distance_to(karkh_platform_edge) > 0.5:
		karkh_path.append(karkh_platform_edge)

	var rusafa_path: Array[Vector2] = [rusafa_bank]
	for index in range(centerline.size() - 1, target_index - 1, -1):
		var point := centerline[index] - side * BANK_RAMP_SIDE_OFFSET
		if rusafa_path[rusafa_path.size() - 1].distance_to(point) > 0.5:
			rusafa_path.append(point)
	var rusafa_platform_edge := target + direction * TOWER_PLATFORM_EDGE_DISTANCE - side * BANK_RAMP_SIDE_OFFSET
	if rusafa_path[rusafa_path.size() - 1].distance_to(rusafa_platform_edge) > 0.5:
		rusafa_path.append(rusafa_platform_edge)

	var bank_corridors := Node3D.new()
	bank_corridors.name = "RepublicBridgeTwoBankAccessCorridors"
	add_child(bank_corridors)
	var karkh_length := _create_sloped_corridor(
		bank_corridors, karkh_path, float(bank_elevations[0]), platform_y,
		BANK_RAMP_WIDTH, BANK_RAMP_THICKNESS, "AlKarkhAccessRamp"
	)
	var rusafa_length := _create_sloped_corridor(
		bank_corridors, rusafa_path, float(bank_elevations[1]), platform_y,
		BANK_RAMP_WIDTH, BANK_RAMP_THICKNESS, "AlRusafaAccessRamp"
	)
	if karkh_length < 100.0 or rusafa_length < 100.0:
		push_warning("SYSTEM Baghdad bridge access: one of the two bank ramps could not be built.")
		return false

	var express_skyway := Node3D.new()
	express_skyway.name = "RepublicBridgeExpressSkyway"
	add_child(express_skyway)
	var city_direction := Vector2(target.x - city_anchor.x, target.y - city_anchor.z).normalized()
	var ring_start := Vector2(city_anchor.x, city_anchor.z) + city_direction * 580.0
	var ring_elevation := city_anchor.y + 34.0
	var skyway_points: Array[Vector2] = []
	var skyway_length := ring_start.distance_to(target)
	var skyway_steps := maxi(2, int(ceil(skyway_length / EXPRESS_SKYWAY_SEGMENT_LENGTH)))
	for index in range(skyway_steps + 1):
		skyway_points.append(ring_start.lerp(target, float(index) / float(skyway_steps)))
	var express_length := _create_sloped_corridor(
		express_skyway, skyway_points, ring_elevation, platform_y,
		EXPRESS_SKYWAY_WIDTH, EXPRESS_SKYWAY_THICKNESS, "SkyRailDeck"
	)
	var support_count := _create_skyway_supports(
		express_skyway,
		Vector2(float(manifest_skyway_start[0]), float(manifest_skyway_start[1])),
		ring_start, target, ring_elevation, platform_y, ground_y,
		support_points, terrain_manager
	)
	if support_count < 5:
		push_warning("SYSTEM Baghdad bridge access: fewer than five land-verified express skyway supports were built.")
		return false

	set_meta("republic_bridge_access_ready", true)
	set_meta("bank_access_corridor_count", 2)
	set_meta("karkh_access_ramp_length_m", round(karkh_length))
	set_meta("rusafa_access_ramp_length_m", round(rusafa_length))
	set_meta("express_skyway_length_m", round(express_length))
	set_meta("express_skyway_support_count", support_count)
	set_meta("river_surface_elevation_world_m", water_y)
	set_meta("bridge_deck_elevation_world_m", bridge_y)
	set_meta("tower_platform_elevation_world_m", platform_y)
	set_meta("river_clearance_to_tower_platform_m", round(platform_y - water_y, 2))
	set_meta("traffic_lane_clear", true)
	set_meta("tigris_navigation_corridor_clear", true)

	tower.set_meta("bridge_tower_access_ready", true)
	tower.set_meta("bridge_bank_access_count", 2)
	tower.set_meta("bridge_deck_elevation_world_m", bridge_y)
	tower.set_meta("river_surface_elevation_world_m", water_y)
	tower.set_meta("tower_platform_elevation_world_m", platform_y)
	tower.set_meta("river_clearance_m", round(platform_y - water_y, 2))
	tower.set_meta("district_connector_type", "express_skyway")
	return true


func _create_materials() -> void:
	deck_material = StandardMaterial3D.new()
	deck_material.albedo_color = Color(0.075, 0.14, 0.19)
	deck_material.metallic = 0.72
	deck_material.roughness = 0.3
	rail_material = StandardMaterial3D.new()
	rail_material.albedo_color = Color(0.42, 0.61, 0.68, 0.78)
	rail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rail_material.metallic = 0.42
	rail_material.roughness = 0.2
	light_material = StandardMaterial3D.new()
	light_material.albedo_color = Color(0.04, 0.7, 0.94)
	light_material.emission_enabled = true
	light_material.emission = Color(0.02, 0.48, 0.92)
	light_material.emission_energy_multiplier = 2.2
	support_material = StandardMaterial3D.new()
	support_material.albedo_color = Color(0.18, 0.25, 0.3)
	support_material.metallic = 0.78
	support_material.roughness = 0.32


func _create_tower_platform(tower: Node3D) -> void:
	var platform := MeshInstance3D.new()
	platform.name = "RepublicBridgeTowerSkyPlatform"
	var platform_mesh := CylinderMesh.new()
	platform_mesh.top_radius = TOWER_PLATFORM_RADIUS
	platform_mesh.bottom_radius = TOWER_PLATFORM_RADIUS + 4.0
	platform_mesh.height = TOWER_PLATFORM_THICKNESS
	platform.mesh = platform_mesh
	platform.position.y = -TOWER_PLATFORM_THICKNESS * 0.5
	platform.material_override = deck_material
	tower.add_child(platform)

	var platform_body := StaticBody3D.new()
	platform_body.name = "RepublicBridgeTowerPlatformCollision"
	var platform_collision := CollisionShape3D.new()
	var platform_shape := CylinderShape3D.new()
	platform_shape.radius = TOWER_PLATFORM_RADIUS
	platform_shape.height = TOWER_PLATFORM_THICKNESS
	platform_collision.shape = platform_shape
	platform_collision.position.y = -TOWER_PLATFORM_THICKNESS * 0.5
	platform_body.add_child(platform_collision)
	tower.add_child(platform_body)



func _create_sloped_corridor(
	parent: Node3D,
	path_points: Array[Vector2],
	start_y: float,
	end_y: float,
	width: float,
	thickness: float,
	name_prefix: String
) -> float:
	if path_points.size() < 2:
		return 0.0
	var total_length := 0.0
	var segment_lengths: Array[float] = []
	for index in range(path_points.size() - 1):
		var segment_length := path_points[index].distance_to(path_points[index + 1])
		segment_lengths.append(segment_length)
		total_length += segment_length
	if total_length < 1.0:
		return 0.0

	var travelled := 0.0
	for index in range(segment_lengths.size()):
		var segment_length := segment_lengths[index]
		var p0 := path_points[index]
		var p1 := path_points[index + 1]
		if segment_length < 1.0:
			travelled += segment_length
			continue
		var y0 := lerpf(start_y, end_y, travelled / total_length)
		var y1 := lerpf(start_y, end_y, (travelled + segment_length) / total_length)
		var center := Vector3(
			(p0.x + p1.x) * 0.5,
			(y0 + y1) * 0.5 - thickness * 0.5,
			(p0.y + p1.y) * 0.5
		)
		var segment := Node3D.new()
		segment.name = "%s_%02d" % [name_prefix, index]
		segment.position = center
		segment.look_at(Vector3(p1.x, y1 - thickness * 0.5, p1.y), Vector3.UP)
		parent.add_child(segment)

		var deck := MeshInstance3D.new()
		deck.name = "WalkableDeck"
		var deck_mesh := BoxMesh.new()
		deck_mesh.size = Vector3(width, thickness, segment_length + 0.6)
		deck.mesh = deck_mesh
		deck.material_override = deck_material
		deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		segment.add_child(deck)

		var body := StaticBody3D.new()
		body.name = "WalkableDeckCollision"
		var collision := CollisionShape3D.new()
		var collision_shape := BoxShape3D.new()
		collision_shape.size = deck_mesh.size
		collision.shape = collision_shape
		body.add_child(collision)
		segment.add_child(body)

		for side_sign in [-1.0, 1.0]:
			var rail := MeshInstance3D.new()
			rail.name = "SafetyRail_%s" % str(int(side_sign))
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(0.2, 1.25, segment_length + 0.6)
			rail.mesh = rail_mesh
			rail.position = Vector3(side_sign * (width * 0.5 - 0.1), 0.82, 0.0)
			rail.material_override = rail_material
			segment.add_child(rail)
			var rail_light := MeshInstance3D.new()
			rail_light.name = "SafetyRailLight_%s" % str(int(side_sign))
			var light_mesh := BoxMesh.new()
			light_mesh.size = Vector3(0.12, 0.08, segment_length - 1.0)
			rail_light.mesh = light_mesh
			rail_light.position = Vector3(side_sign * (width * 0.5 - 0.1), 0.28, 0.0)
			rail_light.material_override = light_material
			segment.add_child(rail_light)
		travelled += segment_length
	return total_length


func _create_skyway_supports(
	parent: Node3D,
	manifest_start: Vector2,
	actual_start: Vector2,
	finish: Vector2,
	start_y: float,
	end_y: float,
	fallback_ground_y: float,
	support_points: Array,
	terrain_manager: Node
) -> int:
	var manifest_length := manifest_start.distance_to(finish)
	if manifest_length < 900.0:
		return 0
	var support_count := 0
	for support_value in support_points:
		if not support_value is Array or support_value.size() != 2:
			continue
		var manifest_point := Vector2(float(support_value[0]), float(support_value[1]))
		var progress := clampf(manifest_start.distance_to(manifest_point) / manifest_length, 0.0, 1.0)
		var point := actual_start.lerp(finish, progress)
		if point.distance_to(finish) < EXPRESS_SKYWAY_NO_PYLON_RADIUS:
			continue
		var local_ground_y := fallback_ground_y
		if terrain_manager != null and terrain_manager.has_method("get_baghdad_osm_ground_height"):
			local_ground_y = float(terrain_manager.call("get_baghdad_osm_ground_height", point.x, point.y))
		elif terrain_manager != null and terrain_manager.has_method("get_terrain_height"):
			local_ground_y = float(terrain_manager.call("get_terrain_height", point.x, point.y))
		var deck_y := lerpf(start_y, end_y, progress)
		var support_height := deck_y - local_ground_y - EXPRESS_SKYWAY_THICKNESS
		if support_height < 4.0:
			continue
		var pylon := MeshInstance3D.new()
		pylon.name = "ExpressSkywaySupport_%02d" % support_count
		var pylon_mesh := CylinderMesh.new()
		pylon_mesh.top_radius = 1.7
		pylon_mesh.bottom_radius = 2.8
		pylon_mesh.height = support_height
		pylon.mesh = pylon_mesh
		pylon.position = Vector3(point.x, local_ground_y + support_height * 0.5, point.y)
		pylon.material_override = support_material
		pylon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(pylon)
		support_count += 1
	return support_count
