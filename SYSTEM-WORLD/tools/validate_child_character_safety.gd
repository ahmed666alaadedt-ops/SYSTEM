extends SceneTree

const CHARACTER_SCRIPT := preload("res://scripts/npc_character_model.gd")

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
		push_error("SYSTEM CHILD QA: child entered a combat activity")
		quit(1)
		return
	var profile: Dictionary = child.get("appearance_profile")
	if str(profile.get("job", "")) != "civilian":
		push_error("SYSTEM CHILD QA: child profession was not restricted to civilian")
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

	print("SYSTEM CHILD QA PASS: children remain civilian and cannot enter combat; adult combat remains available")
	child.queue_free()
	adult.queue_free()
	quit(0)
