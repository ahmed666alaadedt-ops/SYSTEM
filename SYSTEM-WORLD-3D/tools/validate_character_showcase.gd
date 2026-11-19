extends SceneTree

const SHOWCASE_SCENE := "res://scenes/character_showcase.tscn"
const REQUIRED_CLIPS := [
	"Idle_Breathing",
	"Walk_Cycle",
	"Run_Cycle",
	"Jump_Animation",
	"Attack_Animation"
]

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var packed := load(SHOWCASE_SCENE) as PackedScene
	if packed == null:
		push_error("SYSTEM CHARACTER QA: showcase scene could not be loaded")
		quit(1)
		return

	var showcase := packed.instantiate()
	get_root().add_child(showcase)
	await process_frame

	var character_count := 0
	var hairstyle_variants: Dictionary = {}
	var required_assets := [
		"SYSTEM_Humanoid_Male.glb", "SYSTEM_Humanoid_Female.glb",
		"SYSTEM_Humanoid_Elder_Male.glb", "SYSTEM_Humanoid_Elder_Female.glb",
		"SYSTEM_Humanoid_Child_Male.glb", "SYSTEM_Humanoid_Child_Female.glb"
	]
	for asset_name in required_assets:
		if not FileAccess.file_exists("res://assets/characters/" + asset_name):
			push_error("SYSTEM CHARACTER QA: missing age/gender asset " + asset_name)
			quit(1)
			return

	for child in showcase.get_children():
		if not child.has_method("get_character_status"):
			continue
		character_count += 1
		var status: Dictionary = child.call("get_character_status")
		var hair_style := str(status.get("hair_style", ""))
		hairstyle_variants[hair_style] = true
		if hair_style != "short" and int(status.get("hairstyle_mesh_count", 0)) < 1:
			push_error("SYSTEM CHARACTER QA: requested hairstyle did not create visible mesh pieces: " + hair_style)
			quit(1)
			return
		print("SYSTEM_CHARACTER_QA ", child.name, " ", status)

		if status.get("model_source", "") == "glb":
			if int(status.get("skeleton_count", 0)) < 1:
				push_error("SYSTEM CHARACTER QA: imported GLB has no Skeleton3D node")
				quit(1)
				return
			if int(status.get("mesh_instance_count", 0)) < 7:
				push_error("SYSTEM CHARACTER QA: imported character is missing expected body, face, hands or outfit mesh groups")
				quit(1)
				return
			var clips: Array = status.get("animation_clips", [])
			var clip_aliases := {
				"Idle_Breathing": ["idle_breathing"],
				"Walk_Cycle": ["walk_cycle", "walk"],
				"Run_Cycle": ["run_cycle", "run"],
				"Jump_Animation": ["jump_animation", "jump"],
				"Attack_Animation": ["attack_animation", "attack"]
			}
			for required_clip in REQUIRED_CLIPS:
				var found := false
				for clip_name in clips:
					var actual_name := str(clip_name).to_lower()
					for alias in clip_aliases[required_clip]:
						if actual_name.contains(alias):
							found = true
							break
					if found:
						break
				if not found:
					push_error("SYSTEM CHARACTER QA: missing animation clip " + str(required_clip))
					quit(1)
					return

	if hairstyle_variants.size() < 4:
		push_error("SYSTEM CHARACTER QA: expected at least four hairstyle variants")
		quit(1)
		return

	if character_count != 6:
		push_error("SYSTEM CHARACTER QA: expected six age/gender showcase characters, found " + str(character_count))
		quit(1)
		return

	for child in showcase.get_children():
		if child.has_method("get_character_status") and child.call("get_character_status").get("model_source") != "glb":
			push_error("SYSTEM CHARACTER QA: GLB assets exist but a character fell back to procedural mode")
			quit(1)
			return


	var society_script = load("res://scripts/ai_npc_society_manager.gd")
	if society_script == null:
		push_error("SYSTEM NPC QA: living society manager failed to load")
		quit(1)
		return
	var society_world := Node3D.new()
	society_world.name = "NPCSocietyValidationWorld"
	get_root().add_child(society_world)
	var society = society_script.new()
	society_world.add_child(society)
	society.call("setup", society_world)
	if int(society.call("get_resident_count")) != 20:
		push_error("SYSTEM NPC QA: expected 20 adult, elder and child residents")
		quit(1)
		return
	var child_profile: Dictionary = society.call("get_resident_information", "ليان")
	var elder_profile: Dictionary = society.call("get_resident_information", "جد سارة")
	var child_family: Dictionary = child_profile.get("family_profile", {})
	var married_bond: Dictionary = society.call("get_relationship_information", "ليلى", "حسن")
	if child_family.get("parents", []).size() != 2:
		push_error("SYSTEM NPC QA: child family parent links were not created")
		quit(1)
		return
	if str(married_bond.get("type", "")) != "married":
		push_error("SYSTEM NPC QA: adult family marriage link was not created")
		quit(1)
		return
	if str(child_profile.get("age_group", "")) != "child":
		push_error("SYSTEM NPC QA: child life stage was not preserved")
		quit(1)
		return
	if str(elder_profile.get("age_group", "")) != "elder":
		push_error("SYSTEM NPC QA: elder life stage was not preserved")
		quit(1)
		return
	var population: Dictionary = society.call("get_population_summary")
	if int(population.get("children", 0)) != 4 or int(population.get("elders", 0)) != 4:
		push_error("SYSTEM NPC QA: child/elder population distribution is incorrect")
		quit(1)
		return
	if bool(society.call("set_resident_activity", "ليان", "combat", Vector3.ZERO)):
		push_error("SYSTEM NPC QA: a child was incorrectly allowed to enter combat")
		quit(1)
		return
	if not bool(society.call("add_resident", {
		"name": "اختبار ساكن جديد", "age": 42, "family": "family_test",
		"body_type": "heavy", "height_type": "tall"
	})):
		push_error("SYSTEM NPC QA: dynamic resident creation failed")
		quit(1)
		return
	if not bool(society.call("create_family_child", "ليلى", "حسن", {
		"name": "مولود الاختبار", "gender": "male",
		"body_type": "average", "height_type": "short"
	})):
		push_error("SYSTEM NPC QA: married NPC family could not welcome a child")
		quit(1)
		return
	var newborn: Dictionary = society.call("get_resident_information", "مولود الاختبار")
	var newborn_family: Dictionary = newborn.get("family_profile", {})
	if str(newborn.get("age_group", "")) != "child" or newborn_family.get("parents", []).size() != 2:
		push_error("SYSTEM NPC QA: newborn age or parentage record is invalid")
		quit(1)
		return
	print("SYSTEM NPC QA PASS: age groups, family records, safe child rules, dynamic residents and body profiles initialized")
	society_world.queue_free()
	print("SYSTEM CHARACTER QA PASS: six age/gender character models loaded and inspected")
	quit(0)
