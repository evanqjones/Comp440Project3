"""Remove the outside poster and add one framed print in each classroom A-E.

This is deliberately incremental: it preserves all existing user placements.
Run with Blender: blender --background assets.blend --python adjust_classroom_wall_art.py
"""
from pathlib import Path
import bpy

ROOT = Path(bpy.data.filepath).parent
ART_DIR = ROOT / "assets" / "wall_art"
COLLECTION = bpy.data.collections.get("School - Wall Art")

# (object name, image, center x, wall's inside face y, side into room)
# Prints avoid the existing doors and windows and do not add anything to the lobby.
CLASSROOMS = [
    ("Classroom A - Oak Print", "poster_oak.png", 33.35, 5.50, -1),
    ("Classroom B - Solar System Print", "poster_solar_system.png", 34.30, 5.68, -1),
    ("Classroom C - Solar System Print", "poster_solar_system.png", 14.55, -16.79, -1),
    ("Classroom D - Art Print", "poster_art_room.png", 18.45, -16.79, -1),
    ("Classroom E - Storybook Print", "poster_storybook.png", 32.40, -26.18, 1),
]


def get_trim_material():
    mat = bpy.data.materials.get("School Art - Blue Gray Frame")
    if mat is None:
        mat = bpy.data.materials.new("School Art - Blue Gray Frame")
        mat.diffuse_color = (0.13, 0.22, 0.27, 1)
        mat.use_nodes = True
        mat.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (0.13, 0.22, 0.27, 1)
    return mat


def image_material(filename):
    name = "School Art Image - " + filename
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(str(ART_DIR / filename), check_existing=True)
    tex.image.pack()
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.use_backface_culling = False
    return mat


def make_frame_mesh(name, bounds):
    x0, x1, y0, y1, z0, z1 = bounds
    verts = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
             (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    mesh = bpy.data.meshes.new(name + " Mesh")
    mesh.from_pydata(verts, [], [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    mesh.materials.append(get_trim_material())
    mesh.update()
    return mesh


def add_poster(name, filename, cx, wall_y, side):
    width, height, rail, thick = 0.68, 0.92, 0.045, 0.035
    x0, x1 = cx - width / 2, cx + width / 2
    z0, z1 = 2.04, 2.96
    y0, y1 = (wall_y, wall_y + thick) if side > 0 else (wall_y - thick, wall_y)
    frame = bpy.data.objects.new(name + " - Frame", make_frame_mesh(name + " Frame", (x0,x1,y0,y1,z0,z1)))
    COLLECTION.objects.link(frame)
    frame["preview_collision_disabled"] = True

    face_y = wall_y + side * (thick + 0.003)
    verts = [(x0+rail,face_y,z0+rail),(x1-rail,face_y,z0+rail),
             (x1-rail,face_y,z1-rail),(x0+rail,face_y,z1-rail)]
    mesh = bpy.data.meshes.new(name + " Mesh")
    mesh.from_pydata(verts, [], [(0,1,2,3)])
    mesh.materials.append(image_material(filename))
    uv = mesh.uv_layers.new(name="Poster UV")
    for loop in mesh.loops:
        uv.data[loop.index].uv = [(0,0),(1,0),(1,1),(0,1)][loop.vertex_index]
    mesh.update()
    art = bpy.data.objects.new(name, mesh)
    COLLECTION.objects.link(art)
    art["preview_collision_disabled"] = True


def main():
    if COLLECTION is None:
        raise RuntimeError("School - Wall Art collection not found")
    # Remove only the exterior hallway poster pair. Leave all other placements as edited.
    for obj in list(COLLECTION.objects):
        if obj.name.startswith("Hallway - Art - "):
            bpy.data.objects.remove(obj, do_unlink=True)
    for name, filename, cx, wall_y, side in CLASSROOMS:
        for obj in list(COLLECTION.objects):
            if obj.name == name or obj.name == name + " - Frame":
                bpy.data.objects.remove(obj, do_unlink=True)
        add_poster(name, filename, cx, wall_y, side)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("Removed outside poster; added five classroom prints; preserved all other placements")


main()
