extends Camera2D

var target: Node2D
var shake_strength := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func setup(follow_target: Node2D) -> void:
	target = follow_target
	global_position = follow_target.global_position

func add_shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)

func _process(delta: float) -> void:
	if target != null:
		global_position = global_position.lerp(target.global_position, 1.0 - exp(-6.0 * delta))

	var desired_offset := Vector2.ZERO
	if shake_strength > 0.01:
		desired_offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * shake_strength * 18.0
		shake_strength = max(0.0, shake_strength - 4.2 * delta)

	offset = offset.lerp(desired_offset, 1.0 - exp(-20.0 * delta))
