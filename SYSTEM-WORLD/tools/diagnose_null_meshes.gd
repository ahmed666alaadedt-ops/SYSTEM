extends SceneTree

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
	for path in null_mesh_paths.slice(0, 100):
		print("SYSTEM NULL MESH: ", path)
	for path in null_multimesh_paths.slice(0, 100):
		print("SYSTEM INVALID MULTIMESH: ", path)
	quit(1 if not null_mesh_paths.is_empty() or not null_multimesh_paths.is_empty() else 0)
