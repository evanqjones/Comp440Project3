@tool
class_name SchoolFoundation
extends Node3D
## Standalone provisional graybox. Positions returned by the API are world-space.
## Static route clearance: radius <= 0.35 m, height <= 2.2 m; keep root scale at one.

signal player_room_changed(previous_room: StringName, current_room: StringName)

const CELL := 4.0
const HEIGHT := 3.2
const RADIUS := 0.35
const DIRECTIONS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

var _cells: Dictionary = {}
var _indices: Dictionary = {}
var _doors: Array[Dictionary] = []
var _walls: Array[AABB] = []
var _stalks: Array[Dictionary] = []
var _graph := AStar3D.new()
var _generated: Node3D
var _player: Node3D
var _current_room: StringName = &""


func _ready() -> void:
	_build()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var room: StringName = get_room_id_at(_player.global_position) if is_instance_valid(_player) else &""
	if room != _current_room:
		var previous := _current_room
		_current_room = room
		player_room_changed.emit(previous, room)


func set_player_target(player: Node3D) -> void:
	_player = player


func get_current_room_id() -> StringName:
	return _current_room


func get_room_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for room: StringName in _cells.values():
		if not result.has(room):
			result.append(room)
	return result


func get_room_id_at(world_position: Vector3) -> StringName:
	var point := to_local(world_position)
	if point.y < -0.1 or point.y >= HEIGHT:
		return &""
	# Half-open cell bounds make threshold ownership deterministic.
	return _cells.get(_cell_at(point), &"")


func get_stalking_locations(room_id: StringName = &"") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for location in _stalks:
		if room_id == &"" or location.room_id == room_id:
			var record := location.duplicate(true)
			record.position = to_global(record.position)
			result.append(record)
	return result


func get_door_connections() -> Array[Dictionary]:
	var result: Array[Dictionary] = _doors.duplicate(true)
	for door in result:
		door.position = to_global(door.position)
	return result


func get_traversable_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	var start := to_local(from_world)
	var finish := to_local(to_world)
	if not _valid_position(start) or not _valid_position(finish):
		return PackedVector3Array()
	start.y = 0.0
	finish.y = 0.0
	var a: int = _indices[_cell_at(start)]
	var b: int = _indices[_cell_at(finish)]
	var path := PackedVector3Array([to_global(start)])
	var middle := _graph.get_point_path(a, b)
	if middle.is_empty():
		return PackedVector3Array()
	for point in middle:
		path.append(to_global(point))
	path.append(to_global(finish))
	return path


func get_entrance_position() -> Vector3:
	return to_global(_center(Vector2i(6, 6)))


func _cell_at(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / CELL), floori(point.z / CELL))


func _center(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * CELL, 0, (cell.y + 0.5) * CELL)


func _valid_position(point: Vector3) -> bool:
	if point.y < -0.1 or point.y > 2.2 or not _cells.has(_cell_at(point)):
		return false
	for wall in _walls:
		if wall.grow(RADIUS).has_point(Vector3(point.x, 1.0, point.z)):
			return false
	# No routing beyond the authored floor, including the outside exit edge.
	var cell := _cell_at(point)
	for direction: Vector2i in DIRECTIONS:
		if not _cells.has(cell + direction):
			var relative := point - _center(cell)
			if relative.x * direction.x + relative.z * direction.y > CELL / 2.0 - RADIUS:
				return false
	return true


func _room(id: StringName, x: int, z: int, width: int, depth: int) -> void:
	for i in range(x, x + width):
		for j in range(z, z + depth):
			_cells[Vector2i(i, j)] = id


func _door(id: StringName, a: Vector2i, b: Vector2i) -> void:
	_doors.append({"id": id, "room_a": _cells[a], "room_b": _cells.get(b, &"outside"),
		"position": (_center(a) + _center(b)) / 2.0, "open": true, "cell_a": a, "cell_b": b})


