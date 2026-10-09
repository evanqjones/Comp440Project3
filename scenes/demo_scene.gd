extends "res://scenes/school_blockout_preview.gd"

@onready var school_bell: Node = $SchoolBell

var _last_objective_progress := -1
var _demo_keys_unlocked := false
var _bell_schedule_has_started := false
var _bell_schedule_paused_for_interaction := false
var _last_required_item_count := 0
var _guaranteed_bell_delays: Array[float] = []
var _monster_collision_layer := 2
var _monster_collision_mask := 1
var _demo_seen_collected_items: Dictionary = {}
var _demo_last_item_checkpoint := Vector3.ZERO
var _demo_capture_respawn_timer := 0.0
var _demo_capture_immunity_remaining := 0.0
var _demo_capture_was_final_chase := false
var _demo_final_chase_positions_saved := false
var _demo_final_chase_player_position := Vector3.ZERO
var _demo_final_chase_monster_position := Vector3.ZERO


func _ready() -> void:
	demo_progression_rules_enabled = true
	_spawn_marker_nodes_visible = false
	demo_monster_spawned = false
	await super._ready()
	monster.call("set_preview_search_cone_visible", false)
	_demo_last_item_checkpoint = player.global_position
	_demo_seen_collected_items = _collected_preview_items.duplicate()
	_monster_collision_layer = monster.collision_layer
	_monster_collision_mask = monster.collision_mask
	monster.visible = false
	monster.collision_layer = 0
	monster.collision_mask = 0
	monster.process_mode = Node.PROCESS_MODE_DISABLED
	player.noise_emitted.disconnect(Callable(monster, "receive_noise"))
	bell_status.hide()
	spawn_help.hide()
	school_bell.connect("bell_state_changed", Callable(self, "_on_school_bell_state_changed"))
	_last_objective_progress = _collected_preview_items.size()
	_last_required_item_count = _demo_required_item_count()
	school_bell.call("set_objective_progress", _last_objective_progress)
	_on_school_bell_state_changed(school_bell.call("get_bell_snapshot"))


func _process(delta: float) -> void:
	super._process(delta)
	_track_last_collected_item_checkpoint()
	if _final_bell_started and not _demo_final_chase_positions_saved:
		_demo_final_chase_positions_saved = true
		_demo_final_chase_player_position = player.global_position
		_demo_final_chase_monster_position = monster.global_position
	_update_demo_capture_and_respawn(delta)
	var objective_progress := _collected_preview_items.size()
	var required_item_count := _demo_required_item_count()
	var interaction_active := _demo_item_interaction_active()
	if _collected_preview_items.has(&"school_keys") and not _demo_keys_unlocked:
		_demo_keys_unlocked = true
		_try_spawn_demo_monster_after_keys()
	if _demo_keys_unlocked and not demo_monster_spawned:
		_try_spawn_demo_monster_after_keys()
	if objective_progress != _last_objective_progress:
		_last_objective_progress = objective_progress
		school_bell.call("set_objective_progress", objective_progress)
	if required_item_count > _last_required_item_count:
		for milestone in [6, 7]:
			if _last_required_item_count < milestone and required_item_count >= milestone:
				_guaranteed_bell_delays.append(5.0)
		_last_required_item_count = required_item_count
	for index in range(_guaranteed_bell_delays.size()):
		_guaranteed_bell_delays[index] = maxf(0.0, _guaranteed_bell_delays[index] - delta)
	if _final_bell_started:
		_guaranteed_bell_delays.clear()
	elif not interaction_active and not bool(school_bell.get("bell_active")) and not _guaranteed_bell_delays.is_empty() and _guaranteed_bell_delays[0] <= 0.0:
		_guaranteed_bell_delays.pop_front()
		school_bell.call("start_guaranteed_bell")
	if objective_progress >= 3 and not _bell_schedule_has_started and not interaction_active and not _final_bell_started:
		_bell_schedule_has_started = true
		school_bell.call("start_scheduling")
	if _final_bell_started:
		if _bell_schedule_has_started and not _bell_schedule_paused_for_interaction:
			school_bell.call("stop_scheduling")
			_bell_schedule_paused_for_interaction = true
	elif interaction_active and _bell_schedule_has_started and not _bell_schedule_paused_for_interaction:
		school_bell.call("stop_scheduling")
		_bell_schedule_paused_for_interaction = true
	elif not interaction_active and _bell_schedule_paused_for_interaction:
		_bell_schedule_paused_for_interaction = false
		school_bell.call("start_scheduling")
	if _final_bell_started:
		bell_status.text = "FINAL BELL: ON | Escape to the entrance"
	elif bool(school_bell.get("bell_active")):
		var snapshot = school_bell.call("get_bell_snapshot")
		bell_status.text = "BELL ACTIVE | %.0f seconds remaining" % float(snapshot.get("remaining_seconds"))
	else:
		bell_status.text = "BELL QUIET | Automatic schedule"

func _demo_required_item_count() -> int:
	var count := 0
	for item_id in DEMO_REQUIRED_ITEMS:
		if _collected_preview_items.has(item_id):
			count += 1
	return count

