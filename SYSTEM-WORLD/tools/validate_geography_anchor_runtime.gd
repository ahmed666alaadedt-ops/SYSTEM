extends SceneTree

## Runtime smoke test: verifies that the Baghdad city anchor is sourced from
## the provisional WGS84 registry and reaches the canonical city region layer.

func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var geography := root.get_node_or_null("SystemRealWorldGeography")
	if geography == null:
		_fail("SystemRealWorldGeography autoload is unavailable")
		return

	var record: Dictionary = geography.call("get_city", "city_baghdad")
	if record.is_empty():
		_fail("Baghdad registry record is missing")
		return
	if str(record.get("city_status", "")) != "geographic_anchor_only":
		_fail("Baghdad record must remain explicitly classified as an anchor only")
		return

	var projected: Vector3 = geography.call("get_city_world_position", "city_baghdad")
	if Vector2(projected.x, projected.z).length() > 1.0 or absf(projected.y - 34.0) > 0.5:
		_fail("Baghdad registry coordinate/elevation projection is incorrect; got " + str(projected))
		return

	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("Canonical MainScene could not be loaded")
		return
	var scene := packed.instantiate()
	if scene == null:
		_fail("Canonical MainScene could not be instantiated")
		return
	root.add_child(scene)

	for _frame in range(6):
		await process_frame

	var world_manager := scene.get_node_or_null("WorldManager")
	if world_manager == null:
		_fail("WorldManager was not created")
		return
	var active_world := world_manager.call("get_active_world") as Node3D
	if active_world == null:
		_fail("Modern world did not become active")
		return
	var region_manager := active_world.get_node_or_null("ModernWorldRegionManager")
	if region_manager == null:
		_fail("ModernWorldRegionManager was not created")
		return

	var anchors: Dictionary = region_manager.get("city_anchors")
	if not anchors.has("Baghdad"):
		_fail("Baghdad city anchor was not registered")
		return
	var actual: Vector2 = anchors["Baghdad"]
	var expected := Vector2(projected.x, projected.z)
	if actual.distance_to(expected) > 100.0:
		_fail("Baghdad city anchor is not derived from the WGS84 registry origin")
		return

	print("SYSTEM GEOGRAPHY QA PASS: Baghdad city anchor is connected to WGS84 registry.")
	print("SYSTEM GEOGRAPHY QA LIMIT: only the Baghdad anchor is real-data-backed; other city layouts remain prototypes.")
	quit(0)


func _fail(reason: String) -> void:
	push_error("SYSTEM GEOGRAPHY QA FAILED: " + reason)
	quit(1)
