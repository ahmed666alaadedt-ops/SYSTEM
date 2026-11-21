extends Node3D
class_name SYSTEMBaghdadTowerFloorWorld

const EntranceScript = preload("res://scripts/system_tower_entrance.gd")
const FLOOR_SIZE := 112.0
const FLOOR_HALF := FLOOR_SIZE * 0.5

var tower_id := ""
var max_floors := 1
var active_floor := 0
var external_return_position := Vector3.ZERO
var active_floor_root: Node3D


func setup(p_tower_id: String, p_max_floors: int) -> void:
	tower_id = p_tower_id.strip_edges()
	max_floors = maxi(1, p_max_floors)


func build_floor(floor_number: int, return_position: Vector3) -> Dictionary:
	if tower_id.is_empty() or floor_number < 1 or floor_number > max_floors:
		return {"success": false, "reason": "INVALID_TOWER_FLOOR"}
	if is_instance_valid(active_floor_root):
		remove_child(active_floor_root)
		active_floor_root.queue_free()
	active_floor = floor_number
	external_return_position = return_position
	active_floor_root = Node3D.new()
	active_floor_root.name = "ActiveTowerFloor_%03d" % floor_number
	active_floor_root.position = Vector3.ZERO
	add_child(active_floor_root)
	active_floor_root.set_meta("tower_id", tower_id)
	active_floor_root.set_meta("floor_number", floor_number)
	active_floor_root.set_meta("tower_floor_world", true)
	var floor_variant := (floor_number - 1) % 4
	active_floor_root.set_meta("floor_theme_variant", floor_variant)
	_build_shell(floor_number)
	_build_tower_theme(floor_number)
	_build_exit()
	return {
		"success": true,
		"tower_id": tower_id,
		"floor": floor_number,
		"max_floors": max_floors,
		"floor_variant": (floor_number - 1) % 4,
		"entry_position": get_entry_position(),
		"return_position": external_return_position
	}


func get_entry_position() -> Vector3:
	if not is_instance_valid(active_floor_root):
		return global_position
	return active_floor_root.to_global(Vector3(0.0, 1.5, FLOOR_HALF - 12.0))


func get_active_floor_status() -> Dictionary:
	return {
		"tower_id": tower_id,
		"floor": active_floor,
		"max_floors": max_floors,
		"active": is_instance_valid(active_floor_root)
	}


func clear_active_floor() -> void:
	if is_instance_valid(active_floor_root):
		remove_child(active_floor_root)
		active_floor_root.queue_free()
	active_floor_root = null
	active_floor = 0


func _build_shell(floor_number: int) -> void:
	var floor_material := _material(Color(0.10, 0.14, 0.19), 0.5, 0.45)
	var wall_material := _material(Color(0.035, 0.065, 0.095), 0.38, 0.58)
	var accent := _accent_material()
	_add_box("FloorGround", Vector3(0.0, -0.35, 0.0), Vector3(FLOOR_SIZE, 0.7, FLOOR_SIZE), floor_material, true)
	_add_box("NorthWall", Vector3(0.0, 7.0, -FLOOR_HALF), Vector3(FLOOR_SIZE, 14.0, 1.0), wall_material, true)
	_add_box("WestWall", Vector3(-FLOOR_HALF, 7.0, 0.0), Vector3(1.0, 14.0, FLOOR_SIZE), wall_material, true)
	_add_box("EastWall", Vector3(FLOOR_HALF, 7.0, 0.0), Vector3(1.0, 14.0, FLOOR_SIZE), wall_material, true)
	_add_box("SouthWallLeft", Vector3(-34.0, 7.0, FLOOR_HALF), Vector3(44.0, 14.0, 1.0), wall_material, true)
	_add_box("SouthWallRight", Vector3(34.0, 7.0, FLOOR_HALF), Vector3(44.0, 14.0, 1.0), wall_material, true)
	_add_box("SouthDoorHeader", Vector3(0.0, 12.0, FLOOR_HALF), Vector3(24.0, 4.0, 1.0), wall_material, true)
	_add_box("Ceiling", Vector3(0.0, 14.0, 0.0), Vector3(FLOOR_SIZE, 0.7, FLOOR_SIZE), wall_material, true)
	_add_box("CentralWalkway", Vector3(0.0, 0.04, 0.0), Vector3(12.0, 0.08, FLOOR_SIZE - 10.0), accent, false)
	var title := Label3D.new()
	title.name = "TowerFloorTitle"
	title.text = "%s\nFLOOR %03d / %03d" % [_tower_title(), floor_number, max_floors]
	title.font_size = 34
	title.position = Vector3(0.0, 10.5, -FLOOR_HALF + 3.0)
	title.pixel_size = 0.014
	title.modulate = Color(0.82, 0.93, 1.0)
	active_floor_root.add_child(title)
	var light := OmniLight3D.new()
	light.name = "TowerFloorLighting"
	light.position = Vector3(0.0, 11.0, 0.0)
	light.light_color = Color(0.36, 0.68, 0.95)
	light.light_energy = 2.0
	light.omni_range = 100.0
	light.shadow_enabled = false
	active_floor_root.add_child(light)
	for index in range(8):
		var pillar_x := -42.0 + float(index % 4) * 28.0
		var pillar_z := -28.0 if index < 4 else 28.0
		_add_box("StructuralPillar_%02d" % index, Vector3(pillar_x, 6.0, pillar_z), Vector3(2.2, 12.0, 2.2), accent, true)


