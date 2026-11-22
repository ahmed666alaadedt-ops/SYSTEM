extends SceneTree

const DOOR_INTERACTABLE = preload("res://scripts/underground_interactable.gd")
const HERITAGE_MANAGER = preload("res://scripts/underground_heritage_manager.gd")
const WORLD_INTERACTION_MANAGER = preload("res://scripts/world_interaction_manager.gd")
const CLOSED_POSITION := Vector3(0.0, 1.9, -7.0)
const OPEN_POSITION := Vector3(0.0, 6.1, -7.0)


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var target: Node3D = DOOR_INTERACTABLE.new()
	target.name = "VaultStoneDoorInteraction"
	target.add_to_group("system_interactable")
	target.set_meta("system_interaction_prompt", "افتح الباب الحجري")
	target.set("action_type", "stone_door")
	target.set("action_target_path", ^"DoorBody")

	var door := AnimatableBody3D.new()
	door.name = "DoorBody"
	door.position = CLOSED_POSITION
	door.sync_to_physics = true
	target.add_child(door)

	var visual := MeshInstance3D.new()
	visual.name = "DoorVisual"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(4.8, 3.8, 0.55)
	visual.mesh = mesh
	door.add_child(visual)

	var collision := CollisionShape3D.new()
	collision.name = "DoorCollision"
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	door.add_child(collision)

	root.add_child(target)

	# Exercise the actual shared camera-ray resolver against the door body.
	var ray_manager: Node = WORLD_INTERACTION_MANAGER.new()
	var ray_camera := Camera3D.new()
	root.add_child(ray_manager)
	root.add_child(ray_camera)
	ray_manager.set("camera", ray_camera)
	ray_manager.set("interaction_distance", 12.0)
	var player_clearance_cast := ShapeCast3D.new()
	var player_capsule := CapsuleShape3D.new()
	player_capsule.radius = 0.35
	player_capsule.height = 1.8
	player_clearance_cast.shape = player_capsule
	player_clearance_cast.target_position = Vector3(0.0, 0.0, -14.0)
	player_clearance_cast.position = Vector3(0.0, 1.0, 0.0)
	player_clearance_cast.collision_mask = 1
	player_clearance_cast.enabled = true
	root.add_child(player_clearance_cast)
	await physics_frame
	player_clearance_cast.force_shapecast_update()
	if player_clearance_cast.get_collision_count() == 0:
		_fail("Player-sized capsule sweep passed through the closed stone door; physical blocking is missing.")
		return
	var player_body := CharacterBody3D.new()
	player_body.position = Vector3(0.0, 1.0, 0.0)
	player_body.collision_mask = 1
	var player_body_shape := CollisionShape3D.new()
	var character_capsule := CapsuleShape3D.new()
	character_capsule.radius = 0.35
	character_capsule.height = 1.8
	player_body_shape.shape = character_capsule
	player_body.add_child(player_body_shape)
	root.add_child(player_body)
	player_clearance_cast.add_exception(player_body)
	await physics_frame
	var closed_body_motion := player_body.move_and_collide(Vector3(0.0, 0.0, -14.0))
	if closed_body_motion == null or player_body.global_position.z <= -7.0:
		_fail("CharacterBody3D crossed the closed vault slab instead of being physically blocked.")
		return

	ray_camera.global_position = Vector3(0.0, 1.9, 0.0)
	ray_camera.look_at(Vector3(0.0, 1.9, -7.0), Vector3.UP)
	await physics_frame
	if ray_manager.call("_find_target_in_front") != target:
		_fail("Front-side camera ray did not resolve the moving door body to its interactable parent.")
		return

	ray_camera.global_position = Vector3(0.0, 1.9, -14.0)
	ray_camera.look_at(Vector3(0.0, 1.9, -7.0), Vector3.UP)
	await physics_frame
	if ray_manager.call("_find_target_in_front") != target:
		_fail("Rear-side camera ray did not resolve the moving door body to its interactable parent.")
		return

	ray_camera.global_position = Vector3(0.0, 1.9, 0.0)
	ray_camera.look_at(Vector3(0.0, 1.9, -7.0), Vector3.UP)
	await physics_frame

	# Opening must animate the physical slab upward without disabling collision.
	target.call("system_interact")
	await create_timer(0.25).timeout
	if door.position.y <= CLOSED_POSITION.y + 0.05 or door.position.y >= OPEN_POSITION.y:
		_fail("Stone door did not move during its opening animation.")
		return
	if collision.disabled:
		_fail("Stone door collision was disabled while opening.")
		return
	if ray_manager.call("_find_target_in_front") != target:
		_fail("Door collision stopped blocking the camera ray during the opening animation.")
		return
	player_clearance_cast.force_shapecast_update()
	if player_clearance_cast.get_collision_count() == 0:
		_fail("Player-sized capsule passed through the slab before the opening animation completed.")
		return
	player_body.global_position = Vector3(0.0, 1.0, 0.0)
	await physics_frame
	var moving_body_motion := player_body.move_and_collide(Vector3(0.0, 0.0, -14.0))
	if moving_body_motion == null or player_body.global_position.z <= -7.0:
		_fail("CharacterBody3D crossed the slab before the opening animation completed.")
		return
	await create_timer(1.1).timeout
	if door.position.distance_to(OPEN_POSITION) > 0.03:
		_fail("Stone door did not reach its fully open position.")
		return
	if not bool(target.get_meta("system_door_open", false)):
		_fail("Open state metadata was not set.")
		return
	if str(target.get_meta("system_interaction_prompt", "")) != "أغلق الباب الحجري":
		_fail("Open-state interaction prompt is incorrect.")
		return
	if ray_manager.call("_find_target_in_front") != null:
		_fail("Fully open vault doorway is still blocked by the raised slab at player height.")
		return
	player_clearance_cast.force_shapecast_update()
	if player_clearance_cast.get_collision_count() != 0:
		_fail("Player-sized capsule cannot pass through the fully opened vault doorway.")
		return
	player_body.global_position = Vector3(0.0, 1.0, 0.0)
	await physics_frame
	var open_body_motion := player_body.move_and_collide(Vector3(0.0, 0.0, -14.0))
	if open_body_motion != null or player_body.global_position.z > -13.9:
		_fail("CharacterBody3D could not traverse the fully opened vault doorway.")
		return

	# Closing must return the same slab and retain its physical collision.
	target.call("system_interact")
	await create_timer(1.4).timeout
	if door.position.distance_to(CLOSED_POSITION) > 0.03:
		_fail("Stone door did not return to its closed position.")
		return
	if collision.disabled:
		_fail("Stone door collision was disabled after closing.")
		return
	player_clearance_cast.force_shapecast_update()
	if player_clearance_cast.get_collision_count() == 0:
		_fail("Player-sized capsule passed through the door after it closed.")
		return
	player_body.global_position = Vector3(0.0, 1.0, 0.0)
	await physics_frame
	var reclosed_body_motion := player_body.move_and_collide(Vector3(0.0, 0.0, -14.0))
	if reclosed_body_motion == null or player_body.global_position.z <= -7.0:
		_fail("CharacterBody3D crossed the vault slab after it closed again.")
		return
	if bool(target.get_meta("system_door_open", true)):
		_fail("Closed state metadata was not updated.")
		return

	# A second interaction during motion must reverse the active tween safely.
	target.call("system_interact")
	await create_timer(0.2).timeout
	target.call("system_interact")
	await create_timer(1.4).timeout
	if door.position.distance_to(CLOSED_POSITION) > 0.03:
		_fail("Door failed to reverse safely during an active animation.")
		return


	# The manager must save the desired state and restore it after its site nodes are rebuilt.
	var world_root := Node3D.new()
	root.add_child(world_root)
	var manager: Node3D = HERITAGE_MANAGER.new()
	world_root.add_child(manager)
	await process_frame
	var managed_door := manager.get_node("BaghdadOldSouk/UndergroundChambers/VaultStoneDoorInteraction")
	managed_door.call("restore_stone_door_state", false)
	managed_door.call("system_interact")
	await create_timer(1.4).timeout
	if not bool(managed_door.get_meta("system_door_open", false)):
		_fail("Managed Baghdad vault door did not open.")
		return
	var independent_door := manager.get_node("BaghdadRiverCatacombs/UndergroundChambers/VaultStoneDoorInteraction")
	if bool(independent_door.get_meta("system_door_open", false)):
		_fail("Opening the Old Souk vault incorrectly changed the River Catacombs door state.")
		return
	manager.queue_free()
	await process_frame
	var restored_manager: Node3D = HERITAGE_MANAGER.new()
	world_root.add_child(restored_manager)
	await physics_frame
	var restored_door := restored_manager.get_node("BaghdadOldSouk/UndergroundChambers/VaultStoneDoorInteraction")
	var restored_body := restored_door.get_node("DoorBody") as Node3D
	if not bool(restored_door.get_meta("system_door_open", false)):
		_fail("Vault door state was not restored after manager recreation.")
		return
	if restored_body.position.distance_to(OPEN_POSITION) > 0.03:
		_fail("Restored vault door body position mismatch. actual=" + str(restored_body.position) + " expected=" + str(OPEN_POSITION) + " target=" + str(restored_door.position) + " saved_states=" + str(restored_manager.get("_door_states")))
		return
	var restored_independent_door := restored_manager.get_node("BaghdadRiverCatacombs/UndergroundChambers/VaultStoneDoorInteraction")
	var independent_body := restored_independent_door.get_node("DoorBody") as Node3D
	if bool(restored_independent_door.get_meta("system_door_open", true)):
		_fail("River Catacombs door state was not isolated from Old Souk persistence.")
		return
	if independent_body.position.distance_to(CLOSED_POSITION) > 0.03:
		_fail("River Catacombs door did not remain closed after Old Souk state restoration.")
		return

	# Closing the restored door must persist just as reliably as opening it.
	restored_door.call("system_interact")
	await create_timer(1.4).timeout
	restored_manager.queue_free()
	await process_frame
	var closed_manager: Node3D = HERITAGE_MANAGER.new()
	world_root.add_child(closed_manager)
	await physics_frame
	var closed_door := closed_manager.get_node("BaghdadOldSouk/UndergroundChambers/VaultStoneDoorInteraction")
	var closed_body := closed_door.get_node("DoorBody") as Node3D
	if bool(closed_door.get_meta("system_door_open", true)):
		_fail("Closed vault state was not restored after a second manager recreation.")
		return
	if closed_body.position.distance_to(CLOSED_POSITION) > 0.03:
		_fail("Closed vault slab did not return to its saved closed position after manager recreation.")
		return
	world_root.queue_free()
	await process_frame

	print("SYSTEM Baghdad vault door lifecycle passed: animation, collision, prompts, reversal, and saved-state restoration.")
	target.queue_free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("SYSTEM Baghdad vault door validation failed: " + message)
	quit(1)
