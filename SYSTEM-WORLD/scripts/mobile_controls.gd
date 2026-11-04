extends CanvasLayer
class_name MobileControls

signal movement_changed(direction: Vector2)
signal jump_pressed
signal look_changed(delta: Vector2)


class TouchOverlay extends Control:
	signal movement_changed(direction: Vector2)
	signal jump_pressed
	signal look_changed(delta: Vector2)

	var joystick_touch := -1
	var joystick_direction := Vector2.ZERO
	var joystick_center := Vector2.ZERO
	var joystick_radius := 75.0

	var jump_touch := -1
	var jump_center := Vector2.ZERO
	var jump_radius := 55.0

	var look_touch := -1


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()


	func _draw() -> void:
		joystick_center = Vector2(125, size.y - 135)
		jump_center = Vector2(size.x - 110, size.y - 125)

		draw_circle(
			joystick_center,
			joystick_radius,
			Color(0.2, 0.3, 0.5, 0.45)
		)

		draw_circle(
			joystick_center + joystick_direction * 35.0,
			30.0,
			Color(0.4, 0.7, 1.0, 0.8)
		)

		draw_circle(
			jump_center,
			jump_radius,
			Color(0.2, 0.6, 1.0, 0.65)
		)

		draw_string(
			ThemeDB.fallback_font,
			jump_center + Vector2(-22, 7),
			"JUMP",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed:
				if event.position.distance_to(joystick_center) <= joystick_radius * 1.8:
					if joystick_touch == -1:
						joystick_touch = event.index
						_update_joystick(event.position)

				elif event.position.distance_to(jump_center) <= jump_radius * 1.5:
					if jump_touch == -1:
						jump_touch = event.index
						jump_pressed.emit()

				elif look_touch == -1:
					look_touch = event.index

			else:
				if event.index == joystick_touch:
					joystick_touch = -1
					joystick_direction = Vector2.ZERO
					movement_changed.emit(Vector2.ZERO)
					queue_redraw()

				if event.index == jump_touch:
					jump_touch = -1

				if event.index == look_touch:
					look_touch = -1

		elif event is InputEventScreenDrag:
			if event.index == joystick_touch:
				_update_joystick(event.position)

			elif event.index == look_touch:
				look_changed.emit(event.relative)


	func _update_joystick(position: Vector2) -> void:
		var offset := position - joystick_center

		joystick_direction = (
			offset.limit_length(joystick_radius) / joystick_radius
		)

		movement_changed.emit(joystick_direction)
		queue_redraw()


var screen_control: TouchOverlay


func _ready() -> void:
	layer = 10

	screen_control = TouchOverlay.new()
	add_child(screen_control)

	screen_control.movement_changed.connect(_on_movement_changed)
	screen_control.jump_pressed.connect(_on_jump_pressed)
	screen_control.look_changed.connect(_on_look_changed)


func _on_movement_changed(direction: Vector2) -> void:
	movement_changed.emit(direction)


func _on_jump_pressed() -> void:
	jump_pressed.emit()


func _on_look_changed(delta: Vector2) -> void:
	look_changed.emit(delta)
