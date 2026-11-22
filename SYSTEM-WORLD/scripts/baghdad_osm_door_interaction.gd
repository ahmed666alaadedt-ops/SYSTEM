extends Node3D
class_name BaghdadOSMDoorInteraction

## Source-verified Baghdad OSM door. The wall opening and collision are built
## by BaghdadOSMCellStreamer; this node owns the physical leaf and interaction.

var door_pivot: Node3D
var restricted := false
var door_open := false
var building_osm_id := ""
var entrance_osm_id := ""
var _door_tween: Tween


func configure(
	p_door_pivot: Node3D,
	p_restricted: bool,
	p_building_osm_id: String,
	p_entrance_osm_id: String
) -> void:
	door_pivot = p_door_pivot
	restricted = p_restricted
	building_osm_id = p_building_osm_id
	entrance_osm_id = p_entrance_osm_id
	door_open = false
	set_meta("system_door_open", false)
	set_meta("system_access_state", "restricted_no_public_entry" if restricted else "verified_door_closed")
	set_meta("system_interaction_prompt", "باب خاص — الدخول ممنوع" if restricted else "افتح الباب")


func system_interact() -> void:
	if restricted:
		print("SYSTEM Baghdad: public access denied at restricted OSM entrance ", entrance_osm_id)
		return
	if not is_instance_valid(door_pivot):
		push_warning("SYSTEM Baghdad: door pivot is unavailable for entrance " + entrance_osm_id)
		return
	door_open = not door_open
	set_meta("system_door_open", door_open)
	set_meta("system_access_state", "verified_door_open" if door_open else "verified_door_closed")
	set_meta("system_interaction_prompt", "أغلق الباب" if door_open else "افتح الباب")
	if _door_tween != null and _door_tween.is_running():
		_door_tween.kill()
	_door_tween = create_tween()
	_door_tween.set_trans(Tween.TRANS_SINE)
	_door_tween.set_ease(Tween.EASE_IN_OUT)
	var target_angle := -1.35 if door_open else 0.0
	_door_tween.tween_property(door_pivot, "rotation:y", target_angle, 0.42)
	print("SYSTEM Baghdad: door ", entrance_osm_id, " open=", door_open)


func is_publicly_accessible() -> bool:
	return not restricted
