extends RefCounted
class_name SystemVehicleCatalog

## Global vehicle-market direction:
## Brand references below are planning/catalog metadata only. They do not imply
## official manufacturer approval, licensed logos, or licensed 3D vehicle assets.
## Replace placeholders with licensed or original vehicles before public release.

const VEHICLES := {
	"city_sedan": {"name":"City Sedan","brand_reference":"Global mainstream","model_class":"Executive sedan","category":"sedan","price":18000,"max_speed":145,"seats":5,"licensing_status":"original_placeholder"},
	"sport_coupe": {"name":"Sport Coupe","brand_reference":"Global performance","model_class":"Performance coupe","category":"sports","price":52000,"max_speed":235,"seats":2,"licensing_status":"original_placeholder"},
	"electric_suv": {"name":"Electric SUV","brand_reference":"Global electric","model_class":"Electric performance SUV","category":"electric","price":68000,"max_speed":190,"seats":5,"licensing_status":"original_placeholder"},
	"city_taxi": {"name":"City Taxi","brand_reference":"Global fleet","model_class":"Urban taxi","category":"service","price":22000,"max_speed":135,"seats":5,"licensing_status":"original_placeholder"},
	"delivery_van": {"name":"Delivery Van","brand_reference":"Global commercial","model_class":"Delivery van","category":"commercial","price":31000,"max_speed":125,"seats":3,"licensing_status":"original_placeholder"},
	"city_bus": {"name":"City Bus","brand_reference":"Global commercial","model_class":"City bus","category":"commercial","price":95000,"max_speed":105,"seats":32,"licensing_status":"original_placeholder"},
	"utility_truck": {"name":"Utility Truck","brand_reference":"Global commercial","model_class":"Utility truck","category":"commercial","price":78000,"max_speed":115,"seats":3,"licensing_status":"original_placeholder"},
	"police_cruiser": {"name":"Police Cruiser","brand_reference":"SYSTEM emergency fleet","model_class":"Police patrol car","category":"service","price":0,"max_speed":190,"seats":5,"licensing_status":"original_placeholder"},
	"ambulance": {"name":"Ambulance","brand_reference":"SYSTEM emergency fleet","model_class":"Emergency ambulance","category":"service","price":0,"max_speed":155,"seats":4,"licensing_status":"original_placeholder"},
	"fire_engine": {"name":"Fire Engine","brand_reference":"SYSTEM emergency fleet","model_class":"Fire and rescue truck","category":"service","price":0,"max_speed":110,"seats":6,"licensing_status":"original_placeholder"},

	## Premium and global-market vehicle classes. Manufacturer references are
	## aspirational compatibility targets, not licensed products.
	"premium_executive": {"name":"Executive Luxury Sedan","brand_reference":"Mercedes-Benz / BMW / Audi class","model_class":"Luxury executive sedan","category":"premium","price":118000,"max_speed":255,"seats":5,"licensing_status":"unlicensed_placeholder"},
	"premium_grand_tourer": {"name":"Grand Touring Coupe","brand_reference":"Aston Martin / Bentley class","model_class":"Luxury grand tourer","category":"premium","price":165000,"max_speed":290,"seats":4,"licensing_status":"unlicensed_placeholder"},
	"performance_supercar": {"name":"Mid-Engine Supercar","brand_reference":"Ferrari / Lamborghini / McLaren class","model_class":"Mid-engine supercar","category":"supercar","price":320000,"max_speed":335,"seats":2,"licensing_status":"unlicensed_placeholder"},
	"electric_hyper_sedan": {"name":"Electric Hyper Sedan","brand_reference":"Tesla / Porsche / Lucid class","model_class":"High-performance electric sedan","category":"electric","price":210000,"max_speed":300,"seats":5,"licensing_status":"unlicensed_placeholder"},
	"offroad_4x4": {"name":"Desert Off-Roader","brand_reference":"Toyota / Land Rover / Jeep class","model_class":"Off-road 4x4","category":"offroad","price":88000,"max_speed":185,"seats":5,"licensing_status":"unlicensed_placeholder"},

	## Dedicated motorsport inventory: circuit, GT, formula, drift and rally.
	"gt3_race_car": {"name":"GT3 Circuit Racer","brand_reference":"Global GT racing class","model_class":"GT3 track car","category":"race_gt","price":480000,"max_speed":295,"seats":2,"licensing_status":"unlicensed_placeholder"},
	"formula_race_car": {"name":"Formula Single-Seater","brand_reference":"International formula racing class","model_class":"Open-wheel formula racer","category":"race_formula","price":950000,"max_speed":350,"seats":1,"licensing_status":"unlicensed_placeholder"},
	"endurance_prototype": {"name":"Endurance Prototype","brand_reference":"Global endurance racing class","model_class":"Le Mans-style prototype","category":"race_endurance","price":780000,"max_speed":335,"seats":2,"licensing_status":"unlicensed_placeholder"},
	"drift_competition": {"name":"Drift Competition Coupe","brand_reference":"Japanese and global drift scene","model_class":"Purpose-built drift car","category":"race_drift","price":185000,"max_speed":265,"seats":2,"licensing_status":"unlicensed_placeholder"},
	"rally_competition": {"name":"Rally Competition Car","brand_reference":"World rally competition class","model_class":"All-wheel-drive rally car","category":"race_rally","price":240000,"max_speed":225,"seats":2,"licensing_status":"unlicensed_placeholder"},
	"drag_competition": {"name":"Drag Strip Racer","brand_reference":"International drag racing class","model_class":"Quarter-mile drag car","category":"race_drag","price":390000,"max_speed":420,"seats":2,"licensing_status":"unlicensed_placeholder"},
	"track_hypercar": {"name":"Track Hypercar","brand_reference":"Bugatti / Koenigsegg class","model_class":"Track-focused hypercar","category":"race_hyper","price":1250000,"max_speed":390,"seats":2,"licensing_status":"unlicensed_placeholder"}
}

static func get_vehicle(vehicle_id: String) -> Dictionary:
	return VEHICLES.get(vehicle_id, {}).duplicate(true)

static func get_catalog() -> Dictionary:
	return VEHICLES.duplicate(true)

static func get_categories() -> Array[String]:
	return [
		"sedan", "sports", "premium", "supercar", "electric", "offroad",
		"commercial", "service", "race_gt", "race_formula",
		"race_endurance", "race_drift", "race_rally", "race_drag", "race_hyper"
	]

static func is_race_vehicle(vehicle_id: String) -> bool:
	var vehicle := get_vehicle(vehicle_id)
	return str(vehicle.get("category", "")).begins_with("race_")
