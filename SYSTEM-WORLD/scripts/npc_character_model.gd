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
var appearance_profile: Dictionary = {}
var age_group := "adult"
var body_type := "average"
var height_type := "average"

func configure(profile: Dictionary, palette_index: int = 0) -> void:
	name = "NPCCharacter_" + str(profile.get("name", "Resident")).replace(" ", "_")
	appearance_profile = profile.duplicate(true)
	var gender_text := str(profile.get("gender", profile.get("appearance", ""))).to_lower()
	var is_female := gender_text in ["female", "woman", "girl", "أنثى", "بنت", "امرأة"]
	if gender_text.is_empty():
		is_female = (palette_index % 2) == 1
	var age_value := float(profile.get("age", 30.0))
	age_group = str(profile.get("age_group", "")).to_lower()
	if age_group.is_empty():
		age_group = "child" if age_value < 18.0 else ("elder" if age_value >= 60.0 else "adult")
	if age_group in ["طفل", "طفلة", "child", "children"]:
		age_group = "child"
	elif age_group in ["كبير السن", "مسن", "مسنة", "elderly", "senior"]:
		age_group = "elder"
	else:
		age_group = "adult"
	appearance_profile["age_group"] = age_group
	if age_group == "child":
		# Keep the civilian-only rule consistent in both imported and fallback models.
		appearance_profile["job"] = "civilian"
		appearance_profile["occupation"] = "civilian"
	if age_group == "child":
		selected_model_path = CHILD_FEMALE_MODEL_PATH if is_female else CHILD_MALE_MODEL_PATH
	elif age_group == "elder":
		selected_model_path = ELDER_FEMALE_MODEL_PATH if is_female else ELDER_MALE_MODEL_PATH
	else:
		selected_model_path = FEMALE_MODEL_PATH if is_female else MALE_MODEL_PATH
	body_type = str(profile.get("body_type", profile.get("body", "average"))).to_lower()
	height_type = str(profile.get("height_type", "average")).to_lower()
	if _load_imported_model(selected_model_path):
		var role := str(appearance_profile.get("job", appearance_profile.get("occupation", ""))).to_lower()
		var world_value := str(profile.get("world_id", profile.get("world", "modern"))).to_lower()
		var outfit_id := "modern"
		if world_value in ["historical", "history", "التاريخي", "تاريخي"]:
			outfit_id = "historical"
		elif world_value in ["fantasy", "mythic", "mythology", "الأسطوري", "الخيالي"]:
			outfit_id = "mythic"
		elif world_value in ["greed_island", "greed island", "جزيرة الطمع"]:
			outfit_id = "greed_island"
		# Children are civilian/family residents only. Never dress them as
		# guards, soldiers, hunters, guild fighters, or combat-capable nobles.
		if age_group == "child":
			outfit_id = "civilian"
		elif "guard" in role or "soldier" in role or "police" in role or "حارس" in role:
			outfit_id = "guard"
		elif "hunter" in role or "guild" in role or "صياد" in role:
			outfit_id = "hunter"
		elif "noble" in role or "royal" in role or "نبيل" in role:
			outfit_id = "royal"
		set_appearance(palette_index)
		set_outfit(outfit_id, palette_index)
		return
	_build_fallback(appearance_profile, palette_index)

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
	var width_scale := 1.0
	var depth_scale := 1.0
	if body_type in ["slim", "thin", "lean", "نحيف", "ضعيف"]:
		width_scale = 0.84
		depth_scale = 0.90
	elif body_type in ["heavy", "overweight", "بدين", "سمين"]:
		width_scale = 1.18
		depth_scale = 1.14
	elif body_type in ["athletic", "رياضي"]:
		width_scale = 1.06
		depth_scale = 1.02
	elif body_type in ["muscular", "strong", "قوي", "ضخم العضلات"]:
		width_scale = 1.14
		depth_scale = 1.08
	var stature := 1.0
	if height_type in ["short", "قصير", "قصيرة"]:
		stature = 0.92
	elif height_type in ["tall", "طويل", "طويلة"]:
		stature = 1.08
	imported_model.scale = Vector3(width_scale, stature, depth_scale)
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
	var requested_activity := value.to_lower()
	var combat_activities := ["attack", "combat", "fight", "battle", "قتال", "هجوم", "معركة"]
	# Child residents may socialize, learn, play, walk and run, but never enter
	# combat animations, even if a caller requests a combat activity by mistake.
	if age_group == "child" and requested_activity in combat_activities:
		current_activity = "idle"
	else:
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
	match str(appearance_profile.get("skin_tone", "")).to_lower():
		"fair", "فاتح", "بيضاء":
			skin_color = Color8(238, 205, 178)
		"olive", "قمحي", "حنطي":
			skin_color = Color8(190, 143, 105)
		"tan", "أسمر", "برونزي":
			skin_color = Color8(151, 101, 72)
		"dark", "داكن", "غامق":
			skin_color = Color8(91, 59, 45)
	match str(appearance_profile.get("hair_color", "")).to_lower():
		"black", "أسود":
			hair_color = Color8(28, 22, 20)
		"brown", "بني":
			hair_color = Color8(92, 52, 30)
		"blonde", "أشقر":
			hair_color = Color8(196, 156, 76)
		"white", "أبيض", "رمادي":
			hair_color = Color8(215, 218, 220)
		"red", "أحمر":
			hair_color = Color8(142, 42, 30)
	var eye_color := Color8(45, 112, 174)
	match str(appearance_profile.get("eye_color", "")).to_lower():
		"brown", "بني":
			eye_color = Color8(104, 64, 35)
		"green", "أخضر":
			eye_color = Color8(55, 125, 76)
		"gray", "رمادي":
			eye_color = Color8(116, 132, 145)
		"hazel", "عسلي":
			eye_color = Color8(151, 111, 54)
		"blue", "أزرق":
			eye_color = Color8(45, 112, 174)
	var skeleton := _find_skeleton(imported_model)
	if is_instance_valid(skeleton):
		var head_bone := skeleton.find_bone("head")
		if head_bone >= 0:
			var face_scale := Vector3.ONE
			var face_shape := str(appearance_profile.get("face_shape", appearance_profile.get("face", ""))).to_lower()
			if face_shape.is_empty():
				var face_variants := ["balanced", "sharp", "soft", "wide", "long", "round", "heart"]
				face_shape = face_variants[posmod(variant_index, face_variants.size())]
			match face_shape:
				"sharp", "حاد":
					face_scale = Vector3(0.94, 1.05, 0.98)
				"soft", "ناعم":
					face_scale = Vector3(1.04, 1.0, 1.03)
				"wide", "عريض":
					face_scale = Vector3(1.12, 0.97, 1.0)
				"long", "طويل":
					face_scale = Vector3(0.96, 1.10, 0.98)
				"round", "مستدير":
					face_scale = Vector3(1.08, 0.96, 1.06)
				"heart", "قلبي":
					face_scale = Vector3(0.98, 1.04, 1.08)
			skeleton.set_bone_pose_scale(head_bone, face_scale)
	var lip_color := Color8(150, 78, 75)
	var sclera_color := Color8(238, 232, 218)
	for node in _collect_mesh_nodes(imported_model):
		var mesh_node := node as MeshInstance3D
		var part_name := mesh_node.name.to_lower()
		var is_skin := "body" in part_name or "faceskin" in part_name or "hands" in part_name or "nose" in part_name or "ear" in part_name or "cheek" in part_name or "palm" in part_name or "finger" in part_name or "upperarm" in part_name or "forearm" in part_name or "thigh" in part_name or "calf" in part_name or "foot" in part_name or "jaw" in part_name
		var is_hair := "hair" in part_name or "brow" in part_name or "eyebrow" in part_name or "beard" in part_name or "mustache" in part_name
		var is_iris := "iris" in part_name
		var is_pupil := "pupil" in part_name
		var is_sclera := "eyewhite" in part_name or "sclera" in part_name or "eyeleft" in part_name or "eyeright" in part_name or part_name.ends_with("_eyes")
		var is_lip := "lip" in part_name or "mouth" in part_name
		var is_highlight := "highlight" in part_name or "catchlight" in part_name
		if is_skin or is_hair or is_iris or is_pupil or is_sclera or is_lip or is_highlight:
			var material := StandardMaterial3D.new()
			if is_skin:
				material.albedo_color = skin_color
				material.roughness = 0.78
			elif is_hair:
				material.albedo_color = hair_color
				material.roughness = 0.86
			elif is_iris:
				material.albedo_color = eye_color
				material.roughness = 0.24
			elif is_pupil:
				material.albedo_color = Color8(8, 7, 8)
				material.roughness = 0.18
			elif is_sclera:
				material.albedo_color = sclera_color
				material.roughness = 0.3
			elif is_lip:
				material.albedo_color = lip_color
				material.roughness = 0.5
			else:
				material.albedo_color = Color8(255, 248, 232)
				material.roughness = 0.2
			mesh_node.material_override = material

