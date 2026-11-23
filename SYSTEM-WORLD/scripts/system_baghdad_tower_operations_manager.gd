extends Node
class_name SYSTEMBaghdadTowerOperationsManager

const NPCCharacterModelScript = preload("res://scripts/npc_character_model.gd")
const TowerOpponentScript = preload("res://scripts/system_tower_opponent.gd")
const TowerFloorThemeBuilder = preload("res://scripts/system_baghdad_tower_floor_theme_builder.gd")
const SAVE_PATH := "user://system_baghdad_tower_operations.cfg"
const STOCK_SAVE_PATH := "user://system_tower_vendor_stock.cfg"
const HOTEL_SAVE_PATH := "user://system_baghdad_hotel_bookings.cfg"
const RESTAURANT_SAVE_PATH := "user://system_baghdad_restaurant_orders.cfg"
const NPC_SALES_SAVE_PATH := "user://system_baghdad_npc_sales.cfg"
const FACILITY_ACTIVITY_SAVE_PATH := "user://system_baghdad_facility_activity.cfg"
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
var current_pool_service_suite: Node3D
var credits := 1200
var vendor_stock: Dictionary = {}
var hotel_bookings: Dictionary = {}
var current_hotel_room_id := ""
var restaurant_orders: Dictionary = {}
var restaurant_order_history: Array = []
var restaurant_draft_items: Dictionary = {}
var current_restaurant_table_id := ""
var current_restaurant_table_node: Node
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

var facility_activity_stats: Dictionary = {}
var active_facility_activity: Dictionary = {}
var current_facility_root: Node3D
var bowling_throw_in_progress := false
var facility_projectile_in_progress := false
var facility_aim := 0.0
var selected_arcade_mode := "shooter"

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
	_load_restaurant_orders()
	_load_npc_sales_ledger()
	_load_facility_activity_stats()
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
	employee.set_meta("system_staff_home_tower_id", tower_id)
	employee.set_meta("system_staff_home_position", employee.position)
	employee.set_meta("system_staff_home_index", index)
	_start_tower_staff_waypoint_patrol(employee, model, index)


