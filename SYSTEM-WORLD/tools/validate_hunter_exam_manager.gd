extends SceneTree

const EXAM_SCRIPT = preload("res://scripts/system_hunter_exam_manager.gd")

func _initialize() -> void:
	var manager = EXAM_SCRIPT.new()
	var validation_save_path := "user://hunter_exam_validator_%d.cfg" % int(Time.get_unix_time_from_system())
	manager.save_path = validation_save_path
	root.add_child(manager)
	if EXAM_SCRIPT.EXAM_STAGES.size() != 7:
		push_error("Hunter exam validation failed: expected exactly seven stages.")
		quit(1)
		return
	var required_types := [
		"endurance_tracking",
		"fieldcraft_cooking",
		"puzzles_and_decisions",
		"island_survival",
		"strategy_deception_negotiation",
		"individual_duels",
		"secret_final_trial"
	]
	for index in range(required_types.size()):
		var stage: Dictionary = EXAM_SCRIPT.EXAM_STAGES[index]
		if str(stage.get("type", "")) != required_types[index] or str(stage.get("id", "")).is_empty():
			push_error("Hunter exam validation failed: stage order or identity mismatch at " + str(index + 1))
			quit(1)
			return
		if stage.get("objectives", []).size() < 2:
			push_error("Hunter exam validation failed: stage has no meaningful objectives.")
			quit(1)
			return

	var registration: Dictionary = manager.apply_for_exam("validator_candidate")
	if not bool(registration.get("success", false)):
		push_error("Hunter exam validation failed: could not register a fresh candidate: " + str(registration))
		quit(1)
		return
	var start: Dictionary = manager.begin_exam()
	if not bool(start.get("success", false)):
		push_error("Hunter exam validation failed: candidate could not begin.")
		quit(1)
		return

	var first_stage: Dictionary = manager.get_current_stage()
	var forged_prefix: Dictionary = manager.complete_current_stage(
		str(first_stage.get("id", "")),
		"SYSTEM_VERIFIED:forged-by-client"
	)
	if str(forged_prefix.get("reason", "")) != "LEGACY_UNTRUSTED_EVIDENCE":
		push_error("Hunter exam validation failed: a forged legacy prefix was not rejected.")
		quit(1)
		return
	if manager.completed_stage_ids.size() != 0:
		push_error("Hunter exam validation failed: forged evidence changed progression.")
		quit(1)
		return

	var no_verifier: Dictionary = manager.complete_current_stage(
		str(first_stage.get("id", "")),
		{"issuer":"SYSTEM_TEST_VALIDATOR","token":"test"}
	)
	if str(no_verifier.get("reason", "")) != "TRUSTED_EVIDENCE_VERIFIER_UNAVAILABLE":
		push_error("Hunter exam validation failed: completion did not fail closed without a verifier.")
		quit(1)
		return

	# Test-only verifier: production runtime must be configured by a trusted backend.
	manager.configure_evidence_verifier(Callable(self, "_verify_test_evidence"))
	# Stage one now requires the three ordered route checkpoints before completion.
	var route_start: Dictionary = manager.reset_stage_one_route()
	if not bool(route_start.get("success", false)):
		push_error("Hunter exam validation failed: stage-one route could not be initialized: " + str(route_start))
		quit(1)
		return
	for checkpoint_id in ["checkpoint_01", "checkpoint_02", "checkpoint_03"]:
		var checkpoint_result: Dictionary = manager.record_stage_one_checkpoint(checkpoint_id)
		if not bool(checkpoint_result.get("success", false)):
			push_error("Hunter exam validation failed: ordered stage-one checkpoint was rejected: " + str(checkpoint_result))
			quit(1)
			return
	for stage_index in range(EXAM_SCRIPT.EXAM_STAGES.size()):
		var current: Dictionary = manager.get_current_stage()
		var expected: Dictionary = EXAM_SCRIPT.EXAM_STAGES[stage_index]
		if str(current.get("id", "")) != str(expected.get("id", "")):
			push_error("Hunter exam validation failed: progression skipped or repeated a stage.")
			quit(1)
			return
		var evidence := {
			"issuer":"SYSTEM_TEST_VALIDATOR",
			"token":"test:%s:%d" % [str(expected.get("id", "")), manager.candidate_number]
		}
		var completion: Dictionary = manager.complete_current_stage(str(expected.get("id", "")), evidence)
		if not bool(completion.get("success", false)):
			push_error("Hunter exam validation failed: verified stage completion rejected: " + str(completion))
			quit(1)
			return

	var overview: Dictionary = manager.get_exam_overview()
	if not bool(overview.get("license_earned_permanently", false)) or bool(overview.get("active", true)):
		push_error("Hunter exam validation failed: permanent license was not recorded after test verification.")
		quit(1)
		return

	var retry_probe = EXAM_SCRIPT.new()
	retry_probe.save_path = validation_save_path
	root.add_child(retry_probe)
	retry_probe.license_earned_permanently = false
	retry_probe.registered = true
	retry_probe.failed = true
	retry_probe.last_failure_unix = int(Time.get_unix_time_from_system())
	retry_probe.attempt_number = 1
	retry_probe.completed_stage_ids.clear()
	var retry_result: Dictionary = retry_probe.apply_for_exam("validator_retry_candidate")
	if str(retry_result.get("reason", "")) != "NEXT_WEEKLY_EXAM_REQUIRED":
		push_error("Hunter exam validation failed: weekly retry cycle was not enforced.")
		quit(1)
		return
	retry_probe.queue_free()
	manager.queue_free()
	print("Hunter exam validation passed: forged-prefix rejection, fail-closed verifier gate, seven-stage progression and permanent test license.")
	quit(0)


func _verify_test_evidence(evidence: Variant, stage_id: String, candidate_number: int) -> bool:
	if not evidence is Dictionary:
		return false
	if str(evidence.get("issuer", "")) != "SYSTEM_TEST_VALIDATOR":
		return false
	return str(evidence.get("token", "")) == "test:%s:%d" % [stage_id, candidate_number]
