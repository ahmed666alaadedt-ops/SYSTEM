extends Node3D
class_name ModernCityServicesManager

## First-pass city service buildings and discoverable interaction markers.
## Functional service menus, interiors and backend transactions are future work.

const SERVICE_DATA := [
	{"id": "hospital", "name": "General Hospital", "prompt": "المستشفى — العلاج والخدمات الطبية", "color": Color(0.78, 0.82, 0.82), "height": 22.0},
	{"id": "police", "name": "Police Headquarters", "prompt": "مركز الشرطة — البلاغات والقانون", "color": Color(0.18, 0.28, 0.38), "height": 19.0},
	{"id": "fire", "name": "Fire and Rescue Station", "prompt": "مركز الإطفاء والإنقاذ", "color": Color(0.55, 0.18, 0.12), "height": 13.0},
	{"id": "hotel", "name": "Grand City Hotel", "prompt": "الفندق — الحجز والإقامة", "color": Color(0.48, 0.38, 0.26), "height": 28.0},
	{"id": "market", "name": "Central Market", "prompt": "السوق المركزي — البيع والشراء", "color": Color(0.38, 0.42, 0.31), "height": 12.0},
	{"id": "garage", "name": "Vehicle Service Garage", "prompt": "كراج المركبات — الصيانة", "color": Color(0.25, 0.31, 0.35), "height": 11.0},
	{"id": "school", "name": "Public School", "prompt": "المدرسة — التعليم والأنشطة", "color": Color(0.72, 0.58, 0.34), "height": 10.0},
	{"id": "university", "name": "City University", "prompt": "الجامعة — التعليم والبحث", "color": Color(0.34, 0.39, 0.52), "height": 16.0},
	{"id": "stadium", "name": "Football Stadium", "prompt": "ملعب كرة القدم — المباريات والفعاليات", "color": Color(0.24, 0.34, 0.28), "height": 18.0},
	{"id": "shops", "name": "Shopping Street", "prompt": "المحلات التجارية — التسوق", "color": Color(0.48, 0.34, 0.27), "height": 9.0},
	{"id": "restaurant", "name": "City Restaurant", "prompt": "المطعم — الطعام والضيافة", "color": Color(0.58, 0.30, 0.20), "height": 9.0},
	{"id": "bank", "name": "City Bank", "prompt": "المصرف — الخدمات المالية", "color": Color(0.30, 0.40, 0.48), "height": 13.0},
	{"id": "mall", "name": "Shopping Mall", "prompt": "المركز التجاري — التسوق والترفيه", "color": Color(0.38, 0.42, 0.48), "height": 17.0},
	{"id": "pharmacy", "name": "Community Pharmacy", "prompt": "الصيدلية — المستلزمات الصحية", "color": Color(0.32, 0.58, 0.48), "height": 8.0},
	{"id": "bakery", "name": "Neighborhood Bakery", "prompt": "المخبز — الخبز والمخبوزات", "color": Color(0.62, 0.42, 0.24), "height": 7.0},
	{"id": "cafe", "name": "City Cafe", "prompt": "المقهى — الجلسات والضيافة", "color": Color(0.42, 0.28, 0.22), "height": 8.0},
	{"id": "fuel_station", "name": "Fuel and Charging Station", "prompt": "محطة الوقود والشحن — خدمة المركبات", "color": Color(0.30, 0.36, 0.40), "height": 7.0},
	{"id": "park", "name": "Public City Park", "prompt": "الحديقة العامة — التنزه والراحة", "color": Color(0.18, 0.38, 0.20), "height": 3.0},
	{"id": "bus_station", "name": "Central Bus Station", "prompt": "محطة الحافلات — النقل العام", "color": Color(0.30, 0.38, 0.46), "height": 9.0},
	{"id": "post_office", "name": "City Post Office", "prompt": "مكتب البريد — الطرود والخدمات", "color": Color(0.52, 0.34, 0.24), "height": 9.0},
	{"id": "library", "name": "Public Library", "prompt": "المكتبة العامة — القراءة والمعرفة", "color": Color(0.38, 0.32, 0.26), "height": 12.0},
	{"id": "train_station", "name": "Urban Rail Station", "prompt": "محطة القطار — الرحلات والتنقل", "color": Color(0.30, 0.40, 0.48), "height": 12.0},
	{"id": "port", "name": "City Harbor Terminal", "prompt": "الميناء — السفن والشحن", "color": Color(0.18, 0.34, 0.46), "height": 14.0},
	{"id": "cinema", "name": "City Cinema", "prompt": "دار السينما — العروض والفعاليات", "color": Color(0.28, 0.22, 0.34), "height": 11.0},
	{"id": "gym", "name": "Fitness Center", "prompt": "مركز اللياقة — التدريب الرياضي", "color": Color(0.30, 0.34, 0.38), "height": 10.0}
]

