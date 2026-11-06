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

var sovereign_player: Node3D = null
var sovereign_identity := ""
var current_world_id := 2

var claimed := false
var flight_enabled := false
var aura_enabled := false

var world_manager: Node = null

# هذه النسخة نموذج محلي للتطوير وليست تحققاً أمنياً من حساب المالك.
var server_verified := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func connect_world_manager(manager: Node) -> void:
	world_manager = manager

	if world_manager != null:
		if world_manager.has_signal("world_changed"):
			var callback := Callable(self, "_on_world_changed")
			if not world_manager.world_changed.is_connected(callback):
				world_manager.world_changed.connect(callback)


# تستدعى صراحةً من main.gd بعد إنشاء اللاعب.
# لا توجد مطالبة تلقائية بالملكية من اسم Player.
func claim_local_creator(player: Node3D) -> bool:
	if player == null or not is_instance_valid(player):
		return false

	if claimed:
		if is_instance_valid(sovereign_player):
			return sovereign_player == player

	# وضع تطوير محلي فقط، وليس إثبات ملكية عبر Firebase.
	sovereign_player = player
	sovereign_identity = CREATOR_ID
	claimed = true
	server_verified = false

	player.set_meta("system_sovereign", true)
	player.set_meta("system_sovereign_identity", CREATOR_ID)
	player.set_meta("system_world_king", true)

	sovereign_claimed.emit(player)
	print("SYSTEM: Local creator session connected.")

	return true


func is_sovereign(player: Node = null) -> bool:
	if not claimed:
		return false

	if not is_instance_valid(sovereign_player):
		return false

	if player == null:
		return true

	return (
		player == sovereign_player
		and player.get_meta("system_sovereign", false)
	)


func get_sovereign_title() -> String:
	return "ملك جزيرة الطمع والملك الأعلى للعوالم الأربعة"


func get_kingdom_world_ids() -> Array:
	return WORLD_IDS.duplicate()


func get_abilities() -> Dictionary:
	return ABILITIES.duplicate(true)


func _on_world_changed(world_id: int) -> void:
	if not is_sovereign():
		return

	if not WORLD_IDS.has(world_id):
		return

	current_world_id = world_id
	sovereign_world_authority_changed.emit(world_id)


func set_active_world(world_id: int) -> bool:
	if not is_sovereign():
		return false

	if not WORLD_IDS.has(world_id):
		return false

	current_world_id = world_id
	sovereign_world_authority_changed.emit(world_id)
	return true


func travel_to_world(world_id: int) -> Dictionary:
	if not is_sovereign():
		return {
			"success": false,
			"reason": "SOVEREIGN_ONLY"
		}

	if not WORLD_IDS.has(world_id):
		return {
			"success": false,
			"reason": "UNKNOWN_WORLD"
		}

	if world_manager == null:
		return {
			"success": false,
			"reason": "WORLD_MANAGER_NOT_CONNECTED"
		}

	if not world_manager.has_method("switch_world"):
		return {
			"success": false,
			"reason": "WORLD_SWITCH_NOT_AVAILABLE"
		}

	world_manager.switch_world(world_id)
	current_world_id = world_id

	sovereign_world_authority_changed.emit(world_id)

	return {
		"success": true,
		"world_id": world_id,
		"world_name": world_manager.get_world_name(world_id)
	}


func use_ability(ability_id: String) -> Dictionary:
	if not is_sovereign():
		return {
			"success": false,
			"reason": "SOVEREIGN_ONLY"
		}

	if not ABILITIES.has(ability_id):
		return {
			"success": false,
			"reason": "UNKNOWN_ABILITY"
		}

	match ability_id:
		"sovereign_aura":
			aura_enabled = not aura_enabled
			sovereign_player.set_meta(
				"system_sovereign_aura",
				aura_enabled
			)

		"sovereign_flight":
			flight_enabled = not flight_enabled
			sovereign_player.set_meta(
				"system_sovereign_flight",
				flight_enabled
			)

		"world_travel":
			return {
				"success": false,
				"reason": "USE_TRAVEL_TO_WORLD"
			}

		"absolute_authority":
			return {
				"success": false,
				"reason": "AUTHORITY_SYSTEM_NOT_CONNECTED"
			}

	sovereign_ability_used.emit(
		ability_id,
		current_world_id
	)

	return {
		"success": true,
		"ability": ability_id,
		"name": ABILITIES[ability_id],
		"enabled": (
			aura_enabled
			if ability_id == "sovereign_aura"
			else flight_enabled
		),
		"world_id": current_world_id
	}


func apply_flight_motion(
	vertical_input: float,
	speed: float = 8.0
) -> bool:
	if not is_sovereign() or not flight_enabled:
		return false

	if not sovereign_player is CharacterBody3D:
		return false

	var body := sovereign_player as CharacterBody3D

	body.velocity.y = clampf(
		vertical_input,
		-1.0,
		1.0
	) * speed

	return true


func stop_flight() -> void:
	if not is_sovereign():
		return

	flight_enabled = false
	sovereign_player.set_meta(
		"system_sovereign_flight",
		false
	)


func get_authority_status() -> Dictionary:
	return {
		"claimed": is_sovereign(),
		"identity": sovereign_identity if claimed else "",
		"title": get_sovereign_title(),
		"world_ids": get_kingdom_world_ids(),
		"active_world_id": current_world_id,
		"exclusive": true,
		"server_verified": server_verified,
		"local_development_mode": true,
		"abilities": get_abilities()
	}
