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
@export_range(0.05, 0.75, 0.025) var preview_squeeze_width_scale: float = 0.15
@export_range(1.0, 3.0, 0.1) var preview_squeeze_height: float = 1.2
@export_range(2.0, 30.0, 0.5) var preview_door_investigation_radius: float = 10.0
@export_range(1.0, 15.0, 0.5) var preview_door_investigation_seconds: float = 6.0
@export_range(0.1, 2.0, 0.1) var preview_door_investigation_speed: float = 0.5
@export_range(0.1, 1.0, 0.05) var preview_bell_window_lurk_speed: float = 0.35
@export_range(0.05, 1.0, 0.05) var preview_book_follow_speed: float = 0.5
@export_range(0.5, 15.0, 0.25) var preview_snack_peek_interval_min: float = 3.0
@export_range(0.5, 20.0, 0.25) var preview_snack_peek_interval_max: float = 5.0
@export_range(0.25, 5.0, 0.25) var preview_snack_peek_seconds: float = 1.5
@export_range(1.0, 20.0, 0.5) var preview_snack_rush_speed: float = 7.0
@export_range(1.0, 30.0, 0.5) var preview_snack_sight_distance: float = 14.0
@export_range(0.5, 15.0, 0.5) var preview_snack_sight_half_width: float = 6.0
@export_range(0.1, 2.0, 0.05) var preview_ruler_hall_speed: float = 1.1
@export_range(1.0, 20.0, 0.5) var preview_ruler_spotlight_chase_speed: float = 8.0
@export_range(0.5, 5.0, 0.1) var preview_quiet_noise_turn_seconds: float = 1.0
@export_range(5.0, 90.0, 1.0) var preview_science_turn_speed_degrees: float = 18.0

const PREVIEW_STUCK_INVESTIGATION_SECONDS := 15.0
const PREVIEW_STUCK_RELOCATION_RETRY_SECONDS := 1.0
const PREVIEW_INVESTIGATION_PROGRESS_EPSILON := 0.002

signal monster_state_changed(state_id: StringName)
signal noise_relocation_requested(source_position: Vector3)

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
var _investigation_time := 0.0
var _investigation_target := Vector3.ZERO
var _investigation_last_target_distance := INF
var _investigation_stall_time := 0.0
var _investigation_relocation_retry_time := 0.0
var _resume_hallway_patrol_after_investigation := false
var _active_safe_room_ids: Array[StringName] = []
var _bell_lurk_room_id: StringName = &""
var _bell_lurk_marker_index := 0
var _quiet_noise_look_position := Vector3.ZERO
var _quiet_noise_look_time := 0.0
var _preview_item_encounter: StringName = &""
var _preview_item_room_bounds := AABB()
var _preview_item_position := Vector3.ZERO
var _preview_item_points: Array[Vector3] = []
var _preview_item_waypoint_index := 0
var _preview_item_refresh := 0.0
var _preview_item_last_navigation_target := Vector3(INF, INF, INF)
var _preview_item_switch_cooldown := 0.0
var _preview_lab_attention_target := Vector3.ZERO
var _preview_lab_attention_time := 0.0
var _preview_item_removed := false
var _preview_brush_chase_active := false
var _search_cone: MeshInstance3D
var _glowing_face: Node3D
var _capsule_was_visible := true
var _science_encounter_settled := false
var _science_has_turn_target := false
var _science_turn_target := Vector3.ZERO
var _preview_window_stalk_active := false
var _preview_window_slide_active := false
var _preview_book_sink_active := false
var _preview_book_sink_start_y := 0.0
var _preview_book_sink_tween: Tween
var _preview_player_hidden := false
var _preview_snack_phase: StringName = &""
var _preview_snack_timer := 0.0
var _preview_snack_peek_index := 1
var _preview_snack_path_refresh := 0.0
var _base_sight_distance := 0.0
var _base_sight_half_width := 0.0
var _preview_player_hidden_in_hallway_locker := false
var _preview_ruler_hall_active := false
var _preview_ruler_hall_spawn_pending := false
var _preview_ruler_hall_spawn_position := Vector3.ZERO
var _preview_ruler_hall_pending_side_science := false
var _preview_ruler_hall_a_spawn := Vector3.ZERO
var _preview_ruler_hall_science_spawn := Vector3.ZERO
var _preview_ruler_hall_end_a := Vector3.ZERO
var _preview_ruler_hall_end_science := Vector3.ZERO
var _preview_ruler_hall_corner_a := Vector3.ZERO
var _preview_ruler_hall_corner_science := Vector3.ZERO
var _preview_ruler_hall_corner_turn_started := false
var _preview_ruler_hall_at_science_spawn := false
var _preview_ruler_hall_travel_to_science := true
var _preview_ruler_hall_has_relocated_once := false
var _preview_ruler_hall_return_count := 0
var _preview_ruler_hall_speed_multiplier := 1.0
var _preview_ruler_hall_complete := false
var _weight_investigation_active := false
var _weight_investigation_target := Vector3.ZERO
var _weight_look_time := 0.0
var _preview_weight_escape_active := false
var _preview_weight_escape_target := Vector3.ZERO
@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
    _collision_shape = $CollisionShape3D
    _capsule_shape = _collision_shape.shape.duplicate() as CapsuleShape3D
    _collision_shape.shape = _capsule_shape
    _visual_capsule = $TallCapsule
    _capsule_was_visible = _visual_capsule.visible
    _base_sight_distance = sight_distance
    _base_sight_half_width = sight_half_width
    _search_cone = get_node_or_null("OpaqueSearchCone") as MeshInstance3D
    _create_opaque_search_cone()
    _search_cone = get_node("OpaqueSearchCone") as MeshInstance3D
    _create_preview_glowing_face()

