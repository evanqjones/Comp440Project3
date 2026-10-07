extends CharacterBody3D

@export_range(0.25, 20.0, 0.125) var sight_distance: float = 3.0
@export_range(0.125, 8.0, 0.03125) var sight_half_width: float = 1.125
@export_range(0.1, 3.0, 0.1) var preview_patrol_speed: float = 0.5
@export_range(0.25, 5.0, 0.25) var preview_patrol_half_length: float = 1.75
@export_range(0.1, 10.0, 0.1) var preview_short_chase_speed: float = 4.5
@export_range(0.1, 15.0, 0.1) var preview_bell_chase_speed: float = 6.5
@export_range(0.1, 5.0, 0.1) var preview_lose_sight_grace: float = 1.0
@export_range(0.5, 1.6, 0.05) var preview_squeeze_clearance: float = 1.1
@export_range(1.0, 3.0, 0.1) var preview_squeeze_probe_distance: float = 2.0
@export_range(0.15, 0.75, 0.05) var preview_squeeze_width_scale: float = 0.3
@export_range(1.5, 3.0, 0.1) var preview_squeeze_height: float = 1.8

signal monster_state_changed(state_id: StringName)

var current_state: StringName = &"PATROL"
var _patrol_origin: Vector3
var _patrol_axis := Vector3.RIGHT
var _patrol_progress := 0.0
var _patrol_sign := 1.0
var _patrol_active := false
var _player_target: Node3D
var _lost_sight_time := 0.0
var _preview_bell_active := false
var _bell_path_refresh := 0.0
var _last_bell_target_position := Vector3.ZERO
var _has_bell_target := false
var _squeeze_amount := 0.0
var _collision_shape: CollisionShape3D
var _capsule_shape: CapsuleShape3D
var _visual_capsule: MeshInstance3D
var _base_capsule_height := 3.0
var _base_capsule_radius := 0.42
@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
    _collision_shape = $CollisionShape3D
    _capsule_shape = _collision_shape.shape.duplicate() as CapsuleShape3D
    _collision_shape.shape = _capsule_shape
    _visual_capsule = $TallCapsule
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

func try_preview_offscreen_teleport(destination: Vector3, player_camera: Camera3D) -> bool:
    # This is a manual preview hook. Production relocation timing/candidate choice
    # remains a stalking-system decision; Bell chase categorically rejects it.
    if _preview_bell_active or current_state != &"PATROL" or not is_instance_valid(player_camera):
        return false
    if _monster_body_visible_from_camera(global_position, player_camera):
        return false
    if _monster_body_visible_from_camera(destination, player_camera):
        return false
    if destination.distance_to(global_position) < 2.0:
        return false
    var nav_map: RID = _navigation_agent.get_navigation_map()
    if NavigationServer3D.map_get_closest_point(nav_map, destination).distance_to(destination) > 1.35:
        return false
    global_position = destination
    velocity = Vector3.ZERO
    start_preview_hallway_patrol(_patrol_axis)
    return true

func _monster_body_visible_from_camera(base_position: Vector3, player_camera: Camera3D) -> bool:
    for height in [0.65, 1.5, 2.35]:
        var point: Vector3 = base_position + Vector3.UP * float(height)
        if player_camera.is_position_behind(point) or not player_camera.is_position_in_frustum(point):
            continue
        var query := PhysicsRayQueryParameters3D.create(player_camera.global_position, point, 1, [get_rid()])
        if _player_target is CollisionObject3D:
            query.exclude.append((_player_target as CollisionObject3D).get_rid())
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if hit.is_empty():
            return true
    return false

func set_preview_bell_active(active: bool) -> void:
    if _preview_bell_active == active:
        return
    _preview_bell_active = active
    _lost_sight_time = 0.0
    _bell_path_refresh = 0.0
    _has_bell_target = false
    _set_state(&"BELL_CHASE" if active else &"PATROL")

