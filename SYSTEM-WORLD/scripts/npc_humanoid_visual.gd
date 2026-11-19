extends Node3D
class_name SystemNPCHumanoidVisual

## Procedural humanoid with a real Godot Skeleton3D hierarchy.
## Body pieces are attached to named bones so the full rig can be animated.
## Final production meshes can later replace these generated mesh pieces.

const WALK_FREQUENCY := 7.0
const WALK_SWING := 0.48

var skeleton: Skeleton3D
var bone_ids: Dictionary = {}
var attachments: Dictionary = {}
var outfit_meshes: Array[MeshInstance3D] = []
var body_root: Node3D
var walk_time := 0.0
var walking := false
var activity := "rest"
var outfit_material: StandardMaterial3D
var hair_attachment: BoneAttachment3D
var hair_nodes: Array[MeshInstance3D] = []
var hair_material: StandardMaterial3D
var hair_style := "short"

func _ready() -> void:
	_build_rigged_body()

func configure(profile: Dictionary, palette_index: int = 0) -> void:
	name = "NPCVisual_" + str(profile.get("name", "Resident")).replace(" ", "_")
	activity = str(profile.get("state", "rest"))
	set_activity(activity)
	outfit_material = _material(_outfit_color(palette_index, str(profile.get("job", ""))))
	for part in outfit_meshes:
		if is_instance_valid(part):
			part.material_override = outfit_material
	set_hair_color(str(profile.get("hair_color", "black")))
	set_hair_style(str(profile.get("hair_style", "short")))

func set_hair_color(color_id: String) -> void:
	var color := _hair_color_from_id(color_id)
	hair_material = _material(color)
	if is_instance_valid(hair_attachment):
		for child in hair_attachment.get_children():
			if child is MeshInstance3D and ("HairCap" in child.name or child.name.begins_with("RuntimeHair")):
				child.material_override = hair_material

func _hair_color_from_id(color_id: String) -> Color:
	match color_id.to_lower().strip_edges():
		"black", "أسود", "اسود": return Color8(28, 22, 20)
		"brown", "بني": return Color8(92, 52, 30)
		"blonde", "yellow", "أشقر", "أصفر": return Color8(220, 184, 72)
		"white", "silver", "أبيض", "فضي": return Color8(215, 218, 220)
		"gray", "grey", "رمادي": return Color8(112, 119, 128)
		"red", "أحمر": return Color8(178, 35, 42)
		"blue", "أزرق": return Color8(35, 105, 220)
		"navy", "dark_blue": return Color8(24, 45, 112)
		"cyan", "turquoise", "سماوي": return Color8(38, 190, 205)
		"purple", "violet", "بنفسجي": return Color8(132, 62, 190)
		"pink", "وردي": return Color8(230, 92, 158)
		"green", "أخضر": return Color8(45, 145, 82)
		"orange", "ginger", "برتقالي": return Color8(220, 104, 38)
		"gold", "ذهبي": return Color8(224, 176, 55)
		"magenta", "أرجواني": return Color8(190, 45, 160)
		_: return Color8(28, 22, 20)

