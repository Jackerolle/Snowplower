extends StaticBody2D

var car_size := Vector2(76.0, 34.0)
var body_color := Color(0.82, 0.32, 0.28)

func _ready() -> void:
	add_to_group("parked_car")

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = car_size
	shape.shape = rectangle
	add_child(shape)
	queue_redraw()

func _draw() -> void:
	var body_rect := Rect2(-car_size * 0.5, car_size)
	var roof_rect := body_rect.grow_individual(-14.0, -7.0, -14.0, -7.0)
	draw_rect(Rect2(body_rect.position + Vector2(4.0, 4.0), body_rect.size), Color(0.0, 0.0, 0.0, 0.18), true)
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect.grow(-2.0), body_color.darkened(0.18), false, 2.0)
	draw_rect(roof_rect, Color(0.90, 0.95, 1.0, 0.68), true)
	draw_rect(Rect2(body_rect.position.x + 6.0, body_rect.position.y + 5.0, 10.0, body_rect.size.y - 10.0), Color(1.0, 0.94, 0.72, 0.9), true)
	draw_rect(Rect2(body_rect.end.x - 16.0, body_rect.position.y + 5.0, 10.0, body_rect.size.y - 10.0), Color(1.0, 0.33, 0.21, 0.85), true)
