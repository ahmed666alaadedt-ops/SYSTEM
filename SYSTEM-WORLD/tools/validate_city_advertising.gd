extends SceneTree

const ADVERTISING_MANAGER = preload("res://scripts/system_city_advertising_manager.gd")
const MAP_MANAGER = preload("res://scripts/world_map_manager.gd")
const PUBLIC_BOARD = preload("res://scripts/system_public_event_board.gd")

var _owned_test_nodes: Array[Node] = []


func _initialize() -> void:
	call_deferred("_run_validation")


func _fail(message: String) -> void:
	push_error("City advertising validation failed: " + message)
	await _release_test_scene()
	quit(1)


func _release_test_scene() -> void:
	# These managers create many temporary 3D billboard meshes. Explicitly
	# release them and let deferred deletion complete before SceneTree exits.
	for index in range(_owned_test_nodes.size() - 1, -1, -1):
		var node := _owned_test_nodes[index]
		if is_instance_valid(node):
			node.queue_free()
	_owned_test_nodes.clear()
	await process_frame
	await process_frame


func _run_validation() -> void:
	var map_manager = MAP_MANAGER.new()
	root.add_child(map_manager)
	_owned_test_nodes.append(map_manager)

	var public_board = PUBLIC_BOARD.new()
	root.add_child(public_board)
	_owned_test_nodes.append(public_board)
	var anchors := {
		"Baghdad": Vector2.ZERO,
		"Tokyo": Vector2(120.0, 80.0)
	}
	public_board.setup(anchors, null)

	var advertising_manager = ADVERTISING_MANAGER.new()
	root.add_child(advertising_manager)
	_owned_test_nodes.append(advertising_manager)
	advertising_manager.setup(anchors, null)
	advertising_manager.connect_map_manager(map_manager, "2")
	public_board.connect_advertising_manager(advertising_manager)

	var locations: Array[Dictionary] = advertising_manager.get_advertisement_locations()
	if locations.size() != 6:
		_fail("Expected three street billboards for each of two test cities; got %d." % locations.size())
		return

	var snapshot: Dictionary = map_manager.get_map_snapshot("2")
	var map_ads: Array = snapshot.get("advertisements", [])
	if map_ads.size() != locations.size():
		_fail("World map advertisement registry does not match physical billboard count.")
		return

	for location in locations:
		var board_id := str(location.get("id", ""))
		var campaign: Dictionary = advertising_manager.get_campaign_details(board_id)
		if campaign.is_empty() or str(campaign.get("title", "")).is_empty():
			_fail("A physical billboard has no active campaign: " + board_id)
			return
		if int(campaign.get("expires_at", 0)) <= int(Time.get_unix_time_from_system()):
			_fail("Campaign expiry is not in the future: " + board_id)
			return
		var record: Dictionary = advertising_manager.displays_by_id.get(board_id, {})
		var board_root := record.get("root") as Node3D
		if board_root == null:
			_fail("Billboard scene root is missing: " + board_id)
			return
		var interaction := board_root.get_node_or_null("AdvertisingInteraction") as Area3D
		if interaction == null or not interaction.is_in_group("system_interactable"):
			_fail("Billboard interaction area is missing: " + board_id)
			return
		if str(interaction.get_meta("system_location_id", "")) != board_id:
			_fail("Billboard interaction ID does not match map ID: " + board_id)
			return

	if public_board.ad_labels.size() != anchors.size():
		_fail("City facade advertising displays were not connected to the shared campaign network.")
		return
	for label in public_board.ad_labels:
		if not is_instance_valid(label) or str(label.text).is_empty():
			_fail("A city facade advertising screen has no campaign text.")
			return

	print("City advertising validation passed: street_boards=", locations.size(), " map_markers=", map_ads.size(), " facade_screens=", public_board.ad_labels.size())
	await _release_test_scene()
	print("City advertising test scene cleanup flushed before SceneTree shutdown.")
	quit(0)
