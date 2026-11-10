
extends Node

# SYSTEM WORLD
# Android <-> Godot communication bridge
# Godot 4.3

signal world_entry_requested(world_id: String)
signal bridge_message(message: String)

const WorldData = preload("res://scripts/world_data.gd")

var pending_world_id: String = ""
var last_requested_world: String = ""
var bridge_ready: bool = false


func _ready() -> void:
	bridge_ready = true
	_read_startup_arguments()

	bridge_message.emit(
		"SYSTEM Android bridge is ready."
	)


# --------------------------------------------------
# REQUEST WORLD ENTRY
# --------------------------------------------------

func request_world_entry(world_id: String) -> bool:
	var normalized_id := WorldData.normalize_world_id(
		world_id
	)

	if normalized_id.is_empty():
		bridge_message.emit(
			"Unknown world: " + world_id
		)
		return false

	pending_world_id = normalized_id
	last_requested_world = normalized_id

	world_entry_requested.emit(normalized_id)

	bridge_message.emit(
		"World entry requested: " + normalized_id
	)

	return true


# --------------------------------------------------
# RECEIVE REQUEST FROM ANDROID
# --------------------------------------------------

func receive_android_world_request(
	world_id: String
) -> bool:
	return request_world_entry(world_id)


# --------------------------------------------------
# PENDING REQUEST
# --------------------------------------------------

func has_pending_world_request() -> bool:
	return not pending_world_id.is_empty()


func consume_pending_world_request() -> String:
	var requested_world := pending_world_id

	pending_world_id = ""

	return requested_world


func get_last_requested_world() -> String:
	return last_requested_world


# --------------------------------------------------
# STARTUP ARGUMENTS
# --------------------------------------------------

func _read_startup_arguments() -> void:
	var arguments := OS.get_cmdline_user_args()

	for argument in arguments:
		if argument.begins_with("--system-world="):
			var world_id := argument.trim_prefix(
				"--system-world="
			)

			request_world_entry(world_id)
			return


# --------------------------------------------------
# BRIDGE STATUS
# --------------------------------------------------

func is_bridge_ready() -> bool:
	return bridge_ready


func get_bridge_status() -> Dictionary:
	return {
		"ready": bridge_ready,
		"pending_world": pending_world_id,
		"last_requested_world": last_requested_world
	}
