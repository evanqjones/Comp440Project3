extends Node

@export_range(5.0, 120.0, 1.0) var preview_turn_speed_degrees: float = 28.0
@export_range(5.0, 240.0, 5.0) var preview_noise_turn_speed_degrees: float = 90.0
@export_range(0.25, 5.0, 0.25) var preview_noise_attention_seconds: float = 1.5
@export_range(1.0, 15.0, 0.5) var preview_chase_speed: float = 6.5
@export_range(0.1, 3.0, 0.1) var preview_lose_sight_grace: float = 0.8
@export_range(0.5, 10.0, 0.1) var preview_pickup_turn_seconds: float = 3.0
@export_range(0.5, 10.0, 0.1) var preview_pickup_pause_seconds: float = 3.0

var _monster: CharacterBody3D
var _player: CharacterBody3D
var _navigation_agent: NavigationAgent3D
var _monster_noise_callable := Callable()
var _encounter_noise_callable := Callable()
var _phase: StringName = &""
var _active := false
var _path_refresh := 0.0
var _last_path_target := Vector3(INF, INF, INF)
var _lost_sight_time := 0.0
var _noise_attention_time := 0.0
var _original_facing := Vector3.FORWARD
var _phase_timer := 0.0
var _original_sight_distance := 3.0
var _original_sight_half_width := 1.125


func configure(monster: CharacterBody3D, player: CharacterBody3D) -> void:
	_monster = monster
	_player = player
	_navigation_agent = monster.get_node("NavigationAgent3D") as NavigationAgent3D
	_monster_noise_callable = Callable(monster, "receive_noise")
	_encounter_noise_callable = Callable(self, "receive_noise")


func begin_guard(room_bounds: AABB, stage_position: Vector3) -> void:
	if not is_instance_valid(_monster) or not is_instance_valid(_player):
		return
	_active = true
	_phase = &"guard"
	_lost_sight_time = 0.0
	_noise_attention_time = 0.0
	_path_refresh = 0.0
	_last_path_target = Vector3(INF, INF, INF)
	_original_facing = Vector3.FORWARD
	_original_sight_distance = float(_monster.get("sight_distance"))
	_original_sight_half_width = float(_monster.get("sight_half_width"))
	_monster.set("sight_distance", maxf(room_bounds.size.z + 1.0, 12.0))
	_monster.set("sight_half_width", room_bounds.size.x * 0.5)
	_monster.call("_create_opaque_search_cone")
	_route_noise_to_encounter(true)
	_monster.set_physics_process(false)
	_monster.global_position = stage_position
	_monster.velocity = Vector3.ZERO
	_monster.rotation.y = 0.0
	_navigation_agent.target_desired_distance = 0.55
	_monster.call("_set_state", &"PATROL")


func begin_escape() -> void:
	if not _active:
		return
	_phase = &"pickup_turn"
	_phase_timer = preview_pickup_turn_seconds
	_lost_sight_time = 0.0
	_last_path_target = Vector3(INF, INF, INF)
	_monster.call("_set_state", &"PATROL")


func finish_encounter() -> void:
	if not _active:
		return
	_active = false
	_phase = &""
	_route_noise_to_encounter(false)
	_monster.velocity = Vector3.ZERO
	_monster.set("sight_distance", _original_sight_distance)
	_monster.set("sight_half_width", _original_sight_half_width)
	_monster.call("_create_opaque_search_cone")
	_monster.set_physics_process(true)
	_monster.call("end_preview_item_encounter")
	_monster.call("_set_state", &"PATROL")


func is_active() -> bool:
	return _active


func _route_noise_to_encounter(enabled: bool) -> void:
	if not is_instance_valid(_player):
		return
	if enabled:
		if _player.is_connected(&"noise_emitted", _monster_noise_callable):
			_player.disconnect(&"noise_emitted", _monster_noise_callable)
		if not _player.is_connected(&"noise_emitted", _encounter_noise_callable):
			_player.connect(&"noise_emitted", _encounter_noise_callable)
	else:
		if _player.is_connected(&"noise_emitted", _encounter_noise_callable):
			_player.disconnect(&"noise_emitted", _encounter_noise_callable)
		if not _player.is_connected(&"noise_emitted", _monster_noise_callable):
			_player.connect(&"noise_emitted", _monster_noise_callable)


