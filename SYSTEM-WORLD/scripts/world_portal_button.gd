
extends Button
class_name WorldPortalButton

signal world_selected(world_id: String)

@export_enum(
	"العالم الحديث:modern",
	"العالم التاريخي:historical",
	"العالم الخيالي:fantasy",
	"جزيرة الطمع:greed_island"
)
var world_id: String = "modern"

@export var portal_color: Color = Color(0.1, 0.8, 1.0, 1.0)

func _ready() -> void:
	text = _get_world_name()
	tooltip_text = "الدخول إلى " + text

	custom_minimum_size = Vector2(180, 70)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	add_theme_color_override(
		"font_hover_color",
		portal_color
	)

	add_theme_color_override(
		"font_pressed_color",
		portal_color
	)

	if not pressed.is_connected(_on_portal_pressed):
		pressed.connect(_on_portal_pressed)


func _get_world_name() -> String:
	match world_id:
		"modern":
			return "العالم الحديث"

		"historical":
			return "العالم التاريخي"

		"fantasy":
			return "العالم الخيالي"

		"greed_island":
			return "جزيرة الطمع"

		_:
			return "عالم غير محدد"


func _on_portal_pressed() -> void:
	print("SYSTEM WORLD: تم اختيار ", world_id)
	world_selected.emit(world_id)


func set_world(new_world_id: String) -> void:
	world_id = new_world_id
	text = _get_world_name()
	tooltip_text = "الدخول إلى " + text
