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
var hair_style := "short"
var hairstyle_attachment: BoneAttachment3D
var hairstyle_mesh_count := 0
var is_player_character := false

func configure(profile: Dictionary, palette_index: int = 0) -> void:
	name = "NPCCharacter_" + str(profile.get("name", "Resident")).replace(" ", "_")
	appearance_profile = profile.duplicate(true)
	is_player_character = bool(profile.get("is_player_character", false))
	hair_style = _normalize_hair_style(str(profile.get("hair_style", "short")))
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
	var requested_role := str(appearance_profile.get("job", appearance_profile.get("occupation", ""))).to_lower().strip_edges()
	var restricted_roles := [
		"police", "policeman", "police_officer", "guard", "security",
		"monitor", "supervisor", "administrator", "admin", "soldier", "military",
		"شرطة", "شرطي", "حارس", "مراقب", "مشرف", "إداري", "عسكري"
	]
	if restricted_roles.has(requested_role):
		appearance_profile["job"] = "civilian"
		appearance_profile["occupation"] = "civilian"
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

var is_defending := false

func set_activity(value: String) -> void:
	var requested_activity := value.to_lower()
	var combat_activities := ["attack", "combat", "fight", "battle", "قتال", "هجوم", "معركة"]
	# Civilian NPCs never initiate offensive combat, regardless of age.
	if requested_activity in combat_activities and not is_player_character:
		current_activity = "idle"
		is_defending = false
		_apply_activity_animation("idle")
		return
	current_activity = value
	is_defending = requested_activity in ["defend", "evade", "call_for_help"]
	_apply_activity_animation(value)

## Called by the threat-response system after any civilian NPC is attacked.
## Adults adopt a defensive stance; minors evade toward safety. No NPC counterattacks.
func respond_to_attack() -> bool:
	is_defending = true
	if age_group == "child":
		current_activity = "evade"
		_apply_activity_animation("evade")
	else:
		current_activity = "defend"
		_apply_activity_animation("defend")
	return true

func _apply_activity_animation(value: String) -> void:
	if is_instance_valid(fallback_model):
		fallback_model.call("set_activity", value)
		return
	if not is_instance_valid(animation_player):
		return
	var requested := value.to_lower()
	var candidates: Array[String] = ["Idle_Breathing", "Idle"]
	if requested in ["run", "sprint", "running", "evade"]:
		candidates = ["Run_Cycle", "Run", "Running"]
	elif requested in ["walk", "work", "eat", "socialize", "wander", "travel"]:
		candidates = ["Walk_Cycle", "Walk", "Walking"]
	elif requested in ["defend", "block", "protect"]:
		candidates = ["Block_Animation", "Block"]
	elif requested in ["jump", "leap"]:
		candidates = ["Jump_Animation", "Jump"]
	elif requested in ["attack", "combat", "fight"]:
		candidates = ["Attack_Animation", "Attack"]
	var available := animation_player.get_animation_list()
	for candidate in candidates:
		for animation_name in available:
			if str(animation_name).to_lower() == candidate.to_lower():
				animation_player.play(animation_name)
				return
	# Never default to the first imported clip: it may be an attack animation.
	for animation_name in available:
		if "idle" in str(animation_name).to_lower():
			animation_player.play(animation_name)
			return
	push_warning("SYSTEM NPC: no safe animation clip for activity " + value)

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
	hair_color = _resolve_hair_color(str(appearance_profile.get("hair_color", "black")))
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
	var face_shape := str(appearance_profile.get("face_shape", appearance_profile.get("face", ""))).to_lower()
	if face_shape.is_empty():
		var face_variants := ["balanced", "sharp", "soft", "wide", "long", "round", "heart"]
		face_shape = face_variants[posmod(variant_index, face_variants.size())]
	set_face_shape(face_shape)
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
	var hair_rig := _find_skeleton(imported_model)
	if is_instance_valid(hair_rig):
		_apply_hair_style(hair_rig, hair_color)

