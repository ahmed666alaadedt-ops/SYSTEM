extends Node3D
class_name SystemNPCCharacterModel

## Loads generated rigged GLB characters when available.
## Keeps the procedural Godot model as a safe fallback.

const FALLBACK_VISUAL = preload("res://scripts/npc_humanoid_visual.gd")
const MALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Male.glb"
const FEMALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Female.glb"

var imported_model: Node3D
var fallback_model: Node3D
var animation_player: AnimationPlayer
var current_activity := "idle"
var selected_model_path := ""

func configure(profile: Dictionary, palette_index: int = 0) -> void:
	name = "NPCCharacter_" + str(profile.get("name", "Resident")).replace(" ", "_")
	var gender_text := str(profile.get("gender", profile.get("appearance", ""))).to_lower()
	var is_female := gender_text in ["female", "woman", "girl", "أنثى", "بنت", "امرأة"]
	if gender_text.is_empty():
		is_female = (palette_index % 2) == 1
	selected_model_path = FEMALE_MODEL_PATH if is_female else MALE_MODEL_PATH
	if _load_imported_model(selected_model_path):
		return
	_build_fallback(profile, palette_index)

func _load_imported_model(path: String) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("SYSTEM NPC: GLB scene could not be loaded: " + path)
		return false
	imported_model = packed.instantiate() as Node3D
	if imported_model == null:
		push_warning("SYSTEM NPC: GLB root is not Node3D: " + path)
		return false
	imported_model.name = "RiggedGLBCharacter"
	add_child(imported_model)
	animation_player = _find_animation_player(imported_model)
	set_activity(current_activity)
	return true

func _build_fallback(profile: Dictionary, palette_index: int) -> void:
	fallback_model = FALLBACK_VISUAL.new()
	fallback_model.name = "ProceduralFallbackCharacter"
	add_child(fallback_model)
	if fallback_model.has_method("configure"):
		fallback_model.call("configure", profile, palette_index)

func _find_animation_player(root: Node) -> AnimationPlayer:
	for child in root.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var nested := _find_animation_player(child)
		if nested != null:
			return nested
	return null

func set_activity(value: String) -> void:
	current_activity = value
	if is_instance_valid(fallback_model):
		fallback_model.call("set_activity", value)
		return
	if not is_instance_valid(animation_player):
		return
	var desired := "Idle_Breathing"
	if value in ["run", "sprint", "running"]:
		desired = "Run_Cycle"
	elif value in ["jump", "leap"]:
		desired = "Jump_Animation"
	elif value in ["attack", "combat", "fight"]:
		desired = "Attack_Animation"
	elif value in ["work", "eat", "socialize", "wander", "travel", "walk"]:
		desired = "Walk_Cycle"
	var available := animation_player.get_animation_list()
	for animation_name in available:
		if desired.to_lower() in str(animation_name).to_lower():
			animation_player.play(animation_name)
			return
	if not available.is_empty():
		animation_player.play(available[0])

func set_outfit(outfit_id: String) -> void:
	if not is_instance_valid(imported_model):
		return
	var palettes := {
		"civilian": Color8(54, 82, 92),
		"hunter": Color8(20, 48, 82),
		"guard": Color8(72, 42, 28),
		"royal": Color8(86, 54, 104)
	}
	var cloth_color: Color = palettes.get(outfit_id.to_lower(), palettes["civilian"])
	for node in _collect_mesh_nodes(imported_model):
		var mesh_node := node as MeshInstance3D
		var part_name := mesh_node.name.to_lower()
		var tint := Color.TRANSPARENT
		if "jacket" in part_name or "sleeve" in part_name:
			tint = cloth_color
		elif "trousers" in part_name:
			tint = cloth_color.darkened(0.48)
		elif "belt" in part_name:
			tint = Color8(156, 112, 48)
		elif "boot" in part_name or "glove" in part_name:
			tint = Color8(28, 24, 22)
		if tint.a > 0.0:
			var material := StandardMaterial3D.new()
			material.albedo_color = tint
			material.roughness = 0.78
			mesh_node.material_override = material

func _collect_mesh_nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		if child is MeshInstance3D:
			result.append(child)
		result.append_array(_collect_mesh_nodes(child))
	return result

func get_character_status() -> Dictionary:
	return {
		"model_source": "glb" if is_instance_valid(imported_model) else "procedural_fallback",
		"model_path": selected_model_path,
		"has_animation_player": is_instance_valid(animation_player),
		"activity": current_activity
	}
