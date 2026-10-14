"""Move the six reusable locker meshes into a visible Blender staging row."""
import bpy
from mathutils import Matrix

PLACEMENT = "School - East Hall Locker Placements"
KIT = "LOCKERS - Move These Into The School"
SCHOOL = "After School - School Blockout"

school = bpy.data.collections.get(SCHOOL)
if school is None:
    raise RuntimeError("School collection is missing")

# Remove the previous in-game Blender placements. The game creates its hallway
# locker row at runtime, so these copies are only a movable Blender placement kit.
old = bpy.data.collections.get(PLACEMENT)
if old:
    for obj in list(old.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for parent in list(bpy.data.collections):
        if old in parent.children.values():
            parent.children.unlink(old)
    bpy.data.collections.remove(old)

old_kit = bpy.data.collections.get(KIT)
if old_kit:
    for obj in list(old_kit.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for parent in list(bpy.data.collections):
        if old_kit in parent.children.values():
            parent.children.unlink(old_kit)
    bpy.data.collections.remove(old_kit)

prototypes = bpy.data.collections.get("School - Locker Asset Prototypes")
single = bpy.data.objects.get("School Locker Single")
if single is None:
    raise RuntimeError("School Locker Single prototype is missing")
parts = [o for o in single.children_recursive if o.type == "MESH"]
if not parts:
    raise RuntimeError("Locker prototype has no mesh parts")

kit = bpy.data.collections.new(KIT)
school.children.link(kit)
# Blender uses Z-up; this row sits just outside the rear wall (positive Y).
# It remains close to the building and is easy to select from the school view.
for i in range(6):
    root = bpy.data.objects.new("Locker Placement %02d - move me" % (i + 1), None)
    kit.objects.link(root)
    root.location = (23.0 + i * 1.15, 23.5, 0.14)
    root.empty_display_type = "CUBE"
    root.empty_display_size = 0.18
    root["placement_kit"] = True
    for src in parts:
        part = src.copy()
        part.data = src.data
        part.name = "Locker %02d - %s" % (i + 1, src.name)
        kit.objects.link(part)
        part.parent = root
        part.matrix_parent_inverse = Matrix.Identity(4)
        part.location = src.location.copy()
        part.rotation_euler = src.rotation_euler.copy()
        part.scale = src.scale.copy()
        part.hide_render = False
        part.hide_set(False)

# Keep the school scene active and the staging collection expanded/visible.
for scene in bpy.data.scenes:
    if scene.name == "School":
        bpy.context.window.scene = scene
        break
for layer in bpy.context.view_layer.layer_collection.children:
    if layer.collection == kit:
        layer.exclude = False

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Staged six individually selectable lockers behind the school")
