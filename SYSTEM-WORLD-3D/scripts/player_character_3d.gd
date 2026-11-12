
extends Node3D
class_name SYSTEMPlayerCharacter3D

# SYSTEM WORLD - PLAYER 3D CHARACTER
# Godot 4.3
# Procedural prototype that responds to profile customization.

var profile_data: Dictionary = {
	"name": "الصياد الجديد",
	"appearance": "ذكر",
	"hair_style": "قصير",
	"hair_color": "أسود",
	"face": "متوازن",
	"body": "رياضي",
	"outfit": "الزي الأساسي"
}

var model_root: Node3D


func _ready() -> void:
	apply_profile(profile_data)


func apply_profile(data: Dictionary) -> void:
	profile_data = data.duplicate(true)

	if is_instance_valid(model_root):
		remove_child(model_root)
		model_root.free()

	model_root = Node3D.new()
	model_root.name = "GeneratedPlayerModel"
	add_child(model_root)

	_build_character()


func _build_character() -> void:
	var is_female := str(
		profile_data.get("appearance", "ذكر")
	) == "أنثى"

	var hair_color := _get_hair_color()
	var outfit_color := _get_outfit_color()

	var skin_material := _make_material(
		Color(0.76, 0.56, 0.42)
	)

	var hair_material := _make_material(hair_color)
	var outfit_material := _make_material(outfit_color)

	var dark_material := _make_material(
		Color(0.025, 0.035, 0.055)
	)

	var eye_material := _make_material(
		Color(0.92, 0.95, 1.0)
	)

	# BODY
	var body_scale := Vector3.ONE

	match str(profile_data.get("body", "رياضي")):
		"نحيف":
			body_scale = Vector3(0.82, 1.0, 0.85)
		"متوسط":
			body_scale = Vector3(1.0, 1.0, 1.0)
		"قوي":
			body_scale = Vector3(1.25, 1.05, 1.1)
		_:
			body_scale = Vector3(1.0, 1.0, 0.95)

	_add_capsule(
		"Torso",
		Vector3(0, 1.12, 0),
		0.24 * body_scale.x,
		0.82,
		outfit_material,
		Vector3(body_scale.x, 1.0, body_scale.z)
	)

	# NECK
	_add_capsule(
		"Neck",
		Vector3(0, 1.60, 0),
		0.075,
		0.22,
		skin_material
	)

	# HEAD
	var head := SphereMesh.new()
	head.radius = 0.19
	head.height = 0.38

	var face_scale := Vector3.ONE

	match str(profile_data.get("face", "متوازن")):
		"حاد":
			face_scale = Vector3(0.88, 1.08, 0.95)
		"ناعم":
			face_scale = Vector3(1.05, 1.0, 1.05)
		"عريض":
			face_scale = Vector3(1.16, 0.95, 1.0)

	if is_female:
		face_scale.x *= 0.96

	_add_mesh(
		"Head",
		head,
		skin_material,
		Vector3(0, 1.78, 0),
		face_scale
	)

	# EYES
	_add_sphere(
		"LeftEye",
		Vector3(-0.075, 1.81, -0.17),
		0.025,
		eye_material
	)

	_add_sphere(
		"RightEye",
		Vector3(0.075, 1.81, -0.17),
		0.025,
		eye_material
	)

	# NOSE
	_add_sphere(
		"Nose",
		Vector3(0, 1.75, -0.19),
		0.025,
		skin_material
	)

	# ARMS
	_add_capsule(
		"LeftArm",
		Vector3(-0.32, 1.15, 0),
		0.085,
		0.72,
		skin_material,
		Vector3.ONE,
		Vector3(0, 0, -0.16)
	)

	_add_capsule(
		"RightArm",
		Vector3(0.32, 1.15, 0),
		0.085,
		0.72,
		skin_material,
		Vector3.ONE,
		Vector3(0, 0, 0.16)
	)

	# LEGS
	_add_capsule(
		"LeftLeg",
		Vector3(-0.13, 0.48, 0),
		0.105,
		0.88,
		dark_material
	)

	_add_capsule(
		"RightLeg",
		Vector3(0.13, 0.48, 0),
		0.105,
		0.88,
		dark_material
	)

	# HAIR
	_build_hair(hair_material)

	# OUTFIT DETAIL
	_add_box(
		"ChestDetail",
		Vector3(0, 1.22, -0.235),
		Vector3(0.12, 0.25, 0.025),
		_make_material(Color(0.08, 0.72, 0.95))
	)


func _build_hair(material: Material) -> void:
	var style := str(
		profile_data.get("hair_style", "قصير")
	)

	var cap := SphereMesh.new()
	cap.radius = 0.205
	cap.height = 0.20

	_add_mesh(
		"HairCap",
		cap,
		material,
		Vector3(0, 1.91, 0),
		Vector3(1.0, 0.65, 1.0)
	)

	if style == "طويل" or style == "متوسط":
		var length := 0.38
		if style == "طويل":
			length = 0.65

		_add_capsule(
			"LeftHair",
			Vector3(-0.17, 1.72 - length * 0.35, 0.015),
			0.055,
			length,
			material
		)

		_add_capsule(
			"RightHair",
			Vector3(0.17, 1.72 - length * 0.35, 0.015),
			0.055,
			length,
			material
		)

	elif style == "مجعد":
		for i in range(5):
			var x := -0.16 + float(i) * 0.08
			_add_sphere(
				"CurlyHair" + str(i),
				Vector3(x, 1.98, -0.02),
				0.075,
				material
			)

	elif style == "مربوط":
		_add_sphere(
			"TiedHair",
			Vector3(0, 1.78, 0.20),
			0.10,
			material
		)


func _get_hair_color() -> Color:
	match str(profile_data.get("hair_color", "أسود")):
		"بني":
			return Color(0.28, 0.12, 0.055)
		"أشقر":
			return Color(0.85, 0.65, 0.24)
		"أبيض":
			return Color(0.85, 0.88, 0.92)
		"أحمر":
			return Color(0.55, 0.055, 0.035)
		_:
			return Color(0.025, 0.02, 0.025)


func _get_outfit_color() -> Color:
	match str(profile_data.get("outfit", "الزي الأساسي")):
		"زي قتالي":
			return Color(0.35, 0.055, 0.045)
		"زي مغامر":
			return Color(0.30, 0.19, 0.09)
		"ملابس يومية":
			return Color(0.18, 0.20, 0.25)
		_:
			return Color(0.035, 0.10, 0.19)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	return material


func _add_mesh(
	part_name: String,
	mesh: Mesh,
	material: Material,
	part_position: Vector3,
	part_scale: Vector3 = Vector3.ONE
) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.material_override = material
	part.position = part_position
	part.scale = part_scale
	model_root.add_child(part)


func _add_capsule(
	part_name: String,
	part_position: Vector3,
	radius: float,
	height: float,
	material: Material,
	part_scale: Vector3 = Vector3.ONE,
	part_rotation: Vector3 = Vector3.ZERO
) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height

	_add_mesh(
		part_name,
		mesh,
		material,
		part_position,
		part_scale
	)

	var part := model_root.get_node_or_null(part_name)
	if part != null:
		part.rotation = part_rotation


func _add_sphere(
	part_name: String,
	part_position: Vector3,
	radius: float,
	material: Material
) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0

	_add_mesh(
		part_name,
		mesh,
		material,
		part_position
	)


func _add_box(
	part_name: String,
	part_position: Vector3,
	box_size: Vector3,
	material: Material
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = box_size

	_add_mesh(
		part_name,
		mesh,
		material,
		part_position
	)
