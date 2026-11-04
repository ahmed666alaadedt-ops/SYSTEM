extends Node3D
class_name WorldManager

signal world_changed(world_id: int)

enum WorldID {
	FANTASY,
	MYTHOLOGY,
	REALISTIC
}

const WORLD_NAMES := {
	WorldID.FANTASY: "Fantasy World",
	WorldID.MYTHOLOGY: "Mythology World",
	WorldID.REALISTIC: "Realistic World"
}

var active_world: int = WorldID.FANTASY
var world_roots: Dictionary = {}


func _ready() -> void:
	create_worlds()
	switch_world(WorldID.FANTASY)


func create_worlds() -> void:
	for world_id in WORLD_NAMES:
		var world_root := Node3D.new()
		world_root.name = WORLD_NAMES[world_id]
		world_root.visible = false
		add_child(world_root)
		world_roots[world_id] = world_root


func switch_world(world_id: int) -> void:
	if not world_roots.has(world_id):
		push_warning("World ID does not exist.")
		return

	for id in world_roots:
		var world_root: Node3D = world_roots[id]
		world_root.visible = (id == world_id)
		world_root.process_mode = (
			Node.PROCESS_MODE_INHERIT
			if id == world_id
			else Node.PROCESS_MODE_DISABLED
		)

	active_world = world_id
	world_changed.emit(world_id)


func get_active_world() -> Node3D:
	return world_roots.get(active_world)


func get_world_name(world_id: int) -> String:
	return WORLD_NAMES.get(world_id, "Unknown World")