func begin_preview_item_encounter(encounter: StringName, room_bounds: AABB, item_position: Vector3, points: Array[Vector3]) -> void:
    if _preview_book_sink_active:
        if is_instance_valid(_preview_book_sink_tween):
            _preview_book_sink_tween.kill()
        position.y = _preview_book_sink_start_y
        _preview_book_sink_active = false
    _preview_window_stalk_active = false
    _preview_window_slide_active = false
    _preview_item_encounter = encounter
    _preview_item_room_bounds = room_bounds
    _preview_item_position = item_position
    _preview_item_points = points.duplicate()
    _preview_item_waypoint_index = 0
    _preview_item_refresh = 0.0
    _preview_item_switch_cooldown = 2.5
    _preview_snack_phase = &""
    _preview_snack_timer = 0.0
    _preview_snack_peek_index = 1
    _preview_snack_path_refresh = 0.0
    _preview_lab_attention_time = 0.0
    _preview_item_removed = false
    _weight_investigation_active = false
    _weight_look_time = 0.0
    _science_encounter_settled = false
    _science_has_turn_target = false
    visible = true
    collision_layer = 2
    collision_mask = 1
    _visual_capsule.visible = _capsule_was_visible
    _search_cone.visible = true
    _glowing_face.visible = false
    _patrol_active = false
    _set_state(&"PATROL")
    _navigation_agent.target_desired_distance = 0.5
    if encounter == &"snack":
        _preview_snack_phase = &"waiting"
        _preview_snack_timer = randf_range(preview_snack_peek_interval_min, maxf(preview_snack_peek_interval_min, preview_snack_peek_interval_max))
        sight_distance = preview_snack_sight_distance
        sight_half_width = preview_snack_sight_half_width
        _create_opaque_search_cone()
    else:
        sight_distance = _base_sight_distance
        sight_half_width = _base_sight_half_width
        _create_opaque_search_cone()
    if encounter == &"lab_coat" and not _preview_item_points.is_empty():
        _navigation_agent.target_position = _preview_item_points[0]
    elif encounter == &"science_classroom" and not _preview_item_points.is_empty():
        _navigation_agent.target_position = _preview_item_points[0]
    elif encounter == &"weight" and _preview_item_points.size() >= 2:
        var patrol_delta := _preview_item_points[1] - _preview_item_points[0]
        patrol_delta.y = 0.0
        _patrol_axis = patrol_delta.normalized()
        _patrol_origin = (_preview_item_points[0] + _preview_item_points[1]) * 0.5
        _patrol_origin.y = global_position.y
        preview_patrol_half_length = patrol_delta.length() * 0.5
        _patrol_progress = clampf((global_position - _patrol_origin).dot(_patrol_axis), -preview_patrol_half_length, preview_patrol_half_length)
        _patrol_sign = 1.0 if _patrol_progress < preview_patrol_half_length else -1.0
        _patrol_active = true
    elif encounter == &"brush":
        _set_item_waypoint_target()

func end_preview_item_encounter() -> void:
    _preview_brush_chase_active = false
    _science_encounter_settled = false
    _science_has_turn_target = false
    _preview_item_encounter = &""
    _preview_snack_phase = &""
    _preview_snack_timer = 0.0
    sight_distance = _base_sight_distance
    sight_half_width = _base_sight_half_width
    _create_opaque_search_cone()
    _preview_item_points.clear()
    _preview_lab_attention_time = 0.0
    _visual_capsule.visible = _capsule_was_visible
    _search_cone.visible = true
    _glowing_face.visible = false
    if visible:
        _set_state(&"PATROL")

func begin_preview_brush_chase() -> void:
    if not is_instance_valid(_player_target):
        return
    _preview_brush_chase_active = true
    _preview_item_encounter = &"brush"
    _preview_player_hidden = false
    visible = true
    global_position.y = _player_target.global_position.y
    global_rotation = Vector3(0.0, global_rotation.y, 0.0)
    collision_layer = 2
    collision_mask = 1
    velocity = Vector3.ZERO
    set_physics_process(true)
    _set_state(&"SHORT_CHASE")

func begin_preview_ruler_hall_event(classroom_a_spawn: Vector3, science_spawn: Vector3, beyond_science: Vector3, beyond_a: Vector3, science_corner: Vector3, a_corner: Vector3) -> void:
    _preview_window_stalk_active = false
    _preview_window_slide_active = false
    _preview_book_sink_active = false
    _preview_weight_escape_active = false
    _preview_item_encounter = &"ruler_hall"
    _preview_item_points.clear()
    _preview_ruler_hall_active = true
    _preview_ruler_hall_complete = false
    _preview_ruler_hall_a_spawn = classroom_a_spawn
    _preview_ruler_hall_science_spawn = science_spawn
    _preview_ruler_hall_end_science = beyond_science
    _preview_ruler_hall_end_a = beyond_a
    _preview_ruler_hall_corner_science = science_corner
    _preview_ruler_hall_corner_a = a_corner
    _preview_ruler_hall_corner_turn_started = false
    _preview_ruler_hall_at_science_spawn = false
    _preview_ruler_hall_pending_side_science = false
    _preview_ruler_hall_travel_to_science = true
    _preview_ruler_hall_has_relocated_once = false
    _preview_ruler_hall_return_count = 0
    _preview_ruler_hall_speed_multiplier = 1.0
    _preview_ruler_hall_spawn_position = classroom_a_spawn
    _preview_ruler_hall_spawn_pending = true
    _preview_item_refresh = 0.0
    _preview_item_last_navigation_target = Vector3(INF, INF, INF)
    _preview_player_hidden = false
    _preview_player_hidden_in_hallway_locker = false
    _patrol_active = false
    _weight_investigation_active = false
    _science_encounter_settled = false
    _visual_capsule.visible = _capsule_was_visible
    _search_cone.visible = true
    _glowing_face.visible = false
    visible = true
    collision_layer = 2
    collision_mask = 1
    _navigation_agent.target_desired_distance = 0.75
    velocity = Vector3.ZERO
    _set_state(&"PATROL")

func request_preview_ruler_hall_spawn(science_side: bool) -> void:
    if not _preview_ruler_hall_active:
        return
    var requested_side := _preview_ruler_hall_pending_side_science if _preview_ruler_hall_spawn_pending else _preview_ruler_hall_at_science_spawn
    if science_side == requested_side:
        return
    if _preview_ruler_hall_has_relocated_once:
        _preview_ruler_hall_return_count += 1
        _preview_ruler_hall_speed_multiplier = pow(3.0, float(_preview_ruler_hall_return_count))
    else:
        _preview_ruler_hall_has_relocated_once = true
    _preview_ruler_hall_pending_side_science = science_side
    _preview_ruler_hall_spawn_position = _preview_ruler_hall_science_spawn if science_side else _preview_ruler_hall_a_spawn
    _preview_ruler_hall_spawn_pending = true

func is_preview_ruler_hall_complete() -> bool:
    return _preview_ruler_hall_complete

func is_preview_ruler_hall_active() -> bool:
    return _preview_ruler_hall_active

