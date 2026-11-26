extends Node3D
class_name SYSTEMPowerTowerCompetitionManager

signal nen_training_completed(result: Dictionary)

# Independent X-S-X Power Tower gameplay contract. Currency mutations must be
# delegated to the existing authoritative SYSTEM wallet/economy service.
const FLOOR_COUNT := 200
const SPECTATOR_NPC_TARGET := 500
const SPECTATOR_DETAILED_ACTOR_COUNT := 8
const SPECTATOR_VISUAL_LOD_COUNT := SPECTATOR_NPC_TARGET - SPECTATOR_DETAILED_ACTOR_COUNT
const ARENA_BANDS := [
	{"first": 1, "last": 20, "count": 8},
	{"first": 21, "last": 40, "count": 6},
	{"first": 41, "last": 60, "count": 4},
	{"first": 61, "last": 80, "count": 3},
	{"first": 81, "last": 100, "count": 2},
	{"first": 101, "last": 200, "count": 1}
]
const COMBAT_STYLES := [
	"UNARMED_HAND_TO_HAND", "KUNG_FU", "MARTIAL_ARTS",
	"TRADITIONAL_MELEE", "BOW_AND_ARROW", "NEN_TECHNIQUES"
]
const NEN_FLOOR_STAGES := [
	{"first": 1, "last": 20, "stage": "DISCOVERY", "label": "Nen Discovery and Aura Awareness"},
	{"first": 21, "last": 40, "stage": "TEN_CONTROL", "label": "Ten - Aura Control"},
	{"first": 41, "last": 60, "stage": "REN_OUTPUT", "label": "Ren - Aura Output"},
	{"first": 61, "last": 79, "stage": "ZETSU_CONTROL", "label": "Zetsu - Aura Concealment"},
	{"first": 80, "last": 100, "stage": "HATSU_FOUNDATION", "label": "Hatsu - Personal Ability"},
	{"first": 101, "last": 150, "stage": "ADVANCED_NEN", "label": "Advanced Nen"},
	{"first": 151, "last": 200, "stage": "NEN_MASTERY", "label": "Nen Mastery"}
]
# Tunable economy policy in basis points. UI must disclose the active policy
# before confirmation; actual wallet transfers are not performed in this class.
const BET_PAYOUT_POLICY_BPS := {
	"tower": 1000,
	"fighter": 1000,
	"winning_bettors": 8000
}

var _settled_match_ids: Dictionary = {}
var player_progression: Node

func _ready() -> void:
	name = "PowerTowerCompetitionManager"
	set_meta("system_power_tower_independent", true)
	set_meta("system_power_tower_floor_count", FLOOR_COUNT)
	set_meta("system_power_tower_arena_bands", ARENA_BANDS)
	set_meta("system_power_tower_spectator_npc_target", SPECTATOR_NPC_TARGET)
	set_meta("system_power_tower_combat_styles", COMBAT_STYLES)
	set_meta("system_power_tower_nen_progression", NEN_FLOOR_STAGES)
	set_meta("system_power_tower_betting_currency", "SYSTEM_VIRTUAL_CREDITS")
	set_meta("system_power_tower_betting_policy_bps", BET_PAYOUT_POLICY_BPS)
	_build_scaled_spectator_crowd()
	_build_arena_floor_layouts()
	_build_restaurant_and_recreation_amenities()

func get_arena_count_for_floor(floor_number: int) -> int:
	if floor_number < 1 or floor_number > FLOOR_COUNT:
		return 0
	for band in ARENA_BANDS:
		if floor_number >= int(band["first"]) and floor_number <= int(band["last"]):
			return int(band["count"])
	return 0

func get_nen_stage_for_floor(floor_number: int) -> Dictionary:
	if floor_number < 1 or floor_number > FLOOR_COUNT:
		return {}
	for band in NEN_FLOOR_STAGES:
		if floor_number >= int(band["first"]) and floor_number <= int(band["last"]):
			return band.duplicate(true)
	return {}

func get_combat_styles_for_floor(floor_number: int) -> Array:
	if floor_number < 1 or floor_number > FLOOR_COUNT:
		return []
	if floor_number >= 81:
		return ["NEN_TECHNIQUES", "UNARMED_HAND_TO_HAND"]
	if floor_number >= 41:
		return ["UNARMED_HAND_TO_HAND", "KUNG_FU", "MARTIAL_ARTS", "TRADITIONAL_MELEE", "BOW_AND_ARROW", "NEN_TECHNIQUES"]
	return ["UNARMED_HAND_TO_HAND", "KUNG_FU", "MARTIAL_ARTS", "TRADITIONAL_MELEE", "BOW_AND_ARROW"]

