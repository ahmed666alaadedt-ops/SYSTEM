
extends RefCounted
class_name SystemCharacterWardrobe

# SYSTEM WORLD
# Miyar and Adam - World-based wardrobe definitions.
# Godot 4.3
# No sportswear or training outfits.

const WORLD_IDS := [
	"modern",
	"history",
	"fantasy",
	"greed"
]

const MIYAR_OUTFITS := {
	"modern": {
		"title": "أناقة المستقبل",
		"design": "أزياء نسائية عصرية مستقبلية فاخرة",
		"style": "أنثوي، جذاب، راقٍ، بقصّات أنيقة",
		"main_color": Color(0.035, 0.10, 0.19),
		"secondary_color": Color(0.12, 0.72, 0.95),
		"detail_color": Color(0.82, 0.91, 1.0),
		"accessories": "إكسسوارات تقنية مضيئة ناعمة"
	},
	"history": {
		"title": "الإمبراطورة الصينية",
		"design": "أزياء نسائية إمبراطورية صينية فاخرة",
		"style": "أنثوي، ملكي، مطرز، فاخر",
		"main_color": Color(0.48, 0.035, 0.09),
		"secondary_color": Color(0.82, 0.57, 0.19),
		"detail_color": Color(1.0, 0.83, 0.48),
		"accessories": "زخارف ذهبية وتاج وحلي إمبراطورية"
	},
	"fantasy": {
		"title": "الساحرة الملكية",
		"design": "أزياء ساحرة خيالية ملكية",
		"style": "أنثوي، ساحر، جذاب، غامض",
		"main_color": Color(0.19, 0.055, 0.36),
		"secondary_color": Color(0.42, 0.20, 0.78),
		"detail_color": Color(0.55, 0.88, 1.0),
		"accessories": "زخارف سحرية وتاج وحلي مضيئة"
	},
	"greed": {
		"title": "ملاك الظلام",
		"design": "فستان ملكي أسود بأجنحة سوداء كبيرة",
		"style": "أنثوي، مهيب، جذاب، غامض",
		"main_color": Color(0.018, 0.018, 0.035),
		"secondary_color": Color(0.20, 0.17, 0.29),
		"detail_color": Color(0.70, 0.65, 0.88),
		"accessories": "أجنحة ريشية سوداء وتاج داكن"
	}
}

const ADAM_OUTFITS := {
	"modern": {
		"title": "أناقة المستقبل الرجالية",
		"design": "أزياء رجالية مستقبلية أنيقة وفاخرة",
		"style": "رجولي، جذاب، أنيق، بهيبة واضحة",
		"main_color": Color(0.035, 0.09, 0.15),
		"secondary_color": Color(0.08, 0.55, 0.78),
		"detail_color": Color(0.75, 0.88, 0.98),
		"accessories": "إكسسوارات تقنية راقية"
	},
	"history": {
		"title": "الأمير والمحارب",
		"design": "أزياء رجالية تاريخية ملكية تناسب الحضارات",
		"style": "رجولي، نبيل، أنيق، مهيب",
		"main_color": Color(0.28, 0.10, 0.045),
		"secondary_color": Color(0.65, 0.38, 0.12),
		"detail_color": Color(0.90, 0.73, 0.38),
		"accessories": "عباءة ملكية وحزام وزخارف تاريخية"
	},
	"fantasy": {
		"title": "الفارس الأسطوري",
		"design": "ملابس فارس أو أمير من ممالك الخيال",
		"style": "رجولي، أنيق، قوي، أسطوري",
		"main_color": Color(0.12, 0.08, 0.25),
		"secondary_color": Color(0.30, 0.22, 0.58),
		"detail_color": Color(0.55, 0.82, 1.0),
		"accessories": "عباءة ملكية وزخارف سحرية"
	},
	"greed": {
		"title": "حارس جزيرة الطمع",
		"design": "زي رجالي ملكي غامض وفخم",
		"style": "رجولي، جذاب، مهيب، غامض",
		"main_color": Color(0.025, 0.025, 0.04),
		"secondary_color": Color(0.22, 0.18, 0.27),
		"detail_color": Color(0.78, 0.68, 0.48),
		"accessories": "عباءة داكنة وزخارف فضية"
	}
}


static func get_miyar_outfit(world_id: String) -> Dictionary:
	return MIYAR_OUTFITS.get(
		world_id,
		MIYAR_OUTFITS["modern"]
	).duplicate(true)


static func get_adam_outfit(world_id: String) -> Dictionary:
	return ADAM_OUTFITS.get(
		world_id,
		ADAM_OUTFITS["modern"]
	).duplicate(true)


static func get_world_outfits(world_id: String) -> Dictionary:
	return {
		"world_id": world_id,
		"miyar": get_miyar_outfit(world_id),
		"adam": get_adam_outfit(world_id)
	}


static func is_supported_world(world_id: String) -> bool:
	return WORLD_IDS.has(world_id)


static func get_all_world_ids() -> Array:
	return WORLD_IDS.duplicate()
