extends Node2D

const PLAY_AREA := Rect2(-900.0, -520.0, 1800.0, 1040.0)

var road_rects: Array[Rect2] = [
	Rect2(-900.0, -170.0, 1800.0, 340.0),
	Rect2(-210.0, -520.0, 420.0, 1040.0),
]

var dump_zones: Array[Rect2] = [
	Rect2(-156.0, -520.0, 312.0, 92.0),
	Rect2(-156.0, 428.0, 312.0, 92.0),
	Rect2(-900.0, -116.0, 92.0, 232.0),
	Rect2(808.0, -116.0, 92.0, 232.0),
]

var black_ice_zones: Array[Rect2] = [
	Rect2(-560.0, -82.0, 200.0, 70.0),
	Rect2(312.0, 24.0, 220.0, 78.0),
	Rect2(-72.0, -350.0, 148.0, 120.0),
]

var corner_blocks: Array[Rect2] = [
	Rect2(-900.0, -520.0, 690.0, 350.0),
	Rect2(210.0, -520.0, 690.0, 350.0),
	Rect2(-900.0, 170.0, 690.0, 350.0),
	Rect2(210.0, 170.0, 690.0, 350.0),
]

var car_specs: Array[Dictionary] = [
	{"position": Vector2(-545.0, -124.0), "rotation": 0.02, "size": Vector2(76.0, 34.0), "color": Color(0.83, 0.24, 0.28)},
	{"position": Vector2(-392.0, 118.0), "rotation": 0.04, "size": Vector2(72.0, 34.0), "color": Color(0.18, 0.61, 0.75)},
	{"position": Vector2(480.0, -116.0), "rotation": -0.05, "size": Vector2(76.0, 35.0), "color": Color(0.11, 0.74, 0.53)},
	{"position": Vector2(610.0, 122.0), "rotation": -0.03, "size": Vector2(82.0, 36.0), "color": Color(0.94, 0.63, 0.14)},
	{"position": Vector2(-126.0, -424.0), "rotation": PI * 0.5, "size": Vector2(76.0, 34.0), "color": Color(0.67, 0.37, 0.93)},
	{"position": Vector2(118.0, 346.0), "rotation": PI * 0.5, "size": Vector2(76.0, 34.0), "color": Color(0.93, 0.43, 0.25)},
]

var _built := false
var _car_script := preload("res://scripts/parked_car.gd")

func _ready() -> void:
	build_level()
	queue_redraw()

func build_level() -> void:
	if _built:
		return

	for wall in _get_wall_rects():
		_add_static_rect("Boundary", wall)

	for block in corner_blocks:
		_add_static_rect("CityBlock", block)

	for car_data in car_specs:
		var car := _car_script.new()
		car.position = car_data["position"]
		car.rotation = car_data["rotation"]
		car.car_size = car_data["size"]
		car.body_color = car_data["color"]
		add_child(car)

	_built = true

