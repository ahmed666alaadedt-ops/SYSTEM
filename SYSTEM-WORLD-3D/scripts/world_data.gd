
extends RefCounted
class_name SystemWorldData

# SYSTEM WORLD
# Central definition for the four connected worlds.
# Godot 4.3

const WORLD_DATA := {
	"modern": {
		"id": "modern",
		"title": "العالم الحديث والمستقبلي",
		"subtitle": "المدن والحياة الواقعية",
		"stage": "prototype",
		"scene_path": "res://scenes/main.tscn",
		"miyar_outfit": "future",
		"environment": "مدن ودول حقيقية، شوارع، مبانٍ، طبيعة، بحار وجزر",
		"combat": "قتال جسدي، أسلحة حديثة، ومهارات وقدرات شخصية",
		"exploration": [
			"مدن ودول حقيقية",
			"مناطق ريفية",
			"بحار وجزر",
			"بوابات وأبراج تحديات",
			"مستشفيات ونقاط سفر سريع"
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
		"stage": "prototype",
		"scene_path": "res://scenes/fantasy_world.tscn",
		"miyar_outfit": "magic",
		"environment": "ممالك متعددة وغابات عملاقة وجبال وقلاع",
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
			"الشخصيات المستقلة",
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


# Android aliases and older identifiers.
const WORLD_ALIASES := {
	"real": "modern",
	"modern": "modern",
	"mythology": "history",
	"historical": "history",
	"history": "history",
	"fantasy": "fantasy",
	"greed": "greed",
	"greed_island": "greed"
}


const SHARED_SYSTEMS := [
	"central_player_account",
	"player_progress",
	"friends",
	"unified_chat",
	"voice_chat",
	"teams_and_clans",
	"guilds",
	"quests",
	"raids",
	"trading",
	"global_economy",
	"npc_society",
	"relationships",
	"families",
	"world_saving",
	"injury_and_healing",
	"reputation",
	"map_discovery",
	"fast_travel"
]


static func normalize_world_id(world_id: String) -> String:
	var key := world_id.strip_edges().to_lower()
	return str(WORLD_ALIASES.get(key, ""))


static func get_all_worlds() -> Array:
	return WORLD_DATA.values().duplicate(true)


static func get_world(world_id: String) -> Dictionary:
	var normalized_id := normalize_world_id(world_id)

	if normalized_id.is_empty():
		return {}

	if not WORLD_DATA.has(normalized_id):
		return {}

	return WORLD_DATA[normalized_id].duplicate(true)


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


static func is_world_available(world_id: String) -> bool:
	var scene_path := get_world_scene(world_id)

	if scene_path.is_empty():
		return false

	return ResourceLoader.exists(scene_path)
