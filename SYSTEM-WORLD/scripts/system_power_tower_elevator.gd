extends Area3D
class_name SYSTEMPowerTowerElevator

const FLOOR_HEIGHT := 4.1
const FLOOR_BASE_Y := 7.0
const TRAVEL_SPEED_METERS_PER_SECOND := 12.0
const MIN_TRAVEL_SECONDS := 2.0

var lift_id := "A"
var lift_center_x := 0.0
var cabin: Node3D
var cabin_floor_label: Label3D
var selection_layer: CanvasLayer
var selection_panel: PanelContainer
var floor_picker: SpinBox
var status_label: Label
var travel_button: Button
var traveling := false


func _ready() -> void:
	lift_id = str(get_meta("system_lift_id", "A"))
	lift_center_x = float(get_meta("system_lift_center_x", 0.0))
	add_to_group("system_interactable")
	set_meta("system_interaction_prompt", "استخدام مصعد X-S-X " + lift_id)
	set_meta("system_elevator_control", true)
	_build_cabin()
	_build_selection_ui()


func system_interact() -> void:
	if traveling:
		return
	var player := _get_player()
	if player == null:
		return
	var maximum_floor := _get_max_accessible_floor()
	floor_picker.max_value = maximum_floor
	floor_picker.value = clampi(_get_player_floor(), 1, maximum_floor)
	status_label.text = "متاح لك الصعود حتى الطابق %03d" % maximum_floor
	selection_panel.show()


func get_max_accessible_floor() -> int:
	return _get_max_accessible_floor()


func get_current_lift_floor() -> int:
	return _get_cabin_floor()


func request_floor(destination_floor: int) -> Dictionary:
	if traveling:
		return {"success": false, "reason": "ELEVATOR_ALREADY_MOVING"}
	if destination_floor < 1 or destination_floor > _get_max_accessible_floor():
		return {"success": false, "reason": "FLOOR_ACCESS_NOT_UNLOCKED", "max_accessible_floor": _get_max_accessible_floor()}
	var player := _get_player()
	if player == null:
		return {"success": false, "reason": "PLAYER_NOT_FOUND"}
	var tower := _get_tower_root()
	if tower == null:
		return {"success": false, "reason": "TOWER_ROOT_NOT_FOUND"}
	var target_local_y := FLOOR_BASE_Y + float(destination_floor - 1) * FLOOR_HEIGHT
	var target_player_position := tower.to_global(Vector3(lift_center_x, target_local_y + 1.1, -0.45))
	var distance := absf(target_local_y - cabin.position.y)
	var travel_seconds := maxf(MIN_TRAVEL_SECONDS, distance / TRAVEL_SPEED_METERS_PER_SECOND)
	traveling = true
	player.set_meta("system_tower_elevator_active", true)
	player.velocity = Vector3.ZERO
	selection_panel.hide()
	status_label.text = "المصعد %s يتحرك إلى الطابق %03d" % [lift_id, destination_floor]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cabin, "position:y", target_local_y, travel_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player, "global_position", target_player_position, travel_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(_finish_travel.bind(player, destination_floor))
	return {"success": true, "lift": lift_id, "destination_floor": destination_floor, "travel_seconds": travel_seconds}


func get_elevator_status() -> Dictionary:
	return {
		"lift": lift_id,
		"moving": traveling,
		"current_floor": _get_cabin_floor(),
		"maximum_accessible_floor": _get_max_accessible_floor(),
		"floor_count": 200
	}


func _finish_travel(player: CharacterBody3D, destination_floor: int) -> void:
	if is_instance_valid(player):
		player.velocity = Vector3.ZERO
		player.remove_meta("system_tower_elevator_active")
	if is_instance_valid(cabin_floor_label):
		cabin_floor_label.text = "FLOOR %03d / 200" % destination_floor
	traveling = false
	if is_instance_valid(status_label):
		status_label.text = "وصلت إلى الطابق %03d" % destination_floor


