extends Node3D
class_name SYSTEMBaghdadBataweenMarketManager

const ORIGIN_LATITUDE := 33.3152
const ORIGIN_LONGITUDE := 44.3661
const BATAWEEN_LATITUDE := 33.3201
const BATAWEEN_LONGITUDE := 44.4205
const WGS84_SEMI_MAJOR_AXIS_M := 6378137.0
const WGS84_INVERSE_FLATTENING := 298.257223563
const MARKET_LOCATION_ID := "baghdad_bataween_antiquities_market"
const MARKET_WIDTH_M := 132.0
const MARKET_DEPTH_M := 112.0

var terrain: Node
var market_position := Vector3.INF
var stall_count := 0
var interaction_count := 0
var _stone_material: StandardMaterial3D
var _wood_material: StandardMaterial3D
var _brass_material: StandardMaterial3D
var _canopy_material: StandardMaterial3D
var _sign_material: StandardMaterial3D


func setup(p_terrain: Node) -> bool:
	terrain = p_terrain
	if terrain == null or not terrain.has_method("is_land_position") or not terrain.has_method("get_terrain_height"):
		push_warning("SYSTEM Baghdad Bataween Market: terrain API is unavailable.")
		return false

	var anchor := _bataween_local_position()
	if not bool(terrain.call("is_land_position", anchor.x, anchor.y)):
		push_warning("SYSTEM Baghdad Bataween Market: the surveyed Al-Bataween anchor is not land in the active terrain; no relocated market was generated.")
		return false

	market_position = Vector3(
		anchor.x,
		float(terrain.call("get_terrain_height", anchor.x, anchor.y)),
		anchor.y
	)
	position = market_position
	_create_materials()
	_create_market_access_route()
	_build_market()
	set_meta("system_location_id", MARKET_LOCATION_ID)
	set_meta("system_display_name", "سوق التحف والآثار الغامضة")
	set_meta("system_market_category_name", "التحف والآثار الغامضة")
	set_meta("system_full_display_name", "سوق التحف والآثار الغامضة")
	set_meta("system_marketplace_kind", "player_to_player_artifact_market")
	set_meta("system_geography_source", "WGS84 Al-Bataween neighborhood anchor")
	set_meta("system_wgs84_latitude", BATAWEEN_LATITUDE)
	set_meta("system_wgs84_longitude", BATAWEEN_LONGITUDE)
	set_meta("system_market_stall_count", stall_count)
	set_meta("system_market_interaction_count", interaction_count)
	set_meta("system_marketplace_backend", "authenticated_firebase_callable_functions")
	set_meta("system_marketplace_currency", "virtual_SYSTEM_only")
	set_meta("gameplay_status", "physical_bataween_market_generated_server_marketplace_connected_by_in_world_ui")
	return true


