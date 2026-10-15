extends SceneTree
## Isolated Microphone encounter and physical center aisle regression check.
var failures := 0
var checks := 0
var player: CharacterBody3D


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


func move_to(point: Vector3) -> bool:
	for i in range(900):
		await physics_frame
		var direction := point - player.global_position
		direction.y = 0
		if direction.length() < 0.05:
			player.velocity = Vector3.ZERO
			return true
		player.velocity = direction.normalized() * minf(3, direction.length() * 60)
		player.velocity.y = -1
		player.move_and_slide()
	return false


func run() -> void:
	var scene := (load("res://scenes/demo_scene.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle(180)
	scene.set_process(false)
	scene.get_node("SchoolBell").call("stop_scheduling")
	player = scene.get_node("PlayerPlaceholder")
	player.set_physics_process(false)
	var monster := scene.get_node("MonsterPlaceholder") as CharacterBody3D
	scene.call("_activate_demo_monster")
	monster.set_physics_process(false)
	var collected: Dictionary = scene.get("_collected_preview_items")
	collected[&"school_keys"] = true
	scene.call("_refresh_demo_door_locks")
	var rooms: Dictionary = scene.get("_item_room_bounds")
	var bounds: AABB = rooms[&"auditorium"]
	var marker := scene.get("_item_markers")[&"microphone"] as Node3D
	var center_x := bounds.get_center().x
	var start := Vector3(center_x, bounds.end.y, bounds.end.z - 0.8)
	var capsule := player.get_node("CollisionShape3D").shape as CapsuleShape3D
	var radius := capsule.radius
	for body_radius in [0.24, 0.45]:
		capsule.radius = body_radius
		player.global_position = start
		check(await move_to(marker.global_position), "physical %.2f m body south approach -> Microphone" % (body_radius * 2))
		check(await move_to(start), "physical %.2f m body Microphone -> south approach" % (body_radius * 2))
	capsule.radius = radius
	player.global_position = marker.global_position
	scene.call("_update_preview_item_encounter")
	var encounter: Node = scene.get("_auditorium_encounter")
	encounter.set_physics_process(false)
	check(encounter.call("is_active") and encounter.get("_phase") == &"guard", "Microphone guard starts through School room handler")
	var expected := Vector3(center_x, bounds.end.y + 0.48, bounds.position.z + 1.15)
	check(monster.global_position.distance_to(expected) < 0.001, "original central stage Monster spawn unchanged")
	await settle(2)
	encounter.call("receive_noise", NoiseEvent.new(player.global_position, NoiseEvent.NoiseLevel.QUIET, &"test"))
	check(encounter.get("_noise_attention_time") > 0, "existing noise attention works")
	encounter.call("_face_direction", player.global_position - monster.global_position, 3.0, 90.0)
	check(encounter.call("_is_player_in_spotlight"), "noise-aimed spotlight sees Player through center aisle")
	check(scene.call("_try_collect_preview_item"), "real Microphone pickup succeeds")
	check(scene.get("_microphone_escape_active") and encounter.get("_phase") == &"pickup_delay", "pickup starts existing suspense delay")
	encounter.call("_physics_process", 2.1)
	check(encounter.get("_phase") == &"escape", "existing delay transitions to chase")
	var door := scene.call("_find_auditorium_exit_door") as Node3D
	door.call("open_for_escape")
	await settle()
	var map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
	check(NavigationServer3D.map_get_path(map, expected, start, true).size() > 1, "stage/steps/aisle navigation connected")
	check(await move_to(start), "Player escapes down original center aisle")
	check(await move_to(Vector3(door.global_position.x, bounds.end.y, bounds.end.z + 0.65)), "Player physically crosses south exit")
	scene.call("_update_preview_item_encounter")
	check(not scene.get("_microphone_escape_active") and not encounter.call("is_active"), "south exit ends existing encounter")
	await settle(90)
	check(door.get("interaction_locked") and not door.get("_opened"), "original south exit slam/lock preserved")
	print("AUDITORIUM_RESULT checks=%d failures=%d" % [checks, failures])
	scene.queue_free()
	await settle(8)
	quit(1 if failures else 0)
