extends Node3D
class_name SYSTEMPowerTowerXSXArchitecture

const TOWER_HEIGHT := 820.0
const BASE_RADIUS := 26.0
const FLOOR_COUNT := 200
const CompetitionManagerScript = preload("res://scripts/system_power_tower_competition_manager.gd")
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
	_build_facade_detail_layers()
	_build_xsx_identity()
	_build_observatory_and_rooftop_pad()
	_build_circular_entrance_podium()
	_build_entrance_media_panels()
	_build_lobby_facilities()
	var competition_manager := CompetitionManagerScript.new()
	competition_manager.name = "PowerTowerCompetitionManager"
	add_child(competition_manager)
	print("SYSTEM WORLD: X-S-X Power Tower architecture, arena progression, Nen training, 500-fan crowd and amenities initialized.")

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
			plaque.rotation.y = -angle
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


func _build_facade_detail_layers() -> void:
	# Lightweight architectural ribs follow the four tapered glass sections.
	var sections := [
		{"bottom": 25.0, "top": 20.0, "height": 175.0, "center": 95.0},
		{"bottom": 20.0, "top": 13.5, "height": 230.0, "center": 300.0},
		{"bottom": 13.5, "top": 7.2, "height": 245.0, "center": 537.5},
		{"bottom": 7.2, "top": 1.2, "height": 150.0, "center": 735.0}
	]
	var rib_count := 0
	for section_index in range(sections.size()):
		var section: Dictionary = sections[section_index]
		var radius := (float(section["bottom"]) + float(section["top"])) * 0.5 + 0.65
		for rib_index in range(16):
			var angle := TAU * float(rib_index) / 16.0
			var rib := MeshInstance3D.new()
			rib.name = "TitaniumFacadeRib_%02d_%02d" % [section_index, rib_index]
			var rib_mesh := BoxMesh.new()
			rib_mesh.size = Vector3(0.72, float(section["height"]) * 0.96, 1.05)
			rib.mesh = rib_mesh
			rib.position = Vector3(cos(angle) * radius, float(section["center"]) + 7.0, sin(angle) * radius)
			rib.rotation.y = -angle
			rib.material_override = titanium
			add_child(rib)
			rib_count += 1

	# Repeated illuminated floor-band markers make the 200-floor height readable.
	var band_count := 0
	for band_index in range(1, 16):
		var height := float(band_index) * 50.0
		var radius := maxf(2.0, 25.0 - height * 0.029)
		_add_ring(self, "TowerFloorLightBand_%02d" % band_index, radius - 0.12, radius + 0.12, height + 7.0, white_emissive)
		band_count += 1
	set_meta("system_power_tower_facade_rib_count", rib_count)
	set_meta("system_power_tower_floor_light_band_count", band_count)


func _build_entrance_media_panels() -> void:
	# Four slim public information screens sit around the independent circular arrival podium.
	var panel_count := 0
	for side in range(4):
		var angle := TAU * float(side) / 4.0
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		var panel := MeshInstance3D.new()
		panel.name = "PowerTowerArrivalMediaPanel_%02d" % side
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(0.7, 8.0, 16.0)
		panel.mesh = panel_mesh
		panel.position = outward * 52.0 + Vector3(0.0, 20.0, 0.0)
		panel.rotation.y = -angle
		panel.material_override = dark_glass
		add_child(panel)
		for rail_index in range(4):
			var frame_rail := MeshInstance3D.new()
			frame_rail.name = "PowerTowerArrivalMediaFrame_%02d_Rail_%d" % [side, rail_index]
			var rail_mesh := BoxMesh.new()
			if rail_index < 2:
				rail_mesh.size = Vector3(0.9, 0.32, 16.35)
				frame_rail.position = panel.position + Vector3(0.0, 4.16 if rail_index == 0 else -4.16, 0.0) + outward * 0.12
			else:
				rail_mesh.size = Vector3(0.9, 8.35, 0.32)
				frame_rail.position = panel.position + Vector3(0.0, 0.0, 8.16 if rail_index == 2 else -8.16) + outward * 0.12
			frame_rail.mesh = rail_mesh
			frame_rail.rotation.y = -angle
			frame_rail.material_override = gold_trim
			add_child(frame_rail)
		var screen_label := Label3D.new()
		screen_label.name = "PowerTowerArrivalMediaText_%02d" % side
		screen_label.text = "X-S-X  |  LIVE ARENA\n200 FLOORS  •  HUNTER RANKINGS"
		screen_label.font_size = 24
		screen_label.pixel_size = 0.012
		screen_label.position = panel.position + outward * 0.42
		screen_label.rotation.y = -angle
		screen_label.modulate = Color(0.72, 0.91, 1.0)
		add_child(screen_label)
		panel_count += 1
	set_meta("system_power_tower_arrival_media_panel_count", panel_count)

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



