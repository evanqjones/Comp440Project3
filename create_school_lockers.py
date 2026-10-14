"""Create detailed reusable locker models in assets.blend.

The two prototypes live far below the school as organized source assets. Use
export_school_lockers.py to export just these prototypes for runtime placement.
"""
import bpy
from mathutils import Matrix


COLLECTION_NAME = "School - Locker Asset Prototypes"
COLLECTION_Y = -1000.0

old = bpy.data.collections.get(COLLECTION_NAME)
if old is not None:
    for obj in list(old.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(old)
collection = bpy.data.collections.new(COLLECTION_NAME)
bpy.context.scene.collection.children.link(collection)


def material(name, color, metallic=0.0, roughness=0.55):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


enamel = material("Locker - Deep School Blue Enamel", (0.10, 0.24, 0.34), 0.48, 0.32)
door_blue = material("Locker - Door Blue", (0.16, 0.37, 0.49), 0.38, 0.34)
edge_blue = material("Locker - Dark Frame", (0.055, 0.13, 0.19), 0.45, 0.4)
inside = material("Locker - Shadowed Interior", (0.018, 0.034, 0.044), 0.12, 0.78)
steel = material("Locker - Brushed Hardware", (0.58, 0.68, 0.71), 0.78, 0.27)
label = material("Locker - Warm White Number Plate", (0.88, 0.83, 0.65), 0.18, 0.42)


def cube(parent, name, location, size, mat, bevel=0.015):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.location = location
    for users_collection in list(obj.users_collection):
        users_collection.objects.unlink(obj)
    collection.objects.link(obj)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.location = location
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Soft formed metal edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.profile = 0.5
        normal = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def make_variant(name, width, door_count):
    root = bpy.data.objects.new(name, None)
    collection.objects.link(root)
    root.location = (0.0, COLLECTION_Y, 0.0)
    root.empty_display_type = "CUBE"
    root.empty_display_size = 0.18
    height, depth = 2.05, 0.78

    # Solid steel shell, dark open face, top cap, and raised plinth.
    # Blender is Z-up, while Godot is Y-up. Keep the cabinet height on Blender Z
    # so the glTF Y-up conversion imports it standing vertically in Godot.
    cube(root, f"{name} - cabinet carcass", (0, 0, height * 0.5), (depth, width, height - 0.10), enamel, 0.035)
    cube(root, f"{name} - recessed face shadow", (depth * 0.5 + 0.006, 0, height * 0.51), (0.018, width - 0.13, height - 0.19), inside, 0.008)
    cube(root, f"{name} - top cap", (0, 0, height - 0.035), (depth + 0.025, width + 0.025, 0.07), edge_blue, 0.018)
    cube(root, f"{name} - kick plate", (depth * 0.28, 0, 0.09), (depth * 0.52, width - 0.08, 0.18), edge_blue, 0.018)
    for side in (-1, 1):
        cube(root, f"{name} - face stile", (depth * 0.5 + 0.025, side * (width * 0.5 - 0.055), height * 0.52), (0.065, 0.09, height - 0.15), edge_blue, 0.012)
        cube(root, f"{name} - foot", (0, side * (width * 0.34), 0.035), (depth * 0.7, 0.07, 0.07), steel, 0.014)

    bay_width = (width - 0.14) / door_count
    for bay in range(door_count):
        center_y = -width * 0.5 + 0.07 + bay_width * (bay + 0.5)
        door_w = bay_width - 0.035
        front_x = depth * 0.5 + 0.052
        cube(root, f"{name} - door {bay + 1}", (front_x, center_y, height * 0.535), (0.045, door_w, height * 0.84), door_blue, 0.022)
        # Shallow inset panel catches light around the vent and handle details.
        cube(root, f"{name} - inset panel {bay + 1}", (front_x + 0.024, center_y, height * 0.51), (0.012, door_w - 0.10, height * 0.60), enamel, 0.012)
        # Three horizontal ventilation slots near the top and bottom.
        for row_z in (height * 0.80, height * 0.75, height * 0.70, height * 0.34, height * 0.29, height * 0.24):
            cube(root, f"{name} - vent {bay + 1}", (front_x + 0.033, center_y, row_z), (0.008, min(door_w * 0.48, 0.23), 0.012), inside, 0.004)
        handle_y = center_y + door_w * 0.30
        cube(root, f"{name} - handle backplate {bay + 1}", (front_x + 0.039, handle_y, height * 0.52), (0.018, 0.075, 0.19), edge_blue, 0.012)
        cube(root, f"{name} - pull handle {bay + 1}", (front_x + 0.055, handle_y, height * 0.52), (0.035, 0.032, 0.14), steel, 0.012)
        cube(root, f"{name} - lock {bay + 1}", (front_x + 0.058, center_y - door_w * 0.28, height * 0.52), (0.018, 0.045, 0.045), steel, 0.018)
        cube(root, f"{name} - number plate {bay + 1}", (front_x + 0.043, center_y, height * 0.91), (0.016, min(door_w * 0.54, 0.30), 0.085), label, 0.009)
        # Visible hinge knuckles on the outside edge of each door.
        hinge_y = center_y - door_w * 0.43
        for hinge_z in (height * 0.20, height * 0.85):
            cube(root, f"{name} - hinge {bay + 1}", (front_x + 0.039, hinge_y, hinge_z), (0.034, 0.035, 0.10), steel, 0.009)
    return root


single = make_variant("School Locker Single", 0.82, 1)
bank = make_variant("School Locker Hall Bank", 2.10, 3)

# Keep prototypes out of the playable school volume while retaining them in the
# Blender source file for easy editing and reuse.
for obj in collection.objects:
    obj.hide_render = True
    obj["asset_prototype"] = True
    obj["locker_asset_note"] = "Reusable locker prototype; see export_school_lockers.py"

bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Created detailed single and three-door locker prototypes in", COLLECTION_NAME)
