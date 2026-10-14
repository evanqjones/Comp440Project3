"""Add a restrained school finish to the existing editable Blender school.

Run with Blender 5.2:
    blender --background assets.blend --python style_school_surfaces.py

The script preserves existing room, wall, floor, furniture, and lighting
geometry. It adds image-based surface materials and decorative trim only.
"""

from array import array
import bpy
import math
import random
from mathutils import Vector


SCHOOL_COLLECTION = "After School - School Blockout"
STYLE_COLLECTION = "School - Architectural Finish"
DOOR_COLLECTION = "School - Door Frames"
WINDOW_COLLECTION = "School - Window Frames"
WAINSCOT_TOP = 1.12
DOOR_HEIGHT = 2.15
FRAME = 0.075


def make_plaster_image(name, base, width=512, height=512):
    image = bpy.data.images.get(name)
    if image is None or image.size[:] != (width, height):
        if image is not None:
            bpy.data.images.remove(image)
        image = bpy.data.images.new(name, width=width, height=height, alpha=False)
    pixels = array("f")
    for y in range(height):
        v = y / height
        for x in range(width):
            u = x / width
            broad = math.sin(2 * math.pi * (3 * u + 2 * v)) * 0.012
            mid = math.sin(2 * math.pi * (13 * u - 9 * v)) * 0.005
            grain = math.sin(2 * math.pi * (67 * u + 53 * v)) * 0.002
            value = broad + mid + grain
            pixels.extend((max(0.0, min(1.0, base[0] + value)),
                           max(0.0, min(1.0, base[1] + value)),
                           max(0.0, min(1.0, base[2] + value)), 1.0))
    image.pixels.foreach_set(pixels)
    image.pack()
    return image