func _build_tower_theme(floor_number: int) -> void:
	var base := _material(Color(0.14, 0.19, 0.24), 0.48, 0.42)
	var accent := _accent_material()
	var variant := (floor_number - 1) % 4
	match tower_id:
		"business_tower_baghdad":
			match variant:
				0:
					for index in range(4):
						var x := -34.0 + float(index) * 22.0
						_add_box("BusinessOffice_%02d" % index, Vector3(x, 1.6, -18.0), Vector3(15.0, 3.2, 16.0), base, true)
					_add_box("BusinessCouncilTable", Vector3(0.0, 1.2, 20.0), Vector3(28.0, 0.8, 8.0), accent, true)
				1:
					for row in range(3):
						for column in range(4):
							var x := -36.0 + float(column) * 24.0
							var z := -24.0 + float(row) * 20.0
							_add_box("TradingDesk_%02d_%02d" % [row, column], Vector3(x, 1.1, z), Vector3(12.0, 2.2, 7.0), base, true)
					_add_box("MarketTickerWall", Vector3(0.0, 8.0, -49.0), Vector3(62.0, 12.0, 0.6), accent, false)
				2:
					_add_box("ExecutiveBoardroomTable", Vector3(0.0, 1.2, 0.0), Vector3(36.0, 1.0, 12.0), accent, true)
					for index in range(10):
						var side := -1.0 if index < 5 else 1.0
						var seat_index := index % 5
						_add_box("BoardroomSeat_%02d" % index, Vector3(side * 22.0, 0.6, -18.0 + float(seat_index) * 9.0), Vector3(4.0, 1.2, 4.0), base, true)
					_add_box("BoardroomPresentationWall", Vector3(0.0, 8.0, -48.0), Vector3(42.0, 12.0, 0.6), accent, false)
				_:
					for index in range(3):
						var x := -30.0 + float(index) * 30.0
						_add_box("ExecutiveSuite_%02d" % index, Vector3(x, 2.0, -18.0), Vector3(22.0, 4.0, 18.0), base, true)
					_add_box("ExecutiveReceptionDesk", Vector3(0.0, 1.5, 24.0), Vector3(30.0, 3.0, 6.0), accent, true)
		"shopping_tower_baghdad":
			match variant:
				0:
					for index in range(6):
						var x := -40.0 + float(index) * 16.0
						_add_box("RetailKiosk_%02d" % index, Vector3(x, 1.7, -15.0), Vector3(11.0, 3.4, 14.0), base, true)
						_add_box("RetailCanopy_%02d" % index, Vector3(x, 3.6, -15.0), Vector3(12.0, 0.35, 15.0), accent, false)
					_add_box("MarketServiceIsland", Vector3(0.0, 1.0, 24.0), Vector3(30.0, 2.0, 7.0), base, true)
				1:
					for index in range(5):
						var x := -40.0 + float(index) * 20.0
						_add_box("FashionDisplayPod_%02d" % index, Vector3(x, 1.4, -12.0), Vector3(12.0, 2.8, 14.0), base, true)
						_add_box("FashionDisplayScreen_%02d" % index, Vector3(x, 5.0, -20.0), Vector3(9.0, 6.0, 0.35), accent, false)
					_add_box("FashionRunway", Vector3(0.0, 0.15, 22.0), Vector3(12.0, 0.3, 38.0), accent, true)
				2:
					for index in range(4):
						var x := -36.0 + float(index) * 24.0
						_add_box("FoodCourtCounter_%02d" % index, Vector3(x, 1.5, -20.0), Vector3(16.0, 3.0, 7.0), accent, true)
						_add_box("FoodCourtTable_%02d" % index, Vector3(x, 0.9, 16.0), Vector3(10.0, 1.8, 8.0), base, true)
				_:
					for index in range(4):
						var x := -30.0 + float(index) * 20.0
						_add_box("ElectronicsIsland_%02d" % index, Vector3(x, 1.3, -12.0), Vector3(14.0, 2.6, 12.0), base, true)
						_add_box("ElectronicsDisplay_%02d" % index, Vector3(x, 5.0, -18.0), Vector3(11.0, 5.5, 0.3), accent, false)
					_add_box("ElectronicsDemoStage", Vector3(0.0, 1.0, 28.0), Vector3(32.0, 2.0, 10.0), accent, true)
		"entertainment_tower_baghdad":
			match variant:
				0:
					_add_box("EntertainmentStage", Vector3(0.0, 1.2, -28.0), Vector3(34.0, 2.4, 14.0), accent, true)
					for row in range(4):
						_add_box("AudienceTier_%02d" % row, Vector3(0.0, 1.0 + float(row) * 1.2, 3.0 + float(row) * 8.0), Vector3(38.0 - float(row) * 3.0, 0.8, 3.0), base, true)
				1:
					_add_box("EsportsArenaStage", Vector3(0.0, 1.0, -22.0), Vector3(28.0, 2.0, 12.0), accent, true)
					for row in range(3):
						for column in range(5):
							var x := -36.0 + float(column) * 18.0
							var z := 2.0 + float(row) * 14.0
							_add_box("EsportsPlayerStation_%02d_%02d" % [row, column], Vector3(x, 1.0, z), Vector3(8.0, 2.0, 5.0), base, true)
				2:
					_add_box("CinemaScreen", Vector3(0.0, 8.0, -48.0), Vector3(54.0, 16.0, 0.5), accent, false)
					for row in range(5):
						_add_box("CinemaSeatRow_%02d" % row, Vector3(0.0, 1.0 + float(row) * 0.7, -12.0 + float(row) * 12.0), Vector3(48.0, 1.0, 3.0), base, true)
				_:
					_add_box("IndoorSportsCourt", Vector3(0.0, 0.12, 0.0), Vector3(58.0, 0.24, 42.0), accent, true)
					for side in [-1.0, 1.0]:
						_add_box("SportsCourtGoal_%s" % str(int(side)), Vector3(0.0, 3.0, side * 23.0), Vector3(12.0, 6.0, 1.0), base, true)
					for row in range(3):
						_add_box("SportsSpectatorTier_%02d" % row, Vector3(0.0, 1.0 + float(row) * 1.2, -48.0 + float(row) * 4.0), Vector3(44.0, 0.8, 3.0), base, true)
		"technology_tower_baghdad":
			match variant:
				0:
					for index in range(4):
						var x := -30.0 + float(index) * 20.0
						_add_box("InnovationWorkbench_%02d" % index, Vector3(x, 1.0, -14.0), Vector3(14.0, 1.0, 8.0), base, true)
						_add_box("InnovationDisplay_%02d" % index, Vector3(x, 4.0, -19.0), Vector3(10.0, 5.0, 0.5), accent, false)
				1:
					for index in range(6):
						var x := -40.0 + float(index) * 16.0
						_add_box("ResearchLabBench_%02d" % index, Vector3(x, 1.0, -10.0), Vector3(10.0, 2.0, 9.0), base, true)
						_add_box("ResearchContainmentPod_%02d" % index, Vector3(x, 4.0, 16.0), Vector3(7.0, 6.0, 7.0), accent, true)
				2:
					for row in range(3):
						for column in range(5):
							var x := -40.0 + float(column) * 20.0
							var z := -25.0 + float(row) * 22.0
							_add_box("ServerRack_%02d_%02d" % [row, column], Vector3(x, 4.0, z), Vector3(8.0, 8.0, 7.0), base, true)
					_add_box("NetworkOperationsWall", Vector3(0.0, 9.0, -49.0), Vector3(54.0, 14.0, 0.5), accent, false)
				_:
					for index in range(4):
						var x := -30.0 + float(index) * 20.0
						_add_box("PrototypeDisplayPod_%02d" % index, Vector3(x, 1.5, 0.0), Vector3(12.0, 3.0, 12.0), accent, true)
						_add_box("PrototypeWorkstation_%02d" % index, Vector3(x, 1.0, 26.0), Vector3(10.0, 2.0, 6.0), base, true)
		_:
			match variant:
				0:
					_add_box("HunterTrainingMat", Vector3(0.0, 0.08, -12.0), Vector3(34.0, 0.16, 26.0), accent, false)
					_add_box("HunterBriefingTable", Vector3(0.0, 1.5, 27.0), Vector3(24.0, 1.0, 7.0), base, true)
					for index in range(5):
						_add_box("HunterTrainingObstacle_%02d" % index, Vector3(-32.0 + float(index) * 16.0, 1.0, -34.0), Vector3(5.0, 2.0 + float((index + floor_number) % 3), 5.0), base, true)
				1:
					_add_box("HunterMissionBriefingTable", Vector3(0.0, 1.5, 10.0), Vector3(30.0, 1.0, 12.0), base, true)
					_add_box("HunterMissionBoard", Vector3(0.0, 8.0, -48.0), Vector3(46.0, 14.0, 0.5), accent, false)
					for index in range(4):
						_add_box("HunterSquadPlanningDesk_%02d" % index, Vector3(-30.0 + float(index) * 20.0, 1.0, -18.0), Vector3(12.0, 2.0, 7.0), base, true)
				2:
					_add_box("HunterSparringCircle", Vector3(0.0, 0.1, 0.0), Vector3(42.0, 0.2, 42.0), accent, true)
					for index in range(8):
						var angle := TAU * float(index) / 8.0
						_add_box("HunterSparringPillar_%02d" % index, Vector3(cos(angle) * 22.0, 3.0, sin(angle) * 22.0), Vector3(3.0, 6.0, 3.0), base, true)
				_:
					for index in range(6):
						var x := -40.0 + float(index) * 16.0
						_add_box("HunterWeaponPracticeTarget_%02d" % index, Vector3(x, 3.0, -25.0), Vector3(3.0, 6.0, 2.0), accent, true)
					_add_box("HunterWeaponsRack", Vector3(0.0, 2.0, 24.0), Vector3(32.0, 4.0, 5.0), base, true)
	var floor_label := Label3D.new()
	floor_label.name = "FloorThemeIdentity"
	floor_label.text = "%s — %03d\nVARIANT %d" % [_tower_title(), floor_number, variant + 1]
	floor_label.font_size = 25
	floor_label.position = Vector3(0.0, 8.0, 36.0)
	floor_label.pixel_size = 0.012
	floor_label.modulate = Color(0.82, 0.92, 1.0)
	active_floor_root.add_child(floor_label)


