extends Node3D

## Independent Power Tower challenge arena blockout.
## It is intentionally not part of the five-tower district or its skybridges.

const ARENA_RADIUS := 30.0
const ARENA_CENTER := Vector3(0.0, 0.0, 92.0)
var arena_floor_material: StandardMaterial3D
var arena_trim_material: StandardMaterial3D
var arena_light_material: StandardMaterial3D

func _ready() -> void:
	name = "PowerTowerArenaVenue"
	_create_materials()
	_build_arena_floor()
	_build_fighting_ring()
	_build_spectator_bowls()
	_build_lighting_and_signage()
	_build_arena_entry_interaction()
	set_meta("independent_power_tower_venue", true)
	set_meta("challenge_arena_blockout", true)

func get_arena_entry_position() -> Vector3:
	return to_global(ARENA_CENTER + Vector3(0.0, 1.5, 18.0))

func get_arena_center() -> Vector3:
	return to_global(ARENA_CENTER + Vector3.UP * 1.0)

func _create_materials() -> void:
	arena_floor_material = _material(Color(0.10, 0.12, 0.15), 0.86, 0.16)
	arena_trim_material = _material(Color(0.82, 0.48, 0.16), 0.32, 0.72)
	arena_light_material = _material(Color(0.08, 0.55, 0.82), 0.25, 0.35)
	arena_light_material.emission_enabled = true
	arena_light_material.emission = Color(0.02, 0.35, 0.75)
	arena_light_material.emission_energy_multiplier = 1.5

func _build_arena_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "PowerArenaFloorCollision"
	floor_body.position = ARENA_CENTER + Vector3.DOWN * 0.45
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = ARENA_RADIUS
	floor_mesh.bottom_radius = ARENA_RADIUS
	floor_mesh.height = 0.9
	var visual := MeshInstance3D.new()
	visual.name = "CombatArenaFloor"
	visual.mesh = floor_mesh
	visual.material_override = arena_floor_material
	floor_body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = ARENA_RADIUS
	shape.height = 0.9
	collision.shape = shape
	floor_body.add_child(collision)
	add_child(floor_body)
	for ring_index in range(3):
		var ring := MeshInstance3D.new()
		ring.name = "ArenaFloorMarking_%d" % ring_index
		var torus := TorusMesh.new()
		torus.inner_radius = 0.18
		torus.outer_radius = 0.28
		torus.rings = 8
		torus.ring_segments = 64
		torus.material = arena_trim_material if ring_index == 0 else arena_light_material
		ring.mesh = torus
		ring.position = ARENA_CENTER + Vector3.UP * 0.08
		ring.scale = Vector3(0.45 + float(ring_index) * 0.22, 1.0, 0.45 + float(ring_index) * 0.22)
		add_child(ring)

func _build_fighting_ring() -> void:
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var post_position := ARENA_CENTER + Vector3(cos(angle) * (ARENA_RADIUS + 1.2), 2.2, sin(angle) * (ARENA_RADIUS + 1.2))
		_add_box("ArenaBoundaryPost_%02d" % index, post_position, Vector3(0.9, 4.4, 0.9), arena_trim_material, false)
	for rope_level in range(3):
		var rope := MeshInstance3D.new()
		rope.name = "ArenaBoundaryRail_%d" % rope_level
		var mesh := TorusMesh.new()
		mesh.inner_radius = ARENA_RADIUS + 0.35
		mesh.outer_radius = ARENA_RADIUS + 0.62
		mesh.rings = 8
		mesh.ring_segments = 72
		rope.mesh = mesh
		rope.position = ARENA_CENTER + Vector3.UP * (1.0 + float(rope_level) * 1.2)
		rope.material_override = arena_trim_material if rope_level == 1 else arena_light_material
		add_child(rope)

func _build_spectator_bowls() -> void:
	for side in range(2):
		for row in range(5):
			var tier := MeshInstance3D.new()
			tier.name = "SpectatorStand_%d_%d" % [side, row]
			var mesh := BoxMesh.new()
			mesh.size = Vector3(66.0 - float(row) * 4.0, 1.2, 5.0)
			tier.mesh = mesh
			tier.position = ARENA_CENTER + Vector3(0.0, 2.0 + float(row) * 1.6, (-1.0 if side == 0 else 1.0) * (ARENA_RADIUS + 8.0 + float(row) * 4.0))
			tier.material_override = arena_floor_material
			add_child(tier)

func _build_lighting_and_signage() -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var lamp := OmniLight3D.new()
		lamp.name = "ArenaFloodlight_%d" % index
		lamp.position = ARENA_CENTER + Vector3(cos(angle) * 38.0, 15.0, sin(angle) * 38.0)
		lamp.light_color = Color(1.0, 0.62, 0.30) if index % 2 == 0 else Color(0.18, 0.62, 1.0)
		lamp.light_energy = 2.0
		lamp.omni_range = 34.0
		lamp.shadow_enabled = false
		add_child(lamp)
	var sign := Label3D.new()
	sign.name = "PowerTowerArenaSign"
	sign.text = "POWER TOWER\nCHALLENGE ARENA"
	sign.font_size = 34
	sign.position = ARENA_CENTER + Vector3(0.0, 12.0, -ARENA_RADIUS - 13.0)
	sign.pixel_size = 0.012
	sign.modulate = Color(1.0, 0.73, 0.42)
	add_child(sign)

func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, with_collision: bool) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	add_child(visual)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "_Collision"
		body.position = position
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result

func _build_arena_entry_interaction() -> void:
	var interaction := Area3D.new()
	interaction.name = "PowerTowerArenaInteraction"
	interaction.position = Vector3(0.0, 1.8, ARENA_CENTER.z + ARENA_RADIUS + 12.0)
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_location_id", "power_tower_arena_baghdad")
	interaction.set_meta("system_region_id", "region_baghdad")
	interaction.set_meta("system_display_name", "حلبة برج القوة")
	interaction.set_meta("system_location_type", 5)
	interaction.set_meta("system_interaction_prompt", "دخول حلبة برج القوة — النزالات الاستعراضية")
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 4.5
	collision.shape = shape
	interaction.add_child(collision)
	add_child(interaction)
