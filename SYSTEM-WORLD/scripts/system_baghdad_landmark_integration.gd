extends Node3D
class_name SYSTEMBaghdadLandmarkIntegration

## Baghdad civic, sport and exploration landmark layer.
## Attached to ModernWorldRegionManager; all positions are local to Baghdad's real-world anchor.
## Existing five landmark towers and hunter HQ remain owned by their original managers.

const WORLD_ID := "2"
const REGION_ID := "region_baghdad"
const ROAD_WIDTH := 12.0

var terrain: Node
var map_manager: Node
var _registered := false
var _hunter_exam_tunnel_root: Node3D
var _hunter_exam_stage_one_root: Node3D
var _sites: Array[Dictionary] = [
	{"id":"hunter_exam_tunnel_start_baghdad","name":"نفق اختبار الصيادين","kind":"tunnel","offset":Vector2(0.0,245.0),"size":Vector3(42.0,12.0,28.0),"color":Color(0.10,0.19,0.27),"prompt":"دخول نفق اختبار الصيادين"},
	{"id":"hunter_exam_stage_one_course_baghdad","name":"مسار المطاردة والتحمل","kind":"exam_stage_one","offset":Vector2(0.0,380.0),"size":Vector3(120.0,8.0,180.0),"color":Color(0.12,0.28,0.19),"prompt":"بدء مسار المرحلة الأولى"},
	{"id":"hunter_exam_public_notice_baghdad","name":"إعلان اختبار الصيادين العام","kind":"advertising","offset":Vector2(0.0,90.0),"size":Vector3(32.0,20.0,10.0),"color":Color(0.08,0.35,0.48),"prompt":"عرض إعلان اختبار الصيادين ومراحله"},
	{"id":"baghdad_archaeological_ruins","name":"موقع الآثار التاريخية في بغداد","kind":"ruins","offset":Vector2(-115.0,-85.0),"size":Vector3(48.0,7.0,38.0),"color":Color(0.52,0.39,0.24),"prompt":"استكشاف موقع الآثار التاريخية"}
]

func build(p_terrain: Node) -> void:
	terrain = p_terrain
	name = "SYSTEMBaghdadLandmarkIntegration"
	if terrain == null or not terrain.has_method("get_terrain_height"):
		push_warning("SYSTEM Baghdad integration: terrain provider unavailable.")
		return
	_build_connected_roads()
	for site in _sites:
		_build_site(site)
	if _hunter_exam_tunnel_root != null and _hunter_exam_stage_one_root != null:
		_add_road_segment("HunterExamTunnelToStageOneRoad", Vector2(0.0,259.0), Vector2(0.0,305.0))
	set_meta("baghdad_landmarks_integrated", true)

func register_map_locations(p_map_manager: Node, world_id: String = WORLD_ID) -> void:
	map_manager = p_map_manager
	if map_manager == null or not map_manager.has_method("register_location") or _registered:
		return
	for site in _sites:
		var point := _site_position(site)
		map_manager.call("register_location", world_id, str(site["id"]), REGION_ID, str(site["name"]), 5, point, false)
	map_manager.call("register_location", world_id, "baghdad_international_motorsport_park", REGION_ID, "مضمار بغداد الدولي للسيارات", 5, _world_point(Vector2(320.0,220.0)), false)
	_registered = true

func _tower_offset(index: int) -> Vector2:
	var angle := TAU * float(index) / 5.0 - PI * 0.5
	return Vector2(cos(angle), sin(angle)) * 135.0

func _world_point(offset: Vector2) -> Vector3:
	var city_origin := Vector3.ZERO
	var region_manager := get_parent()
	if region_manager != null and region_manager.has_method("get_city_anchor"):
		city_origin = region_manager.call("get_city_anchor", "Baghdad")
	var x := city_origin.x + offset.x
	var z := city_origin.z + offset.y
	return Vector3(x, float(terrain.call("get_terrain_height", x, z)), z)

