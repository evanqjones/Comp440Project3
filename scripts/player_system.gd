extends CharacterBody3D
class_name PlayerSystem

signal interaction_requested(target_id: StringName)
# Player-internal presentation event; not a shared School/Monster contract.
signal stamina_state_changed(current: float, capacity: float, exhausted: bool)

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

var stamina_current: float:
	get:
		return _stamina

var stamina_exhausted: bool:
	get:
		return _stamina_exhausted

var capture_presentation_active: bool:
	get:
		return _capture_presentation_active

var _movement_state: StringName = &"idle"
var _input_enabled: bool = true
var _capture_presentation_active: bool = false
var _capture_checkpoint_id: StringName = &""
var _stamina: float = 0.0
var _stamina_exhausted: bool = false
var _stamina_regeneration_delay_remaining: float = 0.0
var _published_stamina: float = -1.0
var _published_stamina_capacity: float = -1.0
var _published_stamina_exhausted: bool = false


func _ready() -> void:
	_stamina = stamina_capacity
	_publish_stamina_state()


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
		_publish_stamina_state()
		return

	# Provisional policy: recover while walking/idle, even with Shift held.
	# After exhaustion, sprint unlocks at the configured capacity fraction;
	# held Shift may resume sprint automatically once that threshold is met.
	var regeneration_delta := maxf(0.0, delta - _stamina_regeneration_delay_remaining)
	_stamina_regeneration_delay_remaining = maxf(0.0, _stamina_regeneration_delay_remaining - delta)
	_stamina = minf(stamina_capacity, _stamina + stamina_regeneration_rate * regeneration_delta)
	if _stamina_exhausted and _stamina >= stamina_capacity * stamina_recovery_fraction:
		_stamina_exhausted = false
	_publish_stamina_state()


func _publish_stamina_state() -> void:
	if (_published_stamina == _stamina and _published_stamina_capacity == stamina_capacity
			and _published_stamina_exhausted == _stamina_exhausted):
		return
	_published_stamina = _stamina
	_published_stamina_capacity = stamina_capacity
	_published_stamina_exhausted = _stamina_exhausted
	stamina_state_changed.emit(_stamina, stamina_capacity, _stamina_exhausted)


func get_world_position() -> Vector3:
	return global_position


func get_current_room_id() -> StringName:
	# Unresolved until School/integration provides its authoritative room lookup.
	# Do not infer a room from preview geometry or invent a fallback room name.
	return &""


func set_input_enabled(enabled: bool) -> void:
	# No resume until authoritative restoration is wired; never bypass capture.
	if enabled and _capture_presentation_active:
		return
	_input_enabled = enabled


func play_capture_and_respawn(checkpoint_id: StringName) -> void:
	if _capture_presentation_active or String(checkpoint_id).strip_edges().is_empty():
		return
	_capture_checkpoint_id = checkpoint_id
	_capture_presentation_active = true
	set_input_enabled(false)
	# Stay disabled until the integrating scene supplies a restored position.


func restore_after_capture(world_position: Vector3, checkpoint_id: StringName) -> void:
	global_position = world_position
	velocity = Vector3.ZERO
	_capture_checkpoint_id = checkpoint_id
	_capture_presentation_active = false
	_input_enabled = true
	_movement_state = &"idle"


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
