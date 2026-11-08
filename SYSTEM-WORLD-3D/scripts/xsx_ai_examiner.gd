
extends Node

class_name XSXAIExaminer

# SYSTEM WORLD - XSX AI EXAMINATION SYSTEM
# Godot 4.3
# AI characters are examiners only, never contestants.
# Local prototype. Production authority must be server-side.

signal exam_started(player_id: String, exam_id: String)
signal stage_started(player_id: String, stage_id: String, stage_number: int)
signal stage_completed(player_id: String, stage_id: String, score: int)
signal exam_completed(player_id: String, passed: bool, final_score: int)
signal exam_review_required(player_id: String, reason: String)

const SAVE_PATH := "user://xsx_ai_exam_data.json"
const SAVE_VERSION := 2

const PASS_SCORE := 70
const MIN_STAGE_SCORE := 40

const ORGANIZATION_NAME := "XSX"
const DIRECTOR_TITLE := "مدير منظمة XSX"
const ISLAND_KING_TITLE := "ملك جزيرة الطمع"
const DIRECTOR_ISLAND_KING_IS_SAME_PERSON := true

const AI_EXAMINERS := {
	"ai_examiner_endurance": {
		"name": "الممتحن الذكي للتحمل",
		"specialty": "endurance"
	},
	"ai_examiner_navigation": {
		"name": "الممتحن الذكي للملاحة",
		"specialty": "navigation"
	},
	"ai_examiner_survival": {
		"name": "الممتحن الذكي للنجاة",
		"specialty": "survival"
	},
	"ai_examiner_intelligence": {
		"name": "الممتحن الذكي للذكاء",
		"specialty": "intelligence"
	},
	"ai_examiner_combat": {
		"name": "الممتحن الذكي للمواجهة",
		"specialty": "combat"
	}
}

const EXAM_STAGES := [
	{
		"id": "endurance",
		"name": "اختبار التحمل",
		"description": "الجري وعبور المسافات والمناطق الصعبة",
		"examiner_id": "ai_examiner_endurance",
		"weights": {
			"completion": 0.40,
			"precision": 0.15,
			"decision": 0.20,
			"survival": 0.25
		}
	},
	{
		"id": "navigation",
		"name": "اختبار الملاحة",
		"description": "اكتشاف الطرق والعثور على المواقع المطلوبة",
		"examiner_id": "ai_examiner_navigation",
		"weights": {
			"completion": 0.35,
			"precision": 0.35,
			"decision": 0.20,
			"survival": 0.10
		}
	},
	{
		"id": "wilderness",
		"name": "اختبار النجاة",
		"description": "البقاء في الغابات والجبال وجمع الموارد",
		"examiner_id": "ai_examiner_survival",
		"weights": {
			"completion": 0.30,
			"precision": 0.15,
			"decision": 0.25,
			"survival": 0.30
		}
	},
	{
		"id": "sea_trial",
		"name": "اختبار البحر",
		"description": "السفن والعواصف والنجاة من المخاطر البحرية",
		"examiner_id": "ai_examiner_survival",
		"weights": {
			"completion": 0.30,
			"precision": 0.25,
			"decision": 0.25,
			"survival": 0.20
		}
	},
	{
		"id": "observation",
		"name": "اختبار الملاحظة",
		"description": "اكتشاف الأدلة والتفاصيل والمعلومات المخفية",
		"examiner_id": "ai_examiner_intelligence",
		"weights": {
			"completion": 0.20,
			"precision": 0.45,
			"decision": 0.25,
			"survival": 0.10
		}
	},
	{
		"id": "puzzle",
		"name": "اختبار الذكاء",
		"description": "حل الألغاز والمواقف المعقدة",
		"examiner_id": "ai_examiner_intelligence",
		"weights": {
			"completion": 0.25,
			"precision": 0.40,
			"decision": 0.30,
			"survival": 0.05
		}
	},
	{
		"id": "combat",
		"name": "اختبار المواجهة",
		"description": "القتال والتكتيك والتعامل مع الخصوم",
		"examiner_id": "ai_examiner_combat",
		"weights": {
			"completion": 0.30,
			"precision": 0.25,
			"decision": 0.25,
			"survival": 0.20
		}
	},
	{
		"id": "final_trial",
		"name": "الاختبار النهائي",
		"description": "اختبار شامل يجمع المهارات السابقة",
		"examiner_id": "ai_examiner_combat",
		"weights": {
			"completion": 0.30,
			"precision": 0.25,
			"decision": 0.25,
			"survival": 0.20
		}
	}
]

