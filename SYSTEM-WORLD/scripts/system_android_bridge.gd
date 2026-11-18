extends Node

## Stable engine-side boundary for the Android host.
## A native Godot Android plugin can call receive_android_world_request()
## and listen to message_to_android after the Godot AAR is integrated.

signal world_entry_requested(world_id: String)
signal message_to_android(message_type: String, payload: Dictionary)
signal bridge_status_changed(status: Dictionary)

const WORLD_IDS := [
	"fantasy",
	"historical",
	"modern",
	"greed_island"
]

var _pending_world_id := ""
var _last_world_id := ""
var _last_error := ""


func _ready() -> void:
	_read_startup_arguments()


func receive_android_world_request(raw_world_id: String) -> bool:
	var world_id := _normalize_world_id(raw_world_id)
	if world_id.is_empty():
		_last_error = "UNKNOWN_WORLD_ID"
		_publish_status()
		return false

	_pending_world_id = world_id
	_last_world_id = world_id
	_last_error = ""
	world_entry_requested.emit(world_id)
	_publish_status()
	return true


func has_pending_world_request() -> bool:
	return not _pending_world_id.is_empty()


func consume_pending_world_request() -> String:
	var requested_world := _pending_world_id
	_pending_world_id = ""
	_publish_status()
	return requested_world


func publish_world_state(world_id: String, world_name: String) -> void:
	var normalized_id := _normalize_world_id(world_id)
	if normalized_id.is_empty():
		return

	_last_world_id = normalized_id
	message_to_android.emit(
		"world_state",
		{
			"world_id": normalized_id,
			"world_name": world_name
		}
	)
	_publish_status()


func publish_request_result(
	world_id: String,
	accepted: bool,
	reason: String
) -> void:
	message_to_android.emit(
		"world_entry_result",
		{
			"world_id": world_id,
			"accepted": accepted,
			"reason": reason
		}
	)


func get_bridge_status() -> Dictionary:
	return {
		"ready": is_inside_tree(),
		"pending_world_id": _pending_world_id,
		"last_world_id": _last_world_id,
		"last_error": _last_error,
		"transport_connected": false
	}


func _normalize_world_id(raw_world_id: String) -> String:
	var normalized := raw_world_id.strip_edges().to_lower()
	if normalized in WORLD_IDS:
		return normalized
	return ""


func _read_startup_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--system-world="):
			var world_id := argument.trim_prefix("--system-world=")
			receive_android_world_request(world_id)
			return


func _publish_status() -> void:
	bridge_status_changed.emit(get_bridge_status())