func _demo_item_interaction_active() -> bool:
	return (
		_active_preview_encounter != &""
		or _ruler_hall_event_active
		or _microphone_escape_active
		or _brush_escape_active
		or _science_spawn_pending
		or _science_window_spawn_pending
		or monster.is_preview_weight_escape_active()
		or monster.is_preview_window_stalking()
		or monster.is_preview_window_sliding()
		or monster.is_preview_book_sinking()
	)

func _track_last_collected_item_checkpoint() -> void:
	for item in PREVIEW_ITEMS:
		var item_id: StringName = item["id"]
		if _collected_preview_items.has(item_id) and not _demo_seen_collected_items.has(item_id):
			_demo_seen_collected_items[item_id] = true
			_demo_last_item_checkpoint = player.global_position

func _update_demo_capture_and_respawn(delta: float) -> void:
	if _demo_capture_respawn_timer > 0.0:
		_demo_capture_respawn_timer = maxf(0.0, _demo_capture_respawn_timer - delta)
		if _demo_capture_respawn_timer == 0.0:
			_finish_demo_capture_respawn()
		return
	if _demo_capture_immunity_remaining > 0.0:
		_demo_capture_immunity_remaining = maxf(0.0, _demo_capture_immunity_remaining - delta)
		return
	if (not _demo_keys_unlocked or not demo_monster_spawned or not monster.visible
			or not player.visible or _active_locker_index >= 0
			or bool(player.get("capture_presentation_active"))):
		return
	var separation := monster.global_position - player.global_position
	if absf(separation.y) > 1.0:
		return
	separation.y = 0.0
	if separation.length() <= 0.86:
		_begin_demo_capture_respawn()

func _begin_demo_capture_respawn() -> void:
	_demo_capture_was_final_chase = _final_bell_started
	if _demo_capture_was_final_chase and not _demo_final_chase_positions_saved:
		_demo_final_chase_positions_saved = true
		_demo_final_chase_player_position = player.global_position
		_demo_final_chase_monster_position = monster.global_position
	var checkpoint_id: StringName = &"final_chase" if _demo_capture_was_final_chase else &"last_item"
	player.call("play_capture_and_respawn", checkpoint_id)
	_demo_capture_respawn_timer = 0.75
	_demo_capture_immunity_remaining = 0.0
	item_help.text = "Caught! Returning to your last item..."
	if not _demo_capture_was_final_chase:
		var bell_was_active := bool(school_bell.get("bell_active"))
		if bell_was_active:
			school_bell.call("stop_scheduling")
			_bell_schedule_has_started = _demo_required_item_count() >= 3
			_bell_schedule_paused_for_interaction = false
			if _bell_schedule_has_started:
				school_bell.call("start_scheduling")
		_preview_relocation_elapsed = 0.0

func _finish_demo_capture_respawn() -> void:
	if _demo_capture_was_final_chase and _demo_final_chase_positions_saved:
		player.call("restore_after_capture", _demo_final_chase_player_position, &"final_chase")
		monster.global_position = _demo_final_chase_monster_position
		monster.velocity = Vector3.ZERO
		monster.visible = true
		monster.collision_layer = _monster_collision_layer
		monster.collision_mask = _monster_collision_mask
		monster.set_physics_process(true)
		monster.call("begin_preview_final_bell_chase")
		item_help.text = "Final chase restarted | Reach the entrance"
	else:
		player.call("restore_after_capture", _demo_last_item_checkpoint, &"last_item")
		_try_debug_offscreen_relocation()
		item_help.text = "Respawned at your last collected item"
	_demo_capture_respawn_timer = 0.0
	_demo_capture_immunity_remaining = 1.5
	_demo_capture_was_final_chase = false

func _try_spawn_demo_monster_after_keys() -> void:
	if not _demo_keys_unlocked or demo_monster_spawned:
		return
	var candidates: Array[Node3D] = []
	for marker in _spawn_markers:
		if _is_hallway_spawn(marker):
			candidates.append(marker)
	if _camera_hallway_spawn_valid and is_instance_valid(_camera_hallway_spawn):
		candidates.append(_camera_hallway_spawn)
	candidates.shuffle()
	# Use the regular visibility gate for its first appearance. The temporary
	# starting position is outside the camera frustum, never a gameplay spawn.
	monster.global_position = player.global_position + Vector3(0.0, -100.0, 0.0)
	for marker in candidates:
		if monster.try_preview_offscreen_teleport(marker.global_position, player.player_camera, true):
			_activate_demo_monster()
			return

func _activate_demo_monster() -> void:
	if demo_monster_spawned:
		return
	monster.collision_layer = _monster_collision_layer
	monster.collision_mask = _monster_collision_mask
	monster.process_mode = Node.PROCESS_MODE_INHERIT
	monster.visible = true
	demo_monster_spawned = true
	var noise_callback := Callable(monster, "receive_noise")
	if not player.noise_emitted.is_connected(noise_callback):
		player.noise_emitted.connect(noise_callback)


func _on_school_bell_state_changed(snapshot) -> void:
	if _final_bell_started:
		return
	_bell_debug_active = bool(snapshot.get("active"))
	_apply_bell_debug_state()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_M, KEY_X]:
		# Bell scheduling is automatic in the demo; spawn and relocation controls
		# are development-only controls from the Mechanics preview.
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
