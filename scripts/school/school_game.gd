extends "res://scenes/school_blockout_preview.gd"
## School_System integration of the team's full building and authored encounters.
## Actor scripts remain owned by Player/Monster; this scene wires their public APIs.

signal bell_state_changed(snapshot: SchoolBell.BellSnapshot)
signal player_room_changed(previous_room: StringName, current_room: StringName)
signal exit_reached()

@export_group("Provisional School timing")
@export var bell_interval_min: float = 30.0
@export var bell_interval_max: float = 60.0
@export var bell_seconds: float = 10.0
@export var completed_bell_interval_multiplier: float = 0.5
@export_group("Provisional School lighting")
@export_range(0.0, 1.0) var ambient_energy: float = 0.3
@export_range(0.0, 2.0) var room_light_energy: float = 0.85

const BellAudio = preload("res://scripts/school/school_bell_audio.gd")
var bell: SchoolBell
var school_ready := false
var escaped := false
var _room_id: StringName = &""
var _bell_audio: AudioStreamPlayer
var _objective_label: Label
var _room_label: Label
var _room_lights: Array[OmniLight3D] = []
var _door_open_states: Dictionary = {}

func _ready() -> void:
	set_process(false)
	await super._ready()
	_spawn_marker_nodes_visible = false
	for marker in _spawn_markers:
		marker.hide()
	_camera_hallway_spawn.hide()
	bell_status.hide()
	spawn_help.hide()
	item_help.hide()
	bell = SchoolBell.new()
	bell.name = "SchoolBell"
	bell.auto_start = false
	bell.minimum_interval = bell_interval_min
	bell.maximum_interval = bell_interval_max
	bell.bell_duration = bell_seconds
	bell.completed_interval_multiplier = completed_bell_interval_multiplier
	bell.objectives_for_maximum_pressure = PREVIEW_ITEMS.size() - 2
	add_child(bell)
	bell.bell_state_changed.connect(_on_school_bell_changed)
	_bell_audio = AudioStreamPlayer.new()
	_bell_audio.name = "SchoolBellAudio"
	_bell_audio.stream = BellAudio.create_stream()
	_bell_audio.volume_db = -12.0
	add_child(_bell_audio)
	_create_school_status()
	_create_school_lighting()
	_final_exit_door = _find_school_entrance_door()
	if is_instance_valid(_final_exit_door):
		_final_exit_door.set_interaction_locked(true)
	school_ready = true
	bell.start_scheduling()
	set_process(true)
	_update_school_status()

func _process(delta: float) -> void:
	if not school_ready or escaped:
		return
	super._process(delta)
	# Let the existing set pieces finish; never consume a Bell silently inside one.
	bell.set_process(_bell_debug_active or not _encounter_busy())
	_update_school_status()
	if _final_bell_started and _final_exit_door_slammed:
		_finish_escape()

func _encounter_busy() -> bool:
	return (_active_preview_encounter != &"" or _brush_escape_active
		or _microphone_escape_active or _ruler_hall_event_active
		or _science_spawn_pending or _science_window_spawn_pending
		or monster.is_preview_weight_escape_active()
		or monster.is_preview_window_stalking() or monster.is_preview_window_sliding()
		or monster.is_preview_book_sinking())

func _unhandled_input(event: InputEvent) -> void:
	if not school_ready:
		return
	if escaped:
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	# The playable version has no manual Bell, relocation, or spawn-panel cheats.
	if event is InputEventKey and event.keycode in [KEY_Z, KEY_X, KEY_M]:
		return
	super._unhandled_input(event)

func _update_preview_item_encounter() -> void:
	# Room entry must not teleport or switch the entity during an automatic chase.
	if _bell_debug_active and not _final_bell_started:
		return
	super._update_preview_item_encounter()

func _try_collect_preview_item() -> bool:
	if _bell_debug_active or escaped:
		return false
	var item := _nearest_collectible_preview_item()
	if item.is_empty():
		return false
	if item["id"] == &"front_door_key" and not _all_belongings_collected():
		return false
	var success := super._try_collect_preview_item()
	if success:
		bell.set_objective_progress(_belongings_count())
		_update_school_status()
	return success

