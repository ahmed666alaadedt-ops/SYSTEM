extends Node3D
class_name SystemNPCCharacterModel

## Loads generated rigged GLB characters when available.
## Keeps the procedural Godot model as a safe fallback.

const FALLBACK_VISUAL = preload("res://scripts/npc_humanoid_visual.gd")
const MALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Male.glb"
const FEMALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Female.glb"
const ELDER_MALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Elder_Male.glb"
const ELDER_FEMALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Elder_Female.glb"
const CHILD_MALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Child_Male.glb"
const CHILD_FEMALE_MODEL_PATH := "res://assets/characters/SYSTEM_Humanoid_Child_Female.glb"

var imported_model: Node3D
var fallback_model: Node3D
var animation_player: AnimationPlayer
var current_activity := "idle"
var selected_model_path := ""
var age_group := "adult"

func configure(profile: Dictionary, palette_index: int = 0) -> void:
	name = "NPCCharacter_" + str(profile.get("name", "Resident")).replace(" ", "_")
	var gender_text := str(profile.get("gender", profile.get("appearance", ""))).to_lower()
	var is_female := gender_text in ["female", "woman", "girl", "أنثى", "بنت", "امرأة"]
	if gender_text.is_empty():
		is_female = (palette_index % 2) == 1
	age_group = str(profile.get("age_group", profile.get("age", "adult"))).to_lower()
	if age_group in ["طفل", "طفلة", "child", "children"]:
		age_group = "child"
	elif age_group in ["كبير السن", "مسن", "مسنة", "elderly", "senior"]:
		age_group = "elder"
	else:
		age_group = "adult"
	if age_group == "child":
		selected_model_path = CHILD_FEMALE_MODEL_PATH if is_female else CHILD_MALE_MODEL_PATH
	elif age_group == "elder":
		selected_model_path = ELDER_FEMALE_MODEL_PATH if is_female else ELDER_MALE_MODEL_PATH
	else:
		selected_model_path = FEMALE_MODEL_PATH if is_female else MALE_MODEL_PATH
	if _load_imported_model(selected_model_path):
		var role := str(profile.get("job", profile.get("occupation", ""))).to_lower()
		if age_group == "child":
			role = "civilian"
		var outfit_id := "civilian"
		if "guard" in role or "soldier" in role or "police" in role:
			outfit_id = "guard"
		elif "hunter" in role or "guild" in role:
			outfit_id = "hunter"
		elif "noble" in role or "royal" in role:
			outfit_id = "royal"
		set_appearance(palette_index)
		set_outfit(outfit_id, palette_index)
		return
	_build_fallback(profile, palette_index)

func _load_imported_model(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var packed := ResourceLoader.load(path) as PackedScene
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
	if age_group == "child" and value in ["attack", "combat", "fight", "run", "sprint", "running", "jump", "leap"]:
		value = "idle"
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
	var aliases := [desired.to_lower()]
	if desired == "Walk_Cycle":
		aliases.append("walk")
	elif desired == "Run_Cycle":
		aliases.append("run")
	for animation_name in available:
		var actual_name := str(animation_name).to_lower()
		for alias in aliases:
			if actual_name.contains(alias):
				animation_player.play(animation_name)
				return
	if not available.is_empty():
		animation_player.play(available[0])

func set_appearance(variant_index: int = 0) -> void:
	if not is_instance_valid(imported_model):
		return
	var skin_tones := [
		Color8(232, 190, 154), Color8(190, 133, 96),
		Color8(139, 91, 66), Color8(104, 70, 56)
	]
	var hair_tones := [
		Color8(35, 22, 17), Color8(72, 43, 25),
		Color8(116, 83, 48), Color8(35, 39, 48)
	]
	var skin_color: Color = skin_tones[posmod(variant_index, skin_tones.size())]
	var hair_color: Color = hair_tones[posmod(variant_index, hair_tones.size())]
	for node in _collect_mesh_nodes(imported_model):
		var mesh_node := node as MeshInstance3D
		var part_name := mesh_node.name.to_lower()
		var is_skin := "body" in part_name or "faceskin" in part_name or "hands" in part_name or "nose" in part_name or "ear" in part_name or "cheek" in part_name or "palm" in part_name or "finger" in part_name or "upperarm" in part_name or "forearm" in part_name or "thigh" in part_name or "calf" in part_name or "foot" in part_name
		var is_hair := "hair" in part_name
		if is_skin or is_hair:
			var material := StandardMaterial3D.new()
			material.albedo_color = skin_color if is_skin else hair_color
			material.roughness = 0.82
			mesh_node.material_override = material

func set_outfit(outfit_id: String, variant_index: int = 0) -> void:
	if not is_instance_valid(imported_model):
		return
	var palettes := {
		"civilian": [Color8(54, 82, 92), Color8(86, 68, 48), Color8(72, 78, 83), Color8(48, 76, 62)],
		"hunter": [Color8(20, 48, 82), Color8(30, 64, 82), Color8(36, 42, 68), Color8(62, 54, 36)],
		"guard": [Color8(72, 42, 28), Color8(46, 58, 72), Color8(72, 62, 34), Color8(42, 66, 54)],
		"royal": [Color8(86, 54, 104), Color8(105, 74, 34), Color8(44, 62, 104), Color8(92, 42, 54)]
	}
	var choices: Array = palettes.get(outfit_id.to_lower(), palettes["civilian"])
	var cloth_color: Color = choices[posmod(variant_index, choices.size())]
	for node in _collect_mesh_nodes(imported_model):
		var mesh_node := node as MeshInstance3D
		var part_name := mesh_node.name.to_lower()
		var tint := Color.TRANSPARENT
		if "jacket" in part_name or "sleeve" in part_name:
			tint = cloth_color
		elif "trousers" in part_name:
			tint = cloth_color.darkened(0.48)
		elif "belt" in part_name or "trim" in part_name:
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
	var skeleton_count := 0
	var mesh_count := 0
	var clip_names: Array[String] = []
	if is_instance_valid(imported_model):
		for node in _collect_skeleton_nodes(imported_model):
			skeleton_count += 1
		for node in _collect_mesh_nodes(imported_model):
			mesh_count += 1
		if is_instance_valid(animation_player):
			for clip_name in animation_player.get_animation_list():
				clip_names.append(str(clip_name))
	return {
		"model_source": "glb" if is_instance_valid(imported_model) else "procedural_fallback",
		"model_path": selected_model_path,
		"has_animation_player": is_instance_valid(animation_player),
		"skeleton_count": skeleton_count,
		"mesh_instance_count": mesh_count,
		"animation_clips": clip_names,
		"activity": current_activity
	}

func _collect_skeleton_nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		if child is Skeleton3D:
			result.append(child)
		result.append_array(_collect_skeleton_nodes(child))
	return result
