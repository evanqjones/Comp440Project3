"""Visual-only Gym / Locker Room / east Ruler hallway kit for assets.blend.

Blender 5.2: --background assets.blend --python create_gym_locker_hallway_props.py
Then run the current export_school_web.py separately. No gameplay files change.
Room placement uses world-space floor/wall bounds. Locker positions and panel
dimensions are read from the current runtime source; unsupported changes fail
closed. Locker crowns sit above the current detailed models, never add a front door or
interaction/collision node. Only this generator's owned content is replaced.
Reports and route paths are written outside the repository under TEMP.
"""
import json
import math
import os
import re
import runpy
from collections import Counter, deque
from pathlib import Path

import bpy
from mathutils import Vector

TAG = "gym_locker_hallway_generator"
GROUPS = ("School Props - Gym", "School Props - Locker Room", "School Props - Hallways")
ROOMS = ("Gym Floor", "Locker Room Floor", "School Site Floor - circulation")
ROOT = Path(bpy.data.filepath).parent
Base = runpy.run_path(str(ROOT / "create_cafeteria_library_props.py"))["Builder"]


def bounds(obj):
    pts = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
    return tuple((min(p[i] for p in pts), max(p[i] for p in pts)) for i in range(3))


class Builder(Base):
    def sphere(self, radius, center, material):
        # 80 triangles, ten-sided equator and four intermediate latitude rings.
        n = 10
        vertices = [(0, 0, -radius)]
        for j in range(1, 5):
            angle = -math.pi/2 + j*math.pi/5
            vertices += [(radius*math.cos(angle)*math.cos(i*2*math.pi/n),
                          radius*math.cos(angle)*math.sin(i*2*math.pi/n),
                          radius*math.sin(angle)) for i in range(n)]
        vertices.append((0, 0, radius))
        faces = [(0, 1+(i+1)%n, 1+i) for i in range(n)]
        for row in range(3):
            a, b = 1+row*n, 1+(row+1)*n
            faces += [(a+i, a+(i+1)%n, b+(i+1)%n, b+i) for i in range(n)]
        faces += [(41, 31+i, 31+(i+1)%n) for i in range(n)]
        self.solid([tuple(Vector(v)+Vector(center)) for v in vertices], faces, material)

    def rim(self, center):
        n, sides, r, tube = 12, 4, .225, .023
        v = []
        for i in range(n):
            a = 2*math.pi*i/n
            for j in range(sides):
                b = 2*math.pi*j/sides
                v.append((center[0]+(r+tube*math.cos(b))*math.cos(a),
                          center[1]+(r+tube*math.cos(b))*math.sin(a),
                          center[2]+tube*math.sin(b)))
        f = [(i*sides+j, ((i+1)%n)*sides+j, ((i+1)%n)*sides+(j+1)%sides,
              i*sides+(j+1)%sides) for i in range(n) for j in range(sides)]
        self.solid(v, f, "Art")

    def mesh(self, name, materials):
        mesh = bpy.data.meshes.new("School Athletics Kit - " + name)
        mesh[TAG] = True
        mesh.from_pydata(self.vertices, [], self.faces)
        slots = list(dict.fromkeys(self.colors))
        for key in slots:
            mesh.materials.append(materials[key])
        for p, key, smooth in zip(mesh.polygons, self.colors, self.smooth):
            p.material_index = slots.index(key)
            p.use_smooth = smooth
        mesh.update()
        mesh.calc_loop_triangles()
        return mesh


def bench(width=1.65):
    k = Builder()
    for y in (-.13, .13):
        k.box((width, .245, .08), (0, y, .46), "Laminate", .016)
    for x in (-width*.35, width*.35):
        for y in (-.15, .15):
            k.box((.075, .075, .42), (x, y, .21), "Metal", .008)
        k.box((.13, .46, .05), (x, 0, .025), "Metal", .009)
    k.box((width*.72, .055, .06), (0, 0, .25), "Metal", 0)
    return k


def locker_skin(width):
    # Current main already supplies the detailed closed locker facade. Add only
    # a formed cap/label rail ABOVE it, without covering the functional face.
    k = Builder()
    k.box((width+.025,.83,.065),(0,0,2.095),"Metal",.012)
    k.box((width-.06,.045,.105),(0,-.405,2.155),"Chair",.008)
    for x in (-width*.31,width*.31):
        k.box((.13,.018,.045),(x,-.434,2.155),"Medical White",.004)
    return k


