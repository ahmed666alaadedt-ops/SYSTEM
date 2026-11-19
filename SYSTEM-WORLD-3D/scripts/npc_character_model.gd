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
var face_attachment: BoneAttachment3D
var outfit_attachment: BoneAttachment3D
var face_detail_mesh_count := 0
var job_accessory_mesh_count := 0

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
		var outfit_id := _resolve_outfit_id(profile)
		set_appearance(palette_index)
		set_outfit(outfit_id, palette_index)
		return
	_build_fallback(profile, palette_index)

func _resolve_outfit_id(profile: Dictionary) -> String:
	if age_group == "child":
		return "student" if str(profile.get("job", "")).to_lower() in ["طالب", "طالبة", "student"] else "civilian"
	if age_group == "elder":
		return "elder"
	var job := str(profile.get("job", profile.get("occupation", ""))).to_lower()
	if job in ["حارس", "حارسة", "guard", "soldier", "police"]:
		return "guard"
	if job in ["صياد", "صيادة", "hunter", "guild", "عضو نقابة"]:
		return "hunter"
	if job in ["طبيب", "طبيبة", "doctor", "nurse", "medic"]:
		return "doctor"
	if job in ["خباز", "خبازة", "baker"]:
		return "baker"
	if job in ["مزارع", "مزارعة", "farmer"]:
		return "farmer"
	if job in ["نجار", "نجارة", "carpenter"]:
		return "carpenter"
	if job in ["تاجر", "تاجرة", "merchant", "trader"]:
		return "merchant"
	if job in ["نبيل", "نبيلة", "royal", "noble"]:
		return "royal"
	return "civilian"


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
	hair_color = _resolve_hair_color(str(appearance_profile.get("hair_color", "black")))
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
		_apply_face_details(skeleton, skin_color)
		_apply_profession_accessories(skeleton)
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

