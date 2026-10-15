extends SceneTree
## Exercises actual input, School success hooks and scene-local audio lifecycle.
var checks := 0
var failures := 0
var cues: Dictionary = {}


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func settle(frames: int = 120) -> void:
	for i in range(frames):
		await physics_frame


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func run() -> void:
	var scene := (load("res://scenes/demo_scene.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle(180)
	scene.set_process(false)
	scene.get_node("SchoolBell").call("stop_scheduling")
	var player := scene.get_node("PlayerPlaceholder") as CharacterBody3D
	var monster := scene.get_node("MonsterPlaceholder") as CharacterBody3D
	monster.set_physics_process(false)
	var audio: Node = scene.get("_audio_presentation")
	audio.connect("cue_started", func(cue: StringName) -> void: cues[cue] = int(cues.get(cue, 0)) + 1)
	check(audio.get("_ambience").playing, "low school ambience starts")
	for file in ["footstep_walk", "footstep_sprint", "door_open", "item_pickup", "school_bell", "school_ambience", "chase_tension", "capture_hit"]:
		var stream := load("res://assets/audio/%s.wav" % file) as AudioStreamWAV
		check(stream != null and stream.get_length() > 0.1 and stream.mix_rate == 22050, "valid imported audio " + file)
	await settle(90)
	check(cues.get(&"walk_step", 0) == 0 and cues.get(&"sprint_step", 0) == 0, "stationary Player has no footstep spam")
	var rooms: Dictionary = scene.get("_item_room_bounds")
	var gym: AABB = rooms[&"gym"]
	var origin := Vector3(gym.get_center().x, gym.end.y, gym.get_center().z)
	player.global_position = origin
	player.get_node("CameraPivot").rotation.y = -PI / 2
	await settle(10)
	key(KEY_W, true)
	await settle(60)
	key(KEY_W, false)
	await settle(10)
	var walk_count := int(cues.get(&"walk_step", 0))
	check(walk_count >= 2 and walk_count <= 3 and player.global_position.distance_to(origin) > 2, "real walking produces paced audible steps")
	player.global_position = origin
	await settle(10)
	key(KEY_SHIFT, true)
	key(KEY_W, true)
	await settle(60)
	key(KEY_W, false)
	key(KEY_SHIFT, false)
	await settle(10)
	var sprint_count := int(cues.get(&"sprint_step", 0))
	check(sprint_count >= 3 and sprint_count <= 4 and sprint_count > walk_count, "real sprint uses faster/heavier footsteps")
	var before := int(cues.get(&"walk_step", 0)) + sprint_count
	await settle(90)
	check(int(cues.get(&"walk_step", 0)) + int(cues.get(&"sprint_step", 0)) == before, "stopping movement stops new steps")
	player.set_physics_process(false)
	var door: Node3D
	for candidate in get_nodes_in_group("preview_school_doors"):
		if not candidate.get("interaction_locked") and not candidate.get("_opened"):
			door = candidate
			break
	check(door != null, "starting Nurse/Office door available before keys")
	if door:
		for i in range(3):
			door.call("open_for_escape")
		check(cues.get(&"door", 0) == 1, "successful door opening sounds once")
	var items: Dictionary = scene.get("_item_markers")
	player.global_position = items[&"school_keys"].global_position
	check(scene.call("_try_collect_preview_item"), "actual School Keys collection works")
	check(not scene.call("_try_collect_preview_item") and cues.get(&"pickup", 0) == 1, "pickup sounds only once after successful collection")
	var bell := scene.get_node("SchoolBell")
	bell.call("start_guaranteed_bell")
	check(audio.get("_bell").playing and audio.get("_tension").playing, "authoritative Bell starts sound and tension")
	bell.call("start_guaranteed_bell")
	check(cues.get(&"bell", 0) == 1 and cues.get(&"tension", 0) == 1, "unchanged Bell state does not retrigger audio")
	bell.call("stop_scheduling")
	check(not audio.get("_bell").playing and not audio.get("_tension").playing, "Bell end stops both layers")
	var collected: Dictionary = scene.get("_collected_preview_items")
	for id in scene.DEMO_REQUIRED_ITEMS:
		collected[id] = true
	scene.call("_activate_demo_monster")
	monster.set_physics_process(false)
	player.global_position = items[&"front_door_key"].global_position
	check(scene.call("_try_collect_preview_item"), "real final key collection works with audio")
	check(audio.get("_bell").playing and audio.get("_tension").playing, "final Bell starts audio independent of scheduler")
	scene.call("_begin_demo_capture_respawn")
	await settle(3)
	check(cues.get(&"capture", 0) == 1 and audio.get("_capture").playing, "capture hit plays once")
	player.call("play_capture_and_respawn", &"final_chase")
	await settle(3)
	check(cues.get(&"capture", 0) == 1, "repeated capture request cannot stack hits")
	check(not audio.get("_bell").playing and not audio.get("_tension").playing, "capture suspends chase/Bell audio")
	scene.call("_finish_demo_capture_respawn")
	await settle(3)
	check(audio.get("_bell").playing and audio.get("_tension").playing, "final-chase restoration resumes layers")
	# Reuse the actual School crossing/slam branch to finish the run.
	scene.call("_on_preview_final_bell_chase_started")
	var exit_door: Node3D = scene.get("_final_exit_door")
	var lobby := scene.call("_find_room_floor", scene.get("school"), "lobby floor") as MeshInstance3D
	var bounds: AABB = lobby.global_transform * lobby.mesh.get_aabb()
	var outward := exit_door.global_position - bounds.get_center()
	outward.y = 0
	player.global_position = exit_door.global_position + outward.normalized() * 1.5
	scene.call("_update_preview_item_encounter")
	check(scene.get("_victory_started") and audio.get("_ended"), "actual victory ends audio lifecycle")
	var silent := true
	for voice in audio.get_children():
		if voice is AudioStreamPlayer or voice is AudioStreamPlayer3D:
			silent = silent and not voice.playing
	check(silent, "victory stops every active voice")
	scene.get_node("EscapeVictory").call("_on_restart_pressed")
	await settle(180)
	var fresh_audio: Node = current_scene.get("_audio_presentation")
	check(fresh_audio != audio and fresh_audio.get("_ambience").playing and not fresh_audio.get("_bell").playing and not fresh_audio.get("_tension").playing, "Restart creates clean ambience without stale Bell/chase")
	print("AUDIO_RESULT checks=%d failures=%d" % [checks, failures])
	current_scene.queue_free()
	await settle(8)
	quit(1 if failures else 0)