var exam_sessions: Dictionary = {}


func _ready() -> void:
	randomize()
	load_data()


# ==================================================
# AUTHORITY INFORMATION
# ==================================================

func get_exam_authority() -> Dictionary:
	return {
		"organization": ORGANIZATION_NAME,
		"director_title": DIRECTOR_TITLE,
		"island_king_title": ISLAND_KING_TITLE,
		"same_person": DIRECTOR_ISLAND_KING_IS_SAME_PERSON,
		"examiners_are_ai": true,
		"ai_are_contestants": false,
		"final_authority": "XSXAssociation"
	}


func get_ai_examiners() -> Dictionary:
	return AI_EXAMINERS.duplicate(true)


func get_exam_stages() -> Array:
	return EXAM_STAGES.duplicate(true)


# ==================================================
# APPLY FOR EXAMINATION
# ==================================================

func apply_for_exam(player_id: String) -> Dictionary:
	if player_id.strip_edges().is_empty():
		return _failure("INVALID_PLAYER_ID")

	var profile := XSXAssociation.get_hunter_profile(player_id)

	if profile.is_empty():
		return _failure("PLAYER_NOT_REGISTERED")

	if bool(profile.get("license_active", false)):
		return _failure("ALREADY_LICENSED")

	return XSXAssociation.apply_for_examination(player_id)


# ==================================================
# START EXAM
# ==================================================

# cohort_id is optional to preserve the original solo prototype.
# When supplied, the player must belong to an active human cohort.

func start_exam(
	player_id: String,
	cohort_id: String = ""
) -> Dictionary:

	if player_id.strip_edges().is_empty():
		return _failure("INVALID_PLAYER_ID")

	var profile := XSXAssociation.get_hunter_profile(player_id)

	if profile.is_empty():
		return _failure("PLAYER_NOT_REGISTERED")

	if profile.get("membership_status", "") != "candidate":
		return _failure("EXAM_APPLICATION_REQUIRED")

	var linked_cohort := cohort_id.strip_edges()

	if not linked_cohort.is_empty():
		if XSXCohorts.get_cohort_status(linked_cohort) != "active":
			return _failure("COHORT_NOT_ACTIVE")

		if not XSXCohorts.is_active_contestant(
			linked_cohort,
			player_id
		):
			return _failure("PLAYER_NOT_ACTIVE_IN_COHORT")

	if exam_sessions.has(player_id):
		var old_session: Dictionary = exam_sessions[player_id]

		if not bool(old_session.get("finished", false)):
			return _failure("EXAM_ALREADY_ACTIVE")

	var exam_id := _generate_exam_id()

	var session := {
		"exam_id": exam_id,
		"player_id": player_id,
		"cohort_id": linked_cohort,
		"current_stage": 0,
		"total_score": 0,
		"stage_results": [],
		"finished": false,
		"passed": false,
		"result_submitted": false,
		"review_required": false,
		"started_at": Time.get_datetime_string_from_system(),
		"finished_at": ""
	}

	exam_sessions[player_id] = session

	save_data()
	exam_started.emit(player_id, exam_id)
	_begin_current_stage(player_id)

	return {
		"success": true,
		"exam_id": exam_id,
		"cohort_id": linked_cohort,
		"total_stages": EXAM_STAGES.size(),
		"first_stage": get_current_stage(player_id)
	}


