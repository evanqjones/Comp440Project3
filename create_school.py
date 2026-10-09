import bpy
import math
from mathutils import Vector


# Rebuild the editable school blockout from the normalized hand-drawn plan.
# The source assets.blend is loaded by Blender before this script and is kept
# intact; this script saves a new School.blend alongside it.

OUT = bpy.path.abspath('//School.blend')
S = 0.04  # art scale only; map coordinates remain normalized proportions
WALL_H = 3.0
WALL_T = 0.22
FLOOR_H = 0.12


def clear_generated():
    col = bpy.data.collections.get('After School - School Blockout')
    if col:
        for obj in list(col.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(col)
    for name in ('School Map Notes',):
        txt = bpy.data.texts.get(name)
        if txt:
            bpy.data.texts.remove(txt)


def make_collection(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def material(name, color, roughness=0.82, emission=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Roughness'].default_value = roughness
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*color, 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission
    return mat


def add_box_mesh(mesh_data, x0, x1, y0, y1, z0, z1):
    # All coordinates here are already scaled to meters.
    base = len(mesh_data[0])
    verts, faces = mesh_data
    verts.extend([
        (x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
        (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1),
    ])
    faces.extend([
        (base+0, base+3, base+2, base+1), (base+4, base+5, base+6, base+7),
        (base+0, base+1, base+5, base+4), (base+1, base+2, base+6, base+5),
        (base+2, base+3, base+7, base+6), (base+3, base+0, base+4, base+7),
    ])


def make_mesh_object(name, data, mat, collection):
    mesh = bpy.data.meshes.new(name + ' Mesh')
    mesh.from_pydata(data[0], [], data[1])
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    return obj


def add_cube(name, center, dims, mat, collection):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def room_bounds(label, x, top, w, h, openings=None, floor_mat=None, walls=True):
    return {'label': label, 'x': x, 'top': top, 'w': w, 'h': h,
            'openings': openings or {}, 'floor_mat': floor_mat, 'walls': walls}


def add_text(label, x, y, z, size, mat, collection):
    curve = bpy.data.curves.new(label + ' Label', 'FONT')
    curve.body = label
    curve.align_x = 'CENTER'
    curve.align_y = 'CENTER'
    curve.size = size
    curve.extrude = 0.0
    obj = bpy.data.objects.new(label + ' Label', curve)
    obj.location = (x, y, z)
    obj.data.materials.append(mat)
    collection.objects.link(obj)
    return obj


def build():
    clear_generated()
    scene = bpy.context.scene
    root = make_collection('After School - School Blockout')
    ground_col = bpy.data.collections.new('01 - Ground and room floors')
    wall_col = bpy.data.collections.new('02 - Walls and partitions')
    label_col = bpy.data.collections.new('03 - Room labels')
    root.children.link(ground_col)
    root.children.link(wall_col)
    root.children.link(label_col)

    mat_ground = material('Corridor - cool concrete', (0.18, 0.22, 0.29))
    mat_outside = material('Outside - muted grass', (0.20, 0.30, 0.24))
    mat_floor_a = material('Room floor - slate', (0.37, 0.40, 0.43))
    mat_floor_b = material('Room floor - alternate slate', (0.33, 0.37, 0.41))
    mat_cafe = material('Cafe floor - muted tile', (0.39, 0.38, 0.33))
    mat_kitchen = material('Kitchen floor - tile', (0.48, 0.46, 0.39))
    mat_lobby = material('Lobby floor - worn tile', (0.40, 0.41, 0.41))
    mat_walls = material('Walls - blue gray plaster', (0.55, 0.59, 0.63))
    mat_label = material('Room lettering - charcoal', (0.045, 0.065, 0.085), emission=0.12)

    # Coordinates follow the reference page: x right, y downward.
    rooms = [
        room_bounds('Locker Room', 0, 95, 140, 125,
                    {'south': [(75, 112)]}, mat_floor_b),
        room_bounds('Auditorium', 265, 20, 240, 95,
                    {'south': [(95, 145)]}, mat_floor_a),
        room_bounds('Bathroom', 600, 25, 170, 95,
                    {'south': [(63, 104)]}, mat_floor_b),
        room_bounds('Cafeteria', 770, 0, 175, 120,
                    {'south': [(64, 108)]}, mat_floor_a),
        room_bounds('Gym', 40, 205, 265, 235,
                    {'east': [(164, 207)], 'south': [(195, 235)]}, mat_floor_b),
        room_bounds('Library', 340, 125, 280, 120,
                    {'west': [(48, 88)], 'south': [(133, 178)]}, mat_floor_a),
        room_bounds('Classroom', 645, 125, 170, 120,
                    {'south': [(62, 104)]}, mat_floor_b),
        room_bounds('Classroom', 810, 120, 175, 125,
                    {'south': [(65, 108)]}, mat_floor_a),
        room_bounds('Cafe', 340, 260, 280, 175,
                    {'north': [(20, 55), (145, 180)], 'south': [(104, 148)]}, mat_cafe),
        room_bounds('Kitchen', 495, 275, 120, 75,
                    {'west': [(29, 52)]}, mat_kitchen),
        room_bounds('Lab Room', 645, 255, 330, 125,
                    {'north': [(54, 94)], 'south': [(270, 308)]}, mat_floor_b),
        room_bounds('Science Classroom', 645, 380, 330, 125,
                    {'north': [(270, 308)], 'south': [(95, 139), (268, 310)]}, mat_floor_a),
        room_bounds('Outside', 140, 445, 165, 320, {}, mat_outside, walls=False),
        room_bounds('Classroom', 335, 445, 145, 155,
                    {'south': [(54, 92)]}, mat_floor_b),
        room_bounds('Classroom', 480, 445, 145, 155,
                    {'south': [(54, 92)]}, mat_floor_a),
        room_bounds('Classroom', 665, 510, 320, 165,
                    {'south': [(147, 195)]}, mat_floor_b),
        room_bounds('Lobby', 300, 580, 640, 190,
                    {'south': [(266, 316)]}, mat_lobby, walls=False),
        room_bounds('Nurse Office', 895, 650, 100, 105,
                    {'north': [(30, 68)], 'south': [(32, 68)]}, mat_floor_a),
        room_bounds('Main Office', 675, 745, 325, 145,
                    {'north': [(64, 108)], 'west': [(30, 67)]}, mat_floor_b),
    ]

    # Unified site slab and colored room footprints; no furniture or extra rooms.
    site = [([], [])]
    # Base under the complete plan footprint, including the circulation bands.
    add_box_mesh(site[0], -30*S, 1015*S, -915*S, 35*S, -0.14, -0.015)
    # Floor tiles sit above the slab, clearly distinguishing rooms from corridors.
    for i, room in enumerate(rooms):
        x, top, w, h = room['x'], room['top'], room['w'], room['h']
        add_box_mesh(site[0], x*S, (x+w)*S, -(top+h)*S, -top*S, -0.005, FLOOR_H)
    make_mesh_object('Ground slab and mapped room floors', site[0], mat_ground, ground_col)
    # Apply per-room floor materials using individual thin tile meshes on top of the base.
    floor_data = {}
    for room in rooms:
        mat = room['floor_mat']
        floor_data.setdefault(mat.name, [mat, ([], [])])
        x, top, w, h = room['x'], room['top'], room['w'], room['h']
        add_box_mesh(floor_data[mat.name][1], x*S, (x+w)*S, -(top+h)*S, -top*S,
                     FLOOR_H + 0.001, FLOOR_H + 0.018)
    for name, (mat, data) in floor_data.items():
        make_mesh_object(name, data, mat, ground_col)

    # Build wall segments and leave the reference's indicated doorways open.
    wall_data = ([], [])

    def emit_h(y, x0, x1):
        if x1 <= x0:
            return
        add_box_mesh(wall_data, x0*S, x1*S, y*S-WALL_T/2, y*S+WALL_T/2, FLOOR_H, FLOOR_H+WALL_H)

    def emit_v(x, y0, y1):
        if y1 <= y0:
            return
        add_box_mesh(wall_data, x*S-WALL_T/2, x*S+WALL_T/2, -y1*S, -y0*S, FLOOR_H, FLOOR_H+WALL_H)

    def segment_with_gaps(start, end, gaps):
        cursor = start
        for a, b in sorted(gaps):
            a = max(start, min(end, a))
            b = max(start, min(end, b))
            if a > cursor:
                yield cursor, a
            cursor = max(cursor, b)
        if cursor < end:
            yield cursor, end

    for room in rooms:
        if not room['walls']:
            continue
        x, t, w, h = room['x'], room['top'], room['w'], room['h']
        op = room['openings']
        for a, b in segment_with_gaps(x, x+w, op.get('north', [])):
            emit_h(-t, a, b)
        for a, b in segment_with_gaps(x, x+w, op.get('south', [])):
            emit_h(-(t+h), a, b)
        for a, b in segment_with_gaps(t, t+h, op.get('west', [])):
            emit_v(x, a, b)
        for a, b in segment_with_gaps(t, t+h, op.get('east', [])):
            emit_v(x+w, a, b)
    # South edge of the broad Lobby is an exterior boundary in the sketch.
    # Leave the marked Entrance threshold open and stop before Main Office.
    emit_h(-745, 300, 560)
    emit_h(-745, 610, 675)
    make_mesh_object('Walls and partitions - open thresholds', wall_data, mat_walls, wall_col)

    # Kitchen is an inset area within Cafe. Keep the top edge open and its shared
    # context readable; the three partition runs match the sketched inset.
    kitchen_data = ([], [])
    kx, kt, kw, kh = 495, 275, 120, 75
    emit_k = lambda x1, x2, y1, y2: add_box_mesh(kitchen_data, x1*S, x2*S, -y2*S, -y1*S, FLOOR_H, FLOOR_H+WALL_H)
    emit_k(kx, kx, kt, kt+kh)
    # Explicit inset partitions (east, south, west portions around the opening).
    emit_k(kx+kw, kx+kw, kt, kt+kh)
    emit_k(kx, kx+kw, kt+kh, kt+kh)
    # Rebuild degenerate inset edges as finite-width boxes.
    kitchen_data = ([], [])
    add_box_mesh(kitchen_data, kx*S-WALL_T/2, kx*S+WALL_T/2, -(kt+kh)*S, -kt*S, FLOOR_H, FLOOR_H+WALL_H)
    add_box_mesh(kitchen_data, (kx+kw)*S-WALL_T/2, (kx+kw)*S+WALL_T/2, -(kt+kh)*S, -kt*S, FLOOR_H, FLOOR_H+WALL_H)
    # South partition has a doorway at its left end.
    add_box_mesh(kitchen_data, kx*S, (kx+22)*S, -(kt+kh)*S-WALL_T/2, -(kt+kh)*S+WALL_T/2, FLOOR_H, FLOOR_H+WALL_H)
    add_box_mesh(kitchen_data, (kx+45)*S, (kx+kw)*S, -(kt+kh)*S-WALL_T/2, -(kt+kh)*S+WALL_T/2, FLOOR_H, FLOOR_H+WALL_H)
    make_mesh_object('Kitchen inset partitions', kitchen_data, mat_walls, wall_col)

    # Floating plan labels make the floor plan readable from the saved top view.
    # Repeated generic classroom names remain faithful to the source drawing.
    counts = {}
    for room in rooms:
        x, t, w, h = room['x'], room['top'], room['w'], room['h']
        counts[room['label']] = counts.get(room['label'], 0) + 1
        # Keep labels away from partition lines and centered within the footprint.
        size = 13.5 if len(room['label']) > 13 else (14.5 if len(room['label']) > 9 else 17.0)
        add_text(room['label'], (x+w/2)*S, -(t+h/2)*S,
                 FLOOR_H+WALL_H+0.035, size*S, mat_label, label_col)
    add_text('Entrance', 585*S, -790*S, FLOOR_H+WALL_H+0.035,
             15.0*S, mat_label, label_col)

    # Reference-map ambiguities are recorded as editable notes, not silently
    # presented as surveyed dimensions or certain gameplay doors.
    note = bpy.data.texts.new('School Map Notes')
    note.write('AFTER SCHOOL - SCHOOL BLOCKOUT\n')
    note.write('Source: After-School-AI-GDD/docs/map_image.png and MAP_RECREATION.md\n')
    note.write('One ground floor, top of page is map north; x right, y downward.\n')
    note.write('Normalized proportions are preserved; dimensions are art scale, not surveyed measurements.\n')
    note.write('Openings are approximated from visible marks and the recreation brief.\n\n')
    note.write('Review uncertain: Gym/Outside boundary and the nearby Gym opening; Cafe/Kitchen inset and doorway; upper corridor openings; exact corridor widths and several door locations.\n')
    note.write('No furniture, props, windows, stairs, extra exits, or additional floors were added.\n')
    note.write('The Kitchen inset uses three partition runs inside Cafe.\n')
    note.write('Door leaves are omitted so the mapped openings remain inspectable.\n')

    # Turn the existing startup camera into an orthographic inspection camera.
    camera = bpy.data.objects.get('Camera')
    if camera is None:
        bpy.ops.object.camera_add()
        camera = bpy.context.object
        camera.name = 'Camera'
    camera.location = (20.0, -18.0, 72.0)
    camera.rotation_euler = (0.0, 0.0, 0.0)
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = 44.0
    camera.data.lens = 50
    scene.camera = camera

    light = bpy.data.objects.get('Light')
    if light is None:
        bpy.ops.object.light_add(type='AREA', location=(20, -18, 35))
        light = bpy.context.object
        light.name = 'Light'
    light.location = (20.0, -18.0, 35.0)
    light.data.type = 'AREA'
    light.data.energy = 5200
    light.data.shape = 'DISK'
    light.data.size = 36

    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 1200
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.film_transparent = False
    scene.world.color = (0.12, 0.12, 0.12)
    scene.render.filepath = bpy.path.abspath('//School_preview.png')
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'Medium High Contrast'

    # Save a clean, useful viewport state: material colors and top-down framing.
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                space = area.spaces.active
                space.region_3d.view_perspective = 'ORTHO'
                space.region_3d.view_location = (20.0, -18.0, 0.0)
                space.region_3d.view_distance = 55.0
                space.region_3d.view_rotation = camera.rotation_euler.to_quaternion()
                space.shading.type = 'MATERIAL'

    bpy.ops.wm.save_as_mainfile(filepath=OUT)
    print('Saved:', OUT)
    print('Generated school objects:', len(root.all_objects))


build()