func set_hair_style(style_id: String) -> void:
	var style := style_id.to_lower().strip_edges().replace("-", "_").replace(" ", "_")
	match style:
		"long", "طويل", "very_long", "طويل_جدا": hair_style = "long"
		"medium", "متوسط": hair_style = "medium"
		"curly", "مجعد", "كيرلي", "afro", "أفرو": hair_style = "curly"
		"braided", "braid", "ضفيرة", "مضفور": hair_style = "braided"
		"ponytail", "pony_tail", "ذيل_حصان": hair_style = "ponytail"
		"bun", "كعكة": hair_style = "bun"
		"topknot", "man_bun", "مرفوع": hair_style = "topknot"
		"bob", "بوب": hair_style = "bob"
		"pixie", "بيكسي": hair_style = "pixie"
		"spiky", "شائك": hair_style = "spiky"
		"side_swept", "جانبي": hair_style = "side_swept"
		"undercut", "محلوق_الجوانب": hair_style = "undercut"
		"dreadlocks", "دريدلوك": hair_style = "dreadlocks"
		"twin_tails", "ضفيرتان": hair_style = "twin_tails"
		_: hair_style = "short"
	if not is_instance_valid(hair_attachment):
		hair_attachment = _attachment_for_bone("head")
	for part in hair_nodes:
		if is_instance_valid(part):
			part.queue_free()
	hair_nodes.clear()
	if not is_instance_valid(hair_material):
		hair_material = _material(Color8(28, 22, 20))
	match hair_style:
		"long":
			_add_runtime_hair_capsule("RuntimeHairLongLeft", Vector3(-0.15, -0.03, 0.035), 0.035, 0.38)
			_add_runtime_hair_capsule("RuntimeHairLongRight", Vector3(0.15, -0.03, 0.035), 0.035, 0.38)
			_add_runtime_hair_capsule("RuntimeHairLongBack", Vector3(0.0, -0.03, 0.13), 0.045, 0.42)
		"medium", "bob":
			_add_runtime_hair_capsule("RuntimeHairMediumLeft", Vector3(-0.14, 0.08, 0.035), 0.035, 0.25)
			_add_runtime_hair_capsule("RuntimeHairMediumRight", Vector3(0.14, 0.08, 0.035), 0.035, 0.25)
		"curly":
			for x in [-0.13, -0.08, -0.025, 0.035, 0.09, 0.14]:
				_add_runtime_hair_sphere("RuntimeHairCurl", Vector3(x, 0.20, 0.02), Vector3(0.065, 0.065, 0.065))
		"braided", "dreadlocks":
			for side in [-1.0, 1.0] if hair_style == "dreadlocks" else [-1.0]:
				_add_runtime_hair_capsule("RuntimeHairBraid", Vector3(0.14 * side, 0.0, 0.05), 0.028, 0.38)
		"ponytail", "twin_tails":
			var sides: Array = [-1.0, 1.0] if hair_style == "twin_tails" else [0.0]
			for side in sides:
				_add_runtime_hair_capsule("RuntimeHairTail", Vector3(0.17 * side, -0.02, 0.16), 0.04, 0.38)
		"bun", "topknot":
			_add_runtime_hair_sphere("RuntimeHairBun", Vector3(0.0, 0.23, 0.13), Vector3(0.11, 0.12, 0.10))
		"spiky", "pixie", "undercut", "side_swept":
			_add_runtime_hair_capsule("RuntimeHairFringe", Vector3(0.0, 0.22, -0.05), 0.035, 0.20)

func _add_runtime_hair_sphere(piece_name: String, at: Vector3, dimensions: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = dimensions
	instance.material_override = hair_material
	hair_attachment.add_child(instance)
	hair_nodes.append(instance)

func _add_runtime_hair_capsule(piece_name: String, at: Vector3, radius: float, height: float) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.name = piece_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = hair_material
	hair_attachment.add_child(instance)
	hair_nodes.append(instance)

func set_activity(value: String) -> void:
	activity = value
	walking = value in ["work", "eat", "socialize", "wander", "travel", "walk"]
	if not walking:
		_reset_pose()

func _process(delta: float) -> void:
	walk_time += delta * (WALK_FREQUENCY if walking else 1.7)
	if not is_instance_valid(skeleton):
		return
	var swing := sin(walk_time) * (WALK_SWING if walking else 0.018)
	_set_bone_rotation("left_thigh", swing)
	_set_bone_rotation("right_thigh", -swing)
	_set_bone_rotation("left_calf", maxf(0.0, -swing) * 0.85)
	_set_bone_rotation("right_calf", maxf(0.0, swing) * 0.85)
	_set_bone_rotation("left_upper_arm", -swing * 0.68)
	_set_bone_rotation("right_upper_arm", swing * 0.68)
	_set_bone_rotation("left_forearm", -0.08 if walking else 0.0)
	_set_bone_rotation("right_forearm", -0.08 if walking else 0.0)
	_set_bone_rotation("spine", sin(walk_time * 0.5) * 0.018)
	_set_bone_rotation("head", sin(walk_time * 0.7) * 0.012)

func _reset_pose() -> void:
	if not is_instance_valid(skeleton):
		return
	for bone_name in bone_ids.keys():
		skeleton.set_bone_pose_rotation(int(bone_ids[bone_name]), Quaternion.IDENTITY)

func _set_bone_rotation(bone_name: String, angle: float) -> void:
	if not bone_ids.has(bone_name):
		return
	var index := int(bone_ids[bone_name])
	skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, angle))

