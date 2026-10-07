extends Node3D

@export var generate_school_collision: bool = true

@onready var school: Node3D = $School
@onready var player: CharacterBody3D = $PlayerPlaceholder
@onready var monster: CharacterBody3D = $MonsterPlaceholder
@onready var preview_environment: WorldEnvironment = $WorldEnvironment
@onready var preview_light: DirectionalLight3D = $PreviewLight
@onready var bell_status: Label = $DebugOverlay/BellStatus

const NORMAL_BACKGROUND := Color(0.055, 0.07, 0.1, 1.0)
const NORMAL_AMBIENT := Color(0.55, 0.62, 0.75, 1.0)
const BELL_BACKGROUND := Color(0.12, 0.018, 0.028, 1.0)
const BELL_AMBIENT := Color(0.68, 0.075, 0.095, 1.0)

var _bell_debug_active := false

func _ready() -> void:
    _load_school_model()
    if generate_school_collision:
        _add_school_collisions(school)
    _place_player_at_nurse_office()
    _place_monster_deeper_in_hallway()
    monster.set_player_target(player)
    _apply_bell_debug_state()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Z:
        _bell_debug_active = not _bell_debug_active
        _apply_bell_debug_state()
        get_viewport().set_input_as_handled()

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
