extends Node
class_name SYSTEMBaghdadTowerOperationsManager

const NPCCharacterModelScript = preload("res://scripts/npc_character_model.gd")
const TowerOpponentScript = preload("res://scripts/system_tower_opponent.gd")
const TowerFloorThemeBuilder = preload("res://scripts/system_baghdad_tower_floor_theme_builder.gd")
const SAVE_PATH := "user://system_baghdad_tower_operations.cfg"
const STOCK_SAVE_PATH := "user://system_tower_vendor_stock.cfg"
const HOTEL_SAVE_PATH := "user://system_baghdad_hotel_bookings.cfg"
const NPC_SALES_SAVE_PATH := "user://system_baghdad_npc_sales.cfg"
const WORLD_ID := 2
const STAFF_NAMES := ["أحمد", "سارة", "علي", "نور", "حسن", "مريم", "يوسف", "ليان", "عمر", "زينب", "مصطفى", "رنا"]

const TOWER_CONFIG := {
	"hunter_association_tower_baghdad": {"node": "HunterAssociationTower", "title": "برج جمعية الصيادين", "floors": 200, "height": 1000.0, "radius": 38.0, "roles": ["مدير النقابة", "موظف الاستقبال", "موظف المهمات", "مسؤول تسجيل الاختبارات", "مستشار الرتب", "منسق النقابات", "مسؤول العلاقات العامة", "مسؤول الإعلانات"], "jobs": ["association_director", "receptionist", "mission_clerk", "exam_registrar", "rank_advisor", "guild_coordinator", "public_relations", "advertising_manager"]},

	"business_investment_tower_baghdad": {"node": "BusinessInvestmentTower", "title": "برج الأعمال والاستثمار", "floors": 36, "height": 220.0, "radius": 26.0, "roles": ["مدير البرج", "مدير الاستثمار", "مستشار الشركات", "موظف البنوك والعقود", "محاسب البرج", "مسؤول التوظيف", "خدمة المستثمرين", "مسؤول الإعلانات"], "jobs": ["tower_director", "investment_manager", "business_advisor", "bank_contract_clerk", "accountant", "recruitment_manager", "investor_relations", "advertising_manager"]},
	"shopping_tower_baghdad": {"node": "ShoppingTower", "title": "برج التسوق والتجارة", "floors": 32, "height": 190.0, "radius": 30.0, "roles": ["مدير البرج", "تاجر الأسلحة والدروع", "صيدلاني الإكسير", "مدير الضيافة والفندق", "شيف المطاعم", "نادل وخدمة الزبائن", "موظف استقبال الفندق", "مشرف الغرف والتنظيف", "مسؤول الإعلانات والتسويق"], "jobs": ["shop_manager", "weapons_merchant", "elixir_pharmacist", "hospitality_manager", "restaurant_chef", "restaurant_waiter", "hotel_receptionist", "hotel_housekeeping", "advertising_manager"]},
	"entertainment_tower_baghdad": {"node": "EntertainmentTower", "title": "برج الترفيه والرياضة", "floors": 34, "height": 205.0, "radius": 29.0, "roles": ["مدير الترفيه", "منظم الفعاليات", "موظف التذاكر", "مشرف المسابح", "مدرب اللياقة", "منظم الألعاب", "خدمة الزوار", "مسؤول الإعلانات"], "jobs": ["entertainment_director", "event_coordinator", "ticket_clerk", "pool_supervisor", "fitness_trainer", "game_host", "guest_services", "advertising_manager"]},
	"technology_tower_baghdad": {"node": "TechnologyTower", "title": "برج التكنولوجيا والابتكار", "floors": 40, "height": 245.0, "radius": 27.0, "roles": ["مدير الابتكار", "موظف المختبر", "مهندس الأجهزة", "مهندس الروبوتات", "باحث الذكاء الاصطناعي", "موظف الخدمات الرقمية", "مسؤول الصيانة", "مسؤول الإعلانات"], "jobs": ["innovation_director", "lab_receptionist", "device_engineer", "robotics_engineer", "ai_researcher", "digital_services", "maintenance_engineer", "advertising_manager"]},
	"power_tower_baghdad": {"node": "PowerTower", "title": "برج القوة", "floors": 200, "height": 820.0, "radius": 26.0, "roles": ["موظف تسجيل التحديات", "منظم الحلبة", "موظف الاستراحة الطبية", "مسؤول الإعلانات"], "jobs": ["arena_registrar", "arena_coordinator", "arena_medic", "advertising_manager"]}
}

const PRODUCT_CATALOG := {
	"shopping_tower_baghdad": [
		{"id":"food_ration","name":"وجبة ميدانية","price":35},
		{"id":"water_bottle","name":"قارورة ماء","price":12},
		{"id":"casual_outfit","name":"ملابس يومية","price":220},
		{"id":"hunter_backpack","name":"حقيبة صياد","price":340},
		{"id":"travel_kit","name":"عدة سفر","price":190},
		{"id":"cosmetic_light","name":"زينة ضوئية","price":500},
		{"id":"training_sword","name":"سيف تدريبي","price":180,"required_rank":"F"},
		{"id":"steel_sword","name":"سيف فولاذي","price":950,"required_rank":"D"},
		{"id":"hunter_spear","name":"رمح صياد","price":780,"required_rank":"D"},
		{"id":"battle_axe","name":"فأس قتالي","price":820,"required_rank":"C"},
		{"id":"composite_bow","name":"قوس مركب وسهام","price":1100,"required_rank":"C"},
		{"id":"system_firearm","name":"سلاح ناري حديث","price":2400,"required_rank":"B"},
		{"id":"hunter_shield","name":"درع صياد","price":650,"required_rank":"D"},
		{"id":"hunter_armor","name":"درع واقٍ","price":1450,"required_rank":"C"},
		{"id":"hunter_helmet","name":"خوذة صياد","price":450,"required_rank":"C"},
		{"id":"combat_outfit","name":"بدلة قتالية أساسية — رتبة F","price":950,"required_rank":"F"},
		{"id":"hunter_outfit_e","name":"بدلة الصياد — رتبة E","price":1250,"required_rank":"E"},
		{"id":"hunter_outfit_d","name":"بدلة الصياد — رتبة D","price":1750,"required_rank":"D"},
		{"id":"hunter_outfit_c","name":"بدلة الصياد — رتبة C","price":2600,"required_rank":"C"},
		{"id":"hunter_outfit_b","name":"بدلة الصياد — رتبة B","price":3900,"required_rank":"B"},
		{"id":"hunter_outfit_a","name":"بدلة الصياد — رتبة A","price":5800,"required_rank":"A"},
		{"id":"hunter_outfit_s","name":"بدلة الصياد — رتبة S","price":9000,"required_rank":"S"},
		{"id":"hunter_outfit_ss","name":"بدلة الصياد — رتبة SS","price":16000,"required_rank":"SS"},
		{"id":"hunter_outfit_sss","name":"بدلة الصياد — رتبة SSS","price":30000,"required_rank":"SSS"},
		{"id":"healing_elixir","name":"إكسير الشفاء","price":280},
		{"id":"strength_elixir","name":"إكسير القوة","price":420},
		{"id":"speed_elixir","name":"إكسير السرعة","price":420},
		{"id":"endurance_elixir","name":"إكسير التحمل","price":450},
		{"id":"energy_elixir","name":"إكسير الطاقة","price":360},
		{"id":"nen_awakening_elixir","name":"إكسير إيقاظ النِن","price":1800},
		{"id":"nen_control_elixir","name":"إكسير التحكم بالنِن","price":2600},
		{"id":"rare_legendary_elixir","name":"إكسير نادر/أسطوري","price":12000},
		{"id":"repair_kit","name":"عدة إصلاح المعدات","price":250},
		{"id":"iron_ingot","name":"سبيكة حديد","price":45},
		{"id":"wood_plank","name":"لوح خشب مصقول","price":20},
		{"id":"leather_roll","name":"لفافة جلد","price":35},
		{"id":"medicinal_herb","name":"عشبة طبية","price":25},
		{"id":"crystal_dust","name":"غبار كريستالي","price":80},
		{"id":"monster_core","name":"نواة وحش","price":150},
		{"id":"nen_fragment","name":"شظية نِن","price":300},
		{"id":"energy_crystal","name":"كريستال طاقة","price":450},
		{"id":"rare_core","name":"نواة نادرة","price":1200},

		{"id":"nen_stabilizer_elixir","name":"إكسير تثبيت هالة النِن","price":3200,"required_rank":"C"},
		{"id":"nen_focus_elixir","name":"إكسير تركيز النِن","price":2100,"required_rank":"D"},
		{"id":"nen_recovery_elixir","name":"إكسير استعادة النِن","price":2800,"required_rank":"C"},
		{"id":"deep_wound_elixir","name":"إكسير علاج الإصابات العميقة","price":950,"required_rank":"D"},
		{"id":"regeneration_elixir","name":"إكسير التجدد الحيوي","price":1450,"required_rank":"C"},
		{"id":"antidote_elixir","name":"إكسير مضاد السموم","price":390,"required_rank":"F"},
		{"id":"resistance_elixir","name":"إكسير مقاومة الإرهاق","price":620,"required_rank":"E"},
		{"id":"elite_legendary_elixir","name":"إكسير أسطوري للنخبة","price":24000,"required_rank":"S"},
		{"id":"hunter_pistol","name":"مسدس صياد حديث","price":1750,"required_rank":"C"},
		{"id":"hunter_rifle","name":"بندقية صياد حديثة","price":3600,"required_rank":"B"},
		{"id":"precision_rifle","name":"بندقية دقيقة بعيدة المدى","price":6200,"required_rank":"A"},
		{"id":"tactical_shotgun","name":"بندقية تكتيكية","price":4100,"required_rank":"B"},
		{"id":"combat_knife","name":"خنجر قتالي","price":520,"required_rank":"E"},
		{"id":"dual_blades","name":"نصلان مزدوجان","price":1850,"required_rank":"C"},
		{"id":"long_sword","name":"سيف طويل متوازن","price":1750,"required_rank":"C"},
		{"id":"great_sword","name":"سيف ثقيل عظيم","price":4200,"required_rank":"B"},
		{"id":"crossbow","name":"قوس نشاب","price":1450,"required_rank":"C"},
		{"id":"reinforced_arrows","name":"سهام مقواة — حزمة","price":160,"required_rank":"F"},
		{"id":"war_hammer","name":"مطرقة حرب","price":1950,"required_rank":"C"},
		{"id":"advanced_hunter_shield","name":"درع صياد معزز","price":2850,"required_rank":"B"},
		{"id":"reinforced_helmet","name":"خوذة مدرعة معززة","price":1350,"required_rank":"B"},
		{"id":"rank_e_armor","name":"درع خفيف — رتبة E","price":1150,"required_rank":"E"},
		{"id":"rank_d_armor","name":"درع ميداني — رتبة D","price":1850,"required_rank":"D"},
		{"id":"rank_c_armor","name":"درع قتالي — رتبة C","price":2900,"required_rank":"C"},
		{"id":"rank_b_armor","name":"درع تكتيكي — رتبة B","price":4600,"required_rank":"B"},
		{"id":"rank_a_armor","name":"درع نخبة — رتبة A","price":7200,"required_rank":"A"},
		{"id":"rank_s_armor","name":"درع متقدم — رتبة S","price":12500,"required_rank":"S"},
		{"id":"rank_ss_armor","name":"درع أسطوري — رتبة SS","price":22000,"required_rank":"SS"},
		{"id":"rank_sss_armor","name":"درع SYSTEM الفريد — رتبة SSS","price":42000,"required_rank":"SSS"},
		{"id":"restaurant_baghdad_breakfast","name":"فطور بغدادي تقليدي","price":42},
		{"id":"restaurant_masگوف","name":"سمك مسگوف عراقي","price":95},
		{"id":"restaurant_kebab","name":"كباب عراقي","price":68},
		{"id":"restaurant_arabic_mandi","name":"مندي عربي","price":82},
		{"id":"restaurant_international_pasta","name":"طبق باستا عالمي","price":76},
		{"id":"restaurant_premium_steak","name":"وجبة ستيك فاخرة","price":220},
		{"id":"restaurant_bakery_bread","name":"مخبوزات طازجة","price":18},
		{"id":"restaurant_cake_slice","name":"قطعة كيك وحلويات","price":38},
		{"id":"restaurant_specialty_coffee","name":"قهوة مختصة","price":28},
		{"id":"restaurant_grilled_meal","name":"وجبة مشاوي بغدادية","price":75},
		{"id":"restaurant_rice_meal","name":"وجبة رز ولحم","price":65},
		{"id":"restaurant_hunter_meal","name":"وجبة الصياد المتكاملة","price":110},
		{"id":"restaurant_fresh_juice","name":"عصير طازج","price":22},
		{"id":"restaurant_tea_coffee","name":"شاي وقهوة","price":15},
		{"id":"restaurant_dessert","name":"حلويات شرقية","price":30},
		{"id":"restaurant_family_combo","name":"وجبة عائلية","price":180}
	],
	"business_investment_tower_baghdad": [
		{"id":"business_registration_package","name":"حزمة تأسيس شركة","price":420},
		{"id":"business_bank_account_service","name":"فتح حساب تجاري","price":95},
		{"id":"business_consultation","name":"استشارة أعمال واستثمار","price":180},
		{"id":"business_office_day_pass","name":"تصريح استخدام مكتب ليوم واحد","price":140},
		{"id":"business_office_week_pass","name":"تصريح مكتب لأسبوع","price":720},
		{"id":"business_investment_certificate","name":"شهادة استثمار تجريبية","price":850},
		{"id":"business_market_share_unit","name":"وحدة مشاركة في محفظة السوق","price":1250},
		{"id":"business_recruitment_listing","name":"إعلان توظيف للشركات","price":120},
		{"id":"business_cafe_espresso","name":"إسبريسو مقهى الأعمال","price":28},
		{"id":"business_cafe_tea","name":"شاي جلسات المستثمرين","price":15},
		{"id":"business_cafe_pastry","name":"معجنات مقهى الأعمال","price":22}
	],
	"entertainment_tower_baghdad": [
		{"id":"sports_ticket","name":"تذكرة رياضية","price":65},
		{"id":"pool_ticket","name":"تذكرة المسبح","price":45},
		{"id":"festival_ticket","name":"تذكرة مهرجان","price":90},
		{"id":"arena_spectator_ticket","name":"تذكرة مشاهدة الحلبة","price":120},
		{"id":"cinema_ticket","name":"تذكرة سينما","price":55},
		{"id":"bowling_ticket","name":"تذكرة بولينغ","price":70},
		{"id":"arcade_credit_pack","name":"رصيد ألعاب إلكترونية","price":30},
		{"id":"fitness_day_pass","name":"تذكرة النادي الرياضي","price":50},
		{"id":"spa_relaxation_ticket","name":"تذكرة الاسترخاء والسبا","price":95},
		{"id":"family_zone_pass","name":"تذكرة منطقة العائلات","price":80},
		{"id":"rooftop_event_ticket","name":"تذكرة فعالية السطح","price":120},
		{"id":"entertainment_cafe_juice","name":"عصير منعش","price":22},
		{"id":"entertainment_cafe_popcorn","name":"فشار السينما","price":18},
		{"id":"entertainment_cafe_sandwich","name":"ساندويتش الزوار","price":35}
	],
	"technology_tower_baghdad": [
		{"id":"scanner_device","name":"جهاز ماسح","price":750},
		{"id":"repair_kit","name":"عدة صيانة","price":160},
		{"id":"drone_camera","name":"كاميرا مسيّرة","price":1250},
		{"id":"energy_cell","name":"خلية طاقة","price":240},
		{"id":"robotics_kit","name":"عدة روبوتات تعليمية","price":620},
		{"id":"ai_compute_access_pass","name":"تصريح استخدام حوسبة الذكاء الاصطناعي","price":180},
		{"id":"vr_simulation_pass","name":"تذكرة محاكاة الواقع الافتراضي","price":90},
		{"id":"prototype_lab_pass","name":"تصريح دخول مختبر النماذج الأولية","price":240},
		{"id":"device_diagnostic_service","name":"فحص وتشخيص جهاز","price":110},
		{"id":"technology_cafe_coffee","name":"قهوة مقهى التقنية","price":25},
		{"id":"technology_cafe_energy_drink","name":"مشروب طاقة","price":32},
		{"id":"technology_cafe_snack","name":"وجبة خفيفة","price":20}
	],
	"hunter_association_tower_baghdad": [
		{"id":"mission_supply_pack","name":"حزمة تجهيز المهمات","price":160},
		{"id":"hunter_medical_kit","name":"حقيبة إسعاف صياد","price":230},
		{"id":"exam_application_pack","name":"حزمة التسجيل للاختبار","price":100},
		{"id":"hunter_cafe_meal","name":"وجبة استراحة الصيادين","price":38},
		{"id":"hunter_cafe_coffee","name":"قهوة الصيادين","price":18},
		{"id":"hunter_cafe_water","name":"ماء معدني","price":12}
	]
}
const HOTEL_ROOM_CATALOG := [
	{"id":"hotel_standard_01","name":"غرفة قياسية 01","rate":180,"required_rank":"F"},
	{"id":"hotel_standard_02","name":"غرفة قياسية 02","rate":180,"required_rank":"F"},
	{"id":"hotel_standard_03","name":"غرفة قياسية 03","rate":180,"required_rank":"F"},
	{"id":"hotel_standard_04","name":"غرفة قياسية 04","rate":180,"required_rank":"F"},
	{"id":"hotel_deluxe_01","name":"غرفة ديلوكس 01","rate":320,"required_rank":"E"},
	{"id":"hotel_deluxe_02","name":"غرفة ديلوكس 02","rate":320,"required_rank":"E"},
	{"id":"hotel_hunter_suite","name":"جناح الصيادين","rate":850,"required_rank":"A"},
	{"id":"hotel_elite_vip","name":"جناح النخبة VIP","rate":1500,"required_rank":"S"}
]

