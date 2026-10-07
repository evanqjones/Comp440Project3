extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	_check(main_path == "res://scenes/school_system_demo.tscn", "F5 must launch the School demo")
	var demo = load(main_path).instantiate()
	root.add_child(demo)
	await physics_frame
	await physics_frame
	var bell = demo.bell
	bell.set_process(false)
	_check(demo.player.get_node("CameraPivot/SpringArm3D/Camera3D").current, "Existing player camera must be active")
	_check(demo.school.get_current_room_id() == &"entrance", "Player must start inside entrance")
	_check(demo.room_label.text == "Room: Entrance", "Room must be visible")
	_check(demo.bell_label.text == "Bell quiet", "Initial Bell state must be visible")
	bell._process(11.0)
	_check(demo.bell_label.text == "BELL ACTIVE", "Bell start must update visible status")
	bell._process(4.1)
	_check(demo.bell_label.text == "Bell quiet", "Bell end must update visible status")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_P
	for i in range(6):
		demo._unhandled_input(key)
	_check(bell.get_bell_snapshot().progression_index == 6, "Demo input must reach School Bell")
	_check(bell.get_interval_bounds().is_equal_approx(Vector2(2.5, 5)), "Demo progress scales future bounds")
	demo.player.position = Vector3(6, 0.05, 6)
	await physics_frame
	await physics_frame
	_check(demo.room_label.text == "Room: Classroom 101", "Walking between rooms must update overlay")
	key.keycode = KEY_R
	demo._unhandled_input(key)
	_check(bell.get_bell_snapshot().progression_index == 0, "Demo reset must clear test progress")
	print("School demo integration: %d failures" % failures)
	quit(1 if failures else 0)
