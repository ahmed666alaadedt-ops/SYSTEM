extends Node3D
class_name SYSTEMPortal3D

@export var portal_name: String = "SYSTEM GATE"
@export var portal_color: Color = Color(0.08, 0.75, 1.0)
@export_range(0.5, 3.0) var portal_radius: float = 1.25
@export_range(0.5, 5.0) var glow_strength: float = 2.5

var portal_light: OmniLight3D
var portal_ring: MeshInstance3D
var energy_surface: MeshInstance3D
var pulse_time: float = 0.0


func _ready() -> void:
    create_portal_frame()
    create_energy_core()
    create_portal_lighting()
    create_portal_label()


func create_portal_frame() -> void:
    portal_ring = MeshInstance3D.new()
    portal_ring.name = "Portal_Ring"

    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = portal_radius - 0.12
    ring_mesh.outer_radius = portal_radius + 0.12
    ring_mesh.rings = 64
    ring_mesh.ring_segments = 16

    portal_ring.mesh = ring_mesh
    portal_ring.position.y = 1.55
    portal_ring.rotation.x = deg_to_rad(90)

    var ring_material := StandardMaterial3D.new()
    ring_material.albedo_color = portal_color
    ring_material.metallic = 0.8
    ring_material.roughness = 0.2
    ring_material.emission_enabled = true
    ring_material.emission = portal_color
    ring_material.emission_energy_multiplier = glow_strength

    portal_ring.material_override = ring_material
    add_child(portal_ring)

    create_side_pillar(-1.48)
    create_side_pillar(1.48)
    create_base()


func create_side_pillar(side: float) -> void:
    var pillar := MeshInstance3D.new()
    pillar.name = "Portal_Pillar"

    var pillar_mesh := BoxMesh.new()
    pillar_mesh.size = Vector3(0.24, 2.9, 0.28)

    pillar.mesh = pillar_mesh
    pillar.position = Vector3(side, 1.45, 0.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.16, 0.22)
    material.metallic = 0.7
    material.roughness = 0.3

    pillar.material_override = material
    add_child(pillar)


func create_base() -> void:
    var base := MeshInstance3D.new()
    base.name = "Portal_Base"

    var base_mesh := BoxMesh.new()
    base_mesh.size = Vector3(3.5, 0.22, 0.65)

    base.mesh = base_mesh
    base.position.y = 0.11

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.09, 0.12, 0.17)
    material.metallic = 0.75
    material.roughness = 0.35

    base.material_override = material
    add_child(base)


func create_energy_core() -> void:
    energy_surface = MeshInstance3D.new()
    energy_surface.name = "Portal_Energy"

    var plane := PlaneMesh.new()
    plane.size = Vector2(
        portal_radius * 2.0,
        portal_radius * 2.0
    )

    energy_surface.mesh = plane
    energy_surface.position = Vector3(0, 1.55, -0.04)

    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 portal_tint : source_color;
uniform float glow_power = 2.5;

void fragment() {
    vec2 centered = UV * 2.0 - 1.0;
    float radius = length(centered);
    float angle = atan(centered.y, centered.x);

    float wave = sin(angle * 8.0 + radius * 22.0 - TIME * 2.4);
    float spiral = sin(angle * 5.0 - radius * 30.0 + TIME * 1.8);

    float pulse = 0.65 + 0.25 * sin(TIME * 2.0);
    float edge = 1.0 - smoothstep(0.82, 1.0, radius);

    vec3 color = portal_tint.rgb;
    color *= 0.65 + wave * 0.16 + spiral * 0.12;
    color *= pulse;

    ALBEDO = color;
    EMISSION = color * glow_power;
    ALPHA = edge * 0.82;
}
"""

    var shader_material := ShaderMaterial.new()
    shader_material.shader = shader
    shader_material.set_shader_parameter(
        "portal_tint",
        Color(portal_color.r, portal_color.g, portal_color.b, 1.0)
    )
    shader_material.set_shader_parameter("glow_power", glow_strength)

    energy_surface.material_override = shader_material
    add_child(energy_surface)


func create_portal_lighting() -> void:
    portal_light = OmniLight3D.new()
    portal_light.name = "Portal_Glow"

    portal_light.position = Vector3(0, 1.6, 0.5)
    portal_light.light_color = portal_color
    portal_light.light_energy = 2.0
    portal_light.omni_range = 7.0

    add_child(portal_light)


func create_portal_label() -> void:
    var label := Label3D.new()
    label.name = "Portal_Name"

    label.text = portal_name
    label.position = Vector3(0, 3.15, 0)
    label.font_size = 48
    label.modulate = portal_color
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.outline_size = 8

    add_child(label)


func _process(delta: float) -> void:
    pulse_time += delta

    if portal_light:
        portal_light.light_energy = (
            1.7 + sin(pulse_time * 2.2) * 0.45
        )

    if portal_ring:
        portal_ring.rotation.z = sin(pulse_time * 0.35) * 0.025