func _generate_exam_id() -> String:
	return "XSX-EXAM-%08d" % randi_range(10000000, 99999999)


func get_player_exam_cohort(player_id: String) -> String:
	if not exam_sessions.has(player_id):
		return ""

	return str(exam_sessions[player_id].get("cohort_id", ""))


# ==================================================
# CURRENT STAGE
# ==================================================

func get_current_stage(player_id: String) -> Dictionary:
	if not exam_sessions.has(player_id):
		return {}

	var session: Dictionary = exam_sessions[player_id]

	if bool(session.get("finished", false)):
		return {}

	var index := int(session.get("current_stage", 0))

	if index < 0 or index >= EXAM_STAGES.size():
		return {}

	var stage: Dictionary = EXAM_STAGES[index].duplicate(true)
	stage["stage_number"] = index + 1
	stage["total_stages"] = EXAM_STAGES.size()

	var examiner_id := str(stage.get("examiner_id", ""))

	stage["examiner"] = AI_EXAMINERS.get(
		examiner_id,
		{}
	).duplicate(true)

	return stage


func _begin_current_stage(player_id: String) -> void:
	var stage := get_current_stage(player_id)

	if stage.is_empty():
		return

	stage_started.emit(
		player_id,
		str(stage["id"]),
		int(stage["stage_number"])
	)


func get_exam_progress(player_id: String) -> Dictionary:
	if not exam_sessions.has(player_id):
		return {}

	var session: Dictionary = exam_sessions[player_id]
	var results: Array = session.get("stage_results", [])

	return {
		"completed_stages": results.size(),
		"total_stages": EXAM_STAGES.size(),
		"current_stage": int(session.get("current_stage", 0)) + 1,
		"finished": bool(session.get("finished", false)),
		"average_score": _calculate_average(session),
		"review_required": bool(session.get("review_required", false)),
		"cohort_id": str(session.get("cohort_id", ""))
	}


# ==================================================
# SUBMIT STAGE EVIDENCE
# ==================================================

# Prototype evidence:
# completion, precision, decision, survival: 0-100
# integrity_ok: optional boolean
#
# Production evidence must be validated by a trusted server.

func submit_stage_evidence(
	player_id: String,
	stage_id: String,
	evidence: Dictionary
) -> Dictionary:

	if not exam_sessions.has(player_id):
		return _failure("NO_ACTIVE_EXAM")

	var session: Dictionary = exam_sessions[player_id]

	if bool(session.get("finished", false)):
		return _failure("EXAM_ALREADY_FINISHED")

	if bool(session.get("review_required", false)):
		return _failure("EXAM_REQUIRES_REVIEW")

	var cohort_id := str(session.get("cohort_id", ""))

	if not cohort_id.is_empty():
		if XSXCohorts.get_cohort_status(cohort_id) != "active":
			return _failure("COHORT_NOT_ACTIVE")

		if not XSXCohorts.is_active_contestant(cohort_id, player_id):
			return _failure("PLAYER_NOT_ACTIVE_IN_COHORT")

	var stage := get_current_stage(player_id)

	if stage.is_empty():
		return _failure("INVALID_STAGE")

	if str(stage.get("id", "")) != stage_id:
		return _failure("WRONG_STAGE")

	var evaluation := _evaluate_evidence(stage, evidence)

	if not bool(evaluation.get("valid", false)):
		return _failure(str(evaluation.get("reason", "INVALID_EVIDENCE")))

	if bool(evaluation.get("review_required", false)):
		session["review_required"] = true
		exam_sessions[player_id] = session
		save_data()

		exam_review_required.emit(
			player_id,
			str(evaluation.get("reason", "EVIDENCE_REVIEW"))
		)

		return {
			"success": false,
			"review_required": true,
			"reason": evaluation.get("reason", "")
		}

	var score := int(evaluation.get("score", 0))

	var result := {
		"stage_id": stage_id,
		"stage_name": stage.get("name", ""),
		"examiner_id": stage.get("examiner_id", ""),
		"score": score,
		"passed": score >= MIN_STAGE_SCORE,
		"evaluated_at": Time.get_datetime_string_from_system()
	}

	var results: Array = session.get("stage_results", [])
	results.append(result)

	session["stage_results"] = results
	session["total_score"] = int(session.get("total_score", 0)) + score
	session["current_stage"] = int(session.get("current_stage", 0)) + 1

	exam_sessions[player_id] = session
	save_data()

	stage_completed.emit(player_id, stage_id, score)

	if int(session["current_stage"]) >= EXAM_STAGES.size():
		return _finish_exam(player_id)

	_begin_current_stage(player_id)

	return {
		"success": true,
		"stage_completed": true,
		"stage_score": score,
		"next_stage": get_current_stage(player_id)
	}


