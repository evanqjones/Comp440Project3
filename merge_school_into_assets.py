import bpy


SOURCE = bpy.path.abspath('//School.blend')
TARGET = bpy.path.abspath('//assets.blend')
COLLECTION_NAME = 'After School - School Blockout'

# This file is run with assets.blend loaded. Append the authored school
# collection and its dependent meshes/materials while retaining the original
# scene objects and startup file.
if COLLECTION_NAME not in bpy.data.collections:
    with bpy.data.libraries.load(SOURCE, link=False) as (source_data, target_data):
        target_data.collections = [COLLECTION_NAME]
        target_data.texts = ['School Map Notes']

school_collection = bpy.data.collections.get(COLLECTION_NAME)
if school_collection is None:
    raise RuntimeError('Could not append school collection from School.blend')
if school_collection.name not in [child.name for child in bpy.context.scene.collection.children]:
    bpy.context.scene.collection.children.link(school_collection)

notes = bpy.data.texts.get('School Map Notes')
if notes is None:
    notes = bpy.data.texts.new('School Map Notes')
    notes.write('AFTER SCHOOL - SCHOOL BLOCKOUT\n')
    notes.write('Source: After-School-AI-GDD/docs/map_image.png and MAP_RECREATION.md\n')
    notes.write('One ground floor, top of page is map north; x right, y downward.\n')
    notes.write('Normalized proportions are preserved; dimensions are art scale, not surveyed measurements.\n')
    notes.write('Openings are approximated from visible marks and the recreation brief.\n\n')
    notes.write('Review uncertain: Gym/Outside boundary and the nearby Gym opening; Cafe/Kitchen inset and doorway; upper corridor openings; exact corridor widths and several door locations.\n')
    notes.write('No furniture, props, windows, stairs, extra exits, or additional floors were added.\n')
    notes.write('The Kitchen inset uses three partition runs inside Cafe.\n')
    notes.write('Door leaves are omitted so the mapped openings remain inspectable.\n')

camera = bpy.data.objects.get('Camera')
if camera is None:
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = 'Camera'
camera.location = (20.0, -18.0, 72.0)
camera.rotation_euler = (0.0, 0.0, 0.0)
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 44.0
bpy.context.scene.camera = camera

light = bpy.data.objects.get('Light')
if light is not None:
    light.location = (20.0, -18.0, 35.0)
    light.data.type = 'AREA'
    light.data.energy = 5200
    light.data.shape = 'DISK'
    light.data.size = 36

for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            space = area.spaces.active
            space.region_3d.view_perspective = 'ORTHO'
            space.region_3d.view_location = (20.0, -18.0, 0.0)
            space.region_3d.view_distance = 55.0
            space.region_3d.view_rotation = camera.rotation_euler.to_quaternion()
            space.shading.type = 'MATERIAL'

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=TARGET)
print('Added school collection to:', TARGET)
print('School objects:', len(school_collection.all_objects))
