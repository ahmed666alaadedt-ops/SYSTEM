extends SceneTree

var _validation_finished := false


func _initialize() -> void:
	call_deferred("_run_validation")
	call_deferred("_watchdog")


func _watchdog() -> void:
	print("SYSTEM QA integration: watchdog armed.")
	await create_timer(12.0).timeout
	if not _validation_finished:
		_fail("Live main-scene integration validation timed out before reaching its completion checkpoint.")


func _run_validation() -> void:
	print("SYSTEM QA integration: validation started.")
	var packed_scene := load("res://MainScene.tscn") as PackedScene
	if packed_scene == null:
		_fail("Canonical MainScene.tscn could not be loaded.")
		return

	var main_scene := packed_scene.instantiate()
	root.add_child(main_scene)
	print("SYSTEM QA integration: canonical main scene instantiated.")
	await process_frame
	print("SYSTEM QA integration: main scene ready frame reached.")

	var world_manager := main_scene.get_node_or_null("WorldManager")
	if world_manager == null:
		_fail("Canonical main scene did not create WorldManager.")
		return
	if int(world_manager.get("active_world")) != 2:
		_fail("Canonical main scene did not start in the Modern Realistic World.")
		return

	print("SYSTEM QA integration: WorldManager and active world verified.")
	var modern_root := world_manager.call("get_world_root", 2) as Node3D
	if modern_root == null:
		_fail("Modern world root is missing from WorldManager.")
		return

	var heritage_manager := modern_root.get_node_or_null("UndergroundHeritageManager")
	if heritage_manager == null:
		_fail("UndergroundHeritageManager is not attached to the active modern world.")
		return

	print("SYSTEM QA integration: live heritage manager verified.")
	var door_interactable := modern_root.get_node_or_null(
		"UndergroundHeritageManager/BaghdadOldSouk/UndergroundChambers/VaultStoneDoorInteraction"
	)
	if door_interactable == null:
		_fail("Baghdad Old Souk vault door is missing from the live modern world.")
		return
	if not door_interactable.is_in_group("system_interactable"):
		_fail("Live Baghdad vault door is not registered in system_interactable.")
		return

	var door_body := door_interactable.get_node_or_null("DoorBody")
	if not door_body is AnimatableBody3D:
		_fail("Live vault slab is not an AnimatableBody3D.")
		return
	var collision := door_body.get_node_or_null("DoorCollision") as CollisionShape3D
	if collision == null or collision.shape == null or collision.disabled:
		_fail("Live vault slab collision is missing or disabled.")
		return

	print("SYSTEM QA integration: live vault door and collision verified.")
	var interaction_manager := main_scene.get_node_or_null("WorldInteractionManager")
	if interaction_manager == null:
		_fail("Canonical WorldInteractionManager is missing.")
		return
	if interaction_manager.get("player") == null or interaction_manager.get("camera") == null:
		_fail("Canonical interaction manager is not connected to the live player and camera.")
		return
	var resolved := interaction_manager.call("_resolve_interactable", door_body)
	if resolved != door_interactable:
		_fail("Canonical interaction manager cannot resolve the live vault slab to its interactable parent.")
		return

	print("SYSTEM Baghdad live-scene integration passed: modern world, heritage manager, vault door, collision, player/camera interaction wiring.")
	_validation_finished = true
	main_scene.queue_free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	_validation_finished = true
	push_error("SYSTEM Baghdad live-scene integration failed: " + message)
	quit(1)
