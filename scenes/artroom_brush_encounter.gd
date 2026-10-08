extends Node3D

@export_range(5.0, 120.0, 1.0) var preview_searchlight_turn_degrees: float = 48.0
@export_range(0.25, 3.0, 0.05) var preview_searchlight_half_width: float = 1.8

var _monster: CharacterBody3D
var _active := false
var _original_position := Vector3.ZERO
var _original_rotation := Vector3.ZERO
var _original_collision_layer := 2
var _original_collision_mask := 1
var _sweep_pivot: Node3D
var _room_bounds := AABB()
var _player: Node3D
var _chase_started := false


func configure(monster: CharacterBody3D, player: Node3D) -> void:
	_monster = monster
	_player = player


func begin_brush_escape(room_bounds: AABB, ceiling_height: float) -> void:
	if _active or not is_instance_valid(_monster):
		return
	_active = true
	_chase_started = false
	_room_bounds = room_bounds
	_original_position = _monster.global_position
	_original_rotation = _monster.global_rotation
	_original_collision_layer = _monster.collision_layer
	_original_collision_mask = _monster.collision_mask
	_monster.set_physics_process(false)
	_monster.velocity = Vector3.ZERO
	_monster.collision_layer = 0
	_monster.collision_mask = 0
	_monster.global_position = Vector3(
		room_bounds.position.x + room_bounds.size.x * 0.5,
		ceiling_height,
		room_bounds.position.z + room_bounds.size.z * 0.5
	)
	_monster.rotation = Vector3(PI, 0.0, 0.0)
	var cone := _monster.get_node_or_null("OpaqueSearchCone") as MeshInstance3D
	if is_instance_valid(cone):
		cone.visible = false
	_create_sweeping_searchlight()


func finish_brush_escape() -> void:
	if not _active or not is_instance_valid(_monster):
		return
	_active = false
	if is_instance_valid(_sweep_pivot):
		_sweep_pivot.queue_free()
	_sweep_pivot = null
	_monster.global_position = _original_position
	_monster.global_rotation = _original_rotation
	_monster.collision_layer = _original_collision_layer
	_monster.collision_mask = _original_collision_mask
	_monster.set_physics_process(true)
	_monster.call("end_preview_item_encounter")
	_monster.call("refresh_preview_navigation")


func _physics_process(delta: float) -> void:
	if not _active or _chase_started or not is_instance_valid(_sweep_pivot):
		return
	_sweep_pivot.rotation.y = wrapf(
		_sweep_pivot.rotation.y + deg_to_rad(preview_searchlight_turn_degrees) * delta,
		-TAU,
		TAU
	)
	if _player_in_sweeping_light():
		_chase_started = true
		_sweep_pivot.visible = false
		_monster.call("begin_preview_brush_chase")


func _player_in_sweeping_light() -> bool:
	if not is_instance_valid(_player) or not is_instance_valid(_sweep_pivot):
		return false
	if _monster.get("_preview_player_hidden"):
		return false
	var local_player := _sweep_pivot.global_transform.affine_inverse() * _player.global_position
	var forward_distance := -local_player.z
	var beam_length := Vector2(_room_bounds.size.x, _room_bounds.size.z).length() * 0.5
	if forward_distance <= 0.05 or forward_distance > beam_length or absf(local_player.y) > 1.5:
		return false
	var beam_half_width := preview_searchlight_half_width * (forward_distance / beam_length)
	if absf(local_player.x) > beam_half_width:
		return false
	var ray_start := _sweep_pivot.global_position + Vector3.UP * 0.08
	var ray_end := _player.global_position + Vector3.UP * 0.75
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1
	query.exclude = [_monster.get_rid()]
	var hit := _monster.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _player


func _create_sweeping_searchlight() -> void:
	_sweep_pivot = Node3D.new()
	_sweep_pivot.name = "BrushGroundSearchlightPivot"
	add_child(_sweep_pivot)
	_sweep_pivot.global_position = Vector3(
		_room_bounds.position.x + _room_bounds.size.x * 0.5,
		_room_bounds.position.y + _room_bounds.size.y + 0.035,
		_room_bounds.position.z + _room_bounds.size.z * 0.5
	)
	var beam := MeshInstance3D.new()
	beam.name = "BrushGroundSearchlight"
	beam.mesh = _make_searchlight_mesh()
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.78, 0.12, 1.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = material
	_sweep_pivot.add_child(beam)


func _make_searchlight_mesh() -> ArrayMesh:
	var radius := Vector2(_room_bounds.size.x, _room_bounds.size.z).length() * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	surface.add_vertex(Vector3(0.0, 0.0, 0.0))
	surface.add_vertex(Vector3(-preview_searchlight_half_width, 0.0, -radius))
	surface.add_vertex(Vector3(preview_searchlight_half_width, 0.0, -radius))
	return surface.commit()
