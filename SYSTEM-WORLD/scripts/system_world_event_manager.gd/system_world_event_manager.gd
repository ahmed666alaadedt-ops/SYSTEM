
extends Node

## SYSTEM WORLD - Shared World Events
## Timed events for all four worlds.

signal event_started(world_id: int, data: Dictionary)
signal event_expired(world_id: int, event_id: String)
signal event_interacted(world_id: int, data: Dictionary)

const DEFAULT_DURATION := 900.0

const WORLD_EVENTS := {
	0: [
		{"id":"dragon_roost","title":"عش التنين القديم","description":"نشاط تنين نادر في جبال التنانين.","region":"dragon_mountains","position":Vector3(65,0,-45),"kind":"portal","color":Color(1,0.25,0.08),"duration":900.0},
		{"id":"leyline_rift","title":"شق خط الطاقة","description":"شق سحري يفتح ممراً إلى منطقة مجهولة.","region":"crystal_valley","position":Vector3(-35,0,75),"kind":"portal","color":Color(0.1,0.68,1),"duration":900.0},
		{"id":"cursed_grove","title":"الغابة الملعونة","description":"طاقة مظلمة تنتشر بين الأشجار القديمة.","region":"enchanted_forest","position":Vector3(-65,0,-30),"kind":"beacon","color":Color(0.62,0.2,0.92),"duration":900.0},
		{"id":"ancient_trial","title":"اختبار البرج القديم","description":"ختم قديم يفتح اختباراً نادراً.","region":"ancient_ruins","position":Vector3(45,0,65),"kind":"beacon","color":Color(1,0.72,0.2),"duration":900.0}
	],
	1: [
		{"id":"buried_tomb","title":"المقبرة الملكية المدفونة","description":"انكشف مدخل مقبرة قديمة تحت الرمال.","region":"babylon_mesopotamia","position":Vector3(0,0,70),"kind":"beacon","color":Color(0.92,0.62,0.22),"duration":900.0},
		{"id":"atlantis_echo","title":"صدى أتلانتس","description":"إشارات غامضة ظهرت قرب المدينة البحرية.","region":"atlantis_legend","position":Vector3(65,0,-65),"kind":"portal","color":Color(0.1,0.78,0.88),"duration":900.0},
		{"id":"oracle_trial","title":"اختبار العرّافة","description":"معبد قديم يدعو المستكشفين لحل لغز.","region":"ancient_wonders","position":Vector3(35,0,55),"kind":"beacon","color":Color(0.7,0.48,1),"duration":900.0},
		{"id":"lost_archive","title":"الأرشيف المفقود","description":"آثار تقود إلى قاعة سجلات منسية.","region":"lost_civilizations","position":Vector3(-35,0,65),"kind":"beacon","color":Color(0.95,0.78,0.36),"duration":900.0}
	],
	2: [
		{"id":"city_gate","title":"بوابة الوحوش - مركز المدينة","description":"بوابة نشطة ظهرت قرب مركز المدينة.","region":"modern_city_center","position":Vector3(0,0,-18),"kind":"portal","color":Color(1,0.08,0.06),"duration":900.0},
		{"id":"west_breach","title":"اختراق البوابة الغربية","description":"اضطراب مكاني يهدد المنطقة الغربية.","region":"modern_west_district","position":Vector3(-35,0,-65),"kind":"portal","color":Color(0.82,0.1,0.16),"duration":900.0},
		{"id":"desert_gate","title":"بوابة الصحراء","description":"بوابة جديدة على أطراف المنطقة الجنوبية.","region":"modern_southern_district","position":Vector3(38,0,-110),"kind":"portal","color":Color(1,0.42,0.08),"duration":900.0},
		{"id":"city_breach","title":"إنذار اقتحام المدينة","description":"إشارة خطر تستدعي استجابة الصيادين.","region":"modern_city_outskirts","position":Vector3(38,0,12),"kind":"portal","color":Color(1,0.12,0.04),"duration":900.0}
	],
	3: [
		{"id":"limited_treasure","title":"الكنز المحدود","description":"كنز نادر ظهر لفترة محدودة على الجزيرة.","region":"greed_treasure_beach","position":Vector3(12,0,-70),"kind":"beacon","color":Color(1,0.72,0.12),"duration":1200.0,"seasonal":true},
		{"id":"trial_arena","title":"تحدي ساحة الجزيرة","description":"تحدٍ موسمي اختياري في ساحة الاختبارات.","region":"royal_trials_region","position":Vector3(40,0,-42),"kind":"beacon","color":Color(0.92,0.48,0.12),"duration":1200.0,"seasonal":true},
		{"id":"floating_rift","title":"الشق العائم","description":"ممر غامض ظهر قرب الجزر الطائرة.","region":"floating_islands_region","position":Vector3(0,2,-112),"kind":"portal","color":Color(0.25,0.72,1),"duration":1200.0,"seasonal":true},
		{"id":"hidden_cavern","title":"سر المغارة البلورية","description":"إشارة تقود إلى مغارة مخفية.","region":"underground_wonders_region","position":Vector3(-42,0,-100),"kind":"portal","color":Color(0.15,0.92,0.86),"duration":1200.0,"seasonal":true}
	]
}


