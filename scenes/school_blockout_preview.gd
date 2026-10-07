extends Node3D

@export var generate_school_collision: bool = true

@onready var school: Node3D = $School
@onready var player: CharacterBody3D = $PlayerPlaceholder
@onready var monster: CharacterBody3D = $MonsterPlaceholder
@onready var preview_environment: WorldEnvironment = $WorldEnvironment
@onready var preview_light: DirectionalLight3D = $PreviewLight
@onready var bell_status: Label = $DebugOverlay/BellStatus
@onready var spawn_help: Label = $DebugOverlay/SpawnHelp

const NORMAL_BACKGROUND := Color(0.055, 0.07, 0.1, 1.0)
const NORMAL_AMBIENT := Color(0.55, 0.62, 0.75, 1.0)
const BELL_BACKGROUND := Color(0.12, 0.018, 0.028, 1.0)
const BELL_AMBIENT := Color(0.68, 0.075, 0.095, 1.0)
const PREVIEW_RELOCATION_INTERVAL := 10.0

var _bell_debug_active := false
var _spawn_markers: Array[Node3D] = []
var _spawn_marker_nodes_visible := true
var _preview_relocation_elapsed := 0.0

func _ready() -> void:
    _load_school_model()
    if generate_school_collision:
        _add_school_collisions(school)
    _build_school_navigation()
    await get_tree().physics_frame
    await get_tree().physics_frame
    await _wait_for_navigation_map()
    _place_player_at_nurse_office()
    _place_monster_deeper_in_hallway()
    monster.set_player_target(player)
    _create_monster_spawn_locations()
    _apply_bell_debug_state()

func _process(delta: float) -> void:
    if _bell_debug_active or monster.current_state == &"SHORT_CHASE" or monster.current_state == &"BELL_CHASE":
        return
    _preview_relocation_elapsed += delta
    if _preview_relocation_elapsed < PREVIEW_RELOCATION_INTERVAL:
        return
    _preview_relocation_elapsed = 0.0
    _try_debug_offscreen_relocation()

func _wait_for_navigation_map() -> void:
    var navigation_agent: NavigationAgent3D = monster.get_node("NavigationAgent3D")
    var navigation_map: RID = navigation_agent.get_navigation_map()
    var nurse_floor: MeshInstance3D = _find_nurse_floor(school)
    if nurse_floor == null or nurse_floor.mesh == null:
        return
    var bounds: AABB = nurse_floor.global_transform * nurse_floor.mesh.get_aabb()
    var sample_position := Vector3(
        bounds.position.x + bounds.size.x * 0.5,
        bounds.position.y + bounds.size.y,
        bounds.position.z + bounds.size.z * 0.5
    )
    for frame_index in range(120):
        var nearest_point: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, sample_position)
        if NavigationServer3D.map_get_iteration_id(navigation_map) > 0 and nearest_point.distance_to(sample_position) <= 1.35:
            return
        await get_tree().physics_frame

func _build_school_navigation() -> void:
    var region := NavigationRegion3D.new()
    region.name = "MonsterNavigation"
    var nav_mesh := NavigationMesh.new()
    nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
    nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
    nav_mesh.geometry_collision_mask = 1
    nav_mesh.agent_radius = 0.1
    nav_mesh.agent_height = 1.8
    nav_mesh.agent_max_climb = 0.2
    nav_mesh.cell_size = 0.1
    nav_mesh.cell_height = 0.1
    nav_mesh.sample_partition_type = NavigationMesh.SAMPLE_PARTITION_MONOTONE
    region.navigation_mesh = nav_mesh
    var school_transform := school.global_transform
    remove_child(school)
    add_child(region)
    region.add_child(school)
    school.global_transform = school_transform
    NavigationServer3D.map_set_cell_size(region.get_navigation_map(), nav_mesh.cell_size)
    NavigationServer3D.map_set_cell_height(region.get_navigation_map(), nav_mesh.cell_height)
    region.bake_navigation_mesh(false)
    if region.navigation_mesh.get_polygon_count() == 0:
        push_error("Monster navigation mesh bake produced no walkable polygons.")

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if event.keycode == KEY_Z:
        _bell_debug_active = not _bell_debug_active
        _apply_bell_debug_state()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_M:
        _spawn_marker_nodes_visible = not _spawn_marker_nodes_visible
        for marker in _spawn_markers:
            marker.visible = _spawn_marker_nodes_visible
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_X:
        _try_debug_offscreen_relocation()
        get_viewport().set_input_as_handled()