func _start_tower_staff_waypoint_patrol(employee: Node3D, model: Node3D, staff_index: int) -> void:
	if not is_instance_valid(employee) or not is_instance_valid(model):
		return
	var origin := employee.position
	var side := -1.0 if posmod(staff_index, 2) == 1 else 1.0
	var waypoints: Array[Vector3] = [
		origin + Vector3(0.0, 0.0, -1.4),
		origin + Vector3(side * 1.1, 0.0, -1.4),
		origin + Vector3(side * 1.1, 0.0, 0.2),
		origin
	]
	employee.set_meta("system_staff_navigation_enabled", true)
	employee.set_meta("system_staff_patrol_waypoints", waypoints)
	employee.set_meta("system_staff_navigation_speed", 1.8)
	var previous_tween: Variant = null
	if employee.has_meta("system_staff_patrol_tween"):
		previous_tween = employee.get_meta("system_staff_patrol_tween")
	if previous_tween is Tween:
		(previous_tween as Tween).kill()
	var patrol_tween := employee.create_tween().set_loops()
	employee.set_meta("system_staff_patrol_tween", patrol_tween)
	var previous_position := origin
	for waypoint in waypoints:
		var direction := waypoint - previous_position
		var yaw := atan2(direction.x, direction.z)
		var travel_duration := maxf(direction.length() / 1.8, 0.35)
		patrol_tween.tween_callback(Callable(model, "set_activity").bind("walk"))
		patrol_tween.tween_property(employee, "rotation:y", yaw, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		patrol_tween.tween_property(employee, "position", waypoint, travel_duration).set_trans(Tween.TRANS_LINEAR)
		patrol_tween.tween_callback(Callable(model, "set_activity").bind("idle"))
		patrol_tween.tween_interval(0.55)

		previous_position = waypoint


func _get_floor_duty_staff_index(tower_id: String, floor_number: int) -> int:
	if not TOWER_CONFIG.has(tower_id):
		return -1
	if floor_number < 1 or floor_number > int(TOWER_CONFIG[tower_id]["floors"]):
		return -1
	match tower_id:
		"hunter_association_tower_baghdad":
			if floor_number >= 191:
				return 0
			if floor_number == 100 or floor_number >= 101:
				return 4 if floor_number <= 150 else 5
			if floor_number >= 51:
				return 3
			if floor_number >= 11:
				return 2
			return 1
		"business_investment_tower_baghdad":
			if floor_number == 8:
				return 1
			if floor_number == 12:
				return 3
			if floor_number == 20:
				return 5
			if floor_number >= 33:
				return 0
			if floor_number >= 25:
				return 4
			if floor_number >= 17:
				return 2
			if floor_number >= 9:
				return 3
			return 1
		"shopping_tower_baghdad":
			if floor_number == 14:
				return 2
			if floor_number == 27:
				return 6
			if floor_number == 28:
				return 7
			if floor_number in [29, 31]:
				return 4
			if floor_number in [30, 32]:
				return 5
			if floor_number >= 17:
				return 1
			if floor_number >= 9:
				return 2
			return 0
		"entertainment_tower_baghdad":
			if floor_number in [18, 19]:
				return 3
			if floor_number == 20:
				return 4
			if floor_number == 24:
				return 1
			if floor_number >= 26:
				return 6
			if floor_number >= 21:
				return 5
			if floor_number >= 11:
				return 2
			return 0
		"technology_tower_baghdad":
			if floor_number == 12:
				return 3
			if floor_number == 20:
				return 4
			if floor_number == 30:
				return 2
			if floor_number >= 30:
				return 2
			if floor_number >= 20:
				return 4
			if floor_number >= 11:
				return 3
			return 1
		"power_tower_baghdad":
			if floor_number == 1:
				return 0
			if floor_number == 100:
				return 1
			if floor_number == 150:
				return 2
			if floor_number >= 101:
				return 1
			if floor_number >= 51:
				return 2
			return 1
	return -1


func _find_tower_staff_model(employee: Node3D) -> Node3D:
	if employee == null:
		return null
	for child in employee.get_children():
		if child is Node3D and child.has_method("set_activity"):
			return child as Node3D
	return null


func _board_floor_duty_staff(tower_id: String, floor_number: int, car: Node3D) -> Dictionary:
	if not is_instance_valid(car) or not staff_by_tower.has(tower_id):
		return {}
	var staff_index := _get_floor_duty_staff_index(tower_id, floor_number)
	var staff_ids: Array = staff_by_tower.get(tower_id, [])
	if staff_index < 0 or staff_index >= staff_ids.size():
		return {}
	var npc_id := str(staff_ids[staff_index])
	var tower := tower_nodes.get(tower_id) as Node3D
	var employee := tower.find_child("TowerStaff_" + npc_id, true, false) as Node3D if tower != null else null
	if employee == null:
		return {}
	var model := _find_tower_staff_model(employee)
	if model == null:
		return {}
	var previous_tween: Variant = employee.get_meta("system_staff_patrol_tween", null)
	if previous_tween is Tween:
		(previous_tween as Tween).kill()
	var home_position: Vector3 = employee.get_meta("system_staff_home_position", employee.position)
	employee.set_meta("system_staff_in_elevator", true)
	employee.set_meta("system_staff_duty_tower", tower_id)
	employee.set_meta("system_staff_duty_floor", floor_number)
	employee.set_meta("system_staff_current_location", tower_id + "_elevator_to_floor_" + str(floor_number))
	employee.reparent(car, true)
	employee.position = Vector3(0.0, 0.35, 0.0)
	model.call("set_activity", "walk")
	return {
		"employee": employee,
		"model": model,
		"tower_id": tower_id,
		"floor_number": floor_number,
		"staff_index": staff_index,
		"npc_id": npc_id,
		"role": str(employee.get_meta("system_tower_staff_role", "tower_staff")),
		"home_position": home_position
	}


func _place_floor_duty_staff_on_floor(trip: Dictionary, room: Node3D, radius: float) -> void:
	if trip.is_empty() or not is_instance_valid(room):
		return
	var employee := trip.get("employee") as Node3D
	var model := trip.get("model") as Node3D
	if not is_instance_valid(employee) or not is_instance_valid(model):
		return
	var tower_id := str(trip.get("tower_id", ""))
	var floor_number := int(trip.get("floor_number", 0))
	var role := str(trip.get("role", "tower_staff"))
	var station_name := "StaffWorkstation_" + role
	var target_position := Vector3(radius * 0.34, 0.0, -radius * 0.16)
	var service_position := target_position + Vector3(2.4, 0.0, 0.0)
	var information_position := target_position + Vector3(1.2, 0.0, 2.1)
	if tower_id == "entertainment_tower_baghdad" and floor_number in [18, 19] and role == "pool_supervisor":
		target_position = Vector3(3.2, 0.0, -17.0)
		service_position = Vector3(6.2, 0.0, -17.0)
		information_position = Vector3(6.2, 0.0, -13.0)
	var station := room.get_node_or_null(station_name) as Node3D
	if station == null:
		station = Node3D.new()
		station.name = station_name
		station.position = target_position + Vector3(0.0, 0.0, -1.35)
		station.set_meta("system_staff_role", role)
		station.set_meta("system_tower_id", tower_id)
		station.set_meta("system_floor_number", floor_number)
		room.add_child(station)
		var desk := MeshInstance3D.new()
		desk.name = "WorkstationDesk"
		var desk_mesh := BoxMesh.new()
		desk_mesh.size = Vector3(2.2, 1.0, 0.9)
		desk.mesh = desk_mesh
		desk.position.y = 0.5
		var desk_material := StandardMaterial3D.new()
		desk_material.albedo_color = Color(0.075, 0.20, 0.25)
		desk_material.metallic = 0.58
		desk_material.roughness = 0.3
		desk.material_override = desk_material
		station.add_child(desk)
		var terminal := MeshInstance3D.new()
		terminal.name = "WorkstationTerminal"
		var terminal_mesh := BoxMesh.new()
		terminal_mesh.size = Vector3(0.9, 0.65, 0.12)
		terminal.mesh = terminal_mesh
		terminal.position = Vector3(0.0, 1.32, -0.18)
		var terminal_material := StandardMaterial3D.new()
		terminal_material.albedo_color = Color(0.08, 0.65, 0.78)
		terminal_material.emission_enabled = true
		terminal_material.emission = Color(0.04, 0.48, 0.72)
		terminal_material.emission_energy_multiplier = 0.8
		terminal.material_override = terminal_material
		station.add_child(terminal)
		var role_sign := Label3D.new()
		role_sign.name = "WorkstationRoleSign"
		role_sign.text = "%s\nالطابق %d" % [role, floor_number]
		role_sign.position = Vector3(0.0, 2.15, 0.0)
		role_sign.font_size = 20
		role_sign.pixel_size = 0.012
		role_sign.modulate = Color(0.72, 0.94, 1.0)
		station.add_child(role_sign)
		if role == "pool_supervisor":
			_add_facility_box(station, "PoolRescueFirstAidKit", Vector3(-1.55, 0.72, 0.2), Vector3(0.9, 1.1, 0.7), desk_material)
			_add_facility_box(station, "PoolRescueTubeRack", Vector3(1.55, 1.05, 0.2), Vector3(0.35, 1.8, 0.35), terminal_material)
			_add_facility_box(station, "PoolRescueWhistlePanel", Vector3(0.0, 1.7, 0.55), Vector3(1.2, 0.35, 0.12), terminal_material)
			_add_pool_room_sign(station, "PoolSafetyEquipmentSign", "معدات الإنقاذ والإسعاف الأولي", Vector3(0.0, 2.65, 0.25), Color(0.95, 0.82, 0.58))

	var service_name := "StaffServicePoint_" + role
	if room.get_node_or_null(service_name) == null:
		var service_point := Node3D.new()
		service_point.name = service_name
		service_point.position = service_position
		service_point.set_meta("system_staff_workstation_type", "service_counter")
		room.add_child(service_point)
		var service_counter := MeshInstance3D.new()
		service_counter.name = "ServiceCounter"
		var counter_mesh := BoxMesh.new()
		counter_mesh.size = Vector3(1.8, 1.05, 0.8)
		service_counter.mesh = counter_mesh
		service_counter.position.y = 0.525
		var counter_material := StandardMaterial3D.new()
		counter_material.albedo_color = Color(0.10, 0.27, 0.31)
		counter_material.metallic = 0.48
		service_counter.material_override = counter_material
		service_point.add_child(service_counter)
		var service_label := Label3D.new()
		service_label.name = "ServicePointLabel"
		service_label.text = "POOL SAFETY / خدمة المنقذ" if role == "pool_supervisor" else "SERVICE / خدمة الموظف"
		service_label.position.y = 1.45
		service_label.font_size = 15
		service_label.pixel_size = 0.012
		service_label.modulate = Color(0.62, 0.94, 1.0)
		service_point.add_child(service_label)

	var information_name := "StaffInformationPoint_" + role
	if room.get_node_or_null(information_name) == null:
		var information_point := Node3D.new()
		information_point.name = information_name
		information_point.position = information_position
		information_point.set_meta("system_staff_workstation_type", "information_terminal")
		room.add_child(information_point)
		var information_pedestal := MeshInstance3D.new()
		information_pedestal.name = "InformationPedestal"
		var pedestal_mesh := BoxMesh.new()
		pedestal_mesh.size = Vector3(0.8, 1.2, 0.8)
		information_pedestal.mesh = pedestal_mesh
		information_pedestal.position.y = 0.6
		var pedestal_material := StandardMaterial3D.new()
		pedestal_material.albedo_color = Color(0.12, 0.18, 0.24)
		pedestal_material.metallic = 0.62
		information_pedestal.material_override = pedestal_material
		information_point.add_child(information_pedestal)
		var information_screen := MeshInstance3D.new()
		information_screen.name = "InformationScreen"
		var screen_mesh := BoxMesh.new()
		screen_mesh.size = Vector3(0.72, 0.52, 0.1)
		information_screen.mesh = screen_mesh
		information_screen.position = Vector3(0.0, 1.38, -0.12)
		var screen_material := StandardMaterial3D.new()
		screen_material.albedo_color = Color(0.08, 0.62, 0.82)
		screen_material.emission_enabled = true
		screen_material.emission = Color(0.04, 0.42, 0.72)
		screen_material.emission_energy_multiplier = 0.75
		information_screen.material_override = screen_material
		information_point.add_child(information_screen)

	var work_route: Array[Vector3] = [service_position, information_position, target_position]
	employee.reparent(room, false)
	employee.position = Vector3.ZERO
	employee.rotation.y = 0.0
	employee.set_meta("system_staff_in_elevator", false)
	employee.set_meta("system_staff_current_location", tower_id + "_floor_" + str(floor_number))
	employee.set_meta("system_staff_workstation_position", target_position)
	employee.set_meta("system_staff_workstation_active", false)
	employee.set_meta("system_staff_work_route", work_route)
	model.call("set_activity", "walk")
	var walk_tween := employee.create_tween()
	employee.set_meta("system_staff_patrol_tween", walk_tween)
	walk_tween.tween_property(employee, "position", target_position, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	walk_tween.tween_callback(func():
		if is_instance_valid(employee) and employee.get_parent() == room:
			employee.set_meta("system_staff_workstation_active", true)
			_start_floor_duty_staff_work_loop(employee, model, work_route)
	)


func _start_floor_duty_staff_work_loop(employee: Node3D, model: Node3D, waypoints: Array[Vector3]) -> void:
	if not is_instance_valid(employee) or not is_instance_valid(model) or waypoints.size() < 2:
		return
	var previous_tween: Variant = employee.get_meta("system_staff_patrol_tween", null)
	if previous_tween is Tween:
		(previous_tween as Tween).kill()
	var work_tween := employee.create_tween().set_loops()
	employee.set_meta("system_staff_patrol_tween", work_tween)
	var previous_position := employee.position
	for waypoint in waypoints:
		var direction := waypoint - previous_position
		var yaw := atan2(direction.x, direction.z)
		var travel_duration := maxf(direction.length() / 1.5, 0.4)
		work_tween.tween_callback(Callable(model, "set_activity").bind("walk"))
		work_tween.tween_property(employee, "rotation:y", yaw, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		work_tween.tween_property(employee, "position", waypoint, travel_duration).set_trans(Tween.TRANS_LINEAR)
		work_tween.tween_callback(Callable(model, "set_activity").bind("idle"))
		work_tween.tween_interval(1.0)
		previous_position = waypoint


func _return_one_tower_staff_to_lobby(employee: Node3D) -> void:
	if not is_instance_valid(employee):
		return
	var tower_id := str(employee.get_meta("system_staff_home_tower_id", employee.get_meta("system_tower_id", "")))
	if tower_id.is_empty() or not tower_nodes.has(tower_id):
		return
	var tower := tower_nodes[tower_id] as Node3D
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D
	if lobby == null:
		return
	var model := _find_tower_staff_model(employee)
	var previous_tween: Variant = employee.get_meta("system_staff_patrol_tween", null)
	if previous_tween is Tween:
		(previous_tween as Tween).kill()
	var staff_index := int(employee.get_meta("system_staff_home_index", 0))
	var home_position: Vector3 = employee.get_meta("system_staff_home_position", Vector3.ZERO)
	employee.reparent(lobby, false)
	employee.position = home_position
	employee.remove_meta("system_staff_in_elevator")
	employee.remove_meta("system_staff_duty_tower")
	employee.remove_meta("system_staff_duty_floor")
	employee.remove_meta("system_staff_current_location")
	employee.remove_meta("system_staff_workstation_position")
	employee.remove_meta("system_staff_workstation_active")
	employee.remove_meta("system_staff_work_route")
	employee.remove_meta("system_staff_assistance_requested")
	employee.remove_meta("system_staff_assistance_target")
	employee.remove_meta("system_staff_assistance_arrived")
	if is_instance_valid(model):
		model.call("set_activity", "idle")
	_start_tower_staff_waypoint_patrol(employee, model, staff_index)


func _return_floor_duty_staff_to_lobbies() -> void:
	for tower_id_value in staff_by_tower.keys():
		var tower_id := str(tower_id_value)
		var tower := tower_nodes.get(tower_id) as Node3D
		if tower == null:
			continue
		var staff_ids: Array = staff_by_tower.get(tower_id, [])
		for npc_id_value in staff_ids:
			var employee := tower.find_child("TowerStaff_" + str(npc_id_value), true, false) as Node3D
			if employee != null and (employee.has_meta("system_staff_duty_floor") or bool(employee.get_meta("system_staff_in_elevator", false))):
				_return_one_tower_staff_to_lobby(employee)


func _board_active_floor_duty_staff_for_lobby_return(car: Node3D) -> Array[Node3D]:
	var boarded: Array[Node3D] = []
	if not is_instance_valid(car) or not is_instance_valid(active_floor_root):
		return boarded
	for child in active_floor_root.get_children():
		if child is Node3D and child.has_meta("system_staff_duty_floor"):
			var employee := child as Node3D
			var model := _find_tower_staff_model(employee)
			var previous_tween: Variant = employee.get_meta("system_staff_patrol_tween", null)
			if previous_tween is Tween:
				(previous_tween as Tween).kill()
			employee.set_meta("system_staff_in_elevator", true)
			employee.reparent(car, true)
			employee.position = Vector3(0.0, 0.35, 0.0)
			if is_instance_valid(model):
				model.call("set_activity", "walk")
			boarded.append(employee)
	return boarded


func _finish_staff_lobby_return(boarded: Array[Node3D]) -> void:
	for employee in boarded:
		_return_one_tower_staff_to_lobby(employee)


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
			_release_restaurant_customer_seat(visitor)
			visitor.reparent(lobby, false)
			var customer_index := int(visitor.get_meta("system_tower_customer_index", 0))
			var radius := float(TOWER_CONFIG[tower_id].get("radius", 24.0))
			visitor.position = Vector3((float(customer_index) - 1.5) * 3.6, 0.0, radius * 1.48 + 12.0 + float(customer_index % 2) * 3.0)
			visitor.remove_meta("system_customer_in_elevator")
			visitor.remove_meta("system_customer_elevator_target_floor")


func _board_customer_visitors_into_elevator(tower_id: String, target_floor: int, car: Node3D) -> int:
	if not is_instance_valid(car) or not customer_ids_by_tower.has(tower_id):
		return 0
	var tower := tower_nodes.get(tower_id) as Node3D
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
	if lobby == null:
		return 0
	var passengers: Array[Node3D] = []
	if is_instance_valid(active_floor_root) and str(active_floor_root.get_meta("system_tower_id", "")) == tower_id:
		for child in active_floor_root.get_children():
			if child is Node3D and str(child.name).begins_with("TowerCustomer_"):
				passengers.append(child as Node3D)
	if passengers.is_empty():
		var ids: Array = customer_ids_by_tower[tower_id]
		for slot in range(mini(2, ids.size())):
			var customer_id := str(ids[posmod(target_floor + slot, ids.size())])
			var visitor := lobby.get_node_or_null("TowerCustomer_" + customer_id) as Node3D
			if visitor != null:
				passengers.append(visitor)
	var boarded := 0
	for visitor in passengers:
		if boarded >= 2:
			break
		var previous_tween: Variant = visitor.get_meta("system_customer_move_tween", null)
		if previous_tween is Tween and (previous_tween as Tween).is_running():
			(previous_tween as Tween).kill()
		_release_restaurant_customer_seat(visitor)
		visitor.reparent(car, true)
		visitor.position = Vector3(-1.2 + float(boarded) * 2.4, 0.45, 0.0)
		visitor.set_meta("system_customer_in_elevator", true)
		visitor.set_meta("system_customer_elevator_target_floor", target_floor)
		for visitor_child in visitor.get_children():
			if visitor_child.has_method("set_activity"):
				visitor_child.call("set_activity", "walk")
		boarded += 1
	return boarded


func _disembark_customer_visitors_to_lobby(tower_id: String, car: Node3D) -> int:
	if not is_instance_valid(car):
		return 0
	var tower := tower_nodes.get(tower_id) as Node3D
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
	if lobby == null:
		return 0
	var disembarked := 0
	for child in car.get_children():
		if not child is Node3D or not str(child.name).begins_with("TowerCustomer_"):
			continue
		var visitor := child as Node3D
		visitor.reparent(lobby, false)
		var customer_index := int(visitor.get_meta("system_tower_customer_index", 0))
		var radius := float(TOWER_CONFIG[tower_id].get("radius", 24.0))
		visitor.position = Vector3((float(customer_index) - 1.5) * 3.6, 0.0, radius * 1.48 + 12.0 + float(customer_index % 2) * 3.0)
		visitor.remove_meta("system_customer_in_elevator")
		visitor.remove_meta("system_customer_elevator_target_floor")
		visitor.remove_meta("system_customer_current_floor")
		visitor.remove_meta("system_customer_current_department")
		if is_instance_valid(society):
			var customer_id := str(visitor.get_meta("system_tower_customer_id", ""))
			var customer: Dictionary = society.call("get_npc", customer_id)
			if not customer.is_empty():
				customer["current_location"] = tower_id + "_public_lobby"
				customer["current_action"] = "waiting_in_lobby"
				society.npcs[customer_id] = customer
		disembarked += 1
	if disembarked > 0 and is_instance_valid(society) and society.has_method("save_society"):
		society.call("save_society")
	return disembarked


func _place_customer_visitors_on_floor(tower_id: String, floor_number: int, room: Node3D) -> void:
	if room == null or not customer_ids_by_tower.has(tower_id):
		return
	var tower := tower_nodes.get(tower_id) as Node3D
	var lobby := tower.get_node_or_null("PublicLobby_Blockout") as Node3D if tower != null else null
	if lobby == null:
		return
	var passengers: Array[Node3D] = []
	if is_instance_valid(active_elevator_car):
		for child in active_elevator_car.get_children():
			if child is Node3D and str(child.name).begins_with("TowerCustomer_"):
				passengers.append(child as Node3D)
	if passengers.is_empty():
		var ids: Array = customer_ids_by_tower[tower_id]
		for slot in range(mini(2, ids.size())):
			var customer_id := str(ids[posmod(floor_number + slot, ids.size())])
			var visitor := lobby.get_node_or_null("TowerCustomer_" + customer_id) as Node3D
			if visitor != null:
				passengers.append(visitor)
	var floor_label := _department_for_floor(tower_id, floor_number, int(TOWER_CONFIG[tower_id].get("floors", 1)))
	var radius := float(TOWER_CONFIG[tower_id].get("radius", 24.0))
	for slot in range(mini(2, passengers.size())):
		var visitor := passengers[slot]
		var customer_id := str(visitor.get_meta("system_tower_customer_id", ""))
		visitor.reparent(room, false)
		visitor.remove_meta("system_customer_in_elevator")
		visitor.remove_meta("system_customer_elevator_target_floor")
		visitor.set_meta("system_customer_current_floor", floor_number)
		visitor.set_meta("system_customer_current_department", floor_label)
		if tower_id == "shopping_tower_baghdad" and floor_number >= 29:
			_seat_customer_at_restaurant(visitor, room, slot)
		else:
			var angle := TAU * float(slot) / float(maxi(passengers.size(), 1))
			visitor.position = Vector3(cos(angle) * radius * 0.28, 0.0, sin(angle) * radius * 0.28)
			for visitor_child in visitor.get_children():
				if visitor_child.has_method("set_activity"):
					visitor_child.call("set_activity", "wander" if slot == 0 else "socialize")
		if is_instance_valid(society) and not customer_id.is_empty():
			var customer: Dictionary = society.call("get_npc", customer_id)
			if not customer.is_empty():
				customer["current_location"] = "%s_floor_%d" % [tower_id, floor_number]
				customer["current_action"] = ("waiting_for_restaurant_table" if visitor.has_meta("system_restaurant_queue_marker") else "dining") if tower_id == "shopping_tower_baghdad" and floor_number >= 29 else "visiting_" + floor_label
				customer["last_tower_visit"] = Time.get_datetime_string_from_system()
				society.npcs[customer_id] = customer
	if is_instance_valid(society) and society.has_method("save_society"):
		society.call("save_society")


func get_customer_schedule_phase(hour: int) -> String:
	var normalized_hour := posmod(hour, 24)
	if normalized_hour >= 7 and normalized_hour < 10:
		return "cafe"
	if normalized_hour >= 10 and normalized_hour < 14:
		return "browse"
	if normalized_hour >= 14 and normalized_hour < 18:
		return "social"
	if normalized_hour >= 18 and normalized_hour < 22:
		return "leisure"
	return "quiet"


func _move_customer_visitors(hour_override: int = -1) -> void:
	var hour := hour_override if hour_override >= 0 else int(Time.get_datetime_dict_from_system().get("hour", 12))
	var phase := get_customer_schedule_phase(hour)
	var society_changed := false
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
				if not str(visitor.name).begins_with("TowerCustomer_") or not visitor is Node3D:
					continue
				var visitor_node := visitor as Node3D
				var customer_index := int(visitor_node.get_meta("system_tower_customer_index", 0))
				var radius := float(config.get("radius", 20.0))
				var target := Vector3.ZERO
				var action := "socializing"
				var location := tower_id + "_public_lobby"
				if visitor_parent == active_floor_root:
					var floor_number := int(active_floor_root.get_meta("system_tower_floor_number", 1))
					target = Vector3(
						(float(customer_index % 2) * 2.0 - 1.0) * radius * 0.20,
						0.0,
						(float(customer_index / 2) - 0.5) * radius * 0.24
					)
					action = "visiting_" + str(visitor_node.get_meta("system_customer_current_department", "department"))
					location = "%s_floor_%d" % [tower_id, floor_number]
				else:
					match phase:
						"cafe":
							target = Vector3(radius * 0.78 + float(customer_index % 2) * 2.0, 0.0, radius * 1.48 + 15.0 + float(customer_index / 2) * 2.4)
							action = "having_breakfast"
							location = tower_id + "_lobby_cafe"
						"browse":
							target = Vector3((float(customer_index) - 1.5) * 3.0, 0.0, radius * 1.48 + 10.0)
							action = "browsing_services"
						"social":
							target = Vector3((float(customer_index) - 1.5) * 2.8, 0.0, radius * 1.48 + 20.0)
							action = "socializing"
						"leisure":
							target = Vector3(-radius * 0.72 + float(customer_index % 2) * 2.0, 0.0, radius * 1.48 + 15.0)
							action = "evening_leisure"
							location = tower_id + "_public_lounge"
						_:
							target = Vector3((float(customer_index) - 1.5) * 3.6, 0.0, radius * 1.48 + 12.0)
							action = "waiting_in_lobby"
				var previous_phase := str(visitor_node.get_meta("system_customer_schedule_phase")) if visitor_node.has_meta("system_customer_schedule_phase") else ""
				visitor_node.set_meta("system_customer_schedule_phase", phase)
				visitor_node.set_meta("system_customer_schedule_action", action)
				visitor_node.set_meta("system_customer_schedule_target", target)
				var customer_id := str(visitor_node.get_meta("system_tower_customer_id", ""))
				if not customer_id.is_empty() and is_instance_valid(society) and previous_phase != phase:
					var customer: Dictionary = society.call("get_npc", customer_id)
					if not customer.is_empty():
						customer["current_action"] = action
						customer["current_location"] = location
						customer["daily_schedule_phase"] = phase
						customer["daily_schedule_updated_at"] = Time.get_datetime_string_from_system()
						society.npcs[customer_id] = customer
						society_changed = true
				var model: Node3D = null
				for visitor_child in visitor_node.get_children():
					if visitor_child.has_method("set_activity"):
						model = visitor_child as Node3D
						break
				var previous_tween: Variant = visitor_node.get_meta("system_customer_move_tween") if visitor_node.has_meta("system_customer_move_tween") else null
				if previous_tween is Tween and (previous_tween as Tween).is_running():
					if previous_phase == phase:
						continue
					(previous_tween as Tween).kill()
				if visitor_node.position.distance_to(target) <= 0.35:
					if is_instance_valid(model):
						model.call("set_activity", "socialize" if action in ["socializing", "evening_leisure"] else "idle")
					continue
				if is_instance_valid(model):
					model.call("set_activity", "walk")
				var move_tween := create_tween()
				visitor_node.set_meta("system_customer_move_tween", move_tween)
				move_tween.set_trans(Tween.TRANS_SINE)
				move_tween.set_ease(Tween.EASE_IN_OUT)
				var travel_duration := clampf(visitor_node.position.distance_to(target) / 1.6, 1.2, 4.0)
				move_tween.tween_property(visitor_node, "position", target, travel_duration)
				move_tween.tween_callback(func():
					if is_instance_valid(model):
						model.call("set_activity", "socialize" if action in ["socializing", "evening_leisure"] else "idle")
				)
	if society_changed and is_instance_valid(society) and society.has_method("save_society"):
		society.call("save_society")


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
	current_restaurant_table_id = ""
	current_restaurant_table_node = null
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
	if role in ["restaurant_chef", "restaurant_waiter"]:
		_add_restaurant_staff_controls(role)
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


func _get_hotel_room_catalog() -> Array:
	return HOTEL_ROOM_CATALOG.duplicate(true)


func _add_hotel_room_collision_box(parent: Node3D, object_name: String, object_size: Vector3, object_position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = object_name
	body.position = object_position
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = object_size
	shape_node.shape = shape
	body.add_child(shape_node)
	parent.add_child(body)
	return body


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


func open_hotel_room_preview(room_id: String) -> void:
	var room_data: Dictionary = {}
	for room_value in HOTEL_ROOM_CATALOG:
		var candidate: Dictionary = room_value
		if str(candidate.get("id", "")) == room_id:
			room_data = candidate
			break
	if room_data.is_empty():
		return
	current_hotel_room_id = room_id
	current_tower_id = "shopping_tower_baghdad"
	panel.visible = true
	title_label.text = "فندق SYSTEM — " + str(room_data.get("name", "غرفة فندقية"))
	_clear_dynamic_controls()
	var details := Label.new()
	details.text = "معاينة داخلية للغرفة\nالسعر: %d رصيد لليلة\nالرتبة المطلوبة: %s\nتتضمن سريراً وخزانة ومكتباً وحماماً خاصاً." % [int(room_data.get("rate", 0)), str(room_data.get("required_rank", "F"))]
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(details)
	var booking: Dictionary = hotel_bookings.get(room_id, {})
	var status := str(booking.get("status", ""))
	if booking.is_empty() or status == "ready":
		var book_button := Button.new()
		book_button.text = "حجز هذه الغرفة — ليلة واحدة"
		book_button.disabled = not _meets_hunter_rank(str(room_data.get("required_rank", "F"))) or credits < int(room_data.get("rate", 0)) or not _get_active_hotel_booking().is_empty()
		book_button.pressed.connect(_book_hotel_room.bind(room_id, str(room_data.get("name", "")), int(room_data.get("rate", 0)), str(room_data.get("required_rank", "F")), 1))
		content.add_child(book_button)
	elif str(booking.get("guest_id", "")) == "local_player":
		var state := Label.new()
		state.text = "حالتك في الغرفة: %s" % status
		content.add_child(state)
		if int(booking.get("check_in_unix", 0)) == 0:
			var check_in_button := Button.new()
			check_in_button.text = "تسجيل الدخول إلى هذه الغرفة"
			check_in_button.pressed.connect(_check_in_hotel_room)
			content.add_child(check_in_button)
		else:
			_add_hotel_room_service_controls(content, booking)
		var checkout_button := Button.new()
		checkout_button.text = "تسجيل الخروج وإنهاء الإقامة"
		checkout_button.pressed.connect(_checkout_hotel_room)
		content.add_child(checkout_button)
	else:
		var occupied := Label.new()
		occupied.text = "هذه الغرفة مشغولة حالياً ولا يمكن حجزها."
		content.add_child(occupied)
	_set_status("معاينة %s — يمكنك الحجز من هنا أو من استقبال الفندق." % str(room_data.get("name", "الغرفة")))


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
		if segment == 0 or segment == 15:
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
	_create_floor_emergency_exit(room, tower_id, floor_number, radius)
	if tower_id == "power_tower_baghdad":
		room.set_meta("system_power_tower_floor", floor_number)
		room.set_meta("system_power_tower_department", "arena")
		_create_power_arena_layout(room, radius, floor_number)
	else:
		_create_floor_facilities(room, tower_id, floor_number, radius, department)
		TowerFloorThemeBuilder.build(room, tower_id, floor_number, radius, department)
	return room

func _create_floor_emergency_exit(room: Node3D, tower_id: String, floor_number: int, radius: float) -> void:
	var exit_root := Node3D.new()
	exit_root.name = "EmergencyEvacuationExit"
	exit_root.position = Vector3(0.0, 0.0, -radius * 0.78)
	exit_root.set_meta("system_tower_id", tower_id)
	exit_root.set_meta("system_floor_number", floor_number)
	exit_root.set_meta("system_facility_type", "emergency_evacuation_exit")
	room.add_child(exit_root)

	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.10, 0.22, 0.25)
	frame_material.metallic = 0.72
	frame_material.roughness = 0.28
	var beacon_material := StandardMaterial3D.new()
	beacon_material.albedo_color = Color(0.12, 0.92, 0.62)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(0.08, 1.0, 0.52)
	beacon_material.emission_energy_multiplier = 2.4

	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		pillar.name = "EmergencyExitFramePillar_%s" % ("L" if side < 0.0 else "R")
		var pillar_mesh := BoxMesh.new()
		pillar_mesh.size = Vector3(0.38, 4.2, 0.55)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(side * 1.35, 2.1, 0.0)
		pillar.material_override = frame_material
		exit_root.add_child(pillar)
	var lintel := MeshInstance3D.new()
	lintel.name = "EmergencyExitFrameLintel"
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(3.08, 0.42, 0.62)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, 4.12, 0.0)
	lintel.material_override = frame_material
	exit_root.add_child(lintel)

	var sign := Label3D.new()
	sign.name = "EmergencyExitSign"
	sign.text = "EMERGENCY EXIT\nمخرج الطوارئ — الطابق %d" % floor_number
	sign.position = Vector3(0.0, 4.82, 0.12)
	sign.font_size = 24
	sign.pixel_size = 0.014
	sign.modulate = Color(0.35, 1.0, 0.68)
	exit_root.add_child(sign)

	var beacon := MeshInstance3D.new()
	beacon.name = "EmergencyExitBeacon"
	var beacon_mesh := BoxMesh.new()
	beacon_mesh.size = Vector3(2.25, 0.16, 0.22)
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0, 4.52, 0.16)
	beacon.material_override = beacon_material
	exit_root.add_child(beacon)

	var exit_light := OmniLight3D.new()
	exit_light.name = "EmergencyExitLight"
	exit_light.position = Vector3(0.0, 3.6, 0.7)
	exit_light.light_color = Color(0.16, 1.0, 0.62)
	exit_light.light_energy = 0.8
	exit_light.omni_range = 8.0
	exit_root.add_child(exit_light)

	var route_marking := MeshInstance3D.new()
	route_marking.name = "EmergencyExitRouteMarking"
	var route_mesh := BoxMesh.new()
	route_mesh.size = Vector3(2.2, 0.035, radius * 0.34)
	route_marking.mesh = route_mesh
	route_marking.position = Vector3(0.0, 0.43, radius * 0.16)
	route_marking.material_override = beacon_material
	room.add_child(route_marking)

	var alarm_panel := MeshInstance3D.new()
	alarm_panel.name = "EmergencyAlarmCallPoint"
	var alarm_mesh := BoxMesh.new()
	alarm_mesh.size = Vector3(0.48, 0.72, 0.16)
	alarm_panel.mesh = alarm_mesh
	alarm_panel.position = Vector3(-radius * 0.52, 1.25, -radius * 0.34)
	var alarm_material := StandardMaterial3D.new()
	alarm_material.albedo_color = Color(0.72, 0.12, 0.10)
	alarm_material.emission_enabled = true
	alarm_material.emission = Color(0.85, 0.08, 0.04)
	alarm_material.emission_energy_multiplier = 0.7
	alarm_panel.material_override = alarm_material
	room.add_child(alarm_panel)

	var exit_sensor := Area3D.new()
	exit_sensor.name = "EmergencyExitSensor"
	exit_sensor.collision_layer = 0
	exit_sensor.collision_mask = 1
	exit_sensor.monitoring = true
	exit_sensor.position = Vector3(0.0, 1.15, -radius * 0.66)
	exit_sensor.set_meta("system_tower_id", tower_id)
	exit_sensor.set_meta("system_floor_number", floor_number)
	exit_sensor.set_meta("system_emergency_exit", true)
	var sensor_shape := CollisionShape3D.new()
	var sensor_box := BoxShape3D.new()
	sensor_box.size = Vector3(2.5, 2.4, 2.2)
	sensor_shape.shape = sensor_box
	exit_sensor.add_child(sensor_shape)
	exit_sensor.body_entered.connect(_on_floor_emergency_exit_body_entered.bind(exit_sensor))
	room.add_child(exit_sensor)


func _on_floor_emergency_exit_body_entered(body: Node3D, exit_sensor: Area3D) -> void:
	if not is_instance_valid(player) or body != player or not is_instance_valid(exit_sensor):
		return
	if exit_sensor.get_parent() != active_floor_root:
		return
	if str(exit_sensor.get_meta("system_tower_id", "")) != current_tower_id:
		return
	_set_status("تم تفعيل مسار الإخلاء للطابق %d — العودة الآمنة إلى بهو البرج." % int(exit_sensor.get_meta("system_floor_number", 0)))
	call_deferred("return_to_lobby")



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
	root.set_meta("system_tower_id", tower_id)
	root.set_meta("system_tower_floor_number", floor_number)
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
			_add_pool_changing_suite(root, "MensChangingSuite", Vector3(-21.0, 0.0, -2.0), accent, highlight, "MEN / تبديل ملابس الرجال")
			_add_pool_changing_suite(root, "WomensChangingSuite", Vector3(21.0, 0.0, -2.0), accent, highlight, "WOMEN / تبديل ملابس النساء")
			_add_pool_lifeguard_station(root, accent, highlight)
			for ladder_side in [-1.0, 1.0]:
				var ladder_label := "Left" if ladder_side < 0.0 else "Right"
				_add_facility_box(root, "PoolLadderRail_%s_A" % ladder_label, Vector3(ladder_side * 10.7, 1.45, -1.2), Vector3(0.16, 2.1, 0.16), highlight)
				_add_facility_box(root, "PoolLadderRail_%s_B" % ladder_label, Vector3(ladder_side * 10.7, 1.45, 1.2), Vector3(0.16, 2.1, 0.16), highlight)
				_add_facility_box(root, "PoolLadderStep_%s" % ladder_label, Vector3(ladder_side * 10.2, 0.55, 0.0), Vector3(1.1, 0.14, 2.4), accent)
			if floor_number == 18:
				for lane_index in range(5):
					_add_facility_box(root, "LapLaneDivider_%02d" % lane_index, Vector3(0.0, 1.24, -5.0 + float(lane_index) * 2.5), Vector3(19.2, 0.035, 0.045), highlight)
				for start_index in range(4):
					_add_facility_box(root, "LapStartBlock_%02d" % start_index, Vector3(-9.0, 0.72, -4.5 + float(start_index) * 3.0), Vector3(1.0, 0.8, 1.0), accent)
				_add_pool_room_sign(root, "PoolZoneSign", "المسبح الأولمبي — مسارات تدريب وسباحة", Vector3(0.0, 3.0, -9.0), Color(0.72, 0.94, 1.0))
			elif floor_number == 19:
				_add_facility_box(root, "FamilySplashPoolRim", Vector3(0.0, 0.42, 20.0), Vector3(12.0, 0.84, 8.0), accent)
				_add_facility_box(root, "FamilySplashPoolWater", Vector3(0.0, 0.88, 20.0), Vector3(10.6, 0.08, 6.6), highlight)
				_add_facility_box(root, "SplashPoolShallowStep", Vector3(-7.0, 0.2, 20.0), Vector3(2.0, 0.4, 8.0), accent)
				for fountain_index in range(3):
					_add_facility_box(root, "SplashFountain_%02d" % fountain_index, Vector3(-3.0 + float(fountain_index) * 3.0, 1.45, 20.0), Vector3(0.22, 1.0, 0.22), highlight)
				_add_pool_room_sign(root, "PoolZoneSign", "المسبح العائلي — منطقة المياه الضحلة", Vector3(0.0, 3.0, 15.0), Color(0.72, 0.94, 1.0))
			else:
				_add_facility_box(root, "SpaHotTubRim", Vector3(-5.0, 0.55, 20.0), Vector3(9.0, 1.1, 7.0), accent)
				_add_facility_box(root, "SpaHotTubWater", Vector3(-5.0, 1.12, 20.0), Vector3(7.8, 0.1, 5.8), highlight)
				_add_facility_box(root, "ThermalPoolRim", Vector3(7.0, 0.55, 20.0), Vector3(9.0, 1.1, 7.0), accent)
				_add_facility_box(root, "ThermalPoolWater", Vector3(7.0, 1.12, 20.0), Vector3(7.8, 0.1, 5.8), highlight)
				_add_facility_box(root, "SaunaCabin", Vector3(-14.0, 1.5, 16.0), Vector3(7.0, 3.0, 7.0), accent)
				_add_facility_box(root, "SaunaBench", Vector3(-14.0, 0.9, 17.5), Vector3(5.0, 0.5, 1.0), highlight)
				_add_facility_box(root, "SteamRoomCabin", Vector3(14.0, 1.5, 16.0), Vector3(7.0, 3.0, 7.0), accent)
				_add_pool_room_sign(root, "PoolZoneSign", "مركز السبا — جاكوزي وساونا وغرفة بخار", Vector3(0.0, 3.0, 14.0), Color(0.72, 0.94, 1.0))
			var water_volume := Area3D.new()
			water_volume.name = "PoolWaterVolume"
			water_volume.collision_layer = 0
			water_volume.collision_mask = 1
			water_volume.monitoring = true
			water_volume.monitorable = false
			water_volume.position = Vector3(0.0, 1.0, 0.0)
			var water_collision := CollisionShape3D.new()
			var water_shape := BoxShape3D.new()
			water_shape.size = Vector3(20.0, 2.2, 12.0)
			water_collision.shape = water_shape
			water_volume.add_child(water_collision)
			water_volume.body_entered.connect(_on_pool_water_body_entered.bind(root.global_position.y + 1.12))
			water_volume.body_exited.connect(_on_pool_water_body_exited)
			root.add_child(water_volume)
		"fitness_gym":
			for index in range(5):
				_add_facility_box(root, "GymMachine_%02d" % index, Vector3(-12.0 + float(index) * 6.0, 1.2, 0.0), Vector3(2.0, 2.4, 2.0), accent)
		"sports_court":
			_add_facility_box(root, "CourtSurface", Vector3(0.0, 0.55, 0.0), Vector3(24.0, 0.2, 15.0), accent)
			var court_body := StaticBody3D.new()
			court_body.name = "CourtPhysics"
			court_body.position.y = 0.55
			var court_collision := CollisionShape3D.new()
			var court_shape := BoxShape3D.new()
			court_shape.size = Vector3(24.0, 0.2, 15.0)
			court_collision.shape = court_shape
			court_body.add_child(court_collision)
			root.add_child(court_body)
			for side in [-1.0, 1.0]:
				_add_facility_box(root, "CourtHoop_%s" % str(side), Vector3(side * 10.0, 3.0, 0.0), Vector3(0.25, 5.0, 0.25), highlight)
			_add_facility_box(root, "BasketballBackboard", Vector3(0.0, 4.1, -6.65), Vector3(3.8, 2.0, 0.2), highlight)
			var rim := MeshInstance3D.new()
			rim.name = "BasketballRim"
			var rim_mesh := TorusMesh.new()
			rim_mesh.inner_radius = 0.58
			rim_mesh.outer_radius = 0.72
			rim.mesh = rim_mesh
			rim.rotation.x = PI * 0.5
			rim.position = Vector3(0.0, 3.05, -5.7)
			rim.material_override = highlight
			root.add_child(rim)
			var scoring_sensor := Area3D.new()
			scoring_sensor.name = "BasketballScoringSensor"
			scoring_sensor.collision_layer = 0
			scoring_sensor.collision_mask = 1
			var sensor_shape := SphereShape3D.new()
			sensor_shape.radius = 0.9
			var sensor_collision := CollisionShape3D.new()
			sensor_collision.shape = sensor_shape
			scoring_sensor.add_child(sensor_collision)
			scoring_sensor.position = Vector3(0.0, 3.0, -5.7)
			scoring_sensor.body_entered.connect(_on_basketball_sensor_body_entered)
			root.add_child(scoring_sensor)
		"bowling":
			for index in range(3):
				_add_facility_box(root, "BowlingLane_%02d" % index, Vector3(-7.0 + float(index) * 7.0, 0.55, -1.0), Vector3(5.0, 0.25, 14.0), accent)
			var lane_body := StaticBody3D.new()
			lane_body.name = "BowlingLanePhysics"
			lane_body.position = Vector3(0.0, 0.55, -1.0)
			var lane_collision := CollisionShape3D.new()
			var lane_shape := BoxShape3D.new()
			lane_shape.size = Vector3(5.0, 0.25, 14.0)
			lane_collision.shape = lane_shape
			lane_body.add_child(lane_collision)
			root.add_child(lane_body)
			var pin_positions := [
				Vector3(0.0, 1.35, -5.4),
				Vector3(-0.48, 1.35, -6.2), Vector3(0.48, 1.35, -6.2),
				Vector3(-0.96, 1.35, -7.0), Vector3(0.0, 1.35, -7.0), Vector3(0.96, 1.35, -7.0),
				Vector3(-1.44, 1.35, -7.8), Vector3(-0.48, 1.35, -7.8), Vector3(0.48, 1.35, -7.8), Vector3(1.44, 1.35, -7.8)
			]
			for pin_index in range(pin_positions.size()):
				var pin := RigidBody3D.new()
				pin.name = "BowlingPin_%02d" % pin_index
				pin.mass = 0.7
				pin.continuous_cd = true
				var pin_mesh := MeshInstance3D.new()
				var pin_capsule := CapsuleMesh.new()
				pin_capsule.radius = 0.28
				pin_capsule.height = 1.35
				pin_mesh.mesh = pin_capsule
				var pin_material := StandardMaterial3D.new()
				pin_material.albedo_color = Color(0.92, 0.92, 0.86)
				pin_mesh.material_override = pin_material
				pin.add_child(pin_mesh)
				var pin_collision := CollisionShape3D.new()
				var pin_shape := CapsuleShape3D.new()
				pin_shape.radius = 0.28
				pin_shape.height = 1.35
				pin_collision.shape = pin_shape
				pin.add_child(pin_collision)
				pin.position = pin_positions[pin_index]
				pin.set_meta("system_bowling_start_position", pin_positions[pin_index])
				root.add_child(pin)
		"cinema":
			_add_facility_box(root, "CinemaScreen", Vector3(0.0, 3.0, -10.0), Vector3(20.0, 6.0, 0.35), highlight)
			var program_screen := MeshInstance3D.new()
			program_screen.name = "CinemaProgramScreen"
			var program_mesh := QuadMesh.new()
			program_mesh.size = Vector2(18.0, 5.0)
			program_screen.mesh = program_mesh
			program_screen.position = Vector3(0.0, 3.0, -9.78)
			program_screen.rotation.y = PI
			var program_material := StandardMaterial3D.new()
			program_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			program_material.albedo_color = Color(0.025, 0.08, 0.15)
			program_material.emission_enabled = true
			program_material.emission = Color(0.02, 0.22, 0.42)
			program_material.emission_energy_multiplier = 1.4
			program_screen.material_override = program_material
			root.add_child(program_screen)
			var program_title := Label3D.new()
			program_title.name = "CinemaProgramTitle"
			program_title.text = "SYSTEM ORIGINALS\nالمشهد 1 | نداء بغداد\nتبدأ الحكاية عند بوابة دجلة"
			program_title.position = Vector3(0.0, 3.0, -9.70)
			program_title.rotation.y = PI
			program_title.font_size = 42
			program_title.pixel_size = 0.006
			program_title.modulate = Color(0.82, 0.94, 1.0)
			root.add_child(program_title)
			for row in range(3):
				for seat in range(6):
					_add_facility_box(root, "CinemaSeat_%02d_%02d" % [row, seat], Vector3(-9.0 + float(seat) * 3.6, 0.65, 1.0 + float(row) * 3.0), Vector3(1.4, 1.3, 1.2), accent)
		"arcade":
			for index in range(6):
				var cabinet_position := Vector3(-12.0 + float(index) * 4.8, 1.4, -2.0)
				_add_facility_box(root, "ArcadeCabinet_%02d" % index, cabinet_position, Vector3(2.0, 2.8, 1.4), highlight)
				var cabinet_screen := MeshInstance3D.new()
				cabinet_screen.name = "ArcadeCabinetScreen_%02d" % index
				var cabinet_screen_mesh := QuadMesh.new()
				cabinet_screen_mesh.size = Vector2(1.35, 0.95)
				cabinet_screen.mesh = cabinet_screen_mesh
				cabinet_screen.position = cabinet_position + Vector3(0.0, 0.25, 0.72)
				var cabinet_screen_material := StandardMaterial3D.new()
				cabinet_screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				cabinet_screen_material.albedo_color = Color(0.02, 0.08, 0.13)
				cabinet_screen_material.emission_enabled = true
				cabinet_screen_material.emission = Color(0.02, 0.34, 0.62) if index % 2 == 0 else Color(0.18, 0.34, 0.08)
				cabinet_screen_material.emission_energy_multiplier = 1.8
				cabinet_screen.material_override = cabinet_screen_material
				root.add_child(cabinet_screen)
				var cabinet_interaction := Area3D.new()
				cabinet_interaction.name = "ArcadeCabinetInteraction_%02d" % index
				cabinet_interaction.add_to_group("system_interactable")
				cabinet_interaction.collision_layer = 1
				cabinet_interaction.collision_mask = 0
				cabinet_interaction.monitoring = true
				cabinet_interaction.position = cabinet_position
				cabinet_interaction.set_meta("system_tower_id", tower_id)
				cabinet_interaction.set_meta("system_tower_floor_number", floor_number)
				cabinet_interaction.set_meta("system_facility_type", "arcade")
				cabinet_interaction.set_meta("system_arcade_cabinet_id", index)
				cabinet_interaction.set_meta("system_arcade_cabinet_mode", ["shooter", "memory", "reflex", "puzzle", "memory", "reflex"][index])
				cabinet_interaction.set_meta("system_interaction_prompt", "جهاز SYSTEM ARCADE %d — اضغط للعب" % (index + 1))
				var cabinet_shape_node := CollisionShape3D.new()
				var cabinet_shape := BoxShape3D.new()
				cabinet_shape.size = Vector3(2.4, 3.0, 2.0)
				cabinet_shape_node.shape = cabinet_shape
				cabinet_interaction.add_child(cabinet_shape_node)
				root.add_child(cabinet_interaction)
			for target_index in range(5):
				var target_x := -4.0 + float(target_index) * 2.0
				var target_visual := MeshInstance3D.new()
				target_visual.name = "ArcadeTarget_%02d" % target_index
				var target_mesh := SphereMesh.new()
				target_mesh.radius = 0.48
				target_mesh.height = 0.96
				target_visual.mesh = target_mesh
				var target_material := StandardMaterial3D.new()
				target_material.albedo_color = Color(0.1, 0.9, 0.58)
				target_material.emission_enabled = true
				target_material.emission = Color(0.05, 0.7, 0.35)
				target_visual.material_override = target_material
				target_visual.position = Vector3(target_x, 2.0, -5.4)
				root.add_child(target_visual)
				var target_sensor := Area3D.new()
				target_sensor.name = "ArcadeTargetSensor_%02d" % target_index
				target_sensor.collision_layer = 0
				target_sensor.collision_mask = 1
				target_sensor.monitoring = true
				var target_collision := CollisionShape3D.new()
				var target_shape := SphereShape3D.new()
				target_shape.radius = 1.25
				target_collision.shape = target_shape
				target_sensor.add_child(target_collision)
				target_sensor.position = Vector3(target_x, 2.0, -5.4)
				target_sensor.body_entered.connect(_on_arcade_target_body_entered.bind(target_index))
				root.add_child(target_sensor)
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
			if facility_type == "robotics_lab":
				var assembly := Node3D.new()
				assembly.name = "RobotAssemblyDisplay"
				assembly.position = Vector3(0.0, 0.5, -4.0)
				root.add_child(assembly)
				var robotics_stats: Dictionary = facility_activity_stats.get("robotics_lab", {})
				var assembly_complete := int(robotics_stats.get("plays", 0)) > 0
				var robot_colors: Array[Color] = [
					Color(0.12, 0.72, 0.86),
					Color(0.78, 0.82, 0.88),
					Color(0.95, 0.62, 0.18),
					Color(0.18, 0.68, 0.82),
					Color(0.18, 0.68, 0.82)
				]
				var target_positions: Array[Vector3] = [
					Vector3(0.0, 0.3, 0.0),
					Vector3(0.0, 1.2, 0.0),
					Vector3(0.0, 2.35, 0.0),
					Vector3(-0.92, 1.15, 0.0),
					Vector3(0.92, 1.15, 0.0)
				]
				for part_index in range(5):
					var part := MeshInstance3D.new()
					part.name = "RobotAssemblyPart_%02d" % part_index
					var part_material := StandardMaterial3D.new()
					part_material.albedo_color = robot_colors[part_index]
					part_material.metallic = 0.62
					part_material.roughness = 0.28
					part_material.emission_enabled = true
					part_material.emission = part_material.albedo_color * 0.18
					if part_index == 0:
						var base_mesh := BoxMesh.new()
						base_mesh.size = Vector3(1.9, 0.45, 1.5)
						part.mesh = base_mesh
					elif part_index == 1:
						var torso_mesh := CapsuleMesh.new()
						torso_mesh.radius = 0.52
						torso_mesh.height = 1.55
						part.mesh = torso_mesh
					elif part_index == 2:
						var head_mesh := SphereMesh.new()
						head_mesh.radius = 0.48
						head_mesh.height = 0.96
						part.mesh = head_mesh
					else:
						var arm_mesh := BoxMesh.new()
						arm_mesh.size = Vector3(0.34, 1.25, 0.42)
						part.mesh = arm_mesh
					part.material_override = part_material
					var target_position: Vector3 = target_positions[part_index]
					part.set_meta("system_robot_target_position", target_position)
					part.set_meta("system_robot_assembled", assembly_complete)
					part.position = target_position
					part.visible = assembly_complete
					part.scale = Vector3.ONE if assembly_complete else Vector3.ZERO
					assembly.add_child(part)
				if assembly_complete:
					_start_robot_idle_animation(assembly)
			elif facility_type == "vr_lab":
				_build_vr_simulation_course(root, highlight, accent)
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


func open_pool_service(target: Node) -> void:
	if target == null or not is_instance_valid(target) or not target.has_meta("system_pool_service_type"):
		return
	var service_type := str(target.get_meta("system_pool_service_type", ""))
	var service_titles := {
		"locker": "خزائن المسبح — خدمة الزوار",
		"shower": "منطقة الاستحمام — مرافق النظافة",
		"lifeguard": "محطة المنقذ — السلامة والإسعاف"
	}
	if not service_titles.has(service_type):
		return
	current_tower_id = str(target.get_meta("system_tower_id", "entertainment_tower_baghdad"))
	current_staff_id = ""
	current_pool_service_suite = target.get_parent() as Node3D if service_type == "locker" else null
	_clear_dynamic_controls()
	title_label.text = str(service_titles[service_type])
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	status_label.text = "الطابق %d — اختر الخدمة المطلوبة." % int(target.get_meta("system_tower_floor_number", 0))
	var action_button := Button.new()
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match service_type:
		"locker":
			action_button.text = "عرض خزانتي الحالية" if is_instance_valid(player) and bool(player.get_meta("system_pool_locker_reserved", false)) else "استلام خزانة شخصية"
		"shower":
			action_button.text = "استخدام الدش وتجهيز السباحة"
		"lifeguard":
			action_button.text = "طلب مساعدة المنقذ"
	action_button.pressed.connect(Callable(self, "_use_pool_service").bind(service_type, current_pool_service_suite))
	content.add_child(action_button)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): panel.hide())
	content.add_child(close_button)
	panel.show()


