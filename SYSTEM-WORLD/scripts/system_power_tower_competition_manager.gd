extends Node3D
class_name SYSTEMPowerTowerCompetitionManager

# Independent X-S-X Power Tower gameplay contract. Currency mutations must be
# delegated to the existing authoritative SYSTEM wallet/economy service.
const FLOOR_COUNT := 200
const SPECTATOR_NPC_TARGET := 500
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
	{"first": 1, "last": 20, "stage": "DISCOVERY", "label": "Nen Discovery"},
	{"first": 21, "last": 40, "stage": "AURA_AWARENESS", "label": "Aura Awareness"},
	{"first": 41, "last": 60, "stage": "TEN_CONTROL", "label": "Ten - Aura Control"},
	{"first": 61, "last": 80, "stage": "REN_OUTPUT", "label": "Ren - Aura Output"},
	{"first": 81, "last": 100, "stage": "HATSU_FOUNDATION", "label": "Hatsu Foundation"},
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
	var styles := COMBAT_STYLES.duplicate()
	if floor_number >= 101:
		styles = ["NEN_TECHNIQUES", "UNARMED_HAND_TO_HAND"]
	elif floor_number >= 81:
		styles.erase("BOW_AND_ARROW")
		styles.erase("TRADITIONAL_MELEE")
	return styles

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
	bodies.instance_count = SPECTATOR_NPC_TARGET
	for index in range(SPECTATOR_NPC_TARGET):
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
	heads.instance_count = SPECTATOR_NPC_TARGET
	for index in range(SPECTATOR_NPC_TARGET):
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

func _build_restaurant_and_recreation_amenities() -> void:
	var lobby := get_parent().get_node_or_null("PublicLobby_Blockout") if get_parent() != null else null
	if lobby == null:
		return
	var amenities := Node3D.new()
	amenities.name = "PowerTowerRestaurantAndRecreation"
	amenities.set_meta("system_power_tower_facilities", ["RESTAURANT", "CAFETERIA", "RECREATION_LOUNGE", "ENTERTAINMENT_ZONE"])
	lobby.add_child(amenities)
	_add_amenity(amenities, "PowerTowerRestaurant", "X-S-X RESTAURANT", Vector3(-30.0, 0.0, 82.0), Color(0.62, 0.31, 0.12))
	_add_amenity(amenities, "PowerTowerRecreationLounge", "RECREATION & REST", Vector3(30.0, 0.0, 82.0), Color(0.18, 0.42, 0.5))
	_add_amenity(amenities, "PowerTowerEntertainmentZone", "ENTERTAINMENT ZONE", Vector3(0.0, 0.0, 96.0), Color(0.35, 0.2, 0.52))
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
	floor.size = Vector3(22.0, 0.35, 15.0)
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
