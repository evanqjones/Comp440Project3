extends "res://scripts/player_system.gd"

@export_range(1.0, 8.0, 0.1) var move_speed: float = 3.5
@export_range(1.0, 16.0, 0.1) var run_speed: float = 5.5
@export_range(1.0, 30.0, 0.5) var ground_acceleration: float = 16.0
@export_range(5.0, 40.0, 0.5) var gravity_strength: float = 24.0
@export_range(0.001, 0.01, 0.0005) var mouse_sensitivity: float = 0.003
@export_range(2.0, 8.0, 0.1) var camera_distance: float = 4.3
@export_range(-1.2, -0.05, 0.01) var camera_min_pitch: float = -0.85
@export_range(0.05, 1.2, 0.01) var camera_max_pitch: float = 0.55

@onready var camera_pivot: Node3D = $CameraPivot
@onready var player_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _ready() -> void:
    super._ready()
    camera_pivot.rotation.x = -0.2
    $CameraPivot/SpringArm3D.spring_length = camera_distance
    player_camera.current = true
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
        get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        return

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
        camera_pivot.rotation.x = clampf(
            camera_pivot.rotation.x - event.relative.y * mouse_sensitivity,
            camera_min_pitch,
            camera_max_pitch
        )

func _physics_process(delta: float) -> void:
    var input_axis := Vector2(
        float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
        float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S))
    ).limit_length(1.0)

    var forward := -camera_pivot.global_basis.z
    forward.y = 0.0
    forward = forward.normalized()
    var right := camera_pivot.global_basis.x
    right.y = 0.0
    right = right.normalized()
    var move_direction := (right * input_axis.x + forward * input_axis.y).normalized()
    var sprint_held := Input.is_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_SHIFT)
    var is_sprinting := sprint_held and _can_sprint(input_axis.length_squared() > 0.0)
    var target_speed := run_speed if is_sprinting else move_speed

    if not is_on_floor():
        velocity.y -= gravity_strength * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    if input_axis.length_squared() > 0.0:
        velocity.x = move_toward(velocity.x, move_direction.x * target_speed, ground_acceleration * delta)
        velocity.z = move_toward(velocity.z, move_direction.z * target_speed, ground_acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, ground_acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, ground_acceleration * delta)

    move_and_slide()
    _update_movement_state(is_sprinting)
    _update_stamina(delta)