func _use_pool_service(service_type: String, suite: Node3D = null) -> void:
	if not is_instance_valid(player):
		return
	match service_type:
		"locker":
			if bool(player.get_meta("system_pool_locker_reserved", false)):
				_set_status("خزانتك الحالية هي رقم %s. تبقى محجوزة لك حتى مغادرة مرافق المسبح." % str(player.get_meta("system_pool_locker_id", "—")))
				return
			var locker_suite := suite if is_instance_valid(suite) else current_pool_service_suite
			if not is_instance_valid(locker_suite):
				_set_status("تعذر تحديد غرفة تبديل الملابس. اقترب من محطة الخزائن وحاول مجدداً.")
				return
			var assigned_locker: MeshInstance3D
			var assigned_index := -1
			for locker_index in range(6):
				var candidate := locker_suite.get_node_or_null("Locker_%02d" % locker_index) as MeshInstance3D
				if candidate != null and not bool(candidate.get_meta("system_pool_locker_occupied", false)):
					assigned_locker = candidate
					assigned_index = locker_index
					break
			if assigned_locker == null:
				_set_status("جميع خزائن هذه الغرفة مشغولة حالياً. جرّب غرفة تبديل الملابس الأخرى.")
				return
			assigned_locker.set_meta("system_pool_locker_occupied", true)
			assigned_locker.set_meta("system_pool_locker_owner", player.get_instance_id())
			assigned_locker.set_meta("system_pool_locker_original_material", assigned_locker.material_override)
			var occupied_material := StandardMaterial3D.new()
			occupied_material.albedo_color = Color(0.88, 0.48, 0.16)
			occupied_material.metallic = 0.38
			occupied_material.roughness = 0.42
			assigned_locker.material_override = occupied_material
			player.set_meta("system_pool_locker_reserved", true)
			player.set_meta("system_pool_locker_tower", current_tower_id)
			player.set_meta("system_pool_locker_floor", int(active_floor_root.get_meta("system_tower_floor_number", 18)) if is_instance_valid(active_floor_root) else int(locker_suite.get_parent().get_meta("system_tower_floor_number", 18)))
			player.set_meta("system_pool_locker_suite", str(locker_suite.name))
			player.set_meta("system_pool_locker_id", str(assigned_locker.name))
			current_pool_service_suite = locker_suite
			_set_status("تم حجز الخزانة رقم %d لك فعلياً في غرفة %s. ستبقى مغلقة باسمك حتى مغادرة الطابق." % [assigned_index + 1, "الرجال" if locker_suite.name == "MensChangingSuite" else "النساء"])
		"shower":
			player.set_meta("system_pool_showered", true)
			_set_status("اكتمل استخدام الدش. أصبحت جاهزاً للسباحة أو مغادرة المسبح.")
		"lifeguard":
			player.set_meta("system_pool_assistance_requested", true)
			if _dispatch_pool_supervisor_to_player():
				_set_status("استلم مشرف المسبح طلبك ويتجه إليك من محطة الإنقاذ.")
			else:
				_set_status("تم تسجيل طلب المساعدة وإبلاغ محطة المنقذ. سيستجيب المشرف عند وصوله إلى الطابق.")
		_:
			return