func _site_position(site: Dictionary) -> Vector3:
	return _world_point(site["offset"])

func _build_connected_roads() -> void:
	var hub := Vector2.ZERO
	var road_points: Array[Vector2] = [hub]
	for site in _sites:
		road_points.append(site["offset"])
	var region_parent: Node = get_parent()
	var origin_position: Vector3 = Vector3.ZERO
	if region_parent != null and region_parent.has_method("get_city_anchor"):
		origin_position = region_parent.call("get_city_anchor", "Baghdad")
	var services: Node = region_parent.get_node_or_null("ModernCityServicesManager") if region_parent != null else null
	if services != null and services.has_method("get_service_locations"):
		for service_data in services.call("get_service_locations"):
			if str(service_data.get("city", "")) != "Baghdad":
				continue
			var service_position: Vector3 = service_data["position"]
			road_points.append(Vector2(service_position.x - origin_position.x, service_position.z - origin_position.z))
	# Connect the existing motorsport circuit rather than creating a duplicate track.
	road_points.append(Vector2(320.0,220.0))
	# The Power Tower remains a separate landmark, outside the five-tower cluster.
	# Use its resolved placement from the existing tower manager so a terrain
	# fallback cannot leave the connecting road pointing at the unadjusted anchor.
	var tower_manager: Node = region_parent.get_node_or_null("BaghdadTowerLandmarksManager") if region_parent != null else null
	var power_tower_added := false
	if tower_manager != null and tower_manager.has_method("get_tower_positions"):
		for tower_data in tower_manager.call("get_tower_positions"):
			if str(tower_data.get("id", "")) != "power_tower_baghdad":
				continue
			var tower_position: Vector3 = tower_data.get("position", Vector3.INF)
			if tower_position != Vector3.INF:
				road_points.append(Vector2(tower_position.x - origin_position.x, tower_position.z - origin_position.z))
				power_tower_added = true
			break
	if not power_tower_added:
		road_points.append(Vector2(850.0,600.0))
	for index in range(1, road_points.size()):
		_add_road_segment("BaghdadRoad_%02d" % index, road_points[0], road_points[index])
	# A perimeter connector makes the landmark district navigable as one loop.
	for index in range(1, road_points.size() - 1):
		_add_road_segment("BaghdadLoopRoad_%02d" % index, road_points[index], road_points[index + 1])

func _add_road_segment(node_name: String, start: Vector2, finish: Vector2) -> void:
	var delta := finish - start
	var length := delta.length()
	if length < 1.0:
		return
	var midpoint := (start + finish) * 0.5
	var road := MeshInstance3D.new()
	road.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(ROAD_WIDTH, 0.24, length)
	road.mesh = mesh
	road.position = _world_point(midpoint)
	road.position.y += 0.12
	road.rotation.y = -atan2(delta.x, delta.y)
	road.material_override = _material(Color(0.075,0.085,0.095),0.95,0.0)
	add_child(road)

func _build_site(site: Dictionary) -> void:
	var kind := str(site["kind"])
	var root := Node3D.new()
	root.name = str(site["id"])
	root.position = _site_position(site)
	add_child(root)
	if kind == "tunnel":
		_hunter_exam_tunnel_root = root
	elif kind == "exam_stage_one":
		_hunter_exam_stage_one_root = root
	match kind:
		"stadium": _build_stadium(root, site)
		"motorsport": _build_motorsport(root, site)
		"tunnel": _build_tunnel(root, site)
		"exam_stage_one": _build_exam_stage_one(root, site)
		"power_tower": _build_power_tower(root, site)
		"advertising": _build_advertising(root, site)
		"ruins": _build_ruins(root, site)
		_: _build_civic_building(root, site)
	_build_interaction(root, site)

