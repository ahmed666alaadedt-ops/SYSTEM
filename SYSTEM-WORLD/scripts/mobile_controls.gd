
extends CanvasLayer
class_name MobileControls

signal movement_changed(direction: Vector2)
signal jump_pressed
signal look_changed(delta: Vector2)
signal camera_toggle_pressed
signal interact_pressed
signal flight_vertical_changed(value: float)


class TouchOverlay extends Control:

	signal movement_changed(direction: Vector2)
	signal jump_pressed
	signal look_changed(delta: Vector2)
	signal camera_toggle_pressed
	signal interact_pressed
	signal flight_vertical_changed(value: float)

	var joystick_touch := -1
	var joystick_direction := Vector2.ZERO
	var joystick_center := Vector2.ZERO
	var joystick_radius := 75.0

	var jump_touch := -1
	var jump_center := Vector2.ZERO
	var jump_radius := 55.0

	var view_center := Vector2.ZERO
	var view_radius := 48.0

	var interact_center := Vector2.ZERO
	var interact_radius := 52.0

	var flight_up_center := Vector2.ZERO
	var flight_down_center := Vector2.ZERO
	var flight_button_radius := 38.0
	var flight_touch := -1
	var flight_value := 0.0

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
		view_center = Vector2(size.x - 100, 105)
		interact_center = Vector2(size.x - 230, size.y - 270)

		flight_up_center = Vector2(size.x - 225, size.y - 390)
		flight_down_center = Vector2(size.x - 125, size.y - 390)

		# عصا الحركة
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

		# زر القفز
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

		# زر تبديل منظور الكاميرا
		draw_circle(
			view_center,
			view_radius,
			Color(0.35, 0.45, 0.7, 0.75)
		)

		draw_string(
			ThemeDB.fallback_font,
			view_center + Vector2(-24, 6),
			"VIEW",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color.WHITE
		)

		# زر التفاعل
		draw_circle(
			interact_center,
			interact_radius,
			Color(0.75, 0.48, 0.16, 0.85)
		)

		draw_arc(
			interact_center,
			interact_radius,
			0.0,
			TAU,
			48,
			Color(1.0, 0.82, 0.48, 0.95),
			3.0
		)

		draw_string(
			ThemeDB.fallback_font,
			interact_center + Vector2(-22, 6),
			"USE",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)

		# زر الطيران إلى الأعلى
		draw_circle(
			flight_up_center,
			flight_button_radius,
			Color(0.10, 0.65, 0.85, 0.78)
		)

		draw_string(
			ThemeDB.fallback_font,
			flight_up_center + Vector2(-18, 6),
			"UP",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)

		# زر الطيران إلى الأسفل
		draw_circle(
			flight_down_center,
			flight_button_radius,
			Color(0.25, 0.38, 0.65, 0.78)
		)

		draw_string(
			ThemeDB.fallback_font,
			flight_down_center + Vector2(-29, 6),
			"DOWN",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			15,
			Color.WHITE
		)


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed:
				if event.position.distance_to(view_center) <= view_radius * 1.5:
					camera_toggle_pressed.emit()

				elif event.position.distance_to(interact_center) <= interact_radius * 1.5:
					interact_pressed.emit()

				elif event.position.distance_to(flight_up_center) <= flight_button_radius * 1.5:
					if flight_touch == -1:
						flight_touch = event.index
						flight_value = 1.0
						flight_vertical_changed.emit(flight_value)

				elif event.position.distance_to(flight_down_center) <= flight_button_radius * 1.5:
					if flight_touch == -1:
						flight_touch = event.index
						flight_value = -1.0
						flight_vertical_changed.emit(flight_value)

				elif event.position.distance_to(joystick_center) <= joystick_radius * 1.8:
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

				if event.index == flight_touch:
					flight_touch = -1
					flight_value = 0.0
					flight_vertical_changed.emit(0.0)

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
	screen_control.camera_toggle_pressed.connect(_on_camera_toggle_pressed)
	screen_control.interact_pressed.connect(_on_interact_pressed)
	screen_control.flight_vertical_changed.connect(_on_flight_vertical_changed)


func _on_movement_changed(direction: Vector2) -> void:
	movement_changed.emit(direction)


func _on_jump_pressed() -> void:
	jump_pressed.emit()


func _on_look_changed(delta: Vector2) -> void:
	look_changed.emit(delta)


func _on_camera_toggle_pressed() -> void:
	camera_toggle_pressed.emit()


func _on_interact_pressed() -> void:
	interact_pressed.emit()


func _on_flight_vertical_changed(value: float) -> void:
	flight_vertical_changed.emit(value)