func _release_pool_locker() -> void:
	if not is_instance_valid(player) or not bool(player.get_meta("system_pool_locker_reserved", false)):
		return
	var locker_id := str(player.get_meta("system_pool_locker_id", ""))
	var tower := tower_nodes.get("entertainment_tower_baghdad") as Node3D
	var locker := tower.find_child(locker_id, true, false) as MeshInstance3D if tower != null and not locker_id.is_empty() else null
	if locker != null and int(locker.get_meta("system_pool_locker_owner", -1)) == player.get_instance_id():
		locker.remove_meta("system_pool_locker_occupied")
		locker.remove_meta("system_pool_locker_owner")
		var original_material: Variant = locker.get_meta("system_pool_locker_original_material", null)
		if original_material is Material:
			locker.material_override = original_material
		locker.remove_meta("system_pool_locker_original_material")
	player.remove_meta("system_pool_locker_reserved")
	player.remove_meta("system_pool_locker_tower")
	player.remove_meta("system_pool_locker_floor")
	player.remove_meta("system_pool_locker_suite")
	player.remove_meta("system_pool_locker_id")


func _clear_pool_visit_state() -> void:
	_release_pool_locker()
	if is_instance_valid(player):
		player.remove_meta("system_pool_showered")
		player.remove_meta("system_pool_assistance_requested")
	current_pool_service_suite = null


