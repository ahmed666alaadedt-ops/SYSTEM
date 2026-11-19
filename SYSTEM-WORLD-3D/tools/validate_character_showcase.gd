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

	if character_count != 6:
		push_error("SYSTEM CHARACTER QA: expected six age/gender showcase characters, found " + str(character_count))
		quit(1)
		return

	for child in showcase.get_children():
		if child.has_method("get_character_status") and child.call("get_character_status").get("model_source") != "glb":
			push_error("SYSTEM CHARACTER QA: GLB assets exist but a character fell back to procedural mode")
			quit(1)
			return

	print("SYSTEM CHARACTER QA PASS: six age/gender character models loaded and inspected")
	quit(0)