func _physics_process(delta: float) -> void:
    if _preview_bell_active:
        _update_bell_chase()
        return

    if current_state == &"SHORT_CHASE":
        _update_short_chase(delta)
        return

    if _can_see_player():
        _set_state(&"SHORT_CHASE")
        _lost_sight_time = 0.0
        _update_short_chase(delta)
        return

    _update_patrol(delta)

func _update_bell_chase() -> void:
    if not is_instance_valid(_player_target):
        velocity = Vector3.ZERO
        move_and_slide()
        return

    _bell_path_refresh -= get_physics_process_delta_time()
    if _bell_path_refresh <= 0.0:
        var target_position := _player_target.global_position
        if not _has_bell_target or _last_bell_target_position.distance_to(target_position) > 0.4:
            _navigation_agent.target_position = target_position
            _last_bell_target_position = target_position
            _has_bell_target = true
        _bell_path_refresh = 0.2

    var to_player := _player_target.global_position - global_position
    to_player.y = 0.0
    if to_player.length() <= _navigation_agent.target_desired_distance:
        velocity = Vector3.ZERO
        move_and_slide()
        _update_squeeze(Vector3.ZERO, get_physics_process_delta_time())
        return

    var direction := _navigation_agent.get_next_path_position() - global_position
    direction.y = 0.0
    if direction.length_squared() < 0.01:
        velocity = Vector3.ZERO
        move_and_slide()
        return

    direction = direction.normalized()
    velocity = direction * preview_bell_chase_speed
    var centerline_is_clear := _is_centerline_clear(direction)
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)
    var squeezed_against_doorway := false
    for collision_index in get_slide_collision_count():
        if absf(get_slide_collision(collision_index).get_normal().y) < 0.5 and centerline_is_clear:
            squeezed_against_doorway = true
            break
    _update_squeeze(direction, get_physics_process_delta_time(), squeezed_against_doorway)

func _update_squeeze(direction: Vector3, delta: float, force_squeeze: bool = false) -> void:
    var target_squeeze := 1.0 if force_squeeze else 0.0
    if not force_squeeze and direction.length_squared() > 0.001:
        var side := Vector3.UP.cross(direction).normalized()
        var ray_start := global_position + direction * (_base_capsule_radius + 0.35) + Vector3.UP * 1.4
        var left_distance := _side_clearance(ray_start, side)
        var right_distance := _side_clearance(ray_start, -side)
        if left_distance >= 0.0 and right_distance >= 0.0:
            var total_clearance := left_distance + right_distance
            var fully_squeezed_clearance := _base_capsule_radius * 2.0 * preview_squeeze_width_scale
            target_squeeze = clampf(
                (preview_squeeze_clearance - total_clearance) / (preview_squeeze_clearance - fully_squeezed_clearance),
                0.0,
                1.0
            )

    if force_squeeze:
        _squeeze_amount = 1.0
    else:
        _squeeze_amount = move_toward(_squeeze_amount, target_squeeze, delta * 5.0)
    var width_scale := lerpf(1.0, preview_squeeze_width_scale, _squeeze_amount)
    var height_squeeze := clampf(_squeeze_amount * 1.5, 0.0, 1.0)
    var height := lerpf(_base_capsule_height, preview_squeeze_height, height_squeeze)
    _capsule_shape.radius = _base_capsule_radius * width_scale
    _capsule_shape.height = height
    _collision_shape.position.y = height * 0.5
    _visual_capsule.position.y = height * 0.5
    _visual_capsule.scale = Vector3(width_scale, height / _base_capsule_height, width_scale)

func _is_centerline_clear(direction: Vector3) -> bool:
    var ray_start := global_position + Vector3.UP * 1.0
    var ray_end := ray_start + direction * 0.6
    var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1, [get_rid()])
    return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _side_clearance(ray_start: Vector3, direction: Vector3) -> float:
    var query := PhysicsRayQueryParameters3D.create(
        ray_start,
        ray_start + direction * preview_squeeze_probe_distance,
        1,
        [get_rid()]
    )
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return -1.0
    return ray_start.distance_to(hit.position)

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
