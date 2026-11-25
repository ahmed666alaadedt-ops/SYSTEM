extends Node3D
class_name SYSTEMHunterMarshlandManager

const REED_COUNT := 12000
const WILLOW_COUNT := 160
const POOL_COUNT := 8
const WALKWAY_COUNT := 9
const FOG_LAYER_COUNT := 18
const DECOY_COUNT := 12
const FALSE_TRAIL_COUNT := 5
const AREA_SIZE := Vector2(460.0, 420.0)

var rng := RandomNumberGenerator.new()
var animals: Array[Node3D] = []

func _ready() -> void:
	name = "HunterMarshland"
	rng.seed = 20261125
	_build_ground()
	_build_reeds()
	_build_willows()
	_build_pools()
	_build_walkways()
	_build_fog()
	_build_animals()
	_build_decoys()
	_build_false_trails()
	set_meta("system_marshland_runtime_ready", true)
	set_meta("system_marshland_replaces_zawraa_park", true)
	set_meta("system_marshland_reed_count", REED_COUNT)
	set_meta("system_marshland_willow_count", WILLOW_COUNT)
	set_meta("system_marshland_pool_count", POOL_COUNT)
	set_meta("system_marshland_walkway_count", WALKWAY_COUNT)
	set_meta("system_marshland_fog_layer_count", FOG_LAYER_COUNT)
	set_meta("system_marshland_giant_animal_count", animals.size())
	set_meta("system_marshland_decoy_npc_count", DECOY_COUNT)
	set_meta("system_marshland_false_trail_count", FALSE_TRAIL_COUNT)
	set_meta("system_marshland_connection", "hunter_tunnel_exit")

func _mat(color: Color, roughness: float = 0.9, alpha: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material, solid: bool = false) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = pos
	visual.material_override = material
	parent.add_child(visual)
	if solid:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		body.position = pos
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		parent.add_child(body)

func _point(margin: float = 10.0) -> Vector2:
	return Vector2(rng.randf_range(-AREA_SIZE.x * 0.5 + margin, AREA_SIZE.x * 0.5 - margin), rng.randf_range(-AREA_SIZE.y * 0.5 + margin, AREA_SIZE.y * 0.5 - margin))

func _build_ground() -> void:
	_box(self, "MarshlandGround", Vector3(0,-0.7,0), Vector3(AREA_SIZE.x,1.4,AREA_SIZE.y), _mat(Color(0.10,0.15,0.09)), true)
	set_meta("system_marshland_ground_collision", true)

func _build_reeds() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.025
	mesh.bottom_radius = 0.07
	mesh.height = 2.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = REED_COUNT
	for i in range(REED_COUNT):
		var p := _point(8.0)
		var h := rng.randf_range(0.65,1.55)
		var s := rng.randf_range(0.75,1.15)
		var basis := Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(Vector3(s,h,s))
		mm.set_instance_transform(i,Transform3D(basis,Vector3(p.x,h,p.y)))
	var reeds := MultiMeshInstance3D.new()
	reeds.name = "MarshReeds_12000"
	reeds.multimesh = mm
	reeds.material_override = _mat(Color(0.37,0.44,0.17))
	reeds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(reeds)

func _build_willows() -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 8.0
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 3.2
	crown_mesh.height = 6.8
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	trunks.mesh = trunk_mesh
	trunks.instance_count = WILLOW_COUNT
	var crowns := MultiMesh.new()
	crowns.transform_format = MultiMesh.TRANSFORM_3D
	crowns.mesh = crown_mesh
	crowns.instance_count = WILLOW_COUNT
	for i in range(WILLOW_COUNT):
		var p := _point(16.0)
		var s := rng.randf_range(0.8,1.25)
		var b := Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(Vector3(s,s,s))
		trunks.set_instance_transform(i,Transform3D(b,Vector3(p.x,4.0*s,p.y)))
		crowns.set_instance_transform(i,Transform3D(b.scaled(Vector3(1.0,0.72,1.0)),Vector3(p.x,9.0*s,p.y)))
	var t := MultiMeshInstance3D.new()
	t.name = "WillowTrunks_160"
	t.multimesh = trunks
	t.material_override = _mat(Color(0.25,0.17,0.09))
	add_child(t)
	var c := MultiMeshInstance3D.new()
	c.name = "WillowCanopies_160"
	c.multimesh = crowns
	c.material_override = _mat(Color(0.12,0.29,0.13))
	add_child(c)

