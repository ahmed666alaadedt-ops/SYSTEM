extends Node
class_name SystemPlayerVehicleManager

signal wallet_changed(balance: int)
signal garage_changed(vehicles: Array)

const SAVE_PATH := "user://system_vehicle_garage.cfg"
const STARTING_CURRENCY := 25000
const RESALE_RATE := 0.60

var balance: int = STARTING_CURRENCY
var owned_vehicles: Array[String] = []
var active_vehicle_id := ""
var vehicle_colors: Dictionary = {}
var catalog_script = preload("res://scripts/system_vehicle_catalog.gd")

func _ready() -> void:
	load_garage()

func get_balance() -> int:
	return balance

func get_vehicle_color(vehicle_id: String) -> Color:
	return Color.from_string(str(vehicle_colors.get(vehicle_id, "#1479C8")), Color(0.08, 0.28, 0.48))

func set_vehicle_color(vehicle_id: String, color: Color) -> void:
	if catalog_script.get_vehicle(vehicle_id).is_empty():
		return
	vehicle_colors[vehicle_id] = color.to_html(false)
	save_garage()
	garage_changed.emit(get_garage())

func get_garage() -> Array[String]:
	return owned_vehicles.duplicate()

func credit_currency(amount: int, reason: String = "system_reward") -> Dictionary:
	if amount <= 0:
		return {"success":false,"reason":"INVALID_AMOUNT"}
	balance += amount
	save_garage()
	wallet_changed.emit(balance)
	return {"success":true,"credited":amount,"balance":balance,"reason":reason,"economy_mode":"local_prototype"}


func spend_currency(amount: int, reason: String = "system_purchase") -> Dictionary:
	if amount <= 0:
		return {"success":false,"reason":"INVALID_AMOUNT"}
	if balance < amount:
		return {"success":false,"reason":"INSUFFICIENT_CURRENCY","required":amount,"balance":balance}
	balance -= amount
	save_garage()
	wallet_changed.emit(balance)
	return {"success":true,"spent":amount,"balance":balance,"reason":reason,"economy_mode":"local_prototype"}


func award_race_reward(amount: int) -> Dictionary:
	return credit_currency(amount, "motorsport_race_reward")


func purchase_vehicle(vehicle_id: String) -> Dictionary:
	var vehicle: Dictionary = catalog_script.get_vehicle(vehicle_id)
	if vehicle.is_empty() or int(vehicle.get("price", 0)) <= 0:
		return {"success":false,"reason":"VEHICLE_NOT_FOR_SALE"}
	if owned_vehicles.has(vehicle_id):
		return {"success":false,"reason":"ALREADY_OWNED"}
	var price := int(vehicle["price"])
	if balance < price:
		return {"success":false,"reason":"INSUFFICIENT_CURRENCY","required":price,"balance":balance}
	balance -= price
	owned_vehicles.append(vehicle_id)
	save_garage()
	wallet_changed.emit(balance)
	garage_changed.emit(get_garage())
	return {"success":true,"vehicle_id":vehicle_id,"paid":price,"balance":balance}

func sell_vehicle(vehicle_id: String) -> Dictionary:
	if not owned_vehicles.has(vehicle_id):
		return {"success":false,"reason":"NOT_OWNED"}
	if vehicle_id == active_vehicle_id:
		return {"success":false,"reason":"RETURN_VEHICLE_TO_GARAGE_FIRST"}
	var vehicle: Dictionary = catalog_script.get_vehicle(vehicle_id)
	var resale := int(floor(float(vehicle.get("price", 0)) * RESALE_RATE))
	if resale <= 0:
		return {"success":false,"reason":"VEHICLE_NOT_RESELLABLE"}
	owned_vehicles.erase(vehicle_id)
	balance += resale
	save_garage()
	wallet_changed.emit(balance)
	garage_changed.emit(get_garage())
	return {"success":true,"vehicle_id":vehicle_id,"received":resale,"balance":balance}

func set_active_vehicle(vehicle_id: String) -> Dictionary:
	if not owned_vehicles.has(vehicle_id):
		return {"success":false,"reason":"NOT_OWNED"}
	active_vehicle_id = vehicle_id
	save_garage()
	return {"success":true,"vehicle_id":vehicle_id}

func clear_active_vehicle() -> void:
	active_vehicle_id = ""
	save_garage()

func save_garage() -> void:
	var config := ConfigFile.new()
	config.set_value("wallet","balance",balance)
	config.set_value("garage","owned",owned_vehicles)
	config.set_value("garage","active_vehicle_id",active_vehicle_id)
	config.set_value("garage","vehicle_colors",vehicle_colors)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM Vehicles: local garage save failed.")

func load_garage() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		save_garage()
		return
	balance = maxi(0,int(config.get_value("wallet","balance",STARTING_CURRENCY)))
	owned_vehicles.clear()
	for value in config.get_value("garage","owned",[]):
		var vehicle_id := str(value)
		if catalog_script.get_vehicle(vehicle_id).is_empty() or owned_vehicles.has(vehicle_id):
			continue
		owned_vehicles.append(vehicle_id)
	vehicle_colors = config.get_value("garage","vehicle_colors",{})
	if not vehicle_colors is Dictionary:
		vehicle_colors = {}
	active_vehicle_id = str(config.get_value("garage","active_vehicle_id",""))
	if not owned_vehicles.has(active_vehicle_id):
		active_vehicle_id = ""

func get_economy_status() -> Dictionary:
	return {"balance":balance,"owned_vehicles":get_garage(),"active_vehicle_id":active_vehicle_id,"save_mode":"local_prototype"}
