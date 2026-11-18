extends Node

# SYSTEM WORLD - Monster Gate Manager
# Godot 4.3

signal gate_spawned(data: Dictionary)
signal gate_rank_changed(data: Dictionary)
signal gate_became_unstable(data: Dictionary)
signal gate_breached(data: Dictionary)
signal gate_contained(data: Dictionary)
signal gate_collapsed(data: Dictionary)

const RANKS := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "EX"]
const RANK_COLORS := {
	"F": Color(0.35, 0.75, 1.0), "E": Color(0.25, 0.9, 0.55),
	"D": Color(0.1, 0.8, 0.85), "C": Color(0.55, 0.35, 1.0),
	"B": Color(1.0, 0.25, 0.2), "A": Color(1.0, 0.65, 0.15),
	"S": Color(1.0, 0.85, 0.2), "SS": Color(0.9, 0.15, 0.45),
	"SSS": Color(0.65, 0.1, 0.95), "EX": Color(0.95, 0.95, 1.0)
}

const STABLE_TIME := 900.0
const UNSTABLE_TIME := 180.0
const BREACH_TIME := 90.0
const MAX_ACTIVE_GATES := 8
const MIN_GATE_DISTANCE := 14.0

var world_root: Node3D
var active_gates: Array[Dictionary] = []
var automatic_spawning := true
var spawn_radius := 55.0
var spawn_timer := 0.0
var next_spawn_time := 240.0
var gate_counter := 0
var initialized := false


func setup(world: Node3D, radius: float = 55.0) -> void:
	if initialized:
		return
	world_root = world
	spawn_radius = radius
	randomize()
	next_spawn_time = randf_range(180.0, 360.0)
	initialized = true
	print("SYSTEM: Monster Gate Manager initialized.")


func update_world(delta: float) -> void:
	if not initialized or not is_instance_valid(world_root):
		return
	_update_gate_timers(delta)
	_animate_gate_visuals(delta)
	_update_spawn_timer(delta)


func _update_spawn_timer(delta: float) -> void:
	if not automatic_spawning:
		return
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:
		spawn_timer = 0.0
		next_spawn_time = randf_range(180.0, 360.0)
		if active_gates.size() >= MAX_ACTIVE_GATES:
			return
		var location := _choose_spawn_location()
		if not location.is_empty():
			spawn_gate_at(
				location["position"],
				str(location["region"]),
				"",
				str(location["biome"])
			)


func spawn_gate_at(
	position: Vector3,
	region_name: String = "Unknown Region",
	forced_rank: String = "",
	biome: String = "urban"
) -> Dictionary:
	if not initialized or not is_instance_valid(world_root):
		return {}
	if active_gates.size() >= MAX_ACTIVE_GATES:
		return {}
	if not _is_gate_position_available(position):
		return {}
	gate_counter += 1
	var gate_id := "MG-%06d" % gate_counter
	var actual_rank := forced_rank if RANKS.has(forced_rank) else _generate_random_rank()
	var displayed_rank := actual_rank
	var deceptive := false
	if randf() < 0.12:
		deceptive = true
		var rank_index := RANKS.find(actual_rank)
		if rank_index > 0:
			displayed_rank = RANKS[rank_index - 1]

	var gate_data := {
		"id": gate_id, "region": region_name, "biome": biome,
		"position": position, "actual_rank": actual_rank,
		"displayed_rank": displayed_rank,
		"deceptive": deceptive, "monster_count": _generate_monster_count(actual_rank),
		"boss_count": _generate_boss_count(actual_rank), "status": "stable",
		"time_remaining": STABLE_TIME, "created_at": Time.get_unix_time_from_system(),
		"scan_count": 0, "pulse_time": 0.0
	}
	gate_data["visual"] = _create_gate_visual(gate_data)
	active_gates.append(gate_data)
	gate_spawned.emit(_public_data(gate_data))
	print("SYSTEM: Gate discovered ", gate_id, " | ", displayed_rank)
	return _public_data(gate_data)


