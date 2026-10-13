"""Lightweight furniture pass for the actual room floors in assets.blend.

Run: blender --background assets.blend --python create_classroom_science_art_props.py
Only tagged generated collections/meshes are replaced. Each prop is one joined
mesh, reused by linked-data instances; no collision suffixes or gameplay edits.
The existing preview adds collision only to architecture/encounter meshes, so
these furnishings remain visual. Keep the reserved routes clear regardless.
Append -- --export to refresh both school_blockout.glb (the playable preview)
and school_web.glb using this checkout's existing selected-school GLB workflow.
The standalone export_school_web.py/demo_scene.tscn are absent on this branch.
"""

import json
import math
import os
import sys
from collections import Counter

import bpy
from mathutils import Matrix, Vector


TAG = "classroom_science_art_generator"
SCHOOL = "After School - School Blockout"
GROUPS = ("School Props - Shared", "School Props - Classrooms",
          "School Props - Science", "School Props - Art Room")
PALETTE = {
    "Laminate": (0.48, 0.34, 0.21),
    "Metal": (0.095, 0.12, 0.15),
    "Chair": (0.24, 0.34, 0.40),
    "Cabinet": (0.42, 0.48, 0.46),
    "Board": (0.86, 0.89, 0.84),
    "Lab": (0.25, 0.33, 0.31),
    "Art": (0.43, 0.28, 0.32),
    "Canvas": (0.76, 0.68, 0.51),
}


def bounds(obj):
    pts = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
    return tuple((min(p[i] for p in pts), max(p[i] for p in pts)) for i in range(3))


