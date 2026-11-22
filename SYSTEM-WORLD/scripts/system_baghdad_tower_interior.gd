extends Node3D

## Shared first playable lobby for the five connected Baghdad landmark towers.
## The Power Tower remains a separate challenge venue and never receives this lobby.

var tower_id := ""
var display_title := ""
var entrance_script: Script
var external_return_position := Vector3.ZERO
var floor_count := 1
var _lift_cabin: Node3D
var _lift_door_left: MeshInstance3D
var _lift_door_right: MeshInstance3D
var _lift_status_label: Label3D
var _elevator_traveling := false

func build(p_tower_id: String, p_title: String, p_entrance_script: Script, p_external_return_position: Vector3, p_floor_count: int = 1) -> void:
	tower_id = p_tower_id
	display_title = p_title
	entrance_script = p_entrance_script
	external_return_position = p_external_return_position
	floor_count = maxi(1, p_floor_count)
	name = "TowerInterior"
	_build_lobby()
	_build_advertising_screens()
	_build_service_desks()
	if tower_id == "hunter_association_tower_baghdad":
		_build_hunter_exam_tunnel()
		_build_hunter_exam_public_announcement()
	_build_exit()
	_build_tower_identity_feature()
	_build_lobby_wayfinding()
	_build_upper_floor_access()
	_build_emergency_stairwell()
	_build_lift_console()
	_build_elevator_cabin()
	set_meta("playable_interior_blockout", true)
	set_meta("upper_floor_blockout_count", mini(4, maxi(0, floor_count - 1)))
	set_meta("total_floor_count", floor_count)
	set_meta("procedural_floor_world_available", true)
	set_meta("interactive_floor_selection", true)
	set_meta("tower_identity_feature_ready", true)
	set_meta("interior_ad_screen_count", 2)
	set_meta("emergency_stairwell_ready", true)
	set_meta("emergency_stairwell_step_count", 200)
	set_meta("animated_elevator_ready", true)
	set_meta("service_desks_have_collision", true)
	set_meta("tower_id", tower_id)

func get_entry_position() -> Vector3:
	return to_global(Vector3(0.0, 1.4, 10.0))

func get_return_position() -> Vector3:
	return external_return_position

func _build_lobby() -> void:
	var floor_mat := _material(Color(0.11, 0.15, 0.20), 0.42, 0.45)
	var wall_mat := _material(Color(0.045, 0.075, 0.11), 0.36, 0.58)
	var accent := _material(Color(0.72, 0.52, 0.22), 0.28, 0.72)
	var glass := _material(Color(0.06, 0.35, 0.48), 0.22, 0.35)
	glass.emission_enabled = true
	glass.emission = Color(0.02, 0.18, 0.28)
	glass.emission_energy_multiplier = 1.0
	_add_solid_box("LobbyFloor", Vector3(0.0, -0.35, 0.0), Vector3(42.0, 0.7, 42.0), floor_mat)
	_add_solid_box("LobbyLeftWall", Vector3(-21.0, 7.0, 0.0), Vector3(1.0, 14.0, 42.0), wall_mat)
	_add_solid_box("LobbyRightWall", Vector3(21.0, 7.0, 0.0), Vector3(1.0, 14.0, 42.0), wall_mat)
	if tower_id == "hunter_association_tower_baghdad":
		_add_solid_box("LobbyRearWall_Left", Vector3(-15.0, 7.0, -21.0), Vector3(12.0, 14.0, 1.0), wall_mat)
		_add_solid_box("LobbyRearWall_Right", Vector3(15.0, 7.0, -21.0), Vector3(12.0, 14.0, 1.0), wall_mat)
		_add_solid_box("LobbyRearWall_AboveExamTunnel", Vector3(0.0, 12.0, -21.0), Vector3(18.0, 4.0, 1.0), wall_mat)
	else:
		_add_solid_box("LobbyRearWall", Vector3(0.0, 7.0, -21.0), Vector3(42.0, 14.0, 1.0), wall_mat)
	_add_solid_box("LobbyFrontWallLeft", Vector3(-14.0, 7.0, 21.0), Vector3(14.0, 14.0, 1.0), wall_mat)
	_add_solid_box("LobbyFrontWallRight", Vector3(14.0, 7.0, 21.0), Vector3(14.0, 14.0, 1.0), wall_mat)
	_add_solid_box("LobbyCeiling", Vector3(0.0, 14.0, 0.0), Vector3(42.0, 0.8, 42.0), wall_mat)
	_add_visual_box("FloorIdentityLine", Vector3(0.0, 0.08, 0.0), Vector3(28.0, 0.08, 0.5), accent)
	if tower_id == "hunter_association_tower_baghdad":
		_add_visual_box("RearFeatureWall_Left", Vector3(-11.0, 7.5, -20.35), Vector3(4.0, 11.0, 0.25), glass)
		_add_visual_box("RearFeatureWall_Right", Vector3(11.0, 7.5, -20.35), Vector3(4.0, 11.0, 0.25), glass)
		_add_visual_box("ExamTunnelEntranceHeader", Vector3(0.0, 12.0, -20.35), Vector3(18.0, 2.0, 0.25), glass)
	else:
		_add_visual_box("RearFeatureWall", Vector3(0.0, 7.5, -20.35), Vector3(26.0, 11.0, 0.25), glass)
	var identity := Label3D.new()
	identity.name = "TowerLobbyIdentity"
	identity.text = display_title + "\nSYSTEM BAGHDAD"
	identity.font_size = 34
	identity.position = Vector3(0.0, 11.0, -19.9)
	identity.pixel_size = 0.012
	identity.modulate = Color(0.75, 0.91, 1.0)
	add_child(identity)
	var light := OmniLight3D.new()
	light.name = "LobbyLighting"
	light.position = Vector3(0.0, 11.5, 0.0)
	light.light_color = Color(0.58, 0.78, 1.0)
	light.light_energy = 1.6
	light.omni_range = 48.0
	light.shadow_enabled = false
	add_child(light)


