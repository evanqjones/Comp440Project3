extends Node3D
## Environment challenges only. Detection/capture are supplied by integration.

signal challenge_started(event_id: StringName)
signal challenge_failed(event_id: StringName, reason: StringName)
signal challenge_completed(event_id: StringName, reward_id: StringName)

@export_range(0.3, 1.5, 0.1) var checkpoint_radius: float = 0.9
@export_range(0.01, 0.5, 0.01) var watched_movement_tolerance: float = 0.08
@export_range(0.1, 2.0, 0.1) var watch_report_timeout: float = 0.5
@export_range(0.0, 1.0, 0.05) var watch_reaction_grace: float = 0.35

var _school: Node3D
var _player: Node3D
var _states: Dictionary = {&"library_maze": &"idle", &"science_stillness": &"idle"}
var _checkpoint: int = 0
var _watching: bool = false
var _watch_age: float = INF
var _watch_elapsed: float = 0.0
var _watch_origin := Vector3.ZERO
var _watch_origin_valid: bool = false
var _beacons: Dictionary = {}
var _labels: Dictionary = {}


func bind_environment(school: Node3D, player: Node3D) -> void:
	_school = school
	_player = player
	if _beacons.is_empty():
		for id: StringName in _states:
			var mesh := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.3
			cylinder.bottom_radius = 0.3
			cylinder.height = 0.12
			mesh.mesh = cylinder
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = Color(1, 0.8, 0.2)
			mesh.material_override = material
			add_child(mesh)
			_beacons[id] = mesh
			var label := Label3D.new()
			label.font_size = 32
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(label)
			_labels[id] = label
	_update_beacons()


func report_lab_watch_state(watching: bool) -> void:
	# Refresh every physics tick from Monster perception. A missing report is unknown,
	# never permission to collect. The demo explicitly supplies a mock watch signal.
	if not watching or not _watching or _watch_age > watch_report_timeout:
		_watch_origin_valid = false
		_watch_elapsed = 0.0
	_watching = watching
	_watch_age = 0.0


func report_player_caught(room_id: StringName) -> void:
	var id: StringName = &"library_maze" if room_id == &"library" else &"science_stillness" if room_id == &"science_lab" else &""
	if id != &"" and _states[id] == &"active":
		_fail(id, &"caught")


func get_challenge_snapshot(event_id: StringName) -> Dictionary:
	if not _states.has(event_id) or not is_instance_valid(_school):
		return {}
	return {"id": event_id, "state": _states[event_id], "next_checkpoint": _checkpoint if event_id == &"library_maze" else 0,
		"target_position": _target(event_id), "watch_known": _watch_age <= watch_report_timeout, "watching": _watching}


func request_retry(event_id: StringName) -> bool:
	if not _states.has(event_id) or _states[event_id] != &"failed" or not _near(_entry(event_id)):
		return false
	_start(event_id)
	return true


func request_reward(event_id: StringName) -> bool:
	if not _states.has(event_id) or _states[event_id] != &"active" or not is_instance_valid(_school):
		return false
	if event_id == &"library_maze" and _checkpoint < _school.layout.library_checkpoints.size():
		return false
	if event_id == &"science_stillness" and (_watch_age > watch_report_timeout or _watching):
		return false
	if not _near(_goal(event_id)):
		return false
	_states[event_id] = &"completed"
	_update_beacons()
	challenge_completed.emit(event_id, &"book" if event_id == &"library_maze" else &"lab_coat")
	return true


func _physics_process(delta: float) -> void:
	_watch_age += delta
	if _watching and _watch_age <= watch_report_timeout:
		_watch_elapsed += delta
	if not is_instance_valid(_school) or not is_instance_valid(_player):
		return
	var room: StringName = _school.get_room_id_at(_player.global_position)
	for id: StringName in _states:
		var required_room: StringName = &"library" if id == &"library_maze" else &"science_lab"
		if _states[id] == &"active" and room != required_room:
			_fail(id, &"left_room")
		if _states[id] == &"idle" and _near(_entry(id)):
			_start(id)
	if _states[&"science_stillness"] == &"active":
		if _watch_age <= watch_report_timeout and _watching and _watch_elapsed > watch_reaction_grace:
			var position_flat := Vector3(_player.global_position.x, 0, _player.global_position.z)
			if not _watch_origin_valid:
				_watch_origin = position_flat
				_watch_origin_valid = true
			elif position_flat.distance_to(_watch_origin) > watched_movement_tolerance:
				_fail(&"science_stillness", &"moved_while_watched")
		else:
			_watch_origin_valid = false
	if _states[&"library_maze"] == &"active":
		var checkpoints: Array[Vector2i] = _school.layout.library_checkpoints
		if _checkpoint < checkpoints.size() and _near(_school.get_cell_position(checkpoints[_checkpoint])):
			_checkpoint += 1
	_update_beacons()


func _start(id: StringName) -> void:
	_states[id] = &"active"
	if id == &"library_maze":
		_checkpoint = 1
	else:
		_watch_origin_valid = false
	challenge_started.emit(id)
	_update_beacons()


func _fail(id: StringName, reason: StringName) -> void:
	_states[id] = &"failed"
	if id == &"library_maze":
		_checkpoint = 0
	_watch_origin_valid = false
	_update_beacons()
	challenge_failed.emit(id, reason)


func _entry(id: StringName) -> Vector3:
	return _school.get_cell_position(_school.layout.library_checkpoints[0] if id == &"library_maze" else _school.layout.science_entry)


func _goal(id: StringName) -> Vector3:
	return _school.get_cell_position(_school.layout.library_checkpoints[-1] if id == &"library_maze" else _school.layout.science_goal)


func _target(id: StringName) -> Vector3:
	if _states[id] in [&"idle", &"failed"]:
		return _entry(id)
	if id == &"library_maze" and _checkpoint < _school.layout.library_checkpoints.size():
		return _school.get_cell_position(_school.layout.library_checkpoints[_checkpoint])
	return _goal(id)


func _near(point: Vector3) -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(point) <= checkpoint_radius


func _update_beacons() -> void:
	for id: StringName in _beacons:
		var mesh: MeshInstance3D = _beacons[id]
		var label: Label3D = _labels[id]
		mesh.global_position = _target(id) + Vector3(0, 0.1, 0)
		label.global_position = _target(id) + Vector3(0, 1.8, 0)
		mesh.visible = _states[id] != &"completed"
		label.visible = mesh.visible
		if _states[id] == &"failed":
			label.text = "RETRY HERE [E]"
		elif _states[id] == &"idle":
			label.text = "LIBRARY MAZE START" if id == &"library_maze" else "SCIENCE LAB START"
		elif id == &"library_maze" and _checkpoint < _school.layout.library_checkpoints.size():
			label.text = "MAZE CHECKPOINT %d" % (_checkpoint + 1)
		else:
			label.text = "BOOK [E]" if id == &"library_maze" else "LAB COAT [E]"
