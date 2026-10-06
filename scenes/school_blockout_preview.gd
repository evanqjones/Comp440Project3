extends Node3D

@export var generate_school_collision: bool = true

@onready var school: Node3D = $School
@onready var player: CharacterBody3D = $PlayerPlaceholder

func _ready() -> void:
    _load_school_model()
    if generate_school_collision:
        _add_school_collisions(school)
    _place_player_at_nurse_office()

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

func _find_nurse_floor(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D and node.name.to_lower().contains("nurse office floor"):
        return node
    for child in node.get_children():
        var found: MeshInstance3D = _find_nurse_floor(child)
        if found != null:
            return found
    return null