func _build_civic_building(root: Node3D, site: Dictionary) -> void:
	var size: Vector3 = site["size"]
	var stone := _material(site["color"],0.78,0.12)
	var trim := _material(Color(0.76,0.62,0.34),0.38,0.48)
	_add_box(root,"MainStructure",Vector3(0.0,size.y*0.5,0.0),Vector3(size.x,size.y,size.z),stone,true)
	_add_box(root,"EntranceCanopy",Vector3(0.0,3.5,-size.z*0.5-4.0),Vector3(size.x*0.42,1.0,8.0),trim,false)
	if str(site["kind"]) == "mosque":
		_add_cylinder(root,"MainDome",Vector3(0.0,size.y+5.0,0.0),size.x*0.22,size.x*0.22,10.0,trim)
		for side in [-1.0,1.0]:
			_add_cylinder(root,"Minaret_%s" % str(side),Vector3(side*size.x*0.36,size.y+12.0,0.0),2.0,1.2,24.0,trim)
	elif str(site["kind"]) == "church":
		_add_cylinder(root,"ChurchBellTower",Vector3(0.0,size.y+7.0,-size.z*0.28),3.0,1.0,14.0,trim)
		_add_cylinder(root,"ChurchSpire",Vector3(0.0,size.y+18.0,-size.z*0.28),1.8,0.0,10.0,trim)
	elif str(site["kind"]) == "museum":
		for i in range(4):
			_add_box(root,"MuseumPillar_%02d" % i,Vector3(-size.x*0.36+float(i)*size.x*0.24, size.y*0.5, -size.z*0.5-0.8),Vector3(2.2,size.y,2.2),trim,false)
	elif str(site["kind"]) == "market":
		for i in range(5):
			_add_box(root,"MarketAwning_%02d" % i,Vector3(-size.x*0.38+float(i)*size.x*0.19,9.0,0.0),Vector3(10.0,0.5,size.z*0.78),trim,false)
	_add_sign(root,str(site["name"]),Vector3(0.0,size.y+5.0,-size.z*0.5-2.0))

func _build_stadium(root: Node3D, site: Dictionary) -> void:
	var size: Vector3 = site["size"]
	_add_box(root,"Pitch",Vector3(0.0,0.25,0.0),Vector3(size.x*0.72,0.5,size.z*0.66),_material(Color(0.12,0.38,0.17),1.0,0.0),false)
	for side in [-1.0,1.0]:
		_add_box(root,"Grandstand_%s" % str(side),Vector3(side*size.x*0.43,8.0,0.0),Vector3(size.x*0.12,16.0,size.z*0.9),_material(Color(0.32,0.34,0.37),0.85,0.0),true)
	_add_sign(root,str(site["name"]),Vector3(0.0,18.0,-size.z*0.5-4.0))

func _build_motorsport(root: Node3D, site: Dictionary) -> void:
	var size: Vector3 = site["size"]
	var track_material := _material(Color(0.055,0.06,0.07),0.96,0.0)
	var safety := _material(Color(0.82,0.19,0.12),0.72,0.0)
	_add_box(root,"TrackSurface",Vector3(0.0,0.18,0.0),Vector3(size.x,size.y*0.04,size.z),track_material,false)
	for x in [-1.0,1.0]:
		_add_box(root,"SafetyBarrier_%s" % str(x),Vector3(x*size.x*0.48,1.1,0.0),Vector3(2.0,2.2,size.z),safety,true)
	for z in [-1.0,1.0]:
		_add_box(root,"SafetyBarrierZ_%s" % str(z),Vector3(0.0,1.1,z*size.z*0.48),Vector3(size.x,2.2,2.0),safety,true)
	_add_sign(root,str(site["name"]),Vector3(0.0,7.0,-size.z*0.5-8.0))

