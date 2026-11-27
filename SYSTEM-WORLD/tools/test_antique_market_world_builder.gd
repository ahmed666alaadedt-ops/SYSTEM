extends SceneTree

const Builder = preload("res://scripts/system_antiques_market_world_builder.gd")

func _initialize() -> void:
	var cases := [
		{"floor": 29, "type": "global_auction_hall", "node": "GlobalAuctionHallInteraction"},
		{"floor": 30, "type": "secret_trader_lounge", "node": "SecretTraderLoungeInteraction"},
		{"floor": 31, "type": "authenticity_appraisal", "node": "AuthenticityAppraisalInteraction"},
		{"floor": 32, "type": "collector_reputation", "node": "CollectorReputationInteraction"}
	]
	for entry in cases:
		var floor_root := Node3D.new()
		root.add_child(floor_root)
		Builder.build_floor(floor_root, int(entry.floor), 29.0)
		var experience := floor_root.get_node_or_null("AntiqueMarketWorldExperience") as Node3D
		assert(experience != null, "Each market floor must build its own 3D experience.")
		var interaction := experience.get_node_or_null(str(entry.node)) as Area3D
		assert(interaction != null, "Each facility must have a 3D interaction volume.")
		assert(interaction.is_in_group("system_interactable"), "Facility interaction must be discoverable by the player.")
		assert(str(interaction.get_meta("system_antique_facility_type", "")) == str(entry.type),
			"Facility metadata must route to the matching in-world service.")
		assert(interaction.get_node_or_null("CollisionShape3D") != null,
			"Facility interaction must have a collision shape.")
		assert(experience.get_child_count() >= 8, "Facility must contain its 3D interior objects and signage.")
		floor_root.queue_free()
	print("ANTIQUES_MARKET_3D_FACILITIES_TESTS_PASSED")
	quit(0)
