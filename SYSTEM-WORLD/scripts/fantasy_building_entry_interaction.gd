extends Area3D

# SYSTEM WORLD - Building Entry / Exit Interaction

var building: Node3D
var half_z: float = 0.0
var is_exit: bool = false


func configure(
	p_building: Node3D,
	p_half_z: float,
	p_is_exit: bool
) -> void:
	building = p_building
	half_z = p_half_z
	is_exit = p_is_exit


func system_interact() -> void:
	if not is_instance_valid(building):
		push_warning("SYSTEM: Building reference is unavailable.")
		return

	var player := get_tree().root.find_child(
		"Player",
		true,
		false
	) as CharacterBody3D

	if player == null:
		push_warning("SYSTEM: Player was not found.")
		return

	if is_exit:
		_exit_building(player)
	else:
		_enter_building(player)


func _enter_building(player: CharacterBody3D) -> void:
	if building.get_meta("system_interior_active", false):
		return

	var roof := building.get_node_or_null(
		"BuildingRoof"
	) as MeshInstance3D

	if roof != null:
		if not building.has_meta("system_roof_original_visible"):
			building.set_meta(
				"system_roof_original_visible",
				roof.visible
			)

		roof.visible = false

	building.set_meta("system_interior_active", true)

	var destination := building.to_global(
		Vector3(0.0, 1.2, 0.0)
	)

	_move_player(player, destination)

	print(
		"SYSTEM: Entered building: ",
		building.name
	)


func _exit_building(player: CharacterBody3D) -> void:
	if not building.get_meta("system_interior_active", false):
		return

	var roof := building.get_node_or_null(
		"BuildingRoof"
	) as MeshInstance3D

	if roof != null:
		if building.has_meta("system_roof_original_visible"):
			roof.visible = bool(
				building.get_meta(
					"system_roof_original_visible"
				)
			)

			building.remove_meta(
				"system_roof_original_visible"
			)

	building.set_meta("system_interior_active", false)

	var destination := building.to_global(
		Vector3(0.0, 1.2, half_z + 3.0)
	)

	_move_player(player, destination)

	print(
		"SYSTEM: Exited building: ",
		building.name
	)


func _move_player(
	player: CharacterBody3D,
	destination: Vector3
) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = destination
