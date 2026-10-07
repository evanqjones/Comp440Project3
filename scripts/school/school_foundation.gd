@tool
class_name SchoolFoundation
extends Node3D
## Standalone provisional graybox. Positions returned by the API are world-space.
## Static route clearance: radius <= 0.35 m, height <= 2.2 m; keep root scale at one.

signal player_room_changed(previous_room: StringName, current_room: StringName)

const Layout = preload("res://scripts/school/school_layout.gd")
@export var layout: Layout = Layout.new()
@export var debug_visible: bool = false:
	set(value):
		debug_visible = value
		if is_instance_valid(_debug_root):
			_debug_root.visible = value
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
var _debug_root: Node3D
var _route_visual: MeshInstance3D


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
	if point.y < -0.1 or point.y >= layout.ceiling_height:
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
	return get_cell_position(layout.entrance_cell)


func get_cell_position(cell: Vector2i) -> Vector3:
	return to_global(_center(cell))


func get_navigation_connections() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cell: Vector2i in _indices:
		var id: int = _indices[cell]
		for neighbor in _graph.get_point_connections(id):
			if neighbor > id:
				var a := _graph.get_point_position(id)
				var b := _graph.get_point_position(neighbor)
				result.append({"from": to_global(a), "to": to_global(b),
					"room_a": _cells[_cell_at(a)], "room_b": _cells[_cell_at(b)]})
	return result


func set_debug_visible(enabled: bool) -> void:
	debug_visible = enabled
	if is_instance_valid(_debug_root):
		_debug_root.visible = enabled


func show_debug_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	var path := get_traversable_path(from_world, to_world)
	if is_instance_valid(_route_visual):
		_route_visual.free()
	_route_visual = _lines(path, Color(1, 0.7, 0.1), false)
	return path


func _partition_between(a: Vector2i, b: Vector2i) -> bool:
	for edge in layout.library_partitions:
		var first := Vector2i(edge.x, edge.y)
		var second := Vector2i(edge.z, edge.w)
		if (a == first and b == second) or (a == second and b == first):
			return true
	return false


func _cell_at(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / layout.cell_size), floori(point.z / layout.cell_size))


func _center(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * layout.cell_size, 0, (cell.y + 0.5) * layout.cell_size)


