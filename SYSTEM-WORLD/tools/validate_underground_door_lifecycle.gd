extends SceneTree

const DOOR_INTERACTABLE = preload("res://scripts/underground_interactable.gd")
const HERITAGE_MANAGER = preload("res://scripts/underground_heritage_manager.gd")
const CLOSED_POSITION := Vector3(0.0, 1.9, -7.0)
const OPEN_POSITION := Vector3(0.0, 6.1, -7.0)


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var target: Node3D = DOOR_INTERACTABLE.new()
	target.name = "VaultStoneDoorInteraction"
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
	await process_frame

	# Opening must animate the physical slab upward without disabling collision.
	target.call("system_interact")
	await create_timer(0.25).timeout
	if door.position.y <= CLOSED_POSITION.y + 0.05 or door.position.y >= OPEN_POSITION.y:
		_fail("Stone door did not move during its opening animation.")
		return
	if collision.disabled:
		_fail("Stone door collision was disabled while opening.")
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

	# Closing must return the same slab and retain its physical collision.
	target.call("system_interact")
	await create_timer(1.4).timeout
	if door.position.distance_to(CLOSED_POSITION) > 0.03:
		_fail("Stone door did not return to its closed position.")
		return
	if collision.disabled:
		_fail("Stone door collision was disabled after closing.")
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
	managed_door.call("system_interact")
	await create_timer(1.4).timeout
	if not bool(managed_door.get_meta("system_door_open", false)):
		_fail("Managed Baghdad vault door did not open.")
		return
	manager.queue_free()
	await process_frame
	var restored_manager: Node3D = HERITAGE_MANAGER.new()
	world_root.add_child(restored_manager)
	await process_frame
	var restored_door := restored_manager.get_node("BaghdadOldSouk/UndergroundChambers/VaultStoneDoorInteraction")
	var restored_body := restored_door.get_node("DoorBody") as Node3D
	if not bool(restored_door.get_meta("system_door_open", false)):
		_fail("Vault door state was not restored after manager recreation.")
		return
	if restored_body.position.distance_to(OPEN_POSITION) > 0.03:
		_fail("Restored vault door body did not return to the saved open position.")
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
