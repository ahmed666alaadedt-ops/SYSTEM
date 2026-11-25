extends Node3D
class_name SYSTEMPowerTowerXSXArchitecture

const TOWER_HEIGHT := 820.0
const BASE_RADIUS := 26.0
const FLOOR_COUNT := 200
const TIER_LEVELS := [205.0, 420.0, 635.0]
const BRAND := "X-S-X"

var dark_glass: StandardMaterial3D
var titanium: StandardMaterial3D
var gold_trim: StandardMaterial3D
var red_emissive: StandardMaterial3D
var white_emissive: StandardMaterial3D

func _ready() -> void:
	name = "PowerTowerXSXArchitecture"
	set_meta("system_power_tower_visual_contract", "XSX_APPROVED_REFERENCE")
	set_meta("system_power_tower_floor_count", FLOOR_COUNT)
	set_meta("system_power_tower_independent_landmark", true)
	set_meta("system_power_tower_shop_modern_firearms_allowed", false)
	_create_materials()
	_build_tapered_silhouette()
	_build_structural_tiers()
	_build_xsx_identity()
	_build_observatory_and_rooftop_pad()
	_build_circular_entrance_podium()
	print("SYSTEM WORLD: X-S-X Power Tower architectural layers generated.")

func _create_materials() -> void:
	dark_glass = StandardMaterial3D.new()
	dark_glass.albedo_color = Color(0.025, 0.055, 0.085)
	dark_glass.metallic = 0.78
	dark_glass.roughness = 0.2
	dark_glass.emission_enabled = true
	dark_glass.emission = Color(0.018, 0.11, 0.19)
	dark_glass.emission_energy_multiplier = 0.38

	titanium = StandardMaterial3D.new()
	titanium.albedo_color = Color(0.34, 0.39, 0.44)
	titanium.metallic = 0.88
	titanium.roughness = 0.24

	gold_trim = StandardMaterial3D.new()
	gold_trim.albedo_color = Color(0.78, 0.52, 0.19)
	gold_trim.metallic = 0.9
	gold_trim.roughness = 0.19
	gold_trim.emission_enabled = true
	gold_trim.emission = Color(0.42, 0.19, 0.045)
	gold_trim.emission_energy_multiplier = 0.65

	red_emissive = _emissive(Color(0.96, 0.035, 0.045), 2.8)
	white_emissive = _emissive(Color(0.82, 0.91, 1.0), 1.45)

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _add_cylinder(parent: Node3D, node_name: String, top_radius: float, bottom_radius: float, height: float, y: float, material: Material, segments: int = 64) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh_instance.mesh = mesh
	mesh_instance.position.y = y
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_ring(parent: Node3D, node_name: String, inner_radius: float, outer_radius: float, y: float, material: Material) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	ring.name = node_name
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 72
	mesh.ring_segments = 12
	ring.mesh = mesh
	ring.rotation.x = PI * 0.5
	ring.position.y = y
	ring.material_override = material
	parent.add_child(ring)
	return ring

func _build_tapered_silhouette() -> void:
	# Layered tapered glass-and-titanium crown supplements the existing 200-floor shaft.
	var sections := [
		{"name":"LowerGlassCrown", "bottom":25.0, "top":20.0, "height":175.0, "center":95.0},
		{"name":"MiddleGlassCrown", "bottom":20.0, "top":13.5, "height":230.0, "center":300.0},
		{"name":"UpperGlassCrown", "bottom":13.5, "top":7.2, "height":245.0, "center":537.5},
		{"name":"SkyObservatorySpire", "bottom":7.2, "top":1.2, "height":150.0, "center":735.0}
	]
	for section in sections:
		_add_cylinder(self, str(section["name"]), float(section["top"]), float(section["bottom"]), float(section["height"]), float(section["center"]) + 7.0, dark_glass, 96)
	set_meta("system_power_tower_tapered_sections", sections.size())

func _build_structural_tiers() -> void:
	for index in range(TIER_LEVELS.size()):
		var level: float = float(TIER_LEVELS[index])
		var radius := 31.0 - float(index) * 5.0
		_add_cylinder(self, "TitaniumSkyTier_%d" % (index + 1), radius - 1.2, radius + 2.2, 5.0, level + 7.0, titanium)
		_add_ring(self, "IlluminatedTierRing_%d" % (index + 1), radius - 0.35, radius + 0.15, level + 9.7, white_emissive)
		_add_ring(self, "GoldStructuralRing_%d" % (index + 1), radius + 1.8, radius + 2.35, level + 5.0, gold_trim)
	set_meta("system_power_tower_structural_tier_count", TIER_LEVELS.size())

