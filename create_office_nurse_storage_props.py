"""Office/Nurse/Storage asset-only pass; requires the current assets.blend.

blender --background assets.blend --python create_office_nurse_storage_props.py
Then use the unchanged export_school_web.py to refresh the portable Web model.
Only this generator's tagged collections/meshes are replaced. Previous props,
architecture, glass and lighting are preserved. Furniture stays visual-only.
"""

import json
import math
import os
import runpy
from collections import Counter, deque
from pathlib import Path

import bpy
from mathutils import Vector


TAG = "office_nurse_storage_generator"
GROUPS = ("School Props - Office", "School Props - Nurse Office", "School Props - Storage")
ROOMS = ("Main Office Floor", "Nurse Office Floor", "Storage Closet Floor")
REUSE = {"Office Desk": "Teacher Desk", "Office Chair": "Teacher Chair",
         "Waiting Chair": "Student Chair", "Exam Stool": "Stool", "Trash Bin": "Trash Can"}
NEW_COLORS = {"Medical White": (0.75, 0.79, 0.74), "Medical Vinyl": (0.34, 0.47, 0.44),
              "Storage Cardboard": (0.47, 0.34, 0.22)}


def bounds(obj):
    points = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
    return tuple((min(p[i] for p in points), max(p[i] for p in points)) for i in range(3))


def make_mesh(name, parts, materials):
    mesh = bpy.data.meshes.new("School Office Kit - " + name)
    mesh[TAG] = True
    mesh.from_pydata(parts.vertices, [], parts.faces)
    slots = list(dict.fromkeys(parts.colors))
    for key in slots:
        mesh.materials.append(materials[key])
    for polygon, key in zip(mesh.polygons, parts.colors):
        polygon.material_index = slots.index(key)
    mesh.update()
    mesh.calc_loop_triangles()
    return mesh


def build_kit(materials):
    # Read reusable primitive builders without running the previous generator.
    library = runpy.run_path(str(Path(bpy.data.filepath).parent / "create_classroom_science_art_props.py"),
                             run_name="prop_kit_library")
    parts_class, table = library["MeshKit"], library["table"]
    designs = {}
    k = parts_class()
    k.box((1.85, 0.68, 0.09), (0, 0, 0.935), "Laminate")
    k.box((1.72, 0.07, 0.83), (0, 0.22, 0.485), "Cabinet")
    for x in (-0.85, 0.85):
        k.box((0.08, 0.57, 0.89), (x, 0, 0.445), "Cabinet")
    k.box((1.70, 0.05, 0.06), (0, 0.263, 0.24), "Metal")
    designs["Reception Desk"] = k
    k = parts_class()
    k.box((0.56, 0.43, 1.22), (0, 0, 0.61), "Cabinet")
    for z in (0.21, 0.61, 1.01):
        k.box((0.49, 0.028, 0.35), (0, -0.23, z), "Board")
        k.box((0.21, 0.035, 0.035), (0, -0.26, z + 0.06), "Metal")
    designs["Filing Cabinet"] = k
    designs["Office Bookcase"] = library["cabinet"](1.15, 1.50, True)
    k = parts_class()
    k.box((0.28, 0.19, 0.035), (0, 0, 0.0175), "Metal")
    k.box((0.055, 0.05, 0.16), (0, 0, 0.10), "Metal")
    k.box((0.43, 0.06, 0.28), (0, 0.015, 0.27), "Metal")
    k.box((0.37, 0.01, 0.22), (0, -0.022, 0.27), "Chair")
    designs["Computer Monitor"] = k
    designs["Nurse Desk"] = table(0.90, 0.50, 0.73)
    designs["Medical Side Table"] = table(0.43, 0.43, 0.57, "Medical White")
    k = parts_class()
    k.box((0.72, 1.80, 0.09), (0, 0, 0.415), "Medical White")
    k.box((0.68, 1.73, 0.12), (0, 0, 0.52), "Medical Vinyl")
    k.box((0.52, 0.34, 0.075), (0, 0.57, 0.6175), "Medical White")
    k.box((0.72, 0.055, 0.42), (0, 0.88, 0.62), "Medical White")
    for x in (-0.27, 0.27):
        for y in (-0.74, 0.74):
            k.box((0.055, 0.055, 0.37), (x, y, 0.185), "Metal")
    designs["Exam Cot"] = k
    k = library["cabinet"](0.55, 1.42, False, "Medical White")
    # A broad inset panel, rather than tiny medical-detail geometry.
    k.box((0.36, 0.012, 0.27), (0, -0.24, 1.06), "Medical Vinyl")
    designs["Medical Cabinet"] = k
    k = parts_class()
    for x in (-0.615, 0.615):
        k.box((0.065, 0.40, 1.65), (x, 0, 0.825), "Metal")
    k.box((1.30, 0.035, 1.65), (0, 0.20, 0.825), "Cabinet")
    for z in (0.075, 0.775, 1.60):
        k.box((1.30, 0.40, 0.05), (0, 0, z), "Cabinet")
    designs["Storage Shelving"] = k
    k = parts_class()
    k.box((0.42, 0.32, 0.32), (0, 0, 0.16), "Storage Cardboard")
    k.box((0.065, 0.324, 0.008), (0, 0, 0.324), "Canvas")
    designs["Cardboard Box"] = k
    k = parts_class()
    for z in (0.18, 0.55, 0.92):
        k.box((1.05, 0.36, 0.32), (0, 0, z), "Chair")
        k.box((1.10, 0.40, 0.04), (0, 0, z + 0.18), "Cabinet")
        k.box((0.23, 0.024, 0.06), (0, -0.192, z + 0.03), "Metal")
    k.box((1.05, 0.36, 0.02), (0, 0, 0.01), "Metal")
    designs["Stacked Supply Bins"] = k
    k = library["cabinet"](0.95, 1.40, True)
    k.box((0.38, 0.29, 0.26), (-0.23, -0.015, 0.23), "Medical Vinyl")
    k.box((0.32, 0.29, 0.32), (0.25, -0.015, 0.27), "Storage Cardboard")
    k.box((0.72, 0.28, 0.24), (0, -0.015, 0.86), "Medical White")
    designs["Janitorial Supply Shelf"] = k
    meshes = {name: make_mesh(name, parts, materials) for name, parts in designs.items()}
    for name, old_name in REUSE.items():
        mesh = bpy.data.meshes.get("School Prop Kit - " + old_name)
        if mesh is None:
            raise RuntimeError("Previous furniture mesh missing: " + old_name)
        mesh.calc_loop_triangles()
        meshes[name] = mesh
    return meshes


