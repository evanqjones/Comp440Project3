import bpy
from mathutils import Vector


COLLECTION_NAME = "After School - School Blockout"
PREFIX = "Auditorium Encounter"


def world_bounds(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return (
        min(point.x for point in points), max(point.x for point in points),
        min(point.y for point in points), max(point.y for point in points),
        min(point.z for point in points), max(point.z for point in points),
    )


def add_box(collection, name, dimensions, location, material):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material is not None:
        obj.data.materials.append(material)
    for existing_collection in list(obj.users_collection):
        existing_collection.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def add_cylinder(collection, name, radius, depth, location, material, vertices=16, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=location,
        rotation=rotation or (0.0, 0.0, 0.0),
    )
    obj = bpy.context.object
    obj.name = name
    if material is not None:
        obj.data.materials.append(material)
    for existing_collection in list(obj.users_collection):
        existing_collection.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def make_material(name, color, roughness=0.78):
    material = bpy.data.materials.get(name)
    if material is None:
        material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.roughness = roughness
    return material


def parent_preserve_world(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def main():
    school_collection = bpy.data.collections.get(COLLECTION_NAME)
    assembly_collection = bpy.data.collections.get("02 - Room Assemblies (floor parents)")
    floor = bpy.data.objects.get("Auditorium Floor")
    if school_collection is None or assembly_collection is None or floor is None:
        raise RuntimeError("The auditorium school collection/floor was not found")

    for obj in list(school_collection.all_objects):
        if obj.name.startswith(PREFIX):
            bpy.data.objects.remove(obj, do_unlink=True)

    min_x, max_x, min_y, max_y, min_z, max_z = world_bounds(floor)
    center_x = (min_x + max_x) * 0.5
    floor_z = max_z
    room_depth = max_y - min_y
    north_edge = max_y

    stage_material = make_material("Preview Auditorium Stage", (0.22, 0.16, 0.12))
    stage_trim = make_material("Preview Auditorium Stage Trim", (0.38, 0.27, 0.18))
    chair_material = make_material("Preview Auditorium Chair", (0.13, 0.20, 0.27))
    chair_frame = make_material("Preview Auditorium Chair Frame", (0.11, 0.12, 0.13))
    mic_material = make_material("Preview Auditorium Microphone", (0.46, 0.49, 0.52), 0.42)

    # The auditorium's south entrance is at the lower-Y end. Keep a full-width
    # center aisle open from that door to the microphone just in front of stage.
    stage_width = min(7.8, max_x - min_x - 1.2)
    stage_depth = min(1.85, room_depth * 0.17)
    stage_front_y = north_edge - stage_depth - 0.12
    stage_center_y = stage_front_y + stage_depth * 0.5
    stage_height = 0.48
    stage_root = bpy.data.objects.new(PREFIX + " - Stage", None)
    stage_root.empty_display_type = "CUBE"
    stage_root.empty_display_size = 0.35
    school_collection.objects.link(stage_root)
    stage_root.location = (center_x, stage_center_y, floor_z)
    stage_root["room"] = "Auditorium"
    stage_root["preview_prop"] = True
    stage_top = add_box(
        school_collection, PREFIX + " Stage Platform",
        (stage_width, stage_depth, stage_height),
        (center_x, stage_center_y, floor_z + stage_height * 0.5), stage_material,
    )
    parent_preserve_world(stage_top, stage_root)
    stage_front = add_box(
        school_collection, PREFIX + " Stage Front Trim",
        (stage_width, 0.10, 0.12),
        (center_x, stage_front_y + 0.035, floor_z + stage_height - 0.06), stage_trim,
    )
    parent_preserve_world(stage_front, stage_root)

    # Two low, broad steps connect the aisle to the raised platform.
    step_footprint = 0.62
    for index, step_height in enumerate((0.32, 0.16)):
        step_depth = step_footprint
        step_back_y = stage_front_y - step_footprint * index
        step_front_y = step_back_y - step_depth
        step_center_y = (step_front_y + step_back_y) * 0.5
        step = add_box(
            school_collection, "%s Stage Step %02d" % (PREFIX, index + 1),
            (2.25, step_depth, step_height),
            (center_x, step_center_y, floor_z + step_height * 0.5), stage_trim,
        )
        parent_preserve_world(step, stage_root)

    mic_y = stage_front_y - 1.75
    mic_root = bpy.data.objects.new(PREFIX + " - Microphone Stand", None)
    mic_root.empty_display_type = "CIRCLE"
    mic_root.empty_display_size = 0.24
    school_collection.objects.link(mic_root)
    mic_root.location = (center_x, mic_y, floor_z)
    mic_root["item_id"] = "microphone"
    mic_root["room"] = "Auditorium"
    for name, radius, depth, z, rotation in (
        ("Base", 0.17, 0.06, 0.04, None),
        ("Stem", 0.035, 1.24, 0.66, None),
        ("Head", 0.075, 0.24, 1.31, (1.5708, 0.0, 0.0)),
    ):
        part = add_cylinder(
            school_collection, "%s Microphone %s" % (PREFIX, name),
            radius, depth, (center_x, mic_y, floor_z + z), mic_material,
            vertices=12, rotation=rotation,
        )
        parent_preserve_world(part, mic_root)

    # Five rows of individual low-poly chairs flank the central approach.
    # Their backs face the stage so a crouched player can break the spotlight.
    chair_width = 0.62
    chair_depth = 0.62
    seat_height = 0.48
    seat_thickness = 0.10
    back_height = 0.58
    back_thickness = 0.08
    row_fractions = (0.78, 0.67, 0.56, 0.45, 0.34)
    side_offsets = (1.48, 2.28, 3.08)
    chair_index = 0
    for row_index, fraction in enumerate(row_fractions, start=1):
        row_y = min_y + room_depth * fraction
        for side in (-1.0, 1.0):
            for seat_index, offset in enumerate(side_offsets, start=1):
                chair_index += 1
                chair_x = center_x + side * offset
                root = bpy.data.objects.new(
                    "%s Chair %02d" % (PREFIX, chair_index), None
                )
                root.empty_display_type = "CUBE"
                root.empty_display_size = 0.22
                school_collection.objects.link(root)
                root.location = (chair_x, row_y, floor_z)
                root["row"] = row_index
                root["seat"] = seat_index
                root["room"] = "Auditorium"
                root["preview_prop"] = True

                parts = (
                    ("Seat", (chair_width, chair_depth, seat_thickness),
                     (chair_x, row_y, floor_z + seat_height - seat_thickness * 0.5), chair_material),
                    ("Back", (chair_width, back_thickness, back_height),
                     (chair_x, row_y - chair_depth * 0.5 + back_thickness * 0.5,
                      floor_z + seat_height + back_height * 0.5 - 0.03), chair_material),
                )
                for suffix, dimensions, location, material in parts:
                    part = add_box(
                        school_collection,
                        "%s Chair %02d %s" % (PREFIX, chair_index, suffix),
                        dimensions, location, material,
                    )
                    parent_preserve_world(part, root)
                leg_height = seat_height - seat_thickness
                for leg_x in (-1.0, 1.0):
                    for leg_y in (-1.0, 1.0):
                        leg = add_box(
                            school_collection,
                            "%s Chair %02d Leg" % (PREFIX, chair_index),
                            (0.055, 0.055, leg_height),
                            (chair_x + leg_x * (chair_width * 0.5 - 0.06),
                             row_y + leg_y * (chair_depth * 0.5 - 0.06),
                             floor_z + leg_height * 0.5), chair_frame,
                        )
                        parent_preserve_world(leg, root)
                parent_preserve_world(root, floor)

    parent_preserve_world(stage_root, floor)
    parent_preserve_world(mic_root, floor)

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in school_collection.all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = floor
    glb_path = bpy.path.abspath("//assets/school_blockout.glb")
    bpy.ops.export_scene.gltf(
        filepath=glb_path, export_format="GLB", use_selection=True,
        export_apply=True, export_yup=True, export_extras=True,
    )
    print("Auditorium encounter created: stage, 2 steps, %d chairs, and microphone placeholder" % chair_index)
    print("Stage front Y: %.3f; microphone Y: %.3f; exported: %s" % (stage_front_y, mic_y, glb_path))


main()
