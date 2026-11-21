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
	{"id": "gym", "name": "Fitness Center", "prompt": "مركز اللياقة — التدريب الرياضي", "color": Color(0.30, 0.34, 0.38), "height": 10.0},
	{"id": "mosque", "name": "Grand Mosque", "prompt": "الجامع — مكان العبادة والزيارة باحترام", "color": Color(0.68, 0.62, 0.43), "height": 24.0},
	{"id": "church", "name": "City Church", "prompt": "الكنيسة — مكان العبادة والزيارة باحترام", "color": Color(0.62, 0.55, 0.43), "height": 22.0},
	{"id": "museum", "name": "City History Museum", "prompt": "متحف المدينة — التاريخ والآثار والمعارض", "color": Color(0.48, 0.38, 0.27), "height": 18.0},
	{"id": "rare_antique_market", "name": "Rare Antiques Bazaar", "prompt": "سوق التحف النادرة — المزادات والتبادل والقطع الأثرية", "color": Color(0.40, 0.28, 0.18), "height": 13.0}
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
		elif service_id == "market" or service_id == "garage" or service_id == "fuel_station" or service_id == "rare_antique_market":
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
	elif service_id == "market" or service_id == "garage" or service_id == "rare_antique_market":
		location_type = 4
	var building := Node3D.new()
	building.name = city_name.replace(" ", "") + "_" + service_id.capitalize() + "Building"
	building.position = Vector3(position.x, float(terrain.call("get_terrain_height", position.x, position.y)), position.y)
	add_child(building)

	var width := 16.0 if service_id != "hotel" else 20.0
	var depth := 14.0 if service_id != "hotel" else 18.0
	if service_id == "stadium":
		# Full-size city stadium footprint with room for a regulation football pitch and stands.
		width = 150.0
		depth = 116.0
	elif service_id == "mall":
		width = 34.0
		depth = 28.0
	elif service_id == "mosque" or service_id == "church" or service_id == "museum" or service_id == "rare_antique_market":
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
	# Keep the stadium foundation below the playing surface so the grass is not buried.
	var shell_height := 0.6 if service_id == "park" or service_id == "stadium" else height
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
	# A stadium is an open venue, not a solid building shell; the pitch and stands provide their own collision.
	collision.disabled = ["stadium", "mosque", "church", "museum", "rare_antique_market"].has(service_id)
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
	elif service_id == "mosque":
		_create_mosque_details(building, width, depth, roof_material, glass)
	elif service_id == "church":
		_create_church_details(building, width, depth, roof_material, glass)
	elif service_id == "museum":
		_create_museum_details(building, width, depth, roof_material)
	elif service_id == "rare_antique_market":
		_create_rare_antique_market_details(building, width, depth, glass, roof_material)
	if ["mosque", "church", "museum", "rare_antique_market"].has(service_id):
		_create_civic_interior_blockout(building, service_id, width, depth, facade, glass, roof_material)

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


func _create_mosque_details(parent: Node3D, width: float, depth: float, stone: Material, glass: Material) -> void:
	var dome := MeshInstance3D.new()
	dome.name = "MosqueCentralDome"
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 7.0
	dome_mesh.height = 10.0
	dome.mesh = dome_mesh
	dome.position = Vector3(0.0, 8.0, 0.0)
	dome.material_override = stone
	parent.add_child(dome)
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			var minaret := MeshInstance3D.new()
			minaret.name = "MosqueMinaret_%s_%s" % [str(int(side_x)), str(int(side_z))]
			var shaft := CylinderMesh.new()
			shaft.top_radius = 0.7
			shaft.bottom_radius = 1.15
			shaft.height = 21.0
			minaret.mesh = shaft
			minaret.position = Vector3(side_x * (width * 0.39), 10.5, side_z * (depth * 0.39))
			minaret.material_override = stone
			parent.add_child(minaret)
			var balcony := MeshInstance3D.new()
			var balcony_mesh := CylinderMesh.new()
			balcony_mesh.top_radius = 1.55
			balcony_mesh.bottom_radius = 1.55
			balcony_mesh.height = 0.55
			balcony.mesh = balcony_mesh
			balcony.position = minaret.position + Vector3.UP * 5.0
			balcony.material_override = glass
			parent.add_child(balcony)


