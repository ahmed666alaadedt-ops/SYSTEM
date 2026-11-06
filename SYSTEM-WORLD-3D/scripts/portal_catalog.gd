
extends RefCounted
class_name SYSTEMPortalCatalog

# كتالوج أنواع البوابات في العوالم الأربعة.
# icon_key هو معرّف الأيقونة التي سنضيف تصميمها لاحقاً.

const PORTALS = {
	"modern": {
		"stable": {
			"name": "بوابة مستقرة",
			"icon_key": "portal_stable",
			"color_hex": "#22DDEE",
			"danger": 1,
			"glow": 1.2
		},
		"random": {
			"name": "بوابة عشوائية",
			"icon_key": "portal_random",
			"color_hex": "#4777FF",
			"danger": 3,
			"glow": 1.7
		},
		"boss": {
			"name": "بوابة زعيم",
			"icon_key": "portal_boss",
			"color_hex": "#FF3333",
			"danger": 5,
			"glow": 2.5
		}
	},

	"historical": {
		"stable": {
			"name": "بوابة الحضارات",
			"icon_key": "portal_civilization",
			"color_hex": "#D6A34A",
			"danger": 2,
			"glow": 1.3
		},
		"random": {
			"name": "بوابة الآثار المفقودة",
			"icon_key": "portal_ruins",
			"color_hex": "#A87942",
			"danger": 4,
			"glow": 1.8
		},
		"boss": {
			"name": "بوابة الحارس القديم",
			"icon_key": "portal_guardian",
			"color_hex": "#E84A32",
			"danger": 5,
			"glow": 2.4
		}
	},

	"fantasy": {
		"stable": {
			"name": "بوابة الطاقة السحرية",
			"icon_key": "portal_magic",
			"color_hex": "#A34DFF",
			"danger": 2,
			"glow": 1.5
		},
		"random": {
			"name": "بوابة المجهول",
			"icon_key": "portal_mystery",
			"color_hex": "#35E89A",
			"danger": 4,
			"glow": 2.0
		},
		"boss": {
			"name": "بوابة التنين",
			"icon_key": "portal_dragon",
			"color_hex": "#FF572E",
			"danger": 5,
			"glow": 2.8
		}
	},

	"greed_island": {
		"stable": {
			"name": "بوابة الجزيرة",
			"icon_key": "portal_island",
			"color_hex": "#F5D442",
			"danger": 3,
			"glow": 1.8
		},
		"random": {
			"name": "بوابة الكنوز",
			"icon_key": "portal_treasure",
			"color_hex": "#FF9D35",
			"danger": 4,
			"glow": 2.2
		},
		"boss": {
			"name": "بوابة التحدي الأسطوري",
			"icon_key": "portal_legendary",
			"color_hex": "#FF3E78",
			"danger": 5,
			"glow": 3.0
		}
	}
}


static func get_world_ids() -> Array:
	return PORTALS.keys()


static func get_world_portals(world_id: String) -> Dictionary:
	if not PORTALS.has(world_id):
		return {}

	return PORTALS[world_id].duplicate(true)


static func get_portal_config(
	world_id: String,
	portal_id: String
) -> Dictionary:
	if not PORTALS.has(world_id):
		return {}

	var world_portals: Dictionary = PORTALS[world_id]

	if not world_portals.has(portal_id):
		return {}

	var config: Dictionary = world_portals[portal_id].duplicate(true)
	config["color"] = Color(config["color_hex"])

	return config


static func get_portal_color(
	world_id: String,
	portal_id: String
) -> Color:
	var config := get_portal_config(world_id, portal_id)

	if config.is_empty():
		return Color.WHITE

	return config["color"]


static func get_portal_danger(
	world_id: String,
	portal_id: String
) -> int:
	var config := get_portal_config(world_id, portal_id)

	if config.is_empty():
		return 0

	return int(config["danger"])