def shelf(towels=False):
    k = Builder()
    for x in (-.51, .51):
        k.box((.055, .34, 1.25), (x, 0, .625), "Metal", .007)
    k.box((1.075, .025, 1.14), (0, .16, .65), "Cabinet", 0)
    for z in (.07, .55, 1.22):
        k.box((1.10, .35, .055), (0, 0, z), "Laminate", 0 if z == .07 else .008)
    if towels:
        for x in (-.27, .27):
            for z in (.62, .69, .76):
                k.box((.40, .26, .055), (x, -.02, z), "Canvas", .008)
        k.box((.55, .25, .20), (0, 0, .1975), "Cabinet", .012)
    else:
        for x, color in ((-.30, "Art"), (0, "Canvas"), (.30, "Chair")):
            k.sphere(.12, (x, -.015, .6975), color)
        k.box((.80, .24, .22), (0, 0, .2075), "Chair", .013)
    return k


def kit(materials):
    designs = {"Athletics Bench": bench(), "Changing Bench": bench(1.20),
               "Locker Crown": locker_skin(.82), "Hall Locker Crown": locker_skin(2.10),
               "Sports Shelf": shelf(), "Towel Shelf": shelf(True)}
    k = Builder()
    # Two modest bleacher tiers: individual planks, riser brackets and foot rail.
    for y, z in ((-.36, .47), (.29, .86)):
        for dy in (-.12, .12):
            k.box((2.80, .23, .08), (0, y+dy, z), "Laminate", .015)
        for x in (-1.10, 1.10):
            k.box((.085, .09, z-.04), (x, y, (z-.04)/2), "Metal", .009)
    for x in (-1.10, 1.10):
        k.box((.15, 1.22, .06), (x, 0, .03), "Metal", .010)
        k.box((.07, .07, .54), (x, .56, .77), "Metal", .005)
    k.box((2.80, .35, .055), (0, .02, .28), "Metal", .008)
    k.box((2.36, .055, .055), (0, .56, 1.04), "Metal", .006)
    designs["Two Tier Bleachers"] = k
    k = Builder()
    k.box((1.65, .075, 1.03), (0, .075, .515), "Metal", .015)
    k.box((1.56, .032, .94), (0, .021, .515), "Medical White", .008)
    for x in (-.285, .285):
        k.box((.025, .012, .32), (x, -.002, .32), "Art", 0)
    for z in (.16, .48):
        k.box((.595, .012, .025), (0, -.002, z), "Art", 0)
    k.box((.12, .30, .045), (0, -.13, .16), "Metal", .007)
    k.rim((0, -.405, .16))
    # Four low-cost hanging net strands and a bottom ring silhouette.
    for x, y in ((-.16, -.405), (.16, -.405), (0, -.245), (0, -.565)):
        k.box((.012, .012, .28), (x, y, .0), "Canvas", 0)
    designs["Backboard and Hoop"] = k
    k = Builder()
    k.box((.82, .095, 1.20), (0, 0, .60), "Metal", .012)
    k.box((.78, .12, 1.15), (0, -.052, .60), "Medical Vinyl", .027)
    k.box((.60, .008, .04), (0, -.115, .12), "Canvas", 0)
    designs["Safety Padding"] = k
    k = Builder()
    for i, color in enumerate(("Medical Vinyl", "Chair", "Medical Vinyl", "Chair")):
        k.box((1.50, .70, .095), (0, 0, .055+i*.10), color, .025)
    for x in (-.52, .52):
        k.box((.04, .018, .36), (x, -.36, .205), "Canvas", 0)
    designs["Stacked Gym Mats"] = k
    k = Builder()
    for x in (-.45, .45):
        for y in (-.24, .24):
            k.box((.04, .04, .85), (x, y, .50), "Metal", .005)
            k.cylinder(.065, .045, (x, y, .065), "Metal", sides=8, wheel=True)
    for z in (.16, .68):
        for y in (-.24, .24):
            k.box((.94, .035, .035), (0, y, z), "Metal", 0)
        for x in (-.45, .45):
            k.box((.035, .51, .035), (x, 0, z), "Metal", 0)
    k.box((.90, .49, .035), (0, 0, .18), "Metal", .005)
    for x, color in ((-.28, "Art"), (0, "Art"), (.28, "Canvas")):
        k.sphere(.13, (x, 0, .33), color)
    k.box((.035, .035, .28), (.45, .33, .87), "Metal", 0)
    k.box((.52, .055, .055), (.205, .33, 1.0), "Metal", .008)
    designs["Ball Cart"] = k
    k = Builder()
    k.box((1.40, .08, .65), (0, 0, .325), "Metal", .018)
    k.box((1.30, .018, .55), (0, -.05, .325), "Cabinet", .005)
    for x in (-.40, -.16, .16, .40):
        for dx, z, sx, sz in ((0, .19, .14, .02), (0, .32, .14, .02),
                              (0, .45, .14, .02), (-.06, .385, .02, .11),
                              (.06, .255, .02, .11)):
            k.box((sx, .01, sz), (x+dx, -.065, z), "Art", 0)
    k.box((.36, .01, .035), (0, -.065, .555), "Canvas", 0)
    designs["Score Panel"] = k
    k = Builder()
    k.box((1.0, .055, .12), (0, 0, .06), "Laminate", .008)
    for x in (-.35, 0, .35):
        k.box((.04, .12, .025), (x, -.075, .035), "Metal", 0)
        k.box((.04, .025, .095), (x, -.125, .07), "Metal", .004)
    designs["Hook Rail"] = k
    k = Builder()
    for x in (-.25, .25):
        k.box((.055, .49, .64), (x, 0, .32), "Cabinet", .010)
    for y in (-.25, .25):
        k.box((.53, .045, .64), (0, y, .32), "Cabinet", .010)
    k.box((.52, .51, .035), (0, 0, .035), "Metal", 0)
    for y in (-.25, .25):
        k.box((.34, .013, .065), (0, y*1.10, .52), "Metal", .010)
    k.box((.31, .012, .12), (0, -.278, .30), "Canvas", 0)
    designs["Equipment Bin"] = k
    k = Builder()
    k.box((1.15, .065, .76), (0, 0, .38), "Laminate", .012)
    k.box((1.04, .018, .65), (0, -.045, .38), "Storage Cardboard", 0)
    for x, z, color in ((-.30, .47, "Canvas"), (.0, .40, "Medical White"), (.30, .43, "Art")):
        k.box((.24, .009, .33), (x, -.058, z), color, 0)
        k.box((.14, .009, .012), (x, -.064, z+.075), "Metal", 0)
    designs["Notice Board"] = k
    k = Builder()
    k.box((.36, .12, .58), (0, 0, .29), "Medical White", 0)
    k.box((.28, .02, .46), (0, -.075, .29), "Art", .010)
    k.cylinder(.065, .27, (0, -.10, .28), "Art", sides=8)
    k.box((.095, .026, .04), (0, -.115, .445), "Metal", .005)
    k.box((.025, .035, .22), (.09, -.103, .29), "Metal", 0)
    designs["Fire Cabinet"] = k
    # Reuse the existing small beveled dining bin rather than duplicating a design.
    meshes = {n: k.mesh(n, materials) for n, k in designs.items()}
    meshes["Trash Bin"] = bpy.data.meshes["School Dining Reading Kit - Trash Bin"]
    return meshes


