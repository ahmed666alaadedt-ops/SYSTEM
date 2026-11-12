
extends Button
class_name WorldPortalButton

const WorldData = preload("res://scripts/world_data.gd")

signal world_selected(world_id: String)

@export var world_id: String = "modern"
@export var accent_color: Color = Color(0.0, 0.75, 1.0)

func _ready() -> void:
	pressed.connect(_on_pressed)
	refresh_button()


func configure(world: Dictionary, selected: bool = false) -> void:
	var normalized_id := WorldData.normalize_world_id(
		str(world.get("id", ""))
	)

	if normalized_id.is_empty():
		push_warning("Invalid SYSTEM WORLD ID")
		return

	world_id = normalized_id
	accent_color = world.get("color", accent_color)

	var icon := str(world.get("icon", ""))
	var title := str(world.get("title", "World"))
	var subtitle := str(world.get("subtitle", ""))

	text = icon + "   " + title + "\n" + subtitle
	tooltip_text = title

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

	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent_color
	style.set_border_width_all(2)

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_color_override("font_color", Color.WHITE)


func _on_pressed() -> void:
	world_selected.emit(world_id)
