extends SceneTree

const BaghdadTowerManagerScript = preload("res://scripts/baghdad_tower_landmarks_manager.gd")
const WorldInteractionManagerScript = preload("res://scripts/world_interaction_manager.gd")

class FakeTerrain extends Node:
	func is_land_position(_x: float, _z: float) -> bool:
		return true

	func get_terrain_height(_x: float, _z: float) -> float:
		return 0.0

class FakeWorldManager extends Node:
	var active_world := "modern"

class FakeRegion extends Node3D:
	var terrain: Node

	func get_city_anchor(city_name: String) -> Vector3:
		return Vector3.ZERO if city_name == "Baghdad" else Vector3.INF


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var region := FakeRegion.new()
	region.name = "ModernWorldRegionManager"
	region.terrain = FakeTerrain.new()
	root.add_child(region)

	var manager := BaghdadTowerManagerScript.new()
	region.add_child(manager)

	var towers: Array[Dictionary] = manager.call("get_tower_positions")
	if towers.size() != 5:
		_fail("Expected five Baghdad landmark towers; found %d." % towers.size())
		return

	var expected_names := [
		"HunterAssociationTower",
		"PowerTower",
		"BusinessTower",
		"ShoppingTower",
		"EntertainmentTower"
	]
	for tower_name in expected_names:
		var tower := manager.get_node_or_null(NodePath(tower_name))
		if tower == null:
			_fail("Missing tower node: " + tower_name)
			return
		var district := tower.get_node_or_null(NodePath("RooftopMicroCity_" + tower_name))
		if district == null:
			_fail("Missing supported rooftop micro-city on " + tower_name)
			return
		if not bool(district.get_meta("supported_by_tower", false)):
			_fail("Rooftop district is not marked as tower-supported: " + tower_name)
			return
		for quarter_name in ["ResidentialQuarter", "MarketAndServicesQuarter", "GardenAndLeisureQuarter", "CivicAndCultureQuarter"]:
			if district.get_node_or_null(NodePath(quarter_name)) == null:
				_fail("Missing rooftop quarter %s on %s." % [quarter_name, tower_name])
				return

	var network := manager.get_node_or_null("BaghdadUnifiedRooftopCityNetwork")
	if network == null:
		_fail("Unified rooftop city network was not created.")
		return
	if int(network.get_meta("connected_tower_count", 0)) != 5:
		_fail("Unified rooftop network does not report five connected towers.")
		return
	var bridge_count := 0
	var lift_core_count := 0
	for child in network.get_children():
		# Count visible deck nodes only; each bridge also owns a collision body.
		if child is MeshInstance3D and child.name.begins_with("UpperCityBridge_"):
			bridge_count += 1
		if child is MeshInstance3D and child.name.begins_with("RooftopCityVerticalLiftCore_"):
			lift_core_count += 1
	if bridge_count != 5:
		_fail("Expected five upper-city bridges; found %d." % bridge_count)
		return
	if lift_core_count != 5:
		_fail("Expected five vertical access cores; found %d." % lift_core_count)
		return

	var cabin_count := 0
	var call_panel_count := 0
	for child in network.get_children():
		if child is Node3D and child.name.begins_with("RooftopCityLiftCabin_"):
			cabin_count += 1
		if child is Area3D and child.name.begins_with("RooftopElevatorCall_"):
			call_panel_count += 1
			if not child.is_in_group("system_interactable"):
				_fail("Rooftop elevator call panel is not registered as interactable.")
				return
	if cabin_count != 5:
		_fail("Expected five elevator cabins; found %d." % cabin_count)
		return
	if call_panel_count != 10:
		_fail("Expected ten elevator call panels; found %d." % call_panel_count)
		return

	var test_panel: Area3D
	for child in network.get_children():
		if child is Area3D and child.name == "RooftopElevatorCall_00_Lower":
			test_panel = child
			break
	if test_panel == null:
		_fail("Could not locate the first lower elevator call panel for ride testing.")
		return
	var test_cabin := network.get_node_or_null("RooftopCityLiftCabin_00") as Node3D
	if test_cabin == null or test_cabin.get_node_or_null("CabinWalkableFloor") == null:
		_fail("Elevator cabin is missing its walkable passenger floor.")
		return
	var floor_collision := _find_shape_collision(test_cabin)
	if floor_collision == null or floor_collision.shape == null:
		_fail("Elevator passenger floor is missing collision geometry under cabin; children: %s" % _describe_children(test_cabin))
		return
	var cabin_body := test_cabin.get_node_or_null("CabinFloorCollisionBody")
	if not cabin_body is AnimatableBody3D:
		_fail("Elevator floor must use an AnimatableBody3D so its moving collision stays synchronized.")
		return
	if not (cabin_body as AnimatableBody3D).sync_to_physics:
		_fail("Elevator AnimatableBody3D is not synchronized with physics.")
		return

	var test_player := CharacterBody3D.new()
	test_player.name = "ElevatorRuntimeValidationPlayer"
	test_player.set_physics_process(true)
	root.add_child(test_player)
	test_player.global_position = test_panel.global_position
	test_panel.call("configure_player", test_player)
	var fake_world_manager := FakeWorldManager.new()
	root.add_child(fake_world_manager)
	var interaction_dispatcher := WorldInteractionManagerScript.new()
	root.add_child(interaction_dispatcher)
	interaction_dispatcher.world_manager = fake_world_manager
	interaction_dispatcher.current_target = test_panel
	if not interaction_dispatcher.interact_with_target():
		_fail("The standard world interaction dispatcher rejected the elevator call panel.")
		return
	var expected_cabin_destination: Vector3 = test_panel.get("destination_cabin_position")
	var expected_player_destination: Vector3 = test_panel.get("destination_player_position")
	if not bool(test_cabin.get_meta("system_elevator_busy", false)):
		_fail("Elevator ride did not enter its busy/moving state.")
		return
	if test_player.is_physics_processing():
		_fail("Player physics was not paused while boarding the elevator.")
		return
	if test_player.get_parent() != test_cabin:
		_fail("Player was not parented to the elevator cabin for a physically coherent ride.")
		return

	await create_timer(1.0).timeout
	var boarding_offset := test_player.position
	if boarding_offset.distance_to(Vector3(0.0, -0.9, 0.0)) > 0.18:
		_fail("Player did not board and remain centered on the moving cabin platform.")
		return
	await create_timer(1.5).timeout
	var ride_offset := test_player.position
	if test_player.get_parent() != test_cabin:
		_fail("Player detached from the elevator cabin during travel.")
		return
	if ride_offset.distance_to(Vector3(0.0, -0.9, 0.0)) > 0.18:
		_fail("Player drifted away from the cabin during the elevator ride.")
		return
	await create_timer(2.5).timeout
	if test_cabin.global_position.distance_to(expected_cabin_destination) > 0.15:
		_fail("Elevator cabin did not reach its configured destination.")
		return
	if test_player.global_position.distance_to(expected_player_destination) > 0.15:
		_fail("Player did not travel with the elevator cabin.")
		return
	if test_player.get_parent() != root:
		_fail("Player was not returned to the original world parent after the ride.")
		return
	if test_player.is_physics_processing() != true:
		_fail("Player physics processing was not restored after the ride.")
		return
	if bool(test_cabin.get_meta("system_elevator_busy", true)):
		_fail("Elevator did not release its busy state after arriving.")
		return
	test_player.queue_free()

	print("Baghdad rooftop city runtime passed: 5 towers, 20 rooftop quarters, 5 upper bridges, 5 lift cores, 5 walkable cabins, 10 interactive call panels and a complete player ride.")
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad rooftop city runtime failed: " + message)
	quit(1)


func _find_shape_collision(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D and node.shape != null:
		return node
	for child in node.get_children():
		var found := _find_shape_collision(child)
		if found != null:
			return found
	return null


func _describe_children(node: Node) -> String:
	var names: PackedStringArray = []
	for child in node.get_children():
		names.append("%s:%s" % [child.name, child.get_class()])
	return ", ".join(names)
