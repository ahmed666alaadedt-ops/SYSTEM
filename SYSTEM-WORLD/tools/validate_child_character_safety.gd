extends SceneTree

const CHARACTER_SCRIPT := preload("res://scripts/npc_character_model.gd")
const SOCIETY_SCRIPT := preload("res://scripts/ai_npc_society_manager.gd")
const POPULATION_SCRIPT := preload("res://scripts/npc_visible_population_manager.gd")

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
	population.add_child(visible_actor)
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
	if not bool(population.call("notify_npc_attacked", "visible_child", Vector3(3.0, 0.0, 0.0))):
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

	var adult := CHARACTER_SCRIPT.new()
	root.add_child(adult)
	adult.call("configure", {
		"name": "Adult Combat QA",
		"gender": "male",
		"age": 28,
		"job": "hunter"
	}, 0)
	adult.call("set_activity", "attack")
	if str(adult.get("current_activity")) != "attack":
		push_error("SYSTEM CHILD QA: adult combat activity was incorrectly blocked")
		quit(1)
		return

	print("SYSTEM CHILD QA PASS: minors cannot take missions/jobs or initiate combat, can live socially and evade to safety when attacked, and adult combat remains available")
	child.queue_free()
	adult.queue_free()
	quit(0)
