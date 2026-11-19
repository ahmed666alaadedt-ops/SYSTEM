extends SceneTree

## Verifies that every canonical humanoid GLB imports as a usable rigged scene.
## Run after Godot's editor import pass:
## godot --headless --path SYSTEM-WORLD --script res://tools/validate_humanoid_assets.gd

const MODEL_PATHS := [
	"res://assets/characters/SYSTEM_Humanoid_Male.glb",
	"res://assets/characters/SYSTEM_Humanoid_Female.glb",
	"res://assets/characters/SYSTEM_Humanoid_Elder_Male.glb",
	"res://assets/characters/SYSTEM_Humanoid_Elder_Female.glb",
	"res://assets/characters/SYSTEM_Humanoid_Child_Male.glb",
	"res://assets/characters/SYSTEM_Humanoid_Child_Female.glb"
]

const REQUIRED_ANIMATIONS := [
	"Idle_Breathing",
	"Walk_Cycle",
	"Run_Cycle",
	"Jump_Animation",
	"Attack_Animation",
	"Facial_Blink",
	"Facial_Talking"
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	for model_path in MODEL_PATHS:
		_validate_model(model_path)

	if failures.is_empty():
		print("HUMANOID ASSET QA PASS: all six canonical GLB models imported with rigs and required animations.")
		quit(0)
		return

	for failure in failures:
		push_error("HUMANOID ASSET QA: " + failure)
	push_error("HUMANOID ASSET QA FAILED: %d issue(s)." % failures.size())
	quit(1)


func _validate_model(model_path: String) -> void:
	if not ResourceLoader.exists(model_path):
		failures.append("Missing canonical model: " + model_path)
		return

	var packed_scene := load(model_path) as PackedScene
	if packed_scene == null:
		failures.append("GLB did not import as a PackedScene: " + model_path)
		return

	var instance := packed_scene.instantiate()
	if not instance is Node3D:
		failures.append("GLB root is not Node3D: " + model_path)
		instance.free()
		return

	var animation_player := _find_animation_player(instance)
	if animation_player == null:
		failures.append("No AnimationPlayer was imported: " + model_path)
		instance.free()
		return

	var animation_names := animation_player.get_animation_list()
	for required_name in REQUIRED_ANIMATIONS:
		if not _contains_animation(animation_names, required_name):
			failures.append(
				"Missing animation '%s' in %s (found: %s)" % [
					required_name,
					model_path,
					", ".join(animation_names)
				]
			)

	var skeleton_count := _count_skeletons(instance)
	var skinned_mesh_count := _count_skinned_meshes(instance)
	if skeleton_count < 1:
		failures.append("No Skeleton3D imported: " + model_path)
	if skinned_mesh_count < 1:
		failures.append("No weighted MeshInstance3D imported: " + model_path)

	print(
		"HUMANOID MODEL OK: %s | skeletons=%d | skinned_meshes=%d | animations=%s" % [
			model_path,
			skeleton_count,
			skinned_mesh_count,
			", ".join(animation_names)
		]
	)
	instance.free()


func _contains_animation(animation_names: PackedStringArray, expected_name: String) -> bool:
	var expected_lower := expected_name.to_lower()
	for animation_name in animation_names:
		if str(animation_name).to_lower().contains(expected_lower):
			return true
	return false


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _count_skeletons(node: Node) -> int:
	var count := 1 if node is Skeleton3D else 0
	for child in node.get_children():
		count += _count_skeletons(child)
	return count


func _count_skinned_meshes(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.skin != null and not mesh_instance.skeleton.is_empty():
			count += 1
	for child in node.get_children():
		count += _count_skinned_meshes(child)
	return count
