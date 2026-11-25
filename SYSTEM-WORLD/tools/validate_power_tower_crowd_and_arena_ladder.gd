extends SceneTree

const PowerTowerScript = preload("res://scripts/system_power_tower_manager.gd")
const OperationsScript = preload("res://scripts/system_baghdad_tower_operations_manager.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var power_manager = PowerTowerScript.new()
	var expected_ladder := {
		1: 8, 20: 8, 21: 6, 40: 6, 41: 4, 60: 4,
		61: 3, 80: 3, 81: 2, 100: 2, 101: 1, 200: 1
	}
	for floor_value in expected_ladder.keys():
		var floor_number := int(floor_value)
		var data: Dictionary = power_manager.call("get_floor_data", floor_number)
		assert(int(data.get("arena_count", 0)) == int(expected_ladder[floor_value]), "Arena count ladder mismatch at floor %d." % floor_number)
		assert(str(data.get("competition_format", "")) == "INDIVIDUAL_1V1")
		assert(str(data.get("opponent_kind", "")) == "HUMAN_PLAYER")
		assert(not bool(data.get("ai_fallback", true)))
	power_manager.free()

	var operations = OperationsScript.new()
	var room := Node3D.new()
	room.name = "PowerTowerCrowdTestRoom"
	room.set_meta("system_power_tower_floor", 1)
	operations.call("_create_power_tower_spectator_gallery", room, 24.0)
	var gallery := room.get_node_or_null("PowerTowerSpectatorGallery") as Node3D
	assert(gallery != null)
	assert(int(gallery.get_meta("system_audience_population_target", 0)) == 500)
	var full_rigs := gallery.get_node_or_null("PowerTowerAudienceActors") as Node3D
	assert(full_rigs != null and full_rigs.get_child_count() == 8)
	var impostors := gallery.get_node_or_null("PowerTowerCrowdImpostors") as MultiMeshInstance3D
	assert(impostors != null and impostors.multimesh != null)
	assert(impostors.multimesh.instance_count == 492)
	var seat_count := 0
	for child in gallery.get_children():
		if bool(child.get_meta("system_power_tower_spectator_seat", false)):
			seat_count += 1
	assert(seat_count == 48)
	print("POWER TOWER CROWD/LADDER VALIDATION PASSED: arena counts 8/6/4/3/2/1 across 200 floors; 500 audience (8 detailed + 492 LOD), 48 reserved seats; official fights remain human 1v1.")
	operations.free()
	room.free()
	quit(0)