const AD_CAMPAIGNS := [
	"معدات الصيادين — جهّز نفسك قبل البوابة",
	"إكسير الشفاء والطاقة متوفر لدى الصيدلاني",
	"عروض التسوق والخدمات اليومية داخل مجمع بغداد",
	"الرياضة والترفيه — فعاليات جديدة بانتظارك",
	"مختبرات SYSTEM — أدوات وتقنيات للاستكشاف",
	"برج القوة — سجّل تحديك القادم واصعد بالرتب"
]

var player: CharacterBody3D
var progression: Node
var society: Node
var power_tower_manager: Node
var player_health: Node
var region_manager: Node
var tower_manager: Node
var tower_nodes: Dictionary = {}
var staff_by_tower: Dictionary = {}
var ad_labels: Dictionary = {}
var prepared_towers: Dictionary = {}
var current_tower_id := ""
var current_staff_id := ""
var credits := 1200
var vendor_stock: Dictionary = {}
var hotel_bookings: Dictionary = {}
var stock_refresh_clock := 300.0
var ad_clock := 0.0
var ad_index := 0
var ui_layer: CanvasLayer
var panel: PanelContainer
var content: VBoxContainer
var catalog_controls: VBoxContainer
var inventory_controls: VBoxContainer
var crafting_controls: VBoxContainer
var title_label: Label
var status_label: Label
var credits_label: Label
var floor_selector: SpinBox
var power_floor_started_at := 0
var power_floor_timer_remaining := 0.0
var power_floor_timer_display_clock := 0.0
var active_power_objective_label: Label3D
var active_power_floor_data: Dictionary = {}
var active_floor_root: Node3D
var active_elevator_car: Node3D
var active_elevator_tower_id := ""
var active_elevator_doors: Array[Node3D] = []
var active_elevator_car_width := 0.0
var active_opponents: Dictionary = {}
var power_tower_progress_board: Label3D
var current_wave := 0
var total_waves := 0
var opponents_per_wave := 0
var defeated_in_wave := 0
var power_floor_in_progress := false
var customer_ids_by_tower: Dictionary = {}
var customer_purchase_clock := 0.0
var customer_walk_clock := 0.0
var npc_sales_total := 0
var npc_purchase_count := 0

func setup(p_player: CharacterBody3D, p_progression: Node, p_society: Node, p_power_manager: Node, p_player_health: Node, p_region_manager: Node) -> void:
	player = p_player
	progression = p_progression
	society = p_society
	power_tower_manager = p_power_manager
	player_health = p_player_health
	region_manager = p_region_manager
	if region_manager == null:
		push_warning("SYSTEM tower operations: Baghdad region manager unavailable.")
		return
	tower_manager = region_manager.get_node_or_null("BaghdadTowerLandmarksManager")
	if tower_manager == null:
		push_warning("SYSTEM tower operations: Baghdad tower landmarks unavailable.")
		return
	_load_wallet()
	_load_vendor_stock()
	_load_hotel_bookings()
	_load_npc_sales_ledger()
	_build_ui()
	if is_instance_valid(player_health) and player_health.has_signal("player_wounded"):
		var wounded_callback := Callable(self, "_on_player_wounded")
		if not player_health.is_connected("player_wounded", wounded_callback):
			player_health.connect("player_wounded", wounded_callback)
	_resolve_towers()
	_create_staff_for_all_towers()
	_create_customer_population()
	_create_public_lobby_cafes()
	_create_advertising_surfaces()
	_create_power_tower_progress_board()
	set_process(true)
	print("SYSTEM tower operations: staff, local trading, floor interiors and advertising initialized.")

func _process(delta: float) -> void:
	ad_clock += delta
	if ad_clock >= 38.0:
		ad_clock = 0.0
		ad_index = (ad_index + 1) % AD_CAMPAIGNS.size()
		_refresh_advertisements()
	stock_refresh_clock -= delta
	if stock_refresh_clock <= 0.0:
		stock_refresh_clock = 300.0
		_restock_vendor_stock()
	customer_purchase_clock += delta
	if customer_purchase_clock >= 42.0:
		customer_purchase_clock = 0.0
		_simulate_customer_purchases()
	customer_walk_clock += delta
	if customer_walk_clock >= 13.0:
		customer_walk_clock = 0.0
		_move_customer_visitors()
	if power_floor_in_progress and power_floor_timer_remaining > 0.0:
		power_floor_timer_remaining = maxf(0.0, power_floor_timer_remaining - delta)
		power_floor_timer_display_clock -= delta
		if power_floor_timer_remaining <= 0.0:
			var objective := str(active_power_floor_data.get("objective_type", ""))
			if objective == "SURVIVE_TIMER":
				_clear_active_power_opponents()
				_complete_power_floor()
			elif objective == "CLEAR_WITHIN_TIME":
				_fail_power_floor("انتهى الوقت قبل إكمال البطولة.")
		elif power_floor_timer_display_clock <= 0.0:
			power_floor_timer_display_clock = 1.0
			_update_power_objective_display()

func _resolve_towers() -> void:
	for tower_id in TOWER_CONFIG.keys():
		var config: Dictionary = TOWER_CONFIG[tower_id]
		var tower := tower_manager.get_node_or_null(str(config["node"])) as Node3D
		if tower != null:
			tower_nodes[tower_id] = tower

func _create_staff_for_all_towers() -> void:
	for tower_id in tower_nodes.keys():
		var config: Dictionary = TOWER_CONFIG[tower_id]
		var staff_ids: Array[String] = []
		for index in range(config["roles"].size()):
			var npc_id := _get_or_create_staff(str(tower_id), index, config)
			if not npc_id.is_empty():
				staff_ids.append(npc_id)
				_create_visible_staff(str(tower_id), npc_id, index, config)
		staff_by_tower[tower_id] = staff_ids
	if is_instance_valid(society) and society.has_method("save_society"):
		society.call("save_society")

func _get_or_create_staff(tower_id: String, index: int, config: Dictionary) -> String:
	if not is_instance_valid(society):
		return ""
	var existing: String = ""
	for npc_id in society.npcs.keys():
		var npc: Dictionary = society.npcs[npc_id]
		if str(npc.get("system_tower_staff_tower", "")) == tower_id and int(npc.get("system_tower_staff_index", -1)) == index and bool(npc.get("alive", false)):
			existing = str(npc_id)
			break
	if existing.is_empty():
		var display_name := str(STAFF_NAMES[posmod(index, STAFF_NAMES.size())])
		existing = str(society.call("create_npc", display_name, WORLD_ID, 24.0 + float(index * 4), "professional", str(config["jobs"][index])))
	if existing.is_empty():
		return ""
	var npc: Dictionary = society.call("get_npc", existing)
	npc["name"] = str(STAFF_NAMES[posmod(index, STAFF_NAMES.size())])
	npc["gender"] = "female" if posmod(index, 2) == 1 else "male"
	npc["system_tower_staff_tower"] = tower_id
	npc["system_tower_staff_index"] = index
	npc["system_tower_staff_role"] = str(config["jobs"][index])
	npc["employer_id"] = tower_id
	npc["home_location"] = "baghdad_staff_residence"
	npc["current_location"] = tower_id + "_lobby"
	npc["wallet"] = float(npc.get("wallet", 120.0))
	npc["daily_wage"] = 18.0 + float(index * 4)
	npc["schedule_profile"] = "tower_shift"
	npc["current_action"] = "working"
	society.npcs[existing] = npc
	if society.has_method("set_activity"):
		society.call("set_activity", existing, "work", tower_id + "_lobby")
	return existing

func _create_visible_staff(tower_id: String, npc_id: String, index: int, config: Dictionary) -> void:
	var tower := tower_nodes.get(tower_id) as Node3D
	if tower == null:
		return
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
	if lobby == null:
		return
	if lobby.get_node_or_null("TowerStaff_" + npc_id) != null:
		return
	var npc: Dictionary = society.call("get_npc", npc_id)
	var employee := Node3D.new()
	employee.name = "TowerStaff_" + npc_id
	employee.add_to_group("system_interactable")
	employee.set_meta("system_tower_staff_id", npc_id)
	employee.set_meta("system_tower_id", tower_id)
	employee.set_meta("system_tower_staff_role", str(config["jobs"][index]))
	employee.set_meta("system_display_name", str(npc.get("name", config["roles"][index])))
	employee.set_meta("system_interaction_prompt", str(config["roles"][index]) + " — اضغط للتعامل")
	lobby.add_child(employee)
	var model = NPCCharacterModelScript.new()
	model.configure({
		"name": str(npc.get("name", "موظف SYSTEM")),
		"gender": "female" if posmod(index, 2) == 1 else "male",
		"age": float(npc.get("age_years", 28.0)),
		"job": str(config["jobs"][index]),
		"occupation": str(config["jobs"][index]),
		"world_id": "modern",
		"hair_style": "short" if posmod(index, 2) == 0 else "long",
		"body_type": "average"
	}, index)
	var uniform_id := "modern"
	match tower_id:
		"hunter_association_tower_baghdad": uniform_id = "hunter_staff"
		"business_investment_tower_baghdad": uniform_id = "business_staff"
		"shopping_tower_baghdad":
			uniform_id = "hotel_staff" if str(config["jobs"][index]) in ["hospitality_manager", "hotel_receptionist", "hotel_housekeeping"] else ("restaurant_staff" if str(config["jobs"][index]) in ["restaurant_chef", "restaurant_waiter"] else "shopping_staff")
		"entertainment_tower_baghdad": uniform_id = "entertainment_staff"
		"technology_tower_baghdad": uniform_id = "technology_staff"
		"power_tower_baghdad": uniform_id = "power_staff"
	if model.has_method("set_outfit"):
		model.call("set_outfit", uniform_id, index)
	model.set_meta("system_uniform_id", uniform_id)
	model.scale = Vector3.ONE * 0.78
	employee.add_child(model)
	var name_label := Label3D.new()
	name_label.text = str(npc.get("name", config["roles"][index])) + "\n" + str(config["roles"][index])
	name_label.position.y = 2.45
	name_label.font_size = 22
	name_label.pixel_size = 0.012
	name_label.modulate = Color(0.82, 0.96, 1.0)
	employee.add_child(name_label)
	var interaction_area := Area3D.new()
	interaction_area.name = "StaffInteractionArea"
	interaction_area.collision_layer = 1
	interaction_area.collision_mask = 0
	employee.add_child(interaction_area)
	var area_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.45
	area_shape.shape = sphere
	area_shape.position.y = 1.05
	interaction_area.add_child(area_shape)
	var lobby_depth := 36.0
	var lobby_center_z := float(config["radius"]) * 1.48 + lobby_depth * 0.5
	employee.position = Vector3((float(index) - float(config["roles"].size() - 1) * 0.5) * 5.0, 0.0, lobby_center_z - 4.0)

func _create_customer_population() -> void:
	if not is_instance_valid(society):
		return
	var public_towers := [
		"hunter_association_tower_baghdad",
		"business_investment_tower_baghdad",
		"shopping_tower_baghdad",
		"entertainment_tower_baghdad",
		"technology_tower_baghdad"
	]
	for tower_index in range(public_towers.size()):
		var tower_id := str(public_towers[tower_index])
		if not tower_nodes.has(tower_id):
			continue
		var config: Dictionary = TOWER_CONFIG[tower_id]
		var tower := tower_nodes[tower_id] as Node3D
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
		if lobby == null:
			continue
		var ids: Array[String] = []
		for index in range(4):
			var existing_id := ""
			for candidate_id in society.npcs.keys():
				var candidate: Dictionary = society.npcs[candidate_id]
				if str(candidate.get("system_tower_customer_tower", "")) == tower_id and int(candidate.get("system_tower_customer_index", -1)) == index and bool(candidate.get("alive", false)):
					existing_id = str(candidate_id)
					break
			var gender := "female" if posmod(index, 2) == 1 else "male"
			var customer_name := "زائر " + str(tower_index + 1) + "-" + str(index + 1)
			if existing_id.is_empty():
				existing_id = str(society.call("create_npc", customer_name, WORLD_ID, 22.0 + float(index * 6), "visitor", "customer"))
			if existing_id.is_empty():
				continue
			var customer: Dictionary = society.call("get_npc", existing_id)
			customer["gender"] = gender
			customer["system_tower_customer_tower"] = tower_id
			customer["system_tower_customer_index"] = index
			customer["current_location"] = tower_id + "_public_area"
			customer["home_location"] = "baghdad_residential_district"
			customer["wallet"] = float(customer.get("wallet", 1800.0 + index * 450.0))
			customer["schedule_profile"] = "tower_customer"
			customer["current_action"] = "shopping"
			customer["last_tower_visit"] = Time.get_datetime_string_from_system()
			society.npcs[existing_id] = customer
			ids.append(existing_id)
			var node_name := "TowerCustomer_" + existing_id
			if lobby.get_node_or_null(node_name) == null:
				var visitor := Node3D.new()
				visitor.name = node_name
				visitor.set_meta("system_tower_customer_id", existing_id)
				visitor.set_meta("system_tower_customer_index", index)
				visitor.set_meta("system_tower_id", tower_id)
				visitor.set_meta("system_display_name", str(customer.get("name", customer_name)))
				lobby.add_child(visitor)
				var model = NPCCharacterModelScript.new()
				model.configure({
					"name": str(customer.get("name", customer_name)),
					"gender": gender,
					"age": float(customer.get("age_years", 26.0)),
					"job": "customer",
					"occupation": "customer",
					"world_id": "modern",
					"hair_style": "medium" if gender == "female" else "short",
					"body_type": "average"
				}, tower_index * 11 + index + 40)
				model.scale = Vector3.ONE * 0.74
				visitor.add_child(model)
				var name_label := Label3D.new()
				name_label.text = str(customer.get("name", customer_name))
				name_label.position.y = 2.3
				name_label.font_size = 15
				name_label.pixel_size = 0.011
				name_label.modulate = Color(0.82, 0.88, 0.94)
				visitor.add_child(name_label)
				visitor.position = Vector3((float(index) - 1.5) * 3.6, 0.0, float(config["radius"]) * 1.48 + 12.0 + float(index % 2) * 3.0)
				if model.has_method("set_activity"):
					model.call("set_activity", "socialize" if posmod(index, 2) == 0 else "wander")
		customer_ids_by_tower[tower_id] = ids
	if society.has_method("save_society"):
		society.call("save_society")
	print("SYSTEM Baghdad towers: customer NPC population initialized.")

func _create_public_lobby_cafes() -> void:
	var public_towers := [
		"hunter_association_tower_baghdad",
		"business_investment_tower_baghdad",
		"shopping_tower_baghdad",
		"entertainment_tower_baghdad",
		"technology_tower_baghdad"
	]
	for tower_id_value in public_towers:
		var tower_id := str(tower_id_value)
		var tower := tower_nodes.get(tower_id) as Node3D
		var config: Dictionary = TOWER_CONFIG[tower_id]
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
		if lobby == null or lobby.get_node_or_null("SYSTEMLobbyCafe") != null:
			continue
		var staff_ids: Array = staff_by_tower.get(tower_id, [])
		if staff_ids.is_empty():
			continue
		var radius := float(config.get("radius", 24.0))
		var center_z := radius * 1.48 + 18.0
		var cafe := Node3D.new()
		cafe.name = "SYSTEMLobbyCafe"
		cafe.position = Vector3(radius * 0.78, 0.0, center_z + 2.0)
		cafe.set_meta("system_tower_cafe", true)
		lobby.add_child(cafe)
		var counter_material := StandardMaterial3D.new()
		counter_material.albedo_color = Color(0.12, 0.18, 0.22)
		counter_material.metallic = 0.32
		counter_material.roughness = 0.42
		var accent_material := StandardMaterial3D.new()
		accent_material.albedo_color = Color(0.78, 0.57, 0.25)
		accent_material.metallic = 0.45
		_add_facility_box(cafe, "CafeCounter", Vector3(0.0, 0.8, -4.0), Vector3(9.0, 1.6, 2.4), counter_material)
		_add_facility_box(cafe, "CafeDisplayCase", Vector3(0.0, 1.9, -4.0), Vector3(6.0, 0.55, 1.5), accent_material)
		var sign := Label3D.new()
		sign.name = "CafeSign"
		sign.text = "SYSTEM CAFE — مقهى واستراحة الزوار"
		sign.position = Vector3(0.0, 3.6, -5.2)
		sign.font_size = 18
		sign.pixel_size = 0.012
		sign.modulate = Color(1.0, 0.82, 0.48)
		cafe.add_child(sign)
		for table_index in range(3):
			var x := -7.0 + float(table_index) * 7.0
			_add_facility_box(cafe, "CafeTable_%02d" % table_index, Vector3(x, 0.85, 3.0), Vector3(3.0, 0.18, 2.2), counter_material)
			for seat_index in range(2):
				_add_facility_box(cafe, "CafeSeat_%02d_%02d" % [table_index, seat_index], Vector3(x + (-1.0 if seat_index == 0 else 1.0), 0.45, 4.7), Vector3(0.7, 0.9, 0.7), accent_material)
		var interaction := Area3D.new()
		interaction.name = "CafeServiceInteraction"
		interaction.add_to_group("system_interactable")
		interaction.set_meta("system_tower_id", tower_id)
		interaction.set_meta("system_tower_staff_id", str(staff_ids[0]))
		interaction.set_meta("system_tower_staff_role", str(config["jobs"][0]))
		interaction.set_meta("system_display_name", "مقهى واستراحة " + str(config["title"]))
		interaction.set_meta("system_interaction_prompt", "مقهى البرج — طلب مشروب أو وجبة خفيفة")
		interaction.collision_layer = 1
		interaction.collision_mask = 0
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 3.4
		shape.shape = sphere
		shape.position = Vector3(0.0, 1.1, -3.0)
		interaction.add_child(shape)
		cafe.add_child(interaction)