func _build_advertising_screens() -> void:
	# Two readable lobby displays, mounted on the side walls so they never block
	# the Hunter examination tunnel or the central tower entrance.
	var screen_material := _material(Color(0.015, 0.12, 0.19), 0.24, 0.32)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.015, 0.32, 0.58)
	screen_material.emission_energy_multiplier = 1.8
	var frame_material := _material(Color(0.72, 0.52, 0.22), 0.25, 0.72)
	var wall_positions := [Vector3(-20.25, 6.4, -2.0), Vector3(20.25, 6.4, -2.0)]
	var wall_rotations := [PI * 0.5, -PI * 0.5]
	for index in range(wall_positions.size()):
		var screen_root := Node3D.new()
		screen_root.name = "InteriorAdScreen_%02d" % index
		screen_root.position = wall_positions[index]
		screen_root.rotation.y = wall_rotations[index]
		add_child(screen_root)
		var frame := MeshInstance3D.new()
		frame.name = "AdScreenFrame"
		var frame_mesh := BoxMesh.new()
		frame_mesh.size = Vector3(10.8, 5.8, 0.65)
		frame.mesh = frame_mesh
		frame.material_override = frame_material
		screen_root.add_child(frame)
		var panel := MeshInstance3D.new()
		panel.name = "AdScreenDisplay"
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(10.0, 5.0, 0.12)
		panel.mesh = panel_mesh
		panel.position.z = -0.4
		panel.material_override = screen_material
		screen_root.add_child(panel)
		var message := Label3D.new()
		message.name = "AdScreenMessage"
		message.text = "إعلانات البرج\nالفعاليات والخدمات\nSYSTEM AD NETWORK"
		message.font_size = 24
		message.position = Vector3(0.0, 0.0, -0.5)
		message.pixel_size = 0.012
		message.modulate = Color(0.84, 0.95, 1.0)
		screen_root.add_child(message)
	set_meta("interior_ad_screen_count", wall_positions.size())
	set_meta("local_ad_content_only", true)


func _build_hunter_exam_tunnel() -> void:
	var shell_mat := _material(Color(0.035, 0.065, 0.095), 0.3, 0.78)
	var floor_mat := _material(Color(0.12, 0.16, 0.20), 0.32, 0.62)
	var trim_mat := _material(Color(0.04, 0.58, 0.82), 0.22, 0.48)
	trim_mat.emission_enabled = true
	trim_mat.emission = Color(0.015, 0.34, 0.72)
	trim_mat.emission_energy_multiplier = 2.0
	var gold_mat := _material(Color(0.72, 0.48, 0.16), 0.26, 0.72)
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(0.24, 0.11, 0.015)
	gold_mat.emission_energy_multiplier = 0.8
	var gate_panel_material := _material(Color(0.035, 0.34, 0.52, 0.42), 0.2, 0.42)
	gate_panel_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gate_panel_material.emission_enabled = true
	gate_panel_material.emission = Color(0.015, 0.28, 0.55)
	gate_panel_material.emission_energy_multiplier = 1.4

	# Open threshold from the Hunter lobby into a dedicated, physically enclosed passage.
	_add_solid_box("ExamTunnelFloor", Vector3(0.0, -0.35, -49.0), Vector3(18.0, 0.7, 58.0), floor_mat)
	_add_solid_box("ExamTunnelLeftWall", Vector3(-9.0, 5.0, -49.0), Vector3(0.7, 10.0, 58.0), shell_mat)
	_add_solid_box("ExamTunnelRightWall", Vector3(9.0, 5.0, -49.0), Vector3(0.7, 10.0, 58.0), shell_mat)
	_add_solid_box("ExamTunnelCeiling", Vector3(0.0, 10.0, -49.0), Vector3(18.0, 0.7, 58.0), shell_mat)

	for index in range(8):
		var z := -23.0 - float(index) * 7.2
		_add_visual_box("ExamTunnelLightStrip_%02d" % index, Vector3(0.0, 9.55, z), Vector3(12.0, 0.12, 0.24), trim_mat)
		_add_visual_box("ExamTunnelFloorGuide_%02d" % index, Vector3(0.0, 0.055, z), Vector3(10.0, 0.045, 0.12), trim_mat)
		_add_visual_box("ExamTunnelFrame_Left_%02d" % index, Vector3(-8.45, 5.0, z), Vector3(0.22, 9.0, 0.35), gold_mat)
		_add_visual_box("ExamTunnelFrame_Right_%02d" % index, Vector3(8.45, 5.0, z), Vector3(0.22, 9.0, 0.35), gold_mat)
		_add_visual_box("ExamTunnelFrame_Header_%02d" % index, Vector3(0.0, 9.4, z), Vector3(17.0, 0.22, 0.35), gold_mat)
		var side_light := OmniLight3D.new()
		side_light.name = "ExamTunnelLamp_%02d" % index
		side_light.position = Vector3(0.0, 8.2, z)
		side_light.light_color = Color(0.08, 0.58, 0.95)
		side_light.light_energy = 1.25
		side_light.omni_range = 13.0
		side_light.shadow_enabled = false
		add_child(side_light)

	_add_solid_box("ExamStagingFloor", Vector3(0.0, -0.35, -82.0), Vector3(24.0, 0.7, 10.0), floor_mat)
	_add_solid_box("ExamStagingBackWall", Vector3(0.0, 6.0, -87.0), Vector3(24.0, 12.0, 0.7), shell_mat)
	_add_solid_box("ExamStagingLeftWall", Vector3(-12.0, 6.0, -82.0), Vector3(0.7, 12.0, 10.0), shell_mat)
	_add_solid_box("ExamStagingRightWall", Vector3(12.0, 6.0, -82.0), Vector3(0.7, 12.0, 10.0), shell_mat)
	_add_visual_box("ExamStagingGateFrame", Vector3(0.0, 5.0, -86.45), Vector3(9.0, 9.0, 0.35), gold_mat)
	_add_visual_box("ExamStagingGateCore", Vector3(0.0, 4.8, -86.2), Vector3(7.0, 7.0, 0.12), trim_mat)

	var title := Label3D.new()
	title.name = "HunterExamTunnelTitle"
	title.text = "HUNTER EXAMINATION\nCANDIDATE TRANSIT"
	title.font_size = 30
	title.position = Vector3(0.0, 7.2, -84.0)
	title.pixel_size = 0.012
	title.modulate = Color(0.76, 0.91, 1.0)
	add_child(title)

	# Seven numbered examination gates turn the tunnel into a readable candidate journey.
	var stage_titles := [
		"01 — المطاردة والتحمل",
		"02 — المهارة والمعرفة",
		"03 — برج الاختبارات",
		"04 — البقاء في الجزيرة",
		"05 — الاستراتيجية والتفاوض",
		"06 — المواجهات الفردية",
		"07 — الاختبار النهائي"
	]
	for stage_index in range(stage_titles.size()):
		var stage_z := -26.0 - float(stage_index) * 6.7
		_add_visual_box("HunterExamStageGate_%02d" % (stage_index + 1), Vector3(0.0, 4.8, stage_z), Vector3(13.0, 0.18, 0.3), gold_mat)
		_add_visual_box("HunterExamStageGate_Left_%02d" % (stage_index + 1), Vector3(-6.4, 2.4, stage_z), Vector3(0.18, 4.8, 0.3), gold_mat)
		_add_visual_box("HunterExamStageGate_Right_%02d" % (stage_index + 1), Vector3(6.4, 2.4, stage_z), Vector3(0.18, 4.8, 0.3), gold_mat)
		var stage_label := Label3D.new()
		stage_label.name = "HunterExamStageLabel_%02d" % (stage_index + 1)
		stage_label.text = str(stage_titles[stage_index])
		stage_label.font_size = 20
		stage_label.position = Vector3(0.0, 6.0, stage_z - 0.25)
		stage_label.pixel_size = 0.012
		stage_label.modulate = Color(0.84, 0.94, 1.0)
		add_child(stage_label)
		_create_hunter_exam_gate_barrier(
			"HunterExamStageGateBarrier_%02d" % (stage_index + 1),
			Vector3(0.0, 4.5, stage_z),
			Vector3(17.6, 8.8, 0.32),
			gate_panel_material
		)

	_create_hunter_exam_gate_barrier(
		"HunterExamStagingGateBarrier",
		Vector3(0.0, 4.5, -86.45),
		Vector3(8.6, 8.6, 0.32),
		gate_panel_material
	)

	if entrance_script != null:
		var start_area: Area3D = entrance_script.new()
		start_area.name = "HunterExamTunnelStart"
		start_area.configure("hunter_exam_tunnel_start_baghdad", "بدء اختبار الصيادين من نفق الانطلاق", "region_baghdad")
		# The candidate must begin or resume the exam at the lobby-side threshold,
		# before reaching any of the seven physical stage gates.
		start_area.position = Vector3(0.0, 1.5, -22.5)
		start_area.set_meta("system_display_name", "بوابة انطلاق اختبار الصيادين")
		start_area.set_meta("system_service_description", "بوابة الانطلاق الرسمية لاختبارات الصيادين داخل برج الجمعية.")
		start_area.set_meta("system_interaction_prompt", "بدء / استئناف اختبار الصيادين")
		var start_collision := CollisionShape3D.new()
		var start_shape := SphereShape3D.new()
		start_shape.radius = 2.0
		start_collision.shape = start_shape
		start_area.add_child(start_collision)
		add_child(start_area)

	set_meta("hunter_exam_tunnel_built", true)
	set_meta("hunter_exam_tunnel_length", 58.0)
	set_meta("hunter_exam_tunnel_staging_chamber", true)
	set_meta("hunter_exam_stage_gate_count", 7)
	set_hunter_exam_tunnel_access(false)


