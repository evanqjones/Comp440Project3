import bpy
bpy.ops.wm.open_mainfile(filepath=bpy.data.filepath)
s=bpy.data.collections['After School - School Blockout']
for n in ('Locker Room Hallway Door Swing Marker','Door Header Wall Infill - Locker Room Hallway','Locker Room - East Wall'):
 o=bpy.data.objects.get(n)
 if o:
  o['door_type']='one_way'
  o['opens_from_room']='Locker Room'
  o['opens_toward_room']='Hallway'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
bpy.ops.object.select_all(action='DESELECT')
for o in s.all_objects:o.select_set(True)
bpy.context.view_layer.objects.active=bpy.data.objects['Locker Room Floor']
bpy.ops.export_scene.gltf(filepath=bpy.path.abspath('//assets/school_blockout.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_extras=True)
print('Tagged Locker Room hallway door as one-way, operable from Locker Room side.')