func start_preview_window_stalk(facing_direction: Vector3, look_target: Vector3 = Vector3.ZERO) -> void:
    _preview_window_stalk_active = true
    _preview_window_slide_active = false
    _patrol_active = false
    velocity = Vector3.ZERO
    if look_target != Vector3.ZERO:
        var direction := look_target - global_position
        direction.y = 0.0
        if direction.length_squared() > 0.001:
            facing_direction = direction.normalized()
    facing_direction.y = 0.0
    if facing_direction.length_squared() > 0.001:
        look_at(global_position + facing_direction.normalized(), Vector3.UP)
    _set_state(&"PATROL")

func is_preview_window_stalking() -> bool:
    return _preview_window_stalk_active

func start_preview_window_left_slide(destination: Vector3) -> void:
    if not _preview_window_stalk_active:
        return
    _preview_window_stalk_active = false
    _preview_window_slide_active = true
    _patrol_active = false
    _navigation_agent.target_desired_distance = 0.2
    _navigation_agent.target_position = destination
    velocity = Vector3.ZERO

func is_preview_window_sliding() -> bool:
    return _preview_window_slide_active

func on_preview_item_collected(item_id: StringName) -> void:
    if item_id == &"book":
        _start_preview_book_sink()
    elif item_id == &"brush":
        _visual_capsule.visible = true
        _search_cone.visible = true
        _glowing_face.visible = false
    elif item_id == &"front_door_key":
        end_preview_item_encounter()

func begin_preview_weight_escape(destination: Vector3) -> void:
    _preview_item_encounter = &""
    _weight_investigation_active = false
    _preview_weight_escape_target = destination
    _preview_weight_escape_active = true
    _patrol_active = false
    _navigation_agent.target_desired_distance = 0.75
    _navigation_agent.target_position = destination
    velocity = Vector3.ZERO

func is_preview_weight_escape_active() -> bool:
    return _preview_weight_escape_active

func _start_preview_book_sink() -> void:
    if _preview_book_sink_active:
        return
    _preview_item_removed = true
    _preview_item_encounter = &""
    _preview_window_stalk_active = false
    _preview_window_slide_active = false
    _preview_book_sink_active = true
    _preview_book_sink_start_y = position.y
    _patrol_active = false
    velocity = Vector3.ZERO
    collision_layer = 0
    collision_mask = 0
    _preview_book_sink_tween = create_tween()
    _preview_book_sink_tween.set_trans(Tween.TRANS_QUAD)
    _preview_book_sink_tween.set_ease(Tween.EASE_IN)
    _preview_book_sink_tween.tween_property(self, "position:y", position.y - 3.2, 1.25)
    _preview_book_sink_tween.tween_callback(_finish_preview_book_sink)

func _finish_preview_book_sink() -> void:
    position.y = _preview_book_sink_start_y
    velocity = Vector3.ZERO
    visible = false
    collision_layer = 0
    collision_mask = 0
    _preview_book_sink_active = false
    _patrol_active = false
    _set_state(&"PATROL")

func is_preview_book_sinking() -> bool:
    return _preview_book_sink_active

func _create_preview_glowing_face() -> void:
    _glowing_face = Node3D.new()
    _glowing_face.name = "PreviewRulerGlowFace"
    add_child(_glowing_face)
    var glow_material := StandardMaterial3D.new()
    glow_material.albedo_color = Color(1.0, 0.93, 0.42, 1.0)
    glow_material.emission_enabled = true
    glow_material.emission = Color(1.0, 0.78, 0.2, 1.0)
    glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for eye_x in [-0.13, 0.13]:
        var eye := MeshInstance3D.new()
        eye.name = "GlowingEye"
        var eye_mesh := SphereMesh.new()
        eye_mesh.radius = 0.075
        eye_mesh.height = 0.15
        eye.mesh = eye_mesh
        eye.position = Vector3(eye_x, 2.05, -0.4)
        eye.material_override = glow_material
        _glowing_face.add_child(eye)
    var smile := MeshInstance3D.new()
    smile.name = "GlowingSmile"
    var smile_mesh := BoxMesh.new()
    smile_mesh.size = Vector3(0.25, 0.045, 0.04)
    smile.mesh = smile_mesh
    smile.position = Vector3(0.0, 1.86, -0.415)
    smile.material_override = glow_material
    _glowing_face.add_child(smile)
    _glowing_face.visible = false

func _set_item_waypoint_target() -> void:
    if _preview_item_points.is_empty():
        return
    _preview_item_waypoint_index = posmod(_preview_item_waypoint_index, _preview_item_points.size())
    _navigation_agent.target_position = _preview_item_points[_preview_item_waypoint_index]

func _preview_clamp_to_encounter_room(position: Vector3) -> Vector3:
    var inset := 0.35
    position.x = clampf(position.x, _preview_item_room_bounds.position.x + inset, _preview_item_room_bounds.end.x - inset)
    position.z = clampf(position.z, _preview_item_room_bounds.position.z + inset, _preview_item_room_bounds.end.z - inset)
    position.y = _preview_item_room_bounds.position.y + _preview_item_room_bounds.size.y
    return position

func _face_preview_direction(direction: Vector3, delta: float) -> void:
    direction.y = 0.0
    if direction.length_squared() < 0.001:
        return
    direction = direction.normalized()
    var scan := sin(Time.get_ticks_msec() * 0.00055) * 0.5
    var desired_basis := Basis(Vector3.UP, scan) * Basis.looking_at(direction, Vector3.UP)
    global_basis = global_basis.slerp(desired_basis, minf(1.0, delta * 1.2))

func _face_preview_direction_stably(direction: Vector3, delta: float) -> void:
    direction.y = 0.0
    if direction.length_squared() < 0.001:
        return
    var desired_basis := Basis.looking_at(direction.normalized(), Vector3.UP)
    global_basis = global_basis.slerp(desired_basis, minf(1.0, delta * 1.8))

func _move_preview_item_toward(target: Vector3, speed: float, delta: float) -> void:
    _preview_item_refresh = maxf(0.0, _preview_item_refresh - delta)
    if _preview_item_refresh <= 0.0 or _preview_item_last_navigation_target.distance_to(target) > 0.35:
        _navigation_agent.target_position = target
        _preview_item_last_navigation_target = target
        _preview_item_refresh = 0.25
    var direction := _navigation_agent.get_next_path_position() - global_position
    direction.y = 0.0
    if _navigation_agent.is_navigation_finished() or direction.length() <= _navigation_agent.target_desired_distance or direction.length_squared() < 0.01:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    direction = direction.normalized()
    velocity = direction * speed
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)

