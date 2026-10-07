extends CharacterBody3D

@export_range(0.25, 20.0, 0.125) var sight_distance: float = 3.0
@export_range(0.125, 8.0, 0.03125) var sight_half_width: float = 1.125
@export_range(0.1, 3.0, 0.1) var preview_patrol_speed: float = 0.7
@export_range(0.25, 5.0, 0.25) var preview_patrol_half_length: float = 1.75
@export_range(0.1, 10.0, 0.1) var preview_short_chase_speed: float = 5.5
@export_range(0.1, 5.0, 0.1) var preview_lose_sight_grace: float = 1.0

signal monster_state_changed(state_id: StringName)

var current_state: StringName = &"PATROL"
var _patrol_origin: Vector3
var _patrol_axis := Vector3.RIGHT
var _patrol_progress := 0.0
var _patrol_sign := 1.0
var _patrol_active := false
var _player_target: Node3D
var _lost_sight_time := 0.0

func _ready() -> void:
    _create_opaque_search_cone()

func start_preview_hallway_patrol(axis: Vector3) -> void:
    axis.y = 0.0
    if axis.length_squared() < 0.001:
        return
    _patrol_axis = axis.normalized()
    _patrol_origin = global_position
    _patrol_progress = 0.0
    _patrol_sign = 1.0
    _patrol_active = true
    current_state = &"PATROL"
    monster_state_changed.emit(current_state)

func set_player_target(player: Node3D) -> void:
    _player_target = player

func _physics_process(delta: float) -> void:
    if current_state == &"SHORT_CHASE":
        _update_short_chase(delta)
        return

    if _can_see_player():
        _set_state(&"SHORT_CHASE")
        _lost_sight_time = 0.0
        _update_short_chase(delta)
        return

    _update_patrol(delta)

func _update_patrol(delta: float) -> void:
    if not _patrol_active:
        return

    var next_progress := _patrol_progress + _patrol_sign * preview_patrol_speed * delta
    if next_progress >= preview_patrol_half_length:
        next_progress = preview_patrol_half_length
        _patrol_sign = -1.0
    elif next_progress <= -preview_patrol_half_length:
        next_progress = -preview_patrol_half_length
        _patrol_sign = 1.0

    var destination := _patrol_origin + _patrol_axis * next_progress
    var previous_position := global_position
    velocity = (destination - global_position) / maxf(delta, 0.001)
    move_and_slide()
    var moved := (global_position - previous_position).dot(_patrol_axis)
    if absf(moved) < 0.001 and absf(next_progress - _patrol_progress) > 0.001:
        _patrol_sign *= -1.0
    else:
        _patrol_progress += moved

    var facing := _patrol_axis * _patrol_sign
    look_at(global_position + facing, Vector3.UP)

func _update_short_chase(delta: float) -> void:
    if not is_instance_valid(_player_target):
        _set_state(&"PATROL")
        return

    if _can_see_player():
        _lost_sight_time = 0.0
    else:
        _lost_sight_time += delta
        if _lost_sight_time >= preview_lose_sight_grace:
            _set_state(&"PATROL")
            return

    var direction := _player_target.global_position - global_position
    direction.y = 0.0
    if direction.length_squared() < 0.01:
        velocity = Vector3.ZERO
        move_and_slide()
        return

    direction = direction.normalized()
    velocity = direction * preview_short_chase_speed
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)

func _can_see_player() -> bool:
    if not is_instance_valid(_player_target):
        return false

    var target_local := global_transform.affine_inverse() * _player_target.global_position
    var forward_distance := -target_local.z
    if forward_distance <= 0.05 or forward_distance > sight_distance:
        return false

    var cone_half_width_at_target := sight_half_width * (forward_distance / sight_distance)
    if absf(target_local.x) > cone_half_width_at_target:
        return false

    var ray_start := global_position + Vector3.UP * 1.5
    var ray_end := _player_target.global_position + Vector3.UP * 0.75
    var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
    query.collision_mask = 1
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.get("collider") == _player_target

func _set_state(next_state: StringName) -> void:
    if current_state == next_state:
        return
    current_state = next_state
    monster_state_changed.emit(current_state)

func _create_opaque_search_cone() -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_normal(Vector3.UP)
    surface.add_vertex(Vector3(0.0, 0.035, 0.0))
    surface.add_vertex(Vector3(-sight_half_width, 0.035, -sight_distance))
    surface.add_vertex(Vector3(sight_half_width, 0.035, -sight_distance))
    var cone_mesh := surface.commit()

    var cone_material := StandardMaterial3D.new()
    cone_material.albedo_color = Color(1.0, 0.82, 0.08, 1.0)
    cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    cone_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    cone_material.cull_mode = BaseMaterial3D.CULL_DISABLED

    var cone := MeshInstance3D.new()
    cone.name = "OpaqueSearchCone"
    cone.mesh = cone_mesh
    cone.material_override = cone_material
    add_child(cone)
