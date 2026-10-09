import bpy


OBJECT_NAME = "School Site Floor - circulation"
OFFSET_Z = 0.06
FLAG = "room_floor_overlap_offset_applied"

floor = bpy.data.objects.get(OBJECT_NAME)
if floor is None or floor.type != "MESH":
	raise RuntimeError("Could not find the circulation foundation mesh")

if not floor.get(FLAG, False):
	world_matrix = floor.matrix_world.copy()
	world_matrix.translation.z -= OFFSET_Z
	floor.matrix_world = world_matrix
	floor[FLAG] = True

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Lowered the circulation foundation by %.3f m to separate it from room floor tops" % OFFSET_Z)