func _create_church_details(parent: Node3D, width: float, depth: float, stone: Material, glass: Material) -> void:
	var nave_roof := MeshInstance3D.new()
	nave_roof.name = "ChurchNaveRoof"
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(width + 2.0, 5.0, depth + 2.0)
	nave_roof.mesh = roof_mesh
	nave_roof.position = Vector3(0.0, 13.0, 0.0)
	nave_roof.material_override = stone
	parent.add_child(nave_roof)
	for side in [-1.0, 1.0]:
		var tower := MeshInstance3D.new()
		tower.name = "ChurchBellTower_%s" % str(int(side))
		var tower_mesh := BoxMesh.new()
		tower_mesh.size = Vector3(5.0, 19.0, 5.0)
		tower.mesh = tower_mesh
		tower.position = Vector3(side * (width * 0.37), 9.5, -depth * 0.34)
		tower.material_override = stone
		parent.add_child(tower)
		var spire := MeshInstance3D.new()
		var spire_mesh := CylinderMesh.new()
		spire_mesh.top_radius = 0.0
		spire_mesh.bottom_radius = 3.2
		spire_mesh.height = 7.0
		spire.mesh = spire_mesh
		spire.position = tower.position + Vector3.UP * 13.0
		spire.material_override = glass
		parent.add_child(spire)


func _create_museum_details(parent: Node3D, width: float, depth: float, stone: Material) -> void:
	var portico := Node3D.new()
	portico.name = "MuseumEntrancePortico"
	parent.add_child(portico)
	for index in range(6):
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.48
		pillar_mesh.bottom_radius = 0.62
		pillar_mesh.height = 9.0
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(-width * 0.38 + float(index) * width * 0.152, 4.5, -depth * 0.5 - 1.0)
		pillar.material_override = stone
		portico.add_child(pillar)
	var pediment := MeshInstance3D.new()
	var pediment_mesh := PrismMesh.new()
	pediment_mesh.size = Vector3(width * 0.92, 5.0, 2.0)
	pediment.mesh = pediment_mesh
	pediment.position = Vector3(0.0, 10.5, -depth * 0.5 - 1.0)
	pediment.material_override = stone
	portico.add_child(pediment)


func _create_rare_antique_market_details(parent: Node3D, width: float, depth: float, canvas: Material, timber: Material) -> void:
	for row in range(2):
		for stall in range(5):
			var booth := Node3D.new()
			booth.name = "RareAntiqueStall_%02d_%02d" % [row, stall]
			booth.position = Vector3(-width * 0.36 + float(stall) * width * 0.18, 0.0, -depth * 0.22 + float(row) * depth * 0.48)
			parent.add_child(booth)
			var counter := MeshInstance3D.new()
			var counter_mesh := BoxMesh.new()
			counter_mesh.size = Vector3(4.8, 1.2, 3.2)
			counter.mesh = counter_mesh
			counter.position.y = 0.8
			counter.material_override = timber
			booth.add_child(counter)
			var canopy := MeshInstance3D.new()
			var canopy_mesh := BoxMesh.new()
			canopy_mesh.size = Vector3(5.4, 0.35, 4.2)
			canopy.mesh = canopy_mesh
			canopy.position.y = 4.0
			canopy.material_override = canvas
			booth.add_child(canopy)
			var relic := MeshInstance3D.new()
			var relic_mesh := SphereMesh.new()
			relic_mesh.radius = 0.72
			relic.mesh = relic_mesh
			relic.position = Vector3(0.0, 1.85, 0.0)
			relic.material_override = _material(Color(0.72, 0.53, 0.24), 0.3, 0.78)
			booth.add_child(relic)



