"""Open the blockout's west/south yard boundary and add schoolyard props.

Run with Blender: blender --background assets.blend --python add_outdoor_yard.py
"""
from math import cos, pi, sin
from pathlib import Path
import random
import bpy

ROOT = Path(bpy.data.filepath).parent
COLLECTION_NAME = "School Props - Outdoor Yard"
YARD_BOUNDS = (-4.93, 9.60, -27.76, -6.13)
GATE_CENTER_X = (YARD_BOUNDS[0] + YARD_BOUNDS[1]) * 0.5
GATE_Y = YARD_BOUNDS[2] + 0.05


def material(name, color, roughness=0.78, metallic=0.0, alpha=1.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, alpha)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, alpha)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Alpha"].default_value = alpha
    if alpha < 1.0:
        mat.surface_render_method = "BLENDED"
    return mat


def mesh_object(name, verts, faces, mat, collection):
    mesh = bpy.data.meshes.new(name + " Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    return obj


def add_box(name, center, size, mat, collection, rotation=0.0):
    cx, cy, cz = center
    sx, sy, sz = (v * 0.5 for v in size)
    verts = [(-sx,-sy,-sz),(sx,-sy,-sz),(sx,sy,-sz),(-sx,sy,-sz),
             (-sx,-sy,sz),(sx,-sy,sz),(sx,sy,sz),(-sx,sy,sz)]
    c, s = cos(rotation), sin(rotation)
    verts = [(cx + x*c - y*s, cy + x*s + y*c, cz + z) for x,y,z in verts]
    faces = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    return mesh_object(name, verts, faces, mat, collection)


def add_cylinder(name, center, radius, depth, mat, collection, sides=12, radius_top=None):
    top_radius = radius if radius_top is None else radius_top
    cx, cy, cz = center
    verts = []
    for z, r in ((-depth*0.5, radius), (depth*0.5, top_radius)):
        for i in range(sides):
            angle = 2*pi*i/sides
            verts.append((cx+r*cos(angle), cy+r*sin(angle), cz+z))
    faces = [tuple(range(sides-1,-1,-1)), tuple(range(sides,2*sides))]
    for i in range(sides):
        j = (i+1) % sides
        faces.append((i,j,sides+j,sides+i))
    return mesh_object(name, verts, faces, mat, collection)


def add_beam(name, a, b, radius, mat, collection, sides=8):
    ax, ay, az = a
    bx, by, bz = b
    dx, dy, dz = bx-ax, by-ay, bz-az
    length = (dx*dx + dy*dy + dz*dz) ** 0.5
    obj = add_cylinder(name, ((ax+bx)*0.5,(ay+by)*0.5,(az+bz)*0.5), radius, length, mat, collection, sides)
    obj.rotation_mode = "QUATERNION"
    from mathutils import Vector
    obj.rotation_quaternion = Vector((0,0,1)).rotation_difference(Vector((dx,dy,dz)).normalized())
    return obj


def append_box(verts, faces, center, size):
    cx, cy, cz = center
    sx, sy, sz = (value * 0.5 for value in size)
    base = len(verts)
    verts.extend(((cx-sx,cy-sy,cz-sz),(cx+sx,cy-sy,cz-sz),
                  (cx+sx,cy+sy,cz-sz),(cx-sx,cy+sy,cz-sz),
                  (cx-sx,cy-sy,cz+sz),(cx+sx,cy-sy,cz+sz),
                  (cx+sx,cy+sy,cz+sz),(cx-sx,cy+sy,cz+sz)))
    faces.extend(tuple(base+i for i in face) for face in (
        (0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)))


def add_tree(name, x, y, collection, bark, leaves):
    add_cylinder(name + " - Trunk", (x,y,1.25), 0.20, 2.5, bark, collection, 10, 0.14)
    for index, (z, radius, height) in enumerate(((2.45,1.15,1.55),(3.25,0.92,1.45),(3.95,0.60,1.20))):
        add_cylinder(name + " - Canopy %02d" % (index+1), (x,y,z), radius, height, leaves, collection, 9, 0.0)


def add_gate(collection, iron, post_mat):
    # A pair of open iron leaves leaves a walk-through gap at the south boundary.
    opening = 4.2
    left_hinge = GATE_CENTER_X - opening*0.5
    right_hinge = GATE_CENTER_X + opening*0.5
    for x, side in ((left_hinge, "West"), (right_hinge, "East")):
        add_cylinder("Outdoor Gate - %s Post" % side, (x,GATE_Y,1.10), 0.10, 2.20, post_mat, collection, 12)

    def gate_leaf(name, hinge_x, direction, angle):
        width, height = opening*0.5, 1.92
        # The local leaf extends away from its hinge; open angles swing toward +Y.
        x_end = direction * width
        rails = [
            (-0.03, x_end + direction*0.03, 0.0, 0.12),
            (-0.03, x_end + direction*0.03, 1.78, 1.90),
            (-0.03, x_end + direction*0.03, 0.86, 0.98),
        ]
        verts, faces = [], []
        for x0, x1, z0, z1 in rails:
            base = len(verts)
            verts.extend(((x0,0.0,z0),(x1,0.0,z0),(x1,0.0,z1),(x0,0.0,z1),
                          (x0,0.06,z0),(x1,0.06,z0),(x1,0.06,z1),(x0,0.06,z1)))
            faces.extend(tuple(base+i for i in face) for face in (
                (0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)))
        bars = 9
        for i in range(bars):
            local_x = direction * (0.12 + (width-0.24)*i/(bars-1))
            base = len(verts)
            verts.extend(((local_x-0.035,0.0,0.12),(local_x+0.035,0.0,0.12),
                          (local_x+0.035,0.0,1.78),(local_x-0.035,0.0,1.78),
                          (local_x-0.035,0.06,0.12),(local_x+0.035,0.06,0.12),
                          (local_x+0.035,0.06,1.78),(local_x-0.035,0.06,1.78)))
            faces.extend(tuple(base+i for i in face) for face in (
                (0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)))
        leaf = mesh_object(name, verts, faces, iron, collection)
        leaf.location = (hinge_x, GATE_Y, 0.0)
        leaf.rotation_euler.z = angle
        return leaf

    gate_leaf("Outdoor Gate - West Leaf Closed", left_hinge, 1.0, 0.0)
    gate_leaf("Outdoor Gate - East Leaf Closed", right_hinge, -1.0, 0.0)


def add_fence_segment(name, start, end, along_x, collection, iron):
    """Build one picket fence span in the same footprint as a hidden yard wall."""
    x0, y0 = start
    x1, y1 = end
    length = abs(x1-x0) if along_x else abs(y1-y0)
    if length < 0.15:
        return
    count = max(1, int(length / 0.27))
    verts, faces = [], []
    if along_x:
        low, high = sorted((x0,x1))
        center_y = y0
        append_box(verts, faces, ((low+high)*0.5,center_y,2.0), (length,0.08,0.10))
        append_box(verts, faces, ((low+high)*0.5,center_y,0.18), (length,0.08,0.10))
        for index in range(count+1):
            x = low + length*index/count
            append_box(verts, faces, (x,center_y,1.10), (0.075,0.075,2.10))
    else:
        low, high = sorted((y0,y1))
        center_x = x0
        append_box(verts, faces, (center_x,(low+high)*0.5,2.0), (0.08,length,0.10))
        append_box(verts, faces, (center_x,(low+high)*0.5,0.18), (0.08,length,0.10))
        for index in range(count+1):
            y = low + length*index/count
            append_box(verts, faces, (center_x,y,1.10), (0.075,0.075,2.10))
    mesh_object(name, verts, faces, iron, collection)


def add_yard_perimeter_fence(collection, iron):
    west_x = -4.78
    south_y = GATE_Y
    opening = 4.2
    left_hinge = GATE_CENTER_X - opening*0.5
    right_hinge = GATE_CENTER_X + opening*0.5
    add_fence_segment("Yard Perimeter Fence - West", (west_x,YARD_BOUNDS[2]), (west_x,YARD_BOUNDS[3]), False, collection, iron)
    add_fence_segment("Yard Perimeter Fence - South West", (YARD_BOUNDS[0],south_y), (left_hinge,south_y), True, collection, iron)
    add_fence_segment("Yard Perimeter Fence - South East", (right_hinge,south_y), (YARD_BOUNDS[1],south_y), True, collection, iron)


def add_basketball_hoop(collection, iron, board, rim):
    x, y = 6.7, -9.0
    add_box("Yard Basketball Hoop - Base", (x,y,0.17), (0.72,0.82,0.28), iron, collection)
    add_cylinder("Yard Basketball Hoop - Pole", (x,y,1.72), 0.07, 3.1, iron, collection, 12, 0.055)
    add_box("Yard Basketball Hoop - Backboard", (x,y-0.43,3.38), (1.20,0.10,0.78), board, collection)
    # Front rim extends south into the play area; the ring sits horizontally.
    ring_verts, ring_faces = [], []
    major_segments, minor_segments = 24, 8
    major_radius, tube_radius = 0.43, 0.035
    for i in range(major_segments):
        theta = 2*pi*i/major_segments
        for j in range(minor_segments):
            phi = 2*pi*j/minor_segments
            radial = major_radius + tube_radius*cos(phi)
            ring_verts.append((x+radial*cos(theta), y-0.90+radial*sin(theta), 3.02+tube_radius*sin(phi)))
    for i in range(major_segments):
        for j in range(minor_segments):
            a = i*minor_segments+j
            b = i*minor_segments+(j+1)%minor_segments
            c = ((i+1)%major_segments)*minor_segments+(j+1)%minor_segments
            d = ((i+1)%major_segments)*minor_segments+j
            ring_faces.append((a,b,c,d))
    mesh_object("Yard Basketball Hoop - Rim", ring_verts, ring_faces, rim, collection)
    add_box("Yard Basketball Hoop - Backboard Target", (x,y-0.495,3.34), (0.44,0.015,0.30), rim, collection)


def add_bench(name, x, y, collection, wood, iron):
    add_box(name + " - Seat", (x,y,0.58), (2.15,0.42,0.12), wood, collection)
    add_box(name + " - Back", (x,y+0.20,1.03), (2.15,0.10,0.76), wood, collection)
    for side in (-1,1):
        bx = x + side*0.78
        add_box(name + " - Leg", (bx,y,0.30), (0.12,0.46,0.58), iron, collection)
        add_box(name + " - Back Support", (bx,y+0.16,0.77), (0.10,0.12,0.78), iron, collection)


def add_soccer_goal(collection, iron):
    x, y, half_width, depth, height = 2.0, -18.0, 1.65, 1.10, 1.75
    z = 0.12
    add_beam("Yard Soccer Goal - Crossbar", (x-half_width,y,z+height), (x+half_width,y,z+height), 0.045, iron, collection)
    for side in (-1,1):
        gx = x + side*half_width
        add_beam("Yard Soccer Goal - Post", (gx,y,z), (gx,y,z+height), 0.045, iron, collection)
        add_beam("Yard Soccer Goal - Depth Bar", (gx,y,z+height), (gx,y+depth,z+height), 0.04, iron, collection)
        add_beam("Yard Soccer Goal - Ground Bar", (gx,y,z), (gx,y+depth,z), 0.035, iron, collection)
    add_beam("Yard Soccer Goal - Rear Bar", (x-half_width,y+depth,z+height), (x+half_width,y+depth,z+height), 0.035, iron, collection)


def add_star_field(collection):
    rng = random.Random(440)
    verts, faces = [], []
    segments, rings = 8, 4
    for _ in range(84):
        cx = 2.3 + rng.uniform(-15.0, 15.0)
        cy = -16.9 + rng.uniform(-21.0, 21.0)
        cz = rng.uniform(10.0, 15.5)
        radius = rng.uniform(0.045, 0.085)
        base = len(verts)
        verts.append((cx,cy,cz+radius))
        for ring in range(1, rings):
            phi = pi*ring/rings
            ring_radius = radius*sin(phi)
            z = cz + radius*cos(phi)
            for segment in range(segments):
                theta = 2*pi*segment/segments
                verts.append((cx+ring_radius*cos(theta),cy+ring_radius*sin(theta),z))
        bottom = len(verts)
        verts.append((cx,cy,cz-radius))
        first_ring = base + 1
        for segment in range(segments):
            next_segment = (segment+1) % segments
            faces.append((base,first_ring+segment,first_ring+next_segment))
        for ring in range(rings-2):
            ring_a = first_ring + ring*segments
            ring_b = ring_a + segments
            for segment in range(segments):
                next_segment = (segment+1) % segments
                faces.extend(((ring_a+segment,ring_b+segment,ring_b+next_segment),
                              (ring_a+segment,ring_b+next_segment,ring_a+next_segment)))
        last_ring = first_ring + (rings-2)*segments
        for segment in range(segments):
            next_segment = (segment+1) % segments
            faces.append((last_ring+segment,bottom,last_ring+next_segment))
    stars = mesh_object("Yard Sky - White Star Dots", verts, faces,
                        material("Yard Sky - Soft White Emission", (1.0,0.98,0.90), 0.45), collection)
    bsdf = stars.data.materials[0].node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Emission Color"].default_value = (1.0,0.98,0.90,1.0)
        bsdf.inputs["Emission Strength"].default_value = 2.5
    stars.visible_shadow = False
    stars["preview_collision_disabled"] = True


def main():
    collection = bpy.data.collections.get(COLLECTION_NAME)
    if collection is None:
        collection = bpy.data.collections.new(COLLECTION_NAME)
        bpy.context.scene.collection.children.link(collection)
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    # Keep the invisible boundaries as optional Blender references, but make
    # them transparent in the exported model and exclude them from preview collision.
    invisible = material("School - Invisible Outdoor Boundary", (0.08,0.08,0.08), alpha=0.0)
    for wall_name in ("Outside - West Wall", "Outside - South Wall"):
        wall = bpy.data.objects.get(wall_name)
        if wall is None:
            raise RuntimeError("Missing expected outdoor wall: " + wall_name)
        wall.data.materials.clear()
        wall.data.materials.append(invisible)
        for polygon in wall.data.polygons:
            polygon.material_index = 0
        wall["preview_collision_disabled"] = True
        wall.hide_render = True
        wall.hide_set(True)

    bark = material("Yard - Bark", (0.24,0.12,0.055))
    leaves = material("Yard - Deep Green Leaves", (0.12,0.34,0.12))
    iron = material("Yard - Graphite Painted Steel", (0.12,0.16,0.18), 0.38, 0.7)
    post_mat = material("Yard - Gate Post Steel", (0.22,0.25,0.24), 0.42, 0.65)
    wood = material("Yard - Bench Timber", (0.42,0.25,0.12))
    board = material("Yard - Basketball Backboard", (0.82,0.85,0.78), 0.55)
    rim = material("Yard - Basketball Orange", (0.88,0.24,0.055), 0.43)

    add_yard_perimeter_fence(collection, iron)
    add_gate(collection, iron, post_mat)
    for name, x, y in (
        ("Yard Tree - West North", -4.10, -10.0),
        ("Yard Tree - West Middle", -4.10, -16.8),
        ("Yard Tree - West South", -4.10, -23.1),
        ("Yard Tree - East North", 8.45, -11.0),
        ("Yard Tree - East South", 8.45, -23.0),
    ):
        add_tree(name, x, y, collection, bark, leaves)
    add_basketball_hoop(collection, iron, board, rim)
    add_soccer_goal(collection, iron)
    add_bench("Yard Bench - North", 0.0, -13.5, collection, wood, iron)
    add_bench("Yard Bench - South", 6.5, -22.0, collection, wood, iron)
    add_star_field(collection)

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("Outdoor yard updated: west/south perimeter fence with closed gate, 5 trees, sports equipment, 2 benches, and 84 white sky stars")


main()