func configure_player_progression(progression_node: Node) -> void:
	player_progression = progression_node


func train_player_nen(training_id: String, floor_number: int, technique: String = "") -> Dictionary:
	var progression := player_progression if is_instance_valid(player_progression) else get_tree().root.find_child("SYSTEMPlayerProgression", true, false)
	if progression == null:
		return {"success": false, "reason": "PLAYER_PROGRESSION_UNAVAILABLE"}
	if not progression.has_method("complete_power_tower_nen_training"):
		return {"success": false, "reason": "POWER_TOWER_NEN_TRAINING_UNAVAILABLE"}
	var result: Dictionary = progression.call("complete_power_tower_nen_training", training_id, floor_number, technique)
	if bool(result.get("success", false)):
		nen_training_completed.emit(result)
	return result


func apply_nen_training(profile: Dictionary, training_points: int) -> Dictionary:
	var result := profile.duplicate(true)
	if training_points <= 0:
		return {"success": false, "reason": "INVALID_TRAINING_POINTS", "profile": result}
	var current := int(result.get("nen_mastery", 0))
	result["nen_mastery"] = clampi(current + training_points, 0, 1000)
	result["nen_discovered"] = true
	result["nen_training_sessions"] = int(result.get("nen_training_sessions", 0)) + 1
	result["nen_stage"] = _nen_stage_from_mastery(int(result["nen_mastery"]))
	return {"success": true, "profile": result}

func _nen_stage_from_mastery(mastery: int) -> String:
	if mastery >= 800: return "MASTERY"
	if mastery >= 600: return "ADVANCED"
	if mastery >= 400: return "HATSU"
	if mastery >= 250: return "REN"
	if mastery >= 100: return "TEN"
	if mastery > 0: return "AURA_AWARENESS"
	return "UNDISCOVERED"

func settle_virtual_bets(match_id: String, bets: Array, winning_side: String, official_result_verified: bool) -> Dictionary:
	if match_id.strip_edges().is_empty() or not official_result_verified:
		return {"success": false, "reason": "UNVERIFIED_MATCH_RESULT"}
	if _settled_match_ids.has(match_id):
		return {"success": false, "reason": "MATCH_ALREADY_SETTLED"}
	if winning_side.strip_edges().is_empty():
		return {"success": false, "reason": "INVALID_WINNING_SIDE"}
	var losing_total := 0
	var winning_total := 0
	for entry_value in bets:
		if not entry_value is Dictionary:
			return {"success": false, "reason": "INVALID_BET_ENTRY"}
		var entry: Dictionary = entry_value
		var stake := int(entry.get("stake", 0))
		if stake <= 0 or str(entry.get("bettor_id", "")).is_empty():
			return {"success": false, "reason": "INVALID_BET_STAKE"}
		if str(entry.get("side", "")) == winning_side:
			winning_total += stake
		else:
			losing_total += stake
	if winning_total <= 0:
		return {"success": false, "reason": "NO_WINNING_BETS"}
	var tower_bps := int(BET_PAYOUT_POLICY_BPS["tower"])
	var fighter_bps := int(BET_PAYOUT_POLICY_BPS["fighter"])
	var bettor_bps := int(BET_PAYOUT_POLICY_BPS["winning_bettors"])
	if tower_bps + fighter_bps + bettor_bps != 10000:
		return {"success": false, "reason": "INVALID_PAYOUT_POLICY"}
	var tower_profit := int(floor(float(losing_total * tower_bps) / 10000.0))
	var fighter_reward := int(floor(float(losing_total * fighter_bps) / 10000.0))
	var bettor_bonus_pool := losing_total - tower_profit - fighter_reward
	var payouts: Array = []
	var distributed_bonus := 0
	for entry_value in bets:
		var entry: Dictionary = entry_value
		if str(entry.get("side", "")) != winning_side:
			continue
		var stake := int(entry["stake"])
		var bonus := int(floor(float(bettor_bonus_pool * stake) / float(winning_total)))
		distributed_bonus += bonus
		payouts.append({"bettor_id": str(entry["bettor_id"]), "stake_return": stake, "profit": bonus, "total_payout": stake + bonus})
	# Rounding dust is assigned to the tower ledger, never silently minted.
	tower_profit += bettor_bonus_pool - distributed_bonus
	var ledger := {
		"match_id": match_id,
		"currency": "SYSTEM_VIRTUAL_CREDITS",
		"tower_profit": tower_profit,
		"fighter_reward": fighter_reward,
		"winning_bettor_payouts": payouts,
		"losing_stakes_total": losing_total,
		"winning_stakes_returned": winning_total,
		"settlement_verified": true
	}
	_settled_match_ids[match_id] = true
	return {"success": true, "ledger": ledger}