def make_tile_image(name, base, grout=(0.28, 0.30, 0.30), size=256, tile_size=128):
    image = bpy.data.images.get(name)
    if image is None or image.size[:] != (size, size):
        if image is not None:
            bpy.data.images.remove(image)
        image = bpy.data.images.new(name, width=size, height=size, alpha=False)
    pixels = array("f")
    rng = random.Random(name)
    tile_colors = []
    for _ in range((size // tile_size) ** 2):
        shift = rng.uniform(-0.018, 0.018)
        tile_colors.append(tuple(max(0.0, min(1.0, c + shift)) for c in base))
    for y in range(size):
        tile_y, local_y = divmod(y, tile_size)
        for x in range(size):
            tile_x, local_x = divmod(x, tile_size)
            edge = min(local_x, local_y, tile_size - 1 - local_x, tile_size - 1 - local_y)
            idx = tile_y * (size // tile_size) + tile_x
            if edge < 3:
                color = grout
            else:
                tile = tile_colors[idx]
                # Fine mineral flecks sit inside the tile and keep the pattern
                # periodic at the grout seams.
                grain = (rng.random() - 0.5) * 0.022
                vein = math.sin(local_x * 0.11 + local_y * 0.06) * 0.006
                color = tuple(max(0.0, min(1.0, c + grain + vein)) for c in tile)
            pixels.extend((color[0], color[1], color[2], 1.0))
    image.pixels.foreach_set(pixels)
    image.pack()
    return image


def make_ceiling_image(name, base, size=256, panel_size=128):
    image = bpy.data.images.get(name)
    if image is None or image.size[:] != (size, size):
        if image is not None:
            bpy.data.images.remove(image)
        image = bpy.data.images.new(name, width=size, height=size, alpha=False)
    pixels = array("f")
    for y in range(size):
        for x in range(size):
            edge = min(x % panel_size, y % panel_size, panel_size - 1 - x % panel_size,
                       panel_size - 1 - y % panel_size)
            v = math.sin(2 * math.pi * (x / panel_size * 2 + y / panel_size)) * 0.006
            if edge < 2:
                c = tuple(max(0.0, x - 0.08) for x in base)
            else:
                c = tuple(max(0.0, min(1.0, x + v)) for x in base)
            pixels.extend((c[0], c[1], c[2], 1.0))
    image.pixels.foreach_set(pixels)
    image.pack()
    return image


def textured_material(name, image, color, roughness=0.78):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    shader = nodes.get("Principled BSDF")
    if shader is None:
        shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Roughness"].default_value = roughness
    tex = nodes.get("School Surface Image")
    if tex is None:
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = "School Surface Image"
    tex.image = image
    tex.extension = "REPEAT"
    tex.interpolation = "Linear"
    links = material.node_tree.links
    for link in list(links):
        if link.to_node == shader and link.to_socket == shader.inputs["Base Color"]:
            links.remove(link)
    links.new(tex.outputs["Color"], shader.inputs["Base Color"])
    return material


def solid_material(name, color, roughness=0.55, metallic=0.0):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    if shader:
        shader.inputs["Base Color"].default_value = (*color, 1.0)
        shader.inputs["Roughness"].default_value = roughness
        shader.inputs["Metallic"].default_value = metallic
    return material


def append_material(obj, material):
    if material.name in [m.name for m in obj.data.materials if m]:
        return obj.data.materials.find(material.name)
    obj.data.materials.append(material)
    return len(obj.data.materials) - 1


def ensure_uv(obj, kind):
    mesh = obj.data
    if mesh.users > 1:
        obj.data = mesh.copy()
        mesh = obj.data
    uv_layer = mesh.uv_layers.get("School Finish UV") or mesh.uv_layers.new(name="School Finish UV")
    uv_layer.active = True
    uv_data = uv_layer.data
    for poly in mesh.polygons:
        normal = obj.matrix_world.to_3x3() @ poly.normal
        for loop_index in poly.loop_indices:
            p = obj.matrix_world @ mesh.vertices[mesh.loops[loop_index].vertex_index].co
            if kind == "floor" or kind == "ceiling" or abs(normal.z) > 0.65:
                uv_data[loop_index].uv = (p.x / 0.6, p.y / 0.6)
            elif abs(normal.x) > abs(normal.y):
                if kind == "wainscot":
                    uv_data[loop_index].uv = (p.y / 0.45, p.z / 0.45)
                else:
                    uv_data[loop_index].uv = (p.y / 2.5, p.z / 1.0)
            else:
                if kind == "wainscot":
                    uv_data[loop_index].uv = (p.x / 0.45, p.z / 0.45)
                else:
                    uv_data[loop_index].uv = (p.x / 2.5, p.z / 1.0)


def world_bounds(obj):
    points = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    return tuple((min(p[i] for p in points), max(p[i] for p in points)) for i in range(3))


def add_box(verts, faces, x0, x1, y0, y1, z0, z1):
    base = len(verts)
    verts.extend(((x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
                  (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)))
    faces.extend(tuple(base + i for i in face) for face in (
        (0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)))


def make_trim_object(name, boxes, collection, material):
    verts, faces = [], []
    for box in boxes:
        add_box(verts, faces, *box)
    if not faces:
        return None
    mesh = bpy.data.meshes.new(name + " Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj["preview_collision_disabled"] = True
    obj["architectural_finish_only"] = True
    return obj


def frame_door(header, collection, material, seen):
    (xmin,xmax),(ymin,ymax),(zmin,zmax) = world_bounds(header)
    dx, dy = xmax - xmin, ymax - ymin
    if dx >= dy:
        axis, width = "x", dx
        center = (xmin + xmax) * 0.5
        depth_center = (ymin + ymax) * 0.5
        depth = max(dy, 0.18) + 0.045
        key = ("x", round(center,2), round(depth_center / 0.5), round(width,2))
        if any(k[0] == key[0] and abs(k[1]-key[1]) < 0.03 and k[2] == key[2]
               and abs(k[3]-key[3]) < 0.03 for k in seen):
            return False
        seen.add(key)
        x0, x1 = xmin, xmax
        y0, y1 = depth_center - depth/2, depth_center + depth/2
        z0 = min((world_bounds(o)[2][0] for o in bpy.data.objects
                  if o.type == "MESH" and "Floor" in o.name), default=0.138)
        z0 = max(z0, 0.12)
        z1 = min(DOOR_HEIGHT, zmin + 0.02)
        boxes = [(x0, x0+FRAME, y0, y1, z0, z1),
                 (x1-FRAME, x1, y0, y1, z0, z1),
                 (x0+FRAME, x1-FRAME, y0, y1, z1-FRAME, z1)]
    else:
        axis, width = "y", dy
        center = (ymin + ymax) * 0.5
        depth_center = (xmin + xmax) * 0.5
        depth = max(dx, 0.18) + 0.045
        key = ("y", round(center,2), round(depth_center / 0.5), round(width,2))
        if any(k[0] == key[0] and abs(k[1]-key[1]) < 0.03 and k[2] == key[2]
               and abs(k[3]-key[3]) < 0.03 for k in seen):
            return False
        seen.add(key)
        x0, x1 = depth_center - depth/2, depth_center + depth/2
        y0, y1 = ymin, ymax
        z0 = min((world_bounds(o)[2][0] for o in bpy.data.objects
                  if o.type == "MESH" and "Floor" in o.name), default=0.138)
        z0 = max(z0, 0.12)
        z1 = min(DOOR_HEIGHT, zmin + 0.02)
        boxes = [(x0, x1, y0, y0+FRAME, z0, z1),
                 (x0, x1, y1-FRAME, y1, z0, z1),
                 (x0, x1, y0+FRAME, y1-FRAME, z1-FRAME, z1)]
    make_trim_object("Door Frame - " + header.name.removeprefix("Door Header Wall Infill - "),
                      boxes, collection, material)
    return True


def frame_window(glass, collection, material):
    (xmin,xmax),(ymin,ymax),(zmin,zmax) = world_bounds(glass)
    dx, dy = xmax - xmin, ymax - ymin
    depth = max(dx, dy)
    if dx >= dy:
        width, plane, xmid = dx, (ymin+ymax)*0.5, (xmin+xmax)*0.5
        frame_depth = max(dy + 0.055, 0.09)
        x0, x1 = xmin - 0.04, xmax + 0.04
        y0, y1 = plane - frame_depth/2, plane + frame_depth/2
        boxes = [(x0, x0+FRAME, y0, y1, zmin-0.04, zmax+0.04),
                 (x1-FRAME, x1, y0, y1, zmin-0.04, zmax+0.04),
                 (x0+FRAME, x1-FRAME, y0, y1, zmax-FRAME, zmax+0.04),
                 (x0+FRAME, x1-FRAME, y0-0.04, y1+0.04, zmin-0.08, zmin)]
        divisions = max(1, round(width / 1.55))
        for index in range(1, divisions):
            x = xmin + width * index / divisions
            boxes.append((x-FRAME/2, x+FRAME/2, y0, y1, zmin, zmax))
    else:
        width, plane, ymid = dy, (xmin+xmax)*0.5, (ymin+ymax)*0.5
        frame_depth = max(dx + 0.055, 0.09)
        x0, x1 = plane - frame_depth/2, plane + frame_depth/2
        y0, y1 = ymin - 0.04, ymax + 0.04
        boxes = [(x0, x1, y0, y0+FRAME, zmin-0.04, zmax+0.04),
                 (x0, x1, y1-FRAME, y1, zmin-0.04, zmax+0.04),
                 (x0, x1, y0+FRAME, y1-FRAME, zmax-FRAME, zmax+0.04),
                 (x0-0.04, x1+0.04, y0+FRAME, y1-FRAME, zmin-0.08, zmin)]
        divisions = max(1, round(width / 1.55))
        for index in range(1, divisions):
            y = ymin + width * index / divisions
            boxes.append((x0, x1, y-FRAME/2, y+FRAME/2, zmin, zmax))
    make_trim_object("Window Frame - " + glass.name.removeprefix("Window Glass - "),
                      boxes, collection, material)


def main():
    school = bpy.data.collections.get(SCHOOL_COLLECTION)
    if school is None:
        raise RuntimeError("School blockout collection is missing")

    old = bpy.data.collections.get(STYLE_COLLECTION)
    if old:
        for obj in list(old.all_objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        for child in list(old.children):
            old.children.unlink(child)
            bpy.data.collections.remove(child)
        for parent in bpy.data.collections:
            if old.name in parent.children:
                parent.children.unlink(old)
        for scene in bpy.data.scenes:
            if old.name in scene.collection.children:
                scene.collection.children.unlink(old)
        bpy.data.collections.remove(old)
    style = bpy.data.collections.new(STYLE_COLLECTION)
    school.children.link(style)
    doors = bpy.data.collections.new(DOOR_COLLECTION)
    windows = bpy.data.collections.new(WINDOW_COLLECTION)
    style.children.link(doors)
    style.children.link(windows)

    images = {
        "plaster": make_plaster_image("School Texture - Warm Plaster", (0.72,0.71,0.67)),
        "wainscot": make_tile_image("School Texture - Blue Gray Wall Tile", (0.30,0.36,0.39), (0.19,0.24,0.26)),
        "slate": make_tile_image("School Texture - Slate Terrazzo", (0.36,0.39,0.41), (0.20,0.23,0.24)),
        "slate_alt": make_tile_image("School Texture - Pale Slate Tile", (0.40,0.42,0.42), (0.24,0.26,0.26)),
        "cafe": make_tile_image("School Texture - Cafe Ceramic Tile", (0.49,0.44,0.36), (0.27,0.25,0.22)),
        "kitchen": make_tile_image("School Texture - Kitchen Ceramic Tile", (0.58,0.54,0.45), (0.33,0.31,0.27)),
        "lobby": make_tile_image("School Texture - Lobby Terrazzo", (0.43,0.44,0.42), (0.24,0.25,0.24)),
        "concrete": make_tile_image("School Texture - Corridor Concrete", (0.27,0.30,0.33), (0.19,0.21,0.23)),
        "ceiling": make_ceiling_image("School Texture - Acoustic Ceiling", (0.72,0.73,0.71)),
    }
    mats = {
        "plaster": textured_material("Walls - Warm School Plaster", images["plaster"], (0.72,0.71,0.67)),
        "wainscot": textured_material("Walls - Blue Gray Ceramic Wainscot", images["wainscot"], (0.30,0.36,0.39)),
        "slate": textured_material("Room floor - slate", images["slate"], (0.36,0.39,0.41)),
        "slate_alt": textured_material("Room floor - alternate slate", images["slate_alt"], (0.40,0.42,0.42)),
        "cafe": textured_material("Cafe floor - muted tile", images["cafe"], (0.49,0.44,0.36)),
        "kitchen": textured_material("Kitchen floor - tile", images["kitchen"], (0.58,0.54,0.45)),
        "lobby": textured_material("Lobby floor - worn tile", images["lobby"], (0.43,0.44,0.42)),
        "concrete": textured_material("Corridor - cool concrete", images["concrete"], (0.27,0.30,0.33)),
        "ceiling": textured_material("Ceilings - warm light gray", images["ceiling"], (0.72,0.73,0.71)),
    }
    frame_mat = solid_material("School Trim - Painted Blue Gray", (0.19,0.27,0.31), 0.55)

    # Retain the existing object geometry and assign image textures through
    # world-aligned UVs so room-to-room seams remain visually consistent.
    material_map = {
        "room floor - slate": mats["slate"],
        "room floor - alternate slate": mats["slate_alt"],
        "cafe floor - muted tile": mats["cafe"],
        "kitchen floor - tile": mats["kitchen"],
        "lobby floor - worn tile": mats["lobby"],
        "corridor - cool concrete": mats["concrete"],
        "ceilings - warm light gray": mats["ceiling"],
    }
    surface_count = 0
    for obj in school.all_objects:
        if obj.type != "MESH" or not obj.data.polygons:
            continue
        lower_name = obj.name.lower()
        if "window glass" in lower_name or "door swing" in lower_name:
            continue
        if "wall" in lower_name:
            plaster_index = append_material(obj, mats["plaster"])
            tile_index = append_material(obj, mats["wainscot"])
            ensure_uv(obj, "wall")
            for poly in obj.data.polygons:
                world_center = obj.matrix_world @ poly.center
                normal = obj.matrix_world.to_3x3() @ poly.normal
                poly.material_index = tile_index if abs(normal.z) < 0.65 and world_center.z <= WAINSCOT_TOP else plaster_index
            surface_count += 1
        else:
            chosen = None
            for old_name, material in material_map.items():
                if any(slot and slot.name.lower().startswith(old_name) for slot in obj.data.materials):
                    chosen = material
                    break
            if chosen:
                index = append_material(obj, chosen)
                ensure_uv(obj, "ceiling" if "roof" in lower_name or "ceiling" in lower_name else "floor")
                for poly in obj.data.polygons:
                    if poly.normal.z > 0.5:
                        poly.material_index = index
                surface_count += 1

    seen_doors = set()
    door_count = 0
    for header in [o for o in school.all_objects if o.type == "MESH" and o.name.startswith("Door Header Wall Infill")]:
        if frame_door(header, doors, frame_mat, seen_doors):
            door_count += 1
    window_count = 0
    for glass in [o for o in school.all_objects if o.type == "MESH" and o.name.startswith("Window Glass -")]:
        frame_window(glass, windows, frame_mat)
        window_count += 1

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("School finish applied:", surface_count, "surface objects,",
          door_count, "door frames,", window_count, "window frames")


main()