func _create_market_access_route() -> void:
	if not terrain.has_method("get_baghdad_bridge_far_bank_anchor"):
		push_warning("SYSTEM Baghdad Bataween Market: opposite Republic Bridge bank anchor is unavailable.")
		return
	var start: Vector3 = terrain.call("get_baghdad_bridge_far_bank_anchor")
	if start == Vector3.INF:
		return
	var start_xz := Vector2(start.x, start.z)
	var finish_xz := Vector2(market_position.x, market_position.z + 43.0)
	var route_delta := finish_xz - start_xz
	var route_length := route_delta.length()
	if route_length < 10.0:
		return
	var side := Vector2(-route_delta.normalized().y, route_delta.normalized().x) * 6.0
	var route_material := _material(Color(0.095, 0.10, 0.105), 0.94, 0.08)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(route_material)
	var segment_count := maxi(8, int(ceil(route_length / 35.0)))
	for segment_index in range(segment_count):
		var t0 := float(segment_index) / float(segment_count)
		var t1 := float(segment_index + 1) / float(segment_count)
		var center_a := start_xz.lerp(finish_xz, t0)
		var center_b := start_xz.lerp(finish_xz, t1)
		var a_left := center_a + side
		var a_right := center_a - side
		var b_left := center_b + side
		var b_right := center_b - side
		var a := Vector3(a_left.x - market_position.x, float(terrain.call("get_terrain_height", a_left.x, a_left.y)) + 0.18 - market_position.y, a_left.y - market_position.z)
		var b := Vector3(a_right.x - market_position.x, float(terrain.call("get_terrain_height", a_right.x, a_right.y)) + 0.18 - market_position.y, a_right.y - market_position.z)
		var c := Vector3(b_left.x - market_position.x, float(terrain.call("get_terrain_height", b_left.x, b_left.y)) + 0.18 - market_position.y, b_left.y - market_position.z)
		var d := Vector3(b_right.x - market_position.x, float(terrain.call("get_terrain_height", b_right.x, b_right.y)) + 0.18 - market_position.y, b_right.y - market_position.z)
		# Counter-clockwise winding keeps the road's visible normal facing upward.
		surface.add_vertex(a)
		surface.add_vertex(c)
		surface.add_vertex(b)
		surface.add_vertex(c)
		surface.add_vertex(d)
		surface.add_vertex(b)
	surface.generate_normals()
	var route_mesh := surface.commit()
	if route_mesh == null or route_mesh.get_surface_count() == 0:
		push_warning("SYSTEM Baghdad Bataween Market: access route mesh could not be generated.")
		return
	var route := MeshInstance3D.new()
	route.name = "BataweenPlayableAccessRoute"
	route.mesh = route_mesh
	route.material_override = route_material
	route.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	route.set_meta("system_generated_access_route", true)
	route.set_meta("system_geography_source", "procedural terrain-conforming Al-Bataween access route; not OpenStreetMap road geometry")
	add_child(route)

	var route_body := StaticBody3D.new()
	route_body.name = "BataweenPlayableAccessRouteCollision"
	var route_collision := CollisionShape3D.new()
	route_collision.name = "CollisionShape3D"
	var route_shape := ConcavePolygonShape3D.new()
	route_shape.set_faces(route_mesh.get_faces())
	route_collision.shape = route_shape
	route_body.add_child(route_collision)
	add_child(route_body)


func _bataween_local_position() -> Vector2:
	var origin_ecef := _wgs84_ecef_components(ORIGIN_LATITUDE, ORIGIN_LONGITUDE)
	var point_ecef := _wgs84_ecef_components(BATAWEEN_LATITUDE, BATAWEEN_LONGITUDE)
	var dx := point_ecef[0] - origin_ecef[0]
	var dy := point_ecef[1] - origin_ecef[1]
	var dz := point_ecef[2] - origin_ecef[2]
	var origin_latitude := deg_to_rad(ORIGIN_LATITUDE)
	var origin_longitude := deg_to_rad(ORIGIN_LONGITUDE)
	var east := -sin(origin_longitude) * dx + cos(origin_longitude) * dy
	var north := (
		-sin(origin_latitude) * cos(origin_longitude) * dx
		-sin(origin_latitude) * sin(origin_longitude) * dy
		+cos(origin_latitude) * dz
	)
	return Vector2(east, -north)


func _wgs84_ecef_components(latitude_degrees: float, longitude_degrees: float) -> PackedFloat64Array:
	var flattening := 1.0 / WGS84_INVERSE_FLATTENING
	var eccentricity_squared := flattening * (2.0 - flattening)
	var latitude := deg_to_rad(latitude_degrees)
	var longitude := deg_to_rad(longitude_degrees)
	var sin_latitude := sin(latitude)
	var prime_vertical_radius := WGS84_SEMI_MAJOR_AXIS_M / sqrt(
		1.0 - eccentricity_squared * sin_latitude * sin_latitude
	)
	var coordinates := PackedFloat64Array()
	coordinates.append(prime_vertical_radius * cos(latitude) * cos(longitude))
	coordinates.append(prime_vertical_radius * cos(latitude) * sin(longitude))
	coordinates.append(prime_vertical_radius * (1.0 - eccentricity_squared) * sin_latitude)
	return coordinates


func get_market_position() -> Vector3:
	return market_position


func get_market_stats() -> Dictionary:
	return {
		"location_id": MARKET_LOCATION_ID,
		"position": market_position,
		"stall_count": stall_count,
		"interaction_count": interaction_count,
		"wgs84_latitude": BATAWEEN_LATITUDE,
		"wgs84_longitude": BATAWEEN_LONGITUDE,
		"currency": "SYSTEM"
	}