func _load_npc_sales_ledger() -> void:
	var config := ConfigFile.new()
	if config.load(NPC_SALES_SAVE_PATH) == OK:
		npc_sales_total = int(config.get_value("sales", "total_credits", 0))
		npc_purchase_count = int(config.get_value("sales", "purchase_count", 0))


func _save_npc_sales_ledger() -> void:
	var config := ConfigFile.new()
	config.set_value("sales", "total_credits", npc_sales_total)
	config.set_value("sales", "purchase_count", npc_purchase_count)
	config.set_value("sales", "updated_at", Time.get_datetime_string_from_system())
	config.save(NPC_SALES_SAVE_PATH)


func _return_customer_visitors_to_lobbies() -> void:
	for tower_id_value in customer_ids_by_tower.keys():
		var tower_id := str(tower_id_value)
		var tower := tower_nodes.get(tower_id) as Node3D
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
		if lobby == null:
			continue
		for customer_id_value in customer_ids_by_tower[tower_id]:
			var customer_id := str(customer_id_value)
			var visitor_name := "TowerCustomer_" + customer_id
			var visitor: Node3D = null
			if is_instance_valid(active_floor_root):
				visitor = active_floor_root.get_node_or_null(visitor_name) as Node3D
			if visitor == null:
				continue
			visitor.reparent(lobby, false)
			var customer_index := int(visitor.get_meta("system_tower_customer_index", 0))
			var radius := float(TOWER_CONFIG[tower_id].get("radius", 24.0))
			visitor.position = Vector3((float(customer_index) - 1.5) * 3.6, 0.0, radius * 1.48 + 12.0 + float(customer_index % 2) * 3.0)


func _place_customer_visitors_on_floor(tower_id: String, floor_number: int, room: Node3D) -> void:
	if room == null or not customer_ids_by_tower.has(tower_id):
		return
	var tower := tower_nodes.get(tower_id) as Node3D
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
	if lobby == null:
		return
	var ids: Array = customer_ids_by_tower[tower_id]
	if ids.is_empty():
		return
	var selected_count := mini(2, ids.size())
	var floor_label := _department_for_floor(tower_id, floor_number, int(TOWER_CONFIG[tower_id].get("floors", 1)))
	for slot in range(selected_count):
		var customer_id := str(ids[posmod(floor_number + slot, ids.size())])
		var visitor_name := "TowerCustomer_" + customer_id
		var visitor := lobby.get_node_or_null(visitor_name) as Node3D
		if visitor == null:
			continue
		visitor.reparent(room, false)
		var angle := TAU * float(slot) / float(maxi(selected_count, 1))
		var radius := float(TOWER_CONFIG[tower_id].get("radius", 24.0))
		visitor.position = Vector3(cos(angle) * radius * 0.28, 0.0, sin(angle) * radius * 0.28)
		visitor.set_meta("system_customer_current_floor", floor_number)
		visitor.set_meta("system_customer_current_department", floor_label)
		var customer_id_copy := customer_id
		if is_instance_valid(society):
			var customer: Dictionary = society.call("get_npc", customer_id_copy)
			customer["current_location"] = "%s_floor_%d" % [tower_id, floor_number]
			customer["current_action"] = "visiting_" + floor_label
			customer["last_tower_visit"] = Time.get_datetime_string_from_system()
			society.npcs[customer_id_copy] = customer
		for visitor_child in visitor.get_children():
			if visitor_child.has_method("set_activity"):
				visitor_child.call("set_activity", "wander" if slot == 0 else "socialize")
	if is_instance_valid(society) and society.has_method("save_society"):
		society.call("save_society")


func _move_customer_visitors() -> void:
	for tower_id_value in customer_ids_by_tower.keys():
		var tower_id := str(tower_id_value)
		var config: Dictionary = TOWER_CONFIG.get(tower_id, {})
		var tower := tower_nodes.get(tower_id) as Node3D
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
		if lobby == null:
			continue
		var visitor_parents: Array[Node3D] = [lobby]
		if is_instance_valid(active_floor_root) and str(active_floor_root.get_meta("system_tower_id", "")) == tower_id:
			visitor_parents.append(active_floor_root)
		for visitor_parent in visitor_parents:
			for visitor in visitor_parent.get_children():
				if not str(visitor.name).begins_with("TowerCustomer_"):
					continue
				var radius := float(config.get("radius", 20.0))
				var target_x := randf_range(-radius * 0.42, radius * 0.42)
				var target_z := randf_range(-radius * 0.42, radius * 0.42) if visitor_parent == active_floor_root else radius * 1.48 + randf_range(5.0, 30.0)
				var model: Node = null
				for visitor_child in visitor.get_children():
					if visitor_child.has_method("set_activity"):
						model = visitor_child
						break
				if model != null:
					model.call("set_activity", "walk")
				var tween := create_tween()
				tween.set_trans(Tween.TRANS_SINE)
				tween.set_ease(Tween.EASE_IN_OUT)
				tween.tween_property(visitor, "position", Vector3(target_x, 0.0, target_z), randf_range(3.0, 5.0))
				if model != null:
					tween.finished.connect(func():
						if is_instance_valid(model):
							model.call("set_activity", "socialize")
					)


func _simulate_customer_purchases() -> void:
	for tower_id_value in customer_ids_by_tower.keys():
		var tower_id := str(tower_id_value)
		var catalog: Array = PRODUCT_CATALOG.get(tower_id, [])
		if catalog.is_empty():
			continue
		var customer_ids: Array = customer_ids_by_tower[tower_id]
		if customer_ids.is_empty():
			continue
		var customer_id := str(customer_ids[randi_range(0, customer_ids.size() - 1)])
		var customer: Dictionary = society.call("get_npc", customer_id)
		if customer.is_empty() or not bool(customer.get("alive", false)):
			continue
		var affordable: Array[Dictionary] = []
		for product_value in catalog:
			var product: Dictionary = product_value
			if str(product.get("required_rank", "F")) not in ["F", "E"]:
				continue
			var item_id := str(product.get("id", ""))
			var price := _get_current_price(item_id)
			if price <= float(customer.get("wallet", 0.0)) and get_vendor_stock(item_id) > 0:
				affordable.append(product)
		if affordable.is_empty():
			continue
		var purchased: Dictionary = affordable[randi_range(0, affordable.size() - 1)]
		var purchased_id := str(purchased.get("id", ""))
		var paid := _get_current_price(purchased_id)
		vendor_stock[purchased_id] = maxi(0, get_vendor_stock(purchased_id) - 1)
		customer["wallet"] = maxf(0.0, float(customer.get("wallet", 0.0)) - float(paid))
		customer["last_purchase"] = purchased_id
		customer["last_purchase_price"] = paid
		customer["last_purchase_at"] = Time.get_datetime_string_from_system()
		customer["current_action"] = "shopping"
		customer["current_location"] = tower_id + "_retail_area"
		society.npcs[customer_id] = customer
		var tower := tower_nodes.get(tower_id) as Node3D
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
		if lobby != null:
			var visitor := lobby.get_node_or_null("TowerCustomer_" + customer_id)
			if visitor != null:
				for visitor_child in visitor.get_children():
					if visitor_child.has_method("set_activity"):
						visitor_child.call("set_activity", "eat" if purchased_id.begins_with("restaurant_") else "socialize")
						break
		npc_sales_total += paid
		npc_purchase_count += 1
	_save_vendor_stock()
	_save_npc_sales_ledger()
	if is_instance_valid(society) and society.has_method("save_society"):
		society.call("save_society")

func _create_power_tower_progress_board() -> void:
	var tower := tower_nodes.get("power_tower_baghdad") as Node3D
	if tower == null:
		return
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
	if lobby == null:
		return
	power_tower_progress_board = lobby.get_node_or_null("PowerTowerProgressBoard") as Label3D
	if power_tower_progress_board == null:
		power_tower_progress_board = Label3D.new()
		power_tower_progress_board.name = "PowerTowerProgressBoard"
		power_tower_progress_board.position = Vector3(0.0, 8.2, -6.0)
		power_tower_progress_board.font_size = 26
		power_tower_progress_board.pixel_size = 0.012
		power_tower_progress_board.modulate = Color(1.0, 0.78, 0.36)
		lobby.add_child(power_tower_progress_board)
	_refresh_power_tower_progress_board()


func _refresh_power_tower_progress_board() -> void:
	if not is_instance_valid(power_tower_progress_board) or not is_instance_valid(power_tower_manager):
		return
	var status: Dictionary = power_tower_manager.call("get_tower_status")
	var highest := int(status.get("highest_cleared_floor", 0))
	var next_floor := int(status.get("next_floor", 1))
	var best_time := float(status.get("best_clear_time", 0.0))
	var best_time_text := "%.1f ثانية" % best_time if best_time > 0.0 else "لم يسجل بعد"
	power_tower_progress_board.text = "SYSTEM POWER TOWER\nالطوابق المنجزة: %d / 200\nالطابق التالي: %s\nرتبة التقدم: %s\nأفضل وقت: %s\nالتقدم: %d%%" % [highest, "اكتمل البرج" if next_floor == 0 else str(next_floor), str(status.get("highest_rank", "-")), best_time_text, int(round(float(highest) / 200.0 * 100.0))]


func _create_advertising_surfaces() -> void:
	for tower_id in tower_nodes.keys():
		var tower := tower_nodes[tower_id] as Node3D
		var config: Dictionary = TOWER_CONFIG[tower_id]
		var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
		if lobby != null:
			var inside := Label3D.new()
			inside.name = "NPCManagedInternalCampaign"
			inside.text = "SYSTEM — إعلان داخلي"
			inside.position = Vector3(0.0, 7.5, float(config["radius"]) * 1.48 + 3.0)
			inside.font_size = 26
			inside.pixel_size = 0.012
			inside.modulate = Color(0.5, 0.92, 1.0)
			lobby.add_child(inside)
			ad_labels[tower_id + "_internal"] = inside
		var outside := tower.get_node_or_null("TowerCampaignText") as Label3D
		if outside == null:
			outside = Label3D.new()
			outside.name = "NPCManagedExternalCampaign"
			outside.position = Vector3(0.0, float(config["height"]) * 0.55, float(config["radius"]) + 1.2)
			outside.font_size = 32
			outside.pixel_size = 0.012
			outside.modulate = Color(0.72, 0.96, 1.0)
			tower.add_child(outside)
		ad_labels[tower_id + "_external"] = outside
		tower.set_meta("system_advertising_mode", "npc_staff_managed_local_campaign")
	_refresh_advertisements()

func _refresh_advertisements() -> void:
	for tower_id in tower_nodes.keys():
		var staff_ids: Array = staff_by_tower.get(tower_id, [])
		var manager_name := "فريق الإعلان"
		if not staff_ids.is_empty() and is_instance_valid(society):
			var manager_index := staff_ids.size() - 1
			var npc: Dictionary = society.call("get_npc", str(staff_ids[manager_index]))
			manager_name = str(npc.get("name", manager_name))
		var message := str(AD_CAMPAIGNS[ad_index])
		for suffix in ["_internal", "_external"]:
			var label := ad_labels.get(str(tower_id) + suffix) as Label3D
			if label != null:
				label.text = "SYSTEM | " + message + "\nبإدارة " + manager_name
				label.visible = true

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "BaghdadTowerOperationsUI"
	ui_layer.layer = 35
	add_child(ui_layer)
	panel = PanelContainer.new()
	panel.name = "TowerOperationsPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-235.0, -265.0)
	panel.custom_minimum_size = Vector2(470.0, 530.0)
	panel.visible = false
	ui_layer.add_child(panel)
	get_viewport().size_changed.connect(_resize_panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 23)
	content.add_child(title_label)
	credits_label = Label.new()
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(credits_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): panel.hide())
	content.add_child(close_button)
	_resize_panel()


func _get_responsive_panel_size(viewport_size: Vector2) -> Vector2:
	return Vector2(
		maxf(180.0, minf(470.0, viewport_size.x - 24.0)),
		maxf(180.0, minf(530.0, viewport_size.y - 32.0))
	)


func _resize_panel() -> void:
	if not is_instance_valid(panel):
		return
	var target_size := _get_responsive_panel_size(get_viewport().get_visible_rect().size)
	panel.custom_minimum_size = target_size
	panel.size = target_size
	panel.position = -target_size * 0.5


func _clear_dynamic_controls() -> void:
	catalog_controls = null
	inventory_controls = null
	crafting_controls = null
	for child in content.get_children():
		if child != title_label and child != credits_label and child != status_label:
			child.queue_free()

func open_tower(tower_id: String) -> void:
	if not tower_nodes.has(tower_id):
		return
	current_tower_id = tower_id
	current_staff_id = ""
	var config: Dictionary = TOWER_CONFIG[tower_id]
	_clear_dynamic_controls()
	title_label.text = str(config["title"])
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	status_label.text = "اختر الطابق من المصعد. الطوابق تُنشأ عند الوصول إليها، ولا تُفتح قبل استيفاء شروطها."
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): panel.hide())
	content.add_child(close_button)
	var floor_label := Label.new()
	floor_label.text = "الطابق المطلوب"
	content.add_child(floor_label)
	floor_selector = SpinBox.new()
	floor_selector.min_value = 1
	floor_selector.max_value = int(config["floors"])
	floor_selector.step = 1
	floor_selector.value = 1
	floor_selector.rounded = true
	content.add_child(floor_selector)
	var travel_button := Button.new()
	travel_button.text = "استدعاء المصعد والانتقال"
	travel_button.pressed.connect(_on_travel_button_pressed)
	content.add_child(travel_button)
	var lobby_button := Button.new()
	lobby_button.text = "العودة إلى بهو البرج"
	lobby_button.pressed.connect(return_to_lobby)
	content.add_child(lobby_button)
	if tower_id == "power_tower_baghdad":
		var power_status: Dictionary = power_tower_manager.call("get_tower_status") if is_instance_valid(power_tower_manager) else {}
		status_label.text = "برج مستقل — 200 طابق\nأعلى طابق مكتمل: %d | الطابق التالي: %d\nكل طابق تحدٍ فعلي، والطابق العاشر ومضاعفاته اختبار زعيم." % [int(power_status.get("highest_cleared_floor", 0)), int(power_status.get("next_floor", 1))]
	if tower_id == "hunter_association_tower_baghdad":
		var rank_board_button := Button.new()
		rank_board_button.name = "HunterRankBoardButton"
		rank_board_button.text = "لوحة رتب الصيادين — F إلى SSS"
		rank_board_button.pressed.connect(_open_hunter_rank_board)
		content.add_child(rank_board_button)
		var nen_demo_button := Button.new()
		nen_demo_button.name = "NenTrainingDemoButton"
		nen_demo_button.text = "ساحة استعراض ضربة النِن — تجربة تدريبية"
		nen_demo_button.pressed.connect(_run_nen_training_demo)
		content.add_child(nen_demo_button)
		var nen_note := Label.new()
		nen_note.text = "الأكاسير والأسلحة والدروع والبدلات والمطاعم كلها في برج التسوق والتجارة؛ أما استعراض مهارات النِن فيكون هنا داخل جمعية الصيادين."
		nen_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(nen_note)
	panel.show()