func _create_hunter_exam_gate_barrier(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var barrier := StaticBody3D.new()
	barrier.name = node_name
	barrier.position = position
	var visual := MeshInstance3D.new()
	visual.name = "GatePanelVisual"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = size
	visual.mesh = panel_mesh
	visual.material_override = material
	barrier.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.name = "GatePanelCollision"
	var collision_shape := BoxShape3D.new()
	collision_shape.size = size
	collision.shape = collision_shape
	barrier.add_child(collision)
	add_child(barrier)


func set_hunter_exam_tunnel_access(open_access: bool) -> void:
	for stage_number in range(1, 8):
		var barrier := get_node_or_null("HunterExamStageGateBarrier_%02d" % stage_number) as StaticBody3D
		if barrier == null:
			continue
		var collision := barrier.get_node_or_null("GatePanelCollision") as CollisionShape3D
		var visual := barrier.get_node_or_null("GatePanelVisual") as MeshInstance3D
		if collision != null:
			collision.disabled = open_access
		if visual != null:
			visual.visible = not open_access
	var staging_barrier := get_node_or_null("HunterExamStagingGateBarrier") as StaticBody3D
	if staging_barrier != null:
		var staging_collision := staging_barrier.get_node_or_null("GatePanelCollision") as CollisionShape3D
		var staging_visual := staging_barrier.get_node_or_null("GatePanelVisual") as MeshInstance3D
		if staging_collision != null:
			staging_collision.disabled = open_access
		if staging_visual != null:
			staging_visual.visible = not open_access
	set_meta("hunter_exam_tunnel_access_open", open_access)
	set_meta("hunter_exam_access_state", "open_for_registered_candidate" if open_access else "registration_and_exam_start_required")


func _build_hunter_exam_public_announcement() -> void:
	# Official public-facing announcement: the exam facility is visible and openly
	# identified by the Hunter Association, not concealed or presented as secret.
	var frame_mat := _material(Color(0.10, 0.14, 0.19), 0.3, 0.72)
	var screen_mat := _material(Color(0.025, 0.16, 0.23), 0.22, 0.38)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.01, 0.24, 0.42)
	screen_mat.emission_energy_multiplier = 1.5
	var gold_mat := _material(Color(0.78, 0.56, 0.22), 0.25, 0.72)
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(0.22, 0.12, 0.025)
	gold_mat.emission_energy_multiplier = 0.8

	# Large bilingual sign directly above the open tunnel threshold.
	_add_visual_box("HunterExamPublicSignBacking", Vector3(0.0, 8.8, -19.45), Vector3(16.0, 3.0, 0.55), frame_mat)
	_add_visual_box("HunterExamPublicSignBorder", Vector3(0.0, 10.45, -19.12), Vector3(15.4, 0.12, 0.12), gold_mat)
	var public_sign := Label3D.new()
	public_sign.name = "HunterExamPublicSign"
	public_sign.text = "مركز اختبارات الصيادين\nHUNTER EXAMINATION CENTER"
	public_sign.font_size = 30
	public_sign.position = Vector3(0.0, 8.65, -19.05)
	public_sign.pixel_size = 0.014
	public_sign.modulate = Color(0.84, 0.94, 1.0)
	add_child(public_sign)

	# Public notice board beside the entrance, visible from the main lobby.
	_add_visual_box("HunterExamNoticeBoardFrame", Vector3(-14.2, 5.0, -19.35), Vector3(7.2, 7.2, 0.65), gold_mat)
	_add_visual_box("HunterExamNoticeBoardScreen", Vector3(-14.2, 5.0, -18.98), Vector3(6.85, 6.85, 0.16), screen_mat)
	var notice := Label3D.new()
	notice.name = "HunterExamPublicNotice"
	notice.text = "إعلان رسمي من نقابة الصيادين\nاختبارات الصيادين\n\nالتسجيل والاستعلام\nفي مكاتب النقابة\n\nمواعيد الدفعات\nتُعلن عبر النقابة\n\nالدخول للنفق للمسجلين\nوالمقبولين فقط"
	notice.font_size = 18
	notice.position = Vector3(-14.2, 7.65, -18.82)
	notice.pixel_size = 0.012
	notice.modulate = Color(0.9, 0.95, 1.0)
	add_child(notice)

	if entrance_script != null:
		var registration_area: Area3D = entrance_script.new()
		registration_area.name = "HunterExamRegistrationInteraction"
		registration_area.configure("hunter_exam_registration_counter_baghdad", "التسجيل في اختبار الصيادين", "region_baghdad")
		registration_area.position = Vector3(-7.0, 1.5, -9.0)
		registration_area.set_meta("system_display_name", "مكتب تسجيل اختبار الصيادين")
		registration_area.set_meta("system_service_description", "التسجيل مجاني، وتُحفظ هوية المرشح ورقم محاولته وتقدمه.")
		registration_area.set_meta("system_interaction_prompt", "التسجيل / الاستعلام عن اختبار الصيادين")
		var registration_collision := CollisionShape3D.new()
		var registration_shape := SphereShape3D.new()
		registration_shape.radius = 3.0
		registration_collision.shape = registration_shape
		registration_area.add_child(registration_collision)
		add_child(registration_area)

	if entrance_script != null:
		var notice_area: Area3D = entrance_script.new()
		notice_area.name = "HunterExamPublicNoticeInteraction"
		notice_area.configure("hunter_exam_public_notice_baghdad", "إعلان اختبارات الصيادين ومواعيدها", "region_baghdad")
		notice_area.position = Vector3(-14.2, 1.5, -15.8)
		notice_area.set_meta("system_display_name", "إعلان نقابة الصيادين")
		notice_area.set_meta("system_service_description", "لوحة عامة معلنة للاختبارات؛ التسجيل والاستعلام متاحان من مكاتب النقابة، والدخول للنفق للمسجلين والمقبولين فقط.")
		notice_area.set_meta("system_interaction_prompt", "قراءة إعلان اختبارات الصيادين")
		var notice_collision := CollisionShape3D.new()
		var notice_shape := SphereShape3D.new()
		notice_shape.radius = 3.0
		notice_collision.shape = notice_shape
		notice_area.add_child(notice_collision)
		add_child(notice_area)

	set_meta("hunter_exam_publicly_announced", true)
	set_meta("hunter_exam_public_notice_board", true)
	set_meta("hunter_exam_entry_requires_registration", true)