func _build_lobby_ambience(lobby: Node3D) -> void:
	# Decorative lighting is aligned to the existing lobby canopy and does not alter its collisions.
	var canopy := lobby.get_node_or_null("LobbyCanopy") as MeshInstance3D
	# Keep the ambience rig available in both the full production lobby and
	# the isolated headless validator fixture, which intentionally has no canopy.
	var center_z := canopy.position.z if canopy != null else 0.0
	lobby.set_meta("system_power_tower_ambience_anchor", "LOBBY_CANOPY" if canopy != null else "SAFE_CENTER_FALLBACK")
	var light_bar_count := 0
	for index in range(5):
		var light_bar := MeshInstance3D.new()
		light_bar.name = "PowerTowerLobbyCeilingLight_%02d" % index
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(18.0, 0.16, 0.34)
		light_bar.mesh = bar_mesh
		light_bar.position = Vector3(0.0, 12.25, center_z - 12.0 + float(index) * 6.0)
		light_bar.material_override = white_emissive
		lobby.add_child(light_bar)
		light_bar_count += 1

	var floor_inlay_count := 0
	for side in [-1.0, 1.0]:
		var inlay := MeshInstance3D.new()
		inlay.name = "PowerTowerLobbyGoldFloorInlay_%s" % str(side)
		var inlay_mesh := BoxMesh.new()
		inlay_mesh.size = Vector3(0.18, 0.055, 25.0)
		inlay.mesh = inlay_mesh
		inlay.position = Vector3(side * 4.2, 1.035, center_z + 2.0)
		inlay.material_override = gold_trim
		lobby.add_child(inlay)
		floor_inlay_count += 1

	var halo_count := 0
	for index in range(3):
		var halo := MeshInstance3D.new()
		halo.name = "PowerTowerLobbyCeilingHalo_%02d" % index
		var halo_mesh := TorusMesh.new()
		halo_mesh.inner_radius = 2.0 + float(index) * 0.8
		halo_mesh.outer_radius = 2.14 + float(index) * 0.8
		halo_mesh.rings = 48
		halo_mesh.ring_segments = 12
		halo.mesh = halo_mesh
		halo.rotation.x = PI * 0.5
		halo.position = Vector3(0.0, 11.8, center_z)
		halo.material_override = gold_trim if index == 1 else white_emissive
		lobby.add_child(halo)
		halo_count += 1
	set_meta("system_power_tower_lobby_light_bar_count", light_bar_count)
	set_meta("system_power_tower_lobby_floor_inlay_count", floor_inlay_count)
	set_meta("system_power_tower_lobby_ceiling_halo_count", halo_count)


