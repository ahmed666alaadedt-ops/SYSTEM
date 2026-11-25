extends Node3D
class_name SYSTEMBaghdadPublicLeisureManager

const WATER_TYPES := ["lap_pool", "family_pool", "thermal_pool"]

var lifeguard: Node3D
var water_volume_count := 0
var locker_count := 0

func _ready() -> void:
	name = "BaghdadPublicLeisureDistrict"
	_build_public_leisure_district()
	set_meta("system_public_leisure_runtime_ready", true)
	set_meta("system_public_leisure_is_tower", false)
	set_meta("system_public_leisure_water_volume_count", water_volume_count)
	set_meta("system_public_leisure_locker_count", locker_count)


func _build_public_leisure_district() -> void:
	var deck_material := _material(Color(0.12, 0.19, 0.23), 0.72, 0.28)
	var tile_material := _material(Color(0.68, 0.78, 0.79), 0.48, 0.12)
	var water_material := _material(Color(0.08, 0.55, 0.78, 0.78), 0.2, 0.18)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.emission_enabled = true
	water_material.emission = Color(0.015, 0.16, 0.24)
	water_material.emission_energy_multiplier = 0.7
	_add_box(self, "PublicLeisurePlaza", Vector3(0.0, -0.45, 0.0), Vector3(112.0, 0.9, 92.0), deck_material, true)
	_add_box(self, "PoolDeckTiles", Vector3(0.0, 0.08, 0.0), Vector3(104.0, 0.12, 84.0), tile_material, false)

	_build_pool("OlympicLapPool", Vector3(-24.0, 0.2, -12.0), Vector3(34.0, 1.0, 20.0), water_material, "lap_pool")
	_build_pool("FamilyLeisurePool", Vector3(23.0, 0.2, -12.0), Vector3(25.0, 0.72, 18.0), water_material, "family_pool")
	_build_pool("ThermalPool", Vector3(0.0, 0.2, 25.0), Vector3(18.0, 0.7, 12.0), water_material, "thermal_pool")
	_build_changing_suite("MensChangingSuite", Vector3(-43.0, 0.0, 20.0), "MEN / تبديل ملابس الرجال")
	_build_changing_suite("WomensChangingSuite", Vector3(43.0, 0.0, 20.0), "WOMEN / تبديل ملابس النساء")
	_build_lifeguard_station()
	_build_public_signage(tile_material)


func _build_pool(pool_name: String, center: Vector3, size: Vector3, water_material: Material, water_type: String) -> void:
	var pool := Node3D.new()
	pool.name = pool_name
	pool.position = center
	add_child(pool)
	_add_box(pool, "PoolRim", Vector3(0.0, 0.25, 0.0), Vector3(size.x + 2.4, 0.5, size.z + 2.4), _material(Color(0.82, 0.86, 0.84), 0.36, 0.12), true)
	_add_box(pool, "WaterSurface", Vector3(0.0, 0.54, 0.0), Vector3(size.x, 0.08, size.z), water_material, false)
	var water_area := Area3D.new()
	water_area.name = "WaterVolume"
	water_area.collision_layer = 0
	water_area.collision_mask = 1
	water_area.monitoring = true
	water_area.set_meta("system_public_leisure_water_type", water_type)
	water_area.set_meta("system_public_leisure_water_depth", 1.15 if water_type == "thermal_pool" else 1.0)
	var water_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(size.x - 0.5, 1.6, size.z - 0.5)
	water_shape.shape = box_shape
	water_shape.position = Vector3(0.0, -0.2, 0.0)
	water_area.add_child(water_shape)
	water_area.body_entered.connect(_on_water_body_entered.bind(water_area))
	water_area.body_exited.connect(_on_water_body_exited.bind(water_area))
	pool.add_child(water_area)
	water_volume_count += 1
	if water_type == "lap_pool":
		for lane in range(5):
			_add_box(pool, "LapLaneDivider_%02d" % lane, Vector3(0.0, 0.62, -size.z * 0.4 + float(lane) * size.z * 0.2), Vector3(size.x - 2.0, 0.035, 0.06), _material(Color(0.92, 0.95, 0.92), 0.4, 0.0), false)
	elif water_type == "family_pool":
		_add_box(pool, "ShallowEntryStep", Vector3(-size.x * 0.36, 0.18, 0.0), Vector3(3.2, 0.3, size.z - 2.0), _material(Color(0.9, 0.84, 0.63), 0.45, 0.0), false)