func _build_xsx_identity() -> void:
	var sign_levels := [34.0, 410.0, 790.0]
	var sign_count := 0
	for side in range(4):
		var angle := TAU * float(side) / 4.0
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		for level in sign_levels:
			var plaque := MeshInstance3D.new()
			plaque.name = "XSXFacadePlaque_%02d_%03d" % [side, int(level)]
			var plaque_mesh := BoxMesh.new()
			plaque_mesh.size = Vector3(0.8, 8.0 if level != 410.0 else 12.0, 18.0 if level != 410.0 else 22.0)
			plaque.mesh = plaque_mesh
			plaque.position = outward * (BASE_RADIUS * 0.91) + Vector3(0.0, level, 0.0)
			plaque.look_at(plaque.position + outward, Vector3.UP)
			plaque.material_override = red_emissive
			add_child(plaque)
			var label := Label3D.new()
			label.name = "XSXIdentity_%02d_%03d" % [side, int(level)]
			label.text = BRAND
			label.font_size = 72 if level == 410.0 else 44
			label.pixel_size = 0.018
			label.modulate = Color(1.0, 0.95, 0.9)
			label.position = plaque.position + outward * 0.58
			label.rotation.y = -angle
			add_child(label)
			sign_count += 1
	set_meta("system_power_tower_xsx_facade_sign_count", sign_count)

func _build_observatory_and_rooftop_pad() -> void:
	var observatory := Node3D.new()
	observatory.name = "SkyObservatory"
	observatory.position.y = 775.0
	observatory.set_meta("system_facility_type", "sky_observatory")
	add_child(observatory)
	_add_cylinder(observatory, "ObservatoryGlassPod", 5.0, 7.0, 18.0, 0.0, dark_glass, 48)
	_add_ring(observatory, "ObservatoryGoldRim", 6.8, 7.35, -8.2, gold_trim)
	var observatory_sign := Label3D.new()
	observatory_sign.name = "ObservatorySign"
	observatory_sign.text = "SKY OBSERVATORY"
	observatory_sign.font_size = 30
	observatory_sign.position = Vector3(0.0, -12.0, 8.0)
	observatory_sign.modulate = Color(0.82, 0.93, 1.0)
	observatory.add_child(observatory_sign)

	var pad := Node3D.new()
	pad.name = "PowerTowerRooftopHelipad"
	pad.position.y = 820.0
	pad.set_meta("system_facility_type", "helicopter_landing_pad")
	add_child(pad)
	_add_cylinder(pad, "HelipadDeck", 14.0, 14.0, 1.4, 0.0, titanium)
	_add_ring(pad, "HelipadPerimeter", 12.2, 12.65, 0.75, white_emissive)
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var lamp := MeshInstance3D.new()
		lamp.name = "HelipadLight_%02d" % index
		var sphere := SphereMesh.new()
		sphere.radius = 0.42
		sphere.height = 0.84
		lamp.mesh = sphere
		lamp.position = Vector3(cos(angle) * 11.0, 1.0, sin(angle) * 11.0)
		lamp.material_override = red_emissive
		pad.add_child(lamp)
	var h := Label3D.new()
	h.name = "HelipadH"
	h.text = "H"
	h.font_size = 110
	h.position.y = 1.0
	h.modulate = Color(1.0, 1.0, 1.0)
	pad.add_child(h)
	set_meta("system_power_tower_roof_facilities", ["SKY_OBSERVATORY", "HELIPAD"])

func _build_circular_entrance_podium() -> void:
	var podium := Node3D.new()
	podium.name = "XSXCircularEntrancePodium"
	podium.set_meta("system_facility_type", "public_entrance_plaza")
	add_child(podium)
	_add_cylinder(podium, "PodiumFoundation", 49.0, 58.0, 12.0, 6.0, titanium, 96)
	_add_cylinder(podium, "UpperArrivalDeck", 43.0, 48.0, 3.0, 13.0, dark_glass, 96)
	for index in range(3):
		var inner := 38.0 - float(index) * 6.0
		_add_ring(podium, "PodiumLightRing_%d" % index, inner, inner + 0.48, 15.0 + float(index) * 0.15, red_emissive if index == 1 else gold_trim)
	var sign := Label3D.new()
	sign.name = "PowerTowerEntranceIdentity"
	sign.text = "X-S-X  |  POWER TOWER"
	sign.font_size = 42
	sign.position = Vector3(0.0, 17.0, 48.0)
	sign.modulate = Color(1.0, 0.82, 0.65)
	podium.add_child(sign)
	set_meta("system_power_tower_podium", "CIRCULAR_MULTI_LEVEL_ARRIVAL")
