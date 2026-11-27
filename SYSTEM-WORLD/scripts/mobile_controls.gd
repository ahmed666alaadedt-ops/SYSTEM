
extends CanvasLayer
class_name MobileControls

signal movement_changed(direction: Vector2)
signal jump_pressed
signal look_changed(delta: Vector2)
signal camera_toggle_pressed
signal interact_pressed
signal flight_vertical_changed(value: float)

# Combat input signals — ready for the combat system connection.
signal attack_pressed
signal skill_one_pressed
signal skill_two_pressed
signal relic_echo_pressed
signal relic_aegis_pressed
signal elemental_fire_pressed
signal elemental_air_pressed
signal elemental_water_pressed
signal elemental_earth_pressed
signal elemental_lightning_pressed
signal dodge_pressed


class TouchOverlay extends Control:

	signal movement_changed(direction: Vector2)
	signal jump_pressed
	signal look_changed(delta: Vector2)
	signal camera_toggle_pressed
	signal interact_pressed
	signal flight_vertical_changed(value: float)

	signal attack_pressed
	signal skill_one_pressed
	signal skill_two_pressed
	signal relic_echo_pressed
	signal relic_aegis_pressed
	signal elemental_fire_pressed
	signal elemental_air_pressed
	signal elemental_water_pressed
	signal elemental_earth_pressed
	signal elemental_lightning_pressed
	signal dodge_pressed

	var joystick_touch := -1
	var joystick_direction := Vector2.ZERO
	var joystick_center := Vector2.ZERO
	var joystick_radius := 70.0

	var jump_center := Vector2.ZERO
	var jump_radius := 40.0

	var attack_center := Vector2.ZERO
	var attack_radius := 52.0

	var skill_one_center := Vector2.ZERO
	var skill_two_center := Vector2.ZERO
	var relic_echo_center := Vector2.ZERO
	var relic_aegis_center := Vector2.ZERO
	var elemental_button_centers: Dictionary = {}
	var elemental_button_radius := 30.0
	var skill_radius := 43.0

	var dodge_center := Vector2.ZERO
	var dodge_radius := 40.0

	var interact_center := Vector2.ZERO
	var interact_radius := 38.0

	var view_center := Vector2.ZERO
	var view_radius := 37.0

	var flight_up_center := Vector2.ZERO
	var flight_down_center := Vector2.ZERO
	var flight_button_radius := 32.0

	var flight_touch := -1
	var flight_value := 0.0
	var look_touch := -1

	var ui_scale := 1.0


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_update_layout()


	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_update_layout()
			queue_redraw()


	func _update_layout() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return

		# Responsive scale for different landscape screens.
		ui_scale = clampf(
			minf(size.x / 1280.0, size.y / 720.0),
			0.72,
			1.15
		)

		# LEFT SIDE: movement joystick.
		joystick_radius = 70.0 * ui_scale
		joystick_center = Vector2(
			115.0 * ui_scale,
			size.y - 125.0 * ui_scale
		)

		# RIGHT SIDE: combat controls.
		attack_radius = 52.0 * ui_scale
		attack_center = Vector2(
			size.x - 105.0 * ui_scale,
			size.y - 120.0 * ui_scale
		)

		skill_radius = 43.0 * ui_scale
		skill_one_center = Vector2(
			size.x - 230.0 * ui_scale,
			size.y - 205.0 * ui_scale
		)
		skill_two_center = Vector2(
			size.x - 115.0 * ui_scale,
			size.y - 285.0 * ui_scale
		)
		relic_echo_center = Vector2(115.0 * ui_scale, size.y - 265.0 * ui_scale)
		relic_aegis_center = Vector2(245.0 * ui_scale, size.y - 265.0 * ui_scale)
		elemental_button_radius = 29.0 * ui_scale
		elemental_button_centers = {
			"fire": Vector2(58.0 * ui_scale, 72.0 * ui_scale),
			"air": Vector2(132.0 * ui_scale, 72.0 * ui_scale),
			"water": Vector2(206.0 * ui_scale, 72.0 * ui_scale),
			"earth": Vector2(280.0 * ui_scale, 72.0 * ui_scale),
			"lightning": Vector2(354.0 * ui_scale, 72.0 * ui_scale)
		}

		dodge_radius = 40.0 * ui_scale
		dodge_center = Vector2(
			size.x - 245.0 * ui_scale,
			size.y - 95.0 * ui_scale
		)

		jump_radius = 40.0 * ui_scale
		jump_center = Vector2(
			size.x - 365.0 * ui_scale,
			size.y - 100.0 * ui_scale
		)

		interact_radius = 38.0 * ui_scale
		interact_center = Vector2(
			size.x - 365.0 * ui_scale,
			size.y - 205.0 * ui_scale
		)

		# CAMERA AND FLIGHT CONTROLS.
		view_radius = 37.0 * ui_scale
		view_center = Vector2(
			size.x - 105.0 * ui_scale,
			90.0 * ui_scale
		)

		flight_button_radius = 32.0 * ui_scale
		flight_up_center = Vector2(
			size.x - 215.0 * ui_scale,
			90.0 * ui_scale
		)
		flight_down_center = Vector2(
			size.x - 300.0 * ui_scale,
			90.0 * ui_scale
		)


	func _draw() -> void:
		# Movement joystick.
		_draw_action_button(
			joystick_center,
			joystick_radius,
			Color(0.20, 0.45, 0.75),
			"",
			"joystick"
		)

		draw_circle(
			joystick_center + joystick_direction * 32.0 * ui_scale,
			27.0 * ui_scale,
			Color(0.35, 0.75, 1.0, 0.85)
		)

		# Main attack.
		_draw_action_button(
			attack_center,
			attack_radius,
			Color(0.85, 0.25, 0.18),
			"ATK",
			"sword"
		)

		# Combat skills.
		_draw_action_button(
			skill_one_center,
			skill_radius,
			Color(0.15, 0.65, 0.85),
			"SKILL",
			"burst"
		)

		_draw_action_button(
			skill_two_center,
			skill_radius,
			Color(0.48, 0.30, 0.85),
			"SKILL",
			"magic"
		)

		# Five Nen-gated elemental relic skills. The buttons request server authorization only.
		_draw_action_button(elemental_button_centers["fire"], elemental_button_radius, Color(0.88, 0.22, 0.12), "FIRE", "magic")
		_draw_action_button(elemental_button_centers["air"], elemental_button_radius, Color(0.55, 0.72, 0.86), "AIR", "up")
		_draw_action_button(elemental_button_centers["water"], elemental_button_radius, Color(0.12, 0.48, 0.92), "WATER", "magic")
		_draw_action_button(elemental_button_centers["earth"], elemental_button_radius, Color(0.38, 0.58, 0.24), "EARTH", "shield")
		_draw_action_button(elemental_button_centers["lightning"], elemental_button_radius, Color(0.78, 0.68, 0.12), "LIGHT", "burst")

		# Rare relic skill control.
		_draw_action_button(relic_echo_center, skill_radius, Color(0.12, 0.72, 0.82), "ECHO", "magic")
		_draw_action_button(relic_aegis_center, skill_radius, Color(0.72, 0.48, 0.16), "AEGIS", "shield")

		# Dodge and jump.
		_draw_action_button(
			dodge_center,
			dodge_radius,
			Color(0.18, 0.65, 0.55),
			"DODGE",
			"dodge"
		)

		_draw_action_button(
			jump_center,
			jump_radius,
			Color(0.20, 0.55, 0.90),
			"JUMP",
			"jump"
		)

		# Interaction.
		_draw_action_button(
			interact_center,
			interact_radius,
			Color(0.80, 0.52, 0.16),
			"USE",
			"interact"
		)

		# Camera view.
		_draw_action_button(
			view_center,
			view_radius,
			Color(0.35, 0.45, 0.72),
			"VIEW",
			"camera"
		)

		# Flight controls.
		_draw_action_button(
			flight_up_center,
			flight_button_radius,
			Color(0.10, 0.65, 0.85),
			"UP",
			"up"
		)

		_draw_action_button(
			flight_down_center,
			flight_button_radius,
			Color(0.25, 0.38, 0.70),
			"DOWN",
			"down"
		)


	func _draw_action_button(
		center: Vector2,
		radius: float,
		tint: Color,
		label: String,
		icon_type: String
	) -> void:
		draw_circle(
			center,
			radius,
			Color(tint.r, tint.g, tint.b, 0.38)
		)

		draw_arc(
			center,
			radius,
			0.0,
			TAU,
			48,
			Color(0.65, 0.88, 1.0, 0.9),
			2.0 * ui_scale,
			true
		)

		var icon_center := center - Vector2(
			0,
			8.0 * ui_scale if not label.is_empty() else 0
		)

		_draw_icon(icon_center, radius, icon_type)

		if not label.is_empty():
			draw_string(
				ThemeDB.fallback_font,
				center + Vector2(-radius * 0.55, radius * 0.62),
				label,
				HORIZONTAL_ALIGNMENT_CENTER,
				radius * 1.1,
				int(11.0 * ui_scale),
				Color.WHITE
			)


	func _draw_icon(
		center: Vector2,
		radius: float,
		icon_type: String
	) -> void:
		var s := radius / 50.0
		var white := Color(1.0, 1.0, 1.0, 0.96)
		var width := 3.0 * ui_scale

		match icon_type:

			"sword":
				draw_line(
					center + Vector2(-17, 15) * s,
					center + Vector2(16, -18) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(-13, -17) * s,
					center + Vector2(17, 14) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(-21, 10) * s,
					center + Vector2(-9, 22) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(9, 10) * s,
					center + Vector2(21, -2) * s,
					white,
					width,
					true
				)

			"burst", "magic":
				for i in range(8):
					var angle := TAU * float(i) / 8.0
					var direction := Vector2(
						cos(angle),
						sin(angle)
					)
					draw_line(
						center + direction * 5.0 * s,
						center + direction * 23.0 * s,
						white,
						width,
						true
					)
				draw_circle(center, 5.0 * s, white)

			"dodge":
				draw_line(
					center + Vector2(-20, 0) * s,
					center + Vector2(16, 0) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(5, -12) * s,
					center + Vector2(18, 0) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(5, 12) * s,
					center + Vector2(18, 0) * s,
					white,
					width,
					true
				)

			"jump", "up":
				draw_line(
					center + Vector2(0, 19) * s,
					center + Vector2(0, -18) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(-13, -5) * s,
					center + Vector2(0, -19) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(13, -5) * s,
					center + Vector2(0, -19) * s,
					white,
					width,
					true
				)

			"down":
				draw_line(
					center + Vector2(0, -18) * s,
					center + Vector2(0, 19) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(-13, 5) * s,
					center + Vector2(0, 19) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(13, 5) * s,
					center + Vector2(0, 19) * s,
					white,
					width,
					true
				)

			"shield":
				var shield_top := center + Vector2(0, -22) * s
				var shield_left := center + Vector2(-18, -12) * s
				var shield_right := center + Vector2(18, -12) * s
				var shield_left_bottom := center + Vector2(-14, 8) * s
				var shield_point := center + Vector2(0, 23) * s
				var shield_right_bottom := center + Vector2(14, 8) * s
				draw_line(shield_top, shield_left, white, width, true)
				draw_line(shield_top, shield_right, white, width, true)
				draw_line(shield_left, shield_left_bottom, white, width, true)
				draw_line(shield_left_bottom, shield_point, white, width, true)
				draw_line(shield_point, shield_right_bottom, white, width, true)
				draw_line(shield_right_bottom, shield_right, white, width, true)

			"camera":
				draw_arc(
					center,
					13.0 * s,
					0,
					TAU,
					32,
					white,
					width,
					true
				)
				draw_circle(
					center,
					5.0 * s,
					white
				)

			"interact":
				draw_arc(
					center,
					15.0 * s,
					0,
					TAU,
					32,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(-10, 0) * s,
					center + Vector2(10, 0) * s,
					white,
					width,
					true
				)
				draw_line(
					center + Vector2(0, -10) * s,
					center + Vector2(0, 10) * s,
					white,
					width,
					true
				)


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed:
				_handle_touch_pressed(event)
			else:
				_handle_touch_released(event)

		elif event is InputEventScreenDrag:
			if event.index == joystick_touch:
				_update_joystick(event.position)

			elif event.index == look_touch:
				look_changed.emit(event.relative)


	func _handle_touch_pressed(event: InputEventScreenTouch) -> void:
		var p := event.position

		for element_id in ["fire", "air", "water", "earth", "lightning"]:
			var elemental_center: Vector2 = elemental_button_centers[element_id]
			if p.distance_to(elemental_center) <= elemental_button_radius * 1.5:
				match element_id:
					"fire": elemental_fire_pressed.emit()
					"air": elemental_air_pressed.emit()
					"water": elemental_water_pressed.emit()
					"earth": elemental_earth_pressed.emit()
					"lightning": elemental_lightning_pressed.emit()
				return

		if p.distance_to(view_center) <= view_radius * 1.45:
			camera_toggle_pressed.emit()
			return

		if p.distance_to(interact_center) <= interact_radius * 1.45:
			interact_pressed.emit()
			return

		if p.distance_to(relic_echo_center) <= skill_radius * 1.4:
			relic_echo_pressed.emit()
			return

		if p.distance_to(relic_aegis_center) <= skill_radius * 1.4:
			relic_aegis_pressed.emit()
			return

		if p.distance_to(flight_up_center) <= flight_button_radius * 1.45:
			if flight_touch == -1:
				flight_touch = event.index
				flight_value = 1.0
				flight_vertical_changed.emit(flight_value)
			return

		if p.distance_to(flight_down_center) <= flight_button_radius * 1.45:
			if flight_touch == -1:
				flight_touch = event.index
				flight_value = -1.0
				flight_vertical_changed.emit(flight_value)
			return

		if p.distance_to(attack_center) <= attack_radius * 1.4:
			attack_pressed.emit()
			return

		if p.distance_to(skill_one_center) <= skill_radius * 1.4:
			skill_one_pressed.emit()
			return

		if p.distance_to(skill_two_center) <= skill_radius * 1.4:
			skill_two_pressed.emit()
			return

		if p.distance_to(dodge_center) <= dodge_radius * 1.4:
			dodge_pressed.emit()
			return

		if p.distance_to(jump_center) <= jump_radius * 1.4:
			jump_pressed.emit()
			return

		if p.distance_to(joystick_center) <= joystick_radius * 1.8:
			if joystick_touch == -1:
				joystick_touch = event.index
				_update_joystick(p)
			return

		# Remaining right-side touch area controls camera look.
		if p.x > size.x * 0.42 and look_touch == -1:
			look_touch = event.index


	func _handle_touch_released(event: InputEventScreenTouch) -> void:
		if event.index == joystick_touch:
			joystick_touch = -1
			joystick_direction = Vector2.ZERO
			movement_changed.emit(Vector2.ZERO)
			queue_redraw()

		if event.index == look_touch:
			look_touch = -1

		if event.index == flight_touch:
			flight_touch = -1
			flight_value = 0.0
			flight_vertical_changed.emit(0.0)


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

	screen_control.attack_pressed.connect(_on_attack_pressed)
	screen_control.skill_one_pressed.connect(_on_skill_one_pressed)
	screen_control.skill_two_pressed.connect(_on_skill_two_pressed)
	screen_control.relic_echo_pressed.connect(_on_relic_echo_pressed)
	screen_control.relic_aegis_pressed.connect(_on_relic_aegis_pressed)
	screen_control.elemental_fire_pressed.connect(_on_elemental_fire_pressed)
	screen_control.elemental_air_pressed.connect(_on_elemental_air_pressed)
	screen_control.elemental_water_pressed.connect(_on_elemental_water_pressed)
	screen_control.elemental_earth_pressed.connect(_on_elemental_earth_pressed)
	screen_control.elemental_lightning_pressed.connect(_on_elemental_lightning_pressed)
	screen_control.dodge_pressed.connect(_on_dodge_pressed)


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


func _on_attack_pressed() -> void:
	attack_pressed.emit()


func _on_skill_one_pressed() -> void:
	skill_one_pressed.emit()


func _on_skill_two_pressed() -> void:
	skill_two_pressed.emit()


func _on_relic_echo_pressed() -> void:
	relic_echo_pressed.emit()


func _on_relic_aegis_pressed() -> void:
	relic_aegis_pressed.emit()


func _on_elemental_fire_pressed() -> void:
	elemental_fire_pressed.emit()


func _on_elemental_air_pressed() -> void:
	elemental_air_pressed.emit()


func _on_elemental_water_pressed() -> void:
	elemental_water_pressed.emit()


func _on_elemental_earth_pressed() -> void:
	elemental_earth_pressed.emit()


func _on_elemental_lightning_pressed() -> void:
	elemental_lightning_pressed.emit()


func _on_dodge_pressed() -> void:
	dodge_pressed.emit()
