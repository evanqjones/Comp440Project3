extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)

func _load_game(path: String) -> Node:
    change_scene_to_file(path)
    await scene_changed
    var game = current_scene
    for frame in 900:
        await physics_frame
        if game.school_ready:
            break
    game.set_process(false)
    game.bell.set_process(false)
    game.player.set_physics_process(false)
    game.monster.set_physics_process(false)
    return game

func _run() -> void:
    var toggle = root.get_node("GameSceneToggle")
    var game = await _load_game(toggle.MAIN_GAME)
    _check(game.school_ready, "Demo startup completes")
    _check(toggle._button.get_global_rect().intersects(root.get_visible_rect()), "Toggle is visible inside the game viewport")
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://.godot/integrated-demo.png")
    var tab := InputEventKey.new()
    tab.keycode = KEY_TAB
    tab.pressed = true
    toggle._input(tab)
    _check(toggle._using_toggle, "Tab enables clicking while playing")
    tab.pressed = false
    toggle._input(tab)
    _check(not toggle._using_toggle, "Releasing Tab restores game controls")
    # Collect real keys, then model two completed authored encounters.
    game.player.global_position = game._item_markers[&"school_keys"].global_position
    _check(game._try_collect_preview_item(), "Demo keys are collectible")
    game._collected_preview_items[&"weight"] = true
    game._collected_preview_items[&"snack"] = true
    game._process(0.0)
    _check(game._bell_schedule_has_started, "Demo progression starts School scheduler")
    _check(game.bell.get_bell_snapshot().progression_index == 2, "Keys do not inflate belongings pressure")
    var remaining: float = game.bell._remaining
    game.player.global_position = game._item_markers[&"book"].global_position
    game._active_preview_encounter = &"book"
    game._process(0.0)
    _check(not game.bell.is_processing(), "Authored encounters pause the bell clock")
    _check(is_equal_approx(game.bell._remaining, remaining), "Pausing does not reroll the interval")
    game.player.global_position = game._item_markers[&"school_keys"].global_position
    game._active_preview_encounter = &""
    game._process(0.0)
    _check(game.bell.is_processing(), "Bell resumes after encounter")
    game.bell.set_process(false)
    # Preserve the team's actual capture/respawn flow on top of School features.
    var checkpoint: Vector3 = game.player.global_position
    game._demo_last_item_checkpoint = checkpoint
    game._begin_demo_capture_respawn()
    _check(game._demo_capture_respawn_timer > 0.0, "Capture starts the respawn delay")
    game.player.global_position += Vector3(3, 0, 0)
    game._finish_demo_capture_respawn()
    _check(game.player.global_position.is_equal_approx(checkpoint), "Capture restores last-item checkpoint")
    _check(game._demo_capture_immunity_remaining > 0.0, "Respawn retains immunity")
    game._collected_preview_items[&"book"] = true
    game._collected_preview_items[&"brush"] = true
    game._collected_preview_items[&"lab_coat"] = true
    game._collected_preview_items[&"ruler"] = true
    game._collected_preview_items[&"snack"] = true
    game._process(0.0)
    _check(not game._guaranteed_bell_delays.is_empty(), "Six-item milestone retains guaranteed Bell")
    game._process(5.1)
    _check(game.bell.bell_active and game._bell_audio.playing, "Guaranteed Bell uses School audio/state")
    game.bell.stop_scheduling()
    game._collected_preview_items[&"microphone"] = true
    game.player.global_position = game._item_markers[&"front_door_key"].global_position
    _check(game._try_collect_preview_item(), "Demo final key starts escape")
    game._process(0.0)
    _check(game.bell.get_bell_snapshot().final_escape, "Demo process cannot cancel School final Bell")
    game._begin_demo_capture_respawn()
    game._finish_demo_capture_respawn()
    _check(game.bell.get_bell_snapshot().final_escape, "Final-chase capture preserves final Bell")
    # Exercise the actual button signal and keyboard callback across fresh scenes.
    toggle._button.pressed.emit()
    await scene_changed
    _check(current_scene.scene_file_path == toggle.SCHOOL_SYSTEM, "Button switches to School System")
    for frame in 900:
        await physics_frame
        if current_scene.school_ready:
            break
    var key := InputEventKey.new()
    key.keycode = KEY_F2
    key.pressed = true
    toggle._input(key)
    await scene_changed
    _check(current_scene.scene_file_path == toggle.MAIN_GAME, "F2 returns to integrated demo")
    for frame in 900:
        await physics_frame
        if current_scene.school_ready:
            break
    print("Team demo integration: %d failures" % failures)
    quit(1 if failures else 0)