var region_manager: Node
var terrain: Node
var service_locations: Array[Dictionary] = []
var active_city_name := ""
var city_check_clock := 0.0

func _ready() -> void:
	name = "ModernCityServicesManager"
	region_manager = get_parent()
	if region_manager == null or not region_manager.has_method("get_city_names"):
		return
	terrain = region_manager.get("terrain")
	if terrain == null:
		return
	active_city_name = _find_nearest_city_name(Vector3.ZERO)
	for city_value in region_manager.call("get_city_names"):
		_build_city_services(str(city_value))
	print("SYSTEM WORLD: service locations registered = ", service_locations.size(),
		"; active city visuals = ", active_city_name)

func _build_city_services(city_name: String) -> void:
	var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
	if anchor == Vector3.INF:
		return
	for index in range(SERVICE_DATA.size()):
		var definition: Dictionary = SERVICE_DATA[index]
		var angle := TAU * float(index) / float(SERVICE_DATA.size()) + deg_to_rad(15.0)
		var requested := Vector2(anchor.x, anchor.z) + Vector2(cos(angle), sin(angle)) * (310.0 if str(definition["id"]) == "stadium" else 205.0)
		var resolved: Vector2 = region_manager.call("_nearest_land_position", requested)
		if resolved == Vector2.INF:
			continue
		var service_position := Vector3(
			resolved.x,
			float(terrain.call("get_terrain_height", resolved.x, resolved.y)),
			resolved.y
		)
		var service_id := str(definition["id"])
		var location_type := 7
		if service_id == "hospital":
			location_type = 2
		elif service_id == "market" or service_id == "garage" or service_id == "fuel_station":
			location_type = 4
		service_locations.append({
			"id": "service_%s_%s" % [city_name.to_lower().replace(" ", "_"), service_id],
			"city": city_name,
			"name": city_name + " " + str(definition["name"]),
			"position": service_position,
			"service_type": service_id,
			"location_type": location_type
		})
		if city_name == active_city_name:
			_create_service_building(city_name, definition, resolved, index)

func _find_nearest_city_name(position: Vector3) -> String:
	var city_names: Array = region_manager.call("get_city_names")
	var nearest_name := "Baghdad"
	var nearest_distance := INF
	for city_value in city_names:
		var city_name := str(city_value)
		var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
		if anchor == Vector3.INF:
			continue
		var distance := Vector2(position.x - anchor.x, position.z - anchor.z).length_squared()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_name = city_name
	return nearest_name


func _rebuild_city_service_visuals(city_name: String) -> void:
	if city_name == active_city_name:
		return
	for child in get_children():
		child.queue_free()
	active_city_name = city_name
	for record in service_locations:
		if str(record.get("city", "")) != active_city_name:
			continue
		var service_id := str(record.get("service_type", ""))
		for index in range(SERVICE_DATA.size()):
			var definition: Dictionary = SERVICE_DATA[index]
			if str(definition.get("id", "")) == service_id:
				var position: Vector3 = record.get("position", Vector3.ZERO)
				_create_service_building(active_city_name, definition, Vector2(position.x, position.z), index)
				break


func _process(delta: float) -> void:
	city_check_clock += delta
	if city_check_clock < 4.0:
		return
	city_check_clock = 0.0
	var player := region_manager.get_parent().get_node_or_null("Player") as Node3D
	var player_position := player.global_position if is_instance_valid(player) else Vector3.ZERO
	_rebuild_city_service_visuals(_find_nearest_city_name(player_position))


