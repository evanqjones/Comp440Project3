extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var school = load("res://scenes/school_foundation.tscn").instantiate()
	root.add_child(school)
	await physics_frame
	await physics_frame
	_check(school.get_room_ids().size() == 10, "Expected ten room/hall IDs")
	_check(school.get_door_connections().size() == 8, "Expected seven interior doors and one exit")
	_check(school.get_room_id_at(Vector3(-10, 0, 0)) == &"", "Outside must have no room")
	_check(school.get_room_id_at(Vector3(2, 5, 14)) == &"", "Above ceiling must have no room")
	var locations: Array = school.get_stalking_locations()
	var tags := {}
	for record: Dictionary in locations:
		for tag in record.tags:
			tags[tag] = true
	for tag in [&"room", &"hallway", &"corner", &"intersection", &"doorway"]:
		_check(tags.has(tag), "Missing stalking category: " + String(tag))
	var copied: Array = school.get_stalking_locations()
	copied[0].tags.clear()
	_check(not school.get_stalking_locations()[0].tags.is_empty(), "Consumer mutation must not change marker authority")
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 2.2
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState3D = school.get_world_3d().direct_space_state
	var checked_segments := {}
	for a: Dictionary in locations:
		_check(school.get_room_id_at(a.position) == a.room_id, "Stalking room mismatch")
		for b: Dictionary in locations:
			var path: PackedVector3Array = school.get_traversable_path(a.position, b.position)
			_check(not path.is_empty(), "Every stalking location must be reachable")
			for i in range(path.size() - 1):
				var key := str(path[i]) + str(path[i + 1])
				if checked_segments.has(key):
					continue
				checked_segments[key] = true
				query.transform = Transform3D(Basis.IDENTITY, path[i] + Vector3(0, 1.15, 0))
				query.motion = path[i + 1] - path[i]
				var motion := space.cast_motion(query)
				_check(motion[0] == 1.0, "Capsule route intersects geometry: " + key)
	var ray := PhysicsRayQueryParameters3D.create(Vector3(6, 1.5, 10), Vector3(14, 1.5, 10), 1)
	_check(not space.intersect_ray(ray).is_empty(), "Room walls must block sight")
	ray = PhysicsRayQueryParameters3D.create(Vector3(18, 1.5, 6), Vector3(18, 1.5, 10), 1)
	_check(not space.intersect_ray(ray).is_empty(), "Library maze partition must block sight")
	var maze_path: PackedVector3Array = school.get_traversable_path(Vector3(18, 0, 6), Vector3(18, 0, 10))
	_check(maze_path.size() > 4, "Navigation must detour around library partition")
	for edge: Dictionary in school.get_navigation_connections():
		_check(not school.get_traversable_path(edge.from, edge.to).is_empty(), "Published connectivity must be traversable")
	school.set_debug_visible(true)
	_check(not school.show_debug_path(school.get_entrance_position(), Vector3(18, 0, 30)).is_empty(), "Debug route reaches science lab")
	_check(school.get_traversable_path(Vector3(-2, 0, 0), locations[0].position).is_empty(), "Invalid endpoints must be rejected")
	_check(school.get_traversable_path(Vector3(8, 0, 10), locations[0].position).is_empty(), "Wall endpoints must be rejected")
	var actor := Node3D.new()
	root.add_child(actor)
	school.set_player_target(actor)
	actor.position = school.get_entrance_position()
	await physics_frame
	await physics_frame
	_check(school.get_current_room_id() == &"entrance", "Tracked room must follow actor")
	actor.queue_free()
	await physics_frame
	await physics_frame
	_check(school.get_current_room_id() == &"", "Freed actor must clear room")
	# Queries must also work when the school is translated and rotated.
	school.position = Vector3(50, 2, -30)
	school.rotation.y = 0.7
	var moved: Array = school.get_stalking_locations()
	_check(school.get_room_id_at(moved[0].position) == moved[0].room_id, "World-space room query")
	_check(not school.get_traversable_path(moved[0].position, moved[-1].position).is_empty(), "World-space route query")
	var configurable = load("res://scenes/school_foundation.tscn").instantiate()
	configurable.layout = school.layout.duplicate(true)
	configurable.layout.cell_size = 5.0
	configurable.layout.ceiling_height = 4.0
	configurable.position = Vector3(-100, 0, -100)
	root.add_child(configurable)
	_check(configurable.get_room_id_at(configurable.get_cell_position(Vector2i(4, 7))) == &"science_lab", "Configured scale updates room regions")
	_check(not configurable.get_traversable_path(configurable.get_entrance_position(), configurable.get_cell_position(Vector2i(4, 7))).is_empty(), "Configured dimensions preserve routing")
	await physics_frame
	await physics_frame
	var scaled_path: PackedVector3Array = configurable.get_traversable_path(configurable.get_entrance_position(), configurable.get_cell_position(Vector2i(4, 7)))
	for i in range(scaled_path.size() - 1):
		query.transform = Transform3D(Basis.IDENTITY, scaled_path[i] + Vector3(0, 1.15, 0))
		query.motion = scaled_path[i + 1] - scaled_path[i]
		_check(space.cast_motion(query)[0] == 1.0, "Configured geometry must match its physical route")
	for cell in [Vector2i(6, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 7)]:
		var target: Vector3 = configurable.get_cell_position(cell) + Vector3(0.4, 0, 0.3)
		var fresh: PackedVector3Array = configurable.get_traversable_path(configurable.get_entrance_position(), target)
		_check(not fresh.is_empty() and fresh[-1].is_equal_approx(target), "Fresh path must end at moving target's new position")
	print("School foundation: %d locations, %d collision-tested segments, %d failures" % [locations.size(), checked_segments.size(), failures])
	quit(1 if failures else 0)