func _build_pools() -> void:
	var water := _mat(Color(0.055,0.22,0.18,0.78),0.2,true)
	water.emission_enabled = true
	water.emission = Color(0.01,0.07,0.05)
	var spots := [Vector3(-155,0,-125),Vector3(-55,0,-145),Vector3(75,0,-135),Vector3(165,0,-80),Vector3(-165,0,35),Vector3(-45,0,80),Vector3(90,0,105),Vector3(165,0,155)]
	var sizes := [Vector2(54,38),Vector2(46,32),Vector2(58,36),Vector2(44,34),Vector2(50,42),Vector2(62,40),Vector2(48,36),Vector2(52,38)]
	for i in range(POOL_COUNT):
		var pond := Node3D.new()
		pond.name = "MarshPool_%02d" % (i+1)
		pond.position = spots[i]
		pond.set_meta("system_marshland_water_body",true)
		pond.set_meta("system_marshland_water_depth_m",rng.randf_range(1.2,4.8))
		add_child(pond)
		_box(pond,"PondBank",Vector3(0,-0.12,0),Vector3(sizes[i].x+3,0.3,sizes[i].y+3),_mat(Color(0.2,0.22,0.13)),false)
		_box(pond,"WaterSurface",Vector3(0,0.035,0),Vector3(sizes[i].x,0.07,sizes[i].y),water,false)
		var area := Area3D.new()
		area.name = "MarshWaterVolume"
		area.collision_layer = 0
		area.collision_mask = 1
		area.monitoring = true
		area.set_meta("system_marshland_water_body",true)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(sizes[i].x-1,3.0,sizes[i].y-1)
		cs.shape = shape
		cs.position.y = -1.1
		area.add_child(cs)
		pond.add_child(area)

func _build_walkways() -> void:
	var wood := _mat(Color(0.30,0.19,0.10))
	var specs := [[Vector3(-150,0.75,-20),92.0,0.0],[Vector3(-55,0.82,-58),84.0,0.32],[Vector3(55,0.78,-22),98.0,-0.25],[Vector3(150,0.72,35),82.0,0.18],[Vector3(-145,0.8,135),96.0,-0.16],[Vector3(-42,0.9,152),88.0,0.0],[Vector3(62,0.82,155),90.0,0.24],[Vector3(155,0.78,-145),86.0,-0.3],[Vector3(0,1.05,0),112.0,1.5707963]]
	for i in range(WALKWAY_COUNT):
		var spec: Array = specs[i]
		var path := Node3D.new()
		path.name = "WoodenWalkway_%02d" % (i+1)
		path.position = spec[0]
		path.rotation.y = float(spec[2])
		add_child(path)
		var length := float(spec[1])
		_box(path,"WalkwayDeck",Vector3.ZERO,Vector3(4.2,0.42,length),wood,true)
		for side in [-1.0,1.0]:
			_box(path,"WalkwayRail_%s" % str(side),Vector3(side*2.0,0.95,0),Vector3(0.18,1.35,length),wood,true)
		path.set_meta("system_marshland_walkable",true)
		path.set_meta("system_marshland_walkway_length_m",length)

func _build_fog() -> void:
	var fog_mat := _mat(Color(0.72,0.79,0.72,0.035),1.0,true)
	fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fog_mat.no_depth_test = true
	for i in range(FOG_LAYER_COUNT):
		var layer := MeshInstance3D.new()
		layer.name = "MarshFogLayer_%02d" % (i+1)
		var plane := PlaneMesh.new()
		plane.size = AREA_SIZE * 0.96
		layer.mesh = plane
		layer.position = Vector3(0,1.4+float(i)*0.72,0)
		layer.rotation.x = -PI*0.5
		layer.material_override = fog_mat
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(layer)

