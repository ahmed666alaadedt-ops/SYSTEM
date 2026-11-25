extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> bool:
	if ok:
		return true
	push_error("Hunter marshland QA failed: " + message)
	quit(1)
	return false

func _count(parent: Node, prefix: String) -> int:
	var n := 0
	for child in parent.get_children():
		if child.name.begins_with(prefix):
			n += 1
	return n

func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if not _check(packed != null, "MainScene missing."): return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	for i in range(18): await process_frame
	var tunnel := scene.find_child("BaghdadHunterExaminationTunnel",true,false) as Node3D
	if not _check(tunnel != null, "Existing tunnel missing."): return
	var marsh := tunnel.get_node_or_null("HunterMarshland") as Node3D
	if not _check(marsh != null and bool(marsh.get_meta("system_marshland_runtime_ready",false)), "Marshland not initialized at tunnel exit."): return
	if not _check(bool(marsh.get_meta("system_marshland_replaces_zawraa_park",false)), "Park replacement marker missing."): return
	var reeds := marsh.get_node_or_null("MarshReeds_12000") as MultiMeshInstance3D
	if not _check(reeds != null and reeds.multimesh.instance_count == 12000, "Reed count is not 12,000."): return
	var trunks := marsh.get_node_or_null("WillowTrunks_160") as MultiMeshInstance3D
	if not _check(trunks != null and trunks.multimesh.instance_count == 160, "Willow count is not 160."): return
	for item in [["MarshPool_",8],["WoodenWalkway_",9],["MarshFogLayer_",18],["giant_",6],["MarshDecoyCandidate_",12],["FalseTrailRegion_",5]]:
		if not _check(_count(marsh,str(item[0])) == int(item[1]), "Wrong count for "+str(item[0])): return
	var ramp := tunnel.get_node_or_null("HunterTunnelToMarshlandRamp")
	if not _check(ramp != null and _count(ramp,"MarshlandRampCollision_") == 8, "Tunnel exit ramp is incomplete."): return
	for i in range(8):
		var water := marsh.get_node_or_null("MarshPool_%02d/MarshWaterVolume" % (i+1)) as Area3D
		if not _check(water != null and water.monitoring, "Marsh pool volume missing: "+str(i+1)): return
	print("SYSTEM HUNTER MARSHLAND QA PASS: 8 pools, 12,000 reeds, 160 willows, 9 walkways, 18 fog layers, 6 giant species, 12 decoys, 5 false trails; tunnel-connected.")
	quit(0)
