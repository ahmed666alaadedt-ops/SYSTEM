extends SceneTree

func _initialize() -> void:
	call_deferred("_run_marketplace_bridge_checks")


func _run_marketplace_bridge_checks() -> void:
	var bridge_script: Script = load("res://scripts/system_android_bridge.gd")
	if bridge_script == null:
		push_error("Marketplace bridge script could not be loaded.")
		quit(1)
		return

	var bridge: Node = bridge_script.new()
	root.add_child(bridge)

	var received := {
		"request_id": "",
		"success": false
	}
	bridge.marketplace_result_received.connect(
		func(request_id: String, payload: Dictionary) -> void:
			received["request_id"] = request_id
			received["success"] = bool(payload.get("success", false))
	)

	var valid_response := JSON.stringify({
		"version": 1,
		"type": "marketplace_result",
		"request_id": "market_test_001",
		"payload": {
			"success": true,
			"data": {"balance": 120}
		}
	})
	if not bool(bridge.call("receive_android_message", valid_response)):
		push_error("Valid marketplace response was rejected.")
		quit(1)
		return
	if received["request_id"] != "market_test_001" or not received["success"]:
		push_error("Marketplace response was not routed to its matching request.")
		quit(1)
		return

	var missing_request_id := JSON.stringify({
		"version": 1,
		"type": "marketplace_result",
		"payload": {"success": true}
	})
	if bool(bridge.call("receive_android_message", missing_request_id)):
		push_error("Marketplace response without request_id was accepted.")
		quit(1)
		return

	if bool(bridge.call("request_marketplace_operation", "unknown_operation", {}, "market_test_002")):
		push_error("Unknown marketplace operation was accepted.")
		quit(1)
		return

	if bool(bridge.call("request_marketplace_operation", "wallet", {}, "market_test_003")):
		push_error("Marketplace request reported success without a native Android transport.")
		quit(1)
		return

	var status: Dictionary = bridge.call("get_bridge_status")
	if str(status.get("last_error", "")) != "ANDROID_TRANSPORT_UNAVAILABLE":
		push_error("Unavailable native transport was not reported accurately.")
		quit(1)
		return

	print("SYSTEM marketplace bridge validation passed: request IDs, response routing, allowlist and offline transport.")
	bridge.queue_free()
	quit(0)