func _turn_science_toward(source_position: Vector3) -> void:
    if _preview_item_encounter != &"science_classroom" or _preview_bell_active:
        return
    _science_turn_target = source_position
    _science_has_turn_target = true

func _update_science_classroom_encounter(delta: float) -> void:
    if _preview_item_points.is_empty():
        velocity = Vector3.ZERO
        move_and_slide()
        return
    var corner_position := _preview_item_points[0]
    if not _science_encounter_settled and global_position.distance_to(corner_position) > 0.65:
        _move_preview_item_toward(corner_position, 0.35, delta)
        return
    velocity = Vector3.ZERO
    move_and_slide()
    if not _science_encounter_settled:
        rotation.y = -PI * 0.5 # Face east into the wall from the southeast corner.
        _science_encounter_settled = true
    if _science_has_turn_target:
        var direction := _science_turn_target - global_position
        direction.y = 0.0
        if direction.length_squared() > 0.001:
            var target_yaw := atan2(-direction.x, -direction.z)
            rotation.y = rotate_toward(rotation.y, target_yaw, deg_to_rad(preview_science_turn_speed_degrees) * delta)

func _update_preview_item_encounter(delta: float) -> void:
    _preview_item_refresh = maxf(0.0, _preview_item_refresh - delta)
    _preview_item_switch_cooldown = maxf(0.0, _preview_item_switch_cooldown - delta)
    match _preview_item_encounter:
        &"weight":
            _update_weight_encounter(delta)
        &"book":
            if not is_instance_valid(_player_target):
                return
            var chase_target := _preview_clamp_to_encounter_room(_player_target.global_position)
            var distance_to_player := global_position.distance_to(chase_target)
            if distance_to_player > 1.1:
                _move_preview_item_toward(chase_target, preview_book_follow_speed, delta)
            else:
                velocity = Vector3.ZERO
                move_and_slide()
                _face_preview_direction(_player_target.global_position - global_position, delta)
        &"brush":
            _visual_capsule.visible = true
            if not _preview_item_points.is_empty() and global_position.distance_to(_preview_item_points[0]) > 0.8:
                _move_preview_item_toward(_preview_item_points[0], 0.25, delta)
                return
            if _preview_item_switch_cooldown <= 0.0 and not _preview_item_points.is_empty() and is_instance_valid(_player_target):
                var camera: Camera3D = _player_target.get("player_camera")
                if is_instance_valid(camera) and not _monster_body_visible_from_camera(global_position, camera):
                    var current_index := _preview_item_waypoint_index
                    var next_index := (current_index + 1) % _preview_item_points.size()
                    var destination: Vector3 = _preview_item_points[next_index]
                    if not _monster_body_visible_from_camera(destination, camera):
                        global_position = destination
                        velocity = Vector3.ZERO
                        _preview_item_waypoint_index = next_index
                _preview_item_switch_cooldown = randf_range(2.0, 4.0)
        &"lab_coat":
            var target := _preview_item_points[0] if not _preview_item_points.is_empty() else global_position
            if _preview_lab_attention_time > 0.0:
                _preview_lab_attention_time = maxf(0.0, _preview_lab_attention_time - delta)
                target = _preview_clamp_to_encounter_room(_preview_lab_attention_target)
            _move_preview_item_toward(target, 0.3 if _preview_lab_attention_time > 0.0 else 0.2, delta)
            if _preview_lab_attention_time > 0.0:
                _face_preview_direction(_preview_lab_attention_target - global_position, delta)
        &"science_classroom":
            _update_science_classroom_encounter(delta)
        &"ruler_hall":
            _update_preview_ruler_hall(delta)
        &"snack":
            _update_snack_encounter(delta)

func _update_snack_encounter(delta: float) -> void:
    if _preview_item_points.size() < 2:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    var kitchen_position := _preview_item_points[0]
    var peek_index := clampi(_preview_snack_peek_index, 1, _preview_item_points.size() - 1)
    var opening_position := _preview_item_points[peek_index]
    if _preview_snack_phase == &"rushing":
        _preview_snack_phase = &"returning"
        if _preview_item_points.size() >= 3:
            _preview_snack_peek_index = 2 if peek_index == 1 else 1
        _navigation_agent.target_position = kitchen_position
    if _preview_snack_phase == &"waiting" or _preview_snack_phase == &"peeking":
        velocity = Vector3.ZERO
        move_and_slide()
        _face_preview_direction_stably(opening_position - global_position, delta)
        _preview_snack_timer -= delta
        if _preview_snack_timer <= 0.0:
            if _preview_snack_phase == &"waiting":
                _preview_snack_phase = &"peeking"
                _preview_snack_timer = preview_snack_peek_seconds
            else:
                _preview_snack_phase = &"waiting"
                _preview_snack_timer = randf_range(preview_snack_peek_interval_min, maxf(preview_snack_peek_interval_min, preview_snack_peek_interval_max))
                if _preview_item_points.size() >= 3:
                    _preview_snack_peek_index = 2 if peek_index == 1 else 1
        return
    if _preview_snack_phase == &"returning":
        if global_position.distance_to(kitchen_position) <= 0.65:
            velocity = Vector3.ZERO
            move_and_slide()
            _preview_snack_phase = &"waiting"
            _preview_snack_timer = randf_range(preview_snack_peek_interval_min, maxf(preview_snack_peek_interval_min, preview_snack_peek_interval_max))
            return
        _move_preview_item_toward(kitchen_position, 0.8, delta)

