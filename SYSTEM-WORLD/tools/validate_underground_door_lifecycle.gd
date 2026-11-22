extends SceneTree

const DOOR_INTERACTABLE = preload("res://scripts/underground_interactable.gd")
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
	target.system_interact()
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
	target.system_interact()
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
	target.system_interact()
	await create_timer(0.2).timeout
	target.system_interact()
	await create_timer(1.4).timeout
	if door.position.distance_to(CLOSED_POSITION) > 0.03:
		_fail("Door failed to reverse safely during an active animation.")
		return

	print("SYSTEM Baghdad vault door lifecycle passed: animated open, close, collision retention, prompts, and mid-motion reversal.")
	target.queue_free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("SYSTEM Baghdad vault door validation failed: " + message)
	quit(1)
