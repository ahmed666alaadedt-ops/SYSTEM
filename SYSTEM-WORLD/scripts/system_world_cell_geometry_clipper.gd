extends RefCounted
class_name SystemWorldCellGeometryClipper

## Deterministic Liang-Barsky clipping for world-space X/Z polylines.
## Adjacent cells clip the same source segment against shared numeric bounds,
## yielding matching boundary coordinates for roads, rivers and bridge guides.

static func clip_polyline_to_rect(
	points: PackedVector2Array,
	minimum: Vector2,
	maximum: Vector2
) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = []
	if points.size() < 2 or minimum.x > maximum.x or minimum.y > maximum.y:
		return pieces
	var current := PackedVector2Array()
	for index in range(points.size() - 1):
		var clipped := _clip_segment(points[index], points[index + 1], minimum, maximum)
		if clipped.is_empty():
			if current.size() >= 2:
				pieces.append(current)
			current = PackedVector2Array()
			continue
		var start: Vector2 = clipped[0]
		var finish: Vector2 = clipped[1]
		if current.is_empty():
			current.append(start)
			current.append(finish)
		elif current[current.size() - 1].is_equal_approx(start):
			if not current[current.size() - 1].is_equal_approx(finish):
				current.append(finish)
		else:
			if current.size() >= 2:
				pieces.append(current)
			current = PackedVector2Array([start, finish])
	if current.size() >= 2:
		pieces.append(current)
	return pieces


static func _clip_segment(
	start: Vector2,
	finish: Vector2,
	minimum: Vector2,
	maximum: Vector2
) -> PackedVector2Array:
	var delta := finish - start
	var t_min := 0.0
	var t_max := 1.0
	var p_values := [-delta.x, delta.x, -delta.y, delta.y]
	var q_values := [
		start.x - minimum.x,
		maximum.x - start.x,
		start.y - minimum.y,
		maximum.y - start.y
	]
	for index in range(4):
		var p: float = p_values[index]
		var q: float = q_values[index]
		if is_zero_approx(p):
			if q < 0.0:
				return PackedVector2Array()
			continue
		var ratio := q / p
		if p < 0.0:
			t_min = maxf(t_min, ratio)
		else:
			t_max = minf(t_max, ratio)
		if t_min > t_max:
			return PackedVector2Array()
	return PackedVector2Array([
		start + delta * t_min,
		start + delta * t_max
	])