func _open_hunter_rank_board() -> void:
	if not is_instance_valid(progression) or not progression.has_method("get_hunter_rank_progress"):
		_set_status("بيانات تقدم الصياد غير متاحة حالياً.")
		return
	var rank_data: Dictionary = progression.call("get_hunter_rank_progress")
	_clear_dynamic_controls()
	title_label.text = "لوحة رتب نقابة الصيادين"
	credits_label.text = "الرتبة الحالية: %s" % str(rank_data.get("rank", "F"))
	status_label.text = "الترقية تعتمد على المهمات الموثقة وإتقان النِن واستخدام المهارات؛ لا يمكن شراء الرتب أو تجاوز الاختبارات."
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): panel.hide())
	content.add_child(close_button)
	var scroll := ScrollContainer.new()
	scroll.name = "HunterRankProgressScroll"
	scroll.custom_minimum_size = Vector2(0.0, 300.0)
	content.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.name = "HunterRankProgressRows"
	scroll.add_child(rows)
	var rank_order: Array = rank_data.get("rank_order", ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"])
	var current_rank := str(rank_data.get("rank", "F"))
	var mission_points := int(rank_data.get("verified_mission_points", 0))
	var mission_count := int(rank_data.get("verified_mission_count", 0))
	var nen_unlocked_value := bool(rank_data.get("nen_unlocked", false))
	var nen_control := int(rank_data.get("nen_control_rank", 0))
	var nen_uses := int(rank_data.get("nen_skill_uses", 0))
	var distinct_abilities := int(rank_data.get("distinct_nen_abilities", 0))
	var requirements := {
		"F": "رتبة البداية والتسجيل في النقابة",
		"E": "100 نقطة مهمات موثقة",
		"D": "250 نقطة مهمات موثقة",
		"C": "500 نقطة مهمات موثقة",
		"B": "850 نقطة مهمات موثقة",
		"A": "1500 نقطة + إيقاظ النِن + تحكم 2 + استخدام 10 مهارات",
		"S": "2500 نقطة + تحكم نِن 4 + 50 استخداماً + قدرتان مختلفتان",
		"SS": "5000 نقطة + تحكم نِن 5 + 150 استخداماً + 3 قدرات مختلفة",
		"SSS": "اعتماد استثنائي من مجلس نقابة الصيادين بعد تقييم خاص"
	}
	for rank_value in rank_order:
		var rank_name := str(rank_value)
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.text = ("▶ " if rank_name == current_rank else "• ") + rank_name + " — " + str(requirements.get(rank_name, "تقييم النقابة"))
		rows.add_child(row)
	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = "المهمات الموثقة: %d نقطة / %d مهمة\nالنِن: %s | رتبة التحكم: %d\nاستخدام المهارات: %d | قدرات مختلفة: %d\nاعتماد SSS: %s" % [mission_points, mission_count, "مستيقظ" if nen_unlocked_value else "غير مستيقظ", nen_control, nen_uses, distinct_abilities, "موجود" if bool(rank_data.get("sss_board_approved", false)) else "يتطلب قرار المجلس"]
	rows.add_child(details)
	var policy := Label.new()
	policy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	policy.text = "رتبة SSS استثنائية ونادرة جداً؛ لا يستطيع اللاعب منحها لنفسه، ويجب أن يصدر القرار من مجلس النقابة بعد اختبار خاص."
	rows.add_child(policy)
	panel.show()

func _on_travel_button_pressed() -> void:
	if floor_selector == null:
		return
	_travel_to_floor(current_tower_id, int(floor_selector.value))


func _run_nen_training_demo() -> void:
	if current_tower_id != "hunter_association_tower_baghdad":
		return
	if is_instance_valid(progression) and bool(progression.get("nen_unlocked")) and int(progression.get("nen_control_rank")) >= 4:
		var combat_system := get_tree().root.find_child("ModernWorldCombatSystem", true, false)
		if combat_system != null and combat_system.has_method("skill_one"):
			var result: Dictionary = combat_system.call("skill_one")
			if bool(result.get("success", false)):
				_set_status("استعراض فعلي لضربة النِن! هذه مهارة قتالية وليست إكسيراً.")
			else:
				_set_status("تعذر تنفيذ الضربة الآن: " + str(result.get("reason", "النظام مشغول")))
			return
	_spawn_nen_training_preview()
	_set_status("استعراض تدريبي لضربة النِن: عرض للقوة فقط، لا يستهلك إكسيراً ولا يوقظ النِن. إكسير الإيقاظ يُشترى أو يُصنع في برج التسوق والتجارة.")


func _spawn_nen_training_preview() -> void:
	if not is_instance_valid(player) or get_tree().current_scene == null:
		return
	var preview := Node3D.new()
	preview.name = "NenTrainingPreviewEffect"
	get_tree().current_scene.add_child(preview)
	preview.global_position = player.global_position - player.global_transform.basis.z * 2.2 + Vector3.UP * 1.2
	var core := MeshInstance3D.new()
	core.name = "NenEnergyCore"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.72
	core_mesh.height = 1.44
	core.mesh = core_mesh
	var core_material := StandardMaterial3D.new()
	core_material.albedo_color = Color(0.16, 0.72, 1.0, 0.9)
	core_material.emission_enabled = true
	core_material.emission = Color(0.08, 0.52, 1.0)
	core_material.emission_energy_multiplier = 3.5
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.material_override = core_material
	preview.add_child(core)
	var shockwave := MeshInstance3D.new()
	shockwave.name = "NenStrikeShockwave"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.85
	ring.outer_radius = 1.15
	shockwave.mesh = ring
	shockwave.rotation.x = deg_to_rad(90.0)
	shockwave.position.z = -0.35
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.25, 0.85, 1.0, 0.85)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.1, 0.65, 1.0)
	ring_material.emission_energy_multiplier = 4.0
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shockwave.material_override = ring_material
	preview.add_child(shockwave)
	get_tree().create_timer(1.25).timeout.connect(func():
		if is_instance_valid(preview):
			preview.queue_free()
	)



func open_floor_services(tower_id: String, floor_number: int) -> void:
	if not tower_nodes.has(tower_id) or not TOWER_CONFIG.has(tower_id):
		return
	var config: Dictionary = TOWER_CONFIG[tower_id]
	if floor_number < 1 or floor_number > int(config.get("floors", 0)):
		return
	var staff_ids: Array = staff_by_tower.get(tower_id, [])
	if staff_ids.is_empty():
		return
	var tower := tower_nodes.get(tower_id) as Node3D
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
	if lobby == null:
		return
	var staff_index := posmod(floor_number - 1, staff_ids.size())
	var staff_node := lobby.get_node_or_null("TowerStaff_" + str(staff_ids[staff_index]))
	if staff_node == null:
		return
	open_staff_service(staff_node)
	if is_instance_valid(status_label):
		status_label.text = "خدمات %s — الطابق %d\n%s" % [str(config.get("title", "البرج")), floor_number, str(staff_node.get_meta("system_tower_staff_role", "service"))]


func open_staff_service(staff_node: Node) -> void:
	if staff_node == null:
		return
	current_tower_id = str(staff_node.get_meta("system_tower_id", ""))
	current_staff_id = str(staff_node.get_meta("system_tower_staff_id", ""))
	if not tower_nodes.has(current_tower_id):
		return
	var config: Dictionary = TOWER_CONFIG[current_tower_id]
	var staff_name := str(staff_node.get_meta("system_display_name", "موظف"))
	var role := str(staff_node.get_meta("system_tower_staff_role", "service"))
	_clear_dynamic_controls()
	title_label.text = staff_name + " — " + str(config["title"])
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	status_label.text = "خدمة الموظف: " + role
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): panel.hide())
	content.add_child(close_button)
	_add_catalog_controls(current_tower_id)
	_add_crafting_controls(current_tower_id)
	_add_sell_controls()
	if role in ["hospitality_manager", "hotel_receptionist", "hotel_housekeeping"]:
		_add_hotel_controls()
	var elevator_button := Button.new()
	elevator_button.text = "فتح دليل الطوابق والمصعد"
	elevator_button.pressed.connect(func(): open_tower(current_tower_id))
	content.add_child(elevator_button)
	panel.show()

func _add_catalog_controls(tower_id: String) -> void:
	if is_instance_valid(catalog_controls):
		var old_scroll := catalog_controls.get_parent()
		if old_scroll != null:
			old_scroll.queue_free()
	var scroll := ScrollContainer.new()
	scroll.name = "VendorCatalogScroll"
	scroll.custom_minimum_size = Vector2(0.0, 160.0)
	content.add_child(scroll)
	catalog_controls = VBoxContainer.new()
	catalog_controls.name = "VendorCatalogControls"
	scroll.add_child(catalog_controls)
	var catalog: Array = PRODUCT_CATALOG.get(tower_id, [])
	var heading := Label.new()
	heading.text = "المعروض للبيع — بإشراف موظفي البرج"
	catalog_controls.add_child(heading)
	if catalog.is_empty():
		var empty := Label.new()
		empty.text = "لا توجد بضائع معروضة في هذا البرج."
		catalog_controls.add_child(empty)
		return
	for product_value in catalog:
		var product: Dictionary = product_value
		var item_id := str(product["id"])
		var item_name := str(product["name"])
		var price := _get_current_price(item_id)
		var stock := get_vendor_stock(item_id)
		var buy_button := Button.new()
		var required_rank := str(product.get("required_rank", "F"))
		buy_button.text = "%s — %d رصيد | رتبة %s | المخزون: %d" % [item_name, price, required_rank, stock]
		buy_button.disabled = stock <= 0 or not _meets_hunter_rank(required_rank)
		buy_button.pressed.connect(_buy_product.bind(item_id, item_name, price, required_rank))
		catalog_controls.add_child(buy_button)

func _add_crafting_controls(tower_id: String) -> void:
	if tower_id != "shopping_tower_baghdad" or not is_instance_valid(progression) or not progression.has_method("get_crafting_recipe_list"):
		return
	if is_instance_valid(crafting_controls):
		var old_scroll := crafting_controls.get_parent()
		if old_scroll != null:
			old_scroll.queue_free()
	var scroll := ScrollContainer.new()
	scroll.name = "CraftingRecipeScroll"
	scroll.custom_minimum_size = Vector2(0.0, 120.0)
	content.add_child(scroll)
	crafting_controls = VBoxContainer.new()
	crafting_controls.name = "CraftingRecipeControls"
	scroll.add_child(crafting_controls)
	var heading := Label.new()
	heading.text = "ورشة الحدادة ومختبر الإكسير — التصنيع بإشراف الموظفين"
	crafting_controls.add_child(heading)
	var recipes: Dictionary = progression.call("get_crafting_recipe_list")
	for recipe_value in recipes.keys():
		var recipe_id := str(recipe_value)
		var recipe: Dictionary = recipes[recipe_id]
		var ingredients: Dictionary = recipe.get("ingredients", {})
		var parts := PackedStringArray()
		for ingredient_id in ingredients.keys():
			parts.append("%s × %d (لديك %d)" % [str(ingredient_id), int(ingredients[ingredient_id]), int(progression.call("get_item_count", str(ingredient_id)))])
		var craft_button := Button.new()
		var requirements_text := "المستوى: %d" % int(recipe.get("required_level", 1))
		if int(recipe.get("required_nen_rank", 0)) > 0:
			requirements_text += " | رتبة النِن: %d" % int(recipe.get("required_nen_rank", 0))
		craft_button.text = str(recipe.get("name", recipe_id)) + " — " + requirements_text + "\n" + ", ".join(parts)
		craft_button.pressed.connect(_craft_recipe.bind(recipe_id))
		crafting_controls.add_child(craft_button)


func _craft_recipe(recipe_id: String) -> void:
	if not is_instance_valid(progression) or not progression.has_method("craft_recipe"):
		_set_status("نظام التصنيع غير متاح.")
		return
	var result: Dictionary = progression.call("craft_recipe", recipe_id)
	if bool(result.get("success", false)):
		_set_status("اكتمل التصنيع: " + str(result.get("output", recipe_id)))
		_add_crafting_controls(current_tower_id)
		_add_sell_controls()
	else:
		_set_status("تعذر التصنيع: " + str(result.get("reason", "تحقق من المستوى والمواد المطلوبة")))


func _add_sell_controls() -> void:
	if is_instance_valid(inventory_controls):
		var old_scroll := inventory_controls.get_parent()
		if old_scroll != null:
			old_scroll.queue_free()
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.name = "InventoryActionScroll"
	inventory_scroll.custom_minimum_size = Vector2(0.0, 115.0)
	content.add_child(inventory_scroll)
	inventory_controls = VBoxContainer.new()
	inventory_controls.name = "InventoryActionControls"
	inventory_scroll.add_child(inventory_controls)
	var heading := Label.new()
	heading.text = "إدارة الحقيبة — بيع وتجهيز واستخدام"
	inventory_controls.add_child(heading)
	if not is_instance_valid(progression):
		return
	var items: Dictionary = progression.get("inventory_items")
	if items.is_empty():
		var empty := Label.new()
		empty.text = "الحقيبة فارغة حالياً."
		inventory_controls.add_child(empty)
	var equipped_slots: Dictionary = progression.get("equipment_slots")
	for slot_value in equipped_slots.keys():
		var slot := str(slot_value)
		var equipped_item := str(equipped_slots[slot])
		if not equipped_item.is_empty():
			var unequip_button := Button.new()
			unequip_button.text = "إزالة تجهيز %s من خانة %s" % [equipped_item, slot]
			unequip_button.pressed.connect(_unequip_item.bind(slot))
			inventory_controls.add_child(unequip_button)
	for item_value in items.keys():
		var item_id := str(item_value)
		var count := int(items[item_id])
		if count <= 0:
			continue
		var sell_button := Button.new()
		sell_button.text = "بيع %s × %d" % [item_id, count]
		sell_button.pressed.connect(_sell_item.bind(item_id, count))
		inventory_controls.add_child(sell_button)
		if progression.has_method("get_item_equipment_slot"):
			var equipment_slot := str(progression.call("get_item_equipment_slot", item_id))
			if not equipment_slot.is_empty():
				var equip_button := Button.new()
				equip_button.text = "تجهيز %s في خانة %s" % [item_id, equipment_slot]
				equip_button.pressed.connect(_equip_item.bind(item_id))
				inventory_controls.add_child(equip_button)
				var upgrade_level := int(progression.call("get_item_upgrade_level", item_id))
				var durability := float(progression.call("get_item_durability", item_id))
				var upgrade_button := Button.new()
				upgrade_button.text = "ترقية %s — المستوى +%d/10" % [item_id, upgrade_level]
				upgrade_button.disabled = upgrade_level >= 10
				upgrade_button.pressed.connect(_upgrade_item.bind(item_id))
				inventory_controls.add_child(upgrade_button)
				var repair_button := Button.new()
				repair_button.text = "إصلاح %s — المتانة %.0f/100" % [item_id, durability]
				repair_button.disabled = durability >= 99.9
				repair_button.pressed.connect(_repair_item.bind(item_id))
				inventory_controls.add_child(repair_button)
		if item_id.ends_with("_elixir"):
			var elixir_button := Button.new()
			elixir_button.text = "استخدام " + item_id
			elixir_button.pressed.connect(_consume_elixir.bind(item_id))
			inventory_controls.add_child(elixir_button)

func _equip_item(item_id: String) -> void:
	if not is_instance_valid(progression) or not progression.has_method("equip_item"):
		_set_status("نظام التجهيز غير متاح.")
		return
	var result: Dictionary = progression.call("equip_item", item_id)
	if bool(result.get("success", false)):
		var bonuses: Dictionary = progression.call("get_equipment_bonuses")
		_set_status("تم تجهيز %s. زيادة الضرر: +%d | الدفاع: +%d" % [item_id, int(bonuses.get("damage_bonus", 0)), int(bonuses.get("defense_bonus", 0))])
		_add_sell_controls()
	else:
		_set_status("تعذر التجهيز: " + str(result.get("reason", "غير معروف")))

func _unequip_item(slot: String) -> void:
	if not is_instance_valid(progression) or not progression.has_method("unequip_item"):
		return
	if bool(progression.call("unequip_item", slot)):
		_set_status("تمت إزالة التجهيز من خانة " + slot)
		_add_sell_controls()


func _upgrade_item(item_id: String) -> void:
	if not is_instance_valid(progression) or not progression.has_method("upgrade_item"):
		return
	var result: Dictionary = progression.call("upgrade_item", item_id)
	if bool(result.get("success", false)):
		_set_status("تمت ترقية %s إلى المستوى +%d." % [item_id, int(result.get("upgrade_level", 0))])
	else:
		_set_status("تعذرت الترقية: " + str(result.get("reason", "تحقق من المستوى والمواد")))
	_add_sell_controls()


func _repair_item(item_id: String) -> void:
	if not is_instance_valid(progression) or not progression.has_method("repair_item"):
		return
	var result: Dictionary = progression.call("repair_item", item_id)
	if bool(result.get("success", false)):
		_set_status("تم إصلاح %s واستعادة المتانة بالكامل." % item_id)
	else:
		_set_status("تعذر الإصلاح: " + str(result.get("reason", "تحتاج عدة إصلاح")))
	_add_sell_controls()


func _consume_elixir(item_id: String) -> void:
	if not is_instance_valid(progression) or not progression.has_method("consume_elixir"):
		_set_status("نظام الإكسير غير متاح.")
		return
	var result: Dictionary = progression.call("consume_elixir", item_id)
	if bool(result.get("success", false)):
		_set_status("تم استخدام %s بنجاح." % item_id)
		_add_sell_controls()
	else:
		_set_status("تعذر استخدام الإكسير: " + str(result.get("reason", "غير معروف")))

func _buy_product(item_id: String, item_name: String, _listed_price: int, required_rank: String = "F") -> void:
	if not _meets_hunter_rank(required_rank):
		_set_status("هذا التجهيز يتطلب رتبة صياد %s أو أعلى. لا يمكن تجاوز الرتبة بالشراء." % required_rank)
		return
	var stock := get_vendor_stock(item_id)
	if stock <= 0:
		_set_status("نفد مخزون هذا المنتج. سيعيد الموظفون تعبئته بعد دورة التوريد.")
		return
	var price := _get_current_price(item_id)
	if credits < price:
		_set_status("رصيدك غير كافٍ لشراء " + item_name)
		return
	if not is_instance_valid(progression) or not progression.has_method("add_item"):
		_set_status("الحقيبة غير متاحة حالياً.")
		return
	credits -= price
	vendor_stock[item_id] = stock - 1
	_save_vendor_stock()
	progression.call("add_item", item_id, 1)
	_save_wallet()
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	_set_status("تم شراء %s من موظف البرج وإضافته إلى حقيبتك. السعر الحالي: %d" % [item_name, price])
	_add_catalog_controls(current_tower_id)
	if current_tower_id == "shopping_tower_baghdad":
		_add_crafting_controls(current_tower_id)
	_add_sell_controls()


