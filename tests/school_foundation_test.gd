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
	_check(school.get_room_ids().size() == 9, "Expected nine room/hall IDs")
	_check(school.get_door_connections().size() == 7, "Expected six interior doors and one exit")
	_check(school.get_room_id_at(Vector3(-10, 0, 0)) == &"", "Outside must have no room")
	_check(school.get_room_id_at(Vector3(2, 5, 14)) == &"", "Above ceiling must have no room")
	var locations: Array = school.get_stalking_locations()
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
	print("School foundation: %d locations, %d collision-tested segments, %d failures" % [locations.size(), checked_segments.size(), failures])
	quit(1 if failures else 0)
