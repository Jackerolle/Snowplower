extends Node2D

var cell_size := 28.0
var play_area := Rect2()
var road_rects: Array[Rect2] = []
var columns := 0
var rows := 0
var snow_amounts := PackedFloat32Array()
var road_mask := PackedByteArray()
var initial_total := 0.0
var remaining_total := 0.0
var rng := RandomNumberGenerator.new()

func setup(level_play_area: Rect2, level_road_rects: Array[Rect2]) -> void:
	rng.randomize()
	play_area = level_play_area
	road_rects = level_road_rects.duplicate()
	columns = int(ceil(play_area.size.x / cell_size))
	rows = int(ceil(play_area.size.y / cell_size))

	var cell_count := columns * rows
	snow_amounts = PackedFloat32Array()
	snow_amounts.resize(cell_count)
	road_mask = PackedByteArray()
	road_mask.resize(cell_count)
	initial_total = 0.0
	remaining_total = 0.0

	for row in range(rows):
		for col in range(columns):
			var index := row * columns + col
			var center := _cell_center(col, row)
			if _point_on_road(center):
				road_mask[index] = 1
				var drift := 0.45 + rng.randf() * 0.55
				drift += 0.12 * sin(center.x * 0.014) + 0.10 * cos(center.y * 0.018)
				drift = clamp(drift, 0.18, 1.0)
				snow_amounts[index] = drift
				initial_total += drift
				remaining_total += drift
			else:
				road_mask[index] = 0
				snow_amounts[index] = 0.0

	queue_redraw()

func get_clear_ratio() -> float:
	if initial_total <= 0.0:
		return 1.0
	return 1.0 - (remaining_total / initial_total)

func plow(blade_center: Vector2, forward: Vector2, blade_width: float, blade_depth: float, delta: float) -> float:
	if columns == 0 or rows == 0:
		return 0.0

	var side := forward.orthogonal()
	var half_width := blade_width * 0.5 + cell_size
	var depth := blade_depth + cell_size
	var corners: Array[Vector2] = [
		blade_center + side * half_width,
		blade_center - side * half_width,
		blade_center + forward * depth + side * half_width,
		blade_center + forward * depth - side * half_width,
	]

	var min_x: float = corners[0].x
	var max_x: float = corners[0].x
	var min_y: float = corners[0].y
	var max_y: float = corners[0].y
	for point in corners:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	var min_col: int = clampi(int(floor((min_x - play_area.position.x) / cell_size)), 0, columns - 1)
	var max_col: int = clampi(int(floor((max_x - play_area.position.x) / cell_size)), 0, columns - 1)
	var min_row: int = clampi(int(floor((min_y - play_area.position.y) / cell_size)), 0, rows - 1)
	var max_row: int = clampi(int(floor((max_y - play_area.position.y) / cell_size)), 0, rows - 1)

	var removed_total := 0.0
	for row in range(min_row, max_row + 1):
		for col in range(min_col, max_col + 1):
			var index := row * columns + col
			if road_mask[index] == 0:
				continue

			var amount := snow_amounts[index]
			if amount <= 0.01:
				continue

			var center: Vector2 = _cell_center(col, row)
			var delta_pos: Vector2 = center - blade_center
			var front: float = delta_pos.dot(forward)
			if front < -cell_size * 0.35 or front > blade_depth:
				continue

			var lateral: float = absf(delta_pos.dot(side))
			if lateral > blade_width * 0.5:
				continue

			var bite: float = delta * 1.35 * (1.15 - (front / maxf(blade_depth, 1.0)))
			var removed: float = minf(amount, maxf(0.01, bite))
			snow_amounts[index] = amount - removed
			removed_total += removed

	if removed_total > 0.0:
		remaining_total = max(0.0, remaining_total - removed_total)
		queue_redraw()

	return removed_total

func _point_on_road(point: Vector2) -> bool:
	for rect in road_rects:
		if rect.has_point(point):
			return true
	return false

func _cell_center(col: int, row: int) -> Vector2:
	return play_area.position + Vector2((col + 0.5) * cell_size, (row + 0.5) * cell_size)

func _draw() -> void:
	if columns == 0 or rows == 0:
		return

	for row in range(rows):
		for col in range(columns):
			var index := row * columns + col
			if road_mask[index] == 0:
				continue

			var amount := snow_amounts[index]
			if amount <= 0.015:
				continue

			var top_left := play_area.position + Vector2(col * cell_size, row * cell_size)
			var alpha: float = 0.14 + amount * 0.72
			var color: Color = Color(0.90, 0.95, 1.0, alpha)
			if amount > 0.70:
				color = Color(0.96, 0.98, 1.0, alpha)

			draw_rect(Rect2(top_left, Vector2(cell_size + 0.5, cell_size + 0.5)), color, true)
