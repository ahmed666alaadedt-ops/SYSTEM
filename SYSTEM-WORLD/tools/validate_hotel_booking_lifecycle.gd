extends SceneTree

var operations: Node
var original_bookings: Dictionary = {}
var original_credits := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not load for hotel lifecycle validation.")
		return
	var main := packed.instantiate() as Node3D
	if main == null:
		_fail("Main scene root is not Node3D.")
		return
	root.add_child(main)
	for _frame in range(20):
		await process_frame

	operations = main.get_node_or_null("BaghdadTowerOperationsManager")
	if operations == null:
		_fail("BaghdadTowerOperationsManager was not initialized for hotel validation.")
		return

	var stored_bookings: Variant = operations.get("hotel_bookings")
	original_bookings = stored_bookings.duplicate(true) if stored_bookings is Dictionary else {}
	original_credits = int(operations.get("credits"))
	operations.set("hotel_bookings", {})
	operations.set("credits", 2000)

	var room_id := "hotel_standard_01"
	operations.call("_book_hotel_room", room_id, "غرفة قياسية 01", 180, "F", 2)
	var booking := _get_room_booking(room_id)
	if str(booking.get("status", "")) != "reserved" or str(booking.get("guest_id", "")) != "local_player" or int(booking.get("nights", 0)) != 2:
		_fail("Two-night room reservation did not create the expected reserved booking.")
		return
	if int(operations.get("credits")) != 1640:
		_fail("Room reservation did not debit exactly two nights from the local SYSTEM wallet.")
		return
	if bool(operations.call("_is_hotel_room_available", room_id)):
		_fail("A reserved hotel room was incorrectly reported as available.")
		return

	# Room service must be unavailable before check-in.
	operations.call("_place_hotel_room_service_order", "restaurant_baghdad_breakfast", "فطور بغدادي", 42)
	if int(operations.get("credits")) != 1640 or not _get_room_booking(room_id).get("room_service_orders", []).is_empty():
		_fail("Hotel room service accepted an order before guest check-in.")
		return

	operations.call("_check_in_hotel_room")
	booking = _get_room_booking(room_id)
	if str(booking.get("status", "")) != "checked_in" or int(booking.get("check_in_unix", 0)) <= 0:
		_fail("Hotel check-in did not move the reservation into checked_in state.")
		return
	var first_check_in := int(booking.get("check_in_unix", 0))
	operations.call("_check_in_hotel_room")
	if int(_get_room_booking(room_id).get("check_in_unix", 0)) != first_check_in:
		_fail("Repeated hotel check-in reset the original check-in timestamp.")
		return

	operations.call("_place_hotel_room_service_order", "restaurant_baghdad_breakfast", "فطور بغدادي", 42)
	booking = _get_room_booking(room_id)
	var orders: Array = booking.get("room_service_orders", [])
	if orders.size() != 1 or str(orders[0].get("status", "")) != "placed" or int(operations.get("credits")) != 1598:
		_fail("Hotel room service order was not stored and charged after check-in.")
		return
	operations.call("_update_hotel_room_service_order", 0, "preparing")
	operations.call("_update_hotel_room_service_order", 0, "delivered")
	booking = _get_room_booking(room_id)
	orders = booking.get("room_service_orders", [])
	if str(orders[0].get("status", "")) != "delivered" or orders[0].get("status_history", []) != ["preparing", "delivered"]:
		_fail("Hotel room service did not enforce the placed → preparing → delivered lifecycle.")
		return

	operations.call("_checkout_hotel_room")
	booking = _get_room_booking(room_id)
	if str(booking.get("status", "")) != "needs_cleaning" or not str(booking.get("guest_id", "")).is_empty():
		_fail("Checked-in guest checkout did not release the room into needs_cleaning state.")
		return
	if int(operations.get("credits")) != 1778:
		_fail("Early checkout refunded the consumed first night; only the unused second night may be refunded.")
		return
	if bool(operations.call("_is_hotel_room_available", room_id)):
		_fail("A room awaiting housekeeping was incorrectly marked available.")
		return

	operations.call("_start_hotel_room_cleaning", room_id)
	if str(_get_room_booking(room_id).get("status", "")) != "cleaning":
		_fail("Housekeeping could not transition the room from needs_cleaning to cleaning.")
		return
	operations.call("_complete_hotel_room_cleaning", room_id)
	booking = _get_room_booking(room_id)
	if str(booking.get("status", "")) != "ready" or not bool(booking.get("inspection_passed", false)) or not bool(operations.call("_is_hotel_room_available", room_id)):
		_fail("Room did not become bookable after completed cleaning and inspection.")
		return

	# A reservation cancelled before check-in is fully refunded and does not require cleaning.
	operations.call("_book_hotel_room", room_id, "غرفة قياسية 01", 180, "F", 1)
	if str(_get_room_booking(room_id).get("status", "")) != "reserved":
		_fail("A cleaned room could not be reserved again.")
		return
	operations.call("_checkout_hotel_room")
	booking = _get_room_booking(room_id)
	if str(booking.get("status", "")) != "ready" or not bool(booking.get("inspection_passed", false)) or int(operations.get("credits")) != 1778:
		_fail("Pre-check-in cancellation did not refund the full booking without triggering housekeeping.")
		return

	_restore_state()
	print("SYSTEM HOTEL LIFECYCLE QA PASS: reservation, check-in, room-service state transitions, consumed-night refund, housekeeping, inspection and pre-check-in cancellation.")
	quit(0)


func _get_room_booking(room_id: String) -> Dictionary:
	var all_bookings: Variant = operations.get("hotel_bookings")
	if not all_bookings is Dictionary:
		return {}
	var booking: Variant = all_bookings.get(room_id, {})
	return booking.duplicate(true) if booking is Dictionary else {}


func _restore_state() -> void:
	if not is_instance_valid(operations):
		return
	operations.set("hotel_bookings", original_bookings.duplicate(true))
	operations.set("credits", original_credits)
	operations.call("_save_hotel_bookings")
	operations.call("_save_wallet")


func _fail(message: String) -> void:
	_restore_state()
	push_error("SYSTEM HOTEL LIFECYCLE QA FAILED: " + message)
	quit(1)