func _update_preview_ruler_hall(delta: float) -> void:
    if not _preview_ruler_hall_active or not is_instance_valid(_player_target):
        velocity = Vector3.ZERO
        move_and_slide()
        return
    var camera: Camera3D = _player_target.get("player_camera")
    if _preview_ruler_hall_spawn_pending:
        var can_relocate := is_instance_valid(camera)
        if can_relocate:
            # Preserve the off-camera rule for both the source and requested spawn.
            can_relocate = not _monster_body_visible_from_camera(global_position, camera) and not _monster_body_visible_from_camera(_preview_ruler_hall_spawn_position, camera)
        if can_relocate:
            global_position = _preview_ruler_hall_spawn_position
            _preview_ruler_hall_at_science_spawn = _preview_ruler_hall_pending_side_science
            _preview_ruler_hall_travel_to_science = not _preview_ruler_hall_at_science_spawn
            _preview_ruler_hall_corner_turn_started = false
            _preview_ruler_hall_spawn_pending = false
            _preview_item_last_navigation_target = Vector3(INF, INF, INF)

    var heading_to_science := _preview_ruler_hall_travel_to_science
    var target: Vector3
    if heading_to_science:
        target = _preview_ruler_hall_corner_science if _preview_ruler_hall_corner_turn_started else _preview_ruler_hall_end_science
    else:
        target = _preview_ruler_hall_corner_a if _preview_ruler_hall_corner_turn_started else _preview_ruler_hall_end_a
    target.y = global_position.y

    if not _preview_ruler_hall_corner_turn_started and global_position.distance_to(target) <= 0.8:
        _preview_ruler_hall_corner_turn_started = true
        target = _preview_ruler_hall_corner_science if heading_to_science else _preview_ruler_hall_corner_a
        target.y = global_position.y
        _preview_item_last_navigation_target = Vector3(INF, INF, INF)
    elif _preview_ruler_hall_corner_turn_started and global_position.distance_to(target) <= 0.8:
        if _preview_player_hidden:
            finish_preview_ruler_hall_event()
            return
        _preview_ruler_hall_travel_to_science = not _preview_ruler_hall_travel_to_science
        heading_to_science = _preview_ruler_hall_travel_to_science
        _preview_ruler_hall_corner_turn_started = false
        target = _preview_ruler_hall_end_science if heading_to_science else _preview_ruler_hall_end_a
        target.y = global_position.y
        _preview_item_last_navigation_target = Vector3(INF, INF, INF)
    _move_preview_ruler_hall_toward(target, preview_ruler_hall_speed * _preview_ruler_hall_speed_multiplier, delta)

func _update_ruler_hall_spotlight() -> void:
    if _preview_player_hidden or not is_instance_valid(_search_cone) or not is_instance_valid(_player_target):
        return
    var direction := _player_target.global_position - _search_cone.global_position
    direction.y = 0.0
    if direction.length_squared() < 0.001:
        return
    var target_yaw := atan2(-direction.x, -direction.z)
    var cone_rotation := _search_cone.global_rotation
    cone_rotation.y = target_yaw
    _search_cone.global_rotation = cone_rotation

func finish_preview_ruler_hall_event(preserve_spawn_behavior: bool = false) -> void:
    _preview_ruler_hall_active = false
    _preview_ruler_hall_complete = true
    _preview_ruler_hall_spawn_pending = false
    _preview_ruler_hall_corner_turn_started = false
    _preview_ruler_hall_has_relocated_once = false
    _preview_ruler_hall_return_count = 0
    _preview_ruler_hall_speed_multiplier = 1.0
    _preview_item_encounter = &""
    if not preserve_spawn_behavior:
        _patrol_active = false
    velocity = Vector3.ZERO
    _set_state(&"PATROL")

func _move_preview_ruler_hall_toward(target: Vector3, speed: float, delta: float) -> void:
    if _preview_item_refresh <= 0.0 or _preview_item_last_navigation_target.distance_to(target) > 0.35:
        _navigation_agent.target_position = target
        _preview_item_last_navigation_target = target
        _preview_item_refresh = 0.25
    else:
        _preview_item_refresh = maxf(0.0, _preview_item_refresh - delta)
    var direction := _navigation_agent.get_next_path_position() - global_position
    direction.y = 0.0
    # If the navigation map briefly reports a finished/empty route, keep the
    # hallway motion going toward the active waypoint instead of freezing.
    if _navigation_agent.is_navigation_finished() or direction.length_squared() < 0.01:
        direction = target - global_position
        direction.y = 0.0
    if direction.length_squared() < 0.001:
        return
    direction = direction.normalized()
    velocity = direction * speed
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)

func _start_weight_investigation(source_position: Vector3) -> void:
    var target := _preview_clamp_to_encounter_room(source_position)
    target.y = global_position.y
    _weight_investigation_target = target
    _weight_investigation_active = true
    _weight_look_time = 0.0

func _update_weight_encounter(delta: float) -> void:
    if _weight_investigation_active:
        var direction := _weight_investigation_target - global_position
        direction.y = 0.0
        if direction.length() > 0.55:
            direction = direction.normalized()
            velocity = direction * 1.5
            move_and_slide()
            _face_preview_direction(direction, delta)
        else:
            velocity = Vector3.ZERO
            move_and_slide()
            _face_preview_direction(direction, delta)
            _weight_look_time += delta
            if _weight_look_time >= 1.6:
                _weight_investigation_active = false
                _weight_look_time = 0.0
                if _preview_item_points.size() >= 2:
                    var offset := global_position - _patrol_origin
                    _patrol_progress = clampf(offset.dot(_patrol_axis), -preview_patrol_half_length, preview_patrol_half_length)
                    if _patrol_progress <= -preview_patrol_half_length + 0.05:
                        _patrol_sign = 1.0
                    elif _patrol_progress >= preview_patrol_half_length - 0.05:
                        _patrol_sign = -1.0
        return
    _update_patrol(delta)

func _update_weight_escape(delta: float) -> void:
    var to_destination := _preview_weight_escape_target - global_position
    to_destination.y = 0.0
    if to_destination.length() <= 1.0:
        _preview_weight_escape_active = false
        _patrol_active = false
        velocity = Vector3.ZERO
        move_and_slide()
        _set_state(&"PATROL")
        return
    var direction := _navigation_agent.get_next_path_position() - global_position
    direction.y = 0.0
    if _navigation_agent.is_navigation_finished() or direction.length_squared() < 0.01:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    direction = direction.normalized()
    var delta_time := maxf(delta, 0.001)
    var low_header_ahead := _has_low_overhead_clearance(direction)
    _update_squeeze(direction, delta_time, low_header_ahead)
    var centerline_is_clear := _is_centerline_clear(direction)
    velocity = direction * 3.5
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)
    var squeezed_against_doorway := low_header_ahead
    for collision_index in get_slide_collision_count():
        if absf(get_slide_collision(collision_index).get_normal().y) < 0.5 and centerline_is_clear:
            squeezed_against_doorway = true
            break
    _update_squeeze(direction, delta_time, squeezed_against_doorway)

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

func set_preview_spawn_behavior(in_hallway: bool, axis: Vector3 = Vector3.RIGHT) -> void:
    _patrol_active = false
    velocity = Vector3.ZERO
    if in_hallway:
        start_preview_hallway_patrol(axis)
    else:
        _set_state(&"PATROL")

func set_player_target(player: Node3D) -> void:
    _player_target = player

