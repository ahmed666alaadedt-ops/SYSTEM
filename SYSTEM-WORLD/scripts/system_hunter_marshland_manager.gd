extends Node3D
class_name SYSTEMHunterMarshlandManager

const PLOT_COUNT := 12
const TREE_COUNT := 168
const UNDERGROWTH_COUNT := 220
const REED_CLUSTER_COUNT := 96
const TURTLE_COUNT := 3
const DECOY_GUIDE_COUNT := 6
const CARNIVOROUS_PLANT_COUNT := 12

func _ready() -> void:
	name = "HunterMarshland"
	_build_marshland()

func _build_marshland() -> void:
	set_meta("system_facility_type", "hunter_exam_marshland")
	set_meta("system_marshland_connected_to_tunnel", true)
	set_meta("system_marshland_is_separate_world", false)
	set_meta("system_marshland_biome", "agricultural_wetland")
	set_meta("system_marshland_fog_enabled", true)
	set_meta("system_marshland_tracking_route_enabled", true)
	set_meta("system_marshland_expected_plot_count", PLOT_COUNT)
	set_meta("system_marshland_expected_tree_count", TREE_COUNT)
	set_meta("system_marshland_expected_undergrowth_count", UNDERGROWTH_COUNT)
	set_meta("system_marshland_expected_reed_cluster_count", REED_CLUSTER_COUNT)
	set_meta("system_marshland_expected_giant_turtle_count", TURTLE_COUNT)
	set_meta("system_marshland_expected_decoy_count", DECOY_GUIDE_COUNT)
	set_meta("system_marshland_expected_carnivorous_plant_count", CARNIVOROUS_PLANT_COUNT)

	var soil := _material(Color(0.19, 0.22, 0.12), 0.98, 0.02)
	var water := _material(Color(0.10, 0.28, 0.25, 0.78), 0.2, 0.1, true)
	var crop := _material(Color(0.32, 0.48, 0.16), 0.9, 0.0)
	var trunk := _material(Color(0.22, 0.14, 0.08), 0.95, 0.0)
	var leaf := _material(Color(0.12, 0.32, 0.14), 0.92, 0.0)
	var leaf_light := _material(Color(0.28, 0.43, 0.16), 0.92, 0.0)
	var leaf_dark := _material(Color(0.055, 0.20, 0.12), 0.94, 0.0)
	var reed_material := _material(Color(0.42, 0.46, 0.18), 0.88, 0.0)
	var flower_material := _material(Color(0.72, 0.48, 0.26), 0.65, 0.0)
	var stone := _material(Color(0.24, 0.28, 0.22), 0.92, 0.0)
	var glow := _material(Color(0.12, 0.72, 0.92), 0.4, 0.4)
	glow.emission_enabled = true
	glow.emission = Color(0.04, 0.48, 0.9)
	glow.emission_energy_multiplier = 1.6

	_add_box("MarshlandGround", Vector3(0.0, -0.65, 34.0), Vector3(110.0, 1.3, 120.0), soil, true)
	_add_box("TunnelToMarshlandThreshold", Vector3(0.0, -0.05, -7.0), Vector3(25.0, 0.4, 16.0), stone, true)
	_add_label("MarshlandWelcome", "أرض المستنقعات\nنهاية نفق اختبار الصيادين", Vector3(0.0, 7.0, -10.0), Color(0.72, 0.92, 0.78))

	# Shallow wetlands are physical water zones, not solid ground.
	for index in range(5):
		var pond := Area3D.new()
		pond.name = "MarshWaterZone_%02d" % index
		pond.position = Vector3(-34.0 + float(index % 3) * 32.0, 0.08, 12.0 + float(index / 3) * 42.0)
		pond.collision_layer = 0
		pond.collision_mask = 1
		pond.set_meta("system_marsh_water", true)
		pond.set_meta("system_swimming_zone", true)
		var water_mesh := MeshInstance3D.new()
		water_mesh.name = "MurkyWaterSurface"
		var water_shape := CylinderMesh.new()
		water_shape.top_radius = 9.0 + float(index % 2) * 3.0
		water_shape.bottom_radius = water_shape.top_radius
		water_shape.height = 0.16
		water_mesh.mesh = water_shape
		water_mesh.material_override = water
		pond.add_child(water_mesh)
		var water_collision := CollisionShape3D.new()
		var water_area_shape := CylinderShape3D.new()
		water_area_shape.radius = water_shape.top_radius
		water_area_shape.height = 1.2
		water_collision.shape = water_area_shape
		pond.add_child(water_collision)
		add_child(pond)

	# Agricultural plots with visible crop rows and walkable furrows.
	for index in range(PLOT_COUNT):
		var plot := Node3D.new()
		plot.name = "AgriculturalPlot_%02d" % index
		var x := -42.0 + float(index % 4) * 28.0
		var z := 3.0 + float(index / 4) * 29.0
		plot.position = Vector3(x, 0.0, z)
		plot.set_meta("system_marshland_plot", true)
		plot.set_meta("system_crop_type", ["reed", "grain", "vegetable"][index % 3])
		add_child(plot)
		for row in range(4):
			for plant_index in range(8):
				var stalk := MeshInstance3D.new()
				stalk.name = "Crop_%02d_%02d" % [row, plant_index]
				var stalk_mesh := CylinderMesh.new()
				stalk_mesh.top_radius = 0.045
				stalk_mesh.bottom_radius = 0.10
				stalk_mesh.height = 1.15 + float((row + plant_index) % 3) * 0.18
				stalk.mesh = stalk_mesh
				stalk.position = Vector3(-8.0 + float(plant_index) * 2.1, stalk_mesh.height * 0.5, -4.5 + float(row) * 3.0)
				stalk.material_override = crop
				plot.add_child(stalk)

	# Dense mixed swamp forest: staggered groves, varied silhouettes and overlapping canopies.
	for index in range(TREE_COUNT):
		var column := index % 14
		var row := int(index / 14)
		var x := -51.0 + float(column) * 7.7 + sin(float(index) * 1.71) * 2.0
		var z := -12.0 + float(row) * 9.0 + cos(float(index) * 0.83) * 2.4
		if absf(x) < 8.0 and z < 9.0:
			z += 15.0
		_build_marsh_tree(index, Vector3(x, 0.0, z), trunk, leaf, leaf_light, leaf_dark)

	# Thick understory: ferns, broad-leaf shrubs, roots and flowering marsh plants.
	for index in range(UNDERGROWTH_COUNT):
		var plant := Node3D.new()
		plant.name = "MarshUnderstory_%03d" % index
		var x := -52.0 + fposmod(float(index) * 13.37, 104.0)
		var z := -8.0 + fposmod(float(index) * 7.91, 98.0)
		plant.position = Vector3(x, 0.0, z)
		plant.set_meta("system_plant_species", ["broadleaf_shrub", "giant_fern", "marsh_flower", "exposed_root"][index % 4])
		add_child(plant)
		var shrub := MeshInstance3D.new()
		shrub.name = "UnderstoryFoliage"
		var shrub_mesh: Mesh
		match index % 4:
			0:
				var sphere := SphereMesh.new()
				sphere.radius = 1.05 + float(index % 3) * 0.22
				sphere.height = sphere.radius * 1.25
				shrub_mesh = sphere
				shrub.material_override = leaf_dark
			1:
				var fern := PrismMesh.new()
				fern.size = Vector3(1.8, 1.7, 0.45)
				shrub_mesh = fern
				shrub.material_override = leaf_light
			2:
				var flower := SphereMesh.new()
				flower.radius = 0.62
				flower.height = 1.2
				shrub_mesh = flower
				shrub.material_override = flower_material
			_:
				var root_mesh := CylinderMesh.new()
				root_mesh.top_radius = 0.10
				root_mesh.bottom_radius = 0.34
				root_mesh.height = 1.4
				shrub_mesh = root_mesh
				shrub.material_override = trunk
		shrub.mesh = shrub_mesh
		shrub.position.y = 0.55
		plant.add_child(shrub)

	# Reed beds and cattails form dense natural screens beside muddy water.
	for index in range(REED_CLUSTER_COUNT):
		var cluster := Node3D.new()
		cluster.name = "MarshReedCluster_%03d" % index
		cluster.position = Vector3(-50.0 + fposmod(float(index) * 17.19, 100.0), 0.0, -4.0 + fposmod(float(index) * 11.73, 92.0))
		cluster.set_meta("system_plant_species", "reed_and_cattail")
		add_child(cluster)
		for blade in range(7):
			var reed := MeshInstance3D.new()
			reed.name = "Reed_%02d" % blade
			var reed_mesh := CylinderMesh.new()
			reed_mesh.top_radius = 0.025
			reed_mesh.bottom_radius = 0.065
			reed_mesh.height = 1.8 + float((index + blade) % 5) * 0.38
			reed.mesh = reed_mesh
			reed.position = Vector3(sin(float(blade) * 2.4) * 0.65, reed_mesh.height * 0.5, cos(float(blade) * 2.4) * 0.65)
			reed.material_override = reed_material
			cluster.add_child(reed)

	# Carnivorous plants are active hazards placed along the running examination route.
	for index in range(CARNIVOROUS_PLANT_COUNT):
		var lane := -1.0 if index % 2 == 0 else 1.0
		var x := lane * (3.8 + float(index % 3) * 1.1)
		var z := 12.0 + float(index) * 6.0
		_build_carnivorous_plant(index, Vector3(x, 0.0, z), leaf_dark, leaf_light, flower_material, trunk)

	# Large original swamp fauna; each creature has its own collision and identity.
	for index in range(TURTLE_COUNT):
		_build_giant_turtle(index, Vector3(-24.0 + float(index) * 24.0, 0.0, 47.0 + float(index % 2) * 13.0), trunk, leaf)
	_build_marsh_beasts(stone)

	# Decoy NPCs deliberately misdirect some candidates; the tracking arrows still lead to the true gate.
	for index in range(DECOY_GUIDE_COUNT):
		var decoy := Node3D.new()
		decoy.name = "MarshlandDecoyGuide_%02d" % index
		decoy.position = Vector3(-40.0 + float(index) * 16.0, 0.0, 17.0 + float(index % 2) * 24.0)
		decoy.set_meta("system_npc_role", "misleading_marshland_resident")
		decoy.set_meta("system_can_misdirect_candidates", true)
		add_child(decoy)
		var body := MeshInstance3D.new()
		body.name = "ResidentBody"
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.48
		body_mesh.height = 1.9
		body.mesh = body_mesh
		body.position.y = 1.0
		body.material_override = stone
		decoy.add_child(body)
		_add_label("ResidentWarning_%02d" % index, "دليل محلي", decoy.position + Vector3(0.0, 2.7, 0.0), Color(0.88, 0.76, 0.52), decoy)

	# Ground-level luminous route chevrons remain readable when fog hides the guide.
	for index in range(8):
		var marker := Node3D.new()
		marker.name = "HunterTrackingArrow_%02d" % index
		marker.position = Vector3(0.0, 0.18, -2.0 + float(index) * 11.0)
		marker.set_meta("system_hunter_tracking_arrow", true)
		marker.set_meta("system_tracking_target", "MarshlandFinalStarGate")
		add_child(marker)
		var arrow := MeshInstance3D.new()
		arrow.name = "LuminousArrow"
		var arrow_mesh := PrismMesh.new()
		arrow_mesh.size = Vector3(2.0, 0.25, 3.0)
		arrow.mesh = arrow_mesh
		arrow.material_override = glow
		marker.add_child(arrow)

	# Volumetric-looking low fog banks made from translucent layered meshes.
	var fog_material := _material(Color(0.68, 0.76, 0.72, 0.20), 0.0, 0.0, true)
	fog_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index in range(14):
		var fog := MeshInstance3D.new()
		fog.name = "MarshFogBank_%02d" % index
		var fog_mesh := SphereMesh.new()
		fog_mesh.radius = 5.0 + float(index % 4) * 1.8
		fog_mesh.height = fog_mesh.radius * 0.55
		fog.mesh = fog_mesh
		fog.position = Vector3(-48.0 + float(index % 7) * 16.0, 2.0 + float(index % 3) * 0.7, 4.0 + float(index / 7) * 45.0)
		fog.material_override = fog_material
		add_child(fog)

	var gate := Node3D.new()
	gate.name = "MarshlandFinalStarGate"
	gate.position = Vector3(0.0, 0.0, 91.0)
	gate.set_meta("system_exam_route_destination", true)
	gate.set_meta("system_exam_gate_type", "star_gate")
	gate.set_meta("system_gate_region", "hunter_exam_marshland")
	add_child(gate)
	_add_label("MarshlandFinalGateSign", "بوابة النجاة", Vector3(0.0, 5.0, 91.0), Color(0.52, 0.9, 1.0), gate)
	var ring := MeshInstance3D.new()
	ring.name = "StarGateRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 3.2
	ring_mesh.outer_radius = 3.8
	ring.mesh = ring_mesh
	ring.position.y = 3.5
	ring.material_override = glow
	gate.add_child(ring)

	set_meta("system_marshland_generated", true)
	set_meta("system_marshland_agricultural_plot_count", PLOT_COUNT)
	set_meta("system_marshland_tree_count", TREE_COUNT)
	set_meta("system_marshland_undergrowth_count", UNDERGROWTH_COUNT)
	set_meta("system_marshland_reed_cluster_count", REED_CLUSTER_COUNT)
	set_meta("system_marshland_plant_species", ["swamp_tree", "broadleaf_shrub", "giant_fern", "marsh_flower", "exposed_root", "reed", "cattail"])
	set_meta("system_marshland_tree_species_count", 4)
	set_meta("system_marshland_understory_species_count", 4)
	set_meta("system_marshland_reed_blades_per_cluster", 7)
	set_meta("system_marshland_forest_canopy_layers", 3)
	set_meta("system_marshland_forest_density_profile", "dense_mixed_groves_with_walkable_routes")
	set_meta("system_marshland_water_zone_count", 5)
	set_meta("system_marshland_giant_turtle_count", TURTLE_COUNT)
	set_meta("system_marshland_decoy_npc_count", DECOY_GUIDE_COUNT)
	set_meta("system_marshland_tracking_arrow_count", 8)
	set_meta("system_marshland_fog_bank_count", 14)
	set_meta("system_marshland_carnivorous_plant_count", CARNIVOROUS_PLANT_COUNT)
	set_meta("system_marshland_carnivorous_plant_species", ["snap_maw", "strangler_vine", "sleeping_spore_bloom", "buried_trap_blossom", "water_lurker"])
	set_meta("system_marshland_running_exam_hazards_enabled", true)
	set_meta("system_marshland_exit_gate_present", true)