func _build_service_desks() -> void:
	var desk_mat := _material(Color(0.20, 0.24, 0.29), 0.34, 0.55)
	var screen_mat := _material(Color(0.04, 0.52, 0.70), 0.22, 0.25)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.02, 0.35, 0.62)
	screen_mat.emission_energy_multiplier = 1.4
	var desk_positions := [Vector3(-12.0, 1.2, -8.0), Vector3(0.0, 1.2, -8.0), Vector3(12.0, 1.2, -8.0)]
	if tower_id == "shopping_tower_baghdad":
		desk_positions = [Vector3(-16.0, 1.2, -8.0), Vector3(-8.0, 1.2, -8.0), Vector3(0.0, 1.2, -8.0), Vector3(8.0, 1.2, -8.0), Vector3(16.0, 1.2, -8.0)]
	var desk_titles := _service_titles()
	for index in range(desk_positions.size()):
		_add_solid_box("ServiceDesk_%d" % index, desk_positions[index], Vector3(7.0, 2.4, 3.0), desk_mat)
		_add_visual_box("ServiceTerminal_%d" % index, desk_positions[index] + Vector3(0.0, 2.0, -0.3), Vector3(3.6, 1.7, 0.25), screen_mat)
		var label := Label3D.new()
		label.name = "ServiceLabel_%d" % index
		label.text = str(desk_titles[index])
		label.font_size = 24
		label.position = desk_positions[index] + Vector3(0.0, 4.0, -1.2)
		label.pixel_size = 0.014
		label.modulate = Color(0.78, 0.91, 1.0)
		add_child(label)
		if entrance_script != null:
			var service_area: Area3D = entrance_script.new()
			service_area.name = "ServiceInteraction_%d" % index
			service_area.configure("tower_service_" + tower_id + "_" + str(index), str(desk_titles[index]), "region_baghdad")
			service_area.set_meta("system_service_description", "نقطة معلومات وخدمة أولية في بهو البرج؛ ربط الخدمة التشغيلية الكاملة قيد التطوير.")
			service_area.set_meta("system_interaction_prompt", "استعراض " + str(desk_titles[index]))
			var service_collision := CollisionShape3D.new()
			var service_shape := SphereShape3D.new()
			service_shape.radius = 3.0
			service_collision.shape = service_shape
			service_area.add_child(service_collision)
			service_area.position = desk_positions[index] + Vector3(0.0, 1.5, 3.0)
			add_child(service_area)

