extends CharacterBody2D

signal impact(intensity: float, obstacle_type: String)
signal scraped_car(cost: int)

const BASE_SPEED := 320.0
const MIN_SPEED_FACTOR := 0.22
const ACCELERATION := 520.0
const KEYBOARD_STEER_SPEED := 2.2
const POINTER_STEER_RESPONSE := 5.4
const LOAD_DRAG := 0.047
const STALL_LOAD := 18.0
const MAX_LOAD := 24.0
const DUMP_RATE := 10.5
const PLOW_WIDTH := 120.0
const PLOW_DEPTH := 76.0
const PLOW_OFFSET := 66.0
const SCRAPE_COOLDOWN := 0.85

var world: Node2D
var snow_field: Node2D
var active := true
var cargo_load := 0.0
var pointer_active := false
var pointer_world := Vector2.ZERO
var scrape_cooldown := 0.0
var impact_cooldown := 0.0
var rng := RandomNumberGenerator.new()
var particles: Array[Dictionary] = []

func _ready() -> void:
	rng.randomize()
	queue_redraw()

func setup(level_world: Node2D, level_snow_field: Node2D) -> void:
	world = level_world
	snow_field = level_snow_field

func set_active(value: bool) -> void:
	active = value

func get_cargo_load() -> float:
	return cargo_load

func get_load_ratio() -> float:
	return clamp(cargo_load / MAX_LOAD, 0.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_active = event.pressed
		if pointer_active:
			pointer_world = _screen_to_world(event.position)
	elif event is InputEventMouseMotion and pointer_active:
		pointer_world = _screen_to_world(event.position)
	elif event is InputEventScreenTouch:
		pointer_active = event.pressed
		if pointer_active:
			pointer_world = _screen_to_world(event.position)
	elif event is InputEventScreenDrag:
		pointer_active = true
		pointer_world = _screen_to_world(event.position)

func _physics_process(delta: float) -> void:
	if scrape_cooldown > 0.0:
		scrape_cooldown = max(0.0, scrape_cooldown - delta)
	if impact_cooldown > 0.0:
		impact_cooldown = max(0.0, impact_cooldown - delta)

	_update_particles(delta)

	var grip := 1.0
	if world != null:
		grip = world.get_steer_grip(global_position)

	if active:
		_apply_rotation(delta, grip)

		var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
		var load_factor: float = maxf(MIN_SPEED_FACTOR, 1.0 - cargo_load * LOAD_DRAG)
		if cargo_load >= STALL_LOAD:
			load_factor *= 0.18

		var target_velocity: Vector2 = forward * (BASE_SPEED * load_factor)
		velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)

	move_and_slide()
	_handle_collisions()

	if active:
		_process_plow(delta)

	queue_redraw()

func _apply_rotation(delta: float, grip: float) -> void:
	var steer_input := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_input -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_input += 1.0

	if pointer_active and global_position.distance_to(pointer_world) > 20.0:
		var target_angle := (pointer_world - global_position).angle()
		rotation = lerp_angle(rotation, target_angle, min(1.0, POINTER_STEER_RESPONSE * grip * delta))
	else:
		rotation += steer_input * KEYBOARD_STEER_SPEED * grip * delta

func _process_plow(delta: float) -> void:
	if snow_field == null:
		return

	var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
	var blade_center: Vector2 = global_position + forward * PLOW_OFFSET
	var removed: float = snow_field.plow(blade_center, forward, PLOW_WIDTH, PLOW_DEPTH, delta)
	if removed > 0.0:
		cargo_load = min(MAX_LOAD * 1.35, cargo_load + removed)
		_spawn_spray(blade_center, forward, removed)

	if world != null and world.is_in_dump_zone(global_position):
		var dumped: float = minf(cargo_load, DUMP_RATE * delta)
		if dumped > 0.0:
			cargo_load -= dumped
			_spawn_dump(blade_center, forward, dumped)

func _handle_collisions() -> void:
	if get_slide_collision_count() == 0:
		return

	for collision_index in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider()
		var normal_alignment: float = absf(collision.get_normal().dot(-Vector2.RIGHT.rotated(rotation)))
		var intensity: float = clampf((velocity.length() / BASE_SPEED) * maxf(0.25, normal_alignment), 0.0, 1.0)
		var obstacle_type := "wall"

		if collider is Node and collider.is_in_group("parked_car"):
			obstacle_type = "parked_car"
			if scrape_cooldown <= 0.0:
				scraped_car.emit(50)
				scrape_cooldown = SCRAPE_COOLDOWN

		if intensity >= 0.18 and (impact_cooldown <= 0.0 or obstacle_type == "parked_car"):
			impact.emit(intensity, obstacle_type)
			impact_cooldown = 0.12

