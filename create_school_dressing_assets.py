"""Build stylized lobby and hallway prop prototypes in assets.blend.

Run from the project root with Blender:
    blender --background assets.blend --python create_school_dressing_assets.py

The authored prototypes are exported separately with export_school_dressing.py
and placed by the Godot preview script. Their visual meshes carry no collision.
"""
import bpy
from mathutils import Matrix


COLLECTION_NAME = "School - Lobby Hallway Prop Prototypes"
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


navy = material("Prop - Deep Teal Upholstery", (0.075, 0.22, 0.27), 0.0, 0.72)
teal = material("Prop - Teal Enamel", (0.08, 0.31, 0.34), 0.28, 0.38)
dark_teal = material("Prop - Shaded Teal", (0.035, 0.13, 0.16), 0.18, 0.48)
warm = material("Prop - Warm Brass Accent", (0.79, 0.52, 0.20), 0.62, 0.31)
wood = material("Prop - Walnut Wood", (0.24, 0.12, 0.065), 0.0, 0.42)
wood_light = material("Prop - Honey Oak", (0.49, 0.29, 0.13), 0.0, 0.44)
cream = material("Prop - Warm Porcelain", (0.84, 0.78, 0.61), 0.05, 0.38)
leaf = material("Prop - Evergreen Foliage", (0.11, 0.30, 0.18), 0.0, 0.79)
leaf_light = material("Prop - Fresh Foliage", (0.24, 0.43, 0.22), 0.0, 0.76)
steel = material("Prop - Brushed Steel", (0.37, 0.49, 0.51), 0.68, 0.31)
glass = material("Prop - Smoked Blue Glass", (0.24, 0.46, 0.50), 0.24, 0.24)
glass_bsdf = glass.node_tree.nodes.get("Principled BSDF")
glass_bsdf.inputs["Alpha"].default_value = 0.34
glass.surface_render_method = "DITHERED"


def root(name):
    obj = bpy.data.objects.new(name, None)
    collection.objects.link(obj)
    obj.location = (0.0, COLLECTION_Y, 0.0)
    obj.empty_display_type = "CUBE"
    obj.empty_display_size = 0.12
    obj["school_prop_prototype"] = True
    return obj


