extends SceneTree

const SHOWCASE_SCENE := "res://scenes/character_showcase.tscn"
const REQUIRED_CLIPS := [
	"Idle_Breathing",
	"Walk_Cycle",
	"Run_Cycle",
	"Jump_Animation",
	"Attack_Animation",
	"Facial_Blink",
	"Facial_Talking"
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
		if int(status.get("face_detail_mesh_count", 0)) < 4:
			push_error("SYSTEM CHARACTER QA: face details were not generated for " + child.name)
			quit(1)
			return
		if str(status.get("age_group", "")) == "elder" and int(status.get("face_detail_mesh_count", 0)) < 8:
			push_error("SYSTEM CHARACTER QA: elder wrinkles or age features are missing")
			quit(1)
			return
		if str(status.get("outfit_id", "")) in ["guard", "hunter"] and int(status.get("job_accessory_mesh_count", 0)) < 2:
			push_error("SYSTEM CHARACTER QA: profession-specific equipment is missing")
			quit(1)
			return
		if str(status.get("city", "")) != "بغداد":
			push_error("SYSTEM CHARACTER QA: local city identity was not passed to the character")
			quit(1)
			return
		if hair_style != "short" and int(status.get("hairstyle_mesh_count", 0)) < 1:
			push_error("SYSTEM CHARACTER QA: requested hairstyle did not create visible mesh pieces: " + hair_style)
			quit(1)
			return
		print("SYSTEM_CHARACTER_QA ", child.name, " ", status)

		if status.get("model_source", "") == "glb":
			if child.name == "NPCCharacter_SYSTEM_Humanoid_Male":
				child.call("set_hair_style", "long")
				child.call("set_hair_color", "blue")
				var long_hair_status: Dictionary = child.call("get_character_status")
				if str(long_hair_status.get("hair_style", "")) != "long" or int(long_hair_status.get("hairstyle_mesh_count", 0)) < 3:
					push_error("SYSTEM CHARACTER QA: long men's hairstyle did not create runtime hair geometry")
					quit(1)
					return
				if str(long_hair_status.get("hair_color", "")).to_lower() != "blue":
					push_error("SYSTEM CHARACTER QA: blue hair color was not saved to the appearance profile")
					quit(1)
					return
				for test_color in ["red", "yellow", "white", "silver", "purple", "green", "cyan", "pink", "orange", "gold", "magenta"]:
					child.call("set_hair_color", test_color)
					var color_status: Dictionary = child.call("get_character_status")
					if str(color_status.get("hair_color", "")).to_lower() != test_color:
						push_error("SYSTEM CHARACTER QA: hair color option was not applied: " + test_color)
						quit(1)
						return
				for test_style in ["medium", "long", "curly", "braided", "ponytail", "bun", "bob", "pixie", "topknot", "afro", "dreadlocks", "twin_tails", "spiky", "side_swept", "undercut", "layered"]:
					child.call("set_hair_style", test_style)
					var style_status: Dictionary = child.call("get_character_status")
					if int(style_status.get("hairstyle_mesh_count", 0)) < 1:
						push_error("SYSTEM CHARACTER QA: hairstyle geometry was not created: " + test_style)
						quit(1)
						return
				child.call("set_hair_style", "long")
				child.call("set_hair_color", "blue")
				print("SYSTEM_HAIR_CUSTOMIZATION_QA long_male=true colors=blue,red,yellow,white,purple,green")
			if int(status.get("skeleton_count", 0)) < 1:
				push_error("SYSTEM CHARACTER QA: imported GLB has no Skeleton3D node")
				quit(1)
				return
			if int(status.get("mesh_instance_count", 0)) < 7:
				push_error("SYSTEM CHARACTER QA: imported character is missing expected body, face, hands or outfit mesh groups")
				quit(1)
				return
			if not bool(status.get("facial_controls_complete", false)):
				push_error("SYSTEM CHARACTER QA: imported rig is missing one or more head/jaw/eye/brow control bones")
				quit(1)
				return
			child.call("set_facial_expression", "happy")
			child.call("set_eye_direction", Vector2(0.5, -0.25))
			child.call("set_facial_expression", "confused")
			child.call("set_face_shape", "wide")
			var customized_status: Dictionary = child.call("get_character_status")
			if str(customized_status.get("face_shape", "")) != "wide":
				push_error("SYSTEM CHARACTER QA: runtime face-shape customization was not saved")
				quit(1)
				return
			var clips: Array = status.get("animation_clips", [])
			var clip_aliases := {
				"Idle_Breathing": ["idle_breathing"],
				"Walk_Cycle": ["walk_cycle", "walk"],
				"Run_Cycle": ["run_cycle", "run"],
				"Jump_Animation": ["jump_animation", "jump"],
				"Attack_Animation": ["attack_animation", "attack"],
				"Facial_Blink": ["facial_blink", "blink"],
				"Facial_Talking": ["facial_talking", "talking"]
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


	var character_script = load("res://scripts/npc_character_model.gd")
	if character_script == null:
		push_error("SYSTEM CHARACTER QA: NPC character script failed to load")
		quit(1)
		return
	var creator_script = load("res://scripts/player_profile_button.gd")
	if creator_script == null:
		push_error("SYSTEM PLAYER QA: player creator script failed to load")
		quit(1)
		return
	var creator_constants: Dictionary = creator_script.get_script_constant_map()
	var male_styles: Array = creator_constants.get("MALE_HAIR_STYLES", [])
	var female_styles: Array = creator_constants.get("FEMALE_HAIR_STYLES", [])
	for modern_cut in ["Fade", "Low Fade", "Mid Fade", "High Fade", "Taper Fade", "Undercut", "Buzz Cut", "Crew Cut", "Textured Crop", "French Crop", "Quiff", "Pompadour", "Slick Back", "Side Part"]:
		if not male_styles.has(modern_cut):
			push_error("SYSTEM PLAYER QA: missing modern men's haircut: " + modern_cut)
			quit(1)
			return
	for long_male_style in ["شعر طويل", "شعر طويل مدرج", "شعر ويفي طويل", "شعر مجعد طويل", "ذيل حصان رجالي", "كعكة رجالية", "ضفائر رجالية"]:
		if not male_styles.has(long_male_style):
			push_error("SYSTEM PLAYER QA: missing long men's hairstyle: " + long_male_style)
			quit(1)
			return
	if male_styles.has("بيكسي") or not female_styles.has("بيكسي"):
		push_error("SYSTEM PLAYER QA: gender-specific hairstyle lists are not separated")
		quit(1)
		return

	var player_script = load("res://scripts/player_character_3d.gd")
	if player_script == null:
		push_error("SYSTEM PLAYER QA: player character script failed to load")
		quit(1)
		return
	var player_test = player_script.new()
	get_root().add_child(player_test)
	player_test.call("apply_profile", {
		"name": "Long Hair Player QA",
		"appearance": "ذكر",
		"age_group": "adult",
		"hair_style": "طويل",
		"hair_color": "أزرق",
		"face": "متوازن",
		"body": "رياضي",
		"outfit": "الزي الأساسي"
	})
	await process_frame
	var player_status: Dictionary = player_test.imported_character.call("get_character_status")
	if str(player_status.get("hair_style", "")) != "long" or int(player_status.get("hairstyle_mesh_count", 0)) < 3:
		push_error("SYSTEM PLAYER QA: male player profile did not apply long hairstyle geometry")
		quit(1)
		return
	if str(player_status.get("hair_color", "")).to_lower() != "أزرق":
		push_error("SYSTEM PLAYER QA: male player profile did not apply blue hair color")
		quit(1)
		return
	for player_color in ["أحمر", "أصفر", "أبيض", "فضي", "رمادي", "أزرق داكن", "بنفسجي", "أخضر", "سماوي", "وردي", "برتقالي", "ذهبي", "أرجواني"]:
		player_test.imported_character.call("set_hair_color", player_color)
		var updated_player_status: Dictionary = player_test.imported_character.call("get_character_status")
		if str(updated_player_status.get("hair_color", "")) != player_color:
			push_error("SYSTEM PLAYER QA: player hair color was not applied: " + player_color)
			quit(1)
			return
	for player_style in ["متوسط", "طويل", "مجعد", "ضفيرة", "ذيل حصان", "كعكة", "مرفوع", "أفرو", "دريدلوك", "ضفيرتان", "بوب", "بيكسي", "مدرج", "شائك", "جانبي", "محلوق الجوانب"]:
		player_test.imported_character.call("set_hair_style", player_style)
		var updated_style_status: Dictionary = player_test.imported_character.call("get_character_status")
		if int(updated_style_status.get("hairstyle_mesh_count", 0)) < 1:
			push_error("SYSTEM PLAYER QA: player hairstyle geometry was not generated: " + player_style)
			quit(1)
			return
	var modern_cut_tests := {
		"Fade": "fade", "Low Fade": "fade", "Mid Fade": "fade",
		"High Fade": "fade", "Taper Fade": "fade", "Undercut": "undercut",
		"Buzz Cut": "short", "Crew Cut": "short", "Textured Crop": "quiff",
		"French Crop": "short", "Quiff": "quiff", "Pompadour": "quiff",
		"Slick Back": "slick_back", "Side Part": "slick_back"
	}
	for cut_name in modern_cut_tests.keys():
		player_test.imported_character.call("set_hair_style", cut_name)
		var cut_status: Dictionary = player_test.imported_character.call("get_character_status")
		if str(cut_status.get("hair_style", "")) != str(modern_cut_tests[cut_name]) or int(cut_status.get("hairstyle_mesh_count", 0)) < 1:
			push_error("SYSTEM PLAYER QA: modern men's cut did not produce its expected geometry: " + cut_name)
			quit(1)
			return

	var fallback_script = load("res://scripts/npc_humanoid_visual.gd")
	if fallback_script == null:
		push_error("SYSTEM PLAYER QA: procedural 3D fallback visual failed to load")
		quit(1)
		return
	var fallback_test = fallback_script.new()
	get_root().add_child(fallback_test)
	await process_frame
	fallback_test.call("configure", {"name": "Men Hair Fallback QA", "appearance": "ذكر", "hair_style": "Fade", "hair_color": "أزرق داكن"})
	for cut_name in modern_cut_tests.keys():
		fallback_test.call("set_hair_style", cut_name)
		var runtime_hair_count := 0
		for mesh_node in fallback_test.find_children("*", "MeshInstance3D", true, false):
			if str(mesh_node.name).begins_with("RuntimeHair"):
				runtime_hair_count += 1
		if runtime_hair_count < 1:
			push_error("SYSTEM PLAYER QA: procedural fallback did not build hair geometry for " + cut_name)
			quit(1)
			return
	fallback_test.queue_free()
	print("SYSTEM PLAYER QA PASS: modern men's cuts map to distinct live hair styles and procedural fallback geometry")
	print("SYSTEM PLAYER QA PASS: saved-profile input reaches live male 3D avatar with long hair and full palette")
	player_test.queue_free()

	var doctor_test = character_script.new()
	get_root().add_child(doctor_test)
	doctor_test.call("configure", {"name": "Doctor QA", "gender": "female", "age_group": "adult", "job": "طبيبة", "city": "بغداد"}, 1)
	var doctor_status: Dictionary = doctor_test.call("get_character_status")
	if str(doctor_status.get("outfit_id", "")) != "doctor" or int(doctor_status.get("job_accessory_mesh_count", 0)) < 3:
		push_error("SYSTEM CHARACTER QA: Arabic doctor profession outfit was not created")
		quit(1)
		return
	var baker_test = character_script.new()
	get_root().add_child(baker_test)
	baker_test.call("configure", {"name": "Baker QA", "gender": "male", "age_group": "adult", "job": "خباز", "city": "بغداد"}, 2)
	var baker_status: Dictionary = baker_test.call("get_character_status")
	if str(baker_status.get("outfit_id", "")) != "baker" or int(baker_status.get("job_accessory_mesh_count", 0)) < 1:
		push_error("SYSTEM CHARACTER QA: Arabic baker profession outfit was not created")
		quit(1)
		return
	doctor_test.queue_free()
	baker_test.queue_free()

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