func _spawn_spray(blade_center: Vector2, forward: Vector2, amount: float) -> void:
	var side := forward.orthogonal()
	var particle_count := clampi(int(ceil(amount * 7.0)), 2, 10)
	for i in range(particle_count):
		var sign := -1.0
		if i % 2 == 1:
			sign = 1.0

		var spawn_position: Vector2 = blade_center + side * sign * (PLOW_WIDTH * 0.45)
		var velocity_vector: Vector2 = side * sign * rng.randf_range(90.0, 180.0)
		velocity_vector += -forward * rng.randf_range(18.0, 66.0)
		particles.append({
			"position": spawn_position,
			"velocity": velocity_vector,
			"life": rng.randf_range(0.25, 0.48),
			"max_life": rng.randf_range(0.25, 0.48),
			"radius": rng.randf_range(1.8, 4.4),
			"color": Color(0.95, 0.97, 1.0, 0.92),
		})

func _spawn_dump(blade_center: Vector2, forward: Vector2, amount: float) -> void:
	var particle_count := clampi(int(ceil(amount * 3.0)), 1, 6)
	for _i in range(particle_count):
		particles.append({
			"position": blade_center + forward * rng.randf_range(8.0, 18.0),
			"velocity": Vector2(rng.randf_range(-40.0, 40.0), rng.randf_range(-20.0, 20.0)),
			"life": rng.randf_range(0.18, 0.34),
			"max_life": rng.randf_range(0.18, 0.34),
			"radius": rng.randf_range(1.2, 3.0),
			"color": Color(0.85, 0.94, 1.0, 0.8),
		})

func _update_particles(delta: float) -> void:
	for index in range(particles.size() - 1, -1, -1):
		var particle := particles[index]
		particle["position"] += particle["velocity"] * delta
		particle["velocity"] *= 0.90
		particle["life"] -= delta
		particles[index] = particle
		if particle["life"] <= 0.0:
			particles.remove_at(index)

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position

func _draw() -> void:
	for particle in particles:
		var life_ratio: float = particle["life"] / particle["max_life"]
		var particle_color: Color = particle["color"]
		particle_color.a *= life_ratio
		draw_circle(to_local(particle["position"]), particle["radius"] * life_ratio, particle_color)

	var shadow_offset := Vector2(7.0, 7.0)
	draw_rect(Rect2(Vector2(-42.0, -24.0) + shadow_offset, Vector2(84.0, 48.0)), Color(0.0, 0.0, 0.0, 0.22), true)
	draw_rect(Rect2(Vector2(-18.0, -28.0) + shadow_offset, Vector2(78.0, 56.0)), Color(0.0, 0.0, 0.0, 0.18), true)

	var body_rect := Rect2(-42.0, -24.0, 84.0, 48.0)
	var cabin_rect := Rect2(-2.0, -28.0, 56.0, 56.0)
	var blade_rect := Rect2(48.0, -34.0, 14.0, 68.0)
	draw_rect(body_rect, Color(0.91, 0.50, 0.12), true)
	draw_rect(body_rect.grow(-2.0), Color(0.75, 0.37, 0.10), false, 2.0)
	draw_rect(cabin_rect, Color(0.97, 0.61, 0.17), true)
	draw_rect(cabin_rect.grow(-2.0), Color(0.91, 0.88, 0.79, 0.85), false, 2.0)
	draw_rect(blade_rect, Color(0.85, 0.90, 0.97), true)
	draw_rect(blade_rect.grow(-2.0), Color(0.42, 0.72, 0.95, 0.8), false, 2.0)
	draw_rect(Rect2(-28.0, -28.0, 18.0, 56.0), Color(0.09, 0.10, 0.12, 0.95), true)
	draw_rect(Rect2(8.0, -22.0, 22.0, 44.0), Color(0.82, 0.90, 0.97, 0.65), true)
	draw_rect(Rect2(34.0, -22.0, 10.0, 44.0), Color(1.0, 0.90, 0.62, 0.85), true)
	draw_circle(Vector2(56.0, -18.0), 3.0, Color(0.42, 0.84, 1.0, 0.95))
	draw_circle(Vector2(56.0, 18.0), 3.0, Color(0.42, 0.84, 1.0, 0.95))

	if cargo_load > 0.2:
		var load_ratio: float = clampf(cargo_load / STALL_LOAD, 0.0, 1.0)
		var spread: float = 16.0 + load_ratio * 16.0
		var load_points := PackedVector2Array([
			Vector2(46.0, -spread),
			Vector2(84.0 + load_ratio * 24.0, 0.0),
			Vector2(46.0, spread),
		])
		draw_colored_polygon(load_points, Color(0.95, 0.98, 1.0, 0.88))
		draw_polyline(load_points, Color(0.70, 0.86, 0.98, 0.95), 3.0, true)