func _build_tunnel(root: Node3D, site: Dictionary) -> void:
	var size: Vector3 = site["size"]
	var dark := _material(Color(0.025,0.045,0.065),0.45,0.2)
	var glow := _material(Color(0.04,0.52,0.76),0.28,0.25)
	glow.emission_enabled = true
	glow.emission = Color(0.02,0.28,0.62)
	var gate_frame := _material(Color(0.12,0.20,0.28),0.32,0.68)
	var gate_accent := _material(Color(0.82,0.58,0.24),0.26,0.72)
	gate_accent.emission_enabled = true
	gate_accent.emission = Color(0.34,0.18,0.035)
	gate_accent.emission_energy_multiplier = 0.8
	var access_barrier := _material(Color(0.48,0.08,0.07),0.42,0.38)
	_add_box(root,"TunnelFloor",Vector3(0.0,0.0,0.0),Vector3(size.x-6.0,0.8,size.z),dark,true)
	_add_box(root,"TunnelLeftWall",Vector3(-size.x*0.5,5.0,0.0),Vector3(3.0,10.0,size.z),dark,true)
	_add_box(root,"TunnelRightWall",Vector3(size.x*0.5,5.0,0.0),Vector3(3.0,10.0,size.z),dark,true)
	_add_box(root,"TunnelRoof",Vector3(0.0,10.0,0.0),Vector3(size.x,2.0,size.z),dark,true)
	_add_box(root,"TunnelPortalGlow",Vector3(0.0,5.0,-size.z*0.5),Vector3(size.x*0.76,9.0,0.6),glow,false)
	_add_sign(root,str(site["name"]),Vector3(0.0,14.0,-size.z*0.5-3.0))

	var access_gate := Node3D.new()
	access_gate.name = "CandidateAccessGate"
	root.add_child(access_gate)
	_add_box(access_gate,"CandidateAccessBarrier",Vector3(0.0,size.y*0.36,-size.z*0.31),Vector3(size.x-3.0,size.y*0.65,0.8),access_barrier,true)
	access_gate.set_meta("candidate_access_open",false)

	for stage_index in range(7):
		var stage_number := stage_index + 1
		var stage_gate := Node3D.new()
		stage_gate.name = "StageGate_%02d" % stage_number
		stage_gate.position.z = -size.z*0.25 + float(stage_index)*(size.z*0.5/6.0)
		root.add_child(stage_gate)
		_add_box(stage_gate,"StageGateLeftPost",Vector3(-17.0,3.7,0.0),Vector3(1.2,7.4,1.2),gate_frame,true)
		_add_box(stage_gate,"StageGateRightPost",Vector3(17.0,3.7,0.0),Vector3(1.2,7.4,1.2),gate_frame,true)
		_add_box(stage_gate,"StageGateHeader",Vector3(0.0,8.0,0.0),Vector3(35.0,1.0,1.2),gate_frame,true)
		_add_box(stage_gate,"StageGateAccent",Vector3(0.0,8.55,0.0),Vector3(30.0,0.12,1.3),gate_accent,false)
		var stage_sign := Label3D.new()
		stage_sign.name = "StageNumberSign_%02d" % stage_number
		stage_sign.text = "بوابة المرحلة %02d" % stage_number
		stage_sign.font_size = 25
		stage_sign.position = Vector3(0.0,8.8,-0.8)
		stage_sign.pixel_size = 0.014
		stage_sign.modulate = Color(0.86,0.94,1.0)
		stage_gate.add_child(stage_sign)
		stage_gate.set_meta("hunter_exam_stage_number",stage_number)

	for light_index in range(5):
		var tunnel_light := OmniLight3D.new()
		tunnel_light.name = "TunnelCeilingLight_%02d" % light_index
		tunnel_light.position = Vector3(0.0,8.8,-size.z*0.38+float(light_index)*(size.z*0.19))
		tunnel_light.light_color = Color(0.24,0.66,1.0)
		tunnel_light.light_energy = 1.15
		tunnel_light.omni_range = 10.0
		tunnel_light.shadow_enabled = false
		root.add_child(tunnel_light)
	_add_box(root,"TunnelFloorGuideLine",Vector3(0.0,0.43,0.0),Vector3(0.28,0.08,size.z*0.82),gate_accent,false)
	root.set_meta("hunter_exam_stage_gate_count",7)
	root.set_meta("candidate_access_enabled",false)