func _meets_hunter_rank(required_rank: String) -> bool:
	if required_rank.is_empty() or required_rank == "F":
		return true
	if not is_instance_valid(progression) or not progression.has_method("get_hunter_rank_progress"):
		return false
	var rank_data: Dictionary = progression.call("get_hunter_rank_progress")
	var order: Array = rank_data.get("rank_order", ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"])
	var current_index := order.find(str(rank_data.get("rank", "F")))
	var required_index := order.find(required_rank)
	return current_index >= 0 and required_index >= 0 and current_index >= required_index

func _sell_item(item_id: String, requested_count: int) -> void:
	if not is_instance_valid(progression):
		return
	if progression.has_method("is_item_equipped") and bool(progression.call("is_item_equipped", item_id)):
		_set_status("لا يمكن بيع غرض مجهّز. أزل تجهيزه أولاً.")
		return
	var items: Dictionary = progression.get("inventory_items")
	var available := int(items.get(item_id, 0))
	var quantity := mini(available, requested_count)
	if quantity <= 0:
		_set_status("لم تعد هذه الكمية متوفرة في الحقيبة.")
		return
	var unit_price := _item_resale_price(item_id)
	items[item_id] = available - quantity
	if int(items[item_id]) <= 0:
		items.erase(item_id)
	progression.set("inventory_items", items)
	if progression.has_method("save_progress"):
		progression.call("save_progress")
	credits += unit_price * quantity
	if vendor_stock.has(item_id):
		vendor_stock[item_id] = mini(_get_stock_cap(item_id), get_vendor_stock(item_id) + quantity)
		_save_vendor_stock()
	_save_wallet()
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	_set_status("اشترى الموظف %d من %s مقابل %d رصيد." % [quantity, item_id, unit_price * quantity])
	_add_catalog_controls(current_tower_id)
	_add_sell_controls()

func _load_hotel_bookings() -> void:
	var config := ConfigFile.new()
	if config.load(HOTEL_SAVE_PATH) != OK:
		hotel_bookings = {}
		return
	var saved: Variant = config.get_value("hotel", "bookings", {})
	hotel_bookings = saved.duplicate(true) if saved is Dictionary else {}


func _save_hotel_bookings() -> void:
	var config := ConfigFile.new()
	config.set_value("hotel", "bookings", hotel_bookings)
	var result := config.save(HOTEL_SAVE_PATH)
	if result != OK:
		push_warning("SYSTEM Hotel: could not persist room reservations.")


func _get_active_hotel_booking() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	for room_id in hotel_bookings.keys():
		var booking: Dictionary = hotel_bookings[room_id]
		if str(booking.get("guest_id", "")) == "local_player" and int(booking.get("check_out_unix", 0)) > now:
			return booking
	return {}


func _is_hotel_room_available(room_id: String) -> bool:
	var booking: Dictionary = hotel_bookings.get(room_id, {})
	if booking.is_empty():
		return true
	var status := str(booking.get("status", ""))
	if status == "ready":
		return true
	var checkout_unix := int(booking.get("check_out_unix", 0))
	if status in ["reserved", "checked_in"] and checkout_unix > 0 and checkout_unix <= int(Time.get_unix_time_from_system()):
		booking["guest_id"] = ""
		booking["status"] = "needs_cleaning"
		booking["check_in_unix"] = 0
		booking["housekeeping_started_unix"] = 0
		booking["housekeeping_completed_unix"] = 0
		booking["inspection_passed"] = false
		hotel_bookings[room_id] = booking
		_save_hotel_bookings()
	return false


func _add_hotel_controls() -> void:
	var previous := content.get_node_or_null("HotelReservationControls")
	if previous != null:
		previous.queue_free()
	var controls := VBoxContainer.new()
	controls.name = "HotelReservationControls"
	content.add_child(controls)
	var heading := Label.new()
	heading.text = "فندق SYSTEM — الحجز والإقامة"
	controls.add_child(heading)
	var active := _get_active_hotel_booking()
	if not active.is_empty():
		var room_name := str(active.get("room_name", "غرفة فندقية"))
		var checkout_time := Time.get_datetime_string_from_unix_time(int(active.get("check_out_unix", 0)), true)
		var active_label := Label.new()
		active_label.text = "حجزك الحالي: %s\nموعد انتهاء الإقامة: %s\nالحالة: %s" % [room_name, checkout_time, "تم تسجيل الدخول" if int(active.get("check_in_unix", 0)) > 0 else "بانتظار تسجيل الدخول"]
		controls.add_child(active_label)
		if int(active.get("check_in_unix", 0)) == 0:
			var check_in_button := Button.new()
			check_in_button.text = "تسجيل الدخول إلى الغرفة"
			check_in_button.pressed.connect(_check_in_hotel_room)
			controls.add_child(check_in_button)
		if int(active.get("check_in_unix", 0)) > 0:
			_add_hotel_room_service_controls(controls, active)
		var checkout_button := Button.new()
		checkout_button.text = "تسجيل الخروج وإنهاء الإقامة"
		checkout_button.pressed.connect(_checkout_hotel_room)
		controls.add_child(checkout_button)
		return
	var hint := Label.new()
	hint.text = "اختر الغرفة ومدة الإقامة. الأجنحة الخاصة تتطلب رتبة صياد مناسبة."
	controls.add_child(hint)
	var housekeeping_heading := Label.new()
	housekeeping_heading.text = "إدارة تجهيز الغرف — التنظيف والفحص"
	controls.add_child(housekeeping_heading)
	for room_id_value in hotel_bookings.keys():
		var room_id := str(room_id_value)
		var room_state: Dictionary = hotel_bookings[room_id]
		var room_status := str(room_state.get("status", ""))
		if room_status not in ["needs_cleaning", "cleaning"]:
			continue
		var state_label := Label.new()
		state_label.text = "%s — %s" % [str(room_state.get("room_name", room_id)), "بانتظار التنظيف" if room_status == "needs_cleaning" else "قيد التنظيف"]
		controls.add_child(state_label)
		var housekeeping_button := Button.new()
		if room_status == "needs_cleaning":
			housekeeping_button.text = "بدء تنظيف " + str(room_state.get("room_name", room_id))
			housekeeping_button.pressed.connect(_start_hotel_room_cleaning.bind(room_id))
		else:
			housekeeping_button.text = "إنهاء التنظيف وفحص " + str(room_state.get("room_name", room_id))
			housekeeping_button.pressed.connect(_complete_hotel_room_cleaning.bind(room_id))
		controls.add_child(housekeeping_button)
	for room_value in HOTEL_ROOM_CATALOG:
		var room: Dictionary = room_value
		var room_id := str(room["id"])
		var room_name := str(room["name"])
		var rate := int(room["rate"])
		var required_rank := str(room["required_rank"])
		if not _is_hotel_room_available(room_id):
			var occupied := Label.new()
			occupied.text = "%s — محجوز حالياً" % room_name
			controls.add_child(occupied)
			continue
		var room_label := Label.new()
		room_label.text = "%s — %d رصيد/ليلة — رتبة %s" % [room_name, rate, required_rank]
		controls.add_child(room_label)
		for nights in [1, 3, 7]:
			var booking_button := Button.new()
			booking_button.text = "حجز %d ليلة — %d رصيد" % [nights, rate * nights]
			booking_button.disabled = not _meets_hunter_rank(required_rank) or credits < rate * nights
			booking_button.pressed.connect(_book_hotel_room.bind(room_id, room_name, rate, required_rank, nights))
			controls.add_child(booking_button)


func _add_hotel_room_service_controls(parent: VBoxContainer, booking: Dictionary) -> void:
	var heading := Label.new()
	heading.text = "خدمة الغرف — طلب الطعام والشراب"
	parent.add_child(heading)
	var menu := [
		{"id": "restaurant_baghdad_breakfast", "name": "فطور بغدادي", "price": 42},
		{"id": "restaurant_kebab", "name": "كباب عراقي", "price": 68},
		{"id": "restaurant_masگوف", "name": "مسگوف", "price": 95},
		{"id": "restaurant_fresh_juice", "name": "عصير طازج", "price": 22},
		{"id": "restaurant_specialty_coffee", "name": "قهوة مختصة", "price": 28},
		{"id": "restaurant_dessert", "name": "حلويات شرقية", "price": 30}
	]
	for item in menu:
		var order_button := Button.new()
		order_button.text = "طلب %s — %d رصيد" % [str(item.name), int(item.price)]
		order_button.disabled = credits < int(item.price)
		order_button.pressed.connect(_place_hotel_room_service_order.bind(str(item.id), str(item.name), int(item.price)))
		parent.add_child(order_button)
	var orders: Array = booking.get("room_service_orders", [])
	for index in range(orders.size()):
		var order: Dictionary = orders[index]
		var state := str(order.get("status", "placed"))
		var order_label := Label.new()
		var state_labels := {"placed": "تم استلام الطلب", "preparing": "قيد التحضير", "delivered": "تم التوصيل"}
		order_label.text = "%s — %s" % [str(order.get("item_name", "طلب")), str(state_labels.get(state, state))]
		parent.add_child(order_label)
		if state == "placed":
			var prepare_button := Button.new()
			prepare_button.text = "بدء تحضير الطلب"
			prepare_button.pressed.connect(_update_hotel_room_service_order.bind(index, "preparing"))
			parent.add_child(prepare_button)
		elif state == "preparing":
			var deliver_button := Button.new()
			deliver_button.text = "تأكيد توصيل الطلب إلى الغرفة"
			deliver_button.pressed.connect(_update_hotel_room_service_order.bind(index, "delivered"))
			parent.add_child(deliver_button)


func _place_hotel_room_service_order(item_id: String, item_name: String, price: int) -> void:
	var booking := _get_active_hotel_booking()
	if booking.is_empty() or int(booking.get("check_in_unix", 0)) <= 0:
		_set_status("يجب تسجيل الدخول إلى الفندق قبل طلب خدمة الغرف.")
		return
	if price <= 0 or credits < price:
		_set_status("رصيدك لا يكفي لطلب خدمة الغرف.")
		return
	var room_id := str(booking.get("room_id", ""))
	if not hotel_bookings.has(room_id):
		return
	credits -= price
	var stored: Dictionary = hotel_bookings[room_id]
	var orders: Array = stored.get("room_service_orders", [])
	orders.append({"item_id": item_id, "item_name": item_name, "price": price, "status": "placed", "ordered_at_unix": int(Time.get_unix_time_from_system())})
	stored["room_service_orders"] = orders
	hotel_bookings[room_id] = stored
	_save_hotel_bookings()
	_save_wallet()
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	_set_status("وصل طلب %s إلى موظف خدمة الغرف. تمت إضافة قيمته إلى الفاتورة." % item_name)
	_add_hotel_controls()


func _update_hotel_room_service_order(order_index: int, next_status: String) -> void:
	if next_status not in ["preparing", "delivered"]:
		return
	var booking := _get_active_hotel_booking()
	if booking.is_empty():
		return
	var room_id := str(booking.get("room_id", ""))
	if not hotel_bookings.has(room_id):
		return
	var stored: Dictionary = hotel_bookings[room_id]
	var orders: Array = stored.get("room_service_orders", [])
	if order_index < 0 or order_index >= orders.size():
		return
	var order: Dictionary = orders[order_index]
	var current := str(order.get("status", "placed"))
	if (next_status == "preparing" and current != "placed") or (next_status == "delivered" and current != "preparing"):
		return
	order["status"] = next_status
	order["updated_at_unix"] = int(Time.get_unix_time_from_system())
	orders[order_index] = order
	stored["room_service_orders"] = orders
	hotel_bookings[room_id] = stored
	_save_hotel_bookings()
	_set_status("تم تحديث حالة طلب خدمة الغرف.")
	_add_hotel_controls()


func _book_hotel_room(room_id: String, room_name: String, nightly_rate: int, required_rank: String, nights: int) -> void:
	if not _get_active_hotel_booking().is_empty():
		_set_status("لديك حجز فندقي نشط بالفعل. أنهِ الإقامة الحالية أولاً.")
		return
	if not _meets_hunter_rank(required_rank):
		_set_status("هذا النوع من الغرف يتطلب رتبة %s أو أعلى." % required_rank)
		return
	if not _is_hotel_room_available(room_id):
		_set_status("هذه الغرفة محجوزة حالياً. اختر غرفة أخرى.")
		return
	var safe_nights := clampi(nights, 1, 7)
	var total_price := nightly_rate * safe_nights
	if credits < total_price:
		_set_status("رصيدك لا يكفي لإتمام حجز الفندق.")
		return
	credits -= total_price
	var now := int(Time.get_unix_time_from_system())
	hotel_bookings[room_id] = {
		"room_id": room_id,
		"room_name": room_name,
		"guest_id": "local_player",
		"nightly_rate": nightly_rate,
		"nights": safe_nights,
		"booked_at_unix": now,
		"check_in_unix": 0,
		"check_out_unix": now + safe_nights * 86400,
		"status": "reserved"
	}
	_save_hotel_bookings()
	_save_wallet()
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	_set_status("تم حجز %s لمدة %d ليلة. راجع موظف الاستقبال لتسجيل الدخول." % [room_name, safe_nights])
	_add_hotel_controls()


func _check_in_hotel_room() -> void:
	var booking := _get_active_hotel_booking()
	if booking.is_empty():
		_set_status("لا يوجد حجز نشط لتسجيل الدخول.")
		return
	var room_id := str(booking.get("room_id", ""))
	if not hotel_bookings.has(room_id):
		return
	var stored: Dictionary = hotel_bookings[room_id]
	stored["check_in_unix"] = int(Time.get_unix_time_from_system())
	stored["status"] = "checked_in"
	hotel_bookings[room_id] = stored
	_save_hotel_bookings()
	_set_status("تم تسجيل الدخول إلى " + str(stored.get("room_name", "الغرفة")) + ". نتمنى لك إقامة سعيدة.")
	_add_hotel_controls()


func _checkout_hotel_room() -> void:
	var booking := _get_active_hotel_booking()
	if booking.is_empty():
		_set_status("لا يوجد حجز نشط لتسجيل الخروج.")
		return
	var room_id := str(booking.get("room_id", ""))
	var checkout_unix := int(booking.get("check_out_unix", 0))
	var remaining_nights := maxi(0, int(ceil(float(checkout_unix - int(Time.get_unix_time_from_system())) / 86400.0)) - 1)
	var refund := remaining_nights * int(booking.get("nightly_rate", 0))
	credits += refund
	var released_room: Dictionary = hotel_bookings.get(room_id, {}).duplicate(true)
	released_room["guest_id"] = ""
	released_room["check_in_unix"] = 0
	released_room["check_out_unix"] = 0
	released_room["status"] = "needs_cleaning"
	released_room["housekeeping_started_unix"] = 0
	released_room["housekeeping_completed_unix"] = 0
	released_room["inspection_passed"] = false
	hotel_bookings[room_id] = released_room
	_save_hotel_bookings()
	_save_wallet()
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	_set_status("تم تسجيل الخروج. أُعيد إلى رصيدك %d عن الليالي غير المستخدمة. الغرفة الآن بانتظار فريق التنظيف والفحص." % refund)
	_add_hotel_controls()


func _start_hotel_room_cleaning(room_id: String) -> void:
	if not hotel_bookings.has(room_id):
		_set_status("سجل الغرفة غير موجود.")
		return
	var room: Dictionary = hotel_bookings[room_id]
	if str(room.get("status", "")) != "needs_cleaning":
		_set_status("هذه الغرفة ليست بانتظار التنظيف.")
		return
	room["status"] = "cleaning"
	room["housekeeping_started_unix"] = int(Time.get_unix_time_from_system())
	hotel_bookings[room_id] = room
	_save_hotel_bookings()
	_set_status("بدأ فريق التدبير الفندقي تنظيف %s. بعده يلزم فحص الغرفة." % str(room.get("room_name", room_id)))
	_add_hotel_controls()


func _complete_hotel_room_cleaning(room_id: String) -> void:
	if not hotel_bookings.has(room_id):
		_set_status("سجل الغرفة غير موجود.")
		return
	var room: Dictionary = hotel_bookings[room_id]
	if str(room.get("status", "")) != "cleaning":
		_set_status("يجب بدء تنظيف الغرفة قبل إكماله.")
		return
	var now := int(Time.get_unix_time_from_system())
	room["status"] = "ready"
	room["housekeeping_completed_unix"] = now
	room["inspection_unix"] = now
	room["inspection_passed"] = true
	hotel_bookings[room_id] = room
	_save_hotel_bookings()
	_set_status("اكتمل تنظيف وفحص %s. أصبحت الغرفة جاهزة للحجز." % str(room.get("room_name", room_id)))
	_add_hotel_controls()


func _item_resale_price(item_id: String) -> int:
	return maxi(1, int(_get_current_price(item_id) / 2))

func _set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message

func _load_wallet() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		credits = maxi(0, int(config.get_value("wallet", "credits", 1200)))

func _save_wallet() -> void:
	var config := ConfigFile.new()
	config.set_value("wallet", "credits", credits)
	config.save(SAVE_PATH)

func _load_vendor_stock() -> void:
	var config := ConfigFile.new()
	if config.load(STOCK_SAVE_PATH) == OK:
		vendor_stock = config.get_value("vendors", "stock", {}).duplicate(true)
	for tower_id in PRODUCT_CATALOG.keys():
		for product_value in PRODUCT_CATALOG[tower_id]:
			var product: Dictionary = product_value
			var item_id := str(product["id"])
			if not vendor_stock.has(item_id):
				vendor_stock[item_id] = _get_stock_cap(item_id)
	_save_vendor_stock()


func _save_vendor_stock() -> void:
	var config := ConfigFile.new()
	config.set_value("vendors", "stock", vendor_stock.duplicate(true))
	config.save(STOCK_SAVE_PATH)


func _get_stock_cap(item_id: String) -> int:
	if item_id in ["rare_legendary_elixir", "rare_core"]:
		return 3
	if item_id in ["nen_awakening_elixir", "nen_acquisition_elixir", "nen_control_elixir", "nen_fragment", "sovereign_core"]:
		return 8
	if item_id in ["iron_ingot", "wood_plank", "leather_roll", "medicinal_herb", "crystal_dust", "monster_core", "energy_crystal"]:
		return 60
	return 25


func get_vendor_stock(item_id: String) -> int:
	return int(vendor_stock.get(item_id, 0))


func _get_current_price(item_id: String) -> int:
	var base_price := 10
	for tower_id in PRODUCT_CATALOG.keys():
		for product_value in PRODUCT_CATALOG[tower_id]:
			var product: Dictionary = product_value
			if str(product["id"]) == item_id:
				base_price = int(product["price"])
				break
	var stock := get_vendor_stock(item_id)
	var cap := _get_stock_cap(item_id)
	if stock <= 2:
		return maxi(1, int(round(float(base_price) * 1.35)))
	if stock >= int(float(cap) * 0.75):
		return maxi(1, int(round(float(base_price) * 0.9)))
	return base_price


func _restock_vendor_stock() -> void:
	for item_id in vendor_stock.keys():
		var item_key := str(item_id)
		var increment := 2 if _get_stock_cap(item_key) <= 8 else 8
		vendor_stock[item_key] = mini(_get_stock_cap(item_key), int(vendor_stock[item_key]) + increment)
	_save_vendor_stock()
	if current_tower_id in PRODUCT_CATALOG:
		_add_catalog_controls(current_tower_id)
		_set_status("وصلت شحنة جديدة إلى مخازن البرج. تم تحديث الأسعار والكميات.")


func _prepare_tower_interior(tower_id: String) -> void:
	if prepared_towers.has(tower_id):
		return
	var tower := tower_nodes.get(tower_id) as Node3D
	if tower == null:
		return
	var config: Dictionary = TOWER_CONFIG[tower_id]
	var radius := float(config["radius"])
	var height := float(config["height"])
	var structure := tower.get_node_or_null("TowerStructureCollision")
	if structure != null:
		for child in structure.get_children():
			if child is CollisionShape3D and child.shape is CylinderShape3D:
				var cylinder := child.shape as CylinderShape3D
				if cylinder.height > height * 0.8:
					child.disabled = true
	var boundary := StaticBody3D.new()
	boundary.name = "TowerInteriorBoundary"
	tower.add_child(boundary)
	for segment in range(24):
		var angle := TAU * float(segment) / 24.0
		var shape_node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(radius * 2.0 * PI / 24.0 * 1.15, height, 1.4)
		shape_node.shape = box
		shape_node.position = Vector3(cos(angle) * radius * 0.86, height * 0.5 + 7.0, sin(angle) * radius * 0.86)
		shape_node.rotation.y = -angle
		boundary.add_child(shape_node)
	var inner_wall := MeshInstance3D.new()
	inner_wall.name = "TowerInteriorInnerWall"
	var wall_mesh := CylinderMesh.new()
	wall_mesh.top_radius = radius * 0.88
	wall_mesh.bottom_radius = radius * 0.88
	wall_mesh.height = height
	inner_wall.mesh = wall_mesh
	inner_wall.position.y = height * 0.5 + 7.0
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.045, 0.11, 0.15)
	wall_material.metallic = 0.62
	wall_material.roughness = 0.35
	wall_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	inner_wall.material_override = wall_material
	tower.add_child(inner_wall)
	var floor_container := Node3D.new()
	floor_container.name = "TowerInteriorFloors"
	tower.add_child(floor_container)
	prepared_towers[tower_id] = floor_container

