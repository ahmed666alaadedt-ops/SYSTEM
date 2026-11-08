
extends Node3D
class_name Assistant3DStage

# SYSTEM WORLD - Assistant 3D Stage
# Godot 4.3

@export var platform_radius: float = 2.5
@export var platform_height: float = 0.18
@export var assistant_height: float = 0.0
@export var create_procedural_avatars: bool = true

var platform: MeshInstance3D
var outer_ring: MeshInstance3D
var inner_ring: MeshInstance3D
var character_anchor: Marker3D
var party_display_anchor: Marker3D
var camera_target: Marker3D

var active_character: Node3D
var active_assistant_id: String = "miyar"

var _built_characters: Dictionary = {}


func _ready() -> void:
	_build_stage()


func _process(delta: float) -> void:
	if is_instance_valid(outer_ring):
		outer_ring.rotate_y(delta * 0.12)

	if is_instance_valid(inner_ring):
		inner_ring.rotate_y(-delta * 0.2)


func _build_stage() -> void:
	_create_platform()
	_create_rings()
	_create_lighting()
	_create_markers()


func _create_platform() -> void:
	platform = MeshInstance3D.new()
	platform.name = "AssistantPlatform"

	var mesh := CylinderMesh.new()
	mesh.top_radius = platform_radius
	mesh.bottom_radius = platform_radius
	mesh.height = platform_height
	mesh.radial_segments = 64

	platform.mesh = mesh
	platform.position.y = platform_height * 0.5
	platform.material_override = _make_material(
		Color(0.025, 0.07, 0.12),
		Color(0.0, 0.55, 0.95),
		0.8
	)

	add_child(platform)


func _create_rings() -> void:
	outer_ring = MeshInstance3D.new()
	outer_ring.name = "OuterEnergyRing"

	var outer_mesh := TorusMesh.new()
	outer_mesh.inner_radius = platform_radius - 0.12
	outer_mesh.outer_radius = platform_radius - 0.04
	outer_mesh.rings = 12
	outer_mesh.ring_segments = 64

	outer_ring.mesh = outer_mesh
	outer_ring.position.y = platform_height + 0.03
	outer_ring.material_override = _make_material(
		Color(0.0, 0.4, 0.8),
		Color(0.0, 0.75, 1.0),
		2.0
	)
	add_child(outer_ring)

	inner_ring = MeshInstance3D.new()
	inner_ring.name = "InnerEnergyRing"

	var inner_mesh := TorusMesh.new()
	inner_mesh.inner_radius = 1.25
	inner_mesh.outer_radius = 1.31
	inner_mesh.rings = 10
	inner_mesh.ring_segments = 48

	inner_ring.mesh = inner_mesh
	inner_ring.position.y = platform_height + 0.06
	inner_ring.material_override = _make_material(
		Color(0.0, 0.35, 0.65),
		Color(0.0, 0.55, 1.0),
		1.4
	)
	add_child(inner_ring)


func _create_lighting() -> void:
	var main_light := OmniLight3D.new()
	main_light.name = "AssistantStageLight"
	main_light.position = Vector3(0, 3.5, 0)
	main_light.light_color = Color(0.25, 0.72, 1.0)
	main_light.light_energy = 2.0
	main_light.omni_range = 9.0
	add_child(main_light)

	var warm_light := OmniLight3D.new()
	warm_light.name = "WarmCharacterLight"
	warm_light.position = Vector3(0, 2.5, 2.0)
	warm_light.light_color = Color(1.0, 0.72, 0.42)
	warm_light.light_energy = 0.8
	warm_light.omni_range = 6.0
	add_child(warm_light)


func _create_markers() -> void:
	character_anchor = Marker3D.new()
	character_anchor.name = "CharacterAnchor"
	character_anchor.position = Vector3(0, assistant_height, -0.35)
	add_child(character_anchor)

	party_display_anchor = Marker3D.new()
	party_display_anchor.name = "PartyDisplayAnchor"
	party_display_anchor.position = Vector3(0, 0, 1.75)
	add_child(party_display_anchor)

	camera_target = Marker3D.new()
	camera_target.name = "AssistantCameraTarget"
	camera_target.position = Vector3(0, 1.65, -0.35)
	add_child(camera_target)


func mount_character(
	character: Node3D,
	assistant_id: String = "miyar"
) -> void:
	if not is_instance_valid(character):
		push_warning("Cannot mount an invalid assistant character.")
		return

	_build_character_visual(character, assistant_id)

	character.global_transform = character_anchor.global_transform
	character.visible = true

	_built_characters[assistant_id] = character
	active_character = character
	active_assistant_id = assistant_id


