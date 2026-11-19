extends Node

## Central inter-world transit. All entry gates are created in Baghdad.
## Greed Island has one exit gate that returns the player to the modern-world hub.

const FANTASY_ID := 0
const HISTORICAL_ID := 1
const MODERN_ID := 2
const GREED_ISLAND_ID := 3

const BAGHDAD_GATE_DATA := [
	{"id": FANTASY_ID, "name": "FantasyStarGate", "title": "بوابة عالم الخيال", "theme": "fantasy", "offset": Vector3(-7.0, 0.0, -12.0)},
	{"id": HISTORICAL_ID, "name": "HistoricalStarGate", "title": "بوابة العالم التاريخي والحضارات", "theme": "historical", "offset": Vector3(0.0, 0.0, -12.0)},
	{"id": GREED_ISLAND_ID, "name": "GreedIslandSeasonalStarGate", "title": "بوابة جزيرة الطمع الموسمية", "theme": "greed", "offset": Vector3(7.0, 0.0, -12.0)}
]

var world_manager: Node
var transition_locked := false
var greed_island_season_open := false
var gates_created := false


func _process(_delta: float) -> void:
	if gates_created:
		return
	world_manager = get_tree().root.find_child("WorldManager", true, false)
	if world_manager == null:
		return
	var roots := _get_world_roots()
	if not roots.has(MODERN_ID) or not roots.has(GREED_ISLAND_ID):
		return
	var modern_root := roots[MODERN_ID] as Node3D
	var island_root := roots[GREED_ISLAND_ID] as Node3D
	if modern_root == null or island_root == null:
		return
	if not _create_baghdad_gate_hub(modern_root):
		return
	_create_island_return_gate(island_root)
	gates_created = true
	print("SYSTEM: Baghdad-only star gate hub initialized.")


func _get_world_roots() -> Dictionary:
	if world_manager == null:
		return {}
	var value: Variant = world_manager.get("world_roots")
	return value if value is Dictionary else {}


func _get_baghdad_position(modern_root: Node3D) -> Vector3:
	var region := modern_root.get_node_or_null("ModernWorldRegionManager")
	if region == null:
		push_warning("SYSTEM: Baghdad gate hub waits for ModernWorldRegionManager.")
		return Vector3.INF
	var anchors: Variant = region.get("city_anchors")
	if not anchors is Dictionary or not anchors.has("Baghdad"):
		push_warning("SYSTEM: Baghdad city anchor is not available; star gates were not placed.")
		return Vector3.INF
	var anchor: Vector2 = anchors["Baghdad"]
	var terrain := modern_root.get_node_or_null("ModernContinent")
	var height := 0.0
	if terrain != null and terrain.has_method("get_terrain_height"):
		height = float(terrain.call("get_terrain_height", anchor.x, anchor.y))
	return Vector3(anchor.x, height, anchor.y)


func _create_baghdad_gate_hub(modern_root: Node3D) -> bool:
	var baghdad := _get_baghdad_position(modern_root)
	if baghdad == Vector3.INF:
		return false
	var hub := modern_root.get_node_or_null("BaghdadStarGateHub") as Node3D
	if hub == null:
		hub = Node3D.new()
		hub.name = "BaghdadStarGateHub"
		hub.position = baghdad
		modern_root.add_child(hub)
	for data in BAGHDAD_GATE_DATA:
		if hub.has_node(str(data["name"])):
			continue
		var gate := Node3D.new()
		gate.name = str(data["name"])
		gate.position = data["offset"]
		hub.add_child(gate)
		_build_gate_visual(gate, str(data["theme"]))
		_add_gate_trigger(gate, data)