func _build_lobby_wayfinding_and_spotlights(facility_root: Node3D) -> void:
	# Floating directory signs make the compact podium interior easier to read.
	var directory_entries := [
		{"name": "Weapons", "text": "WEAPONS  →", "position": Vector3(-18.0, 8.0, 12.0), "color": Color(0.62, 0.88, 1.0)},
		{"name": "Armor", "text": "ARMOR & DEFENSE  →", "position": Vector3(-18.0, 8.0, -12.0), "color": Color(1.0, 0.82, 0.52)},
		{"name": "Elixirs", "text": "ELIXIRS & NEN  →", "position": Vector3(18.0, 8.0, 12.0), "color": Color(0.52, 0.88, 1.0)},
		{"name": "Skills", "text": "SKILLS & TECHNIQUES  →", "position": Vector3(18.0, 8.0, -12.0), "color": Color(1.0, 0.78, 0.48)},
		{"name": "Cafeteria", "text": "CAFETERIA  ↓", "position": Vector3(0.0, 8.0, 26.0), "color": Color(1.0, 0.84, 0.58)},
		{"name": "NenHall", "text": "NEN TRAINING  ↓", "position": Vector3(0.0, 8.0, -27.0), "color": Color(0.48, 0.9, 1.0)}
	]
	for entry in directory_entries:
		var directory_sign := Label3D.new()
		directory_sign.name = "PowerTowerDirectory_" + str(entry["name"])
		directory_sign.text = str(entry["text"])
		directory_sign.font_size = 18
		directory_sign.pixel_size = 0.012
		directory_sign.position = entry["position"]
		directory_sign.modulate = entry["color"]
		directory_sign.outline_size = 8
		facility_root.add_child(directory_sign)

	# Soft local lighting separates merchandise zones without adding shadow-heavy lights.
	var light_positions := [
		Vector3(-18.0, 7.0, 12.0), Vector3(-18.0, 7.0, -12.0),
		Vector3(18.0, 7.0, 12.0), Vector3(18.0, 7.0, -12.0),
		Vector3(0.0, 7.0, 26.0), Vector3(0.0, 7.0, -27.0)
	]
	for index in range(light_positions.size()):
		var accent_light := OmniLight3D.new()
		accent_light.name = "PowerTowerInteriorAccentLight_%02d" % index
		accent_light.position = light_positions[index]
		accent_light.light_color = Color(0.55, 0.78, 1.0) if index % 2 == 0 else Color(1.0, 0.76, 0.48)
		accent_light.light_energy = 1.25
		accent_light.omni_range = 16.0
		accent_light.shadow_enabled = false
		facility_root.add_child(accent_light)
	set_meta("system_power_tower_interior_directory_sign_count", directory_entries.size())
	set_meta("system_power_tower_interior_accent_light_count", light_positions.size())