func set_preview_player_hidden(hidden: bool, in_hallway_locker: bool = false) -> void:
    _preview_player_hidden = hidden
    _preview_player_hidden_in_hallway_locker = hidden and in_hallway_locker
    if not hidden:
        _preview_ruler_hall_corner_turn_started = false
    if hidden and current_state == &"SHORT_CHASE":
        _lost_sight_time = 0.0
        _set_state(&"PATROL")

func set_safe_rooms(room_ids: Array[StringName]) -> void:
    _active_safe_room_ids = room_ids.duplicate()
    _bell_lurk_room_id = &""
    _bell_lurk_marker_index = 0
    if current_state == &"BELL_CHASE":
        _bell_path_refresh = 0.0

func refresh_preview_navigation() -> void:
    if current_state == &"INVESTIGATE":
        _navigation_agent.target_position = _investigation_target
    elif current_state == &"BELL_CHASE":
        _has_bell_target = false
        _bell_path_refresh = 0.0

func try_preview_offscreen_teleport(destination: Vector3, player_camera: Camera3D, in_hallway: bool, minimum_distance: float = 2.0, patrol_axis: Vector3 = Vector3.RIGHT) -> bool:
    # This is a manual preview hook. Production relocation timing/candidate choice
    # remains a stalking-system decision; Bell chase categorically rejects it.
    if _preview_bell_active or current_state not in [&"PATROL", &"INVESTIGATE"] or not is_instance_valid(player_camera):
        return false
    var hidden_after_book := _preview_item_removed and not visible
    if not hidden_after_book and _monster_body_visible_from_camera(global_position, player_camera):
        return false
    if _monster_body_visible_from_camera(destination, player_camera):
        return false
    if destination.distance_to(global_position) < minimum_distance:
        return false
    var nav_map: RID = _navigation_agent.get_navigation_map()
    if NavigationServer3D.map_get_closest_point(nav_map, destination).distance_to(destination) > 1.35:
        return false
    global_position = destination
    velocity = Vector3.ZERO
    if hidden_after_book:
        visible = true
        collision_layer = 2
        collision_mask = 1
        _preview_item_removed = false
    set_preview_spawn_behavior(in_hallway, patrol_axis)
    return true

func receive_preview_door_noise(source_position: Vector3, loudness: float = 0.7) -> void:
    if _preview_item_encounter == &"weight" and not _preview_bell_active:
        _start_weight_investigation(source_position)
        return
    if _preview_item_encounter == &"science_classroom" and not _preview_bell_active:
        _turn_science_toward(source_position)
        return
    if _preview_item_encounter == &"lab_coat" and not _preview_bell_active:
        _preview_lab_attention_target = source_position
        _preview_lab_attention_time = 5.0
        return
    if _preview_bell_active or current_state != &"PATROL" or randf() > clampf(loudness, 0.0, 1.0):
        return
    var distance := global_position.distance_to(source_position)
    if distance <= preview_door_investigation_radius:
        begin_preview_investigation(source_position)
    else:
        noise_relocation_requested.emit(source_position)

func receive_noise(event: NoiseEvent) -> void:
    if _preview_bell_active:
        return
    if _preview_item_encounter == &"science_classroom":
        _turn_science_toward(event.source_position)
        return
    if _preview_item_encounter == &"weight":
        _start_weight_investigation(event.source_position)
        return
    if _preview_item_encounter == &"lab_coat" and event.level == NoiseEvent.NoiseLevel.LOUD:
        _preview_lab_attention_target = event.source_position
        _preview_lab_attention_time = 5.0
        return
    if current_state == &"INVESTIGATE":
        if global_position.distance_to(event.source_position) <= preview_door_investigation_radius:
            _quiet_noise_look_position = event.source_position
            _quiet_noise_look_time = preview_quiet_noise_turn_seconds
        return
    if event.level == NoiseEvent.NoiseLevel.LOUD:
        receive_preview_door_noise(event.source_position, 0.7)
        return
    if current_state != &"PATROL" or randf() > 0.3:
        return
    if global_position.distance_to(event.source_position) > preview_door_investigation_radius:
        return
    _quiet_noise_look_position = event.source_position
    _quiet_noise_look_time = preview_quiet_noise_turn_seconds

func begin_preview_investigation(source_position: Vector3) -> void:
    if _preview_bell_active or current_state in [&"SHORT_CHASE", &"BELL_CHASE"]:
        return
    _resume_hallway_patrol_after_investigation = _patrol_active
    _patrol_active = false
    _investigation_target = source_position
    _investigation_time = preview_door_investigation_seconds
    _investigation_last_target_distance = global_position.distance_to(source_position)
    _investigation_stall_time = 0.0
    _investigation_relocation_retry_time = 0.0
    _navigation_agent.target_position = source_position
    _set_state(&"INVESTIGATE")

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
    if active:
        if _preview_book_sink_active:
            if is_instance_valid(_preview_book_sink_tween):
                _preview_book_sink_tween.kill()
            position.y = _preview_book_sink_start_y
            _preview_book_sink_active = false
        if _preview_item_removed:
            visible = true
            collision_layer = 2
            collision_mask = 1
            _preview_item_removed = false
        _preview_window_stalk_active = false
        _preview_window_slide_active = false
    _lost_sight_time = 0.0
    _bell_path_refresh = 0.0
    _has_bell_target = false
    _set_state(&"BELL_CHASE" if active else &"PATROL")

func _physics_process(delta: float) -> void:
    if _preview_bell_active:
        _update_bell_chase()
        return

    if _preview_brush_chase_active:
        _update_brush_chase()
        return

    if _preview_weight_escape_active:
        _update_weight_escape(delta)
        return

    if _preview_window_stalk_active:
        velocity = Vector3.ZERO
        move_and_slide()
        return

    if _preview_book_sink_active or (_preview_item_removed and not visible):
        velocity = Vector3.ZERO
        return

    if _preview_window_slide_active:
        var slide_direction := _navigation_agent.get_next_path_position() - global_position
        slide_direction.y = 0.0
        if _navigation_agent.is_navigation_finished() or slide_direction.length() <= _navigation_agent.target_desired_distance or slide_direction.length_squared() < 0.01:
            _preview_window_slide_active = false
            velocity = Vector3.ZERO
            move_and_slide()
            return
        velocity = slide_direction.normalized() * 0.85
        move_and_slide()
        return

    if _preview_ruler_hall_active:
        _update_ruler_hall_spotlight()
        if _can_see_from_ruler_spotlight():
            _set_state(&"SHORT_CHASE")
            _lost_sight_time = 0.0

    if current_state == &"SHORT_CHASE":
        _update_short_chase(delta)
        return

    if _can_see_player() and _preview_item_encounter not in [&"weight", &"ruler_hall"]:
        var snack_is_peeking := _preview_item_encounter != &"snack" or _preview_snack_phase == &"peeking"
        if snack_is_peeking and (_preview_item_encounter == &"snack" or (_preview_item_encounter == &"science_classroom" and _science_encounter_settled)):
            if _preview_item_encounter == &"snack":
                _preview_snack_phase = &"rushing"
            _set_state(&"SHORT_CHASE")
            _lost_sight_time = 0.0
            _update_short_chase(delta)
            return

    if _preview_item_encounter != &"":
        _update_preview_item_encounter(delta)
        return

    if _can_see_player() and _preview_item_encounter not in [&"weight", &"ruler_hall"]:
        _set_state(&"SHORT_CHASE")
        _lost_sight_time = 0.0
        _update_short_chase(delta)
        return

    if current_state == &"INVESTIGATE":
        _update_investigation(delta)
        _update_quiet_noise_look(delta)
        return

    _update_patrol(delta)
    _update_quiet_noise_look(delta)