func _create_materials() -> void:
	_stone_material = _material(Color(0.48, 0.39, 0.29), 0.94, 0.0)
	_wood_material = _material(Color(0.24, 0.12, 0.065), 0.86, 0.08)
	_brass_material = _material(Color(0.72, 0.52, 0.22), 0.38, 0.76)
	_canopy_material = _material(Color(0.34, 0.12, 0.075), 0.82, 0.0)
	_sign_material = _material(Color(0.10, 0.075, 0.045), 0.52, 0.35)


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


func _build_market() -> void:
	name = "BaghdadAlBataweenAntiquitiesMarket"
	var ground := MeshInstance3D.new()
	ground.name = "MarketCourtyard"
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(MARKET_WIDTH_M, 0.55, MARKET_DEPTH_M)
	ground.mesh = ground_mesh
	ground.position.y = 0.275
	ground.material_override = _stone_material
	add_child(ground)
	_add_box_collision(self, "MarketCourtyardCollision", ground.position, ground_mesh.size)

	_add_market_sign()
	_add_market_gate()
	_add_historical_relic_quest_altar()
	_add_assyrian_relic_quest_altar()

	var hidden_trace := Node3D.new()
	hidden_trace.name = "HiddenBabylonianInscriptionTrace"
	hidden_trace.position = Vector3(13.0, 0.25, 27.0)
	hidden_trace.visible = false
	hidden_trace.add_to_group("system_hidden_historical_trace")
	var trace_marker := MeshInstance3D.new()
	trace_marker.name = "EchoTraceMarker"
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.65
	marker_mesh.height = 1.3
	trace_marker.mesh = marker_mesh
	trace_marker.material_override = _brass_material
	hidden_trace.add_child(trace_marker)
	var trace_label := Label3D.new()
	trace_label.name = "EchoTraceLabel"
	trace_label.text = "نقش بابلي مخفي — أثر يقود إلى سر قديم"
	trace_label.font_size = 16
	trace_label.position = Vector3(0.0, 1.6, 0.0)
	hidden_trace.add_child(trace_label)
	add_child(hidden_trace)
	_add_main_aisles()
	_build_stalls()
	_add_lighting()
	set_meta("system_market_is_independent_of_five_towers", true)
	set_meta("system_market_is_not_a_sixth_tower", true)
	set_meta("system_market_uses_existing_antiques_marketplace_backend", true)


func _add_historical_relic_quest_altar() -> void:
	var pedestal := MeshInstance3D.new()
	pedestal.name = "SealedHistoricalRelicPedestal"
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 1.5
	pedestal_mesh.bottom_radius = 2.0
	pedestal_mesh.height = 1.5
	pedestal.mesh = pedestal_mesh
	pedestal.position = Vector3(0.0, 1.0, 34.0)
	pedestal.material_override = _brass_material
	add_child(pedestal)
	_add_box_collision(self, "SealedHistoricalRelicPedestalCollision", pedestal.position, Vector3(3.4, 1.5, 3.4))
	var relic := MeshInstance3D.new()
	relic.name = "SealedBabylonStarTablet"
	var relic_mesh := BoxMesh.new()
	relic_mesh.size = Vector3(1.0, 1.3, 0.35)
	relic.mesh = relic_mesh
	relic.position = Vector3(0.0, 2.35, 34.0)
	relic.material_override = _wood_material
	add_child(relic)
	var label := Label3D.new()
	label.name = "SealedHistoricalRelicLabel"
	label.text = "لوح النجمة المختوم — أثر يوقظ مهارة نادرة"
	label.font_size = 19
	label.position = Vector3(0.0, 4.0, 34.0)
	label.modulate = Color(0.76, 0.88, 1.0)
	add_child(label)
	var interaction := Area3D.new()
	interaction.name = "HistoricalRelicQuestStart"
	interaction.position = Vector3(0.0, 1.7, 37.0)
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_location_id", "mysterious_antiques_relic_quest")
	interaction.set_meta("system_historical_relic_quest_start", true)
	interaction.set_meta("system_interaction_prompt", "افحص لوح النجمة المختوم وابدأ مهمة أصداء بابل")
	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.5
	shape_node.shape = sphere
	interaction.add_child(shape_node)
	add_child(interaction)
	interaction_count += 1


