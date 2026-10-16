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
var _demo_capture_interaction: StringName = &""
var _demo_final_chase_positions_saved := false
var _demo_final_chase_player_position := Vector3.ZERO
var _demo_final_chase_monster_position := Vector3.ZERO
var _wakeup_intro_active := false
var _wakeup_intro_dismissed := false


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
	await _play_opening_wakeup()


func _play_opening_wakeup() -> void:
	_wakeup_intro_active = true
	_wakeup_intro_dismissed = false
	player.call("set_input_enabled", false)
	var pivot: Node3D = player.get_node("CameraPivot")
	var camera: Camera3D = player.get_node("CameraPivot/Camera3D")
	var standing_position := pivot.position
	var standing_rotation := pivot.rotation
	pivot.position.y = 0.36
	pivot.rotation.x = 0.78
	camera.current = true
	var intro := CanvasLayer.new()
	intro.name = "WakeUpIntro"
	intro.layer = 20
	add_child(intro)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.008, 0.014, 0.022, 0.62)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(640.0, 0.0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.035, 0.055, 0.067, 0.94)
	card_style.border_color = Color(0.48, 0.59, 0.57, 0.8)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(6)
	card_style.content_margin_left = 32.0
	card_style.content_margin_right = 32.0
	card_style.content_margin_top = 26.0
	card_style.content_margin_bottom = 28.0
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)
	var heading := Label.new()
	heading.text = "..."
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color(0.91, 0.83, 0.63))
	content.add_child(heading)
	var story := Label.new()
	story.text = "Ugh... did I really fall asleep in the nurse's office?\n\nHow late is it? I need to find my things before I can leave.\n\nWhy is the school so quiet? Something feels wrong... like I'm not alone."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("font_size", 19)
	story.add_theme_color_override("font_color", Color(0.87, 0.89, 0.86))
	content.add_child(story)
	var hint := Label.new()
	hint.text = "I should stay low... holding SPACE lets me crouch and move quietly. Maybe it won't hear me."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.63, 0.8, 0.72))
	content.add_child(hint)
	var continue_prompt := Label.new()
	continue_prompt.text = "PRESS SPACE TO CONTINUE"
	continue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_prompt.add_theme_font_size_override("font_size", 13)
	continue_prompt.add_theme_color_override("font_color", Color(0.73, 0.77, 0.75))
	content.add_child(continue_prompt)
	backdrop.modulate.a = 0.0
	var intro_deadline := Time.get_ticks_msec() + 10000
	var fade_in := create_tween()
	fade_in.tween_property(backdrop, "modulate:a", 1.0, 0.45)
	var camera_tween := create_tween()
	camera_tween.set_trans(Tween.TRANS_SINE)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(pivot, "position", standing_position, 3.8)
	camera_tween.parallel().tween_property(pivot, "rotation", standing_rotation, 3.8)
	await camera_tween.finished
	while not _wakeup_intro_dismissed and Time.get_ticks_msec() < intro_deadline:
		await get_tree().process_frame
	var fade_out := create_tween()
	fade_out.tween_property(backdrop, "modulate:a", 0.0, 0.45)
	await fade_out.finished
	intro.queue_free()
	_wakeup_intro_active = false
	player.call("set_input_enabled", true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	super._process(delta)
	if _victory_started:
		return
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

func _complete_final_escape() -> void:
	if _victory_started:
		return
	# Final Bell belongs to this integration; retain progression and checkpoints.
	school_bell.call("stop_scheduling")
	_guaranteed_bell_delays.clear()
	_demo_capture_respawn_timer = 0.0
	super._complete_final_escape()


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
			or not bool(monster.call("can_capture_player"))
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
	_demo_capture_interaction = &""
	if _active_preview_encounter in [&"ruler_hall", &"microphone", &"microphone_escape", &"brush_escape"]:
		_demo_capture_interaction = _active_preview_encounter
	if _demo_capture_was_final_chase and not _demo_final_chase_positions_saved:
		_demo_final_chase_positions_saved = true
		_demo_final_chase_player_position = player.global_position
		_demo_final_chase_monster_position = monster.global_position
	var checkpoint_id: StringName = &"final_chase" if _demo_capture_was_final_chase else &"last_item"
	monster.visible = false
	player.call("play_capture_and_respawn", checkpoint_id)
	_demo_capture_respawn_timer = 1.05
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
	var captured_interaction := _demo_capture_interaction
	monster.visible = true
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
		match captured_interaction:
			&"ruler_hall":
				restart_ruler_hall_event_after_capture()
			&"microphone":
				_auditorium_encounter.call("restart_after_capture", false)
				item_help.text = "Caught! Microphone encounter restarted at the stage"
			&"microphone_escape":
				_microphone_escape_finish_started = false
				_auditorium_encounter.call("restart_after_capture", true)
				item_help.text = "Caught! Microphone chase restarted at the stage"
			&"brush_escape":
				restart_artroom_brush_escape_after_capture()
				item_help.text = "Caught! Paintbrush encounter restarted in the Artroom"
			_:
				_try_debug_offscreen_relocation()
				item_help.text = "Respawned at your last collected item"
	_demo_capture_respawn_timer = 0.0
	_demo_capture_immunity_remaining = 1.5
	_demo_capture_was_final_chase = false
	_demo_capture_interaction = &""

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
	if _wakeup_intro_active and event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
		_wakeup_intro_dismissed = true
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_M, KEY_X]:
		# Bell scheduling is automatic in the demo; spawn and relocation controls
		# are development-only controls from the Mechanics preview.
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
