extends Node3D
class_name ModernWorldCinematicPresentation

## Lightweight cinematic atmosphere for the modern world.
## Uses one sun light and a restrained sky/fog/glow setup for mobile compatibility.

const SUN_COLOR := Color(1.0, 0.78, 0.58)
const SKY_TOP := Color(0.055, 0.12, 0.23)
const SKY_HORIZON := Color(0.92, 0.48, 0.27)
const AMBIENT_COLOR := Color(0.34, 0.43, 0.58)

var world_environment: WorldEnvironment
var sun_light: DirectionalLight3D


func _ready() -> void:
	name = "ModernWorldCinematicPresentation"
	_create_cinematic_environment()
	_create_cinematic_sun()
	set_meta("system_cinematic_presentation", true)
	set_meta("system_cinematic_profile", "baghdad_golden_hour_filmic")
	set_meta("system_mobile_friendly_light_count", 1)
	print("SYSTEM WORLD: cinematic modern-world atmosphere initialized.")


func _create_cinematic_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.sky_curve = 0.18
	sky_material.sky_energy_multiplier = 0.82
	sky_material.ground_bottom_color = Color(0.075, 0.085, 0.12)
	sky_material.ground_horizon_color = Color(0.42, 0.24, 0.20)
	sky_material.ground_curve = 0.12
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = AMBIENT_COLOR
	environment.ambient_light_energy = 0.72
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 6.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.48
	environment.glow_strength = 0.72
	environment.glow_bloom = 0.035
	environment.glow_hdr_threshold = 1.35
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.78, 0.48, 0.35)
	environment.fog_density = 0.0012
	environment.fog_sky_affect = 0.28
	world_environment = WorldEnvironment.new()
	world_environment.name = "SYSTEMCinematicWorldEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


func _create_cinematic_sun() -> void:
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SYSTEMCinematicGoldenHourSun"
	sun_light.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
	sun_light.light_color = SUN_COLOR
	sun_light.light_energy = 1.18
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_max_distance = 180.0
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun_light.light_angular_distance = 0.7
	sun_light.light_specular = 0.72
	add_child(sun_light)
