extends Node3D

signal opened(door_id: StringName, world_position: Vector3, loudness: float)

@export var preview_open_seconds: float = 1.8
@export var preview_trigger_distance: float = 1.35

var door_id: StringName
var is_double := false
var one_way := false
var operable_side := Vector3.ZERO
var _player: Node3D
var _panels: Array[Node3D] = []
var _opened := false
var _door_width := 1.0

func configure(id: StringName, center: Vector3, width: float, height: float, thickness: float,
		player: Node3D, double_door: bool, restricted: bool, allowed_side: Vector3, along_z: bool) -> void:
	door_id = id
	position = center
	_player = player
	_door_width = width
	is_double = double_door
	one_way = restricted
	operable_side = allowed_side.normalized()
	if along_z:
		rotation.y = PI * 0.5
	_create_panels(width, height, thickness)

func _physics_process(_delta: float) -> void:
	if _opened or not is_instance_valid(_player):
		return
	var offset := _player.global_position - global_position
	offset.y = 0.0
	var local_offset := global_basis.inverse() * offset
	if absf(local_offset.x) > _door_width * 0.5 + preview_trigger_distance or absf(local_offset.z) > preview_trigger_distance:
		return
	if one_way and offset.dot(operable_side) <= 0.0:
		return
	_open_door(offset)

func _create_panels(width: float, height: float, thickness: float) -> void:
	var panel_count := 2 if is_double else 1
	var panel_width := width / float(panel_count) - 0.035
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(panel_width, height, thickness)
	var panel_shape := BoxShape3D.new()
	panel_shape.size = panel_mesh.size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.20, 0.10)
	material.roughness = 0.82
	for index in range(panel_count):
		var hinge := Node3D.new()
		hinge.name = "DoorLeaf%d" % (index + 1)
		var side := 0.0 if not is_double else (-1.0 if index == 0 else 1.0)
		hinge.position.x = -width * 0.5 if not is_double else side * width * 0.5
		add_child(hinge)
		var body := AnimatableBody3D.new()
		body.sync_to_physics = true
		body.collision_layer = 1
		body.collision_mask = 1
		hinge.add_child(body)
		var mesh := MeshInstance3D.new()
		mesh.mesh = panel_mesh
		mesh.material_override = material
		mesh.position.x = -side * panel_width * 0.5 if is_double else panel_width * 0.5
		mesh.position.y = height * 0.5
		body.add_child(mesh)
		var collision := CollisionShape3D.new()
		collision.shape = panel_shape
		collision.position = mesh.position
		body.add_child(collision)
		_panels.append(hinge)

func _open_door(player_offset: Vector3) -> void:
	_opened = true
	opened.emit(door_id, global_position, 0.7)
	var normal := global_basis * Vector3.BACK
	var player_side := 1.0 if player_offset.dot(normal) >= 0.0 else -1.0
	if one_way:
		player_side = 1.0 if operable_side.dot(normal) >= 0.0 else -1.0
	for index in range(_panels.size()):
		var hinge := _panels[index]
		var hinge_sign := 1.0 if not is_double or index == 1 else -1.0
		var swing_sign := -player_side * hinge_sign
		var tween := create_tween()
		tween.tween_property(hinge, "rotation:y", swing_sign * PI * 0.48, preview_open_seconds)
