extends SceneTree

const Builder = preload("res://scripts/system_antiques_market_world_builder.gd")

func _initialize() -> void:
	if not _run_facility_checks():
		quit(1)
		return
	print("ANTIQUES_MARKET_3D_FACILITIES_TESTS_PASSED")
	quit(0)


func _run_facility_checks() -> bool:
	var cases := [
		{"floor": 29, "type": "global_auction_hall", "node": "GlobalAuctionHallInteraction"},
		{"floor": 30, "type": "secret_trader_lounge", "node": "SecretTraderLoungeInteraction"},
		{"floor": 31, "type": "authenticity_appraisal", "node": "AuthenticityAppraisalInteraction"},
		{"floor": 32, "type": "collector_reputation", "node": "CollectorReputationInteraction"}
	]
	for entry in cases:
		var floor_number := int(entry["floor"])
		var floor_root := Node3D.new()
		root.add_child(floor_root)
		Builder.build_floor(floor_root, floor_number, 29.0)
		var experience := floor_root.get_node_or_null("AntiqueMarketWorldExperience") as Node3D
		if experience == null:
			push_error("Missing 3D experience on antiques floor %d." % floor_number)
			return false
		var interaction := experience.get_node_or_null(str(entry["node"])) as Area3D
		if interaction == null:
			push_error("Missing interaction volume on antiques floor %d." % floor_number)
			return false
		if not interaction.is_in_group("system_interactable"):
			push_error("Antiques floor %d interaction is not discoverable." % floor_number)
			return false
		if str(interaction.get_meta("system_antique_facility_type", "")) != str(entry["type"]):
			push_error("Antiques floor %d interaction routes to the wrong service." % floor_number)
			return false
		if interaction.get_node_or_null("CollisionShape3D") == null:
			push_error("Antiques floor %d interaction has no collision shape." % floor_number)
			return false
		if experience.get_child_count() < 8:
			push_error("Antiques floor %d has too few 3D interior objects." % floor_number)
			return false
		if floor_number == 30:
			for trader_index in range(5):
				var trader_area := experience.get_node_or_null("SecretTraderInteraction_%02d" % trader_index) as Area3D
				if trader_area == null:
					push_error("Secret trader booth %d has no interaction." % trader_index)
					return false
				if str(trader_area.get_meta("system_secret_trader_id", "")).is_empty():
					push_error("Secret trader booth %d has no stable identity." % trader_index)
					return false
		floor_root.queue_free()
	return true