func _nearest_collectible_preview_item() -> Dictionary:
	if _bell_debug_active or escaped:
		return {}
	var item := super._nearest_collectible_preview_item()
	if not item.is_empty() and item["id"] == &"front_door_key" and not _all_belongings_collected():
		return {}
	return item

func _start_final_key_bell() -> void:
	# Keep the team's storage-closet setup, entrance opening, and trailing chase.
	super._start_final_key_bell()
	bell.start_final_escape()

func _apply_bell_debug_state() -> void:
	# Invoked by the base scene during setup. No debug-controlled state authority.
	if not school_ready:
		monster.set_preview_bell_active(false)

func _on_school_bell_changed(snapshot: SchoolBell.BellSnapshot) -> void:
	_bell_debug_active = snapshot.active
	_bell_hall_spawn_pending = false
	preview_environment.environment.background_color = BELL_BACKGROUND if snapshot.active else NORMAL_BACKGROUND
	preview_environment.environment.ambient_light_color = BELL_AMBIENT if snapshot.active else NORMAL_AMBIENT
	preview_light.light_color = Color(1.0, 0.12, 0.16) if snapshot.active else Color.WHITE
	for light in _room_lights:
		light.light_color = Color(0.9, 0.14, 0.1) if snapshot.active else Color(1.0, 0.86, 0.62)
	if snapshot.active and not snapshot.final_escape:
		_choose_preview_safe_rooms()
	else:
		_active_safe_room_ids.clear()
		for light in _safe_room_lights.values():
			light.queue_free()
		_safe_room_lights.clear()
	_sync_safe_room_door_links()
	monster.set_safe_rooms(_active_safe_room_ids)
	if not snapshot.final_escape:
		# Start where the entity actually is. Never use the preview hallway teleport.
		monster.set_preview_bell_active(snapshot.active)
	if snapshot.active:
		_bell_audio.play()
	else:
		_bell_audio.stop()
	snapshot.active_safe_room_ids = _active_safe_room_ids.duplicate()
	bell_state_changed.emit(snapshot)

func get_bell_snapshot() -> SchoolBell.BellSnapshot:
	var snapshot := bell.get_bell_snapshot()
	snapshot.active_safe_room_ids = _active_safe_room_ids.duplicate()
	return snapshot

func _belongings_count() -> int:
	var count := 0
	for item in PREVIEW_ITEMS:
		if item["id"] not in [&"school_keys", &"front_door_key"] and _collected_preview_items.has(item["id"]):
			count += 1
	return count

func _all_belongings_collected() -> bool:
	return _belongings_count() == PREVIEW_ITEMS.size() - 2 and _collected_preview_items.has(&"school_keys")

func _finish_escape() -> void:
	if escaped or not _all_belongings_collected() or not _collected_preview_items.has(&"front_door_key"):
		return
	if not _player_has_cleared_school_entrance():
		return
	escaped = true
	bell.stop_scheduling()
	monster.set_physics_process(false)
	player.set_input_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_objective_label.text = "YOU MADE IT HOME\nAll belongings recovered. Press R to play again."
	exit_reached.emit()

func get_room_id_at(world_position: Vector3) -> StringName:
	# Imported circulation/lobby slabs extend under small office floors.
	# Prefer the most specific containing room rather than dictionary order.
	var closest_room: StringName = &""
	var smallest_area := INF
	for room_id in _item_room_bounds:
		var bounds: AABB = _item_room_bounds[room_id]
		if absf(world_position.y - bounds.end.y) < 4.0 and _point_inside_room(world_position, bounds):
			var area := bounds.size.x * bounds.size.z
			if area < smallest_area:
				smallest_area = area
				closest_room = room_id
	if closest_room != &"":
		return closest_room
	var circulation := _find_room_floor(school, "school site floor - circulation")
	if circulation != null:
		var bounds: AABB = circulation.global_transform * circulation.mesh.get_aabb()
		if _point_inside_room(world_position, bounds):
			return &"hallway"
	return &"outside"

func get_current_room_id() -> StringName:
	return get_room_id_at(player.get_world_position())