func _create_service_building(city_name: String, definition: Dictionary, position: Vector2, index: int) -> void:
	var service_id := str(definition["id"])
	var location_id := "service_%s_%s" % [city_name.to_lower().replace(" ", "_"), service_id]
	var location_type := 7
	if service_id == "hospital":
		location_type = 2
	elif service_id == "market" or service_id == "garage":
		location_type = 4
	var building := Node3D.new()
	building.name = city_name.replace(" ", "") + "_" + service_id.capitalize() + "Building"
	building.position = Vector3(position.x, float(terrain.call("get_terrain_height", position.x, position.y)), position.y)
	add_child(building)

	var width := 16.0 if service_id != "hotel" else 20.0
	var depth := 14.0 if service_id != "hotel" else 18.0
	if service_id == "stadium":
		width = 96.0
		depth = 76.0
	elif service_id == "mall":
		width = 34.0
		depth = 28.0
	elif service_id == "school" or service_id == "university":
		width = 28.0
		depth = 22.0
	elif service_id == "shops":
		width = 38.0
		depth = 12.0
	elif service_id == "bus_station" or service_id == "train_station" or service_id == "port":
		width = 42.0
		depth = 30.0
	elif service_id == "park":
		width = 34.0
		depth = 28.0
	elif service_id == "cinema" or service_id == "library" or service_id == "gym":
		width = 24.0
		depth = 20.0
	var height := float(definition["height"])
	var facade := _material(definition["color"], 0.78, 0.12)
	var roof_material := _material(Color(0.10, 0.13, 0.16), 0.55, 0.25)
	var glass := _material(Color(0.08, 0.2, 0.28), 0.22, 0.35)

	var body := StaticBody3D.new()
	body.name = "ServiceBuildingCollisionBody"
	building.add_child(body)
	var structure := MeshInstance3D.new()
	structure.name = "ServiceBuildingFacade"
	var structure_mesh := BoxMesh.new()
	var shell_height := 0.6 if service_id == "park" else (1.2 if service_id == "stadium" else height)
	structure_mesh.size = Vector3(width, shell_height, depth)
	structure.mesh = structure_mesh
	structure.position.y = shell_height * 0.5
	structure.material_override = facade
	structure.visibility_range_end = 1100.0
	body.add_child(structure)
	var collision := CollisionShape3D.new()
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(width, shell_height, depth)
	collision.shape = collision_shape
	collision.position.y = shell_height * 0.5
	body.add_child(collision)

	if service_id != "stadium" and service_id != "park":
		var roof := MeshInstance3D.new()
		var roof_mesh := BoxMesh.new()
		roof_mesh.size = Vector3(width + 0.7, 0.45, depth + 0.7)
		roof.mesh = roof_mesh
		roof.position.y = height + 0.2
		roof.material_override = roof_material
		roof.visibility_range_end = 1100.0
		building.add_child(roof)

	# Keep facade detail counts bounded for Android: three visible window bands,
	# with only two windows per band on each procedural service building.
	var visible_window_bands := 0 if service_id == "stadium" or service_id == "park" else (3 if height > 15.0 else 2)
	for floor_index in range(visible_window_bands):
		var y := 2.0 + float(floor_index) * 4.2
		for column in range(2):
			var x := -3.2 + float(column) * 6.4
			var window := MeshInstance3D.new()
			var window_mesh := BoxMesh.new()
			window_mesh.size = Vector3(2.0, 1.55, 0.12)
			window.mesh = window_mesh
			window.position = Vector3(x, y, -depth * 0.5 - 0.07)
			window.material_override = glass
			window.visibility_range_end = 1100.0
			building.add_child(window)

	if service_id == "stadium":
		_create_stadium_details(building, width, depth)
	elif service_id == "school" or service_id == "university":
		var courtyard_material := _material(Color(0.15, 0.32, 0.18), 1.0, 0.0)
		_create_civic_courtyard(building, width, depth, courtyard_material)
	elif service_id == "shops":
		_create_shopfronts(building, width, depth, glass, roof_material)

	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(2.2, 3.0, 0.18)
	door.mesh = door_mesh
	door.position = Vector3(0.0, 1.5, -depth * 0.5 - 0.12)
	door.material_override = roof_material
	door.visibility_range_end = 1100.0
	building.add_child(door)

	var sign := Label3D.new()
	sign.name = "ServiceNameSign"
	sign.text = str(definition["name"])
	sign.font_size = 34
	sign.outline_size = 5
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(0.0, height + 3.0, 0.0)
	sign.modulate = Color(0.72, 0.94, 1.0)
	building.add_child(sign)

	var interaction := Area3D.new()
	interaction.name = "ServiceEntranceInteraction"
	interaction.position = Vector3(0.0, 1.2, -depth * 0.5 - 1.5)
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_interaction_prompt", str(definition["prompt"]))
	interaction.set_meta("system_location_id", location_id)
	interaction.set_meta("system_region_id", "region_" + city_name.to_lower().replace(" ", "_"))
	interaction.set_meta("system_display_name", city_name + " " + str(definition["name"]))
	interaction.set_meta("system_location_type", location_type)
	interaction.set_meta("system_service_type", service_id)
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(3.0, 2.6, 3.0)
	area_shape.shape = area_box
	interaction.add_child(area_shape)
	building.add_child(interaction)


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func get_service_locations() -> Array[Dictionary]:
	return service_locations.duplicate(true)

