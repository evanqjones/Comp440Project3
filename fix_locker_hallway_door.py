import bpy
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=bpy.data.filepath)
s=bpy.data.collections['After School - School Blockout']; floor=bpy.data.objects['Locker Room Floor']; wall=bpy.data.objects['Locker Room - North Wall']
pts=[wall.matrix_world@v.co for v in wall.data.vertices]
z0=min(p.z for p in pts); z1=max(p.z for p in pts); ymin=min(p.y for p in pts); ymax=max(p.y for p in pts); xmin=min(p.x for p in pts); xmax=max(p.x for p in pts); center=(xmin+xmax)/2; width=1.05; a=center-width/2; b=center+width/2
# Rebuild opening while retaining any pre-existing wall discontinuities.
parent=list(range(len(wall.data.vertices)))
def find(i):
 while parent[i]!=i: parent[i]=parent[parent[i]]; i=parent[i]
 return i
def join(a,b):
 a=find(a); b=find(b)
 if a!=b: parent[b]=a
for poly in wall.data.polygons:
 ids=list(poly.vertices)
 for i in ids[1:]: join(ids[0],i)
groups={}
for i,v in enumerate(wall.data.vertices): groups.setdefault(find(i),[]).append((wall.matrix_world@v.co).x)
sol_int=sorted((min(xs),max(xs)) for xs in groups.values()); gaps=[]; cur=xmin
for lo,hi in sol_int:
 if lo>cur+1e-4:gaps.append((cur,lo))
 cur=max(cur,hi)
if cur<xmax-1e-4:gaps.append((cur,xmax))
gaps.append((a,b)); gaps.sort(); merged=[]
for lo,hi in gaps:
 if merged and lo<=merged[-1][1]+1e-4:merged[-1]=(merged[-1][0],max(merged[-1][1],hi))
 else:merged.append((lo,hi))
solids=[]; cur=xmin
for lo,hi in merged:
 if lo>cur+1e-4:solids.append((cur,lo))
 cur=max(cur,hi)
if cur<xmax-1e-4:solids.append((cur,xmax))
verts=[]; faces=[]; inv=wall.matrix_world.inverted()
def box(target,x0,x1,y0,y1,z0,z1):
 ps=[Vector((x0,y0,z0)),Vector((x1,y0,z0)),Vector((x1,y1,z0)),Vector((x0,y1,z0)),Vector((x0,y0,z1)),Vector((x1,y0,z1)),Vector((x1,y1,z1)),Vector((x0,y1,z1))]; off=len(target[0]); target[0].extend([tuple(inv@p) for p in ps]); target[1].extend([tuple(off+i for i in f) for f in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))])
for lo,hi in solids:box((verts,faces),lo,hi,ymin,ymax,z0,z1)
wall.data.clear_geometry(); wall.data.from_pydata(verts,[],faces); wall.data.update()
# Replace header with jambs and a high transom opening.
name='Door Header Wall Infill - Locker Room Hallway'; old=bpy.data.objects.get(name)
if old:bpy.data.objects.remove(old,do_unlink=True)
hv=[]; hf=[]
def hbox(x0,x1,y0,y1,z0,z1):
 ps=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]; off=len(hv); hv.extend(ps); hf.extend([tuple(off+i for i in f) for f in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))])
hbox(a,a+.16,ymin,ymax,2.15,z1); hbox(b-.16,b,ymin,ymax,2.15,z1); hbox(a+.16,b-.16,ymin,ymax,2.72,z1)
mesh=bpy.data.meshes.new(name+' Mesh'); mesh.from_pydata(hv,[],hf); mesh.update(); header=bpy.data.objects.new(name,mesh); s.objects.link(header); header.parent=floor; header.matrix_parent_inverse=floor.matrix_world.inverted(); header.location=(0,0,0); mat=bpy.data.materials.get('Walls - blue gray plaster')
if mat:mesh.materials.append(mat)
# Place copied single-door swing arc on the room side of the north wall.
marker_name='Locker Room Hallway Door Swing Marker'; old=bpy.data.objects.get(marker_name)
if old:bpy.data.objects.remove(old,do_unlink=True)
src=bpy.data.objects['Locker Room Door Swing Marker 2']; marker=src.copy(); marker.data=src.data.copy(); marker.name=marker_name; s.objects.link(marker)
for v in marker.data.vertices:
 v.co.x += center-(-1.55); v.co.y = (ymin+ymax)/2 - (v.co.y-3.34)
marker.data.update()
bpy.context.preferences.filepaths.save_version=0; bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
bpy.ops.object.select_all(action='DESELECT')
for o in s.all_objects:o.select_set(True)
bpy.context.view_layer.objects.active=floor
bpy.ops.export_scene.gltf(filepath=bpy.path.abspath('//assets/school_blockout.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('Updated locker north door, header, transom, marker. Opening:',round(a,2),round(b,2),'at y',round((ymin+ymax)/2,2))
