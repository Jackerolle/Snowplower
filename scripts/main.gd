extends Node2D

const CLEAR_TARGET := 0.90
const SHIFT_DURATION := 210.0
const BASE_REWARD := 450

@onready var world: Node2D = $World
@onready var snow_field: Node2D = $SnowField
@onready var truck: CharacterBody2D = $Truck
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $CanvasLayer/HUD

var shift_state := "playing"
var shift_time_left := SHIFT_DURATION
var damage_costs := 0
var payout := 0

func _ready() -> void:
	world.build_level()
	snow_field.setup(world.get_play_area(), world.get_road_rects())
	truck.setup(world, snow_field)
	truck.global_position = world.get_spawn_point()
	truck.rotation = world.get_spawn_rotation()
	camera.setup(truck)
	hud.setup(truck, snow_field, self)
	truck.impact.connect(_on_truck_impact)
	truck.scraped_car.connect(_on_truck_scraped_car)

func _process(delta: float) -> void:
	if shift_state != "playing":
		return

	shift_time_left = max(0.0, shift_time_left - delta)
	if snow_field.get_clear_ratio() >= CLEAR_TARGET:
		_complete_shift()
	elif shift_time_left <= 0.0:
		_fail_shift()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and shift_state != "playing":
		get_tree().reload_current_scene()

func _complete_shift() -> void:
	shift_state = "completed"
	truck.set_active(false)
	payout = max(0, BASE_REWARD + int(round(shift_time_left * 2.0)) - damage_costs)

func _fail_shift() -> void:
	shift_state = "failed"
	truck.set_active(false)
	payout = 0

func _on_truck_impact(intensity: float, obstacle_type: String) -> void:
	var shake := intensity
	if obstacle_type == "parked_car":
		shake *= 1.2
	camera.add_shake(shake)

func _on_truck_scraped_car(cost: int) -> void:
	if shift_state != "playing":
		return
	damage_costs += cost

func get_shift_state() -> String:
	return shift_state

func get_shift_time_left() -> float:
	return shift_time_left

func get_damage_costs() -> int:
	return damage_costs

func get_payout() -> int:
	return payout

func get_clear_target() -> float:
	return CLEAR_TARGET

