extends SceneTree

const CHARACTER_SCRIPT := preload("res://scripts/npc_character_model.gd")
const SOCIETY_SCRIPT := preload("res://scripts/ai_npc_society_manager.gd")
const DAILY_LIFE_SCRIPT := preload("res://scripts/npc_daily_life_manager.gd")
const POPULATION_SCRIPT := preload("res://scripts/npc_visible_population_manager.gd")
const THREAT_RECEIVER_SCRIPT := preload("res://scripts/npc_threat_receiver.gd")

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var child := CHARACTER_SCRIPT.new()
	root.add_child(child)
	child.call("configure", {
		"name": "Child Safety QA",
		"gender": "female",
		"age": 10,
		"job": "hunter",
		"world": "fantasy"
	}, 1)
	var child_mesh_report: Dictionary = child.call("get_mesh_safety_report")
	print("SYSTEM CHILD MESH SAFETY: ", child_mesh_report)
	if int(child_mesh_report.get("null_meshes", 0)) > 0 or int(child_mesh_report.get("invalid_mesh_rids", 0)) > 0:
		push_error("SYSTEM CHILD QA: imported character contains null or invalid mesh resources")
		quit(1)
		return
	child.call("set_activity", "attack")
	if str(child.get("current_activity")) != "idle":
		push_error("SYSTEM CHILD QA: child entered an offensive combat activity")
		quit(1)
		return
	if not bool(child.call("respond_to_attack")):
		push_error("SYSTEM CHILD QA: child could not trigger a defensive response after being attacked")
		quit(1)
		return
	if str(child.get("current_activity")) != "evade" or not bool(child.get("is_defending")):
		push_error("SYSTEM CHILD QA: child evasive defensive response state was not applied")
		quit(1)
		return
	child.call("set_activity", "attack")
	if str(child.get("current_activity")) != "idle" or bool(child.get("is_defending")):
		push_error("SYSTEM CHILD QA: defensive response allowed a child to initiate an attack")
		quit(1)
		return
	var profile: Dictionary = child.get("appearance_profile")
	if str(profile.get("job", "")) != "civilian" or str(profile.get("occupation", "")) != "civilian":
		push_error("SYSTEM CHILD QA: child profession was not restricted to civilian")
		quit(1)
		return

	var population := POPULATION_SCRIPT.new()
	root.add_child(population)
	var visible_actor := Node3D.new()
	visible_actor.set_script(THREAT_RECEIVER_SCRIPT)
	visible_actor.set("npc_id", "visible_child")
	visible_actor.set("population_manager", population)
	population.add_child(visible_actor)
	var attacker := Node3D.new()
	attacker.position = Vector3(3.0, 0.0, 0.0)
	root.add_child(attacker)
	var visible_child := CHARACTER_SCRIPT.new()
	visible_actor.add_child(visible_child)
	visible_child.call("configure", {"name": "Visible Child QA", "age": 10, "gender": "male"}, 0)
	population.set("pedestrians", {
		"visible_child": {
			"actor": visible_actor,
			"visual": visible_child,
			"destination": Vector3.ZERO,
			"path": [],
			"walking": false,
			"animation_walking": false
		}
	})
	if not bool(visible_actor.call("receive_threat", attacker)):
		push_error("SYSTEM CHILD QA: visible population did not route an attack into a defensive escape")
		quit(1)
		return
	var visible_record: Dictionary = population.get("pedestrians").get("visible_child", {})
	var escape_path: Array = visible_record.get("path", [])
	if escape_path.is_empty() or float(escape_path[escape_path.size() - 1].x) >= float(visible_actor.position.x):
		push_error("SYSTEM CHILD QA: child did not receive an escape path away from the attacker")
		quit(1)
		return

	var society := SOCIETY_SCRIPT.new()
	root.add_child(society)
	var child_npc_id: String = society.call("create_npc", "Child Resident QA", 0, 10.0, "curious", "police")
	var child_npc: Dictionary = society.call("get_npc", child_npc_id)
	if str(child_npc.get("occupation", "")) != "student":
		push_error("SYSTEM CHILD QA: society manager did not normalize a minor to student")
		quit(1)
		return
	if bool(society.call("set_activity", child_npc_id, "work")):
		push_error("SYSTEM CHILD QA: society manager allowed formal work for a minor")
		quit(1)
		return
	if not bool(society.call("set_activity", child_npc_id, "socialize")):
		push_error("SYSTEM CHILD QA: society manager blocked ordinary minor social life")
		quit(1)
		return

	var adult_official_id: String = society.call("create_npc", "Adult Official QA", 0, 30.0, "balanced", "police")
	var adult_official: Dictionary = society.call("get_npc", adult_official_id)
	if str(adult_official.get("occupation", "")) != "civilian":
		push_error("SYSTEM NPC QA: civilian society allowed an NPC to hold a police/official occupation")
		quit(1)
		return

	var daily_life := DAILY_LIFE_SCRIPT.new()
	daily_life.society_manager = society
	society.set("simulation_hours", 9.0)
	var teen_profile := {"age_years": 17.0, "occupation": "police", "parent_ids": []}
	var normal_needs := {"hunger": 100.0, "thirst": 100.0, "hygiene": 100.0, "energy": 100.0, "social": 100.0}
	if str(daily_life.call("_choose_action", teen_profile, normal_needs)) != "school":
		push_error("SYSTEM CHILD QA: minor daily schedule did not choose school instead of employment")
		quit(1)
		return
	society.set("simulation_hours", 17.0)
	if str(daily_life.call("_choose_action", teen_profile, normal_needs)) == "work":
		push_error("SYSTEM CHILD QA: minor daily schedule assigned employment outside school hours")
		quit(1)
		return

	var adult := CHARACTER_SCRIPT.new()
	root.add_child(adult)
	adult.call("configure", {
		"name": "Adult Combat QA",
		"gender": "male",
		"age": 28,
		"job": "hunter"
	}, 0)
	adult.call("set_activity", "attack")
	if str(adult.get("current_activity")) != "idle":
		push_error("SYSTEM NPC QA: adult civilian NPC was allowed to initiate offensive combat")
		quit(1)
		return
	if not bool(adult.call("respond_to_attack")) or str(adult.get("current_activity")) != "defend":
		push_error("SYSTEM NPC QA: adult civilian NPC could not enter defensive stance after being attacked")
		quit(1)
		return

	var visible_adult_actor := Node3D.new()
	visible_adult_actor.set_script(THREAT_RECEIVER_SCRIPT)
	visible_adult_actor.set("npc_id", "visible_adult")
	visible_adult_actor.set("population_manager", population)
	population.add_child(visible_adult_actor)
	var visible_adult := CHARACTER_SCRIPT.new()
	visible_adult_actor.add_child(visible_adult)
	visible_adult.call("configure", {"name": "Visible Adult QA", "age": 30, "gender": "female"}, 0)
	var population_records: Dictionary = population.get("pedestrians")
	population_records["visible_adult"] = {
		"actor": visible_adult_actor,
		"visual": visible_adult,
		"destination": Vector3.ZERO,
		"path": [],
		"walking": false,
		"animation_walking": false
	}
	population.set("pedestrians", population_records)
	attacker.position = Vector3(-3.0, 0.0, 0.0)
	if not bool(visible_adult_actor.call("receive_threat", attacker)):
		push_error("SYSTEM NPC QA: visible adult did not receive defensive threat response")
		quit(1)
		return
	if str(visible_adult.get("current_activity")) != "defend":
		push_error("SYSTEM NPC QA: visible adult did not retain defensive stance")
		quit(1)
		return

	# Report every character rig and every MeshInstance3D in this isolated test
	# scene. The first child rig was clean, but renderer errors continued after
	# the other adult/visible-character rigs were created.
	for character in [child, visible_child, adult, visible_adult]:
		if character.has_method("get_mesh_safety_report"):
			print("SYSTEM CHARACTER MESH SAFETY ", character.name, ": ",
				character.call("get_mesh_safety_report"))
	var scene_mesh_report := _get_scene_mesh_safety_report(root)
	print("SYSTEM CHILD QA SCENE MESH SAFETY: ", scene_mesh_report)
	if int(scene_mesh_report.get("null_meshes", 0)) > 0 or int(scene_mesh_report.get("invalid_mesh_rids", 0)) > 0:
		push_error("SYSTEM CHILD QA: test scene contains null or invalid mesh resources")
		quit(1)
		return

	print("SYSTEM NPC QA PASS: civilians do not join missions or initiate combat; minors evade and adults defend/retreat when attacked")
	await process_frame
	quit(0)


func _get_scene_mesh_safety_report(root_node: Node) -> Dictionary:
	var report := {
		"null_meshes": 0,
		"invalid_mesh_rids": 0,
		"valid_meshes": 0,
		"invalid_nodes": []
	}
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D:
			var mesh_node := current as MeshInstance3D
			if mesh_node.mesh == null:
				report["null_meshes"] += 1
				report["invalid_nodes"].append(str(mesh_node.get_path()) + " (null)")
			elif not mesh_node.mesh.get_rid().is_valid():
				report["invalid_mesh_rids"] += 1
				report["invalid_nodes"].append(str(mesh_node.get_path()) + " (invalid RID)")
			else:
				report["valid_meshes"] += 1
		for child_node in current.get_children():
			stack.append(child_node)
	return report