func _build_cabin() -> void:
	var bank := get_parent() as Node3D
	if bank == null:
		return
	cabin = Node3D.new()
	cabin.name = "MovingElevatorCabin_%s" % lift_id
	cabin.position = Vector3(lift_center_x, FLOOR_BASE_Y, -0.45)
	bank.add_child(cabin)
	_add_cabin_box("CabinFloor", Vector3(4.15, 0.22, 4.4), Vector3(0.0, 0.0, 0.0), Color(0.26, 0.31, 0.37))
	_add_cabin_box("CabinRearWall", Vector3(4.15, 4.0, 0.18), Vector3(0.0, 2.0, -2.1), Color(0.17, 0.23, 0.3))
	_add_cabin_box("CabinLeftWall", Vector3(0.16, 4.0, 4.2), Vector3(-2.0, 2.0, 0.0), Color(0.22, 0.29, 0.35))
	_add_cabin_box("CabinRightWall", Vector3(0.16, 4.0, 4.2), Vector3(2.0, 2.0, 0.0), Color(0.22, 0.29, 0.35))
	_add_cabin_box("CabinRoof", Vector3(4.15, 0.18, 4.4), Vector3(0.0, 4.0, 0.0), Color(0.3, 0.34, 0.39))
	_add_cabin_box("CabinDoorLeft", Vector3(1.95, 3.85, 0.12), Vector3(-1.0, 1.95, 2.12), Color(0.07, 0.2, 0.28))
	_add_cabin_box("CabinDoorRight", Vector3(1.95, 3.85, 0.12), Vector3(1.0, 1.95, 2.12), Color(0.07, 0.2, 0.28))
	cabin_floor_label = Label3D.new()
	cabin_floor_label.name = "CabinFloorDisplay"
	cabin_floor_label.text = "FLOOR 001 / 200"
	cabin_floor_label.font_size = 24
	cabin_floor_label.pixel_size = 0.014
	cabin_floor_label.position = Vector3(0.0, 3.55, 1.85)
	cabin.add_child(cabin_floor_label)


func _add_cabin_box(node_name: String, dimensions: Vector3, local_position: Vector3, tint: Color) -> void:
	var part := MeshInstance3D.new()
	part.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = local_position
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.72
	material.roughness = 0.24
	material.emission_enabled = true
	material.emission = tint * 0.12
	part.material_override = material
	cabin.add_child(part)


func _build_selection_ui() -> void:
	selection_layer = CanvasLayer.new()
	selection_layer.name = "ElevatorSelectionUI_%s" % lift_id
	selection_layer.layer = 22
	add_child(selection_layer)
	selection_panel = PanelContainer.new()
	selection_panel.name = "ElevatorFloorSelectionPanel"
	selection_panel.set_anchors_preset(Control.PRESET_CENTER)
	selection_panel.position = Vector2(-190.0, -145.0)
	selection_panel.size = Vector2(380.0, 290.0)
	selection_panel.custom_minimum_size = Vector2(380.0, 290.0)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	selection_panel.add_child(layout)
	var title := Label.new()
	title.text = "مصعد X-S-X " + lift_id
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	layout.add_child(title)
	var instruction := Label.new()
	instruction.text = "اختر الطابق المطلوب"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(instruction)
	floor_picker = SpinBox.new()
	floor_picker.min_value = 1
	floor_picker.max_value = 200
	floor_picker.step = 1
	floor_picker.value = 1
	floor_picker.custom_minimum_size = Vector2(300.0, 52.0)
	floor_picker.add_theme_font_size_override("font_size", 24)
	layout.add_child(floor_picker)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)
	travel_button = Button.new()
	travel_button.text = "انطلاق"
	travel_button.custom_minimum_size = Vector2(300.0, 52.0)
	travel_button.pressed.connect(_on_travel_pressed)
	layout.add_child(travel_button)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.custom_minimum_size = Vector2(300.0, 44.0)
	close_button.pressed.connect(selection_panel.hide)
	layout.add_child(close_button)
	selection_layer.add_child(selection_panel)
	selection_panel.hide()


func _on_travel_pressed() -> void:
	var result := request_floor(int(floor_picker.value))
	if not bool(result.get("success", false)):
		status_label.text = "لا يمكن الوصول لهذا الطابق حالياً"
		return
	travel_button.disabled = true
	status_label.text = "المصعد يتحرك... وقت الرحلة %.0f ثانية" % float(result.get("travel_seconds", 0.0))


func _get_player() -> CharacterBody3D:
	var players := get_tree().get_nodes_in_group("system_player")
	if players.is_empty():
		return null
	return players[0] as CharacterBody3D


func _get_tower_root() -> Node3D:
	var bank := get_parent()
	if bank == null:
		return null
	var facility := bank.get_parent()
	var lobby := facility.get_parent() if facility != null else null
	var tower := lobby.get_parent() if lobby != null else null
	return tower as Node3D


func _get_max_accessible_floor() -> int:
	var manager := get_tree().root.find_child("PowerTowerManager", true, false)
	if manager == null:
		manager = get_tree().root.find_child("PowerTowerCompetitionManager", true, false)
	var cleared := 0
	if manager != null:
		cleared = int(manager.get("highest_cleared_floor"))
	return clampi(cleared + 1, 1, 200)


func _get_cabin_floor() -> int:
	if cabin == null:
		return 1
	return clampi(roundi((cabin.position.y - FLOOR_BASE_Y) / FLOOR_HEIGHT) + 1, 1, 200)


func _get_player_floor() -> int:
	var player := _get_player()
	var tower := _get_tower_root()
	if player == null or tower == null:
		return _get_cabin_floor()
	var local_position := tower.to_local(player.global_position)
	return clampi(roundi((local_position.y - FLOOR_BASE_Y) / FLOOR_HEIGHT) + 1, 1, 200)