func _make_bone_attachment(skeleton: Skeleton3D, bone_name: String, attachment_name: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = attachment_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	return attachment


func _apply_face_details(skeleton: Skeleton3D, skin_color: Color) -> void:
	if is_instance_valid(face_attachment):
		face_attachment.queue_free()
	face_detail_mesh_count = 0
	face_attachment = _make_bone_attachment(skeleton, "head", "RuntimeFaceDetails")
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color8(42, 27, 23)
	dark.roughness = 0.9
	var skin := StandardMaterial3D.new()
	skin.albedo_color = skin_color
	skin.roughness = 0.82
	var face_shape := str(appearance_profile.get("face", "متوازن"))
	var brow_width := 0.062
	if face_shape == "عريض":
		brow_width = 0.075
	elif face_shape == "حاد":
		brow_width = 0.055
	_add_face_capsule("LeftEyebrowDetail", Vector3(-0.075, 0.125, -0.128), Vector3(-0.018, 0.135, -0.137), 0.009, dark)
	_add_face_capsule("RightEyebrowDetail", Vector3(0.018, 0.135, -0.137), Vector3(0.075, 0.125, -0.128), 0.009, dark)
	var cheek_size := Vector3(0.045, 0.035, 0.022)
	if face_shape == "ناعم":
		cheek_size = Vector3(0.052, 0.042, 0.025)
	elif face_shape == "حاد":
		cheek_size = Vector3(0.038, 0.03, 0.02)
	_add_face_sphere("LeftCheekContour", Vector3(-0.09, -0.005, -0.105), cheek_size, skin)
	_add_face_sphere("RightCheekContour", Vector3(0.09, -0.005, -0.105), cheek_size, skin)
	var gender := str(appearance_profile.get("gender", appearance_profile.get("appearance", ""))).to_lower()
	var is_male := gender in ["male", "man", "ذكر", "رجل", "ولد"]
	if age_group == "elder":
		for side in [-1.0, 1.0]:
			_add_face_capsule("AgeSmileLine", Vector3(side * 0.055, -0.015, -0.132), Vector3(side * 0.09, -0.045, -0.115), 0.0035, dark)
			_add_face_capsule("ForeheadWrinkle", Vector3(-0.045, 0.17, -0.105), Vector3(0.045, 0.17, -0.105), 0.003, dark)
		if is_male:
			_add_face_sphere("ElderBeard", Vector3(0.0, -0.105, -0.105), Vector3(0.085, 0.065, 0.055), dark)
			_add_face_capsule("ElderMoustache", Vector3(-0.045, -0.055, -0.145), Vector3(0.045, -0.055, -0.145), 0.012, dark)
	face_detail_mesh_count = face_attachment.get_child_count()


func _add_face_sphere(piece_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = dimensions
	instance.material_override = mat
	face_attachment.add_child(instance)


func _add_face_capsule(piece_name: String, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = from.distance_to(to) + radius * 2.0
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = (from + to) * 0.5
	instance.material_override = mat
	instance.look_at(instance.position + (to - from).normalized(), Vector3.UP)
	face_attachment.add_child(instance)


func _apply_profession_accessories(skeleton: Skeleton3D) -> void:
	if is_instance_valid(outfit_attachment):
		outfit_attachment.queue_free()
	job_accessory_mesh_count = 0
	outfit_attachment = _make_bone_attachment(skeleton, "chest", "ProfessionAccessories")
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color8(188, 145, 65)
	gold.metallic = 0.35
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color8(35, 42, 48)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color8(220, 226, 225)
	var job := str(appearance_profile.get("job", "")).to_lower()
	match _resolve_outfit_id(appearance_profile):
		"doctor":
			_add_outfit_capsule("StethoscopeLeft", Vector3(-0.09, 0.12, -0.17), Vector3(-0.07, -0.12, -0.18), 0.012, dark)
			_add_outfit_capsule("StethoscopeRight", Vector3(0.09, 0.12, -0.17), Vector3(0.07, -0.12, -0.18), 0.012, dark)
			_add_outfit_sphere("StethoscopeChest", Vector3(0.0, -0.13, -0.19), Vector3(0.035, 0.035, 0.018), gold)
			_add_outfit_box("MedicalBadge", Vector3(0.14, 0.02, -0.16), Vector3(0.07, 0.08, 0.018), white)
		"baker":
			_add_outfit_box("BakerApron", Vector3(0.0, -0.20, -0.17), Vector3(0.28, 0.34, 0.025), white)
		"guard":
			_add_outfit_box("GuardChestBadge", Vector3(0.14, 0.04, -0.17), Vector3(0.075, 0.09, 0.025), gold)
			_add_outfit_sphere("GuardShoulderMark", Vector3(-0.22, 0.17, 0.0), Vector3(0.09, 0.055, 0.08), gold)
		"hunter":
			_add_outfit_box("HunterGuildInsignia", Vector3(0.14, 0.06, -0.17), Vector3(0.09, 0.09, 0.025), gold)
			_add_outfit_box("HunterUtilityStrap", Vector3(-0.12, -0.19, -0.17), Vector3(0.07, 0.22, 0.025), dark)
		"farmer":
			_add_outfit_box("FarmerFieldPouch", Vector3(0.19, -0.18, -0.11), Vector3(0.10, 0.13, 0.09), dark)
		"carpenter":
			_add_outfit_box("CarpenterToolBelt", Vector3(0.0, -0.30, -0.15), Vector3(0.34, 0.07, 0.05), gold)
			_add_outfit_capsule("CarpenterHammerHandle", Vector3(0.19, -0.28, -0.19), Vector3(0.19, -0.12, -0.19), 0.018, dark)
		"merchant":
			_add_outfit_box("MerchantSash", Vector3(0.0, 0.02, -0.16), Vector3(0.10, 0.40, 0.025), gold)
		"student":
			_add_outfit_box("StudentBackpack", Vector3(0.0, -0.12, 0.13), Vector3(0.25, 0.28, 0.11), dark)
	job_accessory_mesh_count = outfit_attachment.get_child_count()


func _add_outfit_box(piece_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = mat
	outfit_attachment.add_child(instance)


func _add_outfit_sphere(piece_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = dimensions
	instance.material_override = mat
	outfit_attachment.add_child(instance)


func _add_outfit_capsule(piece_name: String, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = from.distance_to(to) + radius * 2.0
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = (from + to) * 0.5
	instance.material_override = mat
	instance.look_at(instance.position + (to - from).normalized(), Vector3.UP)
	outfit_attachment.add_child(instance)


func _normalize_hair_style(value: String) -> String:
	var style := value.to_lower().strip_edges().replace("-", "_").replace(" ", "_")
	match style:
		"متوسط", "medium", "shoulder_length":
			return "medium"
		"طويل", "طويل_جدا", "long", "very_long":
			return "long"
		"مجعد", "كيرلي", "curly":
			return "curly"
		"ضفيرة", "مضفور", "braided", "braid":
			return "braided"
		"ذيل_حصان", "مربوط", "pony_tail", "ponytail":
			return "ponytail"
		"كعكة", "bun":
			return "bun"
		"بوب", "bob":
			return "bob"
		"بيكسي", "pixie":
			return "pixie"
		"مدرج", "layered":
			return "layered"
		"مرفوع", "topknot", "man_bun":
			return "topknot"
		"افرو", "أفرو", "afro":
			return "afro"
		"دريدلوك", "ضفائر_رفيعة", "dreadlocks":
			return "dreadlocks"
		"شعرتان", "ضفيرتان", "twin_tails":
			return "twin_tails"
		"شائك", "spiky":
			return "spiky"
		"جانبي", "side_swept":
			return "side_swept"
		"محلوق_الجوانب", "undercut":
			return "undercut"
		_:
			return "short"

func _resolve_hair_color(value: String = "") -> Color:
	var color_id := value.to_lower().strip_edges()
	match color_id:
		"أسود", "اسود", "black":
			return Color8(28, 22, 20)
		"بني", "brown", "chestnut":
			return Color8(92, 52, 30)
		"أشقر", "اشقر", "blonde", "golden_blonde", "yellow", "أصفر", "اصفر":
			return Color8(220, 184, 72)
		"أبيض", "ابيض", "white", "silver", "فضي":
			return Color8(215, 218, 220)
		"رمادي", "gray", "grey", "ash":
			return Color8(112, 119, 128)
		"أحمر", "احمر", "red", "crimson":
			return Color8(178, 35, 42)
		"أزرق", "ازرق", "blue", "electric_blue":
			return Color8(35, 105, 220)
		"أزرق_داكن", "navy", "dark_blue":
			return Color8(24, 45, 112)
		"سماوي", "cyan", "turquoise":
			return Color8(38, 190, 205)
		"بنفسجي", "purple", "violet":
			return Color8(132, 62, 190)
		"وردي", "pink", "rose":
			return Color8(230, 92, 158)
		"أخضر", "اخضر", "green", "emerald":
			return Color8(45, 145, 82)
		"برتقالي", "orange", "ginger":
			return Color8(220, 104, 38)
		"ذهبي", "gold":
			return Color8(224, 176, 55)
		"أرجواني", "magenta":
			return Color8(190, 45, 160)
		_:
			return Color8(35, 22, 17)

func set_hair_color(color_id: String) -> void:
	appearance_profile["hair_color"] = color_id
	if is_instance_valid(fallback_model) and fallback_model.has_method("set_hair_color"):
		fallback_model.call("set_hair_color", color_id)
		return
	var selected_color := _resolve_hair_color(color_id)
	var target_meshes: Array[Node] = _collect_mesh_nodes(imported_model) if is_instance_valid(imported_model) else []
	for node in target_meshes:
		var mesh_node := node as MeshInstance3D
		if "hair" in mesh_node.name.to_lower() or "brow" in mesh_node.name.to_lower() or "beard" in mesh_node.name.to_lower() or "mustache" in mesh_node.name.to_lower():
			var material := StandardMaterial3D.new()
			material.albedo_color = selected_color
			material.roughness = 0.84
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
func set_outfit(outfit_id: String, variant_index: int = 0) -> void:
	if not is_instance_valid(imported_model):
		return
	var palettes := {
		"civilian": [Color8(54, 82, 92), Color8(86, 68, 48), Color8(72, 78, 83), Color8(48, 76, 62)],
		"hunter": [Color8(20, 48, 82), Color8(30, 64, 82), Color8(36, 42, 68), Color8(62, 54, 36)],
		"guard": [Color8(72, 42, 28), Color8(46, 58, 72), Color8(72, 62, 34), Color8(42, 66, 54)],
		"royal": [Color8(86, 54, 104), Color8(105, 74, 34), Color8(44, 62, 104), Color8(92, 42, 54)],
		"doctor": [Color8(205, 218, 220), Color8(224, 230, 226), Color8(185, 207, 210), Color8(220, 224, 216)],
		"baker": [Color8(130, 92, 58), Color8(164, 130, 88), Color8(112, 82, 58), Color8(150, 112, 72)],
		"farmer": [Color8(58, 92, 55), Color8(88, 104, 55), Color8(78, 88, 48), Color8(64, 98, 72)],
		"carpenter": [Color8(92, 64, 42), Color8(112, 78, 48), Color8(72, 58, 45), Color8(102, 76, 52)],
		"merchant": [Color8(92, 48, 78), Color8(72, 62, 112), Color8(118, 78, 42), Color8(52, 82, 102)],
		"student": [Color8(42, 68, 104), Color8(62, 82, 116), Color8(48, 74, 92), Color8(72, 84, 105)],
		"elder": [Color8(88, 82, 72), Color8(72, 78, 82), Color8(104, 88, 72), Color8(76, 82, 68)]
	}
	var choices: Array = palettes.get(outfit_id.to_lower(), palettes["civilian"])
	var cloth_color: Color = choices[posmod(variant_index, choices.size())]
	var regional_accent := _city_accent_color()
	for node in _collect_mesh_nodes(imported_model):
		var mesh_node := node as MeshInstance3D
		var part_name := mesh_node.name.to_lower()
		var tint := Color.TRANSPARENT
		if "jacket" in part_name or "sleeve" in part_name:
			tint = cloth_color
		elif "trousers" in part_name:
			tint = cloth_color.darkened(0.48)
		elif "belt" in part_name or "trim" in part_name:
			tint = regional_accent
		elif "boot" in part_name or "glove" in part_name:
			tint = Color8(28, 24, 22)
		if tint.a > 0.0:
			var material := StandardMaterial3D.new()
			material.albedo_color = tint
			material.roughness = 0.78
			mesh_node.material_override = material

func _city_accent_color() -> Color:
	var city := str(appearance_profile.get("city", "بغداد")).to_lower()
	if city in ["بغداد", "البصرة", "الموصل", "أربيل", "iraq", "baghdad"]:
		return Color8(184, 137, 61)
	if city in ["طوكيو", "سيول", "tokyo", "seoul"]:
		return Color8(65, 165, 205)
	if city in ["باريس", "لندن", "paris", "london"]:
		return Color8(154, 166, 184)
	if city in ["نيويورك", "new york"]:
		return Color8(75, 184, 205)
	if city in ["موسكو", "moscow"]:
		return Color8(160, 92, 72)
	return Color8(156, 130, 82)


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
		"age_group": age_group,
		"body_type": body_type,
		"height_type": height_type,
		"hair_style": hair_style,
		"hair_color": str(appearance_profile.get("hair_color", "black")),
		"hairstyle_mesh_count": hairstyle_mesh_count,
		"face_detail_mesh_count": face_detail_mesh_count,
		"job_accessory_mesh_count": job_accessory_mesh_count,
		"outfit_id": _resolve_outfit_id(appearance_profile),
		"city": str(appearance_profile.get("city", "بغداد")),
		"culture": str(appearance_profile.get("culture", "عراقية")),
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