func get_room_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for room_id in _item_room_bounds:
		ids.append(room_id)
	ids.append(&"hallway")
	return ids

func get_door_state(door_id: StringName) -> int:
	# -1 unknown, 0 closed, 1 open, 2 interaction-locked.
	for door in get_tree().get_nodes_in_group("preview_school_doors"):
		if door.door_id == door_id:
			if door.interaction_locked:
				return 2
			return 1 if _door_open_states.get(door_id, false) else 0
	return -1

func _on_preview_door_state_changed(door_id: StringName, is_open: bool) -> void:
	_door_open_states[door_id] = is_open
	super._on_preview_door_state_changed(door_id, is_open)

func get_objective_snapshot() -> Dictionary:
	return {"collected": _collected_preview_items.duplicate(),
		"completed_belongings": _belongings_count(), "total_belongings": PREVIEW_ITEMS.size() - 2,
		"exit_available": _all_belongings_collected() and _collected_preview_items.has(&"front_door_key"),
		"escaped": escaped}

func is_room_active_safe(room_id: StringName) -> bool:
	return _bell_debug_active and _active_safe_room_ids.has(room_id)

func get_stalking_locations(room_filter: StringName = &"") -> Array[Dictionary]:
	var locations: Array[Dictionary] = []
	for marker in _spawn_markers:
		var room := get_room_id_at(marker.global_position)
		if room_filter == &"" or room_filter == room:
			locations.append({"id": marker.get_meta("spawn_id"), "room_id": room,
				"position": marker.global_position, "kind": marker.get_meta("spawn_kind")})
	return locations

func get_traversable_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
	if NavigationServer3D.map_get_closest_point(navigation_map, from).distance_to(from) > 1.35:
		return PackedVector3Array()
	if NavigationServer3D.map_get_closest_point(navigation_map, to).distance_to(to) > 1.35:
		return PackedVector3Array()
	var path := NavigationServer3D.map_get_path(navigation_map, from, to, true)
	# Godot may return a partial path when a closed door disconnects regions.
	if path.is_empty() or path[path.size() - 1].distance_to(to) > 1.35:
		return PackedVector3Array()
	return path

func _create_school_status() -> void:
	var margin := MarginContainer.new()
	margin.position = Vector2(20, 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$DebugOverlay.add_child(margin)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	var title := Label.new()
	title.text = "AFTER SCHOOL  |  School_System"
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)
	_room_label = Label.new()
	layout.add_child(_room_label)
	_objective_label = Label.new()
	_objective_label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	layout.add_child(_objective_label)
	var controls := Label.new()
	controls.text = "WASD move   Shift run   Ctrl crouch   E collect / hide   Esc mouse"
	controls.add_theme_font_size_override("font_size", 13)
	layout.add_child(controls)

func _create_school_lighting() -> void:
	preview_environment.environment.ambient_light_energy = ambient_energy
	preview_light.light_energy = 0.25
	for room_id in _item_room_bounds:
		var bounds: AABB = _item_room_bounds[room_id]
		var light := OmniLight3D.new()
		light.name = "SchoolLight_" + String(room_id)
		light.position = Vector3(bounds.get_center().x, bounds.end.y + 2.4, bounds.get_center().z)
		light.omni_range = clampf(maxf(bounds.size.x, bounds.size.z) * 0.7, 5.0, 12.0)
		light.light_energy = room_light_energy
		light.light_color = Color(1.0, 0.86, 0.62)
		add_child(light)
		_room_lights.append(light)

func _update_school_status() -> void:
	var room := get_current_room_id()
	if room != _room_id:
		var previous := _room_id
		_room_id = room
		player_room_changed.emit(previous, room)
	_room_label.text = String(room).replace("_", " ").capitalize()
	var objective := ""
	if _final_bell_started:
		objective = "Reach the front entrance."
	else:
		for item in PREVIEW_ITEMS:
			if not _collected_preview_items.has(item["id"]):
				objective = "Find %s — %s" % [item["name"], String(item["room"]).replace("_", " ").capitalize()]
				break
	_objective_label.text = "Belongings %d / %d\n%s" % [_belongings_count(), PREVIEW_ITEMS.size() - 2, objective]