class EventMarker extends Area3D:
	var controller: Node
	var world_id: int
	var event_id: String

	func system_interact() -> void:
		if is_instance_valid(controller):
			controller.call("on_event_interacted", world_id, event_id)


var world_manager: Node
var world_roots: Dictionary = {}
var active_events: Dictionary = {}
var active_markers: Dictionary = {}
var event_indices: Dictionary = {}
var remaining_times: Dictionary = {}
var attached := false


func _ready() -> void:
	name = "SYSTEMWorldEvents"


func _process(delta: float) -> void:
	if not attached:
		_try_attach_to_worlds()
		return

	for key in remaining_times.keys():
		var world_id := int(key)
		var left := float(remaining_times.get(world_id, 0.0)) - delta

		if left <= 0.0:
			_activate_next_event(world_id)
		else:
			remaining_times[world_id] = left


func _try_attach_to_worlds() -> void:
	var candidate := get_tree().root.find_child(
		"WorldManager", true, false
	)

	if candidate == null:
		return

	var found_roots := {}

	for world_id in range(4):
		var world_root: Variant = candidate.call(
			"get_world_root", world_id
		)

		if world_root is Node3D:
			found_roots[world_id] = world_root

	if found_roots.size() != 4:
		return

	world_manager = candidate
	world_roots = found_roots
	attached = true

	for world_id in range(4):
		_activate_next_event(world_id)

	print("SYSTEM WORLD: Events connected to all four maps.")


func _activate_next_event(world_id: int) -> void:
	var events: Array = WORLD_EVENTS.get(world_id, [])

	if events.is_empty():
		return

	var previous: Dictionary = active_events.get(world_id, {})

	if not previous.is_empty():
		event_expired.emit(
			world_id, str(previous.get("id", ""))
		)

	var old_marker: Node = active_markers.get(world_id)

	if is_instance_valid(old_marker):
		old_marker.queue_free()

	var next_index := int(event_indices.get(world_id, -1)) + 1
	next_index %= events.size()
	event_indices[world_id] = next_index

	var data: Dictionary = events[next_index].duplicate(true)
	active_events[world_id] = data
	remaining_times[world_id] = float(
		data.get("duration", DEFAULT_DURATION)
	)

	var root: Node3D = world_roots[world_id]
	_spawn_event_marker(root, world_id, data)

	event_started.emit(world_id, data.duplicate(true))

	print(
		"SYSTEM EVENT: ",
		data.get("title", ""),
		" / WORLD ",
		world_id
	)


