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
var _sites: Array[Dictionary] = [
	{"id":"baghdad_mosque_grand","name":"الجامع الكبير في بغداد","kind":"mosque","offset":Vector2(-170.0,-120.0),"size":Vector3(58.0,18.0,48.0),"color":Color(0.68,0.58,0.39),"prompt":"دخول الجامع الكبير في بغداد"},
	{"id":"baghdad_church_old","name":"الكنيسة التاريخية في بغداد","kind":"church","offset":Vector2(-95.0,-205.0),"size":Vector3(42.0,22.0,36.0),"color":Color(0.54,0.48,0.39),"prompt":"دخول الكنيسة التاريخية في بغداد"},
	{"id":"baghdad_antiquities_museum","name":"متحف وآثار بغداد","kind":"museum","offset":Vector2(95.0,-205.0),"size":Vector3(62.0,20.0,44.0),"color":Color(0.52,0.43,0.31),"prompt":"زيارة متحف وآثار بغداد"},
	{"id":"baghdad_rare_market","name":"سوق التحف والمزادات","kind":"market","offset":Vector2(190.0,-105.0),"size":Vector3(68.0,12.0,42.0),"color":Color(0.43,0.29,0.17),"prompt":"دخول سوق التحف والمزادات"},
	{"id":"baghdad_football_stadium","name":"ملعب بغداد لكرة القدم","kind":"stadium","offset":Vector2(205.0,105.0),"size":Vector3(150.0,18.0,108.0),"color":Color(0.12,0.30,0.16),"prompt":"دخول ملعب بغداد لكرة القدم"},
	{"id":"baghdad_motorsport_circuit","name":"مضمار بغداد الدولي للسيارات","kind":"motorsport","offset":Vector2(-185.0,205.0),"size":Vector3(190.0,8.0,120.0),"color":Color(0.12,0.13,0.15),"prompt":"دخول مضمار سباق السيارات"},
	{"id":"baghdad_hunter_exam_tunnel","name":"نفق اختبار الصيادين","kind":"tunnel","offset":Vector2(0.0,245.0),"size":Vector3(42.0,12.0,28.0),"color":Color(0.10,0.19,0.27),"prompt":"دخول نفق اختبار الصيادين"},
	{"id":"baghdad_power_tower","name":"برج القوة — 200 طابق","kind":"power_tower","offset":Vector2(0.0,-300.0),"size":Vector3(44.0,480.0,44.0),"color":Color(0.12,0.24,0.34),"prompt":"دخول برج القوة المستقل"},
	{"id":"baghdad_advertising_plaza","name":"ساحة الإعلانات العامة","kind":"advertising","offset":Vector2(0.0,90.0),"size":Vector3(32.0,20.0,10.0),"color":Color(0.08,0.35,0.48),"prompt":"عرض إعلانات وأخبار بغداد"}
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
	_build_existing_tower_map_pins()
	set_meta("baghdad_landmarks_integrated", true)

func register_map_locations(p_map_manager: Node, world_id: String = WORLD_ID) -> void:
	map_manager = p_map_manager
	if map_manager == null or not map_manager.has_method("register_location") or _registered:
		return
	for site in _sites:
		var point := _site_position(site)
		map_manager.call("register_location", world_id, str(site["id"]), REGION_ID, str(site["name"]), 5, point, false)
	for index in range(5):
		var tower_id := "baghdad_tower_%02d" % (index + 1)
		var offset := _tower_offset(index)
		var point := _world_point(offset)
		map_manager.call("register_location", world_id, tower_id, REGION_ID, "برج بغداد %d" % (index + 1), 5, point, false)
	map_manager.call("register_location", world_id, "hunter_association_headquarters_baghdad", REGION_ID, "المقر الرئيسي لنقابة الصيادين", 5, _world_point(Vector2(0.0,0.0)), false)
	_registered = true

func _tower_offset(index: int) -> Vector2:
	var angle := TAU * float(index) / 5.0 - PI * 0.5
	return Vector2(cos(angle), sin(angle)) * 135.0

func _world_point(offset: Vector2) -> Vector3:
	var anchor := Vector3.ZERO
	var region_manager := get_parent()
	if region_manager != null and region_manager.has_method("get_city_anchor"):
		anchor = region_manager.call("get_city_anchor", "Baghdad")
	var x := anchor.x + offset.x
	var z := anchor.z + offset.y
	return Vector3(x, float(terrain.call("get_terrain_height", x, z)), z)

func _site_position(site: Dictionary) -> Vector3:
	return _world_point(site["offset"])

func _build_connected_roads() -> void:
	var hub := Vector2.ZERO
	var road_points: Array[Vector2] = [hub]
	for site in _sites:
		var offset: Vector2 = site["offset"]
		if str(site["kind"]) == "power_tower":
			continue
		road_points.append(offset)
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
	match kind:
		"stadium": _build_stadium(root, site)
		"motorsport": _build_motorsport(root, site)
		"tunnel": _build_tunnel(root, site)
		"power_tower": _build_power_tower(root, site)
		"advertising": _build_advertising(root, site)
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
	_add_box(root,"TunnelLeftWall",Vector3(-size.x*0.5,5.0,0.0),Vector3(3.0,10.0,size.z),dark,true)
	_add_box(root,"TunnelRightWall",Vector3(size.x*0.5,5.0,0.0),Vector3(3.0,10.0,size.z),dark,true)
	_add_box(root,"TunnelRoof",Vector3(0.0,10.0,0.0),Vector3(size.x,2.0,size.z),dark,true)
	_add_box(root,"TunnelPortalGlow",Vector3(0.0,5.0,-size.z*0.5),Vector3(size.x*0.76,9.0,0.6),glow,false)
	_add_sign(root,str(site["name"]),Vector3(0.0,14.0,-size.z*0.5-3.0))

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

func _build_existing_tower_map_pins() -> void:
	# Pins only: the five physical towers are already built by BaghdadTowerLandmarksManager.
	pass

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
