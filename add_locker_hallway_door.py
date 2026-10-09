import bpy
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=bpy.data.filepath)
s=bpy.data.collections['After School - School Blockout']
floor=bpy.data.objects['Locker Room Floor']
wall=bpy.data.objects['Locker Room - North Wall']
pts=[wall.matrix_world@v.co for v in wall.data.vertices]
z0=min(p.z for p in pts); z1=max(p.z for p in pts)
ymin=min(p.y for p in pts); ymax=max(p.y for p in pts); thick=ymax-ymin
xmin=min(p.x for p in pts); xmax=max(p.x for p in pts)
# Single 1.05 m opening centered in the north wall, opening onto the hallway.
center=(xmin+xmax)/2; width=1.05; a=center-width/2; b=center+width/2
# Treat connected wall pieces as preserved existing openings, then subtract the new door.
parent=list(range(len(wall.data.vertices)))
def find(i):
 while parent[i]!=i:
  parent[i]=parent[parent[i]]; i=parent[i]
 return i
def join(a,b):
 a=find(a); b=find(b)
 if a!=b: parent[b]=a
for poly in wall.data.polygons:
 ids=list(poly.vertices)
 for i in ids[1:]: join(ids[0],i)
groups={}
for i,v in enumerate(wall.data.vertices):
 p=wall.matrix_world@v.co; groups.setdefault(find(i),[]).append(p.x)
solid=[(min(xs),max(xs)) for xs in groups.values()]
gaps=[]; cursor=xmin
for lo,hi in sorted(solid):
 if lo>cursor+1e-4: gaps.append((cursor,lo))
 cursor=max(cursor,hi)
if cursor<xmax-1e-4: gaps.append((cursor,xmax))
gaps.append((a,b)); gaps.sort()
merged=[]
for lo,hi in gaps:
 if merged and lo<=merged[-1][1]+1e-4: merged[-1]=(merged[-1][0],max(merged[-1][1],hi))
 else: merged.append((lo,hi))
solids=[]; cursor=xmin
for lo,hi in merged:
 if lo>cursor+1e-4: solids.append((cursor,lo))
 cursor=max(cursor,hi)
if cursor<xmax-1e-4: solids.append((cursor,xmax))
verts=[]; faces=[]; inv=wall.matrix_world.inverted()
def box(x0,x1,y0,y1,z0,z1):
 ps=[Vector((x0,y0,z0)),Vector((x1,y0,z0)),Vector((x1,y1,z0)),Vector((x0,y1,z0)),Vector((x0,y0,z1)),Vector((x1,y0,z1)),Vector((x1,y1,z1)),Vector((x0,y1,z1))]
 off=len(verts); verts.extend([tuple(inv@p) for p in ps]); faces.extend([tuple(off+i for i in f) for f in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))])
for lo,hi in solids: box(lo,hi,ymin,ymax,z0,z1)
wall.data.clear_geometry(); wall.data.from_pydata(verts,[],faces); wall.data.update()
# Door header infill above the 2.15 m door height.
header_name='Door Header Wall Infill - Locker Room Hallway'
old=bpy.data.objects.get(header_name)
if old: bpy.data.objects.remove(old,do_unlink=True)
hverts=[]; hfaces=[]
def add_local_box(x0,x1,y0,y1,z0,z1):
 ps=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
 off=len(hverts); hverts.extend(ps); hfaces.extend([tuple(off+i for i in f) for f in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))])
add_local_box(a,b,ymin,ymax,2.15,z1)
mesh=bpy.data.meshes.new(header_name+' Mesh'); mesh.from_pydata(hverts,[],hfaces); mesh.update()
header=bpy.data.objects.new(header_name,mesh); s.objects.link(header); header.parent=floor; header.matrix_parent_inverse=floor.matrix_world.inverted(); header.location=(0,0,0)
mat=bpy.data.materials.get('Walls - blue gray plaster')
if mat: mesh.materials.append(mat)
# Reuse the existing single-door swing arc, reflected northward and centered at the new opening.
source=bpy.data.objects['Locker Room Door Swing Marker 2']
marker_name='Locker Room Hallway Door Swing Marker'
old=bpy.data.objects.get(marker_name)
if old: bpy.data.objects.remove(old,do_unlink=True)
marker=source.copy(); marker.data=source.data.copy(); marker.name=marker_name; s.objects.link(marker)
# Existing marker arc is on the gym side (north of its south wall); reflect across the north-wall plane.
plane=(ymin+ymax)/2
for v in marker.data.vertices:
 v.co.x += center-(-1.55)
 v.co.y = 2*plane-v.co.y
marker.data.update()
# Add transom opening in the new header, consistent with other single doors.
# Header infill is split around a centered 0.7 m transom above the door.
# Replace the simple solid header with two side piers and top rail surrounding a rectangular gap.
bpy.data.objects.remove(header,do_unlink=True)
hverts=[]; hfaces=[]
add_local_box(a,a+0.16,ymin,ymax,2.15,z1)
add_local_box(b-0.16,b,ymin,ymax,2.15,z1)
add_local_box(a+0.16,b-0.16,ymin,ymax,2.72,z1)
mesh=bpy.data.meshes.new(header_name+' Mesh'); mesh.from_pydata(hverts,[],hfaces); mesh.update(); header=bpy.data.objects.new(header_name,mesh); s.objects.link(header); header.parent=floor; header.matrix_parent_inverse=floor.matrix_world.inverted(); header.location=(0,0,0)
if mat: mesh.materials.append(mat)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
# Export the full school collection for Godot.
bpy.ops.object.select_all(action='DESELECT')
for o in s.all_objects: o.select_set(True)
bpy.context.view_layer.objects.active=floor
bpy.ops.export_scene.gltf(filepath=bpy.path.abspath('//assets/school_blockout.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('Added Locker Room to hallway single door:',round(center,2),round(plane,2),'opening',round(width,2),'m')