class MeshKit:
    """Build disconnected primitive parts into a single exportable mesh."""

    def __init__(self):
        self.vertices, self.faces, self.colors = [], [], []

    def box(self, size, center, material, tilt=0):
        base = len(self.vertices)
        transform = Matrix.Rotation(tilt, 4, "X")
        for x, y, z in ((-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1),
                        (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)):
            p = transform @ Vector((x * size[0] / 2, y * size[1] / 2, z * size[2] / 2))
            self.vertices.append(tuple(p + Vector(center)))
        for face in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
                     (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            self.faces.append(tuple(base + i for i in face))
            self.colors.append(material)

    def cylinder(self, radius, height, z, material, sides=8, open_top=False):
        base = len(self.vertices)
        for h in (z - height / 2, z + height / 2):
            for i in range(sides):
                a = 2 * math.pi * i / sides
                self.vertices.append((radius * math.cos(a), radius * math.sin(a), h))
        faces = [tuple(base + i for i in reversed(range(sides)))]
        if not open_top:
            faces.append(tuple(base + sides + i for i in range(sides)))
        faces += [(base + i, base + (i + 1) % sides,
                   base + sides + (i + 1) % sides, base + sides + i) for i in range(sides)]
        self.faces += faces
        self.colors += [material] * len(faces)

    def mesh(self, name, materials):
        mesh = bpy.data.meshes.new("School Prop Kit - " + name)
        mesh[TAG] = True
        mesh.from_pydata(self.vertices, [], self.faces)
        slots = list(dict.fromkeys(self.colors))
        for key in slots:
            mesh.materials.append(materials[key])
        for poly, key in zip(mesh.polygons, self.colors):
            poly.material_index = slots.index(key)
        mesh.update()
        mesh.calc_loop_triangles()
        return mesh


def table(width, depth, height, surface="Laminate", modesty=False):
    k = MeshKit()
    k.box((width, depth, 0.075), (0, 0, height - 0.0375), surface)
    for x in (-width / 2 + 0.085, width / 2 - 0.085):
        for y in (-depth / 2 + 0.085, depth / 2 - 0.085):
            k.box((0.065, 0.065, height - 0.075), (x, y, (height - 0.075) / 2), "Metal")
    if modesty:
        k.box((width - 0.17, 0.055, 0.35), (0, depth / 2 - 0.10, height - 0.27), "Cabinet")
    return k


def chair(teacher=False):
    k = MeshKit()
    width, depth = (0.48, 0.47) if teacher else (0.43, 0.43)
    k.box((width, depth, 0.065), (0, 0, 0.4275), "Chair")
    k.box((width, 0.065, 0.40), (0, -depth / 2 + 0.025, 0.64), "Chair")
    for x in (-width / 2 + 0.055, width / 2 - 0.055):
        for y in (-depth / 2 + 0.055, depth / 2 - 0.055):
            k.box((0.045, 0.045, 0.395), (x, y, 0.1975), "Metal")
    if teacher:
        for x in (-0.28, 0.28):
            k.box((0.05, 0.32, 0.05), (x, 0, 0.61), "Metal")
    return k


def cabinet(width=1.10, height=1.55, open_shelf=False, accent="Cabinet"):
    k = MeshKit()
    k.box((width, 0.055, height), (0, 0.195, height / 2), accent)
    for x in (-width / 2 + 0.035, width / 2 - 0.035):
        k.box((0.07, 0.44, height), (x, 0, height / 2), accent)
    for z in (0.06, height / 2, height - 0.04):
        k.box((width, 0.44, 0.06), (0, 0, z), accent)
    if not open_shelf:
        for x in (-width / 4, width / 4):
            k.box((width / 2 - 0.065, 0.055, height - 0.18), (x, -0.207, height / 2), accent)
            k.box((0.035, 0.055, 0.18), (x * 0.2, -0.255, height * 0.54), "Metal")
    return k


def kit(materials):
    designs = {
        "Student Desk": table(0.90, 0.57, 0.73),
        "Student Chair": chair(),
        "Teacher Desk": table(1.25, 0.62, 0.76, modesty=True),
        "Teacher Chair": chair(True),
        "Classroom Cabinet": cabinet(),
        "Science Lab Table": table(1.90, 0.85, 0.87, "Lab"),
        "Science Cabinet": cabinet(1.2, 1.50),
        "Science Counter": cabinet(1.65, 0.88),
        "Art Table": table(2.10, 0.90, 0.76),
        "Art Supply Shelf": cabinet(1.55, 1.45, True, "Art"),
    }
    k = MeshKit()
    k.box((1.95, 0.075, 1.05), (0, 0, 1.72), "Metal")
    k.box((1.85, 0.025, 0.95), (0, -0.05, 1.72), "Board")
    k.box((1.95, 0.14, 0.04), (0, -0.055, 1.19), "Metal")
    designs["Whiteboard"] = k
    k = MeshKit()
    k.cylinder(0.20, 0.065, 0.4975, "Chair")
    for x in (-0.13, 0.13):
        for y in (-0.13, 0.13):
            k.box((0.045, 0.045, 0.465), (x, y, 0.2325), "Metal")
    k.box((0.30, 0.035, 0.035), (0, -0.13, 0.20), "Metal")
    designs["Stool"] = k  # Science and Art use the same linked mesh.
    k = MeshKit()
    k.cylinder(0.19, 0.42, 0.21, "Metal", open_top=True)
    k.cylinder(0.165, 0.015, 0.365, "Metal")  # inset dark opening
    designs["Trash Can"] = k
    k = MeshKit()
    for x in (-0.28, 0.28):
        k.box((0.065, 0.065, 1.45), (x, 0, 0.725), "Laminate", -0.10)
    k.box((0.07, 0.07, 1.22), (0, 0.28, 0.60), "Laminate", 0.36)
    k.box((0.75, 0.14, 0.06), (0, -0.10, 0.63), "Laminate")
    k.box((0.61, 0.055, 0.74), (0, -0.10, 1.025), "Canvas", -0.10)
    designs["Easel"] = k
    return {name: design.mesh(name, materials) for name, design in designs.items()}


class Furnisher:
    def __init__(self, collections, meshes):
        self.collections, self.meshes = collections, meshes
        self.instances, self.reserved = [], {}

    def floor(self, name):
        obj = bpy.data.objects.get(name)
        if obj is None or obj.type != "MESH":
            raise RuntimeError("Required actual room floor missing: " + name)
        return obj

    def place(self, design, floor, x, y, angle=0, group=0, label=None):
        name = "%s - %s" % (floor.name.removesuffix(" Floor"), label or design)
        obj = bpy.data.objects.new(name, self.meshes[design])
        self.collections[group].objects.link(obj)
        obj[TAG], obj["prop_type"], obj["room_floor"] = True, label or design, floor.name
        obj["collision_policy"] = "visual-only; preserve existing preview conventions"
        obj.location = (x, y, bounds(floor)[2][1])
        obj.rotation_euler.z = angle
        bpy.context.view_layer.update()
        world = obj.matrix_world.copy()
        obj.parent = floor
        obj.matrix_world = world
        self.instances.append(obj)
        return obj

    def reserve_point(self, floor, u, v, radius, label):
        (x0, x1), (y0, y1), _ = bounds(floor)
        x, y = x0 + (x1 - x0) * u, y1 - (y1 - y0) * v
        self.reserved.setdefault(floor.name, []).append((x, y, radius, label))

    def classroom(self, letter):
        floor = self.floor("Classroom %s Floor" % letter)
        (x0, x1), (y0, y1), _ = bounds(floor)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        east_front = letter in "ABE"  # Leave the north windows uncovered.
        angle = -math.pi / 2 if east_front else 0
        width, depth = ((y1 - y0, x1 - x0) if east_front else (x1 - x0, y1 - y0))

        def local(design, x, y, rotation=0, group=1):
            px = cx + math.cos(angle) * x - math.sin(angle) * y
            py = cy + math.sin(angle) * x + math.cos(angle) * y
            return self.place(design, floor, px, py, angle + rotation, group)

        # Two desk banks, a >=1.2 m central aisle and clear rear/front routes.
        columns = (-2.15, -1.15, 1.15, 2.15) if width >= 6.5 else (-1.40, 1.40)
        rows = (-depth / 2 + 1.55, depth / 2 - 1.70)
        if not east_front:
            rows = (-1.35, 1.25)
        if depth >= 8:
            rows = (-depth / 2 + 1.65, -0.7, depth / 2 - 2.65)
        for y in rows:
            row_columns = (-1.05, 1.05) if not east_front and y > 0 else columns
            for x in row_columns:
                # E's south door is beside the outer bank in the middle row.
                if letter == "E" and abs(y + 0.7) < 0.01 and x > 2:
                    continue
                local("Student Desk", x, y)
                local("Student Chair", x, y - 0.58)
        local("Whiteboard", 0, depth / 2 - 0.16, group=0)
        local("Teacher Desk", 0 if east_front else -1.00,
              depth / 2 - (0.95 if east_front else 1.20), group=0)
        local("Teacher Chair", 0 if east_front else -1.00,
              depth / 2 - (0.40 if east_front else 0.63), math.pi, 0)
        local("Classroom Cabinet", width / 2 - 0.80, depth / 2 - 0.43, group=0)
        local("Trash Can", -width / 2 + 0.43, depth / 2 - 0.43, group=0)
        if letter == "B":
            self.reserve_point(floor, 0.5, 0.5, 0.85, "Ruler pickup")

    def science(self):
        for room in ("Science Classroom", "Lab Room"):
            floor = self.floor(room + " Floor")
            (x0, x1), (y0, y1), _ = bounds(floor)
            cy = (y0 + y1) / 2
            offsets = (3.15, 6.30, 9.45) if room == "Science Classroom" else (5.10, 8.25)
            for dx in offsets:
                self.place("Science Lab Table", floor, x0 + dx, cy, group=2)
                for side in (-1, 1):
                    self.place("Stool", floor, x0 + dx, cy + side * 0.80,
                               group=2, label="Science Stool")
            # Short cabinets on the solid east wall; door/SE corner kept clear.
            self.place("Science Cabinet", floor, x1 - 0.43,
                       cy if room == "Science Classroom" else y1 - 1.0,
                       -math.pi / 2, 2)
            if room == "Science Classroom":
                self.reserve_point(floor, 0.88, 0.88, 1.10, "Science monster southeast position")
            else:
                self.reserve_point(floor, 0.12, 0.12, 1.20, "Lab Coat northwest pickup")
                self.place("Science Counter", floor, x0 + 0.53, cy,
                           math.pi / 2, 2)
                self.place("Whiteboard", floor, x0 + 0.18, y0 + 1.20,
                           math.pi / 2, 0)

    def art(self):
        # Confirmed by Artroom Label and PREVIEW_ITEMS: not Cafe Floor.
        floor = self.floor("Cafeteria Floor")
        (x0, x1), (y0, y1), _ = bounds(floor)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        for x, y in ((cx, y0 + 2.0), (x1 - 1.48, cy + 0.75)):
            self.place("Art Table", floor, x, y, group=3)
            for dx in (-0.55, 0.55):
                for dy in (-0.80, 0.80):
                    self.place("Stool", floor, x + dx, y + dy, group=3, label="Art Stool")
        self.place("Art Supply Shelf", floor, cx, y1 - 0.48, group=3)
        self.place("Easel", floor, x1 - 0.85, y0 + 2.9, -math.pi / 2, 3)
        self.place("Easel", floor, x0 + 1.77, y1 - 0.9, group=3)
        self.place("Easel", floor, x1 - 1.77, y1 - 0.9, group=3)
        self.place("Trash Can", floor, x1 - 0.43, y0 + 0.48, group=0)
        self.reserve_point(floor, 0.5, 0.5, 0.90, "Brush pickup / ceiling sweep center")
        for u, v in ((0.2, 0.2), (0.8, 0.2), (0.8, 0.8), (0.2, 0.8), (0.5, 0.25)):
            self.reserve_point(floor, u, v, 0.60, "Brush encounter candidate")

    def validate(self):
        bpy.context.view_layer.update()
        errors = []
        for obj in self.instances:
            floor = self.floor(obj["room_floor"])
            ob, fb = bounds(obj), bounds(floor)
            if any(ob[i][0] < fb[i][0] + 0.11 or ob[i][1] > fb[i][1] - 0.11 for i in (0, 1)):
                errors.append("Outside interior wall margin: " + obj.name)
            if abs(ob[2][0] - fb[2][1]) > 0.002 and obj["prop_type"] != "Whiteboard":
                errors.append("Not seated on floor: " + obj.name)
            for x, y, radius, label in self.reserved.get(floor.name, []):
                dx = max(ob[0][0] - x, 0, x - ob[0][1])
                dy = max(ob[1][0] - y, 0, y - ob[1][1])
                if math.hypot(dx, dy) < radius:
                    errors.append("%s overlaps %s" % (obj.name, label))
            # Read ALL modeled headers near a room, including shared Bathroom
            # and classroom doors whose names belong to the adjacent room.
            for door in bpy.data.objects:
                if not door.name.startswith("Door Header"):
                    continue
                db = bounds(door)
                if all(db[i][1] >= fb[i][0] - 0.15 and db[i][0] <= fb[i][1] + 0.15 for i in (0, 1)):
                    margins = (0.35, 1.20) if db[0][1] - db[0][0] > db[1][1] - db[1][0] else (1.20, 0.35)
                    if all(ob[i][1] > db[i][0] - margins[i] and ob[i][0] < db[i][1] + margins[i] for i in (0, 1)):
                        errors.append("Door approach occupied: %s / %s" % (obj.name, door.name))
        # No intersecting prop AABBs (apart from intentionally touching parts
        # already joined inside a design). Also catches misplaced chairs.
        for i, obj in enumerate(self.instances):
            a = bounds(obj)
            for other in self.instances[i + 1:]:
                if other["room_floor"] != obj["room_floor"]:
                    continue
                b = bounds(other)
                if all(a[k][1] > b[k][0] + 0.002 and b[k][1] > a[k][0] + 0.002 for k in range(3)):
                    errors.append("Props overlap: %s / %s" % (obj.name, other.name))
        if errors:
            raise RuntimeError("Placement validation failed:\n" + "\n".join(errors))


def main():
    school = bpy.data.collections.get(SCHOOL)
    if school is None or not bpy.data.filepath:
        raise RuntimeError("Run against the existing assets.blend school scene")
    # Refuse to overwrite an untagged collection owned by someone else.
    for name in GROUPS:
        collection = bpy.data.collections.get(name)
        if collection and not collection.get(TAG):
            raise RuntimeError("Existing unowned collection: " + name)
        if collection and any(not obj.get(TAG) for obj in collection.all_objects):
            raise RuntimeError("Unowned object inside generated collection: " + name)
    for name in GROUPS:
        collection = bpy.data.collections.get(name)
        if collection:
            for obj in list(collection.objects):
                bpy.data.objects.remove(obj, do_unlink=True)
            bpy.data.collections.remove(collection)
    for mesh in list(bpy.data.meshes):
        if mesh.get(TAG) and mesh.users == 0:
            bpy.data.meshes.remove(mesh)
    collections = []
    for name in GROUPS:
        collection = bpy.data.collections.new(name)
        collection[TAG] = True
        school.children.link(collection)
        collections.append(collection)
    materials = {}
    for key, color in PALETTE.items():
        name = "School Props - " + key
        mat = bpy.data.materials.get(name)
        if mat and not mat.get(TAG):
            raise RuntimeError("Existing unowned material: " + name)
        mat = mat or bpy.data.materials.new(name)
        mat[TAG] = True
        mat.diffuse_color = (*color, 1)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*color, 1)
        bsdf.inputs["Roughness"].default_value = 0.78
        materials[key] = mat
    meshes = kit(materials)
    furnisher = Furnisher(collections, meshes)
    for letter in "ABCDE":
        furnisher.classroom(letter)
    furnisher.science()
    furnisher.art()
    furnisher.validate()
    counts = Counter(obj["prop_type"] for obj in furnisher.instances)
    stats = {
        "instances": len(furnisher.instances), "designs": len(meshes),
        "materials": len(materials), "types": dict(counts),
        "rooms": dict(Counter(obj["room_floor"] for obj in furnisher.instances)),
        "unique_triangles": sum(len(mesh.loop_triangles) for mesh in meshes.values()),
        "instanced_triangles": sum(len(obj.data.loop_triangles) for obj in furnisher.instances),
        "collections": list(GROUPS),
    }
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    report_path = os.path.join(os.environ.get("TEMP", "/tmp"), "classroom_props_stats.json")
    with open(report_path, "w", encoding="utf-8") as output:
        json.dump(stats, output, indent=2)
    print("CLASSROOM_PROPS", json.dumps(stats, sort_keys=True))


def export_web_models():
    # Match create_auditorium_microphone.py's export settings, retaining the
    # seven Library Maze Walls included in the current committed GLB as well.
    school = bpy.data.collections[SCHOOL]
    objects = set(school.all_objects)
    objects.update(obj for obj in bpy.data.objects if obj.name.startswith("Library Maze Wall"))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = bpy.data.objects["Classroom A Floor"]
    for filename in ("school_blockout.glb", "school_web.glb"):
        path = bpy.path.abspath("//assets/" + filename)
        bpy.ops.export_scene.gltf(
            filepath=path, export_format="GLB", use_selection=True,
            export_apply=True, export_yup=True, export_extras=True,
        )
        print("EXPORTED", path, os.path.getsize(path), "bytes")


if __name__ == "__main__":
    main()
    if "--" in sys.argv and "--export" in sys.argv[sys.argv.index("--") + 1:]:
        export_web_models()
