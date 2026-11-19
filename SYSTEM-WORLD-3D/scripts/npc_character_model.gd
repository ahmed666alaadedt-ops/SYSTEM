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
var body_type := "average"
var height_type := "average"
var appearance_profile: Dictionary = {}
var hair_style := "short"
var hairstyle_attachment: BoneAttachment3D
var hairstyle_mesh_count := 0

func configure(profile: Dictionary, palette_index: int = 0) -> void:
	name = "NPCCharacter_" + str(profile.get("name", "Resident")).replace(" ", "_")
	appearance_profile = profile.duplicate(true)
	hair_style = _normalize_hair_style(str(profile.get("hair_style", "short")))
	var gender_text := str(profile.get("gender", profile.get("appearance", ""))).to_lower()
	var is_female := gender_text in ["female", "woman", "girl", "أنثى", "بنت", "امرأة"]
	if gender_text.is_empty():
		is_female = (palette_index % 2) == 1
	var age_value = float(profile.get("age", 30.0))
	age_group = str(profile.get("age_group", "")).to_lower()
	if age_group.is_empty():
		age_group = "child" if age_value < 18.0 else ("elder" if age_value >= 60.0 else "adult")
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

	body_type = str(profile.get("body_type", profile.get("body", ""))).to_lower()
	if body_type in ["سمين", "بدين", "heavy", "fat", "overweight"]:
		body_type = "heavy"
	elif body_type in ["نحيف", "ضعيف", "slim", "thin", "lean"]:
		body_type = "slim"
	elif body_type in ["قوي", "ضخم العضلات", "muscular", "strong", "stocky"]:
		body_type = "muscular"
	elif body_type in ["رياضي", "athletic"]:
		body_type = "athletic"
	else:
		body_type = ["average", "slim", "heavy", "athletic", "muscular"][posmod(palette_index, 5)]

	height_type = str(profile.get("height_type", profile.get("height", ""))).to_lower()
	if height_type in ["قصير", "قصيرة", "short"]:
		height_type = "short"
	elif height_type in ["طويل", "طويلة", "tall"]:
		height_type = "tall"
	elif height_type in ["متوسط", "متوسطة", "average", "medium"]:
		height_type = "average"
	else:
		height_type = ["short", "average", "tall"][posmod(int(palette_index / 2), 3)]

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
	var body_width := 1.0
	var body_depth := 1.0
	match body_type:
		"heavy":
			body_width = 1.22
			body_depth = 1.18
		"slim":
			body_width = 0.82
			body_depth = 0.88
		"athletic":
			body_width = 1.07
			body_depth = 1.02
		"muscular":
			body_width = 1.16
			body_depth = 1.10
	var stature := 1.0
	match height_type:
		"short":
			stature = 0.91
		"tall":
			stature = 1.09
	imported_model.scale = Vector3(body_width, stature, body_depth)
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
	var width_scale := 1.0
	var depth_scale := 1.0
	match body_type:
		"heavy":
			width_scale = 1.22
			depth_scale = 1.18
		"slim":
			width_scale = 0.82
			depth_scale = 0.88
		"athletic":
			width_scale = 1.07
			depth_scale = 1.02
		"muscular":
			width_scale = 1.16
			depth_scale = 1.10
	var height_scale := 1.0
	match height_type:
		"short":
			height_scale = 0.91
		"tall":
			height_scale = 1.09
	var age_scale := 0.68 if age_group == "child" else (0.93 if age_group == "elder" else 1.0)
	fallback_model.scale = Vector3(width_scale * age_scale, height_scale * age_scale, depth_scale * age_scale)

func _find_animation_player(root: Node) -> AnimationPlayer:
	for child in root.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var nested := _find_animation_player(child)
		if nested != null:
			return nested
	return null

