import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSET_DIR = os.path.join(ROOT, "assets")
BLEND_PATH = os.path.join(ROOT, "Pickup_Items.blend")


def material(name, color, metallic=0.0, roughness=0.45):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


M = {
    "gold": material("Warm brass", (0.82, 0.48, 0.08), 0.72, 0.24),
    "steel": material("Brushed steel", (0.45, 0.52, 0.57), 0.78, 0.28),
    "blue": material("School blue enamel", (0.035, 0.18, 0.48), 0.18, 0.32),
    "red": material("Paint red", (0.78, 0.035, 0.025), 0.05, 0.28),
    "green": material("Book green", (0.035, 0.32, 0.17), 0.05, 0.42),
    "paper": material("Warm paper", (0.9, 0.81, 0.57), 0.0, 0.72),
    "white": material("Cotton white", (0.88, 0.9, 0.88), 0.0, 0.68),
    "dark": material("Rubber black", (0.035, 0.045, 0.055), 0.0, 0.58),
    "orange": material("Snack orange", (0.95, 0.28, 0.035), 0.0, 0.38),
    "yellow": material("Ruler yellow", (0.96, 0.69, 0.12), 0.0, 0.4),
    "pink": material("Strawberry jam", (0.73, 0.035, 0.12), 0.0, 0.35),
}


def put_in_collection(obj, coll):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    coll.objects.link(obj)
    return obj


