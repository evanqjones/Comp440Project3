extends Node3D

@export_range(4.0, 20.0, 0.5) var sight_distance: float = 10.0
@export_range(1.0, 8.0, 0.25) var sight_half_width: float = 3.75

func _ready() -> void:
    _create_opaque_search_cone()

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