func set_active_character(
	character: Node3D,
	assistant_id: String
) -> void:
	if not is_instance_valid(character):
		return

	if not _built_characters.has(assistant_id):
		_build_character_visual(character, assistant_id)
		_built_characters[assistant_id] = character

	character.global_transform = character_anchor.global_transform
	character.visible = true

	active_character = character
	active_assistant_id = assistant_id


func clear_active_character() -> void:
	if is_instance_valid(active_character):
		active_character.visible = false

	active_character = null


func get_character_anchor() -> Marker3D:
	return character_anchor


func get_party_display_anchor() -> Marker3D:
	return party_display_anchor


func get_camera_target() -> Marker3D:
	return camera_target


func get_active_character() -> Node3D:
	if is_instance_valid(active_character):
		return active_character

	return null


func _build_character_visual(
	character: Node3D,
	assistant_id: String
) -> void:
	if not create_procedural_avatars:
		return

	var model_root := character.get_node_or_null("CharacterModelRoot") as Node3D

	if model_root == null:
		model_root = Node3D.new()
		model_root.name = "CharacterModelRoot"
		character.add_child(model_root)

	if _contains_mesh(model_root):
		return

	var is_adam := assistant_id == "adam"

	var outfit_color := (
		Color(0.16, 0.22, 0.34)
		if is_adam
		else Color(0.04, 0.28, 0.48)
	)

	var accent_color := (
		Color(0.9, 0.62, 0.25)
		if is_adam
		else Color(0.0, 0.78, 1.0)
	)

	var skin_color := Color(0.78, 0.59, 0.47)
	var hair_color := (
		Color(0.055, 0.045, 0.04)
		if is_adam
		else Color(0.045, 0.035, 0.07)
	)

	_add_capsule(
		model_root, "Body", 0.34, 0.82,
		Vector3(0, 1.12, 0), outfit_color, accent_color
	)

	_add_sphere(
		model_root, "Neck", 0.12,
		Vector3(0, 1.62, 0), skin_color
	)

	_add_sphere(
		model_root, "Head", 0.25,
		Vector3(0, 1.88, 0), skin_color
	)

	_add_sphere(
		model_root, "Hair", 0.265,
		Vector3(0, 2.02, -0.025), hair_color
	)

	_add_capsule(
		model_root, "LeftArm", 0.105, 0.68,
		Vector3(-0.43, 1.17, 0), outfit_color, accent_color,
		Vector3(0, 0, -0.12)
	)

	_add_capsule(
		model_root, "RightArm", 0.105, 0.68,
		Vector3(0.43, 1.17, 0), outfit_color, accent_color,
		Vector3(0, 0, 0.12)
	)

	_add_capsule(
		model_root, "LeftLeg", 0.13, 0.78,
		Vector3(-0.17, 0.42, 0), outfit_color, accent_color
	)

	_add_capsule(
		model_root, "RightLeg", 0.13, 0.78,
		Vector3(0.17, 0.42, 0), outfit_color, accent_color
	)

	_add_sphere(
		model_root, "ChestEmblem", 0.105,
		Vector3(0, 1.28, -0.315), accent_color
	)


func _contains_mesh(root: Node) -> bool:
	for child in root.get_children():
		if child is MeshInstance3D:
			return true

		if _contains_mesh(child):
			return true

	return false


func _add_capsule(
	parent: Node3D,
	object_name: String,
	radius: float,
	height: float,
	at: Vector3,
	base_color: Color,
	glow_color: Color,
	rotation_value: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = object_name

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height

	instance.mesh = mesh
	instance.position = at
	instance.rotation = rotation_value
	instance.material_override = _make_material(
		base_color, glow_color, 0.35
	)

	parent.add_child(instance)
	return instance


func _add_sphere(
	parent: Node3D,
	object_name: String,
	radius: float,
	at: Vector3,
	base_color: Color
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = object_name

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0

	instance.mesh = mesh
	instance.position = at
	instance.material_override = _make_material(
		base_color, Color.BLACK, 0.0
	)

	parent.add_child(instance)
	return instance


func _make_material(
	base_color: Color,
	glow_color: Color,
	glow_strength: float
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.roughness = 0.42

	if glow_strength > 0.0:
		material.emission_enabled = true
		material.emission = glow_color
		material.emission_energy_multiplier = glow_strength

	return material
