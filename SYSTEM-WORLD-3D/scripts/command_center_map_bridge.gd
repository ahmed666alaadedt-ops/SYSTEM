extends "res://scripts/command_center_complete.gd"

# SYSTEM WORLD - Map Button Bridge
# Godot 4.3

const MapPanelScript = preload(
	"res://scripts/command_center_map_panel.gd"
)

var map_panel: Node


func _ready() -> void:
	super._ready()

	map_panel = MapPanelScript.new()
	map_panel.name = "SYSTEMCommandCenterMap"
	add_child(map_panel)


func _on_utility_pressed(action_name: String) -> void:
	if action_name == "الخريطة":
		if is_instance_valid(map_panel):
			map_panel.call(
				"open_map",
				selected_world
			)

		if is_instance_valid(utility_status):
			utility_status.text = (
				"تم فتح أطلس العالم المحدد."
			)

		return

	super._on_utility_pressed(action_name)