func _service_titles() -> Array[String]:
	match tower_id:
		"business_tower_baghdad":
			return ["استشارات الأعمال", "مكاتب الاستثمار", "خدمات الشركات"]
		"shopping_tower_baghdad":
			return ["سوق بغداد", "المتاجر والمشتريات", "حقيبة المقتنيات", "معرض الأسلحة", "مختبر جرعات إيقاظ النِن"]
		"entertainment_tower_baghdad":
			return ["الفعاليات", "الرياضة والترفيه", "حجز الأنشطة"]
		"technology_tower_baghdad":
			return ["مختبر الابتكار", "مركز التقنية", "معرض الاختراعات"]
		_:
			return ["تسجيل الصيادين", "لوحة المهام", "معلومات النقابة"]

func _build_exit() -> void:
	if entrance_script == null:
		return
	var exit_area: Area3D = entrance_script.new()
	exit_area.name = "TowerLobbyExit"
	exit_area.configure("tower_exit_" + tower_id, "الخروج من " + display_title, "region_baghdad")
	exit_area.position = Vector3(0.0, 1.4, 18.0)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.5
	collision.shape = shape
	exit_area.add_child(collision)
	add_child(exit_area)

func _add_solid_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_visual_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	add_child(visual)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


func _build_tower_identity_feature() -> void:
	var accent_color := Color(0.08, 0.62, 0.92)
	var feature_title := "SYSTEM"
	match tower_id:
		"hunter_association_tower_baghdad":
			accent_color = Color(0.08, 0.62, 0.92)
			feature_title = "HUNTER MISSION CORE"
		"business_tower_baghdad":
			accent_color = Color(0.24, 0.78, 0.72)
			feature_title = "BUSINESS & INVESTMENT"
		"shopping_tower_baghdad":
			accent_color = Color(0.95, 0.72, 0.28)
			feature_title = "WEAPON ARMORY & NEN AWAKENING"
		"entertainment_tower_baghdad":
			accent_color = Color(0.75, 0.38, 0.95)
			feature_title = "EVENTS & ARENA HUB"
		"technology_tower_baghdad":
			accent_color = Color(0.18, 0.88, 0.78)
			feature_title = "INNOVATION CORE"
	var accent := _material(accent_color, 0.24, 0.48)
	accent.emission_enabled = true
	accent.emission = accent_color * 0.38
	accent.emission_energy_multiplier = 1.2
	var dark := _material(Color(0.025, 0.055, 0.085), 0.32, 0.58)
	_add_visual_box("TowerIdentityFeatureBase", Vector3(0.0, 0.12, 1.0), Vector3(12.0, 0.22, 7.0), dark)
	_add_visual_box("TowerIdentityFeatureScreen", Vector3(0.0, 5.2, -1.0), Vector3(10.0, 7.0, 0.45), accent)
	_add_visual_box("TowerIdentityFeatureHeader", Vector3(0.0, 9.2, -0.72), Vector3(11.0, 0.28, 0.24), accent)
	var title := Label3D.new()
	title.name = "TowerIdentityFeatureTitle"
	title.text = feature_title
	title.font_size = 25
	title.position = Vector3(0.0, 10.1, -0.55)
	title.pixel_size = 0.012
	title.modulate = accent_color.lightened(0.25)
	add_child(title)
	for index in range(3):
		var marker := MeshInstance3D.new()
		marker.name = "FeatureStatusMarker_%d" % index
		var marker_mesh := SphereMesh.new()
		marker_mesh.radius = 0.28
		marker_mesh.height = 0.56
		marker.mesh = marker_mesh
		marker.position = Vector3(-3.0 + float(index) * 3.0, 2.4, -0.65)
		marker.material_override = accent
		add_child(marker)


func _build_lobby_wayfinding() -> void:
	var gold := _material(Color(0.78, 0.57, 0.25), 0.28, 0.72)
	var cyan := _material(Color(0.06, 0.56, 0.78), 0.24, 0.42)
	cyan.emission_enabled = true
	cyan.emission = Color(0.02, 0.32, 0.62)
	cyan.emission_energy_multiplier = 1.0
	for side in [-1.0, 1.0]:
		_add_solid_box("LobbyWayfindingPillar_%s" % str(int(side)), Vector3(side * 17.5, 6.0, 12.0), Vector3(1.2, 12.0, 1.2), gold)
		_add_visual_box("LobbyWayfindingLight_%s" % str(int(side)), Vector3(side * 17.5, 10.0, 11.3), Vector3(0.16, 6.0, 0.12), cyan)
	var direction := Label3D.new()
	direction.name = "LobbyWayfindingSign"
	direction.text = "معلومات وخدمات البرج  ←     →  المخرج"
	direction.font_size = 22
	direction.position = Vector3(0.0, 12.0, 16.0)
	direction.pixel_size = 0.012
	direction.modulate = Color(0.72, 0.9, 1.0)
	add_child(direction)


