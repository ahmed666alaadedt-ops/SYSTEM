extends Node
class_name SYSTEMHunterExamManager

signal exam_registered(candidate_number: int)
signal stage_started(stage_id: String, stage_number: int)
signal stage_completed(stage_id: String, stage_number: int)
signal exam_failed(reason: String)
signal license_earned(candidate_number: int, license_rank: String)

const SAVE_PATH := "user://system_hunter_exam.cfg"
const RETRY_CYCLE_SECONDS := 7 * 24 * 60 * 60
const EXAM_STAGES := [
	{"id":"endurance_pursuit","city":"Baghdad outskirts","title":"المرحلة الأولى: المطاردة والتحمل","type":"endurance_tracking","difficulty":3,"description":"تتبّع الهدف عبر مسار طويل، اجتز نقاط التفتيش، حافظ على طاقتك، ولا تؤذِ المدنيين.","objectives":["تسجيل ثلاث نقاط تتبع صحيحة","إكمال مسار التحمل ضمن الحد الزمني","حماية المدنيين وتجنب المخالفات"]},
	{"id":"fieldcraft_and_cooking","city":"Babylon frontier","title":"المرحلة الثانية: المهارة والمعرفة","type":"fieldcraft_cooking","difficulty":3,"description":"اجمع مكونات محددة من البيئة، تعرّف على خصائصها، وأعد وجبة وفق وصفة الاختبار.","objectives":["جمع المكونات الصحيحة","تمييز المواد الآمنة من غير الصالحة","إعداد الوصفة وتسليمها"]},
	{"id":"tower_of_choices","city":"Baghdad examination tower","title":"المرحلة الثالثة: برج الاختبارات","type":"puzzles_and_decisions","difficulty":4,"description":"اصعد برجاً متعدد المسارات، حل ألغازاً مترابطة، واتخذ قرارات تؤثر في طريق فريقك.","objectives":["حل ثلاثة ألغاز مترابطة","اختيار مسار مع تبرير القرار","الوصول إلى بوابة الخروج"]},
	{"id":"island_survival","city":"Island wilderness","title":"المرحلة الرابعة: البقاء في الجزيرة","type":"island_survival","difficulty":4,"description":"ابقَ على قيد الحياة في جزيرة متغيرة، وأدر الماء والطعام والمأوى والطقس دون الاعتماد على القتال وحده.","objectives":["تأمين الماء والطعام","إنشاء مأوى آمن","الوصول إلى نقطة الإخلاء"]},
	{"id":"strategy_and_negotiation","city":"Freeport district","title":"المرحلة الخامسة: الاستراتيجية والتفاوض","type":"strategy_deception_negotiation","difficulty":5,"description":"اجمع المعلومات، اكشف التضليل، فاوض أطرافاً متعارضة، واختر متى تتعاون ومتى تنسحب.","objectives":["جمع دليلين مستقلين","كشف معلومة مضللة","إتمام اتفاق أو انسحاب آمن"]},
	{"id":"individual_duels","city":"Hunter arena","title":"المرحلة السادسة: المواجهات الفردية","type":"individual_duels","difficulty":5,"description":"واجه خصوماً في نزالات فردية بقواعد واضحة؛ الفوز ليس بالقوة وحدها بل بالتحكم والانضباط واحترام قواعد السلامة.","objectives":["إكمال المواجهة الأولى","إظهار التحكم والدفاع","اجتياز مواجهة التقييم"]},
	{"id":"secret_final_trial","city":"Classified SYSTEM location","title":"المرحلة السابعة: الاختبار النهائي السري","type":"secret_final_trial","difficulty":5,"description":"اختبار نهائي يتغير بين الدفعات ويجمع الملاحظة والقرار والتعاون؛ تفاصيله لا تكشف قبل بدء المرحلة.","objectives":["اكتشاف الهدف الحقيقي","اتخاذ القرار النهائي","العودة إلى لجنة التقييم"]}
]

var candidate_number := 0
var player_id := ""
var attempt_number := 0
var last_failure_unix := 0
var license_earned_permanently := false
var registered := false
var exam_active := false
var current_stage_index := -1
var completed_stage_ids: Array[String] = []
var failed := false
var failure_reason := ""

func _ready() -> void:
	name = "SYSTEMHunterExamManager"
	_load_exam_state()

func apply_for_exam(player_id: String) -> Dictionary:
	if player_id.strip_edges().is_empty():
		return {"success":false,"reason":"PLAYER_ID_REQUIRED"}
	if registered and completed_stage_ids.size() >= EXAM_STAGES.size():
		return {"success":false,"reason":"HUNTER_LICENSE_ALREADY_EARNED","candidate_number":candidate_number}
	if registered and not failed:
		return {"success":false,"reason":"ALREADY_REGISTERED","candidate_number":candidate_number,"stages":EXAM_STAGES.size()}
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	candidate_number = int(config.get_value("exam","next_candidate_number",1001))
	config.set_value("exam","next_candidate_number",candidate_number + 1)
	config.set_value("exam","candidate_number",candidate_number)
	config.set_value("exam","player_id",player_id)
	attempt_number += 1
	config.set_value("exam","attempt_number",attempt_number)
	config.set_value("exam","last_failure_unix",last_failure_unix)
	config.set_value("exam","license_earned_permanently",false)
	config.set_value("exam","completed_stage_ids",[])
	config.set_value("exam","exam_active",false)
	config.set_value("exam","current_stage_index",-1)
	config.set_value("exam","failed",false)
	config.set_value("exam","failure_reason","")
	config.save(SAVE_PATH)
	self.player_id = player_id
	registered = true
	exam_active = false
	current_stage_index = -1
	completed_stage_ids.clear()
	failed = false
	failure_reason = ""
	exam_registered.emit(candidate_number)
	return {"success":true,"candidate_number":candidate_number,"stages":EXAM_STAGES.size(),"message":"تم تسجيلك. احتفظ برقمك طوال الاختبار."}