func receive_noise(_event: NoiseEvent) -> void:
	if _active and _phase == &"guard":
		_noise_attention_time = preview_noise_attention_seconds
		_monster.call("_set_state", &"PATROL")


func _physics_process(delta: float) -> void:
	if not _active or not is_instance_valid(_monster) or not is_instance_valid(_player):
		return
	match _phase:
		&"guard":
			_update_guard(delta)
		&"spotlight_chase":
			_update_spotlight_chase(delta)
		&"pickup_turn":
			_face_direction(_player.global_position - _monster.global_position, delta)
			_monster.velocity = Vector3.ZERO
			_monster.move_and_slide()
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_phase = &"pickup_pause"
				_phase_timer = preview_pickup_pause_seconds
		&"pickup_pause":
			_monster.velocity = Vector3.ZERO
			_monster.move_and_slide()
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_phase = &"escape"
				_monster.call("_set_state", &"SHORT_CHASE")
		&"escape":
			_move_toward_player(delta, preview_chase_speed)


func _update_guard(delta: float) -> void:
	_noise_attention_time = maxf(0.0, _noise_attention_time - delta)
	if _noise_attention_time > 0.0:
		_face_direction(_player.global_position - _monster.global_position, delta, preview_noise_turn_speed_degrees)
	else:
		_face_direction(_original_facing, delta)
	if _is_player_in_spotlight():
		_phase = &"spotlight_chase"
		_lost_sight_time = 0.0
		_monster.call("_set_state", &"SHORT_CHASE")
		_move_toward_player(delta, preview_chase_speed)
	else:
		_monster.velocity = Vector3.ZERO
		_monster.move_and_slide()


func _update_spotlight_chase(delta: float) -> void:
	if _is_player_in_spotlight():
		_lost_sight_time = 0.0
	else:
		_lost_sight_time += delta
		if _lost_sight_time >= preview_lose_sight_grace:
			_phase = &"guard"
			_monster.call("_set_state", &"PATROL")
			_monster.velocity = Vector3.ZERO
			return
	_move_toward_player(delta, preview_chase_speed)


func _is_player_in_spotlight() -> bool:
	var target_height := 0.42 if _player.get("movement_state") == &"crouching" else 0.75
	var target := _player.global_position + Vector3.UP * target_height
	var local_target := _monster.global_transform.affine_inverse() * target
	var forward_distance := -local_target.z
	var max_distance := float(_monster.get("sight_distance"))
	var half_width := float(_monster.get("sight_half_width"))
	if forward_distance <= 0.05 or forward_distance > max_distance:
		return false
	if absf(local_target.x) > half_width * (forward_distance / max_distance):
		return false
	var ray_start := _monster.global_position + Vector3.UP * 1.35
	var query := PhysicsRayQueryParameters3D.create(ray_start, target)
	query.collision_mask = 1
	query.exclude = [_monster.get_rid()]
	var hit := _monster.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _player


func _move_toward_player(delta: float, speed: float) -> void:
	var target := _player.global_position
	_path_refresh -= delta
	if _path_refresh <= 0.0 or _last_path_target.distance_to(target) > 0.35:
		_navigation_agent.target_position = target
		_last_path_target = target
		_path_refresh = 0.18
	var next_position := _navigation_agent.get_next_path_position()
	var direction := next_position - _monster.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		direction = target - _monster.global_position
		direction.y = 0.0
	if direction.length_squared() < 0.01:
		_monster.velocity = Vector3.ZERO
		_monster.move_and_slide()
		return
	direction = direction.normalized()
	var vertical_speed := clampf((next_position.y - _monster.global_position.y) * 3.5, -2.0, 2.0)
	_monster.velocity = Vector3(direction.x * speed, vertical_speed, direction.z * speed)
	_monster.move_and_slide()
	# Keep the searchlight aimed at the player during pursuit, even when the
	# navigation path bends around stage pieces or chairs.
	_face_direction(target - _monster.global_position, delta, preview_turn_speed_degrees * 3.0)


func _face_direction(direction: Vector3, delta: float, turn_speed: float = preview_turn_speed_degrees) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	_monster.rotation.y = rotate_toward(
		_monster.rotation.y,
		target_yaw,
		deg_to_rad(turn_speed) * delta
	)
