extends SceneTree

const TERRAIN_MANAGER = preload("res://scripts/modern_continent_manager.gd")


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var terrain := TERRAIN_MANAGER.new() as Node3D
	if terrain == null:
		_fail("ModernContinentManager could not be instantiated.")
		return
	terrain.name = "BaghdadBridgeDetailValidationTerrain"
	root.add_child(terrain)
	for frame_index in range(2):
		await process_frame

	if not bool(terrain.get("baghdad_bridge_reference_loaded")):
		_fail("Verified Republic Bridge/Tigris reference did not load.")
		return
	var bridge := terrain.get_node_or_null("BaghdadRepublicBridge") as Node3D
	if bridge == null:
		_fail("Verified Republic Bridge polygon deck was not built.")
		return
	if int(bridge.get_meta("system_osm_bridge_polygon_way_id", 0)) != 1077808833:
		_fail("Republic Bridge deck is not tied to the approved OSM polygon way.")
		return
	if int(bridge.get_meta("system_osm_primary_centerline_way_id", 0)) != 4080878 or int(bridge.get_meta("system_osm_secondary_centerline_way_id", 0)) != 754157537:
		_fail("Republic Bridge deck is missing one or both verified roadway centerline references.")
		return

	var deck := bridge.get_node_or_null("RepublicBridgeDeck") as MeshInstance3D
	var collision := bridge.get_node_or_null("RepublicBridgeDeckCollision/RepublicBridgeDeckCollisionShape") as CollisionShape3D
	if deck == null or deck.mesh == null or deck.mesh.get_surface_count() == 0:
		_fail("Republic Bridge triangulated deck mesh is missing or empty.")
		return
	if absf(float(deck.get_meta("system_bridge_deck_height_m", -999.0)) - 18.0) > 0.01:
		_fail("Republic Bridge deck elevation differs from the approved 18.0 m reference.")
		return
	if collision == null or not (collision.shape is ConcavePolygonShape3D):
		_fail("Republic Bridge deck does not have a physical concave collision shape.")
		return
	var collision_faces := (collision.shape as ConcavePolygonShape3D).get_faces()
	if collision_faces.size() < 30:
		_fail("Republic Bridge collision does not contain the triangulated deck faces.")
		return

	var guardrail_posts := bridge.get_node_or_null("RepublicBridgeGuardrailPosts") as MultiMeshInstance3D
	if guardrail_posts == null or guardrail_posts.multimesh == null or guardrail_posts.multimesh.instance_count < 16:
		_fail("Republic Bridge perimeter guardrail posts are missing or insufficient.")
		return
	var rail_count := bridge.find_children("RepublicBridgeGuardrail_*", "MeshInstance3D", true, false).size()
	var handrail_count := bridge.find_children("RepublicBridgeHandrail_*", "MeshInstance3D", true, false).size()
	if rail_count < 3 or handrail_count != rail_count:
		_fail("Republic Bridge continuous guardrails and matching handrails are incomplete.")
		return
	for marking_name in ["RepublicBridgeCenterlineMarkings", "RepublicBridgeLaneMarkings", "RepublicBridgeExpansionJoints"]:
		var marking := bridge.get_node_or_null(marking_name) as MeshInstance3D
		if marking == null or marking.mesh == null or marking.mesh.get_surface_count() == 0:
			_fail("Republic Bridge road detail surface is missing: " + marking_name)
			return

	var poles := bridge.get_node_or_null("RepublicBridgeLightPoles") as MultiMeshInstance3D
	var lamp_heads := bridge.get_node_or_null("RepublicBridgeLampHeads") as MultiMeshInstance3D
	if poles == null or lamp_heads == null or poles.multimesh == null or lamp_heads.multimesh == null:
		_fail("Republic Bridge approach lights are missing instanced poles or lamp heads.")
		return
	if poles.multimesh.instance_count < 4 or lamp_heads.multimesh.instance_count != poles.multimesh.instance_count:
		_fail("Republic Bridge light poles and lamp heads are not paired across the roadways.")
		return
	if int(bridge.get_meta("system_bridge_light_count", 0)) != poles.multimesh.instance_count:
		_fail("Republic Bridge lighting count metadata does not match its MultiMesh population.")
		return

	var river := terrain.get_node_or_null("BaghdadTigrisRiver") as MeshInstance3D
	var foam := terrain.get_node_or_null("BaghdadTigrisBankFoam") as MeshInstance3D
	if river == null or river.mesh == null or river.mesh.get_surface_count() == 0:
		_fail("Tigris River surface mesh is missing or empty.")
		return
	if str(river.get_meta("system_geography_source", "")) != "OpenStreetMap way 24709603":
		_fail("Tigris River surface is not tied to the verified OSM waterway.")
		return
	var water_material := river.material_override as ShaderMaterial
	if water_material == null or water_material.shader == null:
		_fail("Tigris River does not use its animated shader material.")
		return
	var shader_code := water_material.shader.code
	if not shader_code.contains("TIME * 0.52") or not shader_code.contains("world_position") or not shader_code.contains("EMISSION"):
		_fail("Tigris River shader is missing world-space time-driven ripples or glints.")
		return
	if foam == null or foam.mesh == null or foam.mesh.get_surface_count() == 0:
		_fail("Tigris Riverbank foam geometry is missing or empty.")
		return
	if str(foam.get_meta("system_water_edge_detail", "")) != "soft_bank_foam":
		_fail("Tigris Riverbank foam is missing its explicit edge-detail classification.")
		return

	print("Baghdad bridge detail validation passed: OSM polygon 1077808833 triangulated deck/collision at 18 m; ",
		guardrail_posts.multimesh.instance_count, " guardrail posts; rails/handrails=", rail_count,
		"; center/lane markings and expansion joints; paired instanced bridge lamps=", lamp_heads.multimesh.instance_count,
		"; Tigris OSM way 24709603 animated world-space water shader and bank foam." )
	# Keep this geometry validation independent of renderer teardown in headless CI.
	quit(0)


func _fail(message: String) -> void:
	push_error("Baghdad bridge detail validation failed: " + message)
	quit(1)
