extends SceneTree

const SHOPPING_TOWER_ID := "shopping_tower_baghdad"

const FLOOR_FACILITIES := {
	4: "shopping_skill_store",
	5: "shopping_weapon_gallery",
	6: "shopping_weapon_gallery",
	7: "shopping_weapon_gallery",
	8: "shopping_ranged_gallery",
	9: "shopping_ranged_gallery",
	10: "shopping_ranged_gallery",
	11: "shopping_armor_gallery",
	12: "shopping_armor_gallery",
	13: "shopping_armor_gallery",
	15: "shopping_crafting_materials",
	16: "shopping_crafting_materials",
	17: "shopping_elixir_pharmacy",
	18: "shopping_elixir_pharmacy",
	19: "shopping_elixir_pharmacy",
	20: "shopping_nen_center",
	21: "shopping_nen_center",
	22: "shopping_nen_center",
	23: "shopping_advanced_elixir_lab",
	24: "shopping_advanced_elixir_lab",
	25: "shopping_advanced_elixir_lab",
	26: "shopping_rare_elixir_vault"
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://MainScene.tscn") as PackedScene
	if packed == null:
		_fail("MainScene.tscn could not be loaded.")
		return

	var main := packed.instantiate() as Node3D
	if main == null:
		_fail("Main scene root is not Node3D.")
		return

	root.add_child(main)
	for _frame in range(24):
		await process_frame

	var operations := main.get_node_or_null("BaghdadTowerOperationsManager")
	if operations == null:
		_fail("BaghdadTowerOperationsManager is unavailable.")
		return

	var total_displays := 0
	var total_interactions := 0
	var total_purchase_routes := 0

	for floor_value in FLOOR_FACILITIES.keys():
		var floor_number := int(floor_value)
		var facility_type := str(FLOOR_FACILITIES[floor_value])
		var room := operations.call(
			"_ensure_floor_room",
			SHOPPING_TOWER_ID,
			floor_number
		) as Node3D
		if room == null:
			_fail("Could not create or resolve Shopping Tower floor %d." % floor_number)
			return

		var facility := room.get_node_or_null(
			"SpecialFacility_" + facility_type
		) as Node3D
		if facility == null:
			_fail("Floor %d is missing facility %s." % [floor_number, facility_type])
			return

		var showcase := facility.get_node_or_null("ShoppingShowcase") as Node3D
		var general_service := facility.get_node_or_null("FacilityServiceInteraction") as Area3D
		var general_service_shape := general_service.get_node_or_null("CollisionShape3D") as CollisionShape3D if general_service != null else null
		if general_service_shape == null or general_service_shape.position.z > -4.5:
			_fail("Floor %d generic department service target overlaps its product showcase interaction zones." % floor_number)
			return
		if showcase == null:
			_fail("Floor %d is missing its 3D ShoppingShowcase." % floor_number)
			return

		var floor_displays := 0
		for item in showcase.get_children():
			if not str(item.name).begins_with("ShowcaseItem_"):
				continue
			floor_displays += 1
			total_displays += 1

			var product_id := str(item.get_meta("system_showcase_product_id", ""))
			if product_id.is_empty():
				_fail("Floor %d display %s has no product ID." % [floor_number, item.name])
				return

			var product: Dictionary = operations.call("_get_catalog_product", product_id)
			if product.is_empty():
				_fail("Floor %d display references unknown catalog product %s." % [floor_number, product_id])
				return

			var interaction := item.get_node_or_null(
				"ShowcaseItemInteraction_%02d" % int(item.get_meta("system_showcase_item_index", -1))
			) as Area3D
			if interaction == null:
				_fail("Floor %d product %s has no Area3D interaction." % [floor_number, product_id])
				return
			if not interaction.is_in_group("system_interactable"):
				_fail("Floor %d product %s is not registered as interactable." % [floor_number, product_id])
				return
			if str(interaction.get_meta("system_showcase_product_id", "")) != product_id:
				_fail("Floor %d interaction metadata does not match product %s." % [floor_number, product_id])
				return
			if int(interaction.get_meta("system_tower_floor_number", -1)) != floor_number:
				_fail("Floor %d interaction has incorrect floor metadata." % floor_number)
				return
			if interaction.get_node_or_null("ShowcaseInteractionShape") == null:
				_fail("Floor %d product %s has no interaction collision shape." % [floor_number, product_id])
				return
			total_interactions += 1

			var opened: bool = operations.call(
				"open_showcase_product_service",
				SHOPPING_TOWER_ID,
				floor_number,
				facility_type,
				product_id
			)
			if not opened:
				_fail("Floor %d product %s could not open its real purchase preview." % [floor_number, product_id])
				return
			var content: Node = operations.get("content")
			var expected_control_name := "ShoppingProduct_" + product_id
			if str(product.get("product_type", "")) == "skill_training_permit":
				expected_control_name = "SkillManualPurchase_" + str(product.get("skill_id", ""))
			var selected_control: Button = null
			var selected_preview: Label = null
			if content != null:
				for child in content.get_children():
					if child.is_queued_for_deletion():
						continue
					if child is Button and str(child.name) == expected_control_name:
						selected_control = child
					elif child is Label and str(child.name) == "SelectedShowcaseProductPreview" and str(child.get_meta("system_showcase_product_id", "")) == product_id:
						selected_preview = child
			if selected_control == null or not selected_control.visible:
				_fail("Floor %d product %s has no visible, live purchase control (%s)." % [floor_number, product_id, expected_control_name])
				return
			if selected_preview == null:
				_fail("Floor %d product %s did not render its own live selected product preview." % [floor_number, product_id])
				return
			for child in content.get_children():
				if child is Button and not child.is_queued_for_deletion() and child != selected_control:
					var child_name := str(child.name)
					if (child_name.begins_with("ShoppingProduct_") or child_name.begins_with("SkillManualPurchase_")) and child.visible:
						_fail("Floor %d product %s left unrelated purchase control %s visible." % [floor_number, product_id, child_name])
						return
			total_purchase_routes += 1

		if floor_displays != 3:
			_fail("Floor %d must have exactly three distinct physical display stations; found %d." % [floor_number, floor_displays])
			return

	# Floor 14 is deliberately outside the new showcase build and keeps its legacy stations.
	var forge_room := operations.call(
		"_ensure_floor_room",
		SHOPPING_TOWER_ID,
		14
	) as Node3D
	if forge_room == null:
		_fail("Legacy Shopping Tower floor 14 is unavailable.")
		return
	if forge_room.get_node_or_null("WeaponsForge") == null:
		_fail("Legacy floor 14 WeaponsForge station was changed or lost.")
		return
	if forge_room.get_node_or_null("ElixirLaboratory") == null:
		_fail("Legacy floor 14 ElixirLaboratory station was changed or lost.")
		return
	if forge_room.get_node_or_null("SpecialFacility_shopping_weapon_gallery") != null:
		_fail("New weapon gallery was incorrectly installed on protected floor 14.")
		return

	print(
		"SYSTEM SHOPPING SHOWCASE QA PASS: floors=%d displays=%d interactions=%d purchase_previews=%d; floor 14 forge/laboratory preserved."
		% [FLOOR_FACILITIES.size(), total_displays, total_interactions, total_purchase_routes]
	)
	quit(0)


func _fail(message: String) -> void:
	push_error("SYSTEM SHOPPING SHOWCASE QA FAIL: " + message)
	quit(1)
