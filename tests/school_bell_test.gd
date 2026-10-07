extends SceneTree

const Bell = preload("res://scripts/school/school_bell.gd")
var failures := 0
var transitions: Array[bool] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)


func _run() -> void:
	var bell := Bell.new()
	bell.auto_start = false
	bell.debug_transitions = true
	root.add_child(bell)
	bell.set_process(false)
	bell.bell_state_changed.connect(func(snapshot: Bell.BellSnapshot) -> void:
		transitions.append(snapshot.active)
		_check(bell.bell_active == snapshot.active, "State must be committed before publication")
	)
	_check(not bell.bell_active, "Initial inactive state")
	bell.stop_scheduling()
	_check(transitions.is_empty(), "No initial/redundant false publication")
	bell.start_scheduling()
	var first_wait := bell._remaining
	_check(first_wait >= 30 and first_wait <= 60, "Initial wait in configured bounds")
	bell.start_scheduling()
	_check(bell._remaining == first_wait, "Repeated start must not reroll")
	bell.set_objective_progress(6)
	_check(bell.get_interval_bounds().is_equal_approx(Vector2(15, 30)), "Progress reduces both future bounds")
	_check(bell._remaining == first_wait, "Progress must not reroll current wait")
	_check(bell.get_bell_snapshot().remaining_seconds == 0, "Inactive snapshot hides next deadline")
	bell._process(first_wait - 0.01)
	_check(transitions.is_empty(), "No early Bell")
	bell._process(0.02)
	_check(transitions == [true], "Exactly one start")
	var snapshot := bell.get_bell_snapshot()
	snapshot.active = false
	_check(bell.bell_active, "Snapshot mutation cannot mutate authority")
	bell._process(9.9)
	_check(transitions == [true], "Duration respected")
	bell._process(0.2)
	_check(transitions == [true, false], "Exactly one end")
	_check(bell._remaining >= 15 and bell._remaining <= 30, "Next wait uses progress")
	var samples := {}
	for i in range(50):
		samples[bell._remaining] = true
		bell._process(bell._remaining + 0.01)
		bell._process(10.01)
	_check(samples.size() > 1, "Future intervals must vary")
	for i in range(transitions.size()):
		_check(transitions[i] == (i % 2 == 0), "Transitions must alternate without duplicates")
	bell._process(10000)
	_check(bell.bell_active, "Hitch preserves full visible Bell phase")
	bell.stop_scheduling()
	var count := transitions.size()
	bell.stop_scheduling()
	bell._process(10000)
	_check(transitions.size() == count, "Stop ends active Bell once and cancels schedule")
	bell.minimum_interval = -5
	bell.maximum_interval = -10
	bell.bell_duration = -1
	bell.set_objective_progress(-1)
	_check(bell.get_bell_snapshot().progression_index == 0, "Negative progress clamped")
	var bounds := bell.get_interval_bounds()
	_check(bounds.x > 0 and bounds.y > bounds.x, "Invalid timing remains positive and randomized")
	bell.start_scheduling()
	bell._process(100)
	_check(bell.get_bell_snapshot().remaining_seconds > 0, "Invalid duration clamped")
	bell.stop_scheduling()
	# Real engine-driven scheduling and pause semantics, without manual time stepping.
	bell.minimum_interval = 0.05
	bell.maximum_interval = 0.1
	bell.bell_duration = 0.05
	bell.set_process(true)
	bell.start_scheduling()
	paused = true
	var paused_remaining := bell._remaining
	await create_timer(0.15, true).timeout
	_check(bell._remaining == paused_remaining, "SceneTree pause must freeze scheduler")
	paused = false
	count = transitions.size()
	await create_timer(0.5).timeout
	_check(transitions.size() >= count + 2, "Engine processing produces full cycles")
	bell.stop_scheduling()
	bell.queue_free()
	print("School Bell tests: %d transitions, %d failures" % [transitions.size(), failures])
	quit(1 if failures else 0)
