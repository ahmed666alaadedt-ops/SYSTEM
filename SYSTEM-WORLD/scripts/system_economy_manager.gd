extends Node
class_name SYSTEMEconomyManager

signal company_registered(company: Dictionary)
signal economy_changed(balance: int)

const SAVE_PATH := "user://system_business_registry.cfg"
const COMPANY_REGISTRATION_FEE := 1000
const MAX_LOCAL_COMPANIES := 5
const VALID_SECTORS := ["تجارة", "تقنية", "خدمات", "ضيافة", "نقل", "صناعة"]

var wallet_manager: Node
var companies: Array[Dictionary] = []
var transaction_ledger: Array[Dictionary] = []
var next_company_number := 1


func setup(p_wallet_manager: Node) -> void:
	wallet_manager = p_wallet_manager
	_load_registry()


func get_balance() -> int:
	if not is_instance_valid(wallet_manager) or not wallet_manager.has_method("get_balance"):
		return 0
	return int(wallet_manager.call("get_balance"))


func get_company_catalog() -> Array[String]:
	return VALID_SECTORS.duplicate()


func get_companies() -> Array[Dictionary]:
	return companies.duplicate(true)


func get_recent_transactions(limit: int = 10) -> Array[Dictionary]:
	var start_index := maxi(0, transaction_ledger.size() - clampi(limit, 1, 50))
	return transaction_ledger.slice(start_index).duplicate(true)


func register_company(company_name: String, sector: String) -> Dictionary:
	var normalized_name := company_name.strip_edges()
	if normalized_name.length() < 3 or normalized_name.length() > 32:
		return {"success": false, "reason": "COMPANY_NAME_LENGTH"}
	if not VALID_SECTORS.has(sector):
		return {"success": false, "reason": "INVALID_BUSINESS_SECTOR"}
	if companies.size() >= MAX_LOCAL_COMPANIES:
		return {"success": false, "reason": "LOCAL_COMPANY_LIMIT_REACHED"}
	for company in companies:
		if str(company.get("name", "")).to_lower() == normalized_name.to_lower():
			return {"success": false, "reason": "COMPANY_NAME_ALREADY_REGISTERED"}
	if not is_instance_valid(wallet_manager) or not wallet_manager.has_method("spend_currency"):
		return {"success": false, "reason": "WALLET_UNAVAILABLE"}
	var payment: Dictionary = wallet_manager.call("spend_currency", COMPANY_REGISTRATION_FEE, "business_company_registration")
	if not bool(payment.get("success", false)):
		return {"success": false, "reason": "INSUFFICIENT_CURRENCY", "balance": get_balance(), "required": COMPANY_REGISTRATION_FEE}
	var company := {
		"id": "local_company_%04d" % next_company_number,
		"name": normalized_name,
		"sector": sector,
		"status": "registered_local_prototype",
		"registered_at": int(Time.get_unix_time_from_system()),
		"owner": "local_player"
	}
	next_company_number += 1
	companies.append(company)
	_record_transaction("company_registration", -COMPANY_REGISTRATION_FEE, company["id"], normalized_name)
	_save_registry()
	company_registered.emit(company.duplicate(true))
	economy_changed.emit(get_balance())
	return {"success": true, "company": company.duplicate(true), "balance": get_balance(), "fee": COMPANY_REGISTRATION_FEE, "save_mode": "local_device_only"}


func get_economy_status() -> Dictionary:
	return {
		"balance": get_balance(),
		"companies": get_companies(),
		"company_limit": MAX_LOCAL_COMPANIES,
		"registration_fee": COMPANY_REGISTRATION_FEE,
		"save_mode": "local_device_only",
		"investment_market_enabled": false
	}


func _record_transaction(transaction_type: String, amount: int, reference_id: String, description: String) -> void:
	transaction_ledger.append({
		"type": transaction_type,
		"amount": amount,
		"reference_id": reference_id,
		"description": description,
		"balance_after": get_balance(),
		"timestamp": int(Time.get_unix_time_from_system())
	})
	while transaction_ledger.size() > 100:
		transaction_ledger.pop_front()


func _save_registry() -> void:
	var config := ConfigFile.new()
	config.set_value("registry", "companies", companies)
	config.set_value("registry", "next_company_number", next_company_number)
	config.set_value("ledger", "transactions", transaction_ledger)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SYSTEM Economy: could not save local business registry.")


func _load_registry() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved_companies: Variant = config.get_value("registry", "companies", [])
	if saved_companies is Array:
		companies.clear()
		for entry in saved_companies:
			if entry is Dictionary and str(entry.get("id", "")).begins_with("local_company_"):
				companies.append(entry.duplicate(true))
	next_company_number = maxi(1, int(config.get_value("registry", "next_company_number", companies.size() + 1)))
	var saved_ledger: Variant = config.get_value("ledger", "transactions", [])
	transaction_ledger.clear()
	if saved_ledger is Array:
		for entry in saved_ledger:
			if entry is Dictionary:
				transaction_ledger.append(entry.duplicate(true))