func _dispatch_pool_supervisor_to_player() -> bool:
	if not is_instance_valid(player) or not staff_by_tower.has("entertainment_tower_baghdad"):
		return false
	var staff_ids: Array = staff_by_tower.get("entertainment_tower_baghdad", [])
	if staff_ids.size() <= 3:
		return false
	var tower := tower_nodes.get("entertainment_tower_baghdad") as Node3D
	var supervisor := tower.find_child("TowerStaff_" + str(staff_ids[3]), true, false) as Node3D if tower != null else null
	if supervisor == null or supervisor.get_parent() != active_floor_root or int(supervisor.get_meta("system_staff_duty_floor", 0)) not in [18, 19]:
		return false
	var model := _find_tower_staff_model(supervisor)
	if model == null:
		return false
	var previous_tween: Variant = supervisor.get_meta("system_staff_patrol_tween", null)
	if previous_tween is Tween and (previous_tween as Tween).is_running():
		(previous_tween as Tween).kill()
	supervisor.set_meta("system_staff_assistance_requested", true)
	supervisor.set_meta("system_staff_assistance_target", player.global_position)
	model.call("set_activity", "walk")
	var response_tween := supervisor.create_tween()
	supervisor.set_meta("system_staff_patrol_tween", response_tween)
	response_tween.tween_property(supervisor, "global_position", player.global_position + Vector3(1.5, 0.0, 0.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	response_tween.tween_callback(func():
		if is_instance_valid(supervisor):
			supervisor.set_meta("system_staff_assistance_arrived", true)
			if is_instance_valid(model):
				model.call("set_activity", "idle")
	)
	return true


func open_facility_service(tower_id: String, floor_number: int, facility_type: String) -> void:
	if bowling_throw_in_progress or facility_projectile_in_progress:
		return
	if not TOWER_CONFIG.has(tower_id) or _facility_activity_definition(facility_type).is_empty():
		return
	current_tower_id = tower_id
	current_staff_id = ""
	var facility_room := _ensure_floor_room(tower_id, floor_number)
	current_facility_root = facility_room.get_node_or_null("SpecialFacility_" + facility_type) as Node3D if facility_room != null else null
	facility_aim = 0.0
	if facility_type == "arcade":
		selected_arcade_mode = "shooter"
	_clear_dynamic_controls()
	var facility_names := {
		"swimming_pool": "مسبح SYSTEM — تحدي السباحة",
		"fitness_gym": "نادي اللياقة — تحدي التمارين",
		"sports_court": "الملعب — تحدي التصويب",
		"bowling": "صالة البولينغ — جولة النقاط",
		"cinema": "سينما SYSTEM — جلسة العرض",
		"arcade": "مركز الألعاب — تحدي الأهداف",
		"family_zone": "منطقة العائلات — رحلة الاستكشاف",
		"rooftop_leisure": "حدائق السطح — تحدي التصوير",
		"robotics_lab": "مختبر الروبوتات — تركيب النموذج",
		"ai_lab": "مختبر الذكاء الاصطناعي — تحليل الإشارات",
		"vr_lab": "مختبر الواقع الافتراضي — مسار المحاكاة"
	}
	title_label.text = str(facility_names.get(facility_type, "نشاط SYSTEM"))
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	status_label.text = "الطابق %d — ابدأ النشاط ثم أكمل خطواته لتحصل على مكافأة." % floor_number
	var close_button := Button.new()
	close_button.text = "إغلاق النشاط"
	close_button.pressed.connect(func(): panel.hide())
	content.add_child(close_button)
	_add_facility_activity_controls(facility_type)
	panel.show()


func _calculate_arcade_mode_index(cabinet_mode: String) -> int:
	return ["shooter", "memory", "reflex", "puzzle"].find(cabinet_mode)


func _arcade_puzzle_questions() -> Array:
	return [
		{"prompt": "3 + 4 = ؟", "answer": 7, "choices": [5, 7, 8, 9]},
		{"prompt": "9 - 2 = ؟", "answer": 7, "choices": [6, 7, 5, 8]},
		{"prompt": "3 × 3 = ؟", "answer": 9, "choices": [7, 8, 9, 6]},
		{"prompt": "12 ÷ 3 = ؟", "answer": 4, "choices": [3, 4, 5, 6]},
		{"prompt": "5 + 6 = ؟", "answer": 11, "choices": [9, 10, 11, 12]}
	]


func _evaluate_arcade_puzzle_answer(questions: Array, cursor: int, input_value: int) -> Dictionary:
	if cursor < 0 or cursor >= questions.size():
		return {"valid": false, "correct": false, "complete": false, "next_cursor": cursor}
	var question: Dictionary = questions[cursor]
	var correct := int(question.get("answer", -1)) == input_value
	return {"valid": true, "correct": correct, "complete": correct and cursor + 1 >= questions.size(), "next_cursor": cursor + 1 if correct else cursor}


func _show_arcade_puzzle_question() -> void:
	if active_facility_activity.is_empty() or str(active_facility_activity.get("mode", "")) != "puzzle":
		return
	var questions: Array = active_facility_activity.get("puzzle_questions", [])
	var cursor := int(active_facility_activity.get("puzzle_cursor", 0))
	if cursor < 0 or cursor >= questions.size():
		return
	var question: Dictionary = questions[cursor]
	var puzzle_status := content.get_node_or_null("ArcadePuzzleStatus") as Label
	if puzzle_status != null:
		puzzle_status.text = "%s  |  السؤال %d من %d" % [str(question.get("prompt", "حل اللغز")), cursor + 1, questions.size()]
	var puzzle_buttons := content.get_node_or_null("ArcadePuzzleButtons") as HBoxContainer
	if puzzle_buttons != null:
		puzzle_buttons.visible = true
		var choices: Array = question.get("choices", [])
		for choice_index in range(puzzle_buttons.get_child_count()):
			var choice_button := puzzle_buttons.get_child(choice_index) as Button
			if choice_button == null:
				continue
			if choice_index < choices.size():
				choice_button.text = str(choices[choice_index])
				choice_button.set_meta("system_arcade_puzzle_answer", int(choices[choice_index]))
				choice_button.visible = true
			else:
				choice_button.visible = false


func _submit_arcade_puzzle_button(button: Button) -> void:
	if button == null or active_facility_activity.is_empty() or str(active_facility_activity.get("mode", "")) != "puzzle":
		return
	var questions: Array = active_facility_activity.get("puzzle_questions", [])
	var cursor := int(active_facility_activity.get("puzzle_cursor", 0))
	var answer := int(button.get_meta("system_arcade_puzzle_answer", -1))
	var result := _evaluate_arcade_puzzle_answer(questions, cursor, answer)
	if not bool(result.get("correct", false)):
		var lives := maxi(0, int(active_facility_activity.get("lives", 0)) - 1)
		active_facility_activity["lives"] = lives
		if lives <= 0:
			active_facility_activity.clear()
			_set_status("انتهت لعبة لغز الأرقام — نفدت المحاولات ولم تُمنح مكافأة.")
			return
		_set_status("إجابة غير صحيحة — بقيت %d محاولات. حاول مجدداً." % lives)
		return
	active_facility_activity["puzzle_cursor"] = int(result.get("next_cursor", cursor + 1))
	active_facility_activity["step"] = int(active_facility_activity.get("step", 0)) + 1
	active_facility_activity["score"] = int(active_facility_activity.get("score", 0)) + 20
	if bool(result.get("complete", false)):
		_complete_facility_activity()
	else:
		_show_arcade_puzzle_question()
		_set_status("إجابة صحيحة! انتقل إلى اللغز التالي.")


func open_arcade_cabinet(tower_id: String, floor_number: int, cabinet_id: int, cabinet_mode: String) -> void:
	if cabinet_id < 0 or cabinet_id >= 6 or cabinet_mode not in ["shooter", "memory", "reflex", "puzzle"]:
		return
	open_facility_service(tower_id, floor_number, "arcade")
	selected_arcade_mode = cabinet_mode
	var mode_index := _calculate_arcade_mode_index(cabinet_mode)
	var selector := content.get_node_or_null("ArcadeModeSelector") as OptionButton
	if selector != null:
		selector.select(mode_index)
	_on_arcade_mode_selected(mode_index)
	var cabinet_game_title := "لغز الأرقام" if cabinet_mode == "puzzle" else ("ذاكرة الألوان" if cabinet_mode == "memory" else ("سرعة الاستجابة" if cabinet_mode == "reflex" else "ميدان التصويب"))
	title_label.text = "SYSTEM ARCADE — الجهاز %d | %s" % [cabinet_id + 1, cabinet_game_title]
	_set_status("تم تشغيل الجهاز %d. اختر بدء الجولة عندما تكون مستعداً." % (cabinet_id + 1))


func _facility_activity_definition(facility_type: String) -> Dictionary:
	var definitions := {
		"swimming_pool": {"action": "lap", "action_label": "إكمال لفة سباحة", "goal": 3, "reward": 45, "title": "السباحة"},
		"fitness_gym": {"action": "rep", "action_label": "إكمال مجموعة تمارين", "goal": 8, "reward": 35, "title": "اللياقة"},
		"sports_court": {"action": "shot", "action_label": "تنفيذ دور المباراة", "goal": 10, "reward": 70, "title": "مباراة كرة السلة 1 ضد 1"},
		"bowling": {"action": "throw", "action_label": "رمي كرة البولينغ", "goal": 10, "reward": 70, "title": "البولينغ"},
		"cinema": {"action": "watch", "action_label": "مشاهدة المشهد التالي", "goal": 3, "reward": 15, "title": "جلسة السينما — ثلاثة مشاهد"},
		"arcade": {"action": "hit", "action_label": "إطلاق الكرة الضوئية", "goal": 10, "reward": 55, "title": "SYSTEM ARCADE — تحدي الأهداف"},
		"family_zone": {"action": "discover", "action_label": "اكتشاف محطة عائلية", "goal": 3, "reward": 30, "title": "استكشاف العائلة"},
		"rooftop_leisure": {"action": "photo", "action_label": "التقاط صورة للسطح", "goal": 1, "reward": 20, "title": "استكشاف السطح"},
		"robotics_lab": {"action": "assemble", "action_label": "تركيب القطعة التالية", "goal": 5, "reward": 95, "title": "تجميع روبوت SYSTEM بخمس قطع"},
		"ai_lab": {"action": "analyze", "action_label": "تحليل إشارة جديدة", "goal": 3, "reward": 65, "title": "تحليل الذكاء الاصطناعي"},
		"vr_lab": {"action": "checkpoint", "action_label": "اجتياز نقطة المحاكاة", "goal": 3, "reward": 60, "title": "محاكاة الواقع الافتراضي"}
	}
	return definitions.get(facility_type, {})


func _add_facility_activity_controls(facility_type: String) -> void:
	var definition := _facility_activity_definition(facility_type)
	if definition.is_empty():
		return
	var description := Label.new()
	description.name = "FacilityActivityInstructions"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if facility_type == "arcade":
		description.text = "اختر جهازاً من أجهزة SYSTEM ARCADE ثم أكمل اللعبة. تتوفر ألعاب التصويب والذاكرة وسرعة الاستجابة وحل الأرقام."
	elif facility_type == "vr_lab":
		description.text = "ابدأ المحاكاة ثم تحرّك داخل المسار ثلاثي الأبعاد واعبر بوابات الطاقة الثلاث بالترتيب حتى تصل إلى منصة الخروج."
	else:
		description.text = "%s: أكمل %d خطوات. تُحفظ أفضل نتيجة وعدد الجولات على هذا الجهاز." % [str(definition["title"]), int(definition["goal"])]
	content.add_child(description)
	if facility_type in ["bowling", "sports_court"] or (facility_type == "arcade" and selected_arcade_mode == "shooter"):
		var aim_label := Label.new()
		aim_label.name = "FacilityAimLabel"
		aim_label.text = "اتجاه الرمية: وسط"
		content.add_child(aim_label)
		var aim_slider := HSlider.new()
		aim_slider.name = "FacilityAimSlider"
		aim_slider.min_value = -1.0
		aim_slider.max_value = 1.0
		aim_slider.step = 0.05
		aim_slider.value = 0.0
		aim_slider.custom_minimum_size = Vector2(260.0, 38.0)
		aim_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		aim_slider.value_changed.connect(_on_facility_aim_changed)
		content.add_child(aim_slider)
	if facility_type == "arcade":
		var mode_label := Label.new()
		mode_label.name = "ArcadeModeLabel"
		mode_label.text = "اختر لعبة الجهاز:"
		content.add_child(mode_label)
		var mode_selector := OptionButton.new()
		mode_selector.name = "ArcadeModeSelector"
		mode_selector.add_item("ميدان التصويب الفيزيائي")
		mode_selector.add_item("تحدي ذاكرة الألوان")
		mode_selector.add_item("اختبار سرعة الاستجابة")
		mode_selector.add_item("تحدي لغز الأرقام")
		mode_selector.item_selected.connect(_on_arcade_mode_selected)
		content.add_child(mode_selector)
		var memory_status := Label.new()
		memory_status.name = "ArcadeMemoryStatus"
		memory_status.text = "اختر تحدي الذاكرة ثم ابدأ الجولة."
		memory_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		memory_status.visible = false
		content.add_child(memory_status)
		var reflex_status := Label.new()
		reflex_status.name = "ArcadeReflexStatus"
		reflex_status.text = "انتظر الإشارة ثم اضغط بأسرع ما تستطيع."
		reflex_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reflex_status.visible = false
		content.add_child(reflex_status)
		var puzzle_status := Label.new()
		puzzle_status.name = "ArcadePuzzleStatus"
		puzzle_status.text = "حل خمسة ألغاز حسابية متتالية."
		puzzle_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		puzzle_status.visible = false
		content.add_child(puzzle_status)
		var puzzle_buttons := HBoxContainer.new()
		puzzle_buttons.name = "ArcadePuzzleButtons"
		for puzzle_index in range(4):
			var puzzle_button := Button.new()
			puzzle_button.name = "ArcadePuzzleButton_%d" % puzzle_index
			puzzle_button.text = "—"
			puzzle_button.custom_minimum_size = Vector2(64.0, 54.0)
			puzzle_button.pressed.connect(_submit_arcade_puzzle_button.bind(puzzle_button))
			puzzle_buttons.add_child(puzzle_button)
		puzzle_buttons.visible = false
		content.add_child(puzzle_buttons)
		var memory_buttons := HBoxContainer.new()
		memory_buttons.name = "ArcadeMemoryButtons"
		for color_index in range(4):
			var memory_button := Button.new()
			memory_button.name = "ArcadeMemoryButton_%d" % color_index
			memory_button.text = ["أزرق", "أحمر", "أخضر", "ذهبي"][color_index]
			memory_button.custom_minimum_size = Vector2(72.0, 54.0)
			memory_button.pressed.connect(_submit_arcade_memory_input.bind(color_index))
			memory_buttons.add_child(memory_button)
		memory_buttons.visible = false
		content.add_child(memory_buttons)
	var start_button := Button.new()
	start_button.name = "StartFacilityActivityButton"
	start_button.text = "بدء النشاط"
	start_button.pressed.connect(start_facility_activity.bind(facility_type))
	content.add_child(start_button)
	var action_button := Button.new()
	action_button.name = "FacilityActivityActionButton"
	action_button.text = str(definition["action_label"])
	action_button.pressed.connect(perform_facility_activity.bind(str(definition["action"])))
	if facility_type == "vr_lab":
		action_button.visible = false
	content.add_child(action_button)
	var stats := Dictionary(facility_activity_stats.get(facility_type, {}))
	var stats_label := Label.new()
	stats_label.name = "FacilityActivityStats"
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.text = "الجولات المكتملة: %d | أفضل نتيجة: %d" % [int(stats.get("plays", 0)), int(stats.get("best_score", 0))]
	content.add_child(stats_label)


func _on_arcade_mode_selected(index: int) -> void:
	selected_arcade_mode = ["shooter", "memory", "reflex", "puzzle"][clampi(index, 0, 3)]
	var aim_slider := content.get_node_or_null("FacilityAimSlider") as HSlider
	var aim_label := content.get_node_or_null("FacilityAimLabel") as Label
	var memory_buttons := content.get_node_or_null("ArcadeMemoryButtons") as HBoxContainer
	var memory_status := content.get_node_or_null("ArcadeMemoryStatus") as Label
	if memory_status != null:
		memory_status.visible = selected_arcade_mode == "memory"
	if aim_slider != null:
		aim_slider.visible = selected_arcade_mode == "shooter"
	if aim_label != null:
		aim_label.visible = selected_arcade_mode == "shooter"
	if memory_buttons != null:
		memory_buttons.visible = selected_arcade_mode == "memory"
	var reflex_status := content.get_node_or_null("ArcadeReflexStatus") as Label
	if reflex_status != null:
		reflex_status.visible = selected_arcade_mode == "reflex"
	var puzzle_status := content.get_node_or_null("ArcadePuzzleStatus") as Label
	if puzzle_status != null:
		puzzle_status.visible = selected_arcade_mode == "puzzle"
	var puzzle_buttons := content.get_node_or_null("ArcadePuzzleButtons") as HBoxContainer
	if puzzle_buttons != null:
		puzzle_buttons.visible = selected_arcade_mode == "puzzle"
	var action_button := content.get_node_or_null("FacilityActivityActionButton") as Button
	if action_button != null:
		action_button.visible = selected_arcade_mode in ["shooter", "reflex"]
		action_button.text = "إطلاق الكرة الضوئية" if selected_arcade_mode == "shooter" else "ضغط عند الإشارة"


func _start_arcade_memory_preview() -> void:
	active_facility_activity["memory_preview"] = true
	var memory_status := content.get_node_or_null("ArcadeMemoryStatus") as Label
	if memory_status != null:
		memory_status.text = "احفظ التسلسل: أخضر ← أزرق ← ذهبي ← أحمر ← أخضر"
	get_tree().create_timer(2.8).timeout.connect(_on_arcade_memory_preview_finished)


func _on_arcade_memory_preview_finished() -> void:
	if active_facility_activity.is_empty() or str(active_facility_activity.get("mode", "")) != "memory":
		return
	active_facility_activity["memory_preview"] = false
	var memory_status := content.get_node_or_null("ArcadeMemoryStatus") as Label
	if memory_status != null:
		memory_status.text = "انتهى العرض! أعد ترتيب الألوان بالضغط على الأزرار."


func _evaluate_arcade_memory_input(sequence: Array, cursor: int, input_index: int) -> Dictionary:
	if cursor < 0 or cursor >= sequence.size():
		return {"valid": false, "complete": false, "next_cursor": cursor}
	var correct := int(sequence[cursor]) == input_index
	var next_cursor := cursor + 1 if correct else 0
	return {"valid": correct, "complete": correct and next_cursor >= sequence.size(), "next_cursor": next_cursor}


func _submit_arcade_memory_input(input_index: int) -> void:
	if active_facility_activity.is_empty() or str(active_facility_activity.get("mode", "")) != "memory":
		return
	if bool(active_facility_activity.get("memory_preview", true)):
		_set_status("انتظر انتهاء عرض التسلسل أولاً.")
		return
	var sequence: Array = active_facility_activity.get("memory_sequence", [])
	var cursor := int(active_facility_activity.get("memory_cursor", 0))
	var result := _evaluate_arcade_memory_input(sequence, cursor, input_index)
	if not bool(result.get("valid", false)):
		var lives := maxi(0, int(active_facility_activity.get("lives", 0)) - 1)
		active_facility_activity["lives"] = lives
		active_facility_activity["memory_cursor"] = 0
		if lives <= 0:
			active_facility_activity.clear()
			_set_status("انتهت لعبة الذاكرة — نفدت المحاولات ولم تُمنح مكافأة.")
			return
		_set_status("خطأ في تسلسل الذاكرة — المحاولات المتبقية: %d. أعد الحفظ." % lives)
		_start_arcade_memory_preview()
		return
	var next_cursor := int(result.get("next_cursor", cursor))
	active_facility_activity["memory_cursor"] = next_cursor
	active_facility_activity["step"] = next_cursor
	active_facility_activity["score"] = int(active_facility_activity.get("score", 0)) + 10
	var memory_status := content.get_node_or_null("ArcadeMemoryStatus") as Label
	if memory_status != null:
		memory_status.text = "إجابة صحيحة: %d/%d" % [next_cursor, sequence.size()]
	if bool(result.get("complete", false)):
		_complete_facility_activity()
	else:
		_set_status("تحدي الذاكرة — تقدمك %d/%d" % [next_cursor, sequence.size()])


func _schedule_arcade_reflex_signal() -> void:
	if active_facility_activity.is_empty() or str(active_facility_activity.get("mode", "")) != "reflex":
		return
	active_facility_activity["reflex_ready"] = false
	var reflex_status := content.get_node_or_null("ArcadeReflexStatus") as Label
	if reflex_status != null:
		reflex_status.text = "استعد... لا تضغط قبل الإشارة!"
	var signal_id := int(active_facility_activity.get("reflex_signal_id", 0)) + 1
	active_facility_activity["reflex_signal_id"] = signal_id
	var wait_seconds := randf_range(1.0, 2.4)
	get_tree().create_timer(wait_seconds).timeout.connect(_on_arcade_reflex_signal.bind(signal_id))


func _on_arcade_reflex_signal(signal_id: int) -> void:
	if active_facility_activity.is_empty() or str(active_facility_activity.get("mode", "")) != "reflex":
		return
	if int(active_facility_activity.get("reflex_signal_id", -1)) != signal_id:
		return
	active_facility_activity["reflex_ready"] = true
	active_facility_activity["reflex_signal_at"] = Time.get_ticks_msec()
	var reflex_status := content.get_node_or_null("ArcadeReflexStatus") as Label
	if reflex_status != null:
		reflex_status.text = "الإشارة ظهرت! اضغط الآن بسرعة!"


func _calculate_arcade_reflex_score(reaction_ms: int) -> int:
	if reaction_ms < 0 or reaction_ms > 5000:
		return 0
	return clampi(25 - int(reaction_ms / 80), 1, 25)


func _submit_arcade_reflex_action() -> Dictionary:
	if active_facility_activity.is_empty() or str(active_facility_activity.get("mode", "")) != "reflex":
		return {"success": false, "reason": "اختبار الاستجابة غير نشط."}
	if not bool(active_facility_activity.get("reflex_ready", false)):
		var lives := maxi(0, int(active_facility_activity.get("lives", 0)) - 1)
		active_facility_activity["lives"] = lives
		if lives <= 0:
			active_facility_activity.clear()
			_set_status("انتهى اختبار الاستجابة — ضغطت مبكراً ونفدت المحاولات.")
			return {"success": false, "completed": true, "lives_remaining": 0}
		_set_status("ضغطت قبل الإشارة! بقيت %d محاولات." % lives)
		_schedule_arcade_reflex_signal()
		return {"success": false, "completed": false, "lives_remaining": lives}
	var reaction_ms := maxi(0, Time.get_ticks_msec() - int(active_facility_activity.get("reflex_signal_at", Time.get_ticks_msec())))
	var gained := _calculate_arcade_reflex_score(reaction_ms)
	var step := int(active_facility_activity.get("step", 0)) + 1
	active_facility_activity["step"] = step
	active_facility_activity["score"] = int(active_facility_activity.get("score", 0)) + gained
	active_facility_activity["reflex_ready"] = false
	var goal := int(active_facility_activity.get("goal", 5))
	if step >= goal:
		var final_result := _complete_facility_activity()
		final_result["last_reaction_ms"] = reaction_ms
		return final_result
	_set_status("زمن الاستجابة: %d ms | +%d نقطة | الجولة %d/%d" % [reaction_ms, gained, step, goal])
	_schedule_arcade_reflex_signal()
	return {"success": true, "completed": false, "step": step, "reaction_ms": reaction_ms, "score_gain": gained, "score": int(active_facility_activity.get("score", 0))}


func _on_facility_aim_changed(value: float) -> void:
	facility_aim = clampf(value, -1.0, 1.0)
	var aim_label := content.get_node_or_null("FacilityAimLabel") as Label
	if aim_label != null:
		var direction_name := "يسار" if facility_aim < -0.15 else ("يمين" if facility_aim > 0.15 else "وسط")
		aim_label.text = "اتجاه الرمية: " + direction_name


func start_facility_activity(facility_type: String) -> bool:
	if bowling_throw_in_progress or facility_projectile_in_progress:
		return false
	var definition := _facility_activity_definition(facility_type)
	if definition.is_empty():
		return false
	active_facility_activity = {
		"type": facility_type,
		"action": str(definition["action"]),
		"step": 0,
		"score": 0,
		"goal": int(definition["goal"]),
		"reward": int(definition["reward"]),
		"started": true,
		"frame": 1,
		"frame_rolls": [],
		"rolls": []
	}
	if facility_type == "vr_lab":
		active_facility_activity["exit_unlocked"] = false
		var vr_course := current_facility_root.get_node_or_null("VRSimulationCourse") as Node3D if is_instance_valid(current_facility_root) else null
		var exit_sensor := vr_course.get_node_or_null("VRSimulationExitSensor") as Area3D if vr_course != null else null
		if exit_sensor != null:
			exit_sensor.monitoring = false
		var exit_platform := vr_course.get_node_or_null("VRSimulationExitPlatform") as MeshInstance3D if vr_course != null else null
		if exit_platform != null:
			exit_platform.set_meta("system_vr_exit_locked", true)
	if facility_type == "sports_court":
		active_facility_activity["opponent_score"] = 0
	if facility_type == "arcade":
		active_facility_activity["mode"] = selected_arcade_mode
		active_facility_activity["lives"] = 3
		active_facility_activity["combo"] = 0
		active_facility_activity["best_combo"] = 0
		active_facility_activity["hits"] = 0
		active_facility_activity["targets_hit"] = []
		if selected_arcade_mode == "memory":
			active_facility_activity["goal"] = 5
			active_facility_activity["memory_sequence"] = [2, 0, 3, 1, 2]
			active_facility_activity["memory_cursor"] = 0
			var memory_buttons := content.get_node_or_null("ArcadeMemoryButtons") as HBoxContainer
			if memory_buttons != null:
				memory_buttons.visible = true
			_start_arcade_memory_preview()
		elif selected_arcade_mode == "reflex":
			active_facility_activity["goal"] = 5
			active_facility_activity["reward"] = 60
			var reflex_status := content.get_node_or_null("ArcadeReflexStatus") as Label
			if reflex_status != null:
				reflex_status.visible = true
			_schedule_arcade_reflex_signal()
		elif selected_arcade_mode == "puzzle":
			active_facility_activity["goal"] = 5
			active_facility_activity["reward"] = 75
			active_facility_activity["lives"] = 3
			active_facility_activity["puzzle_questions"] = _arcade_puzzle_questions()
			active_facility_activity["puzzle_cursor"] = 0
			var puzzle_status := content.get_node_or_null("ArcadePuzzleStatus") as Label
			if puzzle_status != null:
				puzzle_status.visible = true
			_show_arcade_puzzle_question()
		else:
			var reflex_status := content.get_node_or_null("ArcadeReflexStatus") as Label
			if reflex_status != null:
				reflex_status.visible = false
			var memory_buttons := content.get_node_or_null("ArcadeMemoryButtons") as HBoxContainer
			if memory_buttons != null:
				memory_buttons.visible = false
	if facility_type == "cinema":
		_update_cinema_program_screen(0)
	var active_goal := int(active_facility_activity.get("goal", definition["goal"]))
	_set_status("%s بدأت. التقدم: 0/%d" % [str(definition["title"]), active_goal])
	return true


func perform_facility_activity(action: String) -> Dictionary:
	if active_facility_activity.is_empty() or not bool(active_facility_activity.get("started", false)):
		return {"success": false, "reason": "لا يوجد نشاط بدأ بعد."}
	if action != str(active_facility_activity.get("action", "")):
		return {"success": false, "reason": "هذا الإجراء لا يخص النشاط الحالي."}
	var facility_type := str(active_facility_activity.get("type", ""))
	if facility_type == "vr_lab":
		return {"success": false, "completed": false, "reason": "يجب اجتياز بوابات الطاقة الثلاث ثم لمس منصة الخروج؛ لا يمكن إكمال المحاكاة بزر."}
	if facility_type == "bowling":
		return await _launch_bowling_ball()
	if facility_type == "sports_court":
		return await _launch_basketball()
	if facility_type == "arcade":
		var arcade_mode := str(active_facility_activity.get("mode", "shooter"))
		if arcade_mode == "memory":
			return {"success": false, "reason": "أدخل تسلسل الألوان من الأزرار الأربعة."}
		if arcade_mode == "reflex":
			return _submit_arcade_reflex_action()
		if arcade_mode == "puzzle":
			return {"success": false, "reason": "اختر الإجابة الصحيحة من لوحة الأرقام لإكمال اللغز."}
		return await _launch_arcade_projectile()
	var step := int(active_facility_activity.get("step", 0)) + 1
	var score_gain := 1
	match facility_type:
		"bowling":
			score_gain = clampi(10 - absi(posmod(step * 3 + 2, 9) - 4), 0, 10)
		"sports_court":
			score_gain = 2 if posmod(step * 2 + 1, 3) != 0 else 0
		"arcade":
			score_gain = 2 if posmod(step + 1, 4) != 0 else 0
		"cinema":
			score_gain = 5
			_update_cinema_program_screen(step)
		"robotics_lab":
			score_gain = 2
			_advance_robotics_assembly(step)
		"ai_lab", "vr_lab":
			score_gain = 2 if posmod(step, 2) == 1 else 1
	active_facility_activity["step"] = step
	active_facility_activity["score"] = int(active_facility_activity.get("score", 0)) + score_gain
	var goal := int(active_facility_activity.get("goal", 1))
	if step >= goal:
		return _complete_facility_activity()
	_set_status("النشاط مستمر — الخطوة %d من %d | النتيجة: %d" % [step, goal, int(active_facility_activity.get("score", 0))])
	return {"success": true, "completed": false, "step": step, "score": int(active_facility_activity.get("score", 0))}


func _on_basketball_sensor_body_entered(body: Node3D) -> void:
	if str(body.name).begins_with("Basketball_"):
		body.set_meta("system_basketball_scored", true)


func _on_arcade_target_body_entered(body: Node3D, target_index: int) -> void:
	if str(body.name).begins_with("ArcadeProjectile_"):
		body.set_meta("system_arcade_hit", true)
		body.set_meta("system_arcade_target", target_index)


func _launch_arcade_projectile() -> Dictionary:
	if bowling_throw_in_progress or facility_projectile_in_progress:
		return {"success": false, "reason": "انتظر حتى تنتهي المحاولة الحالية."}
	if current_facility_root == null or not is_instance_valid(current_facility_root):
		return {"success": false, "reason": "مركز الألعاب غير جاهز."}
	var target_count := 0
	for child in current_facility_root.get_children():
		if child is Area3D and str(child.name).begins_with("ArcadeTargetSensor_"):
			target_count += 1
	if target_count != 5:
		return {"success": false, "reason": "أهداف مركز الألعاب غير مكتملة."}
	facility_projectile_in_progress = true
	var projectile := RigidBody3D.new()
	projectile.name = "ArcadeProjectile_Active"
	projectile.mass = 0.5
	projectile.continuous_cd = true
	projectile.set_meta("system_arcade_hit", false)
	projectile.set_meta("system_arcade_target", -1)
	var projectile_mesh := MeshInstance3D.new()
	var projectile_sphere := SphereMesh.new()
	projectile_sphere.radius = 0.2
	projectile_sphere.height = 0.4
	projectile_mesh.mesh = projectile_sphere
	var projectile_material := StandardMaterial3D.new()
	projectile_material.albedo_color = Color(0.1, 0.85, 1.0)
	projectile_material.emission_enabled = true
	projectile_material.emission = Color(0.05, 0.5, 0.9)
	projectile_mesh.material_override = projectile_material
	projectile.add_child(projectile_mesh)
	var projectile_collision := CollisionShape3D.new()
	var projectile_shape := SphereShape3D.new()
	projectile_shape.radius = 0.2
	projectile_collision.shape = projectile_shape
	projectile.add_child(projectile_collision)
	current_facility_root.add_child(projectile)
	projectile.position = Vector3(facility_aim * 4.0, 3.5, 4.0)
	projectile.apply_central_impulse(Vector3(0.0, 0.0, -8.0))
	_set_status("SYSTEM ARCADE — انطلقت الكرة الضوئية!")
	var hit := false
	var target_id := -1
	var nearest_target_distance := INF
	var nearest_projectile_position := Vector3.ZERO
	var nearest_target_position := Vector3.ZERO
	for _physics_step in range(30):
		await get_tree().create_timer(0.05).timeout
		if not is_instance_valid(projectile):
			break
		if bool(projectile.get_meta("system_arcade_hit", false)):
			hit = true
			target_id = int(projectile.get_meta("system_arcade_target", -1))
			break
		for sensor_index in range(5):
			var target_sensor := current_facility_root.get_node_or_null("ArcadeTargetSensor_%02d" % sensor_index) as Area3D
			if target_sensor != null:
				var target_distance := projectile.global_position.distance_to(target_sensor.global_position)
				if target_distance < nearest_target_distance:
					nearest_target_distance = target_distance
					nearest_projectile_position = projectile.global_position
					nearest_target_position = target_sensor.global_position
				if target_distance <= 1.6:
					hit = true
					target_id = sensor_index
					break
		if hit:
			break
	var projectile_end_position := projectile.global_position if is_instance_valid(projectile) else Vector3.ZERO
	if is_instance_valid(projectile):
		projectile.queue_free()
	var step := int(active_facility_activity.get("step", 0)) + 1
	var combo := int(active_facility_activity.get("combo", 0))
	var lives := int(active_facility_activity.get("lives", 3))
	var hits := int(active_facility_activity.get("hits", 0))
	var points := 0
	if hit:
		points = _calculate_arcade_target_points(target_id, combo)
		combo += 1
		hits += 1
	else:
		combo = 0
		lives = maxi(0, lives - 1)
	var best_combo := maxi(int(active_facility_activity.get("best_combo", 0)), combo)
	var targets_hit: Array = active_facility_activity.get("targets_hit", []).duplicate()
	if hit and not targets_hit.has(target_id):
		targets_hit.append(target_id)
	active_facility_activity["step"] = step
	active_facility_activity["score"] = int(active_facility_activity.get("score", 0)) + points
	active_facility_activity["combo"] = combo
	active_facility_activity["best_combo"] = best_combo
	active_facility_activity["lives"] = lives
	active_facility_activity["hits"] = hits
	active_facility_activity["targets_hit"] = targets_hit
	facility_projectile_in_progress = false
	var goal := int(active_facility_activity.get("goal", 10))
	var score := int(active_facility_activity.get("score", 0))
	var completed_game := step >= goal or lives <= 0
	if completed_game:
		var result := _complete_facility_activity()
		result["last_target_hit"] = hit
		result["last_target_id"] = target_id
		result["last_target_distance"] = nearest_target_distance
		result["last_projectile_position"] = projectile_end_position
		result["nearest_projectile_position"] = nearest_projectile_position
		result["nearest_target_position"] = nearest_target_position
		result["hits"] = hits
		result["lives_remaining"] = lives
		result["best_combo"] = best_combo
		result["targets_hit"] = targets_hit
		result["last_target_points"] = points
		return result
	_set_status(("أصبت الهدف %d! +%d" % [target_id + 1, points] if hit else "ضاعت الكرة — خسرت محاولة حياة.") + " | المحاولة %d/%d | حياة: %d | كومبو: %d | النقاط: %d" % [step, goal, lives, combo, score])
	return {"success": true, "completed": false, "step": step, "hit": hit, "target_id": target_id, "score": score, "lives_remaining": lives, "combo": combo, "best_combo": best_combo, "hits": hits, "last_target_points": points, "nearest_target_distance": nearest_target_distance, "projectile_end_position": projectile_end_position, "nearest_projectile_position": nearest_projectile_position, "nearest_target_position": nearest_target_position}


func _calculate_arcade_target_points(target_id: int, combo: int) -> int:
	var target_scores := [5, 8, 12, 8, 5]
	if target_id < 0 or target_id >= target_scores.size():
		return 0
	return int(target_scores[target_id]) + mini(maxi(combo, 0), 4) * 2


func _launch_basketball() -> Dictionary:
	if facility_projectile_in_progress:
		return {"success": false, "reason": "المحاولة السابقة لم تنتهِ بعد."}
	if current_facility_root == null or not is_instance_valid(current_facility_root):
		return {"success": false, "reason": "ملعب كرة السلة غير جاهز."}
	if current_facility_root.get_node_or_null("BasketballScoringSensor") == null:
		return {"success": false, "reason": "حلقة التسجيل غير موجودة."}
	facility_projectile_in_progress = true
	var player_ball := RigidBody3D.new()
	player_ball.name = "Basketball_Active_Player"
	player_ball.mass = 1.2
	player_ball.continuous_cd = true
	player_ball.set_meta("system_basketball_scored", false)
	var ball_mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.27
	sphere_mesh.height = 0.54
	ball_mesh.mesh = sphere_mesh
	var ball_material := StandardMaterial3D.new()
	ball_material.albedo_color = Color(0.9, 0.34, 0.08)
	ball_material.roughness = 0.62
	ball_mesh.material_override = ball_material
	player_ball.add_child(ball_mesh)
	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.27
	collision.shape = sphere_shape
	player_ball.add_child(collision)
	current_facility_root.add_child(player_ball)
	player_ball.position = Vector3(0.0, 1.4, 1.5)
	var player_aim := facility_aim
	player_ball.apply_central_impulse(Vector3(player_aim * 1.2, 7.2, -10.0))
	_set_status("مباراة كرة السلة — تصويبتك انطلقت!")
	await get_tree().create_timer(1.45).timeout
	var player_scored := is_instance_valid(player_ball) and bool(player_ball.get_meta("system_basketball_scored", false))
	if is_instance_valid(player_ball):
		player_ball.queue_free()
	var step := int(active_facility_activity.get("step", 0)) + 1
	var player_score := int(active_facility_activity.get("score", 0)) + (2 if player_scored else 0)
	active_facility_activity["score"] = player_score
	var opponent_scored := await _launch_basketball_opponent_shot(step)
	var opponent_score := int(active_facility_activity.get("opponent_score", 0)) + (2 if opponent_scored else 0)
	active_facility_activity["opponent_score"] = opponent_score
	active_facility_activity["step"] = step
	facility_projectile_in_progress = false
	var goal := int(active_facility_activity.get("goal", 10))
	if step >= goal:
		var match_result := "win" if player_score > opponent_score else ("draw" if player_score == opponent_score else "loss")
		if match_result == "win":
			active_facility_activity["reward"] = int(active_facility_activity.get("reward", 0)) + 25
		elif match_result == "draw":
			active_facility_activity["reward"] = int(active_facility_activity.get("reward", 0)) + 10
		var result := _complete_facility_activity()
		result["last_shot_scored"] = player_scored
		result["last_opponent_shot_scored"] = opponent_scored
		result["player_score"] = player_score
		result["opponent_score"] = opponent_score
		result["match_result"] = match_result
		return result
	_set_status("مباراة 1 ضد 1 — الجولة %d/%d | أنت %d : %d الخصم | %s" % [step, goal, player_score, opponent_score, "سجلت" if player_scored else "أضعت التصويبة"])
	return {"success": true, "completed": false, "step": step, "scored": player_scored, "opponent_scored": opponent_scored, "player_score": player_score, "opponent_score": opponent_score}


func _launch_basketball_opponent_shot(step: int) -> bool:
	if current_facility_root == null or not is_instance_valid(current_facility_root):
		return false
	var ball := RigidBody3D.new()
	ball.name = "Basketball_Opponent_Active"
	ball.mass = 1.2
	ball.continuous_cd = true
	ball.set_meta("system_basketball_scored", false)
	var ball_mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.27
	sphere_mesh.height = 0.54
	ball_mesh.mesh = sphere_mesh
	var ball_material := StandardMaterial3D.new()
	ball_material.albedo_color = Color(0.2, 0.48, 0.92)
	ball_material.roughness = 0.62
	ball_mesh.material_override = ball_material
	ball.add_child(ball_mesh)
	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.27
	collision.shape = sphere_shape
	ball.add_child(collision)
	current_facility_root.add_child(ball)
	ball.position = Vector3(3.8, 1.4, 5.6)
	var opponent_aim := sin(float(step) * 1.35) * 0.32
	ball.apply_central_impulse(Vector3(opponent_aim * 1.2, 7.2, -10.0))
	_set_status("دور الخصم — اللاعب الآلي يسدد الآن...")
	await get_tree().create_timer(1.45).timeout
	var scored := is_instance_valid(ball) and bool(ball.get_meta("system_basketball_scored", false))
	if is_instance_valid(ball):
		ball.queue_free()
	return scored


func _launch_bowling_ball() -> Dictionary:
	if bowling_throw_in_progress:
		return {"success": false, "reason": "الكرة السابقة ما زالت تتحرك."}
	if current_facility_root == null or not is_instance_valid(current_facility_root):
		return {"success": false, "reason": "مسار البولينغ غير جاهز."}
	var pins: Array[RigidBody3D] = []
	for child in current_facility_root.get_children():
		if child is RigidBody3D and str(child.name).begins_with("BowlingPin_"):
			pins.append(child as RigidBody3D)
	if pins.size() != 10:
		return {"success": false, "reason": "لم تكتمل دبابيس البولينغ العشرة."}
	bowling_throw_in_progress = true
	for pin in pins:
		if not pin.has_meta("system_bowling_start_position"):
			pin.set_meta("system_bowling_start_position", pin.position)
		if not pin.has_meta("system_bowling_down"):
			pin.set_meta("system_bowling_down", false)
	var ball := RigidBody3D.new()
	ball.name = "BowlingBall_Active"
	ball.mass = 5.0
	ball.continuous_cd = true
	var ball_mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.38
	sphere_mesh.height = 0.76
	ball_mesh.mesh = sphere_mesh
	var ball_material := StandardMaterial3D.new()
	ball_material.albedo_color = Color(0.08, 0.72, 0.86)
	ball_material.metallic = 0.32
	ball_material.roughness = 0.24
	ball_mesh.material_override = ball_material
	ball.add_child(ball_mesh)
	var ball_collision := CollisionShape3D.new()
	var ball_shape := SphereShape3D.new()
	ball_shape.radius = 0.38
	ball_collision.shape = ball_shape
	ball.add_child(ball_collision)
	current_facility_root.add_child(ball)
	ball.position = Vector3(0.0, 1.08, 4.2)
	var aim := facility_aim
	ball.apply_central_impulse(Vector3(aim * 2.4, 1.1, -45.0))
	_set_status("الكرة انطلقت! راقب الدبابيس...")
	await get_tree().create_timer(2.5).timeout
	if not is_instance_valid(ball):
		bowling_throw_in_progress = false
		return {"success": false, "reason": "انتهت محاولة الرمي قبل تسجيل النتيجة."}
	var knocked_down := 0
	for pin in pins:
		if not is_instance_valid(pin):
			continue
		var tilt := pin.rotation.x + pin.rotation.z
		var start_position: Vector3 = pin.get_meta("system_bowling_start_position", pin.position)
		var displacement := pin.position.distance_to(start_position)
		var is_down := absf(tilt) > 0.65 or displacement > 0.55 or pin.position.y < 0.8
		if is_down and not bool(pin.get_meta("system_bowling_down", false)):
			pin.set_meta("system_bowling_down", true)
			knocked_down += 1
	ball.queue_free()
	var frame := int(active_facility_activity.get("frame", 1))
	var frame_rolls: Array = active_facility_activity.get("frame_rolls", []).duplicate()
	frame_rolls.append(knocked_down)
	var rolls: Array = active_facility_activity.get("rolls", []).duplicate()
	rolls.append(knocked_down)
	var frame_complete := false
	var reset_for_bonus := false
	if frame < 10:
		frame_complete = int(frame_rolls[0]) == 10 or frame_rolls.size() >= 2
	else:
		if frame_rolls.size() == 1:
			reset_for_bonus = int(frame_rolls[0]) == 10
		elif frame_rolls.size() == 2:
			var first_roll := int(frame_rolls[0])
			var second_roll := int(frame_rolls[1])
			if first_roll == 10:
				reset_for_bonus = second_roll == 10
			else:
				if first_roll + second_roll >= 10:
					reset_for_bonus = true
				else:
					frame_complete = true
		elif frame_rolls.size() >= 3:
			frame_complete = true
	active_facility_activity["rolls"] = rolls
	active_facility_activity["step"] = int(active_facility_activity.get("step", 0)) + 1
	var score := _calculate_bowling_score(rolls)
	active_facility_activity["score"] = score
	var total_down := 0
	for pin in pins:
		if not is_instance_valid(pin):
			continue
		if bool(pin.get_meta("system_bowling_down", false)):
			total_down += 1
			pin.freeze = true
	if frame_complete:
		if frame >= 10:
			bowling_throw_in_progress = false
			var completed := _complete_facility_activity()
			completed["last_throw"] = knocked_down
			completed["frame"] = 10
			completed["score"] = score
			return completed
		frame += 1
		frame_rolls.clear()
		_reset_bowling_pin_rack(pins)
	elif reset_for_bonus:
		_reset_bowling_pin_rack(pins)
	active_facility_activity["frame"] = frame
	active_facility_activity["frame_rolls"] = frame_rolls
	bowling_throw_in_progress = false
	var throw_number := frame_rolls.size() + 1
	_set_status("البولينغ — الإطار %d/10 | الرمية %d | سقط %d | المجموع: %d نقطة" % [frame, throw_number, knocked_down, score])
	return {"success": true, "completed": false, "step": int(active_facility_activity.get("step", 0)), "pins": knocked_down, "frame_pins_down": total_down, "frame": frame, "throw": throw_number, "score": score}


func _reset_bowling_pin_rack(pins: Array) -> void:
	for pin_index in range(pins.size()):
		var pin := pins[pin_index] as RigidBody3D
		if not is_instance_valid(pin):
			continue
		pin.freeze = true
		pin.linear_velocity = Vector3.ZERO
		pin.angular_velocity = Vector3.ZERO
		pin.rotation = Vector3.ZERO
		pin.position = _bowling_pin_start_position(pin_index)
		pin.set_meta("system_bowling_start_position", pin.position)
		pin.set_meta("system_bowling_down", false)
		pin.freeze = false


func _calculate_bowling_score(rolls: Array) -> int:
	var total := 0
	var roll_index := 0
	for frame_index in range(10):
		if roll_index >= rolls.size():
			break
		var first_roll := int(rolls[roll_index])
		if first_roll == 10:
			if roll_index + 2 >= rolls.size():
				break
			total += 10 + int(rolls[roll_index + 1]) + int(rolls[roll_index + 2])
			roll_index += 1
		else:
			if roll_index + 1 >= rolls.size():
				break
			var second_roll := int(rolls[roll_index + 1])
			if first_roll + second_roll == 10:
				if roll_index + 2 >= rolls.size():
					break
				total += 10 + int(rolls[roll_index + 2])
			else:
				total += first_roll + second_roll
			roll_index += 2
	return total


func _bowling_pin_start_position(pin_index: int) -> Vector3:
	var positions := [
		Vector3(0.0, 1.35, -5.4),
		Vector3(-0.48, 1.35, -6.2), Vector3(0.48, 1.35, -6.2),
		Vector3(-0.96, 1.35, -7.0), Vector3(0.0, 1.35, -7.0), Vector3(0.96, 1.35, -7.0),
		Vector3(-1.44, 1.35, -7.8), Vector3(-0.48, 1.35, -7.8), Vector3(0.48, 1.35, -7.8), Vector3(1.44, 1.35, -7.8)
	]
	return positions[clampi(pin_index, 0, positions.size() - 1)]


func _advance_robotics_assembly(step: int) -> void:
	if not is_instance_valid(current_facility_root):
		return
	var assembly := current_facility_root.get_node_or_null("RobotAssemblyDisplay") as Node3D
	if assembly == null:
		return
	var part_index := clampi(step - 1, 0, 4)
	var part := assembly.get_node_or_null("RobotAssemblyPart_%02d" % part_index) as MeshInstance3D
	if part == null:
		return
	var target_position: Vector3 = part.get_meta("system_robot_target_position", part.position)
	part.visible = true
	part.position = target_position + Vector3(0.0, 1.6, 0.0)
	part.scale = Vector3(0.12, 0.12, 0.12)
	part.rotation = Vector3(0.0, PI, 0.0)
	part.set_meta("system_robot_assembled", true)
	var assembly_tween := create_tween().set_parallel(true)
	assembly_tween.tween_property(part, "position", target_position, 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	assembly_tween.tween_property(part, "scale", Vector3.ONE, 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	assembly_tween.tween_property(part, "rotation", Vector3.ZERO, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_set_status("تجميع الروبوت: تم تثبيت القطعة %d من 5" % (part_index + 1))
	if step >= 5:
		assembly.set_meta("system_robot_idle_animation", true)
		assembly_tween.finished.connect(_animate_robot_idle_animation.bind(assembly))


func _start_robot_idle_animation(assembly: Node3D) -> void:
	if not is_instance_valid(assembly) or bool(assembly.get_meta("system_robot_idle_animation", false)):
		return
	assembly.set_meta("system_robot_idle_animation", true)
	_animate_robot_idle_animation(assembly)


func _animate_robot_idle_animation(assembly: Node3D) -> void:
	if not is_instance_valid(assembly):
		return
	var left_arm := assembly.get_node_or_null("RobotAssemblyPart_03") as MeshInstance3D
	var right_arm := assembly.get_node_or_null("RobotAssemblyPart_04") as MeshInstance3D
	var head := assembly.get_node_or_null("RobotAssemblyPart_02") as MeshInstance3D
	if left_arm != null:
		var left_tween := assembly.create_tween().set_loops()
		left_tween.tween_property(left_arm, "rotation", Vector3(0.0, 0.0, -0.24), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		left_tween.tween_property(left_arm, "rotation", Vector3.ZERO, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if right_arm != null:
		var right_tween := assembly.create_tween().set_loops()
		right_tween.tween_property(right_arm, "rotation", Vector3(0.0, 0.0, 0.24), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		right_tween.tween_property(right_arm, "rotation", Vector3.ZERO, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if head != null:
		var head_tween := assembly.create_tween().set_loops()
		head_tween.tween_property(head, "rotation", Vector3(0.0, 0.18, 0.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		head_tween.tween_property(head, "rotation", Vector3.ZERO, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _update_cinema_program_screen(scene_number: int) -> void:
	if not is_instance_valid(current_facility_root):
		return
	var title_label := current_facility_root.get_node_or_null("CinemaProgramTitle") as Label3D
	var screen := current_facility_root.get_node_or_null("CinemaProgramScreen") as MeshInstance3D
	if title_label == null or screen == null:
		return
	var scene_titles := [
		"نداء بغداد",
		"أسرار برج النور",
		"رحلة الصياد الأول"
	]
	var scene_descriptions := [
		"تبدأ الحكاية عند بوابة دجلة",
		"إشارة غامضة تكشف سر البرج",
		"قرار شجاع يفتح طريقاً جديداً"
	]
	var scene_colors := [
		Color(0.02, 0.28, 0.52),
		Color(0.30, 0.12, 0.48),
		Color(0.48, 0.22, 0.06)
	]
	var index := clampi(scene_number - 1, 0, scene_titles.size() - 1)
	title_label.text = "SYSTEM ORIGINALS\nالمشهد %d | %s\n%s" % [scene_number if scene_number > 0 else 1, scene_titles[index], scene_descriptions[index]]
	var material := screen.material_override as StandardMaterial3D
	if material != null:
		material.emission = scene_colors[index]


func _build_vr_simulation_course(root: Node3D, highlight: Material, accent: Material) -> void:
	var course := Node3D.new()
	course.name = "VRSimulationCourse"
	course.position = Vector3(0.0, 0.0, -1.0)
	root.add_child(course)
	_add_facility_box(course, "VRSimulationFloor", Vector3(0.0, 0.12, 0.0), Vector3(12.0, 0.24, 23.0), accent)
	var floor_body := StaticBody3D.new()
	floor_body.name = "VRSimulationFloorPhysics"
	floor_body.position = Vector3(0.0, 0.12, 0.0)
	var floor_collision := CollisionShape3D.new()
	floor_collision.name = "CollisionShape3D"
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(12.0, 0.24, 23.0)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	course.add_child(floor_body)
	_add_facility_box(course, "VRSimulationStartMarker", Vector3(0.0, 0.28, -9.0), Vector3(4.0, 0.12, 1.0), highlight)
	var exit_platform := MeshInstance3D.new()
	exit_platform.name = "VRSimulationExitPlatform"
	var exit_platform_mesh := BoxMesh.new()
	exit_platform_mesh.size = Vector3(4.4, 0.3, 2.6)
	exit_platform.mesh = exit_platform_mesh
	exit_platform.position = Vector3(0.0, 0.28, 10.0)
	var exit_material := StandardMaterial3D.new()
	exit_material.albedo_color = Color(0.08, 0.28, 0.38)
	exit_material.emission_enabled = true
	exit_material.emission = Color(0.02, 0.18, 0.28)
	exit_material.emission_energy_multiplier = 0.6
	exit_material.metallic = 0.5
	exit_platform.material_override = exit_material
	exit_platform.set_meta("system_vr_exit_locked", true)
	course.add_child(exit_platform)
	var exit_sensor := Area3D.new()
	exit_sensor.name = "VRSimulationExitSensor"
	exit_sensor.collision_layer = 0
	exit_sensor.collision_mask = 1
	exit_sensor.monitoring = false
	exit_sensor.monitorable = true
	exit_sensor.position = Vector3(0.0, 1.5, 10.0)
	var exit_collision := CollisionShape3D.new()
	exit_collision.name = "CollisionShape3D"
	var exit_shape := BoxShape3D.new()
	exit_shape.size = Vector3(4.2, 3.0, 2.4)
	exit_collision.shape = exit_shape
	exit_sensor.add_child(exit_collision)
	exit_sensor.body_entered.connect(_on_vr_exit_body_entered)
	course.add_child(exit_sensor)
	for checkpoint_index in range(3):
		var gate := Node3D.new()
		gate.name = "VRCheckpointGate_%02d" % checkpoint_index
		gate.position = Vector3(0.0, 0.0, -6.0 + float(checkpoint_index) * 6.0)
		course.add_child(gate)
		var gate_material := highlight.duplicate() as StandardMaterial3D
		gate_material.emission_enabled = true
		gate_material.emission = Color(0.04, 0.62, 0.92)
		gate_material.emission_energy_multiplier = 1.5
		_add_facility_box(gate, "GateLeft", Vector3(-2.0, 1.8, 0.0), Vector3(0.22, 3.6, 0.35), gate_material)
		_add_facility_box(gate, "GateRight", Vector3(2.0, 1.8, 0.0), Vector3(0.22, 3.6, 0.35), gate_material)
		_add_facility_box(gate, "GateTop", Vector3(0.0, 3.55, 0.0), Vector3(4.2, 0.22, 0.35), gate_material)
		var sensor := Area3D.new()
		sensor.name = "VRCheckpointSensor_%02d" % checkpoint_index
		sensor.collision_layer = 0
		sensor.collision_mask = 1
		sensor.monitoring = true
		sensor.position = Vector3(0.0, 1.5, 0.0)
		var sensor_collision := CollisionShape3D.new()
		sensor_collision.name = "CollisionShape3D"
		var sensor_shape := BoxShape3D.new()
		sensor_shape.size = Vector3(3.8, 3.0, 1.2)
		sensor_collision.shape = sensor_shape
		sensor.add_child(sensor_collision)
		sensor.body_entered.connect(_on_vr_checkpoint_body_entered.bind(checkpoint_index))
		gate.add_child(sensor)
	for obstacle_index in range(4):
		var side := -1.0 if obstacle_index % 2 == 0 else 1.0
		var obstacle_position := Vector3(side * 4.5, 1.3, -3.0 + float(obstacle_index) * 2.0)
		_add_facility_box(course, "VRHologramObstacle_%02d" % obstacle_index, obstacle_position, Vector3(0.7, 2.6, 0.7), highlight)
		var obstacle_body := StaticBody3D.new()
		obstacle_body.name = "VRHologramObstaclePhysics_%02d" % obstacle_index
		obstacle_body.position = obstacle_position
		var obstacle_collision := CollisionShape3D.new()
		obstacle_collision.name = "CollisionShape3D"
		var obstacle_shape := BoxShape3D.new()
		obstacle_shape.size = Vector3(0.7, 2.6, 0.7)
		obstacle_collision.shape = obstacle_shape
		obstacle_body.add_child(obstacle_collision)
		course.add_child(obstacle_body)
	var exit_beacon := OmniLight3D.new()
	exit_beacon.name = "VRSimulationExitBeacon"
	exit_beacon.position = Vector3(0.0, 3.0, 10.0)
	exit_beacon.light_color = Color(0.12, 0.45, 0.58)
	exit_beacon.light_energy = 0.45
	exit_beacon.omni_range = 12.0
	course.add_child(exit_beacon)


func _on_vr_checkpoint_body_entered(body: Node3D, checkpoint_index: int) -> void:
	if body != player or active_facility_activity.is_empty():
		return
	if str(active_facility_activity.get("type", "")) != "vr_lab" or not bool(active_facility_activity.get("started", false)):
		return
	var expected_checkpoint := int(active_facility_activity.get("step", 0))
	if checkpoint_index != expected_checkpoint:
		_set_status("مسار المحاكاة: اعبر البوابة %d أولاً." % (expected_checkpoint + 1))
		return
	var next_step := expected_checkpoint + 1
	active_facility_activity["step"] = next_step
	active_facility_activity["score"] = int(active_facility_activity.get("score", 0)) + 20
	if next_step >= int(active_facility_activity.get("goal", 3)):
		active_facility_activity["exit_unlocked"] = true
		var course := current_facility_root.get_node_or_null("VRSimulationCourse") as Node3D if is_instance_valid(current_facility_root) else null
		var exit_sensor := course.get_node_or_null("VRSimulationExitSensor") as Area3D if course != null else null
		if exit_sensor != null:
			exit_sensor.monitoring = true
		var exit_platform := course.get_node_or_null("VRSimulationExitPlatform") as MeshInstance3D if course != null else null
		if exit_platform != null:
			exit_platform.set_meta("system_vr_exit_locked", false)
			var platform_material := exit_platform.material_override as StandardMaterial3D
			if platform_material != null:
				platform_material.albedo_color = Color(0.08, 0.48, 0.25)
				platform_material.emission = Color(0.02, 0.72, 0.22)
				platform_material.emission_energy_multiplier = 1.8
		var beacon := course.get_node_or_null("VRSimulationExitBeacon") as OmniLight3D if course != null else null
		if beacon != null:
			beacon.light_color = Color(0.12, 1.0, 0.38)
			beacon.light_energy = 2.4
		_set_status("اكتملت البوابات الثلاث. منصة الخروج فُتحت — تحرّك إليها لإنهاء المحاكاة.")
		return
	_set_status("تم اجتياز بوابة المحاكاة %d من 3." % next_step)


func _on_vr_exit_body_entered(body: Node3D) -> void:
	if body != player or active_facility_activity.is_empty():
		return
	if str(active_facility_activity.get("type", "")) != "vr_lab" or not bool(active_facility_activity.get("started", false)):
		return
	if not bool(active_facility_activity.get("exit_unlocked", false)) or int(active_facility_activity.get("step", 0)) < int(active_facility_activity.get("goal", 3)):
		_set_status("منصة الخروج مغلقة. أكمل بوابات الطاقة الثلاث أولاً.")
		return
	active_facility_activity["exit_reached"] = true
	_complete_facility_activity()


func _complete_facility_activity() -> Dictionary:
	var facility_type := str(active_facility_activity.get("type", ""))
	var score := int(active_facility_activity.get("score", 0))
	var reward := int(active_facility_activity.get("reward", 0)) + score
	var stats: Dictionary = facility_activity_stats.get(facility_type, {})
	stats["plays"] = int(stats.get("plays", 0)) + 1
	stats["best_score"] = maxi(int(stats.get("best_score", 0)), score)
	stats["total_score"] = int(stats.get("total_score", 0)) + score
	stats["total_rewards"] = int(stats.get("total_rewards", 0)) + reward
	facility_activity_stats[facility_type] = stats
	credits += reward
	_save_wallet()
	_save_facility_activity_stats()
	active_facility_activity.clear()
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	_set_status("اكتمل النشاط بنجاح! النتيجة: %d — مكافأتك: %d رصيد SYSTEM." % [score, reward])
	return {"success": true, "completed": true, "score": score, "reward": reward}


func _load_facility_activity_stats() -> void:
	var config := ConfigFile.new()
	if config.load(FACILITY_ACTIVITY_SAVE_PATH) != OK:
		facility_activity_stats = {}
		return
	var stored: Variant = config.get_value("activities", "stats", {})
	facility_activity_stats = stored if stored is Dictionary else {}


func _save_facility_activity_stats() -> void:
	var config := ConfigFile.new()
	config.set_value("activities", "stats", facility_activity_stats)
	var error := config.save(FACILITY_ACTIVITY_SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM facility activity stats could not be saved: " + str(error))


func _on_pool_water_body_entered(body: Node3D, surface_y: float) -> void:
	if body != player:
		return
	body.set_meta("system_swimming", true)
	body.set_meta("system_swim_surface_y", surface_y)
	body.set_meta("system_swim_source", "Baghdad SYSTEM pool")


func _on_pool_water_body_exited(body: Node3D) -> void:
	if body != player:
		return
	body.set_meta("system_swimming", false)
	body.remove_meta("system_swim_surface_y")
	body.remove_meta("system_swim_source")
	if is_instance_valid(status_label):
		status_label.text = "خرجت من المسبح — عادت حركة اللاعب الطبيعية."



func _add_pool_room_sign(parent: Node3D, node_name: String, label_text: String, position: Vector3, color: Color) -> void:
	var sign := Label3D.new()
	sign.name = node_name
	sign.text = label_text
	sign.position = position
	sign.font_size = 17
	sign.pixel_size = 0.012
	sign.modulate = color
	parent.add_child(sign)


func _add_pool_changing_suite(parent: Node3D, suite_name: String, center: Vector3, accent: Material, highlight: Material, label_text: String) -> void:
	var suite := Node3D.new()
	suite.name = suite_name
	suite.position = center
	parent.add_child(suite)
	_add_facility_box(suite, "ChangingSuiteFloor", Vector3(0.0, 0.12, 0.0), Vector3(8.0, 0.24, 11.0), accent)
	_add_facility_box(suite, "ChangingSuiteBackWall", Vector3(0.0, 1.7, -5.3), Vector3(8.0, 3.4, 0.25), accent)
	_add_facility_box(suite, "ChangingSuiteLeftWall", Vector3(-3.9, 1.7, 0.0), Vector3(0.25, 3.4, 10.5), accent)
	_add_facility_box(suite, "ChangingSuiteRightWall", Vector3(3.9, 1.7, 0.0), Vector3(0.25, 3.4, 10.5), accent)
	_add_pool_room_sign(suite, "ChangingSuiteSign", label_text, Vector3(0.0, 4.0, -4.8), Color(0.95, 0.86, 0.62))
	for locker_index in range(6):
		var locker_x := -2.7 + float(locker_index) * 1.08
		_add_facility_box(suite, "Locker_%02d" % locker_index, Vector3(locker_x, 1.15, -3.9), Vector3(0.86, 2.3, 0.72), highlight)
		_add_facility_box(suite, "LockerHandle_%02d" % locker_index, Vector3(locker_x + 0.25, 1.15, -3.48), Vector3(0.08, 0.24, 0.06), accent)
	_add_facility_box(suite, "ChangingBench", Vector3(0.0, 0.58, -1.8), Vector3(5.6, 0.3, 0.9), highlight)
	_create_pool_service_interaction(suite, "PoolLockerServiceInteraction", "locker", "خزائن المسبح — استلام خزانة شخصية", Vector3(0.0, 1.0, -1.9), 2.2)
	_create_pool_service_interaction(suite, "PoolShowerServiceInteraction", "shower", "منطقة الاستحمام — استخدام الدش قبل وبعد السباحة", Vector3(0.0, 1.0, 3.4), 2.0)
	for shower_index in range(3):
		var shower_x := -2.4 + float(shower_index) * 2.4
		_add_facility_box(suite, "ShowerPartition_%02d" % shower_index, Vector3(shower_x + 1.0, 1.35, 2.6), Vector3(0.12, 2.7, 3.0), highlight)
		_add_facility_box(suite, "ShowerColumn_%02d" % shower_index, Vector3(shower_x, 1.2, 3.4), Vector3(0.18, 2.4, 0.18), accent)
		_add_facility_box(suite, "ShowerHead_%02d" % shower_index, Vector3(shower_x, 2.35, 3.4), Vector3(0.72, 0.12, 0.42), highlight)
		_add_facility_box(suite, "ShowerDrain_%02d" % shower_index, Vector3(shower_x, 0.26, 3.4), Vector3(0.8, 0.04, 0.8), accent)


func _add_pool_lifeguard_station(parent: Node3D, accent: Material, highlight: Material) -> void:
	var station := Node3D.new()
	station.name = "PoolLifeguardStation"
	station.position = Vector3(0.0, 0.0, -17.0)
	parent.add_child(station)
	_add_facility_box(station, "LifeguardPlatform", Vector3(0.0, 1.0, 0.0), Vector3(3.2, 0.45, 2.8), accent)
	_add_facility_box(station, "LifeguardSeat", Vector3(0.0, 2.1, -0.2), Vector3(1.2, 1.8, 1.0), highlight)
	_add_facility_box(station, "LifeguardUmbrellaPole", Vector3(0.0, 3.4, 1.3), Vector3(0.14, 3.0, 0.14), accent)
	_add_facility_box(station, "LifeguardUmbrella", Vector3(0.0, 5.0, 1.3), Vector3(3.2, 0.22, 3.2), highlight)
	_add_facility_box(station, "RescueRing", Vector3(1.9, 1.6, 0.0), Vector3(0.8, 0.8, 0.2), highlight)
	_add_pool_room_sign(station, "LifeguardSign", "منقذ السباحة — إسعاف أولي", Vector3(0.0, 5.8, -1.4), Color(1.0, 0.86, 0.62))
	_create_pool_service_interaction(station, "PoolLifeguardServiceInteraction", "lifeguard", "محطة المنقذ — طلب مساعدة أو إسعاف أولي", Vector3(0.0, 1.0, 0.0), 2.6)


func _create_pool_service_interaction(parent: Node3D, node_name: String, service_type: String, prompt: String, local_position: Vector3, radius: float) -> void:
	var interaction := Area3D.new()
	interaction.name = node_name
	interaction.add_to_group("system_interactable")
	interaction.set_meta("system_pool_service_type", service_type)
	interaction.set_meta("system_interaction_prompt", prompt)
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	var facility_root: Node = parent
	while facility_root != null and not facility_root.has_meta("system_facility_type"):
		facility_root = facility_root.get_parent()
	if facility_root != null:
		interaction.set_meta("system_tower_id", str(facility_root.get_meta("system_tower_id", "")))
		interaction.set_meta("system_tower_floor_number", int(facility_root.get_meta("system_tower_floor_number", 0)))
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	collision.shape = shape
	collision.position = local_position
	interaction.add_child(collision)
	parent.add_child(interaction)


func _add_facility_box(parent: Node3D, object_name: String, object_position: Vector3, object_size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = object_name
	var mesh := BoxMesh.new()
	mesh.size = object_size
	visual.mesh = mesh
	visual.position = object_position
	visual.material_override = material
	parent.add_child(visual)


func _add_hotel_room_box(parent: Node3D, object_name: String, object_size: Vector3, object_position: Vector3, material: Material) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = object_name
	var mesh := BoxMesh.new()
	mesh.size = object_size
	visual.mesh = mesh
	visual.position = object_position
	visual.material_override = material
	parent.add_child(visual)
	return visual


func _create_hotel_room_interior(parent: Node3D, room_data: Dictionary, room_index: int, radius: float, materials: Dictionary) -> void:
	var room_id := str(room_data.get("id", "hotel_room_%02d" % room_index))
	var room_name := str(room_data.get("name", "غرفة فندقية"))
	var angle := TAU * float(room_index) / float(HOTEL_ROOM_CATALOG.size())
	var room_root := Node3D.new()
	room_root.name = "HotelRoomInterior_" + room_id
	room_root.position = Vector3(cos(angle) * radius * 0.34, 0.0, sin(angle) * radius * 0.34)
	room_root.rotation.y = PI * 0.5 - angle
	room_root.set_meta("system_hotel_room_id", room_id)
	room_root.set_meta("system_hotel_room_type", "vip" if room_id == "hotel_elite_vip" else ("hunter_suite" if room_id == "hotel_hunter_suite" else ("deluxe" if room_id.begins_with("hotel_deluxe") else "standard")))
	parent.add_child(room_root)
	var wall: Material = materials["wall"]
	var floor: Material = materials["floor"]
	var wood: Material = materials["wood"]
	var linen: Material = materials["linen"]
	var accent: Material = materials["accent"]
	var glass: Material = materials["glass"]
	var gold: Material = materials["gold"]
	var dark: Material = materials["dark"]
	_add_hotel_room_box(room_root, "HotelRoomFloor", Vector3(5.4, 0.08, 5.8), Vector3(0.0, 0.04, 0.0), floor)
	_add_hotel_room_box(room_root, "HotelRoomBackWall", Vector3(5.4, 3.2, 0.16), Vector3(0.0, 1.6, -2.9), wall)
	_add_hotel_room_collision_box(room_root, "HotelRoomBackWallCollision", Vector3(5.4, 3.2, 0.16), Vector3(0.0, 1.6, -2.9))
	_add_hotel_room_box(room_root, "HotelRoomLeftWall", Vector3(0.16, 3.2, 5.8), Vector3(-2.7, 1.6, 0.0), wall)
	_add_hotel_room_collision_box(room_root, "HotelRoomLeftWallCollision", Vector3(0.16, 3.2, 5.8), Vector3(-2.7, 1.6, 0.0))
	_add_hotel_room_box(room_root, "HotelRoomRightWall", Vector3(0.16, 3.2, 5.8), Vector3(2.7, 1.6, 0.0), wall)
	_add_hotel_room_collision_box(room_root, "HotelRoomRightWallCollision", Vector3(0.16, 3.2, 5.8), Vector3(2.7, 1.6, 0.0))
	_add_hotel_room_box(room_root, "HotelRoomFrontLeftWall", Vector3(1.65, 3.2, 0.16), Vector3(-1.88, 1.6, 2.9), wall)
	_add_hotel_room_collision_box(room_root, "HotelRoomFrontLeftWallCollision", Vector3(1.65, 3.2, 0.16), Vector3(-1.88, 1.6, 2.9))
	_add_hotel_room_box(room_root, "HotelRoomFrontRightWall", Vector3(1.65, 3.2, 0.16), Vector3(1.88, 1.6, 2.9), wall)
	_add_hotel_room_collision_box(room_root, "HotelRoomFrontRightWallCollision", Vector3(1.65, 3.2, 0.16), Vector3(1.88, 1.6, 2.9))
	_add_hotel_room_box(room_root, "HotelRoomDoorHeader", Vector3(2.1, 0.38, 0.18), Vector3(0.0, 3.02, 2.9), gold)
	_add_hotel_room_collision_box(room_root, "HotelRoomDoorHeaderCollision", Vector3(2.1, 0.38, 0.18), Vector3(0.0, 3.02, 2.9))
	var window := _add_hotel_room_box(room_root, "HotelRoomWindow", Vector3(2.25, 1.25, 0.08), Vector3(0.0, 2.0, -2.78), glass)
	window.set_meta("system_hotel_room_window", true)
	_add_hotel_room_box(room_root, "HotelRoomBed", Vector3(2.15, 0.48, 2.45), Vector3(-1.15, 0.42, -0.75), wood)
	_add_hotel_room_box(room_root, "HotelRoomMattress", Vector3(2.08, 0.22, 2.38), Vector3(-1.15, 0.77, -0.75), linen)
	_add_hotel_room_box(room_root, "HotelRoomPillow", Vector3(1.6, 0.15, 0.48), Vector3(-1.15, 0.94, -1.68), linen)
	_add_hotel_room_box(room_root, "HotelRoomHeadboard", Vector3(2.2, 1.0, 0.16), Vector3(-1.15, 0.92, -2.03), accent)
	_add_hotel_room_box(room_root, "HotelRoomWardrobe", Vector3(0.9, 2.15, 0.95), Vector3(2.1, 1.08, 0.15), wood)
	_add_hotel_room_box(room_root, "HotelRoomDesk", Vector3(1.65, 0.16, 0.78), Vector3(0.9, 0.78, 1.0), wood)
	_add_hotel_room_box(room_root, "HotelRoomDeskLegs", Vector3(1.45, 0.72, 0.12), Vector3(0.9, 0.36, 1.0), dark)
	_add_hotel_room_box(room_root, "HotelRoomDeskChair", Vector3(0.68, 0.92, 0.68), Vector3(0.9, 0.52, 1.85), accent)
	_add_hotel_room_box(room_root, "HotelRoomTelevision", Vector3(1.55, 0.92, 0.1), Vector3(0.9, 1.82, -2.78), dark)
	_add_hotel_room_box(room_root, "HotelRoomBathroomPartition", Vector3(0.12, 2.45, 2.2), Vector3(0.55, 1.22, -1.72), wall)
	_add_hotel_room_collision_box(room_root, "HotelRoomBathroomPartitionCollision", Vector3(0.12, 2.45, 2.2), Vector3(0.55, 1.22, -1.72))
	var bathroom := Node3D.new()
	bathroom.name = "HotelRoomBathroom"
	bathroom.position = Vector3(1.55, 0.0, -1.72)
	room_root.add_child(bathroom)
	_add_hotel_room_box(bathroom, "HotelBathroomFloor", Vector3(1.95, 0.12, 2.25), Vector3.ZERO, floor)
	_add_hotel_room_box(bathroom, "HotelBathroomShower", Vector3(0.82, 1.9, 0.82), Vector3(0.52, 1.0, -0.55), glass)
	_add_hotel_room_box(bathroom, "HotelBathroomSink", Vector3(0.72, 0.82, 0.55), Vector3(-0.52, 0.42, -0.55), linen)
	_add_hotel_room_box(bathroom, "HotelBathroomToilet", Vector3(0.58, 0.62, 0.78), Vector3(0.48, 0.32, 0.58), linen)
	var door := _add_hotel_room_box(room_root, "HotelRoomDoor", Vector3(1.45, 2.72, 0.14), Vector3(0.72, 1.36, 2.82), wood)
	door.rotation.y = -0.42
	_add_hotel_room_box(room_root, "HotelRoomDoorHandle", Vector3(0.08, 0.18, 0.08), Vector3(1.28, 1.36, 2.74), gold)
	var lamp := _add_hotel_room_box(room_root, "HotelRoomBedsideLamp", Vector3(0.28, 0.72, 0.28), Vector3(-2.12, 1.08, -1.72), gold)
	lamp.set_meta("system_hotel_room_lamp", true)
	if room_id.begins_with("hotel_deluxe") or room_id == "hotel_hunter_suite" or room_id == "hotel_elite_vip":
		_add_hotel_room_box(room_root, "HotelRoomSofa", Vector3(1.75, 0.72, 0.82), Vector3(0.45, 0.42, 0.25), accent)
		_add_hotel_room_box(room_root, "HotelRoomCoffeeTable", Vector3(1.0, 0.18, 0.62), Vector3(0.45, 0.28, 0.95), wood)
	if room_id == "hotel_hunter_suite":
		_add_hotel_room_box(room_root, "HotelRoomHunterGearRack", Vector3(0.22, 1.75, 1.25), Vector3(2.25, 1.0, -1.2), gold)
		_add_hotel_room_box(room_root, "HotelRoomHunterTrophyDisplay", Vector3(0.9, 1.05, 0.22), Vector3(1.35, 1.55, 1.85), dark)
	elif room_id == "hotel_elite_vip":
		_add_hotel_room_box(room_root, "HotelRoomVIPDiningTable", Vector3(1.65, 0.16, 1.0), Vector3(0.55, 0.78, 1.45), gold)
		_add_hotel_room_box(room_root, "HotelRoomVIPChandelier", Vector3(0.8, 0.18, 0.8), Vector3(0.0, 3.05, 0.0), gold)
	var room_label := Label3D.new()
	room_label.name = "HotelRoomNameLabel"
	room_label.text = room_name
	room_label.position = Vector3(0.0, 3.25, 2.15)
	room_label.font_size = 18
	room_label.pixel_size = 0.009
	room_label.modulate = Color(1.0, 0.86, 0.58)
	room_root.add_child(room_label)
	var interaction := Area3D.new()
	interaction.name = "HotelRoomDoorInteraction"
	interaction.add_to_group("system_interactable")
	interaction.collision_layer = 1
	interaction.collision_mask = 0
	interaction.set_meta("system_tower_id", "shopping_tower_baghdad")
	interaction.set_meta("system_tower_floor_number", 28)
	interaction.set_meta("system_hotel_room_id", room_id)
	interaction.set_meta("system_hotel_room_name", room_name)
	interaction.set_meta("system_hotel_room_rate", int(room_data.get("rate", 0)))
	interaction.set_meta("system_hotel_room_required_rank", str(room_data.get("required_rank", "F")))
	interaction.set_meta("system_interaction_prompt", "معاينة وحجز " + room_name)
	var interaction_shape := CollisionShape3D.new()
	var interaction_sphere := SphereShape3D.new()
	interaction_sphere.radius = 1.8
	interaction_shape.shape = interaction_sphere
	interaction_shape.position = Vector3(0.0, 1.2, 3.15)
	interaction.add_child(interaction_shape)
	room_root.add_child(interaction)


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
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.74, 0.72, 0.66)
	wall_material.roughness = 0.88
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.22, 0.27, 0.29)
	floor_material.roughness = 0.62
	var wood_material := StandardMaterial3D.new()
	wood_material.albedo_color = Color(0.34, 0.19, 0.10)
	wood_material.roughness = 0.68
	var linen_material := StandardMaterial3D.new()
	linen_material.albedo_color = Color(0.82, 0.79, 0.71)
	linen_material.roughness = 0.92
	var accent_material := StandardMaterial3D.new()
	accent_material.albedo_color = Color(0.08, 0.32, 0.39)
	accent_material.metallic = 0.28
	var glass_material := StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(0.24, 0.62, 0.78, 0.34)
	glass_material.roughness = 0.12
	var room_materials := {
		"wall": wall_material,
		"floor": floor_material,
		"wood": wood_material,
		"linen": linen_material,
		"accent": accent_material,
		"glass": glass_material,
		"gold": gold,
		"dark": dark
	}
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
		for index in range(HOTEL_ROOM_CATALOG.size()):
			var room_data: Dictionary = HOTEL_ROOM_CATALOG[index]
			_create_hotel_room_interior(hotel, room_data, index, radius, room_materials)
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



func _add_restaurant_staff_controls(role: String) -> void:
	var heading := Label.new()
	heading.text = "طلبات المطاعم — " + ("مهام الشيف والمطبخ" if role == "restaurant_chef" else "مهام النادل والتقديم")
	content.add_child(heading)
	var visible_orders := 0
	for table_id_value in restaurant_orders.keys():
		var table_id := str(table_id_value)
		var order: Dictionary = restaurant_orders[table_id]
		var state := str(order.get("status", ""))
		var next_status := ""
		var action_text := ""
		if role == "restaurant_chef" and state == "placed":
			next_status = "preparing"
			action_text = "قبول الطلب وبدء التحضير"
		elif role == "restaurant_chef" and state == "preparing":
			next_status = "ready"
			action_text = "تأكيد جاهزية الوجبة"
		elif role == "restaurant_waiter" and state == "ready":
			next_status = "served"
			action_text = "توصيل الوجبة إلى الطاولة"
		if next_status.is_empty():
			continue
		visible_orders += 1
		var order_items: Array = order.get("items", [])
		var names: Array[String] = []
		for item_value in order_items:
			var item: Dictionary = item_value
			names.append(str(item.get("name", "وجبة")))
		var order_label := Label.new()
		order_label.text = "%s — %s — %d رصيد" % [table_id, "، ".join(PackedStringArray(names)), int(order.get("total", 0))]
		order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(order_label)
		var action_button := Button.new()
		action_button.text = action_text
		action_button.pressed.connect(_advance_restaurant_order.bind(table_id, next_status))
		content.add_child(action_button)
	if visible_orders == 0:
		var empty_label := Label.new()
		empty_label.text = "لا توجد طلبات تحتاج إلى إجراء من هذا الموظف حالياً."
		content.add_child(empty_label)

func _load_restaurant_orders() -> void:
	var config := ConfigFile.new()
	if config.load(RESTAURANT_SAVE_PATH) != OK:
		restaurant_orders = {}
		restaurant_order_history = []
		return
	var saved_orders: Variant = config.get_value("restaurant", "active_orders", {})
	var saved_history: Variant = config.get_value("restaurant", "order_history", [])
	restaurant_orders = saved_orders.duplicate(true) if saved_orders is Dictionary else {}
	restaurant_order_history = saved_history.duplicate(true) if saved_history is Array else []


func _save_restaurant_orders() -> void:
	var config := ConfigFile.new()
	config.set_value("restaurant", "active_orders", restaurant_orders)
	config.set_value("restaurant", "order_history", restaurant_order_history)
	var result := config.save(RESTAURANT_SAVE_PATH)
	if result != OK:
		push_warning("SYSTEM restaurants: could not persist dining orders.")


func open_restaurant_table(table_node: Node) -> void:
	if table_node == null or not table_node.has_meta("system_restaurant_table_id"):
		return
	current_tower_id = "shopping_tower_baghdad"
	current_restaurant_table_node = table_node
	current_restaurant_table_id = str(table_node.get_meta("system_restaurant_table_id", ""))
	if current_restaurant_table_id.is_empty():
		return
	_clear_dynamic_controls()
	title_label.text = "مطاعم برج التسوق — " + str(table_node.get_meta("system_restaurant_table_name", "طاولة الطعام"))
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): panel.hide())
	content.add_child(close_button)
	var active_order: Dictionary = restaurant_orders.get(current_restaurant_table_id, {})
	if not active_order.is_empty():
		var state := str(active_order.get("status", "placed"))
		var state_names := {
			"placed": "وصل الطلب إلى المطبخ",
			"preparing": "الشيف يحضّر الوجبة",
			"ready": "الوجبة جاهزة للتقديم",
			"served": "النادل قدّم الوجبة — استمتع بوجبتك"
		}
		var items: Array = active_order.get("items", [])
		var item_names: Array[String] = []
		for item_value in items:
			var item: Dictionary = item_value
			item_names.append(str(item.get("name", "وجبة")))
		status_label.text = "%s\n%s\nالإجمالي: %d رصيد" % [str(state_names.get(state, state)), "، ".join(PackedStringArray(item_names)), int(active_order.get("total", 0))]
		if state == "served":
			var finish_button := Button.new()
			finish_button.text = "إنهاء الوجبة ومغادرة الطاولة"
			finish_button.pressed.connect(_advance_restaurant_order.bind(current_restaurant_table_id, "completed"))
			content.add_child(finish_button)
		else:
			var waiting_label := Label.new()
			waiting_label.text = "طلبك قيد الخدمة. يتولى الشيف التحضير والنادل التقديم."
			content.add_child(waiting_label)
	else:
		status_label.text = "اختر أطباقك ومشروباتك. تُخصم القيمة عند إرسال الطلب إلى المطبخ."
		var draft: Array = restaurant_draft_items.get(current_restaurant_table_id, [])
		for product_value in PRODUCT_CATALOG["shopping_tower_baghdad"]:
			var product: Dictionary = product_value
			var item_id := str(product.get("id", ""))
			if not item_id.begins_with("restaurant_"):
				continue
			var item_button := Button.new()
			item_button.text = "إضافة %s — %d رصيد" % [str(product.get("name", "وجبة")), int(product.get("price", 0))]
			item_button.disabled = credits < int(product.get("price", 0))
			item_button.pressed.connect(_add_restaurant_draft_item.bind(current_restaurant_table_id, item_id, str(product.get("name", "وجبة")), int(product.get("price", 0))))
			content.add_child(item_button)
		var draft_total := 0
		var draft_names: Array[String] = []
		for item_value in draft:
			var item: Dictionary = item_value
			draft_total += int(item.get("price", 0))
			draft_names.append(str(item.get("name", "وجبة")))
		var draft_label := Label.new()
		draft_label.text = "طلبك: %s\nالمجموع: %d رصيد" % ["، ".join(draft_names) if not draft_names.is_empty() else "لم تختر شيئاً", draft_total]
		draft_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(draft_label)
		var place_button := Button.new()
		place_button.text = "إرسال الطلب إلى المطبخ والدفع"
		place_button.disabled = draft.is_empty() or credits < draft_total
		place_button.pressed.connect(_place_restaurant_order.bind(current_restaurant_table_id))
		content.add_child(place_button)
	panel.show()


func _add_restaurant_draft_item(table_id: String, item_id: String, item_name: String, price: int) -> void:
	var active_order: Dictionary = restaurant_orders.get(table_id, {})
	if table_id.is_empty() or price <= 0 or not active_order.is_empty():
		return
	var draft: Array = restaurant_draft_items.get(table_id, [])
	draft.append({"item_id": item_id, "name": item_name, "price": price})
	restaurant_draft_items[table_id] = draft
	if is_instance_valid(current_restaurant_table_node):
		open_restaurant_table(current_restaurant_table_node)


func _place_restaurant_order(table_id: String) -> void:
	if table_id.is_empty() or restaurant_orders.has(table_id):
		return
	var draft: Array = restaurant_draft_items.get(table_id, [])
	if draft.is_empty():
		_set_status("اختر طبقاً أو مشروباً قبل إرسال الطلب.")
		return
	var total := 0
	for item_value in draft:
		var item: Dictionary = item_value
		total += int(item.get("price", 0))
	if total <= 0 or credits < total:
		_set_status("رصيدك لا يكفي لإتمام طلب المطعم.")
		return
	credits -= total
	restaurant_orders[table_id] = {
		"table_id": table_id,
		"items": draft.duplicate(true),
		"total": total,
		"status": "placed",
		"created_at_unix": int(Time.get_unix_time_from_system()),
		"tower_id": "shopping_tower_baghdad"
	}
	restaurant_draft_items.erase(table_id)
	_save_restaurant_orders()
	_save_wallet()
	credits_label.text = "رصيدك: %d رصيد SYSTEM" % credits
	_set_status("تم إرسال طلبك إلى مطبخ المطعم. بدأ مسار تجهيز الوجبة.")
	if is_instance_valid(current_restaurant_table_node):
		open_restaurant_table(current_restaurant_table_node)


func _advance_restaurant_order(table_id: String, next_status: String) -> void:
	if not restaurant_orders.has(table_id):
		return
	var order: Dictionary = restaurant_orders[table_id]
	var current := str(order.get("status", ""))
	var allowed := {
		"placed": "preparing",
		"preparing": "ready",
		"ready": "served",
		"served": "completed"
	}
	if str(allowed.get(current, "")) != next_status:
		_set_status("لا يمكن تجاوز مراحل تجهيز وتقديم الطلب.")
		return
	order["status"] = next_status
	order["updated_at_unix"] = int(Time.get_unix_time_from_system())
	if next_status == "completed":
		restaurant_order_history.append(order.duplicate(true))
		restaurant_orders.erase(table_id)
	else:
		restaurant_orders[table_id] = order
	_save_restaurant_orders()
	_set_status("تم تحديث حالة طلب المطعم: " + next_status)
	if panel.visible and is_instance_valid(current_restaurant_table_node) and current_restaurant_table_id == table_id:
		open_restaurant_table(current_restaurant_table_node)
	elif panel.visible and current_tower_id == "shopping_tower_baghdad" and not current_staff_id.is_empty():
		var shopping_tower := tower_nodes.get("shopping_tower_baghdad") as Node3D
		var lobby := shopping_tower.get_node_or_null("PublicLobby_Blockout") as Node3D if shopping_tower != null else null
		var staff_node := lobby.get_node_or_null("TowerStaff_" + current_staff_id) if lobby != null else null
		if staff_node != null:
			open_staff_service(staff_node)


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
		table_root.set_meta("system_restaurant_table_id", "shopping_floor_%02d_table_%02d" % [floor_number, index])
		table_root.set_meta("system_restaurant_table_name", "طاولة %d — الطابق %d" % [index + 1, floor_number])
		table_root.set_meta("system_restaurant_table_index", index)
		table_root.set_meta("system_restaurant_occupants", [])
		room.add_child(table_root)
		var interaction_body := StaticBody3D.new()
		interaction_body.name = "RestaurantTableInteraction"
		interaction_body.collision_layer = 1
		interaction_body.collision_mask = 0
		interaction_body.add_to_group("system_interactable")
		interaction_body.set_meta("system_restaurant_table_id", str(table_root.get_meta("system_restaurant_table_id")))
		interaction_body.set_meta("system_restaurant_table_name", str(table_root.get_meta("system_restaurant_table_name")))
		interaction_body.set_meta("system_interaction_prompt", "مطعم SYSTEM — اجلس واطلب الطعام")
		var interaction_shape := CollisionShape3D.new()
		var interaction_box := BoxShape3D.new()
		interaction_box.size = Vector3(2.8, 1.25, 1.8)
		interaction_shape.shape = interaction_box
		interaction_shape.position.y = 1.0
		interaction_body.add_child(interaction_shape)
		table_root.add_child(interaction_body)
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
			var seat_marker := Node3D.new()
			seat_marker.name = "RestaurantSeat_%02d" % seat_index
			seat_marker.position = Vector3(cos(seat_angle) * 1.05, 0.0, sin(seat_angle) * 0.78)
			seat_marker.set_meta("system_restaurant_seat_occupant", "")
			table_root.add_child(seat_marker)
	var queue_sign := Label3D.new()
	queue_sign.name = "RestaurantQueueSign"
	queue_sign.text = "QUEUE — طابور انتظار الطاولات"
	queue_sign.position = Vector3(-radius * 0.30, 2.1, radius * 0.20)
	queue_sign.font_size = 15
	queue_sign.pixel_size = 0.012
	queue_sign.modulate = Color(0.55, 0.9, 1.0)
	room.add_child(queue_sign)
	for queue_index in range(8):
		var queue_marker := Node3D.new()
		queue_marker.name = "RestaurantQueuePosition_%02d" % queue_index
		queue_marker.position = Vector3(-radius * 0.30, 0.0, radius * 0.20 + float(queue_index) * 1.15)
		queue_marker.set_meta("system_restaurant_queue_occupant", "")
		var ring := MeshInstance3D.new()
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = 0.34
		ring_mesh.bottom_radius = 0.34
		ring_mesh.height = 0.05
		ring.mesh = ring_mesh
		var ring_material := StandardMaterial3D.new()
		ring_material.albedo_color = Color(0.12, 0.62, 0.78, 0.72)
		ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = ring_material
		ring.position.y = 0.04
		queue_marker.add_child(ring)
		room.add_child(queue_marker)


func _seat_customer_at_restaurant(visitor: Node3D, room: Node3D, queue_seed: int) -> void:
	if visitor == null or room == null:
		return
	var customer_id := str(visitor.get_meta("system_tower_customer_id", visitor.name))
	for table_index in range(4):
		var table_root := room.get_node_or_null("RestaurantTable_%02d" % table_index) as Node3D
		if table_root == null:
			continue
		for seat_index in range(4):
			var seat_marker := table_root.get_node_or_null("RestaurantSeat_%02d" % seat_index) as Node3D
			if seat_marker == null or not str(seat_marker.get_meta("system_restaurant_seat_occupant", "")).is_empty():
				continue
			var old_queue_name := str(visitor.get_meta("system_restaurant_queue_marker", ""))
			if not old_queue_name.is_empty():
				var old_queue_marker := room.get_node_or_null(old_queue_name) as Node3D
				if old_queue_marker != null:
					old_queue_marker.set_meta("system_restaurant_queue_occupant", "")
			seat_marker.set_meta("system_restaurant_seat_occupant", customer_id)
			var occupants: Array = table_root.get_meta("system_restaurant_occupants", [])
			if not occupants.has(customer_id):
				occupants.append(customer_id)
			table_root.set_meta("system_restaurant_occupants", occupants)
			visitor.position = table_root.position + seat_marker.position
			visitor.rotation.y = atan2(table_root.position.x - visitor.position.x, table_root.position.z - visitor.position.z)
			visitor.set_meta("system_restaurant_table_node", table_root.name)
			visitor.set_meta("system_restaurant_seat_node", seat_marker.name)
			visitor.remove_meta("system_restaurant_queue_marker")
			for visitor_child in visitor.get_children():
				if visitor_child.has_method("set_activity"):
					visitor_child.call("set_activity", "eat")
			return
	for queue_index in range(8):
		var marker_index := posmod(queue_seed + queue_index, 8)
		var queue_marker := room.get_node_or_null("RestaurantQueuePosition_%02d" % marker_index) as Node3D
		if queue_marker == null or not str(queue_marker.get_meta("system_restaurant_queue_occupant", "")).is_empty():
			continue
		queue_marker.set_meta("system_restaurant_queue_occupant", customer_id)
		visitor.position = queue_marker.position
		visitor.set_meta("system_restaurant_queue_marker", queue_marker.name)
		visitor.remove_meta("system_restaurant_table_node")
		visitor.remove_meta("system_restaurant_seat_node")
		for visitor_child in visitor.get_children():
			if visitor_child.has_method("set_activity"):
				visitor_child.call("set_activity", "wait")
		return
	visitor.set_meta("system_restaurant_queue_overflow", true)
	visitor.position = Vector3(-room.get_meta("system_tower_radius", 24.0) * 0.3, 0.0, room.get_meta("system_tower_radius", 24.0) * 0.45 + float(queue_seed) * 1.1)


func _promote_restaurant_queue(room: Node3D) -> void:
	if room == null:
		return
	for queue_index in range(8):
		var queue_marker := room.get_node_or_null("RestaurantQueuePosition_%02d" % queue_index) as Node3D
		if queue_marker == null:
			continue
		var customer_id := str(queue_marker.get_meta("system_restaurant_queue_occupant", ""))
		if customer_id.is_empty():
			continue
		var visitor := room.get_node_or_null("TowerCustomer_" + customer_id) as Node3D
		if visitor != null:
			_seat_customer_at_restaurant(visitor, room, queue_index)
			return


func _release_restaurant_customer_seat(visitor: Node3D) -> void:
	if visitor == null or not is_instance_valid(visitor):
		return
	var room := visitor.get_parent() as Node3D
	if room == null:
		return
	var customer_id := str(visitor.get_meta("system_tower_customer_id", visitor.name))
	var table_name := str(visitor.get_meta("system_restaurant_table_node", ""))
	var seat_name := str(visitor.get_meta("system_restaurant_seat_node", ""))
	var released_seat := false
	if not table_name.is_empty():
		var table_root := room.get_node_or_null(table_name) as Node3D
		var seat_marker := table_root.get_node_or_null(seat_name) as Node3D if table_root != null else null
		if seat_marker != null and str(seat_marker.get_meta("system_restaurant_seat_occupant", "")) == customer_id:
			seat_marker.set_meta("system_restaurant_seat_occupant", "")
			released_seat = true
		if table_root != null:
			var occupants: Array = table_root.get_meta("system_restaurant_occupants", [])
			occupants.erase(customer_id)
			table_root.set_meta("system_restaurant_occupants", occupants)
		visitor.remove_meta("system_restaurant_table_node")
		visitor.remove_meta("system_restaurant_seat_node")
	var queue_name := str(visitor.get_meta("system_restaurant_queue_marker", ""))
	if not queue_name.is_empty():
		var queue_marker := room.get_node_or_null(queue_name) as Node3D
		if queue_marker != null and str(queue_marker.get_meta("system_restaurant_queue_occupant", "")) == customer_id:
			queue_marker.set_meta("system_restaurant_queue_occupant", "")
		visitor.remove_meta("system_restaurant_queue_marker")
	visitor.remove_meta("system_restaurant_queue_overflow")
	if released_seat:
		_promote_restaurant_queue(room)


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
	if is_instance_valid(active_floor_root) and str(active_floor_root.get_meta("system_tower_id", "")) != tower_id:
		_return_customer_visitors_to_lobbies()
	var car := _ensure_elevator_car(tower_id, start_y)
	if car == null:
		_set_status("تعذر تجهيز عربة المصعد.")
		return
	_board_customer_visitors_into_elevator(tower_id, floor_number, car)
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
	if is_instance_valid(active_floor_root) and (tower_id != current_tower_id or floor_number != int(active_floor_root.get_meta("system_tower_floor_number", 0))):
		_clear_pool_visit_state()
	_return_floor_duty_staff_to_lobbies()
	var duty_staff_trip := _board_floor_duty_staff(tower_id, floor_number, car)
	if not is_instance_valid(active_floor_root):
		player.global_position = tower.to_global(Vector3(0.0, start_y + 1.2, 0.0))
	if is_instance_valid(active_floor_root) and active_floor_root != room:
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
		_place_floor_duty_staff_on_floor(duty_staff_trip, room, float(config["radius"]))
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
	_board_customer_visitors_into_elevator(current_tower_id, 1, car)
	var returning_staff := _board_active_floor_duty_staff_for_lobby_return(car)
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
			_clear_pool_visit_state()
			_disembark_customer_visitors_to_lobby(current_tower_id, car)
			_finish_staff_lobby_return(returning_staff)
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