func _build_rigged_body() -> void:
	body_root = Node3D.new()
	body_root.name = "BodyRoot"
	add_child(body_root)

	skeleton = Skeleton3D.new()
	skeleton.name = "HumanoidSkeleton"
	body_root.add_child(skeleton)
	_create_bone_hierarchy()
	_create_body_parts()

func _create_bone_hierarchy() -> void:
	_add_bone("root", "", Vector3.ZERO)
	_add_bone("pelvis", "root", Vector3(0, 0.91, 0))
	_add_bone("spine", "pelvis", Vector3(0, 0.17, 0))
	_add_bone("chest", "spine", Vector3(0, 0.34, 0))
	_add_bone("neck", "chest", Vector3(0, 0.34, 0))
	_add_bone("head", "neck", Vector3(0, 0.15, 0))

	_add_bone("left_clavicle", "chest", Vector3(-0.22, 0.22, 0))
	_add_bone("left_upper_arm", "left_clavicle", Vector3(-0.09, -0.02, 0))
	_add_bone("left_forearm", "left_upper_arm", Vector3(0, -0.31, 0))
	_add_bone("left_hand", "left_forearm", Vector3(0, -0.28, 0))
	_add_bone("right_clavicle", "chest", Vector3(0.22, 0.22, 0))
	_add_bone("right_upper_arm", "right_clavicle", Vector3(0.09, -0.02, 0))
	_add_bone("right_forearm", "right_upper_arm", Vector3(0, -0.31, 0))
	_add_bone("right_hand", "right_forearm", Vector3(0, -0.28, 0))

	_add_bone("left_thigh", "pelvis", Vector3(-0.12, -0.08, 0))
	_add_bone("left_calf", "left_thigh", Vector3(0, -0.39, 0))
	_add_bone("left_foot", "left_calf", Vector3(0, -0.38, -0.035))
	_add_bone("right_thigh", "pelvis", Vector3(0.12, -0.08, 0))
	_add_bone("right_calf", "right_thigh", Vector3(0, -0.39, 0))
	_add_bone("right_foot", "right_calf", Vector3(0, -0.38, -0.035))

func _add_bone(bone_name: String, parent_name: String, rest_position: Vector3) -> void:
	var index := skeleton.get_bone_count()
	skeleton.add_bone(bone_name)
	bone_ids[bone_name] = index
	if not parent_name.is_empty():
		skeleton.set_bone_parent(index, int(bone_ids[parent_name]))
	skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, rest_position))