func _build_carnivorous_plant(index: int, location: Vector3, dark_leaf: Material, light_leaf: Material, bloom_material: Material, vine_material: Material) -> void:
	var plant := Node3D.new()
	plant.name = "CarnivorousExamPlant_%02d" % index
	plant.position = location
	var species := index % 5
	var species_names := ["snap_maw", "strangler_vine", "sleeping_spore_bloom", "buried_trap_blossom", "water_lurker"]
	plant.set_meta("system_carnivorous_plant_species", species_names[species])
	plant.set_meta("system_hunter_exam_running_hazard", true)
	plant.set_meta("system_can_swallow_candidate", species == 0 or species == 3 or species == 4)
	plant.set_meta("system_can_entangle_candidate", species == 1)
	plant.set_meta("system_can_release_sleep_spores", species == 2)
	add_child(plant)

	var stem := MeshInstance3D.new()
	stem.name = "FleshyStem"
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.22
	stem_mesh.bottom_radius = 0.42
	stem_mesh.height = 1.5
	stem.mesh = stem_mesh
	stem.position.y = 0.75
	stem.material_override = vine_material
	plant.add_child(stem)

	var maw := MeshInstance3D.new()
	maw.name = "PredatorMaw"
	var maw_mesh := SphereMesh.new()
	maw_mesh.radius = 1.25 if species != 2 else 1.55
	maw_mesh.height = 1.55
	maw.mesh = maw_mesh
	maw.position.y = 1.65
	maw.material_override = bloom_material if species == 2 else dark_leaf
	plant.add_child(maw)

	for petal_index in range(6):
		var petal := MeshInstance3D.new()
		petal.name = "ToothedPetal_%02d" % petal_index
		var petal_mesh := CylinderMesh.new()
		petal_mesh.top_radius = 0.0
		petal_mesh.bottom_radius = 0.42
		petal_mesh.height = 1.35
		petal.mesh = petal_mesh
		var angle := TAU * float(petal_index) / 6.0
		petal.position = Vector3(cos(angle) * 1.05, 1.55, sin(angle) * 1.05)
		petal.rotation.z = -0.82
		petal.rotation.y = -angle
		petal.material_override = light_leaf if petal_index % 2 == 0 else dark_leaf
		plant.add_child(petal)

	if species == 1 or species == 4:
		for vine_index in range(4):
			var tendril := MeshInstance3D.new()
			tendril.name = "GrabbingTendril_%02d" % vine_index
			var tendril_mesh := CylinderMesh.new()
			tendril_mesh.top_radius = 0.045
			tendril_mesh.bottom_radius = 0.14
			tendril_mesh.height = 3.2
			tendril.mesh = tendril_mesh
			var angle := TAU * float(vine_index) / 4.0
			tendril.position = Vector3(cos(angle) * 1.25, 0.9, sin(angle) * 1.25)
			tendril.rotation.z = 0.7 * cos(angle)
			tendril.rotation.x = 0.7 * sin(angle)
			tendril.material_override = vine_material
			plant.add_child(tendril)

	if species == 2:
		var spore_cloud := MeshInstance3D.new()
		spore_cloud.name = "SleepSporeCloud"
		var cloud_mesh := SphereMesh.new()
		cloud_mesh.radius = 2.2
		cloud_mesh.height = 1.4
		spore_cloud.mesh = cloud_mesh
		spore_cloud.position.y = 2.8
		var spore_material := _material(Color(0.70, 0.78, 0.30, 0.24), 0.0, 0.0, true)
		spore_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spore_cloud.material_override = spore_material
		plant.add_child(spore_cloud)

	var trigger := Area3D.new()
	trigger.name = "CandidateCaptureZone"
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	trigger.set_meta("system_exam_trap_trigger", true)
	var trigger_shape := CollisionShape3D.new()
	var capture_shape := SphereShape3D.new()
	capture_shape.radius = 2.5 if species != 1 else 3.2
	trigger_shape.shape = capture_shape
	trigger_shape.position.y = 1.0
	trigger.add_child(trigger_shape)
	plant.add_child(trigger)
	trigger.body_entered.connect(_on_carnivorous_plant_body_entered.bind(plant))