class Layout:
    def __init__(self, collections, meshes):
        self.collections, self.meshes = collections, meshes
        self.objects, self.reserved, self.targets, self.camera_zones = [], {}, {}, []

    def floor(self, name):
        floor = bpy.data.objects.get(name)
        if floor is None or floor.type != "MESH":
            raise RuntimeError("Missing actual floor: " + name)
        return floor

    def place(self, room, design, x, y, angle=0, base=0, support=None, label=None):
        floor = self.floor(room)
        index = sum(o["room_floor"] == room and o["prop_type"] == design for o in self.objects) + 1
        name = "%s - %s %02d" % (room.removesuffix(" Floor"), label or design, index)
        if bpy.data.objects.get(name):
            raise RuntimeError("Unowned object name conflicts: " + name)
        obj = bpy.data.objects.new(name, self.meshes[design])
        self.collections[ROOMS.index(room)].objects.link(obj)
        obj[TAG], obj["prop_type"], obj["room_floor"] = True, design, room
        obj["collision_policy"] = "visual-only; match classroom props"
        obj["base_above_floor"] = base
        if support:
            obj["support_object"] = support.name
        obj.location = (x, y, bounds(floor)[2][1] + base)
        obj.rotation_euler.z = angle
        bpy.context.view_layer.update()
        world = obj.matrix_world.copy()
        obj.parent = floor
        obj.matrix_world = world
        self.objects.append(obj)
        return obj

    def reserve(self, room, u, v, radius, label):
        (x0, x1), (y0, y1), _ = bounds(self.floor(room))
        # Match Godot floor fractions: Godot z is negative Blender y.
        point = (x0 + (x1 - x0) * u, y1 - (y1 - y0) * v)
        self.reserved.setdefault(room, []).append((*point, radius, label))
        self.targets.setdefault(room, []).append((label, point))

    def furnish(self):
        office, nurse, storage = ROOMS
        (x0, x1), (y0, y1), _ = bounds(self.floor(office))
        self.reserve(office, 0.5, 0.5, 1.30, "School Keys pickup")
        for dx in (3.40, 9.40):
            desk = self.place(office, "Office Desk", x0 + dx, y0 + 1.20)
            self.place(office, "Office Chair", x0 + dx, y0 + 0.63)
            self.place(office, "Computer Monitor", x0 + dx, y0 + 1.30, base=0.76, support=desk)
        self.place(office, "Reception Desk", x0 + 2.15, (y0 + y1) / 2)
        for dy in (2.10, 1.05):
            self.place(office, "Waiting Chair", x0 + 0.80, y1 - dy, -math.pi / 2)
        for dy in (0.70, 1.55):
            self.place(office, "Filing Cabinet", x0 + 0.48, y0 + dy, math.pi / 2)
        self.place(office, "Office Bookcase", x1 - 0.45, (y0 + y1) / 2, -math.pi / 2)
        self.place(office, "Trash Bin", x1 - 0.48, y0 + 0.48)

        (x0, x1), (y0, y1), _ = bounds(self.floor(nurse))
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        self.reserve(nurse, 0.5, 0.5, 0.96, "Player spawn / first movement")
        # Initial CameraPivot yaw is 0, pitch -0.2, SpringArm 3.5 at scale .8.
        # Reserve its full south-facing plan corridor, including the office side.
        self.camera_zones.append(((cx - 0.50, cx + 0.50), (cy - 2.80, cy + 0.10), "Initial Nurse camera"))
        self.place(nurse, "Exam Cot", x1 - 0.60, cy)
        self.place(nurse, "Nurse Desk", x0 + 1.05, y1 - 0.95)
        self.place(nurse, "Office Chair", x0 + 1.05, y1 - 0.42, math.pi, label="Nurse Desk Chair")
        self.place(nurse, "Medical Cabinet", x0 + 0.55, y0 + 0.45)
        self.place(nurse, "Medical Side Table", x1 - 0.60, y1 - 0.55)
        self.place(nurse, "Exam Stool", x1 - 0.60, y0 + 0.42)

        (x0, x1), (y0, y1), _ = bounds(self.floor(storage))
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        self.reserve(storage, 0.5, 0.5, 0.95, "Front Door Key pickup")
        # _final_key_monster_spawn chooses the farthest navigable candidate.
        # Keep every candidate clear, rather than assuming which wins a tie.
        for u, v in ((0.2, 0.2), (0.8, 0.2), (0.2, 0.8), (0.8, 0.8)):
            self.reserve(storage, u, v, 0.70, "Final Monster candidate %.1f %.1f" % (u, v))
        shelf = self.place(storage, "Storage Shelving", cx, y1 - 0.40)
        for dx in (-0.30, 0.30):
            for height in (0.10, 0.80):
                self.place(storage, "Cardboard Box", cx + dx, y1 - 0.40,
                           base=height, support=shelf)
        self.place(storage, "Janitorial Supply Shelf", x0 + 0.49, cy, math.pi / 2)
        self.place(storage, "Stacked Supply Bins", x1 - 0.45, cy, -math.pi / 2)

    def validate(self):
        bpy.context.view_layer.update()
        errors = []
        for obj in self.objects:
            room = obj["room_floor"]
            ob, fb = bounds(obj), bounds(self.floor(room))
            if any(ob[i][0] < fb[i][0] + 0.15 or ob[i][1] > fb[i][1] - 0.15 for i in (0, 1)):
                errors.append("Inside wall margin: " + obj.name)
            if abs(ob[2][0] - fb[2][1] - obj["base_above_floor"]) > 0.002:
                errors.append("Bad floor/support height: " + obj.name)
            for x, y, radius, label in self.reserved.get(room, []):
                distance = math.hypot(max(ob[0][0] - x, 0, x - ob[0][1]),
                                      max(ob[1][0] - y, 0, y - ob[1][1]))
                if distance < radius:
                    errors.append("%s overlaps %s" % (obj.name, label))
            for xb, yb, label in self.camera_zones:
                if ob[2][0] < fb[2][1] + 2.20 and all(ob[i][1] > zone[0] and ob[i][0] < zone[1] for i, zone in enumerate((xb, yb))):
                    errors.append("%s overlaps %s" % (obj.name, label))
            for door in bpy.data.objects:
                if not door.name.startswith("Door Header"):
                    continue
                db = bounds(door)
                if all(db[i][1] >= fb[i][0] - 0.22 and db[i][0] <= fb[i][1] + 0.22 for i in (0, 1)):
                    margins = (0.35, 1.20) if db[0][1] - db[0][0] > db[1][1] - db[1][0] else (1.20, 0.35)
                    if all(ob[i][1] > db[i][0] - margins[i] and ob[i][0] < db[i][1] + margins[i] for i in (0, 1)):
                        errors.append("Door approach: %s / %s" % (obj.name, door.name))
        for i, obj in enumerate(self.objects):
            a = bounds(obj)
            for other in self.objects[i + 1:]:
                if obj["room_floor"] != other["room_floor"]:
                    continue
                # Boxes intentionally occupy shelf bays, with base heights above
                # the actual shelves. Monitors are supported by desktops.
                if obj.get("support_object") == other.name or other.get("support_object") == obj.name:
                    continue
                b = bounds(other)
                if all(a[k][1] > b[k][0] + 0.002 and b[k][1] > a[k][0] + 0.002 for k in range(3)):
                    errors.append("Prop overlap: %s / %s" % (obj.name, other.name))
        if errors:
            raise RuntimeError("Placement rejected:\n" + "\n".join(errors))
        self.validate_routes()

    def validate_routes(self):
        """Conservative 10 cm grid: treat visual prop footprints as obstacles.

        Check all door endpoints, spawn and pickups in one connected component,
        for both the .48 m player and a .9 m body. Godot checks are separate.
        """
        for room in ROOMS:
            (x0, x1), (y0, y1), _ = bounds(self.floor(room))
            for radius in (0.24, 0.45):
                margin, step = radius + 0.20, 0.10
                obstacles = [bounds(obj) for obj in self.objects if obj["room_floor"] == room]
                free = set()

                def point(cell):
                    return (x0 + margin + cell[0] * step, y0 + margin + cell[1] * step)

                for i in range(int((x1 - x0 - 2 * margin) / step) + 1):
                    for j in range(int((y1 - y0 - 2 * margin) / step) + 1):
                        x, y = point((i, j))
                        if all(math.hypot(max(b[0][0] - x, 0, x - b[0][1]),
                                          max(b[1][0] - y, 0, y - b[1][1])) >= radius for b in obstacles):
                            free.add((i, j))
                if not free:
                    raise RuntimeError("No furniture-free route: " + room)
                targets = list(self.targets.get(room, []))
                fb = bounds(self.floor(room))
                for door in bpy.data.objects:
                    if not door.name.startswith("Door Header"):
                        continue
                    db = bounds(door)
                    if all(db[i][1] >= fb[i][0] - 0.22 and db[i][0] <= fb[i][1] + 0.22 for i in (0, 1)):
                        x, y = [(db[i][0] + db[i][1]) / 2 for i in (0, 1)]
                        targets.append((door.name, (min(x1 - margin, max(x0 + margin, x)),
                                                          min(y1 - margin, max(y0 + margin, y)))))
                cells = []
                for label, target in targets:
                    cell = min(free, key=lambda c: math.dist(point(c), target))
                    if math.dist(point(cell), target) > 0.16:
                        raise RuntimeError("Route target obstructed: %s / %s" % (room, label))
                    cells.append(cell)
                visited, queue = {cells[0]}, deque([cells[0]])
                while queue:
                    i, j = queue.popleft()
                    for cell in ((i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1)):
                        if cell in free and cell not in visited:
                            visited.add(cell)
                            queue.append(cell)
                if not all(cell in visited for cell in cells):
                    raise RuntimeError("Disconnected furniture-free route: " + room)
                print("ROUTE_CLEAR", room, "body width", radius * 2, "targets", len(cells))