func _build_animals() -> void:
	var specs := [
		["giant_swamp_turtle","السلحفاة العملاقة",Vector3(-120,0,-75),Vector3(10,5.5,13),Color(0.24,0.31,0.15)],
		["giant_marsh_crocodile","تمساح المستنقع العملاق",Vector3(115,0,-95),Vector3(5,3,18),Color(0.20,0.29,0.19)],
		["giant_swamp_frog","ضفدع المستنقع العملاق",Vector3(-155,0,105),Vector3(7,6,7),Color(0.30,0.42,0.17)],
		["giant_marsh_stag","أيل المستنقع العملاق",Vector3(40,0,125),Vector3(5,9,6),Color(0.42,0.29,0.16)],
		["giant_mire_boar","خنزير الطين العملاق",Vector3(165,0,75),Vector3(7,5,10),Color(0.34,0.22,0.13)],
		["giant_marsh_heron","مالك الحزين العملاق",Vector3(-15,0,-165),Vector3(4,11,4),Color(0.34,0.38,0.32)]
	]
	for spec in specs:
		var animal := Node3D.new()
		animal.name = str(spec[0])
		animal.position = spec[2]
		animal.scale = spec[3]
		animal.set_meta("system_marshland_giant_animal",true)
		animal.set_meta("system_marshland_species_id",str(spec[0]))
		animal.set_meta("system_display_name",str(spec[1]))
		add_child(animal)
		var body := MeshInstance3D.new()
		body.name = "GiantAnimalBody"
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.5
		capsule.height = 1.8
		body.mesh = capsule
		body.material_override = _mat(spec[4])
		animal.add_child(body)
		var head := MeshInstance3D.new()
		head.name = "GiantAnimalHead"
		var sphere := SphereMesh.new()
		sphere.radius = 0.46
		sphere.height = 0.92
		head.mesh = sphere
		head.position = Vector3(0,0.15,-0.78)
		head.material_override = body.material_override
		animal.add_child(head)
		animals.append(animal)

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for i in range(animals.size()):
		var animal := animals[i]
		if is_instance_valid(animal):
			animal.position.x += sin(t*0.18+float(i))*delta*0.38
			animal.rotation.y = sin(t*0.16+float(i))*0.12

func _build_decoys() -> void:
	for i in range(DECOY_COUNT):
		var zone := i % FALSE_TRAIL_COUNT
		var npc := Node3D.new()
		npc.name = "MarshDecoyCandidate_%02d" % (i+1)
		npc.position = Vector3(-170+float(zone)*82,0,-125+float(zone)*58+float(i/5)*9)
		npc.set_meta("system_npc_role","hunter_exam_misdirection_actor")
		npc.set_meta("system_marshland_decoy",true)
		npc.set_meta("system_marshland_false_trail_id","false_trail_%02d" % (zone+1))
		add_child(npc)
		var body := MeshInstance3D.new()
		body.name = "DecoyBody"
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.42
		capsule.height = 1.8
		body.mesh = capsule
		body.position.y = 0.95
		body.material_override = _mat(Color(0.32,0.38,0.43))
		npc.add_child(body)
		var head := MeshInstance3D.new()
		head.name = "DecoyHead"
		var sphere := SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.56
		head.mesh = sphere
		head.position.y = 2.0
		head.material_override = _mat(Color(0.58,0.43,0.31))
		npc.add_child(head)
		var area := Area3D.new()
		area.name = "DecoyInteraction"
		area.add_to_group("system_interactable")
		area.set_meta("system_marshland_decoy",true)
		area.set_meta("system_marshland_false_trail_id","false_trail_%02d" % (zone+1))
		var cs := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 2.2
		cs.shape = shape
		area.add_child(cs)
		npc.add_child(area)

func _build_false_trails() -> void:
	for i in range(FALSE_TRAIL_COUNT):
		var route := Node3D.new()
		route.name = "FalseTrailRegion_%02d" % (i+1)
		route.position = Vector3(-170+float(i)*82,0,-125+float(i)*58)
		route.set_meta("system_marshland_false_trail",true)
		route.set_meta("system_marshland_false_trail_id","false_trail_%02d" % (i+1))
		add_child(route)
