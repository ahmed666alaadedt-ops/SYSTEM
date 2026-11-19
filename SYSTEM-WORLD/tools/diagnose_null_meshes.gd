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
	var mesh_count := 0
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			mesh_count += 1
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh == null:
				null_mesh_paths.append(str(mesh_instance.get_path()))
		for child in node.get_children():
			pending.append(child)
	print("SYSTEM MESH DIAGNOSTIC: mesh_instances=", mesh_count,
		" null_mesh_instances=", null_mesh_paths.size())
	for path in null_mesh_paths.slice(0, 100):
		print("SYSTEM NULL MESH: ", path)
	quit(1 if not null_mesh_paths.is_empty() else 0)