func _ensure_floor_room(tower_id: String, floor_number: int) -> Node3D:
	_prepare_tower_interior(tower_id)
	var floors := prepared_towers.get(tower_id) as Node3D
	if floors == null:
		return null
	var room_name := "InteriorFloor_%03d" % floor_number
	var existing := floors.get_node_or_null(room_name) as Node3D
	if existing != null:
		return existing
	var tower := tower_nodes.get(tower_id) as Node3D
	var config: Dictionary = TOWER_CONFIG[tower_id]
	var height := float(config["height"])
	var radius := float(config["radius"])
	var count := int(config["floors"])
	var floor_y := 9.0 + (height - 16.0) * float(floor_number - 1) / float(maxi(count - 1, 1))
	var room := Node3D.new()
	room.name = room_name
	room.position.y = floor_y
	floors.add_child(room)
	var body := StaticBody3D.new()
	body.name = "FloorCollision"
	room.add_child(body)
	var floor_visual := MeshInstance3D.new()
	floor_visual.name = "FloorDeck"
	var deck := CylinderMesh.new()
	deck.top_radius = radius * 0.82
	deck.bottom_radius = radius * 0.82
	deck.height = 0.8
	floor_visual.mesh = deck
	floor_visual.position.y = 0.0
	var deck_material := StandardMaterial3D.new()
	deck_material.albedo_color = Color(0.12, 0.17, 0.21)
	deck_material.metallic = 0.38
	deck_material.roughness = 0.48
	floor_visual.material_override = deck_material
	room.add_child(floor_visual)
	var deck_collision := CollisionShape3D.new()
	var deck_shape := CylinderShape3D.new()
	deck_shape.radius = radius * 0.82
	deck_shape.height = 0.8
	deck_collision.shape = deck_shape
	body.add_child(deck_collision)
	for segment in range(20):
		if segment == 0:
			continue
		var angle := TAU * float(segment) / 20.0
		var wall_mesh_instance := MeshInstance3D.new()
		wall_mesh_instance.name = "InteriorWall_%02d" % segment
		var wall_mesh := BoxMesh.new()
		var arc_width := radius * 2.0 * PI / 20.0 * 0.9
		wall_mesh.size = Vector3(arc_width, 5.2, 0.8)
		wall_mesh_instance.mesh = wall_mesh
		wall_mesh_instance.position = Vector3(cos(angle) * radius * 0.80, 2.6, sin(angle) * radius * 0.80)
		wall_mesh_instance.rotation.y = -angle
		wall_mesh_instance.material_override = deck_material
		room.add_child(wall_mesh_instance)
		var wall_collision := CollisionShape3D.new()
		var wall_shape := BoxShape3D.new()
		wall_shape.size = wall_mesh.size
		wall_collision.shape = wall_shape
		wall_collision.position = wall_mesh_instance.position
		wall_collision.rotation = wall_mesh_instance.rotation
		body.add_child(wall_collision)
	var department := _department_for_floor(tower_id, floor_number, count)
	var sign := Label3D.new()
	sign.name = "FloorDepartmentSign"
	sign.text = "%s\nالطابق %d / %d" % [department, floor_number, count]
	sign.position = Vector3(0.0, 3.4, -radius * 0.55)
	sign.font_size = 34
	sign.pixel_size = 0.012
	sign.modulate = Color(0.8, 0.94, 1.0)
	room.add_child(sign)
	var elevator_marker := Area3D.new()
	elevator_marker.name = "ElevatorReturnMarker"
	elevator_marker.add_to_group("system_interactable")
	elevator_marker.set_meta("system_tower_id", tower_id)
	elevator_marker.set_meta("system_tower_elevator_panel", true)
	elevator_marker.set_meta("system_interaction_prompt", "مصعد البرج — العودة إلى البهو")
	var marker_shape := CollisionShape3D.new()
	var marker_sphere := SphereShape3D.new()
	marker_sphere.radius = 2.2
	marker_shape.shape = marker_sphere
	elevator_marker.add_child(marker_shape)
	elevator_marker.position = Vector3(0.0, 1.1, radius * 0.36)
	room.add_child(elevator_marker)
	if tower_id == "power_tower_baghdad":
		room.set_meta("system_power_tower_floor", floor_number)
		room.set_meta("system_power_tower_department", "arena")
		_create_power_arena_layout(room, radius, floor_number)
	else:
		_create_floor_facilities(room, tower_id, floor_number, radius, department)
		TowerFloorThemeBuilder.build(room, tower_id, floor_number, radius, department)
	return room


func _create_power_arena_layout(room: Node3D, radius: float, floor_number: int) -> void:
	var data: Dictionary = power_tower_manager.call("get_floor_data", floor_number) if is_instance_valid(power_tower_manager) else {}
	var arena_type := str(data.get("arena_type", "DUEL"))
	var rules := str(data.get("arena_rules", "اهزم خصوم الطابق"))
	room.set_meta("system_power_tower_arena_type", arena_type)
	room.set_meta("system_power_tower_rules", rules)
	var arena_label := Label3D.new()
	arena_label.name = "ArenaChallengeDisplay"
	arena_label.text = "%s\nالطابق %d\n%s" % [str(data.get("arena_name", "POWER ARENA")), floor_number, rules]
	arena_label.position = Vector3(0.0, 5.4, -radius * 0.48)
	arena_label.font_size = 22
	arena_label.pixel_size = 0.014
	arena_label.modulate = Color(1.0, 0.78, 0.42)
	room.add_child(arena_label)
	var objective_label := Label3D.new()
	objective_label.name = "PowerTowerObjectiveLabel"
	objective_label.position = Vector3(0.0, 7.0, radius * 0.20)
	objective_label.font_size = 20
	objective_label.pixel_size = 0.013
	objective_label.modulate = Color(0.50, 0.94, 1.0)
	room.add_child(objective_label)
	var obstacle_count := 2
	match arena_type:
		"TEAM":
			obstacle_count = 6
		"SURVIVAL":
			obstacle_count = 8
		"ELITE":
			obstacle_count = 5
		"CHAMPIONSHIP":
			obstacle_count = 4
		"BOSS_TRIAL":
			obstacle_count = 8
		_:
			obstacle_count = 2
	var obstacle_material := StandardMaterial3D.new()
	obstacle_material.albedo_color = Color(0.20, 0.24, 0.29) if arena_type != "BOSS_TRIAL" else (Color(0.68, 0.43, 0.08) if bool(data.get("final_boss", false)) else Color(0.34, 0.075, 0.045))
	obstacle_material.metallic = 0.62
	obstacle_material.roughness = 0.36
	for index in range(obstacle_count):
		var angle := TAU * float(index) / float(maxi(obstacle_count, 1))
		var obstacle := MeshInstance3D.new()
		obstacle.name = "ArenaObstacle_%02d" % index
		var obstacle_mesh := BoxMesh.new()
		var obstacle_size := Vector3(2.4, 3.2, 1.2)
		if arena_type == "BOSS_TRIAL":
			obstacle_size = Vector3(2.0, 5.0, 2.0)
		elif arena_type == "SURVIVAL":
			obstacle_size = Vector3(3.2, 2.0, 1.0)
		obstacle_mesh.size = obstacle_size
		obstacle.mesh = obstacle_mesh
		obstacle.position = Vector3(cos(angle) * radius * 0.43, obstacle_size.y * 0.5, sin(angle) * radius * 0.43)
		obstacle.rotation.y = -angle
		obstacle.material_override = obstacle_material
		room.add_child(obstacle)
		var collision_body := StaticBody3D.new()
		collision_body.name = "ArenaObstacleCollision_%02d" % index
		room.add_child(collision_body)
		var collision := CollisionShape3D.new()
		var collision_shape := BoxShape3D.new()
		collision_shape.size = obstacle_size
		collision.shape = collision_shape
		collision.position = obstacle.position
		collision.rotation = obstacle.rotation
		collision_body.add_child(collision)
	if arena_type == "BOSS_TRIAL":
		var boss_platform := MeshInstance3D.new()
		boss_platform.name = "BossTrialPlatform"
		var platform_mesh := CylinderMesh.new()
		platform_mesh.top_radius = 8.0 if bool(data.get("final_boss", false)) else 6.0
		platform_mesh.bottom_radius = 8.5 if bool(data.get("final_boss", false)) else 6.5
		platform_mesh.height = 0.8
		boss_platform.mesh = platform_mesh
		boss_platform.position.y = 0.8
		boss_platform.material_override = obstacle_material
		room.add_child(boss_platform)


func _department_for_floor(tower_id: String, floor_number: int, total: int) -> String:
	var ratio := float(floor_number) / float(maxi(total, 1))
	match tower_id:
		"shopping_tower_baghdad":
			if floor_number >= 29: return "المطاعم الراقية وصالات الطعام والمقاهي"
			if floor_number >= 27: return "فندق SYSTEM — الاستقبال والأجنحة والغرف الفندقية"
			if ratio > 0.90: return "المطاعم الراقية وصالات الطعام والمقاهي"
			if ratio > 0.80: return "مطاعم الوجبات السريعة والحلويات والمشروبات"
			if ratio > 0.68: return "مخزن الإكسير النادر والأسطوري — وصول مقيّد"
			if ratio > 0.58: return "مختبر النِن وتحضير الأكاسير والعلاج"
			if ratio > 0.46: return "صيدلية الإكسير والشفاء والطاقة"
			if ratio > 0.34: return "الدروع والخوذ والبدلات حسب رتب الصيادين"
			if ratio > 0.20: return "معرض الأسلحة الحديثة والسيوف والأقواس والسهام"
			return "الردهة التجارية والأسواق والاحتياجات اليومية"
		"business_investment_tower_baghdad":
			if floor_number == 8: return "قاعة التداول والبورصة"
			if floor_number == 16: return "مركز المؤتمرات والاجتماعات"
			if floor_number == 24: return "نادي المستثمرين وصالة الأعمال"
			if ratio > 0.8: return "مكاتب الاستثمار والشركات الكبرى"
			if ratio > 0.55: return "البنوك والتمويل والعقود التجارية"
			if ratio > 0.3: return "مكاتب تأسيس الشركات والتوظيف"
			return "ردهة الأعمال والاستشارات"
		"entertainment_tower_baghdad":
			if floor_number in [18, 19, 20]: return "المسابح والمنتجع المائي"
			if floor_number == 21: return "النادي الرياضي واللياقة"
			if floor_number == 22: return "الملاعب والأنشطة الجماعية"
			if floor_number == 23: return "البولينغ والألعاب"
			if floor_number == 24: return "السينما والعروض"
			if floor_number == 25: return "الألعاب الإلكترونية"
			if floor_number == 26: return "منطقة العائلات والأطفال"
			if floor_number >= 33: return "حدائق السطح والفعاليات المفتوحة"
			if ratio > 0.8: return "المهرجانات والفعاليات"
			if ratio > 0.55: return "الرياضة والترفيه"
			if ratio > 0.3: return "الأنشطة العائلية"
			return "مركز الترفيه"
		"technology_tower_baghdad":
			if ratio > 0.75: return "مختبرات الابتكار المتقدم"
			if ratio > 0.5: return "الروبوتات والهندسة"
			if ratio > 0.25: return "الخدمات الرقمية"
			return "معارض التكنولوجيا"
		"hunter_association_tower_baghdad":
			if ratio > 0.85: return "قاعة الشرف والسجل العالمي"
			if ratio > 0.65: return "إدارة الاختبار العالمي"
			if ratio > 0.4: return "قاعات التدريب والبحث"
			if ratio > 0.2: return "مكاتب المهمات والنقابات"
			return "الاستقبال وتسجيل الصيادين"
		_:
			return "حلبة التحديات — " + str(floor_number)

func _create_floor_facilities(room: Node3D, tower_id: String, floor_number: int, radius: float, department: String) -> void:
	for index in range(3):
		var kiosk := Node3D.new()
		kiosk.name = "ServiceKiosk_%d" % index
		kiosk.position = Vector3((float(index) - 1.0) * radius * 0.35, 0.0, -radius * 0.2)
		room.add_child(kiosk)
		var plinth := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.2, 1.5, 1.4)
		plinth.mesh = mesh
		plinth.position.y = 0.75
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.10, 0.28, 0.36)
		material.metallic = 0.5
		plinth.material_override = material
		kiosk.add_child(plinth)
		var label := Label3D.new()
		label.text = department
		label.position.y = 2.2
		label.font_size = 16
		label.pixel_size = 0.012
		kiosk.add_child(label)
		var kiosk_area := Area3D.new()
		kiosk_area.name = "TowerServiceInteraction"
		kiosk_area.add_to_group("system_interactable")
		kiosk_area.set_meta("system_tower_id", tower_id)
		kiosk_area.set_meta("system_tower_floor_number", floor_number)
		kiosk_area.set_meta("system_interaction_prompt", "خدمات " + department + " — فتح خدمات البرج")
		kiosk_area.collision_layer = 1
		kiosk_area.collision_mask = 0
		var kiosk_shape := CollisionShape3D.new()
		var kiosk_sphere := SphereShape3D.new()
		kiosk_sphere.radius = 2.0
		kiosk_shape.shape = kiosk_sphere
		kiosk_shape.position.y = 1.1
		kiosk_area.add_child(kiosk_shape)
		kiosk.add_child(kiosk_area)
	if tower_id == "shopping_tower_baghdad" and floor_number == 14:
		var staff_ids: Array = staff_by_tower.get(tower_id, [])
		if staff_ids.size() >= 3:
			_create_workshop_station(room, "WeaponsForge", "ورشة الحدادة وصناعة الأسلحة الحديثة والتقليدية", Vector3(-radius * 0.32, 0.0, -radius * 0.42), str(staff_ids[1]), "weapons_merchant")
			_create_workshop_station(room, "ElixirLaboratory", "مختبر تحضير الأكاسير وإيقاظ النِن والعلاج", Vector3(radius * 0.32, 0.0, -radius * 0.42), str(staff_ids[2]), "elixir_pharmacist")
	if tower_id == "shopping_tower_baghdad" and floor_number >= 29:
		_create_restaurant_dining_area(room, radius, floor_number)
	if tower_id == "shopping_tower_baghdad" and floor_number in [27, 28]:
		var hotel_staff: Array = staff_by_tower.get(tower_id, [])
		var hospitality_staff_id := str(hotel_staff[6]) if hotel_staff.size() > 6 else (str(hotel_staff[3]) if hotel_staff.size() > 3 else "")
		_create_hotel_facilities(room, radius, floor_number, hospitality_staff_id)
	room.set_meta("system_tower_id", tower_id)
	room.set_meta("system_tower_floor_number", floor_number)
	room.set_meta("system_tower_department", department)
	_create_specialized_floor_facility(room, tower_id, floor_number, radius, department)


