
extends Node
class_name SystemWorldMapManager

## إدارة اكتشاف الخريطة ونقاط الانتقال والعلامات الشخصية.
## هذا الملف مستقل، ولا يغيّر سلوك الحركة الحالي حتى يتم ربطه في main.gd.

signal map_updated(world_id: String)
signal fast_travel_confirmed(world_id: String, point_id: String)
signal marker_added(world_id: String, marker_id: String)
signal marker_removed(world_id: String, marker_id: String)

enum LocationType {
	CITY,
	VILLAGE,
	HOSPITAL,
	CLINIC,
	SHOP,
	LANDMARK,
	FAST_TRAVEL_POINT,
	OTHER
}

const SAVE_PATH := "user://system_world_map_state.json"
const DEFAULT_ACTIVATION_DISTANCE := 3.0

# world_id -> location_id -> location data
var locations_by_world: Dictionary = {}

# world_id -> { region_id: true }
var discovered_regions: Dictionary = {}

# world_id -> { location_id: true }
var discovered_locations: Dictionary = {}

# world_id -> { location_id: true }
var activated_fast_travel_points: Dictionary = {}

# world_id -> Array[Dictionary]
# تُخزن إحداثيات العلامة كأرقام حتى يمكن حفظها في JSON.
var personal_markers: Dictionary = {}


func _ready() -> void:
	_load_state()


func register_location(
	world_id: String,
	location_id: String,
	region_id: String,
	display_name: String,
	location_type: int,
	position: Vector3,
	is_fast_travel_point: bool = false
) -> bool:
	if world_id.is_empty() or location_id.is_empty():
		return false
	if region_id.is_empty() or display_name.is_empty():
		return false
	if location_type < 0 or location_type >= LocationType.size():
		return false

	var world_locations := _get_bucket(locations_by_world, world_id)
	if world_locations.has(location_id):
		return false

	world_locations[location_id] = {
		"id": location_id,
		"world_id": world_id,
		"region_id": region_id,
		"name": display_name,
		"type": location_type,
		"position": position,
		"is_fast_travel_point": (
			is_fast_travel_point
			or location_type == LocationType.FAST_TRAVEL_POINT
		)
	}
	return true


func discover_region(world_id: String, region_id: String) -> bool:
	if world_id.is_empty() or region_id.is_empty():
		return false

	var regions := _get_bucket(discovered_regions, world_id)
	if regions.has(region_id):
		return false

	regions[region_id] = true
	map_updated.emit(world_id)
	_save_state()
	return true


func discover_location(world_id: String, location_id: String) -> bool:
	var location := _get_location_data(world_id, location_id)
	if location.is_empty():
		return false

	var regions := _get_bucket(discovered_regions, world_id)
	if not regions.has(location["region_id"]):
		return false

	var discovered := _get_bucket(discovered_locations, world_id)
	if discovered.has(location_id):
		return false

	discovered[location_id] = true
	map_updated.emit(world_id)
	_save_state()
	return true


## تُستدعى عند تفاعل اللاعب مع نقطة الانتقال وهو قريب منها.
## الوصول إلى المنطقة وحده لا يفعّل بقية نقاط الانتقال الموجودة فيها.
func activate_fast_travel_point(
	world_id: String,
	point_id: String,
	player_position: Vector3,
	activation_distance: float = DEFAULT_ACTIVATION_DISTANCE
) -> bool:
	var location := _get_location_data(world_id, point_id)
	if location.is_empty():
		return false
	if not bool(location["is_fast_travel_point"]):
		return false

	var point_position: Vector3 = location["position"]
	if player_position.distance_to(point_position) > maxf(activation_distance, 0.1):
		return false

	var regions := _get_bucket(discovered_regions, world_id)
	regions[location["region_id"]] = true

	var discovered := _get_bucket(discovered_locations, world_id)
	discovered[point_id] = true

	var activated := _get_bucket(activated_fast_travel_points, world_id)
	if activated.has(point_id):
		return false

	activated[point_id] = true
	map_updated.emit(world_id)
	_save_state()
	return true


func is_fast_travel_point_activated(world_id: String, point_id: String) -> bool:
	var activated := _get_bucket(activated_fast_travel_points, world_id)
	return activated.has(point_id)


## لا تنقل اللاعب بنفسها؛ تعيد وجهة صالحة بعد فحص القيود.
## على main.gd تنفيذ نقل اللاعب ثم استدعاء confirm_fast_travel().
func request_fast_travel(
	world_id: String,
	point_id: String,
	restrictions: Dictionary = {}
) -> Dictionary:
	if not is_fast_travel_point_activated(world_id, point_id):
		return {
			"success": false,
			"reason": "FAST_TRAVEL_POINT_NOT_ACTIVATED"
		}

	if bool(restrictions.get("in_combat", false)):
		return {"success": false, "reason": "PLAYER_IN_COMBAT"}
	if bool(restrictions.get("mission_blocks_fast_travel", false)):
		return {"success": false, "reason": "MISSION_RESTRICTION"}
	if bool(restrictions.get("dangerous_state", false)):
		return {"success": false, "reason": "DANGEROUS_STATE"}
	if bool(restrictions.get("custom_blocked", false)):
		return {"success": false, "reason": "TRAVEL_BLOCKED"}

	var location := _get_location_data(world_id, point_id)
	if location.is_empty():
		return {"success": false, "reason": "DESTINATION_NOT_FOUND"}

	var destination: Vector3 = location["position"]
	return {
		"success": true,
		"destination": destination + Vector3.UP * 1.2,
		"location_id": point_id,
		"location_name": location["name"]
	}