def part(parent, name, location, dimensions, mat, bevel=0.025, segments=3):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for users_collection in list(obj.users_collection):
        users_collection.objects.unlink(obj)
    collection.objects.link(obj)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.location = location
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Soft formed edges", "BEVEL")
        mod.width = bevel
        mod.segments = segments
        mod.profile = 0.5
        obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def cylinder(parent, name, location, radius, depth, mat, vertices=16, bevel=0.012):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    for users_collection in list(obj.users_collection):
        users_collection.objects.unlink(obj)
    collection.objects.link(obj)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.location = location
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    if bevel:
        mod = obj.modifiers.new("Rounded rim", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def sphere(parent, name, location, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    for users_collection in list(obj.users_collection):
        users_collection.objects.unlink(obj)
    collection.objects.link(obj)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.location = location
    obj.scale = scale
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


# Reception seating: upholstered cushions, inset seams, tapered-looking feet,
# and a school-blue accent strip echo the enamel and hardware on the lockers.
sofa = root("Prop_LobbySofa")
part(sofa, "Sofa - shadowed plinth", (0, 0, 0.09), (1.52, 0.68, 0.18), dark_teal, 0.055)
for x in (-0.64, 0.64):
    for y in (-0.25, 0.25):
        cylinder(sofa, "Sofa - brass foot", (x, y, 0.04), 0.045, 0.08, warm, 12, 0.008)
part(sofa, "Sofa - rounded seat cushion", (0, -0.015, 0.33), (1.53, 0.70, 0.38), navy, 0.13, 5)
part(sofa, "Sofa - back cushion", (0, 0.27, 0.65), (1.48, 0.22, 0.60), navy, 0.105, 5)
part(sofa, "Sofa - blue back piping", (0, 0.15, 0.68), (1.40, 0.025, 0.035), teal, 0.015, 3)
for x in (-0.76, 0.76):
    part(sofa, "Sofa - padded arm", (x, 0, 0.47), (0.21, 0.79, 0.48), teal, 0.09, 4)
for x in (-0.34, 0.34):
    part(sofa, "Sofa - tailored seat seam", (x, -0.015, 0.526), (0.018, 0.48, 0.008), dark_teal, 0.004, 2)
part(sofa, "Sofa - gold accent cushion", (0, -0.105, 0.58), (0.38, 0.32, 0.14), warm, 0.07, 4)


# Lobby trophy cabinet: a detailed wood-and-brass plinth, tinted glass panels,
# shelves, and small dimensional cups. Glass stays visual-only in Godot.
case = root("Prop_LobbyTrophyCase")
part(case, "Case - base plinth", (0, 0, 0.10), (2.0, 0.62, 0.20), wood, 0.035)
part(case, "Case - brass base reveal", (0, -0.006, 0.205), (1.96, 0.625, 0.035), warm, 0.012)
part(case, "Case - lower cabinet", (0, 0, 0.40), (1.88, 0.54, 0.38), wood_light, 0.025)
part(case, "Case - upper canopy", (0, 0, 1.57), (2.0, 0.64, 0.14), wood, 0.04)
part(case, "Case - canopy trim", (0, -0.012, 1.49), (1.94, 0.65, 0.035), warm, 0.012)
for x in (-0.94, 0.94):
    part(case, "Case - vertical walnut stile", (x, 0, 0.99), (0.11, 0.60, 1.12), wood, 0.024)
    part(case, "Case - inner brass stile", (x * 0.91, -0.012, 0.99), (0.018, 0.02, 1.02), warm, 0.008)
for z in (0.49, 0.98, 1.43):
    part(case, "Case - framed shelf", (0, 0, z), (1.76, 0.51, 0.055), wood_light, 0.012)
part(case, "Case - back panel", (0, 0.245, 0.98), (1.75, 0.045, 1.00), dark_teal, 0.018)
part(case, "Case - blue glass front", (0, -0.27, 0.99), (1.72, 0.022, 0.94), glass, 0.012)
for x in (-0.43, 0.0, 0.43):
    part(case, "Case - glass door seam", (x, -0.289, 0.99), (0.012, 0.018, 0.91), warm, 0.005)
    cylinder(case, "Case - brass pull", (x + 0.055, -0.303, 0.99), 0.018, 0.028, warm, 12, 0.004)
for shelf_z in (0.69, 1.17):
    for index, x in enumerate((-0.66, -0.22, 0.22, 0.66)):
        cylinder(case, "Trophy - cup", (x, -0.06, shelf_z + 0.105), 0.065, 0.12, warm, 16, 0.01)
        cylinder(case, "Trophy - stem", (x, -0.06, shelf_z + 0.035), 0.022, 0.08, steel, 12, 0.006)
        part(case, "Trophy - base", (x, -0.06, shelf_z - 0.014), (0.13, 0.10, 0.035), warm, 0.012)


# Faceted but softly shaded planters, with a glazed ceramic pot, brass rim,
# dark soil and layered stylized leaf clusters.
planter = root("Prop_LobbyPlanter")
cylinder(planter, "Planter - tapered ceramic body", (0, 0, 0.23), 0.25, 0.43, teal, 16, 0.025)
cylinder(planter, "Planter - rolled brass rim", (0, 0, 0.45), 0.27, 0.055, warm, 16, 0.012)
cylinder(planter, "Planter - dark soil", (0, 0, 0.475), 0.225, 0.018, wood, 16, 0.003)
for i, (x, y, height, sx, sy, mat) in enumerate((
    (0, 0, 0.76, 0.12, 0.105, leaf),
    (-0.12, 0.02, 0.70, 0.12, 0.09, leaf_light),
    (0.12, -0.02, 0.72, 0.12, 0.09, leaf),
    (-0.05, -0.12, 0.80, 0.10, 0.11, leaf_light),
    (0.07, 0.12, 0.83, 0.10, 0.10, leaf),
    (0.0, 0.02, 0.96, 0.085, 0.08, leaf_light),
)):
    leaf_obj = sphere(planter, "Planter - sculpted foliage %02d" % i, (x, y, height), (sx, sy, 0.22), mat)
    leaf_obj.rotation_euler[1] = (-0.35 + (i % 3) * 0.35)
    leaf_obj.rotation_euler[0] = (i - 2) * 0.12


# Hall recycling bin: rounded, slightly tapered body, thick lid, separate
# opening, raised badge and metal foot ring. The silhouette reads at a glance.
bin = root("Prop_HallwayRecyclingBin")
cylinder(bin, "Bin - brushed steel foot ring", (0, 0, 0.045), 0.19, 0.07, steel, 16, 0.012)
cylinder(bin, "Bin - teal enamel body", (0, 0, 0.39), 0.175, 0.66, teal, 16, 0.025)
cylinder(bin, "Bin - dark inset lid", (0, 0, 0.74), 0.19, 0.075, dark_teal, 16, 0.018)
cylinder(bin, "Bin - lid highlight rim", (0, 0, 0.785), 0.185, 0.025, warm, 16, 0.008)
part(bin, "Bin - rounded opening", (0, -0.14, 0.71), (0.17, 0.025, 0.055), wood, 0.026, 5)
part(bin, "Bin - porcelain recycle badge", (0, -0.181, 0.47), (0.20, 0.025, 0.20), cream, 0.05, 5)
for angle in (0.0, 2.094, 4.188):
    x, z = 0.055 * __import__("math").cos(angle), 0.47 + 0.055 * __import__("math").sin(angle)
    mark = part(bin, "Bin - recycle mark", (x, -0.198, z), (0.018, 0.012, 0.09), teal, 0.007, 2)
    mark.rotation_euler[1] = angle


for obj in collection.objects:
    obj.hide_render = True
    obj["asset_prototype"] = True

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Built Blender prop prototypes in", COLLECTION_NAME)
