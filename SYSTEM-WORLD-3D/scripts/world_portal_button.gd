
extends Button
class_name WorldPortalButton

const WorldData = preload("res://scripts/world_data.gd")

signal world_selected(world_id: String)

@export var world_id: String = "modern"
@export var accent_color: Color = Color(0.0, 0.75, 1.0)

var is_configured: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)

	if not is_configured:
		refresh_button()


func configure(world: Dictionary, selected: bool = false) -> void:
	var normalized_id := WorldData.normalize_world_id(
		str(world.get("id", ""))
	)

	if normalized_id.is_empty():
		push_warning("Invalid SYSTEM WORLD ID")
		return

	world_id = normalized_id

	var world_color = world.get("color", accent_color)
	if world_color is Color:
		accent_color = world_color

	var icon := str(world.get("icon", ""))
	var title := str(world.get("title", "World"))
	var subtitle := str(world.get("subtitle", ""))

	text = icon + "   " + title + "\n" + subtitle
	tooltip_text = title

	is_configured = true
	set_selected(selected)


func refresh_button() -> void:
	var world := WorldData.get_world(world_id)

	if world.is_empty():
		text = "عالم غير معروف"
		return

	text = str(world.get("title", "World"))
	tooltip_text = text


func set_selected(selected: bool) -> void:
	var background := Color(0.035, 0.09, 0.15, 0.97)

	if selected:
		background = Color(0.08, 0.22, 0.30, 1.0)

	var normal_style := _make_style(background)
	var hover_style := _make_style(
		Color(0.08, 0.18, 0.26, 1.0)
	)

	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", normal_style)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_hover_color", Color.WHITE)


func _make_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background
	style.border_color = accent_color
	style.set_border_width_all(2)

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	return style


func _on_pressed() -> void:
	world_selected.emit(world_id)