func _valid_position(point: Vector3) -> bool:
	if point.y < -0.1 or point.y > layout.navigation_height or not _cells.has(_cell_at(point)):
		return false
	for wall in _walls:
		if wall.grow(layout.navigation_radius).has_point(Vector3(point.x, 1.0, point.z)):
			return false
	# No routing beyond the authored floor, including the outside exit edge.
	var cell := _cell_at(point)
	for direction: Vector2i in DIRECTIONS:
		if not _cells.has(cell + direction):
			var relative := point - _center(cell)
			if relative.x * direction.x + relative.z * direction.y > layout.cell_size / 2.0 - layout.navigation_radius:
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
	var errors := layout.validation_errors()
	if not errors.is_empty():
		push_error("Invalid School layout: " + "; ".join(errors))
		return
	_generated = Node3D.new()
	_generated.name = "GeneratedSchool"
	add_child(_generated)
	for id: StringName in layout.room_rectangles:
		var rect: Rect2i = layout.room_rectangles[id]
		_room(id, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	for id: StringName in layout.door_edges:
		var edge: Vector4i = layout.door_edges[id]
		_door(id, Vector2i(edge.x, edge.y), Vector2i(edge.z, edge.w))
	for cell: Vector2i in _cells:
		var index := _indices.size()
		_indices[cell] = index
		_graph.add_point(index, _center(cell))
		var room: StringName = _cells[cell]
		var color := Color(0.24, 0.29, 0.34) if String(room).begins_with("hall") else Color(0.38, 0.35, 0.28)
		_box("Floor", _center(cell) + Vector3(0, -0.1, 0), Vector3(layout.cell_size, 0.2, layout.cell_size), color)
		_box("Ceiling", _center(cell) + Vector3(0, layout.ceiling_height + 0.1, 0), Vector3(layout.cell_size, 0.2, layout.cell_size), Color(0.22, 0.24, 0.28))
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
				if _partition_between(cell, other):
					open_edge = false
					doorway = false
				if open_edge or doorway:
					_graph.connect_points(_indices[cell], _indices[other])
			if not open_edge:
				var center := (_center(cell) + _center(other)) / 2.0
				if _partition_between(cell, other):
					var size := Vector3(layout.wall_thickness, layout.ceiling_height, layout.cell_size) if direction.x != 0 else Vector3(layout.cell_size, layout.ceiling_height, layout.wall_thickness)
					_walls.append(AABB(center + Vector3(0, layout.ceiling_height / 2, 0) - size / 2, size))
					_box("LibraryShelfPartition", center + Vector3(0, layout.ceiling_height / 2, 0), size, Color(0.28, 0.16, 0.08))
				else:
					_boundary(center, direction.x != 0, doorway)
	_build_stalking_markers()
	for room in get_room_ids():
		var locations := get_stalking_locations(room)
		var label := Label3D.new()
		label.text = String(room).replace("_", " ").to_upper()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = to_local(locations[0].position) + Vector3(0, 2.5, 0)
		label.font_size = 40
		_generated.add_child(label)
		var light := OmniLight3D.new()
		light.position = label.position
		light.omni_range = 12.0
		light.light_color = Color(1.0, 0.85, 0.58)
		light.light_energy = 1.2
		_generated.add_child(light)
	_build_debug()


func _boundary(center: Vector3, along_z: bool, doorway: bool) -> void:
	if not doorway:
		_wall(center + Vector3(0, layout.ceiling_height / 2, 0), Vector3(layout.wall_thickness, layout.ceiling_height, layout.cell_size) if along_z else Vector3(layout.cell_size, layout.ceiling_height, layout.wall_thickness))
		return
	var jamb := (layout.cell_size - layout.door_width) / 2
	var offset_distance := (layout.cell_size + layout.door_width) / 4
	for sign_value in [-1.0, 1.0]:
		var offset := Vector3(0, layout.ceiling_height / 2, sign_value * offset_distance) if along_z else Vector3(sign_value * offset_distance, layout.ceiling_height / 2, 0)
		_wall(center + offset, Vector3(layout.wall_thickness, layout.ceiling_height, jamb) if along_z else Vector3(jamb, layout.ceiling_height, layout.wall_thickness))
	var lintel := layout.ceiling_height - layout.door_height
	_box("DoorLintel", center + Vector3(0, layout.door_height + lintel / 2, 0), Vector3(layout.wall_thickness, lintel, layout.door_width) if along_z else Vector3(layout.door_width, lintel, layout.wall_thickness), Color(0.35, 0.27, 0.16))


func _build_stalking_markers() -> void:
	for cell: Vector2i in _cells:
		var room: StringName = _cells[cell]
		var tags: Array[StringName] = []
		tags.append(&"hallway" if String(room).begins_with("hall") else &"room")
		var connections := _graph.get_point_connections(_indices[cell])
		if connections.size() >= 3 and tags.has(&"hallway"):
			tags.append(&"intersection")
		if connections.size() == 2:
			var a := _graph.get_point_position(connections[0]) - _center(cell)
			var b := _graph.get_point_position(connections[1]) - _center(cell)
			if absf(a.normalized().dot(b.normalized())) < 0.1:
				tags.append(&"corner")
		_add_stalk(StringName("stalk_%s_%d_%d" % [room, cell.x, cell.y]), _center(cell), tags)
	for door in _doors:
		if door.room_b == &"outside":
			continue
		_add_stalk(StringName("stalk_" + String(door.id)), door.position, [&"doorway"])


func _add_stalk(id: StringName, position_local: Vector3, tags: Array[StringName]) -> void:
	if not _valid_position(position_local):
		push_error("Stalking marker has no clearance: " + String(id))
		return
	_stalks.append({"id": id, "room_id": _cells[_cell_at(position_local)], "position": position_local, "tags": tags})
	var marker := Marker3D.new()
	marker.name = id
	marker.position = position_local
	_generated.add_child(marker)


func _build_debug() -> void:
	_debug_root = Node3D.new()
	_debug_root.name = "NavigationDebug"
	_generated.add_child(_debug_root)
	var points := PackedVector3Array()
	for edge in get_navigation_connections():
		points.append(edge.from)
		points.append(edge.to)
	_lines(points, Color(0.15, 0.85, 1), true)
	for location in _stalks:
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		mesh.mesh = sphere
		mesh.position = location.position + Vector3(0, 0.25, 0)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(1, 0.3, 0.85) if location.tags.has(&"doorway") else Color(0.2, 1, 0.4)
		mesh.material_override = material
		_debug_root.add_child(mesh)
	set_debug_visible(debug_visible)


func _lines(points: PackedVector3Array, color: Color, pairs: bool) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	_debug_root.add_child(visual)
	if points.size() < 2:
		return visual
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var step := 2 if pairs else 1
	for i in range(0, points.size() - 1, step):
		mesh.surface_add_vertex(to_local(points[i]) + Vector3(0, 0.15, 0))
		mesh.surface_add_vertex(to_local(points[i + 1]) + Vector3(0, 0.15, 0))
	mesh.surface_end()
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	visual.material_override = material
	return visual


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