func _choose_spawn_location() -> Dictionary:
	# Keep automatic gates outside the prototype town centre.
	for attempt in range(10):
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(maxf(22.0, spawn_radius * 0.42), spawn_radius)
		var position := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		if not _is_gate_position_available(position):
			continue
		var biome := "urban" if distance < 31.0 else "forest"
		var region := "Outer District" if biome == "urban" else "Forest Border"
		return {"position": position, "biome": biome, "region": region}
	return {}


func _is_gate_position_available(position: Vector3) -> bool:
	for gate in active_gates:
		var existing: Vector3 = gate.get("position", Vector3.ZERO)
		if existing.distance_to(position) < MIN_GATE_DISTANCE:
			return false
	return true


func _animate_gate_visuals(delta: float) -> void:
	for data in active_gates:
		data["pulse_time"] = float(data.get("pulse_time", 0.0)) + delta
		var visual = data.get("visual")
		if not is_instance_valid(visual):
			continue
		var ring = visual.get_node_or_null("GateRing")
		var core = visual.get_node_or_null("GateCore")
		if ring != null:
			ring.rotation.z += delta * 0.22
		if core != null:
			var pulse := 1.0 + sin(float(data["pulse_time"]) * 2.2) * 0.055
			core.scale = Vector3.ONE * pulse
		var label = visual.get_node_or_null("GateRankLabel")
		if label != null:
			var seconds := int(maxf(0.0, float(data.get("time_remaining", 0.0))))
			label.text = "SYSTEM GATE\n%s | %s\n%02d:%02d" % [
				str(data.get("displayed_rank", "F")),
				str(data.get("status", "stable")).to_upper(),
				floori(float(seconds) / 60.0),
				seconds % 60
			]


func _generate_random_rank() -> String:
	var roll := randf()
	if roll < 0.35: return "F"
	if roll < 0.60: return "E"
	if roll < 0.78: return "D"
	if roll < 0.88: return "C"
	if roll < 0.94: return "B"
	if roll < 0.975: return "A"
	if roll < 0.990: return "S"
	if roll < 0.997: return "SS"
	if roll < 0.999: return "SSS"
	return "EX"


func _generate_monster_count(rank: String) -> int:
	match rank:
		"F": return randi_range(3, 8)
		"E": return randi_range(6, 14)
		"D": return randi_range(10, 22)
		"C": return randi_range(15, 35)
		"B": return randi_range(25, 55)
		"A": return randi_range(35, 80)
		"S": return randi_range(50, 120)
		"SS": return randi_range(80, 180)
		"SSS": return randi_range(120, 250)
		"EX": return randi_range(150, 400)
	return 5


func _generate_boss_count(rank: String) -> int:
	match rank:
		"F", "E": return 0
		"D", "C": return 1
		"B", "A": return randi_range(1, 2)
		"S", "SS": return randi_range(2, 4)
		"SSS", "EX": return randi_range(3, 6)
	return 0


