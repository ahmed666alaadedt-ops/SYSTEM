extends Area3D
class_name SystemTowerEntrance

var tower_id := ""
var display_title := ""

func configure(p_tower_id: String, p_title: String, region_id: String) -> void:
	tower_id = p_tower_id
	display_title = p_title
	add_to_group("system_interactable")
	set_meta("system_location_id", tower_id)
	set_meta("system_region_id", region_id)
	set_meta("system_display_name", display_title)
	set_meta("system_location_type", 5)
	set_meta("system_interaction_prompt", "التفاعل مع " + display_title)

func system_interact() -> void:
	print("SYSTEM WORLD tower entrance selected: ", tower_id, " / ", display_title)