func _build_scaled_spectator_crowd() -> void:
	var crowd := Node3D.new()
	crowd.name = "PowerTower500SpectatorNPCs"
	crowd.set_meta("system_npc_population", SPECTATOR_NPC_TARGET)
	crowd.set_meta("system_npc_role", "POWER_TOWER_FAN_SPECTATOR")
	crowd.set_meta("system_npc_behaviour", ["WATCH_1V1", "CHEER", "REACT_TO_SCORE", "CELEBRATE_WINNER"])
	crowd.set_meta("system_npc_visual_lod", "MULTIMESH_CROWD_PROXY")
	add_child(crowd)
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.32
	body_mesh.height = 1.45
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.12, 0.24, 0.42)
	body_material.roughness = 0.82
	var bodies := MultiMesh.new()
	bodies.transform_format = MultiMesh.TRANSFORM_3D
	bodies.mesh = body_mesh
	bodies.instance_count = SPECTATOR_VISUAL_LOD_COUNT
	for index in range(SPECTATOR_VISUAL_LOD_COUNT):
		var ring := index / 100
		var slot := index % 100
		var angle := TAU * float(slot) / 100.0
		var radius := 31.0 + float(ring) * 2.2
		var height := 16.0 + float(ring) * 1.25
		var transform := Transform3D(Basis(Vector3.UP, -angle), Vector3(cos(angle) * radius, height, sin(angle) * radius))
		bodies.set_instance_transform(index, transform)
	var body_instance := MultiMeshInstance3D.new()
	body_instance.name = "SpectatorNPCBodies500"
	body_instance.multimesh = bodies
	body_instance.material_override = body_material
	crowd.add_child(body_instance)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.2
	head_mesh.height = 0.4
	var heads := MultiMesh.new()
	heads.transform_format = MultiMesh.TRANSFORM_3D
	heads.mesh = head_mesh
	heads.instance_count = SPECTATOR_VISUAL_LOD_COUNT
	for index in range(SPECTATOR_VISUAL_LOD_COUNT):
		var ring := index / 100
		var slot := index % 100
		var angle := TAU * float(slot) / 100.0
		var radius := 31.0 + float(ring) * 2.2
		var height := 16.95 + float(ring) * 1.25
		heads.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(cos(angle) * radius, height, sin(angle) * radius)))
	var head_instance := MultiMeshInstance3D.new()
	head_instance.name = "SpectatorNPCHeads500"
	head_instance.multimesh = heads
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.76, 0.62, 0.48)
	head_instance.material_override = head_material
	crowd.add_child(head_instance)
	crowd.set_meta("system_visible_spectator_count", SPECTATOR_NPC_TARGET)
	crowd.set_meta("system_multimesh_impostor_count", SPECTATOR_VISUAL_LOD_COUNT)
	crowd.set_meta("system_full_rig_count", SPECTATOR_DETAILED_ACTOR_COUNT)
	for actor_index in range(SPECTATOR_DETAILED_ACTOR_COUNT):
		var actor_angle := TAU * float(actor_index) / float(SPECTATOR_DETAILED_ACTOR_COUNT)
		var actor_position := Vector3(cos(actor_angle) * 28.0, 16.0, sin(actor_angle) * 28.0)
		var detailed_actor := _create_detailed_spectator_actor(actor_index, actor_position)
		crowd.add_child(detailed_actor)
	crowd.set_meta("system_detailed_actor_nodes_created", SPECTATOR_DETAILED_ACTOR_COUNT)
	_build_spectator_grandstands(crowd)


