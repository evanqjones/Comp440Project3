extends SceneTree
## Run: Godot --headless --fixed-fps 60 --path . --script tools/test_final_escape.gd
## Prerequisite inventory is injected to isolate the real final-key/exit flow.
var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	checks += 1
	print(("PASS " if value else "FAIL ") + label)
	if not value:
		failures += 1


func settle(frames: int = 150) -> void:
	for i in range(frames):
		await physics_frame


func cross_entrance(player: CharacterBody3D, destination: Vector3) -> bool:
	for i in range(300):
		await physics_frame
		var direction := destination - player.global_position
		direction.y = 0
		if direction.length() < 0.05:
			player.velocity = Vector3.ZERO
			return true
		player.velocity = direction.normalized() * minf(2, direction.length() * 60)
		player.velocity.y = -1
		player.move_and_slide()
	return false


func run() -> void:
	var scene := (load("res://scenes/demo_scene.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle()
	for iteration in range(2):
		scene = current_scene
		var player := scene.get_node("PlayerPlaceholder") as CharacterBody3D
		var monster := scene.get_node("MonsterPlaceholder") as CharacterBody3D
		scene.set_process(false)
		scene.get_node("SchoolBell").call("stop_scheduling")
		check(not scene.get("_victory_started") and player.is_on_floor(), "normal grounded Nurse startup / restart %d" % iteration)
		scene.call("_begin_demo_capture_respawn")
		check(player.get("capture_presentation_active"), "capture presentation still works before final escape")
		scene.call("_finish_demo_capture_respawn")
		check(not player.get("capture_presentation_active") and player.get("_input_enabled"), "capture restores input")
		var collected: Dictionary = scene.get("_collected_preview_items")
		collected[&"school_keys"] = true
		for id in scene.DEMO_REQUIRED_ITEMS:
			collected[id] = true
		scene.call("_activate_demo_monster")
		var items: Dictionary = scene.get("_item_markers")
		player.global_position = items[&"front_door_key"].global_position
		check(scene.call("_try_collect_preview_item"), "real Front Door Key collection succeeds")
		check(scene.get("_final_bell_started") and monster.current_state == &"BELL_CHASE", "key starts final Bell / chase")
		var door: Node3D = scene.get("_final_exit_door")
		check(door.get("interaction_locked"), "entrance locked during chase delay")
		var lobby := scene.call("_find_room_floor", scene.get("school"), "lobby floor") as MeshInstance3D
		var bounds: AABB = lobby.global_transform * lobby.mesh.get_aabb()
		var outward := door.global_position - bounds.get_center()
		outward.y = 0.0
		outward = outward.normalized()
		var key_position := player.global_position
		player.global_position = door.global_position + outward * 1.5
		scene.call("_update_preview_item_encounter")
		check(not scene.get("_victory_started"), "crossing before chase starts cannot win")
		player.global_position = key_position
		await settle(400)
		check(scene.get("_final_exit_chase_started") and door.get("_opened"), "existing chase signal opens front entrance")
		monster.set_physics_process(false)
		player.set_physics_process(false)
		player.global_position = door.global_position - outward * 0.5
		scene.call("_update_preview_item_encounter")
		check(not scene.get("_victory_started"), "inside entrance cannot win")
		check(await cross_entrance(player, door.global_position + outward * 1.5), "Player physically crosses opened final entrance")
		check(scene.call("_player_has_cleared_school_entrance"), "existing crossing detector confirms escape")
		scene.call("_update_preview_item_encounter")
		var ending := scene.get_node("EscapeVictory")
		for i in range(10):
			scene.call("_update_preview_item_encounter")
		check(scene.get("_victory_started") and scene.get("_final_exit_door_slammed"), "School triggers victory and entrance slam")
		check(scene.get_node("EscapeVictory") == ending, "victory triggers exactly once")
		check(not player.get("_input_enabled") and not player.is_physics_processing(), "ending disables input and movement")
		check(not player.is_processing_unhandled_input(), "ending prevents mouse recapture")
		check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "ending releases mouse for buttons")
		check(monster.process_mode == Node.PROCESS_MODE_DISABLED and not monster.get("_preview_bell_active"), "final pursuit stops")
		check(not scene.get_node("SchoolBell").get("bell_active"), "scheduled Bell stops")
		await settle(130)
		check(not door.get("_opened") and door.get("interaction_locked"), "entrance ends closed and locked")
		var restart := ending.get_node("Fade/Center/Ending/Restart") as Button
		var quit_button := ending.get_node("Fade/Center/Ending/Quit") as Button
		check(not restart.disabled and quit_button.pressed.is_connected(ending._on_quit_pressed), "Restart enabled / Quit wired")
		if OS.get_cmdline_user_args().has("--quit"):
			print("QUIT_BUTTON_EXERCISED")
			quit_button.pressed.emit()
			return
		var old_id := scene.get_instance_id()
		restart.pressed.emit()
		await settle(180)
		check(is_instance_valid(current_scene) and current_scene.get_instance_id() != old_id, "Restart reloads current game")
		check(not current_scene.get("_victory_started") and not current_scene.has_node("EscapeVictory"), "Restart clears ending UI/state")
	print("FINAL_ESCAPE_RESULT checks=%d failures=%d" % [checks, failures])
	current_scene.queue_free()
	await settle(8)
	quit(1 if failures else 0)
