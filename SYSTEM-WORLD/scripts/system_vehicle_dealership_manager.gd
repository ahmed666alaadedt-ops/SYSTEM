extends Node3D
class_name SystemVehicleDealershipManager

const VehicleCatalogScript = preload("res://scripts/system_vehicle_catalog.gd")
var vehicle_manager: SystemPlayerVehicleManager

func setup(manager: SystemPlayerVehicleManager) -> void:
	vehicle_manager = manager
	_build_showroom_markers()

func get_available_stock() -> Dictionary:
	return VehicleCatalogScript.get_catalog()

func buy(vehicle_id: String) -> Dictionary:
	if vehicle_manager == null:
		return {"success":false,"reason":"GARAGE_NOT_READY"}
	return vehicle_manager.purchase_vehicle(vehicle_id)

func sell(vehicle_id: String) -> Dictionary:
	if vehicle_manager == null:
		return {"success":false,"reason":"GARAGE_NOT_READY"}
	return vehicle_manager.sell_vehicle(vehicle_id)

func _build_showroom_markers() -> void:
	var showroom := Node3D.new()
	showroom.name = "VehicleShowroomVisual"
	add_child(showroom)
	var floor_mesh := MeshInstance3D.new()
	var floor := BoxMesh.new()
	floor.size = Vector3(34.0,0.35,22.0)
	floor_mesh.mesh = floor
	floor_mesh.position.y = 0.18
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.12,0.16,0.20)
	floor_material.metallic = 0.45
	floor_mesh.material_override = floor_material
	showroom.add_child(floor_mesh)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(18.0,2.2,0.35)
	sign.mesh = sign_mesh
	sign.position = Vector3(0.0,5.0,-10.0)
	var sign_material := StandardMaterial3D.new()
	sign_material.albedo_color = Color(0.04,0.45,0.58)
	sign_material.emission_enabled = true
	sign_material.emission = Color(0.02,0.32,0.48)
	sign_material.emission_energy_multiplier = 1.2
	sign.material_override = sign_material
	showroom.add_child(sign)