## Changes the overall facial silhouette through the head and jaw rig controls.
## The seven profiles are lightweight and safe to apply during character creation.
func set_face_shape(shape_id: String) -> void:
	var skeleton := _find_skeleton(imported_model) if is_instance_valid(imported_model) else null
	if not is_instance_valid(skeleton):
		return
	var face_shape := shape_id.to_lower()
	var face_scale := Vector3.ONE
	var jaw_scale := Vector3.ONE
	match face_shape:
		"sharp", "حاد":
			face_shape = "sharp"
			face_scale = Vector3(0.94, 1.05, 0.98)
			jaw_scale = Vector3(0.94, 1.06, 0.96)
		"soft", "ناعم":
			face_shape = "soft"
			face_scale = Vector3(1.04, 1.0, 1.03)
			jaw_scale = Vector3(1.04, 0.98, 1.02)
		"wide", "عريض":
			face_shape = "wide"
			face_scale = Vector3(1.12, 0.97, 1.0)
			jaw_scale = Vector3(1.10, 0.98, 1.0)
		"long", "طويل":
			face_shape = "long"
			face_scale = Vector3(0.96, 1.10, 0.98)
			jaw_scale = Vector3(0.98, 1.08, 0.98)
		"round", "مستدير":
			face_shape = "round"
			face_scale = Vector3(1.08, 0.96, 1.06)
			jaw_scale = Vector3(1.08, 0.96, 1.06)
		"heart", "قلبي":
			face_shape = "heart"
			face_scale = Vector3(0.98, 1.04, 1.08)
			jaw_scale = Vector3(0.94, 1.02, 0.98)
		_:
			face_shape = "balanced"
	var head_bone := skeleton.find_bone("head")
	if head_bone >= 0:
		skeleton.set_bone_pose_scale(head_bone, face_scale)
	var jaw_bone := skeleton.find_bone("jaw")
	if jaw_bone >= 0:
		skeleton.set_bone_pose_scale(jaw_bone, jaw_scale)
	appearance_profile["face_shape"] = face_shape

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

func _normalize_hair_style(value: String) -> String:
	var style := value.to_lower().strip_edges().replace("-", "_").replace(" ", "_")
	match style:
		"fade", "low_fade", "mid_fade", "high_fade", "taper_fade":
			return "fade"
		"undercut":
			return "undercut"
		"buzz_cut", "crew_cut", "french_crop":
			return "short"
		"textured_crop", "quiff", "pompadour":
			return "quiff"
		"spiky":
			return "spiky"
		"slick_back", "side_part":
			return "slick_back"
		"شعر_متوسط", "شعر_ويفي_طويل", "ويفي":
			return "medium"
		"شعر_طويل", "شعر_طويل_مدرج", "شعر_مجعد_طويل":
			return "long"
		"ذيل_حصان_رجالي":
			return "ponytail"
		"كعكة_رجالية":
			return "topknot"
		"ضفائر_رجالية":
			return "braided"
		"متوسط", "medium", "shoulder_length": return "medium"
		"طويل", "طويل_جدا", "long", "very_long": return "long"
		"مجعد", "كيرلي", "curly": return "curly"
		"ضفيرة", "مضفور", "braided", "braid": return "braided"
		"ذيل_حصان", "مربوط", "pony_tail", "ponytail": return "ponytail"
		"كعكة", "bun": return "bun"
		"بوب", "bob": return "bob"
		"بيكسي", "pixie": return "pixie"
		"مدرج", "layered": return "layered"
		"مرفوع", "topknot", "man_bun": return "topknot"
		"افرو", "أفرو", "afro": return "afro"
		"دريدلوك", "ضفائر_رفيعة", "dreadlocks": return "dreadlocks"
		"شعرتان", "ضفيرتان", "twin_tails": return "twin_tails"
		"شائك", "spiky": return "spiky"
		"جانبي", "side_swept": return "side_swept"
		"محلوق_الجوانب", "undercut": return "undercut"
		_: return "short"