func _build_changing_suite(suite_name: String, center: Vector3, sign_text: String) -> void:
	var suite := Node3D.new()
	suite.name = suite_name
	suite.position = center
	add_child(suite)
	var wall_material := _material(Color(0.12, 0.23, 0.28), 0.6, 0.18)
	_add_box(suite, "ChangingSuiteFloor", Vector3(0.0, 0.12, 0.0), Vector3(17.0, 0.24, 15.0), wall_material, true)
	_add_box(suite, "ChangingSuiteBackWall", Vector3(0.0, 2.0, -7.3), Vector3(17.0, 4.0, 0.35), wall_material, true)
	_add_box(suite, "ChangingSuiteLeftWall", Vector3(-8.3, 2.0, 0.0), Vector3(0.35, 4.0, 14.5), wall_material, true)
	_add_box(suite, "ChangingSuiteRightWall", Vector3(8.3, 2.0, 0.0), Vector3(0.35, 4.0, 14.5), wall_material, true)
	_add_sign(suite, "ChangingSuiteSign", sign_text, Vector3(0.0, 4.0, -6.8))
	for index in range(8):
		var locker := MeshInstance3D.new()
		locker.name = "Locker_%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.15, 2.35, 0.85)
		locker.mesh = mesh
		locker.position = Vector3(-4.1 + float(index) * 1.17, 1.35, -5.9)
		locker.material_override = _material(Color(0.16, 0.42, 0.5), 0.38, 0.52)
		locker.set_meta("system_pool_locker_occupied", false)
		suite.add_child(locker)
		locker_count += 1
	_add_box(suite, "ChangingBench", Vector3(0.0, 0.62, -2.4), Vector3(9.0, 0.35, 1.0), wall_material, false)
	_create_service_interaction(suite, "PoolLockerServiceInteraction", "locker", "استلام خزانة شخصية", Vector3(0.0, 1.0, -2.0), 2.8)
	_create_service_interaction(suite, "PoolShowerServiceInteraction", "shower", "استخدام الدش", Vector3(0.0, 1.0, 4.0), 2.6)
	for index in range(3):
		_add_box(suite, "ShowerColumn_%02d" % index, Vector3(-3.0 + float(index) * 3.0, 1.5, 4.0), Vector3(0.25, 3.0, 0.25), wall_material, false)


func _build_lifeguard_station() -> void:
	var station := Node3D.new()
	station.name = "PoolLifeguardStation"
	station.position = Vector3(0.0, 0.0, -39.0)
	add_child(station)
	_add_box(station, "LifeguardPlatform", Vector3(0.0, 0.5, 0.0), Vector3(5.0, 0.5, 4.0), _material(Color(0.78, 0.35, 0.12), 0.5, 0.1), true)
	lifeguard = Node3D.new()
	lifeguard.name = "PublicLifeguardNPC"
	var body := MeshInstance3D.new()
	body.name = "LifeguardBody"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.48
	capsule.height = 1.9
	body.mesh = capsule
	body.position.y = 1.45
	body.material_override = _material(Color(0.95, 0.58, 0.16), 0.62, 0.0)
	lifeguard.add_child(body)
	lifeguard.position = Vector3(0.0, 0.75, 0.0)
	lifeguard.set_meta("system_npc_role", "public_pool_lifeguard")
	station.add_child(lifeguard)
	_add_sign(station, "LifeguardSign", "منقذ المسبح — إسعاف أولي", Vector3(0.0, 4.0, -1.5))
	_create_service_interaction(station, "PoolLifeguardServiceInteraction", "lifeguard", "طلب مساعدة المنقذ", Vector3(0.0, 1.0, 0.0), 3.0)


