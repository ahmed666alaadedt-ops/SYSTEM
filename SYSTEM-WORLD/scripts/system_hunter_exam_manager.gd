extends Node
class_name SYSTEMHunterExamManager

signal exam_registered(candidate_number: int)
signal stage_started(stage_id: String, stage_number: int)
signal stage_completed(stage_id: String, stage_number: int)
signal exam_failed(reason: String)
signal license_earned(candidate_number: int, license_rank: String)

const SAVE_PATH := "user://system_hunter_exam.cfg"
const EXAM_STAGES := [
	{"id":"baghdad_heritage_trial","city":"Baghdad","title":"اختبار الأثر الرافديني","type":"heritage_riddle_trial","difficulty":3,"description":"اقرأ نقوش العين والنهر والتاج بالترتيب، تجاوز الفخاخ، واسترجع الأثر الصحيح."},
	{"id":"cairo_buried_market","city":"Cairo","title":"متاهة السوق المدفون","type":"resource_navigation_trial","difficulty":4,"description":"تنقل بين طرق السوق المتغيرة، حافظ على الماء والمؤونة، واعثر على المخرج."},
	{"id":"alexandria_lighthouse","city":"Alexandria","title":"اختبار المنارة والعاصفة","type":"coastal_rescue_trial","difficulty":4,"description":"أصلح إشارة المنارة، أنقذ المتسابق العالق، ووجّه الضوء عبر العاصفة."},
	{"id":"paris_catacombs","city":"Paris","title":"سراديب باريس الصامتة","type":"stealth_logic_trial","difficulty":5,"description":"حلل الأصداء والإشارات واعبر السراديب دون تنبيه الحراس."},
	{"id":"babylon_guardian","city":"Babylon","title":"آلية حارس بابل","type":"guardian_mechanism_trial","difficulty":5,"description":"افهم تروس الحارس وعطّل الآلية واستعد الختم."},
	{"id":"tokyo_urban_pursuit","city":"Tokyo","title":"مطاردة المدينة المتغيرة","type":"urban_observation_trial","difficulty":5,"description":"تتبع الأثر وساعد المدنيين وحدد نقطة الاعتراض دون تعريضهم للخطر."},
	{"id":"final_survival_route","city":"Highland Frontier","title":"مسار البقاء الأخير","type":"survival_teamwork_trial","difficulty":6,"description":"اجمع المؤونة واعثر على مأوى واجتز طريق القمة في ظروف قاسية."}
]

var candidate_number := 0
var invitation_accepted := false
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
	if registered:
		return {"success":false,"reason":"ALREADY_REGISTERED","candidate_number":candidate_number,"stages":EXAM_STAGES.size()}
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	candidate_number = int(config.get_value("exam","next_candidate_number",1001))
	config.set_value("exam","next_candidate_number",candidate_number + 1)
	config.set_value("exam","candidate_number",candidate_number)
	config.set_value("exam","player_id",player_id)
	config.set_value("exam","invitation_accepted",true)
	config.set_value("exam","completed_stage_ids",[])
	config.set_value("exam","exam_active",false)
	config.save(SAVE_PATH)
	invitation_accepted = true
	registered = true
	exam_active = false
	current_stage_index = -1
	completed_stage_ids.clear()
	failed = false
	failure_reason = ""
	exam_registered.emit(candidate_number)
	return {"success":true,"candidate_number":candidate_number,"stages":EXAM_STAGES.size(),"message":"تم تسجيلك. احتفظ برقمك طوال المراحل السبع."}

func accept_exam_invitation(player_id: String) -> Dictionary:
	if player_id.strip_edges().is_empty():
		return {"success":false,"reason":"PLAYER_ID_REQUIRED"}
	if registered:
		return {"success":true,"already_registered":true,"candidate_number":candidate_number}
	if invitation_accepted:
		return {"success":true,"pending_tunnel_registration":true,"message":"تم قبول طلبك. اتبع مرشد نقابة الصيادين إلى النفق."}
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("exam", "player_id", player_id)
	config.set_value("exam", "invitation_accepted", true)
	config.set_value("exam", "candidate_number", 0)
	config.set_value("exam", "exam_active", false)
	config.save(SAVE_PATH)
	invitation_accepted = true
	registered = false
	candidate_number = 0
	return {"success":true,"pending_tunnel_registration":true,"message":"تم قبول طلبك. اتبع مرشد نقابة الصيادين إلى النفق."}

func register_candidate_at_tunnel(player_id: String) -> Dictionary:
	if not invitation_accepted:
		return {"success":false,"reason":"INVITATION_NOT_ACCEPTED"}
	if registered and candidate_number > 0:
		return {"success":true,"already_registered":true,"candidate_number":candidate_number}
	if player_id.strip_edges().is_empty():
		return {"success":false,"reason":"PLAYER_ID_REQUIRED"}
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	candidate_number = int(config.get_value("exam", "next_candidate_number", 1001))
	config.set_value("exam", "next_candidate_number", candidate_number + 1)
	config.set_value("exam", "candidate_number", candidate_number)
	config.set_value("exam", "player_id", player_id)
	config.set_value("exam", "invitation_accepted", true)
	config.set_value("exam", "completed_stage_ids", [])
	config.set_value("exam", "exam_active", false)
	config.save(SAVE_PATH)
	registered = true
	exam_active = false
	current_stage_index = -1
	completed_stage_ids.clear()
	failed = false
	failure_reason = ""
	exam_registered.emit(candidate_number)
	return {"success":true,"candidate_number":candidate_number,"message":"تم تسجيلك في النفق. هذا رقمك التسلسلي الدائم."}

func begin_exam() -> Dictionary:
	if not registered:
		return {"success":false,"reason":"NOT_REGISTERED"}
	if failed:
		return {"success":false,"reason":"EXAM_FAILED"}
	if completed_stage_ids.size() >= EXAM_STAGES.size():
		exam_active = false
		current_stage_index = EXAM_STAGES.size()
		return {"success":false,"reason":"ALL_STAGES_COMPLETED"}
	if exam_active:
		return {"success":true,"candidate_number":candidate_number,"stage":get_current_stage(),"resumed":true}
	exam_active = true
	current_stage_index = completed_stage_ids.size()
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
	return {"candidate_number":candidate_number,"invitation_accepted":invitation_accepted,"registered":registered,"active":exam_active,"current_stage_index":current_stage_index,"completed_stages":completed_stage_ids.duplicate(),"total_stages":EXAM_STAGES.size(),"failed":failed,"failure_reason":failure_reason,"stages":EXAM_STAGES.duplicate(true)}

func _load_exam_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	candidate_number = int(config.get_value("exam", "candidate_number", 0))
	invitation_accepted = bool(config.get_value("exam", "invitation_accepted", candidate_number > 0))
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
	config.set_value("exam", "invitation_accepted", invitation_accepted)
	config.set_value("exam", "completed_stage_ids", completed_stage_ids)
	config.set_value("exam", "exam_active", exam_active)
	config.set_value("exam", "current_stage_index", current_stage_index)
	config.set_value("exam", "failed", failed)
	config.set_value("exam", "failure_reason", failure_reason)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM: Hunter examination progress could not be saved.")
