extends "res://scripts/player_system.gd"

@export_range(1.0, 8.0, 0.1) var move_speed: float = 3.5
@export_range(1.0, 16.0, 0.1) var run_speed: float = 5.5
@export_range(0.5, 4.0, 0.1) var crouch_speed: float = 2.0
@export_range(0.2, 2.0, 0.1) var movement_noise_interval: float = 0.8
@export_range(1.0, 30.0, 0.5) var ground_acceleration: float = 16.0
@export_range(5.0, 40.0, 0.5) var gravity_strength: float = 24.0
@export_range(0.001, 0.01, 0.0005) var mouse_sensitivity: float = 0.003
@export_range(2.0, 8.0, 0.1) var camera_distance: float = 4.3
@export_range(-1.2, -0.05, 0.01) var camera_min_pitch: float = -0.85
@export_range(0.05, 1.2, 0.01) var camera_max_pitch: float = 0.55

@onready var camera_pivot: Node3D = $CameraPivot
@onready var player_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

signal noise_emitted(event: NoiseEvent)

var _is_crouching := false
var _noise_time_remaining := 0.0
var _standing_capsule_height := 1.65
var _standing_camera_height := 1.32
var _standing_visual_height := 1.65

func _ready() -> void:
    super._ready()
    var collision_shape := $CollisionShape3D as CollisionShape3D
    collision_shape.shape = collision_shape.shape.duplicate() as CapsuleShape3D
    var visual := $CapsuleVisual as MeshInstance3D
    visual.mesh = visual.mesh.duplicate() as CapsuleMesh
    _standing_capsule_height = ($CollisionShape3D.shape as CapsuleShape3D).height
    _standing_camera_height = camera_pivot.position.y
    _standing_visual_height = ($CapsuleVisual.mesh as CapsuleMesh).height
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
    var wants_to_crouch := Input.is_physical_key_pressed(KEY_CTRL)
    _set_crouching(wants_to_crouch)
    _noise_time_remaining = maxf(0.0, _noise_time_remaining - delta)

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
    var is_sprinting := not _is_crouching and sprint_held and _can_sprint(input_axis.length_squared() > 0.0)
    var target_speed := crouch_speed if _is_crouching else (run_speed if is_sprinting else move_speed)

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
    if _is_crouching:
        _movement_state = &"crouching"
    _emit_movement_noise(input_axis.length_squared() > 0.0, is_sprinting)
    _update_stamina(delta)

func _set_crouching(crouching: bool) -> void:
    if _is_crouching == crouching:
        return
    _is_crouching = crouching
    _noise_time_remaining = movement_noise_interval
    var collision_shape := $CollisionShape3D as CollisionShape3D
    var capsule := collision_shape.shape as CapsuleShape3D
    var visual := $CapsuleVisual as MeshInstance3D
    var capsule_mesh := visual.mesh as CapsuleMesh
    var crouched_height := minf(0.95, _standing_capsule_height)
    capsule.height = crouched_height if crouching else _standing_capsule_height
    collision_shape.position.y = capsule.height * 0.5
    capsule_mesh.height = crouched_height if crouching else _standing_visual_height
    visual.position.y = capsule_mesh.height * 0.5
    camera_pivot.position.y = 0.78 if crouching else _standing_camera_height

func _emit_movement_noise(has_movement_input: bool, is_sprinting: bool) -> void:
    var real_velocity := get_real_velocity()
    var horizontal_speed := Vector2(real_velocity.x, real_velocity.z).length()
    if not has_movement_input or horizontal_speed < 0.15 or _is_crouching or _noise_time_remaining > 0.0:
        return
    var noise_level := NoiseEvent.NoiseLevel.LOUD if is_sprinting else NoiseEvent.NoiseLevel.QUIET
    noise_emitted.emit(NoiseEvent.new(global_position, noise_level, &"player_footsteps"))
    _noise_time_remaining = movement_noise_interval
