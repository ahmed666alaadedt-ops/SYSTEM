extends Node3D
class_name CommandCenterPartyDisplay

# SYSTEM WORLD
# Dynamic Party Display beside Miyar
# Godot 4.3

@export_group("Team Layout")
@export_range(1, 12, 1) var max_columns: int = 4
@export var horizontal_spacing: float = 1.25
@export var row_spacing: float = 1.35
@export var forward_distance: float = 1.8
@export var vertical_offset: float = 0.0

@export_group("Display")
@export var show_members: bool = true
@export var face_same_direction_as_assistant: bool = true

signal party_display_changed(member_count: int)
signal member_added(player_id: String)
signal member_removed(player_id: String)

var _assistant: Node3D
var _display_origin: Node3D

# Player ID -> actual 3D display avatar.
var _members: Dictionary = {}

# Keeps the display order stable.
var _member_ids: Array[String] = []


func _ready() -> void:
	_layout_members()


# ==================================================
# DISPLAY CONFIGURATION
# ==================================================

func configure_display(
	assistant: Node3D,
	display_origin: Node3D = null
) -> void:
	_assistant = assistant
	_display_origin = display_origin

	_layout_members()


func set_display_origin(origin: Node3D) -> void:
	_display_origin = origin
	_layout_members()


func set_assistant(assistant: Node3D) -> void:
	_assistant = assistant
	_layout_members()


# ==================================================
# PARTY REGISTRATION
# ==================================================

func register_party_member(
	player_id: String,
	display_avatar: Node3D
) -> void:
	var clean_id := player_id.strip_edges()

	if clean_id.is_empty():
		push_warning("Party member ID cannot be empty.")
		return

	if not is_instance_valid(display_avatar):
		push_warning("Party display avatar is invalid.")
		return

	# Replace an older display avatar for this player.
	if _members.has(clean_id):
		var old_avatar: Node3D = _members[clean_id]

		if is_instance_valid(old_avatar):
			old_avatar.visible = false

	else:
		_member_ids.append(clean_id)

	_members[clean_id] = display_avatar

	# Add only unparented display instances.
	if display_avatar.get_parent() == null:
		add_child(display_avatar)

	display_avatar.visible = show_members

	_layout_members()

	member_added.emit(clean_id)
	party_display_changed.emit(get_member_count())


func unregister_party_member(player_id: String) -> void:
	var clean_id := player_id.strip_edges()

	if not _members.has(clean_id):
		return

	var avatar: Node3D = _members[clean_id]

	if is_instance_valid(avatar):
		avatar.visible = false

	_members.erase(clean_id)
	_member_ids.erase(clean_id)

	_layout_members()

	member_removed.emit(clean_id)
	party_display_changed.emit(get_member_count())


# Replace the displayed party with a new list.
# Each item must be a real 3D display avatar.
func set_party_members(members: Array) -> void:
	clear_party_members()

	var index := 0

	for item in members:
		if not item is Node3D:
			continue

		var avatar := item as Node3D
		var player_id := "party_member_%d" % index

		register_party_member(player_id, avatar)
		index += 1

	_layout_members()


# Remove all displayed party members.
func clear_party_members() -> void:
	for player_id in _member_ids:
		var avatar: Node3D = _members.get(player_id)

		if is_instance_valid(avatar):
			avatar.visible = false

	_members.clear()
	_member_ids.clear()

	party_display_changed.emit(0)


# ==================================================
# MEMBER APPEARANCE AND VISIBILITY
# ==================================================

func refresh_member_display(player_id: String) -> void:
	var clean_id := player_id.strip_edges()

	if not _members.has(clean_id):
		return

	var avatar: Node3D = _members[clean_id]

	if not is_instance_valid(avatar):
		unregister_party_member(clean_id)
		return

	# Clothing and model changes are supplied by the avatar itself.
	# This function refreshes its position and visibility.
	avatar.visible = show_members
	_layout_members()


func set_member_visible(
	player_id: String,
	is_visible: bool
) -> void:
	var clean_id := player_id.strip_edges()

	if not _members.has(clean_id):
		return

	var avatar: Node3D = _members[clean_id]

	if is_instance_valid(avatar):
		avatar.visible = is_visible and show_members


func set_party_display_visible(is_visible: bool) -> void:
	show_members = is_visible

	for player_id in _member_ids:
		var avatar: Node3D = _members.get(player_id)

		if is_instance_valid(avatar):
			avatar.visible = show_members

	_layout_members()


# ==================================================
# PARTY INFORMATION
# ==================================================

func get_member_count() -> int:
	_remove_invalid_members()
	return _member_ids.size()


func get_party_member(player_id: String) -> Node3D:
	var clean_id := player_id.strip_edges()

	if not _members.has(clean_id):
		return null

	var avatar: Node3D = _members[clean_id]

	if not is_instance_valid(avatar):
		return null

	return avatar


func get_party_member_ids() -> Array[String]:
	_remove_invalid_members()
	return _member_ids.duplicate()


func has_party_member(player_id: String) -> bool:
	var clean_id := player_id.strip_edges()

	if not _members.has(clean_id):
		return false

	return is_instance_valid(_members[clean_id])


# ==================================================
# AUTOMATIC TEAM ARRANGEMENT
# ==================================================

func refresh_party_layout() -> void:
	_layout_members()


func _layout_members() -> void:
	_remove_invalid_members()

	var anchor := _get_layout_anchor()

	if not is_instance_valid(anchor):
		return

	var count := _member_ids.size()

	if count == 0:
		return

	var columns := maxi(1, mini(max_columns, count))
	var basis := anchor.global_transform.basis.orthonormalized()

	for i in range(count):
		var player_id := _member_ids[i]
		var avatar: Node3D = _members.get(player_id)

		if not is_instance_valid(avatar):
			continue

		var column_index := i % columns
		var row_index := floori(
			float(i) / float(columns)
		)

		var centered_column := (
			float(column_index) -
			float(columns - 1) * 0.5
		)

		var local_offset := Vector3(
			centered_column * horizontal_spacing,
			vertical_offset,
			forward_distance +
			float(row_index) * row_spacing
		)

		var world_offset := basis * local_offset

		avatar.global_position = (
			anchor.global_position +
			world_offset
		)

		if face_same_direction_as_assistant:
			avatar.global_rotation.y = anchor.global_rotation.y

		avatar.visible = show_members


func _get_layout_anchor() -> Node3D:
	if is_instance_valid(_display_origin):
		return _display_origin

	if is_instance_valid(_assistant):
		return _assistant

	return null


# ==================================================
# INVALID MEMBER CLEANUP
# ==================================================

func _remove_invalid_members() -> void:
	var invalid_ids: Array[String] = []

	for player_id in _member_ids:
		var avatar: Node3D = _members.get(player_id)

		if not is_instance_valid(avatar):
			invalid_ids.append(player_id)

	for player_id in invalid_ids:
		_members.erase(player_id)
		_member_ids.erase(player_id)

	if not invalid_ids.is_empty():
		party_display_changed.emit(_member_ids.size())
