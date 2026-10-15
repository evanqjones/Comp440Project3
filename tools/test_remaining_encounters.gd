extends SceneTree
## Isolated regression checks for the unchanged Library, Art, Lab and Cafe flows.
## Room entry uses School handlers; camera orientations exercise offscreen gates.
var checks := 0
var failures := 0
var scene: Node3D
var player: CharacterBody3D
var monster: CharacterBody3D


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


func fresh() -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		await settle(8)
	scene = (load("res://scenes/demo_scene.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle(180)
	scene.set_process(false)
	scene.get_node("SchoolBell").call("stop_scheduling")
	player = scene.get_node("PlayerPlaceholder")
	player.set_physics_process(false)
	monster = scene.get_node("MonsterPlaceholder")
	scene.call("_activate_demo_monster")
	monster.set_physics_process(false)


func unlock() -> void:
	var keys := scene.get("_item_markers")[&"school_keys"] as Node3D
	player.global_position = keys.global_position
	check(scene.call("_try_collect_preview_item"), "real School Keys pickup / progression")
	for door in get_nodes_in_group("preview_school_doors"):
		if not door.get("interaction_locked"):
			door.call("open_for_escape")
	await settle()


func run() -> void:
	await fresh()
	check(player.is_on_floor() and not scene.get("_victory_started"), "Nurse startup remains grounded without early victory")
	var nurse := scene.call("_find_nurse_floor", scene.get("school")) as MeshInstance3D
	var nurse_bounds: AABB = nurse.global_transform * nurse.mesh.get_aabb()
	check(scene.call("_point_inside_room", player.global_position, nurse_bounds), "startup is inside the actual Nurse Office")
	var items: Dictionary = scene.get("_item_markers")
	player.global_position = items[&"weight"].global_position
	check(not scene.call("_try_collect_preview_item"), "School rejects belonging before keys")
	await unlock()
	var available := 0
	for door in get_nodes_in_group("preview_school_doors"):
		if not door.get("interaction_locked"):
			available += 1
	check(available > 10, "keys unlock ordinary progression doors")
	player.global_position = items[&"book"].global_position
	scene.call("_update_preview_item_encounter")
	check(scene.get("_active_preview_encounter") == &"book" and monster.get("_preview_item_encounter") == &"book", "Library room entry starts Book encounter")
	var room: AABB = scene.get("_item_room_bounds")[&"library"]
	check(monster.global_position.distance_to(scene.call("_library_northwest_spawn", room)) < 0.001, "Library northwest Monster spawn preserved")
	var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
	check(NavigationServer3D.map_get_path(navigation_map, monster.global_position, player.global_position, true).size() > 1, "Library maze navigation to Book remains connected")
	check(scene.call("_try_collect_preview_item") and monster.call("is_preview_book_sinking"), "actual Book pickup starts original sink")
	await settle(90)
	check(not monster.visible and not monster.call("is_preview_book_sinking"), "Book sink completes and removes Monster")

	await fresh()
	await unlock()
	items = scene.get("_item_markers")
	player.global_position = items[&"brush"].global_position
	scene.call("_update_preview_item_encounter")
	check(scene.get("_active_preview_encounter") == &"brush", "Art room entry starts existing encounter")
	check(scene.call("_try_collect_preview_item") and scene.get("_brush_escape_active"), "actual Brush pickup starts ceiling escape")
	var art: Node = scene.get("_artroom_brush_encounter")
	art.set_physics_process(false)
	check(art.get("_active") and monster.global_basis.y.dot(Vector3.UP) < -0.99, "original ceiling Monster/searchlight initialized")
	var circulation := scene.call("_find_room_floor", scene.get("school"), "school site floor - circulation") as MeshInstance3D
	var circulation_bounds: AABB = circulation.global_transform * circulation.mesh.get_aabb()
	# Search an actual circulation point beyond Art/Bathroom room bounds.
	var found := false
	for x in range(int(circulation_bounds.position.x) + 1, int(circulation_bounds.end.x)):
		for z in range(int(circulation_bounds.position.z) + 1, int(circulation_bounds.end.z)):
			player.global_position = Vector3(x, 0.138, z)
			if scene.call("_player_has_reached_artroom_hallway"):
				found = true
				break
		if found:
			break
	scene.call("_update_preview_item_encounter")
	check(found and not scene.get("_brush_escape_active") and not art.get("_active"), "School hallway detector ends Art escape")

	await fresh()
	await unlock()
	var science: AABB = scene.get("_item_room_bounds")[&"science_classroom"]
	player.global_position = Vector3(science.get_center().x, science.end.y, science.get_center().z)
	scene.call("_update_preview_item_encounter")
	check(scene.get("_science_spawn_pending") and scene.get("_active_preview_encounter") == &"science_classroom", "Science entry queues Lab encounter")
	for i in range(16):
		player.get_node("CameraPivot").rotation.y = i * TAU / 16
		await settle(2)
		scene.call("_try_science_room_encounter_spawn")
		if not scene.get("_science_spawn_pending"):
			break
	check(monster.get("_preview_item_encounter") == &"science_classroom", "existing offscreen gate starts Science Monster")
	var lab: AABB = scene.get("_item_room_bounds")[&"lab_room"]
	player.global_position = Vector3(lab.get_center().x, lab.end.y, lab.get_center().z)
	scene.call("_update_preview_item_encounter")
	check(scene.get("_science_window_spawn_pending"), "Lab entry queues existing window stalk")
	for i in range(16):
		player.get_node("CameraPivot").rotation.y = i * TAU / 16
		await settle(2)
		scene.call("_try_science_window_stalk_spawn")
		if not scene.get("_science_window_spawn_pending"):
			break
	check(monster.call("is_preview_window_stalking"), "Lab window stalk starts through existing visibility gate")
	items = scene.get("_item_markers")
	player.global_position = items[&"lab_coat"].global_position
	check(scene.call("_try_collect_preview_item"), "actual Lab Coat pickup works")
	check(monster.call("is_preview_window_sliding"), "Lab Coat starts original window slide")

	await fresh()
	await unlock()
	items = scene.get("_item_markers")
	player.global_position = items[&"ruler"].global_position
	check(scene.call("_try_collect_preview_item"), "actual Ruler pickup works")
	check(scene.get("_ruler_hall_event_active") and monster.call("is_preview_ruler_hall_active"), "Ruler pickup starts existing hallway encounter")

	await fresh()
	await unlock()
	items = scene.get("_item_markers")
	player.global_position = items[&"snack"].global_position
	scene.call("_update_preview_item_encounter")
	check(monster.get("_preview_item_encounter") == &"snack" and monster.get("_preview_snack_phase") == &"waiting", "Cafe room entry starts Kitchen watch")
	var cafe: AABB = scene.get("_item_room_bounds")[&"cafeteria"]
	var points: Array = scene.call("_cafeteria_snack_points", cafe)
	check(points.size() == 3 and monster.global_position.distance_to(points[0]) < 0.001, "Cafe wait and both peek targets available")
	check(scene.call("_try_collect_preview_item"), "actual Snack pickup works")
	check(not scene.get("_final_bell_started") and not scene.get("_victory_started"), "ordinary pickups do not trigger final victory")
	print("REMAINING_ENCOUNTERS_RESULT checks=%d failures=%d" % [checks, failures])
	scene.queue_free()
	await settle(8)
	quit(1 if failures else 0)
