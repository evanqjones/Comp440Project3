extends AudioStreamPlayer
## Audible presentation only; Monster detection still uses the player's NoiseEvent.

signal step_played

const STEPS = [
	preload("res://assets/audio/footsteps/concrete_01.wav"),
	preload("res://assets/audio/footsteps/concrete_02.wav"),
	preload("res://assets/audio/footsteps/concrete_03.wav"),
	preload("res://assets/audio/footsteps/concrete_04.wav"),
	preload("res://assets/audio/footsteps/concrete_05.wav"),
	preload("res://assets/audio/footsteps/concrete_06.wav"),
]

@export var walk_step_distance: float = 1.7
@export var run_step_distance: float = 1.9
@export var sneak_step_distance: float = 1.8
@export var walk_volume_db: float = -10.0
@export var run_volume_db: float = -6.0
@export var sneak_volume_db: float = -22.0

var _distance := 0.0
var _moving := false
var _last_step := -1
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	_random.randomize()
	max_polyphony = 2

func update_movement(distance: float, can_step: bool, sprinting: bool, sneaking: bool) -> void:
	if not can_step or distance <= 0.0:
		reset_steps()
		return
	var spacing := sneak_step_distance if sneaking else (run_step_distance if sprinting else walk_step_distance)
	_distance += distance
	if not _moving or _distance >= maxf(spacing, 0.1):
		_distance = 0.0
		var index := _random.randi_range(0, STEPS.size() - 2)
		if index >= _last_step:
			index += 1
		_last_step = index
		stream = STEPS[index]
		volume_db = sneak_volume_db if sneaking else (run_volume_db if sprinting else walk_volume_db)
		pitch_scale = _random.randf_range(0.97, 1.03)
		play()
		step_played.emit()
	_moving = true

func reset_steps() -> void:
	_distance = 0.0
	_moving = false
	stop()