func _build_gate_visual(parent: Node3D, theme: String) -> void:
	var frame_color := Color(0.08, 0.18, 0.25)
	var energy_color := Color(0.08, 0.78, 1.0)
	match theme:
		"fantasy":
			frame_color = Color(0.18, 0.22, 0.40)
			energy_color = Color(0.28, 0.48, 1.0)
		"historical":
			frame_color = Color(0.48, 0.32, 0.17)
			energy_color = Color(1.0, 0.58, 0.18)
		"greed":
			frame_color = Color(0.35, 0.22, 0.08)
			energy_color = Color(1.0, 0.78, 0.18)
	var frame := _make_material(frame_color, 0.35, 0.65)
	var energy := _make_glowing_material(energy_color)
	_add_box(parent, "GateLeftFrame", Vector3(-1.8, 2.5, 0.0), Vector3(0.35, 5.0, 0.65), frame)
	_add_box(parent, "GateRightFrame", Vector3(1.8, 2.5, 0.0), Vector3(0.35, 5.0, 0.65), frame)
	_add_box(parent, "GateUpperFrame", Vector3(0.0, 4.9, 0.0), Vector3(3.9, 0.35, 0.65), frame)
	_add_box(parent, "GateEnergyVeil", Vector3(0.0, 2.4, 0.18), Vector3(2.9, 3.9, 0.08), energy)


func _add_gate_trigger(parent: Node3D, data: Dictionary) -> void:
	var area := Area3D.new()
	area.name = "GateActivationArea"
	area.position = Vector3(0.0, 1.2, 1.8)
	area.set_meta("system_star_gate", true)
	area.set_meta("system_gate_title", str(data["title"]))
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.4
	collision.shape = sphere
	area.add_child(collision)
	parent.add_child(area)
	area.body_entered.connect(_on_baghdad_gate_entered.bind(int(data["id"])))


func _create_island_return_gate(island_root: Node3D) -> void:
	var island := island_root.get_node_or_null("GreedIslandEnvironment")
	if island == null:
		push_warning("SYSTEM: GreedIslandEnvironment is missing; island exit gate could not be created.")
		return
	if island.has_node("ReturnToBaghdadGate"):
		return
	var gate := Node3D.new()
	gate.name = "ReturnToBaghdadGate"
	gate.position = Vector3(0.0, 0.0, -35.0)
	island.add_child(gate)
	_build_gate_visual(gate, "modern")
	var data := {"title": "بوابة العودة إلى بغداد", "id": MODERN_ID}
	_add_gate_trigger(gate, data)


func set_greed_island_season_open(is_open: bool) -> void:
	greed_island_season_open = is_open


func _has_greed_island_seal() -> bool:
	var progression := get_tree().root.find_child("PlayerProgression", true, false)
	if progression == null or not progression.has_method("get_world_fragment_data"):
		return false
	var data: Dictionary = progression.call("get_world_fragment_data")
	return bool(data.get("all_world_keys_ready", false))


func _is_local_player(body: Node3D) -> bool:
	if not body is CharacterBody3D:
		return false
	return body.name == "Player" or body.is_in_group("system_player")


func _on_baghdad_gate_entered(body: Node3D, destination_id: int) -> void:
	if transition_locked or not _is_local_player(body):
		return
	if destination_id == GREED_ISLAND_ID:
		if not greed_island_season_open:
			print("SYSTEM: Greed Island season is currently closed.")
			return
		if not _has_greed_island_seal():
			print("SYSTEM: Complete the three main-world keys before entering Greed Island.")
			return
	var roots := _get_world_roots()
	if not roots.has(destination_id):
		push_warning("SYSTEM: Star gate destination is unavailable.")
		return
	_transition_to_world(destination_id)


func _transition_to_world(destination_id: int) -> void:
	if transition_locked or world_manager == null:
		return
	transition_locked = true
	world_manager.call("switch_world", destination_id)
	await get_tree().create_timer(0.8).timeout
	transition_locked = false


func _make_material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_glowing_material(color: Color) -> StandardMaterial3D:
	var material := _make_material(color, 0.25, 0.2)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	return material


func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	parent.add_child(visual)
