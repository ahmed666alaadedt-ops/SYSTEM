
extends Node

signal sovereign_claimed(player: Node)
signal sovereign_ability_used(ability_id: String, world_id: int)
signal sovereign_world_authority_changed(world_id: int)

const CREATOR_ID := "SYSTEM_CREATOR"
const WORLD_IDS := [0, 1, 2, 3]

const ABILITIES := {
	"sovereign_aura": "الهالة الملكية",
	"sovereign_flight": "الطيران الأسطوري",
	"world_travel": "الانتقال بين العوالم",
	"absolute_authority": "السلطة الملكية العليا"
}

var sovereign_player: Node3D
var sovereign_identity := CREATOR_ID
var current_world_id := 2
var claimed := false
var flight_enabled := false
var aura_enabled := false


func _process(_delta: float) -> void:
	if claimed and is_instance_valid(sovereign_player):
		return

	var candidate := get_tree().root.find_child("Player", true, false)
	if candidate is Node3D:
		claim_sovereignty(candidate, CREATOR_ID)


func claim_sovereignty(player: Node3D, identity: String) -> bool:
	if player == null or identity != CREATOR_ID:
		return false

	if claimed and is_instance_valid(sovereign_player) and sovereign_player != player:
		return false

	sovereign_player = player
	sovereign_identity = identity
	claimed = true

	player.set_meta("system_sovereign", true)
	player.set_meta("system_sovereign_identity", CREATOR_ID)
	player.set_meta("system_absolute_protection", true)
	player.set_meta("system_world_king", true)

	sovereign_claimed.emit(player)
	print("SYSTEM: Sovereign identity activated.")
	return true


func is_sovereign(player: Node = null) -> bool:
	if not claimed or not is_instance_valid(sovereign_player):
		return false

	if player == null:
		return true

	return player == sovereign_player and player.get_meta("system_sovereign", false)


func get_sovereign_title() -> String:
	return "ملك جزيرة الطمع والملك الأعلى للعوالم الأربعة"


func get_kingdom_world_ids() -> Array:
	return WORLD_IDS.duplicate()


func get_abilities() -> Dictionary:
	return ABILITIES.duplicate(true)


func set_active_world(world_id: int) -> bool:
	if not is_sovereign() or not WORLD_IDS.has(world_id):
		return false

	current_world_id = world_id
	sovereign_world_authority_changed.emit(world_id)
	return true


func use_ability(ability_id: String) -> Dictionary:
	if not is_sovereign():
		return {"success": false, "reason": "SOVEREIGN_ONLY"}

	if not ABILITIES.has(ability_id):
		return {"success": false, "reason": "UNKNOWN_ABILITY"}

	match ability_id:
		"sovereign_aura":
			aura_enabled = not aura_enabled
			sovereign_player.set_meta("system_sovereign_aura", aura_enabled)

		"sovereign_flight":
			flight_enabled = not flight_enabled
			sovereign_player.set_meta("system_sovereign_flight", flight_enabled)

			if flight_enabled and sovereign_player is CharacterBody3D:
				(sovereign_player as CharacterBody3D).velocity.y = 8.0

		"world_travel":
			return {
				"success": true,
				"ability": ability_id,
				"world_ids": get_kingdom_world_ids(),
				"note": "طلب انتقال ملكي إلى أحد العوالم."
			}

		"absolute_authority":
			sovereign_player.set_meta("system_absolute_authority", true)

	sovereign_ability_used.emit(ability_id, current_world_id)

	return {
		"success": true,
		"ability": ability_id,
		"name": ABILITIES[ability_id],
		"world_id": current_world_id
	}


func apply_flight_motion(vertical_input: float, speed: float = 8.0) -> bool:
	if not is_sovereign() or not flight_enabled:
		return false

	if sovereign_player is CharacterBody3D:
		var body := sovereign_player as CharacterBody3D
		body.velocity.y = clampf(vertical_input, -1.0, 1.0) * speed
		return true

	return false


func get_authority_status() -> Dictionary:
	return {
		"claimed": is_sovereign(),
		"identity": sovereign_identity if claimed else "",
		"title": get_sovereign_title(),
		"world_ids": get_kingdom_world_ids(),
		"active_world_id": current_world_id,
		"exclusive": true,
		"abilities": get_abilities()
	}
