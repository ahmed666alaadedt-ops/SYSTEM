extends Node

## Engine-side adapter for the versioned SYSTEM Android message protocol.
## The native Android plugin must register SYSTEMAndroidHost with
## message_from_android(raw_json) and send_to_android(raw_json).
## Until that plugin is installed, transport_connected remains false.

signal world_entry_requested(world_id: String)
signal player_context_received(context: Dictionary)
signal marketplace_result_received(request_id: String, payload: Dictionary)
signal message_to_android(message_type: String, payload: Dictionary)
signal bridge_status_changed(status: Dictionary)

const PROTOCOL_VERSION := 1
const MAX_MESSAGE_LENGTH := 16 * 1024
const NATIVE_SINGLETON_NAME := "SYSTEMAndroidHost"
const WORLD_IDS := ["fantasy", "historical", "modern", "greed_island"]
const INBOUND_TYPES := ["open_world", "player_context", "marketplace_result"]
const MARKETPLACE_OPERATIONS := [
    "wallet",
    "owned_artifacts",
    "browse_listings",
    "create_listing",
    "purchase_listing",
    "cancel_listing",
    "expire_listing",
    "trade_history",
    "browse_auctions",
    "create_auction",
    "place_bid",
    "auction_bids",
    "settle_auction",
    "cancel_auction",
    "exchange_offers",
    "create_exchange_offer",
    "accept_exchange_offer",
    "close_exchange_offer"
]

var _pending_world_id := ""
var _last_world_id := ""
var _last_error := ""
var _native_host: Object


func _ready() -> void:
    _connect_native_transport()
    _read_startup_arguments()


func _connect_native_transport() -> void:
    _native_host = null
    if not Engine.has_singleton(NATIVE_SINGLETON_NAME):
        _publish_status()
        return

    _native_host = Engine.get_singleton(NATIVE_SINGLETON_NAME)
    var callback := Callable(self, "receive_android_message")
    if _native_host.has_signal("message_from_android"):
        if not _native_host.is_connected("message_from_android", callback):
            _native_host.connect("message_from_android", callback)
    if _native_host.has_method("send_to_android"):
        _send_to_android(
            "bridge_ready",
            {"ready": true, "protocol_version": PROTOCOL_VERSION}
        )
    _publish_status()


## Receives a JSON envelope from the native Android plugin.
## Account context is display/session context only, never gameplay authority.
func receive_android_message(raw_message: String) -> bool:
    if raw_message.is_empty() or raw_message.length() > MAX_MESSAGE_LENGTH:
        _last_error = "MESSAGE_SIZE_INVALID"
        _publish_status()
        return false

    var parsed: Variant = JSON.parse_string(raw_message)
    if not parsed is Dictionary:
        _last_error = "MESSAGE_JSON_INVALID"
        _publish_status()
        return false

    var message: Dictionary = parsed
    if int(message.get("version", -1)) != PROTOCOL_VERSION:
        _last_error = "MESSAGE_VERSION_UNSUPPORTED"
        _publish_status()
        return false

    var message_type := str(message.get("type", ""))
    if message_type not in INBOUND_TYPES:
        _last_error = "MESSAGE_TYPE_NOT_ALLOWED"
        _publish_status()
        return false

    var payload: Variant = message.get("payload", {})
    if not payload is Dictionary:
        _last_error = "MESSAGE_PAYLOAD_INVALID"
        _publish_status()
        return false

    match message_type:
        "open_world":
            return receive_android_world_request(str(payload.get("world_id", "")))
        "player_context":
            var uid := str(payload.get("uid", "")).strip_edges()
            var display_name := str(payload.get("display_name", "")).strip_edges()
            if uid.length() > 128 or display_name.length() > 80:
                _last_error = "PLAYER_CONTEXT_INVALID"
                _publish_status()
                return false
            player_context_received.emit({
                "uid": uid,
                "display_name": display_name,
                "trusted": false
            })
            _last_error = ""
            _publish_status()
            return true
        "marketplace_result":
            var request_id := str(message.get("request_id", "")).strip_edges()
            if request_id.is_empty() or request_id.length() > 128:
                _last_error = "MARKETPLACE_RESPONSE_ID_INVALID"
                _publish_status()
                return false
            marketplace_result_received.emit(request_id, payload)
            _last_error = "" if bool(payload.get("success", false)) else str(
                payload.get("error", "MARKETPLACE_REQUEST_FAILED")
            )
            _publish_status()
            return true

    return false


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
    var payload := {
        "world_id": normalized_id,
        "world_name": world_name
    }
    message_to_android.emit("world_state", payload)
    _send_to_android("world_state", payload)
    _publish_status()


func publish_request_result(
    world_id: String,
    accepted: bool,
    reason: String
) -> void:
    var payload := {
        "world_id": world_id,
        "accepted": accepted,
        "reason": reason
    }
    message_to_android.emit("world_entry_result", payload)
    _send_to_android("world_entry_result", payload)


## Requests an authenticated marketplace operation through the Android host.
## Android echoes request_id so the game can match the asynchronous response.
func request_marketplace_operation(
    operation: String,
    payload: Dictionary,
    request_id: String
) -> bool:
    if (
        operation not in MARKETPLACE_OPERATIONS
        or request_id.strip_edges().is_empty()
        or request_id.length() > 128
    ):
        _last_error = "MARKETPLACE_REQUEST_INVALID"
        _publish_status()
        return false

    var request_payload := payload.duplicate(true)
    request_payload["operation"] = operation
    message_to_android.emit("marketplace_request", request_payload)
    var sent := _send_to_android("marketplace_request", request_payload, request_id)
    if not sent:
        _last_error = "ANDROID_MARKETPLACE_TRANSPORT_UNAVAILABLE"
        _publish_status()
        return false
    _last_error = ""
    _publish_status()
    return true


func get_bridge_status() -> Dictionary:
    var connected := (
        is_instance_valid(_native_host)
        and _native_host.has_method("send_to_android")
        and _native_host.has_signal("message_from_android")
    )
    return {
        "ready": is_inside_tree(),
        "pending_world_id": _pending_world_id,
        "last_world_id": _last_world_id,
        "last_error": _last_error,
        "transport_connected": connected
    }


func _send_to_android(
    message_type: String,
    payload: Dictionary,
    request_id: String = ""
) -> bool:
    if not is_instance_valid(_native_host):
        return false
    if not _native_host.has_method("send_to_android"):
        return false

    var envelope := {
        "version": PROTOCOL_VERSION,
        "type": message_type,
        "payload": payload
    }
    if not request_id.is_empty():
        envelope["request_id"] = request_id

    var raw_message := JSON.stringify(envelope)
    if raw_message.length() > MAX_MESSAGE_LENGTH:
        _last_error = "MESSAGE_SIZE_INVALID"
        return false

    _native_host.call("send_to_android", raw_message)
    return true


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
