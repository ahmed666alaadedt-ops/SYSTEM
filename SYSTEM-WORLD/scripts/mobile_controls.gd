extends CanvasLayer
class_name MobileControls

signal movement_changed(direction: Vector2)
signal jump_pressed

var joystick_touch := -1
var joystick_direction := Vector2.ZERO
var joystick_center := Vector2.ZERO
var joystick_radius := 75.0

var jump_touch := -1
var jump_center := Vector2.ZERO
var jump_radius := 55.0

var screen_control: Control


func _ready() -> void:
	screen_control = Control.new()
	screen_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_control.mouse_filter = Control.MOUSE_FILTER_STOP
	screen_control.gui_input.connect(_on_screen_input)
	add_child(screen_control)
	_update_positions()
	screen_control.draw.connect(_draw_controls)


func _update_positions() -> void:
	var size := get_viewport().get_visible_rect().size
	joystick_center = Vector2(125, size.y - 135)
	jump_center = Vector2(size.x - 110, size.y - 125)


func _draw_controls() -> void:
	screen_control.draw_circle(joystick_center, joystick_radius, Color(0.2, 0.3, 0.5, 0.35))
	screen_control.draw_circle(
		joystick_center + joystick_direction * 35.0,
		30.0,
		Color(0.4, 0.7, 1.0, 0.7)
	)

	screen_control.draw_circle(jump_center, jump_radius, Color(0.2, 0.6, 1.0, 0.45))
	screen_control.draw_string(
		ThemeDB.fallback_font,
		jump_center - Vector2(22, -8),
		"JUMP",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color.WHITE
	)


func _on_screen_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(joystick_center) <= joystick_radius * 1.8:
				joystick_touch = event.index
				_update_joystick(event.position)
			elif event.position.distance_to(jump_center) <= jump_radius * 1.5:
				jump_touch = event.index
				jump_pressed.emit()
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				joystick_direction = Vector2.ZERO
				movement_changed.emit(Vector2.ZERO)
			if event.index == jump_touch:
				jump_touch = -1

	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)


func _update_joystick(position: Vector2) -> void:
	var offset := position - joystick_center
	joystick_direction = offset.limit_length(joystick_radius) / joystick_radius
	movement_changed.emit(joystick_direction)
	screen_control.queue_redraw()