def runtime_layout():
    src = (ROOT / "scenes/school_blockout_preview.gd").read_text(encoding="utf-8")
    room_src = src.split("func _create_locker_placeholders()")[1].split("func _create_ruler_hallway_lockers()")[0]
    hall_src = src.split("func _create_ruler_hallway_lockers()")[1].split("func _register_placed_locker_spots(")[0]
    fractions = [(float(a), float(b)) for a, b in re.findall(r"Vector2\((0\.\d+), (0\.\d+)\)", room_src)]
    if len(fractions) != 6:
        raise RuntimeError("Locker runtime convention changed: inspect before generating")
    for code, width in ((room_src, .82), (hall_src, 2.1)):
        for key, expected in (("width", width), ("depth", .78), ("height", 2.05)):
            actual = float(re.search(r"var "+key+r" := ([\d.]+)", code)[1])
            if actual != expected:
                raise RuntimeError("Locker dimensions changed")
        for token in ("_add_locker_model", "depth * 0.15", "depth + 0.72"):
            if token not in code:
                raise RuntimeError("Locker geometry/interaction convention changed")
    hall = {key: float(re.search(r"var "+key+r" := ([\d.]+)", hall_src)[1])
            for key in ("wall_x", "first_z", "last_z")}
    if "range(6)" not in hall_src:
        raise RuntimeError("Hall locker count changed")
    return fractions, hall