func begin_exam() -> Dictionary:
	if not registered:
		return {"success":false,"reason":"NOT_REGISTERED"}
	if failed:
		return {"success":false,"reason":"EXAM_FAILED"}
	if exam_active:
		var active_stage := get_current_stage()
		if active_stage.is_empty():
			return {"success":false,"reason":"ACTIVE_STAGE_STATE_INVALID"}
		return {"success":true,"candidate_number":candidate_number,"stage":active_stage,"resumed":true}
	current_stage_index = completed_stage_ids.size()
	if current_stage_index >= EXAM_STAGES.size():
		return {"success":false,"reason":"ALL_STAGES_COMPLETED"}
	exam_active = true
	_save_exam_state()
	stage_started.emit(str(EXAM_STAGES[current_stage_index]["id"]),current_stage_index + 1)
	return {"success":true,"candidate_number":candidate_number,"stage":get_current_stage()}

func get_current_stage() -> Dictionary:
	if not exam_active or current_stage_index < 0 or current_stage_index >= EXAM_STAGES.size():
		return {}
	return EXAM_STAGES[current_stage_index].duplicate(true)

func complete_current_stage(stage_id: String, verified_evidence: String) -> Dictionary:
	if not exam_active or current_stage_index < 0:
		return {"success":false,"reason":"NO_ACTIVE_STAGE"}
	var stage: Dictionary = EXAM_STAGES[current_stage_index]
	if stage_id != str(stage["id"]):
		return {"success":false,"reason":"STAGE_ORDER_MISMATCH"}
	if verified_evidence.strip_edges().is_empty():
		return {"success":false,"reason":"VERIFIED_EVIDENCE_REQUIRED"}
	if completed_stage_ids.has(stage_id):
		return {"success":false,"reason":"STAGE_ALREADY_COMPLETED"}
	completed_stage_ids.append(stage_id)
	stage_completed.emit(stage_id,current_stage_index + 1)
	current_stage_index += 1
	if current_stage_index >= EXAM_STAGES.size():
		exam_active = false
		_save_exam_state()
		license_earned_permanently = true
		_save_exam_state()
		license_earned.emit(candidate_number,"HUNTER_LICENSE")
		return {"success":true,"exam_completed":true,"candidate_number":candidate_number,"license_rank":"HUNTER_LICENSE","permanent":true}
	_save_exam_state()
	var next_stage: Dictionary = EXAM_STAGES[current_stage_index]
	stage_started.emit(str(next_stage["id"]),current_stage_index + 1)
	return {"success":true,"exam_completed":false,"next_stage":next_stage}

func withdraw_or_fail(reason: String) -> void:
	if not exam_active:
		return
	exam_active = false
	failed = true
	failure_reason = reason
	last_failure_unix = int(Time.get_unix_time_from_system())
	exam_failed.emit(reason)
	_save_exam_state()

func get_exam_overview() -> Dictionary:
	var retry_at := last_failure_unix + RETRY_CYCLE_SECONDS if failed and last_failure_unix > 0 else 0
	return {"candidate_number":candidate_number,"player_id":player_id,"attempt_number":attempt_number,"registered":registered,"active":exam_active,"current_stage_index":current_stage_index,"completed_stages":completed_stage_ids.duplicate(),"total_stages":EXAM_STAGES.size(),"failed":failed,"failure_reason":failure_reason,"retry_at":retry_at,"license_earned_permanently":license_earned_permanently,"stages":EXAM_STAGES.duplicate(true)}


func _load_exam_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	candidate_number = int(config.get_value("exam", "candidate_number", 0))
	player_id = str(config.get_value("exam", "player_id", ""))
	attempt_number = int(config.get_value("exam", "attempt_number", 0))
	last_failure_unix = int(config.get_value("exam", "last_failure_unix", 0))
	license_earned_permanently = bool(config.get_value("exam", "license_earned_permanently", false))
	registered = candidate_number > 0
	exam_active = bool(config.get_value("exam", "exam_active", false))
	failed = bool(config.get_value("exam", "failed", false))
	failure_reason = str(config.get_value("exam", "failure_reason", ""))
	completed_stage_ids.clear()
	for stage_id in config.get_value("exam", "completed_stage_ids", []):
		completed_stage_ids.append(str(stage_id))
	current_stage_index = completed_stage_ids.size() if exam_active else -1


func _save_exam_state() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("exam", "candidate_number", candidate_number)
	config.set_value("exam", "player_id", player_id)
	config.set_value("exam", "attempt_number", attempt_number)
	config.set_value("exam", "last_failure_unix", last_failure_unix)
	config.set_value("exam", "license_earned_permanently", license_earned_permanently)
	config.set_value("exam", "completed_stage_ids", completed_stage_ids)
	config.set_value("exam", "exam_active", exam_active)
	config.set_value("exam", "current_stage_index", current_stage_index)
	config.set_value("exam", "failed", failed)
	config.set_value("exam", "failure_reason", failure_reason)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM: Hunter examination progress could not be saved.")