func _create_specialized_floor_facility(room: Node3D, tower_id: String, floor_number: int, radius: float, department: String) -> void:
	var facility_type := ""
	var facility_title := ""
	match tower_id:
		"entertainment_tower_baghdad":
			if floor_number in [18, 19, 20]:
				facility_type = "swimming_pool"
				facility_title = "مسبح SYSTEM — مسبح رئيسي ومنطقة استرخاء"
			elif floor_number == 21:
				facility_type = "fitness_gym"
				facility_title = "نادي اللياقة والأجهزة الرياضية"
			elif floor_number == 22:
				facility_type = "sports_court"
				facility_title = "ملعب كرة السلة والأنشطة الجماعية"
			elif floor_number == 23:
				facility_type = "bowling"
				facility_title = "صالة البولينغ والألعاب"
			elif floor_number == 24:
				facility_type = "cinema"
				facility_title = "سينما SYSTEM"
			elif floor_number == 25:
				facility_type = "arcade"
				facility_title = "مركز الألعاب الإلكترونية"
			elif floor_number == 26:
				facility_type = "family_zone"
				facility_title = "منطقة العائلات والأطفال"
			elif floor_number in [33, 34]:
				facility_type = "rooftop_leisure"
				facility_title = "حديقة السطح والمطاعم المفتوحة"
		"business_investment_tower_baghdad":
			if floor_number == 8:
				facility_type = "stock_exchange"
				facility_title = "قاعة التداول والبورصة"
			elif floor_number == 16:
				facility_type = "conference_center"
				facility_title = "مركز المؤتمرات والاجتماعات"
			elif floor_number == 24:
				facility_type = "business_lounge"
				facility_title = "نادي رجال الأعمال وصالة المستثمرين"
		"technology_tower_baghdad":
			if floor_number == 10:
				facility_type = "robotics_lab"
				facility_title = "مختبر الروبوتات"
			elif floor_number == 20:
				facility_type = "ai_lab"
				facility_title = "مختبر الذكاء الاصطناعي"
			elif floor_number == 30:
				facility_type = "vr_lab"
				facility_title = "مختبر الواقع الافتراضي والمحاكاة"
			elif floor_number == 40:
				facility_type = "innovation_rooftop"
				facility_title = "منصة الابتكار والرصد التقني"
		"hunter_association_tower_baghdad":
			if floor_number in [4, 5, 6]:
				facility_type = "hunter_training"
				facility_title = "قاعة تدريب الصيادين"
			elif floor_number == 12:
				facility_type = "guild_lounge"
				facility_title = "صالة النقابات واجتماعات الصيادين"
			elif floor_number == 30:
				facility_type = "hunter_library"
				facility_title = "مكتبة وأرشيف الصيادين"
			elif floor_number == 100:
				facility_type = "hunter_hall_of_honor"
				facility_title = "قاعة الشرف العالمية"
			elif floor_number == 195:
				facility_type = "hunter_council"
				facility_title = "مجلس نقابة الصيادين العالمي"
			elif floor_number == 200:
				facility_type = "hunter_headquarters"
				facility_title = "المقر العالمي الأعلى لنقابة الصيادين"
	if facility_type.is_empty():
		return
	var root := Node3D.new()
	root.name = "SpecialFacility_" + facility_type
	root.set_meta("system_facility_type", facility_type)
	root.set_meta("system_facility_title", facility_title)
	room.add_child(root)
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(0.10, 0.52, 0.68) if tower_id == "technology_tower_baghdad" else Color(0.12, 0.42, 0.34)
	accent.metallic = 0.38
	accent.roughness = 0.3
	var highlight := StandardMaterial3D.new()
	highlight.albedo_color = Color(0.16, 0.72, 0.90, 0.72)
	highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight.metallic = 0.2
	highlight.roughness = 0.2
	var title := Label3D.new()
	title.name = "FacilityTitle"
	title.text = facility_title
	title.position = Vector3(0.0, 5.0, -radius * 0.42)
	title.font_size = 23
	title.pixel_size = 0.013
	title.modulate = Color(0.92, 0.82, 0.55)
	root.add_child(title)
	match facility_type:
		"swimming_pool":
			_add_facility_box(root, "PoolRim", Vector3(0.0, 0.65, 0.0), Vector3(23.0, 1.3, 15.0), accent)
			_add_facility_box(root, "PoolWater", Vector3(0.0, 1.12, 0.0), Vector3(20.8, 0.12, 12.8), highlight)
			_add_facility_box(root, "PoolDeckLeft", Vector3(-14.0, 0.3, 0.0), Vector3(4.0, 0.6, 18.0), accent)
			_add_facility_box(root, "PoolDeckRight", Vector3(14.0, 0.3, 0.0), Vector3(4.0, 0.6, 18.0), accent)
			for index in range(4):
				_add_facility_box(root, "SunLounger_%02d" % index, Vector3(-13.0 + float(index) * 2.0, 0.8, 11.0), Vector3(1.5, 0.35, 3.0), highlight)
		"fitness_gym":
			for index in range(5):
				_add_facility_box(root, "GymMachine_%02d" % index, Vector3(-12.0 + float(index) * 6.0, 1.2, 0.0), Vector3(2.0, 2.4, 2.0), accent)
		"sports_court":
			_add_facility_box(root, "CourtSurface", Vector3(0.0, 0.12, 0.0), Vector3(24.0, 0.2, 15.0), accent)
			for side in [-1.0, 1.0]:
				_add_facility_box(root, "CourtHoop_%s" % str(side), Vector3(side * 10.0, 3.0, 0.0), Vector3(0.25, 5.0, 0.25), highlight)
		"bowling":
			for index in range(3):
				_add_facility_box(root, "BowlingLane_%02d" % index, Vector3(-7.0 + float(index) * 7.0, 0.15, -1.0), Vector3(5.0, 0.25, 14.0), accent)
		"cinema":
			_add_facility_box(root, "CinemaScreen", Vector3(0.0, 3.0, -10.0), Vector3(20.0, 6.0, 0.35), highlight)
			for row in range(3):
				for seat in range(6):
					_add_facility_box(root, "CinemaSeat_%02d_%02d" % [row, seat], Vector3(-9.0 + float(seat) * 3.6, 0.65, 1.0 + float(row) * 3.0), Vector3(1.4, 1.3, 1.2), accent)
		"arcade":
			for index in range(6):
				_add_facility_box(root, "ArcadeCabinet_%02d" % index, Vector3(-12.0 + float(index) * 4.8, 1.4, -2.0), Vector3(2.0, 2.8, 1.4), highlight)
		"family_zone":
			for index in range(4):
				_add_facility_box(root, "FamilyPlayUnit_%02d" % index, Vector3(-9.0 + float(index) * 6.0, 1.0, 1.0), Vector3(3.2, 2.0, 3.2), accent)
		"rooftop_leisure":
			for index in range(6):
				_add_facility_box(root, "RooftopPlanter_%02d" % index, Vector3(-13.0 + float(index) * 5.2, 0.7, 7.0), Vector3(2.6, 1.4, 2.6), accent)
		"stock_exchange":
			_add_facility_box(root, "TradingDisplay", Vector3(0.0, 3.0, -8.0), Vector3(18.0, 5.0, 0.3), highlight)
			for index in range(5):
				_add_facility_box(root, "TradingDesk_%02d" % index, Vector3(-12.0 + float(index) * 6.0, 0.8, 1.0), Vector3(3.0, 1.6, 2.0), accent)
		"conference_center":
			for index in range(6):
				_add_facility_box(root, "ConferenceTable_%02d" % index, Vector3(-10.0 + float(index % 3) * 10.0, 0.8, -3.0 + float(index / 3) * 7.0), Vector3(5.0, 1.4, 2.4), accent)
		"business_lounge":
			for index in range(4):
				_add_facility_box(root, "LoungeSeat_%02d" % index, Vector3(-9.0 + float(index) * 6.0, 0.65, 1.0), Vector3(3.0, 1.3, 1.2), accent)
		"robotics_lab", "ai_lab", "vr_lab":
			for index in range(5):
				_add_facility_box(root, "TechnologyPod_%02d" % index, Vector3(-12.0 + float(index) * 6.0, 1.2, 0.0), Vector3(2.4, 2.4, 2.4), highlight if index % 2 == 0 else accent)
		"innovation_rooftop":
			for index in range(5):
				_add_facility_box(root, "InnovationConsole_%02d" % index, Vector3(-12.0 + float(index) * 6.0, 1.0, 1.0), Vector3(2.4, 2.0, 1.8), highlight)
		"hunter_training":
			for index in range(5):
				_add_facility_box(root, "HunterTrainingTarget_%02d" % index, Vector3(-12.0 + float(index) * 6.0, 2.0, -1.0), Vector3(1.5, 4.0, 1.5), accent)
		"guild_lounge":
			for index in range(4):
				_add_facility_box(root, "GuildTable_%02d" % index, Vector3(-9.0 + float(index) * 6.0, 0.8, 1.0), Vector3(3.0, 1.4, 2.0), accent)
		"hunter_library":
			for index in range(5):
				_add_facility_box(root, "ArchiveShelf_%02d" % index, Vector3(-12.0 + float(index) * 6.0, 1.6, 0.0), Vector3(2.4, 3.2, 0.8), accent)
		"hunter_hall_of_honor":
			for index in range(6):
				_add_facility_box(root, "HonorPillar_%02d" % index, Vector3(-15.0 + float(index) * 6.0, 2.5, 0.0), Vector3(1.2, 5.0, 1.2), highlight)
		"hunter_council":
			_add_facility_box(root, "GlobalCouncilTable", Vector3(0.0, 0.8, 0.0), Vector3(18.0, 1.4, 5.0), accent)
			_add_facility_box(root, "CouncilWorldDisplay", Vector3(0.0, 4.0, -10.0), Vector3(22.0, 6.0, 0.35), highlight)
			for index in range(8):
				_add_facility_box(root, "CouncilSeat_%02d" % index, Vector3(-12.0 + float(index) * 3.4, 0.7, 4.0), Vector3(1.4, 1.4, 1.4), accent)
		"hunter_headquarters":
			_add_facility_box(root, "AssociationDirectorDesk", Vector3(0.0, 0.8, -5.0), Vector3(8.0, 1.6, 2.6), accent)
			_add_facility_box(root, "GlobalOperationsDisplay", Vector3(0.0, 4.5, -13.0), Vector3(24.0, 7.0, 0.35), highlight)
			_add_facility_box(root, "AssociationFlagLeft", Vector3(-15.0, 4.0, 0.0), Vector3(0.3, 8.0, 0.3), accent)
			_add_facility_box(root, "AssociationFlagRight", Vector3(15.0, 4.0, 0.0), Vector3(0.3, 8.0, 0.3), accent)
			for index in range(4):
				_add_facility_box(root, "ExecutiveSeat_%02d" % index, Vector3(-6.0 + float(index) * 4.0, 0.7, 1.5), Vector3(2.0, 1.4, 1.6), accent)
	var interaction := Area3D.new()
	interaction.name = "FacilityServiceInteraction"
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_tower_id", tower_id)
	interaction.set_meta("system_tower_floor_number", floor_number)
	interaction.set_meta("system_facility_type", facility_type)
	interaction.set_meta("system_interaction_prompt", facility_title + " — اضغط للتعامل")
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.0
	shape.shape = sphere
	shape.position = Vector3(0.0, 1.2, 0.0)
	interaction.add_child(shape)
	root.add_child(interaction)


func _add_facility_box(parent: Node3D, object_name: String, object_position: Vector3, object_size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = object_name
	var mesh := BoxMesh.new()
	mesh.size = object_size
	visual.mesh = mesh
	visual.position = object_position
	visual.material_override = material
	parent.add_child(visual)


func _create_hotel_facilities(room: Node3D, radius: float, floor_number: int, hospitality_staff_id: String) -> void:
	var hotel := Node3D.new()
	hotel.name = "SYSTEMHotelFacilities"
	room.add_child(hotel)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.62, 0.39, 0.12)
	gold.metallic = 0.58
	gold.roughness = 0.3
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.07, 0.12, 0.16)
	dark.metallic = 0.35
	var sign := Label3D.new()
	sign.name = "HotelFloorSign"
	sign.text = "فندق SYSTEM — " + ("الاستقبال والصالة" if floor_number == 27 else "الغرف والأجنحة")
	sign.position = Vector3(0.0, 4.0, -radius * 0.48)
	sign.font_size = 28
	sign.pixel_size = 0.014
	sign.modulate = Color(1.0, 0.82, 0.48)
	hotel.add_child(sign)
	if floor_number == 27:
		var desk := MeshInstance3D.new()
		desk.name = "HotelReceptionDesk"
		var desk_mesh := BoxMesh.new()
		desk_mesh.size = Vector3(8.0, 1.4, 2.2)
		desk.mesh = desk_mesh
		desk.position = Vector3(0.0, 0.7, -radius * 0.18)
		desk.material_override = gold
		hotel.add_child(desk)
		var lounge := MeshInstance3D.new()
		lounge.name = "HotelLoungeFeature"
		var lounge_mesh := CylinderMesh.new()
		lounge_mesh.top_radius = 4.5
		lounge_mesh.bottom_radius = 4.5
		lounge_mesh.height = 0.35
		lounge.mesh = lounge_mesh
		lounge.position = Vector3(0.0, 0.2, radius * 0.28)
		lounge.material_override = dark
		hotel.add_child(lounge)
	else:
		for index in range(8):
			var angle := TAU * float(index) / 8.0
			var door := MeshInstance3D.new()
			door.name = "HotelSuiteDoor_%02d" % index
			var door_mesh := BoxMesh.new()
			door_mesh.size = Vector3(2.2, 3.4, 0.22)
			door.mesh = door_mesh
			door.position = Vector3(cos(angle) * radius * 0.48, 1.7, sin(angle) * radius * 0.48)
			door.rotation.y = -angle
			door.material_override = gold
			hotel.add_child(door)
	var interaction := Area3D.new()
	interaction.name = "HotelReceptionInteraction" if floor_number == 27 else "HotelSuiteBookingInteraction"
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_tower_id", "shopping_tower_baghdad")
	interaction.set_meta("system_tower_floor_number", floor_number)
	interaction.set_meta("system_hotel_service", "reception_booking" if floor_number == 27 else "room_and_suite_booking")
	interaction.set_meta("system_tower_staff_id", hospitality_staff_id)
	interaction.set_meta("system_tower_staff_role", "hotel_receptionist")
	interaction.set_meta("system_display_name", "استقبال فندق SYSTEM" if floor_number == 27 else "حجز الغرف والأجنحة")
	interaction.set_meta("system_interaction_prompt", "فندق SYSTEM — " + ("حجز غرفة أو جناح وتسجيل الدخول" if floor_number == 27 else "اختيار غرفة أو جناح ومعاينة خيارات الإقامة"))
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.2
	shape.shape = sphere
	shape.position.y = 1.2
	interaction.add_child(shape)
	hotel.add_child(interaction)
	room.set_meta("system_hotel_floor", floor_number)
	room.set_meta("system_hotel_staff_id", hospitality_staff_id)


func _create_restaurant_dining_area(room: Node3D, radius: float, floor_number: int) -> void:
	var dining_sign := Label3D.new()
	dining_sign.name = "RestaurantDiningSign"
	dining_sign.text = "SYSTEM FOOD HALL — مطاعم ومقاهي وصالات طعام"
	dining_sign.position = Vector3(0.0, 4.0, -radius * 0.42)
	dining_sign.font_size = 22
	dining_sign.pixel_size = 0.013
	dining_sign.modulate = Color(1.0, 0.78, 0.42)
	room.add_child(dining_sign)
	for index in range(4):
		var table_root := Node3D.new()
		table_root.name = "RestaurantTable_%02d" % index
		var angle := TAU * float(index) / 4.0
		table_root.position = Vector3(cos(angle) * radius * 0.34, 0.0, sin(angle) * radius * 0.34)
		room.add_child(table_root)
		var table := MeshInstance3D.new()
		var table_mesh := BoxMesh.new()
		table_mesh.size = Vector3(2.8, 0.18, 1.8)
		table.mesh = table_mesh
		table.position.y = 1.0
		var table_material := StandardMaterial3D.new()
		table_material.albedo_color = Color(0.34, 0.19, 0.10)
		table_material.roughness = 0.58
		table.material_override = table_material
		table_root.add_child(table)
		for seat_index in range(4):
			var seat := MeshInstance3D.new()
			var seat_mesh := BoxMesh.new()
			seat_mesh.size = Vector3(0.55, 0.9, 0.55)
			seat.mesh = seat_mesh
			var seat_angle := TAU * float(seat_index) / 4.0
			seat.position = Vector3(cos(seat_angle) * 1.35, 0.45, sin(seat_angle) * 1.0)
			seat.material_override = table_material
			table_root.add_child(seat)