func set_activity(value: String) -> void:
	if age_group == "child" and value in ["attack", "combat", "fight"]:
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
	elif value in ["work", "eat", "socialize", "wander", "travel", "walk", "play", "school", "family"]:
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
	match str(appearance_profile.get("hair_color", "")):
		"أسود":
			hair_color = Color8(28, 22, 20)
		"بني":
			hair_color = Color8(92, 52, 30)
		"أشقر":
			hair_color = Color8(196, 156, 76)
		"أبيض":
			hair_color = Color8(215, 218, 220)
		"أحمر":
			hair_color = Color8(142, 42, 30)
	var skeleton := _find_skeleton(imported_model)
	if is_instance_valid(skeleton):
		var head_bone := skeleton.find_bone("head")
		if head_bone >= 0:
			var face_scale := Vector3.ONE
			match str(appearance_profile.get("face", "متوازن")):
				"حاد":
					face_scale = Vector3(0.94, 1.05, 0.98)
				"ناعم":
					face_scale = Vector3(1.04, 1.0, 1.03)
				"عريض":
					face_scale = Vector3(1.12, 0.97, 1.0)
			skeleton.set_bone_pose_scale(head_bone, face_scale)
		_apply_hair_style(skeleton, hair_color)
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

func _normalize_hair_style(value: String) -> String:
	var style := value.to_lower().strip_edges()
	match style:
		"متوسط", "medium":
			return "medium"
		"طويل", "long":
			return "long"
		"مجعد", "كيرلي", "curly":
			return "curly"
		"ضفيرة", "مضفور", "braided", "braid":
			return "braided"
		"ذيل حصان", "مربوط", "pony tail", "ponytail":
			return "ponytail"
		"كعكة", "bun":
			return "bun"
		_:
			return "short"

func _apply_hair_style(skeleton: Skeleton3D, color: Color) -> void:
	if is_instance_valid(hairstyle_attachment):
		hairstyle_attachment.queue_free()
	hairstyle_mesh_count = 0
	hairstyle_attachment = BoneAttachment3D.new()
	hairstyle_attachment.name = "RuntimeHairstyle"
	hairstyle_attachment.bone_name = "head"
	skeleton.add_child(hairstyle_attachment)
	var hair_material := StandardMaterial3D.new()
	hair_material.albedo_color = color
	hair_material.roughness = 0.86
	match hair_style:
		"medium":
			_add_hair_capsule("MediumHairLeft", Vector3(-0.135, 0.09, 0.035), 0.032, 0.22, hair_material)
			_add_hair_capsule("MediumHairRight", Vector3(0.135, 0.09, 0.035), 0.032, 0.22, hair_material)
		"long":
			_add_hair_capsule("LongHairLeft", Vector3(-0.135, 0.02, 0.035), 0.035, 0.38, hair_material)
			_add_hair_capsule("LongHairRight", Vector3(0.135, 0.02, 0.035), 0.035, 0.38, hair_material)
		"curly":
			for x in [-0.13, -0.08, -0.025, 0.035, 0.09, 0.14]:
				for z in [-0.055, 0.025]:
					_add_hair_sphere("CurlyLock", Vector3(x, 0.30, z), Vector3(0.065, 0.065, 0.065), hair_material)
		"braided":
			_add_hair_capsule("BraidLeft", Vector3(-0.14, 0.00, 0.04), 0.028, 0.32, hair_material)
			for step in range(5):
				var y := 0.18 - float(step) * 0.065
				_add_hair_sphere("BraidKnot", Vector3(-0.14, y, 0.065), Vector3(0.045, 0.045, 0.045), hair_material)
		"ponytail":
			_add_hair_sphere("PonytailTie", Vector3(0.0, 0.23, 0.14), Vector3(0.075, 0.07, 0.07), hair_material)
			_add_hair_capsule("Ponytail", Vector3(0.0, 0.04, 0.20), 0.045, 0.34, hair_material)
		"bun":
			_add_hair_sphere("HairBun", Vector3(0.0, 0.25, 0.15), Vector3(0.11, 0.12, 0.10), hair_material)

func _add_hair_sphere(piece_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = dimensions
	instance.material_override = mat
	hairstyle_attachment.add_child(instance)
	hairstyle_mesh_count += 1

func _add_hair_capsule(piece_name: String, at: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = mat
	hairstyle_attachment.add_child(instance)
	hairstyle_mesh_count += 1
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

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if is_instance_valid(found):
			return found
	return null

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
		"age_group": age_group,
		"body_type": body_type,
		"height_type": height_type,
		"hair_style": hair_style,
		"hairstyle_mesh_count": hairstyle_mesh_count,
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
