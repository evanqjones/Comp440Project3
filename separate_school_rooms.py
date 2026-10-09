import bpy

S = 0.04
FLOOR_TOP = 0.138
FLOOR_BOTTOM = 0.12
WALL_H = 3.0
WALL_T = 0.22
ROOT_NAME = 'After School - School Blockout'


def mesh_object(name, verts, faces, mat, collection):
    mesh = bpy.data.meshes.new(name + ' Mesh')
    mesh.from_pydata(verts, [], faces)
    if mat:
        mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    return obj


def box_data(x0, x1, y0, y1, z0, z1):
    verts = [
        (x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
        (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1),
    ]
    faces = [
        (0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
        (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7),
    ]
    return verts, faces


def append_box(data, x0, x1, y0, y1, z0, z1):
    verts, faces = data
    off = len(verts)
    v, f = box_data(x0, x1, y0, y1, z0, z1)
    verts.extend(v)
    faces.extend([tuple(i + off for i in face) for face in f])


def segments_without_gaps(start, end, gaps):
    cursor = start
    for a, b in sorted(gaps):
        a, b = max(start, min(end, a)), max(start, min(end, b))
        if a > cursor:
            yield cursor, a
        cursor = max(cursor, b)
    if cursor < end:
        yield cursor, end


def room(label, floor_name, x, top, w, h, material_name, openings=None):
    return {'label': label, 'floor': floor_name, 'x': x, 'top': top,
            'w': w, 'h': h, 'material': material_name,
            'openings': openings or {}}


rooms = [
    room('Locker Room', 'Locker Room Floor', 0, 95, 140, 125, 'Room floor - alternate slate', {'south': [(75,112)]}),
    room('Auditorium', 'Auditorium Floor', 265, 20, 240, 95, 'Room floor - slate', {'south': [(95,145)]}),
    room('Bathroom', 'Bathroom Floor', 600, 25, 170, 95, 'Room floor - alternate slate', {'south': [(63,104)]}),
    room('Cafeteria', 'Cafeteria Floor', 770, 0, 175, 120, 'Room floor - slate', {'south': [(64,108)]}),
    room('Gym', 'Gym Floor', 40, 205, 265, 235, 'Room floor - alternate slate', {'east': [(164,207)], 'south': [(195,235)]}),
    room('Library', 'Library Floor', 340, 125, 280, 120, 'Room floor - slate', {'west': [(48,88)], 'south': [(133,178)]}),
    room('Classroom', 'Classroom A Floor', 645, 125, 170, 120, 'Room floor - alternate slate', {'south': [(62,104)]}),
    room('Classroom', 'Classroom B Floor', 810, 120, 175, 125, 'Room floor - slate', {'south': [(65,108)]}),
    room('Cafe', 'Cafe Floor', 340, 260, 280, 175, 'Cafe floor - muted tile', {'north': [(20,55),(145,180)], 'south': [(104,148)]}),
    room('Kitchen', 'Kitchen Floor', 495, 275, 120, 75, 'Kitchen floor - tile', {'west': [(29,52)], 'south': [(22,45)]}),
    room('Lab Room', 'Lab Room Floor', 645, 255, 330, 125, 'Room floor - alternate slate', {'north': [(54,94)], 'south': [(270,308)]}),
    room('Science Classroom', 'Science Classroom Floor', 645, 380, 330, 125, 'Room floor - slate', {'north': [(270,308)], 'south': [(95,139),(268,310)]}),
    room('Outside', 'Outside Floor', 140, 445, 165, 320, 'Outside - muted grass', {'north': [(82,122)], 'east': [(130,170)], 'south': [(62,106)]}),
    room('Classroom', 'Classroom C Floor', 335, 445, 145, 155, 'Room floor - alternate slate', {'south': [(54,92)]}),
    room('Classroom', 'Classroom D Floor', 480, 445, 145, 155, 'Room floor - slate', {'south': [(54,92)]}),
    room('Classroom', 'Classroom E Floor', 665, 510, 320, 165, 'Room floor - alternate slate', {'south': [(147,195)]}),
    room('Lobby', 'Lobby Floor', 300, 580, 640, 190, 'Lobby floor - worn tile',
         {'north': [(89,127),(234,272),(512,560)], 'east': [(70,175)], 'south': [(266,316),(375,483)]}),
    room('Nurse Office', 'Nurse Office Floor', 895, 650, 100, 105, 'Room floor - slate', {'north': [(30,68)], 'south': [(32,68)]}),
    room('Main Office', 'Main Office Floor', 675, 745, 325, 145, 'Room floor - alternate slate', {'north': [(64,108)], 'west': [(30,67)]}),
]

scene = bpy.context.scene
root = bpy.data.collections.get(ROOT_NAME)
if root is None:
    raise RuntimeError('School collection is missing from assets.blend')

# Remove the previous combined geometry, keeping labels and existing materials.
for collection_name in ('01 - Ground and room floors', '02 - Walls and partitions',
                        '01 - Site Surface', '02 - Room Assemblies (floor parents)', '04 - Room Assemblies'):
    col = bpy.data.collections.get(collection_name)
    if col:
        for obj in list(col.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        for child in list(col.children):
            for obj in list(child.objects):
                bpy.data.objects.remove(obj, do_unlink=True)
            bpy.data.collections.remove(child)
        bpy.data.collections.remove(col)

site_col = bpy.data.collections.new('01 - Site Surface')
assembly_col = bpy.data.collections.new('02 - Room Assemblies (floor parents)')
root.children.link(site_col)
root.children.link(assembly_col)

ground_mat = bpy.data.materials.get('Corridor - cool concrete')
slab_verts, slab_faces = box_data(-30*S, 1015*S, -915*S, 35*S, -0.14, -0.015)
mesh_object('School Site Floor - circulation', slab_verts, slab_faces, ground_mat, site_col)

floors_by_room = []
for room_data in rooms:
    x, t, w, h = room_data['x'], room_data['top'], room_data['w'], room_data['h']
    mat = bpy.data.materials.get(room_data['material'])
    fv, ff = box_data(x*S, (x+w)*S, -(t+h)*S, -t*S, FLOOR_BOTTOM, FLOOR_TOP)
    floor = mesh_object(room_data['floor'], fv, ff, mat, assembly_col)
    floor['room_label'] = room_data['label']
    floor['room_bounds_normalized'] = (x, t, w, h)
    floors_by_room.append((room_data, floor))

    sides = {
        'North': ('north', x, x+w, -t),
        'South': ('south', x, x+w, -(t+h)),
        'West': ('west', t, t+h, x),
        'East': ('east', t, t+h, x+w),
    }
    for side_name, (side_key, start, end, fixed) in sides.items():
        data = ([], [])
        if room_data['floor'] == 'Outside Floor':
            side_segments = []
        elif room_data['floor'] == 'Lobby Floor' and side_key != 'south':
            side_segments = []
        elif room_data['floor'] == 'Lobby Floor' and side_key == 'south':
            side_segments = [(300, 560), (610, 675)]
            fixed = -745
        elif room_data['floor'] == 'Kitchen Floor' and side_key == 'north':
            side_segments = []
        else:
            side_segments = list(segments_without_gaps(start, end, room_data['openings'].get(side_key, [])))
        for a, b in side_segments:
            if side_key in ('north', 'south'):
                y = fixed * S
                append_box(data, a*S, b*S, y-WALL_T/2, y+WALL_T/2, FLOOR_TOP, FLOOR_TOP+WALL_H)
            else:
                x_wall = fixed * S
                append_box(data, x_wall-WALL_T/2, x_wall+WALL_T/2, -b*S, -a*S, FLOOR_TOP, FLOOR_TOP+WALL_H)
        wall_mat = bpy.data.materials.get('Walls - blue gray plaster')
        wall = mesh_object(room_data['floor'].replace(' Floor', '') + ' - ' + side_name + ' Wall',
                           data[0], data[1], wall_mat, assembly_col)
        wall['wall_side'] = side_name.lower()
        wall['doorway_gaps_preserved'] = True
        wall['open_edge'] = len(data[1]) == 0
        wall.parent = floor
        wall.matrix_parent_inverse = floor.matrix_world.inverted()

# Parent each plan label to its closest corresponding room floor so it follows
# that room when the user moves or reformats the assembly.
labels_col = bpy.data.collections.get('03 - Room labels')
labels = [o for o in bpy.data.objects if o.type == 'FONT']
for room_data, floor in floors_by_room:
    candidates = [o for o in labels if o.data.body == room_data['label'] and o.parent is None]
    if not candidates:
        continue
    cx, cy = ((room_data['x'] + room_data['w']/2)*S,
              -(room_data['top'] + room_data['h']/2)*S)
    label = min(candidates, key=lambda o: (o.location.x-cx)**2 + (o.location.y-cy)**2)
    world = label.matrix_world.copy()
    label.parent = floor
    label.matrix_parent_inverse = floor.matrix_world.inverted()
    label.matrix_world = world

entrance = next((o for o in labels if o.data.body == 'Entrance'), None)
lobby_floor = bpy.data.objects.get('Lobby Floor')
if entrance and lobby_floor:
    world = entrance.matrix_world.copy()
    entrance.parent = lobby_floor
    entrance.matrix_parent_inverse = lobby_floor.matrix_world.inverted()
    entrance.matrix_world = world

# Keep the saved camera framing the complete, now-separated floorplan.
camera = scene.camera
if camera:
    camera.location = (20.0, -18.0, 72.0)
    camera.rotation_euler = (0.0, 0.0, 0.0)
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = 44.0

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print('Separated room floors:', len(floors_by_room))
print('Parented walls:', sum(1 for o in bpy.data.objects if ' Wall' in o.name and o.parent is not None))
print('Outside floor:', bool(bpy.data.objects.get('Outside Floor')))