def main():
    school = bpy.data.collections.get("After School - School Blockout")
    if not school or not bpy.data.filepath:
        raise RuntimeError("Open current assets.blend before running")
    for room in ROOMS:
        if bpy.data.objects.get(room) is None:
            raise RuntimeError("Required floor missing: " + room)
    for name in GROUPS:
        collection = bpy.data.collections.get(name)
        if collection and (not collection.get(TAG) or collection.children or
                           any(not obj.get(TAG) for obj in collection.objects)):
            raise RuntimeError("Refusing unowned/generated collection conflict: " + name)
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
    for key in ("Laminate", "Metal", "Chair", "Cabinet", "Board", "Canvas"):
        mat = bpy.data.materials.get("School Props - " + key)
        if not mat:
            raise RuntimeError("Required shared palette missing: " + key)
        materials[key] = mat
    for key, color in NEW_COLORS.items():
        name = "School Props - " + key
        mat = bpy.data.materials.get(name)
        if mat and not mat.get(TAG):
            raise RuntimeError("Refusing unowned material conflict: " + name)
        mat = mat or bpy.data.materials.new(name)
        mat[TAG] = True
        mat.diffuse_color = (*color, 1)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*color, 1)
        bsdf.inputs["Roughness"].default_value = 0.80
        materials[key] = mat
    meshes = build_kit(materials)
    layout = Layout(collections, meshes)
    layout.furnish()
    layout.validate()
    stats = {"instances": len(layout.objects), "new_designs": len(meshes) - len(REUSE),
             "reused_designs": len(REUSE), "materials_added": len(NEW_COLORS), "materials_reused": 6,
             "types": dict(Counter(obj["prop_type"] for obj in layout.objects)),
             "rooms": dict(Counter(obj["room_floor"] for obj in layout.objects)),
             "unique_triangles": sum(len(m.loop_triangles) for m in meshes.values()),
             "instanced_triangles": sum(len(obj.data.loop_triangles) for obj in layout.objects)}
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    report = {"stats": stats, "reserved": layout.reserved, "camera_zones": layout.camera_zones,
              "objects": {obj.name: {"room": obj["room_floor"], "bounds": bounds(obj),
                                     "type": obj["prop_type"]} for obj in layout.objects}}
    folder = Path(os.environ.get("TEMP", "/tmp")) / "after-school-office-props-review"
    folder.mkdir(exist_ok=True)
    (folder / "props_report.json").write_text(json.dumps(report, indent=2))
    print("OFFICE_PROPS", json.dumps(stats, sort_keys=True))


if __name__ == "__main__":
    main()
