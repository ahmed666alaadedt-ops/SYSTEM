
extends "res://scripts/command_center_complete.gd"

# SYSTEM WORLD - Map and Miyar Visual Bridge
# Godot 4.3

const MapPanelScript = preload(
	"res://scripts/command_center_map_panel.gd"
)

const OLD_MIYAR_PARTS := [
	"MiyarChairBack",
	"MiyarChairSeat",
	"MiyarBody",
	"MiyarHead",
	"MiyarHair",
	"MiyarLeftArm",
	"MiyarRightArm",
	"MiyarLeftLeg",
	"MiyarRightLeg"
]

var map_panel: Node


func _ready() -> void:
	super._ready()

	_remove_old_miyar_placeholder()

	map_panel = MapPanelScript.new()
	map_panel.name = "SYSTEMCommandCenterMap"
	add_child(map_panel)


func _remove_old_miyar_placeholder() -> void:
	for part_name in OLD_MIYAR_PARTS:
		var old_part := get_node_or_null(part_name)

		if is_instance_valid(old_part):
			old_part.queue_free()


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