func _resolve_hair_color(value: String = "") -> Color:
	match value.to_lower().strip_edges():
		"أسود", "اسود", "black": return Color8(28, 22, 20)
		"بني", "brown", "chestnut": return Color8(92, 52, 30)
		"أشقر", "اشقر", "blonde", "golden_blonde", "yellow", "أصفر", "اصفر": return Color8(220, 184, 72)
		"أبيض", "ابيض", "white", "silver", "فضي": return Color8(215, 218, 220)
		"رمادي", "gray", "grey", "ash": return Color8(112, 119, 128)
		"أحمر", "احمر", "red", "crimson": return Color8(178, 35, 42)
		"أزرق", "ازرق", "blue", "electric_blue": return Color8(35, 105, 220)
		"أزرق_داكن", "أزرق داكن", "navy", "dark_blue", "أزرق داكن": return Color8(24, 45, 112)
		"سماوي", "cyan", "turquoise": return Color8(38, 190, 205)
		"بنفسجي", "purple", "violet": return Color8(132, 62, 190)
		"وردي", "pink", "rose": return Color8(230, 92, 158)
		"أخضر", "اخضر", "green", "emerald": return Color8(45, 145, 82)
		"برتقالي", "orange", "ginger": return Color8(220, 104, 38)
		"ذهبي", "gold": return Color8(224, 176, 55)
		"أرجواني", "magenta": return Color8(190, 45, 160)
		_: return Color8(35, 22, 17)

func set_hair_color(color_id: String) -> void:
	appearance_profile["hair_color"] = color_id
	if is_instance_valid(fallback_model) and fallback_model.has_method("set_hair_color"):
		fallback_model.call("set_hair_color", color_id)
		return
	var selected_color := _resolve_hair_color(color_id)
	var target_meshes: Array[Node] = _collect_mesh_nodes(imported_model) if is_instance_valid(imported_model) else []
	for node in target_meshes:
		var mesh_node := node as MeshInstance3D
		var part_name := mesh_node.name.to_lower()
		if "hair" in part_name or "brow" in part_name or "beard" in part_name or "mustache" in part_name:
			var material := StandardMaterial3D.new()
			material.albedo_color = selected_color
			material.roughness = 0.86
			mesh_node.material_override = material
	if is_instance_valid(hairstyle_attachment):
		for child in hairstyle_attachment.get_children():
			if child is MeshInstance3D:
				var material := StandardMaterial3D.new()
				material.albedo_color = selected_color
				material.roughness = 0.86
				child.material_override = material

