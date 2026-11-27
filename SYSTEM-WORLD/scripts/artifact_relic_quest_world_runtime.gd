extends Node3D
class_name ArtifactRelicQuestWorldRuntime

## Creates in-world objective interactables for the active relic quest.
## This is presentation/progression scaffolding only; the backend must verify
## objective completion before granting a skill or changing artifact ownership.

const OBJECTIVE_LAYOUTS := {
	"babylonian_star_tablet": [
		{"id": "find_the_sealed_archive", "label": "اكتشف الأرشيف البابلي المختوم", "position": Vector3(-65.0, 1.0, 78.0)},
		{"id": "solve_the_celestial_lock", "label": "حل قفل النجوم", "position": Vector3(-48.0, 1.0, 62.0)},
		{"id": "defeat_the_archive_guardian", "label": "واجه حارس الأرشيف", "position": Vector3(-82.0, 1.0, 54.0)}
	],
	"sumerian_oath_seal": [
		{"id": "recover_the_three_oaths", "label": "اجمع العهود السومرية الثلاثة", "position": Vector3(22.0, 1.0, 24.0)},
		{"id": "restore_the_temple_seal", "label": "أعد ختم المعبد", "position": Vector3(36.0, 1.0, 42.0)}
	],
	"akkadian_shadow_crown": [
		{"id": "trace_the_lost_dynasty", "label": "تتبّع أثر السلالة المفقودة", "position": Vector3(74.0, 1.0, 20.0)},
		{"id": "pass_the_shadow_trial", "label": "اجتز اختبار الظلال", "position": Vector3(92.0, 1.0, 42.0)},
		{"id": "seal_the_cursed_chamber", "label": "أغلق حجرة اللعنة", "position": Vector3(68.0, 1.0, 58.0)}
	]
}

var relic_id := ""
var quest_id := ""
var historical_site_id := ""
var return_required := false


func setup(p_relic_id: String, definition: Dictionary) -> bool:
	if not OBJECTIVE_LAYOUTS.has(p_relic_id):
		return false
	relic_id = p_relic_id
	quest_id = str(definition.get("quest_id", ""))
	historical_site_id = str(definition.get("historical_site_id", ""))
	return_required = bool(definition.get("return_relic", false))
	_build_objectives()
	if return_required:
		_build_return_site()
	return true


func _build_objectives() -> void:
	for entry in OBJECTIVE_LAYOUTS[relic_id]:
		var objective := Node3D.new()
		objective.name = "RelicQuestObjective_" + str(entry.id)
		objective.position = entry.position
		objective.add_to_group("system_interactable")
		objective.set_meta("system_relic_quest_objective_id", str(entry.id))
		objective.set_meta("system_relic_id", relic_id)
		objective.set_meta("system_relic_quest_id", quest_id)
		objective.set_meta("system_interaction_prompt", str(entry.label) + " — تفاعل")
		var visual := MeshInstance3D.new()
		visual.name = "ObjectiveMarker"
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.9, 1.6, 0.9)
		visual.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.78, 0.55, 0.22)
		material.metallic = 0.45
		material.roughness = 0.32
		material.emission_enabled = true
		material.emission = Color(0.28, 0.12, 0.025)
		visual.material_override = material
		visual.position.y = 1.0
		objective.add_child(visual)
		var area := Area3D.new()
		area.name = "ObjectiveInteractionArea"
		area.collision_layer = 1
		area.collision_mask = 1
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 3.0
		collision.shape = sphere
		area.add_child(collision)
		objective.add_child(area)
		add_child(objective)


func _build_return_site() -> void:
	var site := Node3D.new()
	site.name = "RelicHistoricalReturnSite"
	site.position = Vector3(-65.0, 1.0, 92.0) if relic_id == "babylonian_star_tablet" else Vector3(35.0, 1.0, 52.0)
	site.add_to_group("system_interactable")
	site.set_meta("system_relic_return_site", true)
	site.set_meta("system_relic_id", relic_id)
	site.set_meta("system_relic_quest_id", quest_id)
	site.set_meta("system_historical_site_id", historical_site_id)
	site.set_meta("system_interaction_prompt", "إرجاع التحفة إلى موقعها التاريخي")
	var visual := MeshInstance3D.new()
	visual.name = "ReturnAltar"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.4
	mesh.bottom_radius = 1.8
	mesh.height = 0.7
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.58, 0.32)
	material.metallic = 0.7
	visual.material_override = material
	site.add_child(visual)
	var area := Area3D.new()
	area.name = "ReturnSiteInteractionArea"
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.5
	collision.shape = sphere
	area.add_child(collision)
	site.add_child(area)
	add_child(site)