func _spawn_event_marker(
	root: Node3D,
	world_id: int,
	data: Dictionary
) -> void:
	var marker := EventMarker.new()
	marker.name = "Event_" + str(data.id)
	marker.controller = self
	marker.world_id = world_id
	marker.event_id = str(data.id)
	marker.position = data.position

	marker.collision_layer = 1
	marker.collision_mask = 1
	marker.monitoring = true
	marker.monitorable = true
	marker.add_to_group("system_interactable")
	marker.add_to_group("system_world_event")

	marker.set_meta("system_location_id", "event_" + str(data.id))
	marker.set_meta("system_region_id", str(data.region))
	marker.set_meta("system_display_name", str(data.title))
	marker.set_meta("system_location_type", 7)
	marker.set_meta("system_fast_travel", false)
	marker.set_meta(
		"system_interaction_prompt",
		"فحص الحدث: " + str(data.title)
	)
	marker.set_meta("system_event_id", str(data.id))
	marker.set_meta("system_event_world_id", world_id)
	marker.set_meta(
		"system_event_description",
		str(data.description)
	)
	marker.set_meta(
		"system_event_seasonal",
		bool(data.get("seasonal", false))
	)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 5.0
	collision.shape = shape
	collision.position = Vector3(0, 2.5, 0)
	marker.add_child(collision)

	_create_visual(marker, data)
	root.add_child(marker)
	active_markers[world_id] = marker


func _create_visual(parent: Node3D, data: Dictionary) -> void:
	var color: Color = data.get("color", Color.CYAN)
	var portal := str(data.get("kind", "")) == "portal"

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 2.4
	base_mesh.bottom_radius = 2.4
	base_mesh.height = 0.22
	base.mesh = base_mesh
	base.position.y = 0.12
	base.material_override = _make_material(color, false)
	parent.add_child(base)

	var glow := _make_material(color, true)

	if portal:
		var frame := _make_material(Color(0.2, 0.23, 0.3), false)

		for side in [-1.0, 1.0]:
			var pillar := MeshInstance3D.new()
			var pillar_mesh := CylinderMesh.new()
			pillar_mesh.top_radius = 0.3
			pillar_mesh.bottom_radius = 0.42
			pillar_mesh.height = 5.0
			pillar.mesh = pillar_mesh
			pillar.position = Vector3(side * 2.0, 2.5, 0)
			pillar.material_override = frame
			parent.add_child(pillar)

		var top := MeshInstance3D.new()
		var top_mesh := BoxMesh.new()
		top_mesh.size = Vector3(4.8, 0.55, 0.65)
		top.mesh = top_mesh
		top.position.y = 5.0
		top.material_override = frame
		parent.add_child(top)

		var core := MeshInstance3D.new()
		var core_mesh := SphereMesh.new()
		core_mesh.radius = 1.45
		core_mesh.height = 3.8
		core.mesh = core_mesh
		core.scale = Vector3(1.0, 1.0, 0.22)
		core.position.y = 2.8
		core.material_override = glow
		parent.add_child(core)
	else:
		var beacon := MeshInstance3D.new()
		var beacon_mesh := CylinderMesh.new()
		beacon_mesh.top_radius = 0.16
		beacon_mesh.bottom_radius = 0.32
		beacon_mesh.height = 5.0
		beacon.mesh = beacon_mesh
		beacon.position.y = 2.7
		beacon.material_override = glow
		parent.add_child(beacon)

		var orb := MeshInstance3D.new()
		var orb_mesh := SphereMesh.new()
		orb_mesh.radius = 0.85
		orb_mesh.height = 1.7
		orb.mesh = orb_mesh
		orb.position.y = 5.6
		orb.material_override = glow
		parent.add_child(orb)


func _make_material(color: Color, emissive: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.3

	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0

	return material


func on_event_interacted(world_id: int, event_id: String) -> void:
	var data: Dictionary = active_events.get(world_id, {})

	if data.is_empty() or str(data.get("id", "")) != event_id:
		return

	event_interacted.emit(world_id, data.duplicate(true))

	print(
		"SYSTEM EVENT DISCOVERED: ",
		data.get("title", ""),
		" — ",
		data.get("description", "")
	)


func get_active_event(world_id: int) -> Dictionary:
	var result: Dictionary = active_events.get(world_id, {}).duplicate(true)

	if not result.is_empty():
		result["remaining_seconds"] = maxf(
			float(remaining_times.get(world_id, 0.0)), 0.0
		)

	return result


func get_event_catalog(world_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for item in WORLD_EVENTS.get(world_id, []):
		result.append(item.duplicate(true))

	return result