# ==================================================
# AI EVALUATION
# ==================================================

func _evaluate_evidence(
	stage: Dictionary,
	evidence: Dictionary
) -> Dictionary:

	if evidence.is_empty():
		return {
			"valid": false,
			"reason": "EMPTY_EVIDENCE"
		}

	if evidence.has("integrity_ok"):
		if not bool(evidence["integrity_ok"]):
			return {
				"valid": true,
				"review_required": true,
				"reason": "INTEGRITY_CHECK_FAILED"
			}

	var required_metrics := [
		"completion",
		"precision",
		"decision",
		"survival"
	]

	var metrics := {}

	for metric in required_metrics:
		if not evidence.has(metric):
			return {
				"valid": false,
				"reason": "MISSING_METRIC_" + str(metric)
			}

		var value = evidence[metric]

		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return {
				"valid": false,
				"reason": "INVALID_METRIC_" + str(metric)
			}

		metrics[metric] = clampf(float(value), 0.0, 100.0)

	var weights: Dictionary = stage.get("weights", {})
	var total := 0.0
	var weight_total := 0.0

	for metric in required_metrics:
		var weight := float(weights.get(metric, 0.0))
		total += float(metrics[metric]) * weight
		weight_total += weight

	if weight_total <= 0.0:
		return {
			"valid": false,
			"reason": "INVALID_STAGE_WEIGHTS"
		}

	var final_score := roundi(total / weight_total)

	return {
		"valid": true,
		"review_required": false,
		"score": clampi(final_score, 0, 100),
		"metrics": metrics
	}


# ==================================================
# FINISH EXAM
# ==================================================

func _finish_exam(player_id: String) -> Dictionary:
	if not exam_sessions.has(player_id):
		return _failure("NO_ACTIVE_EXAM")

	var session: Dictionary = exam_sessions[player_id]
	var results: Array = session.get("stage_results", [])

	if results.size() != EXAM_STAGES.size():
		return _failure("EXAM_STAGES_INCOMPLETE")

	var final_score := _calculate_average(session)
	var all_stages_passed := true

	for result in results:
		if not bool(result.get("passed", false)):
			all_stages_passed = false
			break

	var passed := final_score >= PASS_SCORE and all_stages_passed

	session["finished"] = true
	session["passed"] = passed
	session["final_score"] = final_score
	session["finished_at"] = Time.get_datetime_string_from_system()

	exam_sessions[player_id] = session
	save_data()

	var authority_result: Dictionary = (
		XSXAssociation.process_examination_result(
			player_id,
			str(session.get("exam_id", "")),
			passed,
			final_score
		)
	)

	if bool(authority_result.get("success", false)):
		session["result_submitted"] = true
	else:
		session["authority_error"] = authority_result.get(
			"reason",
			"AUTHORITY_REJECTED_RESULT"
		)

	exam_sessions[player_id] = session
	save_data()

	exam_completed.emit(player_id, passed, final_score)

	return {
		"success": true,
		"passed": passed,
		"final_score": final_score,
		"minimum_score": PASS_SCORE,
		"all_stages_passed": all_stages_passed,
		"cohort_id": str(session.get("cohort_id", "")),
		"authority_result": authority_result,
		"license_granted": bool(authority_result.get("passed", false))
	}


