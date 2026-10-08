extends Node3D

signal opened(door_id: StringName, world_position: Vector3, loudness: float)
signal open_state_changed(door_id: StringName, is_open: bool)

@export var preview_open_seconds: float = 1.8
@export var preview_trigger_distance: float = 0.5
@export var preview_one_way_hold_seconds: float = 1.0

var door_id: StringName
var is_double := false
var one_way := false
var operable_side := Vector3.ZERO
var _player: Node3D
var _monster: Node3D
var _panels: Array[Node3D] = []
var _panel_bodies: Array[AnimatableBody3D] = []
var _opened := false
var _door_width := 1.0
var _is_animating := false
var _noise_emitted := false

func configure(id: StringName, center: Vector3, width: float, height: float, thickness: float,
		player: Node3D, monster: Node3D, double_door: bool, restricted: bool, allowed_side: Vector3, along_z: bool) -> void:
	door_id = id
	position = center
	_player = player
	_monster = monster
	_door_width = width
	is_double = double_door
	one_way = restricted
	operable_side = allowed_side.normalized()
	if along_z:
		rotation.y = PI * 0.5
	_create_panels(width, height, thickness)

func _physics_process(_delta: float) -> void:
	if _opened or _is_animating or not is_instance_valid(_player):
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
		_panel_bodies.append(body)
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
	_is_animating = true
	if not _noise_emitted:
		_noise_emitted = true
		opened.emit(door_id, global_position, 0.7)
	var normal := global_basis * Vector3.BACK
	var player_side := 1.0 if player_offset.dot(normal) >= 0.0 else -1.0
	if one_way:
		player_side = 1.0 if operable_side.dot(normal) >= 0.0 else -1.0
	var tween := create_tween()
	tween.set_parallel(true)
	for index in range(_panels.size()):
		var hinge := _panels[index]
		var hinge_sign := -1.0 if index == 0 else 1.0
		var swing_sign := -player_side * hinge_sign
		tween.tween_property(hinge, "rotation:y", swing_sign * PI * 0.48, preview_open_seconds)
	tween.set_parallel(false)
	await tween.finished
	_release_open_door_collision()
	_is_animating = false
	open_state_changed.emit(door_id, true)
	if one_way:
		_close_one_way_after_player_passes()

func _close_one_way_after_player_passes() -> void:
	await get_tree().create_timer(preview_one_way_hold_seconds).timeout
	while is_instance_valid(_player) and (not _actor_cleared_of_doorway(_player) or not _monster_clear_of_doorway()):
		await get_tree().physics_frame
	if not is_instance_valid(_player):
		return
	_is_animating = true
	var tween := create_tween()
	tween.set_parallel(true)
	for hinge in _panels:
		tween.tween_property(hinge, "rotation:y", 0.0, preview_open_seconds)
	tween.set_parallel(false)
	await tween.finished
	_opened = false
	_is_animating = false
	_noise_emitted = false
	for body in _panel_bodies:
		if is_instance_valid(body):
			body.collision_layer = 1
			body.collision_mask = 1
	open_state_changed.emit(door_id, false)

func _actor_cleared_of_doorway(actor: Node3D) -> bool:
	var offset := global_basis.inverse() * (actor.global_position - global_position)
	return absf(offset.x) > _door_width * 0.5 + 0.55 or absf(offset.z) > 0.7

func _monster_clear_of_doorway() -> bool:
	if not is_instance_valid(_monster):
		return true
	var state: StringName = _monster.get("current_state")
	if state in [&"INVESTIGATE", &"SHORT_CHASE", &"BELL_CHASE"]:
		return false
	return _actor_cleared_of_doorway(_monster)

func _release_open_door_collision() -> void:
	for body in _panel_bodies:
		if is_instance_valid(body):
			body.collision_layer = 0
			body.collision_mask = 0
