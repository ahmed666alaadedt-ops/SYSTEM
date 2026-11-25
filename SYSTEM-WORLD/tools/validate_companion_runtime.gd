extends SceneTree

## Confirms Miyar and Adam are interface-only assistants, not player followers.

func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not be loaded")
		return
	var scene := packed.instantiate()
	if scene == null:
		_fail("MainScene.tscn could not be instantiated")
		return
	root.add_child(scene)
	await process_frame
	await process_frame

	var manager := scene.get_node_or_null("SYSTEMCompanionManager")
	if manager == null:
		_fail("SYSTEMCompanionManager assistant interface was not mounted by main.gd")
		return
	if manager.get("miyar") != null or manager.get("adam") != null:
		_fail("Miyar or Adam was instantiated as a world companion instead of remaining interface-only")
		return
	if manager.get_node_or_null("SYSTEM_Miyar") != null or manager.get_node_or_null("SYSTEM_Adam") != null:
		_fail("A Miyar/Adam follower model was mounted under the assistant manager")
		return
	var layer := manager.get_node_or_null("SYSTEMCompanionInterface") as CanvasLayer
	if layer == null:
		_fail("The interface-only assistant panel is missing")
		return
	var miyar_button := layer.find_child("MiyarAssistantButton", true, false) as Button
	var adam_button := layer.find_child("AdamAssistantButton", true, false) as Button
	var dialogue := layer.find_child("AssistantDialogue", true, false) as Label
	if miyar_button == null or adam_button == null or dialogue == null:
		_fail("Miyar/Adam assistant controls or dialogue surface are missing")
		return
	miyar_button.pressed.emit()
	if str(manager.get("selected_assistant")) != "miyar" or not dialogue.text.begins_with("ميار:"):
		_fail("Miyar interface selection did not open her SYSTEM explanation")
		return
	adam_button.pressed.emit()
	if str(manager.get("selected_assistant")) != "adam" or not dialogue.text.begins_with("آدم:"):
		_fail("Adam interface selection did not open his SYSTEM explanation")
		return

	print("SYSTEM ASSISTANT INTERFACE VALIDATION PASSED: Miyar and Adam remain UI-only; no world follower models are created.")
	quit(0)


func _fail(reason: String) -> void:
	push_error("SYSTEM ASSISTANT INTERFACE VALIDATION FAILED: " + reason)
	quit(1)
