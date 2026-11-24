extends CharacterBody3D
class_name SYSTEMHunterRivalActor

var rival_id := ""
var current_health := 100.0
var maximum_health := 100.0
var competition_manager: Node

func configure(profile: Dictionary, manager: Node) -> void:
	rival_id = str(profile.get("id", ""))
	maximum_health = maxf(1.0, float(profile.get("health", 100.0)))
	current_health = maximum_health
	competition_manager = manager
	set_meta("system_exam_rival_id", rival_id)
	set_meta("rival_health", current_health)
	set_meta("rival_max_health", maximum_health)

func take_damage(amount: float, source: Node = null) -> bool:
	if amount <= 0.0 or current_health <= 0.0:
		return false
	current_health = maxf(0.0, current_health - amount)
	set_meta("rival_health", current_health)
	if is_instance_valid(competition_manager) and competition_manager.has_method("_on_rival_damaged"):
		competition_manager.call("_on_rival_damaged", rival_id, amount, source)
	return true

func get_health_ratio() -> float:
	return current_health / maximum_health if maximum_health > 0.0 else 0.0
