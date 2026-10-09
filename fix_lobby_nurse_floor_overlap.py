import bpy


LOBBY_NAME = "Lobby Floor"
NURSE_NAME = "Nurse Office Floor"
FLAG = "nurse_office_overlap_removed"
EDGE_MARGIN = 0.006
CUTTER_DEPTH = 0.3


def world_bounds(obj):
	points = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
	return (
		min(point.x for point in points), max(point.x for point in points),
		min(point.y for point in points), max(point.y for point in points),
		min(point.z for point in points), max(point.z for point in points),
	)


lobby = bpy.data.objects.get(LOBBY_NAME)
nurse = bpy.data.objects.get(NURSE_NAME)
if lobby is None or nurse is None or lobby.type != "MESH" or nurse.type != "MESH":
	raise RuntimeError("Could not find the Lobby and Nurse Office floor meshes")

if not lobby.get(FLAG, False):
	bpy.context.view_layer.update()
	lobby_bounds = world_bounds(lobby)
	nurse_bounds = world_bounds(nurse)
	x_min = max(lobby_bounds[0], nurse_bounds[0]) - EDGE_MARGIN
	x_max = min(lobby_bounds[1], nurse_bounds[1]) + EDGE_MARGIN
	y_min = max(lobby_bounds[2], nurse_bounds[2]) - EDGE_MARGIN
	y_max = min(lobby_bounds[3], nurse_bounds[3]) + EDGE_MARGIN
	z_min = min(lobby_bounds[4], nurse_bounds[4]) - CUTTER_DEPTH * 0.5
	z_max = max(lobby_bounds[5], nurse_bounds[5]) + CUTTER_DEPTH * 0.5
	if x_max <= x_min or y_max <= y_min:
		raise RuntimeError("The Lobby and Nurse Office floors do not overlap")

	center = ((x_min + x_max) * 0.5, (y_min + y_max) * 0.5, (z_min + z_max) * 0.5)
	size = (x_max - x_min, y_max - y_min, z_max - z_min)
	mesh = bpy.data.meshes.new("Temporary Nurse Office Floor Cutout Mesh")
	verts = [
		(-size[0] / 2, -size[1] / 2, -size[2] / 2),
		(size[0] / 2, -size[1] / 2, -size[2] / 2),
		(size[0] / 2, size[1] / 2, -size[2] / 2),
		(-size[0] / 2, size[1] / 2, -size[2] / 2),
		(-size[0] / 2, -size[1] / 2, size[2] / 2),
		(size[0] / 2, -size[1] / 2, size[2] / 2),
		(size[0] / 2, size[1] / 2, size[2] / 2),
		(-size[0] / 2, size[1] / 2, size[2] / 2),
	]
	faces = [
		(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
		(1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7),
	]
	mesh.from_pydata(verts, [], faces)
	cutter = bpy.data.objects.new("Temporary Nurse Office Floor Cutout", mesh)
	cutter.location = center
	bpy.context.collection.objects.link(cutter)

	modifier = lobby.modifiers.new("Remove floor under Nurse Office", "BOOLEAN")
	modifier.operation = "DIFFERENCE"
	modifier.solver = "EXACT"
	modifier.object = cutter
	bpy.ops.object.select_all(action="DESELECT")
	lobby.select_set(True)
	bpy.context.view_layer.objects.active = lobby
	bpy.ops.object.modifier_apply(modifier=modifier.name)
	bpy.data.objects.remove(cutter, do_unlink=True)
	lobby[FLAG] = True

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Removed the Nurse Office footprint from the Lobby floor to stop the overlapping surfaces")