func _build() -> void:
	_generated = Node3D.new()
	_generated.name = "GeneratedSchool"
	add_child(_generated)
	_room(&"hall_main", 0, 3, 6, 1)
	_room(&"hall_east", 6, 0, 1, 6)
	_room(&"hall_north", 2, 0, 4, 1)
	_room(&"hall_west", 2, 1, 1, 2)
	_room(&"classroom_101", 0, 1, 2, 2)
	_room(&"classroom_102", 0, 4, 2, 2)
	_room(&"classroom_103", 3, 4, 2, 2)
	_room(&"library", 3, 1, 3, 2)
	_room(&"entrance", 6, 6, 1, 1)
	_door(&"door_101", Vector2i(1, 2), Vector2i(1, 3))
	_door(&"door_102", Vector2i(1, 4), Vector2i(1, 3))
	_door(&"door_103", Vector2i(3, 4), Vector2i(3, 3))
	_door(&"door_library_south", Vector2i(4, 2), Vector2i(4, 3))
	_door(&"door_library_east", Vector2i(5, 1), Vector2i(6, 1))
	_door(&"door_lobby", Vector2i(6, 5), Vector2i(6, 6))
	_door(&"exit_main", Vector2i(6, 6), Vector2i(6, 7))
	for cell: Vector2i in _cells:
		var index := _indices.size()
		_indices[cell] = index
		_graph.add_point(index, _center(cell))
		var room: StringName = _cells[cell]
		var color := Color(0.24, 0.29, 0.34) if String(room).begins_with("hall") else Color(0.38, 0.35, 0.28)
		_box("Floor", _center(cell) + Vector3(0, -0.1, 0), Vector3(CELL, 0.2, CELL), color)
		_box("Ceiling", _center(cell) + Vector3(0, HEIGHT + 0.1, 0), Vector3(CELL, 0.2, CELL), Color(0.22, 0.24, 0.28))
		var stalk_id := StringName("stalk_%s_%d_%d" % [room, cell.x, cell.y])
		_stalks.append({"id": stalk_id, "room_id": room, "position": _center(cell)})
		var marker := Marker3D.new()
		marker.name = stalk_id
		marker.position = _center(cell)
		_generated.add_child(marker)
	for cell: Vector2i in _cells:
		for direction: Vector2i in DIRECTIONS:
			var other := cell + direction
			if _cells.has(other) and _indices[cell] > _indices[other]:
				continue
			var doorway := false
			for door in _doors:
				if (door.cell_a == cell and door.cell_b == other) or (door.cell_b == cell and door.cell_a == other):
					doorway = true
			var open_edge := false
			if _cells.has(other):
				open_edge = _cells[cell] == _cells[other] or (String(_cells[cell]).begins_with("hall") and String(_cells[other]).begins_with("hall"))
				if open_edge or doorway:
					_graph.connect_points(_indices[cell], _indices[other])
			if not open_edge:
				_boundary((_center(cell) + _center(other)) / 2.0, direction.x != 0, doorway)
	for room in get_room_ids():
		var locations := get_stalking_locations(room)
		var label := Label3D.new()
		label.text = String(room).replace("_", " ").to_upper()
		label.position = to_local(locations[0].position) + Vector3(0, 2.5, 0)
		label.font_size = 40
		_generated.add_child(label)
		var light := OmniLight3D.new()
		light.position = label.position
		light.omni_range = 12.0
		light.light_color = Color(1.0, 0.85, 0.58)
		light.light_energy = 1.2
		_generated.add_child(light)


func _boundary(center: Vector3, along_z: bool, doorway: bool) -> void:
	if not doorway:
		_wall(center + Vector3(0, HEIGHT / 2, 0), Vector3(0.2, HEIGHT, CELL) if along_z else Vector3(CELL, HEIGHT, 0.2))
		return
	# A 2 m wide, 2.5 m high open door with solid jambs and lintel.
	for sign_value in [-1.0, 1.0]:
		var offset := Vector3(0, HEIGHT / 2, sign_value * 1.5) if along_z else Vector3(sign_value * 1.5, HEIGHT / 2, 0)
		_wall(center + offset, Vector3(0.2, HEIGHT, 1) if along_z else Vector3(1, HEIGHT, 0.2))
	_box("DoorLintel", center + Vector3(0, 2.85, 0), Vector3(0.2, 0.7, 2) if along_z else Vector3(2, 0.7, 0.2), Color(0.35, 0.27, 0.16))


func _wall(center: Vector3, size: Vector3) -> void:
	_walls.append(AABB(center - size / 2, size))
	_box("Wall", center, size, Color(0.43, 0.48, 0.5))


func _box(label: String, center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = center
	body.collision_layer = 1
	_generated.add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
