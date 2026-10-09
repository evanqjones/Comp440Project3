import bpy
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=bpy.data.filepath)
s=bpy.data.collections['After School - School Blockout']
floor=bpy.data.objects['Auditorium Floor']
north=bpy.data.objects['Auditorium - North Wall']
west=bpy.data.objects['Auditorium - West Wall']
east=bpy.data.objects['Auditorium - East Wall']
expansion=4.0
floor_pts=[floor.matrix_world@v.co for v in floor.data.vertices]
old_north=max(p.y for p in floor_pts)
old_south=min(p.y for p in floor_pts)
old_center=(old_north+old_south)/2

def shift_vertices(obj, predicate):
 inv=obj.matrix_world.inverted()
 count=0
 for v in obj.data.vertices:
  world=obj.matrix_world@v.co
  if predicate(world):
   world.y += expansion
   v.co=inv@world
   count+=1
 obj.data.update()
 return count

# Stretch the Auditorium floor only at its north edge, keeping the south entrance fixed.
floor_moved=shift_vertices(floor,lambda p:p.y>old_center)
# Move the north end wall and extend the east/west walls to the new north boundary.
north_moved=shift_vertices(north,lambda p:True)
west_moved=shift_vertices(west,lambda p:p.y>old_north-1e-3)
east_moved=shift_vertices(east,lambda p:p.y>old_north-1e-3)

# Add a matching ceiling slab over the new northern floor area. It overlaps the
# existing combined roof shell slightly so there is no visible seam at the join.
roof_name='Auditorium North Roof Extension'
old=bpy.data.objects.get(roof_name)
if old:bpy.data.objects.remove(old,do_unlink=True)
roof=bpy.data.objects['Interior Roof Shell']
roof_pts=[roof.matrix_world@v.co for v in roof.data.vertices]
z0=min(p.z for p in roof_pts); z1=max(p.z for p in roof_pts)
wall_pts=[east.matrix_world@v.co for v in east.data.vertices]+[west.matrix_world@v.co for v in west.data.vertices]
x0=min(p.x for p in wall_pts); x1=max(p.x for p in wall_pts)
y0=old_north-0.08; y1=old_north+expansion+0.08
verts=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
mesh=bpy.data.meshes.new(roof_name+' Mesh'); mesh.from_pydata(verts,[],faces); mesh.update()
obj=bpy.data.objects.new(roof_name,mesh); s.objects.link(obj)
ceiling_mat=bpy.data.materials.get('Ceilings - warm light gray')
if ceiling_mat:mesh.materials.append(ceiling_mat)
obj['room']='Auditorium'; obj['extends_north_m']=expansion
floor['north_expansion_m']=expansion
# Keep the auditorium label near the new room center.
label=bpy.data.objects.get('Auditorium Label')
if label:
 world=label.matrix_world.copy(); world.translation.y += expansion/2; label.matrix_world=world
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
bpy.ops.object.select_all(action='DESELECT')
for o in s.all_objects:o.select_set(True)
bpy.context.view_layer.objects.active=floor
bpy.ops.export_scene.gltf(filepath=bpy.path.abspath('//assets/school_blockout.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_extras=True)
print('Auditorium expanded north by',expansion,'m; floor verts',floor_moved,'north wall verts',north_moved,'west/east side verts',west_moved,east_moved)
print('New north edge',round(max((floor.matrix_world@v.co).y for v in floor.data.vertices),2),'roof y',round(y0,2),'..',round(y1,2))
