extends Node
class_name SYSTEMCinematicQualityManager

## Adaptive anti-aliasing and frame pacing for the cinematic 3D world.
## Keeps the Android profile sharp without forcing expensive desktop-only effects.

var active_profile := "balanced_high"
var applied_viewport: Viewport


func _ready() -> void:
	name = "SYSTEMCinematicQualityManager"
	_apply_quality_profile()
	set_meta("system_cinematic_quality_manager", true)


func _apply_quality_profile() -> void:
	applied_viewport = get_viewport()
	if applied_viewport == null:
		push_warning("SYSTEM Quality: viewport unavailable; keeping engine defaults.")
		return

	var is_mobile := OS.has_feature("mobile")
	if is_mobile:
		active_profile = "mobile_high"
		applied_viewport.msaa_3d = Viewport.MSAA_2X
		applied_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		applied_viewport.scaling_3d_scale = 1.0
		Engine.max_fps = 60
	else:
		active_profile = "cinematic_ultra"
		applied_viewport.msaa_3d = Viewport.MSAA_4X
		applied_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		applied_viewport.scaling_3d_scale = 1.0
		Engine.max_fps = 120

	applied_viewport.use_debanding = true
	set_meta("system_cinematic_quality_profile", active_profile)
	set_meta("system_msaa_3d", int(applied_viewport.msaa_3d))
	set_meta("system_render_scale", applied_viewport.scaling_3d_scale)
	print("SYSTEM WORLD: cinematic quality profile = ", active_profile,
		", MSAA = ", applied_viewport.msaa_3d,
		", render scale = ", applied_viewport.scaling_3d_scale)


func get_quality_report() -> Dictionary:
	return {
		"profile": active_profile,
		"msaa_3d": int(applied_viewport.msaa_3d) if is_instance_valid(applied_viewport) else -1,
		"screen_space_aa": int(applied_viewport.screen_space_aa) if is_instance_valid(applied_viewport) else -1,
		"render_scale": applied_viewport.scaling_3d_scale if is_instance_valid(applied_viewport) else 0.0,
		"debanding": applied_viewport.use_debanding if is_instance_valid(applied_viewport) else false
	}
