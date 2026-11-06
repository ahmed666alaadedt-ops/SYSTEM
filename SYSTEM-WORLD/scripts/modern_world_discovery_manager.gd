
extends Node3D
class_name ModernWorldDiscoveryManager

## نظام اكتشاف مناطق العالم الحديث.
## يسجل المناطق عند تفاعل اللاعب معها.
## لا يفتح السفر السريع تلقائياً.

const DISCOVERY_POINTS: Array[Dictionary] = [
	{
		"id": "modern_city_center",
		"region": "modern_city_center",
		"name": "مركز المدينة",
		"position": Vector3(0.0, 0.0, -12.0)
	},
	{
		"id": "modern_west_district",
		"region": "modern_west_district",
		"name": "المنطقة الغربية",
		"position": Vector3(-5.0, 0.0, -32.0)
	},
	{
		"id": "modern_east_district",
		"region": "modern_east_district",
		"name": "المنطقة الشرقية",
		"position": Vector3(5.0, 0.0, -52.0)
	},
	{
		"id": "modern_commercial_district",
		"region": "modern_commercial_district",
		"name": "المنطقة التجارية",
		"position": Vector3(-5.0, 0.0, -75.0)
	},
	{
		"id": "modern_southern_district",
		"region": "modern_southern_district",
		"name": "المنطقة الجنوبية",
		"position": Vector3(5.0, 0.0, -100.0)
	}
]


func _ready() -> void:
	_create_discovery_points()


func _create_discovery_points() -> void:
	for point_data in DISCOVERY_POINTS:
		_create_discovery_point(point_data)


func _create_discovery_point(data: Dictionary) -> void:
	var point := Area3D.new()

	point.name = "Discovery_" + str(data["id"])
	point.position = data["position"]

	point.collision_layer = 1
	point.collision_mask = 1
	point.monitoring = true
	point.monitorable = true

	point.set_meta("system_location_id", str(data["id"]))
	point.set_meta("system_region_id", str(data["region"]))
	point.set_meta("system_display_name", str(data["name"]))
	point.set_meta("system_location_type", 7)
	point.set_meta(
		"system_interaction_prompt",
		"اكتشاف " + str(data["name"])
	)
	point.set_meta("system_fast_travel", false)

	point.add_to_group("system_interactable")

	var collision := CollisionShape3D.new()
	collision.name = "DiscoveryCollision"

	var shape := SphereShape3D.new()
	shape.radius = 2.0

	collision.shape = shape
	collision.position = Vector3(0.0, 1.0, 0.0)

	point.add_child(collision)

	_create_visual_marker(point)

	add_child(point)


func _create_visual_marker(parent: Node3D) -> void:
	var material := StandardMaterial3D.new()

	material.albedo_color = Color(0.05, 0.75, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.02, 0.55, 1.0, 1.0)
	material.emission_energy_multiplier = 2.0

	var beacon := MeshInstance3D.new()
	beacon.name = "DiscoveryBeacon"

	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56

	beacon.mesh = mesh
	beacon.position = Vector3(0.0, 1.8, 0.0)
	beacon.material_override = material

	parent.add_child(beacon)


func get_discovery_point_count() -> int:
	return DISCOVERY_POINTS.size()
