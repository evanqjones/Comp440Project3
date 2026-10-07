extends SceneTree

var failures := 0
var completions: Array[StringName] = []
var failures_seen: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func _run() -> void:
	var school = load("res://scenes/school_foundation.tscn").instantiate()
	root.add_child(school)
	var events = school.get_node("RoomEvents")
	events.watch_reaction_grace = 0.0
	events.set_physics_process(false)
	var actor := Node3D.new()
	root.add_child(actor)
	events.bind_environment(school, actor)
	events.challenge_completed.connect(func(id: StringName, _reward: StringName) -> void: completions.append(id))
	events.challenge_failed.connect(func(_id: StringName, reason: StringName) -> void: failures_seen.append(reason))
	# Fixture moves only the test actor. School challenge code never moves actors.
	actor.position = school.get_cell_position(school.layout.library_checkpoints[0])
	events._physics_process(0.016)
	_check(events.get_challenge_snapshot(&"library_maze").state == &"active", "Library starts at entry")
	actor.position = school.get_cell_position(school.layout.library_checkpoints[-1])
	_check(not events.request_reward(&"library_maze"), "Shortcut cannot bypass maze checkpoints")
	for cell: Vector2i in school.layout.library_checkpoints:
		actor.position = school.get_cell_position(cell)
		events._physics_process(0.016)
	_check(events.request_reward(&"library_maze"), "Ordered maze completion unlocks book")
	_check(not events.request_reward(&"library_maze"), "No duplicate book completion")
	events.report_player_caught(&"library")
	_check(events.get_challenge_snapshot(&"library_maze").state == &"completed", "Capture does not undo awarded challenge")
	actor.position = school.get_cell_position(school.layout.science_entry)
	events.report_lab_watch_state(true)
	events._physics_process(0.016)
	var original: Vector3 = actor.position
	actor.position.x += 0.2
	events._physics_process(0.016)
	_check(failures_seen == [&"moved_while_watched"], "Moving while watched fails exactly once")
	_check(is_equal_approx(actor.position.x, original.x + 0.2), "Failure must not teleport player")
	events._physics_process(0.016)
	_check(failures_seen.size() == 1, "Failed challenge must not spam events")
	actor.position = school.get_cell_position(school.layout.science_goal)
	_check(not events.request_retry(&"science_stillness"), "Retry requires return to start")
	_check(not events.request_reward(&"science_stillness"), "Failed attempt cannot collect")
	actor.position = school.get_cell_position(school.layout.science_entry)
	_check(events.request_retry(&"science_stillness"), "Retry at entry resets challenge")
	events.report_lab_watch_state(true)
	events._physics_process(0.016)
	events._physics_process(0.1)
	_check(events.get_challenge_snapshot(&"science_stillness").state == &"active", "Standing still while watched is valid")
	events.report_lab_watch_state(false)
	actor.position = school.get_cell_position(school.layout.science_goal)
	events._physics_process(0.016)
	events._physics_process(1.0)
	_check(not events.request_reward(&"science_stillness"), "Stale watch report must not permit collection")
	events.report_lab_watch_state(false)
	_check(events.request_reward(&"science_stillness"), "Looking away permits lab coat collection")
	_check(completions == [&"library_maze", &"science_stillness"], "Exactly one completion per reward")
	# New instance verifies capture abort and leaving-room reset before reward.
	var other = load("res://scripts/school/school_room_events.gd").new()
	root.add_child(other)
	other.set_physics_process(false)
	other.bind_environment(school, actor)
	actor.position = school.get_cell_position(school.layout.library_checkpoints[0])
	other._physics_process(0.016)
	other.report_player_caught(&"library")
	_check(other.get_challenge_snapshot(&"library_maze").state == &"failed", "External capture aborts maze")
	_check(other.request_retry(&"library_maze"), "Maze retry allowed at start")
	actor.position = school.get_entrance_position()
	other._physics_process(0.016)
	_check(other.get_challenge_snapshot(&"library_maze").state == &"failed", "Leaving challenge resets attempt")
	print("School room events: %d rewards, %d failures" % [completions.size(), failures])
	quit(1 if failures else 0)
