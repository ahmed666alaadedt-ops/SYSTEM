extends Node3D
class_name ModernCityServicesManager

## First-pass city service buildings and discoverable interaction markers.
## Functional service menus, interiors and backend transactions are future work.

const SERVICE_DATA := [
	{"id": "hospital", "name": "General Hospital", "prompt": "المستشفى — الخدمات الطبية قيد التطوير", "color": Color(0.78, 0.82, 0.82), "height": 22.0},
	{"id": "police", "name": "Police Headquarters", "prompt": "مركز الشرطة — خدمات القانون قيد التطوير", "color": Color(0.18, 0.28, 0.38), "height": 19.0},
	{"id": "fire", "name": "Fire and Rescue Station", "prompt": "مركز الإطفاء والإنقاذ", "color": Color(0.55, 0.18, 0.12), "height": 13.0},
	{"id": "hotel", "name": "Grand City Hotel", "prompt": "الفندق — الحجز والإقامة قيد التطوير", "color": Color(0.48, 0.38, 0.26), "height": 28.0},
	{"id": "market", "name": "Central Market", "prompt": "السوق المركزي — التجارة قيد التطوير", "color": Color(0.38, 0.42, 0.31), "height": 12.0},
	{"id": "garage", "name": "Vehicle Service Garage", "prompt": "كراج المركبات — الصيانة قيد التطوير", "color": Color(0.25, 0.31, 0.35), "height": 11.0}
]

var region_manager: Node
var terrain: Node
var service_locations: Array[Dictionary] = []

func _ready() -> void:
	name = "ModernCityServicesManager"
	region_manager = get_parent()
	if region_manager == null or not region_manager.has_method("get_city_names"):
		return
	terrain = region_manager.get("terrain")
	if terrain == null:
		return
	for city_value in region_manager.call("get_city_names"):
		_build_city_services(str(city_value))
	print("SYSTEM WORLD: city service buildings created = ", service_locations.size())

func _build_city_services(city_name: String) -> void:
	var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
	if anchor == Vector3.INF:
		return
	for index in range(SERVICE_DATA.size()):
		var definition: Dictionary = SERVICE_DATA[index]
		var angle := TAU * float(index) / float(SERVICE_DATA.size()) + deg_to_rad(15.0)
		var requested := Vector2(anchor.x, anchor.z) + Vector2(cos(angle), sin(angle)) * 205.0
		var resolved: Vector2 = region_manager.call("_nearest_land_position", requested)
		if resolved == Vector2.INF:
			continue
		_create_service_building(city_name, definition, resolved, index)

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
	structure_mesh.size = Vector3(width, height, depth)
	structure.mesh = structure_mesh
	structure.position.y = height * 0.5
	structure.material_override = facade
	structure.visibility_range_end = 1100.0
	body.add_child(structure)
	var collision := CollisionShape3D.new()
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(width, height, depth)
	collision.shape = collision_shape
	collision.position.y = height * 0.5
	body.add_child(collision)

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
	var visible_window_bands := 3 if height > 15.0 else 2
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

	service_locations.append({
		"id": location_id,
		"city": city_name,
		"name": city_name + " " + str(definition["name"]),
		"position": building.position,
		"service_type": service_id,
		"location_type": location_type
	})

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func get_service_locations() -> Array[Dictionary]:
	return service_locations.duplicate(true)
