extends RefCounted
class_name SystemWorldData

# SYSTEM WORLD
# Central definition for the four independent worlds.
# Godot 4.3

const WORLD_DATA := {
	"modern": {
		"id": "modern",
		"title": "العالم الحديث",
		"subtitle": "عالم المدن والحياة الواقعية",
		"stage": "prototype",
		"scene_path": "res://scenes/main.tscn",
		"miyar_outfit": "future",
		"environment": "مدن حديثة، طرق، مبانٍ، طبيعة ومناطق واقعية",
		"combat": "أسلحة حديثة ومهارات شخصية مستوحاة من نظام Nen",
		"exploration": [
			"مدن ودول حقيقية",
			"مناطق ريفية",
			"بحار وجزر",
			"بوابات وأبراج تحديات",
			"مستشفيات ونقاط سفر"
		],
		"activities": [
			"النقابات",
			"المهام",
			"التجارة",
			"الوظائف",
			"المنازل والعقارات",
			"الغارات"
		]
	},

	"history": {
		"id": "history",
		"title": "العالم التاريخي",
		"subtitle": "الحضارات والإمبراطوريات القديمة",
		"stage": "prototype",
		"scene_path": "res://scenes/historical_world.tscn",
		"miyar_outfit": "historical",
		"environment": "مدن تاريخية ومعابد وقلاع وصحارى وأنهار",
		"combat": "سيوف ورماح وأقواس ودروع وأساليب قتال تاريخية",
		"civilizations": [
			"حضارة سومر",
			"حضارة بابل",
			"مصر القديمة",
			"الإسكندرية",
			"اليونان القديمة",
			"الصين القديمة"
		],
		"activities": [
			"النقابات",
			"المعارك التاريخية",
			"التجارة",
			"استكشاف الآثار",
			"الحصون والقلاع",
			"الغارات"
		]
	},

	"fantasy": {
		"id": "fantasy",
		"title": "العالم الخيالي",
		"subtitle": "الممالك والسحر والمخلوقات",
		"stage": "planned",
		"scene_path": "",
		"miyar_outfit": "magic",
		"environment": "ممالك خيالية وغابات عملاقة وجبال وقلاع",
		"combat": "السحر والأسلحة الأسطورية والقوى الخارقة",
		"races": [
			"البشر",
			"الإلف",
			"الأعراق الوحشية ذات الهيئة البشرية",
			"مجتمعات وممالك خيالية أخرى"
		],
		"creatures": [
			"التنانين",
			"الوحوش العملاقة",
			"المخلوقات السحرية",
			"المخلوقات الطائرة"
		],
		"activities": [
			"النقابات",
			"السحر",
			"استكشاف الممالك",
			"الغارات",
			"ترويض المخلوقات",
			"التجارة"
		]
	},

	"greed": {
		"id": "greed",
		"title": "جزيرة الطمع",
		"subtitle": "الجزيرة العائمة والتحديات النادرة",
		"stage": "planned",
		"scene_path": "",
		"miyar_outfit": "treasure",
		"environment": "جزيرة عائمة وقصر وأسواق وبوابات ومناطق غامضة",
		"combat": "وحوش وتحديات ومواجهات خاصة بالجزيرة",
		"features": [
			"قصر الجزيرة",
			"الخدم والشخصيات المستقلة",
			"الفنادق والمطاعم",
			"بوابات التحديات",
			"الكنوز النادرة",
			"الموسم المحدود"
		],
		"access": "تذاكر تُكتسب من اللعب والإنجازات",
		"activities": [
			"استكشاف الجزيرة",
			"التجارة",
			"تحديات الموسم",
			"جمع الكنوز",
			"الغارات",
			"أنشطة القصر"
		]
	}
}


const SHARED_SYSTEMS := [
	"player_progress",
	"guilds",
	"quests",
	"raids",
	"trading",
	"npc_society",
	"relationships",
	"families",
	"world_saving",
	"injury_and_healing",
	"reputation",
	"map_discovery",
	"fast_travel"
]


static func get_all_worlds() -> Array:
	return WORLD_DATA.values().duplicate(true)


static func get_world(world_id: String) -> Dictionary:
	if not WORLD_DATA.has(world_id):
		return {}

	return WORLD_DATA[world_id].duplicate(true)


static func get_world_ids() -> Array[String]:
	var result: Array[String] = []

	for world_id in WORLD_DATA.keys():
		result.append(str(world_id))

	return result


static func get_world_scene(world_id: String) -> String:
	var world := get_world(world_id)

	if world.is_empty():
		return ""

	return str(world.get("scene_path", ""))


static func get_world_stage(world_id: String) -> String:
	var world := get_world(world_id)

	if world.is_empty():
		return "unknown"

	return str(world.get("stage", "planned"))


static func get_miyar_outfit(world_id: String) -> String:
	var world := get_world(world_id)

	if world.is_empty():
		return "default"

	return str(world.get("miyar_outfit", "default"))


static func get_shared_systems() -> Array:
	return SHARED_SYSTEMS.duplicate(true)