func _create_stadium_details(parent: Node3D, width: float, depth: float) -> void:
	var pitch_material := _material(Color(0.08, 0.34, 0.12), 0.95, 0.0)
	var line_material := _material(Color(0.92, 0.94, 0.86), 0.9, 0.0)
	var pitch := MeshInstance3D.new()
	pitch.name = "FootballPitch"
	var pitch_mesh := BoxMesh.new()
	pitch_mesh.size = Vector3(width * 0.56, 0.18, depth * 0.52)
	pitch.mesh = pitch_mesh
	pitch.position.y = 1.2
	pitch.material_override = pitch_material
	parent.add_child(pitch)
	for side in [-1.0, 1.0]:
		var stand := MeshInstance3D.new()
		stand.name = "SpectatorStand_%s" % str(side)
		var stand_mesh := BoxMesh.new()
		stand_mesh.size = Vector3(width * 0.72, 8.0, 10.0)
		stand.mesh = stand_mesh
		stand.position = Vector3(0.0, 5.0, side * depth * 0.39)
		stand.material_override = _material(Color(0.28, 0.32, 0.38), 0.82, 0.0)
		parent.add_child(stand)
	for side in [-1.0, 1.0]:
		var goal := MeshInstance3D.new()
		goal.name = "GoalFrame_%s" % str(side)
		var goal_mesh := BoxMesh.new()
		goal_mesh.size = Vector3(7.3, 2.5, 0.18)
		goal.mesh = goal_mesh
		goal.position = Vector3(0.0, 2.5, side * depth * 0.27)
		goal.material_override = line_material
		parent.add_child(goal)
	var center_line := MeshInstance3D.new()
	center_line.name = "PitchCenterLine"
	var center_mesh := BoxMesh.new()
	center_mesh.size = Vector3(0.16, 0.035, depth * 0.52)
	center_line.mesh = center_mesh
	center_line.position.y = 1.31
	center_line.material_override = line_material
	parent.add_child(center_line)


func _create_civic_courtyard(parent: Node3D, width: float, depth: float, green: Material) -> void:
	var yard := MeshInstance3D.new()
	yard.name = "SchoolOrUniversityCourtyard"
	var yard_mesh := BoxMesh.new()
	yard_mesh.size = Vector3(width * 0.72, 0.16, depth * 0.5)
	yard.mesh = yard_mesh
	yard.position = Vector3(0.0, 0.12, depth * 0.68)
	yard.material_override = green
	parent.add_child(yard)


func _create_shopfronts(parent: Node3D, width: float, depth: float, glass: Material, trim: Material) -> void:
	for index in range(5):
		var shop := MeshInstance3D.new()
		shop.name = "Shopfront_%02d" % index
		var shop_mesh := BoxMesh.new()
		shop_mesh.size = Vector3(width / 6.0, 3.2, 0.16)
		shop.mesh = shop_mesh
		shop.position = Vector3(-width * 0.4 + float(index) * width * 0.2, 2.0, -depth * 0.5 - 0.12)
		shop.material_override = glass
		parent.add_child(shop)
		var awning := MeshInstance3D.new()
		awning.name = "ShopAwning_%02d" % index
		var awning_mesh := BoxMesh.new()
		awning_mesh.size = Vector3(width / 6.0, 0.22, 1.5)
		awning.mesh = awning_mesh
		awning.position = Vector3(shop.position.x, 4.0, -depth * 0.5 - 0.9)
		awning.material_override = trim
		parent.add_child(awning)

