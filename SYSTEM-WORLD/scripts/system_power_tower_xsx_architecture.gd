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
	_build_xsx_identity()
	_build_observatory_and_rooftop_pad()
	_build_circular_entrance_podium()
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

	# Traditional weapons gallery: no firearms or modern projectile displays are created here.
	var weapon_root := Node3D.new()
	weapon_root.name = "TraditionalWeaponsGallery"
	weapon_root.position = Vector3(-23.0, 0.0, 50.0)
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

	# Armor mannequins and defensive equipment display.
	var armor_root := Node3D.new()
	armor_root.name = "ArmorShowroom"
	armor_root.position = Vector3(-22.0, 0.0, 65.0)
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
	elixir_root.position = Vector3(23.0, 0.0, 49.0)
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
	skill_root.position = Vector3(23.0, 0.0, 65.0)
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
	accessories.position = Vector3(0.0, 0.0, 58.0)
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
	cafe.position = Vector3(0.0, 0.0, 68.0)
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
	set_meta("system_power_tower_interior_display_groups", ["TraditionalWeaponsGallery", "ArmorShowroom", "NenElixirCabinet", "SkillScrollLibrary", "HunterAccessoriesGallery", "PowerTowerCafeteria"])
	set_meta("system_power_tower_cafeteria_table_count", 4)
	set_meta("system_power_tower_cafeteria_seat_count", 16)
