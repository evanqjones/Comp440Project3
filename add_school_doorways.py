import bpy
from collections import defaultdict
from mathutils import Vector

SCHOOL = bpy.data.collections.get('After School - School Blockout')
if SCHOOL is None:
    raise RuntimeError('School collection is missing from assets.blend')

FLOOR_NAMES = {
    'auditorium': 'Auditorium Floor',
    'restroom': 'Bathroom Floor',
    'art': 'Cafeteria Floor',
    'class_a': 'Classroom A Floor',
    'class_b': 'Classroom B Floor',
    'library': 'Library Floor',
    'cafeteria': 'Cafe Floor',
    'lab': 'Lab Room Floor',
    'science': 'Science Classroom Floor',
    'class_c': 'Classroom C Floor',
    'class_d': 'Classroom D Floor',
    'class_e': 'Classroom E Floor',
    'lobby': 'Lobby Floor',
    'nurse': 'Nurse Office Floor',
    'office': 'Main Office Floor',
    'locker': 'Locker Room Floor',
    'gym': 'Gym Floor',
    'outside': 'Outside Floor',
}

def world_bounds(obj):
    pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    return {
        'xmin': min(p.x for p in pts), 'xmax': max(p.x for p in pts),
        'ymin': min(p.y for p in pts), 'ymax': max(p.y for p in pts),
        'zmin': min(p.z for p in pts), 'zmax': max(p.z for p in pts),
    }

floors = {key: bpy.data.objects[name] for key, name in FLOOR_NAMES.items()}
bounds = {key: world_bounds(obj) for key, obj in floors.items()}

# Keep wall height and thickness from the current user-edited model.
wall_z_mins, wall_z_maxs, thicknesses = [], [], []
for obj in SCHOOL.all_objects:
    if ' Wall' not in obj.name or obj.type != 'MESH' or not obj.data.vertices:
        continue
    pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    wall_z_mins.append(min(p.z for p in pts))
    wall_z_maxs.append(max(p.z for p in pts))
    dx = max(p.x for p in pts) - min(p.x for p in pts)
    dy = max(p.y for p in pts) - min(p.y for p in pts)
    thicknesses.append(min(dx, dy))