func confirm_fast_travel(world_id: String, point_id: String) -> void:
	if is_fast_travel_point_activated(world_id, point_id):
		fast_travel_confirmed.emit(world_id, point_id)


func add_personal_marker(
	world_id: String,
	marker_id: String,
	label: String,
	position: Vector3,
	note: String = ""
) -> bool:
	if world_id.is_empty() or marker_id.is_empty() or label.is_empty():
		return false

	var markers: Array = personal_markers.get(world_id, [])
	for marker in markers:
		if str(marker.get("id", "")) == marker_id:
			return false

	markers.append({
		"id": marker_id,
		"label": label,
		"note": note,
		"position": [position.x, position.y, position.z]
	})
	personal_markers[world_id] = markers

	marker_added.emit(world_id, marker_id)
	map_updated.emit(world_id)
	_save_state()
	return true


func remove_personal_marker(world_id: String, marker_id: String) -> bool:
	var markers: Array = personal_markers.get(world_id, [])
	for index in range(markers.size()):
		if str(markers[index].get("id", "")) == marker_id:
			markers.remove_at(index)
			personal_markers[world_id] = markers
			marker_removed.emit(world_id, marker_id)
			map_updated.emit(world_id)
			_save_state()
			return true
	return false


func get_personal_markers(world_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var markers: Array = personal_markers.get(world_id, [])

	for marker in markers:
		if typeof(marker) != TYPE_DICTIONARY:
			continue
		var position_data: Array = marker.get("position", [])
		if position_data.size() != 3:
			continue

		result.append({
			"id": str(marker.get("id", "")),
			"label": str(marker.get("label", "")),
			"note": str(marker.get("note", "")),
			"position": Vector3(
				float(position_data[0]),
				float(position_data[1]),
				float(position_data[2])
			)
		})
	return result


func get_discovered_locations(world_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var discovered: Dictionary = _get_bucket(discovered_locations, world_id)
	var activated: Dictionary = _get_bucket(activated_fast_travel_points, world_id)
	var world_locations: Dictionary = _get_bucket(locations_by_world, world_id)

	for location_id in discovered.keys():
		if not world_locations.has(location_id):
			continue
		var item: Dictionary = world_locations[location_id].duplicate(true)
		item["is_discovered"] = true
		item["is_fast_travel_activated"] = activated.has(location_id)
		result.append(item)

	return result


func get_map_snapshot(world_id: String) -> Dictionary:
	var regions: Dictionary = _get_bucket(discovered_regions, world_id)
	var activated: Dictionary = _get_bucket(activated_fast_travel_points, world_id)

	return {
		"world_id": world_id,
		"discovered_regions": regions.keys(),
		"discovered_locations": get_discovered_locations(world_id),
		"activated_fast_travel_points": activated.keys(),
		"personal_markers": get_personal_markers(world_id)
	}


func _get_location_data(world_id: String, location_id: String) -> Dictionary:
	var world_locations: Dictionary = _get_bucket(locations_by_world, world_id)
	if not world_locations.has(location_id):
		return {}
	return world_locations[location_id]


func _get_bucket(source: Dictionary, world_id: String) -> Dictionary:
	if not source.has(world_id) or typeof(source[world_id]) != TYPE_DICTIONARY:
		source[world_id] = {}
	return source[world_id]


func _save_state() -> void:
	var state := {
		"discovered_regions": discovered_regions,
		"discovered_locations": discovered_locations,
		"activated_fast_travel_points": activated_fast_travel_points,
		"personal_markers": personal_markers
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SYSTEM WORLD map state could not be saved.")
		return

	file.store_string(JSON.stringify(state))


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SYSTEM WORLD map state could not be loaded.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SYSTEM WORLD map save file is invalid.")
		return

	var state: Dictionary = parsed
	if typeof(state.get("discovered_regions", {})) == TYPE_DICTIONARY:
		discovered_regions = state["discovered_regions"]
	if typeof(state.get("discovered_locations", {})) == TYPE_DICTIONARY:
		discovered_locations = state["discovered_locations"]
	if typeof(state.get("activated_fast_travel_points", {})) == TYPE_DICTIONARY:
		activated_fast_travel_points = state["activated_fast_travel_points"]
	if typeof(state.get("personal_markers", {})) == TYPE_DICTIONARY:
		personal_markers = state["personal_markers"]
