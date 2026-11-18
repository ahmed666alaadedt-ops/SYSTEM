extends Area3D
class_name SystemNPCVehicle

var vehicle_id := ""
var owner_npc_id := ""
var owner_name := ""
var city_name := ""
var crime_manager: Node

func configure(p_vehicle_id: String, p_owner_id: String, p_owner_name: String, p_city: String, p_manager: Node) -> void:
	vehicle_id = p_vehicle_id
	owner_npc_id = p_owner_id
	owner_name = p_owner_name
	city_name = p_city
	crime_manager = p_manager
	name = "NPCVehicle_" + vehicle_id
	add_to_group("system_interactable")
	set_meta("system_interaction_prompt", "سيارة مدنية — تفاعل")
	set_meta("system_vehicle_id", vehicle_id)

func system_interact() -> void:
	if is_instance_valid(crime_manager):
		crime_manager.call("attempt_vehicle_theft", vehicle_id)

func set_stolen_visual() -> void:
	set_meta("system_interaction_prompt", "سيارة مسروقة — الشرطة قد تلاحقك")