class Layout:
    def __init__(self, collections, meshes):
        self.collections, self.meshes = collections, meshes
        self.objects, self.lockers = [], []
        self.targets, self.obstacles, self.routes = {}, {}, {}
        self.reserved = []

    def place(self, room, design, x, y, angle=0, lift=0, index=None):
        i = sum(o["room_floor"] == room and o["prop_type"] == design for o in self.objects)+1
        prefix = ("Gym", "Locker Room", "East Hall")[ROOMS.index(room)]
        name = f"{prefix} - {design} {i:02d}"
        if bpy.data.objects.get(name):
            raise RuntimeError("Unowned object name conflict: "+name)
        o = bpy.data.objects.new(name, self.meshes[design])
        self.collections[ROOMS.index(room)].objects.link(o)
        o[TAG], o["room_floor"], o["prop_type"] = True, room, design
        o["collision_policy"] = "visual-only; functional runtime shell untouched"
        o["preview_collision_disabled"] = True
        if index is not None:
            o["runtime_locker_index"] = index
        floor = bpy.data.objects[room]
        z = bounds(floor)[2][1]
        # Hall lockers are intentionally at Science floor height in runtime.
        if "Locker Crown" in design and room == ROOMS[2]:
            z = bounds(bpy.data.objects["Science Classroom Floor"])[2][1]
        o.location = x, y, z+lift
        o.rotation_euler.z = angle
        bpy.context.view_layer.update()
        world = o.matrix_world.copy()
        o.parent = floor
        o.matrix_world = world
        self.objects.append(o)
        return o

    def target(self, room, label, p, radius=.5):
        self.targets.setdefault(room, []).append((label, p))
        if radius:
            self.reserved.append((room, label, p, radius))

    def furnish(self):
        gym, locker, hall_room = ROOMS
        (x0, x1), (y0, y1), _ = bounds(bpy.data.objects[gym])
        cx, cy = (x0+x1)/2, (y0+y1)/2
        self.place(gym, "Two Tier Bleachers", x0+1.0, cy, math.pi/2)
        self.place(gym, "Athletics Bench", x0+.65, y1-1.25, math.pi/2)
        self.place(gym, "Backboard and Hoop", x1-.25, cy, -math.pi/2, 2.75)
        for dy in (-1.05, 0, 1.05):
            self.place(gym, "Safety Padding", x0+.18, cy+dy, math.pi/2, .05)
        self.place(gym, "Stacked Gym Mats", x0+1.1, y0+.62)
        self.place(gym, "Ball Cart", x1-.82, y1-.75)
        self.place(gym, "Sports Shelf", x1-1.85, y1-.42)
        self.place(gym, "Score Panel", cx, y1-.25, 0, 3.10)
        self.target(gym, "Weight escape center", (cx, cy), 1.55)
        for dy in (-2.3, 2.3):
            self.target(gym, "Center court "+str(dy), (cx, cy+dy), .65)

        fractions, hall = runtime_layout()
        (x0, x1), (y0, y1), _ = bounds(bpy.data.objects[locker])
        cx = (x0+x1)/2
        weight = (cx, y1-(y1-y0)*.12)
        self.target(locker, "Weight pickup", weight, .68)
        self.target(locker, "Patrol north", (cx, y1-(y1-y0)*.16), .5)
        self.target(locker, "Patrol south", (cx, y1-(y1-y0)*.84), .5)
        for i, (u, v) in enumerate(fractions):
            x, y = x0+(x1-x0)*u, y1-(y1-y0)*v
            inward = 1 if u < .5 else -1
            obj = self.place(locker, "Locker Crown", x, y, inward*math.pi/2, index=i+12)
            self.lockers.append({"object": obj.name, "room": locker, "center": (x, y),
                                 "inside": (x+inward*.117, y), "outside": (x+inward*1.5, y),
                                 "normal": inward, "width": .82, "index": i+12})
            self.target(locker, f"Locker {i+1} outside", (x+inward*1.5, y), .48)
        self.place(locker, "Athletics Bench", x0+.40, y0+3.80, math.pi/2)
        self.place(locker, "Changing Bench", x1-.90, y1-.49)
        self.place(locker, "Sports Shelf", x0+.85, y1-.44)
        self.place(locker, "Towel Shelf", x1-.43, y0+3.08, -math.pi/2)
        self.place(locker, "Equipment Bin", x0+.45, y0+.67)
        self.place(locker, "Hook Rail", x0+.19, y0+3.80, math.pi/2, 1.53)
        self.place(locker, "Hook Rail", x1-.90, y1-.28, 0, 1.53)

        for i in range(6):
            x, y = hall["wall_x"], -(hall["first_z"]+(hall["last_z"]-hall["first_z"])*i/5)
            obj = self.place(hall_room, "Hall Locker Crown", x, y, -math.pi/2, index=i)
            self.lockers.append({"object": obj.name, "room": hall_room, "center": (x, y),
                                 "inside": (x-.117, y), "outside": (x-1.5, y),
                                 "normal": -1, "width": 2.1, "index": i})
            self.target(hall_room, f"Ruler locker {i+1} outside", (x-1.5, y), .48)
        exterior = bounds(bpy.data.objects["School - East Exterior Wall"])
        wall_x = exterior[0][0]
        self.place(hall_room, "Notice Board", wall_x-.10, -18.05, -math.pi/2, 1.10)
        self.place(hall_room, "Fire Cabinet", wall_x-.12, -.95, -math.pi/2, 1.05)
        self.place(hall_room, "Trash Bin", wall_x-.36, -19.05)
        # These are the unchanged explicit targets in _start_ruler_hall_event.
        z_min, z_max = hall["first_z"]-1.05, hall["last_z"]+1.05
        for label, x, z in (("Pass A", 38.2, z_min-.35), ("Pass Science", 38.2, z_max+.35),
                            ("Corner A", 36.5, z_min-.35), ("Corner Science", 36.5, z_max+.35)):
            self.target(hall_room, label, (x, -z), .65)
        self.target(hall_room, "Hall south connection", (38.2, -19.0), .55)
        self.target(hall_room, "Hall north connection", (38.2, -.60), .55)
        science_door = bounds(bpy.data.objects["Door Header Wall Infill - Science Classroom - 15"])
        a_door = bounds(bpy.data.objects["Door Header Wall Infill - Classroom A - 11"])
        self.target(hall_room, "Science doorway approach", (sum(science_door[0])/2, sum(science_door[1])/2-1.1), .55)
        self.target(hall_room, "Classroom A doorway approach", (sum(a_door[0])/2, sum(a_door[1])/2-.9), .55)
        self.target(hall_room, "Classroom B door approach", (37.316, -.15), .50)
        self.obstacles = {room: [] for room in ROOMS}
        # Current runtime boxes, with the same orientation as each locker.
        for s in self.lockers:
            x, y = s["center"]
            w = s["width"]
            self.obstacles[s["room"]].append(((x-.39,x+.39),(y-w/2,y+w/2)))
        # Conservatively account for the classroom walls bounding the east hall.
        for name in ("Science Classroom Floor", "Lab Room Floor"):
            rb = bounds(bpy.data.objects[name])
            self.obstacles[hall_room].append(((rb[0][0]-.11, rb[0][1]+.11),
                                              (rb[1][0]-.11, rb[1][1]+.11)))

    def validate(self):
        bpy.context.view_layer.update()
        errors = []
        for o in self.objects:
            ob, room = bounds(o), o["room_floor"]
            if "Locker Crown" in o["prop_type"]:
                # Mouth cross-section remains the original .72 / 2.0 m wide.
                s = next(s for s in self.lockers if s["object"] == o.name)
                if s["width"]-.114 < .70:
                    errors.append("Locker mouth narrowed")
            elif room != ROOMS[2]:
                fb = bounds(bpy.data.objects[room])
                if any(ob[i][0] < fb[i][0]+.12 or ob[i][1] > fb[i][1]-.12 for i in (0, 1)):
                    errors.append("Room perimeter: "+o.name)
            # Above-head fixtures are excluded from floor route footprints.
            if ob[2][0] >= 2.35:
                continue
            for r, label, p, radius in self.reserved:
                if r == room and distance(p, ob) < radius:
                    errors.append(o.name+" encroaches "+label)
            for door in bpy.data.objects:
                if not door.name.startswith("Door Header"):
                    continue
                db = bounds(door)
                margins = (.35, 1.10) if db[0][1]-db[0][0] > db[1][1]-db[1][0] else (1.10, .35)
                if "Locker Crown" in o["prop_type"]:
                    # Locker 5 already lies 20 cm past the hallway doorway.
                    # Keep that existing alignment; the skin adds only 7 mm.
                    margins = (.15, 1.10) if db[0][1]-db[0][0] > db[1][1]-db[1][0] else (1.10, .15)
                if all(ob[i][1] > db[i][0]-margins[i] and ob[i][0] < db[i][1]+margins[i] for i in (0, 1)):
                    errors.append(o.name+" blocks "+door.name)
            # No cross-object clipping. Hook rails mounted above benches are safe.
            for other in self.objects:
                if other.name <= o.name or other["room_floor"] != room:
                    continue
                bb = bounds(other)
                if all(ob[i][1] > bb[i][0]+.002 and bb[i][1] > ob[i][0]+.002 for i in range(3)):
                    errors.append("Clipping: "+o.name+" / "+other.name)
        if errors:
            raise RuntimeError("Placement rejected:\n"+"\n".join(errors))
        for room in ROOMS:
            self.check_routes(room)
        # Direct patrol and Monster row-pass segments are reserved, not just
        # alternative flood-fill connections around furniture.
        for room, labels in ((ROOMS[1], ("Patrol north", "Patrol south")),
                             (ROOMS[2], ("Pass A", "Pass Science"))):
            points = dict(self.targets[room])
            a, b = points[labels[0]], points[labels[1]]
            obstacles = self.route_obstacles(room)
            for i in range(401):
                p = tuple(a[j]+(b[j]-a[j])*i/400 for j in (0, 1))
                if any(distance(p, bb) < .45 for bb in obstacles):
                    raise RuntimeError("Direct Monster route blocked: "+room)

    def route_obstacles(self, room):
        result = list(self.obstacles[room])
        for o in self.objects:
            if o["room_floor"] != room or "Locker Crown" in o["prop_type"]:
                continue
            bb = bounds(o)
            if bb[2][0] < 2.35:
                result.append(bb[:2])
        return result

    def check_routes(self, room):
        fb = bounds(bpy.data.objects[room])
        targets = list(self.targets[room])
        if room == ROOMS[2]:
            # Corridor cutout on the actual circulation floor, including turns.
            science = bounds(bpy.data.objects["Science Classroom Floor"])
            classroom = bounds(bpy.data.objects["Classroom B Floor"])
            exterior = bounds(bpy.data.objects["School - East Exterior Wall"])
            x0, x1 = science[0][0]-.11, exterior[0][0]
            y0, y1 = exterior[1][0]+.09, classroom[1][0]-.11
        else:
            (x0, x1), (y0, y1), _ = fb
            for o in bpy.data.objects:
                if not o.name.startswith("Door Header"):
                    continue
                db = bounds(o)
                if all(db[i][1] >= fb[i][0]-.22 and db[i][0] <= fb[i][1]+.22 for i in (0, 1)):
                    p = (sum(db[0])/2, sum(db[1])/2)
                    targets.append((o.name, p))
        obstacles = self.route_obstacles(room)
        for radius in (.24, .45):
            step, inset = .05, radius+.12
            def point(c):
                return x0+inset+c[0]*step, y0+inset+c[1]*step
            free = set()
            for i in range(int((x1-x0-2*inset)/step)+1):
                for j in range(int((y1-y0-2*inset)/step)+1):
                    if all(distance(point((i, j)), b) >= radius for b in obstacles):
                        free.add((i, j))
            actual_targets = []
            for label, p in targets:
                if label.startswith("Door Header"):
                    p = (min(x1-inset, max(x0+inset, p[0])), min(y1-inset, max(y0+inset, p[1])))
                c = min(free, key=lambda c: math.dist(point(c), p))
                if math.dist(point(c), p) > .12:
                    raise RuntimeError("Blocked route endpoint: "+label)
                actual_targets.append((label, c))
            start = actual_targets[0][1]
            queue, seen, parents = deque([start]), {start}, {start: None}
            while queue:
                i, j = queue.popleft()
                for c in ((i-1, j), (i+1, j), (i, j-1), (i, j+1)):
                    if c in free and c not in seen:
                        seen.add(c)
                        queue.append(c)
                        parents[c] = (i, j)
            if any(c not in seen for _, c in actual_targets):
                raise RuntimeError("Routes disconnected: "+room)
            if radius == .24:
                self.routes[room] = {}
                for label, c in actual_targets:
                    path = []
                    while c is not None:
                        path.append(point(c))
                        c = parents[c]
                    path.reverse()
                    compact = [path[0]]
                    for j in range(1, len(path)-1):
                        a = tuple(round(path[j][k]-path[j-1][k], 3) for k in (0, 1))
                        b = tuple(round(path[j+1][k]-path[j][k], 3) for k in (0, 1))
                        if a != b:
                            compact.append(path[j])
                    compact.append(path[-1])
                    self.routes[room][label] = compact
            print("ROUTE_CLEAR", room, "width", radius*2, "targets", len(actual_targets))


