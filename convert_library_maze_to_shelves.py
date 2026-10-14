"""Replace the library's low maze panels with two-sided bookcases."""
import bpy
import math
from mathutils import Matrix, Vector

NAMES = [
    "Library Maze Wall 01", "Library Maze Wall 02",
    "Library Maze Wall 03", "Library Maze Wall 03.001",
    "Library Maze Wall 03.002", "Library Maze Wall 04",
    "Library Maze Wall 04.001",
]

def material(name, color, roughness=0.72):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = roughness
    return mat

wood = material("Library Bookshelf - Warm Oak", (0.25, 0.13, 0.065))
backing_mat = material("Library Bookshelf - Dark Backing", (0.16, 0.085, 0.045))
book_mats = [
    material("Library Book Spine - Forest Green", (0.055, 0.18, 0.12)),
    material("Library Book Spine - Navy", (0.045, 0.105, 0.22)),
    material("Library Book Spine - Burgundy", (0.28, 0.055, 0.075)),
    material("Library Book Spine - Ochre", (0.55, 0.31, 0.085)),
    material("Library Book Spine - Teal", (0.045, 0.27, 0.28)),
    material("Library Book Spine - Plum", (0.22, 0.1, 0.25)),
]

def append_box(verts, faces, center, size):
    x, y, z = center
    sx, sy, sz = (d * 0.5 for d in size)
    start = len(verts)
    verts.extend([
        (x - sx, y - sy, z - sz), (x + sx, y - sy, z - sz),
        (x + sx, y + sy, z - sz), (x - sx, y + sy, z - sz),
        (x - sx, y - sy, z + sz), (x + sx, y - sy, z + sz),
        (x + sx, y + sy, z + sz), (x - sx, y + sy, z + sz),
    ])
    faces.extend([tuple(start + i for i in f) for f in (
        (0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
        (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7),
    )])

def add_mesh_object(name, verts, faces, mat, root, collections):
    if not verts:
        return None
    mesh = bpy.data.meshes.new(name + " Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collections[0].objects.link(obj)
    obj.parent = root
    obj.matrix_parent_inverse = Matrix.Identity(4)
    return obj

for source_name in NAMES:
    source = bpy.data.objects.get(source_name)
    if source is None:
        raise RuntimeError("Missing library maze panel: " + source_name)
    points = [source.matrix_world @ Vector(v) for v in source.bound_box]
    lo = [min(p[i] for p in points) for i in range(3)]
    hi = [max(p[i] for p in points) for i in range(3)]
    sx, sy, height = hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]
    length = max(sx, sy)
    depth = min(sx, sy)
    angle = 0.0 if sx >= sy else math.pi * 0.5
    center = Vector(((lo[0] + hi[0]) * 0.5, (lo[1] + hi[1]) * 0.5, lo[2]))
    collections = list(source.users_collection) or [bpy.data.collections.get("After School - School Blockout")]
    root = bpy.data.objects.new(source_name.replace("Maze Wall", "Bookshelf Maze"), None)
    collections[0].objects.link(root)
    if source.parent:
        root.parent = source.parent
    root.matrix_world = Matrix.Translation(center) @ Matrix.Rotation(angle, 4, "Z")
    root.empty_display_type = "CUBE"
    root.empty_display_size = 0.15
    root["bookshelf_maze"] = True
    root["converted_from"] = source_name

    frame_v, frame_f = [], []
    # Central backing and end uprights.
    append_box(frame_v, frame_f, (0, 0, height * 0.5), (length, 0.035, height))
    post_w = min(0.06, length * 0.08)
    for x in (-length * 0.5 + post_w * 0.5, length * 0.5 - post_w * 0.5):
        append_box(frame_v, frame_f, (x, 0, height * 0.5), (post_w, depth, height))
    shelf_levels = [0.07 + i * (height - 0.14) / 4.0 for i in range(5)]
    for z in shelf_levels:
        append_box(frame_v, frame_f, (0, 0, z), (length, depth, min(0.045, height * 0.035)))
    add_mesh_object(root.name + " - Oak Frame and Shelves", frame_v, frame_f, wood, root, collections)

    # Short upright books on both faces of every shelf bay, grouped by spine color.
    grouped = [[] for _ in book_mats]
    grouped_faces = [[] for _ in book_mats]
    face_count = [0 for _ in book_mats]
    shelf_depth = min(0.105, depth * 0.34)
    available = max(0.15, length - post_w * 2 - 0.12)
    for row in range(len(shelf_levels) - 1):
        lower = shelf_levels[row] + 0.025
        upper = shelf_levels[row + 1] - 0.025
        z = (lower + upper) * 0.5
        book_h = min(upper - lower, 0.31)
        cursor = -available * 0.5
        book_index = 0
        while cursor < available * 0.5 - 0.08:
            width = 0.105 + 0.018 * (1 + math.sin((book_index + 1) * 2.13 + row))
            if cursor + width > available * 0.5:
                break
            x = cursor + width * 0.5
            color_index = (book_index * 3 + row * 2 + int(abs(center.x) * 2)) % len(book_mats)
            for side in (-1, 1):
                y = side * (depth * 0.5 - shelf_depth * 0.62)
                append_box(grouped[color_index], grouped_faces[color_index], (x, y, z), (width, shelf_depth, book_h * (0.92 + 0.06 * ((book_index + row) % 2))))
            cursor += width + 0.018
            book_index += 1
    for i, mat in enumerate(book_mats):
        add_mesh_object(root.name + " - Books %02d" % (i + 1), grouped[i], grouped_faces[i], mat, root, collections)

    bpy.data.objects.remove(source, do_unlink=True)

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Converted seven library maze panels into two-sided bookshelves")
