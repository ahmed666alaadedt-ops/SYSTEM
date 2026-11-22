extends Node3D
class_name BaghdadOSMDoorInteraction

## Source-verified Baghdad OSM door with a real hinged leaf and local building interior.

var door_pivot: Node3D
var interior_root: Node3D
var roof_node: MeshInstance3D
var inward_direction := Vector3.FORWARD
var restricted := false
var door_open := false
var building_osm_id := ""
var entrance_osm_id := ""
var _door_tween: Tween


func configure(
	p_door_pivot: Node3D,
	p_restricted: bool,
	p_building_osm_id: String,
	p_entrance_osm_id: String,
	p_interior_root: Node3D,
	p_roof_node: MeshInstance3D,
	p_inward_direction: Vector3
) -> void:
	door_pivot = p_door_pivot
	restricted = p_restricted
	building_osm_id = p_building_osm_id
	entrance_osm_id = p_entrance_osm_id
	interior_root = p_interior_root
	roof_node = p_roof_node
	inward_direction = p_inward_direction.normalized()
	if inward_direction.length_squared() < 0.5:
		inward_direction = global_transform.basis.z.normalized()
	door_open = false
	set_meta("system_door_open", false)
	set_meta("system_access_state", "restricted_no_public_entry" if restricted else "verified_door_closed")
	set_meta("system_interaction_prompt", "باب خاص — الدخول ممنوع" if restricted else "افتح الباب")


func system_interact() -> void:
	if restricted:
		print("SYSTEM Baghdad: public access denied at restricted OSM entrance ", entrance_osm_id)
		return
	if not is_instance_valid(door_pivot):
		push_warning("SYSTEM Baghdad: door pivot is unavailable for entrance " + entrance_osm_id)
		return
	var player := _find_player()
	if player == null:
		push_warning("SYSTEM Baghdad: player was not found for door " + entrance_osm_id)
		return
	var inside_building := str(player.get_meta("system_inside_building_id", ""))
	if inside_building == building_osm_id:
		_exit_building(player)
		return
	if not door_open:
		_set_door_open(true)
		return
	_enter_building(player)


func _find_player() -> CharacterBody3D:
	for player_value in get_tree().get_nodes_in_group("system_player"):
		if player_value is CharacterBody3D and is_instance_valid(player_value):
			return player_value as CharacterBody3D
	var named_player := get_tree().root.find_child("Player", true, false)
	return named_player as CharacterBody3D


func _enter_building(player: CharacterBody3D) -> void:
	if not is_instance_valid(interior_root):
		push_warning("SYSTEM Baghdad: interior scene is unavailable for building " + building_osm_id)
		return
	interior_root.visible = true
	_set_interior_collision_enabled(true)
	if is_instance_valid(roof_node):
		roof_node.visible = false
	player.set_meta("system_inside_building_id", building_osm_id)
	player.set_meta("system_inside_building_entrance_id", entrance_osm_id)
	player.velocity = Vector3.ZERO
	player.global_position = global_position + inward_direction * 1.35 + Vector3.UP * 1.0
	set_meta("system_interaction_prompt", "اخرج من المبنى")
	print("SYSTEM Baghdad: entered OSM building ", building_osm_id, " through ", entrance_osm_id)


func _exit_building(player: CharacterBody3D) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = global_position - inward_direction * 1.45 + Vector3.UP * 1.0
	player.remove_meta("system_inside_building_id")
	player.remove_meta("system_inside_building_entrance_id")
	if is_instance_valid(interior_root):
		_set_interior_collision_enabled(false)
		interior_root.visible = false
	if is_instance_valid(roof_node):
		roof_node.visible = true
	_set_door_open(false)
	print("SYSTEM Baghdad: exited OSM building ", building_osm_id, " through ", entrance_osm_id)


func _set_interior_collision_enabled(enabled: bool) -> void:
	if not is_instance_valid(interior_root):
		return
	var pending: Array[Node] = [interior_root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is CollisionObject3D:
			(node as CollisionObject3D).collision_layer = 1 if enabled else 0
		for child in node.get_children():
			pending.append(child)


func _set_door_open(open_value: bool) -> void:
	door_open = open_value
	set_meta("system_door_open", door_open)
	set_meta("system_access_state", "verified_door_open" if door_open else "verified_door_closed")
	set_meta("system_interaction_prompt", "أغلق الباب" if door_open else "افتح الباب")
	if _door_tween != null and _door_tween.is_running():
		_door_tween.kill()
	_door_tween = create_tween()
	_door_tween.set_trans(Tween.TRANS_SINE)
	_door_tween.set_ease(Tween.EASE_IN_OUT)
	var target_angle := -1.35 if door_open else 0.0
	_door_tween.tween_property(door_pivot, "rotation:y", target_angle, 0.42)


func is_publicly_accessible() -> bool:
	return not restricted