func set_hunter_exam_tunnel_access(enabled: bool) -> void:
	if _hunter_exam_tunnel_root == null:
		return
	var access_gate := _hunter_exam_tunnel_root.get_node_or_null("CandidateAccessGate")
	var barrier_mesh := access_gate.get_node_or_null("CandidateAccessBarrier") as MeshInstance3D if access_gate != null else null
	var barrier_body := access_gate.get_node_or_null("CandidateAccessBarrierCollision") as StaticBody3D if access_gate != null else null
	var barrier_shape := barrier_body.get_node_or_null("CollisionShape3D") as CollisionShape3D if barrier_body != null else null
	if barrier_mesh == null or barrier_shape == null:
		push_warning("SYSTEM Hunter tunnel: candidate access barrier is incomplete.")
		return
	barrier_mesh.visible = not enabled
	barrier_shape.disabled = enabled
	access_gate.set_meta("candidate_access_open",enabled)
	_hunter_exam_tunnel_root.set_meta("candidate_access_enabled",enabled)


func _build_exam_stage_one(root: Node3D, site: Dictionary) -> void:
	var size: Vector3 = site["size"]
	var ground_material := _material(Color(0.11,0.17,0.14),0.92,0.0)
	var route_material := _material(Color(0.055,0.065,0.07),0.96,0.0)
	var edge_material := _material(Color(0.86,0.62,0.22),0.42,0.5)
	var frame_material := _material(Color(0.07,0.15,0.21),0.34,0.62)
	_add_box(root,"StageOneCourseGround",Vector3(0.0,-0.35,0.0),Vector3(size.x,0.7,size.z),ground_material,true)
	var route_points: Array[Vector2] = [
		Vector2(0.0,-75.0),
		Vector2(0.0,-25.0),
		Vector2(35.0,10.0),
		Vector2(0.0,45.0),
		Vector2(-20.0,75.0)
	]
	for segment_index in range(1,route_points.size()):
		_add_exam_course_segment(root,"StageOneRoute_%02d" % segment_index,route_points[segment_index-1],route_points[segment_index],10.0,route_material)
		_add_exam_course_edge(root,"StageOneRouteEdge_%02d" % segment_index,route_points[segment_index-1],route_points[segment_index],5.8,edge_material)
	_add_exam_stage_marker(root,"StageOneStartGate","بداية المرحلة الأولى",route_points[0],"hunter_exam_stage_one_start_baghdad","")
	_add_exam_stage_marker(root,"StageOneCheckpoint_01","نقطة التتبع الأولى",route_points[1],"hunter_exam_stage_one_checkpoint_01_baghdad","checkpoint_01")
	_add_exam_stage_marker(root,"StageOneCheckpoint_02","نقطة التتبع الثانية",route_points[2],"hunter_exam_stage_one_checkpoint_02_baghdad","checkpoint_02")
	_add_exam_stage_marker(root,"StageOneCheckpoint_03","نقطة التتبع الثالثة",route_points[3],"hunter_exam_stage_one_checkpoint_03_baghdad","checkpoint_03")
	_add_exam_stage_marker(root,"StageOneFinishGate","نهاية مسار التحمل",route_points[4],"hunter_exam_stage_one_finish_baghdad","")
	_add_sign(root,"المرحلة الأولى — المطاردة والتحمل",Vector3(0.0,9.0,-size.z*0.5+4.0))
	var safety_notice := Label3D.new()
	safety_notice.name = "StageOneCivilianSafetyNotice"
	safety_notice.text = "حافظ على سلامة المدنيين — تجنب المخالفات"
	safety_notice.font_size = 22
	safety_notice.position = Vector3(0.0,5.0,0.0)
	safety_notice.pixel_size = 0.014
	safety_notice.modulate = Color(0.92,0.82,0.58)
	root.add_child(safety_notice)
	root.set_meta("hunter_exam_stage_id","endurance_pursuit")
	root.set_meta("hunter_exam_checkpoint_count",3)