func _on_carnivorous_plant_body_entered(body: Node3D, plant: Node3D) -> void:
	if not is_instance_valid(body) or not is_instance_valid(plant):
		return
	if bool(plant.get_meta("system_plant_cooldown", false)):
		return
	if bool(body.get_meta("system_examiner_trapped", false)):
		return

	var species := str(plant.get_meta("system_carnivorous_plant_species", "snap_maw"))
	var capture_seconds := 2.4
	var damage_amount := 8.0
	match species:
		"strangler_vine":
			capture_seconds = 3.2
			damage_amount = 5.0
		"sleeping_spore_bloom":
			capture_seconds = 2.8
			damage_amount = 4.0
		"buried_trap_blossom":
			capture_seconds = 2.6
			damage_amount = 10.0
		"water_lurker":
			capture_seconds = 3.0
			damage_amount = 9.0

	plant.set_meta("system_plant_cooldown", true)
	plant.set_meta("system_plant_has_captured_candidate", true)
	body.set_meta("system_examiner_trapped", true)
	body.set_meta("system_examiner_trap_species", species)
	body.set_meta("system_examiner_trap_source", plant.name)
	body.set_meta("system_examiner_trap_release_at_msec", Time.get_ticks_msec() + int(capture_seconds * 1000.0))

	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = Vector3.ZERO

	# Route the hazard through the game's real combat-health component when
	# the captured actor is the player; rival actors use their own damage API.
	var health_component := body.get_node_or_null("PlayerCombatHealth")
	if health_component != null and health_component.has_method("receive_damage"):
		health_component.call("receive_damage", damage_amount, plant)
	elif body.has_method("take_damage"):
		body.call("take_damage", damage_amount, plant)

	var captured_origin := body.global_position
	body.set_meta("system_examiner_capture_origin", captured_origin)
	body.set_meta("system_examiner_swallowed", true)

	# Pull the runner into the maw, close the petals around them, then hide only
	# rendered actor meshes so the player camera and physics body remain active.
	var swallow_tween := create_tween()
	swallow_tween.tween_property(body, "global_position", plant.to_global(Vector3(0.0, 1.25, 0.0)), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	swallow_tween.tween_callback(func():
		if is_instance_valid(body):
			_set_captured_actor_visuals_visible(body, false)
	)
	for petal_index in range(6):
		var petal := plant.get_node_or_null("ToothedPetal_%02d" % petal_index) as Node3D
		if petal != null:
			var petal_angle := TAU * float(petal_index) / 6.0
			var closing_tween := create_tween()
			closing_tween.tween_property(petal, "position", Vector3(cos(petal_angle) * 0.32, 1.05, sin(petal_angle) * 0.32), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var maw := plant.get_node_or_null("PredatorMaw") as Node3D
	if maw != null:
		var maw_tween := create_tween()
		maw_tween.tween_property(maw, "scale", Vector3(0.12, 0.12, 0.12), 0.24)
		maw_tween.tween_interval(maxf(0.25, capture_seconds - 0.55))
		maw_tween.tween_property(maw, "scale", Vector3.ONE, 0.31)

	await get_tree().create_timer(capture_seconds).timeout
	if is_instance_valid(body):
		_set_captured_actor_visuals_visible(body, true)
		if is_instance_valid(plant):
			var release_position := plant.to_global(Vector3(0.0, 0.0, 2.8))
			release_position.y = captured_origin.y
			body.global_position = release_position
		else:
			body.global_position = captured_origin
		body.set_meta("system_examiner_trapped", false)
		body.set_meta("system_examiner_swallowed", false)
		body.set_meta("system_examiner_released_from_trap", true)
		body.remove_meta("system_examiner_trap_release_at_msec")
		body.remove_meta("system_examiner_capture_origin")
	if is_instance_valid(plant):
		for petal_index in range(6):
			var petal := plant.get_node_or_null("ToothedPetal_%02d" % petal_index) as Node3D
			if petal != null:
				var petal_angle := TAU * float(petal_index) / 6.0
				var opening_tween := create_tween()
				opening_tween.tween_property(petal, "position", Vector3(cos(petal_angle) * 1.05, 1.55, sin(petal_angle) * 1.05), 0.3)
		plant.set_meta("system_plant_has_captured_candidate", false)
		await get_tree().create_timer(4.0).timeout
		if is_instance_valid(plant):
			plant.set_meta("system_plant_cooldown", false)


func _set_captured_actor_visuals_visible(actor: Node, should_be_visible: bool) -> void:
	for child in actor.get_children():
		if child is VisualInstance3D:
			(child as VisualInstance3D).visible = should_be_visible
		else:
			_set_captured_actor_visuals_visible(child, should_be_visible)

func _build_marsh_tree(index: int, location: Vector3, bark: Material, canopy_a: Material, canopy_b: Material, canopy_c: Material) -> void:
	var tree := Node3D.new()
	tree.name = "MarshTree_%03d" % index
	tree.position = location
	var species := index % 4
	tree.set_meta("system_tree_species", ["bald_cypress", "swamp_oak", "broadleaf_marsh_tree", "willow_like_tree"][species])
	add_child(tree)
	var height := 7.0 + float(index % 6) * 1.15
	var stem := MeshInstance3D.new()
	stem.name = "Trunk"
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.24 if species != 1 else 0.38
	stem_mesh.bottom_radius = 0.48 if species != 1 else 0.68
	stem_mesh.height = height
	stem.mesh = stem_mesh
	stem.position.y = height * 0.5
	stem.material_override = bark
	tree.add_child(stem)
	var crown_material: Material = canopy_a if species == 0 else (canopy_b if species == 1 else canopy_c)
	if species == 0:
		for crown_index in range(3):
			var crown := MeshInstance3D.new()
			crown.name = "CypressCanopy_%02d" % crown_index
			var crown_mesh := CylinderMesh.new()
			crown_mesh.top_radius = 0.0
			crown_mesh.bottom_radius = 2.8 - float(crown_index) * 0.48
			crown_mesh.height = 3.8
			crown.mesh = crown_mesh
			crown.position = Vector3(0.0, height * 0.48 + float(crown_index) * 1.8, 0.0)
			crown.material_override = crown_material
			tree.add_child(crown)
	else:
		var crown := MeshInstance3D.new()
		crown.name = "BroadCanopy"
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 3.0 + float(index % 3) * 0.5
		crown_mesh.height = 3.7 + float(index % 2)
		crown.mesh = crown_mesh
		crown.position.y = height + 1.0
		crown.material_override = crown_material
		tree.add_child(crown)
		if species == 3:
			for branch_index in range(5):
				var branch := MeshInstance3D.new()
				branch.name = "DroopingWillowBranch_%02d" % branch_index
				var branch_mesh := CylinderMesh.new()
				branch_mesh.top_radius = 0.035
				branch_mesh.bottom_radius = 0.12
				branch_mesh.height = 3.8
				branch.mesh = branch_mesh
				branch.position = Vector3(cos(float(branch_index) * TAU / 5.0) * 2.0, height - 0.5, sin(float(branch_index) * TAU / 5.0) * 2.0)
				branch.rotation.z = 0.48
				branch.material_override = canopy_b
				tree.add_child(branch)

func _build_giant_turtle(index: int, location: Vector3, shell_material: Material, body_material: Material) -> void:
	var turtle := Node3D.new()
	turtle.name = "GiantMarshTurtle_%02d" % index
	turtle.position = location
	turtle.set_meta("system_wildlife_species", "giant_marsh_turtle")
	turtle.set_meta("system_wildlife_scale", "giant")
	add_child(turtle)
	var shell := MeshInstance3D.new()
	shell.name = "Shell"
	var shell_mesh := SphereMesh.new()
	shell_mesh.radius = 3.2
	shell_mesh.height = 3.0
	shell.mesh = shell_mesh
	shell.position.y = 2.0
	shell.material_override = shell_material
	turtle.add_child(shell)
	var shell_body := StaticBody3D.new()
	shell_body.name = "ShellCollision"
	var shell_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.8
	shell_shape.shape = sphere
	shell_shape.position.y = 2.0
	shell_body.add_child(shell_shape)
	turtle.add_child(shell_body)
	for leg_index in range(4):
		var leg := MeshInstance3D.new()
		leg.name = "Leg_%02d" % leg_index
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.55
		leg_mesh.height = 1.8
		leg.mesh = leg_mesh
		leg.position = Vector3(-1.8 if leg_index < 2 else 1.8, 0.65, -1.7 if leg_index % 2 == 0 else 1.7)
		leg.material_override = body_material
		turtle.add_child(leg)

func _build_marsh_beasts(material: Material) -> void:
	for index in range(4):
		var beast := Node3D.new()
		beast.name = "MarshBeast_%02d" % index
		beast.position = Vector3(-36.0 + float(index) * 24.0, 0.0, 68.0)
		beast.set_meta("system_wildlife_species", "marshland_beast")
		beast.set_meta("system_wildlife_scale", "large")
		add_child(beast)
		var body := MeshInstance3D.new()
		body.name = "BeastBody"
		var mesh := CapsuleMesh.new()
		mesh.radius = 1.5
		mesh.height = 4.5
		body.mesh = mesh
		body.position.y = 2.0
		body.material_override = material
		beast.add_child(body)

func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	add_child(mesh_instance)
	if collision:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.position = position
		body.add_child(shape)
		add_child(body)

func _add_label(node_name: String, content: String, position: Vector3, color: Color, parent: Node = null) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = content
	label.font_size = 24
	label.pixel_size = 0.014
	label.position = position if parent == null else position - parent.position
	label.modulate = color
	if parent == null:
		add_child(label)
	else:
		parent.add_child(label)

func _material(color: Color, metallic: float, roughness: float, transparent: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	if transparent:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return result
