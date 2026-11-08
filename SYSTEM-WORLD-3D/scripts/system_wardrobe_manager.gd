extends Node
class_name SystemWardrobeManager

# SYSTEM WORLD - WORLD OUTFIT MANAGER
# Godot 4.3
# Manages Miyar and Adam outfits across four worlds.

signal outfit_changed(
	character_name: String,
	world_id: String,
	outfit_data: Dictionary
)

const WardrobeData = preload(
	"res://scripts/system_character_wardrobe.gd"
)

var current_world: String = "modern"

var miyar_character: Node3D
var adam_character: Node3D


func _ready() -> void:
	apply_current_world_outfits()


# ==========================================
# CHARACTER REGISTRATION
# ==========================================

func register_miyar(character: Node3D) -> void:
	miyar_character = character

	if is_instance_valid(miyar_character):
		apply_miyar_outfit(current_world)


func register_adam(character: Node3D) -> void:
	adam_character = character

	if is_instance_valid(adam_character):
		apply_adam_outfit(current_world)


# ==========================================
# WORLD SELECTION
# ==========================================

func change_world(world_id: String) -> void:
	if not WardrobeData.is_supported_world(world_id):
		push_warning(
			"Unsupported SYSTEM WORLD: " + world_id
		)
		return

	current_world = world_id

	apply_current_world_outfits()


func apply_current_world_outfits() -> void:
	apply_miyar_outfit(current_world)
	apply_adam_outfit(current_world)


# ==========================================
# MIYAR OUTFIT
# ==========================================

func apply_miyar_outfit(world_id: String) -> void:
	if not is_instance_valid(miyar_character):
		return

	var outfit := WardrobeData.get_miyar_outfit(
		world_id
	)

	_store_outfit_data(
		miyar_character,
		outfit,
		world_id,
		"Miyar"
	)

	outfit_changed.emit(
		"Miyar",
		world_id,
		outfit
	)


# ==========================================
# ADAM OUTFIT
# ==========================================

func apply_adam_outfit(world_id: String) -> void:
	if not is_instance_valid(adam_character):
		return

	var outfit := WardrobeData.get_adam_outfit(
		world_id
	)

	_store_outfit_data(
		adam_character,
		outfit,
		world_id,
		"Adam"
	)

	outfit_changed.emit(
		"Adam",
		world_id,
		outfit
	)


# ==========================================
# OUTFIT DATA
# ==========================================

func _store_outfit_data(
	character: Node3D,
	outfit: Dictionary,
	world_id: String,
	character_name: String
) -> void:
	character.set_meta(
		"system_outfit_data",
		outfit.duplicate(true)
	)

	character.set_meta(
		"system_outfit_world",
		world_id
	)

	character.set_meta(
		"system_character_name",
		character_name
	)


func get_miyar_outfit() -> Dictionary:
	return WardrobeData.get_miyar_outfit(
		current_world
	)


func get_adam_outfit() -> Dictionary:
	return WardrobeData.get_adam_outfit(
		current_world
	)


func get_current_world() -> String:
	return current_world


func get_outfit_description(
	character_name: String
) -> String:
	var outfit: Dictionary

	if character_name.to_lower() == "adam":
		outfit = get_adam_outfit()
	else:
		outfit = get_miyar_outfit()

	return str(outfit.get("design", ""))


func get_outfit_title(
	character_name: String
) -> String:
	var outfit: Dictionary

	if character_name.to_lower() == "adam":
		outfit = get_adam_outfit()
	else:
		outfit = get_miyar_outfit()

	return str(outfit.get("title", ""))