func _add_assyrian_relic_quest_altar() -> void:
	var pedestal := MeshInstance3D.new()
	pedestal.name = "SealedAssyrianRelicPedestal"
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 1.35
	pedestal_mesh.bottom_radius = 1.85
	pedestal_mesh.height = 1.35
	pedestal.mesh = pedestal_mesh
	pedestal.position = Vector3(8.5, 0.9, 34.0)
	pedestal.material_override = _stone_material
	add_child(pedestal)
	_add_box_collision(self, "SealedAssyrianRelicPedestalCollision", pedestal.position, Vector3(3.2, 1.4, 3.2))
	var relic := MeshInstance3D.new()
	relic.name = "SealedAssyrianRoyalSeal"
	var relic_mesh := BoxMesh.new()
	relic_mesh.size = Vector3(1.15, 1.0, 0.3)
	relic.mesh = relic_mesh
	relic.position = Vector3(8.5, 2.05, 34.0)
	relic.material_override = _brass_material
	add_child(relic)
	var label := Label3D.new()
	label.name = "SealedAssyrianRelicLabel"
	label.text = "الختم الملكي الآشوري — سر حراس نينوى"
	label.font_size = 17
	label.position = Vector3(8.5, 3.65, 34.0)
	label.modulate = Color(1.0, 0.78, 0.48)
	add_child(label)
	var interaction := Area3D.new()
	interaction.name = "AssyrianRelicQuestStart"
	interaction.position = Vector3(8.5, 1.6, 37.0)
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_location_id", "mysterious_antiques_assyrian_relic_quest")
	interaction.set_meta("system_assyrian_relic_quest_start", true)
	interaction.set_meta("system_interaction_prompt", "افحص الختم الملكي الآشوري وابدأ مهمة حراس نينوى")
	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.2
	shape_node.shape = sphere
	interaction.add_child(shape_node)
	add_child(interaction)
	interaction_count += 1


func _add_market_sign() -> void:
	var arch := MeshInstance3D.new()
	arch.name = "BataweenMarketEntryArch"
	var arch_mesh := BoxMesh.new()
	arch_mesh.size = Vector3(34.0, 1.3, 2.0)
	arch.mesh = arch_mesh
	arch.position = Vector3(0.0, 8.6, 51.0)
	arch.material_override = _brass_material
	add_child(arch)

	var left_pillar := MeshInstance3D.new()
	left_pillar.name = "EntryPillarLeft"
	var pillar_mesh := BoxMesh.new()
	pillar_mesh.size = Vector3(1.8, 9.0, 2.0)
	left_pillar.mesh = pillar_mesh
	left_pillar.position = Vector3(-16.0, 4.5, 51.0)
	left_pillar.material_override = _stone_material
	add_child(left_pillar)

	var right_pillar := MeshInstance3D.new()
	right_pillar.name = "EntryPillarRight"
	right_pillar.mesh = pillar_mesh
	right_pillar.position = Vector3(16.0, 4.5, 51.0)
	right_pillar.material_override = _stone_material
	add_child(right_pillar)

	var title := Label3D.new()
	title.name = "BataweenMarketTitle"
	title.text = "سوق التحف والآثار الغامضة\nMYSTERIOUS ANTIQUES & ARTIFACTS MARKET"
	title.font_size = 34
	title.pixel_size = 0.012
	title.position = Vector3(0.0, 10.4, 50.2)
	title.modulate = Color(1.0, 0.86, 0.58)
	add_child(title)

	var subtitle := Label3D.new()
	subtitle.name = "BataweenMarketSubtitle"
	subtitle.text = "بيع وشراء ومزادات بين اللاعبين — SYSTEM"
	subtitle.font_size = 19
	subtitle.pixel_size = 0.012
	subtitle.position = Vector3(0.0, 6.7, 50.0)
	subtitle.modulate = Color(0.95, 0.91, 0.82)
	add_child(subtitle)