func _find_skeleton(root: Node) -> Skeleton3D:
	for child in root.get_children():
		if child is Skeleton3D:
			return child as Skeleton3D
		var nested := _find_skeleton(child)
		if nested != null:
			return nested
	return null

## Applies skeletal facial poses when the imported GLB contains the facial control bones.
## These are bone-driven poses, not blendshape morph targets.
func set_facial_expression(expression: String) -> void:
	var skeleton := _find_skeleton(imported_model) if is_instance_valid(imported_model) else null
	if not is_instance_valid(skeleton):
		return
	var jaw := skeleton.find_bone("jaw")
	var eye_left := skeleton.find_bone("eye.L")
	var eye_right := skeleton.find_bone("eye.R")
	var brow_left := skeleton.find_bone("brow.L")
	var brow_right := skeleton.find_bone("brow.R")
	for bone_index in [jaw, eye_left, eye_right, brow_left, brow_right]:
		if bone_index >= 0:
			skeleton.set_bone_pose_rotation(bone_index, Quaternion.IDENTITY)
			skeleton.set_bone_pose_scale(bone_index, Vector3.ONE)
	match expression.to_lower():
		"happy", "فرح", "سعيد":
			if brow_left >= 0:
				skeleton.set_bone_pose_rotation(brow_left, Quaternion(Vector3.RIGHT, -0.08))
			if brow_right >= 0:
				skeleton.set_bone_pose_rotation(brow_right, Quaternion(Vector3.RIGHT, -0.08))
		"angry", "غاضب":
			if brow_left >= 0:
				skeleton.set_bone_pose_rotation(brow_left, Quaternion(Vector3.RIGHT, 0.18))
			if brow_right >= 0:
				skeleton.set_bone_pose_rotation(brow_right, Quaternion(Vector3.RIGHT, 0.18))
		"surprised", "مندهش":
			if jaw >= 0:
				skeleton.set_bone_pose_rotation(jaw, Quaternion(Vector3.RIGHT, -0.22))
			if brow_left >= 0:
				skeleton.set_bone_pose_rotation(brow_left, Quaternion(Vector3.RIGHT, -0.20))
			if brow_right >= 0:
				skeleton.set_bone_pose_rotation(brow_right, Quaternion(Vector3.RIGHT, -0.20))
		"sad", "حزين":
			if brow_left >= 0:
				skeleton.set_bone_pose_rotation(brow_left, Quaternion(Vector3.RIGHT, -0.12))
			if brow_right >= 0:
				skeleton.set_bone_pose_rotation(brow_right, Quaternion(Vector3.RIGHT, 0.12))
		"talking", "يتكلم":
			if jaw >= 0:
				skeleton.set_bone_pose_rotation(jaw, Quaternion(Vector3.RIGHT, -0.12))
		"fear", "afraid", "خائف":
			if jaw >= 0:
				skeleton.set_bone_pose_rotation(jaw, Quaternion(Vector3.RIGHT, -0.10))
			if brow_left >= 0:
				skeleton.set_bone_pose_rotation(brow_left, Quaternion(Vector3.RIGHT, -0.24))
			if brow_right >= 0:
				skeleton.set_bone_pose_rotation(brow_right, Quaternion(Vector3.RIGHT, -0.24))
		"confused", "حائر", "محتار":
			if brow_left >= 0:
				skeleton.set_bone_pose_rotation(brow_left, Quaternion(Vector3.RIGHT, -0.16))
			if brow_right >= 0:
				skeleton.set_bone_pose_rotation(brow_right, Quaternion(Vector3.RIGHT, 0.08))
		"determined", "مصمم", "عازم":
			if brow_left >= 0:
				skeleton.set_bone_pose_rotation(brow_left, Quaternion(Vector3.RIGHT, 0.12))
			if brow_right >= 0:
				skeleton.set_bone_pose_rotation(brow_right, Quaternion(Vector3.RIGHT, 0.12))
		"blink", "رمش":
			if eye_left >= 0:
				skeleton.set_bone_pose_scale(eye_left, Vector3(1.0, 0.12, 1.0))
			if eye_right >= 0:
				skeleton.set_bone_pose_scale(eye_right, Vector3(1.0, 0.12, 1.0))