func _create_workshop_station(room: Node3D, station_id: String, station_title: String, station_position: Vector3, staff_id: String, staff_role: String) -> void:
	var station := Node3D.new()
	station.name = station_id
	station.position = station_position
	room.add_child(station)
	var bench := MeshInstance3D.new()
	bench.name = "CraftingBenchVisual"
	var bench_mesh := BoxMesh.new()
	bench_mesh.size = Vector3(4.2, 1.1, 2.2)
	bench.mesh = bench_mesh
	bench.position.y = 0.55
	var bench_material := StandardMaterial3D.new()
	bench_material.albedo_color = Color(0.16, 0.20, 0.23)
	bench_material.metallic = 0.62
	bench.material_override = bench_material
	station.add_child(bench)
	var bench_collision := StaticBody3D.new()
	bench_collision.name = "CraftingBenchCollision"
	station.add_child(bench_collision)
	var bench_shape := CollisionShape3D.new()
	var bench_box := BoxShape3D.new()
	bench_box.size = bench_mesh.size
	bench_shape.shape = bench_box
	bench_shape.position = bench.position
	bench_collision.add_child(bench_shape)
	var title := Label3D.new()
	title.text = station_title
	title.position.y = 2.0
	title.font_size = 22
	title.pixel_size = 0.012
	title.modulate = Color(0.76, 0.94, 1.0)
	station.add_child(title)
	var interaction := Area3D.new()
	interaction.name = "CraftingStationInteraction"
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_tower_id", "shopping_tower_baghdad")
	interaction.set_meta("system_tower_staff_id", staff_id)
	interaction.set_meta("system_tower_staff_role", staff_role)
	interaction.set_meta("system_display_name", station_title)
	interaction.set_meta("system_interaction_prompt", station_title + " — تحدث مع الموظف")
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	var interaction_shape := CollisionShape3D.new()
	var interaction_sphere := SphereShape3D.new()
	interaction_sphere.radius = 2.8
	interaction_shape.shape = interaction_sphere
	interaction_shape.position.y = 1.1
	interaction.add_child(interaction_shape)
	station.add_child(interaction)


func _add_elevator_panel(parent: Node3D, panel_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var panel_mesh := MeshInstance3D.new()
	panel_mesh.name = panel_name
	var box := BoxMesh.new()
	box.size = size
	panel_mesh.mesh = box
	panel_mesh.position = position
	panel_mesh.material_override = material
	parent.add_child(panel_mesh)
	return panel_mesh

func _ensure_elevator_car(tower_id: String, start_y: float) -> Node3D:
	var tower := tower_nodes.get(tower_id) as Node3D
	if tower == null:
		return null
	if is_instance_valid(active_elevator_car) and active_elevator_tower_id == tower_id:
		active_elevator_car.position.y = start_y
		_close_elevator_doors()
		return active_elevator_car
	if is_instance_valid(active_elevator_car):
		active_elevator_car.queue_free()
	active_elevator_doors.clear()
	var config: Dictionary = TOWER_CONFIG[tower_id]
	var width := clampf(float(config["radius"]) * 0.46, 7.0, 12.0)
	var depth := width
	active_elevator_car_width = width
	var car := Node3D.new()
	car.name = "ActiveTowerElevatorCar"
	car.position = Vector3(0.0, start_y, 0.0)
	tower.add_child(car)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.045, 0.13, 0.18)
	metal.metallic = 0.78
	metal.roughness = 0.24
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.10, 0.42, 0.56, 0.38)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.42
	glass.roughness = 0.18
	_add_elevator_panel(car, "ElevatorCabinFloor", Vector3(width, 0.28, depth), Vector3(0.0, 0.0, 0.0), metal)
	_add_elevator_panel(car, "ElevatorCabinRoof", Vector3(width, 0.24, depth), Vector3(0.0, 4.5, 0.0), metal)
	_add_elevator_panel(car, "ElevatorCabinLeftWall", Vector3(0.25, 4.5, depth), Vector3(-width * 0.5, 2.25, 0.0), glass)
	_add_elevator_panel(car, "ElevatorCabinRightWall", Vector3(0.25, 4.5, depth), Vector3(width * 0.5, 2.25, 0.0), glass)
	_add_elevator_panel(car, "ElevatorCabinBackWall", Vector3(width, 4.5, 0.25), Vector3(0.0, 2.25, -depth * 0.5), metal)
	var left_door := _add_elevator_panel(car, "ElevatorLeftDoor", Vector3(width * 0.44, 4.35, 0.18), Vector3(-width * 0.22, 2.2, depth * 0.5), glass)
	var right_door := _add_elevator_panel(car, "ElevatorRightDoor", Vector3(width * 0.44, 4.35, 0.18), Vector3(width * 0.22, 2.2, depth * 0.5), glass)
	active_elevator_doors.clear()
	active_elevator_doors.append(left_door)
	active_elevator_doors.append(right_door)
	var lift_label := Label3D.new()
	lift_label.text = "SYSTEM LIFT"
	lift_label.position = Vector3(0.0, 3.9, -depth * 0.5 + 0.2)
	lift_label.font_size = 20
	lift_label.pixel_size = 0.012
	lift_label.modulate = Color(0.55, 0.94, 1.0)
	car.add_child(lift_label)
	active_elevator_car = car
	active_elevator_tower_id = tower_id
	_close_elevator_doors()
	return car

func _close_elevator_doors() -> void:
	if active_elevator_doors.size() < 2:
		return
	active_elevator_doors[0].position.x = -active_elevator_car_width * 0.22
	active_elevator_doors[1].position.x = active_elevator_car_width * 0.22

func _open_elevator_doors() -> void:
	if active_elevator_doors.size() < 2:
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(active_elevator_doors[0], "position:x", -active_elevator_car_width * 0.45, 0.35)
	tween.tween_property(active_elevator_doors[1], "position:x", active_elevator_car_width * 0.45, 0.35)

func _travel_to_floor(tower_id: String, floor_number: int) -> void:
	if not tower_nodes.has(tower_id) or not is_instance_valid(player):
		return
	var config: Dictionary = TOWER_CONFIG[tower_id]
	if floor_number < 1 or floor_number > int(config["floors"]):
		_set_status("رقم الطابق خارج حدود البرج.")
		return
	var room := _ensure_floor_room(tower_id, floor_number)
	if room == null:
		_set_status("تعذر تجهيز الطابق.")
		return
	var tower := tower_nodes[tower_id] as Node3D
	var start_y := active_floor_root.position.y if is_instance_valid(active_floor_root) else 9.0
	var car := _ensure_elevator_car(tower_id, start_y)
	if car == null:
		_set_status("تعذر تجهيز عربة المصعد.")
		return
	if tower_id == "power_tower_baghdad":
		if not is_instance_valid(power_tower_manager):
			_set_status("نظام برج القوة غير متاح.")
			return
		var state: Dictionary = power_tower_manager.call("get_tower_status")
		if floor_number != int(state.get("next_floor", 1)):
			_set_status("برج القوة يتطلب اجتياز الطوابق بالترتيب. الطابق التالي هو %d." % int(state.get("next_floor", 1)))
			return
		var request: Dictionary = power_tower_manager.call("request_floor", floor_number, int(progression.get("current_level")) if is_instance_valid(progression) else 1)
		if not bool(request.get("success", false)):
			_set_status("تعذر بدء التحدي: " + str(request.get("reason", "غير معروف")))
			return
		active_power_floor_data = request.get("floor_data", {})
		power_floor_in_progress = true
	if not is_instance_valid(active_floor_root):
		player.global_position = tower.to_global(Vector3(0.0, start_y + 1.2, 0.0))
	if is_instance_valid(active_floor_root) and active_floor_root != room:
		_return_customer_visitors_to_lobbies()
		active_floor_root.queue_free()
	active_floor_root = room
	active_floor_root.set_meta("system_tower_id", tower_id)
	active_floor_root.set_meta("system_tower_floor_number", floor_number)
	if tower_id == "power_tower_baghdad":
		active_power_objective_label = room.get_node_or_null("PowerTowerObjectiveLabel") as Label3D
	panel.hide()
	player.set_meta("system_tower_elevator_active", true)
	var target_position := tower.to_global(Vector3(0.0, room.position.y + 1.25, 0.0))
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(player, "global_position", target_position, 2.4)
	tween.tween_property(car, "position:y", room.position.y, 2.4)
	tween.finished.connect(func():
		_open_elevator_doors()
		if is_instance_valid(player):
			player.set_meta("system_tower_elevator_active", false)
			player.velocity = Vector3.ZERO
		if tower_id == "power_tower_baghdad" and power_floor_in_progress:
			_begin_power_floor()
		elif tower_id != "power_tower_baghdad":
			_place_customer_visitors_on_floor(tower_id, floor_number, room)
	)
	_set_status("عربة المصعد تتحرك إلى الطابق %d..." % floor_number)

func _begin_power_floor() -> void:
	if active_power_floor_data.is_empty() or active_floor_root == null:
		return
	power_floor_started_at = Time.get_ticks_msec()
	current_wave = 0
	total_waves = maxi(1, int(active_power_floor_data.get("wave_count", 1)))
	opponents_per_wave = maxi(1, int(active_power_floor_data.get("opponent_count", 1)))
	power_floor_timer_remaining = float(active_power_floor_data.get("time_limit_seconds", 0))
	power_floor_timer_display_clock = 0.0
	_update_power_objective_display()
	_spawn_power_wave()

func _spawn_power_wave() -> void:
	if active_floor_root == null:
		return
	current_wave += 1
	var difficulty := int(active_power_floor_data.get("difficulty", 1))
	var boss := bool(active_power_floor_data.get("boss_floor", false))
	var final_boss := bool(active_power_floor_data.get("final_boss", false))
	var count := 1 if boss else opponents_per_wave
	for index in range(count):
		var opponent = TowerOpponentScript.new()
		var health_multiplier := 4.0 if boss else 1.0
		if final_boss:
			health_multiplier = 10.0
		var damage_value := clampf(6.0 + float(difficulty) * 0.72, 6.0, 34.0)
		if boss:
			damage_value *= 1.35
		if final_boss:
			damage_value *= 1.25
		opponent.configure(
			player,
			player_health,
			(110.0 + float(difficulty) * 28.0) * health_multiplier,
			damage_value,
			2.1 + float(difficulty) * 0.025 + (0.25 if final_boss else 0.0),
			boss,
			final_boss
		)
		opponent.defeated.connect(_on_power_opponent_defeated)
		active_floor_root.add_child(opponent)
		var angle := TAU * float(index) / float(maxi(count, 1))
		opponent.position = Vector3(cos(angle) * 9.0, 1.1, sin(angle) * 9.0)
		active_opponents[opponent.get_instance_id()] = opponent
	_set_status("برج القوة — الطابق %d\nالموجة %d من %d | خصوم: %d" % [int(active_power_floor_data.get("floor", 1)), current_wave, total_waves, count])

func _on_power_opponent_defeated(opponent: Node) -> void:
	if opponent == null:
		return
	active_opponents.erase(opponent.get_instance_id())
	if not power_floor_in_progress or not active_opponents.is_empty():
		return
	if str(active_power_floor_data.get("objective_type", "")) == "SURVIVE_TIMER":
		if current_wave < total_waves:
			_spawn_power_wave()
		return
	if current_wave < total_waves:
		_spawn_power_wave()
	else:
		_complete_power_floor()

func _update_power_objective_display() -> void:
	if not is_instance_valid(active_power_objective_label) or active_power_floor_data.is_empty():
		return
	var objective := str(active_power_floor_data.get("objective_type", "ELIMINATE_WAVES"))
	var seconds := int(ceil(power_floor_timer_remaining))
	var objective_text := "أكمل موجات الخصوم"
	if objective == "SURVIVE_TIMER":
		objective_text = "اصمد حتى انتهاء الوقت"
	elif objective == "CLEAR_WITHIN_TIME":
		objective_text = "اهزم جميع الخصوم قبل انتهاء الوقت"
	elif objective == "DEFEAT_BOSS":
		objective_text = "اهزم زعيم الطابق"
	active_power_objective_label.text = objective_text + ("\nالوقت المتبقي: %d ثانية" % seconds if power_floor_timer_remaining > 0.0 else "")


func _clear_active_power_opponents() -> void:
	for opponent in active_opponents.values():
		if is_instance_valid(opponent):
			opponent.queue_free()
	active_opponents.clear()


func _fail_power_floor(reason: String) -> void:
	if not power_floor_in_progress:
		return
	_clear_active_power_opponents()
	power_tower_manager.call("abandon_active_floor")
	power_floor_in_progress = false
	power_floor_timer_remaining = 0.0
	active_power_floor_data.clear()
	if is_instance_valid(active_power_objective_label):
		active_power_objective_label.text = "انتهى الوقت — أعد المحاولة من المصعد"
	_set_status("لم تنجح في التحدي: " + reason + " حاول مرة أخرى من المصعد.")


func grant_power_tower_credits(floor_number: int, final_boss: bool = false) -> int:
	var reward := 75 + floor_number * 15 + (5000 if final_boss else 0)
	credits += reward
	_save_wallet()
	return reward


func _complete_power_floor() -> void:
	if not power_floor_in_progress:
		return
	var floor_number := int(active_power_floor_data.get("floor", 0))
	var reward_items: Array = active_power_floor_data.get("reward_items", []).duplicate()
	var final_boss := bool(active_power_floor_data.get("final_boss", false))
	var elapsed := maxf(1.0, float(Time.get_ticks_msec() - power_floor_started_at) / 1000.0)
	_clear_active_power_opponents()
	power_floor_timer_remaining = 0.0
	var result: Dictionary = power_tower_manager.call("confirm_floor_clear", floor_number, elapsed)
	power_floor_in_progress = false
	active_power_floor_data.clear()
	if bool(result.get("success", false)):
		var loot_names := PackedStringArray()
		if is_instance_valid(progression) and progression.has_method("add_item"):
			for item_id in reward_items:
				progression.call("add_item", str(item_id), 1)
				loot_names.append(str(item_id))
		var loot_text := " | الغنائم: " + ", ".join(loot_names) if not loot_names.is_empty() else ""
		var credit_reward := grant_power_tower_credits(floor_number, final_boss)
		_refresh_power_tower_progress_board()
		if is_instance_valid(active_power_objective_label):
			active_power_objective_label.text = "تم اجتياز الطابق %d" % floor_number
		_set_status("تم اجتياز الطابق %d!\nالتصنيف: %s | XP: %d | رصيد: %d%s\nالطابق التالي أصبح متاحاً." % [floor_number, str(result.get("rank", "E")), int(result.get("reward_xp", 0)), credit_reward, loot_text])
	else:
		_set_status("انتهى القتال لكن تعذر اعتماد النتيجة: " + str(result.get("reason", "غير معروف")))

func return_to_lobby() -> void:
	if current_tower_id.is_empty() or not tower_nodes.has(current_tower_id) or not is_instance_valid(player):
		return
	if not is_instance_valid(active_floor_root):
		panel.hide()
		return
	if current_tower_id == "power_tower_baghdad" and power_floor_in_progress:
		for opponent in active_opponents.values():
			if is_instance_valid(opponent):
				opponent.queue_free()
		active_opponents.clear()
		power_tower_manager.call("abandon_active_floor")
		power_floor_in_progress = false
		active_power_floor_data.clear()
		power_floor_timer_remaining = 0.0
		active_power_objective_label = null
	var tower := tower_nodes[current_tower_id] as Node3D
	var config: Dictionary = TOWER_CONFIG[current_tower_id]
	var start_y := active_floor_root.position.y
	var car := _ensure_elevator_car(current_tower_id, start_y)
	var first_floor_y := 9.0
	var lobby_position := tower.to_global(Vector3(0.0, 1.4, float(config["radius"]) * 1.48 + 10.0))
	player.set_meta("system_tower_elevator_active", true)
	panel.hide()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(player, "global_position", tower.to_global(Vector3(0.0, first_floor_y + 1.2, 0.0)), 2.0)
	if car != null:
		tween.tween_property(car, "position:y", first_floor_y, 2.0)
	tween.finished.connect(func():
		_open_elevator_doors()
		var exit_tween := create_tween()
		exit_tween.tween_property(player, "global_position", lobby_position, 0.7)
		exit_tween.finished.connect(func():
			if is_instance_valid(player):
				player.set_meta("system_tower_elevator_active", false)
				player.velocity = Vector3.ZERO
			if is_instance_valid(active_floor_root):
				active_floor_root.queue_free()
			active_floor_root = null
			active_power_objective_label = null
			if is_instance_valid(active_elevator_car):
				active_elevator_car.queue_free()
			active_elevator_car = null
			active_elevator_tower_id = ""
			active_elevator_doors.clear()
		)
	)

func _on_player_wounded() -> void:
	if not power_floor_in_progress:
		return
	for opponent in active_opponents.values():
		if is_instance_valid(opponent):
			opponent.queue_free()
	active_opponents.clear()
	if is_instance_valid(power_tower_manager):
		power_tower_manager.call("abandon_active_floor")
	power_floor_in_progress = false
	active_power_floor_data.clear()
	_set_status("تعرضت للإصابة، وتم إيقاف تحدي برج القوة دون احتساب الطابق. عُدت إلى البهو؛ توجه إلى المستشفى للعلاج.")
	return_to_lobby()

func get_operations_status() -> Dictionary:
	var total_staff := 0
	var total_customers := 0
	for ids in staff_by_tower.values():
		total_staff += ids.size()
	for ids in customer_ids_by_tower.values():
		total_customers += ids.size()
	return {"tower_count": tower_nodes.size(), "staff_count": total_staff, "customer_count": total_customers, "npc_purchase_count": npc_purchase_count, "npc_sales_total": npc_sales_total, "credits": credits, "interior_tower_count": prepared_towers.size(), "power_floor_active": power_floor_in_progress, "advertising_mode": "npc_staff_managed_internal_external"}

