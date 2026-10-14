"""Add decorative, visual-only framed school artwork to assets.blend.

Run: blender --background assets.blend --python add_school_wall_art.py
"""
from pathlib import Path
import bpy

ROOT = Path(bpy.data.filepath).parent
ART_DIR = ROOT / "assets" / "wall_art"
COLLECTION_NAME = "School - Wall Art"

# Centers are on clear interior wall stretches, outside door and window openings.
# Each tuple is (name, image, orientation, center_x, center_y, z, wall_plane).
# orientation "x" means the picture spans X on a wall parallel to X; "y" spans Y.
PLACEMENTS = [
    ("Hallway - Solar System", "poster_solar_system.png", "x", 5.2, -6.00, 2.45, "y"),
    # These wall centers use the inside face of the lobby and perimeter wall.
    ("Hallway - Reading", "poster_storybook.png", "y", 9.86, -24.4, 2.45, "x"),
    ("Hallway - Nature", "poster_oak.png", "x", 26.0, -30.32, 2.45, "y"),
    ("Hallway - Art", "poster_art_room.png", "y", -4.82, -14.0, 2.45, "x"),
    ("Classroom A - Solar System", "poster_solar_system.png", "x", 28.8, 0.93, 2.5, "y"),
    ("Classroom B - Nature", "poster_oak.png", "x", 34.5, 0.68, 2.5, "y"),
    ("Library - Reading", "poster_storybook.png", "y", 21.18, 1.0, 2.5, "x"),
    ("Lab - Solar System", "poster_solar_system.png", "x", 31.5, -9.52, 2.5, "y"),
    ("Science Classroom - Nature", "poster_oak.png", "x", 27.1, -20.20, 2.5, "y"),
    ("Science Classroom - Solar System", "poster_solar_system.png", "x", 36.8, -20.20, 2.5, "y"),
    ("Classroom C - Art", "poster_art_room.png", "x", 14.2, -23.21, 2.5, "y"),
    ("Classroom D - Reading", "poster_storybook.png", "x", 22.8, -24.00, 2.5, "y"),
    ("Classroom E - Nature", "poster_oak.png", "x", 28.0, -27.00, 2.5, "y"),
    ("Classroom E - Art", "poster_art_room.png", "x", 38.0, -27.00, 2.5, "y"),
]


def material(name, color, roughness=0.75):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def box_mesh(name, bounds):
    x0, x1, y0, y1, z0, z1 = bounds
    verts = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
             (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    faces = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    mesh = bpy.data.meshes.new(name + " Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    return mesh


def main():
    collection = bpy.data.collections.get(COLLECTION_NAME)
    if collection is None:
        collection = bpy.data.collections.new(COLLECTION_NAME)
        bpy.context.scene.collection.children.link(collection)
    # Reruns replace only this decorative collection.
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    trim = material("School Art - Blue Gray Frame", (0.13, 0.22, 0.27), 0.48)
    matboard = material("School Art - Warm Mat", (0.92, 0.88, 0.76), 0.8)
    made = 0
    for name, filename, orient, cx, cy, cz, wall_axis in PLACEMENTS:
        image_path = ART_DIR / filename
        image = bpy.data.images.load(str(image_path), check_existing=True)
        image.pack()
        artmat = bpy.data.materials.get("School Art Image - " + filename) or bpy.data.materials.new("School Art Image - " + filename)
        artmat.use_nodes = True
        nt = artmat.node_tree
        nt.nodes.clear()
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Linear"
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        artmat.use_backface_culling = False

        # Portrait frame dimensions and slim, raised rails.
        width, height, rail = 0.68, 0.92, 0.045
        cx0, cx1 = cx-width/2, cx+width/2
        z0, z1 = cz-height/2, cz+height/2
        if wall_axis == "y":
            # Front face points toward either side; geometry is double-sided.
            py = cy + 0.018
            thickness = 0.035
            bounds = (cx0, cx1, py-thickness/2, py+thickness/2, z0, z1)
            plane_center = (cx, py + thickness/2 + 0.003, cz)
            plane_verts = [(cx0+rail,plane_center[1],z0+rail),(cx1-rail,plane_center[1],z0+rail),
                           (cx1-rail,plane_center[1],z1-rail),(cx0+rail,plane_center[1],z1-rail)]
            uv = [(0,0),(1,0),(1,1),(0,1)]
            trim_boxes = [(cx0, cx0+rail, py-thickness/2, py+thickness/2, z0, z1),
                          (cx1-rail, cx1, py-thickness/2, py+thickness/2, z0, z1),
                          (cx0+rail, cx1-rail, py-thickness/2, py+thickness/2, z0, z0+rail),
                          (cx0+rail, cx1-rail, py-thickness/2, py+thickness/2, z1-rail, z1)]
        else:
            px = cx + (0.018 if cx < 20 else -0.018)
            thickness = 0.035
            bounds = (px-thickness/2, px+thickness/2, cy-width/2, cy+width/2, z0, z1)
            plane_center = (px + thickness/2 + 0.003, cy, cz)
            plane_verts = [(plane_center[0],cy-width/2+rail,z0+rail),(plane_center[0],cy+width/2-rail,z0+rail),
                           (plane_center[0],cy+width/2-rail,z1-rail),(plane_center[0],cy-width/2+rail,z1-rail)]
            uv = [(0,0),(1,0),(1,1),(0,1)]
            trim_boxes = [(px-thickness/2, px+thickness/2, cy-width/2, cy-width/2+rail, z0, z1),
                          (px-thickness/2, px+thickness/2, cy+width/2-rail, cy+width/2, z0, z1),
                          (px-thickness/2, px+thickness/2, cy-width/2+rail, cy+width/2-rail, z0, z0+rail),
                          (px-thickness/2, px+thickness/2, cy-width/2+rail, cy+width/2-rail, z1-rail, z1)]
        frame_obj = bpy.data.objects.new(name + " - Frame", box_mesh(name + " Frame", bounds))
        collection.objects.link(frame_obj)
        frame_obj.data.materials.append(trim)
        frame_obj["preview_collision_disabled"] = True
        image_mesh = bpy.data.meshes.new(name + " Print Mesh")
        image_mesh.from_pydata(plane_verts, [], [(0,1,2,3)])
        image_mesh.materials.append(artmat)
        uv_layer = image_mesh.uv_layers.new(name="Poster UV")
        for loop in image_mesh.loops:
            uv_layer.data[loop.index].uv = uv[loop.vertex_index]
        image_mesh.update()
        image_obj = bpy.data.objects.new(name + " - Print", image_mesh)
        collection.objects.link(image_obj)
        image_obj["preview_collision_disabled"] = True
        made += 1

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("Added", made, "visual-only school wall art pieces")


main()