func _add_market_gate() -> void:
	var gate := Area3D.new()
	gate.name = "BataweenMarketMainInteraction"
	gate.position = Vector3(0.0, 1.5, 43.0)
	gate.collision_layer = 1
	gate.collision_mask = 0
	gate.add_to_group("system_interactable")
	gate.set_meta("system_location_id", MARKET_LOCATION_ID)
	gate.set_meta("system_bataween_market_action", "open_market")
	gate.set_meta("system_marketplace_section", "market")
	gate.set_meta("system_interaction_type", "bataween_player_market_entry")
	gate.set_meta("system_interaction_prompt", "افتح سوق التحف والآثار الغامضة")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 5.0
	shape.shape = sphere
	gate.add_child(shape)
	add_child(gate)
	interaction_count += 1


func _add_main_aisles() -> void:
	for lane_index in range(3):
		var lane := MeshInstance3D.new()
		lane.name = "MarketAisle_%02d" % lane_index
		var lane_mesh := BoxMesh.new()
		lane_mesh.size = Vector3(MARKET_WIDTH_M - 12.0, 0.08, 7.0)
		lane.mesh = lane_mesh
		lane.position = Vector3(0.0, 0.59, -25.0 + float(lane_index) * 25.0)
		lane.material_override = _brass_material
		add_child(lane)


func _build_stalls() -> void:
	var categories := [
		{"id": "iraqi_heritage", "name": "التراث العراقي", "subtitle": "سومر وأكد وبابل وآشور"},
		{"id": "manuscripts", "name": "المخطوطات والوثائق", "subtitle": "مخطوطات ونسخ فنية خيالية"},
		{"id": "coins", "name": "النقود والمسكوكات", "subtitle": "عملات وميداليات داخل اللعبة"},
		{"id": "ceramics", "name": "الخزف والفخار", "subtitle": "خزف وأوانٍ فنية"},
		{"id": "metalwork", "name": "المعادن والحلي", "subtitle": "حلي وتماثيل ومشغولات"},
		{"id": "player_market", "name": "تجارة اللاعبين", "subtitle": "بيع وشراء القطع المملوكة"},
		{"id": "player_listings", "name": "عروض اللاعبين", "subtitle": "تصفح عروض البيع والشراء"},
		{"id": "restoration", "name": "الترميم والتقييم", "subtitle": "فحص الحالة وسجل المنشأ"}
	]
	for index in range(24):
		var row := int(index / 6)
		var column := index % 6
		var x := (float(column) - 2.5) * 19.0
		var z := (float(row) - 1.5) * 22.0 - 3.0
		var category: Dictionary = categories[row * 2 + (column % 2)]
		_build_stall(index + 1, Vector3(x, 0.0, z), category)
		stall_count += 1


