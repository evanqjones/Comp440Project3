import bpy
from math import radians

collection = bpy.data.collections.get("LOCKERS - Move These Into The School")
if collection is None:
    raise RuntimeError("Locker placement collection is missing")

# The locker doors are built toward local +X. The placed row is along the north
# wall, with the corridor on its -Y side, so turn each root 90 degrees clockwise.
for root in collection.objects:
    if root.type == "EMPTY" and root.name.startswith("Locker Placement "):
        root.rotation_euler.z = radians(-90)

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Rotated six placed lockers to face the hallway (-Y)")