func _build_spectator_grandstands(crowd: Node3D) -> void:
	# Five concentric seating tiers align with the five 100-person crowd LOD rings.
	var stands := Node3D.new()
	stands.name = "PowerTowerFiveTierSpectatorGrandstands"
	stands.set_meta("system_grandstand_tier_count", 5)
	stands.set_meta("system_grandstand_seat_capacity", SPECTATOR_NPC_TARGET)
	crowd.add_child(stands)

	var tier_count := 5
	var seats_per_tier := 100
	var total_seats := tier_count * seats_per_tier
	var deck_multi := MultiMesh.new()
	deck_multi.transform_format = MultiMesh.TRANSFORM_3D
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(1.85, 0.28, 1.35)
	deck_multi.mesh = deck_mesh
	deck_multi.instance_count = total_seats

	var cushion_multi := MultiMesh.new()
	cushion_multi.transform_format = MultiMesh.TRANSFORM_3D
	var cushion_mesh := BoxMesh.new()
	cushion_mesh.size = Vector3(1.55, 0.24, 0.62)
	cushion_multi.mesh = cushion_mesh
	cushion_multi.instance_count = total_seats

	var backrest_multi := MultiMesh.new()
	backrest_multi.transform_format = MultiMesh.TRANSFORM_3D
	var backrest_mesh := BoxMesh.new()
	backrest_mesh.size = Vector3(1.55, 0.78, 0.18)
	backrest_multi.mesh = backrest_mesh
	backrest_multi.instance_count = total_seats

	for tier in range(tier_count):
		var radius := 31.0 + float(tier) * 2.2
		var tier_y := 15.42 + float(tier) * 1.25
		for slot in range(seats_per_tier):
			var index := tier * seats_per_tier + slot
			var angle := TAU * float(slot) / float(seats_per_tier)
			var outward := Vector3(cos(angle), 0.0, sin(angle))
			var center := outward * radius
			var facing_basis := Basis(Vector3.UP, -angle)
			deck_multi.set_instance_transform(index, Transform3D(facing_basis, Vector3(center.x, tier_y, center.z)))
			cushion_multi.set_instance_transform(index, Transform3D(facing_basis, Vector3(center.x, tier_y + 0.24, center.z)))
			var back_position := center + outward * 0.49
			backrest_multi.set_instance_transform(index, Transform3D(facing_basis, Vector3(back_position.x, tier_y + 0.69, back_position.z)))

	var deck_material := StandardMaterial3D.new()
	deck_material.albedo_color = Color(0.055, 0.085, 0.12)
	deck_material.metallic = 0.78
	deck_material.roughness = 0.26
	var cushion_material := StandardMaterial3D.new()
	cushion_material.albedo_color = Color(0.42, 0.12, 0.16)
	cushion_material.roughness = 0.72
	var backrest_material := StandardMaterial3D.new()
	backrest_material.albedo_color = Color(0.12, 0.16, 0.2)
	backrest_material.metallic = 0.48
	backrest_material.roughness = 0.38

	var decks := MultiMeshInstance3D.new()
	decks.name = "GrandstandTierDecks500"
	decks.multimesh = deck_multi
	decks.material_override = deck_material
	stands.add_child(decks)
	var cushions := MultiMeshInstance3D.new()
	cushions.name = "GrandstandSpectatorSeats500"
	cushions.multimesh = cushion_multi
	cushions.material_override = cushion_material
	stands.add_child(cushions)
	var backrests := MultiMeshInstance3D.new()
	backrests.name = "GrandstandSeatBackrests500"
	backrests.multimesh = backrest_multi
	backrests.material_override = backrest_material
	stands.add_child(backrests)

	stands.set_meta("system_grandstand_deck_count", total_seats)
	stands.set_meta("system_grandstand_seat_count", total_seats)
	stands.set_meta("system_grandstand_backrest_count", total_seats)
	stands.set_meta("system_grandstand_rows", tier_count)
	stands.set_meta("system_grandstand_seats_per_row", seats_per_tier)