func _build_stall(stall_number: int, stall_position: Vector3, category: Dictionary) -> void:
	var stall := Node3D.new()
	stall.name = "AntiquesStall_%02d" % stall_number
	stall.position = stall_position
	stall.set_meta("system_market_stall_id", "bataween_stall_%02d" % stall_number)
	stall.set_meta("system_market_category", str(category["id"]))
	stall.set_meta("system_market_stall_is_player_commerce", str(category["id"]) in ["player_market", "player_listings"])
	add_child(stall)

	var back_wall := MeshInstance3D.new()
	back_wall.name = "StallBackWall"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(12.0, 5.2, 0.65)
	back_wall.mesh = wall_mesh
	back_wall.position = Vector3(0.0, 2.6, -3.5)
	back_wall.material_override = _stone_material
	stall.add_child(back_wall)
	_add_box_collision(stall, "StallBackWallCollision", back_wall.position, wall_mesh.size)

	for side in [-1.0, 1.0]:
		var side_wall := MeshInstance3D.new()
		side_wall.name = "StallSideWall_%s" % str(side)
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.65, 4.4, 7.0)
		side_wall.mesh = side_mesh
		side_wall.position = Vector3(side * 5.7, 2.2, 0.0)
		side_wall.material_override = _stone_material
		stall.add_child(side_wall)
		_add_box_collision(stall, "StallSideWallCollision_%s" % str(side), side_wall.position, side_mesh.size)

	var canopy := MeshInstance3D.new()
	canopy.name = "StallCanopy"
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(13.0, 0.55, 8.5)
	canopy.mesh = canopy_mesh
	canopy.position = Vector3(0.0, 5.2, 0.0)
	canopy.material_override = _canopy_material
	stall.add_child(canopy)
	_add_box_collision(stall, "StallCanopyCollision", canopy.position, canopy_mesh.size)

	var counter := MeshInstance3D.new()
	counter.name = "DisplayCounter"
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(8.4, 1.25, 1.35)
	counter.mesh = counter_mesh
	counter.position = Vector3(0.0, 0.85, 2.4)
	counter.material_override = _wood_material
	stall.add_child(counter)
	_add_box_collision(stall, "DisplayCounterCollision", counter.position, counter_mesh.size)

	var display_case := MeshInstance3D.new()
	display_case.name = "ArtifactDisplayCase"
	var case_mesh := BoxMesh.new()
	case_mesh.size = Vector3(5.8, 1.15, 1.0)
	display_case.mesh = case_mesh
	display_case.position = Vector3(0.0, 2.0, 2.3)
	display_case.material_override = _brass_material
	stall.add_child(display_case)
	_add_box_collision(stall, "ArtifactDisplayCaseCollision", display_case.position, case_mesh.size)

	for display_index in range(3):
		var artifact := MeshInstance3D.new()
		artifact.name = "VirtualArtifactDisplay_%02d" % display_index
		match display_index:
			0:
				var relic_box := BoxMesh.new()
				relic_box.size = Vector3(0.72, 0.85, 0.55)
				artifact.mesh = relic_box
			1:
				var relic_cylinder := CylinderMesh.new()
				relic_cylinder.top_radius = 0.32
				relic_cylinder.bottom_radius = 0.42
				relic_cylinder.height = 0.9
				artifact.mesh = relic_cylinder
			_:
				var relic_sphere := SphereMesh.new()
				relic_sphere.radius = 0.4
				relic_sphere.height = 0.8
				artifact.mesh = relic_sphere
		artifact.position = Vector3(-1.65 + float(display_index) * 1.65, 2.85, 2.25)
		artifact.material_override = _brass_material if display_index != 1 else _wood_material
		stall.add_child(artifact)

	var sign := Label3D.new()
	sign.name = "StallSign"
	sign.text = str(category["name"]) + "\n" + str(category["subtitle"])
	sign.font_size = 18
	sign.pixel_size = 0.012
	sign.position = Vector3(0.0, 6.3, 4.0)
	sign.modulate = Color(1.0, 0.88, 0.68)
	stall.add_child(sign)

	var interaction := Area3D.new()
	interaction.name = "StallMarketplaceInteraction"
	interaction.position = Vector3(0.0, 1.45, 5.0)
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_location_id", MARKET_LOCATION_ID)
	interaction.set_meta("system_bataween_market_action", "open_market")
	interaction.set_meta("system_marketplace_section", str(category["id"]))
	interaction.set_meta("system_market_stall_id", "bataween_stall_%02d" % stall_number)
	interaction.set_meta("system_interaction_type", "bataween_player_market_stall")
	interaction.set_meta("system_interaction_prompt", "تصفح " + str(category["name"]) + " — سوق التحف والآثار الغامضة")
	var interaction_shape := CollisionShape3D.new()
	var interaction_sphere := SphereShape3D.new()
	interaction_sphere.radius = 4.0
	interaction_shape.shape = interaction_sphere
	interaction.add_child(interaction_shape)
	stall.add_child(interaction)
	interaction_count += 1


func _add_lighting() -> void:
	for index in range(8):
		var light := OmniLight3D.new()
		light.name = "MarketLantern_%02d" % index
		light.position = Vector3(-52.0 + float(index) * 15.0, 7.0, -38.0)
		light.light_color = Color(1.0, 0.72, 0.42)
		light.light_energy = 0.65
		light.omni_range = 24.0
		add_child(light)


func _add_box_collision(parent: Node, node_name: String, box_position: Vector3, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
