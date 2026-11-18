extends RefCounted
class_name SystemVehicleCatalog

const VEHICLES := {
	"city_sedan": {"name":"City Sedan","category":"car","price":18000,"max_speed":145,"seats":5},
	"sport_coupe": {"name":"Sport Coupe","category":"car","price":52000,"max_speed":235,"seats":2},
	"electric_suv": {"name":"Electric SUV","category":"car","price":68000,"max_speed":190,"seats":5},
	"city_taxi": {"name":"City Taxi","category":"service","price":22000,"max_speed":135,"seats":5},
	"delivery_van": {"name":"Delivery Van","category":"commercial","price":31000,"max_speed":125,"seats":3},
	"city_bus": {"name":"City Bus","category":"commercial","price":95000,"max_speed":105,"seats":32},
	"utility_truck": {"name":"Utility Truck","category":"commercial","price":78000,"max_speed":115,"seats":3},
	"police_cruiser": {"name":"Police Cruiser","category":"service","price":0,"max_speed":190,"seats":5},
	"ambulance": {"name":"Ambulance","category":"service","price":0,"max_speed":155,"seats":4},
	"fire_engine": {"name":"Fire Engine","category":"service","price":0,"max_speed":110,"seats":6}
}

static func get_vehicle(vehicle_id: String) -> Dictionary:
	return VEHICLES.get(vehicle_id, {}).duplicate(true)

static func get_catalog() -> Dictionary:
	return VEHICLES.duplicate(true)