def finish(obj, name, mat, coll, bevel=0.0):
    obj.name = name
    put_in_collection(obj, coll)
    if mat:
        obj.data.materials.append(mat)
    if bevel and obj.type == "MESH":
        mod = obj.modifiers.new("Soft manufactured edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def cube(name, loc, dims, mat, coll, bevel=0.025):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, coll, bevel)


def cylinder(name, loc, radius, depth, mat, coll, rotation=(0, 0, 0), vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    return finish(bpy.context.object, name, mat, coll, 0.008)


def sphere(name, loc, scale, mat, coll):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for face in obj.data.polygons:
        face.use_smooth = True
    return finish(obj, name, mat, coll)


def torus(name, loc, major, minor, mat, coll, rotation=(math.pi / 2, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=32, minor_segments=8, location=loc, rotation=rotation)
    return finish(bpy.context.object, name, mat, coll)


def build_school_keys(c):
    torus("School key ring", (0, 0, 0), 0.19, 0.035, M["gold"], c)
    for y in (-0.11, 0.11):
        cylinder("Key shaft", (0.22, y, 0), 0.035, 0.44, M["gold"], c, (0, math.pi / 2, 0))
        cylinder("Round key bow", (0.46, y, 0), 0.07, 0.045, M["gold"], c, (0, math.pi / 2, 0))
        cube("Key tooth", (0.3, y, -0.055), (0.11, 0.06, 0.08), M["gold"], c, 0.012)


def build_weight(c):
    cylinder("Dumbbell grip", (0, 0, 0), 0.065, 0.68, M["steel"], c, (0, math.pi / 2, 0))
    for x in (-0.35, 0.35):
        for y in (-0.13, 0.13):
            cylinder("Rubber weight plate", (x, y, 0), 0.25, 0.15, M["dark"], c, (0, math.pi / 2, 0), 32)
            cylinder("Blue plate hub", (x + (0.08 if x > 0 else -0.08), y, 0), 0.095, 0.025, M["blue"], c, (0, math.pi / 2, 0))


def build_book(c):
    cube("Book pages", (0, 0, 0), (0.55, 0.16, 0.72), M["paper"], c, 0.025)
    cube("Front cover", (0, -0.105, 0), (0.59, 0.055, 0.76), M["green"], c, 0.035)
    cube("Back cover", (0, 0.105, 0), (0.59, 0.055, 0.76), M["green"], c, 0.035)
    cube("Book spine", (-0.285, 0, 0), (0.07, 0.22, 0.77), M["blue"], c, 0.02)
    cube("Cover title plaque", (0, -0.137, 0.08), (0.3, 0.012, 0.22), M["gold"], c, 0.012)
    cube("Title inset", (0, -0.146, 0.08), (0.24, 0.008, 0.16), M["green"], c, 0.008)


def build_brush(c):
    cylinder("Paintbrush wooden handle", (0, 0, -0.02), 0.055, 0.57, M["orange"], c, vertices=20)
    cylinder("Ferrule", (0, 0, 0.29), 0.075, 0.13, M["gold"], c, vertices=20)
    sphere("Brush bristles", (0, 0, 0.43), (0.09, 0.09, 0.18), M["white"], c)
    sphere("Red paint tip", (0, 0, 0.56), (0.07, 0.07, 0.08), M["red"], c)


def build_lab_coat(c):
    cube("Coat torso", (0, 0, 0), (0.58, 0.18, 0.68), M["white"], c, 0.06)
    cube("Open coat front", (0, -0.101, 0), (0.12, 0.025, 0.65), M["blue"], c, 0.012)
    for side in (-1, 1):
        sleeve = cube("Coat sleeve", (side * 0.39, 0, -0.015), (0.22, 0.17, 0.56), M["white"], c, 0.06)
        sleeve.rotation_euler.y = side * -0.14
        cube("Cuff", (side * 0.4, 0, -0.28), (0.2, 0.18, 0.09), M["blue"], c, 0.025)
    cube("Coat collar left", (-0.1, -0.105, 0.29), (0.18, 0.035, 0.18), M["white"], c, 0.025).rotation_euler.y = -0.5
    cube("Coat collar right", (0.1, -0.105, 0.29), (0.18, 0.035, 0.18), M["white"], c, 0.025).rotation_euler.y = 0.5
    for z in (-0.18, -0.03, 0.12):
        sphere("Coat button", (0.035, -0.125, z), (0.025, 0.012, 0.025), M["gold"], c)


def build_ruler(c):
    cube("Wood ruler", (0, 0, 0), (0.18, 0.055, 0.82), M["yellow"], c, 0.014)
    for i in range(11):
        z = -0.37 + i * 0.074
        width = 0.065 if i % 5 == 0 else 0.04
        cube("Measurement mark", (0.025, -0.031, z), (width, 0.008, 0.012), M["dark"], c, 0.002)


def build_snack(c):
    cube("Cracker sandwich", (0, 0, 0), (0.62, 0.42, 0.2), M["paper"], c, 0.07)
    cube("Cheese layer", (0, -0.005, 0.11), (0.52, 0.34, 0.055), M["yellow"], c, 0.04)
    cube("Jam layer", (0, 0.005, 0.155), (0.45, 0.29, 0.045), M["pink"], c, 0.035)
    cube("Top cracker", (0, 0, 0.21), (0.62, 0.42, 0.12), M["orange"], c, 0.07)
    for x in (-0.19, 0, 0.19):
        for y in (-0.1, 0.1):
            sphere("Cracker dimple", (x, y, 0.275), (0.018, 0.018, 0.009), M["paper"], c)


def build_microphone(c):
    cylinder("Microphone handle", (0, 0, -0.08), 0.09, 0.46, M["dark"], c, vertices=24)
    cylinder("Blue microphone band", (0, 0, 0.12), 0.095, 0.07, M["blue"], c, vertices=24)
    sphere("Metal microphone grille", (0, 0, 0.27), (0.14, 0.14, 0.18), M["steel"], c)
    for z in (0.23, 0.28, 0.33):
        torus("Grille ring", (0, 0, z), 0.12, 0.012, M["dark"], c, (0, 0, 0))


def build_front_key(c):
    torus("Oversized entrance key bow", (-0.24, 0, 0), 0.19, 0.045, M["gold"], c)
    cylinder("Entrance key shaft", (0.13, 0, 0), 0.045, 0.68, M["gold"], c, (0, math.pi / 2, 0))
    cube("Key tooth one", (0.31, 0, -0.085), (0.13, 0.07, 0.13), M["gold"], c, 0.012)
    cube("Key tooth two", (0.22, 0, -0.11), (0.08, 0.07, 0.09), M["gold"], c, 0.01)


MODELS = [
    ("pickup_school_keys", "School Keys", build_school_keys),
    ("pickup_weight", "Weight", build_weight),
    ("pickup_book", "Book", build_book),
    ("pickup_brush", "Paintbrush", build_brush),
    ("pickup_lab_coat", "Lab Coat", build_lab_coat),
    ("pickup_ruler", "Ruler", build_ruler),
    ("pickup_snack", "Snack", build_snack),
    ("pickup_microphone", "Microphone", build_microphone),
    ("pickup_front_door_key", "Front Door Key", build_front_key),
]


def aim(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in list(bpy.data.collections):
        if coll.name != "Collection":
            bpy.data.collections.remove(coll)
    exports = []
    spacing = 2.8
    for index, (filename, label, builder) in enumerate(MODELS):
        coll = bpy.data.collections.new("Pickup | " + label)
        bpy.context.scene.collection.children.link(coll)
        before = set(bpy.data.objects)
        builder(coll)
        objects = list(set(bpy.data.objects) - before)
        offset = index * spacing
        for obj in objects:
            obj.location.x += offset
        exports.append((filename, objects, offset))

    # Arrange the asset library for convenient inspection in Blender.
    bpy.ops.object.camera_add(location=(11.2, -33, 13.5))
    camera = bpy.context.object
    camera.name = "Pickup Asset Overview Camera"
    aim(camera, (11.2, 0, 0))
    bpy.context.scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(11, -8, 12))
    key_light = bpy.context.object
    key_light.name = "Pickup Asset Softbox"
    key_light.data.energy = 2100
    key_light.data.shape = "DISK"
    key_light.data.size = 12
    aim(key_light, (11, 0, 0))
    bpy.ops.object.light_add(type="AREA", location=(2, 5, 7))
    fill = bpy.context.object
    fill.name = "Pickup Asset Fill"
    fill.data.energy = 1200
    fill.data.size = 10
    aim(fill, (11, 0, 0))
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 1600
    bpy.context.scene.render.resolution_y = 700
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.world.color = (0.08, 0.08, 0.08)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)

    for filename, objects, offset in exports:
        for obj in objects:
            obj.location.x -= offset
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        glb_path = os.path.join(ASSET_DIR, filename + ".glb")
        bpy.ops.export_scene.gltf(filepath=glb_path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True, export_cameras=False, export_lights=False)
        for obj in objects:
            obj.location.x += offset


if __name__ == "__main__":
    main()
