extends Node
class_name SystemNPCCityNavigationManager

## Lightweight pedestrian waypoint graph aligned with the generated city street grid.
## This is a local prototype graph; it is not a real-world road dataset or NavMesh.

const GRID_RADIUS := 4
const GRID_SPACING := 34.0
const SIDEWALK_OFFSET := 4.2

var region_manager: Node
var cached_anchors: Dictionary = {}
var routes_requested := 0
var routes_found := 0

func setup(p_region_manager: Node) -> void:
	region_manager = p_region_manager
	if not is_instance_valid(region_manager) or not region_manager.has_method("get_city_anchor"):
		push_warning("SYSTEM Navigation: city region manager is unavailable.")
		set_process(false)
		return
	set_process(false)

func find_pedestrian_path(city_name: String, start: Vector3, target: Vector3) -> Array[Vector3]:
	routes_requested += 1
	var anchor := _get_anchor(city_name)
	if anchor == Vector3.INF:
		return [target]
	var start_node := _nearest_grid_node(start, anchor)
	var target_node := _nearest_grid_node(target, anchor)
	var node_path := _find_grid_path(start_node, target_node)
	if node_path.is_empty():
		return [target]
	var result: Array[Vector3] = []
	for node in node_path:
		var point := anchor + Vector3(float(node.x) * GRID_SPACING + SIDEWALK_OFFSET, 0.0,
			float(node.y) * GRID_SPACING + SIDEWALK_OFFSET)
		if result.is_empty() or result[result.size() - 1].distance_to(point) > 1.0:
			result.append(point)
	if result.is_empty() or result[result.size() - 1].distance_to(target) > 1.0:
		result.append(target)
	routes_found += 1
	return result

func _get_anchor(city_name: String) -> Vector3:
	if cached_anchors.has(city_name):
		return cached_anchors[city_name]
	if not is_instance_valid(region_manager):
		return Vector3.INF
	var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
	cached_anchors[city_name] = anchor
	return anchor

func _nearest_grid_node(point: Vector3, anchor: Vector3) -> Vector2i:
	var local_x := (point.x - anchor.x - SIDEWALK_OFFSET) / GRID_SPACING
	var local_z := (point.z - anchor.z - SIDEWALK_OFFSET) / GRID_SPACING
	return Vector2i(
		clampi(roundi(local_x), -GRID_RADIUS, GRID_RADIUS),
		clampi(roundi(local_z), -GRID_RADIUS, GRID_RADIUS)
	)

func _find_grid_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal:
			break
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = current + offset
			if abs(next.x) > GRID_RADIUS or abs(next.y) > GRID_RADIUS:
				continue
			if came_from.has(next):
				continue
			came_from[next] = current
			queue.append(next)
	if not came_from.has(goal):
		return []
	var reversed: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		reversed.append(cursor)
		cursor = came_from[cursor]
	reversed.append(start)
	reversed.reverse()
	return reversed

func get_navigation_status() -> Dictionary:
	return {
		"active": is_instance_valid(region_manager),
		"model": "generated_city_sidewalk_waypoint_grid",
		"grid_radius": GRID_RADIUS,
		"grid_spacing_m": GRID_SPACING,
		"routes_requested": routes_requested,
		"routes_found": routes_found,
		"uses_real_road_data": false,
		"uses_navigation_mesh": false
	}
