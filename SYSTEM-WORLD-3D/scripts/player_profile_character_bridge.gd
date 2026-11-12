extends Node

# SYSTEM WORLD - PLAYER PROFILE CHARACTER BRIDGE
# Godot 4.3

const PlayerCharacterScript = preload(
	"res://scripts/player_character_3d.gd"
)

var player_character: Node3D
var profile_button: Button


func _ready() -> void:
	call_deferred("_connect_profile_button")
	_create_player_character()


func _create_player_character() -> void:
	if is_instance_valid(player_character):
		return

	var root := get_parent()

	if not is_instance_valid(root):
		return

	player_character = PlayerCharacterScript.new()
	player_character.name = "SYSTEMPlayerCharacter"

	player_character.position = Vector3(
		3.2,
		0.0,
		-0.35
	)

	root.add_child(player_character)


func _connect_profile_button() -> void:
	var root := get_parent()

	if not is_instance_valid(root):
		return

	var buttons := root.find_children(
		"*",
		"Button",
		true,
		false
	)

	for item in buttons:
		if item.has_signal("profile_updated"):
			profile_button = item as Button

			var callback := Callable(
				self,
				"_on_profile_updated"
			)

			if not profile_button.is_connected(
				"profile_updated",
				callback
			):
				profile_button.connect(
					"profile_updated",
					callback
				)

			return

	push_warning(
		"SYSTEM: Player profile button was not found."
	)


func _on_profile_updated(
	profile_data: Dictionary
) -> void:
	if not is_instance_valid(player_character):
		_create_player_character()

	if not is_instance_valid(player_character):
		return

	player_character.call(
		"apply_profile",
		profile_data
	)
