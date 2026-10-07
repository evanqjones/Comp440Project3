@tool
extends Resource
## Edit the SchoolFoundation's Layout resource, then reload the scene/run again.

@export_range(3.0, 8.0, 0.1) var cell_size: float = 4.0
@export_range(2.8, 6.0, 0.1) var ceiling_height: float = 3.2
@export_range(0.1, 0.5, 0.05) var wall_thickness: float = 0.2
@export_range(1.2, 2.8, 0.1) var door_width: float = 2.0
@export_range(2.3, 2.7, 0.1) var door_height: float = 2.5
@export_range(0.1, 0.5, 0.05) var navigation_radius: float = 0.35
@export_range(1.0, 2.2, 0.1) var navigation_height: float = 2.2
@export var entrance_cell := Vector2i(6, 6)
@export var room_rectangles: Dictionary = {
	&"hall_main": Rect2i(0, 3, 6, 1), &"hall_east": Rect2i(6, 0, 1, 6),
	&"hall_north": Rect2i(2, 0, 4, 1), &"hall_west": Rect2i(2, 1, 1, 2),
	&"classroom_101": Rect2i(0, 1, 2, 2), &"classroom_102": Rect2i(0, 4, 2, 2),
	&"classroom_103": Rect2i(3, 4, 2, 2), &"library": Rect2i(3, 1, 3, 2),
	&"entrance": Rect2i(6, 6, 1, 1), &"science_lab": Rect2i(3, 6, 2, 2),
}
@export var door_edges: Dictionary = {
	&"door_101": Vector4i(1, 2, 1, 3), &"door_102": Vector4i(1, 4, 1, 3),
	&"door_103": Vector4i(3, 4, 3, 3), &"door_library_south": Vector4i(4, 2, 4, 3),
	&"door_library_east": Vector4i(5, 1, 6, 1), &"door_lobby": Vector4i(6, 5, 6, 6),
	&"exit_main": Vector4i(6, 6, 6, 7), &"door_science": Vector4i(3, 5, 3, 6),
}
## Solid shelf partitions: also remove the exact matching navigation edges.
@export var library_partitions: Array[Vector4i] = [Vector4i(4, 1, 4, 2), Vector4i(4, 2, 5, 2)]
@export var library_checkpoints: Array[Vector2i] = [Vector2i(4, 2), Vector2i(3, 2), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(5, 2)]
@export var science_entry := Vector2i(3, 6)
@export var science_goal := Vector2i(4, 7)


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(cell_size) or cell_size < 3 or not is_finite(ceiling_height) or ceiling_height < 2.8:
		errors.append("Cell size/ceiling height are invalid.")
	if not is_finite(wall_thickness) or wall_thickness <= 0 or wall_thickness >= cell_size / 2:
		errors.append("Wall thickness is invalid.")
	if not is_finite(navigation_radius) or navigation_radius <= 0 or navigation_radius * 2 + wall_thickness >= cell_size:
		errors.append("Navigation radius cannot fit inside a cell.")
	if not is_finite(navigation_height) or navigation_height <= 0 or navigation_height >= door_height:
		errors.append("Navigation height must fit below the door lintel.")
	if not is_finite(door_width) or door_width <= navigation_radius * 2 + 0.1 or door_width >= cell_size:
		errors.append("Door width must clear the supported agent and leave jambs.")
	if not is_finite(door_height) or door_height >= ceiling_height:
		errors.append("Door height must be below the ceiling.")
	var cells := {}
	for id in room_rectangles:
		if not room_rectangles[id] is Rect2i or String(id).is_empty():
			errors.append("Every room needs an ID and Rect2i.")
			continue
		var rect: Rect2i = room_rectangles[id]
		if rect.size.x <= 0 or rect.size.y <= 0 or rect.get_area() > 256:
			errors.append("Room dimensions must contain 1–256 cells.")
			continue
		for x in range(rect.position.x, rect.end.x):
			for z in range(rect.position.y, rect.end.y):
				var cell := Vector2i(x, z)
				if cells.has(cell):
					errors.append("Overlapping rooms at %s" % cell)
				cells[cell] = id
	for id in door_edges:
		if not door_edges[id] is Vector4i:
			errors.append("Door edges must be Vector4i pairs.")
			continue
		var edge: Vector4i = door_edges[id]
		var a := Vector2i(edge.x, edge.y)
		var b := Vector2i(edge.z, edge.w)
		if absi(a.x - b.x) + absi(a.y - b.y) != 1 or not cells.has(a):
			errors.append("Door %s must connect adjacent cells with an interior start." % id)
	for edge in library_partitions:
		var a := Vector2i(edge.x, edge.y)
		var b := Vector2i(edge.z, edge.w)
		if cells.get(a) != &"library" or cells.get(b) != &"library" or absi(a.x - b.x) + absi(a.y - b.y) != 1:
			errors.append("Library partition must join adjacent library cells.")
	if not cells.has(entrance_cell) or cells.get(science_entry) != &"science_lab" or cells.get(science_goal) != &"science_lab":
		errors.append("Entrance/science anchors must lie inside their rooms.")
	if library_checkpoints.size() < 2:
		errors.append("Library needs entry and item checkpoints.")
	for cell in library_checkpoints:
		if cells.get(cell) != &"library":
			errors.append("Library checkpoint must lie inside library.")
	return errors