func _build_upper_floor_access() -> void:
	var floor_material := _material(Color(0.13, 0.19, 0.25), 0.38, 0.52)
	var edge_material := _material(Color(0.06, 0.55, 0.78), 0.24, 0.42)
	edge_material.emission_enabled = true
	edge_material.emission = Color(0.02, 0.32, 0.58)
	edge_material.emission_energy_multiplier = 1.1
	# Continuous visual lift shaft, with paired illuminated guide rails.
	_add_visual_box("LiftShaftGuide_Left", Vector3(8.0, 36.0, 12.0), Vector3(0.35, 72.0, 0.35), edge_material)
	_add_visual_box("LiftShaftGuide_Right", Vector3(12.0, 36.0, 12.0), Vector3(0.35, 72.0, 0.35), edge_material)
	var floor_titles := ["الطابق 02 — الخدمات", "الطابق 03 — المرافق", "الطابق 04 — الإدارة", "الطابق 05 — المنصة العليا"]
	for index in range(4):
		var floor_number := index + 2
		var floor_y := 18.0 * float(floor_number - 1)
		_add_solid_box("UpperFloor_%02d" % floor_number, Vector3(0.0, floor_y, 0.0), Vector3(38.0, 0.8, 38.0), floor_material)
		_add_visual_box("UpperFloorIdentityBand_%02d" % floor_number, Vector3(0.0, floor_y + 0.48, -17.0), Vector3(24.0, 0.18, 0.22), edge_material)
		var floor_label := Label3D.new()
		floor_label.name = "UpperFloorLabel_%02d" % floor_number
		floor_label.text = str(floor_titles[index])
		floor_label.font_size = 26
		floor_label.position = Vector3(0.0, floor_y + 4.0, -16.5)
		floor_label.pixel_size = 0.014
		floor_label.modulate = Color(0.76, 0.91, 1.0)
		add_child(floor_label)
		_add_solid_box("LiftLandingMarker_%02d" % floor_number, Vector3(14.0, floor_y + 1.2, 12.0), Vector3(5.0, 2.4, 4.0), floor_material)
		_add_visual_box("LiftDoor_Left_%02d" % floor_number, Vector3(9.0, floor_y + 4.0, 11.6), Vector3(1.8, 7.0, 0.22), edge_material)
		_add_visual_box("LiftDoor_Right_%02d" % floor_number, Vector3(11.0, floor_y + 4.0, 11.6), Vector3(1.8, 7.0, 0.22), edge_material)
		_build_floor_theme(floor_number, floor_y, floor_material, edge_material)
		_create_floor_selector(floor_number, floor_y)
		_create_lobby_floor_selector(floor_number, floor_y)


func _build_lift_console() -> void:
	if entrance_script == null:
		return
	var console_material := _material(Color(0.035, 0.09, 0.14), 0.28, 0.62)
	var screen_material := _material(Color(0.04, 0.58, 0.82), 0.2, 0.38)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.02, 0.34, 0.72)
	screen_material.emission_energy_multiplier = 1.5
	_add_solid_box("CentralLiftConsole", Vector3(0.0, 1.5, 3.0), Vector3(5.0, 3.0, 1.2), console_material)
	_add_visual_box("CentralLiftConsoleScreen", Vector3(0.0, 2.2, 2.35), Vector3(4.0, 1.4, 0.12), screen_material)
	var label := Label3D.new()
	label.name = "CentralLiftConsoleLabel"
	label.text = "مصعد البرج\nاختيار جميع الطوابق"
	label.font_size = 21
	label.position = Vector3(0.0, 5.0, 2.3)
	label.pixel_size = 0.012
	label.modulate = Color(0.8, 0.94, 1.0)
	add_child(label)
	var area: Area3D = entrance_script.new()
	area.name = "CentralLiftConsoleInteraction"
	area.configure("tower_lift_console_" + tower_id, "اختيار طابق في " + display_title, "region_baghdad")
	area.set_meta("system_tower_id", tower_id)
	area.set_meta("system_tower_title", display_title)
	area.set_meta("system_tower_floor_count", floor_count)
	area.set_meta("system_interaction_prompt", "فتح قائمة طوابق البرج")
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.0
	collision.shape = shape
	area.add_child(collision)
	area.position = Vector3(0.0, 1.5, 4.5)
	add_child(area)



func _build_elevator_cabin() -> void:
	var cabin_material := _material(Color(0.12, 0.18, 0.24), 0.28, 0.72)
	var glass_material := _material(Color(0.035, 0.34, 0.48), 0.2, 0.42)
	glass_material.emission_enabled = true
	glass_material.emission = Color(0.02, 0.28, 0.52)
	glass_material.emission_energy_multiplier = 1.3
	var door_material := _material(Color(0.18, 0.31, 0.39), 0.24, 0.78)
	_lift_cabin = Node3D.new()
	_lift_cabin.name = "AnimatedElevatorCabin"
	_lift_cabin.position = Vector3(10.0, 0.0, 12.0)
	add_child(_lift_cabin)
	_add_cabin_box(_lift_cabin, "CabinFloor", Vector3(0.0, 0.25, 0.0), Vector3(4.4, 0.5, 4.4), cabin_material, true)
	_add_cabin_box(_lift_cabin, "CabinRearWall", Vector3(0.0, 2.8, -2.05), Vector3(4.4, 5.1, 0.22), glass_material, true)
	_add_cabin_box(_lift_cabin, "CabinLeftWall", Vector3(-2.08, 2.8, 0.0), Vector3(0.22, 5.1, 4.0), glass_material, true)
	_add_cabin_box(_lift_cabin, "CabinRightWall", Vector3(2.08, 2.8, 0.0), Vector3(0.22, 5.1, 4.0), glass_material, true)
	_add_cabin_box(_lift_cabin, "CabinCeiling", Vector3(0.0, 5.4, 0.0), Vector3(4.4, 0.25, 4.4), cabin_material, true)
	_lift_door_left = _add_cabin_box(_lift_cabin, "CabinDoorLeft", Vector3(-1.0, 2.8, 2.05), Vector3(1.95, 5.0, 0.18), door_material, false)
	_lift_door_right = _add_cabin_box(_lift_cabin, "CabinDoorRight", Vector3(1.0, 2.8, 2.05), Vector3(1.95, 5.0, 0.18), door_material, false)
	var status := Label3D.new()
	status.name = "ElevatorFloorIndicator"
	status.text = "SYSTEM LIFT — 001"
	status.font_size = 24
	status.position = Vector3(0.0, 4.85, 1.88)
	status.pixel_size = 0.012
	status.modulate = Color(0.82, 0.95, 1.0)
	_lift_cabin.add_child(status)
	_lift_status_label = status
	var cabin_light := OmniLight3D.new()
	cabin_light.name = "ElevatorCabinLight"
	cabin_light.position = Vector3(0.0, 4.7, 0.0)
	cabin_light.light_color = Color(0.34, 0.72, 1.0)
	cabin_light.light_energy = 1.0
	cabin_light.omni_range = 8.0
	cabin_light.shadow_enabled = false
	_lift_cabin.add_child(cabin_light)


