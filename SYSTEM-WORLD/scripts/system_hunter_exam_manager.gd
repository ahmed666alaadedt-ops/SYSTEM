extends Node
class_name SYSTEMHunterExamManager

signal exam_registered(candidate_number: int)
signal stage_started(stage_id: String, stage_number: int)
signal stage_completed(stage_id: String, stage_number: int)
signal exam_failed(reason: String)
signal license_earned(candidate_number: int, license_rank: String)

const SAVE_PATH := "user://system_hunter_exam.cfg"
const EXAM_STAGES := [
	{"id":"baghdad_heritage_trial","city":"Baghdad","title":"اختبار الأثر الرافديني","type":"artifact_recovery","difficulty":3,"description":"دخول موقع أثري مغلق، قراءة النقوش، تحديد القطعة الصحيحة وتجنب الفخاخ الوهمية والحقيقية."},
	{"id":"cairo_buried_market","city":"Cairo","title":"متاهة السوق المدفون","type":"maze_navigation","difficulty":4,"description":"متاهة متعددة الطبقات، طرق تتغير، موارد محدودة وعلامات مضللة؛ يجب إيجاد المخرج دون إضاعة فريقك."},
	{"id":"alexandria_lighthouse","city":"Alexandria","title":"اختبار المنارة والعاصفة","type":"navigation_rescue","difficulty":4,"description":"توجيه فريق عبر ممرات ساحلية وعاصفة، تشغيل إشارات قديمة وإنقاذ متسابقين."},
	{"id":"paris_catacombs","city":"Paris","title":"سراديب باريس الصامتة","type":"logic_and_stealth","difficulty":4,"description":"شبكة سراديب وألغاز صوتية ومسارات مراقبة؛ القتال ليس الحل الأفضل."},
	{"id":"babylon_guardian","city":"Babylon","title":"حارس بابل","type":"guardian_trial","difficulty":5,"description":"اجتياز أطلال بابل، كشف آلية الحارس، ثم مواجهة حارس قوي وفق قواعد المرحلة."},
	{"id":"tokyo_urban_pursuit","city":"Tokyo","title":"مطاردة المدينة المتغيرة","type":"urban_pursuit","difficulty":4,"description":"سباق تتبع وملاحظة بين أحياء حضرية وحواجز متغيرة، مع منع إيذاء المدنيين."},
	{"id":"final_survival_route","city":"Highland Frontier","title":"مسار البقاء الأخير","type":"survival_and_teamwork","difficulty":5,"description":"مسار جبلي طويل، طقس قاسٍ وموارد محدودة وقرارات تعاون؛ يصل للنهاية من يوازن بين السرعة والبقاء."}
]

var candidate_number := 0
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
	config.set_value("exam","completed_stage_ids",[])
	config.set_value("exam","exam_active",false)
	config.save(SAVE_PATH)
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
		return {"success":false,"reason":"EXAM_ALREADY_ACTIVE"}
	if exam_active:
		return {"success":true,"candidate_number":candidate_number,"stage":get_current_stage(),"resumed":true}
	exam_active = true
	current_stage_index = completed_stage_ids.size()
	if current_stage_index >= EXAM_STAGES.size():
		return {"success":false,"reason":"ALL_STAGES_COMPLETED"}
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
		license_earned.emit(candidate_number,"PROVISIONAL_HUNTER")
		return {"success":true,"exam_completed":true,"candidate_number":candidate_number,"license_rank":"PROVISIONAL_HUNTER"}
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
	exam_failed.emit(reason)
	_save_exam_state()

func get_exam_overview() -> Dictionary:
	return {"candidate_number":candidate_number,"registered":registered,"active":exam_active,"current_stage_index":current_stage_index,"completed_stages":completed_stage_ids.duplicate(),"total_stages":EXAM_STAGES.size(),"failed":failed,"failure_reason":failure_reason,"stages":EXAM_STAGES.duplicate(true)}


func _load_exam_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	candidate_number = int(config.get_value("exam", "candidate_number", 0))
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
	config.set_value("exam", "completed_stage_ids", completed_stage_ids)
	config.set_value("exam", "exam_active", exam_active)
	config.set_value("exam", "current_stage_index", current_stage_index)
	config.set_value("exam", "failed", failed)
	config.set_value("exam", "failure_reason", failure_reason)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM: Hunter examination progress could not be saved.")