func _update_brush_chase() -> void:
    if not is_instance_valid(_player_target):
        velocity = Vector3.ZERO
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

func _update_quiet_noise_look(delta: float) -> void:
    if _quiet_noise_look_time <= 0.0 or current_state not in [&"PATROL", &"INVESTIGATE"]:
        return
    _quiet_noise_look_time = maxf(0.0, _quiet_noise_look_time - delta)
    var direction := _quiet_noise_look_position - global_position
    direction.y = 0.0
    if direction.length_squared() > 0.001:
        look_at(global_position + direction, Vector3.UP)

func _update_investigation(delta: float) -> void:
    var direction := _navigation_agent.get_next_path_position() - global_position
    direction.y = 0.0
    if not _navigation_agent.is_navigation_finished() and direction.length() > _navigation_agent.target_desired_distance and direction.length_squared() > 0.01:
        direction = direction.normalized()
        var delta_time := maxf(delta, 0.001)
        var low_header_ahead := _has_low_overhead_clearance(direction)
        _update_squeeze(direction, delta_time, low_header_ahead)
        var centerline_is_clear := _is_centerline_clear(direction)
        velocity = direction * preview_door_investigation_speed
        move_and_slide()
        look_at(global_position + direction, Vector3.UP)
        var squeezed_against_doorway := low_header_ahead
        for collision_index in get_slide_collision_count():
            if absf(get_slide_collision(collision_index).get_normal().y) < 0.5 and centerline_is_clear:
                squeezed_against_doorway = true
                break
        _update_squeeze(direction, delta_time, squeezed_against_doorway)
    else:
        velocity = Vector3.ZERO
        move_and_slide()
        var toward_noise := _investigation_target - global_position
        toward_noise.y = 0.0
        _update_squeeze(toward_noise, delta, _has_low_overhead_clearance(toward_noise))
        if toward_noise.length_squared() > 0.01:
            look_at(global_position + toward_noise.normalized(), Vector3.UP)
        _investigation_time -= delta
        if _investigation_time <= 0.0:
            if _resume_hallway_patrol_after_investigation:
                start_preview_hallway_patrol(_patrol_axis)
            else:
                _set_state(&"PATROL")
            _squeeze_amount = 0.0
            _apply_squeeze_shape()
    _check_stuck_investigation(delta)

func _check_stuck_investigation(delta: float) -> void:
    if current_state != &"INVESTIGATE" or _preview_bell_active:
        return
    var target_distance := global_position.distance_to(_investigation_target)
    if _investigation_last_target_distance - target_distance >= PREVIEW_INVESTIGATION_PROGRESS_EPSILON:
        _investigation_stall_time = 0.0
    else:
        _investigation_stall_time += delta
    _investigation_last_target_distance = target_distance
    _investigation_relocation_retry_time = maxf(0.0, _investigation_relocation_retry_time - delta)
    if _investigation_stall_time >= PREVIEW_STUCK_INVESTIGATION_SECONDS and _investigation_relocation_retry_time <= 0.0:
        _investigation_relocation_retry_time = PREVIEW_STUCK_RELOCATION_RETRY_SECONDS
        noise_relocation_requested.emit(_investigation_target)

func _update_bell_chase() -> void:
    if _preview_player_hidden:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    if not is_instance_valid(_player_target):
        velocity = Vector3.ZERO
        move_and_slide()
        return

    var safe_room_id := _preview_safe_room_at(_player_target.global_position)
    if safe_room_id != &"":
        _update_window_lurk(safe_room_id)
        return
    _bell_lurk_room_id = &""
    _navigation_agent.target_desired_distance = 0.5

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
    var delta_time := get_physics_process_delta_time()
    var low_header_ahead := _has_low_overhead_clearance(direction)
    _update_squeeze(direction, delta_time, low_header_ahead)
    velocity = direction * preview_bell_chase_speed
    var centerline_is_clear := _is_centerline_clear(direction)
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)
    var squeezed_against_doorway := false
    for collision_index in get_slide_collision_count():
        if absf(get_slide_collision(collision_index).get_normal().y) < 0.5 and centerline_is_clear:
            squeezed_against_doorway = true
            break
    _update_squeeze(direction, delta_time, squeezed_against_doorway or low_header_ahead)

func _preview_safe_room_at(world_position: Vector3) -> StringName:
    for floor_node in get_tree().get_nodes_in_group("preview_safe_room_floors"):
        var room_id: StringName = floor_node.get_meta("preview_room_id", &"")
        if not _active_safe_room_ids.has(room_id):
            continue
        var bounds: AABB = floor_node.get_meta("preview_room_bounds")
        if (world_position.x >= bounds.position.x and world_position.x <= bounds.end.x
                and world_position.z >= bounds.position.z and world_position.z <= bounds.end.z):
            return room_id
    return &""

