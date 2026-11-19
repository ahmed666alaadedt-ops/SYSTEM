extends SceneTree


func _count_meshes(start: Node) -> int:
	var pending: Array[Node] = [start]
	var count := 0
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			count += 1
		for child in node.get_children():
			pending.append(child)
	return count

func _initialize() -> void:
	call_deferred("_run_diagnostic")

func _run_diagnostic() -> void:
	var packed: PackedScene = load("res://MainScene.tscn")
	if packed == null:
		push_error("Mesh diagnostic: MainScene.tscn could not be loaded.")
		quit(2)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for frame_index in range(12):
		await process_frame
	var pending: Array[Node] = [scene]
	var null_mesh_paths: Array[String] = []
	var null_multimesh_paths: Array[String] = []
	var mesh_count := 0
	var multimesh_count := 0
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			mesh_count += 1
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh == null:
				null_mesh_paths.append(str(mesh_instance.get_path()))
		if node is MultiMeshInstance3D:
			multimesh_count += 1
			var multimesh_instance := node as MultiMeshInstance3D
			if multimesh_instance.multimesh == null or multimesh_instance.multimesh.mesh == null:
				null_multimesh_paths.append(str(multimesh_instance.get_path()))
		for child in node.get_children():
			pending.append(child)
	print("SYSTEM MESH DIAGNOSTIC: mesh_instances=", mesh_count,
		" null_mesh_instances=", null_mesh_paths.size(),
		" multimesh_instances=", multimesh_count,
		" invalid_multimeshes=", null_multimesh_paths.size())
	var manager := scene.find_child("WorldManager", true, false)
	if manager != null:
		var roots: Dictionary = manager.get("world_roots")
		for world_id in roots.keys():
			var world_root := roots[world_id] as Node
			var world_pending: Array[Node] = [world_root]
			var world_mesh_count := 0
			while not world_pending.is_empty():
				var world_node: Node = world_pending.pop_back()
				if world_node is MeshInstance3D:
					world_mesh_count += 1
				for child in world_node.get_children():
					world_pending.append(child)
			print("SYSTEM WORLD MESH COUNT: world=", world_id, " meshes=", world_mesh_count)
			for top_child in world_root.get_children():
				var child_mesh_count := _count_meshes(top_child)
				if child_mesh_count > 0:
					print("SYSTEM WORLD MESH GROUP: world=", world_id,
						" group=", top_child.name, " meshes=", child_mesh_count)
				if top_child.name == "ModernWorldTransportNetworkManager":
					for transport_child in top_child.get_children():
						var transport_mesh_count := _count_meshes(transport_child)
						if transport_mesh_count > 0:
							print("SYSTEM TRANSPORT MESH GROUP: group=", transport_child.name,
								" meshes=", transport_mesh_count)
				if top_child.name == "ModernWorldRegionManager":
					for region_child in top_child.get_children():
						var region_mesh_count := _count_meshes(region_child)
						if region_mesh_count > 0:
							print("SYSTEM REGION MESH GROUP: group=", region_child.name,
								" meshes=", region_mesh_count)
	for path in null_mesh_paths.slice(0, 100):
		print("SYSTEM NULL MESH: ", path)
	for path in null_multimesh_paths.slice(0, 100):
		print("SYSTEM INVALID MULTIMESH: ", path)
	# Exercise first-entry loading for all four worlds, then return to the modern world.
	if manager != null:
		for world_id in [0, 1, 3, 2]:
			manager.call("switch_world", world_id)
			for frame_index in range(3):
				await process_frame
			var initialized: Dictionary = manager.get("world_initialized")
			if not bool(initialized.get(world_id, false)):
				push_error("World lazy-load test failed for world ID " + str(world_id))
				quit(3)
				return
			print("SYSTEM WORLD LOAD TEST: world=", world_id, " initialized=true")
	quit(1 if not null_mesh_paths.is_empty() or not null_multimesh_paths.is_empty() else 0)
