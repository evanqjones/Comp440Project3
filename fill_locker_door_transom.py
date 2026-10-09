import bpy
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=bpy.data.filepath)
s=bpy.data.collections['After School - School Blockout']; floor=bpy.data.objects['Locker Room Floor']
wall=bpy.data.objects['Locker Room - East Wall']; ps=[wall.matrix_world@v.co for v in wall.data.vertices]
ex0=min(p.x for p in ps); ex1=max(p.x for p in ps); ey0=min(p.y for p in ps); ey1=max(p.y for p in ps); ez1=max(p.z for p in ps)
center=(ey0+ey1)/2; width=1.05; a=center-width/2; b=center+width/2
name='Door Header Wall Infill - Locker Room Hallway'; old=bpy.data.objects.get(name)
if old:bpy.data.objects.remove(old,do_unlink=True)
verts=[(ex0,a,2.15),(ex1,a,2.15),(ex1,b,2.15),(ex0,b,2.15),(ex0,a,ez1),(ex1,a,ez1),(ex1,b,ez1),(ex0,b,ez1)]
faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
mesh=bpy.data.meshes.new(name+' Mesh'); mesh.from_pydata(verts,[],faces); mesh.update(); obj=bpy.data.objects.new(name,mesh); s.objects.link(obj); obj.parent=floor; obj.matrix_parent_inverse=floor.matrix_world.inverted(); obj.location=(0,0,0)
mat=bpy.data.materials.get('Walls - blue gray plaster')
if mat:mesh.materials.append(mat)
bpy.context.preferences.filepaths.save_version=0; bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
bpy.ops.object.select_all(action='DESELECT')
for o in s.all_objects:o.select_set(True)
bpy.context.view_layer.objects.active=floor
bpy.ops.export_scene.gltf(filepath=bpy.path.abspath('//assets/school_blockout.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('Filled transom over Locker Room hallway door; clear door opening remains',round(a,2),round(b,2),'m wide.')