func _create_body_parts() -> void:
	var skin := _material(Color(0.72, 0.49, 0.35))
	var hair := _material(Color(0.075, 0.045, 0.035))
	var cloth := _material(Color(0.12, 0.22, 0.34))
	var trim := _material(Color(0.72, 0.52, 0.22))
	var pants := _material(Color(0.075, 0.095, 0.13))
	var shoes := _material(Color(0.035, 0.04, 0.05))
	var eyes := _material(Color(0.025, 0.02, 0.018))
	var mouth := _material(Color(0.25, 0.075, 0.065))

	_add_box("pelvis", "PelvisClothing", Vector3.ZERO, Vector3(0.39, 0.27, 0.25), pants, true)
	_add_capsule("spine", "Abdomen", Vector3(0, 0.14, 0), 0.19, 0.42, cloth, true)
	_add_box("chest", "ChestClothing", Vector3(0, 0.02, 0), Vector3(0.47, 0.40, 0.28), cloth, true)
	_add_box("chest", "ChestTrim", Vector3(0, -0.02, -0.146), Vector3(0.12, 0.32, 0.014), trim, true)
	_add_capsule("neck", "Neck", Vector3(0, 0.015, 0), 0.075, 0.19, skin)
	_add_sphere("head", "Face", Vector3(0, 0.065, 0), Vector3(0.38, 0.46, 0.35), skin)
	_add_sphere("head", "HairCap", Vector3(0, 0.19, 0.018), Vector3(0.395, 0.20, 0.37), hair)
	_add_sphere("head", "LeftEye", Vector3(-0.075, 0.075, -0.166), Vector3(0.035, 0.035, 0.018), eyes)
	_add_sphere("head", "RightEye", Vector3(0.075, 0.075, -0.166), Vector3(0.035, 0.035, 0.018), eyes)
	_add_box("head", "Nose", Vector3(0, 0.025, -0.184), Vector3(0.045, 0.075, 0.055), skin)
	_add_box("head", "Mouth", Vector3(0, -0.045, -0.174), Vector3(0.075, 0.014, 0.012), mouth)
	_add_sphere("head", "LeftEar", Vector3(-0.195, 0.055, 0), Vector3(0.075, 0.11, 0.075), skin)
	_add_sphere("head", "RightEar", Vector3(0.195, 0.055, 0), Vector3(0.075, 0.11, 0.075), skin)

	_add_capsule("left_upper_arm", "LeftSleeve", Vector3(0, -0.15, 0), 0.082, 0.34, cloth, true)
	_add_capsule("left_forearm", "LeftForearm", Vector3(0, -0.14, 0), 0.065, 0.31, skin)
	_add_capsule("left_hand", "LeftHand", Vector3(0, -0.045, 0), 0.052, 0.13, skin)
	_add_capsule("right_upper_arm", "RightSleeve", Vector3(0, -0.15, 0), 0.082, 0.34, cloth, true)
	_add_capsule("right_forearm", "RightForearm", Vector3(0, -0.14, 0), 0.065, 0.31, skin)
	_add_capsule("right_hand", "RightHand", Vector3(0, -0.045, 0), 0.052, 0.13, skin)

	_add_capsule("left_thigh", "LeftTrouserUpper", Vector3(0, -0.18, 0), 0.095, 0.39, pants, true)
	_add_capsule("left_calf", "LeftTrouserLower", Vector3(0, -0.18, 0), 0.078, 0.38, pants, true)
	_add_box("left_foot", "LeftBoot", Vector3(0, -0.015, -0.07), Vector3(0.16, 0.12, 0.27), shoes)
	_add_capsule("right_thigh", "RightTrouserUpper", Vector3(0, -0.18, 0), 0.095, 0.39, pants, true)
	_add_capsule("right_calf", "RightTrouserLower", Vector3(0, -0.18, 0), 0.078, 0.38, pants, true)
	_add_box("right_foot", "RightBoot", Vector3(0, -0.015, -0.07), Vector3(0.16, 0.12, 0.27), shoes)

func _attachment_for_bone(bone_name: String) -> BoneAttachment3D:
	if attachments.has(bone_name):
		return attachments[bone_name]
	var attachment := BoneAttachment3D.new()
	attachment.name = bone_name.capitalize() + "Attachment"
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	attachments[bone_name] = attachment
	return attachment

func _add_box(bone_name: String, node_name: String, at: Vector3, dimensions: Vector3, mat: Material, is_clothing: bool = false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_add_mesh(bone_name, node_name, mesh, at, mat, Vector3.ONE, is_clothing)

func _add_capsule(bone_name: String, node_name: String, at: Vector3, radius: float, height: float, mat: Material, is_clothing: bool = false) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	_add_mesh(bone_name, node_name, mesh, at, mat, Vector3.ONE, is_clothing)

func _add_sphere(bone_name: String, node_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	_add_mesh(bone_name, node_name, mesh, at, mat, dimensions)

func _add_mesh(bone_name: String, node_name: String, mesh: Mesh, at: Vector3, mat: Material, scale_value: Vector3 = Vector3.ONE, is_clothing: bool = false) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = scale_value
	instance.material_override = mat
	_attachment_for_bone(bone_name).add_child(instance)
	if is_clothing:
		outfit_meshes.append(instance)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat

func get_skeleton_status() -> Dictionary:
	return {
		"has_skeleton": is_instance_valid(skeleton),
		"bone_count": skeleton.get_bone_count() if is_instance_valid(skeleton) else 0,
		"bones": bone_ids.keys(),
		"rig_type": "procedural_hierarchical_bone_attachments",
		"skinned_mesh_deformation": false
	}

func _outfit_color(index: int, occupation: String) -> Color:
	match occupation:
		"طبيبة", "طبيب": return Color(0.78, 0.82, 0.86)
		"حارس": return Color(0.12, 0.18, 0.27)
		"مزارعة": return Color(0.20, 0.34, 0.18)
		"خباز": return Color(0.48, 0.29, 0.15)
		"تاجرة": return Color(0.34, 0.16, 0.28)
		"نجار": return Color(0.38, 0.25, 0.13)
		_: return Color.from_hsv(fposmod(float(index) * 0.137, 1.0), 0.48, 0.68)
