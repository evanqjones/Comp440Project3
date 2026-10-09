class_name SchoolBell
extends Node
## School-owned scheduler. No actor, UI, audio, or scene-tree dependencies.

class BellSnapshot extends RefCounted:
	var active: bool = false
	var final_escape: bool = false
	var remaining_seconds: float = 0.0
	var progression_index: int = 0
	var active_safe_room_ids: Array[StringName] = []

signal bell_state_changed(snapshot: BellSnapshot)

@export_group("Provisional timing (seconds)")
@export_range(0.05, 600.0, 0.05, "or_greater") var minimum_interval: float = 30.0
@export_range(0.05, 600.0, 0.05, "or_greater") var maximum_interval: float = 60.0
@export_range(0.05, 120.0, 0.05, "or_greater") var bell_duration: float = 10.0
@export_group("Objective progress")
@export_range(1, 100, 1, "or_greater") var objectives_for_maximum_pressure: int = 6
@export_range(0.05, 1.0, 0.01) var completed_interval_multiplier: float = 0.5
@export_group("Lifecycle")
@export var auto_start: bool = true
@export var debug_transitions: bool = false

var bell_active: bool:
	get:
		return _active

var _active: bool = false
var _running: bool = false
var _remaining: float = 0.0
var _progress: int = 0
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	if auto_start:
		start_scheduling()


func _process(delta: float) -> void:
	if not _running:
		return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining > 0.0:
		return
	# One transition per frame: a hitch never consumes a whole Bell invisibly.
	# Commit the next phase before notification, so listeners can safely stop us.
	if _active:
		_schedule_next()
		_publish(false)
	else:
		_remaining = _positive(bell_duration, 10.0)
		_publish(true)


func start_scheduling() -> void:
	if _running:
		return
	_running = true
	_schedule_next()


func stop_scheduling() -> void:
	_running = false
	_remaining = 0.0
	_publish(false)


func start_guaranteed_bell() -> void:
	_running = true
	_remaining = _positive(bell_duration, 10.0)
	_publish(true)


func set_objective_progress(completed_objectives: int) -> void:
	_progress = maxi(0, completed_objectives)
	# Do not reroll the current interval or alter an already active Bell.


func get_bell_snapshot() -> BellSnapshot:
	var snapshot := BellSnapshot.new()
	snapshot.active = _active
	snapshot.remaining_seconds = _remaining if _active else 0.0
	snapshot.progression_index = _progress
	return snapshot


func get_interval_bounds() -> Vector2:
	var low := _positive(minimum_interval, 30.0)
	var high := _positive(maximum_interval, 60.0)
	var lower := minf(low, high)
	var upper := maxf(low, high)
	var progress_fraction := clampf(float(_progress) / maxi(1, objectives_for_maximum_pressure), 0.0, 1.0)
	var multiplier := completed_interval_multiplier if is_finite(completed_interval_multiplier) else 0.5
	var scale := lerpf(1.0, clampf(multiplier, 0.05, 1.0), progress_fraction)
	lower = maxf(0.05, lower * scale)
	upper = maxf(lower + 0.05, upper * scale)
	return Vector2(lower, upper)


func _schedule_next() -> void:
	var bounds := get_interval_bounds()
	_remaining = _random.randf_range(bounds.x, bounds.y)


func _publish(active: bool) -> void:
	if _active == active:
		return
	_active = active
	if debug_transitions:
		print("SchoolBell: bell_active=%s progress=%d" % [_active, _progress])
	bell_state_changed.emit(get_bell_snapshot())


func _positive(value: float, fallback: float) -> float:
	return maxf(0.05, value) if is_finite(value) else fallback