func _create_gate_visual(data: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(data["id"])
	root.position = data["position"]

	var ring := MeshInstance3D.new()
	ring.name = "GateRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.15
	torus.outer_radius = 1.4
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = _gate_material(str(data["displayed_rank"]))
	root.add_child(ring)

	var core := MeshInstance3D.new()
	core.name = "GateCore"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.95
	core_mesh.height = 1.9
	core.mesh = core_mesh
	core.position.y = 0.0
	var core_material := _gate_material(str(data["displayed_rank"]))
	core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_material.albedo_color.a = 0.48
	core.material_override = core_material
	root.add_child(core)

	var label := Label3D.new()
	label.name = "GateRankLabel"
	label.text = "SYSTEM GATE\n" + str(data["displayed_rank"])
	label.position.y = 2.5
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

	world_root.add_child(root)
	return root


func _gate_material(rank: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = RANK_COLORS.get(rank, Color.WHITE)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 2.5
	return material


func scan_gate(gate_id: String) -> Dictionary:
	var index := _find_gate_index(gate_id)
	if index == -1:
		return {}
	var data: Dictionary = active_gates[index]
	data["scan_count"] = int(data["scan_count"]) + 1
	var revealed_rank := str(data["displayed_rank"])
	var success := true
	if bool(data["deceptive"]):
		success = randf() >= 0.25
		if success:
			revealed_rank = str(data["actual_rank"])
	var result := _public_data(data)
	result["scan_success"] = success
	result["scanned_rank"] = revealed_rank
	result["real_rank_revealed"] = success and bool(data["deceptive"])
	return result


func _update_gate_timers(delta: float) -> void:
	for index in range(active_gates.size() - 1, -1, -1):
		var data: Dictionary = active_gates[index]
		data["time_remaining"] = maxf(0.0, float(data["time_remaining"]) - delta)
		var remaining := float(data["time_remaining"])
		var status := str(data["status"])
		if status == "stable" and remaining <= UNSTABLE_TIME:
			data["status"] = "unstable"
			gate_became_unstable.emit(_public_data(data))
		elif status == "unstable" and remaining <= 0.0:
			data["status"] = "breached"
			data["time_remaining"] = BREACH_TIME
			gate_breached.emit(_public_data(data))
			print("SYSTEM ALERT: Gate breach ", data["id"])
		elif status == "breached" and remaining <= 0.0:
			_remove_gate(index)


func evolve_gate(gate_id: String, new_rank: String) -> bool:
	if not RANKS.has(new_rank):
		return false
	var index := _find_gate_index(gate_id)
	if index == -1:
		return false
	var data: Dictionary = active_gates[index]
	if str(data["status"]) == "breached":
		return false
	if RANKS.find(new_rank) <= RANKS.find(str(data["actual_rank"])):
		return false
	data["actual_rank"] = new_rank
	data["displayed_rank"] = new_rank
	data["deceptive"] = false
	data["monster_count"] = _generate_monster_count(new_rank)
	data["boss_count"] = _generate_boss_count(new_rank)
	_refresh_gate_visual(data)
	gate_rank_changed.emit(_public_data(data))
	return true


func _refresh_gate_visual(data: Dictionary) -> void:
	var visual = data.get("visual")
	if not is_instance_valid(visual):
		return
	var ring = visual.get_node_or_null("GateRing")
	if ring != null:
		ring.material_override = _gate_material(str(data["displayed_rank"]))
	var core = visual.get_node_or_null("GateCore")
	if core != null:
		var core_material := _gate_material(str(data["displayed_rank"]))
		core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		core_material.albedo_color.a = 0.48
		core.material_override = core_material
	var label = visual.get_node_or_null("GateRankLabel")
	if label != null:
		label.text = "SYSTEM GATE\n" + str(data["displayed_rank"])


func contain_gate(gate_id: String) -> bool:
	var index := _find_gate_index(gate_id)
	if index == -1:
		return false
	var data: Dictionary = active_gates[index]
	data["status"] = "contained"
	gate_contained.emit(_public_data(data))
	var visual = data.get("visual")
	if is_instance_valid(visual):
		visual.queue_free()
	active_gates.remove_at(index)
	return true


func _remove_gate(index: int) -> void:
	var data: Dictionary = active_gates[index]
	data["status"] = "collapsed"
	gate_collapsed.emit(_public_data(data))
	var visual = data.get("visual")
	if is_instance_valid(visual):
		visual.queue_free()
	active_gates.remove_at(index)


func get_gate_information(gate_id: String) -> Dictionary:
	var index := _find_gate_index(gate_id)
	if index == -1:
		return {}
	return _public_data(active_gates[index])


func get_active_gates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in active_gates:
		result.append(_public_data(data))
	return result


func get_active_gate_count() -> int:
	return active_gates.size()


func _find_gate_index(gate_id: String) -> int:
	for index in range(active_gates.size()):
		if str(active_gates[index]["id"]) == gate_id:
			return index
	return -1


func _public_data(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result.erase("visual")
	result.erase("actual_rank")
	result.erase("deceptive")
	return result
