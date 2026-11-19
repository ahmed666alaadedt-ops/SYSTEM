extends Node3D
class_name SystemCharacterShowcase

const CHARACTER_MODEL = preload("res://scripts/npc_character_model.gd")

func _ready() -> void:
	_build_stage()
	_spawn_character("SYSTEM_Humanoid_Male", "male", "hunter", Vector3(-0.95, 0.0, 0.0))
	_spawn_character("SYSTEM_Humanoid_Female", "female", "guard", Vector3(0.95, 0.0, 0.0))

func _spawn_character(display_name: String, gender: String, job: String, at: Vector3) -> void:
	var character := CHARACTER_MODEL.new()
	character.name = display_name
	add_child(character)
	character.position = at
	character.configure({"name": display_name, "gender": gender, "job": job}, 0)
	character.set_activity("idle")
	call_deferred("_report_character_status", character)
	var title := Label3D.new()
	title.text = gender.capitalize() + " • " + job.capitalize()
	title.position = Vector3(0.0, 2.15, 0.0)
	title.font_size = 32
	title.outline_size = 8
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	character.add_child(title)

func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "ShowcaseFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 12.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color8(17, 25, 37)
	floor_material.roughness = 0.9
	floor.material_override = floor_material
	add_child(floor)

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color8(8, 13, 24)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color8(95, 112, 142)
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42.0, 28.0, 0.0)
	key_light.light_energy = 1.7
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(2.8, 3.0, 2.0)
	fill_light.light_color = Color8(65, 160, 230)
	fill_light.light_energy = 1.1
	fill_light.omni_range = 8.0
	add_child(fill_light)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.45, 6.2)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)

func _report_character_status(character: Node) -> void:
	if is_instance_valid(character) and character.has_method("get_character_status"):
		print("SYSTEM_CHARACTER_SHOWCASE ", character.name, " ", character.call("get_character_status"))