func _build_lobby_elevator_bank(facility_root: Node3D) -> void:
	# Three premium passenger lifts establish a clear vertical route from the podium.
	# This is presentation geometry only; floor travel remains owned by the existing tower manager.
	var bank := Node3D.new()
	bank.name = "PowerTowerLobbyElevatorBank"
	bank.position = Vector3(0.0, 0.0, -44.0)
	bank.set_meta("system_facility_type", "PASSENGER_ELEVATOR_BANK")
	bank.set_meta("system_elevator_count", 3)
	bank.set_meta("system_elevator_floor_range", Vector2i(1, FLOOR_COUNT))
	bank.set_meta("system_elevator_visual_only", true)
	facility_root.add_child(bank)

	var door_count := 0
	var lift_names := ["A", "B", "C"]
	for lift_index in range(3):
		var center_x := (float(lift_index) - 1.0) * 7.4
		var frame := MeshInstance3D.new()
		frame.name = "ElevatorPortalFrame_%s" % lift_names[lift_index]
		var frame_mesh := BoxMesh.new()
		frame_mesh.size = Vector3(5.0, 9.4, 0.55)
		frame.mesh = frame_mesh
		frame.position = Vector3(center_x, 4.7, 0.0)
		frame.material_override = titanium
		bank.add_child(frame)

		var lintel := MeshInstance3D.new()
		lintel.name = "ElevatorPortalGoldHeader_%s" % lift_names[lift_index]
		var lintel_mesh := BoxMesh.new()
		lintel_mesh.size = Vector3(4.45, 0.28, 0.72)
		lintel.mesh = lintel_mesh
		lintel.position = Vector3(center_x, 9.0, 0.0)
		lintel.material_override = gold_trim
		bank.add_child(lintel)

		for leaf_index in range(2):
			var leaf := MeshInstance3D.new()
			leaf.name = "ElevatorDoor_%s_%d" % [lift_names[lift_index], leaf_index]
			var leaf_mesh := BoxMesh.new()
			leaf_mesh.size = Vector3(0.14, 8.25, 2.08)
			leaf.mesh = leaf_mesh
			leaf.position = Vector3(center_x + (-1.04 if leaf_index == 0 else 1.04), 4.18, 0.08)
			leaf.material_override = dark_glass
			bank.add_child(leaf)
			door_count += 1

		var center_seam := MeshInstance3D.new()
		center_seam.name = "ElevatorDoorSeam_%s" % lift_names[lift_index]
		var seam_mesh := BoxMesh.new()
		seam_mesh.size = Vector3(0.055, 8.0, 0.08)
		center_seam.mesh = seam_mesh
		center_seam.position = Vector3(center_x, 4.18, 0.2)
		center_seam.material_override = white_emissive
		bank.add_child(center_seam)

		var indicator := Label3D.new()
		indicator.name = "ElevatorFloorIndicator_%s" % lift_names[lift_index]
		indicator.text = "01  /  200"
		indicator.font_size = 22
		indicator.pixel_size = 0.012
		indicator.position = Vector3(center_x, 10.0, 0.0)
		indicator.modulate = Color(0.66, 0.92, 1.0)
		bank.add_child(indicator)

		var lift_label := Label3D.new()
		lift_label.name = "ElevatorIdentity_%s" % lift_names[lift_index]
		lift_label.text = "X-S-X  LIFT  %s" % lift_names[lift_index]
		lift_label.font_size = 16
		lift_label.pixel_size = 0.012
		lift_label.position = Vector3(center_x, 0.55, 0.42)
		lift_label.modulate = Color(0.94, 0.78, 0.5)
		bank.add_child(lift_label)

		var call_panel := MeshInstance3D.new()
		call_panel.name = "ElevatorCallPanel_%s" % lift_names[lift_index]
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(0.62, 1.65, 0.18)
		call_panel.mesh = panel_mesh
		call_panel.position = Vector3(center_x + 2.95, 1.65, 0.0)
		call_panel.material_override = dark_glass
		bank.add_child(call_panel)

		for button_index in range(3):
			var call_button := MeshInstance3D.new()
			call_button.name = "ElevatorCallButton_%s_%d" % [lift_names[lift_index], button_index]
			var button_mesh := SphereMesh.new()
			button_mesh.radius = 0.11
			button_mesh.height = 0.22
			call_button.mesh = button_mesh
			call_button.position = call_panel.position + Vector3(0.0, 0.48 - float(button_index) * 0.48, 0.13)
			call_button.material_override = red_emissive if button_index == 0 else white_emissive
			bank.add_child(call_button)

		var threshold := MeshInstance3D.new()
		threshold.name = "ElevatorThreshold_%s" % lift_names[lift_index]
		var threshold_mesh := BoxMesh.new()
		threshold_mesh.size = Vector3(4.2, 0.12, 1.0)
		threshold.mesh = threshold_mesh
		threshold.position = Vector3(center_x, 0.12, 0.55)
		threshold.material_override = gold_trim
		bank.add_child(threshold)

	var directory := Label3D.new()
	directory.name = "PowerTowerElevatorFloorDirectory"
	directory.text = "VERTICAL TRANSIT\nFLOORS 001–200\nARENAS  •  TRAINING  •  OBSERVATORY"
	directory.font_size = 20
	directory.pixel_size = 0.014
	directory.position = Vector3(0.0, 12.0, -1.2)
	directory.modulate = Color(0.84, 0.92, 1.0)
	bank.add_child(directory)
	set_meta("system_power_tower_elevator_count", 3)
	set_meta("system_power_tower_elevator_door_leaf_count", door_count)
	set_meta("system_power_tower_elevator_floor_range", Vector2i(1, FLOOR_COUNT))

