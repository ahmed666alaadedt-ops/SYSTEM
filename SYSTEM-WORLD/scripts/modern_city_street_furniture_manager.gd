extends Node3D
class_name ModernCityStreetFurnitureManager

## Lightweight visual city details: crosswalks, signal heads, bus shelters and parking bays.
## Signal phases are decorative until the traffic AI is connected to this controller.

const SIGNAL_CYCLE_SECONDS := 24.0
var region_manager: Node
var signal_groups: Array[Dictionary] = []
var elapsed := 0.0
var city_check_clock := 0.0
var active_city_name := ""
var white_material: StandardMaterial3D
var dark_material: StandardMaterial3D
var shelter_material: StandardMaterial3D
var red_material: StandardMaterial3D
var amber_material: StandardMaterial3D
var green_material: StandardMaterial3D

func _ready() -> void:
	name = "ModernCityStreetFurnitureManager"
	region_manager = get_parent()
	if region_manager == null or not region_manager.has_method("get_city_names"):
		return
	_create_materials()
	active_city_name = _find_nearest_city_name(Vector3.ZERO)
	_build_city_furniture(active_city_name)
	print("SYSTEM WORLD: streamed street furniture for ", active_city_name)

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


func _build_city_furniture(city_name: String) -> void:
	var anchor: Vector3 = region_manager.call("get_city_anchor", city_name)
	if anchor == Vector3.INF:
		return
	_build_crosswalks(city_name, anchor)
	_build_traffic_signals(city_name, anchor)
	_build_bus_shelters(city_name, anchor)
	_build_parking_bays(city_name, anchor)


func _rebuild_city_furniture(city_name: String) -> void:
	for child in get_children():
		child.queue_free()
	signal_groups.clear()
	active_city_name = city_name
	_build_city_furniture(active_city_name)


func _create_materials() -> void:
	white_material = _material(Color(0.88, 0.88, 0.82), 0.8)
	dark_material = _material(Color(0.055, 0.065, 0.075), 0.92, 0.1)
	shelter_material = _material(Color(0.12, 0.27, 0.33), 0.38, 0.42)
	red_material = _emissive(Color(0.85, 0.045, 0.025))
	amber_material = _emissive(Color(1.0, 0.52, 0.04))
	green_material = _emissive(Color(0.04, 0.8, 0.22))

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emissive(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.35, 0.0)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.7
	return material

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	instance.visibility_range_end = 650.0
	parent.add_child(instance)
	return instance

func _build_crosswalks(city_name: String, anchor: Vector3) -> void:
	var root := Node3D.new()
	root.name = city_name.replace(" ", "") + "_PedestrianCrossings"
	root.position = anchor
	add_child(root)
	for index in range(8):
		var offset := -7.0 + float(index) * 2.0
		_add_box(root, "NorthSouthCrosswalkStripe_%02d" % index, Vector3(offset, 0.62, -9.0), Vector3(1.0, 0.045, 8.0), white_material)
		_add_box(root, "EastWestCrosswalkStripe_%02d" % index, Vector3(9.0, 0.62, offset), Vector3(8.0, 0.045, 1.0), white_material)

func _build_traffic_signals(city_name: String, anchor: Vector3) -> void:
	var group := {"city": city_name, "lights": []}
	var root := Node3D.new()
	root.name = city_name.replace(" ", "") + "_TrafficSignals"
	root.position = anchor
	add_child(root)
	var corners := [
		Vector2(-10.0, -10.0), Vector2(10.0, -10.0),
		Vector2(-10.0, 10.0), Vector2(10.0, 10.0)
	]
	for index in range(corners.size()):
		var corner: Vector2 = corners[index]
		var pole := Node3D.new()
		pole.position = Vector3(corner.x, 0.0, corner.y)
		root.add_child(pole)
		_add_box(pole, "SignalPole", Vector3(0.0, 3.0, 0.0), Vector3(0.22, 6.0, 0.22), dark_material)
		_add_box(pole, "SignalHousing", Vector3(0.0, 5.2, -0.35), Vector3(0.85, 2.0, 0.65), dark_material)
		var red := _add_box(pole, "RedSignal", Vector3(0.0, 5.78, -0.71), Vector3(0.38, 0.38, 0.12), red_material)
		var amber := _add_box(pole, "AmberSignal", Vector3(0.0, 5.2, -0.71), Vector3(0.38, 0.38, 0.12), dark_material)
		var green := _add_box(pole, "GreenSignal", Vector3(0.0, 4.62, -0.71), Vector3(0.38, 0.38, 0.12), dark_material)
		group["lights"].append({"red": red, "amber": amber, "green": green})
	signal_groups.append(group)