Z0 = sorted(wall_z_mins)[len(wall_z_mins)//2]
Z1 = sorted(wall_z_maxs)[len(wall_z_maxs)//2]
THICK = sorted(thicknesses)[len(thicknesses)//2]

def component_intervals(obj, axis):
    """Return current wall-piece intervals, preserving existing doorway gaps."""
    mesh = obj.data
    if not mesh.vertices:
        return []
    parent = list(range(len(mesh.vertices)))
    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    def join(a, b):
        a, b = find(a), find(b)
        if a != b:
            parent[b] = a
    for poly in mesh.polygons:
        ids = list(poly.vertices)
        for i in ids[1:]:
            join(ids[0], i)
    groups = defaultdict(list)
    for i, vert in enumerate(mesh.vertices):
        groups[find(i)].append(obj.matrix_world @ vert.co)
    return [(min(getattr(p, axis) for p in ps), max(getattr(p, axis) for p in ps))
            for ps in groups.values()]

def complement(start, end, solid_intervals):
    gaps, cursor = [], start
    for a, b in sorted(solid_intervals):
        a, b = max(start, a), min(end, b)
        if a > cursor + 1e-4:
            gaps.append((cursor, a))
        cursor = max(cursor, b)
    if cursor < end - 1e-4:
        gaps.append((cursor, end))
    return gaps

def merge_intervals(intervals):
    result = []
    for a, b in sorted((min(a,b), max(a,b)) for a,b in intervals):
        if not result or a > result[-1][1] + 1e-4:
            result.append([a,b])
        else:
            result[-1][1] = max(result[-1][1], b)
    return [(a,b) for a,b in result]

def wall_edge(room_key, side):
    b = bounds[room_key]
    if side in ('north','south'):
        axis = 'x'
        fixed = b['ymax'] if side == 'north' else b['ymin']
        start, end = b['xmin'], b['xmax']
    else:
        axis = 'y'
        fixed = b['xmax'] if side == 'east' else b['xmin']
        start, end = b['ymin'], b['ymax']
    obj = bpy.data.objects.get(floors[room_key].name.replace(' Floor','') + f' - {side.title()} Wall')
    if obj is None:
        raise RuntimeError(f'Missing wall object: {room_key} {side}')
    return obj, axis, start, end, fixed

def queue(room_key, side, center, width=1.05, preserve=True):
    obj, axis, start, end, fixed = wall_edge(room_key, side)
    a, b = max(start, center-width/2), min(end, center+width/2)
    if b-a < width*0.65:
        raise RuntimeError(f'Door does not fit on {room_key} {side}: {a:.2f}..{b:.2f}')
    requested[obj.name].append((a,b))
    if not preserve:
        rebuild[obj.name] = True

def edge_range(room_key, side):
    b = bounds[room_key]
    return (b['xmin'],b['xmax']) if side in ('north','south') else (b['ymin'],b['ymax'])

def add_pair(a_room, a_side, b_room, b_side, center, width=1.05):
    queue(a_room, a_side, center, width)
    queue(b_room, b_side, center, width)

requested = defaultdict(list)
rebuild = {}

# Doors that open into the existing hallways.
for key, side in [
    ('auditorium','south'), ('class_a','south'), ('class_b','south'),
    ('library','west'), ('cafeteria','east'), ('class_c','south'),
    ('class_d','south'), ('class_e','south'), ('science','south'),
]:
    lo, hi = edge_range(key, side)
    center = (lo+hi)/2
    if key == 'science':
        # This opening faces the clear strip west of Classroom E.
        center = lo + 1.05
    queue(key, side, center, 1.05)

# Restroom: two separate south doors for Girls and Boys.
rest_lo, rest_hi = edge_range('restroom','south')
rest_centers = (rest_lo+(rest_hi-rest_lo)*0.32, rest_lo+(rest_hi-rest_lo)*0.68)
queue('restroom','south',rest_centers[0],0.95)
queue('restroom','south',rest_centers[1],0.95)

# Art Room west door is shared through its common wall with the Restroom.
shared_y = (max(bounds['art']['ymin'], bounds['restroom']['ymin']) +
            min(bounds['art']['ymax'], bounds['restroom']['ymax'])) / 2
add_pair('art','west','restroom','east',shared_y,1.0)

# Lab south/right and Science north are one shared opening.
lab_right = min(bounds['lab']['xmax'], bounds['science']['xmax']) - 0.9
add_pair('lab','south','science','north',lab_right,1.0)

# Door between the two lower classrooms; both sides of their shared partition open.
class_shared_y = (max(bounds['class_c']['ymin'], bounds['class_d']['ymin']) +
                  min(bounds['class_c']['ymax'], bounds['class_d']['ymax'])) / 2
add_pair('class_c','east','class_d','west',class_shared_y,1.0)

# Nurse Office opens west to the Lobby and south to Main Office.
nurse_west = sum(edge_range('nurse','west'))/2
queue('nurse','west',nurse_west,1.0)
nurse_south_x = sum(edge_range('nurse','south'))/2
add_pair('nurse','south','office','north',nurse_south_x,1.0)

# Locker Room and Gym share one aligned opening. Reuse the existing Locker door.
locker_obj, locker_axis, locker_lo, locker_hi, _ = wall_edge('locker','south')
locker_intervals = component_intervals(locker_obj, locker_axis)
locker_gaps = complement(locker_lo, locker_hi, locker_intervals)
if locker_gaps:
    a,b = max(locker_gaps, key=lambda pair: pair[1]-pair[0])
    add_pair('locker','south','gym','north',(a+b)/2,b-a)
else:
    common = (max(bounds['locker']['xmin'],bounds['gym']['xmin']), min(bounds['locker']['xmax'],bounds['gym']['xmax']))
    add_pair('locker','south','gym','north',sum(common)/2,1.0)

# Lobby's west doorway and Outside's east doorway face the open passage between them.
hall_y = (max(bounds['lobby']['ymin'],bounds['outside']['ymin']) +
          min(bounds['lobby']['ymax'],bounds['outside']['ymax'])) / 2
queue('lobby','west',hall_y,1.2,preserve=False)
queue('outside','east',hall_y,1.2,preserve=False)

# Give Outside a bounding wall on each side. Its north door aligns with the
# existing Gym south doorway, so that is one shared passage.
gym_obj, gym_axis, gym_lo, gym_hi, _ = wall_edge('gym','south')
gym_intervals = component_intervals(gym_obj, gym_axis)
gym_gaps = complement(gym_lo,gym_hi,gym_intervals)
if gym_gaps:
    ga,gb=max(gym_gaps,key=lambda pair:pair[1]-pair[0])
    outside_x=(ga+gb)/2
    add_pair('gym','south','outside','north',outside_x,gb-ga)
else:
    xcommon=(max(bounds['gym']['xmin'],bounds['outside']['xmin']), min(bounds['gym']['xmax'],bounds['outside']['xmax']))
    add_pair('gym','south','outside','north',sum(xcommon)/2,1.2)
for side in ('north','east','south','west'):
    obj,axis,lo,hi,_=wall_edge('outside',side)
    rebuild[obj.name]=True

# Rebuild only the specified wall meshes, preserving any existing openings.
wall_mat = bpy.data.materials.get('Walls - blue gray plaster')
def add_world_box(verts, faces, x0,x1,y0,y1,z0,z1, inverse):
    world_verts=[Vector((x0,y0,z0)),Vector((x1,y0,z0)),Vector((x1,y1,z0)),Vector((x0,y1,z0)),
                 Vector((x0,y0,z1)),Vector((x1,y0,z1)),Vector((x1,y1,z1)),Vector((x0,y1,z1))]
    off=len(verts)
    verts.extend([tuple(inverse @ p) for p in world_verts])
    faces.extend([tuple(off+i for i in f) for f in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))])

for name, new_gaps in requested.items():
    obj=bpy.data.objects[name]
    side=name.rsplit(' ',2)[-2].lower()
    room_key=next(key for key,f in floors.items() if f.name.replace(' Floor','') == name.rsplit(' - ',1)[0])
    axis='x' if side in ('north','south') else 'y'
    b=bounds[room_key]
    start,end=(b['xmin'],b['xmax']) if axis=='x' else (b['ymin'],b['ymax'])
    fixed=(b['ymax'] if side=='north' else b['ymin']) if axis=='x' else (b['xmax'] if side=='east' else b['xmin'])
    if rebuild.get(name):
        old_gaps=[]
    else:
        old_gaps=complement(start,end,component_intervals(obj,axis)) if obj.data.vertices else [(start,end)]
    gaps=merge_intervals(old_gaps+new_gaps)
    solids=[]; cursor=start
    for a,bg in gaps:
        if a>cursor+1e-4: solids.append((cursor,a))
        cursor=max(cursor,bg)
    if cursor<end-1e-4: solids.append((cursor,end))
    verts,faces=[],[]
    inv=obj.matrix_world.inverted()
    for a,bg in solids:
        if axis=='x':
            add_world_box(verts,faces,a,bg,fixed-THICK/2,fixed+THICK/2,Z0,Z1,inv)
        else:
            add_world_box(verts,faces,fixed-THICK/2,fixed+THICK/2,a,bg,Z0,Z1,inv)
    mesh=obj.data
    mesh.clear_geometry()
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    if not mesh.materials and wall_mat:
        mesh.materials.append(wall_mat)
    obj['open_edge']=not bool(faces)
    obj['doorway_gaps_preserved']=True

# Update the room name and add the two restroom door signs.
restroom_label=next((o for o in SCHOOL.all_objects if o.type=='FONT' and o.data.body in ('Bathroom','Restroom')),None)
if restroom_label:
    restroom_label.data.body='Restroom'

def add_door_sign(name, body, x, y, parent):
    old=bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old,do_unlink=True)
    curve=bpy.data.curves.new(name+' Text','FONT')
    curve.body=body
    curve.align_x='CENTER'
    curve.align_y='CENTER'
    curve.size=0.3
    obj=bpy.data.objects.new(name,curve)
    SCHOOL.children.get('03 - Room labels').objects.link(obj)
    obj.location=(x,y,Z1+0.04)
    mat=bpy.data.materials.get('Room lettering - charcoal')
    if mat: curve.materials.append(mat)
    obj.parent=parent
    obj.matrix_parent_inverse=parent.matrix_world.inverted()
    return obj

rest_floor=floors['restroom']
rb=bounds['restroom']
add_door_sign('Restroom Girls Door Label','Girls',rest_centers[0],rb['ymin']+0.4,rest_floor)
add_door_sign('Restroom Boys Door Label','Boys',rest_centers[1],rb['ymin']+0.4,rest_floor)

bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print('Doorway updates saved. Modified wall objects:',len(requested))
print('Restroom doors: Girls, Boys; Outside perimeter built with shared Gym and Lobby entries.')
