extends Node3D
class_name SYSTEMNPCThreatReceiver

## Non-damaging hit receiver for civilian NPCs.
## It routes weapon hits into a defensive response; NPCs have no health pool here.

const RESPONSE_COOLDOWN_MSEC := 1200

var npc_id := ""
var population_manager: Node
var last_response_msec := -10000


func receive_threat(attacker: Node = null) -> bool:
	if npc_id.is_empty() or not is_instance_valid(population_manager):
		return false
	if not population_manager.has_method("notify_npc_attacked"):
		return false

	var now := Time.get_ticks_msec()
	if now - last_response_msec < RESPONSE_COOLDOWN_MSEC:
		return false

	var attacker_position := global_position - global_basis.z
	if attacker is Node3D:
		attacker_position = (attacker as Node3D).global_position

	var handled := bool(population_manager.call(
		"notify_npc_attacked",
		npc_id,
		attacker_position
	))
	if handled:
		last_response_msec = now
	return handled