func set_hair_style(style_id: String) -> void:
	hair_style = _normalize_hair_style(style_id)
	appearance_profile["hair_style"] = hair_style
	if is_instance_valid(fallback_model) and fallback_model.has_method("set_hair_style"):
		fallback_model.call("set_hair_style", hair_style)
		return
	var skeleton := _find_skeleton(imported_model) if is_instance_valid(imported_model) else null
	if is_instance_valid(skeleton):
		_apply_hair_style(skeleton, _resolve_hair_color(str(appearance_profile.get("hair_color", "black"))))

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
		"fade":
			_add_hair_capsule("FadeTop", Vector3(0.0, 0.28, 0.0), 0.07, 0.16, hair_material)
			for side in [-1.0, 1.0]:
				_add_hair_capsule("FadeTemple", Vector3(0.175 * side, 0.105, 0.0), 0.018, 0.13, hair_material)
		"quiff":
			_add_hair_capsule("QuiffBase", Vector3(0.0, 0.25, -0.01), 0.065, 0.18, hair_material)
			_add_hair_capsule("QuiffFront", Vector3(0.0, 0.30, -0.08), 0.035, 0.20, hair_material)
			_add_hair_capsule("QuiffSideLeft", Vector3(-0.075, 0.24, -0.02), 0.03, 0.14, hair_material)
			_add_hair_capsule("QuiffSideRight", Vector3(0.075, 0.24, -0.02), 0.03, 0.14, hair_material)
		"slick_back":
			_add_hair_capsule("SlickBackTop", Vector3(0.0, 0.24, 0.045), 0.065, 0.20, hair_material)
			_add_hair_capsule("SlickBackRear", Vector3(0.0, 0.12, 0.13), 0.04, 0.20, hair_material)
			_add_hair_capsule("SlickPartLine", Vector3(0.065, 0.25, -0.015), 0.012, 0.16, hair_material)
		"short":
			_add_hair_capsule("ShortCutTop", Vector3(0.0, 0.23, 0.0), 0.07, 0.14, hair_material)
		"medium", "layered":
			_add_hair_capsule("MediumHairLeft", Vector3(-0.135, 0.09, 0.035), 0.032, 0.22, hair_material)
			_add_hair_capsule("MediumHairRight", Vector3(0.135, 0.09, 0.035), 0.032, 0.22, hair_material)
		"long":
			_add_hair_capsule("LongHairLeft", Vector3(-0.135, 0.02, 0.035), 0.035, 0.38, hair_material)
			_add_hair_capsule("LongHairRight", Vector3(0.135, 0.02, 0.035), 0.035, 0.38, hair_material)
			_add_hair_capsule("LongHairBack", Vector3(0.0, 0.02, 0.12), 0.045, 0.42, hair_material)
		"curly", "afro":
			for x in [-0.13, -0.08, -0.025, 0.035, 0.09, 0.14]:
				for z in [-0.055, 0.025]:
					_add_hair_sphere("CurlyLock", Vector3(x, 0.30, z), Vector3(0.065, 0.065, 0.065), hair_material)
		"braided", "dreadlocks":
			var braid_sides: Array = [-1.0]
			if hair_style == "dreadlocks":
				braid_sides = [-1.0, 1.0]
			for side in braid_sides:
				_add_hair_capsule("BraidLock", Vector3(0.14 * side, 0.00, 0.04), 0.028, 0.36, hair_material)
				for step in range(5):
					var y := 0.18 - float(step) * 0.065
					_add_hair_sphere("BraidKnot", Vector3(0.14 * side, y, 0.065), Vector3(0.045, 0.045, 0.045), hair_material)
		"ponytail":
			_add_hair_sphere("PonytailTie", Vector3(0.0, 0.23, 0.14), Vector3(0.075, 0.07, 0.07), hair_material)
			_add_hair_capsule("Ponytail", Vector3(0.0, 0.04, 0.20), 0.045, 0.40, hair_material)
		"twin_tails":
			for side in [-1.0, 1.0]:
				_add_hair_sphere("TwinTailTie", Vector3(0.14 * side, 0.22, 0.08), Vector3(0.055, 0.055, 0.055), hair_material)
				_add_hair_capsule("TwinTail", Vector3(0.17 * side, 0.02, 0.11), 0.035, 0.38, hair_material)
		"bun", "topknot":
			_add_hair_sphere("HairBun", Vector3(0.0, 0.25, 0.15), Vector3(0.11, 0.12, 0.10), hair_material)
			if hair_style == "topknot":
				_add_hair_capsule("TopKnotTail", Vector3(0.0, 0.12, 0.18), 0.035, 0.24, hair_material)
		"bob":
			_add_hair_capsule("BobLeft", Vector3(-0.13, 0.12, 0.04), 0.038, 0.25, hair_material)
			_add_hair_capsule("BobRight", Vector3(0.13, 0.12, 0.04), 0.038, 0.25, hair_material)
		"pixie", "undercut":
			_add_hair_capsule("PixieFringe", Vector3(0.0, 0.25, -0.055), 0.035, 0.16, hair_material)
			if hair_style == "undercut":
				_add_hair_capsule("UndercutTop", Vector3(0.0, 0.31, 0.02), 0.045, 0.18, hair_material)
		"spiky":
			for x in [-0.10, -0.05, 0.0, 0.05, 0.10]:
				_add_hair_capsule("SpikyLock", Vector3(x, 0.31, 0.0), 0.022, 0.18, hair_material)
		"side_swept":
			_add_hair_capsule("SideSweptFringe", Vector3(-0.04, 0.25, -0.07), 0.035, 0.22, hair_material)

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
		"face_shape": str(appearance_profile.get("face_shape", "balanced")),
		"skin_tone": str(appearance_profile.get("skin_tone", "palette")),
		"hair_color": str(appearance_profile.get("hair_color", "palette")),
		"hair_style": hair_style,
		"hairstyle_mesh_count": hairstyle_mesh_count,
		"eye_color": str(appearance_profile.get("eye_color", "blue")),
		"activity": current_activity
	}

func _collect_skeleton_nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		if child is Skeleton3D:
			result.append(child)
		result.append_array(_collect_skeleton_nodes(child))
	return result
