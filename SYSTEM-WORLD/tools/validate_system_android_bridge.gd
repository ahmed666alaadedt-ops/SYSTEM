extends SceneTree

const BridgeScript = preload("res://scripts/system_android_bridge.gd")


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var bridge := BridgeScript.new()
    root.add_child(bridge)
    await process_frame

    var received: Array[Dictionary] = []
    bridge.marketplace_result_received.connect(
        func(request_id: String, payload: Dictionary) -> void:
            received.append({"request_id": request_id, "payload": payload})
    )

    var valid_response := JSON.stringify({
        "version": 1,
        "type": "marketplace_result",
        "request_id": "market_test_001",
        "payload": {
            "success": true,
            "data": {"balance": 1250, "currency": "SYSTEM"}
        }
    })
    if not bridge.receive_android_message(valid_response):
        _fail("A valid marketplace response was rejected.")
        return
    if received.size() != 1:
        _fail("The marketplace response signal was not emitted exactly once.")
        return
    if str(received[0].get("request_id", "")) != "market_test_001":
        _fail("The marketplace response request ID was not preserved.")
        return
    var response_payload: Dictionary = received[0].get("payload", {})
    if not bool(response_payload.get("success", false)):
        _fail("The marketplace response payload was altered.")
        return

    var missing_id := JSON.stringify({
        "version": 1,
        "type": "marketplace_result",
        "payload": {"success": true}
    })
    if bridge.receive_android_message(missing_id):
        _fail("A marketplace response without a request ID was accepted.")
        return

    if bridge.request_marketplace_operation("unlisted_operation", {}, "market_test_002"):
        _fail("An unlisted marketplace operation was accepted.")
        return

    if bridge.request_marketplace_operation("wallet", {}, "market_test_003"):
        _fail("Marketplace transport reported success without the native host.")
        return
    if str(bridge.get_bridge_status().get("last_error", "")) != "ANDROID_MARKETPLACE_TRANSPORT_UNAVAILABLE":
        _fail("Missing native transport was not reported accurately.")
        return

    if not bridge.receive_android_world_request("modern"):
        _fail("The modern-world request contract regressed.")
        return
    if bridge.consume_pending_world_request() != "modern":
        _fail("The pending modern-world request was not consumed correctly.")
        return

    print("SYSTEM Android marketplace bridge validation passed: request IDs, response delivery, operation allowlist and unavailable-host behavior.")
    bridge.queue_free()
    quit(0)


func _fail(reason: String) -> void:
    push_error("SYSTEM Android marketplace bridge validation failed: " + reason)
    quit(1)