## Directs both eye control bones for gaze tracking. Values are clamped to avoid
## unnatural rotations; call from dialogue, attention, or look-at systems.
func set_eye_direction(direction: Vector2) -> void:
	var skeleton := _find_skeleton(imported_model) if is_instance_valid(imported_model) else null
	if not is_instance_valid(skeleton):
		return
	var horizontal := clampf(direction.x, -1.0, 1.0) * 0.28
	var vertical := clampf(direction.y, -1.0, 1.0) * 0.18
	for bone_name in ["eye.L", "eye.R"]:
		var bone_index := skeleton.find_bone(bone_name)
		if bone_index >= 0:
			var yaw := Quaternion(Vector3.UP, horizontal)
			var pitch := Quaternion(Vector3.RIGHT, -vertical)
			skeleton.set_bone_pose_rotation(bone_index, yaw * pitch)

func set_outfit(outfit_id: String, variant_index: int = 0) -> void:
	if not is_instance_valid(imported_model):
		return
	var palettes := {
		"civilian": [Color8(54, 82, 92), Color8(86, 68, 48), Color8(72, 78, 83), Color8(48, 76, 62)],
		"modern": [Color8(22, 48, 70), Color8(38, 62, 78), Color8(48, 52, 62), Color8(30, 76, 78)],
		"historical": [Color8(112, 62, 34), Color8(92, 46, 38), Color8(142, 112, 62), Color8(54, 68, 52)],
		"mythic": [Color8(58, 42, 112), Color8(112, 70, 34), Color8(38, 68, 112), Color8(112, 42, 64)],
		"greed_island": [Color8(38, 104, 92), Color8(76, 82, 42), Color8(62, 62, 112), Color8(132, 76, 32)],
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
	var facial_control_bones: Array[String] = []
	if is_instance_valid(imported_model):
		for node in _collect_skeleton_nodes(imported_model):
			skeleton_count += 1
			var rig := node as Skeleton3D
			for bone_name in ["head", "jaw", "eye.L", "eye.R", "brow.L", "brow.R"]:
				if rig.find_bone(bone_name) >= 0 and not facial_control_bones.has(bone_name):
					facial_control_bones.append(bone_name)
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
		"facial_control_bones": facial_control_bones,
		"facial_controls_complete": facial_control_bones.size() == 6,
		"activity": current_activity
	}

func _collect_skeleton_nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		if child is Skeleton3D:
			result.append(child)
		result.append_array(_collect_skeleton_nodes(child))
	return result
