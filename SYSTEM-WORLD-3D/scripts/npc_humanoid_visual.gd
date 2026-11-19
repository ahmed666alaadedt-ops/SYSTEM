extends Node3D
class_name SystemNPCHumanoidVisual

## Reusable lightweight 3D civilian body for SYSTEM WORLD.
## Procedural placeholder visual: replaceable later by rigged GLB characters.

var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var body_root: Node3D
var walk_time := 0.0
var walking := false
var activity := "rest"

func _ready() -> void:
	_build_body()

func configure(profile: Dictionary, palette_index: int = 0) -> void:
	name = "NPCVisual_" + str(profile.get("name", "Resident")).replace(" ", "_")
	activity = str(profile.get("state", "rest"))
	set_activity(activity)
	if is_instance_valid(body_root):
		var outfit := _outfit_color(palette_index, str(profile.get("job", "")))
		var clothing := body_root.get_node_or_null("Clothing") as MeshInstance3D
		if clothing:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = outfit
			mat.roughness = 0.82
			clothing.material_override = mat

func set_activity(value: String) -> void:
	activity = value
	walking = value in ["work", "eat", "socialize", "wander", "travel"]
	if not walking:
		_reset_pose()

func _process(delta: float) -> void:
	walk_time += delta * (7.0 if walking else 1.8)
	if is_instance_valid(body_root):
		body_root.position.y = 0.025 * sin(walk_time * (2.0 if walking else 1.0))
		body_root.rotation.z = 0.025 * sin(walk_time * 0.5)
	if walking:
		var swing := sin(walk_time) * 0.48
		if left_arm_pivot: left_arm_pivot.rotation.x = -swing * 0.72
		if right_arm_pivot: right_arm_pivot.rotation.x = swing * 0.72
		if left_leg_pivot: left_leg_pivot.rotation.x = swing
		if right_leg_pivot: right_leg_pivot.rotation.x = -swing
	else:
		var breathe := sin(walk_time) * 0.025
		if left_arm_pivot: left_arm_pivot.rotation.x = breathe
		if right_arm_pivot: right_arm_pivot.rotation.x = -breathe

func _reset_pose() -> void:
	for pivot in [left_arm_pivot, right_arm_pivot, left_leg_pivot, right_leg_pivot]:
		if is_instance_valid(pivot):
			pivot.rotation = Vector3.ZERO

func _build_body() -> void:
	body_root = Node3D.new()
	body_root.name = "BodyRoot"
	add_child(body_root)

	var skin := _material(Color(0.72, 0.49, 0.35))
	var hair := _material(Color(0.075, 0.045, 0.035))
	var cloth := _material(Color(0.12, 0.22, 0.34))
	var trim := _material(Color(0.72, 0.52, 0.22))
	var pants := _material(Color(0.075, 0.095, 0.13))
	var shoes := _material(Color(0.035, 0.04, 0.05))
	var eyes := _material(Color(0.025, 0.02, 0.018))

	_add_box(body_root, "Torso", Vector3(0, 1.12, 0), Vector3(0.48, 0.70, 0.29), cloth)
	_add_box(body_root, "Clothing", Vector3(0, 1.16, -0.153), Vector3(0.30, 0.43, 0.018), trim)
	_add_capsule(body_root, "Neck", Vector3(0, 1.53, 0), 0.075, 0.18, skin)
	_add_sphere(body_root, "Head", Vector3(0, 1.77, 0), Vector3(0.19, 0.23, 0.18), skin)
	_add_sphere(body_root, "Hair", Vector3(0, 1.91, 0.015), Vector3(0.195, 0.105, 0.19), hair)
	_add_sphere(body_root, "LeftEye", Vector3(-0.073, 1.79, -0.164), Vector3(0.023, 0.023, 0.012), eyes)
	_add_sphere(body_root, "RightEye", Vector3(0.073, 1.79, -0.164), Vector3(0.023, 0.023, 0.012), eyes)

	left_arm_pivot = _make_limb_pivot("LeftArmPivot", Vector3(-0.29, 1.42, 0))
	body_root.add_child(left_arm_pivot)
	_add_capsule(left_arm_pivot, "Sleeve", Vector3(0, -0.22, 0), 0.085, 0.52, cloth)
	_add_capsule(left_arm_pivot, "Hand", Vector3(0, -0.53, 0), 0.055, 0.15, skin)

	right_arm_pivot = _make_limb_pivot("RightArmPivot", Vector3(0.29, 1.42, 0))
	body_root.add_child(right_arm_pivot)
	_add_capsule(right_arm_pivot, "Sleeve", Vector3(0, -0.22, 0), 0.085, 0.52, cloth)
	_add_capsule(right_arm_pivot, "Hand", Vector3(0, -0.53, 0), 0.055, 0.15, skin)

	left_leg_pivot = _make_limb_pivot("LeftLegPivot", Vector3(-0.13, 0.78, 0))
	body_root.add_child(left_leg_pivot)
	_add_capsule(left_leg_pivot, "Trouser", Vector3(0, -0.28, 0), 0.095, 0.62, pants)
	_add_box(left_leg_pivot, "Boot", Vector3(0, -0.61, -0.055), Vector3(0.17, 0.12, 0.28), shoes)

	right_leg_pivot = _make_limb_pivot("RightLegPivot", Vector3(0.13, 0.78, 0))
	body_root.add_child(right_leg_pivot)
	_add_capsule(right_leg_pivot, "Trouser", Vector3(0, -0.28, 0), 0.095, 0.62, pants)
	_add_box(right_leg_pivot, "Boot", Vector3(0, -0.61, -0.055), Vector3(0.17, 0.12, 0.28), shoes)

func _make_limb_pivot(node_name: String, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = at
	return pivot

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat

func _add_box(parent: Node3D, node_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_add_mesh(parent, node_name, mesh, at, mat)

func _add_capsule(parent: Node3D, node_name: String, at: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	_add_mesh(parent, node_name, mesh, at, mat)

func _add_sphere(parent: Node3D, node_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	_add_mesh(parent, node_name, mesh, at, mat, dimensions)

func _add_mesh(parent: Node3D, node_name: String, mesh: Mesh, at: Vector3, mat: Material, scale_value: Vector3 = Vector3.ONE) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = scale_value
	instance.material_override = mat
	parent.add_child(instance)

func _outfit_color(index: int, occupation: String) -> Color:
	match occupation:
		"طبيبة", "طبيب": return Color(0.78, 0.82, 0.86)
		"حارس": return Color(0.12, 0.18, 0.27)
		"مزارعة": return Color(0.20, 0.34, 0.18)
		"خباز": return Color(0.48, 0.29, 0.15)
		"تاجرة": return Color(0.34, 0.16, 0.28)
		"نجار": return Color(0.38, 0.25, 0.13)
		_: return Color.from_hsv(fposmod(float(index) * 0.137, 1.0), 0.48, 0.68)