func _add_static_rect(name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = name
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.position + rect.size * 0.5
	body.add_child(shape)
	add_child(body)

func _get_wall_rects() -> Array[Rect2]:
	return [
		Rect2(PLAY_AREA.position.x - 36.0, PLAY_AREA.position.y - 36.0, PLAY_AREA.size.x + 72.0, 36.0),
		Rect2(PLAY_AREA.position.x - 36.0, PLAY_AREA.end.y, PLAY_AREA.size.x + 72.0, 36.0),
		Rect2(PLAY_AREA.position.x - 36.0, PLAY_AREA.position.y, 36.0, PLAY_AREA.size.y),
		Rect2(PLAY_AREA.end.x, PLAY_AREA.position.y, 36.0, PLAY_AREA.size.y),
	]

func get_play_area() -> Rect2:
	return PLAY_AREA

func get_road_rects() -> Array[Rect2]:
	return road_rects.duplicate()

func get_spawn_point() -> Vector2:
	return Vector2(-760.0, 0.0)

func get_spawn_rotation() -> float:
	return 0.0

func is_in_dump_zone(point: Vector2) -> bool:
	for zone in dump_zones:
		if zone.has_point(point):
			return true
	return false

func get_steer_grip(point: Vector2) -> float:
	for zone in black_ice_zones:
		if zone.has_point(point):
			return 0.38
	return 1.0

func _draw() -> void:
	draw_rect(Rect2(-1600.0, -1100.0, 3200.0, 2200.0), Color(0.02, 0.05, 0.08), true)
	draw_rect(PLAY_AREA, Color(0.05, 0.08, 0.12), true)

	for block in corner_blocks:
		draw_rect(block, Color(0.09, 0.12, 0.17), true)
		_draw_building_windows(block)

	for road in road_rects:
		draw_rect(road, Color(0.13, 0.15, 0.18), true)
		draw_rect(road.grow(-10.0), Color(0.11, 0.13, 0.16), false, 2.0)

	_draw_lane_markings()
	_draw_dump_zones()
	_draw_black_ice()
	_draw_neon_reflections()

func _draw_building_windows(block: Rect2) -> void:
	var start_x := block.position.x + 30.0
	var end_x := block.end.x - 18.0
	var start_y := block.position.y + 26.0
	var end_y := block.end.y - 16.0
	var toggle := 0
	var x := start_x
	while x < end_x:
		var y := start_y
		while y < end_y:
			if toggle % 3 != 0:
				var glow := Color(0.18, 0.81, 0.92, 0.26)
				if toggle % 4 == 0:
					glow = Color(1.0, 0.56, 0.14, 0.22)
				draw_rect(Rect2(x, y, 16.0, 9.0), glow, true)
			toggle += 1
			y += 22.0
		x += 26.0

func _draw_lane_markings() -> void:
	var dash_color := Color(0.77, 0.79, 0.83, 0.22)
	var x := PLAY_AREA.position.x + 36.0
	while x < PLAY_AREA.end.x - 36.0:
		draw_rect(Rect2(x, -6.0, 38.0, 12.0), dash_color, true)
		x += 78.0

	var y := PLAY_AREA.position.y + 34.0
	while y < PLAY_AREA.end.y - 34.0:
		draw_rect(Rect2(-6.0, y, 12.0, 42.0), dash_color, true)
		y += 84.0

func _draw_dump_zones() -> void:
	for zone in dump_zones:
		draw_rect(zone, Color(0.10, 0.17, 0.23), true)
		draw_rect(zone.grow(-6.0), Color(0.25, 0.61, 0.83, 0.25), false, 3.0)
		var stripe_axis := "horizontal"
		if zone.size.x < zone.size.y:
			stripe_axis = "vertical"

		if stripe_axis == "horizontal":
			var x := zone.position.x + 10.0
			while x < zone.end.x - 8.0:
				draw_line(Vector2(x, zone.position.y + 12.0), Vector2(x + 22.0, zone.end.y - 12.0), Color(0.98, 0.86, 0.19, 0.65), 3.0)
				x += 38.0
		else:
			var y := zone.position.y + 10.0
			while y < zone.end.y - 8.0:
				draw_line(Vector2(zone.position.x + 12.0, y), Vector2(zone.end.x - 12.0, y + 22.0), Color(0.98, 0.86, 0.19, 0.65), 3.0)
				y += 36.0

func _draw_black_ice() -> void:
	for patch in black_ice_zones:
		draw_rect(patch, Color(0.48, 0.80, 0.95, 0.12), true)
		draw_rect(patch.grow(-4.0), Color(0.65, 0.90, 1.0, 0.18), false, 2.0)

func _draw_neon_reflections() -> void:
	draw_line(Vector2(-900.0, -154.0), Vector2(900.0, -154.0), Color(0.24, 0.88, 0.98, 0.10), 10.0)
	draw_line(Vector2(-900.0, 154.0), Vector2(900.0, 154.0), Color(1.0, 0.58, 0.16, 0.08), 10.0)
	draw_line(Vector2(-194.0, -520.0), Vector2(-194.0, 520.0), Color(0.24, 0.88, 0.98, 0.08), 10.0)
	draw_line(Vector2(194.0, -520.0), Vector2(194.0, 520.0), Color(1.0, 0.58, 0.16, 0.08), 10.0)