func _build_exit() -> void:
	var exit_area := EntranceScript.new()
	exit_area.name = "TowerFloorExit"
	exit_area.configure("tower_floor_exit_" + tower_id, "العودة إلى بهو البرج", "region_baghdad")
	exit_area.position = Vector3(0.0, 1.5, FLOOR_HALF - 5.0)
	exit_area.set_meta("system_return_position", external_return_position)
	exit_area.set_meta("system_tower_id", tower_id)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.5
	collision.shape = shape
	exit_area.add_child(collision)
	active_floor_root.add_child(exit_area)


func _tower_title() -> String:
	match tower_id:
		"hunter_association_tower_baghdad": return "برج نقابة الصيادين"
		"business_tower_baghdad": return "برج الأعمال"
		"shopping_tower_baghdad": return "برج التسوق"
		"entertainment_tower_baghdad": return "برج الترفيه"
		"technology_tower_baghdad": return "برج التكنولوجيا والابتكار"
		_: return "برج بغداد"


func _accent_material() -> StandardMaterial3D:
	var color := Color(0.08, 0.62, 0.92)
	match tower_id:
		"business_tower_baghdad": color = Color(0.24, 0.78, 0.72)
		"shopping_tower_baghdad": color = Color(0.95, 0.72, 0.28)
		"entertainment_tower_baghdad": color = Color(0.75, 0.38, 0.95)
		"technology_tower_baghdad": color = Color(0.18, 0.88, 0.78)
	var material := _material(color, 0.26, 0.5)
	material.emission_enabled = true
	material.emission = color * 0.22
	material.emission_energy_multiplier = 1.2
	return material


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, with_collision: bool) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	active_floor_root.add_child(visual)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "_Collision"
		body.position = position
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		active_floor_root.add_child(body)


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