func _build_lobby_facilities() -> void:
	var tower := get_parent()
	if tower == null:
		return
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
	if lobby == null:
		push_warning("X-S-X Power Tower: public lobby not found; interior displays were not generated.")
		return
	var steel := titanium
	var display_glow := _emissive(Color(0.16, 0.58, 0.92), 1.4)
	var facility_root := Node3D.new()
	facility_root.name = "XSXShopAndCafeteriaInterior"
	facility_root.set_meta("system_power_tower_interior_facilities", ["TRADITIONAL_WEAPON_GALLERY", "ARMOR_SHOWROOM", "ELIXIR_CABINET", "SKILL_LIBRARY", "CAFETERIA"])
	lobby.add_child(facility_root)
	_build_lobby_ambience(lobby)
	_build_lobby_wayfinding_and_spotlights(facility_root)
	_build_lobby_elevator_bank(facility_root)

	# Traditional weapons gallery: no firearms or modern projectile displays are created here.
	var weapon_root := Node3D.new()
	weapon_root.name = "TraditionalWeaponsGallery"
	weapon_root.position = Vector3(-18.0, 0.0, 12.0)
	weapon_root.set_meta("system_shop_allowed_categories", ["MELEE", "TRADITIONAL_RANGED"])
	weapon_root.set_meta("system_shop_forbidden_categories", ["FIREARM", "MODERN_PROJECTILE"])
	facility_root.add_child(weapon_root)
	_add_cylinder(weapon_root, "WeaponDisplayPlinth", 4.2, 4.8, 1.0, 1.0, steel, 32)
	for index in range(4):
		var stand := MeshInstance3D.new()
		stand.name = "TraditionalWeaponStand_%02d" % index
		var stand_mesh := BoxMesh.new()
		stand_mesh.size = Vector3(0.45, 4.2, 0.45)
		stand.mesh = stand_mesh
		stand.position = Vector3(-2.4 + float(index) * 1.6, 3.2, 0.0)
		stand.material_override = gold_trim
		weapon_root.add_child(stand)
		var blade := MeshInstance3D.new()
		blade.name = "DisplayBlade_%02d" % index
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.18, 2.7, 0.38)
		blade.mesh = blade_mesh
		blade.position = stand.position + Vector3(0.0, 2.1, 0.0)
		blade.material_override = white_emissive
		weapon_root.add_child(blade)
	var weapon_sign := Label3D.new()
	weapon_sign.name = "TraditionalWeaponsSign"
	weapon_sign.text = "TRADITIONAL WEAPONS\nNO FIREARMS"
	weapon_sign.font_size = 22
	weapon_sign.position = Vector3(0.0, 6.2, 3.2)
	weapon_sign.modulate = Color(0.82, 0.94, 1.0)
	weapon_root.add_child(weapon_sign)

	# Additional traditional equipment displays: spear, bow and shield.
	var spear := MeshInstance3D.new()
	spear.name = "TraditionalSpearDisplay"
	var spear_mesh := CylinderMesh.new()
	spear_mesh.top_radius = 0.055
	spear_mesh.bottom_radius = 0.09
	spear_mesh.height = 4.8
	spear.mesh = spear_mesh
	spear.position = Vector3(-5.0, 2.8, -2.8)
	spear.material_override = gold_trim
	weapon_root.add_child(spear)
	var bow := MeshInstance3D.new()
	bow.name = "TraditionalBowDisplay"
	var bow_mesh := TorusMesh.new()
	bow_mesh.inner_radius = 1.15
	bow_mesh.outer_radius = 1.32
	bow_mesh.rings = 32
	bow_mesh.ring_segments = 10
	bow.mesh = bow_mesh
	bow.position = Vector3(0.0, 3.0, -2.8)
	bow.rotation.x = PI * 0.5
	bow.material_override = gold_trim
	weapon_root.add_child(bow)
	var shield := MeshInstance3D.new()
	shield.name = "TraditionalShieldDisplay"
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 1.0
	shield_mesh.bottom_radius = 1.0
	shield_mesh.height = 0.28
	shield_mesh.radial_segments = 12
	shield.mesh = shield_mesh
	shield.position = Vector3(5.0, 3.0, -2.8)
	shield.rotation.x = PI * 0.5
	shield.material_override = display_glow
	weapon_root.add_child(shield)
	weapon_root.set_meta("system_traditional_equipment_display_count", 3)

	# Armor mannequins and defensive equipment display.
	var armor_root := Node3D.new()
	armor_root.name = "ArmorShowroom"
	armor_root.position = Vector3(-18.0, 0.0, -12.0)
	facility_root.add_child(armor_root)
	for index in range(3):
		var mannequin := Node3D.new()
		mannequin.name = "ArmorMannequin_%02d" % index
		mannequin.position.x = float(index - 1) * 4.0
		armor_root.add_child(mannequin)
		_add_cylinder(mannequin, "ArmorTorso", 0.72, 0.9, 2.4, 2.5, steel, 24)
		var head := MeshInstance3D.new()
		head.name = "ArmorHelmet"
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.62
		head_mesh.height = 1.0
		head.mesh = head_mesh
		head.position.y = 4.05
		head.material_override = gold_trim if index == 2 else steel
		mannequin.add_child(head)
	# Five footwear tiers from bronze training boots to diamond sovereign boots.
	for index in range(5):
		var footwear := MeshInstance3D.new()
		footwear.name = "FootwearDisplay_%02d" % index
		var shoe_mesh := BoxMesh.new()
		shoe_mesh.size = Vector3(0.72, 0.42, 1.25)
		footwear.mesh = shoe_mesh
		footwear.position = Vector3(-6.0 + float(index) * 3.0, 0.5, 5.0)
		footwear.material_override = [steel, display_glow, gold_trim, white_emissive, red_emissive][index]
		armor_root.add_child(footwear)
	var footwear_sign := Label3D.new()
	footwear_sign.name = "FootwearProgressionSign"
	footwear_sign.text = "FOOTWEAR: BRONZE → SILVER → GOLD → DIAMOND"
	footwear_sign.font_size = 14
	footwear_sign.position = Vector3(0.0, 2.5, 6.2)
	footwear_sign.modulate = Color(0.8, 0.9, 1.0)
	armor_root.add_child(footwear_sign)
	armor_root.set_meta("system_shop_category", "ARMOR_AND_FOOTWEAR")
	armor_root.set_meta("system_footwear_display_count", 5)

	var armor_sign := Label3D.new()
	armor_sign.name = "ArmorShowroomSign"
	armor_sign.text = "ARMOR & DEFENSE"
	armor_sign.font_size = 20
	armor_sign.position = Vector3(0.0, 5.8, 3.0)
	armor_sign.modulate = Color(0.9, 0.82, 0.62)
	armor_root.add_child(armor_sign)

	# Elixir cabinet and skill-scroll library.
	var elixir_root := Node3D.new()
	elixir_root.name = "NenElixirCabinet"
	elixir_root.position = Vector3(18.0, 0.0, 12.0)
	facility_root.add_child(elixir_root)
	_add_cylinder(elixir_root, "ElixirCabinetBase", 3.6, 4.0, 1.0, 0.8, steel, 32)
	for index in range(5):
		var bottle := MeshInstance3D.new()
		bottle.name = "ElixirBottle_%02d" % index
		var bottle_mesh := CylinderMesh.new()
		bottle_mesh.top_radius = 0.32
		bottle_mesh.bottom_radius = 0.42
		bottle_mesh.height = 1.5
		bottle.mesh = bottle_mesh
		bottle.position = Vector3(-2.0 + float(index) * 1.0, 2.0, 0.0)
		bottle.material_override = display_glow if index % 2 == 0 else red_emissive
		elixir_root.add_child(bottle)
	var elixir_sign := Label3D.new()
	elixir_sign.name = "NenElixirSign"
	elixir_sign.text = "ELIXIRS & NEN"
	elixir_sign.font_size = 20
	elixir_sign.position = Vector3(0.0, 4.0, 2.8)
	elixir_sign.modulate = Color(0.72, 0.9, 1.0)
	elixir_root.add_child(elixir_sign)

	var skill_root := Node3D.new()
	skill_root.name = "SkillScrollLibrary"
	skill_root.position = Vector3(18.0, 0.0, -12.0)
	facility_root.add_child(skill_root)
	_add_cylinder(skill_root, "SkillLibraryBase", 3.2, 3.8, 1.0, 0.8, steel, 32)
	for index in range(4):
		var scroll := MeshInstance3D.new()
		scroll.name = "SkillScroll_%02d" % index
		var scroll_mesh := CylinderMesh.new()
		scroll_mesh.top_radius = 0.22
		scroll_mesh.bottom_radius = 0.22
		scroll_mesh.height = 1.4
		scroll.mesh = scroll_mesh
		scroll.rotation.z = PI * 0.5
		scroll.position = Vector3(-1.8 + float(index) * 1.2, 1.8, 0.0)
		scroll.material_override = gold_trim
		skill_root.add_child(scroll)
	var skill_sign := Label3D.new()
	skill_sign.name = "SkillLibrarySign"
	skill_sign.text = "SKILLS & TECHNIQUES"
	skill_sign.font_size = 18
	skill_sign.position = Vector3(0.0, 3.8, 2.8)
	skill_sign.modulate = Color(1.0, 0.82, 0.52)
	skill_root.add_child(skill_sign)

	# Equippable hunter accessories: pendants, rings, aura bracelets and guild insignia.
	var accessories := Node3D.new()
	accessories.name = "HunterAccessoriesGallery"
	accessories.position = Vector3(0.0, 0.0, 0.0)
	accessories.set_meta("system_shop_category", "ACCESSORY")
	facility_root.add_child(accessories)
	_add_cylinder(accessories, "AccessoryDisplayBase", 3.8, 4.4, 0.9, 0.7, steel, 32)
	for index in range(4):
		var item_display := MeshInstance3D.new()
		item_display.name = "AccessoryDisplay_%02d" % index
		var display_mesh := TorusMesh.new()
		display_mesh.inner_radius = 0.42
		display_mesh.outer_radius = 0.58
		display_mesh.rings = 24
		display_mesh.ring_segments = 8
		item_display.mesh = display_mesh
		item_display.position = Vector3(-1.8 + float(index) * 1.2, 1.8, 0.0)
		item_display.material_override = gold_trim if index % 2 == 0 else white_emissive
		accessories.add_child(item_display)
	var accessory_sign := Label3D.new()
	accessory_sign.name = "AccessoriesGallerySign"
	accessory_sign.text = "HUNTER ACCESSORIES"
	accessory_sign.font_size = 20
	accessory_sign.position = Vector3(0.0, 3.7, 2.8)
	accessory_sign.modulate = Color(1.0, 0.86, 0.55)
	accessories.add_child(accessory_sign)

	# Cafeteria service counter with four dining tables and visible seating.
	var cafe := Node3D.new()
	cafe.name = "PowerTowerCafeteria"
	cafe.position = Vector3(0.0, 0.0, 26.0)
	cafe.set_meta("system_facility_type", "cafeteria")
	cafe.set_meta("system_service_roles", ["tower_cafeteria_chef", "tower_cafeteria_waiter"])
	facility_root.add_child(cafe)
	var counter := MeshInstance3D.new()
	counter.name = "CafeteriaServiceCounter"
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(15.0, 2.6, 2.4)
	counter.mesh = counter_mesh
	counter.position = Vector3(0.0, 1.4, 0.0)
	counter.material_override = gold_trim
	cafe.add_child(counter)
	var counter_sign := Label3D.new()
	counter_sign.name = "CafeteriaSign"
	counter_sign.text = "X-S-X CAFETERIA"
	counter_sign.font_size = 26
	counter_sign.position = Vector3(0.0, 4.0, 1.6)
	counter_sign.modulate = Color(1.0, 0.82, 0.56)
	cafe.add_child(counter_sign)
	for index in range(4):
		var table := MeshInstance3D.new()
		table.name = "CafeteriaTable_%02d" % index
		var table_mesh := CylinderMesh.new()
		table_mesh.top_radius = 1.45
		table_mesh.bottom_radius = 1.45
		table_mesh.height = 0.3
		table.mesh = table_mesh
		table.position = Vector3(-8.0 + float(index % 2) * 16.0, 1.8, -7.0 - float(index / 2) * 7.0)
		table.material_override = steel
		cafe.add_child(table)
		for seat_index in range(4):
			var angle := TAU * float(seat_index) / 4.0
			var seat := MeshInstance3D.new()
			seat.name = "CafeteriaSeat_%02d_%02d" % [index, seat_index]
			var seat_mesh := BoxMesh.new()
			seat_mesh.size = Vector3(0.9, 1.1, 0.9)
			seat.mesh = seat_mesh
			seat.position = table.position + Vector3(cos(angle) * 2.1, -0.8, sin(angle) * 2.1)
			seat.material_override = titanium
			cafe.add_child(seat)
	# Dedicated Nen learning hall. Progress is handled by SYSTEMPlayerProgression through the competition manager.
	var nen_hall := Node3D.new()
	nen_hall.name = "PowerTowerNenTrainingHall"
	nen_hall.position = Vector3(0.0, 0.0, -27.0)
	nen_hall.set_meta("system_facility_type", "NEN_TRAINING_HALL")
	nen_hall.set_meta("system_tower_id", "power_tower_baghdad")
	nen_hall.set_meta("system_interaction_action", "POWER_TOWER_NEN_TRAINING")
	nen_hall.set_meta("system_training_progression", ["AURA_AWARENESS", "TEN", "REN", "ZETSU", "HATSU"])
	facility_root.add_child(nen_hall)
	_add_cylinder(nen_hall, "NenTrainingDais", 8.0, 10.0, 0.8, 0.5, steel, 48)
	for index in range(3):
		var station := Node3D.new()
		station.name = "NenTrainingStation_%02d" % index
		station.position = Vector3(-9.0 + float(index) * 9.0, 0.0, 0.0)
		nen_hall.add_child(station)
		_add_cylinder(station, "TrainingPlatform", 2.0, 2.5, 0.45, 0.55, gold_trim, 32)
		var aura_ring := MeshInstance3D.new()
		aura_ring.name = "NenAuraRing"
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 1.25
		ring_mesh.outer_radius = 1.42
		ring_mesh.rings = 32
		ring_mesh.ring_segments = 12
		aura_ring.mesh = ring_mesh
		aura_ring.position.y = 1.2
		aura_ring.material_override = display_glow
		station.add_child(aura_ring)
		var station_label := Label3D.new()
		station_label.name = "NenTrainingLabel"
		station_label.text = ["AURA & TEN", "REN & ZETSU", "HATSU MASTERY"][index]
		station_label.font_size = 16
		station_label.position = Vector3(0.0, 3.0, 1.8)
		station.add_child(station_label)
	var nen_sign := Label3D.new()
	nen_sign.name = "NenTrainingHallSign"
	nen_sign.text = "NEN TRAINING HALL\nDISCOVER • CONTROL • MASTER"
	nen_sign.font_size = 24
	nen_sign.position = Vector3(0.0, 6.0, 5.0)
	nen_sign.modulate = Color(0.45, 0.9, 1.0)
	nen_hall.add_child(nen_sign)
	var training_area := Area3D.new()
	training_area.name = "NenTrainingInteractionArea"
	training_area.add_to_group("system_interactable")
	training_area.set_meta("system_tower_id", "power_tower_baghdad")
	training_area.position = Vector3(0.0, 1.0, 0.0)
	training_area.set_meta("system_interaction_action", "POWER_TOWER_NEN_TRAINING")
	training_area.set_meta("system_training_manager_method", "train_player_nen")
	var training_collision := CollisionShape3D.new()
	var training_shape := BoxShape3D.new()
	training_shape.size = Vector3(28.0, 4.0, 16.0)
	training_collision.shape = training_shape
	training_area.add_child(training_collision)
	nen_hall.add_child(training_area)
	set_meta("system_power_tower_nen_training_hall", "PowerTowerNenTrainingHall")
	var combat_board := Node3D.new()
	combat_board.name = "PowerTowerCombatStyleBoard"
	combat_board.position = Vector3(0.0, 0.0, 40.0)
	combat_board.set_meta("system_facility_type", "COMBAT_STYLE_SELECTION")
	combat_board.set_meta("system_tower_id", "power_tower_baghdad")
	facility_root.add_child(combat_board)
	var combat_board_mesh := MeshInstance3D.new()
	combat_board_mesh.name = "CombatStyleBoardDisplay"
	var combat_board_box := BoxMesh.new()
	combat_board_box.size = Vector3(7.0, 4.2, 0.45)
	combat_board_mesh.mesh = combat_board_box
	combat_board_mesh.position.y = 2.1
	combat_board_mesh.material_override = dark_glass
	combat_board.add_child(combat_board_mesh)
	var combat_board_label := Label3D.new()
	combat_board_label.name = "CombatStyleBoardLabel"
	combat_board_label.text = "X-S-X COMBAT STYLES\nKUNG FU • MARTIAL ARTS • WEAPONS • NEN"
	combat_board_label.font_size = 18
	combat_board_label.position = Vector3(0.0, 2.2, 0.28)
	combat_board_label.modulate = Color(0.55, 0.92, 1.0)
	combat_board.add_child(combat_board_label)
	var combat_board_interaction := Area3D.new()
	combat_board_interaction.name = "CombatStyleBoardInteraction"
	combat_board_interaction.add_to_group("system_interactable")
	combat_board_interaction.set_meta("system_tower_id", "power_tower_baghdad")
	combat_board_interaction.set_meta("system_power_tower_combat_style_board", true)
	combat_board_interaction.set_meta("system_interaction_prompt", "اختيار أسلوب القتال للطابق القادم")
	var combat_board_collision := CollisionShape3D.new()
	var combat_board_shape := BoxShape3D.new()
	combat_board_shape.size = Vector3(8.0, 4.5, 4.0)
	combat_board_collision.shape = combat_board_shape
	combat_board_collision.position.y = 2.1
	combat_board_interaction.add_child(combat_board_collision)
	combat_board.add_child(combat_board_interaction)
	set_meta("system_power_tower_interior_display_groups", ["TraditionalWeaponsGallery", "ArmorShowroom", "NenElixirCabinet", "SkillScrollLibrary", "HunterAccessoriesGallery", "PowerTowerCafeteria", "PowerTowerNenTrainingHall", "PowerTowerCombatStyleBoard"])
	set_meta("system_power_tower_cafeteria_table_count", 4)
	set_meta("system_power_tower_cafeteria_seat_count", 16)
