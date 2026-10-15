extends Node3D

signal opened(door_id: StringName, world_position: Vector3, loudness: float)
signal open_state_changed(door_id: StringName, is_open: bool)

@export var preview_open_seconds: float = 1.8
@export var preview_trigger_distance: float = 0.5
@export var preview_one_way_hold_seconds: float = 1.0

var door_id: StringName
var is_double := false
var one_way := false
var interaction_locked := false
var operable_side := Vector3.ZERO
var _player: Node3D
var _monster: Node3D
var _panels: Array[Node3D] = []
var _panel_bodies: Array[AnimatableBody3D] = []
var _panel_meshes: Array[MeshInstance3D] = []
var _door_material: StandardMaterial3D
var _glass_material: StandardMaterial3D
var _opened := false
var _door_width := 1.0
var _door_height := 2.15
var _door_thickness := 0.12
var _is_animating := false
var _noise_emitted := false

func configure(id: StringName, center: Vector3, width: float, height: float, thickness: float,
		player: Node3D, monster: Node3D, double_door: bool, restricted: bool, allowed_side: Vector3, along_z: bool) -> void:
	door_id = id
	position = center
	_player = player
	_monster = monster
	_door_width = width
	_door_height = height
	_door_thickness = thickness
	is_double = double_door
	one_way = restricted
	operable_side = allowed_side.normalized()
	if along_z:
		rotation.y = PI * 0.5
	_create_panels(width, height, thickness)

func _physics_process(_delta: float) -> void:
	if interaction_locked or _opened or _is_animating or not is_instance_valid(_player):
		return
	var offset := _player.global_position - global_position
	offset.y = 0.0
	var local_offset := global_basis.inverse() * offset
	if absf(local_offset.x) > _door_width * 0.5 + preview_trigger_distance or absf(local_offset.z) > preview_trigger_distance:
		return
	if one_way and offset.dot(operable_side) <= 0.0:
		return
	_open_door(offset)

func set_interaction_locked(locked: bool) -> void:
	interaction_locked = locked

func open_for_escape(opening_side: Vector3 = Vector3.ZERO) -> void:
	interaction_locked = false
	if _opened or _is_animating or _panels.is_empty():
		return
	if opening_side.length_squared() < 0.001 and is_instance_valid(_player):
		opening_side = _player.global_position - global_position
	_open_door(opening_side)

func set_one_way_from_world_side(allowed_side: Vector3) -> void:
	allowed_side.y = 0.0
	if allowed_side.length_squared() < 0.001:
		return
	one_way = true
	operable_side = allowed_side.normalized()

func set_glass_appearance() -> void:
	if _glass_material == null:
		_glass_material = StandardMaterial3D.new()
		_glass_material.albedo_color = Color(0.56, 0.82, 0.91, 0.26)
		_glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass_material.roughness = 0.12
		_glass_material.metallic = 0.08
		_glass_material.emission_enabled = true
		_glass_material.emission = Color(0.16, 0.34, 0.42)
	for mesh in _panel_meshes:
		if is_instance_valid(mesh):
			mesh.material_override = _glass_material
	_create_transom_window()

func _create_transom_window() -> void:
	var transom := Node3D.new()
	transom.name = "CrissCrossTransom"
	var window_width := maxf(0.38, _door_width - 0.06)
	var window_height := 0.42
	var frame_width := 0.04
	var depth := maxf(0.06, _door_thickness * 0.65)
	transom.position.y = _door_height + window_height * 0.5
	add_child(transom)
	var glass := MeshInstance3D.new()
	glass.name = "TransomGlass"
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(window_width - frame_width, window_height - frame_width, depth * 0.55)
	glass.mesh = glass_mesh
	glass.material_override = _glass_material
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	transom.add_child(glass)

	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.13, 0.18, 0.19, 1.0)
	frame_material.roughness = 0.38
	_add_transom_bar(transom, Vector3(window_width, frame_width, depth), Vector3(0.0, window_height * 0.5 - frame_width * 0.5, 0.0), 0.0, frame_material)
	_add_transom_bar(transom, Vector3(window_width, frame_width, depth), Vector3(0.0, -window_height * 0.5 + frame_width * 0.5, 0.0), 0.0, frame_material)
	_add_transom_bar(transom, Vector3(frame_width, window_height, depth), Vector3(-window_width * 0.5 + frame_width * 0.5, 0.0, 0.0), 0.0, frame_material)
	_add_transom_bar(transom, Vector3(frame_width, window_height, depth), Vector3(window_width * 0.5 - frame_width * 0.5, 0.0, 0.0), 0.0, frame_material)

	var lite_count := 2 if is_double else 1
	var divider_width := 0.035
	if lite_count == 2:
		_add_transom_bar(transom, Vector3(divider_width, window_height, depth), Vector3.ZERO, 0.0, frame_material)
	var lite_width := (window_width - frame_width * 2.0 - divider_width * float(lite_count - 1)) / float(lite_count)
	var grille_width := maxf(0.1, lite_width - frame_width * 2.0)
	var grille_height := window_height - frame_width * 2.0
	var diagonal_length := Vector2(grille_width, grille_height).length()
	var diagonal_angle := atan2(grille_height, grille_width)
	for lite_index in range(lite_count):
		var side := -1.0 if lite_count == 2 and lite_index == 0 else 1.0
		var lite_center_x := 0.0 if lite_count == 1 else side * (divider_width * 0.5 + lite_width * 0.5)
		_add_transom_bar(transom, Vector3(diagonal_length, 0.025, depth), Vector3(lite_center_x, 0.0, 0.0), diagonal_angle, frame_material)
		_add_transom_bar(transom, Vector3(diagonal_length, 0.025, depth), Vector3(lite_center_x, 0.0, 0.0), -diagonal_angle, frame_material)

func _add_transom_bar(parent: Node3D, size: Vector3, local_position: Vector3, angle: float, material: StandardMaterial3D) -> void:
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = size
	bar.mesh = bar_mesh
	bar.material_override = material
	bar.position = local_position
	bar.rotation.z = angle
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bar)

func _create_panels(width: float, height: float, thickness: float) -> void:
	var panel_count := 2 if is_double else 1
	var panel_width := width / float(panel_count) - 0.035
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(panel_width, height, thickness)
	var panel_shape := BoxShape3D.new()
	panel_shape.size = panel_mesh.size
	_door_material = StandardMaterial3D.new()
	_door_material.albedo_color = Color(0.34, 0.20, 0.10)
	_door_material.roughness = 0.82
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
		mesh.material_override = _door_material
		mesh.position.x = -side * panel_width * 0.5 if is_double else panel_width * 0.5
		mesh.position.y = height * 0.5
		body.add_child(mesh)
		_panel_meshes.append(mesh)
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

func slam_shut() -> void:
	if not _opened or _panels.is_empty():
		return
	_is_animating = true
	var tween := create_tween()
	tween.set_parallel(true)
	for hinge in _panels:
		tween.tween_property(hinge, "rotation:y", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
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
