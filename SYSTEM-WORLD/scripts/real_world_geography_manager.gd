extends Node
class_name SystemRealWorldGeographyManager

## WGS84 registry and regional metric projection for the real-world layer.
## Gameplay geometry must be generated from licensed, versioned regional data packs.

const REGISTRY_PATH := "res://data/geography/real_world_registry.json"
const DEFAULT_TILE_SIZE_METERS := 1000.0
const WGS84_SEMI_MAJOR := 6378137.0
const WGS84_INVERSE_FLATTENING := 298.257223563
const WGS84_FLATTENING := 1.0 / WGS84_INVERSE_FLATTENING
const WGS84_ECCENTRICITY_SQUARED := WGS84_FLATTENING * (2.0 - WGS84_FLATTENING)

var registry: Dictionary = {}
var origins_by_region: Dictionary = {}


func _ready() -> void:
	load_registry()


func load_registry() -> bool:
	if not FileAccess.file_exists(REGISTRY_PATH):
		push_warning("SYSTEM Geography: registry file is missing.")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
	if not parsed is Dictionary:
		push_warning("SYSTEM Geography: registry JSON is invalid.")
		return false
	registry = parsed
	origins_by_region.clear()
	var regions: Dictionary = registry.get("regions", {})
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		var origin: Dictionary = region.get("origin", {})
		if origin.has("latitude") and origin.has("longitude"):
			origins_by_region[str(region_id)] = {
				"latitude": float(origin["latitude"]),
				"longitude": float(origin["longitude"]),
				"altitude": float(origin.get("altitude_m", 0.0))
			}
	return true


func get_city(city_id: String) -> Dictionary:
	var cities: Dictionary = registry.get("cities", {})
	if not cities.has(city_id):
		return {}
	return cities[city_id].duplicate(true)


func get_region(region_id: String) -> Dictionary:
	var regions: Dictionary = registry.get("regions", {})
	if not regions.has(region_id):
		return {}
	return regions[region_id].duplicate(true)


func get_registry_version() -> String:
	return str(registry.get("version", "unknown"))


func geodetic_to_ecef(latitude: float, longitude: float, altitude_m: float = 0.0) -> Vector3:
	var lat := deg_to_rad(latitude)
	var lon := deg_to_rad(longitude)
	var sin_lat := sin(lat)
	var cos_lat := cos(lat)
	var normal_radius := WGS84_SEMI_MAJOR / sqrt(1.0 - WGS84_ECCENTRICITY_SQUARED * sin_lat * sin_lat)
	return Vector3(
		(normal_radius + altitude_m) * cos_lat * cos(lon),
		(normal_radius + altitude_m) * cos_lat * sin(lon),
		(normal_radius * (1.0 - WGS84_ECCENTRICITY_SQUARED) + altitude_m) * sin_lat
	)


## Godot local coordinates: east=X, up=Y, south=+Z.
## Use a regional origin and rebase it when streaming distant regions.
func to_local_world_position(region_id: String, latitude: float, longitude: float, altitude_m: float = 0.0) -> Vector3:
	if not origins_by_region.has(region_id):
		push_warning("SYSTEM Geography: unknown regional origin: " + region_id)
		return Vector3.ZERO
	var origin: Dictionary = origins_by_region[region_id]
	var origin_lat := deg_to_rad(float(origin["latitude"]))
	var origin_lon := deg_to_rad(float(origin["longitude"]))
	var origin_ecef := geodetic_to_ecef(float(origin["latitude"]), float(origin["longitude"]), float(origin["altitude"]))
	var point_ecef := geodetic_to_ecef(latitude, longitude, altitude_m)
	var delta := point_ecef - origin_ecef
	var east_axis := Vector3(-sin(origin_lon), cos(origin_lon), 0.0)
	var up_axis := Vector3(cos(origin_lat) * cos(origin_lon), cos(origin_lat) * sin(origin_lon), sin(origin_lat))
	var north_axis := Vector3(-sin(origin_lat) * cos(origin_lon), -sin(origin_lat) * sin(origin_lon), cos(origin_lat))
	return Vector3(delta.dot(east_axis), delta.dot(up_axis), -delta.dot(north_axis))


func get_tile_id(region_id: String, latitude: float, longitude: float, tile_size_meters: float = DEFAULT_TILE_SIZE_METERS) -> String:
	var tile_size := maxf(tile_size_meters, 100.0)
	var local_position := to_local_world_position(region_id, latitude, longitude)
	var tile_x := floori(local_position.x / tile_size)
	var tile_z := floori(local_position.z / tile_size)
	return "%s_%d_%d" % [region_id, tile_x, tile_z]


func get_city_world_position(city_id: String) -> Vector3:
	var city := get_city(city_id)
	if city.is_empty():
		return Vector3.ZERO
	return to_local_world_position(
		str(city.get("region_id", "")),
		float(city.get("latitude", 0.0)),
		float(city.get("longitude", 0.0)),
		float(city.get("elevation_m", 0.0))
	)



func get_city_landmarks(city_id: String) -> Dictionary:
	var city := get_city(city_id)
	var landmarks: Dictionary = city.get("landmarks", {})
	return landmarks.duplicate(true)


func get_landmark_world_position(city_id: String, landmark_id: String) -> Vector3:
	var landmarks := get_city_landmarks(city_id)
	if not landmarks.has(landmark_id):
		return Vector3.ZERO
	var landmark: Dictionary = landmarks[landmark_id]
	return to_local_world_position(
		str(get_city(city_id).get("region_id", "")),
		float(landmark.get("latitude", 0.0)),
		float(landmark.get("longitude", 0.0)),
		float(landmark.get("elevation_m", 0.0))
	)
