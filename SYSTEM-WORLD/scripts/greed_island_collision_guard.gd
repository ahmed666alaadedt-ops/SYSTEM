extends Node

## يصحح ارتفاع تصادم أرض جزيرة الطمع بعد إنشائها.
## لا يغيّر المجسمات أو بقية أنظمة الجزيرة.

var collision_fixed := false


func _process(_delta: float) -> void:
	if collision_fixed:
		return

	var collision := get_tree().root.find_child(
		"IslandWalkableCollision",
		true,
		false
	) as CollisionShape3D

	if collision == null:
		return

	collision.position.y = 0.0
	collision_fixed = true

	print("GREED ISLAND: ground collision height corrected.")