func _create_civic_interior_blockout(parent: Node3D, service_id: String, width: float, depth: float, stone: Material, glass: Material, timber: Material) -> void:
	var floor := MeshInstance3D.new()
	floor.name = "InteriorFloor_Blockout"
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(width - 2.0, 0.24, depth - 2.0)
	floor.mesh = floor_mesh
	floor.position.y = 0.28
	floor.material_override = _material(Color(0.34, 0.31, 0.26), 0.94, 0.0)
	parent.add_child(floor)
	match service_id:
		"mosque":
			var prayer_carpet := _material(Color(0.22, 0.34, 0.28), 0.98, 0.0)
			for row in range(5):
				var runner := MeshInstance3D.new()
				runner.name = "PrayerCarpetRow_%02d" % row
				var runner_mesh := BoxMesh.new()
				runner_mesh.size = Vector3(width - 7.0, 0.035, 1.55)
				runner.mesh = runner_mesh
				runner.position = Vector3(0.0, 0.43, -depth * 0.31 + float(row) * 3.2)
				runner.material_override = prayer_carpet
				parent.add_child(runner)
			for side in [-1.0, 1.0]:
				for column in range(2):
					var pillar := MeshInstance3D.new()
					pillar.name = "PrayerHallColumn_%s_%d" % [str(side), column]
					var pillar_mesh := CylinderMesh.new()
					pillar_mesh.top_radius = 0.42
					pillar_mesh.bottom_radius = 0.55
					pillar_mesh.height = 7.5
					pillar.mesh = pillar_mesh
					pillar.position = Vector3(side * (width * 0.31), 4.0, -4.0 + float(column) * 8.0)
					pillar.material_override = stone
					parent.add_child(pillar)
		"church":
			for side in [-1.0, 1.0]:
				for row in range(4):
					var pew := MeshInstance3D.new()
					pew.name = "ChurchPew_%s_%02d" % [str(side), row]
					var pew_mesh := BoxMesh.new()
					pew_mesh.size = Vector3(7.0, 0.65, 0.85)
					pew.mesh = pew_mesh
					pew.position = Vector3(side * 7.0, 0.85, -depth * 0.29 + float(row) * 4.0)
					pew.material_override = timber
					parent.add_child(pew)
			var altar := MeshInstance3D.new()
			altar.name = "ChurchAltar_Blockout"
			var altar_mesh := BoxMesh.new()
			altar_mesh.size = Vector3(5.0, 1.1, 2.0)
			altar.mesh = altar_mesh
			altar.position = Vector3(0.0, 0.9, depth * 0.31)
			altar.material_override = stone
			parent.add_child(altar)
			var stained_glass := MeshInstance3D.new()
			stained_glass.name = "ChurchStainedGlass_Blockout"
			var glass_mesh := BoxMesh.new()
			glass_mesh.size = Vector3(4.0, 5.0, 0.16)
			stained_glass.mesh = glass_mesh
			stained_glass.position = Vector3(0.0, 7.0, depth * 0.49)
			stained_glass.material_override = glass
			parent.add_child(stained_glass)
		"museum":
			for index in range(4):
				var pedestal := MeshInstance3D.new()
				pedestal.name = "MuseumExhibitPedestal_%02d" % index
				var pedestal_mesh := BoxMesh.new()
				pedestal_mesh.size = Vector3(3.0, 1.2, 2.8)
				pedestal.mesh = pedestal_mesh
				pedestal.position = Vector3(-width * 0.32 + float(index) * width * 0.21, 0.9, 0.0)
				pedestal.material_override = timber
				parent.add_child(pedestal)
				var case_mesh_node := MeshInstance3D.new()
				case_mesh_node.name = "MuseumGlassCase_%02d" % index
				var case_mesh := BoxMesh.new()
				case_mesh.size = Vector3(2.4, 2.2, 2.1)
				case_mesh_node.mesh = case_mesh
				case_mesh_node.position = pedestal.position + Vector3.UP * 1.7
				case_mesh_node.material_override = glass
				parent.add_child(case_mesh_node)
		"rare_antique_market":
			for index in range(3):
				var display := MeshInstance3D.new()
				display.name = "AntiqueDisplayCabinet_%02d" % index
				var display_mesh := BoxMesh.new()
				display_mesh.size = Vector3(4.2, 2.5, 1.4)
				display.mesh = display_mesh
				display.position = Vector3(-width * 0.3 + float(index) * width * 0.3, 1.55, depth * 0.34)
				display.material_override = glass
				parent.add_child(display)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func get_service_locations() -> Array[Dictionary]:
	return service_locations.duplicate(true)