func _update_window_lurk(room_id: StringName) -> void:
    var markers: Array[Node] = []
    for marker in get_tree().get_nodes_in_group("preview_bell_lurk_points"):
        if marker.get_meta("preview_room_id", &"") == room_id:
            markers.append(marker)
    if markers.is_empty():
        velocity = Vector3.ZERO
        move_and_slide()
        return
    markers.sort_custom(func(a: Node, b: Node) -> bool:
        return float(a.get_meta("lurk_angle", 0.0)) < float(b.get_meta("lurk_angle", 0.0))
    )
    if _bell_lurk_room_id != room_id:
        _bell_lurk_room_id = room_id
        _bell_lurk_marker_index = 0
        _navigation_agent.target_desired_distance = 0.35
        var nearest_distance := INF
        for index in markers.size():
            var distance := global_position.distance_squared_to((markers[index] as Node3D).global_position)
            if distance < nearest_distance:
                nearest_distance = distance
                _bell_lurk_marker_index = index
        _navigation_agent.target_position = (markers[_bell_lurk_marker_index] as Node3D).global_position
    var marker_target := (markers[_bell_lurk_marker_index] as Node3D).global_position
    var to_marker := marker_target - global_position
    to_marker.y = 0.0
    if to_marker.length() <= 0.55:
        _bell_lurk_marker_index = (_bell_lurk_marker_index + 1) % markers.size()
        marker_target = (markers[_bell_lurk_marker_index] as Node3D).global_position
        _navigation_agent.target_position = marker_target
        to_marker = marker_target - global_position
        to_marker.y = 0.0
    if to_marker.length_squared() < 0.01:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    var direction := _navigation_agent.get_next_path_position() - global_position
    direction.y = 0.0
    if direction.length_squared() < 0.01:
        direction = to_marker
    direction = direction.normalized()
    var delta_time := get_physics_process_delta_time()
    var low_header_ahead := _has_low_overhead_clearance(direction)
    _update_squeeze(direction, delta_time, low_header_ahead)
    velocity = direction * preview_bell_window_lurk_speed
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)
    _update_squeeze(direction, delta_time, low_header_ahead)

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
    _apply_squeeze_shape()

func _apply_squeeze_shape() -> void:
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

func _has_low_overhead_clearance(direction: Vector3) -> bool:
    direction.y = 0.0
    var probe_positions: Array[Vector3] = [global_position]
    if direction.length_squared() >= 0.001:
        probe_positions.append(global_position + direction.normalized() * (_base_capsule_radius + 0.25))
    for probe_position in probe_positions:
        var ray_start := probe_position + Vector3.UP * (preview_squeeze_height - 0.05)
        var ray_end := probe_position + Vector3.UP * (_base_capsule_height - 0.05)
        var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1, [get_rid()])
        if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
            return true
    return false

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

    var can_see_target := _can_see_from_ruler_spotlight() if _preview_ruler_hall_active else _can_see_player()
    if can_see_target:
        _lost_sight_time = 0.0
    else:
        _lost_sight_time += delta
        if _lost_sight_time >= preview_lose_sight_grace:
            if _preview_item_encounter == &"snack":
                if _preview_snack_phase == &"rushing" and _preview_item_points.size() >= 3:
                    _preview_snack_peek_index = 2 if _preview_snack_peek_index == 1 else 1
                _preview_snack_phase = &"returning"
                if not _preview_item_points.is_empty():
                    _navigation_agent.target_position = _preview_item_points[0]
                    _preview_item_last_navigation_target = _preview_item_points[0]
            _set_state(&"PATROL")
            return

    var direction := _player_target.global_position - global_position
    direction.y = 0.0
    if direction.length_squared() < 0.01:
        velocity = Vector3.ZERO
        move_and_slide()
        return

    var low_header_ahead := false
    if _preview_item_encounter == &"snack":
        _preview_snack_path_refresh -= delta
        if (_preview_snack_path_refresh <= 0.0
                or _navigation_agent.target_position.distance_to(_player_target.global_position) > 0.5):
            _navigation_agent.target_position = _player_target.global_position
            _preview_snack_path_refresh = 0.2
        direction = _navigation_agent.get_next_path_position() - global_position
        direction.y = 0.0
        if direction.length_squared() < 0.01:
            direction = _player_target.global_position - global_position
            direction.y = 0.0
        low_header_ahead = _has_low_overhead_clearance(direction)
        _update_squeeze(direction, delta, low_header_ahead)
    if direction.length_squared() < 0.01:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    direction = direction.normalized()
    var chase_speed := preview_ruler_spotlight_chase_speed if _preview_ruler_hall_active else (preview_snack_rush_speed if _preview_item_encounter == &"snack" else preview_short_chase_speed)
    velocity = direction * chase_speed
    var centerline_is_clear := _is_centerline_clear(direction)
    move_and_slide()
    look_at(global_position + direction, Vector3.UP)
    if _preview_item_encounter == &"snack":
        var squeezed_against_opening := low_header_ahead
        for collision_index in get_slide_collision_count():
            if absf(get_slide_collision(collision_index).get_normal().y) < 0.5 and centerline_is_clear:
                squeezed_against_opening = true
                break
        _update_squeeze(direction, delta, squeezed_against_opening)

func _can_see_player() -> bool:
    if _preview_player_hidden:
        return false
    if not is_instance_valid(_player_target):
        return false

    var player_movement_state: Variant = _player_target.get("movement_state")
    var snack_standing_target_height := 1.3 if _preview_item_encounter == &"snack" else 0.75
    var target_height := 0.42 if player_movement_state == &"crouching" else snack_standing_target_height
    var visible_target := _player_target.global_position + Vector3.UP * target_height
    var target_local := global_transform.affine_inverse() * visible_target
    var forward_distance := -target_local.z
    if forward_distance <= 0.05 or forward_distance > sight_distance:
        return false

    var cone_half_width_at_target := sight_half_width * (forward_distance / sight_distance)
    if absf(target_local.x) > cone_half_width_at_target:
        return false

    var ray_start := global_position + Vector3.UP * 1.5
    var ray_end := visible_target
    var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
    query.collision_mask = 1
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.get("collider") == _player_target

func _can_see_from_ruler_spotlight() -> bool:
    if _preview_player_hidden or not is_instance_valid(_player_target) or not is_instance_valid(_search_cone):
        return false
    var target_local := _search_cone.global_transform.affine_inverse() * _player_target.global_position
    var forward_distance := -target_local.z
    if forward_distance <= 0.05 or forward_distance > sight_distance:
        return false
    var cone_half_width_at_target := sight_half_width * (forward_distance / sight_distance)
    if absf(target_local.x) > cone_half_width_at_target:
        return false
    var ray_start := _search_cone.global_position + Vector3.UP * 1.5
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
    if next_state == &"PATROL":
        _squeeze_amount = 0.0
        _apply_squeeze_shape()
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

    var cone := get_node_or_null("OpaqueSearchCone") as MeshInstance3D
    if cone == null:
        cone = MeshInstance3D.new()
        cone.name = "OpaqueSearchCone"
        add_child(cone)
    cone.mesh = cone_mesh
    cone.material_override = cone_material
    _search_cone = cone
