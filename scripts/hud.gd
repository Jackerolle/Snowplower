extends Control

var truck: CharacterBody2D
var snow_field: Node2D
var game: Node2D

func setup(level_truck: CharacterBody2D, level_snow_field: Node2D, level_game: Node2D) -> void:
	truck = level_truck
	snow_field = level_snow_field
	game = level_game

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	if font == null or truck == null or snow_field == null or game == null:
		return

	var progress: float = snow_field.get_clear_ratio()
	var target: float = game.get_clear_target()
	var load_ratio: float = truck.get_load_ratio()
	var state: String = game.get_shift_state()
	var top_bar_rect := Rect2(36.0, 24.0, size.x - 72.0, 26.0)
	draw_rect(Rect2(20.0, 16.0, size.x - 40.0, 80.0), Color(0.02, 0.05, 0.08, 0.52), true)
	draw_rect(top_bar_rect, Color(0.14, 0.18, 0.23, 0.95), true)
	draw_rect(Rect2(top_bar_rect.position, Vector2(top_bar_rect.size.x * progress, top_bar_rect.size.y)), Color(0.24, 0.80, 0.94, 0.95), true)
	draw_line(Vector2(top_bar_rect.position.x + top_bar_rect.size.x * target, top_bar_rect.position.y - 6.0), Vector2(top_bar_rect.position.x + top_bar_rect.size.x * target, top_bar_rect.end.y + 6.0), Color(1.0, 0.85, 0.20, 0.95), 3.0)
	draw_string(font, Vector2(36.0, 88.0), "CLEARING %d%% / %d%%" % [int(round(progress * 100.0)), int(round(target * 100.0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(0.95, 0.98, 1.0))

	var side_panel := Rect2(24.0, size.y - 188.0, 330.0, 152.0)
	var right_panel := Rect2(size.x - 330.0, size.y - 188.0, 306.0, 152.0)
	draw_rect(side_panel, Color(0.02, 0.05, 0.08, 0.66), true)
	draw_rect(right_panel, Color(0.02, 0.05, 0.08, 0.66), true)

	draw_string(font, Vector2(side_panel.position.x + 18.0, side_panel.position.y + 34.0), "PLOW LOAD", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.82, 0.90, 0.97))
	var load_bar := Rect2(side_panel.position.x + 18.0, side_panel.position.y + 50.0, side_panel.size.x - 36.0, 18.0)
	draw_rect(load_bar, Color(0.12, 0.16, 0.20, 0.95), true)
	var load_color := Color(0.38, 0.86, 0.96, 0.95)
	if load_ratio > 0.70:
		load_color = Color(1.0, 0.61, 0.16, 0.95)
	draw_rect(Rect2(load_bar.position, Vector2(load_bar.size.x * load_ratio, load_bar.size.y)), load_color, true)
	draw_string(font, Vector2(side_panel.position.x + 18.0, side_panel.position.y + 96.0), "Stored snow: %.1f" % truck.get_cargo_load(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.92, 0.95, 1.0))
	draw_string(font, Vector2(side_panel.position.x + 18.0, side_panel.position.y + 126.0), "Dump zones vent the blade load.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.75, 0.82, 0.90))

	var time_text := _format_time(game.get_shift_time_left())
	draw_string(font, Vector2(right_panel.position.x + 18.0, right_panel.position.y + 34.0), "SHIFT CLOCK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.82, 0.90, 0.97))
	draw_string(font, Vector2(right_panel.position.x + 18.0, right_panel.position.y + 72.0), time_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 36, Color(0.98, 0.86, 0.20))
	draw_string(font, Vector2(right_panel.position.x + 18.0, right_panel.position.y + 106.0), "Damage penalties: $%d" % game.get_damage_costs(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.96, 0.73, 0.73))
	draw_string(font, Vector2(right_panel.position.x + 18.0, right_panel.position.y + 132.0), "Steer with A/D or drag. R restarts after shift end.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.75, 0.82, 0.90))

	if state != "playing":
		var banner := Rect2(size.x * 0.5 - 280.0, size.y * 0.5 - 92.0, 560.0, 184.0)
		draw_rect(banner, Color(0.02, 0.05, 0.08, 0.84), true)
		draw_rect(banner.grow(-4.0), Color(0.18, 0.62, 0.82, 0.28), false, 3.0)
		var title := "SHIFT COMPLETE"
		var subtitle := "Payout: $%d" % game.get_payout()
		if state == "failed":
			title = "MORNING TRAFFIC WON"
			subtitle = "Clear 90%% before the shift timer expires."

		draw_string(font, Vector2(banner.position.x + 40.0, banner.position.y + 70.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 34, Color(0.95, 0.98, 1.0))
		draw_string(font, Vector2(banner.position.x + 40.0, banner.position.y + 116.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(0.98, 0.86, 0.20))
		draw_string(font, Vector2(banner.position.x + 40.0, banner.position.y + 150.0), "Press R to run another shift.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.76, 0.84, 0.91))

func _format_time(seconds_left: float) -> String:
	var total_seconds := int(ceil(max(0.0, seconds_left)))
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