func _add_cabin_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, with_collision: bool) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	parent.add_child(visual)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "_Collision"
		body.position = position
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
	return visual


func animate_lift_to_floor(floor_number: int) -> bool:
	if floor_number < 1 or floor_number > floor_count or _elevator_traveling:
		return false
	if not is_instance_valid(_lift_cabin) or not is_instance_valid(_lift_door_left) or not is_instance_valid(_lift_door_right):
		return false
	_elevator_traveling = true
	var target_height := minf(float(floor_number - 1) * 18.0, 72.0)
	var travel_duration := clampf(absf(_lift_cabin.position.y - target_height) / 36.0, 0.35, 1.6)
	var travel_tween := create_tween()
	travel_tween.set_trans(Tween.TRANS_SINE)
	travel_tween.set_ease(Tween.EASE_IN_OUT)
	travel_tween.tween_property(_lift_cabin, "position:y", target_height, travel_duration)
	await travel_tween.finished
	if is_instance_valid(_lift_status_label):
		_lift_status_label.text = "SYSTEM LIFT — %03d" % floor_number
	var open_tween := create_tween()
	open_tween.set_trans(Tween.TRANS_SINE)
	open_tween.set_ease(Tween.EASE_OUT)
	open_tween.tween_property(_lift_door_left, "position:x", -1.85, 0.28)
	open_tween.parallel().tween_property(_lift_door_right, "position:x", 1.85, 0.28)
	await open_tween.finished
	var close_tween := create_tween()
	close_tween.set_trans(Tween.TRANS_SINE)
	close_tween.set_ease(Tween.EASE_IN)
	close_tween.tween_property(_lift_door_left, "position:x", -1.0, 0.28)
	close_tween.parallel().tween_property(_lift_door_right, "position:x", 1.0, 0.28)
	await close_tween.finished
	_elevator_traveling = false
	return true


func _build_emergency_stairwell() -> void:
	var step_material := _material(Color(0.16, 0.21, 0.27), 0.46, 0.58)
	var rail_material := _material(Color(0.72, 0.52, 0.22), 0.28, 0.72)
	for floor_number in range(2, 6):
		var floor_y := 18.0 * float(floor_number - 1)
		for flight in range(2):
			for step_index in range(25):
				var step_x := -15.0 if flight == 0 else -9.0
				var step_z := -14.0 + (float(step_index) + 0.5) * 0.6 if flight == 0 else 14.0 - (float(step_index) + 0.5) * 0.6
				var step_y := floor_y - 18.0 + float(flight * 25 + step_index + 1) * 0.36
				_add_solid_box("EmergencyStair_%02d_%02d_%02d" % [floor_number, flight, step_index], Vector3(step_x, step_y, step_z), Vector3(4.6, 0.36, 0.72), step_material)
			var rail_x := -17.6 if flight == 0 else -6.4
			var rail_z := -7.0 if flight == 0 else 7.0
			var rail_y := floor_y - 13.5 + float(flight) * 9.0
			_add_visual_box("EmergencyStairRail_%02d_%02d" % [floor_number, flight], Vector3(rail_x, rail_y, rail_z), Vector3(0.18, 2.2, 15.5), rail_material)
			_add_solid_box("EmergencyStairRailCollision_%02d_%02d" % [floor_number, flight], Vector3(rail_x, rail_y, rail_z), Vector3(0.18, 2.2, 15.5), rail_material)
		_add_solid_box("EmergencyStairLanding_%02d" % floor_number, Vector3(-12.0, floor_y - 9.0, 0.0), Vector3(10.5, 0.7, 4.0), step_material)
		var sign := Label3D.new()
		sign.name = "EmergencyStairSign_%02d" % floor_number
		sign.text = "مخرج طوارئ — الطابق %02d" % floor_number
		sign.font_size = 18
		sign.position = Vector3(-12.0, floor_y - 8.0, 2.2)
		sign.pixel_size = 0.012
		sign.modulate = Color(1.0, 0.72, 0.35)
		add_child(sign)


func _create_floor_selector(floor_number: int, floor_y: float) -> void:
	if entrance_script == null:
		return
	var area: Area3D = entrance_script.new()
	area.name = "LiftFloorSelector_%02d" % floor_number
	var floor_title := "الطابق %02d" % floor_number
	area.configure("tower_floor_%s_%02d" % [tower_id, floor_number], "الانتقال إلى " + floor_title, "region_baghdad")
	area.set_meta("system_destination_position", to_global(Vector3(10.0, floor_y + 1.5, 12.0)))
	area.set_meta("system_tower_id", tower_id)
	area.set_meta("system_floor_number", floor_number)
	area.set_meta("system_interaction_prompt", "استخدام المصعد — " + floor_title)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.2
	collision.shape = shape
	area.add_child(collision)
	area.position = Vector3(10.0, floor_y + 1.5, 8.0)
	add_child(area)


