extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	_check(main_path == "res://scenes/after_school.tscn", "F5 must launch the integrated team game")
	await _check_full_game(main_path)
	var demo = load("res://scenes/school_system_demo.tscn").instantiate()
	root.add_child(demo)
	await physics_frame
	await physics_frame
	var bell = demo.bell
	bell.set_process(false)
	_check(demo.player.get_node("CameraPivot/SpringArm3D/Camera3D").current, "Existing player camera must be active")
	_check(demo.school.get_current_room_id() == &"entrance", "Player must start inside entrance")
	_check(demo.room_label.text == "Room: Entrance", "Room must be visible")
	_check(demo.bell_label.text == "Bell quiet", "Initial Bell state must be visible")
	bell._process(11.0)
	_check(demo.bell_label.text == "BELL ACTIVE", "Bell start must update visible status")
	bell._process(4.1)
	_check(demo.bell_label.text == "Bell quiet", "Bell end must update visible status")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_P
	for i in range(6):
		demo._unhandled_input(key)
	_check(bell.get_bell_snapshot().progression_index == 6, "Demo input must reach School Bell")
	_check(bell.get_interval_bounds().is_equal_approx(Vector2(2.5, 5)), "Demo progress scales future bounds")
	demo.player.position = Vector3(6, 0.05, 6)
	await physics_frame
	await physics_frame
	_check(demo.room_label.text == "Room: Classroom 101", "Walking between rooms must update overlay")
	key.keycode = KEY_R
	demo._unhandled_input(key)
	_check(bell.get_bell_snapshot().progression_index == 0, "Demo reset must clear test progress")
	print("School demo integration: %d failures" % failures)
	quit(1 if failures else 0)


func _check_full_game(path: String) -> void:
	var game = load(path).instantiate()
	root.add_child(game)
	for frame in 900:
		await physics_frame
		if game.school_ready:
			break
	_check(game.school_ready, "Full building must finish navigation setup")
	if not game.school_ready:
		game.queue_free()
		await process_frame
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://school_integrated.png")
	game.set_process(false)
	game.bell.set_process(false)
	game.player.set_physics_process(false)
	game.monster.set_physics_process(false)
	_check(game.get_current_room_id() == &"nurse_office", "Full game begins in Nurse Office")
	_check(game._item_markers.size() == 9, "Preserve all nine team objectives including microphone and keys")
	_check(game.get_room_ids().size() >= 18, "Use the large school, not graybox rooms")
	_check(not game.spawn_help.visible and not game.bell_status.visible, "Do not reveal monster debug or Bell timer")
	_check(not game._spawn_marker_nodes_visible, "Stalking candidates are invisible in game")
	_check(game.get_stalking_locations().size() > 0, "Full building exposes stalking candidates")
	_check(game._final_exit_door.interaction_locked, "Exit is initially locked")
	var monster_position: Vector3 = game.monster.global_position
	game.bell._process(61.0)
	_check(game.bell.bell_active and game.monster.current_state == &"BELL_CHASE", "Automatic bell starts actual Monster chase")
	_check(game.monster.global_position.is_equal_approx(monster_position), "Bell never teleports monster")
	_check(game._bell_audio.playing, "Active bell has audio")
	_check(not game.get_bell_snapshot().active_safe_room_ids.is_empty(), "School snapshot publishes safe rooms")
	game.bell._process(10.1)
	_check(not game.bell.bell_active and game.monster.current_state == &"PATROL", "Bell returns Monster to stalking")
	_check(not game._bell_audio.playing, "Bell audio stops with chase")
	_check(game.get_bell_snapshot().active_safe_room_ids.is_empty(), "Quiet phase clears temporary safe rooms")
	# Verify real pickup changes pacing; final key cannot skip belongings.
	game.player.global_position = game._item_markers[&"front_door_key"].global_position
	_check(not game._try_collect_preview_item(), "Cannot collect final key before all belongings")
	game.player.global_position = game._item_markers[&"school_keys"].global_position
	_check(game._try_collect_preview_item(), "Existing key pickup works")
	_check(game.bell.get_bell_snapshot().progression_index == 0, "Access keys are not a belonging")
	game.player.global_position = game._item_markers[&"weight"].global_position
	_check(game._try_collect_preview_item(), "Existing Weight pickup works")
	_check(game.bell.get_bell_snapshot().progression_index == 1, "Actual pickup advances Bell pressure")
	_check(game.bell.get_interval_bounds().x < 30.0, "Collected belongings shorten random wait bounds")
	_check(not game._try_collect_preview_item(), "Repeated pickup cannot double count")
	# Freeze the scheduler inside authored encounters; their AI remains team-owned.
	game._active_preview_encounter = &"book"
	_check(game._encounter_busy(), "Authored encounter reserves its Bell-free sequence")
	game._active_preview_encounter = &""
	for item in game.PREVIEW_ITEMS:
		if item["id"] != &"front_door_key":
			game._collected_preview_items[item["id"]] = true
	game.player.global_position = game._item_markers[&"front_door_key"].global_position
	_check(game._try_collect_preview_item(), "Final key becomes available after belongings")
	_check(game.get_bell_snapshot().final_escape, "Final encounter uses School's authoritative final Bell")
	game.bell._process(1000.0)
	_check(game.bell.bell_active, "Final Bell persists until exit")
	game._finish_escape()
	_check(not game.escaped, "Cannot win while still inside the school")
	var lobby: AABB = game._item_room_bounds[&"lobby"]
	var outward: Vector3 = game._final_exit_door.global_position - lobby.get_center()
	outward.y = 0.0
	game.player.global_position = game._final_exit_door.global_position + outward.normalized() * 2.0
	game._finish_escape()
	_check(game.escaped and not game.bell.bell_active, "Completed escape stops School Bell")
	_check(not game._bell_audio.playing, "Victory stops bell audio")
	game.queue_free()
	await process_frame
	await physics_frame
