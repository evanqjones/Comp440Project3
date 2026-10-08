extends CharacterBody3D
class_name PlayerSystem

# Temporary tuning only: exact stamina values/policy remain OPEN in GAME_SPEC.md.
@export_group("Provisional Stamina")
@export_range(1.0, 1000.0, 1.0) var stamina_capacity: float = 100.0
@export_range(0.0, 100.0, 0.5) var stamina_drain_rate: float = 20.0
@export_range(0.0, 100.0, 0.5) var stamina_regeneration_rate: float = 15.0
@export_range(0.01, 1.0, 0.01) var stamina_recovery_fraction: float = 0.25
@export_range(0.0, 10.0, 0.05) var stamina_regeneration_delay: float = 0.75

# Read the body's live 3D position instead of maintaining a second location.
var current_location: Vector3:
	get:
		return get_world_position()

var movement_state: StringName:
	get:
		return _movement_state

var _movement_state: StringName = &"idle"
var _stamina: float = 0.0
var _stamina_exhausted: bool = false
var _stamina_regeneration_delay_remaining: float = 0.0


func _ready() -> void:
	_stamina = stamina_capacity


func _can_sprint(has_directional_input: bool) -> bool:
	return has_directional_input and _stamina > 0.0 and not _stamina_exhausted


func _update_stamina(delta: float) -> void:
	# Movement state is measured after collision resolution, so holding Shift
	# while idle or fully blocked does not drain stamina or restart the delay.
	if _movement_state == &"running":
		_stamina = maxf(0.0, _stamina - stamina_drain_rate * delta)
		_stamina_regeneration_delay_remaining = stamina_regeneration_delay
		if is_zero_approx(_stamina):
			_stamina = 0.0
			_stamina_exhausted = true
		return

	# Provisional policy: recover while walking/idle, even with Shift held.
	# After exhaustion, sprint unlocks at the configured capacity fraction;
	# held Shift may resume sprint automatically once that threshold is met.
	var regeneration_delta := maxf(0.0, delta - _stamina_regeneration_delay_remaining)
	_stamina_regeneration_delay_remaining = maxf(0.0, _stamina_regeneration_delay_remaining - delta)
	_stamina = minf(stamina_capacity, _stamina + stamina_regeneration_rate * regeneration_delta)
	if _stamina_exhausted and _stamina >= stamina_capacity * stamina_recovery_fraction:
		_stamina_exhausted = false


func get_world_position() -> Vector3:
	return global_position


func _update_movement_state(is_running: bool) -> void:
	# Call after move_and_slide(): walls and gravity alone must not count as walking.
	var real_velocity := get_real_velocity()
	var horizontal_speed_squared := Vector2(real_velocity.x, real_velocity.z).length_squared()

	if horizontal_speed_squared <= 0.0001:
		_movement_state = &"idle"
	elif is_running:
		_movement_state = &"running"
	else:
		_movement_state = &"walking"