func _create_lobby_floor_selector(floor_number: int, floor_y: float) -> void:
	if entrance_script == null:
		return
	var selector_index := floor_number - 2
	var x_position := -15.0 + float(selector_index) * 10.0
	var panel_material := _material(Color(0.035, 0.12, 0.18), 0.24, 0.62)
	var accent_material := _material(Color(0.04, 0.58, 0.82), 0.22, 0.4)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.02, 0.34, 0.72)
	accent_material.emission_energy_multiplier = 1.4
	_add_solid_box("LobbyLiftPanel_%02d" % floor_number, Vector3(x_position, 1.5, 5.0), Vector3(3.4, 3.0, 0.7), panel_material)
	_add_visual_box("LobbyLiftPanelScreen_%02d" % floor_number, Vector3(x_position, 2.0, 4.58), Vector3(2.5, 1.25, 0.12), accent_material)
	var label := Label3D.new()
	label.name = "LobbyLiftPanelLabel_%02d" % floor_number
	label.text = "طابق %02d" % floor_number
	label.font_size = 20
	label.position = Vector3(x_position, 3.4, 4.45)
	label.pixel_size = 0.012
	label.modulate = Color(0.78, 0.94, 1.0)
	add_child(label)
	var area: Area3D = entrance_script.new()
	area.name = "LobbyLiftSelector_%02d" % floor_number
	area.configure("tower_floor_%s_%02d" % [tower_id, floor_number], "المصعد إلى الطابق %02d" % floor_number, "region_baghdad")
	area.set_meta("system_destination_position", to_global(Vector3(10.0, floor_y + 1.5, 12.0)))
	area.set_meta("system_tower_id", tower_id)
	area.set_meta("system_floor_number", floor_number)
	area.set_meta("system_display_name", "مصعد الطابق %02d" % floor_number)
	area.set_meta("system_interaction_prompt", "الانتقال إلى الطابق %02d" % floor_number)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.4
	collision.shape = shape
	area.add_child(collision)
	area.position = Vector3(x_position, 1.5, 6.5)
	add_child(area)


func _build_floor_theme(floor_number: int, floor_y: float, floor_material: Material, accent_material: Material) -> void:
	match tower_id:
		"hunter_association_tower_baghdad":
			_build_hunter_floor(floor_number, floor_y, floor_material, accent_material)
		"business_tower_baghdad":
			_build_business_floor(floor_number, floor_y, floor_material, accent_material)
		"shopping_tower_baghdad":
			_build_shopping_floor(floor_number, floor_y, floor_material, accent_material)
		"entertainment_tower_baghdad":
			_build_entertainment_floor(floor_number, floor_y, floor_material, accent_material)
		"technology_tower_baghdad":
			_build_technology_floor(floor_number, floor_y, floor_material, accent_material)


func _build_hunter_floor(floor_number: int, floor_y: float, base: Material, accent: Material) -> void:
	_add_solid_box("HunterBriefingTable_%02d" % floor_number, Vector3(-8.0, floor_y + 1.5, -5.0), Vector3(12.0, 1.0, 5.0), base)
	_add_visual_box("HunterMissionBoard_%02d" % floor_number, Vector3(0.0, floor_y + 6.0, -17.0), Vector3(15.0, 7.0, 0.4), accent)
	_add_visual_box("HunterHallOfHonor_%02d" % floor_number, Vector3(0.0, floor_y + 4.0, 16.0), Vector3(18.0, 5.0, 0.5), base)


func _build_business_floor(floor_number: int, floor_y: float, base: Material, accent: Material) -> void:
	for index in range(3):
		var x := -11.0 + float(index) * 11.0
		_add_solid_box("BusinessOfficePod_%02d_%d" % [floor_number, index], Vector3(x, floor_y + 1.5, -7.0), Vector3(8.0, 3.0, 8.0), base)
		_add_visual_box("BusinessDisplay_%02d_%d" % [floor_number, index], Vector3(x, floor_y + 5.0, -11.0), Vector3(6.0, 2.8, 0.25), accent)
	_add_solid_box("InvestmentConferenceTable_%02d" % floor_number, Vector3(0.0, floor_y + 1.2, 8.0), Vector3(15.0, 0.8, 4.0), base)


func _build_shopping_floor(floor_number: int, floor_y: float, base: Material, accent: Material) -> void:
	for index in range(4):
		var x := -12.0 + float(index) * 8.0
		_add_solid_box("MarketKiosk_%02d_%d" % [floor_number, index], Vector3(x, floor_y + 1.5, -7.0), Vector3(5.0, 3.0, 6.0), base)
		_add_visual_box("MarketCanopy_%02d_%d" % [floor_number, index], Vector3(x, floor_y + 3.5, -7.0), Vector3(5.8, 0.35, 6.8), accent)
	_add_solid_box("MarketServiceIsland_%02d" % floor_number, Vector3(0.0, floor_y + 1.0, 10.0), Vector3(12.0, 2.0, 4.0), base)


func _build_entertainment_floor(floor_number: int, floor_y: float, base: Material, accent: Material) -> void:
	_add_solid_box("EntertainmentStage_%02d" % floor_number, Vector3(0.0, floor_y + 1.0, -12.0), Vector3(18.0, 2.0, 7.0), base)
	for row in range(3):
		_add_solid_box("EntertainmentAudienceTier_%02d_%d" % [floor_number, row], Vector3(0.0, floor_y + 1.0 + float(row) * 1.2, 3.0 + float(row) * 4.0), Vector3(22.0 - float(row) * 2.0, 1.0, 2.0), base)
	_add_visual_box("EntertainmentEventDisplay_%02d" % floor_number, Vector3(0.0, floor_y + 6.0, -16.0), Vector3(14.0, 6.0, 0.3), accent)


func _build_technology_floor(floor_number: int, floor_y: float, base: Material, accent: Material) -> void:
	for index in range(3):
		var x := -10.0 + float(index) * 10.0
		_add_solid_box("InnovationWorkbench_%02d_%d" % [floor_number, index], Vector3(x, floor_y + 1.2, -5.0), Vector3(7.0, 1.2, 5.0), base)
		_add_visual_box("InnovationDisplay_%02d_%d" % [floor_number, index], Vector3(x, floor_y + 4.0, -8.0), Vector3(5.0, 3.0, 0.25), accent)
	_add_solid_box("PrototypePresentationPod_%02d" % floor_number, Vector3(0.0, floor_y + 1.0, 10.0), Vector3(10.0, 2.0, 8.0), base)