func _create_monster_spawn_locations() -> void:
    # Fractions are measured across the named room floor bounds. Entries are
    # preview candidates only; excluded rooms are checked again before creation.
    var candidates: Array[Dictionary] = [
        {"id": "hall_corner_lobby_west", "floor": "lobby floor", "u": 0.12, "v": 0.22, "kind": "Beyond hallway corner"},
        {"id": "hall_corner_lobby_east", "floor": "lobby floor", "u": 0.92, "v": 0.78, "kind": "Beyond hallway corner"},
        {"id": "hall_corner_auditorium_wing", "floor": "school site floor - circulation", "x": 6.5, "z": -5.0, "kind": "Beyond hallway corner"},
        {"id": "hall_corner_cafe_science", "floor": "school site floor - circulation", "x": 22.5, "z": 11.0, "kind": "Beyond hallway corner"},
        {"id": "hall_corner_classroom_cd", "floor": "school site floor - circulation", "x": 20.0, "z": 15.5, "kind": "Beyond hallway corner"},
        {"id": "hall_corner_science_class_e", "floor": "school site floor - circulation", "x": 28.0, "z": 16.0, "kind": "Beyond hallway corner"},
        {"id": "t_intersection_lobby", "floor": "lobby floor", "u": 0.70, "v": 0.48, "kind": "T-intersection"},
        {"id": "behind_lobby_pillar", "floor": "lobby floor", "u": 0.49, "v": 0.83, "kind": "Behind pillar"},
        {"id": "behind_locker_bank_hall", "floor": "", "u": 0.0, "v": 0.0, "kind": "Behind lockers (hall side)"},
        {"id": "behind_player_nurse", "floor": "nurse office floor", "u": 0.78, "v": 0.80, "kind": "Behind player"},
        {"id": "far_end_lobby_hall", "floor": "lobby floor", "u": 0.96, "v": 0.45, "kind": "Far end of hall"},
        {"id": "class_a_door", "floor": "classroom a floor", "u": 0.36, "v": 0.68, "kind": "Inside classroom doorway"},
        {"id": "class_c_door", "floor": "classroom c floor", "u": 0.48, "v": 0.73, "kind": "Inside classroom doorway"},
        {"id": "class_d_door", "floor": "classroom d floor", "u": 0.48, "v": 0.73, "kind": "Inside classroom doorway"},
        {"id": "class_e_door", "floor": "classroom e floor", "u": 0.42, "v": 0.79, "kind": "Inside classroom doorway"},
        {"id": "class_a_window_west", "floor": "classroom a floor", "u": 0.15, "v": 0.45, "kind": "Behind classroom window"},
        {"id": "class_a_window_north", "floor": "classroom a floor", "u": 0.76, "v": 0.16, "kind": "Behind classroom window"},
        {"id": "class_c_window_west", "floor": "classroom c floor", "u": 0.15, "v": 0.44, "kind": "Behind classroom window"},
        {"id": "class_d_window_east", "floor": "classroom d floor", "u": 0.85, "v": 0.45, "kind": "Behind classroom window"},
        {"id": "class_e_window_west", "floor": "classroom e floor", "u": 0.14, "v": 0.48, "kind": "Behind classroom window"},
        {"id": "class_e_window_north", "floor": "classroom e floor", "u": 0.76, "v": 0.15, "kind": "Behind classroom window"},
        {"id": "inside_auditorium", "floor": "auditorium floor", "u": 0.84, "v": 0.18, "kind": "Inside room"},
        {"id": "inside_gym", "floor": "gym floor", "u": 0.18, "v": 0.82, "kind": "Inside room"},
        {"id": "inside_class_a", "floor": "classroom a floor", "u": 0.80, "v": 0.78, "kind": "Inside room"},
        {"id": "inside_class_c", "floor": "classroom c floor", "u": 0.80, "v": 0.24, "kind": "Inside room"},
        {"id": "inside_class_d", "floor": "classroom d floor", "u": 0.20, "v": 0.24, "kind": "Inside room"},
        {"id": "inside_class_e", "floor": "classroom e floor", "u": 0.82, "v": 0.54, "kind": "Inside room"},
        {"id": "inside_nurse_office", "floor": "nurse office floor", "u": 0.25, "v": 0.24, "kind": "Inside room"},
        {"id": "inside_bathroom", "floor": "bathroom floor", "u": 0.24, "v": 0.75, "kind": "Inside room"}
    ]
    var excluded_floor_names: Array[String] = [
        "main office floor", "locker room floor", "library floor", "artroom floor",
        "art room floor", "lab room floor", "classroom b floor", "cafeteria floor",
        "outside floor", "storage closet floor"
    ]
    var navigation_agent: NavigationAgent3D = monster.get_node("NavigationAgent3D")
    var navigation_map: RID = navigation_agent.get_navigation_map()
    for candidate in candidates:
        var spawn_position: Vector3
        if candidate.has("x") and candidate.has("z"):
            var circulation_floor := _find_room_floor(school, candidate["floor"])
            if circulation_floor == null or circulation_floor.mesh == null:
                continue
            var circulation_bounds: AABB = circulation_floor.global_transform * circulation_floor.mesh.get_aabb()
            spawn_position = Vector3(float(candidate["x"]), circulation_bounds.position.y + circulation_bounds.size.y, float(candidate["z"]))
        elif candidate["id"] == "behind_locker_bank_hall":
            var locker_floor := _find_room_floor(school, "locker room floor")
            if locker_floor == null or locker_floor.mesh == null:
                continue
            var locker_bounds: AABB = locker_floor.global_transform * locker_floor.mesh.get_aabb()
            spawn_position = Vector3(locker_bounds.end.x + 0.75, locker_bounds.position.y + locker_bounds.size.y, locker_bounds.position.z + locker_bounds.size.z * 0.5)
        else:
            var room_floor := _find_room_floor(school, candidate["floor"])
            if room_floor == null or room_floor.mesh == null:
                continue
            var bounds: AABB = room_floor.global_transform * room_floor.mesh.get_aabb()
            spawn_position = Vector3(
                bounds.position.x + bounds.size.x * float(candidate["u"]),
                bounds.position.y + bounds.size.y,
                bounds.position.z + bounds.size.z * float(candidate["v"])
            )
        if _position_in_excluded_floor(spawn_position, excluded_floor_names):
            continue
        var closest_nav_point: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, spawn_position)
        if closest_nav_point.distance_to(spawn_position) > 1.35:
            continue
        if _position_in_excluded_floor(closest_nav_point, excluded_floor_names):
            continue
        _spawn_markers.append(_make_spawn_panel(candidate, closest_nav_point))
    spawn_help.text = "Spawn panels: %d   Auto relocate: 10s while not chasing   M: toggle   X: test" % _spawn_markers.size()