func _build_bus_shelters(city_name: String, anchor: Vector3) -> void:
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var shelter := Node3D.new()
		shelter.name = city_name.replace(" ", "") + "_BusShelter_%02d" % index
		shelter.position = anchor + Vector3(side * 19.0, 0.0, -62.0)
		add_child(shelter)
		_add_box(shelter, "BusStopPlatform", Vector3.ZERO, Vector3(9.0, 0.25, 5.0), white_material)
		_add_box(shelter, "ShelterRoof", Vector3(0.0, 3.0, 0.0), Vector3(8.0, 0.25, 3.5), shelter_material)
		for post_x in [-3.5, 3.5]:
			for post_z in [-1.4, 1.4]:
				_add_box(shelter, "ShelterPost", Vector3(post_x, 1.5, post_z), Vector3(0.16, 3.0, 0.16), dark_material)
		_add_box(shelter, "BusStopBench", Vector3(0.0, 0.85, 0.7), Vector3(4.8, 0.22, 0.7), shelter_material)
		_add_box(shelter, "BusStopSign", Vector3(4.8, 2.0, -1.8), Vector3(0.18, 3.6, 0.18), dark_material)

func _build_parking_bays(city_name: String, anchor: Vector3) -> void:
	var lot := Node3D.new()
	lot.name = city_name.replace(" ", "") + "_PublicParking"
	lot.position = anchor + Vector3(62.0, 0.0, 52.0)
	add_child(lot)
	_add_box(lot, "ParkingLotSurface", Vector3.ZERO, Vector3(38.0, 0.18, 26.0), dark_material)
	for index in range(8):
		var x := -16.0 + float(index) * 4.5
		_add_box(lot, "ParkingBayLine_%02d" % index, Vector3(x, 0.12, 0.0), Vector3(0.12, 0.035, 20.0), white_material)
	_add_box(lot, "ParkingEntranceMark", Vector3(0.0, 0.13, 12.0), Vector3(9.0, 0.04, 0.3), white_material)

func _process(delta: float) -> void:
	elapsed += delta
	city_check_clock += delta
	if city_check_clock >= 4.0:
		city_check_clock = 0.0
		var player := region_manager.get_parent().get_node_or_null("Player") as Node3D
		var player_position := player.global_position if is_instance_valid(player) else Vector3.ZERO
		var nearest_city := _find_nearest_city_name(player_position)
		if nearest_city != active_city_name:
			_rebuild_city_furniture(nearest_city)
	var phase := fposmod(elapsed, SIGNAL_CYCLE_SECONDS)
	for group in signal_groups:
		var lights: Array = group["lights"]
		for index in range(lights.size()):
			var light_set: Dictionary = lights[index]
			var use_horizontal := index < 2
			var green_active := (phase < 10.0) if use_horizontal else (phase >= 12.0 and phase < 22.0)
			var amber_active := (phase >= 10.0 and phase < 12.0) if use_horizontal else (phase >= 22.0)
			_set_signal(light_set, green_active, amber_active, not green_active and not amber_active)

func _set_signal(light_set: Dictionary, green_on: bool, amber_on: bool, red_on: bool) -> void:
	var red := light_set["red"] as MeshInstance3D
	var amber := light_set["amber"] as MeshInstance3D
	var green := light_set["green"] as MeshInstance3D
	red.material_override = red_material if red_on else dark_material
	amber.material_override = amber_material if amber_on else dark_material
	green.material_override = green_material if green_on else dark_material
