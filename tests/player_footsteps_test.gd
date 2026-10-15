extends SceneTree

var failures := 0
var steps := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        push_error(message)

func _key(code: Key, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = pressed
    Input.parse_input_event(event)

func _frames(count: int) -> void:
    for i in count:
        await physics_frame

func _run() -> void:
    var world := Node3D.new()
    root.add_child(world)
    var floor_body := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(100, 1, 100)
    shape.shape = box
    floor_body.add_child(shape)
    floor_body.position.y = -0.5
    world.add_child(floor_body)
    var player = load("res://scenes/player_placeholder.tscn").instantiate()
    world.add_child(player)
    player.footsteps.step_played.connect(func(): steps += 1)
    await _frames(30)
    _check(steps == 0, "Idle must be silent")
    _key(KEY_W, true)
    await _frames(120)
    var walking := steps
    _check(walking >= 3, "Grounded walking plays recorded footsteps")
    _key(KEY_SHIFT, true)
    steps = 0
    await _frames(120)
    _check(steps > walking, "Running plays footsteps more frequently")
    _check(player.footsteps.volume_db == player.footsteps.run_volume_db, "Running uses louder mix")
    _key(KEY_SHIFT, false)
    _key(KEY_SPACE, true)
    await _frames(60)
    _check(player.footsteps.volume_db == player.footsteps.sneak_volume_db, "Sneaking uses quieter mix")
    _key(KEY_SPACE, false)
    _key(KEY_W, false)
    await _frames(20)
    _check(not player.footsteps.playing, "Releasing movement stops playback")
    _key(KEY_W, true)
    await _frames(20)
    player.set_input_enabled(false)
    _check(not player.footsteps.playing, "Capture or disabled input stops immediately")
    player.set_input_enabled(true)
    var wall := StaticBody3D.new()
    var wall_shape := CollisionShape3D.new()
    var wall_box := BoxShape3D.new()
    wall_box.size = Vector3(10, 4, 1)
    wall_shape.shape = wall_box
    wall.add_child(wall_shape)
    wall.position = Vector3(0, 2, -2)
    world.add_child(wall)
    player.position = Vector3(0, 0.05, 0)
    player.velocity = Vector3.ZERO
    await _frames(90)
    steps = 0
    await _frames(30)
    _check(steps == 0 and not player.footsteps.playing, "Pushing against a wall is silent")
    player.position.y = 20
    player.velocity = Vector3.ZERO
    await _frames(3)
    steps = 0
    await _frames(10)
    _check(steps == 0, "Airborne movement is silent")
    _key(KEY_W, false)
    for stream in player.footsteps.STEPS:
        _check(stream.get_length() > 0.4 and stream.get_length() < 0.7, "Individual recorded step imported")
    print("Player footsteps: %d failures" % failures)
    quit(1 if failures else 0)
