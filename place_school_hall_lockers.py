"""Place the six reusable locker banks in the Blender school under the long hall window."""
import bpy
from mathutils import Matrix


SCHOOL_NAME = "After School - School Blockout"
PROTOTYPE_COLLECTION_NAME = "School - Locker Asset Prototypes"
PLACEMENT_COLLECTION_NAME = "School - East Hall Locker Placements"
WALL_X = 40.0
FLOOR_Z = 0.138
GODOT_Z_POSITIONS = [3.8, 6.04, 8.28, 10.52, 12.76, 15.0]

school = bpy.data.collections.get(SCHOOL_NAME)
prototypes = bpy.data.collections.get(PROTOTYPE_COLLECTION_NAME)
if school is None or prototypes is None:
    raise RuntimeError("School and locker prototype collections must exist")
bank_source = bpy.data.objects.get("School Locker Hall Bank")
if bank_source is None:
    raise RuntimeError("School Locker Hall Bank prototype is missing")

old = bpy.data.collections.get(PLACEMENT_COLLECTION_NAME)
if old is not None:
    for obj in list(old.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for child in list(old.children):
        old.children.unlink(child)
    for parent_collection in list(old.users_collection):
        parent_collection.children.unlink(old)
    bpy.data.collections.remove(old)

placements = bpy.data.collections.new(PLACEMENT_COLLECTION_NAME)
school.children.link(placements)
source_parts = [obj for obj in bank_source.children if obj.type == "MESH"]

for index, godot_z in enumerate(GODOT_Z_POSITIONS, 1):
    root = bpy.data.objects.new("RulerHallLocker_%02d" % index, None)
    placements.objects.link(root)
    # Godot's Y-up coordinates map from Blender's Z-up: Godot Z = -Blender Y.
    root.location = (WALL_X, -godot_z, FLOOR_Z)
    root.rotation_euler.z = 3.141592653589793
    root.empty_display_type = "CUBE"
    root.empty_display_size = 0.14
    root["locker_hiding_spot"] = True
    root["prototype"] = "School Locker Hall Bank"
    for source in source_parts:
        part = source.copy()
        part.data = source.data
        part.name = "RulerHallLocker_%02d - %s" % (index, source.name.rsplit(" - ", 1)[-1])
        placements.objects.link(part)
        part.parent = root
        part.matrix_parent_inverse = Matrix.Identity(4)
        part.location = source.location.copy()
        part.rotation_euler = source.rotation_euler.copy()
        part.scale = source.scale.copy()
        part.hide_render = False
        part.hide_set(False)

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Placed six detailed locker banks below the narrow east hallway window")