func _add_exam_course_segment(parent: Node3D, node_name: String, start: Vector2, finish: Vector2, width: float, material: Material) -> void:
	var delta := finish - start
	var length := delta.length()
	if length < 1.0:
		return
	var midpoint := (start + finish) * 0.5
	var angle := -atan2(delta.x,delta.y)
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width,0.24,length)
	mesh_node.mesh = mesh
	mesh_node.position = Vector3(midpoint.x,0.18,midpoint.y)
	mesh_node.rotation.y = angle
	mesh_node.material_override = material
	parent.add_child(mesh_node)
	var body := StaticBody3D.new()
	body.name = node_name + "Collision"
	body.position = mesh_node.position
	body.rotation.y = angle
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(width,0.24,length)
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _add_exam_course_edge(parent: Node3D, node_name: String, start: Vector2, finish: Vector2, offset: float, material: Material) -> void:
	var delta := finish - start
	if delta.length() < 1.0:
		return
	var side := Vector2(delta.y,-delta.x).normalized() * offset
	for side_index in [-1.0,1.0]:
		var edge_start: Vector2 = start + side * float(side_index)
		var edge_finish: Vector2 = finish + side * float(side_index)
		var edge_delta: Vector2 = edge_finish - edge_start
		var midpoint: Vector2 = (edge_start + edge_finish) * 0.5
		var edge := MeshInstance3D.new()
		edge.name = node_name + ("_Left" if side_index < 0.0 else "_Right")
		var edge_mesh := BoxMesh.new()
		edge_mesh.size = Vector3(0.35,0.18,edge_delta.length())
		edge.mesh = edge_mesh
		edge.position = Vector3(midpoint.x,0.36,midpoint.y)
		edge.rotation.y = -atan2(edge_delta.x,edge_delta.y)
		edge.material_override = material
		parent.add_child(edge)


func _add_exam_stage_marker(parent: Node3D, node_name: String, title: String, local_position: Vector2, location_id: String, checkpoint_id: String) -> void:
	var marker_root := Node3D.new()
	marker_root.name = node_name
	marker_root.position = Vector3(local_position.x,0.0,local_position.y)
	parent.add_child(marker_root)
	var frame_material := _material(Color(0.07,0.15,0.21),0.34,0.62)
	var accent_material := _material(Color(0.08,0.54,0.78),0.24,0.45)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.02,0.24,0.48)
	_add_box(marker_root,"MarkerLeftPost",Vector3(-5.0,3.5,0.0),Vector3(0.9,7.0,0.9),frame_material,true)
	_add_box(marker_root,"MarkerRightPost",Vector3(5.0,3.5,0.0),Vector3(0.9,7.0,0.9),frame_material,true)
	_add_box(marker_root,"MarkerHeader",Vector3(0.0,7.2,0.0),Vector3(10.8,0.9,0.9),frame_material,true)
	_add_box(marker_root,"MarkerAccent",Vector3(0.0,7.72,0.0),Vector3(8.8,0.12,1.0),accent_material,false)
	var sign := Label3D.new()
	sign.name = "MarkerSign"
	sign.text = title
	sign.font_size = 23
	sign.position = Vector3(0.0,8.5,-0.7)
	sign.pixel_size = 0.013
	sign.modulate = Color(0.84,0.94,1.0)
	marker_root.add_child(sign)
	var interaction := Area3D.new()
	interaction.name = "StageMarkerInteraction"
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_location_id",location_id)
	interaction.set_meta("system_region_id",REGION_ID)
	interaction.set_meta("system_display_name",title)
	interaction.set_meta("system_location_type",5)
	interaction.set_meta("system_interaction_prompt",title)
	interaction.set_meta("system_city_name","Baghdad")
	interaction.set_meta("system_checkpoint_id",checkpoint_id)
	var area_collision := CollisionShape3D.new()
	area_collision.name = "CollisionShape3D"
	var area_shape := SphereShape3D.new()
	area_shape.radius = 4.5
	area_collision.shape = area_shape
	interaction.add_child(area_collision)
	interaction.position = Vector3(0.0,1.5,0.0)
	marker_root.add_child(interaction)