func _build_public_signage(material: Material) -> void:
	_add_sign(self, "PublicLeisureDistrictSign", "منطقة بغداد العامة للترفيه والسباحة", Vector3(0.0, 7.0, -45.0))
	_add_sign(self, "PublicPoolSafetySign", "اتبع تعليمات المنقذ — يمنع الغطس في المياه الضحلة", Vector3(0.0, 3.0, 43.0))


func _create_service_interaction(parent: Node3D, node_name: String, service_type: String, prompt: String, position: Vector3, radius: float) -> void:
	var interaction := Area3D.new()
	interaction.name = node_name
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_pool_service_type", service_type)
	interaction.set_meta("system_interaction_prompt", prompt)
	interaction.set_meta("system_tower_id", "public_leisure_district")
	interaction.set_meta("system_tower_floor_number", 1)
	interaction.set_meta("system_public_leisure_service", true)
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	collision.shape = sphere
	collision.position = position
	interaction.add_child(collision)
	parent.add_child(interaction)


func _on_water_body_entered(body: Node3D, water_area: Area3D) -> void:
	if body == null or not is_instance_valid(body) or not body.is_in_group("system_player"):
		return
	body.set_meta("system_public_leisure_swimming", true)
	body.set_meta("system_public_leisure_water_type", str(water_area.get_meta("system_public_leisure_water_type", "leisure")))
	body.set_meta("system_public_leisure_water_depth", float(water_area.get_meta("system_public_leisure_water_depth", 1.0)))


func _on_water_body_exited(body: Node3D, _water_area: Area3D) -> void:
	if body == null or not is_instance_valid(body) or not body.is_in_group("system_player"):
		return
	body.remove_meta("system_public_leisure_swimming")
	body.remove_meta("system_public_leisure_water_type")
	body.remove_meta("system_public_leisure_water_depth")


func dispatch_lifeguard_to(target: Node3D) -> bool:
	if not is_instance_valid(target) or not is_instance_valid(lifeguard):
		return false
	var previous: Variant = lifeguard.get_meta("system_lifeguard_response_tween", null)
	if previous is Tween and (previous as Tween).is_running():
		(previous as Tween).kill()
	lifeguard.set_meta("system_lifeguard_assistance_requested", true)
	lifeguard.set_meta("system_lifeguard_assistance_target", target.global_position)
	var tween := lifeguard.create_tween()
	lifeguard.set_meta("system_lifeguard_response_tween", tween)
	tween.tween_property(lifeguard, "global_position", target.global_position + Vector3(1.4, 0.0, 0.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if is_instance_valid(lifeguard):
			lifeguard.set_meta("system_lifeguard_assistance_arrived", true)
	)
	return true


func release_locker(suite_name: String, locker_id: String, owner_instance_id: int) -> bool:
	if suite_name.is_empty() or locker_id.is_empty():
		return false
	var suite := get_node_or_null(suite_name) as Node3D
	var locker := suite.get_node_or_null(locker_id) as MeshInstance3D if suite != null else null
	if locker == null or int(locker.get_meta("system_pool_locker_owner", -1)) != owner_instance_id:
		return false
	locker.set_meta("system_pool_locker_occupied", false)
	locker.remove_meta("system_pool_locker_owner")
	var original: Variant = locker.get_meta("system_pool_locker_original_material", null)
	if original is Material:
		locker.material_override = original
	locker.remove_meta("system_pool_locker_original_material")
	return true


func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, with_collision: bool) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = position
	mesh_node.material_override = material
	parent.add_child(mesh_node)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		body.position = position
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		parent.add_child(body)


func _add_sign(parent: Node3D, node_name: String, text_value: String, position: Vector3) -> void:
	var sign := Label3D.new()
	sign.name = node_name
	sign.text = text_value
	sign.position = position
	sign.font_size = 28
	sign.pixel_size = 0.014
	sign.modulate = Color(0.86, 0.96, 1.0)
	parent.add_child(sign)


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result