func _make_spawn_panel(candidate: Dictionary, spawn_position: Vector3) -> Node3D:
    var marker := Node3D.new()
    marker.name = "Spawn_" + String(candidate["id"])
    marker.position = spawn_position
    marker.add_to_group("monster_spawn_points")
    marker.set_meta("spawn_kind", candidate["kind"])
    marker.set_meta("spawn_id", candidate["id"])
    var panel := MeshInstance3D.new()
    panel.name = "TemporaryGreenPanel"
    var panel_mesh := QuadMesh.new()
    panel_mesh.size = Vector2(0.48, 0.48)
    panel.mesh = panel_mesh
    panel.position.y = 1.0
    panel.rotation_degrees.x = 90.0
    panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var panel_material := StandardMaterial3D.new()
    panel_material.albedo_color = Color(0.12, 1.0, 0.18, 1.0)
    panel_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    panel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    panel.material_override = panel_material
    marker.add_child(panel)
    school.add_child(marker)
    return marker

func _position_in_excluded_floor(position: Vector3, excluded_names: Array[String]) -> bool:
    for floor_name in excluded_names:
        var floor_node := _find_room_floor(school, floor_name)
        if floor_node == null or floor_node.mesh == null:
            continue
        var bounds: AABB = floor_node.global_transform * floor_node.mesh.get_aabb()
        var inside_x := position.x >= bounds.position.x and position.x <= bounds.end.x
        var inside_z := position.z >= bounds.position.z and position.z <= bounds.end.z
        if inside_x and inside_z:
            return true
    return false

