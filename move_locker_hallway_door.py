import bpy
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=bpy.data.filepath)
s=bpy.data.collections['After School - School Blockout']; floor=bpy.data.objects['Locker Room Floor']
mat=bpy.data.materials.get('Walls - blue gray plaster')
def bounds(obj):
 p=[obj.matrix_world@v.co for v in obj.data.vertices]
 return (min(v.x for v in p),max(v.x for v in p),min(v.y for v in p),max(v.y for v in p),min(v.z for v in p),max(v.z for v in p))
def mesh_boxes(obj, boxes):
 inv=obj.matrix_world.inverted(); vs=[]; fs=[]
 for x0,x1,y0,y1,z0,z1 in boxes:
  ps=[Vector((x0,y0,z0)),Vector((x1,y0,z0)),Vector((x1,y1,z0)),Vector((x0,y1,z0)),Vector((x0,y0,z1)),Vector((x1,y0,z1)),Vector((x1,y1,z1)),Vector((x0,y1,z1))]
  off=len(vs); vs.extend([tuple(inv@q) for q in ps]); fs.extend([tuple(off+i for i in f) for f in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))])
 obj.data.clear_geometry(); obj.data.from_pydata(vs,[],fs); obj.data.update()
# Restore the north wall, removing the misplaced exit-to-bounds opening.
north=bpy.data.objects['Locker Room - North Wall']; nx0,nx1,ny0,ny1,z0,z1=bounds(north); mesh_boxes(north,[(nx0,nx1,ny0,ny1,z0,z1)])
# Cut a 1.05 m single door into the east wall, toward the school's internal corridor.
east=bpy.data.objects['Locker Room - East Wall']; ex0,ex1,ey0,ey1,ez0,ez1=bounds(east); center=(ey0+ey1)/2; width=1.05; a=center-width/2; b=center+width/2
mesh_boxes(east,[(ex0,ex1,ey0,a,ez0,ez1),(ex0,ex1,b,ey1,ez0,ez1)])
# Replace the north-door header with a header/transom over the east-wall opening.
name='Door Header Wall Infill - Locker Room Hallway'; old=bpy.data.objects.get(name)
if old:bpy.data.objects.remove(old,do_unlink=True)
hv=[]; hf=[]
def hbox(x0,x1,y0,y1,z0,z1):
 ps=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]; off=len(hv); hv.extend(ps); hf.extend([tuple(off+i for i in f) for f in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7))])
hbox(ex0,ex1,a,a+.16,2.15,ez1); hbox(ex0,ex1,b-.16,b,2.15,ez1); hbox(ex0,ex1,a+.16,b-.16,2.72,ez1)
mesh=bpy.data.meshes.new(name+' Mesh'); mesh.from_pydata(hv,[],hf); mesh.update(); header=bpy.data.objects.new(name,mesh); s.objects.link(header); header.parent=floor; header.matrix_parent_inverse=floor.matrix_world.inverted(); header.location=(0,0,0)
if mat:mesh.materials.append(mat)
# Reorient the existing single-door swing arc to the inside of the east wall.
marker_name='Locker Room Hallway Door Swing Marker'; old=bpy.data.objects.get(marker_name)
if old:bpy.data.objects.remove(old,do_unlink=True)
src=bpy.data.objects['Locker Room Door Swing Marker 2']; marker=src.copy(); marker.data=src.data.copy(); marker.name=marker_name; s.objects.link(marker)
wallx=(ex0+ex1)/2; source_center_x=-1.55; source_wall_y=3.34
for v in marker.data.vertices:
 dx=v.co.x-source_center_x; dy=v.co.y-source_wall_y
 v.co.x=wallx-dy; v.co.y=center+dx
marker.data.update()
bpy.context.preferences.filepaths.save_version=0; bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
bpy.ops.object.select_all(action='DESELECT')
for o in s.all_objects:o.select_set(True)
bpy.context.view_layer.objects.active=floor
bpy.ops.export_scene.gltf(filepath=bpy.path.abspath('//assets/school_blockout.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('Locker Room door moved from north (restored) to east interior wall at y=',round(center,2))