func _create_detailed_spectator_actor(actor_index: int, actor_position: Vector3) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.name = "SpectatorDetailedNPC_%02d" % actor_index
	actor.position = actor_position
	actor.set_meta("system_npc_full_rig", true)
	actor.set_meta("system_npc_role", "POWER_TOWER_FAN_SPECTATOR")
	actor.set_meta("system_npc_detail_tier", "FULL_DETAIL")
	actor.set_meta("system_npc_behaviour", ["WATCH_1V1", "CHEER", "REACT_TO_SCORE", "CELEBRATE_WINNER"])
	var clothing_colors := [
		Color(0.12, 0.28, 0.52), Color(0.42, 0.16, 0.12),
		Color(0.12, 0.38, 0.26), Color(0.36, 0.28, 0.12),
		Color(0.28, 0.18, 0.42), Color(0.16, 0.36, 0.42),
		Color(0.42, 0.24, 0.32), Color(0.32, 0.34, 0.38)
	]
	var clothing := StandardMaterial3D.new()
	clothing.albedo_color = clothing_colors[actor_index % clothing_colors.size()]
	clothing.roughness = 0.82
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.68, 0.49, 0.36) if actor_index % 2 == 0 else Color(0.48, 0.32, 0.24)
	var body := MeshInstance3D.new()
	body.name = "Torso"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.25
	body.mesh = body_mesh
	body.position.y = 0.98
	body.material_override = clothing
	actor.add_child(body)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	head.mesh = head_mesh
	head.position.y = 1.82
	head.material_override = skin
	actor.add_child(head)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.name = "Arm_%s" % ("L" if side < 0.0 else "R")
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.12
		arm_mesh.height = 0.78
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.43, 1.02, 0.0)
		arm.rotation.z = side * -0.12
		arm.material_override = clothing
		actor.add_child(arm)
		var leg := MeshInstance3D.new()
		leg.name = "Leg_%s" % ("L" if side < 0.0 else "R")
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.15
		leg_mesh.height = 0.82
		leg.mesh = leg_mesh
		leg.position = Vector3(side * 0.17, 0.32, 0.0)
		leg.material_override = clothing
		actor.add_child(leg)
	actor.set_meta("system_npc_visual_part_count", actor.get_child_count())
	return actor