func _try_debug_offscreen_relocation() -> void:
    if _bell_debug_active or _spawn_markers.is_empty():
        return
    var shuffled := _spawn_markers.duplicate()
    shuffled.shuffle()
    for marker in shuffled:
        if monster.try_preview_offscreen_teleport(marker.global_position, player.player_camera):
            return

func _load_school_model() -> void:
    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var error: Error = document.append_from_file("res://assets/school_blockout.glb", state)
    if error != OK:
        push_error("Could not load assets/school_blockout.glb (error %s)." % error)
        return
    var model: Node = document.generate_scene(state)
    model.name = "SchoolModel"
    school.add_child(model)

func _add_school_collisions(node: Node) -> void:
    if node is MeshInstance3D and node.mesh != null:
        var lower_name: String = node.name.to_lower()
        if lower_name.contains("wall") or lower_name.contains("floor") or lower_name.contains("roof"):
            var shape: Shape3D = node.mesh.create_trimesh_shape()
            if shape != null:
                var body := StaticBody3D.new()
                body.name = "StaticCollision"
                body.collision_layer = 1
                body.collision_mask = 1
                node.add_child(body)
                var collision := CollisionShape3D.new()
                collision.shape = shape
                body.add_child(collision)

    for child in node.get_children():
        _add_school_collisions(child)

func _place_player_at_nurse_office() -> void:
    var nurse_floor: MeshInstance3D = _find_nurse_floor(school)
    if nurse_floor != null and nurse_floor.mesh != null:
        var bounds: AABB = nurse_floor.global_transform * nurse_floor.mesh.get_aabb()
        player.global_position = Vector3(
            bounds.position.x + bounds.size.x * 0.5,
            bounds.position.y + bounds.size.y,
            bounds.position.z + bounds.size.z * 0.5
        )
    else:
        player.position = Vector3(38.6, 0.14, 28.35)

func _place_monster_deeper_in_hallway() -> void:
    var lobby_floor: MeshInstance3D = _find_room_floor(school, "lobby floor")
    if lobby_floor == null or lobby_floor.mesh == null:
        monster.global_position = player.global_position + Vector3(-8.0, 0.0, -3.0)
        monster.start_preview_hallway_patrol(Vector3.RIGHT)
        return

    var bounds: AABB = lobby_floor.global_transform * lobby_floor.mesh.get_aabb()
    var center := bounds.position + bounds.size * 0.5
    var inner_room_floor: MeshInstance3D = _find_room_floor(school, "classroom d floor")
    var inner_target := center + Vector3(-2.0, 0.0, -3.0)
    if inner_room_floor != null and inner_room_floor.mesh != null:
        var inner_bounds: AABB = inner_room_floor.global_transform * inner_room_floor.mesh.get_aabb()
        inner_target = inner_bounds.position + inner_bounds.size * 0.5
    var direction := inner_target - center
    direction.y = 0.0
    if direction.length_squared() > 0.001:
        direction = direction.normalized()
    else:
        direction = Vector3(0.0, 0.0, -1.0)

    monster.global_position = Vector3(
        center.x + direction.x * 2.5,
        bounds.position.y + bounds.size.y,
        center.z + direction.z * 2.5
    )
    monster.start_preview_hallway_patrol(Vector3.RIGHT)

func _apply_bell_debug_state() -> void:
    preview_environment.environment.background_color = BELL_BACKGROUND if _bell_debug_active else NORMAL_BACKGROUND
    preview_environment.environment.ambient_light_color = BELL_AMBIENT if _bell_debug_active else NORMAL_AMBIENT
    preview_light.light_color = Color(1.0, 0.12, 0.16) if _bell_debug_active else Color.WHITE
    bell_status.text = "BELL DEBUG: ON (Z)" if _bell_debug_active else "BELL DEBUG: OFF (Z)"
    monster.call("set_preview_bell_active", _bell_debug_active)

func _find_room_floor(node: Node, room_name: String) -> MeshInstance3D:
    if node is MeshInstance3D and node.name.to_lower().contains(room_name):
        return node
    for child in node.get_children():
        var found: MeshInstance3D = _find_room_floor(child, room_name)
        if found != null:
            return found
    return null

func _find_nurse_floor(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D and node.name.to_lower().contains("nurse office floor"):
        return node
    for child in node.get_children():
        var found: MeshInstance3D = _find_nurse_floor(child)
        if found != null:
            return found
    return null