def distance(p, bb):
    return math.hypot(max(bb[0][0]-p[0], 0, p[0]-bb[0][1]),
                      max(bb[1][0]-p[1], 0, p[1]-bb[1][1]))


def main():
    if Path(bpy.data.filepath).name != "assets.blend":
        raise RuntimeError("Open the current assets.blend")
    school = bpy.data.collections["After School - School Blockout"]
    for name in ROOMS+("Science Classroom Floor", "School - East Exterior Wall"):
        if not bpy.data.objects.get(name):
            raise RuntimeError("Actual school geometry missing: "+name)
    if not bpy.data.collections.get("School Props - Shared"):
        raise RuntimeError("Existing shared kit missing")
    runtime_layout()  # Validate convention before replacing anything.
    for name in GROUPS:
        c = bpy.data.collections.get(name)
        if c and (not c.get(TAG) or c.children or any(not o.get(TAG) for o in c.objects)):
            raise RuntimeError("Refusing unowned collection: "+name)
    for name in GROUPS:
        c = bpy.data.collections.get(name)
        if c:
            for o in list(c.objects):
                bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.collections.remove(c)
    for mesh in list(bpy.data.meshes):
        if mesh.get(TAG) and mesh.users == 0:
            bpy.data.meshes.remove(mesh)
    collections = []
    for name in GROUPS:
        c = bpy.data.collections.new(name)
        c[TAG] = True
        school.children.link(c)
        collections.append(c)
    keys = ("Laminate", "Metal", "Chair", "Cabinet", "Canvas", "Art",
            "Medical White", "Medical Vinyl", "Storage Cardboard")
    materials = {key: bpy.data.materials["School Props - "+key] for key in keys}
    meshes = kit(materials)
    layout = Layout(collections, meshes)
    layout.furnish()
    layout.validate()
    stats = {"instances": len(layout.objects), "designs": len(meshes),
             "new_designs": sum(bool(m.get(TAG)) for m in meshes.values()),
             "materials_added": 0, "materials_reused": len(materials),
             "rooms": dict(Counter(o["room_floor"] for o in layout.objects)),
             "types": dict(Counter(o["prop_type"] for o in layout.objects)),
             "triangles_per_design": {n: len(m.loop_triangles) for n, m in meshes.items()},
             "instanced_triangles": sum(len(o.data.loop_triangles) for o in layout.objects)}
    report = {"stats": stats, "targets": layout.targets, "reserved": layout.reserved,
              "lockers": layout.lockers, "routes": layout.routes,
              "objects": {o.name: {"room": o["room_floor"], "type": o["prop_type"],
                                    "bounds": bounds(o), "matrix": [list(r) for r in o.matrix_world],
                                    "mesh": o.data.name} for o in layout.objects}}
    folder = Path(os.environ.get("TEMP", "/tmp"))/"final-school-polish-review"
    folder.mkdir(exist_ok=True)
    (folder/"props_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("ATHLETICS_PROPS", json.dumps(stats, sort_keys=True))


if __name__ == "__main__":
    main()