func _calculate_average(session: Dictionary) -> int:
	var results: Array = session.get("stage_results", [])

	if results.is_empty():
		return 0

	var total := 0

	for result in results:
		total += int(result.get("score", 0))

	return roundi(float(total) / float(results.size()))


# ==================================================
# REVIEW SYSTEM
# ==================================================

func resolve_exam_review(
	player_id: String,
	approved: bool,
	reviewer_note: String = ""
) -> Dictionary:

	if not exam_sessions.has(player_id):
		return _failure("NO_EXAM_SESSION")

	var session: Dictionary = exam_sessions[player_id]

	if not bool(session.get("review_required", false)):
		return _failure("NO_PENDING_REVIEW")

	session["review_required"] = false
	session["review_note"] = reviewer_note
	session["review_approved"] = approved

	if not approved:
		session["finished"] = true
		session["passed"] = false
		session["finished_at"] = Time.get_datetime_string_from_system()

	exam_sessions[player_id] = session
	save_data()

	if approved:
		return {
			"success": true,
			"review_approved": true,
			"message": "يمكن إعادة إرسال أدلة المرحلة للمراجعة"
		}

	return {
		"success": true,
		"review_approved": false,
		"exam_failed": true
	}


# ==================================================
# EXAM SUMMARY
# ==================================================

func get_exam_summary(player_id: String) -> Dictionary:
	if not exam_sessions.has(player_id):
		return {}

	var session: Dictionary = exam_sessions[player_id]

	return {
		"exam_id": session.get("exam_id", ""),
		"player_id": player_id,
		"cohort_id": session.get("cohort_id", ""),
		"finished": session.get("finished", false),
		"passed": session.get("passed", false),
		"final_score": session.get("final_score", 0),
		"stage_results": session.get("stage_results", []).duplicate(true),
		"started_at": session.get("started_at", ""),
		"finished_at": session.get("finished_at", ""),
		"result_submitted": session.get("result_submitted", false)
	}


# ==================================================
# CANCEL EXAM
# ==================================================

func cancel_exam(player_id: String) -> Dictionary:
	if not exam_sessions.has(player_id):
		return _failure("NO_ACTIVE_EXAM")

	var session: Dictionary = exam_sessions[player_id]

	if bool(session.get("finished", false)):
		return _failure("EXAM_ALREADY_FINISHED")

	session["finished"] = true
	session["cancelled"] = true
	session["finished_at"] = Time.get_datetime_string_from_system()

	exam_sessions[player_id] = session
	save_data()

	return {
		"success": true,
		"cancelled": true
	}


# ==================================================
# PERSISTENCE
# ==================================================

func save_data() -> bool:
	var payload := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"exam_sessions": exam_sessions
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("XSX Exam: Could not open save file.")
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	return true


func load_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		exam_sessions = {}
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("XSX Exam: Could not read save file.")
		return false

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("XSX Exam: Invalid save data.")
		return false

	var version := int(parsed.get("save_version", -1))

	if version < 1 or version > SAVE_VERSION:
		push_warning("XSX Exam: Save version is incompatible.")
		return false

	var saved_sessions = parsed.get("exam_sessions", {})

	if typeof(saved_sessions) != TYPE_DICTIONARY:
		return false

	exam_sessions = saved_sessions.duplicate(true)

	# Migrate old sessions created before cohort support.
	for player_id in exam_sessions.keys():
		var session: Dictionary = exam_sessions[player_id]

		if not session.has("cohort_id"):
			session["cohort_id"] = ""

		exam_sessions[player_id] = session

	return true


# ==================================================
# UTILITIES
# ==================================================

func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason
	}


func get_active_exam_count() -> int:
	var count := 0

	for player_id in exam_sessions.keys():
		var session: Dictionary = exam_sessions[player_id]

		if not bool(session.get("finished", false)):
			count += 1

	return count
