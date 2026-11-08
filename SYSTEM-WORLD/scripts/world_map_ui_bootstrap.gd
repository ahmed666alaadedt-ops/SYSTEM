extends Node

const MapUIScript = preload("res://scripts/world_map_ui.gd")

var attached := false


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if attached:
		set_process(false)
		return

	var main := get_tree().root.get_node_or_null("SYSTEMWorld")

	if main == null:
		return

	var map_manager: Variant = main.get("world_map_manager")
	var world_manager: Variant = main.get("world_manager")
	var player: Variant = main.get("player")

	if not map_manager is Node:
		return

	if not world_manager is Node:
		return

	if not player is CharacterBody3D:
		return

	var map_ui := MapUIScript.new()
	map_ui.name = "SYSTEMWorldMapUI"

	main.add_child(map_ui)

	map_ui.setup(
		map_manager,
		world_manager,
		player
	)

	attached = true
	set_process(false)

	print("SYSTEM WORLD: Interactive map UI connected.")