func _build_arena_floor_layouts() -> void:
	var arena_root := Node3D.new()
	arena_root.name = "PowerTowerProgressiveArenaFloors"
	arena_root.set_meta("system_arena_floor_count", FLOOR_COUNT)
	arena_root.set_meta("system_arena_floor_height", 4.1)
	arena_root.set_meta("system_arena_progression", ARENA_BANDS)
	add_child(arena_root)
	_build_arena_tier_wayfinding(arena_root)

	var total_arenas := 0
	for floor_number in range(1, FLOOR_COUNT + 1):
		total_arenas += get_arena_count_for_floor(floor_number)
	var floor_multi := MultiMesh.new()
	floor_multi.transform_format = MultiMesh.TRANSFORM_3D
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(9.0, 0.22, 9.0)
	floor_multi.mesh = floor_box
	floor_multi.instance_count = total_arenas
	var rail_multi := MultiMesh.new()
	rail_multi.transform_format = MultiMesh.TRANSFORM_3D
	var rail_box := BoxMesh.new()
	rail_box.size = Vector3(9.0, 1.35, 0.18)
	rail_multi.mesh = rail_box
	rail_multi.instance_count = total_arenas * 4
	var ring_multi := MultiMesh.new()
	ring_multi.transform_format = MultiMesh.TRANSFORM_3D
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 3.45
	ring_mesh.outer_radius = 3.7
	ring_mesh.rings = 48
	ring_mesh.ring_segments = 12
	ring_multi.mesh = ring_mesh
	ring_multi.instance_count = total_arenas
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.035, 0.12, 0.17)
	floor_material.metallic = 0.68
	floor_material.roughness = 0.28
	floor_material.emission_enabled = true
	floor_material.emission = Color(0.02, 0.22, 0.28)
	floor_material.emission_energy_multiplier = 0.35
	var rail_material := StandardMaterial3D.new()
	rail_material.albedo_color = Color(0.42, 0.68, 0.72)
	rail_material.metallic = 0.82
	rail_material.roughness = 0.2
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.12, 0.72, 0.88)
	ring_material.metallic = 0.58
	ring_material.roughness = 0.22
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.035, 0.42, 0.62)
	ring_material.emission_energy_multiplier = 0.8
	var floor_index := 0
	var rail_index := 0
	var ring_index := 0
	var collision_faces := PackedVector3Array()
	for floor_number in range(1, FLOOR_COUNT + 1):
		var arena_count := get_arena_count_for_floor(floor_number)
		var columns := 1
		match arena_count:
			8: columns = 4
			6: columns = 3
			4: columns = 2
			3: columns = 3
			2: columns = 2
			_: columns = 1
		var rows := int(ceil(float(arena_count) / float(columns)))
		var floor_y := float(floor_number - 1) * 4.1 + 2.05
		for arena_index in range(arena_count):
			var column := arena_index % columns
			var row := int(arena_index / columns)
			var x := (float(column) - float(columns - 1) * 0.5) * 12.0
			var z := (float(row) - float(rows - 1) * 0.5) * 12.0
			var center := Vector3(x, floor_y, z)
			floor_multi.set_instance_transform(floor_index, Transform3D(Basis.IDENTITY, center))
			floor_index += 1
			ring_multi.set_instance_transform(ring_index, Transform3D(Basis.IDENTITY, center + Vector3(0.0, 0.14, 0.0)))
			ring_index += 1
			var edge_y := floor_y + 0.78
			var edge_positions := [
				{"position": center + Vector3(0.0, 0.0, -4.4), "rotation": 0.0},
				{"position": center + Vector3(0.0, 0.0, 4.4), "rotation": 0.0},
				{"position": center + Vector3(-4.4, 0.0, 0.0), "rotation": PI * 0.5},
				{"position": center + Vector3(4.4, 0.0, 0.0), "rotation": PI * 0.5}
			]
			for edge in edge_positions:
				var edge_position: Vector3 = edge["position"]
				edge_position.y = edge_y
				var edge_basis := Basis(Vector3.UP, float(edge["rotation"]))
				rail_multi.set_instance_transform(rail_index, Transform3D(edge_basis, edge_position))
				rail_index += 1
			var half := 4.5
			var a := Vector3(x - half, floor_y + 0.12, z - half)
			var b := Vector3(x + half, floor_y + 0.12, z - half)
			var d := Vector3(x - half, floor_y + 0.12, z + half)
			var e := Vector3(x + half, floor_y + 0.12, z + half)
			collision_faces.append(a)
			collision_faces.append(b)
			collision_faces.append(e)
			collision_faces.append(a)
			collision_faces.append(e)
			collision_faces.append(d)
	var floors_instance := MultiMeshInstance3D.new()
	floors_instance.name = "ArenaFloorSurfaces560"
	floors_instance.multimesh = floor_multi
	floors_instance.material_override = floor_material
	arena_root.add_child(floors_instance)
	var rings_instance := MultiMeshInstance3D.new()
	rings_instance.name = "ArenaCombatRingOutlines560"
	rings_instance.multimesh = ring_multi
	rings_instance.material_override = ring_material
	arena_root.add_child(rings_instance)
	var rails_instance := MultiMeshInstance3D.new()
	rails_instance.name = "ArenaSafetyRails2240"
	rails_instance.multimesh = rail_multi
	rails_instance.material_override = rail_material
	arena_root.add_child(rails_instance)
	var collision_body := StaticBody3D.new()
	collision_body.name = "ArenaFloorCollision"
	var collision_shape := CollisionShape3D.new()
	var concave_shape := ConcavePolygonShape3D.new()
	concave_shape.set_faces(collision_faces)
	collision_shape.shape = concave_shape
	collision_body.add_child(collision_shape)
	arena_root.add_child(collision_body)
	arena_root.set_meta("system_arena_instance_count", total_arenas)
	arena_root.set_meta("system_arena_combat_ring_outline_count", ring_index)
	arena_root.set_meta("system_arena_boundary_rail_count", total_arenas * 4)
	arena_root.set_meta("system_arena_collision_triangle_count", collision_faces.size() / 3)