func _build_power_tower(root: Node3D, site: Dictionary) -> void:
	var size: Vector3 = site["size"]
	var dark := _material(Color(0.035,0.075,0.12),0.32,0.62)
	var cyan := _material(Color(0.04,0.48,0.72),0.22,0.52)
	cyan.emission_enabled = true
	cyan.emission = Color(0.02,0.22,0.52)
	_add_box(root,"IndependentPowerTower",Vector3(0.0,size.y*0.5,0.0),Vector3(size.x,size.y,size.z),dark,true)
	for floor_index in range(1,200):
		var band := MeshInstance3D.new()
		band.name = "FloorBand_%03d" % floor_index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(size.x+0.8,0.35,size.z+0.8)
		band.mesh = mesh
		band.position.y = float(floor_index)*2.4
		band.material_override = cyan if floor_index % 10 == 0 else dark
		root.add_child(band)
	_add_sign(root,"برج القوة — 200 طابق",Vector3(0.0,size.y+8.0,-size.z*0.5-5.0))

func _build_advertising(root: Node3D, site: Dictionary) -> void:
	var frame := _material(Color(0.035,0.06,0.09),0.28,0.65)
	var screen := _material(Color(0.02,0.28,0.42),0.2,0.15)
	screen.emission_enabled = true
	screen.emission = Color(0.02,0.35,0.65)
	screen.emission_energy_multiplier = 1.7
	_add_box(root,"AdvertisingFrame",Vector3(0.0,10.0,0.0),Vector3(26.0,18.0,3.0),frame,true)
	_add_box(root,"PublicInformationScreen",Vector3(0.0,10.0,-1.7),Vector3(23.0,14.0,0.35),screen,false)
	_add_sign(root,"إعلانات وأخبار بغداد",Vector3(0.0,21.0,-2.2))

func _build_ruins(root: Node3D, site: Dictionary) -> void:
	var stone := _material(Color(0.43,0.34,0.24),0.92,0.0)
	var size: Vector3 = site["size"]
	for index in range(7):
		var x := -size.x*0.42 + float(index)*size.x*0.14
		var height := 2.5 + float(index % 3)*1.4
		_add_box(root,"BrokenStoneColumn_%02d" % index,Vector3(x,height*0.5,0.0),Vector3(2.2,height,2.2),stone,true)
	_add_box(root,"RuinedFoundation",Vector3(0.0,0.25,0.0),Vector3(size.x,0.5,size.z),stone,false)
	_add_sign(root,str(site["name"]),Vector3(0.0,9.0,-size.z*0.5-3.0))


func _build_interaction(root: Node3D, site: Dictionary) -> void:
	var area := Area3D.new()
	area.name = "LandmarkInteraction"
	var site_size: Vector3 = site["size"]
	area.position = Vector3(0.0,1.5, -site_size.z*0.5-3.0)
	area.add_to_group("system_interactable")
	area.set_meta("system_location_id",str(site["id"]))
	area.set_meta("system_region_id",REGION_ID)
	area.set_meta("system_display_name",str(site["name"]))
	area.set_meta("system_location_type",5)
	area.set_meta("system_interaction_prompt",str(site["prompt"]))
	area.set_meta("system_service_type",str(site["kind"]))
	area.set_meta("system_city_name","Baghdad")
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 5.0
	collision.shape = shape
	area.add_child(collision)
	root.add_child(area)

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = position
	mesh_node.material_override = material
	parent.add_child(mesh_node)
	if collision:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		body.position = position
		var shape_node := CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		parent.add_child(body)

func _add_cylinder(parent: Node3D, node_name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)

func _add_sign(parent: Node3D, label_text: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.name = "LandmarkSign"
	label.text = label_text
	label.font_size = 30
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position
	label.modulate = Color(0.85,0.94,1.0)
	parent.add_child(label)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