func _create_stadium_details(parent: Node3D, width: float, depth: float) -> void:
	# Full-size open pitch blockout with collision, markings, goals and four spectator sides.
	# Regulation-size pitch: 105 m × 68 m, kept inside the stadium footprint.
	var pitch_width := minf(width * 0.70, 105.0)
	var pitch_depth := minf(depth * 0.60, 68.0)
	var pitch_material := _material(Color(0.07, 0.31, 0.105), 0.96, 0.0)
	var alternate_grass := _material(Color(0.09, 0.37, 0.13), 0.96, 0.0)
	var line_material := _material(Color(0.92, 0.94, 0.86), 0.9, 0.0)
	var stand_material := _material(Color(0.22, 0.28, 0.36), 0.84, 0.12)
	var roof_material := _material(Color(0.12, 0.17, 0.22), 0.55, 0.3)

	var pitch_body := StaticBody3D.new()
	pitch_body.name = "PlayableFootballPitchCollision"
	var pitch := MeshInstance3D.new()
	pitch.name = "FootballPitch"
	var pitch_mesh := BoxMesh.new()
	pitch_mesh.size = Vector3(pitch_width, 0.3, pitch_depth)
	pitch.mesh = pitch_mesh
	pitch.position.y = 0.9
	pitch.material_override = pitch_material
	pitch_body.add_child(pitch)
	var pitch_collision := CollisionShape3D.new()
	var pitch_shape := BoxShape3D.new()
	pitch_shape.size = Vector3(pitch_width, 0.3, pitch_depth)
	pitch_collision.shape = pitch_shape
	pitch_collision.position.y = 0.9
	pitch_body.add_child(pitch_collision)
	parent.add_child(pitch_body)

	for stripe_index in range(8):
		var stripe := MeshInstance3D.new()
		stripe.name = "GrassStripe_%02d" % stripe_index
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(pitch_width / 8.0, 0.025, pitch_depth)
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(-pitch_width * 0.4375 + float(stripe_index) * pitch_width / 7.0, 1.065, 0.0)
		stripe.material_override = alternate_grass if stripe_index % 2 == 0 else pitch_material
		parent.add_child(stripe)

	_add_stadium_marking(parent, "TouchlineTop", Vector3(0.0, 1.09, -pitch_depth * 0.5), Vector3(pitch_width, 0.045, 0.16), line_material)
	_add_stadium_marking(parent, "TouchlineBottom", Vector3(0.0, 1.09, pitch_depth * 0.5), Vector3(pitch_width, 0.045, 0.16), line_material)
	_add_stadium_marking(parent, "GoalLineLeft", Vector3(-pitch_width * 0.5, 1.09, 0.0), Vector3(0.16, 0.045, pitch_depth), line_material)
	_add_stadium_marking(parent, "GoalLineRight", Vector3(pitch_width * 0.5, 1.09, 0.0), Vector3(0.16, 0.045, pitch_depth), line_material)
	_add_stadium_marking(parent, "HalfwayLine", Vector3(0.0, 1.09, 0.0), Vector3(0.14, 0.045, pitch_depth), line_material)
	var center_spot := MeshInstance3D.new()
	center_spot.name = "CenterSpot"
	var center_spot_mesh := CylinderMesh.new()
	center_spot_mesh.top_radius = 0.22
	center_spot_mesh.bottom_radius = 0.22
	center_spot_mesh.height = 0.035
	center_spot.mesh = center_spot_mesh
	center_spot.position.y = 1.15
	center_spot.material_override = line_material
	parent.add_child(center_spot)

	var center_circle := MeshInstance3D.new()
	center_circle.name = "CenterCircle"
	var circle_mesh := TorusMesh.new()
	circle_mesh.inner_radius = 8.8
	circle_mesh.outer_radius = 9.0
	circle_mesh.rings = 8
	circle_mesh.ring_segments = 48
	center_circle.mesh = circle_mesh
	center_circle.position.y = 1.12
	center_circle.material_override = line_material
	parent.add_child(center_circle)

	for side in [-1.0, 1.0]:
		# Penalty area: 16.5 m deep × 40.32 m wide.
		var penalty_front_x := side * (pitch_width * 0.5 - 16.5)
		_add_stadium_marking(parent, "PenaltyAreaFront_%s" % str(side), Vector3(penalty_front_x, 1.12, 0.0), Vector3(0.16, 0.045, 40.32), line_material)
		for edge in [-1.0, 1.0]:
			_add_stadium_marking(parent, "PenaltyAreaSide_%s_%s" % [str(side), str(edge)], Vector3(side * (pitch_width * 0.5 - 8.25), 1.12, edge * 20.16), Vector3(16.5, 0.045, 0.16), line_material)
		# Goal area: 5.5 m deep × 18.32 m wide.
		var goal_area_front_x := side * (pitch_width * 0.5 - 5.5)
		_add_stadium_marking(parent, "GoalAreaFront_%s" % str(side), Vector3(goal_area_front_x, 1.13, 0.0), Vector3(0.16, 0.045, 18.32), line_material)
		for edge in [-1.0, 1.0]:
			_add_stadium_marking(parent, "GoalAreaSide_%s_%s" % [str(side), str(edge)], Vector3(side * (pitch_width * 0.5 - 2.75), 1.13, edge * 9.16), Vector3(5.5, 0.045, 0.16), line_material)
		var penalty_spot := MeshInstance3D.new()
		penalty_spot.name = "PenaltySpot_%s" % str(side)
		var spot_mesh := CylinderMesh.new()
		spot_mesh.top_radius = 0.22
		spot_mesh.bottom_radius = 0.22
		spot_mesh.height = 0.035
		penalty_spot.mesh = spot_mesh
		penalty_spot.position = Vector3(side * (pitch_width * 0.5 - 11.0), 1.15, 0.0)
		penalty_spot.material_override = line_material
		parent.add_child(penalty_spot)
		_build_stadium_goal(parent, side, pitch_width, pitch_depth, line_material)

	# Four stepped grandstands leave the corners open for access.
	for side in [-1.0, 1.0]:
		for row in range(4):
			var stand := MeshInstance3D.new()
			stand.name = "LongStand_%s_%02d" % [str(side), row]
			var stand_mesh := BoxMesh.new()
			stand_mesh.size = Vector3(pitch_width * 0.82, 1.4, 4.2)
			stand.mesh = stand_mesh
			stand.position = Vector3(0.0, 2.0 + float(row) * 1.5, side * (pitch_depth * 0.5 + 7.0 + float(row) * 3.0))
			stand.material_override = stand_material
			parent.add_child(stand)
	for side in [-1.0, 1.0]:
		for row in range(3):
			var end_stand := MeshInstance3D.new()
			end_stand.name = "EndStand_%s_%02d" % [str(side), row]
			var end_mesh := BoxMesh.new()
			end_mesh.size = Vector3(4.0, 1.4, pitch_depth * 0.55)
			end_stand.mesh = end_mesh
			end_stand.position = Vector3(side * (pitch_width * 0.5 + 7.0 + float(row) * 3.0), 2.0 + float(row) * 1.5, 0.0)
			end_stand.material_override = stand_material
			parent.add_child(end_stand)
	var canopy := MeshInstance3D.new()
	canopy.name = "StadiumRoofCanopy"
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(pitch_width + 30.0, 1.0, 5.0)
	canopy.mesh = canopy_mesh
	canopy.position = Vector3(0.0, 10.0, -pitch_depth * 0.5 - 13.0)
	canopy.material_override = roof_material
	parent.add_child(canopy)

func _build_stadium_goal(parent: Node3D, side: float, pitch_width: float, pitch_depth: float, material: Material) -> void:
	var goal_center := Vector3(side * (pitch_width * 0.5 + 0.15), 1.1, 0.0)
	for post_side in [-1.0, 1.0]:
		_add_stadium_marking(parent, "GoalPost_%s_%s" % [str(side), str(post_side)], goal_center + Vector3(0.0, 1.2, post_side * 3.66), Vector3(0.18, 2.4, 0.18), material)
	_add_stadium_marking(parent, "GoalCrossbar_%s" % str(side), goal_center + Vector3(0.0, 2.4, 0.0), Vector3(0.18, 0.18, 7.5), material)
	_add_stadium_marking(parent, "GoalNetBack_%s" % str(side), goal_center + Vector3(side * 2.0, 1.0, 0.0), Vector3(0.12, 2.0, 7.3), material)

func _add_stadium_marking(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var marking := MeshInstance3D.new()
	marking.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	marking.mesh = mesh
	marking.position = position
	marking.material_override = material
	parent.add_child(marking)


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