func _build_arena_tier_wayfinding(arena_root: Node3D) -> void:
	# A small, readable identity marker is placed at each progression transition.
	var tiers := [
		{"floor": 1, "last": 20, "name": "ROOKIE ARENAS", "color": Color(0.42, 0.82, 1.0)},
		{"floor": 21, "last": 40, "name": "ADVANCED ARENAS", "color": Color(0.42, 1.0, 0.78)},
		{"floor": 41, "last": 60, "name": "ELITE ARENAS", "color": Color(1.0, 0.82, 0.42)},
		{"floor": 61, "last": 80, "name": "MASTER ARENAS", "color": Color(1.0, 0.58, 0.38)},
		{"floor": 81, "last": 100, "name": "NEN ARENAS", "color": Color(0.52, 0.78, 1.0)},
		{"floor": 101, "last": 150, "name": "HIGH-RANK ARENAS", "color": Color(0.78, 0.62, 1.0)},
		{"floor": 151, "last": 200, "name": "SOVEREIGN ARENAS", "color": Color(1.0, 0.72, 0.42)}
	]
	for tier in tiers:
		var floor_number := int(tier["floor"])
		var marker := Node3D.new()
		marker.name = "ArenaTierMarker_%03d" % floor_number
		marker.position = Vector3(0.0, float(floor_number - 1) * 4.1 + 3.2, -17.0)
		marker.set_meta("system_arena_tier_first_floor", floor_number)
		marker.set_meta("system_arena_tier_last_floor", int(tier["last"]))
		marker.set_meta("system_arena_match_format", "PLAYER_ONLY_1V1")
		arena_root.add_child(marker)

		var backplate := MeshInstance3D.new()
		backplate.name = "TierSignBackplate"
		var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(10.0, 2.4, 0.28)
		backplate.mesh = plate_mesh
		var plate_material := StandardMaterial3D.new()
		plate_material.albedo_color = Color(0.018, 0.045, 0.065)
		plate_material.metallic = 0.72
		plate_material.roughness = 0.24
		backplate.material_override = plate_material
		marker.add_child(backplate)

		var label := Label3D.new()
		label.name = "ArenaTierSignText"
		label.text = "FLOORS %03d–%03d  |  %s" % [floor_number, int(tier["last"]), str(tier["name"])]
		label.font_size = 28
		label.pixel_size = 0.012
		label.position = Vector3(0.0, -0.2, 0.2)
		label.modulate = tier["color"]
		label.outline_size = 8
		marker.add_child(label)

		var light := OmniLight3D.new()
		light.name = "ArenaTierAccentLight"
		light.position = Vector3(0.0, 1.8, 0.8)
		light.light_color = tier["color"]
		light.light_energy = 0.8
		light.omni_range = 12.0
		light.shadow_enabled = false
		marker.add_child(light)
	arena_root.set_meta("system_arena_tier_marker_count", tiers.size())
	arena_root.set_meta("system_arena_match_format", "PLAYER_ONLY_1V1")
	arena_root.set_meta("system_arena_progression_signage", true)

func _build_restaurant_and_recreation_amenities() -> void:
	var tower_root := get_parent().get_parent() if get_parent() != null else null
	var lobby := tower_root.get_node_or_null("PublicLobby_Blockout") if tower_root != null else null
	if lobby == null:
		return
	var amenities := Node3D.new()
	amenities.name = "PowerTowerRestaurantAndRecreation"
	amenities.set_meta("system_power_tower_facilities", ["RESTAURANT", "CAFETERIA", "RECREATION_LOUNGE", "ENTERTAINMENT_ZONE"])
	lobby.add_child(amenities)
	_add_amenity(amenities, "PowerTowerRestaurant", "X-S-X RESTAURANT", Vector3(-12.0, 0.0, 22.0), Color(0.62, 0.31, 0.12))
	_add_amenity(amenities, "PowerTowerRecreationLounge", "RECREATION & REST", Vector3(12.0, 0.0, 22.0), Color(0.18, 0.42, 0.5))
	_add_amenity(amenities, "PowerTowerEntertainmentZone", "ENTERTAINMENT ZONE", Vector3(0.0, 0.0, -35.0), Color(0.35, 0.2, 0.52))
	set_meta("system_power_tower_amenity_count", 3)

func _add_amenity(parent: Node3D, node_name: String, sign_text: String, location: Vector3, color: Color) -> void:
	var room := Node3D.new()
	room.name = node_name
	room.position = location
	room.set_meta("system_facility_type", node_name.to_snake_case())
	parent.add_child(room)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "FacilityFloor"
	var floor := BoxMesh.new()
	floor.size = Vector3(16.0, 0.35, 12.0)
	floor_mesh.mesh = floor
	floor_mesh.position.y = 0.18
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.42
	material.roughness = 0.32
	floor_mesh.material_override = material
	room.add_child(floor_mesh)
	var sign := Label3D.new()
	sign.name = "FacilitySign"
	sign.text = sign_text
	sign.font_size = 24
	sign.position = Vector3(0.0, 4.0, 0.0)
	room.add_child(sign)
	for index in range(4):
		var seat := MeshInstance3D.new()
		seat.name = "VisitorSeat_%02d" % index
		var seat_mesh := BoxMesh.new()
		seat_mesh.size = Vector3(1.2, 0.8, 1.2)
		seat.mesh = seat_mesh
		seat.position = Vector3(-6.0 + float(index) * 4.0, 0.7, 3.0)
		seat.material_override = material
		room.add_child(seat)
